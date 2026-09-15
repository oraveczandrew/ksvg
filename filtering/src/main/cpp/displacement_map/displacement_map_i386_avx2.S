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

.text
.intel_syntax noprefix

/*
 * i386 AVX2 Displacement Map kernel.
 *
 * Signature:
 *   void ksvgDisplacementMapApplyAvx2_i386(
 *       const int32_t* src, const int32_t* map, int32_t* dst,
 *       int width, int height, float scale, int xChannel, int yChannel);
 *
 * i386 SysV ABI, at function entry:
 *   4  src
 *   8  map
 *   12 dst
 *   16 width
 *   20 height
 *   24 scale
 *   28 xChannel
 *   32 yChannel
 *
 * Fast path assumes mapWidth == width and mapHeight == height, as does the
 * existing SIMD path.  Eight pixels are processed per iteration.  AVX2 does
 * all coordinate arithmetic and VPGATHERDD performs the source gather.
 *
 * The VPGATHERDD opcode is emitted as bytes because LLVM's integrated
 * assembler rejects the 32-bit-mode VSIB form even though IA-32 AVX2 supports
 * VSIB addressing with 32-bit effective addresses.
 */

.globl SYM(ksvgDisplacementMapApplyAvx2_i386)
TYPE(SYM(ksvgDisplacementMapApplyAvx2_i386), @function)
    SYM(ksvgDisplacementMapApplyAvx2_i386):
    mov     eax, DWORD PTR [esp+28]
    shl     eax, 2
    add     eax, DWORD PTR [esp+32]
    cmp     eax, 0
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k00)
    cmp     eax, 1
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k01)
    cmp     eax, 2
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k02)
    cmp     eax, 3
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k03)
    cmp     eax, 4
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k04)
    cmp     eax, 5
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k05)
    cmp     eax, 6
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k06)
    cmp     eax, 7
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k07)
    cmp     eax, 8
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k08)
    cmp     eax, 9
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k09)
    cmp     eax, 10
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k10)
    cmp     eax, 11
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k11)
    cmp     eax, 12
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k12)
    cmp     eax, 13
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k13)
    cmp     eax, 14
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k14)
    cmp     eax, 15
    je      SYM(ksvgDisplacementMapApplyAvx2_i386_k15)
    ret
    //      SIZE(SYM(ksvgDisplacementMapApplyAvx2_i386))

.set DM_MASK_OFF, .Ldm_mask_ff - .Ldm_const
.set DM_HALF_OFF, .Ldm_half - .Ldm_const
.set DM_255_OFF, .Ldm_255 - .Ldm_const
.set DM_INC_OFF, .Ldm_inc8 - .Ldm_const
.set DM_255F_OFF, .Ldm_255f - .Ldm_const
.set DM_HALFF_OFF, .Ldm_half_f - .Ldm_const

.macro KERNEL LABEL, SHIFTX, SHIFTY
    .p2align 5
    .globl SYM(\LABEL)
    TYPE(SYM(\LABEL), @function)
    HIDE_SYM(\LABEL)
    SYM(\LABEL):
    push    ebp
    push    ebx
    push    esi
    push    edi
    sub     esp, 32

        /* Save constant-pool address in callee-saved EBP. */
    call    .Lpc_\LABEL
.Lpc_\LABEL:
    pop     ebp
    .set DM_PC_OFF_\LABEL, .Ldm_const - .Lpc_\LABEL
    add     ebp, OFFSET DM_PC_OFF_\LABEL

        /* After prologue + locals, arguments are at +52 .. +80. */
    mov     esi, DWORD PTR [esp+52] /* src */
    mov     edi, DWORD PTR [esp+56] /* map */
    mov     ebx, DWORD PTR [esp+60] /* dst */
    mov     ecx, DWORD PTR [esp+64] /* width */
    mov     edx, DWORD PTR [esp+68] /* height */

    test    ecx, ecx
    jle     .Ldone_\LABEL
    test    edx, edx
    jle     .Ldone_\LABEL

    vmovdqa ymm1, YMMWORD PTR [ebp+DM_MASK_OFF]
    vmovups ymm2, YMMWORD PTR [ebp+DM_HALF_OFF]
    vmovups ymm3, YMMWORD PTR [ebp+DM_255_OFF]
    vmovss  xmm4, DWORD PTR [esp+72]
    vbroadcastss ymm4, xmm4

    mov     DWORD PTR [esp+4], 0 /* y */
    xor     eax, eax /* x */

.Lrow_\LABEL:
    xor     eax, eax

.Lvec_\LABEL:
        /* Enter vector path only while x + 8 <= width. */
    mov     edx, ecx
    sub     edx, 8
    cmp     eax, edx
    jg      .Ltail_\LABEL

    vmovdqu ymm5, YMMWORD PTR [edi]
    vmovdqa ymm6, ymm5

    vpsrld  ymm6, ymm6, \SHIFTX
    vpand   ymm6, ymm6, ymm1
    vpsrld  ymm5, ymm5, \SHIFTY
    vpand   ymm5, ymm5, ymm1

        /* dx = (int)(scale * ((channel / 255.0f) - 0.5f)). */
    vcvtdq2ps ymm6, ymm6
    vdivps  ymm6, ymm6, ymm3
    vsubps  ymm6, ymm6, ymm2
    vmulps  ymm6, ymm6, ymm4
    vcvttps2dq ymm6, ymm6

        /* dy */
    vcvtdq2ps ymm5, ymm5
    vdivps  ymm5, ymm5, ymm3
    vsubps  ymm5, ymm5, ymm2
    vmulps  ymm5, ymm5, ymm4
    vcvttps2dq ymm5, ymm5

        /* Old floating constants are dead.  Reuse the registers for clamp/index. */
    vpxor   ymm1, ymm1, ymm1 /* zero */
    vpcmpeqd ymm7, ymm7, ymm7
    vpsrld  ymm7, ymm7, 31 /* 1 */

    vmovd   xmm2, ecx
    vpbroadcastd ymm2, xmm2
    vpsubd  ymm2, ymm2, ymm7 /* width - 1 */
    vmovd   xmm3, DWORD PTR [esp+68]
    vpbroadcastd ymm3, DWORD PTR [esp+68]
    vpsubd  ymm3, ymm3, ymm7 /* height - 1 */

        /* sx = clamp(x + dx, 0, width - 1). */
    vmovd   xmm0, eax
    vpbroadcastd ymm0, xmm0
    vpaddd  ymm0, ymm0, YMMWORD PTR [ebp+DM_INC_OFF]
    vpaddd  ymm6, ymm0, ymm6
    vpmaxsd ymm6, ymm6, ymm1
    vpminsd ymm6, ymm6, ymm2

        /* sy = clamp(y + dy, 0, height - 1). */
    vpbroadcastd ymm0, DWORD PTR [esp+4]
    vpaddd  ymm0, ymm0, YMMWORD PTR [ebp+DM_INC_OFF]
    vpaddd  ymm5, ymm0, ymm5
    vpmaxsd ymm5, ymm5, ymm1
    vpminsd ymm5, ymm5, ymm3

        /* index = sy * width + sx (in pixels). */
    vmovd   xmm2, ecx
    vpbroadcastd ymm2, xmm2
    vpmulld ymm5, ymm5, ymm2
    vpaddd  ymm5, ymm5, ymm6

        /*
         * VPGATHERDD ymm0, [esi + ymm5*4], ymm1
         * Encoding: VEX.256.66.0F38.W0 90 /r with
         *   dst = ymm0, mask = ymm1, VSIB index = ymm5, base = esi.
         *
         * LLVM IAS does not accept this form in 32-bit mode, therefore the
         * encoding is emitted explicitly. objdump decodes it as expected.
         */
    .byte 0xc4, 0xe2, 0x75, 0x90, 0x04, 0xae
    vmovdqu YMMWORD PTR [ebx], ymm0

    add     eax, 8
    add     edi, 32
    add     ebx, 32
    jmp     .Lvec_\LABEL

.Ltail_\LABEL:
        /* x is in EAX, y is in [esp+4].  Tail is at most 7 pixels. */
    cmp     eax, ecx
    jge     .Lnextrow_\LABEL

.Ltail_pixel_\LABEL:
    mov     DWORD PTR [esp+0], eax /* x */
    mov     edx, DWORD PTR [edi]
    mov     DWORD PTR [esp+16], edx /* mapPixel */

        /* dx */
    mov     edx, DWORD PTR [esp+16]
    shr     edx, \SHIFTX
    and     edx, 0xff
    cvtsi2ss xmm0, edx
    divss   xmm0, DWORD PTR [ebp+DM_255F_OFF]
    subss   xmm0, DWORD PTR [ebp+DM_HALFF_OFF]
    mulss   xmm0, DWORD PTR [esp+72]
    cvttss2si edx, xmm0
    mov     DWORD PTR [esp+8], edx

        /* dy */
    mov     edx, DWORD PTR [esp+16]
    shr     edx, \SHIFTY
    and     edx, 0xff
    cvtsi2ss xmm0, edx
    divss   xmm0, DWORD PTR [ebp+DM_255F_OFF]
    subss   xmm0, DWORD PTR [ebp+DM_HALFF_OFF]
    mulss   xmm0, DWORD PTR [esp+72]
    cvttss2si edx, xmm0
    mov     DWORD PTR [esp+12], edx

        /* sx = clamp(x + dx, 0, width - 1). */
    mov     edx, DWORD PTR [esp+0]
    add     edx, DWORD PTR [esp+8]
    test    edx, edx
    jns     .Lsx_nonneg_\LABEL
    xor     edx, edx
.Lsx_nonneg_\LABEL:
    cmp     edx, ecx
    jl      .Lsx_ok_\LABEL
    lea     edx, [ecx-1]
.Lsx_ok_\LABEL:
    mov     DWORD PTR [esp+20], edx

        /* sy = clamp(y + dy, 0, height - 1). */
    mov     edx, DWORD PTR [esp+4]
    add     edx, DWORD PTR [esp+12]
    test    edx, edx
    jns     .Lsy_nonneg_\LABEL
    xor     edx, edx
.Lsy_nonneg_\LABEL:
    mov     esi, DWORD PTR [esp+68]
    dec     esi
    cmp     edx, esi
    jl      .Lsy_ok_\LABEL
    mov     edx, esi
.Lsy_ok_\LABEL:

        /* src[(sy * width + sx)] */
    imul    edx, ecx
    add     edx, DWORD PTR [esp+20]
    mov     esi, DWORD PTR [esp+52]
    mov     esi, DWORD PTR [esi+edx*4]
    mov     DWORD PTR [ebx], esi

    inc     eax
    add     edi, 4
    add     ebx, 4
    cmp     eax, ecx
    jl      .Ltail_pixel_\LABEL

.Lnextrow_\LABEL:
    mov     esi, DWORD PTR [esp+52] /* restore src base after scalar tail */
    inc     DWORD PTR [esp+4]
    mov     edx, DWORD PTR [esp+4]
    cmp     edx, DWORD PTR [esp+68]
    jl      .Lrow_\LABEL

.Ldone_\LABEL:
    vzeroupper
    add     esp, 32
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret
    //      SIZE(SYM(\LABEL))
.endm

    KERNEL ksvgDisplacementMapApplyAvx2_i386_k00, 16, 16
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k01, 16, 8
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k02, 16, 0
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k03, 16, 24
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k04, 8, 16
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k05, 8, 8
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k06, 8, 0
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k07, 8, 24
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k08, 0, 16
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k09, 0, 8
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k10, 0, 0
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k11, 0, 24
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k12, 24, 16
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k13, 24, 8
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k14, 24, 0
    KERNEL ksvgDisplacementMapApplyAvx2_i386_k15, 24, 24

.p2align 5
.Ldm_const:
.Ldm_mask_ff:
.long 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
.Ldm_half:
.float 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5
.Ldm_255:
.float 255.0, 255.0, 255.0, 255.0, 255.0, 255.0, 255.0, 255.0
.Ldm_inc8:
.long 0, 1, 2, 3, 4, 5, 6, 7
.Ldm_255f:
.float 255.0
.Ldm_half_f:
.float 0.5

GNU_STACK
