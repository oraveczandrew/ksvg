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

/*
 * KSVG Filter Kernel Shared Color Look-Up Tables.
 *
 * This file contains the standard sRGB <-> Linear RGB 256-byte LUTs,
 * exactly matching ColorLuts.kt and librsvg's reference curve.
 */

#include "asm_macros.S"

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 4

# -------------------------------------------------------------------------
# sRGB -> Linear (Linearize) 256-byte LUT
# -------------------------------------------------------------------------
.globl SYM(ksvg_srgb_to_linear_lut)
SYM(ksvg_srgb_to_linear_lut):
    .byte 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1
    .byte 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3
    .byte 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7
    .byte 8, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 12, 12, 12, 13
    .byte 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 17, 18, 18, 19, 19, 20
    .byte 20, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 27, 27, 28, 29, 29
    .byte 30, 30, 31, 32, 32, 33, 34, 35, 35, 36, 37, 37, 38, 39, 40, 41
    .byte 41, 42, 43, 44, 45, 45, 46, 47, 48, 49, 50, 51, 51, 52, 53, 54
    .byte 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70
    .byte 71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 82, 84, 85, 86, 87, 88
    .byte 90, 91, 92, 93, 95, 96, 97, 99, 100, 101, 103, 104, 105, 107, 108, 109
    .byte 111, 112, 114, 115, 116, 118, 119, 121, 122, 124, 125, 127, 128, 130, 131, 133
    .byte 134, 136, 138, 139, 141, 142, 144, 146, 147, 149, 151, 152, 154, 156, 157, 159
    .byte 161, 163, 164, 166, 168, 170, 171, 173, 175, 177, 179, 181, 183, 184, 186, 188
    .byte 190, 192, 194, 196, 198, 200, 202, 204, 206, 208, 210, 212, 214, 216, 218, 220
    .byte 222, 224, 226, 229, 231, 233, 235, 237, 239, 242, 244, 246, 248, 250, 253, 255

# -------------------------------------------------------------------------
# sRGB -> Linear (S2L) Piecewise Approximation Constants
# -------------------------------------------------------------------------

.globl SYM(ksvg_s2l_base_lut)
SYM(ksvg_s2l_base_lut):
    .byte 0,2,4,8,13,21,30,41,55,71,90,111,135,161,190,222

.globl SYM(ksvg_s2l_slope_lut)
SYM(ksvg_s2l_slope_lut):
    .byte 3,2,7,10,14,18,23,28,31,37,41,46,51,58,63,70

.globl SYM(ksvg_s2l_exact_low16)
SYM(ksvg_s2l_exact_low16):
    .byte 0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1

.globl SYM(ksvg_s2l_corr_lo)
SYM(ksvg_s2l_corr_lo):
    .byte 34,98,8,44,68,104,9,36,110,42,32,64,228,0,0,0

.globl SYM(ksvg_s2l_corr_hi)
SYM(ksvg_s2l_corr_hi):
    .byte 16,16,36,20,8,16,60,32,184,4,2,16,0,32,0,0

# -------------------------------------------------------------------------
# Linear -> sRGB (Unlinearize) 256-byte LUT
# -------------------------------------------------------------------------
.globl SYM(ksvg_linear_to_srgb_lut)
SYM(ksvg_linear_to_srgb_lut):
    .byte 0, 13, 22, 28, 34, 38, 42, 46, 50, 53, 56, 59, 61, 64, 66, 69
    .byte 71, 73, 75, 77, 79, 81, 83, 85, 86, 88, 90, 92, 93, 95, 96, 98
    .byte 99, 101, 102, 104, 105, 106, 108, 109, 110, 112, 113, 114, 115, 117, 118, 119
    .byte 120, 121, 122, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136
    .byte 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 148, 149, 150, 151
    .byte 152, 153, 154, 155, 155, 156, 157, 158, 159, 159, 160, 161, 162, 163, 163, 164
    .byte 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 175, 176
    .byte 177, 178, 178, 179, 180, 180, 181, 182, 182, 183, 184, 185, 185, 186, 187, 187
    .byte 188, 189, 189, 190, 190, 191, 192, 192, 193, 194, 194, 195, 196, 196, 197, 197
    .byte 198, 199, 199, 200, 200, 201, 202, 202, 203, 203, 204, 205, 205, 206, 206, 207
    .byte 208, 208, 209, 209, 210, 210, 211, 212, 212, 213, 213, 214, 214, 215, 215, 216
    .byte 216, 217, 218, 218, 219, 219, 220, 220, 221, 221, 222, 222, 223, 223, 224, 224
    .byte 225, 226, 226, 227, 227, 228, 228, 229, 229, 230, 230, 231, 231, 232, 232, 233
    .byte 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 238, 238, 239, 239, 240, 240
    .byte 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246, 246, 246, 247, 247, 248
    .byte 248, 249, 249, 250, 250, 251, 251, 251, 252, 252, 253, 253, 254, 254, 255, 255

# -------------------------------------------------------------------------
# Linear -> sRGB (L2S) Piecewise Approximation Constants
# -------------------------------------------------------------------------

.globl SYM(ksvg_l2s_base_lut)
SYM(ksvg_l2s_base_lut):
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248

.globl SYM(ksvg_l2s_slope_lut)
SYM(ksvg_l2s_slope_lut):
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16

.globl SYM(ksvg_l2s_exact_low16)
SYM(ksvg_l2s_exact_low16):
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69

.globl SYM(ksvg_l2s_corr_lo)
SYM(ksvg_l2s_corr_lo):
    .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1

.globl SYM(ksvg_l2s_corr_xor)
SYM(ksvg_l2s_corr_xor):
    .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
