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
    RODATA16
.p2align 4, 0x0
.LCPI0_0:
.long 0
.long 1
.long 2
.long 3
.LCPI0_1:
.long 0x437f0000  // float 255
.long 0x437f0000  // float 255
.long 0x437f0000  // float 255
.long 0x437f0000  // float 255
.LCPI0_2:
.long 0xbf000000  // float -0.5
.long 0xbf000000  // float -0.5
.long 0xbf000000  // float -0.5
.long 0xbf000000  // float -0.5
.LCPI0_3:
.long 4
.long 4
.long 4
.long 4
.LCPI0_6:
.byte 255
.byte 0
.byte 0
.byte 0
.byte 255
.byte 0
.byte 0
.byte 0
.byte 255
.byte 0
.byte 0
.byte 0
.byte 255
.byte 0
.byte 0
.byte 0
.LCPI0_7:
.long 0x437f0000  // float 255
.long 0x437f0000  // float 255
.zero 4
.zero 4
.LCPI0_8:
.long 0xbf000000  // float -0.5
.long 0xbf000000  // float -0.5
.zero 4
.zero 4
.LCPI0_9:
.byte 255
.byte 0
.byte 0
.byte 0
.byte 255
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
.byte 0
    RODATA4
.p2align 2, 0x0
.LCPI0_4:
.long 0x437f0000  // float 255
.LCPI0_5:
.long 0xbf000000  // float -0.5
.text
.globl SYM(ksvgDisplacementMapApplySse2)
.p2align 4, 0x90
TYPE(SYM(ksvgDisplacementMapApplySse2), @function)
    SYM(ksvgDisplacementMapApplySse2):
    CFI_START
    pushq   %rbp
    CFI_DEF_CFA_OFFSET(16)
    pushq   %r15
    CFI_DEF_CFA_OFFSET(24)
    pushq   %r14
    CFI_DEF_CFA_OFFSET(32)
    pushq   %r13
    CFI_DEF_CFA_OFFSET(40)
    pushq   %r12
    CFI_DEF_CFA_OFFSET(48)
    pushq   %rbx
    CFI_DEF_CFA_OFFSET(56)
    subq    $56, %rsp
    CFI_DEF_CFA_OFFSET(112)
    CFI_OFFSET(%rbx, -56)
    CFI_OFFSET(%r12, -48)
    CFI_OFFSET(%r13, -40)
    CFI_OFFSET(%r14, -32)
    CFI_OFFSET(%r15, -24)
    CFI_OFFSET(%rbp, -16)
                                        // kill: def $r8d killed $r8d def $r8
                                        // kill: def $ecx killed $ecx def $rcx
    movq    %rdx, -120(%rsp)
    movq    %rsi, -128(%rsp)
    movl    112(%rsp), %eax
    cmpq    $3, %rax
    ja      .LBB0_746
    movaps  %xmm0, %xmm12
    leaq    .LJTI0_0(%rip), %rdx
    movslq  (%rdx, %rax, 4), %rax
    addq    %rdx, %rax
    movaps  %xmm0, -32(%rsp)
    jmpq    *%rax
.LBB0_2:
    cmpl    $3, %r9d
    ja      .LBB0_746
    movl    %r9d, %eax
    leaq    .LJTI0_4(%rip), %rdx
    movslq  (%rdx, %rax, 4), %rax
    addq    %rdx, %rax
    jmpq    *%rax
.LBB0_4:
    testl   %r8d, %r8d
    jle     .LBB0_746
    leal    -1(%rcx), %esi
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_6
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm2
    jmp     .LBB0_22
.LBB0_374:
    cmpl    $3, %r9d
    ja      .LBB0_746
    movl    %r9d, %eax
    leaq    .LJTI0_2(%rip), %rdx
    movslq  (%rdx, %rax, 4), %rax
    addq    %rdx, %rax
    jmpq    *%rax
.LBB0_376:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_378
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movq    .LCPI0_9(%rip), %xmm1
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movl    $1, %eax
    movd    %eax, %xmm4
    movl    $2, %eax
    movd    %eax, %xmm5
    movq    -120(%rsp), %rsi
    jmp     .LBB0_394
.LBB0_560:
    cmpl    $3, %r9d
    ja      .LBB0_746
    movl    %r9d, %eax
    leaq    .LJTI0_1(%rip), %rdx
    movslq  (%rdx, %rax, 4), %rax
    addq    %rdx, %rax
    jmpq    *%rax
.LBB0_562:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_564
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movaps  .LCPI0_7(%rip), %xmm1
    movaps  .LCPI0_8(%rip), %xmm2
    movl    $1, %eax
    movd    %eax, %xmm3
    movl    $2, %eax
    movd    %eax, %xmm4
    movq    -120(%rsp), %rsi
    jmp     .LBB0_580
.LBB0_188:
    cmpl    $3, %r9d
    ja      .LBB0_746
    movl    %r9d, %eax
    leaq    .LJTI0_3(%rip), %rdx
    movslq  (%rdx, %rax, 4), %rax
    addq    %rdx, %rax
    jmpq    *%rax
.LBB0_190:
    testl   %r8d, %r8d
    jle     .LBB0_746
    leal    -1(%rcx), %edx
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_192
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %eax
    xorl    %r15d, %r15d
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm2
    jmp     .LBB0_208
.LBB0_420:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_421:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_394:
    movd    %ebx, %xmm6
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm7
    punpckldq %xmm7, %xmm0
    pand    %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm7
    paddd   %xmm6, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_396
    movl    %r14d, %r12d
.LBB0_396:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_397
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_399
.LBB0_400:
    testb   $1, %r15b
    jne     .LBB0_402
.LBB0_401:
    movl    %edx, %ebp
.LBB0_402:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_421
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm7
    punpckldq %xmm7, %xmm0
    pand    %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_405
    movl    %r14d, %r12d
.LBB0_405:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_406
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_408
.LBB0_409:
    testb   $1, %r15b
    jne     .LBB0_411
.LBB0_410:
    movl    %edx, %ebp
.LBB0_411:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_421
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm7
    punpckldq %xmm7, %xmm0
    pand    %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm5, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_414
    movl    %r14d, %r12d
.LBB0_414:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_415
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_417
.LBB0_418:
    testb   $1, %r15b
    jne     .LBB0_420
    jmp     .LBB0_419
.LBB0_397:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_400
.LBB0_399:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_401
    jmp     .LBB0_402
.LBB0_406:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_409
.LBB0_408:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_410
    jmp     .LBB0_411
.LBB0_415:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_418
.LBB0_417:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_420
.LBB0_419:
    movl    %edx, %ebp
    jmp     .LBB0_420
.LBB0_606:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_607:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_580:
    movd    %ebx, %xmm5
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movl    %eax, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm6
    paddd   %xmm5, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_582
    movl    %r14d, %r12d
.LBB0_582:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_583
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_585
.LBB0_586:
    testb   $1, %r15b
    jne     .LBB0_588
.LBB0_587:
    movl    %edx, %ebp
.LBB0_588:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_607
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movl    %eax, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm3, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_591
    movl    %r14d, %r12d
.LBB0_591:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_592
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_594
.LBB0_595:
    testb   $1, %r15b
    jne     .LBB0_597
.LBB0_596:
    movl    %edx, %ebp
.LBB0_597:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_607
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movl    %eax, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_600
    movl    %r14d, %r12d
.LBB0_600:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_601
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_603
.LBB0_604:
    testb   $1, %r15b
    jne     .LBB0_606
    jmp     .LBB0_605
.LBB0_583:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_586
.LBB0_585:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_587
    jmp     .LBB0_588
.LBB0_592:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_595
.LBB0_594:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_596
    jmp     .LBB0_597
.LBB0_601:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_604
.LBB0_603:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_606
.LBB0_605:
    movl    %edx, %ebp
    jmp     .LBB0_606
.LBB0_48:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -120(%rsp), %rdx
    movl    %eax, (%rdx, %r11)
.LBB0_49:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_22:
    movq    -128(%rsp), %rax
    movzbl  -6(%rax, %r11), %eax
    xorps   %xmm3, %xmm3
    cvtsi2ss %eax, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %r14d
    movl    %r14d, %edx
    cmpl    %esi, %r14d
    jge     .LBB0_23
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_25
.LBB0_26:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_27
.LBB0_28:
    testl   %r14d, %r14d
    js      .LBB0_30
.LBB0_29:
    movl    %eax, %ebp
.LBB0_30:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -120(%rsp), %rdx
    movl    %eax, -8(%rdx, %r11)
    cmpl    $1, %ecx
    je      .LBB0_49
    movq    -128(%rsp), %rax
    movzbl  -2(%rax, %r11), %eax
    xorps   %xmm3, %xmm3
    cvtsi2ss %eax, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %r14d
    leal    1(%r14), %edx
    cmpl    %esi, %edx
    jge     .LBB0_32
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_34
.LBB0_35:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_36
.LBB0_37:
    testl   %r14d, %r14d
    js      .LBB0_39
.LBB0_38:
    movl    %eax, %ebp
.LBB0_39:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -120(%rsp), %rdx
    movl    %eax, -4(%rdx, %r11)
    cmpl    $2, %ecx
    je      .LBB0_49
    movq    -128(%rsp), %rax
    movzbl  2(%rax, %r11), %eax
    xorps   %xmm3, %xmm3
    cvtsi2ss %eax, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %r14d
    leal    2(%r14), %edx
    cmpl    %esi, %edx
    jge     .LBB0_41
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_43
.LBB0_44:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_45
.LBB0_46:
    testl   %r14d, %r14d
    js      .LBB0_48
    jmp     .LBB0_47
.LBB0_23:
    movl    %esi, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_26
.LBB0_25:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_28
.LBB0_27:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    jns     .LBB0_29
    jmp     .LBB0_30
.LBB0_32:
    movl    %esi, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_35
.LBB0_34:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_37
.LBB0_36:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    jns     .LBB0_38
    jmp     .LBB0_39
.LBB0_41:
    movl    %esi, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_44
.LBB0_43:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_46
.LBB0_45:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    js      .LBB0_48
.LBB0_47:
    movl    %eax, %ebp
    jmp     .LBB0_48
.LBB0_234:
    imull   %ecx, %ebp
    addl    %r14d, %ebp
    movslq  %ebp, %rsi
    movl    (%rdi, %rsi, 4), %esi
    movq    -120(%rsp), %r11
    movl    %esi, (%r11, %rax)
.LBB0_235:
    incq    %r15
    addq    %r10, %rax
    cmpq    %r15, %r8
    je      .LBB0_746
.LBB0_208:
    movq    -128(%rsp), %rsi
    movl    -8(%rsi, %rax), %ebx
    movl    %ebx, %esi
    shrl    $16, %esi
    movzbl  %sil, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r11d
    movl    %r11d, %esi
    cmpl    %edx, %r11d
    jl      .LBB0_210
    movl    %edx, %esi
.LBB0_210:
    xorl    %ebp, %ebp
    movl    $0, %r14d
    testl   %r11d, %r11d
    js      .LBB0_212
    movl    %esi, %r14d
.LBB0_212:
    movzbl  %bh, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r11d
    addl    %r15d, %r11d
    movl    %r11d, %esi
    cmpl    %r9d, %r11d
    jl      .LBB0_214
    movl    %r9d, %esi
.LBB0_214:
    testl   %r11d, %r11d
    js      .LBB0_216
    movl    %esi, %ebp
.LBB0_216:
    imull   %ecx, %ebp
    addl    %r14d, %ebp
    movslq  %ebp, %rsi
    movl    (%rdi, %rsi, 4), %esi
    movq    -120(%rsp), %r11
    movl    %esi, -8(%r11, %rax)
    cmpl    $1, %ecx
    je      .LBB0_235
    movq    -128(%rsp), %rsi
    movl    -4(%rsi, %rax), %esi
    movl    %esi, %r12d
    shrl    $16, %esi
    movzbl  %sil, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r11d
    leal    1(%r11), %ebx
    cmpl    %edx, %ebx
    jl      .LBB0_219
    movl    %edx, %ebx
.LBB0_219:
    xorl    %ebp, %ebp
    movl    $0, %r14d
    cmpl    $-1, %r11d
    jl      .LBB0_221
    movl    %ebx, %r14d
.LBB0_221:
    movl    %r12d, %ebx
    movzbl  %bh, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r11d
    addl    %r15d, %r11d
    movl    %r11d, %esi
    cmpl    %r9d, %r11d
    jl      .LBB0_223
    movl    %r9d, %esi
.LBB0_223:
    testl   %r11d, %r11d
    js      .LBB0_225
    movl    %esi, %ebp
.LBB0_225:
    imull   %ecx, %ebp
    addl    %r14d, %ebp
    movslq  %ebp, %rsi
    movl    (%rdi, %rsi, 4), %esi
    movq    -120(%rsp), %r11
    movl    %esi, -4(%r11, %rax)
    cmpl    $2, %ecx
    je      .LBB0_235
    movq    -128(%rsp), %rsi
    movl    (%rsi, %rax), %esi
    movl    %esi, %r12d
    shrl    $16, %esi
    movzbl  %sil, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r11d
    leal    2(%r11), %ebx
    cmpl    %edx, %ebx
    jl      .LBB0_228
    movl    %edx, %ebx
.LBB0_228:
    xorl    %ebp, %ebp
    movl    $0, %r14d
    cmpl    $-2, %r11d
    jl      .LBB0_230
    movl    %ebx, %r14d
.LBB0_230:
    movl    %r12d, %ebx
    movzbl  %bh, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r11d
    addl    %r15d, %r11d
    movl    %r11d, %esi
    cmpl    %r9d, %r11d
    jl      .LBB0_232
    movl    %r9d, %esi
.LBB0_232:
    testl   %r11d, %r11d
    js      .LBB0_234
    movl    %esi, %ebp
    jmp     .LBB0_234
.LBB0_468:
    testl   %r8d, %r8d
    jle     .LBB0_746
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_470
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm2
    movq    -120(%rsp), %rsi
    jmp     .LBB0_486
.LBB0_512:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, (%rsi, %r11)
.LBB0_513:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_486:
    movq    -128(%rsp), %rdx
    movzbl  -8(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    movl    %r14d, %edx
    cmpl    %eax, %r14d
    jge     .LBB0_487
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_489
.LBB0_490:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_491
.LBB0_492:
    testl   %r14d, %r14d
    js      .LBB0_494
.LBB0_493:
    movl    %edx, %ebp
.LBB0_494:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_513
    movq    -128(%rsp), %rdx
    movzbl  -4(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    leal    1(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_496
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_498
.LBB0_499:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_500
.LBB0_501:
    testl   %r14d, %r14d
    js      .LBB0_503
.LBB0_502:
    movl    %edx, %ebp
.LBB0_503:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_513
    movq    -128(%rsp), %rdx
    movzbl  (%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    leal    2(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_505
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_507
.LBB0_508:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_509
.LBB0_510:
    testl   %r14d, %r14d
    js      .LBB0_512
    jmp     .LBB0_511
.LBB0_487:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_490
.LBB0_489:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_492
.LBB0_491:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    jns     .LBB0_493
    jmp     .LBB0_494
.LBB0_496:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_499
.LBB0_498:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_501
.LBB0_500:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    jns     .LBB0_502
    jmp     .LBB0_503
.LBB0_505:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_508
.LBB0_507:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_510
.LBB0_509:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    js      .LBB0_512
.LBB0_511:
    movl    %edx, %ebp
    jmp     .LBB0_512
.LBB0_514:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_516
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movaps  .LCPI0_7(%rip), %xmm1
    movaps  .LCPI0_8(%rip), %xmm2
    movl    $1, %eax
    movd    %eax, %xmm3
    movl    $2, %eax
    movd    %eax, %xmm4
    movq    -120(%rsp), %rsi
    jmp     .LBB0_532
.LBB0_558:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_559:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_532:
    movd    %ebx, %xmm5
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm6
    paddd   %xmm5, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_534
    movl    %r14d, %r12d
.LBB0_534:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_535
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_537
.LBB0_538:
    testb   $1, %r15b
    jne     .LBB0_540
.LBB0_539:
    movl    %edx, %ebp
.LBB0_540:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_559
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm3, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_543
    movl    %r14d, %r12d
.LBB0_543:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_544
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_546
.LBB0_547:
    testb   $1, %r15b
    jne     .LBB0_549
.LBB0_548:
    movl    %edx, %ebp
.LBB0_549:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_559
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_552
    movl    %r14d, %r12d
.LBB0_552:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_553
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_555
.LBB0_556:
    testb   $1, %r15b
    jne     .LBB0_558
    jmp     .LBB0_557
.LBB0_535:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_538
.LBB0_537:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_539
    jmp     .LBB0_540
.LBB0_544:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_547
.LBB0_546:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_548
    jmp     .LBB0_549
.LBB0_553:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_556
.LBB0_555:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_558
.LBB0_557:
    movl    %edx, %ebp
    jmp     .LBB0_558
.LBB0_654:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_656
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movaps  .LCPI0_7(%rip), %xmm1
    movaps  .LCPI0_8(%rip), %xmm2
    movl    $1, %eax
    movd    %eax, %xmm3
    movl    $2, %eax
    movd    %eax, %xmm4
    movq    -120(%rsp), %rsi
    jmp     .LBB0_672
.LBB0_698:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_699:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_672:
    movd    %ebx, %xmm5
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm6
    paddd   %xmm5, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_674
    movl    %r14d, %r12d
.LBB0_674:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_675
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_677
.LBB0_678:
    testb   $1, %r15b
    jne     .LBB0_680
.LBB0_679:
    movl    %edx, %ebp
.LBB0_680:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_699
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm3, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_683
    movl    %r14d, %r12d
.LBB0_683:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_684
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_686
.LBB0_687:
    testb   $1, %r15b
    jne     .LBB0_689
.LBB0_688:
    movl    %edx, %ebp
.LBB0_689:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_699
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_692
    movl    %r14d, %r12d
.LBB0_692:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_693
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_695
.LBB0_696:
    testb   $1, %r15b
    jne     .LBB0_698
    jmp     .LBB0_697
.LBB0_675:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_678
.LBB0_677:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_679
    jmp     .LBB0_680
.LBB0_684:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_687
.LBB0_686:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_688
    jmp     .LBB0_689
.LBB0_693:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_696
.LBB0_695:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_698
.LBB0_697:
    movl    %edx, %ebp
    jmp     .LBB0_698
.LBB0_96:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_98
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movq    .LCPI0_9(%rip), %xmm1
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movl    $1, %eax
    movd    %eax, %xmm4
    movl    $2, %eax
    movd    %eax, %xmm5
    movq    -120(%rsp), %rsi
    jmp     .LBB0_114
.LBB0_140:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_141:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_114:
    movd    %ebx, %xmm6
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm7
    punpckldq %xmm0, %xmm7
    pand    %xmm1, %xmm7
    cvtdq2ps %xmm7, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm7
    paddd   %xmm6, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_116
    movl    %r14d, %r12d
.LBB0_116:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_117
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_119
.LBB0_120:
    testb   $1, %r15b
    jne     .LBB0_122
.LBB0_121:
    movl    %edx, %ebp
.LBB0_122:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_141
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm7
    punpckldq %xmm0, %xmm7
    pand    %xmm1, %xmm7
    cvtdq2ps %xmm7, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_125
    movl    %r14d, %r12d
.LBB0_125:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_126
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_128
.LBB0_129:
    testb   $1, %r15b
    jne     .LBB0_131
.LBB0_130:
    movl    %edx, %ebp
.LBB0_131:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_141
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm7
    punpckldq %xmm0, %xmm7
    pand    %xmm1, %xmm7
    cvtdq2ps %xmm7, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm5, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_134
    movl    %r14d, %r12d
.LBB0_134:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_135
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_137
.LBB0_138:
    testb   $1, %r15b
    jne     .LBB0_140
    jmp     .LBB0_139
.LBB0_117:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_120
.LBB0_119:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_121
    jmp     .LBB0_122
.LBB0_126:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_129
.LBB0_128:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_130
    jmp     .LBB0_131
.LBB0_135:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_138
.LBB0_137:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_140
.LBB0_139:
    movl    %edx, %ebp
    jmp     .LBB0_140
.LBB0_422:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_424
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movq    .LCPI0_9(%rip), %xmm1
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movl    $1, %eax
    movd    %eax, %xmm4
    movl    $2, %eax
    movd    %eax, %xmm5
    movq    -120(%rsp), %rsi
    jmp     .LBB0_440
.LBB0_466:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_467:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_440:
    movd    %ebx, %xmm6
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm7
    punpckldq %xmm7, %xmm0
    pand    %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm7
    paddd   %xmm6, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_442
    movl    %r14d, %r12d
.LBB0_442:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_443
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_445
.LBB0_446:
    testb   $1, %r15b
    jne     .LBB0_448
.LBB0_447:
    movl    %edx, %ebp
.LBB0_448:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_467
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm7
    punpckldq %xmm7, %xmm0
    pand    %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_451
    movl    %r14d, %r12d
.LBB0_451:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_452
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_454
.LBB0_455:
    testb   $1, %r15b
    jne     .LBB0_457
.LBB0_456:
    movl    %edx, %ebp
.LBB0_457:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_467
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm7
    punpckldq %xmm7, %xmm0
    pand    %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm5, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_460
    movl    %r14d, %r12d
.LBB0_460:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_461
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_463
.LBB0_464:
    testb   $1, %r15b
    jne     .LBB0_466
    jmp     .LBB0_465
.LBB0_443:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_446
.LBB0_445:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_447
    jmp     .LBB0_448
.LBB0_452:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_455
.LBB0_454:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_456
    jmp     .LBB0_457
.LBB0_461:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_464
.LBB0_463:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_466
.LBB0_465:
    movl    %edx, %ebp
    jmp     .LBB0_466
.LBB0_282:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_284
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movq    .LCPI0_9(%rip), %xmm1
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movl    $1, %eax
    movd    %eax, %xmm4
    movl    $2, %eax
    movd    %eax, %xmm5
    movq    -120(%rsp), %rsi
    jmp     .LBB0_300
.LBB0_326:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_327:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_300:
    movd    %ebx, %xmm6
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm7
    punpckldq %xmm0, %xmm7
    pand    %xmm1, %xmm7
    cvtdq2ps %xmm7, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm7
    paddd   %xmm6, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_302
    movl    %r14d, %r12d
.LBB0_302:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_303
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_305
.LBB0_306:
    testb   $1, %r15b
    jne     .LBB0_308
.LBB0_307:
    movl    %edx, %ebp
.LBB0_308:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_327
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm7
    punpckldq %xmm0, %xmm7
    pand    %xmm1, %xmm7
    cvtdq2ps %xmm7, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_311
    movl    %r14d, %r12d
.LBB0_311:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_312
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_314
.LBB0_315:
    testb   $1, %r15b
    jne     .LBB0_317
.LBB0_316:
    movl    %edx, %ebp
.LBB0_317:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_327
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm7
    punpckldq %xmm0, %xmm7
    pand    %xmm1, %xmm7
    cvtdq2ps %xmm7, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm5, %xmm7
    punpcklqdq %xmm6, %xmm7
    shufps  $226, %xmm6, %xmm7
    paddd   %xmm0, %xmm7
    pshufd  $85, %xmm7, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_320
    movl    %r14d, %r12d
.LBB0_320:
    pshufd  $80, %xmm7, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_321
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_323
.LBB0_324:
    testb   $1, %r15b
    jne     .LBB0_326
    jmp     .LBB0_325
.LBB0_303:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_306
.LBB0_305:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_307
    jmp     .LBB0_308
.LBB0_312:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_315
.LBB0_314:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_316
    jmp     .LBB0_317
.LBB0_321:
    movl    %r12d, %eax
    movd    %xmm7, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_324
.LBB0_323:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_326
.LBB0_325:
    movl    %edx, %ebp
    jmp     .LBB0_326
.LBB0_700:
    testl   %r8d, %r8d
    jle     .LBB0_746
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_702
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm2
    movq    -120(%rsp), %rsi
    jmp     .LBB0_718
.LBB0_744:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, (%rsi, %r11)
.LBB0_745:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_718:
    movq    -128(%rsp), %rdx
    movzbl  -5(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    movl    %r14d, %edx
    cmpl    %eax, %r14d
    jge     .LBB0_719
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_721
.LBB0_722:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_723
.LBB0_724:
    testl   %r14d, %r14d
    js      .LBB0_726
.LBB0_725:
    movl    %edx, %ebp
.LBB0_726:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_745
    movq    -128(%rsp), %rdx
    movzbl  -1(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    leal    1(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_728
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_730
.LBB0_731:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_732
.LBB0_733:
    testl   %r14d, %r14d
    js      .LBB0_735
.LBB0_734:
    movl    %edx, %ebp
.LBB0_735:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_745
    movq    -128(%rsp), %rdx
    movzbl  3(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    leal    2(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_737
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_739
.LBB0_740:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_741
.LBB0_742:
    testl   %r14d, %r14d
    js      .LBB0_744
    jmp     .LBB0_743
.LBB0_719:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_722
.LBB0_721:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_724
.LBB0_723:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    jns     .LBB0_725
    jmp     .LBB0_726
.LBB0_728:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_731
.LBB0_730:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_733
.LBB0_732:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    jns     .LBB0_734
    jmp     .LBB0_735
.LBB0_737:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_740
.LBB0_739:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_742
.LBB0_741:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    js      .LBB0_744
.LBB0_743:
    movl    %edx, %ebp
    jmp     .LBB0_744
.LBB0_142:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_144
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movaps  .LCPI0_7(%rip), %xmm1
    movaps  .LCPI0_8(%rip), %xmm2
    movl    $1, %eax
    movd    %eax, %xmm3
    movl    $2, %eax
    movd    %eax, %xmm4
    movq    -120(%rsp), %rsi
    jmp     .LBB0_160
.LBB0_186:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_187:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_160:
    movd    %ebx, %xmm5
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movl    %eax, %edx
    shrl    $24, %edx
    shrl    $16, %eax
    movzbl  %al, %eax
    movd    %edx, %xmm0
    movd    %eax, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm6
    paddd   %xmm5, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_162
    movl    %r14d, %r12d
.LBB0_162:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_163
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_165
.LBB0_166:
    testb   $1, %r15b
    jne     .LBB0_168
.LBB0_167:
    movl    %edx, %ebp
.LBB0_168:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_187
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movl    %eax, %edx
    shrl    $24, %edx
    shrl    $16, %eax
    movzbl  %al, %eax
    movd    %edx, %xmm0
    movd    %eax, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm3, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_171
    movl    %r14d, %r12d
.LBB0_171:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_172
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_174
.LBB0_175:
    testb   $1, %r15b
    jne     .LBB0_177
.LBB0_176:
    movl    %edx, %ebp
.LBB0_177:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_187
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movl    %eax, %edx
    shrl    $24, %edx
    shrl    $16, %eax
    movzbl  %al, %eax
    movd    %edx, %xmm0
    movd    %eax, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_180
    movl    %r14d, %r12d
.LBB0_180:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_181
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_183
.LBB0_184:
    testb   $1, %r15b
    jne     .LBB0_186
    jmp     .LBB0_185
.LBB0_163:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_166
.LBB0_165:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_167
    jmp     .LBB0_168
.LBB0_172:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_175
.LBB0_174:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_176
    jmp     .LBB0_177
.LBB0_181:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_184
.LBB0_183:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_186
.LBB0_185:
    movl    %edx, %ebp
    jmp     .LBB0_186
.LBB0_608:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_610
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movaps  .LCPI0_7(%rip), %xmm1
    movaps  .LCPI0_8(%rip), %xmm2
    movl    $1, %eax
    movd    %eax, %xmm3
    movl    $2, %eax
    movd    %eax, %xmm4
    movq    -120(%rsp), %rsi
    jmp     .LBB0_626
.LBB0_652:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_653:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_626:
    movd    %ebx, %xmm5
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm6
    paddd   %xmm5, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_628
    movl    %r14d, %r12d
.LBB0_628:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_629
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_631
.LBB0_632:
    testb   $1, %r15b
    jne     .LBB0_634
.LBB0_633:
    movl    %edx, %ebp
.LBB0_634:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_653
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm3, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_637
    movl    %r14d, %r12d
.LBB0_637:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_638
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_640
.LBB0_641:
    testb   $1, %r15b
    jne     .LBB0_643
.LBB0_642:
    movl    %edx, %ebp
.LBB0_643:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_653
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm6, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_646
    movl    %r14d, %r12d
.LBB0_646:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_647
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_649
.LBB0_650:
    testb   $1, %r15b
    jne     .LBB0_652
    jmp     .LBB0_651
.LBB0_629:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_632
.LBB0_631:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_633
    jmp     .LBB0_634
.LBB0_638:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_641
.LBB0_640:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_642
    jmp     .LBB0_643
.LBB0_647:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_650
.LBB0_649:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_652
.LBB0_651:
    movl    %edx, %ebp
    jmp     .LBB0_652
.LBB0_328:
    testl   %r8d, %r8d
    jle     .LBB0_746
    shufps  $0, %xmm12, %xmm12
    leal    -1(%rcx), %r14d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_330
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movaps  .LCPI0_7(%rip), %xmm1
    movaps  .LCPI0_8(%rip), %xmm2
    movl    $1, %eax
    movd    %eax, %xmm3
    movl    $2, %eax
    movd    %eax, %xmm4
    movq    -120(%rsp), %rsi
    jmp     .LBB0_346
.LBB0_372:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r11)
.LBB0_373:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_346:
    movd    %ebx, %xmm5
    movq    -128(%rsp), %rax
    movl    -8(%rax, %r11), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm6
    paddd   %xmm5, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_348
    movl    %r14d, %r12d
.LBB0_348:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_349
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_351
.LBB0_352:
    testb   $1, %r15b
    jne     .LBB0_354
.LBB0_353:
    movl    %edx, %ebp
.LBB0_354:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_373
    movq    -128(%rsp), %rax
    movl    -4(%rax, %r11), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm3, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_357
    movl    %r14d, %r12d
.LBB0_357:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_358
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_360
.LBB0_361:
    testb   $1, %r15b
    jne     .LBB0_363
.LBB0_362:
    movl    %edx, %ebp
.LBB0_363:
    imull   %ecx, %ebp
    addl    %eax, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_373
    movq    -128(%rsp), %rax
    movl    (%rax, %r11), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm6
    punpckldq %xmm0, %xmm6
    cvtdq2ps %xmm6, %xmm0
    divps   %xmm1, %xmm0
    addps   %xmm2, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm4, %xmm6
    punpcklqdq %xmm5, %xmm6
    shufps  $226, %xmm5, %xmm6
    paddd   %xmm0, %xmm6
    pshufd  $85, %xmm6, %xmm0
    movd    %xmm0, %r12d
    cmpl    %r14d, %r12d
    jl      .LBB0_366
    movl    %r14d, %r12d
.LBB0_366:
    pshufd  $80, %xmm6, %xmm0
    movmskpd %xmm0, %r15d
    xorl    %ebp, %ebp
    movl    $0, %eax
    testb   $2, %r15b
    je      .LBB0_367
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jge     .LBB0_369
.LBB0_370:
    testb   $1, %r15b
    jne     .LBB0_372
    jmp     .LBB0_371
.LBB0_349:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_352
.LBB0_351:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_353
    jmp     .LBB0_354
.LBB0_358:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_361
.LBB0_360:
    movl    %r9d, %edx
    testb   $1, %r15b
    je      .LBB0_362
    jmp     .LBB0_363
.LBB0_367:
    movl    %r12d, %eax
    movd    %xmm6, %edx
    cmpl    %r9d, %edx
    jl      .LBB0_370
.LBB0_369:
    movl    %r9d, %edx
    testb   $1, %r15b
    jne     .LBB0_372
.LBB0_371:
    movl    %edx, %ebp
    jmp     .LBB0_372
.LBB0_50:
    testl   %r8d, %r8d
    jle     .LBB0_746
    leal    -1(%rcx), %r11d
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_52
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %eax
    xorl    %r15d, %r15d
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm2
    jmp     .LBB0_68
.LBB0_94:
    imull   %ecx, %ebp
    addl    %r14d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movq    -120(%rsp), %rsi
    movl    %edx, (%rsi, %rax)
.LBB0_95:
    incq    %r15
    addq    %r10, %rax
    cmpq    %r15, %r8
    je      .LBB0_746
.LBB0_68:
    movq    -128(%rsp), %rdx
    movl    -8(%rdx, %rax), %ebx
    movzbl  %bh, %edx
    xorps   %xmm3, %xmm3
    cvtsi2ss %edx, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %edx
    movl    %edx, %esi
    cmpl    %r11d, %edx
    jl      .LBB0_70
    movl    %r11d, %esi
.LBB0_70:
    xorl    %ebp, %ebp
    movl    $0, %r14d
    testl   %edx, %edx
    js      .LBB0_72
    movl    %esi, %r14d
.LBB0_72:
    shrl    $16, %ebx
    movzbl  %bl, %edx
    xorps   %xmm3, %xmm3
    cvtsi2ss %edx, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %edx
    addl    %r15d, %edx
    movl    %edx, %esi
    cmpl    %r9d, %edx
    jl      .LBB0_74
    movl    %r9d, %esi
.LBB0_74:
    testl   %edx, %edx
    js      .LBB0_76
    movl    %esi, %ebp
.LBB0_76:
    imull   %ecx, %ebp
    addl    %r14d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movq    -120(%rsp), %rsi
    movl    %edx, -8(%rsi, %rax)
    cmpl    $1, %ecx
    je      .LBB0_95
    movq    -128(%rsp), %rdx
    movl    -4(%rdx, %rax), %ebx
    movzbl  %bh, %edx
    xorps   %xmm3, %xmm3
    cvtsi2ss %edx, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %edx
    leal    1(%rdx), %r12d
    cmpl    %r11d, %r12d
    jl      .LBB0_79
    movl    %r11d, %r12d
.LBB0_79:
    xorl    %ebp, %ebp
    movl    $0, %r14d
    cmpl    $-1, %edx
    jl      .LBB0_81
    movl    %r12d, %r14d
.LBB0_81:
    shrl    $16, %ebx
    movzbl  %bl, %edx
    xorps   %xmm3, %xmm3
    cvtsi2ss %edx, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %edx
    addl    %r15d, %edx
    movl    %edx, %esi
    cmpl    %r9d, %edx
    jl      .LBB0_83
    movl    %r9d, %esi
.LBB0_83:
    testl   %edx, %edx
    js      .LBB0_85
    movl    %esi, %ebp
.LBB0_85:
    imull   %ecx, %ebp
    addl    %r14d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movq    -120(%rsp), %rsi
    movl    %edx, -4(%rsi, %rax)
    cmpl    $2, %ecx
    je      .LBB0_95
    movq    -128(%rsp), %rdx
    movl    (%rdx, %rax), %ebx
    movzbl  %bh, %edx
    xorps   %xmm3, %xmm3
    cvtsi2ss %edx, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %edx
    leal    2(%rdx), %r12d
    cmpl    %r11d, %r12d
    jl      .LBB0_88
    movl    %r11d, %r12d
.LBB0_88:
    xorl    %ebp, %ebp
    movl    $0, %r14d
    cmpl    $-2, %edx
    jl      .LBB0_90
    movl    %r12d, %r14d
.LBB0_90:
    shrl    $16, %ebx
    movzbl  %bl, %edx
    xorps   %xmm3, %xmm3
    cvtsi2ss %edx, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm2, %xmm3
    mulss   %xmm12, %xmm3
    cvttss2si %xmm3, %edx
    addl    %r15d, %edx
    movl    %edx, %esi
    cmpl    %r9d, %edx
    jl      .LBB0_92
    movl    %r9d, %esi
.LBB0_92:
    testl   %edx, %edx
    js      .LBB0_94
    movl    %esi, %ebp
    jmp     .LBB0_94
.LBB0_236:
    testl   %r8d, %r8d
    jle     .LBB0_746
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $4, %ecx
    jge     .LBB0_238
    testl   %ecx, %ecx
    jle     .LBB0_746
    movl    %ecx, %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $8, %r11d
    xorl    %ebx, %ebx
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm2
    movq    -120(%rsp), %rsi
    jmp     .LBB0_254
.LBB0_280:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, (%rsi, %r11)
.LBB0_281:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_746
.LBB0_254:
    movq    -128(%rsp), %rdx
    movzbl  -7(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    movl    %r14d, %edx
    cmpl    %eax, %r14d
    jge     .LBB0_255
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_257
.LBB0_258:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_259
.LBB0_260:
    testl   %r14d, %r14d
    js      .LBB0_262
.LBB0_261:
    movl    %edx, %ebp
.LBB0_262:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, -8(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_281
    movq    -128(%rsp), %rdx
    movzbl  -3(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    leal    1(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_264
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_266
.LBB0_267:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_268
.LBB0_269:
    testl   %r14d, %r14d
    js      .LBB0_271
.LBB0_270:
    movl    %edx, %ebp
.LBB0_271:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, -4(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_281
    movq    -128(%rsp), %rdx
    movzbl  1(%rdx, %r11), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm2, %xmm0
    mulss   %xmm12, %xmm0
    cvttss2si %xmm0, %r14d
    leal    2(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_273
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_275
.LBB0_276:
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jge     .LBB0_277
.LBB0_278:
    testl   %r14d, %r14d
    js      .LBB0_280
    jmp     .LBB0_279
.LBB0_255:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_258
.LBB0_257:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_260
.LBB0_259:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    jns     .LBB0_261
    jmp     .LBB0_262
.LBB0_264:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_267
.LBB0_266:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_269
.LBB0_268:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    jns     .LBB0_270
    jmp     .LBB0_271
.LBB0_273:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_276
.LBB0_275:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %edx
    cmpl    %r9d, %r14d
    jl      .LBB0_278
.LBB0_277:
    movl    %r9d, %edx
    testl   %r14d, %r14d
    js      .LBB0_280
.LBB0_279:
    movl    %edx, %ebp
    jmp     .LBB0_280
.LBB0_470:
    shufps  $0, %xmm12, %xmm12
    movaps  %xmm12, -96(%rsp)
    movd    %eax, %xmm0
    pshufd  $0, %xmm0, %xmm2
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm7
    movl    %ecx, %r10d
    movl    %r8d, %edx
    movq    %rdx, -64(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rdx
    movq    %rdx, -80(%rsp)
    movl    $16, %ebx
    xorl    %r14d, %r14d
    pxor    %xmm9, %xmm9
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm10
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -112(%rsp), %xmm8
    movdqa  .LCPI0_3(%rip), %xmm11
    jmp     .LBB0_471
.p2align 4, 0x90
.LBB0_483:
    incq    %r14
    movq    -80(%rsp), %rdx
    addq    %rdx, %r12
    addq    %rdx, %r15
    movq    -48(%rsp), %rbx
    addq    %rdx, %rbx
    cmpq    -64(%rsp), %r14
    je      .LBB0_746
.LBB0_471:
                                        // Child Loop BB0_472 Depth 2
                                        // Child Loop BB0_474 Depth 2
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
    movaps  .LCPI0_2(%rip), %xmm1
    movaps  -96(%rsp), %xmm4
.p2align 4, 0x90
.LBB0_472:  // Parent Loop BB0_471 Depth=1
    movq    %rbp, %r8
    movups  (%r15, %rbp, 4), %xmm0
    andps   .LCPI0_6(%rip), %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   .LCPI0_1(%rip), %xmm0
    addps   %xmm1, %xmm0
    mulps   %xmm4, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm0, %xmm12
    paddd   %xmm15, %xmm12
    paddd   %xmm14, %xmm0
    movdqa  %xmm12, %xmm5
    pcmpgtd %xmm9, %xmm5
    movdqa  %xmm0, %xmm6
    pcmpgtd %xmm9, %xmm6
    pand    %xmm0, %xmm6
    pand    %xmm12, %xmm5
    movdqa  %xmm5, %xmm0
    pcmpgtd %xmm2, %xmm0
    movdqa  %xmm2, %xmm12
    pand    %xmm0, %xmm12
    movdqa  %xmm6, %xmm13
    pcmpgtd %xmm7, %xmm13
    movdqa  %xmm7, %xmm3
    pandn   %xmm5, %xmm0
    pand    %xmm13, %xmm3
    pandn   %xmm6, %xmm13
    por     %xmm3, %xmm13
    por     %xmm12, %xmm0
    pshufd  $245, %xmm13, %xmm3
    pmuludq %xmm8, %xmm13
    pmuludq %xmm10, %xmm3
    pshufd  $232, %xmm13, %xmm5
    pshufd  $232, %xmm3, %xmm3
    punpckldq %xmm3, %xmm5
    paddd   %xmm0, %xmm5
    movq    %rbx, %r13
    movd    %xmm5, %edx
    pshufd  $85, %xmm5, %xmm0
    pshufd  $238, %xmm5, %xmm3
    movd    %xmm0, %esi
    movd    %xmm3, %r11d
    pshufd  $255, %xmm5, %xmm0
    movd    %xmm0, %ebx
    movss   (%rdi, %rbx, 4), %xmm0
    movss   (%rdi, %r11, 4), %xmm3
    movss   (%rdi, %rdx, 4), %xmm5
    movss   (%rdi, %rsi, 4), %xmm6
    unpcklps %xmm0, %xmm3
    unpcklps %xmm6, %xmm5
    movlhps %xmm3, %xmm5
    paddd   %xmm11, %xmm15
    movups  %xmm5, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    leaq    16(%r13), %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_472
    cmpl    %ecx, %ebp
    movaps  -32(%rsp), %xmm3
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm4
    jl      .LBB0_474
    jmp     .LBB0_483
.p2align 4, 0x90
.LBB0_482:
    imull   %ecx, %ebx
    addl    %r11d, %ebx
    movslq  %ebx, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_483
.LBB0_474:  // Parent Loop BB0_471 Depth=1
    movq    -128(%rsp), %rdx
    movzbl  (%rdx, %r13), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm4, %xmm0
    mulss   %xmm3, %xmm0
    cvttss2si %xmm0, %r8d
    leal    (%r8, %rbp), %edx
    movl    %edx, %esi
    cmpl    %eax, %edx
    jge     .LBB0_475
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    jns     .LBB0_477
.LBB0_478:
    addl    %r14d, %r8d
    movl    %r8d, %edx
    cmpl    %r9d, %r8d
    jge     .LBB0_479
.LBB0_480:
    testl   %r8d, %r8d
    movq    -120(%rsp), %rsi
    js      .LBB0_482
    jmp     .LBB0_481
.p2align 4, 0x90
.LBB0_475:
    movl    %eax, %esi
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    js      .LBB0_478
.LBB0_477:
    movl    %esi, %r11d
    addl    %r14d, %r8d
    movl    %r8d, %edx
    cmpl    %r9d, %r8d
    jl      .LBB0_480
.LBB0_479:
    movl    %r9d, %edx
    testl   %r8d, %r8d
    movq    -120(%rsp), %rsi
    js      .LBB0_482
.LBB0_481:
    movl    %edx, %ebx
    jmp     .LBB0_482
.LBB0_516:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm7
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm10
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm5
    movaps  .LCPI0_1(%rip), %xmm6
    movaps  .LCPI0_2(%rip), %xmm8
    pxor    %xmm9, %xmm9
    movdqa  -16(%rsp), %xmm13
    jmp     .LBB0_517
.p2align 4, 0x90
.LBB0_529:
    movq    -32(%rsp), %rdx
    incq    %rdx
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %rdx
    je      .LBB0_746
.LBB0_517:
                                        // Child Loop BB0_518 Depth 2
                                        // Child Loop BB0_520 Depth 2
    movq    %rdx, -32(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -64(%rsp)
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
.p2align 4, 0x90
.LBB0_518:  // Parent Loop BB0_517 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm4
    movdqa  %xmm4, %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm6, %xmm0
    addps   %xmm8, %xmm0
    pand    .LCPI0_6(%rip), %xmm4
    cvtdq2ps %xmm4, %xmm4
    divps   %xmm6, %xmm4
    mulps   %xmm12, %xmm0
    addps   %xmm8, %xmm4
    mulps   %xmm12, %xmm4
    cvttps2dq %xmm4, %xmm4
    cvttps2dq %xmm0, %xmm11
    paddd   %xmm14, %xmm4
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm0
    pcmpgtd %xmm9, %xmm0
    movaps  %xmm12, %xmm3
    movdqa  %xmm4, %xmm12
    pcmpgtd %xmm9, %xmm12
    pand    %xmm4, %xmm12
    pand    %xmm11, %xmm0
    movdqa  %xmm0, %xmm11
    pcmpgtd %xmm7, %xmm11
    movdqa  %xmm7, %xmm1
    pand    %xmm11, %xmm1
    movdqa  %xmm12, %xmm4
    pcmpgtd %xmm10, %xmm4
    movdqa  %xmm10, %xmm2
    pandn   %xmm0, %xmm11
    pand    %xmm4, %xmm2
    pandn   %xmm12, %xmm4
    movaps  %xmm3, %xmm12
    por     %xmm2, %xmm4
    por     %xmm1, %xmm11
    pshufd  $245, %xmm4, %xmm0
    pmuludq %xmm5, %xmm4
    pmuludq %xmm13, %xmm0
    pshufd  $232, %xmm4, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm11, %xmm1
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm4
    unpcklps %xmm0, %xmm1
    unpcklps %xmm4, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm15
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_518
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rsi
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movdqa  -64(%rsp), %xmm4
    jl      .LBB0_520
    jmp     .LBB0_529
.p2align 4, 0x90
.LBB0_528:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_529
.LBB0_520:  // Parent Loop BB0_517 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm1
    punpckldq %xmm0, %xmm1
    cvtdq2ps %xmm1, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm14
    punpcklqdq %xmm4, %xmm14
    shufps  $226, %xmm4, %xmm14
    paddd   %xmm0, %xmm14
    pshufd  $85, %xmm14, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_522
    movl    %r14d, %eax
.LBB0_522:
    pshufd  $80, %xmm14, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_523
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_525
.LBB0_526:
    testb   $1, %r11b
    jne     .LBB0_528
    jmp     .LBB0_527
.p2align 4, 0x90
.LBB0_523:
    movl    %eax, %ebx
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_526
.LBB0_525:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_528
.LBB0_527:
    movl    %eax, %r8d
    jmp     .LBB0_528
.LBB0_656:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm5
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm10
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm6
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm7, %xmm7
    movdqa  -16(%rsp), %xmm13
    jmp     .LBB0_657
.p2align 4, 0x90
.LBB0_669:
    movq    -32(%rsp), %rdx
    incq    %rdx
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %rdx
    je      .LBB0_746
.LBB0_657:
                                        // Child Loop BB0_658 Depth 2
                                        // Child Loop BB0_660 Depth 2
    movq    %rdx, -32(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -64(%rsp)
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
.p2align 4, 0x90
.LBB0_658:  // Parent Loop BB0_657 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    movdqa  %xmm0, %xmm4
    psrld   $24, %xmm4
    pand    .LCPI0_6(%rip), %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    cvtdq2ps %xmm4, %xmm4
    divps   %xmm8, %xmm4
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm4
    mulps   %xmm12, %xmm4
    cvttps2dq %xmm4, %xmm4
    cvttps2dq %xmm0, %xmm11
    paddd   %xmm14, %xmm4
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm0
    pcmpgtd %xmm7, %xmm0
    movaps  %xmm12, %xmm3
    movdqa  %xmm4, %xmm12
    pcmpgtd %xmm7, %xmm12
    pand    %xmm4, %xmm12
    pand    %xmm11, %xmm0
    movdqa  %xmm0, %xmm11
    pcmpgtd %xmm5, %xmm11
    movdqa  %xmm5, %xmm1
    pand    %xmm11, %xmm1
    movdqa  %xmm12, %xmm4
    pcmpgtd %xmm10, %xmm4
    movdqa  %xmm10, %xmm2
    pandn   %xmm0, %xmm11
    pand    %xmm4, %xmm2
    pandn   %xmm12, %xmm4
    movaps  %xmm3, %xmm12
    por     %xmm2, %xmm4
    por     %xmm1, %xmm11
    pshufd  $245, %xmm4, %xmm0
    pmuludq %xmm6, %xmm4
    pmuludq %xmm13, %xmm0
    pshufd  $232, %xmm4, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm11, %xmm1
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm4
    unpcklps %xmm0, %xmm1
    unpcklps %xmm4, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm15
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_658
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rsi
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movdqa  -64(%rsp), %xmm4
    jl      .LBB0_660
    jmp     .LBB0_669
.p2align 4, 0x90
.LBB0_668:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_669
.LBB0_660:  // Parent Loop BB0_657 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movzbl  %al, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm1
    punpckldq %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm14
    punpcklqdq %xmm4, %xmm14
    shufps  $226, %xmm4, %xmm14
    paddd   %xmm0, %xmm14
    pshufd  $85, %xmm14, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_662
    movl    %r14d, %eax
.LBB0_662:
    pshufd  $80, %xmm14, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_663
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_665
.LBB0_666:
    testb   $1, %r11b
    jne     .LBB0_668
    jmp     .LBB0_667
.p2align 4, 0x90
.LBB0_663:
    movl    %eax, %ebx
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_666
.LBB0_665:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_668
.LBB0_667:
    movl    %eax, %r8d
    jmp     .LBB0_668
.LBB0_378:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 32(%rsp)
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 16(%rsp)
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -96(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -16(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, (%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  .LCPI0_6(%rip), %xmm7
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm14, %xmm14
    movdqa  (%rsp), %xmm10
    movdqa  16(%rsp), %xmm15
    jmp     .LBB0_379
.p2align 4, 0x90
.LBB0_391:
    movq    -64(%rsp), %rdx
    incq    %rdx
    movq    -16(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -32(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -96(%rsp), %rdx
    je      .LBB0_746
.LBB0_379:
                                        // Child Loop BB0_380 Depth 2
                                        // Child Loop BB0_382 Depth 2
    movq    %rdx, -64(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -80(%rsp)
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, -48(%rsp)
    movq    %rbx, -32(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm4
    movdqa  -112(%rsp), %xmm6
    movdqa  32(%rsp), %xmm3
.p2align 4, 0x90
.LBB0_380:  // Parent Loop BB0_379 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm11
    movdqa  %xmm11, %xmm0
    psrld   $16, %xmm0
    pand    %xmm7, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    pand    %xmm7, %xmm11
    cvtdq2ps %xmm11, %xmm11
    divps   %xmm8, %xmm11
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm11
    mulps   %xmm12, %xmm11
    cvttps2dq %xmm11, %xmm11
    movaps  %xmm12, %xmm5
    cvttps2dq %xmm0, %xmm12
    paddd   -48(%rsp), %xmm11
    paddd   %xmm4, %xmm12
    movdqa  %xmm12, %xmm0
    pcmpgtd %xmm14, %xmm0
    movdqa  %xmm11, %xmm13
    pcmpgtd %xmm14, %xmm13
    pand    %xmm11, %xmm13
    pand    %xmm12, %xmm0
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm3, %xmm12
    movdqa  %xmm3, %xmm1
    pand    %xmm12, %xmm1
    movdqa  %xmm13, %xmm11
    pcmpgtd %xmm15, %xmm11
    movdqa  %xmm15, %xmm2
    pandn   %xmm0, %xmm12
    pand    %xmm11, %xmm2
    pandn   %xmm13, %xmm11
    por     %xmm2, %xmm11
    por     %xmm1, %xmm12
    pshufd  $245, %xmm11, %xmm0
    pmuludq %xmm6, %xmm11
    pmuludq %xmm10, %xmm0
    pshufd  $232, %xmm11, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm12, %xmm1
    movaps  %xmm5, %xmm12
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm11
    unpcklps %xmm0, %xmm1
    unpcklps %xmm11, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm4
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_380
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rdx
    movq    .LCPI0_9(%rip), %xmm2
    movaps  .LCPI0_7(%rip), %xmm3
    movaps  .LCPI0_8(%rip), %xmm5
    movdqa  -80(%rsp), %xmm6
    jl      .LBB0_382
    jmp     .LBB0_391
.p2align 4, 0x90
.LBB0_390:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_391
.LBB0_382:  // Parent Loop BB0_379 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm1
    punpckldq %xmm1, %xmm0
    pand    %xmm2, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm3, %xmm0
    addps   %xmm5, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm4
    punpcklqdq %xmm6, %xmm4
    shufps  $226, %xmm6, %xmm4
    paddd   %xmm0, %xmm4
    pshufd  $85, %xmm4, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_384
    movl    %r14d, %eax
.LBB0_384:
    pshufd  $80, %xmm4, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_385
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_387
.LBB0_388:
    testb   $1, %r11b
    jne     .LBB0_390
    jmp     .LBB0_389
.p2align 4, 0x90
.LBB0_385:
    movl    %eax, %ebx
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_388
.LBB0_387:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_390
.LBB0_389:
    movl    %eax, %r8d
    jmp     .LBB0_390
.LBB0_98:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 32(%rsp)
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 16(%rsp)
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -96(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -16(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, (%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  .LCPI0_6(%rip), %xmm7
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm14, %xmm14
    movdqa  (%rsp), %xmm10
    movdqa  16(%rsp), %xmm15
    jmp     .LBB0_99
.p2align 4, 0x90
.LBB0_111:
    movq    -64(%rsp), %rdx
    incq    %rdx
    movq    -16(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -32(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -96(%rsp), %rdx
    je      .LBB0_746
.LBB0_99:
                                        // Child Loop BB0_100 Depth 2
                                        // Child Loop BB0_102 Depth 2
    movq    %rdx, -64(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -80(%rsp)
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, -48(%rsp)
    movq    %rbx, -32(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm4
    movdqa  -112(%rsp), %xmm6
    movdqa  32(%rsp), %xmm3
.p2align 4, 0x90
.LBB0_100:  // Parent Loop BB0_99 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    movdqa  %xmm0, %xmm11
    psrld   $16, %xmm11
    pand    %xmm7, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    pand    %xmm7, %xmm11
    cvtdq2ps %xmm11, %xmm11
    divps   %xmm8, %xmm11
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm11
    mulps   %xmm12, %xmm11
    cvttps2dq %xmm11, %xmm11
    movaps  %xmm12, %xmm5
    cvttps2dq %xmm0, %xmm12
    paddd   -48(%rsp), %xmm11
    paddd   %xmm4, %xmm12
    movdqa  %xmm12, %xmm0
    pcmpgtd %xmm14, %xmm0
    movdqa  %xmm11, %xmm13
    pcmpgtd %xmm14, %xmm13
    pand    %xmm11, %xmm13
    pand    %xmm12, %xmm0
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm3, %xmm12
    movdqa  %xmm3, %xmm1
    pand    %xmm12, %xmm1
    movdqa  %xmm13, %xmm11
    pcmpgtd %xmm15, %xmm11
    movdqa  %xmm15, %xmm2
    pandn   %xmm0, %xmm12
    pand    %xmm11, %xmm2
    pandn   %xmm13, %xmm11
    por     %xmm2, %xmm11
    por     %xmm1, %xmm12
    pshufd  $245, %xmm11, %xmm0
    pmuludq %xmm6, %xmm11
    pmuludq %xmm10, %xmm0
    pshufd  $232, %xmm11, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm12, %xmm1
    movaps  %xmm5, %xmm12
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm11
    unpcklps %xmm0, %xmm1
    unpcklps %xmm11, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm4
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_100
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rdx
    movq    .LCPI0_9(%rip), %xmm2
    movaps  .LCPI0_7(%rip), %xmm3
    movaps  .LCPI0_8(%rip), %xmm5
    movdqa  -80(%rsp), %xmm6
    jl      .LBB0_102
    jmp     .LBB0_111
.p2align 4, 0x90
.LBB0_110:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_111
.LBB0_102:  // Parent Loop BB0_99 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movd    %eax, %xmm0
    shrl    $16, %eax
    movd    %eax, %xmm1
    punpckldq %xmm0, %xmm1
    pand    %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm0
    divps   %xmm3, %xmm0
    addps   %xmm5, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm4
    punpcklqdq %xmm6, %xmm4
    shufps  $226, %xmm6, %xmm4
    paddd   %xmm0, %xmm4
    pshufd  $85, %xmm4, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_104
    movl    %r14d, %eax
.LBB0_104:
    pshufd  $80, %xmm4, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_105
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_107
.LBB0_108:
    testb   $1, %r11b
    jne     .LBB0_110
    jmp     .LBB0_109
.p2align 4, 0x90
.LBB0_105:
    movl    %eax, %ebx
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_108
.LBB0_107:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_110
.LBB0_109:
    movl    %eax, %r8d
    jmp     .LBB0_110
.LBB0_424:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 32(%rsp)
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 16(%rsp)
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -96(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -16(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, (%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  .LCPI0_6(%rip), %xmm7
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm14, %xmm14
    movdqa  (%rsp), %xmm10
    movdqa  16(%rsp), %xmm15
    jmp     .LBB0_425
.p2align 4, 0x90
.LBB0_437:
    movq    -64(%rsp), %rdx
    incq    %rdx
    movq    -16(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -32(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -96(%rsp), %rdx
    je      .LBB0_746
.LBB0_425:
                                        // Child Loop BB0_426 Depth 2
                                        // Child Loop BB0_428 Depth 2
    movq    %rdx, -64(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -80(%rsp)
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, -48(%rsp)
    movq    %rbx, -32(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm4
    movdqa  -112(%rsp), %xmm6
    movdqa  32(%rsp), %xmm3
.p2align 4, 0x90
.LBB0_426:  // Parent Loop BB0_425 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm11
    movdqa  %xmm11, %xmm0
    psrld   $8, %xmm0
    pand    %xmm7, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    pand    %xmm7, %xmm11
    cvtdq2ps %xmm11, %xmm11
    divps   %xmm8, %xmm11
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm11
    mulps   %xmm12, %xmm11
    cvttps2dq %xmm11, %xmm11
    movaps  %xmm12, %xmm5
    cvttps2dq %xmm0, %xmm12
    paddd   -48(%rsp), %xmm11
    paddd   %xmm4, %xmm12
    movdqa  %xmm12, %xmm0
    pcmpgtd %xmm14, %xmm0
    movdqa  %xmm11, %xmm13
    pcmpgtd %xmm14, %xmm13
    pand    %xmm11, %xmm13
    pand    %xmm12, %xmm0
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm3, %xmm12
    movdqa  %xmm3, %xmm1
    pand    %xmm12, %xmm1
    movdqa  %xmm13, %xmm11
    pcmpgtd %xmm15, %xmm11
    movdqa  %xmm15, %xmm2
    pandn   %xmm0, %xmm12
    pand    %xmm11, %xmm2
    pandn   %xmm13, %xmm11
    por     %xmm2, %xmm11
    por     %xmm1, %xmm12
    pshufd  $245, %xmm11, %xmm0
    pmuludq %xmm6, %xmm11
    pmuludq %xmm10, %xmm0
    pshufd  $232, %xmm11, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm12, %xmm1
    movaps  %xmm5, %xmm12
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm11
    unpcklps %xmm0, %xmm1
    unpcklps %xmm11, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm4
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_426
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rdx
    movq    .LCPI0_9(%rip), %xmm2
    movaps  .LCPI0_7(%rip), %xmm3
    movaps  .LCPI0_8(%rip), %xmm5
    movdqa  -80(%rsp), %xmm6
    jl      .LBB0_428
    jmp     .LBB0_437
.p2align 4, 0x90
.LBB0_436:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_437
.LBB0_428:  // Parent Loop BB0_425 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm1
    punpckldq %xmm1, %xmm0
    pand    %xmm2, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm3, %xmm0
    addps   %xmm5, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm4
    punpcklqdq %xmm6, %xmm4
    shufps  $226, %xmm6, %xmm4
    paddd   %xmm0, %xmm4
    pshufd  $85, %xmm4, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_430
    movl    %r14d, %eax
.LBB0_430:
    pshufd  $80, %xmm4, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_431
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_433
.LBB0_434:
    testb   $1, %r11b
    jne     .LBB0_436
    jmp     .LBB0_435
.p2align 4, 0x90
.LBB0_431:
    movl    %eax, %ebx
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_434
.LBB0_433:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_436
.LBB0_435:
    movl    %eax, %r8d
    jmp     .LBB0_436
.LBB0_284:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 32(%rsp)
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, 16(%rsp)
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -96(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -16(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, (%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  .LCPI0_6(%rip), %xmm7
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm14, %xmm14
    movdqa  (%rsp), %xmm10
    movdqa  16(%rsp), %xmm15
    jmp     .LBB0_285
.p2align 4, 0x90
.LBB0_297:
    movq    -64(%rsp), %rdx
    incq    %rdx
    movq    -16(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -32(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -96(%rsp), %rdx
    je      .LBB0_746
.LBB0_285:
                                        // Child Loop BB0_286 Depth 2
                                        // Child Loop BB0_288 Depth 2
    movq    %rdx, -64(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -80(%rsp)
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, -48(%rsp)
    movq    %rbx, -32(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm4
    movdqa  -112(%rsp), %xmm6
    movdqa  32(%rsp), %xmm3
.p2align 4, 0x90
.LBB0_286:  // Parent Loop BB0_285 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    movdqa  %xmm0, %xmm11
    psrld   $8, %xmm11
    pand    %xmm7, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    pand    %xmm7, %xmm11
    cvtdq2ps %xmm11, %xmm11
    divps   %xmm8, %xmm11
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm11
    mulps   %xmm12, %xmm11
    cvttps2dq %xmm11, %xmm11
    movaps  %xmm12, %xmm5
    cvttps2dq %xmm0, %xmm12
    paddd   -48(%rsp), %xmm11
    paddd   %xmm4, %xmm12
    movdqa  %xmm12, %xmm0
    pcmpgtd %xmm14, %xmm0
    movdqa  %xmm11, %xmm13
    pcmpgtd %xmm14, %xmm13
    pand    %xmm11, %xmm13
    pand    %xmm12, %xmm0
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm3, %xmm12
    movdqa  %xmm3, %xmm1
    pand    %xmm12, %xmm1
    movdqa  %xmm13, %xmm11
    pcmpgtd %xmm15, %xmm11
    movdqa  %xmm15, %xmm2
    pandn   %xmm0, %xmm12
    pand    %xmm11, %xmm2
    pandn   %xmm13, %xmm11
    por     %xmm2, %xmm11
    por     %xmm1, %xmm12
    pshufd  $245, %xmm11, %xmm0
    pmuludq %xmm6, %xmm11
    pmuludq %xmm10, %xmm0
    pshufd  $232, %xmm11, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm12, %xmm1
    movaps  %xmm5, %xmm12
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm11
    unpcklps %xmm0, %xmm1
    unpcklps %xmm11, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm4
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_286
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rdx
    movq    .LCPI0_9(%rip), %xmm2
    movaps  .LCPI0_7(%rip), %xmm3
    movaps  .LCPI0_8(%rip), %xmm5
    movdqa  -80(%rsp), %xmm6
    jl      .LBB0_288
    jmp     .LBB0_297
.p2align 4, 0x90
.LBB0_296:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_297
.LBB0_288:  // Parent Loop BB0_285 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movd    %eax, %xmm0
    shrl    $8, %eax
    movd    %eax, %xmm1
    punpckldq %xmm0, %xmm1
    pand    %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm0
    divps   %xmm3, %xmm0
    addps   %xmm5, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm4
    punpcklqdq %xmm6, %xmm4
    shufps  $226, %xmm6, %xmm4
    paddd   %xmm0, %xmm4
    pshufd  $85, %xmm4, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_290
    movl    %r14d, %eax
.LBB0_290:
    pshufd  $80, %xmm4, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_291
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_293
.LBB0_294:
    testb   $1, %r11b
    jne     .LBB0_296
    jmp     .LBB0_295
.p2align 4, 0x90
.LBB0_291:
    movl    %eax, %ebx
    movd    %xmm4, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_294
.LBB0_293:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_296
.LBB0_295:
    movl    %eax, %r8d
    jmp     .LBB0_296
.LBB0_702:
    shufps  $0, %xmm12, %xmm12
    movaps  %xmm12, -96(%rsp)
    movd    %eax, %xmm0
    pshufd  $0, %xmm0, %xmm2
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm6
    movl    %ecx, %r10d
    movl    %r8d, %edx
    movq    %rdx, -64(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rdx
    movq    %rdx, -80(%rsp)
    movl    $16, %ebx
    xorl    %r14d, %r14d
    pxor    %xmm8, %xmm8
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm9
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movaps  .LCPI0_2(%rip), %xmm10
    movdqa  -112(%rsp), %xmm7
    jmp     .LBB0_703
.p2align 4, 0x90
.LBB0_715:
    incq    %r14
    movq    -80(%rsp), %rdx
    addq    %rdx, %r12
    addq    %rdx, %r15
    movq    -48(%rsp), %rbx
    addq    %rdx, %rbx
    cmpq    -64(%rsp), %r14
    je      .LBB0_746
.LBB0_703:
                                        // Child Loop BB0_704 Depth 2
                                        // Child Loop BB0_706 Depth 2
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm13
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm14
    movdqa  .LCPI0_3(%rip), %xmm1
    movaps  -96(%rsp), %xmm4
.p2align 4, 0x90
.LBB0_704:  // Parent Loop BB0_703 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    psrld   $24, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   .LCPI0_1(%rip), %xmm0
    addps   %xmm10, %xmm0
    mulps   %xmm4, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm0, %xmm5
    paddd   %xmm14, %xmm5
    paddd   %xmm13, %xmm0
    movdqa  %xmm5, %xmm15
    pcmpgtd %xmm8, %xmm15
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm8, %xmm12
    pand    %xmm0, %xmm12
    pand    %xmm5, %xmm15
    movdqa  %xmm15, %xmm0
    pcmpgtd %xmm2, %xmm0
    movdqa  %xmm2, %xmm5
    pand    %xmm0, %xmm5
    movdqa  %xmm12, %xmm11
    pcmpgtd %xmm6, %xmm11
    movdqa  %xmm6, %xmm3
    pandn   %xmm15, %xmm0
    pand    %xmm11, %xmm3
    pandn   %xmm12, %xmm11
    por     %xmm3, %xmm11
    por     %xmm5, %xmm0
    pshufd  $245, %xmm11, %xmm3
    pmuludq %xmm7, %xmm11
    pmuludq %xmm9, %xmm3
    pshufd  $232, %xmm11, %xmm5
    pshufd  $232, %xmm3, %xmm3
    punpckldq %xmm3, %xmm5
    paddd   %xmm0, %xmm5
    movq    %rbx, %r13
    movd    %xmm5, %edx
    pshufd  $85, %xmm5, %xmm0
    pshufd  $238, %xmm5, %xmm3
    movd    %xmm0, %esi
    movd    %xmm3, %r11d
    pshufd  $255, %xmm5, %xmm0
    movd    %xmm0, %ebx
    movss   (%rdi, %rbx, 4), %xmm0
    movss   (%rdi, %r11, 4), %xmm3
    movss   (%rdi, %rdx, 4), %xmm5
    movss   (%rdi, %rsi, 4), %xmm11
    unpcklps %xmm0, %xmm3
    unpcklps %xmm11, %xmm5
    movlhps %xmm3, %xmm5
    paddd   %xmm1, %xmm14
    movups  %xmm5, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    leaq    16(%r13), %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_704
    cmpl    %ecx, %ebp
    movaps  -32(%rsp), %xmm3
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm4
    jl      .LBB0_706
    jmp     .LBB0_715
.p2align 4, 0x90
.LBB0_714:
    imull   %ecx, %ebx
    addl    %r11d, %ebx
    movslq  %ebx, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_715
.LBB0_706:  // Parent Loop BB0_703 Depth=1
    movq    -128(%rsp), %rdx
    movzbl  3(%rdx, %r13), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm4, %xmm0
    mulss   %xmm3, %xmm0
    cvttss2si %xmm0, %r8d
    leal    (%r8, %rbp), %edx
    movl    %edx, %esi
    cmpl    %eax, %edx
    jge     .LBB0_707
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    jns     .LBB0_709
.LBB0_710:
    addl    %r14d, %r8d
    movl    %r8d, %edx
    cmpl    %r9d, %r8d
    jge     .LBB0_711
.LBB0_712:
    testl   %r8d, %r8d
    movq    -120(%rsp), %rsi
    js      .LBB0_714
    jmp     .LBB0_713
.p2align 4, 0x90
.LBB0_707:
    movl    %eax, %esi
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    js      .LBB0_710
.LBB0_709:
    movl    %esi, %r11d
    addl    %r14d, %r8d
    movl    %r8d, %edx
    cmpl    %r9d, %r8d
    jl      .LBB0_712
.LBB0_711:
    movl    %r9d, %edx
    testl   %r8d, %r8d
    movq    -120(%rsp), %rsi
    js      .LBB0_714
.LBB0_713:
    movl    %edx, %ebx
    jmp     .LBB0_714
.LBB0_564:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm5
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm10
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm6
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm7, %xmm7
    movdqa  -16(%rsp), %xmm13
    jmp     .LBB0_565
.p2align 4, 0x90
.LBB0_577:
    movq    -32(%rsp), %rdx
    incq    %rdx
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %rdx
    je      .LBB0_746
.LBB0_565:
                                        // Child Loop BB0_566 Depth 2
                                        // Child Loop BB0_568 Depth 2
    movq    %rdx, -32(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -64(%rsp)
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
.p2align 4, 0x90
.LBB0_566:  // Parent Loop BB0_565 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm4
    movdqa  %xmm4, %xmm0
    psrld   $16, %xmm0
    pand    .LCPI0_6(%rip), %xmm0
    psrld   $24, %xmm4
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    cvtdq2ps %xmm4, %xmm4
    divps   %xmm8, %xmm4
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm4
    mulps   %xmm12, %xmm4
    cvttps2dq %xmm4, %xmm4
    cvttps2dq %xmm0, %xmm11
    paddd   %xmm14, %xmm4
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm0
    pcmpgtd %xmm7, %xmm0
    movaps  %xmm12, %xmm3
    movdqa  %xmm4, %xmm12
    pcmpgtd %xmm7, %xmm12
    pand    %xmm4, %xmm12
    pand    %xmm11, %xmm0
    movdqa  %xmm0, %xmm11
    pcmpgtd %xmm5, %xmm11
    movdqa  %xmm5, %xmm1
    pand    %xmm11, %xmm1
    movdqa  %xmm12, %xmm4
    pcmpgtd %xmm10, %xmm4
    movdqa  %xmm10, %xmm2
    pandn   %xmm0, %xmm11
    pand    %xmm4, %xmm2
    pandn   %xmm12, %xmm4
    movaps  %xmm3, %xmm12
    por     %xmm2, %xmm4
    por     %xmm1, %xmm11
    pshufd  $245, %xmm4, %xmm0
    pmuludq %xmm6, %xmm4
    pmuludq %xmm13, %xmm0
    pshufd  $232, %xmm4, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm11, %xmm1
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm4
    unpcklps %xmm0, %xmm1
    unpcklps %xmm4, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm15
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_566
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rsi
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movdqa  -64(%rsp), %xmm4
    jl      .LBB0_568
    jmp     .LBB0_577
.p2align 4, 0x90
.LBB0_576:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_577
.LBB0_568:  // Parent Loop BB0_565 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movl    %eax, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm1
    punpckldq %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm14
    punpcklqdq %xmm4, %xmm14
    shufps  $226, %xmm4, %xmm14
    paddd   %xmm0, %xmm14
    pshufd  $85, %xmm14, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_570
    movl    %r14d, %eax
.LBB0_570:
    pshufd  $80, %xmm14, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_571
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_573
.LBB0_574:
    testb   $1, %r11b
    jne     .LBB0_576
    jmp     .LBB0_575
.p2align 4, 0x90
.LBB0_571:
    movl    %eax, %ebx
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_574
.LBB0_573:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_576
.LBB0_575:
    movl    %eax, %r8d
    jmp     .LBB0_576
.LBB0_144:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm7
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm10
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm5
    movaps  .LCPI0_1(%rip), %xmm6
    movaps  .LCPI0_2(%rip), %xmm8
    pxor    %xmm9, %xmm9
    movdqa  -16(%rsp), %xmm13
    jmp     .LBB0_145
.p2align 4, 0x90
.LBB0_157:
    movq    -32(%rsp), %rdx
    incq    %rdx
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %rdx
    je      .LBB0_746
.LBB0_145:
                                        // Child Loop BB0_146 Depth 2
                                        // Child Loop BB0_148 Depth 2
    movq    %rdx, -32(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -64(%rsp)
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
.p2align 4, 0x90
.LBB0_146:  // Parent Loop BB0_145 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    movdqa  %xmm0, %xmm4
    psrld   $24, %xmm4
    psrld   $16, %xmm0
    pand    .LCPI0_6(%rip), %xmm0
    cvtdq2ps %xmm4, %xmm4
    divps   %xmm6, %xmm4
    addps   %xmm8, %xmm4
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm6, %xmm0
    mulps   %xmm12, %xmm4
    addps   %xmm8, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    cvttps2dq %xmm4, %xmm11
    paddd   %xmm14, %xmm0
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm4
    pcmpgtd %xmm9, %xmm4
    movaps  %xmm12, %xmm3
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm9, %xmm12
    pand    %xmm0, %xmm12
    pand    %xmm11, %xmm4
    movdqa  %xmm4, %xmm11
    pcmpgtd %xmm7, %xmm11
    movdqa  %xmm7, %xmm1
    pand    %xmm11, %xmm1
    movdqa  %xmm12, %xmm0
    pcmpgtd %xmm10, %xmm0
    movdqa  %xmm10, %xmm2
    pandn   %xmm4, %xmm11
    pand    %xmm0, %xmm2
    pandn   %xmm12, %xmm0
    movaps  %xmm3, %xmm12
    por     %xmm2, %xmm0
    por     %xmm1, %xmm11
    pshufd  $245, %xmm0, %xmm1
    pmuludq %xmm5, %xmm0
    pmuludq %xmm13, %xmm1
    pshufd  $232, %xmm0, %xmm0
    pshufd  $232, %xmm1, %xmm1
    punpckldq %xmm1, %xmm0
    paddd   %xmm11, %xmm0
    movq    %rbx, %r13
    movd    %xmm0, %eax
    pshufd  $85, %xmm0, %xmm1
    pshufd  $238, %xmm0, %xmm2
    movd    %xmm1, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm0, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm4
    unpcklps %xmm0, %xmm1
    unpcklps %xmm4, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm15
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_146
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rsi
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movdqa  -64(%rsp), %xmm4
    jl      .LBB0_148
    jmp     .LBB0_157
.p2align 4, 0x90
.LBB0_156:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_157
.LBB0_148:  // Parent Loop BB0_145 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movl    %eax, %edx
    shrl    $24, %edx
    shrl    $16, %eax
    movzbl  %al, %eax
    movd    %edx, %xmm0
    movd    %eax, %xmm1
    punpckldq %xmm0, %xmm1
    cvtdq2ps %xmm1, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm14
    punpcklqdq %xmm4, %xmm14
    shufps  $226, %xmm4, %xmm14
    paddd   %xmm0, %xmm14
    pshufd  $85, %xmm14, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_150
    movl    %r14d, %eax
.LBB0_150:
    pshufd  $80, %xmm14, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_151
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_153
.LBB0_154:
    testb   $1, %r11b
    jne     .LBB0_156
    jmp     .LBB0_155
.p2align 4, 0x90
.LBB0_151:
    movl    %eax, %ebx
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_154
.LBB0_153:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_156
.LBB0_155:
    movl    %eax, %r8d
    jmp     .LBB0_156
.LBB0_610:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm5
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm10
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm6
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm7, %xmm7
    movdqa  -16(%rsp), %xmm13
    jmp     .LBB0_611
.p2align 4, 0x90
.LBB0_623:
    movq    -32(%rsp), %rdx
    incq    %rdx
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %rdx
    je      .LBB0_746
.LBB0_611:
                                        // Child Loop BB0_612 Depth 2
                                        // Child Loop BB0_614 Depth 2
    movq    %rdx, -32(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -64(%rsp)
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
.p2align 4, 0x90
.LBB0_612:  // Parent Loop BB0_611 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm4
    movdqa  %xmm4, %xmm0
    psrld   $8, %xmm0
    pand    .LCPI0_6(%rip), %xmm0
    psrld   $24, %xmm4
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    cvtdq2ps %xmm4, %xmm4
    divps   %xmm8, %xmm4
    mulps   %xmm12, %xmm0
    addps   %xmm9, %xmm4
    mulps   %xmm12, %xmm4
    cvttps2dq %xmm4, %xmm4
    cvttps2dq %xmm0, %xmm11
    paddd   %xmm14, %xmm4
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm0
    pcmpgtd %xmm7, %xmm0
    movaps  %xmm12, %xmm3
    movdqa  %xmm4, %xmm12
    pcmpgtd %xmm7, %xmm12
    pand    %xmm4, %xmm12
    pand    %xmm11, %xmm0
    movdqa  %xmm0, %xmm11
    pcmpgtd %xmm5, %xmm11
    movdqa  %xmm5, %xmm1
    pand    %xmm11, %xmm1
    movdqa  %xmm12, %xmm4
    pcmpgtd %xmm10, %xmm4
    movdqa  %xmm10, %xmm2
    pandn   %xmm0, %xmm11
    pand    %xmm4, %xmm2
    pandn   %xmm12, %xmm4
    movaps  %xmm3, %xmm12
    por     %xmm2, %xmm4
    por     %xmm1, %xmm11
    pshufd  $245, %xmm4, %xmm0
    pmuludq %xmm6, %xmm4
    pmuludq %xmm13, %xmm0
    pshufd  $232, %xmm4, %xmm1
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm1
    paddd   %xmm11, %xmm1
    movq    %rbx, %r13
    movd    %xmm1, %eax
    pshufd  $85, %xmm1, %xmm0
    pshufd  $238, %xmm1, %xmm2
    movd    %xmm0, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm1, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm4
    unpcklps %xmm0, %xmm1
    unpcklps %xmm4, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm15
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_612
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rsi
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movdqa  -64(%rsp), %xmm4
    jl      .LBB0_614
    jmp     .LBB0_623
.p2align 4, 0x90
.LBB0_622:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_623
.LBB0_614:  // Parent Loop BB0_611 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm1
    punpckldq %xmm1, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm14
    punpcklqdq %xmm4, %xmm14
    shufps  $226, %xmm4, %xmm14
    paddd   %xmm0, %xmm14
    pshufd  $85, %xmm14, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_616
    movl    %r14d, %eax
.LBB0_616:
    pshufd  $80, %xmm14, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_617
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_619
.LBB0_620:
    testb   $1, %r11b
    jne     .LBB0_622
    jmp     .LBB0_621
.p2align 4, 0x90
.LBB0_617:
    movl    %eax, %ebx
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_620
.LBB0_619:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_622
.LBB0_621:
    movl    %eax, %r8d
    jmp     .LBB0_622
.LBB0_330:
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm7
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm10
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %edx, %edx
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm5
    movaps  .LCPI0_1(%rip), %xmm6
    movaps  .LCPI0_2(%rip), %xmm8
    pxor    %xmm9, %xmm9
    movdqa  -16(%rsp), %xmm13
    jmp     .LBB0_331
.p2align 4, 0x90
.LBB0_343:
    movq    -32(%rsp), %rdx
    incq    %rdx
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %rdx
    je      .LBB0_746
.LBB0_331:
                                        // Child Loop BB0_332 Depth 2
                                        // Child Loop BB0_334 Depth 2
    movq    %rdx, -32(%rsp)
    movd    %edx, %xmm0
    movdqa  %xmm0, -64(%rsp)
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
.p2align 4, 0x90
.LBB0_332:  // Parent Loop BB0_331 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    movdqa  %xmm0, %xmm4
    psrld   $24, %xmm4
    psrld   $8, %xmm0
    pand    .LCPI0_6(%rip), %xmm0
    cvtdq2ps %xmm4, %xmm4
    divps   %xmm6, %xmm4
    addps   %xmm8, %xmm4
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm6, %xmm0
    mulps   %xmm12, %xmm4
    addps   %xmm8, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    cvttps2dq %xmm4, %xmm11
    paddd   %xmm14, %xmm0
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm4
    pcmpgtd %xmm9, %xmm4
    movaps  %xmm12, %xmm3
    movdqa  %xmm0, %xmm12
    pcmpgtd %xmm9, %xmm12
    pand    %xmm0, %xmm12
    pand    %xmm11, %xmm4
    movdqa  %xmm4, %xmm11
    pcmpgtd %xmm7, %xmm11
    movdqa  %xmm7, %xmm1
    pand    %xmm11, %xmm1
    movdqa  %xmm12, %xmm0
    pcmpgtd %xmm10, %xmm0
    movdqa  %xmm10, %xmm2
    pandn   %xmm4, %xmm11
    pand    %xmm0, %xmm2
    pandn   %xmm12, %xmm0
    movaps  %xmm3, %xmm12
    por     %xmm2, %xmm0
    por     %xmm1, %xmm11
    pshufd  $245, %xmm0, %xmm1
    pmuludq %xmm5, %xmm0
    pmuludq %xmm13, %xmm1
    pshufd  $232, %xmm0, %xmm0
    pshufd  $232, %xmm1, %xmm1
    punpckldq %xmm1, %xmm0
    paddd   %xmm11, %xmm0
    movq    %rbx, %r13
    movd    %xmm0, %eax
    pshufd  $85, %xmm0, %xmm1
    pshufd  $238, %xmm0, %xmm2
    movd    %xmm1, %edx
    movd    %xmm2, %esi
    pshufd  $255, %xmm0, %xmm0
    movd    %xmm0, %r11d
    movss   (%rdi, %r11, 4), %xmm0
    movss   (%rdi, %rsi, 4), %xmm1
    movss   (%rdi, %rax, 4), %xmm2
    movss   (%rdi, %rdx, 4), %xmm4
    unpcklps %xmm0, %xmm1
    unpcklps %xmm4, %xmm2
    unpcklpd %xmm1, %xmm2
    paddd   .LCPI0_3(%rip), %xmm15
    movupd  %xmm2, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    addq    $16, %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_332
    cmpl    %ecx, %ebp
    movq    -120(%rsp), %rsi
    movaps  .LCPI0_7(%rip), %xmm2
    movaps  .LCPI0_8(%rip), %xmm3
    movdqa  -64(%rsp), %xmm4
    jl      .LBB0_334
    jmp     .LBB0_343
.p2align 4, 0x90
.LBB0_342:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_343
.LBB0_334:  // Parent Loop BB0_331 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movzbl  %ah, %edx
    shrl    $24, %eax
    movd    %eax, %xmm0
    movd    %edx, %xmm1
    punpckldq %xmm0, %xmm1
    cvtdq2ps %xmm1, %xmm0
    divps   %xmm2, %xmm0
    addps   %xmm3, %xmm0
    mulps   %xmm12, %xmm0
    cvttps2dq %xmm0, %xmm0
    movd    %ebp, %xmm14
    punpcklqdq %xmm4, %xmm14
    shufps  $226, %xmm4, %xmm14
    paddd   %xmm0, %xmm14
    pshufd  $85, %xmm14, %xmm0
    movd    %xmm0, %eax
    cmpl    %r14d, %eax
    jl      .LBB0_336
    movl    %r14d, %eax
.LBB0_336:
    pshufd  $80, %xmm14, %xmm0
    movmskpd %xmm0, %r11d
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testb   $2, %r11b
    je      .LBB0_337
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_339
.LBB0_340:
    testb   $1, %r11b
    jne     .LBB0_342
    jmp     .LBB0_341
.p2align 4, 0x90
.LBB0_337:
    movl    %eax, %ebx
    movd    %xmm14, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_340
.LBB0_339:
    movl    %r9d, %eax
    testb   $1, %r11b
    jne     .LBB0_342
.LBB0_341:
    movl    %eax, %r8d
    jmp     .LBB0_342
.LBB0_6:
    shufps  $0, %xmm12, %xmm12
    movaps  %xmm12, -96(%rsp)
    movd    %esi, %xmm2
    pshufd  $0, %xmm2, %xmm2
    movd    %r9d, %xmm3
    pshufd  $0, %xmm3, %xmm8
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -64(%rsp)
    movd    %ecx, %xmm4
    pshufd  $0, %xmm4, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -80(%rsp)
    movl    $16, %ebx
    xorl    %r14d, %r14d
    pxor    %xmm9, %xmm9
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm10
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  .LCPI0_3(%rip), %xmm11
    jmp     .LBB0_7
.p2align 4, 0x90
.LBB0_19:
    incq    %r14
    movq    -80(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -48(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -64(%rsp), %r14
    je      .LBB0_746
.LBB0_7:
                                        // Child Loop BB0_8 Depth 2
                                        // Child Loop BB0_10 Depth 2
    movd    %r14d, %xmm14
    pshufd  $0, %xmm14, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
    movaps  .LCPI0_2(%rip), %xmm1
    movaps  -96(%rsp), %xmm4
    movdqa  -112(%rsp), %xmm0
.p2align 4, 0x90
.LBB0_8:  // Parent Loop BB0_7 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm5
    psrld   $16, %xmm5
    pand    .LCPI0_6(%rip), %xmm5
    cvtdq2ps %xmm5, %xmm5
    divps   .LCPI0_1(%rip), %xmm5
    addps   %xmm1, %xmm5
    mulps   %xmm4, %xmm5
    cvttps2dq %xmm5, %xmm5
    movdqa  %xmm5, %xmm13
    paddd   %xmm15, %xmm13
    paddd   %xmm14, %xmm5
    movdqa  %xmm13, %xmm12
    pcmpgtd %xmm9, %xmm12
    movdqa  %xmm5, %xmm7
    pcmpgtd %xmm9, %xmm7
    pand    %xmm5, %xmm7
    pand    %xmm13, %xmm12
    movdqa  %xmm12, %xmm5
    pcmpgtd %xmm2, %xmm5
    movdqa  %xmm2, %xmm13
    pand    %xmm5, %xmm13
    movdqa  %xmm7, %xmm6
    pcmpgtd %xmm8, %xmm6
    movdqa  %xmm8, %xmm3
    pandn   %xmm12, %xmm5
    pand    %xmm6, %xmm3
    pandn   %xmm7, %xmm6
    por     %xmm3, %xmm6
    por     %xmm13, %xmm5
    pshufd  $245, %xmm6, %xmm3
    pmuludq %xmm0, %xmm6
    pmuludq %xmm10, %xmm3
    pshufd  $232, %xmm6, %xmm6
    pshufd  $232, %xmm3, %xmm3
    punpckldq %xmm3, %xmm6
    paddd   %xmm5, %xmm6
    movq    %rbx, %r13
    movd    %xmm6, %eax
    pshufd  $85, %xmm6, %xmm3
    pshufd  $238, %xmm6, %xmm5
    movd    %xmm3, %edx
    movd    %xmm5, %r11d
    pshufd  $255, %xmm6, %xmm3
    movd    %xmm3, %ebx
    movss   (%rdi, %rbx, 4), %xmm3
    movss   (%rdi, %r11, 4), %xmm5
    movss   (%rdi, %rax, 4), %xmm6
    movss   (%rdi, %rdx, 4), %xmm7
    unpcklps %xmm3, %xmm5
    unpcklps %xmm7, %xmm6
    movlhps %xmm5, %xmm6
    paddd   %xmm11, %xmm15
    movups  %xmm6, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    leaq    16(%r13), %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_8
    cmpl    %ecx, %ebp
    movaps  -32(%rsp), %xmm0
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm4
    jl      .LBB0_10
    jmp     .LBB0_19
.p2align 4, 0x90
.LBB0_18:
    imull   %ecx, %ebx
    addl    %r11d, %ebx
    movslq  %ebx, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -120(%rsp), %rdx
    movl    %eax, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_19
.LBB0_10:  // Parent Loop BB0_7 Depth=1
    movq    -128(%rsp), %rax
    movzbl  2(%rax, %r13), %eax
    xorps   %xmm3, %xmm3
    cvtsi2ss %eax, %xmm3
    divss   %xmm1, %xmm3
    addss   %xmm4, %xmm3
    mulss   %xmm0, %xmm3
    cvttss2si %xmm3, %r8d
    leal    (%r8, %rbp), %edx
    movl    %edx, %eax
    cmpl    %esi, %edx
    jge     .LBB0_11
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    jns     .LBB0_13
.LBB0_14:
    addl    %r14d, %r8d
    movl    %r8d, %eax
    cmpl    %r9d, %r8d
    jge     .LBB0_15
.LBB0_16:
    testl   %r8d, %r8d
    js      .LBB0_18
    jmp     .LBB0_17
.p2align 4, 0x90
.LBB0_11:
    movl    %esi, %eax
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    js      .LBB0_14
.LBB0_13:
    movl    %eax, %r11d
    addl    %r14d, %r8d
    movl    %r8d, %eax
    cmpl    %r9d, %r8d
    jl      .LBB0_16
.LBB0_15:
    movl    %r9d, %eax
    testl   %r8d, %r8d
    js      .LBB0_18
.LBB0_17:
    movl    %eax, %ebx
    jmp     .LBB0_18
.LBB0_192:
    shufps  $0, %xmm12, %xmm12
    movaps  %xmm12, (%rsp)
    movd    %edx, %xmm0
    pshufd  $0, %xmm0, %xmm13
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm4
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %r14d, %r14d
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -96(%rsp), %xmm6
    movdqa  .LCPI0_6(%rip), %xmm7
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm10, %xmm10
    movaps  (%rsp), %xmm14
    jmp     .LBB0_193
.p2align 4, 0x90
.LBB0_205:
    incq    %r14
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -64(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %r14
    je      .LBB0_746
.LBB0_193:
                                        // Child Loop BB0_194 Depth 2
                                        // Child Loop BB0_196 Depth 2
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm0
    movdqa  %xmm0, -48(%rsp)
    movq    %rbx, -64(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
    movdqa  -16(%rsp), %xmm1
.p2align 4, 0x90
.LBB0_194:  // Parent Loop BB0_193 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm5
    movdqa  %xmm5, %xmm0
    psrld   $8, %xmm5
    psrld   $16, %xmm0
    pand    %xmm7, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   %xmm8, %xmm0
    addps   %xmm9, %xmm0
    pand    %xmm7, %xmm5
    cvtdq2ps %xmm5, %xmm5
    divps   %xmm8, %xmm5
    mulps   %xmm14, %xmm0
    addps   %xmm9, %xmm5
    mulps   %xmm14, %xmm5
    cvttps2dq %xmm5, %xmm5
    cvttps2dq %xmm0, %xmm11
    paddd   -48(%rsp), %xmm5
    paddd   %xmm15, %xmm11
    movdqa  %xmm11, %xmm0
    pcmpgtd %xmm10, %xmm0
    movdqa  %xmm5, %xmm12
    pcmpgtd %xmm10, %xmm12
    pand    %xmm5, %xmm12
    pand    %xmm11, %xmm0
    movdqa  %xmm0, %xmm11
    pcmpgtd %xmm13, %xmm11
    movdqa  %xmm13, %xmm2
    pand    %xmm11, %xmm2
    movdqa  %xmm12, %xmm5
    pcmpgtd %xmm4, %xmm5
    movdqa  %xmm4, %xmm3
    pandn   %xmm0, %xmm11
    pand    %xmm5, %xmm3
    pandn   %xmm12, %xmm5
    por     %xmm3, %xmm5
    por     %xmm2, %xmm11
    pshufd  $245, %xmm5, %xmm0
    pmuludq %xmm6, %xmm5
    pmuludq %xmm1, %xmm0
    pshufd  $232, %xmm5, %xmm2
    pshufd  $232, %xmm0, %xmm0
    punpckldq %xmm0, %xmm2
    paddd   %xmm11, %xmm2
    movq    %rbx, %r13
    movd    %xmm2, %eax
    pshufd  $85, %xmm2, %xmm0
    pshufd  $238, %xmm2, %xmm3
    movd    %xmm0, %esi
    movd    %xmm3, %r11d
    pshufd  $255, %xmm2, %xmm0
    movd    %xmm0, %ebx
    movss   (%rdi, %rbx, 4), %xmm0
    movss   (%rdi, %r11, 4), %xmm2
    movss   (%rdi, %rax, 4), %xmm3
    movss   (%rdi, %rsi, 4), %xmm5
    unpcklps %xmm0, %xmm2
    unpcklps %xmm5, %xmm3
    movlhps %xmm2, %xmm3
    paddd   .LCPI0_3(%rip), %xmm15
    movups  %xmm3, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    leaq    16(%r13), %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_194
    cmpl    %ecx, %ebp
    movaps  -32(%rsp), %xmm2
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm3
    jl      .LBB0_196
    jmp     .LBB0_205
.p2align 4, 0x90
.LBB0_204:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -120(%rsp), %rsi
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_205
.LBB0_196:  // Parent Loop BB0_193 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movl    %eax, %esi
    shrl    $16, %esi
    movzbl  %sil, %esi
    xorps   %xmm0, %xmm0
    cvtsi2ss %esi, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm3, %xmm0
    mulss   %xmm2, %xmm0
    cvttss2si %xmm0, %r11d
    addl    %ebp, %r11d
    movl    %r11d, %esi
    cmpl    %edx, %r11d
    jl      .LBB0_198
    movl    %edx, %esi
.LBB0_198:
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testl   %r11d, %r11d
    js      .LBB0_200
    movl    %esi, %ebx
.LBB0_200:
    movzbl  %ah, %eax
    xorps   %xmm0, %xmm0
    cvtsi2ss %eax, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm3, %xmm0
    mulss   %xmm2, %xmm0
    cvttss2si %xmm0, %eax
    addl    %r14d, %eax
    movl    %eax, %esi
    cmpl    %r9d, %eax
    jl      .LBB0_202
    movl    %r9d, %esi
.LBB0_202:
    testl   %eax, %eax
    js      .LBB0_204
    movl    %esi, %r8d
    jmp     .LBB0_204
.LBB0_52:
    shufps  $0, %xmm12, %xmm12
    movaps  %xmm12, (%rsp)
    movd    %r11d, %xmm2
    pshufd  $0, %xmm2, %xmm6
    movd    %r9d, %xmm3
    pshufd  $0, %xmm3, %xmm7
    movl    %ecx, %r10d
    movl    %r8d, %eax
    movq    %rax, -80(%rsp)
    movd    %ecx, %xmm4
    pshufd  $0, %xmm4, %xmm0
    leaq    (, %r10, 4), %rax
    movq    %rax, -112(%rsp)
    movl    $16, %ebx
    xorl    %r14d, %r14d
    movdqa  %xmm0, -96(%rsp)
    pshufd  $245, %xmm0, %xmm0
    movdqa  %xmm0, -16(%rsp)
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  .LCPI0_6(%rip), %xmm4
    movaps  .LCPI0_1(%rip), %xmm8
    movaps  .LCPI0_2(%rip), %xmm9
    pxor    %xmm10, %xmm10
    jmp     .LBB0_53
.p2align 4, 0x90
.LBB0_65:
    incq    %r14
    movq    -112(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    movq    -64(%rsp), %rbx
    addq    %rax, %rbx
    cmpq    -80(%rsp), %r14
    je      .LBB0_746
.LBB0_53:
                                        // Child Loop BB0_54 Depth 2
                                        // Child Loop BB0_56 Depth 2
    movd    %r14d, %xmm14
    pshufd  $0, %xmm14, %xmm0
    movdqa  %xmm0, -48(%rsp)
    movq    %rbx, -64(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
    movdqa  -96(%rsp), %xmm0
    movdqa  -16(%rsp), %xmm1
    movaps  (%rsp), %xmm14
.p2align 4, 0x90
.LBB0_54:  // Parent Loop BB0_53 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm11
    movdqa  %xmm11, %xmm5
    psrld   $16, %xmm11
    psrld   $8, %xmm5
    pand    %xmm4, %xmm5
    cvtdq2ps %xmm5, %xmm5
    divps   %xmm8, %xmm5
    addps   %xmm9, %xmm5
    pand    %xmm4, %xmm11
    cvtdq2ps %xmm11, %xmm11
    divps   %xmm8, %xmm11
    mulps   %xmm14, %xmm5
    addps   %xmm9, %xmm11
    mulps   %xmm14, %xmm11
    cvttps2dq %xmm11, %xmm11
    cvttps2dq %xmm5, %xmm12
    paddd   -48(%rsp), %xmm11
    paddd   %xmm15, %xmm12
    movdqa  %xmm12, %xmm5
    pcmpgtd %xmm10, %xmm5
    movdqa  %xmm11, %xmm13
    pcmpgtd %xmm10, %xmm13
    pand    %xmm11, %xmm13
    pand    %xmm12, %xmm5
    movdqa  %xmm5, %xmm12
    pcmpgtd %xmm6, %xmm12
    movdqa  %xmm6, %xmm2
    pand    %xmm12, %xmm2
    movdqa  %xmm13, %xmm11
    pcmpgtd %xmm7, %xmm11
    movdqa  %xmm7, %xmm3
    pandn   %xmm5, %xmm12
    pand    %xmm11, %xmm3
    pandn   %xmm13, %xmm11
    por     %xmm3, %xmm11
    por     %xmm2, %xmm12
    pshufd  $245, %xmm11, %xmm2
    pmuludq %xmm0, %xmm11
    pmuludq %xmm1, %xmm2
    pshufd  $232, %xmm11, %xmm3
    pshufd  $232, %xmm2, %xmm2
    punpckldq %xmm2, %xmm3
    paddd   %xmm12, %xmm3
    movq    %rbx, %r13
    movd    %xmm3, %eax
    pshufd  $85, %xmm3, %xmm2
    pshufd  $238, %xmm3, %xmm5
    movd    %xmm2, %edx
    movd    %xmm5, %esi
    pshufd  $255, %xmm3, %xmm2
    movd    %xmm2, %ebx
    movss   (%rdi, %rbx, 4), %xmm2
    movss   (%rdi, %rsi, 4), %xmm3
    movss   (%rdi, %rax, 4), %xmm5
    movss   (%rdi, %rdx, 4), %xmm11
    unpcklps %xmm2, %xmm3
    unpcklps %xmm11, %xmm5
    movlhps %xmm3, %xmm5
    paddd   .LCPI0_3(%rip), %xmm15
    movups  %xmm5, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    leaq    16(%r13), %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_54
    cmpl    %ecx, %ebp
    movaps  -32(%rsp), %xmm3
    movss   .LCPI0_4(%rip), %xmm0
    movss   .LCPI0_5(%rip), %xmm1
    jl      .LBB0_56
    jmp     .LBB0_65
.p2align 4, 0x90
.LBB0_64:
    imull   %ecx, %r8d
    addl    %ebx, %r8d
    movslq  %r8d, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_65
.LBB0_56:  // Parent Loop BB0_53 Depth=1
    movq    -128(%rsp), %rax
    movl    (%rax, %r13), %eax
    movzbl  %ah, %edx
    xorps   %xmm2, %xmm2
    cvtsi2ss %edx, %xmm2
    divss   %xmm0, %xmm2
    addss   %xmm1, %xmm2
    mulss   %xmm3, %xmm2
    cvttss2si %xmm2, %edx
    addl    %ebp, %edx
    movl    %edx, %esi
    cmpl    %r11d, %edx
    jl      .LBB0_58
    movl    %r11d, %esi
.LBB0_58:
    xorl    %r8d, %r8d
    movl    $0, %ebx
    testl   %edx, %edx
    js      .LBB0_60
    movl    %esi, %ebx
.LBB0_60:
    shrl    $16, %eax
    movzbl  %al, %eax
    xorps   %xmm2, %xmm2
    cvtsi2ss %eax, %xmm2
    divss   %xmm0, %xmm2
    addss   %xmm1, %xmm2
    mulss   %xmm3, %xmm2
    cvttss2si %xmm2, %eax
    addl    %r14d, %eax
    movl    %eax, %edx
    cmpl    %r9d, %eax
    jl      .LBB0_62
    movl    %r9d, %edx
.LBB0_62:
    testl   %eax, %eax
    movq    -120(%rsp), %rsi
    js      .LBB0_64
    movl    %edx, %r8d
    jmp     .LBB0_64
.LBB0_238:
    shufps  $0, %xmm12, %xmm12
    movaps  %xmm12, -96(%rsp)
    movd    %eax, %xmm0
    pshufd  $0, %xmm0, %xmm2
    movd    %r9d, %xmm0
    pshufd  $0, %xmm0, %xmm7
    movl    %ecx, %r10d
    movl    %r8d, %edx
    movq    %rdx, -64(%rsp)
    movd    %ecx, %xmm0
    pshufd  $0, %xmm0, %xmm0
    leaq    (, %r10, 4), %rdx
    movq    %rdx, -80(%rsp)
    movl    $16, %ebx
    xorl    %r14d, %r14d
    pxor    %xmm9, %xmm9
    movdqa  %xmm0, -112(%rsp)
    pshufd  $245, %xmm0, %xmm10
    movq    -128(%rsp), %r15
    movq    -120(%rsp), %r12
    movdqa  -112(%rsp), %xmm8
    movdqa  .LCPI0_3(%rip), %xmm11
    jmp     .LBB0_239
.p2align 4, 0x90
.LBB0_251:
    incq    %r14
    movq    -80(%rsp), %rdx
    addq    %rdx, %r12
    addq    %rdx, %r15
    movq    -48(%rsp), %rbx
    addq    %rdx, %rbx
    cmpq    -64(%rsp), %r14
    je      .LBB0_746
.LBB0_239:
                                        // Child Loop BB0_240 Depth 2
                                        // Child Loop BB0_242 Depth 2
    movd    %r14d, %xmm0
    pshufd  $0, %xmm0, %xmm14
    movq    %rbx, -48(%rsp)
    xorl    %ebp, %ebp
    movdqa  .LCPI0_0(%rip), %xmm15
    movaps  .LCPI0_2(%rip), %xmm1
    movaps  -96(%rsp), %xmm4
.p2align 4, 0x90
.LBB0_240:  // Parent Loop BB0_239 Depth=1
    movq    %rbp, %r8
    movdqu  (%r15, %rbp, 4), %xmm0
    psrld   $8, %xmm0
    pand    .LCPI0_6(%rip), %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps   .LCPI0_1(%rip), %xmm0
    addps   %xmm1, %xmm0
    mulps   %xmm4, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqa  %xmm0, %xmm12
    paddd   %xmm15, %xmm12
    paddd   %xmm14, %xmm0
    movdqa  %xmm12, %xmm5
    pcmpgtd %xmm9, %xmm5
    movdqa  %xmm0, %xmm6
    pcmpgtd %xmm9, %xmm6
    pand    %xmm0, %xmm6
    pand    %xmm12, %xmm5
    movdqa  %xmm5, %xmm0
    pcmpgtd %xmm2, %xmm0
    movdqa  %xmm2, %xmm12
    pand    %xmm0, %xmm12
    movdqa  %xmm6, %xmm13
    pcmpgtd %xmm7, %xmm13
    movdqa  %xmm7, %xmm3
    pandn   %xmm5, %xmm0
    pand    %xmm13, %xmm3
    pandn   %xmm6, %xmm13
    por     %xmm3, %xmm13
    por     %xmm12, %xmm0
    pshufd  $245, %xmm13, %xmm3
    pmuludq %xmm8, %xmm13
    pmuludq %xmm10, %xmm3
    pshufd  $232, %xmm13, %xmm5
    pshufd  $232, %xmm3, %xmm3
    punpckldq %xmm3, %xmm5
    paddd   %xmm0, %xmm5
    movq    %rbx, %r13
    movd    %xmm5, %edx
    pshufd  $85, %xmm5, %xmm0
    pshufd  $238, %xmm5, %xmm3
    movd    %xmm0, %esi
    movd    %xmm3, %r11d
    pshufd  $255, %xmm5, %xmm0
    movd    %xmm0, %ebx
    movss   (%rdi, %rbx, 4), %xmm0
    movss   (%rdi, %r11, 4), %xmm3
    movss   (%rdi, %rdx, 4), %xmm5
    movss   (%rdi, %rsi, 4), %xmm6
    unpcklps %xmm0, %xmm3
    unpcklps %xmm6, %xmm5
    movlhps %xmm3, %xmm5
    paddd   %xmm11, %xmm15
    movups  %xmm5, (%r12, %rbp, 4)
    addq    $4, %rbp
    addq    $8, %r8
    leaq    16(%r13), %rbx
    cmpq    %r10, %r8
    jbe     .LBB0_240
    cmpl    %ecx, %ebp
    movaps  -32(%rsp), %xmm3
    movss   .LCPI0_4(%rip), %xmm1
    movss   .LCPI0_5(%rip), %xmm4
    jl      .LBB0_242
    jmp     .LBB0_251
.p2align 4, 0x90
.LBB0_250:
    imull   %ecx, %ebx
    addl    %r11d, %ebx
    movslq  %ebx, %rdx
    movl    (%rdi, %rdx, 4), %edx
    movl    %edx, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_251
.LBB0_242:  // Parent Loop BB0_239 Depth=1
    movq    -128(%rsp), %rdx
    movzbl  1(%rdx, %r13), %edx
    xorps   %xmm0, %xmm0
    cvtsi2ss %edx, %xmm0
    divss   %xmm1, %xmm0
    addss   %xmm4, %xmm0
    mulss   %xmm3, %xmm0
    cvttss2si %xmm0, %r8d
    leal    (%r8, %rbp), %edx
    movl    %edx, %esi
    cmpl    %eax, %edx
    jge     .LBB0_243
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    jns     .LBB0_245
.LBB0_246:
    addl    %r14d, %r8d
    movl    %r8d, %edx
    cmpl    %r9d, %r8d
    jge     .LBB0_247
.LBB0_248:
    testl   %r8d, %r8d
    movq    -120(%rsp), %rsi
    js      .LBB0_250
    jmp     .LBB0_249
.p2align 4, 0x90
.LBB0_243:
    movl    %eax, %esi
    xorl    %ebx, %ebx
    movl    $0, %r11d
    testl   %edx, %edx
    js      .LBB0_246
.LBB0_245:
    movl    %esi, %r11d
    addl    %r14d, %r8d
    movl    %r8d, %edx
    cmpl    %r9d, %r8d
    jl      .LBB0_248
.LBB0_247:
    movl    %r9d, %edx
    testl   %r8d, %r8d
    movq    -120(%rsp), %rsi
    js      .LBB0_250
.LBB0_249:
    movl    %edx, %ebx
    jmp     .LBB0_250
.LBB0_746:
    addq    $56, %rsp
    CFI_DEF_CFA_OFFSET(56)
    popq    %rbx
    CFI_DEF_CFA_OFFSET(48)
    popq    %r12
    CFI_DEF_CFA_OFFSET(40)
    popq    %r13
    CFI_DEF_CFA_OFFSET(32)
    popq    %r14
    CFI_DEF_CFA_OFFSET(24)
    popq    %r15
    CFI_DEF_CFA_OFFSET(16)
    popq    %rbp
    CFI_DEF_CFA_OFFSET(8)
    retq
.Lfunc_end0:
// SIZE(SYM(ksvgDisplacementMapApplySse2))
    CFI_END
    RODATA
.p2align 2, 0x0
.LJTI0_0:
.long .LBB0_2-.LJTI0_0
.long .LBB0_188-.LJTI0_0
.long .LBB0_374-.LJTI0_0
.long .LBB0_560-.LJTI0_0
.LJTI0_1:
.long .LBB0_562-.LJTI0_1
.long .LBB0_608-.LJTI0_1
.long .LBB0_654-.LJTI0_1
.long .LBB0_700-.LJTI0_1
.LJTI0_2:
.long .LBB0_376-.LJTI0_2
.long .LBB0_422-.LJTI0_2
.long .LBB0_468-.LJTI0_2
.long .LBB0_514-.LJTI0_2
.LJTI0_3:
.long .LBB0_190-.LJTI0_3
.long .LBB0_236-.LJTI0_3
.long .LBB0_282-.LJTI0_3
.long .LBB0_328-.LJTI0_3
.LJTI0_4:
.long .LBB0_4-.LJTI0_4
.long .LBB0_50-.LJTI0_4
.long .LBB0_96-.LJTI0_4
.long .LBB0_142-.LJTI0_4
GNU_STACK
ADDRSIG
