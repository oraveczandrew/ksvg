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
 * Shared i386 SSSE3 lighting-kernel macros.
 *
 * This header is included by the lighting_*_i386_ssse3.S sources (after
 * asm_macros.S). Only definitions live here; every macro is
 * register-parameterized. Everything is position-independent by
 * construction (stack-relative and register operands only; globals are
 * accessed by the callers via GOT/GOTOFF, never from inside a macro).
 * 32-bit constraints: GPRs are %eax/%ecx/%edx/%ebx/%esi/%edi/%ebp only;
 * address sizes are 32-bit throughout.
 */

/*
 * Description:
 *   Converts one stacked integer alpha (0..255) to a scaled float:
 *   loads the int, converts int32->float (cvtdq2ps, exact), scales by the
 *   surface-scale vector, and stores the float back to the same stack slot.
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
.macro TO_FLOAT stack_off
    movd  \stack_off(%ebp), %xmm0
    cvtdq2ps %xmm0, %xmm0
    mulss %xmm7, %xmm0
    movss %xmm0, \stack_off(%ebp)
.endm

/*
 * Description:
 *   Extracts one pixel's alpha byte and stores it as an integer: loads the
 *   pixel, shifts the alpha byte down (shrl $24), and stores the 0..255
 *   integer to a stack slot. 32-bit throughout; position-independent.
 *
 * Inputs:
 *   \src_off  = byte offset of the pixel from the row pointer in %eax
 *               (caller loads the row base into %eax)
 *   \dst_off  = stack offset of the integer slot in (%ebp)
 *
 * Output:
 *   0..255 integer at \dst_off(%ebp)
 *
 * Clobbers:
 *   %ecx
 */
.macro ALPHA_EXTRACT src_off, dst_off
    movl  \src_off(%eax), %ecx
    shrl  $24, %ecx
    movl  %ecx, \dst_off(%ebp)
.endm

/*
 * Description:
 *   Scales one color channel by the intensity, rounds half-up, and truncates
 *   to int: loads the channel factor, multiplies by the intensity, adds 0.5,
 *   converts with truncation. The intensity is always in %xmm0 and the
 *   scratch is always %xmm1 at every call site (kernel contract, verified);
 *   the GOT base %ebx is likewise fixed (established by LOAD_GOT, same as
 *   the %r15 LUT-base contract of L2S_SPOT).
 *
 * Inputs:
 *   \mem_off  = byte offset of the channel factor from the params base
 *   \base     = params base register (holds %eax for R, %edx for G/B)
 *   \dst      = 32-bit GPR receiving the truncated channel (eax/ecx/edx)
 *   \half     = symbol of the 0.5 literal (e.g. .Ldd_half, via GOTOFF)
 *
 * Output:
 *   \dst = (int)(\base[\mem_off] * intensity + 0.5)
 *
 * Clobbers:
 *   %xmm1
 *   \dst (written)
 */
.macro CHAN_TO_INT mem_off, base, dst, half
    movss \mem_off(\base), %xmm1
    mulss %xmm0, %xmm1
    addss \half@GOTOFF(%ebx), %xmm1
    cvttss2si %xmm1, \dst
.endm

/*
 * Description:
 *   Linear-path L2S gather: loads the LUT base and converts the three
 *   truncated channel bytes (in %eax/%ecx/%edx, the CHAN_TO_INT outputs)
 *   through the exact 256-entry linear->sRGB table. The LUT spill slot
 *   -24(%ebp) is part of the kernel frame contract (identical in all users).
 *
 * Inputs:
 *   \lut  = GPR receiving the LUT base (always %esi in practice)
 *
 * Output:
 *   %eax/%ecx/%edx = sRGB bytes
 *
 * Clobbers:
 *   \lut (written)
 *   %eax/%ecx/%edx (in-place)
 */
.macro L2S_GATHER lut
    movl  -24(%ebp), \lut
    movzbl (\lut,%eax), %eax
    movzbl (\lut,%ecx), %ecx
    movzbl (\lut,%edx), %edx
.endm

/*
 * Description:
 *   Force-alpha ARGB pack + store for diffuse kernels: R<<16 | G<<8 | B |
 *   0xFF000000, stored to (%ecx) reloaded as the dst pointer. Registers are
 *   deliberately fixed: the pack always consumes the L2S/CHAN outputs in
 *   %eax/%ecx/%edx (kernel contract, identical at all 3 use sites), so
 *   parameters would be pure noise.
 *
 * Output:
 *   packed 0xFFRRGGBB pixel stored to the dst pointer
 *
 * Clobbers:
 *   %eax (in-place: holds R<<16, then the packed pixel)
 *   %ecx (reloaded as dst pointer)
 */
.macro PACK_FORCE_ALPHA
    shll  $16, %eax
    shll  $8, %ecx
    orl   %ecx, %eax
    orl   %edx, %eax
    orl   $-16777216, %eax
    movl  -8(%ebp), %ecx
    movl  %eax, (%ecx)
.endm

/*
 * Description:
 *   Max-alpha ARGB pack + store for specular kernels: R<<16 | G<<8 | B,
 *   then alpha = max(R,G,B) (SIGNED cmovl, matching the pre-existing blocks)
 *   shifted to A<<24 and OR-ed in, stored to the dst pointer. Registers are
 *   deliberately fixed (kernel contract, identical at both use sites).
 *
 * Output:
 *   packed 0xAARRGGBB pixel stored to the dst pointer
 *
 * Clobbers:
 *   %eax (in-place), %esi
 *   %ecx (reloaded as dst pointer)
 */
.macro PACK_MAX_ALPHA
    shll  $16, %eax
    shll  $8, %ecx
    orl   %ecx, %eax
    orl   %edx, %eax
    movl  %eax, %esi
    cmpl  %ecx, %esi
    cmovl %ecx, %esi
    cmpl  %edx, %esi
    cmovl %edx, %esi
    shll  $24, %esi
    orl   %esi, %eax
    movl  -8(%ebp), %ecx
    movl  %eax, (%ecx)
.endm
