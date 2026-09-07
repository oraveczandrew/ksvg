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
import org.junit.Assert.assertEquals
import org.junit.Assume.assumeTrue
import org.junit.BeforeClass
import org.junit.Test
import kotlin.random.Random

/**
 * Mandated correctness gate for the experimental SSSE3 assembly layout variants
 * [UnLinearizeNative.applySsse3Variant] (0 = vA committed baseline, 1 = vB
 * 16 px/4-vector no-stack, 2 = vC 8 px/2-vector):
 *
 *  - random 256-entry LUTs (also the identity/stepping production tables),
 *    random pixel data covering every channel value, random widths/heights;
 *  - total sizes NOT divisible by 4 and NOT divisible by 16 (vector tail);
 *  - both src != dst and in-place src == dst;
 *  - a LUT that is a general permutation/bijection-free random map — never a
 *    monotonic/approximable assumption.
 *
 * Every variant must be byte-exact with [KotlinKernels.unLinearize] (the same
 * oracle the shared parity suite uses). This test exists only where the host
 * libksvgblur is loaded (KSSVG_HOST_BUILD); elsewhere it is skipped.
 */
class UnLinearizeVariantCorrectnessTest {

    companion object {
        /** [UnLinearizeNative.applySsse3Variant] variant ids. */
        const val VAR_A = 0
        const val VAR_B = 1
        const val VAR_C = 2

        @BeforeClass
        @JvmStatic
        fun setup() {
            // Assumption is evaluated per-test, but prove the lib is loadable once.
            assumeTrue("NativeBackend not available on this host JVM", NativeBackend.isAvailable)
            assertNativeBackendAvailable()
        }

        private fun randomTable(seed: Int): ByteArray =
            ByteArray(256) { Random(seed * 31 + it).nextInt(0, 256).toByte() }
    }

    // Case list helper. Each entry: (label, width, height, table, inputKind).
    private fun cases(): List<Array<Any?>> = buildList {
        val rng = Random(0xC0FFEE)
        run {
            // Flat pixel counts around every vector width and its scalar tail,
            // including non-multiples of 4 and of 16.
            val flatSizes = intArrayOf(
                0, 1, 2, 3, 4, 5, 7, 8, 9, 11, 15, 16, 17, 19,
                23, 31, 32, 33, 47, 63, 64, 65, 95, 127, 128, 129,
                255, 256, 257, 511, 512, 1003, 4097,
            )
            for (pixels in flatSizes) {
                add(arrayOf("flat $pixels px", pixels, 1, randomTable(rng.nextInt()), "random"))
            }
            // Image shapes whose WIDTH is not divisible by 4 or by 16.
            val shapes = arrayOf(
                1 to 1, 1 to 5, 2 to 3, 3 to 3, 3 to 7, 5 to 5, 7 to 3,
                9 to 9, 11 to 2, 23 to 5, 37 to 13, 61 to 7, 5 to 16,
                16 to 5, 33 to 9, 65 to 33, 7 to 129, 129 to 7,
            )
            for ((w, h) in shapes) {
                add(arrayOf("shape ${w}x$h", w, h, randomTable(rng.nextInt()), "random"))
            }
            // Deterministic structured inputs over random and production LUTs.
            for ((w, h) in listOf(17 to 3, 9 to 9, 5 to 7, 4 to 4, 16 to 16)) {
                add(arrayOf("coverage ${w}x$h", w, h, randomTable(rng.nextInt()), "coverage"))
                add(arrayOf("step ${w}x$h", w, h, UnLinearizeValidationCorpus.steppingTable, "coverage"))
            }
        }
    }

    @Test
    fun variantsAreByteExactVsKotlin() {
        for (case in cases()) {
            val label = case[0] as String
            val width = case[1] as Int
            val height = case[2] as Int
            val table = case[3] as ByteArray
            val input = when (case[4] as String) {
                "coverage" -> UnLinearizeValidationCorpus.exhaustiveLut(width * height)
                else -> UnLinearizeValidationCorpus.fixedSeedRandom(width * height)
            }

            val ref = IntArray(width * height)
            KotlinKernels.unLinearize(input, ref, width, height, table)

            for (variant in intArrayOf(VAR_A, VAR_B, VAR_C)) {
                // Out-of-place.
                val outOfPlace = IntArray(width * height)
                UnLinearizeNative.applySsse3Variant(input, outOfPlace, width, height, table, variant)
                assertArrayEquals(
                    "out-of-place $label variant=$variant",
                    ref, outOfPlace,
                )
                // In-place (src == dst) — the pipeline path.
                val inPlace = input.copyOf()
                UnLinearizeNative.applySsse3Variant(inPlace, inPlace, width, height, table, variant)
                assertArrayEquals(
                    "in-place $label variant=$variant",
                    ref, inPlace,
                )
            }
        }
    }

    /**
     * Random LUT, all 256 values in every channel: alpha must still pass through
     * untouched even though the LUT maps the alpha byte to arbitrary garbage.
     */
    @Test
    fun alphaPassesThroughOnRandomLut() {
        for (variant in intArrayOf(VAR_B, VAR_C)) {
            val table = randomTable(0xABCDEF)
            val src = UnLinearizeValidationCorpus.allAlpha(16 * 16) // alpha = i & 0xFF, 0..255
            val out = IntArray(src.size)
            UnLinearizeNative.applySsse3Variant(src, out, 16, 16, table, variant)
            for (i in src.indices) {
                assertEquals(
                    "alpha byte must pass through on variant=$variant at $i",
                    (src[i] ushr 24) and 0xFF,
                    (out[i] ushr 24) and 0xFF,
                )
            }
        }
    }

    @Test
    fun largeBufferIsByteExact() {
        val width = 17
        val height = 4017 // 68,289 px: many vector iterations + odd tail, width not divisible by 4/16
        val total = width * height
        val table = randomTable(42)
        val src = UnLinearizeValidationCorpus.fixedSeedRandom(total)

        val ref = IntArray(total)
        KotlinKernels.unLinearize(src, ref, width, height, table)

        for (variant in intArrayOf(VAR_A, VAR_B, VAR_C)) {
            val out = src.copyOf()
            UnLinearizeNative.applySsse3Variant(out, out, width, height, table, variant)
            assertArrayEquals("large 17x4017 variant=$variant", ref, out)
        }
    }
}