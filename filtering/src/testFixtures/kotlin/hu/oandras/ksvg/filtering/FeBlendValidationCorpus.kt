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
 * Deterministic validation corpus for feBlend (all non-normal modes).
 * Mode values are [FeBlendMode] constants.
 */
public object FeBlendValidationCorpus {

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
        @FeBlendMode
        public val mode: Int,
        @JvmField
        public val useLinear: Boolean,
        @JvmField
        public val input: IntArray,
        @JvmField
        public val input2: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.feBlend(
                input, input2, out, width,
                clipLeft, clipTop, clipRight, clipBottom,
                mode, useLinear
            )
            return out
        }
    }

    private fun modeName(mode: Int): String = when (mode) {
        FeBlendMode.MULTIPLY -> "multiply"
        FeBlendMode.SCREEN -> "screen"
        FeBlendMode.OVERLAY -> "overlay"
        FeBlendMode.DARKEN -> "darken"
        FeBlendMode.LIGHTEN -> "lighten"
        FeBlendMode.COLOR_DODGE -> "color-dodge"
        FeBlendMode.COLOR_BURN -> "color-burn"
        FeBlendMode.HARD_LIGHT -> "hard-light"
        FeBlendMode.SOFT_LIGHT -> "soft-light"
        FeBlendMode.DIFFERENCE -> "difference"
        FeBlendMode.EXCLUSION -> "exclusion"
        FeBlendMode.HUE -> "hue"
        FeBlendMode.SATURATION -> "saturation"
        FeBlendMode.COLOR -> "color"
        else -> "luminosity"
    }

    @JvmField
    public val cases: List<Case> = buildList {
        val modes = listOf(
            FeBlendMode.MULTIPLY, FeBlendMode.SCREEN, FeBlendMode.OVERLAY,
            FeBlendMode.DARKEN, FeBlendMode.LIGHTEN, FeBlendMode.COLOR_DODGE,
            FeBlendMode.COLOR_BURN, FeBlendMode.HARD_LIGHT, FeBlendMode.SOFT_LIGHT,
            FeBlendMode.DIFFERENCE, FeBlendMode.EXCLUSION, FeBlendMode.HUE,
            FeBlendMode.SATURATION, FeBlendMode.COLOR, FeBlendMode.LUMINOSITY,
        )
        for (useLinear in listOf(false, true)) {
            val space = if (useLinear) "linear" else "sRGB"
            for (mode in modes) {
                val name = modeName(mode)
                // Random translucent pair, full clip.
                add(Case("$name $space 16x16", 16, 16, 0, 0, 16, 16, mode, useLinear,
                    UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
                    UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16).reversedArray()))
                // Random pair, sub-clip region.
                add(Case("$name $space subclip 32x32", 32, 32, 4, 4, 28, 28, mode, useLinear,
                    UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32),
                    UnLinearizeValidationCorpus.fixedSeedRandom(32 * 32).reversedArray()))
            }
        }
        // Alpha edges: fully transparent pair, opaque pair, transparent backdrop.
        add(Case("multiply transparent 8x8", 8, 8, 0, 0, 8, 8, FeBlendMode.MULTIPLY, true,
            IntArray(64), IntArray(64)))
        add(Case("multiply opaque 8x8", 8, 8, 0, 0, 8, 8, FeBlendMode.MULTIPLY, true,
            IntArray(64) { 0xFF00FFFF.toInt() }, IntArray(64) { 0xFFFF0000.toInt() }))
        add(Case("screen transparent-backdrop 8x8", 8, 8, 0, 0, 8, 8, FeBlendMode.SCREEN, true,
            IntArray(64) { 0xFF00FFFF.toInt() }, IntArray(64)))
    }
}
