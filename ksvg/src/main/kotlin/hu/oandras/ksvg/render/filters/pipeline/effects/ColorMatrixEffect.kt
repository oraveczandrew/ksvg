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
 * Straight-tap color matrix with premultiplied output, clipped to
 * `uPrimitiveRegion` (transparent outside — mirrors the CPU kernel, which
 * clipRects to the primitive region).
 */
private const val COLOR_MATRIX_SHADER: String = """
            uniform shader uInput;
            uniform float uMatrix[20];
            uniform float4 uPrimitiveRegion;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w) {
                    return half4(0.0);
                }
                float4 c = uInput.eval(fragCoord);
                float alpha = c.a;
                if (alpha > 0.0) c.rgb /= alpha;
                float4 res;
                res.r = uMatrix[0]*c.r + uMatrix[1]*c.g + uMatrix[2]*c.b + uMatrix[3]*c.a + uMatrix[4]/255.0;
                res.g = uMatrix[5]*c.r + uMatrix[6]*c.g + uMatrix[7]*c.b + uMatrix[8]*c.a + uMatrix[9]/255.0;
                res.b = uMatrix[10]*c.r + uMatrix[11]*c.g + uMatrix[12]*c.b + uMatrix[13]*c.a + uMatrix[14]/255.0;
                res.a = uMatrix[15]*c.r + uMatrix[16]*c.g + uMatrix[17]*c.b + uMatrix[18]*c.a + uMatrix[19]/255.0;
                res = clamp(res, 0.0, 1.0);
                return half4(res.r * res.a, res.g * res.a, res.b * res.a, res.a);
            }
        """

/**
 * Builds the color-matrix step of an Impl33 chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * The caller chains the effect onto the primitive input and registers the
 * shader; the 20-float matrix comes from `buildColorMatrix` (same values
 * the CPU kernel uses).
 *
 * @param matrix the 20-float color matrix in row-major RGBA+offset order
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createColorMatrixShaderEffect(
    matrix: FloatArray,
    primitiveRegion: RectF,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(COLOR_MATRIX_SHADER)
    shader.setFloatUniform("uMatrix", matrix)
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
