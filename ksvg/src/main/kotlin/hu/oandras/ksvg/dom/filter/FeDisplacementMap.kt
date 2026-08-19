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

internal class FeDisplacementMap(
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
    val scale: Float,
    @JvmField
    val xChannelSelector: FeChannelSelector,
    @JvmField
    val yChannelSelector: FeChannelSelector,
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
        return "feDisplacementMap"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeDisplacementMap>(
        document = document,
        parent = parent
    ) {
        private var in2: String? = null
        private var scale: Float = 0f
        private var xChannelSelector: FeChannelSelector = FeChannelSelector.A
        private var yChannelSelector: FeChannelSelector = FeChannelSelector.A

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.in2 -> in2 = value
                SVGAttr.scale -> scale = parseFloat(value)
                SVGAttr.xChannelSelector -> xChannelSelector = if (value.isEmpty()) FeChannelSelector.A else try {
                    FeChannelSelector.valueOf(value.uppercase())
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid xChannelSelector attribute: $value")
                }
                SVGAttr.yChannelSelector -> yChannelSelector = if (value.isEmpty()) FeChannelSelector.A else try {
                    FeChannelSelector.valueOf(value.uppercase())
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid yChannelSelector attribute: $value")
                }
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeDisplacementMap {
            return FeDisplacementMap(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                in2 = in2,
                scale = scale,
                xChannelSelector = xChannelSelector,
                yChannelSelector = yChannelSelector,
            )
        }
    }
}