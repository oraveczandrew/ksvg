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
#if defined(__i386__) || defined(__x86_64__)
#include <immintrin.h>
#endif
#include <cstdint>

#if defined(__i386__) || defined(__x86_64__)

extern "C" {

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

} // extern "C"

#endif
