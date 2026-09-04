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
inline uint8x16_t lookup256Neon(uint8x16_t indices, const uint8x16_t table[16]) {
    const uint8x16_t lo = vandq_u8(indices, vdupq_n_u8(0x0F));
    const uint8x16_t hi = vshrq_n_u8(indices, 4);
    uint8x16_t result = vdupq_n_u8(0);
    for (int row = 0; row < 16; ++row) {
        const uint8x16_t value = vqtbl1q_u8(table[row], lo);
        const uint8x16_t mask = vceqq_u8(hi, vdupq_n_u8(static_cast<uint8_t>(row)));
        result = vbslq_u8(mask, value, result);
    }
    return result;
}
#endif

#ifndef __aarch64__
inline uint8x8_t lookup256Neon32(uint8x8_t indices, const uint8x8x2_t table[16]) {
    const uint8x8_t lo = vand_u8(indices, vdup_n_u8(0x0F));
    const uint8x8_t hi = vand_u8(vshr_n_u8(indices, 4), vdup_n_u8(0x0F));
    uint8x8_t result = vdup_n_u8(0);
    for (int i = 0; i < 16; i++) {
        const uint8x8_t candidate = vtbl2_u8(table[i], lo);
        const uint8x8_t sel = vceq_u8(hi, vdup_n_u8(static_cast<uint8_t>(i)));
        result = vorr_u8(result, vand_u8(candidate, sel));
    }
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
