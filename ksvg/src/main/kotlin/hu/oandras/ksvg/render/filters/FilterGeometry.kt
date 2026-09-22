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
import hu.oandras.ksvg.filtering.SoftwareKernels
import hu.oandras.ksvg.render.FeConvolveMatrixRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeMorphologyRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.withClip
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.clamp

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
        val clipLeft = primitiveRegion.left - filterRegion.left
        val clipTop = primitiveRegion.top - filterRegion.top
        val clipRight = primitiveRegion.right - filterRegion.left
        val clipBottom = primitiveRegion.bottom - filterRegion.top
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

    SoftwareKernels.convolveMatrix(
        srcPixels, outPixels, width, height,
        kernel, orderX, orderY, targetX, targetY,
        divisor, bias, preserveAlpha, edgeMode.ordinal,
    )
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}


context(renderContext: RenderContext)
internal fun doFeGaussianBlurFilter(
    primitiveNode: FeGaussianBlurRenderNode,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
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

    // The blur backends emit premultiplied (Kotlin stack-blur fallback) or
    // straight (native true-Gaussian) channels; `setPixels` below stores
    // straight. Unpremultiplying normalizes uniform regions exactly on both
    // backends (halo chroma stays full while alpha fades — F1, rsvg
    // reference); native straight edges stay approximate (premult-native is
    // a separate :filtering tétel). In place, no allocation.
    unpremultiplyInPlace(pixels)

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    res.setPixels(pixels, 0, width, 0, 0, width, height)

    val clipLeft = (primitiveRegion.left - filterRegion.left).toInt()
    val clipTop = (primitiveRegion.top - filterRegion.top).toInt()
    val clipRight = (primitiveRegion.right - filterRegion.left).toInt()
    val clipBottom = (primitiveRegion.bottom - filterRegion.top).toInt()

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

/**
 * In-place straight-normalization for blur output (F1): maps premultiplied
 * channels back to straight (`c = c*255/a`, half-up) so halo chroma survives
 * `setPixels` (straight-in store). Exact for uniform regions on both blur
 * backends (premult-out fallback; straight-out native, where uniform
 * r/a ratios restore full chroma); alpha untouched; a==0 stays 0, a==255
 * is identity. No allocation.
 */
private fun unpremultiplyInPlace(pixels: IntArray) {
    for (i in pixels.indices) {
        val p = pixels[i]
        val a = p ushr 24
        if (a == 0 || a == 255) continue
        val r = clamp(((p shr 16 and 0xff) * 255 + (a shr 1)) / a, 0, 255)
        val g = clamp(((p shr 8 and 0xff) * 255 + (a shr 1)) / a, 0, 255)
        val b = clamp(((p and 0xff) * 255 + (a shr 1)) / a, 0, 255)
        pixels[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
    }
}

context(renderContext: RenderContext)
internal fun doFeMorphologyFilter(
    primitiveNode: FeMorphologyRenderNode,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val radiusX = (primitive.radiusX * primitiveScaleX).ceilToInt()
    val radiusY = (primitive.radiusY * primitiveScaleY).ceilToInt()
    return applyMorphology(inputBitmap, radiusX, radiusY, primitiveNode.erode, primitiveNode, primitiveRegion, filterRegion)
}

context(renderContext: RenderContext)
internal fun doFeTileFilter(
    inputBitmap: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap = applyTile(
    input = inputBitmap,
    primitiveRegion = primitiveRegion,
    filterRegion = filterRegion,
)

context(renderContext: RenderContext)
internal fun filterPrimitiveLengthX(
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
internal fun filterPrimitiveLengthY(
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

    val clipLeft = clamp((primitiveRegion.left - filterRegion.left).toInt(), 0, width)
    val clipTop = clamp((primitiveRegion.top - filterRegion.top).toInt(), 0, height)
    val clipRight = clamp((primitiveRegion.right - filterRegion.left).toInt(), 0, width)
    val clipBottom = clamp((primitiveRegion.bottom - filterRegion.top).toInt(), 0, height)

    dst.fill(0) // Initialize with transparent

    SoftwareKernels.morphology(
        src, dst, width, height, radiusX, radiusY, erode,
        clipLeft, clipTop, clipRight, clipBottom,
    )

    val res = renderContext.bitmapPool.acquireSameAs(input)
    res.setPixels(dst, 0, width, 0, 0, width, height)
    return res
}


context(renderContext: RenderContext)
private fun applyTile(
    input: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap {
    val res = renderContext.bitmapPool.acquireSameAs(input)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val clipLeft = primitiveRegion.left - filterRegion.left
        val clipTop = primitiveRegion.top - filterRegion.top
        val clipRight = primitiveRegion.right - filterRegion.left
        val clipBottom = primitiveRegion.bottom - filterRegion.top

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
