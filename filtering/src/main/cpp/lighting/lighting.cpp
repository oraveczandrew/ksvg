//    Copyright 2026 András Oravecz <info@oandras.hu>
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

#include <jni.h>
#include <cmath>
#include <cassert>
#include <algorithm>
#include "cpu_dispatch.h"
#include "shared/math_utils.h"
#include "color_luts.h"

#if defined(__aarch64__)
// Hand-written AArch64/AdvSIMD distant-light diffuse kernel (lighting_distant_diffuse_aarch64_neon.S).
extern "C" void ksvgLightingDistantDiffuseRowNeon64(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params);
extern "C" void ksvgLightingDistantDiffuseRowNeon64Linear(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params,
    const uint8_t* linearToSrgb);
extern "C" void ksvgLightingDistantSpecularRowNeon64(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params, float exponent);
extern "C" void ksvgLightingDistantSpecularRowNeon64Linear(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params,
    float exponent, const uint8_t* linearToSrgb);
// Hand-written AArch64/AdvSIMD point-light diffuse kernel (lighting_point_diffuse_aarch64_neon.S).
extern "C" void ksvgLightingPointDiffuseRowNeon64(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const PointLightingParams* params);
extern "C" void ksvgLightingPointDiffuseRowNeon64Linear(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const PointLightingParams* params,
    const uint8_t* linearToSrgb);
#elif defined(__arm__)
// Hand-written ARM32/AdvSIMD distant-light diffuse kernel (lighting_distant_diffuse_armv7a_neon.S).
extern "C" void ksvgLightingDistantDiffuseRowNeon32(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params);
extern "C" void ksvgLightingDistantDiffuseRowNeon32Linear(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params,
    const uint8_t* linearToSrgb);
extern "C" void ksvgLightingDistantSpecularRowNeon32(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params, float exponent);
extern "C" void ksvgLightingDistantSpecularRowNeon32Linear(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params,
    const uint8_t* linearToSrgb, float exponent);
#elif defined(__i386__) || defined(__x86_64__)
#include "simd_x86.h"
#endif

namespace {

float heightAt(const jint* pix, const jint width, const jint height, const jint x, const jint y, const float ss) {
    const jint cx = x < 0 ? 0 : x > width - 1 ? width - 1 : x;
    const jint cy = y < 0 ? 0 : y > height - 1 ? height - 1 : y;
    return static_cast<float>((pix[cy * width + cx] >> 24) & 0xff) * ss;
}

float clamp01(const float v) { return v < 0.f ? 0.f : v > 1.f ? 1.f : v; }

inline jint sRgbToLight(const jint c) {
    return ksvg_srgb_to_linear_lut[c & 0xFF];
}

inline jint linearToLightSRgb(const jint c) {
    return ksvg_linear_to_srgb_lut[c & 0xFF];
}

inline jint packPixel(const jint outA, const jint outR, const jint outG, const jint outB) {
    return (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

inline void applyScalarPixel_full(
        const jint* pix, jint* out, jint width, jint height,
        jint x, jint y,
        float ss, float invDx, float invDy,
        jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop, jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        jint lightType, bool isSpecular, float k, float exponent,
        float lr, float lg, float lb, const jdouble* params,
        bool premultiplied, bool useLinear) {
    const jdouble userY = userTop + y * invCanvasScaleY;
    const auto uy = static_cast<float>((userY - originY) / unitSizeY);
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
        float dot = nx * lx + ny * ly + nz * lz;
        if (dot < 0.f) dot = 0.f;
        intensity = clamp01(dot * k * factor);
    } else {
        float hx = lx, hy = ly, hz = lz + 1.f;
        const float hLen = std::sqrt(hx * hx + hy * hy + hz * hz);
        if (hLen != 0.f) { hx /= hLen; hy /= hLen; hz /= hLen; }
        float ndoth = nx * hx + ny * hy + nz * hz;
        if (ndoth < 0.f) ndoth = 0.f;
        const float p = std::pow(ndoth, exponent);
        intensity = clamp01(k * p * factor);
    }

    jint outR = ksvg::clamp255(lr * intensity);
    jint outG = ksvg::clamp255(lg * intensity);
    jint outB = ksvg::clamp255(lb * intensity);
    if (useLinear) {
        outR = linearToLightSRgb(outR);
        outG = linearToLightSRgb(outG);
        outB = linearToLightSRgb(outB);
    }
    const jint outA = isSpecular
            ? (outR > outG ? (outR > outB ? outR : outB) : outG > outB ? outG : outB)
            : 255;

    out[y * width + x] = isSpecular && premultiplied
            ? (ksvg::clamp255(intensity * 255.f) << 24) | (static_cast<jint>(lr + 0.5f) << 16) | (static_cast<jint>(lg + 0.5f) << 8) | static_cast<jint>(lb + 0.5f)
            : packPixel(outA, outR, outG, outB);
}

inline void applyScalarDistantDiffuse(
        const jint* pix, jint* out, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const float ss, const float invDx, const float invDy,
        const float k, const float lr, const float lg, const float lb,
        const jdouble* params) {
    const double az = params[0] * M_PI / 180.0;
    const double el = params[1] * M_PI / 180.0;
    const float lx = static_cast<float>(std::cos(az) * std::cos(el));
    const float ly = static_cast<float>(std::sin(az) * std::cos(el));
    const float lz = static_cast<float>(std::sin(el));

    const int lastX = width - 1;
    const int lastY = height - 1;

    for (jint y = clipTop; y < clipBottom; ++y) {
        const int ym1 = y > 0 ? y - 1 : 0;
        const int yp1 = y < lastY ? y + 1 : lastY;

        const jint* rowT = pix + ym1 * width;
        const jint* rowM = pix + y * width;
        const jint* rowB = pix + yp1 * width;
        jint* dst = out + y * width;

        const jint x0 = clipLeft;
        const jint x1 = clipRight;

        // The interior is the hot path: no per-sample clamp arithmetic.
        const jint ix0 = std::max(x0, 1);
        const jint ix1 = std::min(x1, lastX);

        for (jint x = x0; x < ix0; ++x) {
            const int xm1 = x > 0 ? x - 1 : 0;
            const int xp1 = x < lastX ? x + 1 : lastX;

            const float tl = static_cast<float>((rowT[xm1] >> 24) & 0xff) * ss;
            const float tm = static_cast<float>((rowT[x]    >> 24) & 0xff) * ss;
            const float tr = static_cast<float>((rowT[xp1] >> 24) & 0xff) * ss;
            const float ml = static_cast<float>((rowM[xm1] >> 24) & 0xff) * ss;
            const float mr = static_cast<float>((rowM[xp1] >> 24) & 0xff) * ss;
            const float bl = static_cast<float>((rowB[xm1] >> 24) & 0xff) * ss;
            const float bm = static_cast<float>((rowB[x]    >> 24) & 0xff) * ss;
            const float br = static_cast<float>((rowB[xp1] >> 24) & 0xff) * ss;

            const float dzdx = (tr + mr + mr + br - (tl + ml + ml + bl)) / invDx;
            const float dzdy = (bl + bm + bm + br - (tl + tm + tm + tr)) / invDy;

            const float nx0 = -dzdx;
            const float ny0 = -dzdy;
            const float nLen = std::sqrt(nx0 * nx0 + ny0 * ny0 + 1.f);
            const float invLen = nLen != 0.f ? 1.f / nLen : 1.f;
            const float dot = (nx0 * lx + ny0 * ly + lz) * invLen;
            const float intensity = clamp01((dot > 0.f ? dot : 0.f) * k);

            dst[x] = packPixel(255,
                               ksvg::clamp255(lr * intensity),
                               ksvg::clamp255(lg * intensity),
                               ksvg::clamp255(lb * intensity));
        }

        for (jint x = ix0; x < ix1; ++x) {
            const jint* t = rowT + x;
            const jint* m = rowM + x;
            const jint* b = rowB + x;

            const float tl = static_cast<float>((t[-1] >> 24) & 0xff) * ss;
            const float tm = static_cast<float>((t[ 0] >> 24) & 0xff) * ss;
            const float tr = static_cast<float>((t[ 1] >> 24) & 0xff) * ss;
            const float ml = static_cast<float>((m[-1] >> 24) & 0xff) * ss;
            const float mr = static_cast<float>((m[ 1] >> 24) & 0xff) * ss;
            const float bl = static_cast<float>((b[-1] >> 24) & 0xff) * ss;
            const float bm = static_cast<float>((b[ 0] >> 24) & 0xff) * ss;
            const float br = static_cast<float>((b[ 1] >> 24) & 0xff) * ss;

            const float dzdx = (tr + mr + mr + br - (tl + ml + ml + bl)) / invDx;
            const float dzdy = (bl + bm + bm + br - (tl + tm + tm + tr)) / invDy;

            const float nx0 = -dzdx;
            const float ny0 = -dzdy;
            const float invLen = 1.f / std::sqrt(nx0 * nx0 + ny0 * ny0 + 1.f);
            const float dot = (nx0 * lx + ny0 * ly + lz) * invLen;
            const float intensity = clamp01((dot > 0.f ? dot : 0.f) * k);

            dst[x] = packPixel(255,
                               ksvg::clamp255(lr * intensity),
                               ksvg::clamp255(lg * intensity),
                               ksvg::clamp255(lb * intensity));
        }

        for (jint x = ix1; x < x1; ++x) {
            const int xm1 = x > 0 ? x - 1 : 0;
            const int xp1 = x < lastX ? x + 1 : lastX;

            const float tl = static_cast<float>((rowT[xm1] >> 24) & 0xff) * ss;
            const float tm = static_cast<float>((rowT[x]    >> 24) & 0xff) * ss;
            const float tr = static_cast<float>((rowT[xp1] >> 24) & 0xff) * ss;
            const float ml = static_cast<float>((rowM[xm1] >> 24) & 0xff) * ss;
            const float mr = static_cast<float>((rowM[xp1] >> 24) & 0xff) * ss;
            const float bl = static_cast<float>((rowB[xm1] >> 24) & 0xff) * ss;
            const float bm = static_cast<float>((rowB[x]    >> 24) & 0xff) * ss;
            const float br = static_cast<float>((rowB[xp1] >> 24) & 0xff) * ss;

            const float dzdx = (tr + mr + mr + br - (tl + ml + ml + bl)) / invDx;
            const float dzdy = (bl + bm + bm + br - (tl + tm + tm + tr)) / invDy;

            const float nx0 = -dzdx;
            const float ny0 = -dzdy;
            const float nLen = std::sqrt(nx0 * nx0 + ny0 * ny0 + 1.f);
            const float invLen = nLen != 0.f ? 1.f / nLen : 1.f;
            const float dot = (nx0 * lx + ny0 * ly + lz) * invLen;
            const float intensity = clamp01((dot > 0.f ? dot : 0.f) * k);

            dst[x] = packPixel(255,
                               ksvg::clamp255(lr * intensity),
                               ksvg::clamp255(lg * intensity),
                               ksvg::clamp255(lb * intensity));
        }
    }
}

void applyScalar(
        const jint* pix, jint* out, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const float ss, const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop, const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const float canvasScaleX, const float canvasScaleY,
        const jint lightType, const bool isSpecular, const float k, const float exponent,
        const float fr, const float fg, const float fb, const jdouble* params,
        const bool premultiplied, const bool useLinear) {
    const float lr = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fr))) : fr;
    const float lg = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fg))) : fg;
    const float lb = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fb))) : fb;
    const float invDx = 4.f / canvasScaleX;
    const float invDy = 4.f / canvasScaleY;

    if (lightType == 0 && !isSpecular && !useLinear) {
        applyScalarDistantDiffuse(pix, out, width, height,
                                  clipLeft, clipTop, clipRight, clipBottom,
                                  ss, invDx, invDy, k, lr, lg, lb, params);
        return;
    }

    for (jint y = clipTop; y < clipBottom; y++) {
        for (jint x = clipLeft; x < clipRight; x++) {
            applyScalarPixel_full(pix, out, width, height, x, y, ss, invDx, invDy,
                                 invCanvasScaleX, invCanvasScaleY, userLeft, userTop,
                                 originX, originY, unitSizeX, unitSizeY,
                                 lightType, isSpecular, k, exponent, lr, lg, lb, params,
                                 premultiplied, useLinear);
        }
    }
}

void applyVector(
        const jint* pix, jint* out, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const float ss, const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop, const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const float canvasScaleX, const float canvasScaleY,
        const jint lightType, const bool isSpecular, const float k, const float exponent,
        const float fr, const float fg, const float fb, const jdouble* params,
        const bool premultiplied, const bool useLinear, const jint backend) {
    const float lr = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fr))) : fr;
    const float lg = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fg))) : fg;
    const float lb = useLinear ? static_cast<float>(sRgbToLight(static_cast<jint>(fb))) : fb;

    const float invDx = 4.f / canvasScaleX;
    const float invDy = 4.f / canvasScaleY;

    float lx = 0.f, ly = 0.f, lz = 0.f;
    if (lightType == 0) {
        const double az = params[0] * M_PI / 180.0;
        const double el = params[1] * M_PI / 180.0;
        lx = static_cast<float>(std::cos(az) * std::cos(el));
        ly = static_cast<float>(std::sin(az) * std::cos(el));
        lz = static_cast<float>(std::sin(el));
    }

    const LightingParams lp = {
        .invDx = invDx, .invDy = invDy, .k = k, .lx = lx, .ly = ly, .lz = lz, .lr = lr, .lg = lg, .lb = lb, .ss = ss
    };

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        const jint iyLo = std::max(clipTop, 1);
        const jint iyHi = std::min(clipBottom, height - 1);
        const jint ixLo = std::max(clipLeft, 1);
        const jint ixHi = std::min(clipRight, width - 1);

        if (y < iyLo || y >= iyHi) {
            for (jint x = clipLeft; x < clipRight; x++) {
                applyScalarPixel_full(pix, out, width, height, x, y, ss, invDx, invDy,
                                     invCanvasScaleX, invCanvasScaleY, userLeft, userTop,
                                     originX, originY, unitSizeX, unitSizeY,
                                     lightType, isSpecular, k, exponent, lr, lg, lb, params,
                                     premultiplied, useLinear);
            }
            continue;
        }

        for (jint x = clipLeft; x < ixLo; x++) {
            applyScalarPixel_full(pix, out, width, height, x, y, ss, invDx, invDy,
                                 invCanvasScaleX, invCanvasScaleY, userLeft, userTop,
                                 originX, originY, unitSizeX, unitSizeY,
                                 lightType, isSpecular, k, exponent, lr, lg, lb, params,
                                 premultiplied, useLinear);
        }

        jint x = ixLo;

        if (lightType == 0 && ixHi - ixLo >= 4) {
            const jint count = ixHi - ixLo & ~3;
            if (count > 0) {
                const jint* srcT = pix + (y - 1) * width + (x - 1);
                const jint* srcM = pix + y * width + (x - 1);
                const jint* srcB = pix + (y + 1) * width + (x - 1);
                jint* rowOut = out + rowOffset + x;

#if defined(__aarch64__)
                if (isSpecular) {
                    // Premultiplied specular uses a different (cairo) terminal
                    // form in the Kotlin reference; fall back to the scalar path.
                    if (!premultiplied) {
                        assert(backend == SIMD_BACKEND_NEON64);
                        if (useLinear) {
                            ksvgLightingDistantSpecularRowNeon64Linear(srcT, srcM, srcB, rowOut, count, &lp, exponent, ksvg_linear_to_srgb_lut);
                        } else {
                            ksvgLightingDistantSpecularRowNeon64(srcT, srcM, srcB, rowOut, count, &lp, exponent);
                        }
                        x += count; srcT += count; srcM += count; srcB += count; rowOut += count;
                    }
                } else {
                    assert(backend == SIMD_BACKEND_NEON64);
                    if (useLinear) {
                        ksvgLightingDistantDiffuseRowNeon64Linear(srcT, srcM, srcB, rowOut, count, &lp, ksvg_linear_to_srgb_lut);
                    } else {
                        ksvgLightingDistantDiffuseRowNeon64(srcT, srcM, srcB, rowOut, count, &lp);
                    }
                    x += count; srcT += count; srcM += count; srcB += count; rowOut += count;
                }
#elif defined(__arm__)
                if (!isSpecular) {
                    assert(backend == SIMD_BACKEND_NEON32);
                    if (useLinear) {
                        ksvgLightingDistantDiffuseRowNeon32Linear(srcT, srcM, srcB, rowOut, count, &lp, ksvg_linear_to_srgb_lut);
                    } else {
                        ksvgLightingDistantDiffuseRowNeon32(srcT, srcM, srcB, rowOut, count, &lp);
                    }
                    x += count; srcT += count; srcM += count; srcB += count; rowOut += count;
                }
#elif defined(__x86_64__)
                switch (backend) {
                    case SIMD_BACKEND_AVX2: {
                        const jint c8 = (ixHi - x) & ~7;
                        if (c8 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingDistantSpecularRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &lp, exponent);
                                } else {
                                    ksvgLightingDistantSpecularRowAvx2(srcT, srcM, srcB, rowOut, c8, &lp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingDistantDiffuseRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &lp);
                                } else {
                                    ksvgLightingDistantDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &lp);
                                }
                            }
                            x += c8; srcT += c8; srcM += c8; srcB += c8; rowOut += c8;
                        }
                        break;
                    }
                    case SIMD_BACKEND_SSSE3: {
                        const jint c4 = (ixHi - x) & ~3;
                        if (c4 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingDistantSpecularRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &lp, exponent);
                                } else {
                                    ksvgLightingDistantSpecularRowSsse3(srcT, srcM, srcB, rowOut, c4, &lp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingDistantDiffuseRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &lp);
                                } else {
                                    ksvgLightingDistantDiffuseRowSsse3(srcT, srcM, srcB, rowOut, c4, &lp);
                                }
                            }
                            x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                        }
                        break;
                    }
                    default:
                        assert(false && "unsupported forced lighting backend on x86-64");
                }
#elif defined(__i386__)
                if (isSpecular) {
                    switch (backend) {
                        case SIMD_BACKEND_AVX2: {
                            const jint c8 = (ixHi - x) & ~7;
                            if (c8 > 0) {
                                if (useLinear) {
                                    ksvgLightingDistantSpecularRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &lp, exponent);
                                } else {
                                    ksvgLightingDistantSpecularRowAvx2(srcT, srcM, srcB, rowOut, c8, &lp, exponent);
                                }
                                x += c8;
                            }
                            break;
                        }
                        case SIMD_BACKEND_SSSE3: {
                            const jint c4 = (ixHi - x) & ~3;
                            if (c4 > 0) {
                                if (useLinear) {
                                    ksvgLightingDistantSpecularRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &lp, exponent);
                                } else {
                                    ksvgLightingDistantSpecularRowSsse3(srcT, srcM, srcB, rowOut, c4, &lp, exponent);
                                }
                                x += c4;
                            }
                            break;
                        }
                        default:
                            assert(false && "unsupported forced specular lighting backend on i386");
                    }
                } else {
                    switch (backend) {
                        case SIMD_BACKEND_AVX2: {
                            const jint c8 = (ixHi - x) & ~7;
                            if (c8 > 0) {
                                if (useLinear) {
                                    ksvgLightingDistantDiffuseRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &lp);
                                } else {
                                    ksvgLightingDistantDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &lp);
                                }
                                x += c8;
                            }
                            break;
                        }
                        case SIMD_BACKEND_SSSE3: {
                            const jint c4 = (ixHi - x) & ~3;
                            if (c4 > 0) {
                                if (useLinear) {
                                    ksvgLightingDistantDiffuseRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &lp);
                                } else {
                                    ksvgLightingDistantDiffuseRowSsse3(srcT, srcM, srcB, rowOut, c4, &lp);
                                }
                                x += c4;
                            }
                            break;
                        }
                        default:
                            assert(false && "unsupported forced diffuse lighting backend on i386");
                    }
                }
#else
                (void)backend;
#endif
            }
        }

        // --- Point-light SIMD rows (x86_64 / i386) ---
        if (lightType == 1 && x < ixHi && (ixHi - x) >= 4) {
            const float ux0 = static_cast<float>((userLeft + x * invCanvasScaleX - originX) / unitSizeX);
            const float uy  = static_cast<float>((userTop + y * invCanvasScaleY - originY) / unitSizeY);
            const float dux = static_cast<float>(invCanvasScaleX / unitSizeX);
            const float plx = static_cast<float>(params[0]);
            const float ply = static_cast<float>(params[1]);
            const float plz = static_cast<float>(params[2]);

            const PointLightingParams plp = {
                .invDx = invDx, .invDy = invDy, .k = k,
                .lx = plx, .ly = ply, .lz = plz,
                .lr = lr, .lg = lg, .lb = lb, .ss = ss,
                .ux0 = ux0, .uy = uy, .dux = dux
            };

            // Premultiplied specular uses a different (cairo) terminal form in
            // the Kotlin reference; fall back to the scalar path for it.
            if (!isSpecular || !premultiplied) {
                const jint* srcT = pix + (y - 1) * width + (x - 1);
                const jint* srcM = pix + y * width + (x - 1);
                const jint* srcB = pix + (y + 1) * width + (x - 1);
                jint* rowOut = out + rowOffset + x;
#if defined(__x86_64__)
                switch (backend) {
                    case SIMD_BACKEND_AVX2: {
                        const jint c8 = (ixHi - x) & ~7;
                        if (c8 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingPointSpecularRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &plp, exponent, ksvg_linear_to_srgb_lut);
                                } else {
                                    ksvgLightingPointSpecularRowAvx2(srcT, srcM, srcB, rowOut, c8, &plp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingPointDiffuseRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &plp, ksvg_linear_to_srgb_lut);
                                } else {
                                    ksvgLightingPointDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &plp);
                                }
                            }
                            x += c8; srcT += c8; srcM += c8; srcB += c8; rowOut += c8;
                        }
                        break;
                    }
                    case SIMD_BACKEND_SSSE3: {
                        const jint c4 = (ixHi - x) & ~3;
                        if (c4 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingPointSpecularRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &plp, exponent, ksvg_linear_to_srgb_lut);
                                } else {
                                    ksvgLightingPointSpecularRowSsse3(srcT, srcM, srcB, rowOut, c4, &plp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingPointDiffuseRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &plp, ksvg_linear_to_srgb_lut);
                                } else {
                                    ksvgLightingPointDiffuseRowSsse3(srcT, srcM, srcB, rowOut, c4, &plp);
                                }
                            }
                            x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                        }
                        break;
                    }
                    default:
                        break;
                }
#elif defined(__i386__)
                switch (backend) {
                    case SIMD_BACKEND_AVX2: {
                        const jint c8 = (ixHi - x) & ~7;
                        if (c8 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingPointSpecularRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &plp, exponent);
                                } else {
                                    ksvgLightingPointSpecularRowAvx2(srcT, srcM, srcB, rowOut, c8, &plp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingPointDiffuseRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &plp);
                                } else {
                                    ksvgLightingPointDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &plp);
                                }
                            }
                            x += c8; srcT += c8; srcM += c8; srcB += c8; rowOut += c8;
                        }
                        break;
                    }
                    case SIMD_BACKEND_SSSE3: {
                        const jint c4 = (ixHi - x) & ~3;
                        if (c4 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingPointSpecularRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &plp, exponent);
                                } else {
                                    ksvgLightingPointSpecularRowSsse3(srcT, srcM, srcB, rowOut, c4, &plp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingPointDiffuseRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &plp);
                                } else {
                                    ksvgLightingPointDiffuseRowSsse3(srcT, srcM, srcB, rowOut, c4, &plp);
                                }
                            }
                            x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                        }
                        break;
                    }
                    default:
                        break;
                }
#elif defined(__aarch64__)
                // Point-specular stays on the scalar fallback until its
                // NEON kernel lands (kernels 4-5); only diffuse is wired.
                if (!isSpecular) {
                    assert(backend == SIMD_BACKEND_NEON64);
                    const jint c4 = (ixHi - x) & ~3;
                    if (c4 > 0) {
                        if (useLinear) {
                            ksvgLightingPointDiffuseRowNeon64Linear(srcT, srcM, srcB, rowOut, c4, &plp, ksvg_linear_to_srgb_lut);
                        } else {
                            ksvgLightingPointDiffuseRowNeon64(srcT, srcM, srcB, rowOut, c4, &plp);
                        }
                        x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                    }
                }
#endif
            }
        }

        // --- Spot-light SIMD rows (x86_64 / i386) ---
        if (lightType == 2 && x < ixHi && (ixHi - x) >= 4) {
            const float ux0 = static_cast<float>((userLeft + x * invCanvasScaleX - originX) / unitSizeX);
            const float uy  = static_cast<float>((userTop + y * invCanvasScaleY - originY) / unitSizeY);
            const float dux = static_cast<float>(invCanvasScaleX / unitSizeX);
            const float slx = static_cast<float>(params[0]);
            const float sly = static_cast<float>(params[1]);
            const float slz = static_cast<float>(params[2]);

            const double tx = params[3] - params[0];
            const double ty = params[4] - params[1];
            const double tz = params[5] - params[2];
            const double tLen = std::sqrt(tx * tx + ty * ty + tz * tz);
            float spotDirX, spotDirY, spotDirZ;
            if (tLen == 0.0) {
                spotDirX = 0.f; spotDirY = 0.f; spotDirZ = 0.f;
            } else {
                spotDirX = static_cast<float>(tx / tLen);
                spotDirY = static_cast<float>(ty / tLen);
                spotDirZ = static_cast<float>(tz / tLen);
            }
            const float spotCos = std::isnan(params[6]) ? -1.f
                    : static_cast<float>(std::cos(params[6] * M_PI / 180.0));

            const SpotLightingParams slp = {
                .invDx = invDx, .invDy = invDy, .k = k,
                .lx = slx, .ly = sly, .lz = slz,
                .lr = lr, .lg = lg, .lb = lb, .ss = ss,
                .ux0 = ux0, .uy = uy, .dux = dux,
                .spotDirX = spotDirX, .spotDirY = spotDirY, .spotDirZ = spotDirZ,
                .spotCos = spotCos
            };

            if (!isSpecular || !premultiplied) {
                const jint* srcT = pix + (y - 1) * width + (x - 1);
                const jint* srcM = pix + y * width + (x - 1);
                const jint* srcB = pix + (y + 1) * width + (x - 1);
                jint* rowOut = out + rowOffset + x;
#if defined(__x86_64__)
                switch (backend) {
                    case SIMD_BACKEND_AVX2: {
                        const jint c8 = (ixHi - x) & ~7;
                        if (c8 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingSpotSpecularRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &slp, exponent);
                                } else {
                                    ksvgLightingSpotSpecularRowAvx2(srcT, srcM, srcB, rowOut, c8, &slp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingSpotDiffuseRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &slp);
                                } else {
                                    ksvgLightingSpotDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &slp);
                                }
                            }
                            x += c8; srcT += c8; srcM += c8; srcB += c8; rowOut += c8;
                        }
                        break;
                    }
                    case SIMD_BACKEND_SSSE3: {
                        const jint c4 = (ixHi - x) & ~3;
                        if (c4 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingSpotSpecularRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &slp, exponent);
                                } else {
                                    ksvgLightingSpotSpecularRowSsse3(srcT, srcM, srcB, rowOut, c4, &slp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingSpotDiffuseRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &slp);
                                } else {
                                    ksvgLightingSpotDiffuseRowSsse3(srcT, srcM, srcB, rowOut, c4, &slp);
                                }
                            }
                            x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                        }
                        break;
                    }
                    default:
                        break;
                }
#elif defined(__i386__)
                switch (backend) {
                    case SIMD_BACKEND_AVX2: {
                        const jint c8 = (ixHi - x) & ~7;
                        if (c8 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingSpotSpecularRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &slp, exponent);
                                } else {
                                    ksvgLightingSpotSpecularRowAvx2(srcT, srcM, srcB, rowOut, c8, &slp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingSpotDiffuseRowAvx2Linear(srcT, srcM, srcB, rowOut, c8, &slp);
                                } else {
                                    ksvgLightingSpotDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &slp);
                                }
                            }
                            x += c8; srcT += c8; srcM += c8; srcB += c8; rowOut += c8;
                        }
                        break;
                    }
                    case SIMD_BACKEND_SSSE3: {
                        const jint c4 = (ixHi - x) & ~3;
                        if (c4 > 0) {
                            if (isSpecular) {
                                if (useLinear) {
                                    ksvgLightingSpotSpecularRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &slp, exponent);
                                } else {
                                    ksvgLightingSpotSpecularRowSsse3(srcT, srcM, srcB, rowOut, c4, &slp, exponent);
                                }
                            } else {
                                if (useLinear) {
                                    ksvgLightingSpotDiffuseRowSsse3Linear(srcT, srcM, srcB, rowOut, c4, &slp);
                                } else {
                                    ksvgLightingSpotDiffuseRowSsse3(srcT, srcM, srcB, rowOut, c4, &slp);
                                }
                            }
                            x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                        }
                        break;
                    }
                    default:
                        break;
                }
#endif
            }
        }

        for (; x < ixHi; x++) {
            applyScalarPixel_full(pix, out, width, height, x, y, ss, invDx, invDy,
                                 invCanvasScaleX, invCanvasScaleY, userLeft, userTop,
                                 originX, originY, unitSizeX, unitSizeY,
                                 lightType, isSpecular, k, exponent, lr, lg, lb, params,
                                 premultiplied, useLinear);
        }

        for (jint x = ixHi; x < clipRight; x++) {
            applyScalarPixel_full(pix, out, width, height, x, y, ss, invDx, invDy,
                                 invCanvasScaleX, invCanvasScaleY, userLeft, userTop,
                                 originX, originY, unitSizeX, unitSizeY,
                                 lightType, isSpecular, k, exponent, lr, lg, lb, params,
                                 premultiplied, useLinear);
        }
    }
}

} // namespace

namespace {

void runForced(const jint* pix, jint* out, const jint width, const jint height,
               const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
               const float ss, const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
               const jdouble userLeft, const jdouble userTop, const jdouble originX, const jdouble originY,
               const jdouble unitSizeX, const jdouble unitSizeY,
               const float canvasScaleX, const float canvasScaleY,
               const jint lightType, const bool isSpecular, const float k, const float exponent,
               const float fr, const float fg, const float fb, const jdouble* params,
               const bool premultiplied, const bool useLinear,
               const jint backend) {
    if (backend == SIMD_BACKEND_SCALAR) {
        applyScalar(pix, out, width, height, clipLeft, clipTop, clipRight, clipBottom,
                    ss, invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                    unitSizeX, unitSizeY, canvasScaleX, canvasScaleY,
                    lightType, isSpecular, k, exponent, fr, fg, fb, params,
                    premultiplied, useLinear);
        return;
    }

    applyVector(pix, out, width, height, clipLeft, clipTop, clipRight, clipBottom,
                ss, invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                unitSizeX, unitSizeY, canvasScaleX, canvasScaleY,
                lightType, isSpecular, k, exponent, fr, fg, fb, params,
                premultiplied, useLinear, backend);
}

jint nativeBackendForAbi() {
    jint backends = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
    backends |= SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backends |= SIMD_BACKEND_NEON32;
#elif defined(__x86_64__)
    // x86_64 baseline lighting rows are the SSSE3 variants; i386 now shares
    // the same SSSE3 naming (its _sse2.S files became _ssse3.S).
    backends |= SIMD_BACKEND_SSSE3;
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
#elif defined(__i386__)
    backends |= SIMD_BACKEND_SSSE3;
    if (detectSimdLevel() >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
#endif
    return backends;
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_LightingNative_nativeBackend(
        [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_LightingNative_applyForced(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jPix, const jintArray jOut,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat surfaceScaleNormalized,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jfloat canvasScaleX, const jfloat canvasScaleY,
        const jint lightType, const jboolean specular,
        const jfloat k, const jfloat exponent,
        const jint lightR, const jint lightG, const jint lightB,
        const jdoubleArray jParams,
        const jboolean premultipliedOutput,
        const jboolean useLinearInput,
        const jint simdBackend) {
    jdouble* params = env->GetDoubleArrayElements(jParams, nullptr);
    if (params == nullptr) return;

    jint* pix = env->GetIntArrayElements(jPix, nullptr);
    if (pix == nullptr) {
        env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
        return;
    }
    jint* out = env->GetIntArrayElements(jOut, nullptr);
    if (out == nullptr) {
        env->ReleaseIntArrayElements(jPix, pix, JNI_ABORT);
        env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
        return;
    }

    runForced(pix, out, width, height, clipLeft, clipTop, clipRight, clipBottom,
              surfaceScaleNormalized, invCanvasScaleX, invCanvasScaleY,
              userLeft, userTop, originX, originY, unitSizeX, unitSizeY,
              canvasScaleX, canvasScaleY, lightType, specular == JNI_TRUE,
              k, exponent, static_cast<float>(lightR), static_cast<float>(lightG),
              static_cast<float>(lightB), params, premultipliedOutput == JNI_TRUE,
              useLinearInput == JNI_TRUE, simdBackend);

    env->ReleaseIntArrayElements(jOut, out, 0);
    env->ReleaseIntArrayElements(jPix, pix, JNI_ABORT);
    env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_LightingNative_apply(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jPix, const jintArray jOut,
        const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jfloat surfaceScaleNormalized,
        const jdouble invCanvasScaleX, const jdouble invCanvasScaleY,
        const jdouble userLeft, const jdouble userTop,
        const jdouble originX, const jdouble originY,
        const jdouble unitSizeX, const jdouble unitSizeY,
        const jfloat canvasScaleX, const jfloat canvasScaleY,
        const jint lightType, const jboolean specular,
        const jfloat k, const jfloat exponent,
        const jint lightR, const jint lightG, const jint lightB,
        const jdoubleArray jParams,
        const jboolean premultipliedOutput,
        const jboolean useLinearInput) {
    jdouble* params = env->GetDoubleArrayElements(jParams, nullptr);
    if (params == nullptr) return;

    jint* pix = env->GetIntArrayElements(jPix, nullptr);
    if (pix == nullptr) {
        env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
        return;
    }
    jint* out = env->GetIntArrayElements(jOut, nullptr);
    if (out == nullptr) {
        env->ReleaseIntArrayElements(jPix, pix, JNI_ABORT);
        env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
        return;
    }

    const bool isSpecular = specular == JNI_TRUE;
    const bool premultiplied = premultipliedOutput == JNI_TRUE;
    const bool useLinear = useLinearInput == JNI_TRUE;

    jint backend = SIMD_BACKEND_SCALAR;
#if defined(__aarch64__)
    backend = SIMD_BACKEND_NEON64;
#elif defined(__ARM_NEON__) || defined(__ARM_NEON)
    backend = SIMD_BACKEND_NEON32;
#elif defined(__x86_64__)
    backend = SIMD_BACKEND_SSSE3;
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) backend = SIMD_BACKEND_AVX2;
#elif defined(__i386__)
    backend = SIMD_BACKEND_SSSE3;
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) backend = SIMD_BACKEND_AVX2;
#endif

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
                premultiplied, useLinear, backend);

    env->ReleaseIntArrayElements(jOut, out, 0);
    env->ReleaseIntArrayElements(jPix, pix, JNI_ABORT);
    env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
}
