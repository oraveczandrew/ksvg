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

/**
 * The SIMD backends whose flag bits are set in [flags] (the bitmask a
 * `XxxNative.nativeBackend()`/`UnLinearizeNative.nativeBackend()` call
 * advertises) for the host/device CPU the test is running on. Shared by the
 * host JVM parity tests (`src/test`) and the Android instrumented parity tests
 * (`src/androidTest`), which both force every advertised backend over the
 * corpus.
 */
public fun getBackendsFor(@SimdBackend flags: Int): IntArray {
    val all = intArrayOf(
        SIMD_SCALAR,
        SIMD_SSSE3,
        SIMD_AVX2,
        SIMD_AVX512,
        SIMD_NEON64,
        SIMD_NEON32,
    )
    return all.filter { (flags and it) != 0 }.toIntArray()
}
