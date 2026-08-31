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
#include <cstring>
#include <cmath>
#include <algorithm>
#include <cstdint>

#if defined(__i386__) || defined(__x86_64__)

#include <immintrin.h>

namespace {

inline float getChannelValue(jint pixel, int channel) {
    uint32_t p = static_cast<uint32_t>(pixel);
    switch (channel) {
        case 0: return ((p >> 16) & 0xFF) / 255.0f; // R
        case 1: return ((p >> 8) & 0xFF) / 255.0f;  // G
        case 2: return (p & 0xFF) / 255.0f;         // B
        default: return (p >> 24) / 255.0f;         // A
    }
}

inline jint clamp255(float v) {
    int i = static_cast<int>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

void convolveScalarPixel(
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
    int outR = clamp255(r / divisor + bias * 255.f);
    int outG = clamp255(g / divisor + bias * 255.f);
    int outB = clamp255(b / divisor + bias * 255.f);
    int outA = preserve ? (static_cast<uint32_t>(src[y * width + x]) >> 24)
                        : clamp255(a / divisor + bias * 255.f);
    dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
}
}

extern "C" {

void ksvgMorphologyApplyPixelAvx512(
        const jint* src, jint* dst, const jint width,
        const jint radiusX, const jint radiusY, const jboolean erode, const jint x, const jint y) {
    const bool isErode = erode == JNI_TRUE;
    const jint top = y - radiusY;
    const jint bottom = y + radiusY;
    const jint left = x - radiusX;
    const jint right = x + radiusX;

    __m512i acc = _mm512_set1_epi8(isErode ? -1 : 0);

    for (jint ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        jint kx = left;
        for (; kx + 16 <= right + 1; kx += 16) {
            __m512i c = _mm512_loadu_si512(reinterpret_cast<const void*>(row + kx));
            acc = isErode ? _mm512_min_epu8(acc, c) : _mm512_max_epu8(acc, c);
        }
        for (; kx <= right; kx++) {
            jint c = row[kx];
            __m512i cv = _mm512_set1_epi32(c);
            acc = isErode ? _mm512_min_epu8(acc, cv) : _mm512_max_epu8(acc, cv);
        }
    }

    alignas(64) uint8_t res[64];
    _mm512_storeu_si512(reinterpret_cast<void*>(res), acc);

    uint8_t finalA = res[3], finalR = res[2], finalG = res[1], finalB = res[0];
    for (int i = 1; i < 16; i++) {
        if (isErode) {
            finalA = std::min(finalA, res[i * 4 + 3]);
            finalR = std::min(finalR, res[i * 4 + 2]);
            finalG = std::min(finalG, res[i * 4 + 1]);
            finalB = std::min(finalB, res[i * 4 + 0]);
        } else {
            finalA = std::max(finalA, res[i * 4 + 3]);
            finalR = std::max(finalR, res[i * 4 + 2]);
            finalG = std::max(finalG, res[i * 4 + 1]);
            finalB = std::max(finalB, res[i * 4 + 0]);
        }
    }
    dst[y * width + x] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
}

void ksvgConvolveApplyInteriorAvx512(
        jint* dst, const jint* src, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha) {
    const bool preserve = preserveAlpha == JNI_TRUE;
    const __m512 vDivisor = _mm512_set1_ps(divisor);
    const __m512 vBias255 = _mm512_set1_ps(bias * 255.0f);
    const __m512 vHalf = _mm512_set1_ps(0.5f);
    const __m512i maskFF = _mm512_set1_epi32(0xFF);
    const __m512i zero = _mm512_setzero_si512();
    const __m512i c255 = _mm512_set1_epi32(255);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;
        jint x = 0;
        for (; x < xLo; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }
        for (; x + 16 <= xHi; x += 16) {
            __m512 accR = _mm512_setzero_ps();
            __m512 accG = _mm512_setzero_ps();
            __m512 accB = _mm512_setzero_ps();
            __m512 accA = _mm512_setzero_ps();

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* srcRow = src + (y + ky - targetY) * width + (x - targetX);
                for (jint kx = 0; kx < orderX; kx++) {
                    const __m512 w = _mm512_set1_ps(kernel[ky * orderX + kx]);
                    const __m512i p = _mm512_loadu_si512(reinterpret_cast<const void*>(srcRow + kx));
                    accB = _mm512_add_ps(accB, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_and_si512(p, maskFF)), w));
                    accG = _mm512_add_ps(accG, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(p, 8), maskFF)), w));
                    accR = _mm512_add_ps(accR, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(p, 16), maskFF)), w));
                    accA = _mm512_add_ps(accA, _mm512_mul_ps(_mm512_cvtepu32_ps(_mm512_srli_epi32(p, 24)), w));
                }
            }

            auto roundRHU = [vDivisor, vBias255, vHalf](__m512 acc) {
                return _mm512_cvttps_epi32(_mm512_floor_ps(_mm512_add_ps(_mm512_add_ps(_mm512_div_ps(acc, vDivisor), vBias255), vHalf)));
            };

            __m512i iR = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accR), zero), c255);
            __m512i iG = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accG), zero), c255);
            __m512i iB = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accB), zero), c255);
            __m512i iA;

            if (preserve) {
                iA = _mm512_srli_epi32(_mm512_loadu_si512(reinterpret_cast<const void*>(src + rowOffset + x)), 24);
            } else {
                iA = _mm512_min_epi32(_mm512_max_epi32(roundRHU(accA), zero), c255);
            }

            const __m512i out = _mm512_or_si512(_mm512_or_si512(_mm512_slli_epi32(iA, 24), _mm512_slli_epi32(iR, 16)),
                                               _mm512_or_si512(_mm512_slli_epi32(iG, 8), iB));
            _mm512_storeu_si512(reinterpret_cast<void*>(dst + rowOffset + x), out);
        }
        for (; x < width; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }
    }
}

void ksvgDisplacementMapApplyAvx512(
        const jint* src, const jint* map, jint* dst, int width, int height,
        float scale, int xChannel, int yChannel) {
    const __m512 vScale = _mm512_set1_ps(scale);
    const __m512 vHalf = _mm512_set1_ps(0.5f);
    const __m512 v255 = _mm512_set1_ps(255.0f);
    const __m512i maskFF = _mm512_set1_epi32(0xFF);
    const __m512i vWidthMinus1 = _mm512_set1_epi32(width - 1);
    const __m512i vHeightMinus1 = _mm512_set1_epi32(height - 1);
    const __m512i vZero = _mm512_setzero_si512();
    const __m512i vWidth = _mm512_set1_epi32(width);

    int xs = xChannel == 0 ? 16 : xChannel == 1 ? 8 : xChannel == 2 ? 0 : 24;
    int ys = yChannel == 0 ? 16 : yChannel == 1 ? 8 : yChannel == 2 ? 0 : 24;

    for (int y = 0; y < height; y++) {
        const int rowOffset = y * width;
        const __m512i vY = _mm512_set1_epi32(y);
        int x = 0;
        for (; x + 16 <= width; x += 16) {
            const __m512i vX = _mm512_add_epi32(_mm512_set1_epi32(x), _mm512_setr_epi32(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15));
            const __m512i mapPixels = _mm512_loadu_si512(reinterpret_cast<const void*>(map + rowOffset + x));

            const __m512 vx = _mm512_div_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(mapPixels, xs), maskFF)), v255);
            const __m512 vy = _mm512_div_ps(_mm512_cvtepu32_ps(_mm512_and_si512(_mm512_srli_epi32(mapPixels, ys), maskFF)), v255);

            const __m512i idx = _mm512_cvttps_epi32(_mm512_mul_ps(vScale, _mm512_sub_ps(vx, vHalf)));
            const __m512i idy = _mm512_cvttps_epi32(_mm512_mul_ps(vScale, _mm512_sub_ps(vy, vHalf)));

            const __m512i sx = _mm512_max_epi32(vZero, _mm512_min_epi32(_mm512_add_epi32(vX, idx), vWidthMinus1));
            const __m512i sy = _mm512_max_epi32(vZero, _mm512_min_epi32(_mm512_add_epi32(vY, idy), vHeightMinus1));

            const __m512i indices = _mm512_add_epi32(_mm512_mullo_epi32(sy, vWidth), sx);
            const __m512i res = _mm512_i32gather_epi32(indices, src, 4);
            _mm512_storeu_si512(reinterpret_cast<void*>(dst + rowOffset + x), res);
        }
        for (; x < width; x++) {
            jint mapPixel = map[rowOffset + x];
            int dx = (int)(scale * (getChannelValue(mapPixel, xChannel) - 0.5f));
            int dy = (int)(scale * (getChannelValue(mapPixel, yChannel) - 0.5f));
            int sx = std::max(0, std::min(width - 1, x + dx));
            int sy = std::max(0, std::min(height - 1, y + dy));
            dst[rowOffset + x] = src[sy * width + sx];
        }
    }
}

} // extern "C"

#endif
