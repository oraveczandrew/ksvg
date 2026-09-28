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

void applyColorMatrixScalar(
        const jint* src, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jfloat* matrix,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);

#if defined(__aarch64__) || defined(__ARM_NEON__) || defined(__ARM_NEON)
void applyColorMatrixNeon(
        const jint* src, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jfloat* matrix,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#if defined(__x86_64__) || defined(_M_X64)
void applyColorMatrixSsse3(
        const jint* src, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jfloat* matrix,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
void applyColorMatrixAvx2(
        const jint* src, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jfloat* matrix,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#if defined(__i386__) || defined(_M_IX86)
void applyColorMatrixSsse3x86(
        const jint* src, jint* dst,
        jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        const jfloat* matrix,
        jboolean useLinear,
        const jbyte* srgbToLinear, const jbyte* linearToSrgb);
#endif

#ifdef __cplusplus
}
#endif
