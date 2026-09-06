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

.text
.align 2
.global ksvgLightingDistantDiffuseRowNeon64
.type ksvgLightingDistantDiffuseRowNeon64, %function

// void ksvgLightingDistantDiffuseRowNeon64(
//   const jint* srcT, const jint* srcM, const jint* srcB,
//   jint* dst, jint count, const LightingParams* params)

ksvgLightingDistantDiffuseRowNeon64:
    // x0=srcT, x1=srcM, x2=srcB, x3=dst, w4=count, x5=params

    cbz     w4, .Ldone

    // Load Params
    ldp     s0, s1, [x5]           // invDx, invDy
    fmov    s16, #1.0
    fdiv    s0, s16, s0            // scaleX
    fdiv    s1, s16, s1            // scaleY

    dup     v7.4s, v0.s[0]
    dup     v8.4s, v1.s[0]

    ldr     s2, [x5, #8]           // k
    dup     v9.4s, v2.s[0]

    ldp     s3, s4, [x5, #12]      // lx, ly
    dup     v10.4s, v3.s[0]
    dup     v11.4s, v4.s[0]

    ldp     s5, s6, [x5, #20]      // lz, lr
    dup     v12.4s, v5.s[0]
    dup     v22.4s, v6.s[0]        // lr

    ldp     s17, s18, [x5, #28]    // lg, lb
    dup     v23.4s, v17.s[0]       // lg
    dup     v24.4s, v18.s[0]       // lb

    ldr     s19, [x5, #36]         // ss
    dup     v25.4s, v19.s[0]

    movi    v13.4s, #0             // zero
    fmov    v14.4s, #1.0           // one
    fmov    v15.4s, #2.0           // two
    movi    v26.4s, #0xFF, lsl #24 // alpha mask

.Lloop:
    // Extract Alpha and convert to Height
    // Row T
    ldr     q0, [x0]               // lT
    ushr    v0.4s, v0.4s, #24
    ucvtf   v0.4s, v0.4s

    ldr     q1, [x0, #4]           // mT
    ushr    v1.4s, v1.4s, #24
    ucvtf   v1.4s, v1.4s

    ldr     q2, [x0, #8]           // rT
    ushr    v2.4s, v2.4s, #24
    ucvtf   v2.4s, v2.4s

    // sumT = lT + 2*mT + rT
    fmul    v3.4s, v1.4s, v15.4s
    fadd    v3.4s, v3.4s, v0.4s
    fadd    v3.4s, v3.4s, v2.4s    // sumT_rel

    // dx_rel = rT - lT
    fsub    v4.4s, v2.4s, v0.4s    // dx_rel_partial

    // Row M
    ldr     q0, [x1]               // lM
    ushr    v0.4s, v0.4s, #24
    ucvtf   v0.4s, v0.4s

    ldr     q2, [x1, #8]           // rM
    ushr    v2.4s, v2.4s, #24
    ucvtf   v2.4s, v2.4s

    // dx_rel += 2*(rM - lM)
    fsub    v5.4s, v2.4s, v0.4s
    fmul    v5.4s, v5.4s, v15.4s
    fadd    v4.4s, v4.4s, v5.4s

    // Row B
    ldr     q0, [x2]               // lB
    ushr    v0.4s, v0.4s, #24
    ucvtf   v0.4s, v0.4s

    ldr     q1, [x2, #4]           // mB
    ushr    v1.4s, v1.4s, #24
    ucvtf   v1.4s, v1.4s

    ldr     q2, [x2, #8]           // rB
    ushr    v2.4s, v2.4s, #24
    ucvtf   v2.4s, v2.4s

    // sumB = lB + 2*mB + rB
    fmul    v5.4s, v1.4s, v15.4s
    fadd    v5.4s, v5.4s, v0.4s
    fadd    v5.4s, v5.4s, v2.4s    // sumB_rel

    // final dx_rel += rB - lB
    fsub    v2.4s, v2.4s, v0.4s
    fadd    v4.4s, v4.4s, v2.4s

    // dy_rel = sumB_rel - sumT_rel
    fsub    v5.4s, v5.4s, v3.4s

    // dx = dx_rel * ss * scaleX, dy = dy_rel * ss * scaleY
    fmul    v0.4s, v25.4s, v7.4s
    fmul    v4.4s, v4.4s, v0.4s    // dx
    fmul    v0.4s, v25.4s, v8.4s
    fmul    v5.4s, v5.4s, v0.4s    // dy

    // n = (-dx, -dy, 1)
    fneg    v0.4s, v4.4s           // nx
    fneg    v1.4s, v5.4s           // ny

    // nLen^2 = nx*nx + ny*ny + 1
    fmul    v2.4s, v0.4s, v0.4s
    fmul    v3.4s, v1.4s, v1.4s
    fadd    v2.4s, v2.4s, v3.4s
    fadd    v2.4s, v2.4s, v14.4s

    // Normalize: 1/nLen
    frsqrte v3.4s, v2.4s
    frsqrts v4.4s, v2.4s, v3.4s
    fmul    v3.4s, v3.4s, v4.4s    // 1/nLen

    fmul    v0.4s, v0.4s, v3.4s    // nx
    fmul    v1.4s, v1.4s, v3.4s    // ny
    // nz = v3

    // dot = nx*lx + ny*ly + nz*lz
    fmul    v0.4s, v0.4s, v10.4s
    fmul    v1.4s, v1.4s, v11.4s
    fadd    v0.4s, v0.4s, v1.4s
    fmul    v1.4s, v3.4s, v12.4s
    fadd    v0.4s, v0.4s, v1.4s    // dot

    fmax    v0.4s, v0.4s, v13.4s
    fmul    v0.4s, v0.4s, v9.4s
    fmin    v0.4s, v0.4s, v14.4s    // intensity

    // Pack to ARGB
    fmul    v1.4s, v0.4s, v22.4s   // outR
    fmul    v2.4s, v0.4s, v23.4s   // outG
    fmul    v3.4s, v0.4s, v24.4s   // outB

    fcvtns  v1.4s, v1.4s
    fcvtns  v2.4s, v2.4s
    fcvtns  v3.4s, v3.4s

    shl     v1.4s, v1.4s, #16
    shl     v2.4s, v2.4s, #8
    orr     v3.16b, v3.16b, v1.16b
    orr     v3.16b, v3.16b, v2.16b
    orr     v3.16b, v3.16b, v26.16b

    str     q3, [x3], #16
    add     x0, x0, #16
    add     x1, x1, #16
    add     x2, x2, #16
    subs    w4, w4, #4
    bne     .Lloop

.Ldone:
    ret
.size ksvgLightingDistantDiffuseRowNeon64, .-ksvgLightingDistantDiffuseRowNeon64
