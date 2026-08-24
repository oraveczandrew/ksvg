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

#ifndef KSVG_TURBULENCE_CORE_H
#define KSVG_TURBULENCE_CORE_H

#include <cmath>
#include <cstdint>

// Pure computational core of feTurbulence (SVG 1.1 section 15.25, adapted from
// Mozilla gfx SVGTurbulenceRenderer-inl.h). No JNI dependencies so it can be
// unit-tested off-device.

namespace {

constexpr int S_BSIZE = 0x100;
constexpr int S_BM = 0xff;

struct PnrRandom {
    int32_t last;
    explicit PnrRandom(int32_t seed) {
        if (seed <= 0) seed = -(seed % 2147483647 - 1) + 1;
        if (seed > 2147483646) seed = 2147483646;
        last = seed;
    }
    int32_t next() {
        // Park & Miller CACM 1988.
        const int32_t hi = last / 127773;
        const int32_t lo = last % 127773;
        int32_t r = 16807 * lo - 2836 * hi;
        if (r <= 0) r += 2147483647;
        last = r;
        return r;
    }
};

// Channel-packed lattice: gradX[i] = {gx_R, gx_G, gx_B, gx_A} of point i,
// gradY[i] likewise — one lookup serves all four channels (mozilla layout).
struct LatticeTables {
    uint8_t selector[S_BSIZE];
    float gradX[S_BSIZE][4];
    float gradY[S_BSIZE][4];
};

void initLattice(LatticeTables& t, const int32_t seed) {
    PnrRandom rand(seed);

    float gradient[4][S_BSIZE][2];
    for (int32_t ch = 0; ch < 4; ch++) {
        for (int32_t i = 0; i < S_BSIZE; i++) {
            float a, b;
            do {
                a = static_cast<float>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
                b = static_cast<float>(rand.next() % (S_BSIZE + S_BSIZE) - S_BSIZE) / S_BSIZE;
            } while (a == 0 && b == 0);
            const float s = std::sqrt(a * a + b * b);
            gradient[ch][i][0] = a / s;
            gradient[ch][i][1] = b / s;
        }
    }

    for (int32_t i = 0; i < S_BSIZE; i++) {
        t.selector[i] = static_cast<uint8_t>(i);
    }
    for (int32_t i = S_BSIZE - 1; i > 0; i--) {
        const int32_t j = rand.next() % S_BSIZE;
        const uint8_t tmp = t.selector[i];
        t.selector[i] = t.selector[j];
        t.selector[j] = tmp;
    }

    // Pack the four channel gradients of the same lattice point so a single
    // vector lookup serves all channels (channel order matches our ARGB byte
    // order: index 0=R .. 3=A).
    for (int32_t i = 0; i < S_BSIZE; i++) {
        const uint8_t j = t.selector[i];
        for (int ch = 0; ch < 4; ch++) {
            t.gradX[i][ch] = gradient[ch][j][0];
            t.gradY[i][ch] = gradient[ch][j][1];
        }
    }
}

struct StitchInfo {
    int32_t width = 0;
    int32_t height = 0;
    int32_t wrapX = 0;
    int32_t wrapY = 0;
};

// True mathematical modulo (result in [0, period)): a single subtraction is
// NOT enough - sample coordinates can be many periods in, and the leftover
// offset produced visible seams every period pixels.
inline int32_t wrapPeriod(int32_t v, const int32_t period) {
    v %= period;
    return v < 0 ? v + period : v;
}

inline void noise2(
        const LatticeTables& t,
        const double pxd, const double pyd,
        const StitchInfo& stitch, const bool stitchEnabled,
        float* out /* [4], channel order R,G,B,A */) {
    // Coordinates stay double until the integer part is wrapped (mask/period):
    // casting large un-wrapped values to float would quantize neighbouring
    // pixels onto the same sample point -> visible blocks.
    const double fxd = std::floor(pxd);
    const double fyd = std::floor(pyd);
    const int32_t b0xRaw = static_cast<int32_t>(fxd);
    const int32_t b0yRaw = static_cast<int32_t>(fyd);
    const float rx0 = static_cast<float>(pxd - fxd);
    const float ry0 = static_cast<float>(pyd - fyd);
    const float rx1 = rx0 - 1.0f;
    const float ry1 = ry0 - 1.0f;

    int32_t bx0 = b0xRaw, by0 = b0yRaw, bx1 = b0xRaw + 1, by1 = b0yRaw + 1;
    if (stitchEnabled && stitch.width > 0 && stitch.height > 0) {
        bx0 = wrapPeriod(bx0, stitch.width);
        bx1 = wrapPeriod(bx1, stitch.width);
        by0 = wrapPeriod(by0, stitch.height);
        by1 = wrapPeriod(by1, stitch.height);
    } else {
        bx0 &= S_BM; bx1 &= S_BM;
        by0 &= S_BM; by1 &= S_BM;
    }

    const uint8_t i = t.selector[bx0];
    const uint8_t j = t.selector[bx1];

    // Corner rows follow the CORNER's lattice x: A/B share bx0 (selector i),
    // C/D share bx1 (selector j). Mixing these breaks continuity at cell
    // borders (visible as blocky seams).
    const float* qax = t.gradX[(i + by0) & S_BM];
    const float* qay = t.gradY[(i + by0) & S_BM];
    const float* qbx = t.gradX[(j + by0) & S_BM];
    const float* qby = t.gradY[(j + by0) & S_BM];
    const float* qcx = t.gradX[(i + by1) & S_BM];
    const float* qcy = t.gradY[(i + by1) & S_BM];
    const float* qdx = t.gradX[(j + by1) & S_BM];
    const float* qdy = t.gradY[(j + by1) & S_BM];

    for (int ch = 0; ch < 4; ch++) {
        const float u = rx0 * qax[ch] + ry0 * qay[ch];
        const float v = rx1 * qbx[ch] + ry0 * qby[ch];
        const float w = rx0 * qcx[ch] + ry1 * qcy[ch];
        const float z = rx1 * qdx[ch] + ry1 * qdy[ch];

        const float sx = rx0 * rx0 * (3 - 2 * rx0);
        const float sy = ry0 * ry0 * (3 - 2 * ry0);
        const float ab = u + sx * (v - u);
        const float cd = w + sx * (z - w);
        out[ch] = ab + sy * (cd - ab);
    }
}

#if defined(__ARM_NEON__) || defined(__ARM_NEON__)
#include <arm_neon.h>

inline void noise2Vec(
        const LatticeTables& t,
        const double pxd, const double pyd,
        const StitchInfo& stitch, const bool stitchEnabled,
        float* out) {
    const double fxd = std::floor(pxd);
    const double fyd = std::floor(pyd);
    const int32_t b0xRaw = static_cast<int32_t>(fxd);
    const int32_t b0yRaw = static_cast<int32_t>(fyd);
    const float rx0 = static_cast<float>(pxd - fxd);
    const float ry0 = static_cast<float>(pyd - fyd);
    const float rx1 = rx0 - 1.0f;
    const float ry1 = ry0 - 1.0f;

    int32_t bx0 = b0xRaw, by0 = b0yRaw, bx1 = b0xRaw + 1, by1 = b0yRaw + 1;
    if (stitchEnabled && stitch.width > 0 && stitch.height > 0) {
        bx0 = wrapPeriod(bx0, stitch.width);
        bx1 = wrapPeriod(bx1, stitch.width);
        by0 = wrapPeriod(by0, stitch.height);
        by1 = wrapPeriod(by1, stitch.height);
    } else {
        bx0 &= S_BM; bx1 &= S_BM;
        by0 &= S_BM; by1 &= S_BM;
    }

    const uint8_t i = t.selector[bx0];
    const uint8_t j = t.selector[bx1];

    const float32x4_t vX0 = vdupq_n_f32(rx0);
    const float32x4_t vX1 = vdupq_n_f32(rx1);
    const float32x4_t vY0 = vdupq_n_f32(ry0);
    const float32x4_t vY1 = vdupq_n_f32(ry1);

    const float32x4_t u = vmlaq_f32(vmulq_f32(vX0, vld1q_f32(t.gradX[(i + by0) & S_BM])),
                                    vY0, vld1q_f32(t.gradY[(i + by0) & S_BM]));
    const float32x4_t v = vmlaq_f32(vmulq_f32(vX1, vld1q_f32(t.gradX[(j + by0) & S_BM])),
                                    vY0, vld1q_f32(t.gradY[(j + by0) & S_BM]));
    const float32x4_t w = vmlaq_f32(vmulq_f32(vX0, vld1q_f32(t.gradX[(i + by1) & S_BM])),
                                    vY1, vld1q_f32(t.gradY[(i + by1) & S_BM]));
    const float32x4_t z = vmlaq_f32(vmulq_f32(vX1, vld1q_f32(t.gradX[(j + by1) & S_BM])),
                                    vY1, vld1q_f32(t.gradY[(j + by1) & S_BM]));

    const float32x4_t sxCurve = vmulq_f32(vmulq_f32(vX0, vX0), vsubq_f32(vdupq_n_f32(3.f),
            vmulq_f32(vdupq_n_f32(2.f), vX0)));
    const float32x4_t syCurve = vmulq_f32(vmulq_f32(vY0, vY0), vsubq_f32(vdupq_n_f32(3.f),
            vmulq_f32(vdupq_n_f32(2.f), vY0)));

    const float32x4_t ab = vmlaq_f32(u, sxCurve, vsubq_f32(v, u));
    const float32x4_t cd = vmlaq_f32(w, sxCurve, vsubq_f32(z, w));
    vst1q_f32(out, vmlaq_f32(ab, syCurve, vsubq_f32(cd, ab)));
}
#elif defined(__SSE2__)
#include <emmintrin.h>

inline void noise2Vec(
        const LatticeTables& t,
        const double pxd, const double pyd,
        const StitchInfo& stitch, const bool stitchEnabled,
        float* out) {
    const double fxd = std::floor(pxd);
    const double fyd = std::floor(pyd);
    const int32_t b0xRaw = static_cast<int32_t>(fxd);
    const int32_t b0yRaw = static_cast<int32_t>(fyd);
    const float rx0 = static_cast<float>(pxd - fxd);
    const float ry0 = static_cast<float>(pyd - fyd);
    const float rx1 = rx0 - 1.0f;
    const float ry1 = ry0 - 1.0f;

    int32_t bx0 = b0xRaw, by0 = b0yRaw, bx1 = b0xRaw + 1, by1 = b0yRaw + 1;
    if (stitchEnabled && stitch.width > 0 && stitch.height > 0) {
        bx0 = wrapPeriod(bx0, stitch.width);
        bx1 = wrapPeriod(bx1, stitch.width);
        by0 = wrapPeriod(by0, stitch.height);
        by1 = wrapPeriod(by1, stitch.height);
    } else {
        bx0 &= S_BM; bx1 &= S_BM;
        by0 &= S_BM; by1 &= S_BM;
    }

    const uint8_t i = t.selector[bx0];
    const uint8_t j = t.selector[bx1];

    const __m128 vX0 = _mm_set1_ps(rx0);
    const __m128 vX1 = _mm_set1_ps(rx1);
    const __m128 vY0 = _mm_set1_ps(ry0);
    const __m128 vY1 = _mm_set1_ps(ry1);

    fprintf(stderr,"[vec] bx0=%d bx1=%d by0=%d by1=%d i=%d j=%d\n",bx0,bx1,by0,by1,i,j);
    const __m128 u = _mm_add_ps(_mm_mul_ps(vX0, _mm_loadu_ps(t.gradX[(i + by0) & S_BM])),
                                _mm_mul_ps(vY0, _mm_loadu_ps(t.gradY[(i + by0) & S_BM])));
    const __m128 v = _mm_add_ps(_mm_mul_ps(vX1, _mm_loadu_ps(t.gradX[(j + by0) & S_BM])),
                                _mm_mul_ps(vY0, _mm_loadu_ps(t.gradY[(j + by0) & S_BM])));
    const __m128 w = _mm_add_ps(_mm_mul_ps(vX0, _mm_loadu_ps(t.gradX[(i + by1) & S_BM])),
                                _mm_mul_ps(vY1, _mm_loadu_ps(t.gradY[(i + by1) & S_BM])));
    const __m128 z = _mm_add_ps(_mm_mul_ps(vX1, _mm_loadu_ps(t.gradX[(j + by1) & S_BM])),
                                _mm_mul_ps(vY1, _mm_loadu_ps(t.gradY[(j + by1) & S_BM])));

    const __m128 sxCurve = _mm_mul_ps(_mm_mul_ps(vX0, vX0), _mm_sub_ps(_mm_set1_ps(3.f),
            _mm_mul_ps(_mm_set1_ps(2.f), vX0)));
    const __m128 syCurve = _mm_mul_ps(_mm_mul_ps(vY0, vY0), _mm_sub_ps(_mm_set1_ps(3.f),
            _mm_mul_ps(_mm_set1_ps(2.f), vY0)));

    const __m128 ab = _mm_add_ps(u, _mm_mul_ps(sxCurve, _mm_sub_ps(v, u)));
    const __m128 cd = _mm_add_ps(w, _mm_mul_ps(sxCurve, _mm_sub_ps(z, w)));
    _mm_storeu_ps(out, _mm_add_ps(ab, _mm_mul_ps(syCurve, _mm_sub_ps(cd, ab))));
}
#endif

} // namespace

#endif // KSVG_TURBULENCE_CORE_H
