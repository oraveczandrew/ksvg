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

package hu.oandras.ksvg.filtering

internal object NativeBackend {
    @JvmField
    internal var loadError: RuntimeException? = null

    @JvmField
    val isAvailable: Boolean = try {
        System.loadLibrary("ksvgfilters")
        true
    } catch (t: Throwable) {
        loadError = RuntimeException(
            "Failed to load native KSVG filter library (libksvgfilters.so). " +
                    "Falling back to slow Kotlin kernels. Performance will be significantly degraded. " +
                    "Check if the APK contains the correct .so files for the current device ABI.",
            t
        )
        false
    }

    /**
     * Kernel-independent device capability mask ([SimdBackend] flags); see
     * `simd_capabilities.cpp`. Plain (non-internal) member so the JNI symbol
     * stays unmangled (see AGENTS.md); the surface stays internal via the
     * enclosing object.
     */
    @JvmStatic
    @SimdBackend
    external fun supportedBackendsMask(): Int
}
