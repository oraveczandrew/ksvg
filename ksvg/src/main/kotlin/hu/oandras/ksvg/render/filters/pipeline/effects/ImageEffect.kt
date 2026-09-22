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
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.render.FeImageRenderNode

/**
 * Raster `feImage` step: samples the decoded image bitmap pinned at the
 * filter-region origin (mirroring the CPU kernel, which returns the bitmap
 * unscaled and unclipped), transparent outside the image bounds (the CPU
 * output carries no content there either — verified against the software
 * bitmap, C20 precedent). Edge clamping inside the bounds is exact at
 * integer texel centers.
 *
 * Premultiplied note (standard across this package): the GPU texture
 * upload premultiplies, so translucent raster sources read back darker
 * than the CPU straight bytes. Round-B/C image inputs stay opaque
 * (`opaqueInput`), where premultiplied == straight and the comparison is
 * exact.
 */
private const val IMAGE_SHADER: String = """
            // uInput is declared (not read): the effect wrapper binds the
            // chain input under this name, and an undeclared uniform aborts
            // in nativeCreateRuntimeShaderEffect (C20 lesson). The primitive
            // is generative; the pixels come from uImage alone.
            uniform shader uInput;
            uniform shader uImage;
            uniform float2 uOffset;
            uniform float4 uImageRect;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uImageRect.x || fragCoord.x >= uImageRect.z ||
                    fragCoord.y < uImageRect.y || fragCoord.y >= uImageRect.w) {
                    return half4(0.0);
                }
                return uImage.eval(fragCoord - uOffset);
            }
        """

/**
 * Builds the image step of an Impl33 chain: the configured [RuntimeShader]
 * (kept by the caller for downstream `resultShaders` lookups) plus the
 * [RenderEffect] wrapping it under [inputUniformName].
 *
 * The primitive is generative (ignores its input): the caller registers
 * the shader but does NOT chain the effect. Returns null when there is no
 * decoded bitmap (missing file, unresolvable href — including element
 * references, whose `referencedNode` only the CPU backend rasterizes
 * (F10)): the caller declines so software renders instead.
 *
 * @param node the image render node (decoded bitmap)
 * @param padX padY the device-space padding of the filter region top-left
 * (bitmap index space starts here, like the turbulence `uOffset`; the
 * image bounds are `pad + bitmap size`, device px == bitmap px — the CPU
 * returns the bitmap unscaled)
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createImageShaderEffect(
    node: FeImageRenderNode,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    val image = node.image ?: return null
    val shader = RuntimeShader(IMAGE_SHADER)
    shader.setInputShader(
        "uImage",
        BitmapShader(image, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP),
    )
    shader.setFloatUniform("uOffset", padX.toFloat(), padY.toFloat())
    shader.setFloatUniform(
        "uImageRect",
        padX.toFloat(),
        padY.toFloat(),
        (padX + image.width).toFloat(),
        (padY + image.height).toFloat(),
    )
    return shader to RenderEffect.createRuntimeShaderEffect(shader, inputUniformName)
}
