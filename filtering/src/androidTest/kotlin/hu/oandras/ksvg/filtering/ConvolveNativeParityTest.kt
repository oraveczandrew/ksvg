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

/**
 * Byte-exact parity between the native `convolve_matrix.cpp` SIMD kernels
 * ([ConvolveNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.convolveMatrix]). For every configuration in the shared
 * [ConvolveValidationCorpus], every SIMD backend this host advertises is forced
 * and compared byte-for-byte, covering kernel orders, anchors, divisors,
 * preserveAlpha, and the duplicate/wrap/none edge modes.
 */
@NativeParityTest
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

        assertArrayEquals(
            "convolve mismatch on [$name] backend ${backendName(backend)}",
            ref, out,
        )
    }
}
