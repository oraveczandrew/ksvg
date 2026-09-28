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
 * Shared scalar-tail code for the feBlend x86 kernels (SSSE3/AVX2/i386).
 * Included into .text (NOT standalone): TAIL_COMPOSITE_NARROW macro, the
 * 11 per-mode scalar tail fragments, and .Ltail_tab (same-section diffs,
 * so the table stays TEXTREL-free wherever it is included).
 *
 * Contract with the including file: lane-0 channels in slots sr@16 sg@32
 * sb@48 as@64 br@80 bg@96 bb@112 ab@128 ao@144, tR@176 tG@192 tB@208;
 * xmm15 = zero; encode table in r15 when ENC=1; fragments return through
 * r11; scalar FP constants (.Lone/.Ltwo/.Lfour/.Ltwelve/.Lsixteen/
 * .Lquarter/.L255/.Lhalf) provided by the including file's RODATA.
 */

/*
 * Scalar (lane-0) shared compositing for the tail. Same formula as
 * COMPOSITE; ao > 0 is guaranteed by the caller's ucomiss branch, so no
 * mask is needed. Result narrowed into r11d at bit SHIFT.
 * Clobbers xmm0, xmm1, xmm7.
 */
.macro TAIL_COMPOSITE_NARROW tslot, scslot, bcslot, shift, enc
    movss .Lone(%rip), %xmm7
    subss 128(%rsp), %xmm7
    mulss \scslot(%rsp), %xmm7
    mulss 64(%rsp), %xmm7
    movss .Lone(%rip), %xmm1
    subss 64(%rsp), %xmm1
    mulss \bcslot(%rsp), %xmm1
    mulss 128(%rsp), %xmm1
    addss %xmm1, %xmm7
    movss 64(%rsp), %xmm1
    mulss 128(%rsp), %xmm1
    mulss \tslot(%rsp), %xmm1
    addss %xmm1, %xmm7
    divss 144(%rsp), %xmm7
    mulss .L255(%rip), %xmm7
    maxss %xmm15, %xmm7
    minss .L255(%rip), %xmm7
    addss .Lhalf(%rip), %xmm7
    cvttss2si %xmm7, %eax
    .if \enc
    movzbl (%r15, %rax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $\shift, %eax
    orl %eax, %r11d
.endm

/* ------------------------------------------------------------------ */
/* Per-mode blend fragments (scalar tail). In: lane-0 channels in     */
/* slots. Out: lane-0 tR@176 tG@192 tB@208. Scratch xmm8/xmm9/xmm13.   */
/* Return through r11. Branches are free here (one pixel, not a loop   */
/* over lanes): each fragment mirrors its C++ scalar branch for branch.*/
/* ------------------------------------------------------------------ */
.p2align 4
.Ltail_multiply:
    movss 80(%rsp), %xmm0
    mulss 16(%rsp), %xmm0
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    mulss 32(%rsp), %xmm0
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    mulss 48(%rsp), %xmm0
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_screen:
    movss 80(%rsp), %xmm0
    addss 16(%rsp), %xmm0
    movss 80(%rsp), %xmm1
    mulss 16(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    addss 32(%rsp), %xmm0
    movss 96(%rsp), %xmm1
    mulss 32(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    addss 48(%rsp), %xmm0
    movss 112(%rsp), %xmm1
    mulss 48(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_overlay:
    movss 80(%rsp), %xmm0
    ucomiss .Lhalf(%rip), %xmm0
    jbe .Ltail_ov_r_lo
    /* hi: 1-((2*(1-cb))*(1-cs)). */
    movss .Lone(%rip), %xmm1
    subss 80(%rsp), %xmm1
    movss .Ltwo(%rip), %xmm2
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm1
    subss 16(%rsp), %xmm1
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail_ov_r_done
.Ltail_ov_r_lo:
    /* lo: (2*cb)*cs. */
    movss .Ltwo(%rip), %xmm0
    mulss 80(%rsp), %xmm0
    mulss 16(%rsp), %xmm0
.Ltail_ov_r_done:
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    ucomiss .Lhalf(%rip), %xmm0
    jbe .Ltail_ov_g_lo
    movss .Lone(%rip), %xmm1
    subss 96(%rsp), %xmm1
    movss .Ltwo(%rip), %xmm2
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm1
    subss 32(%rsp), %xmm1
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail_ov_g_done
.Ltail_ov_g_lo:
    movss .Ltwo(%rip), %xmm0
    mulss 96(%rsp), %xmm0
    mulss 32(%rsp), %xmm0
.Ltail_ov_g_done:
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    ucomiss .Lhalf(%rip), %xmm0
    jbe .Ltail_ov_b_lo
    movss .Lone(%rip), %xmm1
    subss 112(%rsp), %xmm1
    movss .Ltwo(%rip), %xmm2
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm1
    subss 48(%rsp), %xmm1
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail_ov_b_done
.Ltail_ov_b_lo:
    movss .Ltwo(%rip), %xmm0
    mulss 112(%rsp), %xmm0
    mulss 48(%rsp), %xmm0
.Ltail_ov_b_done:
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_darken:
    /* t = cb<cs ? cb : cs. ucomiss sets CF iff cb<cs (ordered). */
    movss 80(%rsp), %xmm0
    ucomiss 16(%rsp), %xmm0
    jb .Ltail_dk_r_keep
    movss 16(%rsp), %xmm0
.Ltail_dk_r_keep:
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    ucomiss 32(%rsp), %xmm0
    jb .Ltail_dk_g_keep
    movss 32(%rsp), %xmm0
.Ltail_dk_g_keep:
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    ucomiss 48(%rsp), %xmm0
    jb .Ltail_dk_b_keep
    movss 48(%rsp), %xmm0
.Ltail_dk_b_keep:
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_lighten:
    /* t = cb>cs ? cb : cs. */
    movss 80(%rsp), %xmm0
    ucomiss 16(%rsp), %xmm0
    ja .Ltail_lt_r_keep
    movss 16(%rsp), %xmm0
.Ltail_lt_r_keep:
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    ucomiss 32(%rsp), %xmm0
    ja .Ltail_lt_g_keep
    movss 32(%rsp), %xmm0
.Ltail_lt_g_keep:
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    ucomiss 48(%rsp), %xmm0
    ja .Ltail_lt_b_keep
    movss 48(%rsp), %xmm0
.Ltail_lt_b_keep:
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_dodge:
    /* cb==0 -> 0; cs>=1 -> 1; else min(cb/(1-cs), 1). */
    movss 80(%rsp), %xmm0
    ucomiss %xmm15, %xmm0
    je .Ltail_dg_r_zero
    movss 16(%rsp), %xmm0
    ucomiss .Lone(%rip), %xmm0
    jae .Ltail_dg_r_one
    movss .Lone(%rip), %xmm1
    subss 16(%rsp), %xmm1
    movss 80(%rsp), %xmm0
    divss %xmm1, %xmm0
    minss .Lone(%rip), %xmm0
    jmp .Ltail_dg_r_done
.Ltail_dg_r_zero:
    movss %xmm15, %xmm0
    jmp .Ltail_dg_r_done
.Ltail_dg_r_one:
    movss .Lone(%rip), %xmm0
.Ltail_dg_r_done:
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    ucomiss %xmm15, %xmm0
    je .Ltail_dg_g_zero
    movss 32(%rsp), %xmm0
    ucomiss .Lone(%rip), %xmm0
    jae .Ltail_dg_g_one
    movss .Lone(%rip), %xmm1
    subss 32(%rsp), %xmm1
    movss 96(%rsp), %xmm0
    divss %xmm1, %xmm0
    minss .Lone(%rip), %xmm0
    jmp .Ltail_dg_g_done
.Ltail_dg_g_zero:
    movss %xmm15, %xmm0
    jmp .Ltail_dg_g_done
.Ltail_dg_g_one:
    movss .Lone(%rip), %xmm0
.Ltail_dg_g_done:
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    ucomiss %xmm15, %xmm0
    je .Ltail_dg_b_zero
    movss 48(%rsp), %xmm0
    ucomiss .Lone(%rip), %xmm0
    jae .Ltail_dg_b_one
    movss .Lone(%rip), %xmm1
    subss 48(%rsp), %xmm1
    movss 112(%rsp), %xmm0
    divss %xmm1, %xmm0
    minss .Lone(%rip), %xmm0
    jmp .Ltail_dg_b_done
.Ltail_dg_b_zero:
    movss %xmm15, %xmm0
    jmp .Ltail_dg_b_done
.Ltail_dg_b_one:
    movss .Lone(%rip), %xmm0
.Ltail_dg_b_done:
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_burn:
    /* cb>=1 -> 1; cs<=0 -> 0; else 1-min((1-cb)/cs, 1). */
    movss 80(%rsp), %xmm0
    ucomiss .Lone(%rip), %xmm0
    jae .Ltail_bn_r_one
    movss 16(%rsp), %xmm0
    ucomiss %xmm15, %xmm0
    jbe .Ltail_bn_r_zero
    movss .Lone(%rip), %xmm1
    subss 80(%rsp), %xmm1
    divss 16(%rsp), %xmm1
    movss .Lone(%rip), %xmm0
    minss %xmm1, %xmm0
    movss .Lone(%rip), %xmm1
    subss %xmm0, %xmm1
    movss %xmm1, %xmm0
    jmp .Ltail_bn_r_done
.Ltail_bn_r_one:
    movss .Lone(%rip), %xmm0
    jmp .Ltail_bn_r_done
.Ltail_bn_r_zero:
    movss %xmm15, %xmm0
.Ltail_bn_r_done:
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    ucomiss .Lone(%rip), %xmm0
    jae .Ltail_bn_g_one
    movss 32(%rsp), %xmm0
    ucomiss %xmm15, %xmm0
    jbe .Ltail_bn_g_zero
    movss .Lone(%rip), %xmm1
    subss 96(%rsp), %xmm1
    divss 32(%rsp), %xmm1
    movss .Lone(%rip), %xmm0
    minss %xmm1, %xmm0
    movss .Lone(%rip), %xmm1
    subss %xmm0, %xmm1
    movss %xmm1, %xmm0
    jmp .Ltail_bn_g_done
.Ltail_bn_g_one:
    movss .Lone(%rip), %xmm0
    jmp .Ltail_bn_g_done
.Ltail_bn_g_zero:
    movss %xmm15, %xmm0
.Ltail_bn_g_done:
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    ucomiss .Lone(%rip), %xmm0
    jae .Ltail_bn_b_one
    movss 48(%rsp), %xmm0
    ucomiss %xmm15, %xmm0
    jbe .Ltail_bn_b_zero
    movss .Lone(%rip), %xmm1
    subss 112(%rsp), %xmm1
    divss 48(%rsp), %xmm1
    movss .Lone(%rip), %xmm0
    minss %xmm1, %xmm0
    movss .Lone(%rip), %xmm1
    subss %xmm0, %xmm1
    movss %xmm1, %xmm0
    jmp .Ltail_bn_b_done
.Ltail_bn_b_one:
    movss .Lone(%rip), %xmm0
    jmp .Ltail_bn_b_done
.Ltail_bn_b_zero:
    movss %xmm15, %xmm0
.Ltail_bn_b_done:
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_hardlight:
    movss 16(%rsp), %xmm0
    ucomiss .Lhalf(%rip), %xmm0
    jbe .Ltail_hl_r_lo
    movss .Lone(%rip), %xmm1
    subss 16(%rsp), %xmm1
    movss .Ltwo(%rip), %xmm2
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm1
    subss 80(%rsp), %xmm1
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail_hl_r_done
.Ltail_hl_r_lo:
    movss .Ltwo(%rip), %xmm0
    mulss 16(%rsp), %xmm0
    mulss 80(%rsp), %xmm0
.Ltail_hl_r_done:
    movss %xmm0, 176(%rsp)
    movss 32(%rsp), %xmm0
    ucomiss .Lhalf(%rip), %xmm0
    jbe .Ltail_hl_g_lo
    movss .Lone(%rip), %xmm1
    subss 32(%rsp), %xmm1
    movss .Ltwo(%rip), %xmm2
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm1
    subss 96(%rsp), %xmm1
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail_hl_g_done
.Ltail_hl_g_lo:
    movss .Ltwo(%rip), %xmm0
    mulss 32(%rsp), %xmm0
    mulss 96(%rsp), %xmm0
.Ltail_hl_g_done:
    movss %xmm0, 192(%rsp)
    movss 48(%rsp), %xmm0
    ucomiss .Lhalf(%rip), %xmm0
    jbe .Ltail_hl_b_lo
    movss .Lone(%rip), %xmm1
    subss 48(%rsp), %xmm1
    movss .Ltwo(%rip), %xmm2
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm1
    subss 112(%rsp), %xmm1
    mulss %xmm1, %xmm2
    movss .Lone(%rip), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail_hl_b_done
.Ltail_hl_b_lo:
    movss .Ltwo(%rip), %xmm0
    mulss 48(%rsp), %xmm0
    mulss 112(%rsp), %xmm0
.Ltail_hl_b_done:
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_softlight:
    /* d = cb<=0.25 ? poly : (float)sqrt((double)cb). */
    movss 80(%rsp), %xmm0
    ucomiss .Lquarter(%rip), %xmm0
    jbe .Ltail_sl_r_poly
    movss 80(%rsp), %xmm0
    cvtss2sd %xmm0, %xmm0
    sqrtsd %xmm0, %xmm0
    cvtsd2ss %xmm0, %xmm0
    jmp .Ltail_sl_r_d_done
.Ltail_sl_r_poly:
    movss .Lsixteen(%rip), %xmm0
    mulss 80(%rsp), %xmm0
    subss .Ltwelve(%rip), %xmm0
    mulss 80(%rsp), %xmm0
    addss .Lfour(%rip), %xmm0
    mulss 80(%rsp), %xmm0
.Ltail_sl_r_d_done:
    /* t = cb + ((2*cs)-1)*(d-cb). */
    movss .Ltwo(%rip), %xmm1
    mulss 16(%rsp), %xmm1
    subss .Lone(%rip), %xmm1
    subss 80(%rsp), %xmm0
    mulss %xmm0, %xmm1
    addss 80(%rsp), %xmm1
    movss %xmm1, 176(%rsp)
    movss 96(%rsp), %xmm0
    ucomiss .Lquarter(%rip), %xmm0
    jbe .Ltail_sl_g_poly
    movss 96(%rsp), %xmm0
    cvtss2sd %xmm0, %xmm0
    sqrtsd %xmm0, %xmm0
    cvtsd2ss %xmm0, %xmm0
    jmp .Ltail_sl_g_d_done
.Ltail_sl_g_poly:
    movss .Lsixteen(%rip), %xmm0
    mulss 96(%rsp), %xmm0
    subss .Ltwelve(%rip), %xmm0
    mulss 96(%rsp), %xmm0
    addss .Lfour(%rip), %xmm0
    mulss 96(%rsp), %xmm0
.Ltail_sl_g_d_done:
    movss .Ltwo(%rip), %xmm1
    mulss 32(%rsp), %xmm1
    subss .Lone(%rip), %xmm1
    subss 96(%rsp), %xmm0
    mulss %xmm0, %xmm1
    addss 96(%rsp), %xmm1
    movss %xmm1, 192(%rsp)
    movss 112(%rsp), %xmm0
    ucomiss .Lquarter(%rip), %xmm0
    jbe .Ltail_sl_b_poly
    movss 112(%rsp), %xmm0
    cvtss2sd %xmm0, %xmm0
    sqrtsd %xmm0, %xmm0
    cvtsd2ss %xmm0, %xmm0
    jmp .Ltail_sl_b_d_done
.Ltail_sl_b_poly:
    movss .Lsixteen(%rip), %xmm0
    mulss 112(%rsp), %xmm0
    subss .Ltwelve(%rip), %xmm0
    mulss 112(%rsp), %xmm0
    addss .Lfour(%rip), %xmm0
    mulss 112(%rsp), %xmm0
.Ltail_sl_b_d_done:
    movss .Ltwo(%rip), %xmm1
    mulss 48(%rsp), %xmm1
    subss .Lone(%rip), %xmm1
    subss 112(%rsp), %xmm0
    mulss %xmm0, %xmm1
    addss 112(%rsp), %xmm1
    movss %xmm1, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_difference:
    movss 80(%rsp), %xmm0
    subss 16(%rsp), %xmm0
    movd %xmm0, %eax
    andl $0x7fffffff, %eax
    movd %eax, %xmm0
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    subss 32(%rsp), %xmm0
    movd %xmm0, %eax
    andl $0x7fffffff, %eax
    movd %eax, %xmm0
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    subss 48(%rsp), %xmm0
    movd %xmm0, %eax
    andl $0x7fffffff, %eax
    movd %eax, %xmm0
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 4
.Ltail_exclusion:
    movss 80(%rsp), %xmm0
    addss 16(%rsp), %xmm0
    movss .Ltwo(%rip), %xmm1
    mulss 80(%rsp), %xmm1
    mulss 16(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 176(%rsp)
    movss 96(%rsp), %xmm0
    addss 32(%rsp), %xmm0
    movss .Ltwo(%rip), %xmm1
    mulss 96(%rsp), %xmm1
    mulss 32(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 192(%rsp)
    movss 112(%rsp), %xmm0
    addss 48(%rsp), %xmm0
    movss .Ltwo(%rip), %xmm1
    mulss 112(%rsp), %xmm1
    mulss 48(%rsp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 208(%rsp)
    jmp *%r11

.p2align 2
.Ltail_tab:
    .long .Ltail_multiply - .Ltail_tab, .Ltail_screen - .Ltail_tab
    .long .Ltail_overlay - .Ltail_tab, .Ltail_darken - .Ltail_tab
    .long .Ltail_lighten - .Ltail_tab, .Ltail_dodge - .Ltail_tab
    .long .Ltail_burn - .Ltail_tab, .Ltail_hardlight - .Ltail_tab
    .long .Ltail_softlight - .Ltail_tab, .Ltail_difference - .Ltail_tab
    .long .Ltail_exclusion - .Ltail_tab
