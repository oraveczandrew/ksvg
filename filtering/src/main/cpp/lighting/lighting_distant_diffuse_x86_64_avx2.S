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
 *   Amortized linear->sRGB conversion for four ARGB pixels in xmm0: exact
 *   value for the low nibbles (0..15) via .L_exact_low16, otherwise nibble
 *   base/slope interpolation rounded to +16>>5 plus the correction bitset,
 *   preserving the source alpha. Same arithmetic/table path as the validated
 *   standalone SSSE3 unlinearize kernel.
 *
 * Inputs:
 *   \sh4, \sh5, \sh3, \sh7  = shift amounts (call sites pass 4,5,3,7)
 *   %xmm0                   = four packed ARGB pixels (in-place)
 *
 * Output:
 *   %xmm0                   = four packed sRGB ARGB pixels
 *
 * Clobbers:
 *   %xmm0      (in-place)
 *   %xmm1..%xmm8
 *   (these are the full 128-bit lanes; on kernels that keep vectors in the
 *   upper ymm halves of ymm6/ymm7/ymm8 the caller must reload them after the
 *   call — the linear distant-diffuse kernel does exactly that)
 */
.macro L2S_ARGB4 sh4, sh5, sh3, sh7
    movdqa       %xmm0, %xmm8
    pand         .L_alpha_mask(%rip), %xmm8
    pxor         %xmm7, %xmm7

    movdqa       %xmm0, %xmm1
    psrlw        $\sh4, %xmm1
    pand         .L_nibble_mask(%rip), %xmm1
    movdqa       %xmm0, %xmm2
    pand         .L_nibble_mask(%rip), %xmm2

    movdqa       .L_base_lut(%rip), %xmm3
    pshufb       %xmm1, %xmm3
    movdqa       .L_slope_lut(%rip), %xmm4
    pshufb       %xmm1, %xmm4

    movdqa       %xmm4, %xmm5
    punpcklbw    %xmm7, %xmm5
    movdqa       %xmm2, %xmm6
    punpcklbw    %xmm7, %xmm6
    pmaddubsw    %xmm6, %xmm5

    movdqa       %xmm4, %xmm6
    punpckhbw    %xmm7, %xmm6
    movdqa       %xmm2, %xmm4
    punpckhbw    %xmm7, %xmm4
    pmaddubsw    %xmm4, %xmm6

    paddw        .L_rounding(%rip), %xmm5
    psrlw        $\sh5, %xmm5
    paddw        .L_rounding(%rip), %xmm6
    psrlw        $\sh5, %xmm6
    packuswb     %xmm6, %xmm5
    paddb        %xmm3, %xmm5

    movdqa       %xmm0, %xmm3
    psrlw        $\sh3, %xmm3
    pand         .L_group_mask(%rip), %xmm3
    movdqa       %xmm3, %xmm4
    psubb        .L_group16(%rip), %xmm4
    movdqa       .L_correction_hi(%rip), %xmm6
    pshufb       %xmm4, %xmm6
    movdqa       %xmm3, %xmm4
    psrlw        $\sh4, %xmm4
    pand         .L_one_byte(%rip), %xmm4
    psllw        $\sh7, %xmm4
    por          %xmm3, %xmm4
    movdqa       .L_correction_lo(%rip), %xmm3
    pshufb       %xmm4, %xmm3
    por          %xmm6, %xmm3
    movdqa       %xmm0, %xmm4
    pand         .L_low3_mask(%rip), %xmm4
    movdqa       .L_onehot_lut(%rip), %xmm6
    pshufb       %xmm4, %xmm6
    pand         %xmm6, %xmm3
    pminub       .L_one_byte(%rip), %xmm3
    psubb        %xmm3, %xmm5

    movdqa       .L_exact_low16(%rip), %xmm3
    pshufb       %xmm2, %xmm3
    pcmpeqb      %xmm7, %xmm1
    pand         %xmm1, %xmm3
    pandn        %xmm5, %xmm1
    por          %xmm3, %xmm1

    pand         .L_rgb_mask(%rip), %xmm1
    por          %xmm8, %xmm1
    movdqa       %xmm1, %xmm0
.endm

/*
 * Description:
 *   Weighted row/column sum a + 2b + c over three integer vectors
 *   (e.g. the 1:2:1 Sobel row-sum). Emits vpaddd b,b,dst; vpaddd a,dst,dst;
 *   vpaddd c,dst,dst so dst = a + 2*b + c, matching the pre-existing
 *   distant-diffuse kernels bit-for-bit (integer add is associative, so the
 *   accumulation order into dst is arbitrary; keep this exact form anyway).
 *
 * Inputs:
 *   \v0, \v1, \v2  = three 256-bit integer vectors (l/m/r or l/b/r);
 *                    \v1 is the doubled middle term. All preserved.
 *   \dst           = distinct destination/accumulator ymm register.
 *
 * Output:
 *   \dst = \v0 + 2*\v1 + \v2
 *
 * Clobbers:
 *   \dst
 *
 * Example: SUM121 %ymm0, %ymm1, %ymm2, %ymm3 computes sumT from lT/mT/rT lanes.
 */
.macro SUM121 v0, v1, v2, dst
    vpaddd       \v1, \v1, \dst
    vpaddd       \v0, \dst, \dst
    vpaddd       \v2, \dst, \dst
.endm

/*
 * Description:
 *   3x3 Sobel window over three alpha rows: extracts the alpha byte of each
 *   lane (vpsrld $24), computes sumT = lT+2*mT+rT and sumB = lB+2*mB+rB via
 *   SUM121, and accumulates the integer x-derivative
 *   dx_rel = rT-lT + 2*(rM-lM) + rB-lB. Matches the pre-existing
 *   distant-diffuse window block bit-for-bit, including the middle row loading
 *   only its l and r lanes (the m lane is unused by the derivative).
 *
 * Inputs:
 *   \srcT, \srcM, \srcB  = three row base addresses (top/mid/bottom)
 *   \a, \b, \c           = scratch ymm registers for the current row's
 *                          l/m/r alpha lanes (clobbered as rows are loaded)
 *   \sumT, \sumB         = output registers for the 1:2:1 sums
 *   \dx                  = output/accumulator register for dx_rel
 *   \tmp                 = scratch for 2*(rM-lM); may alias \sumB (the
 *                          distant-diffuse kernels use %ymm5 for both)
 *
 * Output:
 *   \sumT, \sumB, \dx set as described above.
 *
 * Clobbers:
 *   \a, \b, \c (row lan scratch, in-place and discarded)
 *   \tmp
 *   \sumT, \sumB, \dx   (written, not preserved)
 */
.macro SOBEL_SUMS_DX srcT, srcM, srcB, a, b, c, sumT, dx, sumB, tmp
    vmovups      0(\srcT), \a
    vpsrld       $24, \a, \a
    vmovups      4(\srcT), \b
    vpsrld       $24, \b, \b
    vmovups      8(\srcT), \c
    vpsrld       $24, \c, \c
    SUM121 \a, \b, \c, \sumT
    vpsubd       \a, \c, \dx
    vmovups      0(\srcM), \a
    vpsrld       $24, \a, \a
    vmovups      8(\srcM), \c
    vpsrld       $24, \c, \c
    vpsubd       \a, \c, \tmp
    vpaddd       \tmp, \tmp, \tmp
    vpaddd       \tmp, \dx, \dx
    vmovups      0(\srcB), \a
    vpsrld       $24, \a, \a
    vmovups      4(\srcB), \b
    vpsrld       $24, \b, \b
    vmovups      8(\srcB), \c
    vpsrld       $24, \c, \c
    SUM121 \a, \b, \c, \sumB
    vpsubd       \a, \c, \a
    vpaddd       \a, \dx, \dx
.endm

/*
 * Description:
 *   Normalizes the surface normal from integer derivatives scaled into dx/dy:
 *   nx = -dx; ny = -dy; nz = 1; len = sqrt(nx^2 + ny^2 + nz^2); then divides
 *   all three components by len (vdivps path, distinct from the reciprocal-mul
 *   NORM_INV). Matches the pre-existing distant-diffuse normalize block
 *   bit-for-bit.
 *
 * Inputs:
 *   \dx, \dy       = float derivative vectors
 *   \one           = broadcast 1.0 constant vector
 *
 * Output:
 *   \nx, \ny, \nz  = normalized normal components (|n| = 1)
 *
 * Clobbers:
 *   \nx, \ny, \nz     (written)
 *   \scratch0, \scratch1   (squares and sqrt temp)
 *   \dx, \dy, \one referents may be reused/aliased after the call as the
 *   macro reads them; in the distant-diffuse kernels \nz aliases \dy (dy is
 *   consumed in step 3, nz written last) and \one = %ymm15 is untouched.
 */
.macro NORM_NEGXY_DIV dx, dy, one, nx, ny, nz, scratch0, scratch1
    vxorps       \nx, \nx, \nx
    vsubps       \dx, \nx, \nx  // nx = -dx
    vxorps       \ny, \ny, \ny
    vsubps       \dy, \ny, \ny  // ny = -dy
    vmulps       \nx, \nx, \scratch0  // nx^2
    vmulps       \ny, \ny, \scratch1  // ny^2
    vaddps       \scratch0, \scratch1, \scratch0  // nx^2 + ny^2
    vaddps       \one, \scratch0, \scratch0  // + 1
    vsqrtps      \scratch0, \scratch1  // len
    vdivps       \scratch1, \nx, \nx
    vdivps       \scratch1, \ny, \ny
    vmovaps      \one, \nz
    vdivps       \scratch1, \nz, \nz
.endm

/*
 * Description:
 *   Scales an intensity by three color factors, rounds half-up, truncates to
 *   int32, and packs into 0xFFRRGGBB (ARGB with full alpha): R<<16 | G<<8 | B
 *   then ORs the alpha byte built as 0xFF000000. No per-channel clamp (the
 *   caller has already clamped the intensity to [0, 1]); matches the
 *   distant-diffuse pack block bit-for-bit.
 *
 * Inputs:
 *   \i            = clamped intensity (float)
 *   \lr, \lg, \lb = per-channel color factors (float; may be memory operands)
 *   \half         = symbol of the 0.5 broadcast literal (e.g. .Lhalf)
 *
 * Output:
 *   \i            = packed 0xFFRRGGBB pixel (int32 lanes)
 *
 * Clobbers:
 *   \i                                   (in-place: holds B then the result)
 *   \r, \g, \tmp
 *   Depends on the passed \half literal in the caller's RODATA.
 *
 * Example: PACK_RGB %ymm0, %ymm12, %ymm13, %ymm14, %ymm1, %ymm2, %ymm3, .Lhalf
 */
.macro PACK_RGB i, lr, lg, lb, r, g, tmp, half
    vmulps       \lr, \i, \r  // R = i * lr
    vmulps       \lg, \i, \g  // G = i * lg
    vmulps       \lb, \i, \i  // B = i * lb
    vbroadcastss \half(%rip), \tmp
    vaddps       \tmp, \r, \r  // R + 0.5
    vaddps       \tmp, \g, \g  // G + 0.5
    vaddps       \tmp, \i, \i  // B + 0.5
    vcvttps2dq   \r, \r
    vcvttps2dq   \g, \g
    vcvttps2dq   \i, \i
    vpslld       $16, \r, \r
    vpslld       $8, \g, \g
    vpor         \r, \i, \i  // B | (G << 8)
    vpor         \g, \i, \i  // ... | (R << 16)
    vpcmpeqd     \tmp, \tmp, \tmp  // 0xFFFFFFFF
    vpslld       $24, \tmp, \tmp  // 0xFF000000
    vpor         \tmp, \i, \i
.endm

/*
 * Description:
 *   Three-term dot product of the surface normal (nx, ny, nz) with the light
 *   direction (lx, ly, lz), clamped to [0, 1] with the k scale applied between
 *   the clamps: i = min(max(nx*lx + ny*ly + nz*lz, 0) * k, 1). The FP operation
 *   order (including which operand accumulates) matches the pre-existing
 *   distant-diffuse kernels bit-for-bit: nx accumulates (lx then ly then lz
 *   products), and the zero bound is materialized with vxorps into \zero.
 *
 * Inputs:
 *   \nx, \ny, \nz = normal components (float vectors)
 *   \lx, \ly, \lz = light direction components (float vectors, preserved)
 *   \k            = intensity scale (float vector, preserved)
 *   \one          = broadcast 1.0 (preserved)
 *   \tmp          = scratch for the ny*ly product
 *   \zero         = scratch materialized to +0.0 via vxorps
 *
 * Output:
 *   \nx          = clamped intensity
 *
 * Clobbers:
 *   \nx  (in-place: holds nx*lx, then the dot, then the intensity)
 *   \nz  (in-place: holds nz*lz, then discarded)
 *   \tmp, \zero
 */
.macro DOT3_K_CLAMP nx, ny, nz, lx, ly, lz, k, one, tmp, zero
    vmulps       \lx, \nx, \nx
    vmulps       \ly, \ny, \tmp
    vaddps       \nx, \tmp, \nx
    vmulps       \lz, \nz, \nz
    vaddps       \nx, \nz, \nx
    vxorps       \zero, \zero, \zero
    vmaxps       \zero, \nx, \nx
    vmulps       \k, \nx, \nx
    vminps       \one, \nx, \nx
.endm

/*
 * Description:
 *   Entry prologue of the distant-diffuse kernels: broadcasts the
 *   DistantLightingParams struct (invDx, invDy, k, lx, ly, lz, lr, lg, lb, ss)
 *   into vectors, forms 1/invDx and 1/invDy via vdivss, and folds the surface
 *   scale ss into the derivative scales. The ss holder is reused for the 1.0
 *   broadcast last. Matches the pre-existing distant-diffuse entry blocks
 *   bit-for-bit (same FP division order).
 *
 * Inputs:
 *   \pb           = GPR pointing at DistantLightingParams (0 -> invDx,
 *                   4 -> invDy, 8 -> k, 12/16/20 -> lx/ly/lz, 24/28/32 ->
 *                   lr/lg/lb, 36 -> ss)
 *   \one          = symbol of the 1.0 broadcast literal (e.g. .Lone)
 *
 * Output:
 *   \idx, \idy    = 1/invDx, 1/invDy folded with ss
 *   \k, \lx, \ly, \lz, \lr, \lg, \lb = broadcast params
 *   \ss_one       = broadcast 1.0 (held ss transiently)
 *
 * Clobbers:
 *   \t0, \t1 (including their \t0x, \t1x low lanes)
 *   \idx, \idy, \k, \lx, \ly, \lz, \lr, \lg, \lb, \ss_one (written)
 *
 * Example: DISTANT_DIFFUSE_PARAMS %r9, .Lone, %ymm0, %ymm1, %xmm0, %xmm1,
 *   %ymm6, %ymm7, %ymm8, %ymm9, %ymm10, %ymm11, %ymm12, %ymm13, %ymm14, %ymm15
 */
.macro DISTANT_DIFFUSE_PARAMS pb, one, t0, t1, t0x, t1x, idx, idy, k, lx, ly, lz, lr, lg, lb, ss_one
    vbroadcastss \one(%rip), \t0
    vdivss       0(\pb), \t0x, \t1x
    vbroadcastss \t1x, \idx
    vdivss       4(\pb), \t0x, \t1x
    vbroadcastss \t1x, \idy
    vbroadcastss 8(\pb), \k
    vbroadcastss 12(\pb), \lx
    vbroadcastss 16(\pb), \ly
    vbroadcastss 20(\pb), \lz
    vbroadcastss 24(\pb), \lr
    vbroadcastss 28(\pb), \lg
    vbroadcastss 32(\pb), \lb
    vbroadcastss 36(\pb), \ss_one
    vmulps       \ss_one, \idx, \idx
    vmulps       \ss_one, \idy, \idy
    vbroadcastss \one(%rip), \ss_one
.endm

.text
.p2align 5

/*
 * void ksvgLightingDistantDiffuseRowAvx2(
 *     const jint* srcT, const jint* srcM, const jint* srcB,
 *     jint* dst, jint count, const LightingParams* params);
 *
 * x86-64 System V ABI:
 *   rdi = srcT, rsi = srcM, rdx = srcB, rcx = dst, r8d = count, r9 = params
 */
.globl SYM(ksvgLightingDistantDiffuseRowAvx2)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx2), @function)
SYM(ksvgLightingDistantDiffuseRowAvx2):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test         %r8d, %r8d
    jz           .Ldone

    // Load Params
    DISTANT_DIFFUSE_PARAMS %r9, .Lone, %ymm0, %ymm1, %xmm0, %xmm1, %ymm6, %ymm7, %ymm8, %ymm9, %ymm10, %ymm11, %ymm12, %ymm13, %ymm14, %ymm15

    mov          %r8d, %r10d

.Lloop:
    // 3x3 Sobel window: sumT, dx_rel, sumB
    SOBEL_SUMS_DX %rdi, %rsi, %rdx, %ymm0, %ymm1, %ymm2, %ymm3, %ymm4, %ymm5, %ymm5

    // Convert the final integer derivatives to float and apply scale once.
    vcvtdq2ps    %ymm4, %ymm4
    vmulps       %ymm6, %ymm4, %ymm4  // dx (includes ss)
    vpsubd       %ymm3, %ymm5, %ymm5
    vcvtdq2ps    %ymm5, %ymm5
    vmulps       %ymm7, %ymm5, %ymm5  // dy (includes ss)

    // n = (-dx, -dy, 1) / |(-dx,-dy,1)|
    NORM_NEGXY_DIV %ymm4, %ymm5, %ymm15, %ymm0, %ymm1, %ymm5, %ymm2, %ymm3

    // Scalar equivalent: intensity = min(k * max(nx*lx + ny*ly + nz*lz, 0), 1)
    DOT3_K_CLAMP %ymm0, %ymm1, %ymm5, %ymm9, %ymm10, %ymm11, %ymm8, %ymm15, %ymm3, %ymm4

    // Pack
    PACK_RGB %ymm0, %ymm12, %ymm13, %ymm14, %ymm1, %ymm2, %ymm3, .Lhalf

    vmovups      %ymm0, (%rcx)

    add          $32, %rdi
    add          $32, %rsi
    add          $32, %rdx
    add          $32, %rcx
    sub          $8, %r10d
    jnz          .Lloop

    vzeroupper
.Ldone:
    ret
SIZE(SYM(ksvgLightingDistantDiffuseRowAvx2))

.p2align 5

/*
 * void ksvgLightingDistantDiffuseRowAvx2Linear(
 *     const jint* srcT, const jint* srcM, const jint* srcB,
 *     jint* dst, jint count, const LightingParams* params,
 *     const uint8_t* linearToSrgb);
 *
 * x86-64 System V ABI:
 *   rdi = srcT, rsi = srcM, rdx = srcB, rcx = dst, r8d = count, r9 = params
 *   stack: linearToSrgb ([rsp+8] at entry)
 */
.globl SYM(ksvgLightingDistantDiffuseRowAvx2Linear)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx2Linear), @function)
SYM(ksvgLightingDistantDiffuseRowAvx2Linear):
    // SysV x86-64: rdi=srcT, rsi=srcM, rdx=srcB, rcx=dst, r8=count, r9=params

    test         %r8d, %r8d
    jz           .Llin_done

    // Load Params
    DISTANT_DIFFUSE_PARAMS %r9, .Lone, %ymm0, %ymm1, %xmm0, %xmm1, %ymm6, %ymm7, %ymm8, %ymm9, %ymm10, %ymm11, %ymm12, %ymm13, %ymm14, %ymm15

    mov          %r8d, %r10d

.Llin_loop:
    // L2S_ARGB4 4,5,3,7 clobbers the low 128 bits of ymm6/ymm7 as scratch; reload them.
    vbroadcastss .Lone(%rip), %ymm0
    vdivss       0(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm6
    vdivss       4(%r9), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm7
    vbroadcastss 36(%r9), %ymm0
    vmulps       %ymm0, %ymm6, %ymm6
    vmulps       %ymm0, %ymm7, %ymm7

    vbroadcastss 8(%r9), %ymm8  // k (L2S clobbers ymm8 low half)
    vbroadcastss .Lone(%rip), %ymm15  // 1.0 (alpha-mask generation clobbers ymm15)
    vbroadcastss 12(%r9), %ymm9
    vbroadcastss 16(%r9), %ymm10
    vbroadcastss 20(%r9), %ymm11
    vbroadcastss 24(%r9), %ymm12
    vbroadcastss 28(%r9), %ymm13
    vbroadcastss 32(%r9), %ymm14

    // 3x3 Sobel window: sumT, dx_rel, sumB
    SOBEL_SUMS_DX %rdi, %rsi, %rdx, %ymm0, %ymm1, %ymm2, %ymm3, %ymm4, %ymm5, %ymm5

    // Convert the final integer derivatives to float and apply scale once.
    vcvtdq2ps    %ymm4, %ymm4
    vmulps       %ymm6, %ymm4, %ymm4  // dx (includes ss)
    vpsubd       %ymm3, %ymm5, %ymm5
    vcvtdq2ps    %ymm5, %ymm5
    vmulps       %ymm7, %ymm5, %ymm5  // dy (includes ss)

    // n = (-dx, -dy, 1) / |(-dx,-dy,1)|
    NORM_NEGXY_DIV %ymm4, %ymm5, %ymm15, %ymm0, %ymm1, %ymm5, %ymm2, %ymm3

    // Scalar equivalent: intensity = min(k * max(nx*lx + ny*ly + nz*lz, 0), 1)
    DOT3_K_CLAMP %ymm0, %ymm1, %ymm5, %ymm9, %ymm10, %ymm11, %ymm8, %ymm15, %ymm3, %ymm4

    // Pack
    PACK_RGB %ymm0, %ymm12, %ymm13, %ymm14, %ymm1, %ymm2, %ymm3, .Lhalf

    subq         $32, %rsp
    vextracti128 $1, %ymm0, %xmm6
    movdqu       %xmm6, 16(%rsp)
    vpxor        %xmm15, %xmm15, %xmm15
    L2S_ARGB4 4, 5, 3, 7
    movdqu       %xmm0, (%rsp)
    movdqu       16(%rsp), %xmm0
    L2S_ARGB4 4, 5, 3, 7
    movdqu       (%rsp), %xmm1
    vinserti128  $1, %xmm0, %ymm1, %ymm0
    addq         $32, %rsp
    vmovups      %ymm0, (%rcx)

    add          $32, %rdi
    add          $32, %rsi
    add          $32, %rdx
    add          $32, %rcx
    sub          $8, %r10d
    jnz          .Llin_loop

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
