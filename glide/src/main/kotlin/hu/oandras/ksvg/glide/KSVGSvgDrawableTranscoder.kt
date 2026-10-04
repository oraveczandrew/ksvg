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

import android.graphics.Bitmap
import android.graphics.Bitmap.createBitmap
import android.graphics.Canvas
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
        prewarmDrawable(drawable)

        return KSVGDrawableResource(drawable)
    }

    /**
     * Renders the fresh drawable once into a scratch bitmap, on Glide's worker
     * thread. Perfetto showed first `draw()` calls costing 8–41 ms on the UI
     * thread (scene build + first-render caches + JIT warmup, including a
     * 49 ms optimized-compile stall) while steady-state draws cost ~0.2 ms.
     *
     * Note the Glide 5 contract: `DrawableResource.get()` hands out a
     * `constantState.newDrawable()` copy on every call, so the warmed scene
     * and pools below stay with this instance and never reach the drawn copy
     * (copies own their scene by design). What *does* carry over process-wide
     * is JIT compilation, class initialization and font caches — those are
     * what made first renders cost 8–27 ms, and warming them here is what
     * shrinks every copy's first draw. Per-copy scene builds (4–14 ms) remain
     * and are tracked separately.
     *
     * Runs on a Glide worker ([transcode] never runs on the UI thread), so
     * its cost never lands on the frame path.
     */
    internal fun prewarmDrawable(drawable: KSVGDrawable) {
        // Plain ifs, not takeIf: the intrinsic sizes are platform Ints and the
        // generic takeIf would box each one (Integer per transcoded drawable).
        val rawWidth = drawable.intrinsicWidth
        val width = if (rawWidth > 0) rawWidth else FALLBACK_DIMENSION_PX
        val rawHeight = drawable.intrinsicHeight
        val height = if (rawHeight > 0) rawHeight else FALLBACK_DIMENSION_PX
        val scratch = createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            drawable.setBounds(0, 0, width, height)
            drawable.draw(Canvas(scratch))
        } finally {
            scratch.recycle()
        }
    }

    private companion object {
        const val FALLBACK_DIMENSION_PX: Int = 192
    }
}
