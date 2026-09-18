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
 * x86-64 SSSE3 implementation of ksvgArithmeticApplySse.
 *
 * Non-linear path: 4 ARGB8888 pixels/iteration, no calls and no stack spills
 * in the pixel loop. Arithmetic instruction order matches the existing
 * SSSE3 C++ implementation.
 *
 * Linear mode uses exact 16-segment integer LUT replacements for the RGB
 * transfer functions; the vector path processes four pixels/iteration.
 *
 * Iter29: the G channel uses FORMULA_LINEAR_INPUTS_INPLACE directly on the
 * S2L4 outputs in xmm0/xmm1, eliminating two register copies before formula
 * evaluation while preserving the scalar arithmetic order.
 */
#include "asm_macros.S"

.equ ALPHA_SHIFT, 24

.macro S2L4 reg
    /* Four packed bytes -> four dwords. Mutate REG in place; none of the
       scratch instructions below needs the original packed-byte register. */
    /* Expand x0..x3 to words: x0,0,x1,0,... */
    punpcklbw %xmm15, \reg
    movdqa \reg, %xmm4
    psrlw $4, %xmm4
    pand .Ls2lNibbleMask(%rip), %xmm4     /* hi nibble */
    pand .Ls2lNibbleMask(%rip), \reg     /* lo nibble */

    movdqa .Ls2lBase(%rip), %xmm5
    pshufb %xmm4, %xmm5
    movdqa .Ls2lSlope(%rip), %xmm10
    pshufb %xmm4, %xmm10

    /* slope*lo + base*32, then round to byte. */
    pmaddubsw \reg, %xmm10
    psllw $5, %xmm5
    paddw %xmm5, %xmm10
    paddw .Ls2lRounding(%rip), %xmm10
    psrlw $5, %xmm10
    packuswb %xmm10, %xmm10          /* four live approximation bytes */

    /* Correction bitset. xmm3 is free in this macro, so keep the correction
       there and subtract it from the approximation in xmm10.  This removes
       the approximation-preservation movdqa xmm10 -> xmm11. */
    movdqa %xmm4, %xmm12
    pcmpgtb .Ls2lHi7(%rip), %xmm12
    movdqa .Ls2lSubLo(%rip), %xmm5
    pshufb \reg, %xmm5
    movdqa %xmm12, %xmm3
    pandn %xmm5, %xmm3
    movdqa .Ls2lSubHi(%rip), %xmm5
    pshufb \reg, %xmm5
    pand %xmm12, %xmm5
    por %xmm5, %xmm3
    movdqa .Ls2lOneHotHi(%rip), %xmm5
    pshufb %xmm4, %xmm5
    pand %xmm5, %xmm3
    pminub .Ls2lOneByte(%rip), %xmm3
    pshufb .LcompactEven4(%rip), %xmm3
    psubb %xmm3, %xmm10

    /* Exact low-16 values. Compact selector/result/mask before blending. */
    movdqa .Ls2lExactLow16(%rip), %xmm5
    pshufb \reg, %xmm5
    pshufb .LcompactEven4(%rip), %xmm5
    /* xmm4 is no longer needed after the high-nibble test; use it as the
       exact-low16 blend mask to avoid another register move. */
    pcmpeqb %xmm15, %xmm4
    pshufb .LcompactEven4(%rip), %xmm4
    pand %xmm4, %xmm5
    pandn %xmm10, %xmm4
    por %xmm5, %xmm4

    movdqa %xmm4, \reg
    punpcklbw %xmm15, \reg
    punpcklwd %xmm15, \reg
.endm

.macro L2S4 reg
    /* REG contains four packed bytes in lanes 0..3. Mutate it in place. */
    punpcklbw %xmm15, \reg  /* x0,0,x1,0,x2,0,x3,0 */

    movdqa \reg, %xmm3
    psrlw $4, %xmm3
    pand .L_nibble_mask(%rip), %xmm3      /* hi nibble */
    movdqa \reg, %xmm4
    pand .L_nibble_mask(%rip), %xmm4      /* lo nibble */

    movdqa .L_base_lut(%rip), %xmm5
    pshufb %xmm3, %xmm5
    movdqa .L_slope_lut(%rip), %xmm6
    pshufb %xmm3, %xmm6

    pmaddubsw %xmm4, %xmm6
    paddw .L_rounding(%rip), %xmm6
    psrlw $5, %xmm6
    packuswb %xmm6, %xmm6

    /* xmm5 is dead after the base lookup; compact it in place. */
    pshufb .LcompactEven4(%rip), %xmm5
    paddb %xmm5, %xmm6
    movdqa %xmm6, %xmm10

    movdqa \reg, %xmm3
    psrlw $3, %xmm3
    pand .L_group_mask(%rip), %xmm3
    movdqa %xmm3, %xmm4
    psubb .L_group16(%rip), %xmm4
    movdqa .L_correction_hi(%rip), %xmm6
    pshufb %xmm4, %xmm6
    movdqa %xmm3, %xmm4
    psrlw $4, %xmm4
    pand .L_one_byte(%rip), %xmm4
    psllw $7, %xmm4
    por %xmm3, %xmm4
    movdqa .L_correction_lo(%rip), %xmm3
    pshufb %xmm4, %xmm3
    por %xmm6, %xmm3
    movdqa \reg, %xmm4
    pand .L_low3_mask(%rip), %xmm4
    movdqa .L_onehot_lut(%rip), %xmm6
    pshufb %xmm4, %xmm6
    pand %xmm6, %xmm3
    pminub .L_one_byte(%rip), %xmm3
    pshufb .LcompactEven4(%rip), %xmm3
    psubb %xmm3, %xmm10

    movdqa .L_exact_low16(%rip), %xmm3
    /* REG is dead after this point except for the final result.  Extract
       the high nibble first, then destructively keep only the low nibble
       in REG for the exact-low16 lookup.  This removes one register copy. */
    movdqa \reg, %xmm6
    psrlw $4, %xmm6
    pand .L_nibble_mask(%rip), %xmm6
    pand .L_nibble_mask(%rip), \reg
    pshufb \reg, %xmm3
    pshufb .LcompactEven4(%rip), %xmm3
    pcmpeqb %xmm15, %xmm6
    pshufb .LcompactEven4(%rip), %xmm6
    pand %xmm6, %xmm3
    pandn %xmm10, %xmm6
    por %xmm3, %xmm6
    movdqa %xmm6, \reg
.endm

.macro FORMULA dst
    cvtdq2ps %xmm6, %xmm6
    cvtdq2ps %xmm7, %xmm7
    movaps %xmm6, %xmm12
    mulps %xmm7, %xmm12
    mulps %xmm13, %xmm12
    mulps %xmm8, %xmm6
    addps %xmm6, %xmm12
    mulps %xmm9, %xmm7
    addps %xmm7, %xmm12
    addps %xmm14, %xmm12
    cvttps2dq %xmm12, %xmm12
    packssdw %xmm15, %xmm12
    packuswb %xmm15, %xmm12
    movdqa %xmm12, \dst
.endm

.macro FORMULA_LINEAR_INPUTS_INPLACE src1, src2
    /* Same arithmetic as FORMULA_LINEAR_INPUTS, but keep the packed result
       in src1. src1/src2 are dead after the alpha calculation, so this
       removes the final result-copy movdqa without changing arithmetic order. */
    cvtdq2ps \src1, \src1
    cvtdq2ps \src2, \src2
    movaps \src1, %xmm12
    mulps \src2, \src1
    mulps %xmm13, \src1
    mulps %xmm8, %xmm12
    addps %xmm12, \src1
    mulps %xmm9, \src2
    addps \src2, \src1
    addps %xmm14, \src1
    cvttps2dq \src1, \src1
    packssdw %xmm15, \src1
    packuswb %xmm15, \src1
.endm

.macro FORMULA_LINEAR dst
    /* Exact arithmetic formula used by applyArithmeticFormulaSsse3().
       LUT values are already 0..255 linear-light bytes, so use the same
       normalized k1 and k4*255 representation as the non-linear path. */
    cvtdq2ps %xmm6, %xmm6
    cvtdq2ps %xmm7, %xmm7
    movaps %xmm6, %xmm12
    mulps %xmm7, %xmm12
    mulps %xmm13, %xmm12
    mulps %xmm8, %xmm6
    addps %xmm6, %xmm12
    mulps %xmm9, %xmm7
    addps %xmm7, %xmm12
    /* Scalar reference truncates after *255; no +0.5 here. */
    addps %xmm14, %xmm12
    cvttps2dq %xmm12, %xmm12
    packssdw %xmm15, %xmm12
    packuswb %xmm15, %xmm12
    movdqa %xmm12, \dst
.endm

.macro FORMULA_LINEAR_SCALAR gdst
    /* Exact scalar arithmeticChannel evaluation, using SSE scalar ops. */
    cvtdq2ps %xmm6, %xmm6
    cvtdq2ps %xmm7, %xmm7
    divss .L255(%rip), %xmm6
    divss .L255(%rip), %xmm7
    mulss %xmm13, %xmm6
    mulss %xmm7, %xmm6
    movss %xmm6, %xmm11
    mulss %xmm8, %xmm11
    addss %xmm11, %xmm6
    movss %xmm7, %xmm11
    mulss %xmm9, %xmm11
    addss %xmm11, %xmm6
    addss %xmm14, %xmm6
    mulss .L255(%rip), %xmm6
    maxss %xmm15, %xmm6
    minss .L255(%rip), %xmm6
    cvttss2sil %xmm6, \gdst
.endm

.text
.p2align 5

/*
 * void ksvgArithmeticApplySse(
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
.globl SYM(ksvgArithmeticApplySse)
TYPE(SYM(ksvgArithmeticApplySse), @function)
SYM(ksvgArithmeticApplySse):
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $32, %rsp
    movss %xmm0, 16(%rsp)
    movss %xmm3, 20(%rsp)

    /* Keep the persistent arguments in callee-saved registers. */
    movq %rdi, %r12                 /* src1 */
    movq %rsi, %r13                 /* src2 */
    movq %rdx, %r14                 /* dst */
    movl %ecx, %r15d                /* width */
    movl %r8d, %ebp                 /* clipLeft */
    movl %ebp, 24(%rsp)
    movl 88(%rsp), %ebx                 /* clipRight */
    movl %r9d, %r11d                /* clipTop */

    /* Number of rows remaining. Keep it in stack scratch: S2L4/L2S4 use xmm10. */
    movl 96(%rsp), %eax              /* clipBottom */
    subl %r11d, %eax                 /* rows = clipBottom - clipTop */
    jle .Ldone
    movl %eax, 12(%rsp)              /* persistent row counter */

    /* xmm8 = k2, xmm9 = k3, xmm13 = k1/255,
       xmm14 = k4*255 + 0.5, xmm12 = 255, xmm15 = zero. */
    movss %xmm0, %xmm13
    movss .L255(%rip), %xmm12
    shufps $0, %xmm12, %xmm12
    divps %xmm12, %xmm13
    shufps $0, %xmm13, %xmm13

    movss %xmm1, %xmm8
    shufps $0, %xmm8, %xmm8
    movss %xmm2, %xmm9
    shufps $0, %xmm9, %xmm9

    movss %xmm3, %xmm14
    shufps $0, %xmm14, %xmm14
    mulps %xmm12, %xmm14
    addps .Lhalf(%rip), %xmm14
    pxor %xmm15, %xmm15

    /* First row starts at clipTop * width + clipLeft. */
    movl %r11d, %eax
    imull %r15d, %eax
    addl %ebp, %eax
    movslq %eax, %rax
    leaq (%r12, %rax, 4), %rdi
    leaq (%r13, %rax, 4), %rsi
    leaq (%r14, %rax, 4), %rdx
    leal (%r15, %r15), %eax
    leal (%rax, %rax), %r15d          /* persistent row stride = width * 4 */

    /* Linear mode uses fixed built-in sRGB <-> linear transforms.
       The caller-supplied LUT pointers are intentionally ignored. */

.Lrow:
    /* count = clipRight - clipLeft; blocks = count / 4; tail = count & 3 */
    movl %ebx, %ecx
    subl %ebp, %ecx
    movl %ecx, %r9d
    shrl $2, %r9d

    jz .Ltail

    movl 104(%rsp), %eax
    testl %eax, %eax
    jne .Llinear_blocks

.p2align 4
    movdqa .LbyteMask(%rip), %xmm11
.Lblock:
    movdqu (%rdi), %xmm0             /* p1 */
    movdqu (%rsi), %xmm1             /* p2 */

    /* B: isolate byte 0 from each 32-bit pixel. */
    movdqa %xmm0, %xmm6
    movdqa %xmm1, %xmm7
    pand %xmm11, %xmm6
    pand %xmm11, %xmm7
    FORMULA %xmm2

    /* G: shift byte 1 into the low byte of each dword. */
    movdqa %xmm0, %xmm6
    movdqa %xmm1, %xmm7
    psrld $8, %xmm6
    psrld $8, %xmm7
    pand %xmm11, %xmm6
    pand %xmm11, %xmm7
    FORMULA %xmm3

    /* R: shift byte 2 into the low byte of each dword. */
    movdqa %xmm0, %xmm6
    movdqa %xmm1, %xmm7
    psrld $16, %xmm6
    psrld $16, %xmm7
    pand %xmm11, %xmm6
    pand %xmm11, %xmm7
    FORMULA %xmm4

    /* A: shift byte 3 into the low byte of each dword. */
    movdqa %xmm0, %xmm6
    movdqa %xmm1, %xmm7
    psrld $24, %xmm6
    psrld $24, %xmm7
    pand %xmm11, %xmm6
    pand %xmm11, %xmm7
    FORMULA %xmm5

    /* BGRA: each output contains four bytes in its low dword. */
    punpcklbw %xmm3, %xmm2
    punpcklbw %xmm5, %xmm4
    punpcklwd %xmm4, %xmm2
    movdqu %xmm2, (%rdx)

    leaq 16(%rdi), %rdi
    leaq 16(%rsi), %rsi
    leaq 16(%rdx), %rdx
    decl %r9d
    jnz .Lblock
    jmp .Ltail

/* 4-pixel linear-light SSSE3 block. The LUT implementation mirrors
   lookup256Ssse3(): 16 PSHUFBs selected by the high nibble. */
.p2align 4
.macro LINEAR_BLOCK_UNROLLED
    /*
     * Dual-channel phased pipeline.
     * Keep B's completed S2L values in xmm6/xmm7 while G is processed from
     * xmm0/xmm1.  This overlaps the expensive S2L phases without requiring
     * six simultaneously live scratch XMM registers.
     */
    movdqu (%rdi), %xmm0             /* raw p1 */
    movdqu (%rsi), %xmm1             /* raw p2 */

    /* B extraction -> S2L.  xmm0/xmm1 are re-used for G afterwards. */
    movdqa %xmm0, %xmm6
    movdqa %xmm1, %xmm7
    pshufb .LshuffleB(%rip), %xmm6
    pshufb .LshuffleB(%rip), %xmm7
    S2L4 %xmm6
    S2L4 %xmm7

    /* G extraction starts only after B S2L has established xmm6/xmm7. */
    pshufb .LshuffleG(%rip), %xmm0
    pshufb .LshuffleG(%rip), %xmm1
    S2L4 %xmm0
    S2L4 %xmm1

    /* B arithmetic: keep the packed result in xmm2. */
    FORMULA_LINEAR %xmm2

    /* G arithmetic: consume the S2L4 outputs directly.  These registers are
       dead after G, so the in-place form removes two register copies. */
    FORMULA_LINEAR_INPUTS_INPLACE %xmm0, %xmm1

    /* Convert both channels without GPR round-trips, then interleave. */
    L2S4 %xmm2
    L2S4 %xmm0
    punpcklbw %xmm0, %xmm2

    /* Reload source once for R/A; packed BG remains in xmm2. */
    movdqu (%rdi), %xmm0             /* raw p1 */
    movdqu (%rsi), %xmm1             /* raw p2 */

    /* R: fixed transfer -> arithmetic -> inverse transfer. */
    movdqa %xmm0, %xmm6
    movdqa %xmm1, %xmm7
    pshufb .LshuffleR(%rip), %xmm6
    pshufb .LshuffleR(%rip), %xmm7
    S2L4 %xmm6
    S2L4 %xmm7
    FORMULA_LINEAR %xmm12
    L2S4 %xmm12
    movd %xmm12, %r8d

    /* A remains in encoded space. Raw p1/p2 are still live in xmm0/xmm1.
       Alpha is already the top byte of each dword, so a dword shift replaces
       the shuffle + byte/word unpack chain with two instructions. */
    psrld $ALPHA_SHIFT, %xmm0
    psrld $ALPHA_SHIFT, %xmm1
    FORMULA_LINEAR_INPUTS_INPLACE %xmm0, %xmm1
    movd %xmm0, %eax

    /* Pack BG + RA from four packed dwords. */
    movd %r8d,  %xmm5
    movd %eax,  %xmm4
    punpcklbw %xmm4, %xmm5
    punpcklwd %xmm5, %xmm2
    movdqu %xmm2, (%rdx)

    leaq 16(%rdi), %rdi
    leaq 16(%rsi), %rsi
    leaq 16(%rdx), %rdx
.endm

.Llinear_blocks:
    /* FORMULA_LINEAR uses xmm12 as its accumulator; restore the persistent
       255 vector for each row before forming k4*255+0.5. */
    movdqa .L255Vec(%rip), %xmm12
    movss 20(%rsp), %xmm14
    shufps $0, %xmm14, %xmm14
    mulps %xmm12, %xmm14
    addps .Lhalf(%rip), %xmm14

    /* Four-block unroll: expose four independent 4-pixel iterations to
       the OoO core and amortize the loop branch/counter overhead. */
    movl %r9d, %eax
    shrl $2, %r9d                  /* quad count */
    andl $3, %eax                  /* remainder blocks */
    movl %eax, 28(%rsp)

.p2align 4
.Llinear_quad:
    testl %r9d, %r9d
    jz .Llinear_remainder
    LINEAR_BLOCK_UNROLLED
    LINEAR_BLOCK_UNROLLED
    LINEAR_BLOCK_UNROLLED
    LINEAR_BLOCK_UNROLLED
    decl %r9d
    jmp .Llinear_quad

.Llinear_remainder:
    movl 28(%rsp), %r9d
.Llinear_remainder_loop:
    testl %r9d, %r9d
    jz .Ltail
    LINEAR_BLOCK_UNROLLED
    decl %r9d
    jmp .Llinear_remainder_loop

.Ltail:
    /* LOOKUP4_BYTE clobbers %ecx; derive tail count from persistent bounds. */
    movl %ebx, %ecx
    subl %ebp, %ecx
    andl $3, %ecx
    jz .Lnext_row
    movl %ecx, 28(%rsp)

    movl 104(%rsp), %eax
    testl %eax, %eax
    jne .Ltail_linear

    /* Tail is scalarized locally, avoiding a PLT call. */
.Ltail_pixel:
    movl (%rdi), %eax                /* p1 */
    movl (%rsi), %r8d                /* p2 */

    /* B */
    movl %eax, %r9d
    movl %r8d, %r10d
    andl $255, %r9d
    andl $255, %r10d
    movd %r9d, %xmm6
    movd %r10d, %xmm7
    FORMULA %xmm6
    movd %xmm6, %r9d
    andl $255, %r9d

    /* G */
    movl %eax, %r10d
    movl %r8d, %r11d
    shrl $8, %r10d
    shrl $8, %r11d
    andl $255, %r10d
    andl $255, %r11d
    movd %r10d, %xmm6
    movd %r11d, %xmm7
    FORMULA %xmm6
    movd %xmm6, %r10d
    andl $255, %r10d

    /* R */
    movl %eax, %r11d
    shrl $16, %r11d
    shrl $16, %r8d
    andl $255, %r11d
    andl $255, %r8d
    movd %r11d, %xmm6
    movd %r8d, %xmm7
    FORMULA %xmm6
    movd %xmm6, %r11d
    andl $255, %r11d

    /* A */
    movl    (%rsi), %r8d              /* R extraction shifted p2; reload it */
    shrl $24, %eax
    shrl $24, %r8d
    movd %eax, %xmm6
    movd %r8d, %xmm7
    FORMULA %xmm6
    movd %xmm6, %eax
    andl $255, %eax

    shll $24, %eax
    shll $16, %r11d
    shll $8, %r10d
    orl %r11d, %r9d
    orl %r10d, %r9d
    orl %eax, %r9d
    movl %r9d, (%rdx)

    addq $4, %rdi
    addq $4, %rsi
    addq $4, %rdx
    decl 28(%rsp)
    jnz .Ltail_pixel
    jmp .Lnext_row

.Ltail_linear:
    /* Fixed transfer-function tail. Cache each source pixel in GPRs so
       RGB extraction does not re-read the same two addresses. */
    movss 16(%rsp), %xmm13
    shufps $0, %xmm13, %xmm13
    movss .L255(%rip), %xmm12
    shufps $0, %xmm12, %xmm12
    divps %xmm12, %xmm13
    shufps $0, %xmm13, %xmm13
    movss 20(%rsp), %xmm14
    shufps $0, %xmm14, %xmm14
    mulps %xmm12, %xmm14

.Ltail_linear_pixel:
    movl (%rdi), %r8d                /* p1 */
    movl (%rsi), %r9d                /* p2 */

    /* Alpha. */
    movl %r8d, %eax
    movl %r9d, %r10d
    shrl $24, %eax
    shrl $24, %r10d
    movd %eax, %xmm6
    movd %r10d, %xmm7
    FORMULA_LINEAR %xmm6
    movd %xmm6, %r10d
    andl $255, %r10d
    shll $24, %r10d

    /* R. */
    movl %r8d, %eax
    movl %r9d, %r11d
    shrl $16, %eax
    shrl $16, %r11d
    andl $255, %eax
    andl $255, %r11d
    movd %eax, %xmm6
    movd %r11d, %xmm7
    S2L4 %xmm6
    S2L4 %xmm7
    FORMULA_LINEAR %xmm6
    movdqa %xmm6, %xmm7
    L2S4 %xmm7
    movd %xmm7, %eax
    andl $255, %eax
    shll $16, %eax
    orl %eax, %r10d

    /* G. */
    movl %r8d, %eax
    movl %r9d, %r11d
    shrl $8, %eax
    shrl $8, %r11d
    andl $255, %eax
    andl $255, %r11d
    movd %eax, %xmm6
    movd %r11d, %xmm7
    S2L4 %xmm6
    S2L4 %xmm7
    FORMULA_LINEAR %xmm6
    movdqa %xmm6, %xmm7
    L2S4 %xmm7
    movd %xmm7, %eax
    andl $255, %eax
    shll $8, %eax
    orl %eax, %r10d

    /* B. */
    movl %r8d, %eax
    movl %r9d, %r11d
    andl $255, %eax
    andl $255, %r11d
    movd %eax, %xmm6
    movd %r11d, %xmm7
    S2L4 %xmm6
    S2L4 %xmm7
    FORMULA_LINEAR %xmm6
    movdqa %xmm6, %xmm7
    L2S4 %xmm7
    movd %xmm7, %eax
    andl $255, %eax
    orl %eax, %r10d

    movl %r10d, (%rdx)
    addq $4, %rdi
    addq $4, %rsi
    addq $4, %rdx
    decl 28(%rsp)
    jnz .Ltail_linear_pixel

.Lnext_row:
    movl 24(%rsp), %ebp
    /* Pointers currently point after the clipped span. Advance by
       width*4 - clippedWidth*4 to the next row's clipLeft. */
    movl %ebx, %eax
    subl %ebp, %eax                   /* clipped pixel count */
    shll $2, %eax                     /* clipped span in bytes */
    movq %r15, %r8                    /* width * 4 */
    subq %rax, %r8                    /* row advance after clipped span */
    addq %r8, %rdi
    addq %r8, %rsi
    addq %r8, %rdx
    decl 12(%rsp)
    jnz .Lrow
    jmp .Ldone

.Ldone:
    addq $32, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    retq

.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.L255Vec:
    .long 0x437f0000, 0x437f0000, 0x437f0000, 0x437f0000
.p2align 4
.Lhalf:
    .long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
.p2align 4
.LshuffleB:
    .byte 0,4,8,12,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.LshuffleG:
    .byte 1,5,9,13,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.LshuffleR:
    .byte 2,6,10,14,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.LshuffleA:
    .byte 3,7,11,15,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.Ls2lExpand4Even:
    .byte 0,0x80,1,0x80,2,0x80,3,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.LdwordExpand4Even:
    .byte 0,0x80,4,0x80,8,0x80,12,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.LcompactEven4:
    .byte 0,2,4,6,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.LbyteMask:
    .long 0x000000ff, 0x000000ff, 0x000000ff, 0x000000ff
.p2align 4
.Lcompact4Mask:
    .byte 0,4,8,12,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.Ls2lCompact4Mask:
    .byte 0,2,4,6,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LnibbleMask:
    .long 0x0000000f, 0x0000000f, 0x0000000f, 0x0000000f
.p2align 4
.LnibbleBytes:
    .long 0x0f0f0f0f, 0x0f0f0f0f, 0x0f0f0f0f, 0x0f0f0f0f
.p2align 4
.LpackedMask:
    .long 0xffffffff, 0x00000000, 0x00000000, 0x00000000
.p2align 4
.Ls2lRounding:
    .short 16,16,16,16,16,16,16,16
.p2align 4
.L_exact_low16:
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.L_base_lut:
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
.L_slope_lut:
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
.L_rounding:
    .short 16,16,16,16,16,16,16,16
.L_const32:
    .rept 16
    .byte 32
    .endr
.L_nibble_mask:
    .rept 16
    .byte 15
    .endr
.L_hi7:
    .rept 16
    .byte 7
    .endr
.L_one_byte:
    .rept 16
    .byte 1
    .endr
.L_group_mask:
    .rept 16
    .byte 31
    .endr
.L_low3_mask:
    .rept 16
    .byte 7
    .endr
.L_group16:
    .rept 16
    .byte 16
    .endr
.L_correction_lo:
    .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
.L_correction_hi:
    .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
.L_onehot_lut:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.L_onehot_hi:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.L_corr_lo:
    .byte 14,10,14,0,0,0,0,0,130,32,0,0,18,18,114,50
.L_corr_xor:
    .byte 166,14,174,4,161,4,0,128,130,160,0,0,82,18,50,50
.p2align 4
.Ls2lExactLow16:
    .byte 0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1
.Ls2lBase:
    .byte 0,2,4,8,13,21,30,41,55,71,90,111,135,161,190,222
.Ls2lSlope:
    .byte 3,2,7,10,14,18,23,28,31,37,41,46,51,58,63,70
.Ls2lConst32:
    .rept 16
    .byte 32
    .endr
.Ls2lNibbleMask:
    .rept 16
    .byte 15
    .endr
.Ls2lHi7:
    .rept 16
    .byte 7
    .endr
.Ls2lOneByte:
    .rept 16
    .byte 1
    .endr
.Ls2lOneHotHi:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.Ls2lSubLo:
    .byte 34,98,8,44,68,104,9,36,110,42,32,64,228,0,0,0
.Ls2lSubHi:
    .byte 16,16,36,20,8,16,60,32,184,4,2,16,0,32,0,0
SIZE(SYM(ksvgArithmeticApplySse))
