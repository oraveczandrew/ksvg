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

/**
 * Deterministic validation corpus for feComponentTransfer.
 */
public object ComponentTransferValidationCorpus {

    public val boundarySizes: IntArray = UnLinearizeValidationCorpus.boundarySizes
    public val shapes: Array<Pair<Int, Int>> = UnLinearizeValidationCorpus.shapes

    public val identityTable: ByteArray = ByteArray(256) { it.toByte() }
    public val reverseTable: ByteArray = ByteArray(256) { (255 - it).toByte() }
    public val alphaTable: ByteArray = ByteArray(256) { ((it * 3) and 0xFF).toByte() }
    public val redTable: ByteArray = ByteArray(256) { ((it + 128) and 0xFF).toByte() }
    public val greenTable: ByteArray = ByteArray(256) { (it / 2).toByte() }
    public val blueTable: ByteArray = ByteArray(256) { ((it * it) shr 8).toByte() }

    private fun toIntTable(table: ByteArray, shift: Int): IntArray {
        return IntArray(256) { (table[it].toInt() and 0xFF) shl shift }
    }

    public class Case(
        public val name: String,
        public val width: Int,
        public val height: Int,
        public val clipLeft: Int,
        public val clipTop: Int,
        public val clipRight: Int,
        public val clipBottom: Int,
        public val tableA: IntArray,
        public val tableR: IntArray,
        public val tableG: IntArray,
        public val tableB: IntArray,
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.componentTransfer(
                input, out, width,
                clipLeft, clipTop, clipRight, clipBottom,
                tableA, tableR, tableG, tableB
            )
            return out
        }

        public fun freshInput(): IntArray = input.copyOf()
    }

    private fun createCase(
        name: String,
        width: Int,
        height: Int,
        clipLeft: Int,
        clipTop: Int,
        clipRight: Int,
        clipBottom: Int,
        tableA: ByteArray,
        tableR: ByteArray,
        tableG: ByteArray,
        tableB: ByteArray,
        input: IntArray
    ): Case = Case(
        name, width, height, clipLeft, clipTop, clipRight, clipBottom,
        toIntTable(tableA, 24), toIntTable(tableR, 16), toIntTable(tableG, 8), toIntTable(tableB, 0),
        input
    )

    public val cases: List<Case> = buildList {
        // Full clip region
        for ((w, h) in listOf(32 to 8, 33 to 9, 16 to 1)) {
            add(createCase("full $w x $h", w, h, 0, 0, w, h, 
                alphaTable, redTable, greenTable, blueTable, 
                UnLinearizeValidationCorpus.fixedSeedRandom(w * h)))
        }
        // Sub-clip region (crucial for component_transfer)
        add(createCase("subclip 32x32", 32, 32, 4, 4, 28, 28,
            identityTable, identityTable, identityTable, identityTable,
            UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32)))
        
        // Edge cases for clip
        add(createCase("clip top-left 16x16", 16, 16, 0, 0, 8, 8,
            reverseTable, redTable, greenTable, blueTable,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        add(createCase("clip bottom-right 16x16", 16, 16, 8, 8, 16, 16,
            alphaTable, reverseTable, identityTable, blueTable,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Non-SIMD boundary sizes
        for (pixels in boundarySizes.filter { it > 0 }) {
            add(createCase("tail $pixels x 1", pixels, 1, 0, 0, pixels, 1,
                alphaTable, redTable, greenTable, blueTable,
                UnLinearizeValidationCorpus.fixedSeedRandom(pixels)))
        }
    }
}
