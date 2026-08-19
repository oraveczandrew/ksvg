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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.ContainerImpl
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.parser.parseFloatList
import org.xml.sax.Attributes

internal class FeFunc(
    baseParams: BaseParams,
    @JvmField
    val channel: Channel = Channel.R,
    @JvmField
    val type: FeFuncType,
    @JvmField
    val tableValues: FloatArray?,
    @JvmField
    val slope: Float = 1f,
    @JvmField
    val intercept: Float,
    @JvmField
    val amplitude: Float,
    @JvmField
    val exponent: Float,
    @JvmField
    val offset: Float,
) : ContainerImpl(
    baseParams = baseParams,
) {
    enum class Channel { R, G, B, A }

    override fun getNodeName(): String {
        return when (channel) {
            Channel.R -> "feFuncR"
            Channel.G -> "feFuncG"
            Channel.B -> "feFuncB"
            Channel.A -> "feFuncA"
        }
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
        private val channel: Channel,
    ) : ContainerImpl.Builder<FeFunc>(
        document = document,
        parent = parent
    ) {

        private var type: FeFuncType = FeFuncType.identity

        private var tableValues: FloatArray? = null

        private var slope: Float = 1f

        private var intercept: Float = 0f

        private var amplitude: Float = 1f

        private var exponent: Float = 1f

        private var offset: Float = 0f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.type -> type = if (value.isEmpty()) FeFuncType.identity else try {
                    FeFuncType.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid feFunc type: $value")
                }
                SVGAttr.tableValues -> tableValues = parseFloatList(value)
                SVGAttr.slope -> slope = parseFloat(value)
                SVGAttr.intercept -> intercept = parseFloat(value)
                SVGAttr.amplitude -> amplitude = parseFloat(value)
                SVGAttr.exponent -> exponent = parseFloat(value)
                SVGAttr.offset -> offset = parseFloat(value)

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeFunc {
            return FeFunc(
                baseParams = getBaseParams(),
                channel = channel,
                type = type,
                tableValues = tableValues,
                slope = slope,
                intercept = intercept,
                amplitude = amplitude,
                exponent = exponent,
                offset = offset
            )
        }
    }
}