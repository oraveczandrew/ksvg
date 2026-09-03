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
 * Deterministic validation corpus for feDisplacementMap.
 */
object DisplacementMapValidationCorpus {

    class Case(
        val name: String,
        val width: Int,
        val height: Int,
        val mapWidth: Int,
        val mapHeight: Int,
        val scale: Float,
        val xChannel: Int,
        val yChannel: Int,
        val src: IntArray,
        val map: IntArray,
    ) {
        val size: Int get() = width * height

        fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.displacementMap(
                src, map, out, width, height, mapWidth, mapHeight,
                scale, xChannel, yChannel
            )
            return out
        }
    }

    val cases: List<Case> = buildList {
        // Full size match
        add(Case("match 16x16", 16, 16, 16, 16, 10f, 0, 1, 
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16).reversedArray()))
        
        // Different map size (routes to scalar)
        add(Case("different 32x8", 32, 8, 16, 4, 20f, 2, 3,
            UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8),
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 4)))

        // Large scale
        add(Case("large scale 16x16", 16, 16, 16, 16, 100f, 1, 2,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Negative scale (displacement directions invert).
        add(Case("negative scale 16x16", 16, 16, 16, 16, -5f, 1, 1,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Identity scale zero: pixels land unshifted (R, R channel).
        add(Case("identity 16x16", 16, 16, 16, 16, 0f, 0, 0,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
    }
}
