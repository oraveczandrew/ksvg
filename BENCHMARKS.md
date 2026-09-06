# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels compared to their scalar C++ counterparts.

Marker column: 🚀 very good speedup (>9x); 🟢 decent speedup; 🔴 regression (slower than the scalar baseline).

## Host Results (i7-7820X)

Measured on macOS (i7-7820X, 64-bit host build, 2026-09-06) using the `KernelPerformanceBenchmark` (host-native build).

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: |
| ArithmeticComposite (linear) | scalar | 512x512 | 0.850 | 308.39 | 2.47 | 1.00x |  |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 0.513 | 511.10 | 4.09 | 1.66x | 🟢 |
| ArithmeticComposite (linear) | avx2 | 512x512 | 0.294 | 892.53 | 7.14 | 2.89x | 🟢 |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 13.444 | 311.99 | 2.50 | 1.00x |  |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 8.453 | 496.19 | 3.97 | 1.59x | 🟢 |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 5.337 | 785.96 | 6.29 | 2.52x | 🟢 |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.819 | 319.89 | 2.56 | 1.00x |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.497 | 527.40 | 4.22 | 1.65x | 🟢 |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.279 | 940.75 | 7.53 | 2.94x | 🟢 |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.447 | 311.91 | 2.50 | 1.00x |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.503 | 493.30 | 3.95 | 1.58x | 🟢 |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.461 | 768.05 | 6.14 | 2.46x | 🟢 |
| ComponentTransfer | scalar | 512x512 | 0.348 | 752.66 | 6.02 | 1.00x |  |
| ComponentTransfer | ssse3 | 512x512 | 1.761 | 148.84 | 1.19 | 0.20x | 🔴 |
| ComponentTransfer | avx2 | 512x512 | 0.328 | 798.54 | 6.39 | 1.06x | 🟢 |
| ComponentTransfer | scalar | 2048x2048 | 6.022 | 696.54 | 5.57 | 1.00x |  |
| ComponentTransfer | ssse3 | 2048x2048 | 28.317 | 148.12 | 1.18 | 0.21x | 🔴 |
| ComponentTransfer | avx2 | 2048x2048 | 5.495 | 763.26 | 6.11 | 1.10x | 🟢 |
| ConvolveMatrix | scalar | 512x512 | 8.735 | 30.01 | 0.24 | 1.00x |  |
| ConvolveMatrix | ssse3 | 512x512 | 2.104 | 124.60 | 1.00 | 4.15x | 🟢 |
| ConvolveMatrix | avx2 | 512x512 | 1.285 | 204.02 | 1.63 | 6.80x | 🟢 |
| ConvolveMatrix | avx512 | 512x512 | 1.204 | 217.67 | 1.74 | 7.25x | 🟢 |
| ConvolveMatrix | scalar | 2048x2048 | 141.026 | 29.74 | 0.24 | 1.00x |  |
| ConvolveMatrix | ssse3 | 2048x2048 | 35.846 | 117.01 | 0.94 | 3.93x | 🟢 |
| ConvolveMatrix | avx2 | 2048x2048 | 22.161 | 189.27 | 1.51 | 6.36x | 🟢 |
| ConvolveMatrix | avx512 | 2048x2048 | 17.715 | 236.76 | 1.89 | 7.96x | 🟢 |
| DisplacementMap | scalar | 512x512 | 2.379 | 110.20 | 1.32 | 1.00x |  |
| DisplacementMap | avx2 | 512x512 | 0.817 | 320.73 | 3.85 | 2.91x | 🟢 |
| DisplacementMap | avx512 | 512x512 | 0.717 | 365.39 | 4.38 | 3.32x | 🟢 |
| DisplacementMap | scalar | 2048x2048 | 36.760 | 114.10 | 1.37 | 1.00x |  |
| DisplacementMap | avx2 | 2048x2048 | 14.150 | 296.42 | 3.56 | 2.60x | 🟢 |
| DisplacementMap | avx512 | 2048x2048 | 12.963 | 323.57 | 3.88 | 2.84x | 🟢 |
| GaussianBlur | scalar | 512x512 | 21.185 | 12.37 | 0.10 | 1.00x |  |
| GaussianBlur | ssse3 | 512x512 | 12.003 | 21.84 | 0.17 | 1.76x | 🟢 |
| GaussianBlur | avx2 | 512x512 | 10.819 | 24.23 | 0.19 | 1.96x | 🟢 |
| GaussianBlur | scalar | 2048x2048 | 338.473 | 12.39 | 0.10 | 1.00x |  |
| GaussianBlur | ssse3 | 2048x2048 | 168.316 | 24.92 | 0.20 | 2.01x | 🟢 |
| GaussianBlur | avx2 | 2048x2048 | 178.952 | 23.44 | 0.19 | 1.89x | 🟢 |
| Lighting | scalar | 512x512 | 13.247 | 19.79 | 0.16 | 1.00x |  |
| Lighting | ssse3 | 512x512 | 0.825 | 317.70 | 2.54 | **16.05x** | 🚀 |
| Lighting | avx2 | 512x512 | 0.813 | 322.57 | 2.58 | **16.30x** | 🚀 |
| Lighting | avx512 | 512x512 | 0.841 | 311.85 | 2.49 | **15.76x** | 🚀 |
| Lighting | sse2 | 512x512 | 0.897 | 292.31 | 2.34 | **14.77x** | 🚀 |
| Lighting | scalar | 2048x2048 | 209.468 | 20.02 | 0.16 | 1.00x |  |
| Lighting | ssse3 | 2048x2048 | 13.850 | 302.84 | 2.42 | **15.12x** | 🚀 |
| Lighting | avx2 | 2048x2048 | 13.829 | 303.29 | 2.43 | **15.15x** | 🚀 |
| Lighting | avx512 | 2048x2048 | 13.878 | 302.24 | 2.42 | **15.09x** | 🚀 |
| Lighting | sse2 | 2048x2048 | 14.079 | 297.91 | 2.38 | **14.88x** | 🚀 |
| Morphology | scalar | 512x512 | 24.077 | 10.89 | 0.09 | 1.00x |  |
| Morphology | ssse3 | 512x512 | 9.120 | 28.74 | 0.23 | 2.64x | 🟢 |
| Morphology | avx2 | 512x512 | 1.353 | 193.80 | 1.55 | **17.80x** | 🚀 |
| Morphology | avx512 | 512x512 | 2.155 | 121.66 | 0.97 | **11.17x** | 🚀 |
| Morphology | sse2 | 512x512 | 1.339 | 195.72 | 1.57 | **17.98x** | 🚀 |
| Morphology | scalar | 2048x2048 | 508.204 | 8.25 | 0.07 | 1.00x |  |
| Morphology | ssse3 | 2048x2048 | 168.184 | 24.94 | 0.20 | 3.02x | 🟢 |
| Morphology | avx2 | 2048x2048 | 25.416 | 165.03 | 1.32 | **20.00x** | 🚀 |
| Morphology | avx512 | 2048x2048 | 38.927 | 107.75 | 0.86 | **13.06x** | 🚀 |
| Morphology | sse2 | 2048x2048 | 25.781 | 162.69 | 1.30 | **19.71x** | 🚀 |
| Turbulence | scalar | 512x512 | 15.739 | 16.66 | 0.07 | 1.00x |  |
| Turbulence | ssse3 | 512x512 | 7.562 | 34.67 | 0.14 | 2.08x | 🟢 |
| Turbulence | avx2 | 512x512 | 6.079 | 43.12 | 0.17 | 2.59x | 🟢 |
| Turbulence | scalar | 2048x2048 | 260.597 | 16.09 | 0.06 | 1.00x |  |
| Turbulence | ssse3 | 2048x2048 | 124.115 | 33.79 | 0.14 | 2.10x | 🟢 |
| Turbulence | avx2 | 2048x2048 | 102.231 | 41.03 | 0.16 | 2.55x | 🟢 |
| UnLinearize | scalar | 512x512 | 0.302 | 867.67 | 6.94 | 1.00x |  |
| UnLinearize | ssse3 | 512x512 | 0.430 | 609.60 | 4.88 | 0.70x | 🔴 |
| UnLinearize | avx2 | 512x512 | 0.197 | 1330.95 | 10.65 | 1.53x | 🟢 |
| UnLinearize | scalar | 2048x2048 | 4.584 | 914.94 | 7.32 | 1.00x |  |
| UnLinearize | ssse3 | 2048x2048 | 6.773 | 619.25 | 4.95 | 0.68x | 🔴 |
| UnLinearize | avx2 | 2048x2048 | 3.644 | 1151.09 | 9.21 | 1.26x | 🟢 |

## Host Results (x86-32, Android emulator)

Measured on an x86 (32-bit) Android 8.0 emulator using the same `nativeBenchmark { }` harness (medians).

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
| ComponentTransfer | ssse3 | 512x512 | 53.954 | 4.86 | 0.04 | 0.03x | 🔴 | ssse3 pshufb path slower than scalar |
| ComponentTransfer | scalar | 2048x2048 | 21.847 | 191.99 | 1.54 | 1.00x |  |  |
| ComponentTransfer | ssse3 | 2048x2048 | 867.596 | 4.83 | 0.04 | 0.03x | 🔴 | ssse3 pshufb path slower than scalar |
| ConvolveMatrix | scalar | 512x512 | 99.742 | 2.63 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | ssse3 | 512x512 | 38.345 | 6.84 | 0.05 | 2.60x | 🟢 |  |
| ConvolveMatrix | scalar | 2048x2048 | 1598.571 | 2.62 | 0.02 | 1.00x |  |  |
| ConvolveMatrix | ssse3 | 2048x2048 | 603.232 | 6.95 | 0.06 | 2.65x | 🟢 |  |
| DisplacementMap | scalar | 512x512 | 7.432 | 35.27 | 0.28 | 1.00x |  | no SIMD backend on x86 |
| DisplacementMap | scalar | 2048x2048 | 117.106 | 35.82 | 0.29 | 1.00x |  | no SIMD backend on x86 |
| GaussianBlur | scalar | 512x512 | 245.435 | 1.07 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 126.926 | 2.07 | 0.02 | 1.93x | 🟢 |  |
| GaussianBlur | scalar | 2048x2048 | 4097.046 | 1.02 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 1920.226 | 2.18 | 0.02 | 2.13x | 🟢 |  |
| Lighting | scalar | 512x512 | 67.943 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.771 | 148.00 | 1.18 | **38.4x** | 🚀 | rebuilt kernel, parity-verified |
| Lighting | ssse3 | 512x512 | 1.853 | 141.51 | 1.13 | **36.7x** | 🚀 | same SSE2 kernel |
| Lighting | scalar | 2048x2048 | 1087.123 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 19.766 | 212.20 | 1.70 | **55.0x** | 🚀 | rebuilt kernel, parity-verified |
| Lighting | ssse3 | 2048x2048 | 19.510 | 214.98 | 1.72 | **55.7x** | 🚀 | same SSE2 kernel |
| Morphology | scalar | 512x512 | 156.698 | 1.67 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.520 | 172.41 | 1.38 | **103.1x** | 🚀 |  |
| Morphology | ssse3 | 512x512 | 170.287 | 1.54 | 0.01 | 0.92x | 🔴 | no x86-32 kernel; falls back to scalar |
| Morphology | scalar | 2048x2048 | 2584.828 | 1.62 | 0.01 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 24.652 | 170.14 | 1.36 | **104.9x** | 🚀 |  |
| Morphology | ssse3 | 2048x2048 | 2807.434 | 1.49 | 0.01 | 0.92x | 🔴 | no x86-32 kernel; falls back to scalar |
| Turbulence | scalar | 512x512 | 67.906 | 3.86 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 53.685 | 4.88 | 0.04 | 1.26x | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 1083.207 | 3.87 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 853.463 | 4.91 | 0.04 | 1.27x | 🟢 |  |
| UnLinearize | scalar | 512x512 | 1.170 | 224.10 | 1.79 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 12.195 | 21.50 | 0.17 | 0.10x | 🔴 | ssse3 pshufb path slower than scalar |
| UnLinearize | scalar | 2048x2048 | 13.602 | 308.35 | 2.47 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 193.809 | 21.64 | 0.17 | 0.07x | 🔴 | ssse3 pshufb path slower than scalar |

The emulator exposes only `scalar`/`sse2`/`ssse3` (AVX is gated out of runtime detection on 32-bit x86 by Android).
If a kernel row is missing a backend it is not advertised on this ABI (e.g. `Morphology` `ssse3` silently runs the scalar fallback).

## Device Results (OnePlus 11)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2) using the stable `nativeBenchmark { }` harness.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: |
| ArithmeticComposite (linear) | scalar | 512x512 | 17.470 | 15.00 | 0.12 | 1.00x |  |
| ArithmeticComposite (linear) | neon64 | 512x512 | 51.858 | 5.05 | 0.04 | 0.34x | 🔴 |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 280.386 | 14.96 | 0.12 | 1.00x |  |
| ArithmeticComposite (linear) | neon64 | 2048x2048 | 830.059 | 5.05 | 0.04 | 0.34x | 🔴 |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 16.469 | 15.92 | 0.13 | 1.00x |  |
| ArithmeticComposite (non-linear) | neon64 | 512x512 | 0.920 | 284.83 | 2.28 | **17.89x** | 🚀 |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 264.485 | 15.86 | 0.13 | 1.00x |  |
| ArithmeticComposite (non-linear) | neon64 | 2048x2048 | 13.585 | 308.75 | 2.47 | **19.47x** | 🚀 |
| ComponentTransfer | scalar | 512x512 | 2.164 | 121.15 | 0.97 | 1.00x |  |
| ComponentTransfer | neon64 | 512x512 | 26.687 | 9.82 | 0.08 | 0.08x | 🔴 |
| ComponentTransfer | scalar | 2048x2048 | 34.701 | 120.87 | 0.97 | 1.00x |  |
| ComponentTransfer | neon64 | 2048x2048 | 427.147 | 9.82 | 0.08 | 0.08x | 🔴 |
| ConvolveMatrix | scalar | 512x512 | 100.919 | 2.60 | 0.02 | 1.00x |  |
| ConvolveMatrix | neon64 | 512x512 | 5.921 | 44.27 | 0.35 | **17.04x** | 🚀 |
| ConvolveMatrix | scalar | 2048x2048 | 1589.315 | 2.64 | 0.02 | 1.00x |  |
| ConvolveMatrix | neon64 | 2048x2048 | 83.963 | 49.95 | 0.40 | **18.93x** | 🚀 |
| DisplacementMap | scalar | 512x512 | 5.705 | 45.95 | 0.37 | 1.00x |  |
| DisplacementMap | neon64 | 512x512 | 9.316 | 28.14 | 0.23 | 0.61x | 🔴 |
| DisplacementMap | scalar | 2048x2048 | 91.168 | 46.01 | 0.37 | 1.00x |  |
| DisplacementMap | neon64 | 2048x2048 | 149.828 | 27.99 | 0.22 | 0.61x | 🔴 |
| GaussianBlur | scalar | 512x512 | 245.457 | 1.07 | 0.01 | 1.00x |  |
| GaussianBlur | neon64 | 512x512 | 4.419 | 59.32 | 0.47 | **55.55x** | 🚀 |
| GaussianBlur | scalar | 2048x2048 | 4012.708 | 1.05 | 0.01 | 1.00x |  |
| GaussianBlur | neon64 | 2048x2048 | 70.647 | 59.37 | 0.47 | **56.80x** | 🚀 |
| Lighting | scalar | 512x512 | 73.112 | 3.59 | 0.03 | 1.00x |  |
| Lighting | neon64 | 512x512 | 75.391 | 3.48 | 0.03 | 0.97x | 🔴 |
| Lighting | scalar | 2048x2048 | 1162.251 | 3.61 | 0.03 | 1.00x |  |
| Lighting | neon64 | 2048x2048 | 1190.288 | 3.52 | 0.03 | 0.98x | 🔴 |
| Morphology | scalar | 512x512 | 198.905 | 1.32 | 0.01 | 1.00x |  |
| Morphology | neon64 | 512x512 | 1.968 | 133.19 | 1.07 | **101.06x** | 🚀 |
| Morphology | scalar | 2048x2048 | 3276.225 | 1.28 | 0.01 | 1.00x |  |
| Morphology | neon64 | 2048x2048 | 27.923 | 150.21 | 1.20 | **117.33x** | 🚀 |
| Turbulence | scalar | 512x512 | 90.420 | 2.90 | 0.02 | 1.00x |  |
| Turbulence | neon64 | 512x512 | 4.464 | 58.72 | 0.47 | **20.25x** | 🚀 |
| Turbulence | scalar | 2048x2048 | 1448.699 | 2.90 | 0.02 | 1.00x |  |
| Turbulence | neon64 | 2048x2048 | 70.556 | 59.45 | 0.48 | **20.53x** | 🚀 |
| UnLinearize | scalar | 512x512 | 1.100 | 238.43 | 1.91 | 1.00x |  |
| UnLinearize | neon64 | 512x512 | 24.242 | 10.81 | 0.09 | 0.05x | 🔴 |
| UnLinearize | scalar | 2048x2048 | 17.811 | 235.48 | 1.88 | 1.00x |  |
| UnLinearize | neon64 | 2048x2048 | 387.704 | 10.82 | 0.09 | 0.05x | 🔴 |

## Device Results (OnePlus 11, 32-bit ARM)

Measured on OnePlus 11 (CPH2449) running the `armeabi-v7a` (32-bit) test APK using the stable `nativeBenchmark { }` harness (medians).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | scalar | 512x512 | 32.484 | 8.07 | 0.06 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 512x512 | 149.170 | 1.76 | 0.01 | 0.22x | 🔴 |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 518.379 | 8.09 | 0.06 | 1.00x |  |  |
| ArithmeticComposite (linear) | neon32 | 2048x2048 | 2383.754 | 1.76 | 0.01 | 0.22x | 🔴 |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 30.497 | 8.60 | 0.07 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 512x512 | 1.317 | 199.08 | 1.59 | **23.16x** | 🚀 | UNSTABLE (noisy timing) |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 487.406 | 8.61 | 0.07 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | neon32 | 2048x2048 | 26.699 | 157.10 | 1.26 | **18.26x** | 🚀 |  |
| ComponentTransfer | scalar | 512x512 | 1.925 | 136.15 | 1.09 | 1.00x |  |  |
| ComponentTransfer | neon32 | 512x512 | 95.988 | 2.73 | 0.02 | 0.02x | 🔴 |  |
| ComponentTransfer | scalar | 2048x2048 | 39.247 | 106.87 | 0.86 | 1.00x |  |  |
| ComponentTransfer | neon32 | 2048x2048 | 1531.672 | 2.74 | 0.02 | 0.03x | 🔴 |  |
| ConvolveMatrix | scalar | 512x512 | 201.631 | 1.30 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | neon32 | 512x512 | 14.543 | 18.03 | 0.14 | **13.87x** | 🚀 |  |
| ConvolveMatrix | scalar | 2048x2048 | 2949.058 | 1.42 | 0.01 | 1.00x |  |  |
| ConvolveMatrix | neon32 | 2048x2048 | 166.404 | 25.21 | 0.20 | **17.72x** | 🚀 |  |
| DisplacementMap | scalar | 512x512 | 10.494 | 24.98 | 0.20 | 1.00x |  | no ARM32 SIMD kernel; scalar only; UNSTABLE (noisy timing) |
| DisplacementMap | scalar | 2048x2048 | 186.859 | 22.45 | 0.18 | 1.00x |  | no ARM32 SIMD kernel; scalar only |
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