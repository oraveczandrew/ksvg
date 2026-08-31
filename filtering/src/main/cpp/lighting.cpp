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

// feDiffuseLighting / feSpecularLighting over unpremultiplied ARGB_8888
// IntArrays. Bit-exact port of the Kotlin reference loop in
// FilterLighting.kt: 3x3 Sobel surface gradients from the alpha heightmap,
// per-pixel light vector (distant / point / spot incl. cone attenuation),
// float math in the same order, specular intensity via double pow.
//
// Light parameter packing (params[8]):
//   distant (0): [0]=azimuthDeg [1]=elevationDeg
//   point   (1): [0..2]=x,y,z
//   spot    (2): [0..2]=x,y,z [3..5]=pointsAtX,Y,Z [6]=limitingConeAngleDeg
//                 (NaN = no cone)
//
// Vectorization: the heavy common part (3x3 Sobel + surface normal) runs on
// 4-pixel f32 vectors (NEON + SSE2) for every light type, from a per-row
// clamped height buffer. With a distant light the whole pixel loop is
// vectorized (constant light vector); point/spot keep their per-pixel
// light-vector + cone math scalar (double cone check, degenerate lanes) on
// top of the vector normals; specular pow stays per-lane scalar. Wider ISAs
// (AVX2/512) would not help much: the kernel is sqrt/div-bound.

namespace {

constexpr jint kMaxVecRowSpan = 4096; // stack height-buffer limit (floats)

 jint clamp255f(const float v) {
    const jint i = static_cast<jint>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

 float heightAt(const jint* pix, const jint width, const jint height, const jint x, const jint y, const float ss) {
    const jint cx = x < 0 ? 0 : (x > width - 1 ? width - 1 : x);
    const jint cy = y < 0 ? 0 : (y > height - 1 ? height - 1 : y);
    return static_cast<float>((pix[cy * width + cx] >> 24) & 0xff) * ss;
}

 float clamp01(const float v) { return v < 0.f ? 0.f : (v > 1.f ? 1.f : v); }

// sRGB<->linear per-component folding, bit-exact with KotlinKernels.sRgbToLinear /
// linearToSRgb (and ColorUtils), used when color-interpolation-filters is linearRGB.
 jint sRgbToLight(const jint c) {
    const float a = static_cast<float>(c) / 255.f;
    const float v = (a <= 0.04045f) ? (a / 12.92f * 255.f)
                                    : (std::pow((a + 0.055f) / 1.055f, 2.4f) * 255.f);
    return clamp255f(v);
}

 jint linearToLightSRgb(const jint c) {
    const float a = static_cast<float>(c) / 255.f;
    const float v = (a <= 0.0031308f) ? (a * 12.92f * 255.f)
                                      : ((1.055f * std::pow(a, 1.f / 2.4f) - 0.055f) * 255.f);
    return clamp255f(v);
}

void applyScalar(
        jint* pix, jint* out, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        float ss, jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop, jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        float canvasScaleX, float canvasScaleY,
        jint lightType, bool isSpecular, float k, float exponent,
        float fr, float fg, float fb, const jdouble* params,
        bool premultiplied, bool useLinear) {
    const float lr = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fr))) : fr;
    const float lg = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fg))) : fg;
    const float lb = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fb))) : fb;
    for (jint y = clipTop; y < clipBottom; y++) {
        const jdouble userY = userTop + y * invCanvasScaleY;
        const auto uy = static_cast<float>((userY - originY) / unitSizeY);
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jdouble userX = userLeft + x * invCanvasScaleX;
            const auto ux = static_cast<float>((userX - originX) / unitSizeX);
            const float surfaceZ = heightAt(pix, width, height, x, y, ss);

            float lx, ly, lz, factor;
            if (lightType == 0) {
                const double az = params[0] * M_PI / 180.0;
                const double el = params[1] * M_PI / 180.0;
                lx = static_cast<float>(std::cos(az) * std::cos(el));
                ly = static_cast<float>(std::sin(az) * std::cos(el));
                lz = static_cast<float>(std::sin(el));
                factor = 1.f;
            } else if (lightType == 1) {
                const float vx = static_cast<float>(params[0]) - ux;
                const float vy = static_cast<float>(params[1]) - uy;
                const float vz = static_cast<float>(params[2]) - surfaceZ;
                const float len = std::sqrt(vx * vx + vy * vy + vz * vz);
                if (len == 0.f) { lx = 0.f; ly = 0.f; lz = 0.f; factor = 0.f; }
                else { lx = vx / len; ly = vy / len; lz = vz / len; factor = 1.f; }
            } else {
                const float vx = static_cast<float>(params[0]) - ux;
                const float vy = static_cast<float>(params[1]) - uy;
                const float vz = static_cast<float>(params[2]) - surfaceZ;
                const float len = std::sqrt(vx * vx + vy * vy + vz * vz);
                if (len == 0.f) { lx = 0.f; ly = 0.f; lz = 0.f; factor = 0.f; }
                else {
                    lx = vx / len; ly = vy / len; lz = vz / len; factor = 1.f;
                    const double tx = params[3] - params[0];
                    const double ty = params[4] - params[1];
                    const double tz = params[5] - params[2];
                    const double tLen = std::sqrt(tx * tx + ty * ty + tz * tz);
                    if (tLen == 0.0) {
                        factor = 1.f;
                    } else {
                        const double dSx = tx / tLen, dSy = ty / tLen, dSz = tz / tLen;
                        double dot = dSx * -lx + dSy * -ly + dSz * -lz;
                        if (dot < -1.0) dot = -1.0; else if (dot > 1.0) dot = 1.0;
                        auto f = static_cast<float>(dot);
                        if (!std::isnan(params[6]) && static_cast<double>(f) < std::cos(params[6] * M_PI / 180.0)) f = 0.f;
                        factor = f < 0.f ? 0.f : f;
                    }
                }
            }

            const float dzdx = (heightAt(pix, width, height, x + 1, y - 1, ss) +
                                2 * heightAt(pix, width, height, x + 1, y,     ss) +
                                heightAt(pix, width, height, x + 1, y + 1, ss) -
                               (heightAt(pix, width, height, x - 1, y - 1, ss) +
                                2 * heightAt(pix, width, height, x - 1, y,     ss) +
                                heightAt(pix, width, height, x - 1, y + 1, ss))) / (4.f / canvasScaleX);
            const float dzdy = (heightAt(pix, width, height, x - 1, y + 1, ss) +
                                2 * heightAt(pix, width, height, x,     y + 1, ss) +
                                heightAt(pix, width, height, x + 1, y + 1, ss) -
                               (heightAt(pix, width, height, x - 1, y - 1, ss) +
                                2 * heightAt(pix, width, height, x,     y - 1, ss) +
                                heightAt(pix, width, height, x + 1, y - 1, ss))) / (4.f / canvasScaleY);

            float nx = -dzdx, ny = -dzdy, nz = 1.f;
            const float nLen = std::sqrt(nx * nx + ny * ny + nz * nz);
            if (nLen != 0.f) { nx /= nLen; ny /= nLen; nz /= nLen; }

            float intensity;
            if (!isSpecular) {
                float dot = nx * lx + ny * ly + nz * lz;
                if (dot < 0.f) dot = 0.f;
                intensity = clamp01(dot * k * factor);
            } else {
                float hx = lx, hy = ly, hz = lz + 1.f;
                const float hLen = std::sqrt(hx * hx + hy * hy + hz * hz);
                if (hLen != 0.f) { hx /= hLen; hy /= hLen; hz /= hLen; }
                float ndoth = nx * hx + ny * hy + nz * hz;
                if (ndoth < 0.f) ndoth = 0.f;
                const double p = std::pow(static_cast<double>(ndoth), static_cast<double>(exponent));
                intensity = clamp01(k * static_cast<float>(p) * factor);
            }

            jint outR = clamp255f(lr * intensity);
            jint outG = clamp255f(lg * intensity);
            jint outB = clamp255f(lb * intensity);
            if (useLinear) {
                outR = linearToLightSRgb(outR);
                outG = linearToLightSRgb(outG);
                outB = linearToLightSRgb(outB);
            }
            const jint outA = isSpecular
                    ? (outR > outG ? (outR > outB ? outR : outB) : (outG > outB ? outG : outB))
                    : 255;

            out[rowOffset + x] = (isSpecular && premultiplied)
                    ? ((clamp255f(intensity * 255.f) << 24) | (jint(fr + 0.5f) << 16) | (jint(fg + 0.5f) << 8) | jint(fb + 0.5f))
                    : ((outA << 24) | (outR << 16) | (outG << 8) | outB);
        }
    }
}

#if defined(__ARM_NEON__) || defined(__SSE2__)
#define LIGHT_SIMD 1
#endif

#ifdef LIGHT_SIMD

#if defined(__ARM_NEON__)
#include <arm_neon.h>
using F32x4 = float32x4_t;
inline F32x4 vLoad(const float* p) { return vld1q_f32(p); }
inline F32x4 vAdd(F32x4 a, F32x4 b) { return vaddq_f32(a, b); }
inline F32x4 vSub(F32x4 a, F32x4 b) { return vsubq_f32(a, b); }
inline F32x4 vMul(F32x4 a, F32x4 b) { return vmulq_f32(a, b); }
#if defined(__aarch64__)
inline F32x4 vDiv(F32x4 a, F32x4 b) { return vdivq_f32(a, b); }
inline F32x4 vSqrt(F32x4 v) { return vsqrtq_f32(v); }
#else
// ARMv7-A NEON does not have vdivq_f32 and vsqrtq_f32.
// Use Newton-Raphson approximation for division and square root.
inline F32x4 vDiv(F32x4 a, F32x4 b) {
    float32x4_t rec = vrecpeq_f32(b);
    rec = vmulq_f32(vrecpsq_f32(b, rec), rec);
    rec = vmulq_f32(vrecpsq_f32(b, rec), rec);
    return vmulq_f32(a, rec);
}
inline F32x4 vSqrt(F32x4 v) {
    float32x4_t rec = vrsqrteq_f32(v);
    rec = vmulq_f32(vrsqrtsq_f32(vmulq_f32(v, rec), rec), rec);
    rec = vmulq_f32(vrsqrtsq_f32(vmulq_f32(v, rec), rec), rec);
    return vmulq_f32(v, rec);
}
#endif
inline F32x4 vSplat(float v) { return vdupq_n_f32(v); }
inline F32x4 vMax(F32x4 a, F32x4 b) { return vmaxq_f32(a, b); }
inline F32x4 vMin(F32x4 a, F32x4 b) { return vminq_f32(a, b); }
inline void vStore(float* p, F32x4 v) { vst1q_f32(p, v); }
#else
#include <emmintrin.h>
using F32x4 = __m128;
inline F32x4 vLoad(const float* p) { return _mm_loadu_ps(p); }
inline F32x4 vAdd(F32x4 a, F32x4 b) { return _mm_add_ps(a, b); }
inline F32x4 vSub(F32x4 a, F32x4 b) { return _mm_sub_ps(a, b); }
inline F32x4 vMul(F32x4 a, F32x4 b) { return _mm_mul_ps(a, b); }
inline F32x4 vDiv(F32x4 a, F32x4 b) { return _mm_div_ps(a, b); }
inline F32x4 vSplat(float v) { return _mm_set1_ps(v); }
inline F32x4 vSqrt(F32x4 v) { return _mm_sqrt_ps(v); }
inline F32x4 vMax(F32x4 a, F32x4 b) { return _mm_max_ps(a, b); }
inline F32x4 vMin(F32x4 a, F32x4 b) { return _mm_min_ps(a, b); }
inline void vStore(float* p, F32x4 v) { _mm_storeu_ps(p, v); }
#endif

// Sobel + surface normal for 4 consecutive pixels. ht/hm/hb point at column
// (x-1) of the clamped top/middle/bottom height rows. Same float op order as
// the scalar reference -> bit-exact. Returns nx, ny, nz (=1/len) vectors.
inline void sobelNormal4(
        const float* ht, const float* hm, const float* hb,
        float invDx, float invDy,
        F32x4& nx, F32x4& ny, F32x4& nz) {
    const F32x4 one = vSplat(1.f);
    const F32x4 two = vSplat(2.f);

    const F32x4 lT = vLoad(ht),     mT = vLoad(ht + 1), rT = vLoad(ht + 2);
    const F32x4 lM = vLoad(hm),     mM = vLoad(hm + 1), rM = vLoad(hm + 2);
    const F32x4 lB = vLoad(hb),     mB = vLoad(hb + 1), rB = vLoad(hb + 2);

    const F32x4 sumR = vAdd(vAdd(rT, vMul(two, rM)), rB);
    const F32x4 sumL = vAdd(vAdd(lT, vMul(two, lM)), lB);
    const F32x4 sumB = vAdd(vAdd(lB, vMul(two, mB)), rB);
    const F32x4 sumT = vAdd(vAdd(lT, vMul(two, mT)), rT);

    const F32x4 dzdx = vDiv(vSub(sumR, sumL), vSplat(invDx));
    const F32x4 dzdy = vDiv(vSub(sumB, sumT), vSplat(invDy));

    nx = vSub(vSplat(0.f), dzdx);
    ny = vSub(vSplat(0.f), dzdy);
    const F32x4 nLen = vSqrt(vAdd(vAdd(vMul(nx, nx), vMul(ny, ny)), one));
    nx = vDiv(nx, nLen);
    ny = vDiv(ny, nLen);
    nz = vDiv(one, nLen);
}

inline jint packPixel(jint outA, jint outR, jint outG, jint outB) {
    return (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

void applyVector(
        jint* pix, jint* out, jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        float ss, jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop, jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        float canvasScaleX, float canvasScaleY,
        jint lightType, bool isSpecular, float k, float exponent,
        float fr, float fg, float fb, const jdouble* params,
        bool premultiplied, bool useLinear) {
    const jint span = clipRight - clipLeft + 3; // columns x-1 .. x+1 of last px
    float rowT[kMaxVecRowSpan], rowM[kMaxVecRowSpan], rowB[kMaxVecRowSpan];
    float intensities[4];

    const float lr = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fr))) : fr;
    const float lg = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fg))) : fg;
    const float lb = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fb))) : fb;

    const float invDx = 4.f / canvasScaleX;
    const float invDy = 4.f / canvasScaleY;

    // Distant light: constant vector, precomputed once.
    float lx = 0.f, ly = 0.f, lz = 0.f;
    if (lightType == 0) {
        const double az = params[0] * M_PI / 180.0;
        const double el = params[1] * M_PI / 180.0;
        lx = static_cast<float>(std::cos(az) * std::cos(el));
        ly = static_cast<float>(std::sin(az) * std::cos(el));
        lz = static_cast<float>(std::sin(el));
    }
    const F32x4 vLx = vSplat(lx), vLy = vSplat(ly), vLz = vSplat(lz);
    const F32x4 one = vSplat(1.f);
    const F32x4 vK = vSplat(k);

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        // Build the three clamped height rows (y-1, y, y+1), columns
        // [clipLeft-1 .. clipRight].
        for (jint i = 0; i < span; i++) {
            const jint cx = clipLeft - 1 + i;
            rowT[i] = heightAt(pix, width, height, cx, y - 1, ss);
            rowM[i] = heightAt(pix, width, height, cx, y,     ss);
            rowB[i] = heightAt(pix, width, height, cx, y + 1, ss);
        }

        const jdouble userY = userTop + y * invCanvasScaleY;
        const auto uy = static_cast<float>((userY - originY) / unitSizeY);

        jint x = clipLeft;
        const jint vecEnd = clipLeft + ((clipRight - clipLeft) & ~3);
        for (; x < vecEnd; x += 4) {
            const jint base = x - clipLeft; // index of column x-1 in the rows
            F32x4 nx, ny, nz;
            sobelNormal4(rowT + base, rowM + base, rowB + base, invDx, invDy, nx, ny, nz);

            if (lightType == 0) {
                if (!isSpecular) {
                    const F32x4 dot = vMax(vSplat(0.f),
                            vAdd(vAdd(vMul(nx, vLx), vMul(ny, vLy)), vMul(nz, vLz)));
                    // factor == 1 for distant light.
                    vStore(intensities, vMin(vMul(dot, vK), one));
                } else {
                    F32x4 hx = vLx, hy = vLy, hz = vAdd(vLz, one);
                    const F32x4 hLen = vSqrt(vAdd(vAdd(vMul(hx, hx), vMul(hy, hy)), vMul(hz, hz)));
                    hx = vDiv(hx, hLen); hy = vDiv(hy, hLen); hz = vDiv(hz, hLen);
                    const F32x4 ndoth = vMax(vSplat(0.f),
                            vAdd(vAdd(vMul(nx, hx), vMul(ny, hy)), vMul(nz, hz)));
                    vStore(intensities, ndoth);
                    for (jint l = 0; l < 4; l++) {
                        const double p = std::pow(static_cast<double>(intensities[l]),
                                                  static_cast<double>(exponent));
                        intensities[l] = clamp01(k * static_cast<float>(p));
                    }
                }
            } else {
                // point/spot: per-pixel light vector on top of vector normals.
                float nxs[4], nys[4], nzs[4];
                vStore(nxs, nx); vStore(nys, ny); vStore(nzs, nz);
                for (jint l = 0; l < 4; l++) {
                    const jint px = x + l;
                    const jdouble userX = userLeft + px * invCanvasScaleX;
                    const auto ux = static_cast<float>((userX - originX) / unitSizeX);
                    const float surfaceZ = rowM[base + l + 1];
                    float plx, ply, plz, factor;
                    if (lightType == 1) {
                        const float vx = static_cast<float>(params[0]) - ux;
                        const float vy = static_cast<float>(params[1]) - uy;
                        const float vz = static_cast<float>(params[2]) - surfaceZ;
                        const float len = std::sqrt(vx * vx + vy * vy + vz * vz);
                        if (len == 0.f) { plx = 0.f; ply = 0.f; plz = 0.f; factor = 0.f; }
                        else { plx = vx / len; ply = vy / len; plz = vz / len; factor = 1.f; }
                    } else {
                        const float vx = static_cast<float>(params[0]) - ux;
                        const float vy = static_cast<float>(params[1]) - uy;
                        const float vz = static_cast<float>(params[2]) - surfaceZ;
                        const float len = std::sqrt(vx * vx + vy * vy + vz * vz);
                        if (len == 0.f) { plx = 0.f; ply = 0.f; plz = 0.f; factor = 0.f; }
                        else {
                            plx = vx / len; ply = vy / len; plz = vz / len; factor = 1.f;
                            const double tx = params[3] - params[0];
                            const double ty = params[4] - params[1];
                            const double tz = params[5] - params[2];
                            const double tLen = std::sqrt(tx * tx + ty * ty + tz * tz);
                            if (tLen == 0.0) {
                                factor = 1.f;
                            } else {
                                const double dSx = tx / tLen, dSy = ty / tLen, dSz = tz / tLen;
                                double dot = dSx * -plx + dSy * -ply + dSz * -plz;
                                if (dot < -1.0) dot = -1.0; else if (dot > 1.0) dot = 1.0;
                                auto f = static_cast<float>(dot);
                                if (!std::isnan(params[6]) &&
                                    static_cast<double>(f) < std::cos(params[6] * M_PI / 180.0)) f = 0.f;
                                factor = f < 0.f ? 0.f : f;
                            }
                        }
                    }
                    float inten;
                    if (!isSpecular) {
                        float dot = nxs[l] * plx + nys[l] * ply + nzs[l] * plz;
                        if (dot < 0.f) dot = 0.f;
                        inten = clamp01(dot * k * factor);
                    } else {
                        float hx = plx, hy = ply, hz = plz + 1.f;
                        const float hLen = std::sqrt(hx * hx + hy * hy + hz * hz);
                        if (hLen != 0.f) { hx /= hLen; hy /= hLen; hz /= hLen; }
                        float ndoth = nxs[l] * hx + nys[l] * hy + nzs[l] * hz;
                        if (ndoth < 0.f) ndoth = 0.f;
                        const double p = std::pow(static_cast<double>(ndoth),
                                                  static_cast<double>(exponent));
                        inten = clamp01(k * static_cast<float>(p) * factor);
                    }
                    intensities[l] = inten;
                }
            }

            for (jint l = 0; l < 4; l++) {
                jint outR = clamp255f(lr * intensities[l]);
                jint outG = clamp255f(lg * intensities[l]);
                jint outB = clamp255f(lb * intensities[l]);
                if (useLinear) {
                    outR = linearToLightSRgb(outR);
                    outG = linearToLightSRgb(outG);
                    outB = linearToLightSRgb(outB);
                }
                const jint outA = isSpecular
                        ? (outR > outG ? (outR > outB ? outR : outB) : (outG > outB ? outG : outB))
                        : 255;

                out[rowOffset + x + l] = (isSpecular && premultiplied)
                        ? ((clamp255f(intensities[l] * 255.f) << 24) | (jint(fr + 0.5f) << 16) | (jint(fg + 0.5f) << 8) | jint(fb + 0.5f))
                        : packPixel(outA, outR, outG, outB);
            }
        }

        // Scalar tail.
        for (; x < clipRight; x++) {
            const jdouble userX = userLeft + x * invCanvasScaleX;
            const auto ux = static_cast<float>((userX - originX) / unitSizeX);
            const float surfaceZ = rowM[x - clipLeft + 1];
            (void) surfaceZ; (void) ux; (void) uy;
            // Reuse the scalar reference for tail pixels via a tiny inline copy:
            float lx2, ly2, lz2, factor;
            if (lightType == 0) {
                lx2 = lx; ly2 = ly; lz2 = lz; factor = 1.f;
            } else {
                float plx, ply, plz;
                const float vx = static_cast<float>(params[0]) - ux;
                const float vy = static_cast<float>(params[1]) - uy;
                const float vz = static_cast<float>(params[2]) - surfaceZ;
                const float len = std::sqrt(vx * vx + vy * vy + vz * vz);
                if (len == 0.f) { plx = 0.f; ply = 0.f; plz = 0.f; factor = 0.f; }
                else {
                    plx = vx / len; ply = vy / len; plz = vz / len; factor = 1.f;
                    if (lightType == 2) {
                        const double tx = params[3] - params[0];
                        const double ty = params[4] - params[1];
                        const double tz = params[5] - params[2];
                        const double tLen = std::sqrt(tx * tx + ty * ty + tz * tz);
                        if (tLen == 0.0) {
                            factor = 1.f;
                        } else {
                            const double dSx = tx / tLen, dSy = ty / tLen, dSz = tz / tLen;
                            double dot = dSx * -plx + dSy * -ply + dSz * -plz;
                            if (dot < -1.0) dot = -1.0; else if (dot > 1.0) dot = 1.0;
                            auto f = static_cast<float>(dot);
                            if (!std::isnan(params[6]) &&
                                static_cast<double>(f) < std::cos(params[6] * M_PI / 180.0)) f = 0.f;
                            factor = f < 0.f ? 0.f : f;
                        }
                    }
                }
                lx2 = plx; ly2 = ply; lz2 = plz;
            }
            const float dzdx = (heightAt(pix, width, height, x + 1, y - 1, ss) +
                                2 * heightAt(pix, width, height, x + 1, y,     ss) +
                                heightAt(pix, width, height, x + 1, y + 1, ss) -
                               (heightAt(pix, width, height, x - 1, y - 1, ss) +
                                2 * heightAt(pix, width, height, x - 1, y,     ss) +
                                heightAt(pix, width, height, x - 1, y + 1, ss))) / invDx;
            const float dzdy = (heightAt(pix, width, height, x - 1, y + 1, ss) +
                                2 * heightAt(pix, width, height, x,     y + 1, ss) +
                                heightAt(pix, width, height, x + 1, y + 1, ss) -
                               (heightAt(pix, width, height, x - 1, y - 1, ss) +
                                2 * heightAt(pix, width, height, x,     y - 1, ss) +
                                heightAt(pix, width, height, x + 1, y - 1, ss))) / invDy;
            float nx = -dzdx, ny = -dzdy, nz = 1.f;
            const float nLen = std::sqrt(nx * nx + ny * ny + nz * nz);
            if (nLen != 0.f) { nx /= nLen; ny /= nLen; nz /= nLen; }
            float intensity;
            if (!isSpecular) {
                float dot = nx * lx2 + ny * ly2 + nz * lz2;
                if (dot < 0.f) dot = 0.f;
                intensity = clamp01(dot * k * factor);
            } else {
                float hx = lx2, hy = ly2, hz = lz2 + 1.f;
                const float hLen = std::sqrt(hx * hx + hy * hy + hz * hz);
                if (hLen != 0.f) { hx /= hLen; hy /= hLen; hz /= hLen; }
                float ndoth = nx * hx + ny * hy + nz * hz;
                if (ndoth < 0.f) ndoth = 0.f;
                const double p = std::pow(static_cast<double>(ndoth), static_cast<double>(exponent));
                intensity = clamp01(k * static_cast<float>(p) * factor);
            }
            jint outR = clamp255f(lr * intensity);
            jint outG = clamp255f(lg * intensity);
            jint outB = clamp255f(lb * intensity);
            if (useLinear) {
                outR = linearToLightSRgb(outR);
                outG = linearToLightSRgb(outG);
                outB = linearToLightSRgb(outB);
            }
            const jint outA = isSpecular
                    ? (outR > outG ? (outR > outB ? outR : outB) : (outG > outB ? outG : outB))
                    : 255;

            out[rowOffset + x] = (isSpecular && premultiplied)
                    ? ((clamp255f(intensity * 255.f) << 24) | (jint(fr + 0.5f) << 16) | (jint(fg + 0.5f) << 8) | jint(fb + 0.5f))
                    : packPixel(outA, outR, outG, outB);
        }
    }
}

#endif // LIGHT_SIMD

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_LightingNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jPix, const jintArray jOut,
        jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat surfaceScaleNormalized,
        jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop,
        jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        jfloat canvasScaleX, jfloat canvasScaleY,
        jint lightType, const jboolean specular,
        jfloat k, jfloat exponent,
        const jint lightR, const jint lightG, const jint lightB,
        const jdoubleArray jParams,
        const jboolean premultipliedOutput,
        const jboolean useLinearInput) {
    // Small array first: no JNI call may occur between a
    // GetPrimitiveArrayCritical pair, so the params must be fetched
    // BEFORE entering the critical sections.
    jdouble* params = env->GetDoubleArrayElements(jParams, nullptr);
    if (params == nullptr) return;

    auto* pix = static_cast<jint*>(env->GetPrimitiveArrayCritical(jPix, nullptr));
    if (pix == nullptr) {
        env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
        return;
    }
    auto* out = static_cast<jint*>(env->GetPrimitiveArrayCritical(jOut, nullptr));
    if (out == nullptr) {
        env->ReleasePrimitiveArrayCritical(jPix, pix, JNI_ABORT);
        env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
        return;
    }

    const bool isSpecular = specular == JNI_TRUE;
    const bool premultiplied = premultipliedOutput == JNI_TRUE;
    const bool useLinear = useLinearInput == JNI_TRUE;
    const jint span = clipRight - clipLeft + 3;

#ifdef LIGHT_SIMD
    if (span <= kMaxVecRowSpan) {
        applyVector(pix, out, width, height,
                    clipLeft, clipTop, clipRight, clipBottom,
                    surfaceScaleNormalized,
                    invCanvasScaleX, invCanvasScaleY,
                    userLeft, userTop, originX, originY,
                    unitSizeX, unitSizeY,
                    canvasScaleX, canvasScaleY,
                    lightType, isSpecular, k, exponent,
                    static_cast<float>(lightR), static_cast<float>(lightG),
                    static_cast<float>(lightB), params,
                    premultiplied, useLinear);
    } else
#endif
    {
        applyScalar(pix, out, width, height,
                    clipLeft, clipTop, clipRight, clipBottom,
                    surfaceScaleNormalized,
                    invCanvasScaleX, invCanvasScaleY,
                    userLeft, userTop, originX, originY,
                    unitSizeX, unitSizeY,
                    canvasScaleX, canvasScaleY,
                    lightType, isSpecular, k, exponent,
                    static_cast<float>(lightR), static_cast<float>(lightG),
                    static_cast<float>(lightB), params,
                    premultiplied, useLinear);
    }

    env->ReleasePrimitiveArrayCritical(jOut, out, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jPix, pix, JNI_ABORT);
    env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
}
