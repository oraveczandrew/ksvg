//    Copyright 2026 András Oravecz <info@oandras.hu>
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        https://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

#pragma once

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

// feBlend modes. Values mirror FeBlendMode in `:ksvg` (0=normal never reaches
// the kernel).
enum FeBlendMode {
    FE_BLEND_MULTIPLY = 1,
    FE_BLEND_SCREEN = 2,
    FE_BLEND_OVERLAY = 3,
    FE_BLEND_DARKEN = 4,
    FE_BLEND_LIGHTEN = 5,
    FE_BLEND_COLOR_DODGE = 6,
    FE_BLEND_COLOR_BURN = 7,
    FE_BLEND_HARD_LIGHT = 8,
    FE_BLEND_SOFT_LIGHT = 9,
    FE_BLEND_DIFFERENCE = 10,
    FE_BLEND_EXCLUSION = 11,
    FE_BLEND_HUE = 12,
    FE_BLEND_SATURATION = 13,
    FE_BLEND_COLOR = 14,
    FE_BLEND_LUMINOSITY = 15,
};

void applyFeBlendScalar(
        const jint* src, const jint* dst, jint* out,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jint mode,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);

#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
// feBlend NEON separable rows (fe_blend_aarch64_neon.S on arm64,
// fe_blend_arm32_neon.S on armv7). Group E
// (hue/saturation/color/luminosity) stays scalar on every backend.
void applyFeBlendNeon(
        const jint* src, const jint* dst, jint* out,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jint mode,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#if defined(__x86_64__) || defined(_M_X64)
void applyFeBlendSsse3(
        const jint* src, const jint* dst, jint* out,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jint mode,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
void applyFeBlendAvx2(
        const jint* src, const jint* dst, jint* out,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jint mode,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#if defined(__i386__) || defined(_M_IX86)
void applyFeBlendSsse3x86(
        const jint* src, const jint* dst, jint* out,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jint mode,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#ifdef __cplusplus
}
#endif
