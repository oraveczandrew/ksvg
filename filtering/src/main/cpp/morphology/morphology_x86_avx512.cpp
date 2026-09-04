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

void ksvgMorphologyApplyPixelAvx512(
        const jint* src, jint* dst, const jint width,
        const jint radiusX, const jint radiusY, const jboolean erode, const jint x, const jint y) {
    const bool isErode = erode == JNI_TRUE;
    const jint top = y - radiusY;
    const jint bottom = y + radiusY;
    const jint left = x - radiusX;
    const jint right = x + radiusX;

    __m512i acc = _mm512_set1_epi8(isErode ? -1 : 0);

    for (jint ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        jint kx = left;
        for (; kx + 16 <= right + 1; kx += 16) {
            __m512i c = _mm512_loadu_si512(reinterpret_cast<const void*>(row + kx));
            acc = isErode ? _mm512_min_epu8(acc, c) : _mm512_max_epu8(acc, c);
        }
        for (; kx <= right; kx++) {
            jint c = row[kx];
            __m512i cv = _mm512_set1_epi32(c);
            acc = isErode ? _mm512_min_epu8(acc, cv) : _mm512_max_epu8(acc, cv);
        }
    }

    alignas(64) uint8_t res[64];
    _mm512_storeu_si512(reinterpret_cast<void*>(res), acc);

    uint8_t finalA = res[3], finalR = res[2], finalG = res[1], finalB = res[0];
    for (int i = 1; i < 16; i++) {
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
