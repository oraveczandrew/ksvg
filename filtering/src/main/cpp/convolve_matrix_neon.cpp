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

    // Clamp-only (edgeMode 0) scalar convolve for the thin edge bands.
    //
    // This is a specialization of convolveScalarPixel() with edgeMode pinned to
    // 0: the runtime edgeMode branch inside sampleCoordinate() (the wrap / none
    // cases) is gone, and because clamp never yields -1 there is no
    // "srcX < 0 || srcY < 0 -> 0" out-of-bounds test either. The only remaining
    // branches are the two tiny clamp comparisons on srcX / srcY.
    static inline void convolveScalarPixelClamp(
        const jint *src, jint *dst,
        const jint width, const jint height, const jfloat *kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias,
        const bool preserve, const jint x, const jint y) {
        float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
        for (jint ky = 0; ky < orderY; ky++) {
            jint srcY = y + ky - targetY;
            if (srcY < 0) srcY = 0;
            else if (srcY >= height) srcY = height - 1;
            const jint *const row = src + srcY * width;
            for (jint kx = 0; kx < orderX; kx++) {
                jint srcX = x + kx - targetX;
                if (srcX < 0) srcX = 0;
                else if (srcX >= width) srcX = width - 1;
                const jint pixel = row[srcX];
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

        // Top edge band.
        for (jint y = 0; y < yLo; y++) {
            for (jint x = 0; x < width; x++) {
                convolveScalarPixelClamp(
                    src, dst, width, height, kernel,
                    orderX, orderY, targetX, targetY,
                    divisor, bias, preserve, x, y);
            }
        }

        // Bottom edge band.
        for (jint y = yHi; y < height; y++) {
            for (jint x = 0; x < width; x++) {
                convolveScalarPixelClamp(
                    src, dst, width, height, kernel,
                    orderX, orderY, targetX, targetY,
                    divisor, bias, preserve, x, y);
            }
        }

        // Left + right portions of the interior rows.
        for (jint y = yLo; y < yHi; y++) {
            for (jint x = 0; x < xLo; x++) {
                convolveScalarPixelClamp(
                    src, dst, width, height, kernel,
                    orderX, orderY, targetX, targetY,
                    divisor, bias, preserve, x, y);
            }
            for (jint x = xHi; x < width; x++) {
                convolveScalarPixelClamp(
                    src, dst, width, height, kernel,
                    orderX, orderY, targetX, targetY,
                    divisor, bias, preserve, x, y);
            }
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
                        convolveScalarPixelClamp(
                            src, dst, width, height, kernel,
                            orderX, orderY, targetX, targetY,
                            divisor, bias, preserve, x, y);
                    }
                }
            } else {
                for (jint y = yLo; y < yHi; y++) {
                    for (jint x = xLo; x < xHi; x++) {
                        convolveScalarPixelClamp(
                            src, dst, width, height, kernel,
                            orderX, orderY, targetX, targetY,
                            divisor, bias, preserve, x, y);
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
