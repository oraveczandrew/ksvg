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
import hu.oandras.ksvg.parser.parseLengthList
import org.xml.sax.Attributes

internal abstract class TextPositionedContainer(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val x: List<CSSLength>?,
    @JvmField
    val y: List<CSSLength>?,
    @JvmField
    val dx: List<CSSLength>?,
    @JvmField
    val dy: List<CSSLength>?,
    transform: Matrix? = null,
) : TextContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
) {
    abstract class Builder<T : TextPositionedContainer>(
        document: SVGImpl,
        parent: Container?,
    ) : TextContainer.Builder<T>(document, parent) {

        private var x: List<CSSLength>? = null
        private var y: List<CSSLength>? = null
        private var dx: List<CSSLength>? = null
        private var dy: List<CSSLength>? = null

        protected fun getX(): List<CSSLength>? = x
        protected fun getY(): List<CSSLength>? = y
        protected fun getDx(): List<CSSLength>? = dx
        protected fun getDy(): List<CSSLength>? = dy

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.x -> x = parseLengthList(value)
                SVGAttr.y -> y = parseLengthList(value)
                SVGAttr.dx -> dx = parseLengthList(value)
                SVGAttr.dy -> dy = parseLengthList(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }
    }
}
