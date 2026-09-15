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

#include "asm_macros.S"

.macro FORMULA8 dA, dB, dOut
    /* Expand A/B to two groups of four float32 values. */
    vmovl.u8 q0, \dA
    vmovl.u8 q1, \dB
    vmovl.u16 q2, d0
    vmovl.u16 q3, d1
    vmovl.u16 q0, d2
    vmovl.u16 q1, d3

    vcvt.f32.u32 q2, q2      /* A low */
    vcvt.f32.u32 q3, q3      /* A high */
    vcvt.f32.u32 q0, q0      /* B low */
    vcvt.f32.u32 q1, q1      /* B high */

    /* Broadcast k1/255 (q5), k2 (q6), k3 (q7) from the core register. */
    ldr     r2, [sp, #0]
    vdup.32 q5, r2           /* k1 / 255 */
    ldr     r2, [sp, #4]
    vdup.32 q6, r2           /* k2 */
    ldr     r2, [sp, #8]
    vdup.32 q7, r2           /* k3 */

    /* Low four pixels: q4 = result.  Non-FMA ordering: ((a*b*k1) + a*k2) + b*k3) + c4. */
    vmul.f32 q4, q2, q0
    vmul.f32 q4, q4, q5
    vmul.f32 q2, q2, q6
    vadd.f32 q4, q4, q2
    vmul.f32 q0, q0, q7
    vadd.f32 q4, q4, q0
    ldr     r2, [sp, #12]
    vdup.32 q5, r2           /* k4*255 + 0.5 */
    vadd.f32 q4, q4, q5

    /* High four pixels: q2 = result, q0 = scratch. */
    ldr     r2, [sp, #0]
    vdup.32 q5, r2           /* k1 / 255 */
    vmul.f32 q2, q3, q1
    vmul.f32 q2, q2, q5
    ldr     r2, [sp, #4]
    vdup.32 q6, r2           /* k2 */
    vmul.f32 q0, q3, q6
    vadd.f32 q2, q2, q0
    ldr     r2, [sp, #8]
    vdup.32 q7, r2           /* k3 */
    vmul.f32 q0, q1, q7
    vadd.f32 q2, q2, q0
    ldr     r2, [sp, #12]
    vdup.32 q3, r2           /* k4*255 + 0.5 */
    vadd.f32 q2, q2, q3

    /* VCVT.S32.F32 on Advanced SIMD truncates toward zero. */
    vcvt.s32.f32 q4, q4
    vcvt.s32.f32 q2, q2
    vqmovn.s32 d14, q4
    vqmovn.s32 d15, q2
    vqmovun.s16 d8, q7
    vmov    \dOut, d8
.endm

.macro CHANNEL acc, p, q, shift, scratch
    mov     \scratch, \p, lsr #\shift
    and     \scratch, \scratch, #0xff
    vmov    s0, \scratch
    vcvt.f32.u32 s0, s0
    mov     \scratch, \q, lsr #\shift
    and     \scratch, \scratch, #0xff
    vmov    s1, \scratch
    vcvt.f32.u32 s1, s1
    vmul.f32 s2, s0, s1
    vmul.f32 s2, s2, s8
    vmul.f32 s3, s0, s9
    vadd.f32 s2, s2, s3
    vmul.f32 s3, s1, s10
    vadd.f32 s2, s2, s3
    vadd.f32 s2, s2, s11
    vmax.f32 d1, d1, d6
    vmin.f32 d1, d1, d7
    vcvt.s32.f32 d2, d1
    vmov    \scratch, s4
    and     \scratch, \scratch, #0xff
    orr     \acc, \acc, \scratch, lsl #\shift
.endm

.macro CHANNEL_L acc, p, q, shift, scratch, lut, lut2
    mov     \scratch, \p, lsr #\shift
    and     \scratch, \scratch, #0xff
    ldrb    \scratch, [\lut, \scratch]
    vmov    s0, \scratch
    vcvt.f32.u32 s0, s0
    mov     \scratch, \q, lsr #\shift
    and     \scratch, \scratch, #0xff
    ldrb    \scratch, [\lut, \scratch]
    vmov    s1, \scratch
    vcvt.f32.u32 s1, s1
    vmul.f32 s2, s0, s1
    vmul.f32 s2, s2, s8
    vmul.f32 s3, s0, s9
    vadd.f32 s2, s2, s3
    vmul.f32 s3, s1, s10
    vadd.f32 s2, s2, s3
    vadd.f32 s2, s2, s11
    vmax.f32 d1, d1, d6
    vmin.f32 d1, d1, d7
    vcvt.s32.f32 d2, d1
    vmov    \scratch, s4
    and     \scratch, \scratch, #0xff
    ldrb    \scratch, [\lut2, \scratch]
    orr     \acc, \acc, \scratch, lsl #\shift
.endm

.text
.p2align 5
.globl SYM(applyArithmeticNeon)
TYPE(SYM(applyArithmeticNeon), %function)
SYM(applyArithmeticNeon):
    push    {r4-r11, lr}
    vpush   {d8-d15}
    sub     sp, sp, #16
    mov     r7, r3

    /* Constants */
    vldr    s0, [sp, #132]       /* k1 */
    movw    r3, #0x8081
    movt    r3, #0x3b80           /* float 1/255 */
    vmov    s1, r3
    vmul.f32 s0, s0, s1
    vstr    s0, [sp, #0]
    vldr    s0, [sp, #136]       /* k2 */
    vstr    s0, [sp, #4]
    vldr    s0, [sp, #140]       /* k3 */
    vstr    s0, [sp, #8]
    vldr    s0, [sp, #144]       /* k4 */
    movw    r3, #0x0000
    movt    r3, #0x437f           /* 255.0f */
    vmov    s1, r3
    vmul.f32 s0, s0, s1
    movw    r3, #0x0000
    movt    r3, #0x3f00           /* 0.5f */
    vmov    s1, r3
    vadd.f32 s0, s0, s1
    vstr    s0, [sp, #12]

    mov     r4, r0
    mov     r5, r1
    mov     r6, r2

    ldr     r8, [sp, #116]       /* clipLeft */
    ldr     r9, [sp, #120]       /* clipTop */
    ldr     r10, [sp, #124]      /* clipRight */
    ldr     r11, [sp, #128]      /* clipBottom */
    ldr     r0, [sp, #152]       /* srgbToLinear */
    ldr     r1, [sp, #156]       /* linearToSrgb */

    mla     r3, r9, r7, r8
    add     r4, r4, r3, lsl #2
    add     r5, r5, r3, lsl #2
    add     r6, r6, r3, lsl #2

    sub     r8, r10, r8          /* width */
    lsl     r10, r7, #2          /* row stride */
    sub     r11, r11, r9         /* row count */
    ldr     r9, [sp, #148]       /* useLinear */

.Lrow:
    mov     r14, r8, lsl #2      /* remaining bytes */

    cmp     r9, #0
    bne     .Llinear_row

.Lnonlin_vec:
    cmp     r14, #32
    blo     .Lnonlin_tail
    vld4.8  {d0, d1, d2, d3}, [r4]!
    vld4.8  {d4, d5, d6, d7}, [r5]!
    vmov    d16, d0
    vmov    d17, d1
    vmov    d18, d2
    vmov    d19, d3
    vmov    d20, d4
    vmov    d21, d5
    vmov    d22, d6
    vmov    d23, d7
    FORMULA8 d16, d20, d24
    FORMULA8 d17, d21, d25
    FORMULA8 d18, d22, d26
    FORMULA8 d19, d23, d27
    vst4.8  {d24, d25, d26, d27}, [r6]!
    sub     r14, r14, #32
    b       .Lnonlin_vec

.Lnonlin_tail:
    mov     r3, r14, lsr #2
    cmp     r3, #0
    beq     .Lnext_row
    vldr    s8, [sp, #0]
    vldr    s9, [sp, #4]
    vldr    s10, [sp, #8]
    vldr    s11, [sp, #12]
    veor    d6, d6, d6
    movw    r12, #0x0000
    movt    r12, #0x437f
    vmov    s14, r12
    vmov    s15, r12
.Lnonlin_tail_pixel:
    ldr     r0, [r4], #4
    ldr     r1, [r5], #4
    eor     r2, r2, r2
    CHANNEL r2, r0, r1, 0, r12
    CHANNEL r2, r0, r1, 8, r12
    CHANNEL r2, r0, r1, 16, r12
    CHANNEL r2, r0, r1, 24, r12
    str     r2, [r6], #4
    subs    r3, r3, #1
    bne     .Lnonlin_tail_pixel
    b       .Lnext_row

.Llinear_row:
.Llinear_vec:
    cmp     r14, #32
    blo     .Llinear_tail
    vld4.8  {d0, d1, d2, d3}, [r4]!
    vld4.8  {d4, d5, d6, d7}, [r5]!
    vmov    d22, d3
    vmov    d23, d7

    @ Scan S2L LUT for 6 channels. Accumulators d16-d21.
    vmov.i8 q8, #0
    vmov.i8 q9, #0
    vmov.i8 q10, #0
    mov     r3, r0
    mov     r12, #0
    vmov.i8 d31, #15
.Ls2l_scan:
    vld1.8  {d14, d15}, [r3]!
    vdup.8  d30, r12

    vshr.u8 d29, d0, #4
    vceq.u8 d29, d29, d30
    vand    d28, d0, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d16
    vmov    d16, d29

    vshr.u8 d29, d1, #4
    vceq.u8 d29, d29, d30
    vand    d28, d1, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d17
    vmov    d17, d29

    vshr.u8 d29, d2, #4
    vceq.u8 d29, d29, d30
    vand    d28, d2, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d18
    vmov    d18, d29

    vshr.u8 d29, d4, #4
    vceq.u8 d29, d29, d30
    vand    d28, d4, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d19
    vmov    d19, d29

    vshr.u8 d29, d5, #4
    vceq.u8 d29, d29, d30
    vand    d28, d5, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d20
    vmov    d20, d29

    vshr.u8 d29, d6, #4
    vceq.u8 d29, d29, d30
    vand    d28, d6, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d21
    vmov    d21, d29

    add     r12, #1
    cmp     r12, #16
    bne     .Ls2l_scan
    sub     r3, r3, #256

    FORMULA8 d16, d19, d16
    FORMULA8 d17, d20, d17
    FORMULA8 d18, d21, d18
    FORMULA8 d22, d23, d19

    @ Scan L2S LUT for 3 results. Accumulators d24-d26.
    vmov.i8 q12, #0
    vmov.i8 d26, #0
    mov     r3, r1
    mov     r12, #0
.Ll2s_scan:
    vld1.8  {d14, d15}, [r3]!
    vdup.8  d30, r12
    vshr.u8 d29, d16, #4
    vceq.u8 d29, d29, d30
    vand    d28, d16, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d24
    vmov    d24, d29
    vshr.u8 d29, d17, #4
    vceq.u8 d29, d29, d30
    vand    d28, d17, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d25
    vmov    d25, d29
    vshr.u8 d29, d18, #4
    vceq.u8 d29, d29, d30
    vand    d28, d18, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, d26
    vmov    d26, d29
    add     r12, #1
    cmp     r12, #16
    bne     .Ll2s_scan
    sub     r3, r3, #256

    vmov    d27, d19
    vst4.8  {d24, d25, d26, d27}, [r6]!
    sub     r14, r14, #32
    b       .Llinear_vec

.Llinear_tail:
    mov     r12, r14, lsr #2
    cmp     r12, #0
    beq     .Lnext_row
    vldr    s8, [sp, #0]
    vldr    s9, [sp, #4]
    vldr    s10, [sp, #8]
    vldr    s11, [sp, #12]
    veor    d6, d6, d6
    movw    r7, #0x0000
    movt    r7, #0x437f
    vmov    s14, r7
    vmov    s15, r7
.Llinear_tail_pixel:
    ldr     r2, [r4], #4
    ldr     r3, [r5], #4
    mov     r14, #0
    CHANNEL_L r14, r2, r3, 0, r7, r0, r1
    CHANNEL_L r14, r2, r3, 8, r7, r0, r1
    CHANNEL_L r14, r2, r3, 16, r7, r0, r1
    CHANNEL    r14, r2, r3, 24, r7
    str     r14, [r6], #4
    subs    r12, r12, #1
    bne     .Llinear_tail_pixel

.Lnext_row:
    mov     r14, r8, lsl #2
    sub     r12, r10, r14
    add     r4, r4, r12
    add     r5, r5, r12
    add     r6, r6, r12
    subs    r11, r11, #1
    bne     .Lrow

    add     sp, sp, #16
    vpop    {d8-d15}
    pop     {r4-r11, pc}
