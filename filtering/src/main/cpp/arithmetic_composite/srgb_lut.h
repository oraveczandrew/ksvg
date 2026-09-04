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

#pragma once

#include <cstdint>

#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
#include <arm_neon.h>

#ifdef __aarch64__

inline uint8x16_t lookup256Neon64(
        uint8x16_t indices,
        const uint8x16_t table[16]) {

    const uint8x16_t zero = vdupq_n_u8(0);

    const uint8x16x4_t t0 = {
        table[0], table[1], table[2], table[3]
    };
    const uint8x16x4_t t1 = {
        table[4], table[5], table[6], table[7]
    };
    const uint8x16x4_t t2 = {
        table[8], table[9], table[10], table[11]
    };
    const uint8x16x4_t t3 = {
        table[12], table[13], table[14], table[15]
    };

    uint8x16_t result = vqtbx4q_u8(
        zero,
        t0,
        indices
    );

    result = vqtbx4q_u8(
        result,
        t1,
        vsubq_u8(indices, vdupq_n_u8(64))
    );

    result = vqtbx4q_u8(
        result,
        t2,
        vsubq_u8(indices, vdupq_n_u8(128))
    );

    result = vqtbx4q_u8(
        result,
        t3,
        vsubq_u8(indices, vdupq_n_u8(192))
    );

    return result;
}
#endif

#ifndef __aarch64__
inline uint8x8_t lookup256Neon32(uint8x8_t indices, const uint8_t* table) {
    uint8x8_t result = vdup_n_u8(0);
    uint8x8x4_t t;

    t = vld1_u8_x4(table + 0);
    result = vtbx4_u8(result, t, indices);

    t = vld1_u8_x4(table + 32);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(32)));

    t = vld1_u8_x4(table + 64);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(64)));

    t = vld1_u8_x4(table + 96);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(96)));

    t = vld1_u8_x4(table + 128);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(128)));

    t = vld1_u8_x4(table + 160);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(160)));

    t = vld1_u8_x4(table + 192);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(192)));

    t = vld1_u8_x4(table + 224);
    result = vtbx4_u8(result, t, vsub_u8(indices, vdup_n_u8(224)));

    return result;
}
#endif
#endif

#if defined(__SSSE3__)
#include <tmmintrin.h>

inline __m128i lookup256Ssse3(const __m128i table[16], __m128i indices) {
    const __m128i loMask = _mm_set1_epi8(0x0F);
    const __m128i lo = _mm_and_si128(indices, loMask);
    const __m128i hi = _mm_and_si128(_mm_srli_epi16(indices, 4), loMask);
    __m128i result = _mm_setzero_si128();
    for (int i = 0; i < 16; i++) {
        const __m128i candidate = _mm_shuffle_epi8(table[i], lo);
        const __m128i sel = _mm_cmpeq_epi8(hi, _mm_set1_epi8(static_cast<char>(i)));
        result = _mm_or_si128(result, _mm_and_si128(candidate, sel));
    }
    return result;
}
#endif
