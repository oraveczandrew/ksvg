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
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.parseLength
import org.xml.sax.Attributes

internal class Symbol(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    preserveAspectRatio: PreserveAspectRatio?,
    viewBox: Box?,
    transform: Matrix?,
    @JvmField
    val refX: CSSLength?,
    @JvmField
    val refY: CSSLength?,
) : ViewBoxContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
    preserveAspectRatio = preserveAspectRatio,
    viewBox = viewBox
), NotDirectlyRendered {
    override fun getNodeName(): String {
        return "symbol"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ViewBoxContainer.Builder<Symbol>(document, parent) {
        private var refX: CSSLength? = null
        private var refY: CSSLength? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.refX -> refX = parseSymbolRef(value, horizontal = true)
                SVGAttr.refY -> refY = parseSymbolRef(value, horizontal = false)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): Symbol {
            return Symbol(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                preserveAspectRatio = getPreserveAspectRatio(),
                viewBox = getViewBox(),
                transform = getTransform(),
                refX = refX,
                refY = refY,
            )
        }
    }
}

/**
 * Parses `symbol` refX/refY: length | percentage | left/center/right
 * (horizontal) | top/center/bottom (vertical). Keywords map to 0%/50%/100%.
 * Unlike `marker`, an unspecified ref means no adjustment — callers must
 * distinguish null (absent) from an explicit zero.
 */
internal fun parseSymbolRef(value: String, horizontal: Boolean): CSSLength {
    return when {
        value.equals("center", ignoreCase = true) -> CSSLength.PERCENT_50
        horizontal && value.equals("left", ignoreCase = true) -> CSSLength.PERCENT_0
        horizontal && value.equals("right", ignoreCase = true) -> CSSLength.PERCENT_100
        !horizontal && value.equals("top", ignoreCase = true) -> CSSLength.PERCENT_0
        !horizontal && value.equals("bottom", ignoreCase = true) -> CSSLength.PERCENT_100
        else -> parseLength(value)
    }
}