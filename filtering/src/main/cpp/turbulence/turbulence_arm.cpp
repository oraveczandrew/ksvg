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
#include <cmath>
#include <cstring>
#include "turbulence_tables.h"
#include "turbulence_arm.h"

#if defined(__aarch64__)
#include <arm_neon.h>

namespace {

 inline float64x2_t lerp2(
        const float64x2_t u,
        const float64x2_t v,
        const double factor) {
    const float64x2_t f = vdupq_n_f64(factor);
    return vaddq_f64(u, vmulq_f64(f, vsubq_f64(v, u)));
}

 inline float64x2_t abs2(const float64x2_t value) {
    return vabsq_f64(value);
}

 inline float64x2_t noise2Channels(
        const Arm64LatticeTables& t,
        const PixelGeometry& g,
        const int channelOffset) {
    const double* gx = &t.gradPackedX[g.b00][channelOffset];
    const double* gy = &t.gradPackedY[g.b00][channelOffset];
    const double* gx10 = &t.gradPackedX[g.b10][channelOffset];
    const double* gy10 = &t.gradPackedY[g.b10][channelOffset];
    const double* gx01 = &t.gradPackedX[g.b01][channelOffset];
    const double* gy01 = &t.gradPackedY[g.b01][channelOffset];
    const double* gx11 = &t.gradPackedX[g.b11][channelOffset];
    const double* gy11 = &t.gradPackedY[g.b11][channelOffset];

    const float64x2_t rx0 = vdupq_n_f64(g.rx0);
    const float64x2_t rx1 = vdupq_n_f64(g.rx1);
    const float64x2_t ry0 = vdupq_n_f64(g.ry0);
    const float64x2_t ry1 = vdupq_n_f64(g.ry1);

    const float64x2_t u = vaddq_f64(
            vmulq_f64(rx0, vld1q_f64(gx)),
            vmulq_f64(ry0, vld1q_f64(gy)));
    const float64x2_t v = vaddq_f64(
            vmulq_f64(rx1, vld1q_f64(gx10)),
            vmulq_f64(ry0, vld1q_f64(gy10)));
    const float64x2_t u2 = vaddq_f64(
            vmulq_f64(rx0, vld1q_f64(gx01)),
            vmulq_f64(ry1, vld1q_f64(gy01)));
    const float64x2_t v2 = vaddq_f64(
            vmulq_f64(rx1, vld1q_f64(gx11)),
            vmulq_f64(ry1, vld1q_f64(gy11)));

    const float64x2_t a = lerp2(u, v, g.sx);
    const float64x2_t b = lerp2(u2, v2, g.sx);
    return lerp2(a, b, g.sy);
}

inline void processPixelNeon64(
        const Arm64LatticeTables& t,
        double sums[4],
        const double px0,
        const double py0,
        const double tileX,
        const double tileY,
        const double baseFrequencyX,
        const double baseFrequencyY,
        const int periodX,
        const int periodY,
        const int octaves,
        const bool fractal,
        const bool stitchEnabled) {
    float64x2_t sum01 = vdupq_n_f64(0.0);
    float64x2_t sum23 = vdupq_n_f64(0.0);

    double fx = px0;
    double fy = py0;
    double curtlx = tileX * baseFrequencyX;
    double curtly = tileY * baseFrequencyY;
    double ratio = 1.0;

    StitchInfo si;
    si.width = periodX;
    si.height = periodY;

    for (int octave = 0; octave < octaves; ++octave) {
        if (stitchEnabled) {
            si.wrapX = static_cast<int32_t>(std::floor(curtlx)) + 4096 + si.width;
            si.wrapY = static_cast<int32_t>(std::floor(curtly)) + 4096 + si.height;
        }

        const PixelGeometry g = geometry32(t.selector32, fx, fy, si, stitchEnabled);
        float64x2_t n01 = noise2Channels(t, g, 0);
        float64x2_t n23 = noise2Channels(t, g, 2);
        const float64x2_t ratioV = vdupq_n_f64(ratio);

        if (fractal) {
            n01 = vdivq_f64(n01, ratioV);
            n23 = vdivq_f64(n23, ratioV);
        } else {
            n01 = vdivq_f64(abs2(n01), ratioV);
            n23 = vdivq_f64(abs2(n23), ratioV);
        }

        sum01 = vaddq_f64(sum01, n01);
        sum23 = vaddq_f64(sum23, n23);

        fx *= 2.0;
        fy *= 2.0;
        curtlx *= 2.0;
        curtly *= 2.0;
        ratio *= 2.0;

        if (stitchEnabled) {
            si.width *= 2;
            si.height *= 2;
        }
    }

    vst1q_f64(sums, sum01);
    vst1q_f64(sums + 2, sum23);
}

} // namespace

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
#if defined(__aarch64__)
    (void) originX;
    (void) originY;

    Arm64LatticeTables tables;
    initArm64Tables(tables, seed);
    std::memset(pixels, 0, static_cast<size_t>(width) * height * sizeof(jint));

    const bool stitchEnabled = periodX > 0 || periodY > 0;
    const bool fractal = fractalNoise == JNI_TRUE;

    for (jint y = clipTop; y < clipBottom; ++y) {
        const double userY = userTop + y * invCanvasScaleY;
        const double py0 = userY / unitSizeY * baseFrequencyY;
        const double tileY = y - clipTop;
        const jint rowOffset = y * width;

        for (jint x = clipLeft; x < clipRight; ++x) {
            const double userX = userLeft + x * invCanvasScaleX;
            const double px0 = userX / unitSizeX * baseFrequencyX;
            const double tileX = x - clipLeft;

            double sums[4];
            processPixelNeon64(
                    tables, sums, px0, py0, tileX, tileY,
                    baseFrequencyX, baseFrequencyY,
                    periodX, periodY, octaves, fractal, stitchEnabled);

            pixels[rowOffset + x] = packPixel(sums, fractal);
        }
    }
#else
    (void) pixels; (void) width; (void) height;
    (void) clipLeft; (void) clipTop; (void) clipRight; (void) clipBottom;
    (void) baseFrequencyX; (void) baseFrequencyY;
    (void) periodX; (void) periodY; (void) octaves; (void) fractalNoise;
    (void) invCanvasScaleX; (void) invCanvasScaleY;
    (void) userLeft; (void) userTop;
    (void) originX; (void) originY;
    (void) unitSizeX; (void) unitSizeY; (void) seed;
#endif

} // extern "C"

#endif
