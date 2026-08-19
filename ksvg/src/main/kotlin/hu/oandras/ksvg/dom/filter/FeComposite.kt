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
import org.xml.sax.Attributes

internal class FeComposite(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?,
    result: String?,
    `in`: String?,
    @JvmField
    val in2: String?,
    @JvmField
    val operator: FeCompositeOperator,
    @JvmField
    val k1: Float,
    @JvmField
    val k2: Float,
    @JvmField
    val k3: Float,
    @JvmField
    val k4: Float,
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
        return "feComposite"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeComposite>(
        document = document,
        parent = parent
    ) {
        private var in2: String? = null
        private var operator: FeCompositeOperator = FeCompositeOperator.over
        private var k1: Float = 0f
        private var k2: Float = 0f
        private var k3: Float = 0f
        private var k4: Float = 0f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.in2 -> in2 = value
                SVGAttr.operator -> operator = if (value.isEmpty()) FeCompositeOperator.over else try {
                    FeCompositeOperator.valueOf(value.lowercase())
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid FeComposite operator: $value")
                }
                SVGAttr.k1 -> k1 = parseFloat(value)
                SVGAttr.k2 -> k2 = parseFloat(value)
                SVGAttr.k3 -> k3 = parseFloat(value)
                SVGAttr.k4 -> k4 = parseFloat(value)

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeComposite {
            return FeComposite(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                operator = operator,
                k1 = k1,
                k2 = k2,
                k3 = k3,
                k4 = k4,
                in2 = in2
            )
        }
    }
}