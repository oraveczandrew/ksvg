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
#include "turbulence_core.h"
#include "turbulence_x86.h"

namespace {

void applyScalar(
        jint* pixels,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jdouble baseFrequencyX, const jdouble baseFrequencyY,
        const jint periodX, const jint periodY,
        const jint octaves, const jboolean fractalNoise,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jint seed) {
    (void)originX;
    (void)originY;

    LatticeTables tables;
    initLattice(tables, seed);

    std::memset(pixels, 0, static_cast<size_t>(width) * height * sizeof(jint));

    const bool stitchEnabled = periodX > 0 || periodY > 0;
    const bool fractal = fractalNoise == JNI_TRUE;

    const double fX = baseFrequencyX;
    const double fY = baseFrequencyY;

    for (jint y = clipTop; y < clipBottom; y++) {
        const jdouble userY = userTop + y * invCanvasScaleY;
        const jdouble py0 = userY / unitSizeY * baseFrequencyY;
        const double tileY = static_cast<double>(y - clipTop);
        const jint rowOffset = y * width;

        for (jint x = clipLeft; x < clipRight; x++) {
            const jdouble userX = userLeft + x * invCanvasScaleX;
            const jdouble px0 = userX / unitSizeX * baseFrequencyX;
            const double tileX = static_cast<double>(x - clipLeft);

            double sums[4] = {0.0, 0.0, 0.0, 0.0};

            for (int ch = 0; ch < 4; ch++) {
                double fx = px0;
                double fy = py0;
                double curtlx = tileX * fX;
                double curtly = tileY * fY;
                double ratio = 1.0;
                StitchInfo si;
                si.width = periodX;
                si.height = periodY;

                for (jint octave = 0; octave < octaves; octave++) {
                    if (stitchEnabled) {
                        si.wrapX = static_cast<int32_t>(std::floor(curtlx)) + 4096 + si.width;
                        si.wrapY = static_cast<int32_t>(std::floor(curtly)) + 4096 + si.height;
                    }

                    double n;
                    noise2(tables, ch, fx, fy, si, stitchEnabled, n);

                    if (fractal) {
                        sums[ch] += n / ratio;
                    } else {
                        sums[ch] += std::abs(n) / ratio;
                    }

                    fx *= 2.0;
                    fy *= 2.0;
                    curtlx *= 2.0;
                    curtly *= 2.0;
                    ratio *= 2.0;
                    if (stitchEnabled) {
                        si.width *= 2;
                        si.height *= 2;
                    }
                }
            }

            jint comps[4];
            for (int ch = 0; ch < 4; ch++) {
                const double finalVal = fractal ? (sums[ch] + 1.0) * 127.5 : sums[ch] * 255.0;
                jint iv = static_cast<jint>(std::floor(finalVal + 0.5));
                if (iv < 0) iv = 0; else if (iv > 255) iv = 255;
                comps[ch] = iv;
            }
            pixels[rowOffset + x] =
                    (comps[3] << 24) | (comps[0] << 16) | (comps[1] << 8) | comps[2];
        }
    }
}

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__i386__) || defined(__x86_64__)
    backends |= SIMD_BACKEND_SSSE3;
    if (detectSimdLevel() >= SIMD_AVX2) {
        backends |= SIMD_BACKEND_AVX2;
    }
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_TurbulenceNative_nativeBackend(
        JNIEnv* env, jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_TurbulenceNative_applyForced(
        JNIEnv* env, jclass clazz,
        const jintArray jPixels,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jdouble baseFrequencyX, const jdouble baseFrequencyY,
        const jint periodX, const jint periodY,
        const jint octaves, const jboolean fractalNoise,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jint seed, const jint simdBackend) {
    auto* pixels = env->GetIntArrayElements(jPixels, nullptr);
    if (pixels == nullptr) return;

    if (simdBackend == SIMD_BACKEND_SCALAR) {
        applyScalar(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                    invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                    unitSizeX, unitSizeY, seed);
    } else {
#if defined(__i386__) || defined(__x86_64__)
        if (simdBackend == SIMD_BACKEND_AVX2) {
            applyAvx2(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                      baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                      invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                      unitSizeX, unitSizeY, seed);
        } else {
            assert(simdBackend == SIMD_BACKEND_SSSE3);
            applySsse3(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                       baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                       invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                       unitSizeX, unitSizeY, seed);
        }
#else
        (void)simdBackend;
        applyScalar(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                    invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                    unitSizeX, unitSizeY, seed);
#endif
    }

    env->ReleaseIntArrayElements(jPixels, pixels, 0);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_TurbulenceNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jPixels,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jdouble baseFrequencyX, const jdouble baseFrequencyY,
        const jint periodX, const jint periodY,
        const jint octaves, const jboolean fractalNoise,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jint seed) {
    auto* pixels = env->GetIntArrayElements(jPixels, nullptr);
    if (pixels == nullptr) return;

#if defined(__i386__) || defined(__x86_64__)
    SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) {
        applyAvx2(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                  baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                  invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                  unitSizeX, unitSizeY, seed);
    } else if (level >= SIMD_SSSE3) {
        applySsse3(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                   baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                   invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                   unitSizeX, unitSizeY, seed);
    } else {
        applyScalar(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                    invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                    unitSizeX, unitSizeY, seed);
    }
#else
    applyScalar(pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                unitSizeX, unitSizeY, seed);
#endif

    env->ReleaseIntArrayElements(jPixels, pixels, 0);
}
