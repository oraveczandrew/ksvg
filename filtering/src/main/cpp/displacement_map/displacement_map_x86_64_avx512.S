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
    RODATA
.p2align 6, 0x0
.LCPI0_0:
.long 0
.long 1
.long 2
.long 3
.long 4
.long 5
.long 6
.long 7
.long 8
.long 9
.long 10
.long 11
.long 12
.long 13
.long 14
.long 15
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
    RODATA4
.p2align 2, 0x0
.LCPI0_1:
.long 0x437f0000  // float 255
.LCPI0_2:
.long 0xbf000000  // float -0.5
.LCPI0_3:
.long 16
.LCPI0_5:
.byte 255
.byte 0
.byte 0
.byte 0
.LCPI0_9:
.byte 255
.byte 255
.byte 0
.byte 0
.LCPI0_10:
.byte 8
.byte 16
.byte 0
.byte 0
.LCPI0_11:
.byte 16
.byte 8
.byte 0
.byte 0
    RODATA16
.p2align 4, 0x0
.LCPI0_6:
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
.LCPI0_7:
.long 8
.long 16
.zero 4
.zero 4
.LCPI0_8:
.long 16
.long 8
.zero 4
.zero 4
.LCPI0_12:
.byte 0
.byte 1
.byte 2
.byte 3
.byte 4
.byte 5
.byte 6
.byte 7
.byte 8
.byte 9
.byte 10
.byte 11
.byte 12
.byte 13
.byte 14
.byte 15
.text
.globl SYM(ksvgDisplacementMapApplyAvx512)
.p2align 4, 0x90
TYPE(SYM(ksvgDisplacementMapApplyAvx512), @function)
    SYM(ksvgDisplacementMapApplyAvx512):
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
    movq    %rcx, -16(%rsp)
    movl    56(%rsp), %eax
    cmpq    $3, %rax
    ja      .LBB0_480
    leaq    .LJTI0_0(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_2:
    cmpl    $3, %r9d
    ja      .LBB0_480
    movl    %r9d, %eax
    leaq    .LJTI0_4(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_4:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %ecx
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_6
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r11d
    leaq    (, %r10, 4), %r8
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_22
.p2align 4, 0x90
.LBB0_32:
    incq    %rbx
    addq    %r8, %rdx
    addq    %r8, %rsi
    cmpq    %r11, %rbx
    je      .LBB0_480
.LBB0_22:
                                        // Child Loop BB0_23 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_23
.p2align 4, 0x90
.LBB0_31:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_32
.LBB0_23:  // Parent Loop BB0_22 Depth=1
    movzbl  2(%rsi, %r14, 4), %eax
    vcvtsi2ss %eax, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r15d
    leal    (%r14, %r15), %r13d
    movl    %r13d, %eax
    cmpl    %ecx, %r13d
    jge     .LBB0_24
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    jns     .LBB0_26
.LBB0_27:
    addl    %ebx, %r15d
    movl    %r15d, %eax
    cmpl    %r9d, %r15d
    jge     .LBB0_28
.LBB0_29:
    testl   %r15d, %r15d
    js      .LBB0_31
    jmp     .LBB0_30
.p2align 4, 0x90
.LBB0_24:
    movl    %ecx, %eax
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    js      .LBB0_27
.LBB0_26:
    movl    %eax, %r12d
    addl    %ebx, %r15d
    movl    %r15d, %eax
    cmpl    %r9d, %r15d
    jl      .LBB0_29
.LBB0_28:
    movl    %r9d, %eax
    testl   %r15d, %r15d
    js      .LBB0_31
.LBB0_30:
    movl    %eax, %ebp
    jmp     .LBB0_31
.LBB0_242:
    cmpl    $3, %r9d
    ja      .LBB0_480
    movl    %r9d, %eax
    leaq    .LJTI0_2(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_244:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %r11d
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_246
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_9(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    vpxor   %xmm4, %xmm4, %xmm4
    jmp     .LBB0_263
.p2align 4, 0x90
.LBB0_273:
    incq    %rbx
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_263:
                                        // Child Loop BB0_264 Depth 2
    vmovd   %ebx, %xmm5
    xorl    %r14d, %r14d
    jmp     .LBB0_264
.p2align 4, 0x90
.LBB0_272:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_273
.LBB0_264:  // Parent Loop BB0_263 Depth=1
    movl    (%rsi, %r14, 4), %ecx
    vmovd   %ecx, %xmm6
    shrl    $16, %ecx
    vpinsrd $1, %ecx, %xmm6, %xmm6
    vpand   %xmm1, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm2, %xmm6, %xmm6
    vaddps  %xmm3, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r14d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %r13d
    cmpl    %r11d, %r13d
    jl      .LBB0_266
    movl    %r11d, %r13d
.LBB0_266:
    vpcmpgtd %zmm6, %zmm4, %k0
    kmovw   %k0, %r12d
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testb   $2, %r12b
    je      .LBB0_267
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_269
.LBB0_270:
    testb   $1, %r12b
    jne     .LBB0_272
    jmp     .LBB0_271
.p2align 4, 0x90
.LBB0_267:
    movl    %r13d, %r15d
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_270
.LBB0_269:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_272
.LBB0_271:
    movl    %ecx, %ebp
    jmp     .LBB0_272
.LBB0_362:
    cmpl    $3, %r9d
    ja      .LBB0_480
    movl    %r9d, %eax
    leaq    .LJTI0_1(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_364:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_366
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_382
.p2align 4, 0x90
.LBB0_392:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_382:
                                        // Child Loop BB0_383 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_383
.p2align 4, 0x90
.LBB0_391:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_392
.LBB0_383:  // Parent Loop BB0_382 Depth=1
    movl    (%rsi, %r14, 4), %r12d
    movl    %r12d, %ecx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r13d
    addl    %r14d, %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jl      .LBB0_385
    movl    %eax, %ecx
.LBB0_385:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r13d, %r13d
    js      .LBB0_387
    movl    %ecx, %r15d
.LBB0_387:
    shrl    $24, %r12d
    vcvtsi2ss %r12d, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %ecx
    addl    %ebx, %ecx
    movl    %ecx, %r12d
    cmpl    %r9d, %ecx
    jl      .LBB0_389
    movl    %r9d, %r12d
.LBB0_389:
    testl   %ecx, %ecx
    js      .LBB0_391
    movl    %r12d, %ebp
    jmp     .LBB0_391
.LBB0_122:
    cmpl    $3, %r9d
    ja      .LBB0_480
    movl    %r9d, %eax
    leaq    .LJTI0_3(%rip), %rcx
    movslq  (%rcx, %rax, 4), %rax
    addq    %rcx, %rax
    jmpq    *%rax
.LBB0_124:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %r11d
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_126
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    xorl    %ebx, %ebx
    vpmovsxbd .LCPI0_10(%rip), %xmm1
    vpmovzxbd .LCPI0_9(%rip), %xmm2
    vbroadcastss .LCPI0_1(%rip), %xmm3
    vbroadcastss .LCPI0_2(%rip), %xmm4
    vpxor   %xmm5, %xmm5, %xmm5
    jmp     .LBB0_143
.p2align 4, 0x90
.LBB0_153:
    incq    %rbx
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_143:
                                        // Child Loop BB0_144 Depth 2
    vmovd   %ebx, %xmm6
    xorl    %r14d, %r14d
    jmp     .LBB0_144
.p2align 4, 0x90
.LBB0_152:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_153
.LBB0_144:  // Parent Loop BB0_143 Depth=1
    vpbroadcastd (%rsi, %r14, 4), %xmm7
    vpsrlvd %xmm1, %xmm7, %xmm7
    vpand   %xmm2, %xmm7, %xmm7
    vcvtdq2ps %xmm7, %xmm7
    vdivps  %xmm3, %xmm7, %xmm7
    vaddps  %xmm4, %xmm7, %xmm7
    vmulps  %xmm0, %xmm7, %xmm7
    vcvttps2dq %xmm7, %xmm7
    vpinsrd $1, %r14d, %xmm6, %xmm8
    vpaddd  %xmm7, %xmm8, %xmm7
    vpextrd $1, %xmm7, %r13d
    cmpl    %r11d, %r13d
    jl      .LBB0_146
    movl    %r11d, %r13d
.LBB0_146:
    vpcmpgtd %zmm7, %zmm5, %k0
    kmovw   %k0, %r12d
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testb   $2, %r12b
    je      .LBB0_147
    vmovd   %xmm7, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_149
.LBB0_150:
    testb   $1, %r12b
    jne     .LBB0_152
    jmp     .LBB0_151
.p2align 4, 0x90
.LBB0_147:
    movl    %r13d, %r15d
    vmovd   %xmm7, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_150
.LBB0_149:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_152
.LBB0_151:
    movl    %ecx, %ebp
    jmp     .LBB0_152
.LBB0_304:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_306
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_322
.p2align 4, 0x90
.LBB0_332:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_322:
                                        // Child Loop BB0_323 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_323
.p2align 4, 0x90
.LBB0_331:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_332
.LBB0_323:  // Parent Loop BB0_322 Depth=1
    movzbl  (%rsi, %r14, 4), %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r15d
    leal    (%r14, %r15), %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jge     .LBB0_324
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    jns     .LBB0_326
.LBB0_327:
    addl    %ebx, %r15d
    movl    %r15d, %ecx
    cmpl    %r9d, %r15d
    jge     .LBB0_328
.LBB0_329:
    testl   %r15d, %r15d
    js      .LBB0_331
    jmp     .LBB0_330
.p2align 4, 0x90
.LBB0_324:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    js      .LBB0_327
.LBB0_326:
    movl    %ecx, %r12d
    addl    %ebx, %r15d
    movl    %r15d, %ecx
    cmpl    %r9d, %r15d
    jl      .LBB0_329
.LBB0_328:
    movl    %r9d, %ecx
    testl   %r15d, %r15d
    js      .LBB0_331
.LBB0_330:
    movl    %ecx, %ebp
    jmp     .LBB0_331
.LBB0_333:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_335
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_351
.p2align 4, 0x90
.LBB0_361:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_351:
                                        // Child Loop BB0_352 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_352
.p2align 4, 0x90
.LBB0_360:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_361
.LBB0_352:  // Parent Loop BB0_351 Depth=1
    movl    (%rsi, %r14, 4), %r12d
    movl    %r12d, %ecx
    shrl    $24, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r13d
    addl    %r14d, %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jl      .LBB0_354
    movl    %eax, %ecx
.LBB0_354:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r13d, %r13d
    js      .LBB0_356
    movl    %ecx, %r15d
.LBB0_356:
    movzbl  %r12b, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %ecx
    addl    %ebx, %ecx
    movl    %ecx, %r12d
    cmpl    %r9d, %ecx
    jl      .LBB0_358
    movl    %r9d, %r12d
.LBB0_358:
    testl   %ecx, %ecx
    js      .LBB0_360
    movl    %r12d, %ebp
    jmp     .LBB0_360
.LBB0_422:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_424
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_440
.p2align 4, 0x90
.LBB0_450:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_440:
                                        // Child Loop BB0_441 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_441
.p2align 4, 0x90
.LBB0_449:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_450
.LBB0_441:  // Parent Loop BB0_440 Depth=1
    movl    (%rsi, %r14, 4), %r12d
    movzbl  %r12b, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r13d
    addl    %r14d, %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jl      .LBB0_443
    movl    %eax, %ecx
.LBB0_443:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r13d, %r13d
    js      .LBB0_445
    movl    %ecx, %r15d
.LBB0_445:
    shrl    $24, %r12d
    vcvtsi2ss %r12d, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %ecx
    addl    %ebx, %ecx
    movl    %ecx, %r12d
    cmpl    %r9d, %ecx
    jl      .LBB0_447
    movl    %r9d, %r12d
.LBB0_447:
    testl   %ecx, %ecx
    js      .LBB0_449
    movl    %r12d, %ebp
    jmp     .LBB0_449
.LBB0_63:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %r11d
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_65
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_9(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    vpxor   %xmm4, %xmm4, %xmm4
    jmp     .LBB0_82
.p2align 4, 0x90
.LBB0_92:
    incq    %rbx
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_82:
                                        // Child Loop BB0_83 Depth 2
    vmovd   %ebx, %xmm5
    xorl    %r14d, %r14d
    jmp     .LBB0_83
.p2align 4, 0x90
.LBB0_91:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_92
.LBB0_83:  // Parent Loop BB0_82 Depth=1
    movl    (%rsi, %r14, 4), %ecx
    movl    %ecx, %ebp
    shrl    $16, %ebp
    vmovd   %ebp, %xmm6
    vpinsrd $1, %ecx, %xmm6, %xmm6
    vpand   %xmm1, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm2, %xmm6, %xmm6
    vaddps  %xmm3, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r14d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %r13d
    cmpl    %r11d, %r13d
    jl      .LBB0_85
    movl    %r11d, %r13d
.LBB0_85:
    vpcmpgtd %zmm6, %zmm4, %k0
    kmovw   %k0, %r12d
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testb   $2, %r12b
    je      .LBB0_86
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_88
.LBB0_89:
    testb   $1, %r12b
    jne     .LBB0_91
    jmp     .LBB0_90
.p2align 4, 0x90
.LBB0_86:
    movl    %r13d, %r15d
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_89
.LBB0_88:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_91
.LBB0_90:
    movl    %ecx, %ebp
    jmp     .LBB0_91
.LBB0_274:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %r11d
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_276
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_9(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    vpxor   %xmm4, %xmm4, %xmm4
    jmp     .LBB0_293
.p2align 4, 0x90
.LBB0_303:
    incq    %rbx
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_293:
                                        // Child Loop BB0_294 Depth 2
    vmovd   %ebx, %xmm5
    xorl    %r14d, %r14d
    jmp     .LBB0_294
.p2align 4, 0x90
.LBB0_302:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_303
.LBB0_294:  // Parent Loop BB0_293 Depth=1
    movl    (%rsi, %r14, 4), %ecx
    vmovd   %ecx, %xmm6
    shrl    $8, %ecx
    vpinsrd $1, %ecx, %xmm6, %xmm6
    vpand   %xmm1, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm2, %xmm6, %xmm6
    vaddps  %xmm3, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r14d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %r13d
    cmpl    %r11d, %r13d
    jl      .LBB0_296
    movl    %r11d, %r13d
.LBB0_296:
    vpcmpgtd %zmm6, %zmm4, %k0
    kmovw   %k0, %r12d
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testb   $2, %r12b
    je      .LBB0_297
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_299
.LBB0_300:
    testb   $1, %r12b
    jne     .LBB0_302
    jmp     .LBB0_301
.p2align 4, 0x90
.LBB0_297:
    movl    %r13d, %r15d
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_300
.LBB0_299:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_302
.LBB0_301:
    movl    %ecx, %ebp
    jmp     .LBB0_302
.LBB0_183:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %r11d
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_185
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    xorl    %ebx, %ebx
    vpmovzxbd .LCPI0_9(%rip), %xmm1
    vbroadcastss .LCPI0_1(%rip), %xmm2
    vbroadcastss .LCPI0_2(%rip), %xmm3
    vpxor   %xmm4, %xmm4, %xmm4
    jmp     .LBB0_202
.p2align 4, 0x90
.LBB0_212:
    incq    %rbx
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_202:
                                        // Child Loop BB0_203 Depth 2
    vmovd   %ebx, %xmm5
    xorl    %r14d, %r14d
    jmp     .LBB0_203
.p2align 4, 0x90
.LBB0_211:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_212
.LBB0_203:  // Parent Loop BB0_202 Depth=1
    movl    (%rsi, %r14, 4), %ecx
    movl    %ecx, %ebp
    shrl    $8, %ebp
    vmovd   %ebp, %xmm6
    vpinsrd $1, %ecx, %xmm6, %xmm6
    vpand   %xmm1, %xmm6, %xmm6
    vcvtdq2ps %xmm6, %xmm6
    vdivps  %xmm2, %xmm6, %xmm6
    vaddps  %xmm3, %xmm6, %xmm6
    vmulps  %xmm0, %xmm6, %xmm6
    vcvttps2dq %xmm6, %xmm6
    vpinsrd $1, %r14d, %xmm5, %xmm7
    vpaddd  %xmm6, %xmm7, %xmm6
    vpextrd $1, %xmm6, %r13d
    cmpl    %r11d, %r13d
    jl      .LBB0_205
    movl    %r11d, %r13d
.LBB0_205:
    vpcmpgtd %zmm6, %zmm4, %k0
    kmovw   %k0, %r12d
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testb   $2, %r12b
    je      .LBB0_206
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_208
.LBB0_209:
    testb   $1, %r12b
    jne     .LBB0_211
    jmp     .LBB0_210
.p2align 4, 0x90
.LBB0_206:
    movl    %r13d, %r15d
    vmovd   %xmm6, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_209
.LBB0_208:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_211
.LBB0_210:
    movl    %ecx, %ebp
    jmp     .LBB0_211
.LBB0_451:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_453
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_469
.p2align 4, 0x90
.LBB0_479:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_469:
                                        // Child Loop BB0_470 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_470
.p2align 4, 0x90
.LBB0_478:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_479
.LBB0_470:  // Parent Loop BB0_469 Depth=1
    movzbl  3(%rsi, %r14, 4), %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r15d
    leal    (%r14, %r15), %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jge     .LBB0_471
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    jns     .LBB0_473
.LBB0_474:
    addl    %ebx, %r15d
    movl    %r15d, %ecx
    cmpl    %r9d, %r15d
    jge     .LBB0_475
.LBB0_476:
    testl   %r15d, %r15d
    js      .LBB0_478
    jmp     .LBB0_477
.p2align 4, 0x90
.LBB0_471:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    js      .LBB0_474
.LBB0_473:
    movl    %ecx, %r12d
    addl    %ebx, %r15d
    movl    %r15d, %ecx
    cmpl    %r9d, %r15d
    jl      .LBB0_476
.LBB0_475:
    movl    %r9d, %ecx
    testl   %r15d, %r15d
    js      .LBB0_478
.LBB0_477:
    movl    %ecx, %ebp
    jmp     .LBB0_478
.LBB0_93:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_95
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_111
.p2align 4, 0x90
.LBB0_121:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_111:
                                        // Child Loop BB0_112 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_112
.p2align 4, 0x90
.LBB0_120:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_121
.LBB0_112:  // Parent Loop BB0_111 Depth=1
    movl    (%rsi, %r14, 4), %r12d
    movl    %r12d, %ecx
    shrl    $24, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r13d
    addl    %r14d, %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jl      .LBB0_114
    movl    %eax, %ecx
.LBB0_114:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r13d, %r13d
    js      .LBB0_116
    movl    %ecx, %r15d
.LBB0_116:
    shrl    $16, %r12d
    movzbl  %r12b, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %ecx
    addl    %ebx, %ecx
    movl    %ecx, %r12d
    cmpl    %r9d, %ecx
    jl      .LBB0_118
    movl    %r9d, %r12d
.LBB0_118:
    testl   %ecx, %ecx
    js      .LBB0_120
    movl    %r12d, %ebp
    jmp     .LBB0_120
.LBB0_393:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %r13d
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_395
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_411
.p2align 4, 0x90
.LBB0_421:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_411:
                                        // Child Loop BB0_412 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_412
.p2align 4, 0x90
.LBB0_420:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_421
.LBB0_412:  // Parent Loop BB0_411 Depth=1
    movl    (%rsi, %r14, 4), %eax
    movzbl  %ah, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r12d
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r13d, %r12d
    jl      .LBB0_414
    movl    %r13d, %ecx
.LBB0_414:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r12d, %r12d
    js      .LBB0_416
    movl    %ecx, %r15d
.LBB0_416:
    shrl    $24, %eax
    vcvtsi2ss %eax, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %eax
    addl    %ebx, %eax
    movl    %eax, %ecx
    cmpl    %r9d, %eax
    jl      .LBB0_418
    movl    %r9d, %ecx
.LBB0_418:
    testl   %eax, %eax
    js      .LBB0_420
    movl    %ecx, %ebp
    jmp     .LBB0_420
.LBB0_213:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %r13d
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_215
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_231
.p2align 4, 0x90
.LBB0_241:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_231:
                                        // Child Loop BB0_232 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_232
.p2align 4, 0x90
.LBB0_240:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_241
.LBB0_232:  // Parent Loop BB0_231 Depth=1
    movl    (%rsi, %r14, 4), %eax
    movl    %eax, %ecx
    shrl    $24, %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r12d
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r13d, %r12d
    jl      .LBB0_234
    movl    %r13d, %ecx
.LBB0_234:
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testl   %r12d, %r12d
    js      .LBB0_236
    movl    %ecx, %r15d
.LBB0_236:
    movzbl  %ah, %eax
    vcvtsi2ss %eax, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %eax
    addl    %ebx, %eax
    movl    %eax, %ecx
    cmpl    %r9d, %eax
    jl      .LBB0_238
    movl    %r9d, %ecx
.LBB0_238:
    testl   %eax, %eax
    js      .LBB0_240
    movl    %ecx, %ebp
    jmp     .LBB0_240
.LBB0_33:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %rax
    leal    -1(%rax), %r11d
    leal    -1(%r8), %r9d
    cmpl    $16, %eax
    jge     .LBB0_35
    testl   %eax, %eax
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rax
    xorl    %ebx, %ebx
    vpmovsxbd .LCPI0_11(%rip), %xmm1
    vpmovzxbd .LCPI0_9(%rip), %xmm2
    vbroadcastss .LCPI0_1(%rip), %xmm3
    vbroadcastss .LCPI0_2(%rip), %xmm4
    vpxor   %xmm5, %xmm5, %xmm5
    jmp     .LBB0_52
.p2align 4, 0x90
.LBB0_62:
    incq    %rbx
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_52:
                                        // Child Loop BB0_53 Depth 2
    vmovd   %ebx, %xmm6
    xorl    %r14d, %r14d
    jmp     .LBB0_53
.p2align 4, 0x90
.LBB0_61:
    imull   -16(%rsp), %ebp
    addl    %r15d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_62
.LBB0_53:  // Parent Loop BB0_52 Depth=1
    vpbroadcastd (%rsi, %r14, 4), %xmm7
    vpsrlvd %xmm1, %xmm7, %xmm7
    vpand   %xmm2, %xmm7, %xmm7
    vcvtdq2ps %xmm7, %xmm7
    vdivps  %xmm3, %xmm7, %xmm7
    vaddps  %xmm4, %xmm7, %xmm7
    vmulps  %xmm0, %xmm7, %xmm7
    vcvttps2dq %xmm7, %xmm7
    vpinsrd $1, %r14d, %xmm6, %xmm8
    vpaddd  %xmm7, %xmm8, %xmm7
    vpextrd $1, %xmm7, %r13d
    cmpl    %r11d, %r13d
    jl      .LBB0_55
    movl    %r11d, %r13d
.LBB0_55:
    vpcmpgtd %zmm7, %zmm5, %k0
    kmovw   %k0, %r12d
    xorl    %ebp, %ebp
    movl    $0, %r15d
    testb   $2, %r12b
    je      .LBB0_56
    vmovd   %xmm7, %ecx
    cmpl    %r9d, %ecx
    jge     .LBB0_58
.LBB0_59:
    testb   $1, %r12b
    jne     .LBB0_61
    jmp     .LBB0_60
.p2align 4, 0x90
.LBB0_56:
    movl    %r13d, %r15d
    vmovd   %xmm7, %ecx
    cmpl    %r9d, %ecx
    jl      .LBB0_59
.LBB0_58:
    movl    %r9d, %ecx
    testb   $1, %r12b
    jne     .LBB0_61
.LBB0_60:
    movl    %ecx, %ebp
    jmp     .LBB0_61
.LBB0_154:
    testl   %r8d, %r8d
    jle     .LBB0_480
    movq    -16(%rsp), %r11
    leal    -1(%r11), %eax
    leal    -1(%r8), %r9d
    cmpl    $16, %r11d
    jge     .LBB0_156
    testl   %r11d, %r11d
    jle     .LBB0_480
    movl    -16(%rsp), %r10d
    movl    %r8d, %r8d
    leaq    (, %r10, 4), %r11
    xorl    %ebx, %ebx
    vmovss  .LCPI0_1(%rip), %xmm1
    vmovss  .LCPI0_2(%rip), %xmm2
    jmp     .LBB0_172
.p2align 4, 0x90
.LBB0_182:
    incq    %rbx
    addq    %r11, %rdx
    addq    %r11, %rsi
    cmpq    %r8, %rbx
    je      .LBB0_480
.LBB0_172:
                                        // Child Loop BB0_173 Depth 2
    xorl    %r14d, %r14d
    jmp     .LBB0_173
.p2align 4, 0x90
.LBB0_181:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r14, 4)
    incq    %r14
    cmpq    %r14, %r10
    je      .LBB0_182
.LBB0_173:  // Parent Loop BB0_172 Depth=1
    movzbl  1(%rsi, %r14, 4), %ecx
    vcvtsi2ss %ecx, %xmm4, %xmm3
    vdivss  %xmm1, %xmm3, %xmm3
    vaddss  %xmm2, %xmm3, %xmm3
    vmulss  %xmm0, %xmm3, %xmm3
    vcvttss2si %xmm3, %r15d
    leal    (%r14, %r15), %r13d
    movl    %r13d, %ecx
    cmpl    %eax, %r13d
    jge     .LBB0_174
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    jns     .LBB0_176
.LBB0_177:
    addl    %ebx, %r15d
    movl    %r15d, %ecx
    cmpl    %r9d, %r15d
    jge     .LBB0_178
.LBB0_179:
    testl   %r15d, %r15d
    js      .LBB0_181
    jmp     .LBB0_180
.p2align 4, 0x90
.LBB0_174:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r13d, %r13d
    js      .LBB0_177
.LBB0_176:
    movl    %ecx, %r12d
    addl    %ebx, %r15d
    movl    %r15d, %ecx
    cmpl    %r9d, %r15d
    jl      .LBB0_179
.LBB0_178:
    movl    %r9d, %ecx
    testl   %r15d, %r15d
    js      .LBB0_181
.LBB0_180:
    movl    %ecx, %ebp
    jmp     .LBB0_181
.LBB0_306:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vpbroadcastd .LCPI0_5(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_307
.p2align 4, 0x90
.LBB0_319:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_307:
                                        // Child Loop BB0_308 Depth 2
                                        // Child Loop BB0_310 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_308:  // Parent Loop BB0_307 Depth=1
    vpandq  -64(%rsi, %r15, 4), %zmm7, %zmm15
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vaddps  %zmm8, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm14, %zmm15, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpaddd  %zmm13, %zmm15, %zmm15
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    vpxord  %zmm16, %zmm16, %zmm16
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_308
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_310
    jmp     .LBB0_319
.p2align 4, 0x90
.LBB0_318:
    imull   -16(%rsp), %ebp
    addl    %r13d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_319
.LBB0_310:  // Parent Loop BB0_307 Depth=1
    movzbl  (%rsi, %r15, 4), %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r12d
    leal    (%r15, %r12), %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jge     .LBB0_311
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    jns     .LBB0_313
.LBB0_314:
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r9d, %r12d
    jge     .LBB0_315
.LBB0_316:
    testl   %r12d, %r12d
    js      .LBB0_318
    jmp     .LBB0_317
.p2align 4, 0x90
.LBB0_311:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    js      .LBB0_314
.LBB0_313:
    movl    %ecx, %r13d
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r9d, %r12d
    jl      .LBB0_316
.LBB0_315:
    movl    %r9d, %ecx
    testl   %r12d, %r12d
    js      .LBB0_318
.LBB0_317:
    movl    %ecx, %ebp
    jmp     .LBB0_318
.LBB0_335:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpbroadcastd .LCPI0_5(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_336
.p2align 4, 0x90
.LBB0_348:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_336:
                                        // Child Loop BB0_337 Depth 2
                                        // Child Loop BB0_339 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_337:  // Parent Loop BB0_336 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm15
    vpsrld  $24, %zmm15, %zmm16
    vcvtdq2ps %zmm16, %zmm16
    vdivps  %zmm6, %zmm16, %zmm16
    vaddps  %zmm7, %zmm16, %zmm16
    vpandq  %zmm8, %zmm15, %zmm15
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vmulps  %zmm16, %zmm1, %zmm16
    vaddps  %zmm7, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm16, %zmm16
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm13, %zmm15, %zmm15
    vpaddd  %zmm14, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    vpxord  %zmm16, %zmm16, %zmm16
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_337
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_339
    jmp     .LBB0_348
.p2align 4, 0x90
.LBB0_347:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_348
.LBB0_339:  // Parent Loop BB0_336 Depth=1
    movl    (%rsi, %r15, 4), %r13d
    movl    %r13d, %ecx
    shrl    $24, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r8d
    addl    %r15d, %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jl      .LBB0_341
    movl    %eax, %ecx
.LBB0_341:
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r8d, %r8d
    js      .LBB0_343
    movl    %ecx, %r12d
.LBB0_343:
    movzbl  %r13b, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %ecx
    addl    %r14d, %ecx
    movl    %ecx, %r8d
    cmpl    %r9d, %ecx
    jl      .LBB0_345
    movl    %r9d, %r8d
.LBB0_345:
    testl   %ecx, %ecx
    js      .LBB0_347
    movl    %r8d, %ebp
    jmp     .LBB0_347
.LBB0_424:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vpbroadcastd .LCPI0_5(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_425
.p2align 4, 0x90
.LBB0_437:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_425:
                                        // Child Loop BB0_426 Depth 2
                                        // Child Loop BB0_428 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_426:  // Parent Loop BB0_425 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm15
    vpsrld  $24, %zmm15, %zmm16
    vpandq  %zmm7, %zmm15, %zmm15
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vaddps  %zmm8, %zmm15, %zmm15
    vcvtdq2ps %zmm16, %zmm16
    vdivps  %zmm6, %zmm16, %zmm16
    vmulps  %zmm15, %zmm1, %zmm15
    vaddps  %zmm8, %zmm16, %zmm16
    vmulps  %zmm16, %zmm1, %zmm16
    vcvttps2dq %zmm15, %zmm15
    vcvttps2dq %zmm16, %zmm16
    vpaddd  %zmm13, %zmm16, %zmm16
    vpaddd  %zmm14, %zmm15, %zmm15
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm2, %zmm15, %zmm15
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm3, %zmm16, %zmm16
    vpmulld %zmm4, %zmm16, %zmm16
    vpaddd  %zmm15, %zmm16, %zmm15
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm16, %zmm16, %zmm16
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_426
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_428
    jmp     .LBB0_437
.p2align 4, 0x90
.LBB0_436:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_437
.LBB0_428:  // Parent Loop BB0_425 Depth=1
    movl    (%rsi, %r15, 4), %r13d
    movzbl  %r13b, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r8d
    addl    %r15d, %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jl      .LBB0_430
    movl    %eax, %ecx
.LBB0_430:
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r8d, %r8d
    js      .LBB0_432
    movl    %ecx, %r12d
.LBB0_432:
    shrl    $24, %r13d
    vcvtsi2ss %r13d, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %ecx
    addl    %r14d, %ecx
    movl    %ecx, %r8d
    cmpl    %r9d, %ecx
    jl      .LBB0_434
    movl    %r9d, %r8d
.LBB0_434:
    testl   %ecx, %ecx
    js      .LBB0_436
    movl    %r8d, %ebp
    jmp     .LBB0_436
.LBB0_246:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r11d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movq    %rax, -8(%rsp)
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_5(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpmovsxbd .LCPI0_12(%rip), %zmm17
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm13
    vpxor   %xmm14, %xmm14, %xmm14
    movq    -16(%rsp), %rcx
    jmp     .LBB0_247
.p2align 4, 0x90
.LBB0_260:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    %r8, %r14
    je      .LBB0_480
.LBB0_247:
                                        // Child Loop BB0_248 Depth 2
                                        // Child Loop BB0_251 Depth 2
    vpbroadcastd %r14d, %zmm15
    movl    $16, %r15d
    vmovdqa64 %zmm17, %zmm16
.p2align 4, 0x90
.LBB0_248:  // Parent Loop BB0_247 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm8
    vpsrld  $16, %zmm8, %zmm18
    vpandd  %zmm5, %zmm18, %zmm18
    vcvtdq2ps %zmm18, %zmm18
    vdivps  %zmm6, %zmm18, %zmm18
    vaddps  %zmm7, %zmm18, %zmm18
    vpandq  %zmm5, %zmm8, %zmm8
    vcvtdq2ps %zmm8, %zmm8
    vdivps  %zmm6, %zmm8, %zmm8
    vmulps  %zmm18, %zmm1, %zmm18
    vaddps  %zmm7, %zmm8, %zmm8
    vmulps  %zmm8, %zmm1, %zmm8
    vcvttps2dq %zmm18, %zmm18
    vcvttps2dq %zmm8, %zmm8
    vpaddd  %zmm15, %zmm8, %zmm8
    vpaddd  %zmm16, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm18, %zmm18
    vpminsd %zmm2, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm8, %zmm8
    vpminsd %zmm3, %zmm8, %zmm8
    vpmulld %zmm4, %zmm8, %zmm8
    vpaddd  %zmm18, %zmm8, %zmm8
    vpxord  %zmm18, %zmm18, %zmm18
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm8, 4), %zmm18 {%k1}
    vmovdqu64 %zmm18, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm16, %zmm16
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_248
    cmpl    %ecx, -8(%rsp)
    je      .LBB0_260
    vmovd   %r14d, %xmm15
    movq    -8(%rsp), %r15
    jmp     .LBB0_251
.p2align 4, 0x90
.LBB0_259:
    imull   %ecx, %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_260
.LBB0_251:  // Parent Loop BB0_247 Depth=1
    movl    (%rsi, %r15, 4), %eax
    vmovd   %eax, %xmm8
    shrl    $16, %eax
    vpinsrd $1, %eax, %xmm8, %xmm8
    vpand   .LCPI0_6(%rip), %xmm8, %xmm8
    vcvtdq2ps %xmm8, %xmm8
    vdivps  %xmm12, %xmm8, %xmm8
    vaddps  %xmm13, %xmm8, %xmm8
    vmulps  %xmm0, %xmm8, %xmm8
    vcvttps2dq %xmm8, %xmm8
    vpinsrd $1, %r15d, %xmm15, %xmm11
    vpaddd  %xmm8, %xmm11, %xmm8
    vpextrd $1, %xmm8, %eax
    cmpl    %r11d, %eax
    jl      .LBB0_253
    movl    %r11d, %eax
.LBB0_253:
    vpcmpgtd %zmm8, %zmm14, %k0
    kmovw   %k0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testb   $2, %r13b
    je      .LBB0_254
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_256
.LBB0_257:
    testb   $1, %r13b
    jne     .LBB0_259
    jmp     .LBB0_258
.p2align 4, 0x90
.LBB0_254:
    movl    %eax, %r12d
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_257
.LBB0_256:
    movl    %r9d, %eax
    testb   $1, %r13b
    jne     .LBB0_259
.LBB0_258:
    movl    %eax, %ebp
    jmp     .LBB0_259
.LBB0_65:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r11d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movq    %rax, -8(%rsp)
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_5(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpmovsxbd .LCPI0_12(%rip), %zmm17
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm13
    vpxor   %xmm14, %xmm14, %xmm14
    jmp     .LBB0_66
.p2align 4, 0x90
.LBB0_79:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    %r8, %r14
    je      .LBB0_480
.LBB0_66:
                                        // Child Loop BB0_67 Depth 2
                                        // Child Loop BB0_70 Depth 2
    vpbroadcastd %r14d, %zmm15
    movl    $16, %r15d
    vmovdqa64 %zmm17, %zmm16
.p2align 4, 0x90
.LBB0_67:  // Parent Loop BB0_66 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm8
    vpandq  %zmm5, %zmm8, %zmm18
    vcvtdq2ps %zmm18, %zmm18
    vdivps  %zmm6, %zmm18, %zmm18
    vpsrld  $16, %zmm8, %zmm8
    vaddps  %zmm7, %zmm18, %zmm18
    vpandd  %zmm5, %zmm8, %zmm8
    vcvtdq2ps %zmm8, %zmm8
    vdivps  %zmm6, %zmm8, %zmm8
    vmulps  %zmm18, %zmm1, %zmm18
    vaddps  %zmm7, %zmm8, %zmm8
    vmulps  %zmm8, %zmm1, %zmm8
    vcvttps2dq %zmm18, %zmm18
    vcvttps2dq %zmm8, %zmm8
    vpaddd  %zmm15, %zmm8, %zmm8
    vpaddd  %zmm16, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm18, %zmm18
    vpminsd %zmm2, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm8, %zmm8
    vpminsd %zmm3, %zmm8, %zmm8
    vpmulld %zmm4, %zmm8, %zmm8
    vpaddd  %zmm18, %zmm8, %zmm8
    vpxord  %zmm18, %zmm18, %zmm18
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm8, 4), %zmm18 {%k1}
    vmovdqu64 %zmm18, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm16, %zmm16
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_67
    movq    -8(%rsp), %rax
    cmpl    -16(%rsp), %eax
    je      .LBB0_79
    vmovd   %r14d, %xmm15
    movq    -8(%rsp), %r15
    jmp     .LBB0_70
.p2align 4, 0x90
.LBB0_78:
    imull   %ecx, %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_79
.LBB0_70:  // Parent Loop BB0_66 Depth=1
    movl    (%rsi, %r15, 4), %eax
    movl    %eax, %ecx
    shrl    $16, %ecx
    vmovd   %ecx, %xmm8
    vpinsrd $1, %eax, %xmm8, %xmm8
    vpand   .LCPI0_6(%rip), %xmm8, %xmm8
    vcvtdq2ps %xmm8, %xmm8
    vdivps  %xmm12, %xmm8, %xmm8
    vaddps  %xmm13, %xmm8, %xmm8
    vmulps  %xmm0, %xmm8, %xmm8
    vcvttps2dq %xmm8, %xmm8
    vpinsrd $1, %r15d, %xmm15, %xmm11
    vpaddd  %xmm8, %xmm11, %xmm8
    vpextrd $1, %xmm8, %eax
    cmpl    %r11d, %eax
    jl      .LBB0_72
    movl    %r11d, %eax
.LBB0_72:
    vpcmpgtd %zmm8, %zmm14, %k0
    kmovw   %k0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testb   $2, %r13b
    je      .LBB0_73
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    movq    -16(%rsp), %rcx
    jge     .LBB0_75
.LBB0_76:
    testb   $1, %r13b
    jne     .LBB0_78
    jmp     .LBB0_77
.p2align 4, 0x90
.LBB0_73:
    movl    %eax, %r12d
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    movq    -16(%rsp), %rcx
    jl      .LBB0_76
.LBB0_75:
    movl    %r9d, %eax
    testb   $1, %r13b
    jne     .LBB0_78
.LBB0_77:
    movl    %eax, %ebp
    jmp     .LBB0_78
.LBB0_276:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r11d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movq    %rax, -8(%rsp)
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_5(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpmovsxbd .LCPI0_12(%rip), %zmm17
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm13
    vpxor   %xmm14, %xmm14, %xmm14
    movq    -16(%rsp), %rcx
    jmp     .LBB0_277
.p2align 4, 0x90
.LBB0_290:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    %r8, %r14
    je      .LBB0_480
.LBB0_277:
                                        // Child Loop BB0_278 Depth 2
                                        // Child Loop BB0_281 Depth 2
    vpbroadcastd %r14d, %zmm15
    movl    $16, %r15d
    vmovdqa64 %zmm17, %zmm16
.p2align 4, 0x90
.LBB0_278:  // Parent Loop BB0_277 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm8
    vpsrld  $8, %zmm8, %zmm18
    vpandd  %zmm5, %zmm18, %zmm18
    vcvtdq2ps %zmm18, %zmm18
    vdivps  %zmm6, %zmm18, %zmm18
    vaddps  %zmm7, %zmm18, %zmm18
    vpandq  %zmm5, %zmm8, %zmm8
    vcvtdq2ps %zmm8, %zmm8
    vdivps  %zmm6, %zmm8, %zmm8
    vmulps  %zmm18, %zmm1, %zmm18
    vaddps  %zmm7, %zmm8, %zmm8
    vmulps  %zmm8, %zmm1, %zmm8
    vcvttps2dq %zmm18, %zmm18
    vcvttps2dq %zmm8, %zmm8
    vpaddd  %zmm15, %zmm8, %zmm8
    vpaddd  %zmm16, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm18, %zmm18
    vpminsd %zmm2, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm8, %zmm8
    vpminsd %zmm3, %zmm8, %zmm8
    vpmulld %zmm4, %zmm8, %zmm8
    vpaddd  %zmm18, %zmm8, %zmm8
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm18, %zmm18, %zmm18
    vpgatherdd (%rdi, %zmm8, 4), %zmm18 {%k1}
    vmovdqu64 %zmm18, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm16, %zmm16
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_278
    cmpl    %ecx, -8(%rsp)
    je      .LBB0_290
    vmovd   %r14d, %xmm15
    movq    -8(%rsp), %r15
    jmp     .LBB0_281
.p2align 4, 0x90
.LBB0_289:
    imull   %ecx, %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_290
.LBB0_281:  // Parent Loop BB0_277 Depth=1
    movl    (%rsi, %r15, 4), %eax
    vmovd   %eax, %xmm8
    shrl    $8, %eax
    vpinsrd $1, %eax, %xmm8, %xmm8
    vpand   .LCPI0_6(%rip), %xmm8, %xmm8
    vcvtdq2ps %xmm8, %xmm8
    vdivps  %xmm12, %xmm8, %xmm8
    vaddps  %xmm13, %xmm8, %xmm8
    vmulps  %xmm0, %xmm8, %xmm8
    vcvttps2dq %xmm8, %xmm8
    vpinsrd $1, %r15d, %xmm15, %xmm11
    vpaddd  %xmm8, %xmm11, %xmm8
    vpextrd $1, %xmm8, %eax
    cmpl    %r11d, %eax
    jl      .LBB0_283
    movl    %r11d, %eax
.LBB0_283:
    vpcmpgtd %zmm8, %zmm14, %k0
    kmovw   %k0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testb   $2, %r13b
    je      .LBB0_284
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_286
.LBB0_287:
    testb   $1, %r13b
    jne     .LBB0_289
    jmp     .LBB0_288
.p2align 4, 0x90
.LBB0_284:
    movl    %eax, %r12d
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_287
.LBB0_286:
    movl    %r9d, %eax
    testb   $1, %r13b
    jne     .LBB0_289
.LBB0_288:
    movl    %eax, %ebp
    jmp     .LBB0_289
.LBB0_185:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r11d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movq    %rax, -8(%rsp)
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpbroadcastd .LCPI0_5(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpmovsxbd .LCPI0_12(%rip), %zmm17
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vbroadcastss .LCPI0_1(%rip), %xmm12
    vbroadcastss .LCPI0_2(%rip), %xmm13
    vpxor   %xmm14, %xmm14, %xmm14
    jmp     .LBB0_186
.p2align 4, 0x90
.LBB0_199:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    %r8, %r14
    je      .LBB0_480
.LBB0_186:
                                        // Child Loop BB0_187 Depth 2
                                        // Child Loop BB0_190 Depth 2
    vpbroadcastd %r14d, %zmm15
    movl    $16, %r15d
    vmovdqa64 %zmm17, %zmm16
.p2align 4, 0x90
.LBB0_187:  // Parent Loop BB0_186 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm8
    vpandq  %zmm5, %zmm8, %zmm18
    vcvtdq2ps %zmm18, %zmm18
    vdivps  %zmm6, %zmm18, %zmm18
    vpsrld  $8, %zmm8, %zmm8
    vaddps  %zmm7, %zmm18, %zmm18
    vpandd  %zmm5, %zmm8, %zmm8
    vcvtdq2ps %zmm8, %zmm8
    vdivps  %zmm6, %zmm8, %zmm8
    vmulps  %zmm18, %zmm1, %zmm18
    vaddps  %zmm7, %zmm8, %zmm8
    vmulps  %zmm8, %zmm1, %zmm8
    vcvttps2dq %zmm18, %zmm18
    vcvttps2dq %zmm8, %zmm8
    vpaddd  %zmm15, %zmm8, %zmm8
    vpaddd  %zmm16, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm18, %zmm18
    vpminsd %zmm2, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm8, %zmm8
    vpminsd %zmm3, %zmm8, %zmm8
    vpmulld %zmm4, %zmm8, %zmm8
    vpaddd  %zmm18, %zmm8, %zmm8
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm18, %zmm18, %zmm18
    vpgatherdd (%rdi, %zmm8, 4), %zmm18 {%k1}
    vmovdqu64 %zmm18, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm16, %zmm16
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_187
    movq    -8(%rsp), %rax
    cmpl    -16(%rsp), %eax
    je      .LBB0_199
    vmovd   %r14d, %xmm15
    movq    -8(%rsp), %r15
    jmp     .LBB0_190
.p2align 4, 0x90
.LBB0_198:
    imull   %ecx, %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_199
.LBB0_190:  // Parent Loop BB0_186 Depth=1
    movl    (%rsi, %r15, 4), %eax
    movl    %eax, %ecx
    shrl    $8, %ecx
    vmovd   %ecx, %xmm8
    vpinsrd $1, %eax, %xmm8, %xmm8
    vpand   .LCPI0_6(%rip), %xmm8, %xmm8
    vcvtdq2ps %xmm8, %xmm8
    vdivps  %xmm12, %xmm8, %xmm8
    vaddps  %xmm13, %xmm8, %xmm8
    vmulps  %xmm0, %xmm8, %xmm8
    vcvttps2dq %xmm8, %xmm8
    vpinsrd $1, %r15d, %xmm15, %xmm11
    vpaddd  %xmm8, %xmm11, %xmm8
    vpextrd $1, %xmm8, %eax
    cmpl    %r11d, %eax
    jl      .LBB0_192
    movl    %r11d, %eax
.LBB0_192:
    vpcmpgtd %zmm8, %zmm14, %k0
    kmovw   %k0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testb   $2, %r13b
    je      .LBB0_193
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    movq    -16(%rsp), %rcx
    jge     .LBB0_195
.LBB0_196:
    testb   $1, %r13b
    jne     .LBB0_198
    jmp     .LBB0_197
.p2align 4, 0x90
.LBB0_193:
    movl    %eax, %r12d
    vmovd   %xmm8, %eax
    cmpl    %r9d, %eax
    movq    -16(%rsp), %rcx
    jl      .LBB0_196
.LBB0_195:
    movl    %r9d, %eax
    testb   $1, %r13b
    jne     .LBB0_198
.LBB0_197:
    movl    %eax, %ebp
    jmp     .LBB0_198
.LBB0_453:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vbroadcastss .LCPI0_1(%rip), %zmm5
    vpmovsxbd .LCPI0_12(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpxor   %xmm8, %xmm8, %xmm8
    vpbroadcastd .LCPI0_3(%rip), %zmm9
    vmovss  .LCPI0_1(%rip), %xmm10
    vmovss  .LCPI0_2(%rip), %xmm11
    jmp     .LBB0_454
.p2align 4, 0x90
.LBB0_466:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_454:
                                        // Child Loop BB0_455 Depth 2
                                        // Child Loop BB0_457 Depth 2
    vpbroadcastd %r14d, %zmm12
    movl    $16, %r15d
    vmovdqa64 %zmm6, %zmm13
.p2align 4, 0x90
.LBB0_455:  // Parent Loop BB0_454 Depth=1
    vpsrld  $24, -64(%rsi, %r15, 4), %zmm14
    vcvtdq2ps %zmm14, %zmm14
    vdivps  %zmm5, %zmm14, %zmm14
    vaddps  %zmm7, %zmm14, %zmm14
    vmulps  %zmm14, %zmm1, %zmm14
    vcvttps2dq %zmm14, %zmm14
    vpaddd  %zmm13, %zmm14, %zmm15
    vpmaxsd %zmm8, %zmm15, %zmm15
    vpminsd %zmm2, %zmm15, %zmm15
    vpaddd  %zmm12, %zmm14, %zmm14
    vpmaxsd %zmm8, %zmm14, %zmm14
    vpminsd %zmm3, %zmm14, %zmm14
    vpmulld %zmm4, %zmm14, %zmm14
    vpaddd  %zmm15, %zmm14, %zmm14
    vpxor   %xmm15, %xmm15, %xmm15
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm14, 4), %zmm15 {%k1}
    vmovdqu64 %zmm15, -64(%rdx, %r15, 4)
    vpaddd  %zmm9, %zmm13, %zmm13
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_455
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_457
    jmp     .LBB0_466
.p2align 4, 0x90
.LBB0_465:
    imull   -16(%rsp), %ebp
    addl    %r13d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_466
.LBB0_457:  // Parent Loop BB0_454 Depth=1
    movzbl  3(%rsi, %r15, 4), %ecx
    vcvtsi2ss %ecx, %xmm16, %xmm12
    vdivss  %xmm10, %xmm12, %xmm12
    vaddss  %xmm11, %xmm12, %xmm12
    vmulss  %xmm0, %xmm12, %xmm12
    vcvttss2si %xmm12, %r12d
    leal    (%r15, %r12), %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jge     .LBB0_458
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    jns     .LBB0_460
.LBB0_461:
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r9d, %r12d
    jge     .LBB0_462
.LBB0_463:
    testl   %r12d, %r12d
    js      .LBB0_465
    jmp     .LBB0_464
.p2align 4, 0x90
.LBB0_458:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    js      .LBB0_461
.LBB0_460:
    movl    %ecx, %r13d
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r9d, %r12d
    jl      .LBB0_463
.LBB0_462:
    movl    %r9d, %ecx
    testl   %r12d, %r12d
    js      .LBB0_465
.LBB0_464:
    movl    %ecx, %ebp
    jmp     .LBB0_465
.LBB0_366:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vpbroadcastd .LCPI0_5(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_367
.p2align 4, 0x90
.LBB0_379:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_367:
                                        // Child Loop BB0_368 Depth 2
                                        // Child Loop BB0_370 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_368:  // Parent Loop BB0_367 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm15
    vpsrld  $16, %zmm15, %zmm16
    vpandd  %zmm7, %zmm16, %zmm16
    vpsrld  $24, %zmm15, %zmm15
    vcvtdq2ps %zmm16, %zmm16
    vdivps  %zmm6, %zmm16, %zmm16
    vaddps  %zmm8, %zmm16, %zmm16
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vmulps  %zmm16, %zmm1, %zmm16
    vaddps  %zmm8, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm16, %zmm16
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm13, %zmm15, %zmm15
    vpaddd  %zmm14, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm16, %zmm16, %zmm16
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_368
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_370
    jmp     .LBB0_379
.p2align 4, 0x90
.LBB0_378:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_379
.LBB0_370:  // Parent Loop BB0_367 Depth=1
    movl    (%rsi, %r15, 4), %r13d
    movl    %r13d, %ecx
    shrl    $16, %ecx
    movzbl  %cl, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r8d
    addl    %r15d, %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jl      .LBB0_372
    movl    %eax, %ecx
.LBB0_372:
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r8d, %r8d
    js      .LBB0_374
    movl    %ecx, %r12d
.LBB0_374:
    shrl    $24, %r13d
    vcvtsi2ss %r13d, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %ecx
    addl    %r14d, %ecx
    movl    %ecx, %r8d
    cmpl    %r9d, %ecx
    jl      .LBB0_376
    movl    %r9d, %r8d
.LBB0_376:
    testl   %ecx, %ecx
    js      .LBB0_378
    movl    %r8d, %ebp
    jmp     .LBB0_378
.LBB0_95:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpbroadcastd .LCPI0_5(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_96
.p2align 4, 0x90
.LBB0_108:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_96:
                                        // Child Loop BB0_97 Depth 2
                                        // Child Loop BB0_99 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_97:  // Parent Loop BB0_96 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm15
    vpsrld  $24, %zmm15, %zmm16
    vpsrld  $16, %zmm15, %zmm15
    vpandd  %zmm8, %zmm15, %zmm15
    vcvtdq2ps %zmm16, %zmm16
    vdivps  %zmm6, %zmm16, %zmm16
    vaddps  %zmm7, %zmm16, %zmm16
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vmulps  %zmm16, %zmm1, %zmm16
    vaddps  %zmm7, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm16, %zmm16
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm13, %zmm15, %zmm15
    vpaddd  %zmm14, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm16, %zmm16, %zmm16
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_97
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_99
    jmp     .LBB0_108
.p2align 4, 0x90
.LBB0_107:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_108
.LBB0_99:  // Parent Loop BB0_96 Depth=1
    movl    (%rsi, %r15, 4), %r13d
    movl    %r13d, %ecx
    shrl    $24, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r8d
    addl    %r15d, %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jl      .LBB0_101
    movl    %eax, %ecx
.LBB0_101:
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r8d, %r8d
    js      .LBB0_103
    movl    %ecx, %r12d
.LBB0_103:
    shrl    $16, %r13d
    movzbl  %r13b, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %ecx
    addl    %r14d, %ecx
    movl    %ecx, %r8d
    cmpl    %r9d, %ecx
    jl      .LBB0_105
    movl    %r9d, %r8d
.LBB0_105:
    testl   %ecx, %ecx
    js      .LBB0_107
    movl    %r8d, %ebp
    jmp     .LBB0_107
.LBB0_395:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r13d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %eax
    movq    %rax, -8(%rsp)
    leaq    (, %r10, 4), %rax
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vpbroadcastd .LCPI0_5(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_396
.p2align 4, 0x90
.LBB0_408:
    incq    %r14
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_396:
                                        // Child Loop BB0_397 Depth 2
                                        // Child Loop BB0_399 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_397:  // Parent Loop BB0_396 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm15
    vpsrld  $8, %zmm15, %zmm16
    vpandd  %zmm7, %zmm16, %zmm16
    vpsrld  $24, %zmm15, %zmm15
    vcvtdq2ps %zmm16, %zmm16
    vdivps  %zmm6, %zmm16, %zmm16
    vaddps  %zmm8, %zmm16, %zmm16
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vmulps  %zmm16, %zmm1, %zmm16
    vaddps  %zmm8, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm16, %zmm16
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm13, %zmm15, %zmm15
    vpaddd  %zmm14, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    vpxord  %zmm16, %zmm16, %zmm16
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_397
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_399
    jmp     .LBB0_408
.p2align 4, 0x90
.LBB0_407:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_408
.LBB0_399:  // Parent Loop BB0_396 Depth=1
    movl    (%rsi, %r15, 4), %ebx
    movzbl  %bh, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r8d
    addl    %r15d, %r8d
    movl    %r8d, %ecx
    cmpl    %r13d, %r8d
    jl      .LBB0_401
    movl    %r13d, %ecx
.LBB0_401:
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r8d, %r8d
    js      .LBB0_403
    movl    %ecx, %r12d
.LBB0_403:
    shrl    $24, %ebx
    vcvtsi2ss %ebx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %ecx
    addl    %r14d, %ecx
    movl    %ecx, %r8d
    cmpl    %r9d, %ecx
    jl      .LBB0_405
    movl    %r9d, %r8d
.LBB0_405:
    testl   %ecx, %ecx
    js      .LBB0_407
    movl    %r8d, %ebp
    jmp     .LBB0_407
.LBB0_215:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r13d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %eax
    movq    %rax, -8(%rsp)
    leaq    (, %r10, 4), %rax
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vbroadcastss .LCPI0_2(%rip), %zmm7
    vpbroadcastd .LCPI0_5(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_216
.p2align 4, 0x90
.LBB0_228:
    incq    %r14
    addq    %rax, %rdx
    addq    %rax, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_216:
                                        // Child Loop BB0_217 Depth 2
                                        // Child Loop BB0_219 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_217:  // Parent Loop BB0_216 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm15
    vpsrld  $24, %zmm15, %zmm16
    vpsrld  $8, %zmm15, %zmm15
    vpandd  %zmm8, %zmm15, %zmm15
    vcvtdq2ps %zmm16, %zmm16
    vdivps  %zmm6, %zmm16, %zmm16
    vaddps  %zmm7, %zmm16, %zmm16
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vmulps  %zmm16, %zmm1, %zmm16
    vaddps  %zmm7, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm16, %zmm16
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm13, %zmm15, %zmm15
    vpaddd  %zmm14, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm16, %zmm16, %zmm16
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_217
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_219
    jmp     .LBB0_228
.p2align 4, 0x90
.LBB0_227:
    imull   -16(%rsp), %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_228
.LBB0_219:  // Parent Loop BB0_216 Depth=1
    movl    (%rsi, %r15, 4), %ebx
    movl    %ebx, %ecx
    shrl    $24, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r8d
    addl    %r15d, %r8d
    movl    %r8d, %ecx
    cmpl    %r13d, %r8d
    jl      .LBB0_221
    movl    %r13d, %ecx
.LBB0_221:
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testl   %r8d, %r8d
    js      .LBB0_223
    movl    %ecx, %r12d
.LBB0_223:
    movzbl  %bh, %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %ecx
    addl    %r14d, %ecx
    movl    %ecx, %r8d
    cmpl    %r9d, %ecx
    jl      .LBB0_225
    movl    %r9d, %r8d
.LBB0_225:
    testl   %ecx, %ecx
    js      .LBB0_227
    movl    %r8d, %ebp
    jmp     .LBB0_227
.LBB0_6:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %ecx, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movl    %r8d, %r8d
    movq    %r8, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vpbroadcastd .LCPI0_5(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_7
.p2align 4, 0x90
.LBB0_19:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_7:
                                        // Child Loop BB0_8 Depth 2
                                        // Child Loop BB0_10 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_8:  // Parent Loop BB0_7 Depth=1
    vpsrld  $16, -64(%rsi, %r15, 4), %zmm15
    vpandd  %zmm7, %zmm15, %zmm15
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vaddps  %zmm8, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm14, %zmm15, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpaddd  %zmm13, %zmm15, %zmm15
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    vpxord  %zmm16, %zmm16, %zmm16
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_8
    movq    %rax, %r15
    cmpl    -16(%rsp), %eax
    jne     .LBB0_10
    jmp     .LBB0_19
.p2align 4, 0x90
.LBB0_18:
    imull   -16(%rsp), %ebp
    addl    %r13d, %ebp
    movslq  %ebp, %r8
    movl    (%rdi, %r8, 4), %r8d
    movl    %r8d, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_19
.LBB0_10:  // Parent Loop BB0_7 Depth=1
    movzbl  2(%rsi, %r15, 4), %r8d
    vcvtsi2ss %r8d, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r12d
    leal    (%r15, %r12), %r8d
    movl    %r8d, %r11d
    cmpl    %ecx, %r8d
    jge     .LBB0_11
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    jns     .LBB0_13
.LBB0_14:
    addl    %r14d, %r12d
    movl    %r12d, %r8d
    cmpl    %r9d, %r12d
    jge     .LBB0_15
.LBB0_16:
    testl   %r12d, %r12d
    js      .LBB0_18
    jmp     .LBB0_17
.p2align 4, 0x90
.LBB0_11:
    movl    %ecx, %r11d
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    js      .LBB0_14
.LBB0_13:
    movl    %r11d, %r13d
    addl    %r14d, %r12d
    movl    %r12d, %r8d
    cmpl    %r9d, %r12d
    jl      .LBB0_16
.LBB0_15:
    movl    %r9d, %r8d
    testl   %r12d, %r12d
    js      .LBB0_18
.LBB0_17:
    movl    %r8d, %ebp
    jmp     .LBB0_18
.LBB0_126:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r11d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movq    %rax, -8(%rsp)
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm16
    vpbroadcastd .LCPI0_5(%rip), %zmm6
    vbroadcastss .LCPI0_1(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vbroadcastss .LCPI0_1(%rip), %xmm13
    vbroadcastss .LCPI0_2(%rip), %xmm14
    vpxor   %xmm15, %xmm15, %xmm15
    movq    -16(%rsp), %rcx
    jmp     .LBB0_127
.p2align 4, 0x90
.LBB0_140:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    %r8, %r14
    je      .LBB0_480
.LBB0_127:
                                        // Child Loop BB0_128 Depth 2
                                        // Child Loop BB0_131 Depth 2
    vpbroadcastd %r14d, %zmm5
    movl    $16, %r15d
    vmovdqa64 %zmm16, %zmm17
.p2align 4, 0x90
.LBB0_128:  // Parent Loop BB0_127 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm11
    vpsrld  $16, %zmm11, %zmm18
    vpandd  %zmm6, %zmm18, %zmm18
    vcvtdq2ps %zmm18, %zmm18
    vdivps  %zmm7, %zmm18, %zmm18
    vpsrld  $8, %zmm11, %zmm11
    vaddps  %zmm8, %zmm18, %zmm18
    vpandd  %zmm6, %zmm11, %zmm11
    vcvtdq2ps %zmm11, %zmm11
    vdivps  %zmm7, %zmm11, %zmm11
    vmulps  %zmm18, %zmm1, %zmm18
    vaddps  %zmm8, %zmm11, %zmm11
    vmulps  %zmm11, %zmm1, %zmm11
    vcvttps2dq %zmm18, %zmm18
    vcvttps2dq %zmm11, %zmm11
    vpaddd  %zmm5, %zmm11, %zmm11
    vpaddd  %zmm17, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm18, %zmm18
    vpminsd %zmm2, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm11, %zmm11
    vpminsd %zmm3, %zmm11, %zmm11
    vpmulld %zmm4, %zmm11, %zmm11
    vpaddd  %zmm18, %zmm11, %zmm11
    vpxord  %zmm18, %zmm18, %zmm18
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm11, 4), %zmm18 {%k1}
    vmovdqu64 %zmm18, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm17, %zmm17
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_128
    cmpl    %ecx, -8(%rsp)
    je      .LBB0_140
    vmovd   %r14d, %xmm5
    movq    -8(%rsp), %r15
    jmp     .LBB0_131
.p2align 4, 0x90
.LBB0_139:
    imull   %ecx, %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_140
.LBB0_131:  // Parent Loop BB0_127 Depth=1
    vpbroadcastd (%rsi, %r15, 4), %xmm11
    vpsrlvd .LCPI0_7(%rip), %xmm11, %xmm11
    vpand   .LCPI0_6(%rip), %xmm11, %xmm11
    vcvtdq2ps %xmm11, %xmm11
    vdivps  %xmm13, %xmm11, %xmm11
    vaddps  %xmm14, %xmm11, %xmm11
    vmulps  %xmm0, %xmm11, %xmm11
    vcvttps2dq %xmm11, %xmm11
    vpinsrd $1, %r15d, %xmm5, %xmm12
    vpaddd  %xmm11, %xmm12, %xmm11
    vpextrd $1, %xmm11, %eax
    cmpl    %r11d, %eax
    jl      .LBB0_133
    movl    %r11d, %eax
.LBB0_133:
    vpcmpgtd %zmm11, %zmm15, %k0
    kmovw   %k0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testb   $2, %r13b
    je      .LBB0_134
    vmovd   %xmm11, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_136
.LBB0_137:
    testb   $1, %r13b
    jne     .LBB0_139
    jmp     .LBB0_138
.p2align 4, 0x90
.LBB0_134:
    movl    %eax, %r12d
    vmovd   %xmm11, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_137
.LBB0_136:
    movl    %r9d, %eax
    testb   $1, %r13b
    jne     .LBB0_139
.LBB0_138:
    movl    %eax, %ebp
    jmp     .LBB0_139
.LBB0_35:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %r11d, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %eax, %zmm4
    movl    %eax, %r10d
                                        // kill: def $eax killed $eax killed $rax def $rax
    andl    $2147483632, %eax  // imm = 0x7FFFFFF0
    movq    %rax, -8(%rsp)
    movl    %r8d, %r8d
    vbroadcastss %xmm0, %xmm0
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm16
    vpbroadcastd .LCPI0_5(%rip), %zmm6
    vbroadcastss .LCPI0_1(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vbroadcastss .LCPI0_1(%rip), %xmm13
    vbroadcastss .LCPI0_2(%rip), %xmm14
    vpxor   %xmm15, %xmm15, %xmm15
    movq    -16(%rsp), %rcx
    jmp     .LBB0_36
.p2align 4, 0x90
.LBB0_49:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    %r8, %r14
    je      .LBB0_480
.LBB0_36:
                                        // Child Loop BB0_37 Depth 2
                                        // Child Loop BB0_40 Depth 2
    vpbroadcastd %r14d, %zmm5
    movl    $16, %r15d
    vmovdqa64 %zmm16, %zmm17
.p2align 4, 0x90
.LBB0_37:  // Parent Loop BB0_36 Depth=1
    vmovdqu64 -64(%rsi, %r15, 4), %zmm11
    vpsrld  $8, %zmm11, %zmm18
    vpandd  %zmm6, %zmm18, %zmm18
    vcvtdq2ps %zmm18, %zmm18
    vdivps  %zmm7, %zmm18, %zmm18
    vpsrld  $16, %zmm11, %zmm11
    vaddps  %zmm8, %zmm18, %zmm18
    vpandd  %zmm6, %zmm11, %zmm11
    vcvtdq2ps %zmm11, %zmm11
    vdivps  %zmm7, %zmm11, %zmm11
    vmulps  %zmm18, %zmm1, %zmm18
    vaddps  %zmm8, %zmm11, %zmm11
    vmulps  %zmm11, %zmm1, %zmm11
    vcvttps2dq %zmm18, %zmm18
    vcvttps2dq %zmm11, %zmm11
    vpaddd  %zmm5, %zmm11, %zmm11
    vpaddd  %zmm17, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm18, %zmm18
    vpminsd %zmm2, %zmm18, %zmm18
    vpmaxsd %zmm9, %zmm11, %zmm11
    vpminsd %zmm3, %zmm11, %zmm11
    vpmulld %zmm4, %zmm11, %zmm11
    vpaddd  %zmm18, %zmm11, %zmm11
    vpxord  %zmm18, %zmm18, %zmm18
    kxnorw  %k0, %k0, %k1
    vpgatherdd (%rdi, %zmm11, 4), %zmm18 {%k1}
    vmovdqu64 %zmm18, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm17, %zmm17
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_37
    cmpl    %ecx, -8(%rsp)
    je      .LBB0_49
    vmovd   %r14d, %xmm5
    movq    -8(%rsp), %r15
    jmp     .LBB0_40
.p2align 4, 0x90
.LBB0_48:
    imull   %ecx, %ebp
    addl    %r12d, %ebp
    movslq  %ebp, %rax
    movl    (%rdi, %rax, 4), %eax
    movl    %eax, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_49
.LBB0_40:  // Parent Loop BB0_36 Depth=1
    vpbroadcastd (%rsi, %r15, 4), %xmm11
    vpsrlvd .LCPI0_8(%rip), %xmm11, %xmm11
    vpand   .LCPI0_6(%rip), %xmm11, %xmm11
    vcvtdq2ps %xmm11, %xmm11
    vdivps  %xmm13, %xmm11, %xmm11
    vaddps  %xmm14, %xmm11, %xmm11
    vmulps  %xmm0, %xmm11, %xmm11
    vcvttps2dq %xmm11, %xmm11
    vpinsrd $1, %r15d, %xmm5, %xmm12
    vpaddd  %xmm11, %xmm12, %xmm11
    vpextrd $1, %xmm11, %eax
    cmpl    %r11d, %eax
    jl      .LBB0_42
    movl    %r11d, %eax
.LBB0_42:
    vpcmpgtd %zmm11, %zmm15, %k0
    kmovw   %k0, %r13d
    xorl    %ebp, %ebp
    movl    $0, %r12d
    testb   $2, %r13b
    je      .LBB0_43
    vmovd   %xmm11, %eax
    cmpl    %r9d, %eax
    jge     .LBB0_45
.LBB0_46:
    testb   $1, %r13b
    jne     .LBB0_48
    jmp     .LBB0_47
.p2align 4, 0x90
.LBB0_43:
    movl    %eax, %r12d
    vmovd   %xmm11, %eax
    cmpl    %r9d, %eax
    jl      .LBB0_46
.LBB0_45:
    movl    %r9d, %eax
    testb   $1, %r13b
    jne     .LBB0_48
.LBB0_47:
    movl    %eax, %ebp
    jmp     .LBB0_48
.LBB0_156:
    vbroadcastss %xmm0, %zmm1
    vpbroadcastd %eax, %zmm2
    vpbroadcastd %r9d, %zmm3
    vpbroadcastd %r11d, %zmm4
    movl    %r11d, %r10d
                                        // kill: def $r11d killed $r11d killed $r11 def $r11
    andl    $2147483632, %r11d  // imm = 0x7FFFFFF0
    movl    %r8d, %ecx
    movq    %rcx, -8(%rsp)
    leaq    (, %r10, 4), %rbx
    xorl    %r14d, %r14d
    vpmovsxbd .LCPI0_12(%rip), %zmm5
    vbroadcastss .LCPI0_1(%rip), %zmm6
    vpbroadcastd .LCPI0_5(%rip), %zmm7
    vbroadcastss .LCPI0_2(%rip), %zmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpbroadcastd .LCPI0_3(%rip), %zmm10
    vmovss  .LCPI0_1(%rip), %xmm11
    vmovss  .LCPI0_2(%rip), %xmm12
    jmp     .LBB0_157
.p2align 4, 0x90
.LBB0_169:
    incq    %r14
    addq    %rbx, %rdx
    addq    %rbx, %rsi
    cmpq    -8(%rsp), %r14
    je      .LBB0_480
.LBB0_157:
                                        // Child Loop BB0_158 Depth 2
                                        // Child Loop BB0_160 Depth 2
    vpbroadcastd %r14d, %zmm13
    movl    $16, %r15d
    vmovdqa64 %zmm5, %zmm14
.p2align 4, 0x90
.LBB0_158:  // Parent Loop BB0_157 Depth=1
    vpsrld  $8, -64(%rsi, %r15, 4), %zmm15
    vpandd  %zmm7, %zmm15, %zmm15
    vcvtdq2ps %zmm15, %zmm15
    vdivps  %zmm6, %zmm15, %zmm15
    vaddps  %zmm8, %zmm15, %zmm15
    vmulps  %zmm15, %zmm1, %zmm15
    vcvttps2dq %zmm15, %zmm15
    vpaddd  %zmm14, %zmm15, %zmm16
    vpmaxsd %zmm9, %zmm16, %zmm16
    vpminsd %zmm2, %zmm16, %zmm16
    vpaddd  %zmm13, %zmm15, %zmm15
    vpmaxsd %zmm9, %zmm15, %zmm15
    vpminsd %zmm3, %zmm15, %zmm15
    vpmulld %zmm4, %zmm15, %zmm15
    vpaddd  %zmm16, %zmm15, %zmm15
    kxnorw  %k0, %k0, %k1
    vpxord  %zmm16, %zmm16, %zmm16
    vpgatherdd (%rdi, %zmm15, 4), %zmm16 {%k1}
    vmovdqu64 %zmm16, -64(%rdx, %r15, 4)
    vpaddd  %zmm10, %zmm14, %zmm14
    addq    $16, %r15
    cmpq    %r10, %r15
    jbe     .LBB0_158
    movq    %r11, %r15
    cmpl    -16(%rsp), %r11d
    jne     .LBB0_160
    jmp     .LBB0_169
.p2align 4, 0x90
.LBB0_168:
    imull   -16(%rsp), %ebp
    addl    %r13d, %ebp
    movslq  %ebp, %rcx
    movl    (%rdi, %rcx, 4), %ecx
    movl    %ecx, (%rdx, %r15, 4)
    incq    %r15
    cmpq    %r10, %r15
    jae     .LBB0_169
.LBB0_160:  // Parent Loop BB0_157 Depth=1
    movzbl  1(%rsi, %r15, 4), %ecx
    vcvtsi2ss %ecx, %xmm17, %xmm13
    vdivss  %xmm11, %xmm13, %xmm13
    vaddss  %xmm12, %xmm13, %xmm13
    vmulss  %xmm0, %xmm13, %xmm13
    vcvttss2si %xmm13, %r12d
    leal    (%r15, %r12), %r8d
    movl    %r8d, %ecx
    cmpl    %eax, %r8d
    jge     .LBB0_161
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    jns     .LBB0_163
.LBB0_164:
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r9d, %r12d
    jge     .LBB0_165
.LBB0_166:
    testl   %r12d, %r12d
    js      .LBB0_168
    jmp     .LBB0_167
.p2align 4, 0x90
.LBB0_161:
    movl    %eax, %ecx
    xorl    %ebp, %ebp
    movl    $0, %r13d
    testl   %r8d, %r8d
    js      .LBB0_164
.LBB0_163:
    movl    %ecx, %r13d
    addl    %r14d, %r12d
    movl    %r12d, %ecx
    cmpl    %r9d, %r12d
    jl      .LBB0_166
.LBB0_165:
    movl    %r9d, %ecx
    testl   %r12d, %r12d
    js      .LBB0_168
.LBB0_167:
    movl    %ecx, %ebp
    jmp     .LBB0_168
.LBB0_480:
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
// SIZE(SYM(ksvgDisplacementMapApplyAvx512))
    CFI_END
    RODATA
.p2align 2, 0x0
.LJTI0_0:
.long .LBB0_2-.LJTI0_0
.long .LBB0_122-.LJTI0_0
.long .LBB0_242-.LJTI0_0
.long .LBB0_362-.LJTI0_0
.LJTI0_1:
.long .LBB0_364-.LJTI0_1
.long .LBB0_393-.LJTI0_1
.long .LBB0_422-.LJTI0_1
.long .LBB0_451-.LJTI0_1
.LJTI0_2:
.long .LBB0_244-.LJTI0_2
.long .LBB0_274-.LJTI0_2
.long .LBB0_304-.LJTI0_2
.long .LBB0_333-.LJTI0_2
.LJTI0_3:
.long .LBB0_124-.LJTI0_3
.long .LBB0_154-.LJTI0_3
.long .LBB0_183-.LJTI0_3
.long .LBB0_213-.LJTI0_3
.LJTI0_4:
.long .LBB0_4-.LJTI0_4
.long .LBB0_33-.LJTI0_4
.long .LBB0_63-.LJTI0_4
.long .LBB0_93-.LJTI0_4
GNU_STACK
ADDRSIG
