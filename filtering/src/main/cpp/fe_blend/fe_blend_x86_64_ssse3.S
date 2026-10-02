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
 * x86-64 SSSE3 implementation of feBlend, separable modes (1..11).
 * Near-exact twin of KotlinKernels.feBlend / fe_blend.cpp scalar
 * under the ssse3 maxDelta=1 parity tolerance: same FP op order
 * (left-to-right evaluation, no FMA), same LUT folding, same clamp255
 * (+0.5, truncate via `cvttps2dq`/`cvttss2si` — NEVER nearest-even).
 * Divisions use reciprocals: widening multiplies by a 1/255 constant
 * (exhaustive: 0/256 roundtrip diffs); compositing/dodge/burn divide
 * via one Newton-Raphson step over `rcpps` (no FMA on SSSE3;
 * relative err ~2^-21, i.e., ~1e-4 LSB at narrow — same profile as
 * the shipped arm32 kernel). 0-lanes give +Inf, masked exactly like
 * the div path. Alpha never linearized. Non-separable modes (12..15)
 * never reach this function: the C++ dispatcher routes them to scalar
 * (FEBLEND_PORT_PLAN).
 *
 * 4px blocks, exact 16B loads/stores (load only what the block consumes;
 * odd widths go through the scalar tail). `mode` is constant per call:
 * one jump table selects the per-mode blend fragment per block (and a
 * second table for the scalar tail) — never a branch per pixel. Fragments
 * return through the address in r11 (set to the space-specific return
 * label before dispatch), so the same 11 fragments serve both spaces.
 *
 * Widened channels live in stack slots, not registers: with two input
 * images (src + dst) plus alphas/ao/mask there is no room for a
 * fully-resident map in 16 xmm regs, and spilling through named slots
 * keeps every blend fragment reviewable (loads/stores never affect FP
 * bit-exactness). The per-channel composite runs packed over all 4 lanes
 * into a temp slot, then narrows lane by lane (scalar narrow per lane).
 *
 * Linear path: exact 16-chunk pshufb scan over the REAL 256B tables
 * (ColorMatrix pattern, exact by construction — no baked segment
 * approximation). Both images are decoded (two scans); encode mirrors it
 * on the narrowed bytes.
 *
 * Parity traps handled here (see FEBLEND_PORT_PLAN §3 for the full list):
 * - darken/lighten/overlay/hard-light use compare+select that mirrors the
 *   scalar ternary EXACTLY (never minps/maxps: NaN semantics differ).
 *   Selects are and/pxor/and/or quadruples (SSSE3 has no blendvps, and
 *   andnps(S,D) = ~D&S — mask-first, NOT value-first: the arithmetic
 *   S2L macro (`pandn %xmm5, %xmm3` = ~mask&lo) is the in-tree proof).
 * - color-dodge/burn compute the division on all lanes, so the 0/0 lane
 *   (cb==0 && cs==1, resp. cb==1 && cs==0) is forced explicitly
 *   (edge masks); the scalar guard-branch order decides which mask wins
 *   (dodge: cb==0 -> 0 applied LAST; burn: cb>=1 -> 1 LAST).
 *   Never rely on (int)NaN (C++ UB) for these lanes.
 * - soft-light D(cb) uses single-precision `sqrtps` (double rounding
 *   can differ in the last bit vs kotlin.math.sqrt(Float); covered by
 *   the ssse3 maxDelta=1 tolerance).
 * - aoAlpha <= 0 forces a zero pixel via an (ao > 0) mask ANDed AFTER the
 *   compositing division (div-by-zero lanes produce inf/NaN, which never
 *   fault and are masked away).
 *
 * Stack frame: 6 pushes (48B) + sub $264 (entry rsp%16==8, so the sub
 * must be ==8 mod 16 to keep movaps slot spills aligned).
 * Stack args: clipRight @320, clipBottom @328, mode @336,
 * useLinear @344, srgbToLinear @352, linearToSrgb @360.
 * Scratch slots: rows @0, tail @8,
 *   sr/sg/sb/as @16/32/48/64, br/bg/bb/ab @80/96/112/128,
 *   ao @144, aoMask @160, tR/tG/tB @176/192/208, composite temp @224.
 * Registers: r12/r14/r13 = src/dst/out cursors, r10 = row stride,
 * r15 = LUT base, ebp = clipLeft, ebx = clipRight,
 * xmm14 = 255.0 broadcast, xmm15 = zero (persistent).
 * Masks and FP constants come from (%rip) memory operands.
 */

#include "asm_macros.S"

/*
 * Widen one channel's packed bytes (low dword of CH) to floats/255.
 * Multiplies by a 1/255 constant (exhaustive: 0/256 roundtrip diffs,
 * maxerr 7.4e-08). Clobbers only CH (xmm14 = 255.0 broadcast, xmm15
 * = zero, persistent; xmm14 kept for shape).
 */
.macro WIDEN4 CH
    punpcklbw %xmm15, \CH
    punpcklwd %xmm15, \CH
    cvtdq2ps \CH, \CH
    mulps .Lrecip255Vec(%rip), \CH
.endm

/*
 * Shared packed per-channel compositing, result quad stored back to TSLOT.
 * Scalar equivalent (fe_blend.cpp):
 *   o = ((1-ab)*cs*as + (1-as)*cb*ab + as*ab*t) / ao; ao<=0 -> 0.
 * 1/ao via one Newton-Raphson step (no FMA on SSSE3): relative err
 * ~2^-21, i.e., ~1e-4 LSB at narrow — same profile as the shipped
 * arm32 kernel (device-green). 0-lanes give +Inf, masked exactly like
 * the div path. Clobbers xmm0, xmm1, xmm2, xmm7. Slots: TSLOT/T
 * channel triple, SCSLOT/BCSLOT. (xmm2 is scratch-reloaded throughout
 * the block loops, dead at every call site.)
 */
.macro COMPOSITE tslot, scslot, bcslot
    movaps .LoneVec(%rip), %xmm7
    subps 128(%rsp), %xmm7
    mulps \scslot(%rsp), %xmm7
    mulps 64(%rsp), %xmm7
    movaps .LoneVec(%rip), %xmm1
    subps 64(%rsp), %xmm1
    mulps \bcslot(%rsp), %xmm1
    mulps 128(%rsp), %xmm1
    addps %xmm1, %xmm7
    movaps 64(%rsp), %xmm1
    mulps 128(%rsp), %xmm1
    mulps \tslot(%rsp), %xmm1
    addps %xmm1, %xmm7
    movaps 144(%rsp), %xmm0
    rcpps %xmm0, %xmm1
    mulps %xmm1, %xmm0
    movaps .LtwoVec(%rip), %xmm2
    subps %xmm0, %xmm2
    mulps %xmm2, %xmm1
    mulps %xmm1, %xmm7
    andps 160(%rsp), %xmm7
    movaps %xmm7, \tslot(%rsp)
.endm

/*
 * Narrow + store one output pixel (lane LANE of the R/G/B composite quads
 * in 176/192/208 and of ao in 144) to LANE*4(%r13).
 * Matches clamp255(): *255, clamp [0,255], +0.5, truncate.
 * ENC=1: encode R/G/B through the table at (%r15); alpha is never encoded.
 * Clobbers xmm0, eax, r11d. Pass bare numbers.
 */
.macro STORE_PIXEL lane, enc
    xorl %r11d, %r11d
    movss 176+\lane*4(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movzbl (%r15, %rax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $16, %eax
    orl %eax, %r11d
    movss 192+\lane*4(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movzbl (%r15, %rax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $8, %eax
    orl %eax, %r11d
    movss 208+\lane*4(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movzbl (%r15, %rax, 1), %eax
    .endif
    andl $0xff, %eax
    orl %eax, %r11d
    movss 144+\lane*4(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, %r11d
    movl %r11d, \lane*4(%r13)
.endm

/* Scalar-tail macro, fragments and tail jump table (shared with the
   AVX2/i386 kernels). Included here — before .text — so the macro is
   defined before its uses in the tail returns below. */
#include "fe_blend_scalar_tail.inc"

.text
.p2align 5
/*
 * void applyFeBlendSsse3(
 *     const jint* src, const jint* dst, jint* out,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     jint mode, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * x86-64 System V ABI:
 *   rdi = src, rsi = dst, rdx = out, ecx = width,
 *   r8d = clipLeft, r9d = clipTop
 *   stack: clipRight, clipBottom, mode, useLinear, srgbToLinear, linearToSrgb
 */
.globl SYM(applyFeBlendSsse3)
TYPE(SYM(applyFeBlendSsse3), @function)
SYM(applyFeBlendSsse3):
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $264, %rsp
    /* 6 pushes = 48 bytes; rsp is orig-304. Stack args:
       clipRight @312, clipBottom @320, mode @328, useLinear @336,
       srgbToLinear @344, linearToSrgb @352. Scratch 0..239. */

    movq %rdi, %r12                  /* src cursor */
    movq %rsi, %r14                  /* dst cursor */
    movq %rdx, %r13                  /* out cursor */
    movl %ecx, %r10d                 /* width */
    movl %r8d, %ebp                  /* clipLeft */
    /* First row starts at clipTop * width + clipLeft. */
    movl %r9d, %eax
    imull %r10d, %eax
    addl %ebp, %eax
    movslq %eax, %rax
    leaq (%r12, %rax, 4), %r12
    leaq (%r14, %rax, 4), %r14
    leaq (%r13, %rax, 4), %r13
    /* Row stride = width * 4. */
    movl %r10d, %eax
    addl %eax, %eax
    addl %eax, %eax
    movl %eax, %r10d
    movl 320(%rsp), %ebx             /* clipRight */
    /* rows = clipBottom - clipTop; empty clip: nothing to do. */
    movl 328(%rsp), %eax
    subl %r9d, %eax
    jle .Ldone
    movl %eax, 0(%rsp)               /* persistent rows left */

    movaps .L255Vec(%rip), %xmm14    /* 255.0 broadcast */
    pxor %xmm15, %xmm15              /* zero */

    movl 344(%rsp), %eax             /* useLinear (jboolean: test low byte) */
    testb %al, %al
    jnz .Llinear_rows

/* ------------------------------------------------------------------ */
/* Non-linear rows.                                                    */
/* ------------------------------------------------------------------ */
.Lnonlin_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx                  /* count = clipRight - clipLeft */
    jle .Lrow_next_nonlin            /* empty-width clip: skip the row */
    movl %ecx, %r9d
    shrl $2, %r9d                    /* blocks */
    andl $3, %ecx
    movl %ecx, 8(%rsp)               /* tail pixels */

    testl %r9d, %r9d
    jz .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    /* Widen src -> sr/sg/sb/as slots. */
    movdqu (%r12), %xmm0
    movdqa %xmm0, %xmm1
    pshufb .LshuffleR(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 16(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleG(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 32(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleB(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 48(%rsp)
    pshufb .LshuffleA(%rip), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 64(%rsp)
    /* Widen dst -> br/bg/bb/ab slots. */
    movdqu (%r14), %xmm0
    movdqa %xmm0, %xmm1
    pshufb .LshuffleR(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 80(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleG(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 96(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleB(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 112(%rsp)
    pshufb .LshuffleA(%rip), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 128(%rsp)
    /* ao = (as+ab) - as*ab; mask = (ao > 0) for the andps zero-guard. */
    movaps 64(%rsp), %xmm0
    addps 128(%rsp), %xmm0
    movaps 64(%rsp), %xmm1
    mulps 128(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 144(%rsp)
    movaps %xmm0, %xmm1
    cmpnleps %xmm15, %xmm1
    movaps %xmm1, 160(%rsp)

    /* Per-mode blend -> tR/tG/tB slots; return to .Lblk_ret_nonlin. */
    leaq .Lblk_ret_nonlin(%rip), %r11
    movl 336(%rsp), %ecx
    decl %ecx
    leaq .Lblk_tab(%rip), %rax
    movslq (%rax, %rcx, 4), %rcx
    addq %rax, %rcx
    jmp *%rcx
.Lblk_ret_nonlin:
    /* Composite R/G/B quads, then narrow + store all 4 pixels. */
    COMPOSITE 176, 16, 80
    COMPOSITE 192, 32, 96
    COMPOSITE 208, 48, 112
    STORE_PIXEL 0, 0
    STORE_PIXEL 1, 0
    STORE_PIXEL 2, 0
    STORE_PIXEL 3, 0

    addq $16, %r12
    addq $16, %r14
    addq $16, %r13
    subl $1, %r9d
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lrow_next_nonlin

.Lnonlin_tail_loop:
    /* Scalar widen both pixels, lane 0 -> slots. */
    movl (%r12), %eax
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 16(%rsp)
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 32(%rsp)
    movl %eax, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 48(%rsp)
    shrl $24, %eax
    cvtsi2ss %eax, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 64(%rsp)
    movl (%r14), %eax
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 80(%rsp)
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 96(%rsp)
    movl %eax, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 112(%rsp)
    shrl $24, %eax
    cvtsi2ss %eax, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 128(%rsp)
    /* ao = (as+ab) - as*ab; ao <= 0 -> zero pixel. */
    movss 64(%rsp), %xmm0
    addss 128(%rsp), %xmm0
    movss 64(%rsp), %xmm1
    mulss 128(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 144(%rsp)
    ucomiss %xmm15, %xmm0
    jbe .Ltail_zero_nonlin

    leaq .Ltail_ret_nonlin(%rip), %r11
    movl 336(%rsp), %edx
    decl %edx
    leaq .Ltail_tab(%rip), %rax
    movslq (%rax, %rdx, 4), %rdx
    addq %rax, %rdx
    jmp *%rdx
.Ltail_ret_nonlin:
    xorl %r11d, %r11d
    TAIL_COMPOSITE_NARROW 176, 16, 80, 16, 0
    TAIL_COMPOSITE_NARROW 192, 32, 96, 8, 0
    TAIL_COMPOSITE_NARROW 208, 48, 112, 0, 0
    movss 144(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, %r11d
    movl %r11d, (%r13)
    jmp .Ltail_advance_nonlin
.Ltail_zero_nonlin:
    movl $0, (%r13)
.Ltail_advance_nonlin:
    addq $4, %r12
    addq $4, %r14
    addq $4, %r13
    decl %ecx
    jnz .Lnonlin_tail_loop

.Lrow_next_nonlin:
    movl %ebx, %eax
    subl %ebp, %eax
    salq $2, %rax
    addq %r10, %r12
    subq %rax, %r12
    addq %r10, %r14
    subq %rax, %r14
    addq %r10, %r13
    subq %rax, %r13
    decl 0(%rsp)
    jnz .Lnonlin_rows
    jmp .Ldone

/* ------------------------------------------------------------------ */
/* Linear rows: LUT decode (both images) around the same core.         */
/* ------------------------------------------------------------------ */
.Llinear_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx
    jle .Lrow_next_linear
    movl %ecx, %r9d
    shrl $2, %r9d
    andl $3, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Llinear_tail

.p2align 4
.Llinear_block:
    /* Decode src RGB via srgbToLinear; alpha bypasses the LUT. */
    movdqu (%r12), %xmm0
    movdqa %xmm0, %xmm10
    pand .LalphaMask(%rip), %xmm10
    movdqa %xmm0, %xmm8
    pand .LnibbleMask(%rip), %xmm8
    movdqa %xmm0, %xmm9
    psrlw $4, %xmm9
    pand .LnibbleMask(%rip), %xmm9
    movq 352(%rsp), %r15
    pxor %xmm1, %xmm1
    xorl %ecx, %ecx
    leaq .LhiTab(%rip), %rax
.Ldec_src_loop:
    movdqu (%r15, %rcx, 1), %xmm5
    pshufb %xmm8, %xmm5
    movdqa (%rax, %rcx, 1), %xmm6
    pcmpeqb %xmm9, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm1
    addq $16, %rcx
    cmpq $256, %rcx
    jne .Ldec_src_loop
    movdqa %xmm1, %xmm0
    pand .LrgbMask(%rip), %xmm0
    por %xmm10, %xmm0
    /* Widen decoded src -> slots (2/3/4 survive the dst scan below;
       as is parked in the as slot only after the dst scan). */
    movdqa %xmm0, %xmm1
    pshufb .LshuffleR(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 16(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleG(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 32(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleB(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 48(%rsp)
    movdqa %xmm0, %xmm7
    pshufb .LshuffleA(%rip), %xmm7
    WIDEN4 %xmm7
    movaps %xmm7, 64(%rsp)
    /* Decode dst RGB the same way (scan clobbers 0/1/5/6/8/9/10/11
       only; widened src in 16/32/48/64 slots is safe). */
    movdqu (%r14), %xmm0
    movdqa %xmm0, %xmm10
    pand .LalphaMask(%rip), %xmm10
    movdqa %xmm0, %xmm8
    pand .LnibbleMask(%rip), %xmm8
    movdqa %xmm0, %xmm9
    psrlw $4, %xmm9
    pand .LnibbleMask(%rip), %xmm9
    pxor %xmm1, %xmm1
    xorl %ecx, %ecx
.Ldec_dst_loop:
    movdqu (%r15, %rcx, 1), %xmm5
    pshufb %xmm8, %xmm5
    movdqa (%rax, %rcx, 1), %xmm6
    pcmpeqb %xmm9, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm1
    addq $16, %rcx
    cmpq $256, %rcx
    jne .Ldec_dst_loop
    movdqa %xmm1, %xmm0
    pand .LrgbMask(%rip), %xmm0
    por %xmm10, %xmm0
    movdqa %xmm0, %xmm1
    pshufb .LshuffleR(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 80(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleG(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 96(%rsp)
    movdqa %xmm0, %xmm1
    pshufb .LshuffleB(%rip), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 112(%rsp)
    pshufb .LshuffleA(%rip), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 128(%rsp)
    /* ao + mask. */
    movaps 64(%rsp), %xmm0
    addps 128(%rsp), %xmm0
    movaps 64(%rsp), %xmm1
    mulps 128(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 144(%rsp)
    movaps %xmm0, %xmm1
    cmpnleps %xmm15, %xmm1
    movaps %xmm1, 160(%rsp)

    leaq .Lblk_ret_linear(%rip), %r11
    movl 336(%rsp), %ecx
    decl %ecx
    leaq .Lblk_tab(%rip), %rax
    movslq (%rax, %rcx, 4), %rcx
    addq %rax, %rcx
    jmp *%rcx
.Lblk_ret_linear:
    /* Composite + narrow with encode. */
    movq 360(%rsp), %r15             /* linearToSrgb */
    COMPOSITE 176, 16, 80
    COMPOSITE 192, 32, 96
    COMPOSITE 208, 48, 112
    STORE_PIXEL 0, 1
    STORE_PIXEL 1, 1
    STORE_PIXEL 2, 1
    STORE_PIXEL 3, 1

    addq $16, %r12
    addq $16, %r14
    addq $16, %r13
    subl $1, %r9d
    jnz .Llinear_block

.Llinear_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lrow_next_linear
    movq 360(%rsp), %r15             /* encode table for the tail */

.Llinear_tail_loop:
    movq 352(%rsp), %rax             /* srgbToLinear */
    movl (%r12), %edx
    movl %edx, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 48(%rsp)            /* sb (B first: byte 0) */
    movl %edx, %esi
    shrl $8, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 32(%rsp)            /* sg */
    movl %edx, %esi
    shrl $16, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 16(%rsp)            /* sr */
    shrl $24, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 64(%rsp)            /* as */
    movl (%r14), %edx
    movl %edx, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 112(%rsp)           /* bb */
    movl %edx, %esi
    shrl $8, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 96(%rsp)            /* bg */
    movl %edx, %esi
    shrl $16, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    cvtsi2ss %esi, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 80(%rsp)            /* br */
    shrl $24, %edx
    cvtsi2ss %edx, %xmm0
    divss .L255(%rip), %xmm0
    movss %xmm0, 128(%rsp)           /* ab */
    movss 64(%rsp), %xmm0
    addss 128(%rsp), %xmm0
    movss 64(%rsp), %xmm1
    mulss 128(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 144(%rsp)
    ucomiss %xmm15, %xmm0
    jbe .Ltail_zero_linear

    leaq .Ltail_ret_linear(%rip), %r11
    movl 336(%rsp), %edx
    decl %edx
    leaq .Ltail_tab(%rip), %rax
    movslq (%rax, %rdx, 4), %rdx
    addq %rax, %rdx
    jmp *%rdx
.Ltail_ret_linear:
    xorl %r11d, %r11d
    TAIL_COMPOSITE_NARROW 176, 16, 80, 16, 1
    TAIL_COMPOSITE_NARROW 192, 32, 96, 8, 1
    TAIL_COMPOSITE_NARROW 208, 48, 112, 0, 1
    movss 144(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, %r11d
    movl %r11d, (%r13)
    jmp .Ltail_advance_linear
.Ltail_zero_linear:
    movl $0, (%r13)
.Ltail_advance_linear:
    addq $4, %r12
    addq $4, %r14
    addq $4, %r13
    decl %ecx
    jnz .Llinear_tail_loop

.Lrow_next_linear:
    movl %ebx, %eax
    subl %ebp, %eax
    salq $2, %rax
    addq %r10, %r12
    subq %rax, %r12
    addq %r10, %r14
    subq %rax, %r14
    addq %r10, %r13
    subq %rax, %r13
    decl 0(%rsp)
    jnz .Llinear_rows
    jmp .Ldone

/* ------------------------------------------------------------------ */
/* Per-mode blend fragments (vector). In: widened channels in slots   */
/* (sr@16 sg@32 sb@48 br@80 bg@96 bb@112). Out: tR@176 tG@192 tB@208. */
/* Clobbers xmm0-xmm7. Return through r11.                             */
/* ------------------------------------------------------------------ */
.p2align 4
.Lblk_multiply:
    movaps 80(%rsp), %xmm0
    mulps 16(%rsp), %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm0
    mulps 32(%rsp), %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm0
    mulps 48(%rsp), %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_screen:
    /* t = (cb+cs) - cb*cs. */
    movaps 80(%rsp), %xmm0
    addps 16(%rsp), %xmm0
    movaps 80(%rsp), %xmm1
    mulps 16(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm0
    addps 32(%rsp), %xmm0
    movaps 96(%rsp), %xmm1
    mulps 32(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm0
    addps 48(%rsp), %xmm0
    movaps 112(%rsp), %xmm1
    mulps 48(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_overlay:
    /* t = cb<=0.5 ? (2*cb)*cs : 1-((2*(1-cb))*(1-cs)). */
    movaps 80(%rsp), %xmm1
    cmpleps .LhalfVec(%rip), %xmm1
    movaps .LtwoVec(%rip), %xmm0
    mulps 80(%rsp), %xmm0
    mulps 16(%rsp), %xmm0
    movaps .LoneVec(%rip), %xmm2
    subps 80(%rsp), %xmm2
    movaps .LtwoVec(%rip), %xmm3
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps 16(%rsp), %xmm2
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm1
    cmpleps .LhalfVec(%rip), %xmm1
    movaps .LtwoVec(%rip), %xmm0
    mulps 96(%rsp), %xmm0
    mulps 32(%rsp), %xmm0
    movaps .LoneVec(%rip), %xmm2
    subps 96(%rsp), %xmm2
    movaps .LtwoVec(%rip), %xmm3
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps 32(%rsp), %xmm2
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm1
    cmpleps .LhalfVec(%rip), %xmm1
    movaps .LtwoVec(%rip), %xmm0
    mulps 112(%rsp), %xmm0
    mulps 48(%rsp), %xmm0
    movaps .LoneVec(%rip), %xmm2
    subps 112(%rsp), %xmm2
    movaps .LtwoVec(%rip), %xmm3
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps 48(%rsp), %xmm2
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_darken:
    /* t = cb<cs ? cb : cs (ternary mirror, never minps). */
    movaps 80(%rsp), %xmm1
    cmpltps 16(%rsp), %xmm1
    movaps 80(%rsp), %xmm0
    andps %xmm1, %xmm0
    movaps 16(%rsp), %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm1
    cmpltps 32(%rsp), %xmm1
    movaps 96(%rsp), %xmm0
    andps %xmm1, %xmm0
    movaps 32(%rsp), %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm1
    cmpltps 48(%rsp), %xmm1
    movaps 112(%rsp), %xmm0
    andps %xmm1, %xmm0
    movaps 48(%rsp), %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_lighten:
    /* t = cb>cs ? cb : cs (mask = cs<cb). */
    movaps 16(%rsp), %xmm1
    cmpltps 80(%rsp), %xmm1
    movaps 80(%rsp), %xmm0
    andps %xmm1, %xmm0
    movaps 16(%rsp), %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 32(%rsp), %xmm1
    cmpltps 96(%rsp), %xmm1
    movaps 96(%rsp), %xmm0
    andps %xmm1, %xmm0
    movaps 32(%rsp), %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 48(%rsp), %xmm1
    cmpltps 112(%rsp), %xmm1
    movaps 112(%rsp), %xmm0
    andps %xmm1, %xmm0
    movaps 48(%rsp), %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_dodge:
    /* v = min(cb/(1-cs), 1); cs>=1 -> 1; cb==0 -> 0 (LAST, wins). */
    movaps .LoneVec(%rip), %xmm0
    subps 16(%rsp), %xmm0
    movaps 80(%rsp), %xmm1
    rcpps %xmm0, %xmm2
    mulps %xmm2, %xmm0
    movaps .LtwoVec(%rip), %xmm3
    subps %xmm0, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm1
    minps .LoneVec(%rip), %xmm1
    movaps 16(%rsp), %xmm2
    cmpnltps .LoneVec(%rip), %xmm2
    movaps .LoneVec(%rip), %xmm0
    andps %xmm2, %xmm0
    pxor .LonesVec(%rip), %xmm2
    andps %xmm2, %xmm1
    orps %xmm0, %xmm1
    movaps 80(%rsp), %xmm2
    cmpneqps %xmm15, %xmm2
    andps %xmm2, %xmm1
    movaps %xmm1, 176(%rsp)
    movaps .LoneVec(%rip), %xmm0
    subps 32(%rsp), %xmm0
    movaps 96(%rsp), %xmm1
    rcpps %xmm0, %xmm2
    mulps %xmm2, %xmm0
    movaps .LtwoVec(%rip), %xmm3
    subps %xmm0, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm1
    minps .LoneVec(%rip), %xmm1
    movaps 32(%rsp), %xmm2
    cmpnltps .LoneVec(%rip), %xmm2
    movaps .LoneVec(%rip), %xmm0
    andps %xmm2, %xmm0
    pxor .LonesVec(%rip), %xmm2
    andps %xmm2, %xmm1
    orps %xmm0, %xmm1
    movaps 96(%rsp), %xmm2
    cmpneqps %xmm15, %xmm2
    andps %xmm2, %xmm1
    movaps %xmm1, 192(%rsp)
    movaps .LoneVec(%rip), %xmm0
    subps 48(%rsp), %xmm0
    movaps 112(%rsp), %xmm1
    rcpps %xmm0, %xmm2
    mulps %xmm2, %xmm0
    movaps .LtwoVec(%rip), %xmm3
    subps %xmm0, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm1
    minps .LoneVec(%rip), %xmm1
    movaps 48(%rsp), %xmm2
    cmpnltps .LoneVec(%rip), %xmm2
    movaps .LoneVec(%rip), %xmm0
    andps %xmm2, %xmm0
    pxor .LonesVec(%rip), %xmm2
    andps %xmm2, %xmm1
    orps %xmm0, %xmm1
    movaps 112(%rsp), %xmm2
    cmpneqps %xmm15, %xmm2
    andps %xmm2, %xmm1
    movaps %xmm1, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_burn:
    /* v = 1-min((1-cb)/cs, 1); cs<=0 -> 0; cb>=1 -> 1 (LAST, wins). */
    movaps .LoneVec(%rip), %xmm0
    subps 80(%rsp), %xmm0
    movaps 16(%rsp), %xmm1
    rcpps %xmm1, %xmm2
    mulps %xmm2, %xmm1
    movaps .LtwoVec(%rip), %xmm3
    subps %xmm1, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm0
    movaps .LoneVec(%rip), %xmm1
    minps %xmm0, %xmm1
    movaps .LoneVec(%rip), %xmm0
    subps %xmm1, %xmm0
    movaps 16(%rsp), %xmm1
    cmpnleps %xmm15, %xmm1
    andps %xmm1, %xmm0
    movaps 80(%rsp), %xmm1
    cmpnltps .LoneVec(%rip), %xmm1
    movaps .LoneVec(%rip), %xmm2
    andps %xmm1, %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm0
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps .LoneVec(%rip), %xmm0
    subps 96(%rsp), %xmm0
    movaps 32(%rsp), %xmm1
    rcpps %xmm1, %xmm2
    mulps %xmm2, %xmm1
    movaps .LtwoVec(%rip), %xmm3
    subps %xmm1, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm0
    movaps .LoneVec(%rip), %xmm1
    minps %xmm0, %xmm1
    movaps .LoneVec(%rip), %xmm0
    subps %xmm1, %xmm0
    movaps 32(%rsp), %xmm1
    cmpnleps %xmm15, %xmm1
    andps %xmm1, %xmm0
    movaps 96(%rsp), %xmm1
    cmpnltps .LoneVec(%rip), %xmm1
    movaps .LoneVec(%rip), %xmm2
    andps %xmm1, %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm0
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps .LoneVec(%rip), %xmm0
    subps 112(%rsp), %xmm0
    movaps 48(%rsp), %xmm1
    rcpps %xmm1, %xmm2
    mulps %xmm2, %xmm1
    movaps .LtwoVec(%rip), %xmm3
    subps %xmm1, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm0
    movaps .LoneVec(%rip), %xmm1
    minps %xmm0, %xmm1
    movaps .LoneVec(%rip), %xmm0
    subps %xmm1, %xmm0
    movaps 48(%rsp), %xmm1
    cmpnleps %xmm15, %xmm1
    andps %xmm1, %xmm0
    movaps 112(%rsp), %xmm1
    cmpnltps .LoneVec(%rip), %xmm1
    movaps .LoneVec(%rip), %xmm2
    andps %xmm1, %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm0
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_hardlight:
    /* t = cs<=0.5 ? (2*cs)*cb : 1-((2*(1-cs))*(1-cb)). */
    movaps 16(%rsp), %xmm1
    cmpleps .LhalfVec(%rip), %xmm1
    movaps .LtwoVec(%rip), %xmm0
    mulps 16(%rsp), %xmm0
    mulps 80(%rsp), %xmm0
    movaps .LoneVec(%rip), %xmm2
    subps 16(%rsp), %xmm2
    movaps .LtwoVec(%rip), %xmm3
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps 80(%rsp), %xmm2
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 32(%rsp), %xmm1
    cmpleps .LhalfVec(%rip), %xmm1
    movaps .LtwoVec(%rip), %xmm0
    mulps 32(%rsp), %xmm0
    mulps 96(%rsp), %xmm0
    movaps .LoneVec(%rip), %xmm2
    subps 32(%rsp), %xmm2
    movaps .LtwoVec(%rip), %xmm3
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps 96(%rsp), %xmm2
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 48(%rsp), %xmm1
    cmpleps .LhalfVec(%rip), %xmm1
    movaps .LtwoVec(%rip), %xmm0
    mulps 48(%rsp), %xmm0
    mulps 112(%rsp), %xmm0
    movaps .LoneVec(%rip), %xmm2
    subps 48(%rsp), %xmm2
    movaps .LtwoVec(%rip), %xmm3
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps 112(%rsp), %xmm2
    mulps %xmm2, %xmm3
    movaps .LoneVec(%rip), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_softlight:
    /* d = cb<=0.25 ? ((16*cb-12)*cb+4)*cb : (float)sqrt((double)cb);
       t = cb + ((2*cs)-1)*(d-cb). */
    movaps 80(%rsp), %xmm0
    movaps 80(%rsp), %xmm1
    cmpleps .LquarterVec(%rip), %xmm1
    /* Polynomial side -> xmm2. */
    movaps .LsixteenVec(%rip), %xmm2
    mulps 80(%rsp), %xmm2
    subps .LtwelveVec(%rip), %xmm2
    mulps 80(%rsp), %xmm2
    addps .LfourVec(%rip), %xmm2
    mulps 80(%rsp), %xmm2
    /* Single-precision sqrt side -> xmm3 (all 4 lanes at once;
       double rounding can differ in the last bit vs the reference;
       covered by the maxDelta=1 tolerance). */
    sqrtps 80(%rsp), %xmm3
    andps %xmm1, %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm3
    orps %xmm3, %xmm2
    /* t = cb + ((2*cs)-1)*(d-cb). */
    movaps .LtwoVec(%rip), %xmm0
    mulps 16(%rsp), %xmm0
    subps .LoneVec(%rip), %xmm0
    movaps %xmm2, %xmm3
    subps 80(%rsp), %xmm3
    mulps %xmm3, %xmm0
    addps 80(%rsp), %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm1
    cmpleps .LquarterVec(%rip), %xmm1
    movaps .LsixteenVec(%rip), %xmm2
    mulps 96(%rsp), %xmm2
    subps .LtwelveVec(%rip), %xmm2
    mulps 96(%rsp), %xmm2
    addps .LfourVec(%rip), %xmm2
    mulps 96(%rsp), %xmm2
    sqrtps 96(%rsp), %xmm3
    andps %xmm1, %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm3
    orps %xmm3, %xmm2
    movaps .LtwoVec(%rip), %xmm0
    mulps 32(%rsp), %xmm0
    subps .LoneVec(%rip), %xmm0
    movaps %xmm2, %xmm3
    subps 96(%rsp), %xmm3
    mulps %xmm3, %xmm0
    addps 96(%rsp), %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm1
    cmpleps .LquarterVec(%rip), %xmm1
    movaps .LsixteenVec(%rip), %xmm2
    mulps 112(%rsp), %xmm2
    subps .LtwelveVec(%rip), %xmm2
    mulps 112(%rsp), %xmm2
    addps .LfourVec(%rip), %xmm2
    mulps 112(%rsp), %xmm2
    sqrtps 112(%rsp), %xmm3
    andps %xmm1, %xmm2
    pxor .LonesVec(%rip), %xmm1
    andps %xmm1, %xmm3
    orps %xmm3, %xmm2
    movaps .LtwoVec(%rip), %xmm0
    mulps 48(%rsp), %xmm0
    subps .LoneVec(%rip), %xmm0
    movaps %xmm2, %xmm3
    subps 112(%rsp), %xmm3
    mulps %xmm3, %xmm0
    addps 112(%rsp), %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_difference:
    /* t = |cb-cs|. */
    movaps 80(%rsp), %xmm0
    subps 16(%rsp), %xmm0
    andps .LabsMask(%rip), %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm0
    subps 32(%rsp), %xmm0
    andps .LabsMask(%rip), %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm0
    subps 48(%rsp), %xmm0
    andps .LabsMask(%rip), %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Lblk_exclusion:
    /* t = (cb+cs) - (2*cb)*cs. */
    movaps 80(%rsp), %xmm0
    addps 16(%rsp), %xmm0
    movaps .LtwoVec(%rip), %xmm1
    mulps 80(%rsp), %xmm1
    mulps 16(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 176(%rsp)
    movaps 96(%rsp), %xmm0
    addps 32(%rsp), %xmm0
    movaps .LtwoVec(%rip), %xmm1
    mulps 96(%rsp), %xmm1
    mulps 32(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 192(%rsp)
    movaps 112(%rsp), %xmm0
    addps 48(%rsp), %xmm0
    movaps .LtwoVec(%rip), %xmm1
    mulps 112(%rsp), %xmm1
    mulps 48(%rsp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 208(%rsp)
    jmp *%r11

.Ldone:
    addq $264, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

SIZE(SYM(applyFeBlendSsse3))

/* Mode jump tables: 32-bit self-relative offsets, index = mode - 1
   (modes 1..11). Same-section diffs assemble to plain constants, so the
   tables need no dynamic relocations and are TEXTREL-safe on every
   platform (absolute .quads would be rejected by the macOS linker and
   would need TEXTREL on ELF i386). */
.p2align 2
.Lblk_tab:
    .long .Lblk_multiply - .Lblk_tab, .Lblk_screen - .Lblk_tab
    .long .Lblk_overlay - .Lblk_tab, .Lblk_darken - .Lblk_tab
    .long .Lblk_lighten - .Lblk_tab, .Lblk_dodge - .Lblk_tab
    .long .Lblk_burn - .Lblk_tab, .Lblk_hardlight - .Lblk_tab
    .long .Lblk_softlight - .Lblk_tab, .Lblk_difference - .Lblk_tab
    .long .Lblk_exclusion - .Lblk_tab

RODATA
.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.L255Vec:
    .long 0x437f0000, 0x437f0000, 0x437f0000, 0x437f0000
.p2align 4
.Lrecip255Vec:
    .long 0x3b808081, 0x3b808081, 0x3b808081, 0x3b808081
.p2align 4
.Lhalf:
    .long 0x3f000000
.p2align 4
.LhalfVec:
    .long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
.p2align 4
.Lone:
    .long 0x3f800000
.p2align 4
.LoneVec:
    .long 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000
.p2align 4
.LonesVec:
    .long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
.p2align 4
.Ltwo:
    .long 0x40000000
.p2align 4
.LtwoVec:
    .long 0x40000000, 0x40000000, 0x40000000, 0x40000000
.p2align 4
.Lfour:
    .long 0x40800000
.p2align 4
.LfourVec:
    .long 0x40800000, 0x40800000, 0x40800000, 0x40800000
.p2align 4
.Ltwelve:
    .long 0x41400000
.p2align 4
.LtwelveVec:
    .long 0x41400000, 0x41400000, 0x41400000, 0x41400000
.p2align 4
.Lsixteen:
    .long 0x41800000
.p2align 4
.LsixteenVec:
    .long 0x41800000, 0x41800000, 0x41800000, 0x41800000
.p2align 4
.Lquarter:
    .long 0x3e800000
.p2align 4
.LquarterVec:
    .long 0x3e800000, 0x3e800000, 0x3e800000, 0x3e800000
.p2align 4
.LabsMask:
    .long 0x7fffffff, 0x7fffffff, 0x7fffffff, 0x7fffffff
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