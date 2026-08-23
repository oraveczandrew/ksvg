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
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class Svg(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    preserveAspectRatio: PreserveAspectRatio?,
    viewBox: Box?,
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
    val version: String?,
) : ViewBoxContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
    preserveAspectRatio = preserveAspectRatio,
    viewBox = viewBox
) {

    override fun getNodeName(): String {
        return "svg"
    }

    fun copy(
        width: CSSLength? = this.width,
        height: CSSLength? = this.height,
        viewBox: Box? = this.viewBox,
        preserveAspectRatio: PreserveAspectRatio? = this.preserveAspectRatio
    ): Svg {
        return Svg(
            baseParams = baseParams,
            conditionalBundle = this@Svg.conditionalBundle,
            preserveAspectRatio = preserveAspectRatio,
            viewBox = viewBox,
            transform = getTransform(),
            x = x,
            y = y,
            width = width,
            height = height,
            version = version
        )
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ViewBoxContainer.Builder<Svg>(document, parent) {
        private var x: CSSLength? = null
        private var y: CSSLength? = null
        private var width: CSSLength? = null
        private var height: CSSLength? = null
        private var version: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.x -> x = parseLength(value)
                SVGAttr.y -> y = parseLength(value)
                SVGAttr.width -> width = parseNonNegativeLength(value, "Invalid <svg> element. width cannot be negative")
                SVGAttr.height -> height = parseNonNegativeLength(value, "Invalid <svg> element. height cannot be negative")
                SVGAttr.version -> version = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): Svg {
            return Svg(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                preserveAspectRatio = getPreserveAspectRatio(),
                viewBox = getViewBox(),
                transform = getTransform(),
                x = x,
                y = y,
                width = width,
                height = height,
                version = version
            )
        }
    }
}