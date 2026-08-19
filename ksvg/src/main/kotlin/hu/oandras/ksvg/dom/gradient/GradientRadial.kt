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
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseLength
import hu.oandras.ksvg.parser.parseNonNegativeLength
import org.xml.sax.Attributes

internal class GradientRadial(
    baseParams: BaseParams,
    gradientUnitsAreUser: Boolean?,
    gradientTransform: Matrix?,
    spreadMethod: GradientSpread?,
    href: String?,
    @JvmField
    var cx: CSSLength?,
    @JvmField
    var cy: CSSLength?,
    @JvmField
    var r: CSSLength?,
    @JvmField
    var fx: CSSLength?,
    @JvmField
    var fy: CSSLength?,
    @JvmField
    var fr: CSSLength?,
) : Gradient(
    baseParams = baseParams,
    gradientUnitsAreUser = gradientUnitsAreUser,
    gradientTransform = gradientTransform,
    spreadMethod = spreadMethod,
    href = href
) {

    override fun getNodeName(): String {
        return "radialGradient"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Gradient.Builder<GradientRadial>(
        document = document,
        parent = parent
    ) {
        private var cx: CSSLength? = null

        private var cy: CSSLength? = null

        private var r: CSSLength? = null

        private var fx: CSSLength? = null

        private var fy: CSSLength? = null

        private var fr: CSSLength? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.cx -> cx = parseLength(value)
                SVGAttr.cy -> cy = parseLength(value)
                SVGAttr.r -> r = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <radialGradient> element. r cannot be negative"
                )

                SVGAttr.fx -> fx = parseLength(value)
                SVGAttr.fy -> fy = parseLength(value)
                SVGAttr.fr -> fr = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <radialGradient> element. fr cannot be negative"
                )

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): GradientRadial {
            return GradientRadial(
                baseParams = getBaseParams(),
                gradientUnitsAreUser = getGradientUnitsAreUser(),
                gradientTransform = getGradientTransform(),
                spreadMethod = getSpreadMethod(),
                href = getHref(),
                cx = cx,
                cy = cy,
                r = r,
                fx = fx,
                fy = fy,
                fr = fr,
            )
        }
    }
}