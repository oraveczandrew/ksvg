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
import android.graphics.Paint
import android.graphics.RectF
import hu.oandras.ksvg.compat.XFerModes
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.filter.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.render.FeConvolveMatrixRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeMorphologyRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.withClip
import hu.oandras.ksvg.filtering.ConvolveNative
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import kotlin.math.max
import kotlin.math.min

context(renderContext: RenderContext)
internal fun doFeOffsetFilter(
    primitiveNode: FeOffsetRenderNode,
    inputBitmap: Bitmap,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap {
    val sourceElement = primitiveNode.sourceElement
    val dx = filterPrimitiveLengthX(sourceElement.dx, primitiveUnitsAreUser, primitiveScaleX, canvasScaleX)
    val dy = filterPrimitiveLengthY(sourceElement.dy, primitiveUnitsAreUser, primitiveScaleY, canvasScaleY)
    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val clipLeft = (primitiveRegion.left - filterRegion.left)
        val clipTop = (primitiveRegion.top - filterRegion.top)
        val clipRight = (primitiveRegion.right - filterRegion.left)
        val clipBottom = (primitiveRegion.bottom - filterRegion.top)
        c.clipRect(clipLeft, clipTop, clipRight, clipBottom)
        c.drawBitmap(inputBitmap, dx, dy, null)
    }
    return res
}

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
internal fun doFeConvolveMatrixFilter(
    primitiveNode: FeConvolveMatrixRenderNode,
    inputBitmap: Bitmap,
): Bitmap {
    val orderX = primitiveNode.orderX
    val orderY = primitiveNode.orderY
    val kernel = primitiveNode.kernel
    val kernelSize = orderX * orderY
    if (kernel == null || kernel.size != kernelSize) {
        return inputBitmap
    }

    val targetX = primitiveNode.targetX
    val targetY = primitiveNode.targetY
    val divisor = primitiveNode.divisor
    val bias = primitiveNode.bias
    val preserveAlpha = primitiveNode.preserveAlpha
    val edgeMode = primitiveNode.edgeMode

    val width = inputBitmap.width
    val height = inputBitmap.height
    val size = width * height
    val srcPixels = primitiveNode.srcPixels.getWithSize(size)
    val outPixels = primitiveNode.outPixels.getWithSize(size)

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    inputBitmap.getPixels(srcPixels, 0, width, 0, 0, width, height)

    if (ConvolveNative.isAvailable) {
        ConvolveNative.apply(
            srcPixels, outPixels, width, height,
            kernel, orderX, orderY, targetX, targetY,
            divisor, bias, preserveAlpha, edgeMode.ordinal
        )
    } else {
        doConvolveMatrixKotlin(
            srcPixels, outPixels, width, height,
            kernel, orderX, orderY, targetX, targetY,
            divisor, bias, preserveAlpha, edgeMode
        )
    }
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

/**
 * Reference scalar loop kept as the JVM/Robolectric fallback; the native kernel
 * in `convolve_matrix.cpp` must stay bit-exact with this implementation.
 */
private fun doConvolveMatrixKotlin(
    srcPixels: IntArray,
    outPixels: IntArray,
    width: Int,
    height: Int,
    kernel: FloatArray,
    orderX: Int,
    orderY: Int,
    targetX: Int,
    targetY: Int,
    divisor: Float,
    bias: Float,
    preserveAlpha: Boolean,
    edgeMode: ConvolveMatrixEdgeMode,
) {
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
}

context(renderContext: RenderContext)
internal fun doFeGaussianBlurFilter(
    primitiveNode: FeGaussianBlurRenderNode,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val stdDeviationX = primitiveNode.stdDeviationX * primitiveScaleX
    val stdDeviationY = primitiveNode.stdDeviationY * primitiveScaleY

    if (stdDeviationX <= 0f && stdDeviationY <= 0f) {
        return inputBitmap
    }

    val width = inputBitmap.width
    val height = inputBitmap.height
    val size = width * height
    val pixels = primitiveNode.pixels.getWithSize(size)
    inputBitmap.getPixels(pixels, 0, width, 0, 0, width, height)

    primitiveNode.blurScratch.blur(pixels, width, height, stdDeviationX, stdDeviationY)

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    res.setPixels(pixels, 0, width, 0, 0, width, height)

    val clipLeft = ((primitiveRegion.left - filterRegion.left)).toInt()
    val clipTop = ((primitiveRegion.top - filterRegion.top)).toInt()
    val clipRight = ((primitiveRegion.right - filterRegion.left)).toInt()
    val clipBottom = ((primitiveRegion.bottom - filterRegion.top)).toInt()

    if (clipLeft > 0 || clipTop > 0 || clipRight < width || clipBottom < height) {
        val clearPaint = Paint()
        clearPaint.xfermode = XFerModes.Clear
        renderContext.canvasPool.withPooledObject { c ->
            c.setBitmap(res)
            // Clear top
            if (clipTop > 0) c.drawRect(0f, 0f, width.toFloat(), clipTop.toFloat(), clearPaint)
            // Clear bottom
            if (clipBottom < height) c.drawRect(0f, clipBottom.toFloat(), width.toFloat(), height.toFloat(), clearPaint)
            // Clear left
            if (clipLeft > 0) c.drawRect(0f, clipTop.toFloat(), clipLeft.toFloat(), clipBottom.toFloat(), clearPaint)
            // Clear right
            if (clipRight < width) c.drawRect(clipRight.toFloat(), clipTop.toFloat(), width.toFloat(), clipBottom.toFloat(), clearPaint)
        }
    }
    return res
}

context(renderContext: RenderContext)
internal fun doFeMorphologyFilter(
    primitiveNode: FeMorphologyRenderNode,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val radiusX = (primitive.radiusX * primitiveScaleX).ceilToInt()
    val radiusY = (primitive.radiusY * primitiveScaleY).ceilToInt()
    return applyMorphology(inputBitmap, radiusX, radiusY, primitiveNode.erode, primitiveNode, primitiveRegion, filterRegion, canvasScaleX, canvasScaleY)
}

context(renderContext: RenderContext)
internal fun doFeTileFilter(
    inputBitmap: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap = applyTile(
    input = inputBitmap,
    primitiveRegion = primitiveRegion,
    filterRegion = filterRegion,
    canvasScaleX = canvasScaleX,
    canvasScaleY = canvasScaleY,
)

context(renderContext: RenderContext)
private fun filterPrimitiveLengthX(
    length: CSSLength?,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleX: Float,
    canvasScaleX: Float,
): Float {
    return when {
        length == null -> 0f
        primitiveUnitsAreUser -> {
            length.floatValueXInContext() * canvasScaleX
        }
        else -> {
            length.floatValueInContext(1f) * primitiveScaleX
        }
    }
}

context(renderContext: RenderContext)
private fun filterPrimitiveLengthY(
    length: CSSLength?,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleY: Float,
    canvasScaleY: Float,
): Float {
    if (length == null) return 0f
    return if (primitiveUnitsAreUser) {
        length.floatValueYInContext() * canvasScaleY
    } else {
        length.floatValueInContext(1f) * primitiveScaleY
    }
}

context(renderContext: RenderContext)
private fun applyMorphology(
    input: Bitmap,
    radiusX: Int,
    radiusY: Int,
    erode: Boolean,
    primitiveNode: FeMorphologyRenderNode,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    if (radiusX <= 0 && radiusY <= 0) {
        return input
    }

    val width = input.width
    val height = input.height
    val size = width * height
    val src = primitiveNode.srcPixels.getWithSize(size)
    input.getPixels(src, 0, width, 0, 0, width, height)
    val dst = primitiveNode.dstPixels.getWithSize(size)

    val clipLeft = clamp(((primitiveRegion.left - filterRegion.left)).toInt(), 0, width)
    val clipTop = clamp(((primitiveRegion.top - filterRegion.top)).toInt(), 0, height)
    val clipRight = clamp(((primitiveRegion.right - filterRegion.left)).toInt(), 0, width)
    val clipBottom = clamp(((primitiveRegion.bottom - filterRegion.top)).toInt(), 0, height)

    val channelInitialValue = if (erode) 255 else 0

    dst.fill(0) // Initialize with transparent

    for (y in clipTop until clipBottom) {
        val rowOffset = y * width
        val top = max(0, y - radiusY)
        val bottom = min(height - 1, y + radiusY)
        val kernelTouchesTopBottom = y - radiusY < 0 || y + radiusY > height - 1
        for (x in clipLeft until clipRight) {
            // Out-of-bounds input pixels are transparent black per spec. For dilation
            // they never win the max, but erosion must yield transparent black whenever
            // the kernel reaches outside the input (dst is pre-filled with 0).
            if (erode && (kernelTouchesTopBottom || x - radiusX < 0 || x + radiusX > width - 1)) {
                continue
            }
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

    val res = renderContext.bitmapPool.acquireSameAs(input)
    res.setPixels(dst, 0, width, 0, 0, width, height)
    return res
}

context(renderContext: RenderContext)
private fun applyTile(
    input: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val res = renderContext.bitmapPool.acquireSameAs(input)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val clipLeft = (primitiveRegion.left - filterRegion.left)
        val clipTop = (primitiveRegion.top - filterRegion.top)
        val clipRight = (primitiveRegion.right - filterRegion.left)
        val clipBottom = (primitiveRegion.bottom - filterRegion.top)

        c.withClip(clipLeft, clipTop, clipRight, clipBottom) {
            var y = clipTop
            while (y < clipBottom) {
                var x = clipLeft
                while (x < clipRight) {
                    c.drawBitmap(input, x, y, null)
                    x += input.width
                }
                y += input.height
            }
        }
    }
    return res
}
