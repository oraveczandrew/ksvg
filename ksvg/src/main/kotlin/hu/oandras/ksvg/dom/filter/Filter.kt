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

import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.ConditionalContainer
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.Region
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class Filter(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val filterUnitsAreUser: Boolean?,
    @JvmField
    val primitiveUnitsAreUser: Boolean?,
    override val x: CSSLength?,
    override val y: CSSLength?,
    override val width: CSSLength?,
    override val height: CSSLength?,
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
), Region {

    override val unitsAreUser: Boolean? get() = filterUnitsAreUser

    override fun getNodeName(): String {
        return "filter"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ): ConditionalContainer.Builder<Filter>(
        document = document,
        parent = parent,
    ) {

        private var filterUnitsAreUser: Boolean? = null

        private var primitiveUnitsAreUser: Boolean? = null

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
                SVGAttr.filterUnits -> filterUnitsAreUser = value == "userSpaceOnUse"
                SVGAttr.primitiveUnits -> primitiveUnitsAreUser = value == "userSpaceOnUse"
                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> width = parseNonNegativeLength(value, "Invalid <filter> element. width cannot be negative")
                SVGAttr.height -> height = parseNonNegativeLength(value, "Invalid <filter> element. height cannot be negative")
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): Filter {
            return Filter(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                filterUnitsAreUser = filterUnitsAreUser,
                primitiveUnitsAreUser = primitiveUnitsAreUser,
                x = x,
                y = y,
                width = width,
                height = height,
            )
        }
    }
}