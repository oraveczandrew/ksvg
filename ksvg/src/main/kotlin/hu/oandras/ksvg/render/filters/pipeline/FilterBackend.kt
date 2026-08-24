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

import android.graphics.RenderEffect

/**
 * Minimal description of one filter graph handed to [FilterBackend.buildEffectChain].
 */
internal class FilterGraphInfo internal constructor(
    internal val primitives: FilterPrimitiveSet,
) {
    internal fun has(flag: Int): Boolean = primitives.contains(flag)
}

/**
 * One selectable filter-execution backend. Instances are owned by the render
 * operation (never shared between threads); [release] is called on teardown.
 *
 * Graph-level decision: a backend either claims the WHOLE graph via
 * [supports] or none of it — mixed CPU/GPU execution would need per-primitive
 * bitmap readback which costs more than software execution.
 */
internal interface FilterBackend {

    /** True if this backend can execute a graph composed of [primitives]. */
    fun supports(primitives: FilterPrimitiveSet): Boolean

    /**
     * Whole-graph GPU chain; null = "cannot represent this graph as an effect
     * chain". Non-null results let the caller skip all intermediate bitmaps and
     * draw the source once with `paint.setRenderEffect(chain)`.
     */
    fun buildEffectChain(graph: FilterGraphInfo): RenderEffect? = null

    /** Drops backend-owned state (shaders, effects, scratch handles). */
    fun release() {}
}
