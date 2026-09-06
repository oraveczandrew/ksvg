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
#include <cassert>
#include <algorithm>
#include "cpu_dispatch.h"
#include "simd_x86.h"

#if defined(__aarch64__)
// Hand-written AArch64/AdvSIMD interior morphology pixel (morphology_neon64.S).
// Same precondition as applyVectorPixel below: the complete
// (2*radiusX+1)x(2*radiusY+1) window must lie inside the image. The init value
// (delta: 0 / erode: 255) is derived from `erode` internally.
extern "C" void ksvgMorphologyApplyPixelNeon64(
    const jint *src, jint *dst, jint width,
    jint radiusX, jint radiusY, jboolean erode,
    jint x, jint y);

// Row kernel: computes xStart..xEnd-1 output pixels of row y in one call so
// overlapping horizontal windows reuse the shared source reads. Requires that
// the whole spanned window lies inside the image. scratch must hold at least
// (xEnd - xStart) + 2*radiusX jints and is written over.
extern "C" void ksvgMorphologyApplyRowNeon64(
    const jint *src, jint *dst, jint width,
    jint radiusX, jint radiusY, jboolean erode,
    jint y, jint xStart, jint xEnd, jint *scratch);
#elif defined(__arm__)
// Hand-written ARM32/AdvSIMD interior morphology pixel (morphology_neon32.S).
extern "C" void ksvgMorphologyApplyPixelNeon32(
    const jint *src, jint *dst, jint width,
    jint radiusX, jint radiusY, jboolean erode,
    jint x, jint y);

// Row kernel for ARM32.
extern "C" void ksvgMorphologyApplyRowNeon32(
    const jint *src, jint *dst, jint width,
    jint radiusX, jint radiusY, jboolean erode,
    jint y, jint xStart, jint xEnd, jint *scratch);
#endif

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
        const jint *src, jint *dst, const jint width, const jint height,
        const jint radiusX, const jint radiusY, const bool isErode, const jint init,
        const jint x, const jint y) {
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
                    const jint ca = (c >> 24) & 0xFF;
                    if (ca < a) a = ca;
                    const jint cr = (c >> 16) & 0xFF;
                    if (cr < r) r = cr;
                    const jint cg = (c >> 8) & 0xFF;
                    if (cg < g) g = cg;
                    const jint cb = c & 0xFF;
                    if (cb < b) b = cb;
                } else {
                    const jint ca = (c >> 24) & 0xFF;
                    if (ca > a) a = ca;
                    const jint cr = (c >> 16) & 0xFF;
                    if (cr > r) r = cr;
                    const jint cg = (c >> 8) & 0xFF;
                    if (cg > g) g = cg;
                    const jint cb = c & 0xFF;
                    if (cb > b) b = cb;
                }
            }
        }
        dst[rowOffset + x] = (a << 24) | (r << 16) | (g << 8) | b;
    }

    void applyScalar(
        const jint *src, jint *dst, const jint width, const jint height,
        const jint radiusX, const jint radiusY, const bool isErode, const jint init,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom) {
        std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));
        for (jint y = clipTop; y < clipBottom; y++) {
            for (jint x = clipLeft; x < clipRight; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
    }

#ifndef MORPH_SIMD
#define MORPH_SIMD
#endif

#ifdef MORPH_SIMD

#if defined(__ARM_NEON__) || defined(__ARM_NEON)
#include <arm_neon.h>
    using Vec = uint8x16_t;
    inline Vec vecLoad(const jint *p) { return vld1q_u8(reinterpret_cast<const uint8_t *>(p)); }
    inline Vec vecMin(Vec a, Vec b) { return vminq_u8(a, b); }
    inline Vec vecMax(Vec a, Vec b) { return vmaxq_u8(a, b); }
    inline Vec vecInit(jint v) { return vreinterpretq_u8_s32(vdupq_n_s32(v)); }
    inline Vec vecInitByte(jint v) { return vdupq_n_u8(static_cast<uint8_t>(v)); }

    inline jint lane(Vec v, int i) {
        alignas(16) uint8_t bytes[16];
        vst1q_u8(bytes, v);
        return static_cast<jint>(bytes[i]);
    }
#else
#include <emmintrin.h>
    using Vec = __m128i;
    inline Vec vecLoad(const jint *p) { return _mm_loadu_si128(reinterpret_cast<const __m128i *>(p)); }
    inline Vec vecMin(Vec a, Vec b) { return _mm_min_epu8(a, b); }
    inline Vec vecMax(Vec a, Vec b) { return _mm_max_epu8(a, b); }
    inline Vec vecInit(jint v) { return _mm_set1_epi32(v); }
    inline Vec vecInitByte(jint v) { return _mm_set1_epi8(static_cast<char>(v)); }
    inline jint lane(Vec v, int i) {
        alignas(16) uint8_t bytes[16];
        _mm_storeu_si128(reinterpret_cast<__m128i *>(bytes), v);
        return static_cast<jint>(bytes[i]);
    }
#endif

    /**
     * Interior pixel: window fully inside the image. Folds the square footprint
     * through 16-byte vectors; lane 0/1/2/3 hold B/G/R/A because chunks start on
     * pixel boundaries. Tail taps (< 4 px) run scalar.
     */
    inline void applyVectorPixel(
        const jint *src, jint *dst, jint width,
        jint radiusX, jint radiusY, bool isErode, jint init, jint x, jint y) {
        const jint top = y - radiusY;
        const jint bottom = y + radiusY;
        const jint left = x - radiusX;
        const jint right = x + radiusX;

        Vec accMin = vecInitByte(isErode ? 255 : 0);
        Vec accMax = vecInitByte(0);

        for (jint ky = top; ky <= bottom; ky++) {
            const jint *row = src + ky * width;
            jint kx = left;
            for (; kx + 4 <= right + 1; kx += 4) {
                const Vec c = vecLoad(row + kx);
                accMin = vecMin(accMin, c);
                accMax = vecMax(accMax, c);
            }
            for (; kx <= right; kx++) {
                const jint c = row[kx];
                const Vec cv = vecInit(c);
                accMin = vecMin(accMin, cv);
                accMax = vecMax(accMax, cv);
            }
        }

        const Vec acc = isErode ? accMin : accMax;
        jint resA = 255, resR = 255, resG = 255, resB = 255;
        if (!isErode) {
            resA = 0;
            resR = 0;
            resG = 0;
            resB = 0;
        }

        for (int i = 0; i < 4; i++) {
            jint a = lane(acc, i * 4 + 3);
            jint r = lane(acc, i * 4 + 2);
            jint g = lane(acc, i * 4 + 1);
            jint b = lane(acc, i * 4 + 0);
            if (isErode) {
                resA = std::min(resA, a);
                resR = std::min(resR, r);
                resG = std::min(resG, g);
                resB = std::min(resB, b);
            } else {
                resA = std::max(resA, a);
                resR = std::max(resR, r);
                resG = std::max(resG, g);
                resB = std::max(resB, b);
            }
        }
        dst[y * width + x] = (resA << 24) | (resR << 16) | (resG << 8) | resB;
    }

#endif // MORPH_SIMD
} // namespace


// Validation/test-only: run an explicitly selected backend (see SimdBackend).
namespace {
    void runForced(const jint *src, jint *dst, jint width, jint height,
                   jint radiusX, jint radiusY, bool erode,
                   jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
                   jint backend) {
        const jint init = erode ? 255 : 0;
        std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));

        const jint yLo = clipTop;
        const jint yHi = clipBottom;
        const jint xLo = clipLeft;
        const jint xHi = clipRight;

        const jint vyLo = std::max(yLo, radiusY);
        const jint vyHi = std::min(yHi, height - radiusY);
        const jint vxLo = std::max(xLo, radiusX);
        const jint vxHi = std::min(xHi, width - radiusX);

        if (vyLo >= vyHi || vxLo >= vxHi) {
            for (jint y = yLo; y < yHi; y++) {
                for (jint x = xLo; x < xHi; x++) {
                    applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
                }
            }
            return;
        }

        for (jint y = yLo; y < vyLo; y++) {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
            }
        }
        for (jint y = vyLo; y < vyHi; y++) {
            for (jint x = xLo; x < vxLo; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
            }
            for (jint x = vxLo; x < vxHi; x++) {
#if defined(__aarch64__)
                if (backend == SIMD_BACKEND_SCALAR) {
                    applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
                } else {
                    assert(backend == SIMD_BACKEND_NEON64);
                    ksvgMorphologyApplyPixelNeon64(src, dst, width, radiusX, radiusY, erode, x, y);
                }
#elif defined(__arm__)
                if (backend == SIMD_BACKEND_SCALAR) {
                    applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
                } else {
                    assert(backend == SIMD_BACKEND_NEON32);
                    ksvgMorphologyApplyPixelNeon32(src, dst, width, radiusX, radiusY, erode, x, y);
                }
#elif defined(__i386__) || defined(__x86_64__)
                switch (backend) {
                    case SIMD_BACKEND_SCALAR:
                        applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
                        break;
                    case SIMD_BACKEND_SSE2:
                        ksvgMorphologyApplyPixelSse2(src, dst, width, radiusX, radiusY, erode, x, y);
                        break;
                    case SIMD_BACKEND_SSSE3:
                        applyVectorPixel(src, dst, width, radiusX, radiusY, erode, init, x, y);
                        break;
                    case SIMD_BACKEND_AVX2:
                        ksvgMorphologyApplyPixelAvx2(src, dst, width, radiusX, radiusY, erode, x, y);
                        break;
                    case SIMD_BACKEND_AVX512:
                        ksvgMorphologyApplyPixelAvx512(src, dst, width, radiusX, radiusY, erode, x, y);
                        break;
                    default:
                        assert(false && "unsupported forced morphology backend on x86");
                }
#else
                (void) backend;
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
#endif
            }
            for (jint x = vxHi; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
            }
        }
        for (jint y = vyHi; y < yHi; y++) {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, erode, init, x, y);
            }
        }
    }

    jint nativeBackendForAbi() {
        jint backends = SIMD_BACKEND_SCALAR;
#ifdef MORPH_SIMD
#if defined(__aarch64__)
        backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
        backends |= SIMD_BACKEND_NEON32;
#elif defined(__i386__) || defined(__x86_64__)
        backends |= SIMD_BACKEND_SSE2;
        backends |= SIMD_BACKEND_SSSE3;
        const SimdLevel level = detectSimdLevel();
        if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
        if (level >= SIMD_AVX512) backends |= SIMD_BACKEND_AVX512;
#endif
#endif
        return backends;
    }
} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_MorphologyNative_nativeBackend(
    JNIEnv *env, jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_MorphologyNative_applyForced(
    JNIEnv *env, jclass clazz,
    const jintArray jSrc, const jintArray jDst,
    const jint width, const jint height,
    const jint radiusX, const jint radiusY, const jboolean erode,
    const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
    const jint simdBackend) {
    auto *src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) return;
    auto *dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }

    runForced(src, dst, width, height, radiusX, radiusY, erode == JNI_TRUE,
              clipLeft, clipTop, clipRight, clipBottom, simdBackend);

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_MorphologyNative_applyForcedRow(
    JNIEnv *env, jclass clazz,
    const jintArray jSrc, const jintArray jDst,
    const jint width, const jint height,
    const jint radiusX, const jint radiusY, const jboolean erode,
    const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom) {
    auto *src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) return;
    auto *dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }

    std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));

#if defined(__aarch64__)
    // Row-kernel forced variant: scalar borders + row kernel on the interior.
    const jint yLo = clipTop;
    const jint yHi = clipBottom;
    const jint xLo = clipLeft;
    const jint xHi = clipRight;

    const jint vyLo = std::max(yLo, radiusY);
    const jint vyHi = std::min(yHi, height - radiusY);
    const jint vxLo = std::max(xLo, radiusX);
    const jint vxHi = std::min(xHi, width - radiusX);

    const bool isErode = erode == JNI_TRUE;
    const jint init = isErode ? 255 : 0;
    const jint span = vxHi - vxLo + 2 * radiusX;
    jint *spanBuf = span > 0 ? new jint[span] : nullptr;

    for (jint y = yLo; y < yHi; y++) {
        if (y >= vyLo && y < vyHi) {
            for (jint x = xLo; x < vxLo; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
            ksvgMorphologyApplyRowNeon64(src, dst, width, radiusX, radiusY, erode, y, vxLo, vxHi, spanBuf);
            for (jint x = vxHi; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        } else {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
    }
    delete[] spanBuf;
#elif defined(__arm__)
    const jint yLo = clipTop;
    const jint yHi = clipBottom;
    const jint xLo = clipLeft;
    const jint xHi = clipRight;

    const jint vyLo = std::max(yLo, radiusY);
    const jint vyHi = std::min(yHi, height - radiusY);
    const jint vxLo = std::max(xLo, radiusX);
    const jint vxHi = std::min(xHi, width - radiusX);

    const bool isErode = erode == JNI_TRUE;
    const jint init = isErode ? 255 : 0;
    const jint span = vxHi - vxLo + 2 * radiusX;
    jint *spanBuf = span > 0 ? new jint[span] : nullptr;

    for (jint y = yLo; y < yHi; y++) {
        if (y >= vyLo && y < vyHi) {
            for (jint x = xLo; x < vxLo; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
            ksvgMorphologyApplyRowNeon32(src, dst, width, radiusX, radiusY, erode, y, vxLo, vxHi, spanBuf);
            for (jint x = vxHi; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        } else {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
    }
    delete[] spanBuf;
#elif defined(__i386__) || defined(__x86_64__)
    const jint yLo = clipTop;
    const jint yHi = clipBottom;
    const jint xLo = clipLeft;
    const jint xHi = clipRight;

    const jint vyLo = std::max(yLo, radiusY);
    const jint vyHi = std::min(yHi, height - radiusY);
    const jint vxLo = std::max(xLo, radiusX);
    const jint vxHi = std::min(xHi, width - radiusX);

    const bool isErode = erode == JNI_TRUE;
    const jint init = isErode ? 255 : 0;
    const jint span = vxHi - vxLo + 2 * radiusX;
    jint *spanBuf = span > 0 ? new jint[span] : nullptr;

    for (jint y = yLo; y < yHi; y++) {
        if (y >= vyLo && y < vyHi) {
            for (jint x = xLo; x < vxLo; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
            ksvgMorphologyApplyRowSse2(src, dst, width, radiusX, radiusY, erode, y, vxLo, vxHi, spanBuf);
            for (jint x = vxHi; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        } else {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
    }
    delete[] spanBuf;
#else
    runForced(src, dst, width, height, radiusX, radiusY, erode == JNI_TRUE,
              clipLeft, clipTop, clipRight, clipBottom, SIMD_BACKEND_SCALAR);
#endif

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_MorphologyNative_apply(
    JNIEnv *env, jclass clazz,
    const jintArray jSrc, const jintArray jDst,
    const jint width, const jint height,
    const jint radiusX, const jint radiusY, const jboolean erode,
    const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom) {
    auto *src = env->GetIntArrayElements(jSrc, nullptr);
    if (src == nullptr) return;
    auto *dst = env->GetIntArrayElements(jDst, nullptr);
    if (dst == nullptr) {
        env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
        return;
    }

    const bool isErode = erode == JNI_TRUE;
    const jint init = isErode ? 255 : 0;

#ifdef MORPH_SIMD
    const jint yLo = clipTop;
    const jint yHi = clipBottom;
    const jint xLo = clipLeft;
    const jint xHi = clipRight;

    // Vectorize only fully-interior windows; borders go to the scalar path.
    const jint vyLo = std::max(yLo, radiusY);
    const jint vyHi = std::min(yHi, height - radiusY);
    const jint vxLo = std::max(xLo, radiusX);
    const jint vxHi = std::min(xHi, width - radiusX);

    if (vyLo >= vyHi || vxLo >= vxHi) {
        for (jint y = yLo; y < yHi; y++) {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
    } else {
        for (jint y = yLo; y < vyLo; y++) {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }

#if defined(__i386__) || defined(__x86_64__)
        const SimdLevel level = detectSimdLevel();
#endif

        for (jint y = vyLo; y < vyHi; y++) {
            for (jint x = xLo; x < vxLo; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
#if defined(__aarch64__)
            // Row kernel for the whole interior run: header math (incl. the
            // byte-row-stride sign-extension) is hoisted out of the per-pixel
            // calls, and overlapping horizontal windows re-use a shared L1
            // scratch row instead of re-reading the same source bytes.
            const jint span = vxHi - vxLo + 2 * radiusX;
            jint *spanBuf = new jint[span];
            ksvgMorphologyApplyRowNeon64(src, dst, width, radiusX, radiusY, erode, y, vxLo, vxHi, spanBuf);
            delete[] spanBuf;
#elif defined(__arm__)
            const jint span = vxHi - vxLo + 2 * radiusX;
            jint *spanBuf = new jint[span];
            ksvgMorphologyApplyRowNeon32(src, dst, width, radiusX, radiusY, erode, y, vxLo, vxHi, spanBuf);
            delete[] spanBuf;
#elif defined(__i386__) || defined(__x86_64__)
            const SimdLevel level = detectSimdLevel();
            if (level < SIMD_AVX2) {
                const jint span = vxHi - vxLo + 2 * radiusX;
                jint *spanBuf = new jint[span];
                ksvgMorphologyApplyRowSse2(src, dst, width, radiusX, radiusY, erode, y, vxLo, vxHi, spanBuf);
                delete[] spanBuf;
            } else {
                for (jint x = vxLo; x < vxHi; x++) {
                    switch (level) {
                        case SIMD_AVX512:
                            ksvgMorphologyApplyPixelAvx512(src, dst, width, radiusX, radiusY, erode, x, y);
                            break;
                        case SIMD_AVX2:
                            ksvgMorphologyApplyPixelAvx2(src, dst, width, radiusX, radiusY, erode, x, y);
                            break;
                        default:
                            applyVectorPixel(src, dst, width, radiusX, radiusY, isErode, init, x, y);
                    }
                }
            }
#else
            for (jint x = vxLo; x < vxHi; x++) {
                applyVectorPixel(src, dst, width, radiusX, radiusY, isErode, init, x, y);
            }
#endif
            for (jint x = vxHi; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
        for (jint y = vyHi; y < yHi; y++) {
            for (jint x = xLo; x < xHi; x++) {
                applyScalarPixel(src, dst, width, height, radiusX, radiusY, isErode, init, x, y);
            }
        }
    }
#else
    applyScalar(src, dst, width, height, radiusX, radiusY, isErode, init,
                clipLeft, clipTop, clipRight, clipBottom);
#endif

    env->ReleaseIntArrayElements(jDst, dst, 0);
    env->ReleaseIntArrayElements(jSrc, src, JNI_ABORT);
}
