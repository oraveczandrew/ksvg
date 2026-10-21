# KSVG Filter Kernel Benchmarks

> **Native-kernel/perf work only** — do NOT load for functional changes.
> Tables: SIMD speedups over the scalar baseline. Regeneration: `docs/RENDERING_FILTERING.md` §6.1.

Speedups relative to `scalar` (`1.00x`). Status: 🚀 >9x, 🟢 faster, 🔴 regression; Kotlin faster = ⬆️. `⚠️ UNSTABLE BENCH` = CoV >5%.
Row order per kernel: `kotlin → scalar → sse2 → ssse3 → avx2` (x86), `kotlin → scalar → neon32 → neon64` (ARM).

## Host Results (i7-7820X)

macOS 15.8, i7-7820X, 64-bit host build.

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 9.855 | 26.60 | 0.32 | 0.40x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 3.953 | 66.32 | 0.80 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 2.997 | 87.46 | 1.05 | 1.32x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 1.805 | 145.23 | 1.74 | 2.19x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 156.879 | 26.74 | 0.32 | 0.40x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 63.178 | 66.39 | 0.80 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 47.922 | 87.52 | 1.05 | 1.32x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 28.999 | 144.64 | 1.74 | 2.18x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.617 | 24.69 | 0.30 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.798 | 328.39 | 3.94 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.465 | 563.38 | 6.76 | 1.72x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.251 | 1042.35 | 12.51 | 3.17x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 169.375 | 24.76 | 0.30 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.214 | 317.42 | 3.81 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 7.798 | 537.85 | 6.45 | 1.69x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 4.728 | 887.20 | 10.65 | 2.79x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.514 | 509.68 | 4.08 | 0.51x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.261 | 1005.67 | 8.05 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 9.342 | 448.99 | 3.59 | 0.50x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 4.690 | 894.24 | 7.15 | 1.00x |  |  |
| ColorMatrix (linear) | kotlin | 512x512 | 5.268 | 49.76 | 0.60 | 0.62x |  |  |
| ColorMatrix (linear) | scalar | 512x512 | 3.288 | 79.74 | 0.96 | 1.00x |  |  |
| ColorMatrix (linear) | ssse3 | 512x512 | 2.128 | 123.18 | 1.48 | 1.54x | 🟢 |  |
| ColorMatrix (linear) | avx2 | 512x512 | 1.134 | 231.22 | 2.77 | 2.90x | 🟢 |  |
| ColorMatrix (linear) | kotlin | 2048x2048 | 85.004 | 49.34 | 0.59 | 0.63x |  |  |
| ColorMatrix (linear) | scalar | 2048x2048 | 53.189 | 78.86 | 0.95 | 1.00x |  |  |
| ColorMatrix (linear) | ssse3 | 2048x2048 | 33.958 | 123.51 | 1.48 | 1.57x | 🟢 |  |
| ColorMatrix (linear) | avx2 | 2048x2048 | 18.235 | 230.01 | 2.76 | 2.92x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 512x512 | 5.594 | 46.86 | 0.56 | 0.13x |  |  |
| ColorMatrix (non-linear) | scalar | 512x512 | 0.744 | 352.33 | 4.23 | 1.00x |  |  |
| ColorMatrix (non-linear) | ssse3 | 512x512 | 0.875 | 299.51 | 3.59 | 0.85x | 🔴 |  |
| ColorMatrix (non-linear) | avx2 | 512x512 | 0.426 | 614.76 | 7.38 | 1.74x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 2048x2048 | 92.488 | 45.35 | 0.54 | 0.13x |  |  |
| ColorMatrix (non-linear) | scalar | 2048x2048 | 12.057 | 347.87 | 4.17 | 1.00x |  |  |
| ColorMatrix (non-linear) | ssse3 | 2048x2048 | 14.568 | 287.90 | 3.45 | 0.83x | 🔴 |  |
| ColorMatrix (non-linear) | avx2 | 2048x2048 | 7.405 | 566.44 | 6.80 | 1.63x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 19.737 | 13.28 | 0.11 | 1.30x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 25.563 | 10.25 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 4.577 | 57.27 | 0.46 | 5.58x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 512x512 | 2.127 | 123.23 | 0.99 | **12.02x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 314.825 | 13.32 | 0.11 | 1.31x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 413.389 | 10.15 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 71.054 | 59.03 | 0.47 | 5.82x | 🟢 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 2048x2048 | 29.107 | 144.10 | 1.15 | **14.20x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 30.982 | 8.46 | 0.07 | 0.85x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 26.450 | 9.91 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 4.799 | 54.63 | 0.44 | 5.51x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 512x512 | 2.369 | 110.65 | 0.89 | **11.16x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 513.421 | 8.17 | 0.07 | 0.82x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 418.615 | 10.02 | 0.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 71.912 | 58.33 | 0.47 | 5.82x | 🟢 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 2048x2048 | 30.934 | 135.59 | 1.08 | **13.53x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 4.473 | 58.61 | 0.70 | 0.57x |  |  |
| DisplacementMap | scalar | 512x512 | 2.538 | 103.30 | 1.24 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 1.206 | 217.43 | 2.61 | 2.10x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.945 | 277.43 | 3.33 | 2.69x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 71.714 | 58.49 | 0.70 | 0.53x |  |  |
| DisplacementMap | scalar | 2048x2048 | 38.145 | 109.96 | 1.32 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 19.074 | 219.90 | 2.64 | 2.00x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 15.391 | 272.51 | 3.27 | 2.48x | 🟢 |  |
| FeBlend (hue, linear) | kotlin | 512x512 | 26.359 | 9.95 | 0.12 | 0.39x |  |  |
| FeBlend (hue, linear) | scalar | 512x512 | 10.404 | 25.20 | 0.30 | 1.00x |  |  |
| FeBlend (hue, linear) | ssse3 | 512x512 | 10.364 | 25.29 | 0.30 | 1.00x |  |  |
| FeBlend (hue, linear) | avx2 | 512x512 | 10.372 | 25.27 | 0.30 | 1.00x |  |  |
| FeBlend (hue, linear) | kotlin | 2048x2048 | 403.080 | 10.41 | 0.12 | 0.41x |  |  |
| FeBlend (hue, linear) | scalar | 2048x2048 | 167.144 | 25.09 | 0.30 | 1.00x |  |  |
| FeBlend (hue, linear) | ssse3 | 2048x2048 | 167.035 | 25.11 | 0.30 | 1.00x |  |  |
| FeBlend (hue, linear) | avx2 | 2048x2048 | 167.560 | 25.03 | 0.30 | 1.00x |  |  |
| FeBlend (multiply, linear) | kotlin | 512x512 | 7.961 | 32.93 | 0.40 | 0.53x |  |  |
| FeBlend (multiply, linear) | scalar | 512x512 | 4.205 | 62.34 | 0.75 | 1.00x |  |  |
| FeBlend (multiply, linear) | ssse3 | 512x512 | 3.769 | 69.55 | 0.83 | 1.12x | 🟢 |  |
| FeBlend (multiply, linear) | avx2 | 512x512 | 2.678 | 97.90 | 1.17 | 1.57x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 2048x2048 | 127.518 | 32.89 | 0.39 | 0.53x |  |  |
| FeBlend (multiply, linear) | scalar | 2048x2048 | 67.283 | 62.34 | 0.75 | 1.00x |  |  |
| FeBlend (multiply, linear) | ssse3 | 2048x2048 | 59.885 | 70.04 | 0.84 | 1.12x | 🟢 |  |
| FeBlend (multiply, linear) | avx2 | 2048x2048 | 44.623 | 93.99 | 1.13 | 1.51x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 512x512 | 8.031 | 32.64 | 0.39 | 0.43x |  |  |
| FeBlend (multiply, non-linear) | scalar | 512x512 | 3.438 | 76.25 | 0.92 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | ssse3 | 512x512 | 2.253 | 116.37 | 1.40 | 1.53x | 🟢 |  |
| FeBlend (multiply, non-linear) | avx2 | 512x512 | 1.904 | 137.68 | 1.65 | 1.81x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 2048x2048 | 127.482 | 32.90 | 0.39 | 0.42x |  |  |
| FeBlend (multiply, non-linear) | scalar | 2048x2048 | 54.095 | 77.54 | 0.93 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | ssse3 | 2048x2048 | 35.651 | 117.65 | 1.41 | 1.52x | 🟢 |  |
| FeBlend (multiply, non-linear) | avx2 | 2048x2048 | 30.125 | 139.23 | 1.67 | 1.80x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 10.530 | 24.89 | 0.20 | 1.92x | ⬆️ |  |
| GaussianBlur | scalar | 512x512 | 20.270 | 12.93 | 0.10 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 11.280 | 23.24 | 0.19 | 1.80x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 5.453 | 48.07 | 0.38 | 3.72x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 254.820 | 16.46 | 0.13 | 1.36x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 346.348 | 12.11 | 0.10 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 173.351 | 24.20 | 0.19 | 2.00x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 85.429 | 49.10 | 0.39 | 4.05x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 7.983 | 32.84 | 0.26 | 0.20x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 1.580 | 165.96 | 1.33 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 1.258 | 208.43 | 1.67 | 1.26x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 0.956 | 274.16 | 2.19 | 1.65x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 126.880 | 33.06 | 0.26 | 0.21x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 26.273 | 159.64 | 1.28 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 20.065 | 209.03 | 1.67 | 1.31x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 15.257 | 274.91 | 2.20 | 1.72x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 7.856 | 33.37 | 0.27 | 1.29x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 10.168 | 25.78 | 0.21 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 2.318 | 113.08 | 0.90 | 4.39x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 1.982 | 132.28 | 1.06 | 5.13x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 124.405 | 33.71 | 0.27 | 1.30x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 161.387 | 25.99 | 0.21 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 36.800 | 113.98 | 0.91 | 4.39x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 30.617 | 136.99 | 1.10 | 5.27x | 🟢 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 8.567 | 30.60 | 0.24 | 1.39x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 11.924 | 21.98 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 2.488 | 105.37 | 0.84 | 4.79x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 512x512 | 1.420 | 184.67 | 1.48 | 8.40x | 🟢 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 139.944 | 29.97 | 0.24 | 1.24x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 173.767 | 24.14 | 0.19 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 31.855 | 131.67 | 1.05 | 5.45x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 19.628 | 213.69 | 1.71 | 8.85x | 🟢 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 8.624 | 30.40 | 0.24 | 1.30x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 11.228 | 23.35 | 0.19 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 2.914 | 89.97 | 0.72 | 3.85x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.030 | 129.12 | 1.03 | 5.53x | 🟢 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 138.410 | 30.30 | 0.24 | 1.33x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 183.460 | 22.86 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 46.940 | 89.35 | 0.71 | 3.91x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 30.658 | 136.81 | 1.09 | 5.98x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 11.068 | 23.68 | 0.19 | 1.07x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 11.850 | 22.12 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 2.233 | 117.39 | 0.94 | 5.31x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 512x512 | 1.574 | 166.54 | 1.33 | 7.53x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 142.525 | 29.43 | 0.24 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 186.930 | 22.44 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 32.781 | 127.95 | 1.02 | 5.70x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 22.312 | 187.98 | 1.50 | 8.38x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 9.699 | 27.03 | 0.22 | 1.24x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 12.042 | 21.77 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 3.222 | 81.37 | 0.65 | 3.74x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 2.330 | 112.50 | 0.90 | 5.17x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 152.463 | 27.51 | 0.22 | 1.25x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 190.194 | 22.05 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 47.639 | 88.04 | 0.70 | 3.99x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 34.296 | 122.30 | 0.98 | 5.55x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 15.629 | 16.77 | 0.13 | 1.12x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 17.519 | 14.96 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 4.335 | 60.47 | 0.48 | 4.04x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 2.232 | 117.47 | 0.94 | 7.85x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 241.515 | 17.37 | 0.14 | 1.15x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 276.673 | 15.16 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 66.353 | 63.21 | 0.51 | 4.17x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 29.427 | 142.53 | 1.14 | **9.40x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 15.457 | 16.96 | 0.14 | 1.19x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 18.348 | 14.29 | 0.11 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 6.272 | 41.79 | 0.33 | 2.93x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 3.285 | 79.80 | 0.64 | 5.59x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 245.454 | 17.09 | 0.14 | 1.15x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 282.682 | 14.84 | 0.12 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 92.392 | 45.40 | 0.36 | 3.06x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 44.280 | 94.72 | 0.76 | 6.38x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 18.908 | 13.86 | 0.11 | 0.98x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 18.496 | 14.17 | 0.11 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 6.854 | 38.25 | 0.31 | 2.70x | 🟢 |  |
| Lighting (specular, point) | avx2 | 512x512 | 3.274 | 80.07 | 0.64 | 5.65x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 301.627 | 13.91 | 0.11 | 0.99x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 299.189 | 14.02 | 0.11 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 105.154 | 39.89 | 0.32 | 2.85x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 45.641 | 91.90 | 0.74 | 6.56x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 18.926 | 13.85 | 0.11 | 1.02x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 19.233 | 13.63 | 0.11 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 7.085 | 37.00 | 0.30 | 2.71x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 4.480 | 58.51 | 0.47 | 4.29x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 312.257 | 13.43 | 0.11 | 1.00x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 311.606 | 13.46 | 0.11 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 108.612 | 38.62 | 0.31 | 2.87x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 68.114 | 61.58 | 0.49 | 4.57x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 19.318 | 13.57 | 0.11 | 0.99x |  |  |
| Lighting (specular, spot) | scalar | 512x512 | 19.053 | 13.76 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 7.112 | 36.86 | 0.29 | 2.68x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 512x512 | 3.041 | 86.21 | 0.69 | 6.27x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 295.900 | 14.17 | 0.11 | 1.03x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 303.570 | 13.82 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 107.685 | 38.95 | 0.31 | 2.82x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 43.106 | 97.30 | 0.78 | 7.04x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 19.041 | 13.77 | 0.11 | 1.04x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 19.712 | 13.30 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 7.387 | 35.49 | 0.28 | 2.67x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 11.883 | 22.06 | 0.18 | 1.66x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 308.353 | 13.60 | 0.11 | 1.01x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 311.019 | 13.49 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 111.772 | 37.53 | 0.30 | 2.78x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 180.086 | 23.29 | 0.19 | 1.73x | 🟢 |  |
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

x86_64 emulator (API 29), thermal gating off. Missing backend = not advertised on this ABI.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 16.33 | 16.05 | 0.19 | 2.01x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 32.78 | 8.00 | 0.10 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 5.07 | 51.69 | 0.62 | 6.46x | 🟢 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | avx2 | 512x512 | 4.67 | 56.11 | 0.67 | 7.02x | 🟢 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 252.59 | 16.61 | 0.20 | 0.92x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 233.62 | 17.95 | 0.22 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 58.07 | 72.22 | 0.87 | 4.02x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 35.04 | 119.71 | 1.44 | 6.67x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 16.80 | 15.61 | 0.19 | 1.26x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 21.18 | 12.38 | 0.15 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.50 | 521.23 | 6.25 | **42.11x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.27 | 962.55 | 11.55 | **77.78x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 475.71 | 8.82 | 0.11 | 0.80x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 382.53 | 10.96 | 0.13 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.40 | 499.55 | 5.99 | **45.56x** | 🚀 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 4.76 | 881.68 | 10.58 | **80.41x** | 🚀 |  |
| ColorMatrix (linear) | kotlin | 512x512 | 12.70 | 20.65 | 0.25 | 0.89x |  |  |
| ColorMatrix (linear) | scalar | 512x512 | 11.31 | 23.19 | 0.28 | 1.00x |  |  |
| ColorMatrix (linear) | ssse3 | 512x512 | 2.26 | 115.84 | 1.39 | 5.00x | 🟢 |  |
| ColorMatrix (linear) | avx2 | 512x512 | 1.21 | 216.85 | 2.60 | **9.35x** | 🚀 |  |
| ColorMatrix (linear) | kotlin | 2048x2048 | 200.66 | 20.90 | 0.25 | 0.83x |  |  |
| ColorMatrix (linear) | scalar | 2048x2048 | 167.33 | 25.07 | 0.30 | 1.00x |  |  |
| ColorMatrix (linear) | ssse3 | 2048x2048 | 35.93 | 116.73 | 1.40 | 4.66x | 🟢 |  |
| ColorMatrix (linear) | avx2 | 2048x2048 | 19.83 | 211.50 | 2.54 | 8.44x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 512x512 | 11.84 | 22.14 | 0.27 | 0.84x |  |  |
| ColorMatrix (non-linear) | scalar | 512x512 | 9.96 | 26.32 | 0.32 | 1.00x |  |  |
| ColorMatrix (non-linear) | ssse3 | 512x512 | 0.88 | 299.40 | 3.59 | **11.37x** | 🚀 |  |
| ColorMatrix (non-linear) | avx2 | 512x512 | 0.44 | 592.45 | 7.11 | **22.51x** | 🚀 |  |
| ColorMatrix (non-linear) | kotlin | 2048x2048 | 189.70 | 22.11 | 0.27 | 0.85x |  |  |
| ColorMatrix (non-linear) | scalar | 2048x2048 | 160.40 | 26.15 | 0.31 | 1.00x |  |  |
| ColorMatrix (non-linear) | ssse3 | 2048x2048 | 14.98 | 280.04 | 3.36 | **10.71x** | 🚀 |  |
| ColorMatrix (non-linear) | avx2 | 2048x2048 | 7.47 | 561.69 | 6.74 | **21.48x** | 🚀 |  |
| ComponentTransfer | kotlin | 512x512 | 0.93 | 282.30 | 2.26 | 1.03x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ComponentTransfer | scalar | 512x512 | 0.96 | 273.50 | 2.19 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 15.53 | 270.08 | 2.16 | 1.04x | ⬆️ |  |
| ComponentTransfer | scalar | 2048x2048 | 16.16 | 259.60 | 2.08 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 29.38 | 8.92 | 0.07 | 3.01x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 88.50 | 2.96 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 5.30 | 49.44 | 0.40 | **16.69x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 512x512 | 3.30 | 79.42 | 0.64 | **26.81x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 473.24 | 8.86 | 0.07 | 3.90x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 1844.38 | 2.27 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 69.63 | 60.23 | 0.48 | **26.49x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 2048x2048 | 28.44 | 147.46 | 1.18 | **64.84x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 38.08 | 6.88 | 0.06 | 2.82x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 107.44 | 2.44 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 5.50 | 47.70 | 0.38 | **19.55x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 512x512 | 3.76 | 69.74 | 0.56 | **28.58x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 543.10 | 7.72 | 0.06 | 2.72x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 1474.92 | 2.84 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 72.73 | 57.67 | 0.46 | **20.28x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 2048x2048 | 32.53 | 128.92 | 1.03 | **45.33x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 4.90 | 53.46 | 0.64 | 1.39x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 6.83 | 38.39 | 0.46 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 0.54 | 484.07 | 5.81 | **12.61x** | 🚀 |  |
| DisplacementMap | avx2 | 512x512 | 0.31 | 857.95 | 10.30 | **22.35x** | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 81.29 | 51.59 | 0.62 | 1.35x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 109.95 | 38.15 | 0.46 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 9.19 | 456.64 | 5.48 | **11.97x** | 🚀 |  |
| DisplacementMap | avx2 | 2048x2048 | 5.50 | 762.35 | 9.15 | **19.98x** | 🚀 |  |
| FeBlend (hue, linear) | kotlin | 512x512 | 48.84 | 5.37 | 0.06 | 1.19x | ⬆️ | ⚠️ UNSTABLE BENCH |
| FeBlend (hue, linear) | scalar | 512x512 | 57.95 | 4.52 | 0.05 | 1.00x |  |  |
| FeBlend (hue, linear) | ssse3 | 512x512 | 57.97 | 4.52 | 0.05 | 1.00x | 🔴 |  |
| FeBlend (hue, linear) | avx2 | 512x512 | 58.07 | 4.51 | 0.05 | 1.00x | 🔴 |  |
| FeBlend (hue, linear) | kotlin | 2048x2048 | 799.61 | 5.25 | 0.06 | 1.14x | ⬆️ |  |
| FeBlend (hue, linear) | scalar | 2048x2048 | 908.30 | 4.62 | 0.06 | 1.00x |  |  |
| FeBlend (hue, linear) | ssse3 | 2048x2048 | 897.23 | 4.67 | 0.06 | 1.01x | 🟢 |  |
| FeBlend (hue, linear) | avx2 | 2048x2048 | 922.31 | 4.55 | 0.05 | 0.98x | 🔴 |  |
| FeBlend (multiply, linear) | kotlin | 512x512 | 16.04 | 16.34 | 0.20 | 0.88x |  |  |
| FeBlend (multiply, linear) | scalar | 512x512 | 14.08 | 18.61 | 0.22 | 1.00x |  |  |
| FeBlend (multiply, linear) | ssse3 | 512x512 | 3.92 | 66.95 | 0.80 | 3.60x | 🟢 |  |
| FeBlend (multiply, linear) | avx2 | 512x512 | 2.82 | 93.12 | 1.12 | 5.00x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 2048x2048 | 252.96 | 16.58 | 0.20 | 0.89x |  |  |
| FeBlend (multiply, linear) | scalar | 2048x2048 | 225.45 | 18.60 | 0.22 | 1.00x |  |  |
| FeBlend (multiply, linear) | ssse3 | 2048x2048 | 63.21 | 66.35 | 0.80 | 3.57x | 🟢 |  |
| FeBlend (multiply, linear) | avx2 | 2048x2048 | 79.05 | 53.06 | 0.64 | 2.85x | 🟢 | ⚠️ UNSTABLE BENCH |
| FeBlend (multiply, non-linear) | kotlin | 512x512 | 26.94 | 9.73 | 0.12 | 0.66x |  | ⚠️ UNSTABLE BENCH |
| FeBlend (multiply, non-linear) | scalar | 512x512 | 17.77 | 14.75 | 0.18 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| FeBlend (multiply, non-linear) | ssse3 | 512x512 | 2.40 | 109.01 | 1.31 | 7.39x | 🟢 |  |
| FeBlend (multiply, non-linear) | avx2 | 512x512 | 1.91 | 137.47 | 1.65 | **9.32x** | 🚀 |  |
| FeBlend (multiply, non-linear) | kotlin | 2048x2048 | 276.10 | 15.19 | 0.18 | 1.42x | ⬆️ |  |
| FeBlend (multiply, non-linear) | scalar | 2048x2048 | 392.52 | 10.69 | 0.13 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| FeBlend (multiply, non-linear) | ssse3 | 2048x2048 | 57.15 | 73.40 | 0.88 | 6.87x | 🟢 | ⚠️ UNSTABLE BENCH |
| FeBlend (multiply, non-linear) | avx2 | 2048x2048 | 33.06 | 126.87 | 1.52 | **11.87x** | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 15.37 | 17.06 | 0.14 | 17.17x | ⬆️ |  |
| GaussianBlur | scalar | 512x512 | 263.84 | 0.99 | 0.01 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| GaussianBlur | ssse3 | 512x512 | 13.03 | 20.13 | 0.16 | **20.25x** | 🚀 |  |
| GaussianBlur | avx2 | 512x512 | 7.76 | 33.78 | 0.27 | **34.00x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 448.82 | 9.35 | 0.07 | 9.48x | ⬆️ | ⚠️ UNSTABLE BENCH |
| GaussianBlur | scalar | 2048x2048 | 4253.41 | 0.99 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 175.30 | 23.93 | 0.19 | **24.26x** | 🚀 |  |
| GaussianBlur | avx2 | 2048x2048 | 94.19 | 44.53 | 0.36 | **45.16x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 15.83 | 16.56 | 0.13 | 0.96x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 15.21 | 17.24 | 0.14 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 1.33 | 196.78 | 1.57 | **11.42x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.14 | 230.09 | 1.84 | **13.35x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 299.56 | 14.00 | 0.11 | 0.89x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 265.34 | 15.81 | 0.13 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 16.01 | 261.96 | 2.10 | **16.57x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 11.50 | 364.59 | 2.92 | **23.06x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 17.65 | 14.85 | 0.12 | 2.21x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 39.04 | 6.71 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 2.57 | 101.92 | 0.82 | **15.18x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 3.28 | 79.98 | 0.64 | **11.91x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 313.55 | 13.38 | 0.11 | 1.94x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 607.90 | 6.90 | 0.06 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 40.70 | 103.05 | 0.82 | **14.93x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 31.70 | 132.33 | 1.06 | **19.18x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 20.30 | 12.91 | 0.10 | 2.77x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 56.18 | 4.67 | 0.04 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | ssse3 | 512x512 | 3.47 | 75.60 | 0.60 | **16.20x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | avx2 | 512x512 | 2.57 | 102.18 | 0.82 | **21.90x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 864.00 | 4.85 | 0.04 | 1.20x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1040.97 | 4.03 | 0.03 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 40.26 | 104.19 | 0.83 | **25.86x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 18.15 | 231.13 | 1.85 | **57.36x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 17.64 | 14.86 | 0.12 | 2.43x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 42.88 | 6.11 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 3.08 | 85.11 | 0.68 | **13.92x** | 🚀 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.56 | 102.41 | 0.82 | **16.75x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 406.29 | 10.32 | 0.08 | 2.86x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1160.79 | 3.61 | 0.03 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 57.31 | 73.18 | 0.59 | **20.25x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 33.54 | 125.05 | 1.00 | **34.61x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | kotlin | 512x512 | 30.88 | 8.49 | 0.07 | 2.06x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | scalar | 512x512 | 63.74 | 4.11 | 0.03 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 2.95 | 88.93 | 0.71 | **21.63x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | avx2 | 512x512 | 2.71 | 96.74 | 0.77 | **23.52x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 326.69 | 12.84 | 0.10 | 2.11x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 687.93 | 6.10 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 31.29 | 134.05 | 1.07 | **21.99x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 22.53 | 186.15 | 1.49 | **30.53x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 20.85 | 12.57 | 0.10 | 2.12x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 44.21 | 5.93 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 3.11 | 84.31 | 0.67 | **14.22x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 2.61 | 100.58 | 0.80 | **16.96x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 338.62 | 12.39 | 0.10 | 2.18x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 737.27 | 5.69 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 43.08 | 97.36 | 0.78 | **17.11x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 30.85 | 135.94 | 1.09 | **23.90x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 24.55 | 10.68 | 0.09 | 1.68x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | scalar | 512x512 | 41.31 | 6.35 | 0.05 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 4.19 | 62.54 | 0.50 | **9.86x** | 🚀 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 2.52 | 104.21 | 0.83 | **16.42x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 522.16 | 8.03 | 0.06 | 1.76x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 919.62 | 4.56 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 100.61 | 41.69 | 0.33 | **9.14x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | avx2 | 2048x2048 | 26.50 | 158.25 | 1.27 | **34.70x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 33.41 | 7.85 | 0.06 | 1.77x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 59.20 | 4.43 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 6.99 | 37.51 | 0.30 | 8.47x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 3.48 | 75.40 | 0.60 | **17.03x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 528.65 | 7.93 | 0.06 | 1.82x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 961.55 | 4.36 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 104.83 | 40.01 | 0.32 | **9.17x** | 🚀 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 43.85 | 95.65 | 0.77 | **21.93x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 512x512 | 39.84 | 6.58 | 0.05 | 1.72x | ⬆️ |  |
| Lighting (specular, point) | scalar | 512x512 | 68.57 | 3.82 | 0.03 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point) | ssse3 | 512x512 | 6.98 | 37.53 | 0.30 | **9.82x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point) | avx2 | 512x512 | 3.47 | 75.52 | 0.60 | **19.75x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point) | kotlin | 2048x2048 | 464.17 | 9.04 | 0.07 | 1.68x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 778.45 | 5.39 | 0.04 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point) | ssse3 | 2048x2048 | 104.36 | 40.19 | 0.32 | 7.46x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 43.51 | 96.41 | 0.77 | **17.89x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 29.09 | 9.01 | 0.07 | 1.66x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 48.27 | 5.43 | 0.04 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 7.27 | 36.06 | 0.29 | 6.64x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 4.63 | 56.61 | 0.45 | **10.42x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 496.07 | 8.46 | 0.07 | 1.58x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 786.13 | 5.34 | 0.04 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 111.52 | 37.61 | 0.30 | 7.05x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 63.81 | 65.73 | 0.53 | **12.32x** | 🚀 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 30.23 | 8.67 | 0.07 | 1.68x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 50.82 | 5.16 | 0.04 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 7.60 | 34.48 | 0.28 | 6.68x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | avx2 | 512x512 | 4.48 | 58.58 | 0.47 | **11.36x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | kotlin | 2048x2048 | 702.40 | 5.97 | 0.05 | 1.65x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1162.24 | 3.61 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 167.18 | 25.09 | 0.20 | 6.95x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 42.91 | 97.76 | 0.78 | **27.09x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 43.04 | 6.09 | 0.05 | 1.71x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 73.77 | 3.55 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 12.19 | 21.50 | 0.17 | 6.05x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 15.51 | 16.90 | 0.14 | 4.76x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 469.54 | 8.93 | 0.07 | 1.84x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 865.32 | 4.85 | 0.04 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 122.25 | 34.31 | 0.27 | 7.08x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 189.54 | 22.13 | 0.18 | 4.57x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 12.20 | 21.50 | 0.17 | 12.00x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Morphology (dilate, r=5) | scalar | 512x512 | 146.40 | 1.79 | 0.01 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Morphology (dilate, r=5) | sse2 | 512x512 | 5.85 | 44.84 | 0.36 | **25.04x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Morphology (dilate, r=5) | avx2 | 512x512 | 5.30 | 49.42 | 0.40 | **27.60x** | 🚀 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 215.65 | 19.45 | 0.16 | 11.15x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 2405.21 | 1.74 | 0.01 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 40.08 | 104.65 | 0.84 | **60.01x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 2048x2048 | 36.56 | 114.74 | 0.92 | **65.80x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 4.76 | 55.05 | 0.44 | 3.30x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=1) | scalar | 512x512 | 15.71 | 16.68 | 0.13 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=1) | sse2 | 512x512 | 1.18 | 222.09 | 1.78 | **13.31x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=1) | avx2 | 512x512 | 1.11 | 235.94 | 1.89 | **14.14x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 72.12 | 58.15 | 0.47 | 3.17x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 228.37 | 18.37 | 0.15 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 11.80 | 355.36 | 2.84 | **19.35x** | 🚀 |  |
| Morphology (erode, r=1) | avx2 | 2048x2048 | 13.52 | 310.30 | 2.48 | **16.90x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=5) | kotlin | 512x512 | 11.49 | 22.82 | 0.18 | 14.06x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=5) | scalar | 512x512 | 161.49 | 1.62 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 0.98 | 267.82 | 2.14 | **164.99x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 512x512 | 0.91 | 287.17 | 2.30 | **176.92x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 202.44 | 20.72 | 0.17 | 13.52x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=5) | scalar | 2048x2048 | 2737.21 | 1.53 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 16.97 | 247.10 | 1.98 | **161.26x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 2048x2048 | 18.05 | 232.33 | 1.86 | **151.62x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 103.20 | 2.54 | 0.01 | 0.43x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 43.90 | 5.97 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 11.68 | 22.44 | 0.09 | 3.76x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 512x512 | 7.96 | 32.93 | 0.13 | 5.51x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 1612.20 | 2.60 | 0.01 | 0.43x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 689.58 | 6.08 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 187.65 | 22.35 | 0.09 | 3.67x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 2048x2048 | 127.35 | 32.93 | 0.13 | 5.41x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.43 | 608.57 | 4.87 | 1.90x | ⬆️ |  |
| UnLinearize | scalar | 512x512 | 0.82 | 320.93 | 2.57 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.27 | 985.60 | 7.88 | 3.07x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.29 | 917.44 | 7.34 | 2.86x | 🟢 |  |
| UnLinearize | kotlin | 2048x2048 | 7.40 | 566.55 | 4.53 | 1.84x | ⬆️ |  |
| UnLinearize | scalar | 2048x2048 | 13.61 | 308.18 | 2.47 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.55 | 922.39 | 7.38 | 2.99x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 5.19 | 808.71 | 6.47 | 2.62x | 🟢 |  |

## Host Results (x86-32, Android emulator)

x86 emulator (API 30). Missing backend = not advertised on this ABI.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 17.23 | 15.22 | 0.18 | 1.41x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 24.29 | 10.79 | 0.13 | 1.00x |  |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 264.55 | 15.85 | 0.19 | 1.38x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 364.77 | 11.50 | 0.14 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 16.96 | 15.45 | 0.19 | 1.62x | ⬆️ |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 27.54 | 9.52 | 0.11 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 265.14 | 15.82 | 0.19 | 1.60x | ⬆️ |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 424.12 | 9.89 | 0.12 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ColorMatrix (linear) | kotlin | 512x512 | 13.82 | 18.96 | 0.23 | 1.20x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ColorMatrix (linear) | scalar | 512x512 | 16.63 | 15.76 | 0.19 | 1.00x |  |  |
| ColorMatrix (linear) | ssse3 | 512x512 | 2.70 | 97.20 | 1.17 | 6.17x | 🟢 |  |
| ColorMatrix (linear) | kotlin | 2048x2048 | 198.51 | 21.13 | 0.25 | 1.42x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ColorMatrix (linear) | scalar | 2048x2048 | 281.27 | 14.91 | 0.18 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| ColorMatrix (linear) | ssse3 | 2048x2048 | 48.10 | 87.19 | 1.05 | 5.85x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 512x512 | 13.87 | 18.90 | 0.23 | 1.28x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ColorMatrix (non-linear) | scalar | 512x512 | 17.77 | 14.75 | 0.18 | 1.00x |  |  |
| ColorMatrix (non-linear) | ssse3 | 512x512 | 1.18 | 221.85 | 2.66 | **15.04x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ColorMatrix (non-linear) | kotlin | 2048x2048 | 261.83 | 16.02 | 0.19 | 0.96x |  | ⚠️ UNSTABLE BENCH |
| ColorMatrix (non-linear) | scalar | 2048x2048 | 252.06 | 16.64 | 0.20 | 1.00x |  |  |
| ColorMatrix (non-linear) | ssse3 | 2048x2048 | 26.09 | 160.76 | 1.93 | **9.66x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ComponentTransfer | kotlin | 512x512 | 1.18 | 221.74 | 1.77 | 0.87x |  | ⚠️ UNSTABLE BENCH |
| ComponentTransfer | scalar | 512x512 | 1.03 | 255.35 | 2.04 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 20.01 | 209.57 | 1.68 | 0.85x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 17.07 | 245.73 | 1.97 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 512x512 | 40.69 | 6.44 | 0.05 | 2.80x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 512x512 | 113.89 | 2.30 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 512x512 | 5.37 | 48.84 | 0.39 | **21.22x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, alpha) | avx2 | 512x512 | 4.26 | 61.57 | 0.49 | **26.75x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | kotlin | 2048x2048 | 585.45 | 7.16 | 0.06 | 2.87x | ⬆️ |  |
| ConvolveMatrix (duplicate, alpha) | scalar | 2048x2048 | 1680.52 | 2.50 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, alpha) | sse2 | 2048x2048 | 64.65 | 64.88 | 0.52 | **25.99x** | 🚀 |  |
| ConvolveMatrix (duplicate, alpha) | avx2 | 2048x2048 | 35.34 | 118.70 | 0.95 | **47.56x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 512x512 | 42.75 | 6.13 | 0.05 | 2.61x | ⬆️ | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 512x512 | 111.38 | 2.35 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 512x512 | 6.06 | 43.29 | 0.35 | **18.39x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 512x512 | 4.40 | 59.56 | 0.48 | **25.31x** | 🚀 | ⚠️ UNSTABLE BENCH |
| ConvolveMatrix (duplicate, no-alpha) | kotlin | 2048x2048 | 655.31 | 6.40 | 0.05 | 2.69x | ⬆️ |  |
| ConvolveMatrix (duplicate, no-alpha) | scalar | 2048x2048 | 1763.60 | 2.38 | 0.02 | 1.00x |  |  |
| ConvolveMatrix (duplicate, no-alpha) | sse2 | 2048x2048 | 82.51 | 50.84 | 0.41 | **21.38x** | 🚀 |  |
| ConvolveMatrix (duplicate, no-alpha) | avx2 | 2048x2048 | 39.61 | 105.89 | 0.85 | **44.52x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 5.60 | 46.80 | 0.56 | 1.42x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 7.95 | 32.99 | 0.40 | 1.00x |  |  |
| DisplacementMap | ssse3 | 512x512 | 0.46 | 565.89 | 6.79 | **17.15x** | 🚀 | ⚠️ UNSTABLE BENCH |
| DisplacementMap | avx2 | 512x512 | 0.31 | 847.32 | 10.17 | **25.68x** | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 90.83 | 46.18 | 0.55 | 1.42x | ⬆️ | ⚠️ UNSTABLE BENCH |
| DisplacementMap | scalar | 2048x2048 | 129.07 | 32.50 | 0.39 | 1.00x |  |  |
| DisplacementMap | ssse3 | 2048x2048 | 8.29 | 506.16 | 6.07 | **15.58x** | 🚀 |  |
| DisplacementMap | avx2 | 2048x2048 | 5.64 | 744.33 | 8.93 | **22.91x** | 🚀 |  |
| FeBlend (hue, linear) | kotlin | 512x512 | 52.23 | 5.02 | 0.06 | 1.62x | ⬆️ |  |
| FeBlend (hue, linear) | scalar | 512x512 | 84.62 | 3.10 | 0.04 | 1.00x |  |  |
| FeBlend (hue, linear) | ssse3 | 512x512 | 82.36 | 3.18 | 0.04 | 1.03x | 🟢 |  |
| FeBlend (hue, linear) | kotlin | 2048x2048 | 781.75 | 5.37 | 0.06 | 1.67x | ⬆️ |  |
| FeBlend (hue, linear) | scalar | 2048x2048 | 1307.77 | 3.21 | 0.04 | 1.00x |  |  |
| FeBlend (hue, linear) | ssse3 | 2048x2048 | 1314.05 | 3.19 | 0.04 | 1.00x | 🔴 |  |
| FeBlend (multiply, linear) | kotlin | 512x512 | 17.84 | 14.69 | 0.18 | 1.20x | ⬆️ | ⚠️ UNSTABLE BENCH |
| FeBlend (multiply, linear) | scalar | 512x512 | 21.34 | 12.29 | 0.15 | 1.00x |  |  |
| FeBlend (multiply, linear) | ssse3 | 512x512 | 4.05 | 64.66 | 0.78 | 5.26x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 2048x2048 | 271.43 | 15.45 | 0.19 | 1.26x | ⬆️ |  |
| FeBlend (multiply, linear) | scalar | 2048x2048 | 341.79 | 12.27 | 0.15 | 1.00x |  |  |
| FeBlend (multiply, linear) | ssse3 | 2048x2048 | 65.87 | 63.68 | 0.76 | 5.19x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 512x512 | 16.42 | 15.96 | 0.19 | 1.26x | ⬆️ |  |
| FeBlend (multiply, non-linear) | scalar | 512x512 | 20.73 | 12.64 | 0.15 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | ssse3 | 512x512 | 2.67 | 98.34 | 1.18 | 7.78x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 2048x2048 | 263.75 | 15.90 | 0.19 | 1.15x | ⬆️ |  |
| FeBlend (multiply, non-linear) | scalar | 2048x2048 | 304.47 | 13.78 | 0.17 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | ssse3 | 2048x2048 | 42.57 | 98.53 | 1.18 | 7.15x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 19.57 | 13.39 | 0.11 | 16.52x | ⬆️ |  |
| GaussianBlur | scalar | 512x512 | 323.38 | 0.81 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 12.94 | 20.27 | 0.16 | **25.00x** | 🚀 |  |
| GaussianBlur | avx2 | 512x512 | 10.14 | 25.84 | 0.21 | **31.88x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 472.77 | 8.87 | 0.07 | 11.51x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 5443.81 | 0.77 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 187.66 | 22.35 | 0.18 | **29.01x** | 🚀 |  |
| GaussianBlur | avx2 | 2048x2048 | 141.35 | 29.67 | 0.24 | **38.51x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 16.24 | 16.14 | 0.13 | 1.30x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 21.08 | 12.43 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 6.45 | 40.62 | 0.32 | 3.27x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.64 | 160.05 | 1.28 | **12.87x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 257.29 | 16.30 | 0.13 | 1.34x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 343.97 | 12.19 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 100.25 | 41.84 | 0.33 | 3.43x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 14.09 | 297.70 | 2.38 | **24.41x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 16.40 | 15.99 | 0.13 | 3.19x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 52.23 | 5.02 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 6.86 | 38.20 | 0.31 | 7.61x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 3.56 | 73.61 | 0.59 | **14.66x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 251.73 | 16.66 | 0.13 | 3.11x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 782.31 | 5.36 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 103.88 | 40.38 | 0.32 | 7.53x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 45.28 | 92.64 | 0.74 | **17.28x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 18.24 | 14.37 | 0.11 | 3.06x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 55.91 | 4.69 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 7.62 | 34.40 | 0.28 | 7.34x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 512x512 | 1.99 | 131.68 | 1.05 | **28.08x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 287.91 | 14.57 | 0.12 | 3.06x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 880.30 | 4.76 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 120.23 | 34.89 | 0.28 | 7.32x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 18.77 | 223.40 | 1.79 | **46.89x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 18.01 | 14.55 | 0.12 | 3.23x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 58.09 | 4.51 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 8.15 | 32.16 | 0.26 | 7.13x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.86 | 91.68 | 0.73 | **20.32x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 287.03 | 14.61 | 0.12 | 3.15x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 905.20 | 4.63 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 119.98 | 34.96 | 0.28 | 7.54x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 31.12 | 134.76 | 1.08 | **29.08x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 22.38 | 11.71 | 0.09 | 2.68x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 59.96 | 4.37 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 8.13 | 32.26 | 0.26 | 7.38x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 512x512 | 8.29 | 31.62 | 0.25 | 7.23x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 368.66 | 11.38 | 0.09 | 2.56x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 942.37 | 4.45 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 122.82 | 34.15 | 0.27 | 7.67x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 126.46 | 33.17 | 0.27 | 7.45x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 21.96 | 11.94 | 0.10 | 2.84x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 62.37 | 4.20 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 8.63 | 30.37 | 0.24 | 7.23x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 9.51 | 27.55 | 0.22 | 6.56x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 346.74 | 12.10 | 0.10 | 2.71x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 939.99 | 4.46 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 127.09 | 33.00 | 0.26 | 7.40x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 128.51 | 32.64 | 0.26 | 7.31x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 27.19 | 9.64 | 0.08 | 2.11x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 57.36 | 4.57 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 17.28 | 15.17 | 0.12 | 3.32x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 13.07 | 20.05 | 0.16 | 4.39x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 422.34 | 9.93 | 0.08 | 2.14x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 903.01 | 4.64 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 280.22 | 14.97 | 0.12 | 3.22x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 200.87 | 20.88 | 0.17 | 4.50x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 27.62 | 9.49 | 0.08 | 2.20x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 60.89 | 4.30 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 19.08 | 13.74 | 0.11 | 3.19x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 14.65 | 17.89 | 0.14 | 4.16x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 429.34 | 9.77 | 0.08 | 2.22x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 951.94 | 4.41 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 276.93 | 15.15 | 0.12 | 3.44x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 221.18 | 18.96 | 0.15 | 4.30x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 33.60 | 7.80 | 0.06 | 1.96x | ⬆️ |  |
| Lighting (specular, point) | scalar | 512x512 | 65.69 | 3.99 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 23.56 | 11.13 | 0.09 | 2.79x | 🟢 |  |
| Lighting (specular, point) | avx2 | 512x512 | 21.56 | 12.16 | 0.10 | 3.05x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 520.89 | 8.05 | 0.06 | 1.99x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1035.84 | 4.05 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 363.41 | 11.54 | 0.09 | 2.85x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 324.86 | 12.91 | 0.10 | 3.19x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 32.30 | 8.12 | 0.06 | 2.11x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 68.08 | 3.85 | 0.03 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 23.39 | 11.21 | 0.09 | 2.91x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 22.59 | 11.60 | 0.09 | 3.01x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 519.62 | 8.07 | 0.06 | 1.99x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1033.02 | 4.06 | 0.03 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 410.51 | 10.22 | 0.08 | 2.52x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 353.59 | 11.86 | 0.09 | 2.92x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | kotlin | 512x512 | 33.89 | 7.74 | 0.06 | 2.12x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 71.69 | 3.66 | 0.03 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | ssse3 | 512x512 | 21.67 | 12.10 | 0.10 | 3.31x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 512x512 | 27.52 | 9.52 | 0.08 | 2.60x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 571.03 | 7.35 | 0.06 | 1.91x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1087.95 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 336.95 | 12.45 | 0.10 | 3.23x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 432.17 | 9.71 | 0.08 | 2.52x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 37.70 | 6.95 | 0.06 | 2.49x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | scalar | 512x512 | 94.03 | 2.79 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 29.69 | 8.83 | 0.07 | 3.17x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 32.41 | 8.09 | 0.06 | 2.90x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 531.33 | 7.89 | 0.06 | 2.05x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1090.13 | 3.85 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 355.20 | 11.81 | 0.09 | 3.07x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 414.39 | 10.12 | 0.08 | 2.63x | 🟢 |  |
| Morphology (dilate, r=5) | kotlin | 512x512 | 18.08 | 14.50 | 0.12 | 8.05x | ⬆️ |  |
| Morphology (dilate, r=5) | scalar | 512x512 | 145.50 | 1.80 | 0.01 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 512x512 | 6.15 | 42.65 | 0.34 | **23.67x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 512x512 | 5.85 | 44.79 | 0.36 | **24.86x** | 🚀 |  |
| Morphology (dilate, r=5) | kotlin | 2048x2048 | 319.83 | 13.11 | 0.10 | 7.23x | ⬆️ |  |
| Morphology (dilate, r=5) | scalar | 2048x2048 | 2312.36 | 1.81 | 0.01 | 1.00x |  |  |
| Morphology (dilate, r=5) | sse2 | 2048x2048 | 46.44 | 90.31 | 0.72 | **49.79x** | 🚀 |  |
| Morphology (dilate, r=5) | avx2 | 2048x2048 | 40.59 | 103.35 | 0.83 | **56.98x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 512x512 | 9.94 | 26.36 | 0.21 | 1.56x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 512x512 | 15.55 | 16.86 | 0.13 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Morphology (erode, r=1) | sse2 | 512x512 | 0.99 | 264.50 | 2.12 | **15.69x** | 🚀 |  |
| Morphology (erode, r=1) | avx2 | 512x512 | 1.00 | 262.40 | 2.10 | **15.56x** | 🚀 |  |
| Morphology (erode, r=1) | kotlin | 2048x2048 | 158.51 | 26.46 | 0.21 | 1.53x | ⬆️ |  |
| Morphology (erode, r=1) | scalar | 2048x2048 | 243.22 | 17.25 | 0.14 | 1.00x |  |  |
| Morphology (erode, r=1) | sse2 | 2048x2048 | 17.04 | 246.09 | 1.97 | **14.27x** | 🚀 |  |
| Morphology (erode, r=1) | avx2 | 2048x2048 | 17.48 | 239.98 | 1.92 | **13.92x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 512x512 | 20.85 | 12.57 | 0.10 | 7.86x | ⬆️ |  |
| Morphology (erode, r=5) | scalar | 512x512 | 163.94 | 1.60 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 512x512 | 1.32 | 197.94 | 1.58 | **123.79x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 512x512 | 1.20 | 218.34 | 1.75 | **136.55x** | 🚀 |  |
| Morphology (erode, r=5) | kotlin | 2048x2048 | 325.40 | 12.89 | 0.10 | 8.01x | ⬆️ |  |
| Morphology (erode, r=5) | scalar | 2048x2048 | 2606.05 | 1.61 | 0.01 | 1.00x |  |  |
| Morphology (erode, r=5) | sse2 | 2048x2048 | 22.50 | 186.38 | 1.49 | **115.80x** | 🚀 |  |
| Morphology (erode, r=5) | avx2 | 2048x2048 | 20.26 | 207.00 | 1.66 | **128.61x** | 🚀 |  |
| Turbulence (turbulence, 1 oct) | kotlin | 512x512 | 121.77 | 2.15 | 0.01 | 0.52x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 512x512 | 63.10 | 4.15 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 512x512 | 14.63 | 17.92 | 0.07 | 4.31x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 512x512 | 10.35 | 25.33 | 0.10 | 6.10x | 🟢 | ⚠️ UNSTABLE BENCH |
| Turbulence (turbulence, 1 oct) | kotlin | 2048x2048 | 1754.83 | 2.39 | 0.01 | 0.56x |  |  |
| Turbulence (turbulence, 1 oct) | scalar | 2048x2048 | 974.72 | 4.30 | 0.02 | 1.00x |  |  |
| Turbulence (turbulence, 1 oct) | ssse3 | 2048x2048 | 226.82 | 18.49 | 0.07 | 4.30x | 🟢 |  |
| Turbulence (turbulence, 1 oct) | avx2 | 2048x2048 | 118.54 | 35.38 | 0.14 | 8.22x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.90 | 290.78 | 2.33 | 0.99x |  |  |
| UnLinearize | scalar | 512x512 | 0.90 | 292.70 | 2.34 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.26 | 994.65 | 7.96 | 3.40x | 🟢 | ⚠️ UNSTABLE BENCH |
| UnLinearize | avx2 | 512x512 | 0.15 | 1732.79 | 13.86 | 5.92x | 🟢 | ⚠️ UNSTABLE BENCH |
| UnLinearize | kotlin | 2048x2048 | 15.52 | 270.22 | 2.16 | 0.92x |  |  |
| UnLinearize | scalar | 2048x2048 | 14.35 | 292.19 | 2.34 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.22 | 994.79 | 7.96 | 3.40x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 2.39 | 1755.56 | 14.04 | 6.01x | 🟢 |  |

## Device Results (OnePlus 11)

OnePlus 11 (Snapdragon 8 Gen 2), `arm64-v8a`.

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
| ColorMatrix (linear) | kotlin | 512x512 | 36.090 | 7.26 | 0.09 | 0.31x |  |  |
| ColorMatrix (linear) | scalar | 512x512 | 11.020 | 23.78 | 0.29 | 1.00x |  |  |
| ColorMatrix (linear) | neon64 | 512x512 | 1.660 | 157.72 | 1.89 | 6.63x | 🟢 |  |
| ColorMatrix (linear) | kotlin | 2048x2048 | 578.260 | 7.25 | 0.09 | 0.30x |  |  |
| ColorMatrix (linear) | scalar | 2048x2048 | 175.400 | 23.91 | 0.29 | 1.00x |  |  |
| ColorMatrix (linear) | neon64 | 2048x2048 | 27.010 | 155.31 | 1.86 | 6.50x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 512x512 | 36.360 | 7.21 | 0.09 | 0.29x |  |  |
| ColorMatrix (non-linear) | scalar | 512x512 | 10.490 | 25.00 | 0.30 | 1.00x |  |  |
| ColorMatrix (non-linear) | neon64 | 512x512 | 0.970 | 271.39 | 3.26 | **10.86x** | 🚀 |  |
| ColorMatrix (non-linear) | kotlin | 2048x2048 | 587.000 | 7.15 | 0.09 | 0.29x |  |  |
| ColorMatrix (non-linear) | scalar | 2048x2048 | 168.460 | 24.90 | 0.30 | 1.00x |  |  |
| ColorMatrix (non-linear) | neon64 | 2048x2048 | 15.680 | 267.52 | 3.21 | **10.74x** | 🚀 |  |
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
| FeBlend (hue, linear) | kotlin | 512x512 | 248.870 | 1.05 | 0.01 | 0.47x |  |  |
| FeBlend (hue, linear) | scalar | 512x512 | 117.560 | 2.23 | 0.03 | 1.00x |  |  |
| FeBlend (hue, linear) | neon64 | 512x512 | 117.530 | 2.23 | 0.03 | 1.00x | 🟢 |  |
| FeBlend (hue, linear) | kotlin | 2048x2048 | 3963.300 | 1.06 | 0.01 | 0.47x |  |  |
| FeBlend (hue, linear) | scalar | 2048x2048 | 1878.900 | 2.23 | 0.03 | 1.00x |  |  |
| FeBlend (hue, linear) | neon64 | 2048x2048 | 1878.250 | 2.23 | 0.03 | 1.00x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 512x512 | 38.490 | 6.81 | 0.08 | 0.38x |  |  |
| FeBlend (multiply, linear) | scalar | 512x512 | 14.510 | 18.06 | 0.22 | 1.00x |  |  |
| FeBlend (multiply, linear) | neon64 | 512x512 | 3.680 | 71.33 | 0.86 | 3.95x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 2048x2048 | 625.220 | 6.71 | 0.08 | 0.37x |  |  |
| FeBlend (multiply, linear) | scalar | 2048x2048 | 233.810 | 17.94 | 0.22 | 1.00x |  |  |
| FeBlend (multiply, linear) | neon64 | 2048x2048 | 59.440 | 70.56 | 0.85 | 3.93x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 512x512 | 38.100 | 6.88 | 0.08 | 0.37x |  |  |
| FeBlend (multiply, non-linear) | scalar | 512x512 | 14.170 | 18.50 | 0.22 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | neon64 | 512x512 | 2.410 | 108.86 | 1.31 | 5.88x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 2048x2048 | 619.140 | 6.77 | 0.08 | 0.37x |  |  |
| FeBlend (multiply, non-linear) | scalar | 2048x2048 | 227.870 | 18.41 | 0.22 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | neon64 | 2048x2048 | 39.030 | 107.47 | 1.29 | 5.84x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 12.397 | 21.15 | 0.17 | **23.52x** | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 291.558 | 0.90 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon64 | 512x512 | 5.228 | 50.14 | 0.40 | **55.77x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 196.646 | 21.33 | 0.17 | **24.09x** | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 2048x2048 | 4736.735 | 0.89 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon64 | 2048x2048 | 83.793 | 50.06 | 0.40 | **56.53x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 44.790 | 5.85 | 0.05 | 0.46x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 20.740 | 12.64 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 512x512 | 1.880 | 139.36 | 1.11 | **11.03x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 725.060 | 5.78 | 0.05 | 0.45x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 326.750 | 12.84 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 2048x2048 | 22.290 | 188.15 | 1.51 | **14.66x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 44.130 | 5.94 | 0.05 | 1.43x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 63.290 | 4.14 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon64 | 512x512 | 2.530 | 103.75 | 0.83 | **25.05x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 718.200 | 5.84 | 0.05 | 1.38x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 992.400 | 4.23 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon64 | 2048x2048 | 32.430 | 129.34 | 1.03 | **30.60x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 57.890 | 4.53 | 0.04 | 1.24x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 72.000 | 3.64 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point) | neon64 | 512x512 | 2.260 | 116.08 | 0.93 | **31.88x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 932.780 | 4.50 | 0.04 | 1.21x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1132.370 | 3.70 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point) | neon64 | 2048x2048 | 30.870 | 135.85 | 1.09 | **36.68x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 57.920 | 4.53 | 0.04 | 1.26x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 72.990 | 3.59 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon64 | 512x512 | 2.850 | 92.07 | 0.74 | **25.64x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 936.970 | 4.48 | 0.04 | 1.23x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1150.290 | 3.65 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon64 | 2048x2048 | 33.730 | 124.33 | 0.99 | **34.10x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 59.890 | 4.38 | 0.04 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 78.200 | 3.35 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon64 | 512x512 | 2.600 | 100.93 | 0.81 | **30.11x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 965.580 | 4.34 | 0.03 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 1268.000 | 3.31 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon64 | 2048x2048 | 33.480 | 125.28 | 1.00 | **37.88x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 59.940 | 4.37 | 0.03 | 1.32x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 78.990 | 3.32 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon64 | 512x512 | 3.100 | 84.69 | 0.68 | **25.52x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 970.990 | 4.32 | 0.03 | 1.32x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1279.370 | 3.28 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon64 | 2048x2048 | 37.440 | 112.02 | 0.90 | **34.17x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 75.980 | 3.45 | 0.03 | 1.03x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 78.070 | 3.36 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 512x512 | 3.760 | 69.70 | 0.56 | **20.76x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 1222.400 | 3.43 | 0.03 | 1.00x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1223.200 | 3.43 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 2048x2048 | 49.540 | 84.67 | 0.68 | **24.69x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 76.740 | 3.42 | 0.03 | 1.03x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 79.000 | 3.32 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon64 | 512x512 | 4.440 | 59.03 | 0.47 | **17.79x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 1236.640 | 3.39 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1234.090 | 3.40 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon64 | 2048x2048 | 58.820 | 71.31 | 0.57 | **20.98x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 512x512 | 90.070 | 2.91 | 0.02 | 0.96x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 86.420 | 3.03 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon64 | 512x512 | 4.630 | 56.64 | 0.45 | **18.67x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 1445.310 | 2.90 | 0.02 | 1.11x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1597.230 | 2.63 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon64 | 2048x2048 | 72.410 | 57.93 | 0.46 | **22.06x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 107.520 | 2.44 | 0.02 | 0.96x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 102.920 | 2.55 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon64 | 512x512 | 5.960 | 43.97 | 0.35 | **17.27x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 1723.020 | 2.43 | 0.02 | 0.93x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1610.600 | 2.60 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon64 | 2048x2048 | 80.550 | 52.07 | 0.42 | **20.00x** | 🚀 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 109.640 | 2.39 | 0.02 | 1.00x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 109.660 | 2.39 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon64 | 512x512 | 5.730 | 45.74 | 0.37 | **19.13x** | 🚀 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 1756.010 | 2.39 | 0.02 | 1.01x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1766.600 | 2.37 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon64 | 2048x2048 | 76.710 | 54.68 | 0.44 | **23.03x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 110.050 | 2.38 | 0.02 | 1.00x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 110.530 | 2.37 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon64 | 512x512 | 6.210 | 42.22 | 0.34 | **17.80x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 1761.840 | 2.38 | 0.02 | 1.01x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1776.420 | 2.36 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon64 | 2048x2048 | 82.870 | 50.61 | 0.40 | **21.44x** | 🚀 |  |
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

OnePlus 11 (Snapdragon 8 Gen 2), `armeabi-v7a`.

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
| ColorMatrix (linear) | kotlin | 512x512 | 63.760 | 4.11 | 0.05 | 0.34x |  |  |
| ColorMatrix (linear) | scalar | 512x512 | 21.810 | 12.02 | 0.14 | 1.00x |  |  |
| ColorMatrix (linear) | neon32 | 512x512 | 15.230 | 17.21 | 0.21 | 1.43x | 🟢 |  |
| ColorMatrix (linear) | kotlin | 2048x2048 | 1018.160 | 4.12 | 0.05 | 0.34x |  |  |
| ColorMatrix (linear) | scalar | 2048x2048 | 347.150 | 12.08 | 0.14 | 1.00x |  |  |
| ColorMatrix (linear) | neon32 | 2048x2048 | 243.740 | 17.21 | 0.21 | 1.42x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 512x512 | 63.000 | 4.16 | 0.05 | 0.32x |  |  |
| ColorMatrix (non-linear) | scalar | 512x512 | 20.190 | 12.98 | 0.16 | 1.00x |  |  |
| ColorMatrix (non-linear) | neon32 | 512x512 | 3.300 | 79.36 | 0.95 | 6.11x | 🟢 |  |
| ColorMatrix (non-linear) | kotlin | 2048x2048 | 1011.230 | 4.15 | 0.05 | 0.32x |  |  |
| ColorMatrix (non-linear) | scalar | 2048x2048 | 322.830 | 12.99 | 0.16 | 1.00x |  |  |
| ColorMatrix (non-linear) | neon32 | 2048x2048 | 53.240 | 78.79 | 0.95 | 6.06x | 🟢 |  |
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
| FeBlend (hue, linear) | kotlin | 512x512 | 508.710 | 0.52 | 0.01 | 0.28x |  |  |
| FeBlend (hue, linear) | scalar | 512x512 | 144.660 | 1.81 | 0.02 | 1.00x |  |  |
| FeBlend (hue, linear) | neon32 | 512x512 | 144.660 | 1.81 | 0.02 | 1.00x | 🟢 |  |
| FeBlend (hue, linear) | kotlin | 2048x2048 | 8137.990 | 0.52 | 0.01 | 0.27x |  |  |
| FeBlend (hue, linear) | scalar | 2048x2048 | 2191.460 | 1.91 | 0.02 | 1.00x |  |  |
| FeBlend (hue, linear) | neon32 | 2048x2048 | 2190.640 | 1.91 | 0.02 | 1.00x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 512x512 | 78.040 | 3.36 | 0.04 | 0.35x |  |  |
| FeBlend (multiply, linear) | scalar | 512x512 | 27.370 | 9.58 | 0.11 | 1.00x |  |  |
| FeBlend (multiply, linear) | neon32 | 512x512 | 17.600 | 14.89 | 0.18 | 1.55x | 🟢 |  |
| FeBlend (multiply, linear) | kotlin | 2048x2048 | 1250.210 | 3.35 | 0.04 | 0.35x |  |  |
| FeBlend (multiply, linear) | scalar | 2048x2048 | 438.770 | 9.56 | 0.11 | 1.00x |  |  |
| FeBlend (multiply, linear) | neon32 | 2048x2048 | 279.880 | 14.99 | 0.18 | 1.57x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 512x512 | 77.850 | 3.37 | 0.04 | 0.34x |  |  |
| FeBlend (multiply, non-linear) | scalar | 512x512 | 26.360 | 9.94 | 0.12 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | neon32 | 512x512 | 5.260 | 49.81 | 0.60 | 5.01x | 🟢 |  |
| FeBlend (multiply, non-linear) | kotlin | 2048x2048 | 1245.460 | 3.37 | 0.04 | 0.34x |  |  |
| FeBlend (multiply, non-linear) | scalar | 2048x2048 | 420.260 | 9.98 | 0.12 | 1.00x |  |  |
| FeBlend (multiply, non-linear) | neon32 | 2048x2048 | 84.420 | 49.68 | 0.60 | 4.98x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 27.400 | 9.57 | 0.08 | 13.63x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 373.322 | 0.70 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 512x512 | 8.751 | 29.96 | 0.24 | **42.66x** | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 501.422 | 8.36 | 0.07 | 12.00x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 2048x2048 | 6018.733 | 0.70 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 2048x2048 | 138.898 | 30.20 | 0.24 | **43.33x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 512x512 | 100.260 | 2.61 | 0.02 | 0.30x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 30.420 | 8.62 | 0.07 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon32 | 512x512 | 4.780 | 54.87 | 0.44 | 6.37x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 1568.540 | 2.67 | 0.02 | 0.28x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 441.210 | 9.51 | 0.08 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon32 | 2048x2048 | 50.380 | 83.26 | 0.67 | 8.76x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 102.400 | 2.56 | 0.02 | 0.88x |  |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 89.860 | 2.92 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon32 | 512x512 | 5.120 | 51.21 | 0.41 | **17.55x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 1601.700 | 2.62 | 0.02 | 0.80x |  |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 1276.990 | 3.28 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon32 | 2048x2048 | 57.140 | 73.40 | 0.59 | **22.35x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 145.460 | 1.80 | 0.01 | 0.67x |  |  |
| Lighting (diffuse, point) | scalar | 512x512 | 97.230 | 2.70 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point) | neon32 | 512x512 | 5.600 | 46.81 | 0.37 | **17.36x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 2250.570 | 1.86 | 0.01 | 0.63x |  |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1407.360 | 2.98 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point) | neon32 | 2048x2048 | 69.240 | 60.58 | 0.48 | **20.33x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 146.350 | 1.79 | 0.01 | 0.69x |  |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 100.720 | 2.60 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon32 | 512x512 | 6.230 | 42.08 | 0.34 | **16.17x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 2263.220 | 1.85 | 0.01 | 0.64x |  |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1454.750 | 2.88 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon32 | 2048x2048 | 78.860 | 53.19 | 0.43 | **18.45x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 149.990 | 1.75 | 0.01 | 0.72x |  |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 107.360 | 2.44 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon32 | 512x512 | 6.290 | 41.66 | 0.33 | **17.06x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 2323.950 | 1.80 | 0.01 | 0.66x |  |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 1536.280 | 2.73 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon32 | 2048x2048 | 79.510 | 52.75 | 0.42 | **19.32x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 151.340 | 1.73 | 0.01 | 0.73x |  |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 110.860 | 2.36 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon32 | 512x512 | 6.830 | 38.40 | 0.31 | **16.24x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 2328.320 | 1.80 | 0.01 | 0.68x |  |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1583.380 | 2.65 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon32 | 2048x2048 | 89.600 | 46.81 | 0.37 | **17.67x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 182.810 | 1.43 | 0.01 | 0.55x |  |  |
| Lighting (specular, distant) | scalar | 512x512 | 99.770 | 2.63 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon32 | 512x512 | 12.970 | 20.22 | 0.16 | 7.69x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 2935.460 | 1.43 | 0.01 | 0.51x |  |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1495.330 | 2.80 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon32 | 2048x2048 | 181.360 | 23.13 | 0.19 | 8.25x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 184.230 | 1.42 | 0.01 | 0.57x |  |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 104.450 | 2.51 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon32 | 512x512 | 15.070 | 17.39 | 0.14 | 6.93x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 2988.380 | 1.40 | 0.01 | 0.52x |  |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1560.420 | 2.69 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon32 | 2048x2048 | 211.940 | 19.79 | 0.16 | 7.36x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 222.780 | 1.18 | 0.01 | 0.51x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 112.530 | 2.33 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon32 | 512x512 | 14.740 | 17.79 | 0.14 | 7.64x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 3569.480 | 1.18 | 0.01 | 0.47x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1667.420 | 2.52 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon32 | 2048x2048 | 217.730 | 19.26 | 0.15 | 7.66x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 225.300 | 1.16 | 0.01 | 0.51x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 115.810 | 2.26 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon32 | 512x512 | 16.430 | 15.95 | 0.13 | 7.05x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 3599.090 | 1.17 | 0.01 | 0.48x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1734.840 | 2.42 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon32 | 2048x2048 | 242.800 | 17.27 | 0.14 | 7.15x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 227.300 | 1.15 | 0.01 | 0.54x |  |  |
| Lighting (specular, spot) | scalar | 512x512 | 122.140 | 2.15 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon32 | 512x512 | 15.060 | 17.41 | 0.14 | 8.11x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 3652.950 | 1.15 | 0.01 | 0.50x |  |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1811.120 | 2.32 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon32 | 2048x2048 | 223.690 | 18.75 | 0.15 | 8.10x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 231.240 | 1.13 | 0.01 | 0.54x |  |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 125.680 | 2.09 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon32 | 512x512 | 16.860 | 15.55 | 0.12 | 7.45x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 3678.560 | 1.14 | 0.01 | 0.51x |  |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1884.500 | 2.23 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon32 | 2048x2048 | 247.980 | 16.91 | 0.14 | 7.60x | 🟢 |  |
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

