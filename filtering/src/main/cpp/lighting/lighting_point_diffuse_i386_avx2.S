/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "asm_macros.S"

/*
 * Description:
 *   Scalar L2S gather + force-alpha byte pack for the linear kernel: gathers
 *   R/G/B bytes via the LUT base in %edx and packs (R << 16) | (G << 8) | B
 *   | 0xFF000000 into %edi. Registers are deliberately fixed (identical at
 *   all 7 use sites), so parameters would be pure noise. Uses VEX extracts
 *   at the call sites (this file is AVX1-class); the last partial block
 *   jumps to the shared .LBB1_5 tail instead and is NOT covered.
 *
 * Output:
 *   %edi = packed 0xFFRRGGBB pixel
 *
 * Clobbers:
 *   %ebp (R<<16), %edi (in-place: G<<8, then the packed pixel), %eax (B)
 */
.macro L2S_GATHER_PACK
	movzbl	(%edx,%ebp), %ebp
	movzbl	(%edx,%edi), %edi
	movzbl	(%edx,%eax), %eax
	shll	$16, %ebp
	shll	$8, %edi
	orl	%ebp, %edi
	orl	%eax, %edi
	orl	$-16777216, %edi
.endm

/*
 * Description:
 *   Alpha-byte to scaled float, VEX-encoded form: extracts the alpha lane,
 *   converts int32->float (exact for 0..255), and scales. The 3-operand VEX
 *   encoding allows arbitrary src/ch/dst combinations (incl. memory-operand
 *   scale) with no extra moves. Mul operand order normalized scale-first;
 *   bit-exact per the header ALPHA_FSCALE argument (finite channel floats).
 *
 * Inputs:
 *   \src, \ch, \scale, \dst as in ALPHA_FSCALE (\scale may be a memory
 *   operand, e.g. a loop-invariant spill reload).
 *
 * Output:
 *   \dst = float((\src >> 24) & 0xFF) * \scale
 *
 * Clobbers:
 *   \ch, \dst (written; \src preserved unless aliased)
 */
.macro ALPHA_FSCALE_V src, ch, scale, dst
	vpsrld	$24, \src, \ch
	vcvtdq2ps	\ch, \ch
	vmulps	\scale, \ch, \dst
.endm

	.text
	.file	"pd_av.c"
	RODATA16
	.p2align	4, 0x0                          # -- Begin function ksvgLightingPointDiffuseRowAvx2
.LCPI0_0:
	.long	0x40000000                      # float 2
	.long	0x40400000                      # float 3
	.long	0x40800000                      # float 4
	.long	0x40a00000                      # float 5
.LCPI0_1:
	.long	0x40c00000                      # float 6
	.long	0x40e00000                      # float 7
	.zero	4
	.zero	4
	RODATA4
	.p2align	2, 0x0
.LCPI0_2:
	.long	0x80000000                      # float -0
.LCPI0_3:
	.long	0x3f800000                      # float 1
.LCPI0_4:
	.long	255                             # 0xff
.LCPI0_5:
	.long	4278190080                      # 0xff000000
.LCPI0_6:
	.long	0x3f000000                      # float 0.5
	.text
	.globl	SYM(ksvgLightingPointDiffuseRowAvx2)
	.p2align	4, 0x90
	.type	SYM(ksvgLightingPointDiffuseRowAvx2),@function
SYM(ksvgLightingPointDiffuseRowAvx2):        # @ksvgLightingPointDiffuseRowAvx2
	CFI_START
# %bb.0:
	pushl	%ebp
	CFI_DEF_CFA_OFFSET(8)
	pushl	%ebx
	CFI_DEF_CFA_OFFSET(12)
	pushl	%edi
	CFI_DEF_CFA_OFFSET(16)
	pushl	%esi
	CFI_DEF_CFA_OFFSET(20)
	subl	$588, %esp
	CFI_DEF_CFA_OFFSET(608)
	CFI_OFFSET(%esi, -20)
	CFI_OFFSET(%edi, -16)
	CFI_OFFSET(%ebx, -12)
	CFI_OFFSET(%ebp, -8)
	calll	.L0$pb
.L0$pb:
	popl	%ebx
.Ltmp0:
	addl	$_GLOBAL_OFFSET_TABLE_+(.Ltmp0-.L0$pb), %ebx
	movl	624(%esp), %eax # count
	testl	%eax, %eax
	jle	.LBB0_3
# %bb.1:
	movl	628(%esp), %ecx # params
	movl	616(%esp), %edx # srcB
	movl	612(%esp), %esi # srcM
	movl	608(%esp), %edi # srcT
	vmovss	16(%ecx), %xmm0
	vbroadcastss	48(%ecx), %xmm4
	vpbroadcastd	36(%ecx), %ymm1
	vmovdqu	%ymm1, 128(%esp)                # 32-byte Spill
	vbroadcastss	(%ecx), %ymm2
	vmovups	%ymm2, 544(%esp)                # 32-byte Spill
	vbroadcastss	4(%ecx), %ymm2
	vmovups	%ymm2, 512(%esp)                # 32-byte Spill
	vxorps	%xmm2, %xmm2, %xmm2
	vblendps	$2, %xmm4, %xmm2, %xmm2
	vmulps	.LCPI0_0@GOTOFF(%ebx), %xmm4, %xmm3
	vpermpd	$208, %ymm3, %ymm3
	vblendps	$3, %ymm2, %ymm3, %ymm2
	vmovaps	%xmm4, 16(%esp)                 # 16-byte Spill
	vmulps	.LCPI0_1@GOTOFF(%ebx), %xmm4, %xmm4
	vinsertf128	$1, %xmm4, %ymm3, %ymm3
	vshufpd	$2, %ymm3, %ymm2, %ymm2
	vmovupd	%ymm2, 480(%esp)                # 32-byte Spill
	vbroadcastss	12(%ecx), %ymm2
	vmovups	%ymm2, 448(%esp)                # 32-byte Spill
	vsubss	44(%ecx), %xmm0, %xmm0
	vbroadcastss	%xmm0, %ymm2
	vmovups	%ymm2, 416(%esp)                # 32-byte Spill
	vmulss	%xmm0, %xmm0, %xmm0
	vbroadcastss	%xmm0, %ymm0
	vmovups	%ymm0, 384(%esp)                # 32-byte Spill
	xorl	%ebp, %ebp # loop counter
	vbroadcastss	20(%ecx), %ymm0
	vmovups	%ymm0, 352(%esp)                # 32-byte Spill
	vbroadcastss	8(%ecx), %ymm0
	vmovups	%ymm0, 320(%esp)                # 32-byte Spill
	vbroadcastss	24(%ecx), %ymm0
	vmovups	%ymm0, 288(%esp)                # 32-byte Spill
	vbroadcastss	28(%ecx), %ymm0
	vmovups	%ymm0, 256(%esp)                # 32-byte Spill
	vbroadcastss	32(%ecx), %ymm0
	vmovups	%ymm0, 224(%esp)                # 32-byte Spill
	vbroadcastss	.LCPI0_2@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 192(%esp)                # 32-byte Spill
	movss	40(%ecx), %xmm0
	vmovss	%xmm0, 12(%esp)                 # 4-byte Spill
	movl	620(%esp), %ecx # dst
	vbroadcastss	.LCPI0_3@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 160(%esp)                # 32-byte Spill
	vbroadcastss	.LCPI0_4@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 96(%esp)                 # 32-byte Spill
	vbroadcastss	.LCPI0_5@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 64(%esp)                 # 32-byte Spill
	.p2align	4, 0x90
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	vxorps	%xmm7, %xmm7, %xmm7
	vcvtsi2ss	%ebp, %xmm7, %xmm0
	vmovss	%xmm0, 32(%esp)                 # 4-byte Spill
	vmovdqu	(%edi,%ebp,4), %ymm3
	vpsrld	$24, %ymm3, %ymm3
	vcvtdq2ps	%ymm3, %ymm3
	vmovups	128(%esp), %ymm1                # 32-byte Reload
	vmulps	%ymm3, %ymm1, %ymm7
	vmovdqu	8(%edi,%ebp,4), %ymm3
	ALPHA_FSCALE_V %ymm3, %ymm3, %ymm1, %ymm5
	vmovdqu	(%esi,%ebp,4), %ymm3
	vmovdqu	8(%esi,%ebp,4), %ymm6
	ALPHA_FSCALE_V %ymm3, %ymm3, %ymm1, %ymm3
	ALPHA_FSCALE_V %ymm6, %ymm6, %ymm1, %ymm4
	vmovdqu	(%edx,%ebp,4), %ymm6
	ALPHA_FSCALE_V %ymm6, %ymm6, %ymm1, %ymm6
	vaddps	%ymm4, %ymm5, %ymm0
	vaddps	%ymm0, %ymm4, %ymm0
	vaddps	%ymm3, %ymm7, %ymm4
	vaddps	%ymm4, %ymm3, %ymm3
	vmovdqu	8(%edx,%ebp,4), %ymm4
	ALPHA_FSCALE_V %ymm4, %ymm4, %ymm1, %ymm4
	vaddps	%ymm4, %ymm0, %ymm0
	vaddps	%ymm6, %ymm3, %ymm3
	vsubps	%ymm3, %ymm0, %ymm0
	vmovdqu	4(%edx,%ebp,4), %ymm3
	ALPHA_FSCALE_V %ymm3, %ymm3, %ymm1, %ymm3
	vaddps	%ymm3, %ymm6, %ymm6
	vaddps	%ymm6, %ymm3, %ymm3
	vmovdqu	4(%edi,%ebp,4), %ymm6
	ALPHA_FSCALE_V %ymm6, %ymm6, %ymm1, %ymm6
	vaddps	%ymm3, %ymm4, %ymm3
	vaddps	%ymm6, %ymm7, %ymm4
	vaddps	%ymm4, %ymm6, %ymm4
	vaddps	%ymm4, %ymm5, %ymm4
	vsubps	%ymm4, %ymm3, %ymm3
	vmovups	192(%esp), %ymm2                # 32-byte Reload
	vxorps	%ymm2, %ymm0, %ymm0
	vdivps	544(%esp), %ymm0, %ymm4
	vxorps	%ymm2, %ymm3, %ymm0
	vdivps	512(%esp), %ymm0, %ymm5
	vmovss	32(%esp), %xmm0                 # 4-byte Reload
	vmulss	16(%esp), %xmm0, %xmm0
	vmulps	%ymm5, %ymm5, %ymm3
	vmulps	%ymm4, %ymm4, %ymm7
	vaddps	%ymm3, %ymm7, %ymm3
	vmovups	160(%esp), %ymm1                # 32-byte Reload
	vaddps	%ymm1, %ymm3, %ymm3
	vsqrtps	%ymm3, %ymm3
	vaddss	12(%esp), %xmm0, %xmm7
	vdivps	%ymm3, %ymm1, %ymm0
	vmulps	%ymm0, %ymm4, %ymm2
	vmovups	%ymm2, 32(%esp)                 # 32-byte Spill
	vbroadcastss	%xmm7, %ymm4
	vaddps	480(%esp), %ymm4, %ymm4
	vmovups	448(%esp), %ymm2
	vsubps	%ymm4, %ymm2, %ymm4
	vmovups	352(%esp), %ymm2
# surfaceZ = srcM[j+1..j+8] * ss (window center), not srcT(tm) center
	vmovdqu	4(%esi,%ebp,4), %ymm6
	ALPHA_FSCALE_V %ymm6, %ymm6, 128(%esp), %ymm6
	vsubps	%ymm6, %ymm2, %ymm6
	vmulps	%ymm4, %ymm4, %ymm7
	vaddps	384(%esp), %ymm7, %ymm7
	vmulps	%ymm6, %ymm6, %ymm2
	vaddps	%ymm7, %ymm2, %ymm2
	vsqrtps	%ymm2, %ymm7
	vdivps	%ymm7, %ymm1, %ymm7
	vmulps	%ymm7, %ymm4, %ymm4
	vxorps	%xmm3, %xmm3, %xmm3
	vcmpneqps	%ymm3, %ymm2, %ymm2
	vandps	%ymm4, %ymm2, %ymm4
	vmulps	32(%esp), %ymm4, %ymm3          # 32-byte Folded Reload
	vmulps	%ymm0, %ymm5, %ymm4
	vmulps	%ymm7, %ymm6, %ymm5
	vmulps	416(%esp), %ymm7, %ymm6
	vandps	%ymm6, %ymm2, %ymm6
	vmulps	%ymm4, %ymm6, %ymm4
	vaddps	%ymm4, %ymm3, %ymm3
	vandps	%ymm5, %ymm2, %ymm2
	vmulps	%ymm2, %ymm0, %ymm0
	vaddps	%ymm3, %ymm0, %ymm0
	vxorps	%xmm4, %xmm4, %xmm4
	vmaxps	%ymm4, %ymm0, %ymm0
	vmulps	320(%esp), %ymm0, %ymm0
	vmaxps	%ymm4, %ymm0, %ymm0
	vminps	%ymm1, %ymm0, %ymm0
	vmulps	288(%esp), %ymm0, %ymm2
	vbroadcastss	.LCPI0_6@GOTOFF(%ebx), %ymm5
	vaddps	%ymm5, %ymm2, %ymm2
	vcvttps2dq	%ymm2, %ymm2
	vpmaxsd	%ymm4, %ymm2, %ymm2
	vmovdqu	96(%esp), %ymm1                 # 32-byte Reload
	vpminsd	%ymm1, %ymm2, %ymm2
	vmulps	256(%esp), %ymm0, %ymm3
	vaddps	%ymm5, %ymm3, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vpmaxsd	%ymm4, %ymm3, %ymm3
	vpminsd	%ymm1, %ymm3, %ymm3
	vpslld	$16, %ymm2, %ymm2
	vpslld	$8, %ymm3, %ymm3
	vpor	%ymm3, %ymm2, %ymm2
	vmulps	224(%esp), %ymm0, %ymm0
	vaddps	%ymm5, %ymm0, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vpmaxsd	%ymm4, %ymm0, %ymm0
	vpminsd	%ymm1, %ymm0, %ymm0
	vpor	64(%esp), %ymm0, %ymm0
	vpor	%ymm0, %ymm2, %ymm0
	vmovdqu	%ymm0, (%ecx,%ebp,4)
	addl	$8, %ebp
	cmpl	%eax, %ebp
	jl	.LBB0_2
.LBB0_3:
	vzeroupper
	addl	$588, %esp
	popl	%esi
	popl	%edi
	popl	%ebx
	popl	%ebp
	retl
.Lfunc_end0:
	SIZE(SYM(ksvgLightingPointDiffuseRowAvx2))
	CFI_END

	RODATA16
	.p2align	4, 0x0                          # -- Begin function ksvgLightingPointDiffuseRowAvx2Linear
.LCPI1_0:
	.long	0x40000000                      # float 2
	.long	0x40400000                      # float 3
	.long	0x40800000                      # float 4
	.long	0x40a00000                      # float 5
.LCPI1_1:
	.long	0x40c00000                      # float 6
	.long	0x40e00000                      # float 7
	.zero	4
	.zero	4
	RODATA4
	.p2align	2, 0x0
.LCPI1_2:
	.long	0x80000000                      # float -0
.LCPI1_3:
	.long	0x3f800000                      # float 1
.LCPI1_4:
	.long	255                             # 0xff
.LCPI1_5:
	.long	4278190080                      # 0xff000000
.LCPI1_6:
	.long	0x3f000000                      # float 0.5
	.text
	.globl	SYM(ksvgLightingPointDiffuseRowAvx2Linear)
	.p2align	4, 0x90
	.type	SYM(ksvgLightingPointDiffuseRowAvx2Linear),@function
SYM(ksvgLightingPointDiffuseRowAvx2Linear):  # @ksvgLightingPointDiffuseRowAvx2Linear
	CFI_START
# %bb.0:
	pushl	%ebp
	CFI_DEF_CFA_OFFSET(8)
	pushl	%ebx
	CFI_DEF_CFA_OFFSET(12)
	pushl	%edi
	CFI_DEF_CFA_OFFSET(16)
	pushl	%esi
	CFI_DEF_CFA_OFFSET(20)
	subl	$556, %esp
	CFI_DEF_CFA_OFFSET(576)
	CFI_OFFSET(%esi, -20)
	CFI_OFFSET(%edi, -16)
	CFI_OFFSET(%ebx, -12)
	CFI_OFFSET(%ebp, -8)
	calll	.L1$pb
.L1$pb:
	popl	%ebx
.Ltmp1:
	addl	$_GLOBAL_OFFSET_TABLE_+(.Ltmp1-.L1$pb), %ebx
	cmpl	$0, 592(%esp) # count
	jle	.LBB1_6
# %bb.1:
	movl	596(%esp), %eax # params
	movl	588(%esp), %esi # dst
	vmovss	16(%eax), %xmm0
	vbroadcastss	48(%eax), %xmm4
	vpbroadcastd	36(%eax), %ymm1
	vmovdqu	%ymm1, 96(%esp)                 # 32-byte Spill
	vbroadcastss	(%eax), %ymm2
	vmovups	%ymm2, 512(%esp)                # 32-byte Spill
	vbroadcastss	4(%eax), %ymm2
	vmovups	%ymm2, 480(%esp)                # 32-byte Spill
	vxorps	%xmm2, %xmm2, %xmm2
	vblendps	$2, %xmm4, %xmm2, %xmm2
	vmulps	.LCPI1_0@GOTOFF(%ebx), %xmm4, %xmm3
	vpermpd	$208, %ymm3, %ymm3
	vblendps	$3, %ymm2, %ymm3, %ymm2
	vmovaps	%xmm4, 16(%esp)                 # 16-byte Spill
	vmulps	.LCPI1_1@GOTOFF(%ebx), %xmm4, %xmm4
	vinsertf128	$1, %xmm4, %ymm3, %ymm3
	vshufpd	$2, %ymm3, %ymm2, %ymm2
	vmovupd	%ymm2, 448(%esp)                # 32-byte Spill
	vbroadcastss	12(%eax), %ymm2
	vmovups	%ymm2, 416(%esp)                # 32-byte Spill
	vsubss	44(%eax), %xmm0, %xmm0
	vbroadcastss	%xmm0, %ymm2
	vmovups	%ymm2, 384(%esp)                # 32-byte Spill
	vmulss	%xmm0, %xmm0, %xmm0
	vbroadcastss	%xmm0, %ymm0
	vmovups	%ymm0, 352(%esp)                # 32-byte Spill
	xorl	%ecx, %ecx # loop counter
	vbroadcastss	20(%eax), %ymm0
	vmovups	%ymm0, 320(%esp)                # 32-byte Spill
	vbroadcastss	8(%eax), %ymm0
	vmovups	%ymm0, 288(%esp)                # 32-byte Spill
	vbroadcastss	24(%eax), %ymm0
	vmovups	%ymm0, 256(%esp)                # 32-byte Spill
	vbroadcastss	28(%eax), %ymm0
	vmovups	%ymm0, 224(%esp)                # 32-byte Spill
	vbroadcastss	32(%eax), %ymm0
	vmovups	%ymm0, 192(%esp)                # 32-byte Spill
	vbroadcastss	.LCPI1_2@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 160(%esp)                # 32-byte Spill
	vbroadcastss	.LCPI1_3@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 128(%esp)                # 32-byte Spill
	vmovss	40(%eax), %xmm0
	vmovss	%xmm0, 12(%esp)                 # 4-byte Spill
	vbroadcastss	.LCPI1_4@GOTOFF(%ebx), %ymm0
	vmovups	%ymm0, 64(%esp)                 # 32-byte Spill
	jmp	.LBB1_2
	.p2align	4, 0x90
.LBB1_4:                                #   in Loop: Header=BB1_2 Depth=1
	vpslld	$16, %xmm7, %xmm2
	vpslld	$8, %xmm5, %xmm5
	vpor	%xmm5, %xmm2, %xmm2
	vpbroadcastd	.LCPI1_5@GOTOFF(%ebx), %xmm5
	vpor	%xmm5, %xmm4, %xmm4
	vpor	%xmm4, %xmm2, %xmm2
	vmovdqu	%xmm2, (%esi,%ecx,4)
	vpslld	$16, %xmm3, %xmm2
	vpslld	$8, %xmm0, %xmm4
	vpor	%xmm4, %xmm2, %xmm2
	vpor	%xmm5, %xmm6, %xmm4
	vpor	%xmm4, %xmm2, %xmm2
	vpextrd	$2, %xmm3, %ebp
	vpextrd	$2, %xmm0, %edi
	vpextrd	$2, %xmm6, %edx # temp register swap
	vmovq	%xmm2, 16(%esi,%ecx,4)
	shll	$16, %ebp
	shll	$8, %edi
	orl	%ebp, %edi
	leal	(%edx,%edi), %edi
	addl	$-16777216, %edi
	movl	%edi, 24(%esi,%ecx,4)
	vpextrd	$3, %xmm3, %ebp
	vpextrd	$3, %xmm0, %edx
	vpextrd	$3, %xmm6, %edi
.LBB1_5:                                #   in Loop: Header=BB1_2 Depth=1
	shll	$16, %ebp
	shll	$8, %edx
	addl	%ebp, %edx
	leal	(%edi,%edx), %ebp
	addl	$-16777216, %ebp
	movl	%ebp, 28(%esi,%ecx,4)
	addl	$8, %ecx
	cmpl	592(%esp), %ecx
	jge	.LBB1_6
.LBB1_2:                                # =>This Inner Loop Header: Depth=1
	vxorps	%xmm7, %xmm7, %xmm7
	vcvtsi2ss	%ecx, %xmm7, %xmm0
	movl	576(%esp), %edi # srcT
	vmovdqu	(%edi,%ecx,4), %ymm3
	vpsrld	$24, %ymm3, %ymm3
	vcvtdq2ps	%ymm3, %ymm3
	vmovups	96(%esp), %ymm1                 # 32-byte Reload
	vmulps	%ymm3, %ymm1, %ymm3
	vmovdqu	8(%edi,%ecx,4), %ymm4
	ALPHA_FSCALE_V %ymm4, %ymm4, %ymm1, %ymm4
	movl	580(%esp), %eax # srcM
	vmovdqu	(%eax,%ecx,4), %ymm5
	vmovdqu	8(%eax,%ecx,4), %ymm7
	ALPHA_FSCALE_V %ymm5, %ymm5, %ymm1, %ymm6
	ALPHA_FSCALE_V %ymm7, %ymm5, %ymm1, %ymm7
	movl	584(%esp), %eax # srcB
	vmovdqu	(%eax,%ecx,4), %ymm5
	ALPHA_FSCALE_V %ymm5, %ymm5, %ymm1, %ymm5
	vaddps	%ymm7, %ymm4, %ymm2
	vaddps	%ymm2, %ymm7, %ymm2
	vaddps	%ymm6, %ymm3, %ymm7
	vaddps	%ymm7, %ymm6, %ymm6
	vmovdqu	8(%eax,%ecx,4), %ymm7
	ALPHA_FSCALE_V %ymm7, %ymm7, %ymm1, %ymm7
	vaddps	%ymm7, %ymm2, %ymm2
	vaddps	%ymm5, %ymm6, %ymm6
	vsubps	%ymm6, %ymm2, %ymm2
	vmovdqu	4(%eax,%ecx,4), %ymm6
	ALPHA_FSCALE_V %ymm6, %ymm6, %ymm1, %ymm6
	vaddps	%ymm6, %ymm5, %ymm5
	vaddps	%ymm5, %ymm6, %ymm6
	vmovdqu	4(%edi,%ecx,4), %ymm5
	ALPHA_FSCALE_V %ymm5, %ymm5, %ymm1, %ymm5
	vaddps	%ymm6, %ymm7, %ymm6
	vaddps	%ymm5, %ymm3, %ymm3
	vaddps	%ymm3, %ymm5, %ymm3
	vaddps	%ymm3, %ymm4, %ymm3
	vsubps	%ymm3, %ymm6, %ymm6
	vmovups	160(%esp), %ymm4                # 32-byte Reload
	vxorps	%ymm4, %ymm2, %ymm2
	vdivps	512(%esp), %ymm2, %ymm2
	vxorps	%ymm4, %ymm6, %ymm3
	vdivps	480(%esp), %ymm3, %ymm3
	vmulss	16(%esp), %xmm0, %xmm0
	vmulps	%ymm3, %ymm3, %ymm4
	vmulps	%ymm2, %ymm2, %ymm6
	vaddps	%ymm4, %ymm6, %ymm4
	vmovups	128(%esp), %ymm1                # 32-byte Reload
	vaddps	%ymm1, %ymm4, %ymm4
	vsqrtps	%ymm4, %ymm4
	vaddss	12(%esp), %xmm0, %xmm6
	vdivps	%ymm4, %ymm1, %ymm0
	vmulps	%ymm0, %ymm2, %ymm2
	vmovups	%ymm2, 32(%esp)                 # 32-byte Spill
	vbroadcastss	%xmm6, %ymm2
	vaddps	448(%esp), %ymm2, %ymm2
vmovups	416(%esp), %ymm6
	vsubps	%ymm2, %ymm6, %ymm2
# surfaceZ = srcM[j+1..j+8] * ss (center of window), not srcT (tm)
	movl	580(%esp), %eax # srcM
	vmovdqu	4(%eax,%ecx,4), %ymm4
	ALPHA_FSCALE_V %ymm4, %ymm4, 96(%esp), %ymm4
	vmovups	320(%esp), %ymm6              # lightZ
	vsubps	%ymm4, %ymm6, %ymm5
	vmulps	%ymm2, %ymm2, %ymm6
	vaddps	352(%esp), %ymm6, %ymm6
	vmulps	%ymm5, %ymm5, %ymm7
	vaddps	%ymm6, %ymm7, %ymm6
	vsqrtps	%ymm6, %ymm7
	vdivps	%ymm7, %ymm1, %ymm7
	vmulps	%ymm7, %ymm2, %ymm2
	vxorps	%xmm4, %xmm4, %xmm4
	vcmpneqps	%ymm4, %ymm6, %ymm6
	vandps	%ymm2, %ymm6, %ymm2
	vmulps	32(%esp), %ymm2, %ymm2
	vmulps	%ymm0, %ymm3, %ymm3
	vmulps	%ymm7, %ymm5, %ymm5
	vmovups	%ymm5, 32(%esp)                 # 32-byte Spill
	vmulps	384(%esp), %ymm7, %ymm5
	vandps	%ymm5, %ymm6, %ymm5
	vmulps	%ymm3, %ymm5, %ymm3
	vaddps	%ymm3, %ymm2, %ymm2
	vandps	32(%esp), %ymm6, %ymm3
	vmulps	%ymm3, %ymm0, %ymm0
	vaddps	%ymm2, %ymm0, %ymm0
	vmaxps	%ymm4, %ymm0, %ymm0
	vmulps	288(%esp), %ymm0, %ymm0
	vmaxps	%ymm4, %ymm0, %ymm0
	vminps	%ymm1, %ymm0, %ymm0
	vmulps	256(%esp), %ymm0, %ymm2
	vbroadcastss	.LCPI1_6@GOTOFF(%ebx), %ymm3
	vaddps	%ymm3, %ymm2, %ymm2
	vcvttps2dq	%ymm2, %ymm2
	vpmaxsd	%ymm4, %ymm2, %ymm2
	vmovdqu	64(%esp), %ymm1                 # 32-byte Reload
	vpminsd	%ymm1, %ymm2, %ymm7
	vmulps	224(%esp), %ymm0, %ymm2
	vaddps	%ymm3, %ymm2, %ymm2
	vcvttps2dq	%ymm2, %ymm2
	vpmaxsd	%ymm4, %ymm2, %ymm2
	vpminsd	%ymm1, %ymm2, %ymm5
	vmulps	192(%esp), %ymm0, %ymm0
	vaddps	%ymm3, %ymm0, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vpmaxsd	%ymm4, %ymm0, %ymm0
	vpminsd	%ymm1, %ymm0, %ymm4
	vextracti128	$1, %ymm7, %xmm3
	vextracti128	$1, %ymm5, %xmm0
	vextracti128	$1, %ymm4, %xmm6
	# In ksvgLightingPointDiffuseRowAvx2Linear, there is NO l2s pointer argument on i386.
	# It uses the global ksvg_linear_to_srgb_lut.
	movl	ksvg_linear_to_srgb_lut@GOT(%ebx), %edx
	testl	%edx, %edx
	je	.LBB1_4
# %bb.3:
	vmovd	%xmm4, %eax
	vmovd	%xmm5, %edi
	vmovd	%xmm7, %ebp # Register swap: ebp was used for temp. ebx is GOT.
	L2S_GATHER_PACK
	movl	%edi, (%esi,%ecx,4)
	vpextrd	$1, %xmm7, %ebp
	vpextrd	$1, %xmm5, %edi
	vpextrd	$1, %xmm4, %eax
	L2S_GATHER_PACK
	movl	%edi, 4(%esi,%ecx,4)
	vpextrd	$2, %xmm7, %ebp
	vpextrd	$2, %xmm5, %edi
	vpextrd	$2, %xmm4, %eax
	L2S_GATHER_PACK
	movl	%edi, 8(%esi,%ecx,4)
	vpextrd	$3, %xmm7, %ebp
	vpextrd	$3, %xmm5, %edi
	vpextrd	$3, %xmm4, %eax
	L2S_GATHER_PACK
	movl	%edi, 12(%esi,%ecx,4)
	vmovd	%xmm3, %ebp
	vmovd	%xmm0, %edi
	vmovd	%xmm6, %eax
	L2S_GATHER_PACK
	movl	%edi, 16(%esi,%ecx,4)
	vpextrd	$1, %xmm3, %ebp
	vpextrd	$1, %xmm0, %edi
	vpextrd	$1, %xmm6, %eax
	L2S_GATHER_PACK
	movl	%edi, 20(%esi,%ecx,4)
	vpextrd	$2, %xmm3, %ebp
	vpextrd	$2, %xmm0, %edi
	vpextrd	$2, %xmm6, %eax
	L2S_GATHER_PACK
	movl	%edi, 24(%esi,%ecx,4)
	vpextrd	$3, %xmm3, %ebp
	vpextrd	$3, %xmm0, %edx
	vpextrd	$3, %xmm6, %edi
	# Now use ebp, edx, edi for the last pixel components.
	# But edx was used as l2s pointer! Reload it.
	movl	ksvg_linear_to_srgb_lut@GOT(%ebx), %eax
	movzbl	(%eax,%ebp), %ebp
	movzbl	(%eax,%edx), %edx
	movzbl	(%eax,%edi), %edi
	jmp	.LBB1_5
.LBB1_6:
	vzeroupper
	addl	$556, %esp
	popl	%esi
	popl	%edi
	popl	%ebx
	popl	%ebp
	retl
.Lfunc_end1:
	SIZE(SYM(ksvgLightingPointDiffuseRowAvx2Linear))
	CFI_END
	IDENT("clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)")
GNU_STACK
ADDRSIG
