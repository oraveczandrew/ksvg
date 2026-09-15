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
#include "lighting_x86_64_avx2_macros.S"

/*
 * Description:
 *   Amortized linear->sRGB conversion for one byte 0..255: exact value for
 *   0..15 via table entry 0, otherwise base + slope interpolation followed by
 *   the per-bit correction set (correction_lo/correction_hi AND onehot).
 *   Matches the pre-existing file-local definition in
 *   lighting_distant_specular_x86_64_avx2.S.
 *
 * Inputs:
 *   \reg  = 32-bit general-purpose register holding the linear intensity (0..255)
 *   %r11  = base of a .Lspec_l2s_data-shaped LUT (loaded by the caller)
 *
 * Output:
 *   \reg  = sRGB byte value, stored through %r9d (top bits zeroed)
 *
 * Clobbers:
 *   \reg      (in-place)
 *   %r8d, %r9d, %r10d
 *
 * Uses \@-suffixed local labels; caller keeps its loop index / loop limit in
 * its own registers.
 */
.macro L2S1 reg
    movl \reg, %r10d
    cmpl $16, %r10d
    jb .Lspec_l2s_exact_\@

    movl %r10d, %r9d
    shrl $4, %r9d
    movl %r9d, %r8d
    movzbl 16(%r11,%r9,1), %r9d
    movzbl 32(%r11,%r8,1), %r8d
    andl $15, %r10d
    imull %r10d, %r8d
    addl $16, %r8d
    shrl $5, %r8d
    addl %r8d, %r9d

    movl \reg, %r10d
    shrl $3, %r10d
    movl %r10d, %r8d
    andl $7, %r8d
    cmpl $16, %r10d
    jb .Lspec_l2s_corr_lo_\@
    subl $16, %r10d
    movzbl 64(%r11,%r10,1), %r10d
    jmp .Lspec_l2s_corr_mask_\@
.Lspec_l2s_corr_lo_\@:
    movzbl 48(%r11,%r10,1), %r10d
.Lspec_l2s_corr_mask_\@:
    movzbl 80(%r11,%r8,1), %r8d
    testb %r8b, %r10b
    setne %r8b
    movzbl %r8b, %r8d
    subl %r8d, %r9d
    movl %r9d, \reg
    jmp .Lspec_l2s_done_\@

.Lspec_l2s_exact_\@:
    movzbl 0(%r11,%r10,1), %r10d
    movl %r10d, \reg
.Lspec_l2s_done_\@:
.endm

.text
.p2align 4
.globl SYM(ksvgLightingDistantSpecularRowAvx2)
TYPE(SYM(ksvgLightingDistantSpecularRowAvx2), @function)
SYM(ksvgLightingDistantSpecularRowAvx2):
# %bb.0:
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	andq	$-64, %rsp
	subq	$320, %rsp                      # imm = 0x140
                                        # kill: def $r8d killed $r8d def $r8
	movq	%rdx, 48(%rsp)                  # 8-byte Spill
	movq	%rsi, 40(%rsp)                  # 8-byte Spill
	movq	%rdi, 32(%rsp)                  # 8-byte Spill
	testl	%r8d, %r8d
	jle	.LBB1_20
# %bb.1:
	movq	%r9, %rbx
	movq	%rcx, %r15
	movq	%r8, %rax
	vbroadcastss	(%r9), %ymm1
	vmovaps	%ymm1, 224(%rsp)                # 32-byte Spill
	vbroadcastss	12(%r9), %ymm1
	vbroadcastss	16(%r9), %ymm2
	vmovss	20(%r9), %xmm3                  # xmm3 = mem[0],zero,zero,zero
	vaddss	.LCPI1_0(%rip), %xmm3, %xmm3
	vmulss	%xmm2, %xmm2, %xmm4
	vmulss	%xmm1, %xmm1, %xmm5
	vaddss	%xmm4, %xmm5, %xmm4
	vmulss	%xmm3, %xmm3, %xmm5
	vaddss	%xmm4, %xmm5, %xmm4
	vbroadcastss	%xmm4, %ymm4
	vsqrtps	%ymm4, %ymm4
	vdivps	%ymm4, %ymm1, %ymm1
	vmovaps	%ymm1, 192(%rsp)                # 32-byte Spill
	vdivps	%ymm4, %ymm2, %ymm1
	vmovaps	%ymm1, 160(%rsp)                # 32-byte Spill
	vbroadcastss	%xmm3, %ymm1
	vdivps	%ymm4, %ymm1, %ymm1
	vmovaps	%ymm1, 128(%rsp)                # 32-byte Spill
	vbroadcastss	4(%r9), %ymm1
	vmovaps	%ymm1, 96(%rsp)                 # 32-byte Spill
	vcvtss2sd	%xmm0, %xmm0, %xmm0
	vmovsd	%xmm0, 56(%rsp)                 # 8-byte Spill
	decl	%eax
	shrl	$3, %eax
	incl	%eax
	movq	%rax, 24(%rsp)                  # 8-byte Spill
	xorl	%r13d, %r13d
	xorl	%r12d, %r12d
	jmp	.LBB1_2
.LBB1_19:                               #   in Loop: Header=BB1_2 Depth=1
	addq	$8, %r13
	incq	%r12
	addq	$32, %r15
	cmpq	24(%rsp), %r12                  # 8-byte Folded Reload
	je	.LBB1_20
.LBB1_2:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_3 Depth 2
	vbroadcastss	36(%rbx), %ymm0
	movq	32(%rsp), %rax                  # 8-byte Reload
	vmovdqu	(%rax,%r13,4), %ymm1
	vmovdqu	4(%rax,%r13,4), %ymm2
	vmovdqu	8(%rax,%r13,4), %ymm3
	ALPHA_FSCALE %ymm1, %ymm1, %ymm0, %ymm1
	ALPHA_FSCALE %ymm2, %ymm2, %ymm0, %ymm2
	ALPHA_FSCALE %ymm3, %ymm3, %ymm0, %ymm3
	movq	40(%rsp), %rax                  # 8-byte Reload
	vmovdqu	(%rax,%r13,4), %ymm4
	vmovdqu	8(%rax,%r13,4), %ymm5
	ALPHA_FSCALE %ymm4, %ymm4, %ymm0, %ymm4
	ALPHA_FSCALE %ymm5, %ymm5, %ymm0, %ymm5
	movq	48(%rsp), %rax                  # 8-byte Reload
	vmovdqu	(%rax,%r13,4), %ymm6
	vmovdqu	4(%rax,%r13,4), %ymm7
	vmovdqu	8(%rax,%r13,4), %ymm8
	ALPHA_FSCALE %ymm6, %ymm6, %ymm0, %ymm6
	vpsrld	$24, %ymm7, %ymm7
	vcvtdq2ps	%ymm7, %ymm7
	vpsrld	$24, %ymm8, %ymm8
	vcvtdq2ps	%ymm8, %ymm8
	vmulps	%ymm0, %ymm8, %ymm8
	vaddps	%ymm5, %ymm5, %ymm5
	vaddps	%ymm3, %ymm5, %ymm5
	vaddps	%ymm5, %ymm8, %ymm5
	vaddps	%ymm4, %ymm4, %ymm4
	vaddps	%ymm1, %ymm4, %ymm4
	vaddps	%ymm6, %ymm4, %ymm4
	vsubps	%ymm4, %ymm5, %ymm4
	vdivps	224(%rsp), %ymm4, %ymm4         # 32-byte Folded Reload
	vmulps	%ymm7, %ymm0, %ymm0
	vaddps	%ymm0, %ymm0, %ymm0
	vaddps	%ymm6, %ymm0, %ymm0
	vaddps	%ymm0, %ymm8, %ymm0
	vaddps	%ymm2, %ymm2, %ymm2
	vaddps	%ymm1, %ymm2, %ymm1
	vaddps	%ymm3, %ymm1, %ymm1
	vsubps	%ymm1, %ymm0, %ymm0
	vdivps	96(%rsp), %ymm0, %ymm0          # 32-byte Folded Reload
	vxorps	%xmm5, %xmm5, %xmm5
	vsubps	%ymm4, %ymm5, %ymm1
	vsubps	%ymm0, %ymm5, %ymm0
	vmulps	%ymm0, %ymm0, %ymm2
	vmulps	%ymm1, %ymm1, %ymm3
	vaddps	%ymm2, %ymm3, %ymm2
	vbroadcastss	.LCPI1_0(%rip), %ymm3   # ymm3 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	vaddps	%ymm3, %ymm2, %ymm2
	vsqrtps	%ymm2, %ymm2
	vdivps	%ymm2, %ymm1, %ymm1
	vdivps	%ymm2, %ymm0, %ymm0
	vmulps	192(%rsp), %ymm1, %ymm1         # 32-byte Folded Reload
	vmulps	160(%rsp), %ymm0, %ymm0         # 32-byte Folded Reload
	vaddps	%ymm0, %ymm1, %ymm0
	vdivps	%ymm2, %ymm3, %ymm1
	vmulps	128(%rsp), %ymm1, %ymm1         # 32-byte Folded Reload
	vaddps	%ymm0, %ymm1, %ymm0
	vmaxps	%ymm5, %ymm0, %ymm0
	vmovaps	%ymm0, 64(%rsp)
	xorl	%r14d, %r14d
	jmp	.LBB1_3
.LBB1_18:                               #   in Loop: Header=BB1_3 Depth=2
	cmpl	%edx, %eax
	movl	%edx, %eax
	cmovgl	%ecx, %eax
	cmpl	%esi, %eax
	cmovbel	%esi, %eax
	shll	$24, %eax
	shll	$16, %ecx
	shll	$8, %edx
	orl	%ecx, %edx
	orl	%esi, %edx
	orl	%eax, %edx
	movl	%edx, (%r15,%r14,4)
	incq	%r14
	cmpq	$8, %r14
	je	.LBB1_19
.LBB1_3:                                #   Parent Loop BB1_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovss	64(%rsp,%r14,4), %xmm0          # xmm0 = mem[0],zero,zero,zero
	vcvtss2sd	%xmm0, %xmm0, %xmm0
	vmovsd	56(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	vzeroupper
	CALL(pow)
	vcvtsd2ss	%xmm0, %xmm0, %xmm0
	vmulss	8(%rbx), %xmm0, %xmm1
	vxorps	%xmm0, %xmm0, %xmm0
	vucomiss	%xmm1, %xmm0
	ja	.LBB1_6
# %bb.4:                                #   in Loop: Header=BB1_3 Depth=2
	vucomiss	.LCPI1_0(%rip), %xmm1
	vmovaps	%xmm1, %xmm0
	jbe	.LBB1_6
# %bb.5:                                #   in Loop: Header=BB1_3 Depth=2
	vmovss	.LCPI1_0(%rip), %xmm0           # xmm0 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
.LBB1_6:                                #   in Loop: Header=BB1_3 Depth=2
	vmulss	24(%rbx), %xmm0, %xmm1
	vroundss	$11, %xmm1, %xmm1, %xmm1
	vcvttss2si	%xmm1, %eax
	vmulss	28(%rbx), %xmm0, %xmm1
	vmulss	32(%rbx), %xmm0, %xmm0
	cmpl	$255, %eax
	jge	.LBB1_7
# %bb.8:                                #   in Loop: Header=BB1_3 Depth=2
	movl	%eax, %ecx
	testl	%eax, %eax
	jle	.LBB1_9
.LBB1_10:                               #   in Loop: Header=BB1_3 Depth=2
	vroundss	$11, %xmm1, %xmm1, %xmm1
	vcvttss2si	%xmm1, %edx
	cmpl	$255, %edx
	jge	.LBB1_11
.LBB1_12:                               #   in Loop: Header=BB1_3 Depth=2
	testl	%edx, %edx
	jle	.LBB1_13
.LBB1_14:                               #   in Loop: Header=BB1_3 Depth=2
	vroundss	$11, %xmm0, %xmm0, %xmm0
	vcvttss2si	%xmm0, %esi
	cmpl	$255, %esi
	jge	.LBB1_15
.LBB1_16:                               #   in Loop: Header=BB1_3 Depth=2
	testl	%esi, %esi
	jg	.LBB1_18
	jmp	.LBB1_17
.LBB1_7:                                #   in Loop: Header=BB1_3 Depth=2
	movl	$255, %eax
	movl	%eax, %ecx
	testl	%eax, %eax
	jg	.LBB1_10
.LBB1_9:                                #   in Loop: Header=BB1_3 Depth=2
	xorl	%ecx, %ecx
	vroundss	$11, %xmm1, %xmm1, %xmm1
	vcvttss2si	%xmm1, %edx
	cmpl	$255, %edx
	jl	.LBB1_12
.LBB1_11:                               #   in Loop: Header=BB1_3 Depth=2
	movl	$255, %edx
	testl	%edx, %edx
	jg	.LBB1_14
.LBB1_13:                               #   in Loop: Header=BB1_3 Depth=2
	xorl	%edx, %edx
	vroundss	$11, %xmm0, %xmm0, %xmm0
	vcvttss2si	%xmm0, %esi
	cmpl	$255, %esi
	jl	.LBB1_16
.LBB1_15:                               #   in Loop: Header=BB1_3 Depth=2
	movl	$255, %esi
	testl	%esi, %esi
	jg	.LBB1_18
.LBB1_17:                               #   in Loop: Header=BB1_3 Depth=2
	xorl	%esi, %esi
	jmp	.LBB1_18
.LBB1_20:
	leaq	-40(%rbp), %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
.Lfunc_end1:
                                        # -- End function



.text
.p2align 4
.globl SYM(ksvgLightingDistantSpecularRowAvx2Linear)
TYPE(SYM(ksvgLightingDistantSpecularRowAvx2Linear), @function)
SYM(ksvgLightingDistantSpecularRowAvx2Linear):
# %bb.0:
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%r15
	pushq	%r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	andq	$-64, %rsp
	subq	$320, %rsp                      # imm = 0x140
                                        # kill: def $r8d killed $r8d def $r8
	movq	%rdx, 48(%rsp)                  # 8-byte Spill
	movq	%rsi, 40(%rsp)                  # 8-byte Spill
	movq	%rdi, 32(%rsp)                  # 8-byte Spill
	testl	%r8d, %r8d
	jle	.LBS1_20
# %bb.1:
	movq	%r9, %rbx
	movq	%rcx, %r15
	movq	%r8, %rax
	vbroadcastss	(%r9), %ymm1
	vmovaps	%ymm1, 224(%rsp)                # 32-byte Spill
	vbroadcastss	12(%r9), %ymm1
	vbroadcastss	16(%r9), %ymm2
	vmovss	20(%r9), %xmm3                  # xmm3 = mem[0],zero,zero,zero
	vaddss	.LCPI1_0(%rip), %xmm3, %xmm3
	vmulss	%xmm2, %xmm2, %xmm4
	vmulss	%xmm1, %xmm1, %xmm5
	vaddss	%xmm4, %xmm5, %xmm4
	vmulss	%xmm3, %xmm3, %xmm5
	vaddss	%xmm4, %xmm5, %xmm4
	vbroadcastss	%xmm4, %ymm4
	vsqrtps	%ymm4, %ymm4
	vdivps	%ymm4, %ymm1, %ymm1
	vmovaps	%ymm1, 192(%rsp)                # 32-byte Spill
	vdivps	%ymm4, %ymm2, %ymm1
	vmovaps	%ymm1, 160(%rsp)                # 32-byte Spill
	vbroadcastss	%xmm3, %ymm1
	vdivps	%ymm4, %ymm1, %ymm1
	vmovaps	%ymm1, 128(%rsp)                # 32-byte Spill
	vbroadcastss	4(%r9), %ymm1
	vmovaps	%ymm1, 96(%rsp)                 # 32-byte Spill
	vcvtss2sd	%xmm0, %xmm0, %xmm0
	vmovsd	%xmm0, 56(%rsp)                 # 8-byte Spill
	decl	%eax
	shrl	$3, %eax
	incl	%eax
	movq	%rax, 24(%rsp)                  # 8-byte Spill
	xorl	%r13d, %r13d
	xorl	%r12d, %r12d
	jmp	.LBS1_2
.LBS1_19:                               #   in Loop: Header=BB1_2 Depth=1
	addq	$8, %r13
	incq	%r12
	addq	$32, %r15
	cmpq	24(%rsp), %r12                  # 8-byte Folded Reload
	je	.LBS1_20
.LBS1_2:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_3 Depth 2
	vbroadcastss	36(%rbx), %ymm0
	movq	32(%rsp), %rax                  # 8-byte Reload
	vmovdqu	(%rax,%r13,4), %ymm1
	vmovdqu	4(%rax,%r13,4), %ymm2
	vmovdqu	8(%rax,%r13,4), %ymm3
	ALPHA_FSCALE %ymm1, %ymm1, %ymm0, %ymm1
	ALPHA_FSCALE %ymm2, %ymm2, %ymm0, %ymm2
	ALPHA_FSCALE %ymm3, %ymm3, %ymm0, %ymm3
	movq	40(%rsp), %rax                  # 8-byte Reload
	vmovdqu	(%rax,%r13,4), %ymm4
	vmovdqu	8(%rax,%r13,4), %ymm5
	ALPHA_FSCALE %ymm4, %ymm4, %ymm0, %ymm4
	ALPHA_FSCALE %ymm5, %ymm5, %ymm0, %ymm5
	movq	48(%rsp), %rax                  # 8-byte Reload
	vmovdqu	(%rax,%r13,4), %ymm6
	vmovdqu	4(%rax,%r13,4), %ymm7
	vmovdqu	8(%rax,%r13,4), %ymm8
	ALPHA_FSCALE %ymm6, %ymm6, %ymm0, %ymm6
	vpsrld	$24, %ymm7, %ymm7
	vcvtdq2ps	%ymm7, %ymm7
	vpsrld	$24, %ymm8, %ymm8
	vcvtdq2ps	%ymm8, %ymm8
	vmulps	%ymm0, %ymm8, %ymm8
	vaddps	%ymm5, %ymm5, %ymm5
	vaddps	%ymm3, %ymm5, %ymm5
	vaddps	%ymm5, %ymm8, %ymm5
	vaddps	%ymm4, %ymm4, %ymm4
	vaddps	%ymm1, %ymm4, %ymm4
	vaddps	%ymm6, %ymm4, %ymm4
	vsubps	%ymm4, %ymm5, %ymm4
	vdivps	224(%rsp), %ymm4, %ymm4         # 32-byte Folded Reload
	vmulps	%ymm7, %ymm0, %ymm0
	vaddps	%ymm0, %ymm0, %ymm0
	vaddps	%ymm6, %ymm0, %ymm0
	vaddps	%ymm0, %ymm8, %ymm0
	vaddps	%ymm2, %ymm2, %ymm2
	vaddps	%ymm1, %ymm2, %ymm1
	vaddps	%ymm3, %ymm1, %ymm1
	vsubps	%ymm1, %ymm0, %ymm0
	vdivps	96(%rsp), %ymm0, %ymm0          # 32-byte Folded Reload
	vxorps	%xmm5, %xmm5, %xmm5
	vsubps	%ymm4, %ymm5, %ymm1
	vsubps	%ymm0, %ymm5, %ymm0
	vmulps	%ymm0, %ymm0, %ymm2
	vmulps	%ymm1, %ymm1, %ymm3
	vaddps	%ymm2, %ymm3, %ymm2
	vbroadcastss	.LCPI1_0(%rip), %ymm3   # ymm3 = [1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0,1.0E+0]
	vaddps	%ymm3, %ymm2, %ymm2
	vsqrtps	%ymm2, %ymm2
	vdivps	%ymm2, %ymm1, %ymm1
	vdivps	%ymm2, %ymm0, %ymm0
	vmulps	192(%rsp), %ymm1, %ymm1         # 32-byte Folded Reload
	vmulps	160(%rsp), %ymm0, %ymm0         # 32-byte Folded Reload
	vaddps	%ymm0, %ymm1, %ymm0
	vdivps	%ymm2, %ymm3, %ymm1
	vmulps	128(%rsp), %ymm1, %ymm1         # 32-byte Folded Reload
	vaddps	%ymm0, %ymm1, %ymm0
	vmaxps	%ymm5, %ymm0, %ymm0
	vmovaps	%ymm0, 64(%rsp)
	xorl	%r14d, %r14d
	jmp	.LBS1_3
.LBS1_18:                               #   in Loop: Header=BB1_3 Depth=2
	leaq	.Lspec_l2s_data(%rip), %r11
	L2S1 %eax
	L2S1 %edx
	L2S1 %esi
	cmpl	%edx, %eax
	movl	%edx, %eax
	cmovgl	%ecx, %eax
	cmpl	%esi, %eax
	cmovbel	%esi, %eax
	shll	$24, %eax
	shll	$16, %ecx
	shll	$8, %edx
	orl	%ecx, %edx
	orl	%esi, %edx
	orl	%eax, %edx
	movl	%edx, (%r15,%r14,4)
	incq	%r14
	cmpq	$8, %r14
	je	.LBS1_19
.LBS1_3:                                #   Parent Loop BB1_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	vmovss	64(%rsp,%r14,4), %xmm0          # xmm0 = mem[0],zero,zero,zero
	vcvtss2sd	%xmm0, %xmm0, %xmm0
	vmovsd	56(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	vzeroupper
	CALL(pow)
	vcvtsd2ss	%xmm0, %xmm0, %xmm0
	vmulss	8(%rbx), %xmm0, %xmm1
	vxorps	%xmm0, %xmm0, %xmm0
	vucomiss	%xmm1, %xmm0
	ja	.LBS1_6
# %bb.4:                                #   in Loop: Header=BB1_3 Depth=2
	vucomiss	.LCPI1_0(%rip), %xmm1
	vmovaps	%xmm1, %xmm0
	jbe	.LBS1_6
# %bb.5:                                #   in Loop: Header=BB1_3 Depth=2
	vmovss	.LCPI1_0(%rip), %xmm0           # xmm0 = [1.0E+0,0.0E+0,0.0E+0,0.0E+0]
.LBS1_6:                                #   in Loop: Header=BB1_3 Depth=2
	vmulss	24(%rbx), %xmm0, %xmm1
	vroundss	$11, %xmm1, %xmm1, %xmm1
	vcvttss2si	%xmm1, %eax
	vmulss	28(%rbx), %xmm0, %xmm1
	vmulss	32(%rbx), %xmm0, %xmm0
	cmpl	$255, %eax
	jge	.LBS1_7
# %bb.8:                                #   in Loop: Header=BB1_3 Depth=2
	movl	%eax, %ecx
	testl	%eax, %eax
	jle	.LBS1_9
.LBS1_10:                               #   in Loop: Header=BB1_3 Depth=2
	vroundss	$11, %xmm1, %xmm1, %xmm1
	vcvttss2si	%xmm1, %edx
	cmpl	$255, %edx
	jge	.LBS1_11
.LBS1_12:                               #   in Loop: Header=BB1_3 Depth=2
	testl	%edx, %edx
	jle	.LBS1_13
.LBS1_14:                               #   in Loop: Header=BB1_3 Depth=2
	vroundss	$11, %xmm0, %xmm0, %xmm0
	vcvttss2si	%xmm0, %esi
	cmpl	$255, %esi
	jge	.LBS1_15
.LBS1_16:                               #   in Loop: Header=BB1_3 Depth=2
	testl	%esi, %esi
	jg	.LBS1_18
	jmp	.LBS1_17
.LBS1_7:                                #   in Loop: Header=BB1_3 Depth=2
	movl	$255, %eax
	movl	%eax, %ecx
	testl	%eax, %eax
	jg	.LBS1_10
.LBS1_9:                                #   in Loop: Header=BB1_3 Depth=2
	xorl	%ecx, %ecx
	vroundss	$11, %xmm1, %xmm1, %xmm1
	vcvttss2si	%xmm1, %edx
	cmpl	$255, %edx
	jl	.LBS1_12
.LBS1_11:                               #   in Loop: Header=BB1_3 Depth=2
	movl	$255, %edx
	testl	%edx, %edx
	jg	.LBS1_14
.LBS1_13:                               #   in Loop: Header=BB1_3 Depth=2
	xorl	%edx, %edx
	vroundss	$11, %xmm0, %xmm0, %xmm0
	vcvttss2si	%xmm0, %esi
	cmpl	$255, %esi
	jl	.LBS1_16
.LBS1_15:                               #   in Loop: Header=BB1_3 Depth=2
	movl	$255, %esi
	testl	%esi, %esi
	jg	.LBS1_18
.LBS1_17:                               #   in Loop: Header=BB1_3 Depth=2
	xorl	%esi, %esi
	jmp	.LBS1_18
.LBS1_20:
	leaq	-40(%rbp), %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
.Lfunc_end_linear:
//// SIZE(ksvgLightingDistantSpecularRowAvx2Linear)



.p2align 4
.Lspec_l2s_data:
    /* exact low 16 */
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
    /* base[16] */
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
    /* slope[16] */
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
    /* correction_lo[16] */
    .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
    /* correction_hi[16] */
    .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
    /* onehot[8] */
    .byte 1,2,4,8,16,32,64,128

RODATA
.p2align 4
.LCPI1_0:
	.long	0x3f800000
.p2align 4                      # float 1
