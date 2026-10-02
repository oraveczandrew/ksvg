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
 * ARMv7 / NEON32 implementation of feBlend, separable modes (1..11).
 * Bit-exact twin of KotlinKernels.feBlend / fe_blend.cpp scalar:
 * same FP op order (VFP scalar divide by 255, left-to-right evaluation,
 * no FMA), same LUT folding, same clamp255 (+0.5, truncate via
 * vcvt.s32.f32 - NEVER round-to-nearest). Alpha never linearized.
 * Non-separable modes (12..15) never reach this function: the C++
 * dispatcher routes them to scalar.
 *
 * 4px blocks, exact-consume stores (per-pixel scalar str post-index;
 * odd widths go through the scalar tail). `mode` is constant per call:
 * inline jump tables (32-bit self-relative .word diffs + adr/ldr/add pc
 * - no GOT, no literal pool, TEXTREL-free) select the per-mode blend
 * fragment per block (and a second table for the scalar tail).
 *
 * Spill design: widened channels live in named stack slots with the SAME
 * offsets as the x86/aarch64 files (sr/sg/sb/as @16/32/48/64,
 * br/bg/bb/ab @80/96/112/128, ao @144, aoMask @160, tR/tG/tB
 * @176/192/208, const255 @224, constOne @240, constHalf @12), so the 11
 * vector fragments transfer with minimal edits. Widened floats live in
 * A=q0 R=q1 G=q2 B=q3 (all in D0-D7, caller-saved). Every fragment is
 * load-compute-store through q0-q3 (+q8/q9 temps), result always in q0.
 * q12 = 255.0 and q13 = 1.0 are rebuilt per block and survive the
 * LUTSCAN decode (which clobbers q7/q14/q15 only) and every
 * fragment (fragments never write q12/q13).
 *
 * ARM32-specific notes:
 * - vld4.8 loads 8px but a 4px block consumes 4 (lanes 4-7 ignored).
 *   The 4px over-read is harmless mid-image but would read past the
 *   buffer on the last row, so the whole last row goes through the
 *   scalar tail (same guard as color_matrix_armv7a_neon.S).
 * - NEON has no vector divide: widening multiplies by a 1/255
 *   reciprocal quad (4 vector ops replacing 16 scalar VFP divides;
 *   exhaustive error analysis in MUL_RECIP), blend divisions via 4x
 *   VFP scalar vdiv per channel, soft-light D(cb) sqrt via single-
 *   precision vsqrt (double rounding can differ in the last bit;
 *   covered by the neon32 maxDelta=1 tolerance).
 * - VFP scalar S-regs exist only as S0-S31 (D16-D31 have no single
 *   views), so widened floats live in A=q0 R=q1 G=q2 B=q3 (all in
 *   D0-D7, caller-saved); s31 (D15) carries 255.0 for the scalar
 *   tail only (the block path multiplies by the q8 reciprocal);
 *   D8-D15 are vpush'd/vpop'd once per call. Widen order is
 *   constrained (a dest D-reg must not hold an unread byte source,
 *   including the d6/D6/q3-low alias: A->q3 would destroy the unread
 *   R source d6): nonlinear images widen B,G,A,R and linear-decode
 *   images A,R,B,G; each site documents its order. Only D0-D15 and
 *   D16-D31 are used.
 * - VFP has no scalar min/max: single-lane clamps run through a NEON
 *   lane (value moved to s8, vector ops on q2, lane read back).
 * - FP tail branches use vcmp.f32 + vmrs APSR_nzcv,fpscr with the
 *   compiler mapping (<= is bls, < is bmi, >= is bge, > is bgt,
 *   == is beq); NaN is unordered so every ordered branch is false,
 *   mirroring the scalar ternary exactly.
 * - Selects are and/bic/or triples mirroring the scalar ternaries
 *   exactly (never vmin/vmax for darken/lighten/overlay/hard-light).
 * - color-dodge/burn compute the division on all lanes, so the 0/0
 *   lane is forced explicitly (cb==0 -> 0 wins last for dodge,
 *   cb>=1 -> 1 wins last for burn); never rely on (int)NaN.
 * - aoAlpha <= 0 forces a zero pixel: block path ANDs an (ao > 0)
 *   mask AFTER the compositing division, tail path branches.
 * - Narrowing is scalar-VFP-free: vector vmul(*255)/vmax/vmin/vadd
 *   (+0.5)/vcvt.s32.f32 (truncate) then per-lane vmov to GPR.
 *   Narrow dests are GPRs, so they can never alias live float quads.
 * - lr holds the fragment return address only (adr lr + bx lr);
 *   never used as a temp. r8/r10/r12 are dispatch/loop scratch,
 *   reloaded per use. r9 (rows) and r11 (blocks/tail) survive every
 *   fragment (tail fragments use s0-s3 + r12 only).
 *
 * Stack frame: push {r4-r11, lr} (36B) + vpush {d8-d15} (64B)
 * + sub sp, sp, #260 (total 360B, so sp stays 8B-aligned per AAPCS;
 * slots use @0..255, @256..259 is padding). Stack args (caller sp+0
 * up, i.e., current sp+360 up): clipLeft @360, clipTop @364,
 * clipRight @368, clipBottom @372, mode @376, useLinear @380 (ldrb:
 * upper bytes void), srgbToLinear @384, linearToSrgb @388.
 * Registers: r4/r5/r6 = src/dst/out cursors, r7 = row stride bytes,
 * r8 = count/mode-index scratch, r9 = rows left, r10 = table base /
 * dispatch base, r11 = blocks/tail counter, r12 = universal scratch,
 * r3 = pixel accumulator / widen temp, r0-r2 free after prologue.
 */

#include "asm_macros.S"

/*
 * Nibble-scan one 8-lane channel through the 256-byte table at [rT]:
 * 16 iterations over 16-byte chunks, high-nibble compare + vtbl + vbsl.
 * Result accumulates in dAcc (zero it first). Clobbers d14, d15, d28,
 * d29, d30, r3, r12. d31 must hold #15. (Copied verbatim from
 * color_matrix_armv7a_neon.S: same contract. Kept exact deliberately:
 * a polynomial decode was tried and reverted — the steep low-end
 * linear-to-sRGB curve (l2s[1]-l2s[0] = 13) amplifies sub-LSB decode
 * errors past any output-byte tolerance. See worklog.)
 */
.macro LUTSCAN dIn, dAcc, rT
    mov     r3, \rT
    mov     r12, #0
.Lscan_\@:
    vld1.8  {d14, d15}, [r3]!
    vdup.8  d30, r12
    vshr.u8 d29, \dIn, #4
    vceq.u8 d29, d29, d30
    vand    d28, \dIn, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, \dAcc
    vmov    \dAcc, d29
    add     r12, r12, #1
    cmp     r12, #16
    bne     .Lscan_\@
    sub     r3, r3, #256
.endm

/*
 * Widen 4 byte lanes of dIn (low 4 lanes = px0-3) to float quad qOut.
 * Clobbers q15. The 1/255 scale is separate (MUL_RECIP via q8).
 */
.macro WIDEN_CH dIn, qOut
    vmovl.u8 q15, \dIn
    vmovl.u16 \qOut, d30
    vcvt.f32.u32 \qOut, \qOut
.endm

/*
 * Multiply the 16 live float lanes (A=q0 R=q1 G=q2 B=q3) by the
 * 1/255 reciprocal in q8 (4 vector ops replacing 16 scalar VFP
 * divides). Precision: fl(b*fl(1/255)) differs from b/255 by at most
 * 7.5e-08 over b = 0..255 (exhaustive, 0/256 direct-roundtrip
 * diffs); after blend math the final pixel can differ from the
 * all-divide reference by ±1 LSB in rare tie cases, which the
 * neon32 maxDelta=1 parity tolerance covers (same argument as the
 * convolve NEON reciprocal). Clobbers nothing else.
 */
.macro MUL_RECIP
    vmul.f32 q0, q0, q8
    vmul.f32 q1, q1, q8
    vmul.f32 q2, q2, q8
    vmul.f32 q3, q3, q8
.endm

/*
 * Load cb+cs channel quads for a block fragment (result quads, NOT
 * fragile: call sites pass bare slot numbers). Clobbers r12.
 */
.macro LD_CB_CS bc, sc
    add     r12, sp, #\bc
    vld1.32 {d0, d1}, [r12]
    add     r12, sp, #\sc
    vld1.32 {d2, d3}, [r12]
.endm

/*
 * Store the channel result (always in q0) to the t slot.
 * Clobbers r12.
 */
.macro ST_T t
    add     r12, sp, #\t
    vst1.32 {d0, d1}, [r12]
.endm

/*
 * Vector ao + mask for a block. Scalar equivalent (fe_blend.cpp):
 * ao = (as+ab) - as*ab; mask = (ao > 0).
 * Clobbers q0-q2, r12.
 */
.macro AO_MASK
    add     r12, sp, #64
    vld1.32 {d0, d1}, [r12]
    add     r12, sp, #128
    vld1.32 {d2, d3}, [r12]
    vmul.f32 q2, q0, q1
    vadd.f32 q0, q0, q1
    vsub.f32 q0, q0, q2
    add     r12, sp, #144
    vst1.32 {d0, d1}, [r12]
    vcgt.f32 q1, q0, #0
    add     r12, sp, #160
    vst1.32 {d2, d3}, [r12]
.endm

/*
 * Scalar ao for the tail: ao -> slot @144, ao <= 0 branches to the
 * given zero label. Clobbers s0/s1/s2.
 */
.macro TAIL_AO zerolabel
    vldr    s0, [sp, #64]
    vldr    s1, [sp, #128]
    vmul.f32 s2, s0, s1
    vadd.f32 s0, s0, s1
    vsub.f32 s0, s0, s2
    vstr    s0, [sp, #144]
    vcmp.f32 s0, #0
    vmrs    APSR_nzcv, fpscr
    bls     \zerolabel
.endm

/*
 * Scalar widen of one packed pixel (no LUT): channels to slots
 * oR/oG/oB/oA via s31 (255.0). Clobbers r12, r3, s0.
 */
.macro TAIL_WIDEN_PIXEL cur, oR, oG, oB, oA
    ldr     r12, [\cur]
    ubfx    r3, r12, #16, #8
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oR]
    ubfx    r3, r12, #8, #8
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oG]
    and     r3, r12, #0xff
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oB]
    lsr     r3, r12, #24
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oA]
.endm

/*
 * Scalar widen of one packed pixel through the LUT at [r10]:
 * R/G/B decoded, alpha raw. Clobbers r12, r3, s0.
 */
.macro TAIL_DECODE_PIXEL cur, oR, oG, oB, oA
    ldr     r12, [\cur]
    ubfx    r3, r12, #16, #8
    ldrb    r3, [r10, r3]
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oR]
    ubfx    r3, r12, #8, #8
    ldrb    r3, [r10, r3]
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oG]
    and     r3, r12, #0xff
    ldrb    r3, [r10, r3]
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oB]
    lsr     r3, r12, #24
    vmov    s0, r3
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s31
    vstr    s0, [sp, #\oA]
.endm

/*
 * Shared per-channel compositing into the t slot (block path).
 * Scalar equivalent (fe_blend.cpp):
 * o = ((1-ab)*cs*as + (1-as)*cb*ab + as*ab*t) / ao; ao<=0 -> 0
 * (the zero comes from the aoMask AND after the division:
 * div-by-zero lanes produce inf, which never faults and is masked).
 * Clobbers q0-q2, r12. q13 = 1.0.
 */
.macro COMPOSITE_ARM tslot, scslot, bcslot
    add     r12, sp, #128
    vld1.32 {d0, d1}, [r12]
    add     r12, sp, #240
    vld1.32 {d2, d3}, [r12]
    vsub.f32 q0, q1, q0
    add     r12, sp, #\scslot
    vld1.32 {d2, d3}, [r12]
    vmul.f32 q0, q0, q1
    add     r12, sp, #64
    vld1.32 {d2, d3}, [r12]
    vmul.f32 q0, q0, q1
    add     r12, sp, #240
    vld1.32 {d2, d3}, [r12]
    add     r12, sp, #64
    vld1.32 {d4, d5}, [r12]
    vsub.f32 q1, q1, q2
    add     r12, sp, #\bcslot
    vld1.32 {d4, d5}, [r12]
    vmul.f32 q1, q1, q2
    add     r12, sp, #128
    vld1.32 {d4, d5}, [r12]
    vmul.f32 q1, q1, q2
    vadd.f32 q0, q0, q1
    add     r12, sp, #64
    vld1.32 {d2, d3}, [r12]
    add     r12, sp, #128
    vld1.32 {d4, d5}, [r12]
    vmul.f32 q1, q1, q2
    add     r12, sp, #\tslot
    vld1.32 {d4, d5}, [r12]
    vmul.f32 q1, q1, q2
    vadd.f32 q0, q0, q1
    add     r12, sp, #144
    vld1.32 {d2, d3}, [r12]
    // 1/ao via one Newton-Raphson step (relative err ~2^-16, final
    // pixel within ±1 LSB in rare tie cases - covered by tolerance).
    // ao = 0 lanes give +Inf, masked to 0 below like the div path.
    vrecpe.f32 q2, q1
    vrecps.f32 q3, q2, q1
    vmul.f32 q2, q2, q3
    vmul.f32 q0, q0, q2
    add     r12, sp, #160
    vld1.32 {d2, d3}, [r12]
    vand    q0, q0, q1
    add     r12, sp, #\tslot
    vst1.32 {d0, d1}, [r12]
.endm

/*
 * Narrow one channel quad in its slot: *255, clamp [0,255], +0.5,
 * truncate. Requires q8 = 0.0, q9 = 0.5, q12 = 255.0.
 * Clobbers q0, r12.
 */
.macro NARROW_Q slot
    add     r12, sp, #\slot
    vld1.32 {d0, d1}, [r12]
    vmul.f32 q0, q0, q12
    vmax.f32 q0, q0, q8
    vmin.f32 q0, q0, q12
    vadd.f32 q0, q0, q9
    vcvt.s32.f32 q0, q0
    vst1.32 {d0, d1}, [r12]
.endm

/*
 * Extract one narrowed lane (full s-reg name, e.g., s0) into the pixel
 * accumulator r3 at SHIFT, with optional LUT encode through [r10].
 * Clobbers r12.
 */
.macro GET_LANE sreg, shift, enc
    vmov    r12, \sreg
    .if \enc
    ldrb    r12, [r10, r12]
    .endif
    and     r12, r12, #0xff
    orr     r3, r3, r12, lsl #\shift
.endm

/*
 * Narrow one tail lane: value in s8 (q2 lane0) through the vector
 * clamp (VFP has no scalar min/max). Requires q8 = 0.0, q9 = 0.5,
 * q12 = 255.0. Result ORRed into r3 at SHIFT, optional encode.
 * Clobbers q2, r12.
 */
.macro NARROW_TAIL shift, enc
    vmul.f32 q2, q2, q12
    vmax.f32 q2, q2, q8
    vmin.f32 q2, q2, q12
    vadd.f32 q2, q2, q9
    vcvt.s32.f32 q2, q2
    vmov    r12, s8
    .if \enc
    ldrb    r12, [r10, r12]
    .endif
    and     r12, r12, #0xff
    orr     r3, r3, r12, lsl #\shift
.endm

/*
 * Scalar shared compositing for the tail (ao > 0 guaranteed by the
 * caller's vcmp branch, so no mask). Result narrowed into r3 at
 * SHIFT. Encode table in r10 (ENC=1). Clobbers s0/s1/s2, q2, r12.
 */
.macro TAIL_COMPOSITE_ARM tslot, scslot, bcslot, shift, enc
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #128]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #\scslot]
    vmul.f32 s1, s1, s0
    vldr    s0, [sp, #64]
    vmul.f32 s1, s1, s0
    vldr    s0, [sp, #240]
    vldr    s2, [sp, #64]
    vsub.f32 s0, s0, s2
    vldr    s2, [sp, #\bcslot]
    vmul.f32 s0, s0, s2
    vldr    s2, [sp, #128]
    vmul.f32 s0, s0, s2
    vadd.f32 s1, s1, s0
    vldr    s0, [sp, #64]
    vldr    s2, [sp, #128]
    vmul.f32 s0, s0, s2
    vldr    s2, [sp, #\tslot]
    vmul.f32 s0, s0, s2
    vadd.f32 s1, s1, s0
    vldr    s0, [sp, #144]
    vdiv.f32 s1, s1, s0
    vmov    s8, s1
    NARROW_TAIL \shift, \enc
.endm

    .text
    .p2align 5
/*
 * void applyFeBlendNeon(
 *     const jint* src, const jint* dst, jint* out,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     jint mode, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * ARMv7a ABI:
 *   r0 = src, r1 = dst, r2 = out, r3 = width
 *   stack: clipLeft, clipTop, clipRight, clipBottom, mode, useLinear,
 *     srgbToLinear, linearToSrgb (one word each, in order)
 */
    .globl SYM(applyFeBlendNeon)
    TYPE(SYM(applyFeBlendNeon), %function)
SYM(applyFeBlendNeon):
    push    {r4-r11, lr}
    vpush   {d8-d15}
    sub     sp, sp, #260
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    // Row consts: 255.0 quad @224, 1.0 quad @240, 0.5 word @12.
    // @12 is bytes 12-15: outside every quad slot (quads start @16).
    movw    r12, #0x0000
    movt    r12, #0x437f
    vdup.32 q12, r12
    add     r3, sp, #224
    vst1.32 {d24, d25}, [r3]
    vmov.f32 q13, #1.0
    add     r3, sp, #240
    vst1.32 {d26, d27}, [r3]
    movw    r12, #0x0000
    movt    r12, #0x3f00
    str     r12, [sp, #12]
    // First row starts at clipTop * width + clipLeft.
    ldr     r8, [sp, #360]
    ldr     r9, [sp, #364]
    ldr     r10, [sp, #368]
    ldr     r11, [sp, #372]
    mla     r12, r9, r7, r8
    add     r4, r4, r12, lsl #2
    add     r5, r5, r12, lsl #2
    add     r6, r6, r12, lsl #2
    lsl     r7, r7, #2
    sub     r9, r11, r9
    cmp     r9, #1
    blt     .Ldone
    ldrb    r12, [sp, #380]
    cmp     r12, #0
    bne     .Llinear_rows

// ------------------------------------------------------------------
// Non-linear rows.
// ------------------------------------------------------------------
.Lnonlin_rows:
    ldr     r8, [sp, #360]
    ldr     r10, [sp, #368]
    sub     r8, r10, r8
    cmp     r8, #0
    ble     .Lrow_next_nonlin
    cmp     r9, #1
    beq     .Llast_row_nonlin
    lsr     r11, r8, #2
    and     r12, r8, #3
    str     r12, [sp, #4]
    cmp     r11, #0
    beq     .Lnonlin_tail_entry

    .p2align 4
.Lnonlin_block:
    // Block consts: q12 = 255.0, q13 = 1.0, q8 = 1/255.
    add     r12, sp, #224
    vld1.32 {d24, d25}, [r12]
    add     r12, sp, #240
    vld1.32 {d26, d27}, [r12]
    movw    r12, #0x8081
    movt    r12, #0x3b80
    vdup.32 q8, r12
    // Widen src (vld4 lanes: d0=B d1=G d2=R d3=A) into
    // A=q0 R=q1 G=q2 B=q3. Order B,G,A,R: a dest D-reg must not
    // hold an unread byte source (A->q0 kills d0/d1, so B and G
    // go first; R->q1 kills d3, so A goes before R).
    vld4.8  {d0, d1, d2, d3}, [r4]
    add     r4, r4, #16
    WIDEN_CH d0, q3
    WIDEN_CH d1, q2
    WIDEN_CH d3, q0
    WIDEN_CH d2, q1
    MUL_RECIP
    add     r12, sp, #64
    vst1.32 {d0, d1}, [r12]
    add     r12, sp, #16
    vst1.32 {d2, d3}, [r12]
    add     r12, sp, #32
    vst1.32 {d4, d5}, [r12]
    add     r12, sp, #48
    vst1.32 {d6, d7}, [r12]
    // Widen dst (same order).
    vld4.8  {d0, d1, d2, d3}, [r5]
    add     r5, r5, #16
    WIDEN_CH d0, q3
    WIDEN_CH d1, q2
    WIDEN_CH d3, q0
    WIDEN_CH d2, q1
    MUL_RECIP
    add     r12, sp, #128
    vst1.32 {d0, d1}, [r12]
    add     r12, sp, #80
    vst1.32 {d2, d3}, [r12]
    add     r12, sp, #96
    vst1.32 {d4, d5}, [r12]
    add     r12, sp, #112
    vst1.32 {d6, d7}, [r12]
    AO_MASK
    // Per-mode blend -> tR/tG/tB slots; return address in lr.
    adr     lr, .Lblk_ret_nonlin
    b       .Ldispatch_nl_blk
.Ldispatch_nl_blk:
    ldr     r8, [sp, #376]
    sub     r8, r8, #1
    adr     r10, .Ltab_nl_blk
    ldr     r12, [r10, r8, lsl #2]
    add     pc, r10, r12
.Ltab_nl_blk:
    .word   .Lblk_multiply - .Ltab_nl_blk
    .word   .Lblk_screen - .Ltab_nl_blk
    .word   .Lblk_overlay - .Ltab_nl_blk
    .word   .Lblk_darken - .Ltab_nl_blk
    .word   .Lblk_lighten - .Ltab_nl_blk
    .word   .Lblk_dodge - .Ltab_nl_blk
    .word   .Lblk_burn - .Ltab_nl_blk
    .word   .Lblk_hardlight - .Ltab_nl_blk
    .word   .Lblk_softlight - .Ltab_nl_blk
    .word   .Lblk_difference - .Ltab_nl_blk
    .word   .Lblk_exclusion - .Ltab_nl_blk
.Lblk_ret_nonlin:
    // Composite quads, then narrow + store all 4 pixels.
    COMPOSITE_ARM 176, 16, 80
    COMPOSITE_ARM 192, 32, 96
    COMPOSITE_ARM 208, 48, 112
    veor    q8, q8, q8
    ldr     r12, [sp, #12]
    vdup.32 q9, r12
    NARROW_Q 176
    NARROW_Q 192
    NARROW_Q 208
    NARROW_Q 144
    add     r12, sp, #176
    vld1.32 {d0, d1}, [r12]
    add     r12, sp, #192
    vld1.32 {d2, d3}, [r12]
    add     r12, sp, #208
    vld1.32 {d4, d5}, [r12]
    add     r12, sp, #144
    vld1.32 {d6, d7}, [r12]
    mov     r3, #0
    GET_LANE s0, 16, 0
    GET_LANE s4, 8, 0
    GET_LANE s8, 0, 0
    GET_LANE s12, 24, 0
    str     r3, [r6], #4
    mov     r3, #0
    GET_LANE s1, 16, 0
    GET_LANE s5, 8, 0
    GET_LANE s9, 0, 0
    GET_LANE s13, 24, 0
    str     r3, [r6], #4
    mov     r3, #0
    GET_LANE s2, 16, 0
    GET_LANE s6, 8, 0
    GET_LANE s10, 0, 0
    GET_LANE s14, 24, 0
    str     r3, [r6], #4
    mov     r3, #0
    GET_LANE s3, 16, 0
    GET_LANE s7, 8, 0
    GET_LANE s11, 0, 0
    GET_LANE s15, 24, 0
    str     r3, [r6], #4
    subs    r11, r11, #1
    bne     .Lnonlin_block

.Lnonlin_tail_entry:
    ldr     r11, [sp, #4]
    cmp     r11, #0
    beq     .Lrow_next_nonlin
    // Tail consts: s31 = 255.0, q12 = 255.0, q8 = 0.0, q9 = 0.5.
    movw    r12, #0x0000
    movt    r12, #0x437f
    vmov    s31, r12
    add     r12, sp, #224
    vld1.32 {d24, d25}, [r12]
    veor    q8, q8, q8
    ldr     r12, [sp, #12]
    vdup.32 q9, r12

    .p2align 4
.Lnonlin_tail_loop:
    // Scalar widen both pixels -> slots.
    TAIL_WIDEN_PIXEL r4, 16, 32, 48, 64
    TAIL_WIDEN_PIXEL r5, 80, 96, 112, 128
    TAIL_AO .Ltail0_nonlin
    adr     lr, .Ltail_ret_nonlin
    b       .Ldispatch_nl_tail
.Ldispatch_nl_tail:
    ldr     r8, [sp, #376]
    sub     r8, r8, #1
    adr     r10, .Ltab_nl_tail
    ldr     r12, [r10, r8, lsl #2]
    add     pc, r10, r12
.Ltab_nl_tail:
    .word   .Ltail_multiply - .Ltab_nl_tail
    .word   .Ltail_screen - .Ltab_nl_tail
    .word   .Ltail_overlay - .Ltab_nl_tail
    .word   .Ltail_darken - .Ltab_nl_tail
    .word   .Ltail_lighten - .Ltab_nl_tail
    .word   .Ltail_dodge - .Ltab_nl_tail
    .word   .Ltail_burn - .Ltab_nl_tail
    .word   .Ltail_hardlight - .Ltab_nl_tail
    .word   .Ltail_softlight - .Ltab_nl_tail
    .word   .Ltail_difference - .Ltab_nl_tail
    .word   .Ltail_exclusion - .Ltab_nl_tail
.Ltail_ret_nonlin:
    mov     r3, #0
    TAIL_COMPOSITE_ARM 176, 16, 80, 16, 0
    TAIL_COMPOSITE_ARM 192, 32, 96, 8, 0
    TAIL_COMPOSITE_ARM 208, 48, 112, 0, 0
    vldr    s0, [sp, #144]
    vmov    s8, s0
    NARROW_TAIL 24, 0
    str     r3, [r6], #4
    b       .Ltail_adv_nonlin
.Ltail0_nonlin:
    mov     r12, #0
    str     r12, [r6], #4
.Ltail_adv_nonlin:
    add     r4, r4, #4
    add     r5, r5, #4
    subs    r11, r11, #1
    bne     .Lnonlin_tail_loop

.Lrow_next_nonlin:
    ldr     r8, [sp, #360]
    ldr     r10, [sp, #368]
    sub     r8, r10, r8
    lsl     r8, r8, #2
    add     r4, r4, r7
    sub     r4, r4, r8
    add     r5, r5, r7
    sub     r5, r5, r8
    add     r6, r6, r7
    sub     r6, r6, r8
    subs    r9, r9, #1
    bne     .Lnonlin_rows
    b       .Ldone

// Last row goes fully scalar: vld4 would over-read past the buffer.
.Llast_row_nonlin:
    str     r8, [sp, #4]
    b       .Lnonlin_tail_entry

// ------------------------------------------------------------------
// Linear rows: LUT decode (both images) around the same core.
// ------------------------------------------------------------------
.Llinear_rows:
    ldr     r8, [sp, #360]
    ldr     r10, [sp, #368]
    sub     r8, r10, r8
    cmp     r8, #0
    ble     .Lrow_next_linear
    cmp     r9, #1
    beq     .Llast_row_linear
    lsr     r11, r8, #2
    and     r12, r8, #3
    str     r12, [sp, #4]
    cmp     r11, #0
    beq     .Llinear_tail_entry

    .p2align 4
.Llinear_block:
    // Block consts: q12 = 255.0, q13 = 1.0, q8 = 1/255 reciprocal
    // (all three survive every LUTSCAN pair and fragment).
    add     r12, sp, #224
    vld1.32 {d24, d25}, [r12]
    add     r12, sp, #240
    vld1.32 {d26, d27}, [r12]
    movw    r12, #0x8081
    movt    r12, #0x3b80
    vdup.32 q8, r12
    // Decode src packed bytes via exact LUT scans; alpha (d3) stays
    // raw (divided by 255 only, never linearized).
    ldr     r10, [sp, #384]
    vmov.i8 d31, #15
    vld4.8  {d0, d1, d2, d3}, [r4]
    add     r4, r4, #16
    veor    d4, d4, d4
    veor    d5, d5, d5
    veor    d6, d6, d6
    LUTSCAN d0, d4, r10
    LUTSCAN d1, d5, r10
    LUTSCAN d2, d6, r10
    // Widen decoded src (d6=R d5=G d4=B, d3=raw A) into
    // A=q0 R=q1 G=q2 B=q3. Order A,R,B,G: R->q1 kills d3, so A
    // goes first; B->q3 kills d6, so R goes before B; G->q2 kills
    // d4, so B goes before G. (A->q3 would kill the unread R
    // source d6 - the d6/D6/q3-low aliasing trap.)
    WIDEN_CH d3, q0
    WIDEN_CH d6, q1
    WIDEN_CH d4, q3
    WIDEN_CH d5, q2
    MUL_RECIP
    add     r12, sp, #64
    vst1.32 {d0, d1}, [r12]
    add     r12, sp, #16
    vst1.32 {d2, d3}, [r12]
    add     r12, sp, #32
    vst1.32 {d4, d5}, [r12]
    add     r12, sp, #48
    vst1.32 {d6, d7}, [r12]
    // Decode dst packed bytes the same way (r10 survives scans;
    // d31 does NOT: rebuild it, like the src side. Alpha raw.)
    ldr     r10, [sp, #384]
    vmov.i8 d31, #15
    vld4.8  {d0, d1, d2, d3}, [r5]
    add     r5, r5, #16
    veor    d4, d4, d4
    veor    d5, d5, d5
    veor    d6, d6, d6
    LUTSCAN d0, d4, r10
    LUTSCAN d1, d5, r10
    LUTSCAN d2, d6, r10
    WIDEN_CH d3, q0
    WIDEN_CH d6, q1
    WIDEN_CH d4, q3
    WIDEN_CH d5, q2
    MUL_RECIP
    add     r12, sp, #128
    vst1.32 {d0, d1}, [r12]
    add     r12, sp, #80
    vst1.32 {d2, d3}, [r12]
    add     r12, sp, #96
    vst1.32 {d4, d5}, [r12]
    add     r12, sp, #112
    vst1.32 {d6, d7}, [r12]
    AO_MASK
    adr     lr, .Lblk_ret_linear
    b       .Ldispatch_ln_blk
.Ldispatch_ln_blk:
    ldr     r8, [sp, #376]
    sub     r8, r8, #1
    adr     r10, .Ltab_ln_blk
    ldr     r12, [r10, r8, lsl #2]
    add     pc, r10, r12
.Ltab_ln_blk:
    .word   .Lblk_multiply - .Ltab_ln_blk
    .word   .Lblk_screen - .Ltab_ln_blk
    .word   .Lblk_overlay - .Ltab_ln_blk
    .word   .Lblk_darken - .Ltab_ln_blk
    .word   .Lblk_lighten - .Ltab_ln_blk
    .word   .Lblk_dodge - .Ltab_ln_blk
    .word   .Lblk_burn - .Ltab_ln_blk
    .word   .Lblk_hardlight - .Ltab_ln_blk
    .word   .Lblk_softlight - .Ltab_ln_blk
    .word   .Lblk_difference - .Ltab_ln_blk
    .word   .Lblk_exclusion - .Ltab_ln_blk
.Lblk_ret_linear:
    COMPOSITE_ARM 176, 16, 80
    COMPOSITE_ARM 192, 32, 96
    COMPOSITE_ARM 208, 48, 112
    // Encode R/G/B in place via scalar ldrb (r10 = table base).
    ldr     r10, [sp, #388]
    veor    q8, q8, q8
    ldr     r12, [sp, #12]
    vdup.32 q9, r12
    NARROW_Q 176
    NARROW_Q 192
    NARROW_Q 208
    NARROW_Q 144
    add     r12, sp, #176
    vld1.32 {d0, d1}, [r12]
    add     r12, sp, #192
    vld1.32 {d2, d3}, [r12]
    add     r12, sp, #208
    vld1.32 {d4, d5}, [r12]
    add     r12, sp, #144
    vld1.32 {d6, d7}, [r12]
    mov     r3, #0
    GET_LANE s0, 16, 1
    GET_LANE s4, 8, 1
    GET_LANE s8, 0, 1
    GET_LANE s12, 24, 0
    str     r3, [r6], #4
    mov     r3, #0
    GET_LANE s1, 16, 1
    GET_LANE s5, 8, 1
    GET_LANE s9, 0, 1
    GET_LANE s13, 24, 0
    str     r3, [r6], #4
    mov     r3, #0
    GET_LANE s2, 16, 1
    GET_LANE s6, 8, 1
    GET_LANE s10, 0, 1
    GET_LANE s14, 24, 0
    str     r3, [r6], #4
    mov     r3, #0
    GET_LANE s3, 16, 1
    GET_LANE s7, 8, 1
    GET_LANE s11, 0, 1
    GET_LANE s15, 24, 0
    str     r3, [r6], #4
    subs    r11, r11, #1
    bne     .Llinear_block

.Llinear_tail_entry:
    ldr     r11, [sp, #4]
    cmp     r11, #0
    beq     .Lrow_next_linear
    movw    r12, #0x0000
    movt    r12, #0x437f
    vmov    s31, r12
    add     r12, sp, #224
    vld1.32 {d24, d25}, [r12]
    veor    q8, q8, q8
    ldr     r12, [sp, #12]
    vdup.32 q9, r12

    .p2align 4
.Llinear_tail_loop:
    // Scalar widen with LUT decode (r10 = decode table).
    ldr     r10, [sp, #384]
    TAIL_DECODE_PIXEL r4, 16, 32, 48, 64
    TAIL_DECODE_PIXEL r5, 80, 96, 112, 128
    TAIL_AO .Ltail0_linear
    adr     lr, .Ltail_ret_linear
    b       .Ldispatch_ln_tail
.Ldispatch_ln_tail:
    ldr     r8, [sp, #376]
    sub     r8, r8, #1
    adr     r10, .Ltab_ln_tail
    ldr     r12, [r10, r8, lsl #2]
    add     pc, r10, r12
.Ltab_ln_tail:
    .word   .Ltail_multiply - .Ltab_ln_tail
    .word   .Ltail_screen - .Ltab_ln_tail
    .word   .Ltail_overlay - .Ltab_ln_tail
    .word   .Ltail_darken - .Ltab_ln_tail
    .word   .Ltail_lighten - .Ltab_ln_tail
    .word   .Ltail_dodge - .Ltab_ln_tail
    .word   .Ltail_burn - .Ltab_ln_tail
    .word   .Ltail_hardlight - .Ltab_ln_tail
    .word   .Ltail_softlight - .Ltab_ln_tail
    .word   .Ltail_difference - .Ltab_ln_tail
    .word   .Ltail_exclusion - .Ltab_ln_tail
.Ltail_ret_linear:
    // NOTE: dispatch reused r10 as table base: reload encode table.
    ldr     r10, [sp, #388]
    mov     r3, #0
    TAIL_COMPOSITE_ARM 176, 16, 80, 16, 1
    TAIL_COMPOSITE_ARM 192, 32, 96, 8, 1
    TAIL_COMPOSITE_ARM 208, 48, 112, 0, 1
    vldr    s0, [sp, #144]
    vmov    s8, s0
    NARROW_TAIL 24, 0
    str     r3, [r6], #4
    b       .Ltail_adv_linear
.Ltail0_linear:
    mov     r12, #0
    str     r12, [r6], #4
.Ltail_adv_linear:
    add     r4, r4, #4
    add     r5, r5, #4
    subs    r11, r11, #1
    bne     .Llinear_tail_loop

.Lrow_next_linear:
    ldr     r8, [sp, #360]
    ldr     r10, [sp, #368]
    sub     r8, r10, r8
    lsl     r8, r8, #2
    add     r4, r4, r7
    sub     r4, r4, r8
    add     r5, r5, r7
    sub     r5, r5, r8
    add     r6, r6, r7
    sub     r6, r6, r8
    subs    r9, r9, #1
    bne     .Llinear_rows
    b       .Ldone

.Llast_row_linear:
    str     r8, [sp, #4]
    b       .Llinear_tail_entry

// ------------------------------------------------------------------
// Per-mode blend fragments (vector, 4-wide). In: quads sr@16 sg@32
// sb@48 br@80 bg@96 bb@112. Out: quads tR@176 tG@192 tB@208, result
// always in q0 at store time. Temps q0-q3/q8/q9; q13 = 1.0 (read
// only); q12 = 255.0 untouched. Return address in lr.
// ------------------------------------------------------------------
    .p2align 4
.Lblk_multiply:
    LD_CB_CS 80, 16
    vmul.f32 q0, q0, q1
    ST_T    176
    LD_CB_CS 96, 32
    vmul.f32 q0, q0, q1
    ST_T    192
    LD_CB_CS 112, 48
    vmul.f32 q0, q0, q1
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_screen:
    // t = (cb+cs) - cb*cs.
    LD_CB_CS 80, 16
    vmul.f32 q2, q0, q1
    vadd.f32 q0, q0, q1
    vsub.f32 q0, q0, q2
    ST_T    176
    LD_CB_CS 96, 32
    vmul.f32 q2, q0, q1
    vadd.f32 q0, q0, q1
    vsub.f32 q0, q0, q2
    ST_T    192
    LD_CB_CS 112, 48
    vmul.f32 q2, q0, q1
    vadd.f32 q0, q0, q1
    vsub.f32 q0, q0, q2
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_overlay:
    // t = cb<=0.5 ? (2*cb)*cs : 1-((2*(1-cb))*(1-cs)).
    // mask = (0.5 >= cb); LO arm under mask-TRUE (scalar takes LO
    // when cb<=0.5).
    LD_CB_CS 80, 16
    vmov.f32 q8, #0.5
    vcge.f32 q2, q8, q0
    vmov.f32 q8, #2.0
    vmul.f32 q3, q0, q8
    vmul.f32 q3, q3, q1
    vsub.f32 q9, q13, q0
    vmul.f32 q9, q9, q8
    vsub.f32 q8, q13, q1
    vmul.f32 q9, q9, q8
    vsub.f32 q9, q13, q9
    vand    q3, q3, q2
    vbic    q9, q9, q2
    vorr    q0, q3, q9
    ST_T    176
    LD_CB_CS 96, 32
    vmov.f32 q8, #0.5
    vcge.f32 q2, q8, q0
    vmov.f32 q8, #2.0
    vmul.f32 q3, q0, q8
    vmul.f32 q3, q3, q1
    vsub.f32 q9, q13, q0
    vmul.f32 q9, q9, q8
    vsub.f32 q8, q13, q1
    vmul.f32 q9, q9, q8
    vsub.f32 q9, q13, q9
    vand    q3, q3, q2
    vbic    q9, q9, q2
    vorr    q0, q3, q9
    ST_T    192
    LD_CB_CS 112, 48
    vmov.f32 q8, #0.5
    vcge.f32 q2, q8, q0
    vmov.f32 q8, #2.0
    vmul.f32 q3, q0, q8
    vmul.f32 q3, q3, q1
    vsub.f32 q9, q13, q0
    vmul.f32 q9, q9, q8
    vsub.f32 q8, q13, q1
    vmul.f32 q9, q9, q8
    vsub.f32 q9, q13, q9
    vand    q3, q3, q2
    vbic    q9, q9, q2
    vorr    q0, q3, q9
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_darken:
    // t = cb<cs ? cb : cs (mask = (cs>cb)).
    LD_CB_CS 80, 16
    vcgt.f32 q2, q1, q0
    vand    q0, q0, q2
    vbic    q1, q1, q2
    vorr    q0, q0, q1
    ST_T    176
    LD_CB_CS 96, 32
    vcgt.f32 q2, q1, q0
    vand    q0, q0, q2
    vbic    q1, q1, q2
    vorr    q0, q0, q1
    ST_T    192
    LD_CB_CS 112, 48
    vcgt.f32 q2, q1, q0
    vand    q0, q0, q2
    vbic    q1, q1, q2
    vorr    q0, q0, q1
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_lighten:
    // t = cb>cs ? cb : cs (mask = (cb>cs)).
    LD_CB_CS 80, 16
    vcgt.f32 q2, q0, q1
    vand    q0, q0, q2
    vbic    q1, q1, q2
    vorr    q0, q0, q1
    ST_T    176
    LD_CB_CS 96, 32
    vcgt.f32 q2, q0, q1
    vand    q0, q0, q2
    vbic    q1, q1, q2
    vorr    q0, q0, q1
    ST_T    192
    LD_CB_CS 112, 48
    vcgt.f32 q2, q0, q1
    vand    q0, q0, q2
    vbic    q1, q1, q2
    vorr    q0, q0, q1
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_dodge:
    // v = min(cb/(1-cs), 1); cs>=1 -> 1; cb==0 -> 0 (LAST, wins).
    LD_CB_CS 80, 16
    vsub.f32 q2, q13, q1
    vrecpe.f32 q3, q2
    vrecps.f32 q8, q3, q2
    vmul.f32 q3, q3, q8
    vmul.f32 q2, q0, q3
    vmin.f32 q2, q2, q13
    vcge.f32 q3, q1, q13
    vand    q8, q13, q3
    vbic    q2, q2, q3
    vorr    q2, q2, q8
    vceq.f32 q3, q0, #0
    vmvn    q3, q3
    vand    q2, q2, q3
    vmov    q0, q2
    ST_T    176
    LD_CB_CS 96, 32
    vsub.f32 q2, q13, q1
    vrecpe.f32 q3, q2
    vrecps.f32 q8, q3, q2
    vmul.f32 q3, q3, q8
    vmul.f32 q2, q0, q3
    vmin.f32 q2, q2, q13
    vcge.f32 q3, q1, q13
    vand    q8, q13, q3
    vbic    q2, q2, q3
    vorr    q2, q2, q8
    vceq.f32 q3, q0, #0
    vmvn    q3, q3
    vand    q2, q2, q3
    vmov    q0, q2
    ST_T    192
    LD_CB_CS 112, 48
    vsub.f32 q2, q13, q1
    vrecpe.f32 q3, q2
    vrecps.f32 q8, q3, q2
    vmul.f32 q3, q3, q8
    vmul.f32 q2, q0, q3
    vmin.f32 q2, q2, q13
    vcge.f32 q3, q1, q13
    vand    q8, q13, q3
    vbic    q2, q2, q3
    vorr    q2, q2, q8
    vceq.f32 q3, q0, #0
    vmvn    q3, q3
    vand    q2, q2, q3
    vmov    q0, q2
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_burn:
    // v = 1-min((1-cb)/cs, 1); cs<=0 -> 0 (keep where cs>0);
    // cb>=1 -> 1 (LAST, wins).
    LD_CB_CS 80, 16
    vsub.f32 q2, q13, q0
    vrecpe.f32 q3, q1
    vrecps.f32 q8, q3, q1
    vmul.f32 q3, q3, q8
    vmul.f32 q2, q2, q3
    vmin.f32 q2, q2, q13
    vsub.f32 q2, q13, q2
    vcgt.f32 q3, q1, #0
    vand    q2, q2, q3
    vcge.f32 q3, q0, q13
    vand    q8, q13, q3
    vbic    q2, q2, q3
    vorr    q2, q2, q8
    vmov    q0, q2
    ST_T    176
    LD_CB_CS 96, 32
    vsub.f32 q2, q13, q0
    vrecpe.f32 q3, q1
    vrecps.f32 q8, q3, q1
    vmul.f32 q3, q3, q8
    vmul.f32 q2, q2, q3
    vmin.f32 q2, q2, q13
    vsub.f32 q2, q13, q2
    vcgt.f32 q3, q1, #0
    vand    q2, q2, q3
    vcge.f32 q3, q0, q13
    vand    q8, q13, q3
    vbic    q2, q2, q3
    vorr    q2, q2, q8
    vmov    q0, q2
    ST_T    192
    LD_CB_CS 112, 48
    vsub.f32 q2, q13, q0
    vrecpe.f32 q3, q1
    vrecps.f32 q8, q3, q1
    vmul.f32 q3, q3, q8
    vmul.f32 q2, q2, q3
    vmin.f32 q2, q2, q13
    vsub.f32 q2, q13, q2
    vcgt.f32 q3, q1, #0
    vand    q2, q2, q3
    vcge.f32 q3, q0, q13
    vand    q8, q13, q3
    vbic    q2, q2, q3
    vorr    q2, q2, q8
    vmov    q0, q2
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_hardlight:
    // t = cs<=0.5 ? (2*cs)*cb : 1-((2*(1-cs))*(1-cb)).
    // mask = (0.5 >= cs); LO arm under mask-TRUE.
    LD_CB_CS 80, 16
    vmov.f32 q8, #0.5
    vcge.f32 q2, q8, q1
    vmov.f32 q8, #2.0
    vsub.f32 q3, q13, q1
    vmul.f32 q3, q3, q8
    vsub.f32 q9, q13, q0
    vmul.f32 q3, q3, q9
    vsub.f32 q3, q13, q3
    vmul.f32 q9, q1, q8
    vmul.f32 q0, q9, q0
    vand    q0, q0, q2
    vbic    q3, q3, q2
    vorr    q0, q0, q3
    ST_T    176
    LD_CB_CS 96, 32
    vmov.f32 q8, #0.5
    vcge.f32 q2, q8, q1
    vmov.f32 q8, #2.0
    vsub.f32 q3, q13, q1
    vmul.f32 q3, q3, q8
    vsub.f32 q9, q13, q0
    vmul.f32 q3, q3, q9
    vsub.f32 q3, q13, q3
    vmul.f32 q9, q1, q8
    vmul.f32 q0, q9, q0
    vand    q0, q0, q2
    vbic    q3, q3, q2
    vorr    q0, q0, q3
    ST_T    192
    LD_CB_CS 112, 48
    vmov.f32 q8, #0.5
    vcge.f32 q2, q8, q1
    vmov.f32 q8, #2.0
    vsub.f32 q3, q13, q1
    vmul.f32 q3, q3, q8
    vsub.f32 q9, q13, q0
    vmul.f32 q3, q3, q9
    vsub.f32 q3, q13, q3
    vmul.f32 q9, q1, q8
    vmul.f32 q0, q9, q0
    vand    q0, q0, q2
    vbic    q3, q3, q2
    vorr    q0, q0, q3
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_softlight:
    // d = cb<=0.25 ? ((16*cb-12)*cb+4)*cb : sqrtf(cb) (single
    // precision; double rounding can differ in the last bit, covered
    // by the neon32 maxDelta=1 tolerance);
    // t = cb+((2*cs)-1)*(d-cb).
    LD_CB_CS 80, 16
    vmov.f32 q9, #0.25
    vcge.f32 q3, q9, q0
    vmov.f32 q9, #16.0
    vmul.f32 q2, q0, q9
    vmov.f32 q9, #12.0
    vsub.f32 q2, q2, q9
    vmul.f32 q2, q2, q0
    vmov.f32 q9, #4.0
    vadd.f32 q2, q2, q9
    vmul.f32 q2, q2, q0
    vsqrt.f32 s16, s0
    vsqrt.f32 s17, s1
    vsqrt.f32 s18, s2
    vsqrt.f32 s19, s3
    vand    q2, q2, q3
    vbic    q4, q4, q3
    vorr    q2, q2, q4
    vmov.f32 q8, #2.0
    vmul.f32 q8, q1, q8
    vsub.f32 q8, q8, q13
    vsub.f32 q9, q2, q0
    vmul.f32 q8, q8, q9
    vadd.f32 q0, q0, q8
    ST_T    176
    LD_CB_CS 96, 32
    vmov.f32 q9, #0.25
    vcge.f32 q3, q9, q0
    vmov.f32 q9, #16.0
    vmul.f32 q2, q0, q9
    vmov.f32 q9, #12.0
    vsub.f32 q2, q2, q9
    vmul.f32 q2, q2, q0
    vmov.f32 q9, #4.0
    vadd.f32 q2, q2, q9
    vmul.f32 q2, q2, q0
    vsqrt.f32 s16, s0
    vsqrt.f32 s17, s1
    vsqrt.f32 s18, s2
    vsqrt.f32 s19, s3
    vand    q2, q2, q3
    vbic    q4, q4, q3
    vorr    q2, q2, q4
    vmov.f32 q8, #2.0
    vmul.f32 q8, q1, q8
    vsub.f32 q8, q8, q13
    vsub.f32 q9, q2, q0
    vmul.f32 q8, q8, q9
    vadd.f32 q0, q0, q8
    ST_T    192
    LD_CB_CS 112, 48
    vmov.f32 q9, #0.25
    vcge.f32 q3, q9, q0
    vmov.f32 q9, #16.0
    vmul.f32 q2, q0, q9
    vmov.f32 q9, #12.0
    vsub.f32 q2, q2, q9
    vmul.f32 q2, q2, q0
    vmov.f32 q9, #4.0
    vadd.f32 q2, q2, q9
    vmul.f32 q2, q2, q0
    vsqrt.f32 s16, s0
    vsqrt.f32 s17, s1
    vsqrt.f32 s18, s2
    vsqrt.f32 s19, s3
    vand    q2, q2, q3
    vbic    q4, q4, q3
    vorr    q2, q2, q4
    vmov.f32 q8, #2.0
    vmul.f32 q8, q1, q8
    vsub.f32 q8, q8, q13
    vsub.f32 q9, q2, q0
    vmul.f32 q8, q8, q9
    vadd.f32 q0, q0, q8
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_difference:
    // t = |cb-cs|.
    LD_CB_CS 80, 16
    vsub.f32 q0, q0, q1
    vabs.f32 q0, q0
    ST_T    176
    LD_CB_CS 96, 32
    vsub.f32 q0, q0, q1
    vabs.f32 q0, q0
    ST_T    192
    LD_CB_CS 112, 48
    vsub.f32 q0, q0, q1
    vabs.f32 q0, q0
    ST_T    208
    bx      lr

    .p2align 4
.Lblk_exclusion:
    // t = (cb+cs) - (2*cb)*cs.
    LD_CB_CS 80, 16
    vadd.f32 q2, q0, q1
    vmov.f32 q8, #2.0
    vmul.f32 q3, q0, q8
    vmul.f32 q3, q3, q1
    vsub.f32 q0, q2, q3
    ST_T    176
    LD_CB_CS 96, 32
    vadd.f32 q2, q0, q1
    vmul.f32 q3, q0, q8
    vmul.f32 q3, q3, q1
    vsub.f32 q0, q2, q3
    ST_T    192
    LD_CB_CS 112, 48
    vadd.f32 q2, q0, q1
    vmul.f32 q3, q0, q8
    vmul.f32 q3, q3, q1
    vsub.f32 q0, q2, q3
    ST_T    208
    bx      lr

// ------------------------------------------------------------------
// Per-mode blend fragments (scalar tail). In: lane-0 channels in
// slots. Out: lane-0 tR@176 tG@192 tB@208. Scratch s0/s1/s2/s3,
// d28 (soft-light double), r12 (bit temps only). Return address in
// lr. FP branches mirror the C++ scalar exactly (vcmp + vmrs;
// <= is bls, < is bmi, >= is bge, > is bgt).
// ------------------------------------------------------------------
    .p2align 4
.Ltail_multiply:
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #16]
    vmul.f32 s0, s0, s1
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #32]
    vmul.f32 s0, s0, s1
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #48]
    vmul.f32 s0, s0, s1
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_screen:
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #16]
    vadd.f32 s2, s0, s1
    vmul.f32 s0, s0, s1
    vsub.f32 s0, s2, s0
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #32]
    vadd.f32 s2, s0, s1
    vmul.f32 s0, s0, s1
    vsub.f32 s0, s2, s0
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #48]
    vadd.f32 s2, s0, s1
    vmul.f32 s0, s0, s1
    vsub.f32 s0, s2, s0
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_overlay:
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #12]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_ov_r_lo
    vldr    s1, [sp, #240]
    vldr    s2, [sp, #80]
    vsub.f32 s1, s1, s2
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #240]
    vldr    s0, [sp, #16]
    vsub.f32 s2, s2, s0
    vmul.f32 s1, s1, s2
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_ov_r_done
.Ltn_ov_r_lo:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s0, s0, s1
    vldr    s1, [sp, #16]
    vmul.f32 s0, s0, s1
.Ltn_ov_r_done:
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #12]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_ov_g_lo
    vldr    s1, [sp, #240]
    vldr    s2, [sp, #96]
    vsub.f32 s1, s1, s2
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #240]
    vldr    s0, [sp, #32]
    vsub.f32 s2, s2, s0
    vmul.f32 s1, s1, s2
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_ov_g_done
.Ltn_ov_g_lo:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s0, s0, s1
    vldr    s1, [sp, #32]
    vmul.f32 s0, s0, s1
.Ltn_ov_g_done:
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #12]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_ov_b_lo
    vldr    s1, [sp, #240]
    vldr    s2, [sp, #112]
    vsub.f32 s1, s1, s2
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #240]
    vldr    s0, [sp, #48]
    vsub.f32 s2, s2, s0
    vmul.f32 s1, s1, s2
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_ov_b_done
.Ltn_ov_b_lo:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s0, s0, s1
    vldr    s1, [sp, #48]
    vmul.f32 s0, s0, s1
.Ltn_ov_b_done:
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_darken:
    // t = cb<cs ? cb : cs.
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #16]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bmi     .Ltn_dk_r_keep
    vmov    s0, s1
.Ltn_dk_r_keep:
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #32]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bmi     .Ltn_dk_g_keep
    vmov    s0, s1
.Ltn_dk_g_keep:
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #48]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bmi     .Ltn_dk_b_keep
    vmov    s0, s1
.Ltn_dk_b_keep:
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_lighten:
    // t = cb>cs ? cb : cs.
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #16]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bgt     .Ltn_lt_r_keep
    vmov    s0, s1
.Ltn_lt_r_keep:
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #32]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bgt     .Ltn_lt_g_keep
    vmov    s0, s1
.Ltn_lt_g_keep:
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #48]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bgt     .Ltn_lt_b_keep
    vmov    s0, s1
.Ltn_lt_b_keep:
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_dodge:
    // cb==0 -> 0; cs>=1 -> 1; else min(cb/(1-cs), 1).
    vldr    s0, [sp, #80]
    mov     r12, #0
    vmov    s1, r12
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    beq     .Ltn_dg_r_zero
    vldr    s0, [sp, #16]
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bge     .Ltn_dg_r_one
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #16]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #80]
    vdiv.f32 s0, s0, s1
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_dg_r_done
    vmov    s0, s1
    b       .Ltn_dg_r_done
.Ltn_dg_r_zero:
    mov     r12, #0
    vmov    s0, r12
    b       .Ltn_dg_r_done
.Ltn_dg_r_one:
    vldr    s0, [sp, #240]
.Ltn_dg_r_done:
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    mov     r12, #0
    vmov    s1, r12
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    beq     .Ltn_dg_g_zero
    vldr    s0, [sp, #32]
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bge     .Ltn_dg_g_one
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #32]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #96]
    vdiv.f32 s0, s0, s1
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_dg_g_done
    vmov    s0, s1
    b       .Ltn_dg_g_done
.Ltn_dg_g_zero:
    mov     r12, #0
    vmov    s0, r12
    b       .Ltn_dg_g_done
.Ltn_dg_g_one:
    vldr    s0, [sp, #240]
.Ltn_dg_g_done:
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    mov     r12, #0
    vmov    s1, r12
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    beq     .Ltn_dg_b_zero
    vldr    s0, [sp, #48]
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bge     .Ltn_dg_b_one
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #48]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #112]
    vdiv.f32 s0, s0, s1
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_dg_b_done
    vmov    s0, s1
    b       .Ltn_dg_b_done
.Ltn_dg_b_zero:
    mov     r12, #0
    vmov    s0, r12
    b       .Ltn_dg_b_done
.Ltn_dg_b_one:
    vldr    s0, [sp, #240]
.Ltn_dg_b_done:
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_burn:
    // cb>=1 -> 1; cs<=0 -> 0; else 1-min((1-cb)/cs, 1).
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bge     .Ltn_bn_r_one
    vldr    s0, [sp, #16]
    mov     r12, #0
    vmov    s1, r12
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_bn_r_zero
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #80]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #16]
    vdiv.f32 s1, s1, s0
    vldr    s0, [sp, #240]
    vcmp.f32 s1, s0
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_bn_r_min
    vmov    s1, s0
.Ltn_bn_r_min:
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_bn_r_done
.Ltn_bn_r_one:
    vldr    s0, [sp, #240]
    b       .Ltn_bn_r_done
.Ltn_bn_r_zero:
    mov     r12, #0
    vmov    s0, r12
.Ltn_bn_r_done:
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bge     .Ltn_bn_g_one
    vldr    s0, [sp, #32]
    mov     r12, #0
    vmov    s1, r12
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_bn_g_zero
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #96]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #32]
    vdiv.f32 s1, s1, s0
    vldr    s0, [sp, #240]
    vcmp.f32 s1, s0
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_bn_g_min
    vmov    s1, s0
.Ltn_bn_g_min:
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_bn_g_done
.Ltn_bn_g_one:
    vldr    s0, [sp, #240]
    b       .Ltn_bn_g_done
.Ltn_bn_g_zero:
    mov     r12, #0
    vmov    s0, r12
.Ltn_bn_g_done:
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #240]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bge     .Ltn_bn_b_one
    vldr    s0, [sp, #48]
    mov     r12, #0
    vmov    s1, r12
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_bn_b_zero
    vldr    s1, [sp, #240]
    vldr    s0, [sp, #112]
    vsub.f32 s1, s1, s0
    vldr    s0, [sp, #48]
    vdiv.f32 s1, s1, s0
    vldr    s0, [sp, #240]
    vcmp.f32 s1, s0
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_bn_b_min
    vmov    s1, s0
.Ltn_bn_b_min:
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_bn_b_done
.Ltn_bn_b_one:
    vldr    s0, [sp, #240]
    b       .Ltn_bn_b_done
.Ltn_bn_b_zero:
    mov     r12, #0
    vmov    s0, r12
.Ltn_bn_b_done:
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_hardlight:
    vldr    s0, [sp, #16]
    vldr    s1, [sp, #12]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_hl_r_lo
    vldr    s1, [sp, #240]
    vldr    s2, [sp, #16]
    vsub.f32 s1, s1, s2
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #240]
    vldr    s0, [sp, #80]
    vsub.f32 s2, s2, s0
    vmul.f32 s1, s1, s2
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_hl_r_done
.Ltn_hl_r_lo:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s0, s0, s1
    vldr    s1, [sp, #80]
    vmul.f32 s0, s0, s1
.Ltn_hl_r_done:
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #32]
    vldr    s1, [sp, #12]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_hl_g_lo
    vldr    s1, [sp, #240]
    vldr    s2, [sp, #32]
    vsub.f32 s1, s1, s2
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #240]
    vldr    s0, [sp, #96]
    vsub.f32 s2, s2, s0
    vmul.f32 s1, s1, s2
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_hl_g_done
.Ltn_hl_g_lo:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s0, s0, s1
    vldr    s1, [sp, #96]
    vmul.f32 s0, s0, s1
.Ltn_hl_g_done:
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #48]
    vldr    s1, [sp, #12]
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_hl_b_lo
    vldr    s1, [sp, #240]
    vldr    s2, [sp, #48]
    vsub.f32 s1, s1, s2
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #240]
    vldr    s0, [sp, #112]
    vsub.f32 s2, s2, s0
    vmul.f32 s1, s1, s2
    vldr    s0, [sp, #240]
    vsub.f32 s0, s0, s1
    b       .Ltn_hl_b_done
.Ltn_hl_b_lo:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s0, s0, s1
    vldr    s1, [sp, #112]
    vmul.f32 s0, s0, s1
.Ltn_hl_b_done:
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_softlight:
    // d = cb<=0.25 ? poly : sqrtf(cb) (single precision, see the
    // block fragment); then t = cb + ((2*cs)-1)*(d-cb). r12 is
    // bit-temp only.
    vldr    s0, [sp, #80]
    vmov.f32 s1, #0.25
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_sl_r_poly
    vsqrt.f32 s0, s0
    b       .Ltn_sl_r_ddone
.Ltn_sl_r_poly:
    vmov.f32 s1, #16.0
    vmul.f32 s0, s0, s1
    vmov.f32 s1, #12.0
    vsub.f32 s0, s0, s1
    vldr    s1, [sp, #80]
    vmul.f32 s0, s0, s1
    vmov.f32 s1, #4.0
    vadd.f32 s0, s0, s1
    vldr    s1, [sp, #80]
    vmul.f32 s0, s0, s1
.Ltn_sl_r_ddone:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #16]
    vmul.f32 s1, s1, s2
    vldr    s2, [sp, #240]
    vsub.f32 s1, s1, s2
    vldr    s2, [sp, #80]
    vsub.f32 s0, s0, s2
    vmul.f32 s1, s1, s0
    vadd.f32 s0, s2, s1
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vmov.f32 s1, #0.25
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_sl_g_poly
    vsqrt.f32 s0, s0
    b       .Ltn_sl_g_ddone
.Ltn_sl_g_poly:
    vmov.f32 s1, #16.0
    vmul.f32 s0, s0, s1
    vmov.f32 s1, #12.0
    vsub.f32 s0, s0, s1
    vldr    s1, [sp, #96]
    vmul.f32 s0, s0, s1
    vmov.f32 s1, #4.0
    vadd.f32 s0, s0, s1
    vldr    s1, [sp, #96]
    vmul.f32 s0, s0, s1
.Ltn_sl_g_ddone:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #32]
    vmul.f32 s1, s1, s2
    vldr    s2, [sp, #240]
    vsub.f32 s1, s1, s2
    vldr    s2, [sp, #96]
    vsub.f32 s0, s0, s2
    vmul.f32 s1, s1, s0
    vadd.f32 s0, s2, s1
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vmov.f32 s1, #0.25
    vcmp.f32 s0, s1
    vmrs    APSR_nzcv, fpscr
    bls     .Ltn_sl_b_poly
    vsqrt.f32 s0, s0
    b       .Ltn_sl_b_ddone
.Ltn_sl_b_poly:
    vmov.f32 s1, #16.0
    vmul.f32 s0, s0, s1
    vmov.f32 s1, #12.0
    vsub.f32 s0, s0, s1
    vldr    s1, [sp, #112]
    vmul.f32 s0, s0, s1
    vmov.f32 s1, #4.0
    vadd.f32 s0, s0, s1
    vldr    s1, [sp, #112]
    vmul.f32 s0, s0, s1
.Ltn_sl_b_ddone:
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vldr    s2, [sp, #48]
    vmul.f32 s1, s1, s2
    vldr    s2, [sp, #240]
    vsub.f32 s1, s1, s2
    vldr    s2, [sp, #112]
    vsub.f32 s0, s0, s2
    vmul.f32 s1, s1, s0
    vadd.f32 s0, s2, s1
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_difference:
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #16]
    vsub.f32 s0, s0, s1
    vabs.f32 s0, s0
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #32]
    vsub.f32 s0, s0, s1
    vabs.f32 s0, s0
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #48]
    vsub.f32 s0, s0, s1
    vabs.f32 s0, s0
    vstr    s0, [sp, #208]
    bx      lr

    .p2align 4
.Ltail_exclusion:
    vldr    s0, [sp, #80]
    vldr    s1, [sp, #16]
    vadd.f32 s2, s0, s1
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s1, s0, s1
    vldr    s0, [sp, #16]
    vmul.f32 s1, s1, s0
    vsub.f32 s0, s2, s1
    vstr    s0, [sp, #176]
    vldr    s0, [sp, #96]
    vldr    s1, [sp, #32]
    vadd.f32 s2, s0, s1
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s1, s0, s1
    vldr    s0, [sp, #32]
    vmul.f32 s1, s1, s0
    vsub.f32 s0, s2, s1
    vstr    s0, [sp, #192]
    vldr    s0, [sp, #112]
    vldr    s1, [sp, #48]
    vadd.f32 s2, s0, s1
    vldr    s1, [sp, #240]
    vadd.f32 s1, s1, s1
    vmul.f32 s1, s0, s1
    vldr    s0, [sp, #48]
    vmul.f32 s1, s1, s0
    vsub.f32 s0, s2, s1
    vstr    s0, [sp, #208]
    bx      lr

.Ldone:
    add     sp, sp, #260
    vpop    {d8-d15}
    pop     {r4-r11, pc}

    SIZE(SYM(applyFeBlendNeon))
    GNU_STACK
