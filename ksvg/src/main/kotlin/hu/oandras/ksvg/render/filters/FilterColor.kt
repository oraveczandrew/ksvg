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

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import hu.oandras.ksvg.dom.FeColorMatrixType
import hu.oandras.ksvg.dom.FeFuncType
import hu.oandras.ksvg.dom.SvgObject.FeColorMatrix
import hu.oandras.ksvg.dom.SvgObject.FeComponentTransfer
import hu.oandras.ksvg.dom.SvgObject.FeFunc
import hu.oandras.ksvg.render.SVGAndroidRenderer.Companion.LUMINANCE_TO_ALPHA_BLUE
import hu.oandras.ksvg.render.SVGAndroidRenderer.Companion.LUMINANCE_TO_ALPHA_GREEN
import hu.oandras.ksvg.render.SVGAndroidRenderer.Companion.LUMINANCE_TO_ALPHA_RED
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.createBitmapSameAs
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.sin

internal fun doFeColorMatrixFilter(primitive: FeColorMatrix, inputBitmap: Bitmap): Bitmap {
    val res = createBitmapSameAs(inputBitmap)
    val c = Canvas(res)
    val paint = Paint()
    val cm = when (primitive.type) {
        FeColorMatrixType.matrix -> {
            val values = primitive.values?.copyOf() ?: floatArrayOf(
                1f, 0f, 0f, 0f, 0f,
                0f, 1f, 0f, 0f, 0f,
                0f, 0f, 1f, 0f, 0f,
                0f, 0f, 0f, 1f, 0f
            )
            if (values.size >= 20) {
                values[4] *= 255f
                values[9] *= 255f
                values[14] *= 255f
                values[19] *= 255f
            }
            ColorMatrix(values)
        }

        FeColorMatrixType.saturate -> ColorMatrix().apply { setSaturation(primitive.values?.get(0) ?: 1f) }
        FeColorMatrixType.hueRotate -> ColorMatrix(createHueRotateMatrix(primitive.values?.get(0) ?: 0f))
        FeColorMatrixType.luminanceToAlpha -> ColorMatrix(
            floatArrayOf(
                0f, 0f, 0f, 0f, 0f,
                0f, 0f, 0f, 0f, 0f,
                0f, 0f, 0f, 0f, 0f,
                LUMINANCE_TO_ALPHA_RED, LUMINANCE_TO_ALPHA_GREEN, LUMINANCE_TO_ALPHA_BLUE, 0f, 0f
            )
        )
    }
    paint.setColorFilter(ColorMatrixColorFilter(cm))
    c.drawBitmap(inputBitmap, 0f, 0f, paint)
    return res
}

internal fun doFeComponentTransferFilter(
    primitive: FeComponentTransfer,
    inputBitmap: Bitmap,
): Bitmap = applyComponentTransfer(inputBitmap, primitive)

private fun createHueRotateMatrix(degrees: Float): FloatArray {
    val angle = degrees.toRadians()
    val cos = cos(angle)
    val sin = sin(angle)
    val r = LUMINANCE_TO_ALPHA_RED
    val g = LUMINANCE_TO_ALPHA_GREEN
    val b = LUMINANCE_TO_ALPHA_BLUE
    return floatArrayOf(
        r + cos * (1f - r) + sin * -r,
        g + cos * -g + sin * -g,
        b + cos * -b + sin * (1f - b),
        0f,
        0f,
        r + cos * -r + sin * 0.143f,
        g + cos * (1f - g) + sin * 0.140f,
        b + cos * -b + sin * -0.283f,
        0f,
        0f,
        r + cos * -r + sin * -(1f - r),
        g + cos * -g + sin * g,
        b + cos * (1f - b) + sin * b,
        0f,
        0f,
        0f,
        0f,
        0f,
        1f,
        0f
    )
}

private fun applyComponentTransfer(input: Bitmap, primitive: FeComponentTransfer): Bitmap {
    val funcs = Array<FeFunc?>(4) { null }
    primitive.getChildren().forEachElement { child ->
        if (child is FeFunc) {
            when (child.channel) {
                FeFunc.Channel.R -> funcs[0] = child
                FeFunc.Channel.G -> funcs[1] = child
                FeFunc.Channel.B -> funcs[2] = child
                FeFunc.Channel.A -> funcs[3] = child
            }
        }
    }

    val width = input.width
    val height = input.height
    val pixels = IntArray(width * height)
    val outPixels = IntArray(width * height)
    input.getPixels(pixels, 0, width, 0, 0, width, height)
    for (i in pixels.indices) {
        val color = pixels[i]
        outPixels[i] = argb(
            alpha = applyTransferFunction(color.alpha, funcs[3]),
            red = applyTransferFunction(color.red, funcs[0]),
            green = applyTransferFunction(color.green, funcs[1]),
            blue = applyTransferFunction(color.blue, funcs[2]),
        )
    }

    val res = createBitmapSameAs(input)
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

private fun applyTransferFunction(value: Int, func: FeFunc?): Int {
    if (func == null || func.type == FeFuncType.identity) return value
    val x = value / 255f
    val y = when (func.type) {
        FeFuncType.table -> interpolateTable(x, func.tableValues)
        FeFuncType.discrete -> discreteTable(x, func.tableValues)
        FeFuncType.linear -> func.slope * x + func.intercept
        FeFuncType.gamma -> func.amplitude * x.pow(func.exponent) + func.offset
        FeFuncType.identity -> x
    }
    return clamp255(y * 255f)
}

private fun interpolateTable(x: Float, tableValues: FloatArray?): Float {
    if (tableValues == null || tableValues.isEmpty()) return x
    if (tableValues.size == 1) return tableValues[0]
    val scaled = clamp(x, 0f, 1f) * (tableValues.size - 1)
    val index = clamp(
        n = floor(scaled).toInt(),
        min = 0,
        max = tableValues.size - 2
    )
    val fraction = scaled - index
    return tableValues[index] + fraction * (tableValues[index + 1] - tableValues[index])
}

private fun discreteTable(x: Float, tableValues: FloatArray?): Float {
    if (tableValues == null || tableValues.isEmpty()) return x
    val index = clamp(
        n = floor(clamp(x, 0f, 1f) * tableValues.size).toInt(),
        min = 0,
        max = tableValues.size - 1
    )
    return tableValues[index]
}
