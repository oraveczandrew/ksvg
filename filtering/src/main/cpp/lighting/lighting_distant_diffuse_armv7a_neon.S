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
.global ksvgLightingDistantDiffuseNeon32
.type ksvgLightingDistantDiffuseNeon32, %function

// void ksvgLightingDistantDiffuseNeon32(
//   const float* ht, const float* hm, const float* hb,
//   int count,
//   float invDx, float invDy, float k,
//   float lx, float ly, float lz,
//   float* outIntensity)
// AAPCS:
//   r0=ht r1=hm r2=hb r3=count
//   After push:
//   [sp,#104]=invDx [sp,#108]=invDy [sp,#112]=k [sp,#116]=lx
//   [sp,#120]=ly [sp,#124]=lz [sp,#128]=outIntensity

ksvgLightingDistantDiffuseNeon32:
    push    {r4-r11, lr}
    vpush   {d8-d15}

    // Offset from sp: 9 registers (36 bytes) + 8 d-registers (64 bytes) = 100 bytes.
    // Stack args start at sp + 100.
    vldr    s0, [sp, #100]    @ invDx
    vldr    s1, [sp, #104]    @ invDy
    vldr    s2, [sp, #108]    @ k
    vldr    s3, [sp, #112]    @ lx
    vldr    s4, [sp, #116]    @ ly
    vldr    s5, [sp, #120]    @ lz
    ldr     r4, [sp, #124]    @ out

    vdup.32 q8, s0            @ invDx
    vdup.32 q9, s1            @ invDy
    vdup.32 q10, s2           @ k
    vdup.32 q11, s3           @ lx
    vdup.32 q12, s4           @ ly
    vdup.32 q13, s5           @ lz

    vmov.f32 q14, #1.0
    vmov.f32 q15, #2.0
    veor    q7, q7, q7        @ zero

    cmp     r3, #0
    beq     .Ldone

.Lloop:
    @ Overlapping loads for 4 pixels
    vld1.32 {q0}, [r0]        @ ht[0..3]
    add     r10, r0, #4
    vld1.32 {q1}, [r10]       @ ht[1..4]
    add     r10, r0, #8
    vld1.32 {q2}, [r10]       @ ht[2..5]

    vld1.32 {q3}, [r1]        @ hm[0..3]
    add     r10, r1, #4
    vld1.32 {q4}, [r10]       @ hm[1..4]
    add     r10, r1, #8
    vld1.32 {q5}, [r10]       @ hm[2..5]

    vld1.32 {q6}, [r2]        @ hb[0..3]
    @ Reuse r10 for hb+4 and hb+8
    add     r10, r2, #4
    vld1.32 {q16}, [r10]      @ hb[1..4]
    add     r10, r2, #8
    vld1.32 {q17}, [r10]      @ hb[2..5]

    @ sumR = rT + 2*rM + rB
    vmul.f32 q18, q5, q15
    vadd.f32 q18, q18, q2
    vadd.f32 q18, q18, q17

    @ sumL = lT + 2*lM + lB
    vmul.f32 q19, q3, q15
    vadd.f32 q19, q19, q0
    vadd.f32 q19, q19, q6

    @ sumB = lB + 2*mB + rB
    vmul.f32 q20, q16, q15
    vadd.f32 q20, q20, q6
    vadd.f32 q20, q20, q17

    @ sumT = lT + 2*mT + rT
    vmul.f32 q21, q1, q15
    vadd.f32 q21, q21, q0
    vadd.f32 q21, q21, q2

    @ dzdx = (sumR - sumL) / invDx
    vsub.f32 q18, q18, q19
    @ ARMv7 reciprocal estimate + refinements
    vrecpe.f32 q19, q8
    vrecps.f32 q22, q8, q19
    vmul.f32 q19, q19, q22
    vrecps.f32 q22, q8, q19
    vmul.f32 q19, q19, q22
    vmul.f32 q18, q18, q19

    @ dzdy = (sumB - sumT) / invDy
    vsub.f32 q20, q20, q21
    vrecpe.f32 q21, q9
    vrecps.f32 q22, q9, q21
    vmul.f32 q21, q21, q22
    vrecps.f32 q22, q9, q21
    vmul.f32 q21, q21, q22
    vmul.f32 q20, q20, q21

    @ n = (-dzdx, -dzdy, 1)
    vneg.f32 q18, q18
    vneg.f32 q20, q20

    @ nLen = sqrt(nx*nx + ny*ny + 1)
    vmul.f32 q22, q18, q18
    vmla.f32 q22, q20, q20
    vadd.f32 q22, q22, q14
    vrsqrte.f32 q23, q22
    vrsqrts.f32 q24, q22, q23
    vmul.f32 q23, q23, q24
    vrsqrts.f32 q24, q22, q23
    vmul.f32 q23, q23, q24
    @ q23 is 1/nLen

    @ nx/nLen, ny/nLen, nz/nLen
    vmul.f32 q18, q18, q23
    vmul.f32 q20, q20, q23
    @ nz = 1/nLen = q23

    @ dot = nx*lx + ny*ly + nz*lz
    vmul.f32 q18, q18, q11
    vmla.f32 q18, q20, q12
    vmla.f32 q18, q23, q13

    @ max(dot, 0), then k, then min 1
    vmax.f32 q18, q18, q7
    vmul.f32 q18, q18, q10
    vmin.f32 q18, q18, q14

    vst1.32 {q18}, [r4]!
    add     r0, r0, #16
    add     r1, r1, #16
    add     r2, r2, #16
    subs    r3, r3, #4
    bne     .Lloop

.Ldone:
    vpop    {d8-d15}
    pop     {r4-r11, pc}
.size ksvgLightingDistantDiffuseNeon32, .-ksvgLightingDistantDiffuseNeon32
