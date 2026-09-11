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
| ArithmeticComposite (linear) | kotlin | 512x512 | 10.652 | 24.61 | 0.20 | 0.30x |  |  |
| ArithmeticComposite (linear) | scalar | 512x512 | 3.186 | 82.27 | 0.66 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.144 | 83.38 | 0.67 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.137 | 83.57 | 0.67 | 1.02x | 🟢 |  |
| ArithmeticComposite (linear) | kotlin | 2048x2048 | 170.773 | 24.56 | 0.20 | 0.30x |  |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 51.036 | 82.18 | 0.66 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 50.592 | 82.91 | 0.66 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 50.550 | 82.97 | 0.66 | 1.01x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 512x512 | 10.395 | 25.22 | 0.20 | 0.08x |  |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.853 | 307.16 | 2.46 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.487 | 538.12 | 4.30 | 1.75x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.306 | 857.21 | 6.86 | 2.79x | 🟢 |  |
| ArithmeticComposite (non-linear) | kotlin | 2048x2048 | 166.597 | 25.18 | 0.20 | 0.09x |  |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 14.390 | 291.48 | 2.33 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.127 | 516.07 | 4.13 | 1.77x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.730 | 732.04 | 5.86 | 2.51x | 🟢 |  |
| ComponentTransfer | kotlin | 512x512 | 0.568 | 461.72 | 3.69 | 0.48x |  |  |
| ComponentTransfer | scalar | 512x512 | 0.272 | 962.11 | 7.70 | 1.00x |  |  |
| ComponentTransfer | kotlin | 2048x2048 | 9.508 | 441.12 | 3.53 | 0.51x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 4.832 | 868.09 | 6.94 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 512x512 | 10.034 | 26.13 | 0.21 | 1.31x | ⬆️ | Kotlin JIT wins on 512x512 |
| ConvolveMatrix | scalar | 512x512 | 13.147 | 19.94 | 0.16 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 2.319 | 113.03 | 0.90 | 5.67x | 🟢 |  |
| ConvolveMatrix | avx2 | 512x512 | 1.257 | 208.50 | 1.67 | **10.46x** | 🚀 |  |
| ConvolveMatrix | avx512 | 512x512 | 1.384 | 189.38 | 1.52 | **9.50x** | 🚀 |  |
| ConvolveMatrix | kotlin | 2048x2048 | 164.644 | 25.48 | 0.20 | 1.28x | ⬆️ |  |
| ConvolveMatrix | scalar | 2048x2048 | 210.431 | 19.93 | 0.16 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 38.532 | 108.85 | 0.87 | 5.46x | 🟢 |  |
| ConvolveMatrix | avx2 | 2048x2048 | 19.720 | 212.69 | 1.70 | **10.67x** | 🚀 |  |
| ConvolveMatrix | avx512 | 2048x2048 | 17.691 | 237.08 | 1.90 | **11.89x** | 🚀 |  |
| DisplacementMap | kotlin | 512x512 | 3.931 | 66.69 | 0.80 | 0.59x |  |  |
| DisplacementMap | scalar | 512x512 | 2.309 | 113.53 | 1.36 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 1.033 | 253.89 | 3.05 | 2.24x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.806 | 325.23 | 3.90 | 2.86x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.748 | 350.44 | 4.21 | 3.09x | 🟢 |  |
| DisplacementMap | kotlin | 2048x2048 | 62.708 | 66.89 | 0.80 | 0.59x |  |  |
| DisplacementMap | scalar | 2048x2048 | 36.948 | 113.52 | 1.36 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 17.319 | 242.18 | 2.91 | 2.13x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 14.537 | 288.53 | 3.46 | 2.54x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 13.304 | 315.28 | 3.78 | 2.78x | 🟢 |  |
| GaussianBlur | kotlin | 512x512 | 10.415 | 25.17 | 0.20 | 1.99x | ⬆️ | StackBlur (approx) vs true Gaussian (scalar) |
| GaussianBlur | scalar | 512x512 | 20.703 | 12.66 | 0.10 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 6.438 | 40.72 | 0.33 | 3.22x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.407 | 40.92 | 0.33 | 3.23x | 🟢 |  |
| GaussianBlur | kotlin | 2048x2048 | 388.204 | 10.80 | 0.09 | 0.98x |  |  |
| GaussianBlur | scalar | 2048x2048 | 379.515 | 11.05 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 99.670 | 42.08 | 0.34 | 3.81x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 100.886 | 41.57 | 0.33 | 3.76x | 🟢 |  |
| Lighting | kotlin | 512x512 | 10.439 | 25.11 | 0.20 | 0.16x |  |  |
| Lighting | scalar | 512x512 | 1.706 | 153.62 | 1.23 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.551 | 169.02 | 1.35 | 1.10x | 🟢 |  |
| Lighting | avx2 | 512x512 | 1.191 | 220.12 | 1.76 | 1.43x | 🟢 |  |
| Lighting | avx512 | 512x512 | 1.224 | 214.11 | 1.71 | 1.39x | 🟢 |  |
| Lighting | kotlin | 2048x2048 | 170.470 | 24.60 | 0.20 | 0.17x |  |  |
| Lighting | scalar | 2048x2048 | 28.362 | 147.89 | 1.18 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 25.776 | 162.72 | 1.30 | 1.10x | 🟢 |  |
| Lighting | avx2 | 2048x2048 | 18.174 | 230.79 | 1.85 | 1.56x | 🟢 |  |
| Lighting | avx512 | 2048x2048 | 15.191 | 276.10 | 2.21 | 1.87x | 🟢 |  |
| Morphology | kotlin | 512x512 | 63.853 | 4.11 | 0.03 | 0.40x |  |  |
| Morphology | scalar | 512x512 | 25.740 | 10.18 | 0.08 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.563 | 167.71 | 1.34 | **16.47x** | 🚀 |  |
| Morphology | avx2 | 512x512 | 1.292 | 202.97 | 1.62 | **19.93x** | 🚀 |  |
| Morphology | avx512 | 512x512 | 2.249 | 116.54 | 0.93 | **11.44x** | 🚀 |  |
| Morphology | kotlin | 2048x2048 | 1001.357 | 4.19 | 0.03 | 0.52x |  |  |
| Morphology | scalar | 2048x2048 | 518.016 | 8.10 | 0.06 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 28.218 | 148.64 | 1.19 | **18.36x** | 🚀 |  |
| Morphology | avx2 | 2048x2048 | 25.195 | 166.48 | 1.33 | **20.56x** | 🚀 |  |
| Morphology | avx512 | 2048x2048 | 39.856 | 105.24 | 0.84 | **13.00x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 21.993 | 11.92 | 0.05 | 0.73x |  |  |
| Turbulence | scalar | 512x512 | 16.022 | 16.36 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 11.528 | 22.74 | 0.09 | 1.39x | 🟢 |  |
| Turbulence | avx2 | 512x512 | 7.606 | 34.47 | 0.14 | 2.11x | 🟢 |  |
| Turbulence | kotlin | 2048x2048 | 359.865 | 11.66 | 0.05 | 0.71x |  |  |
| Turbulence | scalar | 2048x2048 | 257.249 | 16.30 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 185.322 | 22.63 | 0.09 | 1.39x | 🟢 |  |
| Turbulence | avx2 | 2048x2048 | 125.050 | 33.54 | 0.13 | 2.06x | 🟢 |  |
| UnLinearize | kotlin | 512x512 | 0.412 | 635.92 | 5.09 | 0.93x |  |  |
| UnLinearize | scalar | 512x512 | 0.384 | 682.13 | 5.46 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.257 | 1018.70 | 8.15 | 1.49x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.277 | 946.83 | 7.57 | 1.39x | 🟢 |  |
| UnLinearize | kotlin | 2048x2048 | 6.579 | 637.51 | 5.10 | 0.96x |  |  |
| UnLinearize | scalar | 2048x2048 | 6.290 | 666.81 | 5.33 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 5.918 | 708.71 | 5.67 | 1.06x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 5.205 | 805.82 | 6.45 | 1.21x | 🟢 |  |

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
| ConvolveMatrix | kotlin | 512x512 | 86.054 | 3.05 | 0.02 | 1.31x | ⬆️ |  |
| ConvolveMatrix | scalar | 512x512 | 112.825 | 2.32 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | kotlin | 2048x2048 | 1379.315 | 3.04 | 0.02 | 1.30x | ⬆️ |  |
| ConvolveMatrix | scalar | 2048x2048 | 1787.947 | 2.35 | 0.02 | 1.00x |  |  |
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
| Lighting | kotlin | 512x512 | 67.062 | 3.91 | 0.03 | 0.38x |  |  |
| Lighting | scalar | 512x512 | 25.373 | 10.33 | 0.08 | 1.00x |  |  |
| Lighting | neon64 | 512x512 | 2.334 | 112.30 | 0.90 | **10.87x** | 🚀 | hand-written NEON distant diffuse |
| Lighting | kotlin | 2048x2048 | 1081.890 | 3.88 | 0.03 | 0.37x |  |  |
| Lighting | scalar | 2048x2048 | 398.610 | 10.52 | 0.08 | 1.00x |  |  |
| Lighting | neon64 | 2048x2048 | 26.793 | 156.54 | 1.25 | **14.88x** | 🚀 |  |
| Morphology | kotlin | 512x512 | 414.102 | 0.63 | 0.01 | 0.56x |  |  |
| Morphology | scalar | 512x512 | 231.044 | 1.13 | 0.01 | 1.00x |  |  |
| Morphology | neon64 | 512x512 | 2.360 | 111.07 | 0.89 | **97.89x** | 🚀 |  |
| Morphology | kotlin | 2048x2048 | 6803.022 | 0.62 | 0.00 | 0.56x |  |  |
| Morphology | scalar | 2048x2048 | 3791.461 | 1.11 | 0.01 | 1.00x |  |  |
| Morphology | neon64 | 2048x2048 | 33.099 | 126.72 | 1.01 | **114.55x** | 🚀 |  |
| Turbulence | kotlin | 512x512 | 384.776 | 0.68 | 0.00 | 0.28x |  |  |
| Turbulence | scalar | 512x512 | 107.340 | 2.44 | 0.01 | 1.00x |  |  |
| Turbulence | neon64 | 512x512 | 5.327 | 49.21 | 0.20 | **20.15x** | 🚀 |  |
| Turbulence | kotlin | 2048x2048 | 6120.077 | 0.69 | 0.00 | 0.28x |  |  |
| Turbulence | scalar | 2048x2048 | 1713.214 | 2.45 | 0.01 | 1.00x |  |  |
| Turbulence | neon64 | 2048x2048 | 84.893 | 49.41 | 0.20 | **20.18x** | 🚀 |  |
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
