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
#include "lighting_x86_64_avx2_macros.S"

/*
 * Description:
 *   Scalar L2S gather + max-channel-alpha byte pack, matching the
 *   point-specular scalar path (LUT != NULL) bit-for-bit. Gathers three bytes
 *   from \lut: lane 1 of \xmm, lane 0 of \xmm, and the scalar index \scl,
 *   then computes alpha = max(R, G, B) with unsigned cmovs (cmoval/cmovbel)
 *   and packs: (max << 24) | (R << 16) | (G << 8) | B.
 *
 * Inputs:
 *   \lut        = base of the L2S table (e.g. %r14)
 *   \xmm        = XMM register holding per-lane packed indices (lanes 0/1)
 *   \lane1q, \lane1d = 64-bit index view / 32-bit value view of the lane-1 reg
 *   \lane0q, \lane0d = same pair for the lane-0 reg (holds the packed result)
 *   \sclq, \scld     = same pair for the scalar-index reg
 *   \tmp        = scratch 32-bit GPR (alpha)
 *
 * Output:
 *   \lane0d     = packed 0xAARRGGBB pixel
 *
 * Clobbers:
 *   \lane1d, \lane0d, \scld, \tmp
 *   Upper 32 bits of the 64-bit registers are untouched.
 */
.macro L2S_GATHER_CMOV_PACK lut, xmm, lane1q, lane1d, lane0q, lane0d, sclq, scld, tmp
    vpextrd $1, \xmm, \lane1d
    movzbl  (\lut,\lane1q), \lane1d
    vmovd   \xmm, \lane0d
    movzbl  (\lut,\lane0q), \lane0d
    movzbl  (\lut,\sclq), \scld
    cmpl    \lane0d, \lane1d
    movl    \lane0d, \tmp
    cmoval  \lane1d, \tmp
    cmpl    \scld, \tmp
    cmovbel \scld, \tmp
    shll    $24, \tmp
    shll    $16, \lane1d
    shll    $8, \lane0d
    orl     \lane1d, \lane0d
    orl     \tmp, \lane0d
    orl     \scld, \lane0d
.endm

	.globl SYM(ksvgLightingPointSpecularRowAvx2) ## -- Begin function ksvgLightingPointSpecularRowAvx2
	.p2align	4, 0x90
SYM(ksvgLightingPointSpecularRowAvx2):      ## @ksvgLightingPointSpecularRowAvx2
	.cfi_startproc
## %bb.0:
	testl	%r8d, %r8d
	jle	LBB0_4
## %bb.1:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$72, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	%rcx, %r15
	movq	%rdx, %r12
	movq	%rsi, %r13
	movq	%rdi, %r14
	xorl	%ebx, %ebx
	vmovss	%xmm0, -48(%rbp)                ## 4-byte Spill
	movq	%r9, -56(%rbp)                  ## 8-byte Spill
	movl	%r8d, -44(%rbp)                 ## 4-byte Spill
	.p2align	4, 0x90
LBB0_2:                                 ## =>This Inner Loop Header: Depth=1
	vmovups	(%r9), %ymm3
	vmovups	20(%r9), %ymm1
	vcvtsi2ss	%ebx, %xmm4, %xmm2
	vmovups	%ymm1, -92(%rbp)
	vmovups	%ymm3, -112(%rbp)
	vmulss	48(%r9), %xmm2, %xmm1
	vaddss	40(%r9), %xmm1, %xmm1
	vmovss	%xmm1, -72(%rbp)
	movq	%r14, %rdi
	movq	%r13, %rsi
	movq	%r12, %rdx
	movq	%r15, %rcx
	leaq	-112(%rbp), %r8
	xorl	%r9d, %r9d
	vzeroupper
	callq	SYM(core8)
	movl	-44(%rbp), %r8d                 ## 4-byte Reload
	movq	-56(%rbp), %r9                  ## 8-byte Reload
	vmovss	-48(%rbp), %xmm0                ## 4-byte Reload
                                        ## xmm0 = mem[0],zero,zero,zero
	addq	$32, %r15
	addq	$32, %r12
	addq	$32, %r13
	addq	$32, %r14
	addl	$8, %ebx
	cmpl	%r8d, %ebx
	jl	LBB0_2
## %bb.3:
	addq	$72, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
LBB0_4:
	retq
	.cfi_endproc
                                        ## -- End function
POINT_LIT4
	.p2align	2, 0x0                          ## -- Begin function core8
LCPI1_0:
	.long	0x3f800000                      ## float 1
LCPI1_2:
	.long	255                             ## 0xff
LCPI1_5:
	.long	0x00000000                      ## float 0
POINT_CONST
	.p2align	5, 0x0
LCPI1_1:
	.long	0x00000000                      ## float 0
	.long	0x3f800000                      ## float 1
	.long	0x40000000                      ## float 2
	.long	0x40400000                      ## float 3
	.long	0x40800000                      ## float 4
	.long	0x40a00000                      ## float 5
	.long	0x40c00000                      ## float 6
	.long	0x40e00000                      ## float 7
LCPI1_6:
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
	.long	0x3f000000                      ## float 0.5
LCPI1_3:
	.long	8                               ## 0x8
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.long	16                              ## 0x10
LCPI1_4:
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.long	16                              ## 0x10
	.long	8                               ## 0x8
	.long	16                              ## 0x10
	.long	8                               ## 0x8
POINT_TEXT
	.p2align	4, 0x90
SYM(core8):                                 ## @core8
	.cfi_startproc
## %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%rbx
	andq	$-32, %rsp
	subq	$288, %rsp                      ## imm = 0x120
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	%r8, %r15
	vbroadcastss	36(%r8), %ymm1
	vbroadcastss	(%r8), %ymm4
	vbroadcastss	4(%r8), %ymm2
	vmovdqu	(%rdi), %ymm3
	vmovdqu	4(%rdi), %ymm5
	vmovdqu	8(%rdi), %ymm6
	ALPHA_FSCALE %ymm3, %ymm3, %ymm1, %ymm3
	ALPHA_FSCALE %ymm5, %ymm5, %ymm1, %ymm5
	ALPHA_FSCALE %ymm6, %ymm6, %ymm1, %ymm6
	vmovdqu	(%rsi), %ymm7
	vmovdqu	8(%rsi), %ymm8
	ALPHA_FSCALE %ymm7, %ymm7, %ymm1, %ymm7
	ALPHA_FSCALE %ymm8, %ymm8, %ymm1, %ymm8
	vmovdqu	(%rdx), %ymm9
	vmovdqu	4(%rdx), %ymm10
	vmovdqu	8(%rdx), %ymm11
	ALPHA_FSCALE %ymm9, %ymm9, %ymm1, %ymm9
	vpsrld	$24, %ymm10, %ymm10
	vpsrld	$24, %ymm11, %ymm11
	vcvtdq2ps	%ymm11, %ymm11
	vmulps	%ymm1, %ymm11, %ymm11
	vaddps	%ymm6, %ymm8, %ymm12
	vaddps	%ymm11, %ymm8, %ymm8
	vaddps	%ymm8, %ymm12, %ymm8
	vaddps	%ymm7, %ymm9, %ymm12
	vaddps	%ymm7, %ymm12, %ymm7
	vaddps	%ymm7, %ymm3, %ymm7
	vsubps	%ymm7, %ymm8, %ymm7
	vdivps	%ymm4, %ymm7, %ymm4
	vcvtdq2ps	%ymm10, %ymm7
	vmulps	%ymm7, %ymm1, %ymm7
	vaddps	%ymm7, %ymm9, %ymm8
	vaddps	%ymm7, %ymm11, %ymm7
	vaddps	%ymm7, %ymm8, %ymm7
	vaddps	%ymm6, %ymm5, %ymm6
	vaddps	%ymm6, %ymm5, %ymm5
	vaddps	%ymm5, %ymm3, %ymm3
	vsubps	%ymm3, %ymm7, %ymm3
	vdivps	%ymm2, %ymm3, %ymm3
	vxorps	%xmm2, %xmm2, %xmm2
	vsubps	%ymm4, %ymm2, %ymm4
	vsubps	%ymm3, %ymm2, %ymm3
	vmulps	%ymm4, %ymm4, %ymm5
	vmulps	%ymm3, %ymm3, %ymm6
	vaddps	%ymm6, %ymm5, %ymm6
	vbroadcastss	LCPI1_0(%rip), %ymm5    ## ymm5 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	vaddps	%ymm5, %ymm6, %ymm6
	vsqrtps	%ymm6, %ymm7
	vdivps	%ymm7, %ymm4, %ymm6
	vdivps	%ymm7, %ymm3, %ymm4
	movq	%r9, %r14
	vdivps	%ymm7, %ymm5, %ymm3
	vmovss	%xmm0, 16(%rsp)                 ## 4-byte Spill
	movq	%rcx, %rbx
	vbroadcastss	40(%r8), %ymm0
	vbroadcastss	48(%r8), %ymm7
	vmulps	LCPI1_1(%rip), %ymm7, %ymm7
	vmovdqu	4(%rsi), %ymm8
	vaddps	%ymm7, %ymm0, %ymm0
	vbroadcastss	12(%r8), %ymm7
	vsubps	%ymm0, %ymm7, %ymm0
	vmovss	16(%r8), %xmm7                  ## xmm7 = mem[0],zero,zero,zero
	vsubss	44(%r8), %xmm7, %xmm7
	vbroadcastss	%xmm7, %ymm9
	vbroadcastss	20(%r8), %ymm10
	ALPHA_FSCALE %ymm8, %ymm8, %ymm1, %ymm1
	vsubps	%ymm1, %ymm10, %ymm1
	vmulps	%ymm0, %ymm0, %ymm8
	vmulss	%xmm7, %xmm7, %xmm7
	vbroadcastss	%xmm7, %ymm7
	vaddps	%ymm7, %ymm8, %ymm7
	vmulps	%ymm1, %ymm1, %ymm8
	vaddps	%ymm7, %ymm8, %ymm7
	vsqrtps	%ymm7, %ymm10
	vcmpneq_oqps	%ymm2, %ymm10, %ymm7
	vdivps	%ymm10, %ymm0, %ymm0
	vandps	%ymm0, %ymm7, %ymm0
	vdivps	%ymm10, %ymm9, %ymm9
	vandps	%ymm9, %ymm7, %ymm9
	vdivps	%ymm10, %ymm1, %ymm1
	vandps	%ymm1, %ymm7, %ymm1
	vaddps	%ymm5, %ymm1, %ymm1
	vblendvps	%ymm7, %ymm1, %ymm5, %ymm1
	vmulps	%ymm0, %ymm0, %ymm7
	vmulps	%ymm9, %ymm9, %ymm8
	vaddps	%ymm7, %ymm8, %ymm7
	vmulps	%ymm1, %ymm1, %ymm8
	vaddps	%ymm7, %ymm8, %ymm7
	vsqrtps	%ymm7, %ymm7
	vcmpneq_oqps	%ymm2, %ymm7, %ymm8
	vdivps	%ymm7, %ymm0, %ymm0
	vandps	%ymm0, %ymm8, %ymm0
	vmulps	%ymm0, %ymm6, %ymm0
	vdivps	%ymm7, %ymm9, %ymm6
	vandps	%ymm6, %ymm8, %ymm6
	vmulps	%ymm6, %ymm4, %ymm4
	vaddps	%ymm4, %ymm0, %ymm0
	vdivps	%ymm7, %ymm1, %ymm1
	vandps	%ymm1, %ymm8, %ymm1
	vmulps	%ymm1, %ymm3, %ymm1
	vaddps	%ymm0, %ymm1, %ymm0
	vmaxps	%ymm2, %ymm0, %ymm0
	vmovaps	%ymm0, 128(%rsp)                ## 32-byte Spill
	vxorps	%xmm1, %xmm1, %xmm1
	vucomiss	%xmm1, %xmm10
	vxorps	%xmm0, %xmm0, %xmm0
	vmovaps	%ymm10, 160(%rsp)               ## 32-byte Spill
	jne	LBB1_1
	jnp	LBB1_2
LBB1_1:
	vmovaps	128(%rsp), %ymm0                ## 32-byte Reload
                                        ## kill: def $xmm0 killed $xmm0 killed $ymm0
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vzeroupper
	CALL(powf)
	vxorps	%xmm1, %xmm1, %xmm1
	vmovaps	160(%rsp), %ymm10               ## 32-byte Reload
	vmulss	8(%r15), %xmm0, %xmm0
LBB1_2:
	vmovss	%xmm0, 80(%rsp)                 ## 4-byte Spill
	vmovshdup	%xmm10, %xmm0           ## xmm0 = xmm10[1,1,3,3]
	vucomiss	%xmm1, %xmm0
	vxorps	%xmm0, %xmm0, %xmm0
	jne	LBB1_3
	jnp	LBB1_4
LBB1_3:
	vmovshdup	128(%rsp), %xmm0        ## 16-byte Folded Reload
                                        ## xmm0 = mem[1,1,3,3]
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vzeroupper
	CALL(powf)
	vmovaps	160(%rsp), %ymm10               ## 32-byte Reload
	vmulss	8(%r15), %xmm0, %xmm0
LBB1_4:
	vmovss	%xmm0, 64(%rsp)                 ## 4-byte Spill
	vxorps	%xmm4, %xmm4, %xmm4
	vshufpd	$1, %xmm10, %xmm10, %xmm0       ## xmm0 = xmm10[1,0]
	vucomiss	%xmm4, %xmm0
	vxorps	%xmm5, %xmm5, %xmm5
	jne	LBB1_5
	jnp	LBB1_6
LBB1_5:
	vpermilpd	$1, 128(%rsp), %xmm0    ## 16-byte Folded Reload
                                        ## xmm0 = mem[1,0]
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vzeroupper
	CALL(powf)
	vxorps	%xmm4, %xmm4, %xmm4
	vmovaps	160(%rsp), %ymm10               ## 32-byte Reload
	vmulss	8(%r15), %xmm0, %xmm5
LBB1_6:
	vshufps	$255, %xmm10, %xmm10, %xmm0     ## xmm0 = xmm10[3,3,3,3]
	vucomiss	%xmm4, %xmm0
	vxorps	%xmm6, %xmm6, %xmm6
	jne	LBB1_7
	jnp	LBB1_8
LBB1_7:
	vpermilps	$255, 128(%rsp), %xmm0  ## 16-byte Folded Reload
                                        ## xmm0 = mem[3,3,3,3]
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vmovss	%xmm5, 32(%rsp)                 ## 4-byte Spill
	vzeroupper
	CALL(powf)
	vmovss	32(%rsp), %xmm5                 ## 4-byte Reload
                                        ## xmm5 = mem[0],zero,zero,zero
	vxorps	%xmm4, %xmm4, %xmm4
	vmovaps	160(%rsp), %ymm10               ## 32-byte Reload
	vmulss	8(%r15), %xmm0, %xmm6
LBB1_8:
	vmovss	LCPI1_0(%rip), %xmm2            ## xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	vxorps	%xmm7, %xmm7, %xmm7
	vextractf128	$1, %ymm10, %xmm3
	vucomiss	%xmm7, %xmm3
	vxorps	%xmm0, %xmm0, %xmm0
	vmovaps	%xmm3, 160(%rsp)                ## 16-byte Spill
	jne	LBB1_9
	jnp	LBB1_10
LBB1_9:
	vmovaps	128(%rsp), %ymm0                ## 32-byte Reload
	vextractf128	$1, %ymm0, %xmm0
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vmovss	%xmm5, 32(%rsp)                 ## 4-byte Spill
	vmovss	%xmm6, 48(%rsp)                 ## 4-byte Spill
	vzeroupper
	CALL(powf)
	vmovss	48(%rsp), %xmm6                 ## 4-byte Reload
                                        ## xmm6 = mem[0],zero,zero,zero
	vxorps	%xmm7, %xmm7, %xmm7
	vmovss	32(%rsp), %xmm5                 ## 4-byte Reload
                                        ## xmm5 = mem[0],zero,zero,zero
	vxorps	%xmm4, %xmm4, %xmm4
	vmovaps	160(%rsp), %xmm3                ## 16-byte Reload
	vmovss	LCPI1_0(%rip), %xmm2            ## xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	vmulss	8(%r15), %xmm0, %xmm0
LBB1_10:
	vmovss	80(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vminss	%xmm1, %xmm2, %xmm8
	vcmpltss	LCPI1_5(%rip), %xmm1, %xmm9
	vmovss	64(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vminss	%xmm1, %xmm2, %xmm10
	vcmpltss	%xmm4, %xmm1, %xmm1
	vminss	%xmm5, %xmm2, %xmm12
	vcmpltss	%xmm4, %xmm5, %xmm4
	vminss	%xmm6, %xmm2, %xmm5
	vcmpltss	%xmm7, %xmm6, %xmm13
	vminss	%xmm0, %xmm2, %xmm14
	vcmpltss	%xmm7, %xmm0, %xmm15
	vmovshdup	%xmm3, %xmm0            ## xmm0 = xmm3[1,1,3,3]
	vucomiss	%xmm7, %xmm0
	jne	LBB1_11
	jnp	LBB1_12
LBB1_11:
	vmovaps	128(%rsp), %ymm0                ## 32-byte Reload
	vextractf128	$1, %ymm0, %xmm0
	vmovshdup	%xmm0, %xmm0            ## xmm0 = xmm0[1,1,3,3]
	vmovaps	%xmm1, 48(%rsp)                 ## 16-byte Spill
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vmovaps	%xmm8, 80(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm9, 64(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm10, 32(%rsp)                ## 16-byte Spill
	vmovaps	%xmm12, 112(%rsp)               ## 16-byte Spill
	vmovaps	%xmm4, 96(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm5, 256(%rsp)                ## 16-byte Spill
	vmovaps	%xmm13, 240(%rsp)               ## 16-byte Spill
	vmovaps	%xmm14, 224(%rsp)               ## 16-byte Spill
	vmovaps	%xmm15, 208(%rsp)               ## 16-byte Spill
	vzeroupper
	CALL(powf)
	vmovaps	208(%rsp), %xmm15               ## 16-byte Reload
	vmovaps	224(%rsp), %xmm14               ## 16-byte Reload
	vmovaps	240(%rsp), %xmm13               ## 16-byte Reload
	vmovaps	256(%rsp), %xmm5                ## 16-byte Reload
	vmovaps	96(%rsp), %xmm4                 ## 16-byte Reload
	vmovaps	112(%rsp), %xmm12               ## 16-byte Reload
	vmovaps	48(%rsp), %xmm1                 ## 16-byte Reload
	vmovaps	32(%rsp), %xmm10                ## 16-byte Reload
	vmovaps	64(%rsp), %xmm9                 ## 16-byte Reload
	vmovaps	80(%rsp), %xmm8                 ## 16-byte Reload
	vmovaps	160(%rsp), %xmm3                ## 16-byte Reload
	vmovss	LCPI1_0(%rip), %xmm2            ## xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	vmulss	8(%r15), %xmm0, %xmm7
LBB1_12:
	vandnps	%xmm8, %xmm9, %xmm6
	vandnps	%xmm10, %xmm1, %xmm11
	vandnps	%xmm12, %xmm4, %xmm10
	vandnps	%xmm5, %xmm13, %xmm9
	vandnps	%xmm14, %xmm15, %xmm8
	vminss	%xmm7, %xmm2, %xmm0
	vxorps	%xmm4, %xmm4, %xmm4
	vcmpltss	%xmm4, %xmm7, %xmm1
	vandnps	%xmm0, %xmm1, %xmm7
	vshufpd	$1, %xmm3, %xmm3, %xmm0         ## xmm0 = xmm3[1,0]
	vucomiss	%xmm4, %xmm0
	vxorps	%xmm0, %xmm0, %xmm0
	jne	LBB1_13
	jnp	LBB1_14
LBB1_13:
	vmovapd	128(%rsp), %ymm0                ## 32-byte Reload
	vextractf128	$1, %ymm0, %xmm0
	vshufpd	$1, %xmm0, %xmm0, %xmm0         ## xmm0 = xmm0[1,0]
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vmovaps	%xmm7, 80(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm8, 64(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm9, 32(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm10, 48(%rsp)                ## 16-byte Spill
	vmovaps	%xmm11, 112(%rsp)               ## 16-byte Spill
	vmovaps	%xmm6, 96(%rsp)                 ## 16-byte Spill
	vzeroupper
	CALL(powf)
	vxorps	%xmm4, %xmm4, %xmm4
	vmovaps	160(%rsp), %xmm3                ## 16-byte Reload
	vmovaps	96(%rsp), %xmm6                 ## 16-byte Reload
	vmovss	LCPI1_0(%rip), %xmm2            ## xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	vmovaps	112(%rsp), %xmm11               ## 16-byte Reload
	vmovaps	48(%rsp), %xmm10                ## 16-byte Reload
	vmovaps	32(%rsp), %xmm9                 ## 16-byte Reload
	vmovaps	64(%rsp), %xmm8                 ## 16-byte Reload
	vmovaps	80(%rsp), %xmm7                 ## 16-byte Reload
	vmulss	8(%r15), %xmm0, %xmm0
LBB1_14:
	vminss	%xmm0, %xmm2, %xmm1
	vcmpltss	%xmm4, %xmm0, %xmm5
	vshufps	$255, %xmm3, %xmm3, %xmm0       ## xmm0 = xmm3[3,3,3,3]
	vucomiss	%xmm4, %xmm0
	jne	LBB1_15
	jnp	LBB1_16
LBB1_15:
	vmovaps	128(%rsp), %ymm0                ## 32-byte Reload
	vextractf128	$1, %ymm0, %xmm0
	vshufps	$255, %xmm0, %xmm0, %xmm0       ## xmm0 = xmm0[3,3,3,3]
	vmovaps	%xmm1, 128(%rsp)                ## 16-byte Spill
	vmovss	16(%rsp), %xmm1                 ## 4-byte Reload
                                        ## xmm1 = mem[0],zero,zero,zero
	vmovaps	%xmm7, 80(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm8, 64(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm9, 32(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm10, 48(%rsp)                ## 16-byte Spill
	vmovaps	%xmm11, 112(%rsp)               ## 16-byte Spill
	vmovaps	%xmm6, 96(%rsp)                 ## 16-byte Spill
	vmovaps	%xmm5, 16(%rsp)                 ## 16-byte Spill
	vzeroupper
	CALL(powf)
	vmovaps	16(%rsp), %xmm5                 ## 16-byte Reload
	vmovaps	128(%rsp), %xmm1                ## 16-byte Reload
	vmovaps	96(%rsp), %xmm6                 ## 16-byte Reload
	vmovss	LCPI1_0(%rip), %xmm2            ## xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	vmovaps	112(%rsp), %xmm11               ## 16-byte Reload
	vmovaps	48(%rsp), %xmm10                ## 16-byte Reload
	vmovaps	32(%rsp), %xmm9                 ## 16-byte Reload
	vmovaps	64(%rsp), %xmm8                 ## 16-byte Reload
	vmovaps	80(%rsp), %xmm7                 ## 16-byte Reload
	vmulss	8(%r15), %xmm0, %xmm4
LBB1_16:
	vandnps	%xmm1, %xmm5, %xmm5
	vminss	%xmm4, %xmm2, %xmm0
	vxorps	%xmm1, %xmm1, %xmm1
	vcmpltss	%xmm1, %xmm4, %xmm1
	vandnps	%xmm0, %xmm1, %xmm2
	vmovsd	24(%r15), %xmm3                 ## xmm3 = mem[0],zero
	vshufps	$225, %xmm3, %xmm3, %xmm0       ## xmm0 = xmm3[1,0,2,3]
	vbroadcastsd	%xmm0, %ymm1
	vmovss	32(%r15), %xmm0                 ## xmm0 = mem[0],zero,zero,zero
	testq	%r14, %r14
	je	LBB1_17
## %bb.19:
	vmulss	%xmm6, %xmm0, %xmm3
	vroundss	$11, %xmm3, %xmm3, %xmm3
	vcvttss2si	%xmm3, %edx
	cmpl	$255, %edx
	movl	$255, %eax
	cmovgel	%eax, %edx
	xorl	%ecx, %ecx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm6, %xmm3
	vmulps	%xmm3, %xmm1, %xmm3
	vroundps	$11, %xmm3, %xmm3
	vcvttps2dq	%xmm3, %xmm4
	vpbroadcastd	LCPI1_2(%rip), %xmm3    ## xmm3 = [255,255,255,255]
	vpminsd	%xmm3, %xmm4, %xmm6
	vpxor	%xmm4, %xmm4, %xmm4
	vpmaxsd	%xmm4, %xmm6, %xmm6
	L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm0, %xmm11, %xmm6
	vroundss	$11, %xmm6, %xmm6, %xmm6
	vcvttss2si	%xmm6, %edx
	movl	%edi, (%rbx)
	cmpl	$255, %edx
	cmovgel	%eax, %edx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm11, %xmm6
	vmulps	%xmm6, %xmm1, %xmm6
	vroundps	$11, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpminsd	%xmm3, %xmm6, %xmm6
	vpmaxsd	%xmm4, %xmm6, %xmm6
	L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm0, %xmm10, %xmm6
	vroundss	$11, %xmm6, %xmm6, %xmm6
	vcvttss2si	%xmm6, %edx
	movl	%edi, 4(%rbx)
	cmpl	$255, %edx
	cmovgel	%eax, %edx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm10, %xmm6
	vmulps	%xmm6, %xmm1, %xmm6
	vroundps	$11, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpminsd	%xmm3, %xmm6, %xmm6
	vpmaxsd	%xmm4, %xmm6, %xmm6
	L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm0, %xmm9, %xmm6
	vroundss	$11, %xmm6, %xmm6, %xmm6
	vcvttss2si	%xmm6, %edx
	movl	%edi, 8(%rbx)
	cmpl	$255, %edx
	cmovgel	%eax, %edx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm9, %xmm6
	vmulps	%xmm6, %xmm1, %xmm6
	vroundps	$11, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpminsd	%xmm3, %xmm6, %xmm6
	vpmaxsd	%xmm4, %xmm6, %xmm6
	L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm0, %xmm8, %xmm6
	vroundss	$11, %xmm6, %xmm6, %xmm6
	vcvttss2si	%xmm6, %edx
	movl	%edi, 12(%rbx)
	cmpl	$255, %edx
	cmovgel	%eax, %edx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm8, %xmm6
	vmulps	%xmm6, %xmm1, %xmm6
	vroundps	$11, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpminsd	%xmm3, %xmm6, %xmm6
	vpmaxsd	%xmm4, %xmm6, %xmm6
	L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm7, %xmm0, %xmm6
	vroundss	$11, %xmm6, %xmm6, %xmm6
	vcvttss2si	%xmm6, %edx
	movl	%edi, 16(%rbx)
	cmpl	$255, %edx
	cmovgel	%eax, %edx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm7, %xmm6
	vmulps	%xmm6, %xmm1, %xmm6
	vroundps	$11, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpminsd	%xmm3, %xmm6, %xmm6
	vpmaxsd	%xmm4, %xmm6, %xmm6
	L2S_GATHER_CMOV_PACK %r14, %xmm6, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm5, %xmm0, %xmm6
	vroundss	$11, %xmm6, %xmm6, %xmm6
	vcvttss2si	%xmm6, %edx
	movl	%edi, 20(%rbx)
	cmpl	$255, %edx
	cmovgel	%eax, %edx
	testl	%edx, %edx
	cmovlel	%ecx, %edx
	vbroadcastss	%xmm5, %xmm5
	vmulps	%xmm5, %xmm1, %xmm5
	vroundps	$11, %xmm5, %xmm5
	vcvttps2dq	%xmm5, %xmm5
	vpminsd	%xmm3, %xmm5, %xmm5
	vpmaxsd	%xmm4, %xmm5, %xmm5
	L2S_GATHER_CMOV_PACK %r14, %xmm5, %rsi, %esi, %rdi, %edi, %rdx, %edx, %r8d
	vmulss	%xmm2, %xmm0, %xmm0
	vroundss	$11, %xmm0, %xmm0, %xmm0
	vcvttss2si	%xmm0, %edx
	movl	%edi, 24(%rbx)
	cmpl	$255, %edx
	cmovll	%edx, %eax
	testl	%eax, %eax
	cmovlel	%ecx, %eax
	vbroadcastss	%xmm2, %xmm0
	vmulps	%xmm0, %xmm1, %xmm0
	vroundps	$11, %xmm0, %xmm0
	vcvttps2dq	%xmm0, %xmm0
	vpminsd	%xmm3, %xmm0, %xmm0
	vpmaxsd	%xmm4, %xmm0, %xmm0
	L2S_GATHER_CMOV_PACK %r14, %xmm0, %rcx, %ecx, %rdx, %edx, %rax, %eax, %esi
	movl	%edx, 28(%rbx)
	jmp	LBB1_18
LBB1_17:
	vinsertps	$16, %xmm2, %xmm5, %xmm2 ## xmm2 = xmm5[0],xmm2[0],xmm5[2,3]
	vinsertps	$16, %xmm7, %xmm8, %xmm4 ## xmm4 = xmm8[0],xmm7[0],xmm8[2,3]
	vinsertps	$16, %xmm11, %xmm6, %xmm5 ## xmm5 = xmm6[0],xmm11[0],xmm6[2,3]
	vinsertps	$32, %xmm10, %xmm5, %xmm5 ## xmm5 = xmm5[0,1],xmm10[0],xmm5[3]
	vinsertps	$48, %xmm9, %xmm5, %xmm5 ## xmm5 = xmm5[0,1,2],xmm9[0]
	vinsertf128	$1, %xmm4, %ymm5, %ymm4
	vinsertf128	$1, %xmm2, %ymm5, %ymm2
	vshufpd	$2, %ymm2, %ymm4, %ymm2         ## ymm2 = ymm4[0],ymm2[1],ymm4[2],ymm2[2]
	vmulps	%ymm2, %ymm1, %ymm1
	vaddps	LCPI1_6(%rip), %ymm1, %ymm1    ## +0.5 round-half-up
	vroundps	$11, %ymm1, %ymm1
	vcvttps2dq	%ymm1, %ymm1
	vpbroadcastd	LCPI1_2(%rip), %ymm4    ## ymm4 = [255,255,255,255,255,255,255,255]
	vpminsd	%ymm4, %ymm1, %ymm1
	vxorps	%xmm5, %xmm5, %xmm5
	vpmaxsd	%ymm5, %ymm1, %ymm1
	vbroadcastsd	%xmm3, %ymm3
	vmulps	%ymm2, %ymm3, %ymm3
	vaddps	LCPI1_6(%rip), %ymm3, %ymm3    ## +0.5 round-half-up
	vroundps	$11, %ymm3, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vpminsd	%ymm4, %ymm3, %ymm3
	vpmaxsd	%ymm5, %ymm3, %ymm3
	vbroadcastss	%xmm0, %ymm0
	vmulps	%ymm2, %ymm0, %ymm0
	vaddps	LCPI1_6(%rip), %ymm0, %ymm0    ## +0.5 round-half-up
	vroundps	$11, %ymm0, %ymm0
	vcvttps2dq	%ymm0, %ymm0
	vpminsd	%ymm4, %ymm0, %ymm0
	vpmaxsd	%ymm5, %ymm0, %ymm0
	vpblendd	$170, %ymm1, %ymm3, %ymm2       ## ymm2 = ymm3[0],ymm1[1],ymm3[2],ymm1[3],ymm3[4],ymm1[5],ymm3[6],ymm1[7]
	vpblendd	$170, %ymm3, %ymm1, %ymm4       ## ymm4 = ymm1[0],ymm3[1],ymm1[2],ymm3[3],ymm1[4],ymm3[5],ymm1[6],ymm3[7]
	vpmaxud	%ymm4, %ymm2, %ymm2
	vpmaxud	%ymm0, %ymm2, %ymm2
	vpslld	$24, %ymm2, %ymm2
	vpsllvd	LCPI1_3(%rip), %ymm1, %ymm1
	vpsllvd	LCPI1_4(%rip), %ymm3, %ymm3
	vpor	%ymm3, %ymm1, %ymm1
	vpor	%ymm0, %ymm2, %ymm0
	vpor	%ymm0, %ymm1, %ymm0
	vmovdqu	%ymm0, (%rbx)
LBB1_18:
	leaq	-24(%rbp), %rsp
	popq	%rbx
	popq	%r14
	popq	%r15
	popq	%rbp
	vzeroupper
	retq
	.cfi_endproc
                                        ## -- End function
	.globl SYM(ksvgLightingPointSpecularRowAvx2Linear) ## -- Begin function ksvgLightingPointSpecularRowAvx2Linear
	.p2align	4, 0x90
SYM(ksvgLightingPointSpecularRowAvx2Linear): ## @ksvgLightingPointSpecularRowAvx2Linear
	.cfi_startproc
## %bb.0:
	testl	%r8d, %r8d
	jle	LBB2_4
## %bb.1:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$72, %rsp
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	movq	%rcx, %r15
	movq	%rdx, %r12
	movq	%rsi, %r13
	movq	%rdi, %r14
	xorl	%ebx, %ebx
	vmovss	%xmm0, -48(%rbp)                ## 4-byte Spill
	movq	%r9, -56(%rbp)                  ## 8-byte Spill
	movl	%r8d, -44(%rbp)                 ## 4-byte Spill
	.p2align	4, 0x90
LBB2_2:                                 ## =>This Inner Loop Header: Depth=1
	vmovups	(%r9), %ymm3
	vmovups	20(%r9), %ymm1
	vcvtsi2ss	%ebx, %xmm4, %xmm2
	vmovups	%ymm1, -92(%rbp)
	vmovups	%ymm3, -112(%rbp)
	vmulss	48(%r9), %xmm2, %xmm1
	vaddss	40(%r9), %xmm1, %xmm1
	vmovss	%xmm1, -72(%rbp)
	movq	%r14, %rdi
	movq	%r13, %rsi
	movq	%r12, %rdx
	movq	%r15, %rcx
	leaq	-112(%rbp), %r8
	movq	16(%rbp), %r9
	vzeroupper
	callq	SYM(core8)
	movl	-44(%rbp), %r8d                 ## 4-byte Reload
	movq	-56(%rbp), %r9                  ## 8-byte Reload
	vmovss	-48(%rbp), %xmm0                ## 4-byte Reload
                                        ## xmm0 = mem[0],zero,zero,zero
	addq	$32, %r15
	addq	$32, %r12
	addq	$32, %r13
	addq	$32, %r14
	addl	$8, %ebx
	cmpl	%r8d, %ebx
	jl	LBB2_2
## %bb.3:
	addq	$72, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
LBB2_4:
	retq
	.cfi_endproc
                                        ## -- End function
