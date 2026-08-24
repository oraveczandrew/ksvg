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
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.RectF
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.filter.FeColorMatrixType
import hu.oandras.ksvg.dom.filter.FeFunc
import hu.oandras.ksvg.dom.filter.FeFuncType
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeComponentTransferRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.Renderer.Companion.LUMINANCE_TO_ALPHA_BLUE
import hu.oandras.ksvg.render.Renderer.Companion.LUMINANCE_TO_ALPHA_GREEN
import hu.oandras.ksvg.render.Renderer.Companion.LUMINANCE_TO_ALPHA_RED
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.linearToSRgb
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.sRgbToLinear
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.sin

internal val luminanceToAlphaFloatArray: FloatArray = floatArrayOf(
    0f, 0f, 0f, 0f, 0f,
    0f, 0f, 0f, 0f, 0f,
    0f, 0f, 0f, 0f, 0f,
    LUMINANCE_TO_ALPHA_RED, LUMINANCE_TO_ALPHA_GREEN, LUMINANCE_TO_ALPHA_BLUE, 0f, 0f
)

private val identity: FloatArray = floatArrayOf(
    1f, 0f, 0f, 0f, 0f,
    0f, 1f, 0f, 0f, 0f,
    0f, 0f, 1f, 0f, 0f,
    0f, 0f, 0f, 1f, 0f
)

context(renderContext: RenderContext)
internal fun doFeColorMatrixFilter(
    primitiveNode: FeColorMatrixRenderNode,
    inputBitmap: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val paint = primitiveNode.paint
        ?: createFilterPaint(
            type = primitiveNode.type,
            values = primitiveNode.values
        ).also {
            primitiveNode.paint = it
        }

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val clipLeft = (primitiveRegion.left - filterRegion.left)
        val clipTop = (primitiveRegion.top - filterRegion.top)
        val clipRight = (primitiveRegion.right - filterRegion.left)
        val clipBottom = (primitiveRegion.bottom - filterRegion.top)
        c.clipRect(clipLeft, clipTop, clipRight, clipBottom)
        c.drawBitmap(inputBitmap, 0f, 0f, paint)
    }
    return res
}

internal fun createFilterPaint(type: FeColorMatrixType, values: FloatArray?): Paint {
    val cm = when (type) {
        FeColorMatrixType.matrix -> {
            val values = (values ?: identity).copyOf()

            if (values.size >= 20) {
                values[4] *= 255f
                values[9] *= 255f
                values[14] *= 255f
                values[19] *= 255f
            }

            ColorMatrix(values)
        }

        FeColorMatrixType.saturate -> {
            ColorMatrix().apply {
                setSaturation(values?.get(0) ?: 1f)
            }
        }

        FeColorMatrixType.hueRotate -> {
            ColorMatrix(createHueRotateMatrix(values?.get(0) ?: 0f))
        }

        FeColorMatrixType.luminanceToAlpha -> ColorMatrix(luminanceToAlphaFloatArray)
    }

    val paint = Paint()
    paint.setColorFilter(ColorMatrixColorFilter(cm))
    return paint
}

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

context(renderContext: RenderContext)
internal fun doFeComponentTransferFilter(
    inputBitmap: Bitmap,
    primitiveNode: FeComponentTransferRenderNode,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val transferFunctions = primitiveNode.transferFunctions

    val width = inputBitmap.width
    val height = inputBitmap.height
    val size = width * height
    val pixels = primitiveNode.srcPixels.getWithSize(size)
    inputBitmap.getPixels(pixels, 0, width, 0, 0, width, height)
    val outPixels = primitiveNode.outPixels.getWithSize(size)
    
    val clipLeft = clamp(((primitiveRegion.left - filterRegion.left)).toInt(), 0, width)
    val clipTop = clamp(((primitiveRegion.top - filterRegion.top)).toInt(), 0, height)
    val clipRight = clamp(((primitiveRegion.right - filterRegion.left)).toInt(), 0, width)
    val clipBottom = clamp(((primitiveRegion.bottom - filterRegion.top)).toInt(), 0, height)

    outPixels.fill(0) // Initialize with transparent
    val useLinear = primitiveNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB

    for (y in clipTop until clipBottom) {
        val rowOffset = y * width
        for (x in clipLeft until clipRight) {
            val i = rowOffset + x
            val color = pixels[i]
            if (useLinear) {
                outPixels[i] = argb(
                    alpha = applyTransferFunction(color.alpha, transferFunctions.a),
                    red = linearToSRgb(applyTransferFunction(sRgbToLinear(color.red), transferFunctions.r)),
                    green = linearToSRgb(applyTransferFunction(sRgbToLinear(color.green), transferFunctions.g)),
                    blue = linearToSRgb(applyTransferFunction(sRgbToLinear(color.blue), transferFunctions.b)),
                )
            } else {
                outPixels[i] = argb(
                    alpha = applyTransferFunction(color.alpha, transferFunctions.a),
                    red = applyTransferFunction(color.red, transferFunctions.r),
                    green = applyTransferFunction(color.green, transferFunctions.g),
                    blue = applyTransferFunction(color.blue, transferFunctions.b),
                )
            }
        }
    }

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

private fun applyTransferFunction(value: Int, transferFunction: FeFunc?): Int {
    if (transferFunction == null || transferFunction.type == FeFuncType.identity) return value
    val x = value / 255f
    val y = when (transferFunction.type) {
        FeFuncType.table -> interpolateTable(x, transferFunction.tableValues)
        FeFuncType.discrete -> discreteTable(x, transferFunction.tableValues)
        FeFuncType.linear -> transferFunction.slope * x + transferFunction.intercept
        FeFuncType.gamma -> transferFunction.amplitude * x.pow(transferFunction.exponent) + transferFunction.offset
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
