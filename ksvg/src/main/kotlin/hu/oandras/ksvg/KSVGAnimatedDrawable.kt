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
package hu.oandras.ksvg

import android.graphics.drawable.Animatable2
import android.graphics.drawable.Drawable
import android.os.SystemClock
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.utils.forEachElement

private const val FRAME_DELAY_MS: Long = 16L

/**
 * An animatable [Drawable] backed by an [SVG] document.
 *
 * This class provides the Android animation lifecycle. SVG SMIL evaluation is intentionally kept
 * behind this drawable boundary so the renderer can be extended without changing the public API.
 */
public open class KSVGAnimatedDrawable @JvmOverloads public constructor(
    svg: SVG,
    renderOptions: RenderOptions? = null
) : KSVGDrawable(svg, renderOptions), Animatable2 {

    private val callbacks: ArrayList<Animatable2.AnimationCallback> = ArrayList()
    private var running: Boolean = false
    private var startedAtMs: Long = 0L

    private val frameRunnable: Runnable = Runnable {
        if (!running) {
            return@Runnable
        }
        invalidateSelf()
        scheduleNextFrame()
    }

    override fun draw(canvas: android.graphics.Canvas) {
        val svgImpl = svg as? SVGImpl
        if (svgImpl != null && running) {
            svgImpl.animationTimeMs = SystemClock.uptimeMillis() - startedAtMs
        }
        super.draw(canvas)
    }

    override fun start() {
        if (!hasAnimation) return

        val wasRunning = running
        running = true
        // Always reset the time base so a drawable that is reused (e.g. by Glide's
        // resource cache) restarts its animation cleanly instead of freezing on a
        // stale start timestamp.
        startedAtMs = SystemClock.uptimeMillis()
        if (!wasRunning) {
            callbacks.forEachElement { it.onAnimationStart(this) }
        }
        invalidateSelf()
        scheduleNextFrame()
    }

    /**
     * Stops the ticker and releases all pooled render memory ([trimMemory]).
     * Stopping is terminal: a later [start] reallocates the pools, so hosts
     * that only toggle visibility should rely on `setVisible` (which keeps
     * the pools) instead of stop/start cycles. Hosts that drop the drawable
     * must still call [stop] (or `Glide.clear()`).
     */
    override fun stop() {
        if (!running) return
        running = false
        unscheduleSelf(frameRunnable)
        callbacks.forEachElement { it.onAnimationEnd(this) }
        trimMemory()
    }

    override fun isRunning(): Boolean = running

    /**
     * Pauses the ticker while invisible (detached/recycled views, hidden tabs)
     * and resumes it when visible again. `running` is preserved across the gap
     * so hosts that only toggle visibility never leak a ticking drawable.
     * Hosts that drop the drawable must still call [stop] (or `Glide.clear()`).
     */
    override fun setVisible(visible: Boolean, restart: Boolean): Boolean {
        val changed = super.setVisible(visible, restart)
        if (visible) {
            if (running) {
                invalidateSelf()
                scheduleNextFrame()
            }
        } else {
            unscheduleSelf(frameRunnable)
        }
        return changed
    }

    override fun registerAnimationCallback(callback: Animatable2.AnimationCallback) {
        if (callback !in callbacks) {
            callbacks.add(callback)
        }
    }

    override fun unregisterAnimationCallback(callback: Animatable2.AnimationCallback): Boolean {
        return callbacks.remove(callback)
    }

    override fun clearAnimationCallbacks() {
        callbacks.clear()
    }

    private fun scheduleNextFrame() {
        unscheduleSelf(frameRunnable)
        scheduleSelf(frameRunnable, SystemClock.uptimeMillis() + FRAME_DELAY_MS)
    }
}
