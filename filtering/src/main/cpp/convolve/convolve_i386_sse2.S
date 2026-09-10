/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

#include "asm_macros.S"

#ifdef __APPLE__
#define CFI_START
#define CFI_DEF_CFA_OFFSET(x)
#define CFI_OFFSET(x,y)
#define CFI_ENDPROC
#else
#define CFI_START .cfi_startproc
#define CFI_DEF_CFA_OFFSET(x) .cfi_def_cfa_offset x
#define CFI_OFFSET(x,y) .cfi_offset x,y
#define CFI_ENDPROC .cfi_endproc
#endif

	.text
	.file	"ksvgConvolveApplyInteriorSse2I386.cpp"
	.p2align	2, 0x0                          # -- Begin function ksvgConvolveApplyInteriorSse2I386
.LCPI0_0:
	.long	0x437f0000                      # float 255
	.p2align	4, 0x0
.LCPI0_1:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_2:
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
	.long	0x3f000000                      # float 0.5
.LCPI0_3:
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
	.long	0x3f800000                      # float 1
.LCPI0_4:
	.zero	16
	.text
	.globl	SYM(ksvgConvolveApplyInteriorSse2)
	.p2align	4, 0x90
TYPE(SYM(ksvgConvolveApplyInteriorSse2), @function)
SYM(ksvgConvolveApplyInteriorSse2):      # @ksvgConvolveApplyInteriorSse2
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
	subl	$172, %esp
CFI_DEF_CFA_OFFSET(192)
CFI_OFFSET(%esi,-20)
CFI_OFFSET(%edi,-16)
CFI_OFFSET(%ebx,-12)
CFI_OFFSET(%ebp,-8)
	call	1f
1:	popl	%eax
	leal	.LCPI0_1-1b(%eax), %eax
	movaps	(%eax), %xmm0
	movups	%xmm0, (%esp)
	movaps	16(%eax), %xmm0
	movups	%xmm0, 16(%esp)
	movaps	32(%eax), %xmm0
	movups	%xmm0, 32(%esp)
	movaps	48(%eax), %xmm0
	movups	%xmm0, 48(%esp)
	leal	.LCPI0_0-.LCPI0_1(%eax), %eax
	movss	(%eax), %xmm0
	movss	%xmm0, 64(%esp)
	movl	220(%esp), %ecx
	movl	212(%esp), %esi
	movl	200(%esp), %edx
	movl	204(%esp), %eax
	subl	%esi, %edx
	leal	(%edx,%ecx), %ebp
	incl	%ebp
	subl	216(%esp), %eax
	leal	1(%eax), %edi
	testl	%edi, %edi
	jle	.LBB0_27
# %bb.1:
	incl	%edx
	cmpl	$4, %edx
	jge	.LBB0_2
.LBB0_27:
	andl	$-4, %ebp
	movl	%ebp, %eax
	addl	$172, %esp
CFI_DEF_CFA_OFFSET(20)
	popl	%esi
CFI_DEF_CFA_OFFSET(16)
	popl	%edi
CFI_DEF_CFA_OFFSET(12)
	popl	%ebx
CFI_DEF_CFA_OFFSET(8)
	popl	%ebp
CFI_DEF_CFA_OFFSET(4)
	retl
.LBB0_2:
CFI_DEF_CFA_OFFSET(192)
	movl	236(%esp), %edx
	movl	224(%esp), %edi
	movss	232(%esp), %xmm0                # xmm0 = mem[0],zero,zero,zero
	addl	%edi, %eax
	incl	%eax
	movl	%eax, 112(%esp)                 # 4-byte Spill
	movss	228(%esp), %xmm1                # xmm1 = mem[0],zero,zero,zero
	shufps	$0, %xmm1, %xmm1                # xmm1 = xmm1[0,0,0,0]
	movups	%xmm1, 128(%esp)                # 16-byte Spill
	mulss	64(%esp), %xmm0
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movups	%xmm0, 144(%esp)                # 16-byte Spill
	leal	4(%ecx), %eax
	movl	%eax, 108(%esp)                 # 4-byte Spill
	movdqu	(%esp), %xmm2                   # xmm2 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	leal	(,%esi,4), %eax
	movl	%eax, 104(%esp)                 # 4-byte Spill
	movl	200(%esp), %eax
	leal	(,%eax,4), %ebx
	movl	%edi, %eax
	movl	192(%esp), %edi
	movl	%ebp, 96(%esp)                  # 4-byte Spill
	jmp	.LBB0_3
	.p2align	4, 0x90
.LBB0_26:                               #   in Loop: Header=BB0_3 Depth=1
	movl	116(%esp), %eax                 # 4-byte Reload
	incl	%eax
	movl	92(%esp), %edi                  # 4-byte Reload
	movl	204(%esp), %edx
	subl	216(%esp), %edx
	addl	224(%esp), %edx
	incl	%edx
	cmpl	%edx, %eax
	jge	.LBB0_27
.LBB0_3:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_4 Depth 2
                                        #       Child Loop BB0_9 Depth 3
                                        #         Child Loop BB0_10 Depth 4
                                        #         Child Loop BB0_12 Depth 4
                                        #       Child Loop BB0_18 Depth 3
                                        #         Child Loop BB0_19 Depth 4
	movl	%edi, 92(%esp)                  # 4-byte Spill: dst base
	movl	%eax, 116(%esp)                 # 4-byte Spill: y
	# Source row = src + (y - targetY) * width * 4.
	movl	%eax, %edx
	subl	224(%esp), %edx
	imull	200(%esp), %edx
	movl	196(%esp), %edi
	leal	(%edi,%edx,4), %edx
	movl	%edx, 88(%esp)                  # 4-byte Spill: current src row
	# Destination row = dst + y * width * 4.
	movl	%eax, %edx
	imull	200(%esp), %edx
	movl	92(%esp), %edi
	leal	(%edi,%edx,4), %edi
	movl	%edi, 120(%esp)                 # 4-byte Spill: dst row
	# %edx is the preserve-alpha flag in the remainder of this block.
	movl	236(%esp), %edx
	movl	108(%esp), %eax                 # 4-byte Reload
	movl	%ecx, %edi
	jmp	.LBB0_4
	.p2align	4, 0x90
.LBB0_25:                               #   in Loop: Header=BB0_4 Depth=2
	divps	128(%esp), %xmm3                # 16-byte Folded Reload
	movups	144(%esp), %xmm0                # 16-byte Reload
	addps	%xmm0, %xmm3
	movaps	%xmm0, %xmm5
	movups	16(%esp), %xmm0                 # xmm0 = [5.0E-1,5.0E-1,5.0E-1,5.0E-1]
	addps	%xmm0, %xmm3
	cvttps2dq	%xmm3, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm3
	movups	32(%esp), %xmm4                 # xmm4 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	andps	%xmm4, %xmm3
	subps	%xmm3, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm3
	pxor	%xmm0, %xmm0
	pcmpgtd	%xmm0, %xmm3
	pand	%xmm4, %xmm3
	divps	128(%esp), %xmm7                # 16-byte Folded Reload
	addps	%xmm5, %xmm7
	addps	16(%esp), %xmm7
	cvttps2dq	%xmm7, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm7
	andps	32(%esp), %xmm7
	subps	%xmm7, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm5
	xorps	%xmm7, %xmm7
	pcmpgtd	%xmm7, %xmm5
	pand	%xmm4, %xmm5
	divps	128(%esp), %xmm6                # 16-byte Folded Reload
	addps	144(%esp), %xmm6                # 16-byte Folded Reload
	addps	16(%esp), %xmm6
	cvttps2dq	%xmm6, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm6
	andps	32(%esp), %xmm6
	subps	%xmm6, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm0
	pcmpgtd	%xmm7, %xmm0
	pand	%xmm4, %xmm0
	pslld	$24, %xmm1
	por	%xmm0, %xmm1
	pslld	$16, %xmm3
	pslld	$8, %xmm5
	por	%xmm3, %xmm5
	por	%xmm1, %xmm5
	movl	120(%esp), %eax                 # 4-byte Reload
	movdqu	%xmm5, (%eax,%edi,4)
	movl	124(%esp), %edi                 # 4-byte Reload
	leal	4(%edi), %eax
	addl	$16, 88(%esp)                   # 4-byte Folded Spill
	cmpl	%ebp, %eax
	jg	.LBB0_26
.LBB0_4:                                #   Parent Loop BB0_3 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_9 Depth 3
                                        #         Child Loop BB0_10 Depth 4
                                        #         Child Loop BB0_12 Depth 4
                                        #       Child Loop BB0_18 Depth 3
                                        #         Child Loop BB0_19 Depth 4
	movl	%eax, 124(%esp)                 # 4-byte Spill
	cmpl	$0, 216(%esp)
	jle	.LBB0_5
# %bb.6:                                #   in Loop: Header=BB0_4 Depth=2
	testl	%esi, %esi
	jle	.LBB0_5
# %bb.7:                                #   in Loop: Header=BB0_4 Depth=2
	movl	%edi, 100(%esp)                 # 4-byte Spill
	testl	%edx, %edx
	je	.LBB0_17
# %bb.8:                                #   in Loop: Header=BB0_4 Depth=2
	xorl	%ebp, %ebp
	xorps	%xmm1, %xmm1
	xorps	%xmm3, %xmm3
	movl	88(%esp), %eax                  # 4-byte Reload
	movl	208(%esp), %edx
	xorps	%xmm7, %xmm7
	xorps	%xmm6, %xmm6
	jmp	.LBB0_9
	.p2align	4, 0x90
.LBB0_15:                               #   in Loop: Header=BB0_9 Depth=3
	incl	%ebp
	addl	104(%esp), %edx                 # 4-byte Folded Reload
	addl	%ebx, %eax
	cmpl	216(%esp), %ebp
	je	.LBB0_16
.LBB0_9:                                #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_10 Depth 4
                                        #         Child Loop BB0_12 Depth 4
	xorl	%edi, %edi
	cmpl	224(%esp), %ebp
	jne	.LBB0_10
# %bb.11:                               #   in Loop: Header=BB0_9 Depth=3
	movaps	%xmm1, %xmm0
	jmp	.LBB0_12
	.p2align	4, 0x90
.LBB0_10:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_9 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	movups	(%eax,%edi,4), %xmm5
	movss	(%edx,%edi,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movaps	%xmm5, %xmm4
	andps	%xmm2, %xmm4
	cvtdq2ps	%xmm4, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm6
	movaps	%xmm5, %xmm4
	psrld	$8, %xmm4
	pand	%xmm2, %xmm4
	cvtdq2ps	%xmm4, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm7
	psrld	$16, %xmm5
	pand	%xmm2, %xmm5
	cvtdq2ps	%xmm5, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm3
	incl	%edi
	cmpl	%edi, %esi
	jne	.LBB0_10
	jmp	.LBB0_15
	.p2align	4, 0x90
.LBB0_14:                               #   in Loop: Header=BB0_12 Depth=4
	movss	(%edx,%edi,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	shufps	$0, %xmm0, %xmm0                # xmm0 = xmm0[0,0,0,0]
	movaps	%xmm4, %xmm5
	andps	%xmm2, %xmm5
	cvtdq2ps	%xmm5, %xmm5
	mulps	%xmm0, %xmm5
	addps	%xmm5, %xmm6
	movaps	%xmm4, %xmm5
	psrld	$8, %xmm5
	pand	%xmm2, %xmm5
	cvtdq2ps	%xmm5, %xmm5
	mulps	%xmm0, %xmm5
	addps	%xmm5, %xmm7
	psrld	$16, %xmm4
	pand	%xmm2, %xmm4
	cvtdq2ps	%xmm4, %xmm4
	mulps	%xmm0, %xmm4
	addps	%xmm4, %xmm3
	incl	%edi
	movaps	%xmm1, %xmm0
	cmpl	%edi, %esi
	je	.LBB0_15
.LBB0_12:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_9 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	movups	(%eax,%edi,4), %xmm4
	movaps	%xmm4, %xmm1
	cmpl	%edi, %ecx
	je	.LBB0_14
# %bb.13:                               #   in Loop: Header=BB0_12 Depth=4
	movaps	%xmm0, %xmm1
	jmp	.LBB0_14
	.p2align	4, 0x90
.LBB0_5:                                #   in Loop: Header=BB0_4 Depth=2
	xorps	%xmm6, %xmm6
	xorps	%xmm1, %xmm1
	xorps	%xmm7, %xmm7
	xorps	%xmm3, %xmm3
	xorps	%xmm5, %xmm5
	testl	%edx, %edx
	jne	.LBB0_25
	jmp	.LBB0_24
	.p2align	4, 0x90
.LBB0_16:                               #   in Loop: Header=BB0_4 Depth=2
	psrld	$24, %xmm1
	xorps	%xmm5, %xmm5
	jmp	.LBB0_22
.LBB0_17:                               #   in Loop: Header=BB0_4 Depth=2
	xorl	%eax, %eax
	xorps	%xmm5, %xmm5
	movl	88(%esp), %edx                   # 4-byte Reload
	movl	208(%esp), %ebp
	xorps	%xmm3, %xmm3
	xorps	%xmm7, %xmm7
	xorps	%xmm6, %xmm6
	.p2align	4, 0x90
.LBB0_18:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_19 Depth 4
	xorl	%edi, %edi
	.p2align	4, 0x90
.LBB0_19:                               #   Parent Loop BB0_3 Depth=1
                                        #     Parent Loop BB0_4 Depth=2
                                        #       Parent Loop BB0_18 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	movups	(%edx,%edi,4), %xmm0
	movss	(%ebp,%edi,4), %xmm4            # xmm4 = mem[0],zero,zero,zero
	shufps	$0, %xmm4, %xmm4                # xmm4 = xmm4[0,0,0,0]
	movaps	%xmm0, %xmm1
	andps	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm1
	mulps	%xmm4, %xmm1
	addps	%xmm1, %xmm6
	movaps	%xmm0, %xmm1
	psrld	$8, %xmm1
	pand	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm1
	mulps	%xmm4, %xmm1
	addps	%xmm1, %xmm7
	movaps	%xmm0, %xmm1
	psrld	$16, %xmm1
	pand	%xmm2, %xmm1
	cvtdq2ps	%xmm1, %xmm1
	mulps	%xmm4, %xmm1
	addps	%xmm1, %xmm3
	psrld	$24, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	mulps	%xmm4, %xmm0
	addps	%xmm0, %xmm5
	incl	%edi
	cmpl	%edi, %esi
	jne	.LBB0_19
# %bb.20:                               #   in Loop: Header=BB0_18 Depth=3
	incl	%eax
	addl	104(%esp), %ebp                 # 4-byte Folded Reload
	addl	%ebx, %edx
	cmpl	216(%esp), %eax
	jne	.LBB0_18
# %bb.21:                               #   in Loop: Header=BB0_4 Depth=2
	xorps	%xmm1, %xmm1
.LBB0_22:                               #   in Loop: Header=BB0_4 Depth=2
	movl	96(%esp), %ebp                  # 4-byte Reload
	movl	236(%esp), %edx
	movl	100(%esp), %edi                 # 4-byte Reload
	testl	%edx, %edx
	jne	.LBB0_25
.LBB0_24:                               #   in Loop: Header=BB0_4 Depth=2
	divps	128(%esp), %xmm5                # 16-byte Folded Reload
	addps	144(%esp), %xmm5                # 16-byte Folded Reload
	addps	16(%esp), %xmm5
	cvttps2dq	%xmm5, %xmm0
	cvtdq2ps	%xmm0, %xmm0
	cmpltps	%xmm0, %xmm5
	andps	32(%esp), %xmm5
	subps	%xmm5, %xmm0
	cvttps2dq	%xmm0, %xmm0
	movdqa	%xmm2, %xmm4
	pcmpgtd	%xmm0, %xmm4
	pand	%xmm4, %xmm0
	pandn	%xmm2, %xmm4
	por	%xmm0, %xmm4
	movdqa	%xmm4, %xmm1
	pcmpgtd	48(%esp), %xmm1
	pand	%xmm4, %xmm1
	jmp	.LBB0_25
.Lfunc_end0:
CFI_ENDPROC
SIZE(SYM(ksvgConvolveApplyInteriorSse2))
                                        # -- End function
	.ident	"clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)"
#ifndef __APPLE__
	.section	.note.GNU-stack,"",@progbits
	.addrsig
#endif
