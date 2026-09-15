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

#include "asm_macros.S"

.text
.globl SYM(ksvgConvolveApplyInteriorSse2)
TYPE(SYM(ksvgConvolveApplyInteriorSse2), @function)
.p2align 4
    SYM(ksvgConvolveApplyInteriorSse2):
    cmpl    $0, 32(%rsp)
    je      .Lsse2_false

    pushq   %rbp
    pushq   %r15
    pushq   %r14
    pushq   %r13
    pushq   %r12
    pushq   %rbx
    subq    $48, %rsp

    movq    %rdi, %r13  // dst base/current row
    movq    %rsi, %r12  // src base/current row
    movq    %r8, %r15  // kernel base
    movl    %r9d, %ebx  // orderX
    movl    104(%rsp), %ebp  // orderY
    movl    112(%rsp), %r10d  // targetX
    movl    120(%rsp), %r11d  // targetY
    movss   %xmm0, 24(%rsp)  // divisor
    movss   %xmm1, 28(%rsp)  // bias
    movslq  %edx, %r14

    // fullEnd = targetX + ((width-orderX+1) & ~3)
    movl    %edx, %eax
    subl    %ebx, %eax
    incl    %eax
    andl    $-4, %eax
    addl    %r10d, %eax
    movl    %eax, %r9d

    // stride bytes and rowAdvance
    leaq    (, %r14, 4), %r14
    movq    %rbx, %rax
    shlq    $2, %rax
    movq    %r14, %r8
    subq    %rax, %r8

    // targetX*4
    movslq  %r10d, %rax
    shlq    $2, %rax
    movq    %rax, 0(%rsp)

    // end source row
    movl    %ecx, %eax
    subl    %ebp, %eax
    incl    %eax
    movslq  %eax, %rax
    imulq   %r14, %rax
    addq    %r12, %rax
    movq    %rax, 8(%rsp)

    // targetY*stride => destination row start
    movslq  %r11d, %rax
    imulq   %r14, %rax
    addq    %rax, %r13

    // constants
    movdqa  .Lsse2_maskFF(%rip), %xmm10
    pxor    %xmm12, %xmm12
    movdqa  .Lsse2_one(%rip), %xmm9
    movdqa  .Lsse2_max255(%rip), %xmm11
    movdqa  .Lsse2_half(%rip), %xmm8
    movss   24(%rsp), %xmm13
    shufps  $0, %xmm13, %xmm13  // divisor
    movss   28(%rsp), %xmm7
    mulss   .Lsse2_255f(%rip), %xmm7
    shufps  $0, %xmm7, %xmm7  // bias255

.Lsse2_true_y:
    movq    0(%rsp), %rax
    leaq    (%r13, %rax), %rdi  // dst block
    movq    %r12, %rsi  // src block starts at x=targetX
    movl    112(%rsp), %r10d  // current x

.Lsse2_true_x:
    cmpl    %r9d, %r10d
    jge     .Lsse2_true_next_y

    // Exact clone of the proven .Lsse2_false body (same register map):
    // B=xmm0, G=xmm1, R=xmm2, A=xmm3, pixels=xmm4, weight=xmm5, scratch=xmm6.
    pxor    %xmm0, %xmm0  // B
    pxor    %xmm1, %xmm1  // G
    pxor    %xmm2, %xmm2  // R
    pxor    %xmm3, %xmm3  // A
    movq    %rsi, %rdx
    movq    %r15, %rcx
    xorl    %eax, %eax  // ky

.Lsse2_true_ky:
    leaq    (%rdx, %rbx, 4), %r11  // end source row
.Lsse2_true_kx:
    movdqu  (%rdx), %xmm4
    movss   (%rcx), %xmm5
    shufps  $0, %xmm5, %xmm5

    movdqa  %xmm4, %xmm6
    pand    %xmm10, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm0

    movdqa  %xmm4, %xmm6
    psrld   $8, %xmm6
    pand    %xmm10, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm1

    movdqa  %xmm4, %xmm6
    psrld   $16, %xmm6
    pand    %xmm10, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm2

    movdqa  %xmm4, %xmm6
    psrld   $24, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm3

    addq    $4, %rdx
    addq    $4, %rcx
    cmpq    %r11, %rdx
    jb      .Lsse2_true_kx

    addq    %r8, %rdx
    incl    %eax
    cmpl    %ebp, %eax
    jb      .Lsse2_true_ky

    // Round/clamp B/G/R/A (identical to .Lsse2_false). For preserve=true the
    // convolved A is unused; source alpha is injected at the pack below.
    divps   %xmm13, %xmm0
    addps   %xmm7, %xmm0
    addps   %xmm8, %xmm0
    cvttps2dq %xmm0, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm0, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm0, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm0, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm0

    divps   %xmm13, %xmm1
    addps   %xmm7, %xmm1
    addps   %xmm8, %xmm1
    cvttps2dq %xmm1, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm1, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm1
    cvttps2dq %xmm1, %xmm1
    movdqa  %xmm1, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm1, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm1

    divps   %xmm13, %xmm2
    addps   %xmm7, %xmm2
    addps   %xmm8, %xmm2
    cvttps2dq %xmm2, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm2, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm2
    cvttps2dq %xmm2, %xmm2
    movdqa  %xmm2, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm2, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm2

    // Pack BGR, then preserve alpha from the center source pixel src[x, y].
    // rsi points at the window-top row (y - targetY) for column x, so add
    // targetX*4 plus targetY*stride to reach the output column/row.
    pslld   $16, %xmm2
    pslld   $8, %xmm1
    por     %xmm1, %xmm0
    por     %xmm2, %xmm0
    movslq  120(%rsp), %rax
    imulq   %r14, %rax
    addq    0(%rsp), %rax
    movdqu  (%rsi, %rax), %xmm3
    psrld   $24, %xmm3
    pslld   $24, %xmm3
    por     %xmm3, %xmm0
    movdqu  %xmm0, (%rdi)

    addq    $16, %rsi
    addq    $16, %rdi
    addl    $4, %r10d
    jmp     .Lsse2_true_x

.Lsse2_true_next_y:
    addq    %r14, %r12
    addq    %r14, %r13
    cmpq    8(%rsp), %r12
    jb      .Lsse2_true_y

    movl    %r9d, %eax
    addq    $48, %rsp
    popq    %rbx
    popq    %r12
    popq    %r13
    popq    %r14
    popq    %r15
    popq    %rbp
    retq

.Lsse2_false:
    pushq   %rbp
    pushq   %r15
    pushq   %r14
    pushq   %r13
    pushq   %r12
    pushq   %rbx
    subq    $48, %rsp

    movq    %rdi, %r13
    movq    %rsi, %r12
    movq    %r8, %r15
    movl    %r9d, %ebx
    movl    104(%rsp), %ebp
    movl    112(%rsp), %r10d
    movl    120(%rsp), %r11d
    movss   %xmm0, 24(%rsp)
    movss   %xmm1, 28(%rsp)
    movslq  %edx, %r14

    movl    %edx, %eax
    subl    %ebx, %eax
    incl    %eax
    andl    $-4, %eax
    addl    %r10d, %eax
    movl    %eax, %r9d

    leaq    (, %r14, 4), %r14
    movq    %rbx, %rax
    shlq    $2, %rax
    movq    %r14, %r8
    subq    %rax, %r8

    movslq  %r10d, %rax
    shlq    $2, %rax
    movq    %rax, 0(%rsp)

    movl    %ecx, %eax
    subl    %ebp, %eax
    incl    %eax
    movslq  %eax, %rax
    imulq   %r14, %rax
    addq    %r12, %rax
    movq    %rax, 8(%rsp)

    movslq  %r11d, %rax
    imulq   %r14, %rax
    addq    %rax, %r13

    movdqa  .Lsse2_maskFF(%rip), %xmm10
    pxor    %xmm12, %xmm12
    movdqa  .Lsse2_one(%rip), %xmm9
    movdqa  .Lsse2_max255(%rip), %xmm11
    movdqa  .Lsse2_half(%rip), %xmm8
    movss   24(%rsp), %xmm13
    shufps  $0, %xmm13, %xmm13
    movss   28(%rsp), %xmm7
    mulss   .Lsse2_255f(%rip), %xmm7
    shufps  $0, %xmm7, %xmm7

.Lsse2_false_y:
    movq    0(%rsp), %rax
    leaq    (%r13, %rax), %rdi
    movq    %r12, %rsi
    movl    112(%rsp), %r10d

.Lsse2_false_x:
    cmpl    %r9d, %r10d
    jge     .Lsse2_false_next_y

    pxor    %xmm0, %xmm0  // B
    pxor    %xmm1, %xmm1  // G
    pxor    %xmm2, %xmm2  // R
    pxor    %xmm3, %xmm3  // A
    movq    %rsi, %rdx
    movq    %r15, %rcx
    xorl    %eax, %eax

.Lsse2_false_ky:
    leaq    (%rdx, %rbx, 4), %r11
.Lsse2_false_kx:
    movdqu  (%rdx), %xmm4
    movss   (%rcx), %xmm5
    shufps  $0, %xmm5, %xmm5

    movdqa  %xmm4, %xmm6
    pand    %xmm10, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm0

    movdqa  %xmm4, %xmm6
    psrld   $8, %xmm6
    pand    %xmm10, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm1

    movdqa  %xmm4, %xmm6
    psrld   $16, %xmm6
    pand    %xmm10, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm2

    movdqa  %xmm4, %xmm6
    psrld   $24, %xmm6
    cvtdq2ps %xmm6, %xmm6
    mulps   %xmm5, %xmm6
    addps   %xmm6, %xmm3

    addq    $4, %rdx
    addq    $4, %rcx
    cmpq    %r11, %rdx
    jb      .Lsse2_false_kx
    addq    %r8, %rdx
    incl    %eax
    cmpl    %ebp, %eax
    jb      .Lsse2_false_ky

    // Round/clamp macro-expanded for B/G/R/A (same as true path).
    divps   %xmm13, %xmm0
    addps   %xmm7, %xmm0
    addps   %xmm8, %xmm0
    cvttps2dq %xmm0, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm0, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm0, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm0, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm0

    divps   %xmm13, %xmm1
    addps   %xmm7, %xmm1
    addps   %xmm8, %xmm1
    cvttps2dq %xmm1, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm1, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm1
    cvttps2dq %xmm1, %xmm1
    movdqa  %xmm1, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm1, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm1

    divps   %xmm13, %xmm2
    addps   %xmm7, %xmm2
    addps   %xmm8, %xmm2
    cvttps2dq %xmm2, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm2, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm2
    cvttps2dq %xmm2, %xmm2
    movdqa  %xmm2, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm2, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm2

    divps   %xmm13, %xmm3
    addps   %xmm7, %xmm3
    addps   %xmm8, %xmm3
    cvttps2dq %xmm3, %xmm14
    cvtdq2ps %xmm14, %xmm15
    movaps  %xmm3, %xmm14
    cmpltps %xmm15, %xmm14
    andps   %xmm9, %xmm14
    subps   %xmm14, %xmm3
    cvttps2dq %xmm3, %xmm3
    movdqa  %xmm3, %xmm14
    pcmpgtd %xmm12, %xmm14
    pand    %xmm3, %xmm14
    movdqa  %xmm11, %xmm15
    pcmpgtd %xmm14, %xmm15
    pand    %xmm15, %xmm14
    pandn   %xmm11, %xmm15
    por     %xmm14, %xmm15
    movdqa  %xmm15, %xmm3

    pslld   $24, %xmm3
    pslld   $16, %xmm2
    pslld   $8, %xmm1
    por     %xmm1, %xmm0
    por     %xmm2, %xmm0
    por     %xmm3, %xmm0
    movdqu  %xmm0, (%rdi)

    addq    $16, %rsi
    addq    $16, %rdi
    addl    $4, %r10d
    jmp     .Lsse2_false_x

.Lsse2_false_next_y:
    addq    %r14, %r12
    addq    %r14, %r13
    cmpq    8(%rsp), %r12
    jb      .Lsse2_false_y
    movl    %r9d, %eax
    addq    $48, %rsp
    popq    %rbx
    popq    %r12
    popq    %r13
    popq    %r14
    popq    %r15
    popq    %rbp
    retq

    // // SIZE(SYM(ksvgConvolveApplyInteriorSse2))

    RODATA
.p2align 4
.Lsse2_maskFF:
.long 0xff, 0xff, 0xff, 0xff
.Lsse2_one:
.long 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000
.Lsse2_half:
.long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
.Lsse2_max255:
.long 255, 255, 255, 255
.Lsse2_255f:
.long 0x437f0000
