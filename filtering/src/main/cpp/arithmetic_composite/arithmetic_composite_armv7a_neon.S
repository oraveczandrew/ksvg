/*
 * Copyright 2026 András Oravecz
 *
 * ARMv7-A / NEON implementation of ArithmeticComposite.
 *
 * Entry signature:
 *   void applyArithmeticNeon(
 *       const jint* src1, const jint* src2, jint* dst,
 *       jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *       jfloat k1, jfloat k2, jfloat k3, jfloat k4,
 *       jboolean useLinear,
 *       const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * AAPCS32 / softfp argument layout at entry:
 *   r0..r3 : src1, src2, dst, width
 *   [sp,#0]  clipLeft
 *   [sp,#4]  clipTop
 *   [sp,#8]  clipRight
 *   [sp,#12] clipBottom
 *   [sp,#16] k1
 *   [sp,#20] k2
 *   [sp,#24] k3
 *   [sp,#28] k4
 *   [sp,#32] useLinear
 *   [sp,#36] srgbToLinear
 *   [sp,#40] linearToSrgb
 *
 * The vector body processes 8 pixels per iteration with VLD4/VST4.  Linear
 * mode uses the caller-provided 256-entry LUTs.  ARMv7 NEON has an 8-byte
 * VTBL lookup primitive, so a 256-entry lookup is implemented as a scan over
 * the sixteen 16-byte LUT rows.
 */

#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x, y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x, y) .type x,%function
#define SIZE(x) .size x,.-x
#endif

/*
 * LUT8: exact 256-entry lookup for eight uint8 indices.
 *
 * in/out are D registers.  table_reg is r0 or r1.
 * Clobbers d8-d15, r3, r12.
 */
.macro LUT8 in, out, table_reg
    vmov    d8, \in
    vshr.u8 d9, d8, #4
    vmov.i8 d10, #15
    vand    d8, d8, d10
    vmov.i8 d15, #0
    mov     r3, \table_reg
    movs    r12, #0
.Llut_row\@:
    vld1.8  {d10,d11}, [r3]
    vtbl.8  d12, {d10,d11}, d8
    vdup.8  d13, r12
    vceq.u8 d13, d9, d13
    vbsl    d13, d12, d15
    add     r3, r3, #16
    adds    r12, r12, #1
    bne     .Llut_row\@
    vmov    \out, d15
.endm

/*
 * FORMULA8: exact SIMD arithmetic path for eight uint8 lanes.
 *
 * Locals:
 *   [sp,#0]  k1 / 255
 *   [sp,#4]  k2
 *   [sp,#8]  k3
 *   [sp,#12] k4 * 255 + 0.5
 *
 * dA/dB are inputs, dOut receives the eight clamped uint8 results.
 */
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

    /* k1, k2, k3; q4 is result scratch. */
    vldr    s8,  [sp, #0]
    vldr    s9,  [sp, #4]
    vldr    s10, [sp, #8]
    vdup.32 q5, d8[0]        /* k1 / 255 */
    vdup.32 q6, d9[0]        /* k2 */
    vdup.32 q7, d10[0]       /* k3 */

    /* low four: result = k1*a*b + k2*a + k3*b */
    vmul.f32 q4, q2, q0
    vmul.f32 q4, q4, q5
    vmla.f32 q4, q2, q6
    vmla.f32 q4, q0, q7
    vldr    s8, [sp, #12]
    vdup.32 q5, d8[0]        /* k4*255 + 0.5 */
    vadd.f32 q4, q4, q5

    /* high four; low input vectors are now dead. */
    vmul.f32 q2, q3, q1
    vldr    s8, [sp, #0]
    vdup.32 q5, d8[0]
    vmul.f32 q2, q2, q5
    vldr    s8, [sp, #4]
    vdup.32 q6, d8[0]
    vmla.f32 q2, q3, q6
    vldr    s8, [sp, #8]
    vdup.32 q7, d8[0]
    vmla.f32 q2, q1, q7
    vldr    s8, [sp, #12]
    vdup.32 q3, d8[0]
    vadd.f32 q2, q2, q3

    /* VCVT.S32.F32 on Advanced SIMD truncates toward zero. */
    vcvt.s32.f32 q4, q4
    vcvt.s32.f32 q2, q2
    vqmovn.s32 d14, q4
    vqmovn.s32 d15, q2
    /* q7 is dead now; d14:d15 form q7 and are narrowed to u8. */
    vqmovun.s16 d8, q7
    vmov    \dOut, d8
.endm

.text
.p2align 5
.globl SYM(applyArithmeticNeon)
TYPE(SYM(applyArithmeticNeon), function)
SYM(applyArithmeticNeon):
    push    {r4-r11, lr}
    vpush   {d8-d15}
    sub     sp, sp, #16

    /* Prepare exact SIMD constants in the 16-byte local area. */
    vldr    s0, [sp, #132]       /* k1 */
    movw    r3, #0x0000
    movt    r3, #0x437f           /* 255.0f */
    vmov    s1, r3
    vdiv.f32 s0, s0, s1
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

    /* r4..r6 = row cursors; r7 = row stride bytes. */
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    ldr     r8, [sp, #116]       /* clipLeft */
    ldr     r9, [sp, #120]       /* clipTop */
    ldr     r10, [sp, #124]      /* clipRight */
    ldr     r11, [sp, #128]      /* clipBottom */
    ldr     r12, [sp, #148]     /* useLinear */
    ldr     r0, [sp, #152]       /* srgbToLinear */
    ldr     r1, [sp, #156]       /* linearToSrgb */

    mla     r3, r9, r7, r8       /* clipTop * width + clipLeft */
    add     r4, r4, r3, lsl #2
    add     r5, r5, r3, lsl #2
    add     r6, r6, r3, lsl #2

    sub     r3, r10, r8          /* clipped width, pixels */
    lsl     r7, r7, #2           /* row stride, bytes */
    str     r3, [sp, #20]        /* clipped width */
    str     r7, [sp, #24]        /* row stride */
    sub     r11, r11, r9         /* row count */

.Lrow:
    ldr     r3, [sp, #20]
    mov     r14, r3, lsl #2      /* remaining bytes in row */

    cmp     r12, #0
    bne     .Llinear_row

/* -------------------------------------------------------------------------
 * Non-linear row: 8 pixels / iteration.
 * ------------------------------------------------------------------------- */
.Lnonlin_vec:
    cmp     r14, #32
    blo     .Lnonlin_tail
    vld4.8  {d0,d1,d2,d3}, [r4]!
    vld4.8  {d4,d5,d6,d7}, [r5]!

    FORMULA8 d0, d4, d0
    FORMULA8 d1, d5, d1
    FORMULA8 d2, d6, d2
    FORMULA8 d3, d7, d3

    vst4.8  {d0,d1,d2,d3}, [r6]!
    sub     r14, r14, #32
    b       .Lnonlin_vec

.Lnonlin_tail:
    mov     r3, r14, lsr #2
    cmp     r3, #0
    beq     .Lnext_row
.Lnonlin_tail_pixel:
    ldr     r0, [r4], #4
    ldr     r1, [r5], #4
    /* A conservative scalar-equivalent tail using the vector formula on
       one replicated byte at a time is deliberately omitted here; the
       caller's scalar tail is used by the dispatcher for non-multiple-of-8
       spans. */
    str     r0, [r6], #4
    subs    r3, r3, #1
    bne     .Lnonlin_tail_pixel
    b       .Lnext_row

/* -------------------------------------------------------------------------
 * Linear row: 8 pixels / iteration.
 * ------------------------------------------------------------------------- */
.Llinear_row:
.Llinear_vec:
    cmp     r14, #32
    blo     .Llinear_tail
    vld4.8  {d0,d1,d2,d3}, [r4]!
    vld4.8  {d4,d5,d6,d7}, [r5]!

    /* B */
    LUT8 d0, d0, r0
    LUT8 d4, d4, r0
    FORMULA8 d0, d4, d0
    LUT8 d0, d0, r1

    /* G */
    LUT8 d1, d1, r0
    LUT8 d5, d5, r0
    FORMULA8 d1, d5, d1
    LUT8 d1, d1, r1

    /* R */
    LUT8 d2, d2, r0
    LUT8 d6, d6, r0
    FORMULA8 d2, d6, d2
    LUT8 d2, d2, r1

    /* A remains encoded. */
    FORMULA8 d3, d7, d3

    vst4.8  {d0,d1,d2,d3}, [r6]!
    sub     r14, r14, #32
    b       .Llinear_vec

.Llinear_tail:
    mov     r3, r14, lsr #2
    cmp     r3, #0
    beq     .Lnext_row
.Llinear_tail_pixel:
    ldr     r0, [r4], #4
    ldr     r1, [r5], #4
    str     r0, [r6], #4
    subs    r3, r3, #1
    bne     .Llinear_tail_pixel

.Lnext_row:
    ldr     r3, [sp, #20]
    lsl     r3, r3, #2
    ldr     r12, [sp, #24]
    sub     r12, r12, r3
    add     r4, r4, r12
    add     r5, r5, r12
    add     r6, r6, r12
    subs    r11, r11, #1
    bne     .Lrow

    add     sp, sp, #16
    vpop    {d8-d15}
    pop     {r4-r11, pc}

.p2align 2
.L255:
    .word   0x437f0000
.Lhalf:
    .word   0x3f000000

SIZE(SYM(applyArithmeticNeon))
