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
 * Byte-exact parity between the native `displacement_map.cpp` SIMD kernels
 * ([DisplacementMapNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.displacementMap]). For every configuration in the shared
 * [DisplacementMapValidationCorpus], every SIMD backend this host advertises is
 * forced and compared byte-for-byte.
 */
@RunWith(Parameterized::class)
class DisplacementMapNativeParityTest(
    private val name: String,
    private val case: DisplacementMapValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = KernelPerformanceBenchmark.getBackendsFor(DisplacementMapNative.nativeBackend())
            return buildList {
                for (case in DisplacementMapValidationCorpus.cases) {
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
        DisplacementMapNative.applyForced(
            case.src, case.map, out, case.width, case.height,
            case.mapWidth, case.mapHeight, case.scale,
            case.xChannel, case.yChannel,
            backend
        )

        assertArrayEquals(
            "displacementMap mismatch on [$name] backend ${backendName(backend)}",
            ref, out,
        )
    }
}
