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
#include <algorithm>
#include <cstdint>
#include <cassert>
#include "cpu_dispatch.h"
#include "simd_x86.h"

namespace {

inline jint clamp255(const float v) {
    const jint i = static_cast<jint>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

inline jint sampleCoordinate(const jint coordinate, const jint limit, const jint edgeMode) {
    if (coordinate >= 0 && coordinate < limit) return coordinate;
    if (edgeMode == 2) return -1;
    if (edgeMode == 1) {
        jint m = coordinate % limit;
        return (m < 0) ? m + limit : m;
    }
    return (coordinate < 0) ? 0 : limit - 1;
}

void convolveScalarPixel(
        const jint* src, jint* dst, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
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
    const jint outA = preserve ? (src[y * width + x] >> 24) & 0xFF
                               : clamp255(a / divisor + bias * 255.f);
    dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

void applyScalar(
        const jint* src, jint* dst, const jint width, const jint height,
        const jfloat* kernel,
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

#ifdef __aarch64__
#include <arm_neon.h>

void applyNeonInterior(
        jint* dst, const jint* src, jint width, jint height,
        const jfloat* kernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, bool preserve) {
    const float32x4_t vDivisor = vdupq_n_f32(divisor);
    const float32x4_t vBias255 = vmulq_f32(vdupq_n_f32(bias), vdupq_n_f32(255.0f));
    const float32x4_t vHalf = vdupq_n_f32(0.5f);
    const uint32x4_t maskFF = vdupq_n_u32(0xFF);
    const int32x4_t vZero = vdupq_n_s32(0);
    const int32x4_t v255 = vdupq_n_s32(255);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;
        jint x = 0;
        for (; x < xLo; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                targetX, targetY, divisor, bias, preserve, 0, x, y);
        }

        for (; x + 4 <= xHi; x += 4) {
            float32x4_t accR = vdupq_n_f32(0.f);
            float32x4_t accG = vdupq_n_f32(0.f);
            float32x4_t accB = vdupq_n_f32(0.f);
            float32x4_t accA = vdupq_n_f32(0.f);

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* srcRow = src + (y + ky - targetY) * width + (x - targetX);
                for (jint kx = 0; kx < orderX; kx++) {
                    const float32x4_t w = vdupq_n_f32(kernel[ky * orderX + kx]);
                    const uint32x4_t p = vld1q_u32(reinterpret_cast<const uint32_t*>(srcRow + kx));
                    accB = vaddq_f32(accB, vmulq_f32(vcvtq_f32_u32(vandq_u32(p, maskFF)), w));
                    accG = vaddq_f32(accG, vmulq_f32(vcvtq_f32_u32(vandq_u32(vshrq_n_u32(p, 8), maskFF)), w));
                    accR = vaddq_f32(accR, vmulq_f32(vcvtq_f32_u32(vandq_u32(vshrq_n_u32(p, 16), maskFF)), w));
                    accA = vaddq_f32(accA, vmulq_f32(vcvtq_f32_u32(vshrq_n_u32(p, 24)), w));
                }
            }

            auto roundRHU = [vDivisor, vBias255, vHalf](float32x4_t acc) {
                return vcvtq_s32_f32(vrndmq_f32(vaddq_f32(vaddq_f32(vdivq_f32(acc, vDivisor), vBias255), vHalf)));
            };

            int32x4_t iR = vmaxq_s32(vZero, vminq_s32(roundRHU(accR), v255));
            int32x4_t iG = vmaxq_s32(vZero, vminq_s32(roundRHU(accG), v255));
            int32x4_t iB = vmaxq_s32(vZero, vminq_s32(roundRHU(accB), v255));

            int32x4_t iA;
            if (preserve) {
                const uint32x4_t ps = vld1q_u32(reinterpret_cast<const uint32_t*>(src + rowOffset + x));
                iA = vreinterpretq_s32_u32(vshrq_n_u32(ps, 24));
            } else {
                iA = vmaxq_s32(vZero, vminq_s32(roundRHU(accA), v255));
            }

            const uint32x4_t out = vorrq_u32(
                    vorrq_u32(vshlq_n_u32(vreinterpretq_u32_s32(iA), 24), vshlq_n_u32(vreinterpretq_u32_s32(iR), 16)),
                    vorrq_u32(vshlq_n_u32(vreinterpretq_u32_s32(iG), 8), vreinterpretq_u32_s32(iB)));
            vst1q_u32(reinterpret_cast<uint32_t*>(dst + rowOffset + x), out);
        }
        for (; x < width; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
    }
}
#endif

#if !defined(__aarch64__) && defined(__SSE2__)
#include <emmintrin.h>

inline __m128i clamp255Sse(__m128i v) {
    const __m128i zero = _mm_setzero_si128();
    const __m128i isPos = _mm_cmpgt_epi32(v, zero);
    v = _mm_and_si128(v, isPos);
    const __m128i over = _mm_cmpgt_epi32(v, _mm_set1_epi32(255));
    return _mm_or_si128(_mm_andnot_si128(over, v), _mm_and_si128(over, _mm_set1_epi32(255)));
}

void applySseInterior(
        jint* dst, const jint* src, jint width, jint height,
        const jfloat* kernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, bool preserve) {
    const __m128 vDivisor = _mm_set1_ps(divisor);
    const __m128 vBias255 = _mm_set1_ps(bias * 255.0f);
    const __m128 vHalf = _mm_set1_ps(0.5f);
    const __m128i maskFF = _mm_set1_epi32(0xFF);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;
        jint x = 0;
        for (; x < xLo; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                targetX, targetY, divisor, bias, preserve, 0, x, y);
        }

        for (; x + 4 <= xHi; x += 4) {
            __m128 accR = _mm_setzero_ps();
            __m128 accG = _mm_setzero_ps();
            __m128 accB = _mm_setzero_ps();
            __m128 accA = _mm_setzero_ps();

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* srcRow = src + (y + ky - targetY) * width + (x - targetX);
                for (jint kx = 0; kx < orderX; kx++) {
                    const __m128 w = _mm_set1_ps(kernel[ky * orderX + kx]);
                    const __m128i p = _mm_loadu_si128(reinterpret_cast<const __m128i*>(srcRow + kx));
                    accB = _mm_add_ps(accB, _mm_mul_ps(_mm_cvtepi32_ps(_mm_and_si128(p, maskFF)), w));
                    accG = _mm_add_ps(accG, _mm_mul_ps(_mm_cvtepi32_ps(_mm_and_si128(_mm_srli_epi32(p, 8), maskFF)), w));
                    accR = _mm_add_ps(accR, _mm_mul_ps(_mm_cvtepi32_ps(_mm_and_si128(_mm_srli_epi32(p, 16), maskFF)), w));
                    accA = _mm_add_ps(accA, _mm_mul_ps(_mm_cvtepi32_ps(_mm_srli_epi32(p, 24)), w));
                }
            }

            auto roundRHU = [vDivisor, vBias255, vHalf](__m128 acc) {
                // Manual floor(x + 0.5) to match Round Half Up on SSE2
                __m128 val = _mm_add_ps(_mm_add_ps(_mm_div_ps(acc, vDivisor), vBias255), vHalf);
                __m128i i = _mm_cvttps_epi32(val);
                __m128 fi = _mm_cvtepi32_ps(i);
                __m128 mask = _mm_cmpgt_ps(fi, val);
                return _mm_cvttps_epi32(_mm_sub_ps(fi, _mm_and_ps(mask, _mm_set1_ps(1.0f))));
            };

            __m128i iR = clamp255Sse(roundRHU(accR));
            __m128i iG = clamp255Sse(roundRHU(accG));
            __m128i iB = clamp255Sse(roundRHU(accB));
            __m128i iA;

            if (preserve) {
                iA = _mm_srli_epi32(_mm_loadu_si128(reinterpret_cast<const __m128i*>(src + rowOffset + x)), 24);
            } else {
                iA = clamp255Sse(roundRHU(accA));
            }

            const __m128i out = _mm_or_si128(_mm_or_si128(_mm_slli_epi32(iA, 24), _mm_slli_epi32(iR, 16)),
                                            _mm_or_si128(_mm_slli_epi32(iG, 8), iB));
            _mm_storeu_si128(reinterpret_cast<__m128i*>(dst + rowOffset + x), out);
        }

        for (; x < width; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
    }
}
#endif

} // namespace


// Validation/test-only: run an explicitly selected backend (see SimdBackend).
namespace {

void runForced(const jint* src, jint* dst, jint width, jint height,
               const jfloat* kernel, jint orderX, jint orderY,
               jint targetX, jint targetY, jfloat divisor, jfloat bias,
               bool preserve, jint edgeMode, jint backend) {
    if (edgeMode == 0 && height >= orderY && width >= orderX) {
#if defined(__aarch64__)
        if (backend == SIMD_BACKEND_SCALAR) {
            applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, edgeMode);
        } else {
            assert(backend == SIMD_BACKEND_NEON64);
            const jint yLo = targetY;
            const jint yHi = height - orderY + 1 + targetY;
            for (jint y = 0; y < yLo; y++) {
                for (jint x = 0; x < width; x++) convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0, x, y);
            }
            for (jint y = yHi; y < height; y++) {
                for (jint x = 0; x < width; x++) convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0, x, y);
            }
            applyNeonInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve);
        }
#elif defined(__i386__) || defined(__x86_64__)
        const jint yLo = targetY;
        const jint yHi = height - orderY + 1 + targetY;
        auto runInterior = [&]() {
            for (jint y = 0; y < yLo; y++) {
                for (jint x = 0; x < width; x++) convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0, x, y);
            }
            for (jint y = yHi; y < height; y++) {
                for (jint x = 0; x < width; x++) convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, 0, x, y);
            }
        };

        switch (backend) {
            case SIMD_BACKEND_SCALAR:
                applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, edgeMode);
                break;
            case SIMD_BACKEND_SSSE3:
                runInterior();
                applySseInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            case SIMD_BACKEND_AVX2:
                runInterior();
                ksvgConvolveApplyInteriorAvx2(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            case SIMD_BACKEND_AVX512:
                runInterior();
                ksvgConvolveApplyInteriorAvx512(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            default:
                assert(false && "unsupported forced convolve backend on x86");
        }
#else
        (void)backend;
        applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, edgeMode);
#endif
        return;
    }
    (void)backend;
    applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, edgeMode);
}

jint nativeBackendForAbi() {
#if defined(__aarch64__)
    return SIMD_BACKEND_NEON64;
#elif defined(__i386__) || defined(__x86_64__)
    switch (detectSimdLevel()) {
        case SIMD_AVX512: return SIMD_BACKEND_AVX512;
        case SIMD_AVX2:   return SIMD_BACKEND_AVX2;
        default:          return SIMD_BACKEND_SSSE3;
    }
#else
    return SIMD_BACKEND_SCALAR;
#endif
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
        jint width, jint height,
        const jfloatArray jKernel, jint orderX, jint orderY,
        jint targetX, jint targetY,
        jfloat divisor, jfloat bias,
        const jboolean preserveAlpha, const jint edgeMode,
        jint simdBackend) {
    auto* kernel = env->GetFloatArrayElements(jKernel, nullptr);
    if (kernel == nullptr) return;

    auto* src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) {
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
    auto* dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }

    runForced(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha == JNI_TRUE, edgeMode, simdBackend);

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        jint width, jint height,
        const jfloatArray jKernel, jint orderX, jint orderY,
        jint targetX, jint targetY,
        jfloat divisor, jfloat bias,
        const jboolean preserveAlpha, const jint edgeMode) {
    auto* kernel = env->GetFloatArrayElements(jKernel, nullptr);
    if (kernel == nullptr) return;

    auto* src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) {
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
    auto* dst = env->GetIntArrayElements(jDst, nullptr);
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
            for (jint x = 0; x < width; x++) convolveScalarPixel(
                    src, dst, width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
        for (jint y = yHi; y < height; y++) {
            for (jint x = 0; x < width; x++) convolveScalarPixel(
                    src, dst, width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
#ifdef __aarch64__
        applyNeonInterior(dst, src, width, height, kernel, orderX, orderY,
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
                applySseInterior(dst, src, width, height, kernel, orderX, orderY,
                                 targetX, targetY, divisor, bias, preserve);
        }
#endif
        env->ReleaseIntArrayElements(jDst, dst, 0);
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
#endif

    applyScalar(src, dst, width, height, kernel,
                orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
}
