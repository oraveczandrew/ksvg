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

import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Device-side parity check: the native feComponentTransfer kernel must produce
 * output bit-identical to the reference scalar loop used as the JVM/unit-test
 * fallback (`doComponentTransferKotlin` semantics).
 */
class ComponentTransferNativeDeviceTest {

    private fun referenceLoop(
        src: IntArray,
        dst: IntArray,
        width: Int,
        height: Int,
        clipL: Int,
        clipT: Int,
        clipR: Int,
        clipB: Int,
        tables: Array<ByteArray>,
    ) {
        val (tableA, tableR, tableG, tableB) = tables
        dst.fill(0)
        for (y in clipT until clipB) {
            val rowOffset = y * width
            for (x in clipL until clipR) {
                val c = src[rowOffset + x]
                dst[rowOffset + x] =
                    ((tableA[(c ushr 24) and 0xFF].toInt() and 0xFF) shl 24) or
                        ((tableR[(c ushr 16) and 0xFF].toInt() and 0xFF) shl 16) or
                        ((tableG[(c ushr 8) and 0xFF].toInt() and 0xFF) shl 8) or
                        (tableB[c and 0xFF].toInt() and 0xFF)
            }
        }
    }

    @Test
    fun nativeMatchesReferenceOnRandomPixels() {
        assertTrue("libksvgblur must be loadable on device", ComponentTransferNative.isAvailable)

        val width = 37 // deliberately not a multiple of 4/8/16
        val height = 23
        val clipL = 5
        val clipT = 3
        val clipR = 31
        val clipB = 19

        val src = IntArray(width * height) { i ->
            // Deterministic pseudo-random ARGB including fully transparent pixels.
            var v = i * 2654435761L.toInt()
            v = v xor (v shr 13)
            v = v xor (v shr 17)
            if (i % 7 == 0) v and 0x00FFFFFF else v
        }
        val tables = Array(4) { ch ->
            ByteArray(256) { v ->
                if (ch == 0) ((v * 220) / 255).toByte() else ((255 - v)).toByte()
            }
        }

        val expected = IntArray(width * height)
        referenceLoop(src, expected, width, height, clipL, clipT, clipR, clipB, tables)

        val actual = IntArray(width * height)
        ComponentTransferNative.apply(
            src, actual, width, height, clipL, clipT, clipR, clipB,
            tables[0], tables[1], tables[2], tables[3]
        )

        for (i in actual.indices) {
            assertTrue(
                "Pixel $i mismatch: expected=${expected[i].toUInt()} actual=${actual[i].toUInt()}",
                expected[i] == actual[i]
            )
        }
    }
}
