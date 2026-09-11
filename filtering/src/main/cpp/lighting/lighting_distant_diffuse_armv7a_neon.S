/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
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
.global ksvgLightingDistantDiffuseRowNeon32
.type ksvgLightingDistantDiffuseRowNeon32, %function

// void ksvgLightingDistantDiffuseRowNeon32(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params)
//
// AAPCS32:
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params
//
// LightingParams layout (lighting.cpp, hard contract):
//   +0 invDx  +4 invDy  +8 k  +12 lx  +16 ly  +20 lz
//   +24 lr    +28 lg    +32 lb +36 ss
//
// Processes 4 ARGB8888 pixels per iteration. For output pixel (x) the taps
// are read from columns (x-1 .. x+1) of rows y-1/y/y+1 via three overlapping
// q-register loads at [src+0], [src+4], [src+8] (l/m/r of each row).
//
// math (matches the Kotlin/scalar reference op order):
//   h = (alpha >> 24) * ss
//   dxRel = (rT-lT) + 2*(rM-lM) + (rB-lB)
//   dyRel = (lB+2*mB+rB) - (lT+2*mT+rT)
//   nx = -dxRel*scaleX, ny = -dyRel*scaleY, nz = 1
//   rec = rsqrt(nx^2+ny^2+1) with 2 Newton-Raphson refinements
//   dot = nx*rec*lx + ny*rec*ly + rec*lz
//   intensity = clamp(clamp(dot,0)*k, 0, 1)
//   out = (round(lr*intensity)<<16) | (round(lg*intensity)<<8)
//         | round(lb*intensity) | 0xFF000000
//
// Register map (loop-invariant):
//   q4 = ss        q5 = scaleX = 1/invDx   q6 = scaleY = 1/invDy
//   q7 = k         q8 = lx      q9 = ly
//   q10 = lz       q11 = lr     q12 = lg
//   q13 = lb       q14 = 1.0f
//   q0-q3, q15     = scratch (q15 is transient only)

ksvgLightingDistantDiffuseRowNeon32:
    push    {r4-r11, r12, lr}      @ 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               @ preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         @ count
    ldr     r5, [sp, #108]         @ params
    cmp     r4, #0
    beq     .Ldone

    // Load Params:
    //   q0 = [invDx, invDy, k, lx]; q1 = [ly, lz, lr, lg]; d4 = [lb, ss]
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]

    // scaleX = 1/invDx, scaleY = 1/invDy (single-precision VFP, VFPv3 ok)
    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     @ ss
    vdup.32 q5, d0[0]     @ scaleX
    vdup.32 q6, d0[1]     @ scaleY
    vdup.32 q7, d1[0]     @ k
    vdup.32 q8, d1[1]     @ lx
    vdup.32 q9, d2[0]     @ ly
    vdup.32 q10, d2[1]    @ lz
    vdup.32 q11, d3[0]    @ lr
    vdup.32 q12, d3[1]    @ lg
    vdup.32 q13, d4[0]    @ lb
    vmov.f32 q14, #1.0    @ one

.Lloop:
    // ---- Row T ----
    vld1.32 {q0}, [r0]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          @ tl

    add     r10, r0, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          @ tm

    add     r10, r0, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          @ top sum

    // ---- Row M ----
    vld1.32 {q0}, [r1]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          @ ml

    add     r10, r1, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ mr

    // ---- Row B ----
    vld1.32 {q0}, [r2]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          @ bl

    add     r10, r2, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          @ bm

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ br

    // Exact scalar bottom sum: bl + bm + bm + br
    vadd.f32 q14, q0, q1
    vadd.f32 q14, q14, q1
    vadd.f32 q14, q14, q2        @ bottom sum
    vsub.f32 q3, q14, q3         @ dyRel
    vmov    q14, q3               @ preserve dyRel while recomputing dx

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r0]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          @ tl

    add     r10, r0, #8
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          @ tr

    vld1.32 {q2}, [r1]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ ml

    add     r10, r1, #8
    vld1.32 {q3}, [r10]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          @ mr

    vadd.f32 q0, q0, q2         @ tl + ml
    vadd.f32 q0, q0, q2         @ (tl + ml) + ml
    vadd.f32 q1, q1, q3         @ tr + mr
    vadd.f32 q1, q1, q3         @ (tr + mr) + mr

    add     r10, r2, #0
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ bl
    vadd.f32 q0, q0, q2         @ + bl

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ br
    vadd.f32 q1, q1, q2         @ + br
    vsub.f32 q0, q1, q0         @ dxRel
    vmov    q3, q14               @ restore dyRel

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          @ q0 = dx
    vmul.f32 q1, q3, q6          @ q1 = dy
    // ---- Normalize exactly like Kotlin reference ----
    // nLen = sqrt(nx*nx + ny*ny + 1); nx/=nLen; ny/=nLen; nz=1/nLen
    vneg.f32 q0, q0              @ nx0
    vneg.f32 q1, q1              @ ny0
    vmul.f32 q2, q0, q0
    vmul.f32 q3, q1, q1
    vadd.f32 q2, q2, q3
    vmov.f32 q14, #1.0
    vadd.f32 q2, q2, q14         @ nLen^2

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
    vmul.f32 q0, q0, q3          @ normalized nx
    vmul.f32 q1, q1, q3          @ normalized ny
    vmov q14, q3                 @ normalized nz = invLen

    // Kotlin dot: nx*lx + ny*ly + nz*lz
    vmul.f32 q2, q0, q8
    vmul.f32 q15, q1, q9
    vadd.f32 q2, q2, q15
    vmul.f32 q15, q14, q10
    vadd.f32 q2, q2, q15
    vmov.f32 q14, #1.0           @ restore one

    // ---- intensity = min(max(dot, 0)*k, 1) ----
    veor    q15, q15, q15         @ zero (transient scratch)
    vmax.f32 q2, q2, q15
    vmul.f32 q2, q2, q7
    vmin.f32 q2, q2, q14          @ q2 = intensity

    // ---- Pack ARGB ----
    vmul.f32 q0, q2, q11          @ outR
    vmul.f32 q1, q2, q12          @ outG
    vmul.f32 q3, q2, q13          @ outB
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
    vdup.32 q0, r6                @ alpha = 0xFF
    vorr    q3, q3, q0

    vst1.32 {q3}, [r3]!

    add     r0, r0, #16
    add     r1, r1, #16
    add     r2, r2, #16
    subs    r4, r4, #4
    bne     .Lloop

.Ldone:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingDistantDiffuseRowNeon32, .-ksvgLightingDistantDiffuseRowNeon32