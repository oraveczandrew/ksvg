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

#include <cstdint>

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

#if defined(__x86_64__) || defined(__i386__)
// Raw-CPUID AVX2 gate.
//
// __builtin_cpu_supports("avx2") additionally relies on CPUID.1:ECX.OSXSAVE,
// which the Android emulator's HVF CPUID mask may clear even though the guest
// kernel has enabled CR4.OSXSAVE and XCR0.YMM, and the AVX2 kernels provably
// execute correctly there. So the OSXSAVE *report* is used neither as evidence
// of AVX2 nor as a gate: the actual XCR0 state is read directly instead.
//
// XCR0.YMM proves the OS saves/restores the YMM register state AVX requires;
// on real silicon this produces the same result as normal AVX2 detection, it
// is just robust against the emulator's masked OSXSAVE bit.
inline bool cpuHasAvx2Raw() {
    uint32_t a, b, c, d;

    // CPUID.1:ECX.XSAVE - sanity precondition: XCR0/XGETBV only exist
    // when the XSAVE feature set is present.
    __asm__ volatile(
        "mov $1, %%eax; cpuid"
        : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
        :
        : "cc");
    if ((c & (1u << 26)) == 0) {
        return false;
    }

    // XCR0[2] = YMM state enabled by the OS.
    uint32_t xlo, xhi;
    __asm__ volatile(
        "xgetbv"
        : "=a"(xlo), "=d"(xhi)
        : "c"(0));
    const uint64_t xcr0 = (static_cast<uint64_t>(xhi) << 32) | xlo;
    if ((xcr0 & (1ull << 2)) == 0) {
        return false;
    }

    // CPUID.7.0:EBX[5] = AVX2
    __asm__ volatile(
        "mov $7, %%eax; xor %%ecx, %%ecx; cpuid"
        : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
        :
        : "cc");
    return (b & (1u << 5)) != 0;
}
#endif

inline SimdLevel detectSimdLevel() {
#if defined(__x86_64__) || defined(__i386__)
    static const SimdLevel level = []() {
        // AVX-512 stays on __builtin_cpu_supports: the emulator masks the
        // AVX-512 CPUID bits and never enables the ZMM XCR0 state, so raw
        // detection must NOT unlock a backend that would #UD there.
        if (__builtin_cpu_supports("avx512f") && __builtin_cpu_supports("avx512bw")) {
            return SIMD_AVX512;
        }
        // OR short-circuit: on real silicon the one-time builtin flag is the
        // fast path and the raw CPUID sequence never runs; only in environments
        // that clear OSXSAVE (Android emulator HVF) does the raw fallback run.
        if (__builtin_cpu_supports("avx2") || cpuHasAvx2Raw()) {
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
// These are now flags so nativeBackend() can return all supported backends.
enum SimdBackend {
    SIMD_BACKEND_SCALAR = 1 << 0,
    SIMD_BACKEND_SSSE3  = 1 << 1,
    SIMD_BACKEND_AVX2   = 1 << 2,
    SIMD_BACKEND_AVX512 = 1 << 3,
    SIMD_BACKEND_NEON64 = 1 << 4,
    SIMD_BACKEND_NEON32 = 1 << 5,
    SIMD_BACKEND_SSE2   = 1 << 6,
};

struct LightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss;
};

#endif // KSVG_CPU_DISPATCH_H
