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

// SVGBase and Style are in the same package
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.parser.getSVGAttr
import hu.oandras.ksvg.parser.getTrimmedValue
import org.xml.sax.Attributes

//===============================================================================
// The objects in the SVG object tree
//===============================================================================
// Any object that can be part of the tree
internal interface SvgObject {
    val document: SVGImpl
    val parent: Container?
    val id: String?

    val styleBuilder: Style.Builder

    fun getNodeName(): String

    fun hasAnimationsOnTree(): Boolean

    abstract class Builder<T: SvgObject>(
        @JvmField
        val document: SVGImpl,
        @JvmField
        val parent: Container?,
    ) {

        fun parseAttributes(attributes: Attributes) {
            for (index in 0..<attributes.length) {
                onAttribute(
                    attributes = attributes,
                    index = index,
                    attr = attributes.getSVGAttr(index),
                    value = attributes.getTrimmedValue(index)
                )
            }
        }

        protected abstract fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String,
        ): Boolean

        abstract fun build(): T
    }
}
