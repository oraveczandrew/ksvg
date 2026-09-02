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

class LightingValidationTest {

    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }
    }

    private fun checkBackend(backend: Int, backendName: String) {
        assertTrue("libksvgblur not loadable on host", LightingNative.isAvailable)
        for (case in LightingValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            LightingNative.applyForced(
                case.input, out, case.width, case.height,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.surfaceScale, case.invCanvasScaleX, case.invCanvasScaleY,
                case.userLeft, case.userTop, case.originX, case.originY,
                case.unitSizeX, case.unitSizeY,
                case.canvasScaleX, case.canvasScaleY,
                case.lightType, case.specular, case.k, case.exponent,
                case.lightR, case.lightG, case.lightB, case.params,
                case.premultiplied, case.useLinear,
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
    fun ssse3MatchesKotlin() = checkBackend(SIMD_SSSE3, "ssse3")

    @Test
    fun productionDispatchSelectsHighest() {
        assertTrue("libksvgblur not loadable on host", LightingNative.isAvailable)
        // Lighting only has one vector path (SSE2 minimum), reported as SSSE3 by dispatcher.
        assertEquals(
            "expected ssse3 as the dispatched lighting backend on this host",
            SIMD_SSSE3,
            LightingNative.nativeBackend()
        )
    }

    @Test
    fun productionApplyMatchesKotlin() {
        assertTrue("libksvgblur not loadable on host", LightingNative.isAvailable)
        for (case in LightingValidationCorpus.cases) {
            val expected = case.reference()
            val out = IntArray(case.size)
            LightingNative.apply(
                case.input, out, case.width, case.height,
                case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
                case.surfaceScale, case.invCanvasScaleX, case.invCanvasScaleY,
                case.userLeft, case.userTop, case.originX, case.originY,
                case.unitSizeX, case.unitSizeY,
                case.canvasScaleX, case.canvasScaleY,
                case.lightType, case.specular, case.k, case.exponent,
                case.lightR, case.lightG, case.lightB, case.params,
                case.premultiplied, case.useLinear
            )
            assertArrayEquals(
                "production apply mismatch on ${case.name}",
                expected, out
            )
        }
    }
}
