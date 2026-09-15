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
    RODATA32
.p2align 5, 0x0
.LCPI0_0:
.long 0
.long 1
.long 2
.long 3
.long 4
.long 5
.long 6
.long 7
.LCPI0_4:
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
.LCPI0_5:
.byte 1
.byte 128
.byte 128
.byte 128
.byte 5
.byte 128
.byte 128
.byte 128
.byte 9
.byte 128
.byte 128
.byte 128
.byte 13
.byte 128
.byte 128
.byte 128
.byte 17
.byte 128
.byte 128
.byte 128
.byte 21
.byte 128
.byte 128
.byte 128
.byte 25
.byte 128
.byte 128
.byte 128
.byte 29
.byte 128
.byte 128
.byte 128
.LCPI0_6:
.byte 2
.byte 128
.byte 128
.byte 128
.byte 6
.byte 128
.byte 128
.byte 128
.byte 10
.byte 128
.byte 128
.byte 128
.byte 14
.byte 128
.byte 128
.byte 128
.byte 18
.byte 128
.byte 128
.byte 128
.byte 22
.byte 128
.byte 128
.byte 128
.byte 26
.byte 128
.byte 128
.byte 128
.byte 30
.byte 128
.byte 128
.byte 128
    RODATA4
.p2align 2, 0x0
.LCPI0_1:
.long 0x437f0000  // float 255
.LCPI0_2:
.long 0xbf000000  // float -0.5
.LCPI0_3:
.long 8
.LCPI0_7:
.byte 255
.byte 0
.byte 0
.byte 0
.LCPI0_11:
.byte 255
.byte 255
.byte 0
.byte 0
.LCPI0_12:
.byte 8
.byte 16
.byte 0
.byte 0
.LCPI0_13:
.byte 16
.byte 8
.byte 0
.byte 0
    RODATA16
.p2align 4, 0x0
.LCPI0_8:
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
.LCPI0_9:
.long 8
.long 16
.zero 4
.zero 4
.LCPI0_10:
.long 16
.long 8
.zero 4
.zero 4
    RODATA8
.LCPI0_14:
.byte 0
.byte 1
.byte 2
.byte 3
.byte 4
.byte 5
.byte 6
.byte 7
.text
.globl SYM(ksvgDisplacementMapApplyAvx2)
.p2align 4, 0x90
TYPE(SYM(ksvgDisplacementMapApplyAvx2), @function)
    SYM(ksvgDisplacementMapApplyAvx2):
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
    CFI_OFFSET(%rbx, -56)
    CFI_OFFSET(%r12, -48)
    CFI_OFFSET(%r13, -40)
    CFI_OFFSET(%r14, -32)
    CFI_OFFSET(%r15, -24)
    CFI_OFFSET(%rbp, -16)
                                        // kill: def $r8d killed $r8d def $r8
                                        // kill: def $ecx killed $ecx def $rcx
    movq    %rcx, -72(%rsp)
    movq    %rdx, -56(%rsp)
    movq    %rsi, -64(%rsp)
    movl    56(%rsp), %eax
    cmpq    $3, %rax
    ja      .LBB0_1322
    vmovaps %xmm0, %xmm5
    leaq    .LJTI0_0(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    vmovaps %xmm0, -24(%rsp)
    jmpq    *%rax
.LBB0_2:
    cmpl    $3, %r9d
    ja      .LBB0_1322
    movl    %r9d, %eax
    leaq    .LJTI0_4(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_4:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rax
    leal    -1(%rax), %edx
    leal    -1(%r8), %r9d
    cmpl    $8, %eax
    jge     .LBB0_6
    testl   %eax, %eax
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_22
.LBB0_662:
    cmpl    $3, %r9d
    ja      .LBB0_1322
    movl    %r9d, %eax
    leaq    .LJTI0_2(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_664:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_666
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_11(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_682
.LBB0_992:
    cmpl    $3, %r9d
    ja      .LBB0_1322
    movl    %r9d, %eax
    leaq    .LJTI0_1(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_994:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_996
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vbroadcastss .LCPI0_1(%rip), %xmm1
    vbroadcastss .LCPI0_2(%rip), %xmm2
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_1012
.LBB0_332:
    cmpl    $3, %r9d
    ja      .LBB0_1322
    movl    %r9d, %eax
    leaq    .LJTI0_3(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_334:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_336
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vpmovsxbd .LCPI0_12(%rip), %xmm1
    vpmovzxbd .LCPI0_11(%rip), %xmm2
    vbroadcastss .LCPI0_1(%rip), %xmm3
    vbroadcastss .LCPI0_2(%rip), %xmm4
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_352
.LBB0_828:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_830
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    movq    -72(%rsp), %rsi
    jmp     .LBB0_846
.LBB0_910:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_912
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vbroadcastss .LCPI0_1(%rip), %xmm1
    vbroadcastss .LCPI0_2(%rip), %xmm2
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_928
.LBB0_1158:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_1160
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vbroadcastss .LCPI0_1(%rip), %xmm1
    vbroadcastss .LCPI0_2(%rip), %xmm2
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_1176
.LBB0_168:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_170
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_11(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_186
.LBB0_746:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_748
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_11(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_764
.LBB0_498:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_500
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_11(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_516
.LBB0_1240:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_1242
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    movq    -72(%rsp), %rsi
    jmp     .LBB0_1258
.LBB0_250:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_252
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vbroadcastss .LCPI0_1(%rip), %xmm1
    vbroadcastss .LCPI0_2(%rip), %xmm2
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_268
.LBB0_1076:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_1078
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vbroadcastss .LCPI0_1(%rip), %xmm1
    vbroadcastss .LCPI0_2(%rip), %xmm2
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_1094
.LBB0_580:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_582
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vbroadcastss .LCPI0_1(%rip), %xmm1
    vbroadcastss .LCPI0_2(%rip), %xmm2
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %r15d
    jmp     .LBB0_598
.LBB0_86:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rax
    leal    -1(%rax), %esi
    leal    -1(%r8), %r9d
    cmpl    $8, %eax
    jge     .LBB0_88
    testl   %eax, %eax
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm5, %xmm0
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %r15d, %r15d
    vpmovsxbd .LCPI0_13(%rip), %xmm1
    vpmovzxbd .LCPI0_11(%rip), %xmm2
    vbroadcastss .LCPI0_1(%rip), %xmm3
    vbroadcastss .LCPI0_2(%rip), %xmm4
    movl    $1, %ebp
    movl    $2, %r14d
    movl    $3, %ebx
    jmp     .LBB0_104
.LBB0_416:
    testl   %r8d, %r8d
    jle     .LBB0_1322
    movq    -72(%rsp), %rcx
    leal    -1(%rcx), %eax
    leal    -1(%r8), %r9d
    cmpl    $8, %ecx
    jge     .LBB0_418
    testl   %ecx, %ecx
    jle     .LBB0_1322
    movl    -72(%rsp), %r10d
    movl    %r8d, %r8d
    shlq    $2, %r10
    movl    $24, %r11d
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    movq    -72(%rsp), %rsi
    jmp     .LBB0_434
.LBB0_830:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm7
    vbroadcastss .LCPI0_7(%rip), %ymm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %ymm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_831
.p2align 4, 0x90
.LBB0_843:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -40(%rsp), %r14
    je      .LBB0_1322
.LBB0_831:
                                        // Child Loop BB0_832 Depth 2
                                        // Child Loop BB0_834 Depth 2
    vmovd   %r14d, %xmm0
    vpbroadcastd %xmm0, %ymm13
    movq    %rbx, %rdx
    xorl    %ebp, %ebp
    vpmovsxbd .LCPI0_14(%rip), %ymm14
.p2align 4, 0x90
.LBB0_832:  // Parent Loop BB0_831 Depth=1
    movq    %rbp, %rcx
    vandps  (%r15, %rbp, 4), %ymm8, %ymm0
    vcvtdq2ps %ymm0, %ymm0
    vdivps  %ymm6, %ymm0, %ymm0
    movq    %rdx, %r13
    vaddps  %ymm7, %ymm0, %ymm0
    vmulps  %ymm0, %ymm1, %ymm0
    vcvttps2dq %ymm0, %ymm0
    vpaddd  %ymm0, %ymm14, %ymm15
    vpmaxsd %ymm9, %ymm15, %ymm15
    vpaddd  %ymm0, %ymm13, %ymm0
    vpmaxsd %ymm9, %ymm0, %ymm0
    vpminsd %ymm2, %ymm15, %ymm15
    vpminsd %ymm3, %ymm0, %ymm0
    vpmulld %ymm4, %ymm0, %ymm0
    vxorps  %xmm5, %xmm5, %xmm5
    vpaddd  %ymm0, %ymm15, %ymm0
    vpcmpeqd %ymm15, %ymm15, %ymm15
    vpgatherdd %ymm15, (%rdi, %ymm0, 4), %ymm5
    vpaddd  %ymm10, %ymm14, %ymm14
    vmovdqu %ymm5, (%r12, %rbp, 4)
    addq    $8, %rbp
    addq    $16, %rcx
    addq    $32, %rdx
    cmpq    %r10, %rcx
    jbe     .LBB0_832
    cmpl    -72(%rsp), %ebp
    vmovaps -24(%rsp), %xmm5
    jl      .LBB0_834
    jmp     .LBB0_843
.p2align 4, 0x90
.LBB0_842:
    imull   -72(%rsp), %r11d
    addl    %edx, %r11d
    movslq  %r11d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_843
.LBB0_834:  // Parent Loop BB0_831 Depth=1
    movq    -64(%rsp), %rcx
    movzbl  (%rcx, %r13), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm11, %xmm0, %xmm0
    vaddss  %xmm0, %xmm12, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r8d
    leal    (%r8, %rbp), %esi
    movl    %esi, %ecx
    cmpl    %eax, %esi
    jge     .LBB0_835
    xorl    %r11d, %r11d
    movl    $0, %edx
    testl   %esi, %esi
    jns     .LBB0_837
.LBB0_838:
    addl    %r14d, %r8d
    movl    %r8d, %ecx
    cmpl    %r9d, %r8d
    jge     .LBB0_839
.LBB0_840:
    testl   %r8d, %r8d
    js      .LBB0_842
    jmp     .LBB0_841
.p2align 4, 0x90
.LBB0_835:
    movl    %eax, %ecx
    xorl    %r11d, %r11d
    movl    $0, %edx
    testl   %esi, %esi
    js      .LBB0_838
.LBB0_837:
    movl    %ecx, %edx
    addl    %r14d, %r8d
    movl    %r8d, %ecx
    cmpl    %r9d, %r8d
    jl      .LBB0_840
.LBB0_839:
    movl    %r9d, %ecx
    testl   %r8d, %r8d
    js      .LBB0_842
.LBB0_841:
    movl    %ecx, %r11d
    jmp     .LBB0_842
.LBB0_912:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -40(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm7
    vbroadcastss .LCPI0_7(%rip), %ymm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %ymm10
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_913
.p2align 4, 0x90
.LBB0_925:
    incq    %r14
    movq    -40(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_913:
                                        // Child Loop BB0_914 Depth 2
                                        // Child Loop BB0_916 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm14
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm15
.p2align 4, 0x90
.LBB0_914:  // Parent Loop BB0_913 Depth=1
    movq    %r8, %rbp
    vmovups (%r15, %r8, 4), %ymm5
    vandps  %ymm5, %ymm8, %ymm11
    vcvtdq2ps %ymm11, %ymm11
    vdivps  %ymm6, %ymm11, %ymm11
    vpsrld  $24, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vdivps  %ymm6, %ymm5, %ymm5
    movq    %r13, %r11
    vaddps  %ymm7, %ymm5, %ymm5
    vaddps  %ymm7, %ymm11, %ymm11
    vmulps  %ymm5, %ymm1, %ymm5
    vmulps  %ymm1, %ymm11, %ymm11
    vcvttps2dq %ymm11, %ymm11
    vpaddd  %ymm14, %ymm11, %ymm11
    vcvttps2dq %ymm5, %ymm5
    vpaddd  %ymm5, %ymm15, %ymm5
    vpmaxsd %ymm9, %ymm5, %ymm5
    vpmaxsd %ymm9, %ymm11, %ymm11
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm11, %ymm11
    vpmulld %ymm4, %ymm11, %ymm11
    vpcmpeqd %ymm12, %ymm12, %ymm12
    vpaddd  %ymm5, %ymm11, %ymm5
    vpxor   %xmm11, %xmm11, %xmm11
    vpgatherdd %ymm12, (%rdi, %ymm5, 4), %ymm11
    vpaddd  %ymm10, %ymm15, %ymm15
    vmovdqu %ymm11, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_914
    cmpl    -72(%rsp), %r8d
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm15
    jl      .LBB0_916
    jmp     .LBB0_925
.p2align 4, 0x90
.LBB0_924:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_925
.LBB0_916:  // Parent Loop BB0_913 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm12, %xmm5, %xmm5
    vaddps  %xmm5, %xmm15, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r8d, %xmm13, %xmm11
    vpaddd  %xmm5, %xmm11, %xmm14
    vpextrd $1, %xmm14, %esi
    cmpl    %eax, %esi
    jl      .LBB0_918
    movl    %eax, %esi
.LBB0_918:
    vpmovsxdq %xmm14, %xmm5
    vmovmskpd %xmm5, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_919
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_921
.LBB0_922:
    testb   $1, %r13b
    jne     .LBB0_924
    jmp     .LBB0_923
.p2align 4, 0x90
.LBB0_919:
    movl    %esi, %edx
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_922
.LBB0_921:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_924
.LBB0_923:
    movl    %ecx, %ebp
    jmp     .LBB0_924
.LBB0_1160:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -40(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm7
    vpbroadcastd .LCPI0_7(%rip), %ymm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %ymm10
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_1161
.p2align 4, 0x90
.LBB0_1173:
    incq    %r14
    movq    -40(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_1161:
                                        // Child Loop BB0_1162 Depth 2
                                        // Child Loop BB0_1164 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm14
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm15
.p2align 4, 0x90
.LBB0_1162:  // Parent Loop BB0_1161 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm5
    vpsrld  $24, %ymm5, %ymm11
    vcvtdq2ps %ymm11, %ymm11
    vdivps  %ymm6, %ymm11, %ymm11
    vpand   %ymm5, %ymm8, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vdivps  %ymm6, %ymm5, %ymm5
    movq    %r13, %r11
    vaddps  %ymm7, %ymm5, %ymm5
    vaddps  %ymm7, %ymm11, %ymm11
    vmulps  %ymm5, %ymm1, %ymm5
    vmulps  %ymm1, %ymm11, %ymm11
    vcvttps2dq %ymm11, %ymm11
    vpaddd  %ymm14, %ymm11, %ymm11
    vcvttps2dq %ymm5, %ymm5
    vpaddd  %ymm5, %ymm15, %ymm5
    vpmaxsd %ymm9, %ymm5, %ymm5
    vpmaxsd %ymm9, %ymm11, %ymm11
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm11, %ymm11
    vpmulld %ymm4, %ymm11, %ymm11
    vpcmpeqd %ymm12, %ymm12, %ymm12
    vpaddd  %ymm5, %ymm11, %ymm5
    vpxor   %xmm11, %xmm11, %xmm11
    vpgatherdd %ymm12, (%rdi, %ymm5, 4), %ymm11
    vpaddd  %ymm10, %ymm15, %ymm15
    vmovdqu %ymm11, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_1162
    cmpl    -72(%rsp), %r8d
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm15
    jl      .LBB0_1164
    jmp     .LBB0_1173
.p2align 4, 0x90
.LBB0_1172:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_1173
.LBB0_1164:  // Parent Loop BB0_1161 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %edx, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm12, %xmm5, %xmm5
    vaddps  %xmm5, %xmm15, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r8d, %xmm13, %xmm11
    vpaddd  %xmm5, %xmm11, %xmm14
    vpextrd $1, %xmm14, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1166
    movl    %eax, %esi
.LBB0_1166:
    vpmovsxdq %xmm14, %xmm5
    vmovmskpd %xmm5, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_1167
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1169
.LBB0_1170:
    testb   $1, %r13b
    jne     .LBB0_1172
    jmp     .LBB0_1171
.p2align 4, 0x90
.LBB0_1167:
    movl    %esi, %edx
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1170
.LBB0_1169:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_1172
.LBB0_1171:
    movl    %ecx, %ebp
    jmp     .LBB0_1172
.LBB0_666:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    vmovaps %xmm0, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vmovdqa .LCPI0_6(%rip), %ymm6
    vbroadcastss .LCPI0_7(%rip), %ymm7
    vbroadcastss .LCPI0_1(%rip), %ymm8
    vbroadcastss .LCPI0_2(%rip), %ymm9
    vpxor   %xmm10, %xmm10, %xmm10
    vpbroadcastd .LCPI0_3(%rip), %ymm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_667
.p2align 4, 0x90
.LBB0_679:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_667:
                                        // Child Loop BB0_668 Depth 2
                                        // Child Loop BB0_670 Depth 2
    vmovd   %r14d, %xmm15
    vpbroadcastd %xmm15, %ymm5
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm12
.p2align 4, 0x90
.LBB0_668:  // Parent Loop BB0_667 Depth=1
    movq    %r8, %rbp
    vmovups (%r15, %r8, 4), %ymm13
    vandps  %ymm7, %ymm13, %ymm14
    vcvtdq2ps %ymm14, %ymm14
    vdivps  %ymm8, %ymm14, %ymm14
    vpshufb %ymm6, %ymm13, %ymm13
    vcvtdq2ps %ymm13, %ymm13
    vdivps  %ymm8, %ymm13, %ymm13
    movq    %r13, %r11
    vaddps  %ymm9, %ymm13, %ymm13
    vaddps  %ymm9, %ymm14, %ymm14
    vmulps  %ymm1, %ymm13, %ymm13
    vmulps  %ymm1, %ymm14, %ymm14
    vcvttps2dq %ymm14, %ymm14
    vpaddd  %ymm5, %ymm14, %ymm14
    vcvttps2dq %ymm13, %ymm13
    vpaddd  %ymm12, %ymm13, %ymm13
    vpmaxsd %ymm10, %ymm13, %ymm13
    vpmaxsd %ymm10, %ymm14, %ymm14
    vpminsd %ymm2, %ymm13, %ymm13
    vpminsd %ymm3, %ymm14, %ymm14
    vpmulld %ymm4, %ymm14, %ymm14
    vxorps  %xmm0, %xmm0, %xmm0
    vpaddd  %ymm13, %ymm14, %ymm13
    vpcmpeqd %ymm14, %ymm14, %ymm14
    vpgatherdd %ymm14, (%rdi, %ymm13, 4), %ymm0
    vpaddd  %ymm11, %ymm12, %ymm12
    vmovdqu %ymm0, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_668
    cmpl    -72(%rsp), %r8d
    vmovaps -40(%rsp), %xmm12
    vpmovzxbd .LCPI0_11(%rip), %xmm13
    vbroadcastss .LCPI0_1(%rip), %xmm14
    jl      .LBB0_670
    jmp     .LBB0_679
.p2align 4, 0x90
.LBB0_678:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_679
.LBB0_670:  // Parent Loop BB0_667 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    vmovd   %ecx, %xmm0
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm0, %xmm0
    vpand   %xmm0, %xmm13, %xmm0
    vcvtdq2ps %xmm0, %xmm0
    vdivps  %xmm14, %xmm0, %xmm0
    vbroadcastss .LCPI0_2(%rip), %xmm5
    vaddps  %xmm5, %xmm0, %xmm0
    vmulps  %xmm0, %xmm12, %xmm0
    vcvttps2dq %xmm0, %xmm0
    vpinsrd $1, %r8d, %xmm15, %xmm5
    vpaddd  %xmm0, %xmm5, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_672
    movl    %eax, %esi
.LBB0_672:
    vpmovsxdq %xmm5, %xmm0
    vmovmskpd %xmm0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_673
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_675
.LBB0_676:
    testb   $1, %r13b
    jne     .LBB0_678
    jmp     .LBB0_677
.p2align 4, 0x90
.LBB0_673:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_676
.LBB0_675:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_678
.LBB0_677:
    movl    %ecx, %ebp
    jmp     .LBB0_678
.LBB0_170:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    vmovaps %xmm0, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_7(%rip), %ymm5
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm8
    vmovdqa .LCPI0_6(%rip), %ymm9
    vpxor   %xmm10, %xmm10, %xmm10
    vpbroadcastd .LCPI0_3(%rip), %ymm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_171
.p2align 4, 0x90
.LBB0_183:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_171:
                                        // Child Loop BB0_172 Depth 2
                                        // Child Loop BB0_174 Depth 2
    vmovd   %r14d, %xmm15
    vpbroadcastd %xmm15, %ymm7
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm12
.p2align 4, 0x90
.LBB0_172:  // Parent Loop BB0_171 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm13
    vpshufb %ymm9, %ymm13, %ymm14
    vcvtdq2ps %ymm14, %ymm14
    vdivps  %ymm6, %ymm14, %ymm14
    vpand   %ymm5, %ymm13, %ymm13
    vcvtdq2ps %ymm13, %ymm13
    vdivps  %ymm6, %ymm13, %ymm13
    movq    %r13, %r11
    vaddps  %ymm8, %ymm13, %ymm13
    vaddps  %ymm8, %ymm14, %ymm14
    vmulps  %ymm1, %ymm13, %ymm13
    vmulps  %ymm1, %ymm14, %ymm14
    vcvttps2dq %ymm14, %ymm14
    vpaddd  %ymm7, %ymm14, %ymm14
    vcvttps2dq %ymm13, %ymm13
    vpaddd  %ymm12, %ymm13, %ymm13
    vpmaxsd %ymm10, %ymm13, %ymm13
    vpmaxsd %ymm10, %ymm14, %ymm14
    vpminsd %ymm2, %ymm13, %ymm13
    vpminsd %ymm3, %ymm14, %ymm14
    vpmulld %ymm4, %ymm14, %ymm14
    vxorps  %xmm0, %xmm0, %xmm0
    vpaddd  %ymm13, %ymm14, %ymm13
    vpcmpeqd %ymm14, %ymm14, %ymm14
    vpgatherdd %ymm14, (%rdi, %ymm13, 4), %ymm0
    vpaddd  %ymm11, %ymm12, %ymm12
    vmovdqu %ymm0, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_172
    cmpl    -72(%rsp), %r8d
    vmovaps -40(%rsp), %xmm12
    vpmovzxbd .LCPI0_11(%rip), %xmm13
    vbroadcastss .LCPI0_1(%rip), %xmm14
    jl      .LBB0_174
    jmp     .LBB0_183
.p2align 4, 0x90
.LBB0_182:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_183
.LBB0_174:  // Parent Loop BB0_171 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm0
    vpinsrd $1, %ecx, %xmm0, %xmm0
    vpand   %xmm0, %xmm13, %xmm0
    vcvtdq2ps %xmm0, %xmm0
    vdivps  %xmm14, %xmm0, %xmm0
    vbroadcastss .LCPI0_2(%rip), %xmm7
    vaddps  %xmm7, %xmm0, %xmm0
    vmulps  %xmm0, %xmm12, %xmm0
    vcvttps2dq %xmm0, %xmm0
    vpinsrd $1, %r8d, %xmm15, %xmm7
    vpaddd  %xmm0, %xmm7, %xmm7
    vpextrd $1, %xmm7, %esi
    cmpl    %eax, %esi
    jl      .LBB0_176
    movl    %eax, %esi
.LBB0_176:
    vpmovsxdq %xmm7, %xmm0
    vmovmskpd %xmm0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_177
    vmovd   %xmm7, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_179
.LBB0_180:
    testb   $1, %r13b
    jne     .LBB0_182
    jmp     .LBB0_181
.p2align 4, 0x90
.LBB0_177:
    movl    %esi, %edx
    vmovd   %xmm7, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_180
.LBB0_179:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_182
.LBB0_181:
    movl    %ecx, %ebp
    jmp     .LBB0_182
.LBB0_748:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    vmovaps %xmm0, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm6
    vmovdqa .LCPI0_5(%rip), %ymm7
    vbroadcastss .LCPI0_7(%rip), %ymm8
    vbroadcastss .LCPI0_1(%rip), %ymm9
    vbroadcastss .LCPI0_2(%rip), %ymm10
    vpxor   %xmm11, %xmm11, %xmm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_749
.p2align 4, 0x90
.LBB0_761:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_749:
                                        // Child Loop BB0_750 Depth 2
                                        // Child Loop BB0_752 Depth 2
    vmovd   %r14d, %xmm15
    vpbroadcastd %xmm15, %ymm5
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm12
.p2align 4, 0x90
.LBB0_750:  // Parent Loop BB0_749 Depth=1
    movq    %r8, %rbp
    vmovups (%r15, %r8, 4), %ymm13
    vandps  %ymm13, %ymm8, %ymm14
    vcvtdq2ps %ymm14, %ymm14
    vdivps  %ymm9, %ymm14, %ymm14
    vpshufb %ymm7, %ymm13, %ymm13
    vcvtdq2ps %ymm13, %ymm13
    vdivps  %ymm9, %ymm13, %ymm13
    movq    %r13, %r11
    vaddps  %ymm10, %ymm13, %ymm13
    vaddps  %ymm10, %ymm14, %ymm14
    vmulps  %ymm1, %ymm13, %ymm13
    vmulps  %ymm1, %ymm14, %ymm14
    vcvttps2dq %ymm14, %ymm14
    vpaddd  %ymm5, %ymm14, %ymm14
    vcvttps2dq %ymm13, %ymm13
    vpaddd  %ymm12, %ymm13, %ymm13
    vpmaxsd %ymm11, %ymm13, %ymm13
    vpmaxsd %ymm11, %ymm14, %ymm14
    vpminsd %ymm2, %ymm13, %ymm13
    vpminsd %ymm3, %ymm14, %ymm14
    vpmulld %ymm4, %ymm14, %ymm14
    vpcmpeqd %ymm0, %ymm0, %ymm0
    vpaddd  %ymm13, %ymm14, %ymm13
    vpxor   %xmm14, %xmm14, %xmm14
    vpgatherdd %ymm0, (%rdi, %ymm13, 4), %ymm14
    vpaddd  %ymm6, %ymm12, %ymm12
    vmovdqu %ymm14, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_750
    cmpl    -72(%rsp), %r8d
    vmovaps -40(%rsp), %xmm12
    vpmovzxbd .LCPI0_11(%rip), %xmm13
    vbroadcastss .LCPI0_1(%rip), %xmm14
    jl      .LBB0_752
    jmp     .LBB0_761
.p2align 4, 0x90
.LBB0_760:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_761
.LBB0_752:  // Parent Loop BB0_749 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    vmovd   %ecx, %xmm0
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm0, %xmm0
    vpand   %xmm0, %xmm13, %xmm0
    vcvtdq2ps %xmm0, %xmm0
    vdivps  %xmm14, %xmm0, %xmm0
    vbroadcastss .LCPI0_2(%rip), %xmm5
    vaddps  %xmm5, %xmm0, %xmm0
    vmulps  %xmm0, %xmm12, %xmm0
    vcvttps2dq %xmm0, %xmm0
    vpinsrd $1, %r8d, %xmm15, %xmm5
    vpaddd  %xmm0, %xmm5, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_754
    movl    %eax, %esi
.LBB0_754:
    vpmovsxdq %xmm5, %xmm0
    vmovmskpd %xmm0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_755
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_757
.LBB0_758:
    testb   $1, %r13b
    jne     .LBB0_760
    jmp     .LBB0_759
.p2align 4, 0x90
.LBB0_755:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_758
.LBB0_757:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_760
.LBB0_759:
    movl    %ecx, %ebp
    jmp     .LBB0_760
.LBB0_500:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    vmovaps %xmm0, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm5
    vpbroadcastd .LCPI0_7(%rip), %ymm6
    vbroadcastss .LCPI0_1(%rip), %ymm7
    vbroadcastss .LCPI0_2(%rip), %ymm8
    vmovdqa .LCPI0_5(%rip), %ymm10
    vpxor   %xmm11, %xmm11, %xmm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_501
.p2align 4, 0x90
.LBB0_513:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_501:
                                        // Child Loop BB0_502 Depth 2
                                        // Child Loop BB0_504 Depth 2
    vmovd   %r14d, %xmm15
    vpbroadcastd %xmm15, %ymm9
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm12
.p2align 4, 0x90
.LBB0_502:  // Parent Loop BB0_501 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm13
    vpshufb %ymm10, %ymm13, %ymm14
    vcvtdq2ps %ymm14, %ymm14
    vdivps  %ymm7, %ymm14, %ymm14
    vpand   %ymm6, %ymm13, %ymm13
    vcvtdq2ps %ymm13, %ymm13
    vdivps  %ymm7, %ymm13, %ymm13
    movq    %r13, %r11
    vaddps  %ymm8, %ymm13, %ymm13
    vaddps  %ymm8, %ymm14, %ymm14
    vmulps  %ymm1, %ymm13, %ymm13
    vmulps  %ymm1, %ymm14, %ymm14
    vcvttps2dq %ymm14, %ymm14
    vpaddd  %ymm9, %ymm14, %ymm14
    vcvttps2dq %ymm13, %ymm13
    vpaddd  %ymm12, %ymm13, %ymm13
    vpmaxsd %ymm11, %ymm13, %ymm13
    vpmaxsd %ymm11, %ymm14, %ymm14
    vpminsd %ymm2, %ymm13, %ymm13
    vpminsd %ymm3, %ymm14, %ymm14
    vpmulld %ymm4, %ymm14, %ymm14
    vxorps  %xmm0, %xmm0, %xmm0
    vpaddd  %ymm13, %ymm14, %ymm13
    vpcmpeqd %ymm14, %ymm14, %ymm14
    vpgatherdd %ymm14, (%rdi, %ymm13, 4), %ymm0
    vpaddd  %ymm5, %ymm12, %ymm12
    vmovdqu %ymm0, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_502
    cmpl    -72(%rsp), %r8d
    vmovaps -40(%rsp), %xmm12
    vpmovzxbd .LCPI0_11(%rip), %xmm13
    vbroadcastss .LCPI0_1(%rip), %xmm14
    jl      .LBB0_504
    jmp     .LBB0_513
.p2align 4, 0x90
.LBB0_512:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_513
.LBB0_504:  // Parent Loop BB0_501 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm0
    vpinsrd $1, %ecx, %xmm0, %xmm0
    vpand   %xmm0, %xmm13, %xmm0
    vcvtdq2ps %xmm0, %xmm0
    vdivps  %xmm14, %xmm0, %xmm0
    vbroadcastss .LCPI0_2(%rip), %xmm9
    vaddps  %xmm0, %xmm9, %xmm0
    vmulps  %xmm0, %xmm12, %xmm0
    vcvttps2dq %xmm0, %xmm0
    vpinsrd $1, %r8d, %xmm15, %xmm9
    vpaddd  %xmm0, %xmm9, %xmm9
    vpextrd $1, %xmm9, %esi
    cmpl    %eax, %esi
    jl      .LBB0_506
    movl    %eax, %esi
.LBB0_506:
    vpmovsxdq %xmm9, %xmm0
    vmovmskpd %xmm0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_507
    vmovd   %xmm9, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_509
.LBB0_510:
    testb   $1, %r13b
    jne     .LBB0_512
    jmp     .LBB0_511
.p2align 4, 0x90
.LBB0_507:
    movl    %esi, %edx
    vmovd   %xmm9, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_510
.LBB0_509:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_512
.LBB0_511:
    movl    %ecx, %ebp
    jmp     .LBB0_512
.LBB0_1242:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm5
    vbroadcastss .LCPI0_2(%rip), %ymm6
    vpmovsxbd .LCPI0_14(%rip), %ymm7
    vpxor   %xmm8, %xmm8, %xmm8
    vpbroadcastd .LCPI0_3(%rip), %ymm9
    vmovss  .LCPI0_1(%rip), %xmm10
    vmovss  .LCPI0_2(%rip), %xmm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_1243
.p2align 4, 0x90
.LBB0_1255:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -40(%rsp), %r14
    je      .LBB0_1322
.LBB0_1243:
                                        // Child Loop BB0_1244 Depth 2
                                        // Child Loop BB0_1246 Depth 2
    vmovd   %r14d, %xmm0
    vpbroadcastd %xmm0, %ymm12
    movq    %rbx, %rdx
    xorl    %ebp, %ebp
    vmovdqa %ymm7, %ymm13
.p2align 4, 0x90
.LBB0_1244:  // Parent Loop BB0_1243 Depth=1
    movq    %rbp, %rcx
    vmovdqu (%r15, %rbp, 4), %ymm0
    vpsrld  $24, %ymm0, %ymm0
    vcvtdq2ps %ymm0, %ymm0
    vdivps  %ymm5, %ymm0, %ymm0
    movq    %rdx, %r13
    vaddps  %ymm6, %ymm0, %ymm0
    vmulps  %ymm0, %ymm1, %ymm0
    vcvttps2dq %ymm0, %ymm0
    vpaddd  %ymm0, %ymm13, %ymm14
    vpmaxsd %ymm8, %ymm14, %ymm14
    vpaddd  %ymm0, %ymm12, %ymm0
    vpmaxsd %ymm8, %ymm0, %ymm0
    vpminsd %ymm2, %ymm14, %ymm14
    vpminsd %ymm3, %ymm0, %ymm0
    vpmulld %ymm4, %ymm0, %ymm0
    vpxor   %xmm15, %xmm15, %xmm15
    vpaddd  %ymm0, %ymm14, %ymm0
    vpcmpeqd %ymm14, %ymm14, %ymm14
    vpgatherdd %ymm14, (%rdi, %ymm0, 4), %ymm15
    vpaddd  %ymm9, %ymm13, %ymm13
    vmovdqu %ymm15, (%r12, %rbp, 4)
    addq    $8, %rbp
    addq    $16, %rcx
    addq    $32, %rdx
    cmpq    %r10, %rcx
    jbe     .LBB0_1244
    cmpl    -72(%rsp), %ebp
    vmovaps -24(%rsp), %xmm12
    jl      .LBB0_1246
    jmp     .LBB0_1255
.p2align 4, 0x90
.LBB0_1254:
    imull   -72(%rsp), %r11d
    addl    %edx, %r11d
    movslq  %r11d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_1255
.LBB0_1246:  // Parent Loop BB0_1243 Depth=1
    movq    -64(%rsp), %rcx
    movzbl  3(%rcx, %r13), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm10, %xmm0, %xmm0
    vaddss  %xmm0, %xmm11, %xmm0
    vmulss  %xmm0, %xmm12, %xmm0
    vcvttss2si %xmm0, %r8d
    leal    (%r8, %rbp), %esi
    movl    %esi, %ecx
    cmpl    %eax, %esi
    jge     .LBB0_1247
    xorl    %r11d, %r11d
    movl    $0, %edx
    testl   %esi, %esi
    jns     .LBB0_1249
.LBB0_1250:
    addl    %r14d, %r8d
    movl    %r8d, %ecx
    cmpl    %r9d, %r8d
    jge     .LBB0_1251
.LBB0_1252:
    testl   %r8d, %r8d
    js      .LBB0_1254
    jmp     .LBB0_1253
.p2align 4, 0x90
.LBB0_1247:
    movl    %eax, %ecx
    xorl    %r11d, %r11d
    movl    $0, %edx
    testl   %esi, %esi
    js      .LBB0_1250
.LBB0_1249:
    movl    %ecx, %edx
    addl    %r14d, %r8d
    movl    %r8d, %ecx
    cmpl    %r9d, %r8d
    jl      .LBB0_1252
.LBB0_1251:
    movl    %r9d, %ecx
    testl   %r8d, %r8d
    js      .LBB0_1254
.LBB0_1253:
    movl    %ecx, %r11d
    jmp     .LBB0_1254
.LBB0_996:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -40(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm7
    vmovdqa .LCPI0_6(%rip), %ymm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %ymm10
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_997
.p2align 4, 0x90
.LBB0_1009:
    incq    %r14
    movq    -40(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_997:
                                        // Child Loop BB0_998 Depth 2
                                        // Child Loop BB0_1000 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm14
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm15
.p2align 4, 0x90
.LBB0_998:  // Parent Loop BB0_997 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm5
    vpsrld  $24, %ymm5, %ymm11
    vcvtdq2ps %ymm11, %ymm11
    vdivps  %ymm6, %ymm11, %ymm11
    vpshufb %ymm8, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vdivps  %ymm6, %ymm5, %ymm5
    movq    %r13, %r11
    vaddps  %ymm7, %ymm5, %ymm5
    vaddps  %ymm7, %ymm11, %ymm11
    vmulps  %ymm5, %ymm1, %ymm5
    vmulps  %ymm1, %ymm11, %ymm11
    vcvttps2dq %ymm11, %ymm11
    vpaddd  %ymm14, %ymm11, %ymm11
    vcvttps2dq %ymm5, %ymm5
    vpaddd  %ymm5, %ymm15, %ymm5
    vpmaxsd %ymm9, %ymm5, %ymm5
    vpmaxsd %ymm9, %ymm11, %ymm11
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm11, %ymm11
    vpmulld %ymm4, %ymm11, %ymm11
    vpcmpeqd %ymm12, %ymm12, %ymm12
    vpaddd  %ymm5, %ymm11, %ymm5
    vpxor   %xmm11, %xmm11, %xmm11
    vpgatherdd %ymm12, (%rdi, %ymm5, 4), %ymm11
    vpaddd  %ymm10, %ymm15, %ymm15
    vmovdqu %ymm11, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_998
    cmpl    -72(%rsp), %r8d
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm15
    jl      .LBB0_1000
    jmp     .LBB0_1009
.p2align 4, 0x90
.LBB0_1008:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_1009
.LBB0_1000:  // Parent Loop BB0_997 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %edx, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm12, %xmm5, %xmm5
    vaddps  %xmm5, %xmm15, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r8d, %xmm13, %xmm11
    vpaddd  %xmm5, %xmm11, %xmm14
    vpextrd $1, %xmm14, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1002
    movl    %eax, %esi
.LBB0_1002:
    vpmovsxdq %xmm14, %xmm5
    vmovmskpd %xmm5, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_1003
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1005
.LBB0_1006:
    testb   $1, %r13b
    jne     .LBB0_1008
    jmp     .LBB0_1007
.p2align 4, 0x90
.LBB0_1003:
    movl    %esi, %edx
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1006
.LBB0_1005:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_1008
.LBB0_1007:
    movl    %ecx, %ebp
    jmp     .LBB0_1008
.LBB0_252:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -40(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm7
    vmovdqa .LCPI0_6(%rip), %ymm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %ymm10
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_253
.p2align 4, 0x90
.LBB0_265:
    incq    %r14
    movq    -40(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_253:
                                        // Child Loop BB0_254 Depth 2
                                        // Child Loop BB0_256 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm14
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm15
.p2align 4, 0x90
.LBB0_254:  // Parent Loop BB0_253 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm5
    vpshufb %ymm8, %ymm5, %ymm11
    vcvtdq2ps %ymm11, %ymm11
    vdivps  %ymm6, %ymm11, %ymm11
    vpsrld  $24, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vdivps  %ymm6, %ymm5, %ymm5
    movq    %r13, %r11
    vaddps  %ymm7, %ymm5, %ymm5
    vaddps  %ymm7, %ymm11, %ymm11
    vmulps  %ymm5, %ymm1, %ymm5
    vmulps  %ymm1, %ymm11, %ymm11
    vcvttps2dq %ymm11, %ymm11
    vpaddd  %ymm14, %ymm11, %ymm11
    vcvttps2dq %ymm5, %ymm5
    vpaddd  %ymm5, %ymm15, %ymm5
    vpmaxsd %ymm9, %ymm5, %ymm5
    vpmaxsd %ymm9, %ymm11, %ymm11
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm11, %ymm11
    vpmulld %ymm4, %ymm11, %ymm11
    vpxor   %xmm12, %xmm12, %xmm12
    vpaddd  %ymm5, %ymm11, %ymm5
    vpcmpeqd %ymm11, %ymm11, %ymm11
    vpgatherdd %ymm11, (%rdi, %ymm5, 4), %ymm12
    vpaddd  %ymm10, %ymm15, %ymm15
    vmovdqu %ymm12, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_254
    cmpl    -72(%rsp), %r8d
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm15
    jl      .LBB0_256
    jmp     .LBB0_265
.p2align 4, 0x90
.LBB0_264:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_265
.LBB0_256:  // Parent Loop BB0_253 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %edx, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm12, %xmm5, %xmm5
    vaddps  %xmm5, %xmm15, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r8d, %xmm13, %xmm11
    vpaddd  %xmm5, %xmm11, %xmm14
    vpextrd $1, %xmm14, %esi
    cmpl    %eax, %esi
    jl      .LBB0_258
    movl    %eax, %esi
.LBB0_258:
    vpmovsxdq %xmm14, %xmm5
    vmovmskpd %xmm5, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_259
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_261
.LBB0_262:
    testb   $1, %r13b
    jne     .LBB0_264
    jmp     .LBB0_263
.p2align 4, 0x90
.LBB0_259:
    movl    %esi, %edx
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_262
.LBB0_261:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_264
.LBB0_263:
    movl    %ecx, %ebp
    jmp     .LBB0_264
.LBB0_1078:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -40(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm6
    vbroadcastss .LCPI0_1(%rip), %ymm7
    vmovdqa .LCPI0_5(%rip), %ymm8
    vbroadcastss .LCPI0_2(%rip), %ymm9
    vpxor   %xmm10, %xmm10, %xmm10
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_1079
.p2align 4, 0x90
.LBB0_1091:
    incq    %r14
    movq    -40(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_1079:
                                        // Child Loop BB0_1080 Depth 2
                                        // Child Loop BB0_1082 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm14
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm15
.p2align 4, 0x90
.LBB0_1080:  // Parent Loop BB0_1079 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm5
    vpsrld  $24, %ymm5, %ymm11
    vcvtdq2ps %ymm11, %ymm11
    vdivps  %ymm7, %ymm11, %ymm11
    vpshufb %ymm8, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vdivps  %ymm7, %ymm5, %ymm5
    movq    %r13, %r11
    vaddps  %ymm5, %ymm9, %ymm5
    vaddps  %ymm9, %ymm11, %ymm11
    vmulps  %ymm5, %ymm1, %ymm5
    vmulps  %ymm1, %ymm11, %ymm11
    vcvttps2dq %ymm11, %ymm11
    vpaddd  %ymm14, %ymm11, %ymm11
    vcvttps2dq %ymm5, %ymm5
    vpaddd  %ymm5, %ymm15, %ymm5
    vpmaxsd %ymm10, %ymm5, %ymm5
    vpmaxsd %ymm10, %ymm11, %ymm11
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm11, %ymm11
    vpmulld %ymm4, %ymm11, %ymm11
    vpxor   %xmm12, %xmm12, %xmm12
    vpaddd  %ymm5, %ymm11, %ymm5
    vpcmpeqd %ymm11, %ymm11, %ymm11
    vpgatherdd %ymm11, (%rdi, %ymm5, 4), %ymm12
    vpaddd  %ymm6, %ymm15, %ymm15
    vmovdqu %ymm12, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_1080
    cmpl    -72(%rsp), %r8d
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm15
    jl      .LBB0_1082
    jmp     .LBB0_1091
.p2align 4, 0x90
.LBB0_1090:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_1091
.LBB0_1082:  // Parent Loop BB0_1079 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm5
    vpinsrd $1, %edx, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm12, %xmm5, %xmm5
    vaddps  %xmm5, %xmm15, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r8d, %xmm13, %xmm11
    vpaddd  %xmm5, %xmm11, %xmm14
    vpextrd $1, %xmm14, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1084
    movl    %eax, %esi
.LBB0_1084:
    vpmovsxdq %xmm14, %xmm5
    vmovmskpd %xmm5, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_1085
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1087
.LBB0_1088:
    testb   $1, %r13b
    jne     .LBB0_1090
    jmp     .LBB0_1089
.p2align 4, 0x90
.LBB0_1085:
    movl    %esi, %edx
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1088
.LBB0_1087:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_1090
.LBB0_1089:
    movl    %ecx, %ebp
    jmp     .LBB0_1090
.LBB0_582:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -40(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm6
    vbroadcastss .LCPI0_1(%rip), %ymm7
    vbroadcastss .LCPI0_2(%rip), %ymm8
    vmovdqa .LCPI0_5(%rip), %ymm9
    vpxor   %xmm10, %xmm10, %xmm10
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_583
.p2align 4, 0x90
.LBB0_595:
    incq    %r14
    movq    -40(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_583:
                                        // Child Loop BB0_584 Depth 2
                                        // Child Loop BB0_586 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm14
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm15
.p2align 4, 0x90
.LBB0_584:  // Parent Loop BB0_583 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm5
    vpshufb %ymm9, %ymm5, %ymm11
    vcvtdq2ps %ymm11, %ymm11
    vdivps  %ymm7, %ymm11, %ymm11
    vpsrld  $24, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vdivps  %ymm7, %ymm5, %ymm5
    movq    %r13, %r11
    vaddps  %ymm5, %ymm8, %ymm5
    vaddps  %ymm8, %ymm11, %ymm11
    vmulps  %ymm5, %ymm1, %ymm5
    vmulps  %ymm1, %ymm11, %ymm11
    vcvttps2dq %ymm11, %ymm11
    vpaddd  %ymm14, %ymm11, %ymm11
    vcvttps2dq %ymm5, %ymm5
    vpaddd  %ymm5, %ymm15, %ymm5
    vpmaxsd %ymm10, %ymm5, %ymm5
    vpmaxsd %ymm10, %ymm11, %ymm11
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm11, %ymm11
    vpmulld %ymm4, %ymm11, %ymm11
    vpxor   %xmm12, %xmm12, %xmm12
    vpaddd  %ymm5, %ymm11, %ymm5
    vpcmpeqd %ymm11, %ymm11, %ymm11
    vpgatherdd %ymm11, (%rdi, %ymm5, 4), %ymm12
    vpaddd  %ymm6, %ymm15, %ymm15
    vmovdqu %ymm12, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_584
    cmpl    -72(%rsp), %r8d
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm15
    jl      .LBB0_586
    jmp     .LBB0_595
.p2align 4, 0x90
.LBB0_594:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_595
.LBB0_586:  // Parent Loop BB0_583 Depth=1
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm12, %xmm5, %xmm5
    vaddps  %xmm5, %xmm15, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r8d, %xmm13, %xmm11
    vpaddd  %xmm5, %xmm11, %xmm14
    vpextrd $1, %xmm14, %esi
    cmpl    %eax, %esi
    jl      .LBB0_588
    movl    %eax, %esi
.LBB0_588:
    vpmovsxdq %xmm14, %xmm5
    vmovmskpd %xmm5, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_589
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_591
.LBB0_592:
    testb   $1, %r13b
    jne     .LBB0_594
    jmp     .LBB0_593
.p2align 4, 0x90
.LBB0_589:
    movl    %esi, %edx
    vmovd   %xmm14, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_592
.LBB0_591:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_594
.LBB0_593:
    movl    %ecx, %ebp
    jmp     .LBB0_594
.LBB0_6:
    vbroadcastss %xmm5, %ymm1
    vmovd   %edx, %xmm2
    vpbroadcastd %xmm2, %ymm2
    vmovd   %r9d, %xmm3
    vpbroadcastd %xmm3, %ymm3
    vmovd   %eax, %xmm4
    vpbroadcastd %xmm4, %ymm4
    movl    %eax, %r10d
    movl    %r8d, %eax
    movq    %rax, -40(%rsp)
    leaq    (, %r10, 4), %rax
    movq    %rax, -48(%rsp)
    movl    $32, %ecx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %ymm6
    vbroadcastss .LCPI0_2(%rip), %ymm7
    vmovdqa .LCPI0_6(%rip), %ymm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %ymm10
    vmovss  .LCPI0_1(%rip), %xmm0
    vmovss  .LCPI0_2(%rip), %xmm12
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_7
.p2align 4, 0x90
.LBB0_19:
    incq    %r14
    movq    -48(%rsp), %rax
    addq    %rax, %r12
    addq    %rax, %r15
    addq    %rax, %rcx
    cmpq    -40(%rsp), %r14
    je      .LBB0_1322
.LBB0_7:
                                        // Child Loop BB0_8 Depth 2
                                        // Child Loop BB0_10 Depth 2
    vmovd   %r14d, %xmm13
    vpbroadcastd %xmm13, %ymm13
    movq    %rcx, %r8
    xorl    %ebp, %ebp
    vpmovsxbd .LCPI0_14(%rip), %ymm14
.p2align 4, 0x90
.LBB0_8:  // Parent Loop BB0_7 Depth=1
    movq    %rbp, %rax
    vmovdqu (%r15, %rbp, 4), %ymm15
    vpshufb %ymm8, %ymm15, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vdivps  %ymm6, %ymm15, %ymm15
    movq    %r8, %r13
    vaddps  %ymm7, %ymm15, %ymm15
    vmulps  %ymm1, %ymm15, %ymm15
    vcvttps2dq %ymm15, %ymm15
    vpaddd  %ymm14, %ymm15, %ymm5
    vpmaxsd %ymm9, %ymm5, %ymm5
    vpaddd  %ymm13, %ymm15, %ymm15
    vpmaxsd %ymm9, %ymm15, %ymm15
    vpminsd %ymm2, %ymm5, %ymm5
    vpminsd %ymm3, %ymm15, %ymm15
    vpmulld %ymm4, %ymm15, %ymm15
    vpxor   %xmm11, %xmm11, %xmm11
    vpaddd  %ymm5, %ymm15, %ymm5
    vpcmpeqd %ymm15, %ymm15, %ymm15
    vpgatherdd %ymm15, (%rdi, %ymm5, 4), %ymm11
    vpaddd  %ymm10, %ymm14, %ymm14
    vmovdqu %ymm11, (%r12, %rbp, 4)
    addq    $8, %rbp
    addq    $16, %rax
    addq    $32, %r8
    cmpq    %r10, %rax
    jbe     .LBB0_8
    cmpl    -72(%rsp), %ebp
    vmovaps -24(%rsp), %xmm11
    jl      .LBB0_10
    jmp     .LBB0_19
.p2align 4, 0x90
.LBB0_18:
    imull   -72(%rsp), %r11d
    addl    %ebx, %r11d
    movslq  %r11d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rsi
    movl    %eax, (%rsi, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_19
.LBB0_10:  // Parent Loop BB0_7 Depth=1
    movq    -64(%rsp), %rax
    movzbl  2(%rax, %r13), %eax
    vcvtsi2ss %eax, %xmm1, %xmm5
    vdivss  %xmm0, %xmm5, %xmm5
    vaddss  %xmm5, %xmm12, %xmm5
    vmulss  %xmm5, %xmm11, %xmm5
    vcvttss2si %xmm5, %r8d
    leal    (%r8, %rbp), %esi
    movl    %esi, %eax
    cmpl    %edx, %esi
    jge     .LBB0_11
    xorl    %r11d, %r11d
    movl    $0, %ebx
    testl   %esi, %esi
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
    movl    %edx, %eax
    xorl    %r11d, %r11d
    movl    $0, %ebx
    testl   %esi, %esi
    js      .LBB0_14
.LBB0_13:
    movl    %eax, %ebx
    addl    %r14d, %r8d
    movl    %r8d, %eax
    cmpl    %r9d, %r8d
    jl      .LBB0_16
.LBB0_15:
    movl    %r9d, %eax
    testl   %r8d, %r8d
    js      .LBB0_18
.LBB0_17:
    movl    %eax, %r11d
    jmp     .LBB0_18
.LBB0_336:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    vmovaps %xmm0, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm6
    vmovdqa .LCPI0_6(%rip), %ymm7
    vbroadcastss .LCPI0_1(%rip), %ymm8
    vbroadcastss .LCPI0_2(%rip), %ymm9
    vmovdqa .LCPI0_5(%rip), %ymm10
    vpxor   %xmm11, %xmm11, %xmm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_337
.p2align 4, 0x90
.LBB0_349:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_337:
                                        // Child Loop BB0_338 Depth 2
                                        // Child Loop BB0_340 Depth 2
    vmovd   %r14d, %xmm5
    vpbroadcastd %xmm5, %ymm12
    movq    %rbx, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm13
.p2align 4, 0x90
.LBB0_338:  // Parent Loop BB0_337 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm14
    vpshufb %ymm10, %ymm14, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vdivps  %ymm8, %ymm15, %ymm15
    vpshufb %ymm7, %ymm14, %ymm14
    vcvtdq2ps %ymm14, %ymm14
    vdivps  %ymm8, %ymm14, %ymm14
    movq    %r13, %r11
    vaddps  %ymm9, %ymm14, %ymm14
    vaddps  %ymm9, %ymm15, %ymm15
    vmulps  %ymm1, %ymm14, %ymm14
    vmulps  %ymm1, %ymm15, %ymm15
    vcvttps2dq %ymm15, %ymm15
    vpaddd  %ymm12, %ymm15, %ymm15
    vcvttps2dq %ymm14, %ymm14
    vpaddd  %ymm13, %ymm14, %ymm14
    vpmaxsd %ymm11, %ymm14, %ymm14
    vpmaxsd %ymm11, %ymm15, %ymm15
    vpminsd %ymm2, %ymm14, %ymm14
    vpminsd %ymm3, %ymm15, %ymm15
    vpmulld %ymm4, %ymm15, %ymm15
    vpcmpeqd %ymm0, %ymm0, %ymm0
    vpaddd  %ymm14, %ymm15, %ymm14
    vpxor   %xmm15, %xmm15, %xmm15
    vpgatherdd %ymm0, (%rdi, %ymm14, 4), %ymm15
    vpaddd  %ymm6, %ymm13, %ymm13
    vmovdqu %ymm15, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_338
    cmpl    -72(%rsp), %r8d
    vmovaps -40(%rsp), %xmm13
    vpmovsxbd .LCPI0_12(%rip), %xmm14
    vpmovzxbd .LCPI0_11(%rip), %xmm15
    jl      .LBB0_340
    jmp     .LBB0_349
.p2align 4, 0x90
.LBB0_348:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_349
.LBB0_340:  // Parent Loop BB0_337 Depth=1
    movq    -64(%rsp), %rcx
    vpbroadcastd (%rcx, %r11), %xmm0
    vpsrlvd %xmm14, %xmm0, %xmm0
    vpand   %xmm0, %xmm15, %xmm0
    vcvtdq2ps %xmm0, %xmm0
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vdivps  %xmm12, %xmm0, %xmm0
    vbroadcastss .LCPI0_2(%rip), %xmm12
    vaddps  %xmm0, %xmm12, %xmm0
    vmulps  %xmm0, %xmm13, %xmm0
    vcvttps2dq %xmm0, %xmm0
    vpinsrd $1, %r8d, %xmm5, %xmm12
    vpaddd  %xmm0, %xmm12, %xmm12
    vpextrd $1, %xmm12, %esi
    cmpl    %eax, %esi
    jl      .LBB0_342
    movl    %eax, %esi
.LBB0_342:
    vpmovsxdq %xmm12, %xmm0
    vmovmskpd %xmm0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_343
    vmovd   %xmm12, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_345
.LBB0_346:
    testb   $1, %r13b
    jne     .LBB0_348
    jmp     .LBB0_347
.p2align 4, 0x90
.LBB0_343:
    movl    %esi, %edx
    vmovd   %xmm12, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_346
.LBB0_345:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_348
.LBB0_347:
    movl    %ecx, %ebp
    jmp     .LBB0_348
.LBB0_88:
    vbroadcastss %xmm5, %ymm1
    vmovd   %esi, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %eax, %r10d
    movl    %r8d, %eax
    movq    %rax, -24(%rsp)
    vbroadcastss %xmm5, %xmm0
    vmovaps %xmm0, -40(%rsp)
    leaq    (, %r10, 4), %rax
    movq    %rax, -48(%rsp)
    movl    $32, %eax
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm6
    vmovdqa .LCPI0_5(%rip), %ymm7
    vbroadcastss .LCPI0_1(%rip), %ymm8
    vbroadcastss .LCPI0_2(%rip), %ymm9
    vmovdqa .LCPI0_6(%rip), %ymm10
    vpxor   %xmm11, %xmm11, %xmm11
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_89
.p2align 4, 0x90
.LBB0_101:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rax
    cmpq    -24(%rsp), %r14
    je      .LBB0_1322
.LBB0_89:
                                        // Child Loop BB0_90 Depth 2
                                        // Child Loop BB0_92 Depth 2
    vmovd   %r14d, %xmm5
    vpbroadcastd %xmm5, %ymm12
    movq    %rax, %r13
    xorl    %r8d, %r8d
    vpmovsxbd .LCPI0_14(%rip), %ymm13
.p2align 4, 0x90
.LBB0_90:  // Parent Loop BB0_89 Depth=1
    movq    %r8, %rbp
    vmovdqu (%r15, %r8, 4), %ymm14
    vpshufb %ymm10, %ymm14, %ymm15
    vcvtdq2ps %ymm15, %ymm15
    vdivps  %ymm8, %ymm15, %ymm15
    vpshufb %ymm7, %ymm14, %ymm14
    vcvtdq2ps %ymm14, %ymm14
    vdivps  %ymm8, %ymm14, %ymm14
    movq    %r13, %r11
    vaddps  %ymm9, %ymm14, %ymm14
    vaddps  %ymm9, %ymm15, %ymm15
    vmulps  %ymm1, %ymm14, %ymm14
    vmulps  %ymm1, %ymm15, %ymm15
    vcvttps2dq %ymm15, %ymm15
    vpaddd  %ymm12, %ymm15, %ymm15
    vcvttps2dq %ymm14, %ymm14
    vpaddd  %ymm13, %ymm14, %ymm14
    vpmaxsd %ymm11, %ymm14, %ymm14
    vpmaxsd %ymm11, %ymm15, %ymm15
    vpminsd %ymm2, %ymm14, %ymm14
    vpminsd %ymm3, %ymm15, %ymm15
    vpmulld %ymm4, %ymm15, %ymm15
    vxorps  %xmm0, %xmm0, %xmm0
    vpaddd  %ymm14, %ymm15, %ymm14
    vpcmpeqd %ymm15, %ymm15, %ymm15
    vpgatherdd %ymm15, (%rdi, %ymm14, 4), %ymm0
    vpaddd  %ymm6, %ymm13, %ymm13
    vmovdqu %ymm0, (%r12, %r8, 4)
    addq    $8, %r8
    addq    $16, %rbp
    addq    $32, %r13
    cmpq    %r10, %rbp
    jbe     .LBB0_90
    cmpl    -72(%rsp), %r8d
    vmovaps -40(%rsp), %xmm13
    vpmovsxbd .LCPI0_13(%rip), %xmm14
    vpmovzxbd .LCPI0_11(%rip), %xmm15
    jl      .LBB0_92
    jmp     .LBB0_101
.p2align 4, 0x90
.LBB0_100:
    imull   -72(%rsp), %ebp
    addl    %edx, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
    incq    %r8
    addq    $4, %r11
    cmpq    %r10, %r8
    jae     .LBB0_101
.LBB0_92:  // Parent Loop BB0_89 Depth=1
    movq    -64(%rsp), %rcx
    vpbroadcastd (%rcx, %r11), %xmm0
    vpsrlvd %xmm14, %xmm0, %xmm0
    vpand   %xmm0, %xmm15, %xmm0
    vcvtdq2ps %xmm0, %xmm0
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vdivps  %xmm12, %xmm0, %xmm0
    vbroadcastss .LCPI0_2(%rip), %xmm12
    vaddps  %xmm0, %xmm12, %xmm0
    vmulps  %xmm0, %xmm13, %xmm0
    vcvttps2dq %xmm0, %xmm0
    vpinsrd $1, %r8d, %xmm5, %xmm12
    vpaddd  %xmm0, %xmm12, %xmm12
    vpextrd $1, %xmm12, %ebx
    cmpl    %esi, %ebx
    jl      .LBB0_94
    movl    %esi, %ebx
.LBB0_94:
    vpmovsxdq %xmm12, %xmm0
    vmovmskpd %xmm0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %edx
    testb   $2, %r13b
    je      .LBB0_95
    vmovd   %xmm12, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_97
.LBB0_98:
    testb   $1, %r13b
    jne     .LBB0_100
    jmp     .LBB0_99
.p2align 4, 0x90
.LBB0_95:
    movl    %ebx, %edx
    vmovd   %xmm12, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_98
.LBB0_97:
    movl    %r9d, %ecx
    testb   $1, %r13b
    jne     .LBB0_100
.LBB0_99:
    movl    %ecx, %ebp
    jmp     .LBB0_100
.LBB0_418:
    vbroadcastss %xmm5, %ymm1
    vmovd   %eax, %xmm0
    vpbroadcastd %xmm0, %ymm2
    vmovd   %r9d, %xmm0
    vpbroadcastd %xmm0, %ymm3
    vmovd   %ecx, %xmm0
    vpbroadcastd %xmm0, %ymm4
    movl    %ecx, %r10d
    movl    %r8d, %ecx
    movq    %rcx, -40(%rsp)
    leaq    (, %r10, 4), %rcx
    movq    %rcx, -48(%rsp)
    movl    $32, %ebx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_3(%rip), %ymm6
    vbroadcastss .LCPI0_1(%rip), %ymm7
    vmovdqa .LCPI0_5(%rip), %ymm8
    vbroadcastss .LCPI0_2(%rip), %ymm9
    vpxor   %xmm10, %xmm10, %xmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    movq    -64(%rsp), %r15
    movq    -56(%rsp), %r12
    jmp     .LBB0_419
.p2align 4, 0x90
.LBB0_431:
    incq    %r14
    movq    -48(%rsp), %rcx
    addq    %rcx, %r12
    addq    %rcx, %r15
    addq    %rcx, %rbx
    cmpq    -40(%rsp), %r14
    je      .LBB0_1322
.LBB0_419:
                                        // Child Loop BB0_420 Depth 2
                                        // Child Loop BB0_422 Depth 2
    vmovd   %r14d, %xmm0
    vpbroadcastd %xmm0, %ymm13
    movq    %rbx, %rdx
    xorl    %ebp, %ebp
    vpmovsxbd .LCPI0_14(%rip), %ymm14
.p2align 4, 0x90
.LBB0_420:  // Parent Loop BB0_419 Depth=1
    movq    %rbp, %rcx
    vmovdqu (%r15, %rbp, 4), %ymm0
    vpshufb %ymm8, %ymm0, %ymm0
    vcvtdq2ps %ymm0, %ymm0
    vdivps  %ymm7, %ymm0, %ymm0
    movq    %rdx, %r13
    vaddps  %ymm0, %ymm9, %ymm0
    vmulps  %ymm0, %ymm1, %ymm0
    vcvttps2dq %ymm0, %ymm0
    vpaddd  %ymm0, %ymm14, %ymm15
    vpmaxsd %ymm10, %ymm15, %ymm15
    vpaddd  %ymm0, %ymm13, %ymm0
    vpmaxsd %ymm10, %ymm0, %ymm0
    vpminsd %ymm2, %ymm15, %ymm15
    vpminsd %ymm3, %ymm0, %ymm0
    vpmulld %ymm4, %ymm0, %ymm0
    vxorps  %xmm5, %xmm5, %xmm5
    vpaddd  %ymm0, %ymm15, %ymm0
    vpcmpeqd %ymm15, %ymm15, %ymm15
    vpgatherdd %ymm15, (%rdi, %ymm0, 4), %ymm5
    vpaddd  %ymm6, %ymm14, %ymm14
    vmovdqu %ymm5, (%r12, %rbp, 4)
    addq    $8, %rbp
    addq    $16, %rcx
    addq    $32, %rdx
    cmpq    %r10, %rcx
    jbe     .LBB0_420
    cmpl    -72(%rsp), %ebp
    vmovaps -24(%rsp), %xmm5
    jl      .LBB0_422
    jmp     .LBB0_431
.p2align 4, 0x90
.LBB0_430:
    imull   -72(%rsp), %r11d
    addl    %edx, %r11d
    movslq  %r11d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r13)
    incq    %rbp
    addq    $4, %r13
    cmpq    %r10, %rbp
    jae     .LBB0_431
.LBB0_422:  // Parent Loop BB0_419 Depth=1
    movq    -64(%rsp), %rcx
    movzbl  1(%rcx, %r13), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm11, %xmm0, %xmm0
    vaddss  %xmm0, %xmm12, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r8d
    leal    (%r8, %rbp), %esi
    movl    %esi, %ecx
    cmpl    %eax, %esi
    jge     .LBB0_423
    xorl    %r11d, %r11d
    movl    $0, %edx
    testl   %esi, %esi
    jns     .LBB0_425
.LBB0_426:
    addl    %r14d, %r8d
    movl    %r8d, %ecx
    cmpl    %r9d, %r8d
    jge     .LBB0_427
.LBB0_428:
    testl   %r8d, %r8d
    js      .LBB0_430
    jmp     .LBB0_429
.p2align 4, 0x90
.LBB0_423:
    movl    %eax, %ecx
    xorl    %r11d, %r11d
    movl    $0, %edx
    testl   %esi, %esi
    js      .LBB0_426
.LBB0_425:
    movl    %ecx, %edx
    addl    %r14d, %r8d
    movl    %r8d, %ecx
    cmpl    %r9d, %r8d
    jl      .LBB0_428
.LBB0_427:
    movl    %r9d, %ecx
    testl   %r8d, %r8d
    js      .LBB0_430
.LBB0_429:
    movl    %ecx, %r11d
    jmp     .LBB0_430
.LBB0_908:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_909:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_846:
    movq    -64(%rsp), %rcx
    movzbl  -24(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    movl    %r14d, %ecx
    cmpl    %eax, %r14d
    jge     .LBB0_847
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_849
.LBB0_850:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_851
.LBB0_852:
    testl   %r14d, %r14d
    js      .LBB0_854
.LBB0_853:
    movl    %ecx, %ebp
.LBB0_854:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_909
    movq    -64(%rsp), %rcx
    movzbl  -20(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    1(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_856
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_858
.LBB0_859:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_860
.LBB0_861:
    testl   %r14d, %r14d
    js      .LBB0_863
.LBB0_862:
    movl    %ecx, %ebp
.LBB0_863:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_909
    movq    -64(%rsp), %rcx
    movzbl  -16(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    2(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_865
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_867
.LBB0_868:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_869
.LBB0_870:
    testl   %r14d, %r14d
    js      .LBB0_872
.LBB0_871:
    movl    %ecx, %ebp
.LBB0_872:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_909
    movq    -64(%rsp), %rcx
    movzbl  -12(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    3(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_874
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jge     .LBB0_876
.LBB0_877:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_878
.LBB0_879:
    testl   %r14d, %r14d
    js      .LBB0_881
.LBB0_880:
    movl    %ecx, %ebp
.LBB0_881:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_909
    movq    -64(%rsp), %rcx
    movzbl  -8(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    4(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_883
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jge     .LBB0_885
.LBB0_886:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_887
.LBB0_888:
    testl   %r14d, %r14d
    js      .LBB0_890
.LBB0_889:
    movl    %ecx, %ebp
.LBB0_890:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_909
    movq    -64(%rsp), %rcx
    movzbl  -4(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    5(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_892
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jge     .LBB0_894
.LBB0_895:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_896
.LBB0_897:
    testl   %r14d, %r14d
    js      .LBB0_899
.LBB0_898:
    movl    %ecx, %ebp
.LBB0_899:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_909
    movq    -64(%rsp), %rcx
    movzbl  (%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    6(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_901
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jge     .LBB0_903
.LBB0_904:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_905
.LBB0_906:
    testl   %r14d, %r14d
    js      .LBB0_908
    jmp     .LBB0_907
.LBB0_847:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_850
.LBB0_849:
    movl    %ecx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_852
.LBB0_851:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_853
    jmp     .LBB0_854
.LBB0_856:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_859
.LBB0_858:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_861
.LBB0_860:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_862
    jmp     .LBB0_863
.LBB0_865:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_868
.LBB0_867:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_870
.LBB0_869:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_871
    jmp     .LBB0_872
.LBB0_874:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jl      .LBB0_877
.LBB0_876:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_879
.LBB0_878:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_880
    jmp     .LBB0_881
.LBB0_883:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jl      .LBB0_886
.LBB0_885:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_888
.LBB0_887:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_889
    jmp     .LBB0_890
.LBB0_892:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jl      .LBB0_895
.LBB0_894:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_897
.LBB0_896:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_898
    jmp     .LBB0_899
.LBB0_901:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jl      .LBB0_904
.LBB0_903:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_906
.LBB0_905:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    js      .LBB0_908
.LBB0_907:
    movl    %ecx, %ebp
    jmp     .LBB0_908
.LBB0_990:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_991:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_928:
    vmovd   %ebx, %xmm3
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpaddd  %xmm4, %xmm3, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_930
    movl    %eax, %esi
.LBB0_930:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_931
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_933
.LBB0_934:
    testb   $1, %r12b
    jne     .LBB0_936
.LBB0_935:
    movl    %ecx, %r13d
.LBB0_936:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_991
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %ebp, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_939
    movl    %eax, %esi
.LBB0_939:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_940
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_942
.LBB0_943:
    testb   $1, %r12b
    jne     .LBB0_945
.LBB0_944:
    movl    %ecx, %r13d
.LBB0_945:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_991
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r14d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_948
    movl    %eax, %esi
.LBB0_948:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_949
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_951
.LBB0_952:
    testb   $1, %r12b
    jne     .LBB0_954
.LBB0_953:
    movl    %ecx, %r13d
.LBB0_954:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_991
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r15d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_957
    movl    %eax, %esi
.LBB0_957:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_958
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_960
.LBB0_961:
    testb   $1, %r12b
    jne     .LBB0_963
.LBB0_962:
    movl    %ecx, %r13d
.LBB0_963:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_991
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_966
    movl    %eax, %esi
.LBB0_966:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_967
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_969
.LBB0_970:
    testb   $1, %r12b
    jne     .LBB0_972
.LBB0_971:
    movl    %ecx, %r13d
.LBB0_972:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_991
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_975
    movl    %eax, %esi
.LBB0_975:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_976
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_978
.LBB0_979:
    testb   $1, %r12b
    jne     .LBB0_981
.LBB0_980:
    movl    %ecx, %r13d
.LBB0_981:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_991
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm3
    vpaddd  %xmm4, %xmm3, %xmm3
    vpextrd $1, %xmm3, %esi
    cmpl    %eax, %esi
    jl      .LBB0_984
    movl    %eax, %esi
.LBB0_984:
    vpmovsxdq %xmm3, %xmm4
    vmovmskpd %xmm4, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_985
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_987
.LBB0_988:
    testb   $1, %r12b
    jne     .LBB0_990
    jmp     .LBB0_989
.LBB0_931:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_934
.LBB0_933:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_935
    jmp     .LBB0_936
.LBB0_940:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_943
.LBB0_942:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_944
    jmp     .LBB0_945
.LBB0_949:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_952
.LBB0_951:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_953
    jmp     .LBB0_954
.LBB0_958:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_961
.LBB0_960:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_962
    jmp     .LBB0_963
.LBB0_967:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_970
.LBB0_969:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_971
    jmp     .LBB0_972
.LBB0_976:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_979
.LBB0_978:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_980
    jmp     .LBB0_981
.LBB0_985:
    movl    %esi, %edx
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_988
.LBB0_987:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_990
.LBB0_989:
    movl    %ecx, %r13d
    jmp     .LBB0_990
.LBB0_1238:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_1239:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_1176:
    vmovd   %ebx, %xmm3
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpaddd  %xmm4, %xmm3, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1178
    movl    %eax, %esi
.LBB0_1178:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1179
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1181
.LBB0_1182:
    testb   $1, %r12b
    jne     .LBB0_1184
.LBB0_1183:
    movl    %ecx, %r13d
.LBB0_1184:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_1239
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %ebp, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1187
    movl    %eax, %esi
.LBB0_1187:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1188
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1190
.LBB0_1191:
    testb   $1, %r12b
    jne     .LBB0_1193
.LBB0_1192:
    movl    %ecx, %r13d
.LBB0_1193:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_1239
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r14d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1196
    movl    %eax, %esi
.LBB0_1196:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1197
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1199
.LBB0_1200:
    testb   $1, %r12b
    jne     .LBB0_1202
.LBB0_1201:
    movl    %ecx, %r13d
.LBB0_1202:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_1239
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r15d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1205
    movl    %eax, %esi
.LBB0_1205:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1206
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1208
.LBB0_1209:
    testb   $1, %r12b
    jne     .LBB0_1211
.LBB0_1210:
    movl    %ecx, %r13d
.LBB0_1211:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_1239
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1214
    movl    %eax, %esi
.LBB0_1214:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1215
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1217
.LBB0_1218:
    testb   $1, %r12b
    jne     .LBB0_1220
.LBB0_1219:
    movl    %ecx, %r13d
.LBB0_1220:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_1239
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1223
    movl    %eax, %esi
.LBB0_1223:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1224
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1226
.LBB0_1227:
    testb   $1, %r12b
    jne     .LBB0_1229
.LBB0_1228:
    movl    %ecx, %r13d
.LBB0_1229:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_1239
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %cl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm3
    vpaddd  %xmm4, %xmm3, %xmm3
    vpextrd $1, %xmm3, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1232
    movl    %eax, %esi
.LBB0_1232:
    vpmovsxdq %xmm3, %xmm4
    vmovmskpd %xmm4, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1233
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1235
.LBB0_1236:
    testb   $1, %r12b
    jne     .LBB0_1238
    jmp     .LBB0_1237
.LBB0_1179:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1182
.LBB0_1181:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1183
    jmp     .LBB0_1184
.LBB0_1188:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1191
.LBB0_1190:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1192
    jmp     .LBB0_1193
.LBB0_1197:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1200
.LBB0_1199:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1201
    jmp     .LBB0_1202
.LBB0_1206:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1209
.LBB0_1208:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1210
    jmp     .LBB0_1211
.LBB0_1215:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1218
.LBB0_1217:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1219
    jmp     .LBB0_1220
.LBB0_1224:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1227
.LBB0_1226:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1228
    jmp     .LBB0_1229
.LBB0_1233:
    movl    %esi, %edx
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1236
.LBB0_1235:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_1238
.LBB0_1237:
    movl    %ecx, %r13d
    jmp     .LBB0_1238
.LBB0_744:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_745:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_682:
    vmovd   %ebx, %xmm4
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpaddd  %xmm5, %xmm4, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_684
    movl    %eax, %esi
.LBB0_684:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_685
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_687
.LBB0_688:
    testb   $1, %r12b
    jne     .LBB0_690
.LBB0_689:
    movl    %ecx, %r13d
.LBB0_690:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_745
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %ebp, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_693
    movl    %eax, %esi
.LBB0_693:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_694
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_696
.LBB0_697:
    testb   $1, %r12b
    jne     .LBB0_699
.LBB0_698:
    movl    %ecx, %r13d
.LBB0_699:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_745
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r14d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_702
    movl    %eax, %esi
.LBB0_702:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_703
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_705
.LBB0_706:
    testb   $1, %r12b
    jne     .LBB0_708
.LBB0_707:
    movl    %ecx, %r13d
.LBB0_708:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_745
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r15d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_711
    movl    %eax, %esi
.LBB0_711:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_712
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_714
.LBB0_715:
    testb   $1, %r12b
    jne     .LBB0_717
.LBB0_716:
    movl    %ecx, %r13d
.LBB0_717:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_745
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_720
    movl    %eax, %esi
.LBB0_720:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_721
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_723
.LBB0_724:
    testb   $1, %r12b
    jne     .LBB0_726
.LBB0_725:
    movl    %ecx, %r13d
.LBB0_726:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_745
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_729
    movl    %eax, %esi
.LBB0_729:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_730
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_732
.LBB0_733:
    testb   $1, %r12b
    jne     .LBB0_735
.LBB0_734:
    movl    %ecx, %r13d
.LBB0_735:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_745
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vpaddd  %xmm5, %xmm4, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_738
    movl    %eax, %esi
.LBB0_738:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_739
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_741
.LBB0_742:
    testb   $1, %r12b
    jne     .LBB0_744
    jmp     .LBB0_743
.LBB0_685:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_688
.LBB0_687:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_689
    jmp     .LBB0_690
.LBB0_694:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_697
.LBB0_696:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_698
    jmp     .LBB0_699
.LBB0_703:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_706
.LBB0_705:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_707
    jmp     .LBB0_708
.LBB0_712:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_715
.LBB0_714:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_716
    jmp     .LBB0_717
.LBB0_721:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_724
.LBB0_723:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_725
    jmp     .LBB0_726
.LBB0_730:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_733
.LBB0_732:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_734
    jmp     .LBB0_735
.LBB0_739:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_742
.LBB0_741:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_744
.LBB0_743:
    movl    %ecx, %r13d
    jmp     .LBB0_744
.LBB0_248:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_249:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_186:
    vmovd   %ebx, %xmm4
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpaddd  %xmm5, %xmm4, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_188
    movl    %eax, %esi
.LBB0_188:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_189
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_191
.LBB0_192:
    testb   $1, %r12b
    jne     .LBB0_194
.LBB0_193:
    movl    %ecx, %r13d
.LBB0_194:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_249
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %ebp, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_197
    movl    %eax, %esi
.LBB0_197:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_198
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_200
.LBB0_201:
    testb   $1, %r12b
    jne     .LBB0_203
.LBB0_202:
    movl    %ecx, %r13d
.LBB0_203:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_249
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r14d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_206
    movl    %eax, %esi
.LBB0_206:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_207
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_209
.LBB0_210:
    testb   $1, %r12b
    jne     .LBB0_212
.LBB0_211:
    movl    %ecx, %r13d
.LBB0_212:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_249
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r15d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_215
    movl    %eax, %esi
.LBB0_215:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_216
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_218
.LBB0_219:
    testb   $1, %r12b
    jne     .LBB0_221
.LBB0_220:
    movl    %ecx, %r13d
.LBB0_221:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_249
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_224
    movl    %eax, %esi
.LBB0_224:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_225
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_227
.LBB0_228:
    testb   $1, %r12b
    jne     .LBB0_230
.LBB0_229:
    movl    %ecx, %r13d
.LBB0_230:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_249
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_233
    movl    %eax, %esi
.LBB0_233:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_234
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_236
.LBB0_237:
    testb   $1, %r12b
    jne     .LBB0_239
.LBB0_238:
    movl    %ecx, %r13d
.LBB0_239:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_249
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vpaddd  %xmm5, %xmm4, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_242
    movl    %eax, %esi
.LBB0_242:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_243
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_245
.LBB0_246:
    testb   $1, %r12b
    jne     .LBB0_248
    jmp     .LBB0_247
.LBB0_189:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_192
.LBB0_191:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_193
    jmp     .LBB0_194
.LBB0_198:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_201
.LBB0_200:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_202
    jmp     .LBB0_203
.LBB0_207:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_210
.LBB0_209:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_211
    jmp     .LBB0_212
.LBB0_216:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_219
.LBB0_218:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_220
    jmp     .LBB0_221
.LBB0_225:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_228
.LBB0_227:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_229
    jmp     .LBB0_230
.LBB0_234:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_237
.LBB0_236:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_238
    jmp     .LBB0_239
.LBB0_243:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_246
.LBB0_245:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_248
.LBB0_247:
    movl    %ecx, %r13d
    jmp     .LBB0_248
.LBB0_826:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_827:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_764:
    vmovd   %ebx, %xmm4
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpaddd  %xmm5, %xmm4, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_766
    movl    %eax, %esi
.LBB0_766:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_767
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_769
.LBB0_770:
    testb   $1, %r12b
    jne     .LBB0_772
.LBB0_771:
    movl    %ecx, %r13d
.LBB0_772:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_827
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %ebp, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_775
    movl    %eax, %esi
.LBB0_775:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_776
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_778
.LBB0_779:
    testb   $1, %r12b
    jne     .LBB0_781
.LBB0_780:
    movl    %ecx, %r13d
.LBB0_781:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_827
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r14d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_784
    movl    %eax, %esi
.LBB0_784:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_785
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_787
.LBB0_788:
    testb   $1, %r12b
    jne     .LBB0_790
.LBB0_789:
    movl    %ecx, %r13d
.LBB0_790:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_827
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r15d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_793
    movl    %eax, %esi
.LBB0_793:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_794
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_796
.LBB0_797:
    testb   $1, %r12b
    jne     .LBB0_799
.LBB0_798:
    movl    %ecx, %r13d
.LBB0_799:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_827
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_802
    movl    %eax, %esi
.LBB0_802:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_803
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_805
.LBB0_806:
    testb   $1, %r12b
    jne     .LBB0_808
.LBB0_807:
    movl    %ecx, %r13d
.LBB0_808:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_827
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_811
    movl    %eax, %esi
.LBB0_811:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_812
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_814
.LBB0_815:
    testb   $1, %r12b
    jne     .LBB0_817
.LBB0_816:
    movl    %ecx, %r13d
.LBB0_817:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_827
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    vmovd   %ecx, %xmm5
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vpaddd  %xmm5, %xmm4, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_820
    movl    %eax, %esi
.LBB0_820:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_821
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_823
.LBB0_824:
    testb   $1, %r12b
    jne     .LBB0_826
    jmp     .LBB0_825
.LBB0_767:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_770
.LBB0_769:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_771
    jmp     .LBB0_772
.LBB0_776:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_779
.LBB0_778:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_780
    jmp     .LBB0_781
.LBB0_785:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_788
.LBB0_787:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_789
    jmp     .LBB0_790
.LBB0_794:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_797
.LBB0_796:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_798
    jmp     .LBB0_799
.LBB0_803:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_806
.LBB0_805:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_807
    jmp     .LBB0_808
.LBB0_812:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_815
.LBB0_814:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_816
    jmp     .LBB0_817
.LBB0_821:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_824
.LBB0_823:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_826
.LBB0_825:
    movl    %ecx, %r13d
    jmp     .LBB0_826
.LBB0_578:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_579:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_516:
    vmovd   %ebx, %xmm4
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpaddd  %xmm5, %xmm4, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_518
    movl    %eax, %esi
.LBB0_518:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_519
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_521
.LBB0_522:
    testb   $1, %r12b
    jne     .LBB0_524
.LBB0_523:
    movl    %ecx, %r13d
.LBB0_524:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_579
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %ebp, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_527
    movl    %eax, %esi
.LBB0_527:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_528
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_530
.LBB0_531:
    testb   $1, %r12b
    jne     .LBB0_533
.LBB0_532:
    movl    %ecx, %r13d
.LBB0_533:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_579
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r14d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_536
    movl    %eax, %esi
.LBB0_536:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_537
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_539
.LBB0_540:
    testb   $1, %r12b
    jne     .LBB0_542
.LBB0_541:
    movl    %ecx, %r13d
.LBB0_542:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_579
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    vpinsrd $1, %r15d, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_545
    movl    %eax, %esi
.LBB0_545:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_546
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_548
.LBB0_549:
    testb   $1, %r12b
    jne     .LBB0_551
.LBB0_550:
    movl    %ecx, %r13d
.LBB0_551:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_579
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_554
    movl    %eax, %esi
.LBB0_554:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_555
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_557
.LBB0_558:
    testb   $1, %r12b
    jne     .LBB0_560
.LBB0_559:
    movl    %ecx, %r13d
.LBB0_560:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_579
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm6
    vpaddd  %xmm5, %xmm6, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_563
    movl    %eax, %esi
.LBB0_563:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_564
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_566
.LBB0_567:
    testb   $1, %r12b
    jne     .LBB0_569
.LBB0_568:
    movl    %ecx, %r13d
.LBB0_569:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_579
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $8, %edx
    vmovd   %edx, %xmm5
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpand   %xmm1, %xmm5, %xmm5
    vcvtdq2ps %xmm5, %xmm5
    vdivps  %xmm2, %xmm5, %xmm5
    vaddps  %xmm3, %xmm5, %xmm5
    vmulps  %xmm0, %xmm5, %xmm5
    vcvttps2dq %xmm5, %xmm5
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vpaddd  %xmm5, %xmm4, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_572
    movl    %eax, %esi
.LBB0_572:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_573
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_575
.LBB0_576:
    testb   $1, %r12b
    jne     .LBB0_578
    jmp     .LBB0_577
.LBB0_519:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_522
.LBB0_521:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_523
    jmp     .LBB0_524
.LBB0_528:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_531
.LBB0_530:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_532
    jmp     .LBB0_533
.LBB0_537:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_540
.LBB0_539:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_541
    jmp     .LBB0_542
.LBB0_546:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_549
.LBB0_548:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_550
    jmp     .LBB0_551
.LBB0_555:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_558
.LBB0_557:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_559
    jmp     .LBB0_560
.LBB0_564:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_567
.LBB0_566:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_568
    jmp     .LBB0_569
.LBB0_573:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_576
.LBB0_575:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_578
.LBB0_577:
    movl    %ecx, %r13d
    jmp     .LBB0_578
.LBB0_1320:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_1321:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_1258:
    movq    -64(%rsp), %rcx
    movzbl  -21(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    movl    %r14d, %ecx
    cmpl    %eax, %r14d
    jge     .LBB0_1259
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_1261
.LBB0_1262:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1263
.LBB0_1264:
    testl   %r14d, %r14d
    js      .LBB0_1266
.LBB0_1265:
    movl    %ecx, %ebp
.LBB0_1266:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_1321
    movq    -64(%rsp), %rcx
    movzbl  -17(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    1(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_1268
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_1270
.LBB0_1271:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1272
.LBB0_1273:
    testl   %r14d, %r14d
    js      .LBB0_1275
.LBB0_1274:
    movl    %ecx, %ebp
.LBB0_1275:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_1321
    movq    -64(%rsp), %rcx
    movzbl  -13(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    2(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_1277
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_1279
.LBB0_1280:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1281
.LBB0_1282:
    testl   %r14d, %r14d
    js      .LBB0_1284
.LBB0_1283:
    movl    %ecx, %ebp
.LBB0_1284:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_1321
    movq    -64(%rsp), %rcx
    movzbl  -9(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    3(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_1286
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jge     .LBB0_1288
.LBB0_1289:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1290
.LBB0_1291:
    testl   %r14d, %r14d
    js      .LBB0_1293
.LBB0_1292:
    movl    %ecx, %ebp
.LBB0_1293:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_1321
    movq    -64(%rsp), %rcx
    movzbl  -5(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    4(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_1295
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jge     .LBB0_1297
.LBB0_1298:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1299
.LBB0_1300:
    testl   %r14d, %r14d
    js      .LBB0_1302
.LBB0_1301:
    movl    %ecx, %ebp
.LBB0_1302:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_1321
    movq    -64(%rsp), %rcx
    movzbl  -1(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    5(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_1304
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jge     .LBB0_1306
.LBB0_1307:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1308
.LBB0_1309:
    testl   %r14d, %r14d
    js      .LBB0_1311
.LBB0_1310:
    movl    %ecx, %ebp
.LBB0_1311:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_1321
    movq    -64(%rsp), %rcx
    movzbl  3(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    6(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_1313
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jge     .LBB0_1315
.LBB0_1316:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_1317
.LBB0_1318:
    testl   %r14d, %r14d
    js      .LBB0_1320
    jmp     .LBB0_1319
.LBB0_1259:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_1262
.LBB0_1261:
    movl    %ecx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1264
.LBB0_1263:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_1265
    jmp     .LBB0_1266
.LBB0_1268:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_1271
.LBB0_1270:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1273
.LBB0_1272:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_1274
    jmp     .LBB0_1275
.LBB0_1277:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_1280
.LBB0_1279:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1282
.LBB0_1281:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_1283
    jmp     .LBB0_1284
.LBB0_1286:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jl      .LBB0_1289
.LBB0_1288:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1291
.LBB0_1290:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_1292
    jmp     .LBB0_1293
.LBB0_1295:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jl      .LBB0_1298
.LBB0_1297:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1300
.LBB0_1299:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_1301
    jmp     .LBB0_1302
.LBB0_1304:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jl      .LBB0_1307
.LBB0_1306:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1309
.LBB0_1308:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_1310
    jmp     .LBB0_1311
.LBB0_1313:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jl      .LBB0_1316
.LBB0_1315:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_1318
.LBB0_1317:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    js      .LBB0_1320
.LBB0_1319:
    movl    %ecx, %ebp
    jmp     .LBB0_1320
.LBB0_1074:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_1075:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_1012:
    vmovd   %ebx, %xmm3
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpaddd  %xmm4, %xmm3, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1014
    movl    %eax, %esi
.LBB0_1014:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1015
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1017
.LBB0_1018:
    testb   $1, %r12b
    jne     .LBB0_1020
.LBB0_1019:
    movl    %ecx, %r13d
.LBB0_1020:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_1075
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %ebp, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1023
    movl    %eax, %esi
.LBB0_1023:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1024
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1026
.LBB0_1027:
    testb   $1, %r12b
    jne     .LBB0_1029
.LBB0_1028:
    movl    %ecx, %r13d
.LBB0_1029:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_1075
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r14d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1032
    movl    %eax, %esi
.LBB0_1032:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1033
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1035
.LBB0_1036:
    testb   $1, %r12b
    jne     .LBB0_1038
.LBB0_1037:
    movl    %ecx, %r13d
.LBB0_1038:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_1075
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r15d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1041
    movl    %eax, %esi
.LBB0_1041:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1042
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1044
.LBB0_1045:
    testb   $1, %r12b
    jne     .LBB0_1047
.LBB0_1046:
    movl    %ecx, %r13d
.LBB0_1047:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_1075
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1050
    movl    %eax, %esi
.LBB0_1050:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1051
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1053
.LBB0_1054:
    testb   $1, %r12b
    jne     .LBB0_1056
.LBB0_1055:
    movl    %ecx, %r13d
.LBB0_1056:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_1075
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1059
    movl    %eax, %esi
.LBB0_1059:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1060
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1062
.LBB0_1063:
    testb   $1, %r12b
    jne     .LBB0_1065
.LBB0_1064:
    movl    %ecx, %r13d
.LBB0_1065:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_1075
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $16, %edx
    movzbl  %dl, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm3
    vpaddd  %xmm4, %xmm3, %xmm3
    vpextrd $1, %xmm3, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1068
    movl    %eax, %esi
.LBB0_1068:
    vpmovsxdq %xmm3, %xmm4
    vmovmskpd %xmm4, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1069
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1071
.LBB0_1072:
    testb   $1, %r12b
    jne     .LBB0_1074
    jmp     .LBB0_1073
.LBB0_1015:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1018
.LBB0_1017:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1019
    jmp     .LBB0_1020
.LBB0_1024:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1027
.LBB0_1026:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1028
    jmp     .LBB0_1029
.LBB0_1033:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1036
.LBB0_1035:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1037
    jmp     .LBB0_1038
.LBB0_1042:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1045
.LBB0_1044:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1046
    jmp     .LBB0_1047
.LBB0_1051:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1054
.LBB0_1053:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1055
    jmp     .LBB0_1056
.LBB0_1060:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1063
.LBB0_1062:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1064
    jmp     .LBB0_1065
.LBB0_1069:
    movl    %esi, %edx
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1072
.LBB0_1071:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_1074
.LBB0_1073:
    movl    %ecx, %r13d
    jmp     .LBB0_1074
.LBB0_1156:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_1157:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_1094:
    vmovd   %ebx, %xmm3
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpaddd  %xmm4, %xmm3, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1096
    movl    %eax, %esi
.LBB0_1096:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1097
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1099
.LBB0_1100:
    testb   $1, %r12b
    jne     .LBB0_1102
.LBB0_1101:
    movl    %ecx, %r13d
.LBB0_1102:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_1157
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %ebp, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1105
    movl    %eax, %esi
.LBB0_1105:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1106
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1108
.LBB0_1109:
    testb   $1, %r12b
    jne     .LBB0_1111
.LBB0_1110:
    movl    %ecx, %r13d
.LBB0_1111:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_1157
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r14d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1114
    movl    %eax, %esi
.LBB0_1114:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1115
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1117
.LBB0_1118:
    testb   $1, %r12b
    jne     .LBB0_1120
.LBB0_1119:
    movl    %ecx, %r13d
.LBB0_1120:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_1157
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r15d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1123
    movl    %eax, %esi
.LBB0_1123:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1124
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1126
.LBB0_1127:
    testb   $1, %r12b
    jne     .LBB0_1129
.LBB0_1128:
    movl    %ecx, %r13d
.LBB0_1129:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_1157
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1132
    movl    %eax, %esi
.LBB0_1132:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1133
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1135
.LBB0_1136:
    testb   $1, %r12b
    jne     .LBB0_1138
.LBB0_1137:
    movl    %ecx, %r13d
.LBB0_1138:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_1157
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1141
    movl    %eax, %esi
.LBB0_1141:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1142
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1144
.LBB0_1145:
    testb   $1, %r12b
    jne     .LBB0_1147
.LBB0_1146:
    movl    %ecx, %r13d
.LBB0_1147:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_1157
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm3
    vpaddd  %xmm4, %xmm3, %xmm3
    vpextrd $1, %xmm3, %esi
    cmpl    %eax, %esi
    jl      .LBB0_1150
    movl    %eax, %esi
.LBB0_1150:
    vpmovsxdq %xmm3, %xmm4
    vmovmskpd %xmm4, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_1151
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_1153
.LBB0_1154:
    testb   $1, %r12b
    jne     .LBB0_1156
    jmp     .LBB0_1155
.LBB0_1097:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1100
.LBB0_1099:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1101
    jmp     .LBB0_1102
.LBB0_1106:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1109
.LBB0_1108:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1110
    jmp     .LBB0_1111
.LBB0_1115:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1118
.LBB0_1117:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1119
    jmp     .LBB0_1120
.LBB0_1124:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1127
.LBB0_1126:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1128
    jmp     .LBB0_1129
.LBB0_1133:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1136
.LBB0_1135:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1137
    jmp     .LBB0_1138
.LBB0_1142:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1145
.LBB0_1144:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_1146
    jmp     .LBB0_1147
.LBB0_1151:
    movl    %esi, %edx
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_1154
.LBB0_1153:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_1156
.LBB0_1155:
    movl    %ecx, %r13d
    jmp     .LBB0_1156
.LBB0_330:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_331:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_268:
    vmovd   %ebx, %xmm3
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpaddd  %xmm4, %xmm3, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_270
    movl    %eax, %esi
.LBB0_270:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_271
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_273
.LBB0_274:
    testb   $1, %r12b
    jne     .LBB0_276
.LBB0_275:
    movl    %ecx, %r13d
.LBB0_276:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_331
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %ebp, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_279
    movl    %eax, %esi
.LBB0_279:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_280
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_282
.LBB0_283:
    testb   $1, %r12b
    jne     .LBB0_285
.LBB0_284:
    movl    %ecx, %r13d
.LBB0_285:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_331
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r14d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_288
    movl    %eax, %esi
.LBB0_288:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_289
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_291
.LBB0_292:
    testb   $1, %r12b
    jne     .LBB0_294
.LBB0_293:
    movl    %ecx, %r13d
.LBB0_294:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_331
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r15d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_297
    movl    %eax, %esi
.LBB0_297:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_298
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_300
.LBB0_301:
    testb   $1, %r12b
    jne     .LBB0_303
.LBB0_302:
    movl    %ecx, %r13d
.LBB0_303:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_331
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_306
    movl    %eax, %esi
.LBB0_306:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_307
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_309
.LBB0_310:
    testb   $1, %r12b
    jne     .LBB0_312
.LBB0_311:
    movl    %ecx, %r13d
.LBB0_312:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_331
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_315
    movl    %eax, %esi
.LBB0_315:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_316
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_318
.LBB0_319:
    testb   $1, %r12b
    jne     .LBB0_321
.LBB0_320:
    movl    %ecx, %r13d
.LBB0_321:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_331
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movl    %ecx, %edx
    shrl    $24, %edx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vmovd   %ecx, %xmm4
    vpinsrd $1, %edx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm3
    vpaddd  %xmm4, %xmm3, %xmm3
    vpextrd $1, %xmm3, %esi
    cmpl    %eax, %esi
    jl      .LBB0_324
    movl    %eax, %esi
.LBB0_324:
    vpmovsxdq %xmm3, %xmm4
    vmovmskpd %xmm4, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_325
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_327
.LBB0_328:
    testb   $1, %r12b
    jne     .LBB0_330
    jmp     .LBB0_329
.LBB0_271:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_274
.LBB0_273:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_275
    jmp     .LBB0_276
.LBB0_280:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_283
.LBB0_282:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_284
    jmp     .LBB0_285
.LBB0_289:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_292
.LBB0_291:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_293
    jmp     .LBB0_294
.LBB0_298:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_301
.LBB0_300:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_302
    jmp     .LBB0_303
.LBB0_307:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_310
.LBB0_309:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_311
    jmp     .LBB0_312
.LBB0_316:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_319
.LBB0_318:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_320
    jmp     .LBB0_321
.LBB0_325:
    movl    %esi, %edx
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_328
.LBB0_327:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_330
.LBB0_329:
    movl    %ecx, %r13d
    jmp     .LBB0_330
.LBB0_660:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_661:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_598:
    vmovd   %ebx, %xmm3
    movq    -64(%rsp), %rcx
    movl    -24(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpaddd  %xmm4, %xmm3, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_600
    movl    %eax, %esi
.LBB0_600:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_601
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_603
.LBB0_604:
    testb   $1, %r12b
    jne     .LBB0_606
.LBB0_605:
    movl    %ecx, %r13d
.LBB0_606:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_661
    movq    -64(%rsp), %rcx
    movl    -20(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %ebp, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_609
    movl    %eax, %esi
.LBB0_609:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_610
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_612
.LBB0_613:
    testb   $1, %r12b
    jne     .LBB0_615
.LBB0_614:
    movl    %ecx, %r13d
.LBB0_615:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_661
    movq    -64(%rsp), %rcx
    movl    -16(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r14d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_618
    movl    %eax, %esi
.LBB0_618:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_619
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_621
.LBB0_622:
    testb   $1, %r12b
    jne     .LBB0_624
.LBB0_623:
    movl    %ecx, %r13d
.LBB0_624:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_661
    movq    -64(%rsp), %rcx
    movl    -12(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    vpinsrd $1, %r15d, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_627
    movl    %eax, %esi
.LBB0_627:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_628
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_630
.LBB0_631:
    testb   $1, %r12b
    jne     .LBB0_633
.LBB0_632:
    movl    %ecx, %r13d
.LBB0_633:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_661
    movq    -64(%rsp), %rcx
    movl    -8(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_636
    movl    %eax, %esi
.LBB0_636:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_637
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_639
.LBB0_640:
    testb   $1, %r12b
    jne     .LBB0_642
.LBB0_641:
    movl    %ecx, %r13d
.LBB0_642:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_661
    movq    -64(%rsp), %rcx
    movl    -4(%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm5
    vpaddd  %xmm4, %xmm5, %xmm4
    vpextrd $1, %xmm4, %esi
    cmpl    %eax, %esi
    jl      .LBB0_645
    movl    %eax, %esi
.LBB0_645:
    vpmovsxdq %xmm4, %xmm5
    vmovmskpd %xmm5, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_646
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_648
.LBB0_649:
    testb   $1, %r12b
    jne     .LBB0_651
.LBB0_650:
    movl    %ecx, %r13d
.LBB0_651:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_661
    movq    -64(%rsp), %rcx
    movl    (%rcx, %r11), %ecx
    movzbl  %ch, %edx
    shrl    $24, %ecx
    vmovd   %edx, %xmm4
    vpinsrd $1, %ecx, %xmm4, %xmm4
    vcvtdq2ps %xmm4, %xmm4
    vdivps  %xmm1, %xmm4, %xmm4
    vaddps  %xmm2, %xmm4, %xmm4
    vmulps  %xmm0, %xmm4, %xmm4
    vcvttps2dq %xmm4, %xmm4
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm3, %xmm3
    vpaddd  %xmm4, %xmm3, %xmm3
    vpextrd $1, %xmm3, %esi
    cmpl    %eax, %esi
    jl      .LBB0_654
    movl    %eax, %esi
.LBB0_654:
    vpmovsxdq %xmm3, %xmm4
    vmovmskpd %xmm4, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_655
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_657
.LBB0_658:
    testb   $1, %r12b
    jne     .LBB0_660
    jmp     .LBB0_659
.LBB0_601:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_604
.LBB0_603:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_605
    jmp     .LBB0_606
.LBB0_610:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_613
.LBB0_612:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_614
    jmp     .LBB0_615
.LBB0_619:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_622
.LBB0_621:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_623
    jmp     .LBB0_624
.LBB0_628:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_631
.LBB0_630:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_632
    jmp     .LBB0_633
.LBB0_637:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_640
.LBB0_639:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_641
    jmp     .LBB0_642
.LBB0_646:
    movl    %esi, %edx
    vmovd   %xmm4, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_649
.LBB0_648:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_650
    jmp     .LBB0_651
.LBB0_655:
    movl    %esi, %edx
    vmovd   %xmm3, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_658
.LBB0_657:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_660
.LBB0_659:
    movl    %ecx, %r13d
    jmp     .LBB0_660
.LBB0_84:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rcx
    movl    %eax, (%rcx, %r11)
.p2align 4, 0x90
.LBB0_85:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_22:
    movq    -64(%rsp), %rax
    movzbl  -22(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    movl    %r14d, %eax
    cmpl    %edx, %r14d
    jl      .LBB0_24
    movl    %edx, %eax
.LBB0_24:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    movq    -72(%rsp), %rcx
    jns     .LBB0_25
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
    movq    -56(%rsp), %rsi
    movl    %eax, -24(%rsi, %r11)
    cmpl    $1, %ecx
    je      .LBB0_85
    movq    -64(%rsp), %rax
    movzbl  -18(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    leal    1(%r14), %eax
    cmpl    %edx, %eax
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
    movq    -56(%rsp), %rsi
    movl    %eax, -20(%rsi, %r11)
    cmpl    $2, %ecx
    je      .LBB0_85
    movq    -64(%rsp), %rax
    movzbl  -14(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    leal    2(%r14), %eax
    cmpl    %edx, %eax
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
.LBB0_47:
    movl    %eax, %ebp
.LBB0_48:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rsi
    movl    %eax, -16(%rsi, %r11)
    cmpl    $3, %ecx
    je      .LBB0_85
    movq    -64(%rsp), %rax
    movzbl  -10(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm0, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    leal    3(%r14), %eax
    cmpl    %edx, %eax
    jge     .LBB0_50
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jge     .LBB0_52
.LBB0_53:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_54
.LBB0_55:
    testl   %r14d, %r14d
    js      .LBB0_57
.LBB0_56:
    movl    %eax, %ebp
.LBB0_57:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rsi
    movl    %eax, -12(%rsi, %r11)
    cmpl    $4, %ecx
    je      .LBB0_85
    movq    -64(%rsp), %rax
    movzbl  -6(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm0, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    leal    4(%r14), %eax
    cmpl    %edx, %eax
    jge     .LBB0_59
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jge     .LBB0_61
.LBB0_62:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_63
.LBB0_64:
    testl   %r14d, %r14d
    js      .LBB0_66
.LBB0_65:
    movl    %eax, %ebp
.LBB0_66:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rsi
    movl    %eax, -8(%rsi, %r11)
    cmpl    $5, %ecx
    je      .LBB0_85
    movq    -64(%rsp), %rax
    movzbl  -2(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm0, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    leal    5(%r14), %eax
    cmpl    %edx, %eax
    jge     .LBB0_68
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jge     .LBB0_70
.LBB0_71:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_72
.LBB0_73:
    testl   %r14d, %r14d
    js      .LBB0_75
.LBB0_74:
    movl    %eax, %ebp
.LBB0_75:
    imull   %ecx, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rsi
    movl    %eax, -4(%rsi, %r11)
    cmpl    $6, %ecx
    je      .LBB0_85
    movq    -64(%rsp), %rax
    movzbl  2(%rax, %r11), %eax
    vcvtsi2ss %eax, %xmm0, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm5, %xmm3, %xmm3
    vcvttss2si %xmm3, %r14d
    leal    6(%r14), %eax
    cmpl    %edx, %eax
    jge     .LBB0_77
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jge     .LBB0_79
.LBB0_80:
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jge     .LBB0_81
.LBB0_82:
    testl   %r14d, %r14d
    js      .LBB0_84
    jmp     .LBB0_83
.LBB0_25:
    movl    %eax, %r15d
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
    movl    %edx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_35
.LBB0_34:
    movl    %eax, %r15d
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
    movl    %edx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_44
.LBB0_43:
    movl    %eax, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_46
.LBB0_45:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    jns     .LBB0_47
    jmp     .LBB0_48
.LBB0_50:
    movl    %edx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jl      .LBB0_53
.LBB0_52:
    movl    %eax, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_55
.LBB0_54:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    jns     .LBB0_56
    jmp     .LBB0_57
.LBB0_59:
    movl    %edx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jl      .LBB0_62
.LBB0_61:
    movl    %eax, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_64
.LBB0_63:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    jns     .LBB0_65
    jmp     .LBB0_66
.LBB0_68:
    movl    %edx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jl      .LBB0_71
.LBB0_70:
    movl    %eax, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_73
.LBB0_72:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    jns     .LBB0_74
    jmp     .LBB0_75
.LBB0_77:
    movl    %edx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jl      .LBB0_80
.LBB0_79:
    movl    %eax, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %eax
    cmpl    %r9d, %r14d
    jl      .LBB0_82
.LBB0_81:
    movl    %r9d, %eax
    testl   %r14d, %r14d
    js      .LBB0_84
.LBB0_83:
    movl    %eax, %ebp
    jmp     .LBB0_84
.LBB0_414:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_415:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_352:
    movq    -64(%rsp), %rcx
    vpbroadcastd -24(%rcx, %r11), %xmm6
    vmovd   %ebx, %xmm5
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpaddd  %xmm6, %xmm5, %xmm6
    vpextrd $1, %xmm6, %esi
    cmpl    %eax, %esi
    jl      .LBB0_354
    movl    %eax, %esi
.LBB0_354:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_355
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_357
.LBB0_358:
    testb   $1, %r12b
    jne     .LBB0_360
.LBB0_359:
    movl    %ecx, %r13d
.LBB0_360:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_415
    movq    -64(%rsp), %rcx
    vpbroadcastd -20(%rcx, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %ebp, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %esi
    cmpl    %eax, %esi
    jl      .LBB0_363
    movl    %eax, %esi
.LBB0_363:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_364
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_366
.LBB0_367:
    testb   $1, %r12b
    jne     .LBB0_369
.LBB0_368:
    movl    %ecx, %r13d
.LBB0_369:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_415
    movq    -64(%rsp), %rcx
    vpbroadcastd -16(%rcx, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r14d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %esi
    cmpl    %eax, %esi
    jl      .LBB0_372
    movl    %eax, %esi
.LBB0_372:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_373
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_375
.LBB0_376:
    testb   $1, %r12b
    jne     .LBB0_378
.LBB0_377:
    movl    %ecx, %r13d
.LBB0_378:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_415
    movq    -64(%rsp), %rcx
    vpbroadcastd -12(%rcx, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r15d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %esi
    cmpl    %eax, %esi
    jl      .LBB0_381
    movl    %eax, %esi
.LBB0_381:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_382
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_384
.LBB0_385:
    testb   $1, %r12b
    jne     .LBB0_387
.LBB0_386:
    movl    %ecx, %r13d
.LBB0_387:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_415
    movq    -64(%rsp), %rcx
    vpbroadcastd -8(%rcx, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    movl    $4, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %esi
    cmpl    %eax, %esi
    jl      .LBB0_390
    movl    %eax, %esi
.LBB0_390:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_391
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_393
.LBB0_394:
    testb   $1, %r12b
    jne     .LBB0_396
.LBB0_395:
    movl    %ecx, %r13d
.LBB0_396:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_415
    movq    -64(%rsp), %rcx
    vpbroadcastd -4(%rcx, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    movl    $5, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %esi
    cmpl    %eax, %esi
    jl      .LBB0_399
    movl    %eax, %esi
.LBB0_399:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_400
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_402
.LBB0_403:
    testb   $1, %r12b
    jne     .LBB0_405
.LBB0_404:
    movl    %ecx, %r13d
.LBB0_405:
    movq    -72(%rsp), %rsi
    imull   %esi, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_415
    movq    -64(%rsp), %rcx
    vpbroadcastd (%rcx, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    movl    $6, %ecx
    vpinsrd $1, %ecx, %xmm5, %xmm5
    vpaddd  %xmm6, %xmm5, %xmm5
    vpextrd $1, %xmm5, %esi
    cmpl    %eax, %esi
    jl      .LBB0_408
    movl    %eax, %esi
.LBB0_408:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_409
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_411
.LBB0_412:
    testb   $1, %r12b
    jne     .LBB0_414
    jmp     .LBB0_413
.LBB0_355:
    movl    %esi, %edx
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_358
.LBB0_357:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_359
    jmp     .LBB0_360
.LBB0_364:
    movl    %esi, %edx
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_367
.LBB0_366:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_368
    jmp     .LBB0_369
.LBB0_373:
    movl    %esi, %edx
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_376
.LBB0_375:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_377
    jmp     .LBB0_378
.LBB0_382:
    movl    %esi, %edx
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_385
.LBB0_384:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_386
    jmp     .LBB0_387
.LBB0_391:
    movl    %esi, %edx
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_394
.LBB0_393:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_395
    jmp     .LBB0_396
.LBB0_400:
    movl    %esi, %edx
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_403
.LBB0_402:
    movl    %r9d, %ecx
    testb   $1, %r12b
    je      .LBB0_404
    jmp     .LBB0_405
.LBB0_409:
    movl    %esi, %edx
    vmovd   %xmm5, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_412
.LBB0_411:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_414
.LBB0_413:
    movl    %ecx, %r13d
    jmp     .LBB0_414
.LBB0_166:
    imull   -72(%rsp), %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rcx
    movl    %eax, (%rcx, %r11)
.p2align 4, 0x90
.LBB0_167:
    incq    %r15
    addq    %r10, %r11
    cmpq    %r15, %r8
    je      .LBB0_1322
.LBB0_104:
    movq    -64(%rsp), %rax
    vpbroadcastd -24(%rax, %r11), %xmm6
    vmovd   %r15d, %xmm5
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpaddd  %xmm6, %xmm5, %xmm6
    vpextrd $1, %xmm6, %eax
    cmpl    %esi, %eax
    jl      .LBB0_106
    movl    %esi, %eax
.LBB0_106:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_107
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_109
.LBB0_110:
    testb   $1, %r12b
    jne     .LBB0_112
.LBB0_111:
    movl    %eax, %r13d
.LBB0_112:
    movq    -72(%rsp), %rcx
    imull   %ecx, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rdx
    movl    %eax, -24(%rdx, %r11)
    cmpl    $1, %ecx
    je      .LBB0_167
    movq    -64(%rsp), %rax
    vpbroadcastd -20(%rax, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %ebp, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %eax
    cmpl    %esi, %eax
    jl      .LBB0_115
    movl    %esi, %eax
.LBB0_115:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_116
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_118
.LBB0_119:
    testb   $1, %r12b
    jne     .LBB0_121
.LBB0_120:
    movl    %eax, %r13d
.LBB0_121:
    movq    -72(%rsp), %rcx
    imull   %ecx, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rdx
    movl    %eax, -20(%rdx, %r11)
    cmpl    $2, %ecx
    je      .LBB0_167
    movq    -64(%rsp), %rax
    vpbroadcastd -16(%rax, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r14d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %eax
    cmpl    %esi, %eax
    jl      .LBB0_124
    movl    %esi, %eax
.LBB0_124:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_125
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_127
.LBB0_128:
    testb   $1, %r12b
    jne     .LBB0_130
.LBB0_129:
    movl    %eax, %r13d
.LBB0_130:
    movq    -72(%rsp), %rcx
    imull   %ecx, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rdx
    movl    %eax, -16(%rdx, %r11)
    cmpl    $3, %ecx
    je      .LBB0_167
    movq    -64(%rsp), %rax
    vpbroadcastd -12(%rax, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %ebx, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %eax
    cmpl    %esi, %eax
    jl      .LBB0_133
    movl    %esi, %eax
.LBB0_133:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_134
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_136
.LBB0_137:
    testb   $1, %r12b
    jne     .LBB0_139
.LBB0_138:
    movl    %eax, %r13d
.LBB0_139:
    movq    -72(%rsp), %rcx
    imull   %ecx, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rdx
    movl    %eax, -12(%rdx, %r11)
    cmpl    $4, %ecx
    je      .LBB0_167
    movq    -64(%rsp), %rax
    vpbroadcastd -8(%rax, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    movl    $4, %eax
    vpinsrd $1, %eax, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %eax
    cmpl    %esi, %eax
    jl      .LBB0_142
    movl    %esi, %eax
.LBB0_142:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_143
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_145
.LBB0_146:
    testb   $1, %r12b
    jne     .LBB0_148
.LBB0_147:
    movl    %eax, %r13d
.LBB0_148:
    movq    -72(%rsp), %rcx
    imull   %ecx, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rdx
    movl    %eax, -8(%rdx, %r11)
    cmpl    $5, %ecx
    je      .LBB0_167
    movq    -64(%rsp), %rax
    vpbroadcastd -4(%rax, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    movl    $5, %eax
    vpinsrd $1, %eax, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %eax
    cmpl    %esi, %eax
    jl      .LBB0_151
    movl    %esi, %eax
.LBB0_151:
    vpmovsxdq %xmm6, %xmm7
    vmovmskpd %xmm7, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_152
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_154
.LBB0_155:
    testb   $1, %r12b
    jne     .LBB0_157
.LBB0_156:
    movl    %eax, %r13d
.LBB0_157:
    movq    -72(%rsp), %rcx
    imull   %ecx, %r13d
    addl    %edx, %r13d
    movslq  %r13d, %rax
    movl    (%rdi, %rax, 4), %eax
    movq    -56(%rsp), %rdx
    movl    %eax, -4(%rdx, %r11)
    cmpl    $6, %ecx
    je      .LBB0_167
    movq    -64(%rsp), %rax
    vpbroadcastd (%rax, %r11), %xmm6
    vpsrlvd %xmm1, %xmm6, %xmm6
    vpand   %xmm2, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm3, %xmm6, %xmm6
    vaddps  %xmm4, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    movl    $6, %eax
    vpinsrd $1, %eax, %xmm5, %xmm5
    vpaddd  %xmm6, %xmm5, %xmm5
    vpextrd $1, %xmm5, %eax
    cmpl    %esi, %eax
    jl      .LBB0_160
    movl    %esi, %eax
.LBB0_160:
    vpmovsxdq %xmm5, %xmm6
    vmovmskpd %xmm6, %r12d
    xorl    %r13d, %r13d
    movl    $0, %edx
    testb   $2, %r12b
    je      .LBB0_161
    vmovd   %xmm5, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_163
.LBB0_164:
    testb   $1, %r12b
    jne     .LBB0_166
    jmp     .LBB0_165
.LBB0_107:
    movl    %eax, %edx
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_110
.LBB0_109:
    movl    %r9d, %eax
    testb   $1, %r12b
    je      .LBB0_111
    jmp     .LBB0_112
.LBB0_116:
    movl    %eax, %edx
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_119
.LBB0_118:
    movl    %r9d, %eax
    testb   $1, %r12b
    je      .LBB0_120
    jmp     .LBB0_121
.LBB0_125:
    movl    %eax, %edx
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_128
.LBB0_127:
    movl    %r9d, %eax
    testb   $1, %r12b
    je      .LBB0_129
    jmp     .LBB0_130
.LBB0_134:
    movl    %eax, %edx
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_137
.LBB0_136:
    movl    %r9d, %eax
    testb   $1, %r12b
    je      .LBB0_138
    jmp     .LBB0_139
.LBB0_143:
    movl    %eax, %edx
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_146
.LBB0_145:
    movl    %r9d, %eax
    testb   $1, %r12b
    je      .LBB0_147
    jmp     .LBB0_148
.LBB0_152:
    movl    %eax, %edx
    vmovd   %xmm6, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_155
.LBB0_154:
    movl    %r9d, %eax
    testb   $1, %r12b
    je      .LBB0_156
    jmp     .LBB0_157
.LBB0_161:
    movl    %eax, %edx
    vmovd   %xmm5, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_164
.LBB0_163:
    movl    %r9d, %eax
    testb   $1, %r12b
    jne     .LBB0_166
.LBB0_165:
    movl    %eax, %r13d
    jmp     .LBB0_166
.LBB0_496:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, (%rdx, %r11)
.p2align 4, 0x90
.LBB0_497:
    incq    %rbx
    addq    %r10, %r11
    cmpq    %rbx, %r8
    je      .LBB0_1322
.LBB0_434:
    movq    -64(%rsp), %rcx
    movzbl  -23(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    movl    %r14d, %ecx
    cmpl    %eax, %r14d
    jge     .LBB0_435
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    jns     .LBB0_437
.LBB0_438:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_439
.LBB0_440:
    testl   %r14d, %r14d
    js      .LBB0_442
.LBB0_441:
    movl    %ecx, %ebp
.LBB0_442:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -24(%rdx, %r11)
    cmpl    $1, %esi
    je      .LBB0_497
    movq    -64(%rsp), %rcx
    movzbl  -19(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    1(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_444
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jge     .LBB0_446
.LBB0_447:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_448
.LBB0_449:
    testl   %r14d, %r14d
    js      .LBB0_451
.LBB0_450:
    movl    %ecx, %ebp
.LBB0_451:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -20(%rdx, %r11)
    cmpl    $2, %esi
    je      .LBB0_497
    movq    -64(%rsp), %rcx
    movzbl  -15(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    2(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_453
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jge     .LBB0_455
.LBB0_456:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_457
.LBB0_458:
    testl   %r14d, %r14d
    js      .LBB0_460
.LBB0_459:
    movl    %ecx, %ebp
.LBB0_460:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -16(%rdx, %r11)
    cmpl    $3, %esi
    je      .LBB0_497
    movq    -64(%rsp), %rcx
    movzbl  -11(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    3(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_462
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jge     .LBB0_464
.LBB0_465:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_466
.LBB0_467:
    testl   %r14d, %r14d
    js      .LBB0_469
.LBB0_468:
    movl    %ecx, %ebp
.LBB0_469:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -12(%rdx, %r11)
    cmpl    $4, %esi
    je      .LBB0_497
    movq    -64(%rsp), %rcx
    movzbl  -7(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm3, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    4(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_471
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jge     .LBB0_473
.LBB0_474:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_475
.LBB0_476:
    testl   %r14d, %r14d
    js      .LBB0_478
.LBB0_477:
    movl    %ecx, %ebp
.LBB0_478:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -8(%rdx, %r11)
    cmpl    $5, %esi
    je      .LBB0_497
    movq    -64(%rsp), %rcx
    movzbl  -3(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    5(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_480
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jge     .LBB0_482
.LBB0_483:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_484
.LBB0_485:
    testl   %r14d, %r14d
    js      .LBB0_487
.LBB0_486:
    movl    %ecx, %ebp
.LBB0_487:
    imull   %esi, %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movq    -56(%rsp), %rdx
    movl    %ecx, -4(%rdx, %r11)
    cmpl    $6, %esi
    je      .LBB0_497
    movq    -64(%rsp), %rcx
    movzbl  1(%rcx, %r11), %ecx
    vcvtsi2ss %ecx, %xmm1, %xmm0
    vdivss  %xmm1, %xmm0, %xmm0
    vaddss  %xmm2, %xmm0, %xmm0
    vmulss  %xmm5, %xmm0, %xmm0
    vcvttss2si %xmm0, %r14d
    leal    6(%r14), %edx
    cmpl    %eax, %edx
    jge     .LBB0_489
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jge     .LBB0_491
.LBB0_492:
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jge     .LBB0_493
.LBB0_494:
    testl   %r14d, %r14d
    js      .LBB0_496
    jmp     .LBB0_495
.LBB0_435:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r14d, %r14d
    js      .LBB0_438
.LBB0_437:
    movl    %ecx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_440
.LBB0_439:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_441
    jmp     .LBB0_442
.LBB0_444:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-1, %r14d
    jl      .LBB0_447
.LBB0_446:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_449
.LBB0_448:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_450
    jmp     .LBB0_451
.LBB0_453:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-2, %r14d
    jl      .LBB0_456
.LBB0_455:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_458
.LBB0_457:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_459
    jmp     .LBB0_460
.LBB0_462:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-3, %r14d
    jl      .LBB0_465
.LBB0_464:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_467
.LBB0_466:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_468
    jmp     .LBB0_469
.LBB0_471:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-4, %r14d
    jl      .LBB0_474
.LBB0_473:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_476
.LBB0_475:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_477
    jmp     .LBB0_478
.LBB0_480:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-5, %r14d
    jl      .LBB0_483
.LBB0_482:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_485
.LBB0_484:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    jns     .LBB0_486
    jmp     .LBB0_487
.LBB0_489:
    movl    %eax, %edx
    xorl    %ebp, %ebp
    movl    $0, %r15d
    cmpl    $-6, %r14d
    jl      .LBB0_492
.LBB0_491:
    movl    %edx, %r15d
    addl    %ebx, %r14d
    movl    %r14d, %ecx
    cmpl    %r9d, %r14d
    jl      .LBB0_494
.LBB0_493:
    movl    %r9d, %ecx
    testl   %r14d, %r14d
    js      .LBB0_496
.LBB0_495:
    movl    %ecx, %ebp
    jmp     .LBB0_496
.LBB0_1322:
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
    vzeroupper
    retq
.Lfunc_end0:
// SIZE(SYM(ksvgDisplacementMapApplyAvx2))
    CFI_END
    RODATA
.p2align 2, 0x0
.LJTI0_0:
.long .LBB0_2-.LJTI0_0
.long .LBB0_332-.LJTI0_0
.long .LBB0_662-.LJTI0_0
.long .LBB0_992-.LJTI0_0
.LJTI0_1:
.long .LBB0_994-.LJTI0_1
.long .LBB0_1076-.LJTI0_1
.long .LBB0_1158-.LJTI0_1
.long .LBB0_1240-.LJTI0_1
.LJTI0_2:
.long .LBB0_664-.LJTI0_2
.long .LBB0_746-.LJTI0_2
.long .LBB0_828-.LJTI0_2
.long .LBB0_910-.LJTI0_2
.LJTI0_3:
.long .LBB0_334-.LJTI0_3
.long .LBB0_416-.LJTI0_3
.long .LBB0_498-.LJTI0_3
.long .LBB0_580-.LJTI0_3
.LJTI0_4:
.long .LBB0_4-.LJTI0_4
.long .LBB0_86-.LJTI0_4
.long .LBB0_168-.LJTI0_4
.long .LBB0_250-.LJTI0_4
GNU_STACK
ADDRSIG
