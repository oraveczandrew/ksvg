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
#include "turbulence_noise_common.S"

.text
.p2align 4
.globl SYM(ksvgTurbulenceApplySse2_x86_64)
TYPE(ksvgTurbulenceApplySse2_x86_64, @function)
    SYM(ksvgTurbulenceApplySse2_x86_64):
    pushq   %r15
    movq    %rdi, %r11
    movl    %esi, %r10d
    movapd  %xmm1, %xmm7
    pushq   %r14
    movapd  %xmm3, %xmm12
    pushq   %r13
    pushq   %r12
    pushq   %rbp
    movl    %r8d, %ebp
    movl    %r9d, %r8d
    pushq   %rbx
    movl    %ecx, %ebx
    subq    $69256, %rsp
    movl    69344(%rsp), %eax
    movl    %edx, 852(%rsp)
    movl    69368(%rsp), %edx
    movl    69320(%rsp), %r15d
    movsd   %xmm0, 104(%rsp)
    movl    %eax, 848(%rsp)
    movl    %eax, %r13d
    movl    $2147483646, %eax
    movl    69328(%rsp), %r14d
    cmpl    %eax, %edx
    movl    69336(%rsp), %r12d
    movsd   %xmm2, 112(%rsp)
    cmovle  %edx, %eax
    movsd   %xmm4, 120(%rsp)
    testl   %edx, %edx
    jg      .L3
    movslq  %edx, %rax
    movl    %edx, %ecx
    imulq   $-2147483645, %rax, %rax
    sarl    $31, %ecx
    shrq    $32, %rax
    addl    %edx, %eax
    sarl    $30, %eax
    subl    %ecx, %eax
    imull   $2147483646, %eax, %eax
    subl    %edx, %eax
    addl    $1, %eax
.L3:
    leaq    5504(%rsp), %rdi
    pxor    %xmm3, %xmm3
    xorl    %ecx, %ecx
    movsd   .LC2(%rip), %xmm2
    leaq    38400(%rsp), %rsi
    movq    %rdi, (%rsp)
    leaq    880(%rsp), %r9
    movq    %rsi, 16(%rsp)
.L4:
    movq    (%rsp), %rsi
    subq    $2048, %rsi
.p2align 4
.p2align 3
.L7:
    movl    %eax, %edi
    pxor    %xmm1, %xmm1
    pxor    %xmm0, %xmm0
    movl    %eax, %edx
    imulq   $110892733, %rdi, %rdi
    shrq    $32, %rdi
    subl    %edi, %edx
    shrl    %edx
    addl    %edi, %edx
    shrl    $16, %edx
    imull   $-2836, %edx, %edi
    imull   $127773, %edx, %edx
    subl    %edx, %eax
    imull   $16807, %eax, %eax
    addl    %edi, %eax
    testl   %eax, %eax
    leal    2147483647(%rax), %edx
    cmovle  %edx, %eax
    movl    %eax, %edx
    movl    %eax, %edi
    andl    $511, %edx
    subl    $256, %edx
    cvtsi2sdl %edx, %xmm1
    movl    %eax, %edx
    imulq   $110892733, %rdx, %rdx
    mulsd   %xmm2, %xmm1
    shrq    $32, %rdx
    subl    %edx, %edi
    shrl    %edi
    addl    %edx, %edi
    shrl    $16, %edi
    imull   $-2836, %edi, %edx
    imull   $127773, %edi, %edi
    subl    %edi, %eax
    imull   $16807, %eax, %eax
    addl    %edx, %eax
    testl   %eax, %eax
    leal    2147483647(%rax), %edx
    cmovle  %edx, %eax
    movl    %eax, %edx
    andl    $511, %edx
    subl    $256, %edx
    cvtsi2sdl %edx, %xmm0
    mulsd   %xmm2, %xmm0
    ucomisd %xmm3, %xmm0
    setnp   %dl
    cmovne  %ecx, %edx
    testb   %dl, %dl
    je      .L59
    ucomisd %xmm3, %xmm1
    setnp   %dl
    cmovne  %ecx, %edx
    testb   %dl, %dl
    jne     .L7
.L59:
    movapd  %xmm0, %xmm4
    movapd  %xmm1, %xmm6
    addq    $8, %rsi
    mulsd   %xmm0, %xmm4
    mulsd   %xmm1, %xmm6
    addsd   %xmm6, %xmm4
    sqrtsd  %xmm4, %xmm4
    divsd   %xmm4, %xmm1
    divsd   %xmm4, %xmm0
    movsd   %xmm1, -8(%rsi)
    movsd   %xmm0, 4104(%rsi)
    cmpq    %rsi, (%rsp)
    jne     .L7
    addq    $8224, (%rsp)
    movq    (%rsp), %rsi
    cmpq    %rsi, 16(%rsp)
    jne     .L4
    movdqa  .LC3(%rip), %xmm0
    leaq    1135(%rsp), %rcx
    movaps  %xmm0, 880(%rsp)
    movdqa  .LC3+16(%rip), %xmm0
    movaps  %xmm0, 896(%rsp)
    movdqa  .LC3+32(%rip), %xmm0
    movaps  %xmm0, 912(%rsp)
    movdqa  .LC3+48(%rip), %xmm0
    movaps  %xmm0, 928(%rsp)
    movdqa  .LC3+64(%rip), %xmm0
    movaps  %xmm0, 944(%rsp)
    movdqa  .LC3+80(%rip), %xmm0
    movaps  %xmm0, 960(%rsp)
    movdqa  .LC3+96(%rip), %xmm0
    movaps  %xmm0, 976(%rsp)
    movdqa  .LC3+112(%rip), %xmm0
    movaps  %xmm0, 992(%rsp)
    movdqa  .LC3+128(%rip), %xmm0
    movaps  %xmm0, 1008(%rsp)
    movdqa  .LC3+144(%rip), %xmm0
    movaps  %xmm0, 1024(%rsp)
    movdqa  .LC3+160(%rip), %xmm0
    movaps  %xmm0, 1040(%rsp)
    movdqa  .LC3+176(%rip), %xmm0
    movaps  %xmm0, 1056(%rsp)
    movdqa  .LC3+192(%rip), %xmm0
    movaps  %xmm0, 1072(%rsp)
    movdqa  .LC3+208(%rip), %xmm0
    movaps  %xmm0, 1088(%rsp)
    movdqa  .LC3+224(%rip), %xmm0
    movaps  %xmm0, 1104(%rsp)
    movdqa  .LC3+240(%rip), %xmm0
    movaps  %xmm0, 1120(%rsp)
.p2align 4
.p2align 3
.L12:
    movl    %eax, %esi
    movl    %eax, %edx
    imulq   $110892733, %rsi, %rsi
    shrq    $32, %rsi
    subl    %esi, %edx
    shrl    %edx
    addl    %esi, %edx
    shrl    $16, %edx
    imull   $-2836, %edx, %esi
    imull   $127773, %edx, %edx
    subl    %edx, %eax
    imull   $16807, %eax, %eax
    addl    %esi, %eax
    movzbl  (%rcx), %esi
    testl   %eax, %eax
    leal    2147483647(%rax), %edx
    cmovle  %edx, %eax
    subq    $1, %rcx
    movzbl  %al, %edx
    addq    %r9, %rdx
    movzbl  (%rdx), %edi
    movb    %dil, 1(%rcx)
    movb    %sil, (%rdx)
    cmpq    %rcx, %r9
    jne     .L12
    leaq    1136(%rsp), %rsi
    leaq    60992(%rsp), %rax
    movsd   %xmm7, 856(%rsp)
    leaq    34288(%rsp), %rdx
    leaq    2420(%rsp), %rcx
    movsd   %xmm12, 864(%rsp)
    leaq    69184(%rsp), %rdi
    movsd   %xmm5, 872(%rsp)
.L13:
    pxor    %xmm7, %xmm7
    addq    $64, %rcx
    subq    $-128, %rdx
    addq    $16, %rsi
    movdqa  -272(%rsi), %xmm0
    addq    $512, %rax
    movdqa  %xmm0, %xmm1
    movaps  %xmm0, -16(%rsi)
    punpckhbw %xmm7, %xmm0
    movapd  -30944(%rdx), %xmm11
    punpcklbw %xmm7, %xmm1
    movdqa  %xmm0, %xmm2
    pxor    %xmm7, %xmm7
    movapd  -30928(%rdx), %xmm15
    movdqa  %xmm1, %xmm3
    punpcklwd %xmm7, %xmm2
    punpckhwd %xmm7, %xmm1
    movapd  -30864(%rdx), %xmm6
    punpcklwd %xmm7, %xmm3
    punpckhwd %xmm7, %xmm0
    movups  %xmm1, -48(%rcx)
    movapd  -30848(%rdx), %xmm5
    movups  %xmm3, -1088(%rcx)
    movapd  -26848(%rdx), %xmm4
    movapd  -26832(%rdx), %xmm13
    movups  %xmm1, -1072(%rcx)
    movapd  -30960(%rdx), %xmm7
    movapd  -26816(%rdx), %xmm12
    movups  %xmm2, -1056(%rcx)
    movapd  -30912(%rdx), %xmm1
    movapd  -26800(%rdx), %xmm8
    movups  %xmm0, -1040(%rcx)
    movapd  -26784(%rdx), %xmm14
    movapd  -26768(%rdx), %xmm10
    movapd  -26752(%rdx), %xmm9
    movups  %xmm3, -64(%rcx)
    movapd  -30896(%rdx), %xmm3
    movups  %xmm2, -32(%rcx)
    movapd  -30880(%rdx), %xmm2
    movups  %xmm0, -16(%rcx)
    movapd  -26736(%rdx), %xmm0
    movaps  %xmm7, -28912(%rdx)
    movaps  %xmm11, -28896(%rdx)
    movaps  %xmm15, -28880(%rdx)
    movaps  %xmm11, 832(%rsp)
    movaps  %xmm15, 816(%rsp)
    movaps  %xmm1, 560(%rsp)
    movaps  %xmm1, -28864(%rdx)
    movapd  -22656(%rdx), %xmm1
    movaps  %xmm3, -28848(%rdx)
    movaps  %xmm2, -28832(%rdx)
    movaps  %xmm6, -28816(%rdx)
    movaps  %xmm5, -28800(%rdx)
    movaps  %xmm4, -24800(%rdx)
    movaps  %xmm13, -24784(%rdx)
    movaps  %xmm8, -24752(%rdx)
    movaps  %xmm14, -24736(%rdx)
    movaps  %xmm10, -24720(%rdx)
    movaps  %xmm9, -24704(%rdx)
    movaps  %xmm0, -24688(%rdx)
    movaps  %xmm3, 544(%rsp)
    movaps  %xmm2, 528(%rsp)
    movapd  -22672(%rdx), %xmm2
    movaps  %xmm6, 512(%rsp)
    movapd  -22688(%rdx), %xmm6
    movaps  %xmm5, 800(%rsp)
    movapd  -22640(%rdx), %xmm5
    movaps  %xmm4, 784(%rsp)
    movapd  -22624(%rdx), %xmm4
    movaps  %xmm13, 768(%rsp)
    movapd  -18624(%rdx), %xmm13
    movaps  %xmm8, 736(%rsp)
    movaps  %xmm14, 720(%rsp)
    movapd  -22720(%rdx), %xmm14
    movaps  %xmm10, 704(%rsp)
    movapd  -22704(%rdx), %xmm10
    movaps  %xmm9, 688(%rsp)
    movaps  %xmm0, 672(%rsp)
    movaps  %xmm12, -24768(%rdx)
    movaps  %xmm12, 752(%rsp)
    movapd  -18608(%rdx), %xmm12
    movapd  -18544(%rdx), %xmm15
    movapd  -18592(%rdx), %xmm8
    movapd  -18560(%rdx), %xmm0
    movaps  %xmm14, -20672(%rdx)
    movapd  -18576(%rdx), %xmm9
    movapd  -22736(%rdx), %xmm7
    movaps  %xmm15, 400(%rsp)
    movapd  -18528(%rdx), %xmm15
    movaps  %xmm10, -20656(%rdx)
    movaps  %xmm7, -20688(%rdx)
    movapd  %xmm15, %xmm11
    movaps  %xmm6, -20640(%rdx)
    movapd  -18512(%rdx), %xmm15
    movaps  %xmm2, -20624(%rdx)
    movapd  %xmm15, %xmm3
    movaps  %xmm1, -20608(%rdx)
    movapd  400(%rsp), %xmm15
    movaps  %xmm5, -20592(%rdx)
    movaps  %xmm4, -20576(%rdx)
    movaps  %xmm13, -16576(%rdx)
    movaps  %xmm12, -16560(%rdx)
    movaps  %xmm8, -16544(%rdx)
    movaps  %xmm9, -16528(%rdx)
    movaps  %xmm0, -16512(%rdx)
    movaps  %xmm15, -16496(%rdx)
    movaps  %xmm1, 656(%rsp)
    movaps  %xmm5, 640(%rsp)
    movaps  %xmm4, 496(%rsp)
    movaps  %xmm13, 480(%rsp)
    movaps  %xmm12, 464(%rsp)
    movaps  %xmm8, 448(%rsp)
    movaps  %xmm9, 432(%rsp)
    movaps  %xmm0, 416(%rsp)
    movaps  %xmm11, 384(%rsp)
    movapd  -14448(%rdx), %xmm1
    movapd  -14496(%rdx), %xmm13
    movaps  %xmm3, -16464(%rdx)
    movapd  -14464(%rdx), %xmm5
    movapd  -14480(%rdx), %xmm9
    movaps  %xmm3, 368(%rsp)
    movapd  -10368(%rdx), %xmm3
    movapd  -14432(%rdx), %xmm4
    movapd  -14416(%rdx), %xmm12
    movapd  -14512(%rdx), %xmm7
    movaps  %xmm11, -16480(%rdx)
    movaps  %xmm3, 288(%rsp)
    movapd  -10352(%rdx), %xmm3
    movapd  -14400(%rdx), %xmm8
    movapd  -10400(%rdx), %xmm0
    movaps  %xmm7, -12464(%rdx)
    movapd  -10384(%rdx), %xmm15
    movaps  %xmm3, 272(%rsp)
    movapd  -10336(%rdx), %xmm3
    movaps  %xmm13, -12448(%rdx)
    movaps  %xmm3, 256(%rsp)
    movapd  -10320(%rdx), %xmm3
    movaps  %xmm9, -12432(%rdx)
    movaps  %xmm3, 240(%rsp)
    movapd  -10304(%rdx), %xmm3
    movaps  %xmm5, -12416(%rdx)
    movaps  %xmm3, 224(%rsp)
    movapd  -10288(%rdx), %xmm3
    movaps  %xmm1, -12400(%rdx)
    movapd  %xmm3, %xmm11
    movaps  %xmm4, -12384(%rdx)
    movaps  %xmm4, 624(%rsp)
    movaps  %xmm12, 352(%rsp)
    movaps  %xmm12, -12368(%rdx)
    movapd  -6176(%rdx), %xmm7
    movapd  288(%rsp), %xmm3
    movapd  -6272(%rdx), %xmm12
    movapd  -6240(%rdx), %xmm4
    movaps  %xmm8, -12352(%rdx)
    movaps  %xmm3, -8320(%rdx)
    movapd  272(%rsp), %xmm3
    movaps  %xmm7, 160(%rsp)
    movapd  -2176(%rdx), %xmm7
    movaps  %xmm3, -8304(%rdx)
    movapd  256(%rsp), %xmm3
    movaps  %xmm7, 144(%rsp)
    movapd  -2160(%rdx), %xmm7
    movaps  %xmm3, -8288(%rdx)
    movapd  240(%rsp), %xmm3
    movaps  %xmm7, 128(%rsp)
    movapd  -2144(%rdx), %xmm7
    movaps  %xmm3, -8272(%rdx)
    movapd  224(%rsp), %xmm3
    movaps  %xmm0, -8352(%rdx)
    movaps  %xmm15, -8336(%rdx)
    movaps  %xmm3, -8256(%rdx)
    movapd  -6192(%rdx), %xmm3
    movaps  %xmm11, -8240(%rdx)
    movaps  %xmm8, 336(%rsp)
    movapd  -6256(%rdx), %xmm8
    movaps  %xmm0, 320(%rsp)
    movapd  -6224(%rdx), %xmm0
    movaps  %xmm15, 304(%rsp)
    movapd  -6208(%rdx), %xmm15
    movaps  %xmm11, 208(%rsp)
    movaps  %xmm7, 80(%rsp)
    movapd  -2128(%rdx), %xmm7
    movapd  -6288(%rdx), %xmm11
    movaps  %xmm12, -4224(%rdx)
    movaps  %xmm7, 64(%rsp)
    movapd  -2112(%rdx), %xmm7
    movaps  %xmm11, -4240(%rdx)
    movaps  %xmm7, 48(%rsp)
    movapd  -2096(%rdx), %xmm7
    movaps  %xmm8, -4208(%rdx)
    movaps  %xmm7, 32(%rsp)
    movapd  -2080(%rdx), %xmm7
    movaps  %xmm4, -4192(%rdx)
    movaps  %xmm7, 16(%rsp)
    movapd  -2064(%rdx), %xmm7
    movaps  %xmm0, -4176(%rdx)
    movaps  %xmm7, (%rsp)
    movapd  160(%rsp), %xmm7
    movaps  %xmm3, -4144(%rdx)
    movaps  %xmm7, -4128(%rdx)
    movapd  144(%rsp), %xmm7
    movaps  %xmm3, 176(%rsp)
    movaps  %xmm7, -128(%rdx)
    movapd  128(%rsp), %xmm7
    movaps  %xmm15, -4160(%rdx)
    movaps  %xmm7, -112(%rdx)
    movapd  80(%rsp), %xmm7
    movaps  %xmm15, 192(%rsp)
    movaps  %xmm7, -96(%rdx)
    movapd  64(%rsp), %xmm7
    movaps  %xmm7, -80(%rdx)
    movapd  48(%rsp), %xmm7
    movaps  %xmm7, -64(%rdx)
    movapd  32(%rsp), %xmm15
    movapd  (%rsp), %xmm3
    movapd  16(%rsp), %xmm7
    movaps  %xmm15, -48(%rdx)
    movapd  -30960(%rdx), %xmm15
    movaps  %xmm3, -16(%rdx)
    movapd  -14512(%rdx), %xmm3
    movhpd  -22736(%rdx), %xmm15
    movaps  %xmm7, -32(%rdx)
    movapd  -22736(%rdx), %xmm7
    movlpd  -30952(%rdx), %xmm7
    movaps  %xmm15, 608(%rsp)
    unpcklpd %xmm11, %xmm3
    movlpd  -14504(%rdx), %xmm11
    movaps  %xmm15, -25152(%rax)
    movapd  832(%rsp), %xmm15
    movaps  %xmm11, -16912(%rax)
    movaps  %xmm11, -25104(%rax)
    movapd  %xmm15, %xmm11
    unpckhpd %xmm14, %xmm15
    unpcklpd %xmm14, %xmm11
    movaps  %xmm7, -25120(%rax)
    movaps  %xmm11, -16896(%rax)
    movapd  %xmm13, %xmm11
    unpckhpd %xmm12, %xmm13
    unpcklpd %xmm12, %xmm11
    movaps  %xmm7, 576(%rsp)
    movapd  816(%rsp), %xmm7
    movaps  %xmm11, -16880(%rax)
    movapd  -16896(%rax), %xmm11
    movaps  %xmm3, -25136(%rax)
    movaps  %xmm11, -25088(%rax)
    movapd  -16880(%rax), %xmm11
    movaps  %xmm3, 592(%rsp)
    movapd  %xmm1, %xmm3
    movaps  %xmm11, -25072(%rax)
    movapd  %xmm7, %xmm11
    unpcklpd %xmm0, %xmm3
    unpcklpd %xmm10, %xmm11
    movaps  %xmm15, -25056(%rax)
    movapd  %xmm11, %xmm12
    movapd  %xmm9, %xmm11
    movaps  %xmm13, -25040(%rax)
    unpckhpd %xmm8, %xmm9
    unpcklpd %xmm8, %xmm11
    movaps  %xmm12, -25024(%rax)
    movapd  %xmm11, %xmm14
    movapd  %xmm7, %xmm11
    unpckhpd %xmm10, %xmm11
    movaps  %xmm14, -25008(%rax)
    movaps  %xmm11, -24992(%rax)
    movapd  560(%rsp), %xmm7
    movaps  %xmm3, 560(%rsp)
    movapd  %xmm7, %xmm10
    unpckhpd %xmm6, %xmm7
    movaps  %xmm9, -24976(%rax)
    unpcklpd %xmm6, %xmm10
    movaps  %xmm7, -24928(%rax)
    movapd  544(%rsp), %xmm6
    movapd  %xmm10, %xmm8
    movapd  %xmm5, %xmm10
    unpckhpd %xmm4, %xmm5
    unpcklpd %xmm4, %xmm10
    movapd  %xmm6, %xmm3
    movapd  %xmm6, %xmm4
    movapd  560(%rsp), %xmm6
    unpcklpd %xmm2, %xmm4
    unpckhpd %xmm2, %xmm3
    movapd  %xmm1, %xmm2
    movapd  656(%rsp), %xmm1
    unpckhpd %xmm0, %xmm2
    movaps  %xmm6, -24880(%rax)
    movapd  528(%rsp), %xmm0
    movapd  624(%rsp), %xmm6
    movaps  %xmm2, -24848(%rax)
    unpcklpd %xmm1, %xmm0
    movaps  %xmm2, 544(%rsp)
    movlpd  536(%rsp), %xmm1
    movapd  %xmm6, %xmm2
    movhpd  192(%rsp), %xmm2
    movaps  %xmm5, -24912(%rax)
    movaps  %xmm1, -16608(%rax)
    movapd  192(%rsp), %xmm1
    movaps  %xmm8, -24960(%rax)
    unpckhpd %xmm1, %xmm6
    movapd  -16608(%rax), %xmm1
    movaps  %xmm10, -24944(%rax)
    movaps  %xmm6, -16592(%rax)
    movaps  %xmm1, -24800(%rax)
    movapd  512(%rsp), %xmm1
    movaps  %xmm6, -24784(%rax)
    movapd  640(%rsp), %xmm6
    movaps  %xmm4, -24896(%rax)
    unpcklpd %xmm6, %xmm1
    movaps  %xmm3, -24864(%rax)
    movaps  %xmm1, -16576(%rax)
    movapd  352(%rsp), %xmm1
    movaps  %xmm0, -24832(%rax)
    movhpd  176(%rsp), %xmm1
    movaps  %xmm2, -24816(%rax)
    movaps  %xmm1, -16560(%rax)
    movapd  %xmm6, %xmm1
    movlpd  520(%rsp), %xmm1
    movapd  176(%rsp), %xmm6
    movlpd  360(%rsp), %xmm6
    movaps  %xmm1, -16544(%rax)
    movapd  -16576(%rax), %xmm1
    movaps  %xmm6, -16528(%rax)
    movaps  %xmm1, -24768(%rax)
    movapd  -16560(%rax), %xmm1
    movaps  %xmm6, -24720(%rax)
    movaps  %xmm1, -24752(%rax)
    movapd  -16544(%rax), %xmm1
    movaps  %xmm1, -24736(%rax)
    movapd  800(%rsp), %xmm1
    movapd  %xmm1, %xmm6
    movhpd  496(%rsp), %xmm6
    movaps  %xmm6, -16512(%rax)
    movapd  336(%rsp), %xmm6
    movhpd  160(%rsp), %xmm6
    movaps  %xmm6, -16496(%rax)
    movapd  496(%rsp), %xmm6
    unpckhpd %xmm6, %xmm1
    movapd  %xmm1, %xmm6
    movaps  %xmm1, -16480(%rax)
    movapd  160(%rsp), %xmm1
    movlpd  344(%rsp), %xmm1
    movaps  %xmm6, -24672(%rax)
    movapd  784(%rsp), %xmm6
    movaps  %xmm1, -16464(%rax)
    movapd  -16512(%rax), %xmm1
    movaps  %xmm1, -24704(%rax)
    movapd  -16496(%rax), %xmm1
    movaps  %xmm1, -24688(%rax)
    movapd  -16464(%rax), %xmm1
    movaps  %xmm1, -24656(%rax)
    movapd  %xmm6, %xmm1
    movhpd  480(%rsp), %xmm1
    movaps  %xmm1, -512(%rax)
    movapd  320(%rsp), %xmm1
    movhpd  144(%rsp), %xmm1
    movaps  %xmm1, -496(%rax)
    movapd  480(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movapd  -512(%rax), %xmm1
    movaps  %xmm6, -480(%rax)
    movapd  144(%rsp), %xmm6
    movlpd  328(%rsp), %xmm6
    movaps  %xmm1, -8704(%rax)
    movapd  -496(%rax), %xmm1
    movaps  %xmm6, -464(%rax)
    movaps  %xmm1, -8688(%rax)
    movapd  -480(%rax), %xmm1
    movaps  %xmm6, -8656(%rax)
    movapd  768(%rsp), %xmm6
    movaps  %xmm1, -8672(%rax)
    movapd  %xmm6, %xmm1
    movhpd  464(%rsp), %xmm1
    movaps  %xmm1, -448(%rax)
    movapd  304(%rsp), %xmm1
    movhpd  128(%rsp), %xmm1
    movaps  %xmm1, -432(%rax)
    movapd  464(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movapd  -448(%rax), %xmm1
    movaps  %xmm6, -416(%rax)
    movapd  128(%rsp), %xmm6
    movlpd  312(%rsp), %xmm6
    movaps  %xmm1, -8640(%rax)
    movapd  -432(%rax), %xmm1
    movaps  %xmm6, -400(%rax)
    movaps  %xmm1, -8624(%rax)
    movapd  -416(%rax), %xmm1
    movaps  %xmm1, -8608(%rax)
    movaps  %xmm6, -8592(%rax)
    movapd  752(%rsp), %xmm6
    movapd  %xmm6, %xmm1
    movhpd  448(%rsp), %xmm1
    movaps  %xmm1, -384(%rax)
    movapd  288(%rsp), %xmm1
    movhpd  80(%rsp), %xmm1
    movaps  %xmm1, -368(%rax)
    movapd  448(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movapd  -384(%rax), %xmm1
    movaps  %xmm6, -352(%rax)
    movapd  80(%rsp), %xmm6
    movlpd  296(%rsp), %xmm6
    movaps  %xmm1, -8576(%rax)
    movapd  -368(%rax), %xmm1
    movaps  %xmm6, -336(%rax)
    movaps  %xmm1, -8560(%rax)
    movapd  -352(%rax), %xmm1
    movaps  %xmm6, -8528(%rax)
    movapd  736(%rsp), %xmm6
    movaps  %xmm1, -8544(%rax)
    movapd  %xmm6, %xmm1
    movhpd  432(%rsp), %xmm1
    movaps  %xmm1, -320(%rax)
    movapd  272(%rsp), %xmm1
    movhpd  64(%rsp), %xmm1
    movaps  %xmm1, -304(%rax)
    movapd  432(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movapd  -320(%rax), %xmm1
    movaps  %xmm6, -288(%rax)
    movapd  64(%rsp), %xmm6
    movlpd  280(%rsp), %xmm6
    movaps  %xmm1, -8512(%rax)
    movapd  -304(%rax), %xmm1
    movaps  %xmm6, -272(%rax)
    movaps  %xmm1, -8496(%rax)
    movapd  -288(%rax), %xmm1
    movaps  %xmm6, -8464(%rax)
    movapd  720(%rsp), %xmm6
    movaps  %xmm1, -8480(%rax)
    movapd  %xmm6, %xmm1
    movhpd  416(%rsp), %xmm1
    movaps  %xmm1, -256(%rax)
    movapd  256(%rsp), %xmm1
    movhpd  48(%rsp), %xmm1
    movaps  %xmm1, -240(%rax)
    movapd  416(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movapd  -256(%rax), %xmm1
    movaps  %xmm6, -224(%rax)
    movapd  48(%rsp), %xmm6
    movlpd  264(%rsp), %xmm6
    movaps  %xmm1, -8448(%rax)
    movapd  -240(%rax), %xmm1
    movaps  %xmm6, -208(%rax)
    movaps  %xmm1, -8432(%rax)
    movapd  -224(%rax), %xmm1
    movaps  %xmm6, -8400(%rax)
    movapd  704(%rsp), %xmm6
    movaps  %xmm1, -8416(%rax)
    movapd  %xmm6, %xmm1
    movhpd  400(%rsp), %xmm1
    movaps  %xmm1, -192(%rax)
    movapd  240(%rsp), %xmm1
    movhpd  32(%rsp), %xmm1
    movaps  %xmm1, -176(%rax)
    movapd  400(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movaps  %xmm6, -160(%rax)
    movapd  32(%rsp), %xmm6
    movlpd  248(%rsp), %xmm6
    movaps  %xmm6, -144(%rax)
    movapd  -192(%rax), %xmm1
    movaps  %xmm6, -8336(%rax)
    movapd  688(%rsp), %xmm6
    movaps  %xmm1, -8384(%rax)
    movapd  -176(%rax), %xmm1
    movaps  %xmm1, -8368(%rax)
    movapd  -160(%rax), %xmm1
    movaps  %xmm1, -8352(%rax)
    movapd  %xmm6, %xmm1
    movhpd  384(%rsp), %xmm1
    movaps  %xmm1, -128(%rax)
    movapd  224(%rsp), %xmm1
    movhpd  16(%rsp), %xmm1
    movaps  %xmm1, -112(%rax)
    movapd  384(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movapd  -128(%rax), %xmm1
    movaps  %xmm6, -96(%rax)
    movapd  16(%rsp), %xmm6
    movlpd  232(%rsp), %xmm6
    movaps  %xmm1, -8320(%rax)
    movapd  -112(%rax), %xmm1
    movaps  %xmm6, -80(%rax)
    movaps  %xmm1, -8304(%rax)
    movapd  -96(%rax), %xmm1
    movaps  %xmm6, -8272(%rax)
    movapd  672(%rsp), %xmm6
    movaps  %xmm1, -8288(%rax)
    movapd  %xmm6, %xmm1
    movhpd  368(%rsp), %xmm1
    movaps  %xmm1, -64(%rax)
    movapd  208(%rsp), %xmm1
    movhpd  (%rsp), %xmm1
    movaps  %xmm1, -48(%rax)
    movapd  368(%rsp), %xmm1
    unpckhpd %xmm1, %xmm6
    movaps  %xmm6, -32(%rax)
    movapd  (%rsp), %xmm6
    movapd  -64(%rax), %xmm1
    movlpd  216(%rsp), %xmm6
    movaps  %xmm7, -16736(%rax)
    movapd  544(%rsp), %xmm7
    movaps  %xmm1, -8256(%rax)
    movapd  -48(%rax), %xmm1
    movaps  %xmm6, -16(%rax)
    movaps  %xmm6, -8208(%rax)
    movapd  608(%rsp), %xmm6
    movaps  %xmm5, -16720(%rax)
    movapd  560(%rsp), %xmm5
    movaps  %xmm6, -16960(%rax)
    movapd  592(%rsp), %xmm6
    movaps  %xmm1, -8240(%rax)
    movapd  -32(%rax), %xmm1
    movaps  %xmm6, -16944(%rax)
    movapd  576(%rsp), %xmm6
    movaps  %xmm1, -8224(%rax)
    movaps  %xmm6, -16928(%rax)
    movaps  %xmm15, -16864(%rax)
    movaps  %xmm13, -16848(%rax)
    movaps  %xmm12, -16832(%rax)
    movaps  %xmm14, -16816(%rax)
    movaps  %xmm11, -16800(%rax)
    movaps  %xmm9, -16784(%rax)
    movaps  %xmm8, -16768(%rax)
    movaps  %xmm10, -16752(%rax)
    movaps  %xmm4, -16704(%rax)
    movaps  %xmm5, -16688(%rax)
    movaps  %xmm3, -16672(%rax)
    movaps  %xmm7, -16656(%rax)
    movaps  %xmm0, -16640(%rax)
    movaps  %xmm2, -16624(%rax)
    cmpq    %rdi, %rax
    jne     .L13
    movzbl  1136(%rsp), %eax
    movslq  %r10d, %rcx
    xorl    %esi, %esi
    movq    %r11, %rdi
    movsd   5504(%rsp), %xmm1
    movsd   9616(%rsp), %xmm0
    movl    %r8d, 128(%rsp)
    movsd   856(%rsp), %xmm7
    movl    %eax, 2420(%rsp)
    movsd   %xmm1, 7552(%rsp)
    movsd   864(%rsp), %xmm12
    movsd   872(%rsp), %xmm5
    movsd   %xmm0, 11664(%rsp)
    movsd   %xmm1, 44544(%rsp)
    movsd   %xmm0, 60992(%rsp)
    movsd   %xmm1, 52736(%rsp)
    movsd   13728(%rsp), %xmm1
    movsd   %xmm0, 69184(%rsp)
    movsd   17840(%rsp), %xmm0
    movsd   %xmm1, 15776(%rsp)
    movsd   %xmm0, 19888(%rsp)
    movsd   %xmm1, 44552(%rsp)
    movsd   %xmm0, 61000(%rsp)
    movsd   %xmm1, 52744(%rsp)
    movsd   21952(%rsp), %xmm1
    movsd   %xmm0, 69192(%rsp)
    movsd   26064(%rsp), %xmm0
    movsd   %xmm7, 80(%rsp)
    movsd   %xmm12, 64(%rsp)
    movsd   %xmm5, 32(%rsp)
    movsd   %xmm1, 24000(%rsp)
    movsd   %xmm0, 28112(%rsp)
    movsd   %xmm1, 44560(%rsp)
    movsd   %xmm0, 61008(%rsp)
    movsd   %xmm1, 52752(%rsp)
    movsd   %xmm0, 69200(%rsp)
    movzwl  1136(%rsp), %edx
    movsd   34288(%rsp), %xmm0
    movsd   30176(%rsp), %xmm1
    movw    %dx, 1392(%rsp)
    movzbl  1137(%rsp), %edx
    movsd   %xmm0, 36336(%rsp)
    movd    %edx, %xmm7
    movl    %edx, 2424(%rsp)
    movsd   %xmm0, 61016(%rsp)
    movsd   %xmm0, 69208(%rsp)
    movd    %eax, %xmm0
    movsd   %xmm1, 32224(%rsp)
    punpckldq %xmm7, %xmm0
    movsd   %xmm1, 44568(%rsp)
    movsd   %xmm1, 52760(%rsp)
    movsd   5512(%rsp), %xmm1
    movq    %xmm0, 3444(%rsp)
    movsd   9624(%rsp), %xmm0
    movsd   %xmm1, 7560(%rsp)
    movsd   %xmm0, 11672(%rsp)
    movsd   %xmm1, 44576(%rsp)
    movsd   %xmm0, 61024(%rsp)
    movsd   %xmm1, 52768(%rsp)
    movsd   13736(%rsp), %xmm1
    movsd   %xmm0, 69216(%rsp)
    movsd   17848(%rsp), %xmm0
    movsd   %xmm1, 15784(%rsp)
    movsd   %xmm0, 19896(%rsp)
    movsd   %xmm1, 44584(%rsp)
    movsd   %xmm0, 61032(%rsp)
    movsd   %xmm1, 52776(%rsp)
    movsd   21960(%rsp), %xmm1
    movsd   %xmm0, 69224(%rsp)
    movsd   26072(%rsp), %xmm0
    movsd   %xmm1, 24008(%rsp)
    movsd   %xmm0, 28120(%rsp)
    movslq  852(%rsp), %rdx
    movsd   %xmm1, 44592(%rsp)
    imulq   %rcx, %rdx
    movl    %r10d, 16(%rsp)
    movsd   %xmm0, 61040(%rsp)
    movsd   %xmm1, 52784(%rsp)
    movsd   30184(%rsp), %xmm1
    movsd   %xmm0, 69232(%rsp)
    salq    $2, %rdx
    movsd   34296(%rsp), %xmm0
    movq    %rcx, (%rsp)
    movsd   %xmm1, 32232(%rsp)
    movsd   %xmm0, 36344(%rsp)
    movsd   %xmm1, 44600(%rsp)
    movsd   %xmm0, 61048(%rsp)
    movsd   %xmm1, 52792(%rsp)
    movsd   %xmm0, 69240(%rsp)
    call    SYM(memset)
    testl   %r15d, %r15d
    movq    %rax, %r11
    setg    %al
    testl   %r14d, %r14d
    setg    %dl
    orl     %edx, %eax
    cmpl    69312(%rsp), %ebp
    jge     .L1
    cmpb    $1, 848(%rsp)
    movq    (%rsp), %rcx
    movq    $0x000000000, 48(%rsp)
    movl    16(%rsp), %r10d
    movsd   32(%rsp), %xmm5
    movsd   64(%rsp), %xmm12
    movsd   80(%rsp), %xmm7
    movl    128(%rsp), %r8d
    jne     .L16
    movsd   .LC0(%rip), %xmm2
    movsd   %xmm2, 48(%rsp)
.L16:
    cmpb    $1, 848(%rsp)
    movsd   .LC20(%rip), %xmm2
    jne     .L18
    movsd   .LC19(%rip), %xmm2
.L18:
    cmpl    %r8d, %ebx
    jge     .L1
    testb   %al, %al
    je      .L82
    movl    %r10d, %eax
    xorl    %edi, %edi
    movapd  %xmm7, %xmm13
    movsd   %xmm2, 80(%rsp)
    imull   %ebp, %eax
    movl    69312(%rsp), %esi
    leaq    0(, %rcx, 4), %rdx
    movslq  %ebx, %rcx
    movsd   .LC22(%rip), %xmm9
    movsd   .LC27(%rip), %xmm6
    movapd  %xmm5, %xmm15
    movsd   .LC26(%rip), %xmm14
    subl    %ebp, %esi
    cltq
    movsd   %xmm6, 64(%rsp)
    movsd   %xmm9, 208(%rsp)
    addq    %rcx, %rax
    leaq    (%r11, %rax, 4), %rax
    movq    %rax, %rcx
    movl    %ebx, %eax
    movl    %r8d, %ebx
    movl    %esi, %r8d
.L36:
    leal    0(%rbp, %rdi), %esi
    pxor    %xmm0, %xmm0
    pxor    %xmm7, %xmm7
    xorl    %r11d, %r11d
    cvtsi2sdl %esi, %xmm0
    movl    %ebx, %esi
    movq    %rcx, 128(%rsp)
    cvtsi2sdl %edi, %xmm7
    subl    %eax, %esi
    movl    %r8d, 224(%rsp)
    movq    %rsi, 160(%rsp)
    movq    %rdx, 240(%rsp)
    mulsd   %xmm12, %xmm0
    movl    %edi, 256(%rsp)
    mulsd   %xmm13, %xmm7
    movl    %eax, 144(%rsp)
    movl    %ebx, 272(%rsp)
    movsd   %xmm15, 320(%rsp)
    movsd   %xmm13, 288(%rsp)
    movsd   %xmm12, 304(%rsp)
    addsd   %xmm15, %xmm0
    divsd   69360(%rsp), %xmm0
    movapd  %xmm0, %xmm6
    movsd   208(%rsp), %xmm15
    mulsd   %xmm13, %xmm6
    movsd   %xmm7, 192(%rsp)
    movsd   %xmm6, 176(%rsp)
.L35:
    pxor    %xmm10, %xmm10
    movsd   104(%rsp), %xmm7
    pxor    %xmm8, %xmm8
    movl    144(%rsp), %ebx
    cvtsi2sdl %r11d, %xmm10
    leal    (%rbx, %r11), %edx
    cvtsi2sdl %edx, %xmm8
    mulsd   112(%rsp), %xmm8
    addsd   120(%rsp), %xmm8
    divsd   69352(%rsp), %xmm8
    mulsd   %xmm7, %xmm8
    mulsd   %xmm7, %xmm10
    testl   %r12d, %r12d
    jle     .L58
    pxor    %xmm7, %xmm7
    movl    %r14d, %r8d
    movl    %r15d, %edi
    xorl    %r10d, %r10d
    movsd   176(%rsp), %xmm12
    movaps  %xmm7, 32(%rsp)
    movsd   192(%rsp), %xmm13
    movsd   .LC0(%rip), %xmm11
    movaps  %xmm7, 16(%rsp)
    movsd   %xmm10, (%rsp)
    jmp     .L51
.p2align 4, , 10
.p2align 3
.L84:
    divpd   %xmm0, %xmm3
    addpd   16(%rsp), %xmm3
    movaps  %xmm3, 16(%rsp)
.L80:
    divpd   %xmm0, %xmm1
    movsd   (%rsp), %xmm2
    addl    $1, %r10d
    addl    %edi, %edi
    addsd   %xmm8, %xmm8
    addsd   %xmm12, %xmm12
    addl    %r8d, %r8d
    movapd  %xmm2, %xmm7
    addsd   %xmm13, %xmm13
    addsd   %xmm11, %xmm11
    addsd   %xmm2, %xmm7
    movsd   %xmm7, (%rsp)
    addpd   32(%rsp), %xmm1
    movaps  %xmm1, 32(%rsp)
    cmpl    %r10d, %r12d
    je      .L83
.L51:
    movsd   .LC21(%rip), %xmm2
    addsd   %xmm8, %xmm2
    movapd  %xmm2, %xmm1
    movapd  %xmm2, %xmm0
    andpd   %xmm14, %xmm1
    ucomisd %xmm1, %xmm15
    jbe     .L38
    cvttsd2siq %xmm2, %rax
    pxor    %xmm1, %xmm1
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rax, %xmm1
    movapd  %xmm1, %xmm0
    cmpnlesd %xmm2, %xmm0
    andpd   %xmm7, %xmm0
    subsd   %xmm0, %xmm1
    movapd  %xmm14, %xmm0
    andnpd  %xmm2, %xmm0
    orpd    %xmm1, %xmm0
.L38:
    cvttsd2sil %xmm0, %ecx
    subsd   %xmm0, %xmm2
    movsd   .LC21(%rip), %xmm0
    addsd   %xmm12, %xmm0
    movapd  %xmm2, %xmm6
    subsd   .LC0(%rip), %xmm6
    leal    1(%rcx), %r9d
    movapd  %xmm0, %xmm1
    movapd  %xmm0, %xmm3
    andpd   %xmm14, %xmm1
    ucomisd %xmm1, %xmm15
    jbe     .L39
    cvttsd2siq %xmm0, %rax
    pxor    %xmm1, %xmm1
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rax, %xmm1
    movapd  %xmm1, %xmm3
    cmpnlesd %xmm0, %xmm3
    andpd   %xmm7, %xmm3
    subsd   %xmm3, %xmm1
    movapd  %xmm14, %xmm3
    andnpd  %xmm0, %xmm3
    orpd    %xmm1, %xmm3
.L39:
    subsd   %xmm3, %xmm0
    movapd  %xmm0, %xmm1
    subsd   .LC0(%rip), %xmm1
    testl   %edi, %edi
    jle     .L40
    movsd   (%rsp), %xmm10
    movapd  %xmm10, %xmm4
    movapd  %xmm10, %xmm5
    andpd   %xmm14, %xmm4
    ucomisd %xmm4, %xmm15
    jbe     .L41
    cvttsd2siq %xmm10, %rax
    pxor    %xmm4, %xmm4
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rax, %xmm4
    movapd  %xmm4, %xmm5
    cmpnlesd %xmm10, %xmm5
    andpd   %xmm7, %xmm5
    subsd   %xmm5, %xmm4
    movapd  %xmm14, %xmm5
    andnpd  %xmm10, %xmm5
    orpd    %xmm4, %xmm5
.L41:
    cvttsd2sil %xmm5, %eax
    leal    4096(%rdi, %rax), %eax
    cmpl    %ecx, %eax
    jg      .L42
    subl    %edi, %ecx
.L43:
    subl    %edi, %r9d
.L40:
    cvttsd2sil %xmm3, %eax
    leal    1(%rax), %edx
    testl   %r8d, %r8d
    jle     .L44
    movapd  %xmm13, %xmm3
    movapd  %xmm13, %xmm4
    andpd   %xmm14, %xmm3
    ucomisd %xmm3, %xmm15
    jbe     .L45
    cvttsd2siq %xmm13, %rsi
    pxor    %xmm3, %xmm3
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rsi, %xmm3
    movapd  %xmm3, %xmm4
    cmpnlesd %xmm13, %xmm4
    andpd   %xmm7, %xmm4
    subsd   %xmm4, %xmm3
    movapd  %xmm14, %xmm4
    andnpd  %xmm13, %xmm4
    orpd    %xmm3, %xmm4
.L45:
    cvttsd2sil %xmm4, %esi
    leal    4096(%r8, %rsi), %esi
    cmpl    %eax, %esi
    jg      .L46
    subl    %r8d, %eax
.L47:
    subl    %r8d, %edx
.L44:
    movapd  %xmm2, %xmm3
    movzbl  %cl, %ecx
    movapd  %xmm0, %xmm4
    movzbl  %al, %eax
    addsd   %xmm2, %xmm3
    addsd   %xmm0, %xmm4
    movapd  %xmm0, %xmm7
    movzbl  %dl, %edx
    mulsd   %xmm0, %xmm7
    unpcklpd %xmm0, %xmm0
    unpcklpd %xmm1, %xmm1
    movzbl  %r9b, %r9d
    movsd   .LC24(%rip), %xmm5
    movzbl  880(%rsp, %rcx), %esi
    unpcklpd %xmm6, %xmm6
    movzbl  880(%rsp, %r9), %r9d
    subsd   %xmm3, %xmm5
    movapd  %xmm2, %xmm3
    leal    (%rax, %rsi), %ecx
    addl    %edx, %esi
    mulsd   %xmm2, %xmm3
    movslq  %ecx, %rcx
    unpcklpd %xmm2, %xmm2
    movslq  %esi, %rsi
    movzbl  880(%rsp, %rcx), %ecx
    movzbl  880(%rsp, %rsi), %esi
    addl    %r9d, %eax
    addl    %r9d, %edx
    cltq
    movslq  %edx, %rdx
    salq    $5, %rcx
    salq    $5, %rsi
    movzbl  880(%rsp, %rax), %eax
    movzbl  880(%rsp, %rdx), %edx
    movapd  52800(%rsp, %rsi), %xmm9
    mulsd   %xmm3, %xmm5
    movsd   .LC24(%rip), %xmm3
    salq    $5, %rax
    mulpd   %xmm1, %xmm9
    salq    $5, %rdx
    movapd  36352(%rsp, %rax), %xmm10
    subsd   %xmm4, %xmm3
    movapd  36352(%rsp, %rcx), %xmm4
    mulpd   %xmm6, %xmm10
    mulpd   %xmm2, %xmm4
    mulsd   %xmm3, %xmm7
    unpcklpd %xmm5, %xmm5
    movapd  52800(%rsp, %rcx), %xmm3
    mulpd   %xmm0, %xmm3
    unpcklpd %xmm7, %xmm7
    addpd   %xmm4, %xmm3
    movapd  36352(%rsp, %rsi), %xmm4
    mulpd   %xmm2, %xmm4
    addpd   %xmm4, %xmm9
    movapd  52800(%rsp, %rax), %xmm4
    mulpd   %xmm0, %xmm4
    addpd   %xmm10, %xmm4
    movapd  36352(%rsp, %rdx), %xmm10
    mulpd   %xmm6, %xmm10
    subpd   %xmm3, %xmm4
    mulpd   %xmm5, %xmm4
    addpd   %xmm3, %xmm4
    movapd  52800(%rsp, %rdx), %xmm3
    mulpd   %xmm1, %xmm3
    addpd   %xmm10, %xmm3
    subpd   %xmm9, %xmm3
    mulpd   %xmm5, %xmm3
    addpd   %xmm9, %xmm3
    movapd  36368(%rsp, %rcx), %xmm9
    mulpd   %xmm2, %xmm9
    mulpd   36368(%rsp, %rsi), %xmm2
    subpd   %xmm4, %xmm3
    mulpd   %xmm7, %xmm3
    addpd   %xmm4, %xmm3
    movapd  52816(%rsp, %rcx), %xmm4
    mulpd   %xmm0, %xmm4
    mulpd   52816(%rsp, %rax), %xmm0
    addpd   %xmm9, %xmm4
    movapd  52816(%rsp, %rsi), %xmm9
    mulpd   %xmm1, %xmm9
    mulpd   52816(%rsp, %rdx), %xmm1
    addpd   %xmm9, %xmm2
    movapd  36368(%rsp, %rax), %xmm9
    mulpd   %xmm6, %xmm9
    mulpd   36368(%rsp, %rdx), %xmm6
    addpd   %xmm9, %xmm0
    addpd   %xmm6, %xmm1
    subpd   %xmm4, %xmm0
    subpd   %xmm2, %xmm1
    mulpd   %xmm5, %xmm0
    mulpd   %xmm5, %xmm1
    addpd   %xmm4, %xmm0
    addpd   %xmm2, %xmm1
    subpd   %xmm0, %xmm1
    mulpd   %xmm7, %xmm1
    addpd   %xmm0, %xmm1
    movapd  %xmm11, %xmm0
    unpcklpd %xmm0, %xmm0
    cmpb    $1, %r13b
    je      .L84
    andpd   .LC25(%rip), %xmm3
    andpd   .LC25(%rip), %xmm1
    divpd   %xmm0, %xmm3
    addpd   16(%rsp), %xmm3
    movaps  %xmm3, 16(%rsp)
    jmp     .L80
.L85:
    movapd  %xmm0, %xmm4
    movsd   80(%rsp), %xmm3
    movq    %r11, %rdx
    movq    %r14, %rdi
    movapd  %xmm4, %xmm7
    movq    %r15, %r11
    unpckhpd %xmm7, %xmm7
    movapd  %xmm7, %xmm6
    movapd  %xmm5, %xmm7
    unpckhpd %xmm5, %xmm5
    movapd  %xmm5, %xmm0
.L21:
    addsd   48(%rsp), %xmm7
    mulsd   32(%rsp), %xmm7
    addsd   64(%rsp), %xmm7
    movapd  %xmm7, %xmm10
    andpd   %xmm15, %xmm10
    ucomisd %xmm10, %xmm2
    jbe     .L29
    cvttsd2siq %xmm7, %rax
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm5
    cvtsi2sdq %rax, %xmm10
    movapd  %xmm10, %xmm12
    cmpnlesd %xmm7, %xmm12
    andpd   %xmm5, %xmm12
    subsd   %xmm12, %xmm10
    movapd  %xmm15, %xmm12
    andnpd  %xmm7, %xmm12
    movapd  %xmm10, %xmm7
    orpd    %xmm12, %xmm7
.L29:
    addsd   48(%rsp), %xmm0
    mulsd   32(%rsp), %xmm0
    addsd   64(%rsp), %xmm0
    movapd  %xmm0, %xmm10
    andpd   %xmm15, %xmm10
    ucomisd %xmm10, %xmm2
    jbe     .L30
    cvttsd2siq %xmm0, %rax
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm5
    cvtsi2sdq %rax, %xmm10
    movapd  %xmm10, %xmm12
    cmpnlesd %xmm0, %xmm12
    andpd   %xmm5, %xmm12
    subsd   %xmm12, %xmm10
    movapd  %xmm15, %xmm12
    andnpd  %xmm0, %xmm12
    movapd  %xmm10, %xmm0
    orpd    %xmm12, %xmm0
.L30:
    addsd   48(%rsp), %xmm4
    mulsd   32(%rsp), %xmm4
    addsd   64(%rsp), %xmm4
    movapd  %xmm4, %xmm10
    andpd   %xmm15, %xmm10
    ucomisd %xmm10, %xmm2
    jbe     .L31
    cvttsd2siq %xmm4, %rax
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm5
    cvtsi2sdq %rax, %xmm10
    movapd  %xmm10, %xmm12
    cmpnlesd %xmm4, %xmm12
    andpd   %xmm5, %xmm12
    subsd   %xmm12, %xmm10
    movapd  %xmm15, %xmm12
    andnpd  %xmm4, %xmm12
    movapd  %xmm10, %xmm4
    orpd    %xmm12, %xmm4
.L31:
    addsd   48(%rsp), %xmm6
    mulsd   32(%rsp), %xmm6
    addsd   64(%rsp), %xmm6
    movapd  %xmm6, %xmm10
    andpd   %xmm15, %xmm10
    ucomisd %xmm10, %xmm2
    jbe     .L32
    cvttsd2siq %xmm6, %rax
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm13
    cvtsi2sdq %rax, %xmm10
    movapd  %xmm10, %xmm12
    cmpnlesd %xmm6, %xmm12
    andpd   %xmm13, %xmm12
    subsd   %xmm12, %xmm10
    movapd  %xmm15, %xmm12
    andnpd  %xmm6, %xmm12
    movapd  %xmm10, %xmm6
    orpd    %xmm12, %xmm6
.L32:
    cvttsd2sil %xmm7, %eax
    movl    $255, %r9d
    movl    $255, %r14d
    cmpl    %r9d, %eax
    cmovg   %r9d, %eax
    xorl    %r9d, %r9d
    testl   %eax, %eax
    cmovs   %r9d, %eax
    sall    $16, %eax
    movl    %eax, %r9d
    cvttsd2sil %xmm6, %eax
    cmpl    %r14d, %eax
    cmovg   %r14d, %eax
    xorl    %r14d, %r14d
    testl   %eax, %eax
    cmovs   %r14d, %eax
    movl    $255, %r14d
    sall    $24, %eax
    orl     %r9d, %eax
    cvttsd2sil %xmm4, %r9d
    cmpl    %r14d, %r9d
    cmovg   %r14d, %r9d
    xorl    %r14d, %r14d
    testl   %r9d, %r9d
    cmovs   %r14d, %r9d
    orl     %r9d, %eax
    cvttsd2sil %xmm0, %r9d
    movl    %eax, %r14d
    movl    $255, %eax
    cmpl    %eax, %r9d
    cmovg   %eax, %r9d
    xorl    %eax, %eax
    testl   %r9d, %r9d
    cmovs   %eax, %r9d
    movl    %r9d, %eax
    sall    $8, %eax
    orl     %r14d, %eax
    movl    %eax, (%rdx, %r11, 4)
    addq    $1, %r11
    cmpq    %r11, 128(%rsp)
    jne     .L33
    movsd   160(%rsp), %xmm13
    movq    %rdi, %rax
    addl    $1, %ebp
    addq    %rdi, %rdx
    movsd   176(%rsp), %xmm12
    movsd   192(%rsp), %xmm3
    cmpl    %ebp, 69312(%rsp)
    jne     .L34
.L1:
    addq    $69256, %rsp
    popq    %rbx
    popq    %rbp
    popq    %r12
    popq    %r13
    popq    %r14
    popq    %r15
    ret
.L82:
    movl    %r10d, %eax
    salq    $2, %rcx
    movapd  %xmm7, %xmm13
    movapd  %xmm5, %xmm3
    imull   %ebp, %eax
    movsd   %xmm2, 32(%rsp)
    movsd   .LC22(%rip), %xmm9
    movsd   .LC27(%rip), %xmm6
    movsd   .LC0(%rip), %xmm8
    movsd   .LC26(%rip), %xmm15
    movsd   %xmm6, 64(%rsp)
    movsd   %xmm9, 144(%rsp)
    cltq
    leaq    (%r11, %rax, 4), %rdx
    movslq  %ebx, %rax
    movq    %rax, %rsi
    movq    %rcx, %rax
.L34:
    pxor    %xmm0, %xmm0
    movl    %r8d, %ecx
    movq    %rsi, %r11
    movq    %rax, %rdi
    movsd   %xmm3, 192(%rsp)
    cvtsi2sdl %ebp, %xmm0
    subl    %ebx, %ecx
    movsd   %xmm13, 160(%rsp)
    addq    %rsi, %rcx
    movq    %rcx, 128(%rsp)
    movsd   %xmm12, 176(%rsp)
    mulsd   %xmm12, %xmm0
    addsd   %xmm3, %xmm0
    divsd   69360(%rsp), %xmm0
    movapd  %xmm0, %xmm2
    mulsd   %xmm13, %xmm2
    movapd  %xmm2, %xmm3
    movsd   144(%rsp), %xmm2
.L33:
    pxor    %xmm10, %xmm10
    cvtsi2sdl %r11d, %xmm10
    mulsd   112(%rsp), %xmm10
    addsd   120(%rsp), %xmm10
    divsd   69352(%rsp), %xmm10
    mulsd   104(%rsp), %xmm10
    testl   %r12d, %r12d
    jle     .L57
    pxor    %xmm7, %xmm7
    movq    %r11, %r15
    movapd  %xmm3, %xmm13
    xorl    %r9d, %r9d
    movaps  %xmm7, (%rsp)
    movapd  %xmm8, %xmm12
    movq    %rdi, %r14
    movq    %rdx, %r11
    movaps  %xmm7, 16(%rsp)
    movsd   %xmm3, 80(%rsp)
    jmp     .L26
.p2align 4, , 10
.p2align 3
.L86:
    andpd   .LC25(%rip), %xmm5
    andpd   .LC25(%rip), %xmm0
    divpd   %xmm1, %xmm5
    addpd   16(%rsp), %xmm5
    movaps  %xmm5, 16(%rsp)
.L79:
    divpd   %xmm1, %xmm0
    addl    $1, %r9d
    addsd   %xmm10, %xmm10
    addsd   %xmm13, %xmm13
    addsd   %xmm12, %xmm12
    addpd   (%rsp), %xmm0
    movaps  %xmm0, (%rsp)
    cmpl    %r9d, %r12d
    je      .L85
.L26:
    movsd   .LC21(%rip), %xmm1
    addsd   %xmm10, %xmm1
    movapd  %xmm1, %xmm4
    movapd  %xmm1, %xmm0
    andpd   %xmm15, %xmm4
    ucomisd %xmm4, %xmm2
    jbe     .L22
    cvttsd2siq %xmm1, %rax
    pxor    %xmm4, %xmm4
    cvtsi2sdq %rax, %xmm4
    movapd  %xmm4, %xmm0
    cmpnlesd %xmm1, %xmm0
    andpd   %xmm8, %xmm0
    subsd   %xmm0, %xmm4
    movapd  %xmm15, %xmm0
    andnpd  %xmm1, %xmm0
    orpd    %xmm4, %xmm0
.L22:
    movsd   .LC21(%rip), %xmm4
    cvttsd2sil %xmm0, %edi
    subsd   %xmm0, %xmm1
    addsd   %xmm13, %xmm4
    movapd  %xmm1, %xmm0
    subsd   %xmm8, %xmm0
    movapd  %xmm4, %xmm6
    movapd  %xmm4, %xmm5
    andpd   %xmm15, %xmm6
    ucomisd %xmm6, %xmm2
    jbe     .L23
    cvttsd2siq %xmm4, %rax
    pxor    %xmm6, %xmm6
    cvtsi2sdq %rax, %xmm6
    movapd  %xmm6, %xmm5
    cmpnlesd %xmm4, %xmm5
    andpd   %xmm8, %xmm5
    subsd   %xmm5, %xmm6
    movapd  %xmm15, %xmm5
    andnpd  %xmm4, %xmm5
    orpd    %xmm6, %xmm5
.L23:
    cvttsd2sil %xmm5, %eax
    subsd   %xmm5, %xmm4
    movapd  %xmm1, %xmm5
    movzbl  %dil, %ecx
    addsd   %xmm1, %xmm5
    addl    $1, %edi
    unpcklpd %xmm0, %xmm0
    movsd   .LC24(%rip), %xmm7
    movsd   .LC24(%rip), %xmm11
    movzbl  880(%rsp, %rcx), %ecx
    movzbl  %dil, %edi
    movzbl  880(%rsp, %rdi), %r10d
    movapd  %xmm4, %xmm9
    subsd   %xmm5, %xmm7
    movapd  %xmm1, %xmm5
    subsd   %xmm8, %xmm9
    movzbl  %al, %edx
    mulsd   %xmm1, %xmm5
    leal    (%rcx, %rdx), %edi
    addl    $1, %eax
    addl    %r10d, %edx
    movslq  %edi, %rdi
    unpcklpd %xmm1, %xmm1
    movzbl  %al, %eax
    movslq  %edx, %rdx
    movzbl  880(%rsp, %rdi), %edi
    addl    %eax, %ecx
    unpcklpd %xmm9, %xmm9
    movzbl  880(%rsp, %rdx), %edx
    movslq  %ecx, %rcx
    addl    %eax, %r10d
    salq    $5, %rdi
    movzbl  880(%rsp, %rcx), %ecx
    salq    $5, %rdx
    movslq  %r10d, %r10
    movapd  52800(%rsp, %rdi), %xmm6
    mulsd   %xmm5, %xmm7
    movapd  %xmm4, %xmm5
    movapd  52800(%rsp, %rdx), %xmm3
    addsd   %xmm4, %xmm5
    salq    $5, %rcx
    movzbl  880(%rsp, %r10), %eax
    movapd  36352(%rsp, %rcx), %xmm14
    salq    $5, %rax
    subsd   %xmm5, %xmm11
    mulpd   %xmm1, %xmm14
    movapd  %xmm4, %xmm5
    mulsd   %xmm4, %xmm5
    unpcklpd %xmm4, %xmm4
    unpcklpd %xmm7, %xmm7
    mulpd   %xmm4, %xmm6
    mulpd   %xmm4, %xmm3
    mulsd   %xmm5, %xmm11
    movapd  36352(%rsp, %rdi), %xmm5
    mulpd   %xmm1, %xmm5
    unpcklpd %xmm11, %xmm11
    addpd   %xmm6, %xmm5
    movapd  52800(%rsp, %rcx), %xmm6
    mulpd   %xmm9, %xmm6
    addpd   %xmm6, %xmm14
    movapd  36352(%rsp, %rdx), %xmm6
    mulpd   %xmm0, %xmm6
    addpd   %xmm3, %xmm6
    movapd  52800(%rsp, %rax), %xmm3
    mulpd   %xmm9, %xmm3
    subpd   %xmm5, %xmm6
    mulpd   %xmm7, %xmm6
    addpd   %xmm5, %xmm6
    movapd  36352(%rsp, %rax), %xmm5
    mulpd   %xmm0, %xmm5
    addpd   %xmm3, %xmm5
    subpd   %xmm14, %xmm5
    mulpd   %xmm7, %xmm5
    addpd   %xmm14, %xmm5
    movapd  36368(%rsp, %rdi), %xmm14
    mulpd   %xmm1, %xmm14
    mulpd   36368(%rsp, %rcx), %xmm1
    subpd   %xmm6, %xmm5
    mulpd   %xmm11, %xmm5
    addpd   %xmm6, %xmm5
    movapd  52816(%rsp, %rdi), %xmm6
    mulpd   %xmm4, %xmm6
    mulpd   52816(%rsp, %rdx), %xmm4
    addpd   %xmm6, %xmm14
    movapd  52816(%rsp, %rcx), %xmm6
    mulpd   %xmm9, %xmm6
    mulpd   52816(%rsp, %rax), %xmm9
    addpd   %xmm6, %xmm1
    movapd  36368(%rsp, %rdx), %xmm6
    mulpd   %xmm0, %xmm6
    mulpd   36368(%rsp, %rax), %xmm0
    addpd   %xmm4, %xmm6
    addpd   %xmm9, %xmm0
    subpd   %xmm14, %xmm6
    subpd   %xmm1, %xmm0
    mulpd   %xmm7, %xmm6
    mulpd   %xmm7, %xmm0
    addpd   %xmm14, %xmm6
    addpd   %xmm1, %xmm0
    movapd  %xmm12, %xmm1
    unpcklpd %xmm1, %xmm1
    subpd   %xmm6, %xmm0
    mulpd   %xmm11, %xmm0
    addpd   %xmm6, %xmm0
    cmpb    $1, %r13b
    jne     .L86
    divpd   %xmm1, %xmm5
    addpd   16(%rsp), %xmm5
    movaps  %xmm5, 16(%rsp)
    jmp     .L79
.p2align 4, , 10
.p2align 3
.L46:
    cmpl    %edx, %esi
    jg      .L44
    jmp     .L47
.p2align 4, , 10
.p2align 3
.L42:
    cmpl    %r9d, %eax
    jg      .L40
    jmp     .L43
.p2align 4, , 10
.p2align 3
.L83:
    movapd  32(%rsp), %xmm2
    movapd  %xmm2, %xmm7
    movapd  %xmm2, %xmm3
    unpckhpd %xmm7, %xmm7
    movapd  %xmm7, %xmm9
    movapd  16(%rsp), %xmm7
    movapd  %xmm7, %xmm8
    unpckhpd %xmm7, %xmm7
    movapd  %xmm7, %xmm0
.L37:
    addsd   48(%rsp), %xmm8
    mulsd   80(%rsp), %xmm8
    addsd   64(%rsp), %xmm8
    movapd  %xmm8, %xmm10
    andpd   %xmm14, %xmm10
    ucomisd %xmm10, %xmm15
    jbe     .L52
    cvttsd2siq %xmm8, %rdx
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rdx, %xmm10
    movapd  %xmm10, %xmm11
    cmpnlesd %xmm8, %xmm11
    andpd   %xmm7, %xmm11
    subsd   %xmm11, %xmm10
    movapd  %xmm14, %xmm11
    andnpd  %xmm8, %xmm11
    movapd  %xmm10, %xmm8
    orpd    %xmm11, %xmm8
.L52:
    addsd   48(%rsp), %xmm0
    mulsd   80(%rsp), %xmm0
    addsd   64(%rsp), %xmm0
    movapd  %xmm0, %xmm10
    andpd   %xmm14, %xmm10
    ucomisd %xmm10, %xmm15
    jbe     .L53
    cvttsd2siq %xmm0, %rdx
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rdx, %xmm10
    movapd  %xmm10, %xmm11
    cmpnlesd %xmm0, %xmm11
    andpd   %xmm7, %xmm11
    subsd   %xmm11, %xmm10
    movapd  %xmm14, %xmm11
    andnpd  %xmm0, %xmm11
    movapd  %xmm10, %xmm0
    orpd    %xmm11, %xmm0
.L53:
    addsd   48(%rsp), %xmm3
    mulsd   80(%rsp), %xmm3
    addsd   64(%rsp), %xmm3
    movapd  %xmm3, %xmm10
    andpd   %xmm14, %xmm10
    ucomisd %xmm10, %xmm15
    jbe     .L54
    cvttsd2siq %xmm3, %rdx
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm7
    cvtsi2sdq %rdx, %xmm10
    movapd  %xmm10, %xmm11
    cmpnlesd %xmm3, %xmm11
    andpd   %xmm7, %xmm11
    subsd   %xmm11, %xmm10
    movapd  %xmm14, %xmm11
    andnpd  %xmm3, %xmm11
    movapd  %xmm10, %xmm3
    orpd    %xmm11, %xmm3
.L54:
    addsd   48(%rsp), %xmm9
    mulsd   80(%rsp), %xmm9
    addsd   64(%rsp), %xmm9
    movapd  %xmm9, %xmm10
    andpd   %xmm14, %xmm10
    ucomisd %xmm10, %xmm15
    jbe     .L55
    cvttsd2siq %xmm9, %rdx
    pxor    %xmm10, %xmm10
    movsd   .LC0(%rip), %xmm12
    cvtsi2sdq %rdx, %xmm10
    movapd  %xmm10, %xmm11
    cmpnlesd %xmm9, %xmm11
    andpd   %xmm12, %xmm11
    subsd   %xmm11, %xmm10
    movapd  %xmm14, %xmm11
    andnpd  %xmm9, %xmm11
    orpd    %xmm11, %xmm10
    movapd  %xmm10, %xmm9
.L55:
    cvttsd2sil %xmm9, %edx
    movl    $255, %edi
    movq    %r11, %rax
    movl    $255, %r8d
    movq    128(%rsp), %rbx
    cmpl    %edi, %edx
    cmovg   %edi, %edx
    xorl    %edi, %edi
    testl   %edx, %edx
    cmovs   %edi, %edx
    cvttsd2sil %xmm8, %edi
    sall    $24, %edx
    cmpl    %r8d, %edi
    cmovg   %r8d, %edi
    xorl    %r8d, %r8d
    testl   %edi, %edi
    cmovs   %r8d, %edi
    movl    $255, %r8d
    sall    $16, %edi
    orl     %edi, %edx
    cvttsd2sil %xmm3, %edi
    cmpl    %r8d, %edi
    cmovg   %r8d, %edi
    xorl    %r8d, %r8d
    testl   %edi, %edi
    cmovs   %r8d, %edi
    movl    $255, %r8d
    orl     %edi, %edx
    cvttsd2sil %xmm0, %edi
    cmpl    %r8d, %edi
    cmovg   %r8d, %edi
    xorl    %r8d, %r8d
    testl   %edi, %edi
    cmovs   %r8d, %edi
    addq    $1, %rax
    sall    $8, %edi
    orl     %edi, %edx
    movl    %edx, (%rbx, %r11, 4)
    movq    %rax, %r11
    cmpq    %rax, 160(%rsp)
    jne     .L35
    movl    256(%rsp), %edi
    movq    240(%rsp), %rdx
    movq    %rbx, %rcx
    movl    224(%rsp), %r8d
    movl    144(%rsp), %eax
    addl    $1, %edi
    addq    %rdx, %rcx
    movl    272(%rsp), %ebx
    movsd   288(%rsp), %xmm13
    movsd   304(%rsp), %xmm12
    movsd   320(%rsp), %xmm15
    cmpl    %edi, %r8d
    jne     .L36
    jmp     .L1
.L57:
    pxor    %xmm4, %xmm4
    movapd  %xmm4, %xmm0
    movapd  %xmm4, %xmm7
    movapd  %xmm4, %xmm6
    jmp     .L21
.L58:
    pxor    %xmm3, %xmm3
    movapd  %xmm3, %xmm0
    movapd  %xmm3, %xmm8
    movapd  %xmm3, %xmm9
    jmp     .L37
// // SIZE(ksvgTurbulenceApplySse2_x86_64)
    RODATA
.balign 8
.LC0: TURB_DBL_1
.LC2: TURB_DBL_1_256
    RODATA
.balign 16
.LC3: TURB_PERMUTATION_DATA
    RODATA
.balign 8
.LC19: TURB_DBL_127_5
.LC20: TURB_DBL_255
.LC21: TURB_DBL_4096
.LC22: TURB_DBL_2_POW_52
.LC24: TURB_DBL_3
    RODATA
.balign 16
.LC25: TURB_ABS_MASK_SSE2
.set .LC26, .LC25
    RODATA
.balign 8
.LC27: TURB_DBL_0_5
GNU_STACK
