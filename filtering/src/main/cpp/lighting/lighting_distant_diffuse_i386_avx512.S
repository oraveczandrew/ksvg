/*
 * Copyright 2026 András Oravecz <info@oandras.hu>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* x86-32 AVX-512F distant-light diffuse kernel. cdecl ABI. */
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
.code32
.p2align 6
.globl SYM(ksvgLightingDistantDiffuseRowAvx512)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx512), @function)
SYM(ksvgLightingDistantDiffuseRowAvx512):
    push    %ebp
    mov     %esp, %ebp
    push    %esi
    push    %edi
    push    %ebx
    sub     $512, %esp

    mov     8(%ebp), %esi
    mov     12(%ebp), %edi
    mov     16(%ebp), %ebx
    mov     24(%ebp), %ecx
    mov     28(%ebp), %eax

    // --- Constant Initialization ---
    mov     $0x3f800000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %zmm0
    vmovaps %zmm0, 256(%esp)   # 256(esp) = 1.0

    mov     $0x40000000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %zmm6  # zmm6 = 2.0

    mov     $0x3fc00000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %zmm0
    vmovaps %zmm0, 320(%esp)   # 320(esp) = 1.5

    // Precalculate Scales
    vmovss  256(%esp), %xmm0
    vdivss  0(%eax), %xmm0, %xmm1
    vbroadcastss %xmm1, %zmm1
    vmovaps %zmm1, 0(%esp)     # 0(esp) = scaleX

    vdivss  4(%eax), %xmm0, %xmm1
    vbroadcastss %xmm1, %zmm1
    vmovaps %zmm1, 64(%esp)    # 64(esp) = scaleY

    // Apply ss
    vbroadcastss 36(%eax), %zmm0
    vmulps  0(%esp), %zmm0, %zmm1
    vmovaps %zmm1, 0(%esp)
    vmulps  64(%esp), %zmm0, %zmm1
    vmovaps %zmm1, 64(%esp)

    // k -> 128(esp)
    vbroadcastss 8(%eax), %zmm0
    vmovaps %zmm0, 128(%esp)

    // lx, ly, lz -> zmm3, zmm4, zmm5
    vbroadcastss 12(%eax), %zmm3
    vbroadcastss 16(%eax), %zmm4
    vbroadcastss 20(%eax), %zmm5

    // lr, lg, lb -> stack
    vbroadcastss 24(%eax), %zmm0
    vmovaps %zmm0, 384(%esp)   # lr
    vbroadcastss 28(%eax), %zmm0
    vmovaps %zmm0, 448(%esp)   # lg
    vbroadcastss 32(%eax), %zmm0
    vmovaps %zmm0, 192(%esp)   # lb

    mov     20(%ebp), %edx     # dst pointer

.Lloop:
    test    %ecx, %ecx
    jz      .Ldone

    // --- Sobel X (dx) ---
    // sumR = rT + 2*rM + rB
    vmovdqu32 0(%esi), %zmm0
    vmovdqu32 64(%esi), %zmm1
    valignd $2, %zmm1, %zmm0, %zmm7 # rT

    vmovdqu32 0(%edi), %zmm0
    vmovdqu32 64(%edi), %zmm1
    valignd $2, %zmm1, %zmm0, %zmm1 # rM
    vmulps  %zmm6, %zmm1, %zmm1
    vaddps  %zmm1, %zmm7, %zmm7     # rT + 2*rM

    vmovdqu32 0(%ebx), %zmm0
    vmovdqu32 64(%ebx), %zmm1
    valignd $2, %zmm1, %zmm0, %zmm1 # rB
    vaddps  %zmm1, %zmm7, %zmm7     # sumR

    // sumL = lT + 2*lM + lB
    vmovdqu32 0(%esi), %zmm0        # lT
    vmovdqu32 0(%edi), %zmm1        # lM
    vmulps  %zmm6, %zmm1, %zmm1
    vaddps  %zmm1, %zmm0, %zmm0     # lT + 2*lM
    vmovdqu32 0(%ebx), %zmm1        # lB
    vaddps  %zmm1, %zmm0, %zmm0     # sumL

    vsubps  %zmm0, %zmm7, %zmm7
    vmulps  0(%esp), %zmm7, %zmm7   # dx (nx numerator * ss * scaleX)
    vmovaps %zmm7, 448(%esp)        # store nx to stack (reuse lg slot temporarily)

    // --- Sobel Y (dy) ---
    // sumB = lB + 2*mB + rB
    vmovdqu32 0(%ebx), %zmm0        # lB
    vmovdqu32 64(%ebx), %zmm2       # 16..31
    valignd $1, %zmm2, %zmm0, %zmm1 # mB
    vmulps  %zmm6, %zmm1, %zmm1
    vaddps  %zmm0, %zmm1, %zmm1     # 2*mB + lB
    valignd $2, %zmm2, %zmm0, %zmm0 # rB
    vaddps  %zmm1, %zmm0, %zmm0     # sumB

    // sumT = lT + 2*mT + rT
    vmovdqu32 0(%esi), %zmm1        # lT
    vmovdqu32 64(%esi), %zmm2
    valignd $1, %zmm2, %zmm1, %zmm7 # mT
    vmulps  %zmm6, %zmm7, %zmm7
    vaddps  %zmm1, %zmm7, %zmm7     # 2*mT + lT
    valignd $2, %zmm2, %zmm1, %zmm1 # rT
    vaddps  %zmm7, %zmm1, %zmm1     # sumT

    vsubps  %zmm1, %zmm0, %zmm0
    vmulps  64(%esp), %zmm0, %zmm0  # dy (ny)

    vmovaps 448(%esp), %zmm7        # reload nx (was stored in lg slot)
    vbroadcastss 28(%eax), %zmm1    # reload lg
    vmovaps %zmm1, 448(%esp)        # restore lg slot

    // n = (-dx, -dy, 1)
    vpxorq  %zmm1, %zmm1, %zmm1
    vsubps  %zmm7, %zmm1, %zmm1     # nx
    vpxorq  %zmm2, %zmm2, %zmm2
    vsubps  %zmm0, %zmm2, %zmm2     # ny

    vmulps  %zmm1, %zmm1, %zmm7
    vmulps  %zmm2, %zmm2, %zmm0
    vaddps  %zmm0, %zmm7, %zmm7
    vaddps  256(%esp), %zmm7, %zmm7 # nLen^2

    vrsqrt14ps %zmm7, %zmm0         # estimate
    vmulps  %zmm0, %zmm0, %zmm6
    vmulps  %zmm7, %zmm6, %zmm6
    vmovaps 320(%esp), %zmm7        # 1.5
    vsubps  %zmm6, %zmm7, %zmm7
    vmulps  %zmm0, %zmm7, %zmm7     # 1/nLen
    vbroadcastss .Ltwo_imm, %zmm6   # restore 2.0 (use immediate or memory)

    vmulps  %zmm7, %zmm1, %zmm1     # nx
    vmulps  %zmm7, %zmm2, %zmm2     # ny
    # nz = zmm7

    vmulps  %zmm3, %zmm1, %zmm1
    vmulps  %zmm4, %zmm2, %zmm2
    vaddps  %zmm2, %zmm1, %zmm1
    vmulps  %zmm5, %zmm7, %zmm7
    vaddps  %zmm7, %zmm1, %zmm1     # dot in zmm1

    vpxorq  %zmm0, %zmm0, %zmm0
    vmaxps  %zmm0, %zmm1, %zmm1
    vbroadcastss 32(%ebp), %zmm0
    vmulps  %zmm0, %zmm1, %zmm1
    vminps  256(%esp), %zmm1, %zmm1 # intensity in zmm1

    // Pack to ARGB
    vmulps  384(%esp), %zmm1, %zmm7 # outR
    vmulps  448(%esp), %zmm1, %zmm2 # outG
    vmulps  192(%esp), %zmm1, %zmm1 # outB

    vcvttps2dq %zmm7, %zmm7
    vcvttps2dq %zmm2, %zmm2
    vcvttps2dq %zmm1, %zmm1

    vpslld  $16, %zmm7, %zmm7
    vpslld  $8, %zmm2, %zmm2
    vporq   %zmm7, %zmm1, %zmm1
    vporq   %zmm2, %zmm1, %zmm1

    mov     $0xFF000000, %eax
    vmovd   %eax, %xmm0
    vbroadcastss %xmm0, %zmm0
    vporq   %zmm0, %zmm1, %zmm1

    vmovdqu32 %zmm1, (%edx)

    add     $64, %esi
    add     $64, %edi
    add     $64, %ebx
    add     $64, %edx
    sub     $16, %ecx
    jnz     .Lloop

.Ldone:
    vzeroupper
    add     $512, %esp
    pop     %ebx
    pop     %edi
    pop     %esi
    pop     %ebp
    ret

#ifdef __APPLE__
.section __TEXT,__const
#else
.section .rodata
#endif
.p2align 6
.Lone:          .float 1.0
.Ltwo:          .float 2.0
.Ltwo_imm:      .float 2.0
.Lthree_halves: .float 1.5

//// SIZE(SYM(ksvgLightingDistantDiffuseRowAvx512))
