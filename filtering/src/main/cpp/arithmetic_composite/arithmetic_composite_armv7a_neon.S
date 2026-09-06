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
 *
 * ARMv7-A NEON hand-written kernel for SVG arithmetic composite.
 * Processes packed 4-byte RGBA pixels, 8 pixels per iteration.
 *
 * void applyArithmetic32Asm(
 *     const uint8_t* src1,   // r0
 *     const uint8_t* src2,   // r1
 *     uint8_t* dst,          // r2
 *     size_t pixels,         // r3
 *     const float* coeffs);  // [sp] (5th argument)
 *
 * coeffs[0] = k1 / 255
 * coeffs[1] = k2
 * coeffs[2] = k3
 * coeffs[3] = k4 * 255 + 0.5
 */

.syntax unified
.fpu neon
.text
.align 2
.global applyArithmetic32Asm
.type applyArithmetic32Asm, %function

applyArithmetic32Asm:
    @ Load 5th argument (coeffs) from stack into ip
    ldr         ip, [sp]

    @ q12 = k1/255, q13 = k2, q14 = k3, q15 = k4*255 + 0.5
    vld1.32     {d8, d9}, [ip]
    vdup.32     q12, d8[0]
    vdup.32     q13, d8[1]
    vdup.32     q14, d9[0]
    vdup.32     q15, d9[1]

    @ Eight pixels per iteration. Use ip as loop counter.
    lsrs        ip, r3, #3
    beq         .done

.loop:
    @ Deinterleave 8 packed RGBA pixels.
    @ d0..d3 = src1 R,G,B,A (8 bytes each)
    @ d4..d7 = src2 R,G,B,A (8 bytes each)
    vld4.8      {d0-d3}, [r0]!
    vld4.8      {d4-d7}, [r1]!

    @ ---------------- Channel 0 (R) ----------------
    vmovl.u8    q8, d0       @ q8 (d16,d17) = R1 (16-bit)
    vmovl.u16   q10, d16     @ q10 (d20,d21) = R1 low 4 (32-bit)
    vmovl.u16   q11, d17     @ q11 (d22,d23) = R1 high 4 (32-bit)
    vcvt.f32.u32 q10, q10
    vcvt.f32.u32 q11, q11

    vmovl.u8    q8, d4       @ q8 (d16,d17) = R2 (16-bit)
    vmovl.u16   q4, d16      @ q4 (d8,d9) = R2 low 4 (32-bit)
    vmovl.u16   q5, d17      @ q5 (d10,d11) = R2 high 4 (32-bit)
    vcvt.f32.u32 q4, q4
    vcvt.f32.u32 q5, q5

    @ Low half: a=q10, b=q4. Formula: k1/255*a*b + k2*a + k3*b + k4*255+0.5
    vmov.f32    q6, q15
    vmla.f32    q6, q4, q14
    vmla.f32    q6, q10, q13
    vmul.f32    q10, q10, q4
    vmla.f32    q6, q10, q12
    vcvt.u32.f32 q6, q6
    vqmovn.u32  d16, q6

    @ High half: a=q11, b=q5
    vmov.f32    q7, q15
    vmla.f32    q7, q5, q14
    vmla.f32    q7, q11, q13
    vmul.f32    q11, q11, q5
    vmla.f32    q7, q11, q12
    vcvt.u32.f32 q7, q7
    vqmovn.u32  d17, q7

    vqmovn.u16  d0, q8


    @ ---------------- Channel 1 (G) ----------------
    vmovl.u8    q8, d1
    vmovl.u16   q10, d16
    vmovl.u16   q11, d17
    vcvt.f32.u32 q10, q10
    vcvt.f32.u32 q11, q11

    vmovl.u8    q8, d5
    vmovl.u16   q4, d16
    vmovl.u16   q5, d17
    vcvt.f32.u32 q4, q4
    vcvt.f32.u32 q5, q5

    vmov.f32    q6, q15
    vmla.f32    q6, q4, q14
    vmla.f32    q6, q10, q13
    vmul.f32    q10, q10, q4
    vmla.f32    q6, q10, q12
    vcvt.u32.f32 q6, q6
    vqmovn.u32  d16, q6

    vmov.f32    q7, q15
    vmla.f32    q7, q5, q14
    vmla.f32    q7, q11, q13
    vmul.f32    q11, q11, q5
    vmla.f32    q7, q11, q12
    vcvt.u32.f32 q7, q7
    vqmovn.u32  d17, q7

    vqmovn.u16  d1, q8


    @ ---------------- Channel 2 (B) ----------------
    vmovl.u8    q8, d2
    vmovl.u16   q10, d16
    vmovl.u16   q11, d17
    vcvt.f32.u32 q10, q10
    vcvt.f32.u32 q11, q11

    vmovl.u8    q8, d6
    vmovl.u16   q4, d16
    vmovl.u16   q5, d17
    vcvt.f32.u32 q4, q4
    vcvt.f32.u32 q5, q5

    vmov.f32    q6, q15
    vmla.f32    q6, q4, q14
    vmla.f32    q6, q10, q13
    vmul.f32    q10, q10, q4
    vmla.f32    q6, q10, q12
    vcvt.u32.f32 q6, q6
    vqmovn.u32  d16, q6

    vmov.f32    q7, q15
    vmla.f32    q7, q5, q14
    vmla.f32    q7, q11, q13
    vmul.f32    q11, q11, q5
    vmla.f32    q7, q11, q12
    vcvt.u32.f32 q7, q7
    vqmovn.u32  d17, q7

    vqmovn.u16  d2, q8


    @ ---------------- Channel 3 (A) ----------------
    vmovl.u8    q8, d3
    vmovl.u16   q10, d16
    vmovl.u16   q11, d17
    vcvt.f32.u32 q10, q10
    vcvt.f32.u32 q11, q11

    vmovl.u8    q8, d7
    vmovl.u16   q4, d16
    vmovl.u16   q5, d17
    vcvt.f32.u32 q4, q4
    vcvt.f32.u32 q5, q5

    vmov.f32    q6, q15
    vmla.f32    q6, q4, q14
    vmla.f32    q6, q10, q13
    vmul.f32    q10, q10, q4
    vmla.f32    q6, q10, q12
    vcvt.u32.f32 q6, q6
    vqmovn.u32  d16, q6

    vmov.f32    q7, q15
    vmla.f32    q7, q5, q14
    vmla.f32    q7, q11, q13
    vmul.f32    q11, q11, q5
    vmla.f32    q7, q11, q12
    vcvt.u32.f32 q7, q7
    vqmovn.u32  d17, q7

    vqmovn.u16  d3, q8


    vst4.8      {d0-d3}, [r2]!

    subs        ip, ip, #1
    bne         .loop

.done:
    bx          lr

.size applyArithmetic32Asm, .-applyArithmetic32Asm
