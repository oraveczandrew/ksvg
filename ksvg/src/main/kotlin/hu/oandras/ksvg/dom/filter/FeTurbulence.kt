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

package hu.oandras.ksvg.dom.filter

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.parser.parseFloatList
import org.xml.sax.Attributes

internal class FeTurbulence(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?,
    result: String?,
    `in`: String?,
    @JvmField
    val baseFrequencyX: Float,
    @JvmField
    val baseFrequencyY: Float,
    @JvmField
    val numOctaves: Int,
    @JvmField
    val seed: Float,
    @JvmField
    val stitchTiles: FeStitchTiles,
    @JvmField
    val type: FeTurbulenceType,
) : FilterPrimitive(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    x = x,
    y = y,
    width = width,
    height = height,
    result = result,
    `in` = `in`,
) {

    override fun getNodeName(): String {
        return "feTurbulence"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeTurbulence>(
        document = document,
        parent = parent
    ) {
        private var baseFrequencyX: Float = 0f
        private var baseFrequencyY: Float = 0f
        private var numOctaves: Int = 1
        private var seed: Float = 0f
        private var stitchTiles: FeStitchTiles = FeStitchTiles.noStitch
        private var type: FeTurbulenceType = FeTurbulenceType.turbulence

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.baseFrequency -> {
                    val values = parseFloatList(value)
                    baseFrequencyX = values.getOrNull(0) ?: 0f
                    baseFrequencyY = values.getOrNull(1) ?: baseFrequencyX
                }

                SVGAttr.numOctaves -> numOctaves = value.toIntOrNull() ?: 1
                SVGAttr.seed -> seed = parseFloat(value)
                SVGAttr.stitchTiles -> stitchTiles =
                    if (value.isEmpty()) FeStitchTiles.noStitch else try {
                        FeStitchTiles.valueOf(value)
                    } catch (_: IllegalArgumentException) {
                        throw KSVGParseException("Invalid stitchTiles attribute: $value")
                    }

                SVGAttr.type -> type =
                    if (value.isEmpty()) FeTurbulenceType.turbulence else try {
                        FeTurbulenceType.valueOf(value)
                    } catch (_: IllegalArgumentException) {
                        throw KSVGParseException("Invalid feTurbulence type: $value")
                    }

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): FeTurbulence {
            return FeTurbulence(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                baseFrequencyX = baseFrequencyX,
                baseFrequencyY = baseFrequencyY,
                numOctaves = numOctaves,
                seed = seed,
                stitchTiles = stitchTiles,
                type = type,
            )
        }
    }
}