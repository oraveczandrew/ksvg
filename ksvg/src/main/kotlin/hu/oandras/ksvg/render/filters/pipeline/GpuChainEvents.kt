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

import hu.oandras.ksvg.render.FilterRenderNode

/**
 * Test-only record of which backend drew each filter (`tmp/GPU_PARITY_PLAN_E.md`).
 *
 * Pixel asserts cannot distinguish "GPU rendered correctly" from "GPU
 * silently declined and software rendered instead" (vacuous pass). The
 * three `drawFiltered` implementations record one event per filter use,
 * so parity tests can assert the GPU took the chain and fallback tests
 * can assert it declined. A LIST (not a map): one filter node shared by
 * several elements records one event per use, which is exactly what
 * guards the per-element slot fix (shared `#shadow` must appear twice).
 *
 * Zero production cost when unregistered: [record] is a single null check.
 * Registration is test-only ([GpuParityHarness] registers around renders).
 * Events are cleared per render by the harness; assert immediately after
 * the measured render.
 */
internal object GpuChainEvents {

    /** Sink invoked per filter draw, or null when nobody listens. */
    @JvmField
    @Volatile
    var listener: ((filterId: String, backend: String) -> Unit)? = null

    /**
     * Backend key for hardware chain draws.
     * ([SoftwareFilterBackend] records [SW].)
     */
    const val GPU: String = "gpu"

    /** Backend key for software fallback draws. */
    const val SW: String = "sw"

    internal fun record(filterNode: FilterRenderNode, backend: String) {
        val sink = listener ?: return
        val id = filterNode.sourceElement.id
        sink(if (id.isNullOrEmpty()) "(anonymous)" else id, backend)
    }
}
