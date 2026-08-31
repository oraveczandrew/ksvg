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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Bit-exact parity check between the native feTurbulence kernel
 * ([TurbulenceNative], driven through the [SoftwareKernels] facade) and the
 * pure-Kotlin reference ([KotlinKernels.turbulence]).
 *
 * This is a host JVM test: it loads a host-architecture build of `libksvgblur`
 * (produced for `x86_64` by the CMake project in `tmp/native-host/`) so the
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
    private val width: Int,
    private val height: Int,
    private val clipLeft: Int,
    private val clipTop: Int,
    private val clipRight: Int,
    private val clipBottom: Int,
    private val baseFrequencyX: Double,
    private val baseFrequencyY: Double,
    private val periodX: Int,
    private val periodY: Int,
    private val octaves: Int,
    private val fractalNoise: Boolean,
    private val invCanvasScaleX: Double,
    private val invCanvasScaleY: Double,
    private val userLeft: Double,
    private val userTop: Double,
    private val originX: Double,
    private val originY: Double,
    private val unitSizeX: Double,
    private val unitSizeY: Double,
    private val seed: Int,
) {

    companion object {
        init {
            // Load the host libksvgblur before any native dispatch is observed, so
            // TurbulenceNative.isAvailable resolves true and SoftwareKernels routes to
            // the native kernel. Throws (test error) if the host build is absent.
            System.loadLibrary("ksvgblur")
        }

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
        fun data(): List<Array<Any?>> = listOf(
            // Turbulence, single octave, no stitching.
            config("plain", 64, 64, 0, 0, 64, 64, 0.05, 0.05, 0, 0, 1, false, seed = 7),
            // Fractal noise, multiple octaves.
            config("fractal4", 64, 64, 0, 0, 64, 64, 0.08, 0.06, 0, 0, 4, true, seed = 42),
            // Anisotropic / sub-rectangle clip region (transparent fill outside).
            config("clip", 96, 80, 12, 8, 84, 72, 0.03, 0.05, 0, 0, 2, false, seed = 1234),
            // Non-integer origin / anchor + non-unit primitive units.
            config("fractional", 50, 50, 0, 0, 50, 50, 0.1, 0.1, 0, 0, 1, true, userLeft = 3.5, userTop = -1.25, originX = 2.0, originY = 7.5, unitSizeX = 0.75, unitSizeY = 1.25, seed = 3),
            // Stitch tiles: whole lattice periods so edges wrap seamlessly.
            config("stitch", 128, 128, 0, 0, 128, 128, 0.02, 0.02, 7, 9, 1, true, seed = 99),
            // Downscaled canvas (canvas scale 2.0 -> frequency doubles in user space).
            config("scaled", 32, 32, 0, 0, 32, 32, 0.05, 0.05, 0, 0, 3, false, invCanvasScaleX = 0.5, invCanvasScaleY = 0.5, seed = 55),
        )

        private fun config(
            name: String,
            width: Int,
            height: Int,
            clipLeft: Int,
            clipTop: Int,
            clipRight: Int,
            clipBottom: Int,
            baseFrequencyX: Double,
            baseFrequencyY: Double,
            periodX: Int,
            periodY: Int,
            octaves: Int,
            fractalNoise: Boolean,
            invCanvasScaleX: Double = 1.0,
            invCanvasScaleY: Double = 1.0,
            userLeft: Double = 0.0,
            userTop: Double = 0.0,
            originX: Double = 0.0,
            originY: Double = 0.0,
            unitSizeX: Double = 1.0,
            unitSizeY: Double = 1.0,
            seed: Int,
        ): Array<Any?> = arrayOf(
            name, width, height, clipLeft, clipTop, clipRight, clipBottom,
            baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
            invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
            unitSizeX, unitSizeY, seed,
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertTrue(
            "libksvgblur not loadable on the host JVM; the native path is not being tested here.",
            TurbulenceNative.isAvailable,
        )

        val kotlinOut = IntArray(width * height)
        val nativeOut = IntArray(width * height)

        KotlinKernels.turbulence(
            kotlinOut, width, height, clipLeft, clipTop, clipRight, clipBottom,
            baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
            invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
            unitSizeX, unitSizeY, seed, generators(seed),
        )

        SoftwareKernels.turbulence(
            nativeOut, width, height, clipLeft, clipTop, clipRight, clipBottom,
            baseFrequencyX, baseFrequencyY, periodX, periodY, octaves, fractalNoise,
            invCanvasScaleX, invCanvasScaleY, userLeft, userTop, originX, originY,
            unitSizeX, unitSizeY, seed, generators(seed),
        )

        assertArrayEquals(
            "native != kotlin for [$name]",
            kotlinOut, nativeOut,
        )
    }
}
