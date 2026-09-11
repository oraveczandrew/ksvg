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

import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Byte-exact parity between the native `unlinearize.cpp` SIMD kernels
 * ([UnLinearizeNative.applyForced]) and the pure-Kotlin reference
 * ([KotlinKernels.unLinearize]). For every configuration in the shared
 * [UnLinearizeValidationCorpus], every SIMD backend this host advertises is
 * forced and compared byte-for-byte, covering the NEON/SSSE3/AVX2 vector tails,
 * separate src/dst, and the in-place (src == dst) path used by the
 * filter-output transfer.
 */
@NativeParityTest
@RunWith(Parameterized::class)
class UnLinearizeNativeParityTest(
    private val name: String,
    private val case: UnLinearizeValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = getBackendsFor(UnLinearizeNative.nativeBackend())
            return buildList {
                for (case in UnLinearizeValidationCorpus.cases) {
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

        val ref = IntArray(case.size)
        KotlinKernels.unLinearize(case.input, ref, case.width, case.height)

        val native = if (case.inPlace) {
            val buf = case.freshInput()
            UnLinearizeNative.applyForced(buf, buf, case.width, case.height, backend)
            buf
        } else {
            val out = IntArray(case.size)
            UnLinearizeNative.applyForced(case.freshInput(), out, case.width, case.height, backend)
            out
        }

        assertColorArrayEquals(
            "unlinearize mismatch on [$name] backend ${backendName(backend)}",
            ref, native,
        )
    }

    /**
     * Explicit alpha-preservation contract across all 256 alpha values: the native
     * kernel must leave the alpha byte untouched regardless of what the table does.
     * Runs every alpha 0..255 over a fixed RGB set on every advertised backend.
     */
    @Test
    fun nativePreservesAllAlphaValues() {
        assertNativeBackendAvailable()

        val width = 16
        val height = 16
        val src = UnLinearizeValidationCorpus.allAlpha(width * height) // alpha = i & 0xFF covers 0..255

        // Force every advertised backend; each must preserve alpha.
        val backends = getBackendsFor(UnLinearizeNative.nativeBackend())
        for (backend in backends) {
            val native = IntArray(width * height)
            UnLinearizeNative.applyForced(
                src.copyOf(), native, width, height, backend,
            )
            for (i in src.indices) {
                assertEquals(
                    "alpha byte must pass through on ${backendName(backend)} at $i",
                    (src[i] ushr 24) and 0xFF,
                    (native[i] ushr 24) and 0xFF
                )
            }
        }
    }
}
