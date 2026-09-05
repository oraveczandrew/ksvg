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
 * Structure: octave-outer / channel-inner. For each pixel the octave loop runs
 * N times; within one octave the channel-independent geometry (wrap, x/y
 * lattice indices, smoothstep, permutation) is computed ONCE, then the four
 * channels (R, G, B, A) each reload their own gradient set and accumulate into
 * a dedicated register. Per-pixel state stays in the VFP register file: the
 * octave loop touches no stack for state, so the previous ~120 bytes of
 * vldr/vstr per octave collapse to a handful of GPR loads/stores.
 *
 * Register map (VFP d0..d31 fully allocated):
 *   d0   = 1.0            d1   = 4096.0
 *   d2   = 3.0 (permanent SMOOTHSTEP constant)
 *   d3-d7   geometry/noise arithmetic scratch
 *   d8-d15  current channel gradients (gx00 gy00 gx10 gy10 gx01 gy01 gx11 gy11)
 *   d16-d19 channel accumulators R G B A
 *   d20-d24 octave state fx fy ctlx ctly weight
 *   d25     2^52 (exponent-step constant, permanent: halves the weight bitwise)
 *   d26-d31 geometry rx0 rx1 ry0 ry1 sx sy
 *
 * GPRs:
 *   r0 args   r3 gradX    r4 gradY    r6 y    r7 x
 *   r8 fractal flag       r9 clipRight
 *   r5 octave index       r2 output cursor (spilled to S_DST inside the loop)
 *   r1 r10-r12 r14 scratch / lattice indices (b00 b01 b10 b11)
 *
 * void turbulence32Asm(const Turbulence32AsmArgs* args);
 *
 * Per-channel sum is accumulated in double precision, scaled by the octave
 * weight d24 (the reciprocal of the lattice ratio 2^octave). The weight is a
 * power of two, so it is stepped bitwise (decrement the biased exponent by one)
 * instead of computing n/2^octave in VFP — multiply by the exact reciprocal and
 * divide by the exact ratio are the same value bit for bit. floor(t) for the
 * lattice index and fractional part is computed as trunc-then-correct (ARMv7
 * VFP has no directed floor convert; vcvt.s32.f64 rounds toward zero). For
 * t >= 0 the correction never triggers, which matches the Kotlin reference's
 * tx.toInt() semantics.
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
/* Doubles: scale/offset/0.5 cached once per call (pack constant triple) */
.equ S_SCALE,    0
.equ S_OFFSET,   8
.equ S_HALF,    16
.equ S_PY0,     24
.equ S_CTLY0,   32
/* Words */
.equ S_DST,     40
.equ S_SIZE,    48

/* floor(t): trunc toward zero, then correct when the truncated value is above
 * the true floor (doesn't happen for t >= 0).  out: \breg (int), \frac (double).
 * Clobbers s14 (low word of d7) and d3. \t must NOT be d7 (s14 aliases d7's low
 * half). d2 is a live constant (3.0), so the integer convert lands in s14. */
.macro FLOOR breg, frac, t
    vcvt.s32.f64 s14, \t
    vmov \breg, s14
    vcvt.f64.s32 d3, s14
    vsub.f64 \frac, \t, d3
    vcmp.f64 \frac, #0.0
    vmrs APSR_nzcv, FPSCR
    bge .Lfloor_ok\@
    vadd.f64 \frac, \frac, d0
    sub \breg, \breg, #1
.Lfloor_ok\@:
.endm

/* sx = t*t*(3.0 - 2.0*t) — same fp op order as the C++ reference. 2*t via
 * t+t (exact doubling, bit-identical to t*2.0) so d25 can stay the permanent
 * exponent-step constant; d2 = 3.0 is a live constant. */
.macro SMOOTHSTEP out, t
    vmul.f64 \out, \t, \t
    vadd.f64 d5, \t, \t            /* 2*t */
    vsub.f64 d6, d2, d5            /* 3 - 2*t */
    vmul.f64 \out, \out, d6
.endm

/* One channel of one octave: reload the channel's gradients (byte offset \chb)
 * into d8-d15 using the shared lattice indices, compute noise into d4 with the
 * shared geometry (d26-d31), and accumulate into \acc (one of d16-d19) with the
 * octave weight (d24, the reciprocal of the lattice ratio). Clobbers r1/r2 as
 * address scratch only.
 *
 * Lattice indices: b00=r14, b01=r10, b10=r12, b11=r11. */
.macro NOISE_CHANNEL chb, acc
    /* b00 -> d8 (gx) / d9 (gy) */
    add r2, r3, r14, lsl #5
    vldr d8, [r2, #\chb]
    add r1, r4, r14, lsl #5
    vldr d9, [r1, #\chb]
    /* b10 -> d10 (gx) / d11 (gy) */
    add r2, r3, r12, lsl #5
    vldr d10, [r2, #\chb]
    add r1, r4, r12, lsl #5
    vldr d11, [r1, #\chb]
    /* b01 -> d12 (gx) / d13 (gy) */
    add r2, r3, r10, lsl #5
    vldr d12, [r2, #\chb]
    add r1, r4, r10, lsl #5
    vldr d13, [r1, #\chb]
    /* b11 -> d14 (gx) / d15 (gy) */
    add r2, r3, r11, lsl #5
    vldr d14, [r2, #\chb]
    add r1, r4, r11, lsl #5
    vldr d15, [r1, #\chb]

    /* Noise2 (u/v/a/u2/v2/b then n), same fp order as the reference ───────
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

    /* Accumulate: acc += (r8 ? n : |n|) * weight. The APSR flags (Z) come from a
 * `cmp r8, #0` hoisted before the channel group: the gradient `add` address
 * math and the VFP ops below never write APSR, so one compare feeds all four
 * channels' vabseq. */
    vabseq.f64 d4, d4
    vmul.f64 d4, d4, d24
    vadd.f64 \acc, \acc, d4
.endm

turbulence32Asm:
    push {r4-r11, lr}
    sub sp, sp, #4                  /* pad to 8-byte alignment for vpush */
    vpush {d8-d15}
    sub sp, sp, #S_SIZE

    /* constants: d0 = 1.0, d1 = 4096.0, d2 = 3.0 */
    mov r12, #0
    movw r1, #0
    movt r1, #0x3FF0
    vmov d0, r12, r1
    movw r1, #0
    movt r1, #0x40B0
    vmov d1, r12, r1
    vmov.f64 d2, #3.0
    /* d25 = 2^52 (0x0010000000000000): one exponent unit. Subtracting it from
     * the weight's bit pattern halves the weight bit-exactly. */
    mov r12, #0
    movw r1, #0x0000
    movt r1, #0x0010
    vmov d25, r12, r1

    ldr r3, [r0, #A_GRADX]
    ldr r4, [r0, #A_GRADY]
    ldr r8, [r0, #A_FRACTAL]
    ldr r6, [r0, #A_CLIP_TOP]
    ldr r9, [r0, #A_CLIP_RIGHT]

    /* pack constants, built ONCE per call (the mode is fixed by r8): scale,
     * offset and 0.5 cached in the frame so pack_pixel needs one vldm. */
    cmp r8, #0
    beq .Lcfg_turb
    mov r12, #0
    movw r1, #0xE000
    movt r1, #0x405F
    vmov d5, r12, r1                /* scale = 127.5 */
    vmov.f64 d6, d0                 /* offset = 1.0 */
    b .Lcfg_store
.Lcfg_turb:
    mov r12, #0
    movw r1, #0xE000
    movt r1, #0x406F
    vmov d5, r12, r1                /* scale = 255.0 */
    veor d6, d6, d6                 /* offset = 0.0 */
.Lcfg_store:
    vmov.f64 d7, #0.5
    vstr d5, [sp, #S_SCALE]
    vstr d6, [sp, #S_OFFSET]
    vstr d7, [sp, #S_HALF]

    b row_loop

/* ════════════════════════════════════════════════════════════════════════════
 * Row loop. r6 = y, r9 = clipRight.
 * ════════════════════════════════════════════════════════════════════════════ */
row_loop:
    ldr r14, [r0, #A_CLIP_BOTTOM]
    cmp r6, r14
    bge finish

    /* py0 = (userTop + y*invScaleY) / unitY * freqY */
    vmov s6, r6
    vcvt.f64.s32 d3, s6
    vldr d5, [r0, #A_INV_SCALE_Y]
    vmul.f64 d3, d3, d5
    vldr d5, [r0, #A_USER_TOP]
    vadd.f64 d3, d3, d5
    vldr d5, [r0, #A_UNIT_Y]
    vdiv.f64 d3, d3, d5
    vldr d5, [r0, #A_FREQ_Y]
    vmul.f64 d3, d3, d5
    vstr d3, [sp, #S_PY0]

    /* ctly0 = (y - clipTop) * freqY  (d5 still holds freqY from py0) */
    ldr r14, [r0, #A_CLIP_TOP]
    sub r1, r6, r14
    vmov s6, r1
    vcvt.f64.s32 d3, s6
    vmul.f64 d3, d3, d5
    vstr d3, [sp, #S_CTLY0]

    /* row destination = pixels + (y*width + clipLeft)*4 */
    ldr r1, [r0, #A_PIXELS]
    ldr r14, [r0, #A_WIDTH]
    ldr r12, [r0, #A_CLIP_LEFT]
    mla r14, r6, r14, r12          /* y*width + clipLeft */
    add r2, r1, r14, lsl #2

    ldr r7, [r0, #A_CLIP_LEFT]

/* ════════════════════════════════════════════════════════════════════════════
 * Pixel loop. r7 = x, r2 = output cursor.
 * ════════════════════════════════════════════════════════════════════════════ */
pixel_loop:
    cmp r7, r9
    bge next_row

    /* accumulators = 0 (q8 = d16/d17, q9 = d18/d19) */
    veor q8, q8, q8
    veor q9, q9, q9

    /* fx = px0 = (userLeft + x*invScaleX) / unitX * freqX */
    vmov s6, r7
    vcvt.f64.s32 d3, s6
    vldr d5, [r0, #A_INV_SCALE_X]
    vmul.f64 d3, d3, d5
    vldr d5, [r0, #A_USER_LEFT]
    vadd.f64 d3, d3, d5
    vldr d5, [r0, #A_UNIT_X]
    vdiv.f64 d3, d3, d5
    vldr d5, [r0, #A_FREQ_X]
    vmul.f64 d20, d3, d5          /* fx */

    /* ctlx = tileX * freqX  (d5 still holds freqX from fx) */
    ldr r14, [r0, #A_CLIP_LEFT]
    sub r1, r7, r14
    vmov s6, r1
    vcvt.f64.s32 d3, s6           /* tileX */
    vmul.f64 d22, d3, d5          /* ctlx */

    /* fy, ctly */
    vldr d21, [sp, #S_PY0]
    vldr d23, [sp, #S_CTLY0]

    /* weight = 1.0 (reciprocal, halves bitwise each octave), octave index = 0,
     * park the output cursor */
    vmov.f64 d24, d0
    mov r5, #0
    str r2, [sp, #S_DST]

    b .Loct
.Loct_done:
    b pack_pixel

/* ════════════════════════════════════════════════════════════════════════════
 * Octave loop. r5 = octave index. Shared geometry once, then 4 channels.
 * ════════════════════════════════════════════════════════════════════════════ */
.Loct:
    ldr r1, [r0, #A_OCTAVES]
    cmp r5, r1
    bge .Loct_done

    /* ── X geometry (stich wrap folded in) ──────────────────────────────── */
    ldr r12, [r0, #A_PERIOD_X]
    cmp r12, #0
    ble .LxNowrap
    lsl r12, r12, r5              /* periodX << octave */
    vadd.f64 d4, d22, d1          /* curtlx + 4096 */
    FLOOR r11, d5, d4
    add r11, r11, r12             /* wrapX */
    b .LxGeom
.LxNowrap:
    mov r11, #0                   /* wrapX = 0  */
    mov r12, #0                   /* no subtract */
.LxGeom:
    vadd.f64 d4, d20, d1          /* tx = fx + 4096 */
    FLOOR r10, d26, d4            /* bx0 = r10, rx0 = d26 */
    add r1, r10, #1               /* bx1 */
    vsub.f64 d27, d26, d0         /* rx1 = rx0 - 1.0 */
    cmp r10, r11
    subge r10, r10, r12
    cmp r1, r11
    subge r1, r1, r12
    and r10, r10, #255            /* bx0 & 255 */
    and r1, r1, #255              /* bx1 & 255 */
    SMOOTHSTEP d30, d26           /* sx */

    /* ── Y geometry (stich wrap folded in) ──────────────────────────────── */
    ldr r2, [r0, #A_PERIOD_Y]
    cmp r2, #0
    ble .LyNowrap
    lsl r2, r2, r5                /* periodY << octave */
    vadd.f64 d4, d23, d1          /* curtly + 4096 */
    FLOOR r14, d5, d4
    add r14, r14, r2              /* wrapY */
    b .LyGeom
.LyNowrap:
    mov r14, #0                   /* wrapY = 0  */
    mov r2, #0                    /* no subtract */
.LyGeom:
    vadd.f64 d4, d21, d1          /* ty = fy + 4096 */
    FLOOR r12, d28, d4            /* by0 = r12, ry0 = d28 */
    add r11, r12, #1              /* by1 */
    vsub.f64 d29, d28, d0         /* ry1 = ry0 - 1.0 */
    cmp r12, r14
    subge r12, r12, r2
    cmp r11, r14
    subge r11, r11, r2
    and r12, r12, #255            /* by0 & 255 */
    and r11, r11, #255            /* by1 & 255 */
    SMOOTHSTEP d31, d28           /* sy */

    /* ── Permutation (selector32) ──────────────────────────────────────── */
    ldr r2, [r0, #A_SELECTOR]
    ldr r14, [r2, r10, lsl #2]    /* i  = sel[bx0] */
    ldr r1, [r2, r1, lsl #2]      /* j  = sel[bx1] */
    add r10, r14, r11             /* i + by1 */
    ldr r10, [r2, r10, lsl #2]    /* b01 */
    add r14, r14, r12             /* i + by0 */
    ldr r14, [r2, r14, lsl #2]    /* b00 */
    add r11, r1, r11              /* j + by1 */
    ldr r11, [r2, r11, lsl #2]    /* b11 */
    add r12, r1, r12              /* j + by0 */
    ldr r12, [r2, r12, lsl #2]    /* b10 */

    /* ── Four channels (R, G, B, A) ──────────────────────────────────────
     * One cmp feeds all four accumulate vabseqs: the VFP arithmetic and the
     * `add` address math in a channel never write APSR. */
    cmp r8, #0
    NOISE_CHANNEL  0, d16
    NOISE_CHANNEL  8, d17
    NOISE_CHANNEL 16, d18
    NOISE_CHANNEL 24, d19

    /* ── Advance state for the next octave ─────────────────────────────── */
    vadd.f64 d20, d20, d20
    vadd.f64 d21, d21, d21
    vadd.f64 d22, d22, d22
    vadd.f64 d23, d23, d23
    /* weight -> weight/2 bitwise, no VFP divide: d25 (2^52) is one exponent
     * unit, so subtracting it from the weight's bit pattern exactly decrements
     * the biased exponent (2^-n stays exact for any count in the normal range).
     * d25 itself is never modified. */
    vsub.i64 d24, d24, d25

    add r5, r5, #1
    b .Loct

/* ════════════════════════════════════════════════════════════════════════════
 * Pack: given sums[4], finalVal = (sum + offset)*scale, +0.5, truncate, clamp.
 * fractal: offset=1.0, scale=127.5    turbulence: offset=0.0, scale=255.0
 * scale/offset/0.5 were cached in the frame once per call; d5-d7 are dead here
 * (the octave loop owns them), so a single vldm restores the triple.
 * Accs are live in d16-d19 (R G B A); output cursor comes back from S_DST.
 * ════════════════════════════════════════════════════════════════════════════ */
pack_pixel:
    ldr r2, [sp, #S_DST]
    vldm sp, {d5, d6, d7}           /* scale, offset, 0.5 */

    /* ch0 (R) d16 -> r12 */
    vadd.f64 d4, d16, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r12, s4
    usat r12, #8, r12

    /* ch1 (G) d17 -> r1 */
    vadd.f64 d4, d17, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r1, s4
    usat r1, #8, r1

    /* ch2 (B) d18 -> r14 */
    vadd.f64 d4, d18, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r14, s4
    usat r14, #8, r14

    orr r1, r14, r1, lsl #8         /* B | G<<8 */
    orr r1, r1, r12, lsl #16        /* | R<<16 */

    /* ch3 (A) d19 -> r12  (r8 stays the fractal flag) */
    vadd.f64 d4, d19, d6
    vmul.f64 d4, d4, d5
    vadd.f64 d4, d4, d7
    vcvt.s32.f64 s4, d4
    vmov r12, s4
    usat r12, #8, r12

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