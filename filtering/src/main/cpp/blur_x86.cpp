/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Gaussian-blur separable kernels, ported from the Android RenderScript
 * Intrinsics Replacement Toolkit (Apache-2.0). Only the blur kernels are kept;
 * the rest of the toolkit's intrinsics are not used by libksvgblur.
 */

// Only compiled on x86/x86_64 (see CMakeLists.txt); included in every ABI's
// target so IDEs don't flag it as orphaned.
#if defined(__i386__) || defined(__x86_64__)
#include <x86intrin.h>

/* Unsigned extend packed 8-bit integer (in LBS) into packed 32-bit integer */
static inline __m128i cvtepu8_epi32(__m128i x) {
#if defined(__SSE4_1__)
    return _mm_cvtepu8_epi32(x);
#elif defined(__SSSE3__)
    const __m128i M8to32 = _mm_set_epi32(0xffffff03, 0xffffff02, 0xffffff01, 0xffffff00);
    x = _mm_shuffle_epi8(x, M8to32);
    return x;
#else
#   error "Require at least SSSE3"
#endif
}

/* Vertical blur pass: convolve `rct` rows (stride bytes apart) for columns
 * [x1, x2), writing one float4 (a,r,g,b) per output column into `dst`.
 * `gptr[k]` is the weight for vertical offset k (k in [0, rct-1]). */
extern "C" void rsdIntrinsicBlurVFU4_K(void *dst,
                                       const void *pin, const int stride, const void *gptr,
                                       const int rct, int x1, const int x2) {
    for (; x1 < x2; x1 += 2) {
        const char *pi = static_cast<const char *>(pin) + (x1 << 2);
        __m128 bp0 = _mm_setzero_ps();
        __m128 bp1 = _mm_setzero_ps();

        for (int r = 0; r < rct; ++r) {
            __m128 x = _mm_load_ss(static_cast<const float *>(gptr) + r);
            x = _mm_shuffle_ps(x, x, _MM_SHUFFLE(0, 0, 0, 0));

            __m128i pi0 = _mm_cvtsi32_si128(*reinterpret_cast<const int *>(pi));
            __m128i pi1 = _mm_cvtsi32_si128(*(reinterpret_cast<const int *>(pi) + 1));

            __m128 pf0 = _mm_cvtepi32_ps(cvtepu8_epi32(pi0));
            __m128 pf1 = _mm_cvtepi32_ps(cvtepu8_epi32(pi1));

            bp0 = _mm_add_ps(bp0, _mm_mul_ps(pf0, x));
            bp1 = _mm_add_ps(bp1, _mm_mul_ps(pf1, x));

            pi += stride;
        }

        _mm_storeu_ps(static_cast<float *>(dst), bp0);
        _mm_storeu_ps(static_cast<float *>(dst) + 4, bp1);
        dst = static_cast<char *>(dst) + 32;
    }
}

/* Horizontal blur pass: convolve `rct` float4 columns for indices [x1, x2),
 * writing one premultiplied ARGB byte per output column into `dst`.
 * `gptr[k]` is the weight for horizontal offset k (k in [0, rct-1]); the caller
 * shifts `pin` so that pin[x1] is the center of the window. */
extern "C" void rsdIntrinsicBlurHFU4_K(void *dst,
                                       const void *pin, const void *gptr,
                                       const int rct, int x1, const int x2) {
    const __m128i Mu8 = _mm_set_epi32(0xffffffff, 0xffffffff, 0xffffffff, 0x0c080400);

    for (; x1 < x2; ++x1) {
        /* rct is define as 2*r+1 by the caller */
        __m128 x = _mm_load_ss(static_cast<const float *>(gptr));
        x = _mm_shuffle_ps(x, x, _MM_SHUFFLE(0, 0, 0, 0));

        const float *pi = static_cast<const float *>(pin) + (x1 << 2);
        __m128 pf = _mm_mul_ps(x, _mm_loadu_ps(pi));

        for (int r = 1; r < rct; r += 2) {
            x = _mm_load_ss(static_cast<const float *>(gptr) + r);
            __m128 y = _mm_load_ss(static_cast<const float *>(gptr) + r + 1);
            x = _mm_shuffle_ps(x, x, _MM_SHUFFLE(0, 0, 0, 0));
            y = _mm_shuffle_ps(y, y, _MM_SHUFFLE(0, 0, 0, 0));

            pf = _mm_add_ps(pf, _mm_mul_ps(x, _mm_loadu_ps(pi + (r << 2))));
            pf = _mm_add_ps(pf, _mm_mul_ps(y, _mm_loadu_ps(pi + (r << 2) + 4)));
        }

        __m128i o = _mm_cvtps_epi32(pf);
        *static_cast<int *>(dst) = _mm_cvtsi128_si32(_mm_shuffle_epi8(o, Mu8));
        dst = static_cast<char *>(dst) + 4;
    }
}

#endif // __i386__ || __x86_64__
