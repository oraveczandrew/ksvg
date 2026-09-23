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
import hu.oandras.ksvg.parser.parseFloatList
import org.xml.sax.Attributes

internal class FeMorphology(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?,
    result: String?,
    `in`: String?,
    @JvmField
    val operator: FeMorphologyOperator,
    @JvmField
    val radiusX: Float,
    @JvmField
    val radiusY: Float,
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
        return "feMorphology"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeMorphology>(
        document = document,
        parent = parent
    ) {
        private var operator: FeMorphologyOperator = FeMorphologyOperator.erode
        private var radiusX: Float = 0f
        private var radiusY: Float = 0f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.operator -> operator = if (value.isEmpty()) FeMorphologyOperator.erode else try {
                    FeMorphologyOperator.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid feMorphology operator: $value")
                }
                SVGAttr.radius -> {
                    val values = parseFloatList(value)
                    // Negative radii are clamped to 0 (passthrough): CPU and GPU paths
                    // must agree, and a 0-radius morphology is the identity anyway.
                    radiusX = (values.getOrNull(0) ?: 0f).coerceAtLeast(0f)
                    radiusY = (values.getOrNull(1) ?: radiusX).coerceAtLeast(0f)
                }
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeMorphology {
            return FeMorphology(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                operator = operator,
                radiusX = radiusX,
                radiusY = radiusY,
            )
        }
    }
}