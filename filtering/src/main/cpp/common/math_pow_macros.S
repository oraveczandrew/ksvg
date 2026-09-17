/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Shared SIMD math macros for fast transcendental approximations.
 */

/*
 * Description:
 *   Emits 8th-degree minimax coefficients for log2(1+f) on the interval [0, 1].
 *   Precision: ~1.365 ULP (float32).
 */
.macro EMIT_LOG2_POLY_8
.p2align 5
.Lpoly_log2:
    .long 0xbc14e99e # c8
    .long 0x3d517250 # c7
    .long 0xbe0b306b # c6
    .long 0x3e762e19 # c5
    .long 0xbeb16ed0 # c4
    .long 0x3ef4f943 # c3
    .long 0xbf389c1f # c2
    .long 0x3fb8a9fd # c1
    .long 0x3335bce7 # c0
.endm

/*
 * Description:
 *   Emits 8th-degree minimax coefficients for exp2(x) on the interval [0, 1].
 *   Precision: ~1.378 ULP (float32).
 */
.macro EMIT_EXP2_POLY_8
.p2align 5
.Lpoly_exp2:
    .long 0x35fbc4c2 # c8
    .long 0x376d5f0a # c7
    .long 0x3922b9a8 # c6
    .long 0x3aaeacc9 # c5
    .long 0x3c1d965e # c4
    .long 0x3d63583b # c3
    .long 0x3e75fdf0 # c2
    .long 0x3f317218 # c1
    .long 0x3f800000 # c0
.endm

/*
 * Description:
 *   Common constants for SIMD range reduction (IEEE-754 bit manipulation).
 */
.macro EMIT_POW_COMMON_CONSTANTS
.p2align 5
.Lbiased_127:    .long 127,127,127,127,127,127,127,127
.Lmantissa_mask: .long 0x007fffff,0x007fffff,0x007fffff,0x007fffff,0x007fffff,0x007fffff,0x007fffff,0x007fffff
.Lfloat_1_bits:  .long 0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000,0x3f800000
.Lfloat_255:     .long 0x437f0000,0x437f0000,0x437f0000,0x437f0000,0x437f0000,0x437f0000,0x437f0000,0x437f0000
.L255_epi32:     .long 255,255,255,255,255,255,255,255
.Lmin_exp_biased: .long 0,0,0,0,0,0,0,0
.endm
