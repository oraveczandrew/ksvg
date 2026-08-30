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
#include "cpu_dispatch.h"
#include "simd_x86.h"

// feConvolveMatrix kernel over ARGB_8888 IntArrays (Bitmap.getPixels layout).
//
// Bit-exact port of the reference Kotlin loop in FilterGeometry.kt:
// - per-channel float accumulation in the same ky/kx order,
// - output = channel/divisor + bias*255, rounded half-up (floor(x+0.5)) and
//   clamped to [0,255] — for negative results truncation vs floor is
//   irrelevant since both clamp to 0,
// - preserveAlpha copies the source alpha instead of the accumulated one,
// - edge modes match sampleCoordinate(): duplicate(clamp), wrap(modulo),
//   none(transparent).
//
// Acceleration (AArch64 NEON): with edgeMode==duplicate the interior region
// (where every tap reads in-bounds pixels) processes 4 pixels per iteration
// using f32x4 accumulation. The operation sequence mirrors the scalar loop
// (mul then add, explicit divide, no FMA) and the whole module compiles with
// -ffp-contract=off, so vector output is bit-identical to the scalar/fallback
// path. Borders and non-duplicate edge modes run the scalar reference loop.
// armv7 / x86 remain fully scalar.

namespace {

 jint clamp255(const float v) {
    const jint i = static_cast<jint>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

 jint sampleX(const jint x, const jint limit, const jint edgeMode) {
    if (x >= 0 && x < limit) return x;
    switch (edgeMode) {
        case 2: return -1;               // none -> transparent contribution
        case 1: {                        // wrap
            const jint m = x % limit;
            return m < 0 ? m + limit : m;
        }
        default: return x < 0 ? 0 : limit - 1; // duplicate
    }
}

 jint sampleY(const jint y, const jint limit, const jint edgeMode) { return sampleX(y, limit, edgeMode); }

 void convolveScalarPixel(
        const jint* src, jint* dst, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const bool preserve, const jint edgeMode, const jint x, const jint y) {
    float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
    for (jint ky = 0; ky < orderY; ky++) {
        const jint srcY = sampleY(y + ky - targetY, height, edgeMode);
        for (jint kx = 0; kx < orderX; kx++) {
            const jint srcX = sampleX(x + kx - targetX, width, edgeMode);
            const jint pixel = (srcX < 0 || srcY < 0) ? 0 : src[srcY * width + srcX];
            const float w = kernel[ky * orderX + kx];
            r += static_cast<float>((pixel >> 16) & 0xFF) * w;
            g += static_cast<float>((pixel >> 8) & 0xFF) * w;
            b += static_cast<float>(pixel & 0xFF) * w;
            a += static_cast<float>((pixel >> 24) & 0xFF) * w;
        }
    }
    const jint outR = clamp255(r / divisor + bias * 255.f);
    const jint outG = clamp255(g / divisor + bias * 255.f);
    const jint outB = clamp255(b / divisor + bias * 255.f);
    const jint outA = preserve ? (src[y * width + x] >> 24) & 0xFF
                               : clamp255(a / divisor + bias * 255.f);
    dst[y * width + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
}

void applyScalar(
        const jint* src, jint* dst, const jint width, const jint height,
        const jfloat* kernel,
        const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha, const jint edgeMode) {
    const bool preserve = preserveAlpha == JNI_TRUE;
    for (jint y = 0; y < height; y++) {
        const jint rowOffset = y * width;
        for (jint x = 0; x < width; x++) {
            float r = 0.f, g = 0.f, b = 0.f, a = 0.f;

            for (jint ky = 0; ky < orderY; ky++) {
                const jint srcY = sampleY(y + ky - targetY, height, edgeMode);
                for (jint kx = 0; kx < orderX; kx++) {
                    const jint srcX = sampleX(x + kx - targetX, width, edgeMode);
                    const jint pixel =
                            (srcX < 0 || srcY < 0) ? 0 : src[srcY * width + srcX];
                    const float weight = kernel[ky * orderX + kx];

                    r += static_cast<float>((pixel >> 16) & 0xFF) * weight;
                    g += static_cast<float>((pixel >> 8) & 0xFF) * weight;
                    b += static_cast<float>(pixel & 0xFF) * weight;
                    a += static_cast<float>((pixel >> 24) & 0xFF) * weight;
                }
            }

            const jint outR = clamp255(r / divisor + bias * 255.f);
            const jint outG = clamp255(g / divisor + bias * 255.f);
            const jint outB = clamp255(b / divisor + bias * 255.f);
            const jint outA = preserve
                              ? (src[rowOffset + x] >> 24) & 0xFF
                              : clamp255(a / divisor + bias * 255.f);
            dst[rowOffset + x] =
                    (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }
}

#ifdef __aarch64__

#include <arm_neon.h>

void applyNeonInterior(
        jint* dst, const jint* src, jint width, jint height,
        const jfloat* kernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, bool preserve) {
    const float32x4_t vDivisor = vdupq_n_f32(divisor);
    const float32x4_t vBias255 = vmulq_f32(vdupq_n_f32(bias), vdupq_n_f32(255.0f));
    const float32x4_t vHalf = vdupq_n_f32(0.5f);
    const uint32x4_t maskFF = vdupq_n_u32(0xFF);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;   // exclusive
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;    // exclusive

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;

        // Left border, scalar.
        for (jint x = 0; x < xLo; x++) {
            float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
            for (jint ky = 0; ky < orderY; ky++) {
                const jint srcY = sampleY(y + ky - targetY, height, 0);
                for (jint kx = 0; kx < orderX; kx++) {
                    const jint srcX = sampleX(x + kx - targetX, width, 0);
                    const jint pixel = src[srcY * width + srcX];
                    const float w = kernel[ky * orderX + kx];
                    r += static_cast<float>((pixel >> 16) & 0xFF) * w;
                    g += static_cast<float>((pixel >> 8) & 0xFF) * w;
                    b += static_cast<float>(pixel & 0xFF) * w;
                    a += static_cast<float>((pixel >> 24) & 0xFF) * w;
                }
            }
            const jint outR = clamp255(r / divisor + bias * 255.f);
            const jint outG = clamp255(g / divisor + bias * 255.f);
            const jint outB = clamp255(b / divisor + bias * 255.f);
            const jint outA = preserve ? (src[rowOffset + x] >> 24) & 0xFF
                                       : clamp255(a / divisor + bias * 255.f);
            dst[rowOffset + x] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }

        // Interior, 4 pixels per iteration.
        jint x = xLo;
        const jint vecEnd = xLo + ((xHi - xLo) & ~3);
        for (; x < vecEnd; x += 4) {
            float32x4_t accR = vdupq_n_f32(0.f);
            float32x4_t accG = vdupq_n_f32(0.f);
            float32x4_t accB = vdupq_n_f32(0.f);
            float32x4_t accA = vdupq_n_f32(0.f);

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* row = src + (y + ky - targetY) * width;
                for (jint kx = 0; kx < orderX; kx++) {
                    const float32x4_t w = vdupq_n_f32(kernel[ky * orderX + kx]);
                    const uint32x4_t p = vld1q_u32(reinterpret_cast<const uint32_t*>(row + x));
                    const uint32x4_t tb = vandq_u32(p, maskFF);
                    const uint32x4_t tg = vandq_u32(vshrq_n_u32(p, 8), maskFF);
                    const uint32x4_t tr = vandq_u32(vshrq_n_u32(p, 16), maskFF);
                    const uint32x4_t ta = vshrq_n_u32(p, 24);
                    accB = vaddq_f32(accB, vmulq_f32(vcvtq_f32_u32(tb), w));
                    accG = vaddq_f32(accG, vmulq_f32(vcvtq_f32_u32(tg), w));
                    accR = vaddq_f32(accR, vmulq_f32(vcvtq_f32_u32(tr), w));
                    accA = vaddq_f32(accA, vmulq_f32(vcvtq_f32_u32(ta), w));
                }
            }

            float32x4_t oR = vaddq_f32(vdivq_f32(accR, vDivisor), vBias255);
            float32x4_t oG = vaddq_f32(vdivq_f32(accG, vDivisor), vBias255);
            float32x4_t oB = vaddq_f32(vdivq_f32(accB, vDivisor), vBias255);
            float32x4_t oA = vaddq_f32(vdivq_f32(accA, vDivisor), vBias255);
            int32x4_t iR = vcvtq_s32_f32(vaddq_f32(oR, vHalf));
            int32x4_t iG = vcvtq_s32_f32(vaddq_f32(oG, vHalf));
            int32x4_t iB = vcvtq_s32_f32(vaddq_f32(oB, vHalf));
            int32x4_t iA = vcvtq_s32_f32(vaddq_f32(oA, vHalf));

            if (!preserve) {
                iR = vmaxq_s32(vminq_s32(iR, vdupq_n_s32(255)), vdupq_n_s32(0));
                iG = vmaxq_s32(vminq_s32(iG, vdupq_n_s32(255)), vdupq_n_s32(0));
                iB = vmaxq_s32(vminq_s32(iB, vdupq_n_s32(255)), vdupq_n_s32(0));
                iA = vmaxq_s32(vminq_s32(iA, vdupq_n_s32(255)), vdupq_n_s32(0));
            } else {
                const uint32x4_t ps = vld1q_u32(reinterpret_cast<const uint32_t*>(src + rowOffset + x));
                iA = vreinterpretq_s32_u32(vshrq_n_u32(ps, 24));
            }

            const uint32x4_t out = vorrq_u32(
                    vorrq_u32(vshlq_n_u32(vreinterpretq_u32_s32(iA), 24),
                              vshlq_n_u32(vreinterpretq_u32_s32(iR), 16)),
                    vorrq_u32(vshlq_n_u32(vreinterpretq_u32_s32(iG), 8),
                              vreinterpretq_u32_s32(iB)));
            vst1q_u32(reinterpret_cast<uint32_t*>(dst + rowOffset + x), out);
        }

        // Right border, scalar.
        for (jint xr = x; xr < xHi; xr++) {
            float r = 0.f, g = 0.f, b = 0.f, a = 0.f;
            for (jint ky = 0; ky < orderY; ky++) {
                const jint srcY = sampleY(y + ky - targetY, height, 0);
                for (jint kx = 0; kx < orderX; kx++) {
                    const jint srcX = sampleX(xr + kx - targetX, width, 0);
                    const jint pixel = src[srcY * width + srcX];
                    const float w = kernel[ky * orderX + kx];
                    r += static_cast<float>((pixel >> 16) & 0xFF) * w;
                    g += static_cast<float>((pixel >> 8) & 0xFF) * w;
                    b += static_cast<float>(pixel & 0xFF) * w;
                    a += static_cast<float>((pixel >> 24) & 0xFF) * w;
                }
            }
            const jint outR = clamp255(r / divisor + bias * 255.f);
            const jint outG = clamp255(g / divisor + bias * 255.f);
            const jint outB = clamp255(b / divisor + bias * 255.f);
            const jint outA = preserve ? (src[rowOffset + xr] >> 24) & 0xFF
                                       : clamp255(a / divisor + bias * 255.f);
            dst[rowOffset + xr] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
    }
}

#endif // __aarch64__

#if !defined(__aarch64__) && defined(__SSE2__)
#include <emmintrin.h>

/**
 * x86 SSE2 mirror of applyNeonInterior: duplicate-edge interior 4 px/iter,
 * borders scalar. Rounding via _mm_cvttps_epi32(x + 0.5f): truncation equals
 * floor(+0.5) for positives and negatives clamp to 0 either way — bit-exact
 * with the scalar reference.
 */
inline __m128i clamp255Sse(__m128i v) {
    const __m128i zero = _mm_setzero_si128();
    const __m128i isPos = _mm_cmpgt_epi32(v, zero);
    v = _mm_and_si128(v, isPos);
    const __m128i over = _mm_cmpgt_epi32(v, _mm_set1_epi32(255));
    return _mm_or_si128(_mm_andnot_si128(over, v), _mm_and_si128(over, _mm_set1_epi32(255)));
}

void applySseInterior(
        jint* dst, const jint* src, jint width, jint height,
        const jfloat* kernel, jint orderX, jint orderY, jint targetX, jint targetY,
        jfloat divisor, jfloat bias, bool preserve) {
    const __m128 vDivisor = _mm_set1_ps(divisor);
    const __m128 vBias255 = _mm_mul_ps(_mm_set1_ps(bias), _mm_set1_ps(255.0f));
    const __m128 vHalf = _mm_set1_ps(0.5f);
    const __m128i maskFF = _mm_set1_epi32(0xFF);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;

        for (jint x = 0; x < xLo; x++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                targetX, targetY, divisor, bias, preserve, 0, x, y);
        }

        jint x = xLo;
        const jint vecEnd = xLo + ((xHi - xLo) & ~3);
        for (; x < vecEnd; x += 4) {
            __m128 accR = _mm_setzero_ps();
            __m128 accG = _mm_setzero_ps();
            __m128 accB = _mm_setzero_ps();
            __m128 accA = _mm_setzero_ps();

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* row = src + (y + ky - targetY) * width;
                for (jint kx = 0; kx < orderX; kx++) {
                    const __m128 w = _mm_set1_ps(kernel[ky * orderX + kx]);
                    const __m128i p = _mm_loadu_si128(
                            reinterpret_cast<const __m128i*>(row + x));
                    const __m128i tb = _mm_and_si128(p, maskFF);
                    const __m128i tg = _mm_and_si128(_mm_srli_epi32(p, 8), maskFF);
                    const __m128i tr = _mm_and_si128(_mm_srli_epi32(p, 16), maskFF);
                    const __m128i ta = _mm_srli_epi32(p, 24);
                    accB = _mm_add_ps(accB, _mm_mul_ps(_mm_cvtepi32_ps(tb), w));
                    accG = _mm_add_ps(accG, _mm_mul_ps(_mm_cvtepi32_ps(tg), w));
                    accR = _mm_add_ps(accR, _mm_mul_ps(_mm_cvtepi32_ps(tr), w));
                    accA = _mm_add_ps(accA, _mm_mul_ps(_mm_cvtepi32_ps(ta), w));
                }
            }

            __m128 oR = _mm_add_ps(_mm_div_ps(accR, vDivisor), vBias255);
            __m128 oG = _mm_add_ps(_mm_div_ps(accG, vDivisor), vBias255);
            __m128 oB = _mm_add_ps(_mm_div_ps(accB, vDivisor), vBias255);
            __m128 oA = _mm_add_ps(_mm_div_ps(accA, vDivisor), vBias255);
            __m128i iR = _mm_cvttps_epi32(_mm_add_ps(oR, vHalf));
            __m128i iG = _mm_cvttps_epi32(_mm_add_ps(oG, vHalf));
            __m128i iB = _mm_cvttps_epi32(_mm_add_ps(oB, vHalf));
            __m128i iA = _mm_cvttps_epi32(_mm_add_ps(oA, vHalf));

            if (!preserve) {
                iR = clamp255Sse(iR);
                iG = clamp255Sse(iG);
                iB = clamp255Sse(iB);
                iA = clamp255Sse(iA);
            } else {
                const __m128i ps = _mm_loadu_si128(
                        reinterpret_cast<const __m128i*>(src + rowOffset + x));
                iA = _mm_srli_epi32(ps, 24);
            }

            const __m128i out = _mm_or_si128(
                    _mm_or_si128(_mm_slli_epi32(iA, 24), _mm_slli_epi32(iR, 16)),
                    _mm_or_si128(_mm_slli_epi32(iG, 8), iB));
            _mm_storeu_si128(reinterpret_cast<__m128i*>(dst + rowOffset + x), out);
        }

        for (jint xr = x; xr < xHi; xr++) {
            convolveScalarPixel(src, dst, width, height, kernel, orderX, orderY,
                                targetX, targetY, divisor, bias, preserve, 0, xr, y);
        }
    }
}

#endif // !__aarch64__ && __SSE2__

} // namespace

extern "C" JNIEXPORT void JNICALL
Java_hu_oandras_ksvg_filtering_ConvolveNative_apply(
        JNIEnv* env, jclass clazz,
        const jintArray jSrc, const jintArray jDst,
        jint width, jint height,
        const jfloatArray jKernel, jint orderX, jint orderY,
        jint targetX, jint targetY,
        jfloat divisor, jfloat bias,
        const jboolean preserveAlpha, const jint edgeMode) {
    // Fetch the small kernel array with a regular (non-critical) call BEFORE
    // entering any GetPrimitiveArrayCritical section: ART aborts on JNI calls
    // made between a critical get/release pair.
    auto* kernel = env->GetFloatArrayElements(jKernel, nullptr);
    if (kernel == nullptr) return;

    auto* src = static_cast<jint*>(env->GetPrimitiveArrayCritical(jSrc, nullptr));
    if (src == nullptr) {
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
    auto* dst = static_cast<jint*>(env->GetPrimitiveArrayCritical(jDst, nullptr));
    if (dst == nullptr) {
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }

#if defined(__aarch64__) || (!defined(__aarch64__) && defined(__SSE2__))
    if (edgeMode == 0 && height >= orderY && width >= orderX) {
        const bool preserve = preserveAlpha == JNI_TRUE;
        const jint yLo = targetY;
        const jint yHi = height - orderY + 1 + targetY;

        for (jint y = 0; y < yLo; y++) {
            for (jint x = 0; x < width; x++) convolveScalarPixel(
                    src, dst, width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
        for (jint y = yHi; y < height; y++) {
            for (jint x = 0; x < width; x++) convolveScalarPixel(
                    src, dst, width, height, kernel, orderX, orderY,
                    targetX, targetY, divisor, bias, preserve, 0, x, y);
        }
#ifdef __aarch64__
        applyNeonInterior(dst, src, width, height, kernel, orderX, orderY,
                          targetX, targetY, divisor, bias, preserve);
#else
        switch (detectSimdLevel()) {
            case SIMD_AVX512:
                ksvgConvolveApplyInteriorAvx512(dst, src, width, height, kernel,
                    orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            case SIMD_AVX2:
                ksvgConvolveApplyInteriorAvx2(dst, src, width, height, kernel,
                    orderX, orderY, targetX, targetY, divisor, bias, preserve);
                break;
            default:
                applySseInterior(dst, src, width, height, kernel, orderX, orderY,
                                 targetX, targetY, divisor, bias, preserve);
        }
#endif
        env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
        env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
        env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
        return;
    }
#endif

    applyScalar(src, dst, width, height, kernel,
                orderX, orderY, targetX, targetY, divisor, bias, preserveAlpha, edgeMode);

    env->ReleasePrimitiveArrayCritical(jDst, dst, JNI_ABORT);
    env->ReleasePrimitiveArrayCritical(jSrc, src, JNI_ABORT);
    env->ReleaseFloatArrayElements(jKernel, kernel, JNI_ABORT);
}
