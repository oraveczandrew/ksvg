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

#ifndef TURBULENCE_NOISE_COMMON_S
#define TURBULENCE_NOISE_COMMON_S

/*
 * Source of truth for turbulence constants (verified x86_64 values).
 * Macros emit the raw data bytes; labels must be provided by the caller.
 */

.macro TURB_DBL_1_256
    .long 0, 1064304640
.endm

.macro TURB_DBL_1
    .long 0, 1072693248
.endm

.macro TURB_DBL_0_5
    .long 0, 1071644672
.endm

.macro TURB_DBL_3
    .long 0, 1074266112
.endm

.macro TURB_DBL_127_5
    .long 0, 1080025088
.endm

.macro TURB_DBL_255
    .long 0, 1081073664
.endm

.macro TURB_DBL_4096
    .long 0, 1085276160
.endm

.macro TURB_DBL_NEG_1
    .long 0, 3220176896
.endm

// MAGIC constant for int-to-double conversion tricks (2^52)
.macro TURB_DBL_2_POW_52
    .long 0, 1127219200
.endm

.macro TURB_ABS_MASK_SSE2
    .long -1, 2147483647
    .long -1, 2147483647
.endm

.macro TURB_ABS_MASK_AVX2
    .long -1, 2147483647
    .long -1, 2147483647
    .long -1, 2147483647
    .long -1, 2147483647
.endm

// Integer 255 in the low 32 bits of an XMM register (rest zero)
.macro TURB_INT_255_XMM
    .long 255, 0, 0, 0
.endm

// Permutation table data (0..255)
.macro TURB_PERMUTATION_DATA
.set i, 0
.rept 256
    .byte i
    .set i, i + 1
.endr
.endm

#endif
