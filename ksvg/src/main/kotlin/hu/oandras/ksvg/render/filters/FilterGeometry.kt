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
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.FeMorphologyOperator
import hu.oandras.ksvg.dom.SvgObject.FeConvolveMatrix
import hu.oandras.ksvg.dom.SvgObject.FeGaussianBlur
import hu.oandras.ksvg.dom.SvgObject.FeMorphology
import hu.oandras.ksvg.dom.SvgObject.FeOffset
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.createBitmapSameAs
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.sampleCoordinate
import hu.oandras.ksvg.utils.stackBlur
import kotlin.math.max
import kotlin.math.min

internal fun doFeOffsetFilter(
    renderContext: RenderContext,
    primitive: FeOffset,
    inputBitmap: Bitmap,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val dx = filterPrimitiveLengthX(renderContext, primitive.dx, primitiveUnitsAreUser, primitiveScaleX, canvasScaleX)
    val dy = filterPrimitiveLengthY(renderContext, primitive.dy, primitiveUnitsAreUser, primitiveScaleY, canvasScaleY)
    val res = createBitmapSameAs(inputBitmap)
    val c = Canvas(res)
    c.drawBitmap(inputBitmap, dx, dy, null)
    return res
}

@SuppressLint("UseKtx")
internal fun doFeConvolveMatrixFilter(primitive: FeConvolveMatrix, inputBitmap: Bitmap): Bitmap {
    val orderX = max(primitive.orderX, 1)
    val orderY = max(primitive.orderY, 1)
    val kernel = primitive.kernelMatrix
    val kernelSize = orderX * orderY
    if (kernel == null || kernel.size != kernelSize) {
        return inputBitmap
    }

    val targetX = clamp(primitive.targetX ?: (orderX / 2), 0, orderX - 1)
    val targetY = clamp(primitive.targetY ?: (orderY / 2), 0, orderY - 1)
    val divisor = if (primitive.divisor != 0f) primitive.divisor else (kernel.sum().takeIf { it != 0f } ?: 1f)
    val bias = primitive.bias
    val preserveAlpha = primitive.preserveAlpha
    val edgeMode = primitive.edgeMode

    val width = inputBitmap.width
    val height = inputBitmap.height
    val res = createBitmapSameAs(inputBitmap)
    val srcPixels = IntArray(width * height)
    val outPixels = IntArray(width * height)
    inputBitmap.getPixels(srcPixels, 0, width, 0, 0, width, height)

    for (y in 0 until height) {
        val rowOffset = y * width
        for (x in 0 until width) {
            var r = 0f
            var g = 0f
            var b = 0f
            var a = 0f

            for (ky in 0 until orderY) {
                for (kx in 0 until orderX) {
                    val srcX = sampleCoordinate(x + kx - targetX, width, edgeMode)
                    val srcY = sampleCoordinate(y + ky - targetY, height, edgeMode)
                    val pixel = if (srcX < 0 || srcY < 0) 0 else srcPixels[srcY * width + srcX]
                    val weight = kernel[ky * orderX + kx]

                    r += pixel.red * weight
                    g += pixel.green * weight
                    b += pixel.blue * weight
                    a += pixel.alpha * weight
                }
            }

            val outR = clamp255(r / divisor + bias * 255f)
            val outG = clamp255(g / divisor + bias * 255f)
            val outB = clamp255(b / divisor + bias * 255f)
            val outA = if (preserveAlpha) srcPixels[rowOffset + x].alpha else clamp255(a / divisor + bias * 255f)
            outPixels[rowOffset + x] = argb(outA, outR, outG, outB)
        }
    }
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

internal fun doFeGaussianBlurFilter(
    primitive: FeGaussianBlur,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
): Bitmap {
    val stdDeviationX = primitive.stdDeviationX * primitiveScaleX
    val stdDeviationY = primitive.stdDeviationY * primitiveScaleY

    if (stdDeviationX <= 0f && stdDeviationY <= 0f) {
        return inputBitmap
    }

    val rx = max((stdDeviationX * 2.5f + 0.5f).toInt(), 0)
    val ry = max((stdDeviationY * 2.5f + 0.5f).toInt(), 0)

    val width = inputBitmap.width
    val height = inputBitmap.height
    val pixels = IntArray(width * height)
    inputBitmap.getPixels(pixels, 0, width, 0, 0, width, height)

    if (rx > 0) {
        stackBlur(pixels, width, height, rx, true)
    }
    if (ry > 0) {
        stackBlur(pixels, width, height, ry, false)
    }

    val res = createBitmapSameAs(inputBitmap)
    res.setPixels(pixels, 0, width, 0, 0, width, height)
    return res
}

internal fun doFeMorphologyFilter(
    primitive: FeMorphology,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
): Bitmap {
    val radiusX = (primitive.radiusX * primitiveScaleX).ceilToInt()
    val radiusY = (primitive.radiusY * primitiveScaleY).ceilToInt()
    return applyMorphology(inputBitmap, radiusX, radiusY, primitive.operator == FeMorphologyOperator.erode)
}

internal fun doFeTileFilter(
    inputBitmap: Bitmap,
): Bitmap = applyTile(inputBitmap)

private fun filterPrimitiveLengthX(
    renderContext: RenderContext,
    length: CSSLength?,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleX: Float,
    canvasScaleX: Float,
): Float {
    if (length == null) return 0f
    return if (primitiveUnitsAreUser) {
        length.floatValueX(renderContext) * canvasScaleX
    } else {
        length.floatValue(renderContext, 1f) * primitiveScaleX
    }
}

private fun filterPrimitiveLengthY(
    renderContext: RenderContext,
    length: CSSLength?,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleY: Float,
    canvasScaleY: Float,
): Float {
    if (length == null) return 0f
    return if (primitiveUnitsAreUser) {
        length.floatValueY(renderContext) * canvasScaleY
    } else {
        length.floatValue(renderContext, 1f) * primitiveScaleY
    }
}

private fun applyMorphology(input: Bitmap, radiusX: Int, radiusY: Int, erode: Boolean): Bitmap {
    if (radiusX <= 0 && radiusY <= 0) {
        return input
    }

    val width = input.width
    val height = input.height
    val src = IntArray(width * height)
    input.getPixels(src, 0, width, 0, 0, width, height)
    val dst = IntArray(width * height)

    val channelInitialValue = if (erode) 255 else 0

    for (y in 0 until height) {
        val rowOffset = y * width
        val top = max(0, y - radiusY)
        val bottom = min(height - 1, y + radiusY)
        for (x in 0 until width) {
            var a = channelInitialValue
            var r = channelInitialValue
            var g = channelInitialValue
            var b = channelInitialValue
            val left = max(0, x - radiusX)
            val right = min(width - 1, x + radiusX)
            for (ky in top..bottom) {
                val kRowOffset = ky * width
                for (kx in left..right) {
                    val color = src[kRowOffset + kx]
                    if (erode) {
                        a = min(a, color.alpha)
                        r = min(r, color.red)
                        g = min(g, color.green)
                        b = min(b, color.blue)
                    } else {
                        a = max(a, color.alpha)
                        r = max(r, color.red)
                        g = max(g, color.green)
                        b = max(b, color.blue)
                    }
                }
            }
            dst[rowOffset + x] = argb(a, r, g, b)
        }
    }

    val res = createBitmapSameAs(input)
    res.setPixels(dst, 0, width, 0, 0, width, height)
    return res
}

private fun applyTile(input: Bitmap): Bitmap {
    val res = createBitmapSameAs(input)
    val c = Canvas(res)
    var y = 0f
    while (y < res.height) {
        var x = 0f
        while (x < res.width) {
            c.drawBitmap(input, x, y, null)
            x += input.width
        }
        y += input.height
    }
    return res
}
