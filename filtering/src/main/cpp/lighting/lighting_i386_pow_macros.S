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
 * i386 scalar pow approximation shared by all lighting_*_i386_*.S kernels.
 *
 * Split out of lighting_i386_ssse3_macros.S so kernels with their own
 * file-local ALPHA_EXTRACT/TO_FLOAT definitions (e.g. the i386 AVX2
 * kernels) can use POW1_SSE without macro redefinition collisions.
 * Everything is position-independent by construction (stack-relative and
 * register operands only; tables via GOTOFF, never from inside a macro).
 *
 * Tables live here too: kernels invoke EMIT_POW1_I386_TABLES once in a
 * data/const section instead of hand-duplicating coefficient hex.
 */

/*
 * Description:
 *   Emits the POW1_SSE constant tables (.Ldss_one / .Ldss_log2 /
 *   .Ldss_exp2) with the §4 minimax coefficients. Invoke once per kernel
 *   file; labels are file-local like all other EMIT_* tables.
 */
.macro EMIT_POW1_I386_TABLES
.p2align 2
.Ldss_one: .long 0x3f800000
.p2align 5
.Ldss_log2:
    .long 0xbc14e99e
    .long 0x3d517250
    .long 0xbe0b306b
    .long 0x3e762e19
    .long 0xbeb16ed0
    .long 0x3ef4f943
    .long 0xbf389c1f
    .long 0x3fb8a9fd
    .long 0x3335bce7
.p2align 5
.Ldss_exp2:
    .long 0x35fbc4c2
    .long 0x376d5f0a
    .long 0x3922b9a8
    .long 0x3aaeacc9
    .long 0x3c1d965e
    .long 0x3d63583b
    .long 0x3e75fdf0
    .long 0x3f317218
    .long 0x3f800000
.endm

/*
 * Description:
 *   Scalar powf approximation: %xmm0 = %xmm1 ^ %xmm2 (all scalar floats,
 *   low lanes only) via 8th-degree log2/exp2 minimax Horner. Drop-in
 *   replacement for the `call powf@PLT` sequence: no calls, %ebx (GOT)
 *   preserved, no stack-pointer juggling.
 *
 * Inputs:
 *   %xmm1 = base (ndoth, already maxss-clamped to >= 0 by caller)
 *   %xmm2 = exponent
 *   %ebx  = GOT base (preserved)
 *   Tables .Ldss_one / .Ldss_log2 / .Ldss_exp2 addressable via GOTOFF(%ebx)
 *   (caller emits them; coefficients match §4 of simd_scalar_pow_analysis).
 *
 * Output:
 *   %xmm0 = pow approximation (0.0f for base <= 0)
 *
 * Clobbers:
 *   %eax, %ecx, %edx, %xmm0, %xmm1
 *   %xmm2 preserved.
 */
.macro POW1_SSE
    xorps   %xmm0, %xmm0
    ucomiss %xmm0, %xmm1
    jbe     77f
    movd    %xmm1, %eax
    movl    %eax, %ecx
    shrl    $23, %ecx
    andl    $0xff, %ecx
    subl    $127, %ecx
    cvtsi2ss %ecx, %xmm0
    andl    $0x007fffff, %eax
    orl     $0x3f800000, %eax
    movd    %eax, %xmm1
    subss   .Ldss_one@GOTOFF(%ebx), %xmm1  # f = m - 1
    # Horner log2(1+f), c8..c0
    movss   .Ldss_log2+0*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+1*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+2*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+3*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+4*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+5*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+6*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+7*4@GOTOFF(%ebx), %xmm0
    mulss   %xmm1, %xmm0
    addss   .Ldss_log2+8*4@GOTOFF(%ebx), %xmm0
    cvtsi2ss %ecx, %xmm1
    addss   %xmm1, %xmm0  # log2x = e + P(f)
    mulss   %xmm2, %xmm0  # t = y * log2x
    # ti = floor(t)
    cvttss2si %xmm0, %ecx
    cvtsi2ss %ecx, %xmm1
    ucomiss %xmm0, %xmm1
    jbe     78f
    decl    %ecx  # NOT subl $1: bare $N is a macro-arg ref on some LLVMs
    cvtsi2ss %ecx, %xmm1
78:
    subss   %xmm1, %xmm0  # tf = t - ti
    # Horner exp2(tf), c8..c0
    movss   .Ldss_exp2+0*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+1*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+2*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+3*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+4*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+5*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+6*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+7*4@GOTOFF(%ebx), %xmm1
    mulss   %xmm0, %xmm1
    addss   .Ldss_exp2+8*4@GOTOFF(%ebx), %xmm1
    # scale by 2^ti
    cmpl    $127, %ecx
    jg      79f
    cmpl    $-126, %ecx
    jl      77f
    addl    $127, %ecx
    shll    $23, %ecx
    movd    %ecx, %xmm0
    mulss   %xmm1, %xmm0
    jmp     80f
79:
    # overflow: +inf -> caller clamps intensity to 1.0f; emit FLT_MAX
    movl    $0x7f7fffff, %ecx
    movd    %ecx, %xmm0
    jmp     80f
77:
    xorps   %xmm0, %xmm0
80:
.endm
