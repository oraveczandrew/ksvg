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

package hu.oandras.ksvg.glide

import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Log
import com.bumptech.glide.load.Options
import com.bumptech.glide.load.ResourceDecoder
import com.bumptech.glide.load.engine.Resource
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPool
import com.bumptech.glide.load.resource.bitmap.BitmapResource
import com.bumptech.glide.request.target.Target
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.SVG
import java.io.IOException
import java.io.InputStream
import kotlin.math.max
import kotlin.math.roundToInt

/** Decodes an SVG internal representation from an [java.io.InputStream].  */
public class SvgDecoder(
    private val pool: BitmapPool
) : ResourceDecoder<InputStream, Bitmap> {

    internal companion object {
        private const val TAG = "SvgDecoder"

        /**
         * Decode-time dimension budget: texture-safe ceiling browsers likewise
         * enforce before allocating (audit R2/D5). Larger requests clamp
         * aspect-preserving instead of throwing OOM.
         */
        internal const val MAX_DECODE_DIMENSION: Int = 8192
    }

    override fun handles(source: InputStream, options: Options): Boolean {
        return isSvg(source)
    }

    @Throws(IOException::class)
    override fun decode(
        source: InputStream,
        width: Int,
        height: Int,
        options: Options
    ): Resource<Bitmap> {
        try {
            val parseAnimations = options.get(KSVGOptions.PARSE_ANIMATIONS) ?: false
            val svg = SVG.getFromInputStream(source, parseAnimations)

            if (svg.documentWidth == -1f || svg.documentHeight == -1f) {
                if (width != Target.SIZE_ORIGINAL && height != Target.SIZE_ORIGINAL) {
                    svg.documentWidth = width.toFloat()
                    svg.documentHeight = height.toFloat()
                } else {
                    svg.documentWidth = 192f
                    svg.documentHeight = 192f
                }
            }

            val documentWidth = svg.documentWidth
            val documentHeight = svg.documentHeight

            val scaleX: Float
            val scaleY: Float

            when {
                width != Target.SIZE_ORIGINAL && height != Target.SIZE_ORIGINAL -> {
                    scaleX = width / documentWidth
                    scaleY = height / documentHeight
                }
                width == Target.SIZE_ORIGINAL && height == Target.SIZE_ORIGINAL -> {
                    scaleX = 1f
                    scaleY = 1f
                }
                width == Target.SIZE_ORIGINAL -> {
                    scaleX = 1f
                    scaleY = height / documentHeight
                }
                else -> {
                    scaleX = width / documentWidth
                    scaleY = 1f
                }
            }

            val scale = max(scaleX, scaleY)
            var finalWidth: Int = (scale * documentWidth).roundToInt()
            var finalHeight: Int = (scale * documentHeight).roundToInt()

            // Decode-time budget (audit R2, browser parity): attacker-controlled
            // dimensions must never drive an unbounded allocation. Clamp
            // aspect-preserving to the texture-safe ceiling instead of OOMing.
            if (finalWidth > MAX_DECODE_DIMENSION || finalHeight > MAX_DECODE_DIMENSION) {
                val down = minOf(
                    MAX_DECODE_DIMENSION / finalWidth.toFloat(),
                    MAX_DECODE_DIMENSION / finalHeight.toFloat()
                )
                Log.w(TAG, "Clamping SVG decode size ${finalWidth}x$finalHeight")
                finalWidth = (finalWidth * down).roundToInt().coerceAtLeast(1)
                finalHeight = (finalHeight * down).roundToInt().coerceAtLeast(1)
            }

            val bitmap = try {
                pool.get(finalWidth, finalHeight, Bitmap.Config.ARGB_8888)
            } catch (e: OutOfMemoryError) {
                throw IOException("SVG decode bitmap too large: ${finalWidth}x$finalHeight", e)
            }
            val canvas = Canvas(bitmap)
            canvas.scale(scale, scale)
            svg.renderToCanvas(canvas)
            return BitmapResource(bitmap, pool)
        } catch (ex: KSVGParseException) {
            throw IOException("Cannot load SVG from stream", ex)
        }
    }
}

