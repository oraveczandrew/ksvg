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

import androidx.collection.ArraySet
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.style.parseFontFamily
import org.xml.sax.Attributes

// Any element that can appear inside a <switch> element.
internal abstract class ConditionalElement(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
) : Element(
    baseParams = baseParams,
), Conditional by conditionalBundle {

    abstract class Builder<T : ConditionalElement>(
        document: SVGImpl,
        parent: Container?,
    ) : Element.Builder<T>(document, parent) {
        private var requiredFeatures: Set<String>? = null
        private var requiredExtensions: String? = null
        private var systemLanguage: Set<String>? = null
        private var requiredFormats: Set<String>? = null
        private var requiredFonts: Set<String>? = null

        protected fun getSvgConditionalBundle(): Conditional {
            return Conditional(
                requiredFeatures = requiredFeatures,
                requiredExtensions = requiredExtensions,
                requiredFormats = requiredFormats,
                requiredFonts = requiredFonts,
                systemLanguage = systemLanguage,
            )
        }

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.requiredFeatures -> requiredFeatures = parseRequiredFeatures(value)
                SVGAttr.requiredExtensions -> requiredExtensions = value
                SVGAttr.systemLanguage -> systemLanguage = parseSystemLanguage(value)
                SVGAttr.requiredFormats -> requiredFormats = parseRequiredFormats(value)
                SVGAttr.requiredFonts -> {
                    val fonts = parseFontFamily(value)
                    requiredFonts = if (fonts != null) {
                        ArraySet(fonts)
                    } else {
                        emptySet()
                    }
                }

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }
    }
}