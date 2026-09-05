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

#if defined(__arm__)

#include <cstddef>

struct Turbulence32AsmArgs {
    const uint32_t* selector32;
    const double* gradPackedX;
    const double* gradPackedY;
    int32_t* pixels;
    int32_t width;
    int32_t clipLeft;
    int32_t clipTop;
    int32_t clipRight;
    int32_t clipBottom;
    int32_t periodX;
    int32_t periodY;
    int32_t octaves;
    int32_t fractal;
    double baseFrequencyX;
    double baseFrequencyY;
    double invCanvasScaleX;
    double invCanvasScaleY;
    double userLeft;
    double userTop;
    double unitSizeX;
    double unitSizeY;
};

// sizeof == 120 on little-endian armv7 (13 x int32 range then 8 doubles: see
// file layout chased from the .equ table in turbulence_noise_neon32.S).
static_assert(offsetof(Turbulence32AsmArgs, selector32) == 0);
static_assert(offsetof(Turbulence32AsmArgs, gradPackedX) == 4);
static_assert(offsetof(Turbulence32AsmArgs, gradPackedY) == 8);
static_assert(offsetof(Turbulence32AsmArgs, pixels) == 12);
static_assert(offsetof(Turbulence32AsmArgs, width) == 16);
static_assert(offsetof(Turbulence32AsmArgs, clipLeft) == 20);
static_assert(offsetof(Turbulence32AsmArgs, clipTop) == 24);
static_assert(offsetof(Turbulence32AsmArgs, clipRight) == 28);
static_assert(offsetof(Turbulence32AsmArgs, clipBottom) == 32);
static_assert(offsetof(Turbulence32AsmArgs, periodX) == 36);
static_assert(offsetof(Turbulence32AsmArgs, periodY) == 40);
static_assert(offsetof(Turbulence32AsmArgs, octaves) == 44);
static_assert(offsetof(Turbulence32AsmArgs, fractal) == 48);
static_assert(offsetof(Turbulence32AsmArgs, baseFrequencyX) == 56);
static_assert(offsetof(Turbulence32AsmArgs, baseFrequencyY) == 64);
static_assert(offsetof(Turbulence32AsmArgs, invCanvasScaleX) == 72);
static_assert(offsetof(Turbulence32AsmArgs, invCanvasScaleY) == 80);
static_assert(offsetof(Turbulence32AsmArgs, userLeft) == 88);
static_assert(offsetof(Turbulence32AsmArgs, userTop) == 96);
static_assert(offsetof(Turbulence32AsmArgs, unitSizeX) == 104);
static_assert(offsetof(Turbulence32AsmArgs, unitSizeY) == 112);
static_assert(sizeof(Turbulence32AsmArgs) == 120);

extern "C" void turbulence32Asm(const Turbulence32AsmArgs* args);

#endif