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

    public data class Case(
        @JvmField
        public val name: String,
        @JvmField
        public val width: Int,
        @JvmField
        public val height: Int,
        @JvmField
        public val clipLeft: Int,
        @JvmField
        public val clipTop: Int,
        @JvmField
        public val clipRight: Int,
        @JvmField
        public val clipBottom: Int,
        @JvmField
        public val baseFrequencyX: Double,
        @JvmField
        public val baseFrequencyY: Double,
        @JvmField
        public val periodX: Int,
        @JvmField
        public val periodY: Int,
        @JvmField
        public val octaves: Int,
        @JvmField
        public val fractalNoise: Boolean,
        @JvmField
        public val invCanvasScaleX: Double,
        @JvmField
        public val invCanvasScaleY: Double,
        @JvmField
        public val userLeft: Double,
        @JvmField
        public val userTop: Double,
        @JvmField
        public val originX: Double,
        @JvmField
        public val originY: Double,
        @JvmField
        public val unitSizeX: Double,
        @JvmField
        public val unitSizeY: Double,
        @JvmField
        public val seed: Int,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
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
                userLeft, userTop,
                unitSizeX, unitSizeY, seed, generators
            )
            return out
        }
    }

    @JvmField
    public val cases: List<Case> = buildList {
        // Basic noise
        add(Case("noise 16x16", 16, 16, 0, 0, 16, 16, 0.05, 0.05, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0))

        // Fractal noise with octaves
        add(Case("fractal octaves 32x8", 32, 8, 0, 0, 32, 8, 0.1, 0.1, 0, 0, 3, true, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 123))

        // Stitching
        add(Case("stitch 16x16", 16, 16, 0, 0, 16, 16, 0.1, 0.1, 10, 10, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 456))

        // Sub-clip
        add(Case("subclip 32x32", 32, 32, 4, 4, 28, 28, 0.05, 0.05, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 789))

        // Single octave, no stitching.
        add(Case("plain", 64, 64, 0, 0, 64, 64, 0.05, 0.05, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 7))

        // Fractal noise, multiple octaves.
        add(Case("fractal4", 64, 64, 0, 0, 64, 64, 0.08, 0.06, 0, 0, 4, true, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 42))

        // Anisotropic / sub-rectangle clip region (transparent fill outside).
        add(Case("clip", 96, 80, 12, 8, 84, 72, 0.03, 0.05, 0, 0, 2, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1234))

        // Non-integer origin / anchor + non-unit primitive units.
        add(Case("fractional", 50, 50, 0, 0, 50, 50, 0.1, 0.1, 0, 0, 1, true, 1.0, 1.0, 3.5, -1.25, 2.0, 7.5, 0.75, 1.25, 3))

        // Stitch tiles: whole lattice periods so edges wrap seamlessly.
        add(Case("stitch tiles 128x128", 128, 128, 0, 0, 128, 128, 0.02, 0.02, 7, 9, 1, true, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 99))

        // Downscaled canvas (canvas scale 2.0 -> frequency doubles in user space).
        add(Case("scaled", 32, 32, 0, 0, 32, 32, 0.05, 0.05, 0, 0, 3, false, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 55))

        // Near-zero frequency: lattice coordinates just above +4096 (origin is
        // exactly an integer cell corner). Lattice coords stay >= 0, so the
        // native floor() and the Kotlin tx.toInt() lattice index agree.
        add(Case("nearzero 32x32", 32, 32, 0, 0, 32, 32, 0.001, 0.001, 0, 0, 1, false, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 321))
    }
}
