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
#include <cmath>
#include <cassert>
#include "cpu_dispatch.h"
#include "simd_x86.h"

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
            const jint mapX = (mapWidth <= 1) ? 0 : (jint)((float)x / widthDivisor * (mapWidth - 1));
            const jint mapY = (mapHeight <= 1) ? 0 : (jint)((float)y / heightDivisor * (mapHeight - 1));
            const jint mapPixel = map[mapY * mapWidth + mapX];

            const int dx = (int)(scale * (getChannelValue(mapPixel, xChannel) - 0.5f));
            const int dy = (int)(scale * (getChannelValue(mapPixel, yChannel) - 0.5f));

            int sx = x + dx;
            int sy = y + dy;
            if (sx < 0) sx = 0; else if (sx >= width) sx = width - 1;
            if (sy < 0) sy = 0; else if (sy >= height) sy = height - 1;

            dst[rowOffset + x] = src[sy * width + sx];
        }
    }
}

#ifdef __aarch64__
#include <arm_neon.h>

template<int Shift>
static inline uint32x4_t shiftRightFF(uint32x4_t pixels) {
    if constexpr (Shift == 0) {
        return pixels;
    } else {
        return vshrq_n_u32(pixels, Shift);
    }
}


template<int XShift, int YShift, int XChannel, int YChannel>
static inline void applyNeon64Impl(
        const jint* src,
        const jint* map,
        jint* dst,
        const int width,
        const int height,
        const float scale) {

    const float32x4_t vScale = vdupq_n_f32(scale);
    const float32x4_t vHalf = vdupq_n_f32(0.5f);
    const float32x4_t v255 = vdupq_n_f32(255.0f);

    const uint32x4_t maskFF = vdupq_n_u32(0xFF);

    const int32x4_t vWidthMinus1 = vdupq_n_s32(width - 1);
    const int32x4_t vHeightMinus1 = vdupq_n_s32(height - 1);
    const int32x4_t vZero = vdupq_n_s32(0);

    static const int32_t increments[4] = {0, 1, 2, 3};
    const int32x4_t vIncrements = vld1q_s32(increments);

    for (int y = 0; y < height; ++y) {
        const int rowOffset = y * width;
        const int32x4_t vY = vdupq_n_s32(y);

        int x = 0;

        for (; x + 4 <= width; x += 4) {
            const int32x4_t vX =
                    vaddq_s32(vdupq_n_s32(x), vIncrements);

            const uint32x4_t mapPixels =
                    vld1q_u32(
                            reinterpret_cast<const uint32_t*>(
                                    map + rowOffset + x));

            const uint32x4_t xPixels =
                    vandq_u32(
                            shiftRightFF<XShift>(mapPixels),
                            maskFF);

            const uint32x4_t yPixels =
                    vandq_u32(
                            shiftRightFF<YShift>(mapPixels),
                            maskFF);

            const float32x4_t vx =
                    vdivq_f32(
                            vcvtq_f32_u32(xPixels),
                            v255);

            const float32x4_t vy =
                    vdivq_f32(
                            vcvtq_f32_u32(yPixels),
                            v255);

            const int32x4_t idx =
                    vcvtq_s32_f32(
                            vmulq_f32(
                                    vScale,
                                    vsubq_f32(vx, vHalf)));

            const int32x4_t idy =
                    vcvtq_s32_f32(
                            vmulq_f32(
                                    vScale,
                                    vsubq_f32(vy, vHalf)));

            const int32x4_t sx =
                    vmaxq_s32(
                            vZero,
                            vminq_s32(
                                    vaddq_s32(vX, idx),
                                    vWidthMinus1));

            const int32x4_t sy =
                    vmaxq_s32(
                            vZero,
                            vminq_s32(
                                    vaddq_s32(vY, idy),
                                    vHeightMinus1));

            alignas(16) int32_t sxa[4];
            alignas(16) int32_t sya[4];

            vst1q_s32(sxa, sx);
            vst1q_s32(sya, sy);

            dst[rowOffset + x + 0] =
                    src[sya[0] * width + sxa[0]];

            dst[rowOffset + x + 1] =
                    src[sya[1] * width + sxa[1]];

            dst[rowOffset + x + 2] =
                    src[sya[2] * width + sxa[2]];

            dst[rowOffset + x + 3] =
                    src[sya[3] * width + sxa[3]];
        }

        for (; x < width; ++x) {
            const jint mapPixel = map[rowOffset + x];

            const int dx =
                    (int)(
                            scale *
                            (getChannelValue(mapPixel, XChannel) - 0.5f));

            const int dy =
                    (int)(
                            scale *
                            (getChannelValue(mapPixel, YChannel) - 0.5f));

            const int sx =
                    std::max(
                            0,
                            std::min(width - 1, x + dx));

            const int sy =
                    std::max(
                            0,
                            std::min(height - 1, y + dy));

            dst[rowOffset + x] =
                    src[sy * width + sx];
        }
    }
}


void applyNeon64(
        const jint* src,
        const jint* map,
        jint* dst,
        const int width,
        const int height,
        const float scale,
        const int xChannel,
        const int yChannel) {

    const int key = (xChannel << 2) | yChannel;

    switch (key) {
        case 0:
            applyNeon64Impl<16, 16, 0, 0>(
                    src, map, dst, width, height, scale);
            break;
        case 1:
            applyNeon64Impl<16, 8, 0, 1>(
                    src, map, dst, width, height, scale);
            break;
        case 2:
            applyNeon64Impl<16, 0, 0, 2>(
                    src, map, dst, width, height, scale);
            break;
        case 3:
            applyNeon64Impl<16, 24, 0, 3>(
                    src, map, dst, width, height, scale);
            break;

        case 4:
            applyNeon64Impl<8, 16, 1, 0>(
                    src, map, dst, width, height, scale);
            break;
        case 5:
            applyNeon64Impl<8, 8, 1, 1>(
                    src, map, dst, width, height, scale);
            break;
        case 6:
            applyNeon64Impl<8, 0, 1, 2>(
                    src, map, dst, width, height, scale);
            break;
        case 7:
            applyNeon64Impl<8, 24, 1, 3>(
                    src, map, dst, width, height, scale);
            break;

        case 8:
            applyNeon64Impl<0, 16, 2, 0>(
                    src, map, dst, width, height, scale);
            break;
        case 9:
            applyNeon64Impl<0, 8, 2, 1>(
                    src, map, dst, width, height, scale);
            break;
        case 10:
            applyNeon64Impl<0, 0, 2, 2>(
                    src, map, dst, width, height, scale);
            break;
        case 11:
            applyNeon64Impl<0, 24, 2, 3>(
                    src, map, dst, width, height, scale);
            break;

        case 12:
            applyNeon64Impl<24, 16, 3, 0>(
                    src, map, dst, width, height, scale);
            break;
        case 13:
            applyNeon64Impl<24, 8, 3, 1>(
                    src, map, dst, width, height, scale);
            break;
        case 14:
            applyNeon64Impl<24, 0, 3, 2>(
                    src, map, dst, width, height, scale);
            break;
        case 15:
            applyNeon64Impl<24, 24, 3, 3>(
                    src, map, dst, width, height, scale);
            break;

        default:
            __builtin_unreachable();
    }
}
#endif

} // namespace


// Validation/test-only: run an explicitly selected backend (see SimdBackend).
namespace {

void runForced(const jint* src, const jint* map, jint* dst, int width, int height,
               int mapWidth, int mapHeight, float scale, int xChannel, int yChannel,
               int backend) {
    if (width == mapWidth && height == mapHeight) {
#if defined(__aarch64__)
        if (backend == SIMD_BACKEND_SCALAR) {
            applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
        } else {
            assert(backend == SIMD_BACKEND_NEON64);
            applyNeon64(src, map, dst, width, height, scale, xChannel, yChannel);
        }
#elif defined(__i386__) || defined(__x86_64__)
        switch (backend) {
            case SIMD_BACKEND_SCALAR:
                applyScalar(src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel);
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
#if defined(__aarch64__)
    return SIMD_BACKEND_NEON64;
#elif defined(__i386__) || defined(__x86_64__)
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX512) return SIMD_BACKEND_AVX512;
    if (level >= SIMD_AVX2)   return SIMD_BACKEND_AVX2;
    return SIMD_BACKEND_SCALAR;
#else
    return SIMD_BACKEND_SCALAR;
#endif
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_DisplacementMapNative_nativeBackend(
        JNIEnv* env, jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_DisplacementMapNative_applyForced(
        JNIEnv* env, jclass clazz,
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
        JNIEnv* env, jclass clazz,
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
        applyNeon64(src, map, dst, width, height, scale, xChannel, yChannel);
#elif defined(__i386__) || defined(__x86_64__)
        const SimdLevel level = detectSimdLevel();
        if (level >= SIMD_AVX512) {
            ksvgDisplacementMapApplyAvx512(src, map, dst, width, height, scale, xChannel, yChannel);
        } else if (level >= SIMD_AVX2) {
            ksvgDisplacementMapApplyAvx2(src, map, dst, width, height, scale, xChannel, yChannel);
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
