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

/*
 * ARMv7-A scalar pow approximation shared by lighting_*_armv7a_neon.S.
 *
 * The armv7a kernels keep their loop invariants in q4-q13 with only
 * q0-q3/q15 free, so a 4-wide vector polynomial does not fit without
 * spilling invariants. Like the i386 POW1_SSE, this scalar VFP macro
 * replaces each per-lane `bl pow` 1:1: no calls, no caller-saved spills.
 *
 * Method: pow(x,y) = 2^(y*log2(x)) with 6th-degree minimax polynomials
 * (Chebyshev-interpolated; split mul+add Horner validated by an exhaustive
 * float32 simulation over x in (0,1) x y in {1,2,3,4,5,8,16,32,64,128}:
 * worst byte delta 1, max float delta 1e-4).
 * Domain note: bases are clamped ndoth in [0,1], exponents positive, so
 * t = y*log2(x) <= 0 always — overflow is impossible in practice, but the
 * macro still guards it (FLT_MAX, caller clamps intensity to 1).
 *
 * Everything is position-independent (adr + per-function pools).
 */

/* (No separate EMIT macro: the 15-word pool is inline in POW1_VFP.) */

/*
 * Description:
 *   Scalar pow(x, y): s0 = pow(s0, s1), single-precision VFP only.
 *
 *   Tables are inline in the expansion (branch over 19 words): adr can only
 *   encode modified-immediate distances, so a shared end-of-function pool is
 *   not reliably reachable. The macro is therefore fully self-contained and
 *   takes no parameters.
 *
 * Inputs:
 *   s0 = base (ndoth, already clamped to >= 0 by caller)
 *   s1 = exponent (preserved)
 *
 * Output:
 *   s0 = pow approximation (exactly 0.0 for base <= 0)
 *
 * Clobbers:
 *   s0 (in-place), s2-s7, r0-r2, r12, APSR/FPSCR flags.
 *   s1 and d8+ (q4-q7 invariants) preserved. Callers must have r12 dead
 *   (it is the tap/address temp, dead at every pow site by construction).
 */
.macro POW1_VFP
    b       76f
75: .long 0xbcc943f4                // log2(1+f) c6
    .long 0x3df0df21                // c5
    .long 0xbe8b9f04                // c4
    .long 0x3ee8b556                // c3
    .long 0xbf37a1cf                // c2
    .long 0x3fb8a251                // c1
    .long 0x3623f9f5                // c0
    .long 0x39654785                // 2^tf c6
    .long 0x3aa26a69                // c5
    .long 0x3c1eaa6c                // c4
    .long 0x3d633fa8                // c3
    .long 0x3e75fef9                // c2
    .long 0x3f317214                // c1
    .long 0x3f800000                // c0
    .long 0x7f7fffff                // FLT_MAX
76: adr     r12, 75b
    vcmp.f32 s0, #0.0
    vmrs    APSR_nzcv, FPSCR
    bls     77f
    vmov    r0, s0                  // bits
    mov     r1, r0, lsr #23
    and     r1, r1, #0xff           // biased exp
    sub     r1, r1, #127            // e
    bic     r0, r0, #0xff000000
    bic     r0, r0, #0x800000       // clear sign+exp
    orr     r0, r0, #0x3f000000
    orr     r0, r0, #0x800000       // | 1.0f
    vmov    s2, r0                  // m
    vmov.f32 s3, #1.0
    vsub.f32 s2, s2, s3             // f = m - 1
    vmov    s4, r1
    vcvt.f32.s32 s4, s4             // e float
    vldr    s5, [r12, #0]           // c6
    vmul.f32 s5, s5, s2
    vldr    s6, [r12, #4]           // c5
    vadd.f32 s5, s5, s6
    vmul.f32 s5, s5, s2
    vldr    s6, [r12, #8]           // c4
    vadd.f32 s5, s5, s6
    vmul.f32 s5, s5, s2
    vldr    s6, [r12, #12]          // c3
    vadd.f32 s5, s5, s6
    vmul.f32 s5, s5, s2
    vldr    s6, [r12, #16]          // c2
    vadd.f32 s5, s5, s6
    vmul.f32 s5, s5, s2
    vldr    s6, [r12, #20]          // c1
    vadd.f32 s5, s5, s6
    vmul.f32 s5, s5, s2
    vldr    s6, [r12, #24]          // c0
    vadd.f32 s5, s5, s6
    vadd.f32 s5, s5, s4             // log2x = e + P(f)
    vmul.f32 s5, s1, s5             // t = y * log2x
    vcvt.s32.f32 s6, s5             // trunc
    vmov    r2, s6                  // ti candidate (int)
    vcvt.f32.s32 s7, s6
    vcmp.f32 s5, s7
    vmrs    APSR_nzcv, FPSCR
    bge     78f
    sub     r2, r2, #1
    vmov    s6, r2
    vcvt.f32.s32 s6, s6
78:
    vsub.f32 s5, s5, s6             // tf = t - ti
    vmov    s6, r2                  // ti int -> s6 (int bits)
    vldr    s7, [r12, #28]          // c6
    vmul.f32 s7, s7, s5
    vldr    s6, [r12, #32]          // c5
    vadd.f32 s7, s7, s6
    vmul.f32 s7, s7, s5
    vldr    s6, [r12, #36]          // c4
    vadd.f32 s7, s7, s6
    vmul.f32 s7, s7, s5
    vldr    s6, [r12, #40]          // c3
    vadd.f32 s7, s7, s6
    vmul.f32 s7, s7, s5
    vldr    s6, [r12, #44]          // c2
    vadd.f32 s7, s7, s6
    vmul.f32 s7, s7, s5
    vldr    s6, [r12, #48]          // c1
    vadd.f32 s7, s7, s6
    vmul.f32 s7, s7, s5
    vldr    s6, [r12, #52]          // c0
    vadd.f32 s7, s7, s6
    cmp     r2, #127
    bgt     79f
    cmp     r2, #-126
    blt     77f
    add     r2, r2, #127
    mov     r2, r2, lsl #23
    vmov    s4, r2
    vmul.f32 s0, s7, s4
    b       80f
79:
    vldr    s0, [r12, #56]          // FLT_MAX (pool tail)
    b       80f
77:
    mov     r2, #0                  // 0.0 is not a VFP immediate; via GPR
    vmov    s0, r2
80:
.endm
