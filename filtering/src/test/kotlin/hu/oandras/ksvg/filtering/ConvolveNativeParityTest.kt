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

import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Bit-exact parity between the native `convolve_matrix.cpp` SIMD kernels
 * ([ConvolveNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.convolveMatrix]). For every configuration in the shared
 * [ConvolveValidationCorpus], every SIMD backend this host advertises is forced
 * and compared byte-for-byte, covering kernel orders, anchors, divisors,
 * preserveAlpha, and the duplicate/wrap/none edge modes.
 *
 * Tolerance (mirrors the instrumented suite, device-PROVEN 2026-09-23): the
 * AArch64/ARM32 NEON kernels hoist `1/divisor` (single `fdiv`) and multiply
 * per pixel, while the reference and the x86 kernels divide per pixel. For
 * non-power-of-two divisors the reciprocal is inexact, so exact .5 ties can
 * differ by ±1 LSB (observed: 1 alpha pixel +1 on `divisor 3.0 5x5
 * [neon64]`). NEON backends therefore allow `maxDelta=1` when the divisor is
 * not an exact power of two; every other combination stays byte-exact.
 */
@RunWith(Parameterized::class)
class ConvolveNativeParityTest(
    private val name: String,
    private val case: ConvolveValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = getBackendsFor(ConvolveNative.nativeBackend())
            return buildList {
                for (case in ConvolveValidationCorpus.cases) {
                    for (b in backends) {
                        add(arrayOf("${case.name} [${backendName(b)}]", case, b))
                    }
                }
            }
        }

        private fun isExactPowerOfTwo(d: Float): Boolean {
            if (!d.isFinite() || d <= 0f) return false
            return (java.lang.Float.floatToIntBits(d) and 0x7FFFFF) == 0
        }

        private fun tolerance(case: ConvolveValidationCorpus.Case, backend: Int): Int =
            if ((backend == SIMD_NEON64 || backend == SIMD_NEON32) && !isExactPowerOfTwo(case.divisor)) 1 else 0
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val ref = case.reference()
        val out = IntArray(case.size)
        ConvolveNative.applyForced(
            case.input, out, case.width, case.height,
            case.kernel, case.orderX, case.orderY,
            case.targetX, case.targetY,
            case.divisor, case.bias, case.preserveAlpha, case.edgeMode,
            backend
        )

        assertColorArrayEquals(
            "convolve mismatch on [$name] backend ${backendName(backend)}",
            ref, out, maxDelta = tolerance(case, backend),
        )
    }
}
