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

private const val FLOOD_SHADER: String = """
            uniform shader uInput;
            layout(color) uniform half4 uColor;
            uniform float4 uPrimitiveRegion;
            half4 main(float2 fragCoord) {
                // fragCoord samples pixel centers: keep exactly the pixels the CPU
                // kernels keep (their clip rects truncate region bounds to ints).
                // The ±1e-3 slack keeps exact-boundary centers (knife-edge
                // strict comparisons flip them via per-pixel fragCoord dust
                // on Adreno — measured: scattered transparent pixels along
                // the top row); true outsiders sit a full pixel away.
                if (fragCoord.x < floor(uPrimitiveRegion.x) + 0.5 - 1e-3 ||
                    fragCoord.x > ceil(uPrimitiveRegion.z) - 0.5 + 1e-3 ||
                    fragCoord.y < floor(uPrimitiveRegion.y) + 0.5 - 1e-3 ||
                    fragCoord.y > ceil(uPrimitiveRegion.w) - 0.5 + 1e-3) {
                    return half4(0.0);
                }
                return uColor;
            }
        """

/**
 * Builds the flood step of an Impl33 chain: the configured [RuntimeShader]
 * (kept by the caller for downstream `resultShaders` lookups) plus the
 * [RenderEffect] wrapping it under [inputUniformName].
 *
 * Flood is generative: the returned effect is NOT chained onto the
 * primitive input (there is none — the color fills the primitive region).
 *
 * @param color the resolved flood color as an ARGB int
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller)
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createFloodShaderEffect(
    color: Int,
    primitiveRegion: RectF,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(FLOOD_SHADER)
    shader.setColorUniform("uColor", color)
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
