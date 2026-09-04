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

#include <jni.h>
#include <cmath>
#include <cstring>
#include <algorithm>
#include <cassert>
#include "cpu_dispatch.h"
#include "convolve.h"
#include "shared/math_utils.h"
#include "simd_x86.h"

namespace Convolve {

inline jint sampleCoordinate(jint coordinate, jint limit, jint edgeMode) {
    if (coordinate >= 0 && coordinate < limit) return coordinate;
    switch (edgeMode) {
        case 2: // None (transparent black)
            return -1;
        case 1: { // Wrap
            jint m = coordinate % limit;
            return (m < 0) ? m + limit : m;
        }
        default: // Duplicate (clamp)
            return (coordinate < 0) ? 0 : limit - 1;
    }
}

void convolveScalarPixel(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve, const jint edgeMode, const jint x, const jint y) {
    float r = 0.f, g = 0.f, b = 0.f, a = 0.f;

    for (jint ky = 0; ky < orderY; ky++) {
        for (jint kx = 0; kx < orderX; kx++) {
            const jint sx = sampleCoordinate(x + kx - targetX, width, edgeMode);
            const jint sy = sampleCoordinate(y + ky - targetY, height, edgeMode);
            const jint pixel = (sx < 0 || sy < 0) ? 0 : src[sy * width + sx];
            const float weight = kernel[ky * orderX + kx];

            r += static_cast<float>((pixel >> 16) & 0xFF) * weight;
            g += static_cast<float>((pixel >> 8) & 0xFF) * weight;
            b += static_cast<float>(pixel & 0xFF) * weight;
            a += static_cast<float>((pixel >> 24) & 0xFF) * weight;
        }
    }

    const jint outR = ksvg::clamp255(r / divisor + bias * 255.f);
    const jint outG = ksvg::clamp255(g / divisor + bias * 255.f);
    const jint outB = ksvg::clamp255(b / divisor + bias * 255.f);
    const jint outA = preserve ? (src[y * width + x] >> 24) & 0xFF
                               : ksvg::clamp255(a / divisor + bias * 255.f);
    dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

void applyScalar(const jint* src, jint* dst, jint width, jint height,
                 const float* kernel, jint orderX, jint orderY, jint targetX, jint targetY,
                 float divisor, float bias, bool preserveAlpha, jint edgeMode) {
    for (jint y = 0; y < height; y++) {
        for (jint x = 0; x < width; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, x, y);
        }
    }
}

#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
void applyX86(const jint* src, jint* dst, jint width, jint height,
              const float* kernel, jint orderX, jint orderY, jint targetX, jint targetY,
              float divisor, float bias, bool preserveAlpha, jint edgeMode, jint forcedBackend) {
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;
    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;

    for (jint y = 0; y < yLo; y++)
        for (jint x = 0; x < width; x++)
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, x, y);
    for (jint y = yHi; y < height; y++)
        for (jint x = 0; x < width; x++)
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, x, y);
    for (jint y = yLo; y < yHi; y++) {
        for (jint x = 0; x < xLo; x++)
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, x, y);
        for (jint x = xHi; x < width; x++)
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, x, y);
    }

    if (xLo < xHi && yLo < yHi) {
        jint backend = forcedBackend;
        if (backend == -1) {
            const SimdLevel level = detectSimdLevel();
            if (level >= SIMD_AVX512) backend = SIMD_BACKEND_AVX512;
            else if (level >= SIMD_AVX2) backend = SIMD_BACKEND_AVX2;
            else backend = SIMD_BACKEND_SSSE3;
        }

        if (backend == SIMD_BACKEND_AVX512) {
            ksvgConvolveApplyInteriorAvx512(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha);
        } else if (backend == SIMD_BACKEND_AVX2) {
            ksvgConvolveApplyInteriorAvx2(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha);
        } else {
            applySseInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha);
        }
    }
}
#endif

} // namespace Convolve

namespace {

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backends |= SIMD_BACKEND_NEON32;
#elif defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
    backends |= SIMD_BACKEND_SSSE3;
    if (detectSimdLevel() >= SIMD_AVX2) {
        backends |= SIMD_BACKEND_AVX2;
    }
    if (detectSimdLevel() >= SIMD_AVX512) {
        backends |= SIMD_BACKEND_AVX512;
    }
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_nativeBackend(
        JNIEnv* env, jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_applyForced(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jfloatArray jKernel, const jint orderX, const jint orderY,
        const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias,
        const jboolean preserveAlpha, const jint edgeMode,
        const jint simdBackend) {
    jint* src = env->GetIntArrayElements(jSrc, nullptr);
    jint* dst = env->GetIntArrayElements(jDst, nullptr);
    jfloat* kernel = env->GetFloatArrayElements(jKernel, nullptr);

    if (src && dst && kernel) {
        if (simdBackend == SIMD_BACKEND_SCALAR) {
            Convolve::applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode);
        } else {
#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
            Convolve::applyNeonInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode);
#elif defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
            Convolve::applyX86(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode, simdBackend);
#endif
        }
    }

    if (kernel) env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
    if (dst) env->ReleaseIntArrayElements(jDst, dst, 0);
    if (src) env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jfloatArray jKernel, const jint orderX, const jint orderY,
        const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias,
        const jboolean preserveAlpha, const jint edgeMode) {
    jint* src = env->GetIntArrayElements(jSrc, nullptr);
    jint* dst = env->GetIntArrayElements(jDst, nullptr);
    jfloat* kernel = env->GetFloatArrayElements(jKernel, nullptr);

    if (src && dst && kernel) {
#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
        Convolve::applyNeonInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode);
#elif defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
        Convolve::applyX86(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode, -1);
#else
        Convolve::applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode);
#endif
    }

    if (kernel) env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
    if (dst) env->ReleaseIntArrayElements(jDst, dst, 0);
    if (src) env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}
