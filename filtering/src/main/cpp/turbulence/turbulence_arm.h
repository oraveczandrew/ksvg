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

#ifndef KSVG_TURBULENCE_ARM_H
#define KSVG_TURBULENCE_ARM_H

#include <jni.h>

extern "C" {

void applyNeon64(
        jint* pixels, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jdouble baseFrequencyX, jdouble baseFrequencyY,
        jint periodX, jint periodY, jint octaves, jboolean fractalNoise,
        jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop,
        jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        jint seed);

}

#endif // KSVG_TURBULENCE_ARM_H
