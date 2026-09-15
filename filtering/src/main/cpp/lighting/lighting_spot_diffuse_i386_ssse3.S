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
 * Spot-light diffuse SSSE3 kernel for i386.
 */

#include "asm_macros.S"
#include "lighting_i386_ssse3_macros.S"

.text
POINT_LIT4
.p2align 2
.Lspd_zero: .long 0
.Lspd_one: .long 0x3f800000
.Lspd_half: .long 0x3f000000

.globl SYM(ksvgLightingSpotDiffuseRowSsse3)
TYPE(SYM(ksvgLightingSpotDiffuseRowSsse3), @function)
SYM(ksvgLightingSpotDiffuseRowSsse3):
    xorl          %eax, %eax
    jmp           .Lspd_entry_Ssse3
.globl SYM(ksvgLightingSpotDiffuseRowSsse3Linear)
TYPE(SYM(ksvgLightingSpotDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingSpotDiffuseRowSsse3Linear):
    movl          $1, %eax
.Lspd_entry_Ssse3:
    pushl         %ebp
    movl          %esp, %ebp
    pushl         %ebx
    pushl         %esi
    pushl         %edi
    subl          $384, %esp
    LOAD_GOT(spd)
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
    movl          ksvg_linear_to_srgb_lut@GOT(%ebx), %eax
    movl          %eax, -24(%ebp)

.Lspd_loop_Ssse3:
    // Per-pixel loop (Sobel window, normalize, spot-cone factor with cutoff,
    // intensity, pack, store).
    cmpl          $0, -12(%ebp)
    jle           .Lspd_done_Ssse3

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
    addss         .Lspd_one@GOTOFF(%ebx), %xmm3
    sqrtss        %xmm3, %xmm3
    movss         .Lspd_one@GOTOFF(%ebx), %xmm0
    divss         %xmm3, %xmm0
    mulss         %xmm0, %xmm1
    mulss         %xmm0, %xmm2
    movss         %xmm2, -124(%ebp)  # nx, ny (spill ny)
    # N . L = nx*lx + ny*ly + nz*lz where nz = invLen (xmm0)

    # L = normalize(lx-ux, ly-uy, lz-sz)
    movl          -16(%ebp), %eax
    movss         40(%eax), %xmm3  # ux
    movss         44(%eax), %xmm4  # uy
    movss         -136(%ebp), %xmm5  # surfaceZ
    movss         12(%eax), %xmm6
    subss         %xmm3, %xmm6  # lx_raw
    movss         16(%eax), %xmm7
    subss         %xmm4, %xmm7  # ly_raw
    movss         20(%eax), %xmm3
    subss         %xmm5, %xmm3  # lz_raw
    movaps        %xmm6, %xmm4
    mulss         %xmm6, %xmm4
    movaps        %xmm7, %xmm5
    mulss         %xmm7, %xmm5
    addss         %xmm5, %xmm4
    movaps        %xmm3, %xmm5
    mulss         %xmm3, %xmm5
    addss         %xmm5, %xmm4
    sqrtss        %xmm4, %xmm4
    movss         .Lspd_zero@GOTOFF(%ebx), %xmm5
    ucomiss       %xmm5, %xmm4
    je            .Lspd_l_zero
    movss         .Lspd_one@GOTOFF(%ebx), %xmm5
    divss         %xmm4, %xmm5
    mulss         %xmm5, %xmm6
    mulss         %xmm5, %xmm7
    mulss         %xmm5, %xmm3
    jmp           .Lspd_l_done
.Lspd_l_zero:
    xorps         %xmm6, %xmm6
    xorps         %xmm7, %xmm7
    xorps         %xmm3, %xmm3
.Lspd_l_done:
    # L = (xmm6, xmm7, xmm3)

    # factor = max(0, -L . spotDir)
    movl          -16(%ebp), %eax
    movaps        %xmm6, %xmm4
    xorps         %xmm5, %xmm5
    subss         %xmm4, %xmm5
    mulss         52(%eax), %xmm5  # -lx * sdx
    movaps        %xmm7, %xmm4
    xorps         %xmm2, %xmm2
    subss         %xmm4, %xmm2
    mulss         56(%eax), %xmm2
    addss         %xmm2, %xmm5  # -ly * sdy
    movaps        %xmm3, %xmm4
    xorps         %xmm2, %xmm2
    subss         %xmm4, %xmm2
    mulss         60(%eax), %xmm2
    addss         %xmm2, %xmm5  # -lz * sdz
    xorps         %xmm4, %xmm4
    maxss         %xmm4, %xmm5
    movss         64(%eax), %xmm2  # spotCos
    ucomiss       %xmm2, %xmm5
    jb            .Lspd_cut
    jmp           .Lspd_cutDone
.Lspd_cut:
    xorps         %xmm5, %xmm5
.Lspd_cutDone:

    # intensity = k * factor * max(0, N . L)
    mulss         %xmm6, %xmm1  # nx * lx
    movss         -124(%ebp), %xmm2
    mulss         %xmm7, %xmm2
    addss         %xmm2, %xmm1  # + ny * ly
    mulss         %xmm0, %xmm3
    addss         %xmm3, %xmm1  # + nz * lz (nz = invLen = xmm0)
    xorps         %xmm0, %xmm0
    maxss         %xmm0, %xmm1
    mulss         8(%eax), %xmm1  # k * dot
    mulss         %xmm5, %xmm1  # * factor
    minss         .Lspd_one@GOTOFF(%ebx), %xmm1
    movaps        %xmm1, %xmm0

    # R,G,B
    CHAN_TO_INT   24, %eax, %eax, .Lspd_half
    movl          -16(%ebp), %edx
    CHAN_TO_INT   28, %edx, %ecx, .Lspd_half
    CHAN_TO_INT   32, %edx, %edx, .Lspd_half

    cmpl          $0, -4(%ebp)  # useLinear
    je            .Lspd_out
    L2S_GATHER    %esi
.Lspd_out:
PACK_FORCE_ALPHA

    addl          $4, -32(%ebp)
    addl          $4, -36(%ebp)
    addl          $4, -40(%ebp)
    addl          $4, -8(%ebp)
    movl          -16(%ebp), %eax
    movss         40(%eax), %xmm0
    addss         48(%eax), %xmm0
    movss         %xmm0, 40(%eax)
    decl          -12(%ebp)
    jmp           .Lspd_loop_Ssse3

.Lspd_done_Ssse3:
    addl          $384, %esp
    popl          %edi
    popl          %esi
    popl          %ebx
    popl          %ebp
    ret
SIZE(SYM(ksvgLightingSpotDiffuseRowSsse3))
SIZE(SYM(ksvgLightingSpotDiffuseRowSsse3Linear))
