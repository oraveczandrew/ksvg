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
 * Bit-exact parity check between the native feMorphology kernel and the
 * pure-Kotlin reference. For every configuration in the shared
 * [MorphologyValidationCorpus], every SIMD backend this host advertises is
 * forced via [MorphologyNative.applyForced] and compared byte-for-byte.
 */
@NativeParityTest
@RunWith(Parameterized::class)
class MorphologyNativeParityTest(
    private val name: String,
    private val case: MorphologyValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Force every backend this host actually advertises, mirroring
            // KernelPerformanceBenchmark.getBackendsFor.
            val backends = getBackendsFor(MorphologyNative.nativeBackend())
            return buildList {
                for (case in MorphologyValidationCorpus.cases) {
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

        val src = case.freshInput()
        val ref = IntArray(case.size)
        val native = IntArray(case.size)

        KotlinKernels.morphology(
            src, ref, case.width, case.height,
            case.radiusX, case.radiusY, case.erode,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
        )
        MorphologyNative.applyForced(
            case.freshInput(), native, case.width, case.height,
            case.radiusX, case.radiusY, case.erode,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom, backend,
        )

        assertArrayEquals(
            "morphology mismatch on [$name] backend ${backendName(backend)}",
            ref, native,
        )
    }
}
