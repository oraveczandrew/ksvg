#include "asm_macros.S"
#include "lighting_x86_64_avx2_macros.S"

/*
 * Description:
 *   Scalar L2S gather + force-alpha byte pack, matching the point-diffuse
 *   linear path. Gathers three bytes from \lut (one per channel) and packs
 *   (R << 16) | (G << 8) | B | 0xFF000000 (full alpha).
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
    movzbl  (\lut,\ri), \ro
    movzbl  (\lut,\gi), \go
    movzbl  (\lut,\bi), \bo
    shll    $16, \ro
    shll    $8, \go
    orl     \ro, \go
    orl     \bo, \go
    orl     $-16777216, \go
.endm

	.text
	.file	"pd_av.c"
LIT16
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
LIT4
	.p2align	2, 0x0
.LCPI0_2:
	.long	0x80000000                      # float -0
.LCPI0_3:
	.long	0x3f800000                      # float 1
.LCPI0_4:
	.long	255                             # 0xff
.LCPI0_5:
	.long	4278190080                      # 0xff000000
RODATA32
	.p2align	5, 0x0
.Lpoint_half:
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.text
	.globl	SYM(ksvgLightingPointDiffuseRowAvx2)
	.p2align	4, 0x90
	TYPE(SYM(ksvgLightingPointDiffuseRowAvx2), @function)
SYM(ksvgLightingPointDiffuseRowAvx2):        # @ksvgLightingPointDiffuseRowAvx2
	CFI_START
# %bb.0:
	testl	%r8d, %r8d
	jle	.LBB0_4
# %bb.1:
	subq	$168, %rsp
	CFI_DEF_CFA_OFFSET(176)
	vmovss	16(%r9), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	vmovss	40(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	vmovss	%xmm1, -116(%rsp)               # 4-byte Spill
	vbroadcastss	48(%r9), %xmm4
	vbroadcastss	36(%r9), %ymm2
	vbroadcastss	(%r9), %ymm1
	vmovups	%ymm1, 128(%rsp)                # 32-byte Spill
	vbroadcastss	4(%r9), %ymm1
	vmovups	%ymm1, 96(%rsp)                 # 32-byte Spill
	vxorps	%xmm1, %xmm1, %xmm1
	vblendps	$2, %xmm4, %xmm1, %xmm1         # xmm1 = xmm1[0],xmm4[1],xmm1[2,3]
	vmulps	.LCPI0_0(%rip), %xmm4, %xmm3
	vpermpd	$208, %ymm3, %ymm3              # ymm3 = ymm3[0,0,1,3]
	vblendps	$3, %ymm1, %ymm3, %ymm1         # ymm1 = ymm1[0,1],ymm3[2,3,4,5,6,7]
	vmovaps	%xmm4, -112(%rsp)               # 16-byte Spill
	vmulps	.LCPI0_1(%rip), %xmm4, %xmm4
	vinsertf128	$1, %xmm4, %ymm3, %ymm3
	vshufpd	$2, %ymm3, %ymm1, %ymm1         # ymm1 = ymm1[0],ymm3[1],ymm1[2],ymm3[2]
	vmovupd	%ymm1, 64(%rsp)                 # 32-byte Spill
	vbroadcastss	12(%r9), %ymm1
	vmovups	%ymm1, 32(%rsp)                 # 32-byte Spill
	vsubss	44(%r9), %xmm0, %xmm0
	vbroadcastss	%xmm0, %ymm1
	vmovups	%ymm1, (%rsp)                   # 32-byte Spill
	vbroadcastss	20(%r9), %ymm1
	vmovups	%ymm1, -32(%rsp)                # 32-byte Spill
	vmulss	%xmm0, %xmm0, %xmm0
	vbroadcastss	8(%r9), %ymm1
	vmovups	%ymm1, -64(%rsp)                # 32-byte Spill
	vpbroadcastd	24(%r9), %ymm1
	vmovdqu	%ymm1, -96(%rsp)                # 32-byte Spill
	vbroadcastss	28(%r9), %ymm11
	vbroadcastss	32(%r9), %ymm12
	vbroadcastss	%xmm0, %ymm13
	movl	%r8d, %eax
	vbroadcastss	.LCPI0_2(%rip), %ymm14  # ymm14 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
	xorl	%r8d, %r8d
	vbroadcastss	.LCPI0_3(%rip), %ymm15  # ymm15 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	vxorps	%xmm0, %xmm0, %xmm0
	vpbroadcastd	.LCPI0_4(%rip), %ymm3   # ymm3 = [255,255,255,255,255,255,255,255]
	vpbroadcastd	.LCPI0_5(%rip), %ymm4   # ymm4 = [4278190080,4278190080,4278190080,4278190080,4278190080,4278190080,4278190080,4278190080]
	.p2align	4, 0x90
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	vxorps	%xmm7, %xmm7, %xmm7
	vcvtsi2ss	%r8d, %xmm7, %xmm5
	vmovdqu	(%rdi,%r8,4), %ymm1
	vmovdqu	8(%rdi,%r8,4), %ymm7
	ALPHA_FSCALE %ymm1, %ymm1, %ymm2, %ymm6
	ALPHA_FSCALE %ymm7, %ymm1, %ymm2, %ymm1
	vmovdqu	(%rsi,%r8,4), %ymm7
	vmovdqu	8(%rsi,%r8,4), %ymm8
	ALPHA_FSCALE %ymm7, %ymm7, %ymm2, %ymm7
	ALPHA_FSCALE %ymm8, %ymm8, %ymm2, %ymm8
	vmovdqu	(%rdx,%r8,4), %ymm9
	vaddps	%ymm1, %ymm8, %ymm10
	vaddps	%ymm10, %ymm8, %ymm8
	vaddps	%ymm7, %ymm6, %ymm10
	vaddps	%ymm7, %ymm10, %ymm7
	vmovdqu	8(%rdx,%r8,4), %ymm10
	ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9
	ALPHA_FSCALE %ymm10, %ymm10, %ymm2, %ymm10
	vaddps	%ymm10, %ymm8, %ymm8
	vaddps	%ymm7, %ymm9, %ymm7
	vsubps	%ymm7, %ymm8, %ymm7
	vmovdqu	4(%rdx,%r8,4), %ymm8
	ALPHA_FSCALE %ymm8, %ymm8, %ymm2, %ymm8
	vaddps	%ymm8, %ymm9, %ymm9
	vaddps	%ymm9, %ymm8, %ymm8
	vmovdqu	4(%rdi,%r8,4), %ymm9
	ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9
	vaddps	%ymm8, %ymm10, %ymm8
	vaddps	%ymm6, %ymm9, %ymm6
	vaddps	%ymm6, %ymm9, %ymm6
	vmovdqu	4(%rsi,%r8,4), %ymm9
	ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9
	vaddps	%ymm6, %ymm1, %ymm1
	vsubps	%ymm1, %ymm8, %ymm1
	vxorps	%ymm7, %ymm14, %ymm6
	vdivps	128(%rsp), %ymm6, %ymm6         # 32-byte Folded Reload
	vxorps	%ymm1, %ymm14, %ymm1
	vdivps	96(%rsp), %ymm1, %ymm1          # 32-byte Folded Reload
	vmulss	-112(%rsp), %xmm5, %xmm5        # 16-byte Folded Reload
	vmulps	%ymm1, %ymm1, %ymm7
	vmulps	%ymm6, %ymm6, %ymm8
	vaddps	%ymm7, %ymm8, %ymm7
	vaddps	%ymm7, %ymm15, %ymm7
	vsqrtps	%ymm7, %ymm7
	vaddss	-116(%rsp), %xmm5, %xmm5        # 4-byte Folded Reload
	vdivps	%ymm7, %ymm15, %ymm7
	vmulps	%ymm7, %ymm6, %ymm6
	vbroadcastss	%xmm5, %ymm5
	vaddps	64(%rsp), %ymm5, %ymm5          # 32-byte Folded Reload
	vmovups	32(%rsp), %ymm8                 # 32-byte Reload
	vsubps	%ymm5, %ymm8, %ymm5
	vmovups	-32(%rsp), %ymm8                # 32-byte Reload
	vsubps	%ymm9, %ymm8, %ymm8
	vmulps	%ymm5, %ymm5, %ymm9
	vaddps	%ymm13, %ymm9, %ymm9
	vmulps	%ymm8, %ymm8, %ymm10
	vaddps	%ymm9, %ymm10, %ymm9
	vsqrtps	%ymm9, %ymm10
	vdivps	%ymm10, %ymm15, %ymm10
	vmulps	%ymm5, %ymm10, %ymm5
	vcmpneqps	%ymm0, %ymm9, %ymm9
	vandps	%ymm5, %ymm9, %ymm5
	vmulps	%ymm5, %ymm6, %ymm5
	vmulps	%ymm7, %ymm1, %ymm1
	vmulps	%ymm10, %ymm8, %ymm6
	vmulps	(%rsp), %ymm10, %ymm8           # 32-byte Folded Reload
	vandps	%ymm8, %ymm9, %ymm8
	vmulps	%ymm1, %ymm8, %ymm1
	vaddps	%ymm1, %ymm5, %ymm1
	vandps	%ymm6, %ymm9, %ymm5
	vmulps	%ymm5, %ymm7, %ymm5
	vaddps	%ymm1, %ymm5, %ymm1
	vmaxps	%ymm0, %ymm1, %ymm1
	vmulps	-64(%rsp), %ymm1, %ymm1         # 32-byte Folded Reload
	vmaxps	%ymm0, %ymm1, %ymm1
	vminps	%ymm15, %ymm1, %ymm1
	vmulps	-96(%rsp), %ymm1, %ymm5         # 32-byte Folded Reload
	vaddps	.Lpoint_half(%rip), %ymm5, %ymm5 # round-half-up R
	vcvttps2dq	%ymm5, %ymm5
	vpmaxsd	%ymm0, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm5, %ymm5
	vmulps	%ymm1, %ymm11, %ymm6
	vaddps	.Lpoint_half(%rip), %ymm6, %ymm6 # round-half-up G
	vcvttps2dq	%ymm6, %ymm6
	vpmaxsd	%ymm0, %ymm6, %ymm6
	vpminsd	%ymm3, %ymm6, %ymm6
	vpslld	$16, %ymm5, %ymm5
	vpslld	$8, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmulps	%ymm1, %ymm12, %ymm1
	vaddps	.Lpoint_half(%rip), %ymm1, %ymm1 # round-half-up B
	vcvttps2dq	%ymm1, %ymm1
	vpmaxsd	%ymm0, %ymm1, %ymm1
	vpminsd	%ymm3, %ymm1, %ymm1
	vpor	%ymm4, %ymm1, %ymm1
	vpor	%ymm1, %ymm5, %ymm1
	vmovdqu	%ymm1, (%rcx,%r8,4)
	addq	$8, %r8
	cmpq	%rax, %r8
	jb	.LBB0_2
# %bb.3:
	addq	$168, %rsp
	CFI_DEF_CFA_OFFSET(8)
.LBB0_4:
	vzeroupper
	retq
.Lfunc_end0:
	CFI_END
                                        # -- End function
LIT16
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
LIT4
	.p2align	2, 0x0
.LCPI1_2:
	.long	0x80000000                      # float -0
.LCPI1_3:
	.long	0x3f800000                      # float 1
.LCPI1_4:
	.long	255                             # 0xff
.LCPI1_5:
	.long	4278190080                      # 0xff000000
	.text
	.globl	SYM(ksvgLightingPointDiffuseRowAvx2Linear)
	.p2align	4, 0x90
	TYPE(SYM(ksvgLightingPointDiffuseRowAvx2Linear), @function)
SYM(ksvgLightingPointDiffuseRowAvx2Linear):  # @ksvgLightingPointDiffuseRowAvx2Linear
	CFI_START
# %bb.0:
	testl	%r8d, %r8d
	jle	.LBB1_7
# %bb.1:
	pushq	%r14
	CFI_DEF_CFA_OFFSET(16)
	pushq	%rbx
	CFI_DEF_CFA_OFFSET(24)
	subq	$152, %rsp
	CFI_DEF_CFA_OFFSET(176)
	CFI_OFFSET(%rbx, -24)
	CFI_OFFSET(%r14, -16)
	movq	176(%rsp), %rax
	vmovss	16(%r9), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	vmovss	40(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	vmovss	%xmm1, -116(%rsp)               # 4-byte Spill
	vbroadcastss	48(%r9), %xmm1
	vbroadcastss	36(%r9), %ymm2
	vbroadcastss	(%r9), %ymm3
	vmovups	%ymm3, 112(%rsp)                # 32-byte Spill
	vbroadcastss	4(%r9), %ymm3
	vmovups	%ymm3, 80(%rsp)                 # 32-byte Spill
	vxorps	%xmm3, %xmm3, %xmm3
	vblendps	$2, %xmm1, %xmm3, %xmm3         # xmm3 = xmm3[0],xmm1[1],xmm3[2,3]
	vmulps	.LCPI1_0(%rip), %xmm1, %xmm4
	vpermpd	$208, %ymm4, %ymm4              # ymm4 = ymm4[0,0,1,3]
	vblendps	$3, %ymm3, %ymm4, %ymm3         # ymm3 = ymm3[0,1],ymm4[2,3,4,5,6,7]
	vmulps	.LCPI1_1(%rip), %xmm1, %xmm5
	vinsertf128	$1, %xmm5, %ymm4, %ymm4
	vshufpd	$2, %ymm4, %ymm3, %ymm3         # ymm3 = ymm3[0],ymm4[1],ymm3[2],ymm4[2]
	vmovupd	%ymm3, 48(%rsp)                 # 32-byte Spill
	vbroadcastss	12(%r9), %ymm3
	vmovups	%ymm3, 16(%rsp)                 # 32-byte Spill
	vsubss	44(%r9), %xmm0, %xmm0
	vbroadcastss	20(%r9), %ymm3
	vmovups	%ymm3, -16(%rsp)                # 32-byte Spill
	vbroadcastss	%xmm0, %ymm3
	vmovups	%ymm3, -48(%rsp)                # 32-byte Spill
	vmulss	%xmm0, %xmm0, %xmm0
	vbroadcastss	8(%r9), %ymm3
	vmovups	%ymm3, -80(%rsp)                # 32-byte Spill
	vbroadcastss	24(%r9), %ymm3
	vmovups	%ymm3, -112(%rsp)               # 32-byte Spill
	vbroadcastss	28(%r9), %ymm11
	vbroadcastss	%xmm0, %ymm12
	vbroadcastss	32(%r9), %ymm13
	movl	%r8d, %r8d
	vbroadcastss	.LCPI1_2(%rip), %ymm14  # ymm14 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
	vbroadcastss	.LCPI1_3(%rip), %ymm15  # ymm15 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	xorl	%r9d, %r9d
	vxorps	%xmm0, %xmm0, %xmm0
	vpbroadcastd	.LCPI1_4(%rip), %ymm3   # ymm3 = [255,255,255,255,255,255,255,255]
	jmp	.LBB1_2
	.p2align	4, 0x90
.LBB1_4:                                #   in Loop: Header=BB1_2 Depth=1
	vpslld	$16, %xmm7, %xmm7
	vpslld	$8, %xmm9, %xmm9
	vpor	%xmm7, %xmm9, %xmm7
	vpbroadcastd	.LCPI1_5(%rip), %xmm9   # xmm9 = [4278190080,4278190080,4278190080,4278190080]
	vpor	%xmm9, %xmm8, %xmm8
	vpor	%xmm7, %xmm8, %xmm7
	vmovdqu	%xmm7, (%rcx,%r9,4)
	vpslld	$16, %xmm6, %xmm7
	vpslld	$8, %xmm5, %xmm8
	vpor	%xmm7, %xmm8, %xmm7
	vpor	%xmm4, %xmm9, %xmm8
	vpor	%xmm7, %xmm8, %xmm7
	vpextrd	$2, %xmm6, %r10d
	vpextrd	$2, %xmm5, %r11d
	vpextrd	$2, %xmm4, %ebx
	vmovq	%xmm7, 16(%rcx,%r9,4)
	shll	$16, %r10d
	shll	$8, %r11d
	orl	%r10d, %r11d
	leal	(%rbx,%r11), %r10d
	addl	$-16777216, %r10d               # imm = 0xFF000000
	movl	%r10d, 24(%rcx,%r9,4)
	vpextrd	$3, %xmm6, %r11d
	vpextrd	$3, %xmm5, %r10d
	vpextrd	$3, %xmm4, %ebx
.LBB1_5:                                #   in Loop: Header=BB1_2 Depth=1
	shll	$16, %r11d
	shll	$8, %r10d
	orl	%r11d, %r10d
	addl	%ebx, %r10d
	addl	$-16777216, %r10d               # imm = 0xFF000000
	movl	%r10d, 28(%rcx,%r9,4)
	addq	$8, %r9
	cmpq	%r8, %r9
	jae	.LBB1_6
.LBB1_2:                                # =>This Inner Loop Header: Depth=1
	vxorps	%xmm10, %xmm10, %xmm10
	vcvtsi2ss	%r9d, %xmm10, %xmm4
	vmovdqu	(%rdi,%r9,4), %ymm5
	vmovdqu	8(%rdi,%r9,4), %ymm6
	ALPHA_FSCALE %ymm5, %ymm5, %ymm2, %ymm5
	ALPHA_FSCALE %ymm6, %ymm6, %ymm2, %ymm6
	vmovdqu	(%rsi,%r9,4), %ymm7
	vmovdqu	8(%rsi,%r9,4), %ymm8
	ALPHA_FSCALE %ymm7, %ymm7, %ymm2, %ymm7
	ALPHA_FSCALE %ymm8, %ymm8, %ymm2, %ymm8
	vmovdqu	(%rdx,%r9,4), %ymm9
	vaddps	%ymm6, %ymm8, %ymm10
	vaddps	%ymm10, %ymm8, %ymm8
	vaddps	%ymm7, %ymm5, %ymm10
	vaddps	%ymm7, %ymm10, %ymm7
	vmovdqu	8(%rdx,%r9,4), %ymm10
	ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9
	ALPHA_FSCALE %ymm10, %ymm10, %ymm2, %ymm10
	vaddps	%ymm10, %ymm8, %ymm8
	vaddps	%ymm7, %ymm9, %ymm7
	vsubps	%ymm7, %ymm8, %ymm7
	vmovdqu	4(%rdx,%r9,4), %ymm8
	ALPHA_FSCALE %ymm8, %ymm8, %ymm2, %ymm8
	vaddps	%ymm8, %ymm9, %ymm9
	vaddps	%ymm9, %ymm8, %ymm8
	vmovdqu	4(%rdi,%r9,4), %ymm9
	ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9
	vaddps	%ymm8, %ymm10, %ymm8
	vaddps	%ymm5, %ymm9, %ymm5
	vaddps	%ymm5, %ymm9, %ymm5
	vmovdqu	4(%rsi,%r9,4), %ymm9
	ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9
	vaddps	%ymm5, %ymm6, %ymm5
	vsubps	%ymm5, %ymm8, %ymm5
	vxorps	%ymm7, %ymm14, %ymm6
	vdivps	112(%rsp), %ymm6, %ymm6         # 32-byte Folded Reload
	vxorps	%ymm5, %ymm14, %ymm5
	vdivps	80(%rsp), %ymm5, %ymm5          # 32-byte Folded Reload
	vmulss	%xmm1, %xmm4, %xmm4
	vmulps	%ymm5, %ymm5, %ymm7
	vmulps	%ymm6, %ymm6, %ymm8
	vaddps	%ymm7, %ymm8, %ymm7
	vaddps	%ymm7, %ymm15, %ymm7
	vsqrtps	%ymm7, %ymm7
	vaddss	-116(%rsp), %xmm4, %xmm4        # 4-byte Folded Reload
	vdivps	%ymm7, %ymm15, %ymm7
	vmulps	%ymm7, %ymm6, %ymm6
	vbroadcastss	%xmm4, %ymm4
	vaddps	48(%rsp), %ymm4, %ymm4          # 32-byte Folded Reload
	vmovups	16(%rsp), %ymm8                 # 32-byte Reload
	vsubps	%ymm4, %ymm8, %ymm4
	vmovups	-16(%rsp), %ymm8                # 32-byte Reload
	vsubps	%ymm9, %ymm8, %ymm8
	vmulps	%ymm4, %ymm4, %ymm9
	vaddps	%ymm12, %ymm9, %ymm9
	vmulps	%ymm8, %ymm8, %ymm10
	vaddps	%ymm9, %ymm10, %ymm9
	vsqrtps	%ymm9, %ymm10
	vdivps	%ymm10, %ymm15, %ymm10
	vmulps	%ymm4, %ymm10, %ymm4
	vcmpneqps	%ymm0, %ymm9, %ymm9
	vandps	%ymm4, %ymm9, %ymm4
	vmulps	%ymm4, %ymm6, %ymm4
	vmulps	%ymm7, %ymm5, %ymm5
	vmulps	%ymm10, %ymm8, %ymm6
	vmulps	-48(%rsp), %ymm10, %ymm8        # 32-byte Folded Reload
	vandps	%ymm8, %ymm9, %ymm8
	vmulps	%ymm5, %ymm8, %ymm5
	vaddps	%ymm5, %ymm4, %ymm4
	vandps	%ymm6, %ymm9, %ymm5
	vmulps	%ymm5, %ymm7, %ymm5
	vaddps	%ymm4, %ymm5, %ymm4
	vmaxps	%ymm0, %ymm4, %ymm4
	vmulps	-80(%rsp), %ymm4, %ymm4         # 32-byte Folded Reload
	vmaxps	%ymm0, %ymm4, %ymm4
	vminps	%ymm15, %ymm4, %ymm4
	vmulps	-112(%rsp), %ymm4, %ymm5        # 32-byte Folded Reload
	vaddps	.Lpoint_half(%rip), %ymm5, %ymm5 # round-half-up R
	vcvttps2dq	%ymm5, %ymm5
	vpmaxsd	%ymm0, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm5, %ymm7
	vmulps	%ymm4, %ymm11, %ymm5
	vaddps	.Lpoint_half(%rip), %ymm5, %ymm5 # round-half-up G
	vcvttps2dq	%ymm5, %ymm5
	vpmaxsd	%ymm0, %ymm5, %ymm5
	vpminsd	%ymm3, %ymm5, %ymm9
	vmulps	%ymm4, %ymm13, %ymm4
	vaddps	.Lpoint_half(%rip), %ymm4, %ymm4 # round-half-up B
	vcvttps2dq	%ymm4, %ymm4
	vpmaxsd	%ymm0, %ymm4, %ymm4
	vpminsd	%ymm3, %ymm4, %ymm8
	vextracti128	$1, %ymm7, %xmm6
	vextracti128	$1, %ymm9, %xmm5
	vextracti128	$1, %ymm8, %xmm4
	testq	%rax, %rax
	je	.LBB1_4
# %bb.3:                                #   in Loop: Header=BB1_2 Depth=1
	vmovd	%xmm8, %r10d
	vmovd	%xmm9, %r11d
	vmovd	%xmm7, %ebx
	L2S_GATHER_PACK %rax, %rbx, %ebx, %r11, %r11d, %r10, %r10d
	movl	%r11d, (%rcx,%r9,4)
	vpextrd	$1, %xmm7, %r10d
	vpextrd	$1, %xmm9, %r11d
	vpextrd	$1, %xmm8, %ebx
	L2S_GATHER_PACK %rax, %r10, %r10d, %r11, %r11d, %rbx, %ebx
	vpextrd	$2, %xmm7, %r10d
	vpextrd	$2, %xmm9, %ebx
	vpextrd	$2, %xmm8, %r14d
	movl	%r11d, 4(%rcx,%r9,4)
	L2S_GATHER_PACK %rax, %r10, %r10d, %rbx, %r11d, %r14, %ebx
	movl	%r11d, 8(%rcx,%r9,4)
	vpextrd	$3, %xmm7, %r10d
	vpextrd	$3, %xmm9, %r11d
	vpextrd	$3, %xmm8, %ebx
	L2S_GATHER_PACK %rax, %r10, %r10d, %r11, %r11d, %rbx, %ebx
	movl	%r11d, 12(%rcx,%r9,4)
	vmovd	%xmm6, %r10d
	vmovd	%xmm5, %r11d
	vmovd	%xmm4, %ebx
	L2S_GATHER_PACK %rax, %r10, %r10d, %r11, %r11d, %rbx, %ebx
	vpextrd	$1, %xmm6, %r10d
	vpextrd	$1, %xmm5, %ebx
	movl	%r11d, 16(%rcx,%r9,4)
	vpextrd	$1, %xmm4, %r11d
	L2S_GATHER_PACK %rax, %r10, %r10d, %rbx, %ebx, %r11, %r11d
	movl	%ebx, 20(%rcx,%r9,4)
	vpextrd	$2, %xmm6, %r10d
	vpextrd	$2, %xmm5, %r11d
	vpextrd	$2, %xmm4, %ebx
	L2S_GATHER_PACK %rax, %r10, %r10d, %r11, %r11d, %rbx, %ebx
	vpextrd	$3, %xmm6, %r10d
	vpextrd	$3, %xmm5, %ebx
	vpextrd	$3, %xmm4, %r14d
	movl	%r11d, 24(%rcx,%r9,4)
	movzbl	(%rax,%r10), %r11d
	movzbl	(%rax,%rbx), %r10d
	movzbl	(%rax,%r14), %ebx
	jmp	.LBB1_5
.LBB1_6:
	addq	$152, %rsp
	CFI_DEF_CFA_OFFSET(24)
	popq	%rbx
	CFI_DEF_CFA_OFFSET(16)
	popq	%r14
	CFI_DEF_CFA_OFFSET(8)
	CFI_RESTORE(%rbx)
	CFI_RESTORE(%r14)
.LBB1_7:
	vzeroupper
	retq
.Lfunc_end1:
	CFI_END
                                        # -- End function
GNU_STACK
