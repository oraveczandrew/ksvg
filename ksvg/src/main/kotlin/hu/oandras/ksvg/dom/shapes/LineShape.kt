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
import org.xml.sax.Attributes

internal class LineShape(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
    @JvmField
    val x1: CSSLength?,
    @JvmField
    val y1: CSSLength?,
    @JvmField
    val x2: CSSLength?,
    @JvmField
    val y2: CSSLength?,
) : Shape(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform
) {

    override fun getNodeName(): String {
        return "line"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Shape.Builder<LineShape>(document, parent) {
        private var x1: CSSLength? = null
        private var y1: CSSLength? = null
        private var x2: CSSLength? = null
        private var y2: CSSLength? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.x1 -> x1 = parseLength(value)
                SVGAttr.y1 -> y1 = parseLength(value)
                SVGAttr.x2 -> x2 = parseLength(value)
                SVGAttr.y2 -> y2 = parseLength(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): LineShape {
            return LineShape(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform(),
                x1 = x1,
                y1 = y1,
                x2 = x2,
                y2 = y2
            )
        }
    }
}