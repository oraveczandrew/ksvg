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

import android.graphics.BitmapShader
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.filters.getOrCreateLinearMatrix

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
 * Builds the color-matrix step of an Impl33 chain, dispatching to the
 * linear-light or the sRGB factory. The caller remaps [primitiveRegion] to
 * buffer space, chains the effect onto the primitive input and registers
 * the returned shader.
 *
 * @param node the color-matrix render node (mode, matrix values)
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createColorMatrixShaderEffect(
    node: FeColorMatrixRenderNode,
    primitiveRegion: RectF,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    // Linear-light matrix runs linearized (like the arithmetic path); the
    // sRGB shader below is gamma-space only.
    return if (node.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB) {
        createLinearColorMatrixShaderEffect(
            matrix = node.getOrCreateLinearMatrix(),
            primitiveRegion = primitiveRegion,
            inputUniformName = inputUniformName,
        )
    } else {
        val matrix = buildColorMatrix(node.sourceElement.type, node.sourceElement.values)
        createColorMatrixShaderEffect(
            matrix = matrix.array,
            primitiveRegion = primitiveRegion,
            inputUniformName = inputUniformName,
        )
    }
}

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

/**
 * Linear-light color matrix: like [createColorMatrixShaderEffect] but the
 * matrix runs linearized with an sRGB EOTF on the output, mirroring the CPU
 * `useLinear` path. The matrix is in SVG semantics (channels and offsets as
 * 0..1 fractions — the raw `buildColorMatrixValues` output, NOT the
 * android-scaled `buildColorMatrix` array).
 */
private const val LINEAR_COLOR_MATRIX_SHADER: String = """
            uniform shader uInput;
            uniform shader uLutLin;
            uniform float uMatrix[20];
            uniform float4 uPrimitiveRegion;
            float3 toLinear(float3 c) {
                return float3(
                    uLutLin.eval(float2(c.r * 255.0 + 0.5, 0.5)).r,
                    uLutLin.eval(float2(c.g * 255.0 + 0.5, 0.5)).g,
                    uLutLin.eval(float2(c.b * 255.0 + 0.5, 0.5)).b
                );
            }
            // Linear->sRGB EOTF matching the CPU linearToSrgb table
            // (threshold branch identical; float rounding may differ by 1 LSB
            // at table rounding boundaries).
            float3 srgbEotf(float3 c) {
                float3 lo = c * 12.92;
                float3 hi = 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055;
                return float3(
                    c.r <= 0.0031308 ? lo.r : hi.r,
                    c.g <= 0.0031308 ? lo.g : hi.g,
                    c.b <= 0.0031308 ? lo.b : hi.b
                );
            }
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w) {
                    return half4(0.0);
                }
                float4 c = uInput.eval(fragCoord);
                float alpha = c.a;
                float3 rgb = alpha > 0.0 ? c.rgb / alpha : float3(0.0);
                float3 lin = toLinear(rgb);
                float3 res;
                res.r = uMatrix[0]*lin.r + uMatrix[1]*lin.g + uMatrix[2]*lin.b + uMatrix[3]*alpha + uMatrix[4];
                res.g = uMatrix[5]*lin.r + uMatrix[6]*lin.g + uMatrix[7]*lin.b + uMatrix[8]*alpha + uMatrix[9];
                res.b = uMatrix[10]*lin.r + uMatrix[11]*lin.g + uMatrix[12]*lin.b + uMatrix[13]*alpha + uMatrix[14];
                float a = uMatrix[15]*lin.r + uMatrix[16]*lin.g + uMatrix[17]*lin.b + uMatrix[18]*alpha + uMatrix[19];
                res = clamp(res, 0.0, 1.0);
                a = clamp(a, 0.0, 1.0);
                float3 eotf = srgbEotf(floor(res * 255.0 + 0.5) / 255.0);
                return half4(eotf * a, a);
            }
        """

/**
 * Builds the linear-light color-matrix step of an Impl33 chain: the
 * configured [RuntimeShader] (kept by the caller for downstream
 * `resultShaders` lookups) plus the [RenderEffect] wrapping it under
 * [inputUniformName].
 *
 * @param matrix the 20-float color matrix in SVG 0..1 semantics (see
 * `buildColorMatrixValues`)
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createLinearColorMatrixShaderEffect(
    matrix: FloatArray,
    primitiveRegion: RectF,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(LINEAR_COLOR_MATRIX_SHADER)
    shader.setFloatUniform("uMatrix", matrix)
    shader.setInputShader(
        "uLutLin",
        BitmapShader(linearTransferLut, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP),
    )
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
