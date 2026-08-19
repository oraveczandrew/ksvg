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
import androidx.collection.IntList
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.ColorParser
import hu.oandras.ksvg.render.animation.parseSemicolonColorList
import org.xml.sax.Attributes

internal class AnimateColor(
    baseParams: BaseParams,
    attributeName: SVGAttr,
    @JvmField
    val values: IntList?,
    @JvmField
    val from: Int?,
    @JvmField
    val to: Int?,
    @JvmField
    val by: Int?,
    durMs: Long,
    beginMs: Long,
    repeatCount: Int,
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
    ) : Animation.Builder<AnimateColor>(document, parent) {
        private var values: IntList? = null
        private var from: Int? = null
        private var to: Int? = null
        private var by: Int? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.values -> values = parseSemicolonColorList(value)
                SVGAttr.from -> from = ColorParser.parseColor(value).value
                SVGAttr.to -> to = ColorParser.parseColor(value).value
                SVGAttr.by -> by = ColorParser.parseColor(value).value
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): AnimateColor {
            return AnimateColor(
                baseParams = getBaseParams(),
                attributeName = requireNotNull(attributeName) { "Missing attributeName for <animate>" },
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
}
