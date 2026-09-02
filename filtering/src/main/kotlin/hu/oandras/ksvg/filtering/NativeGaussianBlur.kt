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

import kotlin.math.max

/**
 * Unified, caller-owned blur scratch. [StackBlurScratch] hides whether the
 * underlying blur is the native true-Gaussian path or the pure-Kotlin stack-blur
 * fallback: construct one via [StackBlurScratch] and reuse it across renders.
 *
 * Each instance owns its reusable buffers (allocated lazily, grown only when the
 * image dimensions change) so [NativeGaussianBlur.blur] performs no allocation
 * and is safe to call from multiple threads — every rendering operation must own
 * its own instance.
 */
public sealed interface StackBlurScratch {

    /**
     * Blurs [pixels] (ARGB, length [width] * [height]) in place. Pixels outside
     * the bitmap are treated as transparent black, matching the SVG spec for
     * filter-region edges (stdDeviation == Gaussian sigma).
     */
    public fun blur(
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
    )

    /** Releases any native resources. No-op for the Kotlin fallback. */
    public fun close() {}
}

private class NativeScratch : StackBlurScratch {
    private var handle: Long = 0

    private fun ensure(): Long {
        if (handle == 0L) handle = NativeGaussianBlur.createScratch()
        return handle
    }

    override fun blur(
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
    ) {
        NativeGaussianBlur.nativeBlur(ensure(), pixels, width, height, stdDeviationX, stdDeviationY)
    }

    override fun close() {
        if (handle != 0L) {
            NativeGaussianBlur.destroyScratch(handle)
            handle = 0L
        }
    }
}

private class FallbackScratch : StackBlurScratch {
    private val scratchX = StackBlurAxisScratch()
    private val scratchY = StackBlurAxisScratch()

    override fun blur(
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
    ) {
        val rx = max((stdDeviationX * 2.5f + 0.5f).toInt(), 0)
        val ry = max((stdDeviationY * 2.5f + 0.5f).toInt(), 0)
        if (rx > 0) stackBlur(pixels, width, height, rx, true, scratchX)
        if (ry > 0) stackBlur(pixels, width, height, ry, false, scratchY)
    }
}

/**
 * Creates a [StackBlurScratch] backed by the native true-Gaussian path when the
 * shared library is available, or by the pure-Kotlin stack blur otherwise. The
 * native handle is created lazily on first [StackBlurScratch.blur], so this is
 * safe to call even when the native library is absent (e.g. under Robolectric),
 * where the Kotlin fallback is used and no native call occurs.
 */
public fun StackBlurScratch(): StackBlurScratch =
    if (NativeBackend.isAvailable) NativeScratch() else FallbackScratch()

/**
 * Native, true-Gaussian blur backed by a bundled shared library (`libksvgblur.so`,
 * built from the RIR Toolkit's separable Gaussian kernel).
 *
 * The blur operates on the ARGB pixels as supplied by [android.graphics.Bitmap.getPixels]
 * (each channel blurred independently) and treats pixels outside the bitmap as transparent
 * black, matching the SVG spec for filter-region edges (stdDeviation == Gaussian sigma).
 *
 * [blur] transparently dispatches to the native path or a pure-Kotlin fallback
 * depending on the [StackBlurScratch] handed to it, so callers always get a working
 * blur without needing to branch on availability themselves.
 */
internal object NativeGaussianBlur {

    @JvmStatic
    external fun nativeBlur(
        scratch: Long,
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
    )

    /**
     * Validation/test-only twin of [nativeBlur]. Runs an explicitly selected backend
     * regardless of normal CPU dispatch.
     */
    @JvmStatic
    external fun applyForced(
        scratch: Long,
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
        simdBackend: Int,
    )

    /** Reports the backend the production dispatcher actually selects on this ABI. */
    @JvmStatic
    external fun nativeBackend(stdDeviationX: Float, stdDeviationY: Float): Int

    @JvmStatic
    external fun createScratch(): Long

    @JvmStatic
    external fun destroyScratch(handle: Long)

    /**
     * Render-loop variant: reuses the caller-owned [scratch] so no allocation
     * happens on the hot path. [scratch] must be owned by the current rendering
     * operation.
     */
    @JvmStatic
    fun blur(
        pixels: IntArray,
        width: Int,
        height: Int,
        stdDeviationX: Float,
        stdDeviationY: Float,
        scratch: StackBlurScratch,
    ) {
        scratch.blur(pixels, width, height, stdDeviationX, stdDeviationY)
    }
}
