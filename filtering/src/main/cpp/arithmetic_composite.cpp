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
#include <cassert>
#include "cpu_dispatch.h"

namespace {

inline uint8_t clamp255(const float v) {
    const int i = static_cast<int>(std::floor(v + 0.5f));
    return static_cast<uint8_t>(std::max(0, std::min(255, i)));
}

inline uint8_t sRgbToLinear(const uint8_t c) {
    const float a = c / 255.f;
    if (a <= 0.04045f) {
        return clamp255((a / 12.92f) * 255.f);
    }

    return clamp255(std::pow((a + 0.055f) / 1.055f, 2.4f) * 255.f);
}

inline uint8_t linearToSRgb(const uint8_t c) {
    const float a = c / 255.f;

    if (a <= 0.0031308f) {
        return clamp255(a * 12.92f * 255.f);
    }

    return clamp255((1.055f * std::pow(a, 1.f / 2.4f) - 0.055f) * 255.f);
}

inline uint8_t arithmeticChannel(const uint8_t in1, const uint8_t in2, const float k1, const float k2, const float k3, const float k4) {
    const float a = in1 / 255.f;
    const float b = in2 / 255.f;
    return clamp255((k1 * a * b + k2 * a + k3 * b + k4) * 255.f);
}

void applyScalar(const jint* src1, const jint* src2, jint* dst,
                 const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
                 const float k1, const float k2, const float k3, const float k4, const bool useLinear) {
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

            if (useLinear) {
                outR = linearToSRgb(arithmeticChannel(sRgbToLinear(r1), sRgbToLinear(r2), k1, k2, k3, k4));
                outG = linearToSRgb(arithmeticChannel(sRgbToLinear(g1), sRgbToLinear(g2), k1, k2, k3, k4));
                outB = linearToSRgb(arithmeticChannel(sRgbToLinear(b1), sRgbToLinear(b2), k1, k2, k3, k4));
            } else {
                outR = arithmeticChannel(r1, r2, k1, k2, k3, k4);
                outG = arithmeticChannel(g1, g2, k1, k2, k3, k4);
                outB = arithmeticChannel(b1, b2, k1, k2, k3, k4);
            }

            dst[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }
}

jint nativeBackendForAbi() {
    return SIMD_BACKEND_SCALAR;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ArithmeticCompositeNative_nativeBackend(
        JNIEnv* env, jclass clazz) {
    return nativeBackendForAbi();
}

jint nativeBackendForAbi() {
    return SIMD_BACKEND_SCALAR;
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ArithmeticCompositeNative_applyForced(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc1, const jintArray jSrc2, const jintArray jDst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4, const jboolean useLinear, const jint simdBackend) {
    (void)simdBackend;
    assert(simdBackend == SIMD_BACKEND_SCALAR);

    jint* src1 = env->GetIntArrayElements(jSrc1, nullptr);
    jint* src2 = env->GetIntArrayElements(jSrc2, nullptr);
    jint* dst = env->GetIntArrayElements(jDst, nullptr);

    if (src1 && src2 && dst) {
        applyScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom, k1, k2, k3, k4, useLinear == JNI_TRUE);
    }

    if (dst) env->ReleaseIntArrayElements(jDst, dst, 0);
    if (src2) env->ReleaseIntArrayElements(jSrc2, src2, JNI_ABORT);
    if (src1) env->ReleaseIntArrayElements(jSrc1, src1, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ArithmeticCompositeNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc1, const jintArray jSrc2, const jintArray jDst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4, const jboolean useLinear) {
    jint* src1 = env->GetIntArrayElements(jSrc1, nullptr);
    jint* src2 = env->GetIntArrayElements(jSrc2, nullptr);
    jint* dst = env->GetIntArrayElements(jDst, nullptr);

    if (src1 && src2 && dst) {
        applyScalar(src1, src2, dst, width, clipLeft, clipTop, clipRight, clipBottom, k1, k2, k3, k4, useLinear == JNI_TRUE);
    }

    if (dst) env->ReleaseIntArrayElements(jDst, dst, 0);
    if (src2) env->ReleaseIntArrayElements(jSrc2, src2, JNI_ABORT);
    if (src1) env->ReleaseIntArrayElements(jSrc1, src1, JNI_ABORT);
}
