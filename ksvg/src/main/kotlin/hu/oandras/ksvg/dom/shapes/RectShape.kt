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
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class RectShape(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
    @JvmField
    val x: CSSLength?,
    @JvmField
    val y: CSSLength?,
    @JvmField
    val width: CSSLength?,
    @JvmField
    val height: CSSLength?,
    @JvmField
    val rx: CSSLength?,
    @JvmField
    val ry: CSSLength?,
) : Shape(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform
) {

    override fun getNodeName(): String {
        return "rect"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Shape.Builder<RectShape>(document, parent) {
        private var x: CSSLength? = null
        private var y: CSSLength? = null
        private var width: CSSLength? = null
        private var height: CSSLength? = null
        private var rx: CSSLength? = null
        private var ry: CSSLength? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> width = parseNonNegativeLength(value, "Invalid <rect> element. width cannot be negative")
                SVGAttr.height -> height = parseNonNegativeLength(value, "Invalid <rect> element. height cannot be negative")
                SVGAttr.rx -> rx = parseNonNegativeLength(value, "Invalid <rect> element. rx cannot be negative")
                SVGAttr.ry -> ry = parseNonNegativeLength(value, "Invalid <rect> element. ry cannot be negative")
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): RectShape {
            return RectShape(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform(),
                x = x,
                y = y,
                width = width,
                height = height,
                rx = rx,
                ry = ry
            )
        }
    }
}
