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
#if defined(__i386__) || defined(__x86_64__)
#include <immintrin.h>
#endif
#include <cmath>
#include <cstring>
#include "turbulence_tables.h"

#if defined(__i386__) || defined(__x86_64__)

namespace {

static inline __m256d lerp4(
        const __m256d u,
        const __m256d v,
        const double factor) {
    const __m256d f = _mm256_set1_pd(factor);
    return _mm256_add_pd(u, _mm256_mul_pd(f, _mm256_sub_pd(v, u)));
}

static inline __m256d abs4(const __m256d value) {
    const __m256i sign = _mm256_set1_epi64x(INT64_C(0x7fffffffffffffff));
    return _mm256_castsi256_pd(_mm256_and_si256(_mm256_castpd_si256(value), sign));
}

static inline __m256d noise4(
        const X86LatticeTables& t,
        const PixelGeometry& g) {
    const double* gx = &t.gradPackedX[g.b00][0];
    const double* gy = &t.gradPackedY[g.b00][0];
    const double* gx10 = &t.gradPackedX[g.b10][0];
    const double* gy10 = &t.gradPackedY[g.b10][0];
    const double* gx01 = &t.gradPackedX[g.b01][0];
    const double* gy01 = &t.gradPackedY[g.b01][0];
    const double* gx11 = &t.gradPackedX[g.b11][0];
    const double* gy11 = &t.gradPackedY[g.b11][0];

    const __m256d rx0 = _mm256_set1_pd(g.rx0);
    const __m256d rx1 = _mm256_set1_pd(g.rx1);
    const __m256d ry0 = _mm256_set1_pd(g.ry0);
    const __m256d ry1 = _mm256_set1_pd(g.ry1);

    const __m256d u = _mm256_add_pd(
            _mm256_mul_pd(rx0, _mm256_loadu_pd(gx)),
            _mm256_mul_pd(ry0, _mm256_loadu_pd(gy)));
    const __m256d v = _mm256_add_pd(
            _mm256_mul_pd(rx1, _mm256_loadu_pd(gx10)),
            _mm256_mul_pd(ry0, _mm256_loadu_pd(gy10)));
    const __m256d u2 = _mm256_add_pd(
            _mm256_mul_pd(rx0, _mm256_loadu_pd(gx01)),
            _mm256_mul_pd(ry1, _mm256_loadu_pd(gy01)));
    const __m256d v2 = _mm256_add_pd(
            _mm256_mul_pd(rx1, _mm256_loadu_pd(gx11)),
            _mm256_mul_pd(ry1, _mm256_loadu_pd(gy11)));

    const __m256d a = lerp4(u, v, g.sx);
    const __m256d b = lerp4(u2, v2, g.sx);
    return lerp4(a, b, g.sy);
}

static inline void processPixelAvx2(
        const X86LatticeTables& t,
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
    __m256d sum = _mm256_setzero_pd();
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
        __m256d n = noise4(t, g);
        if (fractal) {
            n = _mm256_div_pd(n, _mm256_set1_pd(ratio));
        } else {
            n = _mm256_div_pd(abs4(n), _mm256_set1_pd(ratio));
        }
        sum = _mm256_add_pd(sum, n);

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

    _mm256_storeu_pd(sums, sum);
}

static inline jint packTurbulencePixel(const double sums[4], const bool fractal) {
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

void applyAvx2(
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

    X86LatticeTables tables;
    initX86Tables(tables, seed);
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
            processPixelAvx2(tables, sums, px0, py0, tileX, tileY,
                    baseFrequencyX, baseFrequencyY, periodX, periodY,
                    octaves, fractal, stitchEnabled);
            pixels[rowOffset + x] = packTurbulencePixel(sums, fractal);
        }
    }
}

} // extern "C"

#endif
