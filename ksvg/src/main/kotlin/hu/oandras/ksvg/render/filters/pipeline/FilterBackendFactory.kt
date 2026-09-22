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

import android.os.Build
import hu.oandras.ksvg.render.Renderer

/**
 * Capability-based filter-backend factory. Graph-level selection lives in
 * `Renderer.obtainFilterBackend`: it tries the GPU backend first (which may
 * still reject a graph while building the effect chain) and always falls back
 * to the software backend created here.
 */
internal object FilterBackendFactory {

    @JvmStatic
    internal fun createSoftware(renderer: Renderer): SoftwareFilterBackend =
        SoftwareFilterBackend(renderer)

    @JvmStatic
    internal fun createGpuOrNull(renderer: Renderer): FilterBackend? =
        when {
            Build.VERSION.SDK_INT >= 33 -> GpuFilterBackendApi33(renderer)
            Build.VERSION.SDK_INT >= 31 -> GpuFilterBackend(renderer)
            else -> null
        }
}
