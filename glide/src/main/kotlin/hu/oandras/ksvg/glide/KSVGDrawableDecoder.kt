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

import android.graphics.Canvas
import android.graphics.drawable.Drawable
import com.bumptech.glide.load.Options
import com.bumptech.glide.load.ResourceDecoder
import com.bumptech.glide.load.engine.Resource
import hu.oandras.ksvg.KSVGDrawable
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.SVG
import java.io.InputStream

/**
 * Decodes an SVG into a [Drawable]. If animations are enabled via [KSVGOptions.PARSE_ANIMATIONS],
 * it returns a [hu.oandras.ksvg.KSVGAnimatedDrawable].
 */
public class KSVGDrawableDecoder : ResourceDecoder<InputStream, Drawable> {

    override fun handles(source: InputStream, options: Options): Boolean {
        return isSvg(source)
    }

    override fun decode(
        source: InputStream,
        width: Int,
        height: Int,
        options: Options
    ): Resource<Drawable> {
        try {
            val parseAnimations = options.get(KSVGOptions.PARSE_ANIMATIONS) ?: false
            val svg = SVG.getFromInputStream(source, parseAnimations)

            val drawable: KSVGDrawable = if (parseAnimations) {
                svg.toAnimatedDrawable()
            } else {
                svg.toDrawable()
            }

            val canvas = Canvas()
            drawable.setBounds(0, 0, width, height)
            drawable.draw(canvas)

            return KSVGDrawableResource(drawable)
        } catch (e: KSVGParseException) {
            throw RuntimeException("Cannot load SVG from stream", e)
        }
    }
}
