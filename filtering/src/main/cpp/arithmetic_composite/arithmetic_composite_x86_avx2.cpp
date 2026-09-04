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
#include "arithmetic_composite.h"
#include "srgb_lut.h"

#if defined(__i386__) || defined(__x86_64__)

namespace {

inline __m256i lutRowBroadcast256(const jbyte* table, int row) {
    const __m128i v = _mm_loadu_si128(
            reinterpret_cast<const __m128i*>(table + row * 16));
    return _mm256_broadcastsi128_si256(v);
}

inline __m256i lut256Avx2(__m256i value, const __m256i rows[16]) {
    const __m256i loMask = _mm256_set1_epi8(0x0f);
    const __m256i lo = _mm256_and_si256(value, loMask);
    const __m256i hi = _mm256_and_si256(_mm256_srli_epi16(value, 4), loMask);

    __m256i result = _mm256_setzero_si256();
    for (int row = 0; row < 16; ++row) {
        const __m256i candidate = _mm256_shuffle_epi8(rows[row], lo);
        const __m256i selected =
                _mm256_cmpeq_epi8(hi, _mm256_set1_epi8(static_cast<char>(row)));
        result = _mm256_or_si256(result, _mm256_and_si256(candidate, selected));
    }
    return result;
}

} // namespace

extern "C" {

void ksvgArithmeticApplyAvx2(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb) {
    __m256 vK1_255 = _mm256_set1_ps(k1 / 255.0f);
    __m256 vK2 = _mm256_set1_ps(k2);
    __m256 vK3 = _mm256_set1_ps(k3);
    __m256 vK4_255_05 = _mm256_set1_ps(k4 * 255.0f + 0.5f);
    __m256i maskFF = _mm256_set1_epi32(0xFF);
    __m256i zero = _mm256_setzero_si256();
    __m256i c255 = _mm256_set1_epi32(255);

    __m256i tS2L[16], tL2S[16];
    if (useLinear) {
        for (int i = 0; i < 16; i++) {
            tS2L[i] = lutRowBroadcast256(srgbToLinear, i);
            tL2S[i] = lutRowBroadcast256(linearToSrgb, i);
        }
    }

    auto compute = [&](__m256 a, __m256 b) {
        __m256 res = _mm256_mul_ps(_mm256_mul_ps(a, b), vK1_255);
        res = _mm256_add_ps(res, _mm256_mul_ps(a, vK2));
        res = _mm256_add_ps(res, _mm256_mul_ps(b, vK3));
        res = _mm256_add_ps(res, vK4_255_05);
        return _mm256_min_epi32(_mm256_max_epi32(_mm256_cvttps_epi32(res), zero), c255);
    };

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        for (; x + 8 <= clipRight; x += 8) {
            __m256i p1 = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(src1 + rowOffset + x));
            __m256i p2 = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(src2 + rowOffset + x));

            __m256i c1[4], c2[4], out[4];
            c1[0] = _mm256_and_si256(p1, maskFF);
            c1[1] = _mm256_and_si256(_mm256_srli_epi32(p1, 8), maskFF);
            c1[2] = _mm256_and_si256(_mm256_srli_epi32(p1, 16), maskFF);
            c1[3] = _mm256_srli_epi32(p1, 24);

            c2[0] = _mm256_and_si256(p2, maskFF);
            c2[1] = _mm256_and_si256(_mm256_srli_epi32(p2, 8), maskFF);
            c2[2] = _mm256_and_si256(_mm256_srli_epi32(p2, 16), maskFF);
            c2[3] = _mm256_srli_epi32(p2, 24);

            out[3] = compute(_mm256_cvtepi32_ps(c1[3]), _mm256_cvtepi32_ps(c2[3]));

            if (useLinear) {
                for (int j = 0; j < 3; j++) {
                    __m256i l1 = lut256Avx2(c1[j], tS2L);
                    __m256i l2 = lut256Avx2(c2[j], tS2L);
                    __m256i res = compute(_mm256_cvtepi32_ps(l1), _mm256_cvtepi32_ps(l2));
                    out[j] = lut256Avx2(res, tL2S);
                }
            } else {
                for (int j = 0; j < 3; j++) {
                    out[j] = compute(_mm256_cvtepi32_ps(c1[j]), _mm256_cvtepi32_ps(c2[j]));
                }
            }

            __m256i res = _mm256_or_si256(_mm256_or_si256(_mm256_slli_epi32(out[3], 24), _mm256_slli_epi32(out[2], 16)),
                                         _mm256_or_si256(_mm256_slli_epi32(out[1], 8), out[0]));
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + rowOffset + x), res);
        }

        if (x < clipRight) {
            applyArithmeticScalar(src1, src2, dst, width, x, y, clipRight, y + 1, k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
    }
}

} // extern "C"

#endif
