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
 * 8 ARGB8888 pixels per vector iteration. The arithmetic instruction order is
 * bit-identical to the SSSE3 kernel (FORMULA): (a*b) * (k1/255), then
 * + a*k2, + b*k3, + (k4*255 + 0.5), truncate and saturate. Because the folded
 * k1/255 constant is computed once in the prologue, the pixel loop has no
 * divisions at all.
 *
 * Deliberately NO FMA (`vfmadd*ps`): the reference evaluates separate mul+add
 * steps and fusing them would change the rounding.
 *
 * Linear mode replaces the sRGB transfer functions with 16-chunk `vpshufb`
 * lookups over the caller-supplied LUTs (identical to the color-matrix AVX2
 * kernel). Alpha always stays in encoded space, so it is saved from the raw
 * pixel before decoding and restored afterwards.
 *
 * Register map:
 *   ymm0/ymm1  extraction scratch / pack scratch
 *   ymm2/ymm3  raw pixels (non-linear) or decoded pixels (linear)
 *   ymm4/ymm5  results R/A (also scalar-tail scratch-free)
 *   ymm6/ymm7  results B/G (and saved alpha during the LUT decode)
 *   ymm8  k2, ymm9 k3, ymm10 k1/255, ymm11 k4*255+0.5
 *   ymm12/ymm13/ymm14 formula temporaries (ymm14 also LUT scratch)
 *   ymm15  zero
 * GPRs: r12 src1, r13 src2, r14 dst, r15 row stride (width*4),
 *       ebx clipRight, ebp clipLeft.
 */

#include "asm_macros.S"

/* 4-bit nibble shift; named so the `$` does not look like a macro argument. */
.equ SHR4, 4
/* Named so the `$` does not look like a macro argument inside LUT macros. */
.equ LUT_STEP, 16
.equ LUT_LIMIT, 256

/* t = a*b*(k1/255); t += a*k2; t += b*k3; t += k4*255+0.5;
   truncate, then saturate to bytes. A and B hold 8 integer lanes in
   [0,255]; DST receives the 8 packed result bytes (split 0..3, 16..19). */
.macro FORMULA8 a, b, dst
    vcvtdq2ps \a, %ymm12
    vcvtdq2ps \b, %ymm13
    vmulps %ymm13, %ymm12, %ymm14
    vmulps %ymm10, %ymm14, %ymm14
    vmulps %ymm8, %ymm12, %ymm12
    vaddps %ymm12, %ymm14, %ymm14
    vmulps %ymm9, %ymm13, %ymm13
    vaddps %ymm13, %ymm14, %ymm14
    vaddps %ymm11, %ymm14, %ymm14
    vcvttps2dq %ymm14, %ymm14
    vpackssdw %ymm15, %ymm14, %ymm14
    vpackuswb %ymm15, %ymm14, %ymm14
    vmovdqa %ymm14, \dst
.endm

/* Packed bytes in the low 4 bytes of each 128-bit lane -> 8 dword lanes. */
.macro WIDEN8 ch
    vpunpcklbw %ymm15, \ch, \ch
    vpunpcklwd %ymm15, \ch, \ch
.endm

/* Decode ymm0/ymm1 through the 256-byte table at %rdi into ymm2/ymm3.
   Clobbers ymm0, ymm1, ymm4, ymm5, ymm12, ymm13, ymm14, %rax, %rcx. */
.macro LUTDECODE2
    vbroadcastf128 .LnibbleMask(%rip), %ymm12
    vpand %ymm12, %ymm0, %ymm4
    vpand %ymm12, %ymm1, %ymm5
    vpsrlw $SHR4, %ymm0, %ymm0
    vpsrlw $SHR4, %ymm1, %ymm1
    vpand %ymm12, %ymm0, %ymm0
    vpand %ymm12, %ymm1, %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    vpxor %ymm3, %ymm3, %ymm3
    xorl %ecx, %ecx
    leaq .LhiTab(%rip), %rax
1:
    vbroadcastf128 (%rdi, %rcx, 1), %ymm13
    vbroadcastf128 (%rax, %rcx, 1), %ymm14
    vpshufb %ymm4, %ymm13, %ymm12
    vpcmpeqb %ymm0, %ymm14, %ymm14
    vpand %ymm14, %ymm12, %ymm12
    vpor %ymm12, %ymm2, %ymm2
    vpshufb %ymm5, %ymm13, %ymm12
    vbroadcastf128 (%rax, %rcx, 1), %ymm14
    vpcmpeqb %ymm1, %ymm14, %ymm14
    vpand %ymm14, %ymm12, %ymm12
    vpor %ymm12, %ymm3, %ymm3
    addq $LUT_STEP, %rcx
    cmpq $LUT_LIMIT, %rcx
    jne 1b
.endm

/* Encode the packed result bytes in REG through the table at %r11, in place.
   Clobbers ymm0, ymm1, ymm12, ymm13, ymm14, %rax, %rcx. */
.macro LUTENCODE reg
    vbroadcastf128 .LnibbleMask(%rip), %ymm14
    vpand %ymm14, \reg, %ymm12
    vpsrlw $SHR4, \reg, %ymm13
    vpand %ymm14, %ymm13, %ymm13
    vpxor %ymm14, %ymm14, %ymm14
    xorl %ecx, %ecx
    leaq .LhiTab(%rip), %rax
1:
    vbroadcastf128 (%r11, %rcx, 1), %ymm0
    vpshufb %ymm12, %ymm0, %ymm0
    vbroadcastf128 (%rax, %rcx, 1), %ymm1
    vpcmpeqb %ymm13, %ymm1, %ymm1
    vpand %ymm1, %ymm0, %ymm0
    vpor %ymm0, %ymm14, %ymm14
    addq $LUT_STEP, %rcx
    cmpq $LUT_LIMIT, %rcx
    jne 1b
    vmovdqa %ymm14, \reg
.endm

/* One scalar channel: a in %r8d, b in %r9d, result in %r8d.
   Clobbers xmm0..xmm3. */
.macro SCALAR_FORMULA
    vcvtsi2ss %r8d, %xmm15, %xmm0
    vcvtsi2ss %r9d, %xmm15, %xmm1
    vmulss %xmm1, %xmm0, %xmm2
    vmulss %xmm10, %xmm2, %xmm2
    vmulss %xmm0, %xmm8, %xmm3
    vaddss %xmm3, %xmm2, %xmm2
    vmulss %xmm1, %xmm9, %xmm3
    vaddss %xmm3, %xmm2, %xmm2
    vaddss %xmm11, %xmm2, %xmm2
    vmaxss %xmm15, %xmm2, %xmm2
    vminss .L255(%rip), %xmm2, %xmm2
    vcvttss2si %xmm2, %r8d
.endm

/* Store the four packed 8-byte results (B=ymm6 G=ymm7 R=ymm4 A=ymm5) as
   8 BGRA pixels. Clobbers ymm0, ymm1. */
.macro STORE8
    vpunpcklbw %ymm7, %ymm6, %ymm0
    vpunpcklbw %ymm5, %ymm4, %ymm1
    vpunpcklwd %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, (%r14)
.endm

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
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $64, %rsp
    /* Stack args: 120=clipRight, 128=clipBottom, 136=useLinear,
       144=srgbToLinear, 152=linearToSrgb. Scratch 0..63. */

    movq %rdi, %r12
    movq %rsi, %r13
    movq %rdx, %r14
    movl %ecx, %r15d
    movl %r8d, %ebp
    movl %r9d, %ebx

    movl 128(%rsp), %eax
    subl %ebx, %eax
    jle .Ldone
    movl %eax, 0(%rsp)

    /* First row starts at clipTop * width + clipLeft. */
    movl %ebx, %eax
    imull %r15d, %eax
    addl %ebp, %eax
    movslq %eax, %rax
    leaq (%r12, %rax, 4), %r12
    leaq (%r13, %rax, 4), %r13
    leaq (%r14, %rax, 4), %r14
    leal (%r15, %r15), %eax
    leal (%rax, %rax), %r15d
    movl 120(%rsp), %ebx

    /* ymm10 = k1/255, ymm8 = k2, ymm9 = k3,
       ymm11 = k4*255 + 0.5, ymm15 = zero. */
    vmovss .L255(%rip), %xmm12
    vdivss %xmm12, %xmm0, %xmm10
    vbroadcastss %xmm10, %ymm10
    vbroadcastss %xmm1, %ymm8
    vbroadcastss %xmm2, %ymm9
    vmulss %xmm12, %xmm3, %xmm11
    vaddss .Lhalf(%rip), %xmm11, %xmm11
    vbroadcastss %xmm11, %ymm11
    vpxor %ymm15, %ymm15, %ymm15

    movl 136(%rsp), %eax
    testb %al, %al
    jnz .Llinear_rows

/* ------------------------------------------------------------------ */
/* Non-linear rows (8px).                                              */
/* ------------------------------------------------------------------ */
.Lnonlin_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx
    movl %ecx, %r9d
    shrl $3, %r9d
    andl $7, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    vmovdqu (%r12), %ymm2
    vmovdqu (%r13), %ymm3

    /* B */
    vpand .LbyteMaskVec(%rip), %ymm2, %ymm0
    vpand .LbyteMaskVec(%rip), %ymm3, %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm6

    /* G */
    vpsrld $8, %ymm2, %ymm0
    vpsrld $8, %ymm3, %ymm1
    vpand .LbyteMaskVec(%rip), %ymm0, %ymm0
    vpand .LbyteMaskVec(%rip), %ymm1, %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm7

    /* R */
    vpsrld $16, %ymm2, %ymm0
    vpsrld $16, %ymm3, %ymm1
    vpand .LbyteMaskVec(%rip), %ymm0, %ymm0
    vpand .LbyteMaskVec(%rip), %ymm1, %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm4

    /* A */
    vpsrld $24, %ymm2, %ymm0
    vpsrld $24, %ymm3, %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm5

    STORE8

    addq $32, %r12
    addq $32, %r13
    addq $32, %r14
    subl $1, %r9d
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lnonlin_next
    movl %ecx, 8(%rsp)

.Lnonlin_tail_loop:
    movl (%r12), %eax
    movl (%r13), %r10d

    /* B */
    movl %eax, %r8d
    movl %r10d, %r9d
    andl $255, %r8d
    andl $255, %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    movl %r8d, %r11d

    /* G */
    movl %eax, %r8d
    movl %r10d, %r9d
    shrl $8, %r8d
    shrl $8, %r9d
    andl $255, %r8d
    andl $255, %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    shll $8, %r8d
    orl %r8d, %r11d

    /* R */
    movl %eax, %r8d
    movl %r10d, %r9d
    shrl $16, %r8d
    shrl $16, %r9d
    andl $255, %r8d
    andl $255, %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    shll $16, %r8d
    orl %r8d, %r11d

    /* A */
    shrl $24, %eax
    shrl $24, %r10d
    movl %eax, %r8d
    movl %r10d, %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    shll $24, %r8d
    orl %r8d, %r11d

    movl %r11d, (%r14)
    addq $4, %r12
    addq $4, %r13
    addq $4, %r14
    decl 8(%rsp)
    jnz .Lnonlin_tail_loop

.Lnonlin_next:
    movl %ebx, %eax
    subl %ebp, %eax
    shll $2, %eax
    movslq %eax, %rax
    movq %r15, %r8
    subq %rax, %r8
    addq %r8, %r12
    addq %r8, %r13
    addq %r8, %r14
    decl 0(%rsp)
    jnz .Lnonlin_rows
    jmp .Ldone

/* ------------------------------------------------------------------ */
/* Linear rows: LUT decode/encode around the same 8-wide core.         */
/* ------------------------------------------------------------------ */
.Llinear_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx
    movl %ecx, %r9d
    shrl $3, %r9d
    andl $7, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Llinear_tail

.p2align 4
.Llinear_block:
    vmovdqu (%r12), %ymm0
    vmovdqu (%r13), %ymm1

    /* Keep alpha encoded; decode only the RGB bytes. */
    vbroadcastf128 .LalphaMask(%rip), %ymm12
    vpand %ymm12, %ymm0, %ymm6
    vpand %ymm12, %ymm1, %ymm7

    movq 144(%rsp), %rdi
    LUTDECODE2

    vbroadcastf128 .LrgbMask(%rip), %ymm12
    vpand %ymm12, %ymm2, %ymm2
    vpor %ymm6, %ymm2, %ymm2
    vpand %ymm12, %ymm3, %ymm3
    vpor %ymm7, %ymm3, %ymm3

    /* B */
    vbroadcastf128 .LshuffleB(%rip), %ymm12
    vpshufb %ymm12, %ymm2, %ymm0
    vpshufb %ymm12, %ymm3, %ymm1
    WIDEN8 %ymm0
    WIDEN8 %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm6

    /* G */
    vbroadcastf128 .LshuffleG(%rip), %ymm12
    vpshufb %ymm12, %ymm2, %ymm0
    vpshufb %ymm12, %ymm3, %ymm1
    WIDEN8 %ymm0
    WIDEN8 %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm7

    /* R */
    vbroadcastf128 .LshuffleR(%rip), %ymm12
    vpshufb %ymm12, %ymm2, %ymm0
    vpshufb %ymm12, %ymm3, %ymm1
    WIDEN8 %ymm0
    WIDEN8 %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm4

    /* A (already encoded) */
    vbroadcastf128 .LshuffleA(%rip), %ymm12
    vpshufb %ymm12, %ymm2, %ymm0
    vpshufb %ymm12, %ymm3, %ymm1
    WIDEN8 %ymm0
    WIDEN8 %ymm1
    FORMULA8 %ymm0, %ymm1, %ymm5

    /* Re-encode RGB. */
    movq 152(%rsp), %r11
    LUTENCODE %ymm6
    LUTENCODE %ymm7
    LUTENCODE %ymm4

    STORE8

    addq $32, %r12
    addq $32, %r13
    addq $32, %r14
    subl $1, %r9d
    jnz .Llinear_block

.Llinear_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Llinear_next
    movq 144(%rsp), %r10
    movq 152(%rsp), %r11

.Llinear_tail_loop:
    movl (%r12), %eax
    movl (%r13), %edx
    xorl %esi, %esi

    /* B */
    movl %eax, %r8d
    movl %edx, %r9d
    andl $255, %r8d
    andl $255, %r9d
    movzbl (%r10, %r8, 1), %r8d
    movzbl (%r10, %r9, 1), %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    movzbl (%r11, %r8, 1), %r8d
    orl %r8d, %esi

    /* G */
    movl %eax, %r8d
    movl %edx, %r9d
    shrl $8, %r8d
    shrl $8, %r9d
    andl $255, %r8d
    andl $255, %r9d
    movzbl (%r10, %r8, 1), %r8d
    movzbl (%r10, %r9, 1), %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    movzbl (%r11, %r8, 1), %r8d
    shll $8, %r8d
    orl %r8d, %esi

    /* R */
    movl %eax, %r8d
    movl %edx, %r9d
    shrl $16, %r8d
    shrl $16, %r9d
    andl $255, %r8d
    andl $255, %r9d
    movzbl (%r10, %r8, 1), %r8d
    movzbl (%r10, %r9, 1), %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    movzbl (%r11, %r8, 1), %r8d
    shll $16, %r8d
    orl %r8d, %esi

    /* A (encoded) */
    shrl $24, %eax
    shrl $24, %edx
    movl %eax, %r8d
    movl %edx, %r9d
    SCALAR_FORMULA
    andl $255, %r8d
    shll $24, %r8d
    orl %r8d, %esi

    movl %esi, (%r14)
    addq $4, %r12
    addq $4, %r13
    addq $4, %r14
    decl %ecx
    jnz .Llinear_tail_loop

.Llinear_next:
    movl %ebx, %eax
    subl %ebp, %eax
    shll $2, %eax
    movslq %eax, %rax
    movq %r15, %r8
    subq %rax, %r8
    addq %r8, %r12
    addq %r8, %r13
    addq %r8, %r14
    decl 0(%rsp)
    jnz .Llinear_rows

.Ldone:
    vzeroupper
    addq $64, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

SIZE(SYM(ksvgArithmeticApplyAvx2))

RODATA
.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.Lhalf:
    .long 0x3f000000
.p2align 5
.LbyteMaskVec:
    .long 0x000000ff, 0x000000ff, 0x000000ff, 0x000000ff
    .long 0x000000ff, 0x000000ff, 0x000000ff, 0x000000ff
.p2align 4
.LnibbleMask:
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.p2align 4
.LalphaMask:
    .long 0xff000000, 0xff000000, 0xff000000, 0xff000000
.p2align 4
.LrgbMask:
    .long 0x00ffffff, 0x00ffffff, 0x00ffffff, 0x00ffffff
.p2align 4
.LshuffleB:
    .byte 0,4,8,12,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleG:
    .byte 1,5,9,13,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleR:
    .byte 2,6,10,14,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleA:
    .byte 3,7,11,15,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
/* High-nibble compare vectors: .LhiTab[i] = 16 copies of byte i. */
.LhiTab:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
    .byte 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    .byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
    .byte 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
    .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
    .byte 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    .byte 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9
    .byte 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
    .byte 11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
    .byte 12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12
    .byte 13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13
    .byte 14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
GNU_STACK
