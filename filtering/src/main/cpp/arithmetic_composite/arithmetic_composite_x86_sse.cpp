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

#if defined(__i386__) || defined(__x86_64__)
#include <immintrin.h>
#endif
#include <algorithm>
#include "arithmetic_composite.h"
#include "srgb_lut.h"
#include "simd_x86.h"

#if defined(__i386__) || defined(__x86_64__)

namespace {

inline __m128i extractChannelSSSE3(__m128i pixels4, int lane) {
    return _mm_shuffle_epi8(pixels4, _mm_setr_epi8(
            static_cast<char>(lane), static_cast<char>(lane + 4),
            static_cast<char>(lane + 8), static_cast<char>(lane + 12),
            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1));
}

inline __m128i applyArithmeticFormulaSsse3(
    __m128i in1, __m128i in2,
    float k1, float k2, float k3, float k4_255) {

    __m128i zero = _mm_setzero_si128();
    auto to_float = [&](__m128i b) {
        return _mm_cvtepi32_ps(_mm_unpacklo_epi16(_mm_unpacklo_epi8(b, zero), zero));
    };

    __m128 f1 = to_float(in1);
    __m128 f2 = to_float(in2);

    // res = k1*in1*in2/255 + k2*in1 + k3*in2 + k4*255
    __m128 res = _mm_mul_ps(_mm_mul_ps(f1, f2), _mm_set1_ps(k1 / 255.0f));
    res = _mm_add_ps(res, _mm_mul_ps(f1, _mm_set1_ps(k2)));
    res = _mm_add_ps(res, _mm_mul_ps(f2, _mm_set1_ps(k3)));
    res = _mm_add_ps(res, _mm_set1_ps(k4_255 + 0.5f));

    __m128i i = _mm_cvttps_epi32(res);
    // pack back to 4 bytes in lane 0-3.
    // _mm_packs_epi32: signed saturation i32 -> i16
    // _mm_packus_epi16: unsigned saturation i16 -> u8
    __m128i p16 = _mm_packs_epi32(i, zero);
    return _mm_packus_epi16(p16, zero);
}

} // namespace

extern "C" {

void ksvgArithmeticApplySse(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb) {

    __m128i tS2L[16], tL2S[16];
    if (useLinear) {
        for (int i = 0; i < 16; i++) {
            tS2L[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(srgbToLinear + i * 16));
            tL2S[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(linearToSrgb + i * 16));
        }
    }

    const float k4_255 = k4 * 255.0f;

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        for (; x + 4 <= clipRight; x += 4) {
            __m128i p1 = _mm_loadu_si128(reinterpret_cast<const __m128i*>(src1 + rowOffset + x));
            __m128i p2 = _mm_loadu_si128(reinterpret_cast<const __m128i*>(src2 + rowOffset + x));

            __m128i c1[4], c2[4], out[4];
            for (int i = 0; i < 4; i++) {
                c1[i] = extractChannelSSSE3(p1, i);
                c2[i] = extractChannelSSSE3(p2, i);
            }

            // Alpha (lane 3)
            out[3] = applyArithmeticFormulaSsse3(c1[3], c2[3], k1, k2, k3, k4_255);

            if (useLinear) {
                for (int i = 0; i < 3; i++) {
                    __m128i l1 = lookup256Ssse3(tS2L, c1[i]);
                    __m128i l2 = lookup256Ssse3(tS2L, c2[i]);
                    __m128i res = applyArithmeticFormulaSsse3(l1, l2, k1, k2, k3, k4_255);
                    out[i] = lookup256Ssse3(tL2S, res);
                }
            } else {
                for (int i = 0; i < 3; i++) {
                    out[i] = applyArithmeticFormulaSsse3(c1[i], c2[i], k1, k2, k3, k4_255);
                }
            }

            // Interleave back
            __m128i bg = _mm_unpacklo_epi8(out[0], out[1]);
            __m128i ra = _mm_unpacklo_epi8(out[2], out[3]);
            __m128i result = _mm_unpacklo_epi16(bg, ra);
            _mm_storeu_si128(reinterpret_cast<__m128i*>(dst + rowOffset + x), result);
        }
        if (x < clipRight) {
            applyArithmeticScalar(src1, src2, dst, width, x, y, clipRight, y + 1, k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
    }
}

} // extern "C"

#endif
