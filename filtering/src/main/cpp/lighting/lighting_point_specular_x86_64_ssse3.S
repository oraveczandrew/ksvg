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
 * Intel x86-64 point-light specular SIMD kernels.
 *
 * PointLightingParams layout (13 x float):
 *   +00 invDx       +04 invDy       +08 k
 *   +12 lightX     +16 lightY     +20 lightZ
 *   +24 lr         +28 lg         +32 lb
 *   +36 ss         +40 ux0        +44 uy
 *   +48 dux
 *
 * srcT/srcM/srcB point at the x-1 pixel of the processed chunk.
 * ux0 is the user-space X coordinate of the first output pixel; uy is
 * the row Y coordinate and dux is the user-space X increment per pixel.
 */

#include "asm_macros.S"

/*
 * Description:
 *   Alpha-byte to scaled float, VEX-encoded form matching the rest of this
 *   (AVX1-class) file: extracts the alpha lane, converts int32->float
 *   (exact for 0..255), and scales. Unlike the SSSE3-header ALPHA_FSCALE,
 *   the 3-operand VEX encoding allows arbitrary src/ch/dst combinations
 *   with no extra moves. Same bit-exactness argument for the normalized
 *   scale-first mulps order (see the header macro).
 *
 * Inputs:
 *   \src, \ch, \scale, \dst as in ALPHA_FSCALE.
 *
 * Output:
 *   \dst = float((\src >> 24) & 0xFF) * \scale
 *
 * Clobbers:
 *   \ch, \dst (written; \src preserved unless aliased)
 */
.macro ALPHA_FSCALE_V src, ch, scale, dst
    vpsrld       $24, \src, \ch
    vcvtdq2ps    \ch, \ch
    vmulps       \scale, \ch, \dst
.endm

.globl SYM(ksvgLightingPointSpecularRowSsse3)
.p2align 4, 0x90
SYM(ksvgLightingPointSpecularRowSsse3):
.cfi_startproc
    testl        %r8d, %r8d
    jle          LBB3_4
    pushq        %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
    movq         %rsp, %rbp
.cfi_def_cfa_register %rbp
    pushq        %r15
    pushq        %r14
    pushq        %r13
    pushq        %r12
    pushq        %rbx
    subq         $88, %rsp
.cfi_offset %rbx, -56
.cfi_offset %r12, -48
.cfi_offset %r13, -40
.cfi_offset %r14, -32
.cfi_offset %r15, -24
    movq         %rcx, %r14
    movq         %rdx, %r15
    movq         %rsi, %r12
    movq         %rdi, %r13
    movl         %r8d, %eax
    movq         %rax, -56(%rbp)  # 8-byte Spill
    xorl         %ebx, %ebx
    vmovss       %xmm0, -44(%rbp)  # 4-byte Spill
    movq         %r9, -64(%rbp)  # 8-byte Spill
.p2align 4, 0x90
LBB3_2:  # =>This Inner Loop Header: Depth=1
    vmovups      (%r9), %ymm3
    vmovups      20(%r9), %ymm1
    vcvtsi2ss    %ebx, %xmm4, %xmm2
    vmovups      %ymm1, -108(%rbp)
    vmovups      %ymm3, -128(%rbp)
    vmulss       48(%r9), %xmm2, %xmm1
    vaddss       40(%r9), %xmm1, %xmm1
    vmovss       %xmm1, -88(%rbp)
    movq         %r13, %rdi
    movq         %r12, %rsi
    movq         %r15, %rdx
    movq         %r14, %rcx
    leaq         -128(%rbp), %r8
    xorl         %r9d, %r9d
    vzeroupper
    // Both wrappers share core4 below (non-linear and linear differ only in
    // the final L2S conversion inside core4's scalar packs).
    callq        SYM(core4)
    movq         -64(%rbp), %r9  # 8-byte Reload
    vmovss       -44(%rbp), %xmm0
    addq         $4, %rbx
    addq         $16, %r14
    addq         $16, %r15
    addq         $16, %r12
    addq         $16, %r13
    cmpq         -56(%rbp), %rbx  # 8-byte Folded Reload
    jb           LBB3_2
    addq         $88, %rsp
    popq         %rbx
    popq         %r12
    popq         %r13
    popq         %r14
    popq         %r15
    popq         %rbp
LBB3_4:
    retq
.cfi_endproc
POINT_LIT4
.p2align 2, 0x0
LCPI4_0:
.long	0x80000000  # float -0
LCPI4_1:
.long	0x3f800000  # float 1
LCPI4_3:
.long	255  # 0xff
POINT_LIT16
.p2align 4, 0x0
LCPI4_2:
.long	0x00000000  # float 0
.long	0x3f800000  # float 1
.long	0x40000000  # float 2
.long	0x40400000  # float 3
LCPI4_4:
.long	8  # 0x8
.long	16  # 0x10
.space	4
.space	4
LCPI4_5:
.long	16  # 0x10
.long	8  # 0x8
.space	4
.space	4
LCPI4_6:
.long	0x3f000000  # float 0.5
.long	0x3f000000  # float 0.5
.long	0x3f000000  # float 0.5
.long	0x3f000000  # float 0.5
POINT_TEXT
.p2align 4, 0x90
SYM(core4):
    // Shared 4-pixel kernel: Sobel window, normalize, per-lane powf for the
    // specular exponent, then scalar L2S packs (or the vector-pack path).
.cfi_startproc
    pushq        %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
    movq         %rsp, %rbp
.cfi_def_cfa_register %rbp
    pushq        %r15
    pushq        %r14
    pushq        %rbx
    subq         $88, %rsp
.cfi_offset %rbx, -40
.cfi_offset %r14, -32
.cfi_offset %r15, -24
    movq         %r9, %r14
    vmovaps      %xmm0, %xmm13
    movq         %r8, %r15
    movq         %rcx, %rbx
    vbroadcastss 36(%r8), %xmm0
    vbroadcastss (%r8), %xmm3
    vbroadcastss 4(%r8), %xmm2
    vmovdqu      (%rdi), %xmm1
    vmovdqu      4(%rdi), %xmm5
    vmovdqu      8(%rdi), %xmm6
    ALPHA_FSCALE_V %xmm1, %xmm1, %xmm0, %xmm4
    ALPHA_FSCALE_V %xmm5, %xmm1, %xmm0, %xmm5
    ALPHA_FSCALE_V %xmm6, %xmm1, %xmm0, %xmm6
    vmovdqu      (%rsi), %xmm7
    vmovdqu      4(%rsi), %xmm1
    vmovdqu      8(%rsi), %xmm8
    ALPHA_FSCALE_V %xmm7, %xmm7, %xmm0, %xmm7
    ALPHA_FSCALE_V %xmm8, %xmm8, %xmm0, %xmm8
    vmovdqu      (%rdx), %xmm9
    vmovdqu      4(%rdx), %xmm10
    vmovdqu      8(%rdx), %xmm11
    ALPHA_FSCALE_V %xmm9, %xmm9, %xmm0, %xmm9
    ALPHA_FSCALE_V %xmm10, %xmm10, %xmm0, %xmm10
    ALPHA_FSCALE_V %xmm11, %xmm11, %xmm0, %xmm11
    vaddps       %xmm6, %xmm8, %xmm12
    vaddps       %xmm11, %xmm8, %xmm8
    vaddps       %xmm8, %xmm12, %xmm8
    vaddps       %xmm7, %xmm9, %xmm12
    vaddps       %xmm7, %xmm12, %xmm7
    vaddps       %xmm7, %xmm4, %xmm7
    vsubps       %xmm7, %xmm8, %xmm7
    vdivps       %xmm3, %xmm7, %xmm3
    vaddps       %xmm10, %xmm9, %xmm7
    vaddps       %xmm11, %xmm10, %xmm8
    vaddps       %xmm7, %xmm8, %xmm7
    vaddps       %xmm6, %xmm5, %xmm6
    vaddps       %xmm6, %xmm5, %xmm5
    vaddps       %xmm5, %xmm4, %xmm4
    vsubps       %xmm4, %xmm7, %xmm4
    vdivps       %xmm2, %xmm4, %xmm2
    vbroadcastss LCPI4_0(%rip), %xmm4  # xmm4 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
    vxorps       %xmm4, %xmm3, %xmm5
    vmulps       %xmm2, %xmm2, %xmm4
    vmulps       %xmm3, %xmm3, %xmm3
    vaddps       %xmm4, %xmm3, %xmm3
    vbroadcastss LCPI4_1(%rip), %xmm4  # xmm4 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vaddps       %xmm4, %xmm3, %xmm3
    vsqrtps      %xmm3, %xmm6
    vdivps       %xmm6, %xmm5, %xmm5
    vdivps       %xmm6, %xmm2, %xmm3
    vdivps       %xmm6, %xmm4, %xmm2
    vbroadcastss 40(%r8), %xmm6
    vbroadcastss 48(%r8), %xmm7
    vmulps       LCPI4_2(%rip), %xmm7, %xmm7
    vaddps       %xmm7, %xmm6, %xmm6
    vbroadcastss 12(%r8), %xmm7
    vsubps       %xmm6, %xmm7, %xmm6
    vmovss       16(%r8), %xmm7  # xmm7 = mem[0],zero,zero,zero
    vsubss       44(%r8), %xmm7, %xmm7
    vbroadcastss %xmm7, %xmm8
    vbroadcastss 20(%r8), %xmm9
    ALPHA_FSCALE_V %xmm1, %xmm1, %xmm0, %xmm0
    vsubps       %xmm0, %xmm9, %xmm0
    vmulss       %xmm7, %xmm7, %xmm1
    vbroadcastss %xmm1, %xmm1
    vmulps       %xmm6, %xmm6, %xmm7
    vaddps       %xmm1, %xmm7, %xmm1
    vmulps       %xmm0, %xmm0, %xmm7
    vaddps       %xmm1, %xmm7, %xmm1
    vsqrtps      %xmm1, %xmm10
    vxorps       %xmm1, %xmm1, %xmm1
    vcmpneqps    %xmm1, %xmm10, %xmm7
    vdivps       %xmm10, %xmm4, %xmm9
    vmulps       %xmm6, %xmm9, %xmm6
    vandps       %xmm6, %xmm7, %xmm6
    vmulps       %xmm9, %xmm8, %xmm8
    vandps       %xmm7, %xmm8, %xmm8
    vmulps       %xmm0, %xmm9, %xmm0
    vaddps       %xmm4, %xmm0, %xmm0
    vblendvps    %xmm7, %xmm0, %xmm4, %xmm0
    vmulps       %xmm8, %xmm8, %xmm7
    vmulps       %xmm6, %xmm6, %xmm9
    vaddps       %xmm7, %xmm9, %xmm7
    vmulps       %xmm0, %xmm0, %xmm9
    vaddps       %xmm7, %xmm9, %xmm7
    vsqrtps      %xmm7, %xmm7
    vcmpneqps    %xmm1, %xmm7, %xmm9
    vdivps       %xmm7, %xmm4, %xmm4
    vmulps       %xmm4, %xmm6, %xmm6
    vandps       %xmm6, %xmm9, %xmm6
    vmulps       %xmm6, %xmm5, %xmm5
    vmulps       %xmm4, %xmm8, %xmm6
    vandps       %xmm6, %xmm9, %xmm6
    vmulps       %xmm6, %xmm3, %xmm3
    vsubps       %xmm3, %xmm5, %xmm3
    vmulps       %xmm4, %xmm0, %xmm0
    vandps       %xmm0, %xmm9, %xmm0
    vmulps       %xmm0, %xmm2, %xmm0
    vaddps       %xmm3, %xmm0, %xmm0
    vmaxps       %xmm1, %xmm0, %xmm2
    vxorps       %xmm5, %xmm5, %xmm5
    vucomiss     %xmm5, %xmm10
    vxorps       %xmm0, %xmm0, %xmm0
    vmovss       %xmm13, -48(%rbp)  # 4-byte Spill
    vmovaps      %xmm10, -96(%rbp)  # 16-byte Spill
    vmovaps      %xmm2, -80(%rbp)  # 16-byte Spill
    jne          LBB4_1
    jnp          LBB4_2
LBB4_1:
    vmovaps      %xmm2, %xmm0
    vmovaps      %xmm13, %xmm1
    CALL(powf)
    vxorps       %xmm5, %xmm5, %xmm5
    vmovaps      -80(%rbp), %xmm2  # 16-byte Reload
    vmovaps      -96(%rbp), %xmm10  # 16-byte Reload
    vmovss       -48(%rbp), %xmm13
    vmulss       8(%r15), %xmm0, %xmm0
LBB4_2:
    vmovss       LCPI4_1(%rip), %xmm3  # xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vminss       %xmm0, %xmm3, %xmm1
    vcmpltss     %xmm5, %xmm0, %xmm0
    vandnps      %xmm1, %xmm0, %xmm0
    vmovaps      %xmm0, -112(%rbp)  # 16-byte Spill
    vmovshdup    %xmm10, %xmm0  # xmm0 = xmm10[1,1,3,3]
    vucomiss     %xmm5, %xmm0
    jne          LBB4_3
    jnp          LBB4_4
LBB4_3:
    vmovshdup    %xmm2, %xmm0  # xmm0 = xmm2[1,1,3,3]
    vmovaps      %xmm13, %xmm1
    CALL(powf)
    vmovss       LCPI4_1(%rip), %xmm3  # xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovaps      -80(%rbp), %xmm2  # 16-byte Reload
    vmovaps      -96(%rbp), %xmm10  # 16-byte Reload
    vmovss       -48(%rbp), %xmm13
    vmulss       8(%r15), %xmm0, %xmm5
LBB4_4:
    vminss       %xmm5, %xmm3, %xmm0
    vxorps       %xmm4, %xmm4, %xmm4
    vcmpltss     %xmm4, %xmm5, %xmm1
    vandnps      %xmm0, %xmm1, %xmm8
    vshufpd      $1, %xmm10, %xmm10, %xmm0  # xmm0 = xmm10[1,0]
    vucomiss     %xmm4, %xmm0
    vxorps       %xmm0, %xmm0, %xmm0
    jne          LBB4_5
    jnp          LBB4_6
LBB4_5:
    vshufpd      $1, %xmm2, %xmm2, %xmm0  # xmm0 = xmm2[1,0]
    vmovaps      %xmm13, %xmm1
    vmovaps      %xmm8, -64(%rbp)  # 16-byte Spill
    CALL(powf)
    vxorps       %xmm4, %xmm4, %xmm4
    vmovss       LCPI4_1(%rip), %xmm3  # xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovaps      -80(%rbp), %xmm2  # 16-byte Reload
    vmovaps      -96(%rbp), %xmm10  # 16-byte Reload
    vmovaps      -64(%rbp), %xmm8  # 16-byte Reload
    vmovss       -48(%rbp), %xmm13
    vmulss       8(%r15), %xmm0, %xmm0
LBB4_6:
    vminss       %xmm0, %xmm3, %xmm1
    vcmpltss     %xmm4, %xmm0, %xmm0
    vandnps      %xmm1, %xmm0, %xmm7
    vshufps      $255, %xmm10, %xmm10, %xmm0  # xmm0 = xmm10[3,3,3,3]
    vucomiss     %xmm4, %xmm0
    jne          LBB4_7
    jnp          LBB4_8
LBB4_7:
    vshufps      $255, %xmm2, %xmm2, %xmm0  # xmm0 = xmm2[3,3,3,3]
    vmovaps      %xmm13, %xmm1
    vmovaps      %xmm7, -48(%rbp)  # 16-byte Spill
    vmovaps      %xmm8, -64(%rbp)  # 16-byte Spill
    CALL(powf)
    vmovss       LCPI4_1(%rip), %xmm3  # xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovaps      -64(%rbp), %xmm8  # 16-byte Reload
    vmovaps      -48(%rbp), %xmm7  # 16-byte Reload
    vmulss       8(%r15), %xmm0, %xmm4
LBB4_8:
    vminss       %xmm4, %xmm3, %xmm0
    vxorps       %xmm1, %xmm1, %xmm1
    vcmpltss     %xmm1, %xmm4, %xmm1
    vandnps      %xmm0, %xmm1, %xmm0
    vmovsd       24(%r15), %xmm5  # xmm5 = mem[0],zero
    vshufps      $225, %xmm5, %xmm5, %xmm4  # xmm4 = xmm5[1,0,2,3]
    vmovss       32(%r15), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovaps      -112(%rbp), %xmm3  # 16-byte Reload
    vmulss       %xmm3, %xmm1, %xmm2
    vaddss       LCPI4_6(%rip), %xmm2, %xmm2  # round-half-up R
    vroundss     $11, %xmm2, %xmm2, %xmm2
    vcvttss2si   %xmm2, %edx
    cmpl         $255, %edx
    movl         $255, %eax
    cmovgel      %eax, %edx
    xorl         %ecx, %ecx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vbroadcastss %xmm3, %xmm2
    vmulps       %xmm2, %xmm4, %xmm2
    vaddps       LCPI4_6(%rip), %xmm2, %xmm2  # round-half-up G/B
    vroundps     $11, %xmm2, %xmm2
    vcvttps2dq   %xmm2, %xmm3
    vpbroadcastd LCPI4_3(%rip), %xmm2  # xmm2 = [255,255,255,255]
    vpminsd      %xmm2, %xmm3, %xmm6
    vpxor        %xmm3, %xmm3, %xmm3
    vpmaxsd      %xmm3, %xmm6, %xmm6
    // With an L2S table, scalar gather packs; otherwise take the
    // vector-pack fast path (.LBB4_9).
    testq        %r14, %r14
    je           LBB4_9
    vpextrd      $1, %xmm6, %esi
    movzbl       (%r14,%rsi), %esi
    vmovd        %xmm6, %edi
    movzbl       (%r14,%rdi), %edi
    movl         %edx, %edx
    movzbl       (%r14,%rdx), %edx
    cmpl         %edi, %esi
    movl         %edi, %r8d
    cmoval       %esi, %r8d
    cmpl         %edx, %r8d
    cmovbel      %edx, %r8d
    shll         $24, %r8d
    shll         $16, %esi
    shll         $8, %edi
    orl          %esi, %edi
    orl          %r8d, %edi
    orl          %edx, %edi
    vmulss       %xmm5, %xmm8, %xmm6
    vaddss       LCPI4_6(%rip), %xmm6, %xmm6  # round-half-up
    vroundss     $11, %xmm6, %xmm6, %xmm6
    vcvttss2si   %xmm6, %edx
    movl         %edi, (%rbx)
    cmpl         $255, %edx
    cmovll       %edx, %eax
    testl        %eax, %eax
    cmovgl       %eax, %ecx
    movzbl       (%r14,%rcx), %eax
    movl         %eax, %ecx
    shll         $16, %ecx
    vshufps      $69, %xmm5, %xmm5, %xmm5  # xmm5 = xmm5[1,1,0,1]
    vinsertps    $16, %xmm1, %xmm5, %xmm5  # xmm5 = xmm5[0],xmm1[0],xmm5[2,3]
    vshufps      $0, %xmm7, %xmm8, %xmm6  # xmm6 = xmm8[0,0],xmm7[0,0]
    vmulps       %xmm6, %xmm5, %xmm5
    vaddps       LCPI4_6(%rip), %xmm5, %xmm5  # round-half-up
    vroundps     $11, %xmm5, %xmm5
    vcvttps2dq   %xmm5, %xmm5
    vpminsd      %xmm2, %xmm5, %xmm5
    vpmaxsd      %xmm3, %xmm5, %xmm5
    vmovd        %xmm5, %edx
    movzbl       (%r14,%rdx), %edx
    vpextrd      $1, %xmm5, %esi
    movzbl       (%r14,%rsi), %esi
    cmpl         %edx, %eax
    cmovbel      %edx, %eax
    cmpl         %esi, %eax
    cmovbel      %esi, %eax
    shll         $24, %eax
    shll         $8, %edx
    orl          %ecx, %edx
    orl          %eax, %edx
    orl          %esi, %edx
    movl         %edx, 4(%rbx)
    vpextrd      $2, %xmm5, %eax
    movzbl       (%r14,%rax), %edx
    vpextrd      $3, %xmm5, %eax
    movzbl       (%r14,%rax), %ecx
    cmpl         %ecx, %edx
    movl         %ecx, %eax
    cmoval       %edx, %eax
    shll         $16, %edx
    shll         $8, %ecx
    orl          %edx, %ecx
    vmovddup     %xmm4, %xmm4  # xmm4 = xmm4[0,0]
    vblendps     $1, %xmm1, %xmm4, %xmm1  # xmm1 = xmm1[0],xmm4[1,2,3]
    vshufps      $36, %xmm1, %xmm1, %xmm1  # xmm1 = xmm1[0,1,2,0]
    vinsertps    $16, %xmm0, %xmm7, %xmm0  # xmm0 = xmm7[0],xmm0[0],xmm7[2,3]
    vshufps      $84, %xmm0, %xmm0, %xmm0  # xmm0 = xmm0[0,1,1,1]
    vmulps       %xmm0, %xmm1, %xmm0
    vaddps       LCPI4_6(%rip), %xmm0, %xmm0  # round-half-up
    vroundps     $11, %xmm0, %xmm0
    vcvttps2dq   %xmm0, %xmm0
    vpminsd      %xmm2, %xmm0, %xmm0
    vpmaxsd      %xmm3, %xmm0, %xmm0
    vmovd        %xmm0, %edx
    movzbl       (%r14,%rdx), %edx
    cmpl         %edx, %eax
    cmovbel      %edx, %eax
    shll         $24, %eax
    orl          %ecx, %eax
    orl          %edx, %eax
    movl         %eax, 8(%rbx)
    vpextrd      $1, %xmm0, %eax
    movzbl       (%r14,%rax), %edx
    vpextrd      $2, %xmm0, %eax
    movzbl       (%r14,%rax), %esi
    vpextrd      $3, %xmm0, %eax
    movzbl       (%r14,%rax), %eax
    jmp          LBB4_10
LBB4_9:
    // No-LUT path: scalar max-pack for pixel 0, then vector scale/round/
    // truncate/clamp for the remaining pixels (lane shuffles below).
    vmovd        %xmm6, %esi
    vpextrd      $1, %xmm6, %edi
    cmpl         %esi, %edi
    movl         %esi, %r8d
    cmoval       %edi, %r8d
    cmpl         %edx, %r8d
    cmovbel      %edx, %r8d
    shll         $24, %r8d
    shll         $16, %edi
    shll         $8, %esi
    orl          %edi, %esi
    orl          %edx, %esi
    orl          %r8d, %esi
    movl         %esi, (%rbx)
    vinsertps    $16, %xmm7, %xmm8, %xmm6  # xmm6 = xmm8[0],xmm7[0],xmm8[2,3]
    vmulps       %xmm6, %xmm5, %xmm7
    vaddps       LCPI4_6(%rip), %xmm7, %xmm7  # +0.5 round-half-up
    vmulps       %xmm6, %xmm4, %xmm4
    vaddps       LCPI4_6(%rip), %xmm4, %xmm4  # +0.5 round-half-up
    vbroadcastss %xmm1, %xmm8
    vmulps       %xmm6, %xmm8, %xmm6
    vaddps       LCPI4_6(%rip), %xmm6, %xmm6  # +0.5 round-half-up
    vroundps     $11, %xmm4, %xmm4
    vcvttps2dq   %xmm4, %xmm4
    vpminsd      %xmm2, %xmm4, %xmm4
    vpmaxsd      %xmm3, %xmm4, %xmm4
    vroundps     $11, %xmm7, %xmm7
    vcvttps2dq   %xmm7, %xmm7
    vpminsd      %xmm2, %xmm7, %xmm7
    vpmaxsd      %xmm3, %xmm7, %xmm7
    vroundps     $11, %xmm6, %xmm6
    vcvttps2dq   %xmm6, %xmm6
    vpminsd      %xmm2, %xmm6, %xmm2
    vpmaxsd      %xmm3, %xmm2, %xmm2
    vpblendd     $2, %xmm4, %xmm7, %xmm3  # xmm3 = xmm7[0],xmm4[1],xmm7[2,3]
    vpblendd     $2, %xmm7, %xmm4, %xmm6  # xmm6 = xmm4[0],xmm7[1],xmm4[2,3]
    vpmaxud      %xmm6, %xmm3, %xmm3
    vpmaxud      %xmm2, %xmm3, %xmm3
    vpslld       $24, %xmm3, %xmm3
    vpsllvd      LCPI4_4(%rip), %xmm4, %xmm4
    vpsllvd      LCPI4_5(%rip), %xmm7, %xmm6
    vmulss       %xmm0, %xmm5, %xmm7
    vaddss       LCPI4_6(%rip), %xmm7, %xmm7  # +0.5 round-half-up
    vroundss     $11, %xmm7, %xmm7, %xmm7
    vcvttss2si   %xmm7, %edx
    vpor         %xmm6, %xmm4, %xmm4
    cmpl         $255, %edx
    cmovgel      %eax, %edx
    testl        %edx, %edx
    cmovlel      %ecx, %edx
    vmovshdup    %xmm5, %xmm5  # xmm5 = xmm5[1,1,3,3]
    vmulss       %xmm0, %xmm5, %xmm5
    vaddss       LCPI4_6(%rip), %xmm5, %xmm5  # +0.5 round-half-up
    vroundss     $11, %xmm5, %xmm5, %xmm5
    vcvttss2si   %xmm5, %esi
    vpor         %xmm2, %xmm3, %xmm2
    cmpl         $255, %esi
    cmovgel      %eax, %esi
    vpor         %xmm2, %xmm4, %xmm2
    testl        %esi, %esi
    cmovlel      %ecx, %esi
    vmulss       %xmm0, %xmm1, %xmm0
    vaddss       LCPI4_6(%rip), %xmm0, %xmm0  # +0.5 round-half-up
    vroundss     $11, %xmm0, %xmm0, %xmm0
    vcvttss2si   %xmm0, %edi
    vmovq        %xmm2, 4(%rbx)
    cmpl         $255, %edi
    cmovll       %edi, %eax
    testl        %eax, %eax
    cmovlel      %ecx, %eax
LBB4_10:
    // Shared epilogue (frame restore + return).
    cmpl         %esi, %edx
    movl         %esi, %ecx
    cmoval       %edx, %ecx
    cmpl         %eax, %ecx
    cmovbel      %eax, %ecx
    shll         $24, %ecx
    shll         $16, %edx
    shll         $8, %esi
    orl          %edx, %esi
    orl          %eax, %esi
    orl          %ecx, %esi
    movl         %esi, 12(%rbx)
    addq         $88, %rsp
    popq         %rbx
    popq         %r14
    popq         %r15
    popq         %rbp
    retq
.cfi_endproc
.globl SYM(ksvgLightingPointSpecularRowSsse3Linear)
.p2align 4, 0x90
SYM(ksvgLightingPointSpecularRowSsse3Linear):
.cfi_startproc
    testl        %r8d, %r8d
    jle          LBB5_4
    pushq        %rbp
.cfi_def_cfa_offset 16
.cfi_offset %rbp, -16
    movq         %rsp, %rbp
.cfi_def_cfa_register %rbp
    pushq        %r15
    pushq        %r14
    pushq        %r13
    pushq        %r12
    pushq        %rbx
    subq         $88, %rsp
.cfi_offset %rbx, -56
.cfi_offset %r12, -48
.cfi_offset %r13, -40
.cfi_offset %r14, -32
.cfi_offset %r15, -24
    movq         %rcx, %r14
    movq         %rdx, %r15
    movq         %rsi, %r12
    movq         %rdi, %r13
    movl         %r8d, %eax
    movq         %rax, -56(%rbp)  # 8-byte Spill
    xorl         %ebx, %ebx
    vmovss       %xmm0, -44(%rbp)  # 4-byte Spill
    movq         %r9, -64(%rbp)  # 8-byte Spill
.p2align 4, 0x90
LBB5_2:  # =>This Inner Loop Header: Depth=1
    vmovups      (%r9), %ymm3
    vmovups      20(%r9), %ymm1
    vcvtsi2ss    %ebx, %xmm4, %xmm2
    vmovups      %ymm1, -108(%rbp)
    vmovups      %ymm3, -128(%rbp)
    vmulss       48(%r9), %xmm2, %xmm1
    vaddss       40(%r9), %xmm1, %xmm1
    vmovss       %xmm1, -88(%rbp)
    movq         %r13, %rdi
    movq         %r12, %rsi
    movq         %r15, %rdx
    movq         %r14, %rcx
    leaq         -128(%rbp), %r8
    movq         16(%rbp), %r9
    vzeroupper
    callq        SYM(core4)
    movq         -64(%rbp), %r9  # 8-byte Reload
    vmovss       -44(%rbp), %xmm0
    addq         $4, %rbx
    addq         $16, %r14
    addq         $16, %r15
    addq         $16, %r12
    addq         $16, %r13
    cmpq         -56(%rbp), %rbx  # 8-byte Folded Reload
    jb           LBB5_2
    addq         $88, %rsp
    popq         %rbx
    popq         %r12
    popq         %r13
    popq         %r14
    popq         %r15
    popq         %rbp
LBB5_4:
    retq
.cfi_endproc
