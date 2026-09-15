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


	.text
	.file	"dm_avx512.cpp"
RODATA
	.p2align	6, 0x0                          # -- Begin function ksvgDisplacementMapApplyAvx512
.LCPI0_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
	.long	4                               # 0x4
	.long	5                               # 0x5
	.long	6                               # 0x6
	.long	7                               # 0x7
	.long	8                               # 0x8
	.long	9                               # 0x9
	.long	10                              # 0xa
	.long	11                              # 0xb
	.long	12                              # 0xc
	.long	13                              # 0xd
	.long	14                              # 0xe
	.long	15                              # 0xf
.LCPI0_4:
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
RODATA4
	.p2align	2, 0x0
.LCPI0_1:
	.long	0x437f0000                      # float 255
.LCPI0_2:
	.long	0xbf000000                      # float -0.5
.LCPI0_3:
	.long	16                              # 0x10
.LCPI0_5:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_9:
	.byte	255                             # 0xff
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_10:
	.byte	8                               # 0x8
	.byte	16                              # 0x10
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_11:
	.byte	16                              # 0x10
	.byte	8                               # 0x8
	.byte	0                               # 0x0
	.byte	0                               # 0x0
RODATA16
	.p2align	4, 0x0
.LCPI0_6:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI0_7:
	.long	8                               # 0x8
	.long	16                              # 0x10
	.zero	4
	.zero	4
.LCPI0_8:
	.long	16                              # 0x10
	.long	8                               # 0x8
	.zero	4
	.zero	4
.LCPI0_12:
	.byte	0                               # 0x0
	.byte	1                               # 0x1
	.byte	2                               # 0x2
	.byte	3                               # 0x3
	.byte	4                               # 0x4
	.byte	5                               # 0x5
	.byte	6                               # 0x6
	.byte	7                               # 0x7
	.byte	8                               # 0x8
	.byte	9                               # 0x9
	.byte	10                              # 0xa
	.byte	11                              # 0xb
	.byte	12                              # 0xc
	.byte	13                              # 0xd
	.byte	14                              # 0xe
	.byte	15                              # 0xf
	.text
	.globl	SYM(ksvgDisplacementMapApplyAvx512)
	.p2align	4, 0x90
	TYPE(SYM(ksvgDisplacementMapApplyAvx512), @function)
SYM(ksvgDisplacementMapApplyAvx512):     # @ksvgDisplacementMapApplyAvx512
	CFI_START
# %bb.0:
	pushq	%rbp
	CFI_DEF_CFA_OFFSET(16)
	pushq	%r15
	CFI_DEF_CFA_OFFSET(24)
	pushq	%r14
	CFI_DEF_CFA_OFFSET(32)
	pushq	%r13
	CFI_DEF_CFA_OFFSET(40)
	pushq	%r12
	CFI_DEF_CFA_OFFSET(48)
	pushq	%rbx
	CFI_DEF_CFA_OFFSET(56)
	CFI_OFFSET(%rbx, -56)
	CFI_OFFSET(%r12, -48)
	CFI_OFFSET(%r13, -40)
	CFI_OFFSET(%r14, -32)
	CFI_OFFSET(%r15, -24)
	CFI_OFFSET(%rbp, -16)
                                        # kill: def $r8d killed $r8d def $r8
                                        # kill: def $ecx killed $ecx def $rcx
	movq	%rcx, -16(%rsp)                 # 8-byte Spill
	movl	56(%rsp), %eax
	cmpq	$3, %rax
	ja	.LBB0_480
# %bb.1:
	leaq	.LJTI0_0(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_2:
	cmpl	$3, %r9d
	ja	.LBB0_480
# %bb.3:
	movl	%r9d, %eax
	leaq	.LJTI0_4(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_4:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.5:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %ecx
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_6
# %bb.20:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.21:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r11d
	leaq	(,%r10,4), %r8
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_22
	.p2align	4, 0x90
.LBB0_32:                               #   in Loop: Header=BB0_22 Depth=1
	incq	%rbx
	addq	%r8, %rdx
	addq	%r8, %rsi
	cmpq	%r11, %rbx
	je	.LBB0_480
.LBB0_22:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_23 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_23
	.p2align	4, 0x90
.LBB0_31:                               #   in Loop: Header=BB0_23 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_32
.LBB0_23:                               #   Parent Loop BB0_22 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	2(%rsi,%r14,4), %eax
	vcvtsi2ss	%eax, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r15d
	leal	(%r14,%r15), %r13d
	movl	%r13d, %eax
	cmpl	%ecx, %r13d
	jge	.LBB0_24
# %bb.25:                               #   in Loop: Header=BB0_23 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	jns	.LBB0_26
.LBB0_27:                               #   in Loop: Header=BB0_23 Depth=2
	addl	%ebx, %r15d
	movl	%r15d, %eax
	cmpl	%r9d, %r15d
	jge	.LBB0_28
.LBB0_29:                               #   in Loop: Header=BB0_23 Depth=2
	testl	%r15d, %r15d
	js	.LBB0_31
	jmp	.LBB0_30
	.p2align	4, 0x90
.LBB0_24:                               #   in Loop: Header=BB0_23 Depth=2
	movl	%ecx, %eax
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	js	.LBB0_27
.LBB0_26:                               #   in Loop: Header=BB0_23 Depth=2
	movl	%eax, %r12d
	addl	%ebx, %r15d
	movl	%r15d, %eax
	cmpl	%r9d, %r15d
	jl	.LBB0_29
.LBB0_28:                               #   in Loop: Header=BB0_23 Depth=2
	movl	%r9d, %eax
	testl	%r15d, %r15d
	js	.LBB0_31
.LBB0_30:                               #   in Loop: Header=BB0_23 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_31
.LBB0_242:
	cmpl	$3, %r9d
	ja	.LBB0_480
# %bb.243:
	movl	%r9d, %eax
	leaq	.LJTI0_2(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_244:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.245:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %r11d
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_246
# %bb.261:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.262:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rax
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_9(%rip), %xmm1   # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm4, %xmm4, %xmm4
	jmp	.LBB0_263
	.p2align	4, 0x90
.LBB0_273:                              #   in Loop: Header=BB0_263 Depth=1
	incq	%rbx
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_263:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_264 Depth 2
	vmovd	%ebx, %xmm5
	xorl	%r14d, %r14d
	jmp	.LBB0_264
	.p2align	4, 0x90
.LBB0_272:                              #   in Loop: Header=BB0_264 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_273
.LBB0_264:                              #   Parent Loop BB0_263 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %ecx
	vmovd	%ecx, %xmm6
	shrl	$16, %ecx
	vpinsrd	$1, %ecx, %xmm6, %xmm6
	vpand	%xmm1, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm2, %xmm6, %xmm6
	vaddps	%xmm3, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r14d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %r13d
	cmpl	%r11d, %r13d
	jl	.LBB0_266
# %bb.265:                              #   in Loop: Header=BB0_264 Depth=2
	movl	%r11d, %r13d
.LBB0_266:                              #   in Loop: Header=BB0_264 Depth=2
	vpcmpgtd	%zmm6, %zmm4, %k0
	kmovw	%k0, %r12d
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testb	$2, %r12b
	je	.LBB0_267
# %bb.268:                              #   in Loop: Header=BB0_264 Depth=2
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_269
.LBB0_270:                              #   in Loop: Header=BB0_264 Depth=2
	testb	$1, %r12b
	jne	.LBB0_272
	jmp	.LBB0_271
	.p2align	4, 0x90
.LBB0_267:                              #   in Loop: Header=BB0_264 Depth=2
	movl	%r13d, %r15d
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_270
.LBB0_269:                              #   in Loop: Header=BB0_264 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_272
.LBB0_271:                              #   in Loop: Header=BB0_264 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_272
.LBB0_362:
	cmpl	$3, %r9d
	ja	.LBB0_480
# %bb.363:
	movl	%r9d, %eax
	leaq	.LJTI0_1(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_364:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.365:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_366
# %bb.380:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.381:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_382
	.p2align	4, 0x90
.LBB0_392:                              #   in Loop: Header=BB0_382 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_382:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_383 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_383
	.p2align	4, 0x90
.LBB0_391:                              #   in Loop: Header=BB0_383 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_392
.LBB0_383:                              #   Parent Loop BB0_382 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %r12d
	movl	%r12d, %ecx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r13d
	addl	%r14d, %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jl	.LBB0_385
# %bb.384:                              #   in Loop: Header=BB0_383 Depth=2
	movl	%eax, %ecx
.LBB0_385:                              #   in Loop: Header=BB0_383 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r13d, %r13d
	js	.LBB0_387
# %bb.386:                              #   in Loop: Header=BB0_383 Depth=2
	movl	%ecx, %r15d
.LBB0_387:                              #   in Loop: Header=BB0_383 Depth=2
	shrl	$24, %r12d
	vcvtsi2ss	%r12d, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %ecx
	addl	%ebx, %ecx
	movl	%ecx, %r12d
	cmpl	%r9d, %ecx
	jl	.LBB0_389
# %bb.388:                              #   in Loop: Header=BB0_383 Depth=2
	movl	%r9d, %r12d
.LBB0_389:                              #   in Loop: Header=BB0_383 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_391
# %bb.390:                              #   in Loop: Header=BB0_383 Depth=2
	movl	%r12d, %ebp
	jmp	.LBB0_391
.LBB0_122:
	cmpl	$3, %r9d
	ja	.LBB0_480
# %bb.123:
	movl	%r9d, %eax
	leaq	.LJTI0_3(%rip), %rcx
	movslq	(%rcx,%rax,4), %rax
	addq	%rcx, %rax
	jmpq	*%rax
.LBB0_124:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.125:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %r11d
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_126
# %bb.141:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.142:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rax
	xorl	%ebx, %ebx
	vpmovsxbd	.LCPI0_10(%rip), %xmm1  # xmm1 = [8,16,0,0]
	vpmovzxbd	.LCPI0_9(%rip), %xmm2   # xmm2 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm3   # xmm3 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm4   # xmm4 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm5, %xmm5, %xmm5
	jmp	.LBB0_143
	.p2align	4, 0x90
.LBB0_153:                              #   in Loop: Header=BB0_143 Depth=1
	incq	%rbx
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_143:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_144 Depth 2
	vmovd	%ebx, %xmm6
	xorl	%r14d, %r14d
	jmp	.LBB0_144
	.p2align	4, 0x90
.LBB0_152:                              #   in Loop: Header=BB0_144 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_153
.LBB0_144:                              #   Parent Loop BB0_143 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpbroadcastd	(%rsi,%r14,4), %xmm7
	vpsrlvd	%xmm1, %xmm7, %xmm7
	vpand	%xmm2, %xmm7, %xmm7
	vcvtdq2ps	%xmm7, %xmm7
	vdivps	%xmm3, %xmm7, %xmm7
	vaddps	%xmm4, %xmm7, %xmm7
	vmulps	%xmm0, %xmm7, %xmm7
	vcvttps2dq	%xmm7, %xmm7
	vpinsrd	$1, %r14d, %xmm6, %xmm8
	vpaddd	%xmm7, %xmm8, %xmm7
	vpextrd	$1, %xmm7, %r13d
	cmpl	%r11d, %r13d
	jl	.LBB0_146
# %bb.145:                              #   in Loop: Header=BB0_144 Depth=2
	movl	%r11d, %r13d
.LBB0_146:                              #   in Loop: Header=BB0_144 Depth=2
	vpcmpgtd	%zmm7, %zmm5, %k0
	kmovw	%k0, %r12d
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testb	$2, %r12b
	je	.LBB0_147
# %bb.148:                              #   in Loop: Header=BB0_144 Depth=2
	vmovd	%xmm7, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_149
.LBB0_150:                              #   in Loop: Header=BB0_144 Depth=2
	testb	$1, %r12b
	jne	.LBB0_152
	jmp	.LBB0_151
	.p2align	4, 0x90
.LBB0_147:                              #   in Loop: Header=BB0_144 Depth=2
	movl	%r13d, %r15d
	vmovd	%xmm7, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_150
.LBB0_149:                              #   in Loop: Header=BB0_144 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_152
.LBB0_151:                              #   in Loop: Header=BB0_144 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_152
.LBB0_304:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.305:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_306
# %bb.320:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.321:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_322
	.p2align	4, 0x90
.LBB0_332:                              #   in Loop: Header=BB0_322 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_322:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_323 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_323
	.p2align	4, 0x90
.LBB0_331:                              #   in Loop: Header=BB0_323 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_332
.LBB0_323:                              #   Parent Loop BB0_322 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	(%rsi,%r14,4), %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r15d
	leal	(%r14,%r15), %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jge	.LBB0_324
# %bb.325:                              #   in Loop: Header=BB0_323 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	jns	.LBB0_326
.LBB0_327:                              #   in Loop: Header=BB0_323 Depth=2
	addl	%ebx, %r15d
	movl	%r15d, %ecx
	cmpl	%r9d, %r15d
	jge	.LBB0_328
.LBB0_329:                              #   in Loop: Header=BB0_323 Depth=2
	testl	%r15d, %r15d
	js	.LBB0_331
	jmp	.LBB0_330
	.p2align	4, 0x90
.LBB0_324:                              #   in Loop: Header=BB0_323 Depth=2
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	js	.LBB0_327
.LBB0_326:                              #   in Loop: Header=BB0_323 Depth=2
	movl	%ecx, %r12d
	addl	%ebx, %r15d
	movl	%r15d, %ecx
	cmpl	%r9d, %r15d
	jl	.LBB0_329
.LBB0_328:                              #   in Loop: Header=BB0_323 Depth=2
	movl	%r9d, %ecx
	testl	%r15d, %r15d
	js	.LBB0_331
.LBB0_330:                              #   in Loop: Header=BB0_323 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_331
.LBB0_333:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.334:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_335
# %bb.349:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.350:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_351
	.p2align	4, 0x90
.LBB0_361:                              #   in Loop: Header=BB0_351 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_351:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_352 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_352
	.p2align	4, 0x90
.LBB0_360:                              #   in Loop: Header=BB0_352 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_361
.LBB0_352:                              #   Parent Loop BB0_351 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %r12d
	movl	%r12d, %ecx
	shrl	$24, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r13d
	addl	%r14d, %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jl	.LBB0_354
# %bb.353:                              #   in Loop: Header=BB0_352 Depth=2
	movl	%eax, %ecx
.LBB0_354:                              #   in Loop: Header=BB0_352 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r13d, %r13d
	js	.LBB0_356
# %bb.355:                              #   in Loop: Header=BB0_352 Depth=2
	movl	%ecx, %r15d
.LBB0_356:                              #   in Loop: Header=BB0_352 Depth=2
	movzbl	%r12b, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %ecx
	addl	%ebx, %ecx
	movl	%ecx, %r12d
	cmpl	%r9d, %ecx
	jl	.LBB0_358
# %bb.357:                              #   in Loop: Header=BB0_352 Depth=2
	movl	%r9d, %r12d
.LBB0_358:                              #   in Loop: Header=BB0_352 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_360
# %bb.359:                              #   in Loop: Header=BB0_352 Depth=2
	movl	%r12d, %ebp
	jmp	.LBB0_360
.LBB0_422:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.423:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_424
# %bb.438:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.439:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_440
	.p2align	4, 0x90
.LBB0_450:                              #   in Loop: Header=BB0_440 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_440:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_441 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_441
	.p2align	4, 0x90
.LBB0_449:                              #   in Loop: Header=BB0_441 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_450
.LBB0_441:                              #   Parent Loop BB0_440 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %r12d
	movzbl	%r12b, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r13d
	addl	%r14d, %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jl	.LBB0_443
# %bb.442:                              #   in Loop: Header=BB0_441 Depth=2
	movl	%eax, %ecx
.LBB0_443:                              #   in Loop: Header=BB0_441 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r13d, %r13d
	js	.LBB0_445
# %bb.444:                              #   in Loop: Header=BB0_441 Depth=2
	movl	%ecx, %r15d
.LBB0_445:                              #   in Loop: Header=BB0_441 Depth=2
	shrl	$24, %r12d
	vcvtsi2ss	%r12d, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %ecx
	addl	%ebx, %ecx
	movl	%ecx, %r12d
	cmpl	%r9d, %ecx
	jl	.LBB0_447
# %bb.446:                              #   in Loop: Header=BB0_441 Depth=2
	movl	%r9d, %r12d
.LBB0_447:                              #   in Loop: Header=BB0_441 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_449
# %bb.448:                              #   in Loop: Header=BB0_441 Depth=2
	movl	%r12d, %ebp
	jmp	.LBB0_449
.LBB0_63:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.64:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %r11d
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_65
# %bb.80:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.81:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rax
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_9(%rip), %xmm1   # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm4, %xmm4, %xmm4
	jmp	.LBB0_82
	.p2align	4, 0x90
.LBB0_92:                               #   in Loop: Header=BB0_82 Depth=1
	incq	%rbx
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_82:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_83 Depth 2
	vmovd	%ebx, %xmm5
	xorl	%r14d, %r14d
	jmp	.LBB0_83
	.p2align	4, 0x90
.LBB0_91:                               #   in Loop: Header=BB0_83 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_92
.LBB0_83:                               #   Parent Loop BB0_82 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %ecx
	movl	%ecx, %ebp
	shrl	$16, %ebp
	vmovd	%ebp, %xmm6
	vpinsrd	$1, %ecx, %xmm6, %xmm6
	vpand	%xmm1, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm2, %xmm6, %xmm6
	vaddps	%xmm3, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r14d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %r13d
	cmpl	%r11d, %r13d
	jl	.LBB0_85
# %bb.84:                               #   in Loop: Header=BB0_83 Depth=2
	movl	%r11d, %r13d
.LBB0_85:                               #   in Loop: Header=BB0_83 Depth=2
	vpcmpgtd	%zmm6, %zmm4, %k0
	kmovw	%k0, %r12d
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testb	$2, %r12b
	je	.LBB0_86
# %bb.87:                               #   in Loop: Header=BB0_83 Depth=2
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_88
.LBB0_89:                               #   in Loop: Header=BB0_83 Depth=2
	testb	$1, %r12b
	jne	.LBB0_91
	jmp	.LBB0_90
	.p2align	4, 0x90
.LBB0_86:                               #   in Loop: Header=BB0_83 Depth=2
	movl	%r13d, %r15d
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_89
.LBB0_88:                               #   in Loop: Header=BB0_83 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_91
.LBB0_90:                               #   in Loop: Header=BB0_83 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_91
.LBB0_274:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.275:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %r11d
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_276
# %bb.291:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.292:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rax
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_9(%rip), %xmm1   # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm4, %xmm4, %xmm4
	jmp	.LBB0_293
	.p2align	4, 0x90
.LBB0_303:                              #   in Loop: Header=BB0_293 Depth=1
	incq	%rbx
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_293:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_294 Depth 2
	vmovd	%ebx, %xmm5
	xorl	%r14d, %r14d
	jmp	.LBB0_294
	.p2align	4, 0x90
.LBB0_302:                              #   in Loop: Header=BB0_294 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_303
.LBB0_294:                              #   Parent Loop BB0_293 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %ecx
	vmovd	%ecx, %xmm6
	shrl	$8, %ecx
	vpinsrd	$1, %ecx, %xmm6, %xmm6
	vpand	%xmm1, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm2, %xmm6, %xmm6
	vaddps	%xmm3, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r14d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %r13d
	cmpl	%r11d, %r13d
	jl	.LBB0_296
# %bb.295:                              #   in Loop: Header=BB0_294 Depth=2
	movl	%r11d, %r13d
.LBB0_296:                              #   in Loop: Header=BB0_294 Depth=2
	vpcmpgtd	%zmm6, %zmm4, %k0
	kmovw	%k0, %r12d
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testb	$2, %r12b
	je	.LBB0_297
# %bb.298:                              #   in Loop: Header=BB0_294 Depth=2
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_299
.LBB0_300:                              #   in Loop: Header=BB0_294 Depth=2
	testb	$1, %r12b
	jne	.LBB0_302
	jmp	.LBB0_301
	.p2align	4, 0x90
.LBB0_297:                              #   in Loop: Header=BB0_294 Depth=2
	movl	%r13d, %r15d
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_300
.LBB0_299:                              #   in Loop: Header=BB0_294 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_302
.LBB0_301:                              #   in Loop: Header=BB0_294 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_302
.LBB0_183:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.184:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %r11d
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_185
# %bb.200:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.201:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rax
	xorl	%ebx, %ebx
	vpmovzxbd	.LCPI0_9(%rip), %xmm1   # xmm1 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm2   # xmm2 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm3   # xmm3 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm4, %xmm4, %xmm4
	jmp	.LBB0_202
	.p2align	4, 0x90
.LBB0_212:                              #   in Loop: Header=BB0_202 Depth=1
	incq	%rbx
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_202:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_203 Depth 2
	vmovd	%ebx, %xmm5
	xorl	%r14d, %r14d
	jmp	.LBB0_203
	.p2align	4, 0x90
.LBB0_211:                              #   in Loop: Header=BB0_203 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_212
.LBB0_203:                              #   Parent Loop BB0_202 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %ecx
	movl	%ecx, %ebp
	shrl	$8, %ebp
	vmovd	%ebp, %xmm6
	vpinsrd	$1, %ecx, %xmm6, %xmm6
	vpand	%xmm1, %xmm6, %xmm6
	vcvtdq2ps	%xmm6, %xmm6
	vdivps	%xmm2, %xmm6, %xmm6
	vaddps	%xmm3, %xmm6, %xmm6
	vmulps	%xmm0, %xmm6, %xmm6
	vcvttps2dq	%xmm6, %xmm6
	vpinsrd	$1, %r14d, %xmm5, %xmm7
	vpaddd	%xmm6, %xmm7, %xmm6
	vpextrd	$1, %xmm6, %r13d
	cmpl	%r11d, %r13d
	jl	.LBB0_205
# %bb.204:                              #   in Loop: Header=BB0_203 Depth=2
	movl	%r11d, %r13d
.LBB0_205:                              #   in Loop: Header=BB0_203 Depth=2
	vpcmpgtd	%zmm6, %zmm4, %k0
	kmovw	%k0, %r12d
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testb	$2, %r12b
	je	.LBB0_206
# %bb.207:                              #   in Loop: Header=BB0_203 Depth=2
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_208
.LBB0_209:                              #   in Loop: Header=BB0_203 Depth=2
	testb	$1, %r12b
	jne	.LBB0_211
	jmp	.LBB0_210
	.p2align	4, 0x90
.LBB0_206:                              #   in Loop: Header=BB0_203 Depth=2
	movl	%r13d, %r15d
	vmovd	%xmm6, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_209
.LBB0_208:                              #   in Loop: Header=BB0_203 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_211
.LBB0_210:                              #   in Loop: Header=BB0_203 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_211
.LBB0_451:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.452:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_453
# %bb.467:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.468:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_469
	.p2align	4, 0x90
.LBB0_479:                              #   in Loop: Header=BB0_469 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_469:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_470 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_470
	.p2align	4, 0x90
.LBB0_478:                              #   in Loop: Header=BB0_470 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_479
.LBB0_470:                              #   Parent Loop BB0_469 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	3(%rsi,%r14,4), %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r15d
	leal	(%r14,%r15), %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jge	.LBB0_471
# %bb.472:                              #   in Loop: Header=BB0_470 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	jns	.LBB0_473
.LBB0_474:                              #   in Loop: Header=BB0_470 Depth=2
	addl	%ebx, %r15d
	movl	%r15d, %ecx
	cmpl	%r9d, %r15d
	jge	.LBB0_475
.LBB0_476:                              #   in Loop: Header=BB0_470 Depth=2
	testl	%r15d, %r15d
	js	.LBB0_478
	jmp	.LBB0_477
	.p2align	4, 0x90
.LBB0_471:                              #   in Loop: Header=BB0_470 Depth=2
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	js	.LBB0_474
.LBB0_473:                              #   in Loop: Header=BB0_470 Depth=2
	movl	%ecx, %r12d
	addl	%ebx, %r15d
	movl	%r15d, %ecx
	cmpl	%r9d, %r15d
	jl	.LBB0_476
.LBB0_475:                              #   in Loop: Header=BB0_470 Depth=2
	movl	%r9d, %ecx
	testl	%r15d, %r15d
	js	.LBB0_478
.LBB0_477:                              #   in Loop: Header=BB0_470 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_478
.LBB0_93:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.94:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_95
# %bb.109:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.110:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_111
	.p2align	4, 0x90
.LBB0_121:                              #   in Loop: Header=BB0_111 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_111:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_112 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_112
	.p2align	4, 0x90
.LBB0_120:                              #   in Loop: Header=BB0_112 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_121
.LBB0_112:                              #   Parent Loop BB0_111 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %r12d
	movl	%r12d, %ecx
	shrl	$24, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r13d
	addl	%r14d, %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jl	.LBB0_114
# %bb.113:                              #   in Loop: Header=BB0_112 Depth=2
	movl	%eax, %ecx
.LBB0_114:                              #   in Loop: Header=BB0_112 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r13d, %r13d
	js	.LBB0_116
# %bb.115:                              #   in Loop: Header=BB0_112 Depth=2
	movl	%ecx, %r15d
.LBB0_116:                              #   in Loop: Header=BB0_112 Depth=2
	shrl	$16, %r12d
	movzbl	%r12b, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %ecx
	addl	%ebx, %ecx
	movl	%ecx, %r12d
	cmpl	%r9d, %ecx
	jl	.LBB0_118
# %bb.117:                              #   in Loop: Header=BB0_112 Depth=2
	movl	%r9d, %r12d
.LBB0_118:                              #   in Loop: Header=BB0_112 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_120
# %bb.119:                              #   in Loop: Header=BB0_112 Depth=2
	movl	%r12d, %ebp
	jmp	.LBB0_120
.LBB0_393:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.394:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %r13d
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_395
# %bb.409:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.410:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_411
	.p2align	4, 0x90
.LBB0_421:                              #   in Loop: Header=BB0_411 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_411:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_412 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_412
	.p2align	4, 0x90
.LBB0_420:                              #   in Loop: Header=BB0_412 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_421
.LBB0_412:                              #   Parent Loop BB0_411 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %eax
	movzbl	%ah, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r12d
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r13d, %r12d
	jl	.LBB0_414
# %bb.413:                              #   in Loop: Header=BB0_412 Depth=2
	movl	%r13d, %ecx
.LBB0_414:                              #   in Loop: Header=BB0_412 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r12d, %r12d
	js	.LBB0_416
# %bb.415:                              #   in Loop: Header=BB0_412 Depth=2
	movl	%ecx, %r15d
.LBB0_416:                              #   in Loop: Header=BB0_412 Depth=2
	shrl	$24, %eax
	vcvtsi2ss	%eax, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %eax
	addl	%ebx, %eax
	movl	%eax, %ecx
	cmpl	%r9d, %eax
	jl	.LBB0_418
# %bb.417:                              #   in Loop: Header=BB0_412 Depth=2
	movl	%r9d, %ecx
.LBB0_418:                              #   in Loop: Header=BB0_412 Depth=2
	testl	%eax, %eax
	js	.LBB0_420
# %bb.419:                              #   in Loop: Header=BB0_412 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_420
.LBB0_213:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.214:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %r13d
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_215
# %bb.229:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.230:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_231
	.p2align	4, 0x90
.LBB0_241:                              #   in Loop: Header=BB0_231 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_231:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_232 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_232
	.p2align	4, 0x90
.LBB0_240:                              #   in Loop: Header=BB0_232 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_241
.LBB0_232:                              #   Parent Loop BB0_231 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r14,4), %eax
	movl	%eax, %ecx
	shrl	$24, %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r12d
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r13d, %r12d
	jl	.LBB0_234
# %bb.233:                              #   in Loop: Header=BB0_232 Depth=2
	movl	%r13d, %ecx
.LBB0_234:                              #   in Loop: Header=BB0_232 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testl	%r12d, %r12d
	js	.LBB0_236
# %bb.235:                              #   in Loop: Header=BB0_232 Depth=2
	movl	%ecx, %r15d
.LBB0_236:                              #   in Loop: Header=BB0_232 Depth=2
	movzbl	%ah, %eax
	vcvtsi2ss	%eax, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %eax
	addl	%ebx, %eax
	movl	%eax, %ecx
	cmpl	%r9d, %eax
	jl	.LBB0_238
# %bb.237:                              #   in Loop: Header=BB0_232 Depth=2
	movl	%r9d, %ecx
.LBB0_238:                              #   in Loop: Header=BB0_232 Depth=2
	testl	%eax, %eax
	js	.LBB0_240
# %bb.239:                              #   in Loop: Header=BB0_232 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_240
.LBB0_33:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.34:
	movq	-16(%rsp), %rax                 # 8-byte Reload
	leal	-1(%rax), %r11d
	leal	-1(%r8), %r9d
	cmpl	$16, %eax
	jge	.LBB0_35
# %bb.50:
	testl	%eax, %eax
	jle	.LBB0_480
# %bb.51:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rax
	xorl	%ebx, %ebx
	vpmovsxbd	.LCPI0_11(%rip), %xmm1  # xmm1 = [16,8,0,0]
	vpmovzxbd	.LCPI0_9(%rip), %xmm2   # xmm2 = [255,255,0,0]
	vbroadcastss	.LCPI0_1(%rip), %xmm3   # xmm3 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm4   # xmm4 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm5, %xmm5, %xmm5
	jmp	.LBB0_52
	.p2align	4, 0x90
.LBB0_62:                               #   in Loop: Header=BB0_52 Depth=1
	incq	%rbx
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_52:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_53 Depth 2
	vmovd	%ebx, %xmm6
	xorl	%r14d, %r14d
	jmp	.LBB0_53
	.p2align	4, 0x90
.LBB0_61:                               #   in Loop: Header=BB0_53 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r15d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_62
.LBB0_53:                               #   Parent Loop BB0_52 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpbroadcastd	(%rsi,%r14,4), %xmm7
	vpsrlvd	%xmm1, %xmm7, %xmm7
	vpand	%xmm2, %xmm7, %xmm7
	vcvtdq2ps	%xmm7, %xmm7
	vdivps	%xmm3, %xmm7, %xmm7
	vaddps	%xmm4, %xmm7, %xmm7
	vmulps	%xmm0, %xmm7, %xmm7
	vcvttps2dq	%xmm7, %xmm7
	vpinsrd	$1, %r14d, %xmm6, %xmm8
	vpaddd	%xmm7, %xmm8, %xmm7
	vpextrd	$1, %xmm7, %r13d
	cmpl	%r11d, %r13d
	jl	.LBB0_55
# %bb.54:                               #   in Loop: Header=BB0_53 Depth=2
	movl	%r11d, %r13d
.LBB0_55:                               #   in Loop: Header=BB0_53 Depth=2
	vpcmpgtd	%zmm7, %zmm5, %k0
	kmovw	%k0, %r12d
	xorl	%ebp, %ebp
	movl	$0, %r15d
	testb	$2, %r12b
	je	.LBB0_56
# %bb.57:                               #   in Loop: Header=BB0_53 Depth=2
	vmovd	%xmm7, %ecx
	cmpl	%r9d, %ecx
	jge	.LBB0_58
.LBB0_59:                               #   in Loop: Header=BB0_53 Depth=2
	testb	$1, %r12b
	jne	.LBB0_61
	jmp	.LBB0_60
	.p2align	4, 0x90
.LBB0_56:                               #   in Loop: Header=BB0_53 Depth=2
	movl	%r13d, %r15d
	vmovd	%xmm7, %ecx
	cmpl	%r9d, %ecx
	jl	.LBB0_59
.LBB0_58:                               #   in Loop: Header=BB0_53 Depth=2
	movl	%r9d, %ecx
	testb	$1, %r12b
	jne	.LBB0_61
.LBB0_60:                               #   in Loop: Header=BB0_53 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_61
.LBB0_154:
	testl	%r8d, %r8d
	jle	.LBB0_480
# %bb.155:
	movq	-16(%rsp), %r11                 # 8-byte Reload
	leal	-1(%r11), %eax
	leal	-1(%r8), %r9d
	cmpl	$16, %r11d
	jge	.LBB0_156
# %bb.170:
	testl	%r11d, %r11d
	jle	.LBB0_480
# %bb.171:
	movl	-16(%rsp), %r10d                # 4-byte Reload
	movl	%r8d, %r8d
	leaq	(,%r10,4), %r11
	xorl	%ebx, %ebx
	vmovss	.LCPI0_1(%rip), %xmm1           # xmm1 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm2           # xmm2 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_172
	.p2align	4, 0x90
.LBB0_182:                              #   in Loop: Header=BB0_172 Depth=1
	incq	%rbx
	addq	%r11, %rdx
	addq	%r11, %rsi
	cmpq	%r8, %rbx
	je	.LBB0_480
.LBB0_172:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_173 Depth 2
	xorl	%r14d, %r14d
	jmp	.LBB0_173
	.p2align	4, 0x90
.LBB0_181:                              #   in Loop: Header=BB0_173 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r14,4)
	incq	%r14
	cmpq	%r14, %r10
	je	.LBB0_182
.LBB0_173:                              #   Parent Loop BB0_172 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	1(%rsi,%r14,4), %ecx
	vcvtsi2ss	%ecx, %xmm4, %xmm3
	vdivss	%xmm1, %xmm3, %xmm3
	vaddss	%xmm2, %xmm3, %xmm3
	vmulss	%xmm0, %xmm3, %xmm3
	vcvttss2si	%xmm3, %r15d
	leal	(%r14,%r15), %r13d
	movl	%r13d, %ecx
	cmpl	%eax, %r13d
	jge	.LBB0_174
# %bb.175:                              #   in Loop: Header=BB0_173 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	jns	.LBB0_176
.LBB0_177:                              #   in Loop: Header=BB0_173 Depth=2
	addl	%ebx, %r15d
	movl	%r15d, %ecx
	cmpl	%r9d, %r15d
	jge	.LBB0_178
.LBB0_179:                              #   in Loop: Header=BB0_173 Depth=2
	testl	%r15d, %r15d
	js	.LBB0_181
	jmp	.LBB0_180
	.p2align	4, 0x90
.LBB0_174:                              #   in Loop: Header=BB0_173 Depth=2
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r13d, %r13d
	js	.LBB0_177
.LBB0_176:                              #   in Loop: Header=BB0_173 Depth=2
	movl	%ecx, %r12d
	addl	%ebx, %r15d
	movl	%r15d, %ecx
	cmpl	%r9d, %r15d
	jl	.LBB0_179
.LBB0_178:                              #   in Loop: Header=BB0_173 Depth=2
	movl	%r9d, %ecx
	testl	%r15d, %r15d
	js	.LBB0_181
.LBB0_180:                              #   in Loop: Header=BB0_173 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_181
.LBB0_306:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpbroadcastd	.LCPI0_5(%rip), %zmm7   # zmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_307
	.p2align	4, 0x90
.LBB0_319:                              #   in Loop: Header=BB0_307 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_307:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_308 Depth 2
                                        #     Child Loop BB0_310 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_308:                              #   Parent Loop BB0_307 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpandq	-64(%rsi,%r15,4), %zmm7, %zmm15
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vaddps	%zmm8, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm14, %zmm15, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpaddd	%zmm13, %zmm15, %zmm15
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	vpxord	%zmm16, %zmm16, %zmm16
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_308
# %bb.309:                              #   in Loop: Header=BB0_307 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_310
	jmp	.LBB0_319
	.p2align	4, 0x90
.LBB0_318:                              #   in Loop: Header=BB0_310 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r13d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_319
.LBB0_310:                              #   Parent Loop BB0_307 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	(%rsi,%r15,4), %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r12d
	leal	(%r15,%r12), %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jge	.LBB0_311
# %bb.312:                              #   in Loop: Header=BB0_310 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	jns	.LBB0_313
.LBB0_314:                              #   in Loop: Header=BB0_310 Depth=2
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r9d, %r12d
	jge	.LBB0_315
.LBB0_316:                              #   in Loop: Header=BB0_310 Depth=2
	testl	%r12d, %r12d
	js	.LBB0_318
	jmp	.LBB0_317
	.p2align	4, 0x90
.LBB0_311:                              #   in Loop: Header=BB0_310 Depth=2
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	js	.LBB0_314
.LBB0_313:                              #   in Loop: Header=BB0_310 Depth=2
	movl	%ecx, %r13d
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r9d, %r12d
	jl	.LBB0_316
.LBB0_315:                              #   in Loop: Header=BB0_310 Depth=2
	movl	%r9d, %ecx
	testl	%r12d, %r12d
	js	.LBB0_318
.LBB0_317:                              #   in Loop: Header=BB0_310 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_318
.LBB0_335:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpbroadcastd	.LCPI0_5(%rip), %zmm8   # zmm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_336
	.p2align	4, 0x90
.LBB0_348:                              #   in Loop: Header=BB0_336 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_336:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_337 Depth 2
                                        #     Child Loop BB0_339 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_337:                              #   Parent Loop BB0_336 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm15
	vpsrld	$24, %zmm15, %zmm16
	vcvtdq2ps	%zmm16, %zmm16
	vdivps	%zmm6, %zmm16, %zmm16
	vaddps	%zmm7, %zmm16, %zmm16
	vpandq	%zmm8, %zmm15, %zmm15
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vmulps	%zmm16, %zmm1, %zmm16
	vaddps	%zmm7, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm16, %zmm16
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm13, %zmm15, %zmm15
	vpaddd	%zmm14, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	vpxord	%zmm16, %zmm16, %zmm16
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_337
# %bb.338:                              #   in Loop: Header=BB0_336 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_339
	jmp	.LBB0_348
	.p2align	4, 0x90
.LBB0_347:                              #   in Loop: Header=BB0_339 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_348
.LBB0_339:                              #   Parent Loop BB0_336 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %r13d
	movl	%r13d, %ecx
	shrl	$24, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r8d
	addl	%r15d, %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jl	.LBB0_341
# %bb.340:                              #   in Loop: Header=BB0_339 Depth=2
	movl	%eax, %ecx
.LBB0_341:                              #   in Loop: Header=BB0_339 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r8d, %r8d
	js	.LBB0_343
# %bb.342:                              #   in Loop: Header=BB0_339 Depth=2
	movl	%ecx, %r12d
.LBB0_343:                              #   in Loop: Header=BB0_339 Depth=2
	movzbl	%r13b, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %ecx
	addl	%r14d, %ecx
	movl	%ecx, %r8d
	cmpl	%r9d, %ecx
	jl	.LBB0_345
# %bb.344:                              #   in Loop: Header=BB0_339 Depth=2
	movl	%r9d, %r8d
.LBB0_345:                              #   in Loop: Header=BB0_339 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_347
# %bb.346:                              #   in Loop: Header=BB0_339 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_347
.LBB0_424:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpbroadcastd	.LCPI0_5(%rip), %zmm7   # zmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_425
	.p2align	4, 0x90
.LBB0_437:                              #   in Loop: Header=BB0_425 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_425:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_426 Depth 2
                                        #     Child Loop BB0_428 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_426:                              #   Parent Loop BB0_425 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm15
	vpsrld	$24, %zmm15, %zmm16
	vpandq	%zmm7, %zmm15, %zmm15
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vaddps	%zmm8, %zmm15, %zmm15
	vcvtdq2ps	%zmm16, %zmm16
	vdivps	%zmm6, %zmm16, %zmm16
	vmulps	%zmm15, %zmm1, %zmm15
	vaddps	%zmm8, %zmm16, %zmm16
	vmulps	%zmm16, %zmm1, %zmm16
	vcvttps2dq	%zmm15, %zmm15
	vcvttps2dq	%zmm16, %zmm16
	vpaddd	%zmm13, %zmm16, %zmm16
	vpaddd	%zmm14, %zmm15, %zmm15
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm2, %zmm15, %zmm15
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm3, %zmm16, %zmm16
	vpmulld	%zmm4, %zmm16, %zmm16
	vpaddd	%zmm15, %zmm16, %zmm15
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm16, %zmm16, %zmm16
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_426
# %bb.427:                              #   in Loop: Header=BB0_425 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_428
	jmp	.LBB0_437
	.p2align	4, 0x90
.LBB0_436:                              #   in Loop: Header=BB0_428 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_437
.LBB0_428:                              #   Parent Loop BB0_425 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %r13d
	movzbl	%r13b, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r8d
	addl	%r15d, %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jl	.LBB0_430
# %bb.429:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%eax, %ecx
.LBB0_430:                              #   in Loop: Header=BB0_428 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r8d, %r8d
	js	.LBB0_432
# %bb.431:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%ecx, %r12d
.LBB0_432:                              #   in Loop: Header=BB0_428 Depth=2
	shrl	$24, %r13d
	vcvtsi2ss	%r13d, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %ecx
	addl	%r14d, %ecx
	movl	%ecx, %r8d
	cmpl	%r9d, %ecx
	jl	.LBB0_434
# %bb.433:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%r9d, %r8d
.LBB0_434:                              #   in Loop: Header=BB0_428 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_436
# %bb.435:                              #   in Loop: Header=BB0_428 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_436
.LBB0_246:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r11d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_5(%rip), %zmm5   # zmm5 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpmovsxbd	.LCPI0_12(%rip), %zmm17 # zmm17 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm13  # xmm13 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm14, %xmm14, %xmm14
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jmp	.LBB0_247
	.p2align	4, 0x90
.LBB0_260:                              #   in Loop: Header=BB0_247 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	%r8, %r14
	je	.LBB0_480
.LBB0_247:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_248 Depth 2
                                        #     Child Loop BB0_251 Depth 2
	vpbroadcastd	%r14d, %zmm15
	movl	$16, %r15d
	vmovdqa64	%zmm17, %zmm16
	.p2align	4, 0x90
.LBB0_248:                              #   Parent Loop BB0_247 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm8
	vpsrld	$16, %zmm8, %zmm18
	vpandd	%zmm5, %zmm18, %zmm18
	vcvtdq2ps	%zmm18, %zmm18
	vdivps	%zmm6, %zmm18, %zmm18
	vaddps	%zmm7, %zmm18, %zmm18
	vpandq	%zmm5, %zmm8, %zmm8
	vcvtdq2ps	%zmm8, %zmm8
	vdivps	%zmm6, %zmm8, %zmm8
	vmulps	%zmm18, %zmm1, %zmm18
	vaddps	%zmm7, %zmm8, %zmm8
	vmulps	%zmm8, %zmm1, %zmm8
	vcvttps2dq	%zmm18, %zmm18
	vcvttps2dq	%zmm8, %zmm8
	vpaddd	%zmm15, %zmm8, %zmm8
	vpaddd	%zmm16, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm18, %zmm18
	vpminsd	%zmm2, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm8, %zmm8
	vpminsd	%zmm3, %zmm8, %zmm8
	vpmulld	%zmm4, %zmm8, %zmm8
	vpaddd	%zmm18, %zmm8, %zmm8
	vpxord	%zmm18, %zmm18, %zmm18
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm8,4), %zmm18 {%k1}
	vmovdqu64	%zmm18, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm16, %zmm16
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_248
# %bb.249:                              #   in Loop: Header=BB0_247 Depth=1
	cmpl	%ecx, -8(%rsp)                  # 4-byte Folded Reload
	je	.LBB0_260
# %bb.250:                              #   in Loop: Header=BB0_247 Depth=1
	vmovd	%r14d, %xmm15
	movq	-8(%rsp), %r15                  # 8-byte Reload
	jmp	.LBB0_251
	.p2align	4, 0x90
.LBB0_259:                              #   in Loop: Header=BB0_251 Depth=2
	imull	%ecx, %ebp
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_260
.LBB0_251:                              #   Parent Loop BB0_247 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %eax
	vmovd	%eax, %xmm8
	shrl	$16, %eax
	vpinsrd	$1, %eax, %xmm8, %xmm8
	vpand	.LCPI0_6(%rip), %xmm8, %xmm8
	vcvtdq2ps	%xmm8, %xmm8
	vdivps	%xmm12, %xmm8, %xmm8
	vaddps	%xmm13, %xmm8, %xmm8
	vmulps	%xmm0, %xmm8, %xmm8
	vcvttps2dq	%xmm8, %xmm8
	vpinsrd	$1, %r15d, %xmm15, %xmm11
	vpaddd	%xmm8, %xmm11, %xmm8
	vpextrd	$1, %xmm8, %eax
	cmpl	%r11d, %eax
	jl	.LBB0_253
# %bb.252:                              #   in Loop: Header=BB0_251 Depth=2
	movl	%r11d, %eax
.LBB0_253:                              #   in Loop: Header=BB0_251 Depth=2
	vpcmpgtd	%zmm8, %zmm14, %k0
	kmovw	%k0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testb	$2, %r13b
	je	.LBB0_254
# %bb.255:                              #   in Loop: Header=BB0_251 Depth=2
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_256
.LBB0_257:                              #   in Loop: Header=BB0_251 Depth=2
	testb	$1, %r13b
	jne	.LBB0_259
	jmp	.LBB0_258
	.p2align	4, 0x90
.LBB0_254:                              #   in Loop: Header=BB0_251 Depth=2
	movl	%eax, %r12d
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_257
.LBB0_256:                              #   in Loop: Header=BB0_251 Depth=2
	movl	%r9d, %eax
	testb	$1, %r13b
	jne	.LBB0_259
.LBB0_258:                              #   in Loop: Header=BB0_251 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_259
.LBB0_65:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r11d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_5(%rip), %zmm5   # zmm5 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpmovsxbd	.LCPI0_12(%rip), %zmm17 # zmm17 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm13  # xmm13 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm14, %xmm14, %xmm14
	jmp	.LBB0_66
	.p2align	4, 0x90
.LBB0_79:                               #   in Loop: Header=BB0_66 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	%r8, %r14
	je	.LBB0_480
.LBB0_66:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_67 Depth 2
                                        #     Child Loop BB0_70 Depth 2
	vpbroadcastd	%r14d, %zmm15
	movl	$16, %r15d
	vmovdqa64	%zmm17, %zmm16
	.p2align	4, 0x90
.LBB0_67:                               #   Parent Loop BB0_66 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm8
	vpandq	%zmm5, %zmm8, %zmm18
	vcvtdq2ps	%zmm18, %zmm18
	vdivps	%zmm6, %zmm18, %zmm18
	vpsrld	$16, %zmm8, %zmm8
	vaddps	%zmm7, %zmm18, %zmm18
	vpandd	%zmm5, %zmm8, %zmm8
	vcvtdq2ps	%zmm8, %zmm8
	vdivps	%zmm6, %zmm8, %zmm8
	vmulps	%zmm18, %zmm1, %zmm18
	vaddps	%zmm7, %zmm8, %zmm8
	vmulps	%zmm8, %zmm1, %zmm8
	vcvttps2dq	%zmm18, %zmm18
	vcvttps2dq	%zmm8, %zmm8
	vpaddd	%zmm15, %zmm8, %zmm8
	vpaddd	%zmm16, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm18, %zmm18
	vpminsd	%zmm2, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm8, %zmm8
	vpminsd	%zmm3, %zmm8, %zmm8
	vpmulld	%zmm4, %zmm8, %zmm8
	vpaddd	%zmm18, %zmm8, %zmm8
	vpxord	%zmm18, %zmm18, %zmm18
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm8,4), %zmm18 {%k1}
	vmovdqu64	%zmm18, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm16, %zmm16
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_67
# %bb.68:                               #   in Loop: Header=BB0_66 Depth=1
	movq	-8(%rsp), %rax                  # 8-byte Reload
	cmpl	-16(%rsp), %eax                 # 4-byte Folded Reload
	je	.LBB0_79
# %bb.69:                               #   in Loop: Header=BB0_66 Depth=1
	vmovd	%r14d, %xmm15
	movq	-8(%rsp), %r15                  # 8-byte Reload
	jmp	.LBB0_70
	.p2align	4, 0x90
.LBB0_78:                               #   in Loop: Header=BB0_70 Depth=2
	imull	%ecx, %ebp
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_79
.LBB0_70:                               #   Parent Loop BB0_66 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %eax
	movl	%eax, %ecx
	shrl	$16, %ecx
	vmovd	%ecx, %xmm8
	vpinsrd	$1, %eax, %xmm8, %xmm8
	vpand	.LCPI0_6(%rip), %xmm8, %xmm8
	vcvtdq2ps	%xmm8, %xmm8
	vdivps	%xmm12, %xmm8, %xmm8
	vaddps	%xmm13, %xmm8, %xmm8
	vmulps	%xmm0, %xmm8, %xmm8
	vcvttps2dq	%xmm8, %xmm8
	vpinsrd	$1, %r15d, %xmm15, %xmm11
	vpaddd	%xmm8, %xmm11, %xmm8
	vpextrd	$1, %xmm8, %eax
	cmpl	%r11d, %eax
	jl	.LBB0_72
# %bb.71:                               #   in Loop: Header=BB0_70 Depth=2
	movl	%r11d, %eax
.LBB0_72:                               #   in Loop: Header=BB0_70 Depth=2
	vpcmpgtd	%zmm8, %zmm14, %k0
	kmovw	%k0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testb	$2, %r13b
	je	.LBB0_73
# %bb.74:                               #   in Loop: Header=BB0_70 Depth=2
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jge	.LBB0_75
.LBB0_76:                               #   in Loop: Header=BB0_70 Depth=2
	testb	$1, %r13b
	jne	.LBB0_78
	jmp	.LBB0_77
	.p2align	4, 0x90
.LBB0_73:                               #   in Loop: Header=BB0_70 Depth=2
	movl	%eax, %r12d
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jl	.LBB0_76
.LBB0_75:                               #   in Loop: Header=BB0_70 Depth=2
	movl	%r9d, %eax
	testb	$1, %r13b
	jne	.LBB0_78
.LBB0_77:                               #   in Loop: Header=BB0_70 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_78
.LBB0_276:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r11d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_5(%rip), %zmm5   # zmm5 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpmovsxbd	.LCPI0_12(%rip), %zmm17 # zmm17 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm13  # xmm13 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm14, %xmm14, %xmm14
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jmp	.LBB0_277
	.p2align	4, 0x90
.LBB0_290:                              #   in Loop: Header=BB0_277 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	%r8, %r14
	je	.LBB0_480
.LBB0_277:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_278 Depth 2
                                        #     Child Loop BB0_281 Depth 2
	vpbroadcastd	%r14d, %zmm15
	movl	$16, %r15d
	vmovdqa64	%zmm17, %zmm16
	.p2align	4, 0x90
.LBB0_278:                              #   Parent Loop BB0_277 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm8
	vpsrld	$8, %zmm8, %zmm18
	vpandd	%zmm5, %zmm18, %zmm18
	vcvtdq2ps	%zmm18, %zmm18
	vdivps	%zmm6, %zmm18, %zmm18
	vaddps	%zmm7, %zmm18, %zmm18
	vpandq	%zmm5, %zmm8, %zmm8
	vcvtdq2ps	%zmm8, %zmm8
	vdivps	%zmm6, %zmm8, %zmm8
	vmulps	%zmm18, %zmm1, %zmm18
	vaddps	%zmm7, %zmm8, %zmm8
	vmulps	%zmm8, %zmm1, %zmm8
	vcvttps2dq	%zmm18, %zmm18
	vcvttps2dq	%zmm8, %zmm8
	vpaddd	%zmm15, %zmm8, %zmm8
	vpaddd	%zmm16, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm18, %zmm18
	vpminsd	%zmm2, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm8, %zmm8
	vpminsd	%zmm3, %zmm8, %zmm8
	vpmulld	%zmm4, %zmm8, %zmm8
	vpaddd	%zmm18, %zmm8, %zmm8
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm18, %zmm18, %zmm18
	vpgatherdd	(%rdi,%zmm8,4), %zmm18 {%k1}
	vmovdqu64	%zmm18, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm16, %zmm16
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_278
# %bb.279:                              #   in Loop: Header=BB0_277 Depth=1
	cmpl	%ecx, -8(%rsp)                  # 4-byte Folded Reload
	je	.LBB0_290
# %bb.280:                              #   in Loop: Header=BB0_277 Depth=1
	vmovd	%r14d, %xmm15
	movq	-8(%rsp), %r15                  # 8-byte Reload
	jmp	.LBB0_281
	.p2align	4, 0x90
.LBB0_289:                              #   in Loop: Header=BB0_281 Depth=2
	imull	%ecx, %ebp
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_290
.LBB0_281:                              #   Parent Loop BB0_277 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %eax
	vmovd	%eax, %xmm8
	shrl	$8, %eax
	vpinsrd	$1, %eax, %xmm8, %xmm8
	vpand	.LCPI0_6(%rip), %xmm8, %xmm8
	vcvtdq2ps	%xmm8, %xmm8
	vdivps	%xmm12, %xmm8, %xmm8
	vaddps	%xmm13, %xmm8, %xmm8
	vmulps	%xmm0, %xmm8, %xmm8
	vcvttps2dq	%xmm8, %xmm8
	vpinsrd	$1, %r15d, %xmm15, %xmm11
	vpaddd	%xmm8, %xmm11, %xmm8
	vpextrd	$1, %xmm8, %eax
	cmpl	%r11d, %eax
	jl	.LBB0_283
# %bb.282:                              #   in Loop: Header=BB0_281 Depth=2
	movl	%r11d, %eax
.LBB0_283:                              #   in Loop: Header=BB0_281 Depth=2
	vpcmpgtd	%zmm8, %zmm14, %k0
	kmovw	%k0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testb	$2, %r13b
	je	.LBB0_284
# %bb.285:                              #   in Loop: Header=BB0_281 Depth=2
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_286
.LBB0_287:                              #   in Loop: Header=BB0_281 Depth=2
	testb	$1, %r13b
	jne	.LBB0_289
	jmp	.LBB0_288
	.p2align	4, 0x90
.LBB0_284:                              #   in Loop: Header=BB0_281 Depth=2
	movl	%eax, %r12d
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_287
.LBB0_286:                              #   in Loop: Header=BB0_281 Depth=2
	movl	%r9d, %eax
	testb	$1, %r13b
	jne	.LBB0_289
.LBB0_288:                              #   in Loop: Header=BB0_281 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_289
.LBB0_185:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r11d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpbroadcastd	.LCPI0_5(%rip), %zmm5   # zmm5 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpmovsxbd	.LCPI0_12(%rip), %zmm17 # zmm17 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vbroadcastss	.LCPI0_1(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm13  # xmm13 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm14, %xmm14, %xmm14
	jmp	.LBB0_186
	.p2align	4, 0x90
.LBB0_199:                              #   in Loop: Header=BB0_186 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	%r8, %r14
	je	.LBB0_480
.LBB0_186:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_187 Depth 2
                                        #     Child Loop BB0_190 Depth 2
	vpbroadcastd	%r14d, %zmm15
	movl	$16, %r15d
	vmovdqa64	%zmm17, %zmm16
	.p2align	4, 0x90
.LBB0_187:                              #   Parent Loop BB0_186 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm8
	vpandq	%zmm5, %zmm8, %zmm18
	vcvtdq2ps	%zmm18, %zmm18
	vdivps	%zmm6, %zmm18, %zmm18
	vpsrld	$8, %zmm8, %zmm8
	vaddps	%zmm7, %zmm18, %zmm18
	vpandd	%zmm5, %zmm8, %zmm8
	vcvtdq2ps	%zmm8, %zmm8
	vdivps	%zmm6, %zmm8, %zmm8
	vmulps	%zmm18, %zmm1, %zmm18
	vaddps	%zmm7, %zmm8, %zmm8
	vmulps	%zmm8, %zmm1, %zmm8
	vcvttps2dq	%zmm18, %zmm18
	vcvttps2dq	%zmm8, %zmm8
	vpaddd	%zmm15, %zmm8, %zmm8
	vpaddd	%zmm16, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm18, %zmm18
	vpminsd	%zmm2, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm8, %zmm8
	vpminsd	%zmm3, %zmm8, %zmm8
	vpmulld	%zmm4, %zmm8, %zmm8
	vpaddd	%zmm18, %zmm8, %zmm8
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm18, %zmm18, %zmm18
	vpgatherdd	(%rdi,%zmm8,4), %zmm18 {%k1}
	vmovdqu64	%zmm18, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm16, %zmm16
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_187
# %bb.188:                              #   in Loop: Header=BB0_186 Depth=1
	movq	-8(%rsp), %rax                  # 8-byte Reload
	cmpl	-16(%rsp), %eax                 # 4-byte Folded Reload
	je	.LBB0_199
# %bb.189:                              #   in Loop: Header=BB0_186 Depth=1
	vmovd	%r14d, %xmm15
	movq	-8(%rsp), %r15                  # 8-byte Reload
	jmp	.LBB0_190
	.p2align	4, 0x90
.LBB0_198:                              #   in Loop: Header=BB0_190 Depth=2
	imull	%ecx, %ebp
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_199
.LBB0_190:                              #   Parent Loop BB0_186 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %eax
	movl	%eax, %ecx
	shrl	$8, %ecx
	vmovd	%ecx, %xmm8
	vpinsrd	$1, %eax, %xmm8, %xmm8
	vpand	.LCPI0_6(%rip), %xmm8, %xmm8
	vcvtdq2ps	%xmm8, %xmm8
	vdivps	%xmm12, %xmm8, %xmm8
	vaddps	%xmm13, %xmm8, %xmm8
	vmulps	%xmm0, %xmm8, %xmm8
	vcvttps2dq	%xmm8, %xmm8
	vpinsrd	$1, %r15d, %xmm15, %xmm11
	vpaddd	%xmm8, %xmm11, %xmm8
	vpextrd	$1, %xmm8, %eax
	cmpl	%r11d, %eax
	jl	.LBB0_192
# %bb.191:                              #   in Loop: Header=BB0_190 Depth=2
	movl	%r11d, %eax
.LBB0_192:                              #   in Loop: Header=BB0_190 Depth=2
	vpcmpgtd	%zmm8, %zmm14, %k0
	kmovw	%k0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testb	$2, %r13b
	je	.LBB0_193
# %bb.194:                              #   in Loop: Header=BB0_190 Depth=2
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jge	.LBB0_195
.LBB0_196:                              #   in Loop: Header=BB0_190 Depth=2
	testb	$1, %r13b
	jne	.LBB0_198
	jmp	.LBB0_197
	.p2align	4, 0x90
.LBB0_193:                              #   in Loop: Header=BB0_190 Depth=2
	movl	%eax, %r12d
	vmovd	%xmm8, %eax
	cmpl	%r9d, %eax
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jl	.LBB0_196
.LBB0_195:                              #   in Loop: Header=BB0_190 Depth=2
	movl	%r9d, %eax
	testb	$1, %r13b
	jne	.LBB0_198
.LBB0_197:                              #   in Loop: Header=BB0_190 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_198
.LBB0_453:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vbroadcastss	.LCPI0_1(%rip), %zmm5   # zmm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpmovsxbd	.LCPI0_12(%rip), %zmm6  # zmm6 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm8, %xmm8, %xmm8
	vpbroadcastd	.LCPI0_3(%rip), %zmm9   # zmm9 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm10          # xmm10 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm11          # xmm11 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_454
	.p2align	4, 0x90
.LBB0_466:                              #   in Loop: Header=BB0_454 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_454:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_455 Depth 2
                                        #     Child Loop BB0_457 Depth 2
	vpbroadcastd	%r14d, %zmm12
	movl	$16, %r15d
	vmovdqa64	%zmm6, %zmm13
	.p2align	4, 0x90
.LBB0_455:                              #   Parent Loop BB0_454 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpsrld	$24, -64(%rsi,%r15,4), %zmm14
	vcvtdq2ps	%zmm14, %zmm14
	vdivps	%zmm5, %zmm14, %zmm14
	vaddps	%zmm7, %zmm14, %zmm14
	vmulps	%zmm14, %zmm1, %zmm14
	vcvttps2dq	%zmm14, %zmm14
	vpaddd	%zmm13, %zmm14, %zmm15
	vpmaxsd	%zmm8, %zmm15, %zmm15
	vpminsd	%zmm2, %zmm15, %zmm15
	vpaddd	%zmm12, %zmm14, %zmm14
	vpmaxsd	%zmm8, %zmm14, %zmm14
	vpminsd	%zmm3, %zmm14, %zmm14
	vpmulld	%zmm4, %zmm14, %zmm14
	vpaddd	%zmm15, %zmm14, %zmm14
	vpxor	%xmm15, %xmm15, %xmm15
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm14,4), %zmm15 {%k1}
	vmovdqu64	%zmm15, -64(%rdx,%r15,4)
	vpaddd	%zmm9, %zmm13, %zmm13
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_455
# %bb.456:                              #   in Loop: Header=BB0_454 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_457
	jmp	.LBB0_466
	.p2align	4, 0x90
.LBB0_465:                              #   in Loop: Header=BB0_457 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r13d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_466
.LBB0_457:                              #   Parent Loop BB0_454 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	3(%rsi,%r15,4), %ecx
	vcvtsi2ss	%ecx, %xmm16, %xmm12
	vdivss	%xmm10, %xmm12, %xmm12
	vaddss	%xmm11, %xmm12, %xmm12
	vmulss	%xmm0, %xmm12, %xmm12
	vcvttss2si	%xmm12, %r12d
	leal	(%r15,%r12), %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jge	.LBB0_458
# %bb.459:                              #   in Loop: Header=BB0_457 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	jns	.LBB0_460
.LBB0_461:                              #   in Loop: Header=BB0_457 Depth=2
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r9d, %r12d
	jge	.LBB0_462
.LBB0_463:                              #   in Loop: Header=BB0_457 Depth=2
	testl	%r12d, %r12d
	js	.LBB0_465
	jmp	.LBB0_464
	.p2align	4, 0x90
.LBB0_458:                              #   in Loop: Header=BB0_457 Depth=2
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	js	.LBB0_461
.LBB0_460:                              #   in Loop: Header=BB0_457 Depth=2
	movl	%ecx, %r13d
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r9d, %r12d
	jl	.LBB0_463
.LBB0_462:                              #   in Loop: Header=BB0_457 Depth=2
	movl	%r9d, %ecx
	testl	%r12d, %r12d
	js	.LBB0_465
.LBB0_464:                              #   in Loop: Header=BB0_457 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_465
.LBB0_366:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpbroadcastd	.LCPI0_5(%rip), %zmm7   # zmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_367
	.p2align	4, 0x90
.LBB0_379:                              #   in Loop: Header=BB0_367 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_367:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_368 Depth 2
                                        #     Child Loop BB0_370 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_368:                              #   Parent Loop BB0_367 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm15
	vpsrld	$16, %zmm15, %zmm16
	vpandd	%zmm7, %zmm16, %zmm16
	vpsrld	$24, %zmm15, %zmm15
	vcvtdq2ps	%zmm16, %zmm16
	vdivps	%zmm6, %zmm16, %zmm16
	vaddps	%zmm8, %zmm16, %zmm16
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vmulps	%zmm16, %zmm1, %zmm16
	vaddps	%zmm8, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm16, %zmm16
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm13, %zmm15, %zmm15
	vpaddd	%zmm14, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm16, %zmm16, %zmm16
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_368
# %bb.369:                              #   in Loop: Header=BB0_367 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_370
	jmp	.LBB0_379
	.p2align	4, 0x90
.LBB0_378:                              #   in Loop: Header=BB0_370 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_379
.LBB0_370:                              #   Parent Loop BB0_367 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %r13d
	movl	%r13d, %ecx
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r8d
	addl	%r15d, %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jl	.LBB0_372
# %bb.371:                              #   in Loop: Header=BB0_370 Depth=2
	movl	%eax, %ecx
.LBB0_372:                              #   in Loop: Header=BB0_370 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r8d, %r8d
	js	.LBB0_374
# %bb.373:                              #   in Loop: Header=BB0_370 Depth=2
	movl	%ecx, %r12d
.LBB0_374:                              #   in Loop: Header=BB0_370 Depth=2
	shrl	$24, %r13d
	vcvtsi2ss	%r13d, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %ecx
	addl	%r14d, %ecx
	movl	%ecx, %r8d
	cmpl	%r9d, %ecx
	jl	.LBB0_376
# %bb.375:                              #   in Loop: Header=BB0_370 Depth=2
	movl	%r9d, %r8d
.LBB0_376:                              #   in Loop: Header=BB0_370 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_378
# %bb.377:                              #   in Loop: Header=BB0_370 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_378
.LBB0_95:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpbroadcastd	.LCPI0_5(%rip), %zmm8   # zmm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_96
	.p2align	4, 0x90
.LBB0_108:                              #   in Loop: Header=BB0_96 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_96:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_97 Depth 2
                                        #     Child Loop BB0_99 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_97:                               #   Parent Loop BB0_96 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm15
	vpsrld	$24, %zmm15, %zmm16
	vpsrld	$16, %zmm15, %zmm15
	vpandd	%zmm8, %zmm15, %zmm15
	vcvtdq2ps	%zmm16, %zmm16
	vdivps	%zmm6, %zmm16, %zmm16
	vaddps	%zmm7, %zmm16, %zmm16
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vmulps	%zmm16, %zmm1, %zmm16
	vaddps	%zmm7, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm16, %zmm16
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm13, %zmm15, %zmm15
	vpaddd	%zmm14, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm16, %zmm16, %zmm16
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_97
# %bb.98:                               #   in Loop: Header=BB0_96 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_99
	jmp	.LBB0_108
	.p2align	4, 0x90
.LBB0_107:                              #   in Loop: Header=BB0_99 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_108
.LBB0_99:                               #   Parent Loop BB0_96 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %r13d
	movl	%r13d, %ecx
	shrl	$24, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r8d
	addl	%r15d, %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jl	.LBB0_101
# %bb.100:                              #   in Loop: Header=BB0_99 Depth=2
	movl	%eax, %ecx
.LBB0_101:                              #   in Loop: Header=BB0_99 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r8d, %r8d
	js	.LBB0_103
# %bb.102:                              #   in Loop: Header=BB0_99 Depth=2
	movl	%ecx, %r12d
.LBB0_103:                              #   in Loop: Header=BB0_99 Depth=2
	shrl	$16, %r13d
	movzbl	%r13b, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %ecx
	addl	%r14d, %ecx
	movl	%ecx, %r8d
	cmpl	%r9d, %ecx
	jl	.LBB0_105
# %bb.104:                              #   in Loop: Header=BB0_99 Depth=2
	movl	%r9d, %r8d
.LBB0_105:                              #   in Loop: Header=BB0_99 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_107
# %bb.106:                              #   in Loop: Header=BB0_99 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_107
.LBB0_395:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r13d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %eax
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rax
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpbroadcastd	.LCPI0_5(%rip), %zmm7   # zmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_396
	.p2align	4, 0x90
.LBB0_408:                              #   in Loop: Header=BB0_396 Depth=1
	incq	%r14
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_396:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_397 Depth 2
                                        #     Child Loop BB0_399 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_397:                              #   Parent Loop BB0_396 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm15
	vpsrld	$8, %zmm15, %zmm16
	vpandd	%zmm7, %zmm16, %zmm16
	vpsrld	$24, %zmm15, %zmm15
	vcvtdq2ps	%zmm16, %zmm16
	vdivps	%zmm6, %zmm16, %zmm16
	vaddps	%zmm8, %zmm16, %zmm16
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vmulps	%zmm16, %zmm1, %zmm16
	vaddps	%zmm8, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm16, %zmm16
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm13, %zmm15, %zmm15
	vpaddd	%zmm14, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	vpxord	%zmm16, %zmm16, %zmm16
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_397
# %bb.398:                              #   in Loop: Header=BB0_396 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_399
	jmp	.LBB0_408
	.p2align	4, 0x90
.LBB0_407:                              #   in Loop: Header=BB0_399 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_408
.LBB0_399:                              #   Parent Loop BB0_396 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %ebx
	movzbl	%bh, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r8d
	addl	%r15d, %r8d
	movl	%r8d, %ecx
	cmpl	%r13d, %r8d
	jl	.LBB0_401
# %bb.400:                              #   in Loop: Header=BB0_399 Depth=2
	movl	%r13d, %ecx
.LBB0_401:                              #   in Loop: Header=BB0_399 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r8d, %r8d
	js	.LBB0_403
# %bb.402:                              #   in Loop: Header=BB0_399 Depth=2
	movl	%ecx, %r12d
.LBB0_403:                              #   in Loop: Header=BB0_399 Depth=2
	shrl	$24, %ebx
	vcvtsi2ss	%ebx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %ecx
	addl	%r14d, %ecx
	movl	%ecx, %r8d
	cmpl	%r9d, %ecx
	jl	.LBB0_405
# %bb.404:                              #   in Loop: Header=BB0_399 Depth=2
	movl	%r9d, %r8d
.LBB0_405:                              #   in Loop: Header=BB0_399 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_407
# %bb.406:                              #   in Loop: Header=BB0_399 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_407
.LBB0_215:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r13d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %eax
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rax
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm7   # zmm7 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpbroadcastd	.LCPI0_5(%rip), %zmm8   # zmm8 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_216
	.p2align	4, 0x90
.LBB0_228:                              #   in Loop: Header=BB0_216 Depth=1
	incq	%r14
	addq	%rax, %rdx
	addq	%rax, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_216:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_217 Depth 2
                                        #     Child Loop BB0_219 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_217:                              #   Parent Loop BB0_216 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm15
	vpsrld	$24, %zmm15, %zmm16
	vpsrld	$8, %zmm15, %zmm15
	vpandd	%zmm8, %zmm15, %zmm15
	vcvtdq2ps	%zmm16, %zmm16
	vdivps	%zmm6, %zmm16, %zmm16
	vaddps	%zmm7, %zmm16, %zmm16
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vmulps	%zmm16, %zmm1, %zmm16
	vaddps	%zmm7, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm16, %zmm16
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm13, %zmm15, %zmm15
	vpaddd	%zmm14, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm16, %zmm16, %zmm16
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_217
# %bb.218:                              #   in Loop: Header=BB0_216 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_219
	jmp	.LBB0_228
	.p2align	4, 0x90
.LBB0_227:                              #   in Loop: Header=BB0_219 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r12d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_228
.LBB0_219:                              #   Parent Loop BB0_216 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rsi,%r15,4), %ebx
	movl	%ebx, %ecx
	shrl	$24, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r8d
	addl	%r15d, %r8d
	movl	%r8d, %ecx
	cmpl	%r13d, %r8d
	jl	.LBB0_221
# %bb.220:                              #   in Loop: Header=BB0_219 Depth=2
	movl	%r13d, %ecx
.LBB0_221:                              #   in Loop: Header=BB0_219 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testl	%r8d, %r8d
	js	.LBB0_223
# %bb.222:                              #   in Loop: Header=BB0_219 Depth=2
	movl	%ecx, %r12d
.LBB0_223:                              #   in Loop: Header=BB0_219 Depth=2
	movzbl	%bh, %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %ecx
	addl	%r14d, %ecx
	movl	%ecx, %r8d
	cmpl	%r9d, %ecx
	jl	.LBB0_225
# %bb.224:                              #   in Loop: Header=BB0_219 Depth=2
	movl	%r9d, %r8d
.LBB0_225:                              #   in Loop: Header=BB0_219 Depth=2
	testl	%ecx, %ecx
	js	.LBB0_227
# %bb.226:                              #   in Loop: Header=BB0_219 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_227
.LBB0_6:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%ecx, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movl	%r8d, %r8d
	movq	%r8, -8(%rsp)                   # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpbroadcastd	.LCPI0_5(%rip), %zmm7   # zmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_7
	.p2align	4, 0x90
.LBB0_19:                               #   in Loop: Header=BB0_7 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_7:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_8 Depth 2
                                        #     Child Loop BB0_10 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_8:                                #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpsrld	$16, -64(%rsi,%r15,4), %zmm15
	vpandd	%zmm7, %zmm15, %zmm15
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vaddps	%zmm8, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm14, %zmm15, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpaddd	%zmm13, %zmm15, %zmm15
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	vpxord	%zmm16, %zmm16, %zmm16
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_8
# %bb.9:                                #   in Loop: Header=BB0_7 Depth=1
	movq	%rax, %r15
	cmpl	-16(%rsp), %eax                 # 4-byte Folded Reload
	jne	.LBB0_10
	jmp	.LBB0_19
	.p2align	4, 0x90
.LBB0_18:                               #   in Loop: Header=BB0_10 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r13d, %ebp
	movslq	%ebp, %r8
	movl	(%rdi,%r8,4), %r8d
	movl	%r8d, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_19
.LBB0_10:                               #   Parent Loop BB0_7 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	2(%rsi,%r15,4), %r8d
	vcvtsi2ss	%r8d, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r12d
	leal	(%r15,%r12), %r8d
	movl	%r8d, %r11d
	cmpl	%ecx, %r8d
	jge	.LBB0_11
# %bb.12:                               #   in Loop: Header=BB0_10 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	jns	.LBB0_13
.LBB0_14:                               #   in Loop: Header=BB0_10 Depth=2
	addl	%r14d, %r12d
	movl	%r12d, %r8d
	cmpl	%r9d, %r12d
	jge	.LBB0_15
.LBB0_16:                               #   in Loop: Header=BB0_10 Depth=2
	testl	%r12d, %r12d
	js	.LBB0_18
	jmp	.LBB0_17
	.p2align	4, 0x90
.LBB0_11:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%ecx, %r11d
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	js	.LBB0_14
.LBB0_13:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%r11d, %r13d
	addl	%r14d, %r12d
	movl	%r12d, %r8d
	cmpl	%r9d, %r12d
	jl	.LBB0_16
.LBB0_15:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%r9d, %r8d
	testl	%r12d, %r12d
	js	.LBB0_18
.LBB0_17:                               #   in Loop: Header=BB0_10 Depth=2
	movl	%r8d, %ebp
	jmp	.LBB0_18
.LBB0_126:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r11d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm16 # zmm16 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vpbroadcastd	.LCPI0_5(%rip), %zmm6   # zmm6 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %zmm7   # zmm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vbroadcastss	.LCPI0_1(%rip), %xmm13  # xmm13 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm14  # xmm14 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm15, %xmm15, %xmm15
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jmp	.LBB0_127
	.p2align	4, 0x90
.LBB0_140:                              #   in Loop: Header=BB0_127 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	%r8, %r14
	je	.LBB0_480
.LBB0_127:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_128 Depth 2
                                        #     Child Loop BB0_131 Depth 2
	vpbroadcastd	%r14d, %zmm5
	movl	$16, %r15d
	vmovdqa64	%zmm16, %zmm17
	.p2align	4, 0x90
.LBB0_128:                              #   Parent Loop BB0_127 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm11
	vpsrld	$16, %zmm11, %zmm18
	vpandd	%zmm6, %zmm18, %zmm18
	vcvtdq2ps	%zmm18, %zmm18
	vdivps	%zmm7, %zmm18, %zmm18
	vpsrld	$8, %zmm11, %zmm11
	vaddps	%zmm8, %zmm18, %zmm18
	vpandd	%zmm6, %zmm11, %zmm11
	vcvtdq2ps	%zmm11, %zmm11
	vdivps	%zmm7, %zmm11, %zmm11
	vmulps	%zmm18, %zmm1, %zmm18
	vaddps	%zmm8, %zmm11, %zmm11
	vmulps	%zmm11, %zmm1, %zmm11
	vcvttps2dq	%zmm18, %zmm18
	vcvttps2dq	%zmm11, %zmm11
	vpaddd	%zmm5, %zmm11, %zmm11
	vpaddd	%zmm17, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm18, %zmm18
	vpminsd	%zmm2, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm11, %zmm11
	vpminsd	%zmm3, %zmm11, %zmm11
	vpmulld	%zmm4, %zmm11, %zmm11
	vpaddd	%zmm18, %zmm11, %zmm11
	vpxord	%zmm18, %zmm18, %zmm18
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm11,4), %zmm18 {%k1}
	vmovdqu64	%zmm18, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm17, %zmm17
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_128
# %bb.129:                              #   in Loop: Header=BB0_127 Depth=1
	cmpl	%ecx, -8(%rsp)                  # 4-byte Folded Reload
	je	.LBB0_140
# %bb.130:                              #   in Loop: Header=BB0_127 Depth=1
	vmovd	%r14d, %xmm5
	movq	-8(%rsp), %r15                  # 8-byte Reload
	jmp	.LBB0_131
	.p2align	4, 0x90
.LBB0_139:                              #   in Loop: Header=BB0_131 Depth=2
	imull	%ecx, %ebp
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_140
.LBB0_131:                              #   Parent Loop BB0_127 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpbroadcastd	(%rsi,%r15,4), %xmm11
	vpsrlvd	.LCPI0_7(%rip), %xmm11, %xmm11
	vpand	.LCPI0_6(%rip), %xmm11, %xmm11
	vcvtdq2ps	%xmm11, %xmm11
	vdivps	%xmm13, %xmm11, %xmm11
	vaddps	%xmm14, %xmm11, %xmm11
	vmulps	%xmm0, %xmm11, %xmm11
	vcvttps2dq	%xmm11, %xmm11
	vpinsrd	$1, %r15d, %xmm5, %xmm12
	vpaddd	%xmm11, %xmm12, %xmm11
	vpextrd	$1, %xmm11, %eax
	cmpl	%r11d, %eax
	jl	.LBB0_133
# %bb.132:                              #   in Loop: Header=BB0_131 Depth=2
	movl	%r11d, %eax
.LBB0_133:                              #   in Loop: Header=BB0_131 Depth=2
	vpcmpgtd	%zmm11, %zmm15, %k0
	kmovw	%k0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testb	$2, %r13b
	je	.LBB0_134
# %bb.135:                              #   in Loop: Header=BB0_131 Depth=2
	vmovd	%xmm11, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_136
.LBB0_137:                              #   in Loop: Header=BB0_131 Depth=2
	testb	$1, %r13b
	jne	.LBB0_139
	jmp	.LBB0_138
	.p2align	4, 0x90
.LBB0_134:                              #   in Loop: Header=BB0_131 Depth=2
	movl	%eax, %r12d
	vmovd	%xmm11, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_137
.LBB0_136:                              #   in Loop: Header=BB0_131 Depth=2
	movl	%r9d, %eax
	testb	$1, %r13b
	jne	.LBB0_139
.LBB0_138:                              #   in Loop: Header=BB0_131 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_139
.LBB0_35:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%r11d, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%eax, %zmm4
	movl	%eax, %r10d
                                        # kill: def $eax killed $eax killed $rax def $rax
	andl	$2147483632, %eax               # imm = 0x7FFFFFF0
	movq	%rax, -8(%rsp)                  # 8-byte Spill
	movl	%r8d, %r8d
	vbroadcastss	%xmm0, %xmm0
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm16 # zmm16 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vpbroadcastd	.LCPI0_5(%rip), %zmm6   # zmm6 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_1(%rip), %zmm7   # zmm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vbroadcastss	.LCPI0_1(%rip), %xmm13  # xmm13 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vbroadcastss	.LCPI0_2(%rip), %xmm14  # xmm14 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm15, %xmm15, %xmm15
	movq	-16(%rsp), %rcx                 # 8-byte Reload
	jmp	.LBB0_36
	.p2align	4, 0x90
.LBB0_49:                               #   in Loop: Header=BB0_36 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	%r8, %r14
	je	.LBB0_480
.LBB0_36:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_37 Depth 2
                                        #     Child Loop BB0_40 Depth 2
	vpbroadcastd	%r14d, %zmm5
	movl	$16, %r15d
	vmovdqa64	%zmm16, %zmm17
	.p2align	4, 0x90
.LBB0_37:                               #   Parent Loop BB0_36 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu64	-64(%rsi,%r15,4), %zmm11
	vpsrld	$8, %zmm11, %zmm18
	vpandd	%zmm6, %zmm18, %zmm18
	vcvtdq2ps	%zmm18, %zmm18
	vdivps	%zmm7, %zmm18, %zmm18
	vpsrld	$16, %zmm11, %zmm11
	vaddps	%zmm8, %zmm18, %zmm18
	vpandd	%zmm6, %zmm11, %zmm11
	vcvtdq2ps	%zmm11, %zmm11
	vdivps	%zmm7, %zmm11, %zmm11
	vmulps	%zmm18, %zmm1, %zmm18
	vaddps	%zmm8, %zmm11, %zmm11
	vmulps	%zmm11, %zmm1, %zmm11
	vcvttps2dq	%zmm18, %zmm18
	vcvttps2dq	%zmm11, %zmm11
	vpaddd	%zmm5, %zmm11, %zmm11
	vpaddd	%zmm17, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm18, %zmm18
	vpminsd	%zmm2, %zmm18, %zmm18
	vpmaxsd	%zmm9, %zmm11, %zmm11
	vpminsd	%zmm3, %zmm11, %zmm11
	vpmulld	%zmm4, %zmm11, %zmm11
	vpaddd	%zmm18, %zmm11, %zmm11
	vpxord	%zmm18, %zmm18, %zmm18
	kxnorw	%k0, %k0, %k1
	vpgatherdd	(%rdi,%zmm11,4), %zmm18 {%k1}
	vmovdqu64	%zmm18, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm17, %zmm17
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_37
# %bb.38:                               #   in Loop: Header=BB0_36 Depth=1
	cmpl	%ecx, -8(%rsp)                  # 4-byte Folded Reload
	je	.LBB0_49
# %bb.39:                               #   in Loop: Header=BB0_36 Depth=1
	vmovd	%r14d, %xmm5
	movq	-8(%rsp), %r15                  # 8-byte Reload
	jmp	.LBB0_40
	.p2align	4, 0x90
.LBB0_48:                               #   in Loop: Header=BB0_40 Depth=2
	imull	%ecx, %ebp
	addl	%r12d, %ebp
	movslq	%ebp, %rax
	movl	(%rdi,%rax,4), %eax
	movl	%eax, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_49
.LBB0_40:                               #   Parent Loop BB0_36 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpbroadcastd	(%rsi,%r15,4), %xmm11
	vpsrlvd	.LCPI0_8(%rip), %xmm11, %xmm11
	vpand	.LCPI0_6(%rip), %xmm11, %xmm11
	vcvtdq2ps	%xmm11, %xmm11
	vdivps	%xmm13, %xmm11, %xmm11
	vaddps	%xmm14, %xmm11, %xmm11
	vmulps	%xmm0, %xmm11, %xmm11
	vcvttps2dq	%xmm11, %xmm11
	vpinsrd	$1, %r15d, %xmm5, %xmm12
	vpaddd	%xmm11, %xmm12, %xmm11
	vpextrd	$1, %xmm11, %eax
	cmpl	%r11d, %eax
	jl	.LBB0_42
# %bb.41:                               #   in Loop: Header=BB0_40 Depth=2
	movl	%r11d, %eax
.LBB0_42:                               #   in Loop: Header=BB0_40 Depth=2
	vpcmpgtd	%zmm11, %zmm15, %k0
	kmovw	%k0, %r13d
	xorl	%ebp, %ebp
	movl	$0, %r12d
	testb	$2, %r13b
	je	.LBB0_43
# %bb.44:                               #   in Loop: Header=BB0_40 Depth=2
	vmovd	%xmm11, %eax
	cmpl	%r9d, %eax
	jge	.LBB0_45
.LBB0_46:                               #   in Loop: Header=BB0_40 Depth=2
	testb	$1, %r13b
	jne	.LBB0_48
	jmp	.LBB0_47
	.p2align	4, 0x90
.LBB0_43:                               #   in Loop: Header=BB0_40 Depth=2
	movl	%eax, %r12d
	vmovd	%xmm11, %eax
	cmpl	%r9d, %eax
	jl	.LBB0_46
.LBB0_45:                               #   in Loop: Header=BB0_40 Depth=2
	movl	%r9d, %eax
	testb	$1, %r13b
	jne	.LBB0_48
.LBB0_47:                               #   in Loop: Header=BB0_40 Depth=2
	movl	%eax, %ebp
	jmp	.LBB0_48
.LBB0_156:
	vbroadcastss	%xmm0, %zmm1
	vpbroadcastd	%eax, %zmm2
	vpbroadcastd	%r9d, %zmm3
	vpbroadcastd	%r11d, %zmm4
	movl	%r11d, %r10d
                                        # kill: def $r11d killed $r11d killed $r11 def $r11
	andl	$2147483632, %r11d              # imm = 0x7FFFFFF0
	movl	%r8d, %ecx
	movq	%rcx, -8(%rsp)                  # 8-byte Spill
	leaq	(,%r10,4), %rbx
	xorl	%r14d, %r14d
	vpmovsxbd	.LCPI0_12(%rip), %zmm5  # zmm5 = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
	vbroadcastss	.LCPI0_1(%rip), %zmm6   # zmm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vpbroadcastd	.LCPI0_5(%rip), %zmm7   # zmm7 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_2(%rip), %zmm8   # zmm8 = [-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1,-5.0E-1]
	vpxor	%xmm9, %xmm9, %xmm9
	vpbroadcastd	.LCPI0_3(%rip), %zmm10  # zmm10 = [16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16]
	vmovss	.LCPI0_1(%rip), %xmm11          # xmm11 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmovss	.LCPI0_2(%rip), %xmm12          # xmm12 = [-5.0E-1,0.0E+0,0.0E+0,0.0E+0]
	jmp	.LBB0_157
	.p2align	4, 0x90
.LBB0_169:                              #   in Loop: Header=BB0_157 Depth=1
	incq	%r14
	addq	%rbx, %rdx
	addq	%rbx, %rsi
	cmpq	-8(%rsp), %r14                  # 8-byte Folded Reload
	je	.LBB0_480
.LBB0_157:                              # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_158 Depth 2
                                        #     Child Loop BB0_160 Depth 2
	vpbroadcastd	%r14d, %zmm13
	movl	$16, %r15d
	vmovdqa64	%zmm5, %zmm14
	.p2align	4, 0x90
.LBB0_158:                              #   Parent Loop BB0_157 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vpsrld	$8, -64(%rsi,%r15,4), %zmm15
	vpandd	%zmm7, %zmm15, %zmm15
	vcvtdq2ps	%zmm15, %zmm15
	vdivps	%zmm6, %zmm15, %zmm15
	vaddps	%zmm8, %zmm15, %zmm15
	vmulps	%zmm15, %zmm1, %zmm15
	vcvttps2dq	%zmm15, %zmm15
	vpaddd	%zmm14, %zmm15, %zmm16
	vpmaxsd	%zmm9, %zmm16, %zmm16
	vpminsd	%zmm2, %zmm16, %zmm16
	vpaddd	%zmm13, %zmm15, %zmm15
	vpmaxsd	%zmm9, %zmm15, %zmm15
	vpminsd	%zmm3, %zmm15, %zmm15
	vpmulld	%zmm4, %zmm15, %zmm15
	vpaddd	%zmm16, %zmm15, %zmm15
	kxnorw	%k0, %k0, %k1
	vpxord	%zmm16, %zmm16, %zmm16
	vpgatherdd	(%rdi,%zmm15,4), %zmm16 {%k1}
	vmovdqu64	%zmm16, -64(%rdx,%r15,4)
	vpaddd	%zmm10, %zmm14, %zmm14
	addq	$16, %r15
	cmpq	%r10, %r15
	jbe	.LBB0_158
# %bb.159:                              #   in Loop: Header=BB0_157 Depth=1
	movq	%r11, %r15
	cmpl	-16(%rsp), %r11d                # 4-byte Folded Reload
	jne	.LBB0_160
	jmp	.LBB0_169
	.p2align	4, 0x90
.LBB0_168:                              #   in Loop: Header=BB0_160 Depth=2
	imull	-16(%rsp), %ebp                 # 4-byte Folded Reload
	addl	%r13d, %ebp
	movslq	%ebp, %rcx
	movl	(%rdi,%rcx,4), %ecx
	movl	%ecx, (%rdx,%r15,4)
	incq	%r15
	cmpq	%r10, %r15
	jae	.LBB0_169
.LBB0_160:                              #   Parent Loop BB0_157 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movzbl	1(%rsi,%r15,4), %ecx
	vcvtsi2ss	%ecx, %xmm17, %xmm13
	vdivss	%xmm11, %xmm13, %xmm13
	vaddss	%xmm12, %xmm13, %xmm13
	vmulss	%xmm0, %xmm13, %xmm13
	vcvttss2si	%xmm13, %r12d
	leal	(%r15,%r12), %r8d
	movl	%r8d, %ecx
	cmpl	%eax, %r8d
	jge	.LBB0_161
# %bb.162:                              #   in Loop: Header=BB0_160 Depth=2
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	jns	.LBB0_163
.LBB0_164:                              #   in Loop: Header=BB0_160 Depth=2
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r9d, %r12d
	jge	.LBB0_165
.LBB0_166:                              #   in Loop: Header=BB0_160 Depth=2
	testl	%r12d, %r12d
	js	.LBB0_168
	jmp	.LBB0_167
	.p2align	4, 0x90
.LBB0_161:                              #   in Loop: Header=BB0_160 Depth=2
	movl	%eax, %ecx
	xorl	%ebp, %ebp
	movl	$0, %r13d
	testl	%r8d, %r8d
	js	.LBB0_164
.LBB0_163:                              #   in Loop: Header=BB0_160 Depth=2
	movl	%ecx, %r13d
	addl	%r14d, %r12d
	movl	%r12d, %ecx
	cmpl	%r9d, %r12d
	jl	.LBB0_166
.LBB0_165:                              #   in Loop: Header=BB0_160 Depth=2
	movl	%r9d, %ecx
	testl	%r12d, %r12d
	js	.LBB0_168
.LBB0_167:                              #   in Loop: Header=BB0_160 Depth=2
	movl	%ecx, %ebp
	jmp	.LBB0_168
.LBB0_480:
	popq	%rbx
	CFI_DEF_CFA_OFFSET(48)
	popq	%r12
	CFI_DEF_CFA_OFFSET(40)
	popq	%r13
	CFI_DEF_CFA_OFFSET(32)
	popq	%r14
	CFI_DEF_CFA_OFFSET(24)
	popq	%r15
	CFI_DEF_CFA_OFFSET(16)
	popq	%rbp
	CFI_DEF_CFA_OFFSET(8)
	vzeroupper
	retq
.Lfunc_end0:
// SIZE(SYM(ksvgDisplacementMapApplyAvx512))
	CFI_END
RODATA
	.p2align	2, 0x0
.LJTI0_0:
	.long	.LBB0_2-.LJTI0_0
	.long	.LBB0_122-.LJTI0_0
	.long	.LBB0_242-.LJTI0_0
	.long	.LBB0_362-.LJTI0_0
.LJTI0_1:
	.long	.LBB0_364-.LJTI0_1
	.long	.LBB0_393-.LJTI0_1
	.long	.LBB0_422-.LJTI0_1
	.long	.LBB0_451-.LJTI0_1
.LJTI0_2:
	.long	.LBB0_244-.LJTI0_2
	.long	.LBB0_274-.LJTI0_2
	.long	.LBB0_304-.LJTI0_2
	.long	.LBB0_333-.LJTI0_2
.LJTI0_3:
	.long	.LBB0_124-.LJTI0_3
	.long	.LBB0_154-.LJTI0_3
	.long	.LBB0_183-.LJTI0_3
	.long	.LBB0_213-.LJTI0_3
.LJTI0_4:
	.long	.LBB0_4-.LJTI0_4
	.long	.LBB0_33-.LJTI0_4
	.long	.LBB0_63-.LJTI0_4
	.long	.LBB0_93-.LJTI0_4
                                        # -- End function
	.ident	"clang version 17.0.0 (https://github.com/swiftlang/llvm-project.git 10999b6d034fe318f3d56c83bddb6572593a8bb0)"
GNU_STACK
ADDRSIG
