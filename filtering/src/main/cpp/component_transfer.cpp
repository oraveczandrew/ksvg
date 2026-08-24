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

// feComponentTransfer kernel. All transfer math (table/discrete/linear/gamma,
// including any sRGB<->linearRGB folding) is precomputed by Kotlin into four
// 256-entry byte tables, one per ARGB channel. The kernel is therefore a pure
// per-pixel table gather over an unpremultiplied ARGB_8888 IntArray — no
// allocation, no shared state, caller owns both arrays.
//
// Pixels outside [clipLeft,clipRight) x [clipTop,clipBottom) are set to
// transparent black in dst, matching the previous pure-Kotlin loop
// (`outPixels.fill(0)` before the clipped transfer pass).

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
    jbyte* tableA = env->GetByteArrayElements(jTableA, nullptr);
    jbyte* tableR = env->GetByteArrayElements(jTableR, nullptr);
    jbyte* tableG = env->GetByteArrayElements(jTableG, nullptr);
    jbyte* tableB = env->GetByteArrayElements(jTableB, nullptr);
    if (dst == nullptr || tableA == nullptr || tableR == nullptr ||
        tableG == nullptr || tableB == nullptr) {
        if (src != nullptr) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        return;
    }

    const jint total = width * height;

    // Everything outside the clip becomes transparent black.
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

    env->ReleaseByteArrayElements(jTableB, tableB, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableG, tableG, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableR, tableR, JNI_ABORT);
    env->ReleaseByteArrayElements(jTableA, tableA, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
