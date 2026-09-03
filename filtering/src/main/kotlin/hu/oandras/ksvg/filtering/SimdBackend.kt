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

import androidx.annotation.IntDef

/**
 * Backend identifiers mirrored from `cpu_dispatch.h`'s `SimdBackend` enum.
 * These are flags so [nativeBackend] can return all available implementations.
 */
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    flag = true,
    value = [
        SIMD_SCALAR,
        SIMD_SSSE3,
        SIMD_AVX2,
        SIMD_AVX512,
        SIMD_NEON64,
        SIMD_NEON32,
    ]
)
public annotation class SimdBackend

public const val SIMD_SCALAR: Int = 1 shl 0
public const val SIMD_SSSE3: Int = 1 shl 1
public const val SIMD_AVX2: Int = 1 shl 2
public const val SIMD_AVX512: Int = 1 shl 3
public const val SIMD_NEON64: Int = 1 shl 4
public const val SIMD_NEON32: Int = 1 shl 5

internal fun backendName(backend: Int): String = when (backend) {
    SIMD_SCALAR -> "scalar"
    SIMD_SSSE3 -> "ssse3"
    SIMD_AVX2 -> "avx2"
    SIMD_AVX512 -> "avx512"
    SIMD_NEON64 -> "neon64"
    SIMD_NEON32 -> "neon32"
    else -> backend.toString()
}
