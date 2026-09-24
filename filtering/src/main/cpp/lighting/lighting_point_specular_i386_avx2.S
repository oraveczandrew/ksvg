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
 * Point-light specular AVX2 kernel for i386.
 */

#include "asm_macros.S"
#include "lighting_i386_pow_macros.S"

.text
EMIT_POW1_I386_TABLES

.text

/*
 * Description:
 *   Extracts one pixel's alpha byte and stores it as an integer: loads the
 *   pixel, shifts the alpha byte down (shrl $24), and stores the 0..255
 *   integer to a stack slot. 32-bit GPR-only (ISA-neutral shape, kept
 *   file-local: single-file use).
 *
 * Inputs:
 *   \src_off  = byte offset of the pixel from the row pointer in %eax
 *   \dst_off  = stack offset of the integer slot in (%ebp)
 *
 * Output:
 *   0..255 integer at \dst_off(%ebp)
 *
 * Clobbers:
 *   %ecx
 */
.macro ALPHA_EXTRACT src_off, dst_off
    movl       \src_off(%eax), %ecx
    shrl       $24, %ecx
    movl       %ecx, \dst_off(%ebp)
.endm

/*
 * Description:
 *   Converts one stacked integer alpha (0..255) to a scaled float (VEX
 *   scalar form): loads the int, converts int32->float (exact), scales by
 *   the surface-scale vector, stores back. Moved up from inside the loop;
 *   unchanged semantics.
 *
 * Inputs:
 *   \stack_off = stack offset of the int slot in (%ebp) (in/out)
 *   %xmm7      = broadcast surface scale ss (loaded by the caller, preserved)
 *
 * Output:
 *   float at \stack_off(%ebp)
 *
 * Clobbers:
 *   %xmm0
 */
.macro PSA_TO_FLOAT stack_off
    vmovd      \stack_off(%ebp), %xmm0
    vcvtdq2ps  %xmm0, %xmm0
    vmulss     %xmm7, %xmm0, %xmm0
    vmovss     %xmm0, \stack_off(%ebp)
.endm

/*
 * Description:
 *   Scales one color channel by the intensity (VEX scalar form), rounds
 *   half-up, and truncates to int. The 0.5 literal (.Lpsa_half) is fixed
 *   (single-file use); intensity is always in %xmm0 and scratch in %xmm1
 *   at all 3 call sites (kernel contract).
 *
 * Inputs:
 *   \mem_off  = byte offset of the channel factor from the params base
 *   \base     = params base register (%eax for R, %edx for G/B)
 *   \dst      = 32-bit GPR receiving the truncated channel
 *
 * Output:
 *   \dst = (int)(\base[\mem_off] * intensity + 0.5)
 *
 * Clobbers:
 *   %xmm1
 *   \dst (written)
 */
.macro PSA_CHAN mem_off, base, dst
    vmovss     \mem_off(\base), %xmm1
    vmulss     %xmm0, %xmm1, %xmm1
    vaddss     .Lpsa_half@GOTOFF(%ebx), %xmm1, %xmm1
    vcvttss2si %xmm1, \dst
.endm

.text
POINT_LIT4
.p2align 2
.Lpsa_zero: .long 0
.Lpsa_one: .long 0x3f800000
.Lpsa_half: .long 0x3f000000

.globl SYM(ksvgLightingPointSpecularRowAvx2)
TYPE(SYM(ksvgLightingPointSpecularRowAvx2), @function)
SYM(ksvgLightingPointSpecularRowAvx2):
    xorl       %eax, %eax
    jmp        .Lpsa_entry_Avx2
.globl SYM(ksvgLightingPointSpecularRowAvx2Linear)
TYPE(SYM(ksvgLightingPointSpecularRowAvx2Linear), @function)
SYM(ksvgLightingPointSpecularRowAvx2Linear):
    movl       $1, %eax
.Lpsa_entry_Avx2:
    pushl      %ebp
    movl       %esp, %ebp
    pushl      %ebx
    pushl      %esi
    pushl      %edi
    subl       $512, %esp
    LOAD_GOT(psa)
    movl       %eax, -4(%ebp)  # useLinear
    movl       8(%ebp), %eax
    movl       %eax, -32(%ebp)  # srcT
    movl       12(%ebp), %eax
    movl       %eax, -36(%ebp)  # srcM
    movl       16(%ebp), %eax
    movl       %eax, -40(%ebp)  # srcB
    movl       20(%ebp), %eax
    movl       %eax, -8(%ebp)  # dst
    movl       24(%ebp), %eax
    movl       %eax, -12(%ebp)  # count
    movl       28(%ebp), %eax
    movl       %eax, -16(%ebp)  # params
    movl       32(%ebp), %eax
    movl       %eax, -20(%ebp)  # exponent
    movl       ksvg_linear_to_srgb_lut@GOT(%ebx), %eax
    movl       %eax, -24(%ebp)

.Lpsa_loop_Avx2:
    # Per-pixel loop (window, normalize, half-vector dot, powf, intensity,
    # pack, store; advances ux0 by dux).
    cmpl       $0, -12(%ebp)
    jle        .Lpsa_done_Avx2

    # Load 3 horizontal samples from 3 rows for ONE output pixel.
    movl       -32(%ebp), %eax
    ALPHA_EXTRACT 0, -84
    ALPHA_EXTRACT 4, -88
    ALPHA_EXTRACT 8, -92
    movl       -36(%ebp), %eax
    ALPHA_EXTRACT 0, -96
    ALPHA_EXTRACT 4, -136
    ALPHA_EXTRACT 8, -100
    movl       -40(%ebp), %eax
    ALPHA_EXTRACT 0, -104
    ALPHA_EXTRACT 4, -108
    ALPHA_EXTRACT 8, -112

    movl       -16(%ebp), %eax
    vmovss     36(%eax), %xmm7  # ss
    PSA_TO_FLOAT -84
    PSA_TO_FLOAT -88
    PSA_TO_FLOAT -92
    PSA_TO_FLOAT -96
    PSA_TO_FLOAT -136
    PSA_TO_FLOAT -100
    PSA_TO_FLOAT -104
    PSA_TO_FLOAT -108
    PSA_TO_FLOAT -112

    # dzdx
    vmovss     -92(%ebp), %xmm0
    vaddss     -100(%ebp), %xmm0, %xmm0
    vaddss     -100(%ebp), %xmm0, %xmm0
    vaddss     -112(%ebp), %xmm0, %xmm0
    vmovss     -84(%ebp), %xmm1
    vaddss     -96(%ebp), %xmm1, %xmm1
    vaddss     -96(%ebp), %xmm1, %xmm1
    vaddss     -104(%ebp), %xmm1, %xmm1
    vsubss     %xmm1, %xmm0, %xmm0
    movl       -16(%ebp), %eax
    vdivss     0(%eax), %xmm0, %xmm0
    vmovss     %xmm0, -116(%ebp)

    # dzdy
    vmovss     -104(%ebp), %xmm0
    vaddss     -108(%ebp), %xmm0, %xmm0
    vaddss     -108(%ebp), %xmm0, %xmm0
    vaddss     -112(%ebp), %xmm0, %xmm0
    vmovss     -84(%ebp), %xmm1
    vaddss     -88(%ebp), %xmm1, %xmm1
    vaddss     -88(%ebp), %xmm1, %xmm1
    vaddss     -92(%ebp), %xmm1, %xmm1
    vsubss     %xmm1, %xmm0, %xmm0
    vdivss     4(%eax), %xmm0, %xmm0
    vmovss     %xmm0, -120(%ebp)

    # Normal N
    vmovss     -116(%ebp), %xmm0
    vxorps     %xmm1, %xmm1, %xmm1
    vsubss     %xmm0, %xmm1, %xmm1  # nx
    vmovss     -120(%ebp), %xmm0
    vxorps     %xmm2, %xmm2, %xmm2
    vsubss     %xmm0, %xmm2, %xmm2  # ny
    vmulss     %xmm1, %xmm1, %xmm3
    vmulss     %xmm2, %xmm2, %xmm0
    vaddss     %xmm0, %xmm3, %xmm3
    vaddss     .Lpsa_one@GOTOFF(%ebx), %xmm3, %xmm3
    vsqrtss    %xmm3, %xmm3, %xmm3
    vmovss     .Lpsa_one@GOTOFF(%ebx), %xmm0
    vdivss     %xmm3, %xmm0, %xmm0
    vmulss     %xmm0, %xmm1, %xmm1
    vmulss     %xmm0, %xmm2, %xmm2
    vmovss     %xmm1, -124(%ebp)
    vmovss     %xmm2, -128(%ebp)
    vmovss     %xmm0, -132(%ebp)  # nz

    # Point light L
    movl       -16(%ebp), %eax
    vmovss     40(%eax), %xmm0
    vmovss     44(%eax), %xmm1
    vmovss     -136(%ebp), %xmm2
    vmovss     12(%eax), %xmm3
    vsubss     %xmm0, %xmm3, %xmm3
    vmovss     16(%eax), %xmm4
    vsubss     %xmm1, %xmm4, %xmm4
    vmovss     20(%eax), %xmm5
    vsubss     %xmm2, %xmm5, %xmm5
    vmulss     %xmm3, %xmm3, %xmm6
    vmulss     %xmm4, %xmm4, %xmm0
    vaddss     %xmm0, %xmm6, %xmm6
    vmulss     %xmm5, %xmm5, %xmm0
    vaddss     %xmm0, %xmm6, %xmm6
    vsqrtss    %xmm6, %xmm6, %xmm6
    vmovss     .Lpsa_zero@GOTOFF(%ebx), %xmm0
    vucomiss   %xmm0, %xmm6
    je         .Lpsa_l_zero
    vmovss     .Lpsa_one@GOTOFF(%ebx), %xmm0
    vdivss     %xmm6, %xmm0, %xmm0
    vmulss     %xmm0, %xmm3, %xmm3
    vmulss     %xmm0, %xmm4, %xmm4
    vmulss     %xmm0, %xmm5, %xmm5
    jmp        .Lpsa_l_done
.Lpsa_l_zero:
    vxorps     %xmm3, %xmm3, %xmm3
    vxorps     %xmm4, %xmm4, %xmm4
    vxorps     %xmm5, %xmm5, %xmm5
.Lpsa_l_done:

    # Half vector H
    vaddss     .Lpsa_one@GOTOFF(%ebx), %xmm5, %xmm5
    vmulss     %xmm3, %xmm3, %xmm6
    vmulss     %xmm4, %xmm4, %xmm0
    vaddss     %xmm0, %xmm6, %xmm6
    vmulss     %xmm5, %xmm5, %xmm0
    vaddss     %xmm0, %xmm6, %xmm6
    vsqrtss    %xmm6, %xmm6, %xmm6
    vmovss     .Lpsa_one@GOTOFF(%ebx), %xmm0
    vdivss     %xmm6, %xmm0, %xmm0
    vmulss     %xmm0, %xmm3, %xmm3
    vmulss     %xmm0, %xmm4, %xmm4
    vmulss     %xmm0, %xmm5, %xmm5

    # ndoth
    vmulss     -124(%ebp), %xmm3, %xmm3
    vmulss     -128(%ebp), %xmm4, %xmm4
    vaddss     %xmm4, %xmm3, %xmm3
    vmulss     -132(%ebp), %xmm5, %xmm5
    vaddss     %xmm5, %xmm3, %xmm3
    vxorps     %xmm0, %xmm0, %xmm0
    vmaxss     %xmm0, %xmm3, %xmm3

    # p = powf(ndoth, exponent): inline scalar minimax, no PLT call.
    vmovaps      %xmm3, %xmm1  # pow base
    vmovss       -20(%ebp), %xmm2  # exponent
    vzeroupper
    POW1_SSE
    vmovss       %xmm0, -160(%ebp)
    vmovss       -160(%ebp), %xmm0

    # intensity
    movl       -16(%ebp), %eax
    vmulss     8(%eax), %xmm0, %xmm0
    vxorps     %xmm1, %xmm1, %xmm1
    vmaxss     %xmm1, %xmm0, %xmm0
    vminss     .Lpsa_one@GOTOFF(%ebx), %xmm0, %xmm0

    # R,G,B
    PSA_CHAN 24, %eax, %eax
    movl       -16(%ebp), %edx
    PSA_CHAN 28, %edx, %ecx
    PSA_CHAN 32, %edx, %edx

    cmpl       $0, -4(%ebp)  # useLinear
    je         .Lpsa_out
    # Linear path: exact L2S bytes via the global LUT.
    movl       -24(%ebp), %esi  # lut
    movzbl     (%esi,%eax), %eax
    movzbl     (%esi,%ecx), %ecx
    movzbl     (%esi,%edx), %edx
.Lpsa_out:
    # Max-channel pack + store (alpha = max(R, G, B)).
    shll       $16, %eax
    shll       $8, %ecx
    orl        %ecx, %eax
    orl        %edx, %eax
    movl       %eax, %esi
    cmpl       %ecx, %esi
    cmovl      %ecx, %esi
    cmpl       %edx, %esi
    cmovl      %edx, %esi
    shll       $24, %esi
    orl        %esi, %eax
    movl       -8(%ebp), %ecx
    movl       %eax, (%ecx)

    addl       $4, -32(%ebp)
    addl       $4, -36(%ebp)
    addl       $4, -40(%ebp)
    addl       $4, -8(%ebp)
    movl       -16(%ebp), %eax
    vmovss     40(%eax), %xmm0
    vaddss     48(%eax), %xmm0, %xmm0
    vmovss     %xmm0, 40(%eax)
    decl       -12(%ebp)
    jmp        .Lpsa_loop_Avx2

.Lpsa_done_Avx2:
    vzeroupper
    addl       $512, %esp
    popl       %edi
    popl       %esi
    popl       %ebx
    popl       %ebp
    ret
SIZE(SYM(ksvgLightingPointSpecularRowAvx2))
SIZE(SYM(ksvgLightingPointSpecularRowAvx2Linear))
GNU_STACK
