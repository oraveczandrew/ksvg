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
// State: the lattice tables are rebuilt per call on the stack (~10 KB) — no
// shared/global mutable state. Scalar float32 implementation; a 4-pixel-wide
// SIMD variant can replace the inner loop later without changing semantics.

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

struct LatticeTables {
    uint8_t selector[S_BSIZE];
    float gradient[S_BSIZE][4][2];
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

    // Pack the four channel gradients of the same lattice point into one
    // float4 so a single lookup serves all channels (channel order matches
    // our ARGB byte order: index 0=R .. 3=A).
    for (int32_t i = 0; i < S_BSIZE; i++) {
        const uint8_t j = t.selector[i];
        for (int ch = 0; ch < 4; ch++) {
            t.gradient[i][ch][0] = gradient[ch][j][0];
            t.gradient[i][ch][1] = gradient[ch][j][1];
        }
    }
}

struct StitchInfo {
    int32_t width = 0;
    int32_t height = 0;
    int32_t wrapX = 0;
    int32_t wrapY = 0;
};

inline int32_t adjustForStitch(const int32_t v, const int32_t wrap, const int32_t period) {
    return v >= wrap ? v - period : v;
}

/**
 * One noise evaluation for all four channels at integer lattice coords.
 */
void noise2(
        const LatticeTables& t,
        const float px, const float py,
        const StitchInfo& stitch, const bool stitchEnabled,
        float* out /* [4], channel order R,G,B,A */) {
    const int32_t b0xRaw = static_cast<int32_t>(std::floor(px));
    const int32_t b0yRaw = static_cast<int32_t>(std::floor(py));
    const float rx0 = px - static_cast<float>(b0xRaw);
    const float ry0 = py - static_cast<float>(b0yRaw);
    const float rx1 = rx0 - 1.0f;
    const float ry1 = ry0 - 1.0f;

    int32_t bx0 = b0xRaw, by0 = b0yRaw, bx1 = b0xRaw + 1, by1 = b0yRaw + 1;
    if (stitchEnabled && stitch.width > 0 && stitch.height > 0) {
        bx0 = adjustForStitch(bx0, stitch.wrapX, stitch.width);
        bx1 = adjustForStitch(bx1, stitch.wrapX, stitch.width);
        by0 = adjustForStitch(by0, stitch.wrapY, stitch.height);
        by1 = adjustForStitch(by1, stitch.wrapY, stitch.height);
    } else {
        bx0 &= S_BM; bx1 &= S_BM;
        by0 &= S_BM; by1 &= S_BM;
    }

    const uint8_t i = t.selector[bx0];
    const uint8_t j = t.selector[bx1];

    for (int ch = 0; ch < 4; ch++) {
        const float* qa = t.gradient[i + by0 & S_BM][ch];
        const float* qb = t.gradient[i + by1 & S_BM][ch];
        const float* qc = t.gradient[j + by0 & S_BM][ch];
        const float* qd = t.gradient[j + by1 & S_BM][ch];

        const float u = rx0 * qa[0] + ry0 * qa[1];
        const float v = rx1 * qb[0] + ry0 * qb[1];
        const float w = rx0 * qc[0] + ry1 * qc[1];
        const float z = rx1 * qd[0] + ry1 * qd[1];

        // SCurve + bilinear mix.
        const float sx = rx0 * rx0 * (3 - 2 * rx0);
        const float sy = ry0 * ry0 * (3 - 2 * ry0);
        const float ab = u + sx * (v - u);
        const float cd = w + sx * (z - w);
        out[ch] = ab + sy * (cd - ab);
    }
}

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
    // Wrap period doubles per octave (matches the spec's stitch doubling).
    const StitchInfo octaveStitchBase = stitch;

    for (jint y = clipTop; y < clipBottom; y++) {
        const jdouble userY = userTop + y * invCanvasScaleY;
        const jdouble py0 = (userY - originY) / unitSizeY * baseFrequencyY;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jdouble userX = userLeft + x * invCanvasScaleX;
            const jdouble px0 = (userX - originX) / unitSizeX * baseFrequencyX;

            float sums[4] = {0.f, 0.f, 0.f, 0.f};
            StitchInfo si = octaveStitchBase;
            float ratio = 1.f;
            float fx = static_cast<float>(px0);
            float fy = static_cast<float>(py0);

            for (jint octave = 0; octave < octaves; octave++) {
                float noise[4];
                noise2(tables, fx, fy, si, stitchEnabled, noise);
                for (int ch = 0; ch < 4; ch++) {
                    const float n = fractal ? noise[ch] : std::abs(noise[ch]);
                    sums[ch] += n / ratio;
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
