# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels and Kotlin reference implementations compared to their scalar C++ counterparts.

Marker column: 🚀 very good speedup (>9x); 🟢 decent speedup; 🔴 regression (slower than the scalar baseline).

**Backend row ordering (x86):** within a kernel block, rows follow the x86 ISA
superset hierarchy — each ISA builds on the previous one:
`kotlin → scalar → sse2 → ssse3 → avx2 → avx512`. Keep this order when adding or
re-measuring rows (missing levels are simply absent). `scalar` is the baseline (1.00x).
(ARM rows: `kotlin → scalar → neon32 → neon64`.)

Kernel rows are ordered alphabetically by kernel name; within each kernel, sizes are ordered from 512x512 to 2048x2048.

## Host Results (i7-7820X)

Measured on macOS (i7-7820X, 64-bit host build).

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 10.258 | 25.56 | 0.20 | 0.31x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 3.222 | 81.36 | 0.65 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.113 | 84.21 | 0.67 | 1.03x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.111 | 84.27 | 0.67 | 1.04x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 169.407 | 24.76 | 0.20 | 0.31x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 51.794 | 80.98 | 0.65 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 50.661 | 82.79 | 0.66 | 1.02x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 49.610 | 84.55 | 0.68 | 1.04x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.443 | 25.10 | 0.20 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.844 | 310.75 | 2.49 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.482 | 543.72 | 4.35 | 1.75x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.307 | 852.67 | 6.82 | 2.74x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 170.798 | 24.56 | 0.20 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.758 | 304.86 | 2.44 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.099 | 517.89 | 4.14 | 1.70x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.886 | 712.65 | 5.70 | 2.34x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.634 | 413.45 | 3.31 | 0.46x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.290 | 904.71 | 7.24 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 9.523 | 440.43 | 3.52 | 0.52x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 4.985 | 841.32 | 6.73 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 12.152 | 21.57 | 0.17 | 1.09x | 🟢 | Kotlin JIT wins slightly on 512x512 |
| ConvolveMatrix | scalar | 512x512 | 13.305 | 19.70 | 0.16 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 2.216 | 118.27 | 0.95 | 6.00x | 🟢 |  |
| ConvolveMatrix | avx2 | 512x512 | 1.219 | 214.99 | 1.72 | **10.91x** | 🚀 |  |
| ConvolveMatrix | avx512 | 512x512 | 1.282 | 204.54 | 1.64 | **10.38x** | 🚀 |  |
| ConvolveMatrix | kotlin | 2048x2048 | 179.286 | 23.39 | 0.19 | 1.17x | 🟢 |  |
| ConvolveMatrix | scalar | 2048x2048 | 210.067 | 19.97 | 0.16 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 40.057 | 104.71 | 0.84 | 5.24x | 🟢 |  |
| ConvolveMatrix | avx2 | 2048x2048 | 20.770 | 201.94 | 1.62 | **10.11x** | 🚀 |  |
| ConvolveMatrix | avx512 | 2048x2048 | 18.278 | 229.47 | 1.84 | **11.49x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 4.751 | 55.17 | 0.66 | 0.54x |  |  |
| DisplacementMap | scalar | 512x512 | 2.548 | 102.87 | 1.23 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 1.082 | 242.23 | 2.91 | 2.35x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.879 | 298.19 | 3.58 | 2.90x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.647 | 405.18 | 4.86 | 3.94x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 77.089 | 54.41 | 0.65 | 0.50x |  |  |
| DisplacementMap | scalar | 2048x2048 | 38.301 | 109.51 | 1.31 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 18.487 | 226.88 | 2.72 | 2.07x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 15.472 | 271.09 | 3.25 | 2.48x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 15.433 | 271.77 | 3.26 | 2.48x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 9.885 | 26.52 | 0.21 | 2.11x | 🟢 | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 512x512 | 20.866 | 12.56 | 0.10 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 6.438 | 40.72 | 0.33 | 3.24x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.296 | 41.64 | 0.33 | 3.31x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 364.663 | 11.50 | 0.09 | 1.03x | 🟢 |  |
| GaussianBlur | scalar | 2048x2048 | 375.840 | 11.16 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 99.505 | 42.15 | 0.34 | 3.78x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 100.324 | 41.81 | 0.32 | 3.75x | 🟢 |  |
| Lighting | kotlin | 512x512 | 26.185 | 10.01 | 0.08 | 0.51x |  |  |
| Lighting | scalar | 512x512 | 13.345 | 19.64 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.507 | 173.98 | 1.39 | 8.86x | 🟢 |  |
| Lighting | avx2 | 512x512 | 1.137 | 230.54 | 1.84 | **11.74x** | 🚀 |  |
| Lighting | avx512 | 512x512 | 1.333 | 196.67 | 1.57 | **10.01x** | 🚀 |  |
| Lighting | kotlin | 2048x2048 | 419.779 | 9.99 | 0.08 | 0.51x |  |  |
| Lighting | scalar | 2048x2048 | 213.301 | 19.66 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 25.734 | 162.99 | 1.30 | 8.29x | 🟢 |  |
| Lighting | avx2 | 2048x2048 | 18.643 | 224.98 | 1.80 | **11.44x** | 🚀 |  |
| Lighting | avx512 | 2048x2048 | 16.259 | 257.97 | 2.06 | **13.12x** | 🚀 |  |
| Morphology | kotlin | 512x512 | 57.228 | 4.58 | 0.04 | 0.47x |  |  |
| Morphology | scalar | 512x512 | 26.710 | 9.81 | 0.08 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.577 | 166.18 | 1.33 | **16.93x** | 🚀 |  |
| Morphology | avx2 | 512x512 | 1.368 | 191.59 | 1.53 | **19.52x** | 🚀 |  |
| Morphology | avx512 | 512x512 | 2.237 | 117.16 | 0.94 | **11.94x** | 🚀 |  |
| Morphology | kotlin | 2048x2048 | 993.637 | 4.22 | 0.03 | 0.52x |  |  |
| Morphology | scalar | 2048x2048 | 521.138 | 8.05 | 0.06 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 30.061 | 139.53 | 1.12 | **17.34x** | 🚀 |  |
| Morphology | avx2 | 2048x2048 | 26.190 | 160.15 | 1.28 | **19.90x** | 🚀 |  |
| Morphology | avx512 | 2048x2048 | 40.523 | 103.50 | 0.83 | **12.86x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 22.750 | 11.52 | 0.05 | 0.70x |  |  |
| Turbulence | scalar | 512x512 | 15.963 | 16.42 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 11.461 | 22.87 | 0.09 | 1.39x | 🟢 |  |
| Turbulence | avx2 | 512x512 | 7.384 | 35.50 | 0.14 | 2.16x | 🟢 |  |
| Turbulence | kotlin | 2048x2048 | 367.007 | 11.43 | 0.05 | 0.70x |  |  |
| Turbulence | scalar | 2048x2048 | 256.637 | 16.34 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 185.396 | 22.62 | 0.09 | 1.38x | 🟢 |  |
| Turbulence | avx2 | 2048x2048 | 125.600 | 33.39 | 0.13 | 2.04x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.395 | 664.42 | 5.32 | 0.95x |  |  |
| UnLinearize | scalar | 512x512 | 0.373 | 702.20 | 5.62 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.268 | 976.69 | 7.81 | 1.39x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.279 | 939.52 | 7.52 | 1.34x | 🟢 |  |
| UnLinearize | kotlin | 2048x2048 | 6.639 | 631.74 | 5.05 | 1.15x | 🟢 | Kotlin JIT wins on large size |
| UnLinearize | scalar | 2048x2048 | 7.661 | 547.50 | 4.38 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 5.007 | 837.70 | 6.70 | 1.53x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 5.252 | 798.55 | 6.39 | 1.46x | 🟢 |  |

## Host Results (x86-32, Android emulator)

Measured on an x86 (32-bit) Android 8.0 emulator.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | scalar | 512x512 | 20.666 | 12.68 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 121.969 | 2.15 | 0.02 | 0.17x | 🔴 | ssse3 pshufb path slower than scalar |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 332.179 | 12.63 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 1940.519 | 2.16 | 0.02 | 0.17x | 🔴 | ssse3 pshufb path slower than scalar |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 23.379 | 11.21 | 0.09 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 15.876 | 16.51 | 0.13 | 1.47x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 368.756 | 11.37 | 0.09 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 252.538 | 16.61 | 0.13 | 1.46x | 🟢 |  |
| ComponentTransfer | scalar | 512x512 | 1.369 | 191.46 | 1.53 | 1.00x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 21.847 | 191.99 | 1.54 | 1.00x |  |  |
| ConvolveMatrix | scalar | 512x512 | 98.760 | 2.66 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 4.942 | 53.18 | 0.43 | **19.98x** | 🚀 |  |
| ConvolveMatrix | ssse3 | 512x512 | 38.345 | 6.84 | 0.05 | 2.60x | 🟢 |  |
| ConvolveMatrix | scalar | 2048x2048 | 1573.879 | 2.67 | 0.02 | — | ⚠️ | harness-invalidated measurement; baseline not used |
| ConvolveMatrix | sse2 | 2048x2048 | 59.464 | 70.61 | 0.56 | — | 🟢 | scalar baseline invalid in this run |
| ConvolveMatrix | ssse3 | 2048x2048 | 603.232 | 6.95 | 0.06 | 2.65x | 🟢 |  |
| DisplacementMap | scalar | 512x512 | 7.745 | 33.95 | 0.27 | 1.00x |  |  |
| DisplacementMap | ssse3 | 512x512 | 0.494 | 553.52 | 4.43 | **15.68x** | 🚀 |  |
| DisplacementMap | scalar | 2048x2048 | 119.300 | 35.15 | 0.28 | 1.00x |  |  |
| DisplacementMap | ssse3 | 2048x2048 | 7.745 | 542.29 | 4.34 | **15.40x** | 🚀 |  |
| GaussianBlur | scalar | 512x512 | 250.787 | 1.05 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 11.752 | 22.31 | 0.18 | **21.34x** | 🚀 |  |
| GaussianBlur | scalar | 2048x2048 | 4100.986 | 1.02 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 169.971 | 24.68 | 0.20 | **24.13x** | 🚀 |  |
| Lighting | scalar | 512x512 | 67.943 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.771 | 148.00 | 1.18 | **38.4x** | 🚀 |  |
| Lighting | scalar | 2048x2048 | 1087.123 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 19.766 | 212.20 | 1.70 | **55.0x** | 🚀 |  |
| Morphology | scalar | 512x512 | 155.450 | 1.69 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.557 | 168.33 | 1.35 | **99.79x** | 🚀 |  |
| Morphology | scalar | 2048x2048 | 2537.789 | 1.65 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 24.784 | 169.23 | 1.35 | **102.40x** | 🚀 |  |
| Turbulence | scalar | 512x512 | 69.761 | 3.76 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 13.730 | 19.09 | 0.15 | **5.08x** | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 1111.571 | 3.77 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 218.275 | 19.22 | 0.15 | **5.10x** | 🟢 |  |
| UnLinearize | scalar | 512x512 | 0.927 | 311.55 | 2.49 | 1.00x | 🟢 |  |
| UnLinearize | ssse3 | 512x512 | 0.281 | 1090.64 | 8.72 | **3.30x** | 🟢 |  |
| UnLinearize | scalar | 2048x2048 | 13.635 | 309.91 | 2.48 | 1.00x | 🟢 |  |
| UnLinearize | ssse3 | 2048x2048 | 3.992 | 1057.71 | 8.46 | **3.42x** | 🟢 |  |

The emulator exposes only `scalar`/`sse2`/`ssse3` (AVX is gated out of runtime detection on 32-bit x86 by Android).
If a kernel row is missing a backend it is not advertised on this ABI. Morphology exposes only scalar/SSE2/AVX2/AVX-512 on x86.

## Device Results (OnePlus 11)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | scalar | 512x512 | 17.49 | 14.98 | 0.12 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon64 | 512x512 | 2.16 | 121.34 | 0.97 | 8.10x | 🟢 |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 280.11 | 14.97 | 0.12 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon64 | 2048x2048 | 34.36 | 122.07 | 0.98 | 8.15x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 17.39 | 15.07 | 0.12 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon64 | 512x512 | 1.02 | 256.38 | 2.05 | **17.05x** | 🚀 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 265.29 | 15.81 | 0.13 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon64 | 2048x2048 | 16.26 | 258.02 | 2.06 | **16.32x** | 🚀 |  |
| ComponentTransfer | scalar | 512x512 | 1.29 | 203.54 | 1.63 | 1.00x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 21.16 | 198.26 | 1.59 | 1.00x |  |  |
| ConvolveMatrix | scalar | 512x512 | 95.24 | 2.75 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | neon64 | 512x512 | 5.92 | 44.27 | 0.35 | **16.09x** | 🚀 |  |
| ConvolveMatrix | scalar | 2048x2048 | 1511.95 | 2.77 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | neon64 | 2048x2048 | 83.96 | 49.95 | 0.40 | **18.01x** | 🚀 |  |
| DisplacementMap | scalar | 512x512 | 5.71 | 45.94 | 0.37 | 1.00x |  |  |
| DisplacementMap | neon64 | 512x512 | 0.46 | 568.78 | 4.55 | **12.41x** | 🚀 |  |
| DisplacementMap | scalar | 2048x2048 | 91.43 | 45.88 | 0.37 | 1.00x |  |  |
| DisplacementMap | neon64 | 2048x2048 | 7.44 | 563.48 | 4.51 | **12.29x** | 🚀 |  |
| GaussianBlur | scalar | 512x512 | 245.67 | 1.07 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon64 | 512x512 | 4.42 | 59.26 | 0.47 | **55.58x** | 🚀 |  |
| GaussianBlur | scalar | 2048x2048 | 4352.96 | 0.96 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon64 | 2048x2048 | 83.81 | 50.05 | 0.40 | **51.94x** | 🚀 |  |
| Lighting | scalar | 512x512 | 69.78 | 3.76 | 0.03 | 1.00x |  |  |
| Lighting | neon64 | 512x512 | 71.85 | 3.65 | 0.03 | 0.97x | 🔴 |  |
| Lighting | scalar | 2048x2048 | 1111.94 | 3.77 | 0.03 | 1.00x |  |  |
| Lighting | neon64 | 2048x2048 | 1132.80 | 3.70 | 0.03 | 0.98x | 🔴 |  |
| Morphology | scalar | 512x512 | 198.86 | 1.32 | 0.01 | 1.00x |  |  |
| Morphology | neon64 | 512x512 | 2.01 | 130.51 | 1.04 | **98.94x** | 🚀 |  |
| Morphology | scalar | 2048x2048 | 3270.68 | 1.28 | 0.01 | 1.00x |  |  |
| Morphology | neon64 | 2048x2048 | 28.35 | 147.94 | 1.18 | **115.37x** | 🚀 |  |
| Turbulence | scalar | 512x512 | 90.34 | 2.90 | 0.02 | 1.00x |  |  |
| Turbulence | neon64 | 512x512 | 4.46 | 58.76 | 0.47 | **20.25x** | 🚀 |  |
| Turbulence | scalar | 2048x2048 | 1446.44 | 2.90 | 0.02 | 1.00x |  |  |
| Turbulence | neon64 | 2048x2048 | 70.88 | 59.18 | 0.47 | **20.41x** | 🚀 |  |
| UnLinearize | scalar | 512x512 | 1.12 | 234.28 | 1.87 | 1.00x |  |  |
| UnLinearize | neon64 | 512x512 | — | — | — | — | 🔴 | un-advertised (was 0.05x regression) |
| UnLinearize | scalar | 2048x2048 | 18.40 | 227.91 | 1.82 | 1.00x |  |  |
| UnLinearize | neon64 | 2048x2048 | — | — | — | — | 🔴 | un-advertised (was 0.05x regression) |

## Device Results (OnePlus 11, 32-bit ARM)

Measured on OnePlus 11 (CPH2449) running the `armeabi-v7a` (32-bit).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | scalar | 512x512 | 32.58 | 8.05 | 0.06 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 512x512 | 9.60 | 27.30 | 0.22 | 3.39x | 🟢 |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 518.90 | 8.08 | 0.06 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 2048x2048 | 154.46 | 27.16 | 0.22 | 3.36x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 30.64 | 8.56 | 0.07 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 512x512 | 2.28 | 114.82 | 0.92 | **13.44x** | 🚀 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 486.11 | 8.63 | 0.07 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 2048x2048 | 36.73 | 114.18 | 0.91 | **13.23x** | 🚀 |  |
| ComponentTransfer | scalar | 512x512 | 1.925 | 136.15 | 1.09 | 1.00x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 39.247 | 106.87 | 0.86 | 1.00x |  |  |
| ConvolveMatrix | scalar | 512x512 | 201.631 | 1.30 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | neon32 | 512x512 | 14.543 | 18.03 | 0.14 | **13.87x** | 🚀 |  |
| ConvolveMatrix | scalar | 2048x2048 | 2949.058 | 1.42 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | neon32 | 2048x2048 | 166.404 | 25.21 | 0.20 | **17.72x** | 🚀 |  |
| DisplacementMap | scalar | 512x512 | 10.580 | 24.78 | 0.20 | 1.00x |  |  |
| DisplacementMap | neon32 | 512x512 | 0.967 | 271.18 | 2.17 | **10.94x** | 🚀 |  |
| DisplacementMap | scalar | 2048x2048 | 187.798 | 22.33 | 0.18 | 1.00x |  |  |
| DisplacementMap | neon32 | 2048x2048 | 23.020 | 182.20 | 1.46 | **8.16x** | 🚀 |  |
| GaussianBlur | scalar | 512x512 | 369.019 | 0.71 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 512x512 | 8.748 | 29.97 | 0.24 | **42.19x** | 🚀 | UNSTABLE (noisy timing) |
| GaussianBlur | scalar | 2048x2048 | 5959.443 | 0.70 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 2048x2048 | 141.507 | 29.64 | 0.24 | **42.11x** | 🚀 |  |
| Lighting | scalar | 512x512 | 103.919 | 2.52 | 0.02 | 1.00x |  |  |
| Lighting | neon32 | 512x512 | 105.469 | 2.49 | 0.02 | 0.99x | 🔴 |  |
| Lighting | scalar | 2048x2048 | 1535.380 | 2.73 | 0.02 | 1.00x |  |  |
| Lighting | neon32 | 2048x2048 | 1554.207 | 2.70 | 0.02 | 0.99x | 🔴 |  |
| Morphology | scalar | 512x512 | 393.798 | 0.67 | 0.01 | 1.00x |  |  |
| Morphology | neon32 | 512x512 | 2.825 | 92.79 | 0.74 | **139.40x** | 🚀 | UNSTABLE (noisy timing) |
| Morphology | scalar | 2048x2048 | 6065.464 | 0.69 | 0.01 | 1.00x |  |  |
| Morphology | neon32 | 2048x2048 | 42.495 | 98.70 | 0.79 | **142.73x** | 🚀 |  |
| Turbulence | scalar | 512x512 | 133.422 | 1.96 | 0.02 | 1.00x |  |  |
| Turbulence | neon32 | 512x512 | 19.943 | 13.14 | 0.11 | 6.69x | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 2123.620 | 1.98 | 0.02 | 1.00x |  |  |
| Turbulence | neon32 | 2048x2048 | 317.419 | 13.21 | 0.11 | 6.69x | 🟢 |  |
| UnLinearize | scalar | 512x512 | 0.939 | 279.26 | 2.23 | 1.00x |  |  |
| UnLinearize | neon32 | 512x512 | 71.004 | 3.69 | 0.03 | 0.01x | 🔴 |  |
| UnLinearize | scalar | 2048x2048 | 19.947 | 210.27 | 1.68 | 1.00x |  |  |
| UnLinearize | neon32 | 2048x2048 | 1136.364 | 3.69 | 0.03 | 0.02x | 🔴 |  |
