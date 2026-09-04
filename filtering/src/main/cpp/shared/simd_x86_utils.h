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
#include <cmath>
#include <algorithm>
#include <cstdint>
#include "shared/math_utils.h"

namespace ksvg_x86 {

inline float getChannelValue(jint pixel, int channel) {
    uint32_t p = static_cast<uint32_t>(pixel);
    switch (channel) {
        case 0: return ((p >> 16) & 0xFF) / 255.0f; // R
        case 1: return ((p >> 8) & 0xFF) / 255.0f;  // G
        case 2: return (p & 0xFF) / 255.0f;         // B
        default: return (p >> 24) / 255.0f;         // A
    }
}

inline void convolveScalarPixel(
        const jint* src, jint* dst, int width, int height,
        const float* kernel, int orderX, int orderY, int targetX, int targetY,
        float divisor, float bias, bool preserve, int x, int y) {
    float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
    for (int ky = 0; ky < orderY; ky++) {
        int sy = std::max(0, std::min(height - 1, y + ky - targetY));
        for (int kx = 0; kx < orderX; kx++) {
            int sx = std::max(0, std::min(width - 1, x + kx - targetX));
            uint32_t pixel = static_cast<uint32_t>(src[sy * width + sx]);
            float w = kernel[ky * orderX + kx];
            b += static_cast<float>(pixel & 0xFF) * w;
            g += static_cast<float>((pixel >> 8) & 0xFF) * w;
            r += static_cast<float>((pixel >> 16) & 0xFF) * w;
            a += static_cast<float>(pixel >> 24) * w;
        }
    }
    int outR = ksvg::clamp255(r / divisor + bias * 255.f);
    int outG = ksvg::clamp255(g / divisor + bias * 255.f);
    int outB = ksvg::clamp255(b / divisor + bias * 255.f);
    uint32_t srcPixel = static_cast<uint32_t>(src[y * width + x]);
    int outA = preserve ? (srcPixel >> 24)
                        : ksvg::clamp255(a / divisor + bias * 255.f);
    dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

} // namespace ksvg_x86
