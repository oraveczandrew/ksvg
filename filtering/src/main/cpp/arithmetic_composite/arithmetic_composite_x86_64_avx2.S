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
 * x86-64 AVX2 implementation of ArithmeticComposite.
 *
 * 8 pixels are processed per vector iteration.  Semantics mirror the
 * current ksvgArithmeticApplyAvx2() reference: the supplied sRGB LUTs
 * are used in linear mode, while non-linear mode applies the arithmetic
 * formula directly in encoded space.
 *
 * This file is Clang/GNU assembler compatible on macOS and ELF hosts.
 */

#include "asm_macros.S"

.text
.p2align 5

/*
 * void ksvgArithmeticApplyAvx2(
 *     const jint* src1, const jint* src2, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     jfloat k1, jfloat k2, jfloat k3, jfloat k4,
 *     jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * x86-64 System V ABI:
 *   rdi = src1, rsi = src2, rdx = dst, ecx = width, r8d = clipLeft, r9d = clipTop
 *   xmm0 = k1, xmm1 = k2, xmm2 = k3, xmm3 = k4
 *   stack: clipRight, clipBottom, useLinear, srgbToLinear, linearToSrgb
 */
.globl SYM(ksvgArithmeticApplyAvx2)
TYPE(SYM(ksvgArithmeticApplyAvx2), @function)
SYM(ksvgArithmeticApplyAvx2):
    pushq                              %rbp
    movq                               %rsp, %rbp
    pushq                              %r15
    pushq                              %r14
    pushq                              %r13
    pushq                              %r12
    pushq                              %rbx
    andq                               $-32, %rsp
    subq                               $1760, %rsp
    vmovaps                            %xmm3, %xmm4
    vmovaps                            %xmm2, %xmm7
    vmovaps                            %xmm0, %xmm5
    movl                               %r9d, %eax
    movq                               %r8, 32(%rsp)
    movq                               %rdx, 24(%rsp)
    movq                               %rsi, 16(%rsp)
    movq                               %rdi, 8(%rsp)
    movq                               48(%rbp), %r13
    movq                               40(%rbp), %r10
    movzbl                             32(%rbp), %ebx
    movl                               24(%rbp), %edx
    testb                              %bl, %bl
    je                                 .LBB0_1
    vbroadcastf128                     (%r10), %ymm0
    vmovaps                            %ymm0, 1152(%rsp)
    vbroadcastf128                     16(%r10), %ymm0
    vmovaps                            %ymm0, 1184(%rsp)
    vbroadcastf128                     32(%r10), %ymm0
    vmovaps                            %ymm0, 1216(%rsp)
    vbroadcastf128                     48(%r10), %ymm0
    vmovaps                            %ymm0, 1248(%rsp)
    vbroadcastf128                     64(%r10), %ymm0
    vmovaps                            %ymm0, 480(%rsp)
    vbroadcasti128                     80(%r10), %ymm2
    vbroadcastf128                     96(%r10), %ymm6
    vbroadcasti128                     112(%r10), %ymm0
    vbroadcastf128                     128(%r10), %ymm3
    vmovaps                            %ymm3, 320(%rsp)
    vbroadcastf128                     144(%r10), %ymm3
    vmovaps                            %ymm3, 608(%rsp)
    vbroadcastf128                     160(%r10), %ymm3
    vmovaps                            %ymm3, 384(%rsp)
    vbroadcastf128                     176(%r10), %ymm3
    vmovaps                            %ymm3, 352(%rsp)
    vbroadcastf128                     192(%r10), %ymm3
    vmovaps                            %ymm3, 448(%rsp)
    vbroadcastf128                     208(%r10), %ymm3
    vmovaps                            %ymm3, 416(%rsp)
    vbroadcasti128                     224(%r10), %ymm14
    vbroadcastf128                     240(%r10), %ymm3
    vmovaps                            %ymm3, 576(%rsp)
    vbroadcastf128                     (%r13), %ymm3
    vmovaps                            %ymm3, 640(%rsp)
    vbroadcastf128                     16(%r13), %ymm3
    vmovaps                            %ymm3, 672(%rsp)
    vbroadcastf128                     32(%r13), %ymm3
    vmovaps                            %ymm3, 704(%rsp)
    vbroadcastf128                     48(%r13), %ymm3
    vmovaps                            %ymm3, 736(%rsp)
    vbroadcastf128                     64(%r13), %ymm3
    vmovaps                            %ymm3, 768(%rsp)
    vbroadcastf128                     80(%r13), %ymm3
    vmovaps                            %ymm3, 800(%rsp)
    vbroadcastf128                     96(%r13), %ymm3
    vmovaps                            %ymm3, 832(%rsp)
    vbroadcastf128                     112(%r13), %ymm3
    vmovaps                            %ymm3, 864(%rsp)
    vbroadcastf128                     128(%r13), %ymm3
    vmovaps                            %ymm3, 896(%rsp)
    vbroadcastf128                     144(%r13), %ymm3
    vmovaps                            %ymm3, 928(%rsp)
    vbroadcastf128                     160(%r13), %ymm3
    vmovaps                            %ymm3, 960(%rsp)
    vbroadcastf128                     176(%r13), %ymm3
    vmovaps                            %ymm3, 992(%rsp)
    vbroadcastf128                     192(%r13), %ymm3
    vmovaps                            %ymm3, 1024(%rsp)
    vbroadcastf128                     208(%r13), %ymm3
    vmovaps                            %ymm3, 1056(%rsp)
    vbroadcastf128                     224(%r13), %ymm3
    vmovaps                            %ymm3, 1088(%rsp)
    vbroadcastf128                     240(%r13), %ymm3
    vmovaps                            %ymm3, 1120(%rsp)
    vmovdqa                            %ymm2, 1280(%rsp)
    vmovaps                            %ymm6, 1312(%rsp)
    cmpl                               %edx, %eax
    jl                                 .LBB0_4
    jmp                                .LBB0_23

.LBB0_1:
    vmovdqa                            %ymm2, 1280(%rsp)
    vmovaps                            %ymm6, 1312(%rsp)
    cmpl                               %edx, %eax
    jge                                .LBB0_23

.LBB0_4:
    vmovdqa                            %ymm0, %ymm2
    vmovss                             .LCPI0_0(%rip), %xmm0
    vmulss                             %xmm0, %xmm4, %xmm3
    vaddss                             .LCPI0_1(%rip), %xmm3, %xmm9
    vdivss                             %xmm0, %xmm5, %xmm0
    vbroadcastss                       %xmm0, %ymm3
    vmovdqa                            %ymm2, %ymm0
    vbroadcastss                       %xmm1, %ymm6
    vbroadcastss                       %xmm7, %ymm11
    vbroadcastss                       %xmm9, %ymm10
    vmovaps                            %ymm3, %ymm1
    movq                               32(%rsp), %rsi
    leal                               8(%rsi), %esi
    movslq                             16(%rbp), %r15
    movl                               %esi, 60(%rsp)
    movslq                             %esi, %rsi
    movq                               %rsi, 72(%rsp)
    movslq                             %eax, %rdi
    movslq                             %ecx, %r11
    movslq                             %edx, %rax
    movq                               %rax, 88(%rsp)
    movq                               24(%rsp), %rax
    movq                               %rax, %rcx
    movq                               8(%rsp), %r8
    subq                               %r8, %rcx
    movq                               %rax, %rdx
    movq                               16(%rsp), %rsi
    subq                               %rsi, %rdx
    vbroadcastss                       %xmm5, %ymm5
    vbroadcastss                       %xmm4, %ymm13
    cmpq                               $32, %rcx
    setb                               %cl
    cmpq                               $32, %rdx
    setb                               %dl
    orb                                %cl, %dl
    movb                               %dl, 7(%rsp)
    movq                               %rdi, 48(%rsp)
    movq                               %rdi, %rcx
    imulq                              %r11, %rcx
    leaq                               (%rax, %rcx, 4), %r9
    movq                               %r11, 64(%rsp)
    leaq                               (, %r11, 4), %rax
    movq                               %rax, 80(%rsp)
    leaq                               (%rsi, %rcx, 4), %rdi
    movq                               %rcx, 40(%rsp)
    leaq                               (%r8, %rcx, 4), %rdx
    vbroadcastss                       .LCPI0_0(%rip), %xmm12
    vmovdqa                            .LCPI0_4(%rip), %ymm2
    vmovaps                            %ymm10, 224(%rsp)
    vmovdqa                            %ymm14, 544(%rsp)
    vmovaps                            %ymm3, 192(%rsp)
    vmovaps                            %ymm6, 96(%rsp)
    vmovaps                            %ymm5, 128(%rsp)
    vmovaps                            %ymm13, 512(%rsp)
    vmovaps                            %ymm11, 288(%rsp)
    vmovdqa                            %ymm0, 256(%rsp)
    jmp                                .LBB0_5
.p2align 4, 0x90

.LBB0_22:
    movq                               48(%rsp), %rax
    incq                               %rax
    movq                               80(%rsp), %rcx
    addq                               %rcx, %r9
    addq                               %rcx, %rdi
    addq                               %rcx, %rdx
    movq                               40(%rsp), %rcx
    addq                               64(%rsp), %rcx
    movq                               %rcx, 40(%rsp)
    movq                               %rax, 48(%rsp)
    cmpq                               88(%rsp), %rax
    movzbl                             32(%rbp), %ebx
    vmovdqa                            .LCPI0_4(%rip), %ymm2
    je                                 .LBB0_23

.LBB0_5:
    movq                               32(%rsp), %rax
    movl                               %eax, %r11d
    movl                               60(%rsp), %eax
    cmpl                               16(%rbp), %eax
    vmovdqa                            .LCPI0_3(%rip), %ymm6
    jle                                .LBB0_6

.LBB0_12:
    cmpl                               16(%rbp), %r11d
    vmovaps                            96(%rsp), %ymm6
    vmovaps                            128(%rsp), %ymm5
    movl                               $-16777216, %r14d
    jge                                .LBB0_22
    movslq                             %r11d, %rsi
    cmpb                               $0, 32(%rbp)
    je                                 .LBB0_16
    vxorps                             %xmm7, %xmm7, %xmm7
.p2align 4, 0x90

.LBB0_15:
    movl                               (%rdx, %rsi, 4), %ecx
    movl                               %ecx, %r8d
    movzbl                             %cl, %r11d
    movzbl                             (%r10, %r11), %r11d
    vmovd                              %r11d, %xmm2
    movzbl                             %ch, %eax
    shrl                               $16, %r8d
    movzbl                             %r8b, %r8d
    vpinsrb                            $4, (%r10, %rax), %xmm2, %xmm2
    vpinsrb                            $8, (%r10, %r8), %xmm2, %xmm2
    shrl                               $24, %ecx
    vpinsrb                            $12, %ecx, %xmm2, %xmm2
    movl                               (%rdi, %rsi, 4), %eax
    movl                               %eax, %ecx
    movzbl                             %al, %r8d
    movzbl                             (%r10, %r8), %r8d
    vmovd                              %r8d, %xmm3
    movzbl                             %ah, %ebx
    shrl                               $16, %ecx
    movzbl                             %cl, %ecx
    vpinsrb                            $4, (%r10, %rbx), %xmm3, %xmm3
    vpinsrb                            $8, (%r10, %rcx), %xmm3, %xmm3
    shrl                               $24, %eax
    vpinsrb                            $12, %eax, %xmm3, %xmm3
    vcvtdq2ps                          %xmm2, %xmm2
    vdivps                             %xmm12, %xmm2, %xmm2
    vcvtdq2ps                          %xmm3, %xmm3
    vdivps                             %xmm12, %xmm3, %xmm3
    vmulps                             %xmm5, %xmm2, %xmm4
    vmulps                             %xmm6, %xmm2, %xmm2
    vmulps                             %xmm3, %xmm4, %xmm4
    vaddps                             %xmm2, %xmm4, %xmm2
    vmulps                             %xmm3, %xmm11, %xmm3
    vaddps                             %xmm2, %xmm3, %xmm2
    vaddps                             %xmm2, %xmm13, %xmm2
    vmulps                             %xmm2, %xmm12, %xmm2
    vmaxps                             %xmm2, %xmm7, %xmm2
    vcmpltps                           %xmm2, %xmm12, %xmm3
    vpextrb                            $12, %xmm3, %r8d
    vshufps                            $255, %xmm2, %xmm2, %xmm4
    vcvttss2si                         %xmm4, %ecx
    vpextrb                            $8, %xmm3, %eax
    vshufpd                            $1, %xmm2, %xmm2, %xmm4
    testb                              $1, %al
    vcvttss2si                         %xmm4, %eax
    movzbl                             %al, %eax
    movl                               $255, %r11d
    cmovneq                            %r11, %rax
    shll                               $24, %ecx
    testb                              $1, %r8b
    movzbl                             (%r13, %rax), %eax
    vpackssdw                          %xmm3, %xmm3, %xmm3
    vpacksswb                          %xmm3, %xmm3, %xmm3
    vcvttps2dq                         %xmm2, %xmm2
    vpshuflw                           $232, %xmm2, %xmm2
    vpackuswb                          %xmm2, %xmm2, %xmm2
    vpor                               %xmm2, %xmm3, %xmm2
    cmovnel                            %r14d, %ecx
    shll                               $16, %eax
    orl                                %ecx, %eax
    vpextrb                            $1, %xmm2, %ecx
    movzbl                             (%r13, %rcx), %ecx
    shll                               $8, %ecx
    orl                                %eax, %ecx
    vpextrb                            $0, %xmm2, %eax
    movzbl                             (%r13, %rax), %eax
    orl                                %eax, %ecx
    movl                               %ecx, (%r9, %rsi, 4)
    incq                               %rsi
    cmpq                               %rsi, %r15
    jne                                .LBB0_15
    jmp                                .LBB0_22
.p2align 4, 0x90

.LBB0_6:
    movq                               48(%rsp), %rcx
    imulq                              64(%rsp), %rcx
    movq                               8(%rsp), %rax
    leaq                               (%rax, %rcx, 4), %r8
    movq                               16(%rsp), %rax
    leaq                               (%rax, %rcx, 4), %r14
    movq                               24(%rsp), %rax
    leaq                               (%rax, %rcx, 4), %rsi
    movq                               72(%rsp), %rcx
    movq                               32(%rsp), %rax
    movl                               %eax, %r11d
    jmp                                .LBB0_7
.p2align 4, 0x90

.LBB0_24:
    vcvtdq2ps                          %ymm12, %ymm6
    vcvtdq2ps                          %ymm3, %ymm3
    vmulps                             %ymm3, %ymm6, %ymm7
    vmulps                             %ymm7, %ymm1, %ymm7
    vmovdqa                            %ymm15, 160(%rsp)
    vmovaps                            96(%rsp), %ymm15
    vmulps                             %ymm6, %ymm15, %ymm6
    vaddps                             %ymm7, %ymm6, %ymm6
    vmulps                             %ymm3, %ymm11, %ymm3
    vaddps                             %ymm6, %ymm3, %ymm3
    vaddps                             %ymm3, %ymm10, %ymm3
    vcvttps2dq                         %ymm3, %ymm3
    vpmaxsd                            %ymm2, %ymm3, %ymm3
    vmovaps                            %ymm13, %ymm12
    vmovdqa                            %ymm0, %ymm13
    vpminsd                            %ymm14, %ymm3, %ymm0
    vcvtdq2ps                          %ymm8, %ymm3
    vcvtdq2ps                          %ymm5, %ymm5
    vmulps                             %ymm5, %ymm3, %ymm6
    vmulps                             %ymm6, %ymm1, %ymm6
    vmulps                             %ymm3, %ymm15, %ymm3
    vaddps                             %ymm6, %ymm3, %ymm3
    vmulps                             %ymm5, %ymm11, %ymm5
    vaddps                             %ymm3, %ymm5, %ymm3
    vaddps                             %ymm3, %ymm10, %ymm3
    vcvttps2dq                         %ymm3, %ymm3
    vpmaxsd                            %ymm2, %ymm3, %ymm3
    vpminsd                            %ymm14, %ymm3, %ymm3
    vcvtdq2ps                          %ymm9, %ymm5
    vcvtdq2ps                          160(%rsp), %ymm6
    vmulps                             %ymm6, %ymm5, %ymm7
    vmulps                             %ymm7, %ymm1, %ymm7
    vmulps                             %ymm5, %ymm15, %ymm5
    vaddps                             %ymm7, %ymm5, %ymm5
    vmulps                             %ymm6, %ymm11, %ymm6
    vaddps                             %ymm5, %ymm6, %ymm5
    vmovdqa                            %ymm0, %ymm6
    vmovdqa                            %ymm13, %ymm0
    vmovaps                            %ymm12, %ymm13
    vbroadcastss                       .LCPI0_0(%rip), %xmm12
    vaddps                             %ymm5, %ymm10, %ymm5
    vcvttps2dq                         %ymm5, %ymm5
    vpmaxsd                            %ymm2, %ymm5, %ymm5
    vpminsd                            %ymm14, %ymm5, %ymm5

.LBB0_11:
    vpslld                             $24, %ymm4, %ymm4
    vpslld                             $16, %ymm5, %ymm2
    vpor                               %ymm4, %ymm2, %ymm2
    vpslld                             $8, %ymm3, %ymm3
    vpor                               %ymm3, %ymm6, %ymm3
    vpor                               %ymm2, %ymm3, %ymm2
    vmovdqu                            %ymm2, (%rsi, %r12, 4)
    movl                               %ecx, %r11d
    leaq                               8(%rcx), %r12
    movq                               %r12, %rcx
    cmpq                               %r15, %r12
    vmovdqa                            .LCPI0_4(%rip), %ymm2
    vmovdqa                            .LCPI0_3(%rip), %ymm6
    jg                                 .LBB0_12

.LBB0_7:
    movslq                             %r11d, %r12
    vmovdqu                            (%r8, %r12, 4), %ymm3
    vpbroadcastd                       .LCPI0_2(%rip), %ymm14
    vmovdqu                            (%r14, %r12, 4), %ymm4
    vpand                              %ymm3, %ymm14, %ymm12
    vmovdqa                            %ymm12, 1600(%rsp)
    vpshufb                            %ymm6, %ymm3, %ymm5
    vmovdqa                            %ymm5, %ymm8
    vmovdqa                            %ymm5, 1632(%rsp)
    vpshufb                            %ymm2, %ymm3, %ymm9
    vmovdqa                            %ymm9, 1664(%rsp)
    vpsrld                             $24, %ymm3, %ymm5
    vmovdqa                            %ymm5, 1696(%rsp)
    vpand                              %ymm4, %ymm14, %ymm3
    vmovdqa                            %ymm3, 1472(%rsp)
    vmovdqa                            %ymm6, %ymm15
    vpsrld                             $24, %ymm4, %ymm6
    vcvtdq2ps                          %ymm5, %ymm7
    vpmaddwd                           %ymm5, %ymm6, %ymm5
    vcvtdq2ps                          %ymm5, %ymm5
    vmulps                             %ymm5, %ymm1, %ymm5
    vmulps                             96(%rsp), %ymm7, %ymm7
    vaddps                             %ymm5, %ymm7, %ymm7
    vpshufb                            %ymm15, %ymm4, %ymm5
    vmovdqa                            %ymm5, 1504(%rsp)
    vpshufb                            %ymm2, %ymm4, %ymm15
    vmovdqa                            %ymm15, 1536(%rsp)
    vmovdqa                            %ymm6, 1568(%rsp)
    vcvtdq2ps                          %ymm6, %ymm4
    vmulps                             %ymm4, %ymm11, %ymm4
    vaddps                             %ymm7, %ymm4, %ymm4
    vaddps                             %ymm4, %ymm10, %ymm4
    vcvttps2dq                         %ymm4, %ymm4
    vpxor                              %xmm2, %xmm2, %xmm2
    vpmaxsd                            %ymm2, %ymm4, %ymm4
    vpminsd                            %ymm14, %ymm4, %ymm4
    vmovdqa                            %ymm4, 1440(%rsp)
    testb                              %bl, %bl
    je                                 .LBB0_24
    xorl                               %r11d, %r11d
    vmovdqa                            %ymm14, 160(%rsp)
.p2align 4, 0x90

.LBB0_9:
    vmovdqa                            1600(%rsp, %r11), %ymm3
    vpsrlw                             $4, %ymm3, %ymm4
    vpbroadcastb                       .LCPI0_24(%rip), %ymm0
    vpand                              %ymm0, %ymm3, %ymm3
    vpand                              %ymm0, %ymm4, %ymm4
    vmovdqa                            1152(%rsp), %ymm13
    vpshufb                            %ymm3, %ymm13, %ymm5
    vpxor                              %xmm0, %xmm0, %xmm0
    vpcmpeqb                           %ymm0, %ymm4, %ymm6
    vpand                              %ymm5, %ymm6, %ymm5
    vmovdqa                            1184(%rsp), %ymm0
    vpshufb                            %ymm3, %ymm0, %ymm6
    vpbroadcastb                       .LCPI0_25(%rip), %ymm1
    vpcmpeqb                           %ymm1, %ymm4, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            1216(%rsp), %ymm14
    vpshufb                            %ymm3, %ymm14, %ymm6
    vpbroadcastb                       .LCPI0_26(%rip), %ymm1
    vpcmpeqb                           %ymm1, %ymm4, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            1248(%rsp), %ymm9
    vpshufb                            %ymm3, %ymm9, %ymm7
    vpbroadcastb                       .LCPI0_27(%rip), %ymm1
    vpcmpeqb                           %ymm1, %ymm4, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            480(%rsp), %ymm1
    vpshufb                            %ymm3, %ymm1, %ymm6
    vpbroadcastb                       .LCPI0_28(%rip), %ymm1
    vpcmpeqb                           %ymm1, %ymm4, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            1280(%rsp), %ymm12
    vpshufb                            %ymm3, %ymm12, %ymm7
    vpbroadcastb                       .LCPI0_29(%rip), %ymm1
    vpcmpeqb                           %ymm1, %ymm4, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            1312(%rsp), %ymm1
    vpshufb                            %ymm3, %ymm1, %ymm7
    vpbroadcastb                       .LCPI0_30(%rip), %ymm2
    vpcmpeqb                           %ymm2, %ymm4, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            256(%rsp), %ymm2
    vpshufb                            %ymm3, %ymm2, %ymm6
    vpbroadcastb                       .LCPI0_31(%rip), %ymm7
    vpcmpeqb                           %ymm7, %ymm4, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            320(%rsp), %ymm7
    vpshufb                            %ymm3, %ymm7, %ymm7
    vpbroadcastb                       .LCPI0_32(%rip), %ymm8
    vpcmpeqb                           %ymm4, %ymm8, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            608(%rsp), %ymm15
    vpshufb                            %ymm3, %ymm15, %ymm7
    vpbroadcastb                       .LCPI0_33(%rip), %ymm8
    vpcmpeqb                           %ymm4, %ymm8, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            384(%rsp), %ymm7
    vpshufb                            %ymm3, %ymm7, %ymm7
    vpbroadcastb                       .LCPI0_34(%rip), %ymm8
    vpcmpeqb                           %ymm4, %ymm8, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            352(%rsp), %ymm6
    vpshufb                            %ymm3, %ymm6, %ymm6
    vpbroadcastb                       .LCPI0_35(%rip), %ymm7
    vpcmpeqb                           %ymm7, %ymm4, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            448(%rsp), %ymm7
    vpshufb                            %ymm3, %ymm7, %ymm7
    vpbroadcastb                       .LCPI0_36(%rip), %ymm8
    vpcmpeqb                           %ymm4, %ymm8, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            416(%rsp), %ymm7
    vpshufb                            %ymm3, %ymm7, %ymm7
    vpbroadcastb                       .LCPI0_37(%rip), %ymm8
    vpcmpeqb                           %ymm4, %ymm8, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            544(%rsp), %ymm11
    vpshufb                            %ymm3, %ymm11, %ymm7
    vpbroadcastb                       .LCPI0_38(%rip), %ymm8
    vpcmpeqb                           %ymm4, %ymm8, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            576(%rsp), %ymm10
    vpshufb                            %ymm3, %ymm10, %ymm3
    vpbroadcastb                       .LCPI0_24(%rip), %ymm7
    vpcmpeqb                           %ymm7, %ymm4, %ymm4
    vpand                              %ymm3, %ymm4, %ymm3
    vpor                               %ymm3, %ymm6, %ymm3
    vpor                               %ymm3, %ymm5, %ymm3
    vmovdqa                            1472(%rsp, %r11), %ymm4
    vpsrlw                             $4, %ymm4, %ymm5
    vpand                              %ymm7, %ymm4, %ymm4
    vpand                              %ymm7, %ymm5, %ymm5
    vpshufb                            %ymm4, %ymm13, %ymm6
    vpcmpeqb                           .LCPI0_23(%rip), %ymm5, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           .LCPI0_6(%rip), %ymm5, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpshufb                            %ymm4, %ymm14, %ymm7
    vpcmpeqb                           .LCPI0_7(%rip), %ymm5, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpshufb                            %ymm4, %ymm9, %ymm8
    vpbroadcastb                       .LCPI0_27(%rip), %ymm13
    vpcmpeqb                           %ymm5, %ymm13, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            480(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           .LCPI0_9(%rip), %ymm5, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpshufb                            %ymm4, %ymm12, %ymm8
    vpcmpeqb                           .LCPI0_10(%rip), %ymm5, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vpshufb                            %ymm4, %ymm1, %ymm8
    vpcmpeqb                           .LCPI0_11(%rip), %ymm5, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpshufb                            %ymm4, %ymm2, %ymm7
    vpcmpeqb                           .LCPI0_12(%rip), %ymm5, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vmovdqa                            320(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm8
    vpcmpeqb                           .LCPI0_13(%rip), %ymm5, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vpshufb                            %ymm4, %ymm15, %ymm8
    vpbroadcastb                       .LCPI0_33(%rip), %ymm15
    vpcmpeqb                           %ymm5, %ymm15, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vmovdqa                            384(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm8
    vpbroadcastb                       .LCPI0_34(%rip), %ymm14
    vpcmpeqb                           %ymm5, %ymm14, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            352(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpbroadcastb                       .LCPI0_35(%rip), %ymm12
    vpcmpeqb                           %ymm5, %ymm12, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vmovdqa                            448(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm8
    vpcmpeqb                           .LCPI0_17(%rip), %ymm5, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vmovdqa                            416(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm8
    vpbroadcastb                       .LCPI0_37(%rip), %ymm2
    vpcmpeqb                           %ymm2, %ymm5, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vpor                               %ymm7, %ymm8, %ymm7
    vpshufb                            %ymm4, %ymm11, %ymm8
    vpbroadcastb                       .LCPI0_38(%rip), %ymm1
    vpcmpeqb                           %ymm1, %ymm5, %ymm9
    vpand                              %ymm8, %ymm9, %ymm8
    vmovdqa                            %ymm10, %ymm0
    vmovaps                            224(%rsp), %ymm10
    vpor                               %ymm7, %ymm8, %ymm7
    vpshufb                            %ymm4, %ymm0, %ymm4
    vpbroadcastb                       .LCPI0_24(%rip), %ymm9
    vpcmpeqb                           %ymm5, %ymm9, %ymm5
    vpand                              %ymm4, %ymm5, %ymm4
    vpor                               %ymm4, %ymm7, %ymm4
    vpor                               %ymm4, %ymm6, %ymm4
    vcvtdq2ps                          %ymm3, %ymm3
    vcvtdq2ps                          %ymm4, %ymm4
    vmulps                             %ymm4, %ymm3, %ymm5
    vmulps                             192(%rsp), %ymm5, %ymm5
    vmulps                             96(%rsp), %ymm3, %ymm3
    vaddps                             %ymm5, %ymm3, %ymm3
    vmulps                             288(%rsp), %ymm4, %ymm4
    vaddps                             %ymm3, %ymm4, %ymm3
    vaddps                             %ymm3, %ymm10, %ymm3
    vcvttps2dq                         %ymm3, %ymm3
    vpxor                              %xmm6, %xmm6, %xmm6
    vpmaxsd                            %ymm6, %ymm3, %ymm3
    vpminsd                            160(%rsp), %ymm3, %ymm4
    vpsrlw                             $4, %ymm4, %ymm3
    vpand                              %ymm4, %ymm9, %ymm4
    vmovdqa                            640(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm5
    vpcmpeqb                           %ymm6, %ymm3, %ymm6
    vpand                              %ymm5, %ymm6, %ymm5
    vmovdqa                            672(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm6
    vpcmpeqb                           .LCPI0_6(%rip), %ymm3, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            704(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm6
    vpcmpeqb                           .LCPI0_7(%rip), %ymm3, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            736(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           %ymm3, %ymm13, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            768(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm6
    vpcmpeqb                           .LCPI0_9(%rip), %ymm3, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            800(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           .LCPI0_10(%rip), %ymm3, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            832(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           .LCPI0_11(%rip), %ymm3, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            864(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm6
    vpcmpeqb                           .LCPI0_12(%rip), %ymm3, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            896(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           .LCPI0_13(%rip), %ymm3, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            928(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           %ymm3, %ymm15, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            960(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           %ymm3, %ymm14, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vpor                               %ymm6, %ymm5, %ymm5
    vmovdqa                            992(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm6
    vpcmpeqb                           %ymm3, %ymm12, %ymm7
    vpand                              %ymm6, %ymm7, %ymm6
    vmovdqa                            1024(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           .LCPI0_17(%rip), %ymm3, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            1056(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           %ymm2, %ymm3, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            1088(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm7
    vpcmpeqb                           %ymm1, %ymm3, %ymm8
    vpand                              %ymm7, %ymm8, %ymm7
    vpor                               %ymm7, %ymm6, %ymm6
    vmovdqa                            1120(%rsp), %ymm0
    vpshufb                            %ymm4, %ymm0, %ymm4
    vpcmpeqb                           %ymm3, %ymm9, %ymm3
    vpand                              %ymm4, %ymm3, %ymm3
    vpor                               %ymm3, %ymm6, %ymm3
    vpor                               %ymm3, %ymm5, %ymm3
    vmovdqa                            %ymm3, 1344(%rsp, %r11)
    addq                               $32, %r11
    cmpq                               $96, %r11
    jne                                .LBB0_9
    vmovdqa                            1344(%rsp), %ymm6
    vmovdqa                            1376(%rsp), %ymm3
    vmovdqa                            1408(%rsp), %ymm5
    vmovdqa                            1440(%rsp), %ymm4
    vmovdqa                            256(%rsp), %ymm0
    vmovaps                            192(%rsp), %ymm1
    vmovaps                            288(%rsp), %ymm11
    vmovaps                            512(%rsp), %ymm13
    vbroadcastss                       .LCPI0_0(%rip), %xmm12
    jmp                                .LBB0_11

.LBB0_16:
    movq                               %r15, %rbx
    subq                               %rsi, %rbx
    cmpq                               $8, %rbx
    setb                               %cl
    orb                                7(%rsp), %cl
    je                                 .LBB0_18
    movq                               %rsi, %rcx
    vxorps                             %xmm7, %xmm7, %xmm7
    jmp                                .LBB0_21

.LBB0_18:
    movq                               %rbx, %r11
    andq                               $-8, %r11
    leaq                               (%r11, %rsi), %rcx
    addq                               40(%rsp), %rsi
    movq                               24(%rsp), %rax
    leaq                               (%rax, %rsi, 4), %r14
    movq                               16(%rsp), %rax
    leaq                               (%rax, %rsi, 4), %r12
    movq                               8(%rsp), %rax
    leaq                               (%rax, %rsi, 4), %rsi
    xorl                               %r8d, %r8d
    vmovaps                            %ymm11, %ymm10
    vmovaps                            %ymm6, %ymm11
    vmovaps                            %ymm13, %ymm12
    vmovaps                            %ymm5, %ymm13
    vbroadcastss                       .LCPI0_0(%rip), %ymm6
    vxorps                             %xmm1, %xmm1, %xmm1
    vmovdqa                            .LCPI0_4(%rip), %ymm9
    vmovdqa                            .LCPI0_3(%rip), %ymm14
.p2align 4, 0x90

.LBB0_19:
    vmovdqu                            (%rsi, %r8, 4), %ymm3
    vmovdqu                            (%r12, %r8, 4), %ymm2
    vpsrld                             $24, %ymm3, %ymm4
    vpsrld                             $24, %ymm2, %ymm5
    vcvtdq2ps                          %ymm4, %ymm4
    vdivps                             %ymm6, %ymm4, %ymm4
    vcvtdq2ps                          %ymm5, %ymm5
    vdivps                             %ymm6, %ymm5, %ymm5
    vmulps                             %ymm4, %ymm13, %ymm6
    vmulps                             %ymm4, %ymm11, %ymm4
    vmulps                             %ymm5, %ymm6, %ymm6
    vaddps                             %ymm4, %ymm6, %ymm4
    vmulps                             %ymm5, %ymm10, %ymm5
    vaddps                             %ymm4, %ymm5, %ymm4
    vaddps                             %ymm4, %ymm12, %ymm4
    vbroadcastss                       .LCPI0_0(%rip), %ymm5
    vmulps                             %ymm5, %ymm4, %ymm4
    vmaxps                             %ymm4, %ymm1, %ymm4
    vbroadcastss                       .LCPI0_0(%rip), %ymm5
    vminps                             %ymm4, %ymm5, %ymm4
    vcvttps2dq                         %ymm4, %ymm4
    vpshufb                            %ymm9, %ymm3, %ymm5
    vcvtdq2ps                          %ymm5, %ymm5
    vbroadcastss                       .LCPI0_0(%rip), %ymm6
    vdivps                             %ymm6, %ymm5, %ymm5
    vextracti128                       $1, %ymm4, %xmm6
    vpackssdw                          %xmm6, %xmm4, %xmm15
    vpshufb                            %ymm9, %ymm2, %ymm4
    vcvtdq2ps                          %ymm4, %ymm4
    vbroadcastss                       .LCPI0_0(%rip), %ymm6
    vdivps                             %ymm6, %ymm4, %ymm4
    vmulps                             %ymm5, %ymm13, %ymm6
    vmulps                             %ymm5, %ymm11, %ymm5
    vmulps                             %ymm4, %ymm6, %ymm6
    vaddps                             %ymm5, %ymm6, %ymm5
    vmulps                             %ymm4, %ymm10, %ymm4
    vaddps                             %ymm5, %ymm4, %ymm4
    vaddps                             %ymm4, %ymm12, %ymm4
    vbroadcastss                       .LCPI0_0(%rip), %ymm5
    vmulps                             %ymm5, %ymm4, %ymm4
    vmaxps                             %ymm4, %ymm1, %ymm4
    vbroadcastss                       .LCPI0_0(%rip), %ymm5
    vminps                             %ymm4, %ymm5, %ymm4
    vcvttps2dq                         %ymm4, %ymm4
    vextracti128                       $1, %ymm4, %xmm5
    vpackssdw                          %xmm5, %xmm4, %xmm4
    vpshufb                            %ymm14, %ymm3, %ymm5
    vcvtdq2ps                          %ymm5, %ymm5
    vpbroadcastd                       .LCPI0_2(%rip), %ymm6
    vbroadcastss                       .LCPI0_0(%rip), %ymm7
    vdivps                             %ymm7, %ymm5, %ymm5
    vpshufb                            %ymm14, %ymm2, %ymm7
    vcvtdq2ps                          %ymm7, %ymm7
    vbroadcastss                       .LCPI0_0(%rip), %ymm8
    vdivps                             %ymm8, %ymm7, %ymm7
    vpackuswb                          %xmm4, %xmm4, %xmm4
    vmulps                             %ymm5, %ymm13, %ymm8
    vmulps                             %ymm5, %ymm11, %ymm5
    vmulps                             %ymm7, %ymm8, %ymm8
    vaddps                             %ymm5, %ymm8, %ymm5
    vmulps                             %ymm7, %ymm10, %ymm7
    vaddps                             %ymm5, %ymm7, %ymm5
    vaddps                             %ymm5, %ymm12, %ymm5
    vbroadcastss                       .LCPI0_0(%rip), %ymm7
    vmulps                             %ymm7, %ymm5, %ymm5
    vmaxps                             %ymm5, %ymm1, %ymm5
    vbroadcastss                       .LCPI0_0(%rip), %ymm7
    vminps                             %ymm5, %ymm7, %ymm5
    vcvttps2dq                         %ymm5, %ymm5
    vextracti128                       $1, %ymm5, %xmm7
    vpackssdw                          %xmm7, %xmm5, %xmm5
    vpand                              %ymm6, %ymm3, %ymm3
    vcvtdq2ps                          %ymm3, %ymm3
    vbroadcastss                       .LCPI0_0(%rip), %ymm7
    vdivps                             %ymm7, %ymm3, %ymm3
    vpand                              %ymm6, %ymm2, %ymm2
    vcvtdq2ps                          %ymm2, %ymm2
    vbroadcastss                       .LCPI0_0(%rip), %ymm6
    vdivps                             %ymm6, %ymm2, %ymm2
    vpackuswb                          %xmm5, %xmm5, %xmm5
    vmulps                             %ymm3, %ymm13, %ymm6
    vmulps                             %ymm3, %ymm11, %ymm3
    vmulps                             %ymm2, %ymm6, %ymm6
    vaddps                             %ymm3, %ymm6, %ymm3
    vbroadcastss                       .LCPI0_0(%rip), %ymm6
    vmulps                             %ymm2, %ymm10, %ymm2
    vaddps                             %ymm3, %ymm2, %ymm2
    vaddps                             %ymm2, %ymm12, %ymm2
    vmulps                             %ymm6, %ymm2, %ymm2
    vmaxps                             %ymm2, %ymm1, %ymm2
    vminps                             %ymm2, %ymm6, %ymm2
    vcvttps2dq                         %ymm2, %ymm2
    vextracti128                       $1, %ymm2, %xmm3
    vpackssdw                          %xmm3, %xmm2, %xmm2
    vpackuswb                          %xmm2, %xmm2, %xmm2
    vpmovzxwd                          %xmm15, %ymm3
    vpslld                             $24, %ymm3, %ymm3
    vpmovzxbd                          %xmm4, %ymm4
    vpslld                             $16, %ymm4, %ymm4
    vpor                               %ymm3, %ymm4, %ymm3
    vpmovzxbd                          %xmm5, %ymm4
    vpslld                             $8, %ymm4, %ymm4
    vpmovzxbd                          %xmm2, %ymm2
    vpor                               %ymm2, %ymm4, %ymm2
    vpor                               %ymm2, %ymm3, %ymm2
    vmovdqu                            %ymm2, (%r14, %r8, 4)
    addq                               $8, %r8
    cmpq                               %r8, %r11
    jne                                .LBB0_19
    cmpq                               %r11, %rbx
    vmovaps                            192(%rsp), %ymm1
    vmovaps                            %ymm10, %ymm11
    vmovaps                            224(%rsp), %ymm10
    vmovaps                            %ymm12, %ymm13
    vbroadcastss                       .LCPI0_0(%rip), %xmm12
    vxorps                             %xmm7, %xmm7, %xmm7
    je                                 .LBB0_22
.p2align 4, 0x90

.LBB0_21:
    movl                               (%rdx, %rcx, 4), %esi
    movl                               (%rdi, %rcx, 4), %r11d
    vmovd                              %esi, %xmm3
    movl                               $-16777216, %ebx
    movzbl                             %sil, %r14d
    movl                               %esi, %r12d
    shrl                               $24, %r12d
    movl                               %r11d, %r8d
    movl                               %r11d, %esi
    movq                               %r13, %rax
    movzbl                             %r11b, %r13d
    shrl                               $24, %r11d
    shrl                               $16, %r8d
    shrl                               $8, %esi
    vpbroadcastq                       .LCPI0_20(%rip), %xmm2
    vpbroadcastd                       %xmm3, %xmm3
    vpsrlvd                            %xmm2, %xmm3, %xmm3
    vpand                              .LCPI0_21(%rip), %xmm3, %xmm3
    vcvtdq2ps                          %xmm3, %xmm3
    vdivps                             %xmm12, %xmm3, %xmm3
    vmovd                              %r14d, %xmm4
    vpinsrb                            $4, %r12d, %xmm4, %xmm4
    vcvtdq2ps                          %xmm4, %xmm4
    vmovd                              %r13d, %xmm5
    movq                               %rax, %r13
    vpinsrb                            $4, %r11d, %xmm5, %xmm5
    vdivps                             %xmm12, %xmm4, %xmm4
    vcvtdq2ps                          %xmm5, %xmm5
    vdivps                             %xmm12, %xmm5, %xmm5
    vmulps                             128(%rsp), %xmm4, %xmm6
    vmulps                             96(%rsp), %xmm4, %xmm4
    vmulps                             %xmm5, %xmm6, %xmm6
    vaddps                             %xmm4, %xmm6, %xmm4
    vmovaps                            96(%rsp), %ymm6
    vmulps                             %xmm5, %xmm11, %xmm5
    vaddps                             %xmm4, %xmm5, %xmm4
    vaddps                             %xmm4, %xmm13, %xmm4
    vmulps                             %xmm4, %xmm12, %xmm4
    vmaxps                             %xmm4, %xmm7, %xmm4
    vcmpltps                           %xmm4, %xmm12, %xmm5
    vshufps                            $80, %xmm5, %xmm5, %xmm5
    vmovmskpd                          %xmm5, %r11d
    vmovshdup                          %xmm4, %xmm5
    vcvttss2si                         %xmm5, %r14d
    vcvttss2si                         %xmm4, %r12d
    shll                               $24, %r14d
    testb                              $2, %r11b
    cmovnel                            %ebx, %r14d
    movzbl                             %r8b, %r8d
    vmovd                              %r8d, %xmm4
    vpinsrb                            $4, %esi, %xmm4, %xmm4
    movzbl                             %r12b, %esi
    vcvtdq2ps                          %xmm4, %xmm4
    vdivps                             %xmm12, %xmm4, %xmm4
    vmulps                             128(%rsp), %xmm3, %xmm5
    vmulps                             %xmm6, %xmm3, %xmm3
    vmulps                             %xmm4, %xmm5, %xmm5
    vaddps                             %xmm3, %xmm5, %xmm3
    vmulps                             %xmm4, %xmm11, %xmm4
    vaddps                             %xmm3, %xmm4, %xmm3
    vaddps                             %xmm3, %xmm13, %xmm3
    vmulps                             %xmm3, %xmm12, %xmm3
    vmaxps                             %xmm3, %xmm7, %xmm3
    vminps                             %xmm3, %xmm12, %xmm3
    vcvttps2dq                         %xmm3, %xmm3
    vpshufb                            .LCPI0_22(%rip), %xmm3, %xmm3
    vpsllvd                            %xmm2, %xmm3, %xmm2
    vmovd                              %xmm2, %r8d
    orl                                %r14d, %r8d
    vpextrd                            $1, %xmm2, %r14d
    orl                                %r8d, %r14d
    testb                              $1, %r11b
    movl                               $255, %eax
    cmovnel                            %eax, %esi
    orl                                %r14d, %esi
    movl                               %esi, (%r9, %rcx, 4)
    incq                               %rcx
    cmpq                               %rcx, %r15
    jne                                .LBB0_21
    jmp                                .LBB0_22

.LBB0_23:
    leaq                               -40(%rbp), %rsp
    popq                               %rbx
    popq                               %r12
    popq                               %r13
    popq                               %r14
    popq                               %r15
    popq                               %rbp
    vzeroupper
    retq

.Lfunc_end0:
SIZE(SYM(ksvgArithmeticApplyAvx2))

.p2align 5

.LCPI0_0:
    .long 0x437f0000  // float 255

.LCPI0_1:
    .long 0x3f000000  // float 0.5

.LCPI0_2:
    .byte 255  // 0xff
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
.p2align 5, 0x0

.LCPI0_3:
    .byte 1  // 0x1
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 5  // 0x5
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 9  // 0x9
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 13  // 0xd
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 17  // 0x11
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 21  // 0x15
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 25  // 0x19
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 29  // 0x1d
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80

.LCPI0_4:
    .byte 2  // 0x2
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 6  // 0x6
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 10  // 0xa
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 14  // 0xe
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 18  // 0x12
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 22  // 0x16
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 26  // 0x1a
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 30  // 0x1e
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80

.LCPI0_5:
    .zero                              32, 15

.LCPI0_6:
    .zero                              32, 1

.LCPI0_7:
    .zero                              32, 2

.LCPI0_8:
    .zero                              32, 3

.LCPI0_9:
    .zero                              32, 4

.LCPI0_10:
    .zero                              32, 5

.LCPI0_11:
    .zero                              32, 6

.LCPI0_12:
    .zero                              32, 7

.LCPI0_13:
    .zero                              32, 8

.LCPI0_14:
    .zero                              32, 9

.LCPI0_15:
    .zero                              32, 10

.LCPI0_16:
    .zero                              32, 11

.LCPI0_17:
    .zero                              32, 12

.LCPI0_18:
    .zero                              32, 13

.LCPI0_19:
    .zero                              32, 14

.LCPI0_23:
    .zero                              32
.p2align 3, 0x0

.LCPI0_20:
    .long 16  // 0x10
    .long 8  // 0x8
.p2align 4, 0x0

.LCPI0_21:
    .byte 255  // 0xff
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 255  // 0xff
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0
    .byte 0  // 0x0

.LCPI0_22:
    .byte 0  // 0x0
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 4  // 0x4
    .byte 128  // 0x80
    .byte 128  // 0x80
    .byte 128  // 0x80
    .zero                              1
    .zero                              1
    .zero                              1
    .zero                              1
    .zero                              1
    .zero                              1
    .zero                              1
    .zero                              1

.LCPI0_24:
    .byte 15  // 0xf

.LCPI0_25:
    .byte 1  // 0x1

.LCPI0_26:
    .byte 2  // 0x2

.LCPI0_27:
    .byte 3  // 0x3

.LCPI0_28:
    .byte 4  // 0x4

.LCPI0_29:
    .byte 5  // 0x5

.LCPI0_30:
    .byte 6  // 0x6

.LCPI0_31:
    .byte 7  // 0x7

.LCPI0_32:
    .byte 8  // 0x8

.LCPI0_33:
    .byte 9  // 0x9

.LCPI0_34:
    .byte 10  // 0xa

.LCPI0_35:
    .byte 11  // 0xb

.LCPI0_36:
    .byte 12  // 0xc

.LCPI0_37:
    .byte 13  // 0xd

.LCPI0_38:
    .byte 14  // 0xe
.p2align 4, 0x90
