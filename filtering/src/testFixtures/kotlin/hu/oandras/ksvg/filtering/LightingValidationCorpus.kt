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
        public val surfaceScale: Float,
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
        public val canvasScaleX: Float,
        @JvmField
        public val canvasScaleY: Float,
        @JvmField
        public val lightType: Int,
        @JvmField
        public val specular: Boolean,
        public val k: Float,
        @JvmField
        public val exponent: Float,
        @JvmField
        public val lightR: Int,
        @JvmField
        public val lightG: Int,
        @JvmField
        public val lightB: Int,
        @JvmField
        public val params: DoubleArray,
        @JvmField
        public val premultiplied: Boolean,
        @JvmField
        public val useLinear: Boolean,
        @JvmField
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

    @JvmField
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

        // Distant light, diffuse, linear output (exercises the in-place
        // linear->sRGB amortized mapping of the *Linear diffuse asm rows).
        add(Case(
            name = "distant diffuse linear 16x16",
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
            useLinear = true,
            input = UnLinearizeValidationCorpus.alternating(16 * 16)
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

        // Distant light, specular, linear output (exercises the in-place
        // linear->sRGB amortized mapping of the *Linear asm entry points).
        add(Case(
            name = "distant specular linear 16x16",
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
            useLinear = true,
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

        // Point light, diffuse, NON-linear output. Exercises the non-linear point
        // rows (lighting_point_diffuse_i386_avx2.S `ksvgLightingPointDiffuseRowAvx2`),
        // which previously had no corpus coverage: surface-Z read from the srcT row
        // instead of the srcM window center, and truncation-instead-of-round+0.5.
        add(Case(
            name = "point diffuse non-linear 24x16",
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
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(24 * 16)
        ))

        // Spot light, specular, non-premultiplied -> exercises the spot-specular
        // SIMD rows (ksvgLightingSpotSpecularRow{Ssse3,Avx2}), which the premult
        // case below never reaches (lighting.cpp dispatches specular SIMD only when
        // !premultiplied). Covers exponent-scaled cos and the non-linear pack path.
        add(Case(
            name = "spot specular 16x16",
            width = 16,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            surfaceScale = 0.05f,
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
            exponent = 5f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(8.0, 8.0, 50.0, 8.0, 8.0, 0.0, 30.0),
            premultiplied = false,
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
        ))

        // Spot light, specular, non-premultiplied, LINEAR output. Exercises the
        // *Linear specular rows and the linear->sRGB mapping.
        add(Case(
            name = "spot specular linear 16x16",
            width = 16,
            height = 16,
            clipLeft = 0,
            clipTop = 0,
            clipRight = 16,
            clipBottom = 16,
            surfaceScale = 0.05f,
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
            exponent = 5f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = doubleArrayOf(8.0, 8.0, 50.0, 8.0, 8.0, 0.0, 30.0),
            premultiplied = false,
            useLinear = true,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
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

        // Point light, specular, linear output
        add(Case(
            name = "point specular linear 32x8",
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
            useLinear = true,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(32 * 8)
        ))

        // Spot light, diffuse, sRGB / non-linear output
        add(Case(
            name = "spot diffuse 16x16",
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
            useLinear = false,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16)
        ))
    }
}
