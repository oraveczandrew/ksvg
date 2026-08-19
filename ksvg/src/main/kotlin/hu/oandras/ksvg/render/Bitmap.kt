/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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

package hu.oandras.ksvg.render

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.render.pool.withPooledObject

internal fun createBitmapSameAs(other: Bitmap): Bitmap {
    return createBitmap(
        width = other.width,
        height = other.height,
        config = other.config!!
    )
}

internal fun createBitmap(width: Int, height: Int): Bitmap {
    return createBitmap(width, height, Bitmap.Config.ARGB_8888)
}

@SuppressLint("UseKtx")
internal fun createBitmap(width: Int, height: Int,config: Bitmap.Config): Bitmap {
    return Bitmap.createBitmap(width, height, config)!!
}

private val extractAlphaPaint = Paint().apply {
    setColorFilter(ColorMatrixColorFilter(ColorMatrix(
        floatArrayOf(
            0f, 0f, 0f, 0f, 0f,
            0f, 0f, 0f, 0f, 0f,
            0f, 0f, 0f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
        )
    )))
}

context(poolOwner: PoolOwner)
internal fun extractAlpha(src: Bitmap): Bitmap {
    val alpha = poolOwner.bitmapPool.acquire(src.width, src.height, Bitmap.Config.ARGB_8888)
    poolOwner.canvasPool.withPooledObject { c ->
        c.setBitmap(alpha)
        c.drawBitmap(src, 0f, 0f, extractAlphaPaint)
    }
    return alpha
}

@SuppressLint("UseKtx")
internal fun isBitmapTransparent(bitmap: Bitmap): Boolean {
    val width = bitmap.width
    if (width == 0) {
        return true
    }

    val height = bitmap.height
    if (height == 0) return true

    // Sample a 3x3 grid plus edge midpoints for better coverage
    val x0 = 0
    val x1 = width / 2
    val x2 = width - 1
    val y0 = 0
    val y1 = height / 2
    val y2 = height - 1
    return bitmap.getPixel(x0, y0) == 0 &&
            bitmap.getPixel(x1, y0) == 0 &&
            bitmap.getPixel(x2, y0) == 0 &&
            bitmap.getPixel(x0, y1) == 0 &&
            bitmap.getPixel(x1, y1) == 0 &&
            bitmap.getPixel(x2, y1) == 0 &&
            bitmap.getPixel(x0, y2) == 0 &&
            bitmap.getPixel(x1, y2) == 0 &&
            bitmap.getPixel(x2, y2) == 0
}