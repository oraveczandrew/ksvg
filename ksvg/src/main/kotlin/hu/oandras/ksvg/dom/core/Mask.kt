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

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class Mask(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val maskUnitsAreUser: Boolean?,
    @JvmField
    val maskContentUnitsAreUser: Boolean?,
    override val x: CSSLength?,
    override val y: CSSLength?,
    override val width: CSSLength?,
    override val height: CSSLength?,
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
), NotDirectlyRendered, Region {

    override val unitsAreUser: Boolean? get() = maskUnitsAreUser

    override fun getNodeName(): String {
        return "mask"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalContainer.Builder<Mask>(
        document = document,
        parent = parent
    ) {
        private var maskUnitsAreUser: Boolean? = null

        private var maskContentUnitsAreUser: Boolean? = null
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
                SVGAttr.maskUnits -> maskUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw KSVGParseException("Invalid value for attribute maskUnits")
                }

                SVGAttr.maskContentUnits -> maskContentUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw KSVGParseException("Invalid value for attribute maskContentUnits")
                }

                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> {
                    width = parseNonNegativeLength(
                        value,
                        "Invalid <mask> element. width cannot be negative"
                    )
                }

                SVGAttr.height -> {
                    height = parseNonNegativeLength(
                        value,
                        "Invalid <mask> element. height cannot be negative"
                    )
                }

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): Mask {
            return Mask(
                baseParams = getBaseParams(),
                x = x,
                y = y,
                width = width,
                height = height,
                conditionalBundle = getSvgConditionalBundle(),
                maskUnitsAreUser = maskUnitsAreUser,
                maskContentUnitsAreUser = maskContentUnitsAreUser,
            )
        }
    }
}