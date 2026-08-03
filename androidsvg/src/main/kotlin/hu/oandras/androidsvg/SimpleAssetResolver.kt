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
package hu.oandras.androidsvg

import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import androidx.collection.ArraySet
import java.io.IOException
import java.io.InputStream
import java.io.Reader

/**
 * A sample implementation of [SVGExternalFileResolver] that retrieves files from
 * an application's "assets" folder.
 */
public class SimpleAssetResolver(
    private val assetManager: AssetManager
) : SVGExternalFileResolver() {

    /**
     * Attempt to find the specified font in the "assets" folder and return a Typeface object.
     * For the font name "Foo", first the file "Foo.ttf" will be tried and if that fails, "Foo.otf".
     */
    override fun resolveFont(
        fontFamily: String,
        fontWeight: Float,
        fontStyle: String,
        fontStretch: Float
    ): Typeface? {
        Log.i(
            TAG,
            "resolveFont('$fontFamily',$fontWeight,'$fontStyle',$fontStretch)"
        )

        val assetManager = assetManager

        // Try font name with suffix ".ttf"
        try {
            return Typeface.createFromAsset(assetManager, "$fontFamily.ttf")
        } catch (_: RuntimeException) {
        }

        // That failed, so try ".otf"
        try {
            return Typeface.createFromAsset(assetManager, "$fontFamily.otf")
        } catch (_: RuntimeException) {
        }

        // That failed, so try ".ttc" (True-type collection), if supported on this version of Android
        val builder = Typeface.Builder(assetManager, "$fontFamily.ttc")
        // Get the first font file in the collection
        builder.setTtcIndex(0)
        return builder.build()
    }


    /**
     * Attempt to find the specified image file in the `assets` folder and return a decoded Bitmap.
     */
    override fun resolveImage(filename: String): Bitmap? {
        Log.i(TAG, "resolveImage($filename)")

        return try {
            assetManager.open(filename).use {
                BitmapFactory.decodeStream(it)
            }
        } catch (_: IOException) {
            null
        }
    }

    /**
     * Returns true when passed the MIME types for SVG, JPEG, PNG or any of the
     * other bitmap image formats supported by Android's BitmapFactory class.
     */
    override fun isFormatSupported(mimeType: String): Boolean {
        return supportedFormats.contains(mimeType)
    }


    /**
     * Attempt to find the specified stylesheet file in the "assets" folder and return its string contents.
     * @since 1.3
     */
    override fun resolveCSSStyleSheet(url: String): String? {
        Log.i(TAG, "resolveCSSStyleSheet($url)")
        return getAssetAsString(url)
    }

    /*
    * Read the contents of the asset whose name is given by "url" and return it as a String.
    */
    private fun getAssetAsString(url: String): String? {
        var inputStream: InputStream? = null
        return try {
            inputStream = assetManager.open(url)

            val r: Reader = inputStream.reader()
            val buffer = CharArray(4096)
            val sb = StringBuilder()
            var len = r.read(buffer)
            while (len > 0) {
                sb.appendRange(buffer, 0, len)
                len = r.read(buffer)
            }
            sb.toString()
        } catch (_: IOException) {
            null
        } finally {
            try {
                inputStream?.close()
            } catch (_: IOException) {
                // Do nothing
            }
        }
    }

    internal companion object {
        private const val TAG = "SimpleAssetResolver"

        private val supportedFormats: Set<String> = ArraySet<String>(8).apply {
            // PNG, JPEG and SVG are required by the SVG 1.2 spec
            add("image/svg+xml")
            add("image/jpeg")
            add("image/png")
            // Other image formats supported by Android BitmapFactory
            add("image/pjpeg")
            add("image/gif")
            add("image/bmp")
            add("image/x-windows-bmp")
            // .webp supported in 4.0+ (ICE_CREAM_SANDWICH)
            add("image/webp")
            // .avif supported in 12.0+ (S)
            if (Build.VERSION.SDK_INT >= 31) {
                add("image/avif")
            }
        }
    }
}
