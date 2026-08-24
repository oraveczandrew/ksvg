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
#include <cstring>

// feComponentTransfer kernel over unpremultiplied ARGB_8888 IntArrays.
//
// All transfer math (table/discrete/linear/gamma, including any sRGB<->linearRGB
// folding) is precomputed by Kotlin into four 256-entry byte tables, one per
// ARGB channel. The kernel performs per-pixel table gathers over the clip
// region; pixels outside it become transparent black (bit-exact with the old
// pure-Kotlin `outPixels.fill(0)` semantics).
//
// jint 0xAARRGGBB is stored little-endian as bytes [BB GG RR AA], so byte
// lane 0 mod 4 is blue and lane 3 mod 4 is alpha everywhere below.
//
// Acceleration:
//  - AArch64: NEON, 16 px/iteration, vld4q/vqtbl4q against the full 256-entry
//    tables. Pure permutation — bit-exact with scalar.
//  - x86 (SSSE3): 4 px/iteration, pshufb-based 16-row selection scheme
//    (entry = table[hi*16+lo]). Pure byte permutation — bit-exact.
//  - armv7 (NEON): 8 px/iteration, same 16-row scheme with vtbl2_u8.
//  - Anything else: scalar reference loop.

namespace {

inline void applyScalar(
        const jint* src, jint* dst, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    const jint total = width * height;
    for (jint i = 0; i < total; i++) {
        dst[i] = 0;
    }
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jint c = src[rowOffset + x];
            dst[rowOffset + x] =
                    (static_cast<jint>(static_cast<uint8_t>(tableA[(c >> 24) & 0xFF])) << 24) |
                    (static_cast<jint>(static_cast<uint8_t>(tableR[(c >> 16) & 0xFF])) << 16) |
                    (static_cast<jint>(static_cast<uint8_t>(tableG[(c >> 8) & 0xFF])) << 8) |
                    static_cast<jint>(static_cast<uint8_t>(tableB[c & 0xFF]));
        }
    }
}

#ifdef __aarch64__
#include <arm_neon.h>

inline uint8x16x4_t loadTable(const jbyte* t) {
    uint8x16x4_t tab;
    tab.val[0] = vld1q_u8(reinterpret_cast<const uint8_t*>(t) + 0);
    tab.val[1] = vld1q_u8(reinterpret_cast<const uint8_t*>(t) + 16);
    tab.val[2] = vld1q_u8(reinterpret_cast<const uint8_t*>(t) + 32);
    tab.val[3] = vld1q_u8(reinterpret_cast<const uint8_t*>(t) + 48);
    return tab;
}

inline void applyNeonBlock(
        const jint* src, jint* dst,
        const uint8x16x4_t& tA, const uint8x16x4_t& tR,
        const uint8x16x4_t& tG, const uint8x16x4_t& tB) {
    const uint8x16x4_t pixels = vld4q_u8(reinterpret_cast<const uint8_t*>(src));
    // vld4q_u8 de-interleaves struct-of-4: val[0] = every byte 0 mod 4 (blue),
    // val[1] = green, val[2] = red, val[3] = alpha — 16 values each.
    uint8x16x4_t out;
    out.val[0] = vqtbl4q_u8(tB, pixels.val[0]);
    out.val[1] = vqtbl4q_u8(tG, pixels.val[1]);
    out.val[2] = vqtbl4q_u8(tR, pixels.val[2]);
    out.val[3] = vqtbl4q_u8(tA, pixels.val[3]);
    vst4q_u8(reinterpret_cast<uint8_t*>(dst), out);
}

void applyNeon64(
        jint* src, jint* dst, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    const jint total = width * height;

    const uint32x4_t zero = vdupq_n_u32(0);
    jint i = 0;
    for (; i + 4 <= total; i += 4) {
        vst1q_u32(reinterpret_cast<uint32_t*>(dst) + i, zero);
    }
    for (; i < total; i++) {
        dst[i] = 0;
    }

    const uint8x16x4_t tA = loadTable(tableA);
    const uint8x16x4_t tR = loadTable(tableR);
    const uint8x16x4_t tG = loadTable(tableG);
    const uint8x16x4_t tB = loadTable(tableB);

    const bool fullRow = clipLeft == 0 && clipRight == width;
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        if (fullRow) {
            for (; x + 16 <= width; x += 16) {
                applyNeonBlock(src + rowOffset + x, dst + rowOffset + x, tA, tR, tG, tB);
            }
        }
        for (; x < clipRight; x++) {
            const jint c = src[rowOffset + x];
            dst[rowOffset + x] =
                    (static_cast<jint>(static_cast<uint8_t>(tableA[(c >> 24) & 0xFF])) << 24) |
                    (static_cast<jint>(static_cast<uint8_t>(tableR[(c >> 16) & 0xFF])) << 16) |
                    (static_cast<jint>(static_cast<uint8_t>(tableG[(c >> 8) & 0xFF])) << 8) |
                    static_cast<jint>(static_cast<uint8_t>(tableB[c & 0xFF]));
        }
    }
}
#endif // __aarch64__

#if defined(__SSSE3__)
#include <tmmintrin.h>

/**
 * 256-entry LUT gather over the 16 bytes of `valueBytes` using pshufb.
 * The table's natural row-major layout means entry = rows[hi][lo], so for
 * each high-nibble value i we select candidates with one shuffle and mask
 * them in with cmpeq. Pure byte permutation — bit-exact with scalar.
 */
inline __m128i lutGatherSSSE3(const __m128i* rows, __m128i valueBytes) {
    const __m128i loMask = _mm_set1_epi8(0x0F);
    const __m128i lo = _mm_and_si128(valueBytes, loMask);
    const __m128i hi = _mm_and_si128(_mm_srli_epi16(valueBytes, 4), loMask);
    __m128i result = _mm_setzero_si128();
    for (int i = 0; i < 16; i++) {
        const __m128i candidate = _mm_shuffle_epi8(_mm_loadu_si128(rows + i), lo);
        const __m128i sel = _mm_cmpeq_epi8(hi, _mm_set1_epi8(static_cast<char>(i)));
        result = _mm_or_si128(result, _mm_and_si128(candidate, sel));
    }
    return result;
}

inline __m128i extractChannelSSSE3(__m128i pixels4, int lane) {
    // Pick the byte at position lane+4k of pixel k into byte k.
    return _mm_shuffle_epi8(pixels4, _mm_set_epi8(
            static_cast<char>(0x80), static_cast<char>(0x80), static_cast<char>(0x80),
            static_cast<char>(lane + 12),
            static_cast<char>(0x80), static_cast<char>(0x80), static_cast<char>(0x80),
            static_cast<char>(lane + 8),
            static_cast<char>(0x80), static_cast<char>(0x80), static_cast<char>(0x80),
            static_cast<char>(lane + 4),
            static_cast<char>(0x80), static_cast<char>(0x80), static_cast<char>(0x80),
            static_cast<char>(lane)));
}

void applySsse3(
        jint* src, jint* dst, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    alignas(16) __m128i rowsA[16], rowsR[16], rowsG[16], rowsB[16];
    for (int i = 0; i < 16; i++) {
        rowsA[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableA + i * 16));
        rowsR[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableR + i * 16));
        rowsG[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableG + i * 16));
        rowsB[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableB + i * 16));
    }

    std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        for (; x + 4 <= clipRight; x += 4) {
            const __m128i pixels4 = _mm_loadu_si128(
                    reinterpret_cast<const __m128i*>(src + rowOffset + x));
            const __m128i outB = lutGatherSSSE3(rowsB, extractChannelSSSE3(pixels4, 0));
            const __m128i outG = lutGatherSSSE3(rowsG, extractChannelSSSE3(pixels4, 1));
            const __m128i outR = lutGatherSSSE3(rowsR, extractChannelSSSE3(pixels4, 2));
            const __m128i outA = lutGatherSSSE3(rowsA, extractChannelSSSE3(pixels4, 3));
            // Interleave back to [B,G,R,A] byte order: two 2-pixel ints in lo,
            // two in hi.
            const __m128i bg = _mm_unpacklo_epi8(outB, outG);
            const __m128i ra = _mm_unpacklo_epi8(outR, outA);
            const __m128i lo = _mm_unpacklo_epi16(bg, ra);
            const __m128i hi = _mm_unpackhi_epi16(bg, ra);
            _mm_storel_epi64(reinterpret_cast<__m128i*>(dst + rowOffset + x), lo);
            _mm_storeh_pi(reinterpret_cast<__m64*>(dst + rowOffset + x + 2),
                          _mm_castsi128_ps(hi));
        }
        for (; x < clipRight; x++) {
            const jint c = src[rowOffset + x];
            dst[rowOffset + x] =
                    (static_cast<jint>(static_cast<uint8_t>(tableA[(c >> 24) & 0xFF])) << 24) |
                    (static_cast<jint>(static_cast<uint8_t>(tableR[(c >> 16) & 0xFF])) << 16) |
                    (static_cast<jint>(static_cast<uint8_t>(tableG[(c >> 8) & 0xFF])) << 8) |
                    static_cast<jint>(static_cast<uint8_t>(tableB[c & 0xFF]));
        }
    }
}
#endif // __SSSE3__

#if defined(__ARM_NEON__) || defined(__ARM_NEON)
#ifndef __aarch64__
#include <arm_neon.h>

/**
 * armv7 NEON: 16-row selection scheme with vtbl2_u8 (a 16-entry row spans two
 * d-registers exactly). 8 pixels per iteration on full-width rows.
 */
inline uint8x8_t lutLookupNeon32(const uint8x8x2_t rows[16], uint8x8_t indices) {
    const uint8x8_t loMask = vdup_n_u8(0x0F);
    const uint8x8_t lo = vand_u8(indices, loMask);
    const uint8x8_t hi = vand_u8(vshr_n_u8(indices, 4), loMask);
    uint8x8_t result = vdup_n_u8(0);
    for (int i = 0; i < 16; i++) {
        // Indices are guaranteed < 16, so vtbl2 never produces zeros here.
        const uint8x8_t candidate = vtbl2_u8(rows[i], lo);
        const uint8x8_t sel = vceq_u8(hi, vdup_n_u8(static_cast<uint8_t>(i)));
        result = vorr_u8(result, vand_u8(candidate, sel));
    }
    return result;
}

void applyNeon32(
        jint* src, jint* dst, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    const jint total = width * height;
    for (jint i = 0; i < total; i++) dst[i] = 0;

    uint8x8x2_t rowsA[16], rowsR[16], rowsG[16], rowsB[16];
    for (int i = 0; i < 16; i++) {
        rowsA[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(tableA) + i * 16);
        rowsA[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(tableA) + i * 16 + 8);
        rowsR[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(tableR) + i * 16);
        rowsR[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(tableR) + i * 16 + 8);
        rowsG[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(tableG) + i * 16);
        rowsG[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(tableG) + i * 16 + 8);
        rowsB[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(tableB) + i * 16);
        rowsB[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(tableB) + i * 16 + 8);
    }

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        if (clipLeft == 0 && clipRight == width) {
            jint x = 0;
            for (; x + 8 <= width; x += 8) {
                // vld4_u8 de-interleaves 32 bytes (8 pixels) into 8-byte lanes.
                const uint8x8x4_t px = vld4_u8(reinterpret_cast<const uint8_t*>(src + rowOffset + x));
                uint8x8x4_t out;
                out.val[0] = lutLookupNeon32(rowsB, px.val[0]);
                out.val[1] = lutLookupNeon32(rowsG, px.val[1]);
                out.val[2] = lutLookupNeon32(rowsR, px.val[2]);
                out.val[3] = lutLookupNeon32(rowsA, px.val[3]);
                vst4_u8(reinterpret_cast<uint8_t*>(dst + rowOffset + x), out);
            }
            for (; x < width; x++) {
                const jint c = src[rowOffset + x];
                dst[rowOffset + x] =
                        (static_cast<jint>(static_cast<uint8_t>(tableA[(c >> 24) & 0xFF])) << 24) |
                        (static_cast<jint>(static_cast<uint8_t>(tableR[(c >> 16) & 0xFF])) << 16) |
                        (static_cast<jint>(static_cast<uint8_t>(tableG[(c >> 8) & 0xFF])) << 8) |
                        static_cast<jint>(static_cast<uint8_t>(tableB[c & 0xFF]));
            }
        } else {
            for (jint x = clipLeft; x < clipRight; x++) {
                const jint c = src[rowOffset + x];
                dst[rowOffset + x] =
                        (static_cast<jint>(static_cast<uint8_t>(tableA[(c >> 24) & 0xFF])) << 24) |
                        (static_cast<jint>(static_cast<uint8_t>(tableR[(c >> 16) & 0xFF])) << 16) |
                        (static_cast<jint>(static_cast<uint8_t>(tableG[(c >> 8) & 0xFF])) << 8) |
                        static_cast<jint>(static_cast<uint8_t>(tableB[c & 0xFF]));
            }
        }
    }
}
#endif // !__aarch64__
#endif // ARM NEON

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ComponentTransferNative_apply(
        JNIEnv* env, jclass clazz,
        jintArray jSrc, jintArray jDst,
        jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jbyteArray jTableA, jbyteArray jTableR, jbyteArray jTableG, jbyteArray jTableB) {
    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) return;
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    auto* tableA = env->GetByteArrayElements(jTableA, nullptr);
    auto* tableR = env->GetByteArrayElements(jTableR, nullptr);
    auto* tableG = env->GetByteArrayElements(jTableG, nullptr);
    auto* tableB = env->GetByteArrayElements(jTableB, nullptr);
    if (dst == nullptr || tableA == nullptr || tableR == nullptr ||
        tableG == nullptr || tableB == nullptr) {
        if (src != nullptr) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        return;
    }

#if defined(__aarch64__)
    applyNeon64(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);
#elif defined(__SSSE3__)
    applySsse3(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
               tableA, tableR, tableG, tableB);
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    applyNeon32(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);
#else
    applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);
#endif

    env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
