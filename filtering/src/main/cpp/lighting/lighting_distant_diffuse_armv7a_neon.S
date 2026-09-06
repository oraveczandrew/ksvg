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
.fpu neon-vfpv4
.text
.align 2
.global ksvgLightingDistantDiffuseRowNeon32
.type ksvgLightingDistantDiffuseRowNeon32, %function

// void ksvgLightingDistantDiffuseRowNeon32(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params)

ksvgLightingDistantDiffuseRowNeon32:
    push    {r4-r11, lr}
    vpush   {d8-d15}

    ldr     r4, [sp, #100]    @ count
    ldr     r5, [sp, #104]    @ params

    cbz     r4, .Ldone

    // Load Params
    vld1.32 {d0, d1}, [r5]!  @ q0 = [invDx, invDy, k, lx]
    vld1.32 {d2, d3}, [r5]!  @ q1 = [ly, lz, lr, lg]
    vld1.32 {d4}, [r5]       @ d4 = [lb, ss]

    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q8, s0           @ scaleX
    vdup.32 q9, s1           @ scaleY
    vdup.32 q10, s2          @ k
    vdup.32 q11, s3          @ lx
    vdup.32 q12, s4          @ ly
    vdup.32 q13, s5          @ lz

    vdup.32 q14, s6          @ lr
    vdup.32 q15, s7          @ lg
    vdup.32 q4, s8           @ lb
    vdup.32 q5, s9           @ ss

    vmov.f32 q6, #1.0        @ one
    vmov.f32 q7, #2.0        @ two
    veor    q16, q16, q16    @ zero

    mov     r6, #0xFF000000
    vdup.32 q17, r6

.Lloop:
    // Row T
    vld1.32 {q0}, [r0]!
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0      @ h_lT

    sub     r0, r0, #16
    add     r10, r0, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1      @ h_mT

    add     r10, r0, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2      @ h_rT

    vmul.f32 q18, q1, q7
    vadd.f32 q18, q18, q0
    vadd.f32 q18, q18, q2    @ q18 = sumT_rel

    vsub.f32 q19, q2, q0     @ dx_rel_partial

    // Row M
    vld1.32 {q0}, [r1]!
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0      @ h_lM

    sub     r1, r1, #16
    add     r10, r1, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2      @ h_rM

    vsub.f32 q20, q2, q0
    vmul.f32 q20, q20, q7
    vadd.f32 q19, q19, q20

    // Row B
    vld1.32 {q0}, [r2]!
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0      @ h_lB

    sub     r2, r2, #16
    add     r10, r2, #4
    vld1.32 {q1}, [r10]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1      @ h_mB

    add     r10, r2, #8
    vld1.32 {q2}, [r10]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2      @ h_rB

    vmul.f32 q20, q1, q7
    vadd.f32 q20, q20, q0
    vadd.f32 q20, q20, q2    @ sumB_rel

    vsub.f32 q2, q2, q0
    vadd.f32 q19, q19, q2    @ final dx_rel

    vsub.f32 q20, q20, q18   @ final dy_rel

    vmul.f32 q0, q5, q8
    vmul.f32 q19, q19, q0    @ dx
    vmul.f32 q0, q5, q9
    vmul.f32 q20, q20, q0    @ dy

    vneg.f32 q21, q19
    vneg.f32 q22, q20
    vmul.f32 q23, q21, q21
    vmul.f32 q25, q22, q22
    vadd.f32 q23, q23, q25
    vadd.f32 q23, q23, q6

    vrsqrte.f32 q0, q23
    vrsqrts.f32 q1, q23, q0
    vmul.f32 q0, q0, q1      @ 1/nLen

    vmul.f32 q21, q21, q0
    vmul.f32 q22, q22, q0

    vmul.f32 q24, q21, q11
    vmul.f32 q25, q22, q12
    vadd.f32 q24, q24, q25
    vmul.f32 q25, q0, q13
    vadd.f32 q24, q24, q25

    vmax.f32 q24, q24, q16
    vmul.f32 q24, q24, q10
    vmin.f32 q24, q24, q6    @ intensity

    vmul.f32 q0, q24, q14
    vmul.f32 q1, q24, q15
    vmul.f32 q2, q24, q4

    vcvt.u32.f32 q0, q0
    vcvt.u32.f32 q1, q1
    vcvt.u32.f32 q2, q2

    vshl.u32 q0, q0, #16
    vshl.u32 q1, q1, #8
    vorr     q2, q2, q0
    vorr     q2, q2, q1
    vorr     q2, q2, q17

    vst1.32 {q2}, [r3]!

    add     r0, r0, #16
    add     r1, r1, #16
    add     r2, r2, #16
    subs    r4, r4, #4
    bne     .Lloop

.Ldone:
    vpop    {d8-d15}
    pop     {r4-r11, pc}
.size ksvgLightingDistantDiffuseRowNeon32, .-ksvgLightingDistantDiffuseRowNeon32
