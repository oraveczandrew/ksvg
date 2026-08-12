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

package hu.oandras.ksvg

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import androidx.annotation.VisibleForTesting
import java.io.File
import java.io.InputStream

@VisibleForTesting
internal fun renderWithLibrary(file: File, outBitmap: Bitmap): Bitmap {
    return file.inputStream().use {
        renderWithLibrary(it, outBitmap)
    }
}

@VisibleForTesting
internal fun renderWithLibrary(input: InputStream, outBitmap: Bitmap): Bitmap {
    outBitmap.eraseColor(0)

    val svg = SVG.getFromInputStream(input)
    val canvas = Canvas(outBitmap)

    val options = RenderOptions.create()
    options.viewPort(
        minX = 0f,
        minY = 0f,
        width = outBitmap.width.toFloat(),
        height = outBitmap.height.toFloat()
    )

    svg.renderToCanvas(canvas, options)
    return outBitmap
}

@VisibleForTesting
internal fun decodePng(file: File, inBitmap: Bitmap): Bitmap? {
    file.inputStream().use {
        return decodePng(it, inBitmap)
    }
}

@VisibleForTesting
internal fun decodePng(input: InputStream, inBitmap: Bitmap): Bitmap? {
    return BitmapFactory.decodeStream(input, null, BitmapFactory.Options().also {
        it.inBitmap = inBitmap
    })
}