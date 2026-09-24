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
//
// SIMD_AVX2 additionally implies FMA (CPUID.1:ECX bit 12): the x86_64
// lighting pow rows (POW8_FMA_STEP in lighting_x86_64_avx2_macros.S, shared
// by all five AVX2 diffuse/specular kernels) execute vfmadd213ps, and FMA is
// a separate feature bit that AVX2 does not imply. A hypervisor may mask FMA
// while reporting AVX2; executing the pow row there faults with SIGILL, so
// such CPUs stay on the SSSE3 rows instead.

enum SimdLevel {
    SIMD_SSE2 = 0,
    SIMD_SSSE3 = 1,
    SIMD_AVX2 = 2,
};

#if defined(__x86_64__) || defined(__i386__)
// Raw-CPUID AVX2+FMA gate.
//
// __builtin_cpu_supports("avx2") additionally relies on CPUID.1:ECX.OSXSAVE,
// which the Android emulator's HVF CPUID mask may clear even though the guest
// kernel has enabled CR4.OSXSAVE and XCR0.YMM, and the AVX2 kernels provably
// execute correctly there. So the OSXSAVE *report* is not used as evidence
// of AVX2: the actual XCR0 state is read directly instead. It IS still used
// as an execution gate: XGETBV faults with #UD when CR4.OSXSAVE is clear, so
// without the OSXSAVE report the raw path declines instead of faulting.
//
// XCR0.YMM proves the OS saves/restores the YMM register state AVX requires;
// on real silicon this produces the same result as normal AVX2 detection, it
// is just robust against the emulator's masked OSXSAVE bit.
//
// FMA (CPUID.1:ECX bit 12) is required alongside AVX2 because the x86_64
// lighting pow rows execute vfmadd213ps, which AVX2 alone does not guarantee.
inline bool cpuHasAvx2AndFmaRaw() {
    uint32_t a, b, c, d;

    // CPUID.1:ECX.XSAVE (bit 26) is the hardware precondition, but XGETBV
    // itself faults with #UD (SIGILL) unless the OS enabled it via
    // CR4.OSXSAVE, reported as CPUID.1:ECX.OSXSAVE (bit 27). Gate on both:
    // without OSXSAVE there is no YMM state for the OS to report, AVX2 is
    // unusable, and XGETBV must not execute. Bit 12 in the same leaf reports
    // FMA, which the lighting AVX2 pow rows require.
    __asm__ volatile(
        "mov $1, %%eax; cpuid"
        : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
        :
        : "cc");
    if ((c & (1u << 26)) == 0 || (c & (1u << 27)) == 0) {
        return false;
    }
    const bool hasFma = (c & (1u << 12)) != 0;

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

    // CPUID.7.0:EBX[5] = AVX2. FMA was read from CPUID.1 above: the
    // lighting AVX2 pow rows need both, so both are required here.
    __asm__ volatile(
        "mov $7, %%eax; xor %%ecx, %%ecx; cpuid"
        : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
        :
        : "cc");
    return hasFma && (b & (1u << 5)) != 0;
}
#endif

inline SimdLevel detectSimdLevel() {
#if defined(__x86_64__) || defined(__i386__)
    static const SimdLevel level = []() {
        // OR short-circuit: on real silicon the one-time builtin flag is the
        // fast path and the raw CPUID sequence never runs; only in environments
        // that clear OSXSAVE (Android emulator HVF) does the raw fallback run.
        // Both legs require FMA alongside AVX2: the x86_64 lighting pow rows
        // execute vfmadd213ps, which AVX2 alone does not guarantee.
        const bool builtinAvx2Fma = __builtin_cpu_supports("avx2") && __builtin_cpu_supports("fma");
        if (builtinAvx2Fma || cpuHasAvx2AndFmaRaw()) {
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
    SIMD_BACKEND_NEON64 = 1 << 4,
    SIMD_BACKEND_NEON32 = 1 << 5,
    SIMD_BACKEND_SSE2   = 1 << 6,
};

struct LightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss;
};

// Point-light kernel parameter block.  The assembly rows compute the
// per-pixel light direction from (lx,ly,lz) - (ux,uy,surfaceZ).
struct PointLightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss, ux0, uy, dux;
};

// Spot-light kernel parameter block.  Extends PointLightingParams with the
// normalised direction-to-target and cosine of the cutoff cone angle.
struct SpotLightingParams {
    float invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss, ux0, uy, dux,
          spotDirX, spotDirY, spotDirZ, spotCos;
};

#endif // KSVG_CPU_DISPATCH_H
