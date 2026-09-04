.text
.align 2
.global ksvgConvolve3x3NeonAsm
.type ksvgConvolve3x3NeonAsm, %function

// AArch64 NEON 3x3 convolution hot path.
//
// ABI:
//   x0  = dst (jint*)
//   x1  = src (const jint*)
//   w2  = width
//   w3  = height
//   x4  = kernel (const float*, 9 elements)
//   s5  = divisor
//   s6  = bias
//
// Specialization:
//   orderX = 3, orderY = 3
//   targetX = 1, targetY = 1
//   preserveAlpha = true
//   edgeMode = 0
//
// Returns:
//   w0 = first interior x not processed by the SIMD loop.
//
// Notes:
//   * 8 output pixels are processed per iteration.
//   * Each source row uses three 16-byte loads (12 packed pixels).
//   * The loaded 12 pixels are decoded once per channel and reused for
//     all three kernel taps via EXT.
//   * Alpha is copied from the unfiltered source.

ksvgConvolve3x3NeonAsm:
    // AAPCS64 callee-saved GPRs/SIMD registers.
    stp     x19, x20, [sp, #-176]!
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     q8, q9,   [sp, #48]
    stp     q10, q11, [sp, #80]
    stp     q12, q13, [sp, #112]
    stp     q14, q15, [sp, #144]

    mov     x19, x0                  // dst
    mov     x20, x1                  // src
    mov     w21, w2                  // width
    mov     w22, w3                  // height
    mov     x23, x4                  // kernel

    // Default return for no interior rows / no SIMD block.
    mov     w0, #1

    cmp     w22, #3
    b.lo    .Ldone

    // Save divisor and bias before loading kernel coefficients into s5/s6.
    fmov    s28, s5
    fmov    s29, s6

    // Load the 9 kernel coefficients.
    ldr     s0, [x23, #0]
    ldr     s1, [x23, #4]
    ldr     s2, [x23, #8]
    ldr     s3, [x23, #12]
    ldr     s4, [x23, #16]
    ldr     s5, [x23, #20]
    ldr     s6, [x23, #24]
    ldr     s7, [x23, #28]
    ldr     s8, [x23, #32]

    // Broadcast kernel coefficients. Using vector coefficients avoids
    // scalar-lane FMLA syntax and keeps the hot loop straightforward.
    dup     v0.4s, v0.s[0]
    dup     v1.4s, v1.s[0]
    dup     v2.4s, v2.s[0]
    dup     v3.4s, v3.s[0]
    dup     v4.4s, v4.s[0]
    dup     v5.4s, v5.s[0]
    dup     v6.4s, v6.s[0]
    dup     v7.4s, v7.s[0]
    dup     v8.4s, v8.s[0]

    // Reciprocal divisor, bias*255, and 0.5.
    fmov    s19, #1.0
    fdiv    s19, s19, s28
    dup     v19.4s, v19.s[0]

    movi    v15.4s, #0xff

    mov     w16, #255
    ucvtf   s20, w16
    fmul    s20, s20, s29
    dup     v20.4s, v20.s[0]

    fmov    s21, #0.5
    dup     v21.4s, v21.s[0]

    // Each iteration loads source pixels 0..11 for an output block
    // starting at x=1, so the largest safe start is width-12.
    sub     w11, w21, #11
    cmp     w11, #1
    b.lt    .Ldone

    // Interior rows: y = 1 .. height-2.
    mov     w9, #1
    sub     w10, w22, #1

.Lrow:
    // Source row y-1; start at source x=0 for destination x=1.
    sub     w14, w9, #1
    mul     w14, w14, w21
    add     x13, x20, w14, uxtw #2

    // Destination y, x=1.
    add     x14, x19, w9, uxtw #2
    add     x14, x14, #4

    mov     w12, #1

.Leight:
    cmp     w12, w11
    b.gt    .Lrow_done

    // B, G, R accumulators for output pixels 0..3 and 4..7.
    movi    v9.4s,  #0
    movi    v10.4s, #0
    movi    v11.4s, #0
    movi    v12.4s, #0
    movi    v13.4s, #0
    movi    v14.4s, #0

    // ================================================================
    // Kernel row 0: source y-1, weights k0/k1/k2.
    // ================================================================
    ld1     {v16.4s}, [x13]
    add     x15, x13, #16
    ld1     {v17.4s}, [x15]
    add     x15, x13, #32
    ld1     {v18.4s}, [x15]

    // ---- B ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v9.4s, v22.4s, v0.4s
    fmla    v10.4s, v23.4s, v0.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v9.4s, v25.4s, v1.4s
    fmla    v10.4s, v26.4s, v1.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v9.4s, v25.4s, v2.4s
    fmla    v10.4s, v26.4s, v2.4s

    // ---- G ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    ushr    v22.4s, v22.4s, #8
    ushr    v23.4s, v23.4s, #8
    ushr    v24.4s, v24.4s, #8
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v11.4s, v22.4s, v0.4s
    fmla    v12.4s, v23.4s, v0.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v11.4s, v25.4s, v1.4s
    fmla    v12.4s, v26.4s, v1.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v11.4s, v25.4s, v2.4s
    fmla    v12.4s, v26.4s, v2.4s

    // ---- R ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    ushr    v22.4s, v22.4s, #16
    ushr    v23.4s, v23.4s, #16
    ushr    v24.4s, v24.4s, #16
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v13.4s, v22.4s, v0.4s
    fmla    v14.4s, v23.4s, v0.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v13.4s, v25.4s, v1.4s
    fmla    v14.4s, v26.4s, v1.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v13.4s, v25.4s, v2.4s
    fmla    v14.4s, v26.4s, v2.4s

    // ================================================================
    // Kernel row 1: source y, weights k3/k4/k5.
    // ================================================================
    add     x15, x13, w21, uxtw #2
    ld1     {v16.4s}, [x15]
    add     x16, x15, #16
    ld1     {v17.4s}, [x16]
    add     x16, x15, #32
    ld1     {v18.4s}, [x16]

    // ---- B ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v9.4s, v22.4s, v3.4s
    fmla    v10.4s, v23.4s, v3.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v9.4s, v25.4s, v4.4s
    fmla    v10.4s, v26.4s, v4.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v9.4s, v25.4s, v5.4s
    fmla    v10.4s, v26.4s, v5.4s

    // ---- G ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    ushr    v22.4s, v22.4s, #8
    ushr    v23.4s, v23.4s, #8
    ushr    v24.4s, v24.4s, #8
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v11.4s, v22.4s, v3.4s
    fmla    v12.4s, v23.4s, v3.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v11.4s, v25.4s, v4.4s
    fmla    v12.4s, v26.4s, v4.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v11.4s, v25.4s, v5.4s
    fmla    v12.4s, v26.4s, v5.4s

    // ---- R ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    ushr    v22.4s, v22.4s, #16
    ushr    v23.4s, v23.4s, #16
    ushr    v24.4s, v24.4s, #16
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v13.4s, v22.4s, v3.4s
    fmla    v14.4s, v23.4s, v3.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v13.4s, v25.4s, v4.4s
    fmla    v14.4s, v26.4s, v4.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v13.4s, v25.4s, v5.4s
    fmla    v14.4s, v26.4s, v5.4s

    // ================================================================
    // Kernel row 2: source y+1, weights k6/k7/k8.
    // ================================================================
    add     x15, x13, x21, lsl #3
    ld1     {v16.4s}, [x15]
    add     x16, x15, #16
    ld1     {v17.4s}, [x16]
    add     x16, x15, #32
    ld1     {v18.4s}, [x16]

    // ---- B ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v9.4s, v22.4s, v6.4s
    fmla    v10.4s, v23.4s, v6.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v9.4s, v25.4s, v7.4s
    fmla    v10.4s, v26.4s, v7.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v9.4s, v25.4s, v8.4s
    fmla    v10.4s, v26.4s, v8.4s

    // ---- G ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    ushr    v22.4s, v22.4s, #8
    ushr    v23.4s, v23.4s, #8
    ushr    v24.4s, v24.4s, #8
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v11.4s, v22.4s, v6.4s
    fmla    v12.4s, v23.4s, v6.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v11.4s, v25.4s, v7.4s
    fmla    v12.4s, v26.4s, v7.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v11.4s, v25.4s, v8.4s
    fmla    v12.4s, v26.4s, v8.4s

    // ---- R ----
    mov     v22.16b, v16.16b
    mov     v23.16b, v17.16b
    mov     v24.16b, v18.16b
    ushr    v22.4s, v22.4s, #16
    ushr    v23.4s, v23.4s, #16
    ushr    v24.4s, v24.4s, #16
    and     v22.16b, v22.16b, v15.16b
    and     v23.16b, v23.16b, v15.16b
    and     v24.16b, v24.16b, v15.16b
    ucvtf   v22.4s, v22.4s
    ucvtf   v23.4s, v23.4s
    ucvtf   v24.4s, v24.4s

    fmla    v13.4s, v22.4s, v6.4s
    fmla    v14.4s, v23.4s, v6.4s
    ext     v25.16b, v22.16b, v23.16b, #4
    ext     v26.16b, v23.16b, v24.16b, #4
    fmla    v13.4s, v25.4s, v7.4s
    fmla    v14.4s, v26.4s, v7.4s
    ext     v25.16b, v22.16b, v23.16b, #8
    ext     v26.16b, v23.16b, v24.16b, #8
    fmla    v13.4s, v25.4s, v8.4s
    fmla    v14.4s, v26.4s, v8.4s

    // ================================================================
    // Finish RGB: * reciprocal(divisor) + bias*255 + 0.5,
    // floor, convert to integer, clamp.
    // ================================================================
    fmul    v9.4s,  v9.4s,  v19.4s
    fmul    v10.4s, v10.4s, v19.4s
    fmul    v11.4s, v11.4s, v19.4s
    fmul    v12.4s, v12.4s, v19.4s
    fmul    v13.4s, v13.4s, v19.4s
    fmul    v14.4s, v14.4s, v19.4s

    fadd    v9.4s,  v9.4s,  v20.4s
    fadd    v10.4s, v10.4s, v20.4s
    fadd    v11.4s, v11.4s, v20.4s
    fadd    v12.4s, v12.4s, v20.4s
    fadd    v13.4s, v13.4s, v20.4s
    fadd    v14.4s, v14.4s, v20.4s

    fadd    v9.4s,  v9.4s,  v21.4s
    fadd    v10.4s, v10.4s, v21.4s
    fadd    v11.4s, v11.4s, v21.4s
    fadd    v12.4s, v12.4s, v21.4s
    fadd    v13.4s, v13.4s, v21.4s
    fadd    v14.4s, v14.4s, v21.4s

    frintm  v9.4s,  v9.4s
    frintm  v10.4s, v10.4s
    frintm  v11.4s, v11.4s
    frintm  v12.4s, v12.4s
    frintm  v13.4s, v13.4s
    frintm  v14.4s, v14.4s

    fcvtzs  v9.4s,  v9.4s
    fcvtzs  v10.4s, v10.4s
    fcvtzs  v11.4s, v11.4s
    fcvtzs  v12.4s, v12.4s
    fcvtzs  v13.4s, v13.4s
    fcvtzs  v14.4s, v14.4s

    movi    v27.4s, #0
    movi    v28.4s, #255

    smax    v9.4s,  v9.4s,  v27.4s
    smax    v10.4s, v10.4s, v27.4s
    smax    v11.4s, v11.4s, v27.4s
    smax    v12.4s, v12.4s, v27.4s
    smax    v13.4s, v13.4s, v27.4s
    smax    v14.4s, v14.4s, v27.4s

    smin    v9.4s,  v9.4s,  v28.4s
    smin    v10.4s, v10.4s, v28.4s
    smin    v11.4s, v11.4s, v28.4s
    smin    v12.4s, v12.4s, v28.4s
    smin    v13.4s, v13.4s, v28.4s
    smin    v14.4s, v14.4s, v28.4s

    // ================================================================
    // Preserve original alpha from destination pixels x..x+7.
    // ================================================================
    add     x15, x13, #4
    ld1     {v29.4s}, [x15]
    add     x16, x15, #16
    ld1     {v30.4s}, [x16]

    ushr    v29.4s, v29.4s, #24
    ushr    v30.4s, v30.4s, #24
    shl     v29.4s, v29.4s, #24
    shl     v30.4s, v30.4s, #24

    // Output 0..3.
    shl     v25.4s, v13.4s, #16
    shl     v26.4s, v11.4s, #8
    orr     v25.16b, v25.16b, v26.16b
    orr     v25.16b, v25.16b, v9.16b
    orr     v25.16b, v25.16b, v29.16b

    // Output 4..7.
    shl     v26.4s, v14.4s, #16
    shl     v27.4s, v12.4s, #8
    orr     v26.16b, v26.16b, v27.16b
    orr     v26.16b, v26.16b, v10.16b
    orr     v26.16b, v26.16b, v30.16b

    st1     {v25.4s}, [x14]
    add     x15, x14, #16
    st1     {v26.4s}, [x15]

    add     x13, x13, #32
    add     x14, x14, #32
    add     w12, w12, #8
    b       .Leight

.Lrow_done:
    // Same x tail for every interior row.
    mov     w0, w12
    add     w9, w9, #1
    cmp     w9, w10
    b.lt    .Lrow

.Ldone:
    ldp     q14, q15, [sp, #144]
    ldp     q12, q13, [sp, #112]
    ldp     q10, q11, [sp, #80]
    ldp     q8, q9,   [sp, #48]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp], #176
    ret

.size ksvgConvolve3x3NeonAsm, .-ksvgConvolve3x3NeonAsm
