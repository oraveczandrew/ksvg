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
.p2align 5, 0x0  # -- Begin function SYM(ksvgLightingSpotDiffuseRowAvx2)
.LCPI0_0:
.long	0  # 0x0
.long	1  # 0x1
.long	2  # 0x2
.long	3  # 0x3
.long	4  # 0x4
.long	5  # 0x5
.long	6  # 0x6
.long	7  # 0x7
RODATA4
.p2align 2, 0x0
.LCPI0_1:
.long	0x80000000  # float -0
.LCPI0_2:
.long	0x3f800000  # float 1
.LCPI0_3:
.long	1258291200  # 0x4b000000
.LCPI0_4:
.long	1392508928  # 0x53000000
.LCPI0_5:
.long	0x53000080  # float 5.49764202E+11
.LCPI0_6:
.long	0x437f0000  # float 255
.LCPI0_7:
.long	8  # 0x8
.LCPI0_8:
.long	4278190080  # 0xff000000
RODATA16
.p2align 4, 0x0
.LCPI0_9:
.long	16  # 0x10
.long	8  # 0x8
.zero	4
.zero	4
.LCPI0_10:
.zero	16
RODATA8
.LCPI0_11:
.byte	0  # 0x0
.byte	1  # 0x1
.byte	2  # 0x2
.byte	3  # 0x3
.byte	4  # 0x4
.byte	5  # 0x5
.byte	6  # 0x6
.byte	7  # 0x7
.text
RODATA4
.p2align 2, 0x0  # -- Begin function ksvgLightingSpotDiffuseRowAvx2_clean
.LSPOTAVX2_C0:
.long	0x3f800000  # float 1
.LSPOTAVX2_C1:
.long	0x40a00000  # float 5
.LSPOTAVX2_C4:
.long	0x437f0000  # float 255
.LSPOTAVX2_HALF:
.long	0x3f000000  # float 0.5
RODATA16
.p2align 4, 0x0
.LSPOTAVX2_C2:
.long	0x40c00000  # float 6
.long	0x40e00000  # float 7
.zero	4
.zero	4
.LSPOTAVX2_C3:
.long	0x40800000  # float 4
.long	0x3f800000  # float 1
.long	0x40000000  # float 2
.long	0x40400000  # float 3
.LSPOTAVX2_C6:
.long	0x40c00000  # float 6
.long	0x40e00000  # float 7
.long	0x00000000  # float 0
.long	0x00000000  # float 0
RODATA8
.p2align 3, 0x0
.LSPOTAVX2_C5:
.quad	-72057589759737856  # 0xff000000ff000000
.text
.globl SYM(ksvgLightingSpotDiffuseRowAvx2)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingSpotDiffuseRowAvx2), @function)
SYM(ksvgLightingSpotDiffuseRowAvx2):  # @ksvgLightingSpotDiffuseRowAvx2
# %bb.0:
    testl        %r8d, %r8d
    jle          LSPOTAVX2_DONE
# %bb.1:
    // Broadcast surface scale + vector constants for the loop below.
    vbroadcastss 36(%r9), %ymm0
    movl         %r8d, %eax
    xorl         %r8d, %r8d
    vbroadcastss .LSPOTAVX2_C0(%rip), %ymm1  # ymm1 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vxorps       %xmm2, %xmm2, %xmm2
    vmovss       .LSPOTAVX2_C1(%rip), %xmm3  # xmm3 = [5.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vmovsd       .LSPOTAVX2_C6(%rip), %xmm4  # xmm4 = [6.0E+0,7.0E+0,0.0E+0,0.0E+0]
    vmovaps      .LSPOTAVX2_C3(%rip), %xmm5  # xmm5 = [4.0E+0,1.0E+0,2.0E+0,3.0E+0]
    vbroadcastss .LSPOTAVX2_C4(%rip), %ymm6  # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
    vpbroadcastq .LSPOTAVX2_C5(%rip), %ymm7  # ymm7 = [18374686483949813760,18374686483949813760,18374686483949813760,18374686483949813760]
.p2align 4, 0x90
LSPOTAVX2_LOOP:  # =>This Inner Loop Header: Depth=1
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
    vdivps       %ymm10, %ymm8, %ymm8  # nx = nx0 / nLen
    vdivps       %ymm10, %ymm9, %ymm9  # ny = ny0 / nLen
    vpsrld       $24, %ymm11, %ymm11
    vxorps       %xmm15, %xmm15, %xmm15
    vcvtsi2ss    %r8d, %xmm15, %xmm12
    vcvtdq2ps    %ymm11, %ymm11
    vmulps       %ymm0, %ymm11, %ymm11
    vaddss       %xmm3, %xmm12, %xmm13
    vbroadcastss %xmm12, %xmm12
    vaddps       %xmm5, %xmm12, %xmm14
    vpermpd      $196, %ymm14, %ymm15  # ymm15 = ymm14[0,1,0,3]
    vblendps     $1, %ymm12, %ymm15, %ymm15  # ymm15 = ymm12[0],ymm15[1,2,3,4,5,6,7]
    vaddps       %xmm4, %xmm12, %xmm12
    vbroadcastss %xmm13, %ymm13
    vblendps     $32, %ymm13, %ymm15, %ymm13  # ymm13 = ymm15[0,1,2,3,4],ymm13[5],ymm15[6,7]
    vinsertf128  $1, %xmm12, %ymm14, %ymm12
    vshufpd      $2, %ymm12, %ymm13, %ymm12  # ymm12 = ymm13[0],ymm12[1],ymm13[2],ymm12[2]
    vbroadcastss 40(%r9), %ymm13
    vbroadcastss 48(%r9), %ymm14
    vmulps       %ymm14, %ymm12, %ymm12
    vaddps       %ymm12, %ymm13, %ymm12
    vbroadcastss 12(%r9), %ymm13
    vsubps       %ymm12, %ymm13, %ymm12
    vmovss       16(%r9), %xmm13  # xmm13 = mem[0],zero,zero,zero
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
    vaddps       %ymm11, %ymm9, %ymm9  # round-half-up R
    vminps       %ymm6, %ymm9, %ymm9
    vcvttps2dq   %ymm9, %ymm9
    vaddps       %ymm11, %ymm10, %ymm10  # round-half-up G
    vminps       %ymm6, %ymm10, %ymm10
    vcvttps2dq   %ymm10, %ymm10
    // Pack R/G/B (round-half-up + truncate + int clamp) with full alpha.
    vpslld       $16, %ymm9, %ymm9
    vpslld       $8, %ymm10, %ymm10
    vpor         %ymm9, %ymm10, %ymm9
    vaddps       %ymm11, %ymm8, %ymm8  # round-half-up B
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
# -- End function
RODATA4
.p2align 2, 0x0  # -- Begin function SYM(ksvgLightingSpotDiffuseRowAvx2Linear)
.LCPI1_0:
.long	0x80000000  # float -0
.LCPI1_1:
.long	0x3f800000  # float 1
.LCPI1_2:
.long	0x437f0000  # float 255
.LCPI1_4:
.long	0x3f000000  # float 0.5
RODATA16
.p2align 4, 0x0
.LCPI1_3:
.zero	16
.text
.globl SYM(ksvgLightingSpotDiffuseRowAvx2Linear)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingSpotDiffuseRowAvx2Linear), @function)
SYM(ksvgLightingSpotDiffuseRowAvx2Linear):  # @SYM(ksvgLightingSpotDiffuseRowAvx2Linear)
# %bb.0:
    testl        %r8d, %r8d
    jle          .LBB1_4
# %bb.1:
    pushq        %rbp
    pushq        %r15
    pushq        %r13
    pushq        %r14
    pushq        %r12
    pushq        %rbx
    subq         $8, %rsp
    // Spill scalar params (surface scale, invD, light pos, spot dir, k,
    // colors) for the per-pixel loop below.
    vmovss       36(%r9), %xmm0  # xmm0 = mem[0],zero,zero,zero
    vmovss       (%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -20(%rsp)  # 4-byte Spill
    vmovss       4(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -24(%rsp)  # 4-byte Spill
    vmovss       40(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -28(%rsp)  # 4-byte Spill
    vmovss       48(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -32(%rsp)  # 4-byte Spill
    vmovss       16(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vsubss       44(%r9), %xmm1, %xmm1
    vmovss       12(%r9), %xmm2  # xmm2 = mem[0],zero,zero,zero
    vmovss       %xmm2, -36(%rsp)  # 4-byte Spill
    vmovss       20(%r9), %xmm2  # xmm2 = mem[0],zero,zero,zero
    vmovss       %xmm2, -40(%rsp)  # 4-byte Spill
    vmovaps      %xmm1, -16(%rsp)  # 16-byte Spill
    vmulss       %xmm1, %xmm1, %xmm1
    vmovss       %xmm1, -44(%rsp)  # 4-byte Spill
    vmovss       52(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -48(%rsp)  # 4-byte Spill
    vmovss       56(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -52(%rsp)  # 4-byte Spill
    vmovss       60(%r9), %xmm1  # xmm1 = mem[0],zero,zero,zero
    vmovss       %xmm1, -56(%rsp)  # 4-byte Spill
    vmovss       64(%r9), %xmm12  # xmm12 = mem[0],zero,zero,zero
    vmovss       8(%r9), %xmm13  # xmm13 = mem[0],zero,zero,zero
    vmovsd       24(%r9), %xmm14  # xmm14 = mem[0],zero
    vmovss       32(%r9), %xmm15  # xmm15 = mem[0],zero,zero,zero
    movq         %rsi, %r13
    movq         %rdx, %r14
    movq         %r14, -64(%rsp)
    movl         %r8d, %r8d
    xorl         %r9d, %r9d
    movl         $255, %r10d
    vbroadcastss .LCPI1_0(%rip), %xmm1  # xmm1 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
    vmovss       .LCPI1_1(%rip), %xmm2  # xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    vxorps       %xmm3, %xmm3, %xmm3
.p2align 4, 0x90
.LBB1_2:  # =>This Inner Loop Header: Depth=1
    // Per-pixel scalar loop: window heights, normalize, spot factor with
    // cutoff, intensity, L2S conversion, pack, store.
    movq         -64(%rsp), %r14
    movzbl       3(%rdi,%r9,4), %r11d
    vxorps       %xmm7, %xmm7, %xmm7
    vcvtsi2ss    %r11d, %xmm7, %xmm4
    vmulss       %xmm4, %xmm0, %xmm6
    movzbl       7(%rdi,%r9,4), %r11d
    vxorps       %xmm7, %xmm7, %xmm7
    vcvtsi2ss    %r11d, %xmm7, %xmm4
    vmulss       %xmm4, %xmm0, %xmm4
    movzbl       11(%rdi,%r9,4), %r11d
    vxorps       %xmm7, %xmm7, %xmm7
    vcvtsi2ss    %r11d, %xmm7, %xmm7
    movzbl       3(%r13,%r9,4), %r11d
    vxorps       %xmm8, %xmm8, %xmm8
    vcvtsi2ss    %r11d, %xmm8, %xmm8
    movzbl       11(%r13,%r9,4), %r11d
    vxorps       %xmm9, %xmm9, %xmm9
    vcvtsi2ss    %r11d, %xmm9, %xmm9
    vmulss       %xmm7, %xmm0, %xmm7
    vmulss       %xmm0, %xmm8, %xmm8
    vmulss       %xmm0, %xmm9, %xmm9
    movzbl       3(%r14,%r9,4), %r11d
    vxorps       %xmm11, %xmm11, %xmm11
    vcvtsi2ss    %r11d, %xmm11, %xmm10
    vmulss       %xmm0, %xmm10, %xmm10
    movzbl       7(%r14,%r9,4), %r11d
    vxorps       %xmm11, %xmm11, %xmm11
    vcvtsi2ss    %r11d, %xmm11, %xmm5
    movzbl       11(%r14,%r9,4), %r11d
    vxorps       %xmm11, %xmm11, %xmm11
    vcvtsi2ss    %r11d, %xmm11, %xmm11
    vmulss       %xmm5, %xmm0, %xmm5
    vmulss       %xmm0, %xmm11, %xmm11
    vaddss       %xmm9, %xmm9, %xmm9
    vaddss       %xmm7, %xmm9, %xmm9
    vaddss       %xmm11, %xmm9, %xmm9
    vaddss       %xmm8, %xmm8, %xmm8
    vaddss       %xmm6, %xmm8, %xmm8
    vaddss       %xmm10, %xmm8, %xmm8
    vsubss       %xmm8, %xmm9, %xmm8
    vaddss       %xmm5, %xmm5, %xmm5
    vaddss       %xmm5, %xmm10, %xmm5
    vaddss       %xmm5, %xmm11, %xmm5
    vaddss       %xmm4, %xmm4, %xmm9
    vaddss       %xmm6, %xmm9, %xmm6
    vaddss       %xmm7, %xmm6, %xmm6
    vsubss       %xmm6, %xmm5, %xmm5
    vxorps       %xmm1, %xmm8, %xmm6
    vdivss       -20(%rsp), %xmm6, %xmm6  # 4-byte Folded Reload
    vxorps       %xmm1, %xmm5, %xmm5
    vdivss       -24(%rsp), %xmm5, %xmm5  # 4-byte Folded Reload
    vmulss       %xmm5, %xmm5, %xmm7
    vmulss       %xmm6, %xmm6, %xmm8
    vaddss       %xmm7, %xmm8, %xmm7
    vaddss       %xmm2, %xmm7, %xmm7
    vcvtsi2ss    %r9d, %xmm0, %xmm8
    vmulss       -32(%rsp), %xmm8, %xmm8  # 4-byte Folded Reload
    vaddss       -28(%rsp), %xmm8, %xmm8  # 4-byte Folded Reload
    vmovss       -36(%rsp), %xmm9  # 4-byte Reload
# xmm9 = mem[0],zero,zero,zero
    vsubss       %xmm8, %xmm9, %xmm8
    movzbl       7(%r13,%r9,4), %r11d  # center height (current pixel alpha)
    vcvtsi2ss    %r11d, %xmm12, %xmm10
    vmulss       %xmm0, %xmm10, %xmm10  # center * ss
    vmovss       -40(%rsp), %xmm9  # 4-byte Reload
# xmm9 = mem[0],zero,zero,zero
    vsubss       %xmm10, %xmm9, %xmm4  # vz = lightZ - center*ss
    vmulss       %xmm8, %xmm8, %xmm9
    vaddss       -44(%rsp), %xmm9, %xmm9  # 4-byte Folded Reload
    vmulss       %xmm4, %xmm4, %xmm10
    vaddss       %xmm9, %xmm10, %xmm9
    vinsertps    $16, %xmm9, %xmm7, %xmm7  # xmm7 = xmm7[0],xmm9[0],xmm7[2,3]
    vsqrtps      %xmm7, %xmm7
    vbroadcastss .LCPI1_1(%rip), %xmm9  # xmm9 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    vdivps       %xmm7, %xmm9, %xmm7
    vmovshdup    %xmm7, %xmm9  # xmm9 = xmm7[1,1,3,3]
    vmulss       %xmm9, %xmm8, %xmm8
    vinsertps    $16, -16(%rsp), %xmm5, %xmm5  # 16-byte Folded Reload
# xmm5 = xmm5[0],mem[0],xmm5[2,3]
    vmulps       %xmm7, %xmm5, %xmm5
    vmulss       %xmm4, %xmm9, %xmm4
    vmovshdup    %xmm5, %xmm9  # xmm9 = xmm5[1,1,3,3]
    vmulss       -52(%rsp), %xmm9, %xmm10  # 4-byte Folded Reload
    vmulss       -48(%rsp), %xmm8, %xmm11  # 4-byte Folded Reload
    vaddss       %xmm10, %xmm11, %xmm10
    vmulss       -56(%rsp), %xmm4, %xmm11  # 4-byte Folded Reload
    vaddss       %xmm10, %xmm11, %xmm10
    vxorps       %xmm1, %xmm10, %xmm11
    vcmpltss     %xmm10, %xmm11, %xmm10
    vandnps      %xmm11, %xmm10, %xmm10
    vcmpltss     %xmm12, %xmm10, %xmm11
    vandnps      %xmm10, %xmm11, %xmm10
    vmulss       %xmm5, %xmm9, %xmm5
    vmulss       %xmm7, %xmm6, %xmm6  # nx = ngx * (1/|n|)
    vmulss       %xmm6, %xmm8, %xmm6
    vaddss       %xmm5, %xmm6, %xmm5
    vmulss       %xmm4, %xmm7, %xmm4  # nz*lz
    vaddss       %xmm5, %xmm4, %xmm4
    vmaxss       %xmm4, %xmm3, %xmm4
    vmulss       %xmm4, %xmm13, %xmm4
    vmulss       %xmm4, %xmm10, %xmm4
    vminss       %xmm4, %xmm2, %xmm5
    vcmpltss     %xmm3, %xmm4, %xmm4
    vandnps      %xmm5, %xmm4, %xmm4
    vbroadcastss %xmm4, %xmm5
    vmulps       %xmm5, %xmm14, %xmm5
    vxorps       %xmm6, %xmm6, %xmm6
    vmaxps       %xmm5, %xmm6, %xmm5
    vbroadcastss .LCPI1_4(%rip), %xmm6  # 0.5
    vaddps       %xmm6, %xmm5, %xmm5  # round-half-up R/G
    vmovshdup    %xmm5, %xmm6  # xmm6 = xmm5[1,1,3,3]
    vcvttss2si   %xmm6, %r11d
    vcvttss2si   %xmm5, %ebx
    vbroadcastss .LCPI1_2(%rip), %xmm6  # xmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
    vcmpltps     %xmm5, %xmm6, %xmm5
    vshufps      $80, %xmm5, %xmm5, %xmm5  # xmm5 = xmm5[0,0,1,1]
    vmovmskpd    %xmm5, %ebp
    vmulss       %xmm4, %xmm15, %xmm4
    vmaxss       %xmm4, %xmm3, %xmm4
    vmovss       .LCPI1_2(%rip), %xmm5  # xmm5 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
    vminss       %xmm4, %xmm5, %xmm4
    vaddss       .LCPI1_4(%rip), %xmm4, %xmm4  # round-half-up B
    vcvttss2si   %xmm4, %r14d
    movl         %ebx, %eax
    movl         %r11d, %esi
    movl         %r14d, %edx
    leaq         .Lspot_l2s_data(%rip), %r15
    L2S_SPOT     %eax
    L2S_SPOT     %esi
    L2S_SPOT     %edx
    shll         $16, %eax
    shll         $8, %esi
    orl          %eax, %esi
    orl          %edx, %esi
    movl         %esi, %ebx
    orl          $-16777216, %ebx
    movl         %ebx, (%rcx,%r9,4)
    leaq         1(%r9), %r11
    movq         %r11, %r9
    cmpq         %r11, %r8
    jne          .LBB1_2
# %bb.3:
    addq         $8, %rsp
    popq         %rbx
    popq         %r12
    popq         %r14
    popq         %r13
    popq         %r15
    popq         %rbp
.LBB1_4:
    retq
.Lfunc_end1:
SIZE(SYM(ksvgLightingSpotDiffuseRowAvx2Linear))
# -- End function
