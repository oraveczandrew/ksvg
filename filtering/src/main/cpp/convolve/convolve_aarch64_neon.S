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

.text
.align 2

/*
 * int ksvgConvolveGenericNeonAsm(
 *     const NeonConvolveParams* params, int* dst, const int* src);
 *
 * AArch64 ABI:
 *   x0 = params, x1 = dst, x2 = src
 *
 * NeonConvolveParams byte layout (hard contract, keep in sync):
 *   +0  width      (jint)
 *   +4  height     (jint)
 *   +8  kernel     (const float*, orderY * orderX)
 *   +16 orderX     (jint)
 *   +20 orderY     (jint)
 *   +24 targetX    (jint)
 *   +28 targetY    (jint)
 *   +32 divisor    (float)
 *   +36 bias       (float)
 *   +40 preserve   (jboolean; 0 = convolve alpha, nonzero = preserve alpha)
 *
 * Processes the interior rectangle:
 *   x in [targetX, width  - orderX  + targetX)
 *   y in [targetY, height - orderY  + targetY)
 *   four output pixels at a time.
 *
 * Returns:
 *   w0 = first x NOT processed on an interior row.
 */
.global ksvgConvolveGenericNeonAsm
.type ksvgConvolveGenericNeonAsm, %function
ksvgConvolveGenericNeonAsm:
    // Save all callee-saved GPRs we use (x19..x30 = 12 regs => 96 bytes) plus
    // the callee-saved FP low halves we clobber (d8..d15 = 8 regs => 128
    // bytes). Total frame 224 bytes, keeps the 16-byte stack alignment
    // required by AAPCS64. (Audit R2: v14/v15 accumulators used to leak.)
    sub     sp, sp, #224
    stp     x19, x20, [sp, #0]
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #48]
    stp     x27, x28, [sp, #64]
    stp     x29, x30, [sp, #80]
    stp     q8, q9, [sp, #96]
    stp     q10, q11, [sp, #128]
    stp     q12, q13, [sp, #160]
    stp     q14, q15, [sp, #192]

    mov     x19, x1  // dst
    mov     x20, x2  // src
    ldr     w22, [x0, #0]  // width
    ldr     w23, [x0, #4]  // height
    ldr     x21, [x0, #8]  // kernel
    ldr     w24, [x0, #16]  // orderX
    ldr     w25, [x0, #20]  // orderY
    ldr     w26, [x0, #24]  // targetX
    ldr     w27, [x0, #28]  // targetY
    ldr     s0, [x0, #32]  // divisor
    ldr     s1, [x0, #36]  // bias
    ldrb    w4, [x0, #40]  // preserve flag (0 = convolve alpha)

    // Constants. NOTE: multiply-by-reciprocal (not per-pixel fdiv): for
    // non-power-of-two divisors 1/d is inexact, so exact .5 ties may differ
    // by +-1 LSB from scalar division (device parity allows maxDelta=1 there).
    fmov    s2, #1.0
    fdiv    s2, s2, s0
    dup     v30.4s, v2.s[0]  // v30 = 1 / divisor
    mov     w0, #255
    scvtf   s3, w0
    fmul    s3, s3, s1
    dup     v31.4s, v3.s[0]  // v31 = bias * 255
    scvtf   s4, w0  // s4 = 255.0 (float), w0 still 255
    dup     v28.4s, v4.s[0]  // v28 = 255.0 (clamp upper bound)
    movi    v27.4s, #255  // v27 = 0x000000ff byte mask (B/G/R unpack)
    fmov    v29.4s, #0.5  // v29 = 0.5 (rounding bias)
    movi    v5.4s, #0  // v5 = 0.0 (clamp lower bound)

    // Interior bounds. Matches the C++ caller's interior rectangle:
    // x in [targetX, width  - orderX  + targetX + 1)
    // y in [targetY, height - orderY  + targetY + 1)
    sub     w28, w22, w24
    add     w28, w28, w26
    add     w28, w28, #1  // w28 = interiorXHi
    sub     w5, w23, w25
    add     w5, w5, w27
    add     w5, w5, #1  // w5  = interiorYHi

    mov     w29, w27  // y = targetY

.Ly:
    cmp     w29, w5
    b.ge    .Ldone

    mov     w30, w26  // x = targetX (block x)

.Lx:
    add     w6, w30, #4
    cmp     w6, w28
    b.gt    .Lrow_done

    // Block source base: src[(y - targetY) * width + (x - targetX)].
    sub     w7, w29, w27
    mul     w7, w7, w22
    sub     w8, w30, w26
    add     w7, w7, w8
    add     x10, x20, w7, uxtw #2  // x10 = block base (bytes)

    // Accumulators (R, G, B, A).
    movi    v14.4s, #0
    movi    v15.4s, #0
    movi    v16.4s, #0
    movi    v18.4s, #0

    mov     w9, #0  // ky
.Lky:
    cmp     w9, w25
    b.ge    .Lnormalize

    mul     w11, w9, w22  // ky * width
    add     x11, x10, w11, uxtw #2  // x11 = source row for this ky
    mul     w12, w9, w24  // ky * orderX
    add     x12, x21, w12, uxtw #2  // x12 = kernel row for this ky

    mov     w13, #0  // kx
.Lkx:
    cmp     w13, w24
    b.ge    .Lnext_ky

    // Four horizontally adjacent source pixels for this tap.
    add     x14, x11, w13, uxtw #2
    ld1     {v0.4s}, [x14]

    // Extract B/G/R/A as uint32 vectors.
    and     v1.16b, v0.16b, v27.16b  // B
    ushr    v2.4s, v0.4s, #8
    and     v2.16b, v2.16b, v27.16b  // G
    ushr    v3.4s, v0.4s, #16
    and     v3.16b, v3.16b, v27.16b  // R
    ushr    v6.4s, v0.4s, #24  // A (0..255 after shift)

    ucvtf   v1.4s, v1.4s
    ucvtf   v2.4s, v2.4s
    ucvtf   v3.4s, v3.4s
    ucvtf   v6.4s, v6.4s

    ldr     s4, [x12]  // kernel coefficient
    dup     v4.4s, v4.s[0]

    fmla    v14.4s, v1.4s, v4.4s
    fmla    v15.4s, v2.4s, v4.4s
    fmla    v16.4s, v3.4s, v4.4s
    fmla    v18.4s, v6.4s, v4.4s

    add     x12, x12, #4
    add     w13, w13, #1
    b       .Lkx

.Lnext_ky:
    add     w9, w9, #1
    b       .Lky

.Lnormalize:
    fmul    v14.4s, v14.4s, v30.4s
    fmul    v15.4s, v15.4s, v30.4s
    fmul    v16.4s, v16.4s, v30.4s
    fmul    v18.4s, v18.4s, v30.4s

    fadd    v14.4s, v14.4s, v31.4s
    fadd    v15.4s, v15.4s, v31.4s
    fadd    v16.4s, v16.4s, v31.4s
    fadd    v18.4s, v18.4s, v31.4s

    // Match the scalar clamp255 rounding convention: add 0.5, floor (frintm),
    // then clamp to [0,255].
    fadd    v14.4s, v14.4s, v29.4s
    fadd    v15.4s, v15.4s, v29.4s
    fadd    v16.4s, v16.4s, v29.4s
    fadd    v18.4s, v18.4s, v29.4s
    frintm  v14.4s, v14.4s
    frintm  v15.4s, v15.4s
    frintm  v16.4s, v16.4s
    frintm  v18.4s, v18.4s

    movi    v5.4s, #0  // zero for clamp
    fmax    v14.4s, v14.4s, v5.4s
    fmin    v14.4s, v14.4s, v28.4s  // v28 = 255.0
    fmax    v15.4s, v15.4s, v5.4s
    fmin    v15.4s, v15.4s, v28.4s
    fmax    v16.4s, v16.4s, v5.4s
    fmin    v16.4s, v16.4s, v28.4s
    fmax    v18.4s, v18.4s, v5.4s
    fmin    v18.4s, v18.4s, v28.4s

    fcvtzs  v14.4s, v14.4s
    fcvtzs  v15.4s, v15.4s
    fcvtzs  v16.4s, v16.4s
    fcvtzs  v18.4s, v18.4s

    // Alpha: preserve from source pixels or use the convolved channel,
    // selected by the preserve flag in w4.
    cmp     w4, #0
    b.eq    .Lalpha_convolved
    mul     w7, w29, w22
    add     w7, w7, w30
    add     x15, x20, w7, uxtw #2
    ld1     {v17.4s}, [x15]
    ushr    v17.4s, v17.4s, #24
    shl     v17.4s, v17.4s, #24
    b       .Lpack
.Lalpha_convolved:
    shl     v17.4s, v18.4s, #24
.Lpack:

    // Pack AARRGGBB.
    shl     v16.4s, v16.4s, #16  // R << 16
    shl     v15.4s, v15.4s, #8  // G << 8
    orr     v16.16b, v16.16b, v15.16b
    orr     v16.16b, v16.16b, v14.16b
    orr     v16.16b, v16.16b, v17.16b

    // Write dst (x..x+3, y).
    mul     w7, w29, w22
    add     w7, w7, w30
    add     x15, x19, w7, uxtw #2
    st1     {v16.4s}, [x15]

    add     w30, w30, #4
    b       .Lx

.Lrow_done:
    add     w29, w29, #1
    b       .Ly

.Ldone:
    mov     w0, w30  // interior row tail x (constant per row)

    ldp     q14, q15, [sp, #192]
    ldp     q12, q13, [sp, #160]
    ldp     q10, q11, [sp, #128]
    ldp     q8, q9, [sp, #96]
    ldp     x29, x30, [sp, #80]
    ldp     x27, x28, [sp, #64]
    ldp     x25, x26, [sp, #48]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp], #224
    ret

.size ksvgConvolveGenericNeonAsm, .-ksvgConvolveGenericNeonAsm
