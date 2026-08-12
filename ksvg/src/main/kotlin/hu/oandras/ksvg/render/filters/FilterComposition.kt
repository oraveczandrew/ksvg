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
import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.os.Build
import hu.oandras.ksvg.dom.FeBlendMode
import hu.oandras.ksvg.dom.FeCompositeOperator
import hu.oandras.ksvg.dom.SvgObject.FeBlend
import hu.oandras.ksvg.dom.SvgObject.FeComposite
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.createBitmapSameAs
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.isBitmapTransparent
import hu.oandras.ksvg.utils.red

internal fun doFeCompositeFilter(
    primitive: FeComposite,
    inputBitmap: Bitmap,
    results: Map<String, Bitmap>,
    lastResult: Bitmap?,
): Bitmap? {
    val in2 = getFilterInput(primitive.in2, results, lastResult) ?: return null
    val operator = primitive.operator
    return when {
        operator == FeCompositeOperator.arithmetic -> applyArithmeticComposite(inputBitmap, in2, primitive)
        operator == FeCompositeOperator.over && isBitmapTransparent(in2) -> inputBitmap
        else -> {
            val res = createBitmapSameAs(inputBitmap)
            val c = Canvas(res)
            c.drawBitmap(in2, 0f, 0f, null)
            val paint = Paint()
            paint.xfermode = PorterDuffXfermode(
                when (operator) {
                    FeCompositeOperator.`in` -> PorterDuff.Mode.SRC_IN
                    FeCompositeOperator.out -> PorterDuff.Mode.SRC_OUT
                    FeCompositeOperator.atop -> PorterDuff.Mode.SRC_ATOP
                    FeCompositeOperator.xor -> PorterDuff.Mode.XOR
                    else -> PorterDuff.Mode.SRC_OVER
                }
            )
            c.drawBitmap(inputBitmap, 0f, 0f, paint)
            res
        }
    }
}

internal fun doFeBlendFilter(
    primitive: FeBlend,
    inputBitmap: Bitmap,
    results: Map<String, Bitmap>,
    lastResult: Bitmap?,
): Bitmap? {
    val in2 = getFilterInput(primitive.in2, results, lastResult) ?: return null
    val mode = primitive.mode
    if (mode == FeBlendMode.normal && isBitmapTransparent(in2)) {
        return inputBitmap
    }
    val res = createBitmapSameAs(inputBitmap)
    val c = Canvas(res)
    c.drawBitmap(in2, 0f, 0f, null)
    val paint = Paint()
    if (mode != FeBlendMode.normal) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            paint.blendMode = when (mode) {
                FeBlendMode.multiply -> BlendMode.MULTIPLY
                FeBlendMode.screen -> BlendMode.SCREEN
                FeBlendMode.darken -> BlendMode.DARKEN
                FeBlendMode.lighten -> BlendMode.LIGHTEN
                FeBlendMode.overlay -> BlendMode.OVERLAY
                FeBlendMode.`color-dodge` -> BlendMode.COLOR_DODGE
                FeBlendMode.`color-burn` -> BlendMode.COLOR_BURN
                FeBlendMode.`hard-light` -> BlendMode.HARD_LIGHT
                FeBlendMode.`soft-light` -> BlendMode.SOFT_LIGHT
                FeBlendMode.difference -> BlendMode.DIFFERENCE
                FeBlendMode.exclusion -> BlendMode.EXCLUSION
                FeBlendMode.hue -> BlendMode.HUE
                FeBlendMode.saturation -> BlendMode.SATURATION
                FeBlendMode.color -> BlendMode.COLOR
                FeBlendMode.luminosity -> BlendMode.LUMINOSITY
            }
        } else {
            paint.xfermode = PorterDuffXfermode(
                when (mode) {
                    FeBlendMode.multiply -> PorterDuff.Mode.MULTIPLY
                    FeBlendMode.screen -> PorterDuff.Mode.SCREEN
                    FeBlendMode.darken -> PorterDuff.Mode.DARKEN
                    FeBlendMode.lighten -> PorterDuff.Mode.LIGHTEN
                    else -> PorterDuff.Mode.SRC_OVER
                }
            )
        }
    }
    c.drawBitmap(inputBitmap, 0f, 0f, paint)
    return res
}

private fun applyArithmeticComposite(input: Bitmap, in2: Bitmap, primitive: FeComposite): Bitmap {
    val width = input.width
    val height = input.height
    val inputPixels = IntArray(width * height)
    val in2Pixels = IntArray(width * height)
    input.getPixels(inputPixels, 0, width, 0, 0, width, height)
    in2.getPixels(in2Pixels, 0, width, 0, 0, width, height)

    val k1 = primitive.k1
    val k2 = primitive.k2
    val k3 = primitive.k3
    val k4 = primitive.k4
    for (i in inputPixels.indices) {
        val a = inputPixels[i]
        val b = in2Pixels[i]
        inputPixels[i] = argb(
            alpha = arithmeticChannel(a.alpha, b.alpha, k1, k2, k3, k4),
            red = arithmeticChannel(a.red, b.red, k1, k2, k3, k4),
            green = arithmeticChannel(a.green, b.green, k1, k2, k3, k4),
            blue = arithmeticChannel(a.blue, b.blue, k1, k2, k3, k4),
        )
    }

    val res = createBitmapSameAs(input)
    res.setPixels(inputPixels, 0, width, 0, 0, width, height)
    return res
}

private fun arithmeticChannel(in1: Int, in2: Int, k1: Float, k2: Float, k3: Float, k4: Float): Int {
    val a = in1 / 255f
    val b = in2 / 255f
    return clamp255((k1 * a * b + k2 * a + k3 * b + k4) * 255f)
}
