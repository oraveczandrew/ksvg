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

// feComponentTransfer kernel over unpremultiplied ARGB_8888 IntArrays.
//
// All transfer math (table/discrete/linear/gamma, including any sRGB<->linearRGB
// folding) is precomputed by Kotlin into four 256-entry IntArray tables, one per
// ARGB channel. Each entry in the table is already shifted to its target
// position (e.g., tableA[i] = alpha << 24).
//
// The kernel performs per-pixel table gathers over the clip region; pixels
// outside it become transparent black.
//
// With pre-shifted IntArray tables, the scalar reference loop is extremely
// efficient (4 lookups and 3 ORs per pixel), so it is used exclusively.

namespace {

void applyScalar(
        const jint* src, jint* dst, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jint* tableA, const jint* tableR, const jint* tableG, const jint* tableB) {
    const jint total = width * height;
    memset(dst, 0, static_cast<size_t>(total) * sizeof(*dst));
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jint c = src[rowOffset + x];
            dst[rowOffset + x] =
                    tableA[(c >> 24) & 0xFF] |
                    tableR[(c >> 16) & 0xFF] |
                    tableG[(c >> 8) & 0xFF] |
                    tableB[c & 0xFF];
        }
    }
}

} // namespace

// Validation/test-only: run an explicitly selected backend (see SimdBackend).
namespace {

void runForced(const jint* src, jint* dst, jint width, jint height,
               jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
               const jint* tableA, const jint* tableR, const jint* tableG, const jint* tableB,
               const jint backend) {
    (void)backend;
    applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);
}

jint nativeBackendForAbi() {
    return SIMD_BACKEND_SCALAR;
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
        const jintArray jTableA, const jintArray jTableR, const jintArray jTableG, const jintArray jTableB,
        const jint simdBackend) {
    auto* tableA = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableA, nullptr));
    auto* tableR = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableR, nullptr));
    auto* tableG = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableG, nullptr));
    auto* tableB = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableB, nullptr));
    if (tableA == nullptr || tableR == nullptr || tableG == nullptr || tableB == nullptr) {
        if (tableA) env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
        if (tableR) env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
        if (tableG) env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
        if (tableB) env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
        return;
    }
    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
        return;
    }

    runForced(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
              tableA, tableR, tableG, tableB, simdBackend);

    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ComponentTransferNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jintArray jTableA, const jintArray jTableR, const jintArray jTableG, const jintArray jTableB) {
    auto* tableA = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableA, nullptr));
    auto* tableR = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableR, nullptr));
    auto* tableG = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableG, nullptr));
    auto* tableB = static_cast<jint*>(env->GetPrimitiveArrayCritical(jTableB, nullptr));
    if (tableA == nullptr || tableR == nullptr || tableG == nullptr || tableB == nullptr) {
        if (tableA) env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
        if (tableR) env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
        if (tableG) env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
        if (tableB) env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
        return;
    }
    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
        return;
    }

    applyScalar(src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB);

    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableB, tableB, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableG, tableG, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableR, tableR, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jTableA, tableA, JNI_ABORT);
}
