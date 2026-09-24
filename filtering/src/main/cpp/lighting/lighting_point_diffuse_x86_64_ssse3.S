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
 *   Scalar L2S gather + force-alpha byte pack, matching the point-diffuse
 *   linear path. Gathers three bytes from \lut (one per channel) and packs
 *   (R << 16) | (G << 8) | B | 0xFF000000 (full alpha). Legacy SSE
 *   mnemonics.
 *
 * Inputs:
 *   \lut        = base of the L2S table (e.g. %rax)
 *   \ri, \gi, \bi = 64-bit index registers holding the byte indices
 *   \ro, \go, \bo = 32-bit registers receiving the gathered bytes
 *                   (may differ from the index regs)
 *
 * Output:
 *   \go         = packed 0xAARRGGBB pixel
 *
 * Clobbers:
 *   \ro, \go, \bo
 *   Upper 32 bits of the 32-bit dests are zero-extended by movzbl.
 */
.macro L2S_GATHER_PACK lut, ri, ro, gi, go, bi, bo
    movzbl         (\lut,\ri), \ro
    movzbl         (\lut,\gi), \go
    movzbl         (\lut,\bi), \bo
    shll           $16, \ro
    shll           $8, \go
    orl            \ro, \go
    orl            \bo, \go
    orl            $-16777216, \go
.endm

.text
LIT16
.p2align 4, 0x0
.LCPI0_0:
.long	0x40000000  // float 2
.long	0x40400000  // float 3
.zero	4
.zero	4
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
.long	255  // 0xff
.long	255  // 0xff
.long	255  // 0xff
.long	255  // 0xff
.LCPI0_4:
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.LCPI0_5:
.zero	16,255
.Lpoint_half:
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.long	0x3f000000  // float 0.5
.text
.globl SYM(ksvgLightingPointDiffuseRowSsse3)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingPointDiffuseRowSsse3), @function)
SYM(ksvgLightingPointDiffuseRowSsse3):
CFI_START
    testl          %r8d, %r8d
    jle            .LBB0_4
    subq           $40, %rsp
    CFI_DEF_CFA_OFFSET(48)
    movss          16(%r9), %xmm0  // xmm0 = mem[0],zero,zero,zero
    movss          40(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movss          %xmm1, -116(%rsp)
    movd           48(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movss          36(%r9), %xmm3  // xmm3 = mem[0],zero,zero,zero
    shufps         $0, %xmm3, %xmm3  // xmm3 = xmm3[0,0,0,0]
    movss          (%r9), %xmm2  // xmm2 = mem[0],zero,zero,zero
    movss          4(%r9), %xmm4  // xmm4 = mem[0],zero,zero,zero
    movss          8(%r9), %xmm5  // xmm5 = mem[0],zero,zero,zero
    movss          12(%r9), %xmm6  // xmm6 = mem[0],zero,zero,zero
    shufps         $0, %xmm2, %xmm2  // xmm2 = xmm2[0,0,0,0]
    movaps         %xmm2, (%rsp)
    shufps         $0, %xmm4, %xmm4  // xmm4 = xmm4[0,0,0,0]
    movaps         %xmm4, -16(%rsp)
    movq           %xmm1, %xmm2  // xmm2 = xmm1[0],zero
    movdqa         %xmm1, 16(%rsp)
    movsldup       %xmm1, %xmm1  // xmm1 = xmm1[0,0,2,2]
    mulps          .LCPI0_0(%rip), %xmm1
    shufps         $66, %xmm1, %xmm2  // xmm2 = xmm2[2,0],xmm1[0,1]
    movaps         %xmm2, -64(%rsp)
    shufps         $0, %xmm6, %xmm6  // xmm6 = xmm6[0,0,0,0]
    movaps         %xmm6, -48(%rsp)
    subss          44(%r9), %xmm0
    movaps         %xmm0, %xmm1
    shufps         $0, %xmm0, %xmm1  // xmm1 = xmm1[0,0],xmm0[0,0]
    movaps         %xmm1, -80(%rsp)
    movss          20(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    shufps         $0, %xmm1, %xmm1  // xmm1 = xmm1[0,0,0,0]
    movaps         %xmm1, -96(%rsp)
    mulss          %xmm0, %xmm0
    shufps         $0, %xmm0, %xmm0  // xmm0 = xmm0[0,0,0,0]
    shufps         $0, %xmm5, %xmm5  // xmm5 = xmm5[0,0,0,0]
    movaps         %xmm5, -32(%rsp)
    movss          24(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    shufps         $0, %xmm1, %xmm1  // xmm1 = xmm1[0,0,0,0]
    movaps         %xmm1, -112(%rsp)
    movss          28(%r9), %xmm12  // xmm12 = mem[0],zero,zero,zero
    shufps         $0, %xmm12, %xmm12  // xmm12 = xmm12[0,0,0,0]
    movss          32(%r9), %xmm13  // xmm13 = mem[0],zero,zero,zero
    shufps         $0, %xmm13, %xmm13  // xmm13 = xmm13[0,0,0,0]
    movl           %r8d, %eax
    xorl           %r8d, %r8d
    movaps         .LCPI0_2(%rip), %xmm15  // xmm15 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    xorps          %xmm1, %xmm1
    movdqa         .LCPI0_3(%rip), %xmm2  // xmm2 = [255,255,255,255]
.p2align 4, 0x90
.LBB0_2:
    // Main loop, 4 pixels per iteration: Sobel window, normalize, dot with
    // the point-light direction, clamp, per-channel pack, store.
    xorps          %xmm4, %xmm4
    cvtsi2ss       %r8d, %xmm4
    mulss          16(%rsp), %xmm4
    addss          -116(%rsp), %xmm4
    movdqu         (%rdi,%r8,4), %xmm5
    movdqu         4(%rdi,%r8,4), %xmm6
    movdqu         8(%rdi,%r8,4), %xmm7
    ALPHA_FSCALE_X %xmm5, %xmm10, %xmm3
    ALPHA_FSCALE_X %xmm6, %xmm5, %xmm3
    ALPHA_FSCALE   %xmm7, %xmm3
    movdqu         (%rsi,%r8,4), %xmm6
    movdqu         8(%rsi,%r8,4), %xmm9
    ALPHA_FSCALE_X %xmm6, %xmm8, %xmm3
    ALPHA_FSCALE   %xmm9, %xmm3
    movdqu         (%rdx,%r8,4), %xmm14
    movaps         %xmm10, %xmm6
    addps          %xmm5, %xmm10
    addps          %xmm5, %xmm10
    movdqu         4(%rsi,%r8,4), %xmm5
    ALPHA_FSCALE   %xmm5, %xmm3
    addps          %xmm7, %xmm10
    addps          %xmm9, %xmm7
    addps          %xmm9, %xmm7
    movdqu         4(%rdx,%r8,4), %xmm9
    addps          %xmm8, %xmm6
    addps          %xmm8, %xmm6
    movdqu         8(%rdx,%r8,4), %xmm11
    ALPHA_FSCALE_X %xmm14, %xmm8, %xmm3
    ALPHA_FSCALE   %xmm9, %xmm3
    ALPHA_FSCALE   %xmm11, %xmm3
    addps          %xmm11, %xmm7
    addps          %xmm8, %xmm6
    subps          %xmm6, %xmm7
    addps          %xmm9, %xmm8
    addps          %xmm9, %xmm8
    addps          %xmm11, %xmm8
    subps          %xmm10, %xmm8
    movaps         .LCPI0_1(%rip), %xmm6  // xmm6 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
    xorps          %xmm6, %xmm7
    divps          (%rsp), %xmm7
    xorps          %xmm6, %xmm8
    divps          -16(%rsp), %xmm8
    movaps         %xmm8, %xmm6
    mulps          %xmm8, %xmm6
    movaps         %xmm7, %xmm9
    mulps          %xmm7, %xmm9
    addps          %xmm6, %xmm9
    addps          %xmm15, %xmm9
    sqrtps         %xmm9, %xmm9
    movaps         %xmm15, %xmm6
    divps          %xmm9, %xmm6
    shufps         $0, %xmm4, %xmm4  // xmm4 = xmm4[0,0,0,0]
    addps          -64(%rsp), %xmm4
    movaps         -48(%rsp), %xmm9
    subps          %xmm4, %xmm9
    movaps         -96(%rsp), %xmm10
    subps          %xmm5, %xmm10
    movaps         %xmm9, %xmm5
    mulps          %xmm9, %xmm5
    addps          %xmm0, %xmm5
    movaps         %xmm10, %xmm4
    mulps          %xmm10, %xmm4
    addps          %xmm5, %xmm4
    sqrtps         %xmm4, %xmm5
    movaps         %xmm15, %xmm11
    divps          %xmm5, %xmm11
    mulps          %xmm11, %xmm9
    movaps         -80(%rsp), %xmm5
    mulps          %xmm11, %xmm5
    mulps          %xmm10, %xmm11
    mulps          %xmm6, %xmm7
    cmpneqps       %xmm1, %xmm4
    andps          %xmm4, %xmm9
    mulps          %xmm7, %xmm9
    mulps          %xmm6, %xmm8
    andps          %xmm4, %xmm5
    mulps          %xmm8, %xmm5
    addps          %xmm9, %xmm5
    andps          %xmm11, %xmm4
    mulps          %xmm6, %xmm4
    addps          %xmm5, %xmm4
    maxps          %xmm1, %xmm4
    mulps          -32(%rsp), %xmm4
    maxps          %xmm1, %xmm4
    minps          %xmm15, %xmm4
    movaps         -112(%rsp), %xmm5
    mulps          %xmm4, %xmm5
    addps          .Lpoint_half(%rip), %xmm5  // round-half-up R
    cvttps2dq      %xmm5, %xmm5
    movdqa         %xmm5, %xmm6
    pcmpgtd        %xmm1, %xmm6
    pand           %xmm5, %xmm6
    movdqa         %xmm2, %xmm5
    pcmpgtd        %xmm6, %xmm5
    pand           %xmm5, %xmm6
    pxor           .LCPI0_5(%rip), %xmm5
    por            %xmm6, %xmm5
    movaps         %xmm12, %xmm6
    mulps          %xmm4, %xmm6
    addps          .Lpoint_half(%rip), %xmm6  // round-half-up G
    cvttps2dq      %xmm6, %xmm6
    movdqa         %xmm6, %xmm7
    pcmpgtd        %xmm1, %xmm7
    pand           %xmm6, %xmm7
    movdqa         %xmm2, %xmm6
    pcmpgtd        %xmm7, %xmm6
    pand           %xmm6, %xmm7
    pandn          %xmm2, %xmm6
    por            %xmm7, %xmm6
    mulps          %xmm13, %xmm4
    addps          .Lpoint_half(%rip), %xmm4  // round-half-up B
    cvttps2dq      %xmm4, %xmm4
    movdqa         %xmm4, %xmm7
    pcmpgtd        %xmm1, %xmm7
    pand           %xmm4, %xmm7
    movdqa         %xmm2, %xmm4
    pcmpgtd        %xmm7, %xmm4
    pand           %xmm4, %xmm7
    pandn          %xmm2, %xmm4
    por            %xmm7, %xmm4
    pslld          $16, %xmm5
    pslld          $8, %xmm6
    por            %xmm5, %xmm6
    por            %xmm4, %xmm6
    por            .LCPI0_4(%rip), %xmm6
    movdqu         %xmm6, (%rcx,%r8,4)
    addq           $4, %r8
    cmpq           %rax, %r8
    jb             .LBB0_2
    addq           $40, %rsp
    CFI_DEF_CFA_OFFSET(8)
.LBB0_4:
    retq
.Lfunc_end0:
CFI_END
LIT16
.p2align 4, 0x0
.LCPI1_0:
.long	0x40000000  // float 2
.long	0x40400000  // float 3
.zero	4
.zero	4
.LCPI1_1:
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.long	0x80000000  // float -0
.LCPI1_2:
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.long	0x3f800000  // float 1
.LCPI1_3:
.long	255  // 0xff
.long	255  // 0xff
.long	255  // 0xff
.long	255  // 0xff
.LCPI1_4:
.long	4278190080  // 0xff000000
.long	4278190080  // 0xff000000
.zero	4
.zero	4
.text
.globl SYM(ksvgLightingPointDiffuseRowSsse3Linear)
.p2align 4, 0x90
TYPE(SYM(ksvgLightingPointDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingPointDiffuseRowSsse3Linear):
CFI_START
    testl          %r8d, %r8d
    jle            .LBB1_7
    pushq          %r14
    CFI_DEF_CFA_OFFSET(16)
    pushq          %rbx
    CFI_DEF_CFA_OFFSET(24)
    subq           $40, %rsp
    CFI_DEF_CFA_OFFSET(64)
    CFI_OFFSET(%rbx, -24)
    CFI_OFFSET(%r14, -16)
    movq           64(%rsp), %rax
    movss          16(%r9), %xmm0  // xmm0 = mem[0],zero,zero,zero
    movss          40(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movss          %xmm1, -116(%rsp)
    movd           48(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    movss          36(%r9), %xmm3  // xmm3 = mem[0],zero,zero,zero
    shufps         $0, %xmm3, %xmm3  // xmm3 = xmm3[0,0,0,0]
    movss          (%r9), %xmm2  // xmm2 = mem[0],zero,zero,zero
    movss          4(%r9), %xmm4  // xmm4 = mem[0],zero,zero,zero
    movss          8(%r9), %xmm5  // xmm5 = mem[0],zero,zero,zero
    movss          12(%r9), %xmm6  // xmm6 = mem[0],zero,zero,zero
    shufps         $0, %xmm2, %xmm2  // xmm2 = xmm2[0,0,0,0]
    movaps         %xmm2, (%rsp)
    shufps         $0, %xmm4, %xmm4  // xmm4 = xmm4[0,0,0,0]
    movaps         %xmm4, -16(%rsp)
    movq           %xmm1, %xmm2  // xmm2 = xmm1[0],zero
    movdqa         %xmm1, 16(%rsp)
    movsldup       %xmm1, %xmm1  // xmm1 = xmm1[0,0,2,2]
    mulps          .LCPI1_0(%rip), %xmm1
    shufps         $66, %xmm1, %xmm2  // xmm2 = xmm2[2,0],xmm1[0,1]
    movaps         %xmm2, -64(%rsp)
    shufps         $0, %xmm6, %xmm6  // xmm6 = xmm6[0,0,0,0]
    movaps         %xmm6, -48(%rsp)
    subss          44(%r9), %xmm0
    movaps         %xmm0, %xmm1
    shufps         $0, %xmm0, %xmm1  // xmm1 = xmm1[0,0],xmm0[0,0]
    movaps         %xmm1, -80(%rsp)
    movss          20(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    shufps         $0, %xmm1, %xmm1  // xmm1 = xmm1[0,0,0,0]
    movaps         %xmm1, -96(%rsp)
    mulss          %xmm0, %xmm0
    shufps         $0, %xmm0, %xmm0  // xmm0 = xmm0[0,0,0,0]
    shufps         $0, %xmm5, %xmm5  // xmm5 = xmm5[0,0,0,0]
    movaps         %xmm5, -32(%rsp)
    movss          24(%r9), %xmm1  // xmm1 = mem[0],zero,zero,zero
    shufps         $0, %xmm1, %xmm1  // xmm1 = xmm1[0,0,0,0]
    movaps         %xmm1, -112(%rsp)
    movss          28(%r9), %xmm12  // xmm12 = mem[0],zero,zero,zero
    shufps         $0, %xmm12, %xmm12  // xmm12 = xmm12[0,0,0,0]
    movss          32(%r9), %xmm13  // xmm13 = mem[0],zero,zero,zero
    shufps         $0, %xmm13, %xmm13  // xmm13 = xmm13[0,0,0,0]
    movl           %r8d, %r8d
    xorl           %r9d, %r9d
    movaps         .LCPI1_2(%rip), %xmm15  // xmm15 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
    xorps          %xmm1, %xmm1
    movdqa         .LCPI1_3(%rip), %xmm11  // xmm11 = [255,255,255,255]
    jmp            .LBB1_2
.p2align 4, 0x90
.LBB1_4:
    // Vector-pack fast path (all channels already sRGB bytes, no LUT).
    pslld          $16, %xmm7
    pslld          $8, %xmm14
    por            %xmm7, %xmm14
    por            %xmm2, %xmm14
    por            .LCPI1_4(%rip), %xmm14
    movq           %xmm14, (%rcx,%r9,4)
    movd           %xmm10, %r10d
    movd           %xmm9, %r11d
    movd           %xmm8, %ebx
    shll           $16, %r10d
    shll           $8, %r11d
    orl            %r10d, %r11d
    leal           (%rbx,%r11), %r10d
    addl           $-16777216, %r10d  // imm = 0xFF000000
    movl           %r10d, 8(%rcx,%r9,4)
    movd           %xmm6, %r11d
    movd           %xmm5, %r10d
    movd           %xmm4, %ebx
.LBB1_5:
    // Shared scalar-pack tail (last pixel of the L2S path).
    shll           $16, %r11d
    shll           $8, %r10d
    addl           %r11d, %r10d
    addl           %ebx, %r10d
    addl           $-16777216, %r10d  // imm = 0xFF000000
    movl           %r10d, 12(%rcx,%r9,4)
    addq           $4, %r9
    cmpq           %r8, %r9
    jae            .LBB1_6
.LBB1_2:
    // Linear-kernel main loop (window/normalize/dot as in the plain kernel,
    // then per-pixel L2S conversion below).
    xorps          %xmm4, %xmm4
    cvtsi2ss       %r9d, %xmm4
    mulss          16(%rsp), %xmm4
    addss          -116(%rsp), %xmm4
    movdqu         (%rdi,%r9,4), %xmm2
    movdqu         4(%rdi,%r9,4), %xmm5
    movdqu         8(%rdi,%r9,4), %xmm7
    ALPHA_FSCALE_X %xmm2, %xmm6, %xmm3
    ALPHA_FSCALE   %xmm5, %xmm3
    psrld          $24, %xmm7

    cvtdq2ps       %xmm7, %xmm7
    mulps          %xmm3, %xmm7
    movdqu         (%rsi,%r9,4), %xmm2
    movdqu         8(%rsi,%r9,4), %xmm8
    ALPHA_FSCALE_X %xmm2, %xmm14, %xmm3
    ALPHA_FSCALE_X %xmm8, %xmm2, %xmm3
    movdqu         (%rdx,%r9,4), %xmm8
    movdqu         4(%rdx,%r9,4), %xmm9
    movaps         %xmm6, %xmm10
    addps          %xmm5, %xmm6
    addps          %xmm5, %xmm6
    movdqu         4(%rsi,%r9,4), %xmm5
    ALPHA_FSCALE   %xmm5, %xmm3
    addps          %xmm7, %xmm6
    addps          %xmm2, %xmm7
    addps          %xmm2, %xmm7
    movdqu         8(%rdx,%r9,4), %xmm2
    ALPHA_FSCALE   %xmm8, %xmm3
    ALPHA_FSCALE   %xmm9, %xmm3
    ALPHA_FSCALE   %xmm2, %xmm3
    addps          %xmm2, %xmm7
    addps          %xmm14, %xmm10
    addps          %xmm14, %xmm10
    addps          %xmm8, %xmm10
    subps          %xmm10, %xmm7
    addps          %xmm9, %xmm8
    addps          %xmm9, %xmm8
    addps          %xmm2, %xmm8
    subps          %xmm6, %xmm8
    movaps         .LCPI1_1(%rip), %xmm2  // xmm2 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
    xorps          %xmm2, %xmm7
    divps          (%rsp), %xmm7
    xorps          %xmm2, %xmm8
    divps          -16(%rsp), %xmm8
    movaps         %xmm8, %xmm2
    mulps          %xmm8, %xmm2
    movaps         %xmm7, %xmm6
    mulps          %xmm7, %xmm6
    addps          %xmm2, %xmm6
    addps          %xmm15, %xmm6
    sqrtps         %xmm6, %xmm6
    movaps         %xmm15, %xmm2
    divps          %xmm6, %xmm2
    mulps          %xmm2, %xmm7
    mulps          %xmm2, %xmm8
    shufps         $0, %xmm4, %xmm4  // xmm4 = xmm4[0,0,0,0]
    addps          -64(%rsp), %xmm4
    movaps         -48(%rsp), %xmm6
    subps          %xmm4, %xmm6
    movaps         -96(%rsp), %xmm9
    subps          %xmm5, %xmm9
    movaps         %xmm6, %xmm5
    mulps          %xmm6, %xmm5
    addps          %xmm0, %xmm5
    movaps         %xmm9, %xmm4
    mulps          %xmm9, %xmm4
    addps          %xmm5, %xmm4
    sqrtps         %xmm4, %xmm5
    movaps         %xmm15, %xmm10
    divps          %xmm5, %xmm10
    mulps          %xmm10, %xmm6
    movaps         -80(%rsp), %xmm5
    mulps          %xmm10, %xmm5
    mulps          %xmm9, %xmm10
    cmpneqps       %xmm1, %xmm4
    andps          %xmm4, %xmm6
    mulps          %xmm7, %xmm6
    andps          %xmm4, %xmm5
    mulps          %xmm8, %xmm5
    addps          %xmm6, %xmm5
    andps          %xmm10, %xmm4
    mulps          %xmm2, %xmm4
    addps          %xmm5, %xmm4
    maxps          %xmm1, %xmm4
    mulps          -32(%rsp), %xmm4
    maxps          %xmm1, %xmm4
    minps          %xmm15, %xmm4
    movaps         -112(%rsp), %xmm2
    mulps          %xmm4, %xmm2
    addps          .Lpoint_half(%rip), %xmm2  // round-half-up R
    cvttps2dq      %xmm2, %xmm2
    movdqa         %xmm2, %xmm5
    pcmpgtd        %xmm1, %xmm5
    pand           %xmm2, %xmm5
    movdqa         %xmm11, %xmm7
    pcmpgtd        %xmm5, %xmm7
    pand           %xmm7, %xmm5
    pandn          %xmm11, %xmm7
    por            %xmm5, %xmm7
    movaps         %xmm12, %xmm2
    mulps          %xmm4, %xmm2
    addps          .Lpoint_half(%rip), %xmm2  // round-half-up G
    cvttps2dq      %xmm2, %xmm2
    movdqa         %xmm2, %xmm5
    pcmpgtd        %xmm1, %xmm5
    pand           %xmm2, %xmm5
    movdqa         %xmm11, %xmm14
    pcmpgtd        %xmm5, %xmm14
    pand           %xmm14, %xmm5
    pandn          %xmm11, %xmm14
    por            %xmm5, %xmm14
    mulps          %xmm13, %xmm4
    addps          .Lpoint_half(%rip), %xmm4  // round-half-up B
    cvttps2dq      %xmm4, %xmm2
    movdqa         %xmm2, %xmm4
    pcmpgtd        %xmm1, %xmm4
    pand           %xmm2, %xmm4
    movdqa         %xmm11, %xmm2
    pcmpgtd        %xmm4, %xmm2
    pand           %xmm2, %xmm4
    pandn          %xmm11, %xmm2
    por            %xmm4, %xmm2
    pshufd         $238, %xmm7, %xmm10  // xmm10 = xmm7[2,3,2,3]
    pshufd         $238, %xmm14, %xmm9  // xmm9 = xmm14[2,3,2,3]
    pshufd         $238, %xmm2, %xmm8  // xmm8 = xmm2[2,3,2,3]
    pshufd         $255, %xmm7, %xmm6  // xmm6 = xmm7[3,3,3,3]
    pshufd         $255, %xmm14, %xmm5  // xmm5 = xmm14[3,3,3,3]
    pshufd         $255, %xmm2, %xmm4  // xmm4 = xmm2[3,3,3,3]
    testq          %rax, %rax
    // With an L2S table, convert channels through it (scalar path below);
    // otherwise take the vector-pack fast path (.LBB1_4).
    je             .LBB1_4
    movd           %xmm2, %r10d
    movd           %xmm14, %r11d
    movd           %xmm7, %ebx
    L2S_GATHER_PACK %rax, %rbx, %ebx, %r11, %r11d, %r10, %r10d
    movl           %r11d, (%rcx,%r9,4)
    pshufd         $85, %xmm7, %xmm7  // xmm7 = xmm7[1,1,1,1]
    movd           %xmm7, %r10d
    pshufd         $85, %xmm14, %xmm7  // xmm7 = xmm14[1,1,1,1]
    movd           %xmm7, %r11d
    pshufd         $85, %xmm2, %xmm2  // xmm2 = xmm2[1,1,1,1]
    movd           %xmm2, %ebx
    L2S_GATHER_PACK %rax, %r10, %r10d, %r11, %r11d, %rbx, %ebx
    movl           %r11d, 4(%rcx,%r9,4)
    movd           %xmm10, %r10d
    movd           %xmm9, %r11d
    movd           %xmm8, %ebx
    L2S_GATHER_PACK %rax, %r10, %r10d, %r11, %r11d, %rbx, %ebx
    movl           %r11d, 8(%rcx,%r9,4)
    movd           %xmm6, %r10d
    movd           %xmm5, %ebx
    movd           %xmm4, %r14d
    movzbl         (%rax,%r10), %r11d
    movzbl         (%rax,%rbx), %r10d
    movzbl         (%rax,%r14), %ebx
    jmp            .LBB1_5
.LBB1_6:
    addq           $40, %rsp
    CFI_DEF_CFA_OFFSET(24)
    popq           %rbx
    CFI_DEF_CFA_OFFSET(16)
    popq           %r14
    CFI_DEF_CFA_OFFSET(8)
    CFI_RESTORE(%rbx)
    CFI_RESTORE(%r14)
.LBB1_7:
    retq
.Lfunc_end1:
CFI_END
GNU_STACK
