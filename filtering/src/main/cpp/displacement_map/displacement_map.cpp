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
#include <algorithm>
#include <cassert>
#include "cpu_dispatch.h"
#include "simd_x86.h"

#if defined(__aarch64__)
// Hand-written AArch64 NEON kernel: 4 px/iteration, no vector→stack→scalar
// spill. See displacement_map_arm64_neon64.S.
extern "C" void ksvgDisplacementMapApplyNeon64(
        const int32_t* src, const int32_t* map, int32_t* dst,
        int width, int height, float scale, int xChannel, int yChannel);
#elif defined(__arm__)
// Hand-written ARMv7 NEON kernel. See displacement_map_arm32_neon32.S.
extern "C" void ksvgDisplacementMapApplyNeon32(
        const int32_t* src, const int32_t* map, int32_t* dst,
        int width, int height, float scale, int xChannel, int yChannel);
#endif

namespace {

inline float getChannelValue(const jint pixel, const int channel) {
    switch (channel) {
        case 0: return ((pixel >> 16) & 0xFF) / 255.0f; // R
        case 1: return ((pixel >> 8) & 0xFF) / 255.0f;  // G
        case 2: return (pixel & 0xFF) / 255.0f;         // B
        default: return ((pixel >> 24) & 0xFF) / 255.0f; // A
    }
}

void applyScalar(
        const jint* src, const jint* map, jint* dst, const int width, const int height,
        const int mapWidth, const int mapHeight, const float scale, const int xChannel, const int yChannel) {
    const int widthDivisor = std::max(width - 1, 1);
    const int heightDivisor = std::max(height - 1, 1);

    for (jint y = 0; y < height; y++) {
        const jint rowOffset = y * width;
        for (jint x = 0; x < width; x++) {
            const jint mapX = mapWidth <= 1 ? 0 : static_cast<jint>(static_cast<float>(x) / widthDivisor * (mapWidth - 1));
            const jint mapY = mapHeight <= 1 ? 0 : static_cast<jint>(static_cast<float>(y) / heightDivisor * (mapHeight - 1));
            const jint mapPixel = map[mapY * mapWidth + mapX];

            const int dx = static_cast<int>(scale * (getChannelValue(mapPixel, xChannel) - 0.5f));
            const int dy = static_cast<int>(scale * (getChannelValue(mapPixel, yChannel) - 0.5f));

            int sx = x + dx;
            int sy = y + dy;
            if (sx < 0) sx = 0; else if (sx >= width) sx = width - 1;
            if (sy < 0) sy = 0; else if (sy >= height) sy = height - 1;

            dst[rowOffset + x] = src[sy * width + sx];
        }
    }
}

} // namespace


// Validation/test-only: run an explicitly selected backend (see SimdBackend).
namespace {

void runForced(const jint* src, const jint* map, jint* dst, int width, int height,
               const int mapWidth, const int mapHeight, float scale, int xChannel, int yChannel,
               const int backend) {
    if (width == mapWidth && height == mapHeight) {
#if defined(__aarch64__)
        if (backend == SIMD_BACKEND_SCALAR) {
            applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
        } else {
            assert(backend == SIMD_BACKEND_NEON64);
            ksvgDisplacementMapApplyNeon64(src, map, dst, width, height, scale, xChannel, yChannel);
        }
#elif defined(__arm__)
        if (backend == SIMD_BACKEND_SCALAR) {
            applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
        } else {
            assert(backend == SIMD_BACKEND_NEON32);
            ksvgDisplacementMapApplyNeon32(src, map, dst, width, height, scale, xChannel, yChannel);
        }
#elif defined(__x86_64__)
        switch (backend) {
            case SIMD_BACKEND_SCALAR:
                applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
                break;
            case SIMD_BACKEND_SSE2:
                ksvgDisplacementMapApplySse2(src, map, dst, width, height, scale, xChannel, yChannel);
                break;
            case SIMD_BACKEND_AVX2:
                ksvgDisplacementMapApplyAvx2(src, map, dst, width, height, scale, xChannel, yChannel);
                break;
            case SIMD_BACKEND_AVX512:
                ksvgDisplacementMapApplyAvx512(src, map, dst, width, height, scale, xChannel, yChannel);
                break;
            default:
                assert(false && "unsupported forced displacement_map backend on x86");
        }
#elif defined(__i386__)
        switch (backend) {
            case SIMD_BACKEND_SCALAR:
                applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
                break;
            case SIMD_BACKEND_SSSE3:
                ksvgDisplacementMapApplySsse3_i386(src, map, dst, width, height, scale, xChannel, yChannel);
                break;
            case SIMD_BACKEND_AVX2:
                ksvgDisplacementMapApplyAvx2_i386(src, map, dst, width, height, scale, xChannel, yChannel);
                break;
            default:
                assert(false && "unsupported forced displacement_map backend on x86");
        }
#else
        (void)backend;
        applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
#endif
        return;
    }
    (void)backend;
    applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
}

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__arm__)
    backends |= SIMD_BACKEND_NEON32;
#elif defined(__x86_64__)
    const SimdLevel level = detectSimdLevel();
    backends |= SIMD_BACKEND_SSE2;
    if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
    if (level >= SIMD_AVX512) backends |= SIMD_BACKEND_AVX512;
#elif defined(__i386__)
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_SSSE3) backends |= SIMD_BACKEND_SSSE3;
    if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_DisplacementMapNative_nativeBackend(
        [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_DisplacementMapNative_applyForced(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jMap, const jintArray jDst,
        const jint width, const jint height, const jint mapWidth, const jint mapHeight,
        const jfloat scale, const jint xChannel, const jint yChannel,
        const jint simdBackend) {
    auto* src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) return;
    auto* map = env->GetIntArrayElements(jMap, nullptr);
    if (map == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }
    auto* dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jMap, map, JNI_ABORT);
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }

    runForced(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel, simdBackend);

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jMap, map, JNI_ABORT);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_DisplacementMapNative_apply(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jMap, const jintArray jDst,
        const jint width, const jint height, const jint mapWidth, const jint mapHeight,
        const jfloat scale, const jint xChannel, const jint yChannel) {
    auto* src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) return;
    auto* map = env->GetIntArrayElements(jMap, nullptr);
    if (map == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }
    auto* dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jMap, map, JNI_ABORT);
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }

    if (width == mapWidth && height == mapHeight) {
#if defined(__aarch64__)
        ksvgDisplacementMapApplyNeon64(src, map, dst, width, height, scale, xChannel, yChannel);
#elif defined(__arm__)
        ksvgDisplacementMapApplyNeon32(src, map, dst, width, height, scale, xChannel, yChannel);
#elif defined(__x86_64__)
        const SimdLevel level = detectSimdLevel();
        if (level >= SIMD_AVX512) {
            ksvgDisplacementMapApplyAvx512(src, map, dst, width, height, scale, xChannel, yChannel);
        } else if (level >= SIMD_AVX2) {
            ksvgDisplacementMapApplyAvx2(src, map, dst, width, height, scale, xChannel, yChannel);
        } else {
            ksvgDisplacementMapApplySse2(src, map, dst, width, height, scale, xChannel, yChannel);
        }
#elif defined(__i386__)
        const SimdLevel level = detectSimdLevel();
        if (level >= SIMD_AVX2) {
            ksvgDisplacementMapApplyAvx2_i386(src, map, dst, width, height, scale, xChannel, yChannel);
        } else if (level >= SIMD_SSSE3) {
            ksvgDisplacementMapApplySsse3_i386(src, map, dst, width, height, scale, xChannel, yChannel);
        } else {
            applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
        }
#else
        applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
#endif
    } else {
        applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
    }

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jMap, map, JNI_ABORT);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}
