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


#if !defined(__aarch64__) && defined(__SSE2__)
#include <jni.h>
#include <cmath>
#include <cassert>
#include <emmintrin.h>
#include "convolve.h"
#include "cpu_dispatch.h"
#include "simd_x86.h"

namespace Convolve {

    static inline __m128i clamp255Sse(__m128i v) {
        const __m128i zero = _mm_setzero_si128();
        const __m128i isPos = _mm_cmpgt_epi32(v, zero);
        v = _mm_and_si128(v, isPos);
        const __m128i over = _mm_cmpgt_epi32(v, _mm_set1_epi32(255));
        return _mm_or_si128(_mm_andnot_si128(over, v), _mm_and_si128(over, _mm_set1_epi32(255)));
    }

    void applySseInterior(
        jint *dst, const jint *src, jint width, jint height,
        const jfloat *kernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, bool preserve) {
        const __m128 vDivisor = _mm_set1_ps(divisor);
        const __m128 vBias255 = _mm_set1_ps(bias * 255.0f);
        const __m128 vHalf = _mm_set1_ps(0.5f);
        const __m128i maskFF = _mm_set1_epi32(0xFF);

        const jint yLo = targetY;
        const jint yHi = height - orderY + 1 + targetY;
        const jint xLo = targetX;
        const jint xHi = width - orderX + 1 + targetX;

        for (jint y = yLo; y < yHi; y++) {
            const jint rowOffset = y * width;
            jint x = 0;
            for (; x < xLo; x++) {
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                    targetX, targetY, divisor, bias, preserve, 0, x, y);
            }

            for (; x + 4 <= xHi; x += 4) {
                __m128 accR = _mm_setzero_ps();
                __m128 accG = _mm_setzero_ps();
                __m128 accB = _mm_setzero_ps();
                __m128 accA = _mm_setzero_ps();

                for (jint ky = 0; ky < orderY; ky++) {
                    const jint *srcRow = src + (y + ky - targetY) * width + (x - targetX);
                    for (jint kx = 0; kx < orderX; kx++) {
                        const __m128 w = _mm_set1_ps(kernel[ky * orderX + kx]);
                        const __m128i p = _mm_loadu_si128(reinterpret_cast<const __m128i *>(srcRow + kx));
                        accB = _mm_add_ps(accB, _mm_mul_ps(_mm_cvtepi32_ps(_mm_and_si128(p, maskFF)), w));
                        accG = _mm_add_ps(accG, _mm_mul_ps(_mm_cvtepi32_ps(_mm_and_si128(_mm_srli_epi32(p, 8), maskFF)),
                                                           w));
                        accR = _mm_add_ps(
                            accR, _mm_mul_ps(_mm_cvtepi32_ps(_mm_and_si128(_mm_srli_epi32(p, 16), maskFF)), w));
                        accA = _mm_add_ps(accA, _mm_mul_ps(_mm_cvtepi32_ps(_mm_srli_epi32(p, 24)), w));
                    }
                }

                auto roundRHU = [vDivisor, vBias255, vHalf](__m128 acc) {
                    // Manual floor(x + 0.5) to match Round Half Up on SSE2
                    __m128 val = _mm_add_ps(_mm_add_ps(_mm_div_ps(acc, vDivisor), vBias255), vHalf);
                    __m128i i = _mm_cvttps_epi32(val);
                    __m128 fi = _mm_cvtepi32_ps(i);
                    __m128 mask = _mm_cmpgt_ps(fi, val);
                    return _mm_cvttps_epi32(_mm_sub_ps(fi, _mm_and_ps(mask, _mm_set1_ps(1.0f))));
                };

                __m128i iR = clamp255Sse(roundRHU(accR));
                __m128i iG = clamp255Sse(roundRHU(accG));
                __m128i iB = clamp255Sse(roundRHU(accB));
                __m128i iA;

                if (preserve) {
                    iA = _mm_srli_epi32(_mm_loadu_si128(reinterpret_cast<const __m128i *>(src + rowOffset + x)), 24);
                } else {
                    iA = clamp255Sse(roundRHU(accA));
                }

                const __m128i out = _mm_or_si128(_mm_or_si128(_mm_slli_epi32(iA, 24), _mm_slli_epi32(iR, 16)),
                                                 _mm_or_si128(_mm_slli_epi32(iG, 8), iB));
                _mm_storeu_si128(reinterpret_cast<__m128i *>(dst + rowOffset + x), out);
            }

            for (; x < width; x++) {
                convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                    targetX, targetY, divisor, bias, preserve, 0, x, y);
            }
        }
    }
}
#endif
