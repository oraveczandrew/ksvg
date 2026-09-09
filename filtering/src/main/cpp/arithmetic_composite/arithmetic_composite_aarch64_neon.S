/*
 * Copyright 2026 András Oravecz
 *
 * AArch64 / NEON implementation of ArithmeticComposite.
 *
 * Signature:
 *   void applyArithmeticNeon(
 *       const jint* src1, const jint* src2, jint* dst,
 *       jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *       jfloat k1, jfloat k2, jfloat k3, jfloat k4,
 *       jboolean useLinear,
 *       const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * AAPCS64:
 *   x0..x7 = integer/pointer arguments 0..7
 *   v0..v3 = k1..k4
 *   [sp]    = useLinear
 *   [sp+8]  = srgbToLinear
 *   [sp+16] = linearToSrgb
 *
 * The vector path processes 8 pixels per iteration.  BGRA input is
 * deinterleaved with LD4.  Linear mode uses the caller-provided exact 256-byte
 * LUTs; the lookup uses four TBL4 groups (64 bytes each), selected by the top
 * two index bits.  This avoids the 16-row scalar-style selection used by the
 * old x86 implementation while preserving exact LUT semantics.
 */

#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x, y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x, y) .type x, y
#define SIZE(x) .size x, .-x
#endif

/*
 * Lookup 8 bytes in a 256-byte table resident in v16..v31.
 * Tables are grouped as four 64-byte TBL4 banks:
 *   v16..v19 = bytes 0..63
 *   v20..v23 = bytes 64..127
 *   v24..v27 = bytes 128..191
 *   v28..v31 = bytes 192..255
 *
 * Input:  V4.8B
 * Output: V14.8B or V15.8B, selected by caller.
 * Clobbers V0..V3, V5..V7, V12..V14.
 */
.macro LUT8_14
    and     v5.8b, v4.8b, v7.8b
    ushr    v6.8b, v4.8b, #6

    tbl     v0.8b, {v16.16b-v19.16b}, v5.8b
    tbl     v1.8b, {v20.16b-v23.16b}, v5.8b
    tbl     v2.8b, {v24.16b-v27.16b}, v5.8b
    tbl     v3.8b, {v28.16b-v31.16b}, v5.8b

    movi    v12.8b, #0
    movi    v13.8b, #1
    movi    v14.8b, #2
    cmeq    v12.8b, v6.8b, v12.8b
    cmeq    v13.8b, v6.8b, v13.8b
    cmeq    v14.8b, v6.8b, v14.8b
    bsl     v14.8b, v2.8b, v3.8b
    bsl     v13.8b, v1.8b, v14.8b
    bsl     v14.8b, v0.8b, v13.8b
.endm

.macro LUT8_15
    and     v5.8b, v4.8b, v7.8b
    ushr    v6.8b, v4.8b, #6
    tbl     v0.8b, {v16.16b-v19.16b}, v5.8b
    tbl     v1.8b, {v20.16b-v23.16b}, v5.8b
    tbl     v2.8b, {v24.16b-v27.16b}, v5.8b
    tbl     v3.8b, {v28.16b-v31.16b}, v5.8b
    movi    v12.8b, #0
    movi    v13.8b, #1
    movi    v14.8b, #2
    cmeq    v12.8b, v6.8b, v12.8b
    cmeq    v13.8b, v6.8b, v13.8b
    cmeq    v14.8b, v6.8b, v14.8b
    bsl     v14.8b, v2.8b, v3.8b
    bsl     v13.8b, v1.8b, v14.8b
    bsl     v15.8b, v0.8b, v13.8b
.endm

/*
 * Arithmetic formula for two 8-byte uint8 vectors.
 *
 * Inputs:
 *   V14.8B, V15.8B
 * Constants:
 *   V8  = k1 / 255
 *   V9  = k2
 *   V10 = k3
 *   V11 = k4 * 255 + 0.5
 *
 * Output:
 *   V6.8B
 *
 * Uses separate MUL/ADD operations to match the existing x86 formula's
 * non-FMA ordering.
 */
.macro FORMULA8
    uxtl    v0.8h, v14.8b
    uxtl    v1.8h, v15.8b
    uxtl    v2.4s, v0.4h
    uxtl2   v3.4s, v0.8h
    uxtl    v4.4s, v1.4h
    uxtl2   v5.4s, v1.8h

    ucvtf   v2.4s, v2.4s
    ucvtf   v3.4s, v3.4s
    ucvtf   v4.4s, v4.4s
    ucvtf   v5.4s, v5.4s

    /* low 4 pixels */
    fmul    v6.4s, v2.4s, v4.4s
    fmul    v6.4s, v6.4s, v8.4s
    fmul    v7.4s, v2.4s, v9.4s
    fadd    v6.4s, v6.4s, v7.4s
    fmul    v7.4s, v4.4s, v10.4s
    fadd    v6.4s, v6.4s, v7.4s
    fadd    v6.4s, v6.4s, v11.4s

    /* high 4 pixels */
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
    sqxtun  v6.8b, v6.8h
.endm

.text
.p2align 5
.globl SYM(applyArithmeticNeon)
TYPE(SYM(applyArithmeticNeon), @function)
SYM(applyArithmeticNeon):
    stp     x29, x30, [sp, #-160]!
    mov     x29, sp

    /* Preserve AAPCS64 callee-saved GPRs used as channel temporaries. */
    stp     x19, x20, [sp, #80]
    stp     x21, x22, [sp, #96]
    stp     x23, x24, [sp, #112]
    stp     x25, x26, [sp, #128]

    /* Save raw coefficients k1..k4 in the spare frame slots.  The vector
       loop clobbers v0..v3 with pixel data, so the scalar tails must reload
       the coefficients from here instead of from s0..s3. */
    stp     s0, s1, [sp, #144]
    stp     s2, s3, [sp, #152]

    /* Preserve AAPCS64 callee-saved v8..v15 (lower 64 bits). */
    stp     d8, d9, [sp, #16]
    stp     d10, d11, [sp, #32]
    stp     d12, d13, [sp, #48]
    stp     d14, d15, [sp, #64]

    /* Establish clipped starting pointers. */
    smaddl  x16, w5, w3, x4          /* clipTop * width + clipLeft */
    add     x9, x0, x16, lsl #2      /* src1 cursor */
    add     x10, x1, x16, lsl #2     /* src2 cursor */
    add     x11, x2, x16, lsl #2     /* dst cursor */

    lsl     x12, x3, #2              /* row stride */
    sub     w13, w6, w4              /* clipped width in pixels */
    lsl     x13, x13, #2             /* clipped span in bytes */
    sub     w14, w7, w5              /* row count */

    ldr     w15, [sp, #160]          /* useLinear */
    ldr     x0, [sp, #168]          /* srgbToLinear */
    ldr     x1, [sp, #176]          /* linearToSrgb */

    cbnz    w15, .Llinear

/* -------------------------------------------------------------------------
 * Non-linear path.  No LUTs are resident, so v16..v31 are available for
 * temporaries.  Source channels are first staged in x16..x23, allowing the
 * formula to freely use v0..v15.
 * ------------------------------------------------------------------------- */
.Lnonlinear:
    /* Scalar/vector constants.  Keep original k1..k4 in v0..v3 intact. */
    mov     w19, #0x8081
    movk    w19, #0x3b80, lsl #16   /* float 1/255 */
    fmov    s8, w19
    dup     v8.4s, v8.s[0]
    fmul    v8.4s, v8.4s, v0.s[0]    /* k1 / 255 */
    dup     v9.4s, v1.s[0]           /* k2 */
    dup     v10.4s, v2.s[0]          /* k3 */

    mov     w19, #0x0000
    movk    w19, #0x437f, lsl #16   /* 255.0 */
    fmov    s12, w19
    dup     v12.4s, v12.s[0]
    dup     v13.4s, v3.s[0]          /* k4 */
    fmul    v13.4s, v13.4s, v12.4s
    fmov    s14, #0.5
    dup     v14.4s, v14.s[0]
    fadd    v11.4s, v13.4s, v14.4s

    mov     w19, #0
    mov     w20, #255
    fmov    s14, wzr                 /* zero */
    fmov    s15, w20                 /* 255 bits are not float: fix below */
    mov     w20, #0x0000
    movk    w20, #0x437f, lsl #16
    fmov    s15, w20
    dup     v15.4s, v15.s[0]

    b       .Lrow_start_nonlin

.Lrow_nonlin:
    add     x9, x9, x12
    add     x10, x10, x12
    add     x11, x11, x12

.Lrow_start_nonlin:
    lsr     w17, w13, #2             /* clipped width in pixels (w13 is bytes) */
    lsr     w24, w17, #3             /* 8-pixel groups */
    and     w25, w17, #7

.Lnonlin_8:
    cbz     w24, .Lnonlin_row_done

    ld4     {v0.8b-v3.8b}, [x9], #32
    ld4     {v4.8b-v7.8b}, [x10], #32
    umov    x16, v0.d[0]
    umov    x17, v4.d[0]
    umov    x18, v1.d[0]
    umov    x19, v5.d[0]
    umov    x20, v2.d[0]
    umov    x21, v6.d[0]
    umov    x22, v3.d[0]
    umov    x23, v7.d[0]

    fmov    d14, x16
    fmov    d15, x17
    FORMULA8
    umov    x16, v6.d[0]
    fmov    d14, x18
    fmov    d15, x19
    FORMULA8
    umov    x18, v6.d[0]
    fmov    d14, x20
    fmov    d15, x21
    FORMULA8
    umov    x20, v6.d[0]
    fmov    d14, x22
    fmov    d15, x23
    FORMULA8
    umov    x22, v6.d[0]

    fmov    d0, x16
    fmov    d1, x18
    fmov    d2, x20
    fmov    d3, x22
    zip1    v4.8b, v0.8b, v1.8b
    zip2    v5.8b, v0.8b, v1.8b
    zip1    v6.8b, v2.8b, v3.8b
    zip2    v7.8b, v2.8b, v3.8b
    ins     v4.d[1], v5.d[0]
    ins     v6.d[1], v7.d[0]
    zip1    v0.8h, v4.8h, v6.8h
    zip2    v1.8h, v4.8h, v6.8h
    st1     {v0.16b, v1.16b}, [x11], #32

    subs    w24, w24, #1
    b.ne    .Lnonlin_8

.Lnonlin_row_done:
    /* Exact scalar tail, 0..7 pixels. */
    cbz     w25, .Lrow_nonlin_next
    b       .Ltail_scalar_nonlin

.Lrow_nonlin_next:
    subs    w14, w14, #1
    b.eq    .Ldone
    sub     x9, x9, x13
    sub     x10, x10, x13
    sub     x11, x11, x13
    b       .Lrow_nonlin

/* -------------------------------------------------------------------------
 * Linear path.  Exact caller-provided 256-byte LUTs are used.  The LUT set
 * occupies v16..v31; all channel values are staged through GPRs so the lookup
 * scratch space never destroys a future channel.
 * ------------------------------------------------------------------------- */
.Llinear:
    mov     w19, #0x8081
    movk    w19, #0x3b80, lsl #16
    fmov    s8, w19
    dup     v8.4s, v8.s[0]
    fmul    v8.4s, v8.4s, v0.s[0]    /* k1 / 255 */
    dup     v9.4s, v1.s[0]
    dup     v10.4s, v2.s[0]

    mov     w19, #0x0000
    movk    w19, #0x437f, lsl #16
    fmov    s12, w19
    dup     v12.4s, v12.s[0]
    dup     v13.4s, v3.s[0]
    fmul    v13.4s, v13.4s, v12.4s
    fmov    s14, #0.5
    dup     v14.4s, v14.s[0]
    fadd    v11.4s, v13.4s, v14.4s
    movi    v7.8b, #63

    /* Load S2L table into four 64-byte TBL4 banks. */
    mov     x8, x0
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]

    b       .Lrow_start_linear

.Lrow_linear:
    add     x9, x9, x12
    add     x10, x10, x12
    add     x11, x11, x12

.Lrow_start_linear:
    lsr     w17, w13, #2             /* clipped width in pixels (w13 is bytes) */
    lsr     w24, w17, #3             /* 8-pixel groups */
    and     w25, w17, #7

.Llinear_8:
    cbz     w24, .Llinear_tail

    ld4     {v0.8b-v3.8b}, [x9], #32
    ld4     {v4.8b-v7.8b}, [x10], #32
    umov    x16, v0.d[0]
    umov    x17, v4.d[0]
    umov    x18, v1.d[0]
    umov    x19, v5.d[0]
    umov    x20, v2.d[0]
    umov    x21, v6.d[0]
    umov    x22, v3.d[0]
    umov    x23, v7.d[0]

    /* B: S2L + arithmetic. */
    fmov    d4, x16
    fmov    d5, x17
    movi    v7.8b, #63
    LUT8_14
    mov     v14.8b, v14.8b
    /* second lookup uses original source2 in x17 */
    fmov    d4, x17
    LUT8_15
    FORMULA8
    umov    x16, v6.d[0]

    /* G */
    fmov    d4, x18
    movi    v7.8b, #63
    LUT8_14
    fmov    d4, x19
    LUT8_15
    FORMULA8
    umov    x18, v6.d[0]

    /* R */
    fmov    d4, x20
    movi    v7.8b, #63
    LUT8_14
    fmov    d4, x21
    LUT8_15
    FORMULA8
    umov    x20, v6.d[0]

    /* A: encoded domain, no S2L/L2S. */
    fmov    d4, x22
    fmov    d5, x23
    FORMULA8
    umov    x22, v6.d[0]

    /* Switch to L2S table. */
    mov     x8, x1
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]

    fmov    d4, x16
    movi    v7.8b, #63
    LUT8_14
    umov    x16, v14.d[0]
    fmov    d4, x18
    LUT8_15
    umov    x18, v15.d[0]
    fmov    d4, x20
    movi    v7.8b, #63
    LUT8_14
    umov    x20, v14.d[0]

    /* Pack BGRA. */
    fmov    d0, x16
    fmov    d1, x18
    fmov    d2, x20
    fmov    d3, x22
    zip1    v4.8b, v0.8b, v1.8b
    zip2    v5.8b, v0.8b, v1.8b
    zip1    v6.8b, v2.8b, v3.8b
    zip2    v7.8b, v2.8b, v3.8b
    ins     v4.d[1], v5.d[0]
    ins     v6.d[1], v7.d[0]
    zip1    v0.8h, v4.8h, v6.8h
    zip2    v1.8h, v4.8h, v6.8h
    st1     {v0.16b, v1.16b}, [x11], #32

    /* Re-load S2L table for the next block. */
    mov     x8, x0
    ld1     {v16.16b-v19.16b}, [x8], #64
    ld1     {v20.16b-v23.16b}, [x8], #64
    ld1     {v24.16b-v27.16b}, [x8], #64
    ld1     {v28.16b-v31.16b}, [x8]

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
    b       .Lrow_start_linear

/* -------------------------------------------------------------------------
 * Scalar tails.
 * ------------------------------------------------------------------------- */
.macro SCALAR_FORMULA a, b
    /* s4=a, s5=b already contain 0..255. */
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
    /* Reload raw coefficients k1..k4 saved in the prologue; the vector loop
       overwrote v0..v3 with pixel data. */
    ldr     s0, [sp, #144]
    ldr     s1, [sp, #148]
    ldr     s2, [sp, #152]
    ldr     s3, [sp, #156]

    /* Recompute scalar constants: s8=k1/255, s9=k2, s10=k3,
       s11=k4*255+0.5, s15=255. */
    mov     w20, #0x8081
    movk    w20, #0x3b80, lsl #16
    fmov    s8, w20
    fmul    s8, s8, s0               /* k1 / 255 */
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
    and     w20, w20, #255

    ubfx    w18, w16, #8, #8
    ubfx    w19, w17, #8, #8
    SCALAR_FORMULA 18, 19
    mov w21, w24
    and     w21, w21, #255

    ubfx    w18, w16, #16, #8
    ubfx    w19, w17, #16, #8
    SCALAR_FORMULA 18, 19
    mov w22, w24
    and     w22, w22, #255

    ubfx    w18, w16, #24, #8
    ubfx    w19, w17, #24, #8
    SCALAR_FORMULA 18, 19
    mov w23, w24
    and     w23, w23, #255

    bfi     w20, w21, #8, #8
    bfi     w20, w22, #16, #8
    bfi     w20, w23, #24, #8
    str     w20, [x11]

    add     x9, x9, #4
    add     x10, x10, #4
    add     x11, x11, #4
    subs    w25, w25, #1
    b.ne    .Ltail_nonlin_loop
    b       .Lrow_nonlin_next

.Ltail_scalar_linear:
    /* Exact scalar tail using the real caller-provided 256-byte LUTs.
       Reload k1..k4 saved in the prologue; the vector loop clobbers v0..v3. */
    ldr     s0, [sp, #144]
    ldr     s1, [sp, #148]
    ldr     s2, [sp, #152]
    ldr     s3, [sp, #156]
    mov     w20, #0x8081
    movk    w20, #0x3b80, lsl #16
    fmov    s8, w20
    fmul    s8, s8, s0               /* k1 / 255 */
    mov     w20, #0x0000
    movk    w20, #0x437f, lsl #16
    fmov    s15, w20
    fmov    s9, s1
    fmov    s10, s2
    fmul    s11, s3, s15
    fmov    s13, #0.5
    fadd    s11, s11, s13
    fmov    s14, wzr

.Ltail_linear_loop:
    ldr     w16, [x9]
    ldr     w17, [x10]

    ubfx    w18, w16, #0, #8
    ubfx    w19, w17, #0, #8
    ldrb    w18, [x0, w18, uxtw]
    ldrb    w19, [x0, w19, uxtw]
    SCALAR_FORMULA 18, 19
    mov w20, w24
    ldrb    w20, [x1, w20, uxtw]

    ubfx    w18, w16, #8, #8
    ubfx    w19, w17, #8, #8
    ldrb    w18, [x0, w18, uxtw]
    ldrb    w19, [x0, w19, uxtw]
    SCALAR_FORMULA 18, 19
    mov w21, w24
    ldrb    w21, [x1, w21, uxtw]

    ubfx    w18, w16, #16, #8
    ubfx    w19, w17, #16, #8
    ldrb    w18, [x0, w18, uxtw]
    ldrb    w19, [x0, w19, uxtw]
    SCALAR_FORMULA 18, 19
    mov w22, w24
    ldrb    w22, [x1, w22, uxtw]

    ubfx    w18, w16, #24, #8
    ubfx    w19, w17, #24, #8
    SCALAR_FORMULA 18, 19
    mov w23, w24

    bfi     w20, w21, #8, #8
    bfi     w20, w22, #16, #8
    bfi     w20, w23, #24, #8
    str     w20, [x11]

    add     x9, x9, #4
    add     x10, x10, #4
    add     x11, x11, #4
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
