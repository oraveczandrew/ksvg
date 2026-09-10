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

/*
 * x86-64 AVX2 implementation of ArithmeticComposite.
 *
 * 8 pixels are processed per vector iteration.  Semantics mirror the
 * current ksvgArithmeticApplyAvx2() reference: the supplied sRGB LUTs
 * are used in linear mode, while non-linear mode applies the arithmetic
 * formula directly in encoded space.
 *
 * This file is Clang/GNU assembler compatible on macOS and ELF hosts.
 */

#include "asm_macros.S"


.text
.p2align 5
.globl SYM(ksvgArithmeticApplyAvx2)
TYPE(SYM(ksvgArithmeticApplyAvx2), @function)
SYM(ksvgArithmeticApplyAvx2):
# %bb.0:
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	andq	$-32, %rsp
	subq	$1760, %rsp                     # imm = 0x6E0
	vmovaps	%xmm3, %xmm4
	vmovaps	%xmm2, %xmm7
	vmovaps	%xmm0, %xmm5
	movl	%r9d, %eax
                                        # kill: def $r8d killed $r8d def $r8
	movq	%r8, 32(%rsp)                   # 8-byte Spill
	movq	%rdx, 24(%rsp)                  # 8-byte Spill
	movq	%rsi, 16(%rsp)                  # 8-byte Spill
	movq	%rdi, 8(%rsp)                   # 8-byte Spill
	movq	48(%rbp), %r13
	movq	40(%rbp), %r10
	movzbl	32(%rbp), %ebx
	movl	24(%rbp), %edx
	testb	%bl, %bl
	je	.LBB0_1
# %bb.2:
	vbroadcastf128	(%r10), %ymm0           # ymm0 = mem[0,1,0,1]
	vmovaps	%ymm0, 1152(%rsp)               # 32-byte Spill
	vbroadcastf128	16(%r10), %ymm0         # ymm0 = mem[0,1,0,1]
	vmovaps	%ymm0, 1184(%rsp)               # 32-byte Spill
	vbroadcastf128	32(%r10), %ymm0         # ymm0 = mem[0,1,0,1]
	vmovaps	%ymm0, 1216(%rsp)               # 32-byte Spill
	vbroadcastf128	48(%r10), %ymm0         # ymm0 = mem[0,1,0,1]
	vmovaps	%ymm0, 1248(%rsp)               # 32-byte Spill
	vbroadcastf128	64(%r10), %ymm0         # ymm0 = mem[0,1,0,1]
	vmovaps	%ymm0, 480(%rsp)                # 32-byte Spill
	vbroadcasti128	80(%r10), %ymm2         # ymm2 = mem[0,1,0,1]
	vbroadcastf128	96(%r10), %ymm6         # ymm6 = mem[0,1,0,1]
	vbroadcasti128	112(%r10), %ymm0        # ymm0 = mem[0,1,0,1]
	vbroadcastf128	128(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 320(%rsp)                # 32-byte Spill
	vbroadcastf128	144(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 608(%rsp)                # 32-byte Spill
	vbroadcastf128	160(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 384(%rsp)                # 32-byte Spill
	vbroadcastf128	176(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 352(%rsp)                # 32-byte Spill
	vbroadcastf128	192(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 448(%rsp)                # 32-byte Spill
	vbroadcastf128	208(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 416(%rsp)                # 32-byte Spill
	vbroadcasti128	224(%r10), %ymm14       # ymm14 = mem[0,1,0,1]
	vbroadcastf128	240(%r10), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 576(%rsp)                # 32-byte Spill
	vbroadcastf128	(%r13), %ymm3           # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 640(%rsp)                # 32-byte Spill
	vbroadcastf128	16(%r13), %ymm3         # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 672(%rsp)                # 32-byte Spill
	vbroadcastf128	32(%r13), %ymm3         # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 704(%rsp)                # 32-byte Spill
	vbroadcastf128	48(%r13), %ymm3         # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 736(%rsp)                # 32-byte Spill
	vbroadcastf128	64(%r13), %ymm3         # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 768(%rsp)                # 32-byte Spill
	vbroadcastf128	80(%r13), %ymm3         # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 800(%rsp)                # 32-byte Spill
	vbroadcastf128	96(%r13), %ymm3         # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 832(%rsp)                # 32-byte Spill
	vbroadcastf128	112(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 864(%rsp)                # 32-byte Spill
	vbroadcastf128	128(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 896(%rsp)                # 32-byte Spill
	vbroadcastf128	144(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 928(%rsp)                # 32-byte Spill
	vbroadcastf128	160(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 960(%rsp)                # 32-byte Spill
	vbroadcastf128	176(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 992(%rsp)                # 32-byte Spill
	vbroadcastf128	192(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 1024(%rsp)               # 32-byte Spill
	vbroadcastf128	208(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 1056(%rsp)               # 32-byte Spill
	vbroadcastf128	224(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 1088(%rsp)               # 32-byte Spill
	vbroadcastf128	240(%r13), %ymm3        # ymm3 = mem[0,1,0,1]
	vmovaps	%ymm3, 1120(%rsp)               # 32-byte Spill
	vmovdqa	%ymm2, 1280(%rsp)               # 32-byte Spill
	vmovaps	%ymm6, 1312(%rsp)               # 32-byte Spill
	cmpl	%edx, %eax
	jl	.LBB0_4
	jmp	.LBB0_23
.LBB0_1:
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm14
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm0
                                        # kill: killed $ymm0
                                        # implicit-def: $ymm0
                                        # implicit-def: $ymm6
                                        # implicit-def: $ymm2
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
                                        # implicit-def: $ymm3
                                        # kill: killed $ymm3
	vmovdqa	%ymm2, 1280(%rsp)               # 32-byte Spill
	vmovaps	%ymm6, 1312(%rsp)               # 32-byte Spill
	cmpl	%edx, %eax
	jge	.LBB0_23
.LBB0_4:
	vmovdqa	%ymm0, %ymm2
	vmovss	.LCPI0_0(%rip), %xmm0           # xmm0 = [2.55E+2,0.0E+0,0.0E+0,0.0E+0]
	vmulss	%xmm0, %xmm4, %xmm3
	vaddss	.LCPI0_1(%rip), %xmm3, %xmm9
	vdivss	%xmm0, %xmm5, %xmm0
	vbroadcastss	%xmm0, %ymm3
	vmovdqa	%ymm2, %ymm0
	vbroadcastss	%xmm1, %ymm6
	vbroadcastss	%xmm7, %ymm11
	vbroadcastss	%xmm9, %ymm10
	vmovaps	%ymm3, %ymm1
	movq	32(%rsp), %rsi                  # 8-byte Reload
	leal	8(%rsi), %esi
	movslq	16(%rbp), %r15
	movl	%esi, 60(%rsp)                  # 4-byte Spill
	movslq	%esi, %rsi
	movq	%rsi, 72(%rsp)                  # 8-byte Spill
	movslq	%eax, %rdi
	movslq	%ecx, %r11
	movslq	%edx, %rax
	movq	%rax, 88(%rsp)                  # 8-byte Spill
	movq	24(%rsp), %rax                  # 8-byte Reload
	movq	%rax, %rcx
	movq	8(%rsp), %r8                    # 8-byte Reload
	subq	%r8, %rcx
	movq	%rax, %rdx
	movq	16(%rsp), %rsi                  # 8-byte Reload
	subq	%rsi, %rdx
	vbroadcastss	%xmm5, %ymm5
	vbroadcastss	%xmm4, %ymm13
	cmpq	$32, %rcx
	setb	%cl
	cmpq	$32, %rdx
	setb	%dl
	orb	%cl, %dl
	movb	%dl, 7(%rsp)                    # 1-byte Spill
	movq	%rdi, 48(%rsp)                  # 8-byte Spill
	movq	%rdi, %rcx
	imulq	%r11, %rcx
	leaq	(%rax,%rcx,4), %r9
	movq	%r11, 64(%rsp)                  # 8-byte Spill
	leaq	(,%r11,4), %rax
	movq	%rax, 80(%rsp)                  # 8-byte Spill
	leaq	(%rsi,%rcx,4), %rdi
	movq	%rcx, 40(%rsp)                  # 8-byte Spill
	leaq	(%r8,%rcx,4), %rdx
	vbroadcastss	.LCPI0_0(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmovdqa	.LCPI0_4(%rip), %ymm2           # ymm2 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vmovaps	%ymm10, 224(%rsp)               # 32-byte Spill
	vmovdqa	%ymm14, 544(%rsp)               # 32-byte Spill
	vmovaps	%ymm3, 192(%rsp)                # 32-byte Spill
	vmovaps	%ymm6, 96(%rsp)                 # 32-byte Spill
	vmovaps	%ymm5, 128(%rsp)                # 32-byte Spill
	vmovaps	%ymm13, 512(%rsp)               # 32-byte Spill
	vmovaps	%ymm11, 288(%rsp)               # 32-byte Spill
	vmovdqa	%ymm0, 256(%rsp)                # 32-byte Spill
	jmp	.LBB0_5
	.p2align	4, 0x90
.LBB0_22:                               #   in Loop: Header=BB0_5 Depth=1
	movq	48(%rsp), %rax                  # 8-byte Reload
	incq	%rax
	movq	80(%rsp), %rcx                  # 8-byte Reload
	addq	%rcx, %r9
	addq	%rcx, %rdi
	addq	%rcx, %rdx
	movq	40(%rsp), %rcx                  # 8-byte Reload
	addq	64(%rsp), %rcx                  # 8-byte Folded Reload
	movq	%rcx, 40(%rsp)                  # 8-byte Spill
	movq	%rax, 48(%rsp)                  # 8-byte Spill
	cmpq	88(%rsp), %rax                  # 8-byte Folded Reload
	movzbl	32(%rbp), %ebx
	vmovdqa	.LCPI0_4(%rip), %ymm2           # ymm2 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	je	.LBB0_23
.LBB0_5:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_7 Depth 2
                                        #       Child Loop BB0_9 Depth 3
                                        #     Child Loop BB0_15 Depth 2
                                        #     Child Loop BB0_19 Depth 2
                                        #     Child Loop BB0_21 Depth 2
	movq	32(%rsp), %rax                  # 8-byte Reload
	movl	%eax, %r11d
	movl	60(%rsp), %eax                  # 4-byte Reload
	cmpl	16(%rbp), %eax
	vmovdqa	.LCPI0_3(%rip), %ymm6           # ymm6 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	jle	.LBB0_6
.LBB0_12:                               #   in Loop: Header=BB0_5 Depth=1
	cmpl	16(%rbp), %r11d
	vmovaps	96(%rsp), %ymm6                 # 32-byte Reload
	vmovaps	128(%rsp), %ymm5                # 32-byte Reload
	movl	$-16777216, %r14d               # imm = 0xFF000000
	jge	.LBB0_22
# %bb.13:                               #   in Loop: Header=BB0_5 Depth=1
	movslq	%r11d, %rsi
	cmpb	$0, 32(%rbp)
	je	.LBB0_16
# %bb.14:                               #   in Loop: Header=BB0_5 Depth=1
	vxorps	%xmm7, %xmm7, %xmm7
	.p2align	4, 0x90
.LBB0_15:                               #   Parent Loop BB0_5 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rdx,%rsi,4), %ecx
	movl	%ecx, %r8d
	movzbl	%cl, %r11d
	movzbl	(%r10,%r11), %r11d
	vmovd	%r11d, %xmm2
	movzbl	%ch, %eax
                                        # kill: def $ecx killed $ecx killed $rcx
	shrl	$16, %r8d
	movzbl	%r8b, %r8d
	vpinsrb	$4, (%r10,%rax), %xmm2, %xmm2
	vpinsrb	$8, (%r10,%r8), %xmm2, %xmm2
	shrl	$24, %ecx
	vpinsrb	$12, %ecx, %xmm2, %xmm2
	movl	(%rdi,%rsi,4), %eax
	movl	%eax, %ecx
	movzbl	%al, %r8d
	movzbl	(%r10,%r8), %r8d
	vmovd	%r8d, %xmm3
	movzbl	%ah, %ebx
                                        # kill: def $eax killed $eax killed $rax
	shrl	$16, %ecx
	movzbl	%cl, %ecx
	vpinsrb	$4, (%r10,%rbx), %xmm3, %xmm3
	vpinsrb	$8, (%r10,%rcx), %xmm3, %xmm3
	shrl	$24, %eax
	vpinsrb	$12, %eax, %xmm3, %xmm3
	vcvtdq2ps	%xmm2, %xmm2
	vdivps	%xmm12, %xmm2, %xmm2
	vcvtdq2ps	%xmm3, %xmm3
	vdivps	%xmm12, %xmm3, %xmm3
	vmulps	%xmm5, %xmm2, %xmm4
	vmulps	%xmm6, %xmm2, %xmm2
	vmulps	%xmm3, %xmm4, %xmm4
	vaddps	%xmm2, %xmm4, %xmm2
	vmulps	%xmm3, %xmm11, %xmm3
	vaddps	%xmm2, %xmm3, %xmm2
	vaddps	%xmm2, %xmm13, %xmm2
	vmulps	%xmm2, %xmm12, %xmm2
	vmaxps	%xmm2, %xmm7, %xmm2
	vcmpltps	%xmm2, %xmm12, %xmm3
	vpextrb	$12, %xmm3, %r8d
	vshufps	$255, %xmm2, %xmm2, %xmm4       # xmm4 = xmm2[3,3,3,3]
	vcvttss2si	%xmm4, %ecx
	vpextrb	$8, %xmm3, %eax
	vshufpd	$1, %xmm2, %xmm2, %xmm4         # xmm4 = xmm2[1,0]
	testb	$1, %al
	vcvttss2si	%xmm4, %eax
	movzbl	%al, %eax
	movl	$255, %r11d
	cmovneq	%r11, %rax
	shll	$24, %ecx
	testb	$1, %r8b
	movzbl	(%r13,%rax), %eax
	vpackssdw	%xmm3, %xmm3, %xmm3
	vpacksswb	%xmm3, %xmm3, %xmm3
	vcvttps2dq	%xmm2, %xmm2
	vpshuflw	$232, %xmm2, %xmm2              # xmm2 = xmm2[0,2,2,3,4,5,6,7]
	vpackuswb	%xmm2, %xmm2, %xmm2
	vpor	%xmm2, %xmm3, %xmm2
	cmovnel	%r14d, %ecx
	shll	$16, %eax
	orl	%ecx, %eax
	vpextrb	$1, %xmm2, %ecx
	movzbl	(%r13,%rcx), %ecx
	shll	$8, %ecx
	orl	%eax, %ecx
	vpextrb	$0, %xmm2, %eax
	movzbl	(%r13,%rax), %eax
	orl	%eax, %ecx
	movl	%ecx, (%r9,%rsi,4)
	incq	%rsi
	cmpq	%rsi, %r15
	jne	.LBB0_15
	jmp	.LBB0_22
	.p2align	4, 0x90
.LBB0_6:                                #   in Loop: Header=BB0_5 Depth=1
	movq	48(%rsp), %rcx                  # 8-byte Reload
	imulq	64(%rsp), %rcx                  # 8-byte Folded Reload
	movq	8(%rsp), %rax                   # 8-byte Reload
	leaq	(%rax,%rcx,4), %r8
	movq	16(%rsp), %rax                  # 8-byte Reload
	leaq	(%rax,%rcx,4), %r14
	movq	24(%rsp), %rax                  # 8-byte Reload
	leaq	(%rax,%rcx,4), %rsi
	movq	72(%rsp), %rcx                  # 8-byte Reload
	movq	32(%rsp), %rax                  # 8-byte Reload
	movl	%eax, %r11d
	jmp	.LBB0_7
	.p2align	4, 0x90
.LBB0_24:                               #   in Loop: Header=BB0_7 Depth=2
	vcvtdq2ps	%ymm12, %ymm6
	vcvtdq2ps	%ymm3, %ymm3
	vmulps	%ymm3, %ymm6, %ymm7
	vmulps	%ymm7, %ymm1, %ymm7
	vmovdqa	%ymm15, 160(%rsp)               # 32-byte Spill
	vmovaps	96(%rsp), %ymm15                # 32-byte Reload
	vmulps	%ymm6, %ymm15, %ymm6
	vaddps	%ymm7, %ymm6, %ymm6
	vmulps	%ymm3, %ymm11, %ymm3
	vaddps	%ymm6, %ymm3, %ymm3
	vaddps	%ymm3, %ymm10, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vpmaxsd	%ymm2, %ymm3, %ymm3
	vmovaps	%ymm13, %ymm12
	vmovdqa	%ymm0, %ymm13
	vpminsd	%ymm14, %ymm3, %ymm0
	vcvtdq2ps	%ymm8, %ymm3
	vcvtdq2ps	%ymm5, %ymm5
	vmulps	%ymm5, %ymm3, %ymm6
	vmulps	%ymm6, %ymm1, %ymm6
	vmulps	%ymm3, %ymm15, %ymm3
	vaddps	%ymm6, %ymm3, %ymm3
	vmulps	%ymm5, %ymm11, %ymm5
	vaddps	%ymm3, %ymm5, %ymm3
	vaddps	%ymm3, %ymm10, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vpmaxsd	%ymm2, %ymm3, %ymm3
	vpminsd	%ymm14, %ymm3, %ymm3
	vcvtdq2ps	%ymm9, %ymm5
	vcvtdq2ps	160(%rsp), %ymm6        # 32-byte Folded Reload
	vmulps	%ymm6, %ymm5, %ymm7
	vmulps	%ymm7, %ymm1, %ymm7
	vmulps	%ymm5, %ymm15, %ymm5
	vaddps	%ymm7, %ymm5, %ymm5
	vmulps	%ymm6, %ymm11, %ymm6
	vaddps	%ymm5, %ymm6, %ymm5
	vmovdqa	%ymm0, %ymm6
	vmovdqa	%ymm13, %ymm0
	vmovaps	%ymm12, %ymm13
	vbroadcastss	.LCPI0_0(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vaddps	%ymm5, %ymm10, %ymm5
	vcvttps2dq	%ymm5, %ymm5
	vpmaxsd	%ymm2, %ymm5, %ymm5
	vpminsd	%ymm14, %ymm5, %ymm5
.LBB0_11:                               #   in Loop: Header=BB0_7 Depth=2
	vpslld	$24, %ymm4, %ymm4
	vpslld	$16, %ymm5, %ymm2
	vpor	%ymm4, %ymm2, %ymm2
	vpslld	$8, %ymm3, %ymm3
	vpor	%ymm3, %ymm6, %ymm3
	vpor	%ymm2, %ymm3, %ymm2
	vmovdqu	%ymm2, (%rsi,%r12,4)
	movl	%ecx, %r11d
	leaq	8(%rcx), %r12
	movq	%r12, %rcx
	cmpq	%r15, %r12
	vmovdqa	.LCPI0_4(%rip), %ymm2           # ymm2 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vmovdqa	.LCPI0_3(%rip), %ymm6           # ymm6 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	jg	.LBB0_12
.LBB0_7:                                #   Parent Loop BB0_5 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_9 Depth 3
	movslq	%r11d, %r12
	vmovdqu	(%r8,%r12,4), %ymm3
	vpbroadcastd	.LCPI0_2(%rip), %ymm14  # ymm14 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vmovdqu	(%r14,%r12,4), %ymm4
	vpand	%ymm3, %ymm14, %ymm12
	vmovdqa	%ymm12, 1600(%rsp)
	vpshufb	%ymm6, %ymm3, %ymm5
	vmovdqa	%ymm5, %ymm8
	vmovdqa	%ymm5, 1632(%rsp)
	vpshufb	%ymm2, %ymm3, %ymm9
	vmovdqa	%ymm9, 1664(%rsp)
	vpsrld	$24, %ymm3, %ymm5
	vmovdqa	%ymm5, 1696(%rsp)
	vpand	%ymm4, %ymm14, %ymm3
	vmovdqa	%ymm3, 1472(%rsp)
	vmovdqa	%ymm6, %ymm15
	vpsrld	$24, %ymm4, %ymm6
	vcvtdq2ps	%ymm5, %ymm7
	vpmaddwd	%ymm5, %ymm6, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vmulps	%ymm5, %ymm1, %ymm5
	vmulps	96(%rsp), %ymm7, %ymm7          # 32-byte Folded Reload
	vaddps	%ymm5, %ymm7, %ymm7
	vpshufb	%ymm15, %ymm4, %ymm5
	vmovdqa	%ymm5, 1504(%rsp)
	vpshufb	%ymm2, %ymm4, %ymm15
	vmovdqa	%ymm15, 1536(%rsp)
	vmovdqa	%ymm6, 1568(%rsp)
	vcvtdq2ps	%ymm6, %ymm4
	vmulps	%ymm4, %ymm11, %ymm4
	vaddps	%ymm7, %ymm4, %ymm4
	vaddps	%ymm4, %ymm10, %ymm4
	vcvttps2dq	%ymm4, %ymm4
	vpxor	%xmm2, %xmm2, %xmm2
	vpmaxsd	%ymm2, %ymm4, %ymm4
	vpminsd	%ymm14, %ymm4, %ymm4
	vmovdqa	%ymm4, 1440(%rsp)
	testb	%bl, %bl
	je	.LBB0_24
# %bb.8:                                #   in Loop: Header=BB0_7 Depth=2
	xorl	%r11d, %r11d
	vmovdqa	%ymm14, 160(%rsp)               # 32-byte Spill
	.p2align	4, 0x90
.LBB0_9:                                #   Parent Loop BB0_5 Depth=1
                                        #     Parent Loop BB0_7 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	vmovdqa	1600(%rsp,%r11), %ymm3
	vpsrlw	$4, %ymm3, %ymm4
	vpbroadcastb	.LCPI0_24(%rip), %ymm0  # ymm0 = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15]
	vpand	%ymm0, %ymm3, %ymm3
	vpand	%ymm0, %ymm4, %ymm4
	vmovdqa	1152(%rsp), %ymm13              # 32-byte Reload
	vpshufb	%ymm3, %ymm13, %ymm5
	vpxor	%xmm0, %xmm0, %xmm0
	vpcmpeqb	%ymm0, %ymm4, %ymm6
	vpand	%ymm5, %ymm6, %ymm5
	vmovdqa	1184(%rsp), %ymm0               # 32-byte Reload
	vpshufb	%ymm3, %ymm0, %ymm6
	vpbroadcastb	.LCPI0_25(%rip), %ymm1  # ymm1 = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	vpcmpeqb	%ymm1, %ymm4, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	1216(%rsp), %ymm14              # 32-byte Reload
	vpshufb	%ymm3, %ymm14, %ymm6
	vpbroadcastb	.LCPI0_26(%rip), %ymm1  # ymm1 = [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]
	vpcmpeqb	%ymm1, %ymm4, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	1248(%rsp), %ymm9               # 32-byte Reload
	vpshufb	%ymm3, %ymm9, %ymm7
	vpbroadcastb	.LCPI0_27(%rip), %ymm1  # ymm1 = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
	vpcmpeqb	%ymm1, %ymm4, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	480(%rsp), %ymm1                # 32-byte Reload
	vpshufb	%ymm3, %ymm1, %ymm6
	vpbroadcastb	.LCPI0_28(%rip), %ymm1  # ymm1 = [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
	vpcmpeqb	%ymm1, %ymm4, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	1280(%rsp), %ymm12              # 32-byte Reload
	vpshufb	%ymm3, %ymm12, %ymm7
	vpbroadcastb	.LCPI0_29(%rip), %ymm1  # ymm1 = [5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5]
	vpcmpeqb	%ymm1, %ymm4, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	1312(%rsp), %ymm1               # 32-byte Reload
	vpshufb	%ymm3, %ymm1, %ymm7
	vpbroadcastb	.LCPI0_30(%rip), %ymm2  # ymm2 = [6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6]
	vpcmpeqb	%ymm2, %ymm4, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	256(%rsp), %ymm2                # 32-byte Reload
	vpshufb	%ymm3, %ymm2, %ymm6
	vpbroadcastb	.LCPI0_31(%rip), %ymm7  # ymm7 = [7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7]
	vpcmpeqb	%ymm7, %ymm4, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	320(%rsp), %ymm7                # 32-byte Reload
	vpshufb	%ymm3, %ymm7, %ymm7
	vpbroadcastb	.LCPI0_32(%rip), %ymm8  # ymm8 = [8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8]
	vpcmpeqb	%ymm4, %ymm8, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	608(%rsp), %ymm15               # 32-byte Reload
	vpshufb	%ymm3, %ymm15, %ymm7
	vpbroadcastb	.LCPI0_33(%rip), %ymm8  # ymm8 = [9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9]
	vpcmpeqb	%ymm4, %ymm8, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	384(%rsp), %ymm7                # 32-byte Reload
	vpshufb	%ymm3, %ymm7, %ymm7
	vpbroadcastb	.LCPI0_34(%rip), %ymm8  # ymm8 = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]
	vpcmpeqb	%ymm4, %ymm8, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	352(%rsp), %ymm6                # 32-byte Reload
	vpshufb	%ymm3, %ymm6, %ymm6
	vpbroadcastb	.LCPI0_35(%rip), %ymm7  # ymm7 = [11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11]
	vpcmpeqb	%ymm7, %ymm4, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	448(%rsp), %ymm7                # 32-byte Reload
	vpshufb	%ymm3, %ymm7, %ymm7
	vpbroadcastb	.LCPI0_36(%rip), %ymm8  # ymm8 = [12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12]
	vpcmpeqb	%ymm4, %ymm8, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	416(%rsp), %ymm7                # 32-byte Reload
	vpshufb	%ymm3, %ymm7, %ymm7
	vpbroadcastb	.LCPI0_37(%rip), %ymm8  # ymm8 = [13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13]
	vpcmpeqb	%ymm4, %ymm8, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	544(%rsp), %ymm11               # 32-byte Reload
	vpshufb	%ymm3, %ymm11, %ymm7
	vpbroadcastb	.LCPI0_38(%rip), %ymm8  # ymm8 = [14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14]
	vpcmpeqb	%ymm4, %ymm8, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	576(%rsp), %ymm10               # 32-byte Reload
	vpshufb	%ymm3, %ymm10, %ymm3
	vpbroadcastb	.LCPI0_24(%rip), %ymm7  # ymm7 = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15]
	vpcmpeqb	%ymm7, %ymm4, %ymm4
	vpand	%ymm3, %ymm4, %ymm3
	vpor	%ymm3, %ymm6, %ymm3
	vpor	%ymm3, %ymm5, %ymm3
	vmovdqa	1472(%rsp,%r11), %ymm4
	vpsrlw	$4, %ymm4, %ymm5
	vpand	%ymm7, %ymm4, %ymm4
	vpand	%ymm7, %ymm5, %ymm5
	vpshufb	%ymm4, %ymm13, %ymm6
	vpcmpeqb	.LCPI0_23(%rip), %ymm5, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	.LCPI0_6(%rip), %ymm5, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpshufb	%ymm4, %ymm14, %ymm7
	vpcmpeqb	.LCPI0_7(%rip), %ymm5, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpshufb	%ymm4, %ymm9, %ymm8
	vpbroadcastb	.LCPI0_27(%rip), %ymm13 # ymm13 = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
	vpcmpeqb	%ymm5, %ymm13, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	480(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	.LCPI0_9(%rip), %ymm5, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpshufb	%ymm4, %ymm12, %ymm8
	vpcmpeqb	.LCPI0_10(%rip), %ymm5, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vpshufb	%ymm4, %ymm1, %ymm8
	vpcmpeqb	.LCPI0_11(%rip), %ymm5, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpshufb	%ymm4, %ymm2, %ymm7
	vpcmpeqb	.LCPI0_12(%rip), %ymm5, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vmovdqa	320(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm8
	vpcmpeqb	.LCPI0_13(%rip), %ymm5, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vpshufb	%ymm4, %ymm15, %ymm8
	vpbroadcastb	.LCPI0_33(%rip), %ymm15 # ymm15 = [9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9]
	vpcmpeqb	%ymm5, %ymm15, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vmovdqa	384(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm8
	vpbroadcastb	.LCPI0_34(%rip), %ymm14 # ymm14 = [10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]
	vpcmpeqb	%ymm5, %ymm14, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	352(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpbroadcastb	.LCPI0_35(%rip), %ymm12 # ymm12 = [11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11]
	vpcmpeqb	%ymm5, %ymm12, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vmovdqa	448(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm8
	vpcmpeqb	.LCPI0_17(%rip), %ymm5, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vmovdqa	416(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm8
	vpbroadcastb	.LCPI0_37(%rip), %ymm2  # ymm2 = [13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13]
	vpcmpeqb	%ymm2, %ymm5, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vpor	%ymm7, %ymm8, %ymm7
	vpshufb	%ymm4, %ymm11, %ymm8
	vpbroadcastb	.LCPI0_38(%rip), %ymm1  # ymm1 = [14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14]
	vpcmpeqb	%ymm1, %ymm5, %ymm9
	vpand	%ymm8, %ymm9, %ymm8
	vmovdqa	%ymm10, %ymm0
	vmovaps	224(%rsp), %ymm10               # 32-byte Reload
	vpor	%ymm7, %ymm8, %ymm7
	vpshufb	%ymm4, %ymm0, %ymm4
	vpbroadcastb	.LCPI0_24(%rip), %ymm9  # ymm9 = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15]
	vpcmpeqb	%ymm5, %ymm9, %ymm5
	vpand	%ymm4, %ymm5, %ymm4
	vpor	%ymm4, %ymm7, %ymm4
	vpor	%ymm4, %ymm6, %ymm4
	vcvtdq2ps	%ymm3, %ymm3
	vcvtdq2ps	%ymm4, %ymm4
	vmulps	%ymm4, %ymm3, %ymm5
	vmulps	192(%rsp), %ymm5, %ymm5         # 32-byte Folded Reload
	vmulps	96(%rsp), %ymm3, %ymm3          # 32-byte Folded Reload
	vaddps	%ymm5, %ymm3, %ymm3
	vmulps	288(%rsp), %ymm4, %ymm4         # 32-byte Folded Reload
	vaddps	%ymm3, %ymm4, %ymm3
	vaddps	%ymm3, %ymm10, %ymm3
	vcvttps2dq	%ymm3, %ymm3
	vpxor	%xmm6, %xmm6, %xmm6
	vpmaxsd	%ymm6, %ymm3, %ymm3
	vpminsd	160(%rsp), %ymm3, %ymm4         # 32-byte Folded Reload
	vpsrlw	$4, %ymm4, %ymm3
	vpand	%ymm4, %ymm9, %ymm4
	vmovdqa	640(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm5
	vpcmpeqb	%ymm6, %ymm3, %ymm6
	vpand	%ymm5, %ymm6, %ymm5
	vmovdqa	672(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm6
	vpcmpeqb	.LCPI0_6(%rip), %ymm3, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	704(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm6
	vpcmpeqb	.LCPI0_7(%rip), %ymm3, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	736(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	%ymm3, %ymm13, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	768(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm6
	vpcmpeqb	.LCPI0_9(%rip), %ymm3, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	800(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	.LCPI0_10(%rip), %ymm3, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	832(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	.LCPI0_11(%rip), %ymm3, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	864(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm6
	vpcmpeqb	.LCPI0_12(%rip), %ymm3, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	896(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	.LCPI0_13(%rip), %ymm3, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	928(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	%ymm3, %ymm15, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	960(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	%ymm3, %ymm14, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vpor	%ymm6, %ymm5, %ymm5
	vmovdqa	992(%rsp), %ymm0                # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm6
	vpcmpeqb	%ymm3, %ymm12, %ymm7
	vpand	%ymm6, %ymm7, %ymm6
	vmovdqa	1024(%rsp), %ymm0               # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	.LCPI0_17(%rip), %ymm3, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	1056(%rsp), %ymm0               # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	%ymm2, %ymm3, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	1088(%rsp), %ymm0               # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm7
	vpcmpeqb	%ymm1, %ymm3, %ymm8
	vpand	%ymm7, %ymm8, %ymm7
	vpor	%ymm7, %ymm6, %ymm6
	vmovdqa	1120(%rsp), %ymm0               # 32-byte Reload
	vpshufb	%ymm4, %ymm0, %ymm4
	vpcmpeqb	%ymm3, %ymm9, %ymm3
	vpand	%ymm4, %ymm3, %ymm3
	vpor	%ymm3, %ymm6, %ymm3
	vpor	%ymm3, %ymm5, %ymm3
	vmovdqa	%ymm3, 1344(%rsp,%r11)
	addq	$32, %r11
	cmpq	$96, %r11
	jne	.LBB0_9
# %bb.10:                               #   in Loop: Header=BB0_7 Depth=2
	vmovdqa	1344(%rsp), %ymm6
	vmovdqa	1376(%rsp), %ymm3
	vmovdqa	1408(%rsp), %ymm5
	vmovdqa	1440(%rsp), %ymm4
	vmovdqa	256(%rsp), %ymm0                # 32-byte Reload
	vmovaps	192(%rsp), %ymm1                # 32-byte Reload
	vmovaps	288(%rsp), %ymm11               # 32-byte Reload
	vmovaps	512(%rsp), %ymm13               # 32-byte Reload
	vbroadcastss	.LCPI0_0(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	jmp	.LBB0_11
.LBB0_16:                               #   in Loop: Header=BB0_5 Depth=1
	movq	%r15, %rbx
	subq	%rsi, %rbx
	cmpq	$8, %rbx
	setb	%cl
	orb	7(%rsp), %cl                    # 1-byte Folded Reload
	je	.LBB0_18
# %bb.17:                               #   in Loop: Header=BB0_5 Depth=1
	movq	%rsi, %rcx
	vxorps	%xmm7, %xmm7, %xmm7
	jmp	.LBB0_21
.LBB0_18:                               #   in Loop: Header=BB0_5 Depth=1
	movq	%rbx, %r11
	andq	$-8, %r11
	leaq	(%r11,%rsi), %rcx
	addq	40(%rsp), %rsi                  # 8-byte Folded Reload
	movq	24(%rsp), %rax                  # 8-byte Reload
	leaq	(%rax,%rsi,4), %r14
	movq	16(%rsp), %rax                  # 8-byte Reload
	leaq	(%rax,%rsi,4), %r12
	movq	8(%rsp), %rax                   # 8-byte Reload
	leaq	(%rax,%rsi,4), %rsi
	xorl	%r8d, %r8d
	vmovaps	%ymm11, %ymm10
	vmovaps	%ymm6, %ymm11
	vmovaps	%ymm13, %ymm12
	vmovaps	%ymm5, %ymm13
	vbroadcastss	.LCPI0_0(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vxorps	%xmm1, %xmm1, %xmm1
	vmovdqa	.LCPI0_4(%rip), %ymm9           # ymm9 = [2,128,128,128,6,128,128,128,10,128,128,128,14,128,128,128,18,128,128,128,22,128,128,128,26,128,128,128,30,128,128,128]
	vmovdqa	.LCPI0_3(%rip), %ymm14          # ymm14 = [1,128,128,128,5,128,128,128,9,128,128,128,13,128,128,128,17,128,128,128,21,128,128,128,25,128,128,128,29,128,128,128]
	.p2align	4, 0x90
.LBB0_19:                               #   Parent Loop BB0_5 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovdqu	(%rsi,%r8,4), %ymm3
	vmovdqu	(%r12,%r8,4), %ymm2
	vpsrld	$24, %ymm3, %ymm4
	vpsrld	$24, %ymm2, %ymm5
	vcvtdq2ps	%ymm4, %ymm4
	vdivps	%ymm6, %ymm4, %ymm4
	vcvtdq2ps	%ymm5, %ymm5
	vdivps	%ymm6, %ymm5, %ymm5
	vmulps	%ymm4, %ymm13, %ymm6
	vmulps	%ymm4, %ymm11, %ymm4
	vmulps	%ymm5, %ymm6, %ymm6
	vaddps	%ymm4, %ymm6, %ymm4
	vmulps	%ymm5, %ymm10, %ymm5
	vaddps	%ymm4, %ymm5, %ymm4
	vaddps	%ymm4, %ymm12, %ymm4
	vbroadcastss	.LCPI0_0(%rip), %ymm5   # ymm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmulps	%ymm5, %ymm4, %ymm4
	vmaxps	%ymm4, %ymm1, %ymm4
	vbroadcastss	.LCPI0_0(%rip), %ymm5   # ymm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vminps	%ymm4, %ymm5, %ymm4
	vcvttps2dq	%ymm4, %ymm4
	vpshufb	%ymm9, %ymm3, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vbroadcastss	.LCPI0_0(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%ymm6, %ymm5, %ymm5
	vextracti128	$1, %ymm4, %xmm6
	vpackssdw	%xmm6, %xmm4, %xmm15
	vpshufb	%ymm9, %ymm2, %ymm4
	vcvtdq2ps	%ymm4, %ymm4
	vbroadcastss	.LCPI0_0(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%ymm6, %ymm4, %ymm4
	vmulps	%ymm5, %ymm13, %ymm6
	vmulps	%ymm5, %ymm11, %ymm5
	vmulps	%ymm4, %ymm6, %ymm6
	vaddps	%ymm5, %ymm6, %ymm5
	vmulps	%ymm4, %ymm10, %ymm4
	vaddps	%ymm5, %ymm4, %ymm4
	vaddps	%ymm4, %ymm12, %ymm4
	vbroadcastss	.LCPI0_0(%rip), %ymm5   # ymm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmulps	%ymm5, %ymm4, %ymm4
	vmaxps	%ymm4, %ymm1, %ymm4
	vbroadcastss	.LCPI0_0(%rip), %ymm5   # ymm5 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vminps	%ymm4, %ymm5, %ymm4
	vcvttps2dq	%ymm4, %ymm4
	vextracti128	$1, %ymm4, %xmm5
	vpackssdw	%xmm5, %xmm4, %xmm4
	vpshufb	%ymm14, %ymm3, %ymm5
	vcvtdq2ps	%ymm5, %ymm5
	vpbroadcastd	.LCPI0_2(%rip), %ymm6   # ymm6 = [255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0,255,0,0,0]
	vbroadcastss	.LCPI0_0(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%ymm7, %ymm5, %ymm5
	vpshufb	%ymm14, %ymm2, %ymm7
	vcvtdq2ps	%ymm7, %ymm7
	vbroadcastss	.LCPI0_0(%rip), %ymm8   # ymm8 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%ymm8, %ymm7, %ymm7
	vpackuswb	%xmm4, %xmm4, %xmm4
	vmulps	%ymm5, %ymm13, %ymm8
	vmulps	%ymm5, %ymm11, %ymm5
	vmulps	%ymm7, %ymm8, %ymm8
	vaddps	%ymm5, %ymm8, %ymm5
	vmulps	%ymm7, %ymm10, %ymm7
	vaddps	%ymm5, %ymm7, %ymm5
	vaddps	%ymm5, %ymm12, %ymm5
	vbroadcastss	.LCPI0_0(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmulps	%ymm7, %ymm5, %ymm5
	vmaxps	%ymm5, %ymm1, %ymm5
	vbroadcastss	.LCPI0_0(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vminps	%ymm5, %ymm7, %ymm5
	vcvttps2dq	%ymm5, %ymm5
	vextracti128	$1, %ymm5, %xmm7
	vpackssdw	%xmm7, %xmm5, %xmm5
	vpand	%ymm6, %ymm3, %ymm3
	vcvtdq2ps	%ymm3, %ymm3
	vbroadcastss	.LCPI0_0(%rip), %ymm7   # ymm7 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%ymm7, %ymm3, %ymm3
	vpand	%ymm6, %ymm2, %ymm2
	vcvtdq2ps	%ymm2, %ymm2
	vbroadcastss	.LCPI0_0(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vdivps	%ymm6, %ymm2, %ymm2
	vpackuswb	%xmm5, %xmm5, %xmm5
	vmulps	%ymm3, %ymm13, %ymm6
	vmulps	%ymm3, %ymm11, %ymm3
	vmulps	%ymm2, %ymm6, %ymm6
	vaddps	%ymm3, %ymm6, %ymm3
	vbroadcastss	.LCPI0_0(%rip), %ymm6   # ymm6 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vmulps	%ymm2, %ymm10, %ymm2
	vaddps	%ymm3, %ymm2, %ymm2
	vaddps	%ymm2, %ymm12, %ymm2
	vmulps	%ymm6, %ymm2, %ymm2
	vmaxps	%ymm2, %ymm1, %ymm2
	vminps	%ymm2, %ymm6, %ymm2
	vcvttps2dq	%ymm2, %ymm2
	vextracti128	$1, %ymm2, %xmm3
	vpackssdw	%xmm3, %xmm2, %xmm2
	vpackuswb	%xmm2, %xmm2, %xmm2
	vpmovzxwd	%xmm15, %ymm3           # ymm3 = xmm15[0],zero,xmm15[1],zero,xmm15[2],zero,xmm15[3],zero,xmm15[4],zero,xmm15[5],zero,xmm15[6],zero,xmm15[7],zero
	vpslld	$24, %ymm3, %ymm3
	vpmovzxbd	%xmm4, %ymm4            # ymm4 = xmm4[0],zero,zero,zero,xmm4[1],zero,zero,zero,xmm4[2],zero,zero,zero,xmm4[3],zero,zero,zero,xmm4[4],zero,zero,zero,xmm4[5],zero,zero,zero,xmm4[6],zero,zero,zero,xmm4[7],zero,zero,zero
	vpslld	$16, %ymm4, %ymm4
	vpor	%ymm3, %ymm4, %ymm3
	vpmovzxbd	%xmm5, %ymm4            # ymm4 = xmm5[0],zero,zero,zero,xmm5[1],zero,zero,zero,xmm5[2],zero,zero,zero,xmm5[3],zero,zero,zero,xmm5[4],zero,zero,zero,xmm5[5],zero,zero,zero,xmm5[6],zero,zero,zero,xmm5[7],zero,zero,zero
	vpslld	$8, %ymm4, %ymm4
	vpmovzxbd	%xmm2, %ymm2            # ymm2 = xmm2[0],zero,zero,zero,xmm2[1],zero,zero,zero,xmm2[2],zero,zero,zero,xmm2[3],zero,zero,zero,xmm2[4],zero,zero,zero,xmm2[5],zero,zero,zero,xmm2[6],zero,zero,zero,xmm2[7],zero,zero,zero
	vpor	%ymm2, %ymm4, %ymm2
	vpor	%ymm2, %ymm3, %ymm2
	vmovdqu	%ymm2, (%r14,%r8,4)
	addq	$8, %r8
	cmpq	%r8, %r11
	jne	.LBB0_19
# %bb.20:                               #   in Loop: Header=BB0_5 Depth=1
	cmpq	%r11, %rbx
	vmovaps	192(%rsp), %ymm1                # 32-byte Reload
	vmovaps	%ymm10, %ymm11
	vmovaps	224(%rsp), %ymm10               # 32-byte Reload
	vmovaps	%ymm12, %ymm13
	vbroadcastss	.LCPI0_0(%rip), %xmm12  # xmm12 = [2.55E+2,2.55E+2,2.55E+2,2.55E+2]
	vxorps	%xmm7, %xmm7, %xmm7
	je	.LBB0_22
	.p2align	4, 0x90
.LBB0_21:                               #   Parent Loop BB0_5 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	(%rdx,%rcx,4), %esi
	movl	(%rdi,%rcx,4), %r11d
	vmovd	%esi, %xmm3
	movl	$-16777216, %ebx                # imm = 0xFF000000
	movzbl	%sil, %r14d
	movl	%esi, %r12d
	shrl	$24, %r12d
	movl	%r11d, %r8d
	movl	%r11d, %esi
	movq	%r13, %rax
	movzbl	%r11b, %r13d
	shrl	$24, %r11d
	shrl	$16, %r8d
	shrl	$8, %esi
	vpbroadcastq	.LCPI0_20(%rip), %xmm2  # xmm2 = [16,8,16,8]
	vpbroadcastd	%xmm3, %xmm3
	vpsrlvd	%xmm2, %xmm3, %xmm3
	vpand	.LCPI0_21(%rip), %xmm3, %xmm3
	vcvtdq2ps	%xmm3, %xmm3
	vdivps	%xmm12, %xmm3, %xmm3
	vmovd	%r14d, %xmm4
	vpinsrb	$4, %r12d, %xmm4, %xmm4
	vcvtdq2ps	%xmm4, %xmm4
	vmovd	%r13d, %xmm5
	movq	%rax, %r13
	vpinsrb	$4, %r11d, %xmm5, %xmm5
	vdivps	%xmm12, %xmm4, %xmm4
	vcvtdq2ps	%xmm5, %xmm5
	vdivps	%xmm12, %xmm5, %xmm5
	vmulps	128(%rsp), %xmm4, %xmm6         # 16-byte Folded Reload
	vmulps	96(%rsp), %xmm4, %xmm4          # 16-byte Folded Reload
	vmulps	%xmm5, %xmm6, %xmm6
	vaddps	%xmm4, %xmm6, %xmm4
	vmovaps	96(%rsp), %ymm6                 # 32-byte Reload
	vmulps	%xmm5, %xmm11, %xmm5
	vaddps	%xmm4, %xmm5, %xmm4
	vaddps	%xmm4, %xmm13, %xmm4
	vmulps	%xmm4, %xmm12, %xmm4
	vmaxps	%xmm4, %xmm7, %xmm4
	vcmpltps	%xmm4, %xmm12, %xmm5
	vshufps	$80, %xmm5, %xmm5, %xmm5        # xmm5 = xmm5[0,0,1,1]
	vmovmskpd	%xmm5, %r11d
	vmovshdup	%xmm4, %xmm5            # xmm5 = xmm4[1,1,3,3]
	vcvttss2si	%xmm5, %r14d
	vcvttss2si	%xmm4, %r12d
	shll	$24, %r14d
	testb	$2, %r11b
	cmovnel	%ebx, %r14d
	movzbl	%r8b, %r8d
	vmovd	%r8d, %xmm4
	vpinsrb	$4, %esi, %xmm4, %xmm4
	movzbl	%r12b, %esi
	vcvtdq2ps	%xmm4, %xmm4
	vdivps	%xmm12, %xmm4, %xmm4
	vmulps	128(%rsp), %xmm3, %xmm5         # 16-byte Folded Reload
	vmulps	%xmm6, %xmm3, %xmm3
	vmulps	%xmm4, %xmm5, %xmm5
	vaddps	%xmm3, %xmm5, %xmm3
	vmulps	%xmm4, %xmm11, %xmm4
	vaddps	%xmm3, %xmm4, %xmm3
	vaddps	%xmm3, %xmm13, %xmm3
	vmulps	%xmm3, %xmm12, %xmm3
	vmaxps	%xmm3, %xmm7, %xmm3
	vminps	%xmm3, %xmm12, %xmm3
	vcvttps2dq	%xmm3, %xmm3
	vpshufb	.LCPI0_22(%rip), %xmm3, %xmm3   # xmm3 = xmm3[0],zero,zero,zero,xmm3[4],zero,zero,zero,xmm3[u,u,u,u,u,u,u,u]
	vpsllvd	%xmm2, %xmm3, %xmm2
	vmovd	%xmm2, %r8d
	orl	%r14d, %r8d
	vpextrd	$1, %xmm2, %r14d
	orl	%r8d, %r14d
	testb	$1, %r11b
	movl	$255, %eax
	cmovnel	%eax, %esi
	orl	%r14d, %esi
	movl	%esi, (%r9,%rcx,4)
	incq	%rcx
	cmpq	%rcx, %r15
	jne	.LBB0_21
	jmp	.LBB0_22
.LBB0_23:
	leaq	-40(%rbp), %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	vzeroupper
	retq
.Lfunc_end0:
SIZE(SYM(ksvgArithmeticApplyAvx2))

.p2align 5
.LCPI0_0:
	.long	0x437f0000                      # float 255
.LCPI0_1:
	.long	0x3f000000                      # float 0.5
.LCPI0_2:
	.byte	255                             # 0xff
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.p2align	5, 0x0
.LCPI0_3:
	.byte	1                               # 0x1
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	5                               # 0x5
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	9                               # 0x9
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	13                              # 0xd
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	17                              # 0x11
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	21                              # 0x15
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	25                              # 0x19
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	29                              # 0x1d
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
.LCPI0_4:
	.byte	2                               # 0x2
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	6                               # 0x6
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	10                              # 0xa
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	14                              # 0xe
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	18                              # 0x12
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	22                              # 0x16
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	26                              # 0x1a
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	30                              # 0x1e
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
.LCPI0_5:
	.zero	32,15
.LCPI0_6:
	.zero	32,1
.LCPI0_7:
	.zero	32,2
.LCPI0_8:
	.zero	32,3
.LCPI0_9:
	.zero	32,4
.LCPI0_10:
	.zero	32,5
.LCPI0_11:
	.zero	32,6
.LCPI0_12:
	.zero	32,7
.LCPI0_13:
	.zero	32,8
.LCPI0_14:
	.zero	32,9
.LCPI0_15:
	.zero	32,10
.LCPI0_16:
	.zero	32,11
.LCPI0_17:
	.zero	32,12
.LCPI0_18:
	.zero	32,13
.LCPI0_19:
	.zero	32,14
.LCPI0_23:
	.zero	32
	.p2align	3, 0x0
.LCPI0_20:
	.long	16                              # 0x10
	.long	8                               # 0x8
	.p2align	4, 0x0
.LCPI0_21:
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
.LCPI0_22:
	.byte	0                               # 0x0
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	4                               # 0x4
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.byte	128                             # 0x80
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
.LCPI0_24:
	.byte	15                              # 0xf
.LCPI0_25:
	.byte	1                               # 0x1
.LCPI0_26:
	.byte	2                               # 0x2
.LCPI0_27:
	.byte	3                               # 0x3
.LCPI0_28:
	.byte	4                               # 0x4
.LCPI0_29:
	.byte	5                               # 0x5
.LCPI0_30:
	.byte	6                               # 0x6
.LCPI0_31:
	.byte	7                               # 0x7
.LCPI0_32:
	.byte	8                               # 0x8
.LCPI0_33:
	.byte	9                               # 0x9
.LCPI0_34:
	.byte	10                              # 0xa
.LCPI0_35:
	.byte	11                              # 0xb
.LCPI0_36:
	.byte	12                              # 0xc
.LCPI0_37:
	.byte	13                              # 0xd
.LCPI0_38:
	.byte	14                              # 0xe
	.p2align	4, 0x90

