cmake_minimum_required(VERSION 3.22.1)

project("ksvgblur" LANGUAGES C CXX ASM)

# ----------------------------------------------------------------------------
# Each file below is an OPTIMIZED kernel set for one ISA, compiled into
# libksvgblur.so for the matching ABI only. gaussian_blur.cpp dispatches the
# isotropic case (stdDeviationX == stdDeviationY, radius <= 25) through these
# kernels (with a zero-padded copy so edges read transparent black), and uses
# its own pure-C++ scalar two-pass fallback for anisotropic / large radii.
# ----------------------------------------------------------------------------

if (ANDROID_ABI STREQUAL "arm64-v8a")
    set(BLUR_SOURCES blur/blur_aarch64_neon.S)
    set(CONVOLVE_SOURCES convolve/convolve_aarch64_neon.S)
    set(ARITHMETIC_COMPOSITE_SOURCES arithmetic_composite/arithmetic_composite_aarch64_neon.S)
    set(MORPHOLOGY_SOURCES morphology/morphology_aarch64_neon.S)
    set(TURBULENCE_SOURCES turbulence/turbulence_noise_aarch64_neon.S)
    set(LIGHTING_SOURCES
            lighting/lighting_distant_diffuse_aarch64_neon.S
            lighting/lighting_distant_specular_aarch64_neon.S
            lighting/lighting_point_diffuse_aarch64_neon.S
            lighting/lighting_spot_diffuse_aarch64_neon.S
            lighting/lighting_point_specular_aarch64_neon.S
    )
    set(DISPLACEMENT_MAP_SOURCES displacement_map/displacement_map_arm64_neon64.S)
endif ()

if (ANDROID_ABI STREQUAL "armeabi-v7a")
    set(BLUR_SOURCES blur/blur_armv7a_neon.S)
    set(BLUR_NEEDS_NEON TRUE)
    set(MORPHOLOGY_SOURCES morphology/morphology_armv7a_neon.S)
    set(LIGHTING_SOURCES
            lighting/lighting_distant_diffuse_armv7a_neon.S
            lighting/lighting_distant_specular_armv7a_neon.S
            lighting/lighting_point_diffuse_armv7a_neon.S
            lighting/lighting_spot_diffuse_armv7a_neon.S
            lighting/lighting_point_specular_armv7a_neon.S
    )
    set(TURBULENCE_SOURCES turbulence/turbulence_noise_armv7a_neon.S)
    set(CONVOLVE_SOURCES convolve/convolve_armv7a_neon.S)
    set(DISPLACEMENT_MAP_SOURCES displacement_map/displacement_map_arm32_neon32.S)
    set(ARITHMETIC_COMPOSITE_SOURCES arithmetic_composite/arithmetic_composite_armv7a_neon.S)
endif ()

if (ANDROID_ABI STREQUAL "x86_64")
    set(BLUR_SOURCES
            blur/blur_x86_64_ssse3.S
            blur/blur_x86_64_avx2.S
    )
    set(MORPHOLOGY_SOURCES
            morphology/morphology_x86_64_sse2.S
            morphology/morphology_x86_64_avx2.S
    )
    set(LIGHTING_SOURCES
            lighting/lighting_distant_diffuse_x86_64_ssse3.S
            lighting/lighting_distant_diffuse_x86_64_avx2.S
            lighting/lighting_distant_specular_x86_64_ssse3.S
            lighting/lighting_distant_specular_x86_64_avx2.S
            lighting/lighting_point_diffuse_x86_64_ssse3.S
            lighting/lighting_point_diffuse_x86_64_avx2.S
            lighting/lighting_point_specular_x86_64_ssse3.S
            lighting/lighting_point_specular_x86_64_avx2.S
            lighting/lighting_spot_diffuse_x86_64_ssse3.S
            lighting/lighting_spot_diffuse_x86_64_avx2.S
            lighting/lighting_spot_specular_x86_64_ssse3.S
            lighting/lighting_spot_specular_x86_64_avx2.S
    )
    set(UNLINEARIZE_SOURCES
            component_transfer/unlinearize_x86_64_ssse3.S
            component_transfer/unlinearize_x86_64_avx2.S
    )
    set(ARITHMETIC_COMPOSITE_SOURCES
            arithmetic_composite/arithmetic_composite_x86_64_ssse3.S
            arithmetic_composite/arithmetic_composite_x86_64_avx2.S
    )
    set(CONVOLVE_SOURCES
            convolve/convolve_x86_64_sse2.S
            convolve/convolve_x86_64_avx2.S
    )
    set(TURBULENCE_SOURCES
            turbulence/turbulence_noise_x86_64_sse2.S
            turbulence/turbulence_noise_x86_64_avx2.S
    )
    set(DISPLACEMENT_MAP_SOURCES
            displacement_map/displacement_map_x86_64_ssse3.S
            displacement_map/displacement_map_x86_64_avx2.S
    )
endif ()

if (ANDROID_ABI STREQUAL "x86")
    set(BLUR_SOURCES
            blur/blur_i386_ssse3.S
            blur/blur_i386_avx2.S
    )
    set(MORPHOLOGY_SOURCES
            morphology/morphology_i386_sse2.S
            morphology/morphology_i386_avx2.S
    )
    # i386 lighting ships the SSSE3 baseline rows (4-lane) plus AVX2 rows
    # (8-lane) for both diffuse and specular; the i386 AVX-512 row was removed.
    set(LIGHTING_SOURCES
            lighting/lighting_distant_diffuse_i386_ssse3.S
            lighting/lighting_distant_diffuse_i386_avx2.S
            lighting/lighting_distant_specular_i386_ssse3.S
            lighting/lighting_distant_specular_i386_avx2.S
            lighting/lighting_point_diffuse_i386_ssse3.S
            lighting/lighting_point_diffuse_i386_avx2.S
            lighting/lighting_point_specular_i386_ssse3.S
            lighting/lighting_point_specular_i386_avx2.S
            lighting/lighting_spot_diffuse_i386_ssse3.S
            lighting/lighting_spot_diffuse_i386_avx2.S
            lighting/lighting_spot_specular_i386_ssse3.S
            lighting/lighting_spot_specular_i386_avx2.S
    )
    set(CONVOLVE_SOURCES
            convolve/convolve_i386_sse2.S
            convolve/convolve_i386_avx2.S
    )
    set(TURBULENCE_SOURCES
            turbulence/turbulence_noise_i386_sse2.S
            turbulence/turbulence_noise_i386_avx2.S
    )
    set(DISPLACEMENT_MAP_SOURCES
            displacement_map/displacement_map_i386_ssse3.S
            displacement_map/displacement_map_i386_avx2.S
    )
    set(UNLINEARIZE_SOURCES
            component_transfer/unlinearize_i386_ssse3.S
            component_transfer/unlinearize_i386_avx2.S
    )
    # i386 ships no SIMD arithmetic kernel: arithmetic_composite routes every
    # backend through the scalar reference there (the hand-written x86-64 .S
    # variants use 64-bit addressing and cannot be assembled for i386).
    set(ARITHMETIC_COMPOSITE_SOURCES
    )
endif ()

add_library(ksvgblur SHARED
        common/color_luts.S
        blur/gaussian_blur.cpp
        convolve/convolve_matrix.cpp convolve/convolve_matrix_neon.cpp
        morphology/morphology.cpp
        component_transfer/component_transfer.cpp component_transfer/unlinearize.cpp
        displacement_map/displacement_map.cpp
        lighting/lighting.cpp
        benchmark/cpu_affinity.cpp
        turbulence/turbulence.cpp turbulence/turbulence_arm.cpp
        arithmetic_composite/arithmetic_composite.cpp
        ${BLUR_SOURCES} ${CONVOLVE_SOURCES} ${ARITHMETIC_COMPOSITE_SOURCES} ${TURBULENCE_SOURCES} ${MORPHOLOGY_SOURCES} ${LIGHTING_SOURCES} ${UNLINEARIZE_SOURCES} ${DISPLACEMENT_MAP_SOURCES})

# Include path so per-filter headers resolve (convolve.h, turbulence_tables.h, etc.)
target_include_directories(ksvgblur PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/common
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
if (ANDROID_ABI STREQUAL "x86" OR ANDROID_ABI STREQUAL "x86_64")
    target_compile_options(ksvgblur PRIVATE -mssse3)
    # All i386 asm is PIC now ({rodata,LCPI} constants live in .text, addressed
    # via the call/1: popl/1b symdiff pattern), so the library no longer needs
    # -z,notext and links TEXTREL-free on x86-32.
    if (FALSE)
        target_link_options(ksvgblur PRIVATE "-Wl,-z,notext")
    endif ()
endif ()

# The ARM32 kernels use NEON instructions; enable the FPU for the C++ side too.
if (BLUR_NEEDS_NEON)
    target_compile_options(ksvgblur PRIVATE -mfpu=neon)
endif ()

find_library(log-lib log)
target_link_libraries(ksvgblur ${log-lib})
