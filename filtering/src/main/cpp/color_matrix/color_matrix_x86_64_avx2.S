/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/*
 * x86-64 AVX2 implementation of ColorMatrix (4x5 matrix, SVG 0..1 semantics).
 * 8-wide twin of color_matrix_x86_64_ssse3.S: same algorithm, same bit-exact
 * guarantees (correctly-rounded `vdivps`, left-to-right rows, `vcvttps2dq`
 * truncate — never nearest-even).
 *
 * Deliberately NO FMA (`vfmadd*ps`) even though the AVX2 dispatch gate
 * implies FMA system-wide: the reference evaluates separate mul+add, and
 * fused contraction would break byte parity. Plain `vmulps`/`vaddps` only.
 * Likewise no `vpgatherdd` for the linear LUT (slow): the same 16-chunk
 * `vpshufb` scan as SSSE3, lane-identical (16B chunks broadcast to both
 * lanes via `vbroadcastf128`, compare vectors likewise).
 *
 * 8px blocks, exact 32B loads/stores; odd widths go scalar. `vzeroupper`
 * before `ret`. Only entered when detectSimdLevel() >= SIMD_AVX2 (YMM
 * state), like the other AVX2 kernels.
 *
 * Register map: same roles as the SSSE3 file, ymm (upper lanes mirror the
 * low-lane computation lane-wise):
 *   ymm0  raw / packed / scan index
 *   ymm1  B floats (narrowed B in scratch ymm9)
 *   ymm2  G floats (narrowed G in scratch ymm8)
 *   ymm3  R floats (narrowed R in scratch ymm7)
 *   ymm4  A floats (narrowed A in place — last row)
 *   ymm5  row accumulator / scan chunk
 *   ymm6  broadcast coeff / scan select
 *   ymm7  narrowed R scratch / pack scratch / scalar-tail zero
 *   ymm8  narrowed G scratch / scan lo nibbles
 *   ymm9  narrowed B scratch / scan hi nibbles
 *   ymm10 saved alpha (linear decode)
 *   ymm14 255.0 broadcast, ymm15 zero (persistent)
 * R/G/B narrow into scratch (same lesson as SSSE3/ARMv7-B5: the later rows
 * still read those float quads); only A narrows in place.
 */

#include "asm_macros.S"

/*
 * One 8-lane matrix row: acc = m0*R + m1*G + m2*B + m3*A + m4.
 * R=ymm3 G=ymm2 B=ymm1 A=ymm4, acc=ymm5. Coeffs via vbroadcastss
 * (AVX2 broadcast, NOT FMA). Left-to-right, no fusion. Clobbers ymm5.
 */
.macro MATROW8 m0, m1, m2, m3, m4
    vbroadcastss \m0(%r10), %ymm5
    vmulps %ymm3, %ymm5, %ymm5
    vbroadcastss \m1(%r10), %ymm6
    vmulps %ymm2, %ymm6, %ymm6
    vaddps %ymm6, %ymm5, %ymm5
    vbroadcastss \m2(%r10), %ymm6
    vmulps %ymm1, %ymm6, %ymm6
    vaddps %ymm6, %ymm5, %ymm5
    vbroadcastss \m3(%r10), %ymm6
    vmulps %ymm4, %ymm6, %ymm6
    vaddps %ymm6, %ymm5, %ymm5
    vbroadcastss \m4(%r10), %ymm6
    vaddps %ymm6, %ymm5, %ymm5
.endm

/*
 * Widen one channel's packed bytes (low qword of CH) to floats/255.
 * Clobbers only CH (ymm14 = 255.0 broadcast, ymm15 = zero, persistent).
 */
.macro WIDEN8 CH
    vpunpcklbw %ymm15, \CH, \CH
    vpunpcklwd %ymm15, \CH, \CH
    vcvtdq2ps \CH, \CH
    vdivps %ymm14, \CH, \CH
.endm

/*
 * Scale row acc (ymm5) by 255, clamp, round half-up, narrow to the low
 * qword of DST. Matches clamp255(). Clobbers ymm5.
 */
.macro NARROW8 DST
    vmulps %ymm14, %ymm5, %ymm5
    vmaxps %ymm15, %ymm5, %ymm5
    vminps %ymm14, %ymm5, %ymm5
    vaddps .LhalfVec(%rip), %ymm5, %ymm5
    vcvttps2dq %ymm5, %ymm5
    vpackssdw %ymm15, %ymm5, %ymm5
    vpackuswb %ymm15, %ymm5, %ymm5
    vmovdqa %ymm5, \DST
.endm

/*
 * One scalar tail channel row (SSE lane-0 semantics via VEX scalar ops, so
 * no AVX<->SSE transition inside the tail). Inputs B=xmm1 G=xmm2 R=xmm3
 * A=xmm4 (lane 0). Result ORed into %r11d at bit SHIFT. xmm7 must be zero.
 * ENC=1: encode R/G/B through the table at (%r15). SHIFT is a bare number.
 */
.macro TAILROW o0, o1, o2, o3, o4, shift, enc
    vbroadcastss \o0(%r10), %xmm5
    vmulss %xmm3, %xmm5, %xmm5
    vbroadcastss \o1(%r10), %xmm6
    vmulss %xmm2, %xmm6, %xmm6
    vaddss %xmm6, %xmm5, %xmm5
    vbroadcastss \o2(%r10), %xmm6
    vmulss %xmm1, %xmm6, %xmm6
    vaddss %xmm6, %xmm5, %xmm5
    vbroadcastss \o3(%r10), %xmm6
    vmulss %xmm4, %xmm6, %xmm6
    vaddss %xmm6, %xmm5, %xmm5
    vbroadcastss \o4(%r10), %xmm6
    vaddss %xmm6, %xmm5, %xmm5
    vmulss .L255(%rip), %xmm5, %xmm5
    vmaxss %xmm7, %xmm5, %xmm5
    vminss .L255(%rip), %xmm5, %xmm5
    vaddss .Lhalf(%rip), %xmm5, %xmm5
    vcvttss2si %xmm5, %eax
    .if \enc
    movzbl (%r15, %rax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $\shift, %eax
    orl %eax, %r11d
.endm

.macro TAILROWS
    xorl %r11d, %r11d
    TAILROW 0, 4, 8, 12, 16, 16, 0
    TAILROW 20, 24, 28, 32, 36, 8, 0
    TAILROW 40, 44, 48, 52, 56, 0, 0
    TAILROW 60, 64, 68, 72, 76, 24, 0
    movl %r11d, (%r13)
.endm

.macro TAILROWSENC
    xorl %r11d, %r11d
    TAILROW 0, 4, 8, 12, 16, 16, 1
    TAILROW 20, 24, 28, 32, 36, 8, 1
    TAILROW 40, 44, 48, 52, 56, 0, 1
    TAILROW 60, 64, 68, 72, 76, 24, 0
    movl %r11d, (%r13)
.endm

.text
.p2align 5
/*
 * void applyColorMatrixAvx2(
 *     const jint* src, jint* dst,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     const jfloat* matrix, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * x86-64 System V ABI: same layout as the SSSE3 entry.
 */
.globl SYM(applyColorMatrixAvx2)
TYPE(SYM(applyColorMatrixAvx2), @function)
SYM(applyColorMatrixAvx2):
    pushq %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $64, %rsp
    /* Stack args: clipBottom @120, matrix @128, useLinear @136,
       srgbToLinear @144, linearToSrgb @152. Scratch 0..63. */

    movq %rdi, %r12
    movq %rsi, %r13
    movl %edx, %r14d
    movl %ecx, %ebp
    movl %r9d, %ebx
    movl %r8d, %r11d

    movl 120(%rsp), %eax
    subl %r11d, %eax
    jle .Ldone
    movl %eax, 0(%rsp)

    movq 128(%rsp), %r10

    vbroadcastss .L255(%rip), %ymm14
    vpxor %ymm15, %ymm15, %ymm15

    movl %r11d, %eax
    imull %r14d, %eax
    addl %ebp, %eax
    movslq %eax, %rax
    leaq (%r12, %rax, 4), %r12
    leaq (%r13, %rax, 4), %r13
    leal (%r14, %r14), %eax
    leal (%rax, %rax), %r14d

    movl 136(%rsp), %eax
    testb %al, %al
    jnz .Llinear_rows

/* ------------------------------------------------------------------ */
/* Non-linear rows (8px).                                              */
/* ------------------------------------------------------------------ */
.Lnonlin_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx
    movl %ecx, %r9d
    shrl $3, %r9d
    andl $7, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    vmovdqu (%r12), %ymm0
    vbroadcastf128 .LshuffleB(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vbroadcastf128 .LshuffleG(%rip), %ymm2
    vpshufb %ymm2, %ymm0, %ymm2
    WIDEN8 %ymm2
    vbroadcastf128 .LshuffleR(%rip), %ymm3
    vpshufb %ymm3, %ymm0, %ymm3
    WIDEN8 %ymm3
    vbroadcastf128 .LshuffleA(%rip), %ymm6
    vpshufb %ymm6, %ymm0, %ymm0
    WIDEN8 %ymm0
    vmovdqa %ymm0, %ymm4

    MATROW8 0, 4, 8, 12, 16
    NARROW8 %ymm7
    MATROW8 20, 24, 28, 32, 36
    NARROW8 %ymm8
    MATROW8 40, 44, 48, 52, 56
    NARROW8 %ymm9
    MATROW8 60, 64, 68, 72, 76
    NARROW8 %ymm4

    vmovdqa %ymm9, %ymm0
    vpunpcklbw %ymm8, %ymm0, %ymm0
    vmovdqa %ymm7, %ymm1
    vpunpcklbw %ymm4, %ymm1, %ymm1
    vpunpcklwd %ymm1, %ymm0, %ymm0
    vmovdqu %ymm0, (%r13)

    addq $32, %r12
    addq $32, %r13
    subl $1, %r9d
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Lnonlin_next
    vpxor %xmm7, %xmm7, %xmm7

.Lnonlin_tail_loop:
    movl (%r12), %eax
    movl %eax, %edx
    andl $0xff, %edx
    vcvtsi2ss %edx, %xmm7, %xmm1
    vdivss .L255(%rip), %xmm1, %xmm1
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    vcvtsi2ss %edx, %xmm7, %xmm2
    vdivss .L255(%rip), %xmm2, %xmm2
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    vcvtsi2ss %edx, %xmm7, %xmm3
    vdivss .L255(%rip), %xmm3, %xmm3
    shrl $24, %eax
    vcvtsi2ss %eax, %xmm7, %xmm4
    vdivss .L255(%rip), %xmm4, %xmm4

    TAILROWS

    addq $4, %r12
    addq $4, %r13
    decl %ecx
    jnz .Lnonlin_tail_loop

.Lnonlin_next:
    movl %ebx, %eax
    subl %ebp, %eax
    salq $2, %rax
    addq %r14, %r12
    subq %rax, %r12
    addq %r14, %r13
    subq %rax, %r13
    decl 0(%rsp)
    jnz .Lnonlin_rows
    jmp .Ldone

/* ------------------------------------------------------------------ */
/* Linear rows: LUT decode/encode around the same 8-wide core.         */
/* ------------------------------------------------------------------ */
.Llinear_rows:
    movl %ebx, %ecx
    subl %ebp, %ecx
    movl %ecx, %r9d
    shrl $3, %r9d
    andl $7, %ecx
    movl %ecx, 8(%rsp)

    testl %r9d, %r9d
    jz .Llinear_tail

.p2align 4
.Llinear_block:
    vmovdqu (%r12), %ymm0
    vmovdqa %ymm0, %ymm10
    vbroadcastf128 .LalphaMask(%rip), %ymm11
    vpand %ymm11, %ymm10, %ymm10
    vbroadcastf128 .LnibbleMask(%rip), %ymm11
    vmovdqa %ymm0, %ymm8
    vpand %ymm11, %ymm8, %ymm8
    vmovdqa %ymm0, %ymm9
    vpsrlw $4, %ymm9, %ymm9
    vpand %ymm11, %ymm9, %ymm9
    movq 144(%rsp), %r15
    vpxor %ymm1, %ymm1, %ymm1
    xorl %r11d, %r11d
    leaq .LhiTab(%rip), %rax
.Ldec_loop:
    vbroadcastf128 (%r15, %r11, 1), %ymm5
    vpshufb %ymm8, %ymm5, %ymm5
    vbroadcastf128 (%rax, %r11, 1), %ymm6
    vpcmpeqb %ymm9, %ymm6, %ymm6
    vpand %ymm6, %ymm5, %ymm5
    vpor %ymm5, %ymm1, %ymm1
    addq $16, %r11
    cmpq $256, %r11
    jne .Ldec_loop
    vmovdqa %ymm1, %ymm0
    vbroadcastf128 .LrgbMask(%rip), %ymm11
    vpand %ymm11, %ymm0, %ymm0
    vpor %ymm10, %ymm0, %ymm0

    vbroadcastf128 .LshuffleB(%rip), %ymm1
    vpshufb %ymm1, %ymm0, %ymm1
    WIDEN8 %ymm1
    vbroadcastf128 .LshuffleG(%rip), %ymm2
    vpshufb %ymm2, %ymm0, %ymm2
    WIDEN8 %ymm2
    vbroadcastf128 .LshuffleR(%rip), %ymm3
    vpshufb %ymm3, %ymm0, %ymm3
    WIDEN8 %ymm3
    vbroadcastf128 .LshuffleA(%rip), %ymm6
    vpshufb %ymm6, %ymm0, %ymm0
    WIDEN8 %ymm0
    vmovdqa %ymm0, %ymm4

    MATROW8 0, 4, 8, 12, 16
    NARROW8 %ymm7
    MATROW8 20, 24, 28, 32, 36
    NARROW8 %ymm8
    MATROW8 40, 44, 48, 52, 56
    NARROW8 %ymm9
    MATROW8 60, 64, 68, 72, 76
    NARROW8 %ymm4

    vmovdqa %ymm9, %ymm0
    vpunpcklbw %ymm8, %ymm0, %ymm0
    vmovdqa %ymm7, %ymm1
    vpunpcklbw %ymm4, %ymm1, %ymm1
    vpunpcklwd %ymm1, %ymm0, %ymm0
    vmovdqa %ymm4, %ymm7
    vbroadcastf128 .LspreadA(%rip), %ymm11
    vpshufb %ymm11, %ymm7, %ymm7
    vmovdqa %ymm0, %ymm8
    vbroadcastf128 .LnibbleMask(%rip), %ymm11
    vpand %ymm11, %ymm8, %ymm8
    vmovdqa %ymm0, %ymm9
    vpsrlw $4, %ymm9, %ymm9
    vpand %ymm11, %ymm9, %ymm9
    movq 152(%rsp), %r15
    vpxor %ymm2, %ymm2, %ymm2
    xorl %r11d, %r11d
.Lenc_loop:
    vbroadcastf128 (%r15, %r11, 1), %ymm5
    vpshufb %ymm8, %ymm5, %ymm5
    vbroadcastf128 (%rax, %r11, 1), %ymm6
    vpcmpeqb %ymm9, %ymm6, %ymm6
    vpand %ymm6, %ymm5, %ymm5
    vpor %ymm5, %ymm2, %ymm2
    addq $16, %r11
    cmpq $256, %r11
    jne .Lenc_loop
    vmovdqa %ymm2, %ymm0
    vbroadcastf128 .LrgbMask(%rip), %ymm11
    vpand %ymm11, %ymm0, %ymm0
    vpor %ymm7, %ymm0, %ymm0
    vmovdqu %ymm0, (%r13)

    addq $32, %r12
    addq $32, %r13
    subl $1, %r9d
    jnz .Llinear_block

.Llinear_tail:
    movl 8(%rsp), %ecx
    testl %ecx, %ecx
    jz .Llinear_next
    vpxor %xmm7, %xmm7, %xmm7
    movq 152(%rsp), %r15

.Llinear_tail_loop:
    movq 144(%rsp), %rax
    movl (%r12), %edx
    movl %edx, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    vcvtsi2ss %esi, %xmm7, %xmm1
    vdivss .L255(%rip), %xmm1, %xmm1
    movl %edx, %esi
    shrl $8, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    vcvtsi2ss %esi, %xmm7, %xmm2
    vdivss .L255(%rip), %xmm2, %xmm2
    movl %edx, %esi
    shrl $16, %esi
    andl $0xff, %esi
    movzbl (%rax, %rsi), %esi
    vcvtsi2ss %esi, %xmm7, %xmm3
    vdivss .L255(%rip), %xmm3, %xmm3
    shrl $24, %edx
    vcvtsi2ss %edx, %xmm7, %xmm4
    vdivss .L255(%rip), %xmm4, %xmm4

    TAILROWSENC

    addq $4, %r12
    addq $4, %r13
    decl %ecx
    jnz .Llinear_tail_loop

.Llinear_next:
    movl %ebx, %eax
    subl %ebp, %eax
    salq $2, %rax
    addq %r14, %r12
    subq %rax, %r12
    addq %r14, %r13
    subq %rax, %r13
    decl 0(%rsp)
    jnz .Llinear_rows
    jmp .Ldone

.Ldone:
    vzeroupper
    addq $64, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

SIZE(SYM(applyColorMatrixAvx2))

RODATA
.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.Lhalf:
    .long 0x3f000000
.p2align 5
.LhalfVec:
    .long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
    .long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
.p2align 4
.LnibbleMask:
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.p2align 4
.LalphaMask:
    .long 0xff000000, 0xff000000, 0xff000000, 0xff000000
.p2align 4
.LrgbMask:
    .long 0x00ffffff, 0x00ffffff, 0x00ffffff, 0x00ffffff
.p2align 4
.LshuffleB:
    .byte 0,4,8,12,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleG:
    .byte 1,5,9,13,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleR:
    .byte 2,6,10,14,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleA:
    .byte 3,7,11,15,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LspreadA:
    .byte 0x80,0x80,0x80,0,0x80,0x80,0x80,1,0x80,0x80,0x80,2,0x80,0x80,0x80,3
.p2align 4
/* High-nibble compare vectors: .LhiTab[i] = 16 copies of byte i. */
.LhiTab:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
    .byte 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    .byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
    .byte 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
    .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
    .byte 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    .byte 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9
    .byte 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
    .byte 11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
    .byte 12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12
    .byte 13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13
    .byte 14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
GNU_STACK
