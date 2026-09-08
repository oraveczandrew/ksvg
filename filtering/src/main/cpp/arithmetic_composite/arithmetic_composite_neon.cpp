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
#include "arithmetic_composite.h"

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

} // namespace

void applyArithmeticNeon(
        const jint* src1, const jint* src2, jint* dst,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat k1, const jfloat k2, const jfloat k3, const jfloat k4,
        const jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb) {

#ifdef __aarch64__
    const float k4_255 = k4 * 255.0f;
#else
    const float k4_255 = k4 * 255.0f;
    const float coeffs[4] = {
            k1 / 255.0f,
            k2,
            k3,
            k4_255 + 0.5f
    };
#endif

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
#ifdef __aarch64__
        const jint simdPixels = clipRight - clipLeft & ~7;
        if (simdPixels > 0) {
            applyArithmetic64Asm(
                    reinterpret_cast<const uint8_t*>(src1 + rowOffset + clipLeft),
                    reinterpret_cast<const uint8_t*>(src2 + rowOffset + clipLeft),
                    reinterpret_cast<uint8_t*>(dst + rowOffset + clipLeft),
                    static_cast<size_t>(simdPixels),
                    k1 / 255.0f, k2, k3, k4_255);
        }
#else
        const jint simdPixels = (clipRight - clipLeft) & ~7;
        if (simdPixels > 0) {
            applyArithmetic32Asm(
                        reinterpret_cast<const uint8_t*>(src1 + rowOffset + clipLeft),
                        reinterpret_cast<const uint8_t*>(src2 + rowOffset + clipLeft),
                        reinterpret_cast<uint8_t*>(dst + rowOffset + clipLeft),
                        static_cast<size_t>(simdPixels),
                        coeffs);
        }
#endif
        const jint scalarLeft = clipLeft + simdPixels;
        if (scalarLeft < clipRight) {
            applyArithmeticScalar(src1, src2, dst, width, scalarLeft, y, clipRight, y + 1,
                    k1, k2, k3, k4, useLinear, srgbToLinear, linearToSrgb);
        }
    }
}
#endif
