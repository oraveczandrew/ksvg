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
    vmov    d15, d13
    add     r3, r3, #16
    adds    r12, r12, #1
    cmp     r12, #16
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
 *
 * Clobbers q0-q7 and the GPR r2.  The coefficient broadcasts MUST come from
 * a core register: s8..s31 alias d4..d15 (q2..q7), so loading constants
 * through s-registers would overwrite the live pixel lanes.
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

    /* Broadcast k1/255 (q5), k2 (q6), k3 (q7) from the core register. */
    ldr     r2, [sp, #0]
    vdup.32 q5, r2           /* k1 / 255 */
    ldr     r2, [sp, #4]
    vdup.32 q6, r2           /* k2 */
    ldr     r2, [sp, #8]
    vdup.32 q7, r2           /* k3 */

    /* Low four pixels: q4 = result.  Non-FMA ordering, matching the
       AArch64/x86 kernels: ((a*b*k1) + a*k2) + b*k3) + c4. */
    vmul.f32 q4, q2, q0
    vmul.f32 q4, q4, q5
    vmul.f32 q2, q2, q6
    vadd.f32 q4, q4, q2
    vmul.f32 q0, q0, q7
    vadd.f32 q4, q4, q0
    ldr     r2, [sp, #12]
    vdup.32 q5, r2           /* k4*255 + 0.5 */
    vadd.f32 q4, q4, q5

    /* High four pixels: q2 = result, q0 = scratch (B low is dead). */
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
    vdup.32 q3, r2           /* k4*255 + 0.5 (q3, A high, is dead now) */
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

/*
 * CHANNEL: scalar formula for the one output byte of a non-linear tail pixel.
 *
 * Extracts the byte at \shift from \p and \q, converts to float, computes
 *   ((a*b*k1/255) + a*k2 + b*k3) + (k4*255+0.5)
 * clamps to [0,255] and ORs the byte into \acc at \shift.  Mirrors the
 * AArch64 scalar tail (incl. truncating VCVT and the 0/255 clamp) so the two
 * kernels stay bit-identical.
 *
 * VFP state: s0/s1 inputs, s8..s11 constants, d6=0, d7=255, d1=result,
 * d2=truncated result.  Only the core \scratch register is clobbered.
 */
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
    vcvt.s32.f32 d2, d1        /* Advanced SIMD form truncates toward zero */
    vmov    \scratch, s4
    and     \scratch, \scratch, #0xff
    orr     \acc, \acc, \scratch, lsl #\shift
.endm

/*
 * CHANNEL_L: linear-mode scalar channel.  B/G/R bytes are first mapped
 * through the caller's srgbToLinear LUT (\lut) and the result back through
 * linearToSrgb (\lut2); alpha is processed by CHANNEL without LUTs, matching
 * the AArch64 linear tail.  Same VFP/core-register contract as CHANNEL.
 */
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
TYPE(SYM(applyArithmeticNeon), function)
SYM(applyArithmeticNeon):
    push    {r4-r11, lr}
    vpush   {d8-d15}
    sub     sp, sp, #16
    mov     r7, r3              /* capture width BEFORE building constants
                                   (r3 is clobbered by the constant builder) */

    /* Prepare exact SIMD constants in the 16-byte local area.
       k1/255 is computed as k1 * (float 1/255) to match the AArch64 kernel's
       scalar-tail constant bit-for-bit. */
    vldr    s0, [sp, #132]       /* k1 */
    movw    r3, #0x8081
    movt    r3, #0x3b80           /* float 1/255 = 0.00392156886f */
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

    /* r4..r6 = row cursors.  r7 already holds the row width (captured at
       entry); the useLinear flag is kept in r9 for the whole invocation. */
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2

    ldr     r8, [sp, #116]       /* clipLeft */
    ldr     r9, [sp, #120]       /* clipTop */
    ldr     r10, [sp, #124]      /* clipRight */
    ldr     r11, [sp, #128]      /* clipBottom */
    ldr     r0, [sp, #152]       /* srgbToLinear */
    ldr     r1, [sp, #156]       /* linearToSrgb */

    mla     r3, r9, r7, r8       /* clipTop * width + clipLeft */
    add     r4, r4, r3, lsl #2
    add     r5, r5, r3, lsl #2
    add     r6, r6, r3, lsl #2

    sub     r3, r10, r8          /* clipped width, pixels */
    mov     r8, r3               /* keep in r8 (clipLeft dead) */
    lsl     r7, r7, #2           /* row stride, bytes */
    mov     r10, r7              /* keep in r10 (clipRight dead) */
    sub     r11, r11, r9         /* row count (clipTop dead after this) */
    ldr     r9, [sp, #148]       /* useLinear -> r9 */

.Lrow:
    mov     r3, r8               /* clipped width, pixels */
    mov     r14, r3, lsl #2      /* remaining bytes in row */

    cmp     r9, #0              /* useLinear */
    bne     .Llinear_row

/* -------------------------------------------------------------------------
 * Non-linear row: 8 pixels / iteration.
 * ------------------------------------------------------------------------- */
.Lnonlin_vec:
    cmp     r14, #32
    blo     .Lnonlin_tail
    vld4.8  {d0,d1,d2,d3}, [r4]!   /* src1 B,G,R,A */
    vld4.8  {d4,d5,d6,d7}, [r5]!   /* src2 B,G,R,A */

    /* Stage all eight channel planes in d16..d23 (q8..q11): FORMULA8 and
       LUT8 clobber only q0..q7, so the still-pending planes survive here.
       Results are collected in d24..d27 (q12/q13). */
    vmov    d16, d0
    vmov    d17, d1
    vmov    d18, d2
    vmov    d19, d3
    vmov    d20, d4
    vmov    d21, d5
    vmov    d22, d6
    vmov    d23, d7

    /* B: src1=d16, src2=d20 */
    vmov    d0, d16
    vmov    d4, d20
    FORMULA8 d0, d4, d0
    vmov    d24, d0

    /* G: src1=d17, src2=d21 */
    vmov    d0, d17
    vmov    d4, d21
    FORMULA8 d0, d4, d0
    vmov    d25, d0

    /* R: src1=d18, src2=d22 */
    vmov    d0, d18
    vmov    d4, d22
    FORMULA8 d0, d4, d0
    vmov    d26, d0

    /* A: src1=d19, src2=d23 */
    vmov    d0, d19
    vmov    d4, d23
    FORMULA8 d0, d4, d0
    vmov    d27, d0

    vst4.8  {d24,d25,d26,d27}, [r6]!
    sub     r14, r14, #32
    b       .Lnonlin_vec

.Lnonlin_tail:
    mov     r3, r14, lsr #2      /* remaining pixels */
    cmp     r3, #0
    beq     .Lnext_row

    /* Scalar constants: s8=k1/255, s9=k2, s10=k3, s11=k4*255+0.5. */
    vldr    s8, [sp, #0]
    vldr    s9, [sp, #4]
    vldr    s10, [sp, #8]
    vldr    s11, [sp, #12]
    veor    d6, d6, d6
    movw    r12, #0x0000
    movt    r12, #0x437f          /* 255.0f */
    vmov    s14, r12
    vmov    s15, r12              /* d7 = {255,255} */
.Lnonlin_tail_pixel:
    ldr     r0, [r4], #4          /* src1 pixel */
    ldr     r1, [r5], #4          /* src2 pixel */
    eor     r2, r2, r2            /* out = 0 */
    CHANNEL r2, r0, r1, 0, r12    /* B */
    CHANNEL r2, r0, r1, 8, r12    /* G */
    CHANNEL r2, r0, r1, 16, r12   /* R */
    CHANNEL r2, r0, r1, 24, r12   /* A */
    str     r2, [r6], #4
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
    vld4.8  {d0,d1,d2,d3}, [r4]!   /* src1 B,G,R,A */
    vld4.8  {d4,d5,d6,d7}, [r5]!   /* src2 B,G,R,A */

    /* Stage the eight channel planes in d16..d23 (q8..q11); both LUT8 and
       FORMULA8 clobber only d8..d15, so the pending planes survive. */
    vmov    d16, d0
    vmov    d17, d1
    vmov    d18, d2
    vmov    d19, d3
    vmov    d20, d4
    vmov    d21, d5
    vmov    d22, d6
    vmov    d23, d7

    /* B: srgbToLinear(src1), srgbToLinear(src2), formula, linearToSrgb. */
    vmov    d0, d16
    LUT8    d0, d0, r0
    vmov    d4, d20
    LUT8    d4, d4, r0
    FORMULA8 d0, d4, d0
    LUT8    d0, d0, r1
    vmov    d24, d0

    /* G */
    vmov    d0, d17
    LUT8    d0, d0, r0
    vmov    d4, d21
    LUT8    d4, d4, r0
    FORMULA8 d0, d4, d0
    LUT8    d0, d0, r1
    vmov    d25, d0

    /* R */
    vmov    d0, d18
    LUT8    d0, d0, r0
    vmov    d4, d22
    LUT8    d4, d4, r0
    FORMULA8 d0, d4, d0
    LUT8    d0, d0, r1
    vmov    d26, d0

    /* A: encoded domain, formula only - no LUTs. */
    vmov    d0, d19
    vmov    d4, d23
    FORMULA8 d0, d4, d0
    vmov    d27, d0

    vst4.8  {d24,d25,d26,d27}, [r6]!
    sub     r14, r14, #32
    b       .Llinear_vec

.Llinear_tail:
    mov     r12, r14, lsr #2     /* remaining pixels (r14 becomes the accumulator) */
    cmp     r12, #0
    beq     .Lnext_row

    /* Scalar constants (same layout as the non-linear tail). */
    vldr    s8, [sp, #0]
    vldr    s9, [sp, #4]
    vldr    s10, [sp, #8]
    vldr    s11, [sp, #12]
    veor    d6, d6, d6
    movw    r7, #0x0000
    movt    r7, #0x437f          /* 255.0f */
    vmov    s14, r7
    vmov    s15, r7              /* d7 = {255,255} */
.Llinear_tail_pixel:
    ldr     r2, [r4], #4         /* src1 pixel */
    ldr     r3, [r5], #4         /* src2 pixel */
    mov     r14, #0              /* out = 0; r14 (lr) is dead in the tails */
    CHANNEL_L r14, r2, r3, 0, r7, r0, r1    /* B */
    CHANNEL_L r14, r2, r3, 8, r7, r0, r1    /* G */
    CHANNEL_L r14, r2, r3, 16, r7, r0, r1   /* R */
    CHANNEL    r14, r2, r3, 24, r7          /* A: encoded domain, no LUTs */
    str     r14, [r6], #4
    subs    r12, r12, #1
    bne     .Llinear_tail_pixel

.Lnext_row:
    mov     r14, r8              /* clipped width, pixels */
    lsl     r14, r14, #2         /* clipped width, bytes */
    sub     r12, r10, r14        /* bytes to skip to the next row */
    add     r4, r4, r12
    add     r5, r5, r12
    add     r6, r6, r12
    subs    r11, r11, #1
    bne     .Lrow

    add     sp, sp, #16
    vpop    {d8-d15}
    pop     {r4-r11, pc}

SIZE(SYM(applyArithmeticNeon))
