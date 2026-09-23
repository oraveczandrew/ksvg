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

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.render.Renderer

/**
 * Capability-based filter-backend factory. Graph-level selection lives in
 * `Renderer.obtainFilterBackend`: it tries the GPU backend first (which may
 * still reject a graph while building the effect chain) and always falls back
 * to the software backend created here.
 *
 * The API-level routing ([forApi]) is a pure function of the SDK level so it
 * stays host-unit-testable, and the chosen factory travels into [Renderer] as
 * a constructor parameter, so device tests can inject [FilterBackendFactoryImpl31]
 * on any API 31+ device (the Impl31 path would otherwise only run on API 31-32
 * hardware).
 */
internal interface FilterBackendFactory {
    fun createSoftware(renderer: Renderer): SoftwareFilterBackend
    fun createGpuOrNull(renderer: Renderer): FilterBackend?

    companion object {

        @SuppressLint("UseRequiresApi")
        @TargetApi(Build.VERSION_CODES.TIRAMISU)
        @JvmStatic
        fun forApi(sdkInt: Int = Build.VERSION.SDK_INT): FilterBackendFactory =
            when {
                sdkInt >= Build.VERSION_CODES.TIRAMISU -> FilterBackendFactoryImpl33
                sdkInt >= Build.VERSION_CODES.S -> FilterBackendFactoryImpl31
                else -> FilterBackendFactoryImpl26
            }
    }
}

/** RenderEffect backend of API 33+ (wide primitive mask). Installed only on API 33+. */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal object FilterBackendFactoryImpl33 : FilterBackendFactory {
    override fun createSoftware(renderer: Renderer): SoftwareFilterBackend =
        SoftwareFilterBackend(renderer)

    override fun createGpuOrNull(renderer: Renderer): FilterBackend =
        GpuFilterBackendApi33(renderer)
}

/** RenderEffect backend of API 31-32 (linear ColorMatrix/Blur/Offset chains). */
@RequiresApi(Build.VERSION_CODES.S)
internal object FilterBackendFactoryImpl31 : FilterBackendFactory {
    override fun createSoftware(renderer: Renderer): SoftwareFilterBackend =
        SoftwareFilterBackend(renderer)

    override fun createGpuOrNull(renderer: Renderer): FilterBackend = GpuFilterBackend(renderer)
}

/**
 * Pre-API-31 factory: no GPU backend exists below API 31, so [createGpuOrNull]
 * returns null and rendering falls back to software — same contract as before.
 */
internal object FilterBackendFactoryImpl26 : FilterBackendFactory {
    override fun createSoftware(renderer: Renderer): SoftwareFilterBackend =
        SoftwareFilterBackend(renderer)

    override fun createGpuOrNull(renderer: Renderer): FilterBackend? = null
}
