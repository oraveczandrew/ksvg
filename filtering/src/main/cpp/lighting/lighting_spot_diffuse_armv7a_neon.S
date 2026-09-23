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

.syntax unified
.arm
.fpu neon
.text
.align 2

// Lane indices [0,1,2,3] for the per-pixel ux walk (integer, converted
// with vcvt then scaled by dux). ADR-relative, stays in .text.
.Llane_idx:
.word 0, 1, 2, 3

.global ksvgLightingSpotDiffuseRowNeon32
.type ksvgLightingSpotDiffuseRowNeon32, %function

// void ksvgLightingSpotDiffuseRowNeon32(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const SpotLightingParams* params)
//
// AAPCS32:
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params
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
// Processes 4 ARGB8888 pixels per iteration. For output pixel (x) the taps
// are read from columns (x-1 .. x+1) of rows y-1/y/y+1 via three overlapping
// q-register loads at [src+0], [src+4], [src+8] (l/m/r of each row). The
// middle row additionally loads m (centers) into q15 for surfZ.
//
// math (matches applyScalarPixel_full lightType==2 op order):
//   h = (alpha >> 24) * ss
//   dxRel = (rT-lT) + 2*(rM-lM) + (rB-lB)
//   dyRel = (lB+2*mB+rB) - (lT+2*mT+rT)
//   nx = -dxRel*scaleX, ny = -dyRel*scaleY, nz = 1 (then normalize)
//   nLen = sqrt(nx*nx + ny*ny + 1) per lane (scalar VFP, exact); the
//   four lanes use vsqrt+vdiv exactly like the Kotlin reference.
//   ux = ux0 + (idx+[0,1,2,3])*dux   (idx = r11 pixel index)
//   surfZ = centerAlpha*ss            (middle-row center tap per output)
//   L = (lx-ux, ly-uy, lz-surfZ) per lane (scalar VFP);
//   len = sqrt(Lx^2+Ly^2+Lz^2); Lhat = (len==0) ? 0 : L/len
//   (len==0 matches the scalar factor=0 path: L=0 -> dot=0 -> intensity 0)
//   dot = nx*Lhatx + ny*Lhaty + nz*Lhatz  (Kotlin op order)
//   sdot = Lhatx*spotDirX + Lhaty*spotDirY + Lhatz*spotDirZ
//   negDot = clamp(-sdot, 0, 1)   (upper clamp mirrors the scalar
//     [-1,1] clamp); cutoff = negDot & (spotCos <= negDot ? all : 0)
//   intensity = clamp(dot*k*cutoff, 0, 1)
//   out = (round(lr*intensity)<<16) | (round(lg*intensity)<<8)
//         | round(lb*intensity) | 0xFF000000
//
// Register map (loop-invariant):
//   q4 = ss        q5 = scaleX = 1/invDx   q6 = scaleY = 1/invDy
//   q7 = 1.0f (ONE; set once, never written: the vdiv "one" source.
//     NOTE: the distant reference instead divides by s28 with q7 = k,
//     which is only correct for k == 1 (all current corpus cases); this
//     kernel deliberately uses a true 1.0 so k != 1 also matches.)
//   q8 = k         q9 = lx      q10 = ly
//   q11 = lz       q12 = lr     q13 = lg
//   q14 = lb (clobbered to nz by the N normalize; reloaded from
//     [r5, #32] after the dot, before the pack)
//   r4 = count (remaining)   r5 = params base (kept live: k/lx reload,
//     lb reload, ux0/uy/dux per-iteration loads)
//   r6 = Ly bits (ly-uy, recomputed per iteration)
//   r10 = lz bits (loaded per iteration; r10 is free after the tap loads)
//   r11 = pixel index (integer, += 4 per iteration)
//   q0-q3, q15 = scratch. Mid-loop repurposing (all documented inline):
//     q8/q9 lend as bottom-sum accumulator / dyRel park across the dx
//       recompute; q4 takes surfZ after ss dies (post-scale) and q6
//       takes Lhaty after scaleY dies; ss/scales/k/lx are reloaded every
//       iteration (prologue values serve iteration 0 only).

ksvgLightingSpotDiffuseRowNeon32:
    push    {r4-r11, r12, lr}      // 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               // preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         // count
    ldr     r5, [sp, #108]         // params
    cmp     r4, #0
    beq     .Ldone

    // Load Params:
    //   q0 = [invDx, invDy, k, lx]; q1 = [ly, lz, lr, lg]; d4 = [lb, ss]
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]
    sub     r5, r5, #32            // r5 = params base again (kept live)

    // scaleX = 1/invDx, scaleY = 1/invDy (single-precision VFP, VFPv3 ok)
    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     // ss
    vdup.32 q5, d0[0]     // scaleX
    vdup.32 q6, d0[1]     // scaleY
    vmov.f32 q7, #1.0     // ONE (vdiv source; never written below)
    vdup.32 q8, d1[0]     // k
    vdup.32 q9, d1[1]     // lx
    vdup.32 q10, d2[0]    // ly
    vdup.32 q11, d2[1]    // lz
    vdup.32 q12, d3[0]    // lr
    vdup.32 q13, d3[1]    // lg
    vdup.32 q14, d4[0]    // lb

    mov     r11, #0                 // pixel index

.Lloop:
    // Reload ss and the gradient scales: the previous iteration's
    // L-window repurposed q4 (surfZ/Lhatz) and q6 (Lhaty), and the taps
    // below consume q4 BEFORE any later reload could run. The prologue
    // values serve iteration 0 only. (k/lx are reloaded post-scale,
    // after the bottom-sum acc/park below clobbers them.)
    // (d6/q3 is scratch here: vld1 targets must not overlap the vdup
    // destinations — VDUP with overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #36
    vld1.32 {d6}, [r12]          // d6 = [ss, ux0]
    vdup.32 q4, d6[0]            // q4 = ss
    vld1.32 {d6}, [r5]           // d6 = [invDx, invDy]
    vdiv.f32 s12, s28, s12       // 1/invDx (s28 = ONE)
    vdiv.f32 s13, s28, s13       // 1/invDy
    vdup.32 q5, d6[0]            // q5 = scaleX
    vdup.32 q6, d6[1]            // q6 = scaleY

    // ---- Row T ----
    vld1.32 {q0}, [r0]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r10, r0, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tm

    add     r10, r0, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          // top sum

    // ---- Row M (l, m, r; m = centers for surfZ) ----
    vld1.32 {q0}, [r1]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // ml

    add     r10, r1, #4
    vld1.32 {q15}, [r10]
    vshr.u32 q15, q15, #24
    vcvt.f32.u32 q15, q15
    vmul.f32 q15, q15, q4        // centers*ss = surfZ (kept in q15)

    add     r10, r1, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // mr

    // ---- Row B ----
    vld1.32 {q0}, [r2]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // bl (q0 reused; ml dead)

    add     r10, r2, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // bm

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br (q2 reused; mr dead)

    // Exact scalar bottom sum: bl + bm + bm + br. The accumulator/park
    // use q9/q8 (lx/k): unlike the distant kernel (whose q14 was a
    // disposable "one"), our q14 holds lb, so k/lx are reloaded below.
    vadd.f32 q9, q0, q1
    vadd.f32 q9, q9, q1
    vadd.f32 q9, q9, q2          // bottom sum
    vsub.f32 q3, q9, q3          // dyRel
    vmov    q8, q3                // park dyRel across the dx recompute

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r0]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r10, r0, #8
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tr

    vld1.32 {q2}, [r1]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // ml

    add     r10, r1, #8
    vld1.32 {q3}, [r10]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          // mr

    vadd.f32 q0, q0, q2         // tl + ml
    vadd.f32 q0, q0, q2         // (tl + ml) + ml
    vadd.f32 q1, q1, q3         // tr + mr
    vadd.f32 q1, q1, q3         // (tr + mr) + mr

    add     r10, r2, #0
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // bl
    vadd.f32 q0, q0, q2         // + bl

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br
    vadd.f32 q1, q1, q2         // + br
    vsub.f32 q0, q1, q0         // dxRel
    vmov    q3, q8                // restore dyRel (q8 = k dead until reload)

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          // q0 = dx
    vmul.f32 q1, q3, q6          // q1 = dy
    // k/lx were lent as scratch above (bottom-sum acc in q9, dyRel park
    // in q8); reload them from the live params base.
    // (d6/q3 is scratch here: vld1 must NOT target overlapping halves —
    // VDUP with overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #8
    vld1.32 {d6}, [r12]          // d6 = [k, lx]
    vdup.32 q8, d6[0]            // q8 = k
    vdup.32 q9, d6[1]            // q9 = lx
    // ss is dead from here on (taps are done); surfZ moves to a
    // scalar-addressable home.
    vmov    q4, q15               // q4 = surfZ (s16-s19; q15 goes scratch)

    // ---- Normalize N exactly like Kotlin reference ----
    // nLen = sqrt(nx*nx + ny*ny + 1); nx/=nLen; ny/=nLen; nz=1/nLen
    vneg.f32 q0, q0              // nx0
    vneg.f32 q1, q1              // ny0
    vmul.f32 q2, q0, q0
    vmul.f32 q3, q1, q1
    vadd.f32 q2, q2, q3
    vadd.f32 q2, q2, q7          // nLen^2 (+ true 1.0)

    // ARMv7 VFP sqrt/div are scalar; normalize four lanes exactly.
    // (s28-s31 are q7 = ONE here, not k: see the header note.)
    vsqrt.f32 s12, s8
    vsqrt.f32 s13, s9
    vsqrt.f32 s14, s10
    vsqrt.f32 s15, s11
    vdiv.f32 s12, s28, s12
    vdiv.f32 s13, s29, s13
    vdiv.f32 s14, s30, s14
    vdiv.f32 s15, s31, s15

    // q3 now contains invLen = 1/nLen.
    vmul.f32 q0, q0, q3          // normalized nx
    vmul.f32 q1, q1, q3          // normalized ny
    vmov q14, q3                 // normalized nz = invLen (lb reloaded later)
    // (q2 = nLen^2 and q3 = invLen are dead from here on.)

    // ---- Per-pixel light vector L (scalar VFP, exact) ----
    // ux = ux0 + (idx+[0,1,2,3])*dux; Lx = lx - ux (into q2).
    // q2/q3 are scratch here (nLen^2/invLen dead).
    vdup.32 q2, r11              // idx broadcast (integer)
    adr     r12, .Llane_idx
    vld1.32 {d6, d7}, [r12]      // q3 = [0,1,2,3]
    vadd.i32 q2, q2, q3
    vcvt.f32.u32 q2, q2
    ldr     r12, [r5, #48]       // dux bits
    vdup.32 q3, r12
    vmul.f32 q2, q2, q3          // (idx+lane)*dux
    ldr     r12, [r5, #40]       // ux0 bits
    vdup.32 q3, r12
    vadd.f32 q2, q2, q3          // ux
    vsub.f32 q2, q9, q2          // Lx = lx - ux (q9 = lx)
    // Ly = ly - uy (row-constant scalar -> r6). s12/s13 are q3 lanes
    // (q3 is scratch here).
    ldr     r12, [r5, #16]       // ly bits
    vmov    s12, r12
    ldr     r12, [r5, #44]       // uy bits
    vmov    s13, r12
    vsub.f32 s12, s12, s13       // Ly
    vmov    r6, s12              // Ly bits -> r6
    ldr     r10, [r5, #20]       // lz bits -> r10 (r10 free: taps done)
    // Per-lane L normalize: Lhat = (len==0) ? 0 : L/len.
    // Sources: Lx s8-s11 (q2), Ly r6, lz r10, surfZ s16-s19 (q4).
    // Dests: Lhatx q2 lanes, Lhaty q6 lanes (scaleY dead), Lhatz q4
    // lanes (same-lane read-then-write with surfZ). Temps: q3 full
    // (s12-s15; Lhaty lives in q6, so q3 never holds a home).
    // lane 0
    vmov.f32 s12, s8
    vmov    s13, r6
    vmov    s14, r10
    vmov.f32 s15, s16
    vsub.f32 s14, s14, s15       // Lz = lz - surfZ
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14       // len2
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp0_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15       // / true 1.0 (q7)
    b       .Lp0_done
.Lp0_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7           // temps = 0 -> products below are 0
.Lp0_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s8, s12
    vmov.f32 s24, s13
    vmov.f32 s16, s14
    // lane 1
    vmov.f32 s12, s9
    vmov    s13, r6
    vmov    s14, r10
    vmov.f32 s15, s17
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp1_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lp1_done
.Lp1_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lp1_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s9, s12
    vmov.f32 s25, s13
    vmov.f32 s17, s14
    // lane 2
    vmov.f32 s12, s10
    vmov    s13, r6
    vmov    s14, r10
    vmov.f32 s15, s18
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp2_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lp2_done
.Lp2_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lp2_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s10, s12
    vmov.f32 s26, s13
    vmov.f32 s18, s14
    // lane 3
    vmov.f32 s12, s11
    vmov    s13, r6
    vmov    s14, r10
    vmov.f32 s15, s19
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp3_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lp3_done
.Lp3_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lp3_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s11, s12
    vmov.f32 s27, s13
    vmov.f32 s19, s14
    // q2 = Lhatx, q6 = Lhaty, q4 = Lhatz; nx = q0, ny = q1, nz = q14.

    // ---- Spot cone: cutoff from the normalized light direction ----
    // sdot = Lhat.dir; negDot = clamp(-sdot,0,1) (upper clamp mirrors
    // the scalar [-1,1] clamp of the cone dot); cutoff = negDot masked
    // by (spotCos <= negDot). spotCos = -1 (NaN cutoff) = always inside.
    // q3 is scratch (per-lane temps dead); the cutoff parks in q15
    // (free: surfZ moved to q4 post-scale). r12 is free here as well.
    ldr     r12, [r5, #52]
    vdup.32 q3, r12              // dirX
    vmul.f32 q3, q2, q3          // Lhatx*dirX
    ldr     r12, [r5, #56]
    vdup.32 q15, r12             // dirY
    vmla.f32 q3, q6, q15         // += Lhaty*dirY
    ldr     r12, [r5, #60]
    vdup.32 q15, r12             // dirZ
    vmla.f32 q3, q4, q15         // += Lhatz*dirZ = sdot
    vneg.f32 q3, q3              // -sdot
    vcge.f32 q15, q3, #0         // (-sdot >= 0) mask
    vand    q3, q3, q15          // max(-sdot,0) = negDot
    vmin.f32 q3, q3, q7          // clamp <= 1 (q7 = ONE)
    ldr     r12, [r5, #64]
    vdup.32 q15, r12             // spotCos
    vcge.f32 q15, q3, q15        // (negDot >= spotCos) mask
    vand    q15, q3, q15         // cutoff -> q15

    // Kotlin dot: nx*Lhatx + ny*Lhaty + nz*Lhatz.
    vmul.f32 q2, q0, q2
    vmul.f32 q6, q1, q6
    vmul.f32 q4, q14, q4
    vadd.f32 q2, q2, q6
    vadd.f32 q2, q2, q4
    // lb was clobbered by nz; reload it before the pack.
    // (d6/q3 is scratch here: vld1 must NOT target d28 (q14 low half) —
    // VDUP with overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #32
    vld1.32 {d6}, [r12]          // d6 = [lb, ss]
    vdup.32 q14, d6[0]           // q14 = lb

    // ---- intensity = min(max(dot*k*cutoff, 0), 1) ----
    // (q15 = cutoff; dot in q2. Order matches the x86 spot kernel:
    // factor = k*ndotl*cutoff, then clamp01.)
    vmul.f32 q2, q2, q8          // * k
    vmul.f32 q2, q2, q15         // * cutoff
    veor    q15, q15, q15         // zero (cutoff dead after this)
    vmax.f32 q2, q2, q15
    vmin.f32 q2, q2, q7          // q2 = intensity (clamp <= true 1.0)

    // ---- Pack ARGB ----
    vmul.f32 q0, q2, q12          // outR
    vmul.f32 q1, q2, q13          // outG
    vmul.f32 q3, q2, q14          // outB
    // Kotlin roundToInt() for nonnegative values: floor(x + 0.5).
    vmov.f32 q14, #0.5
    vadd.f32 q0, q0, q14
    vadd.f32 q1, q1, q14
    vadd.f32 q3, q3, q14
    vcvt.s32.f32 q0, q0
    vcvt.s32.f32 q1, q1
    vcvt.s32.f32 q3, q3

    vshl.u32 q0, q0, #16
    vshl.u32 q1, q1, #8
    vorr    q3, q3, q0
    vorr    q3, q3, q1

    mov     r6, #0xFF000000
    vdup.32 q0, r6                // alpha = 0xFF
    vorr    q3, q3, q0

    vst1.32 {q3}, [r3]!

    add     r0, r0, #16
    add     r1, r1, #16
    add     r2, r2, #16
    add     r11, r11, #4          // pixel index += 4
    subs    r4, r4, #4
    bne     .Lloop

.Ldone:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingSpotDiffuseRowNeon32, .-ksvgLightingSpotDiffuseRowNeon32

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): identical Sobel/normalize/L/dot
// math to Neon32, then a scalar per-pixel linear->sRGB LUT conversion
// (3 ldrb lookups into ksvg_linear_to_srgb_lut, matching the distant
// armv7a *Linear row). Bit-exact by construction: the table IS the Kotlin
// reference (ColorLuts.LINEAR_TO_SRGB).
//
// void ksvgLightingSpotDiffuseRowNeon32Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const SpotLightingParams* params,
//   const uint8_t* linearToSrgb)
//
// AAPCS32:
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params, [sp, #8] = linearToSrgb
//   (i.e. [sp+#104]/[sp+#108]/[sp+#112] after the two pushes below)
//
// Register map (loop-invariant): same q4-q14 params/helpers as Neon32,
// except Ly bits live in r7 here (r6 = linearToSrgb LUT base).
//   r5 = params base (kept live); r6 = linearToSrgb (LUT base);
//   r11 = pixel index; r10 = lz bits (per iteration).
//   r8-r10 = scalar L2S scratch (r10 reused after lz dies). r3/dst is
//   advanced by the scalar closure.
//
// Math is byte-identical to Neon32 up to and including the pack: the only
// difference is the linear bytes are converted through the LUT (alpha stays
// 0xFF - no L2S on alpha), then stored scalar per pixel.

.macro L2S_PIXEL inr
    mov     r9, \inr, lsr #16        // R index (bits 23-16)
    and     r9, r9, #0xFF
    ldrb    r9, [r6, r9]
    mov     r10, \inr, lsr #8        // G index (bits 15-8)
    and     r10, r10, #0xFF
    ldrb    r10, [r6, r10]
    and     \inr, \inr, #0xFF        // B index (bits 7-0)
    ldrb    \inr, [r6, \inr]
    lsl     r9, r9, #16
    orr     r9, r9, r10, lsl #8
    orr     r9, r9, \inr
    orr     r9, r9, #0xFF000000
    str     r9, [r3], #4
.endm

// Second lane-index literal (one per entry point: ADR range).
.Llane_idx2:
.word 0, 1, 2, 3

.global ksvgLightingSpotDiffuseRowNeon32Linear
.type ksvgLightingSpotDiffuseRowNeon32Linear, %function

ksvgLightingSpotDiffuseRowNeon32Linear:
    push    {r4-r11, r12, lr}      // 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               // preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         // count
    ldr     r5, [sp, #108]         // params
    ldr     r6, [sp, #112]         // linearToSrgb LUT
    cmp     r4, #0
    beq     .Llin_done

    // Load Params: identical to Neon32.
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]
    sub     r5, r5, #32            // r5 = params base again (kept live)

    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     // ss
    vdup.32 q5, d0[0]     // scaleX
    vdup.32 q6, d0[1]     // scaleY
    vmov.f32 q7, #1.0     // ONE (vdiv source; never written below)
    vdup.32 q8, d1[0]     // k
    vdup.32 q9, d1[1]     // lx
    vdup.32 q10, d2[0]    // ly
    vdup.32 q11, d2[1]    // lz
    vdup.32 q12, d3[0]    // lr
    vdup.32 q13, d3[1]    // lg
    vdup.32 q14, d4[0]    // lb

    mov     r11, #0                 // pixel index

.Llin_loop:
    // Reload ss and the gradient scales: the previous iteration's
    // L-window repurposed q4 (surfZ/Lhatz) and q6 (Lhaty), and the taps
    // below consume q4 BEFORE any later reload could run. The prologue
    // values serve iteration 0 only. (k/lx are reloaded post-scale,
    // after the bottom-sum acc/park below clobbers them.)
    // (d6/q3 is scratch here: vld1 targets must not overlap the vdup
    // destinations — VDUP with overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #36
    vld1.32 {d6}, [r12]          // d6 = [ss, ux0]
    vdup.32 q4, d6[0]            // q4 = ss
    vld1.32 {d6}, [r5]           // d6 = [invDx, invDy]
    vdiv.f32 s12, s28, s12       // 1/invDx (s28 = ONE)
    vdiv.f32 s13, s28, s13       // 1/invDy
    vdup.32 q5, d6[0]            // q5 = scaleX
    vdup.32 q6, d6[1]            // q6 = scaleY

    // ---- Row T ----
    vld1.32 {q0}, [r0]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r10, r0, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tm

    add     r10, r0, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          // top sum

    // ---- Row M (l, m, r; m = centers for surfZ) ----
    vld1.32 {q0}, [r1]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // ml

    add     r10, r1, #4
    vld1.32 {q15}, [r10]
    vshr.u32 q15, q15, #24
    vcvt.f32.u32 q15, q15
    vmul.f32 q15, q15, q4        // centers*ss = surfZ (kept in q15)

    add     r10, r1, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // mr

    // ---- Row B ----
    vld1.32 {q0}, [r2]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // bl (q0 reused; ml dead)

    add     r10, r2, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // bm

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br (q2 reused; mr dead)

    // Exact scalar bottom sum (accumulator/park in q9/q8; k/lx reloaded).
    vadd.f32 q9, q0, q1
    vadd.f32 q9, q9, q1
    vadd.f32 q9, q9, q2          // bottom sum
    vsub.f32 q3, q9, q3          // dyRel
    vmov    q8, q3                // park dyRel across the dx recompute

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r0]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r10, r0, #8
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tr

    vld1.32 {q2}, [r1]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // ml

    add     r10, r1, #8
    vld1.32 {q3}, [r10]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          // mr

    vadd.f32 q0, q0, q2         // tl + ml
    vadd.f32 q0, q0, q2         // (tl + ml) + ml
    vadd.f32 q1, q1, q3         // tr + mr
    vadd.f32 q1, q1, q3         // (tr + mr) + mr

    add     r10, r2, #0
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // bl
    vadd.f32 q0, q0, q2         // + bl

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br
    vadd.f32 q1, q1, q2         // + br
    vsub.f32 q0, q1, q0         // dxRel
    vmov    q3, q8                // restore dyRel

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          // q0 = dx
    vmul.f32 q1, q3, q6          // q1 = dy
    // k/lx were lent as scratch above (bottom-sum acc in q9, dyRel park
    // in q8); reload them from the live params base.
    // (d6/q3 is scratch here: vld1 must NOT target overlapping halves —
    // VDUP with overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #8
    vld1.32 {d6}, [r12]          // d6 = [k, lx]
    vdup.32 q8, d6[0]            // q8 = k
    vdup.32 q9, d6[1]            // q9 = lx
    // ss is dead from here on (taps are done); surfZ moves to a
    // scalar-addressable home.
    vmov    q4, q15               // q4 = surfZ (s16-s19; q15 goes scratch)

    // ---- Normalize N exactly like Kotlin reference ----
    vneg.f32 q0, q0              // nx0
    vneg.f32 q1, q1              // ny0
    vmul.f32 q2, q0, q0
    vmul.f32 q3, q1, q1
    vadd.f32 q2, q2, q3
    vadd.f32 q2, q2, q7          // nLen^2 (+ true 1.0)

    // ARMv7 VFP sqrt/div are scalar; normalize four lanes exactly.
    vsqrt.f32 s12, s8
    vsqrt.f32 s13, s9
    vsqrt.f32 s14, s10
    vsqrt.f32 s15, s11
    vdiv.f32 s12, s28, s12
    vdiv.f32 s13, s29, s13
    vdiv.f32 s14, s30, s14
    vdiv.f32 s15, s31, s15

    // q3 now contains invLen = 1/nLen.
    vmul.f32 q0, q0, q3          // normalized nx
    vmul.f32 q1, q1, q3          // normalized ny
    vmov q14, q3                 // normalized nz = invLen (lb reloaded later)

    // ---- Per-pixel light vector L (scalar VFP, exact) ----
    // ux = ux0 + (idx+[0,1,2,3])*dux; Lx = lx - ux (into q2).
    vdup.32 q2, r11              // idx broadcast (integer)
    adr     r12, .Llane_idx2
    vld1.32 {d6, d7}, [r12]      // q3 = [0,1,2,3]
    vadd.i32 q2, q2, q3
    vcvt.f32.u32 q2, q2
    ldr     r12, [r5, #48]       // dux bits
    vdup.32 q3, r12
    vmul.f32 q2, q2, q3          // (idx+lane)*dux
    ldr     r12, [r5, #40]       // ux0 bits
    vdup.32 q3, r12
    vadd.f32 q2, q2, q3          // ux
    vsub.f32 q2, q9, q2          // Lx = lx - ux (q9 = lx)
    // Ly = ly - uy (row-constant scalar -> r7; r6 is the LUT base).
    ldr     r12, [r5, #16]       // ly bits
    vmov    s12, r12
    ldr     r12, [r5, #44]       // uy bits
    vmov    s13, r12
    vsub.f32 s12, s12, s13       // Ly
    vmov    r7, s12              // Ly bits -> r7
    ldr     r10, [r5, #20]       // lz bits -> r10 (r10 free: taps done)
    // Per-lane L normalize (Lhatx -> q2, Lhaty -> q6, Lhatz -> q4).
    // lane 0
    vmov.f32 s12, s8
    vmov    s13, r7
    vmov    s14, r10
    vmov.f32 s15, s16
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq0_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lq0_done
.Lq0_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lq0_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s8, s12
    vmov.f32 s24, s13
    vmov.f32 s16, s14
    // lane 1
    vmov.f32 s12, s9
    vmov    s13, r7
    vmov    s14, r10
    vmov.f32 s15, s17
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq1_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lq1_done
.Lq1_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lq1_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s9, s12
    vmov.f32 s25, s13
    vmov.f32 s17, s14
    // lane 2
    vmov.f32 s12, s10
    vmov    s13, r7
    vmov    s14, r10
    vmov.f32 s15, s18
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq2_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lq2_done
.Lq2_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lq2_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s10, s12
    vmov.f32 s26, s13
    vmov.f32 s18, s14
    // lane 3
    vmov.f32 s12, s11
    vmov    s13, r7
    vmov    s14, r10
    vmov.f32 s15, s19
    vsub.f32 s14, s14, s15
    vmul.f32 s15, s12, s12
    vmla.f32 s15, s13, s13
    vmla.f32 s15, s14, s14
    vcmp.f32 s15, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq3_zero
    vsqrt.f32 s15, s15
    vdiv.f32 s15, s28, s15
    b       .Lq3_done
.Lq3_zero:
    veor    d6, d6, d6
    veor    d7, d7, d7
.Lq3_done:
    vmul.f32 s12, s12, s15
    vmul.f32 s13, s13, s15
    vmul.f32 s14, s14, s15
    vmov.f32 s11, s12
    vmov.f32 s27, s13
    vmov.f32 s19, s14
    // q2 = Lhatx, q6 = Lhaty, q4 = Lhatz; nx = q0, ny = q1, nz = q14.

    // ---- Spot cone: cutoff from the normalized light direction ----
    // sdot = Lhat.dir; negDot = clamp(-sdot,0,1) (upper clamp mirrors
    // the scalar [-1,1] clamp of the cone dot); cutoff = negDot masked
    // by (spotCos <= negDot). spotCos = -1 (NaN cutoff) = always inside.
    // q3 is scratch (per-lane temps dead); the cutoff parks in q15
    // (free: surfZ moved to q4 post-scale). r12 is free here as well.
    ldr     r12, [r5, #52]
    vdup.32 q3, r12              // dirX
    vmul.f32 q3, q2, q3          // Lhatx*dirX
    ldr     r12, [r5, #56]
    vdup.32 q15, r12             // dirY
    vmla.f32 q3, q6, q15         // += Lhaty*dirY
    ldr     r12, [r5, #60]
    vdup.32 q15, r12             // dirZ
    vmla.f32 q3, q4, q15         // += Lhatz*dirZ = sdot
    vneg.f32 q3, q3              // -sdot
    vcge.f32 q15, q3, #0         // (-sdot >= 0) mask
    vand    q3, q3, q15          // max(-sdot,0) = negDot
    vmin.f32 q3, q3, q7          // clamp <= 1 (q7 = ONE)
    ldr     r12, [r5, #64]
    vdup.32 q15, r12             // spotCos
    vcge.f32 q15, q3, q15        // (negDot >= spotCos) mask
    vand    q15, q3, q15         // cutoff -> q15

    // Kotlin dot: nx*Lhatx + ny*Lhaty + nz*Lhatz.
    vmul.f32 q2, q0, q2
    vmul.f32 q6, q1, q6
    vmul.f32 q4, q14, q4
    vadd.f32 q2, q2, q6
    vadd.f32 q2, q2, q4
    // lb was clobbered by nz; reload it before the pack.
    // (d6/q3 is scratch here: vld1 must NOT target d28 (q14 low half) —
    // VDUP with overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #32
    vld1.32 {d6}, [r12]          // d6 = [lb, ss]
    vdup.32 q14, d6[0]           // q14 = lb

    // ---- intensity = min(max(dot*k*cutoff, 0), 1) ----
    // (q15 = cutoff; dot in q2. Order matches the x86 spot kernel:
    // factor = k*ndotl*cutoff, then clamp01.)
    vmul.f32 q2, q2, q8          // * k
    vmul.f32 q2, q2, q15         // * cutoff
    veor    q15, q15, q15         // zero (cutoff dead after this)
    vmax.f32 q2, q2, q15
    vmin.f32 q2, q2, q7          // q2 = intensity (clamp <= true 1.0)

    // ---- Pack ARGB (linear-light bytes, alpha = 0xFF) ----
    vmul.f32 q0, q2, q12          // outR
    vmul.f32 q1, q2, q13          // outG
    vmul.f32 q3, q2, q14          // outB
    // Kotlin roundToInt() for nonnegative values: floor(x + 0.5).
    vmov.f32 q14, #0.5
    vadd.f32 q0, q0, q14
    vadd.f32 q1, q1, q14
    vadd.f32 q3, q3, q14
    vcvt.s32.f32 q0, q0
    vcvt.s32.f32 q1, q1
    vcvt.s32.f32 q3, q3

    vshl.u32 q0, q0, #16
    vshl.u32 q1, q1, #8
    vorr    q3, q3, q0
    vorr    q3, q3, q1

    mov     r7, #0xFF000000
    vdup.32 q0, r7                // alpha = 0xFF
    vorr    q3, q3, q0

    // ---- Linear -> sRGB (scalar LUT lookups, one 4-px vector) ----
    vmov    r8, s12
    L2S_PIXEL r8
    vmov    r8, s13
    L2S_PIXEL r8
    vmov    r8, s14
    L2S_PIXEL r8
    vmov    r8, s15
    L2S_PIXEL r8

    add     r0, r0, #16
    add     r1, r1, #16
    add     r2, r2, #16
    add     r11, r11, #4          // pixel index += 4
    subs    r4, r4, #4
    bne     .Llin_loop

.Llin_done:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingSpotDiffuseRowNeon32Linear, .-ksvgLightingSpotDiffuseRowNeon32Linear
