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
RODATA16
.p2align 4, 0x0
.LCPI0_0:
.long	0  // 0x0
.long	1  // 0x1
.long	2  // 0x2
.long	3  // 0x3
.LCPI0_1:
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.LCPI0_2:
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.LCPI0_3:
.long	65535  // 0xffff
.long	65535  // 0xffff
.long	65535  // 0xffff
.long	65535  // 0xffff
.LCPI0_4:
.long	1258291200  // 0x4b000000
.long	1258291200  // 0x4b000000
.long	1258291200  // 0x4b000000
.long	1258291200  // 0x4b000000
.LCPI0_5:
.long	1392508928  // 0x53000000
.long	1392508928  // 0x53000000
.long	1392508928  // 0x53000000
.long	1392508928  // 0x53000000
.LCPI0_6:
.long	0x53000080  // float 5.49764202E+11
.long	0x53000080  // float 5.49764202E+11
.long	0x53000080  // float 5.49764202E+11
.long	0x53000080  // float 5.49764202E+11
.LCPI0_7:
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.LCPI0_8:
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.LCPI0_9:
.long	4  // 0x4
.long	4  // 0x4
.long	4  // 0x4
.long	4  // 0x4
.LCPI0_11:
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.zero	4
.zero	4
.LCPI0_12:
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.zero	4
.zero	4
.LCPI0_14:
.zero	16
.LSPOTSSSE3_HALF:
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
RODATA4
.p2align 2, 0x0
.LCPI0_10:
.long	0x3f800000  // float 1
.LCPI0_13:
.long	0x437f0000  // float 255
.LCPI0_15:
.long	0x00000000  // float 0
.text
RODATA16
.p2align 4, 0x0
.LSPOTSSSE3_C0:
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.LSPOTSSSE3_C2:
.long	0x40000000  // float 2
.long	0x40400000  // float 3
.zero	4
.zero	4
.LSPOTSSSE3_C3:
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.LSPOTSSSE3_C4:
.quad	-72057589759737856  // 0xff000000ff000000
.quad	-72057589759737856  // 0xff000000ff000000
.LSPOTSSSE3_C5:
.long	0x40000000  // float 2
.long	0x40400000  // float 3
.long	0x00000000  // float 0
.long	0x00000000  // float 0
RODATA4
.p2align 2, 0x0
.LSPOTSSSE3_C1:
.long	0x3f800000  // float 1
.text
.globl SYM(ksvgLightingSpotDiffuseRowSsse3)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingSpotDiffuseRowSsse3), @function)
SYM(ksvgLightingSpotDiffuseRowSsse3):
    // Caller contract: count is a multiple of 4 (C++ passes (ixHi-x)&~3);
    // there is no 1-3px tail here, scalar C++ covers row edges/tails.
    testl          %r8d, %r8d
    jle            LSPOTSSSE3_DONE
    // Broadcast surface scale + vector constants for the loop below.
    movss          36(%r9), %xmm0  // xmm0 = mem[0],zero,zero,zero
    shufps         $0, %xmm0, %xmm0  // xmm0 = xmm0[0,0,0,0]
    movl           %r8d, %eax
    xorl           %r8d, %r8d
    xorps          %xmm1, %xmm1
    movaps         .LSPOTSSSE3_C0(%rip), %xmm2  // xmm2 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    movss          .LSPOTSSSE3_C1(%rip), %xmm3  // xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    movsd          .LSPOTSSSE3_C5(%rip), %xmm4  // xmm4 = [2.0E+0,3.0E+0,0.0E+0,0.0E+0]
    movaps         .LSPOTSSSE3_C3(%rip), %xmm5  // xmm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
    movdqa         .LSPOTSSSE3_C4(%rip), %xmm6  // xmm6 = [18374686483949813760,18374686483949813760]
.p2align 4, 0x90
LSPOTSSSE3_LOOP:
    // Main loop, 4 pixels per iteration: Sobel window, normalize, spot-cone
    // factor with cutoff, intensity, pack, store.
    movdqu         (%rdi,%r8,4), %xmm7
    movdqu         4(%rdi,%r8,4), %xmm8
    movdqu         8(%rdi,%r8,4), %xmm9
    ALPHA_FSCALE   %xmm7, %xmm0
    ALPHA_FSCALE_X %xmm8, %xmm10, %xmm0
    ALPHA_FSCALE_X %xmm9, %xmm8, %xmm0
    addps          %xmm10, %xmm10
    addps          %xmm7, %xmm10
    addps          %xmm8, %xmm10
    movaps         %xmm8, %xmm11
    subps          %xmm7, %xmm11
    xorps          %xmm8, %xmm8
    subps          %xmm10, %xmm8
    movdqu         (%rsi,%r8,4), %xmm7
    movdqu         4(%rsi,%r8,4), %xmm9
    movdqu         8(%rsi,%r8,4), %xmm10
    ALPHA_FSCALE_X %xmm7, %xmm12, %xmm0
    ALPHA_FSCALE_X %xmm9, %xmm7, %xmm0
    ALPHA_FSCALE_X %xmm10, %xmm9, %xmm0
    addps          %xmm9, %xmm9
    addps          %xmm12, %xmm12
    subps          %xmm12, %xmm9
    addps          %xmm11, %xmm9
    movdqu         (%rdx,%r8,4), %xmm10
    movdqu         4(%rdx,%r8,4), %xmm11
    movdqu         8(%rdx,%r8,4), %xmm13
    ALPHA_FSCALE   %xmm10, %xmm0
    ALPHA_FSCALE_X %xmm11, %xmm12, %xmm0
    ALPHA_FSCALE_X %xmm13, %xmm11, %xmm0
    addps          %xmm12, %xmm12
    addps          %xmm10, %xmm12
    addps          %xmm11, %xmm12
    movaps         %xmm11, %xmm13
    subps          %xmm10, %xmm13
    addps          %xmm9, %xmm13
    addps          %xmm8, %xmm12
    movss          (%r9), %xmm8  // xmm8 = mem[0],zero,zero,zero
    movss          4(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    movss          12(%r9), %xmm9  // xmm9 = mem[0],zero,zero,zero
    shufps         $0, %xmm8, %xmm8  // xmm8 = xmm8[0,0,0,0]
    divps          %xmm8, %xmm13
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    divps          %xmm10, %xmm12
    xorps          %xmm11, %xmm11
    subps          %xmm13, %xmm11
    xorps          %xmm10, %xmm10
    subps          %xmm12, %xmm10
    movaps         %xmm11, %xmm8
    mulps          %xmm11, %xmm8
    movaps         %xmm10, %xmm12
    mulps          %xmm10, %xmm12
    addps          %xmm8, %xmm12
    addps          %xmm2, %xmm12
    sqrtps         %xmm12, %xmm12
    divps          %xmm12, %xmm11  // nx = nx0 / nLen
    divps          %xmm12, %xmm10  // ny = ny0 / nLen
    xorps          %xmm13, %xmm13
    cvtsi2ss       %r8d, %xmm13
    movaps         %xmm2, %xmm8
    divps          %xmm12, %xmm8
    movaps         %xmm13, %xmm12
    addss          %xmm3, %xmm12
    movsldup       %xmm13, %xmm14  // xmm14 = xmm13[0,0,2,2]
    addps          %xmm4, %xmm14
    unpcklps       %xmm12, %xmm13  // xmm13 = xmm13[0],xmm12[0],xmm13[1],xmm12[1]
    movlhps        %xmm14, %xmm13  // xmm13 = xmm13[0],xmm14[0]
    movss          40(%r9), %xmm12  // xmm12 = mem[0],zero,zero,zero
    shufps         $0, %xmm12, %xmm12  // xmm12 = xmm12[0,0,0,0]
    movss          48(%r9), %xmm14  // xmm14 = mem[0],zero,zero,zero
    shufps         $0, %xmm14, %xmm14  // xmm14 = xmm14[0,0,0,0]
    mulps          %xmm13, %xmm14
    addps          %xmm12, %xmm14
    shufps         $0, %xmm9, %xmm9  // xmm9 = xmm9[0,0,0,0]
    subps          %xmm14, %xmm9
    movss          16(%r9), %xmm13  // xmm13 = mem[0],zero,zero,zero
    subss          44(%r9), %xmm13
    movaps         %xmm13, %xmm12
    movss          20(%r9), %xmm14  // xmm14 = mem[0],zero,zero,zero
    shufps         $0, %xmm14, %xmm14  // xmm14 = xmm14[0,0,0,0]
    subps          %xmm7, %xmm14
    movaps         %xmm9, %xmm7
    mulps          %xmm9, %xmm7
    mulss          %xmm13, %xmm13
    shufps         $0, %xmm13, %xmm13  // xmm13 = xmm13[0,0,0,0]
    addps          %xmm7, %xmm13
    movaps         %xmm14, %xmm15
    mulps          %xmm14, %xmm15
    addps          %xmm13, %xmm15
    sqrtps         %xmm15, %xmm13
    movaps         %xmm2, %xmm7
    divps          %xmm13, %xmm7
    cmpneqps       %xmm1, %xmm15
    andps          %xmm15, %xmm7
    shufps         $0, %xmm12, %xmm12  // xmm12 = xmm12[0,0,0,0]
    mulps          %xmm7, %xmm9
    mulps          %xmm7, %xmm12
    mulps          %xmm14, %xmm7
    mulps          %xmm9, %xmm11
    mulps          %xmm12, %xmm10
    addps          %xmm11, %xmm10
    mulps          %xmm7, %xmm8
    addps          %xmm10, %xmm8
    movss          52(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    mulps          %xmm9, %xmm10
    movss          56(%r9), %xmm9  // xmm9 = mem[0],zero,zero,zero
    shufps         $0, %xmm9, %xmm9  // xmm9 = xmm9[0,0,0,0]
    mulps          %xmm12, %xmm9
    addps          %xmm10, %xmm9
    movss          60(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    mulps          %xmm7, %xmm10
    movss          8(%r9), %xmm7  // xmm7 = mem[0],zero,zero,zero
    maxps          %xmm1, %xmm8
    addps          %xmm9, %xmm10
    xorps          %xmm9, %xmm9
    subps          %xmm10, %xmm9
    maxps          %xmm1, %xmm9
    movss          64(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    cmpleps        %xmm9, %xmm10
    andps          %xmm9, %xmm10
    shufps         $0, %xmm7, %xmm7  // xmm7 = xmm7[0,0,0,0]
    mulps          %xmm8, %xmm7
    mulps          %xmm10, %xmm7
    minps          %xmm2, %xmm7
    movss          24(%r9), %xmm8  // xmm8 = mem[0],zero,zero,zero
    shufps         $0, %xmm8, %xmm8  // xmm8 = xmm8[0,0,0,0]
    mulps          %xmm7, %xmm8
    movss          28(%r9), %xmm9  // xmm9 = mem[0],zero,zero,zero
    shufps         $0, %xmm9, %xmm9  // xmm9 = xmm9[0,0,0,0]
    mulps          %xmm7, %xmm9
    movss          32(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    mulps          %xmm7, %xmm10
    addps          .LSPOTSSSE3_HALF(%rip), %xmm8  // round-half-up R
    minps          %xmm5, %xmm8
    cvttps2dq      %xmm8, %xmm7
    addps          .LSPOTSSSE3_HALF(%rip), %xmm9  // round-half-up G
    minps          %xmm5, %xmm9
    cvttps2dq      %xmm9, %xmm8
    // Pack R/G/B (round-half-up + truncate + int clamp) with full alpha.
    pslld          $16, %xmm7
    pslld          $8, %xmm8
    por            %xmm7, %xmm8
    addps          .LSPOTSSSE3_HALF(%rip), %xmm10  // round-half-up B
    minps          %xmm5, %xmm10
    cvttps2dq      %xmm10, %xmm7
    por            %xmm7, %xmm8
    por            %xmm6, %xmm8
    movdqu         %xmm8, (%rcx,%r8,4)
    addq           $4, %r8
    cmpq           %rax, %r8
    jb             LSPOTSSSE3_LOOP
LSPOTSSSE3_DONE:
    retq
.Lfunc_end0:
SIZE(SYM(ksvgLightingSpotDiffuseRowSsse3))
RODATA16
.p2align 4, 0x0
.LCPI1_0:
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.LCPI1_2:
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.zero	4
.zero	4
.LCPI1_3:
.long	0x437f0000  // float 255
.long	0x437f0000  // float 255
.zero	4
.zero	4
.LCPI1_6:
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.zero	4
.zero	4
RODATA4
.p2align 2, 0x0
.LCPI1_1:
.long	0x3f800000  // float 1
.LCPI1_4:
.long	0x437f0000  // float 255
.LCPI1_5:
.long	0x00000000  // float 0
.LCPI1_7:
.long	0x3f000000  // float 0.5
.text
.globl SYM(ksvgLightingSpotDiffuseRowSsse3Linear)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingSpotDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingSpotDiffuseRowSsse3Linear):
    // Caller contract: count is a multiple of 4 (C++ passes (ixHi-x)&~3);
    // there is no 1-3px tail here, scalar C++ covers row edges/tails.
    // 4px/iter vector loop: the proven sRGB front half through the R/G int
    // converts, then exact L2S bytes via the scalar LUT (GPR lookups).
    testl          %r8d, %r8d
    jle            .LSPOT_LINEAR4_DONE
    pushq          %r15                  // LUT base; keeps rsp 16B-aligned
    leaq           .Lspot_l2s_data(%rip), %r15
    movss          36(%r9), %xmm0  // xmm0 = mem[0],zero,zero,zero
    shufps         $0, %xmm0, %xmm0  // xmm0 = xmm0[0,0,0,0]
    movl           %r8d, %eax
    xorl           %r8d, %r8d
    xorps          %xmm1, %xmm1
    movaps         .LSPOTSSSE3_C0(%rip), %xmm2  // xmm2 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    movss          .LSPOTSSSE3_C1(%rip), %xmm3  // xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
    movsd          .LSPOTSSSE3_C5(%rip), %xmm4  // xmm4 = [2.0E+0,3.0E+0,0.0E+0,0.0E+0]
    movaps         .LSPOTSSSE3_C3(%rip), %xmm5  // xmm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
    movdqa         .LSPOTSSSE3_C4(%rip), %xmm6  // xmm6 = [18374686483949813760,18374686483949813760]
.p2align 4, 0x90
.LSPOT_LINEAR4_LOOP:
    // Main loop, 4 pixels per iteration: Sobel window, normalize, spot-cone
    // factor with cutoff, intensity, pack, store.
    movdqu         (%rdi,%r8,4), %xmm7
    movdqu         4(%rdi,%r8,4), %xmm8
    movdqu         8(%rdi,%r8,4), %xmm9
    ALPHA_FSCALE   %xmm7, %xmm0
    ALPHA_FSCALE_X %xmm8, %xmm10, %xmm0
    ALPHA_FSCALE_X %xmm9, %xmm8, %xmm0
    addps          %xmm10, %xmm10
    addps          %xmm7, %xmm10
    addps          %xmm8, %xmm10
    movaps         %xmm8, %xmm11
    subps          %xmm7, %xmm11
    xorps          %xmm8, %xmm8
    subps          %xmm10, %xmm8
    movdqu         (%rsi,%r8,4), %xmm7
    movdqu         4(%rsi,%r8,4), %xmm9
    movdqu         8(%rsi,%r8,4), %xmm10
    ALPHA_FSCALE_X %xmm7, %xmm12, %xmm0
    ALPHA_FSCALE_X %xmm9, %xmm7, %xmm0
    ALPHA_FSCALE_X %xmm10, %xmm9, %xmm0
    addps          %xmm9, %xmm9
    addps          %xmm12, %xmm12
    subps          %xmm12, %xmm9
    addps          %xmm11, %xmm9
    movdqu         (%rdx,%r8,4), %xmm10
    movdqu         4(%rdx,%r8,4), %xmm11
    movdqu         8(%rdx,%r8,4), %xmm13
    ALPHA_FSCALE   %xmm10, %xmm0
    ALPHA_FSCALE_X %xmm11, %xmm12, %xmm0
    ALPHA_FSCALE_X %xmm13, %xmm11, %xmm0
    addps          %xmm12, %xmm12
    addps          %xmm10, %xmm12
    addps          %xmm11, %xmm12
    movaps         %xmm11, %xmm13
    subps          %xmm10, %xmm13
    addps          %xmm9, %xmm13
    addps          %xmm8, %xmm12
    movss          (%r9), %xmm8  // xmm8 = mem[0],zero,zero,zero
    movss          4(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    movss          12(%r9), %xmm9  // xmm9 = mem[0],zero,zero,zero
    shufps         $0, %xmm8, %xmm8  // xmm8 = xmm8[0,0,0,0]
    divps          %xmm8, %xmm13
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    divps          %xmm10, %xmm12
    xorps          %xmm11, %xmm11
    subps          %xmm13, %xmm11
    xorps          %xmm10, %xmm10
    subps          %xmm12, %xmm10
    movaps         %xmm11, %xmm8
    mulps          %xmm11, %xmm8
    movaps         %xmm10, %xmm12
    mulps          %xmm10, %xmm12
    addps          %xmm8, %xmm12
    addps          %xmm2, %xmm12
    sqrtps         %xmm12, %xmm12
    divps          %xmm12, %xmm11  // nx = nx0 / nLen
    divps          %xmm12, %xmm10  // ny = ny0 / nLen
    xorps          %xmm13, %xmm13
    cvtsi2ss       %r8d, %xmm13
    movaps         %xmm2, %xmm8
    divps          %xmm12, %xmm8
    movaps         %xmm13, %xmm12
    addss          %xmm3, %xmm12
    movsldup       %xmm13, %xmm14  // xmm14 = xmm13[0,0,2,2]
    addps          %xmm4, %xmm14
    unpcklps       %xmm12, %xmm13  // xmm13 = xmm13[0],xmm12[0],xmm13[1],xmm12[1]
    movlhps        %xmm14, %xmm13  // xmm13 = xmm13[0],xmm14[0]
    movss          40(%r9), %xmm12  // xmm12 = mem[0],zero,zero,zero
    shufps         $0, %xmm12, %xmm12  // xmm12 = xmm12[0,0,0,0]
    movss          48(%r9), %xmm14  // xmm14 = mem[0],zero,zero,zero
    shufps         $0, %xmm14, %xmm14  // xmm14 = xmm14[0,0,0,0]
    mulps          %xmm13, %xmm14
    addps          %xmm12, %xmm14
    shufps         $0, %xmm9, %xmm9  // xmm9 = xmm9[0,0,0,0]
    subps          %xmm14, %xmm9
    movss          16(%r9), %xmm13  // xmm13 = mem[0],zero,zero,zero
    subss          44(%r9), %xmm13
    movaps         %xmm13, %xmm12
    movss          20(%r9), %xmm14  // xmm14 = mem[0],zero,zero,zero
    shufps         $0, %xmm14, %xmm14  // xmm14 = xmm14[0,0,0,0]
    subps          %xmm7, %xmm14
    movaps         %xmm9, %xmm7
    mulps          %xmm9, %xmm7
    mulss          %xmm13, %xmm13
    shufps         $0, %xmm13, %xmm13  // xmm13 = xmm13[0,0,0,0]
    addps          %xmm7, %xmm13
    movaps         %xmm14, %xmm15
    mulps          %xmm14, %xmm15
    addps          %xmm13, %xmm15
    sqrtps         %xmm15, %xmm13
    movaps         %xmm2, %xmm7
    divps          %xmm13, %xmm7
    cmpneqps       %xmm1, %xmm15
    andps          %xmm15, %xmm7
    shufps         $0, %xmm12, %xmm12  // xmm12 = xmm12[0,0,0,0]
    mulps          %xmm7, %xmm9
    mulps          %xmm7, %xmm12
    mulps          %xmm14, %xmm7
    mulps          %xmm9, %xmm11
    mulps          %xmm12, %xmm10
    addps          %xmm11, %xmm10
    mulps          %xmm7, %xmm8
    addps          %xmm10, %xmm8
    movss          52(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    mulps          %xmm9, %xmm10
    movss          56(%r9), %xmm9  // xmm9 = mem[0],zero,zero,zero
    shufps         $0, %xmm9, %xmm9  // xmm9 = xmm9[0,0,0,0]
    mulps          %xmm12, %xmm9
    addps          %xmm10, %xmm9
    movss          60(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    mulps          %xmm7, %xmm10
    movss          8(%r9), %xmm7  // xmm7 = mem[0],zero,zero,zero
    maxps          %xmm1, %xmm8
    addps          %xmm9, %xmm10
    xorps          %xmm9, %xmm9
    subps          %xmm10, %xmm9
    maxps          %xmm1, %xmm9
    movss          64(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    cmpleps        %xmm9, %xmm10
    andps          %xmm9, %xmm10
    shufps         $0, %xmm7, %xmm7  // xmm7 = xmm7[0,0,0,0]
    mulps          %xmm8, %xmm7
    mulps          %xmm10, %xmm7
    minps          %xmm2, %xmm7
    // Full clamp01 like the scalar tail (its cmpltss/andnps pair is dead).
    // Guards k<0 intensity (fuzzer SIGSEGV without it). xmm3 holds a
    // prologue const reused every iteration, xmm1 the zero vector: both
    // parked and restored for the next iteration.
    movaps         %xmm3, %xmm1
    xorps          %xmm3, %xmm3
    maxps          %xmm7, %xmm3
    movaps         %xmm3, %xmm7
    movaps         %xmm1, %xmm3
    xorps          %xmm1, %xmm1
    movss          24(%r9), %xmm8  // xmm8 = mem[0],zero,zero,zero
    shufps         $0, %xmm8, %xmm8  // xmm8 = xmm8[0,0,0,0]
    mulps          %xmm7, %xmm8
    movss          28(%r9), %xmm9  // xmm9 = mem[0],zero,zero,zero
    shufps         $0, %xmm9, %xmm9  // xmm9 = xmm9[0,0,0,0]
    mulps          %xmm7, %xmm9
    movss          32(%r9), %xmm10  // xmm10 = mem[0],zero,zero,zero
    shufps         $0, %xmm10, %xmm10  // xmm10 = xmm10[0,0,0,0]
    mulps          %xmm7, %xmm10
    addps          .LSPOTSSSE3_HALF(%rip), %xmm8  // round-half-up R
    minps          %xmm5, %xmm8
    cvttps2dq      %xmm8, %xmm7
    addps          .LSPOTSSSE3_HALF(%rip), %xmm9  // round-half-up G
    minps          %xmm5, %xmm9
    cvttps2dq      %xmm9, %xmm8
    // R/G/B intensity ints are ready in xmm7/xmm8 (+ B float in xmm10):
    // int-convert B, then exact sRGB bytes via the scalar LUT (same table,
    // same indices the 1px loop feeds L2S_SPOT — GPR lookups, no cascade).
    addps          .LSPOTSSSE3_HALF(%rip), %xmm10
    minps          %xmm5, %xmm10
    cvttps2dq      %xmm10, %xmm10      // B ints
    // Pixel 0.
    movd           %xmm7, %r11d
    L2S_SPOT       %r11d               // sRGB(R0)
    shll           $16, %r11d
    movd           %xmm8, %r10d
    L2S_SPOT       %r10d               // sRGB(G0)
    shll           $8, %r10d
    orl            %r10d, %r11d
    movd           %xmm10, %r10d
    L2S_SPOT       %r10d               // sRGB(B0)
    orl            %r10d, %r11d
    orl            $-16777216, %r11d   // force alpha
    movl           %r11d, (%rcx,%r8,4)
    psrldq         $4, %xmm7
    psrldq         $4, %xmm8
    psrldq         $4, %xmm10
    // Pixel 1.
    movd           %xmm7, %r11d
    L2S_SPOT       %r11d
    shll           $16, %r11d
    movd           %xmm8, %r10d
    L2S_SPOT       %r10d
    shll           $8, %r10d
    orl            %r10d, %r11d
    movd           %xmm10, %r10d
    L2S_SPOT       %r10d
    orl            %r10d, %r11d
    orl            $-16777216, %r11d
    movl           %r11d, 4(%rcx,%r8,4)
    psrldq         $4, %xmm7
    psrldq         $4, %xmm8
    psrldq         $4, %xmm10
    // Pixel 2.
    movd           %xmm7, %r11d
    L2S_SPOT       %r11d
    shll           $16, %r11d
    movd           %xmm8, %r10d
    L2S_SPOT       %r10d
    shll           $8, %r10d
    orl            %r10d, %r11d
    movd           %xmm10, %r10d
    L2S_SPOT       %r10d
    orl            %r10d, %r11d
    orl            $-16777216, %r11d
    movl           %r11d, 8(%rcx,%r8,4)
    psrldq         $4, %xmm7
    psrldq         $4, %xmm8
    psrldq         $4, %xmm10
    // Pixel 3.
    movd           %xmm7, %r11d
    L2S_SPOT       %r11d
    shll           $16, %r11d
    movd           %xmm8, %r10d
    L2S_SPOT       %r10d
    shll           $8, %r10d
    orl            %r10d, %r11d
    movd           %xmm10, %r10d
    L2S_SPOT       %r10d
    orl            %r10d, %r11d
    orl            $-16777216, %r11d
    movl           %r11d, 12(%rcx,%r8,4)
    addq           $4, %r8
    cmpq           %rax, %r8
    jb             .LSPOT_LINEAR4_LOOP
.LSPOT_LINEAR4_DONE:
    popq           %r15
    retq
.Lfunc_end1:
SIZE(SYM(ksvgLightingSpotDiffuseRowSsse3Linear))
