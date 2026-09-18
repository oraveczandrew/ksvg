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

/* i386 AVX2 sRGB unlinearize.
 * Exact 8-bit result using 16-segment integer approximation + correction.
 * V26: PIC/no-text-rel local constants, fused base term; fixed tail table argument offset.
 */
#include "asm_macros.S"

.text
.p2align 5

/*
 * void ksvgUnlinearizeApplyAvx2ApproxV26(
 *     const jint* src, jint* dst, jint width, jint height, const jbyte* table);
 *
 * i386 ABI:
 *   stack: src, dst, width, height, table
 */
.globl SYM(ksvgUnlinearizeApplyAvx2ApproxV26)
TYPE(SYM(ksvgUnlinearizeApplyAvx2ApproxV26), @function)
SYM(ksvgUnlinearizeApplyAvx2ApproxV26):
    pushl   %ebp
    pushl   %ebx
    pushl   %esi
    pushl   %edi

    # EIP-relative base for local constants; no R_386_32 relocations.
    call    1f
1:  popl    %ebp

    movl    20(%esp), %esi
    movl    24(%esp), %edi
    movl    28(%esp), %eax
    imull   32(%esp), %eax
    movl    %eax, %ebx
    shrl    $3, %ebx
    andl    $7, %eax
    movl    %eax, %ecx

    vpxor   %ymm7, %ymm7, %ymm7
    testl   %ebx, %ebx
    jz      .L_tail

.p2align 5
.L_loop:
    vmovdqu (%esi), %ymm0

    # hi = x >> 4, lo = x & 15
    vmovdqa %ymm0, %ymm1
    vpsrlw  $4, %ymm1, %ymm1
    vpand   (.L_nibble_mask_32-1b)(%ebp), %ymm1, %ymm1
    vmovdqa %ymm0, %ymm2
    vpand   (.L_nibble_mask_32-1b)(%ebp), %ymm2, %ymm2

    # base[hi], slope[hi]
    vmovdqa (.L_base_lut_32-1b)(%ebp), %ymm3
    vpshufb %ymm1, %ymm3, %ymm3
    vmovdqa (.L_slope_lut_32-1b)(%ebp), %ymm4
    vpshufb %ymm1, %ymm4, %ymm4

    # (slope * lo + base * 32 + 16) >> 5
    vmovdqa %ymm4, %ymm5
    vpunpcklbw %ymm3, %ymm5, %ymm5
    vmovdqa %ymm2, %ymm6
    vpunpcklbw (.L_const32_32-1b)(%ebp), %ymm6, %ymm6
    vpmaddubsw %ymm6, %ymm5, %ymm5

    vmovdqa %ymm4, %ymm6
    vpunpckhbw %ymm3, %ymm6, %ymm6
    vmovdqa %ymm2, %ymm4
    vpunpckhbw (.L_const32_32-1b)(%ebp), %ymm4, %ymm4
    vpmaddubsw %ymm4, %ymm6, %ymm6

    vpaddw  (.L_rounding_32-1b)(%ebp), %ymm5, %ymm5
    vpsrlw  $5, %ymm5, %ymm5
    vpaddw  (.L_rounding_32-1b)(%ebp), %ymm6, %ymm6
    vpsrlw  $5, %ymm6, %ymm6
    vpackuswb %ymm6, %ymm5, %ymm5

    # approximation is reference + 1 at the selected (hi,lo) points
    vmovdqa %ymm1, %ymm7
    vpcmpgtb (.L_hi7_32-1b)(%ebp), %ymm7, %ymm7

    vmovdqa (.L_corr_lo_32-1b)(%ebp), %ymm4
    vpshufb %ymm2, %ymm4, %ymm4
    vmovdqa (.L_corr_xor_32-1b)(%ebp), %ymm6
    vpshufb %ymm2, %ymm6, %ymm6
    vpand   %ymm7, %ymm6, %ymm6
    vpxor   %ymm6, %ymm4, %ymm4

    vmovdqa (.L_onehot_hi_32-1b)(%ebp), %ymm6
    vpshufb %ymm1, %ymm6, %ymm6
    vpand   %ymm6, %ymm4, %ymm4
    vpminub (.L_one_byte_32-1b)(%ebp), %ymm4, %ymm4
    vpsubb  %ymm4, %ymm5, %ymm5

    # exact x < 16
    vpxor   %ymm7, %ymm7, %ymm7
    vmovdqa (.L_exact_low16_32-1b)(%ebp), %ymm4
    vpshufb %ymm2, %ymm4, %ymm4
    vpcmpeqb %ymm7, %ymm1, %ymm1
    vpblendvb %ymm1, %ymm4, %ymm5, %ymm5

    # preserve alpha
    vpand   (.L_rgb_mask_32-1b)(%ebp), %ymm5, %ymm5
    vmovdqa (.L_alpha_blend_mask_32-1b)(%ebp), %ymm6
    vpblendvb %ymm6, %ymm0, %ymm5, %ymm5
    vmovdqu %ymm5, (%edi)

    addl    $32, %esi
    addl    $32, %edi
    decl    %ebx
    jnz     .L_loop

.L_tail:
    testl   %ecx, %ecx
    jz      .L_done
.L_tail_loop:
    movl    (%esi), %eax
    movl    %eax, %edx
    andl    $0xff000000, %edx
    movl    %eax, %ebx
    andl    $0xff, %ebx
    movzbl  (.L_unlinearize_lut-1b)(%ebp, %ebx, 1), %ebx
    movl    %ebx, %eax
    movl    (%esi), %ebx
    shrl    $8, %ebx
    andl    $0xff, %ebx
    movzbl  (.L_unlinearize_lut-1b)(%ebp, %ebx, 1), %ebx
    shll    $8, %ebx
    orl     %ebx, %eax
    movl    (%esi), %ebx
    shrl    $16, %ebx
    andl    $0xff, %ebx
    movzbl  (.L_unlinearize_lut-1b)(%ebp, %ebx, 1), %ebx
    shll    $16, %ebx
    orl     %ebx, %eax
    orl     %edx, %eax
    movl    %eax, (%edi)
    addl    $4, %esi
    addl    $4, %edi
    decl    %ecx
    jnz     .L_tail_loop
.L_done:
    vzeroupper
    popl    %edi
    popl    %esi
    popl    %ebx
    popl    %ebp
    ret
SIZE(SYM(ksvgUnlinearizeApplyAvx2ApproxV26))

.p2align 4
.L_unlinearize_lut:
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

.text
.p2align 5
.L_const32_32:
    .rept 32
    .byte 32
    .endr
.L_nibble_mask_32:
    .rept 32
    .byte 15
    .endr
.L_hi7_32:
    .rept 32
    .byte 7
    .endr
.L_one_byte_32:
    .rept 32
    .byte 1
    .endr
.L_rounding_32:
    .rept 16
    .short 16
    .endr
.L_exact_low16_32:
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.L_base_lut_32:
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,234,241,249
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,234,241,249
.L_slope_lut_32:
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,13,15,13
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,13,15,13
.L_onehot_hi_32:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.L_corr_lo_32:
    .byte 14,10,14,0,0,0,0,0,130,32,0,0,18,18,114,50
    .byte 14,10,14,0,0,0,0,0,130,32,0,0,18,18,114,50
.L_corr_xor_32:
    .byte 166,14,174,4,161,4,0,128,130,160,0,0,82,18,50,50
    .byte 166,14,174,4,161,4,0,128,130,160,0,0,82,18,50,50
.L_rgb_mask_32:
    .rept 8
    .long 0x00ffffff
    .endr
.L_alpha_blend_mask_32:
    .rept 8
    .long 0xff000000
    .endr
