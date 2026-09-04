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
#include "convolve.h"
#include <arm_neon.h>

extern "C" jint ksvgConvolveGenericNeonAsm(
    const Convolve::NeonConvolveParams *p,
    jint *dst,
    const jint *src);

namespace Convolve {

    // Bit-exact replica of clamp255() in convolve_matrix.cpp (that helper is
    // static there, so it is invisible from this TU). Round-half-up, matching
    // the Kotlin reference / convolveScalarPixel().
    static inline jint clamp255Neon(const float v) {
        const jint i = static_cast<jint>(std::floor(v + 0.5f));
        return i < 0 ? 0 : i > 255 ? 255 : i;
    }

    // Compile-time edgeMode specialization of scalar coordinate sampling for the
    // boundary bands (bit-exact with sampleCoordinate() in convolve_matrix.cpp).
    // EDGE_MODE 0 = clamp, 1 = wrap, 2 = none (outside -> -1).
    template <int EDGE_MODE>
    static inline jint sampleCoordinateNeonEdgeT(const jint coordinate, const jint size) {
        if (coordinate >= 0 && coordinate < size) return coordinate;
        if (EDGE_MODE == 2) return -1;
        if (EDGE_MODE == 1) {
            const jint m = coordinate % size;
            return m < 0 ? m + size : m;
        }
        return coordinate < 0 ? 0 : size - 1;
    }

    // EdgeMode-specialized single-pixel scalar convolve for the thin edge bands.
    // The runtime edgeMode branch inside sampleCoordinate() is eliminated; the
    // only remaining branches are the reachable sampler comparison. This is
    // bit-exact with convolveScalarPixel() / the Kotlin reference.
    template <int EDGE_MODE>
    static inline void convolveScalarPixelEdged(
        const jint *src, jint *dst,
        const jint width, const jint height, const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const float divisor, const float bias,
        const bool preserve, const jint x, const jint y) {
        float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
        for (jint ky = 0; ky < orderY; ky++) {
            const jint srcY = sampleCoordinateNeonEdgeT<EDGE_MODE>(y + ky - targetY, height);
            for (jint kx = 0; kx < orderX; kx++) {
                const jint srcX = sampleCoordinateNeonEdgeT<EDGE_MODE>(x + kx - targetX, width);
                const jint pixel = (srcX < 0 || srcY < 0) ? 0 : src[srcY * width + srcX];
                const float w = kernel[ky * orderX + kx];
                r += static_cast<float>((pixel >> 16) & 0xFF) * w;
                g += static_cast<float>((pixel >> 8) & 0xFF) * w;
                b += static_cast<float>(pixel & 0xFF) * w;
                a += static_cast<float>((pixel >> 24) & 0xFF) * w;
            }
        }
        const jint outR = clamp255Neon(r / divisor + bias * 255.f);
        const jint outG = clamp255Neon(g / divisor + bias * 255.f);
        const jint outB = clamp255Neon(b / divisor + bias * 255.f);
        const jint outA = preserve
                              ? (src[y * width + x] >> 24) & 0xFF
                              : clamp255Neon(a / divisor + bias * 255.f);
        dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    template <int EDGE_MODE>
    static void applyNeonGenericAsmWithEdgesImpl(
        jint *dst, const jint *src,
        const jint width, const jint height,
        const jfloat *kernel,
        const jint orderX, const jint orderY,
        const jint targetX, const jint targetY,
        const float divisor, const float bias,
        const bool preserve) {
        const jint xLo = targetX;
        const jint xHi = width - orderX + targetX + 1;

        const jint yLo = targetY;
        const jint yHi = height - orderY + targetY + 1;

        // Top + bottom edge bands, plus left/right portions of interior rows.
        // All go through the edgeMode-specialized sampler (branch-free interior
        // columns are handled by the SIMD interior / scalar tail below).
        for (jint y = 0; y < yLo; y++)
            for (jint x = 0; x < width; x++)
                convolveScalarPixelEdged<EDGE_MODE>(
                    src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        for (jint y = yHi; y < height; y++)
            for (jint x = 0; x < width; x++)
                convolveScalarPixelEdged<EDGE_MODE>(
                    src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        for (jint y = yLo; y < yHi; y++) {
            for (jint x = 0; x < xLo; x++)
                convolveScalarPixelEdged<EDGE_MODE>(
                    src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
            for (jint x = xHi; x < width; x++)
                convolveScalarPixelEdged<EDGE_MODE>(
                    src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }

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
                        convolveScalarPixelEdged<EDGE_MODE>(
                            src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
                    }
                }
            } else {
                for (jint y = yLo; y < yHi; y++) {
                    for (jint x = xLo; x < xHi; x++) {
                        convolveScalarPixelEdged<EDGE_MODE>(
                            src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
                    }
                }
            }
        }
    }

    void applyNeonInterior(
        jint *dst, const jint *src, const jint width, const jint height,
        const jfloat *kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve, const jint edgeMode) {
        switch (edgeMode) {
            case 0: applyNeonGenericAsmWithEdgesImpl<0>(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve); break;
            case 1: applyNeonGenericAsmWithEdgesImpl<1>(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve); break;
            default: applyNeonGenericAsmWithEdgesImpl<2>(dst, src, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve); break;
        }
    }
}

#endif
