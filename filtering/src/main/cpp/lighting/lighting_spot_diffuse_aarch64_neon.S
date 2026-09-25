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

// Lane indices [0,1,2,3] for the per-pixel ux walk (integer, converted
// with ucvtf then scaled by dux). PC-relative adr/ldr, stays in .text.
.Llane_idx:
.word 0, 1, 2, 3

.global ksvgLightingSpotDiffuseRowNeon64
.type ksvgLightingSpotDiffuseRowNeon64, %function

// void ksvgLightingSpotDiffuseRowNeon64(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const SpotLightingParams* params)
//
// AAPCS64:
//   x0 = srcT, x1 = srcM, x2 = srcB, x3 = dst, w4 = count, x5 = params
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
// Processes 8 ARGB8888 pixels per iteration as two independent 4-lane
// batches (A = outputs 0..3, B = outputs 4..7). Sobel loads are identical
// to ksvgLightingDistantDiffuseRowNeon64: each source row loads exactly
// 10 pixels (ld1 v0-v1 plus ldr d2 = 40 bytes); the two 4-pixel stencil
// windows are derived from the same extracted alpha vectors via ext.
// C++ only calls this kernel with count > 0 (cbz guard) and a multiple
// of 4 (the .Ltail4 fallthrough handles exactly the 4-px remainder).
//
// math (matches applyScalarPixel_full lightType==2 op order):
//   h = (alpha >> 24) * ss          (ss is folded into the scales below;
//                                    the surface height uses the raw ss)
//   dxRel = (rT-lT) + 2*(rM-lM) + (rB-lB)
//   dyRel = (lB+2*mB+rB) - (lT+2*mT+rT)
//   nx = -dxRel*ss/invDx, ny = -dyRel*ss/invDy, nz = 1
//   rec = rsqrt(nx^2+ny^2+1) with 2 Newton-Raphson refinements
//   ux = ux0 + (idx+[0,1,2,3])*dux   (idx = x9 pixel index)
//   surfZ = centerAlpha*ss            (middle-row center tap per output)
//   L = (lx-ux, ly-uy, lz-surfZ); len2 = (Lx^2+Ly^2)+Lz^2
//   len = sqrt(len2); invLen = (len2==0) ? 0 : 1/len
//   (len==0 matches the scalar factor=0 path: L=0 -> dot=0 -> intensity 0)
//   Lhat = L*invLen
//   sdot = Lhatx*spotDirX + Lhaty*spotDirY + Lhatz*spotDirZ
//   negDot = clamp(-sdot, 0, 1)   (the upper clamp mirrors the scalar
//     [-1,1] clamp of the cone dot; spotCos <= 1 always)
//   cutoff = negDot & (spotCos <= negDot ? all-ones : 0)
//     (spotCos = -1 for NaN cutoff: always inside)
//   dot = (Lhatz - (dx*Lhatx + dy*Lhaty)) * rec   (negation folded, same
//         shape as the distant kernel: dot = (N.L) with N=(-dx,-dy,1)*rec)
//   intensity = clamp(dot*k*cutoff, 0, 1)
//     (== clamp(clamp(dot,0)*k*factor,0,1): cutoff >= 0, k >= 0)
//   out = (round(lr*intensity)<<16) | (round(lg*intensity)<<8)
//         | round(lb*intensity) | 0xFF000000
//   round(x) for non-negative x is floor(x + 0.5) (v27 bias + fcvtzu).
//
// Register map (loop-invariant):
//   v16 = ss/invDx   v17 = ss/invDy   v18 = k    v19 = lx   v20 = ly
//   v21 = lz         v22 = lr         v23 = lg   v24 = lb   v25 = ss
//   v26 = 1.0f       v27 = 0.5f       v28 = 0.0f v29 = 0xFF000000 bytes
//   v13 = ux0        v15 = uy         v30 = dux  (broadcasts)
//   x9  = pixel index (integer, += 8 per main iteration)
//   x10 = &.Llane_idx (integer lane-index literal)
//   v0-v12, v14, v31 = scratch; v14/v31 stash the middle-row integer
//   center alphas across the BOTTOM section (both are Sobel-free).
ksvgLightingSpotDiffuseRowNeon64:
    cbz     w4, .Ldone

    /* Spill d8-d15 (AAPCS64 callee-saved); without this the caller's FP
    state dies here and the failure surfaces rows later. */
    sub     sp, sp, #64
    stp     d8, d9, [sp, #0]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

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
    ldr     s13, [x5, #40]      // ux0
    ldr     s15, [x5, #44]      // uy
    ldr     s30, [x5, #48]      // dux

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
    dup     v25.4s, v25.s[0]
    dup     v13.4s, v13.s[0]
    dup     v15.4s, v15.s[0]
    dup     v30.4s, v30.s[0]
    fmov    v26.4s, #1.0
    fmov    v27.4s, #0.5
    movi    v28.4s, #0
    movi    v29.4s, #0xff, lsl #24

    mov     w9, #0              // pixel index
    adr     x10, .Llane_idx

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

    // Stash middle-row integer center alphas (outputs 0..3 need p1..p4,
    // outputs 4..7 need p5..p8). v14/v31 are Sobel-free.
    ext     v14.16b, v0.16b, v1.16b, #4  // centers A (integer alphas)
    ext     v31.16b, v1.16b, v2.16b, #4  // centers B (integer alphas)

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

    // Surface heights: surfZ = centerAlpha*ss (float, per output).
    ucvtf   v14.4s, v14.4s
    fmul    v14.4s, v14.4s, v25.4s  // surfZA
    ucvtf   v31.4s, v31.4s
    fmul    v31.4s, v31.4s, v25.4s  // surfZB

    // ------------------- BATCH A: N, L, dot, pack -----------------
    // N length chain (same rsqrt+2NR as distant): v4 = recA.
    fmul    v0.4s, v5.4s, v5.4s
    fmla    v0.4s, v11.4s, v11.4s
    fadd    v0.4s, v0.4s, v26.4s    // nLen2_A
    frsqrte v4.4s, v0.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v0.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v0.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s    // recA

    // uxA = ux0 + (x9+[0,1,2,3])*dux (v0/v10 transient, v11=dyA live!).
    dup     v10.4s, w9
    ldr     q0, [x10]
    add     v10.4s, v10.4s, v0.4s  // idx+[0,1,2,3] (integer)
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s  // (idx+lane)*dux
    fadd    v10.4s, v10.4s, v13.4s  // uxA

    // L_A = (lx-ux, ly-uy, lz-surfZ).
    fsub    v6.4s, v19.4s, v10.4s   // LxA
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v14.4s   // LzA (surfZA dead after this)
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2A = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // lenA
    fcmeq   v3.4s, v10.4s, #0.0    // len2==0 mask (scalar factor=0 path)
    fdiv    v10.4s, v26.4s, v14.4s  // 1/lenA
    bic     v10.16b, v10.16b, v3.16b  // invLenA (0 when len==0)
    fmul    v6.4s, v6.4s, v10.4s   // LhatxA
    fmul    v7.4s, v7.4s, v10.4s   // LhatyA
    fmul    v8.4s, v8.4s, v10.4s   // LhatzA
    // ---- Spot cone: cutoff from the normalized light direction ----
    // sdot = Lhat.dir; negDot = clamp(-sdot,0,1) (upper clamp mirrors
    // the scalar [-1,1] clamp of the cone dot); cutoff = negDot masked
    // by (spotCos <= negDot). spotCos = -1 (NaN cutoff) = always inside.
    // v10/v0 are scratch here (invLen/nLen2 dead).
    ldr     s0, [x5, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x5, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x5, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x5, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoff
    // dotA = (Lhatz - (dx*Lhatx + dy*Lhaty)) * rec, then *k*cutoff/clamp.
    fmul    v3.4s, v5.4s, v6.4s
    fmla    v3.4s, v11.4s, v7.4s
    fsub    v3.4s, v8.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmul    v3.4s, v3.4s, v10.4s  // *cutoff
    fmax    v3.4s, v3.4s, v28.4s      // clamp(dot*k*cutoff) >= 0
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

    // ------------------- BATCH B: N, L, dot, pack -----------------
    // N length chain: v4 = recB (v4 dead after batch A dot).
    fmul    v0.4s, v9.4s, v9.4s
    fmla    v0.4s, v12.4s, v12.4s
    fadd    v0.4s, v0.4s, v26.4s    // nLen2_B
    frsqrte v4.4s, v0.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v0.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v0.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s    // recB

    // uxB = ux0 + ((x9+4)+[0,1,2,3])*dux.
    add     w12, w9, #4
    dup     v10.4s, w12
    ldr     q0, [x10]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s  // uxB

    // L_B = (lx-ux, ly-uy, lz-surfZ).
    fsub    v6.4s, v19.4s, v10.4s   // LxB
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v31.4s   // LzB (surfZB dead after this)
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2B = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // lenB
    fcmeq   v3.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/lenB
    bic     v10.16b, v10.16b, v3.16b  // invLenB (0 when len==0)
    fmul    v6.4s, v6.4s, v10.4s   // LhatxB
    fmul    v7.4s, v7.4s, v10.4s   // LhatyB
    fmul    v8.4s, v8.4s, v10.4s   // LhatzB
    // ---- Spot cone: cutoff from the normalized light direction ----
    // (same shape as batch A; v10/v0 are scratch here.)
    ldr     s0, [x5, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x5, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x5, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x5, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoff
    // dotB = (Lhatz - (dx*Lhatx + dy*Lhaty)) * rec, then *k*cutoff/clamp.
    fmul    v3.4s, v9.4s, v6.4s
    fmla    v3.4s, v12.4s, v7.4s
    fsub    v3.4s, v8.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmul    v3.4s, v3.4s, v10.4s  // *cutoff
    fmax    v3.4s, v3.4s, v28.4s      // clamp(dot*k*cutoff) >= 0
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
    // x9 tracks the pixel index for the ux walk.
    add     x0, x0, #32
    add     x1, x1, #32
    add     x2, x2, #32
    add     x3, x3, #32
    add     w9, w9, #8
    subs    w4, w4, #8
    cbnz    w4, .Lloop8
    b       .Ldone

.Ltail4:
    // 4-px tail: same Sobel/normalize/L/dot math, one 4-lane batch
    // (v4 = dx, v5 = dy). The middle row loads l/m/r (m = centers).
    // v6 = 2.0 weights the middle tap (v30 stays dux).
    fmov    v6.4s, #2.0

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
    fmul    v3.4s, v1.4s, v6.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    // ---- Row M: l/m/r; dx += 2*(r-l); centers = m*ss ----
    ldr     q0, [x1]
    ldr     q1, [x1, #4]
    ldr     q2, [x1, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fsub    v7.4s, v2.4s, v0.4s
    fadd    v7.4s, v7.4s, v7.4s
    fadd    v4.4s, v4.4s, v7.4s
    fmul    v14.4s, v1.4s, v25.4s  // surfZ (v14 scratch here)

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
    fmul    v5.4s, v1.4s, v6.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    fsub    v5.4s, v5.4s, v3.4s      // dy = sumB - sumT
    fmul    v4.4s, v4.4s, v16.4s      // dx *= ss/invDx
    fmul    v5.4s, v5.4s, v17.4s      // dy *= ss/invDy

    // N length chain: single rsqrt, 2 refinements (v1 = rec).
    fmul    v0.4s, v4.4s, v4.4s
    fmla    v0.4s, v5.4s, v5.4s
    fadd    v0.4s, v0.4s, v26.4s
    frsqrte v1.4s, v0.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s      // rec

    // ux = ux0 + (x9+[0,1,2,3])*dux.
    dup     v10.4s, w9
    ldr     q0, [x10]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s   // ux (v0 dead after n-chain? v0=nLen2
                                     // consumed by rsqrt -> free. v1=rec live.)

    // L = (lx-ux, ly-uy, lz-surfZ).
    fsub    v2.4s, v19.4s, v10.4s   // Lx
    fsub    v3.4s, v20.4s, v15.4s   // Ly
    fsub    v0.4s, v21.4s, v14.4s   // Lz (surfZ dead after this)
    fmul    v10.4s, v2.4s, v2.4s
    fmul    v14.4s, v3.4s, v3.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v0.4s, v0.4s    // len2 = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // len
    fcmeq   v7.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/len
    bic     v10.16b, v10.16b, v7.16b  // invLen (0 when len==0)
    fmul    v2.4s, v2.4s, v10.4s   // Lhatx
    fmul    v3.4s, v3.4s, v10.4s   // Lhaty
    fmul    v0.4s, v0.4s, v10.4s   // Lhatz
    // ---- Spot cone: cutoff from the normalized light direction ----
    // (same shape as batch A; v10 = cutoff, v6 = scratch — the 2.0
    // Sobel const is dead here.)
    ldr     s6, [x5, #52]
    dup     v10.4s, v6.s[0]       // dirX
    fmul    v10.4s, v2.4s, v10.4s  // Lhatx*dirX
    ldr     s6, [x5, #56]
    dup     v6.4s, v6.s[0]        // dirY
    fmla    v10.4s, v3.4s, v6.4s  // += Lhaty*dirY
    ldr     s6, [x5, #60]
    dup     v6.4s, v6.s[0]        // dirZ
    fmla    v10.4s, v0.4s, v6.4s  // += Lhatz*dirZ = sdot
    ldr     s6, [x5, #64]
    dup     v6.4s, v6.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v6.4s, v10.4s, v6.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v6.16b  // cutoff
    // dot = (Lhatz - (dx*Lhatx + dy*Lhaty)) * rec, then *k*cutoff/clamp.
    fmul    v7.4s, v4.4s, v2.4s
    fmla    v7.4s, v5.4s, v3.4s
    fsub    v7.4s, v0.4s, v7.4s
    fmul    v2.4s, v7.4s, v1.4s
    fmul    v2.4s, v2.4s, v18.4s
    fmul    v2.4s, v2.4s, v10.4s  // *cutoff
    fmax    v2.4s, v2.4s, v28.4s      // clamp(dot*k*cutoff) >= 0
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
    ldp     d14, d15, [sp, #48]
    ldp     d12, d13, [sp, #32]
    ldp     d10, d11, [sp, #16]
    ldp     d8, d9, [sp, #0]
    add     sp, sp, #64
    ret

.size ksvgLightingSpotDiffuseRowNeon64, .-ksvgLightingSpotDiffuseRowNeon64

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): same Sobel/L/intensity math, then
// a linear->sRGB 256-byte LUT lookup instead of straight byte output.
// ---------------------------------------------------------------------------

// Load + broadcast SpotLightingParams (x5) and the float/byte helpers
// into v16-v30 (s25 = ss folded into the gradient scales s16/s17, then
// kept live in v25 for surfZ; ux0/uy/dux broadcast into v13/v15/v30).
// Clobbers the caller-saved v16-v31 set — the LUT load clobbers these
// anyway, so call it at the top of every iteration (and at tail entry).
// x9 (pixel index) and x10 (lane literal) survive in GPRs.
.macro LOAD_PARAMS_PT
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
    ldr     s0, [x5, #40]
    ldr     s1, [x5, #44]
    ldr     s2, [x5, #48]
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
    dup     v13.4s, v0.s[0]
    dup     v15.4s, v1.s[0]
    dup     v30.4s, v2.s[0]
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
.global ksvgLightingSpotDiffuseRowNeon64Linear
.type ksvgLightingSpotDiffuseRowNeon64Linear, %function

// void ksvgLightingSpotDiffuseRowNeon64Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const SpotLightingParams* params,
//   const uint8_t* linearToSrgb)
//
// AAPCS64: x0-x5 as the non-linear kernel, x6 = linearToSrgb
// (ksvg_linear_to_srgb_lut).
//
// 8 output pixels / main iteration, mirror of the non-linear kernel: the
// Sobel/normalize/L/intensity block is identical, then the linear-light
// pack (0xFF alpha OR'd on, kept as linear bytes) is converted via the
// table at x6. LUT256_16 clobbers v16-v31 (incl. v13/v15/v30), so params
// are reloaded via LOAD_PARAMS_PT at the top of every iteration (and at
// tail entry); the ux walk itself is index-arithmetic from x9, so no
// cross-iteration vector state is lost.
ksvgLightingSpotDiffuseRowNeon64Linear:
    cbz     w4, .Llin_done
    sub     sp, sp, #64
    stp     d8, d9, [sp, #0]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]
    mov     w9, #0              // pixel index
    adr     x10, .Llane_idx

.Llin_loop8:
    cmp     w4, #8
    b.lo    .Llin_tail4

    LOAD_PARAMS_PT

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

    // Stash middle-row integer center alphas (v14/v31 are Sobel-free).
    ext     v14.16b, v0.16b, v1.16b, #4  // centers A (integer alphas)
    ext     v31.16b, v1.16b, v2.16b, #4  // centers B (integer alphas)

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

    // Surface heights: surfZ = centerAlpha*ss (float, per output).
    ucvtf   v14.4s, v14.4s
    fmul    v14.4s, v14.4s, v25.4s  // surfZA
    ucvtf   v31.4s, v31.4s
    fmul    v31.4s, v31.4s, v25.4s  // surfZB

    // ------------------- BATCH A: N, L, dot, pack -----------------
    fmul    v0.4s, v5.4s, v5.4s
    fmla    v0.4s, v11.4s, v11.4s
    fadd    v0.4s, v0.4s, v26.4s    // nLen2_A
    frsqrte v4.4s, v0.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v0.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v0.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s    // recA

    // uxA = ux0 + (x9+[0,1,2,3])*dux.
    dup     v10.4s, w9
    ldr     q0, [x10]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s  // uxA

    // L_A = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard.
    fsub    v6.4s, v19.4s, v10.4s   // LxA
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v14.4s   // LzA
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2A = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // lenA
    fcmeq   v3.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/lenA
    bic     v10.16b, v10.16b, v3.16b  // invLenA (0 when len==0)
    fmul    v6.4s, v6.4s, v10.4s
    fmul    v7.4s, v7.4s, v10.4s
    fmul    v8.4s, v8.4s, v10.4s   // LhatA
    // ---- Spot cone: cutoff from the normalized light direction ----
    // (same shape as the non-linear batch A; v10/v0 are scratch here.)
    ldr     s0, [x5, #52]
    dup     v10.4s, v0.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s0, [x5, #56]
    dup     v0.4s, v0.s[0]        // dirY
    fmla    v10.4s, v7.4s, v0.4s  // += Lhaty*dirY
    ldr     s0, [x5, #60]
    dup     v0.4s, v0.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v0.4s  // += Lhatz*dirZ = sdot
    ldr     s0, [x5, #64]
    dup     v0.4s, v0.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v0.4s, v10.4s, v0.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v0.16b  // cutoff
    fmul    v3.4s, v5.4s, v6.4s
    fmla    v3.4s, v11.4s, v7.4s
    fsub    v3.4s, v8.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmul    v3.4s, v3.4s, v10.4s  // *cutoff
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v8.4s, v3.4s, v24.4s
    fadd    v6.4s, v6.4s, v27.4s
    fadd    v7.4s, v7.4s, v27.4s
    fadd    v8.4s, v8.4s, v27.4s
    fcvtzu  v6.4s, v6.4s
    fcvtzu  v7.4s, v7.4s
    fcvtzu  v8.4s, v8.4s
    shl     v6.4s, v6.4s, #16
    shl     v7.4s, v7.4s, #8
    orr     v8.16b, v8.16b, v7.16b
    orr     v8.16b, v8.16b, v6.16b
    orr     v8.16b, v8.16b, v29.16b  // alpha = 0xFF
    mov     v0.16b, v8.16b          // stash batch A (linear ARGB)

    // ------------------- BATCH B: N, L, dot, pack -----------------
    fmul    v2.4s, v9.4s, v9.4s
    fmla    v2.4s, v12.4s, v12.4s
    fadd    v2.4s, v2.4s, v26.4s    // nLen2_B
    frsqrte v4.4s, v2.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v2.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s
    fmul    v6.4s, v4.4s, v4.4s
    frsqrts v6.4s, v2.4s, v6.4s
    fmul    v4.4s, v4.4s, v6.4s    // recB (v2=nLen2, v0 stashed batch A)

    // uxB = ux0 + ((x9+4)+[0,1,2,3])*dux.
    add     w12, w9, #4
    dup     v10.4s, w12
    ldr     q6, [x10]
    add     v10.4s, v10.4s, v6.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s  // uxB

    // L_B = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard.
    fsub    v6.4s, v19.4s, v10.4s   // LxB
    fsub    v7.4s, v20.4s, v15.4s   // Ly (row-constant)
    fsub    v8.4s, v21.4s, v31.4s   // LzB
    fmul    v10.4s, v6.4s, v6.4s
    fmul    v14.4s, v7.4s, v7.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v8.4s, v8.4s    // len2B = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // lenB
    fcmeq   v3.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/lenB
    bic     v10.16b, v10.16b, v3.16b  // invLenB (0 when len==0)
    fmul    v6.4s, v6.4s, v10.4s
    fmul    v7.4s, v7.4s, v10.4s
    fmul    v8.4s, v8.4s, v10.4s   // LhatB
    // ---- Spot cone: cutoff from the normalized light direction ----
    // (same shape as batch A, but v0 holds the stashed batch-A linear
    // ARGB here — v2 (dead nLen2) is the scratch instead of v0.)
    ldr     s2, [x5, #52]
    dup     v10.4s, v2.s[0]       // dirX
    fmul    v10.4s, v6.4s, v10.4s  // Lhatx*dirX
    ldr     s2, [x5, #56]
    dup     v2.4s, v2.s[0]        // dirY
    fmla    v10.4s, v7.4s, v2.4s  // += Lhaty*dirY
    ldr     s2, [x5, #60]
    dup     v2.4s, v2.s[0]        // dirZ
    fmla    v10.4s, v8.4s, v2.4s  // += Lhatz*dirZ = sdot
    ldr     s2, [x5, #64]
    dup     v2.4s, v2.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v2.4s, v10.4s, v2.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v2.16b  // cutoff
    fmul    v3.4s, v9.4s, v6.4s
    fmla    v3.4s, v12.4s, v7.4s
    fsub    v3.4s, v8.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s
    fmul    v3.4s, v3.4s, v18.4s
    fmul    v3.4s, v3.4s, v10.4s  // *cutoff
    fmax    v3.4s, v3.4s, v28.4s
    fmin    v3.4s, v3.4s, v26.4s
    fmul    v6.4s, v3.4s, v22.4s
    fmul    v7.4s, v3.4s, v23.4s
    fmul    v8.4s, v3.4s, v24.4s
    fadd    v6.4s, v6.4s, v27.4s
    fadd    v7.4s, v7.4s, v27.4s
    fadd    v8.4s, v8.4s, v27.4s
    fcvtzu  v6.4s, v6.4s
    fcvtzu  v7.4s, v7.4s
    fcvtzu  v8.4s, v8.4s
    shl     v6.4s, v6.4s, #16
    shl     v7.4s, v7.4s, #8
    orr     v8.16b, v8.16b, v7.16b
    orr     v8.16b, v8.16b, v6.16b
    orr     v8.16b, v8.16b, v29.16b  // alpha = 0xFF

    // v0/v8 = linear-light ARGB batches (A/B). Load the 256-byte L2S LUT
    // into v16-v31 (clobbers the params; reloaded next iteration), convert.
    // x11 = LUT pointer (x9 pixel index and x10 literal must survive).
    mov     x11, x6
    ld1     {v16.16b-v19.16b}, [x11], #64
    ld1     {v20.16b-v23.16b}, [x11], #64
    ld1     {v24.16b-v27.16b}, [x11], #64
    ld1     {v28.16b-v31.16b}, [x11], #64
    movi    v12.16b, #63
    LUT256_16 v0, v0
    LUT256_16 v8, v8
    str     q0, [x3]
    str     q8, [x3, #16]

    // 8 pixels * 4 bytes; w4 stays a multiple of 4 (C++ contract).
    // x9 tracks the pixel index for the ux walk.
    add     x0, x0, #32
    add     x1, x1, #32
    add     x2, x2, #32
    add     x3, x3, #32
    add     w9, w9, #8
    subs    w4, w4, #8
    cbnz    w4, .Llin_loop8
    b       .Llin_done

.Llin_tail4:
    // Params were clobbered by the last LUT load; reload for the 4-px tail.
    LOAD_PARAMS_PT
    // 4-px tail: same Sobel/normalize/L/intensity math, one 4-lane batch
    // (v4 = dx, v5 = dy). The middle row loads l/m/r (m = centers).
    // v6 = 2.0 weights the middle tap (v30 stays dux).
    fmov    v6.4s, #2.0

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
    fmul    v3.4s, v1.4s, v6.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s
    fsub    v4.4s, v2.4s, v0.4s

    // ---- Row M: l/m/r; dx += 2*(r-l); centers = m*ss ----
    ldr     q0, [x1]
    ldr     q1, [x1, #4]
    ldr     q2, [x1, #8]
    ushr    v0.4s, v0.4s, #24
    ushr    v1.4s, v1.4s, #24
    ushr    v2.4s, v2.4s, #24
    ucvtf   v0.4s, v0.4s
    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    fsub    v7.4s, v2.4s, v0.4s
    fadd    v7.4s, v7.4s, v7.4s
    fadd    v4.4s, v4.4s, v7.4s
    fmul    v14.4s, v1.4s, v25.4s  // surfZ (v14 scratch here)

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
    fmul    v5.4s, v1.4s, v6.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    fsub    v5.4s, v5.4s, v3.4s      // dy = sumB - sumT
    fmul    v4.4s, v4.4s, v16.4s      // dx *= ss/invDx
    fmul    v5.4s, v5.4s, v17.4s      // dy *= ss/invDy

    // N length chain: single rsqrt, 2 refinements (v1 = rec).
    fmul    v0.4s, v4.4s, v4.4s
    fmla    v0.4s, v5.4s, v5.4s
    fadd    v0.4s, v0.4s, v26.4s
    frsqrte v1.4s, v0.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s
    fmul    v3.4s, v1.4s, v1.4s
    frsqrts v2.4s, v0.4s, v3.4s
    fmul    v1.4s, v1.4s, v2.4s      // rec

    // ux = ux0 + (x9+[0,1,2,3])*dux (v0 dead after the rsqrt chain).
    dup     v10.4s, w9
    ldr     q0, [x10]
    add     v10.4s, v10.4s, v0.4s
    ucvtf   v10.4s, v10.4s
    fmul    v10.4s, v10.4s, v30.4s
    fadd    v10.4s, v10.4s, v13.4s   // ux

    // L = (lx-ux, ly-uy, lz-surfZ); normalize with len==0 guard.
    fsub    v2.4s, v19.4s, v10.4s   // Lx
    fsub    v3.4s, v20.4s, v15.4s   // Ly
    fsub    v0.4s, v21.4s, v14.4s   // Lz (surfZ dead after this)
    fmul    v10.4s, v2.4s, v2.4s
    fmul    v14.4s, v3.4s, v3.4s
    fadd    v10.4s, v10.4s, v14.4s
    fmla    v10.4s, v0.4s, v0.4s    // len2 = (Lx^2+Ly^2)+Lz^2
    fsqrt   v14.4s, v10.4s         // len
    fcmeq   v7.4s, v10.4s, #0.0    // len2==0 mask
    fdiv    v10.4s, v26.4s, v14.4s  // 1/len
    bic     v10.16b, v10.16b, v7.16b  // invLen (0 when len==0)
    fmul    v2.4s, v2.4s, v10.4s   // Lhatx
    fmul    v3.4s, v3.4s, v10.4s   // Lhaty
    fmul    v0.4s, v0.4s, v10.4s   // Lhatz
    // ---- Spot cone: cutoff from the normalized light direction ----
    // (same shape as batch A; v10 = cutoff, v6 = scratch — the 2.0
    // Sobel const is dead here.)
    ldr     s6, [x5, #52]
    dup     v10.4s, v6.s[0]       // dirX
    fmul    v10.4s, v2.4s, v10.4s  // Lhatx*dirX
    ldr     s6, [x5, #56]
    dup     v6.4s, v6.s[0]        // dirY
    fmla    v10.4s, v3.4s, v6.4s  // += Lhaty*dirY
    ldr     s6, [x5, #60]
    dup     v6.4s, v6.s[0]        // dirZ
    fmla    v10.4s, v0.4s, v6.4s  // += Lhatz*dirZ = sdot
    ldr     s6, [x5, #64]
    dup     v6.4s, v6.s[0]        // spotCos
    fneg    v10.4s, v10.4s        // -sdot
    fmax    v10.4s, v10.4s, v28.4s  // negDot = max(-sdot,0)
    fmin    v10.4s, v10.4s, v26.4s  // clamp <= 1
    fcmge   v6.4s, v10.4s, v6.4s  // mask = (negDot >= spotCos)
    and     v10.16b, v10.16b, v6.16b  // cutoff
    // dot = (Lhatz - (dx*Lhatx + dy*Lhaty)) * rec, then *k*cutoff/clamp.
    fmul    v7.4s, v4.4s, v2.4s
    fmla    v7.4s, v5.4s, v3.4s
    fsub    v7.4s, v0.4s, v7.4s
    fmul    v2.4s, v7.4s, v1.4s
    fmul    v2.4s, v2.4s, v18.4s
    fmul    v2.4s, v2.4s, v10.4s  // *cutoff
    fmax    v2.4s, v2.4s, v28.4s
    fmin    v2.4s, v2.4s, v26.4s
    fmul    v0.4s, v2.4s, v22.4s
    fmul    v1.4s, v2.4s, v23.4s
    fmul    v3.4s, v2.4s, v24.4s
    fadd    v0.4s, v0.4s, v27.4s
    fadd    v1.4s, v1.4s, v27.4s
    fadd    v3.4s, v3.4s, v27.4s
    fcvtzu  v0.4s, v0.4s
    fcvtzu  v1.4s, v1.4s
    fcvtzu  v3.4s, v3.4s
    shl     v0.4s, v0.4s, #16
    shl     v1.4s, v1.4s, #8
    orr     v3.16b, v3.16b, v1.16b
    orr     v3.16b, v3.16b, v0.16b
    orr     v3.16b, v3.16b, v29.16b  // alpha = 0xFF

    // Linear-light ARGB in v3: convert through the 256-byte LUT at x6.
    mov     x11, x6
    ld1     {v16.16b-v19.16b}, [x11], #64
    ld1     {v20.16b-v23.16b}, [x11], #64
    ld1     {v24.16b-v27.16b}, [x11], #64
    ld1     {v28.16b-v31.16b}, [x11], #64
    movi    v12.16b, #63
    LUT256_16 v3, v3
    str     q3, [x3]

.Llin_done:
    ldp     d14, d15, [sp, #48]
    ldp     d12, d13, [sp, #32]
    ldp     d10, d11, [sp, #16]
    ldp     d8, d9, [sp, #0]
    add     sp, sp, #64
    ret

.size ksvgLightingSpotDiffuseRowNeon64Linear, .-ksvgLightingSpotDiffuseRowNeon64Linear
#ifndef __APPLE__
.section .note.GNU-stack,"",%progbits
#endif
