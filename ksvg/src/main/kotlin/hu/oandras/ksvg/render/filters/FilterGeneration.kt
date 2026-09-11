/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.render.filters

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.RectF
import hu.oandras.ksvg.dom.filter.FeStitchTiles
import hu.oandras.ksvg.dom.filter.FeTurbulenceType
import hu.oandras.ksvg.filtering.SoftwareKernels
import hu.oandras.ksvg.render.FeDisplacementMapRenderNode
import hu.oandras.ksvg.render.FeImageRenderNode
import hu.oandras.ksvg.render.FeTurbulenceRenderNode
import hu.oandras.ksvg.render.FilterSourceMap
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.createBitmap
import kotlin.math.ceil
import kotlin.math.floor

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
internal fun doFeTurbulenceFilter(
    primitiveNode: FeTurbulenceRenderNode,
    @Suppress("UNUSED_PARAMETER") inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveOriginX: Float,
    primitiveOriginY: Float,
    regionLeft: Float,
    regionTop: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    filterRegionPx: RectF,
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val width = filterRegionPx.width().toInt()
    val height = filterRegionPx.height().toInt()

    val baseX = maxOf(0.0, primitive.baseFrequencyX.toDouble())
    val baseY = maxOf(0.0, primitive.baseFrequencyY.toDouble())
    val octaves = primitive.numOctaves.coerceIn(1, 8)
    val isFractal = primitive.type == FeTurbulenceType.fractalNoise
    val generators = primitiveNode.generators

    val size = width * height
    val pixels = primitiveNode.pixels.getWithSize(size)

    val invCanvasScaleX = 1.0 / canvasScaleX.toDouble()
    val invCanvasScaleY = 1.0 / canvasScaleY.toDouble()

    val userLeft = floor(regionLeft.toDouble() + 0.5)
    val userTop = floor(regionTop.toDouble() + 0.5)

    val primitiveUnitSizeX = primitiveScaleX.toDouble() / canvasScaleX.toDouble()
    val primitiveUnitSizeY = primitiveScaleY.toDouble() / canvasScaleY.toDouble()

    val clipLeft = ((primitiveRegion.left - filterRegionPx.left)).toInt().coerceIn(0, width)
    val clipTop = ((primitiveRegion.top - filterRegionPx.top)).toInt().coerceIn(0, height)
    val clipRight = ((primitiveRegion.right - filterRegionPx.left)).toInt().coerceIn(0, width)
    val clipBottom = ((primitiveRegion.bottom - filterRegionPx.top)).toInt().coerceIn(0, height)

    var baseFrequencyX = baseX
    var baseFrequencyY = baseY
    var periodX = 0
    var periodY = 0

    if (primitive.stitchTiles == FeStitchTiles.stitch) {
        // Stitch tile size = the device-pixel bounds of the primitive region
        // (the pixels this kernel fills), matching librsvg, which derives the
        // stitch tile from bounds.width()/bounds.height() of the output IRect
        // instead of from a ceil of the user-space region.
        val tileWidthPx = width.toDouble()
        val tileHeightPx = height.toDouble()

        if (tileWidthPx > 0.0 && baseX != 0.0) {
            val freq: Double = baseX
            val fLo = floor(tileWidthPx * freq) / tileWidthPx
            val fHi = ceil(tileWidthPx * freq) / tileWidthPx
            val adjustedFreq = if (freq / fLo < fHi / freq) fLo else fHi
            baseFrequencyX = adjustedFreq
            periodX = (tileWidthPx * adjustedFreq + 0.5).toInt()
        }
        if (tileHeightPx > 0.0 && baseY != 0.0) {
            val freq: Double = baseY
            val fLo = floor(tileHeightPx * freq) / tileHeightPx
            val fHi = ceil(tileHeightPx * freq) / tileHeightPx
            val adjustedFreq = if (freq / fLo < fHi / freq) fLo else fHi
            baseFrequencyY = adjustedFreq
            periodY = (tileHeightPx * adjustedFreq + 0.5).toInt()
        }
    }

    SoftwareKernels.turbulence(
        pixels, width, height,
        clipLeft, clipTop, clipRight, clipBottom,
        baseFrequencyX, baseFrequencyY, periodX, periodY,
        octaves, isFractal,
        invCanvasScaleX, invCanvasScaleY,
        userLeft, userTop, 0.0, 0.0,
        primitiveUnitSizeX, primitiveUnitSizeY,
        primitive.seed.toInt(),
        generators,
    )

    val res = renderContext.bitmapPool.acquire(width, height, Bitmap.Config.ARGB_8888)
    res.setPixels(pixels, 0, width, 0, 0, width, height)
    return res
}

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
internal fun doFeDisplacementMapFilter(
    primitiveNode: FeDisplacementMapRenderNode,
    inputBitmap: Bitmap,
    results: FilterSourceMap,
    lastResult: Bitmap?,
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val displacementMap = getFilterInput(primitive.in2, results, lastResult) ?: return inputBitmap
    val scale = primitive.scale
    if (scale == 0f) {
        return inputBitmap
    }

    val width = inputBitmap.width
    val height = inputBitmap.height
    val mapWidth = displacementMap.width
    val mapHeight = displacementMap.height
    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)

    val inputSize = width * height
    val src = primitiveNode.inputPixels.getWithSize(inputSize)
    val map = primitiveNode.mapPixels.getWithSize(mapWidth * mapHeight)
    val dst = primitiveNode.outPixels.getWithSize(inputSize)

    inputBitmap.getPixels(src, 0, width, 0, 0, width, height)
    displacementMap.getPixels(map, 0, mapWidth, 0, 0, mapWidth, mapHeight)

    SoftwareKernels.displacementMap(
        src, map, dst, width, height, mapWidth, mapHeight, scale,
        primitive.xChannelSelector.ordinal,
        primitive.yChannelSelector.ordinal
    )

    res.setPixels(dst, 0, width, 0, 0, width, height)
    return res
}

@SuppressLint("UseKtx")
internal fun doFeImageFilter(
    primitiveNode: FeImageRenderNode,
    @Suppress("UNUSED_PARAMETER") inputBitmap: Bitmap,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val bitmap = primitiveNode.image ?: return createBitmap(1, 1)
    // feImage output size is determined by its primitive subregion, but the
    // source bitmap might be different size, so we scale by the canvas (device) scale.
    return bitmap
}
