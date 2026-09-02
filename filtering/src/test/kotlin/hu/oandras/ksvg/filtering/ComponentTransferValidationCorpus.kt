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

import kotlin.math.max
import kotlin.math.min

/**
 * Deterministic validation corpus for feComponentTransfer.
 */
public object ComponentTransferValidationCorpus {

    val boundarySizes: List<Int> = UnlinearizeValidationCorpus.boundarySizes
    val shapes: List<Pair<Int, Int>> = UnlinearizeValidationCorpus.shapes

    val identityTable = ByteArray(256) { it.toByte() }
    val reverseTable = ByteArray(256) { (255 - it).toByte() }
    val alphaTable = ByteArray(256) { ((it * 3) and 0xFF).toByte() } // Non-identity alpha
    val redTable = ByteArray(256) { ((it + 128) and 0xFF).toByte() }
    val greenTable = ByteArray(256) { (it / 2).toByte() }
    val blueTable = ByteArray(256) { ((it * it) shr 8).toByte() }

    data class Case(
        val name: String,
        val width: Int,
        val height: Int,
        val clipLeft: Int,
        val clipTop: Int,
        val clipRight: Int,
        val clipBottom: Int,
        val tableA: ByteArray,
        val tableR: ByteArray,
        val tableG: ByteArray,
        val tableB: ByteArray,
        val input: IntArray,
    ) {
        val size: Int get() = width * height

        fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.componentTransfer(
                input, out, width,
                clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB
            )
            return out
        }

        fun freshInput(): IntArray = input.copyOf()
    }

    val cases: List<Case> = buildList {
        // Full clip region
        for ((w, h) in listOf(32 to 8, 33 to 9, 16 to 1)) {
            add(Case("full $w x $h", w, h, 0, 0, w, h, 
                alphaTable, redTable, greenTable, blueTable, 
                UnlinearizeValidationCorpus.fixedSeedRandom(w * h)))
        }
        // Sub-clip region (crucial for component_transfer)
        add(Case("subclip 32x32", 32, 32, 4, 4, 28, 28,
            identityTable, identityTable, identityTable, identityTable,
            UnlinearizeValidationCorpus.fixedSeedRandom(32 * 32)))
        
        // Edge cases for clip
        add(Case("clip top-left 16x16", 16, 16, 0, 0, 8, 8,
            reverseTable, redTable, greenTable, blueTable,
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        add(Case("clip bottom-right 16x16", 16, 16, 8, 8, 16, 16,
            alphaTable, reverseTable, identityTable, blueTable,
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Non-SIMD boundary sizes
        for (pixels in boundarySizes.filter { it > 0 }) {
            add(Case("tail $pixels x 1", pixels, 1, 0, 0, pixels, 1,
                alphaTable, redTable, greenTable, blueTable,
                UnlinearizeValidationCorpus.fixedSeedRandom(pixels)))
        }
    }
}
