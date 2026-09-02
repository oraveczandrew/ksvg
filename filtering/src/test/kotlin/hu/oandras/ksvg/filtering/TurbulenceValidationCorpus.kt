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
 * Deterministic validation corpus for feTurbulence.
 */
public object TurbulenceValidationCorpus {

    data class Case(
        val name: String,
        val width: Int,
        val height: Int,
        val clipLeft: Int,
        val clipTop: Int,
        val clipRight: Int,
        val clipBottom: Int,
        val baseFrequencyX: Double,
        val baseFrequencyY: Double,
        val periodX: Int,
        val periodY: Int,
        val octaves: Int,
        val fractalNoise: Boolean,
        val invCanvasScaleX: Double,
        val invCanvasScaleY: Double,
        val userLeft: Double,
        val userTop: Double,
        val originX: Double,
        val originY: Double,
        val unitSizeX: Double,
        val unitSizeY: Double,
        val seed: Int,
    ) {
        val size: Int get() = width * height

        fun reference(): IntArray {
            val out = IntArray(size)
            val lcg = LcgRandom(seed)
            val p = IntArray(SvgPathNoise.LATTICE_SIZE)
            val generators = Array(4) { SvgPathNoise(lcg, p) }
            SvgPathNoise.buildPermutation(lcg, p)

            KotlinKernels.turbulence(
                out, width, height,
                clipLeft, clipTop, clipRight, clipBottom,
                baseFrequencyX, baseFrequencyY,
                periodX, periodY, octaves, fractalNoise,
                invCanvasScaleX, invCanvasScaleY,
                userLeft, userTop, originX, originY,
                unitSizeX, unitSizeY, seed, generators
            )
            return out
        }
    }

    val cases: List<Case> = buildList {
        // Basic noise
        add(Case("noise 16x16", 16, 16, 0, 0, 16, 16, 0.05, 0.05, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0))
        
        // Fractal noise with octaves
        add(Case("fractal octaves 32x8", 32, 8, 0, 0, 32, 8, 0.1, 0.1, 0, 0, 3, true, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 123))

        // Stitching
        add(Case("stitch 16x16", 16, 16, 0, 0, 16, 16, 0.1, 0.1, 10, 10, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 456))

        // Sub-clip
        add(Case("subclip 32x32", 32, 32, 4, 4, 28, 28, 0.05, 0.05, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 789))
    }
}
