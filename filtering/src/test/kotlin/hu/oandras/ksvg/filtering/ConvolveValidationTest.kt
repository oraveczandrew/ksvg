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
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ConvolveValidationTest {

    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }
    }

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on host", ConvolveNative.isAvailable)
        for (case in ConvolveValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ConvolveNative.applyForced(
                case.input, out, case.width, case.height,
                case.kernel, case.orderX, case.orderY,
                case.targetX, case.targetY,
                case.divisor, case.bias, case.preserveAlpha, case.edgeMode,
                backend
            )
            assertArrayEquals(
                "$backendName mismatch on ${case.name}",
                expected, out
            )
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(UnlinearizeNative.SIMD_SCALAR, "scalar")

    @Test
    fun ssse3MatchesKotlin() = checkBackend(UnlinearizeNative.SIMD_SSSE3, "ssse3")

    @Test
    fun avx2MatchesKotlin() = checkBackend(UnlinearizeNative.SIMD_AVX2, "avx2")

    @Test
    fun avx512MatchesKotlin() = checkBackend(UnlinearizeNative.SIMD_AVX512, "avx512")

    @Test
    fun productionDispatchSelectsHighest() {
        assertTrue("libksvgblur not loadable on host", ConvolveNative.isAvailable)
        assertEquals(
            "expected avx512 as the dispatched convolve backend on this host",
            UnlinearizeNative.SIMD_AVX512,
            ConvolveNative.nativeBackend()
        )
    }

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on host", ConvolveNative.isAvailable)
        for (case in ConvolveValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ConvolveNative.apply(
                case.input, out, case.width, case.height,
                case.kernel, case.orderX, case.orderY,
                case.targetX, case.targetY,
                case.divisor, case.bias, case.preserveAlpha, case.edgeMode
            )
            assertArrayEquals(
                "production apply mismatch on ${case.name}",
                expected, out
            )
        }
    }
}
