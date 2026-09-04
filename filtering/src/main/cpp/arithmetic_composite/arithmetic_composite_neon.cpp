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
extern "C" void applyArithmetic64Asm(
        const uint8_t* src1, const uint8_t* src2, uint8_t* dst,
        size_t pixels, float k1_div_255, float k2, float k3, float k4_255);
#else
    extern "C" void applyArithmetic32Asm(
        const uint8_t* src1,
        const uint8_t* src2,
        uint8_t* dst,
        size_t pixels,
        const float* coeffs);
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

        if (!useLinear) {
            const jint rowPixels = clipRight - clipLeft;
            const jint simdPixels = rowPixels & ~7;
            if (simdPixels > 0) {
                applyArithmetic64Asm(
                        reinterpret_cast<const uint8_t*>(src1 + rowOffset + clipLeft),
                        reinterpret_cast<const uint8_t*>(src2 + rowOffset + clipLeft),
                        reinterpret_cast<uint8_t*>(dst + rowOffset + clipLeft),
                        static_cast<size_t>(simdPixels),
                        k1 / 255.0f, k2, k3, k4_255);
            }

            const jint scalarLeft = clipLeft + simdPixels;
            if (scalarLeft < clipRight) {
                applyArithmeticScalar(src1, src2, dst, width, scalarLeft, y, clipRight, y + 1,
                        k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
            }
            continue;
        }

        jint x = clipLeft;
        for (; x + 16 <= clipRight; x += 16) {
            uint8x16x4_t p1 = vld4q_u8(reinterpret_cast<const uint8_t*>(src1 + rowOffset + x));
            uint8x16x4_t p2 = vld4q_u8(reinterpret_cast<const uint8_t*>(src2 + rowOffset + x));
            uint8x16x4_t out;

            // Alpha remains non-linear in linear-light mode.
            out.val[3] = applyArithmeticFormulaNeon64(p1.val[3], p2.val[3], k1, k2, k3, k4_255);
            for (int c = 0; c < 3; c++) {
                uint8x16_t l1 = lookup256Neon64(p1.val[c], tS2L);
                uint8x16_t l2 = lookup256Neon64(p2.val[c], tS2L);
                uint8x16_t res = applyArithmeticFormulaNeon64(l1, l2, k1, k2, k3, k4_255);
                out.val[c] = lookup256Neon64(res, tL2S);
            }

            vst4q_u8(reinterpret_cast<uint8_t*>(dst + rowOffset + x), out);
        }

        if (x < clipRight) {
            applyArithmeticScalar(src1, src2, dst, width, x, y, clipRight, y + 1,
                    k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
    }

#else
    // NEON32
    const float k4_255 = k4 * 255.0f;
    const float coeffs[4] = {
            k1 / 255.0f,
            k2,
            k3,
            k4_255 + 0.5f
    };

    const uint8_t* uS2L = reinterpret_cast<const uint8_t*>(srgbToLinear);
    const uint8_t* uL2S = reinterpret_cast<const uint8_t*>(linearToSrgb);

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;

        if (!useLinear) {
            const jint rowPixels = clipRight - clipLeft;
            const jint simdPixels = rowPixels & ~7;
            if (simdPixels > 0) {
                applyArithmetic32Asm(
                        reinterpret_cast<const uint8_t*>(src1 + rowOffset + clipLeft),
                        reinterpret_cast<const uint8_t*>(src2 + rowOffset + clipLeft),
                        reinterpret_cast<uint8_t*>(dst + rowOffset + clipLeft),
                        static_cast<size_t>(simdPixels),
                        coeffs);
            }

            const jint scalarLeft = clipLeft + simdPixels;
            if (scalarLeft < clipRight) {
                applyArithmeticScalar(src1, src2, dst, width, scalarLeft, y, clipRight, y + 1,
                        k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
            }
            continue;
        }

        jint x = clipLeft;
        for (; x + 8 <= clipRight; x += 8) {
            uint8x8x4_t p1 = vld4_u8(reinterpret_cast<const uint8_t*>(src1 + rowOffset + x));
            uint8x8x4_t p2 = vld4_u8(reinterpret_cast<const uint8_t*>(src2 + rowOffset + x));
            uint8x8x4_t out;

            out.val[3] = applyArithmeticFormulaNeon32(p1.val[3], p2.val[3], k1, k2, k3, k4_255);

            for (int c = 0; c < 3; c++) {
                uint8x8_t l1 = lookup256Neon32(p1.val[c], uS2L);
                uint8x8_t l2 = lookup256Neon32(p2.val[c], uS2L);
                uint8x8_t res = applyArithmeticFormulaNeon32(l1, l2, k1, k2, k3, k4_255);
                out.val[c] = lookup256Neon32(res, uL2S);
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
