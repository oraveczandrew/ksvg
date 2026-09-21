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

import android.graphics.Bitmap
import android.graphics.BitmapShader
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.render.FeComponentTransferRenderNode
import hu.oandras.ksvg.render.filters.buildTransferLutTables

/**
 * Straight-then-premult transfer lookup. Out-of-`uPrimitiveRegion` pixels
 * emit transparent (mirrors the CPU kernel, which writes the clip only) —
 * without this the transfer would run over the whole filter region while
 * the reference keeps outside-clip transparent.
 */
private const val COMPONENT_TRANSFER_SHADER: String = """
            uniform shader uInput;
            uniform shader uLutRgb;
            uniform shader uLutA;
            uniform float4 uPrimitiveRegion;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x || fragCoord.x >= uPrimitiveRegion.z ||
                    fragCoord.y < uPrimitiveRegion.y || fragCoord.y >= uPrimitiveRegion.w) {
                    return half4(0.0);
                }
                float4 color = uInput.eval(fragCoord);
                float alpha = color.a;
                if (alpha > 0.0) color.rgb /= alpha;
                float r = uLutRgb.eval(float2(color.r * 255.0 + 0.5, 0.5)).r;
                float g = uLutRgb.eval(float2(color.g * 255.0 + 0.5, 0.5)).g;
                float b = uLutRgb.eval(float2(color.b * 255.0 + 0.5, 0.5)).b;
                float a = uLutA.eval(float2(color.a * 255.0 + 0.5, 0.5)).r;
                return half4(r * a, g * a, b * a, a);
            }
        """

/**
 * Builds the component-transfer step of an Impl33 chain: the configured
 * [RuntimeShader] (kept by the caller for downstream `resultShaders`
 * lookups) plus the [RenderEffect] wrapping it under [inputUniformName].
 *
 * The caller chains the effect onto the primitive input and registers the
 * shader. The transfer tables are the same LUTs the CPU kernel uses
 * (built eagerly here — on a pure-GPU render the node's lazy tables are
 * still null).
 *
 * @param node the component-transfer render node (transfer functions +
 * cached LUT/data bitmaps)
 * @param primitiveRegion the primitive subregion in buffer space (already
 * remapped from user space by the caller); the CPU kernel writes the clip
 * only
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createComponentTransferShaderEffect(
    node: FeComponentTransferRenderNode,
    primitiveRegion: RectF,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect> {
    val shader = RuntimeShader(COMPONENT_TRANSFER_SHADER)
    // NB: lutTables is lazily built by the CPU path; on a pure-GPU render it
    // is still null here, so build the real tables (same as the CPU kernel
    // uses) instead of falling back to zeros (which would zero the alpha).
    val lut = node.lutTables ?: buildTransferLutTables(
        node.transferFunctions,
        node.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB,
    ).also { node.lutTables = it }
    // Two opaque textures (RGB tables + alpha table as gray): data bitmaps
    // MUST stay opaque because GPU uploads premultiply, corrupting any data
    // byte packed into RGB wherever alpha < 255.
    var rgb = node.gpuLutBitmap
    if (rgb == null || rgb.isRecycled) {
        rgb = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
        node.gpuLutBitmap = rgb
    }
    var alpha = node.gpuLutAlphaBitmap
    if (alpha == null || alpha.isRecycled) {
        alpha = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
        node.gpuLutAlphaBitmap = alpha
    }
    val rgbPixels = IntArray(256)
    val alphaPixels = IntArray(256)
    for (i in 0 until 256) {
        val a = (lut[0][i] ushr 24) and 0xFF
        rgbPixels[i] = -0x1000000 or lut[1][i] or lut[2][i] or lut[3][i]
        alphaPixels[i] = -0x1000000 or (a shl 16) or (a shl 8) or a
    }
    rgb.setPixels(rgbPixels, 0, 256, 0, 0, 256, 1)
    alpha.setPixels(alphaPixels, 0, 256, 0, 0, 256, 1)
    shader.setInputShader("uLutRgb", BitmapShader(rgb, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
    shader.setInputShader("uLutA", BitmapShader(alpha, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
    shader.setFloatUniform(
        "uPrimitiveRegion",
        primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom,
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
