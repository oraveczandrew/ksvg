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
 * AArch64 / NEON implementation of ColorMatrix (4x5 matrix, SVG 0..1 semantics).
 * Bit-exact twin of KotlinKernels.colorMatrix: same FP op order (fdiv by 255,
 * left-to-right Horner-free row evaluation, no FMA), same LUT folding, same
 * clamp255 (+0.5 / fcvtzs / saturating narrow). Alpha never linearized.
 *
 * Register map (stable across the main loops):
 *   x9  = src cursor, x10 = dst cursor, x7 = matrix base (read-only)
 *   x12 = row stride bytes, x13 = row byte count, w14 = rows left
 *   x0  = srgbToLinear base, x1 = linearToSrgb base, w15 = useLinear
 *   w11 = 8px block counter, w2 = tail pixel counter (width is consumed
 *     in the prologue, so w2 is free), w3 = tail packed-pixel accumulator
 *     (clipLeft is consumed in the prologue, so w3 is free)
 *   GPR rule: only caller-saved regs (x0-x15) are touched; x19-x28 are
 *   never written (the JNI caller keeps live handles in x21/x25).
 *   v0-v3: pixel bytes B,G,R,A (ld4 order) / widened A-high lives in v0
 *   v4,v5: R floats lo/hi, v6,v7: G floats lo/hi
 *   v9,v10: B floats lo/hi, v11: A floats lo (A-high in v0 after widening)
 *   v8.4s = 255.0, v13.4s = 0.0, v14.4s = 0.5 (clamp constants, rebuilt
 *     per output row because narrow dests overlap their lanes)
 *   v12.8b = 63 mask for LUT256 (linear path only, set once, never written)
 *   v16-v31: LUT tables (linear path only)
 *   v1: LOW row accumulator, v4: HIGH row accumulator (R-low floats are dead
 *     by then — consumed into v1 first), v2: coeffs, v3: m4 dup
 *   Narrow dests are the results: R->v26 G->v25 B->v24 A->v27 (encode LUTs
 *   run in place on v26/v25/v24; st4 packs them directly, no parking movs)
 *   v15: widen + row-math scratch, w16: coefficient word temp
 *   d8-d15 (v8-v15 low halves) are callee-saved: spilled in prologue.
 */

#include "asm_macros.S"

/*
 * Lookup 8 bytes in a 256-byte table resident in v16..v31.
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
 * Widen 8 byte lanes to two float vectors, dividing by 255.0f exactly like
 * the reference (`(byte & 0xFF) / 255f`). Clobbers v15.
 */
.macro WIDEN8 vIn, vLo, vHi
    uxtl    v15.8h, \vIn\().8b
    uxtl    \vLo\().4s, v15.4h
    uxtl2   \vHi\().4s, v15.8h
    ucvtf   \vLo\().4s, \vLo\().4s
    ucvtf   \vHi\().4s, \vHi\().4s
    fdiv    \vLo\().4s, \vLo\().4s, v8.4s
    fdiv    \vHi\().4s, \vHi\().4s, v8.4s
.endm

/*
 * One 4-lane matrix row: vOut = m0*vR + m1*vG + m2*vB + m3*vA + m4,
 * coefficients from [x7 + rOff .. rOff+16]. Left-to-right order matches the
 * reference exactly; no FMA. Clobbers v2, v3, v15, w16.
 * (vOut must not be v2/v3/v15; HIGH rows use v12 as accumulator.)
 */
.macro MATROW4 vR, vG, vB, vA, vOut, rOff
    add     x16, x7, #\rOff
    ld1     {v2.4s}, [x16]
    ldr     w16, [x16, #16]
    dup     v3.4s, w16
    fmul    \vOut\().4s, \vR\().4s, v2.s[0]
    fmul    v15.4s, \vG\().4s, v2.s[1]
    fadd    \vOut\().4s, \vOut\().4s, v15.4s
    fmul    v15.4s, \vB\().4s, v2.s[2]
    fadd    \vOut\().4s, \vOut\().4s, v15.4s
    fmul    v15.4s, \vA\().4s, v2.s[3]
    fadd    \vOut\().4s, \vOut\().4s, v15.4s
    fadd    \vOut\().4s, \vOut\().4s, v3.4s
.endm

/*
 * Scale by 255, clamp to [0,255], round half-up and narrow to 8 lanes.
 * Matches clamp255() = roundToInt().coerceIn(0, 255): fmax/fmin before +0.5
 * is equivalent for all finite inputs and keeps fcvtzs in range.
 */
.macro CLAMPNARROW8 vLo, vHi, vOut
    fmul    \vLo\().4s, \vLo\().4s, v8.4s
    fmul    \vHi\().4s, \vHi\().4s, v8.4s
    fmax    \vLo\().4s, \vLo\().4s, v13.4s
    fmax    \vHi\().4s, \vHi\().4s, v13.4s
    fmin    \vLo\().4s, \vLo\().4s, v8.4s
    fmin    \vHi\().4s, \vHi\().4s, v8.4s
    fadd    \vLo\().4s, \vLo\().4s, v14.4s
    fadd    \vHi\().4s, \vHi\().4s, v14.4s
    fcvtzs  \vLo\().4s, \vLo\().4s
    fcvtzs  \vHi\().4s, \vHi\().4s
    sqxtn   \vOut\().4h, \vLo\().4s
    sqxtn2  \vOut\().8h, \vHi\().4s
    sqxtun  \vOut\().8b, \vOut\().8h
.endm

/*
 * Rebuild clamp constants: v8 = 255.0f, v13 = 0.0f, v14 = 0.5f.
 * Needed per output row: narrow dests (v24-v27) overlap q12/q13 lanes.
 * Clobbers w16.
 */
.macro ROWCONSTS
    movz    w16, #0x0000
    movk    w16, #0x437f, lsl #16
    fmov    s8, w16
    dup     v8.4s, v8.s[0]
    movi    v13.4s, #0
    fmov    v14.4s, #0.5
.endm

.text
.p2align 5
/*
 * void applyColorMatrixNeon(
 *     const jint* src, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     const jfloat* matrix, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * AArch64 ABI:
 *   x0 = src, x1 = dst
 *   w2 = width, w3 = clipLeft, w4 = clipTop, w5 = clipRight, w6 = clipBottom
 *   x7 = matrix
 *   stack: useLinear (w), srgbToLinear (x), linearToSrgb (x)
 */
.globl SYM(applyColorMatrixNeon)
TYPE(SYM(applyColorMatrixNeon), @function)
SYM(applyColorMatrixNeon):
    sub     sp, sp, #64
    stp     d8, d9, [sp, #0]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smaddl  x16, w4, w2, x3
    add     x9, x0, x16, lsl #2
    add     x10, x1, x16, lsl #2
    lsl     x12, x2, #2
    sub     w13, w5, w3
    cbz     w13, .Ldone          /* empty width clip: nothing to do */
    lsl     x13, x13, #2
    sub     w14, w6, w4
    cbz     w14, .Ldone          /* empty height clip: nothing to do */
    ldrb    w15, [sp, #64]       /* jboolean: upper stack bytes unspecified */
    ldr     x0, [sp, #72]
    ldr     x1, [sp, #80]

    cbnz    w15, .Llinear

.Lnonlinear:
    b       .Lrow_start_nonlin

.Lrow_nonlin:
    add     x9, x9, x12
    add     x10, x10, x12

.Lrow_start_nonlin:
    lsr     w17, w13, #2
    lsr     w11, w17, #3
    and     w2, w17, #7

.Lnonlin_8:
    cbz     w11, .Lnonlin_tail
    ld4     {v0.8b-v3.8b}, [x9], #32

    // Constants once per block: WIDEN8 divides by v8; rows/narrow only read
    // the consts (MATROW4 writes v2/v3/v15, never v8/v13/v14).
    ROWCONSTS

    // Widen B,G,R,A bytes to float pairs (A-high goes to v0 which is dead
    // after B widening).
    WIDEN8  v2, v4, v5
    WIDEN8  v1, v6, v7
    WIDEN8  v0, v9, v10
    WIDEN8  v3, v11, v0

    // R,G,B,A rows: LOW acc v1, HIGH acc v12 (v12 is free on this path;
    // on the linear path the LUT mask is rebuilt before encode).
    // Narrow dests are the results.
    MATROW4 v4, v6, v9, v11, v1, 0
    MATROW4 v5, v7, v10, v0, v12, 0
    CLAMPNARROW8 v1, v12, v26
    MATROW4 v4, v6, v9, v11, v1, 20
    MATROW4 v5, v7, v10, v0, v12, 20
    CLAMPNARROW8 v1, v12, v25
    MATROW4 v4, v6, v9, v11, v1, 40
    MATROW4 v5, v7, v10, v0, v12, 40
    CLAMPNARROW8 v1, v12, v24
    MATROW4 v4, v6, v9, v11, v1, 60
    MATROW4 v5, v7, v10, v0, v12, 60
    CLAMPNARROW8 v1, v12, v27

    // Pack B,G,R,A (st4 needs consecutive regs; dests already ordered).
    st4     {v24.8b-v27.8b}, [x10], #32
    subs    w11, w11, #1
    b.ne    .Lnonlin_8

.Lnonlin_tail:
    cbz     w2, .Lrow_nonlin_next
    b       .Ltail_scalar_nonlin

.Lrow_nonlin_next:
    subs    w14, w14, #1
    b.eq    .Ldone
    sub     x9, x9, x13
    sub     x10, x10, x13
    b       .Lrow_nonlin

.Llinear:
    movi    v12.8b, #63
    b       .Lrow_start_linear

.Lrow_linear:
    add     x9, x9, x12
    add     x10, x10, x12

.Lrow_start_linear:
    lsr     w17, w13, #2
    lsr     w11, w17, #3
    and     w2, w17, #7

.Llinear_8:
    cbz     w11, .Llinear_tail
    ld4     {v0.8b-v3.8b}, [x9], #32

    // Load sRGB->linear tables into v16..v31.
    mov     x8, x0
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]

    // Linearize R,G,B (alpha bypasses the LUT).
    LUT256  v2, v2
    LUT256  v1, v1
    LUT256  v0, v0

    // Constants before widening (WIDEN8 divides by v8).
    ROWCONSTS

    WIDEN8  v2, v4, v5
    WIDEN8  v1, v6, v7
    WIDEN8  v0, v9, v10
    WIDEN8  v3, v11, v0

    // R,G,B,A rows: LOW acc v1, HIGH acc v12 (mask rebuilt below).
    MATROW4 v4, v6, v9, v11, v1, 0
    MATROW4 v5, v7, v10, v0, v12, 0
    CLAMPNARROW8 v1, v12, v26
    MATROW4 v4, v6, v9, v11, v1, 20
    MATROW4 v5, v7, v10, v0, v12, 20
    CLAMPNARROW8 v1, v12, v25
    MATROW4 v4, v6, v9, v11, v1, 40
    MATROW4 v5, v7, v10, v0, v12, 40
    CLAMPNARROW8 v1, v12, v24
    MATROW4 v4, v6, v9, v11, v1, 60
    MATROW4 v5, v7, v10, v0, v12, 60
    CLAMPNARROW8 v1, v12, v27

    // Park results out of v24-v27: the encode-table reload below overwrites
    // v16-v31. (v0-v3 are dead here — byte vecs consumed by widen, A-hi in v0
    // dead after the A row — and LUT256 never touches them.)
    mov     v2.8b, v24.8b
    mov     v3.8b, v25.8b
    mov     v0.8b, v26.8b
    mov     v1.8b, v27.8b

    // Encode R,G,B back through the linear->sRGB tables (reloaded; the
    // s2l tables above are spent). Encode dests (v8/v9/v10: float consts and
    // inputs, all dead after the rows) must stay outside v16-v31: every
    // LUT256 reads the tables from those lanes. Alpha is packed raw.
    mov     x8, x1
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]
    movi    v12.8b, #63
    LUT256  v0, v8
    LUT256  v3, v9
    LUT256  v2, v10
    mov     v24.8b, v10.8b
    mov     v25.8b, v9.8b
    mov     v26.8b, v8.8b
    mov     v27.8b, v1.8b

    // Pack B,G,R,A directly (st4 needs consecutive regs).
    st4     {v24.8b-v27.8b}, [x10], #32
    subs    w11, w11, #1
    b.ne    .Llinear_8

.Llinear_tail:
    cbz     w2, .Lrow_linear_next
    b       .Ltail_scalar_linear

.Lrow_linear_next:
    subs    w14, w14, #1
    b.eq    .Ldone
    sub     x9, x9, x13
    sub     x10, x10, x13
    b       .Lrow_linear

// Scalar tail: one pixel in w16; B,G,R,A bytes extracted and widened to
// s1..s4 (linearized except alpha). Each output row evaluates
// m0*R + m1*G + m2*B + m3*A + m4 left-to-right like the reference, then the
// shared clamp/round/pack. Coeff offsets are all literal (no macro arithmetic
// on immediates). Clobbers s0, s5, s6, w16, w17, w3.
.macro TAIL_ROW o0, o1, o2, o3, o4, shift, enc
    ldr     s5, [x7, #\o0]
    fmul    s6, s3, s5
    ldr     s5, [x7, #\o1]
    fmul    s0, s2, s5
    fadd    s6, s6, s0
    ldr     s5, [x7, #\o2]
    fmul    s0, s1, s5
    fadd    s6, s6, s0
    ldr     s5, [x7, #\o3]
    fmul    s0, s4, s5
    fadd    s6, s6, s0
    ldr     s5, [x7, #\o4]
    fadd    s6, s6, s5
    fmul    s6, s6, s8
    fmax    s6, s6, s9
    fmin    s6, s6, s8
    fadd    s6, s6, s10
    fcvtzs  w17, s6
    .if \enc
    ldrb    w17, [x1, w17, uxtw]
    .endif
    and     w17, w17, #0xff
    orr     w3, w3, w17, lsl #\shift
.endm

.macro TAIL_INPUTS linear
    ubfx    w17, w16, #0, #8
    .if \linear
    ldrb    w17, [x0, w17, uxtw]
    .endif
    fmov    s1, w17
    ucvtf   s1, s1
    fdiv    s1, s1, s8
    ubfx    w17, w16, #8, #8
    .if \linear
    ldrb    w17, [x0, w17, uxtw]
    .endif
    fmov    s2, w17
    ucvtf   s2, s2
    fdiv    s2, s2, s8
    ubfx    w17, w16, #16, #8
    .if \linear
    ldrb    w17, [x0, w17, uxtw]
    .endif
    fmov    s3, w17
    ucvtf   s3, s3
    fdiv    s3, s3, s8
    ubfx    w17, w16, #24, #8
    fmov    s4, w17
    ucvtf   s4, s4
    fdiv    s4, s4, s8
.endm

.Ltail_scalar_nonlin:
    mov     w16, #0x0000
    movk    w16, #0x437f, lsl #16
    fmov    s8, w16
    fmov    s9, wzr
    fmov    s10, #0.5
    b       .Ltail_nonlin_loop

.Ltail_scalar_linear:
    mov     w16, #0x0000
    movk    w16, #0x437f, lsl #16
    fmov    s8, w16
    fmov    s9, wzr
    fmov    s10, #0.5
    b       .Ltail_linear_loop

.Ltail_nonlin_loop:
    ldr     w16, [x9], #4
    mov     w3, #0
    TAIL_INPUTS 0
    TAIL_ROW 0, 4, 8, 12, 16, 16, 0
    TAIL_ROW 20, 24, 28, 32, 36, 8, 0
    TAIL_ROW 40, 44, 48, 52, 56, 0, 0
    TAIL_ROW 60, 64, 68, 72, 76, 24, 0
    str     w3, [x10], #4
    subs    w2, w2, #1
    b.ne    .Ltail_nonlin_loop
    b       .Lrow_nonlin_next

.Ltail_linear_loop:
    ldr     w16, [x9], #4
    mov     w3, #0
    TAIL_INPUTS 1
    TAIL_ROW 0, 4, 8, 12, 16, 16, 1
    TAIL_ROW 20, 24, 28, 32, 36, 8, 1
    TAIL_ROW 40, 44, 48, 52, 56, 0, 1
    TAIL_ROW 60, 64, 68, 72, 76, 24, 0
    str     w3, [x10], #4
    subs    w2, w2, #1
    b.ne    .Ltail_linear_loop
    b       .Lrow_linear_next

.Ldone:
    ldp     d14, d15, [sp, #48]
    ldp     d12, d13, [sp, #32]
    ldp     d10, d11, [sp, #16]
    ldp     d8, d9, [sp, #0]
    add     sp, sp, #64
    ret

SIZE(SYM(applyColorMatrixNeon))
GNU_STACK
