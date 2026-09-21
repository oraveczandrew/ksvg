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
 * Out-of-bounds taps clamp to [uBounds] (the input extent in `fragCoord`
 * space), mirroring the CPU `duplicate` path (`sampleCoordinate` clamp).
 * Skia child sampling outside the input is NOT reliably clamped (Adreno
 * reads undefined values there), so the clamp is explicit. wrap/none edge
 * modes are declined host-side (software fallback) instead.
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
            uniform float4 uBounds;
            half4 main(float2 fragCoord) {
                float4 sum = float4(0.0);
                int kx = 0;
                int ky = 0;
                for (int i = 0; i < 25; ++i) {
                    if (i >= uOrderX * uOrderY) break;
                    float2 offset = float2(float(kx - uTargetX), float(ky - uTargetY));
                    sum += uInput.eval(clamp(fragCoord + offset, uBounds.xy, uBounds.zw)) * uKernel[i];
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
 * Builds the convolve-matrix step of an Impl33 chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * Returns null when the GPU cannot serve the case (kernel larger than
 * 5x5, or a non-`duplicate` edge mode whose out-of-bounds taps the
 * shader would clamp wrongly): the caller declines the chain so the
 * software backend renders instead. The caller chains the effect onto
 * the primitive input and registers the shader.
 *
 * @param node the convolve render node (order/target/divisor/bias/
 * preserveAlpha/edgeMode/kernel)
 * @param filterRegion the filter region in user space (for the tap-clamp
 * extent)
 * @param scaleX scaleY the canvas scale in device pixels per user unit
 * @param padX padY the device-space padding of the filter region top-left
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
    val size = node.orderX * node.orderY
    val kernel = node.kernel ?: FloatArray(size)
    if (size > 25 || kernel.size > 25) return null
    // The AGSL sampling below clamps out-of-bounds taps (Skia child
    // clamping), which is only correct for edgeMode=duplicate. wrap/none
    // would silently compute the wrong edges on the GPU, so decline the
    // chain and let the software backend handle them (round-B fallback
    // coverage in GpuConvolveCorpusParityTest).
    if (node.edgeMode != ConvolveMatrixEdgeMode.duplicate) return null
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
