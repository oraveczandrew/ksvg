#ifdef __APPLE__
#define SYM(x) _##x
#define TYPE(x,y)
#define SIZE(x)
#else
#define SYM(x) x
#define TYPE(x,y) .type x,y
#define SIZE(x) .size x,.-x
#endif

        .text
        .intel_syntax noprefix

/*
 * i386 SSSE3 Displacement Map kernel.
 *
 * Signature:
 *   void ksvgDisplacementMapApplySsse3_i386(
 *       const int32_t* src, const int32_t* map, int32_t* dst,
 *       int width, int height, float scale, int xChannel, int yChannel);
 *
 * i386 SysV ABI at entry:
 *   4  src, 8 map, 12 dst, 16 width, 20 height,
 *   24 scale, 28 xChannel, 32 yChannel
 *
 * The fast path assumes map dimensions equal image dimensions, exactly as
 * the existing NEON/x86 SIMD dispatch does. Four pixels are processed per
 * iteration. SSSE3 PSHUFB extracts the requested map channels directly.
 * Source pixels remain scalar because SSSE3 has no integer gather.
 */

        .globl  SYM(ksvgDisplacementMapApplySsse3_i386)
        TYPE(SYM(ksvgDisplacementMapApplySsse3_i386), @function)
SYM(ksvgDisplacementMapApplySsse3_i386):
        mov     eax, DWORD PTR [esp+28]
        shl     eax, 2
        add     eax, DWORD PTR [esp+32]
        cmp     eax, 15
        ja      .Lbad_dispatch

        mov     edx, eax
        cmp     edx, 0
        je      .Ldm_k00
        cmp     edx, 1
        je      .Ldm_k01
        cmp     edx, 2
        je      .Ldm_k02
        cmp     edx, 3
        je      .Ldm_k03
        cmp     edx, 4
        je      .Ldm_k04
        cmp     edx, 5
        je      .Ldm_k05
        cmp     edx, 6
        je      .Ldm_k06
        cmp     edx, 7
        je      .Ldm_k07
        cmp     edx, 8
        je      .Ldm_k08
        cmp     edx, 9
        je      .Ldm_k09
        cmp     edx, 10
        je      .Ldm_k10
        cmp     edx, 11
        je      .Ldm_k11
        cmp     edx, 12
        je      .Ldm_k12
        cmp     edx, 13
        je      .Ldm_k13
        cmp     edx, 14
        je      .Ldm_k14
        jmp     .Ldm_k15

.Lbad_dispatch:
        ret

/* Jump table is used only once per call; hot row/column loops are branch-light. */
/* Literal pool / mask offsets. Each kernel computes its PIC base once. */
.set DM_INC4_OFF,  .Ldm_inc4 - .Ldm_const
.set DM_FOUR_OFF,  .Ldm_four - .Ldm_const
.set DM_ZERO_OFF,  .Ldm_zero - .Ldm_const
.set DM_255V_OFF,  .Ldm_255v - .Ldm_const
.set DM_HALFV_OFF, .Ldm_halfv - .Ldm_const
.set DM_255S_OFF,  .Ldm_255s - .Ldm_const
.set DM_HALFS_OFF, .Ldm_halfs - .Ldm_const
.set DM_MASK_B_OFF, .Ldm_mask_b - .Ldm_const
.set DM_MASK_G_OFF, .Ldm_mask_g - .Ldm_const
.set DM_MASK_R_OFF, .Ldm_mask_r - .Ldm_const
.set DM_MASK_A_OFF, .Ldm_mask_a - .Ldm_const

.macro KERNEL LABEL, XMASK, YMASK, XSHIFT, YSHIFT
        .p2align 4
        TYPE(SYM(\LABEL), @function)
SYM(\LABEL):
        push    ebp
        push    ebx
        push    esi
        push    edi
        sub     esp, 48

        /* PIC literal-pool base. Keep it in EBP; width lives in [esp+32]. */
        call    .Lpc_\LABEL
.Lpc_\LABEL:
        pop     ebp
        .set DM_PC_OFF_\LABEL, .Ldm_const - .Lpc_\LABEL
        add     ebp, OFFSET DM_PC_OFF_\LABEL

        /* Original args are +68..+96 after prologue. */
        mov     esi, DWORD PTR [esp+68]       /* src */
        mov     edi, DWORD PTR [esp+72]       /* map */
        mov     ebx, DWORD PTR [esp+76]       /* dst */
        mov     eax, DWORD PTR [esp+80]
        mov     DWORD PTR [esp+32], eax                   /* width */
        mov     eax, DWORD PTR [esp+80]
        dec     eax
        mov     DWORD PTR [esp+36], eax        /* width-1 */
        sub     eax, 3
        mov     DWORD PTR [esp+44], eax        /* width-4 */
        mov     eax, DWORD PTR [esp+84]
        dec     eax
        mov     DWORD PTR [esp+40], eax        /* height-1 */

        /* Scale broadcast. */
        movss   xmm7, DWORD PTR [esp+88]
        shufps  xmm7, xmm7, 0

        test    DWORD PTR [esp+32], -1
        jle     .Ldone_\LABEL
        test    DWORD PTR [esp+84], -1
        jle     .Ldone_\LABEL

        /* Y is EDX, X is ECX. EAX remains the gather scratch register. */
        xor     edx, edx
.Lrow_\LABEL:
        xor     ecx, ecx
        movdqa  xmm4, XMMWORD PTR [ebp+DM_INC4_OFF]
        movd    xmm5, edx
        pshufd  xmm5, xmm5, 0

.Lvec_\LABEL:
        cmp     ecx, DWORD PTR [esp+44]
        jg      .Ltail_\LABEL

        movdqu  xmm0, XMMWORD PTR [edi]

        /* dx = (int)(scale * ((channel / 255.0f) - 0.5f)). */
        movdqa  xmm1, xmm0
        pshufb  xmm1, XMMWORD PTR [ebp+\XMASK]
        cvtdq2ps xmm1, xmm1
        divps   xmm1, XMMWORD PTR [ebp+DM_255V_OFF]
        subps   xmm1, XMMWORD PTR [ebp+DM_HALFV_OFF]
        mulps   xmm1, xmm7
        cvttps2dq xmm1, xmm1

        /* dy */
        movdqa  xmm2, xmm0
        pshufb  xmm2, XMMWORD PTR [ebp+\YMASK]
        cvtdq2ps xmm2, xmm2
        divps   xmm2, XMMWORD PTR [ebp+DM_255V_OFF]
        subps   xmm2, XMMWORD PTR [ebp+DM_HALFV_OFF]
        mulps   xmm2, xmm7
        cvttps2dq xmm2, xmm2

        /* sx = clamp(x + dx, 0, width-1). */
        movdqa  xmm6, xmm4
        paddd   xmm6, xmm1
        movdqa  xmm3, XMMWORD PTR [esp+36]
        movdqa  xmm1, xmm6
        pcmpgtd xmm6, xmm3                 /* candidate > max */
        pand    xmm3, xmm6                 /* max where needed */
        pandn   xmm6, xmm1                 /* candidate otherwise */
        por     xmm3, xmm6
        movdqa  xmm1, xmm3
        pxor    xmm6, xmm6
        pcmpgtd xmm6, xmm1                 /* 0 > candidate => negative */
        pandn   xmm6, xmm1                 /* max(0,candidate) */
        movdqa  xmm1, xmm6
        movdqu  XMMWORD PTR [esp+0], xmm1

        /* sy = clamp(y + dy, 0, height-1). */
        movdqa  xmm6, xmm5
        paddd   xmm6, xmm2
        movdqa  xmm3, XMMWORD PTR [esp+40]
        movdqa  xmm2, xmm6
        pcmpgtd xmm6, xmm3                 /* candidate > max */
        pand    xmm3, xmm6
        pandn   xmm6, xmm2
        por     xmm3, xmm6
        movdqa  xmm2, xmm3
        pxor    xmm6, xmm6
        pcmpgtd xmm6, xmm2                 /* negative */
        pandn   xmm6, xmm2
        movdqu  XMMWORD PTR [esp+16], xmm6

        /* Four scalar source gathers. Width is a stack local, so EBP can hold
         * the literal-pool base without sacrificing a GPR. */
        mov     eax, DWORD PTR [esp+16]
        imul    eax, DWORD PTR [esp+32]
        add     eax, DWORD PTR [esp+0]
        mov     eax, DWORD PTR [esi+eax*4]
        mov     DWORD PTR [ebx], eax

        mov     eax, DWORD PTR [esp+20]
        imul    eax, DWORD PTR [esp+32]
        add     eax, DWORD PTR [esp+4]
        mov     eax, DWORD PTR [esi+eax*4]
        mov     DWORD PTR [ebx+4], eax

        mov     eax, DWORD PTR [esp+24]
        imul    eax, DWORD PTR [esp+32]
        add     eax, DWORD PTR [esp+8]
        mov     eax, DWORD PTR [esi+eax*4]
        mov     DWORD PTR [ebx+8], eax

        mov     eax, DWORD PTR [esp+28]
        imul    eax, DWORD PTR [esp+32]
        add     eax, DWORD PTR [esp+12]
        mov     eax, DWORD PTR [esi+eax*4]
        mov     DWORD PTR [ebx+12], eax

        add     ecx, 4
        add     edi, 16
        add     ebx, 16
        paddd   xmm4, XMMWORD PTR [ebp+DM_FOUR_OFF]
        jmp     .Lvec_\LABEL

.Ltail_\LABEL:
        cmp     ecx, DWORD PTR [esp+32]
        jge     .Lnextrow_\LABEL

.Ltail_pixel_\LABEL:
        mov     eax, DWORD PTR [edi]

        /* dx */
        mov     DWORD PTR [esp+20], eax
        mov     eax, DWORD PTR [esp+20]
        shr     eax, \XSHIFT
        and     eax, 255
        cvtsi2ss xmm0, eax
        divss   xmm0, DWORD PTR [ebp+DM_255S_OFF]
        subss   xmm0, DWORD PTR [ebp+DM_HALFS_OFF]
        mulss   xmm0, DWORD PTR [esp+88]
        cvttss2si eax, xmm0
        mov     DWORD PTR [esp+24], eax

        /* dy */
        mov     eax, DWORD PTR [esp+20]
        shr     eax, \YSHIFT
        and     eax, 255
        cvtsi2ss xmm0, eax
        divss   xmm0, DWORD PTR [ebp+DM_255S_OFF]
        subss   xmm0, DWORD PTR [ebp+DM_HALFS_OFF]
        mulss   xmm0, DWORD PTR [esp+88]
        cvttss2si eax, xmm0
        mov     DWORD PTR [esp+28], eax

        /* sx = clamp(x + dx, 0, width-1). */
        mov     eax, ecx
        add     eax, DWORD PTR [esp+24]
        test    eax, eax
        jns     .Lsx_nonneg_\LABEL
        xor     eax, eax
.Lsx_nonneg_\LABEL:
        cmp     eax, DWORD PTR [esp+32]
        jl      .Lsx_ok_\LABEL
        lea     eax, [esp+32]
        mov     eax, DWORD PTR [eax]
        dec     eax
.Lsx_ok_\LABEL:
        mov     DWORD PTR [esp+4], eax

        /* sy = clamp(y + dy, 0, height-1). */
        mov     eax, edx
        add     eax, DWORD PTR [esp+28]
        test    eax, eax
        jns     .Lsy_nonneg_\LABEL
        xor     eax, eax
.Lsy_nonneg_\LABEL:
        cmp     eax, DWORD PTR [esp+40]
        jle     .Lsy_ok_\LABEL
        mov     eax, DWORD PTR [esp+40]
.Lsy_ok_\LABEL:

        imul    eax, DWORD PTR [esp+32]
        add     eax, DWORD PTR [esp+4]
        mov     eax, DWORD PTR [esi+eax*4]
        mov     DWORD PTR [ebx], eax

        inc     ecx
        add     edi, 4
        add     ebx, 4
        cmp     ecx, DWORD PTR [esp+32]
        jl      .Ltail_pixel_\LABEL

.Lnextrow_\LABEL:
        inc     edx
        cmp     edx, DWORD PTR [esp+40]
        jle     .Lrow_\LABEL

.Ldone_\LABEL:
        add     esp, 48
        pop     edi
        pop     esi
        pop     ebx
        pop     ebp
        ret
       // SIZE(SYM(\LABEL))
.endm

        KERNEL .Ldm_k00, DM_MASK_B_OFF, DM_MASK_B_OFF, 0, 0
        KERNEL .Ldm_k01, DM_MASK_B_OFF, DM_MASK_G_OFF, 0, 8
        KERNEL .Ldm_k02, DM_MASK_B_OFF, DM_MASK_R_OFF, 0, 16
        KERNEL .Ldm_k03, DM_MASK_B_OFF, DM_MASK_A_OFF, 0, 24
        KERNEL .Ldm_k04, DM_MASK_G_OFF, DM_MASK_B_OFF, 8, 0
        KERNEL .Ldm_k05, DM_MASK_G_OFF, DM_MASK_G_OFF, 8, 8
        KERNEL .Ldm_k06, DM_MASK_G_OFF, DM_MASK_R_OFF, 8, 16
        KERNEL .Ldm_k07, DM_MASK_G_OFF, DM_MASK_A_OFF, 8, 24
        KERNEL .Ldm_k08, DM_MASK_R_OFF, DM_MASK_B_OFF, 16, 0
        KERNEL .Ldm_k09, DM_MASK_R_OFF, DM_MASK_G_OFF, 16, 8
        KERNEL .Ldm_k10, DM_MASK_R_OFF, DM_MASK_R_OFF, 16, 16
        KERNEL .Ldm_k11, DM_MASK_R_OFF, DM_MASK_A_OFF, 16, 24
        KERNEL .Ldm_k12, DM_MASK_A_OFF, DM_MASK_B_OFF, 24, 0
        KERNEL .Ldm_k13, DM_MASK_A_OFF, DM_MASK_G_OFF, 24, 8
        KERNEL .Ldm_k14, DM_MASK_A_OFF, DM_MASK_R_OFF, 24, 16
        KERNEL .Ldm_k15, DM_MASK_A_OFF, DM_MASK_A_OFF, 24, 24

        .p2align 4
.Ldm_const:
.Ldm_inc4:
        .long 0,1,2,3
.Ldm_four:
        .long 4,4,4,4
.Ldm_zero:
        .long 0,0,0,0
.Ldm_255v:
        .float 255.0,255.0,255.0,255.0
.Ldm_halfv:
        .float 0.5,0.5,0.5,0.5
.Ldm_255s:
        .float 255.0
.Ldm_halfs:
        .float 0.5
        .p2align 4
.Ldm_mask_b:
        .byte 0,0x80,0x80,0x80, 4,0x80,0x80,0x80, 8,0x80,0x80,0x80, 12,0x80,0x80,0x80
.Ldm_mask_g:
        .byte 1,0x80,0x80,0x80, 5,0x80,0x80,0x80, 9,0x80,0x80,0x80, 13,0x80,0x80,0x80
.Ldm_mask_r:
        .byte 2,0x80,0x80,0x80, 6,0x80,0x80,0x80, 10,0x80,0x80,0x80, 14,0x80,0x80,0x80
.Ldm_mask_a:
        .byte 3,0x80,0x80,0x80, 7,0x80,0x80,0x80, 11,0x80,0x80,0x80, 15,0x80,0x80,0x80

        .section .note.GNU-stack,"",@progbits
