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

/*
 * void ksvgLightingDistantDiffuseRowNeon64(
 *     const jint* srcT, const jint* srcM, const jint* srcB,
 *     jint* dst, jint count, const LightingParams* params);
 *
 * AArch64 ABI:
 *   x0 = srcT, x1 = srcM, x2 = srcB, x3 = dst, w4 = count, x5 = params
 */
.global ksvgLightingDistantDiffuseRowNeon64
.type ksvgLightingDistantDiffuseRowNeon64, %function

// void ksvgLightingDistantDiffuseRowNeon64(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params)
//
// AAPCS64:
//   x0 = srcT, x1 = srcM, x2 = srcB, x3 = dst, w4 = count, x5 = params
//
// LightingParams layout (lighting.cpp, hard contract):
//   +0 invDx  +4 invDy  +8 k  +12 lx  +16 ly  +20 lz
//   +24 lr    +28 lg    +32 lb +36 ss
//
// Processes 8 ARGB8888 pixels per iteration as two independent 4-lane
// batches (A = outputs 0..3, B = outputs 4..7). Each source row loads
// exactly 10 pixels (ld1 v0-v1 plus ldr d2 = 40 bytes); the two 4-pixel
// stencil windows are derived from the same extracted alpha vectors via
// ext, so no second load is needed. The 4-px tail (.Ltail4) instead uses
// overlapping ldr triplets at [src+0]/[src+4]/[src+8].
// C++ only calls this kernel with count > 0 (cbz guard) and a multiple
// of 4 (the .Lloop8 fallthrough handles exactly the 4-px remainder).
//
// math (matches the Kotlin/scalar reference op order):
//   h = (alpha >> 24) * ss          (ss is folded into the scales below)
//   dxRel = (rT-lT) + 2*(rM-lM) + (rB-lB)
//   dyRel = (lB+2*mB+rB) - (lT+2*mT+rT)
//   nx = -dxRel*ss/invDx, ny = -dyRel*ss/invDy, nz = 1
//   rec = rsqrt(nx^2+ny^2+1) with 2 Newton-Raphson refinements
//   dot = lz - (dxRel*sx*lx + dyRel*sy*ly)   (negation folded into the dot)
//   intensity = clamp(clamp(dot,0)*k, 0, 1)
//   out = (round(lr*intensity)<<16) | (round(lg*intensity)<<8)
//         | round(lb*intensity) | 0xFF000000
//   round(x) for non-negative x is floor(x + 0.5) (v27 bias + fcvtzu).
//
// Register map (loop-invariant):
//   v16 = ss/invDx   v17 = ss/invDy   v18 = k    v19 = lx   v20 = ly
//   v21 = lz         v22 = lr         v23 = lg   v24 = lb
//   v26 = 1.0f       v27 = 0.5f       v28 = 0.0f v29 = 0xFF000000 bytes
//   v0-v15, v25, v30-v31 = scratch (v25/ss is dead after the ss fold)
ksvgLightingDistantDiffuseRowNeon64:
    cbz     w4, .Ldone

    ldr     s16, [x5]
    ldr     s17, [x5, #4]
    ldr     s18, [x5, #8]
    ldr     s19, [x5, #12]
    ldr     s20, [x5, #16]
    ldr     s21, [x5, #20]
    ldr     s22, [x5, #24]
    ldr     s23, [x5, #28]
    ldr     s24, [x5, #32]
    ldr     s25, [x5, #36]

    // Sobel is linear: fold ss into gradient scales.
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

.Lloop8:
    cmp     w4, #8
    b.lo    .Ltail4

    // ------------------------------ TOP ---------------------------
    ld1     {v0.4s-v1.4s}, [x0]
    ldr     d2, [x0, #32]
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
    ld1     {v0.4s-v1.4s}, [x1]
    ldr     d2, [x1, #32]
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
    ld1     {v0.4s-v1.4s}, [x2]
    ldr     d2, [x2, #32]
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
    // Keep both n2 values and both dot numerators live before rsqrt to
    // expose independent work to the OoO scheduler.
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

    // Two independent reciprocal-sqrt chains. FRSQRTS is (3 - Vn*Vm)/2,
    // so Vm must be the estimate SQUARED; a bare frsqrts(x, est) chain
    // computes est*(3 - n2*est)/2, which goes negative for n2 > ~9 and
    // inverts the lighting. Two refinements give ~2^-32 relative error,
    // tight enough to be byte-exact vs the reference's correctly-rounded
    // sqrt.
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

    // Apply invLen and k/clamp to A.
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s      // clamp(dot*k) >= 0
    fmin    v3.4s, v3.4s, v26.4s      // clamp <= 1 (intensity)
    fmul    v6.4s, v3.4s, v22.4s      // outR = intensity*lr
    fmul    v7.4s, v3.4s, v23.4s      // outG = intensity*lg
    fmul    v8.4s, v3.4s, v24.4s      // outB = intensity*lb
    fadd    v6.4s, v6.4s, v27.4s      // +0.5: round-half-up
    fadd    v7.4s, v7.4s, v27.4s      // +0.5: round-half-up
    fadd    v8.4s, v8.4s, v27.4s      // +0.5: round-half-up
    fcvtzu  v6.4s, v6.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v7.4s, v7.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v8.4s, v8.4s          // floor(x+0.5): Kotlin roundToInt
    shl     v6.4s, v6.4s, #16       // R << 16
    shl     v7.4s, v7.4s, #8        // G << 8
    orr     v8.16b, v8.16b, v7.16b   // B|G
    orr     v8.16b, v8.16b, v6.16b   // B|G|R
    orr     v8.16b, v8.16b, v29.16b  // alpha = 0xFF
    str     q8, [x3]

    // Apply invLen and k/clamp to B.
    fmul    v3.4s, v1.4s, v5.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s      // clamp(dot*k) >= 0
    fmin    v3.4s, v3.4s, v26.4s      // clamp <= 1 (intensity)
    fmul    v6.4s, v3.4s, v22.4s      // outR = intensity*lr
    fmul    v7.4s, v3.4s, v23.4s      // outG = intensity*lg
    fmul    v8.4s, v3.4s, v24.4s      // outB = intensity*lb
    fadd    v6.4s, v6.4s, v27.4s      // +0.5: round-half-up
    fadd    v7.4s, v7.4s, v27.4s      // +0.5: round-half-up
    fadd    v8.4s, v8.4s, v27.4s      // +0.5: round-half-up
    fcvtzu  v6.4s, v6.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v7.4s, v7.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v8.4s, v8.4s          // floor(x+0.5): Kotlin roundToInt
    shl     v6.4s, v6.4s, #16       // R << 16
    shl     v7.4s, v7.4s, #8        // G << 8
    orr     v8.16b, v8.16b, v7.16b   // B|G
    orr     v8.16b, v8.16b, v6.16b   // B|G|R
    orr     v8.16b, v8.16b, v29.16b  // alpha = 0xFF
    str     q8, [x3, #16]

    // 8 pixels * 4 bytes; w4 stays a multiple of 4 (C++ contract).
    add     x0, x0, #32
    add     x1, x1, #32
    add     x2, x2, #32
    add     x3, x3, #32
    subs    w4, w4, #8
    cbnz    w4, .Lloop8
    b       .Ldone

.Ltail4:
    // 4-px tail: same Sobel/normalize/intensity math, one 4-lane batch
    // (v4 = dx, v5 = dy). The 2.0 constant weights the middle tap.
    fmov    v30.4s, #2.0

    // ---- Row T: overlapping l/m/r triplet; v3 = l+2m+r, v4 = r-l ----
    ldr     q0, [x0]
    ldr     q1, [x0, #4]
    ldr     q2, [x0, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v3.4s, v1.4s, v30.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    // ---- Row M: middle row contributes 2*(r-l) to dx only (dy taps
    // cancel), so only the l/r loads are needed ----
    ldr     q0, [x1]
    ldr     q2, [x1, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v2.4s, v2.4s
    fsub    v5.4s, v2.4s, v0.4s
    fadd    v5.4s, v5.4s, v5.4s
    fadd    v4.4s, v4.4s, v5.4s

    // ---- Row B: overlapping l/m/r triplet; v4 += r-l, v5 = sumB ----
    ldr     q0, [x2]
    ldr     q1, [x2, #4]
    ldr     q2, [x2, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v5.4s, v1.4s, v30.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    fsub    v5.4s, v5.4s, v3.4s      // dy = sumB - sumT
    fmul    v4.4s, v4.4s, v16.4s      // dx *= ss/invDx
    fmul    v5.4s, v5.4s, v17.4s      // dy *= ss/invDy

    fmul    v0.4s, v4.4s, v4.4s
    fmla    v0.4s, v5.4s, v5.4s
    fadd    v0.4s, v0.4s, v26.4s
    frsqrte v1.4s, v0.4s          // single rsqrt chain, 2 refinements
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v2.4s, v4.4s, v19.4s      // dot = lz - (dx*lx + dy*ly)
    fmla    v2.4s, v5.4s, v20.4s
    fsub    v2.4s, v21.4s, v2.4s
    fmul    v2.4s, v2.4s, v1.4s
    fmul    v2.4s, v2.4s, v18.4s
    fmax    v2.4s, v2.4s, v28.4s      // clamp(dot*k) >= 0
    fmin    v2.4s, v2.4s, v26.4s      // clamp <= 1 (intensity)
    fmul    v0.4s, v2.4s, v22.4s      // outR = intensity*lr
    fmul    v1.4s, v2.4s, v23.4s      // outG = intensity*lg
    fmul    v3.4s, v2.4s, v24.4s      // outB = intensity*lb
    fadd    v0.4s, v0.4s, v27.4s      // +0.5: round-half-up
    fadd    v1.4s, v1.4s, v27.4s      // +0.5: round-half-up
    fadd    v3.4s, v3.4s, v27.4s      // +0.5: round-half-up
    fcvtzu  v0.4s, v0.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v1.4s, v1.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v3.4s, v3.4s          // floor(x+0.5): Kotlin roundToInt
    shl     v0.4s, v0.4s, #16       // R << 16
    shl     v1.4s, v1.4s, #8        // G << 8
    orr     v3.16b, v3.16b, v1.16b   // B|G
    orr     v3.16b, v3.16b, v0.16b   // B|G|R
    orr     v3.16b, v3.16b, v29.16b  // alpha = 0xFF
    str     q3, [x3]

.Ldone:
    ret

.size ksvgLightingDistantDiffuseRowNeon64, .-ksvgLightingDistantDiffuseRowNeon64

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): same Sobel/intensity math, then a
// linear->sRGB 256-byte LUT lookup instead of straight byte output.
// ---------------------------------------------------------------------------

// Load + broadcast LightingParams (x5) and the float/byte helpers into
// v16-v29. s25 (ss) is folded into the gradient scales s16/s17, then left
// dead (matches the non-linear prologue).
.macro LOAD_PARAMS
    ldr     s16, [x5]
    ldr     s17, [x5, #4]
    ldr     s18, [x5, #8]
    ldr     s19, [x5, #12]
    ldr     s20, [x5, #16]
    ldr     s21, [x5, #20]
    ldr     s22, [x5, #24]
    ldr     s23, [x5, #28]
    ldr     s24, [x5, #32]
    ldr     s25, [x5, #36]
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

.text
.align 2

/*
 * void ksvgLightingDistantDiffuseRowNeon64Linear(
 *     const jint* srcT, const jint* srcM, const jint* srcB,
 *     jint* dst, jint count, const LightingParams* params,
 *     const uint8_t* linearToSrgb);
 *
 * AArch64 ABI:
 *   x0 = srcT, x1 = srcM, x2 = srcB, x3 = dst, w4 = count, x5 = params
 *   x6 = linearToSrgb
 */
.global ksvgLightingDistantDiffuseRowNeon64Linear
.type ksvgLightingDistantDiffuseRowNeon64Linear, %function

// void ksvgLightingDistantDiffuseRowNeon64Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params,
//   const uint8_t* linearToSrgb)
//
// AAPCS64: x0-x5 as the non-linear kernel, x6 = linearToSrgb
// (ksvg_linear_to_srgb_lut).
//
// 8 output pixels / main iteration, mirror of the non-linear kernel: the
// Sobel/normalize/intensity block is identical, then the linear-light pack
// (0xFF alpha OR'd on, kept as linear bytes) is converted via the table at
// x6. LUT256_16 clobbers v16-v31, so params are reloaded via LOAD_PARAMS
// at the top of every iteration (and at tail entry).
ksvgLightingDistantDiffuseRowNeon64Linear:
    cbz     w4, .Llin_done

.Llin_loop8:
    cmp     w4, #8
    b.lo    .Llin_tail4

    LOAD_PARAMS

    // ------------------------------ TOP ---------------------------
    ld1     {v0.4s-v1.4s}, [x0]
    ldr     d2, [x0, #32]
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
    ld1     {v0.4s-v1.4s}, [x1]
    ldr     d2, [x1, #32]
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
    ld1     {v0.4s-v1.4s}, [x2]
    ldr     d2, [x2, #32]
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

    // Apply invLen and k/clamp to A.
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s      // clamp(dot*k) >= 0
    fmin    v3.4s, v3.4s, v26.4s      // clamp <= 1 (intensity)
    fmul    v6.4s, v3.4s, v22.4s      // outR = intensity*lr
    fmul    v7.4s, v3.4s, v23.4s      // outG = intensity*lg
    fmul    v8.4s, v3.4s, v24.4s      // outB = intensity*lb
    fadd    v6.4s, v6.4s, v27.4s      // +0.5: round-half-up
    fadd    v7.4s, v7.4s, v27.4s      // +0.5: round-half-up
    fadd    v8.4s, v8.4s, v27.4s      // +0.5: round-half-up
    fcvtzu  v6.4s, v6.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v7.4s, v7.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v8.4s, v8.4s          // floor(x+0.5): Kotlin roundToInt
    shl     v6.4s, v6.4s, #16       // R << 16
    shl     v7.4s, v7.4s, #8        // G << 8
    orr     v8.16b, v8.16b, v7.16b   // B|G
    orr     v8.16b, v8.16b, v6.16b   // B|G|R
    orr     v8.16b, v8.16b, v29.16b  // alpha = 0xFF
    mov     v0.16b, v8.16b          // stash batch A (linear ARGB)

    // Apply invLen and k/clamp to B.
    fmul    v3.4s, v1.4s, v5.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmax    v3.4s, v3.4s, v28.4s      // clamp(dot*k) >= 0
    fmin    v3.4s, v3.4s, v26.4s      // clamp <= 1 (intensity)
    fmul    v6.4s, v3.4s, v22.4s      // outR = intensity*lr
    fmul    v7.4s, v3.4s, v23.4s      // outG = intensity*lg
    fmul    v8.4s, v3.4s, v24.4s      // outB = intensity*lb
    fadd    v6.4s, v6.4s, v27.4s      // +0.5: round-half-up
    fadd    v7.4s, v7.4s, v27.4s      // +0.5: round-half-up
    fadd    v8.4s, v8.4s, v27.4s      // +0.5: round-half-up
    fcvtzu  v6.4s, v6.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v7.4s, v7.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v8.4s, v8.4s          // floor(x+0.5): Kotlin roundToInt
    shl     v6.4s, v6.4s, #16       // R << 16
    shl     v7.4s, v7.4s, #8        // G << 8
    orr     v8.16b, v8.16b, v7.16b   // B|G
    orr     v8.16b, v8.16b, v6.16b   // B|G|R
    orr     v8.16b, v8.16b, v29.16b  // alpha = 0xFF

    // v0/v8 = linear-light ARGB batches (A/B). Load the 256-byte L2S LUT
    // into v16-v31 (clobbers the params; reloaded next iteration), convert.
    mov     x9, x6
    ld1     {v16.16b-v19.16b}, [x9], #64
    ld1     {v20.16b-v23.16b}, [x9], #64
    ld1     {v24.16b-v27.16b}, [x9], #64
    ld1     {v28.16b-v31.16b}, [x9], #64
    movi    v12.16b, #63
    LUT256_16 v0, v0
    LUT256_16 v8, v8
    str     q0, [x3]
    str     q8, [x3, #16]

    // 8 pixels * 4 bytes; w4 stays a multiple of 4 (C++ contract).
    add     x0, x0, #32
    add     x1, x1, #32
    add     x2, x2, #32
    add     x3, x3, #32
    subs    w4, w4, #8
    cbnz    w4, .Llin_loop8
    b       .Llin_done

.Llin_tail4:
    // Params were clobbered by the last LUT load; reload for the 4-px tail.
    LOAD_PARAMS
    // 4-px tail: same Sobel/normalize/intensity math, one 4-lane batch
    // (v4 = dx, v5 = dy). The 2.0 constant weights the middle tap.
    fmov    v30.4s, #2.0

    // ---- Row T: overlapping l/m/r triplet; v3 = l+2m+r, v4 = r-l ----
    ldr     q0, [x0]
    ldr     q1, [x0, #4]
    ldr     q2, [x0, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v3.4s, v1.4s, v30.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    // ---- Row M: middle row contributes 2*(r-l) to dx only (dy taps
    // cancel), so only the l/r loads are needed ----
    ldr     q0, [x1]
    ldr     q2, [x1, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v2.4s, v2.4s
    fsub    v5.4s, v2.4s, v0.4s
    fadd    v5.4s, v5.4s, v5.4s
    fadd    v4.4s, v4.4s, v5.4s

    // ---- Row B: overlapping l/m/r triplet; v4 += r-l, v5 = sumB ----
    ldr     q0, [x2]
    ldr     q1, [x2, #4]
    ldr     q2, [x2, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v5.4s, v1.4s, v30.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    fsub    v5.4s, v5.4s, v3.4s      // dy = sumB - sumT
    fmul    v4.4s, v4.4s, v16.4s      // dx *= ss/invDx
    fmul    v5.4s, v5.4s, v17.4s      // dy *= ss/invDy

    fmul    v0.4s, v4.4s, v4.4s
    fmla    v0.4s, v5.4s, v5.4s
    fadd    v0.4s, v0.4s, v26.4s
    frsqrte v1.4s, v0.4s          // single rsqrt chain, 2 refinements
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v2.4s, v4.4s, v19.4s      // dot = lz - (dx*lx + dy*ly)
    fmla    v2.4s, v5.4s, v20.4s
    fsub    v2.4s, v21.4s, v2.4s
    fmul    v2.4s, v2.4s, v1.4s
    fmul    v2.4s, v2.4s, v18.4s
    fmax    v2.4s, v2.4s, v28.4s      // clamp(dot*k) >= 0
    fmin    v2.4s, v2.4s, v26.4s      // clamp <= 1 (intensity)
    fmul    v0.4s, v2.4s, v22.4s      // outR = intensity*lr
    fmul    v1.4s, v2.4s, v23.4s      // outG = intensity*lg
    fmul    v3.4s, v2.4s, v24.4s      // outB = intensity*lb
    fadd    v0.4s, v0.4s, v27.4s      // +0.5: round-half-up
    fadd    v1.4s, v1.4s, v27.4s      // +0.5: round-half-up
    fadd    v3.4s, v3.4s, v27.4s      // +0.5: round-half-up
    fcvtzu  v0.4s, v0.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v1.4s, v1.4s          // floor(x+0.5): Kotlin roundToInt
    fcvtzu  v3.4s, v3.4s          // floor(x+0.5): Kotlin roundToInt
    shl     v0.4s, v0.4s, #16       // R << 16
    shl     v1.4s, v1.4s, #8        // G << 8
    orr     v3.16b, v3.16b, v1.16b   // B|G
    orr     v3.16b, v3.16b, v0.16b   // B|G|R
    orr     v3.16b, v3.16b, v29.16b  // alpha = 0xFF

    mov     x9, x6
    ld1     {v16.16b-v19.16b}, [x9], #64
    ld1     {v20.16b-v23.16b}, [x9], #64
    ld1     {v24.16b-v27.16b}, [x9], #64
    ld1     {v28.16b-v31.16b}, [x9], #64
    movi    v12.16b, #63
    LUT256_16 v3, v3
    str     q3, [x3]

.Llin_done:
    ret

.size ksvgLightingDistantDiffuseRowNeon64Linear, .-ksvgLightingDistantDiffuseRowNeon64Linear
