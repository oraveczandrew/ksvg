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

class DisplacementMapValidationTest {

    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }
    }

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on host", DisplacementMapNative.isAvailable)
        for (case in DisplacementMapValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            DisplacementMapNative.applyForced(
                case.src, case.map, out, case.width, case.height,
                case.mapWidth, case.mapHeight, case.scale,
                case.xChannel, case.yChannel,
                backend
            )
            assertArrayEquals(
                "$backendName mismatch on ${case.name}",
                expected, out
            )
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(SIMD_SCALAR, "scalar")

    @Test
    fun avx2MatchesKotlin() = checkBackend(SIMD_AVX2, "avx2")

    @Test
    fun avx512MatchesKotlin() = checkBackend(SIMD_AVX512, "avx512")

    @Test
    fun productionDispatchSelectsHighest() {
        assertTrue("libksvgblur not loadable on host", DisplacementMapNative.isAvailable)
        assertEquals(
            "expected avx512 as the dispatched displacement_map backend on this host",
            SIMD_AVX512,
            DisplacementMapNative.nativeBackend()
        )
    }

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on host", DisplacementMapNative.isAvailable)
        for (case in DisplacementMapValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            DisplacementMapNative.apply(
                case.src, case.map, out, case.width, case.height,
                case.mapWidth, case.mapHeight, case.scale,
                case.xChannel, case.yChannel
            )
            assertArrayEquals(
                "production apply mismatch on ${case.name}",
                expected, out
            )
        }
    }
}
