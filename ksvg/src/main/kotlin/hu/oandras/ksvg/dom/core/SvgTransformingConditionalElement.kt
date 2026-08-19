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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.parseTransform
import org.xml.sax.Attributes

internal open class SvgTransformingConditionalElement(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    @JvmField
    val transform: Matrix?,
) : ConditionalElement(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
), HasTransform {

    override fun getTransform(): Matrix? {
        return transform
    }

    abstract class Builder<T : SvgTransformingConditionalElement>(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalElement.Builder<T>(document, parent) {
        private var transform: Matrix? = null

        protected fun getTransform(): Matrix? = transform

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.transform -> transform = parseTransform(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }
    }
}