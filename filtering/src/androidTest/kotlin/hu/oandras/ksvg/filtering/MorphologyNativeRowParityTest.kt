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
 * Bit-exact parity check for the aarch64 **row** morphology kernel
 * (ksvgMorphologyApplyRowNeon64) against the pure-Kotlin reference. The row
 * kernel is not advertised by [MorphologyNative.nativeBackend], so it is driven
 * through [MorphologyNative.applyForcedRow] (scalar borders + row interior).
 *
 * Runs the shared [MorphologyValidationCorpus] (which already forces the row
 * path over narrow boundary/shape cases) plus an explicit wide-interior run
 * covering the multi-pixel-per-call code path with both many vector groups and
 * the tail-column path.
 */
@NativeParityTest
@RunWith(Parameterized::class)
class MorphologyNativeRowParityTest(
    private val name: String,
    private val case: MorphologyValidationCorpus.Case,
    private val backend: Int,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            val backends = getBackendsFor(MorphologyNative.nativeBackend())
            val wide = buildList {
                for (erode in listOf(true, false)) {
                    val op = if (erode) "erode" else "dilate"
                    // 5x5 interior over 129 columns: spans 2*radiusX = 10 extra
                    // columns + vector groups and tail-column path all exercised.
                    add(case(op + " row 5x5 wide 129x17", 129, 17, 5, 5, erode))
                    // 3x3 interior over a 2-column-wide interior (tail-heavy
                    // horizontal fold: only 1 vector group + tail for most rows).
                    add(case(op + " row 3x3 narrow 9x9", 9, 9, 3, 3, erode))
                }
            }
            return buildList {
                for (case in (MorphologyValidationCorpus.cases + wide)) {
                    for (b in backends) {
                        add(arrayOf("${case.name} [${backendName(b)}]", case, b))
                    }
                }
            }
        }

        private fun case(
            name: String,
            width: Int,
            height: Int,
            radiusX: Int,
            radiusY: Int,
            erode: Boolean,
        ) = MorphologyValidationCorpus.Case(
            name, width, height, radiusX, radiusY, erode,
            0, 0, width, height,
            UnLinearizeValidationCorpus.fixedSeedRandom(width * height),
        )
    }

    @Test
    fun rowNativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val ref = IntArray(case.size)
        val native = IntArray(case.size)

        KotlinKernels.morphology(
            case.freshInput(), ref, case.width, case.height,
            case.radiusX, case.radiusY, case.erode,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
        )
        MorphologyNative.applyForcedRow(
            case.freshInput(), native, case.width, case.height,
            case.radiusX, case.radiusY, case.erode,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom, backend
        )

        assertArrayEquals("morphology row mismatch on [$name]", ref, native)
    }
}