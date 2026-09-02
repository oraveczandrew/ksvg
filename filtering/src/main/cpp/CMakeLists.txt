cmake_minimum_required(VERSION 3.22.1)

project("ksvgblur" LANGUAGES C CXX ASM)

# ----------------------------------------------------------------------------
# Native Gaussian blur backends, ported from the Android RenderScript
# Intrinsics Replacement Toolkit's `Blur` (Apache-2.0).
#
# Each file below is an OPTIMIZED kernel set for one ISA, compiled into
# libksvgblur.so for the matching ABI only. gaussian_blur.cpp dispatches the
# isotropic case (stdDeviationX == stdDeviationY, radius <= 25) through these
# kernels (with a zero-padded copy so edges read transparent black), and uses
# its own pure-C++ scalar two-pass fallback for anisotropic / large radii.
# ----------------------------------------------------------------------------

# ARM32 NEON kernels (32-bit ARM assembly).
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(BLUR_SOURCES Blur_advsimd.S)
    set(BLUR_NEEDS_NEON TRUE)
endif()

# AArch64 NEON kernels (64-bit ARM assembly). Same symbol/ABI contract as the
# 32-bit kernel above (single combined vertical+horizontal separable pass).
if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(BLUR_SOURCES Blur_advsimd64.S)
endif()

add_library(ksvgblur SHARED gaussian_blur.cpp component_transfer.cpp unlinearize.cpp arithmetic_composite.cpp displacement_map.cpp convolve_matrix.cpp morphology.cpp turbulence.cpp lighting.cpp blur_x86.cpp ${BLUR_SOURCES})

# Bit-exact float parity with the Kotlin reference loops: forbid FMA contraction.
target_compile_options(ksvgblur PRIVATE -ffp-contract=off)

# SSSE3 is required for the x86 pshufb LUT path (component_transfer.cpp).
# Every known Android x86 device satisfies this.
if(ANDROID_ABI STREQUAL "x86" OR ANDROID_ABI STREQUAL "x86_64")
    target_compile_options(ksvgblur PRIVATE -mssse3)
    # Per-file flags make <immintrin.h> declare the AVX2/AVX-512 intrinsics
    # (invalid options on ARM ABIs, hence the guard).
    set_source_files_properties(simd_x86_avx2.cpp PROPERTIES COMPILE_OPTIONS "-mavx2")
    set_source_files_properties(simd_x86_avx512.cpp PROPERTIES COMPILE_OPTIONS "-mavx512f;-mavx512bw")
endif()

# Wide ISA paths as separate TUs; baseline code stays SSE2 and calls into these
# only after runtime detection (cpu_dispatch.h). The TUs are preprocessor-
# guarded, so joining every ABI's target is safe (empty on non-x86) and keeps
# IDEs happy.
target_sources(ksvgblur PRIVATE simd_x86_avx2.cpp simd_x86_avx512.cpp)

# The ARM32 kernels use NEON instructions; enable the FPU for the C++ side too.
if(BLUR_NEEDS_NEON)
    target_compile_options(ksvgblur PRIVATE -mfpu=neon)
endif()

find_library(log-lib log)
target_link_libraries(ksvgblur ${log-lib})
