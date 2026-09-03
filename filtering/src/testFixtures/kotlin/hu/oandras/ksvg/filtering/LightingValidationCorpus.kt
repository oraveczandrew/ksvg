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
 * Deterministic validation corpus for feDiffuseLighting / feSpecularLighting.
 */
public object LightingValidationCorpus {

    public class Case(
        public val name: String,
        public val width: Int,
        public val height: Int,
        public val clipLeft: Int,
        public val clipTop: Int,
        public val clipRight: Int,
        public val clipBottom: Int,
        public val surfaceScale: Float,
        public val invCanvasScaleX: Double,
        public val invCanvasScaleY: Double,
        public val userLeft: Double,
        public val userTop: Double,
        public val originX: Double,
        public val originY: Double,
        public val unitSizeX: Double,
        public val unitSizeY: Double,
        public val canvasScaleX: Float,
        public val canvasScaleY: Float,
        public val lightType: Int,
        public val specular: Boolean,
        public val k: Float,
        public val exponent: Float,
        public val lightR: Int,
        public val lightG: Int,
        public val lightB: Int,
        public val params: DoubleArray,
        public val premultiplied: Boolean,
        public val useLinear: Boolean,
        public val input: IntArray,
    ) {
        public val size: Int get() = width * height

        public fun reference(): IntArray {
            val out = IntArray(size)
            KotlinKernels.lighting(
                input, out, width, height,
                clipLeft, clipTop, clipRight, clipBottom,
                surfaceScale, invCanvasScaleX, invCanvasScaleY,
                userLeft, userTop, originX, originY,
                unitSizeX, unitSizeY,
                canvasScaleX, canvasScaleY,
                lightType, specular, k, exponent,
                lightR, lightG, lightB, params,
                premultiplied, useLinear
            )
            return out
        }
    }

    public val cases: List<Case> = buildList {
        // Distant light, diffuse
        add(Case("distant diffuse 16x16", 16, 16, 0, 0, 16, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 0, false, 1f, 1f, 255, 255, 255, doubleArrayOf(45.0, 45.0), false, false, 
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // Point light, specular
        add(Case("point specular 32x8", 32, 8, 0, 0, 32, 8, 5f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 1, true, 1f, 20f, 255, 255, 255, doubleArrayOf(16.0, 4.0, 50.0), false, false,
            UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8)))

        // Spot light, diffuse, linear
        add(Case("spot diffuse linear 16x16", 16, 16, 0, 0, 16, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 2, false, 1f, 1f, 255, 255, 255, doubleArrayOf(8.0, 8.0, 100.0, 8.0, 8.0, 0.0, 30.0), false, true,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Distant light, specular (exponent drives the specular falloff).
        add(Case("distant specular 16x16", 16, 16, 0, 0, 16, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 0, true, 1f, 20f, 255, 255, 255, doubleArrayOf(30.0, 60.0), false, false,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))

        // Point light, diffuse.
        add(Case("point diffuse 24x16", 24, 16, 0, 0, 24, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 1, false, 1f, 1f, 255, 255, 255, doubleArrayOf(12.0, 8.0, 50.0), false, true,
            UnLinearizeValidationCorpus.fixedSeedRandom(24 * 16)))

        // Spot light, specular, premultiplied output (no limiting cone -> NaN).
        add(Case("spot specular premult 16x16", 16, 16, 0, 0, 16, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 2, true, 1f, 20f, 255, 255, 255, doubleArrayOf(8.0, 8.0, 50.0, 0.0, 0.0, 0.0, Double.NaN), true, false,
            UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
    }
}
