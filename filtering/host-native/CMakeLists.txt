cmake_minimum_required(VERSION 3.22.1)
project("ksvgblur_host" LANGUAGES C CXX)

set(JAVA_HOME "$ENV{JAVA_HOME}")

add_library(ksvgblur SHARED
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/gaussian_blur.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/component_transfer.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/unlinearize.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/arithmetic_composite.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/displacement_map.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve_matrix.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/convolve_matrix_x86_sse.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/morphology.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/turbulence_x86.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/lighting.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/blur_x86.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_x86_avx2.cpp
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_x86_avx512.cpp
)

target_include_directories(ksvgblur PRIVATE
  ${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp
  ${JAVA_HOME}/include
  ${JAVA_HOME}/include/darwin
)

target_compile_options(ksvgblur PRIVATE -ffp-contract=off -mssse3)
set_source_files_properties(${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_x86_avx2.cpp PROPERTIES COMPILE_OPTIONS "-mavx2")
set_source_files_properties(${CMAKE_SOURCE_DIR}/../../filtering/src/main/cpp/simd_x86_avx512.cpp PROPERTIES COMPILE_OPTIONS "-mavx512f;-mavx512bw")
