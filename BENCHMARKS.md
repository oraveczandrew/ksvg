# KSVG Filter Kernel Benchmarks

Speedups relative to `scalar` (`1.00x`). Status: 🚀 >9x, 🟢 faster, 🔴 regression; Kotlin faster = ⬆️. `⚠️ UNSTABLE BENCH` = CoV >5%.
Row order per kernel: `kotlin → scalar → sse2 → ssse3 → avx2` (x86), `kotlin → scalar → neon32 → neon64` (ARM).

## Host Results (i7-7820X)

macOS 15.8, i7-7820X, 64-bit host build.

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 10.144 | 25.84 | 0.31 | 0.42x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 4.253 | 61.64 | 0.74 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.158 | 83.02 | 1.00 | 1.35x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.149 | 83.25 | 1.00 | 1.35x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 162.348 | 25.84 | 0.31 | 0.40x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 65.097 | 64.43 | 0.77 | 1.00x |  |  |
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
| Lighting (diffuse, distant) | kotlin | 512x512 | 8.175 | 32.07 | 0.26 | 0.21x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 1.745 | 150.25 | 1.20 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 1.289 | 203.32 | 1.63 | 1.35x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 0.985 | 266.23 | 2.13 | 1.77x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 131.326 | 31.94 | 0.26 | 0.23x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 30.064 | 139.51 | 1.12 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 22.519 | 186.26 | 1.49 | 1.34x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 16.710 | 251.00 | 2.01 | 1.80x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 8.352 | 31.39 | 0.25 | 1.33x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 11.115 | 23.59 | 0.19 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 2.430 | 107.88 | 0.86 | 4.57x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 2.053 | 127.71 | 1.02 | 5.41x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 133.067 | 31.52 | 0.25 | 1.33x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 176.656 | 23.74 | 0.19 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 39.005 | 107.53 | 0.86 | 4.53x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 32.992 | 127.13 | 1.02 | 5.35x | 🟢 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 9.115 | 28.76 | 0.23 | 1.29x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 11.787 | 22.24 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 2.287 | 114.63 | 0.92 | 5.15x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 512x512 | 1.441 | 181.92 | 1.46 | 8.18x | 🟢 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 149.877 | 27.98 | 0.22 | 1.26x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 189.269 | 22.16 | 0.18 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 35.990 | 116.54 | 0.93 | 5.26x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 26.042 | 161.06 | 1.29 | 7.27x | 🟢 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 9.435 | 27.79 | 0.22 | 1.33x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 12.565 | 20.86 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 3.209 | 81.68 | 0.65 | 3.92x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.095 | 125.11 | 1.00 | 6.00x | 🟢 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 147.529 | 28.43 | 0.23 | 1.34x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 198.411 | 21.14 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 52.039 | 80.60 | 0.64 | 3.81x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 35.090 | 119.53 | 0.96 | 5.65x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 24.145 | 10.86 | 0.09 | 0.54x |  |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 13.051 | 20.09 | 0.16 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 2.966 | 88.38 | 0.71 | 4.40x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 512x512 | 1.975 | 132.71 | 1.06 | 6.61x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 148.211 | 28.30 | 0.23 | 1.58x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 234.720 | 17.87 | 0.14 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 38.439 | 109.12 | 0.87 | 6.11x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 25.544 | 164.20 | 1.31 | **9.19x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 8.840 | 29.65 | 0.24 | 1.40x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 12.334 | 21.25 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 2.969 | 88.29 | 0.71 | 4.15x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 2.183 | 120.09 | 0.96 | 5.65x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 139.530 | 30.06 | 0.24 | 1.40x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 194.983 | 21.51 | 0.17 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 49.253 | 85.16 | 0.68 | 3.96x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 34.772 | 120.62 | 0.96 | 5.61x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 17.464 | 15.01 | 0.12 | 1.09x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 19.113 | 13.72 | 0.11 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 4.778 | 54.86 | 0.44 | 4.00x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 2.352 | 111.48 | 0.89 | 8.13x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 255.331 | 16.43 | 0.13 | 1.24x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 315.752 | 13.28 | 0.11 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 72.726 | 57.67 | 0.46 | 4.34x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 33.034 | 126.97 | 1.02 | **9.56x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 16.576 | 15.81 | 0.13 | 1.15x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 19.088 | 13.73 | 0.11 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 6.302 | 41.60 | 0.33 | 3.03x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 3.297 | 79.51 | 0.64 | 5.79x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 258.370 | 16.23 | 0.13 | 1.30x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 336.572 | 12.46 | 0.10 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 100.468 | 41.75 | 0.33 | 3.35x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 49.584 | 84.59 | 0.68 | 6.79x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 21.278 | 12.32 | 0.10 | 0.92x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 19.613 | 13.37 | 0.11 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 6.775 | 38.69 | 0.31 | 2.79x | 🟢 |  |
| Lighting (specular, point) | avx2 | 512x512 | 3.443 | 76.15 | 0.61 | 5.70x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 316.780 | 13.24 | 0.11 | 1.02x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 322.960 | 12.99 | 0.10 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 105.284 | 39.84 | 0.32 | 2.81x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 49.955 | 83.96 | 0.67 | 6.47x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 20.004 | 13.10 | 0.10 | 0.99x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 19.903 | 13.17 | 0.11 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 7.060 | 37.13 | 0.30 | 2.72x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 4.590 | 57.12 | 0.46 | 4.34x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 321.572 | 13.04 | 0.10 | 0.98x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 316.042 | 13.27 | 0.11 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 110.725 | 37.88 | 0.30 | 2.73x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 67.827 | 61.84 | 0.49 | 4.66x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 18.757 | 13.98 | 0.11 | 1.13x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 21.244 | 12.34 | 0.10 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 7.160 | 36.61 | 0.29 | 2.72x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 512x512 | 3.443 | 76.15 | 0.61 | 6.17x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 292.741 | 14.33 | 0.11 | 1.09x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 318.698 | 13.16 | 0.11 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 109.340 | 38.36 | 0.31 | 2.80x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 46.967 | 89.30 | 0.71 | 6.79x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 18.728 | 14.00 | 0.11 | 1.11x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 20.704 | 12.66 | 0.10 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 7.578 | 34.59 | 0.28 | 2.64x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 12.199 | 21.49 | 0.17 | 1.70x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 298.916 | 14.03 | 0.11 | 1.10x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 327.969 | 12.79 | 0.10 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 113.026 | 37.11 | 0.30 | 2.85x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 187.504 | 22.37 | 0.18 | 1.75x | 🟢 |  |
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
| Lighting (diffuse, distant) | kotlin | 512x512 | 18.83 | 13.92 | 0.11 | 0.95x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 17.86 | 14.68 | 0.12 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 1.63 | 160.99 | 1.29 | **10.97x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.65 | 158.72 | 1.27 | **10.81x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 313.03 | 13.40 | 0.11 | 0.88x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 275.46 | 15.23 | 0.12 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 19.18 | 218.67 | 1.75 | **14.36x** | 🚀 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 13.37 | 313.80 | 2.51 | **20.61x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 19.66 | 13.33 | 0.11 | 2.02x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 39.77 | 6.59 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 2.77 | 94.73 | 0.76 | **14.37x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 2.52 | 104.07 | 0.83 | **15.79x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 299.12 | 14.02 | 0.11 | 2.13x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 636.72 | 6.59 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 39.13 | 107.18 | 0.86 | **16.27x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 33.40 | 125.59 | 1.00 | **19.07x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | kotlin | 512x512 | 19.64 | 13.35 | 0.11 | 2.21x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 43.47 | 6.03 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 2.48 | 105.50 | 0.84 | **17.50x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | avx2 | 512x512 | 1.95 | 134.19 | 1.07 | **22.25x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 313.34 | 13.39 | 0.11 | 2.26x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 707.02 | 5.93 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 34.11 | 122.96 | 0.98 | **20.73x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 21.78 | 192.55 | 1.54 | **32.46x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 21.22 | 12.36 | 0.10 | 2.31x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 49.06 | 5.34 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 3.78 | 69.35 | 0.55 | **12.98x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 2.92 | 89.76 | 0.72 | **16.80x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 331.42 | 12.66 | 0.10 | 2.16x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 715.71 | 5.86 | 0.05 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 53.70 | 78.11 | 0.62 | **13.33x** | 🚀 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 33.97 | 123.47 | 0.99 | **21.07x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | kotlin | 512x512 | 25.44 | 10.30 | 0.08 | 2.17x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 55.14 | 4.75 | 0.04 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 2.60 | 100.98 | 0.81 | **21.24x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | avx2 | 512x512 | 2.32 | 112.93 | 0.90 | **23.76x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 372.56 | 11.26 | 0.09 | 2.01x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 750.03 | 5.59 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 37.64 | 111.43 | 0.89 | **19.93x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 23.07 | 181.84 | 1.45 | **32.52x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 25.71 | 10.20 | 0.08 | 2.21x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 56.90 | 4.61 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 8.09 | 32.41 | 0.26 | 7.04x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 9.19 | 28.51 | 0.23 | 6.19x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 377.46 | 11.11 | 0.09 | 2.03x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 766.78 | 5.47 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 131.82 | 31.82 | 0.25 | 5.82x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 132.02 | 31.77 | 0.25 | 5.81x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | kotlin | 512x512 | 29.78 | 8.80 | 0.07 | 1.77x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 52.61 | 4.98 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 4.98 | 52.66 | 0.42 | **10.57x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | avx2 | 512x512 | 3.31 | 79.21 | 0.63 | **15.90x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant) | kotlin | 2048x2048 | 580.40 | 7.23 | 0.06 | 1.82x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1055.40 | 3.97 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 119.70 | 35.04 | 0.28 | 8.82x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 34.09 | 123.02 | 0.98 | **30.95x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 38.76 | 6.76 | 0.05 | 1.87x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 72.52 | 3.61 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 8.46 | 30.98 | 0.25 | 8.57x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 4.54 | 57.76 | 0.46 | **15.98x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 562.09 | 7.46 | 0.06 | 1.84x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1035.88 | 4.05 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 123.74 | 33.90 | 0.27 | 8.37x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 54.46 | 77.02 | 0.62 | **19.02x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 512x512 | 43.58 | 6.02 | 0.05 | 1.79x | ⬆️ |  |
| Lighting (specular, point) | scalar | 512x512 | 78.08 | 3.36 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 10.63 | 24.67 | 0.20 | 7.35x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point) | avx2 | 512x512 | 4.04 | 64.95 | 0.52 | **19.34x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point) | kotlin | 2048x2048 | 512.52 | 8.18 | 0.07 | 1.59x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 813.70 | 5.15 | 0.04 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 164.52 | 25.49 | 0.20 | 4.95x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 52.52 | 79.86 | 0.64 | **15.49x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point, linear) | kotlin | 512x512 | 35.25 | 7.44 | 0.06 | 1.62x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 57.00 | 4.60 | 0.04 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 11.78 | 22.24 | 0.18 | 4.84x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, point, linear) | avx2 | 512x512 | 5.25 | 49.96 | 0.40 | **10.86x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 512.64 | 8.18 | 0.07 | 1.62x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 830.15 | 5.05 | 0.04 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 167.04 | 25.11 | 0.20 | 4.97x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 76.16 | 55.08 | 0.44 | **10.90x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | kotlin | 512x512 | 40.04 | 6.55 | 0.05 | 1.52x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | scalar | 512x512 | 60.87 | 4.31 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 14.33 | 18.29 | 0.15 | 4.25x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | avx2 | 512x512 | 4.90 | 53.54 | 0.43 | **12.43x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot) | kotlin | 2048x2048 | 762.50 | 5.50 | 0.04 | 1.64x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1250.81 | 3.35 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 351.88 | 11.92 | 0.10 | 3.55x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 51.76 | 81.04 | 0.65 | **24.17x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 53.99 | 4.86 | 0.04 | 1.64x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 88.56 | 2.96 | 0.02 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 24.15 | 10.86 | 0.09 | 3.67x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 18.34 | 14.29 | 0.11 | 4.83x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 523.20 | 8.02 | 0.06 | 1.74x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 911.49 | 4.60 | 0.04 | 1.00x |  | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 217.51 | 19.28 | 0.15 | 4.19x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 203.50 | 20.61 | 0.16 | 4.48x | 🟢 |  |
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
| UnLinearize | ssse3 | 2048x2048 | 5.37 | 780.57 | 6.24 | 3.13x | 🟢 |  

## Host Results (x86-32, Android emulator)

x86 emulator (API 30). Missing backend = not advertised on this ABI.

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
| Lighting (diffuse, distant) | kotlin | 512x512 | 17.46 | 15.01 | 0.12 | 1.28x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 22.40 | 11.70 | 0.09 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 512x512 | 6.90 | 38.01 | 0.30 | 3.25x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 512x512 | 1.77 | 148.21 | 1.19 | **12.66x** | 🚀 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 266.28 | 15.75 | 0.13 | 1.36x | ⬆️ |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 362.09 | 11.58 | 0.09 | 1.00x |  |  |
| Lighting (diffuse, distant) | ssse3 | 2048x2048 | 105.18 | 39.88 | 0.32 | 3.44x | 🟢 |  |
| Lighting (diffuse, distant) | avx2 | 2048x2048 | 14.25 | 294.33 | 2.35 | **25.41x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 17.21 | 15.24 | 0.12 | 3.15x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 54.21 | 4.84 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 512x512 | 7.11 | 36.85 | 0.29 | 7.62x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 512x512 | 3.63 | 72.26 | 0.58 | **14.94x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 265.83 | 15.78 | 0.13 | 3.14x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 835.07 | 5.02 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | ssse3 | 2048x2048 | 109.23 | 38.40 | 0.31 | 7.65x | 🟢 |  |
| Lighting (diffuse, distant, linear) | avx2 | 2048x2048 | 51.40 | 81.61 | 0.65 | **16.25x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 18.89 | 13.88 | 0.11 | 3.12x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 58.96 | 4.45 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 512x512 | 7.96 | 32.91 | 0.26 | 7.40x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 512x512 | 2.19 | 119.97 | 0.96 | **26.98x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 291.83 | 14.37 | 0.11 | 3.15x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 920.43 | 4.56 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point) | ssse3 | 2048x2048 | 125.16 | 33.51 | 0.27 | 7.35x | 🟢 |  |
| Lighting (diffuse, point) | avx2 | 2048x2048 | 19.97 | 210.00 | 1.68 | **46.08x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 17.88 | 14.66 | 0.12 | 3.47x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 62.00 | 4.23 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 512x512 | 8.39 | 31.26 | 0.25 | 7.39x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 512x512 | 3.05 | 86.03 | 0.69 | **20.35x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 281.06 | 14.92 | 0.12 | 3.35x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 942.94 | 4.45 | 0.04 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | ssse3 | 2048x2048 | 128.26 | 32.70 | 0.26 | 7.35x | 🟢 |  |
| Lighting (diffuse, point, linear) | avx2 | 2048x2048 | 33.31 | 125.93 | 1.01 | **28.31x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 23.12 | 11.34 | 0.09 | 2.75x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | scalar | 512x512 | 63.49 | 4.13 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 512x512 | 8.80 | 29.79 | 0.24 | 7.22x | 🟢 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, spot) | avx2 | 512x512 | 9.05 | 28.96 | 0.23 | 7.01x | 🟢 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 343.92 | 12.20 | 0.10 | 2.84x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 975.95 | 4.30 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | ssse3 | 2048x2048 | 127.64 | 32.86 | 0.26 | 7.65x | 🟢 |  |
| Lighting (diffuse, spot) | avx2 | 2048x2048 | 131.18 | 31.97 | 0.26 | 7.44x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 21.69 | 12.09 | 0.10 | 2.96x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 64.15 | 4.09 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 512x512 | 9.03 | 29.04 | 0.23 | 7.11x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 512x512 | 9.29 | 28.21 | 0.23 | 6.90x | 🟢 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 339.61 | 12.35 | 0.10 | 2.98x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1012.71 | 4.14 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | ssse3 | 2048x2048 | 139.88 | 29.98 | 0.24 | 7.24x | 🟢 |  |
| Lighting (diffuse, spot, linear) | avx2 | 2048x2048 | 138.14 | 30.36 | 0.24 | 7.33x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 28.65 | 9.15 | 0.07 | 2.14x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 61.20 | 4.28 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 512x512 | 18.34 | 14.29 | 0.11 | 3.34x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 512x512 | 14.69 | 17.84 | 0.14 | 4.17x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 440.25 | 9.53 | 0.08 | 2.14x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 944.23 | 4.44 | 0.04 | 1.00x |  |  |
| Lighting (specular, distant) | ssse3 | 2048x2048 | 284.43 | 14.75 | 0.12 | 3.32x | 🟢 |  |
| Lighting (specular, distant) | avx2 | 2048x2048 | 204.07 | 20.55 | 0.16 | 4.63x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 28.00 | 9.36 | 0.07 | 2.21x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 61.95 | 4.23 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 512x512 | 18.24 | 14.37 | 0.11 | 3.40x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 512x512 | 15.08 | 17.38 | 0.14 | 4.11x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 450.87 | 9.30 | 0.07 | 2.18x | ⬆️ | ⚠️ UNSTABLE BENCH |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 980.90 | 4.28 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | ssse3 | 2048x2048 | 291.54 | 14.39 | 0.12 | 3.36x | 🟢 |  |
| Lighting (specular, distant, linear) | avx2 | 2048x2048 | 230.06 | 18.23 | 0.15 | 4.26x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 32.96 | 7.95 | 0.06 | 2.07x | ⬆️ |  |
| Lighting (specular, point) | scalar | 512x512 | 68.35 | 3.84 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 512x512 | 23.91 | 10.96 | 0.09 | 2.86x | 🟢 |  |
| Lighting (specular, point) | avx2 | 512x512 | 22.93 | 11.43 | 0.09 | 2.98x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 520.02 | 8.07 | 0.06 | 1.97x | ⬆️ |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1025.56 | 4.09 | 0.03 | 1.00x |  |  |
| Lighting (specular, point) | ssse3 | 2048x2048 | 360.84 | 11.62 | 0.09 | 2.84x | 🟢 |  |
| Lighting (specular, point) | avx2 | 2048x2048 | 337.40 | 12.43 | 0.10 | 3.04x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 32.63 | 8.03 | 0.06 | 2.16x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 70.57 | 3.71 | 0.03 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 512x512 | 23.78 | 11.02 | 0.09 | 2.97x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 512x512 | 23.57 | 11.12 | 0.09 | 2.99x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 509.10 | 8.24 | 0.07 | 2.06x | ⬆️ |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1047.16 | 4.01 | 0.03 | 1.00x |  |  |
| Lighting (specular, point, linear) | ssse3 | 2048x2048 | 373.68 | 11.22 | 0.09 | 2.80x | 🟢 |  |
| Lighting (specular, point, linear) | avx2 | 2048x2048 | 356.15 | 11.78 | 0.09 | 2.94x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 32.86 | 7.98 | 0.06 | 2.12x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 69.82 | 3.75 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 512x512 | 21.96 | 11.94 | 0.10 | 3.18x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 512x512 | 28.35 | 9.25 | 0.07 | 2.46x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 511.73 | 8.20 | 0.07 | 2.11x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1080.33 | 3.88 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot) | ssse3 | 2048x2048 | 340.57 | 12.32 | 0.10 | 3.17x | 🟢 |  |
| Lighting (specular, spot) | avx2 | 2048x2048 | 423.95 | 9.89 | 0.08 | 2.55x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 33.15 | 7.91 | 0.06 | 2.16x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 71.45 | 3.67 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 512x512 | 23.34 | 11.23 | 0.09 | 3.06x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 512x512 | 29.11 | 9.01 | 0.07 | 2.45x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 519.53 | 8.07 | 0.06 | 2.17x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1128.89 | 3.72 | 0.03 | 1.00x |  |  |
| Lighting (specular, spot, linear) | ssse3 | 2048x2048 | 364.78 | 11.50 | 0.09 | 3.09x | 🟢 |  |
| Lighting (specular, spot, linear) | avx2 | 2048x2048 | 430.57 | 9.74 | 0.08 | 2.62x | 🟢 |  |
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
| Lighting (diffuse, distant) | kotlin | 512x512 | 45.53 | 5.76 | 0.05 | 0.47x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 21.43 | 12.23 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 512x512 | 1.86 | 140.73 | 1.13 | **11.51x** | 🚀 | ⚠️ UNSTABLE BENCH |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 737.67 | 5.69 | 0.05 | 0.46x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 337.38 | 12.43 | 0.10 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon64 | 2048x2048 | 21.97 | 190.91 | 1.53 | **15.36x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 45.62 | 5.75 | 0.05 | 1.37x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 62.72 | 4.18 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon64 | 512x512 | 2.53 | 103.45 | 0.83 | **24.75x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 739.22 | 5.67 | 0.05 | 1.33x | ⬆️ |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 983.68 | 4.26 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon64 | 2048x2048 | 31.63 | 132.59 | 1.06 | **31.10x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 59.64 | 4.40 | 0.04 | 1.20x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 512x512 | 71.61 | 3.66 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point) | neon64 | 512x512 | 2.25 | 116.26 | 0.93 | **31.76x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 967.40 | 4.34 | 0.03 | 1.17x | ⬆️ |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1129.39 | 3.71 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point) | neon64 | 2048x2048 | 30.72 | 136.53 | 1.09 | **36.76x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 59.74 | 4.39 | 0.04 | 1.21x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 72.41 | 3.62 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon64 | 512x512 | 2.85 | 91.92 | 0.74 | **25.39x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 964.19 | 4.35 | 0.03 | 1.19x | ⬆️ |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1148.99 | 3.65 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon64 | 2048x2048 | 34.00 | 123.37 | 0.99 | **33.79x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 60.78 | 4.31 | 0.03 | 1.30x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 78.96 | 3.32 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon64 | 512x512 | 2.59 | 101.03 | 0.81 | **30.43x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 981.56 | 4.27 | 0.03 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 1288.95 | 3.25 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon64 | 2048x2048 | 33.17 | 126.44 | 1.01 | **38.85x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 60.95 | 4.30 | 0.03 | 1.30x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 79.28 | 3.31 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon64 | 512x512 | 3.09 | 84.71 | 0.68 | **25.62x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 983.21 | 4.27 | 0.03 | 1.31x | ⬆️ |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1291.24 | 3.25 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon64 | 2048x2048 | 38.04 | 110.26 | 0.88 | **33.94x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 77.23 | 3.39 | 0.03 | 1.02x | ⬆️ |  |
| Lighting (specular, distant) | scalar | 512x512 | 78.42 | 3.34 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 512x512 | 3.75 | 69.81 | 0.56 | **20.88x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 1247.57 | 3.36 | 0.03 | 0.99x |  |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1232.04 | 3.40 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant) | neon64 | 2048x2048 | 49.40 | 84.90 | 0.68 | **24.94x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 77.48 | 3.38 | 0.03 | 1.02x | ⬆️ |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 79.14 | 3.31 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon64 | 512x512 | 4.43 | 59.16 | 0.47 | **17.86x** | 🚀 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 1247.61 | 3.36 | 0.03 | 0.99x |  |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1237.47 | 3.39 | 0.03 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon64 | 2048x2048 | 58.19 | 72.08 | 0.58 | **21.27x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 512x512 | 90.92 | 2.88 | 0.02 | 0.96x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 86.94 | 3.02 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon64 | 512x512 | 4.61 | 56.87 | 0.45 | **18.86x** | 🚀 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 1461.46 | 2.87 | 0.02 | 0.93x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1366.30 | 3.07 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon64 | 2048x2048 | 61.05 | 68.70 | 0.55 | **22.38x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 91.26 | 2.87 | 0.02 | 0.96x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 87.62 | 2.99 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon64 | 512x512 | 5.04 | 52.05 | 0.42 | **17.40x** | 🚀 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 1467.88 | 2.86 | 0.02 | 0.94x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1376.98 | 3.05 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon64 | 2048x2048 | 66.93 | 62.66 | 0.50 | **20.57x** | 🚀 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 92.92 | 2.82 | 0.02 | 1.00x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 512x512 | 93.22 | 2.81 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon64 | 512x512 | 4.83 | 54.28 | 0.43 | **19.30x** | 🚀 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 1496.71 | 2.80 | 0.02 | 1.01x | ⬆️ |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1505.59 | 2.79 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon64 | 2048x2048 | 64.24 | 65.29 | 0.52 | **23.44x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 93.39 | 2.81 | 0.02 | 1.00x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 93.84 | 2.79 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon64 | 512x512 | 5.24 | 50.06 | 0.40 | **17.92x** | 🚀 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 1502.31 | 2.79 | 0.02 | 1.01x | ⬆️ |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1513.33 | 2.77 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon64 | 2048x2048 | 69.78 | 60.10 | 0.48 | **21.69x** | 🚀 |  |
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
| Lighting (diffuse, distant) | kotlin | 512x512 | 105.14 | 2.49 | 0.02 | 0.30x |  |  |
| Lighting (diffuse, distant) | scalar | 512x512 | 31.18 | 8.41 | 0.07 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon32 | 512x512 | 4.76 | 55.05 | 0.44 | 6.55x | 🟢 |  |
| Lighting (diffuse, distant) | kotlin | 2048x2048 | 1652.55 | 2.54 | 0.02 | 0.27x |  |  |
| Lighting (diffuse, distant) | scalar | 2048x2048 | 443.88 | 9.45 | 0.08 | 1.00x |  |  |
| Lighting (diffuse, distant) | neon32 | 2048x2048 | 50.28 | 83.41 | 0.67 | 8.83x | 🟢 |  |
| Lighting (diffuse, distant, linear) | kotlin | 512x512 | 104.95 | 2.50 | 0.02 | 0.82x |  |  |
| Lighting (diffuse, distant, linear) | scalar | 512x512 | 86.12 | 3.04 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon32 | 512x512 | 4.91 | 53.44 | 0.43 | **17.56x** | 🚀 |  |
| Lighting (diffuse, distant, linear) | kotlin | 2048x2048 | 1657.96 | 2.53 | 0.02 | 0.74x |  |  |
| Lighting (diffuse, distant, linear) | scalar | 2048x2048 | 1226.59 | 3.42 | 0.03 | 1.00x |  |  |
| Lighting (diffuse, distant, linear) | neon32 | 2048x2048 | 56.81 | 73.82 | 0.59 | **21.59x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 512x512 | 143.96 | 1.82 | 0.01 | 0.68x |  |  |
| Lighting (diffuse, point) | scalar | 512x512 | 98.05 | 2.67 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point) | neon32 | 512x512 | 6.43 | 40.75 | 0.33 | **15.24x** | 🚀 |  |
| Lighting (diffuse, point) | kotlin | 2048x2048 | 2278.33 | 1.84 | 0.01 | 0.61x |  |  |
| Lighting (diffuse, point) | scalar | 2048x2048 | 1397.60 | 3.00 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point) | neon32 | 2048x2048 | 80.86 | 51.87 | 0.41 | **17.28x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 512x512 | 145.18 | 1.81 | 0.01 | 0.68x |  |  |
| Lighting (diffuse, point, linear) | scalar | 512x512 | 98.94 | 2.65 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon32 | 512x512 | 6.96 | 37.68 | 0.30 | **14.22x** | 🚀 |  |
| Lighting (diffuse, point, linear) | kotlin | 2048x2048 | 2268.40 | 1.85 | 0.01 | 0.63x |  |  |
| Lighting (diffuse, point, linear) | scalar | 2048x2048 | 1420.60 | 2.95 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, point, linear) | neon32 | 2048x2048 | 90.27 | 46.47 | 0.37 | **15.74x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 512x512 | 147.00 | 1.78 | 0.01 | 0.75x |  |  |
| Lighting (diffuse, spot) | scalar | 512x512 | 109.63 | 2.39 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon32 | 512x512 | 7.07 | 37.08 | 0.30 | **15.51x** | 🚀 |  |
| Lighting (diffuse, spot) | kotlin | 2048x2048 | 2313.01 | 1.81 | 0.01 | 0.67x |  |  |
| Lighting (diffuse, spot) | scalar | 2048x2048 | 1544.95 | 2.71 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot) | neon32 | 2048x2048 | 89.72 | 46.75 | 0.37 | **17.22x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 512x512 | 146.15 | 1.79 | 0.01 | 0.76x |  |  |
| Lighting (diffuse, spot, linear) | scalar | 512x512 | 111.17 | 2.36 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon32 | 512x512 | 7.43 | 35.27 | 0.28 | **14.96x** | 🚀 |  |
| Lighting (diffuse, spot, linear) | kotlin | 2048x2048 | 2324.65 | 1.80 | 0.01 | 0.67x |  |  |
| Lighting (diffuse, spot, linear) | scalar | 2048x2048 | 1558.82 | 2.69 | 0.02 | 1.00x |  |  |
| Lighting (diffuse, spot, linear) | neon32 | 2048x2048 | 101.81 | 41.20 | 0.33 | **15.31x** | 🚀 |  |
| Lighting (specular, distant) | kotlin | 512x512 | 189.56 | 1.38 | 0.01 | 0.52x |  |  |
| Lighting (specular, distant) | scalar | 512x512 | 98.47 | 2.66 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon32 | 512x512 | 14.35 | 18.27 | 0.15 | 6.86x | 🟢 |  |
| Lighting (specular, distant) | kotlin | 2048x2048 | 2990.34 | 1.40 | 0.01 | 0.49x |  |  |
| Lighting (specular, distant) | scalar | 2048x2048 | 1466.18 | 2.86 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant) | neon32 | 2048x2048 | 202.60 | 20.70 | 0.17 | 7.24x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 512x512 | 188.78 | 1.39 | 0.01 | 0.55x |  |  |
| Lighting (specular, distant, linear) | scalar | 512x512 | 103.25 | 2.54 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon32 | 512x512 | 16.40 | 15.99 | 0.13 | 6.30x | 🟢 |  |
| Lighting (specular, distant, linear) | kotlin | 2048x2048 | 2992.05 | 1.40 | 0.01 | 0.51x |  |  |
| Lighting (specular, distant, linear) | scalar | 2048x2048 | 1531.85 | 2.74 | 0.02 | 1.00x |  |  |
| Lighting (specular, distant, linear) | neon32 | 2048x2048 | 233.89 | 17.93 | 0.14 | 6.55x | 🟢 |  |
| Lighting (specular, point) | kotlin | 512x512 | 225.66 | 1.16 | 0.01 | 0.49x |  |  |
| Lighting (specular, point) | scalar | 512x512 | 111.56 | 2.35 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon32 | 512x512 | 18.67 | 14.04 | 0.11 | 5.98x | 🟢 |  |
| Lighting (specular, point) | kotlin | 2048x2048 | 3587.53 | 1.17 | 0.01 | 0.46x |  |  |
| Lighting (specular, point) | scalar | 2048x2048 | 1658.99 | 2.53 | 0.02 | 1.00x |  |  |
| Lighting (specular, point) | neon32 | 2048x2048 | 278.55 | 15.06 | 0.12 | 5.96x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 512x512 | 225.60 | 1.16 | 0.01 | 0.51x |  |  |
| Lighting (specular, point, linear) | scalar | 512x512 | 115.72 | 2.27 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon32 | 512x512 | 20.54 | 12.77 | 0.10 | 5.64x | 🟢 |  |
| Lighting (specular, point, linear) | kotlin | 2048x2048 | 3587.82 | 1.17 | 0.01 | 0.48x |  |  |
| Lighting (specular, point, linear) | scalar | 2048x2048 | 1723.49 | 2.43 | 0.02 | 1.00x |  |  |
| Lighting (specular, point, linear) | neon32 | 2048x2048 | 303.77 | 13.81 | 0.11 | 5.67x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 512x512 | 229.82 | 1.14 | 0.01 | 0.54x |  |  |
| Lighting (specular, spot) | scalar | 512x512 | 123.01 | 2.13 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon32 | 512x512 | 18.37 | 14.27 | 0.11 | 6.70x | 🟢 |  |
| Lighting (specular, spot) | kotlin | 2048x2048 | 3701.02 | 1.13 | 0.01 | 0.48x |  |  |
| Lighting (specular, spot) | scalar | 2048x2048 | 1794.91 | 2.34 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot) | neon32 | 2048x2048 | 269.86 | 15.54 | 0.12 | 6.65x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 512x512 | 230.51 | 1.14 | 0.01 | 0.55x |  |  |
| Lighting (specular, spot, linear) | scalar | 512x512 | 127.93 | 2.05 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon32 | 512x512 | 20.43 | 12.83 | 0.10 | 6.26x | 🟢 |  |
| Lighting (specular, spot, linear) | kotlin | 2048x2048 | 3670.23 | 1.14 | 0.01 | 0.51x |  |  |
| Lighting (specular, spot, linear) | scalar | 2048x2048 | 1863.15 | 2.25 | 0.02 | 1.00x |  |  |
| Lighting (specular, spot, linear) | neon32 | 2048x2048 | 295.43 | 14.20 | 0.11 | 6.31x | 🟢 |  |
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
