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

/*
 * AArch64 / NEON implementation of ArithmeticComposite.
 */

#include "asm_macros.S"

/*
 * Lookup 8 bytes in a 256-byte table resident in v16..v31.
 * Input:  vIn (8b)
 * Output: vOut (8b)
 * Clobbers v4, v5, v6, v7, v14, v15.
 * Requires v12 to be mask #63.
 */
.macro LUT256 vIn, vOut
    and     v15.8b, \vIn\().8b, v12.8b   /* v12 = 63 */
    ushr    v14.8b, \vIn\().8b, #6        /* bank index 0..3 */

    tbl     v4.8b, {v16.16b-v19.16b}, v15.8b
    tbl     v5.8b, {v20.16b-v23.16b}, v15.8b
    tbl     v6.8b, {v24.16b-v27.16b}, v15.8b
    tbl     v7.8b, {v28.16b-v31.16b}, v15.8b

    movi    v15.8b, #2
    cmeq    v15.8b, v14.8b, v15.8b
    bsl     v15.8b, v6.8b, v7.8b     /* (bank==2)? v6 : v7 */

    movi    v7.8b, #1
    cmeq    v7.8b, v14.8b, v7.8b
    bsl     v7.8b, v5.8b, v15.8b     /* (bank==1)? v5 : v15 */

    movi    v15.8b, #0
    cmeq    v15.8b, v14.8b, v15.8b
    bsl     v15.8b, v4.8b, v7.8b      /* (bank==0)? v4 : v7 */

    mov     \vOut\().8b, v15.8b
.endm

/*
 * FORMULA8: exact SIMD arithmetic path for eight uint8 lanes.
 * Constants: v8=k1/255, v9=k2, v10=k3, v11=k4*255+0.5
 * Clobbers v0-v7.
 */
.macro FORMULA8 vA, vB, vOut
    uxtl    v0.8h, \vA\().8b
    uxtl    v1.8h, \vB\().8b
    uxtl    v2.4s, v0.4h
    uxtl2   v3.4s, v0.8h
    uxtl    v4.4s, v1.4h
    uxtl2   v5.4s, v1.8h
    ucvtf   v2.4s, v2.4s
    ucvtf   v3.4s, v3.4s
    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s
    fmul    v6.4s, v2.4s, v4.4s
    fmul    v6.4s, v6.4s, v8.4s
    fmul    v7.4s, v2.4s, v9.4s
    fadd    v6.4s, v6.4s, v7.4s
    fmul    v7.4s, v4.4s, v10.4s
    fadd    v6.4s, v6.4s, v7.4s
    fadd    v6.4s, v6.4s, v11.4s
    fmul    v7.4s, v3.4s, v5.4s
    fmul    v7.4s, v7.4s, v8.4s
    fmul    v0.4s, v3.4s, v9.4s
    fadd    v7.4s, v7.4s, v0.4s
    fmul    v0.4s, v5.4s, v10.4s
    fadd    v7.4s, v7.4s, v0.4s
    fadd    v7.4s, v7.4s, v11.4s
    fcvtzs  v6.4s, v6.4s
    fcvtzs  v7.4s, v7.4s
    sqxtn   v6.4h, v6.4s
    sqxtn2  v6.8h, v7.4s
    sqxtun  \vOut\().8b, v6.8h
.endm

.text
.p2align 5
/*
 * void applyArithmeticNeon(
 *     const jint* src1, const jint* src2, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     jfloat k1, jfloat k2, jfloat k3, jfloat k4,
 *     jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * AArch64 ABI:
 *   x0 = src1, x1 = src2, x2 = dst
 *   w3 = width, w4 = clipLeft, w5 = clipTop, w6 = clipRight, w7 = clipBottom
 *   s0 = k1, s1 = k2, s2 = k3, s3 = k4
 *   stack: useLinear (w15), srgbToLinear (x0), linearToSrgb (x1)
 */
.globl SYM(applyArithmeticNeon)
TYPE(SYM(applyArithmeticNeon), @function)
SYM(applyArithmeticNeon):
    stp     x29, x30, [sp, #-160]!
    mov     x29, sp
    stp     x19, x20, [sp, #80]
    stp     x21, x22, [sp, #96]
    stp     x23, x24, [sp, #112]
    stp     x25, x26, [sp, #128]
    stp     s0, s1, [sp, #144]
    stp     s2, s3, [sp, #152]
    stp     d8, d9, [sp, #16]
    stp     d10, d11, [sp, #32]
    stp     d12, d13, [sp, #48]
    stp     d14, d15, [sp, #64]

    smaddl  x16, w5, w3, x4
    add     x9, x0, x16, lsl #2
    add     x10, x1, x16, lsl #2
    add     x11, x2, x16, lsl #2
    lsl     x12, x3, #2
    sub     w13, w6, w4
    lsl     x13, x13, #2
    sub     w14, w7, w5
    ldr     w15, [sp, #160]
    ldr     x0, [sp, #168]
    ldr     x1, [sp, #176]

    /* Constants in v8-v11 */
    mov     w19, #0x8081
    movk    w19, #0x3b80, lsl #16
    fmov    s8, w19
    ldr     s0, [sp, #144]
    fmul    s8, s8, s0
    dup     v8.4s, v8.s[0]
    ldr     s1, [sp, #148]
    fmov    s9, s1
    dup     v9.4s, v9.s[0]
    ldr     s2, [sp, #152]
    fmov    s10, s2
    dup     v10.4s, v10.s[0]
    ldr     s3, [sp, #156]
    mov     w19, #0x0000
    movk    w19, #0x437f, lsl #16
    fmov    s11, w19
    fmul    s11, s11, s3
    fmov    s12, #0.5
    fadd    s11, s11, s12
    dup     v11.4s, v11.s[0]

    movi    v12.8b, #63

    cbnz    w15, .Llinear

.Lnonlinear:
    fmov    s14, wzr
    mov     w19, #0x0000
    movk    w19, #0x437f, lsl #16
    fmov    s15, w19
    dup     v15.4s, v15.s[0]
    b       .Lrow_start_nonlin

.Lrow_nonlin:
    add     x9, x9, x12
    add     x10, x10, x12
    add     x11, x11, x12

.Lrow_start_nonlin:
    lsr     w17, w13, #2
    lsr     w24, w17, #3
    and     w25, w17, #7

.Lnonlin_8:
    cbz     w24, .Lnonlin_row_done
    ld4     {v0.8b-v3.8b}, [x9], #32
    ld4     {v4.8b-v7.8b}, [x10], #32

    /* Staging in v16-v23 */
    mov     v16.8b, v0.8b
    mov     v17.8b, v1.8b
    mov     v18.8b, v2.8b
    mov     v19.8b, v3.8b
    mov     v20.8b, v4.8b
    mov     v21.8b, v5.8b
    mov     v22.8b, v6.8b
    mov     v23.8b, v7.8b

    FORMULA8 v16, v20, v24
    FORMULA8 v17, v21, v25
    FORMULA8 v18, v22, v26
    FORMULA8 v19, v23, v27

    st4     {v24.8b-v27.8b}, [x11], #32
    subs    w24, w24, #1
    b.ne    .Lnonlin_8

.Lnonlin_row_done:
    cbz     w25, .Lrow_nonlin_next
    b       .Ltail_scalar_nonlin

.Lrow_nonlin_next:
    subs    w14, w14, #1
    b.eq    .Ldone
    sub     x9, x9, x13
    sub     x10, x10, x13
    sub     x11, x11, x13
    b       .Lrow_nonlin

.Llinear:
    b       .Lrow_start_linear

.Lrow_linear:
    add     x9, x9, x12
    add     x10, x10, x12
    add     x11, x11, x12

.Lrow_start_linear:
    lsr     w17, w13, #2
    lsr     w24, w17, #3
    and     w25, w17, #7

.Llinear_8:
    cbz     w24, .Llinear_tail
    ld4     {v0.8b-v3.8b}, [x9], #32
    ld4     {v4.8b-v7.8b}, [x10], #32

    /* Save A and B to GPRs because LUT256 and FORMULA8 clobber SIMD regs */
    umov    x16, v0.d[0]    /* A_R */
    umov    x17, v4.d[0]    /* B_R */
    umov    x18, v1.d[0]    /* A_G */
    umov    x19, v5.d[0]    /* B_G */
    umov    x20, v2.d[0]    /* A_B */
    umov    x21, v6.d[0]    /* B_B */
    umov    x22, v3.d[0]    /* A_A */
    umov    x23, v7.d[0]    /* B_A */

    mov     x8, x0          /* srgbToLinear */
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]

    /* Lookup Linear A */
    fmov    d0, x16
    LUT256  v0, v0
    umov    x16, v0.d[0]

    fmov    d1, x18
    LUT256  v1, v1
    umov    x18, v1.d[0]

    fmov    d2, x20
    LUT256  v2, v2
    umov    x20, v2.d[0]

    /* Lookup Linear B */
    fmov    d4, x17
    LUT256  v4, v4
    umov    x17, v4.d[0]

    fmov    d5, x19
    LUT256  v5, v5
    umov    x19, v5.d[0]

    fmov    d6, x21
    LUT256  v6, v6
    umov    x21, v6.d[0]

    /* Load Linear to Srgb LUT */
    mov     x8, x1
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]

    /* R channel */
    fmov    d14, x16
    fmov    d15, x17
    FORMULA8 v14, v15, v0
    LUT256  v0, v0
    umov    x16, v0.d[0]

    /* G channel */
    fmov    d14, x18
    fmov    d15, x19
    FORMULA8 v14, v15, v1
    LUT256  v1, v1
    umov    x18, v1.d[0]

    /* B channel */
    fmov    d14, x20
    fmov    d15, x21
    FORMULA8 v14, v15, v2
    LUT256  v2, v2
    umov    x20, v2.d[0]

    /* Alpha channel */
    fmov    d14, x22
    fmov    d15, x23
    FORMULA8 v14, v15, v3
    umov    x22, v3.d[0]

    /* Final assembly */
    fmov    d0, x16
    fmov    d1, x18
    fmov    d2, x20
    fmov    d3, x22

    st4     {v0.8b-v3.8b}, [x11], #32
    subs    w24, w24, #1
    b.ne    .Llinear_8

.Llinear_tail:
    cbz     w25, .Lrow_linear_next
    b       .Ltail_scalar_linear

.Lrow_linear_next:
    subs    w14, w14, #1
    b.eq    .Ldone
    sub     x9, x9, x13
    sub     x10, x10, x13
    sub     x11, x11, x13
    b       .Lrow_linear

.macro SCALAR_FORMULA a, b
    ucvtf   s4, w\a
    ucvtf   s5, w\b
    fmul    s6, s4, s5
    fmul    s6, s6, s8
    fmul    s7, s4, s9
    fadd    s6, s6, s7
    fmul    s7, s5, s10
    fadd    s6, s6, s7
    fadd    s6, s6, s11
    fmax    s6, s6, s14
    fmin    s6, s6, s15
    fcvtzs  w24, s6
.endm

.Ltail_scalar_nonlin:
    ldr     s0, [sp, #144]
    ldr     s1, [sp, #148]
    ldr     s2, [sp, #152]
    ldr     s3, [sp, #156]
    mov     w20, #0x8081
    movk    w20, #0x3b80, lsl #16
    fmov    s8, w20
    fmul    s8, s8, s0
    mov     w20, #0x0000
    movk    w20, #0x437f, lsl #16
    fmov    s15, w20
    fmul    s11, s3, s15
    fmov    s13, #0.5
    fadd    s11, s11, s13
    fmov    s14, wzr
    fmov    s9, s1
    fmov    s10, s2
.Ltail_nonlin_loop:
    ldr     w16, [x9]
    ldr     w17, [x10]
    ubfx    w18, w16, #0, #8
    ubfx    w19, w17, #0, #8
    SCALAR_FORMULA 18, 19
    mov w20, w24
    ubfx    w18, w16, #8, #8
    ubfx    w19, w17, #8, #8
    SCALAR_FORMULA 18, 19
    mov w21, w24
    ubfx    w18, w16, #16, #8
    ubfx    w19, w17, #16, #8
    SCALAR_FORMULA 18, 19
    mov w22, w24
    ubfx    w18, w16, #24, #8
    ubfx    w19, w17, #24, #8
    SCALAR_FORMULA 18, 19
    mov w23, w24
    bfi     w20, w21, #8, #8
    bfi     w20, w22, #16, #8
    bfi     w20, w23, #24, #8
    str     w20, [x11], #4
    add     x9, x9, #4
    add     x10, x10, #4
    subs    w25, w25, #1
    b.ne    .Ltail_nonlin_loop
    b       .Lrow_nonlin_next

.Ltail_scalar_linear:
    ldr     s0, [sp, #144]
    ldr     s1, [sp, #148]
    ldr     s2, [sp, #152]
    ldr     s3, [sp, #156]
    mov     w20, #0x8081
    movk    w20, #0x3b80, lsl #16
    fmov    s8, w20
    fmul    s8, s8, s0
    mov     w20, #0x0000
    movk    w20, #0x437f, lsl #16
    fmov    s15, w20
    fmul    s11, s3, s15
    fmov    s13, #0.5
    fadd    s11, s11, s13
    fmov    s14, wzr
    fmov    s9, s1
    fmov    s10, s2
.Ltail_linear_loop:
    ldr     w16, [x9]
    ldr     w17, [x10]
    ubfx    w18, w16, #0, #8
    ubfx    w19, w17, #0, #8
    ldrb    w18, [x0, w18, uxtw]
    ldrb    w19, [x0, w19, uxtw]
    SCALAR_FORMULA 18, 19
    ldrb    w20, [x1, w24, uxtw]
    ubfx    w18, w16, #8, #8
    ubfx    w19, w17, #8, #8
    ldrb    w18, [x0, w18, uxtw]
    ldrb    w19, [x0, w19, uxtw]
    SCALAR_FORMULA 18, 19
    ldrb    w21, [x1, w24, uxtw]
    ubfx    w18, w16, #16, #8
    ubfx    w19, w17, #16, #8
    ldrb    w18, [x0, w18, uxtw]
    ldrb    w19, [x0, w19, uxtw]
    SCALAR_FORMULA 18, 19
    ldrb    w22, [x1, w24, uxtw]
    ubfx    w18, w16, #24, #8
    ubfx    w19, w17, #24, #8
    SCALAR_FORMULA 18, 19
    mov w23, w24
    bfi     w20, w21, #8, #8
    bfi     w20, w22, #16, #8
    bfi     w20, w23, #24, #8
    str     w20, [x11], #4
    add     x9, x9, #4
    add     x10, x10, #4
    subs    w25, w25, #1
    b.ne    .Ltail_linear_loop
    b       .Lrow_linear_next

.Ldone:
    ldp     d14, d15, [sp, #64]
    ldp     d12, d13, [sp, #48]
    ldp     d10, d11, [sp, #32]
    ldp     d8, d9, [sp, #16]
    ldp     x25, x26, [sp, #128]
    ldp     x23, x24, [sp, #112]
    ldp     x21, x22, [sp, #96]
    ldp     x19, x20, [sp, #80]
    ldp     x29, x30, [sp], #160
    ret

SIZE(SYM(applyArithmeticNeon))
