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
#include <cstring>

// feMorphology (erode/dilate) over unpremultiplied ARGB_8888 IntArrays.
//
// Bit-exact port of the Kotlin reference loop in FilterGeometry.kt:
// - min/max over ALL FOUR channels including alpha (SVG spec),
// - square footprint, out-of-bounds treated as transparent black:
//   dilation visits only clamped in-bounds taps (transparent black never wins
//   the max), erosion yields transparent black whenever the kernel reaches
//   outside the input,
// - only the clip region is written; everything outside stays transparent black.
//
// Acceleration (all ISAs): for output pixels whose window is fully interior,
// the tap fold runs on 16-byte vectors of raw pixel bytes (vmin/vmaxq_u8 NEON,
// _mm_min/max_epu8 SSE2). Every lane position maps to one fixed channel
// (chunks start on pixel boundaries: lane 0=B, 1=G, 2=R, 3=A), so integer
// min/max per lane is exactly the scalar per-channel min/max. Border pixels
// and short tails run the scalar reference loop.

namespace {

void applyScalarPixel(
        const jint* src, jint* dst, jint width, jint height,
        jint radiusX, jint radiusY, bool isErode, jint init,
        jint x, jint y) {
    const jint top = y - radiusY < 0 ? 0 : y - radiusY;
    const jint bottom = y + radiusY > height - 1 ? height - 1 : y + radiusY;
    const bool touchesTB = y - radiusY < 0 || y + radiusY > height - 1;
    const bool touchesLR = x - radiusX < 0 || x + radiusX > width - 1;

    // Erosion with an out-of-image kernel yields transparent black (spec);
    // dst is pre-filled with zero.
    if (isErode && (touchesTB || touchesLR)) {
        return;
    }

    jint a = init, r = init, g = init, b = init;
    const jint rowOffset = y * width;
    const jint left = touchesLR ? (x - radiusX < 0 ? 0 : x - radiusX) : x - radiusX;
    const jint right = touchesLR ? (x + radiusX > width - 1 ? width - 1 : x + radiusX) : x + radiusX;
    for (jint ky = top; ky <= bottom; ky++) {
        const jint kRowOffset = ky * width;
        for (jint kx = left; kx <= right; kx++) {
            const jint c = src[kRowOffset + kx];
            if (isErode) {
                const jint ca = (c >> 24) & 0xFF; if (ca < a) a = ca;
                const jint cr = (c >> 16) & 0xFF; if (cr < r) r = cr;
                const jint cg = (c >> 8) & 0xFF;  if (cg < g) g = cg;
                const jint cb = c & 0xFF;         if (cb < b) b = cb;
            } else {
                const jint ca = (c >> 24) & 0xFF; if (ca > a) a = ca;
                const jint cr = (c >> 16) & 0xFF; if (cr > r) r = cr;
                const jint cg = (c >> 8) & 0xFF;  if (cg > g) g = cg;
                const jint cb = c & 0xFF;         if (cb > b) b = cb;
            }
        }
    }
    dst[rowOffset + x] = (a << 24) | (r << 16) | (g << 8) | b;
}

void applyScalar(
        const jint* src, jint* dst, jint width, jint height,
        jint radiusX, jint radiusY, bool isErode, jint init,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom) {
    std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));
    for (jint y = clipTop; y < clipBottom; y++) {
        for (jint x = clipLeft; x < clipRight; x++) {
            applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
        }
    }
}

#ifdef MORPH_SIMD

#if defined(__ARM_NEON__) || defined(__ARM_NEON__)
#include <arm_neon.h>
using Vec = uint8x16_t;
inline Vec vecLoad(const jint* p) { return vld1q_u8(reinterpret_cast<const uint8_t*>(p)); }
inline Vec vecMin(Vec a, Vec b) { return vminq_u8(a, b); }
inline Vec vecMax(Vec a, Vec b) { return vmaxq_u8(a, b); }
inline Vec vecInit(jint v) { return vdupq_n_u8(static_cast<uint8_t>(v)); }
inline jint lane(Vec v, int i) { return static_cast<jint>(vgetq_lane_u8(v, i)); }
#else
#include <emmintrin.h>
using Vec = __m128i;
inline Vec vecLoad(const jint* p) { return _mm_loadu_si128(reinterpret_cast<const __m128i*>(p)); }
inline Vec vecMin(Vec a, Vec b) { return _mm_min_epu8(a, b); }
inline Vec vecMax(Vec a, Vec b) { return _mm_max_epu8(a, b); }
inline Vec vecInit(jint v) { return _mm_set1_epi8(static_cast<char>(v)); }
inline jint lane(Vec v, int i) { return _mm_cvtsi128_si32(_mm_srli_si128(v, i)) & 0xFF; }
#endif

/**
 * Interior pixel: window fully inside the image. Folds the square footprint
 * through 16-byte vectors; lane 0/1/2/3 hold B/G/R/A because chunks start on
 * pixel boundaries. Tail taps (< 4 px) run scalar.
 */
inline void applyVectorPixel(
        const jint* src, jint* dst, jint width,
        jint radiusX, jint radiusY, bool isErode, jint init, jint x, jint y) {
    const jint top = y - radiusY;
    const jint bottom = y + radiusY;
    const jint left = x - radiusX;
    const jint right = x + radiusX;

    Vec accMin = vecInit(isErode ? 255 : 0);
    Vec accMax = vecInit(0);

    for (jint ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        jint kx = left;
        for (; kx + 4 <= right + 1; kx += 4) {
            const Vec c = vecLoad(row + kx);
            accMin = vecMin(accMin, c);
            accMax = vecMax(accMax, c);
        }
        for (; kx <= right; kx++) {
            const Vec c = vecLoad(row + kx);
            accMin = vecMin(accMin, c);
            accMax = vecMax(accMax, c);
        }
    }

    const Vec acc = isErode ? accMin : accMax;
    const jint a = lane(acc, 3) & 0xFF;
    const jint r = lane(acc, 2) & 0xFF;
    const jint g = lane(acc, 1) & 0xFF;
    const jint b = lane(acc, 0) & 0xFF;
    (void) init;
    dst[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
}

#endif // MORPH_SIMD

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_MorphologyNative_apply(
        JNIEnv* env, jclass clazz,
        jintArray jSrc, jintArray jDst,
        jint width, jint height,
        jint radiusX, jint radiusY, jboolean erode,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom) {
    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) return;
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        return;
    }

    const bool isErode = erode == JNI_TRUE;
    const jint init = isErode ? 255 : 0;

    std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));

    const jint yLo = clipTop;
    const jint yHi = clipBottom;
    const jint xLo = clipLeft;
    const jint xHi = clipRight;

#ifdef MORPH_SIMD
    // Vectorize only fully-interior windows; borders go to the scalar path.
    const jint vyLo = yLo > radiusY ? yLo : radiusY;
    const jint vyHi = yHi < height - radiusY ? yHi : height - radiusY;
    const jint vxLo = xLo > radiusX ? xLo : radiusX;
    const jint vxHi = xHi < width - radiusX ? xHi : width - radiusX;

    for (jint y = yLo; y < vyLo; y++) {
        for (jint x = xLo; x < xHi; x++) {
            applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
        }
    }
    for (jint y = vyLo; y < vyHi; y++) {
        for (jint x = xLo; x < vxLo; x++) {
            applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
        }
        for (jint x = vxLo; x < vxHi; x++) {
            applyVectorPixel(src, dst, width, radiusX, radiusY, isErode, init, x, y);
        }
        for (jint x = vxHi; x < xHi; x++) {
            applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
        }
    }
    for (jint y = vyHi; y < yHi; y++) {
        for (jint x = xLo; x < xHi; x++) {
            applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
        }
    }
#else
    applyScalar(src, dst, width, height, radiusX, radiusY, isErode, init,
                clipLeft, clipTop, clipRight, clipBottom);
#endif

    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
