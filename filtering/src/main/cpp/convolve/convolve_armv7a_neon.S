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
.fpu neon
.align 2

.global ksvgConvolveGenericNeonAsm32
.type ksvgConvolveGenericNeonAsm32, %function

    //       Generic ARMv7-A NEON feConvolveMatrix interior kernel (32-bit).
    //
    //       ABI:
    //       r0 = const Convolve::NeonConvolveParams32* (see convolve.h)
    //       r1 = jint*                        dst
    //       r2 = const jint*                  src
    //
    //       NeonConvolveParams32 byte layout (hard contract, keep in sync):
    //       +0  width      (jint/int32_t)
    //       +4  height     (jint/int32_t)
    //       +8  kernel     (const float*, orderY * orderX)
    //       +12 orderX     (jint)
    //       +16 orderY     (jint)
    //       +20 targetX    (jint)
    //       +24 targetY    (jint)
    //       +28 divisor    (float)
    //       +32 bias       (float)
    //       +36 preserve   (jboolean; 0 = convolve alpha, nonzero = preserve)
    //
    //       Processes the interior rectangle:
    //       x in [targetX, width  - orderX  + targetX)
    //       y in [targetY, height - orderY  + targetY)
    //       four output pixels at a time, immediately to the right of / below the
    //       caller's edge handling.  The kernel dimensions and anchor are fully
    //       runtime-variable; only the interior-validity guarantee is required.
    //
    //       Alpha is preserved from the corresponding source pixel when the
    //       preserve flag is nonzero, otherwise the alpha channel is convolved
    //       with the same normalize/round/clamp path as R/G/B. The alpha
    //       accumulator (q9, with q8 as channel temp; both caller-saved d16-d19)
    //       is always maintained so both modes share one loop.
    //
    //       The routine never writes the 0..3 leftover interior pixels at the end of a
    //       row.
    //
    //       Q-register allocation:
    //       q0 = source pixels / temp / broadcast
    //       q1 = B channel (uint32 -> float)
    //       q2 = G channel (uint32 -> float)
    //       q3 = R channel (uint32 -> float)
    //       q4 = B accumulator
    //       q5 = G accumulator
    //       q6 = R accumulator
    //       q7 = 0xFF mask (constant)
    //       q8 = A channel temp (uint32 -> float; caller-saved, no preserve needed)
    //       q9 = A accumulator (caller-saved, no preserve needed)
    //
    //       Returns:
    //       r0 = first x NOT processed on an interior row (constant per row).

ksvgConvolveGenericNeonAsm32:
    push    {r4-r11, r12, lr} // 10 words -> sp stays 8-byte aligned for vpush
    // Save callee-saved d8-d15 (q4-q7 accumulators/mask).
    // (Audit R7: used to leak.)
    vpush   {d8-d15}
    sub     sp, sp, #32

    //       Save callee-saved GPRs.
    mov     r4, r1 // r4  = dst
    mov     r5, r2 // r5  = src
    ldrb    r1, [r0, #36] // r1  = preserve flag
    str     r1, [sp, #28] // sp+28 = preserve (params ptr reused below)
    ldr     r6, [r0, #0] // r6  = width
    ldr     r7, [r0, #8] // r7  = kernel base
    ldr     r8, [r0, #12] // r8  = orderX
    ldr     r9, [r0, #16] // r9  = orderY
    ldr     r10, [r0, #20] // r10 = targetX
    ldr     r11, [r0, #24] // r11 = targetY

    //       Stack layout (32 bytes, 8-byte aligned for NEON spills):
    //       sp+0  = interiorXHi
    //       sp+4  = interiorYHi
    //       sp+8  = ky counter
    //       sp+12 = 1.0f / divisor (reciprocal)
    //       sp+16 = bias * 255.0f
    //       sp+20 = y counter
    //       sp+24 = x counter
    //       sp+28 = preserve flag (0 = convolve alpha)

    //       interiorXHi = width - orderX + targetX + 1.
    sub     r1, r6, r8
    add     r1, r1, r10
    add     r1, r1, #1
    str     r1, [sp, #0]

    //       interiorYHi = height - orderY + targetY + 1.
    ldr     r2, [r0, #4] // r2 = height
    sub     r3, r2, r9
    add     r3, r3, r11
    add     r3, r3, #1
    str     r3, [sp, #4]

    //       Pre-compute reciprocal: 1.0f / divisor -> sp+12.
    vldr    s0, [r0, #28]
    vmov.f32 s1, #1.0
    vdiv.f32 s0, s1, s0
    vstr    s0, [sp, #12]

    //       Pre-compute bias * 255.0f -> sp+16.
    vldr    s0, [r0, #32] // s0 = bias
    mov     r0, #255
    vmov    s1, r0
    vcvt.f32.u32 s1, s1 // s1 = 255.0f
    vmul.f32 s0, s0, s1
    vstr    s0, [sp, #16]

    //       0xFF mask in q7 (ARM32 safe: vdup from GPR avoids vmov.i32 sign-extension).
    mov     r0, #255
    vdup.32 q7, r0

    //       y = targetY.
    str     r11, [sp, #20]

.Ly:
    ldr     r2, [sp, #4] // r2 = interiorYHi
    ldr     r3, [sp, #20] // r3 = y
    cmp     r3, r2
    bge     .Ldone

    //       x = targetX.
    str     r10, [sp, #24]

.Lx:
    ldr     r0, [sp, #24] // r0 = x
    add     r2, r0, #4
    ldr     r3, [sp, #0] // r3 = interiorXHi
    cmp     r2, r3
    bgt     .Lrow_done

    //       Block base: src[(y - targetY) * width + (x - targetX)].
    ldr     r2, [sp, #20] // r2 = y
    sub     r2, r2, r11 // r2 = y - targetY
    mul     r2, r2, r6 // r2 = (y - targetY) * width
    ldr     r0, [sp, #24] // r0 = x
    sub     r0, r0, r10 // r0 = x - targetX
    add     r2, r2, r0 // r2 = linear offset
    add     r12, r5, r2, lsl #2 // r12 = src block base (bytes)

    //       Accumulators (B, G, R, A).
    vmov.i32 q4, #0
    vmov.i32 q5, #0
    vmov.i32 q6, #0
    vmov.i32 q9, #0

    //       ky = 0.
    mov     r0, #0
    str     r0, [sp, #8]

.Lky:
    ldr     r0, [sp, #8] // r0 = ky
    cmp     r0, r9 // r9 = orderY
    bge     .Lnormalize

    //       Source row for this ky: block_base + ky * width * 4.
    mul     r3, r0, r6 // r3 = ky * width
    add     r3, r12, r3, lsl #2 // r3 = block_base + ky * width * 4

    //       Kernel row for this ky: kernel + ky * orderX.
    mul     r2, r0, r8 // r2 = ky * orderX
    add     r2, r7, r2, lsl #2 // r2 = kernel row byte address

    //       kx = 0.
    mov     r0, #0

.Lkx:
    cmp     r0, r8
    bge     .Lnext_ky

    //       Compute source pixel address: src_row + kx.
    add     r1, r3, r0, lsl #2 // r1 = &src_row[kx] (byte address)
    vld1.32 {q0}, [r1]

    //       Extract B, G, R, A channels.
    vand    q1, q0, q7 // B
    vshr.u32 q2, q0, #8
    vand    q2, q2, q7 // G
    vshr.u32 q3, q0, #16
    vand    q3, q3, q7 // R
    vshr.u32 q8, q0, #24 // A (0..255 after shift)

    //       Convert to float.
    vcvt.f32.u32 q1, q1
    vcvt.f32.u32 q2, q2
    vcvt.f32.u32 q3, q3
    vcvt.f32.u32 q8, q8

    //       Load kernel coefficient and broadcast to all lanes of q0.
    vldr    s0, [r2]
    add     r2, r2, #4
    vdup.32 q0, d0[0]

    //       Accumulate.
    vmla.f32 q4, q1, q0
    vmla.f32 q5, q2, q0
    vmla.f32 q6, q3, q0
    vmla.f32 q9, q8, q0

    add     r0, r0, #1
    b       .Lkx

.Lnext_ky:
    ldr     r0, [sp, #8]
    add     r0, r0, #1
    str     r0, [sp, #8]
    b       .Lky

.Lnormalize:
    //       Multiply by reciprocal divisor (broadcast via q0).
    vldr    s0, [sp, #12]
    vdup.32 q0, d0[0]
    vmul.f32 q4, q4, q0
    vmul.f32 q5, q5, q0
    vmul.f32 q6, q6, q0
    vmul.f32 q9, q9, q0

    //       Add bias * 255.
    vldr    s0, [sp, #16]
    vdup.32 q0, d0[0]
    vadd.f32 q4, q4, q0
    vadd.f32 q5, q5, q0
    vadd.f32 q6, q6, q0
    vadd.f32 q9, q9, q0

    //       +0.5 rounding bias.
    vmov.f32 s0, #0.5
    vdup.32 q0, d0[0]
    vadd.f32 q4, q4, q0
    vadd.f32 q5, q5, q0
    vadd.f32 q6, q6, q0
    vadd.f32 q9, q9, q0

    //       Floor via FPSCR RMode manipulation (no frintm on ARMv7).
    //       Set round-toward-minus-infinity (bits 23:22 = 0b10).
    fmrx    r0, fpscr
    orr     r0, r0, #(2 << 22)
    fmxr    fpscr, r0

    //       Convert to signed integer (floor via RMode).
    vcvt.s32.f32 q4, q4
    vcvt.s32.f32 q5, q5
    vcvt.s32.f32 q6, q6
    vcvt.s32.f32 q9, q9

    //       Restore default FPSCR (round-to-nearest).
    bic     r0, r0, #(3 << 22)
    fmxr    fpscr, r0

    //       Clamp to [0, 255].
    vmov.i32 q0, #0
    vmax.s32 q4, q4, q0
    vmin.s32 q4, q4, q7 // q7 = 0xFF (255 in each lane)
    vmax.s32 q5, q5, q0
    vmin.s32 q5, q5, q7
    vmax.s32 q6, q6, q0
    vmin.s32 q6, q6, q7
    vmax.s32 q9, q9, q0
    vmin.s32 q9, q9, q7

    //       Alpha: preserve from source or use convolved channel (sp+28).
    ldr     r0, [sp, #28] // r0 = preserve flag
    cmp     r0, #0
    beq     .Lalpha_convolved
    ldr     r0, [sp, #20] // r0 = y
    ldr     r2, [sp, #24] // r2 = x
    mla     r3, r0, r6, r2 // r3 = y * width + x
    add     r3, r5, r3, lsl #2 // r3 = src pixel address
    vld1.32 {q0}, [r3]

    //       Extract alpha: (pixel >> 24) & 0xFF, then << 24.
    vshr.u32 q0, q0, #24
    vshl.i32 q0, q0, #24
    b       .Lpack
.Lalpha_convolved:
    vshl.i32 q0, q9, #24
.Lpack:

    //       Pack: (R << 16) | (G << 8) | B | A.
    vshl.i32 q6, q6, #16 // R << 16
    vshl.i32 q5, q5, #8 // G << 8
    vorr    q6, q6, q5
    vorr    q6, q6, q4
    vorr    q6, q6, q0

    //       Write dst (x..x+3, y).
    ldr     r0, [sp, #20] // r0 = y
    ldr     r2, [sp, #24] // r2 = x
    mla     r3, r0, r6, r2 // r3 = y * width + x
    add     r3, r4, r3, lsl #2 // r3 = dst pixel address
    vst1.32 {q6}, [r3]

    //       x += 4.
    ldr     r0, [sp, #24]
    add     r0, r0, #4
    str     r0, [sp, #24]
    b       .Lx

.Lrow_done:
    //       y += 1.
    ldr     r0, [sp, #20]
    add     r0, r0, #1
    str     r0, [sp, #20]
    b       .Ly

.Ldone:
    ldr     r0, [sp, #24] // r0 = first unprocessed x
    add     sp, sp, #32
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}

.size ksvgConvolveGenericNeonAsm32, .-ksvgConvolveGenericNeonAsm32
