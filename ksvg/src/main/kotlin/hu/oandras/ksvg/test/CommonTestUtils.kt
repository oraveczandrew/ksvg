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

package hu.oandras.ksvg.test

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import androidx.annotation.VisibleForTesting
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import hu.oandras.ksvg.SlowSoftwareFiltering
import java.io.File
import java.io.InputStream

@VisibleForTesting
 internal fun renderWithLibrary(file: File, outBitmap: Bitmap): Bitmap {
     return file.inputStream().use {
         renderWithLibrary(it, outBitmap)
     }
 }

 internal fun renderWithLibrary(file: File, outBitmap: Bitmap, softwareFiltering: Boolean): Bitmap {
     return file.inputStream().use {
         renderWithLibrary(it, outBitmap, softwareFiltering)
     }
 }

 @VisibleForTesting
internal fun renderWithLibrary(input: InputStream, outBitmap: Bitmap): Bitmap {
    val svg = SVG.getFromInputStream(input)
    return renderSvgTo(svg, outBitmap)
}

 @VisibleForTesting
internal fun renderWithLibrary(input: InputStream, outBitmap: Bitmap, softwareFiltering: Boolean): Bitmap {
    val svg = SVG.getFromInputStream(input)
    return renderSvgTo(svg, outBitmap, softwareFiltering)
}

@VisibleForTesting
internal fun renderWithLibrary(
    input: String,
    outBitmap: Bitmap,
    softwareFiltering: Boolean = false,
    externalFileResolver: hu.oandras.ksvg.ExternalFileResolver? = null,
): Bitmap {
    val svg = SVG.getFromString(input, externalFileResolver = externalFileResolver)
    return renderSvgTo(svg, outBitmap, softwareFiltering)
}

private fun renderSvgTo(svg: SVG, outBitmap: Bitmap): Bitmap {
    return renderSvgTo(svg, outBitmap, false)
}

 @OptIn(SlowSoftwareFiltering::class)
 private fun renderSvgTo(svg: SVG, outBitmap: Bitmap, softwareFiltering: Boolean): Bitmap {
     outBitmap.eraseColor(0)

     val canvas = Canvas(outBitmap)

     val options = RenderOptions.create()
     options.viewPort(
         minX = 0f,
         minY = 0f,
         width = outBitmap.width.toFloat(),
         height = outBitmap.height.toFloat()
     )
     if (softwareFiltering) {
         options.softwareFiltering(true)
     }

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
    return decodePng(input, inBitmap, BitmapFactory.Options().also {
        it.inBitmap = inBitmap
    })
}

@VisibleForTesting
internal fun decodePng(input: InputStream, inBitmap: Bitmap, opts: BitmapFactory.Options): Bitmap? {
    return BitmapFactory.decodeStream(input, null, opts)
}

/**
 * Iterates over every pixel of [this] Bitmap, invoking [action] with the raw ARGB color int.
 */
@VisibleForTesting
internal inline fun Bitmap.forEachPixel(action: (color: Int) -> Unit) {
    val w = width
    val h = height
    val px = IntArray(w * h)
    getPixels(px, 0, w, 0, 0, w, h)
    for (i in px.indices) {
        action(px[i])
    }
}

/**
 * Counts the pixels of [bitmap] for which [predicate] returns true. The predicate
 * receives the raw ARGB color int; use [hu.oandras.ksvg.utils.alpha] /
 * [hu.oandras.ksvg.utils.red] etc. to inspect individual channels.
 */
@VisibleForTesting
internal inline fun countPixels(bitmap: Bitmap, predicate: (color: Int) -> Boolean): Int {
    var count = 0
    bitmap.forEachPixel { color ->
        if (predicate(color)) count++
    }
    return count
}