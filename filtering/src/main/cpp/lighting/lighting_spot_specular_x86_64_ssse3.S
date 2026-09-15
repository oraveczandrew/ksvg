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
#include "lighting_x86_64_ssse3_macros.S"

/*
 * Description:
 *   Per-pixel spot-specular: intensity[i] -> powf(specular exponent) -> x k
 *   -> x spot-factor segment -> clamp intensity to [0,1], then R/G/B =
 *   intensity x lr/lg/lb, per-channel max 0 / min 255 / round-nearest (+.5,
 *   roundss $11) / truncate, max-channel-alpha cmov pack, stored to
 *   out_off(%r14). With \l2s == 1 the three truncated bytes go through
 *   L2S_SPOT first (linear core, %r15 LUT base loaded by the caller).
 *   Fixed-register form (matches all 8 core sites): params via %rbp,
 *   exponent in %r13d, intensity/spot segments in the caller's (%rsp)
 *   scratch area, store base %r14.
 *
 * Inputs:
 *   \intens_off  = byte offset of intensity[i] in (%rsp) (e.g. 4*i)
 *   \spot_off    = byte offset of the spot-factor segment (e.g. 16+4*i)
 *   \out_off     = byte offset for the packed pixel store
 *   \l2s         = 1 to run L2S_SPOT on the three truncated bytes, 0 otherwise
 *
 * Output:
 *   packed ARGB stored at \out_off(%r14)
 *
 * Clobbers:
 *   %xmm0, %xmm1, %xmm2
 *   %eax, %ecx, %edx, %edi
 *   all SysV caller-saved registers via CALL(powf)
 *   (flags)
 *
 * Depends on the file-local .Lspot_zero/.Lspot_one/.Lspot_255/.Lspot_half
 * literals in the caller's RODATA.
 */
.macro SPOT_SPEC_PIXEL intens_off, spot_off, out_off, l2s
    movss     \intens_off(%rsp), %xmm0
    movd      %r13d, %xmm1
    CALL(powf)
    mulss     8(%rbp), %xmm0
    mulss     \spot_off(%rsp), %xmm0
    maxss     .Lspot_zero(%rip), %xmm0
    minss     .Lspot_one(%rip), %xmm0
    movaps    %xmm0, %xmm1
    movaps    %xmm0, %xmm2
    mulss     24(%rbp), %xmm0
    mulss     28(%rbp), %xmm1
    mulss     32(%rbp), %xmm2
    maxss     .Lspot_zero(%rip), %xmm0
    maxss     .Lspot_zero(%rip), %xmm1
    maxss     .Lspot_zero(%rip), %xmm2
    minss     .Lspot_255(%rip), %xmm0
    minss     .Lspot_255(%rip), %xmm1
    minss     .Lspot_255(%rip), %xmm2
    addss     .Lspot_half(%rip), %xmm0
    addss     .Lspot_half(%rip), %xmm1
    addss     .Lspot_half(%rip), %xmm2
    cvttss2si %xmm0, %eax
    cvttss2si %xmm1, %ecx
    cvttss2si %xmm2, %edx
.if \l2s
    L2S_SPOT  %eax
    L2S_SPOT  %ecx
    L2S_SPOT  %edx
.endif
    movl      %eax, %edi
    cmpl      %ecx, %edi
    cmovl     %ecx, %edi
    cmpl      %edx, %edi
    cmovl     %edx, %edi
    shll      $24, %edi
    shll      $16, %eax
    shll      $8, %ecx
    orl       %ecx, %eax
    orl       %edx, %eax
    orl       %edi, %eax
    movl      %eax, \out_off(%r14)
.endm

/*
 * Description:
 *   Normalizes a float vector (x, y, z) by its sqrt'd squared length using a
 *   reciprocal: len = sqrt(l2); guard = (len != 0); r = 1/len; then scales
 *   x, y, z by r and zeroes the lanes where len == 0 via the guard mask.
 *   Uses the cmpps $4 (NEQ) + divps + mulps + andps sequence so the FP
 *   operation order matches the pre-existing spot-specular view-vector
 *   normalize blocks bit-for-bit. Caller computes l2 = x^2 + y^2 + z^2
 *   beforehand. Legacy SSE mnemonics; the 1.0 broadcast uses movss+shufps.
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
 */
.macro NORM_INV l2, x, y, z, guard, recip
    sqrtps    \l2, \l2
    pxor      \guard, \guard
    cmpps     $4, \l2, \guard
    movss     .Lspot_one(%rip), \recip
    shufps    $0, \recip, \recip
    divps     \l2, \recip
    mulps     \recip, \x
    mulps     \recip, \y
    mulps     \recip, \z
    andps     \guard, \x
    andps     \guard, \y
    andps     \guard, \z
.endm

/* Spot-light + specular Intel SSSE3 kernels.
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

SPOT_CONST
.p2align 5
.Lspot_idx8: .long 0,1,2,3,4,5,6,7
SPOT_CONST
.p2align 4
.Lspot_idx4: .long 0,1,2,3
SPOT_LIT4
.p2align 2
.Lspot_zero: .long 0x00000000
.Lspot_one: .long 0x3f800000
.Lspot_255: .long 0x437f0000
.Lspot_half: .long 0x3f000000

SPOT_TEXT

.globl SYM(ksvgLightingSpotSpecularRowSsse3)
.p2align 4
SYM(ksvgLightingSpotSpecularRowSsse3):
    testl     %r8d, %r8d
    jle       .Lspot_ssse3_ret
    pushq     %rbp
    pushq     %rbx
    pushq     %r12
    pushq     %r13
    pushq     %r14
    pushq     %r15
    movq      %r9, %rbp
    movq      %rdi, %r12
    movq      %rsi, %r13
    movq      %rdx, %r14
    movq      %rcx, %r15
    movl      %r8d, %ebx
    subq      $72, %rsp
    movss     %xmm0, 68(%rsp)
    movups    0(%rbp), %xmm0
    movups    %xmm0, 0(%rsp)
    movups    16(%rbp), %xmm0
    movups    %xmm0, 16(%rsp)
    movups    32(%rbp), %xmm0
    movups    %xmm0, 32(%rsp)
    movups    48(%rbp), %xmm0
    movups    %xmm0, 48(%rsp)
    movss     64(%rbp), %xmm0
    movss     %xmm0, 64(%rsp)
.Lspot_ssse3_loop:
    // Issue 4-pixel core calls until done (both wrappers share one core
    // each; linear differs only in L2S).
    movss     68(%rsp), %xmm0
    leaq      0(%rsp), %r9
    movq      %r12, %rdi
    movq      %r13, %rsi
    movq      %r14, %rdx
    movq      %r15, %rcx
    movl      $4, %r8d
    callq     .Lspot_ssse3_core
    subl      $4, %ebx
    jle       .Lspot_ssse3_done

    movss     48(%rsp), %xmm0
    addss     %xmm0, %xmm0
    addss     %xmm0, %xmm0
    movss     %xmm0, %xmm1
    movss     40(%rsp), %xmm0
    addss     %xmm1, %xmm0
    movss     %xmm0, 40(%rsp)
    addq      $16, %r12
    addq      $16, %r13
    addq      $16, %r14
    addq      $16, %r15

    movss     68(%rsp), %xmm0
    leaq      0(%rsp), %r9
    movq      %r12, %rdi
    movq      %r13, %rsi
    movq      %r14, %rdx
    movq      %r15, %rcx
    movl      $4, %r8d
    callq     .Lspot_ssse3_core
    subl      $4, %ebx

    movss     48(%rsp), %xmm0
    addss     %xmm0, %xmm0
    addss     %xmm0, %xmm0
    movss     %xmm0, %xmm1
    movss     40(%rsp), %xmm0
    addss     %xmm1, %xmm0
    movss     %xmm0, 40(%rsp)
    addq      $16, %r12
    addq      $16, %r13
    addq      $16, %r14
    addq      $16, %r15
    jg        .Lspot_ssse3_loop

.Lspot_ssse3_done:
    addq      $72, %rsp
    popq      %r15
    popq      %r14
    popq      %r13
    popq      %r12
    popq      %rbx
    popq      %rbp
.Lspot_ssse3_ret:
    retq

.p2align 4
.Lspot_ssse3_core:
    // Shared 4-pixel kernel: Sobel window, normalize, per-pixel powf blocks
    // (specular exponent, intensity, RGB, pack) below.
    pushq     %rbp
    pushq     %r12
    pushq     %r13
    pushq     %r14
    pushq     %r15
    subq      $40, %rsp
    movq      %r9, %rbp
    movq      %rcx, %r14
    movd      %xmm0, %r13d

    movdqu    0(%rdi), %xmm0
    movdqu    4(%rdi), %xmm1
    movdqu    8(%rdi), %xmm2
    movdqu    0(%rsi), %xmm3
    movdqu    4(%rsi), %xmm4
    movdqu    8(%rsi), %xmm5
    movdqu    0(%rdx), %xmm6
    movdqu    4(%rdx), %xmm7
    movdqu    8(%rdx), %xmm8
    psrld     $24, %xmm0
    psrld     $24, %xmm1
    psrld     $24, %xmm2
    psrld     $24, %xmm3
    psrld     $24, %xmm4
    psrld     $24, %xmm5
    psrld     $24, %xmm6
    psrld     $24, %xmm7
    psrld     $24, %xmm8
    cvtdq2ps  %xmm0, %xmm0
    cvtdq2ps  %xmm1, %xmm1
    cvtdq2ps  %xmm2, %xmm2
    cvtdq2ps  %xmm3, %xmm3
    cvtdq2ps  %xmm4, %xmm4
    cvtdq2ps  %xmm5, %xmm5
    cvtdq2ps  %xmm6, %xmm6
    cvtdq2ps  %xmm7, %xmm7
    cvtdq2ps  %xmm8, %xmm8
    movss     36(%rbp), %xmm11
    shufps    $0, %xmm11, %xmm11
    mulps     %xmm11, %xmm0
    mulps     %xmm11, %xmm1
    mulps     %xmm11, %xmm2
    mulps     %xmm11, %xmm3
    mulps     %xmm11, %xmm4
    mulps     %xmm11, %xmm5
    mulps     %xmm11, %xmm6
    mulps     %xmm11, %xmm7
    mulps     %xmm11, %xmm8
    movaps    %xmm2, %xmm9
    addps     %xmm8, %xmm9
    movaps    %xmm5, %xmm11
    addps     %xmm5, %xmm11
    addps     %xmm11, %xmm9
    movaps    %xmm0, %xmm10
    addps     %xmm6, %xmm10
    movaps    %xmm3, %xmm11
    addps     %xmm3, %xmm11
    addps     %xmm11, %xmm10
    subps     %xmm10, %xmm9
    movaps    %xmm6, %xmm10
    addps     %xmm8, %xmm10
    movaps    %xmm7, %xmm11
    addps     %xmm7, %xmm11
    addps     %xmm11, %xmm10
    movaps    %xmm0, %xmm11
    addps     %xmm2, %xmm11
    movaps    %xmm1, %xmm0
    addps     %xmm1, %xmm0
    addps     %xmm0, %xmm11
    subps     %xmm11, %xmm10
    movss     0(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    divps     %xmm0, %xmm9
    movss     4(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    divps     %xmm0, %xmm10
    pxor      %xmm0, %xmm0
    subps     %xmm9, %xmm0
    movaps    %xmm0, %xmm9
    pxor      %xmm0, %xmm0
    subps     %xmm10, %xmm0
    movaps    %xmm0, %xmm10
    movaps    %xmm9, %xmm11
    mulps     %xmm9, %xmm11
    movaps    %xmm10, %xmm0
    mulps     %xmm10, %xmm0
    addps     %xmm0, %xmm11
    movss     .Lspot_one(%rip), %xmm0
    shufps    $0, %xmm0, %xmm0
    addps     %xmm0, %xmm11
    sqrtps    %xmm11, %xmm11
    movss     .Lspot_one(%rip), %xmm0
    shufps    $0, %xmm0, %xmm0
    divps     %xmm11, %xmm0
    movaps    %xmm0, %xmm12
    mulps     %xmm0, %xmm9
    mulps     %xmm0, %xmm10
    movdqu    4(%rsi), %xmm13
    psrld     $24, %xmm13
    cvtdq2ps  %xmm13, %xmm13
    movss     36(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    mulps     %xmm0, %xmm13
    movss     40(%rbp), %xmm11
    shufps    $0, %xmm11, %xmm11
    movss     48(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    movdqa    .Lspot_idx4(%rip), %xmm8
    cvtdq2ps  %xmm8, %xmm8
    mulps     %xmm0, %xmm8
    addps     %xmm8, %xmm11
    movss     12(%rbp), %xmm14
    shufps    $0, %xmm14, %xmm14
    subps     %xmm11, %xmm14
    movss     16(%rbp), %xmm15
    shufps    $0, %xmm15, %xmm15
    movss     44(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    subps     %xmm0, %xmm15
    movss     20(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    subps     %xmm13, %xmm0
    movaps    %xmm0, %xmm13
    movaps    %xmm14, %xmm0
    mulps     %xmm14, %xmm0
    movaps    %xmm15, %xmm1
    mulps     %xmm15, %xmm1
    addps     %xmm1, %xmm0
    movaps    %xmm13, %xmm1
    mulps     %xmm13, %xmm1
    addps     %xmm1, %xmm0
    NORM_INV %xmm0, %xmm14, %xmm15, %xmm13, %xmm6, %xmm7
    pxor      %xmm0, %xmm0
    movaps    %xmm14, %xmm6
    subps     %xmm6, %xmm0
    movss     52(%rbp), %xmm1
    shufps    $0, %xmm1, %xmm1
    mulps     %xmm1, %xmm0
    movaps    %xmm15, %xmm1
    pxor      %xmm7, %xmm7
    subps     %xmm15, %xmm7
    movss     56(%rbp), %xmm2
    shufps    $0, %xmm2, %xmm2
    mulps     %xmm2, %xmm7
    addps     %xmm7, %xmm0
    pxor      %xmm7, %xmm7
    subps     %xmm13, %xmm7
    movss     60(%rbp), %xmm2
    shufps    $0, %xmm2, %xmm2
    mulps     %xmm2, %xmm7
    addps     %xmm7, %xmm0
    pxor      %xmm7, %xmm7
    maxps     %xmm7, %xmm0
    movss     .Lspot_one(%rip), %xmm7
    shufps    $0, %xmm7, %xmm7
    minps     %xmm7, %xmm0
    movss     64(%rbp), %xmm7
    shufps    $0, %xmm7, %xmm7
    movaps    %xmm7, %xmm5
    cmpps     $2, %xmm0, %xmm7
    cmpps     $3, %xmm5, %xmm5
    orps      %xmm5, %xmm7
    andps     %xmm7, %xmm0
    movups    %xmm0, 16(%rsp)
    movaps    %xmm14, %xmm7
    movaps    %xmm15, %xmm1
    movaps    %xmm13, %xmm2
    movss     .Lspot_one(%rip), %xmm0
    shufps    $0, %xmm0, %xmm0
    addps     %xmm0, %xmm2
    movaps    %xmm7, %xmm11
    mulps     %xmm7, %xmm11
    movaps    %xmm1, %xmm0
    mulps     %xmm1, %xmm0
    addps     %xmm0, %xmm11
    movaps    %xmm2, %xmm0
    mulps     %xmm2, %xmm0
    addps     %xmm0, %xmm11
    NORM_INV %xmm11, %xmm7, %xmm1, %xmm2, %xmm8, %xmm0
    movaps    %xmm7, %xmm11
    mulps     %xmm9, %xmm11
    movaps    %xmm1, %xmm0
    mulps     %xmm10, %xmm0
    addps     %xmm0, %xmm11
    movaps    %xmm2, %xmm0
    mulps     %xmm12, %xmm0
    addps     %xmm0, %xmm11
    pxor      %xmm0, %xmm0
    maxps     %xmm0, %xmm11
    movups    %xmm11, 0(%rsp)
    // Per-pixel specular blocks below (powf + intensity + RGB + pack).
    SPOT_SPEC_PIXEL 0, 16, 0, 0
    SPOT_SPEC_PIXEL 4, 20, 4, 0
    SPOT_SPEC_PIXEL 8, 24, 8, 0
    SPOT_SPEC_PIXEL 12, 28, 12, 0
    movd      %r13d, %xmm0
    addq      $40, %rsp
    popq      %r15
    popq      %r14
    popq      %r13
    popq      %r12
    popq      %rbp
    retq
.globl SYM(ksvgLightingSpotSpecularRowSsse3Linear)
.p2align 4
SYM(ksvgLightingSpotSpecularRowSsse3Linear):
    testl     %r8d, %r8d
    jle       .Lspot_ssse3_retLinear
    pushq     %rbp
    pushq     %rbx
    pushq     %r12
    pushq     %r13
    pushq     %r14
    pushq     %r15
    movq      %r9, %rbp
    movq      %rdi, %r12
    movq      %rsi, %r13
    movq      %rdx, %r14
    movq      %rcx, %r15
    movl      %r8d, %ebx
    subq      $72, %rsp
    movss     %xmm0, 68(%rsp)
    movups    0(%rbp), %xmm0
    movups    %xmm0, 0(%rsp)
    movups    16(%rbp), %xmm0
    movups    %xmm0, 16(%rsp)
    movups    32(%rbp), %xmm0
    movups    %xmm0, 32(%rsp)
    movups    48(%rbp), %xmm0
    movups    %xmm0, 48(%rsp)
    movss     64(%rbp), %xmm0
    movss     %xmm0, 64(%rsp)
.Lspot_ssse3_loopLinear:
    movss     68(%rsp), %xmm0
    leaq      0(%rsp), %r9
    movq      %r12, %rdi
    movq      %r13, %rsi
    movq      %r14, %rdx
    movq      %r15, %rcx
    movl      $4, %r8d
    callq     .Lspot_ssse3_coreLinear
    subl      $4, %ebx
    jle       .Lspot_ssse3_doneLinear

    movss     48(%rsp), %xmm0
    addss     %xmm0, %xmm0
    addss     %xmm0, %xmm0
    movss     %xmm0, %xmm1
    movss     40(%rsp), %xmm0
    addss     %xmm1, %xmm0
    movss     %xmm0, 40(%rsp)
    addq      $16, %r12
    addq      $16, %r13
    addq      $16, %r14
    addq      $16, %r15

    movss     68(%rsp), %xmm0
    leaq      0(%rsp), %r9
    movq      %r12, %rdi
    movq      %r13, %rsi
    movq      %r14, %rdx
    movq      %r15, %rcx
    movl      $4, %r8d
    callq     .Lspot_ssse3_coreLinear
    subl      $4, %ebx

    movss     48(%rsp), %xmm0
    addss     %xmm0, %xmm0
    addss     %xmm0, %xmm0
    movss     %xmm0, %xmm1
    movss     40(%rsp), %xmm0
    addss     %xmm1, %xmm0
    movss     %xmm0, 40(%rsp)
    addq      $16, %r12
    addq      $16, %r13
    addq      $16, %r14
    addq      $16, %r15
    jg        .Lspot_ssse3_loopLinear

.Lspot_ssse3_doneLinear:
    addq      $72, %rsp
    popq      %r15
    popq      %r14
    popq      %r13
    popq      %r12
    popq      %rbx
    popq      %rbp
.Lspot_ssse3_retLinear:
    retq

.p2align 4
.Lspot_ssse3_coreLinear:
    // Shared 4-pixel kernel, linear variant (per-pixel L2S conversion).
    pushq     %rbp
    pushq     %r12
    pushq     %r13
    pushq     %r14
    pushq     %r15
    subq      $40, %rsp
    movq      %r9, %rbp
    movq      %rcx, %r14
    movd      %xmm0, %r13d

    movdqu    0(%rdi), %xmm0
    movdqu    4(%rdi), %xmm1
    movdqu    8(%rdi), %xmm2
    movdqu    0(%rsi), %xmm3
    movdqu    4(%rsi), %xmm4
    movdqu    8(%rsi), %xmm5
    movdqu    0(%rdx), %xmm6
    movdqu    4(%rdx), %xmm7
    movdqu    8(%rdx), %xmm8
    psrld     $24, %xmm0
    psrld     $24, %xmm1
    psrld     $24, %xmm2
    psrld     $24, %xmm3
    psrld     $24, %xmm4
    psrld     $24, %xmm5
    psrld     $24, %xmm6
    psrld     $24, %xmm7
    psrld     $24, %xmm8
    cvtdq2ps  %xmm0, %xmm0
    cvtdq2ps  %xmm1, %xmm1
    cvtdq2ps  %xmm2, %xmm2
    cvtdq2ps  %xmm3, %xmm3
    cvtdq2ps  %xmm4, %xmm4
    cvtdq2ps  %xmm5, %xmm5
    cvtdq2ps  %xmm6, %xmm6
    cvtdq2ps  %xmm7, %xmm7
    cvtdq2ps  %xmm8, %xmm8
    movss     36(%rbp), %xmm11
    shufps    $0, %xmm11, %xmm11
    mulps     %xmm11, %xmm0
    mulps     %xmm11, %xmm1
    mulps     %xmm11, %xmm2
    mulps     %xmm11, %xmm3
    mulps     %xmm11, %xmm4
    mulps     %xmm11, %xmm5
    mulps     %xmm11, %xmm6
    mulps     %xmm11, %xmm7
    mulps     %xmm11, %xmm8
    movaps    %xmm2, %xmm9
    addps     %xmm8, %xmm9
    movaps    %xmm5, %xmm11
    addps     %xmm5, %xmm11
    addps     %xmm11, %xmm9
    movaps    %xmm0, %xmm10
    addps     %xmm6, %xmm10
    movaps    %xmm3, %xmm11
    addps     %xmm3, %xmm11
    addps     %xmm11, %xmm10
    subps     %xmm10, %xmm9
    movaps    %xmm6, %xmm10
    addps     %xmm8, %xmm10
    movaps    %xmm7, %xmm11
    addps     %xmm7, %xmm11
    addps     %xmm11, %xmm10
    movaps    %xmm0, %xmm11
    addps     %xmm2, %xmm11
    movaps    %xmm1, %xmm0
    addps     %xmm1, %xmm0
    addps     %xmm0, %xmm11
    subps     %xmm11, %xmm10
    movss     0(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    divps     %xmm0, %xmm9
    movss     4(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    divps     %xmm0, %xmm10
    pxor      %xmm0, %xmm0
    subps     %xmm9, %xmm0
    movaps    %xmm0, %xmm9
    pxor      %xmm0, %xmm0
    subps     %xmm10, %xmm0
    movaps    %xmm0, %xmm10
    movaps    %xmm9, %xmm11
    mulps     %xmm9, %xmm11
    movaps    %xmm10, %xmm0
    mulps     %xmm10, %xmm0
    addps     %xmm0, %xmm11
    movss     .Lspot_one(%rip), %xmm0
    shufps    $0, %xmm0, %xmm0
    addps     %xmm0, %xmm11
    sqrtps    %xmm11, %xmm11
    movss     .Lspot_one(%rip), %xmm0
    shufps    $0, %xmm0, %xmm0
    divps     %xmm11, %xmm0
    movaps    %xmm0, %xmm12
    mulps     %xmm0, %xmm9
    mulps     %xmm0, %xmm10
    movdqu    4(%rsi), %xmm13
    psrld     $24, %xmm13
    cvtdq2ps  %xmm13, %xmm13
    movss     36(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    mulps     %xmm0, %xmm13
    movss     40(%rbp), %xmm11
    shufps    $0, %xmm11, %xmm11
    movss     48(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    movdqa    .Lspot_idx4(%rip), %xmm8
    cvtdq2ps  %xmm8, %xmm8
    mulps     %xmm0, %xmm8
    addps     %xmm8, %xmm11
    movss     12(%rbp), %xmm14
    shufps    $0, %xmm14, %xmm14
    subps     %xmm11, %xmm14
    movss     16(%rbp), %xmm15
    shufps    $0, %xmm15, %xmm15
    movss     44(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    subps     %xmm0, %xmm15
    movss     20(%rbp), %xmm0
    shufps    $0, %xmm0, %xmm0
    subps     %xmm13, %xmm0
    movaps    %xmm0, %xmm13
    movaps    %xmm14, %xmm0
    mulps     %xmm14, %xmm0
    movaps    %xmm15, %xmm1
    mulps     %xmm15, %xmm1
    addps     %xmm1, %xmm0
    movaps    %xmm13, %xmm1
    mulps     %xmm13, %xmm1
    addps     %xmm1, %xmm0
    NORM_INV %xmm0, %xmm14, %xmm15, %xmm13, %xmm6, %xmm7
    pxor      %xmm0, %xmm0
    movaps    %xmm14, %xmm6
    subps     %xmm6, %xmm0
    movss     52(%rbp), %xmm1
    shufps    $0, %xmm1, %xmm1
    mulps     %xmm1, %xmm0
    movaps    %xmm15, %xmm1
    pxor      %xmm7, %xmm7
    subps     %xmm15, %xmm7
    movss     56(%rbp), %xmm2
    shufps    $0, %xmm2, %xmm2
    mulps     %xmm2, %xmm7
    addps     %xmm7, %xmm0
    pxor      %xmm7, %xmm7
    subps     %xmm13, %xmm7
    movss     60(%rbp), %xmm2
    shufps    $0, %xmm2, %xmm2
    mulps     %xmm2, %xmm7
    addps     %xmm7, %xmm0
    pxor      %xmm7, %xmm7
    maxps     %xmm7, %xmm0
    movss     .Lspot_one(%rip), %xmm7
    shufps    $0, %xmm7, %xmm7
    minps     %xmm7, %xmm0
    movss     64(%rbp), %xmm7
    shufps    $0, %xmm7, %xmm7
    movaps    %xmm7, %xmm5
    cmpps     $2, %xmm0, %xmm7
    cmpps     $3, %xmm5, %xmm5
    orps      %xmm5, %xmm7
    andps     %xmm7, %xmm0
    movups    %xmm0, 16(%rsp)
    movaps    %xmm14, %xmm7
    movaps    %xmm15, %xmm1
    movaps    %xmm13, %xmm2
    movss     .Lspot_one(%rip), %xmm0
    shufps    $0, %xmm0, %xmm0
    addps     %xmm0, %xmm2
    movaps    %xmm7, %xmm11
    mulps     %xmm7, %xmm11
    movaps    %xmm1, %xmm0
    mulps     %xmm1, %xmm0
    addps     %xmm0, %xmm11
    movaps    %xmm2, %xmm0
    mulps     %xmm2, %xmm0
    addps     %xmm0, %xmm11
    NORM_INV %xmm11, %xmm7, %xmm1, %xmm2, %xmm8, %xmm0
    movaps    %xmm7, %xmm11
    mulps     %xmm9, %xmm11
    movaps    %xmm1, %xmm0
    mulps     %xmm10, %xmm0
    addps     %xmm0, %xmm11
    movaps    %xmm2, %xmm0
    mulps     %xmm12, %xmm0
    addps     %xmm0, %xmm11
    pxor      %xmm0, %xmm0
    maxps     %xmm0, %xmm11
    movups    %xmm11, 0(%rsp)
    leaq      .Lspot_l2s_data(%rip), %r15
    // Per-pixel specular blocks below (powf + intensity + RGB + L2S + pack).
    SPOT_SPEC_PIXEL 0, 16, 0, 1
    SPOT_SPEC_PIXEL 4, 20, 4, 1
    SPOT_SPEC_PIXEL 8, 24, 8, 1
    SPOT_SPEC_PIXEL 12, 28, 12, 1
    movd      %r13d, %xmm0
    addq      $40, %rsp
    popq      %r15
    popq      %r14
    popq      %r13
    popq      %r12
    popq      %rbp
    retq
