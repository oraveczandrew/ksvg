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
 * feConvolveMatrix kernel over ARGB_8888 IntArrays — bit-exact port of the
 * Kotlin reference loop (same accumulation order, half-up rounding, identical
 * edge-mode handling). Supports arbitrary kernel order and anchor; edgeMode
 * uses the `ConvolveMatrixEdgeMode` ordinal: 0=duplicate, 1=wrap, 2=none.
 *
 * Stateless: caller-owned pixel/kernel arrays, no shared state. Availability
 * follows `libksvgblur` ([NativeBackend.isAvailable]).
 */
internal object ConvolveNative {

    @JvmField
    val isAvailable: Boolean = NativeBackend.isAvailable

    @JvmStatic
    external fun apply(
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
    )

    /**
     * Validation/test-only twin of [apply]. Runs an explicitly selected backend
     * regardless of normal CPU dispatch.
     */
    @JvmStatic
    external fun applyForced(
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
        @SimdBackend simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    @SimdBackend
    external fun nativeBackend(): Int
}
