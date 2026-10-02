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
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseFloat
import hu.oandras.ksvg.parser.parseFloatList
import java.util.Locale
import org.xml.sax.Attributes

internal class FeConvolveMatrix(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?,
    result: String?,
    `in`: String?,
    @JvmField
    val orderX: Int,
    @JvmField
    val orderY: Int,
    @JvmField
    val kernelMatrix: FloatArray?,
    @JvmField
    val divisor: Float,
    @JvmField
    val bias: Float,
    @JvmField
    val targetX: Int?,
    @JvmField
    val targetY: Int?,
    /**
     * `kernelUnitLength` in filter primitive units, or 0f when unspecified
     * (default = one offscreen pixel). Non-positive values fall back to the
     * default per spec and are stored as 0f.
     */
    @JvmField
    val kernelUnitLengthX: Float,
    @JvmField
    val kernelUnitLengthY: Float,
    @JvmField
    val edgeMode: ConvolveMatrixEdgeMode,
    @JvmField
    val preserveAlpha: Boolean,
) : FilterPrimitive(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    x = x,
    y = y,
    width = width,
    height = height,
    result = result,
    `in` = `in`,
) {
    
    override fun getNodeName(): String {
        return "feConvolveMatrix"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : FilterPrimitive.Builder<FeConvolveMatrix>(
        document = document,
        parent = parent
    ) {
        private var orderX: Int = 3
        private var orderY: Int = 3
        private var kernelMatrix: FloatArray? = null
        private var divisor: Float = 0f
        private var bias: Float = 0f
        private var targetX: Int? = null
        private var targetY: Int? = null
        private var kernelUnitLengthX: Float = 0f
        private var kernelUnitLengthY: Float = 0f
        private var edgeMode: ConvolveMatrixEdgeMode = ConvolveMatrixEdgeMode.duplicate
        private var preserveAlpha: Boolean = false

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.order -> {
                    val values = parseFloatList(value)
                    orderX = values.getOrElse(0) { 3f }.toInt()
                    orderY = values.getOrElse(1) { orderX.toFloat() }.toInt()
                }
                SVGAttr.kernelMatrix -> kernelMatrix = parseFloatList(value)
                SVGAttr.divisor -> divisor = parseFloat(value)
                SVGAttr.bias -> bias = parseFloat(value)
                SVGAttr.targetX -> targetX = parseFloat(value).toInt()
                SVGAttr.targetY -> targetY = parseFloat(value).toInt()
                SVGAttr.edgeMode -> edgeMode = if (value.isEmpty()) ConvolveMatrixEdgeMode.duplicate else try {
                    ConvolveMatrixEdgeMode.valueOf(value.lowercase(Locale.US))
                } catch (_: IllegalArgumentException) {
                    throw KSVGParseException("Invalid matrix edge mode: $value")
                }
                SVGAttr.kernelUnitLength -> {
                    val values = parseFloatList(value)
                    // -1f sentinel instead of null: only > 0 survives below,
                    // so a missing entry and a non-positive one agree.
                    val x = values.getOrElse(0) { -1f }
                    val y = values.getOrElse(1) { x }
                    kernelUnitLengthX = if (x > 0f) x else 0f
                    kernelUnitLengthY = if (y > 0f) y else 0f
                }
                SVGAttr.preserveAlpha -> preserveAlpha = value.equals("true", ignoreCase = true)
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeConvolveMatrix {
            return FeConvolveMatrix(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                x = getX(),
                y = getY(),
                width = getWidth(),
                height = getHeight(),
                result = getResult(),
                `in` = getIn(),
                orderX = orderX,
                orderY = orderY,
                kernelMatrix = kernelMatrix,
                divisor = divisor,
                bias = bias,
                targetX = targetX,
                targetY = targetY,
                kernelUnitLengthX = kernelUnitLengthX,
                kernelUnitLengthY = kernelUnitLengthY,
                edgeMode = edgeMode,
                preserveAlpha = preserveAlpha,
            )
        }
    }
}