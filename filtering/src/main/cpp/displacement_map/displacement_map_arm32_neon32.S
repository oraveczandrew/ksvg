/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 */

#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x,y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x,y) .type x,y
#define SIZE(x) .size x,.-x
#endif

    .syntax unified
    .text
    .fpu neon
    .align 2

/*
 * void ksvgDisplacementMapApplyNeon32(
 *     const int32_t* src, const int32_t* map, int32_t* dst,
 *     int width, int height, float scale, int xChannel, int yChannel);
 *
 * AAPCS / armeabi-v7a softfp ABI (same convention the repo's other armv7a
 * kernels use, e.g. morphology_armv7a_neon.S):
 *   r0 = src     r1 = map      r2 = dst     r3 = width
 *   [sp,#0]  = height
 *   [sp,#4]  = scale (float bits)
 *   [sp,#8]  = xChannel
 *   [sp,#12] = yChannel
 *
 * This is a 4-pixel NEON kernel. The final src access is inherently scalar:
 * ARMv7 NEON has no general integer gather.
 *
 * The vector path keeps the byte-exact u/255.0f via a true VFP scalar divide
 * per lane (NEON has no vector FP divide; the reciprocal-refinement multiply
 * is 1 ulp off against the Kotlin /255f reference).
 */

    .global SYM(ksvgDisplacementMapApplyNeon32)
    TYPE(SYM(ksvgDisplacementMapApplyNeon32), %function)
SYM(ksvgDisplacementMapApplyNeon32):
    ldr     r8, [sp, #8]
    ldr     r9, [sp, #12]
    and     r8, r8, #3
    lsl     r8, r8, #2
    and     r9, r9, #3
    orr     r8, r8, r9

    cmp     r8, #0
    beq     .L_RR
    cmp     r8, #1
    beq     .L_RG
    cmp     r8, #2
    beq     .L_RB
    cmp     r8, #3
    beq     .L_RA
    cmp     r8, #4
    beq     .L_GR
    cmp     r8, #5
    beq     .L_GG
    cmp     r8, #6
    beq     .L_GB
    cmp     r8, #7
    beq     .L_GA
    cmp     r8, #8
    beq     .L_BR
    cmp     r8, #9
    beq     .L_BG
    cmp     r8, #10
    beq     .L_BB
    cmp     r8, #11
    beq     .L_BA
    cmp     r8, #12
    beq     .L_AR
    cmp     r8, #13
    beq     .L_AG
    cmp     r8, #14
    beq     .L_AB
    b       .L_AA

    .macro DEFINE_KERNEL label, xshift, yshift
\label:
    push    {r4-r11, lr}

    mov     r4, r0                @ src
    mov     r5, r1                @ map row pointer
    mov     r6, r2                @ dst row pointer
    mov     r7, r3                @ width
    ldr     r8, [sp, #36]         @ height
    sub     r9, r7, #1            @ width - 1
    sub     r10, r8, #1           @ height - 1
    mov     r11, #0               @ y

    cmp     r7, #0
    beq     .L_done_\label
    cmp     r8, #0
    beq     .L_done_\label

    vdup.32 q7, r9               @ width - 1
    vdup.32 q8, r10              @ height - 1
    vmov.i32 q9, #0              @ zero
    vmov.i32 q10, #255           @ byte mask / 255 source

    vldr    s22, [sp, #40]       @ scale
    vdup.32 q11, d11[0]          @ scale = s22 (=d11[0]); NOT d22[0] (s44, uninit)
    vmov.f32 q12, #0.5           @ half

    @ 255.0f for the true per-lane divide below. s26 = d13[0] is only safe
    @ because the row's y-broadcast lives in q13, NOT q6 (= d12/d13): a
    @ vdup.32 q6, r11 would have clobbered s26 with raw y bits every row,
    @ yielding byte/0.0f -> +Inf -> saturating INT_MAX indices.
    vldr    s26, .L_float255_\label

    adr     r0, .L_inc_\label
    vld1.32  {d28-d29}, [r0]     @ q14 = 0,1,2,3

    mov     r12, #0              @ x

.L_row_\label:
    cmp     r11, r8
    bge     .L_done_\label

    vdup.32 q13, r11             @ y,y,y,y (q13: do NOT use q6, it aliases the s26 divisor)
    mov     r12, #0

.L_vec_\label:
    cmp     r12, r7
    bge     .L_tail_\label

    vld1.32  {d0-d1}, [r5]!      @ 4 map pixels

    .if \xshift == 0
        vmov    q1, q0
        vand    q1, q1, q10
    .else
        vshr.u32 q1, q0, #\xshift
        vand    q1, q1, q10
    .endif

    .if \yshift == 0
        vmov    q2, q0
        vand    q2, q2, q10
    .else
        vshr.u32 q2, q0, #\yshift
        vand    q2, q2, q10
    .endif

    vcvt.f32.u32 s4, s4
    vdiv.f32 s4, s4, s26
    vcvt.f32.u32 s5, s5
    vdiv.f32 s5, s5, s26
    vcvt.f32.u32 s6, s6
    vdiv.f32 s6, s6, s26
    vcvt.f32.u32 s7, s7
    vdiv.f32 s7, s7, s26
    vcvt.f32.u32 s8, s8
    vdiv.f32 s8, s8, s26
    vcvt.f32.u32 s9, s9
    vdiv.f32 s9, s9, s26
    vcvt.f32.u32 s10, s10
    vdiv.f32 s10, s10, s26
    vcvt.f32.u32 s11, s11
    vdiv.f32 s11, s11, s26
    vsub.f32 q1, q1, q12
    vsub.f32 q2, q2, q12
    vmul.f32 q1, q1, q11
    vmul.f32 q2, q2, q11
    vcvt.s32.f32 q1, q1
    vcvt.s32.f32 q2, q2

    vdup.32 q5, r12
    vadd.i32 q5, q5, q14         @ x..x+3

    vadd.i32 q3, q5, q1
    vmax.s32 q3, q3, q9
    vmin.s32 q3, q3, q7

    vadd.i32 q4, q13, q2
    vmax.s32 q4, q4, q9
    vmin.s32 q4, q4, q8

    @ lane 0
    vmov    r0, s12              @ sx0
    vmov    r1, s16              @ sy0
    mla     r2, r1, r7, r0
    ldr     r3, [r4, r2, lsl #2]
    str     r3, [r6, #0]

    @ lane 1
    vmov    r0, s13              @ sx1
    vmov    r1, s17              @ sy1
    mla     r2, r1, r7, r0
    ldr     r3, [r4, r2, lsl #2]
    str     r3, [r6, #4]

    @ lane 2
    vmov    r0, s14              @ sx2
    vmov    r1, s18              @ sy2
    mla     r2, r1, r7, r0
    ldr     r3, [r4, r2, lsl #2]
    str     r3, [r6, #8]

    @ lane 3
    vmov    r0, s15              @ sx3
    vmov    r1, s19              @ sy3
    mla     r2, r1, r7, r0
    ldr     r3, [r4, r2, lsl #2]
    str     r3, [r6, #12]

    add     r6, r6, #16
    add     r12, r12, #4
    b       .L_vec_\label

.L_tail_\label:
    cmp     r12, r7
    bge     .L_row_done_\label

.L_tail_loop_\label:
    ldr     r3, [r5], #4

    lsr     r0, r3, #\xshift
    and     r0, r0, #255
    vmov    s0, r0
    vcvt.f32.u32 s0, s0
    vldr    s1, .L_float255_\label
    vdiv.f32 s0, s0, s1
    vldr    s1, .L_half_\label
    vsub.f32 s0, s0, s1
    vldr    s2, [sp, #40]
    vmul.f32 s0, s0, s2
    vcvt.s32.f32 s0, s0
    vmov    r0, s0
    add     r0, r0, r12
    cmp     r0, #0
    movlt   r0, #0
    cmp     r0, r7
    movge   r0, r9

    lsr     r1, r3, #\yshift
    and     r1, r1, #255
    vmov    s0, r1
    vcvt.f32.u32 s0, s0
    vldr    s1, .L_float255_\label
    vdiv.f32 s0, s0, s1
    vldr    s1, .L_half_\label
    vsub.f32 s0, s0, s1
    vldr    s2, [sp, #40]
    vmul.f32 s0, s0, s2
    vcvt.s32.f32 s0, s0
    vmov    r1, s0
    add     r1, r1, r11
    cmp     r1, #0
    movlt   r1, #0
    cmp     r1, r8
    movge   r1, r10

    mla     r2, r1, r7, r0
    ldr     r3, [r4, r2, lsl #2]
    str     r3, [r6], #4

    add     r12, r12, #1
    cmp     r12, r7
    blt     .L_tail_loop_\label

.L_row_done_\label:
    add     r11, r11, #1
    b       .L_row_\label

.L_done_\label:
    pop     {r4-r11, pc}

    .align 2
.L_inc_\label:
    .word 0, 1, 2, 3
.L_float255_\label:
    .word 0x437f0000
.L_half_\label:
    .word 0x3f000000
    .endm

    .align 2
.L_RR:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_RR, 16, 16
.L_RG:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_RG, 16, 8
.L_RB:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_RB, 16, 0
.L_RA:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_RA, 16, 24
.L_GR:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_GR, 8, 16
.L_GG:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_GG, 8, 8
.L_GB:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_GB, 8, 0
.L_GA:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_GA, 8, 24
.L_BR:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_BR, 0, 16
.L_BG:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_BG, 0, 8
.L_BB:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_BB, 0, 0
.L_BA:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_BA, 0, 24
.L_AR:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_AR, 24, 16
.L_AG:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_AG, 24, 8
.L_AB:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_AB, 24, 0
.L_AA:
    DEFINE_KERNEL ksvgDisplacementMapApplyNeon32_AA, 24, 24

    .section .note.GNU-stack,"",%progbits
