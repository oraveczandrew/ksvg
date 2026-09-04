.text
.align 2

.global ksvgConvolve7x7NeonAsm
.type ksvgConvolve7x7NeonAsm, %function

// AArch64 NEON, 7x7 feConvolveMatrix hot path.
//
// ABI:
//   x0 = dst (jint*)
//   x1 = src (const jint*)
//   w2 = width
//   w3 = height
//   x4 = kernel (const float*, 49 elements)
//   s0 = divisor
//   s1 = bias
//
// Specialization:
//   orderX = orderY = 7
//   targetX = targetY = 3
//   preserveAlpha = true
//
// The caller must invoke this only for the fully valid interior:
//   x = 3 .. width-4
//   y = 3 .. height-4
//
// Returns w0 = first interior x not processed on the current/next row.
// IMPORTANT: the function itself processes every interior row. The returned
// value is the first x of the final tail (width-4 or the next unprocessed x).
//
// Four output pixels are processed per x iteration.
//
// Each source row loads 12 pixels starting at x-3. That covers:
//   x-3 ... x+8
// which is enough for four outputs and a 7-tap horizontal kernel.
//
// Pixel format: AARRGGBB.
//
// This implementation deliberately favors correctness and simple register
// lifetime over the more aggressive hand-unrolled AOSP blur style.

ksvgConvolve7x7NeonAsm:
    // Preserve all callee-saved GPRs used below.
    stp     x19, x20, [sp, #-96]!
    stp     x21, x22, [sp, #16]
    stp     x23, x24, [sp, #32]
    stp     x25, x26, [sp, #48]
    stp     x27, x28, [sp, #64]
    stp     x29, x30, [sp, #80]

    mov     x19, x0              // dst
    mov     x20, x1              // src
    mov     w21, w2              // width
    mov     w22, w3              // height
    mov     x23, x4              // kernel

    // v31 = 1 / divisor
    fmov    s2, #1.0
    fdiv    s2, s2, s0
    dup     v31.4s, v2.s[0]

    // v30 = bias * 255
    mov     w28, #255
    scvtf   s3, w28
    fmul    s3, s3, s1
    dup     v30.4s, v3.s[0]

    // v29 = 0.5
    fmov    s4, #0.5
    dup     v29.4s, v4.s[0]

    // v28 = 0
    // v27 = 255
    movi    v28.4s, #0
    movi    v27.4s, #255

    // y = 3
    mov     w24, #3

    // exclusive y end = height - 3
    sub     w25, w22, #3

.Ly:
    cmp     w24, w25
    b.ge    .Ldone

    // x = 3
    mov     w26, #3

    // exclusive x end = width - 3
    sub     w27, w21, #3

.Lx:
    // Need four outputs: x..x+3.
    // They are all interior iff x+3 < width-3.
    add     w28, w26, #4
    cmp     w28, w27
    b.gt    .Lrow_tail

    // ---------------------------------------------------------------
    // Accumulators: B, G, R for four output pixels.
    // ---------------------------------------------------------------
    movi    v14.4s, #0
    movi    v15.4s, #0
    movi    v16.4s, #0

    // Kernel row pointer starts at the beginning of the 49-float kernel.
    mov     x5, x23

    // source base row = src + (y-3)*width*4 + (x-3)*4
    sub     w28, w24, #3
    mul     w28, w28, w21
    add     x6, x20, w28, uxtw #2
    add     x6, x6, w26, uxtw #2
    sub     x6, x6, #12

    // ---------------------------------------------------------------
    // ky loop
    // ---------------------------------------------------------------
    mov     w29, #0

.Lky:
    // Load 12 pixels (48 bytes) from x-3 through x+8.
    ld1     {v0.16b, v1.16b, v2.16b}, [x6]

    // ---------------------------------------------------------------
    // Deinterleave B/G/R bytes using TBL.
    //
    // Memory layout:
    //   B G R A B G R A ...
    //
    // v3/v4 = B[0..7], B[8..11]
    // v5/v6 = G[0..7], G[8..11]
    // v7/v8 = R[0..7], R[8..11]
    // ---------------------------------------------------------------

    // Build byte-index vectors once per source row.
    // v24 = [0,4,8,12,16,20,24,28]
    // v25 = [32,36,40,44,0,0,0,0]
    // v26 = [1,1,1,1,1,1,1,1]
    movi    v24.8b, #0
    mov     w28, #4
    mov     v24.b[1], w28
    mov     w28, #8
    mov     v24.b[2], w28
    mov     w28, #12
    mov     v24.b[3], w28
    mov     w28, #16
    mov     v24.b[4], w28
    mov     w28, #20
    mov     v24.b[5], w28
    mov     w28, #24
    mov     v24.b[6], w28
    mov     w28, #28
    mov     v24.b[7], w28

    movi    v25.8b, #0
    mov     w28, #32
    mov     v25.b[0], w28
    mov     w28, #36
    mov     v25.b[1], w28
    mov     w28, #40
    mov     v25.b[2], w28
    mov     w28, #44
    mov     v25.b[3], w28

    movi    v26.8b, #1

    // B
    tbl     v3.8b, {v0.16b, v1.16b, v2.16b}, v24.8b
    tbl     v4.8b, {v0.16b, v1.16b, v2.16b}, v25.8b

    // G
    add     v24.8b, v24.8b, v26.8b
    add     v25.8b, v25.8b, v26.8b
    tbl     v5.8b, {v0.16b, v1.16b, v2.16b}, v24.8b
    tbl     v6.8b, {v0.16b, v1.16b, v2.16b}, v25.8b

    // R
    add     v24.8b, v24.8b, v26.8b
    add     v25.8b, v25.8b, v26.8b
    tbl     v7.8b, {v0.16b, v1.16b, v2.16b}, v24.8b
    tbl     v8.8b, {v0.16b, v1.16b, v2.16b}, v25.8b

    // Build 16-byte channel vectors. First 12 bytes are meaningful.
    // v9 = B[0..11], v10 = G[0..11], v11 = R[0..11]
    movi    v9.16b, #0
    ins     v9.d[0], v3.d[0]
    ins     v9.d[1], v4.d[0]

    movi    v10.16b, #0
    ins     v10.d[0], v5.d[0]
    ins     v10.d[1], v6.d[0]

    movi    v11.16b, #0
    ins     v11.d[0], v7.d[0]
    ins     v11.d[1], v8.d[0]

    // ---------------------------------------------------------------
    // kx = 0..6
    // ---------------------------------------------------------------
    mov     w28, #0

.Lkx:
    // Load coefficient.
    ldr     s12, [x5], #4
    dup     v12.4s, v12.s[0]

    // The AArch64 EXT immediate is encoded in the instruction, so select
    // the required byte offset explicitly.
    cmp     w28, #0
    b.eq    .Lwin0
    cmp     w28, #1
    b.eq    .Lwin1
    cmp     w28, #2
    b.eq    .Lwin2
    cmp     w28, #3
    b.eq    .Lwin3
    cmp     w28, #4
    b.eq    .Lwin4
    cmp     w28, #5
    b.eq    .Lwin5
    // kx = 6
    ext     v13.16b, v9.16b, v9.16b, #6
    ext     v17.16b, v10.16b, v10.16b, #6
    ext     v18.16b, v11.16b, v11.16b, #6
    b       .Lwindows_ready

.Lwin0:
    ext     v13.16b, v9.16b, v9.16b, #0
    ext     v17.16b, v10.16b, v10.16b, #0
    ext     v18.16b, v11.16b, v11.16b, #0
    b       .Lwindows_ready
.Lwin1:
    ext     v13.16b, v9.16b, v9.16b, #1
    ext     v17.16b, v10.16b, v10.16b, #1
    ext     v18.16b, v11.16b, v11.16b, #1
    b       .Lwindows_ready
.Lwin2:
    ext     v13.16b, v9.16b, v9.16b, #2
    ext     v17.16b, v10.16b, v10.16b, #2
    ext     v18.16b, v11.16b, v11.16b, #2
    b       .Lwindows_ready
.Lwin3:
    ext     v13.16b, v9.16b, v9.16b, #3
    ext     v17.16b, v10.16b, v10.16b, #3
    ext     v18.16b, v11.16b, v11.16b, #3
    b       .Lwindows_ready
.Lwin4:
    ext     v13.16b, v9.16b, v9.16b, #4
    ext     v17.16b, v10.16b, v10.16b, #4
    ext     v18.16b, v11.16b, v11.16b, #4
    b       .Lwindows_ready
.Lwin5:
    ext     v13.16b, v9.16b, v9.16b, #5
    ext     v17.16b, v10.16b, v10.16b, #5

    ext     v18.16b, v11.16b, v11.16b, #5
    b       .Lwindows_ready

.Lwindows_ready:
    uxtl    v19.8h, v13.8b
    uxtl    v20.4s, v19.4h
    ucvtf   v20.4s, v20.4s

    // G byte -> float
    uxtl    v19.8h, v17.8b
    uxtl    v21.4s, v19.4h
    ucvtf   v21.4s, v21.4s

    // R byte -> float
    uxtl    v19.8h, v18.8b
    uxtl    v22.4s, v19.4h
    ucvtf   v22.4s, v22.4s

    fmla    v14.4s, v20.4s, v12.4s
    fmla    v15.4s, v21.4s, v12.4s
    fmla    v16.4s, v22.4s, v12.4s

    add     w28, w28, #1
    cmp     w28, #7
    b.lt    .Lkx

    // Next source row.
    add     x6, x6, w21, uxtw #2

    add     w29, w29, #1
    cmp     w29, #7
    b.lt    .Lky

    // ---------------------------------------------------------------
    // Normalize and clamp.
    // ---------------------------------------------------------------
    fmul    v14.4s, v14.4s, v31.4s
    fmul    v15.4s, v15.4s, v31.4s
    fmul    v16.4s, v16.4s, v31.4s

    fadd    v14.4s, v14.4s, v30.4s
    fadd    v15.4s, v15.4s, v30.4s
    fadd    v16.4s, v16.4s, v30.4s

    fadd    v14.4s, v14.4s, v29.4s
    fadd    v15.4s, v15.4s, v29.4s
    fadd    v16.4s, v16.4s, v29.4s

    frintm  v14.4s, v14.4s
    frintm  v15.4s, v15.4s
    frintm  v16.4s, v16.4s

    fmax    v14.4s, v14.4s, v28.4s
    fmin    v14.4s, v14.4s, v27.4s

    fmax    v15.4s, v15.4s, v28.4s
    fmin    v15.4s, v15.4s, v27.4s

    fmax    v16.4s, v16.4s, v28.4s
    fmin    v16.4s, v16.4s, v27.4s

    fcvtzs  v14.4s, v14.4s
    fcvtzs  v15.4s, v15.4s
    fcvtzs  v16.4s, v16.4s

    // ---------------------------------------------------------------
    // Preserve alpha from src[y*width+x .. x+3].
    // ---------------------------------------------------------------
    mul     w28, w24, w21
    add     x7, x20, w28, uxtw #2
    add     x7, x7, w26, uxtw #2

    ld1     {v23.4s}, [x7]
    ushr    v23.4s, v23.4s, #24
    shl     v23.4s, v23.4s, #24

    // Pack AARRGGBB.
    shl     v16.4s, v16.4s, #16
    shl     v15.4s, v15.4s, #8

    orr     v16.16b, v16.16b, v15.16b
    orr     v16.16b, v16.16b, v14.16b
    orr     v16.16b, v16.16b, v23.16b

    // dst[y*width+x .. x+3]
    mul     w28, w24, w21
    add     x7, x19, w28, uxtw #2
    add     x7, x7, w26, uxtw #2

    st1     {v16.4s}, [x7]

    add     w26, w26, #4
    b       .Lx

.Lrow_tail:
    // Remaining 0..3 interior pixels are handled by the C++ scalar tail.
    // Continue with the next interior row.
    add     w24, w24, #1
    b       .Ly

.Ldone:
    // Return the common scalar-tail start:
    //   3 + floor((width - 6) / 4) * 4
    sub     w28, w21, #6
    and     w28, w28, #~3
    add     w0, w28, #3

.Lreturn:
    ldp     x29, x30, [sp, #80]
    ldp     x27, x28, [sp, #64]
    ldp     x25, x26, [sp, #48]
    ldp     x23, x24, [sp, #32]
    ldp     x21, x22, [sp, #16]
    ldp     x19, x20, [sp], #96
    ret

.size ksvgConvolve7x7NeonAsm, .-ksvgConvolve7x7NeonAsm
