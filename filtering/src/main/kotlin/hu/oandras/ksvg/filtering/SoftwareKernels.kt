/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.filtering

/**
 * Unified software-kernel dispatch for filter primitives.
 *
 * Each method routes to the native C++ backend (when `libksvgblur` is loaded)
 * or to the pure-Kotlin reference implementation in [KotlinKernels].
 * Callers in `:ksvg` never branch on native availability — the choice is
 * encapsulated here.
 *
 * Stateless and allocation-free: all pixel/kernel arrays are caller-owned.
 */
public object SoftwareKernels {

    /**
     * The error encountered while loading the native filter library, or null if
     * loaded successfully or not yet attempted.
     */
    @JvmStatic
    public val nativeLoadError: RuntimeException?
        get() = NativeBackend.loadError

    /**
     * True if the native filter library (libksvgblur) is loaded and available.
     */
    @JvmStatic
    public val isNativeAvailable: Boolean
        get() = NativeBackend.isAvailable

    /**
     * Supported SIMD execution sets on this device (e.g. "Scalar, SSSE3, AVX2"
     * or "Scalar, NEON64"), reported by a kernel-independent native function.
     * This is device *capability*, not the dispatched backend: production
     * dispatch is per-kernel and may still fall back to scalar, and x86_64
     * implies the SSE2 baseline without a dedicated flag bit. "None" when the
     * native library failed to load (see [nativeLoadError]).
     */
    @JvmStatic
    public val supportedSimdBackends: String
        get() {
            if (!isNativeAvailable) {
                return "None"
            }
            val mask = NativeBackend.supportedBackendsMask()
            val names = ArrayList<String>(6)
            if (mask and SIMD_SCALAR != 0) names.add(backendName(SIMD_SCALAR))
            if (mask and SIMD_SSSE3 != 0) names.add(backendName(SIMD_SSSE3))
            if (mask and SIMD_AVX2 != 0) names.add(backendName(SIMD_AVX2))
            if (mask and SIMD_NEON64 != 0) names.add(backendName(SIMD_NEON64))
            if (mask and SIMD_NEON32 != 0) names.add(backendName(SIMD_NEON32))
            if (mask and SIMD_SSE2 != 0) names.add(backendName(SIMD_SSE2))
            val known = SIMD_SCALAR or SIMD_SSSE3 or SIMD_AVX2 or SIMD_NEON64 or SIMD_NEON32 or SIMD_SSE2
            val unknown = mask and known.inv()
            if (unknown != 0) {
                names.add("unknown(0x" + unknown.toString(16) + ")")
            }
            if (names.isEmpty()) {
                names.add("none(0x" + mask.toString(16) + ")")
            }
            return names.joinToString()
        }

    // ----------------------------------------------------------- feConvolveMatrix

    @JvmStatic
    public fun convolveMatrix(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        kernel: FloatArray,
        orderX: Int,
        orderY: Int,
        targetX: Int,
        targetY: Int,
        divisor: Float,
        bias: Float,
        preserveAlpha: Boolean,
        edgeMode: Int,
    ) {
        // In-place convolution is unsupported: interior taps read rows the kernel
        // already overwrote (audit: convolve aliasing contract gap).
        require(src !== dst) { "convolveMatrix src and dst must not alias" }
        if (ConvolveNative.isAvailable) {
            ConvolveNative.apply(
                src, dst, width, height, kernel, orderX, orderY, targetX, targetY,
                divisor, bias, preserveAlpha, edgeMode,
            )
        } else {
            KotlinKernels.convolveMatrix(
                src, dst, width, height, kernel, orderX, orderY, targetX, targetY,
                divisor, bias, preserveAlpha, edgeMode,
            )
        }
    }

    // -------------------------------------------------------------- feMorphology

    @JvmStatic
    public fun morphology(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        radiusX: Int,
        radiusY: Int,
        erode: Boolean,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
    ) {
        if (MorphologyNative.isAvailable) {
            MorphologyNative.apply(
                src, dst, width, height, radiusX, radiusY, erode,
                clipLeft, clipTop, clipRight, clipBottom,
            )
        } else {
            KotlinKernels.morphology(
                src, dst, width, height, radiusX, radiusY, erode,
                clipLeft, clipTop, clipRight, clipBottom,
            )
        }
    }

    // -------------------------------------------------------- feComponentTransfer

    @JvmStatic
    public fun componentTransfer(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        tableA: IntArray,
        tableR: IntArray,
        tableG: IntArray,
        tableB: IntArray,
    ) {
        if (ComponentTransferNative.isAvailable) {
            ComponentTransferNative.apply(
                src, dst, width, height, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB,
            )
        } else {
            KotlinKernels.componentTransfer(
                src, dst, width, clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB,
            )
        }
    }

    // ------------------------------------------------------------- unlinearize

    @JvmStatic
    public fun unLinearize(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
    ) {
        if (UnLinearizeNative.isAvailable) {
            UnLinearizeNative.apply(src, dst, width, height)
        } else {
            KotlinKernels.unLinearize(src, dst, width, height)
        }
    }

    // ---------------------------------------------------- feDiffuse / feSpecular

    @JvmStatic
    public fun lighting(
        pix: IntArray,
        out: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        surfaceScaleNormalized: Float,
        invCanvasScaleX: Double,
        invCanvasScaleY: Double,
        userLeft: Double,
        userTop: Double,
        originX: Double,
        originY: Double,
        unitSizeX: Double,
        unitSizeY: Double,
        canvasScaleX: Float,
        canvasScaleY: Float,
        @LightType lightType: Int,
        specular: Boolean,
        k: Float,
        exponent: Float,
        lightR: Int,
        lightG: Int,
        lightB: Int,
        params: DoubleArray,
        premultipliedOutput: Boolean,
        useLinear: Boolean,
    ) {
        if (LightingNative.isAvailable) {
            LightingNative.apply(
                pix, out, width, height, clipLeft, clipTop, clipRight, clipBottom,
                surfaceScaleNormalized, invCanvasScaleX, invCanvasScaleY,
                userLeft, userTop, originX, originY, unitSizeX, unitSizeY,
                canvasScaleX, canvasScaleY, lightType, specular, k, exponent,
                lightR, lightG, lightB, params, premultipliedOutput, useLinear,
            )
        } else {
            KotlinKernels.lighting(
                pix, out, width, height, clipLeft, clipTop, clipRight, clipBottom,
                surfaceScaleNormalized, invCanvasScaleX, invCanvasScaleY,
                userLeft, userTop, originX, originY, unitSizeX, unitSizeY,
                canvasScaleX, canvasScaleY, lightType, specular, k, exponent,
                lightR, lightG, lightB, params, premultipliedOutput, useLinear,
            )
        }
    }

    // -------------------------------------------------- feComposite arithmetic

    @JvmStatic
    public fun arithmeticComposite(
        inputPixels: IntArray,
        in2Pixels: IntArray,
        outPixels: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        k1: Float,
        k2: Float,
        k3: Float,
        k4: Float,
        useLinear: Boolean,
    ) {
        if (ArithmeticCompositeNative.isAvailable) {
            ArithmeticCompositeNative.apply(
                inputPixels, in2Pixels, outPixels, width,
                clipLeft, clipTop, clipRight, clipBottom,
                k1, k2, k3, k4, useLinear
            )
        } else {
            KotlinKernels.arithmeticComposite(
                inputPixels, in2Pixels, outPixels, width,
                clipLeft, clipTop, clipRight, clipBottom,
                k1, k2, k3, k4, useLinear,
            )
        }
    }

    // -------------------------------------------------------- displacement map

    @JvmStatic
    public fun displacementMap(
        src: IntArray,
        map: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        mapWidth: Int,
        mapHeight: Int,
        scale: Float,
        xChannel: Int,
        yChannel: Int,
    ) {
        if (DisplacementMapNative.isAvailable) {
            DisplacementMapNative.apply(
                src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel
            )
        } else {
            KotlinKernels.displacementMap(
                src, map, dst, width, height, mapWidth, mapHeight, scale, xChannel, yChannel
            )
        }
    }

    // --------------------------------------------------------------- feTurbulence

    @JvmStatic
    public fun turbulence(
        pixels: IntArray,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        baseFrequencyX: Double,
        baseFrequencyY: Double,
        periodX: Int,
        periodY: Int,
        octaves: Int,
        fractalNoise: Boolean,
        invCanvasScaleX: Double,
        invCanvasScaleY: Double,
        userLeft: Double,
        userTop: Double,
        originX: Double,
        originY: Double,
        unitSizeX: Double,
        unitSizeY: Double,
        seed: Int,
        generators: Array<SvgPathNoise>,
    ) {
        if (TurbulenceNative.isAvailable) {
            TurbulenceNative.apply(
                pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
                unitSizeX, unitSizeY, seed,
            )
        } else {
            KotlinKernels.turbulence(
                pixels, width, height, clipLeft, clipTop, clipRight, clipBottom,
                baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
                invCanvasScaleX, invCanvasScaleY, userLeft, userTop,
                unitSizeX, unitSizeY, seed, generators,
            )
        }
    }
}
