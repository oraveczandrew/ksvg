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
 * Spot-light specular SSSE3 kernel for i386.
 */

#include "asm_macros.S"
#include "lighting_i386_ssse3_macros.S"

.text
POINT_LIT4
.p2align 2
.Lsps_zero: .long 0
.Lsps_one: .long 0x3f800000
.Lsps_half: .long 0x3f000000
EMIT_POW1_I386_TABLES

.globl SYM(ksvgLightingSpotSpecularRowSsse3)
TYPE(SYM(ksvgLightingSpotSpecularRowSsse3), @function)
SYM(ksvgLightingSpotSpecularRowSsse3):
    xorl          %eax, %eax
    jmp           .Lsps_entry_Ssse3
.globl SYM(ksvgLightingSpotSpecularRowSsse3Linear)
TYPE(SYM(ksvgLightingSpotSpecularRowSsse3Linear), @function)
SYM(ksvgLightingSpotSpecularRowSsse3Linear):
    movl          $1, %eax
.Lsps_entry_Ssse3:
    pushl         %ebp
    movl          %esp, %ebp
    pushl         %ebx
    pushl         %esi
    pushl         %edi
    subl          $384, %esp
    LOAD_GOT(sps)
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
    movl          %eax, -24(%ebp)

.Lsps_loop_Ssse3:
    // Per-pixel loop (Sobel window, normalize, half-vector dot, powf,
    // intensity, pack, store).
    cmpl          $0, -12(%ebp)
    jle           .Lsps_done_Ssse3

    movl          -32(%ebp), %eax
    ALPHA_EXTRACT 0, -84
    ALPHA_EXTRACT 4, -88
    ALPHA_EXTRACT 8, -92
    movl          -36(%ebp), %eax
    ALPHA_EXTRACT 0, -96
    ALPHA_EXTRACT 4, -136
    ALPHA_EXTRACT 8, -100
    movl          -40(%ebp), %eax
    ALPHA_EXTRACT 0, -104
    ALPHA_EXTRACT 4, -108
    ALPHA_EXTRACT 8, -112

    movl          -16(%ebp), %eax
    movss         36(%eax), %xmm7  # ss
    TO_FLOAT      -84
    TO_FLOAT      -88
    TO_FLOAT      -92
    TO_FLOAT      -96
    TO_FLOAT      -136
    TO_FLOAT      -100
    TO_FLOAT      -104
    TO_FLOAT      -108
    TO_FLOAT      -112

    # dzdx
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
    divss         0(%eax), %xmm0
    movss         %xmm0, -116(%ebp)

    # dzdy
    movss         -104(%ebp), %xmm0
    addss         -108(%ebp), %xmm0
    addss         -108(%ebp), %xmm0
    addss         -112(%ebp), %xmm0
    movss         -84(%ebp), %xmm1
    addss         -88(%ebp), %xmm1
    addss         -88(%ebp), %xmm1
    addss         -92(%ebp), %xmm1
    subss         %xmm1, %xmm0
    divss         4(%eax), %xmm0
    movss         %xmm0, -120(%ebp)

    # Normal N
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
    addss         .Lsps_one@GOTOFF(%ebx), %xmm3
    sqrtss        %xmm3, %xmm3
    movss         .Lsps_one@GOTOFF(%ebx), %xmm0
    divss         %xmm3, %xmm0
    mulss         %xmm0, %xmm1
    mulss         %xmm0, %xmm2
    movss         %xmm1, -124(%ebp)
    movss         %xmm2, -128(%ebp)
    movss         %xmm0, -132(%ebp)  # nz

    # L = normalize(lx-ux, ly-uy, lz-sz)
    movl          -16(%ebp), %eax
    movss         40(%eax), %xmm0
    movss         44(%eax), %xmm1
    movss         -136(%ebp), %xmm2
    movss         12(%eax), %xmm3
    subss         %xmm0, %xmm3
    movss         16(%eax), %xmm4
    subss         %xmm1, %xmm4
    movss         20(%eax), %xmm5
    subss         %xmm2, %xmm5
    movaps        %xmm3, %xmm6
    mulss         %xmm3, %xmm6
    movaps        %xmm4, %xmm0
    mulss         %xmm4, %xmm0
    addss         %xmm0, %xmm6
    movaps        %xmm5, %xmm0
    mulss         %xmm5, %xmm0
    addss         %xmm0, %xmm6
    sqrtss        %xmm6, %xmm6
    movss         .Lsps_zero@GOTOFF(%ebx), %xmm0
    ucomiss       %xmm0, %xmm6
    je            .Lsps_l_zero
    movss         .Lsps_one@GOTOFF(%ebx), %xmm0
    divss         %xmm6, %xmm0
    mulss         %xmm0, %xmm3
    mulss         %xmm0, %xmm4
    mulss         %xmm0, %xmm5
    jmp           .Lsps_l_done
.Lsps_l_zero:
    xorps         %xmm3, %xmm3
    xorps         %xmm4, %xmm4
    xorps         %xmm5, %xmm5
.Lsps_l_done:

    # factor = max(0, -L . spotDir)
    movl          -16(%ebp), %eax
    movaps        %xmm3, %xmm0
    xorps         %xmm1, %xmm1
    subss         %xmm0, %xmm1
    mulss         52(%eax), %xmm1  # -lx * sdx
    movaps        %xmm4, %xmm0
    xorps         %xmm2, %xmm2
    subss         %xmm0, %xmm2
    mulss         56(%eax), %xmm2
    addss         %xmm2, %xmm1  # -ly * sdy
    movaps        %xmm5, %xmm0
    xorps         %xmm2, %xmm2
    subss         %xmm0, %xmm2
    mulss         60(%eax), %xmm2
    addss         %xmm2, %xmm1  # -lz * sdz
    xorps         %xmm0, %xmm0
    maxss         %xmm0, %xmm1
    movss         64(%eax), %xmm2  # spotCos
    ucomiss       %xmm2, %xmm1
    jb            .Lsps_cut
    jmp           .Lsps_cutDone
.Lsps_cut:
    xorps         %xmm1, %xmm1
.Lsps_cutDone:
    movss         %xmm1, -140(%ebp)  # factor

    # H = normalize(L + (0,0,1))
    addss         .Lsps_one@GOTOFF(%ebx), %xmm5  # lz + 1
    movaps        %xmm3, %xmm6
    mulss         %xmm3, %xmm6
    movaps        %xmm4, %xmm0
    mulss         %xmm4, %xmm0
    addss         %xmm0, %xmm6
    movaps        %xmm5, %xmm0
    mulss         %xmm5, %xmm0
    addss         %xmm0, %xmm6
    sqrtss        %xmm6, %xmm6
    movss         .Lsps_one@GOTOFF(%ebx), %xmm0
    divss         %xmm6, %xmm0
    mulss         %xmm0, %xmm3
    mulss         %xmm0, %xmm4
    mulss         %xmm0, %xmm5

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

    # intensity = k * factor * p
    movl          -16(%ebp), %eax
    mulss         8(%eax), %xmm0
    mulss         -140(%ebp), %xmm0
    xorps         %xmm1, %xmm1
    maxss         %xmm1, %xmm0
    minss         .Lsps_one@GOTOFF(%ebx), %xmm0

    # R,G,B
    CHAN_TO_INT   24, %eax, %eax, .Lsps_half
    movl          -16(%ebp), %edx
    CHAN_TO_INT   28, %edx, %ecx, .Lsps_half
    CHAN_TO_INT   32, %edx, %edx, .Lsps_half

    cmpl          $0, -4(%ebp)  # useLinear
    je            .Lsps_out
    L2S_GATHER    %esi
.Lsps_out:
PACK_MAX_ALPHA

    addl          $4, -32(%ebp)
    addl          $4, -36(%ebp)
    addl          $4, -40(%ebp)
    addl          $4, -8(%ebp)
    movl          -16(%ebp), %eax
    movss         40(%eax), %xmm0
    addss         48(%eax), %xmm0
    movss         %xmm0, 40(%eax)
    decl          -12(%ebp)
    jmp           .Lsps_loop_Ssse3

.Lsps_done_Ssse3:
    addl          $384, %esp
    popl          %edi
    popl          %esi
    popl          %ebx
    popl          %ebp
    ret
SIZE(SYM(ksvgLightingSpotSpecularRowSsse3))
SIZE(SYM(ksvgLightingSpotSpecularRowSsse3Linear))
