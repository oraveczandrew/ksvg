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

package hu.oandras.ksvg.dom.animation

import androidx.collection.FloatList
import androidx.collection.MutableFloatList
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.TextScanner
import org.xml.sax.Attributes

internal sealed class AnimateTransform(
    @JvmField
    val transformType: TransformType,
    baseParams: BaseParams,
    @JvmField
    val values: FloatList?,
    @JvmField
    val from: FloatList?,
    @JvmField
    val to: FloatList?,
    @JvmField
    val by: FloatList?,
    durMs: Long,
    beginMs: Long,
    repeatCount: Float,
    repeatDurMs: Long,
    endMs: Long,
    fillFreeze: Boolean,
    additiveSum: Boolean,
    accumulateSum: Boolean,
    keyTimes: FloatList?,
    calcMode: CalcMode,
    keySplines: String?
) : Animation(
    baseParams = baseParams,
    attributeName = SVGAttr.transform,
    durMs = durMs,
    beginMs = beginMs,
    repeatCount = repeatCount,
    repeatDurMs = repeatDurMs,
    endMs = endMs,
    fillFreeze = fillFreeze,
    additiveSum = additiveSum,
    accumulateSum = accumulateSum,
    keyTimes = keyTimes,
    calcMode = calcMode,
    keySplines = keySplines
) {
    override fun getNodeName(): String {
        return "animateTransform"
    }

    override fun isValid(): Boolean {
        return super.isValid() && (values != null || to != null || by != null)
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Animation.Builder<AnimateTransform>(document, parent) {
        private var type: TransformType = TransformType.translate

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.type -> {
                    type = TransformType.entries.firstOrNull { it.name.equals(value, ignoreCase = true) }
                        ?: TransformType.translate
                }

                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): AnimateTransform {
            val values = valuesStr?.let { parseTransformValues(type, it) }
            val from = fromStr?.let { parseTransformValues(type, it) }
            val to = toStr?.let { parseTransformValues(type, it) }
            val by = byStr?.let { parseTransformValues(type, it) }

            val baseParams = getBaseParams()
            return when (type) {
                TransformType.translate -> AnimateTranslate(
                    baseParams = baseParams,
                    values = values,
                    from = from,
                    to = to,
                    by = by,
                    durMs = durMs,
                    beginMs = beginMs,
                    repeatCount = repeatCount,
                    repeatDurMs = repeatDurMs,
                    endMs = endMs,
                    fillFreeze = fillFreeze,
                    additiveSum = additiveSum,
                    accumulateSum = accumulateSum,
                    keyTimes = keyTimes,
                    calcMode = calcMode,
                    keySplines = keySplines
                )

                TransformType.scale -> AnimateScale(
                    baseParams = baseParams,
                    values = values,
                    from = from,
                    to = to,
                    by = by,
                    durMs = durMs,
                    beginMs = beginMs,
                    repeatCount = repeatCount,
                    repeatDurMs = repeatDurMs,
                    endMs = endMs,
                    fillFreeze = fillFreeze,
                    additiveSum = additiveSum,
                    accumulateSum = accumulateSum,
                    keyTimes = keyTimes,
                    calcMode = calcMode,
                    keySplines = keySplines
                )

                TransformType.rotate -> AnimateRotate(
                    baseParams = baseParams,
                    values = values,
                    from = from,
                    to = to,
                    by = by,
                    durMs = durMs,
                    beginMs = beginMs,
                    repeatCount = repeatCount,
                    repeatDurMs = repeatDurMs,
                    endMs = endMs,
                    fillFreeze = fillFreeze,
                    additiveSum = additiveSum,
                    accumulateSum = accumulateSum,
                    keyTimes = keyTimes,
                    calcMode = calcMode,
                    keySplines = keySplines
                )

                TransformType.skewX -> AnimateSkewX(
                    baseParams = baseParams,
                    values = values,
                    from = from,
                    to = to,
                    by = by,
                    durMs = durMs,
                    beginMs = beginMs,
                    repeatCount = repeatCount,
                    repeatDurMs = repeatDurMs,
                    endMs = endMs,
                    fillFreeze = fillFreeze,
                    additiveSum = additiveSum,
                    accumulateSum = accumulateSum,
                    keyTimes = keyTimes,
                    calcMode = calcMode,
                    keySplines = keySplines
                )

                TransformType.skewY -> AnimateSkewY(
                    baseParams = baseParams,
                    values = values,
                    from = from,
                    to = to,
                    by = by,
                    durMs = durMs,
                    beginMs = beginMs,
                    repeatCount = repeatCount,
                    repeatDurMs = repeatDurMs,
                    endMs = endMs,
                    fillFreeze = fillFreeze,
                    additiveSum = additiveSum,
                    accumulateSum = accumulateSum,
                    keyTimes = keyTimes,
                    calcMode = calcMode,
                    keySplines = keySplines
                )
            }
        }

        private fun parseTransformValues(type: TransformType, value: String): FloatList {
            val scanner = TextScanner(value)
            val result = MutableFloatList()
            while (!scanner.empty()) {
                when (type) {
                    TransformType.translate -> {
                        val x = scanner.nextFloat()
                        require(!x.isNaN()) { "Invalid x value for translate" }
                        val y = scanner.possibleNextFloat().let { if (it.isNaN()) 0f else it }
                        result.add(x)
                        result.add(y)
                    }

                    TransformType.scale -> {
                        val sx = scanner.nextFloat()
                        require(!sx.isNaN()) { "Invalid sx value for scale" }
                        val sy = scanner.possibleNextFloat().let { if (it.isNaN()) sx else it }
                        result.add(sx)
                        result.add(sy)
                    }

                    TransformType.rotate -> {
                        val angle = scanner.nextFloat()
                        require(!angle.isNaN()) { "Invalid angle for rotate" }
                        val cx = scanner.possibleNextFloat()
                        if (cx.isNaN()) {
                            result.add(angle)
                            result.add(0f)
                            result.add(0f)
                        } else {
                            scanner.skipWhitespace()
                            val cy = scanner.nextFloat()
                            require(!cy.isNaN()) {
                                "Invalid cy value for rotate"
                            }
                            result.add(angle)
                            result.add(cx)
                            result.add(cy)
                        }
                    }

                    TransformType.skewX, TransformType.skewY -> {
                        val angle = scanner.nextFloat()
                        require(!angle.isNaN()) { "Invalid angle for skew" }
                        result.add(angle)
                    }
                }
                scanner.skipSemicolonWhitespace()
            }
            return result
        }
    }
}
