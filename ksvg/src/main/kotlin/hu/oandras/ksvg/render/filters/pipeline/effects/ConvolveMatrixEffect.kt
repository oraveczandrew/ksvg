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
            uniform float uKernel[25];
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
                for (int i = 0; i < 25; ++i) {
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
                return half4(res);
            }
        """

/**
 * Builds the duplicate-mode convolve-matrix step of an Impl33 chain: the
 * configured [RuntimeShader] (kept by the caller for downstream
 * `resultShaders` lookups) plus the [RenderEffect] wrapping it under
 * [inputUniformName]. See [createConvolveWrapShaderEffect] for the shared
 * semantics; the mode is pinned per factory (no caller-side flag).
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createConvolveDuplicateShaderEffect(
    node: FeConvolveMatrixRenderNode,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    return createConvolveShaderEffect(node, 0, filterRegion, scaleX, scaleY, padX, padY, inputUniformName)
}

/**
 * Builds the wrap-mode convolve-matrix step of an Impl33 chain (out-of-
 * bounds taps wrap around the input extent). See
 * [createConvolveDuplicateShaderEffect] for the shared semantics.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createConvolveWrapShaderEffect(
    node: FeConvolveMatrixRenderNode,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    return createConvolveShaderEffect(node, 1, filterRegion, scaleX, scaleY, padX, padY, inputUniformName)
}

/**
 * Builds the none-mode convolve-matrix step of an Impl33 chain
 * (out-of-bounds taps read transparent). See
 * [createConvolveDuplicateShaderEffect] for the shared semantics.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createConvolveNoneShaderEffect(
    node: FeConvolveMatrixRenderNode,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    return createConvolveShaderEffect(node, 2, filterRegion, scaleX, scaleY, padX, padY, inputUniformName)
}

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
    if (size > 25 || kernel.size > 25) return null
    val shader = RuntimeShader(CONVOLVE_MATRIX_SHADER)
    val paddedKernel = FloatArray(25)
    kernel.copyInto(paddedKernel)
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
