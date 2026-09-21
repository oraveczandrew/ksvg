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

package hu.oandras.ksvg.filtering.parity

import hu.oandras.ksvg.filtering.LightingValidationCorpus
import hu.oandras.ksvg.filtering.UnLinearizeValidationCorpus
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.JUnit4

/**
 * Host-side snapshot of the round-B lighting SVG builder.
 */
@RunWith(JUnit4::class)
class LightingParitySvgTest {

    private fun caseWith(
        lightType: Int,
        specular: Boolean,
        params: DoubleArray,
        useLinear: Boolean,
    ): LightingValidationCorpus.Case {
        return LightingValidationCorpus.Case(
            name = "snapshot",
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
            lightType = lightType,
            specular = specular,
            k = 1f,
            exponent = 1f,
            lightR = 255,
            lightG = 255,
            lightB = 255,
            params = params,
            premultiplied = false,
            useLinear = useLinear,
            input = UnLinearizeValidationCorpus.fixedSeedRandom(16 * 16),
        )
    }

    @Test
    fun distantDiffuseSrgb() {
        val svg = LightingParitySvg.toSvg(
            caseWith(0, false, doubleArrayOf(45.0, 45.0), false),
            URI,
        )
        assertTrue(
            svg.contains(
                "<feDiffuseLighting surfaceScale=\"1.0\" diffuseConstant=\"1.0\" " +
                    "lighting-color=\"#ffffff\" color-interpolation-filters=\"sRGB\">" +
                    "<feDistantLight azimuth=\"45.0\" elevation=\"45.0\"/>" +
                    "</feDiffuseLighting>",
            ),
        )
        assertTrue(svg.contains("filter=\"url(#f)\""))
    }

    @Test
    fun spotSpecularLinearNoCone() {
        val svg = LightingParitySvg.toSvg(
            caseWith(2, true, doubleArrayOf(8.0, 8.0, 50.0, 0.0, 0.0, 0.0, Double.NaN), true),
            URI,
        )
        // NaN cone angle must be omitted (means "no cone" on both sides).
        assertTrue(
            svg.contains(
                "<feSpotLight x=\"8.0\" y=\"8.0\" z=\"50.0\" " +
                    "pointsAtX=\"0.0\" pointsAtY=\"0.0\" pointsAtZ=\"0.0\"/>",
            ),
        )
        assertTrue(svg.contains("color-interpolation-filters=\"linearRGB\""))
    }

    companion object {
        private const val URI = "data:image/png;base64,AAA"
    }
}
