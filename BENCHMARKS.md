# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels compared to their scalar C++ counterparts.

Marker column: 🚀 very good speedup (>9x); 🟢 decent speedup; 🔴 regression (slower than the scalar baseline).

**Backend row ordering (x86):** within a kernel block, rows follow the x86 ISA
superset hierarchy — each ISA builds on the previous one:
`scalar → sse2 → ssse3 → avx2 → avx512`. Keep this order when adding or
re-measuring rows (missing levels are simply absent). `scalar` is always the
baseline row first. (ARM rows: `scalar → neon32 → neon64`.)
Kernel rows are ordered alphabetically by kernel name; within each kernel, sizes are ordered from 512x512 to 2048x2048.

## Host Results (i7-7820X)

Measured on macOS (i7-7820X, 64-bit host build); full-suite run 2026-09-08.

> **WP3 gate (2026-09-07):** ComponentTransfer no longer advertises SSSE3 (losing
> path); UnLinearize keeps its exact production-LUT SSSE3 backend because the refreshed
> benchmark is faster than scalar. `nativeBackend()` = scalar + SSSE3 + AVX2 for
> UnLinearize, while ComponentTransfer remains scalar + AVX2.
> ArithmeticComposite keeps its advertised SSE/NEON backends (the non-linear formula asm
> wins big) but routes the **linear** mode to scalar on ARM / SSE, and to AVX2 where
> available. The linear rows below are measured from `applyForced` (true kernel numbers) —
> rows marked *un-advertised* document why a backend was gated out.
>
> **Benchmark bug fixed 2026-09-07:** the previous "ArithmeticComposite (linear)" rows were
> actually non-linear measurements (`KernelPerformanceBenchmark` passed `useLinear=false`).

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
| ArithmeticComposite (linear) | scalar | 512x512 | 3.179 | 82.45 | 0.66 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 3.146 | 83.32 | 0.67 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 512x512 | 3.105 | 84.43 | 0.68 | 1.02x | 🟢 |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 50.961 | 82.30 | 0.66 | 1.00x |  | linear → scalar fallback on all SIMD backends |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 50.209 | 83.54 | 0.67 | 1.01x | 🟢 |  |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 50.173 | 83.60 | 0.67 | 1.02x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.859 | 305.17 | 2.44 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.499 | 525.65 | 4.21 | 1.72x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.315 | 832.47 | 6.66 | 2.73x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 14.114 | 297.18 | 2.38 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.086 | 518.72 | 4.15 | 1.75x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.690 | 737.08 | 5.90 | 2.48x | 🟢 |  |
| ComponentTransfer | scalar | 512x512 | 0.350 | 749.06 | 5.99 | 1.00x |  |  |
| ComponentTransfer | scalar | 2048x2048 | 6.110 | 686.49 | 5.49 | 1.00x |  |  |
| ConvolveMatrix | scalar | 512x512 | 12.710 | 20.63 | 0.17 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 2.201 | 119.12 | 0.95 | 5.78x | 🟢 |  |
| ConvolveMatrix | avx2 | 512x512 | 1.201 | 218.32 | 1.75 | **10.58x** | 🚀 |  |
| ConvolveMatrix | avx512 | 512x512 | 1.307 | 200.53 | 1.60 | **9.72x** | 🚀 |  |
| ConvolveMatrix | scalar | 2048x2048 | 201.881 | 20.78 | 0.17 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 37.006 | 113.34 | 0.91 | 5.46x | 🟢 |  |
| ConvolveMatrix | avx2 | 2048x2048 | 19.829 | 211.53 | 1.69 | **10.18x** | 🚀 |  |
| ConvolveMatrix | avx512 | 2048x2048 | 16.997 | 246.76 | 1.97 | **11.88x** | 🚀 |  |
| DisplacementMap | scalar | 512x512 | 2.339 | 112.09 | 1.35 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 0.972 | 269.72 | 3.24 | 2.41x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.786 | 333.63 | 4.00 | 2.98x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.597 | 439.20 | 5.27 | 3.92x | 🟢 |  |
| DisplacementMap | scalar | 2048x2048 | 35.891 | 116.86 | 1.40 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 16.677 | 251.50 | 3.02 | 2.15x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 15.066 | 278.39 | 3.34 | 2.38x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 13.048 | 321.46 | 3.86 | 2.75x | 🟢 |  |
| GaussianBlur | scalar | 512x512 | 19.921 | 13.16 | 0.11 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 6.213 | 42.20 | 0.34 | 3.21x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.123 | 42.82 | 0.34 | 3.25x | 🟢 |  |
| GaussianBlur | scalar | 2048x2048 | 359.959 | 11.65 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 96.724 | 43.36 | 0.35 | 3.72x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 94.774 | 44.26 | 0.35 | 3.80x | 🟢 |  |
| Lighting | scalar | 512x512 | 13.621 | 19.25 | 0.15 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.496 | 175.29 | 1.40 | **9.11x** | 🚀 |  |
| Lighting | avx2 | 512x512 | 1.161 | 225.75 | 1.81 | **11.73x** | 🚀 |  |
| Lighting | avx512 | 512x512 | 1.184 | 221.48 | 1.77 | **11.51x** | 🚀 |  |
| Lighting | scalar | 2048x2048 | 214.983 | 19.51 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 25.379 | 165.27 | 1.32 | 8.47x | 🟢 |  |
| Lighting | avx2 | 2048x2048 | 17.970 | 233.40 | 1.87 | **11.96x** | 🚀 |  |
| Lighting | avx512 | 2048x2048 | 15.453 | 271.42 | 2.17 | **13.91x** | 🚀 |  |
| Morphology | scalar | 512x512 | 23.872 | 10.98 | 0.09 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.323 | 198.14 | 1.59 | **18.04x** | 🚀 |  |
| Morphology | avx2 | 512x512 | 1.254 | 209.07 | 1.67 | **19.04x** | 🚀 |  |
| Morphology | avx512 | 512x512 | 2.163 | 121.18 | 0.97 | **11.04x** | 🚀 |  |
| Morphology | scalar | 2048x2048 | 499.261 | 8.40 | 0.07 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 24.340 | 172.32 | 1.38 | **20.51x** | 🚀 |  |
| Morphology | avx2 | 2048x2048 | 24.339 | 172.33 | 1.38 | **20.51x** | 🚀 |  |
| Morphology | avx512 | 2048x2048 | 38.556 | 108.78 | 0.87 | **12.95x** | 🚀 |  |
| Turbulence | scalar | 512x512 | 15.466 | 16.95 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 11.179 | 23.45 | 0.09 | 1.38x | 🟢 |  |
| Turbulence | avx2 | 512x512 | 7.251 | 36.15 | 0.14 | 2.13x | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 250.909 | 16.72 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 179.375 | 23.38 | 0.09 | 1.40x | 🟢 |  |
| Turbulence | avx2 | 2048x2048 | 120.001 | 34.95 | 0.14 | 2.09x | 🟢 |  |
| UnLinearize | scalar | 512x512 | 0.278 | 944.57 | 7.56 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.253 | 1035.23 | 8.28 | 1.10x | 🟢 |  |
| UnLinearize | avx2 | 512x512 | 0.264 | 994.29 | 7.95 | 1.05x | 🟢 |  |
| UnLinearize | scalar | 2048x2048 | 4.682 | 895.91 | 7.17 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.252 | 986.42 | 7.89 | 1.10x | 🟢 |  |
| UnLinearize | avx2 | 2048x2048 | 4.488 | 934.62 | 7.48 | 1.04x | 🟢 |  |
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
| Turbulence | scalar | 2048x2048 | 1113.571 | 3.77 | 0.03 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 218.275 | 19.22 | 0.15 | **5.10x** | 🟢 |  |
| UnLinearize | scalar | 512x512 | 0.927 | 311.55 | 2.49 | 1.00x | 🟢 |  |
| UnLinearize | ssse3 | 512x512 | 0.281 | 1090.64 | 8.72 | **3.30x** | 🟢 |  |
| UnLinearize | scalar | 2048x2048 | 13.635 | 309.91 | 2.48 | 1.00x | 🟢 |  |
| UnLinearize | ssse3 | 2048x2048 | 3.992 | 1057.71 | 8.46 | **3.42x** | 🟢 |  |

The emulator exposes only `scalar`/`sse2`/`ssse3` (AVX is gated out of runtime detection on 32-bit x86 by Android).
If a kernel row is missing a backend it is not advertised on this ABI. Morphology exposes only scalar/SSE2/AVX2/AVX-512 on x86.

## Device Results (OnePlus 11)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2) using the stable `nativeBenchmark { }` harness (medians, fresh 2026-09-09 re-measurement after fixing and verifying ArithmeticComposite clobbering bug).

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
| ComponentTransfer | neon64 | 512x512 | — | — | — | — | 🔴 | un-advertised (was 0.08x regression) |
| ComponentTransfer | scalar | 2048x2048 | 21.16 | 198.26 | 1.59 | 1.00x |  |  |
| ComponentTransfer | neon64 | 2048x2048 | — | — | — | — | 🔴 | un-advertised (was 0.08x regression) |
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

Measured on OnePlus 11 (CPH2449) running the `armeabi-v7a` (32-bit) test APK using the stable `nativeBenchmark { }` harness (medians).

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
| ComponentTransfer | neon32 | 512x512 | 95.988 | 2.73 | 0.02 | 0.02x | 🔴 |  |
| ComponentTransfer | scalar | 2048x2048 | 39.247 | 106.87 | 0.86 | 1.00x |  |  |
| ComponentTransfer | neon32 | 2048x2048 | 1531.672 | 2.74 | 0.02 | 0.03x | 🔴 |  |
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
