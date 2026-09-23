/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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

package hu.oandras.ksvg.dom.shapes

import android.graphics.Matrix
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeFloat
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class CircleShape(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
    @JvmField
    val cx: CSSLength?,
    @JvmField
    val cy: CSSLength?,
    @JvmField
    val r: CSSLength?,
    @JvmField
    val pathLength: Float? = null,
) : Shape(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform
) {

    override fun getNodeName(): String {
        return "circle"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Shape.Builder<CircleShape>(document, parent) {
        private var cx: CSSLength? = null
        private var cy: CSSLength? = null
        private var r: CSSLength? = null
        private var pathLength: Float? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.cx -> cx = parseLength(value)
                SVGAttr.cy -> cy = parseLength(value)
                SVGAttr.r -> r = parseNonNegativeLength(
                    value,
                    "Invalid <circle> element. r cannot be negative"
                )
                SVGAttr.pathLength -> pathLength = parseNonNegativeFloat(
                    value = value,
                    errorMessage = "Invalid <circle> element. pathLength cannot be negative"
                )
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): CircleShape {
            return CircleShape(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform(),
                cx = cx,
                cy = cy,
                r = r,
                pathLength = pathLength
            )
        }
    }
}
