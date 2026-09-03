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
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class GaussianBlurValidationTest {

    private fun checkBackend(backend: Int, backendName: String, tolerance: Int = 0) {
        assertNativeBackendAvailable()
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for (case in GaussianBlurValidationCorpus.cases) {
                val expected = case.reference()
                val out = case.input.copyOf()
                NativeGaussianBlur.applyForced(
                    scratch, out, case.width, case.height,
                    case.stdDeviationX, case.stdDeviationY,
                    backend
                )

                if (tolerance == 0) {
                    assertArrayEquals(
                        "$backendName mismatch on ${case.name}",
                        expected, out
                    )
                } else {
                    for (i in expected.indices) {
                        for (ch in 0..3) {
                            val shift = ch * 8
                            val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                            assertTrue(
                                "$backendName mismatch on ${case.name} at element [$i] channel $ch: " +
                                    "expected ${((expected[i] shr shift) and 0xff)} but was ${((out[i] shr shift) and 0xff)} " +
                                    "(diff $d > tolerance $tolerance)",
                                d <= tolerance
                            )
                        }
                    }
                }
            }
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
    }

    @Test
    fun scalarMatchesKotlin() = checkBackend(SIMD_SCALAR, "scalar")

    @Test
    fun ssse3MatchesKotlin() = checkBackend(SIMD_SSSE3, "ssse3", tolerance = 1)

    @Test
    fun avx2MatchesKotlin() = checkBackend(SIMD_AVX2, "avx2", tolerance = 1)

    @Test
    fun productionApplyMatchesKotlin() {
        assertNativeBackendAvailable()
        val scratch = NativeGaussianBlur.createScratch()
        try {
            for (case in GaussianBlurValidationCorpus.cases) {
                val expected = case.reference()
                val out = case.input.copyOf()
                NativeGaussianBlur.nativeBlur(
                    scratch, out, case.width, case.height,
                    case.stdDeviationX, case.stdDeviationY
                )
                
                // Production might use optimized paths, so allow tolerance 1
                for (i in expected.indices) {
                    for (ch in 0..3) {
                        val shift = ch * 8
                        val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                        assertTrue(
                            "production mismatch on ${case.name} at element [$i] channel $ch: diff $d > 1",
                            d <= 1
                        )
                    }
                }
            }
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }
    }
}
