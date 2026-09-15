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


/* Exact amortized linear->sRGB conversion for four ARGB pixels.
 * Same arithmetic/table path as the validated standalone SSSE3 unlinearize kernel.
 * Input/output: xmm0 = four packed ARGB pixels.
 */
.macro L2S_ARGB4 sh4, sh5, sh3, sh7
    movdqa  %xmm0, %xmm8
    pand    .L_alpha_mask(%rip), %xmm8
    pxor    %xmm7, %xmm7

    movdqa  %xmm0, %xmm1
    psrlw   $\sh4, %xmm1
    pand    .L_nibble_mask(%rip), %xmm1
    movdqa  %xmm0, %xmm2
    pand    .L_nibble_mask(%rip), %xmm2

    movdqa  .L_base_lut(%rip), %xmm3
    pshufb  %xmm1, %xmm3
    movdqa  .L_slope_lut(%rip), %xmm4
    pshufb  %xmm1, %xmm4

    movdqa  %xmm4, %xmm5
    punpcklbw %xmm7, %xmm5
    movdqa  %xmm2, %xmm6
    punpcklbw %xmm7, %xmm6
    pmaddubsw %xmm6, %xmm5

    movdqa  %xmm4, %xmm6
    punpckhbw %xmm7, %xmm6
    movdqa  %xmm2, %xmm4
    punpckhbw %xmm7, %xmm4
    pmaddubsw %xmm4, %xmm6

    paddw   .L_rounding(%rip), %xmm5
    psrlw   $\sh5, %xmm5
    paddw   .L_rounding(%rip), %xmm6
    psrlw   $\sh5, %xmm6
    packuswb %xmm6, %xmm5
    paddb   %xmm3, %xmm5

    movdqa  %xmm0, %xmm3
    psrlw   $\sh3, %xmm3
    pand    .L_group_mask(%rip), %xmm3
    movdqa  %xmm3, %xmm4
    psubb   .L_group16(%rip), %xmm4
    movdqa  .L_correction_hi(%rip), %xmm6
    pshufb  %xmm4, %xmm6
    movdqa  %xmm3, %xmm4
    psrlw   $\sh4, %xmm4
    pand    .L_one_byte(%rip), %xmm4
    psllw   $\sh7, %xmm4
    por     %xmm3, %xmm4
    movdqa  .L_correction_lo(%rip), %xmm3
    pshufb  %xmm4, %xmm3
    por     %xmm6, %xmm3
    movdqa  %xmm0, %xmm4
    pand    .L_low3_mask(%rip), %xmm4
    movdqa  .L_onehot_lut(%rip), %xmm6
    pshufb  %xmm4, %xmm6
    pand    %xmm6, %xmm3
    pminub  .L_one_byte(%rip), %xmm3
    psubb   %xmm3, %xmm5

    movdqa  .L_exact_low16(%rip), %xmm3
    pshufb  %xmm2, %xmm3
    pcmpeqb %xmm7, %xmm1
    pand    %xmm1, %xmm3
    pandn   %xmm5, %xmm1
    por     %xmm3, %xmm1

    pand    .L_rgb_mask(%rip), %xmm1
    por     %xmm8, %xmm1
    movdqa  %xmm1, %xmm0
.endm

.text
.p2align 5
.globl SYM(ksvgLightingDistantDiffuseRowAvx2)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx2), @function)
SYM(ksvgLightingDistantDiffuseRowAvx2):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Ldone

    // Load Params
    vbroadcastss .Lone(%rip), %ymm0
    vdivss  0(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm6           // ymm6 = 1/invDx
    vdivss  4(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm7           // ymm7 = 1/invDy

    vbroadcastss 8(%r9), %ymm8           // k
    vbroadcastss 12(%r9), %ymm9          // lx
    vbroadcastss 16(%r9), %ymm10         // ly
    vbroadcastss 20(%r9), %ymm11         // lz
    vbroadcastss 24(%r9), %ymm12         // lr
    vbroadcastss 28(%r9), %ymm13         // lg
    vbroadcastss 32(%r9), %ymm14         // lb
    // Fold surface scale into derivative scales; ymm15 becomes available.
    vbroadcastss 36(%r9), %ymm15         // ss
    vmulps  %ymm15, %ymm6, %ymm6         // ss / invDx
    vmulps  %ymm15, %ymm7, %ymm7         // ss / invDy
    vbroadcastss .Lone(%rip), %ymm15     // 1.0

    mov     %r8d, %r10d

.Lloop:
    // rowT alpha
    vmovups 0(%rdi), %ymm0
    vpsrld  $24, %ymm0, %ymm0        // hT_l
    vmovups 4(%rdi), %ymm1
    vpsrld  $24, %ymm1, %ymm1        // hT_m
    vmovups 8(%rdi), %ymm2
    vpsrld  $24, %ymm2, %ymm2        // hT_r

    // sumT = lT + 2*mT + rT
    vpaddd  %ymm1, %ymm1, %ymm3
    vpaddd  %ymm0, %ymm3, %ymm3
    vpaddd  %ymm2, %ymm3, %ymm3

    // dx_rel = rT - lT
    vpsubd  %ymm0, %ymm2, %ymm4

    // rowM alpha
    vmovups 0(%rsi), %ymm0
    vpsrld  $24, %ymm0, %ymm0        // hM_l
    vmovups 8(%rsi), %ymm2
    vpsrld  $24, %ymm2, %ymm2        // hM_r

    // dx_rel += 2*(rM - lM)
    vpsubd  %ymm0, %ymm2, %ymm5
    vpaddd  %ymm5, %ymm5, %ymm5
    vpaddd  %ymm5, %ymm4, %ymm4

    // rowB alpha
    vmovups 0(%rdx), %ymm0
    vpsrld  $24, %ymm0, %ymm0        // hB_l
    vmovups 4(%rdx), %ymm1
    vpsrld  $24, %ymm1, %ymm1        // hB_m
    vmovups 8(%rdx), %ymm2
    vpsrld  $24, %ymm2, %ymm2        // hB_r

    // sumB = lB + 2*mB + rB
    vpaddd  %ymm1, %ymm1, %ymm5
    vpaddd  %ymm0, %ymm5, %ymm5
    vpaddd  %ymm2, %ymm5, %ymm5

    // final dx_rel += rB - lB
    vpsubd  %ymm0, %ymm2, %ymm0
    vpaddd  %ymm0, %ymm4, %ymm4

    // Convert the final integer derivatives to float and apply scale once.
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm6, %ymm4, %ymm4       // dx (includes ss)
    vpsubd  %ymm3, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vmulps  %ymm7, %ymm5, %ymm5       // dy (includes ss)

    // n = (-dx, -dy, 1)
    vxorps  %ymm0, %ymm0, %ymm0
    vsubps  %ymm4, %ymm0, %ymm0         // nx
    vxorps  %ymm1, %ymm1, %ymm1
    vsubps  %ymm5, %ymm1, %ymm1         // ny

    vmulps  %ymm0, %ymm0, %ymm2
    vmulps  %ymm1, %ymm1, %ymm3
    vaddps  %ymm2, %ymm3, %ymm2         // nx² + ny²
    vaddps  %ymm15, %ymm2, %ymm2        // nLen^2

    vsqrtps %ymm2, %ymm3                // nLen
    vdivps  %ymm3, %ymm0, %ymm0         // nx
    vdivps  %ymm3, %ymm1, %ymm1         // ny
    vmovaps %ymm15, %ymm5
    vdivps  %ymm3, %ymm5, %ymm5         // nz

    vmulps  %ymm9, %ymm0, %ymm0
    vmulps  %ymm10, %ymm1, %ymm3
    vaddps  %ymm0, %ymm3, %ymm0         // nx*lx + ny*ly
    vmulps  %ymm11, %ymm5, %ymm5
    vaddps  %ymm0, %ymm5, %ymm0         // + nz*lz

    vxorps  %ymm4, %ymm4, %ymm4
    vmaxps  %ymm4, %ymm0, %ymm0
    vmulps  %ymm8, %ymm0, %ymm0
    vminps  %ymm15, %ymm0, %ymm0         // intensity

    // Pack
    vmulps  %ymm12, %ymm0, %ymm1
    vmulps  %ymm13, %ymm0, %ymm2
    vmulps  %ymm14, %ymm0, %ymm0

    vbroadcastss .Lhalf(%rip), %ymm3
    vaddps  %ymm3, %ymm1, %ymm1
    vaddps  %ymm3, %ymm2, %ymm2
    vaddps  %ymm3, %ymm0, %ymm0

    vcvttps2dq %ymm1, %ymm1
    vcvttps2dq %ymm2, %ymm2
    vcvttps2dq %ymm0, %ymm0

    vpslld  $16, %ymm1, %ymm1
    vpslld  $8, %ymm2, %ymm2
    vpor    %ymm1, %ymm0, %ymm0
    vpor    %ymm2, %ymm0, %ymm0
    // Build 0xFF000000 in scratch ymm3; keep ymm15=1.0 for next iteration.
    vpcmpeqd %ymm3, %ymm3, %ymm3
    vpslld   $24, %ymm3, %ymm3
    vpor     %ymm3, %ymm0, %ymm0

    vmovups %ymm0, (%rcx)

    add     $32, %rdi
    add     $32, %rsi
    add     $32, %rdx
    add     $32, %rcx
    sub     $8, %r10d
    jnz     .Lloop

    vzeroupper
.Ldone:
    ret
SIZE(SYM(ksvgLightingDistantDiffuseRowAvx2))

.p2align 5
.globl SYM(ksvgLightingDistantDiffuseRowAvx2Linear)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx2Linear), @function)
SYM(ksvgLightingDistantDiffuseRowAvx2Linear):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test    %r8d, %r8d
    jz      .Llin_done

    // Load Params
    vbroadcastss .Lone(%rip), %ymm0
    vdivss  0(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm6           // ymm6 = 1/invDx
    vdivss  4(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm7           // ymm7 = 1/invDy

    vbroadcastss 8(%r9), %ymm8           // k
    vbroadcastss 12(%r9), %ymm9          // lx
    vbroadcastss 16(%r9), %ymm10         // ly
    vbroadcastss 20(%r9), %ymm11         // lz
    vbroadcastss 24(%r9), %ymm12         // lr
    vbroadcastss 28(%r9), %ymm13         // lg
    vbroadcastss 32(%r9), %ymm14         // lb
    // Fold surface scale into derivative scales; ymm15 becomes available.
    vbroadcastss 36(%r9), %ymm15         // ss
    vmulps  %ymm15, %ymm6, %ymm6         // ss / invDx
    vmulps  %ymm15, %ymm7, %ymm7         // ss / invDy
    vbroadcastss .Lone(%rip), %ymm15     // 1.0

    mov     %r8d, %r10d

.Llin_loop:
    // L2S_ARGB4 4,5,3,7 clobbers the low 128 bits of ymm6/ymm7 as scratch; reload them.
    vbroadcastss .Lone(%rip), %ymm0
    vdivss 0(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm6
    vdivss 4(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm7
    vbroadcastss 36(%r9), %ymm0
    vmulps %ymm0, %ymm6, %ymm6
    vmulps %ymm0, %ymm7, %ymm7

    vbroadcastss 8(%r9), %ymm8             // k (L2S clobbers ymm8 low half)
    vbroadcastss .Lone(%rip), %ymm15          // 1.0 (alpha-mask generation clobbers ymm15)
    vbroadcastss 12(%r9), %ymm9
    vbroadcastss 16(%r9), %ymm10
    vbroadcastss 20(%r9), %ymm11
    vbroadcastss 24(%r9), %ymm12
    vbroadcastss 28(%r9), %ymm13
    vbroadcastss 32(%r9), %ymm14

    // rowT alpha
    vmovups 0(%rdi), %ymm0
    vpsrld  $24, %ymm0, %ymm0        // hT_l
    vmovups 4(%rdi), %ymm1
    vpsrld  $24, %ymm1, %ymm1        // hT_m
    vmovups 8(%rdi), %ymm2
    vpsrld  $24, %ymm2, %ymm2        // hT_r

    // sumT = lT + 2*mT + rT
    vpaddd  %ymm1, %ymm1, %ymm3
    vpaddd  %ymm0, %ymm3, %ymm3
    vpaddd  %ymm2, %ymm3, %ymm3

    // dx_rel = rT - lT
    vpsubd  %ymm0, %ymm2, %ymm4

    // rowM alpha
    vmovups 0(%rsi), %ymm0
    vpsrld  $24, %ymm0, %ymm0        // hM_l
    vmovups 8(%rsi), %ymm2
    vpsrld  $24, %ymm2, %ymm2        // hM_r

    // dx_rel += 2*(rM - lM)
    vpsubd  %ymm0, %ymm2, %ymm5
    vpaddd  %ymm5, %ymm5, %ymm5
    vpaddd  %ymm5, %ymm4, %ymm4

    // rowB alpha
    vmovups 0(%rdx), %ymm0
    vpsrld  $24, %ymm0, %ymm0        // hB_l
    vmovups 4(%rdx), %ymm1
    vpsrld  $24, %ymm1, %ymm1        // hB_m
    vmovups 8(%rdx), %ymm2
    vpsrld  $24, %ymm2, %ymm2        // hB_r

    // sumB = lB + 2*mB + rB
    vpaddd  %ymm1, %ymm1, %ymm5
    vpaddd  %ymm0, %ymm5, %ymm5
    vpaddd  %ymm2, %ymm5, %ymm5

    // final dx_rel += rB - lB
    vpsubd  %ymm0, %ymm2, %ymm0
    vpaddd  %ymm0, %ymm4, %ymm4

    // Convert the final integer derivatives to float and apply scale once.
    vcvtdq2ps %ymm4, %ymm4
    vmulps  %ymm6, %ymm4, %ymm4       // dx (includes ss)
    vpsubd  %ymm3, %ymm5, %ymm5
    vcvtdq2ps %ymm5, %ymm5
    vmulps  %ymm7, %ymm5, %ymm5       // dy (includes ss)

    // n = (-dx, -dy, 1)
    vxorps  %ymm0, %ymm0, %ymm0
    vsubps  %ymm4, %ymm0, %ymm0         // nx
    vxorps  %ymm1, %ymm1, %ymm1
    vsubps  %ymm5, %ymm1, %ymm1         // ny

    vmulps  %ymm0, %ymm0, %ymm2
    vmulps  %ymm1, %ymm1, %ymm3
    vaddps  %ymm2, %ymm3, %ymm2         // nx² + ny²
    vaddps  %ymm15, %ymm2, %ymm2        // nLen^2

    vsqrtps %ymm2, %ymm3                // nLen
    vdivps  %ymm3, %ymm0, %ymm0         // nx
    vdivps  %ymm3, %ymm1, %ymm1         // ny
    vmovaps %ymm15, %ymm5
    vdivps  %ymm3, %ymm5, %ymm5         // nz

    vmulps  %ymm9, %ymm0, %ymm0
    vmulps  %ymm10, %ymm1, %ymm3
    vaddps  %ymm0, %ymm3, %ymm0         // nx*lx + ny*ly
    vmulps  %ymm11, %ymm5, %ymm5
    vaddps  %ymm0, %ymm5, %ymm0         // + nz*lz

    vxorps  %ymm4, %ymm4, %ymm4
    vmaxps  %ymm4, %ymm0, %ymm0
    vmulps  %ymm8, %ymm0, %ymm0
    vminps  %ymm15, %ymm0, %ymm0         // intensity

    // Pack
    vmulps  %ymm12, %ymm0, %ymm1
    vmulps  %ymm13, %ymm0, %ymm2
    vmulps  %ymm14, %ymm0, %ymm0

    vbroadcastss .Lhalf(%rip), %ymm3
    vaddps  %ymm3, %ymm1, %ymm1
    vaddps  %ymm3, %ymm2, %ymm2
    vaddps  %ymm3, %ymm0, %ymm0

    vcvttps2dq %ymm1, %ymm1
    vcvttps2dq %ymm2, %ymm2
    vcvttps2dq %ymm0, %ymm0

    vpslld  $16, %ymm1, %ymm1
    vpslld  $8, %ymm2, %ymm2
    vpor    %ymm1, %ymm0, %ymm0
    vpor    %ymm2, %ymm0, %ymm0
    // Build 0xFF000000 in scratch ymm3; keep ymm15=1.0 for next iteration.
    vpcmpeqd %ymm3, %ymm3, %ymm3
    vpslld   $24, %ymm3, %ymm3
    vpor     %ymm3, %ymm0, %ymm0

    subq    $32, %rsp
    vextracti128 $1, %ymm0, %xmm6
    movdqu  %xmm6, 16(%rsp)
    vpxor   %xmm15, %xmm15, %xmm15
    L2S_ARGB4 4,5,3,7
    movdqu  %xmm0, (%rsp)
    movdqu  16(%rsp), %xmm0
    L2S_ARGB4 4,5,3,7
    movdqu  (%rsp), %xmm1
    vinserti128 $1, %xmm0, %ymm1, %ymm0
    addq    $32, %rsp
    vmovups %ymm0, (%rcx)

    add     $32, %rdi
    add     $32, %rsi
    add     $32, %rdx
    add     $32, %rcx
    sub     $8, %r10d
    jnz     .Llin_loop

    vzeroupper
.Llin_done:
    ret
SIZE(SYM(ksvgLightingDistantDiffuseRowAvx2Linear))

RODATA
.p2align 4
.Lzero: .float 0.0,0.0,0.0,0.0
.Lone: .float 1.0,1.0,1.0,1.0
.Lhalf: .float 0.5,0.5,0.5,0.5
.Lthree_halves: .float 1.5,1.5,1.5,1.5
.LmaskAlphaShifted: .long 0xff000000,0xff000000,0xff000000,0xff000000,0xff000000,0xff000000,0xff000000,0xff000000
.L_exact_low16: .byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.L_base_lut: .byte 0,72,100,121,137,152,165,177,188,198,208,217,225,233,241,248
.L_slope_lut: .byte 0,58,41,31,31,27,24,22,20,19,16,15,16,16,15,16
.L_rounding: .short 16,16,16,16,16,16,16,16
.L_nibble_mask: .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.L_group_mask: .byte 31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31
.L_low3_mask: .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
.L_one_byte: .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.L_group16: .byte 16,16,16,16,16,16,16,16,16,16,16,16,16,16,16,16
.L_onehot_lut: .byte 1,2,4,8,16,32,64,128,1,2,4,8,16,32,64,128
.L_correction_lo: .byte 0,0,7,241,5,0,7,0,0,240,0,194,0,64,0,1
.L_correction_hi: .byte 16,0,0,0,42,0,1,0,0,0,0,168,0,80,128,170
.L_alpha_mask: .long 0xff000000,0xff000000,0xff000000,0xff000000
.L_rgb_mask: .long 0x00ffffff,0x00ffffff,0x00ffffff,0x00ffffff
