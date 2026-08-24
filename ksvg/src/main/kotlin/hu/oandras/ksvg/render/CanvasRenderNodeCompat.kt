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

package hu.oandras.ksvg.render

import android.graphics.Canvas
import android.graphics.Picture
import android.graphics.RenderNode
import android.os.Build
import androidx.annotation.RequiresApi
import kotlin.math.floor

/**
 * Off-screen display-list capture for static subtrees.
 *
 * Recorded content is replayed natively, bypassing Java-level canvas hooks
 * (OEM ROMs such as OnePlus PaintExtImpl/BaseCanvasExtImpl allocate on every
 * draw operation). Implementations:
 *  - [NoOpDisplayListRecorder]: tests / software canvases (no caching).
 *  - [PictureRecorder]: API < 29, works on any canvas.
 *  - [RenderNodeRecorder]: API 29+, hardware-accelerated display lists.
 *
 * Semantics: [beginRecord] returns a canvas pre-translated by (-ox, -oy);
 * content drawn there in user coordinates replays identically through
 * [replay] regardless of the current canvas transform (the target canvas
 * matrix is applied on top, exactly like immediate-mode drawing).
 */
internal abstract class CanvasRenderNodeCompat {
    abstract val isSupported: Boolean

    /** Returns true when a capture with [key] exists and was replayed. */
    abstract fun replay(canvas: Canvas, key: Long): Boolean

    /** Starts recording; draw into the returned Canvas, then call [endRecord]. */
    abstract fun beginRecord(key: Long, width: Int, height: Int, ox: Float, oy: Float): Canvas

    abstract fun endRecord()
}

internal class NoOpDisplayListRecorder : CanvasRenderNodeCompat() {
    override val isSupported: Boolean = false
    override fun replay(canvas: Canvas, key: Long): Boolean = false
    override fun beginRecord(key: Long, width: Int, height: Int, ox: Float, oy: Float): Canvas =
        throw UnsupportedOperationException()

    override fun endRecord() {}
}

internal class PictureRecorder : CanvasRenderNodeCompat() {
    private var picture: Picture? = null
    private var key: Long = 0L
    private var ox = 0f
    private var oy = 0f

    override val isSupported: Boolean = true
    override fun replay(canvas: Canvas, key: Long): Boolean {
        val p = picture ?: return false
        if (this.key != key) return false
        // Undo the (-ox,-oy) recording translate: it was baked into the picture
        // and would otherwise be scaled/offset by the current canvas matrix.
        val save = canvas.save()
        canvas.translate(ox, oy)
        try {
            p.draw(canvas)
        } finally {
            canvas.restoreToCount(save)
        }
        return true
    }

    override fun beginRecord(key: Long, width: Int, height: Int, ox: Float, oy: Float): Canvas {
        this.key = key
        this.ox = ox
        this.oy = oy
        // Always record into a FRESH Picture: re-beginning a Picture that a
        // previously rendered frame still references causes intermittent flashes.
        val p = Picture()
        picture = p
        return p.beginRecording(maxOf(1, width), maxOf(1, height)).apply {
            translate(-ox, -oy)
        }
    }

    override fun endRecord() {
        picture?.endRecording()
    }
}

@RequiresApi(Build.VERSION_CODES.Q)
internal class RenderNodeRecorder : CanvasRenderNodeCompat() {
    private var renderNode: RenderNode? = null
    private var key: Long = 0L
    private var width = 0
    private var height = 0
    private var ox = 0f
    private var oy = 0f

    override val isSupported: Boolean = true

    override fun replay(canvas: Canvas, key: Long): Boolean {
        val rn = renderNode ?: return false

        if (this.key != key) return false

        if (!rn.hasDisplayList()) return false

        // Move the node's clip bounds over the recorded user-space area...
        val left = floor(ox).toInt()
        val top = floor(oy).toInt()
        rn.setPosition(left, top, left + width, top + height)
        // ...and put the sub-pixel remainder back via translation.
        rn.translationX = ox - left
        rn.translationY = oy - top
        canvas.drawRenderNode(rn)
        return true
    }

    override fun beginRecord(key: Long, width: Int, height: Int, ox: Float, oy: Float): Canvas {
        this.key = key
        this.width = maxOf(1, width)
        this.height = maxOf(1, height)
        this.ox = ox
        this.oy = oy
        val rn = renderNode ?: RenderNode("ksvg").also { renderNode = it }
        rn.setPosition(
            floor(ox).toInt(), floor(oy).toInt(),
            floor(ox).toInt() + this.width, floor(oy).toInt() + this.height
        )
        val c = rn.beginRecording(this.width, this.height)
        c.translate(-ox, -oy)
        return c
    }

    override fun endRecord() {
        renderNode!!.endRecording()
    }
}

internal object CanvasRenderNodeCompatFactory {
    /**
     * Picks the recorder for the given target canvas. Software/mock canvases
     * (tests, bitmap rendering) get a NoOp so individual draw operations stay
     * observable; hardware-accelerated canvases get native display lists.
     */
    fun create(target: Canvas): CanvasRenderNodeCompat {
        return when {
            !target.isHardwareAccelerated -> NoOpDisplayListRecorder()
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> RenderNodeRecorder()
            else -> PictureRecorder()
        }
    }
}
