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

import android.graphics.Matrix
import android.graphics.Path
import hu.oandras.ksvg.BuildConfig
import hu.oandras.ksvg.compat.supportsWordSpacing
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.animation.CalcMode
import hu.oandras.ksvg.dom.animation.TransformType
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.HasTransform
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.dom.shapes.CircleShape
import hu.oandras.ksvg.dom.shapes.EllipseShape
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PathShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.shapes.PolygonShape
import hu.oandras.ksvg.dom.shapes.RectShape
import hu.oandras.ksvg.dom.style.ColorValue
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.logW
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.FilterPrimitiveRenderNode
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.GroupRenderNode
import hu.oandras.ksvg.render.PathRenderNode
import hu.oandras.ksvg.render.PatternRenderNode
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.calculatePathBounds
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.updatePathAndBoundingBox
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.interpolateColor
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.toDegrees
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.atan2
import kotlin.math.tan

context(renderContext: AnimationContext)
internal fun RenderNode<*>.updateAnimations(animationTimeMs: Long): Boolean {
    if (!hasAnimations()) return false

    var changed = false
    var contentChanged = false
    val obj = sourceElement

    val matrix = this.transform ?: Matrix().also {
        this.transform = it
    }

    // Update transform
    renderContext.matrixPool.withPooledObject { tempMatrix ->
        val baseTransform = animationBaseTransform ?: (obj as? HasTransform)?.getTransform()
        if (baseTransform != null) {
            tempMatrix.set(baseTransform)
        } else {
            tempMatrix.reset()
        }

        if (obj is ElementBase) {
            animationNodes?.let {
                renderContext.matrixPool.withPooledObject { animMatrix ->
                    animMatrix.reset()

                    it.forEachElement { animation ->
                        when (animation) {
                            is AnimateTransformNode -> {
                                animation.toMatrix(animationTimeMs, animMatrix)
                                tempMatrix.preConcat(animMatrix)
                            }

                            is AnimateMotionNode -> {
                                if (animation.applyMotionAt(animationTimeMs, animMatrix)) {
                                    tempMatrix.preConcat(animMatrix)
                                }
                            }

                            else -> {}
                        }
                    }
                }
            }

                // Revert to the resolved base style + paint state before applying this
                // frame's animation values, so a finished `fill="remove"` animation
                // reverts to the base and `additive="sum"` adds to the base value
                // (instead of compounding the previous frame's result).
                val baseState = baseAnimatorState
                    ?: RendererState().apply { apply(renderState) }.also { baseAnimatorState = it }
                renderState.apply(baseState)

                // Update animated styles in renderState
                renderContext.styleBuilderPool.withPooledObject { builder ->
                    builder.reset(renderState.style)
                    if (applyAnimatedStyle(renderState, builder, this)) {
                        renderState.style = builder.build()
                        contentChanged = true
                    }
                }
        }

        if (matrix != tempMatrix) {
            matrix.set(tempMatrix)
            contentChanged = true
        }
    }

    if (maskNode?.updateAnimations(animationTimeMs) == true) contentChanged = true
    if (markerStartNode?.updateAnimations(animationTimeMs) == true) contentChanged = true
    if (markerMidNode?.updateAnimations(animationTimeMs) == true) contentChanged = true
    if (markerEndNode?.updateAnimations(animationTimeMs) == true) contentChanged = true
    if (fillPatternNode?.updateAnimations(animationTimeMs) == true) contentChanged = true
    if (strokePatternNode?.updateAnimations(animationTimeMs) == true) contentChanged = true

    if (filterNode?.updateAnimations(animationTimeMs) == true) changed = true

    if (this is PathRenderNode) {
        when (val shape = sourceElement) {
            is RectShape -> if (updatePathAndBoundingBox(shape, path, this)) contentChanged = true
            is CircleShape -> if (updatePathAndBoundingBox(shape, path, this)) contentChanged = true
            is EllipseShape -> if (updatePathAndBoundingBox(shape, path, this)) contentChanged = true
            is LineShape -> if (updatePathAndBoundingBox(shape, path, this)) contentChanged = true
            is PolyLineShape -> if (updatePathAndBoundingBox(shape, path, this, animationTimeMs)) contentChanged = true
            is PathShape -> if (updatePathAndBoundingBox(shape, path, this, animationTimeMs)) contentChanged = true
        }
    }

    if (this is GroupRenderNode) {
        children.forEachElement {
            if (it.updateAnimations(animationTimeMs)) contentChanged = true
        }
    } else if (this is PatternRenderNode) {
        children.forEachElement {
            if (it.updateAnimations(animationTimeMs)) contentChanged = true
        }
    }

    if (contentChanged) {
        changed = true
    }

    if (changed) {
        notifyChange(contentChanged)
    }
    return changed
}

context(renderContext: AnimationContext)
internal fun updatePathAndBoundingBox(
    obj: PolyLineShape,
    outPath: Path,
    node: PathRenderNode,
    animationTimeMs: Long,
): Boolean {
    val originalPoints = obj.points ?: return false
    val stride = originalPoints.size
    var animatedPoints: FloatArray? = null
    var pathChanged = false

    node.animationNodes?.forEachElement { anim ->
        if (anim is AnimateFloatNode && anim.attributeName == SVGAttr.points) {
            val buf = node.pointsBuffer.getWithSize(stride)
            if (anim.withPointsAt(animationTimeMs, stride, buf)) {
                animatedPoints = buf
            }
        } else if (anim is AnimatePathNode && anim.attributeName == SVGAttr.points) {
            if (anim.withPathAt(animationTimeMs, outPath)) {
                pathChanged = true
            }
        }
    }

    return if (pathChanged) {
        if (obj is PolygonShape) {
            outPath.close()
        }
        val box = calculatePathBounds(outPath, obj.boundingBox)
        obj.boundingBox = box
        node.boundingBox = box
        true
    } else {
        val changed = updatePathAndBoundingBox(obj, outPath, animatedPoints)
        animatedPoints != null || changed
    }
}

context(renderContext: AnimationContext)
internal fun updatePathAndBoundingBox(
    obj: PathShape,
    outPath: Path,
    node: PathRenderNode,
    animationTimeMs: Long,
): Boolean {
    if (obj.d == null) return false

    var dChanged = false
    node.animationNodes?.forEachElement { anim ->
        if (anim is AnimatePathNode && anim.attributeName == SVGAttr.d) {
            if (anim.withPathAt(animationTimeMs, outPath)) {
                dChanged = true
            }
        }
    }

    return if (dChanged) {
        val box = calculatePathBounds(outPath, obj.boundingBox)
        obj.boundingBox = box
        node.boundingBox = box
        true
    } else {
        false
    }
}

context(renderContext: AnimationContext)
internal fun FilterRenderNode.updateAnimations(animationTimeMs: Long): Boolean {
    var changed = false
    primitives.forEachElement {
        if (it.updateAnimations(animationTimeMs)) changed = true
    }
    if (changed) {
        version++
    }
    return changed
}

context(_: AnimationContext)
internal fun FilterPrimitiveRenderNode<*>.updateAnimations(animationTimeMs: Long): Boolean {
    var changed = false
    animationNodes?.forEachElement { animation ->
        when (animation) {
            is AnimateFloatNode -> {
                animation.withValueAt(animationTimeMs) { valAt ->
                    val attributeName = animation.attributeName
                    val additiveSum = animation.additiveSum

                    when (this) {
                        is FeGaussianBlurRenderNode -> {
                            if (attributeName == SVGAttr.stdDeviation) {
                                val newVal = if (additiveSum) stdDeviationX + valAt else valAt
                                if (stdDeviationX != newVal || stdDeviationY != newVal) {
                                    stdDeviationX = newVal
                                    stdDeviationY = newVal
                                    changed = true
                                }
                            }
                        }

                        is FeOffsetRenderNode -> {
                            if (attributeName == SVGAttr.dx) {
                                val newVal = if (additiveSum) dx + valAt else valAt
                                if (dx != newVal) {
                                    dx = newVal
                                    changed = true
                                }
                            } else if (attributeName == SVGAttr.dy) {
                                val newVal = if (additiveSum) dy + valAt else valAt
                                if (dy != newVal) {
                                    dy = newVal
                                    changed = true
                                }
                            }
                        }

                        else -> {}
                    }
                }
            }

            else -> {}
        }
    }
    if (changed) {
        version++
    }
    return changed
}

context(renderContext: AnimationContext)
internal fun applyAnimatedStyle(
    state: RendererState,
    builder: Style.Builder,
    node: RenderNode<*>,
): Boolean {
    val sourceElement = node.sourceElement
    return sourceElement is ElementBase
            && applyAnimatedStyle(state, builder, node.animationNodes)
}

context(renderContext: AnimationContext)
internal fun applyAnimatedStyle(
    state: RendererState,
    builder: Style.Builder,
    animationNodes: List<AnimationNode>?,
): Boolean {
    var changed = false

    animationNodes?.forEachElement { animation ->
        when (animation) {
            is AnimateFloatNode -> {
                animation.withValueAt(renderContext.animationTimeMs) { valAt ->
                    if (applyFloatAnimation(state, builder, animation.attributeName, valAt, animation)) {
                        changed = true
                    }
                }
            }

            is AnimateColorNode -> {
                val baseColor = baseColorFor(state, builder, animation.attributeName)
                animation.withColorAt(renderContext.animationTimeMs, baseColor) { color ->
                    if (applyColorAnimation(state, builder, animation.attributeName, color)) {
                        changed = true
                    }
                }
            }

            is AnimateDashArrayNode -> {
                val out = animation.dashBuffer
                if (animation.withDashArrayAt(renderContext.animationTimeMs, out)) {
                    if (animation.additiveSum) {
                        val baseDashResolved = builder.strokeDashArrayResolved
                        if (baseDashResolved != null) {
                            for (i in out.indices) {
                                out[i] += if (i < baseDashResolved.size) baseDashResolved[i] else 0f
                            }
                        } else {
                            val baseDash = builder.strokeDashArray
                            if (baseDash != null) {
                                for (i in out.indices) {
                                    out[i] += if (i < baseDash.size) {
                                        baseDash[i].floatValueInContext()
                                    } else {
                                        0f
                                    }
                                }
                            }
                        }
                    }

                    if (!out.contentEquals(builder.strokeDashArrayResolved)) {
                        builder.strokeDashArrayResolved = out.copyOf()
                        state.updateStrokeDash(
                            strokeDashArrayResolved = builder.strokeDashArrayResolved,
                            strokeDashOffsetResolved = builder.strokeDashOffsetResolved
                        )
                        changed = true
                    }
                }
            }

            is AnimateTransformNode -> {}
            is AnimateMotionNode -> {}
            is AnimatePathNode -> {}
        }
    }

    return changed
}

/**
 * Resolves an interpolated float animation value against the base value.
 *
 * Plain from-to/values animation replaces the base (or adds to it with
 * `additive="sum"`). SMIL `by`-only / `to`-only animations
 * ([AnimateFloatNode.baseRelative]) interpolate a normalized 0→1 ramp that is
 * resolved here: `by`-only adds `by * p`; `to`-only with `additive="sum"` adds
 * `to * p`; plain `to`-only interpolates `base → to`.
 */
context(renderContext: AnimationContext)
private fun resolveAnimatedFloat(base: Float, valAt: Float, animation: AnimateFloatNode): Float {
    if (!animation.baseRelative) {
        return if (animation.additiveSum) base + valAt else valAt
    }
    val by = animation.byValue
    if (by != null) return base + by * valAt
    return if (animation.additiveSum) {
        base + animation.endValue * valAt
    } else {
        base + (animation.endValue - base) * valAt
    }
}

context(renderContext: AnimationContext)
private fun applyFloatAnimation(
    state: RendererState,
    builder: Style.Builder,
    attributeName: SVGAttr,
    valAt: Float,
    animation: AnimateFloatNode
): Boolean {
    var changed = false
    when (attributeName) {
        SVGAttr.opacity -> {
            val newVal = resolveAnimatedFloat(builder.opacity, valAt, animation)
            if (builder.opacity != newVal) {
                builder.opacity = newVal
                changed = true
            }
        }

        SVGAttr.fill_opacity -> {
            val base = if (builder.fillOpacity.isNaN()) 1f else builder.fillOpacity
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (builder.fillOpacity != newVal) {
                builder.fillOpacity = newVal
                changed = true
            }
        }

        SVGAttr.stroke_opacity -> {
            val base = if (builder.strokeOpacity.isNaN()) 1f else builder.strokeOpacity
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (builder.strokeOpacity != newVal) {
                builder.strokeOpacity = newVal
                changed = true
            }
        }

        SVGAttr.stroke_width -> {
            val base = builder.strokeWidth?.floatValueInContext() ?: 1f
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (base != newVal) {
                val newStrokeWidth = CSSLength(newVal)
                builder.strokeWidth = newStrokeWidth
                state.strokeConfig.setStrokeWidth(newStrokeWidth.floatValueInContext())
                changed = true
            }
        }

        SVGAttr.stroke_dashoffset -> {
            val base = if (!builder.strokeDashOffsetResolved.isNaN()) {
                builder.strokeDashOffsetResolved
            } else {
                builder.strokeDashOffset?.floatValueInContext() ?: 0f
            }
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (base != newVal) {
                builder.strokeDashOffsetResolved = newVal
                state.updateStrokeDash(
                    strokeDashArrayResolved = builder.strokeDashArrayResolved, 
                    strokeDashOffsetResolved = newVal
                )
                changed = true
            }
        }

        SVGAttr.stroke_miterlimit -> {
            val base = builder.strokeMiterLimit
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (base != newVal) {
                builder.strokeMiterLimit = newVal
                state.strokeConfig.setStrokeMiter(newVal)
                changed = true
            }
        }

        SVGAttr.stop_opacity -> {
            val base = if (builder.stopOpacity.isNaN()) 1f else builder.stopOpacity
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (builder.stopOpacity != newVal) {
                builder.stopOpacity = newVal
                changed = true
            }
        }

        SVGAttr.flood_opacity -> {
            val base = if (builder.floodOpacity.isNaN()) 1f else builder.floodOpacity
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (builder.floodOpacity != newVal) {
                builder.floodOpacity = newVal
                changed = true
            }
        }

        SVGAttr.solid_opacity -> {
            val base = if (builder.solidOpacity.isNaN()) 1f else builder.solidOpacity
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (builder.solidOpacity != newVal) {
                builder.solidOpacity = newVal
                changed = true
            }
        }

        SVGAttr.viewport_fill_opacity -> {
            val base = if (builder.viewportFillOpacity.isNaN()) 1f else builder.viewportFillOpacity
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (builder.viewportFillOpacity != newVal) {
                builder.viewportFillOpacity = newVal
                changed = true
            }
        }

        SVGAttr.font_size -> {
            val base = builder.fontSize?.floatValue() ?: 12f
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (base != newVal) {
                val newFontSize = CSSLength(newVal)
                builder.fontSize = newFontSize
                val currentFontSize = renderContext.currentFontSize
                state.fillConfig.setTextSize(newFontSize.floatValueInContext(currentFontSize))
                state.strokeConfig.setTextSize(newFontSize.floatValueInContext(currentFontSize))
                changed = true
            }
        }

        SVGAttr.letter_spacing -> {
            val base = builder.letterSpacing?.floatValueInContext() ?: 0f
            val newVal = resolveAnimatedFloat(base, valAt, animation)
            if (base != newVal) {
                val newSpacing = CSSLength(newVal)
                builder.letterSpacing = newSpacing
                var spacing = newSpacing.floatValueInContext()
                if (spacing > 0) {
                    val currentFontSize = renderContext.currentFontSize
                    if (currentFontSize > 0) {
                        spacing /= currentFontSize
                    }
                }
                state.fillConfig.setLetterSpacing(spacing)
                state.strokeConfig.setLetterSpacing(spacing)
                changed = true
            }
        }

        SVGAttr.word_spacing -> {
            if (supportsWordSpacing()) {
                val base = builder.wordSpacing?.floatValueInContext() ?: 0f
                val newVal = resolveAnimatedFloat(base, valAt, animation)
                if (base != newVal) {
                    val newSpacing = CSSLength(newVal)
                    builder.wordSpacing = newSpacing
                    val spacing = newSpacing.floatValueInContext()
                    state.fillConfig.setWordSpacing(spacing)
                    state.strokeConfig.setWordSpacing(spacing)
                    changed = true
                }
            }
        }

        SVGAttr.x, SVGAttr.y, SVGAttr.width, SVGAttr.height,
        SVGAttr.cx, SVGAttr.cy, SVGAttr.r, SVGAttr.rx, SVGAttr.ry,
        SVGAttr.x1, SVGAttr.y1, SVGAttr.x2, SVGAttr.y2,
        SVGAttr.dx, SVGAttr.dy, SVGAttr.stdDeviation,
        SVGAttr.stroke_dasharray,
        SVGAttr.offset, SVGAttr.points -> {
            // These geometric and presentation attributes are handled elsewhere (e.g., in PathUtils),
            // but they can be targeted by <animate>, so we ignore them here to avoid warnings.
        }

        else -> {
            if (BuildConfig.DEBUG) {
                renderContext.logW("KSVG") { "Unknown animated attribute: $attributeName" }
            }
        }
    }
    return changed
}

context(renderContext: AnimationContext)
private fun applyColorAnimation(
    state: RendererState,
    builder: Style.Builder,
    attributeName: SVGAttr,
    color: Int
): Boolean {
    var changed = false
    when (attributeName) {
        SVGAttr.fill -> {
            if (state.fillConfig.color != color) {
                builder.fill = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_FILL)
                state.fillConfig.setColor(color)
                changed = true
            }
        }

        SVGAttr.stroke -> {
            if (state.strokeConfig.color != color) {
                builder.stroke = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_STROKE)
                state.strokeConfig.setColor(color)
                changed = true
            }
        }

        SVGAttr.stop_color -> {
            if ((builder.stopColor as? ColorValue)?.value != color) {
                builder.stopColor = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_STOP_COLOR)
                changed = true
            }
        }

        SVGAttr.flood_color -> {
            if ((builder.floodColor as? ColorValue)?.value != color) {
                builder.floodColor = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_FLOOD_COLOR)
                changed = true
            }
        }

        SVGAttr.color -> {
            if (builder.color?.value != color) {
                builder.color = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_COLOR)
                changed = true
            }
        }

        SVGAttr.solid_color -> {
            if ((builder.solidColor as? ColorValue)?.value != color) {
                builder.solidColor = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_SOLID_COLOR)
                changed = true
            }
        }

        SVGAttr.lighting_color -> {
            if ((builder.lightingColor as? ColorValue)?.value != color) {
                builder.lightingColor = ColorValue.of(color)
                builder.addSpecifiedFlag(Style.SPECIFIED_LIGHTING_COLOR)
                changed = true
            }
        }

        else -> {
            if (BuildConfig.DEBUG) {
                renderContext.logW("KSVG") { "Unknown animated attribute: $attributeName" }
            }
        }
    }
    return changed
}

context(renderContext: AnimationContext)
internal fun animatedFloat(
    node: RenderNode<*>,
    attributeName: SVGAttr,
    defaultValue: Float
): Float {
    var value = defaultValue

    val animationTimeMs = renderContext.animationTimeMs
    node.animationNodes?.forEachElement { anim ->
        if (anim is AnimateFloatNode && anim.attributeName == attributeName) {
            anim.withValueAt(animationTimeMs) { valAt ->
                value = resolveAnimatedFloat(value, valAt, anim)
            }
        }
    }

    return value
}

internal inline fun AnimateFloatNode.withValueAt(animationTimeMs: Long, handler: (Float) -> Unit) {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)
    val effectiveKeyTimes = if (calcMode == CalcMode.paced) pacedKeyTimes ?: keyTimes else keyTimes

    var result = when (calcMode) {
        CalcMode.discrete -> selectAnimationSegmentDiscrete(effectiveValues, effectiveKeyTimes, progress)
        else -> selectAnimationSegment(effectiveValues, effectiveKeyTimes, progress, ::interpolate, parsedKeySplines)
    }

    if (accumulateSum) {
        val repeatCount = (elapsed / durMs).toInt()
        if (repeatCount > 0) {
            val range = effectiveValues[effectiveValues.size - 1] - effectiveValues[0]
            result += range * repeatCount
        }
    }

    handler.invoke(result)
}

internal inline fun AnimateColorNode.withColorAt(animationTimeMs: Long, baseColor: Int, handler: (Int) -> Unit) {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)

    val color = if (baseRelative) {
        // SMIL by-only / to-only: resolve against the base color. Discrete
        // freezes at the full delta (keyTimes/spline are meaningless without
        // `values` and are ignored).
        val p = if (calcMode == CalcMode.discrete) 1f else progress
        val by = byValue
        if (by != null) addColors(baseColor, by, p) else interpolateColor(baseColor, endValue, p)
    } else {
        val effectiveKeyTimes = if (calcMode == CalcMode.paced) pacedKeyTimes ?: keyTimes else keyTimes
        when (calcMode) {
            CalcMode.discrete -> selectAnimationSegmentDiscrete(effectiveValues, effectiveKeyTimes, progress)
            else -> selectAnimationSegment(effectiveValues, effectiveKeyTimes, progress, ::interpolateColor, parsedKeySplines)
        }
    }
    handler.invoke(color)
}

/** Per-channel `base + by * p` for SMIL `by`-only color animation. */
private fun addColors(baseColor: Int, byColor: Int, progress: Float): Int {
    return argb(
        clamp255(baseColor.alpha + byColor.alpha * progress),
        clamp255(baseColor.red + byColor.red * progress),
        clamp255(baseColor.green + byColor.green * progress),
        clamp255(baseColor.blue + byColor.blue * progress)
    )
}

/**
 * Base color of a color-animated attribute. Must be read after the per-frame
 * base reset in `updateAnimations`, so `by`-only / `to`-only animations
 * resolve against the underlying value instead of compounding.
 */
private fun baseColorFor(state: RendererState, builder: Style.Builder, attributeName: SVGAttr): Int {
    return when (attributeName) {
        SVGAttr.fill -> state.fillConfig.color
        SVGAttr.stroke -> state.strokeConfig.color
        SVGAttr.stop_color -> (builder.stopColor as? ColorValue)?.value ?: 0xFF000000.toInt()
        SVGAttr.flood_color -> (builder.floodColor as? ColorValue)?.value ?: 0xFF000000.toInt()
        SVGAttr.color -> builder.color?.value ?: 0xFF000000.toInt()
        SVGAttr.solid_color -> (builder.solidColor as? ColorValue)?.value ?: 0xFF000000.toInt()
        SVGAttr.lighting_color -> (builder.lightingColor as? ColorValue)?.value ?: 0xFFFFFFFF.toInt()
        else -> 0xFF000000.toInt()
    }
}

internal fun AnimateTransformNode.applyValueAt(animationTimeMs: Long, out: FloatArray): Boolean {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return false

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return false

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)
    val effectiveKeyTimes = if (calcMode == CalcMode.paced) pacedKeyTimes ?: keyTimes else keyTimes

    when (calcMode) {
        CalcMode.discrete -> selectAnimationSegmentDiscrete(effectiveValues, stride, effectiveKeyTimes, progress, out)
        else -> selectAnimationSegment(effectiveValues, stride, effectiveKeyTimes, progress, parsedKeySplines, out)
    }

    if (accumulateSum) {
        val repeatCount = (elapsed / durMs).toInt()
        if (repeatCount > 0) {
            val firstIdx = 0
            val lastIdx = effectiveValues.size - stride
            for (i in 0 until stride) {
                if (transformType == TransformType.rotate && i > 0) continue // cx, cy not accumulated
                out[i] += (effectiveValues[lastIdx + i] - effectiveValues[firstIdx + i]) * repeatCount
            }
        }
    }

    return true
}

context(context: AnimationContext)
internal fun AnimateTransformNode.toMatrix(animationTimeMs: Long, out: Matrix): Matrix? {
    if (attributeName != SVGAttr.transform) return null

    return context.floatArray3Pool.withPooledObject { valAt ->
        if (!applyValueAt(animationTimeMs, valAt)) {
            null
        } else {
            when (transformType) {
                TransformType.translate -> {
                    val dx = valAt[0]
                    val dy = valAt[1]
                    if (dx != 0f || dy != 0f) {
                        out.setTranslate(dx, dy)
                    }
                }

                TransformType.scale -> {
                    val sx = valAt[0]
                    val sy = valAt[1]
                    if (sx != 1f || sy != 1f) {
                        out.setScale(sx, sy)
                    }
                }

                TransformType.rotate -> {
                    val degrees = valAt[0]
                    if (degrees != 0f) {
                        out.setRotate(degrees, valAt[1], valAt[2])
                    }
                }

                TransformType.skewX -> {
                    val degrees = valAt[0]
                    if (degrees != 0f) {
                        out.setSkew(tan(degrees.toRadians()), 0f)
                    }
                }

                TransformType.skewY -> {
                    val degrees = valAt[0]
                    if (degrees != 0f) {
                        out.setSkew(0f, tan(degrees.toRadians()))
                    }
                }
            }
            out
        }
    }
}

internal fun AnimateDashArrayNode.withDashArrayAt(animationTimeMs: Long, out: FloatArray): Boolean {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return false

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return false

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)
    val effectiveKeyTimes = if (calcMode == CalcMode.paced) pacedKeyTimes ?: keyTimes else keyTimes

    when (calcMode) {
        CalcMode.discrete -> selectAnimationSegmentDiscrete(effectiveValues, stride, effectiveKeyTimes, progress, out)
        else -> selectAnimationSegment(effectiveValues, stride, effectiveKeyTimes, progress, parsedKeySplines, out)
    }

    if (accumulateSum) {
        val repeatCount = (elapsed / durMs).toInt()
        if (repeatCount > 0) {
            val firstIdx = 0
            val lastIdx = effectiveValues.size - stride
            for (i in 0 until stride) {
                out[i] += (effectiveValues[lastIdx + i] - effectiveValues[firstIdx + i]) * repeatCount
            }
        }
    }

    return true
}

internal fun AnimateFloatNode.withPointsAt(animationTimeMs: Long, stride: Int, out: FloatArray): Boolean {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return false

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return false

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)
    val effectiveKeyTimes = if (calcMode == CalcMode.paced) pacedKeyTimes ?: keyTimes else keyTimes

    when (calcMode) {
        CalcMode.discrete -> selectAnimationSegmentDiscrete(effectiveValues, stride, effectiveKeyTimes, progress, out)
        else -> selectAnimationSegment(effectiveValues, stride, effectiveKeyTimes, progress, parsedKeySplines, out)
    }

    if (accumulateSum) {
        val repeatCount = (elapsed / durMs).toInt()
        if (repeatCount > 0) {
            val lastIdx = effectiveValues.size - stride
            for (i in 0 until stride) {
                out[i] += (effectiveValues[lastIdx + i] - effectiveValues[i]) * repeatCount
            }
        }
    }

    return true
}

internal fun AnimatePathNode.withPathAt(animationTimeMs: Long, outPath: Path): Boolean {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return false

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return false

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)
    val values = effectiveValues
    val count = values.size
    if (count == 0) return false

    outPath.reset()
    pathAppender.target = outPath

    if (count == 1) {
        values[0].enumeratePath(pathAppender)
        return true
    }

    if (calcMode == CalcMode.discrete) {
        val segmentCount = count - 1
        var idx = 1
        val keyTimes = this.keyTimes
        if (keyTimes != null && keyTimes.size == count) {
            for (i in 0 until segmentCount) {
                val end = keyTimes[i + 1]
                if (progress < end || i == segmentCount - 1) {
                    idx = i + 1
                    break
                }
            }
        } else {
            val scaled = progress * segmentCount
            val index = clamp(scaled.toInt(), 0, segmentCount - 1)
            idx = index + 1
        }
        values[idx].enumeratePath(pathAppender)
        return true
    }

    val segmentCount = count - 1
    var fromIdx = 0
    var toIdx = 1
    var eased = progress
    val keyTimes = this.keyTimes
    if (keyTimes != null && keyTimes.size == count) {
        for (i in 0 until segmentCount) {
            val start = keyTimes[i]
            val end = keyTimes[i + 1]
            if (progress <= end || i == segmentCount - 1) {
                val local = if (end == start) {
                    1f
                } else {
                    clamp((progress - start) / (end - start), 0f, 1f)
                }
                eased = if (parsedKeySplines != null && i < parsedKeySplines.size) {
                    applySplineInterpolation(local, parsedKeySplines[i])
                } else {
                    local
                }
                fromIdx = i
                toIdx = i + 1
                break
            }
        }
    } else {
        val scaled = progress * segmentCount
        val index = clamp(scaled.toInt(), 0, segmentCount - 1)
        val local = scaled - index
        eased = if (parsedKeySplines != null && index < parsedKeySplines.size) {
            applySplineInterpolation(local, parsedKeySplines[index])
        } else {
            local
        }
        fromIdx = index
        toIdx = index + 1
    }

    values[fromIdx].enumerateInterpolated(values[toIdx], eased, pathAppender)
    return true
}

internal fun AnimateMotionNode.applyMotionAt(animationTimeMs: Long, out: Matrix): Boolean {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return false

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed) && !fillFreeze) return false

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed)

    val effectiveProgress = if (keyPoints != null && keyTimes != null) {
        selectAnimationSegment(keyPoints, keyTimes, progress, ::interpolate, parsedKeySplines)
    } else {
        progress
    }

    val path = this.path ?: return false
    val pathMeasure = reusablePathMeasure
    pathMeasure.setPath(path, false)
    val length = pathMeasure.length
    val distance = length * effectiveProgress

    val pos = pos
    val tan = tan
    if (pathMeasure.getPosTan(distance, pos, tan)) {
        out.setTranslate(pos[0], pos[1])

        val rotateVal = rotate
        if (rotateVal != null) {
            when (rotateVal) {
                "auto" -> {
                    val angle = atan2(tan[1].toDouble(), tan[0].toDouble()).toDegrees().toFloat()
                    out.preRotate(angle)
                }

                "auto-reverse" -> {
                    val angle = atan2(tan[1].toDouble(), tan[0].toDouble()).toDegrees().toFloat() + 180f
                    out.preRotate(angle)
                }

                else -> {
                    val angle = rotateVal.toFloatOrNull() ?: 0f
                    if (angle != 0f) {
                        out.preRotate(angle)
                    }
                }
            }
        }

        if (accumulateSum) {
            val repeatCount = (elapsed / durMs).toInt()
            if (repeatCount > 0) {
                // For motion, we accumulate the distance between the last and first points of the path
                if (pathMeasure.getPosTan(0f, startPos, null) && pathMeasure.getPosTan(length, endPos, null)) {
                    out.postTranslate((endPos[0] - startPos[0]) * repeatCount, (endPos[1] - startPos[1]) * repeatCount)
                }
            }
        }

        return true
    }
    return false
}
