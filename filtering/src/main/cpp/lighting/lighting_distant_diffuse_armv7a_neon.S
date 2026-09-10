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
    vmul.f32 q0, q0, q4          @ q0 = h_lT = alpha*ss

    add     r10, r0, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          @ q1 = h_mT

    add     r10, r0, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ q2 = h_rT

    vadd.f32 q3, q1, q1          @ 2*mT
    vadd.f32 q3, q3, q0          @ + lT
    vadd.f32 q3, q3, q2          @ q3 = sumT
    vsub.f32 q1, q2, q0          @ q1 = dx_rel (rT - lT)

    // ---- Row M (middle column cancels out of dx) ----
    vld1.32 {q0}, [r1]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          @ q0 = h_lM

    add     r10, r1, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ q2 = h_rM

    vsub.f32 q2, q2, q0          @ rM - lM
    vadd.f32 q2, q2, q2          @ 2*(rM - lM)
    vadd.f32 q1, q1, q2          @ dx_rel += 2*(rM - lM)

    // ---- Row B ----
    vld1.32 {q0}, [r2]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          @ q0 = h_lB

    add     r10, r2, #4
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          @ q2 = h_mB

    add     r10, r2, #8
    vld1.32 {q15}, [r10]
    vshr.u32 q15, q15, #24
    vcvt.f32.u32 q15, q15
    vmul.f32 q15, q15, q4        @ q15 = h_rB

    vadd.f32 q2, q2, q2          @ 2*mB
    vadd.f32 q2, q2, q0          @ + lB
    vadd.f32 q2, q2, q15         @ sumB
    vsub.f32 q2, q2, q3          @ q2 = dy_rel = sumB - sumT
    vsub.f32 q0, q15, q0         @ rB - lB
    vadd.f32 q1, q1, q0          @ q1 = final dx_rel

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q1, q5          @ q0 = dx
    vmul.f32 q1, q2, q6          @ q1 = dy

    // ---- Surface normal: n = (-dx, -dy, 1) ----
    vneg.f32 q0, q0              @ nx
    vneg.f32 q1, q1              @ ny

    vmul.f32 q2, q0, q0          @ nx^2
    vmul.f32 q3, q1, q1          @ ny^2
    vadd.f32 q2, q2, q3
    vadd.f32 q2, q2, q14         @ nLen^2 = nx^2 + ny^2 + 1

    // 1/nLen via vrsqrte + two Newton-Raphson refinements (matches the
    // previous ARMv7 C++ NEON reference's two-step refinement).
    vrsqrte.f32 q3, q2           @ estimate
    vmul.f32 q15, q3, q3         @ est^2 (VRSQRTS = (3 - Vn*Vm)/2)
    vrsqrts.f32 q15, q2, q15     @ (3 - nLen^2*est^2) / 2
    vmul.f32 q3, q3, q15         @ refinement 1
    vmul.f32 q15, q3, q3         @ est1^2
    vrsqrts.f32 q15, q2, q15     @ refinement 2
    vmul.f32 q3, q3, q15         @ q3 = 1/nLen

    vmul.f32 q0, q0, q3          @ nx' = nx / nLen
    vmul.f32 q1, q1, q3          @ ny' = ny / nLen
                                 @ nz' = q3 = 1/nLen

    // ---- dot = nx'*lx + ny'*ly + nz'*lz ----
    vmul.f32 q2, q0, q8
    vmla.f32 q2, q1, q9
    vmla.f32 q2, q3, q10

    // ---- intensity = min(max(dot, 0)*k, 1) ----
    veor    q15, q15, q15         @ zero (transient scratch)
    vmax.f32 q2, q2, q15
    vmul.f32 q2, q2, q7
    vmin.f32 q2, q2, q14          @ q2 = intensity

    // ---- Pack ARGB ----
    vmul.f32 q0, q2, q11          @ outR
    vmul.f32 q1, q2, q12          @ outG
    vmul.f32 q3, q2, q13          @ outB
    vcvt.u32.f32 q0, q0           @ round-to-nearest-even == Kotlin roundToInt()
    vcvt.u32.f32 q1, q1
    vcvt.u32.f32 q3, q3

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