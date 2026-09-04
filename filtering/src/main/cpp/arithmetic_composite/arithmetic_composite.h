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

#pragma once

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

void applyArithmeticScalar(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);

#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
void applyArithmeticNeon(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#if defined(__i386__) || defined(__x86_64__)
void ksvgArithmeticApplySse(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);

void ksvgArithmeticApplyAvx2(
        const jint* src1, const jint* src2, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat k1, jfloat k2, jfloat k3, jfloat k4,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#ifdef __cplusplus
}
#endif
