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

#if defined(__aarch64__)

#include <cstddef>

struct Turbulence64AsmArgs {
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

static_assert(offsetof(Turbulence64AsmArgs, selector32) == 0);
static_assert(offsetof(Turbulence64AsmArgs, gradPackedX) == 8);
static_assert(offsetof(Turbulence64AsmArgs, gradPackedY) == 16);
static_assert(offsetof(Turbulence64AsmArgs, pixels) == 24);
static_assert(offsetof(Turbulence64AsmArgs, width) == 32);
static_assert(offsetof(Turbulence64AsmArgs, clipLeft) == 36);
static_assert(offsetof(Turbulence64AsmArgs, clipTop) == 40);
static_assert(offsetof(Turbulence64AsmArgs, clipRight) == 44);
static_assert(offsetof(Turbulence64AsmArgs, clipBottom) == 48);
static_assert(offsetof(Turbulence64AsmArgs, periodX) == 52);
static_assert(offsetof(Turbulence64AsmArgs, periodY) == 56);
static_assert(offsetof(Turbulence64AsmArgs, octaves) == 60);
static_assert(offsetof(Turbulence64AsmArgs, fractal) == 64);
static_assert(offsetof(Turbulence64AsmArgs, baseFrequencyX) == 72);
static_assert(offsetof(Turbulence64AsmArgs, baseFrequencyY) == 80);
static_assert(offsetof(Turbulence64AsmArgs, invCanvasScaleX) == 88);
static_assert(offsetof(Turbulence64AsmArgs, invCanvasScaleY) == 96);
static_assert(offsetof(Turbulence64AsmArgs, userLeft) == 104);
static_assert(offsetof(Turbulence64AsmArgs, userTop) == 112);
static_assert(offsetof(Turbulence64AsmArgs, unitSizeX) == 120);
static_assert(offsetof(Turbulence64AsmArgs, unitSizeY) == 128);

extern "C" void turbulence64Asm(const Turbulence64AsmArgs* args);

#endif
