/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.filtering.parity

import hu.oandras.ksvg.filtering.ComponentTransferValidationCorpus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

/**
 * Host-side snapshot of the round-B transfer SVG builder: byte-stable
 * output plus `tableValues` float fidelity over every corpus table.
 */
@RunWith(JUnit4::class)
class ComponentTransferParitySvgTest {

    @Test
    fun tablesRoundTripEveryCorpusByte() {
        // Every corpus table byte must survive byte -> float-string ->
        // float -> byte. The CPU interpolator lands on the exact entry
        // because neighbors are integers and fp dust is ~1e-5; here we
        // prove the emission side is lossless.
        val tables = listOf(
            ComponentTransferValidationCorpus.identityTable,
            ComponentTransferValidationCorpus.reverseTable,
            ComponentTransferValidationCorpus.alphaTable,
            ComponentTransferValidationCorpus.redTable,
            ComponentTransferValidationCorpus.greenTable,
            ComponentTransferValidationCorpus.blueTable,
        )
        for (table in tables) {
            val parsed = ComponentTransferParitySvg.tableString(table)
                .split(' ').map { it.toFloat() }
            assertEquals(256, parsed.size)
            for (i in 0 until 256) {
                val expected = table[i].toInt() and 0xFF
                assertEquals(expected, (parsed[i] * 255f + 0.5f).toInt())
            }
        }
    }

    @Test
    fun subclipEmitsSubregionAndSrgb() {
        val zeros = ByteArray(256)
        val svg = ComponentTransferParitySvg.toSvg(
            width = 32,
            height = 32,
            tableA = zeros,
            tableR = zeros,
            tableG = zeros,
            tableB = zeros,
            clipLeft = 4,
            clipTop = 4,
            clipRight = 28,
            clipBottom = 28,
            imageDataUri = URI,
        )
        assertTrue(svg.contains("<feComponentTransfer x=\"4\" y=\"4\" width=\"24\" height=\"24\""))
        assertTrue(svg.contains("color-interpolation-filters=\"sRGB\""))
        assertTrue(svg.contains("filter=\"url(#f)\""))
    }

    @Test
    fun fullClipOmitsSubregion() {
        val zeros = ByteArray(256)
        val svg = ComponentTransferParitySvg.toSvg(
            width = 16,
            height = 16,
            tableA = zeros,
            tableR = zeros,
            tableG = zeros,
            tableB = zeros,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            imageDataUri = URI,
        )
        assertTrue(svg.contains("<feComponentTransfer color-interpolation-filters=\"sRGB\">"))
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
