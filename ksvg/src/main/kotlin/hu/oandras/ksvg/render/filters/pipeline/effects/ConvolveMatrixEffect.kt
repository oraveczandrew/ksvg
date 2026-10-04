/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

@file:Suppress("SpellCheckingInspection") // AGSL builtins

package hu.oandras.ksvg.render.filters.pipeline.effects

import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.filter.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.render.FeConvolveMatrixRenderNode

/**
 * Single-pass convolution over straight taps with premultiplied output.
 * Out-of-bounds taps follow `uEdgeMode` (0 = duplicate/clamp, 1 = wrap,
 * 2 = none/transparent), mirroring the CPU `sampleCoordinate` paths over
 * integer texel indices. Skia child sampling outside the input is NOT
 * reliably clamped (Adreno reads undefined values there), so every mode
 * resolves taps explicitly. `uBounds` holds the first/last texel centers
 * in `fragCoord` space (half-texel inset, like the lighting/Sobel bounds):
 * at 1:1 sampling the taps land exactly on centers and every mode matches
 * the CPU index math bit-for-bit up to float rounding.
 */
private const val CONVOLVE_MATRIX_SHADER: String = """
            uniform shader uInput;
            uniform float uKernel[49];
            uniform int uOrderX;
            uniform int uOrderY;
            uniform int uTargetX;
            uniform int uTargetY;
            uniform float uDivisor;
            uniform float uBias;
            uniform int uPreserveAlpha;
            uniform int uEdgeMode;
            uniform float4 uBounds;
            half4 main(float2 fragCoord) {
                float4 sum = float4(0.0);
                int kx = 0;
                int ky = 0;
                float2 size = float2(uBounds.z - uBounds.x + 1.0, uBounds.w - uBounds.y + 1.0);
                for (int i = 0; i < 49; ++i) {
                    if (i >= uOrderX * uOrderY) break;
                    float2 raw = fragCoord + float2(float(kx - uTargetX), float(ky - uTargetY));
                    float4 tap;
                    if (uEdgeMode == 2) {
                        // none: transparent outside the input extent.
                        if (raw.x < uBounds.x - 0.5 || raw.x > uBounds.z + 0.5 ||
                            raw.y < uBounds.y - 0.5 || raw.y > uBounds.w + 0.5) {
                            tap = float4(0.0);
                        } else {
                            tap = uInput.eval(raw);
                        }
                    } else if (uEdgeMode == 1) {
                        // wrap: floored modulo over the input extent
                        // (AGSL mod is floored, like the CPU kernel).
                        // Snap to the tap grid first: fragCoord carries
                        // Adreno interpolation dust, and a tap dusted just
                        // BELOW the extent would wrap catastrophically to
                        // the far end (C7 precedent: full missing edge
                        // columns). Interior/integer taps are unaffected
                        // (snapping is exact there). 1.0 tap pitch matches
                        // the duplicate path's device-px offsets.
                        float2 grid = floor(raw - uBounds.xy + 0.5);
                        float2 wrapped = float2(
                            uBounds.x + mod(grid.x, size.x),
                            uBounds.y + mod(grid.y, size.y));
                        tap = uInput.eval(wrapped);
                    } else {
                        tap = uInput.eval(clamp(raw, uBounds.xy, uBounds.zw));
                    }
                    sum += tap * uKernel[i];
                    kx++;
                    if (kx >= uOrderX) {
                        kx = 0;
                        ky++;
                    }
                }
                float4 res = sum / uDivisor + uBias;
                if (uPreserveAlpha != 0) res.a = uInput.eval(fragCoord).a;
                // Clamp like the CPU clamp255, then premultiply: the pipeline
                // contract is premultiplied effect output (like the sibling
                // shaders), and premultiplying by an unclamped alpha would
                // blow out bright pixels. Straight output would only hide
                // behind alpha-255 pixels and surface on computed mid-range
                // alpha instead.
                res = clamp(res, float4(0.0), float4(1.0));
                return half4(res.rgb * res.a, res.a);
            }
        """

/**
 * Builds the convolve-matrix step of an Impl33 chain, selecting the edge
 * mode. The caller chains the effect onto the primitive input
 * and registers the returned shader. Returns null when the chain must be
 * declined: a `kernelUnitLength` needs a downscale-convolve-upscale
 * sequence, which the GPU chain cannot represent, or when the kernel
 * exceeds the shader limit.
 *
 * @param node the convolve render node (order, kernel, edge mode)
 * @param filterRegion the filter region in user space
 * @param scaleX scaleY the buffer scale
 * @param padX padY the chain padding in buffer pixels
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createConvolveMatrixShaderEffect(
    node: FeConvolveMatrixRenderNode,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    if (node.kernelUnitLengthX != 0f || node.kernelUnitLengthY != 0f) {
        return null
    }
    // uEdgeMode: 0 = duplicate/clamp, 1 = wrap, 2 = none/transparent.
    val edgeMode = when (node.sourceElement.edgeMode) {
        ConvolveMatrixEdgeMode.wrap -> 1
        ConvolveMatrixEdgeMode.none -> 2
        else -> 0
    }
    return createConvolveShaderEffect(
        node = node,
        edgeMode = edgeMode,
        filterRegion = filterRegion,
        scaleX = scaleX,
        scaleY = scaleY,
        padX = padX,
        padY = padY,
        inputUniformName = inputUniformName,
    )
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private fun createConvolveShaderEffect(
    node: FeConvolveMatrixRenderNode,
    edgeMode: Int,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    val size = node.orderX * node.orderY
    val kernel = node.kernel ?: FloatArray(size)
    if (size > 49 || kernel.size > 49) return null
    val shader = RuntimeShader(CONVOLVE_MATRIX_SHADER)
    val paddedKernel = FloatArray(49)
    kernel.copyInto(paddedKernel)
    // SVG 1.1 section 15.22: true convolution — the shader correlates its
    // taps in row-major order, so mirror the spec-order kernel 180 degrees
    // up front (zero padding beyond `size` stays put).
    for (i in 0 until size / 2) {
        val j = size - 1 - i
        val tmp = paddedKernel[i]
        paddedKernel[i] = paddedKernel[j]
        paddedKernel[j] = tmp
    }
    shader.setFloatUniform("uKernel", paddedKernel)
    shader.setIntUniform("uOrderX", node.orderX)
    shader.setIntUniform("uOrderY", node.orderY)
    shader.setIntUniform("uTargetX", node.targetX)
    shader.setIntUniform("uTargetY", node.targetY)
    shader.setFloatUniform("uDivisor", node.divisor)
    shader.setFloatUniform("uBias", node.bias)
    shader.setIntUniform("uPreserveAlpha", if (node.preserveAlpha) 1 else 0)
    shader.setIntUniform("uEdgeMode", edgeMode)
    // Input extent for tap clamping (mirrors the CPU bitmap bounds).
    // Inset by half a texel: clamped taps must land on texel CENTERS
    // (integer-corner clamping would bilinearly blend two edge texels
    // where the CPU samples the single clamped index exactly).
    shader.setFloatUniform(
        "uBounds",
        padX + 0.5f,
        padY + 0.5f,
        padX + filterRegion.width() * scaleX - 0.5f,
        padY + filterRegion.height() * scaleY - 0.5f,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
