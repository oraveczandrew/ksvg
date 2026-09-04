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

void ksvgConvolveApplyInteriorAvx512(
        jint* dst, const jint* src, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha) {
    const bool preserve = preserveAlpha == JNI_TRUE;
    const __m512 vDivisor = _mm512_set1_ps(divisor);
    const __m512 vBias255 = _mm512_set1_ps(bias * 255.0f);
    const __m512 vHalf = _mm512_set1_ps(0.5f);
    const __m512i maskFF = _mm512_set1_epi32(0xFF);
    const __m512i zero = _mm512_setzero_si512();
    const __m512i c255 = _mm512_set1_epi32(255);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;
        int x = xLo;
        for (; x + 16 <= xHi; x += 16) {
            __m512 accR = _mm512_setzero_ps();
            __m512 accG = _mm512_setzero_ps();
            __m512 accB = _mm512_setzero_ps();
            __m512 accA = _mm512_setzero_ps();

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* srcRow = src + (y + ky - targetY) * width + (x - targetX);
                for (jint kx = 0; kx < orderX; kx++) {
                    const __m512 w = _mm512_set1_ps(kernel[ky * orderX + kx]);
                    const __m512i p = _mm512_loadu_si512(reinterpret_cast<const void*>(srcRow + kx));
                    accB = _mm512_add_ps(accB, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_and_si512(p, maskFF)), w));
                    accG = _mm512_add_ps(accG, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(p, 8), maskFF)), w));
                    accR = _mm512_add_ps(accR, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(p, 16), maskFF)), w));
                    accA = _mm512_add_ps(accA, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_srli_epi32(p, 24)), w));
                }
            }

            auto roundRHU = [vDivisor, vBias255, vHalf](__m512 acc) {
                return _mm512_cvttps_epi32(_mm512_floor_ps(_mm512_add_ps(_mm512_add_ps(_mm512_div_ps(acc, vDivisor), vBias255), vHalf)));
            };

            __m512i iR = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accR), zero), c255);
            __m512i iG = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accG), zero), c255);
            __m512i iB = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accB), zero), c255);
            __m512i iA;

            if (preserve) {
                iA = _mm512_srli_epi32(_mm512_loadu_si512(reinterpret_cast<const void*>(src + rowOffset + x)), 24);
            } else {
                iA = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accA), zero), c255);
            }

            const __m512i out = _mm512_or_si512(_mm512_or_si512(_mm512_slli_epi32(iA, 24), _mm512_slli_epi32(iR, 16)),
                                               _mm512_or_si512(_mm512_slli_epi32(iG, 8), iB));
            _mm512_storeu_si512(reinterpret_cast<void*>(dst + rowOffset + x), out);
        }
        for (; x < xHi; x++) {
            ksvg_x86::convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }
    }
}

} // extern "C"

#endif
