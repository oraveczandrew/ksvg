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

package hu.oandras.ksvg.render.filters.pipeline

import android.graphics.Matrix
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.RenderNode

/**
 * Per-element GPU fast-path state for one [FilterRenderNode].
 *
 * Several elements may share a single filter node (e.g. one `blur` filter
 * referenced twice); each needs its own source recording and effect chain.
 * A single shared slot makes all but the last element draw the last one's
 * recorded content on deferred hardware canvases (endpoint `filters.svg`
 * precedent: a shared dropShadow filter dropped every element but the
 * last). Slots live in the filter node's slot map keyed by element and die
 * with it; the version/scale/position keys below invalidate stale entries
 * in place, exactly like the former single-slot fields did.
 */
internal class GpuFilterSlot internal constructor() {
    @JvmField var gpuNode: android.graphics.RenderNode? = null
    @JvmField var gpuSourceVersion: Int = -1
    @JvmField var gpuFilterVersion: Int = -1
    @JvmField var gpuScaleX: Float = 0f
    @JvmField var gpuScaleY: Float = 0f
    @JvmField var gpuWidth: Int = 0
    @JvmField var gpuHeight: Int = 0
    @JvmField var gpuPadX: Int = 0
    @JvmField var gpuPadY: Int = 0

    /**
     * The CTM captured when the source display list was recorded. Content
     * and matrix are baked into the display list, so either changing
     * invalidates it (e.g., an animated transform must force a re-record
     * every frame).
     */
    @JvmField var gpuSourceMatrix: Matrix? = null

    /** Built effect chain cache: depends on the filter's attributes
     * (version) and the primitive scales, not on the rendered content. */
    @JvmField var gpuChain: FilterPipelineImpl31.Chain? = null
    @JvmField var gpuChainVersion: Int = -1
    @JvmField var gpuChainScaleX: Float = 0f
    @JvmField var gpuChainScaleY: Float = 0f
    @JvmField var gpuChainDeviceLeft: Float = 0f
    @JvmField var gpuChainDeviceTop: Float = 0f
}

/**
 * Returns the GPU slot for [element], creating it on first use. Callers in
 * the pipeline pass their element render node ([FilterBackend] provides it
 * at every entry point that needs GPU state).
 */
internal fun FilterRenderNode.gpuSlotFor(element: RenderNode<*>): GpuFilterSlot {
    return gpuSlots.getOrPut(element) { GpuFilterSlot() }
}
