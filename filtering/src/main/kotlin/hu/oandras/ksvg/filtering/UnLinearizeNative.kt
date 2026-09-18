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
 * Linear→sRGB (unlinearize) transfer kernel over straight ARGB_8888 IntArrays.
 *
 * This is the filter-output color-space conversion (the KSVG equivalent of
 * librsvg's `FilterContext::into_output` → `unlinearize_surface`): each pixel's
 * straight R/G/B channel is looked up in a single shared 256-entry byte table
 * (the caller's `UNLINEARIZE` LUT) and alpha is passed through unchanged.
 *
 * Unlike [ComponentTransferNative] there is one table shared by three channels
 * and alpha needs no lookup — it is a pure element-wise byte map, so `src` and
 * `dst` may alias (in-place). Stateless and allocation-free: the pixel arrays
 * are caller-owned scratch (reused buffers), no shared/global state. Avail-
 * ability follows the same `libksvgblur` library as [NativeGaussianBlur].
 */
internal object UnLinearizeNative {

    @JvmField
    val isAvailable: Boolean = NativeBackend.isAvailable

    @JvmStatic
    external fun apply(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
    )

    /**
     * Validation/test-only twin of [apply]. Runs an explicitly selected backend
     * (see [SIMD_SCALAR]..[SIMD_NEON32]) regardless of normal CPU dispatch,
     * asserted on the native side for ABI/backend validity. Normal production
     * code must NOT call this — it exists only for the backend-validation
     * harness, and normal dispatch/`apply` is unchanged.
     */
    @JvmStatic
    external fun applyForced(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        @SimdBackend simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    @SimdBackend
    external fun nativeBackend(): Int
}
