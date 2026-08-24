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
// Scalar this round; the distant-light case (constant light vector) is the
// natural candidate for a 4-pixel SIMD follow-up.

namespace {

inline jint clamp255f(const float v) {
    jint i = static_cast<jint>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

inline float heightAt(const jint* pix, const jint width, const jint height, const jint x, const jint y, const float ss) {
    jint cx = x < 0 ? 0 : (x > width - 1 ? width - 1 : x);
    jint cy = y < 0 ? 0 : (y > height - 1 ? height - 1 : y);
    return static_cast<float>((pix[cy * width + cx] >> 24) & 0xff) * ss;
}

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_LightingNative_apply(
        JNIEnv* env, jclass clazz,
        jintArray jPix, jintArray jOut,
        jint width, jint height,
        jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
        jfloat surfaceScaleNormalized,
        jdouble invCanvasScaleX, jdouble invCanvasScaleY,
        jdouble userLeft, jdouble userTop,
        jdouble originX, jdouble originY,
        jdouble unitSizeX, jdouble unitSizeY,
        jfloat canvasScaleX, jfloat canvasScaleY,
        jint lightType, jboolean specular,
        jfloat k, jfloat exponent,
        jint lightR, jint lightG, jint lightB,
        jdoubleArray jParams) {
    auto* pix = static_cast<jint*>(env->GetPrimitiveArrayCritical(jPix, nullptr));
    if (pix == nullptr) return;
    auto* out = static_cast<jint*>(env->GetPrimitiveArrayCritical(jOut, nullptr));
    jdouble* params = env->GetDoubleArrayElements(jParams, nullptr);
    if (out == nullptr || params == nullptr) {
        if (out != nullptr) env->ReleasePrimitiveArrayCritical(jOut, out, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jPix, pix, JNI_ABORT);
        return;
    }

    const bool isSpecular = specular == JNI_TRUE;
    const float fr = static_cast<float>(lightR);
    const float fg = static_cast<float>(lightG);
    const float fb = static_cast<float>(lightB);

    // Precompute the constant parts of the light vector for distant light.
    float dlx = 0.f, dly = 0.f, dlz = 0.f; // distant direction
    if (lightType == 0) {
        const double az = params[0] * M_PI / 180.0;
        const double el = params[1] * M_PI / 180.0;
        dlx = static_cast<float>(std::cos(az) * std::cos(el));
        dly = static_cast<float>(std::sin(az) * std::cos(el));
        dlz = static_cast<float>(std::sin(el));
    }
    const double coneCos = std::cos(params[6] * M_PI / 180.0);
    const bool hasCone = lightType == 2 && !std::isnan(params[6]);

    for (jint y = clipTop; y < clipBottom; y++) {
        const jdouble userY = userTop + y * invCanvasScaleY;
        const float uy = static_cast<float>((userY - originY) / unitSizeY);
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jdouble userX = userLeft + x * invCanvasScaleX;
            const float ux = static_cast<float>((userX - originX) / unitSizeX);

            const float surfaceZ = heightAt(pix, width, height, x, y, surfaceScaleNormalized);

            // Light vector (Lx,Ly,Lz,factor).
            float lx, ly, lz, factor;
            if (lightType == 0) {
                lx = dlx; ly = dly; lz = dlz; factor = 1.f;
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
                        const double sx = tx / tLen, sy = ty / tLen, sz = tz / tLen;
                        double dot = sx * -lx + sy * -ly + sz * -lz;
                        if (dot < -1.0) dot = -1.0; else if (dot > 1.0) dot = 1.0;
                        float f = static_cast<float>(dot);
                        if (hasCone && static_cast<double>(f) < coneCos) f = 0.f;
                        factor = f < 0.f ? 0.f : f;
                    }
                }
            }

            // 3x3 Sobel surface gradient.
            const float dzdx = (heightAt(pix, width, height, x + 1, y - 1, surfaceScaleNormalized) +
                                2 * heightAt(pix, width, height, x + 1, y,     surfaceScaleNormalized) +
                                heightAt(pix, width, height, x + 1, y + 1, surfaceScaleNormalized) -
                               (heightAt(pix, width, height, x - 1, y - 1, surfaceScaleNormalized) +
                                2 * heightAt(pix, width, height, x - 1, y,     surfaceScaleNormalized) +
                                heightAt(pix, width, height, x - 1, y + 1, surfaceScaleNormalized))) / (4.f / canvasScaleX);
            const float dzdy = (heightAt(pix, width, height, x - 1, y + 1, surfaceScaleNormalized) +
                                2 * heightAt(pix, width, height, x,     y + 1, surfaceScaleNormalized) +
                                heightAt(pix, width, height, x + 1, y + 1, surfaceScaleNormalized) -
                               (heightAt(pix, width, height, x - 1, y - 1, surfaceScaleNormalized) +
                                2 * heightAt(pix, width, height, x,     y - 1, surfaceScaleNormalized) +
                                heightAt(pix, width, height, x + 1, y - 1, surfaceScaleNormalized))) / (4.f / canvasScaleY);

            // Surface normal.
            float nx = -dzdx, ny = -dzdy, nz = 1.f;
            const float nLen = std::sqrt(nx * nx + ny * ny + nz * nz);
            if (nLen != 0.f) { nx /= nLen; ny /= nLen; nz /= nLen; }

            float intensity;
            if (!isSpecular) {
                float dot = nx * lx + ny * ly + nz * lz;
                if (dot < 0.f) dot = 0.f;
                intensity = dot * k * factor;
                if (intensity < 0.f) intensity = 0.f; else if (intensity > 1.f) intensity = 1.f;
            } else {
                float hx = lx, hy = ly, hz = lz + 1.f;
                const float hLen = std::sqrt(hx * hx + hy * hy + hz * hz);
                if (hLen != 0.f) { hx /= hLen; hy /= hLen; hz /= hLen; }
                float ndoth = nx * hx + ny * hy + nz * hz;
                if (ndoth < 0.f) ndoth = 0.f;
                double p = std::pow(static_cast<double>(ndoth), static_cast<double>(exponent));
                float v = k * static_cast<float>(p) * factor;
                intensity = v < 0.f ? 0.f : (v > 1.f ? 1.f : v);
            }

            const jint outR = clamp255f(fr * intensity);
            const jint outG = clamp255f(fg * intensity);
            const jint outB = clamp255f(fb * intensity);
            const jint outA = isSpecular
                    ? (outR > outG ? (outR > outB ? outR : outB) : (outG > outB ? outG : outB))
                    : 255;
            out[rowOffset + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }

    env->ReleaseDoubleArrayElements(jParams, params, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jOut, out, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jPix, pix, JNI_ABORT);
}
