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
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.XLINK_NAMESPACE
import hu.oandras.ksvg.parser.parseLength
import org.xml.sax.Attributes

internal class TextPath(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val href: String?,
    @JvmField
    val startOffset: CSSLength?,
) : TextContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
), TextChild {
    override var textRoot: TextRoot? = null

    override fun getNodeName(): String {
        return "textPath"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : TextContainer.Builder<TextPath>(document, parent) {

        private var href: String? = null
        private var startOffset: CSSLength? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.href -> {
                    val uri = attributes.getURI(index)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        href = value
                    }
                }

                SVGAttr.startOffset -> startOffset = parseLength(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): TextPath {
            return TextPath(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                href = href,
                startOffset = startOffset,
            )
        }
    }
}