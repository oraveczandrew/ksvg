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

class ComponentTransferValidationTest {

    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }
    }

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on host", ComponentTransferNative.isAvailable)
        for (case in ComponentTransferValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ComponentTransferNative.applyForced(
                case.input, out, case.width, case.height,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.tableA, case.tableR, case.tableG, case.tableB,
                backend
            )
            assertArrayEquals(
                "$backendName mismatch on ${case.name} (${case.width}x${case.height})",
                expected, out
            )
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(SIMD_SCALAR, "scalar")

    @Test
    fun ssse3MatchesKotlin() = checkBackend(SIMD_SSSE3, "ssse3")

    @Test
    fun avx2MatchesKotlin() = checkBackend(SIMD_AVX2, "avx2")

    @Test
    fun productionDispatchSelectsHighest() {
        assertTrue("libksvgblur not loadable on host", ComponentTransferNative.isAvailable)
        // On this host (i7-7820X) it should be AVX2.
        assertEquals(
            "expected avx2 as the dispatched component_transfer backend on this host",
            SIMD_AVX2 or SIMD_SSSE3 or SIMD_SCALAR,
            ComponentTransferNative.nativeBackend()
        )
    }

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on host", ComponentTransferNative.isAvailable)
        for (case in ComponentTransferValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            ComponentTransferNative.apply(
                case.input, out, case.width, case.height,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.tableA, case.tableR, case.tableG, case.tableB
            )
            assertArrayEquals(
                "production apply mismatch on ${case.name}",
                expected, out
            )
        }
    }
}
