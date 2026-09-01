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
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val width = filterRegion.width().toInt()
    val height = filterRegion.height().toInt()

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

    val clipLeft = ((primitiveRegion.left - filterRegion.left)).toInt().coerceIn(0, width)
    val clipTop = ((primitiveRegion.top - filterRegion.top)).toInt().coerceIn(0, height)
    val clipRight = ((primitiveRegion.right - filterRegion.left)).toInt().coerceIn(0, width)
    val clipBottom = ((primitiveRegion.bottom - filterRegion.top)).toInt().coerceIn(0, height)

    var baseFrequencyX = baseX
    var baseFrequencyY = baseY
    var periodX = 0
    var periodY = 0

    if (primitive.stitchTiles == FeStitchTiles.stitch) {
        val tileWidthPx = primitiveRegion.width().toDouble() * canvasScaleX.toDouble()
        val tileHeightPx = primitiveRegion.height().toDouble() * canvasScaleY.toDouble()

        if (tileWidthPx > 0.0 && baseX != 0.0) {
            val freqPx = baseX * invCanvasScaleX / primitiveUnitSizeX
            val fLo = floor(tileWidthPx * freqPx) / tileWidthPx
            val fHi = ceil(tileWidthPx * freqPx) / tileWidthPx
            val adjustedFreqPx = if (freqPx / fLo < fHi / freqPx) fLo else fHi
            baseFrequencyX = adjustedFreqPx / invCanvasScaleX * primitiveUnitSizeX
            periodX = (tileWidthPx * adjustedFreqPx + 0.5).toInt()
        }
        if (tileHeightPx > 0.0 && baseY != 0.0) {
            val freqPx = baseY * invCanvasScaleY / primitiveUnitSizeY
            val fLo = floor(tileHeightPx * freqPx) / tileHeightPx
            val fHi = ceil(tileHeightPx * freqPx) / tileHeightPx
            val adjustedFreqPx = if (freqPx / fLo < fHi / freqPx) fLo else fHi
            baseFrequencyY = adjustedFreqPx / invCanvasScaleY * primitiveUnitSizeY
            periodY = (tileHeightPx * adjustedFreqPx + 0.5).toInt()
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
