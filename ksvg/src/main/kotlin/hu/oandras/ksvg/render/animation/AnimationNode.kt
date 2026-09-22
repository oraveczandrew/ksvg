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

package hu.oandras.ksvg.render.animation

import android.graphics.Path
import android.graphics.PathMeasure
import androidx.collection.FloatList
import androidx.collection.IntList
import hu.oandras.ksvg.dom.animation.AnimateColor
import hu.oandras.ksvg.dom.animation.AnimateDashArray
import hu.oandras.ksvg.dom.animation.AnimateFloat
import hu.oandras.ksvg.dom.animation.AnimateMotion
import hu.oandras.ksvg.dom.animation.AnimatePath
import hu.oandras.ksvg.dom.animation.AnimateTransform
import hu.oandras.ksvg.dom.animation.Animation
import hu.oandras.ksvg.dom.animation.CalcMode
import hu.oandras.ksvg.dom.animation.TransformType
import hu.oandras.ksvg.dom.core.PathDefinition
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.render.PathAppender
import hu.oandras.ksvg.utils.CubicBezier

internal sealed class AnimationNode(
    @JvmField
    val sourceElement: Animation
) {
    @JvmField
    val attributeName: SVGAttr = sourceElement.attributeName

    @JvmField
    val durMs: Long = sourceElement.durMs

    @JvmField
    val beginMs: Long = sourceElement.beginMs

    @JvmField
    val repeatCount: Int = sourceElement.repeatCount

    @JvmField
    val repeatDurMs: Long = sourceElement.repeatDurMs

    @JvmField
    val endMs: Long = sourceElement.endMs

    @JvmField
    val fillFreeze: Boolean = sourceElement.fillFreeze

    @JvmField
    val additiveSum: Boolean = sourceElement.additiveSum

    @JvmField
    val accumulateSum: Boolean = sourceElement.accumulateSum

    @JvmField
    val keyTimes: FloatList? = sourceElement.keyTimes

    @JvmField
    val calcMode: CalcMode = sourceElement.calcMode

    val repeatIndefinite: Boolean get() = repeatCount == Animation.REPEAT_INDEFINITE

    override fun toString(): String {
        return buildString {
            append("AnimationNode(sourceElement=")
            append(sourceElement)
            append(", attributeName=")
            append(attributeName)
            append(", durMs=")
            append(durMs)
            append(", beginMs=")
            append(beginMs)
            append(", repeatCount=")
            append(repeatCount)
            append(", repeatDurMs=")
            append(repeatDurMs)
            append(", endMs=")
            append(endMs)
            append(", fillFreeze=")
            append(fillFreeze)
            append(", additiveSum=")
            append(additiveSum)
            append(", accumulateSum=")
            append(accumulateSum)
            append(", keyTimes=")
            append(keyTimes)
            append(", calcMode=")
            append(calcMode)
            append(", repeatIndefinite=")
            append(repeatIndefinite)
            append(")")
        }
    }
}

internal class AnimateTransformNode(
    sourceElement: AnimateTransform,
    @JvmField
    val transformType: TransformType,
    @JvmField
    val stride: Int,
    @JvmField
    val effectiveValues: FloatList,
    @JvmField
    val parsedKeySplines: List<CubicBezier>? = null,
    @JvmField
    val pacedKeyTimes: FloatList? = null
) : AnimationNode(sourceElement)

internal class AnimateMotionNode(
    sourceElement: AnimateMotion,
    @JvmField
    val path: Path?,
    @JvmField
    val rotate: String?,
    @JvmField
    val keyPoints: FloatList?,
    @JvmField
    val parsedKeySplines: List<CubicBezier>? = null,
    @JvmField
    val pacedKeyTimes: FloatList? = null
) : AnimationNode(sourceElement) {
    @JvmField
    val reusablePathMeasure = PathMeasure()
    @JvmField
    val pos = FloatArray(2)
    @JvmField
    val tan = FloatArray(2)
    @JvmField
    val startPos = FloatArray(2)
    @JvmField
    val endPos = FloatArray(2)
}

internal class AnimateFloatNode(
    sourceElement: AnimateFloat,
    @JvmField
    val effectiveValues: FloatList,
    @JvmField
    val parsedKeySplines: List<CubicBezier>? = null,
    @JvmField
    val pacedKeyTimes: FloatList? = null,
    /**
     * True for SMIL `by`-only / `to`-only animations, where `effectiveValues`
     * is a normalized 0→1 ramp and the endpoint is resolved against the base
     * value at apply time (the base is unknown at tree-build time):
     * - `by`-only: `base + byValue * p`
     * - `to`-only + `additive="sum"`: `base + endValue * p`
     * - `to`-only + replace: `base + (endValue - base) * p`
     */
    @JvmField
    val baseRelative: Boolean = false,
    @JvmField
    val endValue: Float = 0f,
    @JvmField
    val byValue: Float? = null
) : AnimationNode(sourceElement) {
    override fun toString(): String {
        return "AnimateFloatNode(effectiveValues=$effectiveValues, parsedKeySplines=$parsedKeySplines, pacedKeyTimes=$pacedKeyTimes, baseRelative=$baseRelative) ${super.toString()}"
    }
}

internal class AnimatePathNode(
    sourceElement: AnimatePath,
    @JvmField
    val effectiveValues: List<PathDefinition>,
    @JvmField
    val parsedKeySplines: List<CubicBezier>? = null,
) : AnimationNode(sourceElement) {
    @JvmField
    val pathAppender = PathAppender()
}

internal class AnimateColorNode(
    sourceElement: AnimateColor,
    @JvmField
    val effectiveValues: IntList,
    @JvmField
    val parsedKeySplines: List<CubicBezier>? = null,
    @JvmField
    val pacedKeyTimes: FloatList? = null
) : AnimationNode(sourceElement)

internal class AnimateDashArrayNode(
    sourceElement: AnimateDashArray,
    @JvmField
    val effectiveValues: FloatList,
    @JvmField
    val stride: Int,
    @JvmField
    val parsedKeySplines: List<CubicBezier>? = null,
    @JvmField
    val pacedKeyTimes: FloatList? = null
) : AnimationNode(sourceElement) {
    @JvmField
    val dashBuffer = FloatArray(stride)
}