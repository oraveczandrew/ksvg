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
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.render.animation.parseClockValueMillis
import hu.oandras.ksvg.render.animation.parseSemicolonFloatList
import org.xml.sax.Attributes

internal sealed class Animation(
    baseParams: BaseParams,
    @JvmField
    val attributeName: SVGAttr,
    @JvmField
    val durMs: Long,
    @JvmField
    val beginMs: Long,
    @JvmField
    val repeatCount: Int,
    @JvmField
    val repeatDurMs: Long,
    @JvmField
    val endMs: Long,
    @JvmField
    val fillFreeze: Boolean,
    @JvmField
    val additiveSum: Boolean,
    @JvmField
    val accumulateSum: Boolean,
    @JvmField
    val keyTimes: FloatList?,
    @JvmField
    val calcMode: CalcMode,
    @JvmField
    val keySplines: String?
) : ElementBase(
    baseParams = baseParams,
) {

    val repeatIndefinite: Boolean get() = repeatCount == REPEAT_INDEFINITE

    override fun getNodeName(): String = "animation"

    open fun isValid(): Boolean {
        return durMs > 0L
    }

    companion object {
        const val REPEAT_INDEFINITE = -1
    }

    abstract class Builder<T : Animation>(
        document: SVGImpl,
        parent: Container?,
    ) : ElementBase.Builder<T>(document, parent) {
        protected var attributeName: SVGAttr? = null
        protected var durMs: Long = 0L
        protected var beginMs: Long = 0L
        protected var repeatCount: Int = 1
        protected var repeatDurMs: Long = 0L
        protected var endMs: Long = Long.MAX_VALUE
        protected var fillFreeze: Boolean = false
        protected var additiveSum: Boolean = false
        protected var accumulateSum: Boolean = false
        protected var keyTimes: FloatList? = null
        internal var calcMode: CalcMode = CalcMode.linear
        protected var keySplines: String? = null

        protected var valuesStr: String? = null
        protected var fromStr: String? = null
        protected var toStr: String? = null
        protected var byStr: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.attributeName -> attributeName = SVGAttr.fromString(value)
                SVGAttr.dur -> durMs = parseClockValueMillis(value)
                SVGAttr.begin -> beginMs = parseClockValueMillis(value)
                SVGAttr.repeatCount -> repeatCount = if (value == "indefinite") {
                    REPEAT_INDEFINITE
                } else {
                    value.toIntOrNull()?.coerceAtLeast(1) ?: 1
                }
                SVGAttr.repeatDur -> repeatDurMs = if (value == "indefinite") {
                    REPEAT_INDEFINITE.toLong()
                } else {
                    parseClockValueMillis(value)
                }
                SVGAttr.end -> endMs = parseClockValueMillis(value)
                SVGAttr.fill -> fillFreeze = (value == "freeze")
                SVGAttr.additive -> additiveSum = (value == "sum")
                SVGAttr.accumulate -> accumulateSum = (value == "sum")
                SVGAttr.keyTimes -> keyTimes = parseSemicolonFloatList(value)
                SVGAttr.calcMode -> calcMode = CalcMode.valueOf(value.lowercase())
                SVGAttr.keySplines -> keySplines = value
                SVGAttr.values -> valuesStr = value
                SVGAttr.from -> fromStr = value
                SVGAttr.to -> toStr = value
                SVGAttr.by -> byStr = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        abstract override fun build(): T
    }
}