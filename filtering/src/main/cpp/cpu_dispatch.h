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

#ifndef KSVG_CPU_DISPATCH_H
#define KSVG_CPU_DISPATCH_H

// One-time x86 SIMD level detection shared by the filter kernels.
//
// The kernels ship multiple code paths compiled with `target(...)` attributes;
// this detector picks the highest safe one exactly once per process. Baseline
// is always SSE2, so non-x86 and pre-AVX CPUs fall back safely.

enum SimdLevel {
    SIMD_SSE2 = 0,
    SIMD_SSSE3 = 1,
    SIMD_AVX2 = 2,
    SIMD_AVX512 = 3,
};

inline SimdLevel detectSimdLevel() {
#if defined(__x86_64__) || defined(__i386__)
    static const SimdLevel level = []() {
        if (__builtin_cpu_supports("avx512f") && __builtin_cpu_supports("avx512bw")) {
            return SIMD_AVX512;
        }
        if (__builtin_cpu_supports("avx2")) {
            return SIMD_AVX2;
        }
        if (__builtin_cpu_supports("ssse3")) {
            return SIMD_SSSE3;
        }
        return SIMD_SSE2;
    }();
    return level;
#else
    return SIMD_SSE2;
#endif
}

// Explicit backend identifiers shared between C++ and the Kotlin test harness.
// Unlike SimdLevel (the highest ISA a CPU supports), a SimdBackend names the
// exact implementation to run, so a test can force one regardless of dispatch.
enum SimdBackend {
    SIMD_BACKEND_SCALAR = 1,
    SIMD_BACKEND_SSSE3 = 2,
    SIMD_BACKEND_AVX2 = 3,
    SIMD_BACKEND_AVX512 = 4,
    SIMD_BACKEND_NEON64 = 5,
    SIMD_BACKEND_NEON32 = 6,
};

#endif // KSVG_CPU_DISPATCH_H
