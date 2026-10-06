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

package hu.oandras.ksvg.compose

import android.graphics.drawable.Drawable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.painter.Painter
import kotlin.math.roundToInt

/**
 * A [Painter] that draws an Android [Drawable] (typically a `KSVGDrawable`).
 *
 * `rememberDrawablePainter` lives in Accompanist, not in `androidx.compose`, so this module
 * vendors the small adapter itself: bounds are set to the draw size on every draw, drawable
 * invalidation re-triggers composition drawing, and `scheduleSelf`/`unscheduleSelf` (used by
 * `KSVGAnimatedDrawable` for its frame ticker) are coalesced through the shared
 * [KsvgFrameScheduler] — one vsync callback per frame no matter how many animated
 * cells are composed — mirroring what `View` does as a `Drawable.Callback`.
 */
internal class KsvgDrawablePainter(
    @JvmField
    val drawable: Drawable,
) : Painter() {

    private var invalidateTick: Int by mutableIntStateOf(0)

    /**
     * Frame callbacks forwarded to [KsvgFrameScheduler] through this painter, so
     * [release] can withdraw exactly the frames this cell requested without
     * touching other cells sharing the scheduler. Plain list (typically a single
     * entry) so [release] stays iterator-free.
     */
    private val scheduledFrames: ArrayList<Runnable> = ArrayList(2)

    private val callback: Drawable.Callback = object : Drawable.Callback {
        override fun invalidateDrawable(who: Drawable) {
            invalidateTick++
        }

        override fun scheduleDrawable(who: Drawable, what: Runnable, `when`: Long) {
            // `contains` on ArrayList is an index-based scan, no iterator.
            if (!scheduledFrames.contains(what)) {
                scheduledFrames.add(what)
            }
            KsvgFrameScheduler.schedule(what, `when`)
        }

        override fun unscheduleDrawable(who: Drawable, what: Runnable) {
            scheduledFrames.remove(what)
            KsvgFrameScheduler.unschedule(what)
        }
    }

    init {
        drawable.callback = callback
    }

    /**
     * Detaches from the drawable. Must be called from `onDispose` of the owning composition;
     * after this the painter must not be drawn again.
     */
    fun release() {
        // Index loop on purpose: no iterator allocation.
        for (i in scheduledFrames.indices) {
            KsvgFrameScheduler.unschedule(scheduledFrames[i])
        }
        scheduledFrames.clear()
        drawable.callback = null
    }

    override val intrinsicSize: Size
        get() {
            val width: Int = drawable.intrinsicWidth
            val height: Int = drawable.intrinsicHeight
            // KSVG reports -1 intrinsics for SVGs without width/height: fall back to
            // unspecified so hosts must supply explicit bounds instead of collapsing.
            return if (width > 0 && height > 0) {
                Size(width.toFloat(), height.toFloat())
            } else {
                Size.Unspecified
            }
        }

    override fun DrawScope.onDraw() {
        // Snapshot subscription: drawable invalidation schedules a re-draw.
        @Suppress("UNUSED_EXPRESSION")
        invalidateTick
        val width: Int = size.width.roundToInt().coerceAtLeast(0)
        val height: Int = size.height.roundToInt().coerceAtLeast(0)
        drawable.setBounds(0, 0, width, height)
        drawable.draw(drawContext.canvas.nativeCanvas)
    }

    override fun applyAlpha(alpha: Float): Boolean {
        drawable.alpha = (alpha * 255f).roundToInt().coerceIn(0, 255)
        return true
    }

    override fun applyColorFilter(colorFilter: ColorFilter?): Boolean {
        // Framework/artist color-filter mapping is left to the Drawable (tint); Compose must
        // not assume it handled the filter.
        return false
    }

    override fun equals(other: Any?): Boolean {
        return other is KsvgDrawablePainter && other.drawable === drawable
    }

    override fun hashCode(): Int {
        return drawable.hashCode()
    }
}
