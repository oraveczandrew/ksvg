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
// Acceleration:
//  - AArch64: NEON path processes 16 pixels/iteration using vqtbl4q_u8 against
//    the full 256-entry tables (channel extraction and BGRA re-packing via
//    constant-selector table lookups + vzip). Pure permutation/lookup work —
//    no floating point, therefore trivially bit-exact with the scalar path.
//  - Everything else (armv7, x86, x86_64): scalar reference loop.

namespace {

void applyScalar(
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

/**
 * Processes 16 whole pixels (64 bytes). jint 0xAARRGGBB is stored
 * little-endian as bytes [BB GG RR AA], so the per-lane channel selectors
 * below pick B/G/R/A bytes; results are re-packed in the same order.
 */
inline void applyNeonBlock(
        const jint* src, jint* dst,
        const uint8x16x4_t& tA, const uint8x16x4_t& tR,
        const uint8x16x4_t& tG, const uint8x16x4_t& tB) {
    const auto* p = reinterpret_cast<const uint8_t*>(src);
    const uint8x16x4_t pixels = vld4q_u8(p);
    // vld4q_u8 de-interleaves struct-of-4: val[0]=every byte 0 mod 4 (B bytes),
    // val[1]=G bytes, val[2]=R bytes, val[3]=A bytes — 16 values each.
    const uint8x16_t outB = vqtbl4q_u8(tB, pixels.val[0]);
    const uint8x16_t outG = vqtbl4q_u8(tG, pixels.val[1]);
    const uint8x16_t outR = vqtbl4q_u8(tR, pixels.val[2]);
    const uint8x16_t outA = vqtbl4q_u8(tA, pixels.val[3]);

    uint8x16x4_t out;
    out.val[0] = outB;
    out.val[1] = outG;
    out.val[2] = outR;
    out.val[3] = outA;
    vst4q_u8(reinterpret_cast<uint8_t*>(dst), out);
}

void applyNeon(
        jint* src, jint* dst, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    const jint total = width * height;

    // Transparent outside the clip (vector fill).
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

    // Full-width rows go through the vector block path; partial-width edge
    // rows fall back to the scalar tail.
    const bool fullRow = clipLeft == 0 && clipRight == width;
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        if (fullRow) {
            jint x = 0;
            for (; x + 16 <= width; x += 16) {
                applyNeonBlock(src + rowOffset + x, dst + rowOffset + x, tA, tR, tG, tB);
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

#endif // __aarch64__

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

#ifdef __aarch64__
    applyNeon(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
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
