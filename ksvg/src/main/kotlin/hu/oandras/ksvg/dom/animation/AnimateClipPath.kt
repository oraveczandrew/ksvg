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
import hu.oandras.ksvg.dom.style.CSSClipPath
import hu.oandras.ksvg.dom.style.parseClipPathEndpoint
import hu.oandras.ksvg.dom.style.parseSemicolonClipPathList
import org.xml.sax.Attributes

/**
 * SMIL animation of the `clip-path` property
 * (`<animate attributeName="clip-path" .../>`). Endpoints are parsed CSS
 * `clip-path` values; interpolation between same-kind basic shapes follows
 * the CSS Shapes rule (same function, same reference box, same arity),
 * everything else is discrete. There is no `by` form for shapes by design
 * (mirrors [AnimatePath], which has no `by` either).
 */
internal class AnimateClipPath(
    baseParams: BaseParams,
    attributeName: SVGAttr,
    @JvmField
    val values: List<CSSClipPath>?,
    @JvmField
    val from: CSSClipPath?,
    @JvmField
    val to: CSSClipPath?,
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
    keySplines: String?,
    @JvmField
    val parsingFailed: Boolean = false
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
        return super.isValid() && !parsingFailed && (!values.isNullOrEmpty() || to != null)
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Animation.Builder<AnimateClipPath>(document, parent) {
        private var values: List<CSSClipPath>? = null
        private var from: CSSClipPath? = null
        private var to: CSSClipPath? = null
        private var parsingFailed: Boolean = false

        private var valuesString: String? = null
        private var fromString: String? = null
        private var toString: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.values -> valuesString = value
                SVGAttr.from -> fromString = value
                SVGAttr.to -> toString = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): AnimateClipPath {
            val attrName = attributeName
            val valuesString = valuesString
            if (valuesString != null) {
                values = parseSemicolonClipPathList(valuesString)
                if (values == null) parsingFailed = true
            }
            val fromString = fromString
            if (fromString != null) {
                from = parseClipPathEndpoint(fromString)
                if (from == null) parsingFailed = true
            }
            val toString = toString
            if (toString != null) {
                to = parseClipPathEndpoint(toString)
                if (to == null) parsingFailed = true
            }

            return AnimateClipPath(
                baseParams = getBaseParams(),
                attributeName = requireNotNull(attrName) { "Missing attributeName for <animate>" },
                values = values,
                from = from,
                to = to,
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
                keySplines = keySplines,
                parsingFailed = parsingFailed
            )
        }
    }
}
