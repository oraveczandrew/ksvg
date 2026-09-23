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

import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import kotlin.math.abs

/**
 * Host-side parity test for [NativeGaussianBlur].
 *
 * Compares the native blur (ported from RIR Toolkit) against an independent
 * Kotlin Gaussian reference (transparent-black edges, stdDeviation == sigma)
 * provided by [GaussianBlurValidationCorpus]. Since they are different
 * implementations of the same mathematical goal, a small per-backend rounding
 * tolerance is allowed (matching the device test): scalar is bit-exact
 * (tolerance 0), the SIMD tails allow 1. The ±1 LSB comes from the x86
 * `cvtps2dq` tie-to-even rounding vs the Kotlin reference `trunc(x + 0.5)`;
 * exact .5 ties can differ by 1, never more (F3-characterization).
 *
 * For every configuration in the shared corpus, every SIMD backend this host
 * advertises for that radius is forced via [NativeGaussianBlur.applyForced].
 */
@RunWith(Parameterized::class)
class GaussianBlurNativeParityTest(
    private val name: String,
    private val case: GaussianBlurValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            return buildList {
                for (case in GaussianBlurValidationCorpus.cases) {
                    val backends = getBackendsFor(
                        NativeGaussianBlur.nativeBackend(case.stdDeviationX, case.stdDeviationY)
                    )
                    for (b in backends) {
                        add(arrayOf("${case.name} [${backendName(b)}]", case, b))
                    }
                }
            }
        }

        private fun tolerance(backend: Int): Int = if (backend == SIMD_SCALAR) 0 else 1
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val expected = case.reference()
        val out = case.input.copyOf()
        val scratch = NativeGaussianBlur.createScratch()
        try {
            NativeGaussianBlur.applyForced(
                scratch, out, case.width, case.height,
                case.stdDeviationX, case.stdDeviationY,
                backend
            )
        } finally {
            NativeGaussianBlur.destroyScratch(scratch)
        }

        val tol = tolerance(backend)
        for (i in expected.indices) {
            for (ch in 0..3) {
                val shift = ch * 8
                val d = abs(((out[i] shr shift) and 0xff) - ((expected[i] shr shift) and 0xff))
                assertTrue(
                    "gaussianBlur mismatch on [$name] backend ${backendName(backend)} " +
                        "at element [$i] channel $ch: diff $d > tolerance $tol",
                    d <= tol
                )
            }
        }
    }
}
