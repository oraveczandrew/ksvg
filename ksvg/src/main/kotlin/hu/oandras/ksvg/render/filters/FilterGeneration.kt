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
import hu.oandras.ksvg.filtering.TurbulenceNative
import hu.oandras.ksvg.render.FeDisplacementMapRenderNode
import hu.oandras.ksvg.render.FeImageRenderNode
import hu.oandras.ksvg.render.FeTurbulenceRenderNode
import hu.oandras.ksvg.render.FilterSourceMap
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
internal fun doFeTurbulenceFilter(
    primitiveNode: FeTurbulenceRenderNode,
    inputBitmap: Bitmap,
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
    val width = inputBitmap.width
    val height = inputBitmap.height
    val res = renderContext.bitmapPool.acquire(
        width = width,
        height = height,
        config = Bitmap.Config.ARGB_8888
    )

    val baseX = clamp(primitive.baseFrequencyX.toDouble(), 0.0, Double.MAX_VALUE)
    val baseY = clamp(primitive.baseFrequencyY.toDouble(), 0.0, Double.MAX_VALUE)
    val octaves = clamp(primitive.numOctaves, 1, 8)
    val isFractal = primitive.type == FeTurbulenceType.fractalNoise
    val generators = primitiveNode.generators

    val size = width * height
    val pixels = primitiveNode.pixels.getWithSize(size)

    val invCanvasScaleX = 1.0 / canvasScaleX.toDouble()
    val invCanvasScaleY = 1.0 / canvasScaleY.toDouble()
    val userLeft = regionLeft.toDouble()
    val userTop = regionTop.toDouble()
    val originX = primitiveOriginX.toDouble()
    val originY = primitiveOriginY.toDouble()

    // Frequency is cycles per primitive unit.
    // If primitiveUnits="userSpaceOnUse", 1 unit = 1 user pixel.
    // If primitiveUnits="objectBoundingBox", 1 unit = BB size.
    // primitiveScaleX / canvasScaleX is the size of 1 primitive unit in user units.
    val primitiveUnitSizeX = primitiveScaleX.toDouble() / canvasScaleX.toDouble()
    val primitiveUnitSizeY = primitiveScaleY.toDouble() / canvasScaleY.toDouble()

    val clipLeft = clamp(((primitiveRegion.left - filterRegion.left)).toInt(), 0, width)
    val clipTop = clamp(((primitiveRegion.top - filterRegion.top)).toInt(), 0, height)
    val clipRight = clamp(((primitiveRegion.right - filterRegion.left)).toInt(), 0, width)
    val clipBottom = clamp(((primitiveRegion.bottom - filterRegion.top)).toInt(), 0, height)

    // feTurbulence stitchTiles="stitch": adjust the base frequencies so the tile
    // contains a whole number of lattice cells, then sample the noise periodically
    // over that period so opposite edges match seamlessly (SVG 1.1 §15.25).
    var baseFrequencyX = baseX
    var baseFrequencyY = baseY
    var periodX = 0
    var periodY = 0
    if (primitive.stitchTiles == FeStitchTiles.stitch) {
        val tileWidthUnits = (clipRight - clipLeft) * invCanvasScaleX / primitiveUnitSizeX
        val tileHeightUnits = (clipBottom - clipTop) * invCanvasScaleY / primitiveUnitSizeY
        val stitchX = floor(tileWidthUnits * baseX + 0.5).toInt()
        val stitchY = floor(tileHeightUnits * baseY + 0.5).toInt()
        if (stitchX > 0 && stitchY > 0 && tileWidthUnits > 0.0 && tileHeightUnits > 0.0) {
            baseFrequencyX = stitchX / tileWidthUnits
            baseFrequencyY = stitchY / tileHeightUnits
            periodX = stitchX
            periodY = stitchY
        }
    }

    if (TurbulenceNative.isAvailable) {
        TurbulenceNative.apply(
            pixels, width, height,
            clipLeft, clipTop, clipRight, clipBottom,
            baseFrequencyX, baseFrequencyY, periodX, periodY,
            octaves, isFractal,
            invCanvasScaleX, invCanvasScaleY,
            userLeft, userTop, originX, originY,
            primitiveUnitSizeX, primitiveUnitSizeY,
            primitive.seed.toInt()
        )
        res.setPixels(pixels, 0, width, 0, 0, width, height)
        return res
    }

    for (y in clipTop until clipBottom) {
        val userY = userTop + y.toDouble() * invCanvasScaleY
        val py0 = ((userY - originY) / primitiveUnitSizeY) * baseFrequencyY
        for (x in clipLeft until clipRight) {
            val userX = userLeft + x.toDouble() * invCanvasScaleX
            val px0 = ((userX - originX) / primitiveUnitSizeX) * baseFrequencyX

            var r = 0.0
            var g = 0.0
            var b = 0.0
            var a = 0.0

            for (channel in 0 until 4) {
                var value = 0.0
                var ratio = 1.0
                var px = px0
                var py = py0
                var octavePeriodX = periodX
                var octavePeriodY = periodY
                for (_ in 0 until octaves) {
                    val n = generators[channel].noise2(px, py, octavePeriodX, octavePeriodY)
                    value += if (isFractal) n / ratio else abs(n) / ratio
                    px *= 2.0
                    py *= 2.0
                    ratio *= 2.0
                    octavePeriodX += octavePeriodX
                    octavePeriodY += octavePeriodY
                }
                val finalVal = if (isFractal) (value + 1.0) * 127.5 else value * 255.0
                when (channel) {
                    0 -> r = finalVal
                    1 -> g = finalVal
                    2 -> b = finalVal
                    3 -> a = finalVal
                }
            }
            pixels[y * width + x] = argb(
                clamp255(a),
                clamp255(r),
                clamp255(g),
                clamp255(b)
            )
        }
    }
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
    val inputPixels = primitiveNode.inputPixels.getWithSize(inputSize)
    inputBitmap.getPixels(inputPixels, 0, width, 0, 0, width, height)

    val mapSize = mapWidth * mapHeight
    val mapPixels = primitiveNode.mapPixels.getWithSize(mapSize)
    displacementMap.getPixels(mapPixels, 0, mapWidth, 0, 0, mapWidth, mapHeight)

    val outPixels = primitiveNode.outPixels.getWithSize(inputSize)

    val widthDivisor = max(width - 1, 1)
    val heightDivisor = max(height - 1, 1)

    for (y in 0 until height) {
        val rowOffset = y * width
        for (x in 0 until width) {
            val mapX = if (mapWidth <= 1) 0 else (x.toFloat() / widthDivisor * (mapWidth - 1)).toInt()
            val mapY = if (mapHeight <= 1) 0 else (y.toFloat() / heightDivisor * (mapHeight - 1)).toInt()
            val mapPixel = mapPixels[mapY * mapWidth + mapX]

            val dx = (scale * (channelSelectorValue(mapPixel, primitive.xChannelSelector) - 0.5f)).toInt()
            val dy = (scale * (channelSelectorValue(mapPixel, primitive.yChannelSelector) - 0.5f)).toInt()

            val srcX = clamp(x + dx, 0, width - 1)
            val srcY = clamp(y + dy, 0, height - 1)
            outPixels[rowOffset + x] = inputPixels[srcY * width + srcX]
        }
    }
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
internal fun doFeImageFilter(
    primitiveNode: FeImageRenderNode,
    inputBitmap: Bitmap,
): Bitmap {
    val image = primitiveNode.image ?: return inputBitmap

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val sx = res.width.toFloat() / image.width.toFloat()
        val sy = res.height.toFloat() / image.height.toFloat()
        c.save()
        c.scale(sx, sy)
        c.drawBitmap(image, 0f, 0f, null)
        c.restore()
    }
    return res
}
