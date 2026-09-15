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
 * Shared x86_64 AVX2 lighting-kernel macros and tables.
 *
 * This header is included by the lighting_*_x86_64_avx2.S sources (after
 * asm_macros.S). Only definitions live here; every macro is
 * register-parameterized, and callers are responsible for loading table
 * bases (e.g. %r15) before use. On Apple the tables land in __TEXT,__const;
 * on ELF in .rodata — the same RODATA handling as the per-file literals.
 */

/*
 * Description:
 *   Converts one linear-light intensity byte (0..255) to its sRGB byte via the
 *   exact 256-entry LUT (.Lspot_l2s_data), matching ColorLuts.LINEAR_TO_SRGB /
 *   ksvg_linear_to_srgb_lut.
 *
 * Inputs:
 *   \reg  = 32-bit general-purpose register holding the linear intensity (0..255)
 *   %r15  = base of the 256-byte .Lspot_l2s_data LUT (loaded by the caller)
 *
 * Output:
 *   \reg  = sRGB byte value, stored through %r10d (top bits zeroed)
 *
 * Clobbers:
 *   \reg  (in-place)
 *   %r10d
 *
 * The instruction stream is byte-identical to the pre-existing L2S_SPOT /
 * L2S_SPOT64 definitions in the spot kernels; callers keep their loop index,
 * loop limit and the %r15 LUT base themselves.
 */
.macro L2S_SPOT reg
    movl      \reg, %r10d
    movzbl    (%r15,%r10,1), %r10d
    movl      %r10d, \reg
.endm

/*
 * Description:
 *   Alpha-byte to scaled float: extracts the alpha lane (vpsrld $24),
 *   converts int32->float (vcvtdq2ps, exact for 0..255), and scales by
 *   \scale. The emitted vmulps uses scale-first operand order; call sites
 *   that had channel-first order are bit-identical under the change because
 *   IEEE-754 multiplication commutes for every reachable input here: \ch is
 *   always a finite 0..255-derived float, and \scale is finite-or-Inf
 *   (finite*finite is order-independent; 0*Inf yields the canonical QNaN in
 *   both orders; QNaN inputs cannot occur).
 *
 * Inputs:
 *   \src          = vector holding the packed ARGB pixel (may equal \ch)
 *   \ch           = channel register receiving the scaled float (may equal
 *                   \src and/or \dst)
 *   \scale        = float scale vector (preserved)
 *   \dst          = destination for the scaled result (may equal \ch)
 *
 * Output:
 *   \dst = float((\src >> 24) & 0xFF) * \scale
 *
 * Clobbers:
 *   \ch, \dst (written; \src preserved unless aliased)
 *
 * Example: ALPHA_FSCALE %ymm9, %ymm9, %ymm2, %ymm9 scales the alpha of ymm9.
 */
.macro ALPHA_FSCALE src, ch, scale, dst
    vpsrld    $24, \src, \ch
    vcvtdq2ps \ch, \ch
    vmulps    \scale, \ch, \dst
.endm

RODATA
.p2align 5
.Lspot_l2s_data:
.byte 0,13,22,28,34,38,42,46,50,53,56,59,61,64,66,69
.byte 71,73,75,77,79,81,83,85,86,88,90,92,93,95,96,98
.byte 99,101,102,104,105,106,108,109,110,112,113,114,115,117,118,119
.byte 120,121,122,124,125,126,127,128,129,130,131,132,133,134,135,136
.byte 137,138,139,140,141,142,143,144,145,146,147,148,148,149,150,151
.byte 152,153,154,155,155,156,157,158,159,159,160,161,162,163,163,164
.byte 165,166,167,167,168,169,170,170,171,172,173,173,174,175,175,176
.byte 177,178,178,179,180,180,181,182,182,183,184,185,185,186,187,187
.byte 188,189,189,190,190,191,192,192,193,194,194,195,196,196,197,197
.byte 198,199,199,200,200,201,202,202,203,203,204,205,205,206,206,207
.byte 208,208,209,209,210,210,211,212,212,213,213,214,214,215,215,216
.byte 216,217,218,218,219,219,220,220,221,221,222,222,223,223,224,224
.byte 225,226,226,227,227,228,228,229,229,230,230,231,231,232,232,233
.byte 233,234,234,235,235,236,236,237,237,238,238,238,239,239,240,240
.byte 241,241,242,242,243,243,244,244,245,245,246,246,246,247,247,248
.byte 248,249,249,250,250,251,251,251,252,252,253,253,254,254,255,255

TEXT_SECTION
