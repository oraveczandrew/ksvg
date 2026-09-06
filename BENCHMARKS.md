# KSVG Filter Kernel Benchmarks

This document records the performance of native SIMD kernels compared to their scalar C++ counterparts.

## Host Results (i7-7820X)

Measured on macOS using the `KernelPerformanceBenchmark` (host-native build).

| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: |
| UnLinearize | scalar | 512x512 | 0.284 | 923.17 | 7.39 | 1.00x |
| UnLinearize | ssse3 | 512x512 | 0.414 | 632.50 | 5.06 | 0.69x |
| UnLinearize | avx2 | 512x512 | 0.185 | 1416.66 | 11.33 | 1.53x |
| UnLinearize | scalar | 2048x2048 | 4.735 | 885.76 | 7.09 | 1.00x |
| UnLinearize | ssse3 | 2048x2048 | 6.543 | 641.02 | 5.13 | 0.72x |
| UnLinearize | avx2 | 2048x2048 | 3.635 | 1153.72 | 9.23 | 1.30x |
| ComponentTransfer | scalar | 512x512 | 0.351 | 746.08 | 5.97 | 1.00x |
| ComponentTransfer | ssse3 | 512x512 | 1.762 | 148.78 | 1.19 | 0.20x |
| ComponentTransfer | avx2 | 512x512 | 0.333 | 786.16 | 6.29 | 1.05x |
| ComponentTransfer | scalar | 2048x2048 | 6.111 | 686.40 | 5.49 | 1.00x |
| ComponentTransfer | ssse3 | 2048x2048 | 28.031 | 149.63 | 1.20 | 0.22x |
| ComponentTransfer | avx2 | 2048x2048 | 5.371 | 780.95 | 6.25 | 1.14x |
| Morphology | scalar | 512x512 | 23.554 | 11.13 | 0.09 | 1.00x |
| Morphology | ssse3 | 512x512 | 9.065 | 28.92 | 0.23 | 2.60x |
| Morphology | avx2 | 512x512 | 1.264 | 207.38 | 1.66 | **18.63x** |
| Morphology | avx512 | 512x512 | 2.085 | 125.70 | 1.01 | 11.29x |
| Morphology | sse2 | 512x512 | 1.302 | 201.32 | 1.61 | **18.09x** |
| Morphology | scalar | 2048x2048 | 496.525 | 8.45 | 0.07 | 1.00x |
| Morphology | ssse3 | 2048x2048 | 161.180 | 26.02 | 0.21 | 3.08x |
| Morphology | avx2 | 2048x2048 | 26.667 | 157.28 | 1.26 | **18.62x** |
| Morphology | avx512 | 2048x2048 | 38.559 | 108.78 | 0.87 | 12.88x |
| Morphology | sse2 | 2048x2048 | 23.915 | 175.38 | 1.40 | **20.76x** |
| ArithmeticComposite (non-linear) | scalar | 512x512 | 0.829 | 316.04 | 2.53 | 1.00x |
| ArithmeticComposite (non-linear) | ssse3 | 512x512 | 0.504 | 519.75 | 4.16 | 1.64x |
| ArithmeticComposite (non-linear) | avx2 | 512x512 | 0.276 | 950.16 | 7.60 | 3.01x |
| ArithmeticComposite (non-linear) | scalar | 2048x2048 | 13.359 | 313.96 | 2.51 | 1.00x |
| ArithmeticComposite (non-linear) | ssse3 | 2048x2048 | 8.559 | 490.05 | 3.92 | 1.56x |
| ArithmeticComposite (non-linear) | avx2 | 2048x2048 | 5.396 | 777.28 | 6.22 | 2.48x |
| ArithmeticComposite (linear) | scalar | 512x512 | 0.834 | 314.48 | 2.52 | 1.00x |
| ArithmeticComposite (linear) | ssse3 | 512x512 | 0.487 | 537.78 | 4.30 | 1.71x |
| ArithmeticComposite (linear) | avx2 | 512x512 | 0.280 | 935.57 | 7.48 | 2.97x |
| ArithmeticComposite (linear) | scalar | 2048x2048 | 13.486 | 311.01 | 2.49 | 1.00x |
| ArithmeticComposite (linear) | ssse3 | 2048x2048 | 8.303 | 505.13 | 4.04 | 1.62x |
| ArithmeticComposite (linear) | avx2 | 2048x2048 | 5.286 | 793.53 | 6.35 | 2.55x |
| ConvolveMatrix | scalar | 512x512 | 8.675 | 30.22 | 0.24 | 1.00x |
| ConvolveMatrix | ssse3 | 512x512 | 2.024 | 129.53 | 1.04 | 4.29x |
| ConvolveMatrix | avx2 | 512x512 | 1.255 | 208.81 | 1.67 | 6.91x |
| ConvolveMatrix | avx512 | 512x512 | 1.178 | 222.49 | 1.78 | 7.36x |
| ConvolveMatrix | scalar | 2048x2048 | 140.783 | 29.79 | 0.24 | 1.00x |
| ConvolveMatrix | ssse3 | 2048x2048 | 34.763 | 120.65 | 0.97 | 4.05x |
| ConvolveMatrix | avx2 | 2048x2048 | 21.749 | 192.85 | 1.54 | 6.47x |
| ConvolveMatrix | avx512 | 2048x2048 | 17.672 | 237.35 | 1.90 | 7.97x |
| DisplacementMap | scalar | 512x512 | 2.219 | 118.12 | 1.42 | 1.00x |
| DisplacementMap | avx2 | 512x512 | 0.740 | 354.09 | 4.25 | 3.00x |
| DisplacementMap | avx512 | 512x512 | 0.666 | 393.69 | 4.72 | 3.33x |
| DisplacementMap | scalar | 2048x2048 | 36.024 | 116.43 | 1.40 | 1.00x |
| DisplacementMap | avx2 | 2048x2048 | 14.038 | 298.77 | 3.59 | 2.57x |
| DisplacementMap | avx512 | 2048x2048 | 13.107 | 320.01 | 3.84 | 2.75x |
| Lighting | scalar | 512x512 | 7.399 | 35.43 | 0.28 | 1.00x |
| Lighting | ssse3 | 512x512 | 11.848 | 22.12 | 0.18 | 0.62x |
| Lighting | avx2 | 512x512 | 12.180 | 21.52 | 0.17 | 0.61x |
| Lighting | avx512 | 512x512 | 11.880 | 22.07 | 0.18 | 0.62x |
| Lighting | sse2 | 512x512 | 11.814 | 22.19 | 0.18 | 0.63x |
| Lighting | scalar | 2048x2048 | 119.766 | 35.02 | 0.28 | 1.00x |
| Lighting | ssse3 | 2048x2048 | 193.058 | 21.73 | 0.17 | 0.62x |
| Lighting | avx2 | 2048x2048 | 196.664 | 21.33 | 0.17 | 0.61x |
| Lighting | avx512 | 2048x2048 | 192.587 | 21.78 | 0.17 | 0.62x |
| Lighting | sse2 | 2048x2048 | 193.373 | 21.69 | 0.17 | 0.62x |
| Turbulence | scalar | 512x512 | 15.478 | 16.94 | 0.07 | 1.00x |
| Turbulence | ssse3 | 512x512 | 7.456 | 35.16 | 0.14 | 2.08x |
| Turbulence | avx2 | 512x512 | 5.988 | 43.78 | 0.18 | 2.58x |
| Turbulence | scalar | 2048x2048 | 251.152 | 16.70 | 0.07 | 1.00x |
| Turbulence | ssse3 | 2048x2048 | 121.076 | 34.64 | 0.14 | 2.07x |
| Turbulence | avx2 | 2048x2048 | 98.447 | 42.60 | 0.17 | 2.55x |
| GaussianBlur | scalar | 512x512 | 19.365 | 13.54 | 0.11 | 1.00x |
| GaussianBlur | ssse3 | 512x512 | 13.260 | 19.77 | 0.16 | 1.46x |
| GaussianBlur | avx2 | 512x512 | 11.258 | 23.29 | 0.19 | 1.72x |
| GaussianBlur | scalar | 2048x2048 | 323.643 | 12.96 | 0.10 | 1.00x |
| GaussianBlur | ssse3 | 2048x2048 | 165.283 | 25.38 | 0.20 | 1.96x |
| GaussianBlur | avx2 | 2048x2048 | 183.952 | 22.80 | 0.18 | 1.76x |

## Device Results (Snapdragon 8 Gen 2)

Measured on OnePlus 12 using the stable `nativeBenchmark { }` harness.

| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup |
| :--- | :--- | :---: | ---: | ---: | ---: | ---: |
| Unlinearize | scalar | 512x512 | 1.282 | 204.53 | 1.64 | 1.00x |
| Unlinearize | neon64 | 512x512 | 33.992 | 7.71 | 0.06 | 0.04x |
| ComponentTransfer | scalar | 512x512 | 2.848 | 92.05 | 0.74 | 1.00x |
| ComponentTransfer | neon64 | 512x512 | 39.201 | 6.69 | 0.05 | 0.07x |
| Morphology | scalar | 512x512 | 200.232 | 1.31 | 0.01 | 1.00x |
| Morphology | neon64 | 512x512 | 15.979 | 16.41 | 0.13 | **12.5x** |
| Morphology | scalar | 2048x2048 | 3295.601 | 1.27 | 0.01 | 1.00x |
| Morphology | neon64 | 2048x2048 | 224.114 | 18.72 | 0.15 | **14.7x** |
| ConvolveMatrix | scalar | 512x512 | 90.549 | 2.90 | 0.02 | 1.00x |
| ConvolveMatrix | neon64 | 512x512 | 9.580 | 27.36 | 0.22 | **9.45x** |
| DisplacementMap | scalar | 512x512 | 8.261 | 31.73 | 0.38 | 1.00x |
| DisplacementMap | neon64 | 512x512 | 13.300 | 19.71 | 0.24 | 0.62x |
| GaussianBlur | scalar | 512x512 | 357.167 | 0.73 | 0.01 | 1.00x |
| GaussianBlur | neon64 | 512x512 | 6.398 | 40.97 | 0.33 | **55.83x** |
| Turbulence | scalar | 512x512 | 131.544 | 1.99 | 0.01 | 1.00x |
