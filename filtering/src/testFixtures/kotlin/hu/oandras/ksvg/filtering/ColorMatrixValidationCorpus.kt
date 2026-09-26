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

package hu.oandras.ksvg.filtering

/**
 * Deterministic validation corpus for feColorMatrix (4x5 matrix in SVG 0..1
 * semantics, covering every lowered type: identity/matrix/saturate/hueRotate/
 * luminanceToAlpha plus offset and alpha-row variants).
 */
public object ColorMatrixValidationCorpus {

    public class Case(
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
        public val matrix: FloatArray,
        @JvmField
        public val useLinear: Boolean,
        @JvmField
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.colorMatrix(
                input, out, width,
                clipLeft, clipTop, clipRight, clipBottom,
                matrix, useLinear
            )
            return out
        }
    }

    private fun identity(): FloatArray = FloatArray(20).also {
        it[0] = 1f; it[6] = 1f; it[12] = 1f; it[18] = 1f
    }

    private fun thirdMatrix(): FloatArray = FloatArray(20).also {
        for (row in 0..2) for (col in 0..2) it[row * 5 + col] = 0.33f
        it[18] = 1f
    }

    private fun saturate(s: Float): FloatArray = floatArrayOf(
        0.213f + 0.787f * s, 0.715f - 0.715f * s, 0.072f - 0.072f * s, 0f, 0f,
        0.213f - 0.213f * s, 0.715f + 0.285f * s, 0.072f - 0.072f * s, 0f, 0f,
        0.213f - 0.213f * s, 0.715f - 0.715f * s, 0.072f + 0.928f * s, 0f, 0f,
        0f, 0f, 0f, 1f, 0f
    )

    private fun hueRotate90(): FloatArray {
        // createHueRotateMatrix(90): cos=0, sin=1, weights 0.2127/0.7151/0.0722.
        val r = 0.2127f
        val g = 0.7151f
        val b = 0.0722f
        return floatArrayOf(
            r, g, b + (1f - b), 0f, 0f,
            r + 0.143f, g + 0.140f, b - 0.283f, 0f, 0f,
            r - (1f - r), g + g, b + b, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
        )
    }

    private fun luminanceToAlpha(): FloatArray = floatArrayOf(
        0f, 0f, 0f, 0f, 0f,
        0f, 0f, 0f, 0f, 0f,
        0f, 0f, 0f, 0f, 0f,
        0.2127f, 0.7151f, 0.0722f, 0f, 0f
    )

    private fun withBias(): FloatArray = identity().also {
        it[4] = 0.1f; it[9] = -0.2f; it[14] = 0.05f; it[19] = 0.5f
    }

    private fun alphaFromRed(): FloatArray = identity().also {
        it[15] = 1f; it[18] = 0f
    }

    @JvmField
    public val cases: List<Case> = buildList {
        val matrices = listOf(
            "identity" to identity(),
            "third" to thirdMatrix(),
            "saturate0" to saturate(0f),
            "saturate2" to saturate(2f),
            "hueRotate90" to hueRotate90(),
            "luminanceToAlpha" to luminanceToAlpha(),
            "bias" to withBias(),
            "alphaFromRed" to alphaFromRed(),
        )
        for (useLinear in listOf(false, true)) {
            val space = if (useLinear) "linear" else "sRGB"
            for ((name, matrix) in matrices) {
                add(Case("$name $space 16x16", 16, 16, 0, 0, 16, 16, matrix, useLinear,
                    UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
                add(Case("$name $space subclip 32x32", 32, 32, 4, 4, 28, 28, matrix, useLinear,
                    UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32)))
                // Odd widths exercise the vector tail + scalar tail.
                add(Case("$name $space odd 10x10", 10, 10, 0, 0, 10, 10, matrix, useLinear,
                    UnLinearizeValidationCorpus.fixedSeedRandom(10 * 10)))
                add(Case("$name $space odd-subclip 30x30", 30, 30, 3, 5, 26, 27, matrix, useLinear,
                    UnLinearizeValidationCorpus.fixedSeedRandom(30 * 30)))
            }
        }
    }
}
