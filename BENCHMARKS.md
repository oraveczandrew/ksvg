# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels and Kotlin reference implementations compared to their scalar C++ counterparts.

Marker column: 🚀 very good speedup (>9x); 🟢 decent speedup; 🔴 regression (slower than the scalar baseline).

Measurements come from the benchmark harness median timings. A run is marked
`UNSTABLE` when all batches complete without thermal throttling but their batch
averages have a coefficient of variation above 5%. Unstable runs remain
displayed with their measured values. The Status icon still reflects the
measured speedup; the `⚠️ UNSTABLE BENCH` marker in the Note column indicates that
the run is not reliable.

Kotlin rows use different status semantics: a slower Kotlin result has no
regression icon, while a faster result uses `⬆️` to indicate the improvement.

Within each kernel, backends are listed from the Kotlin reference and scalar
baseline through progressively wider ISA implementations. On x86 the order is
`kotlin → scalar → sse2 → ssse3 → avx2 → avx512`; on ARM it is
`kotlin → scalar → neon32 → neon64`. Omit backends that were not measured.
Speedups are relative to `scalar` (`1.00x`).

Kernel rows are ordered alphabetically by kernel name; within each kernel, sizes are ordered from 512x512 to 2048x2048.

## Host Results (i7-7820X)

Measured on macOS 15.8 (24H23) (i7-7820X, 64-bit host build).

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 9.780 | 26.80 | 0.32 | 0.40x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 3.895 | 67.30 | 0.81 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.054 | 85.83 | 1.03 | 1.28x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.068 | 85.44 | 1.03 | 1.27x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 155.571 | 26.96 | 0.32 | 0.40x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 62.732 | 66.86 | 0.80 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 48.768 | 86.01 | 1.03 | 1.29x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 47.409 | 88.47 | 1.06 | 1.32x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.510 | 24.94 | 0.30 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.818 | 320.36 | 3.84 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.465 | 563.43 | 6.76 | 1.76x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.287 | 913.22 | 10.96 | 2.85x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 168.711 | 24.86 | 0.30 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.065 | 321.03 | 3.85 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 7.550 | 555.51 | 6.67 | 1.73x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 4.943 | 848.61 | 10.18 | 2.64x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.576 | 454.89 | 3.64 | 0.42x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.244 | 1074.81 | 8.60 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 8.391 | 499.87 | 4.00 | 0.54x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 4.508 | 930.42 | 7.44 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 18.354 | 14.28 | 0.11 | 1.35x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 24.763 | 10.59 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 4.381 | 59.84 | 0.48 | 5.65x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 512x512 | 2.257 | 116.15 | 0.93 | **10.97x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx512 | 512x512 | 2.364 | 110.88 | 0.89 | **10.47x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 294.993 | 14.22 | 0.11 | 1.35x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 397.185 | 10.56 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 66.940 | 62.66 | 0.50 | 5.93x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 2048x2048 | 30.855 | 135.93 | 1.09 | **12.87x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx512 | 2048x2048 | 27.258 | 153.87 | 1.23 | **14.57x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 30.414 | 8.62 | 0.07 | 0.84x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 25.464 | 10.29 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 4.740 | 55.30 | 0.44 | 5.37x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 512x512 | 2.663 | 98.42 | 0.79 | **9.56x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx512 | 512x512 | 2.615 | 100.26 | 0.80 | **9.74x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 484.381 | 8.66 | 0.07 | 0.84x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 407.621 | 10.29 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 69.227 | 60.59 | 0.48 | 5.89x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 2048x2048 | 35.963 | 116.63 | 0.93 | **11.33x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx512 | 2048x2048 | 30.825 | 136.07 | 1.09 | **13.22x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 3.782 | 69.31 | 0.83 | 0.56x |  |  |
| DisplacementMap | scalar | 512x512 | 2.128 | 123.21 | 1.48 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 0.944 | 277.61 | 3.33 | 2.25x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.638 | 410.66 | 4.93 | 3.33x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.670 | 391.03 | 4.69 | 3.18x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 59.588 | 70.39 | 0.84 | 0.60x |  |  |
| DisplacementMap | scalar | 2048x2048 | 36.022 | 116.44 | 1.40 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 16.480 | 254.50 | 3.05 | 2.19x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 13.378 | 313.52 | 3.76 | 2.69x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 12.557 | 334.03 | 4.01 | 2.87x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 9.835 | 26.65 | 0.21 | 1.99x | ⬆️ | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 512x512 | 19.559 | 13.40 | 0.11 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 6.082 | 43.10 | 0.34 | 3.22x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 5.979 | 43.85 | 0.35 | 3.27x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 317.197 | 13.22 | 0.11 | 1.12x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 356.489 | 11.77 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 94.821 | 44.23 | 0.35 | 3.76x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 97.079 | 43.21 | 0.35 | 3.67x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 9.214 | 28.45 | 0.23 | 0.16x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 1.448 | 181.00 | 1.45 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 512x512 | 1.332 | 196.87 | 1.57 | 1.09x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 0.950 | 275.97 | 2.21 | 1.52x | 🟢 |  |
| Lighting (diffuse, distant) | avx512 | 512x512 | 1.219 | 215.09 | 1.72 | 1.19x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 147.991 | 28.34 | 0.23 | 0.18x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 26.045 | 161.04 | 1.29 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 2048x2048 | 20.144 | 208.22 | 1.67 | 1.29x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 14.852 | 282.41 | 2.26 | 1.75x | 🟢 |  |
| Lighting (diffuse, distant) | avx512 | 2048x2048 | 12.868 | 325.96 | 2.61 | 2.02x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 18.329 | 14.30 | 0.11 | 1.34x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 24.558 | 10.67 | 0.09 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 512x512 | 23.100 | 11.35 | 0.09 | 1.06x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 23.306 | 11.25 | 0.09 | 1.05x | 🟢 |  |
| Lighting (specular, distant) | avx512 | 512x512 | 23.304 | 11.25 | 0.09 | 1.05x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 274.101 | 15.30 | 0.12 | 1.37x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 376.693 | 11.13 | 0.09 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 2048x2048 | 365.708 | 11.47 | 0.09 | 1.03x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 368.143 | 11.39 | 0.09 | 1.02x | 🟢 |  |
| Lighting (specular, distant) | avx512 | 2048x2048 | 368.632 | 11.38 | 0.09 | 1.02x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 55.615 | 4.71 | 0.04 | 0.50x |  |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 27.976 | 9.37 | 0.07 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 512x512 | 1.989 | 131.79 | 1.05 | **14.07x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 512x512 | 1.965 | 133.38 | 1.07 | **14.24x** | 🚀 |  |
| Morphology (dilate, r=5) | avx512 | 512x512 | 3.630 | 72.21 | 0.58 | 7.71x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 945.878 | 4.43 | 0.04 | 0.59x |  |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 555.188 | 7.55 | 0.06 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 24.643 | 170.20 | 1.36 | **22.53x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 2048x2048 | 23.128 | 181.36 | 1.45 | **24.01x** | 🚀 |  |
| Morphology (dilate, r=5) | avx512 | 2048x2048 | 52.275 | 80.24 | 0.64 | **10.62x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 6.007 | 43.64 | 0.35 | 0.72x |  |  |
| Morphology (erode, r=1) | scalar | 512x512 | 4.315 | 60.76 | 0.49 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 512x512 | 0.948 | 276.63 | 2.21 | 4.55x | 🟢 |  |
| Morphology (erode, r=1) | avx2 | 512x512 | 1.088 | 240.91 | 1.93 | 3.97x | 🟢 |  |
| Morphology (erode, r=1) | avx512 | 512x512 | 1.095 | 239.35 | 1.91 | 3.94x | 🟢 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 99.202 | 42.28 | 0.34 | 0.72x |  |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 71.845 | 58.38 | 0.47 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 17.812 | 235.48 | 1.88 | 4.03x | 🟢 |  |
| Morphology (erode, r=1) | avx2 | 2048x2048 | 19.926 | 210.49 | 1.68 | 3.61x | 🟢 |  |
| Morphology (erode, r=1) | avx512 | 2048x2048 | 20.699 | 202.64 | 1.62 | 3.47x | 🟢 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 50.502 | 5.19 | 0.04 | 0.46x |  |  |
| Morphology (erode, r=5) | scalar | 512x512 | 23.358 | 11.22 | 0.09 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 1.331 | 196.88 | 1.58 | **17.55x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 512x512 | 1.281 | 204.71 | 1.64 | **18.24x** | 🚀 |  |
| Morphology (erode, r=5) | avx512 | 512x512 | 2.070 | 126.64 | 1.01 | **11.28x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 870.119 | 4.82 | 0.04 | 0.57x |  |  |
| Morphology (erode, r=5) | scalar | 2048x2048 | 492.863 | 8.51 | 0.07 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 23.537 | 178.20 | 1.43 | **20.94x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 2048x2048 | 23.556 | 178.05 | 1.42 | **20.92x** | 🚀 |  |
| Morphology (erode, r=5) | avx512 | 2048x2048 | 37.039 | 113.24 | 0.91 | **13.31x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 20.931 | 12.52 | 0.05 | 0.72x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 15.009 | 17.47 | 0.07 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 10.980 | 23.87 | 0.10 | 1.37x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 512x512 | 7.176 | 36.53 | 0.15 | 2.09x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 334.122 | 12.55 | 0.05 | 0.74x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 245.866 | 17.06 | 0.07 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 176.978 | 23.70 | 0.09 | 1.39x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 2048x2048 | 118.167 | 35.49 | 0.14 | 2.08x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.416 | 630.49 | 5.04 | 0.65x |  |  |
| UnLinearize | scalar | 512x512 | 0.270 | 970.32 | 7.76 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.245 | 1070.72 | 8.57 | 1.10x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.279 | 938.27 | 7.51 | 0.97x | 🔴 |  |
| UnLinearize | kotlin | 2048x2048 | 6.398 | 655.54 | 5.24 | 0.71x |  |  |
| UnLinearize | scalar | 2048x2048 | 4.544 | 923.14 | 7.39 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.174 | 1004.88 | 8.04 | 1.09x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 4.697 | 893.05 | 7.14 | 0.97x | 🔴 |  |

## Host Results (x86-64, Android emulator)

Measured on the x86_64 Android emulator (API 37, 16 KB page-size image), on the same hardware.
Harness-reported median timings with the thermal gate disabled (`benchmark.thermalGating=false`).
ConvolveMatrix measures the unified 5×5 kernel; ArithmeticComposite uses 3 buffers (12 B/px).
Where a kernel row is missing a backend, that backend is not advertised on this ABI.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 66.17 | 3.96 | 0.05 | 0.31x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | scalar | 512x512 | 20.52 | 12.77 | 0.15 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.96 | 66.17 | 0.79 | 5.18x | 🟢 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 950.82 | 4.41 | 0.05 | 0.40x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 379.29 | 11.06 | 0.13 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 63.22 | 66.34 | 0.80 | 6.00x | 🟢 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 51.78 | 5.06 | 0.06 | 0.49x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 25.51 | 10.27 | 0.12 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.58 | 453.98 | 5.45 | **44.19x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 979.56 | 4.28 | 0.05 | 0.39x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 380.65 | 11.02 | 0.13 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 9.01 | 465.30 | 5.58 | **42.23x** | 🚀 |  |
| ComponentTransfer | kotlin | 512x512 | 0.79 | 333.11 | 2.66 | 1.61x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ComponentTransfer | scalar | 512x512 | 1.27 | 207.14 | 1.66 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ComponentTransfer | kotlin | 2048x2048 | 15.93 | 263.37 | 2.11 | 1.21x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ComponentTransfer | scalar | 2048x2048 | 19.34 | 216.84 | 1.73 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 62.30 | 4.21 | 0.03 | 2.04x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 127.02 | 2.06 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 8.71 | 30.09 | 0.24 | **14.58x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 928.13 | 4.52 | 0.04 | 1.68x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 1562.25 | 2.68 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 102.19 | 41.04 | 0.33 | **15.29x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 73.26 | 3.58 | 0.03 | 1.42x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 104.28 | 2.51 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 6.56 | 39.98 | 0.32 | **15.90x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 1159.52 | 3.62 | 0.03 | 1.55x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 1796.29 | 2.33 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 74.30 | 56.45 | 0.45 | **24.18x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 5.63 | 46.53 | 0.56 | 1.25x | ⬆️ | ⚠️ UNSTABLE BENCH |
| DisplacementMap | scalar | 512x512 | 7.02 | 37.32 | 0.45 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 0.52 | 504.27 | 6.05 | **13.51x** | 🚀 | ⚠️ UNSTABLE BENCH |
| DisplacementMap | kotlin | 2048x2048 | 89.63 | 46.80 | 0.56 | 1.25x | ⬆️ | ⚠️ UNSTABLE BENCH |
| DisplacementMap | scalar | 2048x2048 | 112.23 | 37.37 | 0.45 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 9.19 | 456.30 | 5.48 | **12.21x** | 🚀 | ⚠️ UNSTABLE BENCH |
| GaussianBlur | kotlin | 512x512 | 22.33 | 11.74 | 0.09 | 10.18x | ⬆️ |  |
| GaussianBlur | scalar | 512x512 | 227.29 | 1.15 | 0.01 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| GaussianBlur | ssse3 | 512x512 | 17.52 | 14.97 | 0.12 | **12.98x** | 🚀 | ⚠️ UNSTABLE BENCH |
| GaussianBlur | kotlin | 2048x2048 | 535.36 | 7.83 | 0.06 | 6.75x | ⬆️ | ⚠️ UNSTABLE BENCH |
| GaussianBlur | scalar | 2048x2048 | 3612.31 | 1.16 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 185.26 | 22.64 | 0.18 | **19.50x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 53.38 | 4.91 | 0.04 | 0.28x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 15.21 | 17.24 | 0.14 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 512x512 | 1.42 | 184.69 | 1.48 | **10.71x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 845.74 | 4.96 | 0.04 | 0.29x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 247.78 | 16.93 | 0.14 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 2048x2048 | 16.30 | 257.30 | 2.06 | **15.20x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 97.27 | 2.69 | 0.02 | 0.63x |  |  |
| Lighting (specular, distant) | scalar | 512x512 | 61.34 | 4.27 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 512x512 | 62.99 | 4.16 | 0.03 | 0.97x | 🔴 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | kotlin | 2048x2048 | 1549.19 | 2.71 | 0.02 | 0.63x |  |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 972.28 | 4.31 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 2048x2048 | 968.85 | 4.33 | 0.03 | 1.00x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 372.51 | 0.70 | 0.01 | 0.36x |  |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 134.48 | 1.95 | 0.02 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 512x512 | 5.49 | 47.75 | 0.38 | **24.50x** | 🚀 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 5995.70 | 0.70 | 0.01 | 0.36x |  |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 2152.26 | 1.95 | 0.02 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 36.71 | 114.25 | 0.91 | **58.63x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 26.55 | 9.87 | 0.08 | 0.53x |  |  |
| Morphology (erode, r=1) | scalar | 512x512 | 14.14 | 18.55 | 0.15 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 512x512 | 0.76 | 346.16 | 2.77 | **18.67x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 419.14 | 10.01 | 0.08 | 0.54x |  |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 224.44 | 18.69 | 0.15 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 13.91 | 301.61 | 2.41 | **16.14x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 308.26 | 0.85 | 0.01 | 0.51x |  |  |
| Morphology (erode, r=5) | scalar | 512x512 | 157.69 | 1.66 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 1.07 | 244.17 | 1.95 | **146.88x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 7001.12 | 0.60 | 0.00 | 0.51x |  | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=5) | scalar | 2048x2048 | 3575.43 | 1.17 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 24.99 | 167.86 | 1.34 | **143.09x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 470.63 | 0.56 | 0.00 | 0.11x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 51.71 | 5.07 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 13.71 | 19.12 | 0.08 | 3.77x | 🟢 | ⚠️ UNSTABLE BENCH |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 7952.20 | 0.53 | 0.00 | 0.11x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 879.76 | 4.77 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 238.70 | 17.57 | 0.07 | 3.69x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.48 | 542.55 | 4.34 | 1.89x | ⬆️ | ⚠️ UNSTABLE BENCH |
| UnLinearize | scalar | 512x512 | 0.91 | 287.49 | 2.30 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| UnLinearize | ssse3 | 512x512 | 0.32 | 817.12 | 6.54 | 2.84x | 🟢 | ⚠️ UNSTABLE BENCH |
| UnLinearize | kotlin | 2048x2048 | 9.19 | 456.20 | 3.65 | 1.83x | ⬆️ |  |
| UnLinearize | scalar | 2048x2048 | 16.79 | 249.75 | 2.00 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 5.37 | 780.57 | 6.24 | 3.13x | 🟢 |  |

The emulator reports only `scalar`/`sse2`/`ssse3`: AVX2/AVX-512 are not matched by runtime detection
(`detectSimdLevel()` stays below `SIMD_AVX2`) although the emulated CPU advertises `avx2`.

Root cause (Android emulator 37.2.8.0 on macOS, HVF): the guest CPUID is served from a fixed mask
regardless of `-qemu -cpu model` (`max`, `Skylake-Server`, forced `osxsave=on,avx512f=on,...` all give
identical results) and `-cpu host` does not exist in this QEMU fork. The mask sets
`CPUID.1:ECX.OSXSAVE=0` (with `AVX=1`) and clears every `CPUID.7:EBX` AVX-512 bit, so
`__builtin_cpu_supports("avx"/"avx2"/"avx512*")` always returns 0 — 32-bit and 64-bit images alike.
Under HVF the AVX/AVX2/AVX-512 backends can therefore never be advertised by runtime detection;
only TCG software emulation would report them (slow). Use desktop/host native validation or forced
backend dispatch instead.

## Host Results (x86-32, Android emulator)

Measured on the x86 (32-bit) Android emulator, API 26, on the same hardware. ConvolveMatrix measures
the unified 5×5 kernel; ArithmeticComposite uses 3 buffers (12 B/px).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 15.51 | 16.90 | 0.20 | 1.37x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 21.17 | 12.38 | 0.15 | 1.00x |  |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 251.25 | 16.69 | 0.20 | 1.36x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 340.92 | 12.30 | 0.15 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 14.86 | 17.64 | 0.21 | 1.66x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 24.63 | 10.64 | 0.13 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 234.90 | 17.86 | 0.21 | 1.71x | ⬆️ |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 401.40 | 10.45 | 0.13 | 1.00x |  |  |
| ComponentTransfer | kotlin | 512x512 | 0.98 | 267.19 | 2.14 | 0.97x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.95 | 276.06 | 2.21 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 17.98 | 233.30 | 1.87 | 0.94x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 16.85 | 248.89 | 1.99 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 36.37 | 7.21 | 0.06 | 2.84x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 103.23 | 2.54 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 4.98 | 52.65 | 0.42 | **20.73x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 557.50 | 7.52 | 0.06 | 2.90x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 1614.13 | 2.60 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 61.74 | 67.93 | 0.54 | **26.14x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 40.66 | 6.45 | 0.05 | 2.59x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 105.30 | 2.49 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 5.88 | 44.58 | 0.36 | **17.91x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 641.66 | 6.54 | 0.05 | 2.62x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 1681.01 | 2.50 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 75.62 | 55.47 | 0.44 | **22.23x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 4.09 | 64.15 | 0.77 | 1.86x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 7.61 | 34.44 | 0.41 | 1.00x |  |  |
| DisplacementMap | ssse3 | 512x512 | 0.46 | 566.67 | 6.80 | **16.46x** | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 65.65 | 63.89 | 0.77 | 1.84x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 120.75 | 34.73 | 0.42 | 1.00x |  |  |
| DisplacementMap | ssse3 | 2048x2048 | 7.85 | 534.26 | 6.41 | **15.38x** | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 18.84 | 13.91 | 0.11 | 13.40x | ⬆️ | ⚠️ UNSTABLE BENCH |
| GaussianBlur | scalar | 512x512 | 252.55 | 1.04 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 12.46 | 21.03 | 0.17 | **20.26x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 487.55 | 8.60 | 0.07 | 8.46x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 4126.68 | 1.02 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 171.02 | 24.53 | 0.20 | **24.13x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 17.45 | 15.02 | 0.12 | 1.28x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 22.29 | 11.76 | 0.09 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 512x512 | 1.83 | 143.35 | 1.15 | **12.19x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 278.01 | 15.09 | 0.12 | 1.29x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 358.76 | 11.69 | 0.09 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 2048x2048 | 20.33 | 206.32 | 1.65 | **17.65x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 46.92 | 5.59 | 0.04 | 1.67x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 78.36 | 3.35 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 512x512 | 77.16 | 3.40 | 0.03 | 1.02x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 744.57 | 5.63 | 0.05 | 1.65x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1226.32 | 3.42 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 2048x2048 | 1231.76 | 3.41 | 0.03 | 1.00x | 🔴 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 104.95 | 2.50 | 0.02 | 1.25x | ⬆️ |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 131.34 | 2.00 | 0.02 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 512x512 | 5.43 | 48.32 | 0.39 | **24.21x** | 🚀 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 1679.63 | 2.50 | 0.02 | 1.25x | ⬆️ |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 2101.25 | 2.00 | 0.02 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 38.22 | 109.75 | 0.88 | **54.98x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 8.04 | 32.62 | 0.26 | 1.79x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 512x512 | 14.38 | 18.24 | 0.15 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 512x512 | 1.19 | 221.02 | 1.77 | **12.12x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 130.68 | 32.10 | 0.26 | 1.73x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 225.58 | 18.59 | 0.15 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 19.95 | 210.27 | 1.68 | **11.31x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 78.79 | 3.33 | 0.03 | 1.93x | ⬆️ |  |
| Morphology (erode, r=5) | scalar | 512x512 | 151.84 | 1.73 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 1.52 | 172.98 | 1.38 | **100.19x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 1291.27 | 3.25 | 0.03 | 1.92x | ⬆️ |  |
| Morphology (erode, r=5) | scalar | 2048x2048 | 2475.86 | 1.69 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 24.96 | 168.06 | 1.34 | **99.20x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 414.96 | 0.63 | 0.00 | 0.17x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 68.82 | 3.81 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 13.52 | 19.40 | 0.08 | 5.09x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 6718.53 | 0.62 | 0.00 | 0.16x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 1106.69 | 3.79 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 216.97 | 19.33 | 0.08 | 5.10x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.52 | 500.06 | 4.00 | 1.59x | ⬆️ |  |
| UnLinearize | scalar | 512x512 | 0.83 | 314.16 | 2.51 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.22 | 1187.54 | 9.50 | 3.78x | 🟢 | ⚠️ UNSTABLE BENCH |
| UnLinearize | kotlin | 2048x2048 | 9.21 | 455.25 | 3.64 | 1.52x | ⬆️ |  |
| UnLinearize | scalar | 2048x2048 | 13.98 | 300.04 | 2.40 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.14 | 1012.00 | 8.10 | 3.37x | 🟢 |  |

The emulator exposes only `scalar`/`sse2`/`ssse3`. This is not a 32-bit x86/Android gating quirk: the
emulator's HVF layer hard-masks guest CPUID (`OSXSAVE=0`, all AVX-512 bits cleared) on 64-bit images
too, so `__builtin_cpu_supports` never advertises AVX. See the note in the x86-64 emulator section.
If a kernel row is missing a backend it is not advertised on this ABI.

## Device Results (OnePlus 11)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2), `arm64-v8a`; non-quick harness run (512x512 and 2048x2048, median timings).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 53.538 | 4.90 | 0.06 | 0.39x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 20.716 | 12.65 | 0.15 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon64 | 512x512 | 2.534 | 103.47 | 1.24 | 8.18x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 864.065 | 4.85 | 0.06 | 0.38x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 331.498 | 12.65 | 0.15 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon64 | 2048x2048 | 38.864 | 107.92 | 1.30 | 8.53x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 46.950 | 5.58 | 0.07 | 0.41x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 19.390 | 13.52 | 0.16 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon64 | 512x512 | 1.206 | 217.33 | 2.61 | **16.08x** | 🚀 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 759.939 | 5.52 | 0.07 | 0.42x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 315.398 | 13.30 | 0.16 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon64 | 2048x2048 | 19.223 | 218.20 | 2.62 | **16.41x** | 🚀 |  |
| ComponentTransfer | kotlin | 512x512 | 1.134 | 231.18 | 1.85 | 1.33x | ⬆️ |  |
| ComponentTransfer | scalar | 512x512 | 1.510 | 173.63 | 1.39 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 18.235 | 230.02 | 1.84 | 1.35x | ⬆️ |  |
| ComponentTransfer | scalar | 2048x2048 | 24.614 | 170.40 | 1.36 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 77.071 | 3.40 | 0.03 | 1.46x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 112.591 | 2.33 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | neon64 | 512x512 | 7.028 | 37.30 | 0.30 | **16.02x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 1221.639 | 3.43 | 0.03 | 1.45x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 1777.191 | 2.36 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | neon64 | 2048x2048 | 98.984 | 42.37 | 0.34 | **17.95x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 101.962 | 2.57 | 0.02 | 1.12x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 113.857 | 2.30 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | neon64 | 512x512 | 104.320 | 2.51 | 0.02 | 1.09x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 1584.696 | 2.65 | 0.02 | 1.14x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 1804.660 | 2.32 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | neon64 | 2048x2048 | 1652.203 | 2.54 | 0.02 | 1.09x | 🟢 |  |
| DisplacementMap | kotlin | 512x512 | 5.454 | 48.07 | 0.58 | 1.24x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 6.737 | 38.91 | 0.47 | 1.00x |  |  |
| DisplacementMap | neon64 | 512x512 | 0.546 | 480.26 | 5.76 | **12.34x** | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 87.064 | 48.17 | 0.58 | 1.24x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 108.314 | 38.72 | 0.46 | 1.00x |  |  |
| DisplacementMap | neon64 | 2048x2048 | 8.784 | 477.51 | 5.73 | **12.33x** | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 12.397 | 21.15 | 0.17 | **23.52x** | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 291.558 | 0.90 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon64 | 512x512 | 5.228 | 50.14 | 0.40 | **55.77x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 196.646 | 21.33 | 0.17 | **24.09x** | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 2048x2048 | 4736.735 | 0.89 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon64 | 2048x2048 | 83.793 | 50.06 | 0.40 | **56.53x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 90.848 | 2.89 | 0.02 | 0.28x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 25.355 | 10.34 | 0.08 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 512x512 | 2.342 | 111.95 | 0.90 | **10.83x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 1501.312 | 2.79 | 0.02 | 0.27x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 398.324 | 10.53 | 0.08 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 2048x2048 | 26.744 | 156.83 | 1.25 | **14.89x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 160.734 | 1.63 | 0.01 | 0.60x |  |  |
| Lighting (specular, distant) | scalar | 512x512 | 96.883 | 2.71 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 512x512 | 98.740 | 2.65 | 0.02 | 0.98x |  |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 2588.797 | 1.62 | 0.01 | 0.58x |  |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1513.089 | 2.77 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 2048x2048 | 1538.032 | 2.73 | 0.02 | 0.98x |  |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 360.973 | 0.73 | 0.01 | 0.56x |  |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 202.227 | 1.30 | 0.01 | 1.00x |  |  |
| Morphology (dilate, r=5) | neon64 | 512x512 | 7.518 | 34.87 | 0.28 | **26.90x** | 🚀 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 6855.477 | 0.61 | 0.00 | 0.56x |  |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 3813.869 | 1.10 | 0.01 | 1.00x |  |  |
| Morphology (dilate, r=5) | neon64 | 2048x2048 | 58.282 | 71.97 | 0.58 | **65.44x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 28.793 | 9.10 | 0.07 | 0.71x |  |  |
| Morphology (erode, r=1) | scalar | 512x512 | 20.482 | 12.80 | 0.10 | 1.00x |  |  |
| Morphology (erode, r=1) | neon64 | 512x512 | 0.664 | 394.73 | 3.16 | **30.84x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 464.271 | 9.03 | 0.07 | 0.70x |  |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 324.513 | 12.92 | 0.10 | 1.00x |  |  |
| Morphology (erode, r=1) | neon64 | 2048x2048 | 10.327 | 406.16 | 3.25 | **31.42x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 348.403 | 0.75 | 0.01 | 0.56x |  |  |
| Morphology (erode, r=5) | scalar | 512x512 | 195.405 | 1.34 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | neon64 | 512x512 | 1.981 | 132.32 | 1.06 | **98.63x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 5735.494 | 0.73 | 0.01 | 0.56x |  |  |
| Morphology (erode, r=5) | scalar | 2048x2048 | 3210.916 | 1.31 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | neon64 | 2048x2048 | 28.266 | 148.38 | 1.19 | **113.59x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 624.422 | 0.42 | 0.00 | 0.17x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 107.768 | 2.43 | 0.01 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | neon64 | 512x512 | 5.342 | 49.07 | 0.20 | **20.17x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 9932.603 | 0.42 | 0.00 | 0.17x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 1714.652 | 2.45 | 0.01 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | neon64 | 2048x2048 | 85.097 | 49.29 | 0.20 | **20.15x** | 🚀 |  |
| UnLinearize | kotlin | 512x512 | 0.516 | 507.63 | 4.06 | 2.51x | ⬆️ |  |
| UnLinearize | scalar | 512x512 | 1.295 | 202.39 | 1.62 | 1.00x |  |  |
| UnLinearize | kotlin | 2048x2048 | 7.502 | 559.10 | 4.47 | 2.80x | ⬆️ | ⚠️ UNSTABLE BENCH |
| UnLinearize | scalar | 2048x2048 | 21.007 | 199.66 | 1.60 | 1.00x |  |  |

## Device Results (OnePlus 11, 32-bit ARM)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2), `armeabi-v7a`; non-quick harness run (512x512 and 2048x2048, median timings).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 88.451 | 2.96 | 0.04 | 0.36x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 32.090 | 8.17 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 512x512 | 9.564 | 27.41 | 0.33 | 3.36x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 1419.548 | 2.95 | 0.04 | 0.36x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 512.997 | 8.18 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 2048x2048 | 154.459 | 27.15 | 0.33 | 3.32x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 73.587 | 3.56 | 0.04 | 0.42x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 30.693 | 8.54 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 512x512 | 2.282 | 114.90 | 1.38 | **13.45x** | 🚀 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 1179.419 | 3.56 | 0.04 | 0.42x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 490.773 | 8.55 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 2048x2048 | 36.597 | 114.61 | 1.38 | **13.41x** | 🚀 |  |
| ComponentTransfer | kotlin | 512x512 | 1.989 | 131.81 | 1.05 | 0.74x |  |  |
| ComponentTransfer | scalar | 512x512 | 1.478 | 177.33 | 1.42 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 31.822 | 131.81 | 1.05 | 0.76x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 24.316 | 172.49 | 1.38 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 181.112 | 1.45 | 0.01 | 1.06x | ⬆️ |  |
| ConvolveMatrix | scalar | 512x512 | 191.301 | 1.37 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 2048x2048 | 2851.253 | 1.47 | 0.01 | 0.98x |  |  |
| ConvolveMatrix | scalar | 2048x2048 | 2799.770 | 1.50 | 0.01 | 1.00x |  |  |
| DisplacementMap | kotlin | 512x512 | 10.025 | 26.15 | 0.31 | 1.05x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 10.481 | 25.01 | 0.30 | 1.00x |  |  |
| DisplacementMap | neon32 | 512x512 | 0.966 | 271.40 | 3.26 | **10.85x** | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 180.692 | 23.21 | 0.28 | 1.03x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 186.921 | 22.44 | 0.27 | 1.00x |  |  |
| DisplacementMap | neon32 | 2048x2048 | 23.084 | 181.70 | 2.18 | 8.10x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 27.400 | 9.57 | 0.08 | 13.63x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 373.322 | 0.70 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 512x512 | 8.751 | 29.96 | 0.24 | **42.66x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 501.422 | 8.36 | 0.07 | 12.00x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 2048x2048 | 6018.733 | 0.70 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 2048x2048 | 138.898 | 30.20 | 0.24 | **43.33x** | 🚀 |  |
| Lighting | kotlin | 512x512 | 123.008 | 2.13 | 0.02 | 0.25x |  |  |
| Lighting | scalar | 512x512 | 31.008 | 8.45 | 0.07 | 1.00x |  |  |
| Lighting | neon32 | 512x512 | 4.020 | 65.20 | 0.52 | 7.71x | 🟢 | hand-written NEON distant diffuse |
| Lighting | kotlin | 2048x2048 | 1956.286 | 2.14 | 0.02 | 0.23x |  |  |
| Lighting | scalar | 2048x2048 | 445.750 | 9.41 | 0.08 | 1.00x |  |  |
| Lighting | neon32 | 2048x2048 | 39.709 | 105.63 | 0.85 | **11.23x** | 🚀 | hand-written NEON distant diffuse |
| Morphology | kotlin | 512x512 | 798.700 | 0.33 | 0.00 | 0.74x |  |  |
| Morphology | scalar | 512x512 | 588.604 | 0.45 | 0.00 | 1.00x |  |  |
| Morphology | neon32 | 512x512 | 3.226 | 81.27 | 0.65 | **182.48x** | 🚀 |  |
| Morphology | kotlin | 2048x2048 | 13146.189 | 0.32 | 0.00 | 0.73x |  |  |
| Morphology | scalar | 2048x2048 | 9608.014 | 0.44 | 0.00 | 1.00x |  |  |
| Morphology | neon32 | 2048x2048 | 38.421 | 109.17 | 0.87 | **250.07x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 814.613 | 0.32 | 0.00 | 0.16x |  |  |
| Turbulence | scalar | 512x512 | 133.616 | 1.96 | 0.01 | 1.00x |  |  |
| Turbulence | neon32 | 512x512 | 19.859 | 13.20 | 0.05 | 6.73x | 🟢 |  |
| Turbulence | kotlin | 2048x2048 | 12926.138 | 0.32 | 0.00 | 0.16x |  |  |
| Turbulence | scalar | 2048x2048 | 2132.623 | 1.97 | 0.01 | 1.00x |  |  |
| Turbulence | neon32 | 2048x2048 | 316.337 | 13.26 | 0.05 | 6.74x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 1.217 | 215.43 | 1.72 | 0.92x |  |  |
| UnLinearize | scalar | 512x512 | 1.119 | 234.25 | 1.87 | 1.00x |  |  |
| UnLinearize | kotlin | 2048x2048 | 19.844 | 211.37 | 1.69 | 0.92x |  |  |
| UnLinearize | scalar | 2048x2048 | 18.206 | 230.38 | 1.84 | 1.00x |  |  |
