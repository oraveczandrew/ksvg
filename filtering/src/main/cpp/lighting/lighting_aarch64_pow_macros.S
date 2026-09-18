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
 * AArch64 NEON pow approximation shared by lighting_*_aarch64_neon.S.
 *
 * Replaces the per-lane scalar double `bl pow` sequences (POW4_STACK):
 * no calls, so caller-saved registers survive and the stash/param-reload
 * dance around every pow block can go away.
 *
 * Method: pow(x,y) = 2^(y*log2(x)) with 8th-degree minimax polynomials
 * (coefficients match §4 of simd_scalar_pow_analysis; split mul+add Horner
 * validated by float32 simulation over x in [0,1] x y in {1..128}: worst
 * byte delta 1).
 * Horner steps use dup+fmul+fadd, NOT indexed FMLA: ARM `FMLA Vd,Vn,Vm`
 * computes Vd += Vn*Vm (dest is only the addend), which cannot express
 * acc = acc*f + c in one instruction (it would compute acc += f*c).
 * The x86 FMA form (vfmadd213) has different operand roles and is fine.
 * Domain note: bases are clamped ndoth in [0,1], exponents positive, so
 * t = y*log2(x) <= 0 always — overflow is impossible; x = 0 yields 0 via
 * the underflow clamp. No branches.
 *
 * Everything is position-independent (adrp + tables emitted per file).
 * NOTE: this file's mtime may be preserved by tooling; touch after edit.
 */

/*
 * Description:
 *   Emits the POW4_NEON constant tables (18 words: log2 c8..c0 then exp2
 *   c8..c0) as .Lpow4_tab. Invoke once per kernel file; the label is
 *   file-local like all other EMIT_* tables.
 */
.macro EMIT_POW4_NEON_TABLES
.align 4
.Lpow4_tab:
    .long 0xbc14e99e
    .long 0x3d517250
    .long 0xbe0b306b
    .long 0x3e762e19
    .long 0xbeb16ed0
    .long 0x3ef4f943
    .long 0xbf389c1f
    .long 0x3fb8a9fd
    .long 0x3335bce7
    .long 0, 0, 0                  // pad: exp block starts at +48 (ldp needs %16)
    .long 0x35fbc4c2
    .long 0x376d5f0a
    .long 0x3922b9a8
    .long 0x3aaeacc9
    .long 0x3c1d965e
    .long 0x3d63583b
    .long 0x3e75fdf0
    .long 0x3f317218
    .long 0x3f800000
.endm

/*
 * Description:
 *   4-lane NEON pow(x, y): \x = pow(\x, \y), all v.4s floats.
 *
 * Inputs:
 *   \x = base vector, lanes in [0, 1] (destroyed)
 *   \y = exponent, broadcast to all lanes (preserved)
 *   .Lpow4_tab reachable via adrp (caller emits EMIT_POW4_NEON_TABLES)
 *
 * Output:
 *   \x = pow approximation (0.0 for zero lanes via underflow clamp)
 *
 * Clobbers:
 *   x9, v4, v5, v6, v7, v10, v11
 *   (v13/v15 row invariants such as ux0/uy are never touched)
 *   Callers must have no live values there (previously everything
 *   caller-saved died in `bl pow` anyway; with no call the only new
 *   requirement is these 7 regs + a reachable table).
 */
.macro POW4_NEON x, y
    adrp    x9, .Lpow4_tab
    add     x9, x9, :lo12:.Lpow4_tab
    // e = (x >> 23) - 127
    movi    v4.4s, #127
    ushr    v6.4s, \x\().4s, #23
    sub     v6.4s, v6.4s, v4.4s
    scvtf   v6.4s, v6.4s                   // v6 = e float
    // m = (x & ~0xFF800000) | 0x3F800000; f = m - 1
    // (No shifted orr-immediate: LLVM rejects `orr v.4s, v.4s, #imm, lsl #N`;
    // use movi + register orr instead.)
    movi    v4.4s, #0xff, lsl #24
    movi    v5.4s, #128, lsl #16
    orr     v4.16b, v4.16b, v5.16b      // v4 = 0xFF800000
    movi    v7.4s, #0x3f, lsl #24
    orr     v7.16b, v7.16b, v5.16b      // v7 = 0x3F800000
    bic     \x\().16b, \x\().16b, v4.16b
    orr     \x\().16b, \x\().16b, v7.16b   // \x = m bits (= m float)
    fmov    v4.4s, #1.0
    fsub    v5.4s, \x\().4s, v4.4s         // v5 = f in [0,1)
    // log2 Horner: acc = c8; acc = acc*f + ci
    ldp     q10, q11, [x9]                 // log c8..c5, c4..c1
    dup     v7.4s, v10.s[0]                // c8
    dup     v4.4s, v10.s[1]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    dup     v4.4s, v10.s[2]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    dup     v4.4s, v10.s[3]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    dup     v4.4s, v11.s[0]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    dup     v4.4s, v11.s[1]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    dup     v4.4s, v11.s[2]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    dup     v4.4s, v11.s[3]
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    ldr     s4, [x9, #32]
    dup     v4.4s, v4.s[0]            // broadcast log c0 (ldr sets lane 0 only)
    fmul    v7.4s, v7.4s, v5.4s
    fadd    v7.4s, v7.4s, v4.4s
    fadd    v6.4s, v6.4s, v7.4s            // v6 = log2(x) = e + P(f)
    fmul    v6.4s, \y\().4s, v6.4s         // v6 = t
    mov     v4.16b, v6.16b                 // v4 = t copy
    frintm  v6.4s, v6.4s                   // v6 = ti = floor(t)
    fsub    v7.4s, v4.4s, v6.4s            // v7 = tf in [0,1)
    // exp2 Horner into \x
    ldp     q10, q11, [x9, #48]           // exp c8..c5, c4..c1
    dup     \x\().4s, v10.s[0]                // c8
    dup     v4.4s, v10.s[1]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    dup     v4.4s, v10.s[2]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    dup     v4.4s, v10.s[3]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    dup     v4.4s, v11.s[0]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    dup     v4.4s, v11.s[1]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    dup     v4.4s, v11.s[2]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    dup     v4.4s, v11.s[3]
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    ldr     s4, [x9, #80]
    dup     v4.4s, v4.s[0]            // broadcast exp c0
    fmul    \x\().4s, \x\().4s, v7.4s
    fadd    \x\().4s, \x\().4s, v4.4s
    // scale by 2^ti with underflow clamp
    fcvtzs  v6.4s, v6.4s
    movi    v4.4s, #127
    add     v6.4s, v6.4s, v4.4s
    movi    v5.4s, #0
    smax    v6.4s, v6.4s, v5.4s
    shl     v6.4s, v6.4s, #23
    fmul    \x\().4s, \x\().4s, v6.4s
.endm
