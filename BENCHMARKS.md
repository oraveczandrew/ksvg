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
`kotlin → scalar → sse2 → ssse3 → avx2`; on ARM it is
`kotlin → scalar → neon32 → neon64`. Omit backends that were not measured.
Speedups are relative to `scalar` (`1.00x`).

Kernel rows are ordered alphabetically by kernel name; within each kernel, sizes are ordered from 512x512 to 2048x2048.

## Host Results (i7-7820X)

Measured on macOS 15.8 (24H23) (i7-7820X, 64-bit host build).

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 10.144 | 25.84 | 0.31 | 0.42x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 4.253 | 61.64 | 0.74 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.158 | 83.02 | 1.00 | 1.35x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.149 | 83.25 | 1.00 | 1.35x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 162.348 | 25.84 | 0.31 | 0.40x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 65.097 | 64.43 | 0.77 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 50.569 | 82.94 | 1.00 | 1.29x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 49.884 | 84.08 | 1.01 | 1.30x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.971 | 23.89 | 0.29 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.843 | 311.03 | 3.73 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.475 | 551.48 | 6.62 | 1.77x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.310 | 846.05 | 10.15 | 2.72x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 174.912 | 23.98 | 0.29 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.841 | 303.02 | 3.64 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 7.946 | 527.82 | 6.33 | 1.74x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.484 | 764.86 | 9.18 | 2.52x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.514 | 509.68 | 4.08 | 0.51x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.261 | 1005.67 | 8.05 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 9.342 | 448.99 | 3.59 | 0.50x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 4.690 | 894.24 | 7.15 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 19.212 | 13.64 | 0.11 | 1.37x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 26.302 | 9.97 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 4.655 | 56.31 | 0.45 | 5.65x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 512x512 | 2.505 | 104.66 | 0.84 | **10.50x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 307.505 | 13.64 | 0.11 | 1.35x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 414.411 | 10.12 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 70.602 | 59.41 | 0.48 | 5.87x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 2048x2048 | 34.264 | 122.41 | 0.98 | **12.09x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 32.262 | 8.13 | 0.07 | 0.83x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 26.800 | 9.78 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 4.801 | 54.60 | 0.44 | 5.58x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 512x512 | 2.907 | 90.16 | 0.72 | **9.22x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 515.487 | 8.14 | 0.07 | 0.82x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 425.104 | 9.87 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 73.575 | 57.01 | 0.46 | 5.78x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 2048x2048 | 39.750 | 105.52 | 0.84 | **10.69x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 4.473 | 58.61 | 0.70 | 0.57x |  |  |
| DisplacementMap | scalar | 512x512 | 2.538 | 103.30 | 1.24 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 1.206 | 217.43 | 2.61 | 2.10x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.945 | 277.43 | 3.33 | 2.69x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 71.714 | 58.49 | 0.70 | 0.53x |  |  |
| DisplacementMap | scalar | 2048x2048 | 38.145 | 109.96 | 1.32 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 19.074 | 219.90 | 2.64 | 2.00x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 15.391 | 272.51 | 3.27 | 2.48x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 12.393 | 21.15 | 0.17 | 1.47x | ⬆️ | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 512x512 | 18.226 | 14.38 | 0.12 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 11.263 | 23.27 | 0.19 | 1.62x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.196 | 42.31 | 0.34 | 2.94x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 370.041 | 11.33 | 0.09 | 0.83x |  | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 2048x2048 | 308.447 | 13.60 | 0.11 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 175.753 | 23.86 | 0.19 | 1.76x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 99.440 | 42.18 | 0.34 | 3.10x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 7.898 | 33.19 | 0.27 | 0.23x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 1.797 | 145.90 | 1.17 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 1.358 | 192.99 | 1.54 | 1.32x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.119 | 234.34 | 1.87 | 1.61x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 126.049 | 33.28 | 0.27 | 0.22x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 27.809 | 150.82 | 1.21 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 21.039 | 199.36 | 1.59 | 1.32x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 15.644 | 268.11 | 2.14 | 1.78x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 8.062 | 32.52 | 0.26 | 1.34x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 10.840 | 24.18 | 0.19 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 2.357 | 111.21 | 0.89 | 4.60x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 2.092 | 125.28 | 1.00 | 5.18x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 127.749 | 32.83 | 0.26 | 1.33x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 170.419 | 24.61 | 0.20 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 37.138 | 112.94 | 0.90 | 4.59x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 31.848 | 131.70 | 1.05 | 5.35x | 🟢 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 8.833 | 29.68 | 0.24 | 1.30x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 11.447 | 22.90 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 2.303 | 113.80 | 0.91 | 4.97x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 512x512 | 1.458 | 179.83 | 1.44 | 7.85x | 🟢 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 141.406 | 29.66 | 0.24 | 1.31x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 185.644 | 22.59 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 33.845 | 123.93 | 0.99 | 5.49x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 21.394 | 196.05 | 1.57 | 8.68x | 🟢 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 9.169 | 28.59 | 0.23 | 1.30x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 11.934 | 21.97 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 3.313 | 79.13 | 0.63 | 3.60x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.215 | 118.37 | 0.95 | 5.39x | 🟢 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 144.024 | 29.12 | 0.23 | 1.28x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 184.909 | 22.68 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 48.785 | 85.98 | 0.69 | 3.79x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 33.251 | 126.14 | 1.01 | 5.56x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 15.750 | 16.64 | 0.13 | 0.79x |  |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 12.382 | 21.17 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 2.410 | 108.76 | 0.87 | 5.14x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 512x512 | 1.575 | 166.46 | 1.33 | 7.86x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 139.230 | 30.12 | 0.24 | 1.38x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 192.741 | 21.76 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 32.874 | 127.59 | 1.02 | 5.86x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 23.047 | 181.99 | 1.46 | 8.36x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 9.025 | 29.05 | 0.23 | 1.40x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 12.647 | 20.73 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 7.411 | 35.37 | 0.28 | 1.71x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 7.232 | 36.25 | 0.29 | 1.75x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 143.186 | 29.29 | 0.23 | 1.37x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 196.435 | 21.35 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 114.218 | 36.72 | 0.29 | 1.72x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 111.683 | 37.56 | 0.30 | 1.76x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 15.336 | 17.09 | 0.14 | 1.17x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 17.987 | 14.57 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 8.757 | 29.94 | 0.24 | 2.05x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 7.635 | 34.33 | 0.27 | 2.36x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 246.027 | 17.05 | 0.14 | 1.16x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 285.099 | 14.71 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 138.699 | 30.24 | 0.24 | 2.06x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 120.949 | 34.68 | 0.28 | 2.36x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 15.378 | 17.05 | 0.14 | 1.18x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 18.126 | 14.46 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 9.787 | 26.78 | 0.21 | 1.85x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 11.223 | 23.36 | 0.19 | 1.62x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 246.370 | 17.02 | 0.14 | 1.17x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 288.494 | 14.54 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 155.308 | 27.01 | 0.22 | 1.86x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 176.552 | 23.76 | 0.19 | 1.63x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 19.326 | 13.56 | 0.11 | 1.00x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 19.281 | 13.60 | 0.11 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 7.602 | 34.48 | 0.28 | 2.54x | 🟢 |  |
| Lighting (specular, point) | avx2 | 512x512 | 6.611 | 39.65 | 0.32 | 2.92x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 309.544 | 13.55 | 0.11 | 0.98x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 303.098 | 13.84 | 0.11 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 112.875 | 37.16 | 0.30 | 2.69x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 97.329 | 43.09 | 0.34 | 3.11x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 19.381 | 13.53 | 0.11 | 1.11x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 21.493 | 12.20 | 0.10 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 8.556 | 30.64 | 0.25 | 2.51x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 8.191 | 32.01 | 0.26 | 2.62x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 308.663 | 13.59 | 0.11 | 0.98x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 303.581 | 13.82 | 0.11 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 113.825 | 36.85 | 0.29 | 2.67x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 105.977 | 39.58 | 0.32 | 2.86x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 17.558 | 14.93 | 0.12 | 1.12x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 19.629 | 13.35 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 8.927 | 29.36 | 0.23 | 2.20x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 512x512 | 10.359 | 25.31 | 0.20 | 1.89x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 281.904 | 14.88 | 0.12 | 1.13x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 319.230 | 13.14 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 139.447 | 30.08 | 0.24 | 2.29x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 158.062 | 26.54 | 0.21 | 2.02x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 17.989 | 14.57 | 0.12 | 1.21x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 21.803 | 12.02 | 0.10 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 10.464 | 25.05 | 0.20 | 2.08x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 11.358 | 23.08 | 0.18 | 1.92x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 309.415 | 13.56 | 0.11 | 1.27x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 391.469 | 10.71 | 0.09 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 204.375 | 20.52 | 0.16 | 1.92x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 157.963 | 26.55 | 0.21 | 2.48x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 10.852 | 24.16 | 0.19 | 2.76x | ⬆️ |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 29.993 | 8.74 | 0.07 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 512x512 | 2.660 | 98.56 | 0.79 | **11.28x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 512x512 | 2.350 | 111.57 | 0.89 | **12.77x** | 🚀 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 184.449 | 22.74 | 0.18 | 3.18x | ⬆️ |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 586.341 | 7.15 | 0.06 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 27.107 | 154.73 | 1.24 | **21.63x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 2048x2048 | 26.360 | 159.11 | 1.27 | **22.24x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 4.108 | 63.81 | 0.51 | 1.17x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 512x512 | 4.804 | 54.57 | 0.44 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 512x512 | 1.137 | 230.64 | 1.85 | 4.23x | 🟢 |  |
| Morphology (erode, r=1) | avx2 | 512x512 | 1.358 | 193.03 | 1.54 | 3.54x | 🟢 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 67.038 | 62.57 | 0.50 | 1.11x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 74.127 | 56.58 | 0.45 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 19.206 | 218.39 | 1.75 | 3.86x | 🟢 |  |
| Morphology (erode, r=1) | avx2 | 2048x2048 | 22.151 | 189.35 | 1.51 | 3.35x | 🟢 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 9.746 | 26.90 | 0.22 | 2.50x | ⬆️ |  |
| Morphology (erode, r=5) | scalar | 512x512 | 24.378 | 10.75 | 0.09 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 1.367 | 191.71 | 1.53 | **17.83x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 512x512 | 1.783 | 147.03 | 1.18 | **13.67x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 176.468 | 23.77 | 0.19 | 2.88x | ⬆️ |  |
| Morphology (erode, r=5) | scalar | 2048x2048 | 508.319 | 8.25 | 0.07 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 26.019 | 161.20 | 1.29 | **19.54x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 2048x2048 | 26.224 | 159.94 | 1.28 | **19.38x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 21.148 | 12.40 | 0.05 | 0.76x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 15.993 | 16.39 | 0.07 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 11.376 | 23.04 | 0.09 | 1.41x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 512x512 | 7.913 | 33.13 | 0.13 | 2.02x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 332.323 | 12.62 | 0.05 | 0.78x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 259.016 | 16.19 | 0.06 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 183.870 | 22.81 | 0.09 | 1.41x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 2048x2048 | 126.561 | 33.14 | 0.13 | 2.05x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.431 | 607.84 | 4.86 | 0.66x |  |  |
| UnLinearize | scalar | 512x512 | 0.285 | 920.87 | 7.37 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.262 | 999.71 | 8.00 | 1.09x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.290 | 905.03 | 7.24 | 0.98x | 🔴 | forced-only; production AVX2 runs the ssse3 approx kernel |
| UnLinearize | kotlin | 2048x2048 | 6.895 | 608.34 | 4.87 | 0.72x |  |  |
| UnLinearize | scalar | 2048x2048 | 4.960 | 845.59 | 6.76 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.283 | 979.39 | 7.84 | 1.16x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 4.890 | 857.77 | 6.86 | 1.01x | 🟢 | forced-only; production AVX2 runs the ssse3 approx kernel |

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
| Lighting (diffuse, distant) | kotlin | 512x512 | 15.81 | 16.59 | 0.13 | 1.42x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 22.42 | 11.69 | 0.09 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 6.17 | 42.48 | 0.34 | 3.63x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.61 | 162.67 | 1.30 | **13.91x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 234.43 | 17.89 | 0.14 | 1.53x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 359.42 | 11.67 | 0.09 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 92.91 | 45.14 | 0.36 | 3.87x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 13.23 | 317.11 | 2.54 | **27.17x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 14.87 | 17.63 | 0.14 | 3.38x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 50.26 | 5.22 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 6.45 | 40.63 | 0.33 | 7.79x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 3.41 | 76.98 | 0.62 | **14.76x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 236.80 | 17.71 | 0.14 | 3.35x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 793.13 | 5.29 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 97.22 | 43.14 | 0.35 | 8.16x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 43.00 | 97.54 | 0.78 | **18.45x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 15.85 | 16.54 | 0.13 | 3.47x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 54.96 | 4.77 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 7.34 | 35.73 | 0.29 | 7.49x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 512x512 | 1.99 | 131.46 | 1.05 | **27.56x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 251.02 | 16.71 | 0.13 | 3.46x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 868.14 | 4.83 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 107.94 | 38.86 | 0.31 | 8.04x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 18.00 | 233.03 | 1.86 | **48.23x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 15.78 | 16.62 | 0.13 | 3.54x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 55.84 | 4.69 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 7.47 | 35.08 | 0.28 | 7.47x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.74 | 95.76 | 0.77 | **20.40x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 250.20 | 16.76 | 0.13 | 3.54x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 886.53 | 4.73 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 112.63 | 37.24 | 0.30 | 7.87x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 30.08 | 139.44 | 1.12 | **29.47x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 19.32 | 13.57 | 0.11 | 2.90x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 56.11 | 4.67 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 7.48 | 35.04 | 0.28 | 7.50x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 512x512 | 7.89 | 33.22 | 0.27 | 7.11x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 306.54 | 13.68 | 0.11 | 2.94x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 899.70 | 4.66 | 0.04 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 113.00 | 37.12 | 0.30 | 7.96x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 114.59 | 36.60 | 0.29 | 7.85x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 19.18 | 13.67 | 0.11 | 2.99x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 57.32 | 4.57 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 7.84 | 33.45 | 0.27 | 7.31x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 8.23 | 31.83 | 0.25 | 6.96x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 304.67 | 13.77 | 0.11 | 2.97x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 906.15 | 4.63 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 121.28 | 34.58 | 0.28 | 7.47x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 121.80 | 34.44 | 0.28 | 7.44x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 44.65 | 5.87 | 0.05 | 1.60x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 71.56 | 3.66 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 26.87 | 9.76 | 0.08 | 2.66x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 11.26 | 23.29 | 0.19 | 6.36x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 689.01 | 6.09 | 0.05 | 1.63x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1121.78 | 3.74 | 0.03 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 409.09 | 10.25 | 0.08 | 2.74x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 161.14 | 26.03 | 0.21 | 6.96x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 44.25 | 5.92 | 0.05 | 1.64x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 72.58 | 3.61 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 26.36 | 9.95 | 0.08 | 2.75x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 11.71 | 22.38 | 0.18 | 6.20x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 702.61 | 5.97 | 0.05 | 1.63x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1144.78 | 3.66 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 410.17 | 10.23 | 0.08 | 2.79x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 169.98 | 24.68 | 0.20 | 6.73x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 47.71 | 5.49 | 0.04 | 1.61x | ⬆️ |  |
| Lighting (specular, point) | scalar | 512x512 | 76.68 | 3.42 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 31.24 | 8.39 | 0.07 | 2.45x | 🟢 |  |
| Lighting (specular, point) | avx2 | 512x512 | 30.05 | 8.72 | 0.07 | 2.55x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 756.87 | 5.54 | 0.04 | 1.58x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1192.39 | 3.52 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 487.02 | 8.61 | 0.07 | 2.45x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 463.12 | 9.06 | 0.07 | 2.57x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 48.09 | 5.45 | 0.04 | 1.61x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 77.55 | 3.38 | 0.03 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 31.33 | 8.37 | 0.07 | 2.48x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 31.19 | 8.41 | 0.07 | 2.49x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 760.00 | 5.52 | 0.04 | 1.59x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1211.57 | 3.46 | 0.03 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 494.04 | 8.49 | 0.07 | 2.45x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 482.93 | 8.69 | 0.07 | 2.51x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 48.56 | 5.40 | 0.04 | 1.59x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 77.44 | 3.38 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 30.02 | 8.73 | 0.07 | 2.58x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 512x512 | 35.53 | 7.38 | 0.06 | 2.18x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 767.46 | 5.47 | 0.04 | 1.60x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1227.87 | 3.42 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 467.45 | 8.97 | 0.07 | 2.63x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 546.38 | 7.68 | 0.06 | 2.25x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 49.12 | 5.34 | 0.04 | 1.60x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 78.72 | 3.33 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 31.25 | 8.39 | 0.07 | 2.52x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 35.39 | 7.41 | 0.06 | 2.22x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 785.26 | 5.34 | 0.04 | 1.61x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1263.84 | 3.32 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 491.31 | 8.54 | 0.07 | 2.57x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 548.75 | 7.64 | 0.06 | 2.30x | 🟢 |  |
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

Exception: the Lighting rows above were re-measured with an emulator image that advertises
`scalar`/`ssse3`/`avx2` for lighting (AVX2 executes natively there; no `sse2` lighting kernel
exists on this ABI, hence no `sse2` Lighting rows). Non-lighting rows are unchanged from the
previous session.

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
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 44.689 | 5.87 | 0.05 | 2.13x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 95.120 | 2.76 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | neon64 | 512x512 | 7.071 | 37.07 | 0.30 | **13.45x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 719.843 | 5.83 | 0.05 | 2.10x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 1510.285 | 2.78 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | neon64 | 2048x2048 | 93.725 | 44.75 | 0.36 | **16.11x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 58.946 | 4.45 | 0.04 | 1.63x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 95.987 | 2.73 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | neon64 | 512x512 | 6.833 | 38.36 | 0.31 | **14.05x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 942.178 | 4.45 | 0.04 | 1.62x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 1524.542 | 2.75 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | neon64 | 2048x2048 | 94.148 | 44.55 | 0.36 | **16.19x** | 🚀 |  |
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
| Lighting (diffuse, distant) | kotlin | 512x512 | 49.02 | 5.35 | 0.04 | 0.44x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 21.59 | 12.14 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 512x512 | 1.99 | 131.41 | 1.05 | **10.82x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 788.24 | 5.32 | 0.04 | 0.43x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 337.35 | 12.43 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 2048x2048 | 22.24 | 188.63 | 1.51 | **15.17x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 50.09 | 5.23 | 0.04 | 1.40x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 69.92 | 3.75 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon64 | 512x512 | 2.65 | 98.83 | 0.79 | **26.36x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 803.62 | 5.22 | 0.04 | 1.39x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 1117.73 | 3.75 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon64 | 2048x2048 | 31.30 | 133.99 | 1.07 | **35.71x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 62.99 | 4.16 | 0.03 | 1.11x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 70.09 | 3.74 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point) | neon64 | 512x512 | 2.24 | 116.82 | 0.93 | **31.23x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 1016.03 | 4.13 | 0.03 | 1.09x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1103.21 | 3.80 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point) | neon64 | 2048x2048 | 30.76 | 136.36 | 1.09 | **35.87x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 62.95 | 4.16 | 0.03 | 1.13x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 70.93 | 3.70 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon64 | 512x512 | 2.85 | 91.93 | 0.74 | **24.88x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 1014.01 | 4.14 | 0.03 | 1.10x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1112.07 | 3.77 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon64 | 2048x2048 | 34.01 | 123.31 | 0.99 | **32.69x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 63.85 | 4.11 | 0.03 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 83.63 | 3.13 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon64 | 512x512 | 2.67 | 98.25 | 0.79 | **31.35x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 1030.19 | 4.07 | 0.03 | 1.30x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 1341.09 | 3.13 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon64 | 2048x2048 | 33.83 | 123.99 | 0.99 | **39.65x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 64.17 | 4.09 | 0.03 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 84.20 | 3.11 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon64 | 512x512 | 3.17 | 82.64 | 0.66 | **26.54x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 1035.32 | 4.05 | 0.03 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1354.67 | 3.10 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon64 | 2048x2048 | 38.35 | 109.38 | 0.88 | **35.33x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 80.86 | 3.24 | 0.03 | 1.07x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 86.24 | 3.04 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 512x512 | 6.21 | 42.21 | 0.34 | **13.89x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 1303.31 | 3.22 | 0.03 | 1.04x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1355.43 | 3.09 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 2048x2048 | 85.70 | 48.94 | 0.39 | **15.82x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 81.07 | 3.23 | 0.03 | 1.07x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 87.04 | 3.01 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon64 | 512x512 | 6.61 | 39.67 | 0.32 | **13.17x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 1301.89 | 3.22 | 0.03 | 1.05x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1361.25 | 3.08 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon64 | 2048x2048 | 93.79 | 44.72 | 0.36 | **14.51x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 512x512 | 111.02 | 2.36 | 0.02 | 0.91x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 101.04 | 2.59 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon64 | 512x512 | 8.02 | 32.70 | 0.26 | **12.61x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 1773.85 | 2.36 | 0.02 | 0.89x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1584.35 | 2.65 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon64 | 2048x2048 | 114.23 | 36.72 | 0.29 | **13.87x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 111.05 | 2.36 | 0.02 | 0.92x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 102.29 | 2.56 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon64 | 512x512 | 8.55 | 30.64 | 0.25 | **11.96x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 1773.84 | 2.36 | 0.02 | 0.91x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1605.88 | 2.61 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon64 | 2048x2048 | 125.76 | 33.35 | 0.27 | **12.77x** | 🚀 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 112.11 | 2.34 | 0.02 | 1.03x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 115.43 | 2.27 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon64 | 512x512 | 8.33 | 31.47 | 0.25 | **13.86x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | kotlin | 2048x2048 | 1789.50 | 2.34 | 0.02 | 1.03x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1840.09 | 2.28 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon64 | 2048x2048 | 117.61 | 35.66 | 0.29 | **15.65x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 111.77 | 2.35 | 0.02 | 1.05x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 116.96 | 2.24 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon64 | 512x512 | 8.84 | 29.65 | 0.24 | **13.23x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 1791.54 | 2.34 | 0.02 | 1.04x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1862.09 | 2.25 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon64 | 2048x2048 | 128.29 | 32.69 | 0.26 | **14.52x** | 🚀 |  |
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
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 97.989 | 2.68 | 0.02 | 1.94x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 189.851 | 1.38 | 0.01 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | neon32 | 512x512 | 16.636 | 15.76 | 0.13 | **11.41x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 1528.437 | 2.74 | 0.02 | 1.85x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 2823.277 | 1.49 | 0.01 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | neon32 | 2048x2048 | 191.187 | 21.94 | 0.18 | **14.77x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 118.538 | 2.21 | 0.02 | 1.65x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 195.022 | 1.34 | 0.01 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | neon32 | 512x512 | 16.050 | 16.33 | 0.13 | **12.15x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 1870.232 | 2.24 | 0.02 | 1.57x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 2939.292 | 1.43 | 0.01 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | neon32 | 2048x2048 | 191.829 | 21.86 | 0.17 | **15.32x** | 🚀 |  |
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
| Lighting (diffuse, distant) | kotlin | 512x512 | 102.96 | 2.55 | 0.02 | 0.30x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 30.83 | 8.50 | 0.07 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon32 | 512x512 | 4.75 | 55.16 | 0.44 | 6.49x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 1638.64 | 2.56 | 0.02 | 0.27x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 445.44 | 9.42 | 0.08 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon32 | 2048x2048 | 50.47 | 83.11 | 0.66 | 8.83x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 104.02 | 2.52 | 0.02 | 0.82x |  |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 85.78 | 3.06 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon32 | 512x512 | 4.98 | 52.67 | 0.42 | **17.23x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 1627.88 | 2.58 | 0.02 | 0.76x |  |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 1232.46 | 3.40 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon32 | 2048x2048 | 56.71 | 73.96 | 0.59 | **21.73x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 139.87 | 1.87 | 0.01 | 0.70x |  |  |
| Lighting (diffuse, point) | scalar | 512x512 | 97.30 | 2.69 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point) | neon32 | 512x512 | 6.44 | 40.72 | 0.33 | **15.11x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 2211.21 | 1.90 | 0.02 | 0.64x |  |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1404.53 | 2.99 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point) | neon32 | 2048x2048 | 80.56 | 52.06 | 0.42 | **17.43x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 140.06 | 1.87 | 0.01 | 0.70x |  |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 98.19 | 2.67 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon32 | 512x512 | 6.97 | 37.61 | 0.30 | **14.09x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 2194.27 | 1.91 | 0.02 | 0.65x |  |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1428.51 | 2.94 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon32 | 2048x2048 | 90.05 | 46.58 | 0.37 | **15.86x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 145.94 | 1.80 | 0.01 | 0.74x |  |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 107.63 | 2.44 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon32 | 512x512 | 7.08 | 37.03 | 0.30 | **15.20x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 2333.27 | 1.80 | 0.01 | 0.66x |  |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 1547.12 | 2.71 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon32 | 2048x2048 | 89.35 | 46.94 | 0.38 | **17.31x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 145.15 | 1.81 | 0.01 | 0.75x |  |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 108.24 | 2.42 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon32 | 512x512 | 7.44 | 35.23 | 0.28 | **14.55x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 2348.12 | 1.79 | 0.01 | 0.67x |  |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1566.22 | 2.68 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon32 | 2048x2048 | 101.63 | 41.27 | 0.33 | **15.41x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 189.53 | 1.38 | 0.01 | 0.52x |  |  |
| Lighting (specular, distant) | scalar | 512x512 | 98.55 | 2.66 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon32 | 512x512 | 14.85 | 17.65 | 0.14 | 6.64x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 2931.19 | 1.43 | 0.01 | 0.51x |  |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1491.89 | 2.81 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon32 | 2048x2048 | 207.98 | 20.17 | 0.16 | 7.17x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 189.74 | 1.38 | 0.01 | 0.54x |  |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 103.21 | 2.54 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon32 | 512x512 | 17.00 | 15.42 | 0.12 | 6.07x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 2935.48 | 1.43 | 0.01 | 0.53x |  |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1555.43 | 2.70 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon32 | 2048x2048 | 241.96 | 17.34 | 0.14 | 6.43x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 222.69 | 1.18 | 0.01 | 0.50x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 111.44 | 2.35 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon32 | 512x512 | 19.13 | 13.71 | 0.11 | 5.83x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 3503.00 | 1.20 | 0.01 | 0.48x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1682.13 | 2.49 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon32 | 2048x2048 | 285.85 | 14.67 | 0.12 | 5.88x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 223.41 | 1.17 | 0.01 | 0.52x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 115.65 | 2.27 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon32 | 512x512 | 20.92 | 12.53 | 0.10 | 5.53x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 3516.18 | 1.19 | 0.01 | 0.50x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1742.88 | 2.41 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon32 | 2048x2048 | 308.35 | 13.60 | 0.11 | 5.65x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 230.83 | 1.14 | 0.01 | 0.53x |  |  |
| Lighting (specular, spot) | scalar | 512x512 | 121.45 | 2.16 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon32 | 512x512 | 18.76 | 13.97 | 0.11 | 6.47x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 3738.56 | 1.12 | 0.01 | 0.49x |  |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1819.09 | 2.31 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon32 | 2048x2048 | 275.18 | 15.24 | 0.12 | 6.61x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 232.51 | 1.13 | 0.01 | 0.54x |  |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 125.71 | 2.09 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon32 | 512x512 | 20.84 | 12.58 | 0.10 | 6.03x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 3748.84 | 1.12 | 0.01 | 0.50x |  |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1878.82 | 2.23 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon32 | 2048x2048 | 302.93 | 13.85 | 0.11 | 6.20x | 🟢 |  |
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
