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
#include "lighting_armv7a_pow_macros.S"

// Lane indices [0,1,2,3] for the per-pixel ux walk (integer, converted
// with vcvt then scaled by dux). ADR-relative, stays in .text.
.Llane_idx:
.word 0, 1, 2, 3

.global ksvgLightingPointSpecularRowNeon32
.type ksvgLightingPointSpecularRowNeon32, %function

// void ksvgLightingPointSpecularRowNeon32(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const PointLightingParams* params, float exponent)
//
// AAPCS32 (softfp armeabi-v7a):
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params, [sp, #8] = exponent (7th arg).
//
// PointLightingParams layout (cpu_dispatch.h, hard contract):
//   +0 invDx  +4 invDy  +8 k  +12 lx  +16 ly  +20 lz
//   +24 lr    +28 lg    +32 lb +36 ss +40 ux0 +44 uy +48 dux
//   (lx/ly/lz = light position; ux0 = user-space x of output pixel 0,
//   uy = row y in user space, dux = user-space x step per pixel.)
//
// Straight (non-premultiplied) point-specular row: the Sobel/normalize
// block mirrors ksvgLightingPointDiffuseRowNeon32 (exact scalar add order),
// but the light direction L is per-pixel and the half vector
// h = normalize(L+(0,0,1)) is per-pixel too (scalar VFP, exact). The
// clamped ndoth feeds a per-lane scalar DOUBLE libm pow (the reference
// uses Kotlin Math.pow / C++ std::pow double math):
//
//   ux = ux0 + (idx+[0,1,2,3])*dux   (idx = stack slot [sp,#40])
//   surfZ = centerAlpha*ss            (middle-row center tap per output)
//   L = (lx-ux, ly-uy, lz-surfZ) per lane (scalar VFP);
//   len = sqrt(Lx^2+Ly^2+Lz^2); Lhat = (len==0) ? 0 : L/len
//   h = (hLen==0) ? 0 : (Lhat+(0,0,1))/hLen   (scalar len==0 path keeps
//     h = L+(0,0,1) = 0, hence ndoth = 0 — identical outcome)
//   ndoth = clamp0(nx*Lhatx... precisely nx*hx+ny*hy+nz*hz, Kotlin order)
//   p     = pow(ndoth, exponent)          (scalar double per lane)
//   I     = clamp01(k * p)
//   R/G/B = round(lr/lg/lb * I)           (floor(x+0.5) for non-negative)
//   A     = max(R, G, B)
//
// 4 output pixels per iteration. `bl pow` clobbers ALL caller-saved state:
// r0-r3, r12, lr, and the VFP caller-saved d0-d7 (q0-q3) / d16-d31 (q8-q15).
// Pointers live in callee-saved r8-r11; ss/scales/ONE survive in d8-d15
// (q4-q7); everything else is reloaded after pow (k/lr/lg/lb/one) or per
// iteration (ss/scales/lx, whose homes are repurposed mid-loop).
//
// Register map:
//   r4 = count (remaining)   r5 = params base (kept live)
//   r7 = scratch             r8 = srcT   r9 = srcM   r10 = srcB
//   r11 = dst                r12 = address temp (taps, pre-pow only)
//   q4 = ss        q5 = scaleX = 1/invDx   q6 = scaleY = 1/invDy
//   q7 = 1.0f (ONE; set once in prologue, never written: VFP d14
//     survives `bl pow`, and the loop never touches q7)
//   q8 = lx (top-of-loop reload; dead after the L-window)
//   q9/q10 = bottom-sum accumulator / dyRel park (pure scratch, never
//     reloaded — unlike the diffuse kernel, which lends live regs)
//   q12 = lr     q13 = lg     q14 = lb (post-pow rebuild; prologue skips)
//   q2 = dx/nLen2/ux/Lx/Lhatx/ndoth/stash/powOut/intensity (lifecycle)
//   q3 = dy/invLen/nz (nz SURVIVES the L-window: it uses q2/q5/q6/q4/q9
//     only, never q3) / outB
//   q0/q1 = dx/dy -> nx/ny -> outR/outG
//   q15 = centers*ss = surfZ, then scratch
//   q5 doubles as per-lane temps (s20-s23; scaleX dead post-scale,
//     reloaded); q6 takes Lhaty, q4 takes Lhatz (same as diffuse)
//   q0-q3, q15 = scratch / rebuilt after pow
//
// Stack frame (48 bytes, after push {r4-r11,r12,lr} + vpush {d8-d15}):
//   [sp, #0..#15]   ndoth stash -> in-place pow results
//   [sp, #16..23]   exponent (double)
//   [sp, #24] Ly (ly-uy, loop-invariant scalar)
//   [sp, #40] pixel index (integer, += 4 per iteration)
// Count reads at [sp, #104], params at [sp, #108], exponent at [sp, #112]
// (entry offsets, read BEFORE the #48 sub below).
//
ksvgLightingPointSpecularRowNeon32:
    push    {r4-r11, r12, lr}      // 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               // preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         // count
    ldr     r5, [sp, #108]         // params
    vldr    s0, [sp, #112]         // exponent (entry offset, pre-sub!)
    cmp     r4, #0
    beq     .Lexit0

    sub     sp, sp, #48            // local scratch frame (8-byte aligned)

    // Move the incoming source/dest pointers into callee-saved GPRs: `bl pow`
    // below clobbers the caller-saved r0-r3, so the row pointers must live in
    // r8-r11 for the whole loop (mirrors the aarch64 x19-x22 move).
    mov     r8, r0                  // srcT
    mov     r9, r1                  // srcM
    mov     r10, r2                 // srcB
    mov     r11, r3                 // dst

    vcvt.f64.f32 d0, s0
    vstr    d0, [sp, #16]          // exponent double

    // Load Params:
    //   q0 = [invDx, invDy, k, lx]; q1 = [ly, lz, lr, lg]; d4 = [lb, ss]
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]
    sub     r5, r5, #32            // r5 = params base (kept live)

    // scaleX = 1/invDx, scaleY = 1/invDy (single-precision VFP, VFPv3 ok)
    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     // ss
    vdup.32 q5, d0[0]     // scaleX
    vdup.32 q6, d0[1]     // scaleY
    vmov.f32 q7, #1.0     // ONE (never written pre-pow; d14 survives pow)

    // Ly = ly - uy (loop-invariant scalar -> stack slot).
    ldr     r7, [r5, #16]          // ly bits
    ldr     r12, [r5, #44]         // uy bits
    vmov    s0, r7
    vmov    s1, r12
    vsub.f32 s0, s0, s1           // Ly
    vstr    s0, [sp, #24]         // Ly slot
    mov     r7, #0
    str     r7, [sp, #40]         // idx = 0

.Lloop:
    // Reload loop invariants clobbered last iteration (ss/scales/lx).
    // (d6/q3 scratch: vld1 must not overlap vdup dests — VDUP with
    // overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #36
    vld1.32 {d6}, [r12]          // d6 = [ss, ...]
    vdup.32 q4, d6[0]            // ss
    vld1.32 {d6}, [r5]           // d6 = [invDx, invDy]
    vdiv.f32 s12, s28, s12       // 1/invDx (s28 = ONE)
    vdiv.f32 s13, s28, s13       // 1/invDy
    vdup.32 q5, d6[0]            // scaleX
    vdup.32 q6, d6[1]            // scaleY
    ldr     r12, [r5, #12]
    vdup.32 q8, r12              // lx (ARM->Q, no overlap hazard)

    // ---- Row T ----
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tm

    add     r12, r8, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          // top sum

    // ---- Row M (l, m, r; m = centers for surfZ) ----
    vld1.32 {q0}, [r9]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // ml

    add     r12, r9, #4
    vld1.32 {q15}, [r12]
    vshr.u32 q15, q15, #24
    vcvt.f32.u32 q15, q15
    vmul.f32 q15, q15, q4        // centers*ss = surfZ (kept in q15)

    add     r12, r9, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // mr

    // ---- Row B ----
    vld1.32 {q0}, [r10]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // bl (q0 reused; ml dead)

    add     r12, r10, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // bm

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br (q2 reused; mr dead)

    // Exact scalar bottom sum: bl + bm + bm + br. The accumulator (q9)
    // and dyRel park (q10) are pure scratch (never reloaded).
    vadd.f32 q9, q0, q1
    vadd.f32 q9, q9, q1
    vadd.f32 q9, q9, q2          // bottom sum
    vsub.f32 q3, q9, q3          // dyRel
    vmov    q10, q3               // park dyRel across the dx recompute

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #8
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tr

    vld1.32 {q2}, [r9]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // ml

    add     r12, r9, #8
    vld1.32 {q3}, [r12]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          // mr

    vadd.f32 q0, q0, q2         // tl + ml
    vadd.f32 q0, q0, q2         // (tl + ml) + ml
    vadd.f32 q1, q1, q3         // tr + mr
    vadd.f32 q1, q1, q3         // (tr + mr) + mr

    add     r12, r10, #0
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // bl
    vadd.f32 q0, q0, q2         // + bl

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br
    vadd.f32 q1, q1, q2         // + br
    vsub.f32 q0, q1, q0         // dxRel
    vmov    q3, q10               // restore dyRel (q10 scratch dead)

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          // q0 = dx
    vmul.f32 q1, q3, q6          // q1 = dy
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
    vmov.f32 q14, #1.0
    vadd.f32 q2, q2, q14         // nLen^2

    // ARMv7 VFP sqrt/div are scalar; normalize four lanes exactly.
    // Dividend is TRUE 1.0 via q2 (s8-s11 hold nLen^2 lanes here).
    vsqrt.f32 s12, s8
    vsqrt.f32 s13, s9
    vsqrt.f32 s14, s10
    vsqrt.f32 s15, s11
    vmov.f32 q2, #1.0
    vdiv.f32 s12, s8, s12
    vdiv.f32 s13, s9, s13
    vdiv.f32 s14, s10, s14
    vdiv.f32 s15, s11, s15

    // q3 now contains invLen = 1/nLen (nz lives here through the
    // L-window: it uses q2/q5/q6/q4/q9 only, never q3).
    vmul.f32 q0, q0, q3          // normalized nx
    vmul.f32 q1, q1, q3          // normalized ny
    // (nz = invLen stays in q3; q14 unused until the pack.)

    // ---- Per-pixel light vector L (scalar VFP, exact) ----
    // ux = ux0 + (idx+[0,1,2,3])*dux; Lx = lx - ux (into q2).
    // q2 (nLen^2 dead) and q9 are scratch here; q3 = nz survives.
    ldr     r7, [sp, #40]        // idx bits
    vdup.32 q2, r7               // idx broadcast (integer)
    adr     r12, .Llane_idx
    vld1.32 {d18, d19}, [r12]    // q9 = [0,1,2,3]
    vadd.i32 q2, q2, q9
    vcvt.f32.u32 q2, q2
    ldr     r12, [r5, #48]       // dux bits
    vdup.32 q9, r12
    vmul.f32 q2, q2, q9          // (idx+lane)*dux
    ldr     r12, [r5, #40]       // ux0 bits
    vdup.32 q9, r12
    vadd.f32 q2, q2, q9          // ux
    vsub.f32 q2, q8, q2          // Lx = lx - ux (q8 = lx)
    ldr     r7, [sp, #24]        // Ly bits -> r7
    ldr     r12, [r5, #20]       // lz bits -> r12
    // Per-lane L normalize + h + ndoth (scalar VFP, exact).
    // Sources: Lx s8-s11 (q2), Ly r7, lz r12, surfZ s16-s19 (q4),
    // nx s0-s3 (q0), ny s4-s7 (q1), nz s12-s15 (q3), ONE s28 (q7).
    // Dests: ndoth -> q2 lanes. Temps: q5 full (s20-s23; scaleX dead,
    // reloaded). Lhat homes (q2/q6/q4) are reused as hx/hy/hz temps
    // within the lane (read-then-write, same lane).
    // lane 0
    vmov.f32 s20, s8
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s16
    vsub.f32 s22, s22, s23       // Lz = lz - surfZ
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22       // len2
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp0_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23       // / ONE
.Lp0_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s8, s20             // Lhatx
    vmov.f32 s24, s21            // Lhaty (q6)
    vmov.f32 s16, s22            // Lhatz (q4)
    // h = normalize(Lhat+(0,0,1)); zero-guarded (scalar keeps h = 0).
    vadd.f32 s22, s22, s28       // hz = Lhatz+1
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22       // hLen2
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp0_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp0_hinv0:
    vmul.f32 s20, s20, s23       // hx
    vmul.f32 s21, s21, s23       // hy
    vmul.f32 s22, s22, s23       // hz
    // ndoth = nx*hx+ny*hy+nz*hz (Kotlin order), clamped >= 0.
    vmul.f32 s23, s0, s20
    vmla.f32 s23, s4, s21
    vmla.f32 s23, s12, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lp0_store
    veor    d11, d11, d11        // s23 = 0 (s22 dead: hz homed? no —
                                 // hx/hy/hz live only in temps; all dead
                                 // after ndoth, so zeroing d11 is safe)
.Lp0_store:
    vmov.f32 s8, s23             // ndoth -> q2 lane 0
    // lane 1
    vmov.f32 s20, s9
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s17
    vsub.f32 s22, s22, s23
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp1_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp1_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s9, s20
    vmov.f32 s25, s21
    vmov.f32 s17, s22
    vadd.f32 s22, s22, s28
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp1_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp1_hinv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmul.f32 s23, s1, s20
    vmla.f32 s23, s5, s21
    vmla.f32 s23, s13, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lp1_store
    veor    d11, d11, d11
.Lp1_store:
    vmov.f32 s9, s23
    // lane 2
    vmov.f32 s20, s10
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s18
    vsub.f32 s22, s22, s23
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp2_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp2_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s10, s20
    vmov.f32 s26, s21
    vmov.f32 s18, s22
    vadd.f32 s22, s22, s28
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp2_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp2_hinv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmul.f32 s23, s2, s20
    vmla.f32 s23, s6, s21
    vmla.f32 s23, s14, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lp2_store
    veor    d11, d11, d11
.Lp2_store:
    vmov.f32 s10, s23
    // lane 3
    vmov.f32 s20, s11
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s19
    vsub.f32 s22, s22, s23
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp3_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp3_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s11, s20
    vmov.f32 s27, s21
    vmov.f32 s19, s22
    vadd.f32 s22, s22, s28
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lp3_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lp3_hinv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmul.f32 s23, s3, s20
    vmla.f32 s23, s7, s21
    vmla.f32 s23, s15, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lp3_store
    veor    d11, d11, d11
.Lp3_store:
    vmov.f32 s11, s23
    // q2 = ndoth vector.

    // ---- per-lane scalar double pow (reference Math.pow semantics) ----
    vst1.32 {q2}, [sp]           // stash ndoth at [sp, #0..#15]
    // ---- 4-lane scalar VFP pow (no bl, invariants survive) ----
    vldr    d1, [sp, #16]        // double exponent
    vcvt.f32.f64 s1, d1          // s1 = exponent float
    vldr    s0, [sp, #0]
    POW1_VFP
    vstr    s0, [sp, #0]

    vldr    s0, [sp, #4]
    POW1_VFP
    vstr    s0, [sp, #4]

    vldr    s0, [sp, #8]
    POW1_VFP
    vstr    s0, [sp, #8]

    vldr    s0, [sp, #12]
    POW1_VFP
    vstr    s0, [sp, #12]

    // ---- rebuild regs repurposed mid-loop (no bl anymore, but q8/q11-q14
    // do not survive the Sobel/normalize window: q8 = lx, q14 = one-temp).
    ldr     r12, [r5, #8]
    vdup.32 q8, r12              // k
    add     r12, r5, #24
    vld1.32 {d18, d19}, [r12]    // d18 = [lr, lg], d19 = [lb, ...]
    vdup.32 q11, d18[0]          // lr
    vdup.32 q12, d18[1]          // lg
    vdup.32 q13, d19[0]          // lb
    vmov.f32 q14, #1.0           // one

    // ---- intensity = clamp01(k * p) ----
    vld1.32 {q2}, [sp]           // q2 = p (in-place pow results)
    vmul.f32 q2, q2, q8          // k * p
    veor    q15, q15, q15
    vmax.f32 q2, q2, q15
    vmin.f32 q2, q2, q14         // q2 = intensity

    // ---- Pack ARGB ----
    vmul.f32 q0, q2, q11          // outR
    vmul.f32 q1, q2, q12          // outG
    vmul.f32 q3, q2, q13          // outB
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

    // alpha = max(R,G,B) bytes (straight form, NOT premultiplied)
    mov     r7, #0xFF
    vdup.32 q0, r7                // 0x000000FF byte mask
    vand    q1, q3, q0            // B
    vshr.u32 q15, q3, #8
    vand    q15, q15, q0          // G
    vshr.u32 q2, q3, #16
    vand    q2, q2, q0            // R
    vmax.u8 q1, q1, q15
    vmax.u8 q1, q1, q2
    vshl.u32 q1, q1, #24
    vorr    q3, q3, q1            // alpha = max(R,G,B)

    vst1.32 {q3}, [r11]!

    add     r8, r8, #16
    add     r9, r9, #16
    add     r10, r10, #16
    ldr     r7, [sp, #40]         // idx += 4 (r7 free: alpha dead)
    add     r7, r7, #4
    str     r7, [sp, #40]
    subs    r4, r4, #4
    bne     .Lloop

.Ldone:
    add     sp, sp, #48
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}

.Lexit0:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingPointSpecularRowNeon32, .-ksvgLightingPointSpecularRowNeon32

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): identical Sobel/normalize/L/h/
// ndoth/pow math to Neon32, then a scalar per-pixel linear->sRGB LUT
// conversion of ALL four bytes (R, G, B AND the alpha byte). The alpha is
// computed as max(Rlin, Glin, Blin) BEFORE the L2S (like the aarch64
// *Neon64Linear row); the L2S LUT is monotonic so LUT[max(linear)] ==
// max(sRGB), matching the scalar maxOf() AFTER the L2S map.
//
// void ksvgLightingPointSpecularRowNeon32Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const PointLightingParams* params,
//   const uint8_t* linearToSrgb, float exponent)
//
// AAPCS32 (softfp armeabi-v7a):
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params, [sp, #8] = exponent (float),
//   [sp, #12] = linearToSrgb.
// NOTE: this (exponent, LUT) order matches the shared C++ dispatch and the
// aarch64 twin — NOT the (LUT, exponent) order of the never-dispatched
// distant-specular armv7a reference (dead code, scalar fallback).
//
// Register map (loop-invariant): same as Neon32, plus:
//   r6 = linearToSrgb LUT base (r7 and r12 remain the only closure scratch).
// ---------------------------------------------------------------------------

.macro L2S_ARGB_PIXEL inr
    // \inr = 0xAARRGGBB, converted in place through the LUT at r6,
    // stored via r11 (dst copy: caller-saved r3 dies in `bl pow`).
    // Scratch: r12 only. Preserves r8-r11 (LUT base is r6).
    mov     r12, \inr, lsr #16        // R index (bits 23-16)
    and     r12, r12, #0xFF
    ldrb    r12, [r6, r12]            // sR
    bic     \inr, \inr, #0x00FF0000
    lsl     r12, r12, #16
    orr     \inr, \inr, r12

    mov     r12, \inr, lsr #8         // G index (bits 15-8)
    and     r12, r12, #0xFF
    ldrb    r12, [r6, r12]            // sG
    bic     \inr, \inr, #0x0000FF00
    lsl     r12, r12, #8
    orr     \inr, \inr, r12

    and     r12, \inr, #0xFF          // B index (bits 7-0)
    ldrb    r12, [r6, r12]            // sB
    bic     \inr, \inr, #0x000000FF
    orr     \inr, \inr, r12

    mov     r12, \inr, lsr #24        // alpha index (bits 31-24, max-linear)
    and     r12, r12, #0xFF
    ldrb    r12, [r6, r12]            // sA
    bic     \inr, \inr, #0xFF000000
    orr     \inr, \inr, r12, lsl #24
    str     \inr, [r11], #4
.endm

// Second lane-index literal (one per entry point: ADR range).
.Llane_idx2:
.word 0, 1, 2, 3

.global ksvgLightingPointSpecularRowNeon32Linear
.type ksvgLightingPointSpecularRowNeon32Linear, %function

ksvgLightingPointSpecularRowNeon32Linear:
    push    {r4-r11, r12, lr}      // 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               // preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         // count
    ldr     r5, [sp, #108]         // params
    vldr    s0, [sp, #112]         // exponent (entry offset, pre-sub!)
    ldr     r6, [sp, #116]         // linearToSrgb LUT (entry offset, pre-sub!)
    cmp     r4, #0
    beq     .Llin_exit0

    sub     sp, sp, #48            // local scratch frame (8-byte aligned)

    // Move the incoming source/dest pointers into callee-saved GPRs: `bl pow`
    // below clobbers the caller-saved r0-r3, so the row pointers must live in
    // r8-r11 for the whole loop (mirrors the aarch64 x19-x22 move).
    mov     r8, r0                  // srcT
    mov     r9, r1                  // srcM
    mov     r10, r2                 // srcB
    mov     r11, r3                 // dst

    vcvt.f64.f32 d0, s0
    vstr    d0, [sp, #16]          // exponent double

    // Load Params:
    //   q0 = [invDx, invDy, k, lx]; q1 = [ly, lz, lr, lg]; d4 = [lb, ss]
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]
    sub     r5, r5, #32            // r5 = params base (kept live)

    // scaleX = 1/invDx, scaleY = 1/invDy (single-precision VFP, VFPv3 ok)
    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     // ss
    vdup.32 q5, d0[0]     // scaleX
    vdup.32 q6, d0[1]     // scaleY
    vmov.f32 q7, #1.0     // ONE (never written pre-pow; d14 survives pow)

    // Ly = ly - uy (loop-invariant scalar -> stack slot).
    ldr     r7, [r5, #16]          // ly bits
    ldr     r12, [r5, #44]         // uy bits
    vmov    s0, r7
    vmov    s1, r12
    vsub.f32 s0, s0, s1           // Ly
    vstr    s0, [sp, #24]         // Ly slot
    mov     r7, #0
    str     r7, [sp, #40]         // idx = 0

.Llin_loop:
    // Reload loop invariants clobbered last iteration (ss/scales/lx).
    // (d6/q3 scratch: vld1 must not overlap vdup dests — VDUP with
    // overlapping Qd/Dm is UNPREDICTABLE.)
    add     r12, r5, #36
    vld1.32 {d6}, [r12]          // d6 = [ss, ...]
    vdup.32 q4, d6[0]            // ss
    vld1.32 {d6}, [r5]           // d6 = [invDx, invDy]
    vdiv.f32 s12, s28, s12       // 1/invDx (s28 = ONE)
    vdiv.f32 s13, s28, s13       // 1/invDy
    vdup.32 q5, d6[0]            // scaleX
    vdup.32 q6, d6[1]            // scaleY
    ldr     r12, [r5, #12]
    vdup.32 q8, r12              // lx (ARM->Q, no overlap hazard)

    // ---- Row T ----
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tm

    add     r12, r8, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          // top sum

    // ---- Row M (l, m, r; m = centers for surfZ) ----
    vld1.32 {q0}, [r9]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // ml

    add     r12, r9, #4
    vld1.32 {q15}, [r12]
    vshr.u32 q15, q15, #24
    vcvt.f32.u32 q15, q15
    vmul.f32 q15, q15, q4        // centers*ss = surfZ (kept in q15)

    add     r12, r9, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // mr

    // ---- Row B ----
    vld1.32 {q0}, [r10]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // bl (q0 reused; ml dead)

    add     r12, r10, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // bm

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br (q2 reused; mr dead)

    // Exact scalar bottom sum: bl + bm + bm + br. The accumulator (q9)
    // and dyRel park (q10) are pure scratch (never reloaded).
    vadd.f32 q9, q0, q1
    vadd.f32 q9, q9, q1
    vadd.f32 q9, q9, q2          // bottom sum
    vsub.f32 q3, q9, q3          // dyRel
    vmov    q10, q3               // park dyRel across the dx recompute

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #8
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tr

    vld1.32 {q2}, [r9]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // ml

    add     r12, r9, #8
    vld1.32 {q3}, [r12]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          // mr

    vadd.f32 q0, q0, q2         // tl + ml
    vadd.f32 q0, q0, q2         // (tl + ml) + ml
    vadd.f32 q1, q1, q3         // tr + mr
    vadd.f32 q1, q1, q3         // (tr + mr) + mr

    add     r12, r10, #0
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // bl
    vadd.f32 q0, q0, q2         // + bl

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br
    vadd.f32 q1, q1, q2         // + br
    vsub.f32 q0, q1, q0         // dxRel
    vmov    q3, q10               // restore dyRel (q10 scratch dead)

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          // q0 = dx
    vmul.f32 q1, q3, q6          // q1 = dy
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
    vmov.f32 q14, #1.0
    vadd.f32 q2, q2, q14         // nLen^2

    // ARMv7 VFP sqrt/div are scalar; normalize four lanes exactly.
    // Dividend is TRUE 1.0 via q2 (s8-s11 hold nLen^2 lanes here).
    vsqrt.f32 s12, s8
    vsqrt.f32 s13, s9
    vsqrt.f32 s14, s10
    vsqrt.f32 s15, s11
    vmov.f32 q2, #1.0
    vdiv.f32 s12, s8, s12
    vdiv.f32 s13, s9, s13
    vdiv.f32 s14, s10, s14
    vdiv.f32 s15, s11, s15

    // q3 now contains invLen = 1/nLen (nz lives here through the
    // L-window: it uses q2/q5/q6/q4/q9 only, never q3).
    vmul.f32 q0, q0, q3          // normalized nx
    vmul.f32 q1, q1, q3          // normalized ny
    // (nz = invLen stays in q3; q14 unused until the pack.)

    // ---- Per-pixel light vector L (scalar VFP, exact) ----
    // ux = ux0 + (idx+[0,1,2,3])*dux; Lx = lx - ux (into q2).
    // q2 (nLen^2 dead) and q9 are scratch here; q3 = nz survives.
    ldr     r7, [sp, #40]        // idx bits
    vdup.32 q2, r7               // idx broadcast (integer)
    adr     r12, .Llane_idx2
    vld1.32 {d18, d19}, [r12]    // q9 = [0,1,2,3]
    vadd.i32 q2, q2, q9
    vcvt.f32.u32 q2, q2
    ldr     r12, [r5, #48]       // dux bits
    vdup.32 q9, r12
    vmul.f32 q2, q2, q9          // (idx+lane)*dux
    ldr     r12, [r5, #40]       // ux0 bits
    vdup.32 q9, r12
    vadd.f32 q2, q2, q9          // ux
    vsub.f32 q2, q8, q2          // Lx = lx - ux (q8 = lx)
    ldr     r7, [sp, #24]        // Ly bits -> r7
    ldr     r12, [r5, #20]       // lz bits -> r12
    // Per-lane L normalize + h + ndoth (scalar VFP, exact).
    // Sources: Lx s8-s11 (q2), Ly r7, lz r12, surfZ s16-s19 (q4),
    // nx s0-s3 (q0), ny s4-s7 (q1), nz s12-s15 (q3), ONE s28 (q7).
    // Dests: ndoth -> q2 lanes. Temps: q5 full (s20-s23; scaleX dead,
    // reloaded). Lhat homes (q2/q6/q4) are reused as hx/hy/hz temps
    // within the lane (read-then-write, same lane).
    // lane 0
    vmov.f32 s20, s8
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s16
    vsub.f32 s22, s22, s23       // Lz = lz - surfZ
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22       // len2
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq0_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23       // / ONE
.Lq0_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s8, s20             // Lhatx
    vmov.f32 s24, s21            // Lhaty (q6)
    vmov.f32 s16, s22            // Lhatz (q4)
    // h = normalize(Lhat+(0,0,1)); zero-guarded (scalar keeps h = 0).
    vadd.f32 s22, s22, s28       // hz = Lhatz+1
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22       // hLen2
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq0_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq0_hinv0:
    vmul.f32 s20, s20, s23       // hx
    vmul.f32 s21, s21, s23       // hy
    vmul.f32 s22, s22, s23       // hz
    // ndoth = nx*hx+ny*hy+nz*hz (Kotlin order), clamped >= 0.
    vmul.f32 s23, s0, s20
    vmla.f32 s23, s4, s21
    vmla.f32 s23, s12, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lq0_store
    veor    d11, d11, d11        // s23 = 0 (s22 dead: hz homed? no —
                                 // hx/hy/hz live only in temps; all dead
                                 // after ndoth, so zeroing d11 is safe)
.Lq0_store:
    vmov.f32 s8, s23             // ndoth -> q2 lane 0
    // lane 1
    vmov.f32 s20, s9
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s17
    vsub.f32 s22, s22, s23
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq1_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq1_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s9, s20
    vmov.f32 s25, s21
    vmov.f32 s17, s22
    vadd.f32 s22, s22, s28
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq1_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq1_hinv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmul.f32 s23, s1, s20
    vmla.f32 s23, s5, s21
    vmla.f32 s23, s13, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lq1_store
    veor    d11, d11, d11
.Lq1_store:
    vmov.f32 s9, s23
    // lane 2
    vmov.f32 s20, s10
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s18
    vsub.f32 s22, s22, s23
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq2_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq2_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s10, s20
    vmov.f32 s26, s21
    vmov.f32 s18, s22
    vadd.f32 s22, s22, s28
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq2_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq2_hinv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmul.f32 s23, s2, s20
    vmla.f32 s23, s6, s21
    vmla.f32 s23, s14, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lq2_store
    veor    d11, d11, d11
.Lq2_store:
    vmov.f32 s10, s23
    // lane 3
    vmov.f32 s20, s11
    vmov    s21, r7
    vmov    s22, r12
    vmov.f32 s23, s19
    vsub.f32 s22, s22, s23
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq3_linv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq3_linv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmov.f32 s11, s20
    vmov.f32 s27, s21
    vmov.f32 s19, s22
    vadd.f32 s22, s22, s28
    vmul.f32 s23, s20, s20
    vmla.f32 s23, s21, s21
    vmla.f32 s23, s22, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    beq     .Lq3_hinv0
    vsqrt.f32 s23, s23
    vdiv.f32 s23, s28, s23
.Lq3_hinv0:
    vmul.f32 s20, s20, s23
    vmul.f32 s21, s21, s23
    vmul.f32 s22, s22, s23
    vmul.f32 s23, s3, s20
    vmla.f32 s23, s7, s21
    vmla.f32 s23, s15, s22
    vcmp.f32 s23, #0.0
    vmrs    apsr_nzcv, fpscr
    bge     .Lq3_store
    veor    d11, d11, d11
.Lq3_store:
    vmov.f32 s11, s23
    // q2 = ndoth vector.

    // ---- per-lane scalar double pow (reference Math.pow semantics) ----
    vst1.32 {q2}, [sp]           // stash ndoth at [sp, #0..#15]
    // ---- 4-lane scalar VFP pow (no bl, invariants survive) ----
    vldr    d1, [sp, #16]        // double exponent
    vcvt.f32.f64 s1, d1          // s1 = exponent float
    vldr    s0, [sp, #0]
    POW1_VFP
    vstr    s0, [sp, #0]

    vldr    s0, [sp, #4]
    POW1_VFP
    vstr    s0, [sp, #4]

    vldr    s0, [sp, #8]
    POW1_VFP
    vstr    s0, [sp, #8]

    vldr    s0, [sp, #12]
    POW1_VFP
    vstr    s0, [sp, #12]

    // ---- rebuild regs repurposed mid-loop (no bl anymore, but q8/q11-q14
    // do not survive the Sobel/normalize window: q8 = lx, q14 = one-temp).
    ldr     r12, [r5, #8]
    vdup.32 q8, r12              // k
    add     r12, r5, #24
    vld1.32 {d18, d19}, [r12]    // d18 = [lr, lg], d19 = [lb, ...]
    vdup.32 q11, d18[0]          // lr
    vdup.32 q12, d18[1]          // lg
    vdup.32 q13, d19[0]          // lb
    vmov.f32 q14, #1.0           // one

    // ---- intensity = clamp01(k * p) ----
    vld1.32 {q2}, [sp]           // q2 = p (in-place pow results)
    vmul.f32 q2, q2, q8          // k * p
    veor    q15, q15, q15
    vmax.f32 q2, q2, q15
    vmin.f32 q2, q2, q14         // q2 = intensity

    // ---- Pack ARGB (linear-light bytes) ----
    vmul.f32 q0, q2, q11          // outR
    vmul.f32 q1, q2, q12          // outG
    vmul.f32 q3, q2, q13          // outB
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

    // alpha = max(R,G,B) of the LINEAR bytes, computed PRE-LUT (monotonic
    // LUT preserves the max through the conversion below).
    mov     r7, #0xFF
    vdup.32 q0, r7                // 0x000000FF byte mask
    vand    q1, q3, q0            // B
    vshr.u32 q15, q3, #8
    vand    q15, q15, q0          // G
    vshr.u32 q2, q3, #16
    vand    q2, q2, q0            // R
    vmax.u8 q1, q1, q15
    vmax.u8 q1, q1, q2
    vshl.u32 q1, q1, #24
    vorr    q3, q3, q1            // alpha = max(Rlin,Glin,Blin)

    // ---- Linear -> sRGB (scalar LUT lookups, all 4 bytes incl alpha) ----
    vmov    r7, s12
    L2S_ARGB_PIXEL r7
    vmov    r7, s13
    L2S_ARGB_PIXEL r7
    vmov    r7, s14
    L2S_ARGB_PIXEL r7
    vmov    r7, s15
    L2S_ARGB_PIXEL r7

    add     r8, r8, #16
    add     r9, r9, #16
    add     r10, r10, #16
    ldr     r7, [sp, #40]         // idx += 4 (r7 free: closure dead)
    add     r7, r7, #4
    str     r7, [sp, #40]
    subs    r4, r4, #4
    bne     .Llin_loop

.Llin_done:
    add     sp, sp, #48
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}

.Llin_exit0:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingPointSpecularRowNeon32Linear, .-ksvgLightingPointSpecularRowNeon32Linear
#ifndef __APPLE__
.section .note.GNU-stack,"",%progbits
#endif
