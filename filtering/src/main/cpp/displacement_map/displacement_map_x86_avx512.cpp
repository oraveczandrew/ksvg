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

void ksvgDisplacementMapApplyAvx512(
        const jint* src, const jint* map, jint* dst, int width, int height,
        float scale, int xChannel, int yChannel) {
    const __m512 vScale = _mm512_set1_ps(scale);
    const __m512 vHalf = _mm512_set1_ps(0.5f);
    const __m512 v255 = _mm512_set1_ps(255.0f);
    const __m512i maskFF = _mm512_set1_epi32(0xFF);
    const __m512i vWidthMinus1 = _mm512_set1_epi32(width - 1);
    const __m512i vHeightMinus1 = _mm512_set1_epi32(height - 1);
    const __m512i vZero = _mm512_setzero_si512();
    const __m512i vWidth = _mm512_set1_epi32(width);

    int xs = xChannel == 0 ? 16 : xChannel == 1 ? 8 : xChannel == 2 ? 0 : 24;
    int ys = yChannel == 0 ? 16 : yChannel == 1 ? 8 : yChannel == 2 ? 0 : 24;

    for (int y = 0; y < height; y++) {
        const int rowOffset = y * width;
        const __m512i vY = _mm512_set1_epi32(y);
        int x = 0;
        for (; x + 16 <= width; x += 16) {
            const __m512i vX = _mm512_add_epi32(_mm512_set1_epi32(x), _mm512_setr_epi32(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15));
            const __m512i mapPixels = _mm512_loadu_si512(reinterpret_cast<const void*>(map + rowOffset + x));

            const __m512 vx = _mm512_div_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(mapPixels, xs), maskFF)), v255);
            const __m512 vy = _mm512_div_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(mapPixels, ys), maskFF)), v255);

            const __m512i idx = _mm512_cvttps_epi32(_mm512_mul_ps(vScale, _mm512_sub_ps(vx, vHalf)));
            const __m512i idy = _mm512_cvttps_epi32(_mm512_mul_ps(vScale, _mm512_sub_ps(vy, vHalf)));

            const __m512i sx = _mm512_max_epi32(vZero, _mm512_min_epi32(_mm512_add_epi32(vX, idx), vWidthMinus1));
            const __m512i sy = _mm512_max_epi32(vZero, _mm512_min_epi32(_mm512_add_epi32(vY, idy), vHeightMinus1));

            const __m512i indices = _mm512_add_epi32(_mm512_mullo_epi32(sy, vWidth), sx);
            const __m512i res = _mm512_i32gather_epi32(indices, src, 4);
            _mm512_storeu_si512(reinterpret_cast<void*>(dst + rowOffset + x), res);
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
