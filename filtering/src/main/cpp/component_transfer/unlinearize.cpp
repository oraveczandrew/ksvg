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
#include <cassert>
#include "cpu_dispatch.h"
#include "simd_x86.h"
#include "color_luts.h"

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
//  - x86-64 (AVX2): 8 px/iteration, 16-row pshufb scheme over a full 32-byte
//    register with alpha restored by masking. Pure byte permutation — bit-exact
//    for any caller table.
//  - x86-64 (SSSE3): the bit-exact integer approximation of the production
//    sRGB LUT (exact to the std-table byte map; scalar tail reads the caller
//    table).
//  - x86-32 (SSSE3/AVX2): bit-exact production-table approximations
//    (ksvgUnlinearizeApplySsse3ApproxV31 / ksvgUnlinearizeApplyAvx2ApproxV26).
//  - Anything else: scalar reference loop.
//
// The LUT-cascade SIMD paths (SSSE3/NEON16-row) lose to the alias-free scalar
// loop per WP3 (see REGRESSION_FIX_WORKLOG.md); production keeps only the
// approximation kernels on x86. The applyNeon64/applyNeon32/reference paths stay
// compiled and reachable via Java_..._applyForced for validation.

namespace {

void applyScalar(const jint* src, jint* dst, const jint width, const jint height) {
    const jint total = width * height;
    for (jint i = 0; i < total; i++) {
        const jint c = src[i];
        dst[i] = (c & 0xFF000000) /* alpha passthrough */ |
                (static_cast<jint>(ksvg_linear_to_srgb_lut[(c >> 16) & 0xFF]) << 16) |
                (static_cast<jint>(ksvg_linear_to_srgb_lut[(c >> 8) & 0xFF]) << 8) |
                static_cast<jint>(ksvg_linear_to_srgb_lut[c & 0xFF]);
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
uint8x16_t lutLookupNeon64(const uint8x16_t* rows, const uint8x16_t indices) {
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
#if defined(__x86_64__)
extern "C" void ksvgUnlinearizeApplySsse3(
        jint* src, jint* dst, jint width, jint height, const jbyte* table);
#else
extern "C" void ksvgUnlinearizeApplySsse3ApproxV31(
        jint* src, jint* dst, jint width, jint height, const jbyte* table);
extern "C" void ksvgUnlinearizeApplyAvx2ApproxV26(
        jint* src, jint* dst, jint width, jint height, const jbyte* table);
#endif
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

// Validation/test-only: run an explicitly selected backend (see SimdBackend).
// The normal production path (Java_..._UnlinearizeNative_apply) never calls
// this; on x86 the backend ids also let a test route to a lower ISA than the
// CPU's highest for independent validation. On the ARM ABIs the only valid
// backend is the one compiled for the ABI, so anything else is an assertion
// failure (debug builds) rather than a silent wrong path.
namespace {

void runForced(jint* src, jint* dst, jint width, jint height, const jint backend) {
    const auto* table = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
#if defined(__aarch64__)
    if (backend == SIMD_BACKEND_SCALAR) {
        applyScalar(src, dst, width, height);
    } else {
        assert(backend == SIMD_BACKEND_NEON64);
        applyNeon64(src, dst, width, height, table);
    }
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    if (backend == SIMD_BACKEND_SCALAR) {
        applyScalar(src, dst, width, height);
    } else {
        assert(backend == SIMD_BACKEND_NEON32);
        applyNeon32(src, dst, width, height, table);
    }
#elif defined(__SSSE3__)
    switch (backend) {
        case SIMD_BACKEND_SCALAR: applyScalar(src, dst, width, height); break;
        case SIMD_BACKEND_SSSE3:
#if defined(__x86_64__)
            ksvgUnlinearizeApplySsse3(src, dst, width, height, table);
#else
            ksvgUnlinearizeApplySsse3ApproxV31(src, dst, width, height, table);
#endif
            break;
        case SIMD_BACKEND_AVX2:
#if defined(__x86_64__)
            ksvgUnlinearizeApplyAvx2(src, dst, width, height, table);
#else
            ksvgUnlinearizeApplyAvx2ApproxV26(src, dst, width, height, table);
#endif
            break;
        default:                  assert(false && "unsupported forced unlinearize backend on x86");
    }
#else
    (void)backend;
    applyScalar(src, dst, width, height);
#endif
}

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__SSSE3__) && (defined(__x86_64__) || defined(__i386__))
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_SSSE3) {
        backends |= SIMD_BACKEND_SSSE3;
    }
    if (level >= SIMD_AVX2) {
        backends |= SIMD_BACKEND_AVX2;
    }
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_UnLinearizeNative_nativeBackend(
    [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_UnLinearizeNative_applyForced(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jint simdBackend) {
    const bool inPlace = env->IsSameObject(jSrc, jDst) == JNI_TRUE;
    if (inPlace) {
        auto* buf = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
        if (buf == nullptr) {
            return;
        }
        runForced(buf, buf, width, height, simdBackend);
        env->ReleasePrimitiveArrayCritical(jSrc, buf, 0);
        return;
    }

    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        return;
    }

    runForced(src, dst, width, height, simdBackend);

    env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_UnLinearizeNative_apply(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height) {
    const auto* table = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
    if (env->IsSameObject(jSrc, jDst) == JNI_TRUE) {
        auto* buf = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
        if (buf == nullptr) {
            return;
        }
#if defined(__SSSE3__)
        const SimdLevel level = detectSimdLevel();
        if (level >= SIMD_AVX2) {
#if defined(__x86_64__)
            ksvgUnlinearizeApplyAvx2(buf, buf, width, height, table);
#else
            ksvgUnlinearizeApplyAvx2ApproxV26(buf, buf, width, height, table);
#endif
        } else if (level >= SIMD_SSSE3) {
#if defined(__x86_64__)
            ksvgUnlinearizeApplySsse3(buf, buf, width, height, table);
#else
            ksvgUnlinearizeApplySsse3ApproxV31(buf, buf, width, height, table);
#endif
        } else {
            applyScalar(buf, buf, width, height);
        }
#else
        applyScalar(buf, buf, width, height);
#endif
        env->ReleasePrimitiveArrayCritical(jSrc, buf, 0);
        return;
    }

    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        return;
    }

#if defined(__SSSE3__)
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) {
#if defined(__x86_64__)
        ksvgUnlinearizeApplyAvx2(src, dst, width, height, table);
#else
        ksvgUnlinearizeApplyAvx2ApproxV26(src, dst, width, height, table);
#endif
    } else if (level >= SIMD_SSSE3) {
#if defined(__x86_64__)
        ksvgUnlinearizeApplySsse3(src, dst, width, height, table);
#else
        ksvgUnlinearizeApplySsse3ApproxV31(src, dst, width, height, table);
#endif
    } else {
        applyScalar(src, dst, width, height);
    }
#else
    applyScalar(src, dst, width, height);
#endif

    env->ReleasePrimitiveArrayCritical(jDst, dst, 0);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
