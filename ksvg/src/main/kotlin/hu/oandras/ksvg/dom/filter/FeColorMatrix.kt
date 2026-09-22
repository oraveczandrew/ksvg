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

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseFloatList
import java.util.Locale
import org.xml.sax.Attributes

internal class FeColorMatrix(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?,
    result: String?,
    `in`: String?,
    @JvmField
    val type: FeColorMatrixType,
    @JvmField
    val values: FloatArray?,
) : FilterPrimitive(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    x = x,
    y = y,
    width = width,
    height = height,
    result = result,
    `in` = `in`,
) {

    override fun getNodeName(): String {
        return "feColorMatrix"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeColorMatrix>(
        document = document,
        parent = parent
    ) {
        private var type: FeColorMatrixType = FeColorMatrixType.matrix
        private var values: FloatArray? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.type -> type = if (value.isEmpty()) {
                    FeColorMatrixType.matrix
                } else try {
                    FeColorMatrixType.valueOf(value.lowercase(Locale.US))
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid matrix type: $value")
                }

                SVGAttr.values -> values = parseFloatList(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeColorMatrix {
            return FeColorMatrix(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                type = type,
                values = values,
            )
        }
    }
}
