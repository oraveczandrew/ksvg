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
 * x86 (i386) SSSE3 implementation of feBlend, separable modes (1..11).
 * 32-bit twin of fe_blend_x86_64_ssse3.S: same algorithm, same
 * near-exact contract under the ssse3 maxDelta=1 parity tolerance
 * (1/255 reciprocal widen, one Newton-Raphson step over `rcpps`,
 * single-precision `sqrtss`; tail divs/sqrts stay exact).
 *
 * Channel slot offsets (16..208) deliberately match the x86-64 file so
 * the per-mode blend fragments transfer verbatim (rsp -> esp, PIC
 * constants); only the prologue, row loop, dispatch, tail and tables
 * are 32-bit-specific.
 *
 * 32-bit-forced deltas (ColorMatrix i386 lessons applied, not
 * rediscovered):
 * - All args on stack (offsets recounted, documented below).
 * - %ebp is ONLY the PIC anchor (call 1f; popl; constants addressed as
 *   (.Lx-1b)(%ebp), pool in RODATA — symdiffs resolve at static link,
 *   zero R_386_32 in .text, no TEXTREL).
 * - %ebx/%esi/%edi are cursors (out/src/dst); %ebp never holds data
 *   (clipLeft lives in a scratch slot, never in %ebp).
 * - 8 xmm regs: widened floats + results spill through the named slots
 *   (same shape as the x86-64 file, which also spills).
 * - Entry esp%16==12, pushes are 16B, so sub must be ==12 (mod 16) to
 *   keep the movaps/movdqa slot spills aligned: $252.
 * - SSSE3-only idioms (no pblendvb/ptest); selects are and/pxor/and/or
 *   with andnps(S,D) = ~D&S (the arithmetic S2L precedent).
 * - The loop counter is never shared with LUT index regs (ColorMatrix
 *   i386 linear-tail SIGSEGV lesson): scans use %eax, counts stay in
 *   %ecx/slots.
 * - Jump tables are 32-bit self-relative .long diffs + leal base (an
 *   absolute .quad/.long table would need TEXTREL on i386).
 * - Fragments return through the retAddr slot (244(%esp)); the tail
 *   fragments are 32-bit translations of fe_blend_scalar_tail.inc
 *   (which hardcodes r64 regs and cannot be included here).
 *
 * Stack frame: 4 pushes (16B) + sub $252. Stack args:
 *   src @272, dst @276, out @280, width @284, clipLeft @288,
 *   clipTop @292, clipRight @296, clipBottom @300, mode @304,
 *   useLinear @308, srgbToLinear @312, linearToSrgb @316.
 * Scratch slots: rows @0, tail @8,
 *   sr/sg/sb/as @16/32/48/64, br/bg/bb/ab @80/96/112/128,
 *   ao @144, aoMask @160, tR/tG/tB @176/192/208,
 *   stride @224, clipLeft @228, clipRight @232, encodeTable @240,
 *   retAddr @244, narrowAcc @248.
 * Registers: %esi/%edi/%ebx = src/dst/out cursors, %ebp = PIC anchor.
 * Masks and FP constants come from (.Lx-1b)(%ebp) memory operands.
 */

#include "asm_macros.S"

/*
 * Widen one channel's packed bytes (low dword of CH) to floats/255.
 * Clobbers only CH (255.0 broadcast + zero loaded per use; with 8 xmm
 * no register stays persistent across the widen spills).
 */
.macro WIDEN4 CH
    punpcklbw %xmm7, \CH
    punpcklwd %xmm7, \CH
    cvtdq2ps \CH, \CH
    mulps (.Lrecip255Vec-1b)(%ebp), \CH
.endm

/*
 * Shared packed per-channel compositing into the tR/tG/tB slot.
 * Scalar equivalent (fe_blend.cpp):
 *   o = ((1-ab)*cs*as + (1-as)*cb*ab + as*ab*t) / ao; ao<=0 -> 0
 *   (aoMask holds (ao > 0), ANDed after the division).
 * 1/ao via one Newton-Raphson step over `rcpps` (same profile as the
 * x86-64 twin; 0-lanes give +Inf, masked exactly like the div path).
 * Clobbers xmm0, xmm1, xmm2, xmm7.
 */
.macro COMPOSITE tslot, scslot, bcslot
    movaps (.LoneVec-1b)(%ebp), %xmm7
    subps 128(%esp), %xmm7
    mulps \scslot(%esp), %xmm7
    mulps 64(%esp), %xmm7
    movaps (.LoneVec-1b)(%ebp), %xmm1
    subps 64(%esp), %xmm1
    mulps \bcslot(%esp), %xmm1
    mulps 128(%esp), %xmm1
    addps %xmm1, %xmm7
    movaps 64(%esp), %xmm1
    mulps 128(%esp), %xmm1
    mulps \tslot(%esp), %xmm1
    addps %xmm1, %xmm7
    movaps 144(%esp), %xmm0
    rcpps %xmm0, %xmm1
    mulps %xmm1, %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm2
    subps %xmm0, %xmm2
    mulps %xmm2, %xmm1
    mulps %xmm1, %xmm7
    andps 160(%esp), %xmm7
    movaps %xmm7, \tslot(%esp)
.endm

/*
 * Narrow + store one output pixel (lane LANE of the R/G/B composite
 * quads in 176/192/208 and of ao in 144) to LANE*4(%ebx).
 * Matches clamp255(): *255, clamp [0,255], +0.5, truncate.
 * ENC=1: encode R/G/B through the table at encodeTable (240(%esp));
 * alpha is never encoded. Accumulates into narrowAcc (248(%esp)).
 * Clobbers xmm0, eax, edx. Pass bare numbers.
 */
.macro STORE_PIXEL86 lane, enc
    movss 176+\lane*4(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movl 240(%esp), %edx
    movzbl (%edx, %eax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $16, %eax
    orl %eax, 248(%esp)
    movss 192+\lane*4(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movl 240(%esp), %edx
    movzbl (%edx, %eax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $8, %eax
    orl %eax, 248(%esp)
    movss 208+\lane*4(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movl 240(%esp), %edx
    movzbl (%edx, %eax, 1), %eax
    .endif
    andl $0xff, %eax
    orl %eax, 248(%esp)
    movss 144+\lane*4(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, 248(%esp)
    movl 248(%esp), %eax
    movl %eax, \lane*4(%ebx)
.endm

/*
 * Scalar (lane-0) shared compositing for the tail. Same formula as
 * COMPOSITE; ao > 0 is guaranteed by the caller's ucomiss branch, so no
 * mask is needed. Result narrowed into narrowAcc (248(%esp)) at SHIFT.
 * Clobbers xmm0, xmm1. Encode table via 240(%esp) when ENC=1.
 */
.macro TAIL_COMPOSITE86 tslot, scslot, bcslot, shift, enc
    movss (.Lone-1b)(%ebp), %xmm0
    subss 128(%esp), %xmm0
    mulss \scslot(%esp), %xmm0
    mulss 64(%esp), %xmm0
    movss (.Lone-1b)(%ebp), %xmm1
    subss 64(%esp), %xmm1
    mulss \bcslot(%esp), %xmm1
    mulss 128(%esp), %xmm1
    addss %xmm1, %xmm0
    movss 64(%esp), %xmm1
    mulss 128(%esp), %xmm1
    mulss \tslot(%esp), %xmm1
    addss %xmm1, %xmm0
    divss 144(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    .if \enc
    movl 240(%esp), %edx
    movzbl (%edx, %eax, 1), %eax
    .endif
    andl $0xff, %eax
    shll $\shift, %eax
    orl %eax, 248(%esp)
.endm

.text
.p2align 5
/*
 * void applyFeBlendSsse3x86(
 *     const jint* src, const jint* dst, jint* out,
 *     jint width, jint clipLeft, jint clipTop, jint clipRight, jint clipBottom,
 *     jint mode, jboolean useLinear,
 *     const jbyte* srgbToLinear, const jbyte* linearToSrgb);
 *
 * i386 SysV ABI: all arguments on the stack (offsets documented above).
 * Callee-saved: %ebp (PIC anchor only), %ebx (out cursor), %esi (src),
 * %edi (dst).
 */
.globl SYM(applyFeBlendSsse3x86)
TYPE(SYM(applyFeBlendSsse3x86), @function)
SYM(applyFeBlendSsse3x86):
    pushl %ebp
    pushl %ebx
    pushl %esi
    pushl %edi
    call 1f
1:  popl %ebp
    subl $252, %esp
    # 4 pushes = 16 bytes; esp is orig-268. Stack args:
    # src @272, dst @276, out @280, width @284, clipLeft @288,
    # clipTop @292, clipRight @296, clipBottom @300, mode @304,
    # useLinear @308, srgbToLinear @312, linearToSrgb @316.
    # Scratch 0..251.

    movl 272(%esp), %esi              # src cursor
    movl 276(%esp), %edi             # dst cursor
    movl 280(%esp), %ebx             # out cursor
    movl 288(%esp), %eax
    movl %eax, 228(%esp)             # clipLeft
    movl 292(%esp), %eax             # clipTop
    movl 284(%esp), %ecx             # width
    imull %ecx, %eax
    addl 228(%esp), %eax
    leal (%esi, %eax, 4), %esi       # first src row
    leal (%edi, %eax, 4), %edi       # first dst row
    leal (%ebx, %eax, 4), %ebx       # first out row
    movl 284(%esp), %eax
    sall $2, %eax                    # stride = width * 4
    movl %eax, 224(%esp)
    movl 296(%esp), %eax
    movl %eax, 232(%esp)             # clipRight
    # rows = clipBottom - clipTop; empty clip: nothing to do.
    movl 300(%esp), %eax
    subl 292(%esp), %eax
    jle .Ldone
    movl %eax, 0(%esp)               # persistent rows left

    movl 308(%esp), %eax             # useLinear (test low byte)
    testb %al, %al
    jnz .Llinear_rows

# ------------------------------------------------------------------
# Non-linear rows.
# ------------------------------------------------------------------
.Lnonlin_rows:
    movl 232(%esp), %ecx
    subl 228(%esp), %ecx             # count = clipRight - clipLeft
    jle .Lrow_next_nonlin            # empty-width clip: skip the row
    movl %ecx, %eax
    shrl $2, %eax                    # blocks
    movl %eax, 4(%esp)               # blocks repurposed in tail slot
    andl $3, %ecx                    # tail pixels (kept in ecx)

    cmpl $0, 4(%esp)
    je .Lnonlin_tail

.p2align 4
.Lnonlin_block:
    # Widen src -> sr/sg/sb/as slots (xmm7 = zero for WIDEN4).
    movdqu (%esi), %xmm0
    pxor %xmm7, %xmm7
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleR-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 16(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleG-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 32(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleB-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 48(%esp)
    pshufb (.LshuffleA-1b)(%ebp), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 64(%esp)
    # Widen dst -> br/bg/bb/ab slots.
    movdqu (%edi), %xmm0
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleR-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 80(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleG-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 96(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleB-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 112(%esp)
    pshufb (.LshuffleA-1b)(%ebp), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 128(%esp)
    # ao = (as+ab) - as*ab; mask = (ao > 0).
    movaps 64(%esp), %xmm0
    addps 128(%esp), %xmm0
    movaps 64(%esp), %xmm1
    mulps 128(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 144(%esp)
    movaps %xmm0, %xmm1
    pxor %xmm0, %xmm0
    cmpnleps %xmm0, %xmm1
    movaps %xmm1, 160(%esp)

    # Per-mode blend -> tR/tG/tB slots; return through retAddr slot.
    leal (.Lblk_ret_nonlin-1b)(%ebp), %eax
    movl %eax, 244(%esp)
    movl 304(%esp), %ecx
    decl %ecx
    leal (.Lblk_tab-1b)(%ebp), %eax
    movl (%eax, %ecx, 4), %ecx
    addl %eax, %ecx
    jmp *%ecx
.Lblk_ret_nonlin:
    # Composite quads, then narrow + store all 4 pixels.
    COMPOSITE 176, 16, 80
    COMPOSITE 192, 32, 96
    COMPOSITE 208, 48, 112
    movl $0, 248(%esp)
    pxor %xmm7, %xmm7                # narrow clamp-zero
    STORE_PIXEL86 0, 0
    movl $0, 248(%esp)
    STORE_PIXEL86 1, 0
    movl $0, 248(%esp)
    STORE_PIXEL86 2, 0
    movl $0, 248(%esp)
    STORE_PIXEL86 3, 0

    addl $16, %esi
    addl $16, %edi
    addl $16, %ebx
    movl 4(%esp), %eax
    subl $1, %eax
    movl %eax, 4(%esp)
    jnz .Lnonlin_block

.Lnonlin_tail:
    movl 232(%esp), %ecx
    subl 228(%esp), %ecx
    andl $3, %ecx
    testl %ecx, %ecx
    jz .Lrow_next_nonlin

.Lnonlin_tail_loop:
    # Scalar widen both pixels, lane 0 -> slots (xmm7 = zero below).
    movl (%esi), %eax
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 16(%esp)
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 32(%esp)
    movl %eax, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 48(%esp)
    shrl $24, %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 64(%esp)
    movl (%edi), %eax
    movl %eax, %edx
    shrl $16, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 80(%esp)
    movl %eax, %edx
    shrl $8, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 96(%esp)
    movl %eax, %edx
    andl $0xff, %edx
    cvtsi2ss %edx, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 112(%esp)
    shrl $24, %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 128(%esp)
    # ao = (as+ab) - as*ab; ao <= 0 -> zero pixel.
    pxor %xmm7, %xmm7
    movss 64(%esp), %xmm0
    addss 128(%esp), %xmm0
    movss 64(%esp), %xmm1
    mulss 128(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 144(%esp)
    ucomiss %xmm7, %xmm0
    jbe .Ltail_zero_nonlin

    leal (.Ltail_ret_nonlin-1b)(%ebp), %eax
    movl %eax, 244(%esp)
    movl 304(%esp), %edx
    decl %edx
    leal (.Ltail_tab-1b)(%ebp), %eax
    movl (%eax, %edx, 4), %edx
    addl %eax, %edx
    jmp *%edx
.Ltail_ret_nonlin:
    movl $0, 248(%esp)
    TAIL_COMPOSITE86 176, 16, 80, 16, 0
    TAIL_COMPOSITE86 192, 32, 96, 8, 0
    TAIL_COMPOSITE86 208, 48, 112, 0, 0
    movss 144(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, 248(%esp)
    movl 248(%esp), %eax
    movl %eax, (%ebx)
    jmp .Ltail_advance_nonlin
.Ltail_zero_nonlin:
    movl $0, (%ebx)
.Ltail_advance_nonlin:
    addl $4, %esi
    addl $4, %edi
    addl $4, %ebx
    decl %ecx
    jnz .Lnonlin_tail_loop

.Lrow_next_nonlin:
    movl 232(%esp), %eax
    subl 228(%esp), %eax
    sall $2, %eax
    addl 224(%esp), %esi
    subl %eax, %esi
    addl 224(%esp), %edi
    subl %eax, %edi
    addl 224(%esp), %ebx
    subl %eax, %ebx
    decl 0(%esp)
    jnz .Lnonlin_rows
    jmp .Ldone

# ------------------------------------------------------------------
# Linear rows: LUT decode (both images) around the same core.
# ------------------------------------------------------------------
.Llinear_rows:
    movl 232(%esp), %ecx
    subl 228(%esp), %ecx
    jle .Lrow_next_linear
    movl %ecx, %eax
    shrl $2, %eax
    movl %eax, 4(%esp)
    andl $3, %ecx

    cmpl $0, 4(%esp)
    je .Llinear_tail

.p2align 4
.Llinear_block:
    # Decode src RGB via srgbToLinear; alpha bypasses the LUT.
    # Scan index in %eax (never the loop counter %ecx).
    movdqu (%esi), %xmm0
    movdqa %xmm0, %xmm1
    pand (.LalphaMask-1b)(%ebp), %xmm1
    movdqa %xmm0, %xmm2
    pand (.LnibbleMask-1b)(%ebp), %xmm2
    movdqa %xmm0, %xmm3
    psrlw $4, %xmm3
    pand (.LnibbleMask-1b)(%ebp), %xmm3
    movl 312(%esp), %edx
    pxor %xmm4, %xmm4                # acc
    xorl %eax, %eax
    leal (.LhiTab-1b)(%ebp), %ecx
.Ldec_src_loop:
    movdqu (%edx, %eax, 1), %xmm5
    pshufb %xmm2, %xmm5
    movdqa (%ecx, %eax, 1), %xmm6
    pcmpeqb %xmm3, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm4
    addl $16, %eax
    cmpl $256, %eax
    jne .Ldec_src_loop
    movdqa %xmm4, %xmm0
    pand (.LrgbMask-1b)(%ebp), %xmm0
    por %xmm1, %xmm0
    # Widen decoded src -> slots.
    pxor %xmm7, %xmm7
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleR-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 16(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleG-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 32(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleB-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 48(%esp)
    pshufb (.LshuffleA-1b)(%ebp), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 64(%esp)
    # Decode dst RGB the same way.
    movdqu (%edi), %xmm0
    movdqa %xmm0, %xmm1
    pand (.LalphaMask-1b)(%ebp), %xmm1
    movdqa %xmm0, %xmm2
    pand (.LnibbleMask-1b)(%ebp), %xmm2
    movdqa %xmm0, %xmm3
    psrlw $4, %xmm3
    pand (.LnibbleMask-1b)(%ebp), %xmm3
    pxor %xmm4, %xmm4
    xorl %eax, %eax
.Ldec_dst_loop:
    movdqu (%edx, %eax, 1), %xmm5
    pshufb %xmm2, %xmm5
    movdqa (%ecx, %eax, 1), %xmm6
    pcmpeqb %xmm3, %xmm6
    pand %xmm6, %xmm5
    por %xmm5, %xmm4
    addl $16, %eax
    cmpl $256, %eax
    jne .Ldec_dst_loop
    movdqa %xmm4, %xmm0
    pand (.LrgbMask-1b)(%ebp), %xmm0
    por %xmm1, %xmm0
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleR-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 80(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleG-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 96(%esp)
    movdqa %xmm0, %xmm1
    pshufb (.LshuffleB-1b)(%ebp), %xmm1
    WIDEN4 %xmm1
    movaps %xmm1, 112(%esp)
    pshufb (.LshuffleA-1b)(%ebp), %xmm0
    WIDEN4 %xmm0
    movaps %xmm0, 128(%esp)
    # ao + mask.
    movaps 64(%esp), %xmm0
    addps 128(%esp), %xmm0
    movaps 64(%esp), %xmm1
    mulps 128(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 144(%esp)
    movaps %xmm0, %xmm1
    pxor %xmm0, %xmm0
    cmpnleps %xmm0, %xmm1
    movaps %xmm1, 160(%esp)

    leal (.Lblk_ret_linear-1b)(%ebp), %eax
    movl %eax, 244(%esp)
    movl 304(%esp), %ecx
    decl %ecx
    leal (.Lblk_tab-1b)(%ebp), %eax
    movl (%eax, %ecx, 4), %ecx
    addl %eax, %ecx
    jmp *%ecx
.Lblk_ret_linear:
    # Composite + narrow with encode.
    movl 316(%esp), %eax
    movl %eax, 240(%esp)             # linearToSrgb
    COMPOSITE 176, 16, 80
    COMPOSITE 192, 32, 96
    COMPOSITE 208, 48, 112
    movl $0, 248(%esp)
    pxor %xmm7, %xmm7
    STORE_PIXEL86 0, 1
    movl $0, 248(%esp)
    STORE_PIXEL86 1, 1
    movl $0, 248(%esp)
    STORE_PIXEL86 2, 1
    movl $0, 248(%esp)
    STORE_PIXEL86 3, 1

    addl $16, %esi
    addl $16, %edi
    addl $16, %ebx
    movl 4(%esp), %eax
    subl $1, %eax
    movl %eax, 4(%esp)
    jnz .Llinear_block

.Llinear_tail:
    movl 232(%esp), %ecx
    subl 228(%esp), %ecx
    andl $3, %ecx
    testl %ecx, %ecx
    jz .Lrow_next_linear
    movl 316(%esp), %eax
    movl %eax, 240(%esp)             # encode table for the tail

.Llinear_tail_loop:
    # Scalar widen with LUT decode. Slot 240 doubles as the pixel spill
    # during decode (the encode table is loaded per pixel afterwards);
    # table base stays in %edx, pixel counter %ecx untouched.
    movl (%esi), %eax
    movl %eax, 240(%esp)
    movl 312(%esp), %edx
    movl 240(%esp), %eax
    andl $0xff, %eax
    movzbl (%edx, %eax, 1), %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 48(%esp)            # sb
    movl 240(%esp), %eax
    shrl $8, %eax
    andl $0xff, %eax
    movzbl (%edx, %eax, 1), %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 32(%esp)            # sg
    movl 240(%esp), %eax
    shrl $16, %eax
    andl $0xff, %eax
    movzbl (%edx, %eax, 1), %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 16(%esp)            # sr
    movl 240(%esp), %eax
    shrl $24, %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 64(%esp)            # as
    movl (%edi), %eax
    movl %eax, 240(%esp)
    movl 240(%esp), %eax
    andl $0xff, %eax
    movzbl (%edx, %eax, 1), %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 112(%esp)           # bb
    movl 240(%esp), %eax
    shrl $8, %eax
    andl $0xff, %eax
    movzbl (%edx, %eax, 1), %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 96(%esp)            # bg
    movl 240(%esp), %eax
    shrl $16, %eax
    andl $0xff, %eax
    movzbl (%edx, %eax, 1), %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 80(%esp)            # br
    movl 240(%esp), %eax
    shrl $24, %eax
    cvtsi2ss %eax, %xmm0
    divss (.L255-1b)(%ebp), %xmm0
    movss %xmm0, 128(%esp)           # ab
    pxor %xmm7, %xmm7
    movss 64(%esp), %xmm0
    addss 128(%esp), %xmm0
    movss 64(%esp), %xmm1
    mulss 128(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 144(%esp)
    ucomiss %xmm7, %xmm0
    jbe .Ltail_zero_linear
    # Encode table now owns slot 240 for the narrow below.
    movl 316(%esp), %eax
    movl %eax, 240(%esp)

    leal (.Ltail_ret_linear-1b)(%ebp), %eax
    movl %eax, 244(%esp)
    movl 304(%esp), %edx
    decl %edx
    leal (.Ltail_tab-1b)(%ebp), %eax
    movl (%eax, %edx, 4), %edx
    addl %eax, %edx
    jmp *%edx
.Ltail_ret_linear:
    movl $0, 248(%esp)
    TAIL_COMPOSITE86 176, 16, 80, 16, 1
    TAIL_COMPOSITE86 192, 32, 96, 8, 1
    TAIL_COMPOSITE86 208, 48, 112, 0, 1
    movss 144(%esp), %xmm0
    mulss (.L255-1b)(%ebp), %xmm0
    maxss %xmm7, %xmm0
    minss (.L255-1b)(%ebp), %xmm0
    addss (.Lhalf-1b)(%ebp), %xmm0
    cvttss2si %xmm0, %eax
    andl $0xff, %eax
    shll $24, %eax
    orl %eax, 248(%esp)
    movl 248(%esp), %eax
    movl %eax, (%ebx)
    jmp .Ltail_advance_linear
.Ltail_zero_linear:
    movl $0, (%ebx)
.Ltail_advance_linear:
    addl $4, %esi
    addl $4, %edi
    addl $4, %ebx
    decl %ecx
    jnz .Llinear_tail_loop

.Lrow_next_linear:
    movl 232(%esp), %eax
    subl 228(%esp), %eax
    sall $2, %eax
    addl 224(%esp), %esi
    subl %eax, %esi
    addl 224(%esp), %edi
    subl %eax, %edi
    addl 224(%esp), %ebx
    subl %eax, %ebx
    decl 0(%esp)
    jnz .Llinear_rows
    jmp .Ldone

# ------------------------------------------------------------------
# Per-mode blend fragments (vector). In: widened channels in slots
# (sr@16 sg@32 sb@48 br@80 bg@96 bb@112). Out: tR@176 tG@192 tB@208.
# Clobbers xmm0-xmm3. Return through retAddr slot (244(%esp)).
# Selects mirror the scalar ternaries exactly (and/pxor/and/or).
# ------------------------------------------------------------------
.p2align 4
.Lblk_multiply:
    movaps 80(%esp), %xmm0
    mulps 16(%esp), %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm0
    mulps 32(%esp), %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm0
    mulps 48(%esp), %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_screen:
    # t = (cb+cs) - cb*cs.
    movaps 80(%esp), %xmm0
    addps 16(%esp), %xmm0
    movaps 80(%esp), %xmm1
    mulps 16(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm0
    addps 32(%esp), %xmm0
    movaps 96(%esp), %xmm1
    mulps 32(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm0
    addps 48(%esp), %xmm0
    movaps 112(%esp), %xmm1
    mulps 48(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_overlay:
    # t = cb<=0.5 ? (2*cb)*cs : 1-((2*(1-cb))*(1-cs)).
    movaps 80(%esp), %xmm1
    cmpleps (.LhalfVec-1b)(%ebp), %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 80(%esp), %xmm0
    mulps 16(%esp), %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 80(%esp), %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 16(%esp), %xmm2
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm1
    cmpleps (.LhalfVec-1b)(%ebp), %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 96(%esp), %xmm0
    mulps 32(%esp), %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 96(%esp), %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 32(%esp), %xmm2
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm1
    cmpleps (.LhalfVec-1b)(%ebp), %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 112(%esp), %xmm0
    mulps 48(%esp), %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 112(%esp), %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 48(%esp), %xmm2
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_darken:
    # t = cb<cs ? cb : cs (ternary mirror, never minps).
    movaps 80(%esp), %xmm1
    cmpltps 16(%esp), %xmm1
    movaps 80(%esp), %xmm0
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    movaps 16(%esp), %xmm2
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm1
    cmpltps 32(%esp), %xmm1
    movaps 96(%esp), %xmm0
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    movaps 32(%esp), %xmm2
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm1
    cmpltps 48(%esp), %xmm1
    movaps 112(%esp), %xmm0
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    movaps 48(%esp), %xmm2
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_lighten:
    # t = cb>cs ? cb : cs (mask = cs<cb).
    movaps 16(%esp), %xmm1
    cmpltps 80(%esp), %xmm1
    movaps 80(%esp), %xmm0
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    movaps 16(%esp), %xmm2
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%esp)
    movaps 32(%esp), %xmm1
    cmpltps 96(%esp), %xmm1
    movaps 96(%esp), %xmm0
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    movaps 32(%esp), %xmm2
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%esp)
    movaps 48(%esp), %xmm1
    cmpltps 112(%esp), %xmm1
    movaps 112(%esp), %xmm0
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    movaps 48(%esp), %xmm2
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_dodge:
    # v = min(cb/(1-cs), 1); cs>=1 -> 1; cb==0 -> 0 (LAST, wins).
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps 16(%esp), %xmm0
    movaps 80(%esp), %xmm1
    rcpps %xmm0, %xmm2
    mulps %xmm2, %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    subps %xmm0, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm1
    minps (.LoneVec-1b)(%ebp), %xmm1
    movaps 16(%esp), %xmm2
    cmpnltps (.LoneVec-1b)(%ebp), %xmm2
    movaps (.LoneVec-1b)(%ebp), %xmm0
    andps %xmm2, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm2
    andps %xmm2, %xmm1
    orps %xmm0, %xmm1
    movaps 80(%esp), %xmm2
    cmpneqps (.Lzero-1b)(%ebp), %xmm2
    andps %xmm2, %xmm1
    movaps %xmm1, 176(%esp)
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps 32(%esp), %xmm0
    movaps 96(%esp), %xmm1
    rcpps %xmm0, %xmm2
    mulps %xmm2, %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    subps %xmm0, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm1
    minps (.LoneVec-1b)(%ebp), %xmm1
    movaps 32(%esp), %xmm2
    cmpnltps (.LoneVec-1b)(%ebp), %xmm2
    movaps (.LoneVec-1b)(%ebp), %xmm0
    andps %xmm2, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm2
    andps %xmm2, %xmm1
    orps %xmm0, %xmm1
    movaps 96(%esp), %xmm2
    cmpneqps (.Lzero-1b)(%ebp), %xmm2
    andps %xmm2, %xmm1
    movaps %xmm1, 192(%esp)
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps 48(%esp), %xmm0
    movaps 112(%esp), %xmm1
    rcpps %xmm0, %xmm2
    mulps %xmm2, %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    subps %xmm0, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm1
    minps (.LoneVec-1b)(%ebp), %xmm1
    movaps 48(%esp), %xmm2
    cmpnltps (.LoneVec-1b)(%ebp), %xmm2
    movaps (.LoneVec-1b)(%ebp), %xmm0
    andps %xmm2, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm2
    andps %xmm2, %xmm1
    orps %xmm0, %xmm1
    movaps 112(%esp), %xmm2
    cmpneqps (.Lzero-1b)(%ebp), %xmm2
    andps %xmm2, %xmm1
    movaps %xmm1, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_burn:
    # v = 1-min((1-cb)/cs, 1); cs<=0 -> 0 (keep where cs>0); cb>=1 -> 1.
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps 80(%esp), %xmm0
    movaps 16(%esp), %xmm1
    rcpps %xmm1, %xmm2
    mulps %xmm2, %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    subps %xmm1, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm1
    minps %xmm0, %xmm1
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps %xmm1, %xmm0
    movaps 16(%esp), %xmm1
    cmpnleps (.Lzero-1b)(%ebp), %xmm1
    andps %xmm1, %xmm0
    movaps 80(%esp), %xmm1
    cmpnltps (.LoneVec-1b)(%ebp), %xmm1
    movaps (.LoneVec-1b)(%ebp), %xmm2
    andps %xmm1, %xmm2
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm0
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%esp)
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps 96(%esp), %xmm0
    movaps 32(%esp), %xmm1
    rcpps %xmm1, %xmm2
    mulps %xmm2, %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    subps %xmm1, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm1
    minps %xmm0, %xmm1
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps %xmm1, %xmm0
    movaps 32(%esp), %xmm1
    cmpnleps (.Lzero-1b)(%ebp), %xmm1
    andps %xmm1, %xmm0
    movaps 96(%esp), %xmm1
    cmpnltps (.LoneVec-1b)(%ebp), %xmm1
    movaps (.LoneVec-1b)(%ebp), %xmm2
    andps %xmm1, %xmm2
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm0
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%esp)
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps 112(%esp), %xmm0
    movaps 48(%esp), %xmm1
    rcpps %xmm1, %xmm2
    mulps %xmm2, %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    subps %xmm1, %xmm3
    mulps %xmm3, %xmm2
    mulps %xmm2, %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm1
    minps %xmm0, %xmm1
    movaps (.LoneVec-1b)(%ebp), %xmm0
    subps %xmm1, %xmm0
    movaps 48(%esp), %xmm1
    cmpnleps (.Lzero-1b)(%ebp), %xmm1
    andps %xmm1, %xmm0
    movaps 112(%esp), %xmm1
    cmpnltps (.LoneVec-1b)(%ebp), %xmm1
    movaps (.LoneVec-1b)(%ebp), %xmm2
    andps %xmm1, %xmm2
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm0
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_hardlight:
    # t = cs<=0.5 ? (2*cs)*cb : 1-((2*(1-cs))*(1-cb)).
    movaps 16(%esp), %xmm1
    cmpleps (.LhalfVec-1b)(%ebp), %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 16(%esp), %xmm0
    mulps 80(%esp), %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 16(%esp), %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 80(%esp), %xmm2
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 176(%esp)
    movaps 32(%esp), %xmm1
    cmpleps (.LhalfVec-1b)(%ebp), %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 32(%esp), %xmm0
    mulps 96(%esp), %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 32(%esp), %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 96(%esp), %xmm2
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 192(%esp)
    movaps 48(%esp), %xmm1
    cmpleps (.LhalfVec-1b)(%ebp), %xmm1
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 48(%esp), %xmm0
    mulps 112(%esp), %xmm0
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 48(%esp), %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm3
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps 112(%esp), %xmm2
    mulps %xmm2, %xmm3
    movaps (.LoneVec-1b)(%ebp), %xmm2
    subps %xmm3, %xmm2
    andps %xmm1, %xmm0
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm2
    orps %xmm2, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_softlight:
    # d = cb<=0.25 ? ((16*cb-12)*cb+4)*cb : (float)sqrt((double)cb),
    # lane by lane (no double SIMD lanes on 32-bit); then
    # t = cb + ((2*cs)-1)*(d-cb). xmm4/xmm5 are free scratch here
    # (widened data lives in slots, not registers).
    movaps 80(%esp), %xmm1
    cmpleps (.LquarterVec-1b)(%ebp), %xmm1
    movaps (.LsixteenVec-1b)(%ebp), %xmm2
    mulps 80(%esp), %xmm2
    subps (.LtwelveVec-1b)(%ebp), %xmm2
    mulps 80(%esp), %xmm2
    addps (.LfourVec-1b)(%ebp), %xmm2
    mulps 80(%esp), %xmm2
    movss 80(%esp), %xmm3
    sqrtss %xmm3, %xmm3
    movss 84(%esp), %xmm4
    sqrtss %xmm4, %xmm4
    unpcklps %xmm4, %xmm3
    movss 88(%esp), %xmm4
    sqrtss %xmm4, %xmm4
    movss 92(%esp), %xmm0
    sqrtss %xmm0, %xmm0
    unpcklps %xmm0, %xmm4
    movlhps %xmm4, %xmm3
    andps %xmm1, %xmm2
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm3
    orps %xmm3, %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 16(%esp), %xmm0
    subps (.LoneVec-1b)(%ebp), %xmm0
    movaps %xmm2, %xmm3
    subps 80(%esp), %xmm3
    mulps %xmm3, %xmm0
    addps 80(%esp), %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm1
    cmpleps (.LquarterVec-1b)(%ebp), %xmm1
    movaps (.LsixteenVec-1b)(%ebp), %xmm2
    mulps 96(%esp), %xmm2
    subps (.LtwelveVec-1b)(%ebp), %xmm2
    mulps 96(%esp), %xmm2
    addps (.LfourVec-1b)(%ebp), %xmm2
    mulps 96(%esp), %xmm2
    movss 96(%esp), %xmm3
    sqrtss %xmm3, %xmm3
    movss 100(%esp), %xmm4
    sqrtss %xmm4, %xmm4
    unpcklps %xmm4, %xmm3
    movss 104(%esp), %xmm4
    sqrtss %xmm4, %xmm4
    movss 108(%esp), %xmm0
    sqrtss %xmm0, %xmm0
    unpcklps %xmm0, %xmm4
    movlhps %xmm4, %xmm3
    andps %xmm1, %xmm2
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm3
    orps %xmm3, %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 32(%esp), %xmm0
    subps (.LoneVec-1b)(%ebp), %xmm0
    movaps %xmm2, %xmm3
    subps 96(%esp), %xmm3
    mulps %xmm3, %xmm0
    addps 96(%esp), %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm1
    cmpleps (.LquarterVec-1b)(%ebp), %xmm1
    movaps (.LsixteenVec-1b)(%ebp), %xmm2
    mulps 112(%esp), %xmm2
    subps (.LtwelveVec-1b)(%ebp), %xmm2
    mulps 112(%esp), %xmm2
    addps (.LfourVec-1b)(%ebp), %xmm2
    mulps 112(%esp), %xmm2
    movss 112(%esp), %xmm3
    sqrtss %xmm3, %xmm3
    movss 116(%esp), %xmm4
    sqrtss %xmm4, %xmm4
    unpcklps %xmm4, %xmm3
    movss 120(%esp), %xmm4
    sqrtss %xmm4, %xmm4
    movss 124(%esp), %xmm0
    sqrtss %xmm0, %xmm0
    unpcklps %xmm0, %xmm4
    movlhps %xmm4, %xmm3
    andps %xmm1, %xmm2
    pxor (.LonesVec-1b)(%ebp), %xmm1
    andps %xmm1, %xmm3
    orps %xmm3, %xmm2
    movaps (.LtwoVec-1b)(%ebp), %xmm0
    mulps 48(%esp), %xmm0
    subps (.LoneVec-1b)(%ebp), %xmm0
    movaps %xmm2, %xmm3
    subps 112(%esp), %xmm3
    mulps %xmm3, %xmm0
    addps 112(%esp), %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_difference:
    # t = |cb-cs|.
    movaps 80(%esp), %xmm0
    subps 16(%esp), %xmm0
    andps (.LabsMask-1b)(%ebp), %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm0
    subps 32(%esp), %xmm0
    andps (.LabsMask-1b)(%ebp), %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm0
    subps 48(%esp), %xmm0
    andps (.LabsMask-1b)(%ebp), %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Lblk_exclusion:
    # t = (cb+cs) - (2*cb)*cs.
    movaps 80(%esp), %xmm0
    addps 16(%esp), %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm1
    mulps 80(%esp), %xmm1
    mulps 16(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 176(%esp)
    movaps 96(%esp), %xmm0
    addps 32(%esp), %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm1
    mulps 96(%esp), %xmm1
    mulps 32(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 192(%esp)
    movaps 112(%esp), %xmm0
    addps 48(%esp), %xmm0
    movaps (.LtwoVec-1b)(%ebp), %xmm1
    mulps 112(%esp), %xmm1
    mulps 48(%esp), %xmm1
    subps %xmm1, %xmm0
    movaps %xmm0, 208(%esp)
    jmp *244(%esp)

# ------------------------------------------------------------------
# Per-mode blend fragments (scalar tail). In: lane-0 channels in
# slots. Out: lane-0 tR@176 tG@192 tB@208. Scratch xmm0-xmm2.
# Return through retAddr slot. Branches are free here: each fragment
# mirrors its C++ scalar branch for branch. xmm7 is the zero.
# ------------------------------------------------------------------
.p2align 4
.Ltail_multiply:
    movss 80(%esp), %xmm0
    mulss 16(%esp), %xmm0
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    mulss 32(%esp), %xmm0
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    mulss 48(%esp), %xmm0
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_screen:
    movss 80(%esp), %xmm0
    addss 16(%esp), %xmm0
    movss 80(%esp), %xmm1
    mulss 16(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    addss 32(%esp), %xmm0
    movss 96(%esp), %xmm1
    mulss 32(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    addss 48(%esp), %xmm0
    movss 112(%esp), %xmm1
    mulss 48(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_overlay:
    movss 80(%esp), %xmm0
    ucomiss (.Lhalf-1b)(%ebp), %xmm0
    jbe .Ltail86_ov_r_lo
    movss (.Lone-1b)(%ebp), %xmm1
    subss 80(%esp), %xmm1
    movss (.Ltwo-1b)(%ebp), %xmm2
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm1
    subss 16(%esp), %xmm1
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail86_ov_r_done
.Ltail86_ov_r_lo:
    movss (.Ltwo-1b)(%ebp), %xmm0
    mulss 80(%esp), %xmm0
    mulss 16(%esp), %xmm0
.Ltail86_ov_r_done:
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    ucomiss (.Lhalf-1b)(%ebp), %xmm0
    jbe .Ltail86_ov_g_lo
    movss (.Lone-1b)(%ebp), %xmm1
    subss 96(%esp), %xmm1
    movss (.Ltwo-1b)(%ebp), %xmm2
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm1
    subss 32(%esp), %xmm1
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail86_ov_g_done
.Ltail86_ov_g_lo:
    movss (.Ltwo-1b)(%ebp), %xmm0
    mulss 96(%esp), %xmm0
    mulss 32(%esp), %xmm0
.Ltail86_ov_g_done:
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    ucomiss (.Lhalf-1b)(%ebp), %xmm0
    jbe .Ltail86_ov_b_lo
    movss (.Lone-1b)(%ebp), %xmm1
    subss 112(%esp), %xmm1
    movss (.Ltwo-1b)(%ebp), %xmm2
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm1
    subss 48(%esp), %xmm1
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail86_ov_b_done
.Ltail86_ov_b_lo:
    movss (.Ltwo-1b)(%ebp), %xmm0
    mulss 112(%esp), %xmm0
    mulss 48(%esp), %xmm0
.Ltail86_ov_b_done:
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_darken:
    # t = cb<cs ? cb : cs. ucomiss sets CF iff cb<cs (ordered).
    movss 80(%esp), %xmm0
    ucomiss 16(%esp), %xmm0
    jb .Ltail86_dk_r_keep
    movss 16(%esp), %xmm0
.Ltail86_dk_r_keep:
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    ucomiss 32(%esp), %xmm0
    jb .Ltail86_dk_g_keep
    movss 32(%esp), %xmm0
.Ltail86_dk_g_keep:
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    ucomiss 48(%esp), %xmm0
    jb .Ltail86_dk_b_keep
    movss 48(%esp), %xmm0
.Ltail86_dk_b_keep:
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_lighten:
    # t = cb>cs ? cb : cs.
    movss 80(%esp), %xmm0
    ucomiss 16(%esp), %xmm0
    ja .Ltail86_lt_r_keep
    movss 16(%esp), %xmm0
.Ltail86_lt_r_keep:
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    ucomiss 32(%esp), %xmm0
    ja .Ltail86_lt_g_keep
    movss 32(%esp), %xmm0
.Ltail86_lt_g_keep:
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    ucomiss 48(%esp), %xmm0
    ja .Ltail86_lt_b_keep
    movss 48(%esp), %xmm0
.Ltail86_lt_b_keep:
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_dodge:
    # cb==0 -> 0; cs>=1 -> 1; else min(cb/(1-cs), 1).
    movss 80(%esp), %xmm0
    ucomiss %xmm7, %xmm0
    je .Ltail86_dg_r_zero
    movss 16(%esp), %xmm0
    ucomiss (.Lone-1b)(%ebp), %xmm0
    jae .Ltail86_dg_r_one
    movss (.Lone-1b)(%ebp), %xmm1
    subss 16(%esp), %xmm1
    movss 80(%esp), %xmm0
    divss %xmm1, %xmm0
    minss (.Lone-1b)(%ebp), %xmm0
    jmp .Ltail86_dg_r_done
.Ltail86_dg_r_zero:
    movss %xmm7, %xmm0
    jmp .Ltail86_dg_r_done
.Ltail86_dg_r_one:
    movss (.Lone-1b)(%ebp), %xmm0
.Ltail86_dg_r_done:
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    ucomiss %xmm7, %xmm0
    je .Ltail86_dg_g_zero
    movss 32(%esp), %xmm0
    ucomiss (.Lone-1b)(%ebp), %xmm0
    jae .Ltail86_dg_g_one
    movss (.Lone-1b)(%ebp), %xmm1
    subss 32(%esp), %xmm1
    movss 96(%esp), %xmm0
    divss %xmm1, %xmm0
    minss (.Lone-1b)(%ebp), %xmm0
    jmp .Ltail86_dg_g_done
.Ltail86_dg_g_zero:
    movss %xmm7, %xmm0
    jmp .Ltail86_dg_g_done
.Ltail86_dg_g_one:
    movss (.Lone-1b)(%ebp), %xmm0
.Ltail86_dg_g_done:
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    ucomiss %xmm7, %xmm0
    je .Ltail86_dg_b_zero
    movss 48(%esp), %xmm0
    ucomiss (.Lone-1b)(%ebp), %xmm0
    jae .Ltail86_dg_b_one
    movss (.Lone-1b)(%ebp), %xmm1
    subss 48(%esp), %xmm1
    movss 112(%esp), %xmm0
    divss %xmm1, %xmm0
    minss (.Lone-1b)(%ebp), %xmm0
    jmp .Ltail86_dg_b_done
.Ltail86_dg_b_zero:
    movss %xmm7, %xmm0
    jmp .Ltail86_dg_b_done
.Ltail86_dg_b_one:
    movss (.Lone-1b)(%ebp), %xmm0
.Ltail86_dg_b_done:
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_burn:
    # cb>=1 -> 1; cs<=0 -> 0; else 1-min((1-cb)/cs, 1).
    movss 80(%esp), %xmm0
    ucomiss (.Lone-1b)(%ebp), %xmm0
    jae .Ltail86_bn_r_one
    movss 16(%esp), %xmm0
    ucomiss %xmm7, %xmm0
    jbe .Ltail86_bn_r_zero
    movss (.Lone-1b)(%ebp), %xmm1
    subss 80(%esp), %xmm1
    divss 16(%esp), %xmm1
    movss (.Lone-1b)(%ebp), %xmm0
    minss %xmm1, %xmm0
    movss (.Lone-1b)(%ebp), %xmm1
    subss %xmm0, %xmm1
    movss %xmm1, %xmm0
    jmp .Ltail86_bn_r_done
.Ltail86_bn_r_one:
    movss (.Lone-1b)(%ebp), %xmm0
    jmp .Ltail86_bn_r_done
.Ltail86_bn_r_zero:
    movss %xmm7, %xmm0
.Ltail86_bn_r_done:
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    ucomiss (.Lone-1b)(%ebp), %xmm0
    jae .Ltail86_bn_g_one
    movss 32(%esp), %xmm0
    ucomiss %xmm7, %xmm0
    jbe .Ltail86_bn_g_zero
    movss (.Lone-1b)(%ebp), %xmm1
    subss 96(%esp), %xmm1
    divss 32(%esp), %xmm1
    movss (.Lone-1b)(%ebp), %xmm0
    minss %xmm1, %xmm0
    movss (.Lone-1b)(%ebp), %xmm1
    subss %xmm0, %xmm1
    movss %xmm1, %xmm0
    jmp .Ltail86_bn_g_done
.Ltail86_bn_g_one:
    movss (.Lone-1b)(%ebp), %xmm0
    jmp .Ltail86_bn_g_done
.Ltail86_bn_g_zero:
    movss %xmm7, %xmm0
.Ltail86_bn_g_done:
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    ucomiss (.Lone-1b)(%ebp), %xmm0
    jae .Ltail86_bn_b_one
    movss 48(%esp), %xmm0
    ucomiss %xmm7, %xmm0
    jbe .Ltail86_bn_b_zero
    movss (.Lone-1b)(%ebp), %xmm1
    subss 112(%esp), %xmm1
    divss 48(%esp), %xmm1
    movss (.Lone-1b)(%ebp), %xmm0
    minss %xmm1, %xmm0
    movss (.Lone-1b)(%ebp), %xmm1
    subss %xmm0, %xmm1
    movss %xmm1, %xmm0
    jmp .Ltail86_bn_b_done
.Ltail86_bn_b_one:
    movss (.Lone-1b)(%ebp), %xmm0
    jmp .Ltail86_bn_b_done
.Ltail86_bn_b_zero:
    movss %xmm7, %xmm0
.Ltail86_bn_b_done:
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_hardlight:
    movss 16(%esp), %xmm0
    ucomiss (.Lhalf-1b)(%ebp), %xmm0
    jbe .Ltail86_hl_r_lo
    movss (.Lone-1b)(%ebp), %xmm1
    subss 16(%esp), %xmm1
    movss (.Ltwo-1b)(%ebp), %xmm2
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm1
    subss 80(%esp), %xmm1
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail86_hl_r_done
.Ltail86_hl_r_lo:
    movss (.Ltwo-1b)(%ebp), %xmm0
    mulss 16(%esp), %xmm0
    mulss 80(%esp), %xmm0
.Ltail86_hl_r_done:
    movss %xmm0, 176(%esp)
    movss 32(%esp), %xmm0
    ucomiss (.Lhalf-1b)(%ebp), %xmm0
    jbe .Ltail86_hl_g_lo
    movss (.Lone-1b)(%ebp), %xmm1
    subss 32(%esp), %xmm1
    movss (.Ltwo-1b)(%ebp), %xmm2
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm1
    subss 96(%esp), %xmm1
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail86_hl_g_done
.Ltail86_hl_g_lo:
    movss (.Ltwo-1b)(%ebp), %xmm0
    mulss 32(%esp), %xmm0
    mulss 96(%esp), %xmm0
.Ltail86_hl_g_done:
    movss %xmm0, 192(%esp)
    movss 48(%esp), %xmm0
    ucomiss (.Lhalf-1b)(%ebp), %xmm0
    jbe .Ltail86_hl_b_lo
    movss (.Lone-1b)(%ebp), %xmm1
    subss 48(%esp), %xmm1
    movss (.Ltwo-1b)(%ebp), %xmm2
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm1
    subss 112(%esp), %xmm1
    mulss %xmm1, %xmm2
    movss (.Lone-1b)(%ebp), %xmm0
    subss %xmm2, %xmm0
    jmp .Ltail86_hl_b_done
.Ltail86_hl_b_lo:
    movss (.Ltwo-1b)(%ebp), %xmm0
    mulss 48(%esp), %xmm0
    mulss 112(%esp), %xmm0
.Ltail86_hl_b_done:
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_softlight:
    # d = cb<=0.25 ? poly : (float)sqrt((double)cb); scalar sqrtsd path.
    movss 80(%esp), %xmm0
    ucomiss (.Lquarter-1b)(%ebp), %xmm0
    jbe .Ltail86_sl_r_poly
    movss 80(%esp), %xmm0
    cvtss2sd %xmm0, %xmm0
    sqrtsd %xmm0, %xmm0
    cvtsd2ss %xmm0, %xmm0
    jmp .Ltail86_sl_r_d_done
.Ltail86_sl_r_poly:
    movss (.Lsixteen-1b)(%ebp), %xmm0
    mulss 80(%esp), %xmm0
    subss (.Ltwelve-1b)(%ebp), %xmm0
    mulss 80(%esp), %xmm0
    addss (.Lfour-1b)(%ebp), %xmm0
    mulss 80(%esp), %xmm0
.Ltail86_sl_r_d_done:
    movss (.Ltwo-1b)(%ebp), %xmm1
    mulss 16(%esp), %xmm1
    subss (.Lone-1b)(%ebp), %xmm1
    subss 80(%esp), %xmm0
    mulss %xmm0, %xmm1
    addss 80(%esp), %xmm1
    movss %xmm1, 176(%esp)
    movss 96(%esp), %xmm0
    ucomiss (.Lquarter-1b)(%ebp), %xmm0
    jbe .Ltail86_sl_g_poly
    movss 96(%esp), %xmm0
    cvtss2sd %xmm0, %xmm0
    sqrtsd %xmm0, %xmm0
    cvtsd2ss %xmm0, %xmm0
    jmp .Ltail86_sl_g_d_done
.Ltail86_sl_g_poly:
    movss (.Lsixteen-1b)(%ebp), %xmm0
    mulss 96(%esp), %xmm0
    subss (.Ltwelve-1b)(%ebp), %xmm0
    mulss 96(%esp), %xmm0
    addss (.Lfour-1b)(%ebp), %xmm0
    mulss 96(%esp), %xmm0
.Ltail86_sl_g_d_done:
    movss (.Ltwo-1b)(%ebp), %xmm1
    mulss 32(%esp), %xmm1
    subss (.Lone-1b)(%ebp), %xmm1
    subss 96(%esp), %xmm0
    mulss %xmm0, %xmm1
    addss 96(%esp), %xmm1
    movss %xmm1, 192(%esp)
    movss 112(%esp), %xmm0
    ucomiss (.Lquarter-1b)(%ebp), %xmm0
    jbe .Ltail86_sl_b_poly
    movss 112(%esp), %xmm0
    cvtss2sd %xmm0, %xmm0
    sqrtsd %xmm0, %xmm0
    cvtsd2ss %xmm0, %xmm0
    jmp .Ltail86_sl_b_d_done
.Ltail86_sl_b_poly:
    movss (.Lsixteen-1b)(%ebp), %xmm0
    mulss 112(%esp), %xmm0
    subss (.Ltwelve-1b)(%ebp), %xmm0
    mulss 112(%esp), %xmm0
    addss (.Lfour-1b)(%ebp), %xmm0
    mulss 112(%esp), %xmm0
.Ltail86_sl_b_d_done:
    movss (.Ltwo-1b)(%ebp), %xmm1
    mulss 48(%esp), %xmm1
    subss (.Lone-1b)(%ebp), %xmm1
    subss 112(%esp), %xmm0
    mulss %xmm0, %xmm1
    addss 112(%esp), %xmm1
    movss %xmm1, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_difference:
    movss 80(%esp), %xmm0
    subss 16(%esp), %xmm0
    movd %xmm0, %eax
    andl $0x7fffffff, %eax
    movd %eax, %xmm0
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    subss 32(%esp), %xmm0
    movd %xmm0, %eax
    andl $0x7fffffff, %eax
    movd %eax, %xmm0
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    subss 48(%esp), %xmm0
    movd %xmm0, %eax
    andl $0x7fffffff, %eax
    movd %eax, %xmm0
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.p2align 4
.Ltail_exclusion:
    movss 80(%esp), %xmm0
    addss 16(%esp), %xmm0
    movss (.Ltwo-1b)(%ebp), %xmm1
    mulss 80(%esp), %xmm1
    mulss 16(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 176(%esp)
    movss 96(%esp), %xmm0
    addss 32(%esp), %xmm0
    movss (.Ltwo-1b)(%ebp), %xmm1
    mulss 96(%esp), %xmm1
    mulss 32(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 192(%esp)
    movss 112(%esp), %xmm0
    addss 48(%esp), %xmm0
    movss (.Ltwo-1b)(%ebp), %xmm1
    mulss 112(%esp), %xmm1
    mulss 48(%esp), %xmm1
    subss %xmm1, %xmm0
    movss %xmm0, 208(%esp)
    jmp *244(%esp)

.Ldone:
    addl $252, %esp
    popl %edi
    popl %esi
    popl %ebx
    popl %ebp
    ret

SIZE(SYM(applyFeBlendSsse3x86))

# Mode jump tables: 32-bit self-relative diffs, index = mode - 1.
# Same-section diffs assemble to constants: no R_386_32 in .text,
# no TEXTREL (an absolute table would need it on i386).
.p2align 2
.Lblk_tab:
    .long .Lblk_multiply - .Lblk_tab, .Lblk_screen - .Lblk_tab
    .long .Lblk_overlay - .Lblk_tab, .Lblk_darken - .Lblk_tab
    .long .Lblk_lighten - .Lblk_tab, .Lblk_dodge - .Lblk_tab
    .long .Lblk_burn - .Lblk_tab, .Lblk_hardlight - .Lblk_tab
    .long .Lblk_softlight - .Lblk_tab, .Lblk_difference - .Lblk_tab
    .long .Lblk_exclusion - .Lblk_tab
.p2align 2
.Ltail_tab:
    .long .Ltail_multiply - .Ltail_tab, .Ltail_screen - .Ltail_tab
    .long .Ltail_overlay - .Ltail_tab, .Ltail_darken - .Ltail_tab
    .long .Ltail_lighten - .Ltail_tab, .Ltail_dodge - .Ltail_tab
    .long .Ltail_burn - .Ltail_tab, .Ltail_hardlight - .Ltail_tab
    .long .Ltail_softlight - .Ltail_tab, .Ltail_difference - .Ltail_tab
    .long .Ltail_exclusion - .Ltail_tab

RODATA
.p2align 4
.L255:
    .long 0x437f0000
.p2align 4
.L255Vec:
    .long 0x437f0000, 0x437f0000, 0x437f0000, 0x437f0000
.p2align 4
.Lrecip255Vec:
    .long 0x3b808081, 0x3b808081, 0x3b808081, 0x3b808081
.p2align 4
.Lhalf:
    .long 0x3f000000
.p2align 4
.LhalfVec:
    .long 0x3f000000, 0x3f000000, 0x3f000000, 0x3f000000
.p2align 4
.Lone:
    .long 0x3f800000
.p2align 4
.LoneVec:
    .long 0x3f800000, 0x3f800000, 0x3f800000, 0x3f800000
.p2align 4
.Ltwo:
    .long 0x40000000
.p2align 4
.LtwoVec:
    .long 0x40000000, 0x40000000, 0x40000000, 0x40000000
.p2align 4
.Lfour:
    .long 0x40800000
.p2align 4
.LfourVec:
    .long 0x40800000, 0x40800000, 0x40800000, 0x40800000
.p2align 4
.Ltwelve:
    .long 0x41400000
.p2align 4
.LtwelveVec:
    .long 0x41400000, 0x41400000, 0x41400000, 0x41400000
.p2align 4
.Lsixteen:
    .long 0x41800000
.p2align 4
.LsixteenVec:
    .long 0x41800000, 0x41800000, 0x41800000, 0x41800000
.p2align 4
.Lquarter:
    .long 0x3e800000
.p2align 4
.LquarterVec:
    .long 0x3e800000, 0x3e800000, 0x3e800000, 0x3e800000
.p2align 4
.LonesVec:
    .long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
.p2align 4
.Lzero:
    .long 0, 0, 0, 0
.p2align 4
.LabsMask:
    .long 0x7fffffff, 0x7fffffff, 0x7fffffff, 0x7fffffff
.p2align 4
.LnibbleMask:
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
.p2align 4
.LalphaMask:
    .long 0xff000000, 0xff000000, 0xff000000, 0xff000000
.p2align 4
.LrgbMask:
    .long 0x00ffffff, 0x00ffffff, 0x00ffffff, 0x00ffffff
.p2align 4
.LshuffleB:
    .byte 0,4,8,12,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleG:
    .byte 1,5,9,13,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleR:
    .byte 2,6,10,14,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LshuffleA:
    .byte 3,7,11,15,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80
.p2align 4
.LhiTab:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3
    .byte 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    .byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
    .byte 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
    .byte 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
    .byte 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    .byte 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9
    .byte 10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10
    .byte 11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11
    .byte 12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12
    .byte 13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13
    .byte 14,14,14,14,14,14,14,14,14,14,14,14,14,14,14,14
    .byte 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
GNU_STACK
