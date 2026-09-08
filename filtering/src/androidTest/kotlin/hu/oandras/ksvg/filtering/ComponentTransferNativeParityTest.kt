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
 * Byte-exact parity between the native `component_transfer.cpp` SIMD kernels
 * ([ComponentTransferNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.componentTransfer]). For every configuration in the shared
 * [ComponentTransferValidationCorpus], every SIMD backend this host advertises
 * is forced and compared byte-for-byte, covering clip/table edge cases and the
 * outer-pixel transparent-black fill.
 */
@NativeParityTest
@RunWith(Parameterized::class)
class ComponentTransferNativeParityTest(
    private val name: String,
    private val case: ComponentTransferValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = getBackendsFor(ComponentTransferNative.nativeBackend())
            return buildList {
                for (case in ComponentTransferValidationCorpus.cases) {
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
        ComponentTransferNative.applyForced(
            case.freshInput(), out, case.width, case.height,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
            case.tableA, case.tableR, case.tableG, case.tableB,
            backend
        )

        assertColorArrayEquals(
            "componentTransfer mismatch on [$name] backend ${backendName(backend)}",
            ref, out,
        )
    }
}
