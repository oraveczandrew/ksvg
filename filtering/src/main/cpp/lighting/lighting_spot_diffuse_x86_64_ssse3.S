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
	.p2align	4, 0x0                          # -- Begin function SYM(ksvgLightingSpotDiffuseRowSsse3)
.LCPI0_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
.LCPI0_1:
	.long	0x80000000                      # float -0
	.long	0x80000000                      # float -0
	.long	0x80000000                      # float -0
	.long	0x80000000                      # float -0
.LCPI0_2:
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
.LCPI0_3:
	.long	65535                           # 0xffff
	.long	65535                           # 0xffff
	.long	65535                           # 0xffff
	.long	65535                           # 0xffff
.LCPI0_4:
	.long	1258291200                      # 0x4b000000
	.long	1258291200                      # 0x4b000000
	.long	1258291200                      # 0x4b000000
	.long	1258291200                      # 0x4b000000
.LCPI0_5:
	.long	1392508928                      # 0x53000000
	.long	1392508928                      # 0x53000000
	.long	1392508928                      # 0x53000000
	.long	1392508928                      # 0x53000000
.LCPI0_6:
	.long	0x53000080                      # float 5.49764202E+11
	.long	0x53000080                      # float 5.49764202E+11
	.long	0x53000080                      # float 5.49764202E+11
	.long	0x53000080                      # float 5.49764202E+11
.LCPI0_7:
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
.LCPI0_8:
	.long	4278190080                      # 0xff000000
	.long	4278190080                      # 0xff000000
	.long	4278190080                      # 0xff000000
	.long	4278190080                      # 0xff000000
.LCPI0_9:
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
.LCPI0_11:
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.zero	4
	.zero	4
.LCPI0_12:
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.zero	4
	.zero	4
.LCPI0_14:
	.zero	16
.LSPOTSSSE3_HALF:
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
RODATA4
	.p2align	2, 0x0
.LCPI0_10:
	.long	0x3f800000                      # float 1
.LCPI0_13:
	.long	0x437f0000                      # float 255
.LCPI0_15:
	.long	0x00000000                      # float 0
	.text
RODATA16
	.p2align	4, 0x0                          # -- Begin function ksvgLightingSpotDiffuseRowSsse3_clean
.LSPOTSSSE3_C0:
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
.LSPOTSSSE3_C2:
	.long	0x40000000                      # float 2
	.long	0x40400000                      # float 3
	.zero	4
	.zero	4
.LSPOTSSSE3_C3:
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
.LSPOTSSSE3_C4:
	.quad	-72057589759737856              # 0xff000000ff000000
	.quad	-72057589759737856              # 0xff000000ff000000
.LSPOTSSSE3_C5:
	.long	0x40000000                      # float 2
	.long	0x40400000                      # float 3
	.long	0x00000000                      # float 0
	.long	0x00000000                      # float 0
RODATA4
	.p2align	2, 0x0
.LSPOTSSSE3_C1:
	.long	0x3f800000                      # float 1
	.text
	.globl	SYM(ksvgLightingSpotDiffuseRowSsse3)
	.p2align	4, 0x90
	TYPE(SYM(ksvgLightingSpotDiffuseRowSsse3), @function)
SYM(ksvgLightingSpotDiffuseRowSsse3):  # @ksvgLightingSpotDiffuseRowSsse3
# %bb.0:
	testl	%r8d, %r8d
	jle	LSPOTSSSE3_DONE
# %bb.1:
	movss	36(%r9), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movl	%r8d, %eax
	xorl	%r8d, %r8d
	xorps	%xmm1, %xmm1
	movaps	.LSPOTSSSE3_C0(%rip), %xmm2           # xmm2 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	movss	.LSPOTSSSE3_C1(%rip), %xmm3           # xmm3 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	movsd	.LSPOTSSSE3_C5(%rip), %xmm4           # xmm4 = [2.0E+0,3.0E+0,0.0E+0,0.0E+0]
	movaps	.LSPOTSSSE3_C3(%rip), %xmm5           # xmm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	movdqa	.LSPOTSSSE3_C4(%rip), %xmm6           # xmm6 = [18374686483949813760,18374686483949813760]
	.p2align	4, 0x90
LSPOTSSSE3_LOOP:                                # =>This Inner Loop Header: Depth=1
	movdqu	(%rdi,%r8,4), %xmm7
	movdqu	4(%rdi,%r8,4), %xmm8
	movdqu	8(%rdi,%r8,4), %xmm9
	ALPHA_FSCALE %xmm7, %xmm0
	ALPHA_FSCALE_X %xmm8, %xmm10, %xmm0
	ALPHA_FSCALE_X %xmm9, %xmm8, %xmm0
	addps	%xmm10, %xmm10
	addps	%xmm7, %xmm10
	addps	%xmm8, %xmm10
	movaps	%xmm8, %xmm11
	subps	%xmm7, %xmm11
	xorps	%xmm8, %xmm8
	subps	%xmm10, %xmm8
	movdqu	(%rsi,%r8,4), %xmm7
	movdqu	4(%rsi,%r8,4), %xmm9
	movdqu	8(%rsi,%r8,4), %xmm10
	ALPHA_FSCALE_X %xmm7, %xmm12, %xmm0
	ALPHA_FSCALE_X %xmm9, %xmm7, %xmm0
	ALPHA_FSCALE_X %xmm10, %xmm9, %xmm0
	addps	%xmm9, %xmm9
	addps	%xmm12, %xmm12
	subps	%xmm12, %xmm9
	addps	%xmm11, %xmm9
	movdqu	(%rdx,%r8,4), %xmm10
	movdqu	4(%rdx,%r8,4), %xmm11
	movdqu	8(%rdx,%r8,4), %xmm13
	ALPHA_FSCALE %xmm10, %xmm0
	ALPHA_FSCALE_X %xmm11, %xmm12, %xmm0
	ALPHA_FSCALE_X %xmm13, %xmm11, %xmm0
	addps	%xmm12, %xmm12
	addps	%xmm10, %xmm12
	addps	%xmm11, %xmm12
	movaps	%xmm11, %xmm13
	subps	%xmm10, %xmm13
	addps	%xmm9, %xmm13
	addps	%xmm8, %xmm12
	movss	(%r9), %xmm8                    # xmm8 = mem[0],zero,zero,zero
	movss	4(%r9), %xmm10                  # xmm10 = mem[0],zero,zero,zero
	movss	12(%r9), %xmm9                  # xmm9 = mem[0],zero,zero,zero
	shufps	$0, %xmm8, %xmm8                # xmm8 = xmm8[0,0,0,0]
	divps	%xmm8, %xmm13
	shufps	$0, %xmm10, %xmm10              # xmm10 = xmm10[0,0,0,0]
	divps	%xmm10, %xmm12
	xorps	%xmm11, %xmm11
	subps	%xmm13, %xmm11
	xorps	%xmm10, %xmm10
	subps	%xmm12, %xmm10
	movaps	%xmm11, %xmm8
	mulps	%xmm11, %xmm8
	movaps	%xmm10, %xmm12
	mulps	%xmm10, %xmm12
	addps	%xmm8, %xmm12
	addps	%xmm2, %xmm12
	sqrtps	%xmm12, %xmm12
	xorps	%xmm13, %xmm13
	cvtsi2ss	%r8d, %xmm13
	movaps	%xmm2, %xmm8
	divps	%xmm12, %xmm8
	movaps	%xmm13, %xmm12
	addss	%xmm3, %xmm12
	movsldup	%xmm13, %xmm14                  # xmm14 = xmm13[0,0,2,2]
	addps	%xmm4, %xmm14
	unpcklps	%xmm12, %xmm13                  # xmm13 = xmm13[0],xmm12[0],xmm13[1],xmm12[1]
	movlhps	%xmm14, %xmm13                  # xmm13 = xmm13[0],xmm14[0]
	movss	40(%r9), %xmm12                 # xmm12 = mem[0],zero,zero,zero
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	movss	48(%r9), %xmm14                 # xmm14 = mem[0],zero,zero,zero
	shufps	$0, %xmm14, %xmm14              # xmm14 = xmm14[0,0,0,0]
	mulps	%xmm13, %xmm14
	addps	%xmm12, %xmm14
	shufps	$0, %xmm9, %xmm9                # xmm9 = xmm9[0,0,0,0]
	subps	%xmm14, %xmm9
	movss	16(%r9), %xmm13                 # xmm13 = mem[0],zero,zero,zero
	subss	44(%r9), %xmm13
	movaps	%xmm13, %xmm12
	movss	20(%r9), %xmm14                 # xmm14 = mem[0],zero,zero,zero
	shufps	$0, %xmm14, %xmm14              # xmm14 = xmm14[0,0,0,0]
	subps	%xmm7, %xmm14
	movaps	%xmm9, %xmm7
	mulps	%xmm9, %xmm7
	mulss	%xmm13, %xmm13
	shufps	$0, %xmm13, %xmm13              # xmm13 = xmm13[0,0,0,0]
	addps	%xmm7, %xmm13
	movaps	%xmm14, %xmm15
	mulps	%xmm14, %xmm15
	addps	%xmm13, %xmm15
	sqrtps	%xmm15, %xmm13
	movaps	%xmm2, %xmm7
	divps	%xmm13, %xmm7
	cmpneqps	%xmm1, %xmm15
	andps	%xmm15, %xmm7
	shufps	$0, %xmm12, %xmm12              # xmm12 = xmm12[0,0,0,0]
	mulps	%xmm7, %xmm9
	mulps	%xmm7, %xmm12
	mulps	%xmm14, %xmm7
	mulps	%xmm9, %xmm11
	mulps	%xmm12, %xmm10
	addps	%xmm11, %xmm10
	mulps	%xmm7, %xmm8
	addps	%xmm10, %xmm8
	movss	52(%r9), %xmm10                 # xmm10 = mem[0],zero,zero,zero
	shufps	$0, %xmm10, %xmm10              # xmm10 = xmm10[0,0,0,0]
	mulps	%xmm9, %xmm10
	movss	56(%r9), %xmm9                  # xmm9 = mem[0],zero,zero,zero
	shufps	$0, %xmm9, %xmm9                # xmm9 = xmm9[0,0,0,0]
	mulps	%xmm12, %xmm9
	addps	%xmm10, %xmm9
	movss	60(%r9), %xmm10                 # xmm10 = mem[0],zero,zero,zero
	shufps	$0, %xmm10, %xmm10              # xmm10 = xmm10[0,0,0,0]
	mulps	%xmm7, %xmm10
	movss	8(%r9), %xmm7                   # xmm7 = mem[0],zero,zero,zero
	maxps	%xmm1, %xmm8
	addps	%xmm9, %xmm10
	xorps	%xmm9, %xmm9
	subps	%xmm10, %xmm9
	maxps	%xmm1, %xmm9
	movss	64(%r9), %xmm10                 # xmm10 = mem[0],zero,zero,zero
	shufps	$0, %xmm10, %xmm10              # xmm10 = xmm10[0,0,0,0]
	cmpleps	%xmm9, %xmm10
	andps	%xmm9, %xmm10
	shufps	$0, %xmm7, %xmm7                # xmm7 = xmm7[0,0,0,0]
	mulps	%xmm8, %xmm7
	mulps	%xmm10, %xmm7
	minps	%xmm2, %xmm7
	movss	24(%r9), %xmm8                  # xmm8 = mem[0],zero,zero,zero
	shufps	$0, %xmm8, %xmm8                # xmm8 = xmm8[0,0,0,0]
	mulps	%xmm7, %xmm8
	movss	28(%r9), %xmm9                  # xmm9 = mem[0],zero,zero,zero
	shufps	$0, %xmm9, %xmm9                # xmm9 = xmm9[0,0,0,0]
	mulps	%xmm7, %xmm9
	movss	32(%r9), %xmm10                 # xmm10 = mem[0],zero,zero,zero
	shufps	$0, %xmm10, %xmm10              # xmm10 = xmm10[0,0,0,0]
	mulps	%xmm7, %xmm10
	addps	.LSPOTSSSE3_HALF(%rip), %xmm8   # round-half-up R
	minps	%xmm5, %xmm8
	cvttps2dq	%xmm8, %xmm7
	addps	.LSPOTSSSE3_HALF(%rip), %xmm9   # round-half-up G
	minps	%xmm5, %xmm9
	cvttps2dq	%xmm9, %xmm8
	pslld	$16, %xmm7
	pslld	$8, %xmm8
	por	%xmm7, %xmm8
	addps	.LSPOTSSSE3_HALF(%rip), %xmm10  # round-half-up B
	minps	%xmm5, %xmm10
	cvttps2dq	%xmm10, %xmm7
	por	%xmm7, %xmm8
	por	%xmm6, %xmm8
	movdqu	%xmm8, (%rcx,%r8,4)
	addq	$4, %r8
	cmpq	%rax, %r8
	jb	LSPOTSSSE3_LOOP
LSPOTSSSE3_DONE:
	retq
.Lfunc_end0:
	SIZE(SYM(ksvgLightingSpotDiffuseRowSsse3))
                                        # -- End function
RODATA16
	.p2align	4, 0x0                          # -- Begin function SYM(ksvgLightingSpotDiffuseRowSsse3Linear)
.LCPI1_0:
	.long	0x80000000                      # float -0
	.long	0x80000000                      # float -0
	.long	0x80000000                      # float -0
	.long	0x80000000                      # float -0
.LCPI1_2:
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.zero	4
	.zero	4
.LCPI1_3:
	.long	0x437f0000                      # float 255
	.long	0x437f0000                      # float 255
	.zero	4
	.zero	4
.LCPI1_6:
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.zero	4
	.zero	4
RODATA4
	.p2align	2, 0x0
.LCPI1_1:
	.long	0x3f800000                      # float 1
.LCPI1_4:
	.long	0x437f0000                      # float 255
.LCPI1_5:
	.long	0x00000000                      # float 0
.LCPI1_7:
	.long	0x3f000000                      # float 0.5
	.text
	.globl	SYM(ksvgLightingSpotDiffuseRowSsse3Linear)
	.p2align	4, 0x90
	TYPE(SYM(ksvgLightingSpotDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingSpotDiffuseRowSsse3Linear):  # @SYM(ksvgLightingSpotDiffuseRowSsse3Linear)
# %bb.0:
	testl	%r8d, %r8d
	jle	.LBB1_4
# %bb.1:
	pushq	%rbp
	pushq	%r15
	pushq	%r13
	pushq	%r14
	pushq	%r12
	pushq	%rbx
	subq	$8, %rsp
	movq	40(%rsp), %rax
	movss	36(%r9), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	movss	(%r9), %xmm1                    # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -4(%rsp)                 # 4-byte Spill
	movss	4(%r9), %xmm1                   # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -8(%rsp)                 # 4-byte Spill
	movss	40(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -12(%rsp)                # 4-byte Spill
	movss	48(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -16(%rsp)                # 4-byte Spill
	movss	16(%r9), %xmm5                  # xmm5 = mem[0],zero,zero,zero
	subss	44(%r9), %xmm5
	movss	12(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -20(%rsp)                # 4-byte Spill
	movss	20(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -24(%rsp)                # 4-byte Spill
	movaps	%xmm5, %xmm8
	mulss	%xmm5, %xmm8
	movss	52(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -28(%rsp)                # 4-byte Spill
	movss	56(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -32(%rsp)                # 4-byte Spill
	movss	60(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -36(%rsp)                # 4-byte Spill
	movss	64(%r9), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -40(%rsp)                # 4-byte Spill
	movss	8(%r9), %xmm1                   # xmm1 = mem[0],zero,zero,zero
	movss	%xmm1, -44(%rsp)                # 4-byte Spill
	movsd	24(%r9), %xmm14                 # xmm14 = mem[0],zero
	movss	32(%r9), %xmm15                 # xmm15 = mem[0],zero,zero,zero
	movq	%rsi, %r13
	movq	%rdx, %r14
	movq	%r14, -64(%rsp)
	movl	%r8d, %r8d
	xorl	%r9d, %r9d
	movl	$255, %r10d
	movaps	.LCPI1_0(%rip), %xmm1           # xmm1 = [-0.0E+0,-0.0E+0,-0.0E+0,-0.0E+0]
	movss	.LCPI1_1(%rip), %xmm2           # xmm2 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
	.p2align	4, 0x90
.LBB1_2:                                # =>This Inner Loop Header: Depth=1
	movq	-64(%rsp), %r14
	movzbl	3(%rdi,%r9,4), %r11d
	xorps	%xmm6, %xmm6
	cvtsi2ss	%r11d, %xmm6
	mulss	%xmm0, %xmm6
	movzbl	7(%rdi,%r9,4), %r11d
	cvtsi2ss	%r11d, %xmm7
	mulss	%xmm0, %xmm7
	movzbl	11(%rdi,%r9,4), %r11d
	cvtsi2ss	%r11d, %xmm9
	movzbl	3(%r13,%r9,4), %r11d
	xorps	%xmm12, %xmm12
	cvtsi2ss	%r11d, %xmm12
	movzbl	11(%r13,%r9,4), %r11d
	xorps	%xmm3, %xmm3
	cvtsi2ss	%r11d, %xmm3
	mulss	%xmm0, %xmm9
	mulss	%xmm0, %xmm12
	mulss	%xmm0, %xmm3
	movzbl	3(%r14,%r9,4), %r11d
	cvtsi2ss	%r11d, %xmm10
	mulss	%xmm0, %xmm10
	movzbl	7(%r14,%r9,4), %r11d
	xorps	%xmm4, %xmm4
	cvtsi2ss	%r11d, %xmm4
	movzbl	11(%r14,%r9,4), %r11d
	cvtsi2ss	%r11d, %xmm13
	mulss	%xmm0, %xmm4
	mulss	%xmm0, %xmm13
	addss	%xmm3, %xmm3
	addss	%xmm9, %xmm3
	addss	%xmm13, %xmm3
	addss	%xmm12, %xmm12
	addss	%xmm6, %xmm12
	addss	%xmm10, %xmm12
	subss	%xmm12, %xmm3
	addss	%xmm4, %xmm4
	addss	%xmm10, %xmm4
	addss	%xmm13, %xmm4
	movss	-24(%rsp), %xmm12               # 4-byte Reload
                                        # xmm12 = mem[0],zero,zero,zero
	movzbl	7(%r13,%r9,4), %r11d            # center height (current pixel alpha)
	cvtsi2ss	%r11d, %xmm10
	mulss	%xmm0, %xmm10                   # center * ss
	subss	%xmm10, %xmm12                  # vz = lightZ - center*ss
	addss	%xmm7, %xmm7
	addss	%xmm6, %xmm7
	addss	%xmm9, %xmm7
	subss	%xmm7, %xmm4
	xorps	%xmm1, %xmm3
	divss	-4(%rsp), %xmm3                 # 4-byte Folded Reload
	xorps	%xmm1, %xmm4
	divss	-8(%rsp), %xmm4                 # 4-byte Folded Reload
	movaps	%xmm4, %xmm6
	mulss	%xmm4, %xmm6
	movaps	%xmm3, %xmm7
	mulss	%xmm3, %xmm7
	addss	%xmm6, %xmm7
	addss	%xmm2, %xmm7
	xorps	%xmm9, %xmm9
	cvtsi2ss	%r9d, %xmm9
	mulss	-16(%rsp), %xmm9                # 4-byte Folded Reload
	addss	-12(%rsp), %xmm9                # 4-byte Folded Reload
	movss	-20(%rsp), %xmm6                # 4-byte Reload
                                        # xmm6 = mem[0],zero,zero,zero
	subss	%xmm9, %xmm6
	movaps	%xmm6, %xmm9
	mulss	%xmm6, %xmm9
	addss	%xmm8, %xmm9
	movaps	%xmm12, %xmm10
	mulss	%xmm12, %xmm10
	addss	%xmm9, %xmm10
	unpcklps	%xmm10, %xmm7                   # xmm7 = xmm7[0],xmm10[0],xmm7[1],xmm10[1]
	sqrtps	%xmm7, %xmm9
	movaps	.LCPI1_2(%rip), %xmm7           # xmm7 = [1.0E+0,1.0E+0,u,u]
	divps	%xmm9, %xmm7
	movshdup	%xmm7, %xmm9                    # xmm9 = xmm7[1,1,3,3]
	mulss	%xmm9, %xmm6
	unpcklps	%xmm5, %xmm4                    # xmm4 = xmm4[0],xmm5[0],xmm4[1],xmm5[1]
	mulps	%xmm7, %xmm4
	mulss	%xmm9, %xmm12
	movshdup	%xmm4, %xmm9                    # xmm9 = xmm4[1,1,3,3]
	movss	-32(%rsp), %xmm10               # 4-byte Reload
                                        # xmm10 = mem[0],zero,zero,zero
	mulss	%xmm9, %xmm10
	movss	-28(%rsp), %xmm13               # 4-byte Reload
                                        # xmm13 = mem[0],zero,zero,zero
	mulss	%xmm6, %xmm13
	addss	%xmm10, %xmm13
	movss	-36(%rsp), %xmm10               # 4-byte Reload
                                        # xmm10 = mem[0],zero,zero,zero
	mulss	%xmm12, %xmm10
	addss	%xmm13, %xmm10
	movaps	%xmm10, %xmm11
	xorps	%xmm1, %xmm11
	movaps	%xmm11, %xmm13
	cmpltss	%xmm10, %xmm13
	andnps	%xmm11, %xmm13
	movaps	%xmm13, %xmm10
	cmpltss	-40(%rsp), %xmm10               # 4-byte Folded Reload
	andnps	%xmm13, %xmm10
	mulss	%xmm9, %xmm4
	mulss	%xmm7, %xmm3
	mulss	%xmm3, %xmm6
	addss	%xmm4, %xmm6
	mulss	%xmm7, %xmm12
	addss	%xmm6, %xmm12
	xorps	%xmm3, %xmm3
	maxss	%xmm12, %xmm3
	mulss	-44(%rsp), %xmm3                # 4-byte Folded Reload
	mulss	%xmm10, %xmm3
	movaps	%xmm2, %xmm4
	minss	%xmm3, %xmm4
	cmpltss	.LCPI1_5(%rip), %xmm3
	andnps	%xmm4, %xmm3
	movsldup	%xmm3, %xmm4                    # xmm4 = xmm3[0,0,2,2]
	mulps	%xmm14, %xmm4
	xorps	%xmm6, %xmm6
	maxps	%xmm4, %xmm6
	addps	.LCPI1_6(%rip), %xmm6           # round-half-up R/G
	movaps	.LCPI1_3(%rip), %xmm4           # xmm4 = [2.55E+2,2.55E+2,u,u]
	cmpltps	%xmm6, %xmm4
	unpcklps	%xmm4, %xmm4                    # xmm4 = xmm4[0,0,1,1]
	movmskpd	%xmm4, %r11d
	cvttss2si	%xmm6, %ebx
	movshdup	%xmm6, %xmm4                    # xmm4 = xmm6[1,1,3,3]
	cvttss2si	%xmm4, %ebp
	mulss	%xmm15, %xmm3
	xorps	%xmm4, %xmm4
	maxss	%xmm3, %xmm4
	movss	.LCPI1_4(%rip), %xmm3           # xmm3 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	minss	%xmm4, %xmm3
	addss	.LCPI1_7(%rip), %xmm3           # round-half-up B
	cvttss2si	%xmm3, %r14d
	movl	%ebx, %eax
	movl	%ebp, %esi
	movl	%r14d, %edx
	leaq	.Lspot_l2s_data(%rip), %r15
	L2S_SPOT %eax
	L2S_SPOT %esi
	L2S_SPOT %edx
	shll	$16, %eax
	shll	$8, %esi
	orl	%eax, %esi
	orl	%edx, %esi
	movl	%esi, %ebx
	orl	$-16777216, %ebx
	movl	%ebx, (%rcx,%r9,4)
	leaq	1(%r9), %r11
	movq	%r11, %r9
	cmpq	%r11, %r8
	jne	.LBB1_2
# %bb.3:
	addq	$8, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
.LBB1_4:
	retq
.Lfunc_end1:
	SIZE(SYM(ksvgLightingSpotDiffuseRowSsse3Linear))
                                        # -- End function
