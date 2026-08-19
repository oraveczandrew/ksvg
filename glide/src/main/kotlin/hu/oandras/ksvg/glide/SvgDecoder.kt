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
@Suppress("UNNECESSARY_NOT_NULL_ASSERTION")
public class SvgDecoder(
    private val pool: BitmapPool
) : ResourceDecoder<InputStream, Bitmap> {

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
            val finalWidth: Int = (scale * documentWidth).roundToInt()
            val finalHeight: Int = (scale * documentHeight).roundToInt()

            val bitmap = pool.get(finalWidth, finalHeight, Bitmap.Config.ARGB_8888)!!
            val canvas = Canvas(bitmap)
            canvas.scale(scale, scale)
           svg.renderToCanvas(canvas)
            return BitmapResource(bitmap, pool)
        } catch (ex: KSVGParseException) {
            throw IOException("Cannot load SVG from stream", ex)
        }
    }
}

