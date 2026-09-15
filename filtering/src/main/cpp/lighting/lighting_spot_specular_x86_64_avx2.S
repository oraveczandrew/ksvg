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

#include "asm_macros.S"
#include "lighting_x86_64_avx2_macros.S"

/*
 * Description:
 *   Packs three already-truncated 0..255 channel values into one ARGB pixel
 *   and stores it: alpha = max(r, g, b) (channel carrying the specular
 *   intensity), then A<<24 | R<<16 | G<<8 | B, stored to dst_off(dst_reg).
 *   The channel order is the AOSP-style AARRGGBB little-endian word used by
 *   the lighting kernels.
 *
 * Inputs:
 *   \r, \g, \b   = 32-bit GPRs holding R, G, B in 0..255 (must be distinct;
 *                  must not be \dst_reg)
 *   \dst_reg    = GPR base for the output store
 *   \dst_off    = immediate byte offset added to (\dst_reg)
 *   \tmp        = 32-bit GPR scratch (must be distinct from \r, \g, \b)
 *
 * Output:
 *   \r          = packed ARGB value (also stored to \dst_off(\dst_reg))
 *
 * Clobbers:
 *   \r      (in-place)
 *   \g      (shifted to G<<8)
 *   \b      (shifted to B<<8 and OR-ed away)
 *   \tmp    (shifts to alpha<<24)
 *   flags
 */
.macro SPOT_PACK r, g, b, dst_reg, dst_off, tmp
    movl         \r, \tmp
    cmpl         \g, \tmp
    cmovl        \g, \tmp
    cmpl         \b, \tmp
    cmovl        \b, \tmp
    shll         $24, \tmp
    shll         $16, \r
    shll         $8, \g
    orl          \g, \r
    orl          \b, \r
    orl          \tmp, \r
    movl         \r, \dst_off(\dst_reg)
.endm

/*
 * Description:
 *   Per-pixel spot-specular front half: intensity[i] -> powf(specular
 *   exponent) -> x k -> x spot-factor segment -> clamp intensity to [0,1],
 *   then R/G/B = intensity x lr/lg/lb, per-channel max 0 / min 255 /
 *   round-nearest (+.5, vroundss $11) / truncate, and finally the packed
 *   ARGB pixel stored via SPOT_PACK to out_off(dst_reg). With \l2s == 1 the
 *   three truncated bytes go through L2S_SPOT first (linear core).
 *
 * Inputs:
 *   \intens_off  = byte offset of intensity[i] in the caller's 32(%rsp)-based
 *                  scratch area (e.g. 4*i)
 *   \spot_off    = byte offset of the spot-factor segment (e.g. 32+4*i)
 *   \out_off     = byte offset for the packed pixel store
 *   \dst_reg     = GPR store base
 *   \params_reg  = GPR pointing at SpotLightingParams (8 -> k, 24/28/32 ->
 *                  lr/lg/lb). Must be callee-saved: powf is called inside.
 *   \exp_reg     = specular exponent GPR (must be callee-saved)
 *   \l2s         = 1 to run L2S_SPOT on the three truncated bytes (uses %r15
 *                  LUT base loaded by the caller), 0 otherwise
 *
 * Output:
 *   packed ARGB stored at \out_off(\dst_reg)
 *
 * Clobbers:
 *   %xmm0 (in-place), %xmm1, %xmm2, %xmm3
 *   %eax, %ecx, %edx, %edi   (via the truncation + SPOT_PACK tail)
 *   all SysV caller-saved registers via CALL(powf)
 *   (flags)
 *
 * Depends on the file-local .Lspot_zero/.Lspot_one/.Lspot_255/.Lspot_half
 * literals in the caller's RODATA.
 */
.macro SPOT_SPEC_PIXEL intens_off, spot_off, out_off, dst_reg, params_reg, exp_reg, l2s
    vmovss       \intens_off(%rsp), %xmm0
    vmovd        \exp_reg, %xmm1
    CALL(powf)
    vmulss       8(\params_reg), %xmm0, %xmm0
    vmulss       \spot_off(%rsp), %xmm0, %xmm0
    vmaxss       .Lspot_zero(%rip), %xmm0, %xmm0
    vminss       .Lspot_one(%rip), %xmm0, %xmm0
    vmulss       24(\params_reg), %xmm0, %xmm1
    vmulss       28(\params_reg), %xmm0, %xmm2
    vmulss       32(\params_reg), %xmm0, %xmm3
    vmaxss       .Lspot_zero(%rip), %xmm1, %xmm1
    vmaxss       .Lspot_zero(%rip), %xmm2, %xmm2
    vmaxss       .Lspot_zero(%rip), %xmm3, %xmm3
    vminss       .Lspot_255(%rip), %xmm1, %xmm1
    vminss       .Lspot_255(%rip), %xmm2, %xmm2
    vminss       .Lspot_255(%rip), %xmm3, %xmm3
    vaddss       .Lspot_half(%rip), %xmm1, %xmm1
    vroundss     $11, %xmm1, %xmm1, %xmm1
    vaddss       .Lspot_half(%rip), %xmm2, %xmm2
    vroundss     $11, %xmm2, %xmm2, %xmm2
    vaddss       .Lspot_half(%rip), %xmm3, %xmm3
    vroundss     $11, %xmm3, %xmm3, %xmm3
    vcvttss2si   %xmm1, %eax
    vcvttss2si   %xmm2, %ecx
    vcvttss2si   %xmm3, %edx
.if \l2s
    L2S_SPOT     %eax
    L2S_SPOT     %ecx
    L2S_SPOT     %edx
.endif
    SPOT_PACK %eax, %ecx, %edx, \dst_reg, \out_off, %edi
.endm

/*
 * Description:
 *   Weighted 1:2:1 sum over three float vectors, matching the spot-specular
 *   3x3 window-sum grouping EXACTLY: the two edge operands are added first
 *   ((v0+v2) -> dst), then the doubled middle term (2*v1 -> scratch), then the
 *   accumulate (dst += scratch). This FP operation order is significant
 *   ((v0+v2)+2*v1 is not bit-equal to 2*v1+v0+v2 in general) and must remain
 *   frozen to keep parity.
 *
 * Inputs:
 *   \v0, \v1, \v2  = three 256-bit float vectors; \v1 is the 1:2:1 middle.
 *                    v0/v2 are read first, so \scratch may alias either of
 *                    them for the caller's convenience.
 *   \dst           = destination/accumulator ymm register.
 *   \scratch       = ymm scratch for the doubled middle (distinct from \dst;
 *                    may alias \v0 or \v2, must not alias \v1).
 *
 * Output:
 *   \dst = \v0 + 2*\v1 + \v2
 *
 * Clobbers:
 *   \dst, \scratch
 */
.macro SUM121F v0, v1, v2, dst, scratch
    vaddps       \v0, \v2, \dst
    vaddps       \v1, \v1, \scratch
    vaddps       \scratch, \dst, \dst
.endm

/*
 * Description:
 *   Normalizes a float vector (x, y, z) by its sqrt'd squared length using a
 *   reciprocal: len = sqrt(l2); guard = (len != 0); r = 1/len; then scales
 *   x, y, z by r and zeroes the lanes where len == 0 via the guard mask.
 *   Uses the vcmpps $4 (NEQ) + vdivps + vmulps + vandps sequence so the FP
 *   operation order matches the pre-existing spot-specular view-vector
 *   normalize blocks bit-for-bit. Caller computes l2 = x^2 + y^2 + z^2
 *   (optionally plus one component offset) into \l2 beforehand.
 *
 * Inputs:
 *   \l2                = squared length of the vector (float)
 *   \x, \y, \z         = vector components to normalize
 *
 * Output:
 *   \x, \y, \z         = normalized components (|v| = 1), zero where len == 0
 *
 * Clobbers:
 *   \l2    (len replaces the squared length)
 *   \x, \y, \z                           (in-place)
 *   \guard, \recip
 *   Depends on the file-local .Lspot_one literal in the caller's RODATA.
 *
 * Example: NORM_INV %ymm11, %ymm7, %ymm1, %ymm2, %ymm0, %ymm8 normalizes
 *   the (7, 1, 2) vector, using ymm0 for the guard mask and ymm8 for r.
 */
.macro NORM_INV l2, x, y, z, guard, recip
    vsqrtps      \l2, \l2  // len
    vxorps       \guard, \guard, \guard
    vcmpps       $4, \guard, \l2, \guard  // guard = (len != 0)
    vbroadcastss .Lspot_one(%rip), \recip
    vdivps       \l2, \recip, \recip  // r = 1/len
    vmulps       \recip, \x, \x
    vmulps       \recip, \y, \y
    vmulps       \recip, \z, \z
    vandps       \guard, \x, \x
    vandps       \guard, \y, \y
    vandps       \guard, \z, \z
.endm

/* Spot-light + specular Intel SIMD kernels.
 *
 * SpotLightingParams (17 x float):
 *   +00 invDx  +04 invDy  +08 k
 *   +12 lightX +16 lightY +20 lightZ
 *   +24 lr +28 lg +32 lb +36 ss
 *   +40 ux0 +44 uy +48 dux
 *   +52 spotDirX +56 spotDirY +60 spotDirZ +64 spotCos
 *
 * srcT/srcM/srcB point to x-1 of the first output pixel.
 * spotDir is normalized; spotCos is cosine(cutoff).
 * Linear variants convert the packed intensity through the exact 256-entry
 * Linear->sRGB LUT (L2S_SPOT), matching ColorLuts.LINEAR_TO_SRGB.
 * C++ supplies lr/lg/lb already in linear-light space.
 */
RODATA
.p2align 5

RODATA
.p2align 5
.Lspot_idx8: .long 0x00000000,0x3f800000,0x40000000,0x40400000,0x40800000,0x40a00000,0x40c00000,0x40e00000
RODATA
.p2align 4
.Lspot_idx4: .long 0,1,2,3
POINT_LIT4
.p2align 2
.Lspot_zero: .long 0x00000000
.Lspot_one: .long 0x3f800000
.Lspot_255: .long 0x437f0000
.Lspot_half: .long 0x3f000000

TEXT_SECTION

.globl SYM(ksvgLightingSpotSpecularRowAvx2)
.p2align 4
SYM(ksvgLightingSpotSpecularRowAvx2):
    // Wrapper: spills params/rows, then issues 4-pixel core calls until done.
    // Both entry points share the core below (linear differs only in L2S).
    testl        %r8d, %r8d
    jle          .Lspot_avx2_ret
    pushq        %rbp
    pushq        %rbx
    pushq        %r12
    pushq        %r13
    pushq        %r14
    pushq        %r15
    movq         %r9, %rbp
    movq         %rdi, %r12
    movq         %rsi, %r13
    movq         %rdx, %r14
    movq         %rcx, %r15
    movl         %r8d, %ebx
    subq         $72, %rsp
    movss        %xmm0, 68(%rsp)
    movups       0(%rbp), %xmm0
    movups       %xmm0, 0(%rsp)
    movups       16(%rbp), %xmm0
    movups       %xmm0, 16(%rsp)
    movups       32(%rbp), %xmm0
    movups       %xmm0, 32(%rsp)
    movups       48(%rbp), %xmm0
    movups       %xmm0, 48(%rsp)
    movss        64(%rbp), %xmm0
    movss        %xmm0, 64(%rsp)
.Lspot_avx2_loop:
    movss        68(%rsp), %xmm0
    leaq         0(%rsp), %r9
    movq         %r12, %rdi
    movq         %r13, %rsi
    movq         %r14, %rdx
    movq         %r15, %rcx
    movl         $8, %r8d
    callq        .Lspot_avx2_core
    movss        48(%rsp), %xmm0
    addss        %xmm0, %xmm0
    addss        %xmm0, %xmm0
    addss        %xmm0, %xmm0
    movss        %xmm0, %xmm1
    movss        40(%rsp), %xmm0
    addss        %xmm1, %xmm0
    movss        %xmm0, 40(%rsp)
    addq         $32, %r12
    addq         $32, %r13
    addq         $32, %r14
    addq         $32, %r15
    subl         $8, %ebx
    jg           .Lspot_avx2_loop
    addq         $72, %rsp
    popq         %r15
    popq         %r14
    popq         %r13
    popq         %r12
    popq         %rbx
    popq         %rbp
.Lspot_avx2_ret:
    retq

.p2align 4
.Lspot_avx2_core:
    pushq        %rbp
    pushq        %r12
    pushq        %r13
    pushq        %r14
    pushq        %r15
    subq         $80, %rsp
    movq         %r9, %rbp
    movq         %rcx, %r14
    movd         %xmm0, %r13d

    vmovdqu      0(%rdi), %ymm0
    vmovdqu      4(%rdi), %ymm1
    vmovdqu      8(%rdi), %ymm2
    vmovdqu      0(%rsi), %ymm3
    vmovdqu      4(%rsi), %ymm4
    vmovdqu      8(%rsi), %ymm5
    vmovdqu      0(%rdx), %ymm6
    vmovdqu      4(%rdx), %ymm7
    vmovdqu      8(%rdx), %ymm8
    vpsrld       $24, %ymm0, %ymm0
    vpsrld       $24, %ymm1, %ymm1
    vpsrld       $24, %ymm2, %ymm2
    vpsrld       $24, %ymm3, %ymm3
    vpsrld       $24, %ymm4, %ymm4
    vpsrld       $24, %ymm5, %ymm5
    vpsrld       $24, %ymm6, %ymm6
    vpsrld       $24, %ymm7, %ymm7
    vpsrld       $24, %ymm8, %ymm8
    vcvtdq2ps    %ymm0, %ymm0
    vcvtdq2ps    %ymm1, %ymm1
    vcvtdq2ps    %ymm2, %ymm2
    vcvtdq2ps    %ymm3, %ymm3
    vcvtdq2ps    %ymm4, %ymm4
    vcvtdq2ps    %ymm5, %ymm5
    vcvtdq2ps    %ymm6, %ymm6
    vcvtdq2ps    %ymm7, %ymm7
    vcvtdq2ps    %ymm8, %ymm8
    vbroadcastss 36(%rbp), %ymm11
    vmulps       %ymm11, %ymm0, %ymm0
    vmulps       %ymm11, %ymm1, %ymm1
    vmulps       %ymm11, %ymm2, %ymm2
    vmulps       %ymm11, %ymm3, %ymm3
    vmulps       %ymm11, %ymm4, %ymm4
    vmulps       %ymm11, %ymm5, %ymm5
    vmulps       %ymm11, %ymm6, %ymm6
    vmulps       %ymm11, %ymm7, %ymm7
    vmulps       %ymm11, %ymm8, %ymm8
    SUM121F %ymm2, %ymm5, %ymm8, %ymm9, %ymm11
    SUM121F %ymm0, %ymm3, %ymm6, %ymm10, %ymm11
    vsubps       %ymm10, %ymm9, %ymm9
    SUM121F %ymm6, %ymm7, %ymm8, %ymm10, %ymm11
    SUM121F %ymm0, %ymm1, %ymm2, %ymm11, %ymm0
    vsubps       %ymm11, %ymm10, %ymm10
    vbroadcastss 0(%rbp), %ymm0
    vdivps       %ymm0, %ymm9, %ymm9
    vbroadcastss 4(%rbp), %ymm0
    vdivps       %ymm0, %ymm10, %ymm10
    vxorps       %ymm0, %ymm0, %ymm0
    vsubps       %ymm9, %ymm0, %ymm9
    vsubps       %ymm10, %ymm0, %ymm10
    vmulps       %ymm9, %ymm9, %ymm11
    vmulps       %ymm10, %ymm10, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vsqrtps      %ymm11, %ymm11
    vdivps       %ymm11, %ymm0, %ymm12
    vmulps       %ymm12, %ymm9, %ymm9
    vmulps       %ymm12, %ymm10, %ymm10
    vmovdqu      4(%rsi), %ymm13
    vpsrld       $24, %ymm13, %ymm13
    vcvtdq2ps    %ymm13, %ymm13
    vbroadcastss 36(%rbp), %ymm0
    vmulps       %ymm0, %ymm13, %ymm13
    vbroadcastss 40(%rbp), %ymm11
    vbroadcastss 48(%rbp), %ymm0
    vmulps       .Lspot_idx8(%rip), %ymm0, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vbroadcastss 12(%rbp), %ymm14
    vsubps       %ymm11, %ymm14, %ymm14
    vbroadcastss 16(%rbp), %ymm15
    vbroadcastss 44(%rbp), %ymm0
    vsubps       %ymm0, %ymm15, %ymm15
    vbroadcastss 20(%rbp), %ymm1
    vsubps       %ymm13, %ymm1, %ymm13
    vmulps       %ymm14, %ymm14, %ymm0
    vmulps       %ymm15, %ymm15, %ymm1
    vaddps       %ymm1, %ymm0, %ymm0
    vmulps       %ymm13, %ymm13, %ymm1
    vaddps       %ymm1, %ymm0, %ymm0
    NORM_INV %ymm0, %ymm14, %ymm15, %ymm13, %ymm6, %ymm7
    vxorps       %ymm0, %ymm0, %ymm0
    vsubps       %ymm14, %ymm0, %ymm6
    vbroadcastss 52(%rbp), %ymm1
    vmulps       %ymm1, %ymm6, %ymm6
    vsubps       %ymm15, %ymm0, %ymm1
    vbroadcastss 56(%rbp), %ymm2
    vmulps       %ymm2, %ymm1, %ymm1
    vaddps       %ymm1, %ymm6, %ymm6
    vsubps       %ymm13, %ymm0, %ymm1
    vbroadcastss 60(%rbp), %ymm2
    vmulps       %ymm2, %ymm1, %ymm1
    vaddps       %ymm1, %ymm6, %ymm6
    vmaxps       %ymm0, %ymm6, %ymm6
    vbroadcastss .Lspot_one(%rip), %ymm7
    vminps       %ymm7, %ymm6, %ymm6
    vbroadcastss 64(%rbp), %ymm7
    vmovaps      %ymm7, %ymm1
    vcmpps       $2, %ymm6, %ymm7, %ymm7
    vcmpps       $3, %ymm1, %ymm1, %ymm1
    vorps        %ymm1, %ymm7, %ymm7
    vandps       %ymm7, %ymm6, %ymm6
    vmovaps      %ymm14, %ymm7
    vmovaps      %ymm15, %ymm1
    vmovaps      %ymm13, %ymm2
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps       %ymm0, %ymm2, %ymm2
    vmulps       %ymm7, %ymm7, %ymm11
    vmulps       %ymm1, %ymm1, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vmulps       %ymm2, %ymm2, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    NORM_INV %ymm11, %ymm7, %ymm1, %ymm2, %ymm0, %ymm8
    vmulps       %ymm7, %ymm9, %ymm11
    vmulps       %ymm1, %ymm10, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vmulps       %ymm2, %ymm12, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vxorps       %ymm0, %ymm0, %ymm0
    vmaxps       %ymm0, %ymm11, %ymm11
    vmovups      %ymm11, 0(%rsp)
    vmovups      %ymm6, 32(%rsp)
    leaq         .Lspot_l2s_data(%rip), %r15
    vzeroupper
    // Per-pixel specular blocks below (powf + intensity + RGB + pack).
    SPOT_SPEC_PIXEL 0, 32, 0, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 4, 36, 4, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 8, 40, 8, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 12, 44, 12, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 16, 48, 16, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 20, 52, 20, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 24, 56, 24, %r14, %rbp, %r13d, 0
    SPOT_SPEC_PIXEL 28, 60, 28, %r14, %rbp, %r13d, 0
    vmovd        %r13d, %xmm0
    addq         $80, %rsp
    popq         %r15
    popq         %r14
    popq         %r13
    popq         %r12
    popq         %rbp
    retq
.globl SYM(ksvgLightingSpotSpecularRowAvx2Linear)
.p2align 4
SYM(ksvgLightingSpotSpecularRowAvx2Linear):
    testl        %r8d, %r8d
    jle          .Lspot_avx2_retLinear
    pushq        %rbp
    pushq        %rbx
    pushq        %r12
    pushq        %r13
    pushq        %r14
    pushq        %r15
    movq         %r9, %rbp
    movq         %rdi, %r12
    movq         %rsi, %r13
    movq         %rdx, %r14
    movq         %rcx, %r15
    movl         %r8d, %ebx
    subq         $72, %rsp
    movss        %xmm0, 68(%rsp)
    movups       0(%rbp), %xmm0
    movups       %xmm0, 0(%rsp)
    movups       16(%rbp), %xmm0
    movups       %xmm0, 16(%rsp)
    movups       32(%rbp), %xmm0
    movups       %xmm0, 32(%rsp)
    movups       48(%rbp), %xmm0
    movups       %xmm0, 48(%rsp)
    movss        64(%rbp), %xmm0
    movss        %xmm0, 64(%rsp)
.Lspot_avx2_loopLinear:
    movss        68(%rsp), %xmm0
    leaq         0(%rsp), %r9
    movq         %r12, %rdi
    movq         %r13, %rsi
    movq         %r14, %rdx
    movq         %r15, %rcx
    movl         $8, %r8d
    callq        .Lspot_avx2_coreLinear
    movss        48(%rsp), %xmm0
    addss        %xmm0, %xmm0
    addss        %xmm0, %xmm0
    addss        %xmm0, %xmm0
    movss        %xmm0, %xmm1
    movss        40(%rsp), %xmm0
    addss        %xmm1, %xmm0
    movss        %xmm0, 40(%rsp)
    addq         $32, %r12
    addq         $32, %r13
    addq         $32, %r14
    addq         $32, %r15
    subl         $8, %ebx
    jg           .Lspot_avx2_loopLinear
    addq         $72, %rsp
    popq         %r15
    popq         %r14
    popq         %r13
    popq         %r12
    popq         %rbx
    popq         %rbp
.Lspot_avx2_retLinear:
    retq

.p2align 4
.Lspot_avx2_coreLinear:
    pushq        %rbp
    pushq        %r12
    pushq        %r13
    pushq        %r14
    pushq        %r15
    subq         $80, %rsp
    movq         %r9, %rbp
    movq         %rcx, %r14
    movd         %xmm0, %r13d

    vmovdqu      0(%rdi), %ymm0
    vmovdqu      4(%rdi), %ymm1
    vmovdqu      8(%rdi), %ymm2
    vmovdqu      0(%rsi), %ymm3
    vmovdqu      4(%rsi), %ymm4
    vmovdqu      8(%rsi), %ymm5
    vmovdqu      0(%rdx), %ymm6
    vmovdqu      4(%rdx), %ymm7
    vmovdqu      8(%rdx), %ymm8
    vpsrld       $24, %ymm0, %ymm0
    vpsrld       $24, %ymm1, %ymm1
    vpsrld       $24, %ymm2, %ymm2
    vpsrld       $24, %ymm3, %ymm3
    vpsrld       $24, %ymm4, %ymm4
    vpsrld       $24, %ymm5, %ymm5
    vpsrld       $24, %ymm6, %ymm6
    vpsrld       $24, %ymm7, %ymm7
    vpsrld       $24, %ymm8, %ymm8
    vcvtdq2ps    %ymm0, %ymm0
    vcvtdq2ps    %ymm1, %ymm1
    vcvtdq2ps    %ymm2, %ymm2
    vcvtdq2ps    %ymm3, %ymm3
    vcvtdq2ps    %ymm4, %ymm4
    vcvtdq2ps    %ymm5, %ymm5
    vcvtdq2ps    %ymm6, %ymm6
    vcvtdq2ps    %ymm7, %ymm7
    vcvtdq2ps    %ymm8, %ymm8
    vbroadcastss 36(%rbp), %ymm11
    vmulps       %ymm11, %ymm0, %ymm0
    vmulps       %ymm11, %ymm1, %ymm1
    vmulps       %ymm11, %ymm2, %ymm2
    vmulps       %ymm11, %ymm3, %ymm3
    vmulps       %ymm11, %ymm4, %ymm4
    vmulps       %ymm11, %ymm5, %ymm5
    vmulps       %ymm11, %ymm6, %ymm6
    vmulps       %ymm11, %ymm7, %ymm7
    vmulps       %ymm11, %ymm8, %ymm8
    SUM121F %ymm2, %ymm5, %ymm8, %ymm9, %ymm11
    SUM121F %ymm0, %ymm3, %ymm6, %ymm10, %ymm11
    vsubps       %ymm10, %ymm9, %ymm9
    SUM121F %ymm6, %ymm7, %ymm8, %ymm10, %ymm11
    SUM121F %ymm0, %ymm1, %ymm2, %ymm11, %ymm0
    vsubps       %ymm11, %ymm10, %ymm10
    vbroadcastss 0(%rbp), %ymm0
    vdivps       %ymm0, %ymm9, %ymm9
    vbroadcastss 4(%rbp), %ymm0
    vdivps       %ymm0, %ymm10, %ymm10
    vxorps       %ymm0, %ymm0, %ymm0
    vsubps       %ymm9, %ymm0, %ymm9
    vsubps       %ymm10, %ymm0, %ymm10
    vmulps       %ymm9, %ymm9, %ymm11
    vmulps       %ymm10, %ymm10, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vsqrtps      %ymm11, %ymm11
    vdivps       %ymm11, %ymm0, %ymm12
    vmulps       %ymm12, %ymm9, %ymm9
    vmulps       %ymm12, %ymm10, %ymm10
    vmovdqu      4(%rsi), %ymm13
    vpsrld       $24, %ymm13, %ymm13
    vcvtdq2ps    %ymm13, %ymm13
    vbroadcastss 36(%rbp), %ymm0
    vmulps       %ymm0, %ymm13, %ymm13
    vbroadcastss 40(%rbp), %ymm11
    vbroadcastss 48(%rbp), %ymm0
    vmulps       .Lspot_idx8(%rip), %ymm0, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vbroadcastss 12(%rbp), %ymm14
    vsubps       %ymm11, %ymm14, %ymm14
    vbroadcastss 16(%rbp), %ymm15
    vbroadcastss 44(%rbp), %ymm0
    vsubps       %ymm0, %ymm15, %ymm15
    vbroadcastss 20(%rbp), %ymm1
    vsubps       %ymm13, %ymm1, %ymm13
    vmulps       %ymm14, %ymm14, %ymm0
    vmulps       %ymm15, %ymm15, %ymm1
    vaddps       %ymm1, %ymm0, %ymm0
    vmulps       %ymm13, %ymm13, %ymm1
    vaddps       %ymm1, %ymm0, %ymm0
    NORM_INV %ymm0, %ymm14, %ymm15, %ymm13, %ymm6, %ymm7
    vxorps       %ymm0, %ymm0, %ymm0
    vsubps       %ymm14, %ymm0, %ymm6
    vbroadcastss 52(%rbp), %ymm1
    vmulps       %ymm1, %ymm6, %ymm6
    vsubps       %ymm15, %ymm0, %ymm1
    vbroadcastss 56(%rbp), %ymm2
    vmulps       %ymm2, %ymm1, %ymm1
    vaddps       %ymm1, %ymm6, %ymm6
    vsubps       %ymm13, %ymm0, %ymm1
    vbroadcastss 60(%rbp), %ymm2
    vmulps       %ymm2, %ymm1, %ymm1
    vaddps       %ymm1, %ymm6, %ymm6
    vmaxps       %ymm0, %ymm6, %ymm6
    vbroadcastss .Lspot_one(%rip), %ymm7
    vminps       %ymm7, %ymm6, %ymm6
    vbroadcastss 64(%rbp), %ymm7
    vmovaps      %ymm7, %ymm1
    vcmpps       $2, %ymm6, %ymm7, %ymm7
    vcmpps       $3, %ymm1, %ymm1, %ymm1
    vorps        %ymm1, %ymm7, %ymm7
    vandps       %ymm7, %ymm6, %ymm6
    vmovaps      %ymm14, %ymm7
    vmovaps      %ymm15, %ymm1
    vmovaps      %ymm13, %ymm2
    vbroadcastss .Lspot_one(%rip), %ymm0
    vaddps       %ymm0, %ymm2, %ymm2
    vmulps       %ymm7, %ymm7, %ymm11
    vmulps       %ymm1, %ymm1, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vmulps       %ymm2, %ymm2, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    NORM_INV %ymm11, %ymm7, %ymm1, %ymm2, %ymm0, %ymm8
    vmulps       %ymm7, %ymm9, %ymm11
    vmulps       %ymm1, %ymm10, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vmulps       %ymm2, %ymm12, %ymm0
    vaddps       %ymm0, %ymm11, %ymm11
    vxorps       %ymm0, %ymm0, %ymm0
    vmaxps       %ymm0, %ymm11, %ymm11
    vmovups      %ymm11, 0(%rsp)
    vmovups      %ymm6, 32(%rsp)
    leaq         .Lspot_l2s_data(%rip), %r15
    vzeroupper
    // Per-pixel specular blocks below (powf + intensity + RGB + pack).
    SPOT_SPEC_PIXEL 0, 32, 0, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 4, 36, 4, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 8, 40, 8, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 12, 44, 12, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 16, 48, 16, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 20, 52, 20, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 24, 56, 24, %r14, %rbp, %r13d, 1
    SPOT_SPEC_PIXEL 28, 60, 28, %r14, %rbp, %r13d, 1
    vmovd        %r13d, %xmm0
    addq         $80, %rsp
    popq         %r15
    popq         %r14
    popq         %r13
    popq         %r12
    popq         %rbp
    retq
