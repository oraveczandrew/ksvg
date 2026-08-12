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
import android.graphics.Canvas
import android.util.Log
import hu.oandras.ksvg.SVGExternalFileResolver
import hu.oandras.ksvg.dom.FeTurbulenceType
import hu.oandras.ksvg.dom.SvgObject.FeDisplacementMap
import hu.oandras.ksvg.dom.SvgObject.FeImage
import hu.oandras.ksvg.dom.SvgObject.FeTurbulence
import hu.oandras.ksvg.utils.LcgRandom
import hu.oandras.ksvg.utils.SvgPathNoise
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.channelSelectorValue
import hu.oandras.ksvg.utils.checkForImageDataURL
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.createBitmap
import hu.oandras.ksvg.utils.createBitmapSameAs
import kotlin.math.abs
import kotlin.math.max

@SuppressLint("UseKtx")
internal fun doFeTurbulenceFilter(
    primitive: FeTurbulence,
    input: Bitmap?,
    lastResult: Bitmap?,
    results: Map<String, Bitmap>,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap? {
    val source = input ?: lastResult ?: results["SourceGraphic"] ?: return null
    val width = source.width
    val height = source.height
    val res = createBitmap(width, height)

    val baseX = clamp(primitive.baseFrequencyX.toDouble(), 0.0, Double.MAX_VALUE) / canvasScaleX
    val baseY = clamp(primitive.baseFrequencyY.toDouble(), 0.0, Double.MAX_VALUE) / canvasScaleY
    val octaves = clamp(primitive.numOctaves, 1, 8)
    val seed = primitive.seed
    val isFractal = primitive.type == FeTurbulenceType.fractalNoise
    val lcg = LcgRandom(if (seed <= 0) 1 else seed.toInt())

    val generators = Array(4) {
        SvgPathNoise(lcg)
    }

    val pixels = IntArray(width * height)

    for (y in 0 until height) {
        for (x in 0 until width) {
            var r = 0.0
            var g = 0.0
            var b = 0.0
            var a = 0.0

            for (channel in 0 until 4) {
                var value = 0.0
                var ratio = 1.0
                var px = x * baseX
                var py = y * baseY
                for (_ in 0 until octaves) {
                    val n = generators[channel].noise2(px, py)
                    value += if (isFractal) n / ratio else abs(n) / ratio
                    px *= 2.0
                    py *= 2.0
                    ratio *= 2.0
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
internal fun doFeDisplacementMapFilter(
    primitive: FeDisplacementMap,
    inputBitmap: Bitmap,
    results: Map<String, Bitmap>,
    lastResult: Bitmap?,
): Bitmap {
    val displacementMap = getFilterInput(primitive.in2, results, lastResult) ?: return inputBitmap
    val scale = primitive.scale
    if (scale == 0f) {
        return inputBitmap
    }

    val width = inputBitmap.width
    val height = inputBitmap.height
    val mapWidth = displacementMap.width
    val mapHeight = displacementMap.height
    val res = createBitmapSameAs(inputBitmap)

    val inputPixels = IntArray(width * height)
    inputBitmap.getPixels(inputPixels, 0, width, 0, 0, width, height)

    val mapPixels = IntArray(mapWidth * mapHeight)
    displacementMap.getPixels(mapPixels, 0, mapWidth, 0, 0, mapWidth, mapHeight)

    val outPixels = IntArray(width * height)

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
internal fun doFeImageFilter(
    primitive: FeImage,
    inputBitmap: Bitmap,
    externalFileResolver: SVGExternalFileResolver?,
): Bitmap {
    val href = primitive.href ?: return inputBitmap
    val image = checkForImageDataURL(href) ?: externalFileResolver?.resolveImage(href)

    if (image == null) {
        Log.w("doFeImageFilter", String.format("Could not locate image '%s'", href))
        return inputBitmap
    }

    val res = createBitmapSameAs(inputBitmap)
    val c = Canvas(res)
    val sx = res.width.toFloat() / image.width.toFloat()
    val sy = res.height.toFloat() / image.height.toFloat()
    c.save()
    c.scale(sx, sy)
    c.drawBitmap(image, 0f, 0f, null)
    c.restore()
    return res
}
