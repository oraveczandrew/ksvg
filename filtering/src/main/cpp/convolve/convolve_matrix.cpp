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
#include "cpu_dispatch.h"
#include "convolve.h"
#include "shared/math_utils.h"
#include "simd_x86.h"

namespace Convolve {

static inline jint sampleCoordinate(const jint coordinate, const jint limit, const jint edgeMode) {
    if (coordinate >= 0 && coordinate < limit) return coordinate;
    switch (edgeMode) {
        case 2: // None (transparent black)
            return -1;
        case 1: { // Wrap
            const jint m = coordinate % limit;
            return m < 0 ? m + limit : m;
        }
        default: // Duplicate (clamp)
            return coordinate < 0 ? 0 : limit - 1;
    }
}

void convolveScalarPixel(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias255, const bool preserve, const jint edgeMode, const jint x, const jint y) {
    float r = 0.f, g = 0.f, b = 0.f, a = 0.f;

    for (jint ky = 0; ky < orderY; ky++) {
        for (jint kx = 0; kx < orderX; kx++) {
            const jint sx = sampleCoordinate(x + kx - targetX, width, edgeMode);
            const jint sy = sampleCoordinate(y + ky - targetY, height, edgeMode);

            if (sx != -1 && sy != -1) {
                const jint pixel = src[sy * width + sx];
                const float weight = kernel[ky * orderX + kx];
                r += ((pixel >> 16) & 0xFF) * weight;
                g += ((pixel >> 8) & 0xFF) * weight;
                b += (pixel & 0xFF) * weight;
                a += ((pixel >> 24) & 0xFF) * weight;
            }
        }
    }

    jint ia;
    if (preserve) {
        ia = (src[y * width + x] >> 24) & 0xFF;
    } else {
        ia = ksvg::clamp255(std::floor(a / divisor + bias255 + 0.5f));
    }
    const jint ir = ksvg::clamp255(std::floor(r / divisor + bias255 + 0.5f));
    const jint ig = ksvg::clamp255(std::floor(g / divisor + bias255 + 0.5f));
    const jint ib = ksvg::clamp255(std::floor(b / divisor + bias255 + 0.5f));

    dst[y * width + x] = (ia << 24) | (ir << 16) | (ig << 8) | ib;
}

void applyScalar(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
    const jfloat divisor, const jfloat bias, const jboolean preserveAlpha, const jint edgeMode) {
    const jfloat bias255 = bias * 255.f;
    for (jint y = 0; y < height; y++) {
        for (jint x = 0; x < width; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias255, preserveAlpha, edgeMode, x, y);
        }
    }
}

#if defined(__i386__) || defined(__x86_64__)
void applyX86(
        const jint *src, jint *dst, const jint width, const jint height,
        const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha, const jint edgeMode,
        const jint forcedBackend) {
    const jfloat bias255 = bias * 255.f;
    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = 0; y < height; y++) {
        if (y >= yLo && y < yHi) {
            for (jint x = 0; x < xLo; x++)
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias255, preserveAlpha, edgeMode, x, y);
            for (jint x = xHi; x < width; x++)
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias255, preserveAlpha, edgeMode, x, y);
        } else {
            for (jint x = 0; x < width; x++)
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias255, preserveAlpha, edgeMode, x, y);
        }
    }

    if (xLo < xHi && yLo < yHi) {
        jint backend = forcedBackend;
        if (backend == -1) {
            const SimdLevel level = detectSimdLevel();
            if (level >= SIMD_AVX2) backend = SIMD_BACKEND_AVX2;
            else backend = SIMD_BACKEND_SSE2;
        }

        if (backend == SIMD_BACKEND_AVX2) {
            ksvgConvolveApplyInteriorAvx2(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha);
        } else {
            ksvgConvolveApplyInteriorSse2(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha);
        }

        // The asm kernels only cover interior columns [xLo, asmEnd), where
        // asmEnd is the start of the last full vector-width block. Fill the
        // scalar remainder [asmEnd, xHi) explicitly so no interior pixel is
        // left unwritten.
        const jint vecWidth = (backend == SIMD_BACKEND_AVX2 ? 8 : 4);
        const jint asmEnd = targetX + ((xHi - targetX) & ~(vecWidth - 1));
        for (jint y = yLo; y < yHi; y++) {
            for (jint x = asmEnd; x < xHi; x++)
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias255, preserveAlpha, edgeMode, x, y);
        }
    }
}

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__x86_64__) || defined(__i386__)
    const SimdLevel level = detectSimdLevel();
    backends |= SIMD_BACKEND_SSE2;
    if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
#elif defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backends |= SIMD_BACKEND_NEON32;
#endif
    return backends;
}
#endif

} // namespace Convolve

namespace {

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_nativeBackend(
        [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__x86_64__) || defined(__i386__)
    const SimdLevel level = detectSimdLevel();
    backends |= SIMD_BACKEND_SSE2;
    if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
#elif defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backends |= SIMD_BACKEND_NEON32;
#endif
    return backends;
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_applyForced(
        JNIEnv *env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst, jint width, jint height,
        const jfloatArray jKernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, jboolean preserveAlpha, jint edgeMode, jint simdBackend) {
    jint *src = env->GetIntArrayElements(jSrc, nullptr);
    jint *dst = env->GetIntArrayElements(jDst, nullptr);
    jfloat *kernel = env->GetFloatArrayElements(jKernel, nullptr);

    if (simdBackend == SIMD_BACKEND_SCALAR) {
        Convolve::applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);
    } else {
#if defined(__aarch64__) || defined(__arm__)
        assert(simdBackend == SIMD_BACKEND_NEON64 || simdBackend == SIMD_BACKEND_NEON32);
        Convolve::applyNeonInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);
#elif defined(__i386__) || defined(__x86_64__)
        Convolve::applyX86(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, simdBackend);
#else
        Convolve::applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);
#endif
    }

    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_apply(
        JNIEnv *env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst, jint width, jint height,
        const jfloatArray jKernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, jboolean preserveAlpha, jint edgeMode) {
    jint *src = env->GetIntArrayElements(jSrc, nullptr);
    jint *dst = env->GetIntArrayElements(jDst, nullptr);
    jfloat *kernel = env->GetFloatArrayElements(jKernel, nullptr);

#if defined(__aarch64__) || defined(__arm__)
    Convolve::applyNeonInterior(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);
#elif defined(__i386__) || defined(__x86_64__)
    Convolve::applyX86(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode, -1);
#else
    Convolve::applyScalar(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);
#endif

    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}

}
