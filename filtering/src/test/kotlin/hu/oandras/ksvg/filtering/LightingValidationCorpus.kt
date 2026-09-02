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

    data class Case(
        val name: String,
        val width: Int,
        val height: Int,
        val clipLeft: Int,
        val clipTop: Int,
        val clipRight: Int,
        val clipBottom: Int,
        val surfaceScale: Float,
        val invCanvasScaleX: Double,
        val invCanvasScaleY: Double,
        val userLeft: Double,
        val userTop: Double,
        val originX: Double,
        val originY: Double,
        val unitSizeX: Double,
        val unitSizeY: Double,
        val canvasScaleX: Float,
        val canvasScaleY: Float,
        val lightType: Int,
        val specular: Boolean,
        val k: Float,
        val exponent: Float,
        val lightR: Int,
        val lightG: Int,
        val lightB: Int,
        val params: DoubleArray,
        val premultiplied: Boolean,
        val useLinear: Boolean,
        val input: IntArray,
    ) {
        val size: Int get() = width * height

        fun reference(): IntArray {
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

    val cases: List<Case> = buildList {
        // Distant light, diffuse
        add(Case("distant diffuse 16x16", 16, 16, 0, 0, 16, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 0, false, 1f, 1f, 255, 255, 255, doubleArrayOf(45.0, 45.0), false, false, 
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
        
        // Point light, specular
        add(Case("point specular 32x8", 32, 8, 0, 0, 32, 8, 5f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 1, true, 1f, 20f, 255, 255, 255, doubleArrayOf(16.0, 4.0, 50.0), false, false,
            UnlinearizeValidationCorpus.fixedSeedRandom(32 * 8)))

        // Spot light, diffuse, linear
        add(Case("spot diffuse linear 16x16", 16, 16, 0, 0, 16, 16, 1f, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1f, 1f, 2, false, 1f, 1f, 255, 255, 255, doubleArrayOf(8.0, 8.0, 100.0, 8.0, 8.0, 0.0, 30.0), false, true,
            UnlinearizeValidationCorpus.fixedSeedRandom(16 * 16)))
    }
}
