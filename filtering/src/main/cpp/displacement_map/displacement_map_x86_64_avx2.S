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
 * void ksvgDisplacementMapApplyAvx2(
 *     const jint* src, const jint* map, jint* dst, jint width, jint height,
 *     jfloat scale, jint xChannel, jint yChannel);
 *
 * x86-64 System V ABI:
 *   rdi = src, rsi = map, rdx = dst, ecx = width, r8d = height
 *   xmm0 = scale, r9d = xChannel
 *   stack: yChannel ([rsp+8] at entry)
 */
.globl SYM(ksvgDisplacementMapApplyAvx2)
TYPE(SYM(ksvgDisplacementMapApplyAvx2), @function)
SYM(ksvgDisplacementMapApplyAvx2):
    cmp     r9d, 3
    ja      .Lbad
    mov     eax, DWORD PTR [rsp+8]
    cmp     eax, 3
    ja      .Lbad
    lea     eax, [rax+r9*4]
    lea     r10, [rip+.Ldm_jt]
    movsxd  rax, DWORD PTR [r10+rax*4]
    add     rax, r10
    jmp     rax

.Lbad:
    ret

.macro KERNEL LABEL, XSHIFT, YSHIFT
.p2align 5
\LABEL:
    test    ecx, ecx
    jle     .Ldone_\@
    test    r8d, r8d
    jle     .Ldone_\@

    vmovaps xmm7, xmm0
    vbroadcastss ymm15, xmm0
    vmovdqa ymm14, YMMWORD PTR [rip+.Ldm_gather_mask]
    vmovdqa ymm1, YMMWORD PTR [rip+.Ldm_mask]
    vmovups ymm13, YMMWORD PTR [rip+.Ldm_255v]
    vmovups ymm12, YMMWORD PTR [rip+.Ldm_halfv]
    vmovdqa ymm11, YMMWORD PTR [rip+.Ldm_inc8]
    vmovdqa ymm10, YMMWORD PTR [rip+.Ldm_one8]
    vpxor   ymm9, ymm9, ymm9
    vpbroadcastd ymm4, ecx
    vpbroadcastd ymm8, r8d
    vpsubd  ymm2, ymm4, ymm10
    vpsubd  ymm3, ymm8, ymm10
    xor     r10d, r10d

.Lrow_\@:
    xor     r11d, r11d

.Lvec_\@:
    lea     eax, [r11d+8]
    cmp     eax, ecx
    jg      .Ltail_\@

    vmovdqu ymm0, YMMWORD PTR [rsi]

    vmovdqa ymm1, ymm0
    vpsrld  ymm1, ymm1, \XSHIFT
    vpand   ymm1, ymm1, YMMWORD PTR [rip+.Ldm_mask]
    vcvtdq2ps ymm1, ymm1
    vdivps  ymm1, ymm1, ymm13
    vsubps  ymm1, ymm1, ymm12
    vmulps  ymm1, ymm1, ymm15
    vcvttps2dq ymm1, ymm1

    vmovdqa ymm5, ymm0
    vpsrld  ymm5, ymm5, \YSHIFT
    vpand   ymm5, ymm5, YMMWORD PTR [rip+.Ldm_mask]
    vcvtdq2ps ymm5, ymm5
    vdivps  ymm5, ymm5, ymm13
    vsubps  ymm5, ymm5, ymm12
    vmulps  ymm5, ymm5, ymm15
    vcvttps2dq ymm5, ymm5

    /* sx = clamp(x + dx, 0, width - 1). */
    vpbroadcastd ymm0, r11d
    vpaddd  ymm0, ymm0, ymm11
    vpaddd  ymm6, ymm0, ymm1
    vpmaxsd ymm6, ymm6, ymm9
    vpminsd ymm6, ymm6, ymm2

    /* sy = clamp(y + dy, 0, height - 1). */
    vpbroadcastd ymm0, r10d
    vpaddd  ymm0, ymm0, ymm5
    vpmaxsd ymm5, ymm0, ymm9
    vpminsd ymm5, ymm5, ymm3

    /* index = sy * width + sx. */
    vpmulld ymm5, ymm5, ymm4
    vpaddd  ymm5, ymm5, ymm6

    /* VPGATHERDD clears its mask; keep the reusable all-ones mask in YMM14. */
    vmovdqa ymm1, ymm14
    vpgatherdd ymm0, [rdi+ymm5*4], ymm1
    vmovdqu YMMWORD PTR [rdx], ymm0

    add     r11d, 8
    add     rsi, 32
    add     rdx, 32
    jmp     .Lvec_\@

.Ltail_\@:
    cmp     r11d, ecx
    jge     .Lnextrow_\@

.Ltail_pixel_\@:
    mov     eax, DWORD PTR [rsi]

    mov     r9d, eax
    shr     r9d, \XSHIFT
    and     r9d, 255
    cvtsi2ss xmm0, r9d
    divss   xmm0, DWORD PTR [rip+.Ldm_255s]
    subss   xmm0, DWORD PTR [rip+.Ldm_halfs]
    mulss   xmm0, xmm7
    cvttss2si r9d, xmm0

    mov     eax, DWORD PTR [rsi]
    shr     eax, \YSHIFT
    and     eax, 255
    cvtsi2ss xmm0, eax
    divss   xmm0, DWORD PTR [rip+.Ldm_255s]
    subss   xmm0, DWORD PTR [rip+.Ldm_halfs]
    mulss   xmm0, xmm7
    cvttss2si eax, xmm0

    add     r9d, r11d
    test    r9d, r9d
    jns     .Lsx_nonneg_\@
    xor     r9d, r9d
.Lsx_nonneg_\@:
    cmp     r9d, ecx
    jl      .Lsx_ok_\@
    lea     r9d, [ecx-1]
.Lsx_ok_\@:

    add     eax, r10d
    test    eax, eax
    jns     .Lsy_nonneg_\@
    xor     eax, eax
.Lsy_nonneg_\@:
    cmp     eax, r8d
    jl      .Lsy_ok_\@
    lea     eax, [r8d-1]
.Lsy_ok_\@:

    imul    eax, ecx
    add     eax, r9d
    mov     eax, DWORD PTR [rdi+rax*4]
    mov     DWORD PTR [rdx], eax

    inc     r11d
    add     rsi, 4
    add     rdx, 4
    cmp     r11d, ecx
    jl      .Ltail_pixel_\@

.Lnextrow_\@:
    inc     r10d
    cmp     r10d, r8d
    jl      .Lrow_\@

.Ldone_\@:
    vzeroupper
    ret
.endm

    // Channel shifts for ARGB_8888 (little-endian): 0=R(16), 1=G(8), 2=B(0),
    // 3=A(24). Row = xChannel, column = yChannel (index = y + 4*x).
    KERNEL .Ldm_k00, 16, 16
    KERNEL .Ldm_k01, 16, 8
    KERNEL .Ldm_k02, 16, 0
    KERNEL .Ldm_k03, 16, 24
    KERNEL .Ldm_k04, 8, 16
    KERNEL .Ldm_k05, 8, 8
    KERNEL .Ldm_k06, 8, 0
    KERNEL .Ldm_k07, 8, 24
    KERNEL .Ldm_k08, 0, 16
    KERNEL .Ldm_k09, 0, 8
    KERNEL .Ldm_k10, 0, 0
    KERNEL .Ldm_k11, 0, 24
    KERNEL .Ldm_k12, 24, 16
    KERNEL .Ldm_k13, 24, 8
    KERNEL .Ldm_k14, 24, 0
    KERNEL .Ldm_k15, 24, 24

.p2align 5
.Ldm_jt:
.long .Ldm_k00-.Ldm_jt, .Ldm_k01-.Ldm_jt, .Ldm_k02-.Ldm_jt, .Ldm_k03-.Ldm_jt
.long .Ldm_k04-.Ldm_jt, .Ldm_k05-.Ldm_jt, .Ldm_k06-.Ldm_jt, .Ldm_k07-.Ldm_jt
.long .Ldm_k08-.Ldm_jt, .Ldm_k09-.Ldm_jt, .Ldm_k10-.Ldm_jt, .Ldm_k11-.Ldm_jt
.long .Ldm_k12-.Ldm_jt, .Ldm_k13-.Ldm_jt, .Ldm_k14-.Ldm_jt, .Ldm_k15-.Ldm_jt

.p2align 5
.Ldm_mask:
.long 255, 255, 255, 255, 255, 255, 255, 255
.Ldm_gather_mask:
.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
.long 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
.Ldm_inc8:
.long 0, 1, 2, 3, 4, 5, 6, 7
.Ldm_one8:
.long 1, 1, 1, 1, 1, 1, 1, 1
.Ldm_255v:
.float 255.0, 255.0, 255.0, 255.0, 255.0, 255.0, 255.0, 255.0
.Ldm_halfv:
.float 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5
.Ldm_255s:
.float 255.0
.Ldm_halfs:
.float 0.5
