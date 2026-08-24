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
 * feTurbulence kernel implementing the SVG 1.1 §15.25 reference algorithm
 * (adapted from Mozilla gfx SVGTurbulenceRenderer). Writes unpremultiplied
 * ARGB ints into the clip region of [apply]'s pixels array; everything outside
 * becomes transparent black.
 *
 * Stateless: lattice tables are rebuilt per call on the native stack; no
 * shared/global state. Availability follows `libksvgblur`
 * ([NativeGaussianBlur.isAvailable]).
 */
public object TurbulenceNative {

    @JvmField
    public val isAvailable: Boolean = NativeGaussianBlur.isAvailable

    @JvmStatic
    public external fun apply(
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
    )
}
