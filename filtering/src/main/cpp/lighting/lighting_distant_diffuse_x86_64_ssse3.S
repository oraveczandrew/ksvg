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


.text
.p2align 5
.globl SYM(ksvgLightingDistantDiffuseRowSsse3)
TYPE(SYM(ksvgLightingDistantDiffuseRowSsse3), @function)
SYM(ksvgLightingDistantDiffuseRowSsse3):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Ldone

    push    %rbx
    push    %rbp

    // Load Params
    movss   .Lone(%rip), %xmm0
    divss   0(%r9), %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, %xmm6            // xmm6 = 1/invDx

    movss   .Lone(%rip), %xmm0
    divss   4(%r9), %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, %xmm7            // xmm7 = 1/invDy

    movss   8(%r9), %xmm8           // k
    shufps  $0, %xmm8, %xmm8
    movss   12(%r9), %xmm9          // lx
    shufps  $0, %xmm9, %xmm9
    movss   16(%r9), %xmm10         // ly
    shufps  $0, %xmm10, %xmm10
    movss   20(%r9), %xmm11         // lz
    shufps  $0, %xmm11, %xmm11
    movss   24(%r9), %xmm12         // lr
    shufps  $0, %xmm12, %xmm12
    movss   28(%r9), %xmm13         // lg
    shufps  $0, %xmm13, %xmm13
    movss   32(%r9), %xmm14         // lb
    shufps  $0, %xmm14, %xmm14
    movss   36(%r9), %xmm15         // ss
    shufps  $0, %xmm15, %xmm15
    mulps   %xmm15, %xmm6            // ss / invDx
    mulps   %xmm15, %xmm7            // ss / invDy

    mov     %r8d, %r10d

.Lloop:
    // rowT alpha (keep integer until derivatives are complete)
    movups  0(%rdi), %xmm0
    psrld   $24, %xmm0               // hT_l

    movups  4(%rdi), %xmm1
    psrld   $24, %xmm1               // hT_m

    movups  8(%rdi), %xmm2
    psrld   $24, %xmm2               // hT_r

    // sumT = lT + 2*mT + rT
    movaps  %xmm1, %xmm3
    paddd   %xmm1, %xmm3
    paddd   %xmm0, %xmm3
    paddd   %xmm2, %xmm3             // xmm3 = sumT

    // dx_rel = rT - lT
    movaps  %xmm2, %xmm4
    psubd   %xmm0, %xmm4

    // rowM alpha
    movups  0(%rsi), %xmm0
    psrld   $24, %xmm0               // hM_l

    movups  8(%rsi), %xmm2
    psrld   $24, %xmm2               // hM_r

    // dx_rel += 2*(rM - lM)
    movaps  %xmm2, %xmm5
    psubd   %xmm0, %xmm5
    paddd   %xmm5, %xmm5
    paddd   %xmm5, %xmm4

    // rowB alpha
    movups  0(%rdx), %xmm0
    psrld   $24, %xmm0               // hB_l

    movups  4(%rdx), %xmm1
    psrld   $24, %xmm1               // hB_m

    movups  8(%rdx), %xmm2
    psrld   $24, %xmm2               // hB_r

    // sumB = lB + 2*mB + rB
    movaps  %xmm1, %xmm5
    paddd   %xmm1, %xmm5
    paddd   %xmm0, %xmm5
    paddd   %xmm2, %xmm5             // xmm5 = sumB

    // final dx_rel += rB - lB
    psubd   %xmm0, %xmm2
    paddd   %xmm2, %xmm4             // final dx_rel

    // Convert final integer derivatives to float and apply scale once.
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm6, %xmm4             // dx (includes ss)
    psubd   %xmm3, %xmm5
    cvtdq2ps %xmm5, %xmm5
    mulps   %xmm7, %xmm5             // dy (includes ss)

    // n = (-dx, -dy, 1)
    xorps   %xmm0, %xmm0
    subps   %xmm4, %xmm0            // nx
    xorps   %xmm1, %xmm1
    subps   %xmm5, %xmm1            // ny

    movaps  %xmm0, %xmm2
    mulps   %xmm0, %xmm2            // nx^2
    movaps  %xmm1, %xmm3
    mulps   %xmm1, %xmm3
    addps   %xmm3, %xmm2
    addps   .Lone(%rip), %xmm2      // nLen^2

    sqrtps  %xmm2, %xmm3            // nLen
    divps   %xmm3, %xmm0            // nx
    divps   %xmm3, %xmm1            // ny
    movaps  .Lone(%rip), %xmm5
    divps   %xmm3, %xmm5            // nz

    mulps   %xmm9, %xmm0
    mulps   %xmm10, %xmm1
    addps   %xmm1, %xmm0
    mulps   %xmm11, %xmm5
    addps   %xmm5, %xmm0            // dot

    maxps   .Lzero(%rip), %xmm0
    mulps   %xmm8, %xmm0
    minps   .Lone(%rip), %xmm0      // intensity

    // Pack
    movaps  %xmm0, %xmm1
    mulps   %xmm12, %xmm1           // outR
    movaps  %xmm0, %xmm2
    mulps   %xmm13, %xmm2           // outG
    mulps   %xmm14, %xmm0           // outB

    addps   .Lhalf(%rip), %xmm1
    addps   .Lhalf(%rip), %xmm2
    addps   .Lhalf(%rip), %xmm0

    cvttps2dq %xmm1, %xmm1
    cvttps2dq %xmm2, %xmm2
    cvttps2dq %xmm0, %xmm0

    pslld   $16, %xmm1
    pslld   $8, %xmm2
    por     %xmm1, %xmm0
    por     %xmm2, %xmm0
    por     .LmaskAlphaShifted(%rip), %xmm0

    movups  %xmm0, (%rcx)

    add     $16, %rdi
    add     $16, %rsi
    add     $16, %rdx
    add     $16, %rcx
    sub     $4, %r10d
    jnz     .Lloop

    pop     %rbp
    pop     %rbx
.Ldone:
    ret

SIZE(SYM(ksvgLightingDistantDiffuseRowSsse3))

.p2align 5
.globl SYM(ksvgLightingDistantDiffuseRowSsse3Linear)
TYPE(SYM(ksvgLightingDistantDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingDistantDiffuseRowSsse3Linear):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Llin_done

    push    %rbx
    push    %rbp

    // Load Params
    movss   .Lone(%rip), %xmm0
    divss   0(%r9), %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, %xmm6            // xmm6 = 1/invDx

    movss   .Lone(%rip), %xmm0
    divss   4(%r9), %xmm0
    shufps  $0, %xmm0, %xmm0
    movaps  %xmm0, %xmm7            // xmm7 = 1/invDy

    movss   8(%r9), %xmm8           // k
    shufps  $0, %xmm8, %xmm8
    movss   12(%r9), %xmm9          // lx
    shufps  $0, %xmm9, %xmm9
    movss   16(%r9), %xmm10         // ly
    shufps  $0, %xmm10, %xmm10
    movss   20(%r9), %xmm11         // lz
    shufps  $0, %xmm11, %xmm11
    movss   24(%r9), %xmm12         // lr
    shufps  $0, %xmm12, %xmm12
    movss   28(%r9), %xmm13         // lg
    shufps  $0, %xmm13, %xmm13
    movss   32(%r9), %xmm14         // lb
    shufps  $0, %xmm14, %xmm14
    movss   36(%r9), %xmm15         // ss
    shufps  $0, %xmm15, %xmm15
    mulps   %xmm15, %xmm6            // ss / invDx
    mulps   %xmm15, %xmm7            // ss / invDy

    mov     %r8d, %r10d

.Llin_loop:
    // rowT alpha (keep integer until derivatives are complete)
    movups  0(%rdi), %xmm0
    psrld   $24, %xmm0               // hT_l

    movups  4(%rdi), %xmm1
    psrld   $24, %xmm1               // hT_m

    movups  8(%rdi), %xmm2
    psrld   $24, %xmm2               // hT_r

    // sumT = lT + 2*mT + rT
    movaps  %xmm1, %xmm3
    paddd   %xmm1, %xmm3
    paddd   %xmm0, %xmm3
    paddd   %xmm2, %xmm3             // xmm3 = sumT

    // dx_rel = rT - lT
    movaps  %xmm2, %xmm4
    psubd   %xmm0, %xmm4

    // rowM alpha
    movups  0(%rsi), %xmm0
    psrld   $24, %xmm0               // hM_l

    movups  8(%rsi), %xmm2
    psrld   $24, %xmm2               // hM_r

    // dx_rel += 2*(rM - lM)
    movaps  %xmm2, %xmm5
    psubd   %xmm0, %xmm5
    paddd   %xmm5, %xmm5
    paddd   %xmm5, %xmm4

    // rowB alpha
    movups  0(%rdx), %xmm0
    psrld   $24, %xmm0               // hB_l

    movups  4(%rdx), %xmm1
    psrld   $24, %xmm1               // hB_m

    movups  8(%rdx), %xmm2
    psrld   $24, %xmm2               // hB_r

    // sumB = lB + 2*mB + rB
    movaps  %xmm1, %xmm5
    paddd   %xmm1, %xmm5
    paddd   %xmm0, %xmm5
    paddd   %xmm2, %xmm5             // xmm5 = sumB

    // final dx_rel += rB - lB
    psubd   %xmm0, %xmm2
    paddd   %xmm2, %xmm4             // final dx_rel

    // Convert final integer derivatives to float and apply scale once.
    cvtdq2ps %xmm4, %xmm4
    mulps   %xmm6, %xmm4             // dx (includes ss)
    psubd   %xmm3, %xmm5
    cvtdq2ps %xmm5, %xmm5
    mulps   %xmm7, %xmm5             // dy (includes ss)

    // n = (-dx, -dy, 1)
    xorps   %xmm0, %xmm0
    subps   %xmm4, %xmm0            // nx
    xorps   %xmm1, %xmm1
    subps   %xmm5, %xmm1            // ny

    movaps  %xmm0, %xmm2
    mulps   %xmm0, %xmm2            // nx^2
    movaps  %xmm1, %xmm3
    mulps   %xmm1, %xmm3
    addps   %xmm3, %xmm2
    addps   .Lone(%rip), %xmm2      // nLen^2

    sqrtps  %xmm2, %xmm3            // nLen
    divps   %xmm3, %xmm0            // nx
    divps   %xmm3, %xmm1            // ny
    movaps  .Lone(%rip), %xmm5
    divps   %xmm3, %xmm5            // nz

    mulps   %xmm9, %xmm0
    mulps   %xmm10, %xmm1
    addps   %xmm1, %xmm0
    mulps   %xmm11, %xmm5
    addps   %xmm5, %xmm0            // dot

    maxps   .Lzero(%rip), %xmm0
    mulps   %xmm8, %xmm0
    minps   .Lone(%rip), %xmm0      // intensity

    // Pack
    movaps  %xmm0, %xmm1
    mulps   %xmm12, %xmm1           // outR
    movaps  %xmm0, %xmm2
    mulps   %xmm13, %xmm2           // outG
    mulps   %xmm14, %xmm0           // outB

    addps   .Lhalf(%rip), %xmm1
    addps   .Lhalf(%rip), %xmm2
    addps   .Lhalf(%rip), %xmm0

    cvttps2dq %xmm1, %xmm1
    cvttps2dq %xmm2, %xmm2
    cvttps2dq %xmm0, %xmm0

    pslld   $16, %xmm1
    pslld   $8, %xmm2
    por     %xmm1, %xmm0
    por     %xmm2, %xmm0
    por     .LmaskAlphaShifted(%rip), %xmm0

    // Inline linear-light -> sRGB amortized L2S conversion.
    // Exact same algorithm as the established x86-64 SSSE3 L2S kernel.
    movdqa  %xmm0, %xmm1              // high nibble
    psrlw   $4, %xmm1
    pand    .Ll2s_nibble_mask(%rip), %xmm1
    movdqa  %xmm0, %xmm2              // low nibble (also retained for exact-low16)
    pand    .Ll2s_nibble_mask(%rip), %xmm2
    pxor    %xmm6, %xmm6              // zero

    movdqa  .Ll2s_base_lut(%rip), %xmm3
    pshufb  %xmm1, %xmm3
    movdqa  .Ll2s_slope_lut(%rip), %xmm4
    pshufb  %xmm1, %xmm4

    movdqa  %xmm4, %xmm5
    punpcklbw %xmm6, %xmm5
    movdqa  %xmm2, %xmm7
    punpcklbw %xmm6, %xmm7
    pmaddubsw %xmm7, %xmm5

    movdqa  %xmm4, %xmm7
    punpckhbw %xmm6, %xmm7
    movdqa  %xmm2, %xmm4
    punpckhbw %xmm6, %xmm4
    pmaddubsw %xmm4, %xmm7

    paddw   .Ll2s_rounding(%rip), %xmm5
    psrlw   $5, %xmm5
    paddw   .Ll2s_rounding(%rip), %xmm7
    psrlw   $5, %xmm7
    packuswb %xmm7, %xmm5
    paddb   %xmm3, %xmm5

    // Correction bitset: use the original packed RGB input (xmm0).
    movdqa  %xmm0, %xmm3
    psrlw   $3, %xmm3
    pand    .Ll2s_group_mask(%rip), %xmm3
    movdqa  %xmm3, %xmm4
    psubb   .Ll2s_group16(%rip), %xmm4
    movdqa  .Ll2s_correction_hi(%rip), %xmm7
    pshufb  %xmm4, %xmm7
    movdqa  %xmm3, %xmm4
    psrlw   $4, %xmm4
    pand    .Ll2s_one_byte(%rip), %xmm4
    psllw   $7, %xmm4
    por     %xmm3, %xmm4
    movdqa  .Ll2s_correction_lo(%rip), %xmm3
    pshufb  %xmm4, %xmm3
    por     %xmm7, %xmm3

    movdqa  %xmm2, %xmm4
    pand    .Ll2s_low3_mask(%rip), %xmm4
    movdqa  .Ll2s_onehot_lut(%rip), %xmm7
    pshufb  %xmm4, %xmm7
    pand    %xmm7, %xmm3
    pminub  .Ll2s_one_byte(%rip), %xmm3
    psubb   %xmm3, %xmm5

    movdqa  .Ll2s_exact_low16(%rip), %xmm3
    pshufb  %xmm2, %xmm3
    pcmpeqb %xmm6, %xmm1
    pand    %xmm1, %xmm3
    pandn   %xmm5, %xmm1
    por     %xmm3, %xmm1

    // Diffuse output alpha is always 255.
    pand    .Ll2s_rgb_mask(%rip), %xmm1
    por     .LmaskAlphaShifted(%rip), %xmm1
    movdqu  %xmm1, (%rcx)
    add     $16, %rdi
    add     $16, %rsi
    add     $16, %rdx
    add     $16, %rcx
    sub     $4, %r10d
    jnz     .Llin_loop

    pop     %rbp
    pop     %rbx
.Llin_done:
    ret

SIZE(SYM(ksvgLightingDistantDiffuseRowSsse3Linear))

RODATA
.p2align 4
.Ll2s_exact_low16:
    .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.Ll2s_base_lut:
    .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
.Ll2s_slope_lut:
    .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
.Ll2s_nibble_mask:
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.Ll2s_group_mask:
    .byte 31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
.Ll2s_low3_mask:
    .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
.Ll2s_one_byte:
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.Ll2s_group16:
    .byte 16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16
.Ll2s_onehot_lut:
    .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.Ll2s_correction_lo:
    .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
.Ll2s_correction_hi:
    .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
.Ll2s_alpha_mask:
    .long 0xff000000,0xff000000,0xff000000,0xff000000
.Ll2s_rgb_mask:
    .long 0x00ffffff,0x00ffffff,0x00ffffff,0x00ffffff
.Ll2s_rounding:
    .short 16,16,16,16,16,16,16,16

.p2align 4
.Lzero:             .float 0.0, 0.0, 0.0, 0.0
.Lone:              .float 1.0, 1.0, 1.0, 1.0
.Lhalf:             .float 0.5, 0.5, 0.5, 0.5
.Lthree_halves:     .float 1.5, 1.5, 1.5, 1.5
.LmaskAlphaShifted: .long 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000


