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
 * Byte-exact parity between the native `arithmetic_composite.cpp` SIMD kernels
 * ([ArithmeticCompositeNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.arithmeticComposite]). For every configuration in the shared
 * [ArithmeticCompositeValidationCorpus], every SIMD backend this host advertises
 * is forced and compared byte-for-byte.
 */
@RunWith(Parameterized::class)
class ArithmeticCompositeNativeParityTest(
    private val name: String,
    private val case: ArithmeticCompositeValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = getBackendsFor(ArithmeticCompositeNative.nativeBackend())
            return buildList {
                for (case in ArithmeticCompositeValidationCorpus.cases) {
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
        ArithmeticCompositeNative.applyForced(
            case.input1, case.input2, out, case.width,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
            case.k1, case.k2, case.k3, case.k4, case.useLinear,
            backend
        )

        assertArrayEquals(
            "arithmeticComposite mismatch on [$name] backend ${backendName(backend)}",
            ref, out,
        )
    }
}
