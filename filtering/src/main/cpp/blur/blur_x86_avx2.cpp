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

#if defined(__i386__) || defined(__x86_64__)
#include <immintrin.h>

extern "C" {

void ksvgBlurVerticalAvx2(void* dst, const void* pin, int stride, const void* gptr, int rct, int x1, int x2) {
    extern void rsdIntrinsicBlurVFU4_K(void*, const void*, int, const void*, int, int, int);
    rsdIntrinsicBlurVFU4_K(dst, pin, stride, gptr, rct, x1, x2);
}

} // extern "C"

#endif
