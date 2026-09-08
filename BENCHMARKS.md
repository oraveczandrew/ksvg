# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels compared to their scalar C++ counterparts.

Marker column: 🚀 very good speedup (>9x); 🟢 decent speedup; 🔴 regression (slower than the scalar baseline).

**Backend row ordering (x86):** within a kernel block, rows follow the x86 ISA
superset hierarchy — each ISA builds on the previous one:
`scalar → sse2 → ssse3 → avx2 → avx512`. Keep this order when adding or
re-measuring rows (missing levels are simply absent). `scalar` is always the
baseline row first. (ARM rows: `scalar → neon32 → neon64`.)

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
| ArithmeticComposite (linear) | scalar | 512x512 | 3.075 | 85.24 | 0.68 | 1.00x |  | linear → scalar fallback on ARM/SSE |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 5.564 | 47.11 | 0.38 | 0.55x | 🔴 | un-advertised; linear LUT loss |
| ArithmeticComposite (linear) | avx2 | 512x512 | 2.853 | 91.87 | 0.73 | 1.08x | 🟢 |  |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 48.949 | 85.69 | 0.69 | 1.00x |  | linear → scalar fallback on ARM/SSE |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 89.511 | 46.86 | 0.37 | 0.55x | 🔴 | un-advertised; linear LUT loss |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 45.959 | 91.26 | 0.73 | 1.07x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.818 | 320.64 | 2.57 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.498 | 526.16 | 4.21 | 1.64x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.290 | 903.51 | 7.23 | 2.82x | 🟢 |  |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.648 | 307.31 | 2.46 | 1.00x |  |  |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.148 | 514.74 | 4.12 | 1.67x | 🟢 |  |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.223 | 803.11 | 6.42 | 2.61x | 🟢 |  |
| ComponentTransfer | scalar | 512x512 | 0.355 | 738.78 | 5.91 | 1.00x |  |  |
| ComponentTransfer | avx2 | 512x512 | 0.333 | 787.90 | 6.30 | 1.07x | 🟢 | ssse3 un-advertised (was 0.20x regression) |
| ComponentTransfer | scalar | 2048x2048 | 5.906 | 710.12 | 5.68 | 1.00x |  |  |
| ComponentTransfer | avx2 | 2048x2048 | 5.275 | 795.08 | 6.36 | 1.12x | 🟢 | ssse3 un-advertised (was 0.20x regression) |
| ConvolveMatrix | scalar | 512x512 | 12.515 | 20.95 | 0.17 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 512x512 | 2.194 | 119.48 | 0.96 | 5.70x | 🟢 |  |
| ConvolveMatrix | avx2 | 512x512 | 1.197 | 219.02 | 1.75 | **10.46x** | 🚀 |  |
| ConvolveMatrix | avx512 | 512x512 | 1.266 | 207.04 | 1.66 | **9.88x** | 🚀 |  |
| ConvolveMatrix | scalar | 2048x2048 | 201.894 | 20.77 | 0.17 | 1.00x |  |  |
| ConvolveMatrix | sse2 | 2048x2048 | 37.423 | 112.08 | 0.90 | 5.39x | 🟢 |  |
| ConvolveMatrix | avx2 | 2048x2048 | 19.159 | 218.92 | 1.75 | **10.54x** | 🚀 |  |
| ConvolveMatrix | avx512 | 2048x2048 | 17.090 | 245.43 | 1.96 | **11.81x** | 🚀 |  |
| DisplacementMap | scalar | 512x512 | 2.312 | 113.37 | 1.36 | 1.00x |  |  |
| DisplacementMap | sse2 | 512x512 | 1.010 | 259.55 | 3.11 | 2.29x | 🟢 |  |
| DisplacementMap | avx2 | 512x512 | 0.769 | 340.96 | 4.09 | 3.01x | 🟢 |  |
| DisplacementMap | avx512 | 512x512 | 0.517 | 507.44 | 6.09 | 4.48x | 🟢 |  |
| DisplacementMap | scalar | 2048x2048 | 35.956 | 116.65 | 1.40 | 1.00x |  |  |
| DisplacementMap | sse2 | 2048x2048 | 16.831 | 249.21 | 2.99 | 2.14x | 🟢 |  |
| DisplacementMap | avx2 | 2048x2048 | 14.587 | 287.53 | 3.45 | 2.46x | 🟢 |  |
| DisplacementMap | avx512 | 2048x2048 | 13.112 | 319.88 | 3.84 | 2.74x | 🟢 |  |
| GaussianBlur | scalar | 512x512 | 20.060 | 13.07 | 0.10 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 6.245 | 41.98 | 0.34 | 3.21x | 🟢 |  |
| GaussianBlur | avx2 | 512x512 | 6.039 | 43.41 | 0.35 | 3.32x | 🟢 |  |
| GaussianBlur | scalar | 2048x2048 | 360.458 | 11.64 | 0.09 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 98.641 | 42.52 | 0.34 | 3.65x | 🟢 |  |
| GaussianBlur | avx2 | 2048x2048 | 95.162 | 44.08 | 0.35 | 3.79x | 🟢 |  |
| Lighting | scalar | 512x512 | 12.935 | 20.27 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 0.838 | 312.90 | 2.50 | **15.44x** | 🚀 |  |
| Lighting | ssse3 | 512x512 | 0.798 | 328.35 | 2.63 | **16.20x** | 🚀 |  |
| Lighting | avx2 | 512x512 | 0.870 | 301.36 | 2.41 | **14.87x** | 🚀 |  |
| Lighting | avx512 | 512x512 | 0.866 | 302.59 | 2.42 | **14.93x** | 🚀 |  |
| Lighting | scalar | 2048x2048 | 205.543 | 20.41 | 0.16 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 13.168 | 318.52 | 2.55 | **15.61x** | 🚀 |  |
| Lighting | ssse3 | 2048x2048 | 13.852 | 302.79 | 2.42 | **14.84x** | 🚀 |  |
| Lighting | avx2 | 2048x2048 | 13.854 | 302.74 | 2.42 | **14.84x** | 🚀 |  |
| Lighting | avx512 | 2048x2048 | 13.388 | 313.28 | 2.51 | **15.35x** | 🚀 |  |
| Morphology | scalar | 512x512 | 23.492 | 11.16 | 0.09 | 1.00x |  |  |
| Morphology | sse2 | 512x512 | 1.297 | 202.06 | 1.62 | **18.11x** | 🚀 |  |
| Morphology | avx2 | 512x512 | 1.254 | 209.04 | 1.67 | **18.73x** | 🚀 |  |
| Morphology | avx512 | 512x512 | 2.105 | 124.51 | 1.00 | **11.16x** | 🚀 |  |
| Morphology | scalar | 2048x2048 | 495.957 | 8.46 | 0.07 | 1.00x |  |  |
| Morphology | sse2 | 2048x2048 | 24.375 | 172.07 | 1.38 | **20.35x** | 🚀 |  |
| Morphology | avx2 | 2048x2048 | 24.679 | 169.95 | 1.36 | **20.10x** | 🚀 |  |
| Morphology | avx512 | 2048x2048 | 38.816 | 108.06 | 0.86 | **12.78x** | 🚀 |  |
| Turbulence | scalar | 512x512 | 15.520 | 16.89 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 512x512 | 11.161 | 23.49 | 0.09 | 1.39x | 🟢 |  |
| Turbulence | avx2 | 512x512 | 7.245 | 36.18 | 0.14 | 2.14x | 🟢 |  |
| Turbulence | scalar | 2048x2048 | 249.062 | 16.84 | 0.07 | 1.00x |  |  |
| Turbulence | ssse3 | 2048x2048 | 179.455 | 23.37 | 0.09 | 1.39x | 🟢 |  |
| Turbulence | avx2 | 2048x2048 | 120.448 | 34.82 | 0.14 | 2.07x | 🟢 |  |
| UnLinearize | scalar | 512x512 | 0.281 | 934.13 | 7.47 | 1.00x |  |  |
| UnLinearize | ssse3 | 512x512 | 0.251 | 1045.08 | 8.36 | 1.12x | 🟢 | exact production-LUT path |
| UnLinearize | avx2 | 512x512 | 0.193 | 1359.32 | 10.87 | 1.46x | 🟢 |  |
| UnLinearize | scalar | 2048x2048 | 4.858 | 863.45 | 6.91 | 1.00x |  |  |
| UnLinearize | ssse3 | 2048x2048 | 4.271 | 982.00 | 7.86 | 1.14x | 🟢 | exact production-LUT path |
| UnLinearize | avx2 | 2048x2048 | 3.818 | 1098.53 | 8.79 | 1.27x | 🟢 |  |
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
| ConvolveMatrix | scalar | 512x512 | 98.760 | 2.66 | 0.02 | 1.00x |  | fresh i386 emulator run |
| ConvolveMatrix | sse2 | 512x512 | 4.942 | 53.18 | 0.43 | **19.98x** | 🚀 | fresh i386 SSE2 assembly run |
| ConvolveMatrix | ssse3 | 512x512 | 38.345 | 6.84 | 0.05 | 2.60x | 🟢 |  |
| ConvolveMatrix | scalar | 2048x2048 | 1573.879 | 2.67 | 0.02 | — | ⚠️ | harness-invalidated measurement; baseline not used |
| ConvolveMatrix | sse2 | 2048x2048 | 59.464 | 70.61 | 0.56 | — | 🟢 | scalar baseline invalid in this run |
| ConvolveMatrix | ssse3 | 2048x2048 | 603.232 | 6.95 | 0.06 | 2.65x | 🟢 |  |
| DisplacementMap | scalar | 512x512 | 7.745 | 33.95 | 0.27 | 1.00x |  | full i386 emulator bench |
| DisplacementMap | ssse3 | 512x512 | 0.494 | 553.52 | 4.43 | **15.68x** | 🚀 | i386 SSSE3 assembly; parity-verified |
| DisplacementMap | scalar | 2048x2048 | 119.300 | 35.15 | 0.28 | 1.00x |  | full i386 emulator bench |
| DisplacementMap | ssse3 | 2048x2048 | 7.745 | 542.29 | 4.34 | **15.40x** | 🚀 | i386 SSSE3 assembly; parity-verified |
| GaussianBlur | scalar | 512x512 | 250.787 | 1.05 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 512x512 | 11.752 | 22.31 | 0.18 | **21.34x** | 🚀 | i386 asm kernel |
| GaussianBlur | scalar | 2048x2048 | 4100.986 | 1.02 | 0.01 | 1.00x |  |  |
| GaussianBlur | ssse3 | 2048x2048 | 169.971 | 24.68 | 0.20 | **24.13x** | 🚀 | i386 asm kernel |
| Lighting | scalar | 512x512 | 67.943 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 512x512 | 1.771 | 148.00 | 1.18 | **38.4x** | 🚀 | rebuilt kernel, parity-verified |
| Lighting | ssse3 | 512x512 | 1.853 | 141.51 | 1.13 | **36.7x** | 🚀 | same SSE2 kernel |
| Lighting | scalar | 2048x2048 | 1087.123 | 3.86 | 0.03 | 1.00x |  |  |
| Lighting | sse2 | 2048x2048 | 19.766 | 212.20 | 1.70 | **55.0x** | 🚀 | rebuilt kernel, parity-verified |
| Lighting | ssse3 | 2048x2048 | 19.510 | 214.98 | 1.72 | **55.7x** | 🚀 | same SSE2 kernel |
| Morphology | scalar | 512x512 | 155.450 | 1.69 | 0.01 | 1.00x |  | fresh full i386 emulator run |
| Morphology | sse2 | 512x512 | 1.557 | 168.33 | 1.35 | **99.79x** | 🚀 | i386 SSE2 assembly; valid |
| Morphology | scalar | 2048x2048 | 2537.789 | 1.65 | 0.01 | 1.00x |  | fresh full i386 emulator run |
| Morphology | sse2 | 2048x2048 | 24.784 | 169.23 | 1.35 | **102.40x** | 🚀 | i386 SSE2 assembly; valid |
| Turbulence | scalar | 512x512 | 69.761 | 3.76 | 0.03 | 1.00x |  | fresh full i386 emulator run |
| Turbulence | ssse3 | 512x512 | 13.730 | 19.09 | 0.15 | **5.08x** | 🟢 | i386 SSSE3 assembly; parity-verified |
| Turbulence | scalar | 2048x2048 | 1113.571 | 3.77 | 0.03 | 1.00x |  | fresh full i386 emulator run |
| Turbulence | ssse3 | 2048x2048 | 218.275 | 19.22 | 0.15 | **5.10x** | 🟢 | i386 SSSE3 assembly; parity-verified |
| UnLinearize | scalar | 512x512 | 0.927 | 311.55 | 2.49 | 1.00x | 🟢 | accepted benchmark result |
| UnLinearize | ssse3 | 512x512 | 0.281 | 1090.64 | 8.72 | **3.30x** | 🟢 | accepted benchmark result |
| UnLinearize | scalar | 2048x2048 | 13.635 | 309.91 | 2.48 | 1.00x | 🟢 | accepted benchmark result |
| UnLinearize | ssse3 | 2048x2048 | 3.992 | 1057.71 | 8.46 | **3.42x** | 🟢 | accepted benchmark result |

The emulator exposes only `scalar`/`sse2`/`ssse3` (AVX is gated out of runtime detection on 32-bit x86 by Android).
If a kernel row is missing a backend it is not advertised on this ABI. Morphology exposes only scalar/SSE2/AVX2/AVX-512 on x86.

## Device Results (OnePlus 11)

Measured on OnePlus 11 (CPH2449, Snapdragon 8 Gen 2) using the stable `nativeBenchmark { }` harness (medians, fresh 2026-09-07 re-measurement after the WP1 arm32 register-aliasing fixes).

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |
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
| DisplacementMap | scalar | 512x512 | 6.765 | 38.75 | 0.31 | 1.00x |  |
| DisplacementMap | neon64 | 512x512 | 0.476 | 550.73 | 4.41 | **14.21x** | 🚀 | byte-exact NEON64 |
| DisplacementMap | scalar | 2048x2048 | 91.717 | 45.73 | 0.37 | 1.00x |  |
| DisplacementMap | neon64 | 2048x2048 | 7.502 | 559.08 | 4.47 | **12.23x** | 🚀 | byte-exact NEON64 |
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
| UnLinearize | neon64 | 2048x2048 | 387.704 | 10.82 | 0.09 | 0.05x | 🔴 |  |
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
| DisplacementMap | scalar | 512x512 | 10.580 | 24.78 | 0.20 | 1.00x |  |  |
| DisplacementMap | neon32 | 512x512 | 0.967 | 271.18 | 2.17 | **10.94x** | 🚀 | byte-exact NEON32 |  |
| DisplacementMap | scalar | 2048x2048 | 187.798 | 22.33 | 0.18 | 1.00x |  |  |
| DisplacementMap | neon32 | 2048x2048 | 23.020 | 182.20 | 1.46 | **8.16x** | 🚀 | byte-exact NEON32 |  |
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
