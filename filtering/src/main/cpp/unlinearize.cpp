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
#include "cpu_dispatch.h"
#include "simd_x86.h"

// Linear→sRGB (unlinearize) filter-output transfer over straight ARGB_8888
// IntArrays. This is the KSVG equivalent of librsvg's `FilterContext::into_output`
// → `unlinearize_surface`: each pixel's straight R/G/B channel is looked up in a
// single shared 256-entry byte table and alpha is passed through unchanged.
//
// jint 0xAARRGGBB is stored little-endian as bytes [BB GG RR AA], so byte
// lane 0 mod 4 is blue, lane 1 green, lane 2 red, lane 3 alpha everywhere below.
//
// The operation is a pure element-wise byte map (dst[i] depends only on src[i]),
// so src and dst may alias (in-place) — every SIMD path loads a full block into
// registers before storing it back to the same location, and the scalar tail is
// trivially in-place safe.
//
// Acceleration:
//  - AArch64: NEON, 16 px/iteration, vld4q/vst4q with a 16-row vqtbl1q_u8
//    table selection (see note vs vqtbl4q below). Pure permutation — bit-exact.
//  - x86 (SSSE3): 4 px/iteration, pshufb-based 16-row selection scheme
//    (entry = table[hi*16+lo]). Pure byte permutation — bit-exact.
//  - armv7 (NEON): 8 px/iteration, same 16-row scheme with vtbl2_u8.
//  - Anything else: scalar reference loop.

namespace {

void applyScalar(const jint* src, jint* dst, const jint width, const jint height,
                 const jbyte* table) {
    const jint total = width * height;
    for (jint i = 0; i < total; i++) {
        const jint c = src[i];
        dst[i] = (c & 0xFF000000) /* alpha passthrough */ |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 16) & 0xFF])) << 16) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 8) & 0xFF])) << 8) |
                static_cast<jint>(static_cast<uint8_t>(table[c & 0xFF]));
    }
}

#if defined(__aarch64__)
#include <arm_neon.h>

// Full 256-entry LUT lookup using the 16-row scheme: row i = table[i*16..i*16+15].
// vqtbl1q_u8 does a 16-entry lookup indexed by the low nibble; the high nibble
// selects the row via a compare-mask loop. (Note: vqtbl4q_u8/vld4q-style single
// wide tables only address 64 entries, so they are NOT usable for an 8-bit input
// index — they would silently zero channels 64..255. The 16-row scheme is the
// correct byte-exact form, mirroring the x86/armv7 implementations.)
uint8x16_t lutLookupNeon64(const uint8x16_t* rows, uint8x16_t indices) {
    const uint8x16_t loMask = vdupq_n_u8(0x0F);
    const uint8x16_t lo = vandq_u8(indices, loMask);
    const uint8x16_t hi = vandq_u8(vshrq_n_u8(indices, 4), loMask);
    uint8x16_t result = vdupq_n_u8(0);
    for (int i = 0; i < 16; i++) {
        const uint8x16_t candidate = vqtbl1q_u8(rows[i], lo);
        const uint8x16_t sel = vceqq_u8(hi, vdupq_n_u8(static_cast<uint8_t>(i)));
        result = vorrq_u8(result, vandq_u8(candidate, sel));
    }
    return result;
}

void applyNeonBlock64(const jint* src, jint* dst, const uint8x16_t* rows) {
    // vld4q_u8 de-interleaves struct-of-4: val[0]=blue, val[1]=green, val[2]=red,
    // val[3]=alpha — 16 values each.
    const uint8x16x4_t pixels = vld4q_u8(reinterpret_cast<const uint8_t*>(src));
    uint8x16x4_t out;
    out.val[0] = lutLookupNeon64(rows, pixels.val[0]);
    out.val[1] = lutLookupNeon64(rows, pixels.val[1]);
    out.val[2] = lutLookupNeon64(rows, pixels.val[2]);
    out.val[3] = pixels.val[3];  // alpha passthrough
    vst4q_u8(reinterpret_cast<uint8_t*>(dst), out);
}

void applyNeon64(const jint* src, jint* dst, const jint width, const jint height,
                 const jbyte* table) {
    uint8x16_t rows[16];
    for (int i = 0; i < 16; i++) {
        rows[i] = vld1q_u8(reinterpret_cast<const uint8_t*>(table) + i * 16);
    }
    const jint total = width * height;
    jint i = 0;
    for (; i + 16 <= total; i += 16) {
        applyNeonBlock64(src + i, dst + i, rows);
    }
    for (; i < total; i++) {
        const jint c = src[i];
        dst[i] = (c & 0xFF000000) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 16) & 0xFF])) << 16) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 8) & 0xFF])) << 8) |
                static_cast<jint>(static_cast<uint8_t>(table[c & 0xFF]));
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

void applySsse3(jint* src, jint* dst, jint width, jint height, const jbyte* table) {
    alignas(16) __m128i rows[16];
    for (int i = 0; i < 16; i++) {
        rows[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(table + i * 16));
    }

    const jint total = width * height;
    jint i = 0;
    for (; i + 4 <= total; i += 4) {
        const __m128i pixels4 = _mm_loadu_si128(reinterpret_cast<const __m128i*>(src + i));
        const __m128i outB = lutGatherSSSE3(rows, extractChannelSSSE3(pixels4, 0));
        const __m128i outG = lutGatherSSSE3(rows, extractChannelSSSE3(pixels4, 1));
        const __m128i outR = lutGatherSSSE3(rows, extractChannelSSSE3(pixels4, 2));
        const __m128i outA = extractChannelSSSE3(pixels4, 3);
        // Interleave back to [B,G,R,A] byte order: two 2-pixel ints in lo, two in hi.
        const __m128i bg = _mm_unpacklo_epi8(outB, outG);
        const __m128i ra = _mm_unpacklo_epi8(outR, outA);
        const __m128i lo = _mm_unpacklo_epi16(bg, ra);
        const __m128i hi = _mm_unpackhi_epi16(bg, ra);
        _mm_storel_epi64(reinterpret_cast<__m128i*>(dst + i), lo);
        _mm_storeh_pi(reinterpret_cast<__m64*>(dst + i + 2), _mm_castsi128_ps(hi));
    }
    for (; i < total; i++) {
        const jint c = src[i];
        dst[i] = (c & 0xFF000000) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 16) & 0xFF])) << 16) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 8) & 0xFF])) << 8) |
                static_cast<jint>(static_cast<uint8_t>(table[c & 0xFF]));
    }
}
#endif // __SSSE3__

#if defined(__ARM_NEON__) || defined(__ARM_NEON)
#ifndef __aarch64__
#include <arm_neon.h>

/**
 * armv7 NEON: 16-row selection scheme with vtbl2_u8 (a 16-entry row spans two
 * d-registers exactly). 8 pixels per iteration.
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

void applyNeon32(jint* src, jint* dst, jint width, jint height, const jbyte* table) {
    uint8x8x2_t rows[16];
    for (int i = 0; i < 16; i++) {
        rows[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(table) + i * 16);
        rows[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(table) + i * 16 + 8);
    }

    const jint total = width * height;
    jint i = 0;
    for (; i + 8 <= total; i += 8) {
        // vld4_u8 de-interleaves 32 bytes (8 pixels) into 8-byte lanes.
        const uint8x8x4_t px = vld4_u8(reinterpret_cast<const uint8_t*>(src + i));
        uint8x8x4_t out;
        out.val[0] = lutLookupNeon32(rows, px.val[0]);
        out.val[1] = lutLookupNeon32(rows, px.val[1]);
        out.val[2] = lutLookupNeon32(rows, px.val[2]);
        out.val[3] = px.val[3];  // alpha passthrough
        vst4_u8(reinterpret_cast<uint8_t*>(dst + i), out);
    }
    for (; i < total; i++) {
        const jint c = src[i];
        dst[i] = (c & 0xFF000000) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 16) & 0xFF])) << 16) |
                (static_cast<jint>(static_cast<uint8_t>(table[(c >> 8) & 0xFF])) << 8) |
                static_cast<jint>(static_cast<uint8_t>(table[c & 0xFF]));
    }
}
#endif // !__aarch64__
#endif // ARM NEON

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_UnlinearizeNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jbyteArray jTable) {
    // The byte table must be fetched BEFORE entering any critical section (no
    // JNI call may occur between a GetPrimitiveArrayCritical pair).
    auto* table = env->GetByteArrayElements(jTable, nullptr);
    if (table == nullptr) {
        return;
    }
    const bool inPlace = env->IsSameObject(jSrc, jDst) == JNI_TRUE;
    if (inPlace) {
        auto* buf = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
        if (buf == nullptr) {
            env->ReleaseByteArrayElements(jTable, table, JNI_ABORT);
            return;
        }
#if defined(__aarch64__)
        applyNeon64(buf, buf, width, height, table);
#elif defined(__SSSE3__)
        if (detectSimdLevel() >= SIMD_AVX2) {
            ksvgUnlinearizeApplyAvx2(buf, buf, width, height, table);
        } else {
            applySsse3(buf, buf, width, height, table);
        }
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
        applyNeon32(buf, buf, width, height, table);
#else
        applyScalar(buf, buf, width, height, table);
#endif
        env->ReleasePrimitiveArrayCritical(jSrc, buf, JNI_ABORT);
        env->ReleaseByteArrayElements(jTable, table, JNI_ABORT);
        return;
    }

    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        env->ReleaseByteArrayElements(jTable, table, JNI_ABORT);
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleaseByteArrayElements(jTable, table, JNI_ABORT);
        return;
    }

#if defined(__aarch64__)
    applyNeon64(src, dst, width, height, table);
#elif defined(__SSSE3__)
    if (detectSimdLevel() >= SIMD_AVX2) {
        ksvgUnlinearizeApplyAvx2(dst, src, width, height, table);
    } else {
        applySsse3(src, dst, width, height, table);
    }
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    applyNeon32(src, dst, width, height, table);
#else
    applyScalar(src, dst, width, height, table);
#endif

    // Release the critical sections FIRST: every Release* call is a JNI call and
    // is forbidden while a critical get is still active.
    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
    env->ReleaseByteArrayElements(jTable, table, JNI_ABORT);
}
