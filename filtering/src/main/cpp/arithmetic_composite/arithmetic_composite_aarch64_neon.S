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

 *
 * AArch64 hand-written kernel for SVG arithmetic composite.
 * Processes packed 4-byte pixels directly, 8 pixels per iteration.
 */

.text
.align 4
.global applyArithmetic64Asm
.type applyArithmetic64Asm, %function

// void applyArithmetic64Asm(
//     const uint8_t* src1,   // x0
//     const uint8_t* src2,   // x1
//     uint8_t* dst,          // x2
//     size_t pixels,         // x3
//     float k1_div_255,      // s0
//     float k2,              // s1
//     float k3,              // s2
//     float k4_255           // s3
// );

applyArithmetic64Asm:
    // AArch64 ABI: x0=src1, x1=src2, x2=dst, x3=pixel count, s0..s3=coefficients.
    // v0-v7 and v16-v31 are caller-saved. No stack frame is required.
    dup     v24.4s, v0.s[0]          // k1 / 255
    dup     v25.4s, v1.s[0]          // k2
    dup     v26.4s, v2.s[0]          // k3
    dup     v27.4s, v3.s[0]          // k4 * 255

    // Eight pixels per iteration. ld4/st4 operate directly on packed RGBA.
    lsr     x4, x3, #3
    cbz     x4, .done

.loop:
    ld4     {v16.8b, v17.8b, v18.8b, v19.8b}, [x0], #32
    ld4     {v20.8b, v21.8b, v22.8b, v23.8b}, [x1], #32

    // Channel 0 (Red)
    uxtl    v4.8h, v16.8b
    uxtl    v5.4s, v4.4h
    uxtl2   v6.4s, v4.8h
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    uxtl    v4.8h, v20.8b
    uxtl    v7.4s, v4.4h
    uxtl2   v4.4s, v4.8h
    ucvtf   v7.4s, v7.4s
    ucvtf   v4.4s, v4.4s

    // Low half.
    fmul    v0.4s, v5.4s, v7.4s
    fmul    v0.4s, v0.4s, v24.4s
    fmla    v0.4s, v5.4s, v25.4s
    fmla    v0.4s, v7.4s, v26.4s
    fadd    v0.4s, v0.4s, v27.4s
    fcvtau  v0.4s, v0.4s

    // High half.
    fmul    v5.4s, v6.4s, v4.4s
    fmul    v5.4s, v5.4s, v24.4s
    fmla    v5.4s, v6.4s, v25.4s
    fmla    v5.4s, v4.4s, v26.4s
    fadd    v5.4s, v5.4s, v27.4s
    fcvtau  v5.4s, v5.4s

    // Packing. uqxtn handles saturation to 255 automatically at the last step.
    uqxtn   v0.4h, v0.4s
    uqxtn2  v0.8h, v5.4s
    uqxtn   v0.8b, v0.8h


    // Channel 1 (Green)
    uxtl    v4.8h, v17.8b
    uxtl    v5.4s, v4.4h
    uxtl2   v6.4s, v4.8h
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    uxtl    v4.8h, v21.8b
    uxtl    v7.4s, v4.4h
    uxtl2   v4.4s, v4.8h
    ucvtf   v7.4s, v7.4s
    ucvtf   v4.4s, v4.4s

    fmul    v1.4s, v5.4s, v7.4s
    fmul    v1.4s, v1.4s, v24.4s
    fmla    v1.4s, v5.4s, v25.4s
    fmla    v1.4s, v7.4s, v26.4s
    fadd    v1.4s, v1.4s, v27.4s
    fcvtau  v1.4s, v1.4s

    fmul    v5.4s, v6.4s, v4.4s
    fmul    v5.4s, v5.4s, v24.4s
    fmla    v5.4s, v6.4s, v25.4s
    fmla    v5.4s, v4.4s, v26.4s
    fadd    v5.4s, v5.4s, v27.4s
    fcvtau  v5.4s, v5.4s

    uqxtn   v1.4h, v1.4s
    uqxtn2  v1.8h, v5.4s
    uqxtn   v1.8b, v1.8h


    // Channel 2 (Blue)
    uxtl    v4.8h, v18.8b
    uxtl    v5.4s, v4.4h
    uxtl2   v6.4s, v4.8h
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    uxtl    v4.8h, v22.8b
    uxtl    v7.4s, v4.4h
    uxtl2   v4.4s, v4.8h
    ucvtf   v7.4s, v7.4s
    ucvtf   v4.4s, v4.4s

    fmul    v2.4s, v5.4s, v7.4s
    fmul    v2.4s, v2.4s, v24.4s
    fmla    v2.4s, v5.4s, v25.4s
    fmla    v2.4s, v7.4s, v26.4s
    fadd    v2.4s, v2.4s, v27.4s
    fcvtau  v2.4s, v2.4s

    fmul    v5.4s, v6.4s, v4.4s
    fmul    v5.4s, v5.4s, v24.4s
    fmla    v5.4s, v6.4s, v25.4s
    fmla    v5.4s, v4.4s, v26.4s
    fadd    v5.4s, v5.4s, v27.4s
    fcvtau  v5.4s, v5.4s

    uqxtn   v2.4h, v2.4s
    uqxtn2  v2.8h, v5.4s
    uqxtn   v2.8b, v2.8h


    // Channel 3 (Alpha)
    uxtl    v4.8h, v19.8b
    uxtl    v5.4s, v4.4h
    uxtl2   v6.4s, v4.8h
    ucvtf   v5.4s, v5.4s
    ucvtf   v6.4s, v6.4s
    uxtl    v4.8h, v23.8b
    uxtl    v7.4s, v4.4h
    uxtl2   v4.4s, v4.8h
    ucvtf   v7.4s, v7.4s
    ucvtf   v4.4s, v4.4s

    fmul    v3.4s, v5.4s, v7.4s
    fmul    v3.4s, v3.4s, v24.4s
    fmla    v3.4s, v5.4s, v25.4s
    fmla    v3.4s, v7.4s, v26.4s
    fadd    v3.4s, v3.4s, v27.4s
    fcvtau  v3.4s, v3.4s

    fmul    v5.4s, v6.4s, v4.4s
    fmul    v5.4s, v5.4s, v24.4s
    fmla    v5.4s, v6.4s, v25.4s
    fmla    v5.4s, v4.4s, v26.4s
    fadd    v5.4s, v5.4s, v27.4s
    fcvtau  v5.4s, v5.4s

    uqxtn   v3.4h, v3.4s
    uqxtn2  v3.8h, v5.4s
    uqxtn   v3.8b, v3.8h


    st4     {v0.8b, v1.8b, v2.8b, v3.8b}, [x2], #32

    subs    x4, x4, #1
    b.ne    .loop

.done:
    ret

.size applyArithmetic64Asm, .-applyArithmetic64Asm
