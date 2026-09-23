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

package hu.oandras.ksvg.dom.core

import android.graphics.Matrix
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.parser.SVGParserImpl
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class Image(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    preserveAspectRatio: PreserveAspectRatio?,
    @JvmField
    val href: String?,
    @JvmField
    val x: CSSLength?,
    @JvmField
    val y: CSSLength?,
    @JvmField
    val width: CSSLength?,
    @JvmField
    val height: CSSLength?,
    transform: Matrix?,
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    preserveAspectRatio = preserveAspectRatio,
    transform = transform,
) {

    override fun getNodeName(): String {
        return "image"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalContainer.Builder<Image>(document, parent) {
        private var href: String? = null
        private var xlinkHref: String? = null
        private var x: CSSLength? = null
        private var y: CSSLength? = null
        private var width: CSSLength? = null
        private var height: CSSLength? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.href -> {
                    // Per SVG2, plain href wins over xlink:href regardless of
                    // document order, so the two are tracked separately.
                    val uri = attributes.getURI(index)
                    if (uri == "") {
                        href = value
                    } else if (uri == SVGParserImpl.XLINK_NAMESPACE) {
                        xlinkHref = value
                    }
                }
                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> width = parseNonNegativeLength(
                    value,
                    "Invalid <image> element. width cannot be negative"
                )
                SVGAttr.height -> height = parseNonNegativeLength(
                    value,
                    "Invalid <image> element. height cannot be negative"
                )
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): Image {
            return Image(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                preserveAspectRatio = getPreserveAspectRatio(),
                href = href ?: xlinkHref
                    ?: throw KSVGParseException("Invalid <image> element. href attribute is required"),
                x = x,
                y = y,
                width = width,
                height = height,
                transform = getTransform()
            )
        }
    }
}
