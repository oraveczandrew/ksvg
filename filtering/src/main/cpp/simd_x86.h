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

#ifndef KSVG_SIMD_X86_H
#define KSVG_SIMD_X86_H

#include <jni.h>
#include "cpu_dispatch.h"

// Entry points implemented in wide-ISA translation units.
// Those translation units are compiled with -mavx2 / -mavx512f,-mavx512bw so
// the intrinsics headers expose the wide ISA; the baseline TUs stay SSE2 and
// call these only after detectSimdLevel() reports support. All kernels are
// bit-exact widenings of the SSE2/scalar reference loops.

#ifdef __cplusplus
extern "C" {
#endif

// morphology.cpp — one fully-interior output range (erode/dilate min/max).
void ksvgMorphologyApplyRowSse2(
        const jint* src, jint* dst, jint width,
        jint radiusX, jint radiusY, jboolean erode,
        jint y, jint xStart, jint xEnd, jint* scratch);

void ksvgMorphologyApplyRowAvx2(
        const jint* src, jint* dst, jint width,
        jint radiusX, jint radiusY, jboolean erode,
        jint y, jint xStart, jint xEnd, jint* scratch);

void ksvgMorphologyApplyRowAvx512(
        const jint* src, jint* dst, jint width,
        jint radiusX, jint radiusY, jboolean erode,
        jint y, jint xStart, jint xEnd, jint* scratch);

// lighting.cpp — distant diffuse/specular pass over ARGB rows.
// count is number of output pixels. rows point at x-1 (start of 3x3 window).
// On x86_64 and i386 the baseline rows are the SSSE3 kernels (the old SSE2
// files were replaced by ssse3 variants that also carry the *Linear
// linear->sRGB rows); i386 additionally ships AVX2 diffuse+specular rows.
#if defined(__x86_64__)
void ksvgLightingDistantDiffuseRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantDiffuseRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantDiffuseRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantDiffuseRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

// Specular distant-light kernels. exponent is the specular exponent (float;
// on x86-64 it travels in xmm0, on i386 on the stack as the 7th cdecl arg).
void ksvgLightingDistantSpecularRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

void ksvgLightingDistantSpecularRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

void ksvgLightingDistantSpecularRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

void ksvgLightingDistantSpecularRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

// Point-light diffuse/specular row kernels (x86_64).
void ksvgLightingPointDiffuseRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params);
void ksvgLightingPointDiffuseRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, const uint8_t* linearToSrgb);
void ksvgLightingPointDiffuseRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params);
void ksvgLightingPointDiffuseRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, const uint8_t* linearToSrgb);

void ksvgLightingPointSpecularRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);
void ksvgLightingPointSpecularRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);
void ksvgLightingPointSpecularRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);
void ksvgLightingPointSpecularRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);

// Spot-light diffuse/specular row kernels (x86_64).
void ksvgLightingSpotDiffuseRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);
void ksvgLightingSpotDiffuseRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);
void ksvgLightingSpotDiffuseRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);
void ksvgLightingSpotDiffuseRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);

void ksvgLightingSpotSpecularRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
void ksvgLightingSpotSpecularRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
void ksvgLightingSpotSpecularRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
void ksvgLightingSpotSpecularRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);

#elif defined(__i386__)
void ksvgLightingDistantDiffuseRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantDiffuseRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantDiffuseRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantDiffuseRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params);

void ksvgLightingDistantSpecularRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

void ksvgLightingDistantSpecularRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

void ksvgLightingDistantSpecularRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

void ksvgLightingDistantSpecularRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const LightingParams* params, float exponent);

// Point-light diffuse/specular row kernels (i386).
void ksvgLightingPointDiffuseRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params);
void ksvgLightingPointDiffuseRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params);
void ksvgLightingPointDiffuseRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params);
void ksvgLightingPointDiffuseRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params);

void ksvgLightingPointSpecularRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);
void ksvgLightingPointSpecularRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);
void ksvgLightingPointSpecularRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);
void ksvgLightingPointSpecularRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const PointLightingParams* params, float exponent);

// Spot-light diffuse/specular row kernels (i386).
void ksvgLightingSpotDiffuseRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);
void ksvgLightingSpotDiffuseRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);
void ksvgLightingSpotDiffuseRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);
void ksvgLightingSpotDiffuseRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params);

void ksvgLightingSpotSpecularRowSsse3(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
void ksvgLightingSpotSpecularRowSsse3Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
void ksvgLightingSpotSpecularRowAvx2(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
void ksvgLightingSpotSpecularRowAvx2Linear(
        const jint* srcT, const jint* srcM, const jint* srcB,
        jint* dst, int count, const SpotLightingParams* params, float exponent);
#endif

// convolve_matrix.cpp — duplicate-edge interior pass.
void ksvgConvolveApplyInteriorAvx2(
        jint* dst, const jint* src, jint width, jint height,
        const float* kernel, jint orderX, jint orderY,
        jint targetX, jint targetY,
        jfloat divisor, jfloat bias, jboolean preserveAlpha);
void ksvgConvolveApplyInteriorSse2(
        jint* dst, const jint* src, jint width, jint height,
        const float* kernel, jint orderX, jint orderY,
        jint targetX, jint targetY,
        jfloat divisor, jfloat bias, jboolean preserveAlpha);
void ksvgConvolveApplyInteriorAvx512(
        jint* dst, const jint* src, jint width, jint height,
        const float* kernel, jint orderX, jint orderY,
        jint targetX, jint targetY,
        jfloat divisor, jfloat bias, jboolean preserveAlpha);

// arithmetic_composite.cpp — per-channel LUT-based arithmetic
// (x86-64 only: i386 routes every backend through the scalar reference).
#if defined(__x86_64__) || defined(_M_X64)
void ksvgArithmeticApplySse(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);

void ksvgArithmeticApplyAvx2(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

// unlinearize.cpp — flat element-wise LUT pass with alpha passthrough.
void ksvgUnlinearizeApplyAvx2(
        const jint* src, jint* dst, jint width, jint height, const jbyte* table);

// displacement_map.cpp — full frame displacement.
#if defined(__x86_64__)
void ksvgDisplacementMapApplySse2(
        const jint* src, const jint* map, jint* dst, jint width, jint height,
        jfloat scale, jint xChannel, jint yChannel);
void ksvgDisplacementMapApplyAvx2(
        const jint* src, const jint* map, jint* dst, jint width, jint height,
        jfloat scale, jint xChannel, jint yChannel);
void ksvgDisplacementMapApplyAvx512(
        const jint* src, const jint* map, jint* dst, jint width, jint height,
        jfloat scale, jint xChannel, jint yChannel);
#elif defined(__i386__)
void ksvgDisplacementMapApplySsse3_i386(
        const jint* src, const jint* map, jint* dst, jint width, jint height,
        jfloat scale, jint xChannel, jint yChannel);
void ksvgDisplacementMapApplyAvx2_i386(
        const jint* src, const jint* map, jint* dst, jint width, jint height,
        jfloat scale, jint xChannel, jint yChannel);
#endif

#ifdef __cplusplus
}
#endif

#endif // KSVG_SIMD_X86_H
