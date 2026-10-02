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
package hu.oandras.ksvg

import android.annotation.SuppressLint
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import androidx.collection.ArraySet
import hu.oandras.ksvg.logger.AndroidLoggerContext
import hu.oandras.ksvg.logger.LoggerContext
import hu.oandras.ksvg.logger.logI
import hu.oandras.ksvg.logger.logW
import java.io.IOException

/**
 * A sample implementation of [ExternalFileResolver] that retrieves files from
 * an application's "assets" folder.
 *
 * @param loggerContext logging scope for resolver diagnostics; defaults to silent.
 */
public class SimpleAssetResolver(
    private val assetManager: AssetManager,
    private val loggerContext: LoggerContext = AndroidLoggerContext,
) : ExternalFileResolver() {

    /**
     * Attempt to find the specified font in the "assets" folder and return a Typeface object.
     * For the font name "Foo", first the file "Foo.ttf" will be tried, and if that fails, "Foo.otf".
     */
    override fun resolveFont(
        fontFamily: String,
        fontWeight: Float,
        fontStyle: String,
        fontStretch: Float
    ): Typeface? {
        loggerContext.logI(TAG) {
            "resolveFont('$fontFamily',$fontWeight,'$fontStyle',$fontStretch)"
        }

        // Try ".ttf", then ".otf", then the first font of a ".ttc" collection.
        // createFromAsset already builds via Typeface.Builder (default TTC index 0),
        // so one nullable lookup per suffix covers all three cases.
        for (suffix in FONT_SUFFIXES) {
            val path = "$fontFamily.$suffix"
            val typeface = assetManager.typefaceOrNull(path)
            if (typeface != null) {
                loggerContext.logI(TAG) { "resolveFont('$fontFamily') -> $path" }
                return typeface
            }
        }

        loggerContext.logW(TAG) { "resolveFont('$fontFamily') not found in assets" }

        return null
    }

    private fun AssetManager.typefaceOrNull(path: String): Typeface? {
        return try {
            Typeface.createFromAsset(this, path)
        } catch (_: RuntimeException) {
            null
        }
    }

    /**
     * Attempt to find the specified image file in the `assets` folder and return a decoded Bitmap.
     *
     * The `href` is resolved against [baseUri] first; absolute results (remote URLs)
     * cannot come from assets and decline to null.
     */
    override fun resolveImage(filename: String, baseUri: String?): Bitmap? {
        val resolved = resolveHrefAgainstBase(baseUri, filename)
        loggerContext.logI(TAG) { "resolveImage($filename, baseUri=$baseUri) -> $resolved" }

        if (!isAssetPath(resolved)) {
            return null
        }

        return try {
            assetManager.open(resolved).use {
                BitmapFactory.decodeStream(it)
            }
        } catch (_: IOException) {
            loggerContext.logW(TAG) { "resolveImage($filename) asset not found: $resolved" }
            null
        }
    }

    /**
     * Returns true when passed the MIME types of the bitmap image formats this
     * resolver can serve via Android's BitmapFactory class. MIME types match
     * case-insensitively per RFC 2045.
     */
    override fun isFormatSupported(mimeType: String): Boolean {
        return supportedFormats.contains(mimeType.lowercase())
    }

    /**
     * Attempt to find the specified stylesheet file in the "assets" folder and return its string contents.
     */
    override fun resolveCSSStyleSheet(url: String, baseUri: String?): ResolvedStylesheet? {
        val resolved = resolveHrefAgainstBase(baseUri, url)
        loggerContext.logI(TAG) { "resolveCSSStyleSheet($url, baseUri=$baseUri) -> $resolved" }

        if (!isAssetPath(resolved)) {
            return null
        }

        return try {
            val css = assetManager.open(resolved).bufferedReader().use { it.readText() }
            ResolvedStylesheet(resolved, css)
        } catch (_: IOException) {
            loggerContext.logW(TAG) { "resolveCSSStyleSheet asset not found: $resolved" }
            null
        }
    }

    /*
    * Only scheme-less relative paths can come from assets: absolute URIs (remote
    * URLs, data: payloads, file: paths) are declined without touching the
    * AssetManager, whose open() would only throw on them anyway.
    */
    @SuppressLint("UseKtx")
    private fun isAssetPath(path: String): Boolean {
        return Uri.parse(path).scheme.isNullOrEmpty()
    }

    internal companion object {
        private const val TAG = "SimpleAssetResolver"

        private val FONT_SUFFIXES: Array<String> = arrayOf("ttf", "otf", "ttc")

        // Bitmap formats this resolver can serve (BitmapFactory-backed). SVG is
        // deliberately absent: resolveImage() returns Bitmaps and cannot decode it.
        // HEIF/HEIC is absent too: platform decoding is codec-dependent, not guaranteed.
        private val supportedFormats: Set<String> = ArraySet<String>(9).apply {
            add("image/jpeg")
            add("image/jpg") // widespread non-standard alias
            add("image/png")
            // Other image formats supported by Android BitmapFactory
            add("image/pjpeg")
            add("image/gif") // first frame only
            add("image/bmp")
            add("image/x-windows-bmp")
            add("image/webp")
            // .avif supported in 12.0+ (S)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add("image/avif")
            }
        }
    }
}
