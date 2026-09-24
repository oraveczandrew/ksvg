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

// Lane indices [0,1,2,3] for the per-pixel ux walk (integer, converted
// with ucvtf then scaled by dux). PC-relative adr/ldr, stays in .text.
.Llane_idx:
.word 0, 1, 2, 3

.global ksvgLightingSpotSpecularRowNeon64
.type ksvgLightingSpotSpecularRowNeon64, %function

// void ksvgLightingSpotSpecularRowNeon64(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const SpotLightingParams* params, float exponent)
//
// AAPCS64: x0 = srcT, x1 = srcM, x2 = srcB, x3 = dst,
//          w4 = count, x5 = params, s0 = exponent (7th arg, float).
//
// SpotLightingParams layout (cpu_dispatch.h, hard contract):
//   +0 invDx  +4 invDy  +8 k  +12 lx  +16 ly  +20 lz
//   +24 lr    +28 lg    +32 lb +36 ss +40 ux0 +44 uy +48 dux
//   +52 spotDirX +56 spotDirY +60 spotDirZ +64 spotCos
//   (lx/ly/lz = light position; ux0 = user-space x of output pixel 0,
//   uy = row y in user space, dux = user-space x step per pixel;
//   spotDir = normalized (target-pos), zeroed by C++ when tLen == 0;
//   spotCos = cos(cutoff), -1.0 when the cutoff is NaN (always inside).
//   NOTE: tLen == 0 rows never reach this kernel — C++ routes them to
//   the point kernel, which is identical to spot with factor = 1.)
//
// Straight (non-premultiplied) spot-specular row: point-specular math
// (per-pixel L, per-pixel h, per-lane double pow) plus the cone cutoff.
// The cutoff is computed pre-`pow` from Lhat (caller-saved NEON dies in
// `bl pow`) and stashed to the stack next to ndoth:
//
//   sdot = Lhatx*spotDirX + Lhaty*spotDirY + Lhatz*spotDirZ
//   negDot = clamp(-sdot, 0, 1); cutoff = negDot&(spotCos<=negDot)
//   ndoth = clamp0((hz-(dx*hx+dy*hy))*rec)
//   p     = pow(ndoth, exponent)          (scalar double per lane)
//   I     = clamp01(k * p * cutoff)
//   R/G/B = round(lr/lg/lb * I)           (floor(x+0.5) for non-negative)
//   A     = max(R, G, B)
//
// Straight (non-premultiplied) spot-specular row: mirrors the distant
// kernel body (Sobel gradients, frsqrte+2NR reciprocal sqrt), but the
// light direction L is per-pixel (like the point-diffuse kernel: ux walk
// + surfZ + len==0 guard) and the half vector h = normalize(L+(0,0,1))
// is per-pixel too (the distant kernel's h is loop-invariant). The
// clamped ndoth feeds a per-lane scalar DOUBLE libm pow (the reference
// uses Kotlin Math.pow / C++ std::pow double math). The multiply-by-k /
// clamp01 / round-pack is then identical to distant specular, with the
// alpha byte max(R, G, B) instead of 0xFF.
//
//   ux = ux0 + (idx+[0,1,2,3])*dux   (idx = x26 pixel index)
//   surfZ = centerAlpha*ss
//   L = (lx-ux, ly-uy, lz-surfZ); Lhat = (len==0) ? 0 : L/len
//   h = (hLen==0) ? 0 : (Lhat+(0,0,1))/hLen   (scalar len==0 path keeps
//     h = L+(0,0,1) = 0, hence ndoth = 0 — identical outcome)
//   ndoth = clamp0((N.Lhat... precisely (hz-(dx*hx+dy*hy))*rec)
//   p     = pow(ndoth, exponent)          (scalar double per lane)
//   I     = clamp01(k * p)
//   R/G/B = round(lr/lg/lb * I)           (floor(x+0.5) for non-negative)
//   A     = max(R, G, B)
//
// 8 output pixels / main iteration (two 4-lane batches), 4-px tail. Because
// outer call `pow` clobbers ALL caller-saved registers (x0-x17, v0-v7,
// v16-v31), every loop invariant lives in a callee-saved GPR (x19-x27) or
// on the stack, and v16-v31 (+ ux0/uy/dux) are reloaded between the pow
// block and the pack. The pixel index (x26) and lane literal (x27) are
// callee-saved GPRs precisely so they survive `bl pow`.
//
// Stack frame (288 bytes, 16-aligned):
//   [sp, #0]    x19 srcT        [sp,#40] x24 params
//   [sp, #8]    x20 srcM        [sp,#56] exponent (double)
//   [sp,#16]    x21 srcB        [sp,#80] ndoth stash A   (16 bytes)
//   [sp,#24]    x22 dst         [sp,#96] ndoth stash B   (16 bytes)
//   [sp,#32]    x23 count       [sp,#112] pow result A   (16 bytes)
//                               [sp,#128] pow result B   (16 bytes)
//                               [sp,#256] cutoff stash A (16 bytes)
//                               [sp,#272] cutoff stash B (16 bytes)
// (x25 = LUT pointer in the Linear kernel, a live GPR, not a slot.)
// Callee-saved state (AAPCS64: d8-d15, x29, x30 must survive the call):
//   [sp,#144]  d8   [sp,#152] d9   [sp,#160] d10 [sp,#168] d11
//   [sp,#176]  d12  [sp,#184] d13  [sp,#192] d14 [sp,#200] d15
//   [sp,#208]  x29               [sp,#216] x30
//   [sp,#224]  x25               [sp,#232] x26 (pixel index)
//   [sp,#240]  x27 (lane-index literal; [sp,#248] pad)
//
// x24 = params base. Exponent double is kept on the stack. The Sobel math
// uses v0-v12 (caller-saved, dead across pow by construction), and `bl pow`
// clobbers x30 on every call, so d8-d15 + x29/x30 are preserved in the
// prologue/epilogue (the armv7a sibling does the same with push {..,lr} +
// vpush {d8-d15}).

// Reload + broadcast PointLightingParams from x24 into v16-v25, v13,
// v15, v30 (s25 = ss folded into the gradient scales s16/s17, then kept
// live in v25 for surfZ), plus the float helpers: v26 = 1.0, v27 = 0.5,
// v28 = 0. Clobbers the caller-saved v16-v31 set — pow clobbers these
// anyway, so call it after every pow block and at the top of every
// iteration (the ux walk itself is index-arithmetic from x26, so no
// cross-pow vector state is lost).
.macro LOAD_PARAMS_PT
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
    ldr     s0, [x24, #40]      // ux0 (transient scalar)
    ldr     s1, [x24, #44]      // uy (transient scalar)
    ldr     s2, [x24, #48]      // dux (transient scalar)
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
    dup     v25.4s, v25.s[0]
    dup     v13.4s, v0.s[0]     // ux0
    dup     v15.4s, v1.s[0]     // uy
    dup     v30.4s, v2.s[0]     // dux
    fmov    v26.4s, #1.0
    fmov    v27.4s, #0.5
    movi    v28.4s, #0
.endm

// 4-lane vector pow (POW4_NEON, lighting_aarch64_pow_macros.S) replaced the
// old per-lane scalar double libm pow (POW4_STACK + bl pow); the ndoth stack
// stash and param reloads around it are gone (cutoff stays stashed).

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

ksvgLightingSpotSpecularRowNeon64:
    cbz     w4, .Ldone

    sub     sp, sp, #288
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #224]
    str     x27, [sp, #240]
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

    // Pixel index + lane-index literal in callee-saved x26/x27.
    mov     w26, #0                 // pixel index
    adr     x27, .Llane_idx

    b       .Lloop8

.Lloop8:
    cmp     w23, #8
    b.lo    .Ltail4

    // Per-iteration reload: the ux walk consumes dux from v30 every
    // iteration, and the post-pow mask setup kills it — so unlike distant
    // (no dux), the sRGB loop cannot hoist this to the prologue.
    LOAD_PARAMS_PT

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

    // Stash middle-row integer center alphas (outputs 0..3 need p1..p4,
    // outputs 4..7 need p5..p8). v14/v31 are Sobel-free and survive
    // until the surfZ conversion below (no call in between).
    ext     v14.16b, v0.16b, v1.16b, #4  // centers A (integer alphas)
    ext     v31.16b, v1.16b, v2.16b, #4  // centers B (integer alphas)

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

    // Surface heights: surfZ = centerAlpha*ss (float, per output).
    ucvtf   v14.4s, v14.4s
    fmul    v14.4s, v14.4s, v25.4s  // surfZA
    ucvtf   v31.4s, v31.4s
    fmul    v31.4s, v31.4s, v25.4s  // surfZB

    // Park dxA: the rsqrt chain below overwrites v5 with recB (same
    // hazard as the distant kernel, which parks its dot numerators in
    // v1/v3 first). dyA (v11) survives the chain untouched. v1 is free
    // here (batch-B numerator not yet computed).
    mov     v1.16b, v5.16b          // park dxA

    // ------------------- NORMALIZATION / LIGHTING -----------------
    // N chain identical to the diffuse kernel: n2 + frsqrte two
    // refinements (recA in v4, recB in v5). The dot operand is the
    // per-pixel half vector h = normalize(Lhat+(0,0,1)) (computed below),
    // not the loop-invariant h of the distant kernel.
    fmul    v0.4s, v5.4s, v5.4s
    fmla    v0.4s, v11.4s, v11.4s
    fadd    v0.4s, v0.4s, v26.4s    // nLen2_A

    fmul    v2.4s, v9.4s, v9.4s
    fmla    v2.4s, v12.4s, v12.4s
    fadd    v2.4s, v2.4s, v26.4s    // nLen2_B

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
    fmul    v4.4s, v4.4s, v6.4s    // recA
    fmul    v5.4s, v5.4s, v7.4s    // recB

    // ---- BATCH A: per-pixel L, h, ndoth ----
    // uxA = ux0 + (x26+[0,1,2,3])*dux (v0/v10 transient: nLen2_A and
    // sumT_B are dead; v11 = dyA stays live).
    dup     v10.4s, w26
    ldr     q0, [x27]
    add     v10.4s, v10.4s, v0.4s  // idx+[0,1,2,3] (integer)
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s  // (idx+lane)*dux
    fadd    v10.4s, v10.4s, v13.4s  // uxA

    // L_A = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard
    // (len==0 matches the scalar len==0 path: L=0 -> h=(0,0,1)-> ndoth
    // from N alone... precisely: scalar keeps L=0, h=normalize(0,0,1)
    // = (0,0,1); the masked version below yields Lhat=0, h=(0,0,1) —
    // identical. See the h block.)
    fsub    v6.4s, v19.4s, v10.4s   // LxA
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v14.4s   // LzA (surfZA dead after this)
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2A = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // lenA
    fcmeq   v3.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/lenA
    bic     v10.16b, v10.16b, v3.16b  // invLenA (0 when len==0)
    fmul    v6.4s, v6.4s, v10.4s   // LhatxA
    fmul    v7.4s, v7.4s, v10.4s   // LhatyA
    fmul    v8.4s, v8.4s, v10.4s   // LhatzA
    // ---- Spot cone A: cutoff from LhatA (v6/v7/v8), BEFORE the h block
    // below overwrites them. v10/v0 scratch (invLenA/nLen2 dead); cutoff parks at [sp,#256] (NEON dies in pow).
    ldr     s0, [x24, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x24, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x24, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x24, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoffA
    str     q10, [sp, #256]       // stash cutoffA
    // h_A = normalize(LhatA+(0,0,1)); zero-guarded like L (scalar
    // keeps h = L+(0,0,1) = 0 when hLen == 0; masked invH gives the
    // same h = 0). hLen2 association matches the scalar op order.
    fadd    v8.4s, v8.4s, v26.4s   // hz = Lhatz+1
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s   // hLen2A
    fsqrt   v14.4s, v10.4s         // hLenA
    fcmeq   v3.4s, v10.4s, #0.0    // hLen2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/hLenA
    bic     v10.16b, v10.16b, v3.16b  // invHA (0 when hLen==0)
    fmul    v6.4s, v6.4s, v10.4s   // hxA
    fmul    v7.4s, v7.4s, v10.4s   // hyA
    fmul    v8.4s, v8.4s, v10.4s   // hzA
    // ndothA = clamp0((hz-(dx*hx+dy*hy))*recA) (negation folded;
    // dxA comes from the v1 park — v5 now holds recB).
    fmul    v3.4s, v1.4s, v6.4s
    fmla    v3.4s, v11.4s, v7.4s
    fsub    v3.4s, v8.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s
    fmax    v3.4s, v3.4s, v28.4s

    // ---- BATCH B: per-pixel L, h, ndoth ----
    // uxB = ux0 + ((x26+4)+[0,1,2,3])*dux (v0/v10 transient again;
    // v12 = dyB stays live).
    add     w12, w26, #4
    dup     v10.4s, w12
    ldr     q0, [x27]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s  // uxB

    // L_B = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard.
    fsub    v6.4s, v19.4s, v10.4s   // LxB
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v31.4s   // LzB (surfZB dead after this)
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2B
    fsqrt   v14.4s, v10.4s         // lenB
    fcmeq   v2.4s, v10.4s, #0.0    // len2==0 mask (v2 = nLen2_B, dead)
    fdiv    v10.4s, v26.4s, v14.4s  // 1/lenB
    bic     v10.16b, v10.16b, v2.16b  // invLenB (0 when len==0)
    fmul    v6.4s, v6.4s, v10.4s
    fmul    v7.4s, v7.4s, v10.4s
    fmul    v8.4s, v8.4s, v10.4s   // LhatB
    // ---- Spot cone B: cutoff from LhatB (v6/v7/v8), BEFORE the h block
    // below overwrites them. v10/v0 scratch
    // (v0 = nLen2_B dead); cutoff parks at [sp,#272].
    ldr     s0, [x24, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x24, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x24, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x24, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoffB
    str     q10, [sp, #272]       // stash cutoffB
    // h_B = normalize(LhatB+(0,0,1)); zero-guarded.
    fadd    v8.4s, v8.4s, v26.4s   // hz = Lhatz+1
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s   // hLen2B
    fsqrt   v14.4s, v10.4s         // hLenB
    fcmeq   v2.4s, v10.4s, #0.0    // hLen2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/hLenB
    bic     v10.16b, v10.16b, v2.16b  // invHB (0 when hLen==0)
    fmul    v6.4s, v6.4s, v10.4s   // hxB
    fmul    v7.4s, v7.4s, v10.4s   // hyB
    fmul    v8.4s, v8.4s, v10.4s   // hzB
    // ndothB = clamp0((hz-(dx*hx+dy*hy))*recB) (negation folded).
    fmul    v1.4s, v9.4s, v6.4s
    fmla    v1.4s, v12.4s, v7.4s
    fsub    v1.4s, v8.4s, v1.4s
    fmul    v1.4s, v1.4s, v5.4s    // recB
    fmax    v1.4s, v1.4s, v28.4s

    // ndoth A/B -> vector pow in place (params survive from the prologue).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v3, v0
    POW4_NEON v1, v0
    mov     v2.16b, v1.16b      // park p_B: pack A clobbers v1
    movi    v30.4s, #0xff       // 0x000000ff byte mask (dux dead past pow)

    // ------------------------- PACK A (p in v3) -------------
    fmul    v3.4s, v3.4s, v18.4s     // k * p
    ldr     q10, [sp, #256]         // cutoffA (stashed pre-pow)
    fmul    v3.4s, v3.4s, v10.4s    // * cutoff
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
    fmul    v3.4s, v2.4s, v18.4s     // k * p
    ldr     q10, [sp, #272]         // cutoffB (stashed pre-pow)
    fmul    v3.4s, v3.4s, v10.4s    // * cutoff
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
    add     w26, w26, #8          // pixel index += 8 (ux walk)
    subs    w23, w23, #8
    cbnz    w23, .Lloop8
    b       .Ldone

.Ltail4:
    // Params/helpers still live from the prologue hoist — except v30 = dux,
    // killed by the loop's post-pow mask setup; reload for the tail ux walk
    // (runs at most once per row).
    LOAD_PARAMS_PT
    // v6 = 2.0 weights the middle tap (v15 stays uy, v30 stays dux).
    fmov    v6.4s, #2.0

    ldr     q0, [x19]
    ldr     q1, [x19, #4]
    ldr     q2, [x19, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v3.4s, v1.4s, v6.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    ldr     q0, [x20]
    ldr     q1, [x20, #4]
    ldr     q2, [x20, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fsub    v5.4s, v2.4s, v0.4s
    fadd    v5.4s, v5.4s, v5.4s
    fadd    v4.4s, v4.4s, v5.4s
    fmul    v14.4s, v1.4s, v25.4s  // surfZ = centers*ss (v14 free here)

    ldr     q0, [x21]
    ldr     q1, [x21, #4]
    ldr     q2, [x21, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v5.4s, v1.4s, v6.4s
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
    fmul    v1.4s, v1.4s, v2.4s      // rec (v0 = nLen2 dead)
    // ux = ux0 + (x26+[0,1,2,3])*dux (v10 transient; v0 dead).
    dup     v10.4s, w26
    ldr     q0, [x27]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s   // ux
    // L = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard.
    // (v2/v3/v0 dead; v7 = mask temp, free in tail.)
    fsub    v2.4s, v19.4s, v10.4s   // Lx
    fsub    v3.4s, v20.4s, v15.4s   // Ly
    fsub    v0.4s, v21.4s, v14.4s   // Lz (surfZ dead after this)
    fmul    v10.4s, v2.4s, v2.4s
    fmul    v14.4s, v3.4s, v3.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v0.4s, v0.4s    // len2
    fsqrt   v14.4s, v10.4s         // len
    fcmeq   v7.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/len
    bic     v10.16b, v10.16b, v7.16b  // invLen
    fmul    v2.4s, v2.4s, v10.4s   // Lhatx
    fmul    v3.4s, v3.4s, v10.4s   // Lhaty
    fmul    v0.4s, v0.4s, v10.4s   // Lhatz
    // ---- Spot cone (tail, single batch): cutoff from Lhat (v2/v3/v0), BEFORE the h block
    // below overwrites them.
    // v10 = cutoff, v6 = scratch (2.0 Sobel const dead); cutoff reuses
    // the A slot (tail runs alone).
    ldr     s6, [x24, #52]
    dup     v10.4s, v6.s[0]       // dirX
    fmul    v10.4s, v2.4s, v10.4s  // Lhatx*dirX
    ldr     s6, [x24, #56]
    dup     v6.4s, v6.s[0]        // dirY
    fmla    v10.4s, v3.4s, v6.4s  // += Lhaty*dirY
    ldr     s6, [x24, #60]
    dup     v6.4s, v6.s[0]        // dirZ
    fmla    v10.4s, v0.4s, v6.4s  // += Lhatz*dirZ = sdot
    ldr     s6, [x24, #64]
    dup     v6.4s, v6.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v6.4s, v10.4s, v6.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v6.16b  // cutoff
    str     q10, [sp, #256]       // stash cutoff (A slot)
    // h = normalize(Lhat+(0,0,1)); zero-guarded.
    fadd    v0.4s, v0.4s, v26.4s   // hz = Lhatz+1
    fmul    v10.4s, v2.4s, v2.4s
    fmul    v14.4s, v3.4s, v3.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v0.4s, v0.4s   // hLen2
    fsqrt   v14.4s, v10.4s         // hLen
    fcmeq   v7.4s, v10.4s, #0.0    // hLen2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/hLen
    bic     v10.16b, v10.16b, v7.16b  // invH
    fmul    v2.4s, v2.4s, v10.4s   // hx
    fmul    v3.4s, v3.4s, v10.4s   // hy
    fmul    v0.4s, v0.4s, v10.4s   // hz
    // ndoth = clamp0((hz-(dx*hx+dy*hy))*rec) (negation folded).
    fmul    v7.4s, v4.4s, v2.4s
    fmla    v7.4s, v5.4s, v3.4s
    fsub    v7.4s, v0.4s, v7.4s
    fmul    v2.4s, v7.4s, v1.4s
    fmax    v2.4s, v2.4s, v28.4s

    // ndoth -> vector pow in place (cutoff stays stashed, params survive).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v2, v0
    movi    v30.4s, #0xff       // 0x000000ff byte mask (dux dead past pow)

    fmul    v3.4s, v2.4s, v18.4s     // k * p
    ldr     q10, [sp, #256]         // cutoffA (stashed pre-pow)
    fmul    v3.4s, v3.4s, v10.4s    // * cutoff
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
    ldr     x27, [sp, #240]
    ldp     x25, x26, [sp, #224]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp, #0]
    add     sp, sp, #288
    ret

.size ksvgLightingSpotSpecularRowNeon64, .-ksvgLightingSpotSpecularRowNeon64

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): identical Sobel/normalize/ndoth/pow
// math, then instead of alpha = max(sRGB bytes) the alpha byte is set to
// max(Rlin, Glin, Blin) BEFORE the linear->sRGB 256-byte LUT conversion. The
// L2S LUT is monotonic, so LUT[max(linear)] == max(LUT[R],LUT[G],LUT[B]) ==
// max(sRGB R,G,B), matching the Kotlin reference's maxOf() AFTER the L2S map.
// The LUT loads clobber v16-v31, so params are reloaded at the top of every
// iteration (and at the 4-px tail), like the diffuse *Neon64Linear row.
//
// void ksvgLightingSpotSpecularRowNeon64Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const SpotLightingParams* params, float exponent,
//   const uint8_t* linearToSrgb)
//
// AAPCS64: x0-x4, x5 = params, s0 = exponent, x6 = linearToSrgb LUT.
// LUT pointer is saved into callee-saved x25 (x6 is clobbered by pow).
// ---------------------------------------------------------------------------

.text
.align 2
.global ksvgLightingSpotSpecularRowNeon64Linear
.type ksvgLightingSpotSpecularRowNeon64Linear, %function

ksvgLightingSpotSpecularRowNeon64Linear:
    cbz     w4, .Llin_done

    sub     sp, sp, #288
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #224]
    str     x27, [sp, #240]
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
    mov     x25, x6                 // linearToSrgb LUT (callee-saved GPR)

    fcvt    d0, s0
    str     d0, [sp, #56]

    // Pixel index + lane-index literal (callee-saved: survive `bl pow`).
    mov     w26, #0                 // pixel index
    adr     x27, .Llane_idx

    b       .Llin_loop8

.Llin_loop8:
    cmp     w23, #8
    b.lo    .Llin_tail4

    LOAD_PARAMS_PT

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

    // Stash middle-row integer center alphas (outputs 0..3 need p1..p4,
    // outputs 4..7 need p5..p8). v14/v31 are Sobel-free and survive
    // until the surfZ conversion below (no call in between).
    ext     v14.16b, v0.16b, v1.16b, #4  // centers A (integer alphas)
    ext     v31.16b, v1.16b, v2.16b, #4  // centers B (integer alphas)

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

    // Surface heights: surfZ = centerAlpha*ss (float, per output).
    ucvtf   v14.4s, v14.4s
    fmul    v14.4s, v14.4s, v25.4s  // surfZA
    ucvtf   v31.4s, v31.4s
    fmul    v31.4s, v31.4s, v25.4s  // surfZB

    // ------------------- NORMALIZATION / ndoth --------------------
    // N chain identical to the non-linear kernel (recA in v4, recB in
    // v5); per-pixel L/h replace the distant loop-invariant h. v0 (batch
    // A) / v2 (batch B masks) are dead nLen2 temporaries; x26 = pixel
    // index, x27 = lane-index literal (both survive `bl pow`).
    // Park dxA (v5 becomes recB in the chain below; dyA/v11 survives).
    mov     v1.16b, v5.16b          // park dxA
    fmul    v0.4s, v5.4s, v5.4s
    fmla    v0.4s, v11.4s, v11.4s
    fadd    v0.4s, v0.4s, v26.4s    // nLen2_A

    fmul    v2.4s, v9.4s, v9.4s
    fmla    v2.4s, v12.4s, v12.4s
    fadd    v2.4s, v2.4s, v26.4s    // nLen2_B

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
    fmul    v4.4s, v4.4s, v6.4s    // recA
    fmul    v5.4s, v5.4s, v7.4s    // recB

    // ---- BATCH A: per-pixel L, h, ndoth ----
    dup     v10.4s, w26
    ldr     q0, [x27]
    add     v10.4s, v10.4s, v0.4s  // idx+[0,1,2,3] (integer)
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s  // (idx+lane)*dux
    fadd    v10.4s, v10.4s, v13.4s  // uxA
    fsub    v6.4s, v19.4s, v10.4s   // LxA
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v14.4s   // LzA (surfZA dead after this)
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2A
    fsqrt   v14.4s, v10.4s
    fcmeq   v3.4s, v10.4s, #0.0
    fdiv    v10.4s, v26.4s, v14.4s
    bic     v10.16b, v10.16b, v3.16b  // invLenA
    fmul    v6.4s, v6.4s, v10.4s
    fmul    v7.4s, v7.4s, v10.4s
    fmul    v8.4s, v8.4s, v10.4s   // LhatA
    // ---- Spot cone A: cutoff from LhatA (v6/v7/v8), BEFORE the h block
    // below overwrites them. v10/v0 scratch (invLenA/nLen2 dead); cutoff
    // parks at [sp,#256] (NEON dies in pow).
    ldr     s0, [x24, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x24, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x24, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x24, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoffA
    str     q10, [sp, #256]       // stash cutoffA
    fadd    v8.4s, v8.4s, v26.4s   // hz = Lhatz+1
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s   // hLen2A
    fsqrt   v14.4s, v10.4s
    fcmeq   v3.4s, v10.4s, #0.0
    fdiv    v10.4s, v26.4s, v14.4s
    bic     v10.16b, v10.16b, v3.16b  // invHA
    fmul    v6.4s, v6.4s, v10.4s   // hxA
    fmul    v7.4s, v7.4s, v10.4s   // hyA
    fmul    v8.4s, v8.4s, v10.4s   // hzA
    fmul    v3.4s, v1.4s, v6.4s   // dxA from the v1 park (v5 is recB)
    fmla    v3.4s, v11.4s, v7.4s
    fsub    v3.4s, v8.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s
    fmax    v3.4s, v3.4s, v28.4s   // ndothA = clamp0

    // ---- BATCH B: per-pixel L, h, ndoth ----
    add     w12, w26, #4
    dup     v10.4s, w12
    ldr     q0, [x27]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s  // uxB
    fsub    v6.4s, v19.4s, v10.4s   // LxB
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v31.4s   // LzB (surfZB dead after this)
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2B
    fsqrt   v14.4s, v10.4s
    fcmeq   v2.4s, v10.4s, #0.0    // (v2 = nLen2_B, dead)
    fdiv    v10.4s, v26.4s, v14.4s
    bic     v10.16b, v10.16b, v2.16b  // invLenB
    fmul    v6.4s, v6.4s, v10.4s
    fmul    v7.4s, v7.4s, v10.4s
    fmul    v8.4s, v8.4s, v10.4s   // LhatB
    // ---- Spot cone B: cutoff from LhatB (v6/v7/v8), BEFORE the h block
    // below overwrites them. v10/v0 scratch (invLenA/nLen2 dead); cutoff
    // parks at [sp,#256] (NEON dies in pow).
    ldr     s0, [x24, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x24, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x24, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x24, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoffB
    str     q10, [sp, #272]       // stash cutoffB
    // h_B = normalize(LhatB+(0,0,1)); zero-guarded (scalar keeps h = 0
    // when hLen == 0; masked invH gives the same).
    fadd    v8.4s, v8.4s, v26.4s   // hz = Lhatz+1
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s   // hLen2B
    fsqrt   v14.4s, v10.4s
    fcmeq   v2.4s, v10.4s, #0.0
    fdiv    v10.4s, v26.4s, v14.4s
    bic     v10.16b, v10.16b, v2.16b  // invHB
    fmul    v6.4s, v6.4s, v10.4s   // hxB
    fmul    v7.4s, v7.4s, v10.4s   // hyB
    fmul    v8.4s, v8.4s, v10.4s   // hzB
    fmul    v1.4s, v9.4s, v6.4s
    fmla    v1.4s, v12.4s, v7.4s
    fsub    v1.4s, v8.4s, v1.4s
    fmul    v1.4s, v1.4s, v5.4s    // recB
    fmax    v1.4s, v1.4s, v28.4s   // ndothB = clamp0

    // ndoth A/B -> vector pow in place (params survive for the pack;
    // the next iteration reloads them after the LUT anyway).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v3, v0
    POW4_NEON v1, v0
    mov     v2.16b, v1.16b      // park p_B: pack A clobbers v1
    movi    v30.4s, #0xff       // 0x000000ff byte mask (dux dead past pow)

    // ------------------- PACK A (linear, alpha = max(Rlin,Glin,Blin)) ----
    fmul    v3.4s, v3.4s, v18.4s     // k * p
    ldr     q10, [sp, #256]         // cutoffA (stashed pre-pow)
    fmul    v3.4s, v3.4s, v10.4s    // * cutoff
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
    fmul    v3.4s, v2.4s, v18.4s     // k * p
    ldr     q10, [sp, #272]         // cutoffB (stashed pre-pow)
    fmul    v3.4s, v3.4s, v10.4s    // * cutoff
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
    mov     v8.16b, v4.16b          // stash B (v4 is LUT scratch below;
                                    // v8 = hzB is dead after ndoth)

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
    add     w26, w26, #8          // pixel index += 8 (ux walk)
    subs    w23, w23, #8
    cbnz    w23, .Llin_loop8
    b       .Llin_done

.Llin_tail4:
    LOAD_PARAMS_PT
    // v6 = 2.0 weights the middle tap (v15 stays uy, v30 stays dux).
    fmov    v6.4s, #2.0

    ldr     q0, [x19]
    ldr     q1, [x19, #4]
    ldr     q2, [x19, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v3.4s, v1.4s, v6.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    ldr     q0, [x20]
    ldr     q1, [x20, #4]
    ldr     q2, [x20, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fsub    v5.4s, v2.4s, v0.4s
    fadd    v5.4s, v5.4s, v5.4s
    fadd    v4.4s, v4.4s, v5.4s
    fmul    v14.4s, v1.4s, v25.4s  // surfZ = centers*ss (v14 free here)

    ldr     q0, [x21]
    ldr     q1, [x21, #4]
    ldr     q2, [x21, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fmul    v5.4s, v1.4s, v6.4s
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
    fmul    v1.4s, v1.4s, v2.4s      // rec (v0 = nLen2 dead)
    // ux = ux0 + (x26+[0,1,2,3])*dux (v10 transient; v0 dead).
    dup     v10.4s, w26
    ldr     q0, [x27]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s   // ux
    // L = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard.
    // (v2/v3/v0 dead; v7 = mask temp, free in tail.)
    fsub    v2.4s, v19.4s, v10.4s   // Lx
    fsub    v3.4s, v20.4s, v15.4s   // Ly
    fsub    v0.4s, v21.4s, v14.4s   // Lz (surfZ dead after this)
    fmul    v10.4s, v2.4s, v2.4s
    fmul    v14.4s, v3.4s, v3.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v0.4s, v0.4s    // len2
    fsqrt   v14.4s, v10.4s         // len
    fcmeq   v7.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/len
    bic     v10.16b, v10.16b, v7.16b  // invLen
    fmul    v2.4s, v2.4s, v10.4s   // Lhatx
    fmul    v3.4s, v3.4s, v10.4s   // Lhaty
    fmul    v0.4s, v0.4s, v10.4s   // Lhatz
    // ---- Spot cone (tail, single batch): cutoff from Lhat (v2/v3/v0),
    // BEFORE the h block below overwrites them.
    // v10 = cutoff, v6 = scratch (2.0 Sobel const dead); cutoff reuses
    // the A slot (tail runs alone).
    ldr     s6, [x24, #52]
    dup     v10.4s, v6.s[0]       // dirX
    fmul    v10.4s, v2.4s, v10.4s  // Lhatx*dirX
    ldr     s6, [x24, #56]
    dup     v6.4s, v6.s[0]        // dirY
    fmla    v10.4s, v3.4s, v6.4s  // += Lhaty*dirY
    ldr     s6, [x24, #60]
    dup     v6.4s, v6.s[0]        // dirZ
    fmla    v10.4s, v0.4s, v6.4s  // += Lhatz*dirZ = sdot
    ldr     s6, [x24, #64]
    dup     v6.4s, v6.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v6.4s, v10.4s, v6.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v6.16b  // cutoff
    str     q10, [sp, #256]       // stash cutoff (A slot)
    // h = normalize(Lhat+(0,0,1)); zero-guarded.
    fadd    v0.4s, v0.4s, v26.4s   // hz = Lhatz+1
    fmul    v10.4s, v2.4s, v2.4s
    fmul    v14.4s, v3.4s, v3.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v0.4s, v0.4s   // hLen2
    fsqrt   v14.4s, v10.4s         // hLen
    fcmeq   v7.4s, v10.4s, #0.0    // hLen2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/hLen
    bic     v10.16b, v10.16b, v7.16b  // invH
    fmul    v2.4s, v2.4s, v10.4s   // hx
    fmul    v3.4s, v3.4s, v10.4s   // hy
    fmul    v0.4s, v0.4s, v10.4s   // hz
    // ndoth = clamp0((hz-(dx*hx+dy*hy))*rec) (negation folded).
    fmul    v7.4s, v4.4s, v2.4s
    fmla    v7.4s, v5.4s, v3.4s
    fsub    v7.4s, v0.4s, v7.4s
    fmul    v2.4s, v7.4s, v1.4s
    fmax    v2.4s, v2.4s, v28.4s

    // ndoth -> vector pow in place (cutoff stays stashed, params survive).
    ldr     d0, [sp, #56]
    fcvt    s0, d0
    dup     v0.4s, v0.s[0]      // y = exponent broadcast
    POW4_NEON v2, v0
    movi    v30.4s, #0xff       // 0x000000ff byte mask (dux dead past pow)

    fmul    v3.4s, v2.4s, v18.4s     // k * p
    ldr     q10, [sp, #256]         // cutoffA (stashed pre-pow)
    fmul    v3.4s, v3.4s, v10.4s    // * cutoff
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
    ldr     x27, [sp, #240]
    ldp     x25, x26, [sp, #224]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp, #0]
    add     sp, sp, #288
    ret

.size ksvgLightingSpotSpecularRowNeon64Linear, .-ksvgLightingSpotSpecularRowNeon64Linear

EMIT_POW4_NEON_TABLES
#ifndef __APPLE__
.section .note.GNU-stack,"",%progbits
#endif
