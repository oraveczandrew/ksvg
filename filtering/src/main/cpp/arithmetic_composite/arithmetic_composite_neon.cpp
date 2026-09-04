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

#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
#include <arm_neon.h>
#include <algorithm>
#include "arithmetic_composite.h"
#include "srgb_lut.h"

namespace {

#ifdef __aarch64__
inline float32x4_t computeChannelNeon64(uint8x16_t c1, uint8x16_t c2,
                                       float32x4_t k1, float32x4_t k2, float32x4_t k3, float32x4_t k4_255,
                                       int lane) {
    // Extract 4 bytes from lane (0, 1, 2, 3) to float32x4
    // We only process 4 pixels at a time for simplicity in FMA loop
    uint32x4_t p1 = vmovl_u16(vget_low_u16(vmovl_u8(vget_low_u8(c1))));
    // Actually vld4q_u8 already gives us planes.
    // If we use vld4q_u8, c1 is already a plane of 16 bytes.
    // We take the first 4 bytes for one iteration.
    // But it's better to process all 16 bytes if possible.
    // However, k values are scalar floats.
    // Let's process 4 pixels at a time (16 bytes total for 4 channels, but we have planes).
    // If we have 16 pixels per vld4q_u8, we have 4 iterations of 4 pixels.

    (void)c1; (void)c2; (void)k1; (void)k2; (void)k3; (void)k4_255; (void)lane;
    return vdupq_n_f32(0); // placeholder
}
#endif

// More efficient: process all 16 pixels from vld4q_u8.
// Since we have 4 float32x4 in 16 pixels, we can loop 4 times.

#ifdef __aarch64__
inline uint8x16_t applyArithmeticFormulaNeon64(
    uint8x16_t in1, uint8x16_t in2,
    float k1, float k2, float k3, float k4_255) {

    // We need to convert u8 to f32. 16 bytes -> four float32x4.
    uint16x8_t low_u16 = vmovl_u8(vget_low_u8(in1));
    uint16x8_t high_u16 = vmovl_u8(vget_high_u8(in1));
    float32x4_t in1_0 = vcvtq_f32_u32(vmovl_u16(vget_low_u16(low_u16)));
    float32x4_t in1_1 = vcvtq_f32_u32(vmovl_u16(vget_high_u16(low_u16)));
    float32x4_t in1_2 = vcvtq_f32_u32(vmovl_u16(vget_low_u16(high_u16)));
    float32x4_t in1_3 = vcvtq_f32_u32(vmovl_u16(vget_high_u16(high_u16)));

    low_u16 = vmovl_u8(vget_low_u8(in2));
    high_u16 = vmovl_u8(vget_high_u8(in2));
    float32x4_t in2_0 = vcvtq_f32_u32(vmovl_u16(vget_low_u16(low_u16)));
    float32x4_t in2_1 = vcvtq_f32_u32(vmovl_u16(vget_high_u16(low_u16)));
    float32x4_t in2_2 = vcvtq_f32_u32(vmovl_u16(vget_low_u16(high_u16)));
    float32x4_t in2_3 = vcvtq_f32_u32(vmovl_u16(vget_high_u16(high_u16)));

    // result = (k1 * a * b + k2 * a + k3 * b + k4) * 255
    // a = in1/255, b = in2/255
    // result = k1*in1*in2/255 + k2*in1 + k3*in2 + k4*255
    float k1_div_255 = k1 / 255.0f;

    auto compute = [&](float32x4_t a, float32x4_t b) {
        float32x4_t res = vmulq_n_f32(vmulq_f32(a, b), k1_div_255);
        res = vfmaq_n_f32(res, a, k2);
        res = vfmaq_n_f32(res, b, k3);
        res = vaddq_f32(res, vdupq_n_f32(k4_255));
        // Round to nearest: use vcvtnq_u32_f32 or vaddq_f32(0.5) + vcvtq_u32_f32
        // SVG spec says floor(v + 0.5)
        res = vaddq_f32(res, vdupq_n_f32(0.5f));
        return vqmovn_u32(vcvtq_u32_f32(res)); // u32x4 -> u16x4
    };

    uint16x4_t r0 = compute(in1_0, in2_0);
    uint16x4_t r1 = compute(in1_1, in2_1);
    uint16x4_t r2 = compute(in1_2, in2_2);
    uint16x4_t r3 = compute(in1_3, in2_3);

    return vcombine_u8(vqmovn_u16(vcombine_u16(r0, r1)), vqmovn_u16(vcombine_u16(r2, r3)));
}
#endif

#ifndef __aarch64__
// NEON32 version: 8 pixels per iteration
inline uint8x8_t applyArithmeticFormulaNeon32(
    uint8x8_t in1, uint8x8_t in2,
    float k1, float k2, float k3, float k4_255) {

    uint16x8_t in1_u16 = vmovl_u8(in1);
    float32x4_t in1_0 = vcvtq_f32_u32(vmovl_u16(vget_low_u16(in1_u16)));
    float32x4_t in1_1 = vcvtq_f32_u32(vmovl_u16(vget_high_u16(in1_u16)));

    uint16x8_t in2_u16 = vmovl_u8(in2);
    float32x4_t in2_0 = vcvtq_f32_u32(vmovl_u16(vget_low_u16(in2_u16)));
    float32x4_t in2_1 = vcvtq_f32_u32(vmovl_u16(vget_high_u16(in2_u16)));

    float k1_div_255 = k1 / 255.0f;

    auto compute = [&](float32x4_t a, float32x4_t b) {
        float32x4_t res = vmulq_n_f32(vmulq_f32(a, b), k1_div_255);
        res = vmlaq_n_f32(res, a, k2);
        res = vmlaq_n_f32(res, b, k3);
        res = vaddq_f32(res, vdupq_n_f32(k4_255 + 0.5f));
        return vqmovn_u32(vcvtq_u32_f32(res));
    };

    uint16x4_t r0 = compute(in1_0, in2_0);
    uint16x4_t r1 = compute(in1_1, in2_1);

    return vqmovn_u16(vcombine_u16(r0, r1));
}
#endif

} // namespace

void applyArithmeticNeon(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb) {

#ifdef __aarch64__
    uint8x16_t tS2L[16], tL2S[16];
    if (useLinear) {
        for (int i = 0; i < 16; i++) {
            tS2L[i] = vld1q_u8(reinterpret_cast<const uint8_t*>(srgbToLinear) + i * 16);
            tL2S[i] = vld1q_u8(reinterpret_cast<const uint8_t*>(linearToSrgb) + i * 16);
        }
    }

    const float k4_255 = k4 * 255.0f;

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        for (; x + 16 <= clipRight; x += 16) {
            uint8x16x4_t p1 = vld4q_u8(reinterpret_cast<const uint8_t*>(src1 + rowOffset + x));
            uint8x16x4_t p2 = vld4q_u8(reinterpret_cast<const uint8_t*>(src2 + rowOffset + x));
            uint8x16x4_t out;

            // Alpha always non-linear
            out.val[3] = applyArithmeticFormulaNeon64(p1.val[3], p2.val[3], k1, k2, k3, k4_255);

            if (useLinear) {
                for (int c = 0; c < 3; c++) {
                    uint8x16_t l1 = lookup256Neon(p1.val[c], tS2L);
                    uint8x16_t l2 = lookup256Neon(p2.val[c], tS2L);
                    uint8x16_t res = applyArithmeticFormulaNeon64(l1, l2, k1, k2, k3, k4_255);
                    out.val[c] = lookup256Neon(res, tL2S);
                }
            } else {
                out.val[0] = applyArithmeticFormulaNeon64(p1.val[0], p2.val[0], k1, k2, k3, k4_255);
                out.val[1] = applyArithmeticFormulaNeon64(p1.val[1], p2.val[1], k1, k2, k3, k4_255);
                out.val[2] = applyArithmeticFormulaNeon64(p1.val[2], p2.val[2], k1, k2, k3, k4_255);
            }

            vst4q_u8(reinterpret_cast<uint8_t*>(dst + rowOffset + x), out);
        }
        // Fallback to scalar for remainder
        if (x < clipRight) {
            applyArithmeticScalar(src1, src2, dst, width, x, y, clipRight, y + 1, k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
    }
#else
    // NEON32
    uint8x8x2_t tS2L[16], tL2S[16];
    if (useLinear) {
        for (int i = 0; i < 16; i++) {
            tS2L[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(srgbToLinear) + i * 16);
            tS2L[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(srgbToLinear) + i * 16 + 8);
            tL2S[i].val[0] = vld1_u8(reinterpret_cast<const uint8_t*>(linearToSrgb) + i * 16);
            tL2S[i].val[1] = vld1_u8(reinterpret_cast<const uint8_t*>(linearToSrgb) + i * 16 + 8);
        }
    }

    const float k4_255 = k4 * 255.0f;

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        for (; x + 8 <= clipRight; x += 8) {
            uint8x8x4_t p1 = vld4_u8(reinterpret_cast<const uint8_t*>(src1 + rowOffset + x));
            uint8x8x4_t p2 = vld4_u8(reinterpret_cast<const uint8_t*>(src2 + rowOffset + x));
            uint8x8x4_t out;

            out.val[3] = applyArithmeticFormulaNeon32(p1.val[3], p2.val[3], k1, k2, k3, k4_255);

            if (useLinear) {
                for (int c = 0; c < 3; c++) {
                    uint8x8_t l1 = lookup256Neon32(p1.val[c], tS2L);
                    uint8x8_t l2 = lookup256Neon32(p2.val[c], tS2L);
                    uint8x8_t res = applyArithmeticFormulaNeon32(l1, l2, k1, k2, k3, k4_255);
                    out.val[c] = lookup256Neon32(res, tL2S);
                }
            } else {
                out.val[0] = applyArithmeticFormulaNeon32(p1.val[0], p2.val[0], k1, k2, k3, k4_255);
                out.val[1] = applyArithmeticFormulaNeon32(p1.val[1], p2.val[1], k1, k2, k3, k4_255);
                out.val[2] = applyArithmeticFormulaNeon32(p1.val[2], p2.val[2], k1, k2, k3, k4_255);
            }

            vst4_u8(reinterpret_cast<uint8_t*>(dst + rowOffset + x), out);
        }
        if (x < clipRight) {
            applyArithmeticScalar(src1, src2, dst, width, x, y, clipRight, y + 1, k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
    }
#endif
}
#endif
