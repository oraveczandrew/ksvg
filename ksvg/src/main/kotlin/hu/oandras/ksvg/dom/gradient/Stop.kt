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

import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.ContainerImpl
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.parser.checkState
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.utils.clamp
import org.xml.sax.Attributes

internal class Stop(
    baseParams: BaseParams,
    @JvmField
    val offset: Float,
) : ContainerImpl(
    baseParams = baseParams,
) {

    // Dummy container methods. Stop is officially a container, but we
    // are not interested in any of its possible child elements.
    override fun addChild(elem: SvgObject) {
        /* do nothing */
    }

    override fun addAll(list: List<SvgObject>) {
        /* do nothing */
    }

    override fun getNodeName(): String {
        return "stop"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ContainerImpl.Builder<Stop>(
        document = document,
        parent = parent
    ) {

        private var offset: Float = 0f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.offset -> offset = parseGradientOffset(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): Stop {
            return Stop(
                baseParams = getBaseParams(),
                offset = offset,
            )
        }

        @Throws(KSVGParseException::class)
        private fun parseGradientOffset(value: String): Float {
            checkState(value.isNotEmpty()) { "Invalid offset value in <stop> (empty string)" }
            var end = value.length
            var isPercent = false

            if (value[value.length - 1] == '%') {
                end -= 1
                isPercent = true
            }

            try {
                var scalar: Float = parseFloat(value, 0, end)
                if (isPercent) {
                    scalar /= 100f
                }
                return clamp(scalar, 0f, 1f)
            } catch (e: NumberFormatException) {
                throw KSVGParseException("Invalid offset value in <stop>: $value", e)
            }
        }
    }
}