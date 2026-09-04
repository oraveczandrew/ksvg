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

void ksvgConvolveApplyInteriorAvx2(
        jint* dst, const jint* src, int width, int height,
        const float* kernel, int orderX, int orderY, int targetX, int targetY,
        float divisor, float bias, jboolean preserveAlpha) {
    const bool preserve = preserveAlpha == JNI_TRUE;
    const __m256 vDivisor = _mm256_set1_ps(divisor);
    const __m256 vBias255 = _mm256_set1_ps(bias * 255.0f);
    const __m256 vHalf = _mm256_set1_ps(0.5f);
    const __m256i maskFF = _mm256_set1_epi32(0xFF);
    const __m256i zero = _mm256_setzero_si256();
    const __m256i c255 = _mm256_set1_epi32(255);

    const int yLo = targetY;
    const int yHi = height - orderY + 1 + targetY;
    const int xLo = targetX;
    const int xHi = width - orderX + 1 + targetX;

    for (int y = yLo; y < yHi; y++) {
        const int rowOffset = y * width;
        int x = xLo;
        for (; x + 8 <= xHi; x += 8) {
            __m256 accR = _mm256_setzero_ps();
            __m256 accG = _mm256_setzero_ps();
            __m256 accB = _mm256_setzero_ps();
            __m256 accA = _mm256_setzero_ps();

            for (int ky = 0; ky < orderY; ky++) {
                const jint* srcRow = src + (y + ky - targetY) * width + (x - targetX);
                for (int kx = 0; kx < orderX; kx++) {
                    __m256 w = _mm256_set1_ps(kernel[ky * orderX + kx]);
                    __m256i p = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(srcRow + kx));
                    accB = _mm256_add_ps(accB, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_and_si256(p, maskFF)), w));
                    accG = _mm256_add_ps(accG, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(p, 8), maskFF)), w));
                    accR = _mm256_add_ps(accR, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(p, 16), maskFF)), w));
                    accA = _mm256_add_ps(accA, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_srli_epi32(p, 24)), w));
                }
            }

            auto roundRHU = [vDivisor, vBias255, vHalf](__m256 acc) {
                return _mm256_cvttps_epi32(_mm256_floor_ps(_mm256_add_ps(_mm256_add_ps(_mm256_div_ps(acc, vDivisor), vBias255), vHalf)));
            };

            __m256i iR = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accR), zero), c255);
            __m256i iG = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accG), zero), c255);
            __m256i iB = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accB), zero), c255);
            __m256i iA;

            if (preserve) {
                iA = _mm256_srli_epi32(_mm256_loadu_si256(reinterpret_cast<const __m256i*>(src + rowOffset + x)), 24);
            } else {
                iA = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accA), zero), c255);
            }

            __m256i out = _mm256_or_si256(_mm256_or_si256(_mm256_slli_epi32(iA, 24), _mm256_slli_epi32(iR, 16)),
                                         _mm256_or_si256(_mm256_slli_epi32(iG, 8), iB));
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + rowOffset + x), out);
        }
        for (; x < xHi; x++) {
            ksvg_x86::convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }
    }
}

} // extern "C"

#endif
