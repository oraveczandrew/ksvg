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
import hu.oandras.ksvg.filtering.SoftwareKernels
import hu.oandras.ksvg.render.ComponentTransferFunctions
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeComponentTransferRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.Renderer.Companion.LUMINANCE_TO_ALPHA_BLUE
import hu.oandras.ksvg.render.Renderer.Companion.LUMINANCE_TO_ALPHA_GREEN
import hu.oandras.ksvg.render.Renderer.Companion.LUMINANCE_TO_ALPHA_RED
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.floorToInt
import hu.oandras.ksvg.utils.linearToSRgb
import hu.oandras.ksvg.utils.sRgbToLinear
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.cos
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
): Bitmap {
    // Linear-space matrix (the default color-interpolation-filters="linearRGB"):
    // the canvas ColorMatrixColorFilter path works in gamma space, which reads
    // ~70/255 too dark vs. the reference on plain matrices. Explicit sRGB keeps
    // the old canvas path.
    if (primitiveNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB) {
        return colorMatrixFilterLinear(
            primitiveNode, inputBitmap, primitiveRegion, filterRegion,
        )
    }
    val paint = primitiveNode.getOrCreatePaint()

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

/**
 * feColorMatrix in the filter's working color space via
 * [SoftwareKernels.colorMatrix]. Pixel plumbing mirrors
 * [applyArithmeticComposite] (pooled buffers, zero outside the clip).
 */
context(renderContext: RenderContext)
internal fun colorMatrixFilterLinear(
    primitiveNode: FeColorMatrixRenderNode,
    inputBitmap: Bitmap,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap {
    val width = inputBitmap.width
    val height = inputBitmap.height
    val size = width * height
    val srcPixels = primitiveNode.srcPixels.getWithSize(size)
    inputBitmap.getPixels(srcPixels, 0, width, 0, 0, width, height)

    val clipLeft = clamp(((primitiveRegion.left - filterRegion.left)).toInt(), 0, width)
    val clipTop = clamp(((primitiveRegion.top - filterRegion.top)).toInt(), 0, height)
    val clipRight = clamp(((primitiveRegion.right - filterRegion.left)).toInt(), 0, width)
    val clipBottom = clamp(((primitiveRegion.bottom - filterRegion.top)).toInt(), 0, height)

    val outPixels = primitiveNode.outPixels.getWithSize(size)
    outPixels.fill(0) // Clean output outside the clip region
    SoftwareKernels.colorMatrix(
        srcPixels = srcPixels,
        outPixels = outPixels,
        width = width,
        clipLeft = clipLeft,
        clipTop = clipTop,
        clipRight = clipRight,
        clipBottom = clipBottom,
        matrix = primitiveNode.getOrCreateLinearMatrix(),
        useLinear = primitiveNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB,
    )

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

/** 4x5 matrix in SVG semantics (channels and offsets as 0..1 fractions).
 * android.graphics.ColorMatrix takes 0..255 offsets, so [buildColorMatrix]
 * scales the offset column after filling. */
internal fun buildColorMatrixValues(type: FeColorMatrixType, values: FloatArray?): FloatArray {
    val dst = FloatArray(20)
    fillColorMatrixValues(dst, type, values)
    return dst
}

private fun fillColorMatrixValues(dst: FloatArray, type: FeColorMatrixType, values: FloatArray?) {
    when (type) {
        FeColorMatrixType.matrix -> {
            // android.graphics.ColorMatrix requires exactly 20 elements (it throws
            // otherwise). Short lists fall back to identity (matching browsers, where
            // the malformed primitive is ignored); long lists keep the first 20.
            if (values == null || values.size < 20) {
                identity.copyInto(dst)
            } else {
                values.copyInto(dst, endIndex = 20)
            }
        }
        FeColorMatrixType.saturate -> fillSaturateMatrixValues(dst, values?.get(0) ?: 1f)
        FeColorMatrixType.hueRotate -> fillHueRotateMatrix(dst, values?.get(0) ?: 0f)
        FeColorMatrixType.luminanceToAlpha -> luminanceToAlphaFloatArray.copyInto(dst)
    }
}

/** Lazily built node cache of [buildColorMatrixValues]: the linear-RGB kernel
 * runs every frame, so rebuilding (plus `cos`/`sin` for hueRotate) on each
 * render is pure overhead for a snapshot that never changes. */
internal fun FeColorMatrixRenderNode.getOrCreateLinearMatrix(): FloatArray {
    var cached = linearMatrix
    if (cached == null) {
        cached = buildColorMatrixValues(type, values)
        linearMatrix = cached
    }
    return cached
}

/** Lazily built node cache of the gamma-space [Paint] (see [buildColorMatrix]). */
internal fun FeColorMatrixRenderNode.getOrCreatePaint(): Paint {
    var cached = paint
    if (cached == null) {
        cached = createFilterPaint(type = type, values = values)
        paint = cached
    }
    return cached
}

/** Clears both derived caches; call it if [FeColorMatrixRenderNode.values]
 * ever becomes animatable (currently nothing mutates it post-build). */
internal fun FeColorMatrixRenderNode.invalidateColorMatrixCache() {
    paint = null
    linearMatrix = null
}

/** saturate matrix with the SVG 1.1 luminance weights — identical to what
 * android.graphics.ColorMatrix.setSaturation computes, spelled out so the
 * kernel path shares it. */
private fun fillSaturateMatrixValues(dst: FloatArray, saturation: Float) {
    dst[0] = 0.213f + 0.787f * saturation; dst[1] = 0.715f - 0.715f * saturation; dst[2] = 0.072f - 0.072f * saturation; dst[3] = 0f; dst[4] = 0f
    dst[5] = 0.213f - 0.213f * saturation; dst[6] = 0.715f + 0.285f * saturation; dst[7] = 0.072f - 0.072f * saturation; dst[8] = 0f; dst[9] = 0f
    dst[10] = 0.213f - 0.213f * saturation; dst[11] = 0.715f - 0.715f * saturation; dst[12] = 0.072f + 0.928f * saturation; dst[13] = 0f; dst[14] = 0f
    dst[15] = 0f; dst[16] = 0f; dst[17] = 0f; dst[18] = 1f; dst[19] = 0f
}

internal fun buildColorMatrix(type: FeColorMatrixType, values: FloatArray?): ColorMatrix {
    // ColorMatrix.getArray() exposes the internal array, so fill it in place
    // instead of allocating a temporary FloatArray that ColorMatrix(float[])
    // would copy once more.
    val result = ColorMatrix()
    val mapped = result.array
    fillColorMatrixValues(mapped, type, values)
    mapped[4] *= 255f
    mapped[9] *= 255f
    mapped[14] *= 255f
    mapped[19] *= 255f
    return result
}

internal fun createFilterPaint(type: FeColorMatrixType, values: FloatArray?): Paint {
    val paint = Paint()
    paint.setColorFilter(ColorMatrixColorFilter(buildColorMatrix(type, values)))
    return paint
}

private fun fillHueRotateMatrix(dst: FloatArray, degrees: Float) {
    val angle = degrees.toRadians()
    val cos = cos(angle)
    val sin = sin(angle)
    val r = LUMINANCE_TO_ALPHA_RED
    val g = LUMINANCE_TO_ALPHA_GREEN
    val b = LUMINANCE_TO_ALPHA_BLUE
    dst[0] = r + cos * (1f - r) + sin * -r
    dst[1] = g + cos * -g + sin * -g
    dst[2] = b + cos * -b + sin * (1f - b)
    dst[3] = 0f
    dst[4] = 0f
    dst[5] = r + cos * -r + sin * 0.143f
    dst[6] = g + cos * (1f - g) + sin * 0.140f
    dst[7] = b + cos * -b + sin * -0.283f
    dst[8] = 0f
    dst[9] = 0f
    dst[10] = r + cos * -r + sin * -(1f - r)
    dst[11] = g + cos * -g + sin * g
    dst[12] = b + cos * (1f - b) + sin * b
    dst[13] = 0f
    dst[14] = 0f
    dst[15] = 0f
    dst[16] = 0f
    dst[17] = 0f
    dst[18] = 1f
    dst[19] = 0f
}

context(renderContext: RenderContext)
internal fun doFeComponentTransferFilter(
    inputBitmap: Bitmap,
    primitiveNode: FeComponentTransferRenderNode,
    primitiveRegion: RectF,
    filterRegion: RectF,
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

    val tables = primitiveNode.lutTables ?: buildTransferLutTables(
        transferFunctions,
        primitiveNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB
    ).also { primitiveNode.lutTables = it }

    SoftwareKernels.componentTransfer(
        src = pixels,
        dst = outPixels,
        width = width,
        height = height,
        clipLeft = clipLeft,
        clipTop = clipTop,
        clipRight = clipRight,
        clipBottom = clipBottom,
        tableA = tables[0],
        tableR = tables[1],
        tableG = tables[2],
        tableB = tables[3],
    )

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

/**
 * Precomputes the four per-channel 256-entry LUTs for the component-transfer kernel.
 * Each entry replicates [applyTransferFunction] exactly (including the
 * sRGB->linear->transfer->sRGB folding used by the linearRGB color
 * interpolation path), so native output is bit-identical to the Kotlin loop.
 */
internal fun buildTransferLutTables(
    transferFunctions: ComponentTransferFunctions,
    useLinearRgb: Boolean,
): Array<IntArray> = arrayOf(
    buildChannelLut(transferFunctions.a, useLinearRgb, isAlpha = true, shift = 24),
    buildChannelLut(transferFunctions.r, useLinearRgb, isAlpha = false, shift = 16),
    buildChannelLut(transferFunctions.g, useLinearRgb, isAlpha = false, shift = 8),
    buildChannelLut(transferFunctions.b, useLinearRgb, isAlpha = false, shift = 0),
)

private fun buildChannelLut(func: FeFunc?, useLinearRgb: Boolean, isAlpha: Boolean, shift: Int): IntArray {
    val table = IntArray(256)
    for (v in 0..255) {
        val res = if (useLinearRgb && !isAlpha) {
            linearToSRgb(applyTransferFunction(sRgbToLinear(v), func))
        } else {
            applyTransferFunction(v, func)
        }
        table[v] = (res and 0xFF) shl shift
    }
    return table
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
        n = scaled.floorToInt(),
        min = 0,
        max = tableValues.size - 2
    )
    val fraction = scaled - index
    return tableValues[index] + fraction * (tableValues[index + 1] - tableValues[index])
}

private fun discreteTable(x: Float, tableValues: FloatArray?): Float {
    if (tableValues == null || tableValues.isEmpty()) return x
    val index = clamp(
        n = (clamp(x, 0f, 1f) * tableValues.size).floorToInt(),
        min = 0,
        max = tableValues.size - 1
    )
    return tableValues[index]
}
