cmake_minimum_required(VERSION 3.22.1)
project("ksvgfilters_host" LANGUAGES C CXX ASM)

if(NOT JAVA_HOME OR "${JAVA_HOME}" STREQUAL "")
  set(JAVA_HOME "$ENV{JAVA_HOME}")
endif()

# Opt-in 32-bit Intel host build (CI: -DKSVG_HOST_32BIT=ON with -m32 multilib).
# Uses the i386 .S kernels; otherwise the x86_64 kernels from before.
option(KSVG_HOST_32BIT "Build 32-bit Intel (i386) host lib for parity tests" OFF)
if(KSVG_HOST_32BIT)
  set(HOST32BIT TRUE)
else()
  set(HOST32BIT FALSE)
endif()

# Host ARM64 (Apple Silicon, CI ubuntu-24.04-arm runners): build the aarch64
# NEON kernels so the JVM parity tests execute natively there. Detected from
# the actual host CPU, no property needed; mirrors the NDK arm64-v8a source
# selection (same .S files plus the ARM-specific C++ dispatchers the NDK
# build also compiles: turbulence_arm.cpp, convolve_matrix_neon.cpp).
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
  set(HOSTAARCH64 TRUE)
else()
  set(HOSTAARCH64 FALSE)
endif()

if(HOSTAARCH64)
add_library(ksvgfilters SHARED
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/common/color_luts.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_capabilities.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/gaussian_blur.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/component_transfer.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_arm64_neon64.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix_neon.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_arm.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_noise_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_specular_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_diffuse_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_specular_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_diffuse_aarch64_neon.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_specular_aarch64_neon.S
)
elseif(HOST32BIT)
add_library(ksvgfilters SHARED
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/common/color_luts.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_capabilities.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/gaussian_blur.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/component_transfer.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_i386_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_noise_i386_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_noise_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_specular_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_specular_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_diffuse_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_diffuse_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_specular_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_specular_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_diffuse_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_diffuse_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_specular_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_specular_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_i386_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_i386_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_i386_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_i386_avx2.S
)
else()
add_library(ksvgfilters SHARED
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/common/color_luts.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_capabilities.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/gaussian_blur.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/component_transfer.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_x86_64_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_noise_x86_64_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_noise_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_specular_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_specular_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_diffuse_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_diffuse_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_specular_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_point_specular_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_diffuse_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_diffuse_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_specular_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_spot_specular_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_x86_64_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite_x86_64_avx2.S
)
endif()

if(APPLE)
  target_sources(ksvgfilters PRIVATE profiler_macos.cpp)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  target_sources(ksvgfilters PRIVATE profiler_linux.cpp)
endif()

target_include_directories(ksvgfilters PRIVATE
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/common
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite
  ${JAVA_HOME}/include
  ${JAVA_HOME}/include/darwin
  ${JAVA_HOME}/include/linux
)

target_compile_options(ksvgfilters PRIVATE -ffp-contract=off)
# -mssse3 is x86-only; aarch64 has NEON unconditionally, no flag needed.
if(NOT HOSTAARCH64)
  target_compile_options(ksvgfilters PRIVATE -mssse3)
endif()
if(HOST32BIT)
  target_compile_options(ksvgfilters PRIVATE -m32)
  target_link_options(ksvgfilters PRIVATE -m32)
endif()

# Host build only: lets unlinearize.cpp expose the experimental vA..vD SSSE3
# assembly variants (UnLinearizeNative.applySsse3Variant) for the structural /
# algorithmic-overhead correctness + benchmark harness. Never defined for the
# Android/NDK build, so the device kernels never reference the variants.
target_compile_definitions(ksvgfilters PRIVATE KSSVG_HOST_BUILD)
