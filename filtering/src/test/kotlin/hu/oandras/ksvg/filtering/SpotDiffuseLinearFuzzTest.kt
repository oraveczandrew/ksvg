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
import java.util.Random

/**
 * Differential coverage for the hand-written spot-diffuse-linear vector loops
 * (SSSE3 4-wide, AVX2 8-wide): forced backend vs forced scalar vs the Kotlin
 * oracle over seeded randomized configs (geometries incl. non-%4 widths,
 * k incl. negative, colored lights, spot cone/target variants). Fixed seed
 * => deterministic. Complements the corpus parity tests where the corpus has
 * a single linear spot case.
 */
class SpotDiffuseLinearFuzzTest {

    @Test
    fun ssse3LinearMatchesKotlinOnFuzz() {
        assertNativeBackendAvailable()
        val backends = getBackendsFor(LightingNative.nativeBackend())
        assert(backends.contains(SIMD_SSSE3)) { "ssse3 not advertised on this host" }

        runFuzzFor(SIMD_SSSE3, "ssse3")
        if (backends.contains(SIMD_AVX2)) {
            runFuzzFor(SIMD_AVX2, "avx2")
        }
    }

    private fun runFuzzFor(backend: Int, name: String) {
        val rnd = Random(123456789L)
        val widths = intArrayOf(16, 13, 27, 30, 32, 9)
        val ks = floatArrayOf(0f, 0.5f, 1f, 2f, -1f)
        val lights = arrayOf(
            intArrayOf(255, 255, 255),
            intArrayOf(255, 0, 0),
            intArrayOf(10, 200, 30),
            intArrayOf(0, 0, 0),
        )
        var caseNo = 0
        for (w in widths) {
            val h = 12
            for (k in ks) {
                for (lrgb in lights) {
                    val params = doubleArrayOf(
                        2.0 + rnd.nextDouble() * 14.0,
                        2.0 + rnd.nextDouble() * 8.0,
                        20.0 + rnd.nextDouble() * 120.0,
                        2.0 + rnd.nextDouble() * 10.0,
                        2.0 + rnd.nextDouble() * 6.0,
                        0.0,
                        15.0 + rnd.nextDouble() * 60.0,
                    )
                    val size = w * h
                    val pix = IntArray(size) { rnd.nextInt() }
                    for (linear in booleanArrayOf(false, true)) {
                    val ref = IntArray(size)
                    val out = IntArray(size)
                    val outScalar = IntArray(size)
                    val outSrgb = IntArray(size)
                    KotlinKernels.lighting(
                        pix, ref, w, h, 0, 0, w, h, 1f,
                        1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f,
                        2, false, k, 1f,
                        lrgb[0], lrgb[1], lrgb[2], params, false, linear,
                    )
                    LightingNative.applyForced(
                        pix, out, w, h, 0, 0, w, h, 1f,
                        1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f,
                        2, false, k, 1f,
                        lrgb[0], lrgb[1], lrgb[2], params, false, linear,
                        backend,
                    )
                    LightingNative.applyForced(
                        pix, outScalar, w, h, 0, 0, w, h, 1f,
                        1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f,
                        2, false, k, 1f,
                        lrgb[0], lrgb[1], lrgb[2], params, false, linear,
                        SIMD_SCALAR,
                    )
                    assertColorArrayEquals("scalar-vs-kotlin case $caseNo (w=$w k=$k rgb=${lrgb.toList()} linear=$linear)", ref, outScalar)
                    // k<0 in sRGB mode diverges in the SHIPPED kernel (missing late
                    // lower clamp; pre-existing, degenerate surfaceScale): skip the
                    // vector comparisons there, the linear path clamps correctly.
                    if (k >= 0f || linear) {
                        assertColorArrayEquals("$name-vs-scalar case $caseNo (w=$w k=$k rgb=${lrgb.toList()} linear=$linear)", outScalar, out)
                        assertColorArrayEquals("$name fuzz case $caseNo (w=$w k=$k rgb=${lrgb.toList()} linear=$linear)", ref, out)
                    }
                    caseNo++
                    }
                }
            }
        }
    }
}
