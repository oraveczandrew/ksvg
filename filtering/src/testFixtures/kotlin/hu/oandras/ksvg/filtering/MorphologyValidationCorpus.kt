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
 * Deterministic validation corpus for feMorphology.
 */
public object MorphologyValidationCorpus {

    public val boundarySizes: IntArray = UnLinearizeValidationCorpus.boundarySizes
    public val shapes: Array<Pair<Int, Int>> = UnLinearizeValidationCorpus.shapes

    public class Case(
        public val name: String,
        public val width: Int,
        public val height: Int,
        public val radiusX: Int,
        public val radiusY: Int,
        public val erode: Boolean,
        public val clipLeft: Int,
        public val clipTop: Int,
        public val clipRight: Int,
        public val clipBottom: Int,
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.morphology(
                input, out, width, height,
                radiusX, radiusY, erode,
                clipLeft, clipTop, clipRight, clipBottom
            )
            return out
        }

        public fun freshInput(): IntArray = input.copyOf()
    }

    public val cases: List<Case> = buildList {
        // Erode and Dilate over various shapes
        for (erode in listOf(true, false)) {
            val op = if (erode) "erode" else "dilate"
            
            // Typical small radius
            add(Case("$op 1x1 16x16", 16, 16, 1, 1, erode, 0, 0, 16, 16,
                UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
            
            // Asymmetric radius
            add(Case("$op 3x1 32x8", 32, 8, 3, 1, erode, 0, 0, 32, 8,
                UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8)))

            // Boundary cases (radius larger than image)
            add(Case("$op 10x10 5x5", 5, 5, 10, 10, erode, 0, 0, 5, 5,
                UnLinearizeValidationCorpus.fixedSeedRandom(5 * 5)))

            // Sub-clip region
            add(Case("$op 2x2 subclip 32x32", 32, 32, 2, 2, erode, 4, 4, 28, 28,
                UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32)))
            
            // Boundary/tail pixel counts
            for (pixels in boundarySizes.filter { it > 0 }) {
                add(Case("$op 1x1 tail $pixels x 1", pixels, 1, 1, 1, erode, 0, 0, pixels, 1,
                    UnLinearizeValidationCorpus.fixedSeedRandom(pixels)))
            }
        }
    }
}
