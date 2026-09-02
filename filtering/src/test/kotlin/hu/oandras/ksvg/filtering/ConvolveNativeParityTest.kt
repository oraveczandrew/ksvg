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

import org.junit.Assert.assertArrayEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

@RunWith(Parameterized::class)
class ConvolveNativeParityTest(
    private val kernel: FloatArray,
    private val orderY: Int,
    private val edgeMode: Int,
) {
    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }

        private const val EDGE_DUPLICATE = 0
        private const val EDGE_WRAP = 1
        private const val EDGE_NONE = 2

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> = listOf(
            // duplicate edge, 3x3 identity-ish kernel with divisor
            arrayOf(floatArrayOf(0f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 0f), 3, EDGE_DUPLICATE),
            // wrap edge, 3x3 box-like kernel, bias
            arrayOf(floatArrayOf(1f, 1f, 1f, 1f, 1f, 1f, 1f, 1f, 1f), 3, EDGE_WRAP),
            // none edge (transparent padding), 3x3, with bias
            arrayOf(floatArrayOf(1f, 0f, -1f, 0f, 0f, 0f, -1f, 0f, 1f), 3, EDGE_NONE),
            // non-square 3x2 kernel
            arrayOf(floatArrayOf(0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.5f), 2, EDGE_DUPLICATE),
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val width = 40
        val height = 34
        val orderX = kernel.size / orderY
        val src = pattern(width, height, edgeMode * 31 + kernel.size)

        for (target in 0..1) {
            for (preserveAlpha in listOf(false, true)) {
                val divisor = maxOf(1f, kernel.sum())
                val ref = IntArray(width * height)
                val native = IntArray(width * height)

                KotlinKernels.convolveMatrix(
                    src, ref, width, height, kernel, orderX, orderY,
                    targetX = target, targetY = target,
                    divisor = divisor, bias = 0.15f,
                    preserveAlpha = preserveAlpha, edgeMode = edgeMode,
                )
                SoftwareKernels.convolveMatrix(
                    src, native, width, height, kernel, orderX, orderY,
                    targetX = target, targetY = target,
                    divisor = divisor, bias = 0.15f,
                    preserveAlpha = preserveAlpha, edgeMode = edgeMode,
                )

                assertArrayEquals(
                    "convolve mismatch: order=${orderX}x$orderY edge=$edgeMode target=$target preserveAlpha=$preserveAlpha",
                    ref, native,
                )
            }
        }
    }
}
