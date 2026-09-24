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

.text
.align 2
#include "lighting_aarch64_pow_macros.S"
.global ksvgLightingDistantSpecularRowNeon64
.type ksvgLightingDistantSpecularRowNeon64, %function

// void ksvgLightingDistantSpecularRowNeon64(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params, float exponent)
//
// AAPCS64: x0 = srcT, x1 = srcM, x2 = srcB, x3 = dst,
//          w4 = count, x5 = params, s0 = exponent (7th arg, float).
//
// LightingParams layout (lighting.cpp, hard contract):
//   +0 invDx  +4 invDy  +8 k  +12 lx  +16 ly  +20 lz
//   +24 lr    +28 lg    +32 lb +36 ss
//
// Straight (non-premultiplied) distant-specular row: mirrors the parity
// validated distant-diffuse kernel body bit-for-bit (Sobel gradients,
// frsqrte+2NR reciprocal sqrt, dot op order), only the light operand is the
// loop-invariant half vector h = normalize(lx, ly, lz + 1) instead of l, and
// the clamped ndoth feeds the 4-lane NEON pow approximation (POW4_NEON;
// the reference uses Kotlin Math.pow / C++ std::pow double math — the ±1
// byte gate absorbs the approximation delta). The multiply-by-k / clamp01 /
// round-pack is then identical to diffuse, but the alpha byte is
// max(R, G, B) instead of 0xFF.
//
//   p     = pow(ndoth, exponent)          (4-lane NEON approximation)
//   I     = clamp01(k * p)
//   R/G/B = round(lr/lg/lb * I)           (floor(x+0.5) for non-negative)
//   A     = max(R, G, B)
//
// 8 output pixels / main iteration (two 4-lane batches), 4-px tail. With no
// libm calls left, loop invariants live in registers across the whole row:
// params/helpers are loaded once per row (sRGB; the linear variant reloads
// at the top of every iteration because its L2S LUT loads clobber v16-v31).
//
// Stack frame (224 bytes, 16-aligned):
//   [sp, #0]    x19 srcT        [sp,#40] x24 params
//   [sp, #8]    x20 srcM        [sp,#48] x25 LUT  (Linear kernel only)
//   [sp,#16]    x21 srcB        [sp,#56] exponent (double)
//   [sp,#24]    x22 dst         [sp,#64] hx  [sp,#68] hy  [sp,#72] hz
//   [sp,#32]    x23 count       [sp,#80] ndoth stash A   (16 bytes)
//                               [sp,#96] ndoth stash B   (16 bytes)
//                               [sp,#112] pow result A   (16 bytes)
//                               [sp,#128] pow result B   (16 bytes)
// Callee-saved state (AAPCS64: d8-d15, x29, x30 must survive the call):
//   [sp,#144]  d8   [sp,#152] d9   [sp,#160] d10 [sp,#168] d11
//   [sp,#176]  d12  [sp,#184] d13  [sp,#192] d14 [sp,#200] d15
//   [sp,#208]  x29               [sp,#216] x30
//
// x24 = params base. Exponent double is kept on the stack. The Sobel math and
// the tail use v8-v12/v15 (callee-saved VFP), and `bl pow` clobbers x30 on
// every call, so d8-d15 + x29/x30 are preserved in the prologue/epilogue (the
// armv7a sibling does the same with push {..,lr} + vpush {d8-d15}).

// Reload + broadcast LightingParams from x24 into v16-v25 (s25 = ss folded
// into the gradient scales s16/s17, then dead), plus the float helpers:
// v26 = 1.0, v27 = 0.5, v28 = 0, v29 = 0xFF000000. Loop-invariant: issued
// once per row (sRGB) or at the top of every iteration (linear, where the
// L2S LUT loads clobber v16-v31).
.macro LOAD_PARAMS
    ldr     s16, [x24]
    ldr     s17, [x24, #4]
    ldr     s18, [x24, #8]
    ldr     s19, [x24, #12]
    ldr     s20, [x24, #16]
    ldr     s21, [x24, #20]
    ldr     s22, [x24, #24]
    ldr     s23, [x24, #28]
    ldr     s24, [x24, #32]
    ldr     s25, [x24, #36]
    fdiv    s16, s25, s16
    fdiv    s17, s25, s17
    dup     v16.4s, v16.s[0]
    dup     v17.4s, v17.s[0]
    dup     v18.4s, v18.s[0]
    dup     v19.4s, v19.s[0]
    dup     v20.4s, v20.s[0]
    dup     v21.4s, v21.s[0]
    dup     v22.4s, v22.s[0]
    dup     v23.4s, v23.s[0]
    dup     v24.4s, v24.s[0]
    fmov    v26.4s, #1.0
    fmov    v27.4s, #0.5
    movi    v28.4s, #0
    movi    v29.4s, #0xff, lsl #24
.endm

// Overwrite the lx/ly/lz slots (just set by LOAD_PARAMS) with the normalized
// half vector broadcast into v19 = hx, v20 = hy, v21 = hz. The h scalars live
// in the stack frame (they are loop invariants computed once in the prologue;
// pow cannot touch stack memory).
.macro H_RELOAD
    ldp     s19, s20, [sp, #64]
    ldr     s21, [sp, #72]
    dup     v19.4s, v19.s[0]
    dup     v20.4s, v20.s[0]
    dup     v21.4s, v21.s[0]
.endm

// 4-lane vector pow (POW4_NEON, lighting_aarch64_pow_macros.S) replaced the
// old per-lane scalar double libm pow (POW4_STACK + bl pow); the stack stash
// and param reloads around it are gone.

// Lookup 16 bytes in a 256-byte table resident in v16..v31 (byte lanes, so
// mapping 0..255). Alpha is preserved by construction: the 0xFF alpha lane
// maps LUT[255]=255. Requires v12 = #63.
// Clobbers v4,v5,v6,v7,v14,v15.
.macro LUT256_16 vIn, vOut
    and     v15.16b, \vIn\().16b, v12.16b   /* v12 = 63 */
    ushr    v14.16b, \vIn\().16b, #6        /* bank index 0..3 */

    tbl     v4.16b, {v16.16b-v19.16b}, v15.16b
    tbl     v5.16b, {v20.16b-v23.16b}, v15.16b
    tbl     v6.16b, {v24.16b-v27.16b}, v15.16b
    tbl     v7.16b, {v28.16b-v31.16b}, v15.16b

    movi    v15.16b, #2
    cmeq    v15.16b, v14.16b, v15.16b
    bsl     v15.16b, v6.16b, v7.16b     /* (bank==2)? v6 : v7 */

    movi    v7.16b, #1
    cmeq    v7.16b, v14.16b, v7.16b
    bsl     v7.16b, v5.16b, v15.16b     /* (bank==1)? v5 : v15 */

    movi    v15.16b, #0
    cmeq    v15.16b, v14.16b, v15.16b
    bsl     v15.16b, v4.16b, v7.16b     /* (bank==0)? v4 : v7 */

    mov     \vOut\().16b, v15.16b
.endm

ksvgLightingDistantSpecularRowNeon64:
    cbz     w4, .Ldone

    sub     sp, sp, #224
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     d8, d9, [sp, #144]
    stp     d10, d11, [sp, #160]
    stp     d12, d13, [sp, #176]
    stp     d14, d15, [sp, #192]
    stp     x29, x30, [sp, #208]

    mov     x19, x0
    mov     x20, x1
    mov     x21, x2
    mov     x22, x3
    mov     x23, x4
    mov     x24, x5

    // Exponent (7th arg, float in s0) -> double, kept on the stack.
    fcvt    d0, s0
    str     d0, [sp, #56]

    // h = normalize(lx, ly, lz + 1), computed once (loop invariant).
    // hLen2 association matches the x86 reference (separate muls + adds).
    ldr     s16, [x24, #12]     // lx
    ldr     s17, [x24, #16]     // ly
    ldr     s18, [x24, #20]     // lz
    fmov    s21, #1.0
    fadd    s18, s18, s21       // hz_raw = lz + 1
    fmul    s19, s17, s17       // ly^2
    fmul    s20, s16, s16       // lx^2
    fadd    s19, s19, s20       // lx^2 + ly^2
    fmul    s20, s18, s18       // hz_raw^2
    fadd    s19, s19, s20       // hLen^2
    fsqrt   s19, s19            // hLen (single precision, matches sqrtps)
    fcmp    s19, #0.0
    b.eq    .Lh_zero
    fdiv    s16, s16, s19       // hx
    fdiv    s17, s17, s19       // hy
    fdiv    s18, s18, s19       // hz
.Lh_zero:
    stp     s16, s17, [sp, #64]
    str     s18, [sp, #72]

    // Loop-invariant params/helpers for the whole row (nothing in the sRGB
    // loop body clobbers v16-v30).
    LOAD_PARAMS
    H_RELOAD
    movi    v30.4s, #0xff       // 0x000000ff byte mask for the alpha max

    b       .Lloop8

.Lloop8:
    cmp     w23, #8
    b.lo    .Ltail4

    // ------------------------------ TOP ---------------------------
    ld1     {v0.4s-v1.4s}, [x19]
    ldr     d2, [x19, #32]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.2s, v2.2s, #24

    // A = outputs 0..3: p0,p1,p2...
    ext     v3.16b, v0.16b, v1.16b, #4
    ext     v4.16b, v0.16b, v1.16b, #8
    sub     v5.4s, v4.4s, v0.4s
    add     v6.4s, v3.4s, v3.4s
    add     v6.4s, v6.4s, v0.4s
    add     v6.4s, v6.4s, v4.4s

    // B = outputs 4..7: p4,p5,p6...
    ext     v7.16b, v1.16b, v2.16b, #4
    ext     v8.16b, v1.16b, v2.16b, #8
    sub     v9.4s, v8.4s, v1.4s
    add     v10.4s, v7.4s, v7.4s
    add     v10.4s, v10.4s, v1.4s
    add     v10.4s, v10.4s, v8.4s

    // v5=dxT_A, v6=sumT_A, v9=dxT_B, v10=sumT_B

    // ----------------------------- MIDDLE -------------------------
    ld1     {v0.4s-v1.4s}, [x20]
    ldr     d2, [x20, #32]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.2s, v2.2s, #24

    // A: 2*(p2-p0)
    ext     v3.16b, v0.16b, v1.16b, #8
    sub     v11.4s, v3.4s, v0.4s
    add     v11.4s, v11.4s, v11.4s
    add     v5.4s, v5.4s, v11.4s

    // B: 2*(p6-p4)
    ext     v8.16b, v1.16b, v2.16b, #8
    sub     v11.4s, v8.4s, v1.4s
    add     v11.4s, v11.4s, v11.4s
    add     v9.4s, v9.4s, v11.4s

    // ----------------------------- BOTTOM -------------------------
    ld1     {v0.4s-v1.4s}, [x21]
    ldr     d2, [x21, #32]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.2s, v2.2s, #24

    // A bottom
    ext     v3.16b, v0.16b, v1.16b, #4
    ext     v4.16b, v0.16b, v1.16b, #8
    add     v11.4s, v3.4s, v3.4s
    add     v11.4s, v11.4s, v0.4s
    add     v11.4s, v11.4s, v4.4s
    sub     v4.4s, v4.4s, v0.4s
    add     v5.4s, v5.4s, v4.4s
    sub     v11.4s, v11.4s, v6.4s

    // B bottom
    ext     v7.16b, v1.16b, v2.16b, #4
    ext     v8.16b, v1.16b, v2.16b, #8
    add     v12.4s, v7.4s, v7.4s
    add     v12.4s, v12.4s, v1.4s
    add     v12.4s, v12.4s, v8.4s
    sub     v8.4s, v8.4s, v1.4s
    add     v9.4s, v9.4s, v8.4s
    sub     v12.4s, v12.4s, v10.4s

    // A dx/dy in v5/v11; B dx/dy in v9/v12.
    scvtf   v5.4s, v5.4s
    scvtf   v11.4s, v11.4s
    fmul    v5.4s, v5.4s, v16.4s
    fmul    v11.4s, v11.4s, v17.4s
    scvtf   v9.4s, v9.4s
    scvtf   v12.4s, v12.4s
    fmul    v9.4s, v9.4s, v16.4s
    fmul    v12.4s, v12.4s, v17.4s

    // ------------------- NORMALIZATION / LIGHTING -----------------
    // Identical chain to the diffuse kernel: n2 + frsqrte two refinements,
    // then dot with the half vector h (v19-v21) instead of the light l.
    fmul    v0.4s, v5.4s, v5.4s
    fmla    v0.4s, v11.4s, v11.4s
    fadd    v0.4s, v0.4s, v26.4s

    fmul    v1.4s, v9.4s, v19.4s
    fmla    v1.4s, v12.4s, v20.4s
    fsub    v1.4s, v21.4s, v1.4s

    fmul    v2.4s, v9.4s, v9.4s
    fmla    v2.4s, v12.4s, v12.4s
    fadd    v2.4s, v2.4s, v26.4s

    fmul    v3.4s, v5.4s, v19.4s
    fmla    v3.4s, v11.4s, v20.4s
    fsub    v3.4s, v21.4s, v3.4s

    frsqrte v4.4s, v0.4s
    frsqrte v5.4s, v2.4s
    fmul    v6.4s, v4.4s, v4.4s
    fmul    v7.4s, v5.4s, v5.4s
    frsqrts v6.4s, v0.4s, v6.4s
    frsqrts v7.4s, v2.4s, v7.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v5.4s, v5.4s, v7.4s
    fmul    v6.4s, v4.4s, v4.4s
    fmul    v7.4s, v5.4s, v5.4s
    frsqrts v6.4s, v0.4s, v6.4s
    frsqrts v7.4s, v2.4s, v7.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v5.4s, v5.4s, v7.4s

    // ndoth A/B = clamp0(dot * invLen).
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v1.4s, v1.4s, v5.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmax    v1.4s, v1.4s, v28.4s

    // ndoth A/B -> vector pow in place (no bl, no stash, params survive).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v3, v0
    POW4_NEON v1, v0
    mov     v2.16b, v1.16b      // park p_B: pack A clobbers v1

    // ------------------------- PACK A (p in v3) -------------
    fmul    v3.4s, v3.4s, v18.4s     // k * p
    fmax    v3.4s, v3.4s, v28.4s     // clamp >= 0
    fmin    v3.4s, v3.4s, v26.4s     // clamp <= 1
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fadd    v6.4s, v6.4s, v27.4s
    fadd    v7.4s, v7.4s, v27.4s
    fadd    v4.4s, v4.4s, v27.4s
    fcvtzu  v6.4s, v6.4s
    fcvtzu  v7.4s, v7.4s
    fcvtzu  v4.4s, v4.4s
    shl     v6.4s, v6.4s, #16
    shl     v7.4s, v7.4s, #8
    orr     v4.16b, v4.16b, v7.16b
    orr     v4.16b, v4.16b, v6.16b
    // alpha = max(R,G,B) bytes
    ushr    v0.4s, v4.4s, #8         // byte0 = G
    ushr    v5.4s, v4.4s, #16        // byte0 = R
    and     v0.16b, v0.16b, v30.16b
    and     v5.16b, v5.16b, v30.16b
    and     v1.16b, v4.16b, v30.16b  // byte0 = B
    umax    v0.16b, v0.16b, v5.16b
    umax    v0.16b, v0.16b, v1.16b
    shl     v0.4s, v0.4s, #24
    orr     v4.16b, v4.16b, v0.16b
    str     q4, [x22]

    // ------------------------- PACK B (p in v2, parked) -------------
    fmul    v3.4s, v2.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fadd    v6.4s, v6.4s, v27.4s
    fadd    v7.4s, v7.4s, v27.4s
    fadd    v4.4s, v4.4s, v27.4s
    fcvtzu  v6.4s, v6.4s
    fcvtzu  v7.4s, v7.4s
    fcvtzu  v4.4s, v4.4s
    shl     v6.4s, v6.4s, #16
    shl     v7.4s, v7.4s, #8
    orr     v4.16b, v4.16b, v7.16b
    orr     v4.16b, v4.16b, v6.16b
    ushr    v0.4s, v4.4s, #8
    ushr    v5.4s, v4.4s, #16
    and     v0.16b, v0.16b, v30.16b
    and     v5.16b, v5.16b, v30.16b
    and     v1.16b, v4.16b, v30.16b
    umax    v0.16b, v0.16b, v5.16b
    umax    v0.16b, v0.16b, v1.16b
    shl     v0.4s, v0.4s, #24
    orr     v4.16b, v4.16b, v0.16b
    str     q4, [x22, #16]

    add     x19, x19, #32
    add     x20, x20, #32
    add     x21, x21, #32
    add     x22, x22, #32
    subs    w23, w23, #8
    cbnz    w23, .Lloop8
    b       .Ldone

.Ltail4:
    // Params/helpers still live from the prologue hoist (nothing in the
    // sRGB loop clobbers them).
    fmov    v15.4s, #2.0

    ldr     q0, [x19]
    ldr     q1, [x19, #4]
    ldr     q2, [x19, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v3.4s, v1.4s, v15.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    ldr     q0, [x20]
    ldr     q2, [x20, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v2.4s, v2.4s
    fsub    v5.4s, v2.4s, v0.4s
    fadd    v5.4s, v5.4s, v5.4s
    fadd    v4.4s, v4.4s, v5.4s

    ldr     q0, [x21]
    ldr     q1, [x21, #4]
    ldr     q2, [x21, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v5.4s, v1.4s, v15.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    fsub    v5.4s, v5.4s, v3.4s
    fmul    v4.4s, v4.4s, v16.4s
    fmul    v5.4s, v5.4s, v17.4s

    fmul    v0.4s, v4.4s, v4.4s
    fmla    v0.4s, v5.4s, v5.4s
    fadd    v0.4s, v0.4s, v26.4s
    frsqrte v1.4s, v0.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v2.4s, v4.4s, v19.4s
    fmla    v2.4s, v5.4s, v20.4s
    fsub    v2.4s, v21.4s, v2.4s
    fmul    v2.4s, v2.4s, v1.4s
    fmax    v2.4s, v2.4s, v28.4s

    // ndoth -> vector pow in place (params survive, no reload).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v2, v0

    fmul    v3.4s, v2.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v0.4s, v3.4s, v22.4s
    fmul    v1.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fadd    v0.4s, v0.4s, v27.4s
    fadd    v1.4s, v1.4s, v27.4s
    fadd    v4.4s, v4.4s, v27.4s
    fcvtzu  v0.4s, v0.4s
    fcvtzu  v1.4s, v1.4s
    fcvtzu  v4.4s, v4.4s
    shl     v0.4s, v0.4s, #16
    shl     v1.4s, v1.4s, #8
    orr     v4.16b, v4.16b, v1.16b
    orr     v4.16b, v4.16b, v0.16b
    ushr    v5.4s, v4.4s, #8
    ushr    v6.4s, v4.4s, #16
    and     v5.16b, v5.16b, v30.16b
    and     v6.16b, v6.16b, v30.16b
    and     v7.16b, v4.16b, v30.16b
    umax    v5.16b, v5.16b, v6.16b
    umax    v5.16b, v5.16b, v7.16b
    shl     v5.4s, v5.4s, #24
    orr     v4.16b, v4.16b, v5.16b
    str     q4, [x22]

.Ldone:
    ldp     x29, x30, [sp, #208]
    ldp     d14, d15, [sp, #192]
    ldp     d12, d13, [sp, #176]
    ldp     d10, d11, [sp, #160]
    ldp     d8, d9, [sp, #144]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp, #0]
    add     sp, sp, #224
    ret

.size ksvgLightingDistantSpecularRowNeon64, .-ksvgLightingDistantSpecularRowNeon64

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): identical Sobel/normalize/ndoth/pow
// math, then instead of alpha = max(sRGB bytes) the alpha byte is set to
// max(Rlin, Glin, Blin) BEFORE the linear->sRGB 256-byte LUT conversion. The
// L2S LUT is monotonic, so LUT[max(linear)] == max(LUT[R],LUT[G],LUT[B]) ==
// max(sRGB R,G,B), matching the Kotlin reference's maxOf() AFTER the L2S map.
// The LUT loads clobber v16-v31, so params are reloaded at the top of every
// iteration (and at the 4-px tail), like the diffuse *Neon64Linear row.
//
// void ksvgLightingDistantSpecularRowNeon64Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params, float exponent,
//   const uint8_t* linearToSrgb)
//
// AAPCS64: x0-x4, x5 = params, s0 = exponent, x6 = linearToSrgb LUT.
// LUT pointer is saved into callee-saved x25 (x6 is clobbered by pow).
// ---------------------------------------------------------------------------

.text
.align 2
.global ksvgLightingDistantSpecularRowNeon64Linear
.type ksvgLightingDistantSpecularRowNeon64Linear, %function

ksvgLightingDistantSpecularRowNeon64Linear:
    cbz     w4, .Llin_done

    sub     sp, sp, #224
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    str     x25, [sp, #48]
    stp     d8, d9, [sp, #144]
    stp     d10, d11, [sp, #160]
    stp     d12, d13, [sp, #176]
    stp     d14, d15, [sp, #192]
    stp     x29, x30, [sp, #208]

    mov     x19, x0
    mov     x20, x1
    mov     x21, x2
    mov     x22, x3
    mov     x23, x4
    mov     x24, x5
    mov     x25, x6

    fcvt    d0, s0
    str     d0, [sp, #56]

    // h = normalize(lx, ly, lz + 1), loop invariant.
    ldr     s16, [x24, #12]
    ldr     s17, [x24, #16]
    ldr     s18, [x24, #20]
    fmov    s21, #1.0
    fadd    s18, s18, s21       // hz_raw
    fmul    s19, s17, s17
    fmul    s20, s16, s16
    fadd    s19, s19, s20
    fmul    s20, s18, s18
    fadd    s19, s19, s20       // hLen^2
    fsqrt   s19, s19
    fcmp    s19, #0.0
    b.eq    .Llin_h_zero
    fdiv    s16, s16, s19
    fdiv    s17, s17, s19
    fdiv    s18, s18, s19
.Llin_h_zero:
    stp     s16, s17, [sp, #64]
    str     s18, [sp, #72]

    b       .Llin_loop8

.Llin_loop8:
    cmp     w23, #8
    b.lo    .Llin_tail4

    LOAD_PARAMS
    H_RELOAD

    // ------------------------------ TOP ---------------------------
    ld1     {v0.4s-v1.4s}, [x19]
    ldr     d2, [x19, #32]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.2s, v2.2s, #24

    ext     v3.16b, v0.16b, v1.16b, #4
    ext     v4.16b, v0.16b, v1.16b, #8
    sub     v5.4s, v4.4s, v0.4s
    add     v6.4s, v3.4s, v3.4s
    add     v6.4s, v6.4s, v0.4s
    add     v6.4s, v6.4s, v4.4s

    ext     v7.16b, v1.16b, v2.16b, #4
    ext     v8.16b, v1.16b, v2.16b, #8
    sub     v9.4s, v8.4s, v1.4s
    add     v10.4s, v7.4s, v7.4s
    add     v10.4s, v10.4s, v1.4s
    add     v10.4s, v10.4s, v8.4s

    // v5=dxT_A, v6=sumT_A, v9=dxT_B, v10=sumT_B

    // ----------------------------- MIDDLE -------------------------
    ld1     {v0.4s-v1.4s}, [x20]
    ldr     d2, [x20, #32]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.2s, v2.2s, #24

    ext     v3.16b, v0.16b, v1.16b, #8
    sub     v11.4s, v3.4s, v0.4s
    add     v11.4s, v11.4s, v11.4s
    add     v5.4s, v5.4s, v11.4s

    ext     v8.16b, v1.16b, v2.16b, #8
    sub     v11.4s, v8.4s, v1.4s
    add     v11.4s, v11.4s, v11.4s
    add     v9.4s, v9.4s, v11.4s

    // ----------------------------- BOTTOM -------------------------
    ld1     {v0.4s-v1.4s}, [x21]
    ldr     d2, [x21, #32]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.2s, v2.2s, #24

    ext     v3.16b, v0.16b, v1.16b, #4
    ext     v4.16b, v0.16b, v1.16b, #8
    add     v11.4s, v3.4s, v3.4s
    add     v11.4s, v11.4s, v0.4s
    add     v11.4s, v11.4s, v4.4s
    sub     v4.4s, v4.4s, v0.4s
    add     v5.4s, v5.4s, v4.4s
    sub     v11.4s, v11.4s, v6.4s

    ext     v7.16b, v1.16b, v2.16b, #4
    ext     v8.16b, v1.16b, v2.16b, #8
    add     v12.4s, v7.4s, v7.4s
    add     v12.4s, v12.4s, v1.4s
    add     v12.4s, v12.4s, v8.4s
    sub     v8.4s, v8.4s, v1.4s
    add     v9.4s, v9.4s, v8.4s
    sub     v12.4s, v12.4s, v10.4s

    scvtf   v5.4s, v5.4s
    scvtf   v11.4s, v11.4s
    fmul    v5.4s, v5.4s, v16.4s
    fmul    v11.4s, v11.4s, v17.4s
    scvtf   v9.4s, v9.4s
    scvtf   v12.4s, v12.4s
    fmul    v9.4s, v9.4s, v16.4s
    fmul    v12.4s, v12.4s, v17.4s

    // ------------------- NORMALIZATION / ndoth --------------------
    fmul    v0.4s, v5.4s, v5.4s
    fmla    v0.4s, v11.4s, v11.4s
    fadd    v0.4s, v0.4s, v26.4s

    fmul    v1.4s, v9.4s, v19.4s
    fmla    v1.4s, v12.4s, v20.4s
    fsub    v1.4s, v21.4s, v1.4s

    fmul    v2.4s, v9.4s, v9.4s
    fmla    v2.4s, v12.4s, v12.4s
    fadd    v2.4s, v2.4s, v26.4s

    fmul    v3.4s, v5.4s, v19.4s
    fmla    v3.4s, v11.4s, v20.4s
    fsub    v3.4s, v21.4s, v3.4s

    frsqrte v4.4s, v0.4s
    frsqrte v5.4s, v2.4s
    fmul    v6.4s, v4.4s, v4.4s
    fmul    v7.4s, v5.4s, v5.4s
    frsqrts v6.4s, v0.4s, v6.4s
    frsqrts v7.4s, v2.4s, v7.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v5.4s, v5.4s, v7.4s
    fmul    v6.4s, v4.4s, v4.4s
    fmul    v7.4s, v5.4s, v5.4s
    frsqrts v6.4s, v0.4s, v6.4s
    frsqrts v7.4s, v2.4s, v7.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v5.4s, v5.4s, v7.4s

    fmul    v3.4s, v3.4s, v4.4s
    fmul    v1.4s, v1.4s, v5.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmax    v1.4s, v1.4s, v28.4s

    // ndoth A/B -> vector pow in place (params survive for the pack;
    // the next iteration reloads them after the LUT anyway).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v3, v0
    POW4_NEON v1, v0
    mov     v2.16b, v1.16b      // park p_B: pack A clobbers v1
    movi    v30.4s, #0xff       // 0x000000ff byte mask for the alpha max

    // ------------------- PACK A (linear, alpha = max(Rlin,Glin,Blin)) ----
    fmul    v3.4s, v3.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fadd    v6.4s, v6.4s, v27.4s
    fadd    v7.4s, v7.4s, v27.4s
    fadd    v4.4s, v4.4s, v27.4s
    fcvtzu  v6.4s, v6.4s
    fcvtzu  v7.4s, v7.4s
    fcvtzu  v4.4s, v4.4s
    shl     v6.4s, v6.4s, #16
    shl     v7.4s, v7.4s, #8
    orr     v4.16b, v4.16b, v7.16b
    orr     v4.16b, v4.16b, v6.16b
    // alpha = max(linear R,G,B) -> pre-LUT (monotonic LUT preserves max)
    ushr    v0.4s, v4.4s, #8
    ushr    v5.4s, v4.4s, #16
    and     v0.16b, v0.16b, v30.16b
    and     v5.16b, v5.16b, v30.16b
    and     v1.16b, v4.16b, v30.16b
    umax    v0.16b, v0.16b, v5.16b
    umax    v0.16b, v0.16b, v1.16b
    shl     v0.4s, v0.4s, #24
    orr     v4.16b, v4.16b, v0.16b
    mov     v0.16b, v4.16b          // stash A

    // ------------------- PACK B (p in v2, parked) ----
    fmul    v3.4s, v2.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fadd    v6.4s, v6.4s, v27.4s
    fadd    v7.4s, v7.4s, v27.4s
    fadd    v4.4s, v4.4s, v27.4s
    fcvtzu  v6.4s, v6.4s
    fcvtzu  v7.4s, v7.4s
    fcvtzu  v4.4s, v4.4s
    shl     v6.4s, v6.4s, #16
    shl     v7.4s, v7.4s, #8
    orr     v4.16b, v4.16b, v7.16b
    orr     v4.16b, v4.16b, v6.16b
    ushr    v9.4s, v4.4s, #8
    ushr    v10.4s, v4.4s, #16
    and     v9.16b, v9.16b, v30.16b
    and     v10.16b, v10.16b, v30.16b
    and     v11.16b, v4.16b, v30.16b
    umax    v9.16b, v9.16b, v10.16b
    umax    v9.16b, v9.16b, v11.16b
    shl     v9.4s, v9.4s, #24
    orr     v4.16b, v4.16b, v9.16b
    mov     v8.16b, v4.16b          // stash B (v4 is LUT scratch below)

    // v0/v8 = packed linear ARGB batches (alpha = max linear). Load the
    // 256-byte L2S LUT into v16-v31 (clobbers params; reloaded next iters).
    mov     x9, x25
    ld1     {v16.16b-v19.16b}, [x9], #64
    ld1     {v20.16b-v23.16b}, [x9], #64
    ld1     {v24.16b-v27.16b}, [x9], #64
    ld1     {v28.16b-v31.16b}, [x9], #64
    movi    v12.16b, #63
    LUT256_16 v0, v0
    LUT256_16 v8, v8
    str     q0, [x22]
    str     q8, [x22, #16]

    add     x19, x19, #32
    add     x20, x20, #32
    add     x21, x21, #32
    add     x22, x22, #32
    subs    w23, w23, #8
    cbnz    w23, .Llin_loop8
    b       .Llin_done

.Llin_tail4:
    LOAD_PARAMS
    H_RELOAD
    movi    v30.4s, #0xff
    fmov    v15.4s, #2.0

    ldr     q0, [x19]
    ldr     q1, [x19, #4]
    ldr     q2, [x19, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v3.4s, v1.4s, v15.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    ldr     q0, [x20]
    ldr     q2, [x20, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v2.4s, v2.4s
    fsub    v5.4s, v2.4s, v0.4s
    fadd    v5.4s, v5.4s, v5.4s
    fadd    v4.4s, v4.4s, v5.4s

    ldr     q0, [x21]
    ldr     q1, [x21, #4]
    ldr     q2, [x21, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v5.4s, v1.4s, v15.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    fsub    v5.4s, v5.4s, v3.4s
    fmul    v4.4s, v4.4s, v16.4s
    fmul    v5.4s, v5.4s, v17.4s

    fmul    v0.4s, v4.4s, v4.4s
    fmla    v0.4s, v5.4s, v5.4s
    fadd    v0.4s, v0.4s, v26.4s
    frsqrte v1.4s, v0.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v2.4s, v4.4s, v19.4s
    fmla    v2.4s, v5.4s, v20.4s
    fsub    v2.4s, v21.4s, v2.4s
    fmul    v2.4s, v2.4s, v1.4s
    fmax    v2.4s, v2.4s, v28.4s

    // ndoth -> vector pow in place (params live from the tail-top reload).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v2, v0

    fmul    v3.4s, v2.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v0.4s, v3.4s, v22.4s
    fmul    v1.4s, v3.4s, v23.4s
    fmul    v4.4s, v3.4s, v24.4s
    fadd    v0.4s, v0.4s, v27.4s
    fadd    v1.4s, v1.4s, v27.4s
    fadd    v4.4s, v4.4s, v27.4s
    fcvtzu  v0.4s, v0.4s
    fcvtzu  v1.4s, v1.4s
    fcvtzu  v4.4s, v4.4s
    shl     v0.4s, v0.4s, #16
    shl     v1.4s, v1.4s, #8
    orr     v4.16b, v4.16b, v1.16b
    orr     v4.16b, v4.16b, v0.16b
    ushr    v5.4s, v4.4s, #8
    ushr    v6.4s, v4.4s, #16
    and     v5.16b, v5.16b, v30.16b
    and     v6.16b, v6.16b, v30.16b
    and     v7.16b, v4.16b, v30.16b
    umax    v5.16b, v5.16b, v6.16b
    umax    v5.16b, v5.16b, v7.16b
    shl     v5.4s, v5.4s, #24
    orr     v4.16b, v4.16b, v5.16b

    mov     x9, x25
    ld1     {v16.16b-v19.16b}, [x9], #64
    ld1     {v20.16b-v23.16b}, [x9], #64
    ld1     {v24.16b-v27.16b}, [x9], #64
    ld1     {v28.16b-v31.16b}, [x9], #64
    movi    v12.16b, #63
    LUT256_16 v4, v4
    str     q4, [x22]

.Llin_done:
    ldp     x29, x30, [sp, #208]
    ldp     d14, d15, [sp, #192]
    ldp     d12, d13, [sp, #176]
    ldp     d10, d11, [sp, #160]
    ldp     d8, d9, [sp, #144]
    ldr     x25, [sp, #48]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp, #0]
    add     sp, sp, #224
    ret

.size ksvgLightingDistantSpecularRowNeon64Linear, .-ksvgLightingDistantSpecularRowNeon64Linear

EMIT_POW4_NEON_TABLES
#ifndef __APPLE__
.section .note.GNU-stack,"",%progbits
#endif
