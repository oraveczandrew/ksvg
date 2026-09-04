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
#include <cstdint>

#if defined(__i386__) || defined(__x86_64__)

extern "C" {

void ksvgMorphologyApplyPixelAvx2(
        const jint* src, jint* dst, int width,
        int radiusX, int radiusY, jboolean erode,
        int x, int y) {
    bool isErode = erode == JNI_TRUE;
    int top = y - radiusY;
    int bottom = y + radiusY;
    int left = x - radiusX;
    int right = x + radiusX;

    __m256i acc = _mm256_set1_epi8(isErode ? -1 : 0);

    for (int ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        int kx = left;
        for (; kx + 8 <= right + 1; kx += 8) {
            __m256i c = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(row + kx));
            acc = isErode ? _mm256_min_epu8(acc, c) : _mm256_max_epu8(acc, c);
        }
        for (; kx <= right; kx++) {
            jint c = row[kx];
            __m256i cv = _mm256_set1_epi32(c);
            acc = isErode ? _mm256_min_epu8(acc, cv) : _mm256_max_epu8(acc, cv);
        }
    }

    alignas(32) uint8_t res[32];
    _mm256_storeu_si256(reinterpret_cast<__m256i*>(res), acc);

    uint8_t finalA = res[3], finalR = res[2], finalG = res[1], finalB = res[0];
    for (int i = 1; i < 8; i++) {
        if (isErode) {
            finalA = std::min(finalA, res[i * 4 + 3]);
            finalR = std::min(finalR, res[i * 4 + 2]);
            finalG = std::min(finalG, res[i * 4 + 1]);
            finalB = std::min(finalB, res[i * 4 + 0]);
        } else {
            finalA = std::max(finalA, res[i * 4 + 3]);
            finalR = std::max(finalR, res[i * 4 + 2]);
            finalG = std::max(finalG, res[i * 4 + 1]);
            finalB = std::max(finalB, res[i * 4 + 0]);
        }
    }
    dst[y * width + x] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
}

} // extern "C"

#endif
