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

// AVX-512 widenings (64-byte vectors). This TU is compiled with
// -mavx512f -mavx512bw (see CMakeLists.txt) and is called only after runtime
// detection reports both. Exact width-widening: output bit-identical to the
// scalar/SSE2 reference loops.

#include <jni.h>
#include <cstring>
// Only compiled on x86/x86_64 (per-file ISA flags in CMakeLists.txt);
// included in every ABI's target so IDEs don't flag it as orphaned.
#if defined(__i386__) || defined(__x86_64__)

#include <immintrin.h>

extern "C" {

void ksvgMorphologyApplyPixelAvx512(
        const jint* src, jint* dst, const jint width,
        const jint radiusX, const jint radiusY, const jboolean erode, const jint x, const jint y) {
    const bool isErode = erode == JNI_TRUE;
    const jint top = y - radiusY;
    const jint bottom = y + radiusY;
    const jint left = x - radiusX;
    const jint right = x + radiusX;

    __m512i accMin = _mm512_set1_epi8(isErode ? -1 : 0);
    __m512i accMax = _mm512_setzero_si512();

    jint mins[4];
    jint maxs[4];
    {
        alignas(64) uint8_t buf[64];
        _mm512_storeu_si512(reinterpret_cast<void*>(buf), accMin);
        for (int ch = 0; ch < 4; ch++) { mins[ch] = buf[ch]; maxs[ch] = 0; }
    }

    for (jint ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        jint kx = left;
        for (; kx + 16 <= right + 1; kx += 16) {
            const __m512i c = _mm512_loadu_si512(reinterpret_cast<const void*>(row + kx));
            accMin = _mm512_min_epu8(accMin, c);
            accMax = _mm512_max_epu8(accMax, c);
        }
        for (; kx <= right; kx++) {
            const jint c = row[kx];
            const jint cb = c & 0xFF, cg = (c >> 8) & 0xFF, cr = (c >> 16) & 0xFF, ca = (c >> 24) & 0xFF;
            if (isErode) {
                if (cb < mins[0]) mins[0] = cb; if (cg < mins[1]) mins[1] = cg;
                if (cr < mins[2]) mins[2] = cr; if (ca < mins[3]) mins[3] = ca;
            } else {
                if (cb > maxs[0]) maxs[0] = cb; if (cg > maxs[1]) maxs[1] = cg;
                if (cr > maxs[2]) maxs[2] = cr; if (ca > maxs[3]) maxs[3] = ca;
            }
        }
    }

    alignas(64) uint8_t buf[64];
    _mm512_storeu_si512(reinterpret_cast<void*>(buf), isErode ? accMin : accMax);
    for (int ch = 0; ch < 4; ch++) {
        for (int p = 0; p < 16; p++) {
            const jint v = buf[p * 4 + ch];
            if (v < mins[ch]) mins[ch] = v;
            if (v > maxs[ch]) maxs[ch] = v;
        }
    }

    dst[y * width + x] =
            ((isErode ? mins[3] : maxs[3]) << 24) |
            ((isErode ? mins[2] : maxs[2]) << 16) |
            ((isErode ? mins[1] : maxs[1]) << 8) |
            (isErode ? mins[0] : maxs[0]);
}

void ksvgConvolveApplyInteriorAvx512(
        jint* dst, const jint* src, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha) {
    const bool preserve = preserveAlpha == JNI_TRUE;
    const __m512 vDivisor = _mm512_set1_ps(divisor);
    const __m512 vBias255 = _mm512_mul_ps(_mm512_set1_ps(bias), _mm512_set1_ps(255.0f));
    const __m512 vHalf = _mm512_set1_ps(0.5f);
    const __m512i maskFF = _mm512_set1_epi32(0xFF);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;
        for (jint x = xLo; x + 16 <= xHi; x += 16) {
            __m512 accR = _mm512_setzero_ps();
            __m512 accG = _mm512_setzero_ps();
            __m512 accB = _mm512_setzero_ps();
            __m512 accA = _mm512_setzero_ps();

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* row = src + (y + ky - targetY) * width;
                for (jint kx = 0; kx < orderX; kx++) {
                    const __m512 w = _mm512_set1_ps(kernel[ky * orderX + kx]);
                    const __m512i p = _mm512_loadu_si512(reinterpret_cast<const void*>(row + x));
                    const __m512i tb = _mm512_and_si512(p, maskFF);
                    const __m512i tg = _mm512_and_si512(_mm512_srli_epi32(p, 8), maskFF);
                    const __m512i tr = _mm512_and_si512(_mm512_srli_epi32(p, 16), maskFF);
                    const __m512i ta = _mm512_srli_epi32(p, 24);
                    accB = _mm512_add_ps(accB, _mm512_mul_ps(_mm512_cvtepu32_ps(tb), w));
                    accG = _mm512_add_ps(accG, _mm512_mul_ps(_mm512_cvtepu32_ps(tg), w));
                    accR = _mm512_add_ps(accR, _mm512_mul_ps(_mm512_cvtepu32_ps(tr), w));
                    accA = _mm512_add_ps(accA, _mm512_mul_ps(_mm512_cvtepu32_ps(ta), w));
                }
            }

            const __m512 oR = _mm512_add_ps(_mm512_div_ps(accR, vDivisor), vBias255);
            const __m512 oG = _mm512_add_ps(_mm512_div_ps(accG, vDivisor), vBias255);
            const __m512 oB = _mm512_add_ps(_mm512_div_ps(accB, vDivisor), vBias255);
            const __m512 oA = _mm512_add_ps(_mm512_div_ps(accA, vDivisor), vBias255);
            __m512i iR = _mm512_cvttps_epi32(_mm512_add_ps(oR, vHalf));
            __m512i iG = _mm512_cvttps_epi32(_mm512_add_ps(oG, vHalf));
            __m512i iB = _mm512_cvttps_epi32(_mm512_add_ps(oB, vHalf));
            __m512i iA = _mm512_cvttps_epi32(_mm512_add_ps(oA, vHalf));
            if (!preserve) {
                // Values are >= -1 only after rounding bias; unsigned min/max on
                // the small negative range would wrap, so clamp negatives first.
                const __m512i zero = _mm512_setzero_si512();
                const __m512i c255 = _mm512_set1_epi32(255);
                iR = _mm512_min_epi32(_mm512_max_epi32(iR, zero), c255);
                iG = _mm512_min_epi32(_mm512_max_epi32(iG, zero), c255);
                iB = _mm512_min_epi32(_mm512_max_epi32(iB, zero), c255);
                iA = _mm512_min_epi32(_mm512_max_epi32(iA, zero), c255);
            } else {
                const __m512i ps = _mm512_loadu_si512(
                        reinterpret_cast<const void*>(src + rowOffset + x));
                iA = _mm512_srli_epi32(ps, 24);
            }

            alignas(64) jint tmpR[16], tmpG[16], tmpB[16], tmpA[16];
            _mm512_storeu_si512(reinterpret_cast<void*>(tmpR), _mm512_slli_epi32(iR, 16));
            _mm512_storeu_si512(reinterpret_cast<void*>(tmpG), _mm512_slli_epi32(iG, 8));
            _mm512_storeu_si512(reinterpret_cast<void*>(tmpB), iB);
            _mm512_storeu_si512(reinterpret_cast<void*>(tmpA), _mm512_slli_epi32(iA, 24));
            for (jint k = 0; k < 16; k++) {
                dst[rowOffset + x + k] = tmpA[k] | tmpR[k] | tmpG[k] | tmpB[k];
            }
        }
    }
}

} // extern "C"

#endif // __i386__ || __x86_64__
