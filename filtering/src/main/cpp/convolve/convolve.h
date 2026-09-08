//    Copyright 2026 András Oravecz <info@oandras.hu>
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

//
// Created by András Oravecz on 2026. 09. 04..
//

#ifndef KSVG_CONVOLVE_H
#define KSVG_CONVOLVE_H

#include "jni.h"

namespace Convolve {

    void applyScalar(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha, const jint edgeMode);

    void convolveScalarPixel(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias255, const bool preserve, const jint edgeMode, const jint x, const jint y);

#ifdef __aarch64__
    // Parameter block consumed by ksvgConvolveGenericNeonAsm in
    // convolve_neon.S. The byte layout of this struct is read directly by the
    // assembly, so the field order/sizes below are a hard ABI contract and
    // must not change without updating convolve_neon.S in lockstep.
    //
    // Layout: width@0, height@4, kernel@8, orderX@16, orderY@20, targetX@24,
    // targetY@28, divisor@32, bias@36, preserve@40. Size 44, align 8.
    struct NeonConvolveParams {
        const jint width;                  // +0
        const jint height;                 // +4
        const jfloat *const kernel;        // +8
        const jint orderX;                 // +16
        const jint orderY;                 // +20
        const jint targetX;                // +24
        const jint targetY;                // +28
        const jfloat divisor;              // +32
        const jfloat bias;                 // +36
        const jboolean preserve;           // +40
    };

    void applyNeonInterior(
        jint *dst, const jint *src, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve, const jint edgeMode);
#elif defined(__ARM_NEON) || defined(__ARM_NEON__)
    // Parameter block consumed by ksvgConvolveGenericNeonAsm32 in
    // convolve_neon32.S. All pointers and jints are 4 bytes on ARM32.
    //
    // Layout: width@0, height@4, kernel@8, orderX@12, orderY@16,
    // targetX@20, targetY@24, divisor@28, bias@32, preserve@36.
    // Size 40, align 4.
    struct NeonConvolveParams32 {
        const jint width;                  // +0
        const jint height;                 // +4
        const jfloat *const kernel;        // +8  (4-byte pointer)
        const jint orderX;                 // +12
        const jint orderY;                 // +16
        const jint targetX;                // +20
        const jint targetY;                // +24
        const jfloat divisor;              // +28
        const jfloat bias;                 // +32
        const jboolean preserve;           // +36
    };

    void applyNeonInterior(
        jint *dst, const jint *src, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve, const jint edgeMode);
#endif

}

#endif //KSVG_CONVOLVE_H
