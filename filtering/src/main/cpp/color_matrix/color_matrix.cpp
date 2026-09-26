//    Copyright 2026 András Oravecz <info@oandras.hu>
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        https://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

#include <jni.h>
#include <cassert>
#include "cpu_dispatch.h"
#include "color_matrix.h"
#include "color_luts.h"
#include "shared/math_utils.h"

namespace {

template <bool kUseLinear>
void applyColorMatrixScalarImpl(
        const jint* src, jint* dst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat* m) {
    const float m00 = m[0]; const float m01 = m[1]; const float m02 = m[2]; const float m03 = m[3]; const float m04 = m[4];
    const float m10 = m[5]; const float m11 = m[6]; const float m12 = m[7]; const float m13 = m[8]; const float m14 = m[9];
    const float m20 = m[10]; const float m21 = m[11]; const float m22 = m[12]; const float m23 = m[13]; const float m24 = m[14];
    const float m30 = m[15]; const float m31 = m[16]; const float m32 = m[17]; const float m33 = m[18]; const float m34 = m[19];
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jint i = rowOffset + x;
            const jint p = src[i];
            const float a = ((p >> 24) & 0xFF) / 255.f;
            float r, g, b;
            if constexpr (kUseLinear) {
                r = ksvg_srgb_to_linear_lut[(p >> 16) & 0xFF] / 255.f;
                g = ksvg_srgb_to_linear_lut[(p >> 8) & 0xFF] / 255.f;
                b = ksvg_srgb_to_linear_lut[p & 0xFF] / 255.f;
            } else {
                r = ((p >> 16) & 0xFF) / 255.f;
                g = ((p >> 8) & 0xFF) / 255.f;
                b = (p & 0xFF) / 255.f;
            }
            const float or_ = m00 * r + m01 * g + m02 * b + m03 * a + m04;
            const float og = m10 * r + m11 * g + m12 * b + m13 * a + m14;
            const float ob = m20 * r + m21 * g + m22 * b + m23 * a + m24;
            const float oa = m30 * r + m31 * g + m32 * b + m33 * a + m34;
            int outR, outG, outB;
            if constexpr (kUseLinear) {
                outR = ksvg_linear_to_srgb_lut[ksvg::clamp255(or_ * 255.f)];
                outG = ksvg_linear_to_srgb_lut[ksvg::clamp255(og * 255.f)];
                outB = ksvg_linear_to_srgb_lut[ksvg::clamp255(ob * 255.f)];
            } else {
                outR = ksvg::clamp255(or_ * 255.f);
                outG = ksvg::clamp255(og * 255.f);
                outB = ksvg::clamp255(ob * 255.f);
            }
            const int outA = ksvg::clamp255(oa * 255.f);
            dst[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }
}

} // namespace

extern "C" {
void applyColorMatrixScalar(
        const jint* src, jint* dst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat* matrix,
        const jboolean useLinear,
        [[maybe_unused]] const jbyte* srgbToLinear, [[maybe_unused]] const jbyte* linearToSrgb) {
    if (useLinear == JNI_TRUE) {
        applyColorMatrixScalarImpl<true>(src, dst, width, clipLeft, clipTop, clipRight, clipBottom, matrix);
    } else {
        applyColorMatrixScalarImpl<false>(src, dst, width, clipLeft, clipTop, clipRight, clipBottom, matrix);
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
#endif
    return backends;
}

void runForced(const jint* src, jint* dst,
               const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
               const jfloat* matrix, const jboolean useLinear,
               const jint backend) {
    const auto* srgbToLinear = reinterpret_cast<const jbyte*>(ksvg_srgb_to_linear_lut);
    const auto* linearToSrgb = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
    if (backend == SIMD_BACKEND_SCALAR) {
        applyColorMatrixScalar(src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                               matrix, useLinear, srgbToLinear, linearToSrgb);
    } else {
        applyColorMatrixNeon(src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                             matrix, useLinear, srgbToLinear, linearToSrgb);
    }
#else
    (void)backend;
    applyColorMatrixScalar(src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                           matrix, useLinear, srgbToLinear, linearToSrgb);
#endif
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ColorMatrixNative_nativeBackend(
    [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ColorMatrixNative_applyForcedNative(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloatArray jMatrix, const jboolean useLinear,
        const jint simdBackend) {
    jint* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    jfloat* matrix = static_cast<jfloat*>(env->GetPrimitiveArrayCritical(jMatrix, nullptr));

    if (src && dst && matrix) {
        runForced(src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                  matrix, useLinear, simdBackend);
    }

    if (matrix) env->ReleasePrimitiveArrayCritical(jMatrix, matrix, JNI_ABORT);
    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    if (src) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ColorMatrixNative_applyNative(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloatArray jMatrix, const jboolean useLinear) {
    const auto* srgbToLinear = reinterpret_cast<const jbyte*>(ksvg_srgb_to_linear_lut);
    const auto* linearToSrgb = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
    jint* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    jfloat* matrix = static_cast<jfloat*>(env->GetPrimitiveArrayCritical(jMatrix, nullptr));

    if (src && dst && matrix) {
#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
        applyColorMatrixNeon(src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                             matrix, useLinear, srgbToLinear, linearToSrgb);
#else
        applyColorMatrixScalar(src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                               matrix, useLinear, srgbToLinear, linearToSrgb);
#endif
    }

    if (matrix) env->ReleasePrimitiveArrayCritical(jMatrix, matrix, JNI_ABORT);
    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    if (src) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
