//    Copyright 2026 András Oravecz <info@oandras.hu>
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        https://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

#include <jni.h>
#include <cmath>
#include <cassert>
#include "cpu_dispatch.h"
#include "fe_blend.h"
#include "color_luts.h"
#include "shared/math_utils.h"

namespace {

// Scalar reference for feBlend (all non-normal modes). Bit-exact twin of
// KotlinKernels.feBlend: same operation order, same LUTs, -ffp-contract=off.
// kotlin.math.sqrt(Float) on the JVM is a double sqrt narrowed back to float,
// so the soft-light branch mirrors that instead of calling sqrtf.
inline float softLightD(const float cb) {
    if (cb <= 0.25f) {
        return ((16.f * cb - 12.f) * cb + 4.f) * cb;
    }
    return static_cast<float>(std::sqrt(static_cast<double>(cb)));
}

inline float separableBlend(const float cb, const float cs, const jint mode) {
    switch (mode) {
        case FE_BLEND_MULTIPLY: return cb * cs;
        case FE_BLEND_SCREEN: return cb + cs - cb * cs;
        case FE_BLEND_OVERLAY: return cb <= 0.5f ? 2.f * cb * cs : 1.f - 2.f * (1.f - cb) * (1.f - cs);
        case FE_BLEND_DARKEN: return cb < cs ? cb : cs;
        case FE_BLEND_LIGHTEN: return cb > cs ? cb : cs;
        case FE_BLEND_COLOR_DODGE:
            if (cb == 0.f) return 0.f;
            if (cs >= 1.f) return 1.f;
            { const float v = cb / (1.f - cs); return v > 1.f ? 1.f : v; }
        case FE_BLEND_COLOR_BURN:
            if (cb >= 1.f) return 1.f;
            if (cs <= 0.f) return 0.f;
            { const float v = (1.f - cb) / cs; return 1.f - (v > 1.f ? 1.f : v); }
        case FE_BLEND_HARD_LIGHT: return cs <= 0.5f ? 2.f * cs * cb : 1.f - 2.f * (1.f - cs) * (1.f - cb);
        case FE_BLEND_SOFT_LIGHT: {
            const float d = softLightD(cb);
            return cb + (2.f * cs - 1.f) * (d - cb);
        }
        case FE_BLEND_DIFFERENCE: return std::fabs(cb - cs);
        default: return cb + cs - 2.f * cb * cs; // FE_BLEND_EXCLUSION
    }
}

inline float blendLuminosity(const float r, const float g, const float b) {
    return 0.3f * r + 0.59f * g + 0.11f * b;
}

inline float blendSaturation(const float r, const float g, const float b) {
    const float cMax = r > g ? (r > b ? r : b) : (g > b ? g : b);
    const float cMin = r < g ? (r < b ? r : b) : (g < b ? g : b);
    return cMax - cMin;
}

inline float blendClipColorChannel(const float r, const float g, const float b, const int channel) {
    const float l = blendLuminosity(r, g, b);
    const float n = r < g ? (r < b ? r : b) : (g < b ? g : b);
    const float x = r > g ? (r > b ? r : b) : (g > b ? g : b);
    float c = channel == 0 ? r : channel == 1 ? g : b;
    if (n < 0.f) {
        c = l + ((c - l) * l / (l - n));
    }
    if (x > 1.f) {
        c = l + ((c - l) * (1.f - l) / (x - l));
    }
    return c;
}

inline float blendSetLumChannel(const float r, const float g, const float b, const float l, const int channel) {
    const float d = l - blendLuminosity(r, g, b);
    return blendClipColorChannel(r + d, g + d, b + d, channel);
}

inline float blendSetSatChannel(const float r, const float g, const float b, const float s, const int channel) {
    const float cMax = r > g ? (r > b ? r : b) : (g > b ? g : b);
    const float cMin = r < g ? (r < b ? r : b) : (g < b ? g : b);
    if (cMax <= cMin) return 0.f;
    const float c = channel == 0 ? r : channel == 1 ? g : b;
    if (c == cMax) return s;
    if (c == cMin) return 0.f;
    return (c - cMin) * s / (cMax - cMin);
}

inline float nonSeparableBlendChannel(
        const float br, const float bg, const float bb,
        const float sr, const float sg, const float sb,
        const jint mode, const int channel) {
    float blended;
    switch (mode) {
        case FE_BLEND_HUE: {
            const float sR = blendSetSatChannel(sr, sg, sb, blendSaturation(br, bg, bb), 0);
            const float sG = blendSetSatChannel(sr, sg, sb, blendSaturation(br, bg, bb), 1);
            const float sB = blendSetSatChannel(sr, sg, sb, blendSaturation(br, bg, bb), 2);
            blended = blendSetLumChannel(sR, sG, sB, blendLuminosity(br, bg, bb), channel);
            break;
        }
        case FE_BLEND_SATURATION: {
            const float sR = blendSetSatChannel(br, bg, bb, blendSaturation(sr, sg, sb), 0);
            const float sG = blendSetSatChannel(br, bg, bb, blendSaturation(sr, sg, sb), 1);
            const float sB = blendSetSatChannel(br, bg, bb, blendSaturation(sr, sg, sb), 2);
            blended = blendSetLumChannel(sR, sG, sB, blendLuminosity(br, bg, bb), channel);
            break;
        }
        case FE_BLEND_COLOR:
            blended = blendSetLumChannel(sr, sg, sb, blendLuminosity(br, bg, bb), channel);
            break;
        default: // FE_BLEND_LUMINOSITY
            blended = blendSetLumChannel(br, bg, bb, blendLuminosity(sr, sg, sb), channel);
            break;
    }
    return blended;
}

template <bool kUseLinear>
void applyFeBlendScalarImpl(
        const jint* src, const jint* dst, jint* out,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jint mode) {
    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        for (jint x = clipLeft; x < clipRight; x++) {
            const jint i = rowOffset + x;
            const jint p = src[i];
            const jint q = dst[i];
            const float asAlpha = ((p >> 24) & 0xFF) / 255.f;
            const float abAlpha = ((q >> 24) & 0xFF) / 255.f;
            const float aoAlpha = asAlpha + abAlpha - asAlpha * abAlpha;
            if (aoAlpha <= 0.f) {
                out[i] = 0;
                continue;
            }
            float sr, sg, sb, br, bg, bb;
            if constexpr (kUseLinear) {
                sr = ksvg_srgb_to_linear_lut[(p >> 16) & 0xFF] / 255.f;
                sg = ksvg_srgb_to_linear_lut[(p >> 8) & 0xFF] / 255.f;
                sb = ksvg_srgb_to_linear_lut[p & 0xFF] / 255.f;
                br = ksvg_srgb_to_linear_lut[(q >> 16) & 0xFF] / 255.f;
                bg = ksvg_srgb_to_linear_lut[(q >> 8) & 0xFF] / 255.f;
                bb = ksvg_srgb_to_linear_lut[q & 0xFF] / 255.f;
            } else {
                sr = ((p >> 16) & 0xFF) / 255.f;
                sg = ((p >> 8) & 0xFF) / 255.f;
                sb = (p & 0xFF) / 255.f;
                br = ((q >> 16) & 0xFF) / 255.f;
                bg = ((q >> 8) & 0xFF) / 255.f;
                bb = (q & 0xFF) / 255.f;
            }
            float tr, tg, tb;
            if (mode >= FE_BLEND_HUE) {
                tr = nonSeparableBlendChannel(br, bg, bb, sr, sg, sb, mode, 0);
                tg = nonSeparableBlendChannel(br, bg, bb, sr, sg, sb, mode, 1);
                tb = nonSeparableBlendChannel(br, bg, bb, sr, sg, sb, mode, 2);
            } else {
                tr = separableBlend(br, sr, mode);
                tg = separableBlend(bg, sg, mode);
                tb = separableBlend(bb, sb, mode);
            }
            // CSS general compositing around the blended triple.
            const float csR = sr, csG = sg, csB = sb;
            const float cbR = br, cbG = bg, cbB = bb;
            const float or_ = ((1.f - abAlpha) * csR * asAlpha + (1.f - asAlpha) * cbR * abAlpha +
                    asAlpha * abAlpha * tr) / aoAlpha;
            const float og = ((1.f - abAlpha) * csG * asAlpha + (1.f - asAlpha) * cbG * abAlpha +
                    asAlpha * abAlpha * tg) / aoAlpha;
            const float ob = ((1.f - abAlpha) * csB * asAlpha + (1.f - asAlpha) * cbB * abAlpha +
                    asAlpha * abAlpha * tb) / aoAlpha;
            int outR, outG, outB;
            if constexpr (kUseLinear) {
                outR = ksvg_linear_to_srgb_lut[ksvg::clamp255(or_ * 255.f)];
                outG = ksvg_linear_to_srgb_lut[ksvg::clamp255(og * 255.f)];
                outB = ksvg_linear_to_srgb_lut[ksvg::clamp255(ob * 255.f)];
            } else {
                outR = ksvg::clamp255(or_ * 255.f);
                outG = ksvg::clamp255(og * 255.f);
                outB = ksvg::clamp255(ob * 255.f);
            }
            const int outA = ksvg::clamp255(aoAlpha * 255.f);
            out[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }
}

} // namespace

extern "C" {
void applyFeBlendScalar(
        const jint* src, const jint* dst, jint* out,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jint mode,
        const jboolean useLinear,
        [[maybe_unused]] const jbyte* srgbToLinear, [[maybe_unused]] const jbyte* linearToSrgb) {
    if (useLinear == JNI_TRUE) {
        applyFeBlendScalarImpl<true>(src, dst, out, width, clipLeft, clipTop, clipRight, clipBottom, mode);
    } else {
        applyFeBlendScalarImpl<false>(src, dst, out, width, clipLeft, clipTop, clipRight, clipBottom, mode);
    }
}
}

namespace {

jint nativeBackendForAbi() {
    // Scalar-only family on every ABI.
    return SIMD_BACKEND_SCALAR;
}

void runForced(const jint* src, const jint* dst, jint* out,
               const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
               const jint mode, const jboolean useLinear,
               const jint backend) {
    const auto* srgbToLinear = reinterpret_cast<const jbyte*>(ksvg_srgb_to_linear_lut);
    const auto* linearToSrgb = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
    if (backend == SIMD_BACKEND_SCALAR) {
        applyFeBlendScalar(src, dst, out, width, clipLeft, clipTop, clipRight, clipBottom,
                           mode, useLinear, srgbToLinear, linearToSrgb);
    } else {
        assert(false && "unsupported forced fe_blend backend (scalar-only family)");
    }
}

} // namespace

extern "C" JNIEXPORT jint JNICALL
Java_hu_oandras_ksvg_filtering_FeBlendNative_nativeBackend(
    [[maybe_unused]] JNIEnv* env, [[maybe_unused]] jclass clazz) {
    return nativeBackendForAbi();
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_FeBlendNative_applyForcedNative(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst, const jintArray jOut,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jint mode, const jboolean useLinear,
        const jint simdBackend) {
    jint* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    jint* out = static_cast<jint*>(env->GetPrimitiveArrayCritical(jOut, nullptr));

    if (src && dst && out) {
        runForced(src, dst, out, width, clipLeft, clipTop, clipRight, clipBottom,
                  mode, useLinear, simdBackend);
    }

    if (out) env->ReleasePrimitiveArrayCritical(jOut, out, 0);
    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    if (src) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_FeBlendNative_applyNative(
        JNIEnv* env, [[maybe_unused]] jclass clazz,
        const jintArray jSrc, const jintArray jDst, const jintArray jOut,
        const jint width, const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jint mode, const jboolean useLinear) {
    const auto* srgbToLinear = reinterpret_cast<const jbyte*>(ksvg_srgb_to_linear_lut);
    const auto* linearToSrgb = reinterpret_cast<const jbyte*>(ksvg_linear_to_srgb_lut);
    jint* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    jint* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    jint* out = static_cast<jint*>(env->GetPrimitiveArrayCritical(jOut, nullptr));

    if (src && dst && out) {
        applyFeBlendScalar(src, dst, out, width, clipLeft, clipTop, clipRight, clipBottom,
                           mode, useLinear, srgbToLinear, linearToSrgb);
    }

    if (out) env->ReleasePrimitiveArrayCritical(jOut, out, 0);
    if (dst) env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    if (src) env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
}
