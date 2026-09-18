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

.syntax unified
.arm
.fpu neon
.text
.align 2
#include "lighting_armv7a_pow_macros.S"
.global ksvgLightingDistantSpecularRowNeon32
.type ksvgLightingDistantSpecularRowNeon32, %function

// void ksvgLightingDistantSpecularRowNeon32(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params, float exponent)
//
// AAPCS32 (softfp armeabi-v7a):
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params, [sp, #8] = exponent (7th arg).
//
// LightingParams layout (lighting.cpp, hard contract):
//   +0 invDx  +4 invDy  +8 k  +12 lx  +16 ly  +20 lz
//   +24 lr    +28 lg    +32 lb +36 ss
//
// Straight (non-premultiplied) distant-specular row: the Sobel/normalize/dot
// block is the bit-for-bit verbatim copy of the parity validated
// ksvgLightingDistantDiffuseRowNeon32 (exact scalar add order for the Sobel
// sums), with ONE deliberate exception: the normalization divides by 1.0
// (nLen) exactly like the Kotlin reference KotlinKernels.kt:520-521 -- the
// diffuse copy's k/nLen dividend is a latent k==1-only artifact. The lighting
// operand is the loop-invariant half vector h = normalize(lx, ly, lz + 1) computed once in the prologue, and the
// clamped ndoth feeds a per-lane scalar DOUBLE libm pow (the reference uses
// Kotlin Math.pow / C++ std::pow double math:
//
//   p     = pow(ndoth, exponent)          (scalar double per lane)
//   I     = clamp01(k * p)
//   R/G/B = round(lr/lg/lb * I)           (floor(x+0.5) for non-negative)
//   A     = max(R, G, B)
//
// 4 output pixels / main iteration (multiple of 4 count, like Neon32).
// `bl pow` clobbers ALL caller-saved state: r0-r3, r12, lr, and the VFP
// caller-saved registers d0-d7 (q0-q3) and d16-d31 (q8-q15). The source /
// dest pointers and the handful of loop invariants must therefore live in
// callee-saved GPRs (r4-r11) and VFP registers d8-d15 (q4-q7). q8-q14 and
// the VFP scratch d0-d7 are rebuilt after the pow block.
//
// Register map (loop-invariant):
//   r4 = count          r5 = params+32    r7 = scratch (mask / L2S pixel)
//   r8 = srcT           r9 = srcM         r10 = srcB
//   r11 = dst           r12 = address temp (taps, pre-pow only)
//   q4 = ss        q5 = scaleX = 1/invDx   q6 = scaleY = 1/invDy
//   q7 = k         q8 = hx      q9 = hy    q10 = hz
//   q11 = lr       q12 = lg     q13 = lb   q14 = 1.0f
//   q0-q3, q15     = scratch / rebuilt after pow
//
// Stack frame (40 bytes, after push {r4-r11,r12,lr} + vpush {d8-d15}):
//   [sp, #0..#15]   ndoth stash -> in-place pow results
//   [sp, #16..23]   exponent (double)
//   [sp, #24] hx    [sp, #28] hy    [sp, #32] hz
//   [sp, #36]       spare (keeps 8-byte frame alignment)
// Count reads at [sp, #104], params at [sp, #108] (offsets from entry,
// before the #40 sub). Exponent is at [sp,#112] from entry.

ksvgLightingDistantSpecularRowNeon32:
    push    {r4-r11, r12, lr}      // 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               // preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         // count
    ldr     r5, [sp, #108]         // params
    vldr    s0, [sp, #112]         // exponent (entry offset, pre-sub!)
    cmp     r4, #0
    beq     .Lexit0

    sub     sp, sp, #40            // local scratch frame (8-byte aligned)

    // Move the incoming source/dest pointers into callee-saved GPRs: `bl pow`
    // below clobbers the caller-saved r0-r3, so the row pointers must live in
    // r8-r11 for the whole loop (mirrors the aarch64 x19-x22 move).
    mov     r8, r0                  // srcT
    mov     r9, r1                  // srcM
    mov     r10, r2                 // srcB
    mov     r11, r3                 // dst

    // Exponent (softfp stack argument, loaded pre-sub above) -> double on
    // the stack, before the param loads below clobber q0 (d0/s0 holder).
    vcvt.f64.f32 d0, s0
    vstr    d0, [sp, #16]

    // h = normalize(lx, ly, lz + 1), computed once (loop invariant).
    // hLen^2 association: (lx^2 + ly^2) + hz_raw^2 via separate muls/adds
    // (matches the x86/64 reference op order), single-precision sqrt.
    vldr    s16, [r5, #12]         // lx
    vldr    s17, [r5, #16]         // ly
    vldr    s18, [r5, #20]         // lz
    vmov.f32 s19, #1.0
    vadd.f32 s18, s18, s19         // hz_raw = lz + 1
    vmul.f32 s20, s17, s17         // ly^2
    vmul.f32 s21, s16, s16         // lx^2
    vadd.f32 s19, s20, s21         // lx^2 + ly^2
    vmul.f32 s20, s18, s18         // hz_raw^2
    vadd.f32 s19, s19, s20         // hLen^2
    vsqrt.f32 s19, s19             // hLen (single precision)
    vcmp.f32 s19, #0.0
    vmrs    APSR_nzcv, FPSCR
    beq     .Lh_zero
    vdiv.f32 s16, s16, s19         // hx
    vdiv.f32 s17, s17, s19         // hy
    vdiv.f32 s18, s18, s19         // hz
.Lh_zero:
    vstr    s16, [sp, #24]
    vstr    s17, [sp, #28]
    vstr    s18, [sp, #32]

    // Load Params (same order as Neon32):
    //   q0 = [invDx, invDy, k, lx]; q1 = [ly, lz, lr, lg]; d4 = [lb, ss]
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]             // r5 now points at params+32

    // scaleX = 1/invDx, scaleY = 1/invDy (single-precision VFP, VFPv3 ok)
    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     // ss
    vdup.32 q5, d0[0]     // scaleX
    vdup.32 q6, d0[1]     // scaleY
    vdup.32 q7, d1[0]     // k
    vdup.32 q11, d3[0]    // lr
    vdup.32 q12, d3[1]    // lg
    vdup.32 q13, d4[0]    // lb
    vmov.f32 q14, #1.0    // one

    // hx/hy/hz come from the stack (the definitive h values). GPR-based
    // VDUP (no Qd/Dm overlap hazard: VDUP Qd,Dm[x] with overlapping
    // registers is UNPREDICTABLE, cf. the point-diffuse armv7a findings).
    ldr     r12, [sp, #24]         // hx bits
    vdup.32 q8, r12
    ldr     r12, [sp, #28]         // hy bits
    vdup.32 q9, r12
    ldr     r12, [sp, #32]         // hz bits
    vdup.32 q10, r12

.Lloop:
    // ---- Row T ----
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tm

    add     r12, r8, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          // top sum

    // ---- Row M ----
    vld1.32 {q0}, [r9]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // ml

    add     r12, r9, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // mr

    // ---- Row B ----
    vld1.32 {q0}, [r10]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // bl

    add     r12, r10, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // bm

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br

    // Exact scalar bottom sum: bl + bm + bm + br
    vadd.f32 q14, q0, q1
    vadd.f32 q14, q14, q1
    vadd.f32 q14, q14, q2        // bottom sum
    vsub.f32 q3, q14, q3         // dyRel
    vmov    q14, q3               // preserve dyRel while recomputing dx

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #8
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tr

    vld1.32 {q2}, [r9]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // ml

    add     r12, r9, #8
    vld1.32 {q3}, [r12]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          // mr

    vadd.f32 q0, q0, q2         // tl + ml
    vadd.f32 q0, q0, q2         // (tl + ml) + ml
    vadd.f32 q1, q1, q3         // tr + mr
    vadd.f32 q1, q1, q3         // (tr + mr) + mr

    add     r12, r10, #0
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // bl
    vadd.f32 q0, q0, q2         // + bl

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br
    vadd.f32 q1, q1, q2         // + br
    vsub.f32 q0, q1, q0         // dxRel
    vmov    q3, q14              // restore dyRel

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          // q0 = dx
    vmul.f32 q1, q3, q6          // q1 = dy
    // ---- Normalize exactly like Kotlin reference ----
    // nLen = sqrt(nx*nx + ny*ny + 1); nx/=nLen; ny/=nLen; nz=1/nLen
    vneg.f32 q0, q0              // nx0
    vneg.f32 q1, q1              // ny0
    vmul.f32 q2, q0, q0
    vmul.f32 q3, q1, q1
    vadd.f32 q2, q2, q3
    vmov.f32 q14, #1.0
    vadd.f32 q2, q2, q14         // nLen^2

    // ARMv7 VFP sqrt/div are scalar; normalize four lanes exactly.
    // Dividend is TRUE 1.0 (NOT k like the diffuse copy): the Kotlin
    // reference divides by the real nLen (nx/=nLen; ny/=nLen; nz/=nLen).
    vsqrt.f32 s12, s8
    vsqrt.f32 s13, s9
    vsqrt.f32 s14, s10
    vsqrt.f32 s15, s11
    vmov.f32 q2, #1.0
    vdiv.f32 s12, s8, s12
    vdiv.f32 s13, s9, s13
    vdiv.f32 s14, s10, s14
    vdiv.f32 s15, s11, s15

    // q3 now contains invLen = 1/nLen.
    vmul.f32 q0, q0, q3          // normalized nx
    vmul.f32 q1, q1, q3          // normalized ny
    vmov q14, q3                 // normalized nz = invLen

    // Kotlin dot with the half vector h (q8-q10): nx*hx + ny*hy + nz*hz
    vmul.f32 q2, q0, q8
    vmul.f32 q15, q1, q9
    vadd.f32 q2, q2, q15
    vmul.f32 q15, q14, q10
    vadd.f32 q2, q2, q15
    vmov.f32 q14, #1.0           // restore one

    // ---- ndoth = max(dot, 0) ----
    veor    q15, q15, q15
    vmax.f32 q2, q2, q15         // ndoth (clamped, non-negative)

    // ---- per-lane scalar double pow (reference Math.pow semantics) ----
    vst1.32 {q2}, [sp]           // stash ndoth at [sp, #0..#15]
    // ---- 4-lane scalar VFP pow (no bl, invariants survive) ----
    vldr    d1, [sp, #16]        // double exponent
    vcvt.f32.f64 s1, d1          // s1 = exponent float
    vldr    s0, [sp, #0]
    POW1_VFP
    vstr    s0, [sp, #0]

    vldr    s0, [sp, #4]
    POW1_VFP
    vstr    s0, [sp, #4]

    vldr    s0, [sp, #8]
    POW1_VFP
    vstr    s0, [sp, #8]

    vldr    s0, [sp, #12]
    POW1_VFP
    vstr    s0, [sp, #12]

    // ---- intensity = clamp01(k * p) ----
    vld1.32 {q2}, [sp]           // q2 = p (in-place pow results)
    vmul.f32 q2, q2, q7          // k * p
    veor    q15, q15, q15
    vmax.f32 q2, q2, q15
    vmin.f32 q2, q2, q14         // q2 = intensity

    // ---- Pack ARGB ----
    vmul.f32 q1, q2, q11          // outR
    vmul.f32 q0, q2, q12          // outG
    vmul.f32 q3, q2, q13          // outB
    // Kotlin roundToInt() for nonnegative values: floor(x + 0.5).
    vmov.f32 q14, #0.5
    vadd.f32 q1, q1, q14
    vadd.f32 q0, q0, q14
    vadd.f32 q3, q3, q14
    vcvt.s32.f32 q1, q1
    vcvt.s32.f32 q0, q0
    vcvt.s32.f32 q3, q3

    vshl.u32 q1, q1, #16
    vshl.u32 q0, q0, #8
    vorr    q3, q3, q1
    vorr    q3, q3, q0            // q3 = [0, R, G, B] (alpha byte = 0)

    // alpha = max(R,G,B) bytes (straight form, NOT premultiplied)
    mov     r7, #0xFF
    vdup.32 q0, r7                // 0x000000FF byte mask
    vand    q1, q3, q0            // B
    vshr.u32 q15, q3, #8
    vand    q15, q15, q0          // G
    vshr.u32 q2, q3, #16
    vand    q2, q2, q0            // R
    vmax.u8 q1, q1, q15
    vmax.u8 q1, q1, q2
    vshl.u32 q1, q1, #24
    vorr    q3, q3, q1            // alpha = max(R,G,B)

    vst1.32 {q3}, [r11]!

    add     r8, r8, #16
    add     r9, r9, #16
    add     r10, r10, #16
    subs    r4, r4, #4
    bne     .Lloop
    b       .Ldone                  // loop done: sp is offset by #40, use .Ldone

.Lexit0:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.Ldone:
    add     sp, sp, #40
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingDistantSpecularRowNeon32, .-ksvgLightingDistantSpecularRowNeon32

// ---------------------------------------------------------------------------
// Linear-light output support (useLinear): identical Sobel/normalize/ndoth/pow
// math to Neon32, then a scalar per-pixel linear->sRGB LUT conversion of ALL
// four bytes (R, G, B AND the alpha byte). The alpha is computed as
// max(Rlin, Glin, Blin) BEFORE the L2S (like the aarch64 *Neon64Linear row);
// the L2S LUT is monotonic so LUT[max(linear)] == max(sRGB), matching the
// Kotlin reference maxOf() AFTER the L2S map.
//
// void ksvgLightingDistantSpecularRowNeon32Linear(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params,
//   float exponent, const uint8_t* linearToSrgb)
//
// AAPCS32 (softfp armeabi-v7a):
//   r0 = srcT, r1 = srcM, r2 = srcB, r3 = dst
//   [sp, #0] = count, [sp, #4] = params, [sp, #8] = exponent (float),
//   [sp, #12] = linearToSrgb.
// NOTE: this (exponent, LUT) order matches the shared C++ dispatch and the
// aarch64 twin (an earlier revision used the (LUT, exponent) order while the
// kernel was never dispatched; fixed when wiring it up).
//
// Register map (loop-invariant): same as Neon32, plus:
//   r6 = linearToSrgb LUT base (r7 and r12 remain the only closure scratch).
// ---------------------------------------------------------------------------

.macro L2S_ARGB_PIXEL inr
    // \inr = 0xAARRGGBB, converted in place through the LUT at r6.
    // Scratch: r12 only. Preserves r8-r11 (LUT base is r6).
    mov     r12, \inr, lsr #16        // R index (bits 23-16)
    and     r12, r12, #0xFF
    ldrb    r12, [r6, r12]            // sR
    bic     \inr, \inr, #0x00FF0000
    lsl     r12, r12, #16
    orr     \inr, \inr, r12

    mov     r12, \inr, lsr #8         // G index (bits 15-8)
    and     r12, r12, #0xFF
    ldrb    r12, [r6, r12]            // sG
    bic     \inr, \inr, #0x0000FF00
    lsl     r12, r12, #8
    orr     \inr, \inr, r12

    and     r12, \inr, #0xFF          // B index (bits 7-0)
    ldrb    r12, [r6, r12]            // sB
    bic     \inr, \inr, #0x000000FF
    orr     \inr, \inr, r12

    mov     r12, \inr, lsr #24        // alpha index (bits 31-24, max-linear)
    and     r12, r12, #0xFF
    ldrb    r12, [r6, r12]            // sA
    bic     \inr, \inr, #0xFF000000
    lsl     r12, r12, #24
    orr     \inr, \inr, r12
    str     \inr, [r11], #4
.endm

.global ksvgLightingDistantSpecularRowNeon32Linear
.type ksvgLightingDistantSpecularRowNeon32Linear, %function

ksvgLightingDistantSpecularRowNeon32Linear:
    push    {r4-r11, r12, lr}      // 10 words -> sp stays 8-byte aligned for vpush
    vpush   {d8-d15}               // preserve callee-saved d8-d15 (q4-q7)

    ldr     r4, [sp, #104]         // count
    ldr     r5, [sp, #108]         // params
    vldr    s0, [sp, #112]         // exponent (entry offset, pre-sub!)
    ldr     r6, [sp, #116]         // linearToSrgb LUT (entry offset, pre-sub!)
    cmp     r4, #0
    beq     .Llin_exit0

    sub     sp, sp, #40            // local scratch frame (8-byte aligned)

    // Move the incoming source/dest pointers into callee-saved GPRs: `bl pow`
    // below clobbers the caller-saved r0-r3, so the row pointers must live in
    // r8-r11 for the whole loop (mirrors the aarch64 x19-x22 move).
    mov     r8, r0                  // srcT
    mov     r9, r1                  // srcM
    mov     r10, r2                 // srcB
    mov     r11, r3                 // dst

    vcvt.f64.f32 d0, s0            // exponent -> double, before q0 clobber
    vstr    d0, [sp, #16]

    // h = normalize(lx, ly, lz + 1), loop invariant (identical to Neon32).
    vldr    s16, [r5, #12]
    vldr    s17, [r5, #16]
    vldr    s18, [r5, #20]
    vmov.f32 s19, #1.0
    vadd.f32 s18, s18, s19         // hz_raw = lz + 1
    vmul.f32 s20, s17, s17
    vmul.f32 s21, s16, s16
    vadd.f32 s19, s20, s21
    vmul.f32 s20, s18, s18
    vadd.f32 s19, s19, s20         // hLen^2
    vsqrt.f32 s19, s19             // hLen
    vcmp.f32 s19, #0.0
    vmrs    APSR_nzcv, FPSCR
    beq     .Llin_h_zero
    vdiv.f32 s16, s16, s19         // hx
    vdiv.f32 s17, s17, s19         // hy
    vdiv.f32 s18, s18, s19         // hz
.Llin_h_zero:
    vstr    s16, [sp, #24]
    vstr    s17, [sp, #28]
    vstr    s18, [sp, #32]

    // Load Params: identical to Neon32.
    vld1.32 {d0, d1}, [r5]!
    vld1.32 {d2, d3}, [r5]!
    vld1.32 {d4}, [r5]

    vmov.f32 s16, #1.0
    vdiv.f32 s0, s16, s0
    vdiv.f32 s1, s16, s1

    vdup.32 q4, d4[1]     // ss
    vdup.32 q5, d0[0]     // scaleX
    vdup.32 q6, d0[1]     // scaleY
    vdup.32 q7, d1[0]     // k
    vdup.32 q11, d3[0]    // lr
    vdup.32 q12, d3[1]    // lg
    vdup.32 q13, d4[0]    // lb
    vmov.f32 q14, #1.0    // one

    // h reload via GPR VDUP (no Qd/Dm overlap hazard, see prologue).
    ldr     r12, [sp, #24]         // hx bits
    vdup.32 q8, r12
    ldr     r12, [sp, #28]         // hy bits
    vdup.32 q9, r12
    ldr     r12, [sp, #32]         // hz bits
    vdup.32 q10, r12

.Llin_loop:
    // ---- Row T ----
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tm

    add     r12, r8, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // tr

    // Exact scalar top sum: tr + tm + tm + tl
    vadd.f32 q3, q2, q1
    vadd.f32 q3, q3, q1
    vadd.f32 q3, q3, q0          // top sum

    // ---- Row M ----
    vld1.32 {q0}, [r9]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // ml

    add     r12, r9, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // mr

    // ---- Row B ----
    vld1.32 {q0}, [r10]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // bl

    add     r12, r10, #4
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // bm

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br

    // Exact scalar bottom sum: bl + bm + bm + br
    vadd.f32 q14, q0, q1
    vadd.f32 q14, q14, q1
    vadd.f32 q14, q14, q2        // bottom sum
    vsub.f32 q3, q14, q3         // dyRel
    vmov    q14, q3               // preserve dyRel while recomputing dx

    // Recompute dx with the exact scalar order:
    //   (tr + mr) + mr + br - ((tl + ml) + ml + bl)
    vld1.32 {q0}, [r8]
    vshr.u32 q0, q0, #24
    vcvt.f32.u32 q0, q0
    vmul.f32 q0, q0, q4          // tl

    add     r12, r8, #8
    vld1.32 {q1}, [r12]
    vshr.u32 q1, q1, #24
    vcvt.f32.u32 q1, q1
    vmul.f32 q1, q1, q4          // tr

    vld1.32 {q2}, [r9]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // ml

    add     r12, r9, #8
    vld1.32 {q3}, [r12]
    vshr.u32 q3, q3, #24
    vcvt.f32.u32 q3, q3
    vmul.f32 q3, q3, q4          // mr

    vadd.f32 q0, q0, q2         // tl + ml
    vadd.f32 q0, q0, q2         // (tl + ml) + ml
    vadd.f32 q1, q1, q3         // tr + mr
    vadd.f32 q1, q1, q3         // (tr + mr) + mr

    add     r12, r10, #0
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // bl
    vadd.f32 q0, q0, q2         // + bl

    add     r12, r10, #8
    vld1.32 {q2}, [r12]
    vshr.u32 q2, q2, #24
    vcvt.f32.u32 q2, q2
    vmul.f32 q2, q2, q4          // br
    vadd.f32 q1, q1, q2         // + br
    vsub.f32 q0, q1, q0         // dxRel
    vmov    q3, q14              // restore dyRel

    // ---- Apply per-axis scale ----
    vmul.f32 q0, q0, q5          // q0 = dx
    vmul.f32 q1, q3, q6          // q1 = dy
    // ---- Normalize exactly like Kotlin reference ----
    vneg.f32 q0, q0              // nx0
    vneg.f32 q1, q1              // ny0
    vmul.f32 q2, q0, q0
    vmul.f32 q3, q1, q1
    vadd.f32 q2, q2, q3
    vmov.f32 q14, #1.0
    vadd.f32 q2, q2, q14         // nLen^2

    vsqrt.f32 s12, s8
    vsqrt.f32 s13, s9
    vsqrt.f32 s14, s10
    vsqrt.f32 s15, s11
    vmov.f32 q2, #1.0
    vdiv.f32 s12, s8, s12
    vdiv.f32 s13, s9, s13
    vdiv.f32 s14, s10, s14
    vdiv.f32 s15, s11, s15

    // q3 now contains invLen = 1/nLen.
    vmul.f32 q0, q0, q3          // normalized nx
    vmul.f32 q1, q1, q3          // normalized ny
    vmov q14, q3                 // normalized nz = invLen

    // Kotlin dot with the half vector h (q8-q10): nx*hx + ny*hy + nz*hz
    vmul.f32 q2, q0, q8
    vmul.f32 q15, q1, q9
    vadd.f32 q2, q2, q15
    vmul.f32 q15, q14, q10
    vadd.f32 q2, q2, q15
    vmov.f32 q14, #1.0           // restore one

    // ---- ndoth = max(dot, 0) ----
    veor    q15, q15, q15
    vmax.f32 q2, q2, q15

    // ---- per-lane scalar double pow (reference Math.pow semantics) ----
    vst1.32 {q2}, [sp]
    // ---- 4-lane scalar VFP pow (no bl, invariants survive) ----
    vldr    d1, [sp, #16]        // double exponent
    vcvt.f32.f64 s1, d1          // s1 = exponent float
    vldr    s0, [sp, #0]
    POW1_VFP
    vstr    s0, [sp, #0]

    vldr    s0, [sp, #4]
    POW1_VFP
    vstr    s0, [sp, #4]

    vldr    s0, [sp, #8]
    POW1_VFP
    vstr    s0, [sp, #8]

    vldr    s0, [sp, #12]
    POW1_VFP
    vstr    s0, [sp, #12]

    // ---- intensity = clamp01(k * p) ----
    vld1.32 {q2}, [sp]
    vmul.f32 q2, q2, q7          // k * p
    veor    q15, q15, q15
    vmax.f32 q2, q2, q15
    vmin.f32 q2, q2, q14         // q2 = intensity

    // ---- Pack ARGB (linear-light bytes) ----
    vmul.f32 q1, q2, q11          // outR
    vmul.f32 q0, q2, q12          // outG
    vmul.f32 q3, q2, q13          // outB
    vmov.f32 q14, #0.5
    vadd.f32 q1, q1, q14
    vadd.f32 q0, q0, q14
    vadd.f32 q3, q3, q14
    vcvt.s32.f32 q1, q1
    vcvt.s32.f32 q0, q0
    vcvt.s32.f32 q3, q3

    vshl.u32 q1, q1, #16
    vshl.u32 q0, q0, #8
    vorr    q3, q3, q1
    vorr    q3, q3, q0            // q3 = [0, R, G, B]

    // alpha = max(R,G,B) of the LINEAR bytes, computed PRE-LUT (monotonic
    // LUT preserves the max through the conversion below).
    mov     r7, #0xFF
    vdup.32 q0, r7
    vand    q1, q3, q0            // B
    vshr.u32 q15, q3, #8
    vand    q15, q15, q0          // G
    vshr.u32 q2, q3, #16
    vand    q2, q2, q0            // R
    vmax.u8 q1, q1, q15
    vmax.u8 q1, q1, q2
    vshl.u32 q1, q1, #24
    vorr    q3, q3, q1            // alpha = max(Rlin,Glin,Blin)

    // ---- Linear -> sRGB (scalar LUT lookups, all 4 bytes incl alpha) ----
    vmov    r7, s12
    L2S_ARGB_PIXEL r7
    vmov    r7, s13
    L2S_ARGB_PIXEL r7
    vmov    r7, s14
    L2S_ARGB_PIXEL r7
    vmov    r7, s15
    L2S_ARGB_PIXEL r7

    add     r8, r8, #16
    add     r9, r9, #16
    add     r10, r10, #16
    subs    r4, r4, #4
    bne     .Llin_loop
    b       .Llin_done              // loop done: sp is offset by #40, use .Llin_done

.Llin_exit0:
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.Llin_done:
    add     sp, sp, #40
    vpop    {d8-d15}
    pop     {r4-r11, r12, pc}
.size ksvgLightingDistantSpecularRowNeon32Linear, .-ksvgLightingDistantSpecularRowNeon32Linear
