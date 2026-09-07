cmake_minimum_required(VERSION 3.22.1)
project("ksvgblur_host" LANGUAGES C CXX ASM)

set(JAVA_HOME "$ENV{JAVA_HOME}")

set(AVX2_SOURCES
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix_x86_avx2.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/component_transfer_x86_avx2.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_x86_avx2.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_x86_avx2.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite_x86_avx2.cpp
)

set(AVX512_SOURCES
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix_x86_avx512.cpp
)

add_library(ksvgblur SHARED
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/gaussian_blur.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_x86_64_ssse3.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur/blur_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/component_transfer.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_ssse3_x86_64.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_ssse3_x86_64_vA.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_ssse3_x86_64_vB.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_ssse3_x86_64_vC.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_ssse3_x86_64_vD.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer/unlinearize_ssse3_x86_64_vE.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite/arithmetic_composite_x86_sse.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve/convolve_matrix_x86_sse.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_x86_64_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology/morphology_x86_64_avx512.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence/turbulence_x86.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_x86_64_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting/lighting_distant_diffuse_x86_64_avx512.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_x86_64_sse2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_x86_64_avx2.S
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map/displacement_map_x86_64_avx512.S
  ${AVX2_SOURCES}
  ${AVX512_SOURCES}
)

target_include_directories(ksvgblur PRIVATE
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite
  ${JAVA_HOME}/include
  ${JAVA_HOME}/include/darwin
  ${JAVA_HOME}/include/linux
)

target_compile_options(ksvgblur PRIVATE -ffp-contract=off -mssse3)
set_source_files_properties(${AVX2_SOURCES} PROPERTIES COMPILE_OPTIONS "-mavx2")
set_source_files_properties(${AVX512_SOURCES} PROPERTIES COMPILE_OPTIONS "-mavx512f;-mavx512bw")

# Host build only: lets unlinearize.cpp expose the experimental vA..vD SSSE3
# assembly variants (UnLinearizeNative.applySsse3Variant) for the structural /
# algorithmic-overhead correctness + benchmark harness. Never defined for the
# Android/NDK build, so the device kernels never reference the variants.
target_compile_definitions(ksvgblur PRIVATE KSSVG_HOST_BUILD)
