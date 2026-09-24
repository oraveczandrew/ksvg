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
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.render.animation.normalizeDashArrays
import hu.oandras.ksvg.render.animation.parseDashArrayKeyframes
import hu.oandras.ksvg.render.animation.parseSingleDashArray
import org.xml.sax.Attributes

internal class AnimateDashArray(
    baseParams: BaseParams,
    attributeName: SVGAttr,
    @JvmField
    val values: FloatList?,
    @JvmField
    val stride: Int,
    @JvmField
    val from: FloatArray?,
    @JvmField
    val to: FloatArray?,
    @JvmField
    val by: FloatArray?,
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
    attributeName = attributeName,
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
        return "animate"
    }

    override fun isValid(): Boolean {
        return super.isValid() && (values != null || to != null || by != null)
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Animation.Builder<AnimateDashArray>(document, parent) {
        private var values: FloatList? = null
        private var stride: Int = 0
        private var from: FloatArray? = null
        private var to: FloatArray? = null
        private var by: FloatArray? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.values -> {
                    val keyframes = parseDashArrayKeyframes(value)
                    if (keyframes.isNotEmpty()) {
                        val (s, normalized) = normalizeDashArrays(keyframes)
                        stride = s
                        values = normalized
                    }
                }

                SVGAttr.from -> from = parseSingleDashArray(value)
                SVGAttr.to -> to = parseSingleDashArray(value)
                SVGAttr.by -> by = parseSingleDashArray(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): AnimateDashArray {
            return AnimateDashArray(
                baseParams = getBaseParams(),
                attributeName = requireNotNull(attributeName) { "Missing attributeName for <animate>" },
                values = values,
                stride = stride,
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
}
