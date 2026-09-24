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
 * Shared x86_64 AVX2 lighting-kernel macros and tables.
 *
 * This header is included by the lighting_*_x86_64_avx2.S sources (after
 * asm_macros.S). Only definitions live here; every macro is
 * register-parameterized, and callers are responsible for loading table
 * bases (e.g. %r15) before use. On Apple the tables land in __TEXT,__const;
 * on ELF in .rodata — the same RODATA handling as the per-file literals.
 */

/*
 * Description:
 *   Converts one linear-light intensity byte (0..255) to its sRGB byte via the
 *   exact 256-entry LUT (.Lspot_l2s_data), matching ColorLuts.LINEAR_TO_SRGB /
 *   ksvg_linear_to_srgb_lut.
 *
 * Inputs:
 *   \reg  = 32-bit general-purpose register holding the linear intensity (0..255)
 *   %r15  = base of the 256-byte .Lspot_l2s_data LUT (loaded by the caller)
 *
 * Output:
 *   \reg  = sRGB byte value, stored through %r10d (top bits zeroed)
 *
 * Clobbers:
 *   \reg  (in-place)
 *   %r10d
 *
 * The instruction stream is byte-identical to the pre-existing L2S_SPOT /
 * L2S_SPOT64 definitions in the spot kernels; callers keep their loop index,
 * loop limit and the %r15 LUT base themselves.
 */
.macro L2S_SPOT reg
    movl      \reg, %r10d
    movzbl    (%r15,%r10,1), %r10d
    movl      %r10d, \reg
.endm

/*
 * Description:
 *   Alpha-byte to scaled float: extracts the alpha lane (vpsrld $24),
 *   converts int32->float (vcvtdq2ps, exact for 0..255), and scales by
 *   \scale. The emitted vmulps uses scale-first operand order; call sites
 *   that had channel-first order are bit-identical under the change because
 *   IEEE-754 multiplication commutes for every reachable input here: \ch is
 *   always a finite 0..255-derived float, and \scale is finite-or-Inf
 *   (finite*finite is order-independent; 0*Inf yields the canonical QNaN in
 *   both orders; QNaN inputs cannot occur).
 *
 * Inputs:
 *   \src          = vector holding the packed ARGB pixel (may equal \ch)
 *   \ch           = channel register receiving the scaled float (may equal
 *                   \src and/or \dst)
 *   \scale        = float scale vector (preserved)
 *   \dst          = destination for the scaled result (may equal \ch)
 *
 * Output:
 *   \dst = float((\src >> 24) & 0xFF) * \scale
 *
 * Clobbers:
 *   \ch, \dst (written; \src preserved unless aliased)
 *
 * Example: ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9 scales the alpha of ymm9.
 */
.macro ALPHA_FSCALE src, ch, scale, dst
    vpsrld    $24, \src, \ch
    vcvtdq2ps \ch, \ch
    vmulps    \scale, \ch, \dst
.endm

/*
 * Description:
 *   One Horner step: acc = f * acc + coeff, with the scalar coefficient
 *   broadcast to all lanes first.
 *
 * WARNING: never fold the broadcast into the FMA memory operand
 *   (vfmadd213ps mem, %ymm, %ymm). VEX.256 FMA has no broadcast semantics
 *   (broadcast is EVEX-only); the mem operand is a full m256, so lanes 1-7
 *   would silently consume neighboring table words. Lane 0 would stay
 *   correct by accident, hiding the bug from narrow tests.
 *
 *   The broadcast scratch is a parameter (\tmp) so callers whose %ymm9 is
 *   live (point/spot kernels) can pass a dead register instead. \tmp must
 *   be dead at every expansion site and distinct from \f, \acc and the
 *   POW8_AVX2 fixed regs below (%ymm10-%ymm15).
 *
 * Clobbers:
 *   \tmp (broadcast scratch), \acc
 */
.macro POW8_FMA_STEP coeff, f, acc, tmp
    vbroadcastss \coeff, \tmp
    vfmadd213ps \tmp, \f, \acc
.endm

/*
 * Description:
 *   Scalar powf approximation: %xmm0 = %xmm0 ^ %xmm1 (low lanes only) via
 *   8th-degree log2/exp2 minimax Horner with plain mulss/addss (no FMA, so
 *   the same body serves SSSE3 callers too). Drop-in replacement for
 *   CALL(powf): no calls, no spills forced by the ABI.
 *
 *   Requires the caller file to EMIT_LOG2_POLY_8 / EMIT_EXP2_POLY_8 /
 *   EMIT_POW_COMMON_CONSTANTS (labels .Lpoly_log2 / .Lpoly_exp2 /
 *   .Lfloat_1_bits), as the distant kernels do.
 *
 * Inputs:
 *   %xmm0 = base (ndoth, may be 0)
 *   %xmm1 = exponent (preserved)
 *
 * Output:
 *   %xmm0 = pow approximation (exactly 0.0f for base <= 0)
 *
 * Clobbers:
 *   %rax, %rcx, %xmm0, %xmm2
 *   %xmm1 preserved. Callee-saved GPRs untouched.
 */
// NOTE: the dummy parameter exists so Apple-LLVM treats $N immediates
// below as literals. In a parameter-less macro body LLVM substitutes
// bare $N (N followed by a non-digit, e.g. $1, $23, $255, $0xff) with
// the Nth macro argument (empty here), silently producing a memory
// operand - or EVEX-encoded garbage -> SIGILL. Named-parameter macros
// (like POW8_AVX2/POW4_SSSE3) are immune. Same reason: no $0x hex,
// no bare $N below without this guard.
.macro POW1_X64 dummy
    // Consume \dummy so GNU as sees the named parameter as used
    // (silences -W "named parameters not used" on Linux) while keeping
    // the Apple-LLVM $N-literal guard intact. No code emitted.
    .ifeqs "\dummy", "__ksvg_never__"
    .endif
    xorps   %xmm2, %xmm2
    ucomiss %xmm2, %xmm0
    jbe     77f
    movd    %xmm0, %eax
    movl    %eax, %ecx
    shrl    $23, %ecx
    andl    $0xff, %ecx
    subl    $127, %ecx
    andl    $0x007fffff, %eax
    orl     $0x3f800000, %eax
    movd    %eax, %xmm2
    subss   .Lfloat_1_bits(%rip), %xmm2  // f = m - 1
    movss   .Lpoly_log2(%rip), %xmm0  // c8
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+4(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+8(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+12(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+16(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+20(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+24(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+28(%rip), %xmm0
    mulss   %xmm2, %xmm0
    addss   .Lpoly_log2+32(%rip), %xmm0
    cvtsi2ss %ecx, %xmm2  // e
    addss   %xmm2, %xmm0  // log2x = e + P(f)
    mulss   %xmm1, %xmm0  // t = y * log2x
    cvttss2si %xmm0, %ecx  // trunc
    cvtsi2ss %ecx, %xmm2
    ucomiss %xmm0, %xmm2
    jbe     78f
    subl    $1, %ecx
    cvtsi2ss %ecx, %xmm2
78:
    subss   %xmm2, %xmm0  // tf = t - ti
    movss   .Lpoly_exp2(%rip), %xmm2  // c8
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+4(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+8(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+12(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+16(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+20(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+24(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+28(%rip), %xmm2
    mulss   %xmm0, %xmm2
    addss   .Lpoly_exp2+32(%rip), %xmm2
    cmpl    $127, %ecx
    jg      79f
    cmpl    $-126, %ecx
    jl      77f
    addl    $127, %ecx
    shll    $23, %ecx
    movd    %ecx, %xmm0
    mulss   %xmm2, %xmm0
    jmp     80f
79:
    movl    $0x7f7fffff, %ecx
    movd    %ecx, %xmm0
    jmp     80f
77:
    xorps   %xmm0, %xmm0
80:
.endm

/*
 * Description:
 *   High-precision SIMD approximation of pow(x, y) = 2^(y * log2(x)).
 *   Optimized for x in [0, 1] (dot products) and positive y (exponents).
 *
 * Inputs:
 *   \x    = YMM register with base values (destroyed)
 *   \y    = YMM register with exponents (preserved)
 *   \tmp  = YMM broadcast scratch (destroyed; must be dead at the call
 *           site and distinct from \x, \y, %ymm10-%ymm15)
 *
 * Output:
 *   \x    = Result of pow(\x, \y)
 *
 * Clobbers:
 *   \x, \tmp, %ymm10-%ymm15
 */
.macro POW8_AVX2 x, y, tmp
    vmovaps   .Lbiased_127(%rip), %ymm15
    vmovaps   .Lmantissa_mask(%rip), %ymm14
    vmovaps   .Lfloat_1_bits(%rip), %ymm13

// 1. log2(x) range reduction
// e = (bits >> 23) - 127; m = (bits & mask) | 1.0f
    vpsrad    $23, \x, %ymm12  // Get biased exponent
    vpsubd    %ymm15, %ymm12, %ymm12  // e = biased - 127
    vcvtdq2ps %ymm12, %ymm12  // e_float

    vpand     %ymm14, \x, %ymm11  // Get mantissa bits
    vpor      %ymm13, %ymm11, %ymm11  // m in [1, 2)
    vsubps    %ymm13, %ymm11, %ymm11  // f = m - 1.0 (in [0, 1))

// 2. Horner's method for P_log(f) ≈ log2(1+f)
    vbroadcastss .Lpoly_log2+0(%rip), %ymm10  // c8
    POW8_FMA_STEP .Lpoly_log2+4(%rip), %ymm11, %ymm10, \tmp  // c8*f + c7
    POW8_FMA_STEP .Lpoly_log2+8(%rip), %ymm11, %ymm10, \tmp  // .. + c6
    POW8_FMA_STEP .Lpoly_log2+12(%rip), %ymm11, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_log2+16(%rip), %ymm11, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_log2+20(%rip), %ymm11, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_log2+24(%rip), %ymm11, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_log2+28(%rip), %ymm11, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_log2+32(%rip), %ymm11, %ymm10, \tmp  // .. + c0

    vaddps    %ymm10, %ymm12, %ymm12  // log2(x) = e + P_log(f)

// 3. t = y * log2(x)
    vmulps    \y, %ymm12, %ymm12  // t = y * log2(x)

// 4. exp2(t) range reduction
// t = t_i + t_f; t_i = floor(t); t_f = t - t_i
    vroundps  $1, %ymm12, %ymm11  // t_i = floor(t)
    vsubps    %ymm11, %ymm12, %ymm12  // t_f = t - t_i (in [0, 1))

// 5. Horner's method for P_exp(t_f) ≈ 2^t_f
    vbroadcastss .Lpoly_exp2+0(%rip), %ymm10  // c8
    POW8_FMA_STEP .Lpoly_exp2+4(%rip), %ymm12, %ymm10, \tmp  // c8*t_f + c7
    POW8_FMA_STEP .Lpoly_exp2+8(%rip), %ymm12, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_exp2+12(%rip), %ymm12, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_exp2+16(%rip), %ymm12, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_exp2+20(%rip), %ymm12, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_exp2+24(%rip), %ymm12, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_exp2+28(%rip), %ymm12, %ymm10, \tmp
    POW8_FMA_STEP .Lpoly_exp2+32(%rip), %ymm12, %ymm10, \tmp  // .. + c0

// 6. Final scale by 2^t_i
    vcvtps2dq %ymm11, %ymm11  // t_i_int
    vpaddd    %ymm15, %ymm11, %ymm11  // biased_t_i = t_i + 127
    vpmaxsd   .Lmin_exp_biased(%rip), %ymm11, %ymm11  // clamp to 0 (handle underflow)
    vpslld    $23, %ymm11, %ymm11  // shift to exponent field
    vmulps    %ymm10, %ymm11, \x  // Result = 2^t_f * 2^t_i
.endm

RODATA
.p2align 5
.Lspot_l2s_data:
.byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.byte 71,73,75,77,79,81,83,85,86,88,90,92,93,95,96,98
.byte 99,101,102,104,105,106,108,109,110,112,113,114,115,117,118,119
.byte 120,121,122,124,125,126,127,128,129,130,131,132,133,134,135,136
.byte 137,138,139,140,141,142,143,144,145,146,147,148,148,149,150,151
.byte 152,153,154,155,155,156,157,158,159,159,160,161,162,163,163,164
.byte 165,166,167,167,168,169,170,170,171,172,173,173,174,175,175,176
.byte 177,178,178,179,180,180,181,182,182,183,184,185,185,186,187,187
.byte 188,189,189,190,190,191,192,192,193,194,194,195,196,196,197,197
.byte 198,199,199,200,200,201,202,202,203,203,204,205,205,206,206,207
.byte 208,208,209,209,210,210,211,212,212,213,213,214,214,215,215,216
.byte 216,217,218,218,219,219,220,220,221,221,222,222,223,223,224,224
.byte 225,226,226,227,227,228,228,229,229,230,230,231,231,232,232,233
.byte 233,234,234,235,235,236,236,237,237,238,238,238,239,239,240,240
.byte 241,241,242,242,243,243,244,244,245,245,246,246,246,247,247,248
.byte 248,249,249,250,250,251,251,251,252,252,253,253,254,254,255,255

TEXT_SECTION
