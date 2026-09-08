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
 * Bit-exact parity check between the native feTurbulence kernel
 * ([TurbulenceNative], driven through the [SoftwareKernels] facade) and the
 * pure-Kotlin reference ([KotlinKernels.turbulence]). Every configuration in
 * the shared [TurbulenceValidationCorpus] is forced through every SIMD backend
 * this host advertises.
 *
 * This is a host JVM test: it loads a host-architecture build of `libksvgblur`
 * (produced for `x86_64` by the CMake project in `filtering/host-native/`) so the
 * natively-dispatched path is genuinely exercised, not just the Kotlin fallback.
 *
 * Precondition: the shared object must be present where `-Djava.library.path`
 * points (configured in `filtering/build.gradle.kts`). If it is missing,
 * [TurbulenceNative.isAvailable] stays false and the test fails loudly rather
 * than silently comparing Kotlin against Kotlin.
 */
@RunWith(Parameterized::class)
class TurbulenceNativeParityTest(
    private val name: String,
    private val case: TurbulenceValidationCorpus.Case,
    private val backend: Int,
) {

    companion object {

        private fun generators(seed: Int): Array<SvgPathNoise> {
            // Mirror RenderTreeBuilder's construction order exactly: the four
            // per-channel lattice samplers consume the shared LCG stream first
            // (one gradient table each), then the shared permutation is built.
            val lcg = LcgRandom(if (seed <= 0) 1 else seed)
            val permutation = IntArray(SvgPathNoise.LATTICE_SIZE)
            val gens = Array(4) { SvgPathNoise(lcg, permutation) }
            SvgPathNoise.buildPermutation(lcg, permutation)
            return gens
        }

        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun data(): List<Array<Any?>> {
            // Force every SIMD backend this host actually advertises.
            val backends = getBackendsFor(TurbulenceNative.nativeBackend())
            return buildList {
                for (case in TurbulenceValidationCorpus.cases) {
                    for (b in backends) {
                        // First element is the JUnit display label: include the
                        // backend name so every case/backend pair is identifiable.
                        add(arrayOf("${case.name} [${backendName(b)}]", case, b))
                    }
                }
            }
        }
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val kotlinOut = IntArray(case.size)
        val nativeOut = IntArray(case.size)

        KotlinKernels.turbulence(
            kotlinOut, case.width, case.height,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
            case.baseFrequencyX, case.baseFrequencyY,
            case.periodX, case.periodY, case.octaves, case.fractalNoise,
            case.invCanvasScaleX, case.invCanvasScaleY,
            case.userLeft, case.userTop, case.originX, case.originY,
            case.unitSizeX, case.unitSizeY, case.seed,
            generators(case.seed),
        )

        TurbulenceNative.applyForced(
            nativeOut, case.width, case.height,
            case.clipLeft, case.clipTop, case.clipRight, case.clipBottom,
            case.baseFrequencyX, case.baseFrequencyY,
            case.periodX, case.periodY, case.octaves, case.fractalNoise,
            case.invCanvasScaleX, case.invCanvasScaleY,
            case.userLeft, case.userTop, case.originX, case.originY,
            case.unitSizeX, case.unitSizeY, case.seed,
            backend,
        )

        assertColorArrayEquals(
            "native != kotlin for [$name] on ${backendName(backend)}",
            kotlinOut, nativeOut,
        )
    }
}
