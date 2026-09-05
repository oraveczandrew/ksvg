/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/* ARMv7-A VFP scalar-feTurbulence kernel. Scalar double-precision port of the
 * AArch64 turbulence_noise_neon64.S (turbulence64Asm). Bit-exact output on the
 * validation corpus (identical fp ops, in the same order).
 *
 * This is intentionally the SIMPLE first cut: one pixel at a time, channels
 * unrolled, all octave state in stack slots, no 2-pixel interleave, no shared
 * Y geometry, plain vdiv for the ratio. Register allocation is trivially
 * separable (only r1/r12/r14 and d8-d15/d16-d23 are ever live at once), so it
 * can be rebalanced later without touching the math.
 *
 * void turbulence32Asm(const Turbulence32AsmArgs* args);
 *
 * Per-channel sum is accumulated in double precision (ratio is a power of two,
 * so n/ratio == n*(1/ratio) exactly). floor(t) for the lattice index and
 * fractional part is computed as trunc-then-correct (ARMv7 VFP has no directed
 * floor convert; vcvt.s32.f64 rounds toward zero). For t >= 0 the correction
 * never triggers, which matches the Kotlin reference's tx.toInt() semantics.
 */

.syntax unified
.arm
.fpu neon
.text
.align 2
.global turbulence32Asm
.type turbulence32Asm, %function

/* ── Argument offsets (Turbulence32AsmArgs, sizeof 120) ───────────────────── */
.equ A_SELECTOR,   0
.equ A_GRADX,      4
.equ A_GRADY,      8
.equ A_PIXELS,    12
.equ A_WIDTH,     16
.equ A_CLIP_LEFT, 20
.equ A_CLIP_TOP,  24
.equ A_CLIP_RIGHT,28
.equ A_CLIP_BOTTOM,32
.equ A_PERIOD_X,  36
.equ A_PERIOD_Y,  40
.equ A_OCTAVES,   44
.equ A_FRACTAL,   48
.equ A_FREQ_X,    56
.equ A_FREQ_Y,    64
.equ A_INV_SCALE_X,72
.equ A_INV_SCALE_Y,80
.equ A_USER_LEFT, 88
.equ A_USER_TOP,  96
.equ A_UNIT_X,   104
.equ A_UNIT_Y,   112

/* ── Stack frame (final sp is 8-aligned) ──────────────────────────────────── */
/* Doubles */
.equ S_PX0,    0
.equ S_PY0,    8
.equ S_TILEX, 16
.equ S_TILEY, 24
/* Per-channel double block (6 doubles = 48 bytes), base + offset: */
/*   FX=+0 FY=+8 CTLX=+16 CTLY=+24 RATIO=+32 VALUE=+40 */
.equ CH0, 32
.equ CH1, 80
.equ CH2, 128
.equ CH3, 176
.equ CH_VALUE0, (CH0 + 40)
.equ CH_VALUE1, (CH1 + 40)
.equ CH_VALUE2, (CH2 + 40)
.equ CH_VALUE3, (CH3 + 40)
/* Words */
.equ S_WRAPX,      224
.equ S_WRAPY,      228
.equ S_PIXEL_BASE, 232
.equ S_OCT,        236
.equ S_GX0,        240
.equ S_GX1,        244
.equ S_GY0,        248
.equ S_GY1,        252
.equ S_B00,        256
.equ S_B10,        260
.equ S_B01,        264
.equ S_B11,        268
.equ S_SIZE,       272

/* ── Register map (stable, lazy) ──────────────────────────────────────────── */
/* r0  = args (persistent)              d0 = 1.0 const
 * r2  = pixel output cursor            d1 = 4096.0 const
 * r3  = gradPackedX base               d2 = int conversion transient (s4)
 * r4  = gradPackedY base               d3 = double conversion transient
 * r5  = selector32 base                d4..d7 = arithmetic scratch
 * r6  = y                               d8..d15 = gradient loads (callee-saved)
 * r7  = x                               d20..d25 = per-octave state
 * r8  = fractal flag                    d26..d31 = geometry (rx/ry/sx/sy + tx/ty)
 * r9  = clipRight
 * r10 = octavePeriodX (per channel)
 * r11 = octavePeriodY (per channel)
 * r1, r12, r14 = scratch
 */

/* floor(t): trunc toward zero, then correct when the truncated value is above
 * the true floor (doesn't happen for t >= 0).  out: \breg (int), \frac (double).
 * Clobbers d2 (via s4) and d3. */
.macro FLOOR breg, frac, t
    vcvt.s32.f64 s4, \t
    vmov \breg, s4
    vcvt.f64.s32 d3, s4
    vsub.f64 \frac, \t, d3
    vcmp.f64 \frac, #0.0
    vmrs APSR_nzcv, FPSCR
    bge .Lfloor_ok\@
    vadd.f64 \frac, \frac, d0
    sub \breg, \breg, #1
.Lfloor_ok\@:
.endm

/* sx = t*t*(3.0 - 2.0*t) — same fp op order as the C++ reference. */
.macro SMOOTHSTEP out, t
    vmul.f64 \out, \t, \t
    vadd.f64 d4, d0, d0            /* 2.0 */
    vmul.f64 d5, \t, d4            /* 2*t */
    vadd.f64 d6, d4, d0            /* 3.0 */
    vsub.f64 d6, d6, d5            /* 3 - 2*t */
    vmul.f64 \out, \out, d6
.endm

/* One complete channel: setup, octave loop (geometry + permutation + noise +
 * accumulate), folded into \base-offset slots.  Channel gradient byte offset
 * (0/8/16/24) is \chb. */
.macro CHANNEL_BLOCK base, chb
    /* ── Setup ─────────────────────────────────────────────────────────── */
    mov r12, #0
    vmov d4, r12, r12
    vstr d4, [sp, #(\base + 40)]   /* VALUE = 0.0 */

    vldr d4, [sp, #S_PX0]
    vstr d4, [sp, #(\base + 0)]    /* FX = px0 */
    vldr d4, [sp, #S_PY0]
    vstr d4, [sp, #(\base + 8)]    /* FY = py0 */

    vldr d4, [sp, #S_TILEX]
    vldr d5, [r0, #A_FREQ_X]
    vmul.f64 d4, d4, d5
    vstr d4, [sp, #(\base + 16)]   /* CTLX = tileX * freqX */
    vldr d4, [sp, #S_TILEY]
    vldr d5, [r0, #A_FREQ_Y]
    vmul.f64 d4, d4, d5
    vstr d4, [sp, #(\base + 24)]   /* CTLY = tileY * freqY */

    vmov.f64 d4, d0
    vstr d4, [sp, #(\base + 32)]   /* RATIO = 1.0 */

    ldr r14, [r0, #A_OCTAVES]
    str r14, [sp, #S_OCT]
    ldr r10, [r0, #A_PERIOD_X]
    ldr r11, [r0, #A_PERIOD_Y]

    /* ── Octave loop ───────────────────────────────────────────────────── */
.Loct\@:
    ldr r14, [sp, #S_OCT]
    cmp r14, #0
    ble .Ldone\@

    vldr d20, [sp, #(\base + 0)]   /* fx */
    vldr d21, [sp, #(\base + 8)]   /* fy */
    vldr d22, [sp, #(\base + 16)]  /* curtlx */
    vldr d23, [sp, #(\base + 24)]  /* curtly */
    vldr d24, [sp, #(\base + 32)]  /* ratio */
    vldr d25, [sp, #(\base + 40)]  /* value */

    /* wrapX = floor(curtlx) + 4096 + width        (floor(curtlx+4096) is the
     * same integer, and adding the exact 4096.0 before the convert is exact) */
    cmp r10, #0
    ble .Lnx\@
    vadd.f64 d4, d22, d1
    FLOOR r12, d5, d4
    add r12, r12, r10
    str r12, [sp, #S_WRAPX]
    b .Lwx\@
.Lnx\@:
    mov r12, #0
    str r12, [sp, #S_WRAPX]
.Lwx\@:
    cmp r11, #0
    ble .Lny\@
    vadd.f64 d4, d23, d1
    FLOOR r12, d5, d4
    add r12, r12, r11
    str r12, [sp, #S_WRAPY]
    b .Lwy\@
.Lny\@:
    mov r12, #0
    str r12, [sp, #S_WRAPY]
.Lwy\@:

    /* ── X geometry ────────────────────────────────────────────────────── */
    vadd.f64 d16, d20, d1          /* tx = fx + 4096 */
    FLOOR r1, d26, d16             /* bx0, rx0 */
    add r12, r1, #1                /* bx1 */
    vsub.f64 d27, d26, d0          /* rx1 = rx0 - 1.0 */

    ldr r14, [sp, #S_WRAPX]
    cmp r10, #0
    ble .Lscx\@
    cmp r1, r14
    subge r1, r1, r10
    cmp r12, r14
    subge r12, r12, r10
.Lscx\@:
    and r1, r1, #255
    and r12, r12, #255
    str r1, [sp, #S_GX0]
    str r12, [sp, #S_GX1]

    SMOOTHSTEP d30, d26            /* sx */

    /* ── Y geometry ────────────────────────────────────────────────────── */
    vadd.f64 d17, d21, d1          /* ty = fy + 4096 */
    FLOOR r14, d28, d17            /* by0, ry0 */
    add r1, r14, #1                /* by1 */
    vsub.f64 d29, d28, d0          /* ry1 = ry0 - 1.0 */

    ldr r12, [sp, #S_WRAPY]
    cmp r11, #0
    ble .Lscy\@
    cmp r14, r12
    subge r14, r14, r11
    cmp r1, r12
    subge r1, r1, r11
.Lscy\@:
    and r14, r14, #255
    and r1, r1, #255
    str r14, [sp, #S_GY0]
    str r1, [sp, #S_GY1]

    SMOOTHSTEP d31, d28            /* sy */

    /* ── Permutation (selector32) ──────────────────────────────────────── */
    ldr r1, [sp, #S_GX0]
    ldr r1, [r5, r1, lsl #2]       /* i  = sel[bx0] */
    ldr r12, [sp, #S_GX1]
    ldr r12, [r5, r12, lsl #2]     /* j  = sel[bx1] */
    ldr r14, [sp, #S_GY1]
    add r14, r1, r14               /* i + by1 */
    ldr r14, [r5, r14, lsl #2]
    str r14, [sp, #S_B01]
    ldr r14, [sp, #S_GY1]
    add r14, r12, r14              /* j + by1 */
    ldr r14, [r5, r14, lsl #2]
    str r14, [sp, #S_B11]
    ldr r14, [sp, #S_GY0]
    add r1, r1, r14                /* i + by0 */
    ldr r1, [r5, r1, lsl #2]
    str r1, [sp, #S_B00]
    add r12, r12, r14              /* j + by0 */
    ldr r12, [r5, r12, lsl #2]
    str r12, [sp, #S_B10]

    /* ── Gradient loads for this channel (byte offset \chb) ────────────── */
    ldr r14, [sp, #S_B00]
    add r1, r3, r14, lsl #5
    add r1, r1, #\chb
    vldr d8, [r1]                  /* gx b00 */
    add r1, r4, r14, lsl #5
    add r1, r1, #\chb
    vldr d9, [r1]                  /* gy b00 */
    ldr r14, [sp, #S_B10]
    add r1, r3, r14, lsl #5
    add r1, r1, #\chb
    vldr d10, [r1]                 /* gx b10 */
    add r1, r4, r14, lsl #5
    add r1, r1, #\chb
    vldr d11, [r1]                 /* gy b10 */
    ldr r14, [sp, #S_B01]
    add r1, r3, r14, lsl #5
    add r1, r1, #\chb
    vldr d12, [r1]                 /* gx b01 */
    add r1, r4, r14, lsl #5
    add r1, r1, #\chb
    vldr d13, [r1]                 /* gy b01 */
    ldr r14, [sp, #S_B11]
    add r1, r3, r14, lsl #5
    add r1, r1, #\chb
    vldr d14, [r1]                 /* gx b11 */
    add r1, r4, r14, lsl #5
    add r1, r1, #\chb
    vldr d15, [r1]                 /* gy b11 */

    /* ── Noise2 (u/v/a/u2/v2/b then n), same fp order as the reference ───
     * vmla.f64 is fused on this VFPv4 core; the C++ reference builds with
     * -ffp-contract=off (separate mul + add), so expand to vmul+vadd for
     * bit-exact parity. */
    vmul.f64 d4, d26, d8           /* u = rx0*gx00 */
    vmul.f64 d3, d28, d9
    vadd.f64 d4, d4, d3            /*   + ry0*gy00 */
    vmul.f64 d5, d27, d10          /* v = rx1*gx10 */
    vmul.f64 d3, d28, d11
    vadd.f64 d5, d5, d3            /*   + ry0*gy10 */
    vsub.f64 d6, d5, d4
    vmul.f64 d3, d30, d6
    vadd.f64 d4, d4, d3            /* a = u + sx*(v-u) */
    vmul.f64 d5, d26, d12          /* u2 = rx0*gx01 */
    vmul.f64 d3, d29, d13
    vadd.f64 d5, d5, d3            /*     + ry1*gy01 */
    vmul.f64 d6, d27, d14          /* v2 = rx1*gx11 */
    vmul.f64 d3, d29, d15
    vadd.f64 d6, d6, d3            /*     + ry1*gy11 */
    vsub.f64 d7, d6, d5
    vmul.f64 d3, d30, d7
    vadd.f64 d5, d5, d3            /* b = u2 + sx*(v2-u2) */
    vsub.f64 d6, d5, d4
    vmul.f64 d3, d31, d6
    vadd.f64 d4, d4, d3            /* n = a + sy*(b-a) */

    /* ── Accumulate: value += fractal ? n/ratio : |n|/ratio ────────────── */
    cmp r8, #0
    beq .Ltb\@
    vdiv.f64 d4, d4, d24
    vadd.f64 d25, d25, d4
    b .Lac\@
.Ltb\@:
    vabs.f64 d4, d4
    vdiv.f64 d4, d4, d24
    vadd.f64 d25, d25, d4
.Lac\@:

    vstr d25, [sp, #(\base + 40)]  /* value */

    /* ── Advance state for the next octave ─────────────────────────────── */
    vadd.f64 d20, d20, d20
    vstr d20, [sp, #(\base + 0)]
    vadd.f64 d21, d21, d21
    vstr d21, [sp, #(\base + 8)]
    vadd.f64 d22, d22, d22
    vstr d22, [sp, #(\base + 16)]
    vadd.f64 d23, d23, d23
    vstr d23, [sp, #(\base + 24)]
    vadd.f64 d24, d24, d24
    vstr d24, [sp, #(\base + 32)]

    cmp r10, #0
    ble .Lndx\@
    lsl r10, r10, #1
.Lndx\@:
    cmp r11, #0
    ble .Lndy\@
    lsl r11, r11, #1
.Lndy\@:

    ldr r14, [sp, #S_OCT]
    subs r14, r14, #1
    str r14, [sp, #S_OCT]
    bgt .Loct\@
.Ldone\@:
.endm

turbulence32Asm:
    push {r4-r11, lr}
    sub sp, sp, #4                  /* pad to 8-byte alignment for vpush */
    vpush {d8-d15}
    sub sp, sp, #S_SIZE

    /* constants: d0 = 1.0, d1 = 4096.0 */
    mov r12, #0
    movw r1, #0
    movt r1, #0x3FF0
    vmov d0, r12, r1
    movw r1, #0
    movt r1, #0x40B0
    vmov d1, r12, r1

    ldr r3, [r0, #A_GRADX]
    ldr r4, [r0, #A_GRADY]
    ldr r5, [r0, #A_SELECTOR]
    ldr r8, [r0, #A_FRACTAL]
    ldr r2, [r0, #A_PIXELS]
    str r2, [sp, #S_PIXEL_BASE]
    ldr r6, [r0, #A_CLIP_TOP]
    ldr r9, [r0, #A_CLIP_RIGHT]

    b row_loop

/* ════════════════════════════════════════════════════════════════════════════
 * Row loop. r6 = y, r9 = clipRight.
 * ════════════════════════════════════════════════════════════════════════════ */
row_loop:
    ldr r14, [r0, #A_CLIP_BOTTOM]
    cmp r6, r14
    bge finish

    /* py0 = (userTop + y*invScaleY) / unitY * freqY */
    vmov s4, r6
    vcvt.f64.s32 d3, s4
    vldr d5, [r0, #A_INV_SCALE_Y]
    vmul.f64 d3, d3, d5
    vldr d5, [r0, #A_USER_TOP]
    vadd.f64 d3, d3, d5
    vldr d5, [r0, #A_UNIT_Y]
    vdiv.f64 d3, d3, d5
    vldr d5, [r0, #A_FREQ_Y]
    vmul.f64 d3, d3, d5
    vstr d3, [sp, #S_PY0]

    /* tileY = (y - clipTop) */
    ldr r14, [r0, #A_CLIP_TOP]
    sub r1, r6, r14
    vmov s4, r1
    vcvt.f64.s32 d3, s4
    vstr d3, [sp, #S_TILEY]

    /* row destination = pixels + (y*width + clipLeft)*4 */
    ldr r1, [sp, #S_PIXEL_BASE]
    ldr r14, [r0, #A_WIDTH]
    mul r14, r6, r14
    ldr r12, [r0, #A_CLIP_LEFT]
    add r14, r14, r12
    add r2, r1, r14, lsl #2

    ldr r7, [r0, #A_CLIP_LEFT]

/* ════════════════════════════════════════════════════════════════════════════
 * Pixel loop. r7 = x.
 * ════════════════════════════════════════════════════════════════════════════ */
pixel_loop:
    cmp r7, r9
    bge next_row

    /* px0 = (userLeft + x*invScaleX) / unitX * freqX */
    vmov s4, r7
    vcvt.f64.s32 d3, s4
    vldr d5, [r0, #A_INV_SCALE_X]
    vmul.f64 d3, d3, d5
    vldr d5, [r0, #A_USER_LEFT]
    vadd.f64 d3, d3, d5
    vldr d5, [r0, #A_UNIT_X]
    vdiv.f64 d3, d3, d5
    vldr d5, [r0, #A_FREQ_X]
    vmul.f64 d3, d3, d5
    vstr d3, [sp, #S_PX0]

    /* tileX = (x - clipLeft) */
    ldr r14, [r0, #A_CLIP_LEFT]
    sub r1, r7, r14
    vmov s4, r1
    vcvt.f64.s32 d3, s4
    vstr d3, [sp, #S_TILEX]

    /* the four channels (R, G, B, A) */
    CHANNEL_BLOCK CH0, 0
    CHANNEL_BLOCK CH1, 8
    CHANNEL_BLOCK CH2, 16
    CHANNEL_BLOCK CH3, 24

/* ════════════════════════════════════════════════════════════════════════════
 * Pack: given sums[4], finalVal = (sum + offset)*scale, +0.5, truncate, clamp.
 * fractal: offset=1.0, scale=127.5    turbulence: offset=0.0, scale=255.0
 * ════════════════════════════════════════════════════════════════════════════ */
pack_pixel:
    cmp r8, #0
    beq .Lfp_turb

    mov r12, #0
    movw r1, #0xE000
    movt r1, #0x405F
    vmov d5, r12, r1                /* scale = 127.5 */
    vmov.f64 d6, d0                 /* offset = 1.0 */
    b .Lfp_common
.Lfp_turb:
    mov r12, #0
    movw r1, #0xE000
    movt r1, #0x406F
    vmov d5, r12, r1                /* scale = 255.0 */
    mov r12, #0
    vmov d6, r12, r12               /* offset = 0.0 */
.Lfp_common:
    mov r12, #0
    movw r1, #0x0000
    movt r1, #0x3FE0
    vmov d7, r12, r1                /* 0.5 */

    /* ch0 (R) -> r12 */
    vldr d4, [sp, #CH_VALUE0]
    vadd.f64 d4, d4, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r12, s4
    cmp r12, #0
    movlt r12, #0
    cmp r12, #255
    movgt r12, #255

    /* ch1 (G) -> r1 */
    vldr d4, [sp, #CH_VALUE1]
    vadd.f64 d4, d4, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r1, s4
    cmp r1, #0
    movlt r1, #0
    cmp r1, #255
    movgt r1, #255

    /* ch2 (B) -> r14 */
    vldr d4, [sp, #CH_VALUE2]
    vadd.f64 d4, d4, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r14, s4
    cmp r14, #0
    movlt r14, #0
    cmp r14, #255
    movgt r14, #255

    orr r1, r14, r1, lsl #8         /* B | G<<8 */
    orr r1, r1, r12, lsl #16        /* | R<<16  (r12's R consumed now) */

    /* ch3 (A) -> r12  (r8 stays the fractal flag) */
    vldr d4, [sp, #CH_VALUE3]
    vadd.f64 d4, d4, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r12, s4
    cmp r12, #0
    movlt r12, #0
    cmp r12, #255
    movgt r12, #255

    orr r12, r1, r12, lsl #24       /* | A<<24 */
    str r12, [r2], #4

    add r7, r7, #1
    b pixel_loop

next_row:
    add r6, r6, #1
    b row_loop

finish:
    add sp, sp, #S_SIZE
    vpop {d8-d15}
    add sp, sp, #4
    pop {r4-r11, pc}

.size turbulence32Asm, .-turbulence32Asm