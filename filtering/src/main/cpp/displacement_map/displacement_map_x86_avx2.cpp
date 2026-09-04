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
#if defined(__i386__) || defined(__x86_64__)
#include <immintrin.h>
#endif
#include <algorithm>
#include "shared/simd_x86_utils.h"

#if defined(__i386__) || defined(__x86_64__)

extern "C" {

void ksvgDisplacementMapApplyAvx2(
        const jint* src, const jint* map, jint* dst, int width, int height,
        float scale, int xChannel, int yChannel) {
    __m256 vScale = _mm256_set1_ps(scale);
    __m256 vHalf = _mm256_set1_ps(0.5f);
    __m256 v255 = _mm256_set1_ps(255.0f);
    __m256i maskFF = _mm256_set1_epi32(0xFF);
    __m256i vWidthMinus1 = _mm256_set1_epi32(width - 1);
    __m256i vHeightMinus1 = _mm256_set1_epi32(height - 1);
    __m256i vZero = _mm256_setzero_si256();
    __m256i vWidth = _mm256_set1_epi32(width);

    int xs = xChannel == 0 ? 16 : xChannel == 1 ? 8 : xChannel == 2 ? 0 : 24;
    int ys = yChannel == 0 ? 16 : yChannel == 1 ? 8 : yChannel == 2 ? 0 : 24;

    for (int y = 0; y < height; y++) {
        const int rowOffset = y * width;
        __m256i vY = _mm256_set1_epi32(y);
        int x = 0;
        for (; x + 8 <= width; x += 8) {
            __m256i vX = _mm256_add_epi32(_mm256_set1_epi32(x), _mm256_setr_epi32(0, 1, 2, 3, 4, 5, 6, 7));
            __m256i mapPixels = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(map + rowOffset + x));

            __m256 vx = _mm256_div_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(mapPixels, xs), maskFF)), v255);
            __m256 vy = _mm256_div_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(mapPixels, ys), maskFF)), v255);

            __m256i idx = _mm256_cvttps_epi32(_mm256_mul_ps(vScale, _mm256_sub_ps(vx, vHalf)));
            __m256i idy = _mm256_cvttps_epi32(_mm256_mul_ps(vScale, _mm256_sub_ps(vy, vHalf)));

            __m256i sx = _mm256_max_epi32(vZero, _mm256_min_epi32(_mm256_add_epi32(vX, idx), vWidthMinus1));
            __m256i sy = _mm256_max_epi32(vZero, _mm256_min_epi32(_mm256_add_epi32(vY, idy), vHeightMinus1));

            __m256i indices = _mm256_add_epi32(_mm256_mullo_epi32(sy, vWidth), sx);
            __m256i res = _mm256_i32gather_epi32(src, indices, 4);
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + rowOffset + x), res);
        }
        for (; x < width; x++) {
            jint mapPixel = map[rowOffset + x];
            int dx = (int)(scale * (ksvg_x86::getChannelValue(mapPixel, xChannel) - 0.5f));
            int dy = (int)(scale * (ksvg_x86::getChannelValue(mapPixel, yChannel) - 0.5f));
            int sx = std::max(0, std::min(width - 1, x + dx));
            int sy = std::max(0, std::min(height - 1, y + dy));
            dst[rowOffset + x] = src[sy * width + sx];
        }
    }
}

} // extern "C"

#endif
