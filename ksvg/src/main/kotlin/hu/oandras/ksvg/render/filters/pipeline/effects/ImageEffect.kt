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
import hu.oandras.ksvg.render.FeImageRenderNode

/**
 * Raster `feImage` step: samples the decoded image bitmap pinned at the
 * filter-region origin (the legacy CPU shape, kept when no
 * preserveAspectRatio mapping applies — the chain caller declines
 * otherwise), transparent outside the image bounds. Edge clamping inside
 * the bounds is exact at integer texel centers.
 *
 * Premultiplied note (standard across this package): the GPU texture
 * upload premultiplies, so translucent raster sources read back darker
 * than the CPU straight bytes. Corpus image inputs stay opaque
 * (`opaqueInput`), where premultiplied == straight and the comparison is
 * exact.
 */
private const val IMAGE_SHADER: String = """
            // uInput is declared (not read): the effect wrapper binds the
            // chain input under this name, and an undeclared uniform aborts
            // effect creation. The primitive
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
 * references, whose `referencedNode` only the CPU backend rasterizes):
 * the caller declines so software renders instead.
 *
 * @param node the image render node (decoded bitmap)
 * @param primitiveRegion the primitive's user-space subregion (read only)
 * @param filterRegion the filter region in user space
 * @param sx sy the buffer scale
 * @param padX padY the device-space padding of the filter region top-left
 * (bitmap index space starts here, like the turbulence `uOffset`; the
 * image bounds are `pad + bitmap size`. Only used when the CPU output is
 * the same unscaled blit — i.e., no preserveAspectRatio mapping, subregion
 * at the region origin, matching bitmap size; returns null otherwise and
 * software renders instead)
 * @param inputUniformName the shader-input uniform name (`uInput`)
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal fun createImageShaderEffect(
    node: FeImageRenderNode,
    primitiveRegion: RectF,
    filterRegion: RectF,
    sx: Float,
    sy: Float,
    padX: Int,
    padY: Int,
    inputUniformName: String,
): Pair<RuntimeShader, RenderEffect>? {
    // Raster feImage only: element references (`referencedNode`) have no
    // decoded bitmap — only the CPU backend rasterizes them — so decline
    // and let software render instead. Pre-rasterizing into a BitmapShader
    // input is deliberately NOT done: chains are cached per element slot
    // across frames, so baked content would go stale (and freeze animations
    // inside the referenced subtree).
    //
    // preserveAspectRatio mapping lives on the CPU path only (the chain
    // draws unscaled at the region origin): decline whenever the software
    // output would differ — an explicit PAR, or a subregion that is not
    // exactly the unscaled bitmap at the region origin. Spurious declines
    // (float dust) only cost software rendering, never correctness.
    val image = node.image ?: return null
    if (node.sourceElement.preserveAspectRatio != null) {
        return null
    }
    val subLeft = (primitiveRegion.left - filterRegion.left) * sx + padX
    val subTop = (primitiveRegion.top - filterRegion.top) * sy + padY
    val subRight = (primitiveRegion.right - filterRegion.left) * sx + padX
    val subBottom = (primitiveRegion.bottom - filterRegion.top) * sy + padY
    if (subLeft != padX.toFloat() || subTop != padY.toFloat() ||
        subRight - subLeft != image.width.toFloat() ||
        subBottom - subTop != image.height.toFloat()
    ) {
        return null
    }
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
