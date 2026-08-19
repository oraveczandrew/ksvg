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

package hu.oandras.ksvg.dom.shapes

import android.graphics.Matrix
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseNonNegativeFloat
import hu.oandras.ksvg.parser.parsePath
import org.xml.sax.Attributes

internal class PathShape(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
    @JvmField
    val d: PathDefinition?,
    @JvmField
    val pathLength: Float?,
) : Shape(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform
) {

    override fun getNodeName(): String {
        return "path"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Shape.Builder<PathShape>(document, parent) {
        private var d: PathDefinition? = null
        private var pathLength: Float? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.d -> d = parsePath(value)
                SVGAttr.pathLength -> pathLength = parseNonNegativeFloat(
                    value = value,
                    errorMessage = "Invalid <path> element. pathLength cannot be negative"
                )
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): PathShape {
            return PathShape(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform(),
                d = requireNotNull(d) { "Invalid <path> element. d attribute is required" },
                pathLength = pathLength
            )
        }
    }
}
