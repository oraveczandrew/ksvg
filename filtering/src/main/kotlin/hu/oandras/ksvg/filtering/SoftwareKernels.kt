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
        tableA: ByteArray,
        tableR: ByteArray,
        tableG: ByteArray,
        tableB: ByteArray,
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
        lightType: Int,
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
        KotlinKernels.arithmeticComposite(
            inputPixels, in2Pixels, outPixels, width,
            clipLeft, clipTop, clipRight, clipBottom,
            k1, k2, k3, k4, useLinear,
        )
    }
}
