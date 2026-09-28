/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/*
 * x86-64 SSSE3 implementation of ColorMatrix (4x5 matrix, SVG 0..1 semantics).
 * Bit-exact twin of KotlinKernels.colorMatrix: same FP op order (vector
 * `divps` by 255.0 is correctly rounded like scalar `/ 255.f`,
 * left-to-right row evaluation, no FMA), same LUT folding, same clamp255
 * (maxps/minps, +0.5, truncate via `cvttps2dq` — NEVER `cvtps2dq`, which
 * rounds to nearest-even). Alpha never linearized.
 *
 * 4px blocks, exact 16B loads/stores (load only what the block consumes;
 * odd widths go through the scalar tail).
 *
 * Non-linear block: pshufb-extract B/G/R/A bytes to low dwords, widen
 * (punpcklbw/lwd, cvtdq2ps, divps), 4 matrix rows, x255, clamp, +0.5,
 * truncate, packssdw/packuswb, punpcklbw/lwd pack, movdqu store.
 *
 * Linear path: the 256-byte tables are ARBITRARY (caller-supplied
 * srgbToLinear/linearToSrgb pointers, possibly unaligned), so no baked
 * segment approximation: a 16-chunk pshufb scan over the packed bytes, in
 * place (16 movdqu loads shared by all channels + 16 compare/blend
 * iterations), alpha blended back untouched. Encode mirrors it on the
 * packed narrowed bytes.
 *
 * x86 xmm registers do not alias each other, but a narrowed channel still
 * destroys its own float quad — and the G/B/A rows still need the R/G/B
 * floats. So R/G/B narrow into scratch (xmm7/xmm8/xmm9, all dead after the
 * rows); only the last row (A) narrows in place. Same trap as the ARMv7
 * B5 bug, different mechanism.
 *
 * Register map, vector blocks:
 *   xmm0  raw / packed / scan index
 *   xmm1  B floats (narrowed B in place)
 *   xmm2  G floats (narrowed G in place; encode-scan acc)
 *   xmm3  R floats (narrowed R in place)
 *   xmm4  A floats (narrowed A in place)
 *   xmm5  row accumulator / scan chunk
 *   xmm6  broadcast coeff / scan select
 *   xmm7  pack scratch / scalar-tail zero
 *   xmm8  scan lo nibbles
 *   xmm9  scan hi nibbles
 *   xmm10 saved alpha (linear decode)
 *   xmm14 255.0 broadcast, xmm15 zero (persistent)
 *   r10   matrix base (MATRIX), r11 scan chunk offset / tail pixel acc,
 *   r12/r13 src/dst cursors, r14d row stride, r15 scan table base.
 * Masks, 0.5 and hi-compare vectors come from (%rip) memory operands.
 */

#include "asm_macros.S"

/*
 * One 4-lane matrix row: acc = m0*R + m1*G + m2*B + m3*A + m4.
 * R=xmm3 G=xmm2 B=xmm1 A=xmm4, acc=xmm5, coeffs from [MATRIX + off].
 * Left-to-right order matches the reference exactly; no FMA.
 * Clobbers xmm5, xmm6. MATRIX is %r10 (defined at the call site).
 */
.macro MATROW4 m0, m1, m2, m3, m4
    movss \m0(%r10), %xmm6
    shufps $0, %xmm6, %xmm6
    mulps %xmm3, %xmm6
    movaps %xmm6, %xmm5
    movss \m1(%r10), %xmm6
    shufps $0, %xmm6, %xmm6
    mulps %xmm2, %xmm6
    addps %xmm6, %xmm5
    movss \m2(%r10), %xmm6
    shufps $0, %xmm6, %xmm6
    mulps %xmm1, %xmm6
    addps %xmm6, %xmm5
    movss \m3(%r10), %xmm6
    shufps $0, %xmm6, %xmm6
    mulps %xmm4, %xmm6
    addps %xmm6, %xmm5
    movss \m4(%r10), %xmm6
    shufps $0, %xmm6, %xmm6
    addps %xmm6, %xmm5
.endm

/*
 * Widen one channel's packed bytes (low dword of CH) to floats/255.
 * Clobbers only CH (xmm14 = 255.0 broadcast, xmm15 = zero, persistent).
 */
.macro WIDEN4 CH
    punpcklbw %xmm15, \CH
    punpcklwd %xmm15, \CH
    cvtdq2ps \CH, \CH
    divps %xmm14, \CH
.endm

/*
 * Scale row acc (xmm5) by 255, clamp to [0,255], round half-up, narrow to
 * the low dword of DST. Matches clamp255(). Clobbers xmm5.
 */
.macro NARROW4 DST
    mulps %xmm14, %xmm5
    maxps %xmm15, %xmm5
    minps %xmm14, %xmm5
    addps .LhalfVec(%rip), %xmm5
    cvttps2dq %xmm5, %xmm5
    packssdw %xmm15, %xmm5
    packuswb %xmm15, %xmm5
    movdqa %xmm5, \DST
.endm

/*
 * One scalar tail channel row: acc = m0*R + m1*G + m2*B + m3*A + m4.
 * Inputs B=xmm1 G=xmm2 R=xmm3 A=xmm4 (lane 0). Result ORed into %r11d at
 * bit SHIFT. xmm7 must be zero (caller zeroes it once per pixel... per
 * tail loop is fine, it is never written elsewhere in the tail).
 * ENC=1: encode R/G/B through the table at (%r15) (A stays raw).
 * Pass bare numbers for SHIFT (see RENDERING_FILTERING.md §4.2).
 */
.macro TAILROW o0, o1, o2, o3, o4, shift, enc
    movss \o0(%r10), %xmm5
    mulss %xmm3, %xmm5
    movss \o1(%r10), %xmm6
    mulss %xmm2, %xmm6
    addss %xmm6, %xmm5
    movss \o2(%r10), %xmm6
    mulss %xmm1, %xmm6
    addss %xmm6, %xmm5
    movss \o3(%r10), %xmm6
    mulss %xmm4, %xmm6
    addss %xmm6, %xmm5
    movss \o4(%r10), %xmm6
    addss %xmm6, %xmm5
    mulss .L255(%rip), %xmm5
    maxss %xmm7, %xmm5
    minss .L255(%rip), %xmm5
    addss .Lhalf(%rip), %xmm5
    cvttss2si %xmm5, %eax
    .if \enc
    movzbl (%r15, %rax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $\shift, %eax
    orl %eax, %r11d
.endm

.macro TAILROWS
    xorl %r11d, %r11d
    TAILROW 0, 4, 8, 12, 16, 16, 0
    TAILROW 20, 24, 28, 32, 36, 8, 0
    TAILROW 40, 44, 48, 52, 56, 0, 0
    TAILROW 60, 64, 68, 72, 76, 24, 0
    movl %r11d, (%r13)
.endm

.macro TAILROWSENC
    xorl %r11d, %r11d
    TAILROW 0, 4, 8, 12, 16, 16, 1
    TAILROW 20, 24, 28, 32, 36, 8, 1
    TAILROW 40, 44, 48, 52, 56, 0, 1
    TAILROW 60, 64, 68, 72, 76, 24, 0
    movl %r11d, (%r13)
.endm

.text
.p2align 5
/*
 * void applyColorMatrixSsse3(
 *     const jint* src, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     const jfloat* matrix, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * x86-64 System V ABI:
 *   rdi = src, rsi = dst, edx = width, ecx = clipLeft,
 *   r8d = clipTop, r9d = clipRight
 *   stack: clipBottom, matrix, useLinear, srgbToLinear, linearToSrgb
 */
.globl SYM(applyColorMatrixSsse3)
TYPE(SYM(applyColorMatrixSsse3), @function)
SYM(applyColorMatrixSsse3):
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $64, %rsp
    /* 6 pushes = 48 bytes; rsp is orig-112. Stack args:
       clipBottom @120, matrix @128, useLinear @136,
       srgbToLinear @144, linearToSrgb @152. Scratch 0..63. */

    movq %rdi, %r12                  /* src base */
    movq %rsi, %r13                  /* dst base */
    movl %edx, %r14d                 /* width */
    movl %ecx, %ebp                  /* clipLeft */
    movl %r9d, %ebx                  /* clipRight */
    movl %r8d, %r11d                 /* clipTop */

    /* rows = clipBottom - clipTop; empty clip: nothing to do. */
    movl 120(%rsp), %eax
    subl %r11d, %eax
    jle .Ldone
    movl %eax, 0(%rsp)               /* persistent rows left */

    movq 128(%rsp), %r10             /* matrix base */

    movaps .L255Vec(%rip), %xmm14    /* 255.0 broadcast */
    pxor %xmm15, %xmm15              /* zero */

    /* First row starts at clipTop * width + clipLeft. */
    movl %r11d, %eax
    imull %r14d, %eax
    addl %ebp, %eax
    movslq %eax, %rax
    leaq (%r12, %rax, 4), %r12
    leaq (%r13, %rax, 4), %r13
    leal (%r14, %r14), %eax
    leal (%rax, %rax), %r14d         /* row stride = width * 4 */

    movl 136(%rsp), %eax             /* useLinear (jboolean: test low byte) */
    testb %al, %al
    jnz .Llinear_rows

/* ------------------------------------------------------------------ */
/* Non-linear rows.                                                    */
/* ------------------------------------------------------------------ */
.Lnonlin_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx                  /* count = clipRight - clipLeft */
    movl %ecx, %r9d
    shrl $2, %r9d                    /* blocks */
    andl $3, %ecx
    movl %ecx, 8(%rsp)               /* tail pixels */

    testl %r9d, %r9d
    jz .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    movdqu (%r12), %xmm0
    movdqa %xmm0, %xmm1
    pshufb .LshuffleB(%rip), %xmm1
    WIDEN4 %xmm1
    movdqa %xmm0, %xmm2
    pshufb .LshuffleG(%rip), %xmm2
    WIDEN4 %xmm2
    movdqa %xmm0, %xmm3
    pshufb .LshuffleR(%rip), %xmm3
    WIDEN4 %xmm3
    pshufb .LshuffleA(%rip), %xmm0
    WIDEN4 %xmm0
    movdqa %xmm0, %xmm4              /* A floats */

    MATROW4 0, 4, 8, 12, 16
    NARROW4 %xmm7
    MATROW4 20, 24, 28, 32, 36
    NARROW4 %xmm8
    MATROW4 40, 44, 48, 52, 56
    NARROW4 %xmm9
    MATROW4 60, 64, 68, 72, 76
    NARROW4 %xmm4

    /* Pack B(xmm9),G(xmm8),R(xmm7),A(xmm4) low dwords -> [B,G,R,A] bytes. */
    movdqa %xmm9, %xmm0
    punpcklbw %xmm8, %xmm0
    movdqa %xmm7, %xmm1
    punpcklbw %xmm4, %xmm1
    punpcklwd %xmm1, %xmm0
    movdqu %xmm0, (%r13)

    addq $16, %r12
    addq $16, %r13
    subl $1, %r9d
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lnonlin_next
    pxor %xmm7, %xmm7                /* TAILROW clamp-zero */

.Lnonlin_tail_loop:
    movl (%r12), %eax
    /* B */
    movl %eax, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm1
    divss .L255(%rip), %xmm1
    /* G */
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm2
    divss .L255(%rip), %xmm2
    /* R */
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm3
    divss .L255(%rip), %xmm3
    /* A */
    shrl $24, %eax
    cvtsi2ss %eax, %xmm4
    divss .L255(%rip), %xmm4

    TAILROWS

    addq $4, %r12
    addq $4, %r13
    decl %ecx
    jnz .Lnonlin_tail_loop

.Lnonlin_next:
    movl %ebx, %eax
    subl %ebp, %eax
    salq $2, %rax
    addq %r14, %r12
    subq %rax, %r12
    addq %r14, %r13
    subq %rax, %r13
    decl 0(%rsp)
    jnz .Lnonlin_rows
    jmp .Ldone

/* ------------------------------------------------------------------ */
/* Linear rows: LUT decode/encode around the same vector core.         */
/* The 16-chunk pshufb scan works on packed bytes in place; alpha is   */
/* blended back untouched on decode and re-spread on encode.           */
/* ------------------------------------------------------------------ */
.Llinear_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx
    movl %ecx, %r9d
    shrl $2, %r9d
    andl $3, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Llinear_tail

.p2align 4
.Llinear_block:
    movdqu (%r12), %xmm0
    /* Save alpha; split indices into nibbles. */
    movdqa %xmm0, %xmm10
    pand .LalphaMask(%rip), %xmm10
    movdqa %xmm0, %xmm8
    pand .LnibbleMask(%rip), %xmm8
    movdqa %xmm0, %xmm9
    psrlw $4, %xmm9
    pand .LnibbleMask(%rip), %xmm9
    /* 16-chunk scan over srgbToLinear. */
    movq 144(%rsp), %r15
    pxor %xmm1, %xmm1
    xorl %r11d, %r11d
    leaq .LhiTab(%rip), %rax
.Ldec_loop:
    movdqu (%r15, %r11, 1), %xmm5
    pshufb %xmm8, %xmm5
    movdqa (%rax, %r11, 1), %xmm6
    pcmpeqb %xmm9, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm1
    addq $16, %r11
    cmpq $256, %r11
    jne .Ldec_loop
    /* Linearized bytes in place; alpha was never transformed. */
    movdqa %xmm1, %xmm0
    pand .LrgbMask(%rip), %xmm0
    por %xmm10, %xmm0

    movdqa %xmm0, %xmm1
    pshufb .LshuffleB(%rip), %xmm1
    WIDEN4 %xmm1
    movdqa %xmm0, %xmm2
    pshufb .LshuffleG(%rip), %xmm2
    WIDEN4 %xmm2
    movdqa %xmm0, %xmm3
    pshufb .LshuffleR(%rip), %xmm3
    WIDEN4 %xmm3
    pshufb .LshuffleA(%rip), %xmm0
    WIDEN4 %xmm0
    movdqa %xmm0, %xmm4

    MATROW4 0, 4, 8, 12, 16
    NARROW4 %xmm7
    MATROW4 20, 24, 28, 32, 36
    NARROW4 %xmm8
    MATROW4 40, 44, 48, 52, 56
    NARROW4 %xmm9
    MATROW4 60, 64, 68, 72, 76
    NARROW4 %xmm4

    /* Pack narrowed bytes, then encode R/G/B in place. */
    movdqa %xmm9, %xmm0
    punpcklbw %xmm8, %xmm0
    movdqa %xmm7, %xmm1
    punpcklbw %xmm4, %xmm1
    punpcklwd %xmm1, %xmm0
    /* Spread narrowed A to alpha positions (xmm4 low dword survives). */
    movdqa %xmm4, %xmm7
    pshufb .LspreadA(%rip), %xmm7
    movdqa %xmm0, %xmm8
    pand .LnibbleMask(%rip), %xmm8
    movdqa %xmm0, %xmm9
    psrlw $4, %xmm9
    pand .LnibbleMask(%rip), %xmm9
    movq 152(%rsp), %r15
    pxor %xmm2, %xmm2                /* acc (narrowed G is dead) */
    xorl %r11d, %r11d
.Lenc_loop:
    movdqu (%r15, %r11, 1), %xmm5
    pshufb %xmm8, %xmm5
    movdqa (%rax, %r11, 1), %xmm6
    pcmpeqb %xmm9, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm2
    addq $16, %r11
    cmpq $256, %r11
    jne .Lenc_loop
    movdqa %xmm2, %xmm0
    pand .LrgbMask(%rip), %xmm0
    por %xmm7, %xmm0
    movdqu %xmm0, (%r13)

    addq $16, %r12
    addq $16, %r13
    subl $1, %r9d
    jnz .Llinear_block

.Llinear_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Llinear_next
    pxor %xmm7, %xmm7
    movq 152(%rsp), %r15             /* encode table for TAILROWSENC */

.Llinear_tail_loop:
    movq 144(%rsp), %rax             /* srgbToLinear */
    movl (%r12), %edx
    movl %edx, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm1
    divss .L255(%rip), %xmm1
    movl %edx, %esi
    shrl $8, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm2
    divss .L255(%rip), %xmm2
    movl %edx, %esi
    shrl $16, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm3
    divss .L255(%rip), %xmm3
    shrl $24, %edx
    cvtsi2ss %edx, %xmm4
    divss .L255(%rip), %xmm4

    TAILROWSENC

    addq $4, %r12
    addq $4, %r13
    decl %ecx
    jnz .Llinear_tail_loop

.Llinear_next:
    movl %ebx, %eax
    subl %ebp, %eax
    salq $2, %rax
    addq %r14, %r12
    subq %rax, %r12
    addq %r14, %r13
    subq %rax, %r13
    decl 0(%rsp)
    jnz .Llinear_rows
    jmp .Ldone

.Ldone:
    addq $64, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

SIZE(SYM(applyColorMatrixSsse3))

RODATA
.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.L255Vec:
    .long 0x437f0000, 0x437f0000, 0x437f0000, 0x437f0000
.p2align 4
.Lhalf:
    .long 0x3f000000
.p2align 4
.LhalfVec:
    .long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
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
.LspreadA:
    .byte 0x80,0x80,0x80,0,0x80,0x80,0x80,1,0x80,0x80,0x80,2,0x80,0x80,0x80,3
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
