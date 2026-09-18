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
 * feDiffuseLighting / feSpecularLighting kernel over unpremultiplied
 * ARGB_8888 IntArrays — near-exact port of the Kotlin reference loop in
 * `FilterLighting.kt` (3x3 Sobel surface gradient from the alpha heightmap,
 * distant/point/spot light vectors incl. cone attenuation, specular via
 * double pow). Diffuse is byte-for-byte; specular allows ±1 LSB
 * (`maxDelta = 1` in the parity test) due to libm pow rounding.
 *
 * params packing: distant → [azimuthDeg, elevationDeg];
 * point → [x, y, z]; spot → [x, y, z, pointsAtX, pointsAtY, pointsAtZ,
 * limitingConeAngleDeg] (NaN = no cone).
 *
 * Stateless: caller-owned pixel arrays, no shared state. Availability follows
 * `libksvgblur` ([NativeBackend.isAvailable]).
 */
internal object LightingNative {

    @JvmField
    val isAvailable: Boolean = NativeBackend.isAvailable

    @JvmStatic
    external fun apply(
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
    )

    /**
     * Validation/test-only twin of [apply]. Runs an explicitly selected backend
     * regardless of normal CPU dispatch.
     */
    @JvmStatic
    @Suppress("LongParameterList")
    external fun applyForced(
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
        simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    external fun nativeBackend(): Int
}
