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

/*
 * AArch64 assembly-backed turbulence implementation.
 */
#include <jni.h>
#include <cstring>
#include "turbulence_tables.h"
#include "turbulence_arm.h"
#include "turbulence_asm64.h"

#if defined(__aarch64__)

void applyNeon64(
        jint* pixels, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jdouble baseFrequencyX, const jdouble baseFrequencyY,
        const jint periodX, const jint periodY, const jint octaves, const jboolean fractalNoise,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jint seed) {
    (void) originX;
    (void) originY;

    Arm64LatticeTables tables;
    initArm64Tables(tables, seed);

    std::memset(
            pixels,
            0,
            static_cast<size_t>(width) * static_cast<size_t>(height) * sizeof(jint));

    Turbulence64AsmArgs args {
            tables.selector32,
            &tables.gradPackedX[0][0],
            &tables.gradPackedY[0][0],
            pixels,
            width,
            clipLeft,
            clipTop,
            clipRight,
            clipBottom,
            periodX,
            periodY,
            octaves,
            fractalNoise == JNI_TRUE ? 1 : 0,
            baseFrequencyX,
            baseFrequencyY,
            invCanvasScaleX,
            invCanvasScaleY,
            userLeft,
            userTop,
            unitSizeX,
            unitSizeY
    };

    turbulence64Asm(&args);
}

#endif
