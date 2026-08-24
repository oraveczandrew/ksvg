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

package hu.oandras.ksvg.filtering.pipeline

import android.os.Build

/**
 * Capability-based filter-pipeline factory. Selection is graph-level: the
 * first backend whose [FilterBackend.supports] accepts the required primitive
 * set wins; the CPU/native backend is always the final fallback.
 *
 * Order (see tmp/plan-filter-pipeline.md §2):
 * 1. software canvas or API < 31  → [FilterPipelineNativeImpl]
 * 2. API ≥ 33                     → Impl33 (AGSL) — future phase
 * 3. API ≥ 31                     → Impl31 (RenderEffect) — future phase
 * 4. otherwise                    → [FilterPipelineNativeImpl]
 */
public object FilterPipeline {

    @JvmStatic
    public fun create(canvas: android.graphics.Canvas): FilterBackend {
        if (!canvas.isHardwareAccelerated || Build.VERSION.SDK_INT < 31) {
            return FilterPipelineNativeImpl()
        }
        // FilterPipelineImpl33 / FilterPipelineImpl31 are wired up in later phases;
        // until then every hardware canvas also takes the native backend.
        return FilterPipelineNativeImpl()
    }
}
