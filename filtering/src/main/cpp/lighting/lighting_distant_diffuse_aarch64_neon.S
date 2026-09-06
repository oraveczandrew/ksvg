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
.global ksvgLightingDistantDiffuseNeon64
.type ksvgLightingDistantDiffuseNeon64, %function

// void ksvgLightingDistantDiffuseNeon64(
//   const float* ht, const float* hm, const float* hb,
//   int count,
//   float invDx, float invDy, float k,
//   float lx, float ly, float lz,
//   float* outIntensity)
// Processes 'count' pixels, count must be a multiple of 4.
// ht/hm/hb point at x-1 for the four outputs.
// Output is clamped to [0,1].

ksvgLightingDistantDiffuseNeon64:
    // Arguments:
    // x0 ht, x1 hm, x2 hb, w3 count
    // s0 invDx, s1 invDy, s2 k, s3 lx, s4 ly, s5 lz, x4 out

    dup     v7.4s, v0.s[0]          // invDx
    dup     v8.4s, v1.s[0]          // invDy
    dup     v9.4s, v2.s[0]          // k
    dup     v10.4s, v3.s[0]         // lx
    dup     v11.4s, v4.s[0]         // ly
    dup     v12.4s, v5.s[0]         // lz
    movi    v13.4s, #0              // zero
    fmov    v14.4s, #1.0            // one
    fmov    v15.4s, #2.0            // two

    cbz     w3, .Ldone

.Lloop:
    // Load overlapping windows for 4 pixels:
    // lT = [0,1,2,3], mT = [1,2,3,4], rT = [2,3,4,5]
    ldr     q0, [x0]                // ht[0..3]
    ldr     q1, [x0, #4]            // ht[1..4]
    ldr     q2, [x0, #8]            // ht[2..5]

    ldr     q3, [x1]                // hm[0..3]
    ldr     q4, [x1, #4]            // hm[1..4]
    ldr     q5, [x1, #8]            // hm[2..5]

    ldr     q6, [x2]                // hb[0..3]
    ldr     q16, [x2, #4]           // hb[1..4]
    ldr     q17, [x2, #8]           // hb[2..5]

    // sumR = rT + 2*rM + rB
    fmul    v18.4s, v5.4s, v15.4s
    fadd    v18.4s, v18.4s, v2.4s
    fadd    v18.4s, v18.4s, v17.4s

    // sumL = lT + 2*lM + lB
    fmul    v19.4s, v3.4s, v15.4s
    fadd    v19.4s, v19.4s, v0.4s
    fadd    v19.4s, v19.4s, v6.4s

    // sumB = lB + 2*mB + rB
    fmul    v20.4s, v16.4s, v15.4s
    fadd    v20.4s, v20.4s, v6.4s
    fadd    v20.4s, v20.4s, v17.4s

    // sumT = lT + 2*mT + rT
    fmul    v21.4s, v1.4s, v15.4s
    fadd    v21.4s, v21.4s, v0.4s
    fadd    v21.4s, v21.4s, v2.4s

    // dzdx = (sumR - sumL) / invDx
    fsub    v18.4s, v18.4s, v19.4s
    fdiv    v18.4s, v18.4s, v7.4s

    // dzdy = (sumB - sumT) / invDy
    fsub    v20.4s, v20.4s, v21.4s
    fdiv    v20.4s, v20.4s, v8.4s

    // n = (-dzdx, -dzdy, 1)
    fneg    v18.4s, v18.4s
    fneg    v20.4s, v20.4s

    // len = sqrt(nx*nx + ny*ny + 1)
    fmul    v22.4s, v18.4s, v18.4s
    fmla    v22.4s, v20.4s, v20.4s
    fadd    v22.4s, v22.4s, v14.4s
    fsqrt   v22.4s, v22.4s

    // nx/nLen, ny/nLen, nz/nLen
    fdiv    v18.4s, v18.4s, v22.4s
    fdiv    v20.4s, v20.4s, v22.4s
    fdiv    v23.4s, v14.4s, v22.4s

    // dot = nx*lx + ny*ly + nz*lz
    fmul    v18.4s, v18.4s, v10.4s
    fmla    v18.4s, v20.4s, v11.4s
    fmla    v18.4s, v23.4s, v12.4s

    // max(dot, 0), then k, then min 1
    fmax    v18.4s, v18.4s, v13.4s
    fmul    v18.4s, v18.4s, v9.4s
    fmin    v18.4s, v18.4s, v14.4s

    st1     {v18.4s}, [x4], #16
    add     x0, x0, #16
    add     x1, x1, #16
    add     x2, x2, #16
    subs    w3, w3, #4
    bne     .Lloop

.Ldone:
    ret
.size ksvgLightingDistantDiffuseNeon64, .-ksvgLightingDistantDiffuseNeon64
