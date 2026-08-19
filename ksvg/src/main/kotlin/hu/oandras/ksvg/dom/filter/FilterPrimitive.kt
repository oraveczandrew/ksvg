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
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal abstract class FilterPrimitive(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val x: CSSLength?,
    @JvmField
    val y: CSSLength?,
    @JvmField
    val width: CSSLength?,
    @JvmField
    val height: CSSLength?,
    @JvmField
    val result: String?,
    @JvmField
    val `in`: String?,
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
) {

    abstract class Builder<T : FilterPrimitive>(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalContainer.Builder<T>(
        document = document,
        parent = parent,
    ) {

        private var x: CSSLength? = null

        private var y: CSSLength? = null

        private var width: CSSLength? = null

        private var height: CSSLength? = null

        private var result: String? = null

        private var `in`: String? = null

        protected fun getX(): CSSLength? = x
        protected fun getY(): CSSLength? = y
        protected fun getWidth(): CSSLength? = width
        protected fun getHeight(): CSSLength? = height
        protected fun getResult(): String? = result
        protected fun getIn(): String? = `in`

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> width = parseNonNegativeLength(value, "Invalid filter primitive width: $value")
                SVGAttr.height -> height = parseNonNegativeLength(value, "Invalid filter primitive height: $value")
                SVGAttr.result -> result = value
                SVGAttr.`in` -> `in` = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }
    }
}
