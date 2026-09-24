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

/* Spot-light diffuse SIMD kernel.
 * SpotLightingParams layout (17 x float):
 *   +00 invDx +04 invDy +08 k
 *   +12 lightX +16 lightY +20 lightZ
 *   +24 lr +28 lg +32 lb +36 ss
 *   +40 ux0 +44 uy +48 dux
 *   +52 spotDirX +56 spotDirY +60 spotDirZ +64 spotCos
 *
 * srcT/srcM/srcB point at the x-1 pixel of the processed chunk.
 */
.text
RODATA32
.p2align 5, 0x0
.LCPI0_0:
.long	0  // 0x0
.long	1  // 0x1
.long	2  // 0x2
.long	3  // 0x3
.long	4  // 0x4
.long	5  // 0x5
.long	6  // 0x6
.long	7  // 0x7
RODATA4
.p2align 2, 0x0
.LCPI0_1:
.long	0x80000000  // float -0
.LCPI0_2:
.long	0x3f800000  // float 1
.LCPI0_3:
.long	1258291200  // 0x4b000000
.LCPI0_4:
.long	1392508928  // 0x53000000
.LCPI0_5:
.long	0x53000080  // float 5.49764202E+11
.LCPI0_6:
.long	0x437f0000  // float 255
.LCPI0_7:
.long	8  // 0x8
.LCPI0_8:
.long	4278190080  // 0xff000000
RODATA16
.p2align 4, 0x0
.LCPI0_9:
.long	16  // 0x10
.long	8  // 0x8
.zero	4
.zero	4
.LCPI0_10:
.zero	16
RODATA8
.LCPI0_11:
.byte	0  // 0x0
.byte	1  // 0x1
.byte	2  // 0x2
.byte	3  // 0x3
.byte	4  // 0x4
.byte	5  // 0x5
.byte	6  // 0x6
.byte	7  // 0x7
.text
RODATA4
.p2align 2, 0x0
.LSPOTAVX2_C0:
.long	0x3f800000  // float 1
.LSPOTAVX2_C1:
.long	0x40a00000  // float 5
.LSPOTAVX2_C4:
.long	0x437f0000  // float 255
.LSPOTAVX2_HALF:
.long	0x3f000000  // float 0.5
RODATA16
.p2align 4, 0x0
.LSPOTAVX2_C2:
.long	0x40c00000  // float 6
.long	0x40e00000  // float 7
.zero	4
.zero	4
.LSPOTAVX2_C3:
.long	0x40800000  // float 4
.long	0x3f800000  // float 1
.long	0x40000000  // float 2
.long	0x40400000  // float 3
.LSPOTAVX2_C6:
.long	0x40c00000  // float 6
.long	0x40e00000  // float 7
.long	0x00000000  // float 0
.long	0x00000000  // float 0
RODATA8
.p2align 3, 0x0
.LSPOTAVX2_C5:
.quad	-72057589759737856  // 0xff000000ff000000
.text
.globl SYM(ksvgLightingSpotDiffuseRowAvx2)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingSpotDiffuseRowAvx2), @function)
SYM(ksvgLightingSpotDiffuseRowAvx2):
    // Caller contract: count is a multiple of 8 (C++ passes (ixHi-x)&~7);
    // there is no sub-8px tail here, scalar C++ covers row edges/tails.
    testl        %r8d, %r8d
    jle          LSPOTAVX2_DONE
    // Broadcast surface scale + vector constants for the loop below.
    vbroadcastss 36(%r9), %ymm0
    movl         %r8d, %eax
    xorl         %r8d, %r8d
    vbroadcastss .LSPOTAVX2_C0(%rip), %ymm1  // ymm1 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vxorps       %xmm2, %xmm2, %xmm2
    vmovss       .LSPOTAVX2_C1(%rip), %xmm3  // xmm3 = [5.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovsd       .LSPOTAVX2_C6(%rip), %xmm4  // xmm4 = [6.0E+0,7.0E+0,0.0E+0,0.0E+0]
    vmovaps      .LSPOTAVX2_C3(%rip), %xmm5  // xmm5 = [4.0E+0,1.0E+0,2.0E+0,3.0E+0]
    vbroadcastss .LSPOTAVX2_C4(%rip), %ymm6  // ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
    vpbroadcastq .LSPOTAVX2_C5(%rip), %ymm7  // ymm7 = [18374686483949813760,18374686483949813760,18374686483949813760,18374686483949813760]
.p2align 4, 0x90
LSPOTAVX2_LOOP:
    // Sobel window: row alphas -> scaled heights, 1:2:1 sums + derivatives.
    vmovdqu      (%rdi,%r8,4), %ymm8
    vmovdqu      4(%rdi,%r8,4), %ymm9
    vmovdqu      8(%rdi,%r8,4), %ymm10
    ALPHA_FSCALE %ymm8, %ymm8, %ymm0, %ymm8
    ALPHA_FSCALE %ymm9, %ymm9, %ymm0, %ymm9
    ALPHA_FSCALE %ymm10, %ymm10, %ymm0, %ymm10
    vsubps       %ymm8, %ymm10, %ymm12
    vaddps       %ymm9, %ymm9, %ymm9
    vaddps       %ymm9, %ymm8, %ymm8
    vaddps       %ymm8, %ymm10, %ymm8
    vsubps       %ymm8, %ymm2, %ymm8
    vmovdqu      (%rsi,%r8,4), %ymm9
    vmovdqu      4(%rsi,%r8,4), %ymm11
    vmovdqu      8(%rsi,%r8,4), %ymm10
    ALPHA_FSCALE %ymm9, %ymm9, %ymm0, %ymm9
    ALPHA_FSCALE %ymm10, %ymm10, %ymm0, %ymm10
    vaddps       %ymm10, %ymm10, %ymm10
    vaddps       %ymm10, %ymm12, %ymm10
    vaddps       %ymm9, %ymm9, %ymm9
    vsubps       %ymm9, %ymm10, %ymm9
    vmovdqu      (%rdx,%r8,4), %ymm10
    vmovdqu      4(%rdx,%r8,4), %ymm12
    vmovdqu      8(%rdx,%r8,4), %ymm13
    ALPHA_FSCALE %ymm10, %ymm10, %ymm0, %ymm10
    ALPHA_FSCALE %ymm12, %ymm12, %ymm0, %ymm12
    ALPHA_FSCALE %ymm13, %ymm13, %ymm0, %ymm13
    vsubps       %ymm10, %ymm13, %ymm14
    vaddps       %ymm14, %ymm9, %ymm9
    vaddps       %ymm12, %ymm12, %ymm12
    vbroadcastss (%r9), %ymm14
    vaddps       %ymm12, %ymm10, %ymm10
    vdivps       %ymm14, %ymm9, %ymm9
    vaddps       %ymm10, %ymm13, %ymm10
    vaddps       %ymm10, %ymm8, %ymm8
    vbroadcastss 4(%r9), %ymm10
    vdivps       %ymm10, %ymm8, %ymm10
    vsubps       %ymm9, %ymm2, %ymm8
    vsubps       %ymm10, %ymm2, %ymm9
    vmulps       %ymm8, %ymm8, %ymm10
    vmulps       %ymm9, %ymm9, %ymm12
    vaddps       %ymm12, %ymm10, %ymm10
    vaddps       %ymm1, %ymm10, %ymm10
    // Normalize + spot-cone factor (cutoff) + intensity = k * factor * dot.
    vsqrtps      %ymm10, %ymm10
    vdivps       %ymm10, %ymm8, %ymm8  // nx = nx0 / nLen
    vdivps       %ymm10, %ymm9, %ymm9  // ny = ny0 / nLen
    vpsrld       $24, %ymm11, %ymm11
    vxorps       %xmm15, %xmm15, %xmm15
    vcvtsi2ss    %r8d, %xmm15, %xmm12
    vcvtdq2ps    %ymm11, %ymm11
    vmulps       %ymm0, %ymm11, %ymm11
    vaddss       %xmm3, %xmm12, %xmm13
    vbroadcastss %xmm12, %xmm12
    vaddps       %xmm5, %xmm12, %xmm14
    vpermpd      $196, %ymm14, %ymm15  // ymm15 = ymm14[0,1,0,3]
    vblendps     $1, %ymm12, %ymm15, %ymm15  // ymm15 = ymm12[0],ymm15[1,2,3,4,5,6,7]
    vaddps       %xmm4, %xmm12, %xmm12
    vbroadcastss %xmm13, %ymm13
    vblendps     $32, %ymm13, %ymm15, %ymm13  // ymm13 = ymm15[0,1,2,3,4],ymm13[5],ymm15[6,7]
    vinsertf128  $1, %xmm12, %ymm14, %ymm12
    vshufpd      $2, %ymm12, %ymm13, %ymm12  // ymm12 = ymm13[0],ymm12[1],ymm13[2],ymm12[2]
    vbroadcastss 40(%r9), %ymm13
    vbroadcastss 48(%r9), %ymm14
    vmulps       %ymm14, %ymm12, %ymm12
    vaddps       %ymm12, %ymm13, %ymm12
    vbroadcastss 12(%r9), %ymm13
    vsubps       %ymm12, %ymm13, %ymm12
    vmovss       16(%r9), %xmm13  // xmm13 = mem[0],zero,zero,zero
    vsubss       44(%r9), %xmm13, %xmm13
    vbroadcastss 20(%r9), %ymm14
    vsubps       %ymm11, %ymm14, %ymm11
    vmulps       %ymm12, %ymm12, %ymm14
    vmulss       %xmm13, %xmm13, %xmm15
    vbroadcastss %xmm15, %ymm15
    vaddps       %ymm15, %ymm14, %ymm14
    vmulps       %ymm11, %ymm11, %ymm15
    vaddps       %ymm15, %ymm14, %ymm14
    vsqrtps      %ymm14, %ymm15
    vdivps       %ymm15, %ymm1, %ymm15
    vcmpneq_oqps %ymm2, %ymm14, %ymm14
    vandps       %ymm15, %ymm14, %ymm14
    vbroadcastss %xmm13, %ymm13
    vmulps       %ymm14, %ymm12, %ymm12
    vmulps       %ymm14, %ymm13, %ymm13
    vmulps       %ymm14, %ymm11, %ymm11
    vmulps       %ymm12, %ymm8, %ymm8
    vmulps       %ymm13, %ymm9, %ymm9
    vaddps       %ymm9, %ymm8, %ymm8
    vdivps       %ymm10, %ymm1, %ymm9
    vmulps       %ymm11, %ymm9, %ymm9
    vaddps       %ymm8, %ymm9, %ymm8
    vbroadcastss 52(%r9), %ymm9
    vmulps       %ymm12, %ymm9, %ymm9
    vbroadcastss 56(%r9), %ymm10
    vmulps       %ymm13, %ymm10, %ymm10
    vmaxps       %ymm2, %ymm8, %ymm8
    vaddps       %ymm10, %ymm9, %ymm9
    vbroadcastss 60(%r9), %ymm10
    vmulps       %ymm11, %ymm10, %ymm10
    vaddps       %ymm9, %ymm10, %ymm9
    vsubps       %ymm9, %ymm2, %ymm9
    vmaxps       %ymm2, %ymm9, %ymm9
    vbroadcastss 64(%r9), %ymm10
    vcmpleps     %ymm9, %ymm10, %ymm10
    vandps       %ymm9, %ymm10, %ymm9
    vbroadcastss 8(%r9), %ymm10
    vmulps       %ymm10, %ymm8, %ymm8
    vmulps       %ymm9, %ymm8, %ymm8
    vminps       %ymm1, %ymm8, %ymm8
    vbroadcastss 24(%r9), %ymm9
    vmulps       %ymm9, %ymm8, %ymm9
    vbroadcastss 28(%r9), %ymm10
    vbroadcastss 32(%r9), %ymm11
    vmulps       %ymm10, %ymm8, %ymm10
    vmulps       %ymm11, %ymm8, %ymm8
    vbroadcastss .LSPOTAVX2_HALF(%rip), %ymm11
    vaddps       %ymm11, %ymm9, %ymm9  // round-half-up R
    vminps       %ymm6, %ymm9, %ymm9
    vcvttps2dq   %ymm9, %ymm9
    vaddps       %ymm11, %ymm10, %ymm10  // round-half-up G
    vminps       %ymm6, %ymm10, %ymm10
    vcvttps2dq   %ymm10, %ymm10
    // Pack R/G/B (round-half-up + truncate + int clamp) with full alpha.
    vpslld       $16, %ymm9, %ymm9
    vpslld       $8, %ymm10, %ymm10
    vpor         %ymm9, %ymm10, %ymm9
    vaddps       %ymm11, %ymm8, %ymm8  // round-half-up B
    vminps       %ymm6, %ymm8, %ymm8
    vcvttps2dq   %ymm8, %ymm8
    vpor         %ymm7, %ymm8, %ymm8
    vpor         %ymm8, %ymm9, %ymm8
    vmovdqu      %ymm8, (%rcx,%r8,4)
    addq         $8, %r8
    cmpq         %rax, %r8
    jb           LSPOTAVX2_LOOP
LSPOTAVX2_DONE:
    vzeroupper
    retq
.Lfunc_end0:
SIZE(SYM(ksvgLightingSpotDiffuseRowAvx2))
RODATA4
.p2align 2, 0x0
.LCPI1_0:
.long	0x80000000  // float -0
.LCPI1_1:
.long	0x3f800000  // float 1
.LCPI1_2:
.long	0x437f0000  // float 255
.LCPI1_4:
.long	0x3f000000  // float 0.5
RODATA16
.p2align 4, 0x0
.LCPI1_3:
.zero	16
.text
.globl SYM(ksvgLightingSpotDiffuseRowAvx2Linear)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingSpotDiffuseRowAvx2Linear), @function)
SYM(ksvgLightingSpotDiffuseRowAvx2Linear):
    // Caller contract: count is a multiple of 8 (C++ passes (ixHi-x)&~7);
    // there is no sub-8px tail here, scalar C++ covers row edges/tails.
    // 8px/iter vector loop: the proven sRGB front half through the R/G/B
    // int converts, then exact L2S bytes via the scalar LUT (GPR lookups).
    testl        %r8d, %r8d
    jle          .LBB1_4
    pushq        %r15                  // LUT base; single push keeps rsp 16B-aligned
    leaq         .Lspot_l2s_data(%rip), %r15
    vbroadcastss 36(%r9), %ymm0
    movl         %r8d, %eax
    xorl         %r8d, %r8d
    vbroadcastss .LSPOTAVX2_C0(%rip), %ymm1  // ymm1 = [1.0E+0 x 8]
    vxorps       %xmm2, %xmm2, %xmm2
    vmovss       .LSPOTAVX2_C1(%rip), %xmm3  // xmm3 = [5.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovsd       .LSPOTAVX2_C6(%rip), %xmm4  // xmm4 = [6.0E+0,7.0E+0,0.0E+0,0.0E+0]
    vmovaps      .LSPOTAVX2_C3(%rip), %xmm5  // xmm5 = [4.0E+0,1.0E+0,2.0E+0,3.0E+0]
    vbroadcastss .LSPOTAVX2_C4(%rip), %ymm6  // ymm6 = [2.55E+2 x 8]
    vpbroadcastq .LSPOTAVX2_C5(%rip), %ymm7  // ymm7 = [0xff000000ff000000 x 4]
.p2align 4, 0x90
.LSPOT_LINEAR8_LOOP:
    // Sobel window: row alphas -> scaled heights, 1:2:1 sums + derivatives.
    vmovdqu      (%rdi,%r8,4), %ymm8
    vmovdqu      4(%rdi,%r8,4), %ymm9
    vmovdqu      8(%rdi,%r8,4), %ymm10
    ALPHA_FSCALE %ymm8, %ymm8, %ymm0, %ymm8
    ALPHA_FSCALE %ymm9, %ymm9, %ymm0, %ymm9
    ALPHA_FSCALE %ymm10, %ymm10, %ymm0, %ymm10
    vsubps       %ymm8, %ymm10, %ymm12
    vaddps       %ymm9, %ymm9, %ymm9
    vaddps       %ymm9, %ymm8, %ymm8
    vaddps       %ymm8, %ymm10, %ymm8
    vsubps       %ymm8, %ymm2, %ymm8
    vmovdqu      (%rsi,%r8,4), %ymm9
    vmovdqu      4(%rsi,%r8,4), %ymm11
    vmovdqu      8(%rsi,%r8,4), %ymm10
    ALPHA_FSCALE %ymm9, %ymm9, %ymm0, %ymm9
    ALPHA_FSCALE %ymm10, %ymm10, %ymm0, %ymm10
    vaddps       %ymm10, %ymm10, %ymm10
    vaddps       %ymm10, %ymm12, %ymm10
    vaddps       %ymm9, %ymm9, %ymm9
    vsubps       %ymm9, %ymm10, %ymm9
    vmovdqu      (%rdx,%r8,4), %ymm10
    vmovdqu      4(%rdx,%r8,4), %ymm12
    vmovdqu      8(%rdx,%r8,4), %ymm13
    ALPHA_FSCALE %ymm10, %ymm10, %ymm0, %ymm10
    ALPHA_FSCALE %ymm12, %ymm12, %ymm0, %ymm12
    ALPHA_FSCALE %ymm13, %ymm13, %ymm0, %ymm13
    vsubps       %ymm10, %ymm13, %ymm14
    vaddps       %ymm14, %ymm9, %ymm9
    vaddps       %ymm12, %ymm12, %ymm12
    vbroadcastss (%r9), %ymm14
    vaddps       %ymm12, %ymm10, %ymm10
    vdivps       %ymm14, %ymm9, %ymm9
    vaddps       %ymm10, %ymm13, %ymm10
    vaddps       %ymm10, %ymm8, %ymm8
    vbroadcastss 4(%r9), %ymm10
    vdivps       %ymm10, %ymm8, %ymm10
    vsubps       %ymm9, %ymm2, %ymm8
    vsubps       %ymm10, %ymm2, %ymm9
    vmulps       %ymm8, %ymm8, %ymm10
    vmulps       %ymm9, %ymm9, %ymm12
    vaddps       %ymm12, %ymm10, %ymm10
    vaddps       %ymm1, %ymm10, %ymm10
    // Normalize + spot-cone factor (cutoff) + intensity = k * factor * dot.
    vsqrtps      %ymm10, %ymm10
    vdivps       %ymm10, %ymm8, %ymm8  // nx = nx0 / nLen
    vdivps       %ymm10, %ymm9, %ymm9  // ny = ny0 / nLen
    vpsrld       $24, %ymm11, %ymm11
    vxorps       %xmm15, %xmm15, %xmm15
    vcvtsi2ss    %r8d, %xmm15, %xmm12
    vcvtdq2ps    %ymm11, %ymm11
    vmulps       %ymm0, %ymm11, %ymm11
    vaddss       %xmm3, %xmm12, %xmm13
    vbroadcastss %xmm12, %xmm12
    vaddps       %xmm5, %xmm12, %xmm14
    vpermpd      $196, %ymm14, %ymm15  // ymm15 = ymm14[0,1,0,3]
    vblendps     $1, %ymm12, %ymm15, %ymm15  // ymm15 = ymm12[0],ymm15[1..7]
    vaddps       %xmm4, %xmm12, %xmm12
    vbroadcastss %xmm13, %ymm13
    vblendps     $32, %ymm13, %ymm15, %ymm13  // ymm13 = ymm15[0..4],ymm13[5],ymm15[6,7]
    vinsertf128  $1, %xmm12, %ymm14, %ymm12
    vshufpd      $2, %ymm12, %ymm13, %ymm12  // ymm12 = ymm13[0],ymm12[1],ymm13[2],ymm12[2]
    vbroadcastss 40(%r9), %ymm13
    vbroadcastss 48(%r9), %ymm14
    vmulps       %ymm14, %ymm12, %ymm12
    vaddps       %ymm12, %ymm13, %ymm12
    vbroadcastss 12(%r9), %ymm13
    vsubps       %ymm12, %ymm13, %ymm12
    vmovss       16(%r9), %xmm13  // xmm13 = mem[0],zero,zero,zero
    vsubss       44(%r9), %xmm13, %xmm13
    vbroadcastss 20(%r9), %ymm14
    vsubps       %ymm11, %ymm14, %ymm11
    vmulps       %ymm12, %ymm12, %ymm14
    vmulss       %xmm13, %xmm13, %xmm15
    vbroadcastss %xmm15, %ymm15
    vaddps       %ymm15, %ymm14, %ymm14
    vmulps       %ymm11, %ymm11, %ymm15
    vaddps       %ymm15, %ymm14, %ymm14
    vsqrtps      %ymm14, %ymm15
    vdivps       %ymm15, %ymm1, %ymm15
    vcmpneq_oqps %ymm2, %ymm14, %ymm14
    vandps       %ymm15, %ymm14, %ymm14
    vbroadcastss %xmm13, %ymm13
    vmulps       %ymm14, %ymm12, %ymm12
    vmulps       %ymm14, %ymm13, %ymm13
    vmulps       %ymm14, %ymm11, %ymm11
    vmulps       %ymm12, %ymm8, %ymm8
    vmulps       %ymm13, %ymm9, %ymm9
    vaddps       %ymm9, %ymm8, %ymm8
    vdivps       %ymm10, %ymm1, %ymm9
    vmulps       %ymm11, %ymm9, %ymm9
    vaddps       %ymm8, %ymm9, %ymm8
    vbroadcastss 52(%r9), %ymm9
    vmulps       %ymm12, %ymm9, %ymm9
    vbroadcastss 56(%r9), %ymm10
    vmulps       %ymm13, %ymm10, %ymm10
    vmaxps       %ymm2, %ymm8, %ymm8
    vaddps       %ymm10, %ymm9, %ymm9
    vbroadcastss 60(%r9), %ymm10
    vmulps       %ymm11, %ymm10, %ymm10
    vaddps       %ymm9, %ymm10, %ymm9
    vsubps       %ymm9, %ymm2, %ymm9
    vmaxps       %ymm2, %ymm9, %ymm9
    vbroadcastss 64(%r9), %ymm10
    vcmpleps     %ymm9, %ymm10, %ymm10
    vandps       %ymm9, %ymm10, %ymm9
    vbroadcastss 8(%r9), %ymm10
    vmulps       %ymm10, %ymm8, %ymm8
    vmulps       %ymm9, %ymm8, %ymm8
    vminps       %ymm1, %ymm8, %ymm8
    // k<0 guard (cf. SSSE3 SIGSEGV): lower-clamp intensity before the LUT
    // tail; mirrors the scalar cmpltss/andnps zeroing pair. Upper clamp is
    // the vminps above, shared with the sRGB twin.
    vmaxps       %ymm2, %ymm8, %ymm8
    vbroadcastss 24(%r9), %ymm9   // lr
    vmulps       %ymm9, %ymm8, %ymm9  // R = intensity * lr
    vbroadcastss 28(%r9), %ymm10  // lg
    vbroadcastss 32(%r9), %ymm11  // lb
    vmulps       %ymm10, %ymm8, %ymm10  // G = intensity * lg
    vmulps       %ymm11, %ymm8, %ymm8  // B = intensity * lb
    vbroadcastss .LSPOTAVX2_HALF(%rip), %ymm11
    vaddps       %ymm11, %ymm9, %ymm9  // round-half-up R
    vminps       %ymm6, %ymm9, %ymm9
    vcvttps2dq   %ymm9, %ymm9
    vaddps       %ymm11, %ymm10, %ymm10  // round-half-up G
    vminps       %ymm6, %ymm10, %ymm10
    vcvttps2dq   %ymm10, %ymm10
    // R/G int vectors are ready in ymm9/ymm10 (+ B floats in ymm8):
    // int-convert B, split 128b lanes, then exact sRGB bytes via the scalar
    // LUT (same table, same indices the 1px loop feeds L2S_SPOT).
    vaddps       %ymm11, %ymm8, %ymm8  // round-half-up B
    vminps       %ymm6, %ymm8, %ymm8
    vcvttps2dq   %ymm8, %ymm8      // B ints
    vextracti128 $1, %ymm9, %xmm11
    vextracti128 $1, %ymm10, %xmm12
    vextracti128 $1, %ymm8, %xmm13
    // Pixels 0-3 (low lane).
    vmovd        %xmm9, %r11d
    L2S_SPOT     %r11d               // sRGB(R0)
    shll         $16, %r11d
    vmovd        %xmm10, %r10d
    L2S_SPOT     %r10d               // sRGB(G0)
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm8, %r10d
    L2S_SPOT     %r10d               // sRGB(B0)
    orl          %r10d, %r11d
    orl          $-16777216, %r11d   // force alpha
    movl         %r11d, (%rcx,%r8,4)
    vpsrldq      $4, %xmm9, %xmm9
    vpsrldq      $4, %xmm10, %xmm10
    vpsrldq      $4, %xmm8, %xmm8
    // Pixel 1.
    vmovd        %xmm9, %r11d
    L2S_SPOT     %r11d
    shll         $16, %r11d
    vmovd        %xmm10, %r10d
    L2S_SPOT     %r10d
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm8, %r10d
    L2S_SPOT     %r10d
    orl          %r10d, %r11d
    orl          $-16777216, %r11d
    movl         %r11d, 4(%rcx,%r8,4)
    vpsrldq      $4, %xmm9, %xmm9
    vpsrldq      $4, %xmm10, %xmm10
    vpsrldq      $4, %xmm8, %xmm8
    // Pixel 2.
    vmovd        %xmm9, %r11d
    L2S_SPOT     %r11d
    shll         $16, %r11d
    vmovd        %xmm10, %r10d
    L2S_SPOT     %r10d
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm8, %r10d
    L2S_SPOT     %r10d
    orl          %r10d, %r11d
    orl          $-16777216, %r11d
    movl         %r11d, 8(%rcx,%r8,4)
    vpsrldq      $4, %xmm9, %xmm9
    vpsrldq      $4, %xmm10, %xmm10
    vpsrldq      $4, %xmm8, %xmm8
    // Pixel 3.
    vmovd        %xmm9, %r11d
    L2S_SPOT     %r11d
    shll         $16, %r11d
    vmovd        %xmm10, %r10d
    L2S_SPOT     %r10d
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm8, %r10d
    L2S_SPOT     %r10d
    orl          %r10d, %r11d
    orl          $-16777216, %r11d
    movl         %r11d, 12(%rcx,%r8,4)
    // Pixels 4-7 (high lane).
    vmovd        %xmm11, %r11d
    L2S_SPOT     %r11d               // sRGB(R4)
    shll         $16, %r11d
    vmovd        %xmm12, %r10d
    L2S_SPOT     %r10d               // sRGB(G4)
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm13, %r10d
    L2S_SPOT     %r10d               // sRGB(B4)
    orl          %r10d, %r11d
    orl          $-16777216, %r11d   // force alpha
    movl         %r11d, 16(%rcx,%r8,4)
    vpsrldq      $4, %xmm11, %xmm11
    vpsrldq      $4, %xmm12, %xmm12
    vpsrldq      $4, %xmm13, %xmm13
    // Pixel 5.
    vmovd        %xmm11, %r11d
    L2S_SPOT     %r11d
    shll         $16, %r11d
    vmovd        %xmm12, %r10d
    L2S_SPOT     %r10d
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm13, %r10d
    L2S_SPOT     %r10d
    orl          %r10d, %r11d
    orl          $-16777216, %r11d
    movl         %r11d, 20(%rcx,%r8,4)
    vpsrldq      $4, %xmm11, %xmm11
    vpsrldq      $4, %xmm12, %xmm12
    vpsrldq      $4, %xmm13, %xmm13
    // Pixel 6.
    vmovd        %xmm11, %r11d
    L2S_SPOT     %r11d
    shll         $16, %r11d
    vmovd        %xmm12, %r10d
    L2S_SPOT     %r10d
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm13, %r10d
    L2S_SPOT     %r10d
    orl          %r10d, %r11d
    orl          $-16777216, %r11d
    movl         %r11d, 24(%rcx,%r8,4)
    vpsrldq      $4, %xmm11, %xmm11
    vpsrldq      $4, %xmm12, %xmm12
    vpsrldq      $4, %xmm13, %xmm13
    // Pixel 7.
    vmovd        %xmm11, %r11d
    L2S_SPOT     %r11d
    shll         $16, %r11d
    vmovd        %xmm12, %r10d
    L2S_SPOT     %r10d
    shll         $8, %r10d
    orl          %r10d, %r11d
    vmovd        %xmm13, %r10d
    L2S_SPOT     %r10d
    orl          %r10d, %r11d
    orl          $-16777216, %r11d
    movl         %r11d, 28(%rcx,%r8,4)
    addq         $8, %r8
    cmpq         %rax, %r8
    jb           .LSPOT_LINEAR8_LOOP
.LBB1_4:
    vzeroupper
    popq         %r15
    retq
.Lfunc_end1:
SIZE(SYM(ksvgLightingSpotDiffuseRowAvx2Linear))
GNU_STACK
