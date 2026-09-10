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
| ArithmeticComposite (linear) | kotlin | 512x512 | 10.735 | 24.42 | 0.20 | 0.30x | |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 3.183 | 82.36 | 0.66 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.157 | 83.03 | 0.66 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.161 | 82.92 | 0.66 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 171.471 | 24.46 | 0.20 | 0.30x | |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 51.453 | 81.52 | 0.65 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 50.733 | 82.67 | 0.66 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 50.181 | 83.58 | 0.67 | 1.03x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.422 | 25.15 | 0.20 | 0.08x | |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.845 | 310.41 | 2.48 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.492 | 533.27 | 4.27 | 1.72x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.308 | 851.52 | 6.81 | 2.74x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 166.758 | 25.15 | 0.20 | 0.08x | |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 14.133 | 296.78 | 2.37 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.307 | 504.93 | 4.04 | 1.70x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.818 | 720.91 | 5.77 | 2.43x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.514 | 509.83 | 4.08 | 0.51x | |  |
| ComponentTransfer | scalar | 512x512 | 0.264 | 993.84 | 7.95 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 9.120 | 459.88 | 3.68 | 0.54x | |  |
| ComponentTransfer | scalar | 2048x2048 | 4.897 | 856.45 | 6.85 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 10.068 | 26.04 | 0.21 | 1.30x | ⬆️ | Kotlin JIT wins on 512x512 |
| ConvolveMatrix | scalar | 512x512 | 13.048 | 20.09 | 0.16 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 2.243 | 116.89 | 0.94 | 5.82x | 🟢 |  |
| ConvolveMatrix | avx2 | 512x512 | 1.329 | 197.23 | 1.58 | **9.82x** | 🚀 |  |
| ConvolveMatrix | avx512 | 512x512 | 1.375 | 190.66 | 1.53 | **9.49x** | 🚀 |  |
| ConvolveMatrix | kotlin | 2048x2048 | 165.168 | 25.39 | 0.20 | 1.29x | ⬆️ |  |
| ConvolveMatrix | scalar | 2048x2048 | 212.562 | 19.73 | 0.16 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 39.563 | 106.02 | 0.85 | 5.37x | 🟢 |  |
| ConvolveMatrix | avx2 | 2048x2048 | 20.033 | 209.37 | 1.67 | **10.61x** | 🚀 |  |
| ConvolveMatrix | avx512 | 2048x2048 | 17.803 | 235.59 | 1.88 | **11.94x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 3.974 | 65.96 | 0.79 | 0.58x | |  |
| DisplacementMap | scalar | 512x512 | 2.297 | 114.14 | 1.37 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 1.064 | 246.43 | 2.96 | 2.16x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.809 | 324.17 | 3.89 | 2.84x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.674 | 388.78 | 4.67 | 3.41x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 62.728 | 66.86 | 0.80 | 0.60x | |  |
| DisplacementMap | scalar | 2048x2048 | 37.491 | 111.87 | 1.34 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 17.245 | 243.22 | 2.92 | 2.17x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 14.878 | 281.91 | 3.38 | 2.52x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 14.351 | 292.26 | 3.51 | 2.61x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 9.572 | 27.39 | 0.22 | 2.83x | ⬆️ | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 512x512 | 27.107 | 9.67 | 0.08 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 7.157 | 36.63 | 0.29 | 3.79x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.726 | 38.97 | 0.31 | 4.03x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 350.293 | 11.97 | 0.10 | 1.08x | ⬆️ |  |
| GaussianBlur | scalar | 2048x2048 | 378.613 | 11.08 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 99.308 | 42.24 | 0.34 | 3.81x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 101.565 | 41.30 | 0.33 | 3.73x | 🟢 |  |
| Lighting | kotlin | 512x512 | 10.470 | 25.04 | 0.20 | 1.28x | ⬆️ |  |
| Lighting | scalar | 512x512 | 13.427 | 19.52 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.723 | 152.15 | 1.22 | 7.79x | 🟢 |  |
| Lighting | avx2 | 512x512 | 1.172 | 223.60 | 1.79 | **11.45x** | 🚀 |  |
| Lighting | avx512 | 512x512 | 1.205 | 217.52 | 1.74 | **11.14x** | 🚀 |  |
| Lighting | kotlin | 2048x2048 | 171.523 | 24.45 | 0.20 | 1.26x | ⬆️ |  |
| Lighting | scalar | 2048x2048 | 215.265 | 19.48 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 25.850 | 162.25 | 1.30 | 8.33x | 🟢 |  |
| Lighting | avx2 | 2048x2048 | 18.940 | 221.45 | 1.77 | **11.37x** | 🚀 |  |
| Lighting | avx512 | 2048x2048 | 15.639 | 268.20 | 2.15 | **13.76x** | 🚀 |  |
| Morphology | kotlin | 512x512 | 57.512 | 4.56 | 0.04 | 0.47x | |  |
| Morphology | scalar | 512x512 | 27.172 | 9.65 | 0.08 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.660 | 157.89 | 1.26 | **16.37x** | 🚀 |  |
| Morphology | avx2 | 512x512 | 1.560 | 168.09 | 1.34 | **17.42x** | 🚀 |  |
| Morphology | avx512 | 512x512 | 2.463 | 106.43 | 0.85 | **11.03x** | 🚀 |  |
| Morphology | kotlin | 2048x2048 | 1003.208 | 4.18 | 0.03 | 0.52x | |  |
| Morphology | scalar | 2048x2048 | 522.252 | 8.03 | 0.06 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 28.230 | 148.58 | 1.19 | **18.50x** | 🚀 |  |
| Morphology | avx2 | 2048x2048 | 25.423 | 164.98 | 1.32 | **20.54x** | 🚀 |  |
| Morphology | avx512 | 2048x2048 | 40.077 | 104.66 | 0.84 | **13.03x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 22.118 | 11.85 | 0.05 | 0.73x | |  |
| Turbulence | scalar | 512x512 | 16.038 | 16.35 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 11.829 | 22.16 | 0.09 | 1.36x | 🟢 |  |
| Turbulence | avx2 | 512x512 | 7.965 | 32.91 | 0.13 | 2.01x | 🟢 |  |
| Turbulence | kotlin | 2048x2048 | 366.498 | 11.44 | 0.05 | 0.71x | |  |
| Turbulence | scalar | 2048x2048 | 259.267 | 16.18 | 0.06 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 186.958 | 22.43 | 0.09 | 1.39x | 🟢 |  |
| Turbulence | avx2 | 2048x2048 | 127.918 | 32.79 | 0.13 | 2.03x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.409 | 640.96 | 5.13 | 0.96x | |  |
| UnLinearize | scalar | 512x512 | 0.392 | 669.11 | 5.35 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.255 | 1028.26 | 8.23 | 1.54x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.274 | 957.03 | 7.66 | 1.43x | 🟢 |  |
| UnLinearize | kotlin | 2048x2048 | 6.523 | 643.01 | 5.14 | 0.97x | |  |
| UnLinearize | scalar | 2048x2048 | 6.306 | 665.13 | 5.32 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.503 | 931.41 | 7.45 | 1.40x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 4.824 | 869.47 | 6.96 | 1.31x | 🟢 |  |

## Host Results (x86-32, Android emulator)

Measured on the x86 (32-bit) Android emulator, on the same hardware.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 19.956 | 13.14 | 1.05 | 1.12x | ⬆️ |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 22.304 | 11.75 | 0.09 | 1.00x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 332.179 | 12.63 | 0.10 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 15.229 | 17.21 | 1.38 | 1.69x | ⬆️ |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 25.778 | 10.17 | 0.08 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 15.876 | 16.51 | 0.13 | 1.47x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 368.756 | 11.37 | 0.09 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 252.538 | 16.61 | 0.13 | 1.46x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 1.104 | 237.44 | 1.90 | 0.90x | | ⚠️ UNSTABLE |
| ComponentTransfer | scalar | 512x512 | 0.989 | 265.04 | 2.12 | 1.00x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 21.847 | 191.99 | 1.54 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 67.177 | 3.90 | 0.31 | 1.57x | ⬆️ |  |
| ConvolveMatrix | scalar | 512x512 | 105.296 | 2.49 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 5.188 | 50.53 | 0.40 | **20.29x** | 🚀 |  |
| ConvolveMatrix | ssse3 | 512x512 | 38.345 | 6.84 | 0.05 | 2.60x | 🟢 |  |
| ConvolveMatrix | scalar | 2048x2048 | 1573.879 | 2.67 | 0.02 | 1.00x |  | harness-invalidated measurement |
| ConvolveMatrix | sse2 | 2048x2048 | 68.674 | 61.08 | 0.49 | 22.92x | 🚀 | ⚠️ UNSTABLE |
| ConvolveMatrix | ssse3 | 2048x2048 | 603.232 | 6.95 | 0.06 | 2.65x | 🟢 |  |
| DisplacementMap | kotlin | 512x512 | 4.270 | 61.40 | 4.91 | 1.87x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 7.974 | 32.87 | 0.26 | 1.00x |  |  |
| DisplacementMap | ssse3 | 512x512 | 0.501 | 522.97 | 4.18 | 15.91x | 🚀 | ⚠️ UNSTABLE |
| DisplacementMap | scalar | 2048x2048 | 119.300 | 35.15 | 0.28 | 1.00x |  |  |
| DisplacementMap | ssse3 | 2048x2048 | 7.745 | 542.29 | 4.34 | **15.40x** | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 18.182 | 14.42 | 1.15 | 14.45x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 262.671 | 1.00 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 12.431 | 21.09 | 0.17 | **21.13x** | 🚀 |  |
| GaussianBlur | scalar | 2048x2048 | 4100.986 | 1.02 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 169.971 | 24.68 | 0.20 | **24.13x** | 🚀 |  |
| Lighting | kotlin | 512x512 | 21.619 | 12.13 | 0.97 | 3.30x | ⬆️ |  |
| Lighting | scalar | 512x512 | 71.376 | 3.67 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.934 | 135.54 | 10.84 | 36.91x | 🚀 | ⚠️ UNSTABLE |
| Lighting | scalar | 2048x2048 | 1087.123 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 19.766 | 212.20 | 1.70 | **55.0x** | 🚀 |  |
| Morphology | kotlin | 512x512 | 84.339 | 3.11 | 0.25 | 1.90x | ⬆️ |  |
| Morphology | scalar | 512x512 | 160.499 | 1.63 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.663 | 157.61 | 1.26 | **96.50x** | 🚀 |  |
| Morphology | scalar | 2048x2048 | 2537.789 | 1.65 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 24.784 | 169.23 | 1.35 | **102.40x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 445.686 | 0.59 | 0.05 | 0.16x | |  |
| Turbulence | scalar | 512x512 | 72.658 | 3.61 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 14.780 | 17.74 | 0.14 | 4.92x | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 1111.571 | 3.77 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 218.275 | 19.22 | 0.15 | **5.10x** | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.748 | 350.57 | 2.80 | 1.27x | ⬆️ | ⚠️ UNSTABLE |
| UnLinearize | scalar | 512x512 | 0.947 | 276.79 | 2.21 | 1.00x |  | ⚠️ UNSTABLE |
| UnLinearize | ssse3 | 512x512 | 0.246 | 1066.41 | 8.53 | 3.85x | 🟢 | ⚠️ UNSTABLE |
| UnLinearize | scalar | 2048x2048 | 13.635 | 309.91 | 2.48 | 1.00x | 🟢 |  |
| UnLinearize | ssse3 | 2048x2048 | 3.992 | 1057.71 | 8.46 | **3.42x** | 🟢 |  |

The emulator exposes only `scalar`/`sse2`/`ssse3` (AVX is gated out of runtime detection on 32-bit x86 by Android).
If a kernel row is missing a backend it is not advertised on this ABI. Morphology exposes only scalar/SSE2/AVX2/AVX-512 on x86.

## Device Results (OnePlus 11)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2), `arm64-v8a`; non-quick harness run (512x512 and 2048x2048, median timings).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 54.396 | 4.82 | 0.04 | 0.38x | |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 20.735 | 12.64 | 0.10 | 1.00x | |  |
| ArithmeticComposite (linear) | neon64 | 512x512 | 2.536 | 103.38 | 0.83 | 8.18x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 879.376 | 4.77 | 0.04 | 0.38x | |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 331.791 | 12.64 | 0.10 | 1.00x | |  |
| ArithmeticComposite (linear) | neon64 | 2048x2048 | 40.643 | 103.20 | 0.83 | 8.16x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 47.142 | 5.56 | 0.04 | 0.41x | |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 19.450 | 13.48 | 0.11 | 1.00x | |  |
| ArithmeticComposite (non-linear) | neon64 | 512x512 | 1.194 | 219.53 | 1.76 | 16.29x | 🚀 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 762.657 | 5.50 | 0.04 | 0.41x | |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 313.100 | 13.40 | 0.11 | 1.00x | |  |
| ArithmeticComposite (non-linear) | neon64 | 2048x2048 | 17.104 | 245.22 | 1.96 | 18.31x | 🚀 |  |
| ComponentTransfer | kotlin | 512x512 | 0.939 | 279.23 | 2.23 | 1.30x | ⬆️ |  |
| ComponentTransfer | scalar | 512x512 | 1.218 | 215.19 | 1.72 | 1.00x | |  |
| ComponentTransfer | kotlin | 2048x2048 | 15.260 | 274.85 | 2.20 | 1.39x | ⬆️ | ⚠️ UNSTABLE |
| ComponentTransfer | scalar | 2048x2048 | 21.213 | 197.72 | 1.58 | 1.00x | |  |
| ConvolveMatrix | kotlin | 512x512 | 85.449 | 3.07 | 0.02 | 1.32x | ⬆️ |  |
| ConvolveMatrix | scalar | 512x512 | 112.726 | 2.33 | 0.02 | 1.00x | |  |
| ConvolveMatrix | kotlin | 2048x2048 | 1371.187 | 3.06 | 0.02 | 1.30x | ⬆️ |  |
| ConvolveMatrix | scalar | 2048x2048 | 1787.758 | 2.35 | 0.02 | 1.00x | |  |
| DisplacementMap | kotlin | 512x512 | 5.470 | 47.92 | 0.38 | 1.24x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 6.756 | 38.80 | 0.31 | 1.00x | |  |
| DisplacementMap | neon64 | 512x512 | 0.544 | 481.50 | 3.85 | 12.41x | 🚀 |  |
| DisplacementMap | kotlin | 2048x2048 | 86.973 | 48.23 | 0.39 | 1.24x | ⬆️ |  |
| DisplacementMap | scalar | 2048x2048 | 107.694 | 38.95 | 0.31 | 1.00x | |  |
| DisplacementMap | neon64 | 2048x2048 | 8.868 | 472.96 | 3.78 | 12.14x | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 12.362 | 21.21 | 0.17 | 23.62x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 291.974 | 0.90 | 0.01 | 1.00x | |  |
| GaussianBlur | neon64 | 512x512 | 5.262 | 49.82 | 0.40 | 55.49x | 🚀 |  |
| GaussianBlur | kotlin | 2048x2048 | 200.729 | 20.90 | 0.17 | 23.66x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 2048x2048 | 4749.843 | 0.88 | 0.01 | 1.00x | |  |
| GaussianBlur | neon64 | 2048x2048 | 84.117 | 49.86 | 0.40 | 56.47x | 🚀 |  |
| Lighting | kotlin | 512x512 | 66.877 | 3.92 | 0.03 | 1.23x | ⬆️ |  |
| Lighting | scalar | 512x512 | 82.113 | 3.19 | 0.03 | 1.00x | |  |
| Lighting | neon64 | 512x512 | 84.499 | 3.10 | 0.02 | 0.97x | 🔴 |  |
| Lighting | kotlin | 2048x2048 | 1108.236 | 3.78 | 0.03 | 1.18x | ⬆️ |  |
| Lighting | scalar | 2048x2048 | 1311.657 | 3.20 | 0.03 | 1.00x | |  |
| Lighting | neon64 | 2048x2048 | 1337.043 | 3.14 | 0.03 | 0.98x | 🔴 |  |
| Morphology | kotlin | 512x512 | 348.674 | 0.75 | 0.01 | 0.56x | |  |
| Morphology | scalar | 512x512 | 195.727 | 1.34 | 0.01 | 1.00x | |  |
| Morphology | neon64 | 512x512 | 2.013 | 130.25 | 1.04 | 97.25x | 🚀 |  |
| Morphology | kotlin | 2048x2048 | 6786.288 | 0.62 | 0.00 | 0.56x | |  |
| Morphology | scalar | 2048x2048 | 3803.223 | 1.10 | 0.01 | 1.00x | |  |
| Morphology | neon64 | 2048x2048 | 33.095 | 126.74 | 1.01 | 114.92x | 🚀 |  |
| Turbulence | kotlin | 512x512 | 385.910 | 0.68 | 0.01 | 0.28x | |  |
| Turbulence | scalar | 512x512 | 107.281 | 2.44 | 0.02 | 1.00x | |  |
| Turbulence | neon64 | 512x512 | 5.293 | 49.52 | 0.40 | 20.27x | 🚀 |  |
| Turbulence | kotlin | 2048x2048 | 6162.194 | 0.68 | 0.01 | 0.28x | |  |
| Turbulence | scalar | 2048x2048 | 1714.706 | 2.45 | 0.02 | 1.00x | |  |
| Turbulence | neon64 | 2048x2048 | 83.795 | 50.05 | 0.40 | 20.46x | 🚀 |  |
| UnLinearize | kotlin | 512x512 | 0.687 | 381.82 | 3.05 | 2.03x | ⬆️ |  |
| UnLinearize | scalar | 512x512 | 1.393 | 188.20 | 1.51 | 1.00x | | ⚠️ UNSTABLE |
| UnLinearize | kotlin | 2048x2048 | 7.716 | 543.60 | 4.35 | 2.37x | ⬆️ |  |
| UnLinearize | scalar | 2048x2048 | 18.311 | 229.06 | 1.83 | 1.00x | |  |

## Device Results (OnePlus 11, 32-bit ARM)

Measured on OnePlus 11 (CPH2449) running the `armeabi-v7a` (32-bit).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | kotlin | 512x512 | 88.968 | 2.95 | 0.24 | 0.36x | |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 32.329 | 8.11 | 0.06 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 512x512 | 9.600 | 27.31 | 0.22 | 3.37x | 🟢 |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 518.90 | 8.08 | 0.06 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 2048x2048 | 154.46 | 27.16 | 0.22 | 3.36x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 73.502 | 3.57 | 0.29 | 0.42x | |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 30.587 | 8.57 | 0.07 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 512x512 | 2.277 | 115.13 | 0.92 | **13.43x** | 🚀 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 486.11 | 8.63 | 0.07 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 2048x2048 | 36.73 | 114.18 | 0.91 | **13.23x** | 🚀 |  |
| ComponentTransfer | kotlin | 512x512 | 2.067 | 126.80 | 1.01 | 0.71x | | ⚠️ scalar baseline UNSTABLE |
| ComponentTransfer | scalar | 512x512 | 1.466 | 178.79 | 1.43 | 1.00x |  | ⚠️ UNSTABLE |
| ComponentTransfer | scalar | 2048x2048 | 39.247 | 106.87 | 0.86 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 181.108 | 1.45 | 0.12 | 1.06x | ⬆️ |  |
| ConvolveMatrix | scalar | 512x512 | 191.308 | 1.37 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | neon32 | 512x512 | 14.543 | 18.03 | 0.14 | **13.87x** | 🚀 |  |
| ConvolveMatrix | scalar | 2048x2048 | 2949.058 | 1.42 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | neon32 | 2048x2048 | 166.404 | 25.21 | 0.20 | **17.72x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 9.973 | 26.29 | 2.10 | 1.06x | ⬆️ |  |
| DisplacementMap | scalar | 512x512 | 10.555 | 24.84 | 0.20 | 1.00x |  |  |
| DisplacementMap | neon32 | 512x512 | 0.968 | 270.91 | 2.17 | 10.91x | 🚀 | ⚠️ UNSTABLE |
| DisplacementMap | scalar | 2048x2048 | 187.798 | 22.33 | 0.18 | 1.00x |  |  |
| DisplacementMap | neon32 | 2048x2048 | 23.020 | 182.20 | 1.46 | **8.16x** | 🚀 |  |
| GaussianBlur | kotlin | 512x512 | 26.915 | 9.74 | 0.78 | 13.81x | ⬆️ | StackBlur (approx) |
| GaussianBlur | scalar | 512x512 | 371.589 | 0.71 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 512x512 | 8.823 | 29.71 | 0.24 | **42.12x** | 🚀 |  |
| GaussianBlur | scalar | 2048x2048 | 5959.443 | 0.70 | 0.01 | 1.00x |  |  |
| GaussianBlur | neon32 | 2048x2048 | 141.507 | 29.64 | 0.24 | **42.11x** | 🚀 |  |
| Lighting | kotlin | 512x512 | 120.431 | 2.18 | 0.17 | 0.84x | |  |
| Lighting | scalar | 512x512 | 101.153 | 2.59 | 0.02 | 1.00x |  |  |
| Lighting | neon32 | 512x512 | 103.053 | 2.54 | 0.02 | 0.98x | 🔴 |  |
| Lighting | scalar | 2048x2048 | 1535.380 | 2.73 | 0.02 | 1.00x |  |  |
| Lighting | neon32 | 2048x2048 | 1554.207 | 2.70 | 0.02 | 0.99x | 🔴 |  |
| Morphology | kotlin | 512x512 | 799.654 | 0.33 | 0.03 | 0.74x | |  |
| Morphology | scalar | 512x512 | 588.373 | 0.45 | 0.00 | 1.00x |  |  |
| Morphology | neon32 | 512x512 | 3.238 | 80.95 | 0.65 | **181.70x** | 🚀 |  |
| Morphology | scalar | 2048x2048 | 6065.464 | 0.69 | 0.01 | 1.00x |  |  |
| Morphology | neon32 | 2048x2048 | 42.495 | 98.70 | 0.79 | **142.73x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 804.240 | 0.33 | 0.03 | 0.17x | |  |
| Turbulence | scalar | 512x512 | 135.210 | 1.94 | 0.02 | 1.00x |  |  |
| Turbulence | neon32 | 512x512 | 19.912 | 13.16 | 0.11 | 6.79x | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 2123.620 | 1.98 | 0.02 | 1.00x |  |  |
| Turbulence | neon32 | 2048x2048 | 317.419 | 13.21 | 0.11 | 6.69x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 1.249 | 209.90 | 1.68 | 0.71x | | ⚠️ UNSTABLE |
| UnLinearize | scalar | 512x512 | 0.883 | 296.96 | 2.38 | 1.00x |  | ⚠️ UNSTABLE |
| UnLinearize | neon32 | 512x512 | — | — | — | — | 🔴 | un-advertised in this run |
| UnLinearize | kotlin | 2048x2048 | 22.859 | 183.49 | 1.47 | 0.80x | |  |
| UnLinearize | scalar | 2048x2048 | 18.321 | 228.94 | 1.83 | 1.00x |  |  |
| UnLinearize | neon32 | 2048x2048 | — | — | — | — | 🔴 | un-advertised in this run |
