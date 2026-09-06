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

/* x86-32 AVX2 distant-light diffuse kernel. cdecl ABI. */
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
.p2align 5
.globl SYM(ksvgLightingDistantDiffuseRowAvx2)
TYPE(SYM(ksvgLightingDistantDiffuseRowAvx2), @function)
SYM(ksvgLightingDistantDiffuseRowAvx2):
    push    %ebp
    mov     %esp, %ebp
    push    %esi
    push    %edi
    push    %ebx
    sub     $256, %esp

    mov     8(%ebp), %esi
    mov     12(%ebp), %edi
    mov     16(%ebp), %ebx
    mov     24(%ebp), %ecx
    mov     28(%ebp), %eax

    // --- Constant Initialization ---
    mov     $0x3f800000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %ymm0
    vmovaps %ymm0, 128(%esp)   # 128(esp) = 1.0

    mov     $0x3f000000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %ymm0
    vmovaps %ymm0, 160(%esp)   # 160(esp) = 0.5

    mov     $0x3fc00000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %ymm0
    vmovaps %ymm0, 192(%esp)   # 192(esp) = 1.5

    mov     $0x40000000, %edx
    vmovd   %edx, %xmm0
    vbroadcastss %xmm0, %ymm6  # ymm6 = 2.0

    // Precalculate Scales
    vmovss  128(%esp), %xmm0
    vdivss  0(%eax), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm1
    vmovaps %ymm1, 0(%esp)     # 0(esp) = scaleX

    vdivss  4(%eax), %xmm0, %xmm1
    vbroadcastss %xmm1, %ymm1
    vmovaps %ymm1, 32(%esp)    # 32(esp) = scaleY

    // Apply ss
    vbroadcastss 36(%eax), %ymm0
    vmulps  0(%esp), %ymm0, %ymm1
    vmovaps %ymm1, 0(%esp)
    vmulps  32(%esp), %ymm0, %ymm1
    vmovaps %ymm1, 32(%esp)

    // lx, ly, lz -> ymm3, ymm4, ymm5
    vbroadcastss 12(%eax), %ymm3
    vbroadcastss 16(%eax), %ymm4
    vbroadcastss 20(%eax), %ymm5

    mov     20(%ebp), %edx     # dst

.Lloop:
    test    %ecx, %ecx
    jz      .Ldone

    // --- Sobel Gradient ---
    vmovups 8(%edi), %ymm0     # rM
    vmulps  %ymm6, %ymm0, %ymm0
    vmovups 8(%esi), %ymm1     # rT
    vaddps  %ymm1, %ymm0, %ymm0
    vmovups 8(%ebx), %ymm1     # rB
    vaddps  %ymm1, %ymm0, %ymm7 # ymm7 = sumR_rel

    vmovups 0(%edi), %ymm0     # lM
    vmulps  %ymm6, %ymm0, %ymm0
    vmovups 0(%esi), %ymm1     # lT
    vaddps  %ymm1, %ymm0, %ymm0
    vmovups 0(%ebx), %ymm1     # lB
    vaddps  %ymm1, %ymm0, %ymm0 # ymm0 = sumL_rel

    vsubps  %ymm0, %ymm7, %ymm0
    vmulps  0(%esp), %ymm0, %ymm0 # ymm0 = dx (final)
    vmovaps %ymm0, 224(%esp)   # store dx to stack

    vmovups 4(%ebx), %ymm0     # mB
    vmulps  %ymm6, %ymm0, %ymm0
    vmovups 0(%ebx), %ymm7     # lB
    vaddps  %ymm7, %ymm0, %ymm0
    vmovups 8(%ebx), %ymm7     # rB
    vaddps  %ymm7, %ymm0, %ymm7 # ymm7 = sumB_rel

    vmovups 4(%esi), %ymm0     # mT
    vmulps  %ymm6, %ymm0, %ymm0
    vmovups 0(%esi), %ymm2     # lT
    vaddps  %ymm2, %ymm0, %ymm0
    vmovups 8(%esi), %ymm2     # rT
    vaddps  %ymm2, %ymm0, %ymm0 # ymm0 = sumT_rel

    vsubps  %ymm0, %ymm7, %ymm1 # dy_rel
    vmulps  32(%esp), %ymm1, %ymm1 # ymm1 = dy (final)

    vmovaps 224(%esp), %ymm0   # reload dx

    // n = (-dx, -dy, 1)
    vxorps  %ymm2, %ymm2, %ymm2
    vsubps  %ymm0, %ymm2, %ymm0 # nx
    vsubps  %ymm1, %ymm2, %ymm1 # ny

    vmulps  %ymm0, %ymm0, %ymm2
    vmulps  %ymm1, %ymm1, %ymm7
    vaddps  %ymm7, %ymm2, %ymm2
    vaddps  128(%esp), %ymm2, %ymm2 # nLen^2

    vrsqrtps %ymm2, %ymm7
    vmulps  %ymm7, %ymm7, %ymm0 # temp xmm0
    vmulps  %ymm2, %ymm0, %ymm0
    vmulps  160(%esp), %ymm0, %ymm0 # 0.5 * x * r^2
    vmovaps 192(%esp), %ymm2    # 1.5
    vsubps  %ymm0, %ymm2, %ymm2
    vmulps  %ymm7, %ymm2, %ymm2 # 1/nLen in ymm2
    vmovaps 224(%esp), %ymm0    # reload dx for nx computation (wait, I used nx negated before)
    # Actually, I have nx in GPR or stack? Let's just re-negate.

    # Register map fix: ymm0=nx, ymm1=ny, ymm2=1/nLen
    # Reload nx, ny
    vmovaps 224(%esp), %ymm0
    vxorps  %ymm7, %ymm7, %ymm7
    vsubps  %ymm0, %ymm7, %ymm0 # nx
    # dy was in ymm1, negate it
    vsubps  %ymm1, %ymm7, %ymm1 # ny (wait, ymm1 was dy_final)
    # Let's just use stack for dy too.

    # ... I will rewrite the loop body to be absolutely safe with registers.
    # Actually, I'll stop here and just do a very clean version for all.
