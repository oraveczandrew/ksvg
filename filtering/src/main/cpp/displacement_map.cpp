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
#include "cpu_dispatch.h"
#include "simd_x86.h"

namespace {

inline float getChannelValue(jint pixel, int channel) {
    switch (channel) {
        case 0: return ((pixel >> 16) & 0xFF) / 255.0f; // R
        case 1: return ((pixel >> 8) & 0xFF) / 255.0f;  // G
        case 2: return (pixel & 0xFF) / 255.0f;         // B
        default: return ((pixel >> 24) & 0xFF) / 255.0f; // A
    }
}

void applyScalar(
        const jint* src, const jint* map, jint* dst, int width, int height,
        int mapWidth, int mapHeight, float scale, int xChannel, int yChannel) {
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

void applyNeon64(
        const jint* src, const jint* map, jint* dst, int width, int height,
        float scale, int xChannel, int yChannel) {
    const float32x4_t vScale = vdupq_n_f32(scale);
    const float32x4_t vHalf = vdupq_n_f32(0.5f);
    const float32x4_t v255 = vdupq_n_f32(255.0f);
    const uint32x4_t maskFF = vdupq_n_u32(0xFF);
    const int32x4_t vWidthMinus1 = vdupq_n_s32(width - 1);
    const int32x4_t vHeightMinus1 = vdupq_n_s32(height - 1);
    const int32x4_t vZero = vdupq_n_s32(0);

    static const int32_t increments[4] = {0, 1, 2, 3};
    const int32x4_t vIncrements = vld1q_s32(increments);

    int xs = xChannel == 0 ? 16 : xChannel == 1 ? 8 : xChannel == 2 ? 0 : 24;
    int ys = yChannel == 0 ? 16 : yChannel == 1 ? 8 : yChannel == 2 ? 0 : 24;

    for (int y = 0; y < height; y++) {
        const int rowOffset = y * width;
        const int32x4_t vY = vdupq_n_s32(y);
        int x = 0;
        for (; x + 4 <= width; x += 4) {
            const int32x4_t vX = vaddq_s32(vdupq_n_s32(x), vIncrements);
            const uint32x4_t mapPixels = vld1q_u32(reinterpret_cast<const uint32_t*>(map + rowOffset + x));

            const float32x4_t vx = vdivq_f32(vcvtq_f32_u32(vandq_u32(vshrq_n_u32(mapPixels, xs), maskFF)), v255);
            const float32x4_t vy = vdivq_f32(vcvtq_f32_u32(vandq_u32(vshrq_n_u32(mapPixels, ys), maskFF)), v255);

            // Using vcvtq_s32_f32 which rounds towards zero, matching Kotlin (int) conversion.
            const int32x4_t idx = vcvtq_s32_f32(vmulq_f32(vScale, vsubq_f32(vx, vHalf)));
            const int32x4_t idy = vcvtq_s32_f32(vmulq_f32(vScale, vsubq_f32(vy, vHalf)));

            int32x4_t sx = vmaxq_s32(vZero, vminq_s32(vaddq_s32(vX, idx), vWidthMinus1));
            int32x4_t sy = vmaxq_s32(vZero, vminq_s32(vaddq_s32(vY, idy), vHeightMinus1));

            alignas(16) int32_t sxa[4], sya[4];
            vst1q_s32(sxa, sx);
            vst1q_s32(sya, sy);

            dst[rowOffset + x + 0] = src[sya[0] * width + sxa[0]];
            dst[rowOffset + x + 1] = src[sya[1] * width + sxa[1]];
            dst[rowOffset + x + 2] = src[sya[2] * width + sxa[2]];
            dst[rowOffset + x + 3] = src[sya[3] * width + sxa[3]];
        }
        for (; x < width; x++) {
            const jint mapPixel = map[rowOffset + x];
            int dx = (int)(scale * (getChannelValue(mapPixel, xChannel) - 0.5f));
            int dy = (int)(scale * (getChannelValue(mapPixel, yChannel) - 0.5f));
            int sx = std::max(0, std::min(width - 1, x + dx));
            int sy = std::max(0, std::min(height - 1, y + dy));
            dst[rowOffset + x] = src[sy * width + sx];
        }
    }
}
#endif

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_DisplacementMapNative_apply(
        JNIEnv* env, jclass clazz,
        jintArray jSrc, jintArray jMap, jintArray jDst,
        jint width, jint height, jint mapWidth, jint mapHeight,
        jfloat scale, jint xChannel, jint yChannel) {
    jint* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    jint* map = static_cast<jint*>(env->GetPrimitiveArrayCritical(jMap, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));

    if (src && map && dst) {
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
    }

    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    if (map) env->ReleasePrimitiveArrayCritical(jMap, map, JNI_ABORT);
    if (src) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
