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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Byte-exact parity between the native `unlinearize.cpp` SIMD kernels and the
 * pure-Kotlin reference [KotlinKernels.unlinearize].
 *
 * Runs on the host JVM against a host-arch build of `libksvgblur` (the
 * `:filtering` test task builds it via `buildHostNativeLib`). Various buffer
 * shapes exercise the NEON/SSSE3/AVX2 vector tails, separate src/dst, and the
 * in-place (src == dst) path used by the filter-output transfer.
 */
@RunWith(Parameterized::class)
class UnlinearizeNativeParityTest(
    private val width: Int,
    private val height: Int,
    private val table: ByteArray,
    private val inPlace: Boolean,
    private val input: IntArray,
) {
    companion object {
        init {
            System.loadLibrary("ksvgblur")
        }

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> {
            val real = KotlinKernels.UN_LINEARIZE
            // Stepping table mirrors component transfer's parity coverage: pure
            // revision of the 16-row gather scheme (NEON/SSSE3/armv7 selection).
            val stepping = ByteArray(256) { ((it * 7) and 0xFF).toByte() }
            // Input that guarantees every 8-bit index appears in each colour channel
            // (catches any single-byte LUT gather bug across all 256 indices).
            val full = fullCoverage(64, 4)
            return listOf(
                // SIMD-aligned (16/8/4-px lane) full buffers.
                arrayOf(32, 8, real, false, pattern(32, 8, 89)),
                arrayOf(16, 16, real, false, fullCoverage(16, 16)),
                // Odd tails to hit the scalar remainder of every vector loop.
                arrayOf(33, 9, real, false, fullCoverage(33, 9)),
                arrayOf(5, 7, real, false, full),
                // In-place (src == dst) — the path the pipeline uses.
                arrayOf(36, 10, real, true, fullCoverage(36, 10)),
                arrayOf(13, 3, real, true, pattern(13, 3, 21)),
                // Non-identity table; alpha passthrough still holds.
                arrayOf(20, 20, stepping, false, fullCoverage(20, 20)),
            )
        }
    }

    @Test
    fun nativeMatchesKotlin() {
        assertTrue("libksvgblur not loadable on the host JVM", UnlinearizeNative.isAvailable)

        val src = input
        val ref = IntArray(width * height)
        val native = IntArray(width * height)

        KotlinKernels.unlinearize(src, ref, width, height, table)

        if (inPlace) {
            // Exercise the JNI in-place (src==dst) path: copy src into native, run in-place.
            System.arraycopy(src, 0, native, 0, src.size)
            SoftwareKernels.unlinearize(native, native, width, height, table)
        } else {
            SoftwareKernels.unlinearize(src, native, width, height, table)
        }

        assertArrayEquals("unlinearize mismatch (${width}x$height, inPlace=$inPlace)", ref, native)
    }

    /**
     * Explicit alpha-preservation contract across all 256 alpha values: the native
     * kernel must leave the alpha byte untouched regardless of what the table does.
     * Runs every alpha 0..255 over a fixed RGB set, comparing native vs Kotlin.
     */
    @Test
    fun nativePreservesAllAlphaValues() {
        assertTrue("libksvgblur not loadable on the host JVM", UnlinearizeNative.isAvailable)

        val width = 16
        val height = 16
        val src = fullCoverage(width, height) // alpha = i & 0xFF covers 0..255
        val ref = IntArray(width * height)
        val native = IntArray(width * height)

        KotlinKernels.unlinearize(src, ref, width, height, KotlinKernels.UN_LINEARIZE)
        SoftwareKernels.unlinearize(src, native, width, height, KotlinKernels.UN_LINEARIZE)

        assertArrayEquals("alpha preservation mismatch", ref, native)
        for (i in src.indices) {
            assertEquals(
                "alpha byte must pass through at $i",
                (src[i] ushr 24) and 0xFF,
                (native[i] ushr 24) and 0xFF
            )
        }
    }
}
