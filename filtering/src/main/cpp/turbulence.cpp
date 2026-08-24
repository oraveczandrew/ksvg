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

// feTurbulence — SVG 1.1 §15.25 reference algorithm, adapted from Mozilla gfx
// SVGTurbulenceRenderer-inl.h (MPL-2.0, vendored under tmp/turbulence/).
//
// Differences from the vendored source, all dictated by our pipeline:
//  - output is written as UNPREMULTIPLIED ARGB_8888 ints (Bitmap.getPixels/
//    setPixels domain) instead of premultiplied B8G8R8A8 bytes;
//  - only the clip region is written, everything else stays transparent black;
//  - sampling coordinates arrive pre-mapped by the caller (the Kotlin layer
//    owns user-space -> primitive-unit -> frequency mapping and stitch
//    frequency adjustment); this TU receives the final per-axis frequency and
//    the lattice periods.
//
// Architecture strategy: like the vendored source, the SIMD axis is the four
// COLOR CHANNELS of one pixel (one f32x4 lane per channel), not adjacent
// pixels — the lattice lookups would require gathers across pixels. Therefore
// there is exactly one wide path per ISA family:
//   - ARM (armv7 NEON + AArch64): float32x4_t
//   - x86 (SSE2 baseline and up; wider ISAs cannot exceed the 4-channel width)
// plus a portable scalar reference. All paths perform identical operations in
// the same order; results agree because each lane is independent.
//
// State: the lattice tables are rebuilt per call on the stack (~10 KB) — no
// shared/global mutable state.

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

    const float* qax = t.gradX[(i + by0) & S_BM];
    const float* qay = t.gradY[(i + by0) & S_BM];
    const float* qbx = t.gradX[(i + by1) & S_BM];
    const float* qby = t.gradY[(i + by1) & S_BM];
    const float* qcx = t.gradX[(j + by0) & S_BM];
    const float* qcy = t.gradY[(j + by0) & S_BM];
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
    const float32x4_t v = vmlaq_f32(vmulq_f32(vX1, vld1q_f32(t.gradX[(i + by1) & S_BM])),
                                    vY0, vld1q_f32(t.gradY[(i + by1) & S_BM]));
    const float32x4_t w = vmlaq_f32(vmulq_f32(vX0, vld1q_f32(t.gradX[(j + by0) & S_BM])),
                                    vY1, vld1q_f32(t.gradY[(j + by0) & S_BM]));
    const float32x4_t z = vmlaq_f32(vmulq_f32(vX1, vld1q_f32(t.gradX[(j + by1) & S_BM])),
                                    vY1, vld1q_f32(t.gradY[(j + by1) & S_BM]));

    const float32x4_t sxCurve = vmulq_f32(vX0, vsubq_f32(vdupq_n_f32(3.f),
            vmulq_f32(vdupq_n_f32(2.f), vX0)));
    const float32x4_t syCurve = vmulq_f32(vY0, vsubq_f32(vdupq_n_f32(3.f),
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

    const __m128 u = _mm_add_ps(_mm_mul_ps(vX0, _mm_loadu_ps(t.gradX[(i + by0) & S_BM])),
                                _mm_mul_ps(vY0, _mm_loadu_ps(t.gradY[(i + by0) & S_BM])));
    const __m128 v = _mm_add_ps(_mm_mul_ps(vX1, _mm_loadu_ps(t.gradX[(i + by1) & S_BM])),
                                _mm_mul_ps(vY0, _mm_loadu_ps(t.gradY[(i + by1) & S_BM])));
    const __m128 w = _mm_add_ps(_mm_mul_ps(vX0, _mm_loadu_ps(t.gradX[(j + by0) & S_BM])),
                                _mm_mul_ps(vY1, _mm_loadu_ps(t.gradY[(j + by0) & S_BM])));
    const __m128 z = _mm_add_ps(_mm_mul_ps(vX1, _mm_loadu_ps(t.gradX[(j + by1) & S_BM])),
                                _mm_mul_ps(vY1, _mm_loadu_ps(t.gradY[(j + by1) & S_BM])));

    const __m128 sxCurve = _mm_mul_ps(vX0, _mm_sub_ps(_mm_set1_ps(3.f),
            _mm_mul_ps(_mm_set1_ps(2.f), vX0)));
    const __m128 syCurve = _mm_mul_ps(vY0, _mm_sub_ps(_mm_set1_ps(3.f),
            _mm_mul_ps(_mm_set1_ps(2.f), vY0)));

    const __m128 ab = _mm_add_ps(u, _mm_mul_ps(sxCurve, _mm_sub_ps(v, u)));
    const __m128 cd = _mm_add_ps(w, _mm_mul_ps(sxCurve, _mm_sub_ps(z, w)));
    _mm_storeu_ps(out, _mm_add_ps(ab, _mm_mul_ps(syCurve, _mm_sub_ps(cd, ab))));
}
#endif

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_TurbulenceNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jPixels,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jdouble baseFrequencyX, const jdouble baseFrequencyY,
        const jint periodX, const jint periodY,
        const jint octaves, const jboolean fractalNoise,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jint seed) {
    auto* pixels = static_cast<jint*>(env->GetPrimitiveArrayCritical(jPixels, nullptr));
    if (pixels == nullptr) return;

    LatticeTables tables;
    initLattice(tables, seed);

    // Transparent outside the clip.
    std::memset(pixels, 0, static_cast<size_t>(width) * height * sizeof(jint));

    const bool stitchEnabled = periodX > 0 && periodY > 0;
    StitchInfo stitch;
    stitch.width = periodX;
    stitch.height = periodY;
    stitch.wrapX = periodX;
    stitch.wrapY = periodY;

    const bool fractal = fractalNoise == JNI_TRUE;

    for (jint y = clipTop; y < clipBottom; y++) {
        const jdouble userY = userTop + y * invCanvasScaleY;
        const jdouble py0 = (userY - originY) / unitSizeY * baseFrequencyY;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jdouble userX = userLeft + x * invCanvasScaleX;
            const jdouble px0 = (userX - originX) / unitSizeX * baseFrequencyX;

            float sums[4] = {0.f, 0.f, 0.f, 0.f};
            StitchInfo si = stitch;
            float ratio = 1.f;
            double fx = px0;
            double fy = py0;

            for (jint octave = 0; octave < octaves; octave++) {
                float noise[4];
#if defined(__ARM_NEON__) || defined(__ARM_NEON__) || defined(__SSE2__)
                noise2Vec(tables, fx, fy, si, stitchEnabled, noise);
#else
                noise2(tables, fx, fy, si, stitchEnabled, noise);
#endif
                if (fractal) {
                    sums[0] += noise[0] / ratio;
                    sums[1] += noise[1] / ratio;
                    sums[2] += noise[2] / ratio;
                    sums[3] += noise[3] / ratio;
                } else {
                    sums[0] += std::abs(noise[0]) / ratio;
                    sums[1] += std::abs(noise[1]) / ratio;
                    sums[2] += std::abs(noise[2]) / ratio;
                    sums[3] += std::abs(noise[3]) / ratio;
                }
                fx *= 2.f;
                fy *= 2.f;
                ratio *= 2.f;
                if (stitchEnabled) {
                    si.width *= 2; si.wrapX *= 2;
                    si.height *= 2; si.wrapY *= 2;
                }
            }

            jint comps[4];
            for (int ch = 0; ch < 4; ch++) {
                const float finalVal = fractal ? (sums[ch] + 1.0f) * 127.5f : sums[ch] * 255.0f;
                jint iv = static_cast<jint>(finalVal + 0.5f);
                if (iv < 0) iv = 0; else if (iv > 255) iv = 255;
                comps[ch] = iv;
            }
            pixels[y * width + x] =
                    (comps[3] << 24) | (comps[0] << 16) | (comps[1] << 8) | comps[2];
        }
    }

    env->ReleasePrimitiveArrayCritical(jPixels, pixels, JNI_ABORT);
}
