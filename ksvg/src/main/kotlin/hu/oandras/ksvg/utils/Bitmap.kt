@file:Suppress("UNNECESSARY_NOT_NULL_ASSERTION")

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

package hu.oandras.ksvg.utils

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint

@SuppressLint("UseKtx")
internal fun createBitmapSameAs(other: Bitmap): Bitmap {
    return Bitmap.createBitmap(
        /* width = */ other.width,
        /* height = */ other.height,
        /* config = */ other.config!!
    )!!
}

internal fun createBitmap(width: Int, height: Int): Bitmap {
    return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)!!
}

internal fun extractAlpha(src: Bitmap): Bitmap {
    val alpha = createBitmap(src.width, src.height)
    val canvas = Canvas(alpha)
    val paint = Paint()
    val matrix = ColorMatrix(
        floatArrayOf(
            0f, 0f, 0f, 0f, 0f,
            0f, 0f, 0f, 0f, 0f,
            0f, 0f, 0f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
        )
    )
    paint.setColorFilter(ColorMatrixColorFilter(matrix))
    canvas.drawBitmap(src, 0f, 0f, paint)
    return alpha
}

@SuppressLint("UseKtx")
internal fun isBitmapTransparent(bitmap: Bitmap): Boolean {
    val width = bitmap.width
    if (width == 0) {
        return true
    }

    val height = bitmap.height
    return height == 0 || bitmap.getPixel(0, 0) == 0 &&
            bitmap.getPixel(width - 1, 0) == 0 &&
            bitmap.getPixel(0, height - 1) == 0 &&
            bitmap.getPixel(width - 1, height - 1) == 0 &&
            bitmap.getPixel(width / 2, height / 2) == 0
    // Check corners and center for speed
}

@SuppressLint("UseKtx")
internal fun Bitmap.getPixelAtClamped(x: Int, y: Int): Int {
    val pixelPosX = clamp(x, 0, width - 1)
    val pixelPosY = clamp(y, 0, height - 1)
    return getPixel(pixelPosX, pixelPosY)
}