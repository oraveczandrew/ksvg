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
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.math.abs
import kotlin.random.Random

/**
 * Device-side mirror of the host `GaussianBlurEdgeModeNativeTest`
 * SIMD-vs-scalar comparison: every advertised SIMD backend (NEON on ARM, SSE
 * on x86) must agree with the scalar reference for `duplicate`/`wrap` within
 * 1 LSB. The NEON kernels cannot execute on the host, so this is the only
 * coverage of the ARM pad-ring path.
 */
@NativeParityTest
@RunWith(Parameterized::class)
class GaussianBlurEdgeModeSimdParityTest(
    private val name: String,
    private val width: Int,
    private val height: Int,
    private val sigma: Float,
    private val backend: Int,
    private val edgeMode: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            return buildList {
                val configs = listOf(
                    Triple(37, 23, 2f),
                    Triple(64, 64, 5f),
                    Triple(16, 9, 1f),
                )
                for ((w, h, sigma) in configs) {
                    val backends = getBackendsFor(NativeGaussianBlur.nativeBackend(sigma, sigma))
                    for (edgeMode in intArrayOf(StackBlur.EDGE_DUPLICATE, StackBlur.EDGE_WRAP)) {
                        for (b in backends) {
                            if (b == SIMD_SCALAR) continue
                            add(arrayOf("$w x $h sigma=$sigma edge=$edgeMode [${backendName(b)}]", w, h, sigma, b, edgeMode))
                        }
                    }
                }
            }
        }
    }

    @Test
    fun simdMatchesScalar() {
        assertNativeBackendAvailable()
        val rnd = Random(width * 1000 + height * 7 + (sigma * 100).toInt())
        val input = IntArray(width * height) {
            (rnd.nextInt(256) shl 24) or (rnd.nextInt(256) shl 16) or
                (rnd.nextInt(256) shl 8) or rnd.nextInt(256)
        }
        val expected = runBackend(input, SIMD_SCALAR)
        val out = runBackend(input, backend)
        var maxD = 0
        for (i in out.indices) {
            for (ch in 0..3) {
                val shift = ch * 8
                val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                if (d > maxD) maxD = d
            }
        }
        assertTrue(
            "blur edge=$edgeMode [$name] backend ${backendName(backend)} differs from scalar: maxD=$maxD",
            maxD <= 1
        )
    }

    private fun runBackend(pixels: IntArray, backend: Int): IntArray {
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
