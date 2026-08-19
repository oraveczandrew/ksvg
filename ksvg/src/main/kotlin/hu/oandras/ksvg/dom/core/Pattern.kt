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
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.XLINK_NAMESPACE
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import hu.oandras.ksvg.parser.parseTransform
import org.xml.sax.Attributes

internal class Pattern(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    preserveAspectRatio: PreserveAspectRatio?,
    viewBox: Box?,
    @JvmField
    var patternUnitsAreUser: Boolean?,
    @JvmField
    var patternContentUnitsAreUser: Boolean?,
    @JvmField
    var patternTransform: Matrix?,
    @JvmField
    var x: CSSLength?,
    @JvmField
    var y: CSSLength?,
    @JvmField
    var width: CSSLength?,
    @JvmField
    var height: CSSLength?,
    @JvmField
    var href: String?,
) : ViewBoxContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    preserveAspectRatio = preserveAspectRatio,
    viewBox = viewBox,
), NotDirectlyRendered {

    override fun getNodeName(): String {
        return "pattern"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ViewBoxContainer.Builder<Pattern>(
        document = document,
        parent = parent
    ) {
        private var patternUnitsAreUser: Boolean? = null

        private var patternContentUnitsAreUser: Boolean? = null

        private var patternTransform: Matrix? = null

        private var x: CSSLength? = null

        private var y: CSSLength? = null

        private var width: CSSLength? = null

        private var height: CSSLength? = null

        private var href: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.patternUnits -> patternUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw KSVGParseException("Invalid value for attribute patternUnits")
                }

                SVGAttr.patternContentUnits -> patternContentUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw KSVGParseException("Invalid value for attribute patternContentUnits")
                }

                SVGAttr.patternTransform -> patternTransform = parseTransform(value)
                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> width = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <pattern> element. width cannot be negative"
                )

                SVGAttr.height -> height = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <pattern> element. height cannot be negative"
                )

                SVGAttr.href -> {
                    val uri = attributes.getURI(index)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        href = value
                    }
                }

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): Pattern {
            return Pattern(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                preserveAspectRatio = getPreserveAspectRatio(),
                viewBox = getViewBox(),
                patternUnitsAreUser = patternUnitsAreUser,
                patternContentUnitsAreUser = patternContentUnitsAreUser,
                patternTransform = patternTransform,
                x = x,
                y = y,
                width = width,
                height = height,
                href = href,
            )
        }
    }
}