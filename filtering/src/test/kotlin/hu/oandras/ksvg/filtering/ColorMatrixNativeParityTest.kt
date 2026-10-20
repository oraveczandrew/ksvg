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

import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Parity between the native `color_matrix.cpp` kernels
 * ([ColorMatrixNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.colorMatrix]). For every configuration in the shared
 * [ColorMatrixValidationCorpus], every SIMD backend this host advertises
 * is forced and compared.
 *
 * Tolerance: the SIMD kernels (AVX2, SSSE3 x86_64, SSSE3 i386) widen
 * packed bytes via multiply-by-reciprocal (1/255 = `0x3B808081`) instead
 * of per-pixel `divps`. The reciprocal is inexact, so exact .5 ties may
 * differ by ±1 LSB from scalar division. SIMD backends therefore allow
 * `maxDelta=1`; the scalar backend stays byte-exact.
 */
@RunWith(Parameterized::class)
class ColorMatrixNativeParityTest(
    private val name: String,
    private val case: ColorMatrixValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = getBackendsFor(ColorMatrixNative.nativeBackend())
            return buildList {
                for (case in ColorMatrixValidationCorpus.cases) {
                    for (b in backends) {
                        add(arrayOf("${case.name} [${backendName(b)}]", case, b))
                    }
                }
            }
        }

        private fun tolerance(backend: Int): Int =
            if (backend == SIMD_SCALAR) 0 else 1
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val ref = case.reference()
        val out = IntArray(case.size)
        ColorMatrixNative.applyForced(
            case.input, out, case.width,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
            case.matrix, case.useLinear,
            backend
        )

        assertColorArrayEquals(
            "colorMatrix mismatch on [$name] backend ${backendName(backend)}",
            ref, out, maxDelta = tolerance(backend),
        )
    }
}
