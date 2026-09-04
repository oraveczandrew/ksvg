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
#include <cassert>

#include "convolve.h"
#include "cpu_dispatch.h"
#include "simd_x86.h"

namespace Convolve {
    static inline jint clamp255(const float v) {
        const jint i = static_cast<jint>(std::floor(v + 0.5f));
        return i < 0 ? 0 : i > 255 ? 255 : i;
    }

    static inline jint sampleCoordinate(const jint coordinate, const jint limit, const jint edgeMode) {
        if (coordinate >= 0 && coordinate < limit) return coordinate;
        if (edgeMode == 2) return -1;
        if (edgeMode == 1) {
            const jint m = coordinate % limit;
            return (m < 0) ? m + limit : m;
        }
        return (coordinate < 0) ? 0 : limit - 1;
    }

    void convolveScalarPixel(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve, const jint edgeMode, const jint x, const jint y) {
        float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
        for (jint ky = 0; ky < orderY; ky++) {
            const jint srcY = sampleCoordinate(y + ky - targetY, height, edgeMode);
            for (jint kx = 0; kx < orderX; kx++) {
                const jint srcX = sampleCoordinate(x + kx - targetX, width, edgeMode);
                const jint pixel = (srcX < 0 || srcY < 0) ? 0 : src[srcY * width + srcX];
                const float w = kernel[ky * orderX + kx];

                // Exactly matching Kotlin's bitwise extraction
                r += static_cast<float>((pixel >> 16) & 0xFF) * w;
                g += static_cast<float>((pixel >> 8) & 0xFF) * w;
                b += static_cast<float>(pixel & 0xFF) * w;
                a += static_cast<float>((pixel >> 24) & 0xFF) * w;
            }
        }
        const jint outR = clamp255(r / divisor + bias * 255.f);
        const jint outG = clamp255(g / divisor + bias * 255.f);
        const jint outB = clamp255(b / divisor + bias * 255.f);
        const jint outA = preserve
                              ? (src[y * width + x] >> 24) & 0xFF
                              : clamp255(a / divisor + bias * 255.f);
        dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    void applyScalar(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha, const jint edgeMode) {
        const bool preserve = preserveAlpha == JNI_TRUE;
        for (jint y = 0; y < height; y++) {
            for (jint x = 0; x < width; x++) {
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                    targetX, targetY, divisor, bias, preserve, edgeMode, x, y);
            }
        }
    }

    static void runForced(const jint *src, jint *dst, const jint width, const jint height,
                   const jfloat *kernel, const jint orderX, const jint orderY,
                   const jint targetX, const jint targetY, const jfloat divisor, const jfloat bias,
                   const bool preserve, const jint edgeMode, const jint backend) {
        if (edgeMode == 0 && height >= orderY && width >= orderX) {
#if defined(__aarch64__)
            if (backend == SIMD_BACKEND_SCALAR) {
                applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve,
                            edgeMode);
            } else {
                assert(backend == SIMD_BACKEND_NEON64);
                const jint yLo = targetY;
                const jint yHi = height - orderY + 1 + targetY;
                for (jint y = 0; y < yLo; y++) {
                    for (jint x = 0; x < width; x++) convolveScalarPixel(
                        src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0,
                        x, y);
                }
                for (jint y = yHi; y < height; y++) {
                    for (jint x = 0; x < width; x++) convolveScalarPixel(
                        src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0,
                        x, y);
                }
                applyNeonInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias,
                                  preserve);
            }
#elif defined(__i386__) || defined(__x86_64__)
            const jint yLo = targetY;
            const jint yHi = height - orderY + 1 + targetY;
            auto runInterior = [&]() {
                for (jint y = 0; y < yLo; y++) {
                    for (jint x = 0; x < width; x++) convolveScalarPixel(
                        src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0,
                        x, y);
                }
                for (jint y = yHi; y < height; y++) {
                    for (jint x = 0; x < width; x++) convolveScalarPixel(
                        src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0,
                        x, y);
                }
            };

            switch (backend) {
                case SIMD_BACKEND_SCALAR:
                    applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias,
                                preserve, edgeMode);
                    break;
                case SIMD_BACKEND_SSSE3:
                    runInterior();
                    applySseInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias,
                                     preserve);
                    break;
                case SIMD_BACKEND_AVX2:
                    runInterior();
                    ksvgConvolveApplyInteriorAvx2(dst, src, width, height, kernel, orderX, orderY, targetX, targetY,
                                                  divisor, bias, preserve);
                    break;
                case SIMD_BACKEND_AVX512:
                    runInterior();
                    ksvgConvolveApplyInteriorAvx512(dst, src, width, height, kernel, orderX, orderY, targetX, targetY,
                                                    divisor, bias, preserve);
                    break;
                default:
                    assert(false && "unsupported forced convolve backend on x86");
            }
#else
            (void) backend;
            applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve,
                        edgeMode);
#endif
            return;
        }
        (void) backend;
        applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve,
                    edgeMode);
    }

    static jint nativeBackendForAbi() {
        jint backends = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
        backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
        backends |= SIMD_BACKEND_NEON32;
#elif defined(__i386__) || defined(__x86_64__)
        backends |= SIMD_BACKEND_SSSE3;
        const SimdLevel level = detectSimdLevel();
        if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
        if (level >= SIMD_AVX512) backends |= SIMD_BACKEND_AVX512;
#endif
        return backends;
    }
} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_nativeBackend(
    JNIEnv *env, jclass clazz) {
    return Convolve::nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_applyForced(
    JNIEnv *env, jclass clazz,
    const jintArray jSrc, const jintArray jDst,
    const jint width, const jint height,
    const jfloatArray jKernel, const jint orderX, const jint orderY,
    const jint targetX, const jint targetY,
    const jfloat divisor, const jfloat bias,
    const jboolean preserveAlpha, const jint edgeMode,
    const jint simdBackend) {
    auto *kernel = env->GetFloatArrayElements(jKernel, nullptr);
    if (kernel == nullptr) return;

    auto *src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) {
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
    auto *dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }

    Convolve::runForced(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias,
                        preserveAlpha == JNI_TRUE, edgeMode, simdBackend);

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_apply(
    JNIEnv *env, jclass clazz,
    const jintArray jSrc, const jintArray jDst,
    const jint width, const jint height,
    const jfloatArray jKernel, const jint orderX, const jint orderY,
    const jint targetX, const jint targetY,
    const jfloat divisor, const jfloat bias,
    const jboolean preserveAlpha, const jint edgeMode) {
    auto *kernel = env->GetFloatArrayElements(jKernel, nullptr);
    if (kernel == nullptr) return;

    auto *src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) {
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
    auto *dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }

#if defined(__aarch64__) || (!defined(__aarch64__) && defined(__SSE2__))
    if (edgeMode == 0 && height >= orderY && width >= orderX) {
        const bool preserve = preserveAlpha == JNI_TRUE;
        const jint yLo = targetY;
        const jint yHi = height - orderY + 1 + targetY;

        for (jint y = 0; y < yLo; y++) {
            for (jint x = 0; x < width; x++)
                Convolve::convolveScalarPixel(
                    src, dst, width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
        for (jint y = yHi; y < height; y++) {
            for (jint x = 0; x < width; x++)
                Convolve::convolveScalarPixel(
                    src, dst, width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
#ifdef __aarch64__
        Convolve::applyNeonInterior(dst, src, width, height, kernel, orderX, orderY,
                                    targetX, targetY, divisor, bias, preserve);
#else
        switch (detectSimdLevel()) {
            case SIMD_AVX512:
                ksvgConvolveApplyInteriorAvx512(dst, src, width, height, kernel,
                                                orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            case SIMD_AVX2:
                ksvgConvolveApplyInteriorAvx2(dst, src, width, height, kernel,
                                              orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            default:
                Convolve::applySseInterior(dst, src, width, height, kernel, orderX, orderY,
                                 targetX, targetY, divisor, bias, preserve);
        }
#endif
        env->ReleaseIntArrayElements(jDst, dst, 0);
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
#endif

    Convolve::applyScalar(src, dst, width, height, kernel,
                          orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
}
