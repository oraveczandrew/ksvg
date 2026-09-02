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
#include <cstdint>
#include <algorithm>
#include "turbulence_core.h"
#include "turbulence_x86.h"

#if defined(__i386__) || defined(__x86_64__)
#include <emmintrin.h>

namespace {

static inline __m128d lerp2(
        const __m128d u,
        const __m128d v,
        const double factor) {
    const __m128d f = _mm_set1_pd(factor);
    return _mm_add_pd(u, _mm_mul_pd(f, _mm_sub_pd(v, u)));
}

static inline __m128d abs2(const __m128d value) {
    const __m128i sign = _mm_set1_epi64x(INT64_C(0x7fffffffffffffff));
    return _mm_castsi128_pd(_mm_and_si128(_mm_castpd_si128(value), sign));
}

static inline __m128d noise2Channels(
        const LatticeTables& t,
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

    const __m128d rx0 = _mm_set1_pd(g.rx0);
    const __m128d rx1 = _mm_set1_pd(g.rx1);
    const __m128d ry0 = _mm_set1_pd(g.ry0);
    const __m128d ry1 = _mm_set1_pd(g.ry1);

    const __m128d u = _mm_add_pd(
            _mm_mul_pd(rx0, _mm_loadu_pd(gx)),
            _mm_mul_pd(ry0, _mm_loadu_pd(gy)));
    const __m128d v = _mm_add_pd(
            _mm_mul_pd(rx1, _mm_loadu_pd(gx10)),
            _mm_mul_pd(ry0, _mm_loadu_pd(gy10)));
    const __m128d u2 = _mm_add_pd(
            _mm_mul_pd(rx0, _mm_loadu_pd(gx01)),
            _mm_mul_pd(ry1, _mm_loadu_pd(gy01)));
    const __m128d v2 = _mm_add_pd(
            _mm_mul_pd(rx1, _mm_loadu_pd(gx11)),
            _mm_mul_pd(ry1, _mm_loadu_pd(gy11)));

    const __m128d a = lerp2(u, v, g.sx);
    const __m128d b = lerp2(u2, v2, g.sx);
    return lerp2(a, b, g.sy);
}

static inline void processPixelSsse3(
        const LatticeTables& t,
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
    __m128d sum01 = _mm_setzero_pd();
    __m128d sum23 = _mm_setzero_pd();
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

        const PixelGeometry g = geometry(t, fx, fy, si, stitchEnabled);
        __m128d n01 = noise2Channels(t, g, 0);
        __m128d n23 = noise2Channels(t, g, 2);
        const __m128d ratioV = _mm_set1_pd(ratio);
        if (fractal) {
            n01 = _mm_div_pd(n01, ratioV);
            n23 = _mm_div_pd(n23, ratioV);
        } else {
            n01 = _mm_div_pd(abs2(n01), ratioV);
            n23 = _mm_div_pd(abs2(n23), ratioV);
        }
        sum01 = _mm_add_pd(sum01, n01);
        sum23 = _mm_add_pd(sum23, n23);

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

    _mm_storeu_pd(sums, sum01);
    _mm_storeu_pd(sums + 2, sum23);
}

static inline jint packPixel(const double sums[4], const bool fractal) {
    jint comps[4];
    for (int ch = 0; ch < 4; ++ch) {
        const double finalVal = fractal ? (sums[ch] + 1.0) * 127.5 : sums[ch] * 255.0;
        jint iv = static_cast<jint>(std::floor(finalVal + 0.5));
        if (iv < 0) iv = 0;
        else if (iv > 255) iv = 255;
        comps[ch] = iv;
    }
    return (comps[3] << 24) | (comps[0] << 16) | (comps[1] << 8) | comps[2];
}

} // namespace

extern "C" {

void applySsse3(
        jint* pixels, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jdouble baseFrequencyX, jdouble baseFrequencyY,
        jint periodX, jint periodY, jint octaves, jboolean fractalNoise,
        jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop,
        jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        jint seed) {
    (void) originX;
    (void) originY;

    LatticeTables tables;
    initLattice(tables, seed);
    std::memset(pixels, 0, static_cast<size_t>(width) * height * sizeof(jint));

    const bool stitchEnabled = periodX > 0 || periodY > 0;
    const bool fractal = fractalNoise == JNI_TRUE;

    for (jint y = clipTop; y < clipBottom; ++y) {
        const double userY = userTop + y * invCanvasScaleY;
        const double py0 = userY / unitSizeY * baseFrequencyY;
        const double tileY = static_cast<double>(y - clipTop);
        const jint rowOffset = y * width;

        for (jint x = clipLeft; x < clipRight; ++x) {
            const double userX = userLeft + x * invCanvasScaleX;
            const double px0 = userX / unitSizeX * baseFrequencyX;
            const double tileX = static_cast<double>(x - clipLeft);
            double sums[4];
            processPixelSsse3(tables, sums, px0, py0, tileX, tileY,
                    baseFrequencyX, baseFrequencyY, periodX, periodY,
                    octaves, fractal, stitchEnabled);
            pixels[rowOffset + x] = packPixel(sums, fractal);
        }
    }
}

} // extern "C"

#endif
