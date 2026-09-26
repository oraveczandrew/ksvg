/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/*
 * ARMv7 / NEON implementation of ColorMatrix (4x5 matrix, SVG 0..1 semantics).
 * Bit-exact twin of KotlinKernels.colorMatrix: same FP op order (scalar VFP
 * division by 255 — NEON has no vector divide — left-to-right row evaluation,
 * no FMA), same LUT folding, same clamp255. Alpha never linearized.
 *
 * Structure mirrors arithmetic_composite_armv7a_neon.S: 4px non-linear loop,
 * 4px linear loop with nibble-scan LUT (16x16-byte table chunks, high-nibble
 * compare + vtbl + vbsl accumulate), scalar tails. d8-d15 are callee-saved:
 * vpush'd/vpop'd.
 *
 * 4px blocks keep every NEON quad-write on even quads (q0,q1,q2,q4 for data,
 * q6 acc, q8 coeff, q9 temp, q11 narrow scratch, q12-q14 consts, q15 widen
 * scratch); q3/q5/q7 are never written. s31 carries the 255.0 divisor
 * (q7 is unused, so no lane is sacrificed).
 *
 * Register map, main loops:
 *   r4 = src, r5 = dst, r6 = matrix base (read-only), r7 = width
 *   r11 = row pixels (pinned), r10 = row stride bytes, r9 = rows left
 *   r0 = srgbToLinear base, r1 = linearToSrgb base (linear path)
 *   Pixels d0(B),d1(G),d2(R),d3(A), low 4 lanes live; floats R=q0 G=q6 B=q2
 *   A=q4; q10 = row acc; q8 = coeff broadcast, q9 = acc temp
 *   q12 = 255.0, q13 = 0.0, q14 = 0.5 (rebuilt per 4px iteration)
 *   Narrow dests: R->d10 G->d11 (q5 scratch) B->d2 A->d3, then R/G moved to
 *   d0/d1 for the packer. R/G MUST NOT narrow into d0/d1 directly: d0/d1
 *   ARE q0 (the live R floats) — narrowing there destroys the R row inputs
 *   for the G/B/A rows. B->d2/A->d3 are safe (q1 is dead). Packed via
 *   vzip.8/vzip.16 + vst1.8 (16 bytes, exact, no over-store); linear encode
 *   scans read R from d10, G from d11, B from d2, A moved to d27.
 *   r2 = coeff word / const temp, r3 = table ptr (scan), r12 = tail counter,
 *   r14 = inner pixel counter.
 */

#include "asm_macros.S"

/*
 * Widen 4 byte lanes to one float vector (the block processes 4px).
 * Each channel uses a DIFFERENT scratch quad (back-to-back same-dest
 * widenings empirically lose all but the first on this core family).
 * Clobbers the named scratch.
 */
.macro WIDEN4_R dIn
    vmovl.u8 q15, \dIn
    vmovl.u16 q0, d30
    vcvt.f32.u32 q0, q0
.endm
.macro WIDEN4_G dIn
    vmovl.u8 q15, \dIn
    vmovl.u16 q6, d30
    vcvt.f32.u32 q6, q6
.endm
.macro WIDEN4_B dIn
    vmovl.u8 q15, \dIn
    vmovl.u16 q2, d30
    vcvt.f32.u32 q2, q2
.endm
.macro WIDEN4_A dIn
    vmovl.u8 q15, \dIn
    vmovl.u16 q4, d30
    vcvt.f32.u32 q4, q4
.endm

/*
 * Divide the 16 live float lanes (R=q0 G=q6 B=q2 A=q4) by s31 (255.0).
 * Scalar VFP per lane: NEON has no vector divide. q3/q5/q6/q7 lanes are not
 * resident, so no s31 sacrifice or fixup is needed. Clobbers nothing else.
 */
.macro DIV255
    vdiv.f32 s0, s0, s31
    vdiv.f32 s1, s1, s31
    vdiv.f32 s2, s2, s31
    vdiv.f32 s3, s3, s31
    vdiv.f32 s8, s8, s31
    vdiv.f32 s9, s9, s31
    vdiv.f32 s10, s10, s31
    vdiv.f32 s11, s11, s31
    vdiv.f32 s16, s16, s31
    vdiv.f32 s17, s17, s31
    vdiv.f32 s18, s18, s31
    vdiv.f32 s19, s19, s31
    vdiv.f32 s24, s24, s31
    vdiv.f32 s25, s25, s31
    vdiv.f32 s26, s26, s31
    vdiv.f32 s27, s27, s31
.endm

/*
 * Rebuild clamp constants: q12 = 255.0, q13 = 0.0, q14 = 0.5, plus s31 =
 * 255.0 for DIV255 (see above). Clobbers r2.
 */
.macro ROWCONSTS
    movw    r2, #0x0000
    movt    r2, #0x437f
    vdup.32 q12, r2
    veor    q13, q13, q13
    vmov.f32 q14, #0.5
    vmov    s31, r2
.endm

/*
 * One 4-lane matrix row into q6:
 * q6 = m0*R + m1*G + m2*B + m3*A + m4, coefficients from [r6 + o*].
 * Left-to-right order matches the reference; no FMA.
 * Inputs fixed: R=q0 G=q6 B=q2 A=q4. Clobbers q8, q9, r2.
 */
.macro MATROW4 o0, o1, o2, o3, o4
    ldr     r2, [r6, #\o0]
    vdup.32 q8, r2
    vmul.f32 q10, q0, q8
    ldr     r2, [r6, #\o1]
    vdup.32 q8, r2
    vmul.f32 q9, q6, q8
    vadd.f32 q10, q10, q9
    ldr     r2, [r6, #\o2]
    vdup.32 q8, r2
    vmul.f32 q9, q2, q8
    vadd.f32 q10, q10, q9
    ldr     r2, [r6, #\o3]
    vdup.32 q8, r2
    vmul.f32 q9, q4, q8
    vadd.f32 q10, q10, q9
    ldr     r2, [r6, #\o4]
    vdup.32 q8, r2
    vadd.f32 q10, q10, q8
.endm

/*
 * Clamp q10 to [0,255] with q12/q13 (255/0), round half-up with q14 (0.5)
 * and narrow to the low 4 bytes of d-reg dOut (high 4 lanes ignored by the
 * packer). Matches clamp255(). Clobbers q11 (d22/d23, dead pre-narrow).
 */
.macro NARROW4 dOut
    vmul.f32 q10, q10, q12
    vmax.f32 q10, q10, q13
    vmin.f32 q10, q10, q12
    vadd.f32 q10, q10, q14
    vcvt.s32.f32 q10, q10
    vqmovn.s32 d22, q10
    vqmovn.s32 d23, q10
    vqmovun.s16 \dOut, q11
.endm

/*
 * Nibble-scan one 8-lane channel through the 256-byte table at [rT]:
 * 16 iterations over 16-byte chunks, high-nibble compare + vtbl + vbsl.
 * Result accumulates in dAcc (zero it first). Clobbers d14,d15,d28,d29,d30,
 * r3, r12. d31 must hold #15.
 */
.macro LUTSCAN dIn, dAcc, rT
    mov     r3, \rT
    mov     r12, #0
.Lscan_\@:
    vld1.8  {d14, d15}, [r3]!
    vdup.8  d30, r12
    vshr.u8 d29, \dIn, #4
    vceq.u8 d29, d29, d30
    vand    d28, \dIn, d31
    vtbl.8  d28, {d14, d15}, d28
    vbsl    d29, d28, \dAcc
    vmov    \dAcc, d29
    add     r12, #1
    cmp     r12, #16
    bne     .Lscan_\@
    sub     r3, r3, #256
.endm

.text
.p2align 5

/*
 * void applyColorMatrixNeon(
 *     const jint* src, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     const jfloat* matrix, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * ARMv7a ABI:
 *   r0 = src, r1 = dst, r2 = width, r3 = clipLeft
 *   stack: clipTop, clipRight, clipBottom, matrix, useLinear,
 *     srgbToLinear, linearToSrgb
 */
.globl SYM(applyColorMatrixNeon)
TYPE(SYM(applyColorMatrixNeon), %function)
SYM(applyColorMatrixNeon):
    push    {r4-r11, lr}
    vpush   {d8-d15}
    sub     sp, sp, #16
    mov     r7, r2
    mov     r8, r3               /* clipLeft (r0-r3 carry src, dst, width, clipLeft) */

    ldr     r9, [sp, #116]       /* clipTop */
    ldr     r10, [sp, #120]      /* clipRight */
    ldr     r11, [sp, #124]      /* clipBottom */
    ldr     r6, [sp, #128]       /* matrix */
    mov     r4, r0
    mov     r5, r1
    ldr     r0, [sp, #136]       /* srgbToLinear */
    ldr     r1, [sp, #140]       /* linearToSrgb */

    mla     r2, r9, r7, r8
    add     r4, r4, r2, lsl #2
    add     r5, r5, r2, lsl #2
    sub     r11, r10, r8         /* row pixels (pinned) */
    cmp     r11, #0
    beq     .Ldone               /* empty width clip: nothing to do */
    lsl     r10, r7, #2          /* row stride bytes */
    ldr     r9, [sp, #124]       /* clipBottom */
    ldr     r2, [sp, #116]       /* clipTop */
    sub     r9, r9, r2           /* row count */
    cmp     r9, #0
    beq     .Ldone               /* empty height clip: nothing to do */
    ldrb    r3, [sp, #132]       /* useLinear (jboolean: upper bytes unspecified) */

    cmp     r3, #0
    bne     .Llinear_rows

.Lnonlin_rows:
    cmp     r9, #1
    beq     .Llast_row_nonlin    /* last row: scalar (no 4px over-read past buffer) */
    mov     r14, r11

.Lnonlin_vec:
    cmp     r14, #4
    blo     .Lnonlin_tail
    vld4.8  {d0, d1, d2, d3}, [r4]
    add     r4, r4, #16

    // Widen B,G,R,A bytes (low 4 lanes = px0-3) to floats.
    // vld4 lanes: d0=B d1=G d2=R d3=A — widened straight into R=q0 G=q6
    // B=q2 A=q4 (each macro clobbers q15 only, so sources stay intact).
    WIDEN4_A d3
    WIDEN4_B d0
    WIDEN4_G d1
    WIDEN4_R d2
    ROWCONSTS
    DIV255

    // R,G,B,A rows. R->d10, G->d11 (q5 is dead scratch — d0/d1 alias q0,
    // the live R floats, so narrowing there would destroy the R inputs of
    // the later rows); B->d2, A->d3 (q1 is dead). Then R/G move to d0/d1
    // for the packer.
    MATROW4 0, 4, 8, 12, 16
    NARROW4 d10
    MATROW4 20, 24, 28, 32, 36
    NARROW4 d11
    MATROW4 40, 44, 48, 52, 56
    NARROW4 d2
    MATROW4 60, 64, 68, 72, 76
    NARROW4 d3
    vmov    d0, d10
    vmov    d1, d11

    // Pack 4xARGB (16 bytes, exact): zip B,G and R,A pairs, then 16-bit zip
    // into [B,G,R,A] byte order (ARGB_8888 words are little-endian).
    vzip.8  d2, d1
    vzip.8  d0, d3
    vzip.16 d2, d0
    vst1.8  {d2}, [r5]!
    vst1.8  {d0}, [r5]!
    sub     r14, r14, #4
    b       .Lnonlin_vec

.Lnonlin_tail:
    cmp     r14, #0
    beq     .Lnext_row_nonlin
    mov     r12, r14
    b       .Ltail_scalar_nonlin

.Llast_row_nonlin:
    mov     r12, r11
    b       .Ltail_scalar_nonlin

.Lnext_row_nonlin:
    add     r4, r4, r10
    sub     r4, r4, r11, lsl #2
    add     r5, r5, r10
    sub     r5, r5, r11, lsl #2
    subs    r9, r9, #1
    bne     .Lnonlin_rows
    b       .Ldone

.Llinear_rows:
    cmp     r9, #1
    beq     .Llast_row_linear    /* last row: scalar (no 4px over-read past buffer) */
    mov     r14, r11

.Llinear_vec:
    cmp     r14, #4
    blo     .Llinear_tail
    vld4.8  {d0, d1, d2, d3}, [r4]
    add     r4, r4, #16

    // Nibble-scan R,G,B through sRGB->linear (alpha bypasses the LUT).
    vmov.i8 q8, #0
    vmov.i8 q9, #0
    vmov.i8 q10, #0
    vmov.i8 d31, #15
    LUTSCAN d2, d16, r0
    LUTSCAN d1, d17, r0
    LUTSCAN d0, d18, r0

    WIDEN4_A d3
    WIDEN4_R d16
    WIDEN4_G d17
    WIDEN4_B d18
    ROWCONSTS
    DIV255

    MATROW4 0, 4, 8, 12, 16
    NARROW4 d10
    MATROW4 20, 24, 28, 32, 36
    NARROW4 d11
    MATROW4 40, 44, 48, 52, 56
    NARROW4 d2
    MATROW4 60, 64, 68, 72, 76
    NARROW4 d3

    // Encode R,G,B through linear->sRGB (nibble-scan), A stays raw.
    // Narrowed R/G live in d10/d11 (see above); B in d2, A in d3.
    // Pack slots are d24=R d25=G d26=B d27=A for the vzip below.
    vmov.i8 q12, #0
    vmov.i8 d26, #0
    vmov.i8 d31, #15
    LUTSCAN d10, d24, r1
    LUTSCAN d11, d25, r1
    LUTSCAN d2, d26, r1
    vmov    d27, d3

    vzip.8  d26, d25
    vzip.8  d24, d27
    vzip.16 d26, d24
    vst1.8  {d26}, [r5]!
    vst1.8  {d24}, [r5]!
    sub     r14, r14, #4
    b       .Llinear_vec

.Llinear_tail:
    cmp     r14, #0
    beq     .Lnext_row_linear
    mov     r12, r14
    b       .Ltail_scalar_linear

.Llast_row_linear:
    mov     r12, r11
    b       .Ltail_scalar_linear

.Lnext_row_linear:
    add     r4, r4, r10
    sub     r4, r4, r11, lsl #2
    add     r5, r5, r10
    sub     r5, r5, r11, lsl #2
    subs    r9, r9, #1
    bne     .Llinear_rows
    b       .Ldone

// Scalar tail: r12 = remaining pixels; one pixel in r2; channels via ubfx,
// scalar VFP math with coefficients from [r6], fmax/fmin clamp, packed with
// orr. Linear path adds ldrb LUT steps (R,G,B only).
.macro TAIL_INPUTS linear
    ldr     r2, [r4], #4
    mov     r3, #0
    ubfx    r7, r2, #0, #8
    .if \linear
    ldrb    r7, [r0, r7]
    .endif
    vmov    s0, r7
    vcvt.f32.u32 s0, s0
    vdiv.f32 s0, s0, s8
    ubfx    r7, r2, #8, #8
    .if \linear
    ldrb    r7, [r0, r7]
    .endif
    vmov    s1, r7
    vcvt.f32.u32 s1, s1
    vdiv.f32 s1, s1, s8
    ubfx    r7, r2, #16, #8
    .if \linear
    ldrb    r7, [r0, r7]
    .endif
    vmov    s2, r7
    vcvt.f32.u32 s2, s2
    vdiv.f32 s2, s2, s8
    ubfx    r7, r2, #24, #8
    vmov    s3, r7
    vcvt.f32.u32 s3, s3
    vdiv.f32 s3, s3, s8
.endm

.macro TAIL_ROW o0, o1, o2, o3, o4, shift, enc
    ldr     r7, [r6, #\o0]
    vmov    s4, r7
    vmul.f32 s5, s2, s4
    ldr     r7, [r6, #\o1]
    vmov    s4, r7
    vmul.f32 s4, s1, s4
    vadd.f32 s5, s5, s4
    ldr     r7, [r6, #\o2]
    vmov    s4, r7
    vmul.f32 s4, s0, s4
    vadd.f32 s5, s5, s4
    ldr     r7, [r6, #\o3]
    vmov    s4, r7
    vmul.f32 s4, s3, s4
    vadd.f32 s5, s5, s4
    ldr     r7, [r6, #\o4]
    vmov    s4, r7
    vadd.f32 s5, s5, s4
    vmul.f32 s5, s5, s8
    // Scalar-VFP clamp (no scalar vmax/vmin on ARMv7 VFP; NaN-free inputs
    // make the compare/select exactly fmax/fmin).
    vcmp.f32 s5, s9
    vmrs    APSR_nzcv, fpscr
    vmovlt.f32 s5, s9
    vcmp.f32 s5, s8
    vmrs    APSR_nzcv, fpscr
    vmovgt.f32 s5, s8
    vadd.f32 s5, s5, s10
    vcvt.s32.f32 s5, s5
    vmov    r7, s5
    .if \enc
    ldrb    r7, [r1, r7]
    .endif
    and     r7, r7, #0xff
    orr     r3, r3, r7, lsl #\shift
.endm

.Ltail_setup_nonlin:
    movw    r7, #0x0000
    movt    r7, #0x437f
    vmov    s8, r7
    mov     r7, #0
    vmov    s9, r7
    vmov.f32 s10, #0.5
    b       .Ltail_nonlin_loop

.Ltail_setup_linear:
    movw    r7, #0x0000
    movt    r7, #0x437f
    vmov    s8, r7
    mov     r7, #0
    vmov    s9, r7
    vmov.f32 s10, #0.5
    b       .Ltail_linear_loop

.Ltail_scalar_nonlin:
    b       .Ltail_setup_nonlin

.Ltail_scalar_linear:
    b       .Ltail_setup_linear

.Ltail_nonlin_loop:
    TAIL_INPUTS 0
    TAIL_ROW 0, 4, 8, 12, 16, 16, 0
    TAIL_ROW 20, 24, 28, 32, 36, 8, 0
    TAIL_ROW 40, 44, 48, 52, 56, 0, 0
    TAIL_ROW 60, 64, 68, 72, 76, 24, 0
    str     r3, [r5], #4
    subs    r12, r12, #1
    bne     .Ltail_nonlin_loop
    b       .Lnext_row_nonlin

.Ltail_linear_loop:
    TAIL_INPUTS 1
    TAIL_ROW 0, 4, 8, 12, 16, 16, 1
    TAIL_ROW 20, 24, 28, 32, 36, 8, 1
    TAIL_ROW 40, 44, 48, 52, 56, 0, 1
    TAIL_ROW 60, 64, 68, 72, 76, 24, 0
    str     r3, [r5], #4
    subs    r12, r12, #1
    bne     .Ltail_linear_loop
    b       .Lnext_row_linear

.Ldone:
    add     sp, sp, #16
    vpop    {d8-d15}
    pop     {r4-r11, pc}
GNU_STACK
