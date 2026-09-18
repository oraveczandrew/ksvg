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

/*
 * Description:
 *   Entry prologue of the distant-diffuse kernels: broadcasts the
 *   DistantLightingParams struct (invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss)
 *   via movss+shufps, forms 1/invDx and 1/invDy via divss, and folds the
 *   surface scale ss into the derivative scales. Legacy SSE mnemonics.
 *   Matches the pre-existing distant-diffuse entry blocks bit-for-bit
 *   (same FP division order).
 *
 * Inputs:
 *   \pb           = GPR pointing at DistantLightingParams (0 -> invDx,
 *                   4 -> invDy, 8 -> k, 12/16/20 -> lx/ly/lz, 24/28/32 ->
 *                   lr/lg/lb, 36 -> ss)
 *   \one          = symbol of the 1.0 literal (e.g. .Lone)
 *
 * Output:
 *   \idx, \idy    = 1/invDx, 1/invDy folded with ss
 *   \k, \lx, \ly, \lz, \lr, \lg, \lb = broadcast params
 *   \ss_one       = ss folded into idx/idy (dead afterwards; NOT reloaded
 *                   to 1.0 — callers use memory .Lone for the clamp)
 *
 * Clobbers:
 *   \t0
 *   \idx, \idy, \k, \lx, \ly, \lz, \lr, \lg, \lb, \ss_one (written)
 */
.macro DISTANT_DIFFUSE_PARAMS pb, one, t0, idx, idy, k, lx, ly, lz, lr, lg, lb, ss_one
    movss     \one(%rip), \t0
    divss     0(\pb), \t0
    shufps    $0, \t0, \t0
    movaps    \t0, \idx
    movss     \one(%rip), \t0
    divss     4(\pb), \t0
    shufps    $0, \t0, \t0
    movaps    \t0, \idy
    movss     8(\pb), \k
    shufps    $0, \k, \k
    movss     12(\pb), \lx
    shufps    $0, \lx, \lx
    movss     16(\pb), \ly
    shufps    $0, \ly, \ly
    movss     20(\pb), \lz
    shufps    $0, \lz, \lz
    movss     24(\pb), \lr
    shufps    $0, \lr, \lr
    movss     28(\pb), \lg
    shufps    $0, \lg, \lg
    movss     32(\pb), \lb
    shufps    $0, \lb, \lb
    movss     36(\pb), \ss_one
    shufps    $0, \ss_one, \ss_one
    mulps     \ss_one, \idx
    mulps     \ss_one, \idy
.endm

/*
 * Description:
 *   3x3 Sobel window over three alpha rows: extracts the alpha byte of each
 *   lane (psrld $24), computes sumT = lT+2*mT+rT and sumB = lB+2*mB+rB via
 *   an inlined integer 1:2:1 sum (movaps + 3x paddd; legacy SSE has no
 *   3-operand paddd), and accumulates the integer x-derivative
 *   dx_rel = rT-lT + 2*(rM-lM) + rB-lB. Matches the pre-existing
 *   distant-diffuse window block bit-for-bit, including the middle row loading
 *   only its l and r lanes (the m lane is unused by the derivative).
 *
 * Inputs:
 *   \srcT, \srcM, \srcB  = three row base addresses (top/mid/bottom)
 *   \a, \b, \c           = scratch xmm registers for the current row's
 *                          l/m/r alpha lanes (clobbered as rows are loaded)
 *   \sumT, \sumB         = output registers for the 1:2:1 sums
 *   \dx                  = output/accumulator register for dx_rel
 *   \tmp                 = scratch for 2*(rM-lM); may alias \sumB (the
 *                          distant-diffuse kernels use %xmm5 for both)
 *
 * Output:
 *   \sumT, \sumB, \dx set as described above.
 *
 * Clobbers:
 *   \a, \b, \c (row lane scratch, in-place and discarded)
 *   \tmp
 *   \sumT, \sumB, \dx   (written, not preserved)
 */
.macro SOBEL_SUMS_DX srcT, srcM, srcB, a, b, c, sumT, dx, sumB, tmp
    movups    0(\srcT), \a
    psrld     $24, \a
    movups    4(\srcT), \b
    psrld     $24, \b
    movups    8(\srcT), \c
    psrld     $24, \c
    movaps    \b, \sumT
    paddd     \b, \sumT
    paddd     \a, \sumT
    paddd     \c, \sumT
    movaps    \c, \dx
    psubd     \a, \dx
    movups    0(\srcM), \a
    psrld     $24, \a
    movups    8(\srcM), \c
    psrld     $24, \c
    movaps    \c, \tmp
    psubd     \a, \tmp
    paddd     \tmp, \tmp
    paddd     \tmp, \dx
    movups    0(\srcB), \a
    psrld     $24, \a
    movups    4(\srcB), \b
    psrld     $24, \b
    movups    8(\srcB), \c
    psrld     $24, \c
    movaps    \b, \sumB
    paddd     \b, \sumB
    paddd     \a, \sumB
    paddd     \c, \sumB
    psubd     \a, \c
    paddd     \c, \dx
.endm

/*
 * Description:
 *   Normalizes the surface normal from derivatives scaled into dx/dy:
 *   nx = -dx; ny = -dy; nz = 1; len = sqrt(nx^2 + ny^2 + nz^2); then divides
 *   all three components by len (divps path). Legacy SSE mnemonics.
 *   Matches the pre-existing distant-diffuse normalize block bit-for-bit.
 *
 * Inputs:
 *   \dx, \dy       = derivative vectors
 *   \one           = symbol of the 1.0 literal (e.g. .Lone)
 *
 * Output:
 *   \nx, \ny, \nz  = normalized normal components (|n| = 1)
 *
 * Clobbers:
 *   \nx, \ny, \nz     (written)
 *   \sq0, \sq1        (squares and length)
 *   \nz may alias \dy (dy is consumed building ny, nz written last;
 *   the distant-diffuse kernels use %xmm5 for both)
 */
.macro NORM_NEGXY_DIV dx, dy, one, nx, ny, nz, sq0, sq1
    xorps     \nx, \nx
    subps     \dx, \nx
    xorps     \ny, \ny
    subps     \dy, \ny
    movaps    \nx, \sq0
    mulps     \nx, \sq0
    movaps    \ny, \sq1
    mulps     \ny, \sq1
    addps     \sq1, \sq0
    addps     \one(%rip), \sq0
    sqrtps    \sq0, \sq1
    divps     \sq1, \nx
    divps     \sq1, \ny
    movaps    \one(%rip), \nz
    divps     \sq1, \nz
.endm

/*
 * Description:
 *   Three-term dot product of the surface normal (nx, ny, nz) with the light
 *   direction (lx, ly, lz), clamped to [0, 1] with the k scale applied between
 *   the clamps: i = min(max(nx*lx + ny*ly + nz*lz, 0) * k, 1). The clamp
 *   bounds come from memory operands (\zero/\one are literal symbols).
 *   Legacy SSE mnemonics. FP operation order matches the pre-existing
 *   distant-diffuse kernels bit-for-bit (nx accumulates).
 *
 * Inputs:
 *   \nx, \ny, \nz = normal components (float vectors)
 *   \lx, \ly, \lz = light direction components (float vectors, preserved)
 *   \k            = intensity scale (float vector, preserved)
 *   \zero, \one   = symbols of the 0.0 / 1.0 literals (e.g. .Lzero, .Lone)
 *
 * Output:
 *   \nx          = clamped intensity
 *
 * Clobbers:
 *   \nx  (in-place: holds nx*lx, then the dot, then the intensity)
 *   \nz  (in-place: holds nz*lz, then discarded)
 *   (\ny preserved)
 */
.macro DOT3_K_CLAMP nx, ny, nz, lx, ly, lz, k, zero, one
    mulps     \lx, \nx
    mulps     \ly, \ny
    addps     \ny, \nx
    mulps     \lz, \nz
    addps     \nz, \nx
    maxps     \zero(%rip), \nx
    mulps     \k, \nx
    minps     \one(%rip), \nx
.endm

/*
 * Description:
 *   Scales an intensity by three color factors, rounds half-up, truncates to
 *   int32, and packs into 0xFFRRGGBB (ARGB with full alpha): R<<16 | G<<8 | B
 *   then ORs the alpha mask literal. No per-channel clamp (the caller has
 *   already clamped the intensity to [0, 1]); matches the distant-diffuse
 *   pack block bit-for-bit. Legacy SSE mnemonics.
 *
 * Inputs:
 *   \i            = clamped intensity (float)
 *   \lr, \lg, \lb = per-channel color factors (float vectors, preserved)
 *   \half         = symbol of the 0.5 literal (e.g. .Lhalf)
 *   \alpha        = symbol of the 0xFF000000 mask literal
 *
 * Output:
 *   \i            = packed 0xFFRRGGBB pixel (int32 lanes)
 *
 * Clobbers:
 *   \i                                   (in-place: holds B then the result)
 *   \r, \g
 *   Depends on the passed \half / \alpha literals in the caller's RODATA.
 */
.macro PACK_RGB i, lr, lg, lb, r, g, half, alpha
    movaps    \i, \r
    mulps     \lr, \r
    movaps    \i, \g
    mulps     \lg, \g
    mulps     \lb, \i
    addps     \half(%rip), \r
    addps     \half(%rip), \g
    addps     \half(%rip), \i
    cvttps2dq \r, \r
    cvttps2dq \g, \g
    cvttps2dq \i, \i
    pslld     $16, \r
    pslld     $8, \g
    por       \r, \i
    por       \g, \i
    por       \alpha(%rip), \i
.endm

.text
.p2align 5

/*
 * void ksvgLightingDistantDiffuseRowSsse3(
 *     const jint* srcT, const jint* srcM, const jint* srcB,
 *     jint* dst, jint count, const LightingParams* params);
 *
 * x86-64 System V ABI:
 *   rdi = srcT, rsi = srcM, rdx = srcB, rcx = dst, r8d = count, r9 = params
 */
.globl SYM(ksvgLightingDistantDiffuseRowSsse3)
TYPE(SYM(ksvgLightingDistantDiffuseRowSsse3), @function)
SYM(ksvgLightingDistantDiffuseRowSsse3):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test      %r8d, %r8d
    jz        .Ldone

    push      %rbx
    push      %rbp

    // Load Params
    DISTANT_DIFFUSE_PARAMS %r9, .Lone, %xmm0, %xmm6, %xmm7, %xmm8, %xmm9, %xmm10, %xmm11, %xmm12, %xmm13, %xmm14, %xmm15

    mov       %r8d, %r10d

.Lloop:
    // 3x3 Sobel window: sumT, dx_rel, sumB.
    SOBEL_SUMS_DX %rdi, %rsi, %rdx, %xmm0, %xmm1, %xmm2, %xmm3, %xmm4, %xmm5, %xmm5

    // Convert final integer derivatives to float and apply scale once.
    cvtdq2ps  %xmm4, %xmm4
    mulps     %xmm6, %xmm4  // dx (includes ss)
    psubd     %xmm3, %xmm5
    cvtdq2ps  %xmm5, %xmm5
    mulps     %xmm7, %xmm5  // dy (includes ss)

    // n = (-dx, -dy, 1) / |(-dx,-dy,1)|.
    NORM_NEGXY_DIV %xmm4, %xmm5, .Lone, %xmm0, %xmm1, %xmm5, %xmm2, %xmm3

    // Scalar equivalent: intensity = min(k * max(nx*lx + ny*ly + nz*lz, 0), 1)
    DOT3_K_CLAMP %xmm0, %xmm1, %xmm5, %xmm9, %xmm10, %xmm11, %xmm8, .Lzero, .Lone

    // Pack
    PACK_RGB %xmm0, %xmm12, %xmm13, %xmm14, %xmm1, %xmm2, .Lhalf, .LmaskAlphaShifted

    movups    %xmm0, (%rcx)

    add       $16, %rdi
    add       $16, %rsi
    add       $16, %rdx
    add       $16, %rcx
    sub       $4, %r10d
    jnz       .Lloop

    pop       %rbp
    pop       %rbx
.Ldone:
    ret

SIZE(SYM(ksvgLightingDistantDiffuseRowSsse3))

.p2align 5

/*
 * void ksvgLightingDistantDiffuseRowSsse3Linear(
 *     const jint* srcT, const jint* srcM, const jint* srcB,
 *     jint* dst, jint count, const LightingParams* params,
 *     const uint8_t* linearToSrgb);
 *
 * x86-64 System V ABI:
 *   rdi = srcT, rsi = srcM, rdx = srcB, rcx = dst, r8d = count, r9 = params
 *   stack: linearToSrgb ([rsp+8] at entry)
 */
.globl SYM(ksvgLightingDistantDiffuseRowSsse3Linear)
TYPE(SYM(ksvgLightingDistantDiffuseRowSsse3Linear), @function)
SYM(ksvgLightingDistantDiffuseRowSsse3Linear):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test      %r8d, %r8d
    jz        .Llin_done

    push      %rbx
    push      %rbp

    // Load Params
    DISTANT_DIFFUSE_PARAMS %r9, .Lone, %xmm0, %xmm6, %xmm7, %xmm8, %xmm9, %xmm10, %xmm11, %xmm12, %xmm13, %xmm14, %xmm15

    mov       %r8d, %r10d

.Llin_loop:
    // 3x3 Sobel window: sumT, dx_rel, sumB.
    SOBEL_SUMS_DX %rdi, %rsi, %rdx, %xmm0, %xmm1, %xmm2, %xmm3, %xmm4, %xmm5, %xmm5

    // Convert final integer derivatives to float and apply scale once.
    cvtdq2ps  %xmm4, %xmm4
    mulps     %xmm6, %xmm4  // dx (includes ss)
    psubd     %xmm3, %xmm5
    cvtdq2ps  %xmm5, %xmm5
    mulps     %xmm7, %xmm5  // dy (includes ss)

    // n = (-dx, -dy, 1) / |(-dx,-dy,1)|.
    NORM_NEGXY_DIV %xmm4, %xmm5, .Lone, %xmm0, %xmm1, %xmm5, %xmm2, %xmm3

    // Scalar equivalent: intensity = min(k * max(nx*lx + ny*ly + nz*lz, 0), 1)
    DOT3_K_CLAMP %xmm0, %xmm1, %xmm5, %xmm9, %xmm10, %xmm11, %xmm8, .Lzero, .Lone

    // Pack
    PACK_RGB %xmm0, %xmm12, %xmm13, %xmm14, %xmm1, %xmm2, .Lhalf, .LmaskAlphaShifted

    // Inline linear-light -> sRGB amortized L2S conversion.
    // Exact same algorithm as the established x86-64 SSSE3 L2S kernel.
    movdqa    %xmm0, %xmm1  // high nibble
    psrlw     $4, %xmm1
    pand      .Ll2s_nibble_mask(%rip), %xmm1
    movdqa    %xmm0, %xmm2  // low nibble (also retained for exact-low16)
    pand      .Ll2s_nibble_mask(%rip), %xmm2
    pxor      %xmm6, %xmm6  // zero

    movdqa    .Ll2s_base_lut(%rip), %xmm3
    pshufb    %xmm1, %xmm3
    movdqa    .Ll2s_slope_lut(%rip), %xmm4
    pshufb    %xmm1, %xmm4

    movdqa    %xmm4, %xmm5
    punpcklbw %xmm6, %xmm5
    movdqa    %xmm2, %xmm7
    punpcklbw %xmm6, %xmm7
    pmaddubsw %xmm7, %xmm5

    movdqa    %xmm4, %xmm7
    punpckhbw %xmm6, %xmm7
    movdqa    %xmm2, %xmm4
    punpckhbw %xmm6, %xmm4
    pmaddubsw %xmm4, %xmm7

    paddw     .Ll2s_rounding(%rip), %xmm5
    psrlw     $5, %xmm5
    paddw     .Ll2s_rounding(%rip), %xmm7
    psrlw     $5, %xmm7
    packuswb  %xmm7, %xmm5
    paddb     %xmm3, %xmm5

    // Correction bitset: use the original packed RGB input (xmm0).
    movdqa    %xmm0, %xmm3
    psrlw     $3, %xmm3
    pand      .Ll2s_group_mask(%rip), %xmm3
    movdqa    %xmm3, %xmm4
    psubb     .Ll2s_group16(%rip), %xmm4
    movdqa    .Ll2s_correction_hi(%rip), %xmm7
    pshufb    %xmm4, %xmm7
    movdqa    %xmm3, %xmm4
    psrlw     $4, %xmm4
    pand      .Ll2s_one_byte(%rip), %xmm4
    psllw     $7, %xmm4
    por       %xmm3, %xmm4
    movdqa    .Ll2s_correction_lo(%rip), %xmm3
    pshufb    %xmm4, %xmm3
    por       %xmm7, %xmm3

    movdqa    %xmm2, %xmm4
    pand      .Ll2s_low3_mask(%rip), %xmm4
    movdqa    .Ll2s_onehot_lut(%rip), %xmm7
    pshufb    %xmm4, %xmm7
    pand      %xmm7, %xmm3
    pminub    .Ll2s_one_byte(%rip), %xmm3
    psubb     %xmm3, %xmm5

    movdqa    .Ll2s_exact_low16(%rip), %xmm3
    pshufb    %xmm2, %xmm3
    pcmpeqb   %xmm6, %xmm1
    pand      %xmm1, %xmm3
    pandn     %xmm5, %xmm1
    por       %xmm3, %xmm1

    // Diffuse output alpha is always 255.
    pand      .Ll2s_rgb_mask(%rip), %xmm1
    por       .LmaskAlphaShifted(%rip), %xmm1
    movdqu    %xmm1, (%rcx)
    add       $16, %rdi
    add       $16, %rsi
    add       $16, %rdx
    add       $16, %rcx
    sub       $4, %r10d
    jnz       .Llin_loop

    pop       %rbp
    pop       %rbx
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
.Lzero: .float 0.0, 0.0, 0.0, 0.0
.Lone: .float 1.0, 1.0, 1.0, 1.0
.Lhalf: .float 0.5, 0.5, 0.5, 0.5
.Lthree_halves: .float 1.5, 1.5, 1.5, 1.5
.LmaskAlphaShifted: .long 0xFF000000, 0xFF000000, 0xFF000000, 0xFF000000
