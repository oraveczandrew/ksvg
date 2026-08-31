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
 * feComposite operator="arithmetic" kernel over unpremultiplied ARGB_8888.
 *
 * result = clamp(k1 * in1 * in2 + k2 * in1 + k3 * in2 + k4)
 *
 * Stateless and availability follows `libksvgblur` ([NativeGaussianBlur.isAvailable]).
 */
internal object ArithmeticCompositeNative {

    @JvmField
    val isAvailable: Boolean = NativeGaussianBlur.isAvailable

    @JvmStatic
    external fun apply(
        src1: IntArray,
        src2: IntArray,
        dst: IntArray,
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
    )
}
