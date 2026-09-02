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
#include <algorithm>
#include <cmath>

#if defined(__i386__) || defined(__x86_64__)

#include <immintrin.h>
#include "turbulence_tables.h"

namespace {

inline float getChannelValue(jint pixel, int channel) {
    switch (channel) {
        case 0: return ((pixel >> 16) & 0xFF) / 255.0f; // R
        case 1: return ((pixel >> 8) & 0xFF) / 255.0f;  // G
        case 2: return (pixel & 0xFF) / 255.0f;         // B
        default: return ((pixel >> 24) & 0xFF) / 255.0f; // A
    }
}

inline jint clamp255(float v) {
    // Kotlin roundToInt() for Float is Round Half Up: floor(v + 0.5f).
    int i = static_cast<int>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

void convolveScalarPixel(
        const jint* src, jint* dst, int width, int height,
        const float* kernel, int orderX, int orderY, int targetX, int targetY,
        float divisor, float bias, bool preserve, int x, int y) {
    float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
    for (int ky = 0; ky < orderY; ky++) {
        int sy = y + ky - targetY;
        if (sy < 0) sy = 0; else if (sy >= height) sy = height - 1;
        for (int kx = 0; kx < orderX; kx++) {
            int sx = x + kx - targetX;
            if (sx < 0) sx = 0; else if (sx >= width) sx = width - 1;
            int pixel = src[sy * width + sx];
            float w = kernel[ky * orderX + kx];
            r += static_cast<float>((pixel >> 16) & 0xFF) * w;
            g += static_cast<float>((pixel >> 8) & 0xFF) * w;
            b += static_cast<float>(pixel & 0xFF) * w;
            a += static_cast<float>((pixel >> 24) & 0xFF) * w;
        }
    }
    int outR = clamp255(r / divisor + bias * 255.f);
    int outG = clamp255(g / divisor + bias * 255.f);
    int outB = clamp255(b / divisor + bias * 255.f);
    int outA = preserve ? (src[y * width + x] >> 24) & 0xFF
                        : clamp255(a / divisor + bias * 255.f);
    dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

// Turbulence AVX2 helpers

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

void ksvgMorphologyApplyPixelAvx2(
        const jint* src, jint* dst, int width,
        int radiusX, int radiusY, jboolean erode,
        int x, int y) {
    bool isErode = erode == JNI_TRUE;
    int top = y - radiusY;
    int bottom = y + radiusY;
    int left = x - radiusX;
    int right = x + radiusX;

    __m256i acc = _mm256_set1_epi8(isErode ? -1 : 0);

    for (int ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        int kx = left;
        for (; kx + 8 <= right + 1; kx += 8) {
            __m256i c = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(row + kx));
            acc = isErode ? _mm256_min_epu8(acc, c) : _mm256_max_epu8(acc, c);
        }
        for (; kx <= right; kx++) {
            jint c = row[kx];
            __m256i cv = _mm256_set1_epi32(c);
            acc = isErode ? _mm256_min_epu8(acc, cv) : _mm256_max_epu8(acc, cv);
        }
    }

    alignas(32) uint8_t res[32];
    _mm256_storeu_si256(reinterpret_cast<__m256i*>(res), acc);

    uint8_t finalA = res[3], finalR = res[2], finalG = res[1], finalB = res[0];
    for (int i = 1; i < 8; i++) {
        if (isErode) {
            finalA = std::min(finalA, res[i * 4 + 3]);
            finalR = std::min(finalR, res[i * 4 + 2]);
            finalG = std::min(finalG, res[i * 4 + 1]);
            finalB = std::min(finalB, res[i * 4 + 0]);
        } else {
            finalA = std::max(finalA, res[i * 4 + 3]);
            finalR = std::max(finalR, res[i * 4 + 2]);
            finalG = std::max(finalG, res[i * 4 + 1]);
            finalB = std::max(finalB, res[i * 4 + 0]);
        }
    }
    dst[y * width + x] = (finalA << 24) | (finalR << 16) | (finalG << 8) | finalB;
}

void ksvgConvolveApplyInteriorAvx2(
        jint* dst, const jint* src, int width, int height,
        const float* kernel, int orderX, int orderY, int targetX, int targetY,
        float divisor, float bias, jboolean preserveAlpha) {
    bool preserve = preserveAlpha == JNI_TRUE;
    __m256 vDivisor = _mm256_set1_ps(divisor);
    __m256 vBias255 = _mm256_set1_ps(bias * 255.0f);
    __m256 vHalf = _mm256_set1_ps(0.5f);
    __m256i maskFF = _mm256_set1_epi32(0xFF);
    __m256i zero = _mm256_setzero_si256();
    __m256i c255 = _mm256_set1_epi32(255);

    int yLo = targetY;
    int yHi = height - orderY + 1 + targetY;
    int xLo = targetX;
    int xHi = width - orderX + 1 + targetX;

    for (int y = yLo; y < yHi; y++) {
        const int rowOffset = y * width;
        int x = 0;
        for (; x < xLo; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }
        for (; x + 8 <= xHi; x += 8) {
            __m256 accR = _mm256_setzero_ps();
            __m256 accG = _mm256_setzero_ps();
            __m256 accB = _mm256_setzero_ps();
            __m256 accA = _mm256_setzero_ps();

            for (int ky = 0; ky < orderY; ky++) {
                const jint* srcRow = src + (y + ky - targetY) * width + (x - targetX);
                for (int kx = 0; kx < orderX; kx++) {
                    __m256 w = _mm256_set1_ps(kernel[ky * orderX + kx]);
                    __m256i p = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(srcRow + kx));
                    accB = _mm256_add_ps(accB, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_and_si256(p, maskFF)), w));
                    accG = _mm256_add_ps(accG, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(p, 8), maskFF)), w));
                    accR = _mm256_add_ps(accR, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(p, 16), maskFF)), w));
                    accA = _mm256_add_ps(accA, _mm256_mul_ps(_mm256_cvtepi32_ps(_mm256_srli_epi32(p, 24)), w));
                }
            }

            // Using floor(v + 0.5) to match Kotlin's Round Half Up (roundToInt).
            auto roundRHU = [vDivisor, vBias255, vHalf](__m256 acc) {
                return _mm256_cvttps_epi32(_mm256_floor_ps(_mm256_add_ps(_mm256_add_ps(_mm256_div_ps(acc, vDivisor), vBias255), vHalf)));
            };

            __m256i iR = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accR), zero), c255);
            __m256i iG = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accG), zero), c255);
            __m256i iB = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accB), zero), c255);
            __m256i iA;

            if (preserve) {
                iA = _mm256_srli_epi32(_mm256_loadu_si256(reinterpret_cast<const __m256i*>(src + rowOffset + x)), 24);
            } else {
                iA = _mm256_min_epi32(_mm256_max_epi32(roundRHU(accA), zero), c255);
            }

            __m256i out = _mm256_or_si256(_mm256_or_si256(_mm256_slli_epi32(iA, 24), _mm256_slli_epi32(iR, 16)),
                                         _mm256_or_si256(_mm256_slli_epi32(iG, 8), iB));
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + rowOffset + x), out);
        }
        for (; x < width; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY, targetX, targetY, divisor, bias, preserve, x, y);
        }
    }
}

void ksvgBlurVerticalAvx2(void* dst, const void* pin, int stride, const void* gptr, int rct, int x1, int x2) {
    extern void rsdIntrinsicBlurVFU4_K(void*, const void*, int, const void*, int, int, int);
    rsdIntrinsicBlurVFU4_K(dst, pin, stride, gptr, rct, x1, x2);
}

void ksvgComponentTransferApplyAvx2(
        const jint* src, jint* dst, int width, int height,
        int clipLeft, int clipTop, int clipRight, int clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    for (int y = clipTop; y < clipBottom; y++) {
        const int rowOffset = y * width;
        int x = clipLeft;
        for (; x + 8 <= clipRight; x += 8) {
            __m256i p = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(src + rowOffset + x));
            alignas(32) jint pixels[8];
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(pixels), p);
            alignas(32) jint res[8];
            for (int i = 0; i < 8; i++) {
                jint c = pixels[i];
                res[i] = ((static_cast<jint>(tableA[(c >> 24) & 0xFF]) & 0xFF) << 24) |
                         ((static_cast<jint>(tableR[(c >> 16) & 0xFF]) & 0xFF) << 16) |
                         ((static_cast<jint>(tableG[(c >> 8) & 0xFF]) & 0xFF) << 8) |
                         (static_cast<jint>(tableB[c & 0xFF]) & 0xFF);
            }
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + rowOffset + x), _mm256_loadu_si256(reinterpret_cast<const __m256i*>(res)));
        }
        for (; x < clipRight; x++) {
            jint c = src[rowOffset + x];
            dst[rowOffset + x] = ((static_cast<jint>(tableA[(c >> 24) & 0xFF]) & 0xFF) << 24) |
                                 ((static_cast<jint>(tableR[(c >> 16) & 0xFF]) & 0xFF) << 16) |
                                 ((static_cast<jint>(tableG[(c >> 8) & 0xFF]) & 0xFF) << 8) |
                                 (static_cast<jint>(tableB[c & 0xFF]) & 0xFF);
        }
    }
}

// One 16-byte LUT row duplicated into both AVX2 128-bit lanes so the per-lane
// pshufb selects correctly for every byte of the 32-byte register.
static inline __m256i lutRowBroadcast256(const jbyte* table, int row) {
    const __m128i v = _mm_loadu_si128(
            reinterpret_cast<const __m128i*>(table + row * 16));
    return _mm256_broadcastsi128_si256(v);
}

// Genuinely vectorized 256-entry LUT lookup over the 32 bytes (8 pixels) of an
// AVX2 register using the 16-row pshufb scheme (entry = rows[hi][lo]). Because
// every byte is looked up in the SAME table, the whole register is transformed
// in one pass — no channel plane extraction or re-interleaving needed.
static inline __m256i lut256Avx2(__m256i value, const __m256i rows[16]) {
    const __m256i loMask = _mm256_set1_epi8(0x0f);
    const __m256i lo = _mm256_and_si256(value, loMask);
    const __m256i hi = _mm256_and_si256(_mm256_srli_epi16(value, 4), loMask);

    __m256i result = _mm256_setzero_si256();
    for (int row = 0; row < 16; ++row) {
        const __m256i candidate = _mm256_shuffle_epi8(rows[row], lo);
        const __m256i selected =
                _mm256_cmpeq_epi8(hi, _mm256_set1_epi8(static_cast<char>(row)));
        result = _mm256_or_si256(result, _mm256_and_si256(candidate, selected));
    }
    return result;
}

void ksvgUnlinearizeApplyAvx2(
        const jint* src, jint* dst, int width, int height, const jbyte* table) {
    const int total = width * height;

    // rows[i] = table[i*16..i*16+15] duplicated into both AVX2 lanes.
    __m256i rows[16];
    for (int i = 0; i < 16; ++i) {
        rows[i] = lutRowBroadcast256(table, i);
    }

    // 0xff in the alpha byte positions (offset 3, 7, 11, 15, 19, 23, 27, 31),
    // i.e. one per pixel across the 8 pixels of the 32-byte register.
    const __m256i alphaMaskBytes = _mm256_setr_epi8(
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1,
            0, 0, 0, -1);

    int i = 0;
    for (; i + 8 <= total; i += 8) {
        const __m256i p = _mm256_loadu_si256(
                reinterpret_cast<const __m256i*>(src + i));

        // Every byte (B/G/R/A) is mapped by the shared LUT in one pass.
        const __m256i transformed = lut256Avx2(p, rows);

        // Restore the original alpha bytes (their transformed value is discarded).
        const __m256i out = _mm256_or_si256(
                _mm256_andnot_si256(alphaMaskBytes, transformed),
                _mm256_and_si256(alphaMaskBytes, p));

        _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + i), out);
    }

    // Scalar tail for the remainder that does not fit the SIMD width.
    for (; i < total; ++i) {
        const jint c = src[i];
        dst[i] = (c & 0xff000000) |
                 (static_cast<jint>(static_cast<uint8_t>(table[(c >> 16) & 0xff])) << 16) |
                 (static_cast<jint>(static_cast<uint8_t>(table[(c >> 8) & 0xff])) << 8) |
                 static_cast<jint>(static_cast<uint8_t>(table[c & 0xff]));
    }
}

void ksvgDisplacementMapApplyAvx2(
        const jint* src, const jint* map, jint* dst, int width, int height,
        float scale, int xChannel, int yChannel) {
    __m256 vScale = _mm256_set1_ps(scale);
    __m256 vHalf = _mm256_set1_ps(0.5f);
    __m256 v255 = _mm256_set1_ps(255.0f);
    __m256i maskFF = _mm256_set1_epi32(0xFF);
    __m256i vWidthMinus1 = _mm256_set1_epi32(width - 1);
    __m256i vHeightMinus1 = _mm256_set1_epi32(height - 1);
    __m256i vZero = _mm256_setzero_si256();
    __m256i vWidth = _mm256_set1_epi32(width);

    int xs = xChannel == 0 ? 16 : xChannel == 1 ? 8 : xChannel == 2 ? 0 : 24;
    int ys = yChannel == 0 ? 16 : yChannel == 1 ? 8 : yChannel == 2 ? 0 : 24;

    for (int y = 0; y < height; y++) {
        const int rowOffset = y * width;
        __m256i vY = _mm256_set1_epi32(y);
        int x = 0;
        for (; x + 8 <= width; x += 8) {
            __m256i vX = _mm256_add_epi32(_mm256_set1_epi32(x), _mm256_setr_epi32(0, 1, 2, 3, 4, 5, 6, 7));
            __m256i mapPixels = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(map + rowOffset + x));

            __m256 vx = _mm256_div_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(mapPixels, xs), maskFF)), v255);
            __m256 vy = _mm256_div_ps(_mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(mapPixels, ys), maskFF)), v255);

            __m256i idx = _mm256_cvttps_epi32(_mm256_mul_ps(vScale, _mm256_sub_ps(vx, vHalf)));
            __m256i idy = _mm256_cvttps_epi32(_mm256_mul_ps(vScale, _mm256_sub_ps(vy, vHalf)));

            __m256i sx = _mm256_max_epi32(vZero, _mm256_min_epi32(_mm256_add_epi32(vX, idx), vWidthMinus1));
            __m256i sy = _mm256_max_epi32(vZero, _mm256_min_epi32(_mm256_add_epi32(vY, idy), vHeightMinus1));

            __m256i indices = _mm256_add_epi32(_mm256_mullo_epi32(sy, vWidth), sx);
            __m256i res = _mm256_i32gather_epi32(src, indices, 4);
            _mm256_storeu_si256(reinterpret_cast<__m256i*>(dst + rowOffset + x), res);
        }
        for (; x < width; x++) {
            jint mapPixel = map[rowOffset + x];
            int dx = (int)(scale * (getChannelValue(mapPixel, xChannel) - 0.5f));
            int dy = (int)(scale * (getChannelValue(mapPixel, yChannel) - 0.5f));
            int sx = std::max(0, std::min(width - 1, x + dx));
            int sy = std::max(0, std::min(height - 1, y + dy));
            dst[rowOffset + x] = src[sy * width + sx];
        }
    }
}

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
