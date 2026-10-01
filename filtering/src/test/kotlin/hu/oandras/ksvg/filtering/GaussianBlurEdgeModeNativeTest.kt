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

import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs
import kotlin.random.Random

/**
 * Edge-mode coverage for the native scalar blur path
 * ([NativeGaussianBlur.applyForced] with `SIMD_SCALAR`).
 *
 * The RIR SIMD kernels only implement transparent edges, so `duplicate` and
 * `wrap` always run on the C++ scalar fallback — this test pins that fallback
 * through JNI with a signal touching the image edge, where the modes must
 * observably differ from `none`.
 */
class GaussianBlurEdgeModeNativeTest {

    private fun runForced(pixels: IntArray, width: Int, height: Int, edgeMode: Int): IntArray {
        assertNativeBackendAvailable()
        val out = pixels.copyOf()
        val scratch = NativeGaussianBlur.createScratch()
        try {
            NativeGaussianBlur.applyForced(
                scratch, out, width, height,
                2f, 0f,
                SIMD_SCALAR, edgeMode
            )
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
        return out
    }

    @Test
    fun duplicateReplicatesEdgePixel() {
        // Opaque white run covering the left half, transparent elsewhere.
        // The run is much wider than the blur radius (6 at sigma=2), so the
        // left edge taps only ever see opaque white under duplicate.
        val input = IntArray(41) { x -> if (x <= 20) -1 else 0 }
        val duplicate = runForced(input, 41, 1, StackBlur.EDGE_DUPLICATE)
        val none = runForced(input, 41, 1, StackBlur.EDGE_NONE)
        val dupAlpha = duplicate[0] ushr 24
        val noneAlpha = none[0] ushr 24
        // Replicated opaque taps keep the edge fully opaque; transparent
        // extension fades it.
        assertTrue("duplicate edge alpha should stay ~opaque, was $dupAlpha", dupAlpha >= 254)
        assertTrue("none edge alpha should fade ($noneAlpha vs $dupAlpha)", noneAlpha < dupAlpha)
    }

    @Test
    fun wrapSamplesOppositeEdge() {        // White run on the left, opaque blue run at the far right end.
        val input = IntArray(41) { x -> if (x <= 20) -1 else if (x >= 35) -16776961 else 0 }
        val wrap = runForced(input, 41, 1, StackBlur.EDGE_WRAP)
        val none = runForced(input, 41, 1, StackBlur.EDGE_NONE)
        // Taps left of x=0 read the opposite (blue) end under wrap but
        // transparent black under none.
        val wrapBlue = wrap[0] and 0xff
        val noneBlue = none[0] and 0xff
        assertTrue("wrap should pull blue from the opposite edge ($wrapBlue vs $noneBlue)", wrapBlue > noneBlue)
    }

    /**
     * Every advertised SIMD backend must agree with the scalar reference for
     * `duplicate`/`wrap` within 1 LSB — the same bound as the `none` parity
     * test (fixed-point weight quantization + tie-to-even vs trunc rounding).
     * The SIMD kernels read only the edge-extended pad ring, so this pins the
     * C++ pad-ring extension per backend.
     */
    @Test
    fun simdMatchesScalarForDuplicateAndWrap() {
        assertNativeBackendAvailable()
        val configs = listOf(
            Triple(37, 23, 2f),
            Triple(64, 64, 5f),
            Triple(16, 9, 1f),
        )
        for ((w, h, sigma) in configs) {
            val rnd = Random(w * 1000 + h * 7 + (sigma * 100).toInt())
            val input = IntArray(w * h) {
                (rnd.nextInt(256) shl 24) or (rnd.nextInt(256) shl 16) or
                    (rnd.nextInt(256) shl 8) or rnd.nextInt(256)
            }
            val backends = getBackendsFor(NativeGaussianBlur.nativeBackend(sigma, sigma))
            println("edge parity ${w}x$h sigma=$sigma backends=${backends.toList()}")
            for (edgeMode in intArrayOf(StackBlur.EDGE_DUPLICATE, StackBlur.EDGE_WRAP)) {
                val expected = runBackend(input, w, h, sigma, SIMD_SCALAR, edgeMode)
                for (backend in backends) {
                    if (backend == SIMD_SCALAR) continue
                    val out = runBackend(input, w, h, sigma, backend, edgeMode)
                    var maxD = 0
                    for (i in out.indices) {
                        for (ch in 0..3) {
                            val shift = ch * 8
                            val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                            if (d > maxD) maxD = d
                        }
                    }
                    assertTrue(
                        "blur edge=$edgeMode ${w}x$h sigma=$sigma backend=$backend differs from scalar: maxD=$maxD",
                        maxD <= 1
                    )
                }
            }
        }
    }

    private fun runBackend(
        pixels: IntArray,
        width: Int,
        height: Int,
        sigma: Float,
        backend: Int,
        edgeMode: Int,
    ): IntArray {
        val out = pixels.copyOf()
        val scratch = NativeGaussianBlur.createScratch()
        try {
            NativeGaussianBlur.applyForced(
                scratch, out, width, height,
                sigma, sigma,
                backend, edgeMode
            )
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
        return out
    }
}
