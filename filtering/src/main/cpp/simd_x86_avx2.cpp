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

// AVX2 widenings of the filter kernels. This TU is compiled with -mavx2 (see
// CMakeLists.txt) so <immintrin.h> exposes the 256-bit ISA; entry points are
// called only after runtime detection reports AVX2 support. Every kernel is an
// exact width-widening of the SSE2/scalar reference loop: byte min/max and
// byte permutation lose nothing, float paths keep the exact op sequence.

#include <jni.h>
#include <cstring>
// Only compiled on x86/x86_64 (per-file ISA flags in CMakeLists.txt);
// included in every ABI's target so IDEs don't flag it as orphaned.
#if defined(__i386__) || defined(__x86_64__)

#include <immintrin.h>

namespace {

inline void reduce32(const uint8_t* buf, const bool isErode, jint (&mins)[4], jint (&maxs)[4]) {
    for (int ch = 0; ch < 4; ch++) {
        for (int p = 0; p < 8; p++) {
            const jint v = buf[p * 4 + ch];
            if (v < mins[ch]) mins[ch] = v;
            if (v > maxs[ch]) maxs[ch] = v;
        }
    }
}

inline jint pick(const bool isErode, const jint ch, const jint (&mins)[4], const jint (&maxs)[4]) {
    return isErode ? mins[ch] : maxs[ch];
}

} // namespace

extern "C" {

void ksvgMorphologyApplyPixelAvx2(
        const jint* src, jint* dst, const jint width,
        const jint radiusX, const jint radiusY, const jboolean erode, const jint x, const jint y) {
    const bool isErode = erode == JNI_TRUE;
    const jint top = y - radiusY;
    const jint bottom = y + radiusY;
    const jint left = x - radiusX;
    const jint right = x + radiusX;

    __m256i accMin = _mm256_set1_epi8(isErode ? -1 : 0);
    __m256i accMax = _mm256_setzero_si256();

    jint mins[4];
    jint maxs[4];
    {
        alignas(32) uint8_t buf[32];
        _mm256_storeu_si256(reinterpret_cast<__m256i*>(buf), accMin);
        for (int ch = 0; ch < 4; ch++) { mins[ch] = buf[ch]; maxs[ch] = 0; }
    }

    for (jint ky = top; ky <= bottom; ky++) {
        const jint* row = src + ky * width;
        jint kx = left;
        for (; kx + 8 <= right + 1; kx += 8) {
            const __m256i c = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(row + kx));
            accMin = _mm256_min_epu8(accMin, c);
            accMax = _mm256_max_epu8(accMax, c);
        }
        // Scalar tail (up to 7 taps).
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

    alignas(32) uint8_t buf[32];
    _mm256_storeu_si256(reinterpret_cast<__m256i*>(buf), isErode ? accMin : accMax);
    reduce32(buf, isErode, mins, maxs);

    dst[y * width + x] =
            (pick(isErode, 3, mins, maxs) << 24) |
            (pick(isErode, 2, mins, maxs) << 16) |
            (pick(isErode, 1, mins, maxs) << 8) |
            pick(isErode, 0, mins, maxs);
}

void ksvgConvolveApplyInteriorAvx2(
        jint* dst, const jint* src, const jint width, const jint height,
        const jfloat* kernel, const jint orderX, const jint orderY, const jint targetX, const jint targetY,
        const jfloat divisor, const jfloat bias, const jboolean preserveAlpha) {
    const bool preserve = preserveAlpha == JNI_TRUE;
    const __m256 vDivisor = _mm256_set1_ps(divisor);
    const __m256 vBias255 = _mm256_mul_ps(_mm256_set1_ps(bias), _mm256_set1_ps(255.0f));
    const __m256 vHalf = _mm256_set1_ps(0.5f);
    const __m256i maskFF = _mm256_set1_epi32(0xFF);

    const jint yLo = targetY;
    const jint yHi = height - orderY + 1 + targetY;
    const jint xLo = targetX;
    const jint xHi = width - orderX + 1 + targetX;

    for (jint y = yLo; y < yHi; y++) {
        const jint rowOffset = y * width;
        for (jint x = xLo; x + 8 <= xHi; x += 8) {
            __m256 accR = _mm256_setzero_ps();
            __m256 accG = _mm256_setzero_ps();
            __m256 accB = _mm256_setzero_ps();
            __m256 accA = _mm256_setzero_ps();

            for (jint ky = 0; ky < orderY; ky++) {
                const jint* row = src + (y + ky - targetY) * width;
                for (jint kx = 0; kx < orderX; kx++) {
                    const __m256 w = _mm256_set1_ps(kernel[ky * orderX + kx]);
                    const __m256i p = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(row + x));
                    const __m256i tb = _mm256_and_si256(p, maskFF);
                    const __m256i tg = _mm256_and_si256(_mm256_srli_epi32(p, 8), maskFF);
                    const __m256i tr = _mm256_and_si256(_mm256_srli_epi32(p, 16), maskFF);
                    const __m256i ta = _mm256_srli_epi32(p, 24);
                    accB = _mm256_add_ps(accB, _mm256_mul_ps(_mm256_cvtepi32_ps(tb), w));
                    accG = _mm256_add_ps(accG, _mm256_mul_ps(_mm256_cvtepi32_ps(tg), w));
                    accR = _mm256_add_ps(accR, _mm256_mul_ps(_mm256_cvtepi32_ps(tr), w));
                    accA = _mm256_add_ps(accA, _mm256_mul_ps(_mm256_cvtepi32_ps(ta), w));
                }
            }

            const __m256 oR = _mm256_add_ps(_mm256_div_ps(accR, vDivisor), vBias255);
            const __m256 oG = _mm256_add_ps(_mm256_div_ps(accG, vDivisor), vBias255);
            const __m256 oB = _mm256_add_ps(_mm256_div_ps(accB, vDivisor), vBias255);
            const __m256 oA = _mm256_add_ps(_mm256_div_ps(accA, vDivisor), vBias255);
            __m256i iR = _mm256_cvttps_epi32(_mm256_add_ps(oR, vHalf));
            __m256i iG = _mm256_cvttps_epi32(_mm256_add_ps(oG, vHalf));
            __m256i iB = _mm256_cvttps_epi32(_mm256_add_ps(oB, vHalf));
            __m256i iA = _mm256_cvttps_epi32(_mm256_add_ps(oA, vHalf));
            if (!preserve) {
                const __m256i zero = _mm256_setzero_si256();
                const __m256i c255 = _mm256_set1_epi32(255);
                iR = _mm256_min_epi32(_mm256_max_epi32(iR, zero), c255);
                iG = _mm256_min_epi32(_mm256_max_epi32(iG, zero), c255);
                iB = _mm256_min_epi32(_mm256_max_epi32(iB, zero), c255);
                iA = _mm256_min_epi32(_mm256_max_epi32(iA, zero), c255);
            } else {
                const __m256i ps = _mm256_loadu_si256(
                        reinterpret_cast<const __m256i*>(src + rowOffset + x));
                iA = _mm256_srli_epi32(ps, 24);
            }

            const auto pack = [](__m128i a, __m128i r, __m128i g, __m128i b) {
                return _mm_or_si128(
                        _mm_or_si128(_mm_slli_epi32(a, 24), _mm_slli_epi32(r, 16)),
                        _mm_or_si128(_mm_slli_epi32(g, 8), b));
            };
            _mm_storeu_si128(reinterpret_cast<__m128i*>(dst + rowOffset + x),
                             pack(_mm256_castsi256_si128(iA), _mm256_castsi256_si128(iR),
                                  _mm256_castsi256_si128(iG), _mm256_castsi256_si128(iB)));
            _mm_storeu_si128(reinterpret_cast<__m128i*>(dst + rowOffset + x + 4),
                             pack(_mm256_extracti128_si256(iA, 1), _mm256_extracti128_si256(iR, 1),
                                  _mm256_extracti128_si256(iG, 1), _mm256_extracti128_si256(iB, 1)));
        }
    }
}

void ksvgComponentTransferApplyAvx2(
        const jint* src, jint* dst, const jint width, const jint height,
        const jint clipLeft, const jint clipTop, const jint clipRight, const jint clipBottom,
        const jbyte* tableA, const jbyte* tableR, const jbyte* tableG, const jbyte* tableB) {
    alignas(16) __m128i rowsA[16], rowsR[16], rowsG[16], rowsB[16];
    for (int i = 0; i < 16; i++) {
        rowsA[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableA + i * 16));
        rowsR[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableR + i * 16));
        rowsG[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableG + i * 16));
        rowsB[i] = _mm_loadu_si128(reinterpret_cast<const __m128i*>(tableB + i * 16));
    }

    std::memset(dst, 0, static_cast<size_t>(width) * height * sizeof(jint));

    // vpshufb works per 128-bit lane: broadcast each 16-entry row into both
    // lanes so one shuffle covers pixels k..k+3 (low lane) and k+4..k+7 (high).
    const auto lutGather = [&rowsA, &rowsR, &rowsG, &rowsB](
            int channel, __m256i valueBytes) -> __m256i {
        const __m128i* rows = channel == 0 ? rowsB : channel == 1 ? rowsG
                            : channel == 2 ? rowsR : rowsA;
        const __m256i loMask = _mm256_set1_epi8(0x0F);
        const __m256i lo = _mm256_and_si256(valueBytes, loMask);
        const __m256i hi = _mm256_and_si256(_mm256_srli_epi16(valueBytes, 4), loMask);
        __m256i result = _mm256_setzero_si256();
        for (int i = 0; i < 16; i++) {
            const __m256i row = _mm256_broadcastsi128_si256(_mm_loadu_si128(rows + i));
            const __m256i candidate = _mm256_shuffle_epi8(row, lo);
            const __m256i sel = _mm256_cmpeq_epi8(hi, _mm256_set1_epi8(static_cast<char>(i)));
            result = _mm256_or_si256(result, _mm256_and_si256(candidate, sel));
        }
        return result;
    };

    const auto extractChannel = [](const int laneByte, const __m256i pixels8) {
        // Same relative byte positions repeated per 128-bit lane.
        const __m128i m = _mm_setr_epi8(
                static_cast<char>(laneByte), static_cast<char>(laneByte + 4),
                static_cast<char>(laneByte + 8), static_cast<char>(laneByte + 12),
                -1, -1, -1, -1,
                static_cast<char>(laneByte), static_cast<char>(laneByte + 4),
                static_cast<char>(laneByte + 8), static_cast<char>(laneByte + 12),
                -1, -1, -1, -1);
        return _mm256_shuffle_epi8(pixels8, _mm256_set_m128i(m, m));
    };

    for (jint y = clipTop; y < clipBottom; y++) {
        const jint rowOffset = y * width;
        jint x = clipLeft;
        for (; x + 8 <= clipRight; x += 8) {
            const __m256i pixels = _mm256_loadu_si256(
                    reinterpret_cast<const __m256i*>(src + rowOffset + x));
            const __m256i outB = lutGather(0, extractChannel(0, pixels));
            const __m256i outG = lutGather(1, extractChannel(1, pixels));
            const __m256i outR = lutGather(2, extractChannel(2, pixels));
            const __m256i outA = lutGather(3, extractChannel(3, pixels));

            const auto interleave = [&](__m256i ob, __m256i og, __m256i orr, __m256i oa, int lane) {
                const __m128i bl = lane == 0 ? _mm256_castsi256_si128(ob) : _mm256_extracti128_si256(ob, 1);
                const __m128i gl = lane == 0 ? _mm256_castsi256_si128(og) : _mm256_extracti128_si256(og, 1);
                const __m128i rl = lane == 0 ? _mm256_castsi256_si128(orr) : _mm256_extracti128_si256(orr, 1);
                const __m128i al = lane == 0 ? _mm256_castsi256_si128(oa) : _mm256_extracti128_si256(oa, 1);
                const __m128i bg = _mm_unpacklo_epi8(bl, gl);
                const __m128i ra = _mm_unpacklo_epi8(rl, al);
                return _mm_unpacklo_epi16(bg, ra); // first 2 pixels of the half
            };
            const auto interleaveHi = [&](__m256i ob, __m256i og, __m256i orr, __m256i oa, int lane) {
                const __m128i bl = lane == 0 ? _mm256_castsi256_si128(ob) : _mm256_extracti128_si256(ob, 1);
                const __m128i gl = lane == 0 ? _mm256_castsi256_si128(og) : _mm256_extracti128_si256(og, 1);
                const __m128i rl = lane == 0 ? _mm256_castsi256_si128(orr) : _mm256_extracti128_si256(orr, 1);
                const __m128i al = lane == 0 ? _mm256_castsi256_si128(oa) : _mm256_extracti128_si256(oa, 1);
                const __m128i bg = _mm_unpackhi_epi8(bl, gl);
                const __m128i ra = _mm_unpackhi_epi8(rl, al);
                return _mm_unpackhi_epi16(bg, ra); // last 2 pixels of the half
            };
            _mm_storel_epi64(reinterpret_cast<__m128i*>(dst + rowOffset + x),
                             interleave(outB, outG, outR, outA, 0));
            _mm_storel_epi64(reinterpret_cast<__m128i*>(dst + rowOffset + x + 2),
                             interleaveHi(outB, outG, outR, outA, 0));
            _mm_storel_epi64(reinterpret_cast<__m128i*>(dst + rowOffset + x + 4),
                             interleave(outB, outG, outR, outA, 1));
            _mm_storel_epi64(reinterpret_cast<__m128i*>(dst + rowOffset + x + 6),
                             interleaveHi(outB, outG, outR, outA, 1));
        }
        for (; x < clipRight; x++) {
            const jint c = src[rowOffset + x];
            dst[rowOffset + x] =
                    (static_cast<jint>(static_cast<uint8_t>(tableA[(c >> 24) & 0xFF])) << 24) |
                    (static_cast<jint>(static_cast<uint8_t>(tableR[(c >> 16) & 0xFF])) << 16) |
                    (static_cast<jint>(static_cast<uint8_t>(tableG[(c >> 8) & 0xFF])) << 8) |
                    static_cast<jint>(static_cast<uint8_t>(tableB[c & 0xFF]));
        }
    }
}


void ksvgBlurVerticalAvx2(
        void* dst, const void* pin, const int stride, const void* gptr,
        const int rct, int x1, int x2) {
    const __m256i maskFF = _mm256_set1_epi32(0xFF);
    const char* base = static_cast<const char*>(pin);

    for (; x1 + 8 <= x2; x1 += 8) {
        __m256 accB = _mm256_setzero_ps();
        __m256 accG = _mm256_setzero_ps();
        __m256 accR = _mm256_setzero_ps();
        __m256 accA = _mm256_setzero_ps();

        const char* pi = base + (x1 << 2);
        for (int r = 0; r < rct; ++r) {
            const __m256 w = _mm256_set1_ps(
                    static_cast<const float*>(gptr)[r]);
            const __m256i p = _mm256_loadu_si256(reinterpret_cast<const __m256i*>(pi));
            const __m256i tb = _mm256_and_si256(p, maskFF);
            const __m256i tg = _mm256_and_si256(_mm256_srli_epi32(p, 8), maskFF);
            const __m256i tr = _mm256_and_si256(_mm256_srli_epi32(p, 16), maskFF);
            const __m256i ta = _mm256_srli_epi32(p, 24);
            accB = _mm256_add_ps(accB, _mm256_mul_ps(_mm256_cvtepi32_ps(tb), w));
            accG = _mm256_add_ps(accG, _mm256_mul_ps(_mm256_cvtepi32_ps(tg), w));
            accR = _mm256_add_ps(accR, _mm256_mul_ps(_mm256_cvtepi32_ps(tr), w));
            accA = _mm256_add_ps(accA, _mm256_mul_ps(_mm256_cvtepi32_ps(ta), w));
            pi += stride;
        }

        // Transpose 4 channels x 8 columns -> 8 float4 groups.
        const __m256 t0 = _mm256_unpacklo_ps(accB, accG); // [B0,G0,B1,G1|B4,G4,B5,G5]
        const __m256 t1 = _mm256_unpackhi_ps(accB, accG); // [B2,G2,B3,G3|B6,G6,B7,G7]
        const __m256 t2 = _mm256_unpacklo_ps(accR, accA);
        const __m256 t3 = _mm256_unpackhi_ps(accR, accA);
        const __m256 o01 = _mm256_shuffle_ps(t0, t2, _MM_SHUFFLE(1, 0, 1, 0));
        const __m256 o23 = _mm256_shuffle_ps(t0, t2, _MM_SHUFFLE(3, 2, 3, 2));
        const __m256 o45 = _mm256_shuffle_ps(t1, t3, _MM_SHUFFLE(1, 0, 1, 0));
        const __m256 o67 = _mm256_shuffle_ps(t1, t3, _MM_SHUFFLE(3, 2, 3, 2));

        float* f = static_cast<float*>(dst) + static_cast<size_t>(x1) * 4;
        _mm_storeu_ps(f + 0 * 4, _mm256_castps256_ps128(o01));
        _mm_storeu_ps(f + 1 * 4, _mm256_castps256_ps128(o23));
        _mm_storeu_ps(f + 2 * 4, _mm256_castps256_ps128(o45));
        _mm_storeu_ps(f + 3 * 4, _mm256_castps256_ps128(o67));
        _mm_storeu_ps(f + 4 * 4, _mm256_extractf128_ps(o01, 1));
        _mm_storeu_ps(f + 5 * 4, _mm256_extractf128_ps(o23, 1));
        _mm_storeu_ps(f + 6 * 4, _mm256_extractf128_ps(o45, 1));
        _mm_storeu_ps(f + 7 * 4, _mm256_extractf128_ps(o67, 1));
    }
}

} // extern "C"

#endif // __i386__ || __x86_64__
