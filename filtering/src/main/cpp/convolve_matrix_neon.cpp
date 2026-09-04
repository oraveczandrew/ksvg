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

#ifdef __aarch64__

#include <jni.h>
#include <cmath>
#include <algorithm>
#include <cassert>
#include <vector>
#include "convolve.h"
#include <arm_neon.h>

extern "C" jint ksvgConvolveGenericNeonAsm(
    const Convolve::NeonConvolveParams *p,
    jint *dst,
    const jint *src);

namespace Convolve {

    // --------------------------------------------------------------
    // NEON boundary-pixel kernels (folded in from convolve_edge_neon.cpp).
    // These process the complement of the interior rectangle that
    // ksvgConvolveGenericNeonAsm covers, and are bit-exact with the scalar
    // convolveScalarPixel() / Kotlin reference.
    // --------------------------------------------------------------

    static inline int sampleCoordinateNeonEdge(const jint coordinate, const jint size, const jint edgeMode) {
        // Bit-exact replica of sampleCoordinate() in convolve_matrix.cpp
        // (that helper is static there, so it is invisible from this TU):
        //   edgeMode 0 = duplicate/clamp, 1 = wrap, 2 = none (outside -> -1).
        // A -1 result is turned into a zero pixel by loadEdgePixels below.
        if (coordinate >= 0 && coordinate < size) return coordinate;
        if (edgeMode == 2) return -1;
        if (edgeMode == 1) {
            const jint m = coordinate % size;
            return m < 0 ? m + size : m;
        }
        return coordinate < 0 ? 0 : size - 1;
    }

    static inline uint32x4_t loadEdgePixels(
        const jint *src, const jint width, const jint height,
        const jint srcY, const jint sx0, const jint sx1, const jint sx2, const jint sx3) {
        uint32_t p0 = 0;
        uint32_t p1 = 0;
        uint32_t p2 = 0;
        uint32_t p3 = 0;
        if (srcY >= 0 && srcY < height) {
            const jint *row = src + srcY * width;
            if (sx0 >= 0 && sx0 < width) p0 = static_cast<uint32_t>(row[sx0]);
            if (sx1 >= 0 && sx1 < width) p1 = static_cast<uint32_t>(row[sx1]);
            if (sx2 >= 0 && sx2 < width) p2 = static_cast<uint32_t>(row[sx2]);
            if (sx3 >= 0 && sx3 < width) p3 = static_cast<uint32_t>(row[sx3]);
        }
        return (uint32x4_t){p0, p1, p2, p3};
    }

    static inline void accumulatePixel4(
        uint32x4_t pixels, const float32x4_t weight,
        float32x4_t &r, float32x4_t &g, float32x4_t &b, float32x4_t &a) {
        const uint32x4_t mask = vdupq_n_u32(0xff);
        uint32x4_t c;
        c = vandq_u32(vshrq_n_u32(pixels, 16), mask);
        r = vmlaq_f32(r, vcvtq_f32_u32(c), weight);
        c = vandq_u32(vshrq_n_u32(pixels, 8), mask);
        g = vmlaq_f32(g, vcvtq_f32_u32(c), weight);
        c = vandq_u32(pixels, mask);
        b = vmlaq_f32(b, vcvtq_f32_u32(c), weight);
        c = vshrq_n_u32(pixels, 24);
        a = vmlaq_f32(a, vcvtq_f32_u32(c), weight);
    }

    static inline void convolveNeonEdge4(
        const jint *src, jint *dst,
        const jint width, const jint height, const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias,
        const bool preserve, const jint edgeMode,
        const jint x, const jint y, const jint count) {
        float32x4_t r = vdupq_n_f32(0.f);
        float32x4_t g = vdupq_n_f32(0.f);
        float32x4_t b = vdupq_n_f32(0.f);
        float32x4_t a = vdupq_n_f32(0.f);

        for (jint ky = 0; ky < orderY; ++ky) {
            const jint sourceY = sampleCoordinateNeonEdge(y + ky - targetY, height, edgeMode);
            for (jint kx = 0; kx < orderX; ++kx) {
                const jint baseX = x + kx - targetX;
                const jint sx0 = sampleCoordinateNeonEdge(baseX, width, edgeMode);
                const jint sx1 = sampleCoordinateNeonEdge(baseX + 1, width, edgeMode);
                const jint sx2 = sampleCoordinateNeonEdge(baseX + 2, width, edgeMode);
                const jint sx3 = sampleCoordinateNeonEdge(baseX + 3, width, edgeMode);
                const uint32x4_t pixels = loadEdgePixels(
                    src, width, height, sourceY, sx0, sx1, sx2, sx3);
                const float32x4_t weight = vdupq_n_f32(kernel[ky * orderX + kx]);
                accumulatePixel4(pixels, weight, r, g, b, a);
            }
        }

        const float32x4_t vDivisor = vdupq_n_f32(divisor);
        const float32x4_t vBias = vdupq_n_f32(bias * 255.f);
        const float32x4_t zero = vdupq_n_f32(0.f);
        const float32x4_t max255 = vdupq_n_f32(255.f);
        const float32x4_t half = vdupq_n_f32(0.5f);

        r = vaddq_f32(vdivq_f32(r, vDivisor), vBias);
        g = vaddq_f32(vdivq_f32(g, vDivisor), vBias);
        b = vaddq_f32(vdivq_f32(b, vDivisor), vBias);
        r = vminq_f32(vmaxq_f32(r, zero), max255);
        g = vminq_f32(vmaxq_f32(g, zero), max255);
        b = vminq_f32(vmaxq_f32(b, zero), max255);

        // Round half-up (add 0.5 then truncate), matching scalar clamp255 /
        // Kotlin Float.roundToInt for these clamped non-negative values.
        const uint32x4_t ri = vcvtq_u32_f32(vaddq_f32(r, half));
        const uint32x4_t gi = vcvtq_u32_f32(vaddq_f32(g, half));
        const uint32x4_t bi = vcvtq_u32_f32(vaddq_f32(b, half));

        uint32x4_t ai;
        if (preserve) {
            const uint32_t a0 = static_cast<uint32_t>((src[y * width + x] >> 24) & 0xff);
            uint32_t a1 = a0;
            uint32_t a2 = a0;
            uint32_t a3 = a0;
            if (count > 1) a1 = static_cast<uint32_t>((src[y * width + x + 1] >> 24) & 0xff);
            if (count > 2) a2 = static_cast<uint32_t>((src[y * width + x + 2] >> 24) & 0xff);
            if (count > 3) a3 = static_cast<uint32_t>((src[y * width + x + 3] >> 24) & 0xff);
            ai = (uint32x4_t){a0, a1, a2, a3};
        } else {
            a = vaddq_f32(vdivq_f32(a, vDivisor), vBias);
            a = vminq_f32(vmaxq_f32(a, zero), max255);
            ai = vcvtq_u32_f32(vaddq_f32(a, half));
        }

        const uint32x4_t result = vorrq_u32(
            vorrq_u32(vorrq_u32(vshlq_n_u32(ai, 24), vshlq_n_u32(ri, 16)), vshlq_n_u32(gi, 8)),
            bi);

        alignas(16) uint32_t tmp[4];
        vst1q_u32(tmp, result);
        for (jint i = 0; i < count; ++i) {
            dst[y * width + x + i] = static_cast<jint>(tmp[i]);
        }
    }

    static void applyNeonEdges4(
        jint *dst, const jint *src,
        const jint width, const jint height, const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias,
        const bool preserve, const jint edgeMode) {
        const jint xLo = targetX;
        const jint xHi = width - orderX + targetX + 1;
        const jint yLo = targetY;
        const jint yHi = height - orderY + targetY + 1;

        auto processRange = [&](const jint y, const jint beginX, const jint endX) {
            jint x = beginX;
            for (; x + 4 <= endX; x += 4) {
                convolveNeonEdge4(src, dst, width, height, kernel, orderX, orderY, targetX, targetY,
                                  divisor, bias, preserve, edgeMode, x, y, 4);
            }
            if (x < endX) {
                convolveNeonEdge4(src, dst, width, height, kernel, orderX, orderY, targetX, targetY,
                                  divisor, bias, preserve, edgeMode, x, y, endX - x);
            }
        };

        // Top.
        for (jint y = 0; y < yLo; ++y) processRange(y, 0, width);
        // Bottom.
        for (jint y = yHi; y < height; ++y) processRange(y, 0, width);
        // Left + right portions of interior rows.
        if (yLo < yHi) {
            for (jint y = yLo; y < yHi; ++y) {
                processRange(y, 0, xLo);
                processRange(y, xHi, width);
            }
        }
    }

    static void applyNeonGenericAsmWithEdges(
        jint *dst, const jint *src,
        const jint width, const jint height,
        const jfloat *kernel,
        const jint orderX, const jint orderY,
        const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias,
        const bool preserve) {
        const jint xLo = targetX;
        const jint xHi = width - orderX + targetX + 1;

        const jint yLo = targetY;
        const jint yHi = height - orderY + targetY + 1;

        // All boundary pixels (the complement of the interior rectangle),
        // computed with the NEON edge kernel.
        applyNeonEdges4(
            dst, src, width, height, kernel,
            orderX, orderY, targetX, targetY,
            divisor, bias, preserve, 0);

        // Interior.
        if (xLo < xHi && yLo < yHi) {
            if (preserve) {
                const NeonConvolveParams params {
                    width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve,
                };
                const jint tailX = ksvgConvolveGenericNeonAsm(&params, dst, src);
                for (jint y = yLo; y < yHi; y++) {
                    for (jint x = tailX; x < xHi; x++) {
                        convolveScalarPixel(
                            src, dst, width, height, kernel,
                            orderX, orderY, targetX, targetY,
                            divisor, bias, preserve, 0, x, y);
                    }
                }
            } else {
                for (jint y = yLo; y < yHi; y++) {
                    for (jint x = xLo; x < xHi; x++) {
                        convolveScalarPixel(
                            src, dst, width, height, kernel,
                            orderX, orderY, targetX, targetY,
                            divisor, bias, preserve, 0, x, y);
                    }
                }
            }
        }
    }

    void applyNeonInterior(
        jint *dst, const jint *src, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve) {
        applyNeonGenericAsmWithEdges(
            dst, src,
            width, height,
            kernel,
            orderX, orderY,
            targetX, targetY,
            divisor, bias,
            preserve);
    }
}

#endif
