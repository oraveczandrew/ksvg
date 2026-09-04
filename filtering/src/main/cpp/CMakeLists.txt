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
    set(BLUR_SOURCES blur/Blur_advsimd.S)
    set(BLUR_NEEDS_NEON TRUE)
endif()

# AArch64 NEON kernels (64-bit ARM assembly). Same symbol/ABI contract as the
# 32-bit kernel above (single combined vertical+horizontal separable pass).
if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(BLUR_SOURCES blur/Blur_advsimd64.S)
endif()

if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(CONVOLVE_SOURCES convolve/convolve_neon.S)
endif()

if(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(CONVOLVE_SOURCES convolve/convolve_neon32.S)
endif()

set(AVX2_SOURCES
    blur/blur_x86_avx2.cpp
    convolve/convolve_matrix_x86_avx2.cpp
    morphology/morphology_x86_avx2.cpp
    component_transfer/component_transfer_x86_avx2.cpp
    component_transfer/unlinearize_x86_avx2.cpp
    displacement_map/displacement_map_x86_avx2.cpp
    turbulence/turbulence_x86_avx2.cpp
    arithmetic_composite/arithmetic_composite_x86_avx2.cpp
)

set(AVX512_SOURCES
    convolve/convolve_matrix_x86_avx512.cpp
    morphology/morphology_x86_avx512.cpp
    displacement_map/displacement_map_x86_avx512.cpp
)

add_library(ksvgblur SHARED
    blur/gaussian_blur.cpp blur/blur_x86.cpp
    convolve/convolve_matrix.cpp convolve/convolve_matrix_neon.cpp convolve/convolve_matrix_x86_sse.cpp
    morphology/morphology.cpp
    component_transfer/component_transfer.cpp component_transfer/unlinearize.cpp
    displacement_map/displacement_map.cpp
    lighting/lighting.cpp
    turbulence/turbulence.cpp turbulence/turbulence_x86.cpp turbulence/turbulence_arm.cpp
    arithmetic_composite/arithmetic_composite.cpp arithmetic_composite/arithmetic_composite_neon.cpp
        arithmetic_composite/arithmetic_composite_x86_sse.cpp
    ${AVX2_SOURCES} ${AVX512_SOURCES}
    ${BLUR_SOURCES} ${CONVOLVE_SOURCES})

# Include path so per-filter headers resolve (convolve.h, turbulence_tables.h, etc.)
target_include_directories(ksvgblur PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/blur
    ${CMAKE_CURRENT_SOURCE_DIR}/convolve
    ${CMAKE_CURRENT_SOURCE_DIR}/morphology
    ${CMAKE_CURRENT_SOURCE_DIR}/component_transfer
    ${CMAKE_CURRENT_SOURCE_DIR}/displacement_map
    ${CMAKE_CURRENT_SOURCE_DIR}/lighting
    ${CMAKE_CURRENT_SOURCE_DIR}/arithmetic_composite
    ${CMAKE_CURRENT_SOURCE_DIR}/turbulence)

# Bit-exact float parity with the Kotlin reference loops: forbid FMA contraction.
target_compile_options(ksvgblur PRIVATE -ffp-contract=off)

# SSSE3 is required for the x86 pshufb LUT path (component_transfer.cpp).
# Every known Android x86 device satisfies this.
if(ANDROID_ABI STREQUAL "x86" OR ANDROID_ABI STREQUAL "x86_64")
    target_compile_options(ksvgblur PRIVATE -mssse3)
    # Per-file flags make <immintrin.h> declare the AVX2/AVX-512 intrinsics
    # (invalid options on ARM ABIs, hence the guard).
    set_source_files_properties(${AVX2_SOURCES} PROPERTIES COMPILE_OPTIONS "-mavx2")
    set_source_files_properties(${AVX512_SOURCES} PROPERTIES COMPILE_OPTIONS "-mavx512f;-mavx512bw")
endif()

# The ARM32 kernels use NEON instructions; enable the FPU for the C++ side too.
if(BLUR_NEEDS_NEON)
    target_compile_options(ksvgblur PRIVATE -mfpu=neon)
endif()

find_library(log-lib log)
target_link_libraries(ksvgblur ${log-lib})
