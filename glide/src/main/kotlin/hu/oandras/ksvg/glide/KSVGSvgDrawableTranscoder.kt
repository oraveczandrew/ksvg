/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.glide

import android.graphics.drawable.Drawable
import com.bumptech.glide.load.Options
import com.bumptech.glide.load.engine.Resource
import com.bumptech.glide.load.resource.transcode.ResourceTranscoder
import hu.oandras.ksvg.KSVGDrawable
import hu.oandras.ksvg.SVG

/**
 * Creates a fresh [Drawable] from a cached [SVG] document on every call.
 *
 * Drawables own a per-view mutable state (scene, pools, bounds, animation
 * clock), so sharing one instance across targets is unsafe. Transcoding runs
 * per request — including per memory-cache key (Glide keys include the target
 * size), which is what gives each target its own drawable.
 *
 * If animations are enabled via [KSVGOptions.PARSE_ANIMATIONS], the result is
 * a [hu.oandras.ksvg.KSVGAnimatedDrawable].
 */
public class KSVGSvgDrawableTranscoder : ResourceTranscoder<SVG, Drawable> {

    override fun transcode(toTranscode: Resource<SVG>, options: Options): Resource<Drawable> {
        val svg = toTranscode.get()
        val parseAnimations = options.get(KSVGOptions.PARSE_ANIMATIONS) ?: false
        val drawable: KSVGDrawable = if (parseAnimations) {
            svg.toAnimatedDrawable()
        } else {
            svg.toDrawable()
        }
        return KSVGDrawableResource(drawable)
    }

}
