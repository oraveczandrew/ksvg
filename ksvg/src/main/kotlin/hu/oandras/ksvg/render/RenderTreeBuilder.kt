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

package hu.oandras.ksvg.render

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Path
import android.graphics.PathMeasure
import androidx.collection.ArrayMap
import androidx.collection.ArraySet
import androidx.collection.MutableFloatList
import androidx.collection.MutableIntList
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.LoggerContext
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.animation.AnimateColor
import hu.oandras.ksvg.dom.animation.AnimateDashArray
import hu.oandras.ksvg.dom.animation.AnimateFloat
import hu.oandras.ksvg.dom.animation.AnimateMotion
import hu.oandras.ksvg.dom.animation.AnimatePath
import hu.oandras.ksvg.dom.animation.AnimateTransform
import hu.oandras.ksvg.dom.animation.Animation
import hu.oandras.ksvg.dom.animation.CalcMode
import hu.oandras.ksvg.dom.animation.MPath
import hu.oandras.ksvg.dom.animation.TransformType
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.ClipPath
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.Element
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.Group
import hu.oandras.ksvg.dom.core.HasTransform
import hu.oandras.ksvg.dom.core.Image
import hu.oandras.ksvg.dom.core.Marker
import hu.oandras.ksvg.dom.core.Mask
import hu.oandras.ksvg.dom.core.NotDirectlyRendered
import hu.oandras.ksvg.dom.core.Pattern
import hu.oandras.ksvg.dom.core.Svg
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.core.Switch
import hu.oandras.ksvg.dom.core.Symbol
import hu.oandras.ksvg.dom.core.Use
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.filter.FeBlend
import hu.oandras.ksvg.dom.filter.FeColorMatrix
import hu.oandras.ksvg.dom.filter.FeComponentTransfer
import hu.oandras.ksvg.dom.filter.FeComposite
import hu.oandras.ksvg.dom.filter.FeConvolveMatrix
import hu.oandras.ksvg.dom.filter.FeDiffuseLighting
import hu.oandras.ksvg.dom.filter.FeDisplacementMap
import hu.oandras.ksvg.dom.filter.FeDropShadow
import hu.oandras.ksvg.dom.filter.FeFlood
import hu.oandras.ksvg.dom.filter.FeFunc
import hu.oandras.ksvg.dom.filter.FeGaussianBlur
import hu.oandras.ksvg.dom.filter.FeImage
import hu.oandras.ksvg.dom.filter.FeMerge
import hu.oandras.ksvg.dom.filter.FeMergeNode
import hu.oandras.ksvg.dom.filter.FeMorphology
import hu.oandras.ksvg.dom.filter.FeMorphologyOperator
import hu.oandras.ksvg.dom.filter.FeOffset
import hu.oandras.ksvg.dom.filter.FeSpecularLighting
import hu.oandras.ksvg.dom.filter.FeTile
import hu.oandras.ksvg.dom.filter.FeTurbulence
import hu.oandras.ksvg.dom.filter.Filter
import hu.oandras.ksvg.dom.filter.FilterPrimitive
import hu.oandras.ksvg.dom.gradient.Gradient
import hu.oandras.ksvg.dom.gradient.Stop
import hu.oandras.ksvg.dom.shapes.CircleShape
import hu.oandras.ksvg.dom.shapes.EllipseShape
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PathShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.shapes.RectShape
import hu.oandras.ksvg.dom.shapes.Shape
import hu.oandras.ksvg.dom.style.FontStyle
import hu.oandras.ksvg.dom.style.PaintReference
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.SvgPaint
import hu.oandras.ksvg.dom.text.TRef
import hu.oandras.ksvg.dom.text.TSpan
import hu.oandras.ksvg.dom.text.Text
import hu.oandras.ksvg.dom.text.TextAnchor
import hu.oandras.ksvg.dom.text.TextContainer
import hu.oandras.ksvg.dom.text.TextPath
import hu.oandras.ksvg.dom.text.TextSequence
import hu.oandras.ksvg.logW
import hu.oandras.ksvg.render.animation.AnimateColorNode
import hu.oandras.ksvg.render.animation.AnimateDashArrayNode
import hu.oandras.ksvg.render.animation.AnimateFloatNode
import hu.oandras.ksvg.render.animation.AnimateMotionNode
import hu.oandras.ksvg.render.animation.AnimatePathNode
import hu.oandras.ksvg.render.animation.AnimateTransformNode
import hu.oandras.ksvg.render.animation.AnimationNode
import hu.oandras.ksvg.render.animation.computePacedKeyTimesColor
import hu.oandras.ksvg.render.animation.computePacedKeyTimesDashArray
import hu.oandras.ksvg.render.animation.computePacedKeyTimesFloat
import hu.oandras.ksvg.render.animation.normalizeDashArrays
import hu.oandras.ksvg.render.animation.parseKeySplines
import hu.oandras.ksvg.render.filters.createBlendPaint
import hu.oandras.ksvg.render.filters.createCompositePaint
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.text.TextBoundsCalculator
import hu.oandras.ksvg.render.text.calculateTextBounds
import hu.oandras.ksvg.render.text.calculateTextWidth
import hu.oandras.ksvg.render.text.extractRawText
import hu.oandras.ksvg.render.text.getAnchorPosition
import hu.oandras.ksvg.render.text.selectTypefaceAndFontStyling
import hu.oandras.ksvg.utils.LcgRandom
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.checkForImageDataURL
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.firstInstanceOrNull
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.mapNotNullElements
import hu.oandras.ksvg.utils.mapToFloatArray
import hu.oandras.ksvg.utils.optimizeReadOnlyList
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.takeIfNonZeroOrElse
import hu.oandras.ksvg.utils.textXMLSpaceTransform
import java.util.*
import kotlin.math.max

internal class RenderTreeBuilder(
    private val document: SVGImpl,
    override val dPI: Float,
    private val externalFileResolver: ExternalFileResolver?,
    pools: PoolOwner,
    logger: LoggerContext,
) : DisplayContext, PoolOwner by pools, LoggerContext by logger {

    private var state: RendererState = RendererState()
    private val stateStack: Stack<RendererState> = Stack()
    private val parentStack: Stack<Container> = Stack()

    private val maskNodeCache = ArrayMap<Mask, MaskRenderNode>()
    private val markerNodeCache = ArrayMap<Marker, MarkerRenderNode>()
    private val patternNodeCache = ArrayMap<Pattern, PatternRenderNode>()
    private val filterNodeCache = ArrayMap<Filter, FilterRenderNode>()
    private val clipPathNodeCache = ArrayMap<ClipPath, ClipPathRenderNode>()

    // Tracks element IDs currently being resolved through a reference
    // (<use>/clip-path) so that a cyclic reference (A->B->A) is treated as an
    // empty/missing reference instead of causing unbounded recursion.
    private val buildingIds: ArraySet<String> = ArraySet()

    private var ruleMatchContext: CSSParser.RuleMatchContext? = null

    override val currentFontSize: Float
        get() = state.fillConfig.textSize

    override val currentFontXHeight: Float
        get() = currentFontSize / 2f

    override val effectiveViewPortInUserUnits: Box
        get() {
            val s = state
            return s.viewBox ?: checkNotNull(s.viewPort) { "Viewport is null" }
        }

    fun build(viewPort: Box): RenderNode<*>? {
        val rootObj = document.rootElement ?: return null
        buildingIds.clear()

        state = RendererState()
        styleBuilderPool.withPooledObject { builder ->
            builder.reset(Style.getDefaultStyle())
            updateStyle(state, builder, Style.getDefaultStyle())
            state.style = builder.build()
        }
        state.viewPort = viewPort

        return build(rootObj)
    }

    fun build(renderOptions: RenderOptions): RenderNode<*>? {
        val rootObj = document.rootElement ?: return null
        buildingIds.clear()

        val css = renderOptions.css
        if (css != null) {
            document.addCSSRules(css.cssRuleSet)
        }

        if (renderOptions.hasTarget()) {
            ruleMatchContext = CSSParser.RuleMatchContext(
                targetElement = document.getElementById(renderOptions.targetId)
            )
        }

        state = RendererState()
        styleBuilderPool.withPooledObject { builder ->
            builder.reset(Style.getDefaultStyle())
            updateStyle(state, builder, Style.getDefaultStyle())
            state.style = builder.build()
        }

        val node = try {
            val overrides = resolveRootViewOverrides(document, renderOptions as RenderOptionsImpl) ?: return null
            val viewBox: Box? = overrides.viewBoxOverride
            val preserveAspectRatio: PreserveAspectRatio? = overrides.parOverride

            var viewPort = renderOptions.viewPort!!
            // The established (external) viewport is decisive. Root width/height only refine it
            // when expressed relative to that viewport (percentages); absolute lengths belong to
            // the document's own coordinate space and must not shrink the container - matching the
            // standard embedding model (and rsvg/browser behaviour) where the outer size wins.
            rootObj.width?.let {
                if (it.unit == CssUnit.percent) {
                    viewPort = viewPort.copy(width = it.floatValueInContext(viewPort.width))
                }
            }
            rootObj.height?.let {
                if (it.unit == CssUnit.percent) {
                    viewPort = viewPort.copy(height = it.floatValueInContext(viewPort.height))
                }
            }
            state.viewPort = viewPort

            statePush()
            checkXMLSpaceAttribute(rootObj)
            val n = buildSvg(
                obj = rootObj,
                viewBoxOverride = viewBox,
                preserveAspectRatioOverride = preserveAspectRatio,
                effectiveViewport = viewPort
            )
            if (n != null) {
                n.hasAnimationsInSubtree = n.computeHasAnimations()
                n.subtreeContainsBlendMode = n.computeSubtreeContainsBlendMode()
            }
            statePop()
            n
        } finally {
            if (renderOptions.hasCss()) {
                document.clearRenderCSSRules()
            }
        }

        return node
    }

    private fun build(obj: SvgObject): RenderNode<*>? {
        if (obj is NotDirectlyRendered) return null
        if (obj is Conditional && !displayConditional(obj)) return null

        // Break cyclic references (e.g. <use>/<g> A->B->A). A referenced element is
        // re-entered while still being built only via such a cycle, so treating its
        // re-entry as empty/missing matches the spec and avoids unbounded recursion.
        val id = (obj as? ElementBase)?.id
        if (id != null && !buildingIds.add(id)) {
            logW("KSVG") { "Cyclic reference detected for id '$id'; treating as empty" }
            return null
        }
        try {
        // A DOM element may be referenced by several <use> instances; its cached
        // bounding box must be recomputed fresh for each build instead of
        // accumulating stale values across instances (SVG-SUPPORT.md, <use>).
        (obj as? Element)?.boundingBox = null
        statePush()
        checkXMLSpaceAttribute(obj)

        val node = when (obj) {
            is Svg -> buildSvg(obj)
            is Use -> buildUse(obj)
            is Switch -> buildSwitch(obj)
            is Group -> buildGroup(obj)
            is Image -> buildImage(obj)
            is PathShape -> buildPath(obj)
            is Shape -> buildGraphicsPathNode(obj)
            is Text -> buildText(obj)
            else -> null
        }

        // Per SVG 1.1, a clip-path or mask property that references a missing or
        // non-matching element is an error: the element must not be rendered.
        var hideInvalidReference = false
        if (node != null && obj is ElementBase) {
            val state = state
            state.style.filter?.let {
                val filter = document.resolveIRI(it) as? Filter
                if (filter != null) {
                    node.filterNode = buildFilter(filter)
                }
            }
            state.style.clipPath?.let {
                val clipPath = document.resolveIRI(it) as? ClipPath
                if (clipPath != null) {
                    node.clipPathNode = buildClipPath(clipPath)
                } else {
                    logW("KSVG") { "Clip-path reference '$it' is missing or invalid; hiding element" }
                    hideInvalidReference = true
                }
            }
            state.style.mask?.let {
                val mask = document.resolveIRI(it) as? Mask
                if (mask != null) {
                    node.maskNode = buildMask(mask)
                } else {
                    logW("KSVG") { "Mask reference '$it' is missing or invalid; hiding element" }
                    hideInvalidReference = true
                }
            }

            if (obj is Shape) {
                state.style.markerStart?.let { (document.resolveIRI(it) as? Marker)?.let { m -> node.markerStartNode = buildMarker(m) } }
                state.style.markerMid?.let { (document.resolveIRI(it) as? Marker)?.let { m -> node.markerMidNode = buildMarker(m) } }
                state.style.markerEnd?.let { (document.resolveIRI(it) as? Marker)?.let { m -> node.markerEndNode = buildMarker(m) } }
            }

            resolvePatternReference(state.style.fill as? PaintReference)?.let { p ->
                node.fillPatternNode = p
            }
            resolvePatternReference(state.style.stroke as? PaintReference)?.let { p ->
                node.strokePatternNode = p
            }
            node.fillPaintRef = resolvePaint(state.style.fill)
            node.strokePaintRef = resolvePaint(state.style.stroke)

            obj.animations?.let { animations ->
                node.animationNodes = animations.mapNotNullElements {
                    buildAnimationNode(it)
                }
            }
            node.hasAnimationsInSubtree = node.computeHasAnimations()
        }

        statePop()
        return if (hideInvalidReference) null else node
        } finally {
            if (id != null) buildingIds.remove(id)
        }
    }

    private fun resolvePatternReference(obj: PaintReference?): PatternRenderNode? {
        val ref = obj ?: return null
        val p = document.resolveIRI(ref.href) as? Pattern ?: return null
        return buildPattern(p)
    }

    private fun resolveNodePaints(node: RenderNode<*>) {
        node.fillPaintRef = resolvePaint(state.style.fill)
        node.strokePaintRef = resolvePaint(state.style.stroke)
    }

    private fun resolvePaint(paint: SvgPaint?): ResolvedPaint? {
        val resolved = resolvePaintReference(document, paint) ?: return null
        if (resolved is ResolvedPaint.Linear || resolved is ResolvedPaint.Radial) {
            populateGradientAnimations(resolved)
        }
        return resolved
    }

    private fun populateGradientAnimations(resolved: ResolvedPaint) {
        when (resolved) {
            is ResolvedPaint.Linear -> {
                resolved.ancestorAnimationNodes = buildAncestorAnimationNodes(resolved.gradient)
                resolved.stopNodes = buildStopNodes(resolved.gradient)
            }
            is ResolvedPaint.Radial -> {
                resolved.ancestorAnimationNodes = buildAncestorAnimationNodes(resolved.gradient)
                resolved.stopNodes = buildStopNodes(resolved.gradient)
            }
            else -> {}
        }
    }

    private fun buildAncestorAnimationNodes(obj: SvgObject): List<List<AnimationNode>> {
        val chain = ArrayList<ElementBase>()
        var current: SvgObject? = obj
        while (current != null) {
            if (current is ElementBase) {
                chain.add(0, current)
            }
            current = current.parent
        }
        val result = ArrayList<List<AnimationNode>>(chain.size)
        chain.forEachElement { ancestor ->
            result.add(ancestor.animations?.mapNotNullElements { buildAnimationNode(it) }.orEmpty())
        }
        return result.optimizeReadOnlyList()
    }

    private fun buildStopNodes(gradient: Gradient): List<StopRenderNode> {
        val children = gradient.getChildren()
        val result = ArrayList<StopRenderNode>(children.size)
        children.forEachElement { child ->
            if (child is Stop) {
                result.add(StopRenderNode(child).also { node ->
                    node.animationNodes = child.animations?.mapNotNullElements { buildAnimationNode(it) }
                })
            }
        }
        return result.optimizeReadOnlyList()
    }

    private fun buildAnimationNode(animation: Animation): AnimationNode? {
        if (!animation.isValid()) return null

        return when (animation) {
            is AnimateMotion -> {
                var pathDef = animation.path
                if (pathDef == null) {
                    val mpath = animation.getChildren().firstInstanceOrNull<MPath>()
                    val href = mpath?.href
                    if (href != null) {
                        val refId = if (href.startsWith('#')) {
                            href.substring(1)
                        } else {
                            href
                        }

                        val refElement = animation.document.getElementById(refId)
                        if (refElement is PathShape) {
                            pathDef = refElement.d
                        }
                    }
                }

                val path = if (pathDef != null) {
                    PathConverter(pathDef).path
                } else {
                    null
                }

                AnimateMotionNode(
                    sourceElement = animation,
                    path = path,
                    rotate = animation.rotate,
                    keyPoints = animation.keyPoints,
                    parsedKeySplines = if (animation.calcMode == CalcMode.spline) {
                        parseKeySplines(animation.keySplines)
                    } else {
                        null
                    },
                    pacedKeyTimes = null
                )
            }

            is AnimateTransform -> {
                val stride = when (animation.transformType) {
                    TransformType.translate -> 2
                    TransformType.scale -> 2
                    TransformType.rotate -> 3
                    TransformType.skewX, TransformType.skewY -> 1
                }
                val effectiveValues = animation.values ?: run {
                    val fromVal = animation.from
                    val toVal = animation.to
                    val byVal = animation.by
                    when {
                        fromVal != null && toVal != null -> {
                            val list = MutableFloatList(stride * 2)
                            for (i in 0 until stride) list.add(fromVal[i])
                            for (i in 0 until stride) list.add(toVal[i])
                            list
                        }

                        fromVal != null && byVal != null -> {
                            val list = MutableFloatList(stride * 2)
                            for (i in 0 until stride) list.add(fromVal[i])
                            for (i in 0 until stride) {
                                val acc = if (animation.transformType == TransformType.rotate && i > 0) {
                                    fromVal[i] // cx, cy not accumulated
                                } else {
                                    fromVal[i] + byVal[i]
                                }
                                list.add(acc)
                            }
                            list
                        }

                        toVal != null -> {
                            val list = MutableFloatList(stride * 2)
                            for (i in 0 until stride) list.add(toVal[i])
                            for (i in 0 until stride) list.add(toVal[i])
                            list
                        }

                        else -> null
                    }
                } ?: return null

                AnimateTransformNode(
                    sourceElement = animation,
                    transformType = animation.transformType,
                    stride = stride,
                    effectiveValues = effectiveValues,
                    parsedKeySplines = if (animation.calcMode == CalcMode.spline) parseKeySplines(animation.keySplines) else null,
                    pacedKeyTimes = if (animation.calcMode == CalcMode.paced && animation.keyTimes == null) computePacedKeyTimesDashArray(
                        effectiveValues,
                        stride
                    ) else null
                )
            }

            is AnimateFloat -> {
                val effectiveValues = animation.values ?: run {
                    val fromVal = animation.from
                    val toVal = animation.to
                    val byVal = animation.by
                    when {
                        fromVal != null && toVal != null -> {
                            val list = MutableFloatList(2)
                            list.add(fromVal)
                            list.add(toVal)
                            list
                        }

                        fromVal != null && byVal != null -> {
                            val list = MutableFloatList(2)
                            list.add(fromVal)
                            list.add(fromVal + byVal)
                            list
                        }

                        toVal != null -> {
                            val list = MutableFloatList(2)
                            list.add(toVal)
                            list.add(toVal)
                            list
                        }

                        else -> null
                    }
                } ?: return null

                AnimateFloatNode(
                    sourceElement = animation,
                    effectiveValues = effectiveValues,
                    parsedKeySplines = if (animation.calcMode == CalcMode.spline) parseKeySplines(animation.keySplines) else null,
                    pacedKeyTimes = if (animation.calcMode == CalcMode.paced && animation.keyTimes == null) computePacedKeyTimesFloat(
                        effectiveValues
                    ) else null
                )
            }

            is AnimatePath -> {
                val effectiveValues = animation.values ?: run {
                    val fromVal = animation.from
                    val toVal = animation.to
                    when {
                        fromVal != null && toVal != null -> listOf(fromVal, toVal)
                        toVal != null -> listOf(toVal, toVal)
                        else -> null
                    }
                } ?: return null

                AnimatePathNode(
                    sourceElement = animation,
                    effectiveValues = effectiveValues,
                    parsedKeySplines = if (animation.calcMode == CalcMode.spline) parseKeySplines(animation.keySplines) else null,
                )
            }

            is AnimateColor -> {
                val effectiveValues = animation.values ?: run {
                    val fromVal = animation.from
                    val toVal = animation.to
                    val byVal = animation.by
                    when {
                        fromVal != null && toVal != null -> {
                            val list = MutableIntList(2)
                            list.add(fromVal)
                            list.add(toVal)
                            list
                        }

                        fromVal != null && byVal != null -> {
                            val list = MutableIntList(2)
                            list.add(fromVal)
                            list.add(
                                argb(
                                    clamp255(fromVal.alpha + byVal.alpha),
                                    clamp255(fromVal.red + byVal.red),
                                    clamp255(fromVal.green + byVal.green),
                                    clamp255(fromVal.blue + byVal.blue)
                                )
                            )
                            list
                        }

                        toVal != null -> {
                            val list = MutableIntList(2)
                            list.add(toVal)
                            list.add(toVal)
                            list
                        }

                        else -> null
                    }
                } ?: return null

                AnimateColorNode(
                    sourceElement = animation,
                    effectiveValues = effectiveValues,
                    parsedKeySplines = if (animation.calcMode == CalcMode.spline) parseKeySplines(animation.keySplines) else null,
                    pacedKeyTimes = if (animation.calcMode == CalcMode.paced && animation.keyTimes == null) computePacedKeyTimesColor(
                        effectiveValues
                    ) else null
                )
            }

            is AnimateDashArray -> {
                var animationStride = 0
                val effectiveValues = animation.values ?: run {
                    val fromVal = animation.from
                    val toVal = animation.to
                    val byVal = animation.by
                    when {
                        fromVal != null && toVal != null -> {
                            val keyframes = listOf(fromVal, toVal)
                            val (s, normalized) = normalizeDashArrays(keyframes)
                            animationStride = s
                            normalized
                        }

                        fromVal != null && byVal != null -> {
                            val result = FloatArray(fromVal.size)
                            for (i in fromVal.indices) {
                                result[i] = fromVal[i] + byVal[i]
                            }
                            val keyframes = listOf(fromVal, result)
                            val (s, normalized) = normalizeDashArrays(keyframes)
                            animationStride = s
                            normalized
                        }

                        toVal != null -> {
                            val keyframes = listOf(toVal, toVal)
                            val (s, normalized) = normalizeDashArrays(keyframes)
                            animationStride = s
                            normalized
                        }

                        else -> null
                    }
                } ?: return null

                val effectiveStride = if (animation.values != null) animation.stride else animationStride
                AnimateDashArrayNode(
                    sourceElement = animation,
                    effectiveValues = effectiveValues,
                    stride = effectiveStride,
                    parsedKeySplines = if (animation.calcMode == CalcMode.spline) parseKeySplines(animation.keySplines) else null,
                    pacedKeyTimes = if (animation.calcMode == CalcMode.paced && animation.keyTimes == null) computePacedKeyTimesDashArray(
                        effectiveValues,
                        effectiveStride
                    ) else null
                )
            }
        }
    }

    private fun buildSvg(
        obj: Svg,
        viewBoxOverride: Box? = null,
        preserveAspectRatioOverride: PreserveAspectRatio? = null,
        effectiveViewport: Box? = null
    ): GroupRenderNode<Svg>? {
        // For the root <svg> the established (external) viewport is decisive; nested <svg>
        // elements still establish their own viewport from their x/y/width/height.
        val viewPort = effectiveViewport ?: makeViewPort(obj.x, obj.y, obj.width, obj.height)
        updateStyleForElement(state, obj)

        if (!display()) return null

        val oldViewPort = state.viewPort
        val oldViewBox = state.viewBox

        state.viewPort = viewPort
        
        val transform = Matrix()
        val viewBox = viewBoxOverride ?: obj.viewBox
        val positioning = preserveAspectRatioOverride ?: obj.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX
        
        if (viewBox != null) {
            calculateViewBoxTransform(viewPort, viewBox, positioning, transform)
            state.viewBox = viewBox
        } else {
            transform.preTranslate(viewPort.minX, viewPort.minY)
            state.viewBox = null
        }

        val children = buildChildren(obj)
        val node = GroupRenderNode(obj, children)
        if (effectiveViewport == null) {
            // Nested <svg>: remember the length sources so RenderScene can
            // resolve this viewport when the drawable bounds change.
            node.viewportSpec = ViewportSpec(obj.x, obj.y, obj.width, obj.height)
        }
        // node.viewPort / node.viewBoxTransform are owned by RenderScene.applyViewport.
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = obj.boundingBox
        updateParentBoundingBox(obj)

        state.viewPort = oldViewPort
        state.viewBox = oldViewBox

        return node
    }

    private fun buildSymbol(
        obj: Symbol,
        useWidth: CSSLength? = null,
        useHeight: CSSLength? = null
    ): GroupRenderNode<Symbol>? {
        // Symbol behaves like a nested <svg> element.
        // It defines a new viewport.
        val viewPort = makeViewPort(null, null, useWidth, useHeight)

        updateStyleForElement(state, obj)
        if (!display()) return null

        val oldViewPort = state.viewPort
        val oldViewBox = state.viewBox

        state.viewPort = viewPort

        val transform = Matrix()
        val viewBox = obj.viewBox
        val positioning = obj.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX

        if (viewBox != null) {
            calculateViewBoxTransform(viewPort, viewBox, positioning, transform)
            state.viewBox = viewBox
        } else {
            state.viewBox = null
        }

        val children = buildChildren(obj)
        val node = GroupRenderNode(obj, children)
        node.viewportSpec = ViewportSpec(null, null, useWidth, useHeight)
        // node.viewPort / node.viewBoxTransform are owned by RenderScene.applyViewport.
        node.renderState.apply(state)
        updateParentBoundingBox(obj)
        node.boundingBox = obj.boundingBox

        state.viewPort = oldViewPort
        state.viewBox = oldViewBox

        return node
    }

    private fun buildGroup(obj: Group): GroupRenderNode<Group>? {
        updateStyleForElement(state, obj)
        if (!display()) return null

        val children = buildChildren(obj)
        val node = GroupRenderNode(obj, children)
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = obj.boundingBox
        updateParentBoundingBox(obj)
        return node
    }

    private fun buildSwitch(obj: Switch): SwitchRenderNode? {
        updateStyleForElement(state, obj)
        if (!display()) return null

        var selectedChild: RenderNode<*>? = null

        val children = obj.getChildren()
        for (i in children.indices) {
            val child = children[i]
            val condObj = child as? Conditional ?: continue

            if (!displayConditional(condObj)) {
                continue
            }

            // All checks passed! Build this one element and exit
            selectedChild = build(child)
            break
        }

        val node = SwitchRenderNode(obj, selectedChild)
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = obj.boundingBox
        updateParentBoundingBox(obj)
        return node
    }

    private fun isRequiredFormatsSupported(
        reqFormats: Collection<String>,
        externalFileResolver: ExternalFileResolver?
    ): Boolean {
        if (reqFormats.isEmpty() || externalFileResolver == null) {
            return true
        }
        // Build-time only; DOM stores these as Set<String>.
        for (format in reqFormats) {
            if (externalFileResolver.isFormatSupported(format)) {
                return true
            }
        }
        return false
    }

    private fun isRequiredFontsSupported(reqFonts: Collection<String>): Boolean {
        if (reqFonts.isEmpty()) {
            return true
        }
        if (externalFileResolver == null) {
            return false
        }
        for (fontName in reqFonts) {
            val style = state.style
            if (externalFileResolver.resolveFont(
                    fontFamily = fontName,
                    fontWeight = if (style.fontWeight.isNaN()) 400f else style.fontWeight,
                    fontStyle = (style.fontStyle ?: FontStyle.normal).toString(),
                    fontStretch = style.fontWidth
                ) == null
            ) {
                return false
            }
        }
        return true
    }

    private fun displayConditional(condObj: Conditional): Boolean {
        // We don't support extensions
        if (condObj.requiredExtensions != null) {
            return false
        }

        // Check language
        val deviceLanguage = Locale.getDefault().language
        val sysLang = condObj.systemLanguage
        if (sysLang != null && (sysLang.isEmpty() || !sysLang.contains(deviceLanguage))) {
            return false
        }

        // Check features
        val reqFeat = condObj.requiredFeatures
        if (reqFeat != null) {
            if (!isSupportedFeatures(reqFeat)) {
                return false
            }
        }

        // Check formats (MIME types)
        val reqFormats = condObj.requiredFormats
        if (reqFormats != null) {
            if (!isRequiredFormatsSupported(reqFormats, externalFileResolver)) {
                return false
            }
        }

        // Check fonts
        val reqFonts = condObj.requiredFonts
        if (reqFonts != null) {
            if (!isRequiredFontsSupported(reqFonts)) {
                return false
            }
        }

        return true
    }

    private fun buildUse(obj: Use): GroupRenderNode<Use>? {
        updateStyleForElement(state, obj)
        if (!display()) return null

        val ref = document.resolveIRI(obj.href) as? Element ?: return null

        val transform = obj.getTransform()?.copy() ?: Matrix()
        val x = obj.x?.floatValueXInContext() ?: 0f
        val y = obj.y?.floatValueYInContext() ?: 0f
        transform.preTranslate(x, y)

        parentPush(obj)
        val refNode = when (ref) {
            is Symbol -> buildSymbol(ref, obj.width, obj.height)
            is Svg -> buildSvg(ref, effectiveViewport = makeViewPort(null, null, obj.width, obj.height))
            else -> build(ref)
        }
        refNode?.hasAnimationsInSubtree = refNode.computeHasAnimations()
        ref.boundingBox?.let { updateParentBoundingBox(ref) }
        parentPop()

        if (refNode == null) return null

        val node = GroupRenderNode(obj, listOf(refNode))
        node.transform = transform
        node.animationBaseTransform = transform.copy()
        node.renderState.apply(state)
        // The referenced element establishes its own viewport (<symbol>/<svg>);
        // its viewBox transform is re-resolved by RenderScene.applyViewport after
        // this build, so don't cache a display list of its (initially unscaled)
        // pixels here.
        if (refNode is GroupRenderNode<*> && refNode.viewportSpec != null) {
            node.disableDisplayListCache = true
        }
        // Pass the full <use> transform (attribute + x/y) so the parent's
        // bounding box is computed in world space. The node's own boundingBox
        // stays in local space, matching how withNodeDisplayList records its
        // content (a fresh recording canvas ignores the outer transform).
        updateParentBoundingBox(obj, transform)
        node.boundingBox = obj.boundingBox
        return node
    }

    private fun buildChildren(obj: Container): List<RenderNode<*>> {
        parentPush(obj)
        val children = obj.getChildren().mapNotNullElements(::build)
        parentPop()
        return children
    }

    private fun buildPath(obj: PathShape): PathRenderNode? {
        updateStyleForElement(state, obj)
        if (!display() || !visible()) return null

        val pathDefinition = obj.d ?: return null
        val path = PathConverter(pathDefinition).path
        
        if (obj.boundingBox == null) {
            obj.boundingBox = calculatePathBounds(path, null)
        }
        updateParentBoundingBox(obj)

        val node = PathRenderNode(obj, path, MarkerPositionCalculator(obj.d).markers)
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = obj.boundingBox
        return node
    }

    private fun buildGraphicsPathNode(obj: Shape): PathRenderNode? {
        updateStyleForElement(state, obj)
        if (!display() || !visible()) return null

        val path = Path()
        updatePathAndBoundingBoxForGraphicsElement(obj, path)
        updateParentBoundingBox(obj)

        val node = PathRenderNode(obj, path)
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = obj.boundingBox
        return node
    }

    private fun updatePathAndBoundingBoxForGraphicsElement(
        obj: Shape,
        outPath: Path,
    ): Boolean {
        return when (obj) {
            is RectShape -> updatePathAndBoundingBox(obj, outPath, null)
            is CircleShape -> updatePathAndBoundingBox(obj, outPath, null)
            is EllipseShape -> updatePathAndBoundingBox(obj, outPath, null)
            is LineShape -> updatePathAndBoundingBox(obj, outPath, null)
            is PolyLineShape -> updatePathAndBoundingBox(obj, outPath, null)
            is PathShape -> updatePathAndBoundingBox(obj, outPath, null)
        }
    }

    private fun buildImage(obj: Image): ImageRenderNode? {
        updateStyleForElement(state, obj)
        if (!display() || !visible()) return null

        val x = obj.x?.floatValueXInContext() ?: 0f
        val y = obj.y?.floatValueYInContext() ?: 0f
        val w = obj.width?.floatValueXInContext() ?: 0f
        val h = obj.height?.floatValueYInContext() ?: 0f

        val imageBox = Box(x, y, w, h)
        obj.boundingBox = imageBox
        updateParentBoundingBox(obj)

        val href = obj.href
        var image: Bitmap? = null
        var imageNaturalSize: Box? = null

        if (href != null) {
            image = checkForImageDataURL(href)
            if (image == null && externalFileResolver != null) {
                image = externalFileResolver.resolveImage(href)
            }

            if (image != null) {
                imageNaturalSize = Box(
                    minX = 0f,
                    minY = 0f,
                    width = image.width.toFloat(),
                    height = image.height.toFloat()
                )
            }
        }

        val node = ImageRenderNode(obj, imageBox, image, imageNaturalSize)
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = imageBox
        return node
    }

    private fun buildText(obj: Text): TextRenderNode? {
        updateStyleForElement(state, obj)
        if (!display()) return null

        state.selectTypefaceAndFontStyling(externalFileResolver)

        // Get the first coordinate pair from the lists in the x and y properties.
        var x = obj.x?.firstOrNull()?.floatValueXInContext() ?: 0f
        val y = obj.y?.firstOrNull()?.floatValueYInContext() ?: 0f
        val dx = obj.dx?.firstOrNull()?.floatValueXInContext() ?: 0f
        val dy = obj.dy?.firstOrNull()?.floatValueYInContext() ?: 0f

        val children = buildTextChildren(obj)

        // Handle text alignment
        val anchor = state.getAnchorPosition()
        if (anchor != TextAnchor.Start) {
            val textWidth = calculateTextWidth(children, state)
            x -= if (anchor == TextAnchor.Middle) {
                textWidth / 2
            } else {
                textWidth // 'End' (right justify)
            }
        }

        if (obj.boundingBox == null) {
            val proc = TextBoundsCalculator().apply {
                this.x = x
                this.y = y
            }
            // Measurement only: TextBoundsCalculator never draws, so a throwaway canvas is fine (build time, not hot path).
            calculateTextBounds(canvas = Canvas(), children = children, proc = proc, parentState = state)
            obj.boundingBox = Box(proc.boundingBox)
        }

        val node = TextRenderNode(obj, x, y, dx, dy, children)
        node.transform = obj.getTransform()?.copy()
        node.renderState.apply(state)
        node.boundingBox = obj.boundingBox

        updateParentBoundingBox(obj)
        return node
    }

    private fun buildTextChildren(parent: TextContainer): List<TextNode> {
        val parentChildren = parent.getChildren()
        val children = ArrayList<TextNode>(parentChildren.size)
        val lastIndex = parentChildren.lastIndex
        for (i in 0..lastIndex) {
            when (val child = parentChildren[i]) {
                is TextSequence -> {
                    val transformedText = textXMLSpaceTransform(
                        text = child.text,
                        isFirstChild = i == 0,
                        isLastChild = i == lastIndex,
                        spacePreserve = state.spacePreserve
                    )
                    children.add(TextSequenceNode(transformedText))
                }

                is TSpan -> buildTSpan(child)?.let { children.add(it) }
                is TextPath -> buildTextPath(child)?.let { children.add(it) }
                is TRef -> buildTRef(child)?.let { children.add(it) }
            }
        }
        return children.optimizeReadOnlyList()
    }

    private fun buildTSpan(obj: TSpan): TSpanRenderNode? {
        statePush()
        updateStyleForElement(state, obj)
        if (!display()) {
            statePop()
            return null
        }
        state.selectTypefaceAndFontStyling(externalFileResolver)

        val x = obj.x?.mapToFloatArray { it.floatValueXInContext() }
        val y = obj.y?.mapToFloatArray { it.floatValueYInContext() }
        val dx = obj.dx?.mapToFloatArray { it.floatValueXInContext() }
        val dy = obj.dy?.mapToFloatArray { it.floatValueYInContext() }

        val children = buildTextChildren(obj)

        // If x was specified on tspan, then we need to recalculate the alignment
        if (x != null && x.isNotEmpty()) {
            val anchor = state.getAnchorPosition()
            if (anchor != TextAnchor.Start) {
                val textWidth = calculateTextWidth(children, state)
                val offset = if (anchor == TextAnchor.Middle) {
                    textWidth / 2
                } else {
                    textWidth // 'End' (right justify)
                }
                x[0] -= offset
            }
        }

        val node = TSpanRenderNode(obj, x, y, dx, dy, children)
        node.renderState.apply(state)
        resolveNodePaints(node)

        statePop()
        return node
    }

    private fun buildTextPath(obj: TextPath): TextPathRenderNode? {
        statePush()
        updateStyleForElement(state, obj)
        if (!display()) {
            statePop()
            return null
        }
        state.selectTypefaceAndFontStyling(externalFileResolver)

        val pathObj = obj.document.resolveIRI(obj.href)
        if (pathObj !is Shape) {
            statePop()
            return null
        }

        val p = getPathFromElement(pathObj)
        if (p == null) {
            statePop()
            return null
        }

        val path = Path(p)
        (pathObj as? HasTransform)?.getTransform()?.let { path.transform(it) }
        val measure = PathMeasure(path, false)
        val startOffset = obj.startOffset?.floatValueInContext(measure.length) ?: 0f

        val children = buildTextChildren(obj)
        val node = TextPathRenderNode(obj, path, startOffset, children)
        node.renderState.apply(state)
        resolveNodePaints(node)
        statePop()
        return node
    }

    private fun buildTRef(obj: TRef): TRefRenderNode? {
        statePush()
        updateStyleForElement(state, obj)
        if (!display()) {
            statePop()
            return null
        }
        state.selectTypefaceAndFontStyling(externalFileResolver)
        val ref = obj.document.resolveIRI(obj.href)
        if (ref is TextContainer) {
            val str = StringBuilder()
            extractRawText(ref, str, state.spacePreserve)

            val x = obj.x?.map { it.floatValueXInContext() }?.toFloatArray()
            val y = obj.y?.map { it.floatValueYInContext() }?.toFloatArray()
            val dx = obj.dx?.map { it.floatValueXInContext() }?.toFloatArray()
            val dy = obj.dy?.map { it.floatValueYInContext() }?.toFloatArray()

            val node = TRefRenderNode(
                sourceElement = obj,
                text = str.toString(),
                x = x,
                y = y,
                dx = dx,
                dy = dy
            )
            node.renderState.apply(state)
            resolveNodePaints(node)
            statePop()
            return node
        }
        statePop()
        return null
    }

    private fun getPathFromElement(obj: Shape): Path? {
        val path = Path()
        return when (obj) {
            is PathShape -> {
                if (updatePathAndBoundingBoxForGraphicsElement(obj, path)) {
                    path
                } else {
                    null
                }
            }

            is RectShape -> {
                updatePathAndBoundingBoxForGraphicsElement(obj, path)
                path
            }

            is CircleShape -> {
                updatePathAndBoundingBoxForGraphicsElement(obj, path)
                path
            }

            is EllipseShape -> {
                updatePathAndBoundingBoxForGraphicsElement(obj, path)
                path
            }

            is LineShape -> {
                updatePathAndBoundingBoxForGraphicsElement(obj, path)
                path
            }

            is PolyLineShape -> {
                if (updatePathAndBoundingBoxForGraphicsElement(obj, path)) {
                    path
                } else {
                    null
                }
            }
        }
    }

    private fun statePush() {
        val newState = RendererState()
        newState.apply(state)
        stateStack.push(state)
        state = newState
    }

    private fun statePop() {
        state = stateStack.pop()
    }

    private fun parentPush(obj: Container) {
        parentStack.push(obj)
    }

    private fun parentPop() {
        parentStack.pop()
    }

    private fun buildClipPath(clipPath: ClipPath): ClipPathRenderNode? {
        val id = clipPath.id
        if (id != null && !buildingIds.add(id)) {
            logW("KSVG") { "Cyclic clip-path reference detected for id '$id'; treating as empty" }
            return null
        }
        try {
        clipPathNodeCache[clipPath]?.let { return it }

        val oldState = state
        val oldStateStack = stateStack.toList()
        stateStack.clear()

        state = findInheritFromAncestorState(clipPath)
        if (clipPath.clipPathUnitsAreUser == false) {
            state.viewBox = null
            state.viewPort = Box._1X1
        }

        val children = buildChildren(clipPath)
        val node = ClipPathRenderNode(clipPath, children)
        node.renderState.apply(state)

        state.style.clipPath?.let {
            val nestedClipPath = document.resolveIRI(it) as? ClipPath
            if (nestedClipPath != null && nestedClipPath !== clipPath) {
                node.clipPathNode = buildClipPath(nestedClipPath)
            }
        }

        state = oldState
        stateStack.clear()
        stateStack.addAll(oldStateStack)

        clipPathNodeCache[clipPath] = node
        return node
        } finally {
            if (id != null) buildingIds.remove(id)
        }
    }

    private fun buildMask(mask: Mask): MaskRenderNode {
        maskNodeCache[mask]?.let { return it }

        val oldState = state
        val oldStateStack = stateStack.toList()
        stateStack.clear()

        state = findInheritFromAncestorState(mask)
        // The 'opacity', 'filter' and 'display' properties do not apply to the 'mask' element" (sect 14.4)
        if (state.style.opacity != 1f) {
            state.style = state.style.copy(opacity = 1f)
        }
        // state.style.filter = null

        val children = buildChildren(mask)
        val node = MaskRenderNode(mask, children)
        node.renderState.apply(state)

        maskNodeCache[mask] = node

        state = oldState
        stateStack.clear()
        stateStack.addAll(oldStateStack)

        return node
    }

    private val tempAncestors = ArrayList<ElementBase>()
    private fun findInheritFromAncestorState(obj: SvgObject): RendererState {
        val newState = RendererState()
        obj.styleBuilder.also { builder ->
            builder.reset(Style.getDefaultStyle())
            updateStyle(newState, builder, Style.getDefaultStyle())
            newState.style = builder.build()
        }
        newState.viewPort = state.viewPort
        newState.viewBox = state.viewBox

        var current: SvgObject? = obj

        val ancestors = tempAncestors
        while (current != null) {
            if (current is ElementBase) {
                ancestors.add(0, current)
            }
            current = current.parent
        }

        styleBuilderPool.withPooledObject { inheritBuilder ->
            inheritBuilder.reset(newState.style)
            ancestors.forEachElement { ancestor ->
                updateStyleForElement(newState, inheritBuilder, ancestor)
            }
            newState.style = inheritBuilder.build()
        }
        ancestors.clear()

        return newState
    }

    private fun buildMarker(marker: Marker): MarkerRenderNode {
        markerNodeCache[marker]?.let { return it }

        val oldState = state
        val oldStateStack = stateStack.toList()
        stateStack.clear()

        state = findInheritFromAncestorState(marker)

        val children = buildChildren(marker)
        val node = MarkerRenderNode(marker, children)
        node.renderState.apply(state)

        markerNodeCache[marker] = node

        state = oldState
        stateStack.clear()
        stateStack.addAll(oldStateStack)

        return node
    }

    private fun buildPattern(pattern: Pattern): PatternRenderNode {
        patternNodeCache[pattern]?.let { return it }

        pattern.href?.let {
            fillInChainedPatternFields(pattern, it)
        }

        val oldState = state
        val oldStateStack = stateStack.toList()
        stateStack.clear()

        state = findInheritFromAncestorState(pattern)
        if (state.style.overflow != false) {
            state.style = state.style.copy(overflow = false) // By default, patterns do not overflow
        }

        val children = buildChildren(pattern)
        val node = PatternRenderNode(pattern, children)
        node.renderState.apply(state)

        val viewBox = pattern.viewBox
        val tileWidth = viewBox?.width
            ?: if (pattern.patternContentUnitsAreUser != false) {
                pattern.width?.floatValueXInContext() ?: 0f
            } else {
                1f
            }
        val tileHeight = viewBox?.height
            ?: if (pattern.patternContentUnitsAreUser != false) {
                pattern.height?.floatValueYInContext() ?: 0f
            } else {
                1f
            }

        if (tileWidth > 0f && tileHeight > 0f) {
            var contentBox: Box? = null
            children.forEachElement {
                it.boundingBox?.let { childBox ->
                    contentBox = contentBox?.union(childBox) ?: childBox
                }
            }
            if (contentBox != null) {
                node.hasOverflow = contentBox.minX < -0.01f || contentBox.minY < -0.01f ||
                        contentBox.maxX() > tileWidth + 0.01f || contentBox.maxY() > tileHeight + 0.01f
            }
        }

        node.hasAnimations = pattern.animations?.isNotEmpty() == true ||
                children.any { it.hasAnimations() }

        patternNodeCache[pattern] = node

        state = oldState
        stateStack.clear()
        stateStack.addAll(oldStateStack)

        return node
    }

    private fun fillInChainedPatternFields(pattern: Pattern, href: String) {
        // Locate the referenced object
        val ref = pattern.document.resolveIRI(href) ?: return
        if (ref !is Pattern) {
            return
        }
        if (ref === pattern) {
            return
        }

        val pRef: Pattern = ref

        if (pattern.patternUnitsAreUser == null) {
            pattern.patternUnitsAreUser = pRef.patternUnitsAreUser
        }

        if (pattern.patternContentUnitsAreUser == null) {
            pattern.patternContentUnitsAreUser = pRef.patternContentUnitsAreUser
        }

        if (pattern.patternTransform == null) {
            pattern.patternTransform = pRef.patternTransform
        }

        if (pattern.x == null) {
            pattern.x = pRef.x
        }

        if (pattern.y == null) {
            pattern.y = pRef.y
        }

        if (pattern.width == null) {
            pattern.width = pRef.width
        }

        if (pattern.height == null) {
            pattern.height = pRef.height
        }

        // attributes from superclasses
        if (pattern.childCount() == 0) {
            pattern.addAll(pRef.getChildren())
        }

        if (pattern.viewBox == null) {
            pattern.viewBox = pRef.viewBox
        }

        if (pattern.preserveAspectRatio == null) {
            pattern.preserveAspectRatio = pRef.preserveAspectRatio
        }

        val nextHref = pRef.href
        if (nextHref != null) {
            fillInChainedPatternFields(pattern, nextHref)
        }
    }

    private fun buildFilter(filter: Filter): FilterRenderNode {
        filterNodeCache[filter]?.let { return it }

        val oldState = state
        val oldStateStack = stateStack.toList()
        stateStack.clear()

        // Filter state initialization if needed
        // For now just keep current state
        
        val primitives = filter.getChildren().mapNotNullElements { child ->
             if (child is FilterPrimitive) {
                 buildFilterPrimitive(child)
             } else {
                 null
             }
        }

        val node = FilterRenderNode(filter, primitives)
        node.renderState.apply(state)
        val filterMode = filter.style?.colorInterpolationFilters
            ?.takeIf { it != ColorInterpolation.UNSPECIFIED }
            ?: filter.baseStyle?.colorInterpolationFilters
                ?.takeIf { it != ColorInterpolation.UNSPECIFIED }
            ?: state.style.colorInterpolationFilters
                .takeIf { it != ColorInterpolation.UNSPECIFIED }
            ?: ColorInterpolation.LINEAR_RGB
        node.colorInterpolationFilters = filterMode
        primitives.forEachElement { primitive ->
            val source = primitive.sourceElement
            primitive.colorInterpolationFilters = source.style?.colorInterpolationFilters
                ?.takeIf { it != ColorInterpolation.UNSPECIFIED }
                ?: source.baseStyle?.colorInterpolationFilters
                    ?.takeIf { it != ColorInterpolation.UNSPECIFIED }
                ?: filterMode
        }
        filterNodeCache[filter] = node

        state = oldState
        stateStack.clear()
        stateStack.addAll(oldStateStack)

        return node
    }

    private fun buildFilterPrimitive(primitive: FilterPrimitive): FilterPrimitiveRenderNode<*> {
        val node = when (primitive) {
            is FeGaussianBlur -> FeGaussianBlurRenderNode(
                sourceElement = primitive,
                stdDeviationX = primitive.stdDeviationX,
                stdDeviationY = primitive.stdDeviationY
            )
            is FeColorMatrix -> FeColorMatrixRenderNode(
                sourceElement = primitive,
                type = primitive.type,
                values = primitive.values
            )
            is FeOffset -> FeOffsetRenderNode(
                sourceElement = primitive,
                dx = primitive.dx?.floatValueInContext() ?: 0f,
                dy = primitive.dy?.floatValueInContext() ?: 0f
            )
            is FeConvolveMatrix -> {
                val orderX = max(primitive.orderX, 1)
                val orderY = max(primitive.orderY, 1)
                val kernel = primitive.kernelMatrix
                val divisor = primitive.divisor.takeIfNonZeroOrElse {
                    kernel?.sum()?.takeIfNonZeroOrElse { 1f } ?: 1f
                }
                FeConvolveMatrixRenderNode(
                    sourceElement = primitive,
                    orderX = orderX,
                    orderY = orderY,
                    kernel = kernel,
                    targetX = clamp(primitive.targetX ?: (orderX / 2), 0, orderX - 1),
                    targetY = clamp(primitive.targetY ?: (orderY / 2), 0, orderY - 1),
                    divisor = divisor,
                    bias = primitive.bias,
                    preserveAlpha = primitive.preserveAlpha,
                    edgeMode = primitive.edgeMode,
                )
            }
            is FeMorphology -> FeMorphologyRenderNode(
                sourceElement = primitive,
                erode = primitive.operator == FeMorphologyOperator.erode
            )
            is FeComponentTransfer -> FeComponentTransferRenderNode(
                sourceElement = primitive,
                transferFunctions = run {
                    var r: FeFunc? = null
                    var g: FeFunc? = null
                    var b: FeFunc? = null
                    var a: FeFunc? = null
                    primitive.getChildren().forEachElement { child ->
                        if (child is FeFunc) {
                            when (child.channel) {
                                FeFunc.Channel.R -> r = child
                                FeFunc.Channel.G -> g = child
                                FeFunc.Channel.B -> b = child
                                FeFunc.Channel.A -> a = child
                            }
                        }
                    }
                    ComponentTransferFunctions(r, g, b, a)
                },
            )
            is FeComposite -> FeCompositeRenderNode(
                primitive,
                paint = createCompositePaint(primitive.operator),
            )
            is FeTurbulence -> FeTurbulenceRenderNode(
                primitive,
                generators = run {
                    val lcg = LcgRandom(if (primitive.seed <= 0) 1 else primitive.seed.toInt())
                    Array(4) { SvgPathNoise(lcg) }
                },
            )
            is FeDisplacementMap -> FeDisplacementMapRenderNode(primitive)
            is FeDiffuseLighting -> FeDiffuseLightingRenderNode(primitive)
            is FeSpecularLighting -> FeSpecularLightingRenderNode(primitive)
            is FeMerge -> {
                val mergeNodes = primitive.getChildren().let { children ->
                    val mergeNodes = ArrayList<String?>(children.size)
                    children.forEachElement { child ->
                        if (child is FeMergeNode) {
                            mergeNodes.add(child.`in`)
                        }
                    }
                    mergeNodes.optimizeReadOnlyList()
                }
                FeMergeRenderNode(primitive, mergeNodes)
            }
            is FeImage -> {
                val href = primitive.href
                val image = href?.let {
                    checkForImageDataURL(it) ?: externalFileResolver?.resolveImage(it)
                }
                // `feImage` may reference another element in the document by id
                // (e.g. `href="#source"`); in that case we build the referenced
                // node and render it instead of an external/raster image.
                val referencedNode = if (href != null && href.startsWith("#")) {
                    document.getElementById(href.substring(1))?.let { build(it) }
                } else {
                    null
                }
                if (image == null && referencedNode == null) {
                    logW("FeImageFilter") { String.format("Could not locate image '%s'", href) }
                }
                FeImageRenderNode(sourceElement = primitive, image = image, referencedNode = referencedNode)
            }
            is FeFlood -> FeFloodRenderNode(primitive).also { node ->
                node.animationNodes = primitive.animations?.mapNotNullElements {
                    buildAnimationNode(it)
                }.orEmpty()
            }
            is FeBlend -> FeBlendRenderNode(
                sourceElement = primitive,
                mode = primitive.mode,
                in2 = primitive.in2,
                paint = createBlendPaint(primitive.mode),
            )
            is FeTile -> FeTileRenderNode(primitive)
            is FeDropShadow -> {
                val bp = primitive.baseParams
                val cb = primitive.conditionalBundle
                val blurNode = FeGaussianBlurRenderNode(
                    sourceElement = FeGaussianBlur(
                        baseParams = bp,
                        conditionalBundle = cb,
                        x = null,
                        y = null,
                        width = null,
                        height = null,
                        result = null,
                        `in` = null,
                        stdDeviationX = primitive.stdDeviationX,
                        stdDeviationY = primitive.stdDeviationY,
                    ),
                    stdDeviationX = primitive.stdDeviationX,
                    stdDeviationY = primitive.stdDeviationY,
                )
                val offsetNode = FeOffsetRenderNode(
                    sourceElement = FeOffset(
                        baseParams = bp,
                        conditionalBundle = cb,
                        x = null,
                        y = null,
                        width = null,
                        height = null,
                        result = null,
                        `in` = null,
                        dx = primitive.dx,
                        dy = primitive.dy,
                    ),
                    dx = 0f,
                    dy = 0f,
                )
                FeDropShadowRenderNode(
                    sourceElement = primitive,
                    blurNode = blurNode,
                    offsetNode = offsetNode,
                )
            }
            else -> GenericFilterPrimitiveRenderNode(primitive)
        }

        node.x = primitive.x?.floatValueXInContext()
        node.y = primitive.y?.floatValueYInContext()
        node.width = primitive.width?.floatValueXInContext()
        node.height = primitive.height?.floatValueYInContext()

        return node
    }

    private fun updateStyleForElement(state: RendererState, obj: ElementBase) {
        // Derive the stroke-dash scaling implied by a declared `pathLength` so that
        // RendererState.updateStrokeDash can honour it. Scale = actualLength / pathLength.
        state.dashLengthScale = computePathLengthScale(obj)

        obj.styleBuilder.also { builder ->
            builder.reset(state.style)
            updateStyleForElement(state, builder, obj)
            state.style = builder.build()
        }
    }

    private fun computePathLengthScale(obj: ElementBase): Float {
        if (obj !is PathShape) return 1f
        val declared = obj.pathLength ?: return 1f
        if (declared <= 0f) return 1f
        val d = obj.d ?: return 1f
        val measure = PathMeasure()
        measure.setPath(PathConverter(d).path, false)
        val length = measure.length
        if (length <= 0f) return 1f
        return length / declared
    }

    private fun updateStyleForElement(state: RendererState, builder: Style.Builder, obj: ElementBase) {
        val isRootSVG = obj.parent == null

        // Pass 1: resolve which properties' winning declaration is a CSS-wide keyword
        // (inherit/unset/initial/revert) so lower-priority concrete values lose to them.
        val matchingRules = ArrayList<Style>()
        document.cSSRules.forEachElement { rule ->
            if (CSSParser.ruleMatch(ruleMatchContext, rule.selector, obj)) {
                matchingRules.add(rule.style)
            }
        }
        val cssWideOverrides = resolveCssWideKeywordMask(obj.baseStyle, matchingRules, obj.style)

        builder.resetNonInheritingProperties(isRootSVG, cssWideOverrides)

        // Pass 2: apply tiers in ascending priority; suppressedFlags hides concrete
        // declarations that lost to a CSS-wide keyword or to '!important'.
        fun apply(source: Style?, importantOnly: Boolean) {
            if (source == null) return
            source.suppressedFlags = cssWideOverrides or
                    if (importantOnly) source.importantFlags.inv() else source.importantFlags
            updateStyle(state, builder, source)
            source.suppressedFlags = 0L
        }
        apply(obj.baseStyle, false)
        matchingRules.forEachElement { apply(it, false) }
        apply(obj.style, false)
        matchingRules.forEachElement { apply(it, true) }
        apply(obj.style, true)

        // Note: we don't apply animations during tree building,
        // they will be applied later using updateAnimations()
    }

    /*
    * Updates the global style state with the style defined by the current object.
    * Will also update the current paints etc. where appropriate.
    */
    private fun updateStyle(state: RendererState, builder: Style.Builder, sourceStyle: Style) {
        updateStyle(state, builder, sourceStyle, this.currentFontSize, sourceStyle.fontWeight)
    }

    private fun makeViewPort(
        x: CSSLength?,
        y: CSSLength?,
        width: CSSLength?,
        height: CSSLength?
    ): Box {
        // Shared implementation lives next to calculateViewBoxTransform.
        return makeViewportInContext(x, y, width, height)
    }

    private fun updateParentBoundingBox(obj: Element, transformOverride: Matrix? = null) {
        if (obj.parent == null) return
        var boundingBox = obj.boundingBox ?: return

        if (parentStack.isEmpty()) return

        // Transform bounding box to parent space
        (transformOverride ?: (obj as? HasTransform)?.getTransform())?.let { matrix ->
            rectFPool.withPooledObject { rect ->
                rect.set(
                    boundingBox.minX,
                    boundingBox.minY,
                    boundingBox.maxX(),
                    boundingBox.maxY()
                )
                matrix.mapRect(rect)
                boundingBox = boundingBox.copy(
                    minX = rect.left,
                    minY = rect.top,
                    width = rect.width(),
                    height = rect.height(),
                )
            }
        }

        val parent = parentStack.peek() as? Element ?: return
        val parentBoundingBox = parent.boundingBox
        parent.boundingBox = parentBoundingBox?.union(boundingBox) ?: boundingBox
    }

    private fun checkXMLSpaceAttribute(obj: SvgObject) {
        if (obj is ElementBase) {
            obj.spacePreserve?.let { state.spacePreserve = it }
        }
    }

    private fun display(): Boolean = state.style.display ?: true
    private fun visible(): Boolean = state.style.visibility ?: true
}
