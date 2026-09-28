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
 * x86-64 AVX2 implementation of feBlend, separable modes (1..11).
 * 8-wide VEX twin of fe_blend_x86_64_ssse3.S: same algorithm, same
 * near-exact contract under the avx2 maxDelta=1 parity tolerance
 * (same FP op order, no FMA, +0.5 + truncate, alpha never linearized,
 * group E routed to scalar by the C++ dispatcher and never reaching
 * this function). Widening multiplies by a 1/255 constant;
 * compositing/dodge/burn divide via one Newton-Raphson step over
 * `vrcpps` (~2^-21); soft-light uses single `vsqrtps`.
 *
 * VEX operand order (GAS lists src1, src2, dst; verified by micro-test):
 *   vop %A, %B, %C  =>  C = B OP A   (dst = SECOND-listed OP FIRST-listed)
 *   vblendvps %M, %T, %F, %O  =>  O = M ? T : F   (mask = FIRST operand)
 *   vcmpps $imm, %A, %B, %C  =>  C = (B OP A)
 *   mem operand must be FIRST-listed (src1/r/m position):
 *   `vmulps mem, %R, %R` assembles, `vmulps %R, mem, %R` does not.
 * Getting these backwards is silent and parity-fatal (or a loud
 * assemble error for the mem rule); the rules above
 * were confirmed instruction by instruction, not from memory.
 * Predicate trap (found via fuzz 2026-09-28: color-burn linear 12x12
 * index 40, cb==1.0 && cs==0.0): the burn/dodge edge masks must be
 * $5 NLT (>=), never $6 NLE (>). At exactly 1.0 the scalar takes the
 * edge arm FIRST (burn: cb>=1 -> 1; dodge: cs>=1 -> 1); with NLE the
 * mask misses, the 0/0 lane goes through vdivps+vminps (whose
 * second-operand NaN rule resolves to 1.0), and burn computes 1-1 = 0
 * instead of 1. SSSE3/i386/aarch64/arm32 all use >= (cmpnltps/vcge);
 * only this file had the $6 slip. Companion trap (same fuzz round,
 * color-burn sRGB/avx2 0x00-vs-~100 single pixels): the burn maskB
 * must be explicit $6 NLE (cs>0), never $7 ORD (merely "not NaN",
 * true for cs==0.0). Newton-Raphson computes q = e*d, and for a
 * 0-denominator e=+Inf gives Inf*0 = NaN where divps gives +Inf; the
 * NaN then poisons the composite (maskB-ORD keeps it, narrow clamps
 * NaN to 0) instead of resolving to 0/1 through the masks. SSSE3/i386
 * use cmpnleps (explicit) and never had this.
 * No vfmadd*ps (reference has separate mul+add), no vpgatherdd
 * (vpshufb nibble scan, lane-wise). vzeroupper before ret.
 *
 * 8px blocks, exact 32B loads/stores; leftovers (< 8px) go through the
 * shared scalar tail (fe_blend_scalar_tail.inc — same contract as the
 * SSSE3 file: lane-0 scalars at slots 16..208, xmm15 = zero, encode
 * table in r15, return through r11). Per-mode VEX fragments return
 * through r11, so both spaces share them.
 *
 * VEX selects are single vblendvps (mask preserved); the SSSE3 pxor
 * dance is unnecessary here. aoAlpha <= 0 is an (ao > 0) mask ANDed
 * after the compositing division.
 *
 * Stack frame: 6 pushes (48B) + sub $648 (entry rsp%16==8, so the sub
 * must be ==8 mod 16 to keep the movaps/vmovaps slot spills aligned).
 * Stack args: clipRight @704, clipBottom @712, mode @720,
 * useLinear @728, srgbToLinear @736, linearToSrgb @744.
 * Scratch: rows @0, tail @8; lane-0 tail scalars sr/sg/sb/as @16/32/
 * 48/64, br/bg/bb/ab @80/96/112/128, ao @144, aoMask @160,
 * tR/tG/tB @176/192/208 (shared with the .inc tail);
 * 8-wide block quads srQ/sgQ/sbQ/asQ @224/256/288/320,
 * brQ/bgQ/bbQ/abQ @352/384/416/448, aoQ @480, aoMaskQ @512,
 * tRQ/tGQ/tBQ @544/576/608. Quad spills use vmovdqu (NOT vmovaps):
 * entry rsp%32 varies with the caller (ABI fixes only %16), so a fixed
 * sub can never 32B-align the frame; unaligned moves have no penalty
 * when the data is aligned anyway.
 * Registers: r12/r14/r13 = src/dst/out cursors, r10 = row stride,
 * r15 = LUT base, ebp = clipLeft, ebx = clipRight,
 * ymm14 = 255.0 broadcast, ymm15 = zero (persistent).
 * FP constants come from (%rip) memory operands (32B quads where the
 * op needs them, 16B for vbroadcastf128/scalar-tail sharing).
 */

#include "asm_macros.S"

/*
 * Widen one channel's 8 packed bytes (low 8B of each lane of CH) to
 * floats/255. Multiplies by a 1/255 constant (same exhaustive proof
 * as SSSE3). Clobbers only CH (ymm14 = 255.0, ymm15 = zero).
 */
.macro WIDEN8 CH
    vpunpcklbw %ymm15, \CH, \CH
    vpunpcklwd %ymm15, \CH, \CH
    vcvtdq2ps \CH, \CH
    vmulps .Lrecip255Vec8(%rip), \CH, \CH
.endm

/*
 * Shared packed per-channel compositing into the tRQ/tGQ/tBQ quad.
 * Scalar equivalent (fe_blend.cpp):
 *   o = ((1-ab)*cs*as + (1-as)*cb*ab + as*ab*t) / ao; ao<=0 -> 0.
 * 1/ao via one Newton-Raphson step (same profile as SSSE3; 0-lanes
 * give +Inf, masked exactly like the div path).
 * Clobbers ymm0, ymm1, ymm2, ymm7.
 */
.macro COMPOSITE8 tslot, scslot, bcslot
    vbroadcastf128 .LoneVec(%rip), %ymm7
    vsubps 448(%rsp), %ymm7, %ymm7
    vmulps \scslot(%rsp), %ymm7, %ymm7
    vmulps 320(%rsp), %ymm7, %ymm7
    vbroadcastf128 .LoneVec(%rip), %ymm1
    vsubps 320(%rsp), %ymm1, %ymm1
    vmulps \bcslot(%rsp), %ymm1, %ymm1
    vmulps 448(%rsp), %ymm1, %ymm1
    vaddps %ymm1, %ymm7, %ymm7
    vmovdqu 320(%rsp), %ymm1
    vmulps 448(%rsp), %ymm1, %ymm1
    vmulps \tslot(%rsp), %ymm1, %ymm1
    vaddps %ymm1, %ymm7, %ymm7
    vrcpps 480(%rsp), %ymm0
    vmulps 480(%rsp), %ymm0, %ymm1
    vbroadcastf128 .LtwoVec(%rip), %ymm2
    vsubps %ymm1, %ymm2, %ymm1
    vmulps %ymm1, %ymm0, %ymm0
    vmulps %ymm0, %ymm7, %ymm7
    vandps 512(%rsp), %ymm7, %ymm7
    vmovdqu %ymm7, \tslot(%rsp)
.endm

/*
 * Narrow + store all 8 output pixels (lanes 0..7 of the R/G/B quads in
 * 544/576/608 and of aoQ in 480) to 32B at (%r13).
 * Matches clamp255(): *255, clamp [0,255], +0.5, truncate.
 * ENC=1: encode R/G/B through the table at (%r15); alpha never encoded.
 * The lane loads are VEX vmovss (not legacy movss): they zero the upper
 * lanes, so the following legacy narrow ops pay no AVX<->SSE transition
 * penalty and no vzeroupper is needed (which would eat the persistent
 * ymm14 broadcast). Pass bare numbers.
 */
.macro STORE_PIXEL8_LANE lane, enc
    vmovss 544+\lane*4(%rsp), %xmm0
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
    vmovss 576+\lane*4(%rsp), %xmm0
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
    vmovss 608+\lane*4(%rsp), %xmm0
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
    vmovss 480+\lane*4(%rsp), %xmm0
    mulss .L255(%rip), %xmm0
    maxss %xmm15, %xmm0
    minss .L255(%rip), %xmm0
    addss .Lhalf(%rip), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, %r11d
.endm

.macro STORE_PIXEL8 enc
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 0, \enc
    movl %r11d, 0(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 1, \enc
    movl %r11d, 4(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 2, \enc
    movl %r11d, 8(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 3, \enc
    movl %r11d, 12(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 4, \enc
    movl %r11d, 16(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 5, \enc
    movl %r11d, 20(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 6, \enc
    movl %r11d, 24(%r13)
    xorl %r11d, %r11d
    STORE_PIXEL8_LANE 7, \enc
    movl %r11d, 28(%r13)
.endm

/* Scalar-tail macro, fragments and tail jump table (shared with the
   SSSE3/i386 kernels). Included here — before .text — so the macro is
   defined before its uses in the tail returns below. */
#include "fe_blend_scalar_tail.inc"

.text
.p2align 5
/*
 * void applyFeBlendAvx2(
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
.globl SYM(applyFeBlendAvx2)
TYPE(SYM(applyFeBlendAvx2), @function)
SYM(applyFeBlendAvx2):
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $648, %rsp
    /* 6 pushes = 48 bytes; rsp is orig-696. Stack args:
       clipRight @704, clipBottom @712, mode @720, useLinear @728,
       srgbToLinear @736, linearToSrgb @744. Scratch 0..639. */

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
    movl 704(%rsp), %ebx             /* clipRight */
    /* rows = clipBottom - clipTop; empty clip: nothing to do. */
    movl 712(%rsp), %eax
    subl %r9d, %eax
    jle .Ldone
    movl %eax, 0(%rsp)               /* persistent rows left */

    vbroadcastf128 .L255Vec(%rip), %ymm14
    vpxor %ymm15, %ymm15, %ymm15     /* zero */

    movl 728(%rsp), %eax             /* useLinear (jboolean: test low byte) */
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
    shrl $3, %r9d                    /* blocks */
    andl $7, %ecx
    movl %ecx, 8(%rsp)               /* tail pixels */

    testl %r9d, %r9d
    jz .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    /* Widen src -> quads. */
    vmovdqu (%r12), %ymm0
    vbroadcastf128 .LshuffleR(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 224(%rsp)
    vbroadcastf128 .LshuffleG(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 256(%rsp)
    vbroadcastf128 .LshuffleB(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 288(%rsp)
    vbroadcastf128 .LshuffleA(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 320(%rsp)
    /* Widen dst -> quads. */
    vmovdqu (%r14), %ymm0
    vbroadcastf128 .LshuffleR(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 352(%rsp)
    vbroadcastf128 .LshuffleG(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 384(%rsp)
    vbroadcastf128 .LshuffleB(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 416(%rsp)
    vbroadcastf128 .LshuffleA(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 448(%rsp)
    /* ao = (as+ab) - as*ab; mask = (ao > 0). */
    vmovdqu 320(%rsp), %ymm0
    vaddps 448(%rsp), %ymm0, %ymm0
    vmovdqu 320(%rsp), %ymm1
    vmulps 448(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 480(%rsp)
    vpxor %ymm1, %ymm1, %ymm1
    vcmpps $7, %ymm1, %ymm0, %ymm1
    vmovdqu %ymm1, 512(%rsp)

    /* Per-mode blend -> tRQ/tGQ/tBQ; return to .Lblk_ret_nonlin. */
    leaq .Lblk_ret_nonlin(%rip), %r11
    movl 720(%rsp), %ecx
    decl %ecx
    leaq .Lblk8_tab(%rip), %rax
    movslq (%rax, %rcx, 4), %rcx
    addq %rax, %rcx
    jmp *%rcx
.Lblk_ret_nonlin:
    /* Composite quads, then narrow + store all 8 pixels. */
    COMPOSITE8 544, 224, 352
    COMPOSITE8 576, 256, 384
    COMPOSITE8 608, 288, 416
    STORE_PIXEL8 0

    addq $32, %r12
    addq $32, %r14
    addq $32, %r13
    subl $1, %r9d
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lrow_next_nonlin

.Lnonlin_tail_loop:
    /* Scalar widen both pixels, lane 0 -> shared tail slots. */
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
    /* NOTE: legacy SSE compare — xmm15 low lane is zero (set via vpxor
       above; lane 0 survives all VEX block code). */
    ucomiss %xmm15, %xmm0
    jbe .Ltail_zero_nonlin

    leaq .Ltail_ret_nonlin(%rip), %r11
    movl 720(%rsp), %edx
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
    shrl $3, %r9d
    andl $7, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Llinear_tail

.p2align 4
.Llinear_block:
    /* Decode src RGB via srgbToLinear; alpha bypasses the LUT.
       16-chunk scan, lane-identical: 16B table chunks and hi-compare
       vectors broadcast to both lanes (ColorMatrix AVX2 pattern). */
    vmovdqu (%r12), %ymm0
    vmovaps %ymm0, %ymm10
    vbroadcastf128 .LalphaMask(%rip), %ymm11
    vpand %ymm11, %ymm10, %ymm10
    vbroadcastf128 .LnibbleMask(%rip), %ymm11
    vmovaps %ymm0, %ymm8
    vpand %ymm11, %ymm8, %ymm8
    vmovaps %ymm0, %ymm9
    vpsrlw $4, %ymm9, %ymm9
    vpand %ymm11, %ymm9, %ymm9
    movq 736(%rsp), %r15
    vpxor %ymm1, %ymm1, %ymm1
    xorl %ecx, %ecx
    leaq .LhiTab(%rip), %rax
.Ldec_src_loop:
    vbroadcastf128 (%r15, %rcx, 1), %ymm5
    vpshufb %ymm8, %ymm5, %ymm5
    vbroadcastf128 (%rax, %rcx, 1), %ymm6
    vpcmpeqb %ymm9, %ymm6, %ymm6
    vpand %ymm6, %ymm5, %ymm5
    vpor %ymm5, %ymm1, %ymm1
    addq $16, %rcx
    cmpq $256, %rcx
    jne .Ldec_src_loop
    vbroadcastf128 .LrgbMask(%rip), %ymm2
    vpand %ymm2, %ymm1, %ymm0
    vpor %ymm10, %ymm0, %ymm0
    /* Widen decoded src -> quads. */
    vbroadcastf128 .LshuffleR(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 224(%rsp)
    vbroadcastf128 .LshuffleG(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 256(%rsp)
    vbroadcastf128 .LshuffleB(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 288(%rsp)
    vbroadcastf128 .LshuffleA(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 320(%rsp)
    /* Decode dst RGB the same way (scan clobbers ymm0/1/5/6/8/9/10/11
       only; widened src quads live in stack slots). */
    vmovdqu (%r14), %ymm0
    vmovaps %ymm0, %ymm10
    vbroadcastf128 .LalphaMask(%rip), %ymm11
    vpand %ymm11, %ymm10, %ymm10
    vbroadcastf128 .LnibbleMask(%rip), %ymm11
    vmovaps %ymm0, %ymm8
    vpand %ymm11, %ymm8, %ymm8
    vmovaps %ymm0, %ymm9
    vpsrlw $4, %ymm9, %ymm9
    vpand %ymm11, %ymm9, %ymm9
    vpxor %ymm1, %ymm1, %ymm1
    xorl %ecx, %ecx
.Ldec_dst_loop:
    vbroadcastf128 (%r15, %rcx, 1), %ymm5
    vpshufb %ymm8, %ymm5, %ymm5
    vbroadcastf128 (%rax, %rcx, 1), %ymm6
    vpcmpeqb %ymm9, %ymm6, %ymm6
    vpand %ymm6, %ymm5, %ymm5
    vpor %ymm5, %ymm1, %ymm1
    addq $16, %rcx
    cmpq $256, %rcx
    jne .Ldec_dst_loop
    vbroadcastf128 .LrgbMask(%rip), %ymm2
    vpand %ymm2, %ymm1, %ymm0
    vpor %ymm10, %ymm0, %ymm0
    vbroadcastf128 .LshuffleR(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 352(%rsp)
    vbroadcastf128 .LshuffleG(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 384(%rsp)
    vbroadcastf128 .LshuffleB(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 416(%rsp)
    vbroadcastf128 .LshuffleA(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vmovdqu %ymm1, 448(%rsp)
    /* ao + mask. */
    vmovdqu 320(%rsp), %ymm0
    vaddps 448(%rsp), %ymm0, %ymm0
    vmovdqu 320(%rsp), %ymm1
    vmulps 448(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 480(%rsp)
    vpxor %ymm1, %ymm1, %ymm1
    vcmpps $7, %ymm1, %ymm0, %ymm1
    vmovdqu %ymm1, 512(%rsp)

    leaq .Lblk_ret_linear(%rip), %r11
    movl 720(%rsp), %ecx
    decl %ecx
    leaq .Lblk8_tab(%rip), %rax
    movslq (%rax, %rcx, 4), %rcx
    addq %rax, %rcx
    jmp *%rcx
.Lblk_ret_linear:
    /* Composite + narrow with encode. */
    movq 744(%rsp), %r15             /* linearToSrgb */
    COMPOSITE8 544, 224, 352
    COMPOSITE8 576, 256, 384
    COMPOSITE8 608, 288, 416
    STORE_PIXEL8 1

    addq $32, %r12
    addq $32, %r14
    addq $32, %r13
    subl $1, %r9d
    jnz .Llinear_block

.Llinear_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lrow_next_linear
    movq 744(%rsp), %r15             /* encode table for the tail */

.Llinear_tail_loop:
    movq 736(%rsp), %rax             /* srgbToLinear */
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
    movl 720(%rsp), %edx
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
/* Per-mode blend fragments (vector, 8-wide). In: widened channel     */
/* quads in slots (srQ@224 sgQ@256 sbQ@288 brQ@352 bgQ@384 bbQ@416).   */
/* Out: tRQ@544 tGQ@576 tBQ@608. Clobbers ymm0-ymm7. Return via r11.   */
/* Selects are single vblendvps (mask preserved, TRUE arm second).     */
/* ------------------------------------------------------------------ */
.p2align 4
.Lblk8_multiply:
    vmovdqu 352(%rsp), %ymm0
    vmulps 224(%rsp), %ymm0, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vmulps 256(%rsp), %ymm0, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vmulps 288(%rsp), %ymm0, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_screen:
    /* t = (cb+cs) - cb*cs. */
    vmovdqu 352(%rsp), %ymm0
    vaddps 224(%rsp), %ymm0, %ymm0
    vmovdqu 352(%rsp), %ymm1
    vmulps 224(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vaddps 256(%rsp), %ymm0, %ymm0
    vmovdqu 384(%rsp), %ymm1
    vmulps 256(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vaddps 288(%rsp), %ymm0, %ymm0
    vmovdqu 416(%rsp), %ymm1
    vmulps 288(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_overlay:
    /* t = cb<=0.5 ? (2*cb)*cs : 1-((2*(1-cb))*(1-cs)). */
    vbroadcastf128 .LhalfVec(%rip), %ymm4
    vbroadcastf128 .LoneVec(%rip), %ymm5
    vbroadcastf128 .LtwoVec(%rip), %ymm6
    vmovdqu 352(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmulps 352(%rsp), %ymm6, %ymm0
    vmulps 224(%rsp), %ymm0, %ymm0
    vsubps 352(%rsp), %ymm5, %ymm2
    vmulps %ymm6, %ymm2, %ymm3
    vsubps 224(%rsp), %ymm5, %ymm2
    vmulps %ymm2, %ymm3, %ymm3
    vsubps %ymm3, %ymm5, %ymm2
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmulps 384(%rsp), %ymm6, %ymm0
    vmulps 256(%rsp), %ymm0, %ymm0
    vsubps 384(%rsp), %ymm5, %ymm2
    vmulps %ymm6, %ymm2, %ymm3
    vsubps 256(%rsp), %ymm5, %ymm2
    vmulps %ymm2, %ymm3, %ymm3
    vsubps %ymm3, %ymm5, %ymm2
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmulps 416(%rsp), %ymm6, %ymm0
    vmulps 288(%rsp), %ymm0, %ymm0
    vsubps 416(%rsp), %ymm5, %ymm2
    vmulps %ymm6, %ymm2, %ymm3
    vsubps 288(%rsp), %ymm5, %ymm2
    vmulps %ymm2, %ymm3, %ymm3
    vsubps %ymm3, %ymm5, %ymm2
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_darken:
    /* t = cb<cs ? cb : cs. */
    vmovdqu 352(%rsp), %ymm0
    vmovdqu 224(%rsp), %ymm2
    vcmpps $1, %ymm2, %ymm0, %ymm1
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vmovdqu 256(%rsp), %ymm2
    vcmpps $1, %ymm2, %ymm0, %ymm1
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vmovdqu 288(%rsp), %ymm2
    vcmpps $1, %ymm2, %ymm0, %ymm1
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_lighten:
    /* t = cb>cs ? cb : cs (mask = cs<cb). */
    vmovdqu 352(%rsp), %ymm0
    vmovdqu 224(%rsp), %ymm2
    vcmpps $1, %ymm0, %ymm2, %ymm1
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vmovdqu 256(%rsp), %ymm2
    vcmpps $1, %ymm0, %ymm2, %ymm1
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vmovdqu 288(%rsp), %ymm2
    vcmpps $1, %ymm0, %ymm2, %ymm1
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_dodge:
    /* v = min(cb/(1-cs), 1); cs>=1 -> 1; cb!=0 keeps, cb==0 -> 0. */
    vbroadcastf128 .LoneVec(%rip), %ymm5
    vmovdqu 224(%rsp), %ymm0
    vsubps %ymm0, %ymm5, %ymm0
    vmovdqu 352(%rsp), %ymm1
    vrcpps %ymm0, %ymm2
    vmulps %ymm2, %ymm0, %ymm0
    vbroadcastf128 .LtwoVec(%rip), %ymm3
    vsubps %ymm0, %ymm3, %ymm0
    vmulps %ymm0, %ymm2, %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vminps %ymm5, %ymm1, %ymm1
    vmovdqu 224(%rsp), %ymm2
    vcmpps $5, %ymm5, %ymm2, %ymm2
    vblendvps %ymm2, %ymm5, %ymm1, %ymm1
    vmovdqu 352(%rsp), %ymm2
    vpxor %ymm3, %ymm3, %ymm3
    vcmpps $4, %ymm2, %ymm3, %ymm2
    vandps %ymm2, %ymm1, %ymm1
    vmovdqu %ymm1, 544(%rsp)
    vmovdqu 256(%rsp), %ymm0
    vsubps %ymm0, %ymm5, %ymm0
    vmovdqu 384(%rsp), %ymm1
    vrcpps %ymm0, %ymm2
    vmulps %ymm2, %ymm0, %ymm0
    vbroadcastf128 .LtwoVec(%rip), %ymm3
    vsubps %ymm0, %ymm3, %ymm0
    vmulps %ymm0, %ymm2, %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vminps %ymm5, %ymm1, %ymm1
    vmovdqu 256(%rsp), %ymm2
    vcmpps $5, %ymm5, %ymm2, %ymm2
    vblendvps %ymm2, %ymm5, %ymm1, %ymm1
    vmovdqu 384(%rsp), %ymm2
    vpxor %ymm3, %ymm3, %ymm3
    vcmpps $4, %ymm2, %ymm3, %ymm2
    vandps %ymm2, %ymm1, %ymm1
    vmovdqu %ymm1, 576(%rsp)
    vmovdqu 288(%rsp), %ymm0
    vsubps %ymm0, %ymm5, %ymm0
    vmovdqu 416(%rsp), %ymm1
    vrcpps %ymm0, %ymm2
    vmulps %ymm2, %ymm0, %ymm0
    vbroadcastf128 .LtwoVec(%rip), %ymm3
    vsubps %ymm0, %ymm3, %ymm0
    vmulps %ymm0, %ymm2, %ymm2
    vmulps %ymm2, %ymm1, %ymm1
    vminps %ymm5, %ymm1, %ymm1
    vmovdqu 288(%rsp), %ymm2
    vcmpps $5, %ymm5, %ymm2, %ymm2
    vblendvps %ymm2, %ymm5, %ymm1, %ymm1
    vmovdqu 416(%rsp), %ymm2
    vpxor %ymm3, %ymm3, %ymm3
    vcmpps $4, %ymm2, %ymm3, %ymm2
    vandps %ymm2, %ymm1, %ymm1
    vmovdqu %ymm1, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_burn:
    /* v = 1-min((1-cb)/cs, 1); cs<=0 -> 0 (keep where cs>0); cb>=1 -> 1. */
    vbroadcastf128 .LoneVec(%rip), %ymm5
    vmovdqu 352(%rsp), %ymm0
    vsubps %ymm0, %ymm5, %ymm0
    vrcpps 224(%rsp), %ymm2
    vmulps 224(%rsp), %ymm2, %ymm1
    vbroadcastf128 .LtwoVec(%rip), %ymm3
    vsubps %ymm1, %ymm3, %ymm1
    vmulps %ymm1, %ymm2, %ymm2
    vmulps %ymm2, %ymm0, %ymm0
    vmovaps %ymm5, %ymm1
    vminps %ymm0, %ymm1, %ymm1
    vsubps %ymm1, %ymm5, %ymm0
    vmovdqu 224(%rsp), %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    vcmpps $6, %ymm2, %ymm1, %ymm1
    vandps %ymm1, %ymm0, %ymm0
    vmovdqu 352(%rsp), %ymm1
    vcmpps $5, %ymm5, %ymm1, %ymm1
    vblendvps %ymm1, %ymm5, %ymm0, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vsubps %ymm0, %ymm5, %ymm0
    vrcpps 256(%rsp), %ymm2
    vmulps 256(%rsp), %ymm2, %ymm1
    vbroadcastf128 .LtwoVec(%rip), %ymm3
    vsubps %ymm1, %ymm3, %ymm1
    vmulps %ymm1, %ymm2, %ymm2
    vmulps %ymm2, %ymm0, %ymm0
    vmovaps %ymm5, %ymm1
    vminps %ymm0, %ymm1, %ymm1
    vsubps %ymm1, %ymm5, %ymm0
    vmovdqu 256(%rsp), %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    vcmpps $6, %ymm2, %ymm1, %ymm1
    vandps %ymm1, %ymm0, %ymm0
    vmovdqu 384(%rsp), %ymm1
    vcmpps $5, %ymm5, %ymm1, %ymm1
    vblendvps %ymm1, %ymm5, %ymm0, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vsubps %ymm0, %ymm5, %ymm0
    vrcpps 288(%rsp), %ymm2
    vmulps 288(%rsp), %ymm2, %ymm1
    vbroadcastf128 .LtwoVec(%rip), %ymm3
    vsubps %ymm1, %ymm3, %ymm1
    vmulps %ymm1, %ymm2, %ymm2
    vmulps %ymm2, %ymm0, %ymm0
    vmovaps %ymm5, %ymm1
    vminps %ymm0, %ymm1, %ymm1
    vsubps %ymm1, %ymm5, %ymm0
    vmovdqu 288(%rsp), %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    vcmpps $6, %ymm2, %ymm1, %ymm1
    vandps %ymm1, %ymm0, %ymm0
    vmovdqu 416(%rsp), %ymm1
    vcmpps $5, %ymm5, %ymm1, %ymm1
    vblendvps %ymm1, %ymm5, %ymm0, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_hardlight:
    /* t = cs<=0.5 ? (2*cs)*cb : 1-((2*(1-cs))*(1-cb)). */
    vbroadcastf128 .LhalfVec(%rip), %ymm4
    vbroadcastf128 .LoneVec(%rip), %ymm5
    vbroadcastf128 .LtwoVec(%rip), %ymm6
    vmovdqu 224(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmulps 224(%rsp), %ymm6, %ymm0
    vmulps 352(%rsp), %ymm0, %ymm0
    vsubps 224(%rsp), %ymm5, %ymm2
    vmulps %ymm6, %ymm2, %ymm3
    vsubps 352(%rsp), %ymm5, %ymm2
    vmulps %ymm2, %ymm3, %ymm3
    vsubps %ymm3, %ymm5, %ymm2
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 256(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmulps 256(%rsp), %ymm6, %ymm0
    vmulps 384(%rsp), %ymm0, %ymm0
    vsubps 256(%rsp), %ymm5, %ymm2
    vmulps %ymm6, %ymm2, %ymm3
    vsubps 384(%rsp), %ymm5, %ymm2
    vmulps %ymm2, %ymm3, %ymm3
    vsubps %ymm3, %ymm5, %ymm2
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 288(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmulps 288(%rsp), %ymm6, %ymm0
    vmulps 416(%rsp), %ymm0, %ymm0
    vsubps 288(%rsp), %ymm5, %ymm2
    vmulps %ymm6, %ymm2, %ymm3
    vsubps 416(%rsp), %ymm5, %ymm2
    vmulps %ymm2, %ymm3, %ymm3
    vsubps %ymm3, %ymm5, %ymm2
    vblendvps %ymm1, %ymm0, %ymm2, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_softlight:
    /* d = cb<=0.25 ? poly : (float)sqrt((double)cb) per 4-lane half;
       t = cb + ((2*cs)-1)*(d-cb). */
    vbroadcastf128 .LquarterVec(%rip), %ymm4
    vmovdqu 352(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmovdqu 352(%rsp), %ymm7
    vbroadcastf128 .LsixteenVec(%rip), %ymm2
    vmulps 352(%rsp), %ymm2, %ymm2
    vbroadcastf128 .LtwelveVec(%rip), %ymm3
    vsubps %ymm3, %ymm2, %ymm2
    vmulps 352(%rsp), %ymm2, %ymm2
    vbroadcastf128 .LfourVec(%rip), %ymm3
    vaddps %ymm3, %ymm2, %ymm2
    vmulps 352(%rsp), %ymm2, %ymm2
    /* Single-precision sqrt (all 8 lanes; double rounding can differ
       in the last bit — covered by tolerance). */
    vsqrtps 352(%rsp), %ymm3
    vblendvps %ymm1, %ymm2, %ymm3, %ymm2
    vbroadcastf128 .LtwoVec(%rip), %ymm0
    vmulps 224(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LoneVec(%rip), %ymm3
    vsubps %ymm3, %ymm0, %ymm0
    vsubps 352(%rsp), %ymm2, %ymm3
    vmulps %ymm3, %ymm0, %ymm0
    vaddps 352(%rsp), %ymm0, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmovdqu 384(%rsp), %ymm7
    vbroadcastf128 .LsixteenVec(%rip), %ymm2
    vmulps 384(%rsp), %ymm2, %ymm2
    vbroadcastf128 .LtwelveVec(%rip), %ymm3
    vsubps %ymm3, %ymm2, %ymm2
    vmulps 384(%rsp), %ymm2, %ymm2
    vbroadcastf128 .LfourVec(%rip), %ymm3
    vaddps %ymm3, %ymm2, %ymm2
    vmulps 384(%rsp), %ymm2, %ymm2
    vsqrtps 384(%rsp), %ymm3
    vblendvps %ymm1, %ymm2, %ymm3, %ymm2
    vbroadcastf128 .LtwoVec(%rip), %ymm0
    vmulps 256(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LoneVec(%rip), %ymm3
    vsubps %ymm3, %ymm0, %ymm0
    vsubps 384(%rsp), %ymm2, %ymm3
    vmulps %ymm3, %ymm0, %ymm0
    vaddps 384(%rsp), %ymm0, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm1
    vcmpps $2, %ymm4, %ymm1, %ymm1
    vmovdqu 416(%rsp), %ymm7
    vbroadcastf128 .LsixteenVec(%rip), %ymm2
    vmulps 416(%rsp), %ymm2, %ymm2
    vbroadcastf128 .LtwelveVec(%rip), %ymm3
    vsubps %ymm3, %ymm2, %ymm2
    vmulps 416(%rsp), %ymm2, %ymm2
    vbroadcastf128 .LfourVec(%rip), %ymm3
    vaddps %ymm3, %ymm2, %ymm2
    vmulps 416(%rsp), %ymm2, %ymm2
    /* Single-precision sqrt (all 8 lanes; double rounding can differ
       in the last bit — covered by tolerance). */
    vsqrtps 416(%rsp), %ymm3
    vblendvps %ymm1, %ymm2, %ymm3, %ymm2
    vbroadcastf128 .LtwoVec(%rip), %ymm0
    vmulps 288(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LoneVec(%rip), %ymm3
    vsubps %ymm3, %ymm0, %ymm0
    vsubps 416(%rsp), %ymm2, %ymm3
    vmulps %ymm3, %ymm0, %ymm0
    vaddps 416(%rsp), %ymm0, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_difference:
    /* t = |cb-cs|. */
    vmovdqu 352(%rsp), %ymm0
    vsubps 224(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LabsMask(%rip), %ymm1
    vandps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vsubps 256(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LabsMask(%rip), %ymm1
    vandps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vsubps 288(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LabsMask(%rip), %ymm1
    vandps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.p2align 4
.Lblk8_exclusion:
    /* t = (cb+cs) - (2*cb)*cs. */
    vmovdqu 352(%rsp), %ymm0
    vaddps 224(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LtwoVec(%rip), %ymm1
    vmulps 352(%rsp), %ymm1, %ymm1
    vmulps 224(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 544(%rsp)
    vmovdqu 384(%rsp), %ymm0
    vaddps 256(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LtwoVec(%rip), %ymm1
    vmulps 384(%rsp), %ymm1, %ymm1
    vmulps 256(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 576(%rsp)
    vmovdqu 416(%rsp), %ymm0
    vaddps 288(%rsp), %ymm0, %ymm0
    vbroadcastf128 .LtwoVec(%rip), %ymm1
    vmulps 416(%rsp), %ymm1, %ymm1
    vmulps 288(%rsp), %ymm1, %ymm1
    vsubps %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, 608(%rsp)
    jmp *%r11

.Ldone:
    vzeroupper
    addq $648, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

SIZE(SYM(applyFeBlendAvx2))

/* Block jump table: 32-bit self-relative diffs, index = mode - 1. */
.p2align 2
.Lblk8_tab:
    .long .Lblk8_multiply - .Lblk8_tab, .Lblk8_screen - .Lblk8_tab
    .long .Lblk8_overlay - .Lblk8_tab, .Lblk8_darken - .Lblk8_tab
    .long .Lblk8_lighten - .Lblk8_tab, .Lblk8_dodge - .Lblk8_tab
    .long .Lblk8_burn - .Lblk8_tab, .Lblk8_hardlight - .Lblk8_tab
    .long .Lblk8_softlight - .Lblk8_tab, .Lblk8_difference - .Lblk8_tab
    .long .Lblk8_exclusion - .Lblk8_tab

RODATA
.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.L255Vec:
    .long 0x437f0000, 0x437f0000, 0x437f0000, 0x437f0000
.p2align 5
.Lrecip255Vec8:
    .long 0x3b808081, 0x3b808081, 0x3b808081, 0x3b808081
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
