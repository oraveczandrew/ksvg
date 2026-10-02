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

import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.parser.parseFloatList
import org.xml.sax.Attributes

internal class FeDiffuseLighting(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?,
    result: String?,
    `in`: String?,
    @JvmField
    val surfaceScale: Float,
    @JvmField
    val diffuseConstant: Float,
    /**
     * `kernelUnitLength` in filter primitive units, or 0f when unspecified
     * (default = one offscreen pixel). Non-positive values fall back to the
     * default per spec and are stored as 0f.
     */
    @JvmField
    val kernelUnitLengthX: Float,
    @JvmField
    val kernelUnitLengthY: Float,
) : FilterPrimitive(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    x = x,
    y = y,
    width = width,
    height = height,
    result = result,
    `in` = `in`,
), FeLighting {

    override var light: Lighting? = null

    override fun getNodeName(): String {
        return "feDiffuseLighting"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeDiffuseLighting>(
        document = document,
        parent = parent
    ) {
        private var surfaceScale: Float = 1f
        private var diffuseConstant: Float = 1f
        private var kernelUnitLengthX: Float = 0f
        private var kernelUnitLengthY: Float = 0f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.surfaceScale -> surfaceScale = parseFloat(value)
                SVGAttr.diffuseConstant -> diffuseConstant = parseFloat(value)
                SVGAttr.kernelUnitLength -> {
                    val values = parseFloatList(value)
                    // -1f sentinel instead of null: only > 0 survives below,
                    // so a missing entry and a non-positive one agree.
                    val x = values.getOrElse(0) { -1f }
                    val y = values.getOrElse(1) { x }
                    kernelUnitLengthX = if (x > 0f) x else 0f
                    kernelUnitLengthY = if (y > 0f) y else 0f
                }
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeDiffuseLighting {
            return FeDiffuseLighting(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                surfaceScale = surfaceScale,
                diffuseConstant = diffuseConstant,
                kernelUnitLengthX = kernelUnitLengthX,
                kernelUnitLengthY = kernelUnitLengthY,
            )
        }
    }
}