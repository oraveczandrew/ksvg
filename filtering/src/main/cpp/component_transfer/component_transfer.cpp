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
#include <cstring>
#include <cassert>
#include "cpu_dispatch.h"
#include "simd_x86.h"

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
//  - x86 (AVX2): wide LUT-cascade gather; pure byte permutation — bit-exact
//    with scalar.
//  - Anything else: scalar reference loop.
//
// WP3 regression gate (see REGRESSION_FIX_WORKLOG.md): the NEON64/NEON32/SSSE3
// LUT cascades lose to the plain scalar loop, so production dispatch and
// nativeBackend() keep only the AVX2 path. The NEON/SSSE3 kernels stay compiled
// and reachable via Java_..._applyForced for validation.

namespace {

 void applyScalar(
        const jint* src, jint* dst, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
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

inline uint8x16_t lookup256Neon(
        uint8x16_t indices,
        const uint8x16_t table[16]) {
    const uint8x16_t lo = vandq_u8(indices, vdupq_n_u8(0x0F));
    const uint8x16_t hi = vshrq_n_u8(indices, 4);

    uint8x16_t result = vdupq_n_u8(0);

    for (int row = 0; row < 16; ++row) {
        const uint8x16_t value = vqtbl1q_u8(table[row], lo);
        const uint8x16_t mask =
                vceqq_u8(hi, vdupq_n_u8(static_cast<uint8_t>(row)));
        result = vbslq_u8(mask, value, result);
    }

    return result;
}

inline void loadTable256(
        const jbyte* src,
        uint8x16_t table[16]) {
    const uint8_t* t = reinterpret_cast<const uint8_t*>(src);

    for (int i = 0; i < 16; ++i) {
        table[i] = vld1q_u8(t + i * 16);
    }
}

inline void applyNeonBlock(
        const jint* src,
        jint* dst,
        const uint8x16_t tableA[16],
        const uint8x16_t tableR[16],
        const uint8x16_t tableG[16],
        const uint8x16_t tableB[16]) {

    const uint8x16x4_t pixels =
            vld4q_u8(reinterpret_cast<const uint8_t*>(src));

    uint8x16x4_t out;

    out.val[0] = lookup256Neon(pixels.val[0], tableB);
    out.val[1] = lookup256Neon(pixels.val[1], tableG);
    out.val[2] = lookup256Neon(pixels.val[2], tableR);
    out.val[3] = lookup256Neon(pixels.val[3], tableA);

    vst4q_u8(reinterpret_cast<uint8_t*>(dst), out);
}

void applyNeon64(
        const jint* src,
        jint* dst,
        const jint width,
        const jint height,
        const jint clipLeft,
        const jint clipTop,
        const jint clipRight,
        const jint clipBottom,
        const jbyte* tableA,
        const jbyte* tableR,
        const jbyte* tableG,
        const jbyte* tableB) {

    const size_t total =
            static_cast<size_t>(width) * static_cast<size_t>(height);

    memset(dst, 0, total * sizeof(jint));

    uint8x16_t tA[16];
    uint8x16_t tR[16];
    uint8x16_t tG[16];
    uint8x16_t tB[16];

    loadTable256(tableA, tA);
    loadTable256(tableR, tR);
    loadTable256(tableG, tG);
    loadTable256(tableB, tB);

    for (jint y = clipTop; y < clipBottom; ++y) {
        const jint rowOffset = y * width;
        jint x = clipLeft;

        for (; x + 16 <= clipRight; x += 16) {
            applyNeonBlock(
                    src + rowOffset + x,
                    dst + rowOffset + x,
                    tA, tR, tG, tB);
        }

        for (; x < clipRight; ++x) {
            const jint c = src[rowOffset + x];

            dst[rowOffset + x] =
                    (static_cast<jint>(
                            static_cast<uint8_t>(
                                    tableA[(c >> 24) & 0xFF])) << 24) |
                    (static_cast<jint>(
                            static_cast<uint8_t>(
                                    tableR[(c >> 16) & 0xFF])) << 16) |
                    (static_cast<jint>(
                            static_cast<uint8_t>(
                                    tableG[(c >> 8) & 0xFF])) << 8) |
                    (static_cast<jint>(
                            static_cast<uint8_t>(
                                    tableB[c & 0xFF])));
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
    // Pick the byte at position lane+4k of pixel k into bytes 0, 1, 2, 3.
    return _mm_shuffle_epi8(pixels4, _mm_setr_epi8(
            static_cast<char>(lane), static_cast<char>(lane + 4),
            static_cast<char>(lane + 8), static_cast<char>(lane + 12),
            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1));
}

void applySsse3(
        const jint* src, jint* dst, jint width, jint height,
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
            const __m128i res = _mm_unpacklo_epi16(bg, ra);
            _mm_storeu_si128(reinterpret_cast<__m128i*>(dst + rowOffset + x), res);
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
        const jint* src, jint* dst, jint width, jint height,
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


// Validation/test-only: run an explicitly selected backend (see SimdBackend).
namespace {

void runForced(const jint* src, jint* dst, jint width, jint height,
               jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
               const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB,
               jint backend) {
#if defined(__aarch64__)
    if (backend == SIMD_BACKEND_SCALAR) {
        applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    tableA, tableR, tableG, tableB);
    } else {
        assert(backend == SIMD_BACKEND_NEON64);
        applyNeon64(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    tableA, tableR, tableG, tableB);
    }
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    if (backend == SIMD_BACKEND_SCALAR) {
        applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    tableA, tableR, tableG, tableB);
    } else {
        assert(backend == SIMD_BACKEND_NEON32);
        applyNeon32(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    tableA, tableR, tableG, tableB);
    }
#elif defined(__SSSE3__)
    switch (backend) {
        case SIMD_BACKEND_SCALAR:
            applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                        tableA, tableR, tableG, tableB);
            break;
        case SIMD_BACKEND_SSSE3:
            applySsse3(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                       tableA, tableR, tableG, tableB);
            break;
        case SIMD_BACKEND_AVX2:
            ksvgComponentTransferApplyAvx2(src, dst, width, height,
                clipLeft, clipTop, clipRight, clipBottom, tableA, tableR, tableG, tableB);
            break;
        default:
            assert(false && "unsupported forced component_transfer backend on x86");
    }
#else
    (void)backend;
    applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);
#endif
}

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__SSSE3__)
    if (detectSimdLevel() >= SIMD_AVX2) {
        backends |= SIMD_BACKEND_AVX2;
    }
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_ComponentTransferNative_nativeBackend(
        JNIEnv* env, jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ComponentTransferNative_applyForced(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jbyteArray jTableA, const jbyteArray jTableR, const jbyteArray jTableG, const jbyteArray jTableB,
        const jint simdBackend) {
    auto* tableA = env->GetByteArrayElements(jTableA, nullptr);
    auto* tableR = env->GetByteArrayElements(jTableR, nullptr);
    auto* tableG = env->GetByteArrayElements(jTableG, nullptr);
    auto* tableB = env->GetByteArrayElements(jTableB, nullptr);
    if (tableA == nullptr || tableR == nullptr || tableG == nullptr || tableB == nullptr) {
        return;
    }
    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
        return;
    }

    runForced(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
              tableA, tableR, tableG, tableB, simdBackend);

    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ComponentTransferNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jbyteArray jTableA, const jbyteArray jTableR, const jbyteArray jTableG, const jbyteArray jTableB) {
    // Small arrays first: no JNI call may occur between a
    // GetPrimitiveArrayCritical pair, so the byte tables must be fetched
    // BEFORE entering the critical sections.
    auto* tableA = env->GetByteArrayElements(jTableA, nullptr);
    auto* tableR = env->GetByteArrayElements(jTableR, nullptr);
    auto* tableG = env->GetByteArrayElements(jTableG, nullptr);
    auto* tableB = env->GetByteArrayElements(jTableB, nullptr);
    if (tableA == nullptr || tableR == nullptr || tableG == nullptr || tableB == nullptr) {
        return;
    }
    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
        env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
        return;
    }

#if defined(__SSSE3__)
    if (detectSimdLevel() >= SIMD_AVX2) {
        ksvgComponentTransferApplyAvx2(src, dst, width, height,
            clipLeft, clipTop, clipRight, clipBottom, tableA, tableR, tableG, tableB);
    } else {
        applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    tableA, tableR, tableG, tableB);
    }
#else
    applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);
#endif

    // Release the critical sections FIRST: every Release* call is a JNI call
    // and is forbidden while a critical get is still active.
    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
}
