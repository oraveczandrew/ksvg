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
#include <cstdint>

#if defined(__i386__) || defined(__x86_64__)
#include <immintrin.h>

namespace {

// One 16-byte LUT row duplicated into both AVX2 128-bit lanes so the per-lane
// pshufb selects correctly for every byte of the 32-byte register.
inline __m256i lutRowBroadcast256(const jbyte* table, int row) {
    const __m128i v = _mm_loadu_si128(
            reinterpret_cast<const __m128i*>(table + row * 16));
    return _mm256_broadcastsi128_si256(v);
}

// Genuinely vectorized 256-entry LUT lookup over the 32 bytes (8 pixels) of an
// AVX2 register using the 16-row pshufb scheme (entry = rows[hi][lo]). Because
// every byte is looked up in the SAME table, the whole register is transformed
// in one pass — no channel plane extraction or re-interleaving needed.
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

void ksvgUnlinearizeApplyAvx2(
        const jint* src, jint* dst, int width, int height, const jbyte* table) {
    const int total = width * height;

    // rows[i] = table[i*16..i*16+15] duplicated into both AVX2 lanes.
    __m256i rows[16];
    for (int i = 0; i < 16; ++i) {
        rows[i] = lutRowBroadcast256(table, i);
    }

    // 0xff in the alpha byte positions (offset 3, 7, 11, 15, 19, 23, 27, 31),
    // i.e. one per pixel across the 8 pixels of the 32-byte register.
    const __m256i alphaMaskBytes = _mm256_setr_epi8(
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1);

    int i = 0;
    for (; i + 8 <= total; i += 8) {
        const __m256i p = _mm256_loadu_si256(
                reinterpret_cast<const __m256i*>(src + i));

        // Every byte (B/G/R/A) is mapped by the shared LUT in one pass.
        const __m256i transformed = lut256Avx2(p, rows);

        // Restore the original alpha bytes (their transformed value is discarded).
        const __m256i out = _mm256_or_si256(
                _mm256_andnot_si256(alphaMaskBytes, transformed),
                _mm256_and_si256(alphaMaskBytes, p));

        _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + i), out);
    }

    // Scalar tail for the remainder that does not fit the SIMD width.
    for (; i < total; ++i) {
        const jint c = src[i];
        dst[i] = (c & 0xff000000) |
                 (static_cast<jint>(static_cast<uint8_t>(table[(c >> 16) & 0xff])) << 16) |
                 (static_cast<jint>(static_cast<uint8_t>(table[(c >> 8) & 0xff])) << 8) |
                 static_cast<jint>(static_cast<uint8_t>(table[c & 0xff]));
    }
}

} // extern "C"

#endif
