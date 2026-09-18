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
 * Point-light specular SSSE3 kernel for i386.
 *
 * void ksvgLightingPointSpecularRowSsse3(
 *   const jint* srcT, const jint* srcM, const jint* srcB,
 *   jint* dst, jint count, const PointLightingParams* params, float exponent)
 *
 * Arguments on stack (8(%ebp) to 32(%ebp)):
 *   8: srcT, 12: srcM, 16: srcB, 20: dst, 24: count, 28: params, 32: exponent
 */

#include "asm_macros.S"
#include "lighting_i386_ssse3_macros.S"

.text

POINT_LIT4
.p2align 2
.Lp_zero: .long 0
.Lp_one: .long 0x3f800000
.Lp_half: .long 0x3f000000
.Lp_255: .long 0x437f0000
.Lp_idx0: .long 0x00000000
.Lp_idx1: .long 0x3f800000
.Lp_idx2: .long 0x40000000
.Lp_idx3: .long 0x40400000
EMIT_POW1_I386_TABLES

.text

/*
 * Description:
 *   Clamps a channel integer to [0, 255] via branches. Pre-existing
 *   file-local macro (single-file use); preserved as-is.
 *
 * Inputs:
 *   \reg  = 32-bit GPR holding the channel value (in-place)
 *
 * Output:
 *   \reg  = clamped to [0, 255]
 *
 * Clobbers:
 *   \reg (in-place)
 *   flags
 */
.macro CLAMP reg
    cmpl          $0, \reg
    jge           1f
    xorl          \reg, \reg
    jmp           2f
1:
    cmpl          $255, \reg
    jle           2f
    movl          $255, \reg
2:
.endm

.globl SYM(ksvgLightingPointSpecularRowSsse3)
TYPE(SYM(ksvgLightingPointSpecularRowSsse3), @function)
SYM(ksvgLightingPointSpecularRowSsse3):
    xorl          %eax, %eax
    jmp           .Lp_entry_Ssse3
.globl SYM(ksvgLightingPointSpecularRowSsse3Linear)
TYPE(SYM(ksvgLightingPointSpecularRowSsse3Linear), @function)
SYM(ksvgLightingPointSpecularRowSsse3Linear):
    movl          $1, %eax
.Lp_entry_Ssse3:
    pushl         %ebp
    movl          %esp, %ebp
    pushl         %ebx
    pushl         %esi
    pushl         %edi
    subl          $256, %esp
    LOAD_GOT(ps)
    movl          %eax, -4(%ebp)  # useLinear
    movl          8(%ebp), %eax
    movl          %eax, -32(%ebp)  # srcT
    movl          12(%ebp), %eax
    movl          %eax, -36(%ebp)  # srcM
    movl          16(%ebp), %eax
    movl          %eax, -40(%ebp)  # srcB
    movl          20(%ebp), %eax
    movl          %eax, -8(%ebp)  # dst
    movl          24(%ebp), %eax
    movl          %eax, -12(%ebp)  # count
    movl          28(%ebp), %eax
    movl          %eax, -16(%ebp)  # params
    movl          32(%ebp), %eax
    movl          %eax, -20(%ebp)  # exponent
    movl          ksvg_linear_to_srgb_lut@GOT(%ebx), %eax
    movl          %eax, -24(%ebp)  # lut pointer

.Lp_loop_Ssse3:
    # Per-pixel loop (Sobel window, normalize, half-vector dot, powf,
    # intensity, pack, store; advances ux0 by dux).
    cmpl          $0, -12(%ebp)
    jle           .Lp_done_Ssse3

    # Load 3 horizontal samples from 3 rows for ONE output pixel.
    # Output pixel 0 needs samples at x-1, x, x+1.
    # srcT/M/B pointers are already at x-1.
    movl          -32(%ebp), %eax
    ALPHA_EXTRACT 0, -84
    ALPHA_EXTRACT 4, -88
    ALPHA_EXTRACT 8, -92

    movl          -36(%ebp), %eax
    ALPHA_EXTRACT 4, -136

    movl          -36(%ebp), %eax
    ALPHA_EXTRACT 0, -96
    ALPHA_EXTRACT 8, -100

    movl          -40(%ebp), %eax
    ALPHA_EXTRACT 0, -104
    ALPHA_EXTRACT 4, -108
    ALPHA_EXTRACT 8, -112

    # Convert to float and scale by surfaceScale.
    movl          -16(%ebp), %eax
    movss         36(%eax), %xmm7  # ss

    TO_FLOAT      -84
    TO_FLOAT      -88
    TO_FLOAT      -92
    TO_FLOAT      -96
    TO_FLOAT      -100
    TO_FLOAT      -136
    TO_FLOAT      -104
    TO_FLOAT      -108
    TO_FLOAT      -112

    # dzdx = (tr + 2*mr + br) - (tl + 2*ml + bl)
    movss         -92(%ebp), %xmm0
    addss         -100(%ebp), %xmm0
    addss         -100(%ebp), %xmm0
    addss         -112(%ebp), %xmm0
    movss         -84(%ebp), %xmm1
    addss         -96(%ebp), %xmm1
    addss         -96(%ebp), %xmm1
    addss         -104(%ebp), %xmm1
    subss         %xmm1, %xmm0
    movl          -16(%ebp), %eax
    divss         0(%eax), %xmm0  # dzdx /= invDx
    movss         %xmm0, -116(%ebp)

    # dzdy = (bl + 2*bm + br) - (tl + 2*tm + tr)
    movss         -104(%ebp), %xmm0
    addss         -108(%ebp), %xmm0
    addss         -108(%ebp), %xmm0
    addss         -112(%ebp), %xmm0
    movss         -84(%ebp), %xmm1
    addss         -88(%ebp), %xmm1
    addss         -88(%ebp), %xmm1
    addss         -92(%ebp), %xmm1
    subss         %xmm1, %xmm0
    divss         4(%eax), %xmm0  # dzdy /= invDy
    movss         %xmm0, -120(%ebp)

    # Normal N = normalize(-dzdx, -dzdy, 1)
    movss         -116(%ebp), %xmm0
    xorps         %xmm1, %xmm1
    subss         %xmm0, %xmm1  # nx
    movss         -120(%ebp), %xmm0
    xorps         %xmm2, %xmm2
    subss         %xmm0, %xmm2  # ny
    movaps        %xmm1, %xmm3
    mulss         %xmm1, %xmm3
    movaps        %xmm2, %xmm0
    mulss         %xmm2, %xmm0
    addss         %xmm0, %xmm3
    addss         .Lp_one@GOTOFF(%ebx), %xmm3  # nz=1, nz^2=1
    sqrtss        %xmm3, %xmm3
    movss         .Lp_one@GOTOFF(%ebx), %xmm0
    divss         %xmm3, %xmm0  # invLen
    mulss         %xmm0, %xmm1  # nx
    mulss         %xmm0, %xmm2  # ny
    movss         %xmm1, -124(%ebp)
    movss         %xmm2, -128(%ebp)
    movss         %xmm0, -132(%ebp)  # nz

    # Point light L = normalize(lightX - ux, lightY - uy, lightZ - surfaceZ)
    movl          -16(%ebp), %eax
    # ux = ux0, uy = uy, dux = dux. (ux0 is updated in loop)
    movss         40(%eax), %xmm0  # ux
    movss         44(%eax), %xmm1  # uy
    movss         -136(%ebp), %xmm2  # surfaceZ (at current pixel mm)

    movss         12(%eax), %xmm3
    subss         %xmm0, %xmm3  # lx_raw
    movss         16(%eax), %xmm4
    subss         %xmm1, %xmm4  # ly_raw
    movss         20(%eax), %xmm5
    subss         %xmm2, %xmm5  # lz_raw

    movaps        %xmm3, %xmm6
    mulss         %xmm3, %xmm6
    movaps        %xmm4, %xmm0
    mulss         %xmm4, %xmm0
    addss         %xmm0, %xmm6
    movaps        %xmm5, %xmm0
    mulss         %xmm5, %xmm0
    addss         %xmm0, %xmm6
    sqrtss        %xmm6, %xmm6
    movss         .Lp_zero@GOTOFF(%ebx), %xmm0
    ucomiss       %xmm0, %xmm6
    je            .Lp_l_zero
    movss         .Lp_one@GOTOFF(%ebx), %xmm0
    divss         %xmm6, %xmm0
    mulss         %xmm0, %xmm3
    mulss         %xmm0, %xmm4
    mulss         %xmm0, %xmm5
    jmp           .Lp_l_done
.Lp_l_zero:
    xorps         %xmm3, %xmm3
    xorps         %xmm4, %xmm4
    xorps         %xmm5, %xmm5
.Lp_l_done:
    # L = (xmm3, xmm4, xmm5)

    # Half vector H = normalize(L + (0,0,1))
    addss         .Lp_one@GOTOFF(%ebx), %xmm5  # lz + 1
    movaps        %xmm3, %xmm6
    mulss         %xmm3, %xmm6
    movaps        %xmm4, %xmm0
    mulss         %xmm4, %xmm0
    addss         %xmm0, %xmm6
    movaps        %xmm5, %xmm0
    mulss         %xmm5, %xmm0
    addss         %xmm0, %xmm6
    sqrtss        %xmm6, %xmm6
    movss         .Lp_one@GOTOFF(%ebx), %xmm0
    divss         %xmm6, %xmm0
    mulss         %xmm0, %xmm3
    mulss         %xmm0, %xmm4
    mulss         %xmm0, %xmm5
    # H = (xmm3, xmm4, xmm5)

    # ndoth = max(0, N . H)
    mulss         -124(%ebp), %xmm3
    mulss         -128(%ebp), %xmm4
    addss         %xmm4, %xmm3
    mulss         -132(%ebp), %xmm5
    addss         %xmm5, %xmm3
    xorps         %xmm0, %xmm0
    maxss         %xmm0, %xmm3

    # p = powf(ndoth, exponent): inline scalar minimax, no PLT call.
    movaps        %xmm3, %xmm1  # pow base
    movss         -20(%ebp), %xmm2  # exponent (y)
    POW1_SSE
    movss         %xmm0, -160(%ebp)
    movss         -160(%ebp), %xmm0

    # intensity = k * p
    movl          -16(%ebp), %eax
    mulss         8(%eax), %xmm0  # k * p
    xorps         %xmm1, %xmm1
    maxss         %xmm1, %xmm0
    movss         .Lp_one@GOTOFF(%ebx), %xmm1
    minss         %xmm1, %xmm0

    # R = lr * intensity, G = lg * intensity, B = lb * intensity
    CHAN_TO_INT   24, %eax, %eax, .Lp_half
    movl          -16(%ebp), %edx
    CHAN_TO_INT   28, %edx, %ecx, .Lp_half
    CHAN_TO_INT   32, %edx, %edx, .Lp_half

    movl          %eax, -168(%ebp)
    movl          %ecx, -172(%ebp)
    movl          %edx, -176(%ebp)

    cmpl          $0, -4(%ebp)  # useLinear
    je            .Lp_nolinear
    movl          -24(%ebp), %esi  # lut
    movl          -168(%ebp), %eax
    CLAMP %eax
    movzbl        (%esi,%eax), %eax
    movl          %eax, -168(%ebp)
    movl          -172(%ebp), %eax
    CLAMP %eax
    movzbl        (%esi,%eax), %eax
    movl          %eax, -172(%ebp)
    movl          -176(%ebp), %eax
    CLAMP %eax
    movzbl        (%esi,%eax), %eax
    movl          %eax, -176(%ebp)
    jmp           .Lp_out
.Lp_nolinear:
    movl          -168(%ebp), %eax
    CLAMP %eax
    movl          %eax, -168(%ebp)
    movl          -172(%ebp), %eax
    CLAMP %eax
    movl          %eax, -172(%ebp)
    movl          -176(%ebp), %eax
    CLAMP %eax
    movl          %eax, -176(%ebp)
.Lp_out:
    movl          -168(%ebp), %eax  # R
    movl          -172(%ebp), %ecx  # G
    movl          -176(%ebp), %edx  # B
    movl          %eax, %esi
    cmpl          %ecx, %esi
    cmovl         %ecx, %esi
    cmpl          %edx, %esi
    cmovl         %edx, %esi  # esi = max(R,G,B)
    shll          $16, %eax
    shll          $8, %ecx
    shll          $24, %esi
    orl           %ecx, %eax
    orl           %edx, %eax
    orl           %esi, %eax
    movl          -8(%ebp), %ecx  # dst
    movl          %eax, (%ecx)

    # Update pointers and ux0
    addl          $4, -32(%ebp)
    addl          $4, -36(%ebp)
    addl          $4, -40(%ebp)
    addl          $4, -8(%ebp)
    movl          -16(%ebp), %eax
    movss         40(%eax), %xmm0
    addss         48(%eax), %xmm0
    movss         %xmm0, 40(%eax)  # ux0 += dux

    decl          -12(%ebp)
    jmp           .Lp_loop_Ssse3

.Lp_done_Ssse3:
    addl          $256, %esp
    popl          %edi
    popl          %esi
    popl          %ebx
    popl          %ebp
    ret

SIZE(SYM(ksvgLightingPointSpecularRowSsse3))
SIZE(SYM(ksvgLightingPointSpecularRowSsse3Linear))
