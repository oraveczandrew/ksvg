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

/*
 * void ksvgTurbulenceApplyAvx2_x86_64(
 *     jint* pixels, jint width, jint height,
 *     jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     jdouble baseFrequencyX, jdouble baseFrequencyY,
 *     jint periodX, jint periodY, jint octaves, jboolean fractalNoise,
 *     jdouble invCanvasScaleX, jdouble invCanvasScaleY,
 *     jdouble userLeft, jdouble userTop,
 *     jdouble originX, jdouble originY,
 *     jdouble unitSizeX, jdouble unitSizeY,
 *     jint seed);
 *
 * x86-64 System V ABI:
 *   rdi = pixels, rsi = width, rdx = height, rcx = clipLeft, r8d = clipTop, r9d = clipRight
 *   xmm0 = baseFrequencyX, xmm1 = baseFrequencyY
 *   xmm2 = invCanvasScaleX, xmm3 = invCanvasScaleY
 *   xmm4 = userLeft, xmm5 = userTop
 *   xmm6 = originX, xmm7 = originY
 *   stack: clipBottom (16(%rbp)), periodX (24(%rbp)), periodY (32(%rbp)), octaves (40(%rbp))
 *   stack: fractalNoise (48(%rbp)), unitSizeX (56(%rbp)), unitSizeY (64(%rbp)), seed (72(%rbp))
 */
.globl SYM(ksvgTurbulenceApplyAvx2_x86_64)
TYPE(ksvgTurbulenceApplyAvx2_x86_64, @function)
    SYM(ksvgTurbulenceApplyAvx2_x86_64):
    pushq   %rbp
    movl    $2147483646, %eax
    movq    %rdi, %r11
    vmovapd %xmm1, %xmm7
    movq    %rsp, %rbp
    pushq   %r15
    movl    %r8d, %r15d
    pushq   %r14
    pushq   %r13
    pushq   %r12
    movl    %ecx, %r12d
    pushq   %rbx
    movl    %esi, %ebx
    andq    $-32, %rsp
    subq    $70144, %rsp
    movl    32(%rbp), %ecx
    movl    40(%rbp), %r13d
    movl    %edx, 1700(%rsp)
    movl    72(%rbp), %edx
    vmovsd  %xmm3, 1704(%rsp)
    movzbl  48(%rbp), %r14d
    vmovapd %xmm4, %xmm3
    vmovsd  %xmm0, 1720(%rsp)
    cmpl    %eax, %edx
    vmovsd  %xmm2, 1712(%rsp)
    cmovle  %edx, %eax
    testl   %edx, %edx
    jg      .L3
    movslq  %edx, %rax
    movl    %edx, %esi
    imulq   $-2147483645, %rax, %rax
    sarl    $31, %esi
    shrq    $32, %rax
    addl    %edx, %eax
    sarl    $30, %eax
    subl    %esi, %eax
    imull   $2147483646, %eax, %eax
    subl    %edx, %eax
    addl    $1, %eax
.L3:
    leaq    6384(%rsp), %r8
    vxorps  %xmm11, %xmm11, %xmm11
    vxorpd  %xmm2, %xmm2, %xmm2
    xorl    %esi, %esi
    leaq    39280(%rsp), %rdi
    movq    %r8, 1728(%rsp)
    vmovsd  .LC2(%rip), %xmm1
    leaq    1760(%rsp), %r10
    movq    %rdi, 1664(%rsp)
.L4:
    movq    1728(%rsp), %rdi
    subq    $2048, %rdi
.p2align 4
.p2align 3
.L7:
    movl    %eax, %r8d
    movl    %eax, %edx
    imulq   $110892733, %r8, %r8
    shrq    $32, %r8
    subl    %r8d, %edx
    shrl    %edx
    addl    %r8d, %edx
    shrl    $16, %edx
    imull   $-2836, %edx, %r8d
    imull   $127773, %edx, %edx
    subl    %edx, %eax
    imull   $16807, %eax, %eax
    addl    %r8d, %eax
    testl   %eax, %eax
    leal    2147483647(%rax), %edx
    cmovle  %edx, %eax
    movl    %eax, %edx
    movl    %eax, %r8d
    andl    $511, %edx
    subl    $256, %edx
    vcvtsi2sdl %edx, %xmm11, %xmm4
    movl    %eax, %edx
    imulq   $110892733, %rdx, %rdx
    vmulsd  %xmm1, %xmm4, %xmm4
    shrq    $32, %rdx
    subl    %edx, %r8d
    shrl    %r8d
    addl    %edx, %r8d
    shrl    $16, %r8d
    imull   $-2836, %r8d, %edx
    imull   $127773, %r8d, %r8d
    subl    %r8d, %eax
    imull   $16807, %eax, %eax
    addl    %edx, %eax
    testl   %eax, %eax
    leal    2147483647(%rax), %edx
    cmovle  %edx, %eax
    movl    %eax, %edx
    andl    $511, %edx
    subl    $256, %edx
    vcvtsi2sdl %edx, %xmm11, %xmm0
    vmulsd  %xmm1, %xmm0, %xmm0
    vucomisd %xmm2, %xmm0
    setnp   %dl
    cmovne  %esi, %edx
    testb   %dl, %dl
    je      .L50
    vucomisd %xmm2, %xmm4
    setnp   %dl
    cmovne  %esi, %edx
    testb   %dl, %dl
    jne     .L7
.L50:
    vmulsd  %xmm0, %xmm0, %xmm6
    movq    1728(%rsp), %rdx
    addq    $8, %rdi
    vmulsd  %xmm4, %xmm4, %xmm8
    vaddsd  %xmm8, %xmm6, %xmm6
    vsqrtsd %xmm6, %xmm6, %xmm6
    vdivsd  %xmm6, %xmm4, %xmm4
    vdivsd  %xmm6, %xmm0, %xmm0
    vmovsd  %xmm4, -8(%rdi)
    vmovsd  %xmm0, 4104(%rdi)
    cmpq    %rdx, %rdi
    jne     .L7
    movq    1664(%rsp), %rdx
    addq    $8224, %rdi
    movq    %rdi, 1728(%rsp)
    cmpq    %rdx, %rdi
    jne     .L4
    vmovdqa .LC3(%rip), %ymm0
    leaq    2015(%rsp), %rsi
    vmovdqa %ymm0, 1760(%rsp)
    vmovdqa .LC3+32(%rip), %ymm0
    vmovdqa %ymm0, 1792(%rsp)
    vmovdqa .LC3+64(%rip), %ymm0
    vmovdqa %ymm0, 1824(%rsp)
    vmovdqa .LC3+96(%rip), %ymm0
    vmovdqa %ymm0, 1856(%rsp)
    vmovdqa .LC3+128(%rip), %ymm0
    vmovdqa %ymm0, 1888(%rsp)
    vmovdqa .LC3+160(%rip), %ymm0
    vmovdqa %ymm0, 1920(%rsp)
    vmovdqa .LC3+192(%rip), %ymm0
    vmovdqa %ymm0, 1952(%rsp)
    vmovdqa .LC3+224(%rip), %ymm0
    vmovdqa %ymm0, 1984(%rsp)
.p2align 4
.p2align 3
.L12:
    movl    %eax, %edi
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
    movzbl  (%rsi), %edi
    testl   %eax, %eax
    leal    2147483647(%rax), %edx
    cmovle  %edx, %eax
    subq    $1, %rsi
    movzbl  %al, %edx
    addq    %r10, %rdx
    movzbl  (%rdx), %r8d
    movb    %r8b, 1(%rsi)
    movb    %dil, (%rdx)
    cmpq    %r10, %rsi
    jne     .L12
    leaq    2016(%rsp), %rdi
    leaq    45424(%rsp), %rax
    vmovsd  %xmm7, 24(%rsp)
    leaq    35168(%rsp), %rdx
    leaq    3300(%rsp), %rsi
    vmovsd  %xmm3, 16(%rsp)
    leaq    53616(%rsp), %r8
    vmovsd  %xmm5, 8(%rsp)
.L13:
    vmovdqa -256(%rdi), %ymm0
    subq    $-128, %rsi
    addq    $32, %rdi
    addq    $1024, %rax
    addq    $256, %rdx
    vmovdqa %ymm0, -32(%rdi)
    vpmovzxbw %xmm0, %ymm1
    vextracti128 $0x1, %ymm0, %xmm0
    vmovupd -31088(%rdx), %ymm11
    vpmovzxbw %xmm0, %ymm0
    vpmovzxwd %xmm1, %ymm3
    vextracti128 $0x1, %ymm1, %xmm1
    vmovupd -31056(%rdx), %ymm4
    vpmovzxwd %xmm0, %ymm2
    vextracti128 $0x1, %ymm0, %xmm0
    vpmovzxwd %xmm1, %ymm1
    vmovdqu %ymm3, -1152(%rsi)
    vpmovzxwd %xmm0, %ymm0
    vmovdqu %ymm1, -1120(%rsi)
    vmovupd -30960(%rdx), %ymm7
    vmovupd -30864(%rdx), %ymm15
    vmovdqu %ymm2, -1088(%rsi)
    vmovapd -26976(%rdx), %ymm13
    vmovapd -26944(%rdx), %ymm12
    vmovdqu %ymm0, -1056(%rsi)
    vmovapd -26912(%rdx), %ymm10
    vmovapd -26880(%rdx), %ymm9
    vmovdqu %ymm3, -128(%rsi)
    vmovapd -26848(%rdx), %ymm8
    vmovupd -30928(%rdx), %ymm3
    vmovdqu %ymm1, -96(%rsi)
    vmovapd -26816(%rdx), %ymm14
    vmovupd -30896(%rdx), %ymm1
    vmovdqu %ymm2, -64(%rsi)
    vmovapd -26784(%rdx), %ymm5
    vmovupd -31024(%rdx), %ymm2
    vmovdqu %ymm0, -32(%rsi)
    vmovupd -30992(%rdx), %ymm6
    vmovapd -26752(%rdx), %ymm0
    vmovupd %ymm11, -29040(%rdx)
    vmovupd %ymm4, -29008(%rdx)
    vmovupd %ymm2, -28976(%rdx)
    vmovapd %ymm11, 672(%rsp)
    vmovapd %ymm2, 640(%rsp)
    vmovapd %ymm6, 608(%rsp)
    vmovupd %ymm6, -28944(%rdx)
    vmovupd -22864(%rdx), %ymm11
    vmovupd %ymm7, -28912(%rdx)
    vmovupd %ymm3, -28880(%rdx)
    vmovupd %ymm1, -28848(%rdx)
    vmovupd %ymm15, -28816(%rdx)
    vmovapd %ymm13, -24928(%rdx)
    vmovapd %ymm12, -24896(%rdx)
    vmovapd %ymm10, -24864(%rdx)
    vmovapd %ymm8, -24800(%rdx)
    vmovapd %ymm14, -24768(%rdx)
    vmovapd %ymm5, -24736(%rdx)
    vmovapd %ymm0, -24704(%rdx)
    vmovapd %ymm7, 576(%rsp)
    vmovapd %ymm3, 544(%rsp)
    vmovupd -22832(%rdx), %ymm3
    vmovapd %ymm1, 512(%rsp)
    vmovupd -22800(%rdx), %ymm1
    vmovapd %ymm15, 480(%rsp)
    vmovupd -22736(%rdx), %ymm15
    vmovapd %ymm13, 704(%rsp)
    vmovupd -22704(%rdx), %ymm13
    vmovapd %ymm12, 736(%rsp)
    vmovupd -22672(%rdx), %ymm12
    vmovapd %ymm10, 768(%rsp)
    vmovupd -22640(%rdx), %ymm10
    vmovapd %ymm8, 832(%rsp)
    vmovapd %ymm14, 864(%rsp)
    vmovapd %ymm5, 896(%rsp)
    vmovapd %ymm0, 928(%rsp)
    vmovupd -22768(%rdx), %ymm0
    vmovapd %ymm9, -24832(%rdx)
    vmovapd %ymm9, 800(%rsp)
    vmovapd -18752(%rdx), %ymm9
    vmovapd -18624(%rdx), %ymm6
    vmovapd -18720(%rdx), %ymm8
    vmovapd -18688(%rdx), %ymm7
    vmovupd %ymm3, -20784(%rdx)
    vmovapd -18656(%rdx), %ymm5
    vmovupd %ymm1, -20752(%rdx)
    vmovapd %ymm6, 1088(%rsp)
    vmovapd -18592(%rdx), %ymm6
    vmovupd %ymm0, -20720(%rdx)
    vmovapd %ymm6, 1120(%rsp)
    vmovapd -18560(%rdx), %ymm6
    vmovupd %ymm15, -20688(%rdx)
    vmovapd %ymm6, %ymm14
    vmovapd -18528(%rdx), %ymm6
    vmovupd %ymm13, -20656(%rdx)
    vmovupd %ymm12, -20624(%rdx)
    vmovapd %ymm6, %ymm2
    vmovupd %ymm10, -20592(%rdx)
    vmovapd 1088(%rsp), %ymm6
    vmovapd %ymm9, -16704(%rdx)
    vmovapd %ymm8, -16672(%rdx)
    vmovapd %ymm7, -16640(%rdx)
    vmovapd %ymm5, -16608(%rdx)
    vmovapd %ymm0, 448(%rsp)
    vmovapd %ymm15, 416(%rsp)
    vmovapd %ymm13, 384(%rsp)
    vmovapd %ymm12, 352(%rsp)
    vmovapd %ymm10, 320(%rsp)
    vmovapd %ymm9, 960(%rsp)
    vmovapd %ymm8, 992(%rsp)
    vmovapd %ymm7, 1024(%rsp)
    vmovapd %ymm5, 1056(%rsp)
    vmovupd %ymm11, -20816(%rdx)
    vmovapd %ymm6, -16576(%rdx)
    vmovupd -14640(%rdx), %ymm7
    vmovupd -14544(%rdx), %ymm0
    vmovapd %ymm2, -16480(%rdx)
    vmovupd -14608(%rdx), %ymm13
    vmovupd -14576(%rdx), %ymm10
    vmovupd -14512(%rdx), %ymm15
    vmovupd -14480(%rdx), %ymm12
    vmovapd %ymm2, 1184(%rsp)
    vmovapd -10464(%rdx), %ymm2
    vmovupd -14448(%rdx), %ymm9
    vmovapd %ymm14, -16512(%rdx)
    vmovupd -14416(%rdx), %ymm8
    vmovapd -10496(%rdx), %ymm5
    vmovupd %ymm7, -12592(%rdx)
    vmovapd %ymm2, 1280(%rsp)
    vmovapd -10432(%rdx), %ymm2
    vmovapd 1120(%rsp), %ymm6
    vmovupd %ymm13, -12560(%rdx)
    vmovapd %ymm2, 1312(%rsp)
    vmovapd -10400(%rdx), %ymm2
    vmovapd %ymm6, -16544(%rdx)
    vmovapd -10528(%rdx), %ymm6
    vmovapd %ymm2, 1344(%rsp)
    vmovapd -10368(%rdx), %ymm2
    vmovupd %ymm10, -12528(%rdx)
    vmovapd %ymm2, 1376(%rsp)
    vmovapd -10336(%rdx), %ymm2
    vmovupd %ymm0, -12496(%rdx)
    vmovapd %ymm2, 1408(%rsp)
    vmovapd -10304(%rdx), %ymm2
    vmovapd %ymm14, 1152(%rsp)
    vmovapd %ymm15, 288(%rsp)
    vmovapd %ymm2, %ymm14
    vmovupd %ymm15, -12464(%rdx)
    vmovupd -6416(%rdx), %ymm15
    vmovapd 1280(%rsp), %ymm2
    vmovapd %ymm14, -8256(%rdx)
    vmovapd %ymm2, -8416(%rdx)
    vmovapd 1312(%rsp), %ymm2
    vmovapd %ymm14, 1440(%rsp)
    vmovupd -6192(%rdx), %ymm14
    vmovapd %ymm2, -8384(%rdx)
    vmovapd 1344(%rsp), %ymm2
    vmovapd %ymm14, 32(%rsp)
    vmovapd -2304(%rdx), %ymm14
    vmovapd %ymm2, -8352(%rdx)
    vmovapd 1376(%rsp), %ymm2
    vmovupd %ymm12, -12432(%rdx)
    vmovapd %ymm2, -8320(%rdx)
    vmovapd 1408(%rsp), %ymm2
    vmovupd %ymm9, -12400(%rdx)
    vmovupd %ymm8, -12368(%rdx)
    vmovapd %ymm6, -8480(%rdx)
    vmovapd %ymm5, -8448(%rdx)
    vmovapd %ymm2, -8288(%rdx)
    vmovupd -6256(%rdx), %ymm2
    vmovapd %ymm12, 256(%rsp)
    vmovupd -6384(%rdx), %ymm12
    vmovapd %ymm9, 224(%rsp)
    vmovupd -6352(%rdx), %ymm9
    vmovapd %ymm8, 192(%rsp)
    vmovupd -6320(%rdx), %ymm8
    vmovapd %ymm6, 1216(%rsp)
    vmovupd -6288(%rdx), %ymm6
    vmovapd %ymm5, 1248(%rsp)
    vmovupd -6224(%rdx), %ymm5
    vmovapd %ymm14, 1472(%rsp)
    vmovapd -2272(%rdx), %ymm14
    vmovupd %ymm15, -4368(%rdx)
    vmovapd %ymm14, 1504(%rsp)
    vmovapd -2240(%rdx), %ymm14
    vmovupd %ymm12, -4336(%rdx)
    vmovapd %ymm14, 1536(%rsp)
    vmovapd -2208(%rdx), %ymm14
    vmovupd %ymm9, -4304(%rdx)
    vmovapd %ymm14, 1568(%rsp)
    vmovapd -2176(%rdx), %ymm14
    vmovupd %ymm8, -4272(%rdx)
    vmovapd %ymm14, 1600(%rsp)
    vmovapd -2144(%rdx), %ymm14
    vmovupd %ymm6, -4240(%rdx)
    vmovapd %ymm14, 1632(%rsp)
    vmovapd -2112(%rdx), %ymm14
    vmovupd %ymm2, -4208(%rdx)
    vmovapd %ymm14, 1664(%rsp)
    vmovapd -2080(%rdx), %ymm14
    vmovupd %ymm5, -4176(%rdx)
    vmovapd %ymm14, 1728(%rsp)
    vmovapd 32(%rsp), %ymm14
    vmovapd %ymm8, 160(%rsp)
    vmovupd %ymm14, -4144(%rdx)
    vmovapd 1472(%rsp), %ymm14
    vmovapd %ymm6, 128(%rsp)
    vmovapd %ymm14, -256(%rdx)
    vmovapd 1504(%rsp), %ymm14
    vmovapd %ymm2, 96(%rsp)
    vmovapd %ymm14, -224(%rdx)
    vmovapd 1536(%rsp), %ymm14
    vmovapd %ymm5, 64(%rsp)
    vpermpd $68, %ymm7, %ymm5
    vmovapd %ymm14, -192(%rdx)
    vmovapd 1568(%rsp), %ymm14
    vmovapd 1600(%rsp), %ymm6
    vmovapd 1632(%rsp), %ymm8
    vmovapd 640(%rsp), %ymm2
    vmovapd %ymm14, -160(%rdx)
    vmovapd 1664(%rsp), %ymm14
    vmovapd %ymm6, -128(%rdx)
    vmovapd 1728(%rsp), %ymm6
    vmovapd %ymm14, -64(%rdx)
    vmovapd 672(%rsp), %ymm14
    vmovapd %ymm8, -96(%rdx)
    vpermpd $68, %ymm14, %ymm8
    vmovapd %ymm6, -32(%rdx)
    vpermpd $238, %ymm14, %ymm6
    vpermpd $238, %ymm15, %ymm14
    vshufpd $12, %ymm5, %ymm8, %ymm8
    vpermpd $238, %ymm7, %ymm5
    vpermpd $68, %ymm11, %ymm7
    vshufpd $12, %ymm5, %ymm6, %ymm6
    vpermpd $68, %ymm15, %ymm5
    vpermpd $68, %ymm8, %ymm15
    vpermpd $238, %ymm8, %ymm8
    vshufpd $12, %ymm5, %ymm7, %ymm7
    vpermpd $238, %ymm11, %ymm5
    vshufpd $12, %ymm14, %ymm5, %ymm5
    vpermpd $68, %ymm7, %ymm14
    vpermpd $238, %ymm7, %ymm7
    vshufpd $12, %ymm14, %ymm15, %ymm14
    vshufpd $12, %ymm7, %ymm8, %ymm15
    vpermpd $68, %ymm6, %ymm8
    vpermpd $68, %ymm5, %ymm7
    vpermpd $238, %ymm6, %ymm6
    vpermpd $238, %ymm5, %ymm5
    vshufpd $12, %ymm7, %ymm8, %ymm7
    vmovupd %ymm7, -960(%rax)
    vshufpd $12, %ymm5, %ymm6, %ymm7
    vpermpd $68, %ymm13, %ymm6
    vmovupd %ymm7, -928(%rax)
    vmovupd -960(%rax), %ymm7
    vpermpd $68, %ymm4, %ymm5
    vpermpd $238, %ymm13, %ymm13
    vpermpd $238, %ymm4, %ymm4
    vmovupd %ymm14, -9216(%rax)
    vmovupd %ymm7, -9152(%rax)
    vmovupd -928(%rax), %ymm7
    vshufpd $12, %ymm6, %ymm5, %ymm5
    vpermpd $68, %ymm3, %ymm6
    vpermpd $68, %ymm5, %ymm8
    vpermpd $238, %ymm3, %ymm3
    vpermpd $238, %ymm5, %ymm5
    vshufpd $12, %ymm13, %ymm4, %ymm4
    vmovupd %ymm7, -9120(%rax)
    vpermpd $68, %ymm12, %ymm7
    vpermpd $238, %ymm12, %ymm12
    vshufpd $12, %ymm7, %ymm6, %ymm6
    vpermpd $68, %ymm6, %ymm7
    vpermpd $238, %ymm6, %ymm6
    vshufpd $12, %ymm12, %ymm3, %ymm3
    vshufpd $12, %ymm7, %ymm8, %ymm7
    vshufpd $12, %ymm6, %ymm5, %ymm8
    vpermpd $68, %ymm4, %ymm6
    vpermpd $68, %ymm3, %ymm5
    vpermpd $238, %ymm4, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm5, %ymm6, %ymm12
    vpermpd $68, %ymm9, %ymm5
    vshufpd $12, %ymm3, %ymm4, %ymm13
    vpermpd $68, %ymm10, %ymm4
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm10, %ymm10
    vshufpd $12, %ymm4, %ymm3, %ymm3
    vpermpd $68, %ymm1, %ymm4
    vpermpd $68, %ymm3, %ymm6
    vpermpd $238, %ymm9, %ymm9
    vshufpd $12, %ymm5, %ymm4, %ymm4
    vpermpd $68, %ymm4, %ymm5
    vpermpd $238, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm4
    vshufpd $12, %ymm5, %ymm6, %ymm6
    vpermpd $238, %ymm2, %ymm2
    vmovapd 608(%rsp), %ymm5
    vpermpd $238, %ymm1, %ymm1
    vshufpd $12, %ymm10, %ymm2, %ymm2
    vshufpd $12, %ymm9, %ymm1, %ymm1
    vshufpd $12, %ymm4, %ymm3, %ymm9
    vpermpd $68, %ymm2, %ymm4
    vpermpd $68, %ymm1, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vpermpd $238, %ymm1, %ymm1
    vmovupd %ymm15, -9184(%rax)
    vshufpd $12, %ymm3, %ymm4, %ymm10
    vshufpd $12, %ymm1, %ymm2, %ymm1
    vmovapd 448(%rsp), %ymm4
    vmovapd %ymm0, %ymm3
    vpermpd $68, %ymm0, %ymm2
    vmovupd %ymm1, -672(%rax)
    vpermpd $238, %ymm5, %ymm0
    vmovupd %ymm1, -8864(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 160(%rsp), %ymm5
    vshufpd $12, %ymm2, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm2
    vpermpd $68, %ymm4, %ymm3
    vmovupd %ymm7, -9088(%rax)
    vshufpd $12, %ymm2, %ymm0, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vmovupd %ymm8, -9056(%rax)
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vmovupd %ymm12, -9024(%rax)
    vpermpd $68, %ymm2, %ymm3
    vmovupd %ymm13, -8992(%rax)
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm6, -8960(%rax)
    vmovupd %ymm9, -8928(%rax)
    vmovupd %ymm10, -8896(%rax)
    vmovupd %ymm4, -640(%rax)
    vmovapd 576(%rsp), %ymm5
    vmovupd %ymm1, -608(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, -576(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 288(%rsp), %ymm3
    vmovupd %ymm1, -544(%rax)
    vmovupd -608(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm4, -8832(%rax)
    vmovapd 416(%rsp), %ymm4
    vmovupd %ymm1, -8800(%rax)
    vmovupd -576(%rax), %ymm1
    vmovupd %ymm1, -8768(%rax)
    vmovupd -544(%rax), %ymm1
    vmovupd %ymm1, -8736(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 128(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, -480(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovupd %ymm4, -512(%rax)
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, -448(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 544(%rsp), %ymm3
    vmovupd %ymm1, -416(%rax)
    vmovupd -480(%rax), %ymm1
    vmovapd 96(%rsp), %ymm5
    vmovupd %ymm4, -8704(%rax)
    vpermpd $238, %ymm3, %ymm2
    vmovapd 256(%rsp), %ymm4
    vmovupd %ymm1, -8672(%rax)
    vmovupd -448(%rax), %ymm1
    vpermpd $68, %ymm4, %ymm0
    vmovupd %ymm1, -8640(%rax)
    vmovupd -416(%rax), %ymm1
    vmovupd %ymm1, -8608(%rax)
    vpermpd $68, %ymm3, %ymm1
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm4, %ymm0
    vmovapd 384(%rsp), %ymm4
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, -352(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovupd %ymm4, -384(%rax)
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, -320(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovupd %ymm1, -288(%rax)
    vmovupd -352(%rax), %ymm1
    vmovapd 512(%rsp), %ymm5
    vmovapd 224(%rsp), %ymm3
    vmovupd %ymm4, -8576(%rax)
    vmovapd 352(%rsp), %ymm4
    vmovupd %ymm1, -8544(%rax)
    vmovupd -320(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm1, -8512(%rax)
    vmovupd -288(%rax), %ymm1
    vmovupd %ymm1, -8480(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 64(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, -224(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovapd 480(%rsp), %ymm5
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, -192(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 192(%rsp), %ymm3
    vmovupd %ymm1, -160(%rax)
    vmovupd -224(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm4, -256(%rax)
    vmovupd %ymm1, -8416(%rax)
    vmovupd -192(%rax), %ymm1
    vmovupd %ymm4, -8448(%rax)
    vmovapd 320(%rsp), %ymm4
    vmovupd %ymm1, -8384(%rax)
    vmovupd -160(%rax), %ymm1
    vmovupd %ymm1, -8352(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 32(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vmovupd %ymm1, -96(%rax)
    vpermpd $238, %ymm2, %ymm2
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovupd %ymm4, -128(%rax)
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, -64(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovupd %ymm1, -32(%rax)
    vmovupd -96(%rax), %ymm1
    vmovupd %ymm4, -8320(%rax)
    vmovupd %ymm1, -8288(%rax)
    vmovupd -64(%rax), %ymm1
    vmovapd 704(%rsp), %ymm5
    vmovapd 1216(%rsp), %ymm3
    vmovapd 960(%rsp), %ymm4
    vmovupd %ymm1, -8256(%rax)
    vmovupd -32(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm1, -8224(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 1472(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, 15456(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovapd 736(%rsp), %ymm5
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, 15488(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 1248(%rsp), %ymm3
    vmovupd %ymm1, 15520(%rax)
    vmovupd 15456(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm4, 15424(%rax)
    vmovupd %ymm1, 7264(%rax)
    vmovupd 15488(%rax), %ymm1
    vmovupd %ymm4, 7232(%rax)
    vmovapd 992(%rsp), %ymm4
    vmovupd %ymm1, 7296(%rax)
    vmovupd 15520(%rax), %ymm1
    vmovupd %ymm1, 7328(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 1504(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, 15584(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovupd %ymm4, 15552(%rax)
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, 15616(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovupd %ymm1, 15648(%rax)
    vmovupd 15584(%rax), %ymm1
    vmovupd %ymm4, 7360(%rax)
    vmovupd %ymm1, 7392(%rax)
    vmovupd 15616(%rax), %ymm1
    vmovupd %ymm1, 7424(%rax)
    vmovupd 15648(%rax), %ymm1
    vmovapd 768(%rsp), %ymm5
    vmovapd 1280(%rsp), %ymm3
    vmovapd 1024(%rsp), %ymm4
    vmovupd %ymm1, 7456(%rax)
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm5, %ymm1
    vmovapd 1536(%rsp), %ymm5
    vpermpd $68, %ymm3, %ymm0
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, 15712(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovapd 800(%rsp), %ymm5
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, 15744(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 1312(%rsp), %ymm3
    vmovupd %ymm1, 15776(%rax)
    vmovupd 15712(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm4, 15680(%rax)
    vmovupd %ymm1, 7520(%rax)
    vmovupd 15744(%rax), %ymm1
    vmovupd %ymm4, 7488(%rax)
    vmovapd 1056(%rsp), %ymm4
    vmovupd %ymm1, 7552(%rax)
    vmovupd 15776(%rax), %ymm1
    vmovupd %ymm1, 7584(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 1568(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, 15840(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovupd %ymm4, 15808(%rax)
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, 15872(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovupd %ymm1, 15904(%rax)
    vmovupd 15840(%rax), %ymm1
    vmovupd %ymm4, 7616(%rax)
    vmovupd %ymm1, 7648(%rax)
    vmovupd 15872(%rax), %ymm1
    vmovupd %ymm1, 7680(%rax)
    vmovupd 15904(%rax), %ymm1
    vmovupd %ymm1, 7712(%rax)
    vmovapd 832(%rsp), %ymm5
    vmovapd 1344(%rsp), %ymm3
    vmovapd 1088(%rsp), %ymm4
    vpermpd $68, %ymm3, %ymm0
    vpermpd $68, %ymm5, %ymm1
    vpermpd $238, %ymm5, %ymm2
    vmovapd 1600(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, 15968(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovapd 864(%rsp), %ymm5
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, 16000(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 1376(%rsp), %ymm3
    vmovupd %ymm1, 16032(%rax)
    vmovupd 15968(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm4, 15936(%rax)
    vmovupd %ymm1, 7776(%rax)
    vmovupd 16000(%rax), %ymm1
    vmovupd %ymm4, 7744(%rax)
    vmovapd 1120(%rsp), %ymm4
    vmovupd %ymm1, 7808(%rax)
    vmovupd 16032(%rax), %ymm1
    vmovupd %ymm1, 7840(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 1632(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vpermpd $68, %ymm4, %ymm3
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm5, %ymm0
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vpermpd $238, %ymm2, %ymm2
    vmovupd %ymm1, 16096(%rax)
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovapd 896(%rsp), %ymm5
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm1, 16128(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm1
    vmovapd 1408(%rsp), %ymm3
    vmovupd %ymm1, 16160(%rax)
    vmovupd 16096(%rax), %ymm1
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm4, 16064(%rax)
    vmovupd %ymm1, 7904(%rax)
    vmovupd 16128(%rax), %ymm1
    vmovupd %ymm4, 7872(%rax)
    vmovupd %ymm1, 7936(%rax)
    vmovupd 16160(%rax), %ymm1
    vmovupd %ymm1, 7968(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovapd 1152(%rsp), %ymm4
    vmovapd 1664(%rsp), %ymm5
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm3, %ymm0
    vmovupd %ymm14, -1024(%rax)
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vpermpd $68, %ymm4, %ymm3
    vpermpd $68, %ymm5, %ymm0
    vmovupd %ymm15, -992(%rax)
    vshufpd $12, %ymm0, %ymm3, %ymm3
    vpermpd $238, %ymm4, %ymm0
    vpermpd $238, %ymm5, %ymm4
    vpermpd $68, %ymm1, %ymm5
    vshufpd $12, %ymm4, %ymm0, %ymm0
    vpermpd $238, %ymm1, %ymm1
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vshufpd $12, %ymm3, %ymm1, %ymm1
    vpermpd $68, %ymm2, %ymm3
    vmovupd %ymm1, 16224(%rax)
    vpermpd $238, %ymm2, %ymm2
    vpermpd $68, %ymm0, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vmovapd 928(%rsp), %ymm5
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vshufpd $12, %ymm0, %ymm2, %ymm2
    vmovapd 1440(%rsp), %ymm3
    vmovupd %ymm2, 16288(%rax)
    vmovupd 16224(%rax), %ymm2
    vmovupd %ymm1, 16256(%rax)
    vpermpd $68, %ymm3, %ymm0
    vmovupd %ymm1, 8064(%rax)
    vpermpd $68, %ymm5, %ymm1
    vmovupd %ymm2, 8032(%rax)
    vmovupd 16288(%rax), %ymm2
    vshufpd $12, %ymm0, %ymm1, %ymm1
    vpermpd $238, %ymm5, %ymm0
    vmovupd %ymm4, 16192(%rax)
    vmovapd 1184(%rsp), %ymm5
    vmovupd %ymm4, 8000(%rax)
    vmovapd 1728(%rsp), %ymm4
    vmovupd %ymm2, 8096(%rax)
    vpermpd $238, %ymm3, %ymm2
    vpermpd $68, %ymm5, %ymm3
    vshufpd $12, %ymm2, %ymm0, %ymm0
    vpermpd $68, %ymm4, %ymm2
    vpermpd $238, %ymm4, %ymm4
    vmovupd %ymm7, -896(%rax)
    vshufpd $12, %ymm2, %ymm3, %ymm3
    vpermpd $238, %ymm5, %ymm2
    vpermpd $68, %ymm1, %ymm5
    vpermpd $238, %ymm1, %ymm1
    vshufpd $12, %ymm4, %ymm2, %ymm2
    vpermpd $68, %ymm3, %ymm4
    vpermpd $238, %ymm3, %ymm3
    vmovupd %ymm8, -864(%rax)
    vshufpd $12, %ymm4, %ymm5, %ymm4
    vshufpd $12, %ymm3, %ymm1, %ymm5
    vpermpd $68, %ymm0, %ymm3
    vpermpd $68, %ymm2, %ymm1
    vpermpd $238, %ymm0, %ymm0
    vpermpd $238, %ymm2, %ymm2
    vshufpd $12, %ymm1, %ymm3, %ymm1
    vmovupd %ymm4, 8128(%rax)
    vshufpd $12, %ymm2, %ymm0, %ymm0
    vmovupd %ymm5, 8160(%rax)
    vmovupd %ymm1, 8192(%rax)
    vmovupd %ymm0, 8224(%rax)
    vmovupd %ymm12, -832(%rax)
    vmovupd %ymm13, -800(%rax)
    vmovupd %ymm6, -768(%rax)
    vmovupd %ymm9, -736(%rax)
    vmovupd %ymm10, -704(%rax)
    vmovupd %ymm4, 16320(%rax)
    vmovupd %ymm5, 16352(%rax)
    vmovupd %ymm1, 16384(%rax)
    vmovupd %ymm0, 16416(%rax)
    cmpq    %r8, %rax
    jne     .L13
    vmovsd  16(%rsp), %xmm3
    movl    %ecx, 32(%rbp)
    movslq  %ebx, %r8
    xorl    %esi, %esi
    vmovsd  8(%rsp), %xmm5
    vmovsd  24(%rsp), %xmm7
    movq    %r11, %rdi
    vpinsrw $0, 2016(%rsp), %xmm6, %xmm6
    vmovsd  22832(%rsp), %xmm0
    vpmovzxbd %xmm6, %xmm2
    vmovsd  6384(%rsp), %xmm4
    vmovsd  %xmm3, 1632(%rsp)
    vmovsd  10496(%rsp), %xmm1
    vmovsd  %xmm5, 1664(%rsp)
    vpextrw $0, %xmm6, 2272(%rsp)
    vmovhpd 31056(%rsp), %xmm0, %xmm0
    vmovhpd 14608(%rsp), %xmm4, %xmm4
    movl    %r9d, 1568(%rsp)
    vmovhpd 18720(%rsp), %xmm1, %xmm1
    vinsertf128 $0x1, %xmm0, %ymm4, %ymm4
    vmovsd  26944(%rsp), %xmm0
    vmovq   %xmm2, 3300(%rsp)
    vmovq   %xmm2, 4324(%rsp)
    vmovhpd 35168(%rsp), %xmm0, %xmm0
    vmovsd  %xmm7, 1600(%rsp)
    vinsertf128 $0x1, %xmm0, %ymm1, %ymm1
    vmovapd 6384(%rsp), %xmm0
    vmovapd %xmm0, 8432(%rsp)
    vmovapd 10496(%rsp), %xmm0
    vmovapd %xmm0, 12544(%rsp)
    vmovapd 14608(%rsp), %xmm0
    vmovapd %xmm0, 16656(%rsp)
    vmovapd 18720(%rsp), %xmm0
    vmovapd %xmm0, 20768(%rsp)
    vmovapd 22832(%rsp), %xmm0
    vmovapd %xmm0, 24880(%rsp)
    vmovapd 26944(%rsp), %xmm0
    vmovapd %xmm0, 28992(%rsp)
    vmovsd  22840(%rsp), %xmm7
    movslq  1700(%rsp), %rdx
    movq    %r8, 1728(%rsp)
    vmovhpd 31064(%rsp), %xmm7, %xmm0
    imulq   %r8, %rdx
    vmovsd  6392(%rsp), %xmm7
    vmovupd %ymm4, 45424(%rsp)
    vmovupd %ymm1, 61872(%rsp)
    vmovhpd 14616(%rsp), %xmm7, %xmm2
    vmovsd  26952(%rsp), %xmm7
    vmovupd %ymm4, 53616(%rsp)
    vinsertf128 $0x1, %xmm0, %ymm2, %ymm2
    salq    $2, %rdx
    vmovupd %ymm1, 70064(%rsp)
    vmovhpd 35176(%rsp), %xmm7, %xmm6
    vmovsd  10504(%rsp), %xmm7
    vmovupd %ymm2, 45456(%rsp)
    vmovupd %ymm2, 53648(%rsp)
    vmovhpd 18728(%rsp), %xmm7, %xmm0
    vinsertf128 $0x1, %xmm6, %ymm0, %ymm0
    vmovapd 31056(%rsp), %xmm6
    vmovupd %ymm0, 61904(%rsp)
    vmovapd %xmm6, 33104(%rsp)
    vmovapd 35168(%rsp), %xmm6
    vmovupd %ymm0, 70096(%rsp)
    vmovapd %xmm6, 37216(%rsp)
    vzeroupper
    call    SYM(memset)
    movl    32(%rbp), %ecx
    movq    %rax, %r11
    movl    24(%rbp), %eax
    testl   %eax, %eax
    setg    %al
    testl   %ecx, %ecx
    setg    %dl
    orl     %edx, %eax
    cmpl    16(%rbp), %r15d
    jge     .L70
    movl    1568(%rsp), %r9d
    cmpl    %r9d, %r12d
    jge     .L70
    movq    1728(%rsp), %r8
    testb   %al, %al
    vxorps  %xmm11, %xmm11, %xmm11
    movl    %ebx, %eax
    vmovsd  1664(%rsp), %xmm5
    vmovsd  1632(%rsp), %xmm3
    vmovsd  1600(%rsp), %xmm7
    leaq    0(, %r8, 4), %rsi
    je      .L74
    imull   %r15d, %eax
    movslq  %r12d, %rdx
    movl    16(%rbp), %edi
    movl    %r9d, %r8d
    vmovsd  .LC15(%rip), %xmm15
    vmovapd %xmm5, %xmm2
    subl    %r15d, %edi
    cltq
    movl    %edi, %ebx
    addq    %rdx, %rax
    xorl    %edx, %edx
    leaq    (%r11, %rax, 4), %rax
    movl    %edx, %edi
    movq    %rsi, %r11
    movq    %rax, %rdx
.L31:
    leal    (%rdi, %r15), %eax
    xorl    %r10d, %r10d
    movl    %edi, 1408(%rsp)
    vmovsd  .LC12(%rip), %xmm13
    vcvtsi2sdl %eax, %xmm11, %xmm1
    movl    %r8d, %eax
    movq    %r10, 1728(%rsp)
    vmulsd  1704(%rsp), %xmm1, %xmm1
    subl    %r12d, %eax
    movq    %rdx, 1600(%rsp)
    movq    %rax, 1536(%rsp)
    movq    %r11, 1376(%rsp)
    movl    %r15d, 1344(%rsp)
    movl    %ecx, 32(%rbp)
    vaddsd  %xmm2, %xmm1, %xmm1
    vdivsd  64(%rbp), %xmm1, %xmm1
    vmulsd  %xmm7, %xmm1, %xmm5
    movl    %ebx, 1440(%rsp)
    vmovsd  %xmm7, 1312(%rsp)
    vcvtsi2sdl %edi, %xmm11, %xmm1
    movl    %r8d, %ebx
    vmovsd  %xmm3, 1568(%rsp)
    vmovsd  %xmm2, 1280(%rsp)
    vmovsd  %xmm15, 1664(%rsp)
    vmovsd  %xmm5, 1504(%rsp)
    vmulsd  %xmm7, %xmm1, %xmm1
    vmovsd  %xmm1, 1472(%rsp)
.L30:
    vmovsd  1720(%rsp), %xmm7
    movl    1728(%rsp), %edi
    vcvtsi2sdl %edi, %xmm11, %xmm9
    leal    (%r12, %rdi), %ecx
    vcvtsi2sdl %ecx, %xmm11, %xmm2
    vmulsd  1712(%rsp), %xmm2, %xmm2
    vaddsd  1568(%rsp), %xmm2, %xmm4
    vdivsd  56(%rbp), %xmm4, %xmm4
    vmulsd  %xmm7, %xmm4, %xmm4
    vmulsd  %xmm7, %xmm9, %xmm9
    testl   %r13d, %r13d
    jle     .L32
    movq    .LC0(%rip), %rax
    movl    24(%rbp), %edi
    xorl    %r9d, %r9d
    movl    %ebx, %r15d
    movl    32(%rbp), %r8d
    vxorpd  %xmm10, %xmm10, %xmm10
    vmovsd  1504(%rsp), %xmm8
    movq    %rax, 1632(%rsp)
    vmovq   %rax, %xmm7
    vmovsd  1472(%rsp), %xmm12
.p2align 4
.p2align 3
.L43:
    vaddsd  .LC11(%rip), %xmm4, %xmm14
    vroundsd $9, %xmm14, %xmm14, %xmm0
    vcvttsd2sil %xmm0, %edx
    vsubsd  %xmm0, %xmm14, %xmm14
    vaddsd  .LC11(%rip), %xmm8, %xmm0
    vsubsd  .LC0(%rip), %xmm14, %xmm3
    vroundsd $9, %xmm0, %xmm0, %xmm2
    leal    1(%rdx), %esi
    vsubsd  %xmm2, %xmm0, %xmm0
    vsubsd  .LC0(%rip), %xmm0, %xmm1
    testl   %edi, %edi
    jle     .L33
    vroundsd $9, %xmm9, %xmm9, %xmm5
    vcvttsd2sil %xmm5, %eax
    leal    4096(%rdi, %rax), %eax
    cmpl    %edx, %eax
    jg      .L34
    subl    %edi, %edx
.L35:
    subl    %edi, %esi
.L33:
    vcvttsd2sil %xmm2, %eax
    leal    1(%rax), %ecx
    testl   %r8d, %r8d
    jle     .L36
    vroundsd $9, %xmm12, %xmm12, %xmm2
    vcvttsd2sil %xmm2, %r10d
    leal    4096(%r8, %r10), %r10d
    cmpl    %eax, %r10d
    jg      .L37
    subl    %r8d, %eax
.L38:
    subl    %r8d, %ecx
.L36:
    vaddsd  %xmm14, %xmm14, %xmm5
    vmulsd  %xmm14, %xmm14, %xmm2
    movzbl  %dl, %edx
    movzbl  %al, %eax
    vaddsd  %xmm0, %xmm0, %xmm6
    movzbl  %cl, %ecx
    vbroadcastsd %xmm14, %ymm14
    movzbl  %sil, %esi
    movl    2276(%rsp, %rdx, 4), %r11d
    vbroadcastsd %xmm1, %ymm1
    vbroadcastsd %xmm3, %ymm3
    movl    2276(%rsp, %rsi, 4), %r10d
    vsubsd  %xmm5, %xmm13, %xmm5
    leal    (%r11, %rax), %edx
    vsubsd  %xmm6, %xmm13, %xmm6
    addl    %ecx, %r11d
    addl    %r10d, %eax
    movzbl  2276(%rsp, %rdx, 4), %edx
    movl    %r11d, %r11d
    addl    %r10d, %ecx
    movl    %eax, %eax
    vmulsd  %xmm2, %xmm5, %xmm2
    movl    %ecx, %ecx
    movzbl  2276(%rsp, %r11, 4), %r11d
    movzbl  2276(%rsp, %rax, 4), %eax
    vmulsd  %xmm0, %xmm0, %xmm5
    salq    $5, %rdx
    vbroadcastsd %xmm0, %ymm0
    movzbl  2276(%rsp, %rcx, 4), %ecx
    salq    $5, %r11
    salq    $5, %rax
    salq    $5, %rcx
    vbroadcastsd %xmm2, %ymm2
    vmulsd  %xmm5, %xmm6, %xmm15
    vmulpd  37232(%rsp, %rdx), %ymm14, %ymm5
    vmulpd  53680(%rsp, %rdx), %ymm0, %ymm6
    vmulpd  37232(%rsp, %r11), %ymm14, %ymm14
    vmulpd  53680(%rsp, %rax), %ymm0, %ymm0
    vaddpd  %ymm5, %ymm6, %ymm6
    vmulpd  53680(%rsp, %r11), %ymm1, %ymm5
    vmulpd  53680(%rsp, %rcx), %ymm1, %ymm1
    vaddpd  %ymm14, %ymm5, %ymm5
    vmulpd  37232(%rsp, %rax), %ymm3, %ymm14
    vmulpd  37232(%rsp, %rcx), %ymm3, %ymm3
    vaddpd  %ymm14, %ymm0, %ymm0
    vaddpd  %ymm3, %ymm1, %ymm1
    vsubpd  %ymm6, %ymm0, %ymm0
    vsubpd  %ymm5, %ymm1, %ymm1
    vmulpd  %ymm2, %ymm0, %ymm0
    vmulpd  %ymm2, %ymm1, %ymm1
    vaddpd  %ymm6, %ymm0, %ymm0
    vaddpd  %ymm5, %ymm1, %ymm1
    vbroadcastsd %xmm15, %ymm5
    vsubpd  %ymm0, %ymm1, %ymm1
    vmulpd  %ymm5, %ymm1, %ymm1
    vaddpd  %ymm0, %ymm1, %ymm1
    vbroadcastsd %xmm7, %ymm0
    cmpb    $1, %r14b
    jne     .L39
    vdivpd  %ymm0, %ymm1, %ymm1
    addl    $1, %r9d
    vaddsd  %xmm4, %xmm4, %xmm4
    addl    %edi, %edi
    vaddsd  %xmm8, %xmm8, %xmm8
    vaddsd  %xmm9, %xmm9, %xmm9
    addl    %r8d, %r8d
    vaddsd  %xmm12, %xmm12, %xmm12
    vaddsd  %xmm7, %xmm7, %xmm7
    vaddpd  %ymm1, %ymm10, %ymm10
    cmpl    %r9d, %r13d
    jne     .L43
    vextractf128 $0x1, %ymm10, %xmm2
    vmovapd %xmm10, %xmm4
    vunpckhpd %xmm10, %xmm10, %xmm7
    movl    %r15d, %ebx
    vmovapd %xmm2, %xmm8
    vunpckhpd %xmm2, %xmm2, %xmm2
.L44:
    vmovsd  1632(%rsp), %xmm5
    vmovdqa .LC18(%rip), %xmm9
    vmovsd  1664(%rsp), %xmm6
    vaddsd  %xmm5, %xmm4, %xmm4
    vmulsd  .LC16(%rip), %xmm4, %xmm4
    vaddsd  %xmm5, %xmm7, %xmm7
    vmulsd  .LC16(%rip), %xmm7, %xmm7
    vaddsd  %xmm5, %xmm8, %xmm8
    vaddsd  %xmm5, %xmm2, %xmm2
    vmulsd  .LC16(%rip), %xmm8, %xmm8
    vmulsd  .LC16(%rip), %xmm2, %xmm2
    vaddsd  %xmm6, %xmm4, %xmm4
    vaddsd  %xmm6, %xmm7, %xmm7
    vaddsd  %xmm6, %xmm8, %xmm8
    vroundsd $9, %xmm4, %xmm4, %xmm4
    vcvttsd2sil %xmm4, %ecx
    vroundsd $9, %xmm7, %xmm7, %xmm7
    vroundsd $9, %xmm8, %xmm8, %xmm8
    vmovd   %ecx, %xmm4
    vcvttsd2sil %xmm7, %ecx
    vpminsd %xmm9, %xmm4, %xmm4
    vpxor   %xmm9, %xmm9, %xmm9
    vpmaxsd %xmm9, %xmm4, %xmm4
    vpinsrd $0, %ecx, %xmm9, %xmm7
    vcvttsd2sil %xmm8, %ecx
    vmovdqa .LC18(%rip), %xmm9
    vpminsd %xmm9, %xmm7, %xmm7
    vpxor   %xmm9, %xmm9, %xmm9
    vpmaxsd %xmm9, %xmm7, %xmm7
    vpinsrd $0, %ecx, %xmm9, %xmm8
    vmovdqa .LC18(%rip), %xmm9
    vpminsd %xmm9, %xmm8, %xmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpmaxsd %xmm9, %xmm8, %xmm8
.L46:
    vaddsd  1664(%rsp), %xmm2, %xmm2
    vpslld  $8, %xmm7, %xmm7
    movq    1728(%rsp), %rax
    movq    1536(%rsp), %rdi
    vroundsd $9, %xmm2, %xmm2, %xmm2
    vcvttsd2sil %xmm2, %ecx
    vmovdqa .LC18(%rip), %xmm2
    vmovd   %ecx, %xmm9
    movq    1600(%rsp), %rcx
    vpminsd %xmm2, %xmm9, %xmm9
    vpxor   %xmm2, %xmm2, %xmm2
    vpmaxsd %xmm2, %xmm9, %xmm9
    vpslld  $16, %xmm4, %xmm2
    vpor    %xmm7, %xmm2, %xmm2
    vpslld  $24, %xmm9, %xmm9
    vpor    %xmm8, %xmm2, %xmm2
    vpor    %xmm2, %xmm9, %xmm9
    vmovd   %xmm9, (%rcx, %rax, 4)
    addq    $1, %rax
    movq    %rax, 1728(%rsp)
    cmpq    %rdi, %rax
    jne     .L30
    movl    1408(%rsp), %edi
    movq    1376(%rsp), %r11
    movl    %ebx, %r8d
    movq    %rcx, %rdx
    movl    1440(%rsp), %ebx
    movl    32(%rbp), %ecx
    addl    $1, %edi
    addq    %r11, %rdx
    movl    1344(%rsp), %r15d
    vmovsd  1312(%rsp), %xmm7
    vmovsd  1568(%rsp), %xmm3
    vmovsd  1280(%rsp), %xmm2
    vmovsd  1664(%rsp), %xmm15
    cmpl    %edi, %ebx
    jne     .L31
    vzeroupper
.L70:
    leaq    -40(%rbp), %rsp
    popq    %rbx
    popq    %r12
    popq    %r13
    popq    %r14
    popq    %r15
    popq    %rbp
    ret
.L74:
    imull   %r15d, %eax
    movslq  %r12d, %rdx
    movq    %rsi, %rdi
    vmovsd  .LC15(%rip), %xmm15
    vmovsd  .LC0(%rip), %xmm8
    vmovapd %xmm7, %xmm1
    vmovsd  .LC11(%rip), %xmm9
    vmovsd  %xmm3, 1600(%rsp)
    vmovsd  %xmm15, 1664(%rsp)
    vmovapd %xmm5, %xmm2
    cltq
    leaq    (%r11, %rax, 4), %rcx
    movl    %r9d, %eax
.L29:
    vcvtsi2sdl %r15d, %xmm11, %xmm0
    movl    %eax, %esi
    movq    %rdx, 1728(%rsp)
    vmulsd  1704(%rsp), %xmm0, %xmm0
    subl    %r12d, %esi
    movq    %rdi, 1568(%rsp)
    movl    %eax, %edi
    vmovsd  %xmm1, 1536(%rsp)
    addq    %rdx, %rsi
    vmovsd  %xmm2, 1504(%rsp)
    vaddsd  %xmm2, %xmm0, %xmm0
    vdivsd  64(%rbp), %xmm0, %xmm0
    vmulsd  %xmm1, %xmm0, %xmm4
    vmovapd %xmm4, %xmm15
.L26:
    vcvtsi2sdl 1728(%rsp), %xmm11, %xmm1
    vmulsd  1712(%rsp), %xmm1, %xmm1
    vaddsd  1600(%rsp), %xmm1, %xmm5
    vdivsd  56(%rbp), %xmm5, %xmm5
    vmulsd  1720(%rsp), %xmm5, %xmm5
    testl   %r13d, %r13d
    jle     .L17
    vmovapd %xmm15, %xmm12
    vxorpd  %xmm13, %xmm13, %xmm13
    vmovapd %xmm8, %xmm10
    xorl    %r10d, %r10d
    vmovsd  %xmm8, 1632(%rsp)
.p2align 4
.p2align 3
.L20:
    vaddsd  %xmm9, %xmm5, %xmm1
    vaddsd  %xmm9, %xmm12, %xmm2
    vmovsd  .LC12(%rip), %xmm7
    vroundsd $9, %xmm1, %xmm1, %xmm0
    vsubsd  %xmm0, %xmm1, %xmm1
    vroundsd $9, %xmm2, %xmm2, %xmm3
    vsubsd  %xmm3, %xmm2, %xmm2
    vcvttsd2sil %xmm0, %r8d
    vcvttsd2sil %xmm3, %eax
    vaddsd  %xmm1, %xmm1, %xmm14
    vmulsd  %xmm1, %xmm1, %xmm3
    vaddsd  %xmm2, %xmm2, %xmm4
    vsubsd  %xmm8, %xmm1, %xmm0
    vsubsd  %xmm8, %xmm2, %xmm6
    vbroadcastsd %xmm1, %ymm1
    movzbl  %r8b, %r9d
    addl    $1, %r8d
    vsubsd  %xmm14, %xmm7, %xmm14
    movl    2276(%rsp, %r9, 4), %r9d
    movzbl  %r8b, %r8d
    vsubsd  %xmm4, %xmm7, %xmm4
    movl    2276(%rsp, %r8, 4), %ebx
    movzbl  %al, %r8d
    addl    $1, %eax
    vbroadcastsd %xmm6, %ymm6
    leal    (%r8, %r9), %r11d
    movzbl  %al, %eax
    vbroadcastsd %xmm0, %ymm0
    vmulsd  %xmm3, %xmm14, %xmm14
    addl    %eax, %r9d
    addl    %ebx, %r8d
    addl    %ebx, %eax
    vmulsd  %xmm2, %xmm2, %xmm3
    vbroadcastsd %xmm2, %ymm2
    movl    %r9d, %r9d
    movl    %r8d, %r8d
    movzbl  2276(%rsp, %r11, 4), %r11d
    movl    %eax, %eax
    movzbl  2276(%rsp, %r9, 4), %r9d
    movzbl  2276(%rsp, %r8, 4), %r8d
    movzbl  2276(%rsp, %rax, 4), %eax
    salq    $5, %r11
    salq    $5, %r9
    salq    $5, %r8
    salq    $5, %rax
    vbroadcastsd %xmm14, %ymm14
    vmulsd  %xmm3, %xmm4, %xmm4
    vmulpd  37232(%rsp, %r11), %ymm1, %ymm7
    vmulpd  53680(%rsp, %r11), %ymm2, %ymm3
    vmulpd  37232(%rsp, %r9), %ymm1, %ymm1
    vmulpd  53680(%rsp, %r8), %ymm2, %ymm2
    vbroadcastsd %xmm4, %ymm4
    vaddpd  %ymm3, %ymm7, %ymm7
    vmulpd  53680(%rsp, %r9), %ymm6, %ymm3
    vmulpd  53680(%rsp, %rax), %ymm6, %ymm6
    vaddpd  %ymm3, %ymm1, %ymm1
    vmulpd  37232(%rsp, %r8), %ymm0, %ymm3
    vmulpd  37232(%rsp, %rax), %ymm0, %ymm0
    vaddpd  %ymm2, %ymm3, %ymm3
    vaddpd  %ymm6, %ymm0, %ymm0
    vsubpd  %ymm7, %ymm3, %ymm3
    vsubpd  %ymm1, %ymm0, %ymm0
    vmulpd  %ymm14, %ymm3, %ymm3
    vmulpd  %ymm14, %ymm0, %ymm0
    vaddpd  %ymm7, %ymm3, %ymm3
    vaddpd  %ymm1, %ymm0, %ymm0
    vbroadcastsd %xmm10, %ymm1
    vsubpd  %ymm3, %ymm0, %ymm0
    vmulpd  %ymm4, %ymm0, %ymm0
    vaddpd  %ymm3, %ymm0, %ymm0
    cmpb    $1, %r14b
    jne     .L75
    vdivpd  %ymm1, %ymm0, %ymm0
    vaddsd  %xmm5, %xmm5, %xmm5
    vaddsd  %xmm12, %xmm12, %xmm12
    addl    $1, %r10d
    vaddsd  %xmm10, %xmm10, %xmm10
    vaddpd  %ymm0, %ymm13, %ymm13
    cmpl    %r10d, %r13d
    jne     .L20
    vextractf128 $0x1, %ymm13, %xmm2
    vmovapd %xmm13, %xmm5
    vunpckhpd %xmm13, %xmm13, %xmm1
    vmovsd  1632(%rsp), %xmm14
    vmovapd %xmm2, %xmm10
    vunpckhpd %xmm2, %xmm2, %xmm2
.L21:
    vaddsd  %xmm14, %xmm5, %xmm5
    vmulsd  .LC16(%rip), %xmm5, %xmm5
    vaddsd  %xmm14, %xmm1, %xmm1
    vmovsd  1664(%rsp), %xmm7
    vmulsd  .LC16(%rip), %xmm1, %xmm1
    vaddsd  %xmm14, %xmm10, %xmm10
    vmovdqa .LC18(%rip), %xmm12
    vaddsd  %xmm14, %xmm2, %xmm2
    vmulsd  .LC16(%rip), %xmm10, %xmm10
    vmulsd  .LC16(%rip), %xmm2, %xmm2
    vaddsd  %xmm7, %xmm5, %xmm5
    vaddsd  %xmm7, %xmm1, %xmm1
    vaddsd  %xmm7, %xmm10, %xmm10
    vroundsd $9, %xmm5, %xmm5, %xmm5
    vcvttsd2sil %xmm5, %eax
    vroundsd $9, %xmm1, %xmm1, %xmm1
    vroundsd $9, %xmm10, %xmm10, %xmm10
    vmovd   %eax, %xmm5
    vcvttsd2sil %xmm1, %eax
    vpminsd %xmm12, %xmm5, %xmm5
    vpxor   %xmm12, %xmm12, %xmm12
    vpmaxsd %xmm12, %xmm5, %xmm5
    vpinsrd $0, %eax, %xmm12, %xmm1
    vcvttsd2sil %xmm10, %eax
    vmovdqa .LC18(%rip), %xmm12
    vpminsd %xmm12, %xmm1, %xmm1
    vpxor   %xmm12, %xmm12, %xmm12
    vpmaxsd %xmm12, %xmm1, %xmm1
    vpinsrd $0, %eax, %xmm12, %xmm10
    vmovdqa .LC18(%rip), %xmm12
    vpminsd %xmm12, %xmm10, %xmm10
    vpxor   %xmm12, %xmm12, %xmm12
    vpmaxsd %xmm12, %xmm10, %xmm10
.L28:
    vaddsd  1664(%rsp), %xmm2, %xmm2
    vpslld  $16, %xmm5, %xmm5
    vpslld  $8, %xmm1, %xmm1
    vpor    %xmm5, %xmm1, %xmm1
    vroundsd $9, %xmm2, %xmm2, %xmm2
    vcvttsd2sil %xmm2, %eax
    vpor    %xmm10, %xmm1, %xmm5
    vmovdqa .LC18(%rip), %xmm2
    vmovd   %eax, %xmm1
    movq    1728(%rsp), %rax
    vpminsd %xmm2, %xmm1, %xmm1
    vpxor   %xmm2, %xmm2, %xmm2
    vpmaxsd %xmm2, %xmm1, %xmm1
    vpslld  $24, %xmm1, %xmm1
    vpor    %xmm1, %xmm5, %xmm1
    vmovd   %xmm1, (%rcx, %rax, 4)
    addq    $1, %rax
    movq    %rax, 1728(%rsp)
    cmpq    %rsi, %rax
    jne     .L26
    vmovsd  1536(%rsp), %xmm1
    movl    %edi, %eax
    movq    1568(%rsp), %rdi
    addl    $1, %r15d
    vmovsd  1504(%rsp), %xmm2
    addq    %rdi, %rcx
    cmpl    %r15d, 16(%rbp)
    jne     .L29
    vzeroupper
    jmp     .L70
.p2align 4, , 10
.p2align 3
.L75:
    vandpd  .LC13(%rip), %ymm0, %ymm0
    vaddsd  %xmm5, %xmm5, %xmm5
    vaddsd  %xmm12, %xmm12, %xmm12
    addl    $1, %r10d
    vaddsd  %xmm10, %xmm10, %xmm10
    vdivpd  %ymm1, %ymm0, %ymm0
    vaddpd  %ymm0, %ymm13, %ymm13
    cmpl    %r10d, %r13d
    jne     .L20
    vextractf128 $0x1, %ymm13, %xmm2
    vmovapd %xmm13, %xmm5
    vunpckhpd %xmm13, %xmm13, %xmm1
    vmovapd %xmm2, %xmm10
    vunpckhpd %xmm2, %xmm2, %xmm2
.L22:
    vmulsd  .LC17(%rip), %xmm5, %xmm5
    vmovdqa .LC18(%rip), %xmm12
    vmovsd  1664(%rsp), %xmm7
    vmulsd  .LC17(%rip), %xmm1, %xmm1
    vmulsd  .LC17(%rip), %xmm10, %xmm10
    vmulsd  .LC17(%rip), %xmm2, %xmm2
    vaddsd  %xmm7, %xmm5, %xmm5
    vaddsd  %xmm7, %xmm1, %xmm1
    vaddsd  %xmm7, %xmm10, %xmm10
    vroundsd $9, %xmm5, %xmm5, %xmm5
    vcvttsd2sil %xmm5, %eax
    vroundsd $9, %xmm1, %xmm1, %xmm1
    vroundsd $9, %xmm10, %xmm10, %xmm10
    vmovd   %eax, %xmm5
    vcvttsd2sil %xmm1, %eax
    vpminsd %xmm12, %xmm5, %xmm5
    vpxor   %xmm12, %xmm12, %xmm12
    vpmaxsd %xmm12, %xmm5, %xmm5
    vpinsrd $0, %eax, %xmm12, %xmm1
    vcvttsd2sil %xmm10, %eax
    vmovdqa .LC18(%rip), %xmm12
    vpminsd %xmm12, %xmm1, %xmm1
    vpxor   %xmm12, %xmm12, %xmm12
    vpmaxsd %xmm12, %xmm1, %xmm1
    vpinsrd $0, %eax, %xmm12, %xmm10
    vmovdqa .LC18(%rip), %xmm12
    vpminsd %xmm12, %xmm10, %xmm10
    vpxor   %xmm12, %xmm12, %xmm12
    vpmaxsd %xmm12, %xmm10, %xmm10
    jmp     .L28
.p2align 4, , 10
.p2align 3
.L39:
    addl    $1, %r9d
    vaddsd  %xmm4, %xmm4, %xmm4
    vaddsd  %xmm8, %xmm8, %xmm8
    addl    %edi, %edi
    vandpd  .LC13(%rip), %ymm1, %ymm1
    vaddsd  %xmm9, %xmm9, %xmm9
    vaddsd  %xmm12, %xmm12, %xmm12
    addl    %r8d, %r8d
    vaddsd  %xmm7, %xmm7, %xmm7
    vdivpd  %ymm0, %ymm1, %ymm1
    vaddpd  %ymm1, %ymm10, %ymm10
    cmpl    %r9d, %r13d
    jne     .L43
    vextractf128 $0x1, %ymm10, %xmm2
    vmovapd %xmm10, %xmm4
    vunpckhpd %xmm10, %xmm10, %xmm7
    movl    %r15d, %ebx
    vmovapd %xmm2, %xmm8
    vunpckhpd %xmm2, %xmm2, %xmm2
.L45:
    vmulsd  .LC17(%rip), %xmm4, %xmm4
    vmovdqa .LC18(%rip), %xmm9
    vmovsd  1664(%rsp), %xmm5
    vmulsd  .LC17(%rip), %xmm7, %xmm7
    vmulsd  .LC17(%rip), %xmm8, %xmm8
    vmulsd  .LC17(%rip), %xmm2, %xmm2
    vaddsd  %xmm5, %xmm4, %xmm4
    vaddsd  %xmm5, %xmm7, %xmm7
    vaddsd  %xmm5, %xmm8, %xmm8
    vroundsd $9, %xmm4, %xmm4, %xmm4
    vcvttsd2sil %xmm4, %ecx
    vroundsd $9, %xmm7, %xmm7, %xmm7
    vroundsd $9, %xmm8, %xmm8, %xmm8
    vmovd   %ecx, %xmm4
    vcvttsd2sil %xmm7, %ecx
    vpminsd %xmm9, %xmm4, %xmm4
    vpxor   %xmm9, %xmm9, %xmm9
    vpmaxsd %xmm9, %xmm4, %xmm4
    vpinsrd $0, %ecx, %xmm9, %xmm7
    vcvttsd2sil %xmm8, %ecx
    vmovdqa .LC18(%rip), %xmm9
    vpminsd %xmm9, %xmm7, %xmm7
    vpxor   %xmm9, %xmm9, %xmm9
    vpmaxsd %xmm9, %xmm7, %xmm7
    vpinsrd $0, %ecx, %xmm9, %xmm8
    vmovdqa .LC18(%rip), %xmm9
    vpminsd %xmm9, %xmm8, %xmm8
    vpxor   %xmm9, %xmm9, %xmm9
    vpmaxsd %xmm9, %xmm8, %xmm8
    jmp     .L46
.p2align 4, , 10
.p2align 3
.L34:
    cmpl    %esi, %eax
    jg      .L33
    jmp     .L35
.p2align 4, , 10
.p2align 3
.L37:
    cmpl    %ecx, %r10d
    jg      .L36
    jmp     .L38
.p2align 4, , 10
.p2align 3
.L17:
    vxorpd  %xmm5, %xmm5, %xmm5
    vmovapd %xmm5, %xmm1
    vmovapd %xmm5, %xmm10
    vmovapd %xmm5, %xmm2
    cmpb    $1, %r14b
    jne     .L22
    vmovsd  .LC0(%rip), %xmm14
    jmp     .L21
.L32:
    vxorpd  %xmm2, %xmm2, %xmm2
    vmovapd %xmm2, %xmm8
    vmovapd %xmm2, %xmm7
    vmovapd %xmm2, %xmm4
    cmpb    $1, %r14b
    jne     .L45
    vmovsd  .LC0(%rip), %xmm5
    vmovsd  %xmm5, 1632(%rsp)
    jmp     .L44
// // SIZE(ksvgTurbulenceApplyAvx2_x86_64)
    RODATA
.balign 8
.LC0: TURB_DBL_1
.LC2: TURB_DBL_1_256
    RODATA
.balign 32
.LC3: TURB_PERMUTATION_DATA
    RODATA
.balign 8
.LC11: TURB_DBL_4096
.LC12: TURB_DBL_3
    RODATA
.balign 32
.LC13: TURB_ABS_MASK_AVX2
    RODATA
.balign 8
.LC15: TURB_DBL_0_5
.LC16: TURB_DBL_127_5
.LC17: TURB_DBL_255
    RODATA
.balign 16
.LC18: TURB_INT_255_XMM
GNU_STACK
