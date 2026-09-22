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

/**
 * Nearest-neighbor shift with premultiplied passthrough, clipped to
 * `uPrimitiveRegion` (transparent outside — mirrors the CPU kernel, which
 * clipRects the shifted draw to the primitive region). Taps outside the
 * input extent (`uBounds`) read transparent (the CPU `drawBitmap` samples
 * transparent outside the source bitmap); Skia child sampling outside the
 * input is undefined on Adreno, so the check is explicit.
 *
 * Nearest (not bilinear) sampling matches the CPU `drawBitmap` with
 * filtering disabled, at integer and fractional offsets alike — unlike the
 * previous Skia-offset path, which additionally ignored subregions.
 */
private const val OFFSET_SHADER: String = """
            uniform shader uInput;
            uniform float2 uOffset;
            uniform float4 uPrimitiveRegion;
            uniform float4 uBounds;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w) {
                    return half4(0.0);
                }
                float2 tap = floor(fragCoord - uOffset) + 0.5;
                if (tap.x < uBounds.x - 0.5 || tap.x > uBounds.z + 0.5 ||
                    tap.y < uBounds.y - 0.5 || tap.y > uBounds.w + 0.5) {
                    return half4(0.0);
                }
                return uInput.eval(tap);
            }
        """

/**
 * Builds the offset step of an Impl33 chain: the configured [RuntimeShader]
 * (kept by the caller for downstream `resultShaders` lookups) plus the
 * [RenderEffect] wrapping it under [inputUniformName].
 *
 * The caller chains the effect onto the primitive input and registers the
 * shader. Zero offsets never reach here (passthrough at the call site).
 *
 * @param offsetX offsetY the shift in device pixels (already converted
 * from user units by the caller, matching the CPU
 * `filterPrimitiveLength` math)
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param filterRegion the filter region in user space (for the input-extent
 * bounds)
 * @param scaleX scaleY the canvas scale in device pixels per user unit
 * @param padX padY the device-space padding of the filter region top-left
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createOffsetShaderEffect(
    offsetX: Float,
    offsetY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    scaleX: Float,
    scaleY: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(OFFSET_SHADER)
    shader.setFloatUniform("uOffset", offsetX, offsetY)
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    // Input extent for the out-of-bounds transparent rule (mirrors the CPU
    // source bitmap bounds). Inset by half a texel like the convolve
    // uBounds.
    shader.setFloatUniform(
        "uBounds",
        padX + 0.5f,
        padY + 0.5f,
        padX + filterRegion.width() * scaleX - 0.5f,
        padY + filterRegion.height() * scaleY - 0.5f,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
