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

import androidx.annotation.CallSuper
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.LoggerContext
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.style.Style
import java.util.Locale
import org.xml.sax.Attributes

//===============================================================================
// The objects in the SVG object tree
//===============================================================================
// Any object that can be part of the tree
internal open class SvgObjectImpl(
    override val id: String?,
    override val document: SVGImpl,
    override val parent: Container?,
    @JvmField
    val spacePreserve: Boolean?,
): SvgObject {

    private var _styleBuilder: Style.Builder? = null
    override val styleBuilder: Style.Builder
        get() = _styleBuilder ?: Style.getDefaultStyle().toBuilder().also {
            _styleBuilder = it
        }

    override fun getNodeName(): String = ""

    override fun hasAnimationsOnTree(): Boolean = false

    open class Builder<T: SvgObjectImpl>(
        document: SVGImpl,
        parent: Container?,
    ): SvgObject.Builder<SvgObjectImpl>(
        document,
        parent,
    ), LoggerContext by document {

        private var id: String? = null

        private var spacePreserve: Boolean? = null

        @CallSuper
        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.id -> id = value
                SVGAttr.space -> spacePreserve = spaceReserveValueFrom(value)
                else -> return false
            }

            return true
        }

        private fun spaceReserveValueFrom(value: String): Boolean {
            return when (val value = value.lowercase(Locale.US)) {
                "default" -> false
                "preserve" -> true
                else -> throw KSVGParseException("Invalid value for \"xml:space\" attribute: $value")
            }
        }

        @Suppress("UNCHECKED_CAST")
        override fun build(): T {
            return SvgObjectImpl(
                id = id,
                document = document,
                parent = parent,
                spacePreserve = spacePreserve,
            ) as T
        }

        protected fun getId(): String? = id
        protected fun getSpacePreserve(): Boolean? = spacePreserve
    }
}