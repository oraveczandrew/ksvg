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

package hu.oandras.ksvg.render.filters.pipeline

import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.RectF
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState

/**
 * One selectable filter-execution backend. Both backends (GPU and software)
 * expose the SAME external API through this interface; the renderer only sees
 * these generic calls. Instances are owned by the render operation (never
 * shared between threads); [release] is called on teardown.
 */
internal interface FilterBackend {

    /** True if this backend can execute a graph composed of [primitives]. */
    fun supports(primitives: FilterPrimitiveSet): Boolean

    /**
     * Starts producing the backend-specific representation of the unfiltered
     * source content. Returns the canvas the caller must record the source
     * into, or null when nothing has to be recorded (cached representation is
     * still valid). Must be followed by [endRecording] when non-null was
     * returned.
     */
    fun beginRecording(
        node: RenderNode<*>,
        filterNode: FilterRenderNode,
        width: Int,
        height: Int,
        sx: Float,
        sy: Float,
        matrix: Matrix,
        newMatrix: Matrix,
        filterRegion: RectF,
        deviceRegion: RectF,
        boundingBox: Box,
    ): Canvas?

    /** Finishes the recording started by a non-null [beginRecording] result. */
    fun endRecording(filterNode: FilterRenderNode)

    /**
     * Draws the filtered result of the recorded source onto [canvas],
     * executing any pending filter work first.
     */
    fun drawFiltered(
        canvas: Canvas,
        node: RenderNode<*>,
        filterNode: FilterRenderNode,
        width: Int,
        height: Int,
        sx: Float,
        sy: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        boundingBox: Box,
        state: RendererState,
    )

    /** Drops backend-owned state (shaders, effects, scratch handles). */
    fun release()
}
