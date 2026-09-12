# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels and Kotlin reference implementations compared to their scalar C++ counterparts.

Marker column: 🚀 very good speedup (>9x); 🟢 decent speedup; 🔴 regression (slower than the scalar baseline).

Measurements come from the benchmark harness median timings. A run is marked
`UNSTABLE` when all batches complete without thermal throttling but their batch
averages have a coefficient of variation above 5%. Unstable runs remain
displayed with their measured values. The Status icon still reflects the
measured speedup; the `⚠️ UNSTABLE` marker in the Note column indicates that
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
| ArithmeticComposite (linear) | kotlin | 512x512 | 10.640 | 24.64 | 0.20 | 0.38x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 4.048 | 64.76 | 0.52 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.097 | 84.65 | 0.68 | 1.31x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.074 | 85.27 | 0.68 | 1.32x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 171.370 | 24.48 | 0.20 | 0.38x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 65.412 | 64.12 | 0.51 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 50.489 | 83.07 | 0.66 | 1.30x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 49.534 | 84.67 | 0.68 | 1.32x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.464 | 25.05 | 0.20 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.835 | 313.82 | 2.51 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.466 | 562.11 | 4.50 | 1.79x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.293 | 895.72 | 7.17 | 2.85x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 167.910 | 24.98 | 0.20 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.772 | 304.55 | 2.44 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 7.794 | 538.12 | 4.30 | 1.77x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.249 | 799.06 | 6.39 | 2.62x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.511 | 513.43 | 4.11 | 0.50x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.258 | 1015.41 | 8.12 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 9.680 | 433.29 | 3.47 | 0.50x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 4.827 | 869.00 | 6.95 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 9.346 | 28.05 | 0.22 | 1.28x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 11.932 | 21.97 | 0.18 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 2.349 | 111.59 | 0.89 | 5.08x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 512x512 | 1.300 | 201.72 | 1.61 | **9.18x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx512 | 512x512 | 1.351 | 194.05 | 1.55 | 8.83x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 149.253 | 28.10 | 0.22 | 1.26x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 187.976 | 22.31 | 0.18 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 37.776 | 111.03 | 0.89 | 4.98x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 2048x2048 | 19.343 | 216.84 | 1.73 | **9.72x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx512 | 2048x2048 | 17.449 | 240.38 | 1.92 | **10.77x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 11.513 | 22.77 | 0.18 | 1.07x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 12.338 | 21.25 | 0.17 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 2.524 | 103.87 | 0.83 | 4.89x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 512x512 | 1.385 | 189.33 | 1.51 | 8.91x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx512 | 512x512 | 1.484 | 176.67 | 1.41 | 8.31x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 185.519 | 22.61 | 0.18 | 1.06x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 195.795 | 21.42 | 0.17 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 40.388 | 103.85 | 0.83 | 4.85x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 2048x2048 | 22.279 | 188.26 | 1.51 | 8.79x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx512 | 2048x2048 | 19.368 | 216.56 | 1.73 | **10.11x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 3.851 | 68.06 | 0.82 | 0.59x |  |  |
| DisplacementMap | scalar | 512x512 | 2.282 | 114.89 | 1.38 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 0.953 | 275.19 | 3.30 | 2.39x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.836 | 313.40 | 3.76 | 2.73x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.662 | 395.94 | 4.75 | 3.45x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 61.453 | 68.25 | 0.82 | 0.59x |  |  |
| DisplacementMap | scalar | 2048x2048 | 36.455 | 115.05 | 1.38 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 17.121 | 244.98 | 2.94 | 2.13x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 14.350 | 292.30 | 3.51 | 2.54x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 13.073 | 320.85 | 3.85 | 2.79x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 10.415 | 25.17 | 0.20 | 1.99x | ⬆️ | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 512x512 | 20.703 | 12.66 | 0.10 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 6.438 | 40.72 | 0.33 | 3.22x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.407 | 40.92 | 0.33 | 3.23x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 388.204 | 10.80 | 0.09 | 0.98x |  |  |
| GaussianBlur | scalar | 2048x2048 | 379.515 | 11.05 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 99.670 | 42.08 | 0.34 | 3.81x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 100.886 | 41.57 | 0.33 | 3.76x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 9.371 | 27.97 | 0.22 | 0.17x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 1.636 | 160.23 | 1.28 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 512x512 | 1.322 | 198.29 | 1.59 | 1.24x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.067 | 245.63 | 1.97 | 1.53x | 🟢 |  |
| Lighting (diffuse, distant) | avx512 | 512x512 | 1.130 | 232.07 | 1.86 | 1.45x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 149.262 | 28.10 | 0.22 | 0.18x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 27.024 | 155.21 | 1.24 | 1.00x |  |  |
| Lighting (diffuse, distant) | sse2 | 2048x2048 | 20.591 | 203.70 | 1.63 | 1.31x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 14.886 | 281.75 | 2.25 | 1.82x | 🟢 |  |
| Lighting (diffuse, distant) | avx512 | 2048x2048 | 13.238 | 316.83 | 2.53 | 2.04x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 17.431 | 15.04 | 0.12 | 1.38x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 24.010 | 10.92 | 0.09 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 512x512 | 24.487 | 10.71 | 0.09 | 0.98x | 🔴 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 23.622 | 11.10 | 0.09 | 1.02x | 🟢 |  |
| Lighting (specular, distant) | avx512 | 512x512 | 24.997 | 10.49 | 0.08 | 0.96x | 🔴 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 286.686 | 14.63 | 0.12 | 1.36x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 390.580 | 10.74 | 0.09 | 1.00x |  |  |
| Lighting (specular, distant) | sse2 | 2048x2048 | 378.323 | 11.09 | 0.09 | 1.03x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 384.519 | 10.91 | 0.09 | 1.02x | 🟢 |  |
| Lighting (specular, distant) | avx512 | 2048x2048 | 378.578 | 11.08 | 0.09 | 1.03x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 54.974 | 4.77 | 0.04 | 0.53x |  |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 28.997 | 9.04 | 0.07 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 512x512 | 2.082 | 125.93 | 1.01 | **13.93x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 512x512 | 1.857 | 141.15 | 1.13 | **15.61x** | 🚀 |  |
| Morphology (dilate, r=5) | avx512 | 512x512 | 3.886 | 67.47 | 0.54 | 7.46x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 932.680 | 4.50 | 0.04 | 0.62x |  |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 574.179 | 7.30 | 0.06 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 26.191 | 160.15 | 1.28 | **21.92x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 2048x2048 | 24.044 | 174.44 | 1.40 | **23.88x** | 🚀 |  |
| Morphology (dilate, r=5) | avx512 | 2048x2048 | 54.727 | 76.64 | 0.61 | **10.49x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 5.882 | 44.56 | 0.36 | 0.75x |  |  |
| Morphology (erode, r=1) | scalar | 512x512 | 4.419 | 59.32 | 0.47 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 512x512 | 0.937 | 279.75 | 2.24 | 4.72x | 🟢 |  |
| Morphology (erode, r=1) | avx2 | 512x512 | 1.093 | 239.81 | 1.92 | 4.04x | 🟢 |  |
| Morphology (erode, r=1) | avx512 | 512x512 | 1.111 | 235.98 | 1.89 | 3.98x | 🟢 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 94.818 | 44.24 | 0.35 | 0.80x |  |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 75.526 | 55.53 | 0.44 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 18.362 | 228.43 | 1.83 | 4.11x | 🟢 |  |
| Morphology (erode, r=1) | avx2 | 2048x2048 | 22.812 | 183.86 | 1.47 | 3.31x | 🟢 |  |
| Morphology (erode, r=1) | avx512 | 2048x2048 | 21.698 | 193.30 | 1.55 | 3.48x | 🟢 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 50.919 | 5.15 | 0.04 | 0.58x |  |  |
| Morphology (erode, r=5) | scalar | 512x512 | 29.594 | 8.86 | 0.07 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 1.335 | 196.42 | 1.57 | **22.17x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 512x512 | 1.370 | 191.32 | 1.53 | **21.60x** | 🚀 |  |
| Morphology (erode, r=5) | avx512 | 512x512 | 2.294 | 114.25 | 0.91 | **12.90x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 883.902 | 4.75 | 0.04 | 0.59x |  |  |
| Morphology (erode, r=5) | scalar | 2048x2048 | 521.206 | 8.05 | 0.06 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 25.051 | 167.43 | 1.34 | **20.81x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 2048x2048 | 24.512 | 171.11 | 1.37 | **21.26x** | 🚀 |  |
| Morphology (erode, r=5) | avx512 | 2048x2048 | 39.271 | 106.80 | 0.85 | **13.27x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 21.642 | 12.11 | 0.05 | 0.74x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 16.034 | 16.35 | 0.07 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 11.496 | 22.80 | 0.09 | 1.39x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 512x512 | 7.492 | 34.99 | 0.14 | 2.14x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 352.997 | 11.88 | 0.05 | 0.72x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 253.222 | 16.56 | 0.07 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 183.510 | 22.86 | 0.09 | 1.38x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 2048x2048 | 126.182 | 33.24 | 0.13 | 2.01x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.430 | 609.85 | 4.88 | 0.67x |  |  |
| UnLinearize | scalar | 512x512 | 0.286 | 916.83 | 7.33 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.251 | 1045.73 | 8.37 | 1.14x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.285 | 918.57 | 7.35 | 1.00x |  |  |
| UnLinearize | kotlin | 2048x2048 | 6.674 | 628.48 | 5.03 | 0.75x |  |  |
| UnLinearize | scalar | 2048x2048 | 5.007 | 837.65 | 6.70 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.314 | 972.27 | 7.78 | 1.16x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 4.860 | 862.95 | 6.90 | 1.03x | 🟢 |  |

## Host Results (x86-64, Android emulator)

Measured on the x86_64 Android emulator (API 37, 16 KB page-size image), on the same hardware.
Harness-reported median timings with the thermal gate disabled (`benchmark.thermalGating=false`).
Where a kernel row is missing a backend, that backend is not advertised on this ABI.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 60.927 | 4.30 | 0.05 | 0.35x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 21.321 | 12.30 | 0.15 | 1.00x |  | ⚠️ UNSTABLE |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 4.957 | 52.89 | 0.63 | 4.30x | 🟢 | ⚠️ UNSTABLE |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 760.435 | 5.52 | 0.07 | 0.36x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 274.144 | 15.30 | 0.18 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 83.002 | 50.53 | 0.61 | 3.30x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 55.096 | 4.76 | 0.06 | 0.49x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 27.026 | 9.70 | 0.12 | 1.00x |  | ⚠️ UNSTABLE |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 1.005 | 260.94 | 3.13 | 26.90x | 🚀 | ⚠️ UNSTABLE |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 642.725 | 6.53 | 0.08 | 0.53x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 339.891 | 12.34 | 0.15 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 13.718 | 305.76 | 3.67 | 24.78x | 🚀 | ⚠️ UNSTABLE |
| ComponentTransfer | kotlin | 512x512 | 1.205 | 217.58 | 1.74 | 1.29x | ⬆️ | ⚠️ UNSTABLE |
| ComponentTransfer | scalar | 512x512 | 1.552 | 168.95 | 1.35 | 1.00x |  | ⚠️ UNSTABLE |
| ComponentTransfer | kotlin | 2048x2048 | 21.787 | 192.52 | 1.54 | 1.33x | ⬆️ | ⚠️ UNSTABLE |
| ComponentTransfer | scalar | 2048x2048 | 29.052 | 144.37 | 1.15 | 1.00x |  | ⚠️ UNSTABLE |
| ConvolveMatrix | kotlin | 512x512 | 123.190 | 2.13 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | scalar | 512x512 | 123.583 | 2.12 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 8.040 | 32.61 | 0.26 | 15.37x | 🚀 | ⚠️ UNSTABLE |
| ConvolveMatrix | kotlin | 2048x2048 | 1455.733 | 2.88 | 0.02 | 1.05x |  |  |
| ConvolveMatrix | scalar | 2048x2048 | 1526.571 | 2.75 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 108.119 | 38.79 | 0.31 | 14.12x | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 9.093 | 28.83 | 0.35 | 1.00x |  | ⚠️ UNSTABLE |
| DisplacementMap | scalar | 512x512 | 9.080 | 28.87 | 0.35 | 1.00x |  | ⚠️ UNSTABLE |
| DisplacementMap | sse2 | 512x512 | 0.804 | 326.00 | 3.91 | 11.29x | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 130.693 | 32.09 | 0.39 | 1.07x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 139.742 | 30.01 | 0.36 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 14.047 | 298.58 | 3.58 | 9.95x | 🟢 | ⚠️ UNSTABLE |
| GaussianBlur | kotlin | 512x512 | 32.959 | 7.95 | 0.06 | 7.71x | ⬆️ | ⚠️ UNSTABLE |
| GaussianBlur | scalar | 512x512 | 254.062 | 1.03 | 0.01 | 1.00x |  | ⚠️ UNSTABLE |
| GaussianBlur | ssse3 | 512x512 | 19.099 | 13.73 | 0.11 | 13.30x | 🚀 | ⚠️ UNSTABLE |
| GaussianBlur | kotlin | 2048x2048 | 527.900 | 7.95 | 0.06 | 7.28x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 3844.961 | 1.09 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 236.114 | 17.76 | 0.14 | 16.28x | 🚀 |  |
| Lighting | kotlin | 512x512 | 94.599 | 2.77 | 0.02 | 0.22x |  | ⚠️ UNSTABLE |
| Lighting | scalar | 512x512 | 20.573 | 12.74 | 0.10 | 1.00x |  | ⚠️ UNSTABLE |
| Lighting | sse2 | 512x512 | 2.631 | 99.66 | 0.80 | 7.82x | 🟢 | ⚠️ UNSTABLE |
| Lighting | kotlin | 2048x2048 | 1010.447 | 4.15 | 0.03 | 0.33x |  |  |
| Lighting | scalar | 2048x2048 | 335.257 | 12.51 | 0.10 | 1.00x |  | ⚠️ UNSTABLE |
| Lighting | sse2 | 2048x2048 | 29.164 | 143.82 | 1.15 | 11.50x | 🚀 | ⚠️ UNSTABLE |
| Morphology | kotlin | 512x512 | 423.581 | 0.62 | 0.00 | 0.58x |  | ⚠️ UNSTABLE |
| Morphology | scalar | 512x512 | 245.395 | 1.07 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.544 | 169.73 | 1.36 | 158.88x | 🚀 | ⚠️ UNSTABLE |
| Morphology | kotlin | 2048x2048 | 5356.177 | 0.78 | 0.01 | 0.51x |  |  |
| Morphology | scalar | 2048x2048 | 2752.511 | 1.52 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 27.773 | 151.02 | 1.21 | 99.11x | 🚀 | ⚠️ UNSTABLE |
| Turbulence | kotlin | 512x512 | 444.130 | 0.59 | 0.00 | 0.14x |  |  |
| Turbulence | scalar | 512x512 | 63.413 | 4.13 | 0.02 | 1.00x |  | ⚠️ UNSTABLE |
| Turbulence | ssse3 | 512x512 | 16.020 | 16.36 | 0.07 | 3.96x | 🟢 | ⚠️ UNSTABLE |
| Turbulence | kotlin | 2048x2048 | 6508.910 | 0.64 | 0.00 | 0.12x |  |  |
| Turbulence | scalar | 2048x2048 | 760.877 | 5.51 | 0.02 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 215.300 | 19.48 | 0.08 | 3.53x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.685 | 382.79 | 3.06 | 2.19x | ⬆️ | ⚠️ UNSTABLE |
| UnLinearize | scalar | 512x512 | 1.501 | 174.65 | 1.40 | 1.00x |  | ⚠️ UNSTABLE |
| UnLinearize | ssse3 | 512x512 | 0.441 | 595.16 | 4.76 | 3.41x | 🟢 | ⚠️ UNSTABLE |
| UnLinearize | kotlin | 2048x2048 | 23.832 | 176.00 | 1.41 | 1.79x | ⬆️ | ⚠️ UNSTABLE |
| UnLinearize | scalar | 2048x2048 | 42.599 | 98.46 | 0.79 | 1.00x |  | ⚠️ UNSTABLE |
| UnLinearize | ssse3 | 2048x2048 | 9.902 | 423.60 | 3.39 | 4.30x | 🟢 | ⚠️ UNSTABLE |

The emulator reports only `scalar`/`sse2`/`ssse3`: AVX2/AVX-512 are not matched by runtime detection
(`detectSimdLevel()` stays below `SIMD_AVX2`) although the emulated CPU advertises `avx2`.

## Host Results (x86-32, Android emulator)

Measured on the x86 (32-bit) Android emulator, on the same hardware.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 20.306 | 12.91 | 0.15 | 1.11x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 22.588 | 11.61 | 0.14 | 1.00x |  |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 327.660 | 12.80 | 0.15 | 1.10x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 360.195 | 11.64 | 0.14 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 16.288 | 16.09 | 0.19 | 1.65x | ⬆️ |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 26.876 | 9.75 | 0.12 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 251.034 | 16.71 | 0.20 | 1.64x | ⬆️ |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 410.862 | 10.21 | 0.12 | 1.00x |  |  |
| ComponentTransfer | kotlin | 512x512 | 1.158 | 226.44 | 1.81 | 0.86x |  | ⚠️ UNSTABLE |
| ComponentTransfer | scalar | 512x512 | 0.998 | 262.58 | 2.10 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 18.454 | 227.29 | 1.82 | 0.95x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 17.591 | 238.43 | 1.91 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 73.365 | 3.57 | 0.03 | 1.53x | ⬆️ |  |
| ConvolveMatrix | scalar | 512x512 | 112.372 | 2.33 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 5.198 | 50.44 | 0.40 | **21.62x** | 🚀 |  |
| ConvolveMatrix | kotlin | 2048x2048 | 1082.690 | 3.87 | 0.03 | 1.56x | ⬆️ |  |
| ConvolveMatrix | scalar | 2048x2048 | 1686.815 | 2.49 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 70.181 | 59.76 | 0.48 | **24.04x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 4.304 | 60.90 | 0.73 | 1.86x | ⬆️ | ⚠️ UNSTABLE |
| DisplacementMap | scalar | 512x512 | 8.024 | 32.67 | 0.39 | 1.00x |  |  |
| DisplacementMap | ssse3 | 512x512 | 0.522 | 502.56 | 6.03 | **15.38x** | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 75.674 | 55.43 | 0.67 | 1.72x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 130.190 | 32.22 | 0.39 | 1.00x |  |  |
| DisplacementMap | ssse3 | 2048x2048 | 8.138 | 515.37 | 6.18 | **16.00x** | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 18.435 | 14.22 | 0.11 | **14.44x** | ⬆️ |  |
| GaussianBlur | scalar | 512x512 | 266.278 | 0.98 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 14.238 | 18.41 | 0.15 | **18.70x** | 🚀 | ⚠️ UNSTABLE |
| GaussianBlur | kotlin | 2048x2048 | 493.107 | 8.51 | 0.07 | 8.80x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 4340.264 | 0.97 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 186.870 | 22.45 | 0.18 | **23.23x** | 🚀 |  |
| Lighting | kotlin | 512x512 | 22.579 | 11.61 | 0.09 | 1.10x | ⬆️ |  |
| Lighting | scalar | 512x512 | 24.924 | 10.52 | 0.08 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.982 | 132.23 | 1.06 | **12.57x** | 🚀 |  |
| Lighting | kotlin | 2048x2048 | 350.623 | 11.96 | 0.10 | 1.10x | ⬆️ |  |
| Lighting | scalar | 2048x2048 | 384.266 | 10.92 | 0.09 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 21.524 | 194.87 | 1.56 | **17.85x** | 🚀 |  |
| Morphology | kotlin | 512x512 | 89.505 | 2.93 | 0.02 | 1.85x | ⬆️ |  |
| Morphology | scalar | 512x512 | 165.200 | 1.59 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.651 | 158.76 | 1.27 | **100.05x** | 🚀 | ⚠️ UNSTABLE |
| Morphology | kotlin | 2048x2048 | 1380.890 | 3.04 | 0.02 | 1.91x | ⬆️ |  |
| Morphology | scalar | 2048x2048 | 2634.523 | 1.59 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 29.444 | 142.45 | 1.14 | **89.48x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 447.657 | 0.59 | 0.00 | 0.17x |  |  |
| Turbulence | scalar | 512x512 | 77.718 | 3.37 | 0.01 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 15.032 | 17.44 | 0.07 | 5.17x | 🟢 |  |
| Turbulence | kotlin | 2048x2048 | 7042.852 | 0.60 | 0.00 | 0.17x |  |  |
| Turbulence | scalar | 2048x2048 | 1162.664 | 3.61 | 0.01 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 229.370 | 18.29 | 0.07 | 5.07x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 1.089 | 240.75 | 1.93 | 0.82x |  | ⚠️ UNSTABLE |
| UnLinearize | scalar | 512x512 | 0.889 | 295.00 | 2.36 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.247 | 1059.41 | 8.48 | 3.59x | 🟢 | ⚠️ UNSTABLE |
| UnLinearize | kotlin | 2048x2048 | 15.759 | 266.15 | 2.13 | 0.94x |  |  |
| UnLinearize | scalar | 2048x2048 | 14.803 | 283.35 | 2.27 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.151 | 1010.40 | 8.08 | 3.57x | 🟢 |  |

The emulator exposes only `scalar`/`sse2`/`ssse3` (AVX is gated out of runtime detection on 32-bit x86 by Android).
If a kernel row is missing a backend it is not advertised on this ABI. Morphology exposes only scalar/SSE2/AVX2/AVX-512 on x86.

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
| UnLinearize | kotlin | 2048x2048 | 7.502 | 559.10 | 4.47 | 2.80x | ⬆️ | ⚠️ UNSTABLE |
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
