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

import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class Marker(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    preserveAspectRatio: PreserveAspectRatio?,
    viewBox: Box?,
    @JvmField
    val markerUnitsAreUser: Boolean,
    @JvmField
    val refX: CSSLength?,
    @JvmField
    val refY: CSSLength?,
    @JvmField
    val markerWidth: CSSLength?,
    @JvmField
    val markerHeight: CSSLength?,
    @JvmField
    val orient: MarkerOrient?
) : ViewBoxContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    preserveAspectRatio = preserveAspectRatio,
    viewBox = viewBox
), NotDirectlyRendered {
    override fun getNodeName(): String {
        return "marker"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ViewBoxContainer.Builder<Marker>(document, parent) {
        private var markerUnitsAreUser: Boolean = false
        private var refX: CSSLength? = null
        private var refY: CSSLength? = null
        private var markerWidth: CSSLength? = null
        private var markerHeight: CSSLength? = null
        private var orient: MarkerOrient? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.markerUnits -> markerUnitsAreUser = value == "userSpaceOnUse"
                SVGAttr.refX -> refX = parseLength(value)
                SVGAttr.refY -> refY = parseLength(value)
                SVGAttr.markerWidth -> markerWidth = parseNonNegativeLength(value, "Invalid <marker> element. markerWidth cannot be negative")
                SVGAttr.markerHeight -> markerHeight = parseNonNegativeLength(value, "Invalid <marker> element. markerHeight cannot be negative")
                SVGAttr.orient -> orient = when (value) {
                    "auto" -> MarkerOrient.Auto
                    "auto-start-reverse" -> MarkerOrient.AutoStartReverse
                    else -> MarkerOrient.Angle(parseFloat(value))
                }
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): Marker {
            return Marker(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                preserveAspectRatio = getPreserveAspectRatio(),
                viewBox = getViewBox(),
                markerUnitsAreUser = markerUnitsAreUser,
                refX = refX,
                refY = refY,
                markerWidth = markerWidth,
                markerHeight = markerHeight,
                orient = orient
            )
        }
    }
}