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

/*
 */

#include "asm_macros.S"

.text
.p2align 5
/*
 * x86-64 AVX2 implementation of UnLinearize.
 *
 * Processes 8 ARGB8888 pixels (32 bytes) per iteration.
 *
 * The 256-entry LUT is 16 rows x 16 bytes. VPSHUFB is lane-local and uses
 * the low nibble as an index, so we select the row with a high-nibble compare.
 * Eight rows fit in YMM4..YMM11; rows 0..15 are loaded from the LUT for each
 * 32-byte block. This deliberately favors correctness and a simple register
 * map over trying to keep all 16 rows live.
 *
 * Alpha is restored unchanged after the RGB lookup.
 *
 * void ksvgUnlinearizeApplyAvx2(
 *     const jint* src, jint* dst, jint width, jint height, const jbyte* table);
 *
 * x86-64 System V ABI:
 *   rdi = src, rsi = dst, edx = width, ecx = height, r8 = table
 */
.globl SYM(ksvgUnlinearizeApplyAvx2)
TYPE(SYM(ksvgUnlinearizeApplyAvx2), @function)
SYM(ksvgUnlinearizeApplyAvx2):
    movl    %edx, %eax
    imull   %ecx, %eax
    movl    %eax, %r9d
    shrl    $3, %r9d                 /* blocks = total / 8 */
    andl    $7, %eax
    movl    %eax, %r10d              /* tail = total % 8 */

    /* ymm15 = 0x0f per byte. */
    vpbroadcastb .L_nibble_mask(%rip), %ymm15

    testl   %r9d, %r9d
    jz      .L_tail

.p2align 5
.L_loop:
    /* Load LUT rows 0..7. */
    vbroadcasti128   0(%r8),   %ymm4
    vbroadcasti128  16(%r8),   %ymm5
    vbroadcasti128  32(%r8),   %ymm6
    vbroadcasti128  48(%r8),   %ymm7
    vbroadcasti128  64(%r8),   %ymm8
    vbroadcasti128  80(%r8),   %ymm9
    vbroadcasti128  96(%r8),   %ymm10
    vbroadcasti128 112(%r8),   %ymm11

    /* Load 8..15 into the same registers after rows 0..7 are consumed. */
    vmovdqu 0(%rdi), %ymm0
    vpand   %ymm15, %ymm0, %ymm1
    vmovdqa %ymm0, %ymm2
    vpsrlw  $4, %ymm2, %ymm2
    vpand   %ymm15, %ymm2, %ymm2

    vpxor   %ymm3, %ymm3, %ymm3
    vpxor   %ymm14, %ymm14, %ymm14  /* high-nibble row id = 0 */

    /* Rows 0..7: table is first source, indices are second source. */
    vpshufb %ymm1, %ymm4, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm5, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm6, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm7, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm8, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm9, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm10, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm11, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3

    /* Reload rows 8..15. */
    vbroadcasti128 128(%r8), %ymm4
    vbroadcasti128 144(%r8), %ymm5
    vbroadcasti128 160(%r8), %ymm6
    vbroadcasti128 176(%r8), %ymm7
    vbroadcasti128 192(%r8), %ymm8
    vbroadcasti128 208(%r8), %ymm9
    vbroadcasti128 224(%r8), %ymm10
    vbroadcasti128 240(%r8), %ymm11

    /* Rows 8..15. */
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14  /* row id = 8 */

    vpshufb %ymm1, %ymm4, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm5, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm6, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm7, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm8, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm9, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm10, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vpaddb  .L_one_vec(%rip), %ymm14, %ymm14

    vpshufb %ymm1, %ymm11, %ymm12
    vpcmpeqb %ymm14, %ymm2, %ymm13
    vpand   %ymm13, %ymm12, %ymm12
    vpor    %ymm12, %ymm3, %ymm3

    /* Restore original alpha bytes, transform RGB only. */
    vpand   .L_rgb_mask(%rip), %ymm3, %ymm3
    vpand   .L_alpha_mask(%rip), %ymm0, %ymm12
    vpor    %ymm12, %ymm3, %ymm3
    vmovdqu %ymm3, (%rsi)

    addq    $32, %rdi
    addq    $32, %rsi
    decl    %r9d
    jnz     .L_loop

.L_tail:
    testl   %r10d, %r10d
    jz      .L_done

    /* Scalar remainder, same mapping as unlinearize.cpp. */
.L_tail_loop:
    movl    (%rdi), %eax
    movl    %eax, %edx
    andl    $0xff000000, %edx          /* alpha */

    movl    %eax, %ecx
    andl    $0xff, %ecx
    movzbl  (%r8, %rcx), %ecx            /* B */
    movl    %ecx, %r11d

    shrl    $8, %eax
    andl    $0xff, %eax
    movzbl  (%r8, %rax), %eax             /* G */
    shll    $8, %eax
    orl     %eax, %r11d

    movl    (%rdi), %eax
    shrl    $16, %eax
    andl    $0xff, %eax
    movzbl  (%r8, %rax), %eax             /* R */
    shll    $16, %eax
    orl     %eax, %r11d

    orl     %edx, %r11d
    movl    %r11d, (%rsi)
    addq    $4, %rdi
    addq    $4, %rsi
    decl    %r10d
    jnz     .L_tail_loop

.L_done:
    vzeroupper
    ret
// SIZE(SYM(ksvgUnlinearizeApplyAvx2))

RODATA
.p2align 5
.L_nibble_mask:
    .byte 15
.L_one_vec:
    .rept 32
    .byte 1
    .endr
.L_eight_vec:
    .rept 32
    .byte 8
    .endr
.p2align 5
.L_rgb_mask:
    .rept 8
    .long 0x00ffffff
    .endr
.L_alpha_mask:
    .rept 8
    .long 0xff000000
    .endr
GNU_STACK
