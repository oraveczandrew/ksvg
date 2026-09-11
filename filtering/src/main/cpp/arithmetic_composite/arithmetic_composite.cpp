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
#include <cassert>
#include "cpu_dispatch.h"
#include "arithmetic_composite.h"
#include "color_luts.h"
#include "shared/math_utils.h"

namespace {

inline uint8_t arithmeticChannel(const uint8_t in1, const uint8_t in2, const float k1, const float k2, const float k3, const float k4) {
    const float a = in1 / 255.f;
    const float b = in2 / 255.f;
    return static_cast<uint8_t>(ksvg::clamp255((k1 * a * b + k2 * a + k3 * b + k4) * 255.f));
}

template <bool kUseLinear>
void applyArithmeticScalarImpl(
        const jint* src1, const jint* src2, jint* dst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4) {
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jint i = rowOffset + x;
            const jint p = src1[i];
            const jint q = src2[i];

            const uint8_t a1 = (p >> 24) & 0xFF;
            const uint8_t r1 = (p >> 16) & 0xFF;
            const uint8_t g1 = (p >> 8) & 0xFF;
            const uint8_t b1 = p & 0xFF;

            const uint8_t a2 = (q >> 24) & 0xFF;
            const uint8_t r2 = (q >> 16) & 0xFF;
            const uint8_t g2 = (q >> 8) & 0xFF;
            const uint8_t b2 = q & 0xFF;

            const uint8_t outA = arithmeticChannel(a1, a2, k1, k2, k3, k4);
            uint8_t outR, outG, outB;

            if constexpr (kUseLinear) {
                outR = ksvg_linear_to_srgb_lut[arithmeticChannel(ksvg_srgb_to_linear_lut[r1], ksvg_srgb_to_linear_lut[r2], k1, k2, k3, k4)];
                outG = ksvg_linear_to_srgb_lut[arithmeticChannel(ksvg_srgb_to_linear_lut[g1], ksvg_srgb_to_linear_lut[g2], k1, k2, k3, k4)];
                outB = ksvg_linear_to_srgb_lut[arithmeticChannel(ksvg_srgb_to_linear_lut[b1], ksvg_srgb_to_linear_lut[b2], k1, k2, k3, k4)];
            } else {
                outR = arithmeticChannel(r1, r2, k1, k2, k3, k4);
                outG = arithmeticChannel(g1, g2, k1, k2, k3, k4);
                outB = arithmeticChannel(b1, b2, k1, k2, k3, k4);
            }

            dst[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }
}

} // namespace

extern "C" {
void applyArithmeticScalar(
        const jint* src1, const jint* src2, jint* dst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4,
        const jboolean useLinear,
        [[maybe_unused]] const jbyte* srgbToLinear, [[maybe_unused]] const jbyte* linearToSrgb) {
    if (useLinear == JNI_TRUE) {
        applyArithmeticScalarImpl<true>(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom, k1, k2, k3, k4);
    } else {
        applyArithmeticScalarImpl<false>(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom, k1, k2, k3, k4);
    }
}
}

namespace {

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backends |= SIMD_BACKEND_NEON32;
#elif defined(__x86_64__) || defined(_M_X64)
    // i386 has no SIMD kernels anymore: arithmetic_composite routes every
    // backend (including forced) through the scalar reference there, so it
    // advertises only the scalar backend.
    backends |= SIMD_BACKEND_SSSE3;
    if (detectSimdLevel() >= SIMD_AVX2) {
        backends |= SIMD_BACKEND_AVX2;
    }
#endif
    return backends;
}

void runForced(const jint* src1, const jint* src2, jint* dst,
               const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
               const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4, const jboolean useLinear,
               const jint backend) {
    const auto* srgbToLinear = reinterpret_cast<const jbyte*>(ksvg_srgb_to_linear_lut);
    const auto* linearToSrgb = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
    if (backend == SIMD_BACKEND_SCALAR) {
        applyArithmeticScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                              k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
    } else {
        applyArithmeticNeon(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                            k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
    }
#elif defined(__x86_64__) || defined(_M_X64)
    switch (backend) {
        case SIMD_BACKEND_SCALAR:
            applyArithmeticScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                                  k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
            break;
        case SIMD_BACKEND_SSSE3:
            ksvgArithmeticApplySse(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                                 k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
            break;
        case SIMD_BACKEND_AVX2:
            ksvgArithmeticApplyAvx2(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                                   k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
            break;
        default:
            assert(false && "unsupported forced arithmetic_composite backend on x86");
    }
#else
    (void)backend;
    applyArithmeticScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                          k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
#endif
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ArithmeticCompositeNative_nativeBackend(
    [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ArithmeticCompositeNative_applyForcedNative(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc1, const jintArray jSrc2, const jintArray jDst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4, const jboolean useLinear,
        const jint simdBackend) {
    jint* src1 = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc1, nullptr));
    jint* src2 = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc2, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));

    if (src1 && src2 && dst) {
        runForced(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                  k1, k2, k3, k4, useLinear, simdBackend);
    }

    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    if (src2) env->ReleasePrimitiveArrayCritical(jSrc2, src2, JNI_ABORT);
    if (src1) env->ReleasePrimitiveArrayCritical(jSrc1, src1, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ArithmeticCompositeNative_applyNative(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc1, const jintArray jSrc2, const jintArray jDst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4, const jboolean useLinear) {
    const auto* srgbToLinear = reinterpret_cast<const jbyte*>(ksvg_srgb_to_linear_lut);
    const auto* linearToSrgb = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
    jint* src1 = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc1, nullptr));
    jint* src2 = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc2, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));

    if (src1 && src2 && dst) {
#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
        applyArithmeticNeon(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                            k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
#elif defined(__x86_64__) || defined(_M_X64)
        if (useLinear == JNI_TRUE) {
            applyArithmeticScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                                  k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        } else if (detectSimdLevel() >= SIMD_AVX2) {
            ksvgArithmeticApplyAvx2(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                                   k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        } else {
            ksvgArithmeticApplySse(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                                 k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
#else
        applyArithmeticScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                              k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
#endif
    }

    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    if (src2) env->ReleasePrimitiveArrayCritical(jSrc2, src2, JNI_ABORT);
    if (src1) env->ReleasePrimitiveArrayCritical(jSrc1, src1, JNI_ABORT);
}
