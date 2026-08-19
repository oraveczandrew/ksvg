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

package hu.oandras.ksvg.dom.gradient

import android.graphics.Matrix
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.ContainerImpl
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.parser.SVGParserImpl.Companion.XLINK_NAMESPACE
import hu.oandras.ksvg.parser.parseTransform
import org.xml.sax.Attributes

internal abstract class Gradient(
    baseParams: BaseParams,
    @JvmField
    var gradientUnitsAreUser: Boolean?,
    @JvmField
    var gradientTransform: Matrix?,
    @JvmField
    var spreadMethod: GradientSpread?,
    @JvmField
    var href: String?,
) : ContainerImpl(
    baseParams = baseParams,
) {

    @Throws(KSVGParseException::class)
    override fun addChild(elem: SvgObject) {
        if (elem is Stop) {
            super.addChild(elem)
        } else {
            throw KSVGParseException("Gradient elements cannot contain $elem elements.")
        }
    }

    abstract class Builder<T : Gradient>(
        document: SVGImpl,
        parent: Container?,
    ) : ContainerImpl.Builder<T>(document, parent) {
        private var gradientUnitsAreUser: Boolean? = null

        private var gradientTransform: Matrix? = null

        private var spreadMethod: GradientSpread? = null

        private var href: String? = null

        protected fun getGradientUnitsAreUser(): Boolean? = gradientUnitsAreUser
        protected fun getGradientTransform(): Matrix? = gradientTransform
        protected fun getSpreadMethod(): GradientSpread? = spreadMethod
        protected fun getHref(): String? = href

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.gradientUnits -> gradientUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw KSVGParseException("Invalid value for attribute gradientUnits")
                }

                SVGAttr.gradientTransform -> gradientTransform = parseTransform(value)
                SVGAttr.spreadMethod -> try {
                    spreadMethod = GradientSpread.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid spreadMethod attribute. \"$value\" is not a valid value.")
                }

                SVGAttr.href -> {
                    val uri = attributes.getURI(index)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        href = value
                    }
                }

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }
    }
}