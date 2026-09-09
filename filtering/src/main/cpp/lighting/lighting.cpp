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
#include <cassert>
#include <algorithm>
#include "cpu_dispatch.h"
#include "shared/math_utils.h"

#if defined(__aarch64__)
// Hand-written AArch64/AdvSIMD distant-light diffuse kernel (lighting_distant_diffuse_aarch64_neon.S).
extern "C" void ksvgLightingDistantDiffuseRowNeon64(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params);
#elif defined(__arm__)
// Hand-written ARM32/AdvSIMD distant-light diffuse kernel (lighting_distant_diffuse_armv7a_neon.S).
extern "C" void ksvgLightingDistantDiffuseRowNeon32(
    const jint* srcT, const jint* srcM, const jint* srcB,
    jint* dst, jint count, const LightingParams* params);
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

 jint sRgbToLight(const jint c) {
    const float a = static_cast<float>(c) / 255.f;
    const float v = a <= 0.04045f ? a / 12.92f * 255.f
                                    : std::pow((a + 0.055f) / 1.055f, 2.4f) * 255.f;
    return ksvg::clamp255(v);
}

 jint linearToLightSRgb(const jint c) {
    const float a = static_cast<float>(c) / 255.f;
    const float v = a <= 0.0031308f ? a * 12.92f * 255.f
                                      : (1.055f * std::pow(a, 1.f / 2.4f) - 0.055f) * 255.f;
    return ksvg::clamp255(v);
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
        const double p = std::pow(static_cast<double>(ndoth), static_cast<double>(exponent));
        intensity = clamp01(k * static_cast<float>(p) * factor);
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
        const bool premultiplied, const bool useLinear, jint backend) {
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
        if (lightType == 0 && !isSpecular && !useLinear && ixHi - ixLo >= 4) {
            const jint count = ixHi - ixLo & ~3;
            if (count > 0) {
                const jint* srcT = pix + (y - 1) * width + (x - 1);
                const jint* srcM = pix + y * width + (x - 1);
                const jint* srcB = pix + (y + 1) * width + (x - 1);
                jint* rowOut = out + rowOffset + x;

#if defined(__aarch64__)
                assert(backend == SIMD_BACKEND_NEON64);
                ksvgLightingDistantDiffuseRowNeon64(srcT, srcM, srcB, rowOut, count, &lp);
#elif defined(__arm__)
                assert(backend == SIMD_BACKEND_NEON32);
                ksvgLightingDistantDiffuseRowNeon32(srcT, srcM, srcB, rowOut, count, &lp);
#elif defined(__i386__) || defined(__x86_64__)
#if defined(__x86_64__)
                switch (backend) {
                    case SIMD_BACKEND_AVX512: {
                        const jint c16 = (ixHi - x) & ~15;
                        if (c16 > 0) {
                            ksvgLightingDistantDiffuseRowAvx512(srcT, srcM, srcB, rowOut, c16, &lp);
                            x += c16; srcT += c16; srcM += c16; srcB += c16; rowOut += c16;
                        }
                        break;
                    }
                    case SIMD_BACKEND_AVX2: {
                        const jint c8 = (ixHi - x) & ~7;
                        if (c8 > 0) {
                            ksvgLightingDistantDiffuseRowAvx2(srcT, srcM, srcB, rowOut, c8, &lp);
                            x += c8; srcT += c8; srcM += c8; srcB += c8; rowOut += c8;
                        }
                        break;
                    }
                    case SIMD_BACKEND_SSE2: {
                        const jint c4 = (ixHi - x) & ~3;
                        if (c4 > 0) {
                            ksvgLightingDistantDiffuseRowSse2(srcT, srcM, srcB, rowOut, c4, &lp);
                            x += c4; srcT += c4; srcM += c4; srcB += c4; rowOut += c4;
                        }
                        break;
                    }
                    default:
                        assert(false && "unsupported forced lighting backend on x86-64");
                }
#else
                assert(backend == SIMD_BACKEND_SSE2);
                const jint c4 = (ixHi - x) & ~3;
                if (c4 > 0) {
                    ksvgLightingDistantDiffuseRowSse2(srcT, srcM, srcB, rowOut, c4, &lp);
                    x += c4;
                }
#endif
#else
                (void)backend;
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
#elif defined(__i386__) || defined(__x86_64__)
    backends |= SIMD_BACKEND_SSE2;
#if defined(__x86_64__)
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) backends |= SIMD_BACKEND_AVX2;
    if (level >= SIMD_AVX512) backends |= SIMD_BACKEND_AVX512;
#endif
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
#elif defined(__i386__) || defined(__x86_64__)
    backend = SIMD_BACKEND_SSE2;
#if defined(__x86_64__)
    const SimdLevel level = detectSimdLevel();
    if (level >= SIMD_AVX2) backend = SIMD_BACKEND_AVX2;
    if (level >= SIMD_AVX512) backend = SIMD_BACKEND_AVX512;
#endif
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
