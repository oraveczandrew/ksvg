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

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Choreographer
import androidx.collection.MutableLongList

/**
 * Coalescing frame scheduler for `KSVGAnimatedDrawable` tickers hosted in Compose.
 *
 * Previously every [KsvgDrawablePainter] forwarded `scheduleSelf` to its own
 * main-looper [Handler], so a grid of N animated cells posted N messages every
 * 16 ms with wall-clock (not vsync-aligned) timing. This object collapses that
 * into a single [Choreographer] callback per vsync: each drawable still owns its
 * frame `Runnable` chain and its own animation clock, only the wake-ups are
 * batched. Per-drawable due times (`Drawable.scheduleSelf(when)`) are honored,
 * so throttled or paused drawables are not pulled forward.
 *
 * All states are confined to the main thread; calls from other threads are
 * marshaled through the main [Handler].
 */
internal object KsvgFrameScheduler {

    private val mainLooper: Looper = Looper.getMainLooper()
    private val handler: Handler = Handler(mainLooper)

    /** Pending frame callbacks. Main thread only. Parallel to [pendingDueMs]. */
    private val pendingFrames: ArrayList<Runnable> = ArrayList()

    /**
     * `uptimeMillis` due time per entry of [pendingFrames]. Primitive list, so
     * per-frame re-registration never boxes. Main thread only.
     */
    private val pendingDueMs: MutableLongList = MutableLongList(16)

    /** Reused scratch list for due callbacks; avoids per-frame iteration hazards. Main thread only. */
    private val dueScratch: ArrayList<Runnable> = ArrayList()

    private var frameScheduled: Boolean = false

    private val frameCallback: Choreographer.FrameCallback = Choreographer.FrameCallback {
        onFrame()
    }

    private val fallbackRunnable: Runnable = Runnable {
        onFrame()
    }

    internal fun schedule(what: Runnable, `when`: Long) {
        if (Looper.myLooper() != mainLooper) {
            handler.post { schedule(what, `when`) }
            return
        }
        val index: Int = indexOfFrame(what)
        if (index >= 0) {
            pendingDueMs[index] = `when`
        } else {
            pendingFrames.add(what)
            pendingDueMs.add(`when`)
        }
        ensureScheduled()
    }

    internal fun unschedule(what: Runnable) {
        if (Looper.myLooper() != mainLooper) {
            handler.post { unschedule(what) }
            return
        }
        removeAt(indexOfFrame(what))
        if (pendingFrames.isEmpty()) {
            cancelScheduled()
        }
    }

    /** Identity-aware linear search; index loops only, no iterator. */
    private fun indexOfFrame(what: Runnable): Int {
        for (i in pendingFrames.indices) {
            if (pendingFrames[i] === what) {
                return i
            }
        }
        return -1
    }

    /** Swap-remove: order is irrelevant, removal is O(1). No-op for negative indices. */
    private fun removeAt(index: Int) {
        if (index < 0) return
        val last: Int = pendingFrames.size - 1
        if (index != last) {
            pendingFrames[index] = pendingFrames[last]
            pendingDueMs[index] = pendingDueMs[last]
        }
        pendingFrames.removeAt(last)
        pendingDueMs.removeAt(last)
    }

    private fun ensureScheduled() {
        if (frameScheduled || pendingFrames.isEmpty()) return
        frameScheduled = true
        try {
            Choreographer.getInstance().postFrameCallback(frameCallback)
        } catch (_: RuntimeException) {
            // No vsync source (e.g., plain unit tests): fall back to a timed post.
            handler.postDelayed(fallbackRunnable, nextDelayMs())
        }
    }

    private fun cancelScheduled() {
        if (!frameScheduled) return
        frameScheduled = false
        try {
            Choreographer.getInstance().removeFrameCallback(frameCallback)
        } catch (_: RuntimeException) {
            // Ignore: no vsync source registered the callback.
        }
        handler.removeCallbacks(fallbackRunnable)
    }

    private fun nextDelayMs(): Long {
        val now: Long = SystemClock.uptimeMillis()
        var earliest: Long = Long.MAX_VALUE
        for (i in pendingFrames.indices) {
            val due: Long = pendingDueMs[i]
            if (due < earliest) {
                earliest = due
            }
        }
        if (earliest == Long.MAX_VALUE) return 0L
        return (earliest - now).coerceAtLeast(0L)
    }

    @JvmSynthetic
    internal fun onFrame() {
        frameScheduled = false
        if (pendingFrames.isEmpty()) return
        val now: Long = SystemClock.uptimeMillis()
        dueScratch.clear()
        for (i in pendingFrames.indices) {
            if (pendingDueMs[i] <= now) {
                dueScratch.add(pendingFrames[i])
            }
        }
        for (i in dueScratch.indices) {
            val frame: Runnable = dueScratch[i]
            // Remove before running: the callback re-registers itself when it
            // schedules the next frame, and `unscheduleSelf` inside must win
            // over a stale entry.
            removeAt(indexOfFrame(frame))
            frame.run()
        }
        dueScratch.clear()
        // Re-arm for rescheduled frames and for future-due entries.
        if (pendingFrames.isNotEmpty()) {
            ensureScheduled()
        }
    }
}
