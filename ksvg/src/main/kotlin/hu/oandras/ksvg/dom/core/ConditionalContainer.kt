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
import androidx.collection.ArraySet
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.style.parseFontFamily
import hu.oandras.ksvg.parser.parseTransform
import org.xml.sax.Attributes

internal abstract class ConditionalContainer(
    baseParams: BaseParams,
    @JvmField
    val conditionalBundle: Conditional,
    @JvmField
    val transform: Matrix? = null,
    @JvmField
    var preserveAspectRatio: PreserveAspectRatio? = null,
) : Element(
    baseParams = baseParams,
), Container, Conditional by conditionalBundle, DomParent by ChildrenStore(), HasTransform {

    override fun getTransform(): Matrix? = transform

    abstract class Builder<T : ConditionalContainer>(
        document: SVGImpl,
        parent: Container?,
    ) : Element.Builder<T>(document, parent) {
        private var requiredFeatures: Set<String>? = null
        private var requiredExtensions: String? = null
        private var systemLanguage: Set<String>? = null
        private var requiredFormats: Set<String>? = null
        private var requiredFonts: Set<String>? = null
        private var transform: Matrix? = null
        private var preserveAspectRatio: PreserveAspectRatio? = null

        protected fun getSvgConditionalBundle(): Conditional {
            return Conditional(
                requiredFeatures = requiredFeatures,
                requiredExtensions = requiredExtensions,
                requiredFormats = requiredFormats,
                requiredFonts = requiredFonts,
                systemLanguage = systemLanguage,
            )
        }

        protected fun getTransform(): Matrix? = transform
        protected fun getPreserveAspectRatio(): PreserveAspectRatio? = preserveAspectRatio

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
                SVGAttr.transform -> transform = parseTransform(value)
                SVGAttr.preserveAspectRatio -> preserveAspectRatio = PreserveAspectRatio.of(value)

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }
    }
}
