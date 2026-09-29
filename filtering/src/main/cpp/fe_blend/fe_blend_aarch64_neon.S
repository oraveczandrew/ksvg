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
 * AArch64 / NEON64 implementation of feBlend, separable modes (1..11).
 * Bit-exact twin of KotlinKernels.feBlend / fe_blend.cpp scalar:
 * same FP op order (fdiv by 255, left-to-right evaluation, no FMA),
 * same LUT folding, same clamp255 (+0.5, truncate via fcvtzs — NEVER
 * round-to-nearest). Alpha never linearized. Non-separable modes
 * (12..15) never reach this function: the C++ dispatcher routes them
 * to scalar (FEBLEND_PORT_PLAN).
 *
 * 4px blocks, exact 16B loads/stores (ld4.4b consumes exactly what it
 * loads; odd widths go through the scalar tail). `mode` is constant
 * per call: one jump table (32-bit self-relative .word diffs + adr/
 * ldrsw/add/br — no GOT, no TEXTREL) selects the per-mode blend
 * fragment per block (and a second table for the scalar tail).
 *
 * Spill design: widened channels live in named stack slots (x86 twin
 * layout); every fragment is load-compute-store through v0-v5, with
 * v6 = 255.0 and v7 = 1.0 rebuilt per block AND after every LUT256
 * pair (the macro clobbers v4-v7; fragments themselves reload v6
 * with 1.0 for their own selects). The dst alpha mask in v2 is
 * rebuilt after the src widen chain for the same reason. v8-v15
 * are never touched (no d8-d15 spill); v16-v31 hold the linear LUT
 * tables only. x9-x17 are all caller-saved (no GPR spill). Loads
 * and stores never affect FP bit-exactness. No literal pool: every
 * constant is built (movi/fmov/movz) or spilled per row.
 *
 * Parity traps handled here (see FEBLEND_PORT_PLAN for the full list):
 * - darken/lighten/overlay/hard-light use compare+select that mirrors
 *   the scalar ternary EXACTLY (never fmax/fmin: NaN semantics differ).
 *   Selects are and/bic/or triples (bic needs no all-ones constant);
 *   bsl(Vd,Vn,Vm) = (Vd&Vn)|(~Vd&Vm) with the mask in Vd (the
 *   arithmetic LUT256 macro is the in-tree proof).
 * - color-dodge/burn compute the division on all lanes, so the 0/0 lane
 *   (cb==0 && cs==1, resp. cb==1 && cs==0) is forced explicitly
 *   (edge masks: mvn for keep-where-nonzero, fcmgt for keep-where-
 *   positive); the scalar guard-branch order decides which mask wins.
 *   Never rely on (int)NaN (C++ UB) for these lanes.
 * - soft-light D(cb) is a correctly-rounded DOUBLE sqrt narrowed to
 *   float (kotlin.math.sqrt(Float) semantics): fcvtl -> fsqrt d-reg
 *   -> fcvtn, per 2-lane half. A single-precision fsqrt is
 *   parity-wrong by construction (double rounding).
 * - aoAlpha <= 0 forces a zero pixel via an (ao > 0) mask ANDed AFTER
 *   the compositing division (div-by-zero lanes produce inf/NaN, which
 *   never fault and are masked away).
 * - AArch64 fsub/fdiv/fcmp/fcmXX follow listed order (Dd = N OP M);
 *   every non-commutative op below is commented with its scalar source.
 * - EXT immediate range follows the ARRANGEMENT, not the register:
 *   `ext Vd.8b, Vn.8b, Vm.8b, #8` is OUT OF RANGE (0-7) and NDK clang
 *   assembles it WITHOUT error as #0 (silent truncation — found via
 *   llvm-objdump after the soft-light/linear hi-half failures). All
 *   hi-half extracts here are therefore `ext Vd.16b, Vn.16b, Vm.16b,
 *   #8` (range 0-15); only the low 8 bytes are consumed downstream.
 *   (The `fcmle Vd.4s, Vn.4s, Vm.4s` register form is only a clang
 *   alias — clang canonicalizes it to `fcmge` with swapped operands —
 *   but GNU as rejects it, so this file spells the `fcmge` form
 *   everywhere for host (GCC) + NDK (clang) + QEMU-guest compatibility.)
 *
 * Stack frame: sub sp, sp, #256 (AArch64 SP stays 16B-aligned).
 * Stack args (8B PCS slots — NOT packed: the C++ caller stores mode
 * with `str w` @0, useLinear with `strb` @8, the tables with `str x`
 * @16/@24; verified against the compiled runForced call site):
 * mode @256 (w), useLinear @264 (b), srgbToLinear @272 (x),
 * linearToSrgb @280 (x).
 * Scratch slots: rowsLeft @0 (w), tail @4 (w), blocks @8 (w),
 *   constHalf @12 (w; NOTE: must NOT share the constOne quad —
 *   a word store @248 would clobber its lane 2, see below),
 *   sr/sg/sb/as @16/32/48/64, br/bg/bb/ab @80/96/112/128,
 *   ao @144, aoMask @160, tR/tG/tB @176/192/208,
 *   const255 @224 (q), constOne @240 (q).
 * Registers: x9/x10/x11 = src/dst/out cursors, x12 = row stride,
 * x13-x17 = temps, x14 = fragment return address.
 * v0-v5 = fragment temps; v6 = 255.0, v7 = 1.0 (per block);
 * v16-v31 = linear LUT tables.
 */

#include "asm_macros.S"

/*
 * Lookup 8 bytes in a 256-byte table resident in v16..v31.
 * (Copied verbatim from color_matrix_aarch64_neon.S: same contract.)
 * Input:  vIn (8b)
 * Output: vOut (8b)
 * Clobbers v4, v5, v6, v7, v14, v15.
 * Requires v12 to be mask #63.
 */
.macro LUT256 vIn, vOut
    and     v15.8b, \vIn\().8b, v12.8b   /* v12 = 63 */
    ushr    v14.8b, \vIn\().8b, #6        /* bank index 0..3 */

    tbl     v4.8b, {v16.16b-v19.16b}, v15.8b
    tbl     v5.8b, {v20.16b-v23.16b}, v15.8b
    tbl     v6.8b, {v24.16b-v27.16b}, v15.8b
    tbl     v7.8b, {v28.16b-v31.16b}, v15.8b

    movi    v15.8b, #2
    cmeq    v15.8b, v14.8b, v15.8b
    bsl     v15.8b, v6.8b, v7.8b     /* (bank==2)? v6 : v7 */

    movi    v7.8b, #1
    cmeq    v7.8b, v14.8b, v7.8b
    bsl     v7.8b, v5.8b, v15.8b     /* (bank==1)? v5 : v15 */

    movi    v15.8b, #0
    cmeq    v15.8b, v14.8b, v15.8b
    bsl     v15.8b, v4.8b, v7.8b      /* (bank==0)? v4 : v7 */

    mov     \vOut\().8b, v15.8b
.endm

/*
 * Widen 4 packed bytes (low 4B of vIn, via ld4.4b) to a float quad,
 * dividing by v6 (= 255.0, rebuilt per block). Upper garbage lanes of
 * vIn are ignored. Clobbers v5.
 */
.macro WIDEN4 vIn, vOut
    uxtl    v5.8h, \vIn\().8b
    uxtl    \vOut\().4s, v5.4h
    ucvtf   \vOut\().4s, \vOut\().4s
    fdiv    \vOut\().4s, \vOut\().4s, v6.4s
.endm

/*
 * Shared per-channel compositing into the tR/tG/tB slot.
 * Scalar equivalent (fe_blend.cpp):
 *   o = ((1-ab)*cs*as + (1-as)*cb*ab + as*ab*t) / ao; ao<=0 -> 0.
 * Clobbers v0, v1. v6 = 255.0 NOT used here (this is pre-narrow);
 * constOne comes from [sp, #240]. Slots hold quads.
 */
.macro COMPOSITE tslot, scslot, bcslot
    ldr     q0, [sp, #240]
    ldr     q1, [sp, #128]
    fsub    v0.4s, v0.4s, v1.4s
    ldr     q1, [sp, #\scslot]
    fmul    v0.4s, v0.4s, v1.4s
    ldr     q1, [sp, #64]
    fmul    v0.4s, v0.4s, v1.4s
    ldr     q1, [sp, #240]
    ldr     q2, [sp, #64]
    fsub    v1.4s, v1.4s, v2.4s
    ldr     q2, [sp, #\bcslot]
    fmul    v1.4s, v1.4s, v2.4s
    ldr     q2, [sp, #128]
    fmul    v1.4s, v1.4s, v2.4s
    fadd    v0.4s, v0.4s, v1.4s
    ldr     q1, [sp, #64]
    ldr     q2, [sp, #128]
    fmul    v1.4s, v1.4s, v2.4s
    ldr     q2, [sp, #\tslot]
    fmul    v1.4s, v1.4s, v2.4s
    fadd    v0.4s, v0.4s, v1.4s
    ldr     q1, [sp, #144]
    fdiv    v0.4s, v0.4s, v1.4s
    ldr     q1, [sp, #160]
    and     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #\tslot]
.endm

/*
 * Narrow + store one output pixel (lane LANE of the R/G/B composite
 * quads in 176/192/208 and of ao in 144) to [x11], #4 (the caller
 * post-indexes x11 after every pixel, so the macro itself must NOT
 * store to LANE*4(x11): with the advancing cursor that address is
 * base+2*LANE*4, whose lane-2/lane-3 writes land in the NEXT block —
 * past row end for the last block — and corrupt out-of-clip pixels).
 * Matches clamp255(): *255, clamp [0,255], +0.5, truncate (fcvtzs).
 * ENC=1: encode R/G/B through the table at x15 (w index); alpha is
 * never encoded. Scalar SISD ops (fcvtzs w = truncate, like cvtt).
 * Clobbers s0/s1, w0, w acc in w13. Pass bare numbers for LANE.
 */
.macro STORE_PIXEL64 lane, enc
    fmov    s2, wzr
    ldr     s0, [sp, #(176+\lane*4)]
    ldr     s1, [sp, #224]
    fmul    s0, s0, s1
    fmax    s0, s0, s2
    fmin    s0, s0, s1
    ldr     s1, [sp, #12]
    fadd    s0, s0, s1
    fcvtzs  w0, s0
    .if \enc
    ldrb    w0, [x15, w0, uxtw]
    .endif
    and     w0, w0, #0xff
    orr     w13, w13, w0, lsl #16
    ldr     s0, [sp, #(192+\lane*4)]
    ldr     s1, [sp, #224]
    fmul    s0, s0, s1
    fmax    s0, s0, s2
    fmin    s0, s0, s1
    ldr     s1, [sp, #12]
    fadd    s0, s0, s1
    fcvtzs  w0, s0
    .if \enc
    ldrb    w0, [x15, w0, uxtw]
    .endif
    and     w0, w0, #0xff
    orr     w13, w13, w0, lsl #8
    ldr     s0, [sp, #(208+\lane*4)]
    ldr     s1, [sp, #224]
    fmul    s0, s0, s1
    fmax    s0, s0, s2
    fmin    s0, s0, s1
    ldr     s1, [sp, #12]
    fadd    s0, s0, s1
    fcvtzs  w0, s0
    .if \enc
    ldrb    w0, [x15, w0, uxtw]
    .endif
    and     w0, w0, #0xff
    orr     w13, w13, w0
    ldr     s0, [sp, #(144+\lane*4)]
    ldr     s1, [sp, #224]
    fmul    s0, s0, s1
    fmax    s0, s0, s2
    fmin    s0, s0, s1
    ldr     s1, [sp, #12]
    fadd    s0, s0, s1
    fcvtzs  w0, s0
    and     w0, w0, #0xff
    orr     w13, w13, w0, lsl #24
.endm

/*
 * Scalar shared compositing for the tail. Same formula as COMPOSITE;
 * ao > 0 is guaranteed by the caller's fcmp branch, so no mask.
 * Result narrowed into w13 at bit SHIFT. Encode table in x15 (ENC=1).
 * Clobbers s0/s1/s2, w0.
 */
.macro TAIL_COMPOSITE64 tslot, scslot, bcslot, shift, enc
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #128]
    fsub    s1, s1, s0
    ldr     s0, [sp, #\scslot]
    fmul    s1, s1, s0
    ldr     s0, [sp, #64]
    fmul    s1, s1, s0
    ldr     s0, [sp, #240]
    ldr     s2, [sp, #64]
    fsub    s0, s0, s2
    ldr     s2, [sp, #\bcslot]
    fmul    s0, s0, s2
    ldr     s2, [sp, #128]
    fmul    s0, s0, s2
    fadd    s1, s1, s0
    ldr     s0, [sp, #64]
    ldr     s2, [sp, #128]
    fmul    s0, s0, s2
    ldr     s2, [sp, #\tslot]
    fmul    s0, s0, s2
    fadd    s1, s1, s0
    ldr     s0, [sp, #144]
    fdiv    s1, s1, s0
    ldr     s0, [sp, #224]
    fmul    s1, s1, s0
    fmov    s3, wzr
    fmax    s1, s1, s3
    fmin    s1, s1, s0
    ldr     s0, [sp, #12]
    fadd    s1, s1, s0
    fcvtzs  w0, s1
    .if \enc
    ldrb    w0, [x15, w0, uxtw]
    .endif
    and     w0, w0, #0xff
    orr     w13, w13, w0, lsl #\shift
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
 * AArch64 ABI:
 *   x0 = src, x1 = dst, x2 = out, w3 = width,
 *   w4 = clipLeft, w5 = clipTop, w6 = clipRight, w7 = clipBottom
 *   stack: mode (w), useLinear (w), srgbToLinear (x), linearToSrgb (x)
 */
.globl SYM(applyFeBlendNeon)
TYPE(SYM(applyFeBlendNeon), @function)
SYM(applyFeBlendNeon):
    sub     sp, sp, #256
    mov     x9, x0                   /* src cursor */
    mov     x10, x1                  /* dst cursor */
    mov     x11, x2                  /* out cursor */
    /* First row starts at clipTop * width + clipLeft. */
    smaddl  x13, w5, w3, xzr
    add     x13, x13, w4, uxtw
    add     x9, x9, x13, lsl #2
    add     x10, x10, x13, lsl #2
    add     x11, x11, x13, lsl #2
    lsl     x12, x3, #2              /* row stride = width * 4 */
    /* rows = clipBottom - clipTop; empty clip: nothing to do. */
    sub     w14, w7, w5
    cbz     w14, .Ldone
    str     w14, [sp, #0]            /* persistent rows left */
    /* Row consts: 255.0 @224, one @240, half @248. */
    movz    w14, #0x0000
    movk    w14, #0x437f, lsl #16
    fmov    s0, w14
    dup     v0.4s, v0.s[0]
    str     q0, [sp, #224]
    fmov    v0.4s, #1.0
    str     q0, [sp, #240]
    movz    w14, #0x0000
    movk    w14, #0x3f00, lsl #16
    fmov    s0, w14
    str     s0, [sp, #12]

    ldrb    w14, [sp, #264]          /* useLinear (ldrb: upper bytes void) */
    cbnz    w14, .Llinear_rows

/* ------------------------------------------------------------------ */
/* Non-linear rows.                                                    */
/* ------------------------------------------------------------------ */
.Lnonlin_rows:
    sub     w13, w6, w4              /* count = clipRight - clipLeft */
    cbz     w13, .Lrow_next_nonlin   /* empty-width clip: skip the row */
    lsr     w14, w13, #2             /* blocks */
    and     w15, w13, #3
    str     w15, [sp, #4]            /* tail pixels */
    str     w14, [sp, #8]            /* blocks */

    cbz     w14, .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    /* Block consts v6 = 255.0, v7 = 1.0 (rebuilt every block;
       fragments reload v6 with 1.0 internally). */
    movz    w13, #0x0000
    movk    w13, #0x437f, lsl #16
    fmov    s6, w13
    dup     v6.4s, v6.s[0]
    fmov    v7.4s, #1.0
    /* Widen src -> sr/sg/sb/as slots (ld4.4b de-interleaves B,G,R,A). */
    ldr     d0, [x9]
    ldr     d1, [x9, #8]
    add     x9, x9, #16
    uzp1    v2.8b, v0.8b, v1.8b
    uzp2    v3.8b, v0.8b, v1.8b
    uzp1    v4.8b, v2.8b, v2.8b
    uzp2    v0.8b, v2.8b, v2.8b
    uzp1    v2.8b, v3.8b, v3.8b
    uzp2    v3.8b, v3.8b, v3.8b
    WIDEN4  v4, v1
    str     q1, [sp, #48]
    WIDEN4  v2, v1
    str     q1, [sp, #32]
    WIDEN4  v0, v1
    str     q1, [sp, #16]
    WIDEN4  v3, v1
    str     q1, [sp, #64]
    /* Widen dst -> br/bg/bb/ab slots. */
    ldr     d0, [x10]
    ldr     d1, [x10, #8]
    add     x10, x10, #16
    uzp1    v2.8b, v0.8b, v1.8b
    uzp2    v3.8b, v0.8b, v1.8b
    uzp1    v4.8b, v2.8b, v2.8b
    uzp2    v0.8b, v2.8b, v2.8b
    uzp1    v2.8b, v3.8b, v3.8b
    uzp2    v3.8b, v3.8b, v3.8b
    WIDEN4  v4, v1
    str     q1, [sp, #112]
    WIDEN4  v2, v1
    str     q1, [sp, #96]
    WIDEN4  v0, v1
    str     q1, [sp, #80]
    WIDEN4  v3, v1
    str     q1, [sp, #128]
    /* ao = (as+ab) - as*ab; mask = (ao > 0). */
    ldr     q0, [sp, #64]
    ldr     q1, [sp, #128]
    fmul    v2.4s, v0.4s, v1.4s
    fadd    v0.4s, v0.4s, v1.4s
    fsub    v0.4s, v0.4s, v2.4s
    str     q0, [sp, #144]
    fcmgt   v1.4s, v0.4s, #0.0
    str     q1, [sp, #160]

    /* Per-mode blend -> tR/tG/tB slots; return address in x14. */
    adr     x14, .Lblk_ret_nonlin
    ldr     w15, [sp, #256]          /* mode */
    sub     w15, w15, #1
    adr     x16, .Lblk_tab
    ldrsw   x17, [x16, w15, uxtw #2]
    add     x16, x16, x17
    br      x16
.Lblk_ret_nonlin:
    /* Composite quads, then narrow + store all 4 pixels. */
    COMPOSITE 176, 16, 80
    COMPOSITE 192, 32, 96
    COMPOSITE 208, 48, 112
    mov     w13, #0
    STORE_PIXEL64 0, 0
    str     w13, [x11], #4
    mov     w13, #0
    STORE_PIXEL64 1, 0
    str     w13, [x11], #4
    mov     w13, #0
    STORE_PIXEL64 2, 0
    str     w13, [x11], #4
    mov     w13, #0
    STORE_PIXEL64 3, 0
    str     w13, [x11], #4

    ldr     w14, [sp, #8]
    sub     w14, w14, #1
    str     w14, [sp, #8]
    cbnz    w14, .Lnonlin_block

.Lnonlin_tail:
    ldr     w13, [sp, #4]
    cbz     w13, .Lrow_next_nonlin

.Lnonlin_tail_loop:
    /* Scalar widen both pixels -> slots (255.0 via slot const). */
    ldr     w14, [x9]
    ubfx    w15, w14, #16, #8
    ucvtf   s0, w15
    ldr     s1, [sp, #224]
    fdiv    s0, s0, s1
    str     s0, [sp, #16]
    ubfx    w15, w14, #8, #8
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #32]
    and     w15, w14, #0xff
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #48]
    lsr     w15, w14, #24
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #64]
    ldr     w14, [x10]
    ubfx    w15, w14, #16, #8
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #80]
    ubfx    w15, w14, #8, #8
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #96]
    and     w15, w14, #0xff
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #112]
    lsr     w15, w14, #24
    ucvtf   s0, w15
    fdiv    s0, s0, s1
    str     s0, [sp, #128]
    /* ao = (as+ab) - as*ab; ao <= 0 -> zero pixel. */
    ldr     s0, [sp, #64]
    ldr     s1, [sp, #128]
    fmul    s2, s0, s1
    fadd    s0, s0, s1
    fsub    s0, s0, s2
    str     s0, [sp, #144]
    fcmp    s0, #0.0
    ble     .Ltail_zero_nonlin

    adr     x14, .Ltail_ret_nonlin
    ldr     w15, [sp, #256]
    sub     w15, w15, #1
    adr     x16, .Ltail_tab
    ldrsw   x17, [x16, w15, uxtw #2]
    add     x16, x16, x17
    br      x16
.Ltail_ret_nonlin:
    mov     w13, #0
    TAIL_COMPOSITE64 176, 16, 80, 16, 0
    TAIL_COMPOSITE64 192, 32, 96, 8, 0
    TAIL_COMPOSITE64 208, 48, 112, 0, 0
    ldr     s0, [sp, #144]
    ldr     s1, [sp, #224]
    fmul    s0, s0, s1
    fmov    s3, wzr
    fmax    s0, s0, s3
    fmin    s0, s0, s1
    ldr     s1, [sp, #12]
    fadd    s0, s0, s1
    fcvtzs  w0, s0
    and     w0, w0, #0xff
    orr     w13, w13, w0, lsl #24
    str     w13, [x11], #4
    b       .Ltail_advance_nonlin
.Ltail_zero_nonlin:
    str     wzr, [x11], #4
.Ltail_advance_nonlin:
    add     x9, x9, #4
    add     x10, x10, #4
    ldr     w13, [sp, #4]
    sub     w13, w13, #1
    str     w13, [sp, #4]
    cbnz    w13, .Lnonlin_tail_loop

.Lrow_next_nonlin:
    sub     w13, w6, w4
    lsl     x13, x13, #2
    add     x9, x9, x12
    sub     x9, x9, x13
    add     x10, x10, x12
    sub     x10, x10, x13
    add     x11, x11, x12
    sub     x11, x11, x13
    ldr     w14, [sp, #0]
    sub     w14, w14, #1
    str     w14, [sp, #0]
    cbnz    w14, .Lnonlin_rows
    b       .Ldone

/* ------------------------------------------------------------------ */
/* Linear rows: LUT decode (both images) around the same core.         */
/* Tables live in v16-v31 (one 256B table at a time); the decoded     */
/* packed bytes go through ld4 + WIDEN4 like the non-linear path.     */
/* ------------------------------------------------------------------ */
.Llinear_rows:
    sub     w13, w6, w4
    cbz     w13, .Lrow_next_linear
    lsr     w14, w13, #2
    and     w15, w13, #3
    str     w15, [sp, #4]
    str     w14, [sp, #8]

    cbz     w14, .Llinear_tail

.p2align 4
.Llinear_block:
    /* Block consts (rebuilt again after each LUT256 pair, which
       clobbers v6/v7; blend fragments reload v6 with 1.0 for
       their own use, so nothing below assumes v6 survives them). */
    ldr     q6, [sp, #224]
    ldr     q7, [sp, #240]
    /* Load srgbToLinear into v16-v31 (4 x 64B post-indexed). */
    ldr     x15, [sp, #272]
    ld1     {v16.16b-v19.16b}, [x15], #64
    ld1     {v20.16b-v23.16b}, [x15], #64
    ld1     {v24.16b-v27.16b}, [x15], #64
    ld1     {v28.16b-v31.16b}, [x15], #64
    movi    v12.8b, #63
    /* Decode src packed bytes (16B); alpha saved first, restored after. */
    ld1     {v0.16b}, [x9]
    movi    v2.4s, #0xff, lsl #24
    and     v3.16b, v0.16b, v2.16b
    ext     v1.16b, v0.16b, v0.16b, #8
    LUT256  v0, v0
    LUT256  v1, v1
    bic     v0.8b, v0.8b, v2.8b
    orr     v0.8b, v0.8b, v3.8b
    ext     v4.16b, v3.16b, v3.16b, #8
    bic     v1.8b, v1.8b, v2.8b
    orr     v1.8b, v1.8b, v4.8b
    /* LUT256 clobbered v6/v7 (see macro): rebuild consts before WIDEN4. */
    ldr     q6, [sp, #224]
    ldr     q7, [sp, #240]
    /* De-interleave decoded src (v0=lo, v1=hi) + widen. */
    uzp1    v2.8b, v0.8b, v1.8b
    uzp2    v3.8b, v0.8b, v1.8b
    uzp1    v4.8b, v2.8b, v2.8b
    uzp2    v0.8b, v2.8b, v2.8b
    uzp1    v2.8b, v3.8b, v3.8b
    uzp2    v1.8b, v3.8b, v3.8b
    WIDEN4  v4, v3
    str     q3, [sp, #48]
    WIDEN4  v2, v3
    str     q3, [sp, #32]
    WIDEN4  v0, v3
    str     q3, [sp, #16]
    WIDEN4  v1, v3
    str     q3, [sp, #64]
    /* Decode dst packed bytes the same way. */
    ld1     {v0.16b}, [x10]
    /* v2 mask died in the src uzp/WIDEN chain: rebuild before use. */
    movi    v2.4s, #0xff, lsl #24
    and     v3.16b, v0.16b, v2.16b
    ext     v1.16b, v0.16b, v0.16b, #8
    LUT256  v0, v0
    LUT256  v1, v1
    bic     v0.8b, v0.8b, v2.8b
    orr     v0.8b, v0.8b, v3.8b
    ext     v4.16b, v3.16b, v3.16b, #8
    bic     v1.8b, v1.8b, v2.8b
    orr     v1.8b, v1.8b, v4.8b
    /* LUT256 clobbered v6/v7 again: rebuild consts before WIDEN4. */
    ldr     q6, [sp, #224]
    ldr     q7, [sp, #240]
    /* De-interleave (v0=lo, v1=hi) + widen. B=v4 G=v2 R=v0 A=v1. */
    uzp1    v2.8b, v0.8b, v1.8b
    uzp2    v3.8b, v0.8b, v1.8b
    uzp1    v4.8b, v2.8b, v2.8b
    uzp2    v0.8b, v2.8b, v2.8b
    uzp1    v2.8b, v3.8b, v3.8b
    uzp2    v1.8b, v3.8b, v3.8b
    WIDEN4  v4, v3
    str     q3, [sp, #112]
    WIDEN4  v2, v3
    str     q3, [sp, #96]
    WIDEN4  v0, v3
    str     q3, [sp, #80]
    WIDEN4  v1, v3
    str     q3, [sp, #128]
    /* ao = (as+ab) - as*ab; mask = (ao > 0). */
    ldr     q0, [sp, #64]
    ldr     q1, [sp, #128]
    fmul    v2.4s, v0.4s, v1.4s
    fadd    v0.4s, v0.4s, v1.4s
    fsub    v0.4s, v0.4s, v2.4s
    str     q0, [sp, #144]
    fcmgt   v1.4s, v0.4s, #0.0
    str     q1, [sp, #160]

    adr     x14, .Lblk_ret_linear
    ldr     w15, [sp, #256]
    sub     w15, w15, #1
    adr     x16, .Lblk_tab
    ldrsw   x17, [x16, w15, uxtw #2]
    add     x16, x16, x17
    br      x16
.Lblk_ret_linear:
    COMPOSITE 176, 16, 80
    COMPOSITE 192, 32, 96
    COMPOSITE 208, 48, 112
    /* Encode R/G/B in place via scalar ldrb (x15 = table base). */
    ldr     x15, [sp, #280]
    mov     w13, #0
    STORE_PIXEL64 0, 1
    str     w13, [x11], #4
    mov     w13, #0
    STORE_PIXEL64 1, 1
    str     w13, [x11], #4
    mov     w13, #0
    STORE_PIXEL64 2, 1
    str     w13, [x11], #4
    mov     w13, #0
    STORE_PIXEL64 3, 1
    str     w13, [x11], #4

    add     x9, x9, #16
    add     x10, x10, #16
    ldr     w14, [sp, #8]
    sub     w14, w14, #1
    str     w14, [sp, #8]
    cbnz    w14, .Llinear_block

.Llinear_tail:
    ldr     w13, [sp, #4]
    cbz     w13, .Lrow_next_linear

.Llinear_tail_loop:
    /* Scalar widen with LUT decode (x15 = table base, reloaded per pixel;
       w13 counter and x9/x10/x11 cursors preserved throughout). */
    ldr     x15, [sp, #272]
    ldr     w14, [x9]
    and     w16, w14, #0xff
    ldrb    w16, [x15, w16, uxtw]
    ucvtf   s0, w16
    ldr     s1, [sp, #224]
    fdiv    s0, s0, s1
    str     s0, [sp, #48]
    ubfx    w16, w14, #8, #8
    ldrb    w16, [x15, w16, uxtw]
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #32]
    ubfx    w16, w14, #16, #8
    ldrb    w16, [x15, w16, uxtw]
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #16]
    lsr     w16, w14, #24
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #64]
    ldr     w14, [x10]
    and     w16, w14, #0xff
    ldrb    w16, [x15, w16, uxtw]
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #112]
    ubfx    w16, w14, #8, #8
    ldrb    w16, [x15, w16, uxtw]
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #96]
    ubfx    w16, w14, #16, #8
    ldrb    w16, [x15, w16, uxtw]
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #80]
    lsr     w16, w14, #24
    ucvtf   s0, w16
    fdiv    s0, s0, s1
    str     s0, [sp, #128]
    ldr     s0, [sp, #64]
    ldr     s1, [sp, #128]
    fmul    s2, s0, s1
    fadd    s0, s0, s1
    fsub    s0, s0, s2
    str     s0, [sp, #144]
    fcmp    s0, #0.0
    bls     .Ltail_zero_linear
    /* Encode table owns x15 for the narrow below. */
    ldr     x15, [sp, #280]

    adr     x14, .Ltail_ret_linear
    ldr     w16, [sp, #256]
    sub     w16, w16, #1
    adr     x17, .Ltail_tab
    ldrsw   x16, [x17, w16, uxtw #2]
    add     x17, x17, x16
    br      x17
.Ltail_ret_linear:
    mov     w13, #0
    TAIL_COMPOSITE64 176, 16, 80, 16, 1
    TAIL_COMPOSITE64 192, 32, 96, 8, 1
    TAIL_COMPOSITE64 208, 48, 112, 0, 1
    ldr     s0, [sp, #144]
    ldr     s1, [sp, #224]
    fmul    s0, s0, s1
    fmov    s3, wzr
    fmax    s0, s0, s3
    fmin    s0, s0, s1
    ldr     s1, [sp, #12]
    fadd    s0, s0, s1
    fcvtzs  w0, s0
    and     w0, w0, #0xff
    orr     w13, w13, w0, lsl #24
    str     w13, [x11], #4
    b       .Ltail_advance_linear
.Ltail_zero_linear:
    str     wzr, [x11], #4
.Ltail_advance_linear:
    add     x9, x9, #4
    add     x10, x10, #4
    ldr     w13, [sp, #4]
    sub     w13, w13, #1
    str     w13, [sp, #4]
    cbnz    w13, .Llinear_tail_loop

.Lrow_next_linear:
    sub     w13, w6, w4
    lsl     x13, x13, #2
    add     x9, x9, x12
    sub     x9, x9, x13
    add     x10, x10, x12
    sub     x10, x10, x13
    add     x11, x11, x12
    sub     x11, x11, x13
    ldr     w14, [sp, #0]
    sub     w14, w14, #1
    str     w14, [sp, #0]
    cbnz    w14, .Llinear_rows
    b       .Ldone

/* ------------------------------------------------------------------ */
/* Per-mode blend fragments (vector, 4-wide). In: quads sr@16 sg@32  */
/* sb@48 br@80 bg@96 bb@112. Out: tR@176 tG@192 tB@208. Temps v0-v5; */
/* v6/v7 arrive as 255.0/1.0 but fragments reload v6 with 1.0 for   */
/* their own selects (v7 untouched). Selects are and/bic/or        */
/* triples mirroring the scalar ternaries exactly.                 */
/* Return address in x14.                                             */
/* ------------------------------------------------------------------ */
.p2align 4
.Lblk_multiply:
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fmul    v0.4s, v0.4s, v1.4s
    str     q0, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fmul    v0.4s, v0.4s, v1.4s
    str     q0, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fmul    v0.4s, v0.4s, v1.4s
    str     q0, [sp, #208]
    br      x14

.p2align 4
.Lblk_screen:
    /* t = (cb+cs) - cb*cs. */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fadd    v2.4s, v0.4s, v1.4s
    fmul    v3.4s, v0.4s, v1.4s
    fsub    v2.4s, v2.4s, v3.4s
    str     q2, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fadd    v2.4s, v0.4s, v1.4s
    fmul    v3.4s, v0.4s, v1.4s
    fsub    v2.4s, v2.4s, v3.4s
    str     q2, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fadd    v2.4s, v0.4s, v1.4s
    fmul    v3.4s, v0.4s, v1.4s
    fsub    v2.4s, v2.4s, v3.4s
    str     q2, [sp, #208]
    br      x14

.p2align 4
.Lblk_overlay:
    /* t = cb<=0.5 ? (2*cb)*cs : 1-((2*(1-cb))*(1-cs)). */
    ldr     q6, [sp, #240]
    fmov    v5.4s, #0.5
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fcmge   v4.4s, v5.4s, v0.4s
    fmov    v5.4s, #2.0
    fmul    v2.4s, v0.4s, v5.4s
    fmul    v2.4s, v2.4s, v1.4s
    fsub    v3.4s, v6.4s, v0.4s
    fmul    v3.4s, v3.4s, v5.4s
    fsub    v5.4s, v6.4s, v1.4s
    fmul    v3.4s, v3.4s, v5.4s
    fsub    v3.4s, v6.4s, v3.4s
    and     v2.16b, v2.16b, v4.16b
    bic     v3.16b, v3.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    str     q2, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fmov    v5.4s, #0.5
    fcmge   v4.4s, v5.4s, v0.4s
    fmov    v5.4s, #2.0
    fmul    v2.4s, v0.4s, v5.4s
    fmul    v2.4s, v2.4s, v1.4s
    fsub    v3.4s, v6.4s, v0.4s
    fmul    v3.4s, v3.4s, v5.4s
    fsub    v5.4s, v6.4s, v1.4s
    fmul    v3.4s, v3.4s, v5.4s
    fsub    v3.4s, v6.4s, v3.4s
    and     v2.16b, v2.16b, v4.16b
    bic     v3.16b, v3.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    str     q2, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fmov    v5.4s, #0.5
    fcmge   v4.4s, v5.4s, v0.4s
    fmov    v5.4s, #2.0
    fmul    v2.4s, v0.4s, v5.4s
    fmul    v2.4s, v2.4s, v1.4s
    fsub    v3.4s, v6.4s, v0.4s
    fmul    v3.4s, v3.4s, v5.4s
    fsub    v5.4s, v6.4s, v1.4s
    fmul    v3.4s, v3.4s, v5.4s
    fsub    v3.4s, v6.4s, v3.4s
    and     v2.16b, v2.16b, v4.16b
    bic     v3.16b, v3.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    str     q2, [sp, #208]
    br      x14

.p2align 4
.Lblk_darken:
    /* t = cb<cs ? cb : cs. */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fcmgt   v4.4s, v1.4s, v0.4s
    and     v0.16b, v0.16b, v4.16b
    bic     v1.16b, v1.16b, v4.16b
    orr     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fcmgt   v4.4s, v1.4s, v0.4s
    and     v0.16b, v0.16b, v4.16b
    bic     v1.16b, v1.16b, v4.16b
    orr     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fcmgt   v4.4s, v1.4s, v0.4s
    and     v0.16b, v0.16b, v4.16b
    bic     v1.16b, v1.16b, v4.16b
    orr     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #208]
    br      x14

.p2align 4
.Lblk_lighten:
    /* t = cb>cs ? cb : cs (mask = (cb>cs)). */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fcmgt   v4.4s, v0.4s, v1.4s
    and     v0.16b, v0.16b, v4.16b
    bic     v1.16b, v1.16b, v4.16b
    orr     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fcmgt   v4.4s, v0.4s, v1.4s
    and     v0.16b, v0.16b, v4.16b
    bic     v1.16b, v1.16b, v4.16b
    orr     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fcmgt   v4.4s, v0.4s, v1.4s
    and     v0.16b, v0.16b, v4.16b
    bic     v1.16b, v1.16b, v4.16b
    orr     v0.16b, v0.16b, v1.16b
    str     q0, [sp, #208]
    br      x14

.p2align 4
.Lblk_dodge:
    /* v = min(cb/(1-cs), 1); cs>=1 -> 1; cb==0 -> 0 (LAST, wins). */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fsub    v2.4s, v6.4s, v1.4s
    fdiv    v2.4s, v0.4s, v2.4s
    fmin    v2.4s, v2.4s, v6.4s
    fcmge   v4.4s, v1.4s, v6.4s
    and     v3.16b, v6.16b, v4.16b
    bic     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    fcmeq   v4.4s, v0.4s, #0.0
    mvn     v4.16b, v4.16b
    and     v2.16b, v2.16b, v4.16b
    str     q2, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fsub    v2.4s, v6.4s, v1.4s
    fdiv    v2.4s, v0.4s, v2.4s
    fmin    v2.4s, v2.4s, v6.4s
    fcmge   v4.4s, v1.4s, v6.4s
    and     v3.16b, v6.16b, v4.16b
    bic     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    fcmeq   v4.4s, v0.4s, #0.0
    mvn     v4.16b, v4.16b
    and     v2.16b, v2.16b, v4.16b
    str     q2, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fsub    v2.4s, v6.4s, v1.4s
    fdiv    v2.4s, v0.4s, v2.4s
    fmin    v2.4s, v6.4s, v2.4s
    fcmge   v4.4s, v1.4s, v6.4s
    and     v3.16b, v6.16b, v4.16b
    bic     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    fcmeq   v4.4s, v0.4s, #0.0
    mvn     v4.16b, v4.16b
    and     v2.16b, v2.16b, v4.16b
    str     q2, [sp, #208]
    br      x14

.p2align 4
.Lblk_burn:
    /* v = 1-min((1-cb)/cs, 1); cs<=0 -> 0 (keep where cs>0); cb>=1 -> 1. */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fsub    v2.4s, v6.4s, v0.4s
    fdiv    v2.4s, v2.4s, v1.4s
    fmin    v2.4s, v2.4s, v6.4s
    fsub    v2.4s, v6.4s, v2.4s
    fcmgt   v4.4s, v1.4s, #0.0
    and     v2.16b, v2.16b, v4.16b
    fcmge   v4.4s, v0.4s, v6.4s
    and     v3.16b, v6.16b, v4.16b
    bic     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    str     q2, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fsub    v2.4s, v6.4s, v0.4s
    fdiv    v2.4s, v2.4s, v1.4s
    fmin    v2.4s, v2.4s, v6.4s
    fsub    v2.4s, v6.4s, v2.4s
    fcmgt   v4.4s, v1.4s, #0.0
    and     v2.16b, v2.16b, v4.16b
    fcmge   v4.4s, v0.4s, v6.4s
    and     v3.16b, v6.16b, v4.16b
    bic     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    str     q2, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fsub    v2.4s, v6.4s, v0.4s
    fdiv    v2.4s, v2.4s, v1.4s
    fmin    v2.4s, v2.4s, v6.4s
    fsub    v2.4s, v6.4s, v2.4s
    fcmgt   v4.4s, v1.4s, #0.0
    and     v2.16b, v2.16b, v4.16b
    fcmge   v4.4s, v0.4s, v6.4s
    and     v3.16b, v6.16b, v4.16b
    bic     v2.16b, v2.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    str     q2, [sp, #208]
    br      x14

.p2align 4
.Lblk_hardlight:
    /* t = cs<=0.5 ? (2*cs)*cb : 1-((2*(1-cs))*(1-cb)). */
    ldr     q6, [sp, #240]
    fmov    v5.4s, #0.5
    fmov    v3.4s, #2.0
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fcmge   v4.4s, v5.4s, v1.4s
    fmul    v2.4s, v1.4s, v3.4s
    fmul    v2.4s, v2.4s, v0.4s
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fsub    v0.4s, v6.4s, v0.4s
    fsub    v1.4s, v6.4s, v1.4s
    fmul    v0.4s, v0.4s, v3.4s
    fmul    v0.4s, v0.4s, v1.4s
    fsub    v0.4s, v6.4s, v0.4s
    and     v2.16b, v2.16b, v4.16b
    bic     v0.16b, v0.16b, v4.16b
    orr     v2.16b, v2.16b, v0.16b
    str     q2, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fcmge   v4.4s, v5.4s, v1.4s
    fmul    v2.4s, v1.4s, v3.4s
    fmul    v2.4s, v2.4s, v0.4s
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fsub    v0.4s, v6.4s, v0.4s
    fsub    v1.4s, v6.4s, v1.4s
    fmul    v0.4s, v0.4s, v3.4s
    fmul    v0.4s, v0.4s, v1.4s
    fsub    v0.4s, v6.4s, v0.4s
    and     v2.16b, v2.16b, v4.16b
    bic     v0.16b, v0.16b, v4.16b
    orr     v2.16b, v2.16b, v0.16b
    str     q2, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fcmge   v4.4s, v5.4s, v1.4s
    fmul    v2.4s, v1.4s, v3.4s
    fmul    v2.4s, v2.4s, v0.4s
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fsub    v0.4s, v6.4s, v0.4s
    fsub    v1.4s, v6.4s, v1.4s
    fmul    v0.4s, v0.4s, v3.4s
    fmul    v0.4s, v0.4s, v1.4s
    fsub    v0.4s, v6.4s, v0.4s
    and     v2.16b, v2.16b, v4.16b
    bic     v0.16b, v0.16b, v4.16b
    orr     v2.16b, v2.16b, v0.16b
    str     q2, [sp, #208]
    br      x14

.p2align 4
.Lblk_softlight:
    /* d = cb<=0.25 ? ((16*cb-12)*cb+4)*cb : (float)sqrt((double)cb),
       per 2-lane half (fcvtl/fsqrt/fcvtn + mov d[1]);
       t = cb + ((2*cs)-1)*(d-cb). */
    ldr     q6, [sp, #240]
    fmov    v5.4s, #0.25
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fcmge   v4.4s, v5.4s, v0.4s
    movz    w13, #0x0000
    movk    w13, #0x4180, lsl #16
    fmov    s5, w13
    dup     v5.4s, v5.s[0]
    fmul    v2.4s, v0.4s, v5.4s
    movz    w13, #0x0000
    movk    w13, #0x4140, lsl #16
    fmov    s5, w13
    dup     v5.4s, v5.s[0]
    fsub    v2.4s, v2.4s, v5.4s
    fmul    v2.4s, v2.4s, v0.4s
    fmov    v5.4s, #4.0
    fadd    v2.4s, v2.4s, v5.4s
    fmul    v2.4s, v2.4s, v0.4s
    fcvtl   v3.2d, v0.2s
    fsqrt  v3.2d, v3.2d
    fcvtn   v3.2s, v3.2d
    ext     v5.16b, v0.16b, v0.16b, #8
    fcvtl   v0.2d, v5.2s
    fsqrt  v0.2d, v0.2d
    fcvtn   v0.2s, v0.2d
    mov     v3.d[1], v0.d[0]
    and     v2.16b, v2.16b, v4.16b
    bic     v3.16b, v3.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    fmov    v5.4s, #2.0
    fmul    v0.4s, v1.4s, v5.4s
    fsub    v0.4s, v0.4s, v6.4s
    ldr     q3, [sp, #80]
    fsub    v1.4s, v2.4s, v3.4s
    fmul    v0.4s, v0.4s, v1.4s
    fadd    v0.4s, v0.4s, v3.4s
    str     q0, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fmov    v5.4s, #0.25
    fcmge   v4.4s, v5.4s, v0.4s
    movz    w13, #0x0000
    movk    w13, #0x4180, lsl #16
    fmov    s5, w13
    dup     v5.4s, v5.s[0]
    fmul    v2.4s, v0.4s, v5.4s
    movz    w13, #0x0000
    movk    w13, #0x4140, lsl #16
    fmov    s5, w13
    dup     v5.4s, v5.s[0]
    fsub    v2.4s, v2.4s, v5.4s
    fmul    v2.4s, v2.4s, v0.4s
    fmov    v5.4s, #4.0
    fadd    v2.4s, v2.4s, v5.4s
    fmul    v2.4s, v2.4s, v0.4s
    fcvtl   v3.2d, v0.2s
    fsqrt   v3.2d, v3.2d
    fcvtn   v3.2s, v3.2d
    ext     v5.16b, v0.16b, v0.16b, #8
    fcvtl   v0.2d, v5.2s
    fsqrt   v0.2d, v0.2d
    fcvtn   v0.2s, v0.2d
    mov     v3.d[1], v0.d[0]
    and     v2.16b, v2.16b, v4.16b
    bic     v3.16b, v3.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    fmov    v5.4s, #2.0
    fmul    v0.4s, v1.4s, v5.4s
    fsub    v0.4s, v0.4s, v6.4s
    ldr     q3, [sp, #96]
    fsub    v1.4s, v2.4s, v3.4s
    fmul    v0.4s, v0.4s, v1.4s
    fadd    v0.4s, v0.4s, v3.4s
    str     q0, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fmov    v5.4s, #0.25
    fcmge   v4.4s, v5.4s, v0.4s
    movz    w13, #0x0000
    movk    w13, #0x4180, lsl #16
    fmov    s5, w13
    dup     v5.4s, v5.s[0]
    fmul    v2.4s, v0.4s, v5.4s
    movz    w13, #0x0000
    movk    w13, #0x4140, lsl #16
    fmov    s5, w13
    dup     v5.4s, v5.s[0]
    fsub    v2.4s, v2.4s, v5.4s
    fmul    v2.4s, v2.4s, v0.4s
    fmov    v5.4s, #4.0
    fadd    v2.4s, v2.4s, v5.4s
    fmul    v2.4s, v2.4s, v0.4s
    fcvtl   v3.2d, v0.2s
    fsqrt   v3.2d, v3.2d
    fcvtn   v3.2s, v3.2d
    ext     v5.16b, v0.16b, v0.16b, #8
    fcvtl   v0.2d, v5.2s
    fsqrt   v0.2d, v0.2d
    fcvtn   v0.2s, v0.2d
    mov     v3.d[1], v0.d[0]
    and     v2.16b, v2.16b, v4.16b
    bic     v3.16b, v3.16b, v4.16b
    orr     v2.16b, v2.16b, v3.16b
    fmov    v5.4s, #2.0
    fmul    v0.4s, v1.4s, v5.4s
    fsub    v0.4s, v0.4s, v6.4s
    ldr     q3, [sp, #112]
    fsub    v1.4s, v2.4s, v3.4s
    fmul    v0.4s, v0.4s, v1.4s
    fadd    v0.4s, v0.4s, v3.4s
    str     q0, [sp, #208]
    br      x14

.p2align 4
.Lblk_difference:
    /* t = |cb-cs|. */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fsub    v0.4s, v0.4s, v1.4s
    fabs    v0.4s, v0.4s
    str     q0, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fsub    v0.4s, v0.4s, v1.4s
    fabs    v0.4s, v0.4s
    str     q0, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fsub    v0.4s, v0.4s, v1.4s
    fabs    v0.4s, v0.4s
    str     q0, [sp, #208]
    br      x14

.p2align 4
.Lblk_exclusion:
    /* t = (cb+cs) - (2*cb)*cs. */
    ldr     q6, [sp, #240]
    ldr     q0, [sp, #80]
    ldr     q1, [sp, #16]
    fadd    v2.4s, v0.4s, v1.4s
    fmov    v5.4s, #2.0
    fmul    v3.4s, v0.4s, v5.4s
    fmul    v3.4s, v3.4s, v1.4s
    fsub    v2.4s, v2.4s, v3.4s
    str     q2, [sp, #176]
    ldr     q0, [sp, #96]
    ldr     q1, [sp, #32]
    fadd    v2.4s, v0.4s, v1.4s
    fmul    v3.4s, v0.4s, v5.4s
    fmul    v3.4s, v3.4s, v1.4s
    fsub    v2.4s, v2.4s, v3.4s
    str     q2, [sp, #192]
    ldr     q0, [sp, #112]
    ldr     q1, [sp, #48]
    fadd    v2.4s, v0.4s, v1.4s
    fmul    v3.4s, v0.4s, v5.4s
    fmul    v3.4s, v3.4s, v1.4s
    fsub    v2.4s, v2.4s, v3.4s
    str     q2, [sp, #208]
    br      x14

/* ------------------------------------------------------------------ */
/* Per-mode blend fragments (scalar tail). In: lane-0 channels in     */
/* slots. Out: lane-0 tR@176 tG@192 tB@208. Scratch s0/s1/s2. Return  */
/* address in x14; encode table in x15 (linear tail only). Branches   */
/* mirror the C++ scalar exactly; FP branch conditions follow the     */
/* compiler mapping (fcmp + b.ls/b.mi/b.ge/b.gt/b.eq), verified       */
/* against NDK clang instruction selection (never from memory).       */
/* ------------------------------------------------------------------ */
.p2align 4
.Ltail_multiply:
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #16]
    fmul    s0, s0, s1
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #32]
    fmul    s0, s0, s1
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #48]
    fmul    s0, s0, s1
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_screen:
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #16]
    fadd    s2, s0, s1
    fmul    s0, s0, s1
    fsub    s0, s2, s0
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #32]
    fadd    s2, s0, s1
    fmul    s0, s0, s1
    fsub    s0, s2, s0
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #48]
    fadd    s2, s0, s1
    fmul    s0, s0, s1
    fsub    s0, s2, s0
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_overlay:
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #12]
    fcmp    s0, s1
    bls     .Ltail64_ov_r_lo
    ldr     s1, [sp, #240]
    ldr     s2, [sp, #80]
    fsub    s1, s1, s2
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    ldr     s0, [sp, #16]
    fsub    s2, s2, s0
    fmul    s1, s1, s2
    ldr     s0, [sp, #240]
    fsub    s0, s0, s1
    b       .Ltail64_ov_r_done
.Ltail64_ov_r_lo:
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s0, s0, s2
    ldr     s1, [sp, #16]
    fmul    s0, s0, s1
.Ltail64_ov_r_done:
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #12]
    fcmp    s0, s1
    bls     .Ltail64_ov_g_lo
    ldr     s1, [sp, #240]
    ldr     s2, [sp, #96]
    fsub    s1, s1, s2
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    ldr     s0, [sp, #32]
    fsub    s2, s2, s0
    fmul    s1, s1, s2
    ldr     s0, [sp, #240]
    fsub    s0, s0, s1
    b       .Ltail64_ov_g_done
.Ltail64_ov_g_lo:
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s0, s0, s2
    ldr     s1, [sp, #32]
    fmul    s0, s0, s1
.Ltail64_ov_g_done:
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #12]
    fcmp    s0, s1
    bls     .Ltail64_ov_b_lo
    ldr     s1, [sp, #240]
    ldr     s2, [sp, #112]
    fsub    s1, s1, s2
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    ldr     s0, [sp, #48]
    fsub    s2, s2, s0
    fmul    s1, s1, s2
    ldr     s0, [sp, #240]
    fsub    s0, s0, s1
    b       .Ltail64_ov_b_done
.Ltail64_ov_b_lo:
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s0, s0, s2
    ldr     s1, [sp, #48]
    fmul    s0, s0, s1
.Ltail64_ov_b_done:
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_darken:
    /* t = cb<cs ? cb : cs. */
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #16]
    fcmp    s0, s1
    bmi     .Ltail64_dk_r_keep
    fmov     s0, s1
.Ltail64_dk_r_keep:
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #32]
    fcmp    s0, s1
    bmi     .Ltail64_dk_g_keep
    fmov     s0, s1
.Ltail64_dk_g_keep:
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #48]
    fcmp    s0, s1
    bmi     .Ltail64_dk_b_keep
    fmov     s0, s1
.Ltail64_dk_b_keep:
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_lighten:
    /* t = cb>cs ? cb : cs. */
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #16]
    fcmp    s0, s1
    bgt     .Ltail64_lt_r_keep
    fmov     s0, s1
.Ltail64_lt_r_keep:
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #32]
    fcmp    s0, s1
    bgt     .Ltail64_lt_g_keep
    fmov     s0, s1
.Ltail64_lt_g_keep:
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #48]
    fcmp    s0, s1
    bgt     .Ltail64_lt_b_keep
    fmov     s0, s1
.Ltail64_lt_b_keep:
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_dodge:
    /* cb==0 -> 0; cs>=1 -> 1; else min(cb/(1-cs), 1). */
    ldr     s0, [sp, #80]
    fmov    s1, wzr
    fcmp    s0, s1
    beq     .Ltail64_dg_r_zero
    ldr     s0, [sp, #16]
    ldr     s1, [sp, #240]
    fcmp    s0, s1
    bge     .Ltail64_dg_r_one
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #16]
    fsub    s1, s1, s0
    ldr     s0, [sp, #80]
    fdiv    s0, s0, s1
    ldr     s1, [sp, #240]
    fmin    s0, s0, s1
    b       .Ltail64_dg_r_done
.Ltail64_dg_r_zero:
    movi    v0.4s, #0
    b       .Ltail64_dg_r_done
.Ltail64_dg_r_one:
    ldr     s0, [sp, #240]
.Ltail64_dg_r_done:
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    fmov    s1, wzr
    fcmp    s0, s1
    beq     .Ltail64_dg_g_zero
    ldr     s0, [sp, #32]
    ldr     s1, [sp, #240]
    fcmp    s0, s1
    bge     .Ltail64_dg_g_one
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #32]
    fsub    s1, s1, s0
    ldr     s0, [sp, #96]
    fdiv    s0, s0, s1
    ldr     s1, [sp, #240]
    fmin    s0, s0, s1
    b       .Ltail64_dg_g_done
.Ltail64_dg_g_zero:
    movi    v0.4s, #0
    b       .Ltail64_dg_g_done
.Ltail64_dg_g_one:
    ldr     s0, [sp, #240]
.Ltail64_dg_g_done:
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    fmov    s1, wzr
    fcmp    s0, s1
    beq     .Ltail64_dg_b_zero
    ldr     s0, [sp, #48]
    ldr     s1, [sp, #240]
    fcmp    s0, s1
    bge     .Ltail64_dg_b_one
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #48]
    fsub    s1, s1, s0
    ldr     s0, [sp, #112]
    fdiv    s0, s0, s1
    ldr     s1, [sp, #240]
    fmin    s0, s0, s1
    b       .Ltail64_dg_b_done
.Ltail64_dg_b_zero:
    movi    v0.4s, #0
    b       .Ltail64_dg_b_done
.Ltail64_dg_b_one:
    ldr     s0, [sp, #240]
.Ltail64_dg_b_done:
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_burn:
    /* cb>=1 -> 1; cs<=0 -> 0; else 1-min((1-cb)/cs, 1). */
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #240]
    fcmp    s0, s1
    bge     .Ltail64_bn_r_one
    ldr     s0, [sp, #16]
    fmov    s1, wzr
    fcmp    s0, s1
    bls     .Ltail64_bn_r_zero
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #80]
    fsub    s1, s1, s0
    ldr     s0, [sp, #16]
    fdiv    s1, s1, s0
    ldr     s0, [sp, #240]
    fmin    s0, s1, s0
    ldr     s1, [sp, #240]
    fsub    s0, s1, s0
    b       .Ltail64_bn_r_done
.Ltail64_bn_r_one:
    ldr     s0, [sp, #240]
    b       .Ltail64_bn_r_done
.Ltail64_bn_r_zero:
    movi    v0.4s, #0
.Ltail64_bn_r_done:
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #240]
    fcmp    s0, s1
    bge     .Ltail64_bn_g_one
    ldr     s0, [sp, #32]
    fmov    s1, wzr
    fcmp    s0, s1
    bls     .Ltail64_bn_g_zero
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #96]
    fsub    s1, s1, s0
    ldr     s0, [sp, #32]
    fdiv    s1, s1, s0
    ldr     s0, [sp, #240]
    fmin    s0, s1, s0
    ldr     s1, [sp, #240]
    fsub    s0, s1, s0
    b       .Ltail64_bn_g_done
.Ltail64_bn_g_one:
    ldr     s0, [sp, #240]
    b       .Ltail64_bn_g_done
.Ltail64_bn_g_zero:
    movi    v0.4s, #0
.Ltail64_bn_g_done:
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #240]
    fcmp    s0, s1
    bge     .Ltail64_bn_b_one
    ldr     s0, [sp, #48]
    fmov    s1, wzr
    fcmp    s0, s1
    bls     .Ltail64_bn_b_zero
    ldr     s1, [sp, #240]
    ldr     s0, [sp, #112]
    fsub    s1, s1, s0
    ldr     s0, [sp, #48]
    fdiv    s1, s1, s0
    ldr     s0, [sp, #240]
    fmin    s0, s1, s0
    ldr     s1, [sp, #240]
    fsub    s0, s1, s0
    b       .Ltail64_bn_b_done
.Ltail64_bn_b_one:
    ldr     s0, [sp, #240]
    b       .Ltail64_bn_b_done
.Ltail64_bn_b_zero:
    movi    v0.4s, #0
.Ltail64_bn_b_done:
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_hardlight:
    ldr     s0, [sp, #16]
    ldr     s1, [sp, #12]
    fcmp    s0, s1
    bls     .Ltail64_hl_r_lo
    ldr     s1, [sp, #240]
    ldr     s2, [sp, #16]
    fsub    s1, s1, s2
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    ldr     s0, [sp, #80]
    fsub    s2, s2, s0
    fmul    s1, s1, s2
    ldr     s0, [sp, #240]
    fsub    s0, s0, s1
    b       .Ltail64_hl_r_done
.Ltail64_hl_r_lo:
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s0, s0, s2
    ldr     s1, [sp, #80]
    fmul    s0, s0, s1
.Ltail64_hl_r_done:
    str     s0, [sp, #176]
    ldr     s0, [sp, #32]
    ldr     s1, [sp, #12]
    fcmp    s0, s1
    bls     .Ltail64_hl_g_lo
    ldr     s1, [sp, #240]
    ldr     s2, [sp, #32]
    fsub    s1, s1, s2
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    ldr     s0, [sp, #96]
    fsub    s2, s2, s0
    fmul    s1, s1, s2
    ldr     s0, [sp, #240]
    fsub    s0, s0, s1
    b       .Ltail64_hl_g_done
.Ltail64_hl_g_lo:
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s0, s0, s2
    ldr     s1, [sp, #96]
    fmul    s0, s0, s1
.Ltail64_hl_g_done:
    str     s0, [sp, #192]
    ldr     s0, [sp, #48]
    ldr     s1, [sp, #12]
    fcmp    s0, s1
    bls     .Ltail64_hl_b_lo
    ldr     s1, [sp, #240]
    ldr     s2, [sp, #48]
    fsub    s1, s1, s2
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    ldr     s0, [sp, #112]
    fsub    s2, s2, s0
    fmul    s1, s1, s2
    ldr     s0, [sp, #240]
    fsub    s0, s0, s1
    b       .Ltail64_hl_b_done
.Ltail64_hl_b_lo:
    ldr     s2, [sp, #240]
    fadd    s2, s2, s2
    fmul    s0, s0, s2
    ldr     s1, [sp, #112]
    fmul    s0, s0, s1
.Ltail64_hl_b_done:
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_softlight:
    /* d = cb<=0.25 ? poly : (double)sqrt((double)cb); then
       t = cb + ((2*cs)-1)*(d-cb). Constants via movz/movk (exact). */
    ldr     s0, [sp, #80]
    movz    w13, #0x0000
    movk    w13, #0x3e80, lsl #16
    fmov    s1, w13
    fcmp    s0, s1
    bls     .Ltail64_sl_r_poly
    ldr     s0, [sp, #80]
    fcvt    d0, s0
    fsqrt   d0, d0
    fcvt    s0, d0
    b       .Ltail64_sl_r_d_done
.Ltail64_sl_r_poly:
    movz    w13, #0x0000
    movk    w13, #0x4180, lsl #16
    fmov    s1, w13
    fmul    s0, s0, s1
    movz    w13, #0x0000
    movk    w13, #0x4140, lsl #16
    fmov    s1, w13
    fsub    s0, s0, s1
    ldr     s1, [sp, #80]
    fmul    s0, s0, s1
    movz    w13, #0x0000
    movk    w13, #0x4080, lsl #16
    fmov    s1, w13
    fadd    s0, s0, s1
    ldr     s1, [sp, #80]
    fmul    s0, s0, s1
.Ltail64_sl_r_d_done:
    ldr     s1, [sp, #240]
    fadd    s1, s1, s1
    ldr     s2, [sp, #16]
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    fsub    s1, s1, s2
    ldr     s2, [sp, #80]
    fsub    s0, s0, s2
    fmul    s1, s1, s0
    fadd    s0, s2, s1
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    movz    w13, #0x0000
    movk    w13, #0x3e80, lsl #16
    fmov    s1, w13
    fcmp    s0, s1
    bls     .Ltail64_sl_g_poly
    ldr     s0, [sp, #96]
    fcvt    d0, s0
    fsqrt   d0, d0
    fcvt    s0, d0
    b       .Ltail64_sl_g_d_done
.Ltail64_sl_g_poly:
    movz    w13, #0x0000
    movk    w13, #0x4180, lsl #16
    fmov    s1, w13
    fmul    s0, s0, s1
    movz    w13, #0x0000
    movk    w13, #0x4140, lsl #16
    fmov    s1, w13
    fsub    s0, s0, s1
    ldr     s1, [sp, #96]
    fmul    s0, s0, s1
    movz    w13, #0x0000
    movk    w13, #0x4080, lsl #16
    fmov    s1, w13
    fadd    s0, s0, s1
    ldr     s1, [sp, #96]
    fmul    s0, s0, s1
.Ltail64_sl_g_d_done:
    ldr     s1, [sp, #240]
    fadd    s1, s1, s1
    ldr     s2, [sp, #32]
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    fsub    s1, s1, s2
    ldr     s2, [sp, #96]
    fsub    s0, s0, s2
    fmul    s1, s1, s0
    fadd    s0, s2, s1
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    movz    w13, #0x0000
    movk    w13, #0x3e80, lsl #16
    fmov    s1, w13
    fcmp    s0, s1
    bls     .Ltail64_sl_b_poly
    ldr     s0, [sp, #112]
    fcvt    d0, s0
    fsqrt   d0, d0
    fcvt    s0, d0
    b       .Ltail64_sl_b_d_done
.Ltail64_sl_b_poly:
    movz    w13, #0x0000
    movk    w13, #0x4180, lsl #16
    fmov    s1, w13
    fmul    s0, s0, s1
    movz    w13, #0x0000
    movk    w13, #0x4140, lsl #16
    fmov    s1, w13
    fsub    s0, s0, s1
    ldr     s1, [sp, #112]
    fmul    s0, s0, s1
    movz    w13, #0x0000
    movk    w13, #0x4080, lsl #16
    fmov    s1, w13
    fadd    s0, s0, s1
    ldr     s1, [sp, #112]
    fmul    s0, s0, s1
.Ltail64_sl_b_d_done:
    ldr     s1, [sp, #240]
    fadd    s1, s1, s1
    ldr     s2, [sp, #48]
    fmul    s1, s1, s2
    ldr     s2, [sp, #240]
    fsub    s1, s1, s2
    ldr     s2, [sp, #112]
    fsub    s0, s0, s2
    fmul    s1, s1, s0
    fadd    s0, s2, s1
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_difference:
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #16]
    fsub    s0, s0, s1
    fabs    s0, s0
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #32]
    fsub    s0, s0, s1
    fabs    s0, s0
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #48]
    fsub    s0, s0, s1
    fabs    s0, s0
    str     s0, [sp, #208]
    br      x14

.p2align 4
.Ltail_exclusion:
    ldr     s0, [sp, #80]
    ldr     s1, [sp, #16]
    fadd    s2, s0, s1
    ldr     s1, [sp, #240]
    fadd    s1, s1, s1
    fmul    s1, s0, s1
    ldr     s0, [sp, #16]
    fmul    s1, s1, s0
    fsub    s0, s2, s1
    str     s0, [sp, #176]
    ldr     s0, [sp, #96]
    ldr     s1, [sp, #32]
    fadd    s2, s0, s1
    ldr     s1, [sp, #240]
    fadd    s1, s1, s1
    fmul    s1, s0, s1
    ldr     s0, [sp, #32]
    fmul    s1, s1, s0
    fsub    s0, s2, s1
    str     s0, [sp, #192]
    ldr     s0, [sp, #112]
    ldr     s1, [sp, #48]
    fadd    s2, s0, s1
    ldr     s1, [sp, #240]
    fadd    s1, s1, s1
    fmul    s1, s0, s1
    ldr     s0, [sp, #48]
    fmul    s1, s1, s0
    fsub    s0, s2, s1
    str     s0, [sp, #208]
    br      x14

.Ldone:
    add     sp, sp, #256
    ret

SIZE(SYM(applyFeBlendNeon))

/* Mode jump tables: 32-bit self-relative diffs, index = mode - 1
   (modes 1..11). Same-section diffs need no relocations (no GOT,
   TEXTREL-free on every platform). */
.p2align 2
.Lblk_tab:
    .word   .Lblk_multiply - .Lblk_tab, .Lblk_screen - .Lblk_tab
    .word   .Lblk_overlay - .Lblk_tab, .Lblk_darken - .Lblk_tab
    .word   .Lblk_lighten - .Lblk_tab, .Lblk_dodge - .Lblk_tab
    .word   .Lblk_burn - .Lblk_tab, .Lblk_hardlight - .Lblk_tab
    .word   .Lblk_softlight - .Lblk_tab, .Lblk_difference - .Lblk_tab
    .word   .Lblk_exclusion - .Lblk_tab
.p2align 2
.Ltail_tab:
    .word   .Ltail_multiply - .Ltail_tab, .Ltail_screen - .Ltail_tab
    .word   .Ltail_overlay - .Ltail_tab, .Ltail_darken - .Ltail_tab
    .word   .Ltail_lighten - .Ltail_tab, .Ltail_dodge - .Ltail_tab
    .word   .Ltail_burn - .Ltail_tab, .Ltail_hardlight - .Ltail_tab
    .word   .Ltail_softlight - .Ltail_tab, .Ltail_difference - .Ltail_tab
    .word   .Ltail_exclusion - .Ltail_tab
GNU_STACK
