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

#include "asm_macros.S"
#include "lighting_i386_pow_macros.S"

/*
 * Description:
 *   Extracts one pixel's alpha byte (accumulator form): loads the pixel
 *   into %eax itself, shifts the alpha byte down, stores the 0..255 integer.
 *   Callers load the row base into %eax per row group. Single-file use.
 *
 * Inputs:
 *   \src_off  = byte offset of the pixel from the row pointer in %eax
 *   \dst_off  = stack offset of the integer slot in (%ebp)
 *
 * Output:
 *   0..255 integer at \dst_off(%ebp); %eax = shifted alpha (clobbered)
 *
 * Clobbers:
 *   %eax (in-place)
 */
.macro ALPHA_EXTRACT_ACC src_off, dst_off
    movl     \src_off(%eax), %eax
    shrl     $24, %eax
    movl     %eax, \dst_off(%ebp)
.endm
.text
EMIT_POW1_I386_TABLES
RODATA
.p2align 4
.Lsp_zero: .long 0
.Lsp_one: .long 0x3f800000
.Lsp_half: .long 0x3f000000
.Lsp_255: .long 0x437f0000
.text
.macro L2S reg
    movl     -24(%ebp), %ecx
    movzbl   (%ecx,\reg), %ecx
    movl     %ecx, \reg
.endm
.macro CLAMP reg
    cmpl     $0, \reg
    jge      1f
    xorl     \reg, \reg
    jmp      2f
1:
    cmpl     $255, \reg
    jle      2f
    movl     $255, \reg
2:
.endm

/*
 * Description:
 *   Converts one stacked integer alpha to a scaled float: loads the int,
 *   converts int32->float (exact), scales by surfaceScale reloaded from
 *   params each time, stores back. Single-file use.
 *
 * Inputs:
 *   \stack_off = stack offset of the int slot in (%ebp) (in/out)
 *
 * Output:
 *   float at \stack_off(%ebp)
 *
 * Clobbers:
 *   %xmm0, %eax
 */
.macro TO_FLOAT stack_off
    movd     \stack_off(%ebp), %xmm0
    cvtdq2ps %xmm0, %xmm0
    movl     -16(%ebp), %eax
    mulss    36(%eax), %xmm0
    movss    %xmm0, \stack_off(%ebp)
.endm

/*
 * Description:
 *   Scales one color channel by the spilled intensity, rounds half-up, and
 *   truncates to int. The intensity spill (-164(%ebp)) and the 0.5 literal
 *   (.Lsp_half) are fixed (single-file use). Intensity in %xmm0 contract.
 *
 * Inputs:
 *   \mem_off  = byte offset of the channel factor from the params base
 *   \base     = params base register
 *   \dst      = 32-bit GPR receiving the truncated channel
 *
 * Output:
 *   \dst = (int)(\base[\mem_off] * intensity + 0.5)
 *
 * Clobbers:
 *   %xmm0
 *   \dst (written)
 */
.macro SP_CHAN mem_off, base, dst
    movss    \mem_off(\base), %xmm0
    mulss    -164(%ebp), %xmm0
    addss    .Lsp_half@GOTOFF(%ebx), %xmm0
    cvttss2si %xmm0, \dst
.endm

/*
 * Description:
 *   Clamps one stacked channel integer to [0, 255] via the file-local CLAMP
 *   macro, with optional exact L2S conversion (linear path, via the
 *   file-local L2S macro reading the global LUT base). Single-file use.
 *
 * Inputs:
 *   \slot  = stack offset of the channel integer slot in (%ebp) (in/out)
 *   \l2s   = 1 to run L2S after clamping, 0 for clamp only
 *
 * Clobbers:
 *   %eax
 */
.macro CLAMP_SLOT slot, l2s
    movl     \slot(%ebp), %eax
    CLAMP %eax
    movl     %eax, \slot(%ebp)
.if \l2s
    L2S %eax
    movl     %eax, \slot(%ebp)
.endif
.endm

.globl SYM(ksvgLightingSpotSpecularRowAvx2)
TYPE(SYM(ksvgLightingSpotSpecularRowAvx2), @function)
SYM(ksvgLightingSpotSpecularRowAvx2):
    xorl     %eax, %eax
    jmp      .Lsp_entry_Avx2
.globl SYM(ksvgLightingSpotSpecularRowAvx2Linear)
TYPE(SYM(ksvgLightingSpotSpecularRowAvx2Linear), @function)
SYM(ksvgLightingSpotSpecularRowAvx2Linear):
    movl     $1, %eax
.Lsp_entry_Avx2:
    pushl    %ebp
    movl     %esp, %ebp
    pushl    %ebx
    pushl    %esi
    pushl    %edi
    subl     $176, %esp
    LOAD_GOT(sp_avx)
    movl     %eax, -4(%ebp)
    movl     ksvg_linear_to_srgb_lut@GOT(%ebx), %eax
    movl     %eax, -24(%ebp)
    movl     8(%ebp), %eax
    movl     %eax, -32(%ebp)
    movl     12(%ebp), %eax
    movl     %eax, -36(%ebp)
    movl     16(%ebp), %eax
    movl     %eax, -40(%ebp)
    movl     20(%ebp), %eax
    movl     %eax, -8(%ebp)
    movl     24(%ebp), %eax
    movl     %eax, -12(%ebp)
    movl     28(%ebp), %eax
    movl     %eax, -16(%ebp)
    movl     32(%ebp), %eax
    movl     %eax, -20(%ebp)
.Lsp_loop_Avx2:
    cmpl     $0, -12(%ebp)
    jle      .Lsp_done_Avx2
    movl     -32(%ebp), %eax
    ALPHA_EXTRACT_ACC 0, -84
    movl     -32(%ebp), %eax
    ALPHA_EXTRACT_ACC 4, -88
    movl     -32(%ebp), %eax
    ALPHA_EXTRACT_ACC 8, -92
    movl     -36(%ebp), %eax
    ALPHA_EXTRACT_ACC 0, -96
    movl     -36(%ebp), %eax
    ALPHA_EXTRACT_ACC 8, -100
    movl     -40(%ebp), %eax
    ALPHA_EXTRACT_ACC 0, -104
    movl     -40(%ebp), %eax
    ALPHA_EXTRACT_ACC 4, -108
    movl     -40(%ebp), %eax
    ALPHA_EXTRACT_ACC 8, -112
    TO_FLOAT -84
    TO_FLOAT -88
    TO_FLOAT -92
    TO_FLOAT -96
    TO_FLOAT -100
    TO_FLOAT -104
    TO_FLOAT -108
    TO_FLOAT -112
    movss    -92(%ebp), %xmm0
    addss    -100(%ebp), %xmm0
    addss    -100(%ebp), %xmm0
    addss    -112(%ebp), %xmm0
    movss    -84(%ebp), %xmm1
    addss    -96(%ebp), %xmm1
    addss    -96(%ebp), %xmm1
    addss    -104(%ebp), %xmm1
    subss    %xmm1, %xmm0
    movl     -16(%ebp), %eax
    divss    0(%eax), %xmm0
    movss    %xmm0, -116(%ebp)
    movss    -104(%ebp), %xmm0
    addss    -108(%ebp), %xmm0
    addss    -108(%ebp), %xmm0
    addss    -112(%ebp), %xmm0
    movss    -84(%ebp), %xmm1
    addss    -88(%ebp), %xmm1
    addss    -88(%ebp), %xmm1
    addss    -92(%ebp), %xmm1
    subss    %xmm1, %xmm0
    movl     -16(%ebp), %eax
    divss    4(%eax), %xmm0
    movss    %xmm0, -120(%ebp)
    movss    -116(%ebp), %xmm0
    xorps    %xmm1, %xmm1
    subss    %xmm0, %xmm1
    movss    -120(%ebp), %xmm0
    xorps    %xmm2, %xmm2
    subss    %xmm0, %xmm2
    movaps   %xmm1, %xmm3
    mulss    %xmm1, %xmm3
    movaps   %xmm2, %xmm0
    mulss    %xmm2, %xmm0
    addss    %xmm0, %xmm3
    addss    .Lsp_one@GOTOFF(%ebx), %xmm3
    sqrtss   %xmm3, %xmm3
    movss    .Lsp_one@GOTOFF(%ebx), %xmm0
    divss    %xmm3, %xmm0
    mulss    %xmm0, %xmm1
    mulss    %xmm0, %xmm2
    movss    %xmm1, -124(%ebp)
    movss    %xmm2, -128(%ebp)
    movss    %xmm0, -132(%ebp)
    movl     -16(%ebp), %eax
    movl     -36(%ebp), %ecx
    movl     4(%ecx), %ecx
    shrl     $24, %ecx
    movd     %ecx, %xmm0
    cvtdq2ps %xmm0, %xmm0
    mulss    36(%eax), %xmm0
    movss    %xmm0, -136(%ebp)
    movl     -16(%ebp), %eax
    movss    40(%eax), %xmm0
    movss    %xmm0, -140(%ebp)
    movl     -16(%ebp), %eax
    movss    12(%eax), %xmm0
    subss    -140(%ebp), %xmm0
    movss    %xmm0, -144(%ebp)
    movss    16(%eax), %xmm0
    subss    44(%eax), %xmm0
    movss    %xmm0, -148(%ebp)
    movss    20(%eax), %xmm0
    subss    -136(%ebp), %xmm0
    movss    %xmm0, -152(%ebp)
    movss    -144(%ebp), %xmm0
    mulss    %xmm0, %xmm0
    movss    -148(%ebp), %xmm1
    mulss    %xmm1, %xmm1
    addss    %xmm1, %xmm0
    movss    -152(%ebp), %xmm1
    mulss    %xmm1, %xmm1
    addss    %xmm1, %xmm0
    sqrtss   %xmm0, %xmm0
    movss    .Lsp_zero@GOTOFF(%ebx), %xmm1
    ucomiss  %xmm1, %xmm0
    je       .Lsp_zeroL_0
    movss    .Lsp_one@GOTOFF(%ebx), %xmm1
    divss    %xmm0, %xmm1
    movss    -144(%ebp), %xmm0
    mulss    %xmm1, %xmm0
    movss    %xmm0, -144(%ebp)
    movss    -148(%ebp), %xmm0
    mulss    %xmm1, %xmm0
    movss    %xmm0, -148(%ebp)
    movss    -152(%ebp), %xmm0
    mulss    %xmm1, %xmm0
    movss    %xmm0, -152(%ebp)
    jmp      .Lsp_afterL_0
.Lsp_zeroL_0:
    movl     $0, -144(%ebp)
    movl     $0, -148(%ebp)
    movl     $0, -152(%ebp)
.Lsp_afterL_0:
    movss    -144(%ebp), %xmm0
    xorps    %xmm1, %xmm1
    subss    %xmm0, %xmm1
    movl     -16(%ebp), %eax
    mulss    52(%eax), %xmm1
    movss    -148(%ebp), %xmm0
    xorps    %xmm2, %xmm2
    subss    %xmm0, %xmm2
    mulss    56(%eax), %xmm2
    addss    %xmm2, %xmm1
    movss    -152(%ebp), %xmm0
    xorps    %xmm2, %xmm2
    subss    %xmm0, %xmm2
    mulss    60(%eax), %xmm2
    addss    %xmm2, %xmm1
    xorps    %xmm0, %xmm0
    maxss    %xmm0, %xmm1
    movss    %xmm1, -156(%ebp)
    movss    64(%eax), %xmm2
    ucomiss  %xmm2, %xmm2
    jp       .Lsp_noCut_0
    ucomiss  %xmm2, %xmm1
    jb       .Lsp_cut0_0
.Lsp_noCut_0:
    jmp      .Lsp_cutDone_0
.Lsp_cut0_0:
    movl     $0, -156(%ebp)
.Lsp_cutDone_0:
    movss    -144(%ebp), %xmm0
    movss    -148(%ebp), %xmm1
    movss    -152(%ebp), %xmm2
    addss    .Lsp_one@GOTOFF(%ebx), %xmm2
    movaps   %xmm0, %xmm3
    mulss    %xmm0, %xmm3
    movaps   %xmm1, %xmm4
    mulss    %xmm1, %xmm4
    addss    %xmm4, %xmm3
    movaps   %xmm2, %xmm4
    mulss    %xmm2, %xmm4
    addss    %xmm4, %xmm3
    sqrtss   %xmm3, %xmm3
    movss    .Lsp_one@GOTOFF(%ebx), %xmm4
    divss    %xmm3, %xmm4
    mulss    %xmm4, %xmm0
    mulss    %xmm4, %xmm1
    mulss    %xmm4, %xmm2
    movss    -124(%ebp), %xmm3
    mulss    %xmm0, %xmm3
    movss    -128(%ebp), %xmm4
    mulss    %xmm1, %xmm4
    addss    %xmm4, %xmm3
    movss    -132(%ebp), %xmm4
    mulss    %xmm2, %xmm4
    addss    %xmm4, %xmm3
    xorps    %xmm4, %xmm4
    maxss    %xmm4, %xmm3
    movss    %xmm3, -160(%ebp)
    # p = powf(ndoth, exponent): inline scalar minimax, no PLT call.
    movss    -160(%ebp), %xmm1  # pow base
    movss    -20(%ebp), %xmm2  # exponent
    POW1_SSE
    movss    %xmm0, -160(%ebp)
    movss    -160(%ebp), %xmm0
    movl     -16(%ebp), %eax
    mulss    8(%eax), %xmm0
    mulss    -156(%ebp), %xmm0
    xorps    %xmm1, %xmm1
    maxss    %xmm1, %xmm0
    movss    .Lsp_one@GOTOFF(%ebx), %xmm1
    minss    %xmm1, %xmm0
    movss    %xmm0, -164(%ebp)
    movl     -16(%ebp), %eax
    SP_CHAN 24, %eax, %eax
    movl     %eax, %ecx
    movl     -16(%ebp), %edx
    SP_CHAN 28, %edx, %edx
    movl     -16(%ebp), %eax
    SP_CHAN 32, %eax, %esi
    # Store channel integers before optional L2S.
    movl     %ecx, -168(%ebp)
    movl     %edx, -172(%ebp)
    movl     %esi, -176(%ebp)
    cmpl     $0, -4(%ebp)
    je       .Lsp_nolinear_0
    CLAMP_SLOT -168, 1
    CLAMP_SLOT -172, 1
    CLAMP_SLOT -176, 1
    jmp      .Lsp_out_0
.Lsp_nolinear_0:
    CLAMP_SLOT -168, 0
    CLAMP_SLOT -172, 0
    CLAMP_SLOT -176, 0
.Lsp_out_0:
    movl     -168(%ebp), %eax
    movl     -172(%ebp), %ecx
    movl     -176(%ebp), %edx
    movl     %eax, %esi
    cmpl     %ecx, %esi
    cmovl    %ecx, %esi
    cmpl     %edx, %esi
    cmovl    %edx, %esi
    shll     $16, %eax
    shll     $8, %ecx
    shll     $24, %esi
    orl      %ecx, %eax
    orl      %edx, %eax
    orl      %esi, %eax
    movl     -8(%ebp), %ecx
    movl     %eax, 0(%ecx)

    addl     $4, -32(%ebp)
    addl     $4, -36(%ebp)
    addl     $4, -40(%ebp)
    addl     $4, -8(%ebp)
    movl     -16(%ebp), %eax
    movss    40(%eax), %xmm0
    addss    48(%eax), %xmm0
    movss    %xmm0, 40(%eax)
    decl     -12(%ebp)
    jmp      .Lsp_loop_Avx2
.Lsp_done_Avx2:
    addl     $176, %esp
    popl     %edi
    popl     %esi
    popl     %ebx
    popl     %ebp
    ret
SIZE(SYM(ksvgLightingSpotSpecularRowAvx2))
SIZE(SYM(ksvgLightingSpotSpecularRowAvx2Linear))
GNU_STACK
