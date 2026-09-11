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
 * Stateless and availability follows `libksvgblur` ([NativeBackend.isAvailable]).
 */
internal object ArithmeticCompositeNative {

    @JvmField
    val isAvailable: Boolean = NativeBackend.isAvailable

    @JvmStatic
    fun apply(
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
    ) {
        applyNative(
            src1 = src1,
            src2 = src2,
            dst = dst,
            width = width,
            clipLeft = clipLeft,
            clipTop = clipTop,
            clipRight = clipRight,
            clipBottom = clipBottom,
            k1 = k1,
            k2 = k2,
            k3 = k3,
            k4 = k4,
            useLinear = useLinear,
        )
    }

    @JvmStatic
    private external fun applyNative(
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

    /**
     * Validation/test-only twin of [apply]. Runs an explicitly selected backend
     * regardless of normal CPU dispatch.
     */
    @JvmStatic
    fun applyForced(
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
        simdBackend: Int,
    ) {
        applyForcedNative(
            src1 = src1,
            src2 = src2,
            dst = dst,
            width = width,
            clipLeft = clipLeft,
            clipTop = clipTop,
            clipRight = clipRight,
            clipBottom = clipBottom,
            k1 = k1,
            k2 = k2,
            k3 = k3,
            k4 = k4,
            useLinear = useLinear,
            simdBackend = simdBackend,
        )
    }

    @JvmStatic
    private external fun applyForcedNative(
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
        simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    external fun nativeBackend(): Int
}
