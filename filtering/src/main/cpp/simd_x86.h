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

// Entry points implemented in simd_x86_avx2.cpp / simd_x86_avx512.cpp.
// Those translation units are compiled with -mavx2 / -mavx512f,-mavx512bw so
// the intrinsics headers expose the wide ISA; the baseline TUs stay SSE2 and
// call these only after detectSimdLevel() reports support. All kernels are
// bit-exact widenings of the SSE2/scalar reference loops.

#ifdef __cplusplus
extern "C" {
#endif

// morphology.cpp — one fully-interior output pixel (erode/dilate min/max).
void ksvgMorphologyApplyPixelAvx2(
        const jint* src, jint* dst, const jint width,
        const jint radiusX, const jint radiusY, const jboolean erode,
        const jint x, const jint y);
void ksvgMorphologyApplyPixelAvx512(
        const jint* src, jint* dst, const jint width,
        const jint radiusX, const jint radiusY, const jboolean erode,
        const jint x, const jint y);

// convolve_matrix.cpp — duplicate-edge interior pass.
void ksvgConvolveApplyInteriorAvx2(
        jint* dst, const jint* src, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY,
        const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha);
void ksvgConvolveApplyInteriorAvx512(
        jint* dst, const jint* src, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY,
        const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha);

// blur_x86.cpp / gaussian_blur.cpp — vertical separable blur pass over byte
// pixels, 8 columns per iteration (horizontal pass stays SSE: the float4-
// interleaved intermediate would need gathers/transposes that eat the gain).
void ksvgBlurVerticalAvx2(
        void* dst, const void* pin, const int stride, const void* gptr,
        const int rct, int x1, int x2);

// component_transfer.cpp — full clip-region LUT pass.
void ksvgComponentTransferApplyAvx2(
        const jint* src, jint* dst, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB);

#ifdef __cplusplus
}
#endif

#endif // KSVG_SIMD_X86_H
