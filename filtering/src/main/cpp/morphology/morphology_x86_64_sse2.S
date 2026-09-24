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
* x86-64 / SSE2 implementation of the interior morphology kernels.
*
* SSE2 is sufficient because PMINUB/PMAXUB operate on 16 unsigned bytes.
*/

#include "asm_macros.S"

/*
* A native little-endian ARGB_8888 jint is four bytes in memory:
*
*     B G R A
*
* so every byte lane stays associated with one fixed color channel.
*
* System V x86-64 ABI (used by x86_64 Android):
*
* Pixel:
*   rdi=src, rsi=dst, edx=width, ecx=radiusX,
*   r8d=radiusY, r9d=erode,
*   [rsp+8]=x, [rsp+16]=y.
*
* Row:
*   rdi=src, rsi=dst, edx=width, ecx=radiusX,
*   r8d=radiusY, r9d=erode,
*   [rsp+8]=y, [rsp+16]=xStart,
*   [rsp+24]=xEnd, [rsp+32]=scratch.
*
* Both routines require a fully-interior kernel/range, matching the SIMD
* dispatch in morphology.cpp. Borders are handled by the scalar caller.
*/

.text
.p2align 4

/* -------------------------------------------------------------------------
* Row kernel
*
* Two-stage implementation:
*   1. vertical byte-wise min/max into caller-provided scratch;
*   2. horizontal byte-wise min/max over the overlapping scratch windows.
*
* This version deliberately favors an easily auditable register map over
* aggressive unrolling. It is a good SSE2 correctness baseline.
* ------------------------------------------------------------------------- */

.globl SYM(ksvgMorphologyApplyRowSse2)
TYPE(SYM(ksvgMorphologyApplyRowSse2), @function)
    SYM(ksvgMorphologyApplyRowSse2):
    push    %rbx
    push    %rbp
    push    %r12
    push    %r13
    push    %r14
    push    %r15

/* Original stack args are +48 after six pushes. */
    mov     56(%rsp), %r15d  // y
    mov     64(%rsp), %ebx  // xStart
    mov     72(%rsp), %ebp  // xEnd (temporary)
    mov     80(%rsp), %r10  // scratch base
    mov     %r9d, %ebp  // preserve erode; xEnd is reloadable from stack

    mov     %edx, %r12d  // width
    mov     %ecx, %r13d  // radiusX
    mov     %r8d, %r14d  // radiusY

/* rowCount = 2*radiusY + 1 */
    lea     1(%r14d, %r14d), %r8d

/* colLo = xStart - radiusX */
    mov     %ebx, %eax
    sub     %r13d, %eax
    mov     %eax, %r11d  // colLo

/* colCount = (xEnd + radiusX) - colLo */
    mov     72(%rsp), %ecx
    add     %r13d, %ecx
    sub     %r11d, %ecx
    mov     %ecx, %edx
    shr     $2, %ecx  // groupCount
    and     $3, %edx
    mov     %edx, %r9d  // tailCols

/* src cursor = &src[y-radiusY][colLo] */
    mov     %r15d, %edx
    sub     %r14d, %edx
    movslq  %edx, %rdx
    movslq  %r12d, %rax
    imul    %rax, %rdx
    movslq  %r11d, %rax
    add     %rax, %rdx
    lea     (%rdi, %rdx, 4), %r11  // source group cursor

/* rowStride bytes in r14; radiusY no longer needed. */
    movslq  %r12d, %r14
    shl     $2, %r14

/* Keep dst base in rdi; rsi becomes scratch cursor. */
    mov     %rsi, %rdi

/* Erase the incoming erode value from r9 now that the branch decision is
* made from the saved rbp value. */
    test    %ebp, %ebp
    jne     .L_row_e_vertical

/* -------------------- dilation vertical -------------------- */
    mov     %r10, %rsi  // scratch cursor
.L_row_d_group:
    test    %ecx, %ecx
    jz      .L_row_d_tail
    pxor    %xmm0, %xmm0
    mov     %r11, %rax
    mov     %r8d, %edx  // row counter
.L_row_d_rows:
    movdqu  (%rax), %xmm1
    pmaxub  %xmm1, %xmm0
    add     %r14, %rax
    dec     %edx
    jnz     .L_row_d_rows
    movdqu  %xmm0, (%rsi)
    add     $16, %rsi
    add     $16, %r11
    dec     %ecx
    jmp     .L_row_d_group

.L_row_d_tail:
    test    %r9d, %r9d
    jz      .L_row_d_horizontal
.L_row_d_tail_col:
    pxor    %xmm0, %xmm0
    mov     %r11, %rax
    mov     %r8d, %ecx
.L_row_d_tail_rows:
    mov     (%rax), %edx
    movd    %edx, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pmaxub  %xmm1, %xmm0
    add     %r14, %rax
    dec     %ecx
    jnz     .L_row_d_tail_rows
    movd    %xmm0, (%rsi)
    add     $4, %rsi
    add     $4, %r11
    dec     %r9d
    jnz     .L_row_d_tail_col

.L_row_d_horizontal:
    jmp     .L_row_horizontal_d

/* -------------------- erosion vertical -------------------- */
.L_row_e_vertical:
    mov     %r10, %rsi
.L_row_e_group:
    test    %ecx, %ecx
    jz      .L_row_e_tail
    pcmpeqb %xmm0, %xmm0
    mov     %r11, %rax
    mov     %r8d, %edx
.L_row_e_rows:
    movdqu  (%rax), %xmm1
    pminub  %xmm1, %xmm0
    add     %r14, %rax
    dec     %edx
    jnz     .L_row_e_rows
    movdqu  %xmm0, (%rsi)
    add     $16, %rsi
    add     $16, %r11
    dec     %ecx
    jmp     .L_row_e_group

.L_row_e_tail:
    test    %r9d, %r9d
    jz      .L_row_e_horizontal
.L_row_e_tail_col:
    pcmpeqb %xmm0, %xmm0
    mov     %r11, %rax
    mov     %r8d, %ecx
.L_row_e_tail_rows:
    mov     (%rax), %edx
    movd    %edx, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pminub  %xmm1, %xmm0
    add     %r14, %rax
    dec     %ecx
    jnz     .L_row_e_tail_rows
    movd    %xmm0, (%rsi)
    add     $4, %rsi
    add     $4, %r11
    dec     %r9d
    jnz     .L_row_e_tail_col

.L_row_e_horizontal:
    jmp     .L_row_horizontal_e

/* -------------------- horizontal dilation -------------------- */
.L_row_horizontal_d:
    mov     80(%rsp), %r10  // scratch base
    mov     72(%rsp), %r9d
    sub     %ebx, %r9d  // outputCount

    movslq  %r15d, %rax
    movslq  %r12d, %rcx
    imul    %rcx, %rax
    movslq  %ebx, %rcx
    add     %rcx, %rax
    lea     (%rdi, %rax, 4), %rdi  // dst cursor

    mov     %r10, %r11  // scratch window cursor
    lea     1(%r13d, %r13d), %r14d  // L
    mov     %r14d, %ecx
    shr     $2, %ecx  // vectorCount

.L_row_d_h_px:
    pxor    %xmm0, %xmm0
    mov     %r11, %rdx
    mov     %ecx, %eax
.L_row_d_h_vec:
    test    %eax, %eax
    jz      .L_row_d_h_tail
    movdqu  (%rdx), %xmm1
    pmaxub  %xmm1, %xmm0
    add     $16, %rdx
    dec     %eax
    jnz     .L_row_d_h_vec
.L_row_d_h_tail:
    mov     (%rdx), %eax
    movd    %eax, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pmaxub  %xmm1, %xmm0
    add     $4, %rdx
    test    $1, %r13d  // radiusX odd => tail=3
    jz      .L_row_d_h_pack
    mov     (%rdx), %eax
    movd    %eax, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pmaxub  %xmm1, %xmm0
    add     $4, %rdx
    mov     (%rdx), %eax
    movd    %eax, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pmaxub  %xmm1, %xmm0
.L_row_d_h_pack:
/* Reduce four pixel positions to one B/G/R/A result. */
    movdqa  %xmm0, %xmm1
    psrldq  $8, %xmm1
    pmaxub  %xmm1, %xmm0
    movdqa  %xmm0, %xmm1
    psrldq  $4, %xmm1
    pmaxub  %xmm1, %xmm0
    movd    %xmm0, %eax
    mov     %eax, (%rdi)
    add     $4, %rdi
    add     $4, %r11
    dec     %r9d
    jnz     .L_row_d_h_px
    jmp     .L_row_epilogue

/* -------------------- horizontal erosion -------------------- */
.L_row_horizontal_e:
    mov     80(%rsp), %r10  // scratch base
    mov     72(%rsp), %r9d
    sub     %ebx, %r9d  // outputCount

    movslq  %r15d, %rax
    movslq  %r12d, %rcx
    imul    %rcx, %rax
    movslq  %ebx, %rcx
    add     %rcx, %rax
    lea     (%rdi, %rax, 4), %rdi  // dst cursor

    mov     %r10, %r11  // scratch window cursor
    lea     1(%r13d, %r13d), %r14d  // L
    mov     %r14d, %ecx
    shr     $2, %ecx  // vectorCount

.L_row_e_h_px:
    pcmpeqb %xmm0, %xmm0
    mov     %r11, %rdx
    mov     %ecx, %eax
.L_row_e_h_vec:
    test    %eax, %eax
    jz      .L_row_e_h_tail
    movdqu  (%rdx), %xmm1
    pminub  %xmm1, %xmm0
    add     $16, %rdx
    dec     %eax
    jnz     .L_row_e_h_vec
.L_row_e_h_tail:
    mov     (%rdx), %eax
    movd    %eax, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pminub  %xmm1, %xmm0
    add     $4, %rdx
    test    $1, %r13d
    jz      .L_row_e_h_pack
    mov     (%rdx), %eax
    movd    %eax, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pminub  %xmm1, %xmm0
    add     $4, %rdx
    mov     (%rdx), %eax
    movd    %eax, %xmm1
    pshufd  $0, %xmm1, %xmm1
    pminub  %xmm1, %xmm0
.L_row_e_h_pack:
/* Reduce four pixel positions to one B/G/R/A result. */
    movdqa  %xmm0, %xmm1
    psrldq  $8, %xmm1
    pminub  %xmm1, %xmm0
    movdqa  %xmm0, %xmm1
    psrldq  $4, %xmm1
    pminub  %xmm1, %xmm0
    movd    %xmm0, %eax
    mov     %eax, (%rdi)
    add     $4, %rdi
    add     $4, %r11
    dec     %r9d
    jnz     .L_row_e_h_px

.L_row_epilogue:
    pop     %r15
    pop     %r14
    pop     %r13
    pop     %r12
    pop     %rbp
    pop     %rbx
    ret
    // SIZE(SYM(ksvgMorphologyApplyRowSse2))
GNU_STACK
