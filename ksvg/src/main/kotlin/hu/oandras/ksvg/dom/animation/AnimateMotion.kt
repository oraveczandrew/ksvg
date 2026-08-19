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
import hu.oandras.ksvg.dom.core.ChildrenStore
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.DomParent
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parsePath
import hu.oandras.ksvg.render.animation.parseSemicolonFloatList
import org.xml.sax.Attributes

internal class AnimateMotion(
    baseParams: BaseParams,
    @JvmField
    val path: PathDefinition?,
    @JvmField
    val rotate: String?,
    @JvmField
    val keyPoints: FloatList?,
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
), Container, DomParent by ChildrenStore() {

    override fun getNodeName(): String = "animateMotion"

    override fun isValid(): Boolean {
        return super.isValid() && (path != null || getChildren().any { it is MPath })
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Animation.Builder<AnimateMotion>(document, parent) {
        private var path: PathDefinition? = null
        private var rotate: String? = null
        private var keyPoints: FloatList? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.path -> path = parsePath(value)
                SVGAttr.rotate -> rotate = value
                SVGAttr.keyPoints -> keyPoints = parseSemicolonFloatList(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): AnimateMotion {
            return AnimateMotion(
                baseParams = getBaseParams(),
                path = path,
                rotate = rotate,
                keyPoints = keyPoints,
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

internal class MPath(
    baseParams: BaseParams,
    @JvmField
    val href: String?
) : ElementBase(baseParams) {
    override fun getNodeName(): String = "mpath"

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ElementBase.Builder<MPath>(document, parent) {
        private var href: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.href -> href = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): MPath {
            return MPath(getBaseParams(), href)
        }
    }
}
