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
import android.graphics.Paint
import android.graphics.RectF
import hu.oandras.ksvg.compat.BlendModeCompat
import hu.oandras.ksvg.compat.XFerModes
import hu.oandras.ksvg.compat.setBlendModeCompat
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeComposite
import hu.oandras.ksvg.dom.filter.FeCompositeOperator
import hu.oandras.ksvg.render.FeBlendRenderNode
import hu.oandras.ksvg.render.FeCompositeRenderNode
import hu.oandras.ksvg.render.FeMergeRenderNode
import hu.oandras.ksvg.render.FilterSourceMap
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.createBitmapSameAs
import hu.oandras.ksvg.render.isBitmapTransparent
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.linearToSRgb
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.sRgbToLinear

context(renderContext: RenderContext)
internal fun doFeCompositeFilter(
    primitiveNode: FeCompositeRenderNode,
    inputBitmap: Bitmap,
    results: FilterSourceMap,
    lastResult: Bitmap?,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap? {
    val primitive = primitiveNode.sourceElement
    val in2 = getFilterInput(primitive.in2, results, lastResult) ?: return null
    return when (primitive.operator) {
        FeCompositeOperator.arithmetic -> applyArithmeticComposite(inputBitmap, in2, primitive, primitiveNode, primitiveRegion, filterRegion, canvasScaleX, canvasScaleY)
        FeCompositeOperator.over if isBitmapTransparent(in2) -> inputBitmap
        else -> {
            val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
            renderContext.canvasPool.withPooledObject { c ->
                c.setBitmap(res)
                val clipLeft = (primitiveRegion.left - filterRegion.left)
                val clipTop = (primitiveRegion.top - filterRegion.top)
                val clipRight = (primitiveRegion.right - filterRegion.left)
                val clipBottom = (primitiveRegion.bottom - filterRegion.top)
                c.clipRect(clipLeft, clipTop, clipRight, clipBottom)
                c.drawBitmap(in2, 0f, 0f, null)
                c.drawBitmap(inputBitmap, 0f, 0f, primitiveNode.paint)
            }
            res
        }
    }
}

context(renderContext: RenderContext)
internal fun doFeBlendFilter(
    primitiveNode: FeBlendRenderNode,
    inputBitmap: Bitmap,
    results: FilterSourceMap,
    lastResult: Bitmap?,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap? {
    val in2 = getFilterInput(primitiveNode.in2, results, lastResult) ?: return null
    val mode = primitiveNode.mode
    if (mode == FeBlendMode.normal && isBitmapTransparent(in2)) {
        return inputBitmap
    }
    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        val clipLeft = (primitiveRegion.left - filterRegion.left)
        val clipTop = (primitiveRegion.top - filterRegion.top)
        val clipRight = (primitiveRegion.right - filterRegion.left)
        val clipBottom = (primitiveRegion.bottom - filterRegion.top)
        c.clipRect(clipLeft, clipTop, clipRight, clipBottom)
        c.drawBitmap(in2, 0f, 0f, null)
        if (mode == FeBlendMode.normal) {
            c.drawBitmap(inputBitmap, 0f, 0f, null)
        } else {
            c.drawBitmap(inputBitmap, 0f, 0f, primitiveNode.paint)
        }
    }
    return res
}

private fun applyArithmeticComposite(
    input: Bitmap,
    in2: Bitmap,
    primitive: FeComposite,
    primitiveNode: FeCompositeRenderNode,
    primitiveRegion: RectF,
    filterRegion: RectF,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val width = input.width
    val height = input.height
    val size = width * height
    val inputPixels = primitiveNode.inputPixels.getWithSize(size)
    val in2Pixels = primitiveNode.in2Pixels.getWithSize(size)
    input.getPixels(inputPixels, 0, width, 0, 0, width, height)
    in2.getPixels(in2Pixels, 0, width, 0, 0, width, height)

    val clipLeft = clamp(((primitiveRegion.left - filterRegion.left)).toInt(), 0, width)
    val clipTop = clamp(((primitiveRegion.top - filterRegion.top)).toInt(), 0, height)
    val clipRight = clamp(((primitiveRegion.right - filterRegion.left)).toInt(), 0, width)
    val clipBottom = clamp(((primitiveRegion.bottom - filterRegion.top)).toInt(), 0, height)

    val k1 = primitive.k1
    val k2 = primitive.k2
    val k3 = primitive.k3
    val k4 = primitive.k4
    
    val outPixels = IntArray(size) // We need a clean output
    val useLinear = primitiveNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB

    val cTop: Int = clipTop
    val cBottom: Int = clipBottom
    val cLeft: Int = clipLeft
    val cRight: Int = clipRight

    for (y in cTop until cBottom) {
        val rowOffset = y * width
        for (x in cLeft until cRight) {
            val i = rowOffset + x
            val a = inputPixels[i]
            val b = in2Pixels[i]

            if (useLinear) {
                outPixels[i] = argb(
                    alpha = arithmeticChannel(a.alpha, b.alpha, k1, k2, k3, k4),
                    red = linearToSRgb(arithmeticChannel(sRgbToLinear(a.red), sRgbToLinear(b.red), k1, k2, k3, k4)),
                    green = linearToSRgb(arithmeticChannel(sRgbToLinear(a.green), sRgbToLinear(b.green), k1, k2, k3, k4)),
                    blue = linearToSRgb(arithmeticChannel(sRgbToLinear(a.blue), sRgbToLinear(b.blue), k1, k2, k3, k4)),
                )
            } else {
                outPixels[i] = argb(
                    alpha = arithmeticChannel(a.alpha, b.alpha, k1, k2, k3, k4),
                    red = arithmeticChannel(a.red, b.red, k1, k2, k3, k4),
                    green = arithmeticChannel(a.green, b.green, k1, k2, k3, k4),
                    blue = arithmeticChannel(a.blue, b.blue, k1, k2, k3, k4),
                )
            }
        }
    }

    val res = createBitmapSameAs(input)
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

private fun arithmeticChannel(in1: Int, in2: Int, k1: Float, k2: Float, k3: Float, k4: Float): Int {
    val a = in1 / 255f
    val b = in2 / 255f
    return clamp255((k1 * a * b + k2 * a + k3 * b + k4) * 255f)
}

context(renderContext: RenderContext)
internal fun doFeMergeFilter(
    merge: FeMergeRenderNode,
    results: FilterSourceMap,
    lastResult: Bitmap?,
    region: RectF,
): Bitmap {
    val res = renderContext.bitmapPool.acquire(
        width = region.width().ceilToInt(),
        height = region.height().ceilToInt(),
        config = Bitmap.Config.ARGB_8888,
    )
    renderContext.canvasPool.withPooledObject { c ->
        c.setBitmap(res)
        var isFirst = true
        merge.mergeNodes.forEachElement { inputId ->
            val input = if (inputId == null) {
                if (isFirst) {
                    results.get("SourceGraphic")
                } else {
                    lastResult
                }
            } else {
                results.get(inputId)
            }
            if (input != null) {
                c.drawBitmap(input, 0f, 0f, null)
            }
            isFirst = false
        }
    }
    return res
}

internal fun createCompositePaint(operator: FeCompositeOperator): Paint {
    val paint = Paint()
    paint.xfermode = when (operator) {
        FeCompositeOperator.`in` -> XFerModes.SrcIn
        FeCompositeOperator.out -> XFerModes.SrcOut
        FeCompositeOperator.atop -> XFerModes.SrcAtop
        FeCompositeOperator.xor -> XFerModes.Xor
        else -> XFerModes.SrcOver
    }
    return paint
}

internal fun createBlendPaint(mode: FeBlendMode): Paint {
    val paint = Paint()
    val blendMode = when (mode) {
        FeBlendMode.multiply -> BlendModeCompat.MULTIPLY
        FeBlendMode.screen -> BlendModeCompat.SCREEN
        FeBlendMode.darken -> BlendModeCompat.DARKEN
        FeBlendMode.lighten -> BlendModeCompat.LIGHTEN
        FeBlendMode.overlay -> BlendModeCompat.OVERLAY
        FeBlendMode.`color-dodge` -> BlendModeCompat.COLOR_DODGE
        FeBlendMode.`color-burn` -> BlendModeCompat.COLOR_BURN
        FeBlendMode.`hard-light` -> BlendModeCompat.HARD_LIGHT
        FeBlendMode.`soft-light` -> BlendModeCompat.SOFT_LIGHT
        FeBlendMode.difference -> BlendModeCompat.DIFFERENCE
        FeBlendMode.exclusion -> BlendModeCompat.EXCLUSION
        FeBlendMode.hue -> BlendModeCompat.HUE
        FeBlendMode.saturation -> BlendModeCompat.SATURATION
        FeBlendMode.color -> BlendModeCompat.COLOR
        FeBlendMode.luminosity -> BlendModeCompat.LUMINOSITY
        FeBlendMode.normal -> null
    }

    paint.setBlendModeCompat(blendMode)
    return paint
}
