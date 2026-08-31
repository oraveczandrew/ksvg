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
 * ARGB_8888 IntArrays — bit-exact port of the Kotlin reference loop in
 * `FilterLighting.kt` (3x3 Sobel surface gradient from the alpha heightmap,
 * distant/point/spot light vectors incl. cone attenuation, specular via
 * double pow).
 *
 * params packing: distant → [azimuthDeg, elevationDeg];
 * point → [x, y, z]; spot → [x, y, z, pointsAtX, pointsAtY, pointsAtZ,
 * limitingConeAngleDeg] (NaN = no cone).
 *
 * Stateless: caller-owned pixel arrays, no shared state. Availability follows
 * `libksvgblur` ([NativeGaussianBlur.isAvailable]).
 */
public object LightingNative {

    @JvmField
    public val isAvailable: Boolean = NativeGaussianBlur.isAvailable

    @JvmStatic
    public external fun apply(
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
        // When true (feSpecularLighting as terminal output), emit premultiplied
        // (lightColor, intensity) to match cairo; otherwise straight.
        premultipliedOutput: Boolean,
        // When true (color-interpolation-filters: linearRGB), gamma-correct the
        // straight RGB output from linear to sRGB (premultiplied terminal unchanged).
        useLinear: Boolean,
    )
}
