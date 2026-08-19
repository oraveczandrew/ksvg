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
import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parsePath
import hu.oandras.ksvg.parser.parsePointsAsPath
import hu.oandras.ksvg.parser.parseSemicolonPathList
import hu.oandras.ksvg.parser.parseSemicolonPointsPathList
import org.xml.sax.Attributes

internal class AnimatePath(
    baseParams: BaseParams,
    attributeName: SVGAttr,
    @JvmField
    val values: List<PathDefinition>?,
    @JvmField
    val from: PathDefinition?,
    @JvmField
    val to: PathDefinition?,
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
        return super.isValid() && (!values.isNullOrEmpty() || to != null)
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Animation.Builder<AnimatePath>(document, parent) {
        private var values: List<PathDefinition>? = null
        private var from: PathDefinition? = null
        private var to: PathDefinition? = null

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

        private var valuesString: String? = null
        private var fromString: String? = null
        private var toString: String? = null

        override fun build(): AnimatePath {
            val attrName = attributeName
            val isPoints = attrName == SVGAttr.points
            
            if (valuesString != null) {
                values = if (isPoints) parseSemicolonPointsPathList(valuesString!!) else parseSemicolonPathList(valuesString!!)
            }
            if (fromString != null) {
                from = if (isPoints) parsePointsAsPath(fromString!!) else parsePath(fromString!!)
            }
            if (toString != null) {
                to = if (isPoints) parsePointsAsPath(toString!!) else parsePath(toString!!)
            }

            return AnimatePath(
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
                keySplines = keySplines
            )
        }
    }
}
