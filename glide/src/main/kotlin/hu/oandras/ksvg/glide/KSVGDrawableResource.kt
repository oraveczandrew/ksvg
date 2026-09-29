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

import android.graphics.drawable.Drawable
import com.bumptech.glide.load.resource.drawable.DrawableResource
import hu.oandras.ksvg.KSVGDrawable

/**
 * Glide [Drawable] resource wrapping a [KSVGDrawable]. Reports the drawable's
 * retained memory for cache weighing and releases its pools on [recycle].
 */
public class KSVGDrawableResource(private val drawable: KSVGDrawable) : DrawableResource<Drawable>(drawable) {
    override fun getResourceClass(): Class<Drawable> = Drawable::class.java
    override fun getSize(): Int {
        val retained = drawable.getMemorySizeBytes()
        if (retained > 0L) {
            return retained.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
        }
        // Fresh drawable (nothing rendered yet): estimate one intrinsic-sized
        // frame so zero-size entries never sit weightless in the memory cache.
        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: FALLBACK_DIMENSION_PX
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: FALLBACK_DIMENSION_PX
        return (width.toLong() * height.toLong() * BYTES_PER_PIXEL)
            .coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }

    override fun recycle() {
        drawable.trimMemory()
    }

    private companion object {
        const val FALLBACK_DIMENSION_PX: Int = 192
        const val BYTES_PER_PIXEL: Long = 4L
    }
}