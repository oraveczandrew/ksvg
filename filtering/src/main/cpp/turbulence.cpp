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

#include "turbulence_core.h"



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
