/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.filtering

/**
 * feBlend kernel over unpremultiplied ARGB_8888 (all non-normal modes, see
 * [FeBlendMode]; [src] is `in`, [dst] is the backdrop `in2`).
 *
 * SIMD backends for the separable modes: SSSE3 on x86_64/i386, AVX2 on
 * x86_64; scalar everywhere as the fallback and for the non-separable
 * modes (hue/saturation/color/luminosity) on every ABI.
 *
 * Stateless and availability follows `libksvgfilters` ([NativeBackend.isAvailable]).
 */
internal object FeBlendNative {

    @JvmField
    val isAvailable: Boolean = NativeBackend.isAvailable

    @JvmStatic
    fun apply(
        src: IntArray,
        dst: IntArray,
        out: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        @FeBlendMode mode: Int,
        useLinear: Boolean,
    ) {
        applyNative(
            src = src,
            dst = dst,
            out = out,
            width = width,
            clipLeft = clipLeft,
            clipTop = clipTop,
            clipRight = clipRight,
            clipBottom = clipBottom,
            mode = mode,
            useLinear = useLinear,
        )
    }

    @JvmStatic
    private external fun applyNative(
        src: IntArray,
        dst: IntArray,
        out: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        @FeBlendMode mode: Int,
        useLinear: Boolean,
    )

    /**
     * Validation/test-only twin of [apply]. Runs an explicitly selected backend
     * regardless of normal CPU dispatch.
     */
    @JvmStatic
    fun applyForced(
        src: IntArray,
        dst: IntArray,
        out: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        @FeBlendMode mode: Int,
        useLinear: Boolean,
        @SimdBackend simdBackend: Int,
    ) {
        applyForcedNative(
            src = src,
            dst = dst,
            out = out,
            width = width,
            clipLeft = clipLeft,
            clipTop = clipTop,
            clipRight = clipRight,
            clipBottom = clipBottom,
            mode = mode,
            useLinear = useLinear,
            simdBackend = simdBackend,
        )
    }

    @JvmStatic
    private external fun applyForcedNative(
        src: IntArray,
        dst: IntArray,
        out: IntArray,
        width: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        @FeBlendMode mode: Int,
        useLinear: Boolean,
        @SimdBackend simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    @SimdBackend
    external fun nativeBackend(): Int
}
