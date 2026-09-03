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
        add(Case(
            name = "distant diffuse 16x16",
            width = 16,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            surfaceScale = 1f,
            invCanvasScaleX = 1.0,
            invCanvasScaleY = 1.0,
            userLeft = 0.0,
            userTop = 0.0,
            originX = 0.0,
            originY = 0.0,
            unitSizeX = 1.0,
            unitSizeY = 1.0,
            canvasScaleX = 1f,
            canvasScaleY = 1f,
            lightType = 0,
            specular = false,
            k = 1f,
            exponent = 1f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(45.0, 45.0),
            premultiplied = false,
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
        ))

        // Point light, specular
        add(Case(
            name = "point specular 32x8",
            width = 32,
            height = 8,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 32,
            clipBottom = 8,
            surfaceScale = 5f,
            invCanvasScaleX = 1.0,
            invCanvasScaleY = 1.0,
            userLeft = 0.0,
            userTop = 0.0,
            originX = 0.0,
            originY = 0.0,
            unitSizeX = 1.0,
            unitSizeY = 1.0,
            canvasScaleX = 1f,
            canvasScaleY = 1f,
            lightType = 1,
            specular = true,
            k = 1f,
            exponent = 20f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(16.0, 4.0, 50.0),
            premultiplied = false,
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8)
        ))

        // Spot light, diffuse, linear
        add(Case(
            name = "spot diffuse linear 16x16",
            width = 16,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            surfaceScale = 1f,
            invCanvasScaleX = 1.0,
            invCanvasScaleY = 1.0,
            userLeft = 0.0,
            userTop = 0.0,
            originX = 0.0,
            originY = 0.0,
            unitSizeX = 1.0,
            unitSizeY = 1.0,
            canvasScaleX = 1f,
            canvasScaleY = 1f,
            lightType = 2,
            specular = false,
            k = 1f,
            exponent = 1f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(8.0, 8.0, 100.0, 8.0, 8.0, 0.0, 30.0),
            premultiplied = false,
            useLinear = true,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
        ))

        // Distant light, specular (exponent drives the specular falloff).
        add(Case(
            name = "distant specular 16x16",
            width = 16,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            surfaceScale = 1f,
            invCanvasScaleX = 1.0,
            invCanvasScaleY = 1.0,
            userLeft = 0.0,
            userTop = 0.0,
            originX = 0.0,
            originY = 0.0,
            unitSizeX = 1.0,
            unitSizeY = 1.0,
            canvasScaleX = 1f,
            canvasScaleY = 1f,
            lightType = 0,
            specular = true,
            k = 1f,
            exponent = 20f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(30.0, 60.0),
            premultiplied = false,
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
        ))

        // Point light, diffuse.
        add(Case(
            name = "point diffuse 24x16",
            width = 24,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 24,
            clipBottom = 16,
            surfaceScale = 1f,
            invCanvasScaleX = 1.0,
            invCanvasScaleY = 1.0,
            userLeft = 0.0,
            userTop = 0.0,
            originX = 0.0,
            originY = 0.0,
            unitSizeX = 1.0,
            unitSizeY = 1.0,
            canvasScaleX = 1f,
            canvasScaleY = 1f,
            lightType = 1,
            specular = false,
            k = 1f,
            exponent = 1f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(12.0, 8.0, 50.0),
            premultiplied = false,
            useLinear = true,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(24 * 16)
        ))

        // Spot light, specular, premultiplied output (no limiting cone -> NaN).
        add(Case(
            name = "spot specular premult 16x16",
            width = 16,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            surfaceScale = 1f,
            invCanvasScaleX = 1.0,
            invCanvasScaleY = 1.0,
            userLeft = 0.0,
            userTop = 0.0,
            originX = 0.0,
            originY = 0.0,
            unitSizeX = 1.0,
            unitSizeY = 1.0,
            canvasScaleX = 1f,
            canvasScaleY = 1f,
            lightType = 2,
            specular = true,
            k = 1f,
            exponent = 20f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(8.0, 8.0, 50.0, 0.0, 0.0, 0.0, Double.NaN),
            premultiplied = true,
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
        ))
    }
}
