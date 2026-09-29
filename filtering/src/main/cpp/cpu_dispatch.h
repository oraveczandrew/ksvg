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

#if defined(__x86_64__) || defined(__i386__)
#include <csetjmp>
#include <csignal>
#endif

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
// which the Android emulator's HVF CPUID mask clears even though the guest
// kernel has enabled CR4.OSXSAVE and XCR0.YMM (device-verified 2026-09-29:
// leaf1 ECX bit 27 = 0 while XGETBV returns XCR0 = 0x7 and YMM ops execute
// fine on both an API-26 x86 and an API-29 x86_64 emulator). So the OSXSAVE
// *report* is used neither as evidence of AVX2 nor as an execution gate:
// the actual XCR0 state is read directly instead, with XGETBV executed under
// a one-shot SIGILL guard, because XGETBV faults with #UD when CR4.OSXSAVE
// is really clear and the CPUID report cannot be trusted to tell beforehand.
//
// XCR0.YMM proves the OS saves/restores the YMM register state AVX requires;
// on real silicon this produces the same result as normal AVX2 detection, it
// is just robust against the emulator's masked OSXSAVE bit.
//
// FMA (CPUID.1:ECX bit 12) is required alongside AVX2 because the x86_64
// lighting pow rows execute vfmadd213ps, which AVX2 alone does not guarantee.
namespace ksvg_cpu_dispatch {

inline sigjmp_buf* xgetbvJumpTarget() {
    static sigjmp_buf buf;
    return &buf;
}

inline void xgetbvSigillHandler(int) {
    siglongjmp(*xgetbvJumpTarget(), 1);
}

// Reads XCR0 under a SIGILL guard; returns false when XGETBV itself faults
// (CR4.OSXSAVE genuinely clear), in which case xcr0 is left untouched.
inline bool readXcr0Guarded(uint64_t& xcr0) {
    struct sigaction oldAct {};
    struct sigaction newAct {};
    newAct.sa_handler = xgetbvSigillHandler;
    sigemptyset(&newAct.sa_mask);
    newAct.sa_flags = 0;
    if (sigaction(SIGILL, &newAct, &oldAct) != 0) {
        return false;
    }
    bool ok = false;
    if (sigsetjmp(*xgetbvJumpTarget(), 1) == 0) {
        uint32_t xlo = 0;
        uint32_t xhi = 0;
        __asm__ volatile(
            "xgetbv"
            : "=a"(xlo), "=d"(xhi)
            : "c"(0));
        xcr0 = (static_cast<uint64_t>(xhi) << 32) | xlo;
        ok = true;
    }
    sigaction(SIGILL, &oldAct, nullptr);
    return ok;
}

} // namespace ksvg_cpu_dispatch

inline bool cpuHasAvx2AndFmaRaw() {
    uint32_t a, b, c, d;

    // CPUID.1:ECX bit 12 reports FMA, which the lighting AVX2 pow rows
    // require. The XSAVE (bit 26) / OSXSAVE (bit 27) reports are deliberately
    // NOT consulted: the emulator masks bit 27 while XCR0.YMM is really
    // enabled, so they are evidence of nothing either way.
    __asm__ volatile(
        "mov $1, %%eax; cpuid"
        : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
        :
        : "cc");
    const bool hasFma = (c & (1u << 12)) != 0;
    if (!hasFma) {
        return false;
    }

    // XCR0[2] = YMM state enabled by the OS. Guarded: faults with #UD only
    // when CR4.OSXSAVE is genuinely clear, in which case AVX2 is unusable.
    uint64_t xcr0 = 0;
    if (!ksvg_cpu_dispatch::readXcr0Guarded(xcr0)) {
        return false;
    }
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

#endif // KSVG_CPU_DISPATCH_H
