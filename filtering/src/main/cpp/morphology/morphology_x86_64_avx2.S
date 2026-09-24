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
 * x86-64 / AVX2 implementation of the interior morphology kernels.
 *
 * Native little-endian ARGB_8888 jint bytes:
 *     B G R A | B G R A | ...
 *
 * AVX2 processes 32 bytes = 8 pixels per vector. PMINUB/PMAXUB operate
 * independently on each byte lane, preserving the per-channel semantics.
 *
 * System V x86-64 ABI (also used by x86_64 Android):
 *
 * Row:
 *   rdi=src, rsi=dst, edx=width, ecx=radiusX,
 *   r8d=radiusY, r9d=erode,
 *   [rsp+8]=y, [rsp+16]=xStart,
 *   [rsp+24]=xEnd, [rsp+32]=scratch.
 *
 * All entry points are for fully interior input/ranges. Borders stay on
 * the caller's scalar path.
 */

#include "asm_macros.S"

.text
.p2align 5

/* -------------------------------------------------------------------------
* Row kernel
*
* Stage 1: vertical byte-wise min/max into scratch for the source span
*          [xStart-radiusX, xEnd+radiusX).
*
* Stage 2: horizontal byte-wise min/max over overlapping scratch windows.
*
* AVX2 processes 8 pixels per vector. Tail counts are handled explicitly
* and may be 0..7 in the vertical stage and 1,3,5,7 in the horizontal stage.
* ------------------------------------------------------------------------- */

.globl SYM(ksvgMorphologyApplyRowAvx2)
TYPE(SYM(ksvgMorphologyApplyRowAvx2), @function)
    SYM(ksvgMorphologyApplyRowAvx2):
    push    %rbx
    push    %rbp
    push    %r12
    push    %r13
    push    %r14
    push    %r15

/* Six pushes = 48 bytes; original stack args are +56/+64/+72/+80. */
    mov     56(%rsp), %r15d  // y
    mov     64(%rsp), %ebx  // xStart
    mov     80(%rsp), %r10  // scratch base

    mov     %r9d, %ebp  // erode
    mov     %edx, %r13d  // width
    mov     %ecx, %r14d  // radiusX
    mov     %ecx, %r12d  // saved radiusX for horizontal stage
/* rowCount = 2*radiusY + 1. */
    lea     1(%r8d, %r8d), %r9d

/* colLo = xStart - radiusX. */
    mov     %ebx, %r11d
    sub     %r14d, %r11d  // r11d = colLo

/*
* Build the source cursor before reusing the temporary registers for
* colCount/groupCount.
*/
    mov     %r15d, %edx
    sub     %r8d, %edx  // top = y-radiusY
    movslq  %edx, %rdx
    movslq  %r13d, %rax
    imul    %rax, %rdx
    movslq  %r11d, %rax  // colLo
    add     %rax, %rdx
    lea     (%rdi, %rdx, 4), %r11  // r11 = source group cursor

/*
* colCount = outputCount + 2*radiusX
*          = (xEnd-xStart) + 2*radiusX
*/
    mov     72(%rsp), %ecx
    sub     %ebx, %ecx  // outputCount
    lea     (%rcx, %r14, 2), %rax  // colCount
    mov     %eax, %ecx

/* vertical groupCount / tail */
    mov     %ecx, %edx
    and     $7, %edx
    mov     %edx, %r8d  // tailCols
    shr     $3, %ecx  // groupCount

/*
* Source cursor is now independent of the original src argument.
* Reuse rdi as the destination base and rsi as the scratch cursor.
*/
    mov     %rsi, %rdi

/* rowStride bytes in r14; radiusX was saved in r14d earlier. */
    movslq  %r13d, %r14
    shl     $2, %r14

    test    %ebp, %ebp
    jne     .L_row_avx2_e_vertical

/* -------------------- vertical dilation -------------------- */
    mov     %r10, %rsi  // scratch cursor

.L_row_avx2_d_group:
    test    %ecx, %ecx
    jz      .L_row_avx2_d_tail

    vxorps  %ymm0, %ymm0, %ymm0
    mov     %r11, %rax
    mov     %r9d, %edx  // row counter

.L_row_avx2_d_rows:
    vmovdqu (%rax), %ymm1
    vpmaxub %ymm1, %ymm0, %ymm0
    add     %r14, %rax
    dec     %edx
    jnz     .L_row_avx2_d_rows

    vmovdqu %ymm0, (%rsi)
    add     $32, %rsi
    add     $32, %r11
    dec     %ecx
    jmp     .L_row_avx2_d_group

.L_row_avx2_d_tail:
    test    %r8d, %r8d
    jz      .L_row_avx2_d_horizontal

.L_row_avx2_d_tail_col:
    vxorps  %ymm0, %ymm0, %ymm0
    mov     %r11, %rax
    mov     %r9d, %ecx  // row counter

.L_row_avx2_d_tail_rows:
    mov     (%rax), %edx
    vmovd   %edx, %xmm1
    vpbroadcastd %xmm1, %ymm1
    vpmaxub %ymm1, %ymm0, %ymm0
    add     %r14, %rax
    dec     %ecx
    jnz     .L_row_avx2_d_tail_rows

    vmovd   %xmm0, %edx
    mov     %edx, (%rsi)
    add     $4, %rsi
    add     $4, %r11
    dec     %r8d
    jnz     .L_row_avx2_d_tail_col
    jmp     .L_row_avx2_d_horizontal

/* -------------------- vertical erosion -------------------- */
.L_row_avx2_e_vertical:
    mov     %r10, %rsi  // scratch cursor

.L_row_avx2_e_group:
    test    %ecx, %ecx
    jz      .L_row_avx2_e_tail

    vpcmpeqb %ymm0, %ymm0, %ymm0
    mov     %r11, %rax
    mov     %r9d, %edx

.L_row_avx2_e_rows:
    vmovdqu (%rax), %ymm1
    vpminub %ymm1, %ymm0, %ymm0
    add     %r14, %rax
    dec     %edx
    jnz     .L_row_avx2_e_rows

    vmovdqu %ymm0, (%rsi)
    add     $32, %rsi
    add     $32, %r11
    dec     %ecx
    jmp     .L_row_avx2_e_group

.L_row_avx2_e_tail:
    test    %r8d, %r8d
    jz      .L_row_avx2_e_horizontal

.L_row_avx2_e_tail_col:
    vpcmpeqb %ymm0, %ymm0, %ymm0
    mov     %r11, %rax
    mov     %r9d, %ecx

.L_row_avx2_e_tail_rows:
    mov     (%rax), %edx
    vmovd   %edx, %xmm1
    vpbroadcastd %xmm1, %ymm1
    vpminub %ymm1, %ymm0, %ymm0
    add     %r14, %rax
    dec     %ecx
    jnz     .L_row_avx2_e_tail_rows

    vmovd   %xmm0, %edx
    mov     %edx, (%rsi)
    add     $4, %rsi
    add     $4, %r11
    dec     %r8d
    jnz     .L_row_avx2_e_tail_col
    jmp     .L_row_avx2_e_horizontal

/* -------------------- horizontal dilation -------------------- */
.L_row_avx2_d_horizontal:
/* L = 2*radiusX+1; r12d still holds saved radiusX. */
    lea     1(%r12d, %r12d), %eax
    mov     %eax, %ecx
    shr     $3, %ecx  // vectorCount
    and     $7, %eax
    mov     %eax, %r9d  // tail = 1,3,5,7

    mov     72(%rsp), %r12d  // xEnd
    sub     %ebx, %r12d  // outputCount

/* dst cursor = dst + (y*width+xStart)*4 */
    mov     56(%rsp), %r15d  // reload y
    movslq  %r15d, %rax
    movslq  %r13d, %rdx
    imul    %rdx, %rax
    movslq  %ebx, %rdx
    add     %rdx, %rax
    lea     (%rdi, %rax, 4), %rdi

    mov     %r10, %r11  // scratch window cursor

.L_row_avx2_d_h_px:
    vxorps  %ymm0, %ymm0, %ymm0
    mov     %r11, %rdx
    mov     %ecx, %eax
    mov     %r9d, %r8d  // restore tail for this output pixel

.L_row_avx2_d_h_vec:
    test    %eax, %eax
    jz      .L_row_avx2_d_h_tail
    vmovdqu (%rdx), %ymm1
    vpmaxub %ymm1, %ymm0, %ymm0
    add     $32, %rdx
    dec     %eax
    jnz     .L_row_avx2_d_h_vec

.L_row_avx2_d_h_tail:
    test    %r8d, %r8d
    jz      .L_row_avx2_d_h_pack

.L_row_avx2_d_h_tail_loop:
    mov     (%rdx), %eax
    vmovd   %eax, %xmm1
    vpbroadcastd %xmm1, %ymm1
    vpmaxub %ymm1, %ymm0, %ymm0
    add     $4, %rdx
    dec     %r8d
    jnz     .L_row_avx2_d_h_tail_loop

.L_row_avx2_d_h_pack:
    vextracti128 $1, %ymm0, %xmm1
    vpmaxub %xmm1, %xmm0, %xmm0
    vpsrldq $8, %xmm0, %xmm1
    vpmaxub %xmm1, %xmm0, %xmm0
    vpsrldq $4, %xmm0, %xmm1
    vpmaxub %xmm1, %xmm0, %xmm0
    vmovd   %xmm0, %eax
    mov     %eax, (%rdi)
    add     $4, %rdi
    add     $4, %r11
    dec     %r12d
    jnz     .L_row_avx2_d_h_px
    jmp     .L_row_avx2_epilogue

/* -------------------- horizontal erosion -------------------- */
.L_row_avx2_e_horizontal:
/* L = 2*radiusX+1; r12d still holds saved radiusX. */
    lea     1(%r12d, %r12d), %eax
    mov     %eax, %ecx
    shr     $3, %ecx  // vectorCount
    and     $7, %eax
    mov     %eax, %r9d  // tail = 1,3,5,7

    mov     72(%rsp), %r12d
    sub     %ebx, %r12d  // outputCount

/* dst cursor = dst + (y*width+xStart)*4 */
    mov     56(%rsp), %r15d  // reload y
    movslq  %r15d, %rax
    movslq  %r13d, %rdx
    imul    %rdx, %rax
    movslq  %ebx, %rdx
    add     %rdx, %rax
    lea     (%rdi, %rax, 4), %rdi

    mov     %r10, %r11

.L_row_avx2_e_h_px:
    vpcmpeqb %ymm0, %ymm0, %ymm0
    mov     %r11, %rdx
    mov     %ecx, %eax
    mov     %r9d, %r8d

.L_row_avx2_e_h_vec:
    test    %eax, %eax
    jz      .L_row_avx2_e_h_tail
    vmovdqu (%rdx), %ymm1
    vpminub %ymm1, %ymm0, %ymm0
    add     $32, %rdx
    dec     %eax
    jnz     .L_row_avx2_e_h_vec

.L_row_avx2_e_h_tail:
    test    %r8d, %r8d
    jz      .L_row_avx2_e_h_pack

.L_row_avx2_e_h_tail_loop:
    mov     (%rdx), %eax
    vmovd   %eax, %xmm1
    vpbroadcastd %xmm1, %ymm1
    vpminub %ymm1, %ymm0, %ymm0
    add     $4, %rdx
    dec     %r8d
    jnz     .L_row_avx2_e_h_tail_loop

.L_row_avx2_e_h_pack:
    vextracti128 $1, %ymm0, %xmm1
    vpminub %xmm1, %xmm0, %xmm0
    vpsrldq $8, %xmm0, %xmm1
    vpminub %xmm1, %xmm0, %xmm0
    vpsrldq $4, %xmm0, %xmm1
    vpminub %xmm1, %xmm0, %xmm0
    vmovd   %xmm0, %eax
    mov     %eax, (%rdi)
    add     $4, %rdi
    add     $4, %r11
    dec     %r12d
    jnz     .L_row_avx2_e_h_px

.L_row_avx2_epilogue:
    vzeroupper
    pop     %r15
    pop     %r14
    pop     %r13
    pop     %r12
    pop     %rbp
    pop     %rbx
    ret
    // // SIZE(SYM(ksvgMorphologyApplyRowAvx2))
GNU_STACK
