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

package hu.oandras.ksvg.dom.text

import android.graphics.Matrix
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseTransform
import org.xml.sax.Attributes

internal class Text(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: List<CSSLength>?,
    y: List<CSSLength>?,
    dx: List<CSSLength>?,
    dy: List<CSSLength>?,
    transform: Matrix?,
) : TextPositionedContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    x = x,
    y = y,
    dx = dx,
    dy = dy,
    transform = transform,
), TextRoot {

    override fun getNodeName(): String {
        return "text"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : TextPositionedContainer.Builder<Text>(document, parent) {
        private var transform: Matrix? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.transform -> transform = parseTransform(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): Text {
            return Text(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                dx = getDx(),
                dy = getDy(),
                transform = transform,
            )
        }
    }
}
