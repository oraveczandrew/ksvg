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
 * i386 SSSE3 implementation of ColorMatrix (4x5 matrix, SVG 0..1 semantics).
 * 4-wide twin of color_matrix_x86_64_ssse3.S: same algorithm, same
 * bit-exact guarantees (correctly-rounded `divps`, left-to-right rows, no
 * FMA, `cvttps2dq` truncate, alpha never linearized).
 *
 * Differences from the x86-64 twin, all forced by the 32-bit target:
 * - i386 SysV ABI: every argument arrives on the stack (offsets counted
 *   from scratch; see the prologue comment).
 * - PIC (docs/RENDERING_FILTERING.md §4.1): %ebp is the PC anchor
 *   (`call 1f; popl`), constants via `(.Llabel-1b)(%ebp)` — no R_386_32
 *   relocations, no TEXTREL. Verify with llvm-readelf after building.
 * - The frame keeps %esp 16-aligned (sub $156) so the spill slots are
 *   16-aligned for movdqa/mulps memory operands (#GP otherwise).
 * - Only 8 xmm registers: widened channel floats spill to stack slots
 *   (B/G/R/A), and R/G/B narrow into spill slots (N0/N1/N2) — only the
 *   last row (A) narrows in place. Same anti-aliasing rule as the 64-bit
 *   twins (later rows still read those float quads).
 * - SSSE3 only (no SSE4 `pblendvb`/`ptest`): masks via pand/por.
 *
 * Stack scratch (after prologue: 4 pushes + call/popl + sub $156):
 *   0 rows left, 4 tail count, 8 row stride, 12 clipLeft, 16 clipRight,
 *   20 pixel acc (tail) / 24 blocks (vector) or encode-table base (tail),
 *   28 pixel spill (linear tail: %ecx is the loop counter),
 *   32/48/64/80 widened B/G/R/A floats, 96/112/128 narrowed R/G/B bytes.
 * Stack args: src @176, dst @180, width @184, clipLeft @188, clipTop @192,
 *   clipRight @196, clipBottom @200, matrix @204, useLinear @208,
 *   srgbToLinear @212, linearToSrgb @216.
 *
 * Register map: %esi/%edi src/dst cursors, %ebx matrix base,
 * %eax/%ecx/%edx scratch, %ebp PIC anchor (restored on exit).
 */

#include "asm_macros.S"

/*
 * One 4-lane matrix row: acc = m0*R + m1*G + m2*B + m3*A + m4.
 * Channel floats come from spill slots: R=64 G=48 B=32 A=80, acc=xmm0.
 * Coeffs from [%ebx]. Left-to-right, no FMA. Clobbers xmm0, xmm5.
 */
.macro MATROW4 m0, m1, m2, m3, m4
    movss \m0(%ebx), %xmm5
    shufps $0, %xmm5, %xmm5
    mulps 64(%esp), %xmm5
    movaps %xmm5, %xmm0
    movss \m1(%ebx), %xmm5
    shufps $0, %xmm5, %xmm5
    mulps 48(%esp), %xmm5
    addps %xmm5, %xmm0
    movss \m2(%ebx), %xmm5
    shufps $0, %xmm5, %xmm5
    mulps 32(%esp), %xmm5
    addps %xmm5, %xmm0
    movss \m3(%ebx), %xmm5
    shufps $0, %xmm5, %xmm5
    mulps 80(%esp), %xmm5
    addps %xmm5, %xmm0
    movss \m4(%ebx), %xmm5
    shufps $0, %xmm5, %xmm5
    addps %xmm5, %xmm0
.endm

/*
 * Narrow row acc (xmm0) like NARROW4, then spill the packed bytes to MEM
 * (a 16-byte stack slot; only the low dword is live). Clobbers xmm0.
 */
.macro NARROW4M MEM
    mulps (.L255Vec-1b)(%ebp), %xmm0
    maxps (.Lzero-1b)(%ebp), %xmm0
    minps (.L255Vec-1b)(%ebp), %xmm0
    addps (.LhalfVec-1b)(%ebp), %xmm0
    cvttps2dq %xmm0, %xmm0
    packssdw (.Lzero-1b)(%ebp), %xmm0
    packuswb (.Lzero-1b)(%ebp), %xmm0
    movdqa %xmm0, \MEM
.endm

/*
 * One scalar tail channel row, ORed into the pixel acc at 20(%esp).
 * Inputs B=xmm1 G=xmm2 R=xmm3 A=xmm4 (lane 0). MATRIX is %ebx, xmm7 is
 * the clamp-zero (caller zeroes it). ENC=1: encode R/G/B through the
 * table whose base the caller stashed at 24(%esp) (A stays raw).
 * SHIFT is a bare number (see docs/RENDERING_FILTERING.md §4.2).
 */
.macro TAILROW o0, o1, o2, o3, o4, shift, enc
    movss \o0(%ebx), %xmm5
    mulss %xmm3, %xmm5
    movss \o1(%ebx), %xmm6
    mulss %xmm2, %xmm6
    addss %xmm6, %xmm5
    movss \o2(%ebx), %xmm6
    mulss %xmm1, %xmm6
    addss %xmm6, %xmm5
    movss \o3(%ebx), %xmm6
    mulss %xmm4, %xmm6
    addss %xmm6, %xmm5
    movss \o4(%ebx), %xmm6
    addss %xmm6, %xmm5
    mulss (.L255-1b)(%ebp), %xmm5
    maxss %xmm7, %xmm5
    minss (.L255-1b)(%ebp), %xmm5
    addss (.Lhalf-1b)(%ebp), %xmm5
    cvttss2si %xmm5, %eax
    .if \enc
    movl 24(%esp), %edx
    movzbl (%edx, %eax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $\shift, %eax
    orl %eax, 20(%esp)
.endm

.macro TAILROWS
    movl $0, 20(%esp)
    TAILROW 0, 4, 8, 12, 16, 16, 0
    TAILROW 20, 24, 28, 32, 36, 8, 0
    TAILROW 40, 44, 48, 52, 56, 0, 0
    TAILROW 60, 64, 68, 72, 76, 24, 0
    movl 20(%esp), %eax
    movl %eax, (%edi)
.endm

.macro TAILROWSENC
    movl $0, 20(%esp)
    TAILROW 0, 4, 8, 12, 16, 16, 1
    TAILROW 20, 24, 28, 32, 36, 8, 1
    TAILROW 40, 44, 48, 52, 56, 0, 1
    TAILROW 60, 64, 68, 72, 76, 24, 0
    movl 20(%esp), %eax
    movl %eax, (%edi)
.endm

.text
.p2align 5
/*
 * void applyColorMatrixSsse3x86(
 *     const jint* src, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     const jfloat* matrix, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * i386 SysV ABI: all arguments on the stack (see header comment).
 * Callee-saved: %ebp (also the PIC anchor), %ebx, %esi, %edi.
 */
.globl SYM(applyColorMatrixSsse3x86)
TYPE(SYM(applyColorMatrixSsse3x86), @function)
SYM(applyColorMatrixSsse3x86):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    call 1f
1:  popl %ebp
    subl $156, %esp

    movl 176(%esp), %esi              /* src base */
    movl 180(%esp), %edi             /* dst base */
    movl 188(%esp), %eax
    movl %eax, 12(%esp)              /* clipLeft */
    movl 196(%esp), %eax
    movl %eax, 16(%esp)              /* clipRight */
    movl 200(%esp), %eax
    subl 192(%esp), %eax             /* rows = clipBottom - clipTop */
    jle .Ldone
    movl %eax, 0(%esp)
    movl 204(%esp), %ebx             /* matrix base */

    /* First row starts at clipTop * width + clipLeft. */
    movl 192(%esp), %eax
    imull 184(%esp), %eax
    addl 12(%esp), %eax
    leal (%esi, %eax, 4), %esi
    leal (%edi, %eax, 4), %edi
    movl 184(%esp), %eax
    sall $2, %eax                    /* stride = width * 4 */
    movl %eax, 8(%esp)

    movl 208(%esp), %eax             /* useLinear (test low byte) */
    testb %al, %al
    jnz .Llinear_rows

/* ------------------------------------------------------------------ */
/* Non-linear rows.                                                    */
/* ------------------------------------------------------------------ */
.Lnonlin_rows:
    movl 16(%esp), %ecx
    subl 12(%esp), %ecx              /* count */
    movl %ecx, %eax
    shrl $2, %eax
    movl %eax, 24(%esp)              /* blocks */
    andl $3, %ecx
    movl %ecx, 4(%esp)               /* tail */

    cmpl $0, 24(%esp)
    je .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    movdqu (%esi), %xmm0
    /* Widen B/G/R/A to spill slots (xmm1 chan, xmm2 zero, xmm3 255). */
    pxor %xmm2, %xmm2
    movdqa (.L255Vec-1b)(%ebp), %xmm3
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleB-1b)(%ebp), %xmm1
    punpcklbw %xmm2, %xmm1
    punpcklwd %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    divps %xmm3, %xmm1
    movdqa %xmm1, 32(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleG-1b)(%ebp), %xmm1
    punpcklbw %xmm2, %xmm1
    punpcklwd %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    divps %xmm3, %xmm1
    movdqa %xmm1, 48(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleR-1b)(%ebp), %xmm1
    punpcklbw %xmm2, %xmm1
    punpcklwd %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    divps %xmm3, %xmm1
    movdqa %xmm1, 64(%esp)
    pshufb (.LshuffleA-1b)(%ebp), %xmm0
    punpcklbw %xmm2, %xmm0
    punpcklwd %xmm2, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps %xmm3, %xmm0
    movdqa %xmm0, 80(%esp)

    MATROW4 0, 4, 8, 12, 16
    NARROW4M 96(%esp)
    MATROW4 20, 24, 28, 32, 36
    NARROW4M 112(%esp)
    MATROW4 40, 44, 48, 52, 56
    NARROW4M 128(%esp)
    MATROW4 60, 64, 68, 72, 76
    /* A row narrows in place (xmm0 dead after: last row). */
    mulps (.L255Vec-1b)(%ebp), %xmm0
    maxps (.Lzero-1b)(%ebp), %xmm0
    minps (.L255Vec-1b)(%ebp), %xmm0
    addps (.LhalfVec-1b)(%ebp), %xmm0
    cvttps2dq %xmm0, %xmm0
    packssdw (.Lzero-1b)(%ebp), %xmm0
    packuswb (.Lzero-1b)(%ebp), %xmm0

    /* Pack N2=B N1=G N0=R A=xmm0 -> [B,G,R,A], store 16 exact bytes. */
    movdqa 128(%esp), %xmm1
    punpcklbw 112(%esp), %xmm1
    movdqa 96(%esp), %xmm2
    punpcklbw %xmm0, %xmm2
    punpcklwd %xmm2, %xmm1
    movdqu %xmm1, (%edi)

    addl $16, %esi
    addl $16, %edi
    decl 24(%esp)
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 4(%esp), %ecx
    testl %ecx, %ecx
    jz .Lnonlin_next
    pxor %xmm7, %xmm7

.Lnonlin_tail_loop:
    movl (%esi), %eax
    movl %eax, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm1
    divss (.L255-1b)(%ebp), %xmm1
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm2
    divss (.L255-1b)(%ebp), %xmm2
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm3
    divss (.L255-1b)(%ebp), %xmm3
    shrl $24, %eax
    cvtsi2ss %eax, %xmm4
    divss (.L255-1b)(%ebp), %xmm4

    TAILROWS

    addl $4, %esi
    addl $4, %edi
    decl %ecx
    jnz .Lnonlin_tail_loop

.Lnonlin_next:
    movl 16(%esp), %eax
    subl 12(%esp), %eax
    sall $2, %eax                    /* count * 4 */
    addl 8(%esp), %esi
    subl %eax, %esi
    addl 8(%esp), %edi
    subl %eax, %edi
    decl 0(%esp)
    jnz .Lnonlin_rows
    jmp .Ldone

/* ------------------------------------------------------------------ */
/* Linear rows.                                                        */
/* ------------------------------------------------------------------ */
.Llinear_rows:
    movl 16(%esp), %ecx
    subl 12(%esp), %ecx
    movl %ecx, %eax
    shrl $2, %eax
    movl %eax, 24(%esp)
    andl $3, %ecx
    movl %ecx, 4(%esp)

    cmpl $0, 24(%esp)
    je .Llinear_tail

.p2align 4
.Llinear_block:
    movdqu (%esi), %xmm0
    movdqa %xmm0, %xmm1
    pand (.LalphaMask-1b)(%ebp), %xmm1  /* saved alpha */
    movdqa %xmm0, %xmm2
    pand (.LnibbleMask-1b)(%ebp), %xmm2 /* lo */
    movdqa %xmm0, %xmm3
    psrlw $4, %xmm3
    pand (.LnibbleMask-1b)(%ebp), %xmm3 /* hi */
    movl 212(%esp), %edx             /* srgbToLinear */
    pxor %xmm4, %xmm4                /* acc */
    xorl %eax, %eax
    leal (.LhiTab-1b)(%ebp), %ecx
.Ldec_loop:
    movdqu (%edx, %eax, 1), %xmm5
    pshufb %xmm2, %xmm5
    movdqa (%ecx, %eax, 1), %xmm6
    pcmpeqb %xmm3, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm4
    addl $16, %eax
    cmpl $256, %eax
    jne .Ldec_loop
    movdqa %xmm4, %xmm0
    pand (.LrgbMask-1b)(%ebp), %xmm0
    por %xmm1, %xmm0

    /* Widen to spill slots (same shape as non-linear). */
    pxor %xmm2, %xmm2
    movdqa (.L255Vec-1b)(%ebp), %xmm3
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleB-1b)(%ebp), %xmm1
    punpcklbw %xmm2, %xmm1
    punpcklwd %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    divps %xmm3, %xmm1
    movdqa %xmm1, 32(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleG-1b)(%ebp), %xmm1
    punpcklbw %xmm2, %xmm1
    punpcklwd %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    divps %xmm3, %xmm1
    movdqa %xmm1, 48(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleR-1b)(%ebp), %xmm1
    punpcklbw %xmm2, %xmm1
    punpcklwd %xmm2, %xmm1
    cvtdq2ps %xmm1, %xmm1
    divps %xmm3, %xmm1
    movdqa %xmm1, 64(%esp)
    pshufb (.LshuffleA-1b)(%ebp), %xmm0
    punpcklbw %xmm2, %xmm0
    punpcklwd %xmm2, %xmm0
    cvtdq2ps %xmm0, %xmm0
    divps %xmm3, %xmm0
    movdqa %xmm0, 80(%esp)

    MATROW4 0, 4, 8, 12, 16
    NARROW4M 96(%esp)
    MATROW4 20, 24, 28, 32, 36
    NARROW4M 112(%esp)
    MATROW4 40, 44, 48, 52, 56
    NARROW4M 128(%esp)
    MATROW4 60, 64, 68, 72, 76
    mulps (.L255Vec-1b)(%ebp), %xmm0
    maxps (.Lzero-1b)(%ebp), %xmm0
    minps (.L255Vec-1b)(%ebp), %xmm0
    addps (.LhalfVec-1b)(%ebp), %xmm0
    cvttps2dq %xmm0, %xmm0
    packssdw (.Lzero-1b)(%ebp), %xmm0
    packuswb (.Lzero-1b)(%ebp), %xmm0

    /* Pack, spread A, encode R/G/B in place, blend, store. */
    movdqa 128(%esp), %xmm1
    punpcklbw 112(%esp), %xmm1
    movdqa 96(%esp), %xmm2
    punpcklbw %xmm0, %xmm2
    punpcklwd %xmm2, %xmm1
    movdqa %xmm0, %xmm3
    pshufb (.LspreadA-1b)(%ebp), %xmm3
    movdqa %xmm1, %xmm4
    pand (.LnibbleMask-1b)(%ebp), %xmm4
    movdqa %xmm1, %xmm5
    psrlw $4, %xmm5
    pand (.LnibbleMask-1b)(%ebp), %xmm5
    movl 216(%esp), %edx             /* linearToSrgb */
    pxor %xmm6, %xmm6                /* acc */
    xorl %eax, %eax
.Lenc_loop:
    movdqu (%edx, %eax, 1), %xmm0
    pshufb %xmm4, %xmm0
    movdqa (%ecx, %eax, 1), %xmm2
    pcmpeqb %xmm5, %xmm2
    pand %xmm2, %xmm0
    por %xmm0, %xmm6
    addl $16, %eax
    cmpl $256, %eax
    jne .Lenc_loop
    movdqa %xmm6, %xmm1
    pand (.LrgbMask-1b)(%ebp), %xmm1
    por %xmm3, %xmm1
    movdqu %xmm1, (%edi)

    addl $16, %esi
    addl $16, %edi
    decl 24(%esp)
    jnz .Llinear_block

.Llinear_tail:
    movl 4(%esp), %ecx
    testl %ecx, %ecx
    jz .Llinear_next
    pxor %xmm7, %xmm7
    movl 216(%esp), %eax
    movl %eax, 24(%esp)              /* encode table for TAILROWSENC */

.Llinear_tail_loop:
    movl (%esi), %edx
    movl %edx, 28(%esp)              /* pixel spill: %ecx is the loop
                                        counter and must survive */
    movl 212(%esp), %eax             /* srgbToLinear */
    andl $0xff, %edx
    movzbl (%eax, %edx), %edx
    cvtsi2ss %edx, %xmm1
    divss (.L255-1b)(%ebp), %xmm1
    movl 28(%esp), %edx
    shrl $8, %edx
    andl $0xff, %edx
    movzbl (%eax, %edx), %edx
    cvtsi2ss %edx, %xmm2
    divss (.L255-1b)(%ebp), %xmm2
    movl 28(%esp), %edx
    shrl $16, %edx
    andl $0xff, %edx
    movzbl (%eax, %edx), %edx
    cvtsi2ss %edx, %xmm3
    divss (.L255-1b)(%ebp), %xmm3
    movl 28(%esp), %edx
    shrl $24, %edx
    cvtsi2ss %edx, %xmm4
    divss (.L255-1b)(%ebp), %xmm4

    TAILROWSENC

    addl $4, %esi
    addl $4, %edi
    decl %ecx
    jnz .Llinear_tail_loop

.Llinear_next:
    movl 16(%esp), %eax
    subl 12(%esp), %eax
    sall $2, %eax
    addl 8(%esp), %esi
    subl %eax, %esi
    addl 8(%esp), %edi
    subl %eax, %edi
    decl 0(%esp)
    jnz .Llinear_rows
    jmp .Ldone

.Ldone:
    addl $156, %esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret

SIZE(SYM(applyColorMatrixSsse3x86))

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
.Lzero:
    .long 0, 0, 0, 0
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
