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

import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.SVGParserImpl
import org.xml.sax.Attributes

internal class TRef(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val href: String?,
    x: List<CSSLength>?,
    y: List<CSSLength>?,
    dx: List<CSSLength>?,
    dy: List<CSSLength>?,
) : TextPositionedContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    x = x,
    y = y,
    dx = dx,
    dy = dy,
), TextChild {

    override var textRoot: TextRoot? = null

    override fun getNodeName(): String {
        return "tref"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : TextPositionedContainer.Builder<TRef>(
        document = document,
        parent = parent
    ) {

        private var href: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.href -> {
                    val uri = attributes.getURI(index)
                    if (uri == "" || uri == SVGParserImpl.XLINK_NAMESPACE) {
                        href = value
                    }
                }
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): TRef {
            return TRef(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                href = href,
                x = getX(),
                y = getY(),
                dx = getDx(),
                dy = getDy(),
            )
        }
    }
}