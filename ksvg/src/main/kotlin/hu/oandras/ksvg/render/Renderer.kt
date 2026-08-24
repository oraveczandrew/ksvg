/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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
@file:Suppress("UsePropertyAccessSyntax")

package hu.oandras.ksvg.render

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PathMeasure
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RadialGradient
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader.TileMode
import android.os.Build
import android.util.Log
import hu.oandras.ksvg.BuildConfig
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.compat.BlendModeCompat
import hu.oandras.ksvg.compat.isBlendModeSupported
import hu.oandras.ksvg.compat.setBlendModeCompat
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.CSSParser.RuleMatchContext
import hu.oandras.ksvg.dom.COLOR_BLACK
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.Element
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.MarkerOrient
import hu.oandras.ksvg.dom.core.SolidColor
import hu.oandras.ksvg.dom.core.Svg
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.gradient.GradientSpread
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PathShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.style.CSSBlendMode
import hu.oandras.ksvg.dom.style.ColorValue
import hu.oandras.ksvg.dom.style.CurrentColor
import hu.oandras.ksvg.dom.style.Isolation
import hu.oandras.ksvg.dom.style.MaskType
import hu.oandras.ksvg.dom.style.PaintReference
import hu.oandras.ksvg.dom.style.RenderQuality
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.dom.style.VectorEffect
import hu.oandras.ksvg.render.animation.AnimationContext
import hu.oandras.ksvg.render.animation.AnimationNode
import hu.oandras.ksvg.render.animation.applyAnimatedStyle
import hu.oandras.ksvg.render.animation.updateAnimations
import hu.oandras.ksvg.render.filters.doFeBlendFilter
import hu.oandras.ksvg.render.filters.doFeColorMatrixFilter
import hu.oandras.ksvg.render.filters.doFeComponentTransferFilter
import hu.oandras.ksvg.render.filters.doFeCompositeFilter
import hu.oandras.ksvg.render.filters.doFeConvolveMatrixFilter
import hu.oandras.ksvg.render.filters.doFeDiffuseLightingFilter
import hu.oandras.ksvg.render.filters.doFeDisplacementMapFilter
import hu.oandras.ksvg.render.filters.doFeGaussianBlurFilter
import hu.oandras.ksvg.render.filters.doFeImageFilter
import hu.oandras.ksvg.render.filters.doFeMergeFilter
import hu.oandras.ksvg.render.filters.doFeMorphologyFilter
import hu.oandras.ksvg.render.filters.doFeOffsetFilter
import hu.oandras.ksvg.render.filters.doFeSpecularLightingFilter
import hu.oandras.ksvg.render.filters.doFeTileFilter
import hu.oandras.ksvg.render.filters.doFeTurbulenceFilter
import hu.oandras.ksvg.filtering.pipeline.FilterBackend
import hu.oandras.ksvg.filtering.pipeline.FilterPipeline
import hu.oandras.ksvg.render.filters.filterGraphInfo
import hu.oandras.ksvg.render.filters.getFilterInput
import hu.oandras.ksvg.render.filters.luminanceToAlphaFloatArray
import hu.oandras.ksvg.render.pool.Pool
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.text.PathTextDrawer
import hu.oandras.ksvg.render.text.PlainTextDrawer
import hu.oandras.ksvg.render.text.PlainTextToPath
import hu.oandras.ksvg.render.text.TextProcessor
import hu.oandras.ksvg.render.text.calculateTextPath
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.colorWithOpacity
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.toDegrees
import hu.oandras.ksvg.utils.withAlpha
import java.util.*
import kotlin.math.atan2
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min


private val SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS: Boolean  = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S // Android 12

/*
 * The rendering part of KSVG.
 */
@SuppressLint("UseKtx")
@Suppress("LocalVariableName")
internal class Renderer internal constructor(
    internal val document: SVGImpl,
    // dots per inch. Needed for accurate conversion of length values that have real world units, such as "cm".
    override val dPI: Float,
    pools: PoolOwner,
): AnimationContext, PoolOwner by pools {
    // Renderer state
    private var state: RendererState = RendererState()

    // Filter-pipeline backend, resolved per render operation (canvas capability).
    private var filterBackend: FilterBackend? = null
    private var filterBackendHardware: Boolean = false

    // Reused across text renders to avoid per-element allocation in the render loop.
    private val plainTextDrawer = PlainTextDrawer(state)

    private val stateStack: Stack<SavedRendererState> = Stack() // Keeps track of render state as we render

    // Keep track of element stack while rendering.
    private val parentStack: Stack<Container> =
        Stack() // The 'render parent' for elements like Symbol cf. file parent

    private val matrixStack: Stack<Matrix> =
        Stack() // Keeps track of current transform as we descend into element tree

    private var ruleMatchContext: RuleMatchContext? = null

    override val currentFontSize: Float
        get() = state.fillConfig.textSize

    override val currentFontXHeight: Float
        get() {
            // The CSS3 spec says to use 0.5em if there is no way to determine true x-height;
            return currentFontSize / 2f
        }

    override val savedRendererStatePool: Pool<SavedRendererState> = object : Pool<SavedRendererState>() {
        private val defaultRenderState = RendererState()

        override fun createInstance(): SavedRendererState {
            return SavedRendererState(defaultRenderState, 0)
        }

        override fun resetInstance(item: SavedRendererState) {
            // ignore
        }
    }

    override val renderStatePool: Pool<RendererState> = object : Pool<RendererState>() {

        private val defaultRenderState = RendererState()

        override fun createInstance(): RendererState {
            return RendererState()
        }

        override fun resetInstance(item: RendererState) {
            item.apply(defaultRenderState)
        }
    }

    override val animationTimeMs: Long
        get() = document.animationTimeMs

    override val effectiveViewPortInUserUnits: Box
        /*
         * Get the current view port in user units.
         * If a viewBox is in effect, then this will return the viewBox
         * since a viewBox transform will have already been applied.
         */
        get() {
            val s = state
            return s.viewBox ?: checkNotNull(s.viewPort) { "Viewport is null" }
        }

    private fun resetState(canvas: Canvas) {
        val oldState = state
        val state = renderStatePool.pull()
        this.state = state
        renderStatePool.release(oldState)
        savedRendererStatePool.releaseAll(stateStack)

        // Initialize the style state properties like Paints etc. using a fresh instance of Style
        styleBuilderPool.withPooledObject { builder ->
            builder.reset(Style.getDefaultStyle())
            updateStyle(state, builder, Style.getDefaultStyle())
            state.style = builder.build()
        }

        state.viewPort = null // Get filled in later

        state.spacePreserve = false

        // Push a copy of the state with 'default' style, so that inherit works for top level objects
        stateStack.push(newSavedRendererState(state , canvas.saveCount)) // Manual push here - don't use statePush();

        // Keep track of element stack while rendering.
        // The 'render parent' for some elements (e.g. <use> references) is different from its DOM parent.
        matrixPool.releaseAll(matrixStack)
        parentStack.clear()
    }

    private fun newSavedRendererState(state: RendererState, canvasSaveCount: Int): SavedRendererState {
        return savedRendererStatePool.pull().also {
            it.state = state
            it.canvasSaveCount = canvasSaveCount
        }
    }

    /*
     * Render the whole document starting from a RenderNode tree.
    */
    internal fun renderDocument(canvas: Canvas, rootNode: RenderNode<*>, renderOptions: RenderOptions) {

        val css = renderOptions.css
        if (css != null) {
            document.addCSSRules(css.cssRuleSet)
        }

        if (renderOptions.hasTarget()) {
            ruleMatchContext = RuleMatchContext(
                targetElement = document.getElementById(renderOptions.targetId)
            )
        }

        // Initialize the state
        resetState(canvas)

        if (document.animationsEnabled) {
            rootNode.updateAnimations(document.animationTimeMs)
        }

        withNewRootContextState(canvas) { canvas, _ ->
            val viewPort = (rootNode as? GroupRenderNode)?.viewPort ?: renderOptions.viewPort
            if (viewPort != null && rootNode.renderState.style.overflow == false) {
                setClipRect(canvas, viewPort)
            }
            rootNode.render(this@Renderer, canvas)
        }

        if (renderOptions.hasCss()) {
            document.clearRenderCSSRules()
        }
    }


    internal fun renderGroupNode(canvas: Canvas, node: GroupRenderNode<*>) {
        withNewNodeState(canvas, node, saveCanvas = true) { canvas, _ ->
            val sourceElement = node.sourceElement
            if (sourceElement is Svg && node.renderState.style.overflow == false) {
                node.viewPort?.let { setClipRect(canvas, it) }
            }

            node.applyTransformTo(canvas)
            node.viewBoxTransform?.let { canvas.concat(it) }

            parentPush(sourceElement, canvas)

            try {
                if (checkForClipPath(node, canvas)) {
                    withNewRenderLayer(canvas, node) { canvas, _ ->
                        // Static groups are captured whole: one replay per frame.
                        node.withNodeDisplayList(canvas) { nodeCanvas ->
                            node.children.forEachElement { it.render(this@Renderer, nodeCanvas) }
                        }
                    }
                }

                updateParentBoundingBox(canvas, sourceElement)
            } finally {
                parentPop()
            }
        }
    }

    internal fun renderSwitchNode(canvas: Canvas, node: SwitchRenderNode) {
        withNewNodeState(canvas, node, saveCanvas = true) { canvas, _ ->
            node.applyTransformTo(canvas)

            val sourceElement = node.sourceElement
            parentPush(sourceElement, canvas)

            try {
                if (checkForClipPath(node, canvas)) {
                    withNewRenderLayer(canvas, node) { canvas, _ ->
                        node.selectedChild?.render(this@Renderer, canvas)
                    }
                }

                updateParentBoundingBox(canvas, node.sourceElement)
            } finally {
                parentPop()
            }
        }
    }

    internal fun renderPathNode(canvas: Canvas, node: PathRenderNode) {
        withNewNodeState(canvas, node, requireVisible = true, saveCanvas = true) { canvas, _ ->
            node.applyTransformTo(canvas)

            val sourceElement = node.sourceElement
            updateParentBoundingBox(canvas, sourceElement)

            checkForGradientsAndPatterns(canvas, node, sourceElement)
            if (checkForClipPath(node, canvas)) {
                withNewRenderLayer(canvas, node) { canvas, state ->
                    val hasMarkers = node.markers != null || state.style.markerStart != null ||
                            state.style.markerMid != null || state.style.markerEnd != null
                    // Static, plain fill/stroke paths are drawn through the
                    // display-list cache: playback is native, bypassing OEM canvas
                    // hooks (changeArea etc.) and their per-draw allocations.
                    val pathCacheable = node.fillPatternNode == null &&
                            node.strokePatternNode == null && !hasMarkers &&
                            state.style.vectorEffect == VectorEffect.None

                    if (!pathCacheable) {
                        drawPathContent(canvas, node, state)
                    } else {
                        node.withNodeDisplayList(canvas) { nodeCanvas ->
                            drawPathContent(nodeCanvas, node, state)
                        }
                    }
                }
            }
        }
    }

    internal fun renderTextNode(canvas: Canvas, node: TextRenderNode) {
        withNewNodeState(canvas, node, saveCanvas = true) { canvas, _ ->
            node.applyTransformTo(canvas)

            val sourceElement = node.sourceElement

            checkForGradientsAndPatterns(canvas, node, sourceElement)
            if (checkForClipPath(node, canvas)) {
                withNewRenderLayer(canvas, node) { canvas, state ->
                    val processor = plainTextDrawer
                    processor.state = state
                    processor.x = node.x + node.dx
                    processor.y = node.y + node.dy
                    renderTextContainer(canvas, node, processor)
                }
            }
        }
    }

    internal fun renderTSpanNode(canvas: Canvas, node: TSpanRenderNode, processor: TextProcessor) {
        withNewNodeState(canvas, node) { canvas, state ->
            // The shared PlainTextDrawer holds a reference to the parent text's
            // renderer state, so temporarily point it at this tspan's styled state
            // so the tspan's own font styling is applied to its text.
            val plainDrawer = processor as? PlainTextDrawer
            val processorState = plainDrawer?.state
            try {
                if (plainDrawer != null) {
                    plainDrawer.state = state
                }
                processor.pushPositioning(node.x, node.y, node.dx, node.dy)

                checkForGradientsAndPatterns(canvas, node, node.sourceElement.textRoot as Element)

                withNewRenderLayer(canvas, node) { canvas, _ ->
                    renderTextContainer(canvas, node, processor)
                }
            } finally {
                processor.popPositioning()
                if (plainDrawer != null) plainDrawer.state = processorState ?: state
            }
        }
    }

    internal fun renderTextPathNode(canvas: Canvas, node: TextPathRenderNode) {
        withNewNodeState(canvas, node, requireVisible = true) { canvas, _ ->
            checkForGradientsAndPatterns(canvas, node, node.sourceElement.textRoot as Element)

            withNewRenderLayer(canvas, node) { canvas, _ ->
                renderTextContainer(
                    canvas = canvas,
                    node = node,
                    processor = PathTextDrawer(
                        path = node.path,
                        state = state
                    ).apply {
                        x = node.startOffset
                        y = 0f
                    }
                )
            }
        }
    }

    internal fun renderTRefNode(canvas: Canvas, node: TRefRenderNode, processor: TextProcessor) {
        withNewNodeState(canvas, node) { canvas, state ->
            checkForGradientsAndPatterns(canvas, node, node.sourceElement.textRoot as Element)

            // The shared PlainTextDrawer holds a reference to the parent text's
            // renderer state, so temporarily point it at this tref's styled state
            // so the tref's own font styling is applied to its text.
            val plainDrawer = processor as? PlainTextDrawer
            val processorState = plainDrawer?.state
            try {
                if (plainDrawer != null) {
                    plainDrawer.state = state
                }
                processor.pushPositioning(node.x, node.y, node.dx, node.dy)
                processor.processText(canvas, node.text)
            } finally {
                processor.popPositioning()
                if (plainDrawer != null) plainDrawer.state = processorState ?: state
            }
        }
    }

    private fun renderTextContainer(
        canvas: Canvas,
        node: KSVGTextContainerRenderNode<*>,
        processor: TextProcessor,
    ) {
        node.children.forEachElement { child ->
            when (child) {
                is TextSequenceNode -> processor.processText(canvas, child.text)
                is TSpanRenderNode -> renderTSpanNode(canvas, child, processor)
                is TextPathRenderNode -> renderTextPathNode(canvas, child)
                is TRefRenderNode -> renderTRefNode(canvas, child, processor)
                else -> {}
            }
        }
    }

    internal fun renderImageNode(canvas: Canvas, node: ImageRenderNode) {
        withNewNodeState(canvas, node, requireVisible = true, saveCanvas = true) { canvas, _ ->
            node.applyTransformTo(canvas)

            val sourceElement = node.sourceElement
            updateParentBoundingBox(canvas, sourceElement)

            if (checkForClipPath(node, canvas)) {
                withNewRenderLayer(canvas, node) { canvas, _ ->
                    viewportFill(canvas)

                    val image = node.bitmap ?: return@withNewRenderLayer
                    val imageNaturalSize = node.imageNaturalSize ?: return@withNewRenderLayer

                    canvas.withSave {
                        // Local transform from image's natural dimensions to the specified SVG dimensions
                        matrixPool.withPooledObject { m ->
                            val positioning = sourceElement.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX
                            val imageBox = node.imageBox
                            calculateViewBoxTransform(
                                viewPortMinX = imageBox.minX,
                                viewPortMinY = imageBox.minY,
                                viewPortWidth = imageBox.width,
                                viewPortHeight = imageBox.height,
                                viewBox = imageNaturalSize,
                                positioning = positioning,
                                outMatrix = m
                            )
                            canvas.concat(m)
                        }

                        val bmPaint = if (state.style.imageRendering == RenderQuality.optimizeSpeed) {
                            bitmapPaintOptimizeSpeed
                        } else {
                            bitmapPaint
                        }
                        canvas.drawBitmap(image, 0f, 0f, bmPaint)
                    }
                }
            }
        }
    }

    private inline fun withNewRootContextState(canvas: Canvas, r: (Canvas, RendererState) -> Unit) {
        val state = statePush(canvas, isRootContext = true)
        try {
            r(canvas, state)
        } finally {
            statePop(canvas)
        }
    }

    private inline fun <T> withNewState(
        canvas: Canvas,
        saveCanvas: Boolean = true,
        r: (state: RendererState) -> T
    ): T {
        val stateStackState = if (BuildConfig.DEBUG) {
            stateStack.size
        } else {
            0
        }
        val state = statePush(canvas = canvas, saveCanvas = saveCanvas)
        return try {
            r.invoke(state)
        } finally {
            statePop(canvas)
            if (BuildConfig.DEBUG) {
                check(stateStack.size == stateStackState) {
                    "Stack size mismatch expected: $stateStackState, was: ${stateStack.size}!"
                }
            }
        }
    }

    //==============================================================================
    private val statePushRectF = Rect()
    @JvmSynthetic
    internal fun statePush(
        canvas: Canvas,
        isRootContext: Boolean = false,
        saveCanvas: Boolean = true,
        applyFrom: RendererState = state,
        host: RenderNode<*>? = null,
    ): RendererState {
        val savedCount = if (saveCanvas) {
            if (isRootContext) {
                // Root SVG context should be transparent. So we need to saveLayer
                // to avoid background messing with blend modes etc.
                val statePushRectF = statePushRectF
                canvas.getClipBounds(statePushRectF)
                canvas.saveLayer(
                    statePushRectF.left.toFloat(),
                    statePushRectF.top.toFloat(),
                    statePushRectF.right.toFloat(),
                    statePushRectF.bottom.toFloat(),
                    null
                )
            } else {
                canvas.save()
            }
        } else {
            -1
        }
        // Save style state
        val oldState = state
        stateStack.push(newSavedRendererState(oldState, savedCount))
        val newState = renderStatePool.pull()
        newState.apply(applyFrom)
        newState.paintHost = host
        state = newState
        return newState
    }

    private inline fun withNewNodeState(
        canvas: Canvas,
        node: RenderNode<*>,
        requireVisible: Boolean = false,
        saveCanvas: Boolean = false,
        r: (Canvas, RendererState) -> Unit,
    ) {
        val newState = statePush(canvas, saveCanvas = saveCanvas, applyFrom = node.renderState, host = node)
        val oldState = stateStack.peek().state
        if (newState.contextStroke == null) newState.contextStroke = oldState.contextStroke
        if (newState.contextFill == null) newState.contextFill = oldState.contextFill
        reapplyDynamicPaints(newState)
        try {
            if (!display() || requireVisible && !visible()) return
            r(canvas, newState)
        } finally {
            statePop(canvas)
        }
    }

    private fun RenderNode<*>.applyTransformTo(canvas: Canvas) {
        transform?.let { canvas.concat(it) }
    }

    private fun angleFromTangent(dx: Float, dy: Float): Float = atan2(dy, dx).toDegrees()

    @JvmSynthetic
    internal fun statePop(canvas: Canvas) {
        val oldState = state
        val poppedState = stateStack.pop()
        if (poppedState.canvasSaveCount != -1) {
            canvas.restoreToCount(poppedState.canvasSaveCount)
        }
        state = poppedState.state
        savedRendererStatePool.release(poppedState)
        renderStatePool.release(oldState)
    }

    private fun switchState(newState: RendererState) {
        val oldState = state
        newState.paintHost = oldState.paintHost
        state = newState
        renderStatePool.release(oldState)
    }


    /**
     * Inline: zero allocation. Decides between replaying a cached display list,
     * recording new content into one, or drawing directly -- then invokes
     * [content] with the correct target canvas.
     */
    private inline fun RenderNode<*>.withNodeDisplayList(
        canvas: Canvas,
        content: (Canvas) -> Unit,
    ) {
        // Software targets cannot play back display lists.
        if (!canvas.isHardwareAccelerated) { content(canvas); return }
        // Animated subtrees change every frame; caching would be pure overhead.
        if (hasAnimationsInSubtree) { content(canvas); return }
        val bb = boundingBox ?: run { content(canvas); return }

        var rec = displayList
        if (rec == null) {
            rec = CanvasRenderNodeCompatFactory.create(canvas)
            displayList = rec
        }
        if (!rec.isSupported) { content(canvas); return }

        val key = displayListKey(this)

        // Replay existing capture if the content hasn't changed.
        if (rec.replay(canvas, key)) return

        // Record fresh content, then replay it once onto the real canvas.
        val pad = 16f
        val w = (bb.width + 2 * pad).toInt().coerceAtLeast(1)
        val h = (bb.height + 2 * pad).toInt().coerceAtLeast(1)
        val ox = bb.minX - pad
        val oy = bb.minY - pad

        val nodeCanvas = rec.beginRecord(key, w, h, ox, oy)
        try {
            content(nodeCanvas)
        } finally {
            rec.endRecord()
        }
        rec.replay(canvas, key)
    }

    private fun displayListKey(node: RenderNode<*>): Long {
        var k = node.contentVersion.toLong() * 31
        k = k * 31 + node.renderState.fillConfig.version
        k = k * 31 + node.renderState.strokeConfig.version
        return k
    }

    private fun drawPathContent(canvas: Canvas, node: PathRenderNode, state: RendererState) {
        // paintOrder is stored already encoded as three 2-bit digits; 0 = normal.
        val order = state.style.paintOrder.takeIf { it != 0 } ?: FILL_STROKE_MARKERS
        for (shift in 4 downTo 0 step 2) {
            when ((order shr shift) and 3) {
                COMPONENT_FILL -> if (state.hasFill) {
                    node.path.fillType = state.fillType
                    doFilledPath(node, node.path, canvas)
                }
                COMPONENT_STROKE -> if (state.hasStroke) {
                    doStroke(node.path, node, canvas)
                }
                COMPONENT_MARKERS -> renderMarkers(canvas, node)
            }
        }
    }

    //==============================================================================
    private fun parentPush(obj: Container, canvas: Canvas) {
        parentStack.push(obj)

        val matrixToPush = matrixPool.pull()
        @Suppress("DEPRECATION")
        canvas.getMatrix(matrixToPush)
        matrixStack.push(matrixToPush)
    }

    private fun parentPop() {
        parentStack.pop()
        matrixPool.release(matrixStack.pop())
    }
    //==============================================================================

    private val matchingRules = ArrayList<Style>()
    private fun updateStyleForElement(
        state: RendererState,
        builder: Style.Builder,
        obj: ElementBase,
        animationNodes: List<AnimationNode>?
    ) {
        val isRootSVG = obj.parent == null

        // Pass 1: resolve CSS-wide keyword winners (see RenderTreeBuilder).
        matchingRules.clear()
        document.cSSRules.forEachElement { rule ->
            if (CSSParser.ruleMatch(ruleMatchContext, rule.selector, obj)) {
                matchingRules.add(rule.style)
            }
        }
        val cssWideOverrides = resolveCssWideKeywordMask(obj.baseStyle, matchingRules, obj.style)

        builder.resetNonInheritingProperties(isRootSVG, cssWideOverrides)

        // Pass 2: apply tiers in ascending priority (see RenderTreeBuilder).
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

        applyAnimatedStyle(state, builder, animationNodes)
    }

    /*
     * Fill a path with either the given paint or if a pattern is set, with the pattern.
     */
    private fun doFilledPath(node: PathRenderNode, path: Path, canvas: Canvas) {
        val s = state

        val fillPatternNode = node.fillPatternNode
        if (fillPatternNode != null) {
            fillWithPattern(node, path, fillPatternNode, canvas)
            return
        }

        // Otherwise do a normal fill
        canvas.drawPath(path, s.fillPaint)
    }

    private fun doStroke(path: Path, node: PathRenderNode, canvas: Canvas) {
        val state = state

        val strokePatternNode = node.strokePatternNode
        if (strokePatternNode != null) {
            pathPool.withPooledObject { strokedPath ->
                state.strokePaint.getFillPath(path, strokedPath)
                fillWithPattern(node, strokedPath, strokePatternNode, canvas)
            }
            return
        }

        if (state.style.vectorEffect == VectorEffect.NonScalingStroke) {
            // For non-scaling-stroke, the stroke width is not transformed along with the path.
            // It will be rendered at the same width no matter how the document contents are transformed.

            // First step: get the current canvas matrix

            matrixPool.withPooledObject { currentMatrix ->
                matrixPool.withPooledObject { currentShaderMatrix ->
                    @Suppress("DEPRECATION")
                    canvas.getMatrix(currentMatrix)
                    // Transform the path using this transform
                    pathPool.withPooledObject { transformedPath ->
                        path.transform(currentMatrix, transformedPath)
                        // Reset the current canvas transform completely
                        canvas.setMatrix(null)

                        // If there is a shader (such as a gradient), we need to update its transform also
                        val shader = state.strokePaint.shader
                        if (shader != null) {
                            shader.getLocalMatrix(currentShaderMatrix)
                            matrixPool.withPooledObject { newShaderMatrix ->
                                newShaderMatrix.set(currentShaderMatrix)
                                newShaderMatrix.postConcat(currentMatrix)
                                shader.setLocalMatrix(newShaderMatrix)
                            }
                        }

                        // Render the transformed path. The stroke width used will be in unscaled device units.
                        drawStrokePath(transformedPath, canvas)

                        // Return the current canvas transform to what it was before all this happened
                        canvas.setMatrix(currentMatrix)
                        // And reset the shader matrix also
                        shader?.setLocalMatrix(currentShaderMatrix)
                    }
                }
            }
        } else {
            drawStrokePath(path, canvas)
        }
    }

    private fun drawStrokePath(path: Path, canvas: Canvas) {
        val strokePaint = state.strokePaint
        canvas.drawPath(path, strokePaint)
        if (strokePaint.strokeCap != Paint.Cap.BUTT) {
            renderDegeneratePath(path, canvas)
        }
    }

    private val degeneratePathMeasure = PathMeasure()
    private val degeneratePathPos = FloatArray(2)
    private fun renderDegeneratePath(path: Path, canvas: Canvas) {
        val pm = degeneratePathMeasure
        pm.setPath(path, false)
        val pos = degeneratePathPos
        while (true) {
            if (pm.length == 0f) {
                pm.getPosTan(0f, pos, null)
                canvas.drawPoint(pos[0], pos[1], state.strokePaint)
            }
            if (!pm.nextContour()) break
        }
    }

    //==============================================================================
    /*
    * Called by an object to update its parent's bounding box.
    *
    * This operation is made more tricky because the child's boundingBox is in the child's coordinate space,
    * but the parent needs it in the parent's coordinate space.
    */
    private val tempFloatArrayForPts = FloatArray(8)
    private fun updateParentBoundingBox(canvas: Canvas, obj: Element) {
        if (obj.parent == null)  // skip this if obj is root element
            return

        val boundingBox = obj.boundingBox
            ?: return // empty boundingBox, possibly as a result of a badly defined element (e.g., bad use reference etc.)

        if (matrixStack.isEmpty())
            return

        // Convert the corners of the child boundingBox to world space
        matrixPool.withPooledObject { m ->
            // Get the inverse of the child transform
            if (matrixStack.peek()!!.invert(m)) {
                val pts = tempFloatArrayForPts

                pts[0] = boundingBox.minX
                pts[1] = boundingBox.minY
                pts[2] = boundingBox.maxX()
                pts[3] = boundingBox.minY
                pts[4] = boundingBox.maxX()
                pts[5] = boundingBox.maxY()
                pts[6] = boundingBox.minX
                pts[7] = boundingBox.maxY()

                // Now concatenate the parent's matrix to create a child-to-parent transform
                matrixPool.withPooledObject { mOut ->
                    @Suppress("DEPRECATION")
                    canvas.getMatrix(mOut)
                    m.preConcat(mOut)
                }

                m.mapPoints(pts)

                // Finally, find the bounding box of the transformed points
                var minX = pts[0]
                var minY = pts[1]
                var maxX = pts[0]
                var maxY = pts[1]
                var i = 2
                while (i <= 6) {
                    if (pts[i] < minX) minX = pts[i]
                    if (pts[i] > maxX) maxX = pts[i]
                    if (pts[i + 1] < minY) minY = pts[i + 1]
                    if (pts[i + 1] > maxY) maxY = pts[i + 1]
                    i += 2
                }
                // Update the parent bounding box with the transformed boundingBox
                val parent = parentStack.peek() as Element
                val currentParentBox = parent.boundingBox
                parent.boundingBox = if (currentParentBox == null) {
                    val fMinX = floor(minX)
                    val fMinY = floor(minY)
                    Box(
                        minX = fMinX,
                        minY = fMinY,
                        width = ceil(maxX) - fMinX,
                        height = ceil(maxY) - fMinY
                    )
                } else {
                    currentParentBox.union(
                        otherMinX = minX,
                        otherMinY = minY,
                        otherMaxX = maxX,
                        otherMaxY = maxY
                    )
                }
            }
        }
    }

    private val getValuesFloatArray = FloatArray(9)
    private inline fun withNewRenderLayer(
        canvas: Canvas,
        node: RenderNode<*>,
        opacityAdjustment: Float = 1f,
        isMaskContent: Boolean = false,
        r: (Canvas, RendererState) -> Unit,
    ) {
        val filterNode = node.filterNode
        if (filterNode != null) {
            renderWithFilter(canvas, node, filterNode, r)
            return
        }

        val stateStackState = if (BuildConfig.DEBUG) {
            stateStack.size
        } else {
            0
        }
        val pushed = pushLayer(canvas, node, opacityAdjustment)
        try {
            r(canvas, state)
        } finally {
            if (pushed) {
                popLayer(canvas, node, isMaskContent)
            }
            if (BuildConfig.DEBUG) {
                val sourceElement = node.sourceElement
                check(stateStack.size == stateStackState) {
                    "Stack size mismatch for node ${sourceElement.getNodeName()} (id: ${sourceElement.id}) expected: $stateStackState, was: ${stateStack.size}!"
                }
            }
        }
    }

    private inline fun renderWithFilter(
        canvas: Canvas,
        node: RenderNode<*>,
        filterNode: FilterRenderNode,
        r: (Canvas, RendererState) -> Unit,
    ) {
        val filter = filterNode.sourceElement
        if (node.boundingBox == null) {
            pathPool.withPooledObject { tempPath ->
                if (nodeToPath(node, tempPath)) {
                    node.updateBoundingBox(tempPath)
                }
            }
        }
        val boundingBox = node.boundingBox ?: Box.EMPTY

        // GPU effect-chain attempt. The native CPU backend answers null and the
        // primitive walk below is skipped entirely on the software path.
        val hardwareCanvas = canvas.isHardwareAccelerated && Build.VERSION.SDK_INT >= 31
        val effectChain = if (hardwareCanvas) {
            val backend = obtainFilterBackend(canvas)
            backend.buildEffectChain(
                filterGraphInfo(filterNode)
            )
        } else {
            null
        }
        if (effectChain != null) {
            // GPU fast path lands with FilterPipelineImpl31/Impl33; the native
            // backend never produces a chain.
            return
        }

        rectFPool.withPooledObject { region ->
            calculateRegion(filter, boundingBox, region)
            if (region.width() > 0f && region.height() > 0f) {

                matrixPool.withPooledObject { matrix ->
                    matrixPool.withPooledObject { newMatrix ->
                        rectFPool.withPooledObject { deviceRegion ->
                            @Suppress("DEPRECATION")
                            canvas.getMatrix(matrix)

                            matrix.mapRect(deviceRegion, region)

                            val m = getValuesFloatArray
                            matrix.getValues(m)
                            val sx = hypot(m[Matrix.MSCALE_X], m[Matrix.MSKEW_Y])
                            val sy = hypot(m[Matrix.MSCALE_Y], m[Matrix.MSKEW_X])
                            val width = stabilizeDimension(deviceRegion.width().ceilToInt())
                            val height = stabilizeDimension(deviceRegion.height().ceilToInt())

                            // Cache check
                            val cachedFilterOutput = node.cachedFilterOutput
                            if (cachedFilterOutput != null &&
                                node.lastSourceVersion == node.contentVersion &&
                                node.lastFilterVersion == filterNode.version &&
                                node.lastScaleX == sx &&
                                node.lastScaleY == sy &&
                                cachedFilterOutput.width == width &&
                                cachedFilterOutput.height == height
                            ) {

                                canvas.withSave {
                                    canvas.setMatrix(null)
                                    canvas.drawBitmap(cachedFilterOutput, deviceRegion.left, deviceRegion.top, configureFilterCompositePaint(state))
                                }
                                return
                            }

                            // Need to re-render source or re-apply filter
                            var sourceBitmap = node.cachedSourceContent
                            val needsSourceWidth: Int = width
                            val needsSourceHeight: Int = height

                            val canReuseSource = sourceBitmap != null &&
                                    !sourceBitmap.isRecycled &&
                                    sourceBitmap.allocationByteCount >= needsSourceWidth * needsSourceHeight * 4

                            if (sourceBitmap == null ||
                                node.lastSourceVersion != node.contentVersion ||
                                node.lastScaleX != sx ||
                                node.lastScaleY != sy ||
                                sourceBitmap.width != needsSourceWidth ||
                                sourceBitmap.height != needsSourceHeight
                            ) {

                                // Re-render source content
                                if (!canReuseSource) {
                                    if (sourceBitmap != null) {
                                        bitmapPool.release(sourceBitmap)
                                    }
                                    sourceBitmap = bitmapPool.acquire(
                                        needsSourceWidth,
                                        needsSourceHeight,
                                        Bitmap.Config.ARGB_8888
                                    )
                                    node.cachedSourceContent = sourceBitmap
                                } else {
                                    sourceBitmap.reconfigure(needsSourceWidth, needsSourceHeight, Bitmap.Config.ARGB_8888)
                                    sourceBitmap.eraseColor(0)
                                }

                                canvasPool.withPooledObject { c ->
                                    c.setBitmap(sourceBitmap)
                                    newMatrix.set(matrix)
                                    newMatrix.postTranslate(-deviceRegion.left, -deviceRegion.top)
                                    c.setMatrix(newMatrix)

                                    val stateStackState = stateStack.size
                                    try {
                                        r.invoke(c, state)
                                    } finally {
                                        if (BuildConfig.DEBUG) {
                                            val sourceElement = node.sourceElement
                                            check(stateStack.size == stateStackState) {
                                                "Stack size mismatch after rendering filter source for node ${sourceElement.getNodeName()} (id: ${sourceElement.id})"
                                            }
                                        }
                                    }
                                }
                                node.lastSourceVersion = node.contentVersion
                            }

                            // Re-apply filter
                            if (cachedFilterOutput != null && cachedFilterOutput !== node.cachedSourceContent) {
                                if (cachedFilterOutput.allocationByteCount < width * height * 4) {
                                    bitmapPool.release(cachedFilterOutput)
                                    node.cachedFilterOutput = null
                                }
                            }

                            val filteredBitmap = applyFilterToBitmap(
                                canvas = canvas,
                                sourceBitmap = sourceBitmap,
                                region = deviceRegion,
                                sx = sx,
                                sy = sy,
                                filterNode = filterNode,
                                originalObjBBox = boundingBox
                            )

                            node.cachedFilterOutput = filteredBitmap
                            node.lastFilterVersion = filterNode.version
                            node.lastScaleX = sx
                            node.lastScaleY = sy

                            if (filteredBitmap != null) {
                                canvas.withSave {
                                    canvas.setMatrix(null)
                                    canvas.drawBitmap(filteredBitmap, deviceRegion.left, deviceRegion.top, configureFilterCompositePaint(state))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //==============================================================================
    private val saveLayerPaint = Paint()
    @JvmSynthetic
    internal fun pushLayer(
        canvas: Canvas,
        node: RenderNode<*>,
        opacityAdjustment: Float = 1f,
    ): Boolean {
        // opacityAdjustment is used by fillWithPattern() to apply the fillOpacity for the
        // pattern

        val oldState = state
        if (!requiresCompositing(node) && opacityAdjustment == 1f) {
            return false
        }

        saveLayerPaint.alpha = clamp255(oldState.style.opacity * opacityAdjustment * 255f)

        if (oldState.style.mixBlendMode != CSSBlendMode.normal) {
            setBlendMode(oldState, saveLayerPaint)
        }

        val statePushRectF = statePushRectF
        canvas.getClipBounds(statePushRectF)
        val savedCount = canvas.saveLayer(
            /* left = */ statePushRectF.left.toFloat(),
            /* top = */ statePushRectF.top.toFloat(),
            /* right = */ statePushRectF.right.toFloat(),
            /* bottom = */ statePushRectF.bottom.toFloat(),
            /* paint = */ saveLayerPaint
        )

        // Save style state
        stateStack.push(newSavedRendererState(oldState, savedCount))
        val newState = renderStatePool.pull()
        newState.apply(oldState)
        newState.paintHost = oldState.paintHost
        state = newState

        return true
    }

    /**
     * @param node The node we are compositing. Compositing happens if the node is not fully opaque or if it has a mask.
     */
    @JvmSynthetic
    internal fun popLayer(canvas: Canvas, node: RenderNode<*>, isMaskContent: Boolean = false) {
        try {
            // If this is masked content, apply the mask now
            val maskNode = if (isMaskContent) null else node.maskNode
            val originalObjBBox = node.boundingBox
            if (maskNode != null && originalObjBBox != null) {
                val maskType = maskNode.renderState.style.maskType

                // The masked content has been drawn, now we have to composite it with our mask layer.
                // The mask has to be built from two parts:
                // Step 1: Apply a luminanceToAlpha conversion to the mask content.
                // Step 2: Multiply the mask's alpha to the alpha channel generated in step 1.

                // Final mask gets composited using Porter Duff mode DST_IN
                val layer1Count = canvas.saveLayer(originalObjBBox, maskPaintCombined)

                if (maskType == MaskType.luminance) {
                    // Step 1: convert the mask luminance to alpha.
                    val layer2Count = canvas.saveLayer(originalObjBBox, luminanceToAlphaPaint)
                    renderMask(canvas, maskNode, node)
                    canvas.restoreToCount(layer2Count)
                    // Step 2: multiply the luminance alpha by the source alpha.
                    val layer3Count = canvas.saveLayer(originalObjBBox, dstInPaint)
                    renderMask(canvas, maskNode, node)
                    canvas.restoreToCount(layer3Count)
                } else {
                    // For mask-type: alpha, the mask's alpha channel is the final mask.
                    renderMask(canvas, maskNode, node)
                }

                // Apply the final mask to the original object waiting in the open layer created in pushLayer()
                canvas.restoreToCount(layer1Count)
            }
        } finally {
            statePop(canvas)
        }
    }

    private fun obtainFilterBackend(canvas: Canvas): FilterBackend {
        val hardware = canvas.isHardwareAccelerated
        val existing = filterBackend
        if (existing != null && filterBackendHardware == hardware) {
            return existing
        }
        val created = FilterPipeline.create(canvas)
        filterBackend = created
        filterBackendHardware = hardware
        return created
    }

    @JvmSynthetic
    internal fun applyFilterToBitmap(
        canvas: Canvas,
        sourceBitmap: Bitmap,
        region: RectF,
        sx: Float,
        sy: Float,
        filterNode: FilterRenderNode,
        originalObjBBox: Box,
    ): Bitmap? {
        val filter = filterNode.sourceElement

        val results = filterNode.filterSourceMap ?: FilterSourceMap(this).also {
            filterNode.filterSourceMap = it
        }

        results.reInitWith(sourceBitmap)

        var lastResult: Bitmap? = sourceBitmap
        val primitiveUnitsAreUser = filter.primitiveUnitsAreUser != false
        val primitiveScaleX = if (primitiveUnitsAreUser) sx else originalObjBBox.width * sx
        val primitiveScaleY = if (primitiveUnitsAreUser) sy else originalObjBBox.height * sy
        val primitiveOriginX = if (primitiveUnitsAreUser) 0f else originalObjBBox.minX
        val primitiveOriginY = if (primitiveUnitsAreUser) 0f else originalObjBBox.minY

        filterNode.primitives.forEachElement { primitiveNode ->
            val child = primitiveNode.sourceElement

            val res = rectFPool.withPooledObject { primitiveRegion ->
                calculatePrimitiveRegion(
                    primitive = child,
                    filterRegion = region,
                    unitsAreUser = primitiveUnitsAreUser,
                    originalObjBBox = originalObjBBox,
                    outRect = primitiveRegion
                )

                when (primitiveNode) {
                    is FeMergeRenderNode -> doFeMergeFilter(
                        merge = primitiveNode,
                        results = results,
                        lastResult = lastResult,
                        region = primitiveRegion
                    )

                    else -> applyPrimitive(
                        canvas = canvas,
                        primitiveNode = primitiveNode,
                        results = results,
                        lastResult = lastResult,
                        primitiveScaleX = primitiveScaleX,
                        primitiveScaleY = primitiveScaleY,
                        primitiveOriginX = primitiveOriginX,
                        primitiveOriginY = primitiveOriginY,
                        canvasScaleX = sx,
                        canvasScaleY = sy,
                        primitiveUnitsAreUser = primitiveUnitsAreUser,
                        region = region,
                        primitiveRegion = primitiveRegion,
                    )
                }
            }

            if (res != null) {
                results.set(child.result, res)
                lastResult = res
            }
        }

        results.recycle(exclude = lastResult)
        return lastResult
    }

    private fun applyPrimitive(
        canvas: Canvas,
        primitiveNode: FilterPrimitiveRenderNode<*>,
        results: FilterSourceMap,
        lastResult: Bitmap?,
        primitiveScaleX: Float,
        primitiveScaleY: Float,
        primitiveOriginX: Float,
        primitiveOriginY: Float,
        canvasScaleX: Float,
        canvasScaleY: Float,
        primitiveUnitsAreUser: Boolean,
        region: RectF,
        primitiveRegion: RectF,
    ): Bitmap? {
        val primitive = primitiveNode.sourceElement
        val input = getFilterInput(
            name = primitive.`in`,
            results = results,
            lastResult = lastResult
        )

        val inputBitmap = input ?: return null

        return when (primitiveNode) {

            is FeTurbulenceRenderNode -> doFeTurbulenceFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                primitiveOriginX = primitiveOriginX,
                primitiveOriginY = primitiveOriginY,
                regionLeft = region.left,
                regionTop = region.top,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeOffsetRenderNode -> doFeOffsetFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveUnitsAreUser = primitiveUnitsAreUser,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeConvolveMatrixRenderNode -> doFeConvolveMatrixFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
            )

            is FeMorphologyRenderNode -> doFeMorphologyFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeComponentTransferRenderNode -> doFeComponentTransferFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeCompositeRenderNode -> doFeCompositeFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                results = results,
                lastResult = lastResult,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeDisplacementMapRenderNode -> doFeDisplacementMapFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                results = results,
                lastResult = lastResult,
            )

            is FeDiffuseLightingRenderNode -> doFeDiffuseLightingFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                primitiveOriginX = primitiveOriginX,
                primitiveOriginY = primitiveOriginY,
                regionLeft = region.left,
                regionTop = region.top,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeSpecularLightingRenderNode -> doFeSpecularLightingFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                primitiveOriginX = primitiveOriginX,
                primitiveOriginY = primitiveOriginY,
                regionLeft = region.left,
                regionTop = region.top,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeColorMatrixRenderNode -> doFeColorMatrixFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeGaussianBlurRenderNode -> doFeGaussianBlurFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeImageRenderNode -> doFeImageFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
            )

            is FeFloodRenderNode -> doFeFloodFilter(
                canvas = canvas,
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            is FeBlendRenderNode -> doFeBlendFilter(
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                results = results,
                lastResult = lastResult,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeTileRenderNode -> doFeTileFilter(
                inputBitmap = inputBitmap,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
            )

            is FeDropShadowRenderNode -> doFeDropShadowFilter(
                canvas = canvas,
                primitiveNode = primitiveNode,
                inputBitmap = inputBitmap,
                results = results,
                lastResult = lastResult,
                primitiveUnitsAreUser = primitiveUnitsAreUser,
                primitiveScaleX = primitiveScaleX,
                primitiveScaleY = primitiveScaleY,
                canvasScaleX = canvasScaleX,
                canvasScaleY = canvasScaleY,
                primitiveRegion = primitiveRegion,
                filterRegion = region,
            )

            else -> {
                canvasPool.withPooledObject { c ->
                    val res = bitmapPool.acquireSameAs(input)
                    c.setBitmap(res)
                    c.drawBitmap(input, 0f, 0f, null)
                    res
                }
            }
        }
    }

    internal fun doFeFloodFilter(
        canvas: Canvas,
        primitiveNode: FeFloodRenderNode,
        inputBitmap: Bitmap,
        primitiveRegion: RectF,
        filterRegion: RectF,
    ): Bitmap {
        val color = withNewState(canvas) { state ->
            styleBuilderPool.withPooledObject { builder ->
                builder.reset(state.style)
                updateStyleForElement(state, builder, primitiveNode.sourceElement, primitiveNode.animationNodes)
                val floodColor = builder.floodColor
                val floodOpacity = builder.floodOpacity
                val colorInt = when (floodColor) {
                    is ColorValue -> floodColor.value
                    is CurrentColor -> builder.color?.value ?: COLOR_BLACK
                    else -> COLOR_BLACK
                }
                val alpha = clamp255(floodOpacity * 255f)
                if (alpha == 0) 0 else colorInt.withAlpha(alpha)
            }
        }

        val res = bitmapPool.acquireSameAs(inputBitmap)
        canvasPool.withPooledObject { c ->
            c.setBitmap(res)
            val clipLeft = (primitiveRegion.left - filterRegion.left)
            val clipTop = (primitiveRegion.top - filterRegion.top)
            val clipRight = (primitiveRegion.right - filterRegion.left)
            val clipBottom = (primitiveRegion.bottom - filterRegion.top)
            
            saveLayerPaint.reset()
            saveLayerPaint.color = color
            c.drawRect(clipLeft, clipTop, clipRight, clipBottom, saveLayerPaint)
        }
        return res
    }

    internal fun doFeDropShadowFilter(
        canvas: Canvas,
        primitiveNode: FeDropShadowRenderNode,
        inputBitmap: Bitmap,
        results: FilterSourceMap,
        lastResult: Bitmap?,
        primitiveUnitsAreUser: Boolean,
        primitiveScaleX: Float,
        primitiveScaleY: Float,
        canvasScaleX: Float,
        canvasScaleY: Float,
        primitiveRegion: RectF,
        filterRegion: RectF,
    ): Bitmap {
        val primitive = primitiveNode.sourceElement

        // The shadow silhouette is derived from the input's alpha.
        val sourceAlpha = getFilterInput("SourceAlpha", results, lastResult)
            ?: getFilterInput(primitive.`in`, results, lastResult)
            ?: return inputBitmap

        // 1. Blur the silhouette.
        val blurred = doFeGaussianBlurFilter(
            primitiveNode = primitiveNode.blurNode,
            inputBitmap = sourceAlpha,
            primitiveScaleX = primitiveScaleX,
            primitiveScaleY = primitiveScaleY,
            primitiveRegion = primitiveRegion,
            filterRegion = filterRegion,
            canvasScaleX = canvasScaleX,
            canvasScaleY = canvasScaleY,
        )

        // 2. Offset the blurred silhouette by dx, dy.
        val offset = doFeOffsetFilter(
            primitiveNode = primitiveNode.offsetNode,
            inputBitmap = blurred,
            primitiveUnitsAreUser = primitiveUnitsAreUser,
            primitiveScaleX = primitiveScaleX,
            primitiveScaleY = primitiveScaleY,
            canvasScaleX = canvasScaleX,
            canvasScaleY = canvasScaleY,
            primitiveRegion = primitiveRegion,
            filterRegion = filterRegion,
        )

        // 3. Resolve the flood color/opacity from the element's style.
        val floodColorInt = withNewState(canvas = canvas) { state ->
            styleBuilderPool.withPooledObject { builder ->
                builder.reset(state.style)
                updateStyleForElement(state, builder, primitive, primitiveNode.animationNodes)
                val floodColor = builder.floodColor
                val floodOpacity = builder.floodOpacity
                val colorInt = when (floodColor) {
                    is ColorValue -> floodColor.value
                    is CurrentColor -> builder.color?.value ?: COLOR_BLACK
                    else -> COLOR_BLACK
                }
                val alpha = clamp255(floodOpacity * 255f)
                if (alpha == 0) 0 else colorInt.withAlpha(alpha)
            }
        }

        // 4. Color the offset silhouette with the flood color.
        val shadow = bitmapPool.acquireSameAs(inputBitmap)
        canvasPool.withPooledObject { c ->
            c.setBitmap(shadow)
            c.drawColor(floodColorInt, PorterDuff.Mode.SRC)
            c.drawBitmap(offset, 0f, 0f, primitiveNode.shadowPaint)
        }

        // 5. Composite the original graphic on top of the shadow.
        val res = bitmapPool.acquireSameAs(inputBitmap)
        canvasPool.withPooledObject { c ->
            c.setBitmap(res)
            c.drawBitmap(shadow, 0f, 0f, null)
            c.drawBitmap(inputBitmap, 0f, 0f, null)
        }
        return res
    }

    private fun requiresCompositing(node: RenderNode<*>): Boolean {
        val style = state.style
        return style.opacity < 1.0f || node.maskNode != null || node.filterNode != null || style.isolation == Isolation.isolate || style.hasMixBlendMode()
    }

    private fun Style.hasMixBlendMode(): Boolean {
        val mixBlendMode = mixBlendMode
        return if (mixBlendMode != null && mixBlendMode != CSSBlendMode.normal) {
            val compat = mixBlendMode.toBlendModeCompat()
            compat != null && isBlendModeSupported(compat)
        } else {
            false
        }
    }

    private fun display(): Boolean {
        return state.style.display ?: true
    }

    private fun visible(): Boolean {
        return state.style.visibility ?: true
    }

    /*
    * Updates the global style state with the style defined by the current object.
    * Will also update the current paints etc. where appropriate.
    */
    private fun updateStyle(state: RendererState, builder: Style.Builder, sourceStyle: Style) {
        val resolvedFontWeight = if (sourceStyle.isSpecified(Style.SPECIFIED_FONT_WEIGHT)) {
            // Font weights are 0..1000
            // Relative weight rules from CSS-Fonts-4: https://www.w3.org/TR/css-fonts-4/#relative-weights
            when (sourceStyle.fontWeight) {
                Style.FONT_WEIGHT_LIGHTER -> {
                    val fw = builder.fontWeight
                    when {
                        fw in 100f..<550f -> 100f
                        fw in 550f..<750f -> 400f
                        fw >= 750f -> 700f
                        else -> fw
                    }
                }

                Style.FONT_WEIGHT_BOLDER -> {
                    val fw = builder.fontWeight
                    when {
                        fw < 350f -> 400f
                        fw in 350f..<550f -> 700f
                        fw in 550f..<900f -> 900f
                        else -> fw
                    }
                }

                else -> sourceStyle.fontWeight
            }
        } else {
            Float.NaN
        }
        updateStyle(state, builder, sourceStyle, this.currentFontSize, resolvedFontWeight)
    }

    private fun setClipRect(canvas: Canvas, box: Box) {
        setClipRect(canvas,
            minX = box.minX,
            minY = box.minY,
            width = box.width,
            height = box.height
        )
    }

    private fun setClipRect(canvas: Canvas, minX: Float, minY: Float, width: Float, height: Float) {
        var left = minX
        var top = minY
        var right = minX + width
        var bottom = minY + height

        val clip = state.style.clip
        if (clip != null) {
            left += clip.left.floatValueXInContext()
            top += clip.top.floatValueYInContext()
            right -= clip.right.floatValueXInContext()
            bottom -= clip.bottom.floatValueYInContext()
        }

        canvas.clipRect(left, top, right, bottom)
    }

    /*
    * Viewport fill color. A new feature in SVG 1.2.
    */
    private fun viewportFill(canvas: Canvas) {
        val style = state.style

        var col: Int = when (val viewportFill = style.viewportFill) {
            is ColorValue -> {
                viewportFill.value
            }

            is CurrentColor -> {
                style.color!!.value
            }

            else -> {
                return
            }
        }

        val viewportFillOpacity = style.viewportFillOpacity
        if (!viewportFillOpacity.isNaN()) {
            col = col.colorWithOpacity(viewportFillOpacity)
        }

        canvas.drawColor(col)
    }

    private fun renderMarkers(canvas: Canvas, node: PathRenderNode) {
        val obj = node.sourceElement

        val markerStartNode = node.markerStartNode
        val midMarkerNode = node.markerMidNode
        val markerEndNode = node.markerEndNode
        if (markerStartNode == null && midMarkerNode == null && markerEndNode == null) {
            return
        }

        val markers = when (obj) {
            is PathShape -> node.markers
            is LineShape -> calculateMarkerPositions(obj)
            else -> {
                // PolyLine and Polygon
                calculateMarkerPositions(obj as PolyLineShape)
            }
        }

        if (markers == null) return

        val markerCount = markers.size
        if (markerCount == 0) return

        if (markerStartNode != null) {
            renderMarker(canvas, markerStartNode, markers[0], isStartMarker = true)
        }

        if (midMarkerNode != null && markers.size > 2) {
            var lastPos = markers[0]
            var thisPos = markers[1]

            for (i in 1..<markerCount - 1) {
                val nextPos = markers[i + 1]
                if (thisPos.isAmbiguous) {
                    thisPos = realignMarkerMid(lastPos, thisPos, nextPos)
                }
                renderMarker(canvas, midMarkerNode, thisPos, isStartMarker = false)
                lastPos = thisPos
                thisPos = nextPos
            }
        }

        if (markerEndNode != null) {
            renderMarker(canvas, markerEndNode, markers[markerCount - 1], isStartMarker = false)
        }
    }

    /*
    * Render the given marker type at the given position
    */
    private fun renderMarker(canvas: Canvas, markerNode: MarkerRenderNode, pos: MarkerVector, isStartMarker: Boolean) {
        val marker = markerNode.sourceElement
        val oldState = state
        val savedCount = canvas.save()
        val newState = renderStatePool.pull()
        newState.apply(markerNode.renderState)
        state = newState
        stateStack.push(newSavedRendererState(oldState, savedCount))

        try {
            matrixPool.withPooledObject { m ->
                var angle = 0f

                // Calculate vector angle
                when (val orient = marker.orient) {
                    is MarkerOrient.Auto -> {
                        if (pos.dx != 0f || pos.dy != 0f) {
                            angle = angleFromTangent(pos.dx, pos.dy)
                        }
                    }

                    is MarkerOrient.AutoStartReverse -> {
                        if (pos.dx != 0f || pos.dy != 0f) {
                            angle = angleFromTangent(pos.dx, pos.dy)
                            if (isStartMarker) {
                                angle += 180f
                            }
                        }
                    }

                    is MarkerOrient.Angle -> angle = orient.degrees
                    null -> {}
                }
                // Calculate unit scale
                val unitsScale: Float = if (marker.markerUnitsAreUser) {
                    1f
                } else {
                    oldState.style.strokeWidth!!.floatValue(dPI)
                }

                m.preTranslate(pos.x, pos.y)
                m.preRotate(angle)
                m.preScale(unitsScale, unitsScale)
                // Scale and/or translate the marker to fit in the marker viewPort
                val _refX = marker.refX?.floatValueXInContext() ?: 0f
                val _refY = marker.refY?.floatValueYInContext() ?: 0f
                val _markerWidth = marker.markerWidth?.floatValueXInContext() ?: 3f
                val _markerHeight = marker.markerHeight?.floatValueYInContext() ?: 3f

                val viewBox = marker.viewBox
                if (viewBox != null) {
                    // We now do a simplified version of calculateViewBoxTransform().  For now, we will
                    // ignore the alignment setting because refX and refY have to be aligned with the
                    // marker position, and alignment would complicate the calculations.
                    var xScale: Float
                    var yScale: Float

                    xScale = _markerWidth / viewBox.width
                    yScale = _markerHeight / viewBox.height

                    // If we are keeping aspect ratio, then set both scales to the appropriate value depending on 'slice'
                    val positioning: PreserveAspectRatio =
                        marker.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX
                    if (positioning != PreserveAspectRatio.STRETCH) {
                        val aspectScale = if (positioning.scale == PreserveAspectRatio.Scale.slice) {
                            max(
                                xScale,
                                yScale
                            )
                        } else {
                            min(xScale, yScale)
                        }
                        yScale = aspectScale
                        xScale = yScale
                    }

                    //m.preTranslate(viewPort.minX, viewPort.minY);
                    m.preTranslate(-_refX * xScale, -_refY * yScale)
                    canvas.concat(m)

                    // Now we need to take account of alignment setting, because it affects the
                    // size and position of the clip rectangle.
                    val imageW = viewBox.width * xScale
                    val imageH = viewBox.height * yScale
                    var xOffset = 0f
                    var yOffset = 0f
                    when (positioning.alignment) {
                        PreserveAspectRatio.Alignment.xMidYMin,
                        PreserveAspectRatio.Alignment.xMidYMid,
                        PreserveAspectRatio.Alignment.xMidYMax -> xOffset -= (_markerWidth - imageW) / 2
                        PreserveAspectRatio.Alignment.xMaxYMin,
                        PreserveAspectRatio.Alignment.xMaxYMid,
                        PreserveAspectRatio.Alignment.xMaxYMax -> xOffset -= _markerWidth - imageW
                        else -> {}
                    }
                    // Determine final Y position
                    when (positioning.alignment) {
                        PreserveAspectRatio.Alignment.xMinYMid,
                        PreserveAspectRatio.Alignment.xMidYMid,
                        PreserveAspectRatio.Alignment.xMaxYMid -> yOffset -= (_markerHeight - imageH) / 2
                        PreserveAspectRatio.Alignment.xMinYMax,
                        PreserveAspectRatio.Alignment.xMidYMax,
                        PreserveAspectRatio.Alignment.xMaxYMax -> yOffset -= _markerHeight - imageH
                        else -> {}
                    }

                    if (!state.style.overflow!!) {
                        setClipRect(canvas, xOffset, yOffset, _markerWidth, _markerHeight)
                    }

                    m.reset()
                    m.preScale(xScale, yScale)
                    canvas.concat(m)
                } else {
                    // No viewBox provided

                    m.preTranslate(-_refX, -_refY)
                    canvas.concat(m)

                    if (!state.style.overflow!!) {
                        setClipRect(canvas, 0f, 0f, _markerWidth, _markerHeight)
                    }
                }
            }

            withNewRenderLayer(canvas, markerNode) { canvas, _ ->
                // context-stroke / context-fill resolve to the paint of the element
                // that references this marker.
                state.contextStroke = oldState.style.stroke
                state.contextFill = oldState.style.fill
                markerNode.children.forEachElement { it.render(this@Renderer, canvas) }
            }
        } finally {
            statePop(canvas)
        }
    }

    private fun findInheritFromAncestorState(
        obj: SvgObject,
        animationNodes: List<List<AnimationNode>?>?
    ): RendererState {
        val newState = renderStatePool.pull()
        obj.styleBuilder.also { builder ->
            builder.reset(Style.getDefaultStyle())
            updateStyle(newState, builder, Style.getDefaultStyle())
            newState.style = builder.build()
        }
        return findInheritFromAncestorState(obj, newState, animationNodes)
    }

    private val tempAncestors: ArrayList<ElementBase> = ArrayList()
    private fun findInheritFromAncestorState(
        obj: SvgObject,
        newState: RendererState,
        animationNodes: List<List<AnimationNode>?>?
    ): RendererState {
        var obj: SvgObject = obj
        val ancestors: ArrayList<ElementBase> = tempAncestors
        ancestors.clear()

        // Traverse up the document tree adding element styles to a list.
        while (true) {
            if (obj is ElementBase) {
                ancestors.add(0, obj)
            }
            obj = obj.parent ?: break
        }


        // Now apply the ancestor styles in reverse order to a fresh RendererState object
        obj.styleBuilder.also { builder ->
            builder.reset(newState.style)
            for (i in ancestors.indices) {
                updateStyleForElement(newState, builder, ancestors[i], animationNodes?.get(i))
            }
            newState.style = builder.build()
        }

        // Caller may also need a valid viewBox to calculate percentages
        val oldState = state
        newState.viewBox = oldState.viewBox
        newState.viewPort = oldState.viewPort
        return newState
    }

    //==============================================================================
    // Gradients
    //==============================================================================
    /*
    * Check for gradient fills or strokes on this object.  These are always relative
    * to the object, so can't be preconfigured. They have to be initialized at the
    * time each object is rendered.
    */
    private fun checkForGradientsAndPatterns(canvas: Canvas, node: RenderNode<*>, obj: Element) {
        val boundingBox = obj.boundingBox ?: return

        node.fillPaintRef?.let { applyPaint(canvas, true, boundingBox, it) }
        node.strokePaintRef?.let { applyPaint(canvas, false, boundingBox, it) }
    }

    /*
    * Applies a build-time-resolved paint reference (gradient or solid color) to the fill/stroke paint.
    * The paint reference itself was resolved when building the render tree; only the shader (and other
    * state-dependent parts) are constructed here, at render time.
    */
    private fun applyPaint(
        canvas: Canvas,
        isFill: Boolean,
        boundingBox: Box,
        resolved: ResolvedPaint
    ) {
        when (resolved) {
            is ResolvedPaint.Solid -> setSolidColor(state, isFill, resolved.ref)

            is ResolvedPaint.Linear -> makeLinearGradient(canvas, isFill, boundingBox, resolved)

            is ResolvedPaint.Radial -> makeRadialGradient(canvas, isFill, boundingBox, resolved)

            is ResolvedPaint.Missing -> {
                val paintRef = (if (isFill) state.style.fill else state.style.stroke) as? PaintReference
                applyMissingPaint(state, isFill, paintRef)
            }
        }
    }

    /*
     * Resolves a paint reference (url(#id)) whose href could not be resolved while building the render tree.
     * The fallback color lives on the still-present PaintReference in `state.style`, so either apply it or,
     * when there is none, disable the fill/stroke entirely (per SVG, a missing paint with no fallback is not painted).
     */
    private fun applyMissingPaint(state: RendererState, isFill: Boolean, paintRef: PaintReference?) {
        val fallback = paintRef?.fallback
        if (fallback != null) {
            styleBuilderPool.withPooledObject { builder ->
                builder.reset(state.style)
                if (isFill) {
                    setFillPaintColor(state, builder, fallback)
                } else {
                    setStrokePaintColor(state, builder, fallback)
                }
            }
        } else if (isFill) {
            state.hasFill = false
        } else {
            state.hasStroke = false
        }
    }

    private fun makeLinearGradient(
        canvas: Canvas,
        isFill: Boolean,
        boundingBox: Box,
        resolved: ResolvedPaint.Linear
    ) {
        val gradient = resolved.gradient
        val userUnits = gradient.gradientUnitsAreUser == true
        val paint = if (isFill) {
            state.fillPaint
        } else {
            state.strokePaint
        }
        val paintOpacity = if (isFill) {
            if (state.style.fillOpacity.isNaN()) 1f else state.style.fillOpacity
        } else {
            if (state.style.strokeOpacity.isNaN()) 1f else state.style.strokeOpacity
        }

        val _x1: Float
        val _y1: Float
        val _x2: Float
        val _y2: Float
        if (userUnits) {
            _x1 = gradient.x1?.floatValueXInContext() ?: 0f
            _y1 = gradient.y1?.floatValueYInContext() ?: 0f
            _x2 = gradient.x2?.floatValueXInContext()
                ?: CSSLength.PERCENT_100.floatValueXInContext() // default is 1.0/100%
            _y2 = gradient.y2?.floatValueYInContext() ?: 0f
        } else {
            _x1 = gradient.x1?.floatValueInContext(1f) ?: 0f
            _y1 = gradient.y1?.floatValueInContext(1f) ?: 0f
            _x2 = gradient.x2?.floatValueInContext(1f) ?: 1f // default is 1.0/100%
            _y2 = gradient.y2?.floatValueInContext(1f) ?: 0f
        }

        // Push the state
        statePush(canvas)

        try {
            // Set the style for the gradient (inherits from its own ancestors, not from callee's state)
            switchState(findInheritFromAncestorState(gradient, resolved.ancestorAnimationNodes))

            matrixPool.withPooledObject { m ->
                // Calculate the gradient transform matrix
                if (!userUnits) {
                    m.preTranslate(boundingBox.minX, boundingBox.minY)
                    m.preScale(boundingBox.width, boundingBox.height)
                }

                gradient.gradientTransform?.let {
                    m.preConcat(it)
                }

                // Create the color and position arrays for the shader
                val stopNodes = checkNotNull(resolved.stopNodes)
                val numStops = stopNodes.size
                if (numStops == 0) {
                    // If there are no stops defined, we are to treat it as paint = 'none' (see spec 13.2.4)
                    if (isFill) {
                        state.hasFill = false
                    } else {
                        state.hasStroke = false
                    }
                    return
                }

                if (resolved.colors.size != numStops) {
                    resolved.colors = IntArray(numStops)
                    resolved.positions = FloatArray(numStops)
                }
                val colors = resolved.colors
                colors.fill(0)
                val positions = resolved.positions
                positions.fill(0f)

                var lastOffset = -1f
                for (i in 0 until numStops) {
                    val stopNode = stopNodes[i]
                    val stop = stopNode.sourceElement
                    val offset: Float = stop.offset
                    if (i == 0 || offset >= lastOffset) {
                        positions[i] = offset
                        lastOffset = offset
                    } else {
                        // Each offset must be equal or greater than the last one.
                        // If it doesn't, we need to replace it with the previous value.
                        positions[i] = lastOffset
                    }

                    withNewState(canvas) { state ->
                        stop.styleBuilder.also { builder ->
                            builder.reset(state.style)
                            updateStyleForElement(state, builder, stop, stopNode.animationNodes)
                            val style = builder.build()
                            state.style = style
                            val col = style.stopColor as ColorValue? ?: ColorValue.BLACK
                            colors[i] = col.value.colorWithOpacity(style.stopOpacity)
                        }
                    }
                }

                // If gradient vector is zero length, we instead fill with last stop color
                if (_x1 == _x2 && _y1 == _y2 || numStops == 1) {
                    paint.setColor(colors[numStops - 1])
                    return
                }

                // Convert spreadMethod->TileMode
                val tileMode: TileMode = when (gradient.spreadMethod) {
                    GradientSpread.reflect -> TileMode.MIRROR
                    GradientSpread.repeat -> TileMode.REPEAT
                    else -> TileMode.CLAMP
                }

                // Create shader instance
                val prevGradient = resolved.shader
                val gr = if (
                    resolved.updateGeometry(_x1, _y1, _x2, _y2, tileMode) ||
                    prevGradient == null ||
                    resolved.colorsChanged()
                ) {
                    LinearGradient(_x1, _y1, _x2, _y2, colors, positions, tileMode).also {
                        resolved.shader = it
                        resolved.markColorsClean()
                    }
                } else {
                    prevGradient
                }
                gr.setLocalMatrix(m)
                paint.setShader(gr)
                paint.alpha = clamp255(paintOpacity * 255f)
            }
        } finally {
            statePop(canvas)
        }
    }

    private fun makeRadialGradient(
        canvas: Canvas,
        isFill: Boolean,
        boundingBox: Box,
        resolved: ResolvedPaint.Radial
    ) {
        val gradient = resolved.gradient
        val userUnits = gradient.gradientUnitsAreUser == true
        val paint = if (isFill) {
            state.fillPaint
        } else {
            state.strokePaint
        }
        val paintOpacity = if (isFill) {
            if (state.style.fillOpacity.isNaN()) 1f else state.style.fillOpacity
        } else {
            if (state.style.strokeOpacity.isNaN()) 1f else state.style.strokeOpacity
        }

        val _cx: Float
        val _cy: Float
        val _r: Float
        var _fx = 0f
        var _fy = 0f
        var _fr = 0f
        if (userUnits) {
            _cx = gradient.cx?.floatValueXInContext() ?: CSSLength.PERCENT_50.floatValueXInContext()
            _cy = gradient.cy?.floatValueYInContext() ?: CSSLength.PERCENT_50.floatValueYInContext()
            _r = gradient.r?.floatValueInContext() ?: CSSLength.PERCENT_50.floatValueInContext()

            if (SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS) {
                _fx = gradient.fx?.floatValueXInContext() ?: _cx
                _fy = gradient.fy?.floatValueYInContext() ?: _cy
                _fr = gradient.fr?.floatValueInContext() ?: 0f
            }
        } else {
            _cx = gradient.cx?.floatValueInContext(1f) ?: 0.5f
            _cy = gradient.cy?.floatValueInContext(1f) ?: 0.5f
            _r = gradient.r?.floatValueInContext(1f) ?: 0.5f

            if (SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS) {
                // Per spec, fx/fy default to the gradient center (not 0.5), even in
                // objectBoundingBox mode where cx/cy may have explicit non-default values.
                _fx = gradient.fx?.floatValueInContext(1f) ?: _cx
                _fy = gradient.fy?.floatValueInContext(1f) ?: _cy
                _fr = gradient.fr?.floatValueInContext(1f) ?: 0f
            }
        }

        // fx and fy are ignored because Android RadialGradient doesn't support a
        // 'focus' point that is different from cx,cy.

        // Push the state
        statePush(canvas)

        try {
            // Set the style for the gradient (inherits from its own ancestors, not from callee's state)
            switchState(findInheritFromAncestorState(gradient, resolved.ancestorAnimationNodes))

            matrixPool.withPooledObject { m ->
                // Calculate the gradient transform matrix
                if (!userUnits) {
                    m.preTranslate(boundingBox.minX, boundingBox.minY)
                    m.preScale(boundingBox.width, boundingBox.height)
                }

                gradient.gradientTransform?.let {
                    m.preConcat(it)
                }

                // Create the color and position arrays for the shader
                val stopNodes = resolved.stopNodes
                val numStops = stopNodes.size
                if (numStops == 0) {
                    // If there are no stops defined, we are to treat it as paint = 'none' (see spec 13.2.4)
                    if (isFill) {
                        state.hasFill = false
                    } else {
                        state.hasStroke = false
                    }
                    return
                }

                if (resolved.colors == null || resolved.colors!!.size != numStops) {
                    resolved.colors = if (SUPPORTS_RADIAL_GRADIENT_WITH_FOCUS) {
                        GradientColorArray.Longs(LongArray(numStops))
                    } else {
                        GradientColorArray.Ints(IntArray(numStops))
                    }
                    resolved.positions = FloatArray(numStops)
                }
                val colors = resolved.colors!!
                val positions = resolved.positions
                var lastOffset = -1f
                for (i in 0 until numStops) {
                    val stopNode = stopNodes[i]
                    val stop = stopNode.sourceElement
                    val offset: Float = stop.offset
                    if (i == 0 || offset >= lastOffset) {
                        positions[i] = offset
                        lastOffset = offset
                    } else {
                        // Each offset must be equal or greater than the last one.
                        // If it doesn't, we need to replace it with the previous value.
                        positions[i] = lastOffset
                    }

                    withNewState(canvas) { st5 ->
                        styleBuilderPool.withPooledObject { builder ->
                            builder.reset(st5.style)
                            updateStyleForElement(st5, builder, stop, stopNode.animationNodes)
                            val style = builder.build()
                            st5.style = style
                            val col = style.stopColor as ColorValue? ?: ColorValue.BLACK
                            colors[i] = col.value.colorWithOpacity(style.stopOpacity)
                        }
                    }
                }

                // If gradient radius is zero, we instead fill with last stop color
                if (_r == 0f || numStops == 1) {
                    colors.setOnPaint(paint, numStops - 1)
                    return
                }

                // Convert spreadMethod->TileMode
                val tileMode = when (gradient.spreadMethod) {
                    GradientSpread.reflect -> TileMode.MIRROR
                    GradientSpread.repeat -> TileMode.REPEAT
                    else -> TileMode.CLAMP
                }

                // Create shader instance
                val prevGradient = resolved.shader
                val gr = if (
                    resolved.updateGeometry(_cx, _cy, _r, _fx, _fy, _fr, tileMode) ||
                    prevGradient == null ||
                    resolved.colorsChanged()
                ) {
                    when (colors) {
                        is GradientColorArray.Longs -> {
                            @Suppress("NewApi")
                            RadialGradient(
                                /* startX = */ _fx,
                                /* startY = */ _fy,
                                /* startRadius = */ _fr,
                                /* endX = */ _cx,
                                /* endY = */ _cy,
                                /* endRadius = */ _r,
                                /* colors = */ colors.array,
                                /* stops = */ positions,
                                /* tileMode = */ tileMode
                            )
                        }

                        is GradientColorArray.Ints -> {
                            RadialGradient(
                                /* centerX = */ _cx,
                                /* centerY = */ _cy,
                                /* radius = */ _r,
                                /* colors = */ colors.array,
                                /* stops = */ positions,
                                /* tileMode = */ tileMode
                            )
                        }
                    }.also {
                        resolved.shader = it
                        resolved.markColorsClean()
                    }
                } else {
                    prevGradient
                }
                gr.setLocalMatrix(m)
                paint.setShader(gr)
                paint.alpha = clamp255(paintOpacity * 255f)
            }
        } finally {
            statePop(canvas)
        }
    }

    //==============================================================================
    // Clip paths
    //==============================================================================

    /**
     * Returns true if the drawing operation is not fully clipped out
     */
    private fun checkForClipPath(node: RenderNode<*>, canvas: Canvas): Boolean {
        return node.clipPathNode == null || pathPool.withPooledObject { combinedPath ->
            if (calculateClipPath(node, combinedPath)) {
                canvas.clipPath(combinedPath)
                !combinedPath.isEmpty
            } else {
                true
            }
        }
    }

    private fun calculateClipPath(node: RenderNode<*>, combinedPath: Path): Boolean {
        val clipPathNode = node.clipPathNode ?: return false

        var first = true
        clipPathNode.children.forEachElement { childNode ->
            pathPool.withPooledObject { part ->
                if (nodeToPath(childNode, part)) {
                    childNode.clipPathNode?.let {
                        pathPool.withPooledObject { nested ->
                            if (calculateClipPath(childNode, nested)) {
                                part.op(nested, Path.Op.INTERSECT)
                            }
                        }
                    }
                    if (first) {
                        combinedPath.set(part)
                        first = false
                    } else {
                        combinedPath.op(part, Path.Op.UNION)
                    }
                }
            }
        }

        if (first) {
            return true
        }

        val clipPath = clipPathNode.sourceElement
        val boundingBox = node.boundingBox

        val clipPathUnitsAreUser = clipPath.clipPathUnitsAreUser != false
        if (!clipPathUnitsAreUser && boundingBox != null) {
            matrixPool.withPooledObject { m ->
                m.reset()
                m.preTranslate(boundingBox.minX, boundingBox.minY)
                m.preScale(boundingBox.width, boundingBox.height)
                clipPath.transform?.let { m.preConcat(it) }
                combinedPath.transform(m)
            }
        } else {
            clipPath.transform?.let { combinedPath.transform(it) }
        }

        // Recursive call for nested clip-path on the clipPath element itself
        if (clipPathNode.clipPathNode != null) {
            pathPool.withPooledObject { nestedPath ->
                if (calculateClipPath(clipPathNode, nestedPath)) {
                    combinedPath.op(nestedPath, Path.Op.INTERSECT)
                }
            }
        }

        combinedPath.fillType = clipPathNode.renderState.clipFillType
        return true
    }

    private fun nodeToPath(node: RenderNode<*>, outPath: Path): Boolean {
        return when (node) {
            is PathRenderNode -> {
                outPath.set(node.path)
                node.transform?.let { outPath.transform(it) }
                true
            }

            is GroupRenderNode -> {
                var first = true
                node.children.forEachElement { childNode ->
                    pathPool.withPooledObject { part ->
                        if (nodeToPath(childNode, part)) {
                            if (first) {
                                outPath.set(part)
                                first = false
                            } else {
                                outPath.op(part, Path.Op.UNION)
                            }
                        }
                    }
                }
                if (!first) {
                    node.transform?.let { outPath.transform(it) }
                }
                !first
            }

            is TextRenderNode -> {
                val proc = PlainTextToPath(textAsPath = outPath).apply {
                    x = node.x + node.dx
                    y = node.y + node.dy
                }
                calculateTextPath(node.children, proc, node.renderState)
                node.transform?.let { outPath.transform(it) }
                true
            }

            else -> false
        }
    }


    private fun fillWithPattern(
        node: PathRenderNode,
        path: Path,
        patternNode: PatternRenderNode,
        canvas: Canvas,
    ) {
        val obj = node.sourceElement
        val pattern = patternNode.sourceElement
        val patternUnitsAreUser = pattern.patternUnitsAreUser == true
        var x: Float
        var y: Float
        var w: Float
        var h: Float
        val objFillOpacity: Float = state.style.fillOpacity

        if (patternUnitsAreUser) {
            x = pattern.x?.floatValueXInContext() ?: 0f
            y = pattern.y?.floatValueYInContext() ?: 0f
            w = pattern.width?.floatValueXInContext() ?: 0f
            h = pattern.height?.floatValueYInContext() ?: 0f
        } else {
            // Convert objectBoundingBox space to user space
            val boundingBox = obj.boundingBox!!
            x = pattern.x?.floatValueInContext(1f) ?: 0f
            y = pattern.y?.floatValueInContext(1f) ?: 0f
            w = pattern.width?.floatValueInContext(1f) ?: 0f
            h = pattern.height?.floatValueInContext(1f) ?: 0f
            x = boundingBox.minX + x * boundingBox.width
            y = boundingBox.minY + y * boundingBox.height
            w *= boundingBox.width
            h *= boundingBox.height
        }
        if (w == 0f || h == 0f) return

        // \"If attribute 'preserveAspectRatio' is not specified, then the effect is as if a value of xMidYMid meet were specified.\"
        val positioning: PreserveAspectRatio = pattern.preserveAspectRatio ?: PreserveAspectRatio.LETTERBOX

        withNewState(canvas) {
            // Set path as the clip region
            canvas.clipPath(path)

            // Switch to pre-calculated pattern state
            val oldState = state
            val newState = renderStatePool.pull()
            newState.apply(patternNode.renderState)
            if (newState.contextStroke == null) newState.contextStroke = oldState.contextStroke
            if (newState.contextFill == null) newState.contextFill = oldState.contextFill
            state = newState
            reapplyDynamicPaints(state)
            stateStack.push(newSavedRendererState(oldState, -1))

            try {
                // The bounds of the area we need to cover with pattern to ensure that our shape is filled
                val bb = obj.boundingBox!!
                var areaMinX = bb.minX
                var areaMinY = bb.minY
                var areaMaxX = bb.maxX()
                var areaMaxY = bb.maxY()

                // Apply the patternTransform
                val patternTransform = pattern.patternTransform
                if (patternTransform != null) {
                    canvas.concat(patternTransform)

                    // A pattern transform will affect the area we need to cover with the pattern.
                    // So we need to alter the area bounding rectangle.
                    matrixPool.withPooledObject { inverse ->
                        if (patternTransform.invert(inverse)) {
                            rectFPool.withPooledObject { srcRect ->
                                rectFPool.withPooledObject { dstRect ->
                                    srcRect.set(bb.minX, bb.minY, bb.maxX(), bb.maxY())
                                    inverse.mapRect(dstRect, srcRect)
                                    areaMinX = floor(dstRect.left)
                                    areaMinY = floor(dstRect.top)
                                    areaMaxX = ceil(dstRect.right)
                                    areaMaxY = ceil(dstRect.bottom)
                                }
                            }
                        }
                    }
                }

                // Calculate the pattern origin
                val originX = x + floor((areaMinX - x) / w) * w
                val originY = y + floor((areaMinY - y) / h) * h

                // For each Y step, then each X step
                val right = areaMaxX
                val bottom = areaMaxY

                withNewRenderLayer(
                    canvas = canvas,
                    node = patternNode,
                    opacityAdjustment = objFillOpacity
                ) { canvas, _ ->
                    var stepY = originY
                    while (stepY < bottom) {
                        var stepX = originX
                        while (stepX < right) {
                            val minX = stepX
                            val minY = stepY

                            withNewState(canvas) { st6 ->
                                // Set pattern clip rectangle if appropriate
                                if (st6.style.overflow == false && patternNode.hasOverflow) {
                                    setClipRect(canvas, minX, minY, w, h)
                                }
                                // Calculate and set the viewport for each instance of the pattern
                                val viewBox = pattern.viewBox
                                if (viewBox != null) {
                                    matrixPool.withPooledObject { m ->
                                        calculateViewBoxTransform(
                                            viewPortMinX = minX,
                                            viewPortMinY = minY,
                                            viewPortWidth = w,
                                            viewPortHeight = h,
                                            viewBox = viewBox,
                                            positioning = positioning,
                                            outMatrix = m
                                        )
                                        canvas.concat(m)
                                    }
                                } else {
                                    val patternContentUnitsAreUser = pattern.patternContentUnitsAreUser != false
                                    // Simple translate of pattern to step position
                                    canvas.translate(stepX, stepY)
                                    // Add a tiny overlap to avoid anti-aliasing seams between tiles
                                    canvas.scale(1.01f, 1.01f, w / 2f, h / 2f)
                                    if (!patternContentUnitsAreUser) {
                                        val boundingBox = obj.boundingBox!!
                                        canvas.scale(boundingBox.width, boundingBox.height)

                                        // Set the viewport to 1x1 so that percentages are resolved correctly
                                        st6.viewPort = Box._1X1
                                        st6.viewBox = null
                                    }
                                }

                                // Render the pattern node content
                                patternNode.children.forEachElement { it.render(this@Renderer, canvas) }
                            }

                            stepX += w
                        }
                        stepY += h
                    }
                }
            } finally {
                statePop(canvas)
            }
        }
    }

    private fun renderMask(canvas: Canvas, maskNode: MaskRenderNode, node: RenderNode<*>) {
        val mask = maskNode.sourceElement
        val originalObjBBox = node.boundingBox!!
        rectFPool.withPooledObject { maskRegion ->
            calculateRegion(mask, originalObjBBox, maskRegion)
            if (maskRegion.width() <= 0f || maskRegion.height() <= 0f) return

            withNewState(canvas) {
                val oldState = state
                val newState = renderStatePool.pull()
                newState.apply(maskNode.renderState)
                if (newState.contextStroke == null) newState.contextStroke = oldState.contextStroke
                if (newState.contextFill == null) newState.contextFill = oldState.contextFill
                state = newState
                reapplyDynamicPaints(state)
                stateStack.push(newSavedRendererState(oldState, -1))

                try {
                    canvas.withSave {
                        canvas.clipRect(maskRegion)

                        withNewRenderLayer(canvas,node, isMaskContent = true) { canvas, _ ->
                            canvas.withSave {
                                val maskContentUnitsAreUser = mask.maskContentUnitsAreUser != false
                                if (!maskContentUnitsAreUser) {
                                    canvas.translate(originalObjBBox.minX, originalObjBBox.minY)
                                    canvas.scale(originalObjBBox.width, originalObjBBox.height)
                                    state.viewPort = Box._1X1
                                    state.viewBox = null
                                }

                                maskNode.children.forEachElement { it.render(this@Renderer, canvas) }
                            }
                        }
                    }
                } finally {
                    statePop(canvas)
                }
            }
        }
    }

    private fun setSolidColor(state: RendererState, isFill: Boolean, ref: SolidColor) {
        styleBuilderPool.withPooledObject { builder ->
            builder.reset(state.style)
            val baseStyle = ref.baseStyle!!

            // Make a Style object that has fill or stroke color values set depending on the value of isFill.
            if (isFill) {
                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_COLOR)) {
                    val solidColor = baseStyle.solidColor
                    builder.fill = solidColor
                    state.hasFill = solidColor != null
                }

                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_OPACITY)) {
                    builder.fillOpacity = baseStyle.solidOpacity
                }

                // If either fill or its opacity has changed, update the fillPaint
                if (baseStyle.isSpecifiedAny(Style.SPECIFIED_SOLID_COLOR or Style.SPECIFIED_SOLID_OPACITY)) {
                    setFillPaintColor(state, builder, builder.fill)
                }
            } else {
                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_COLOR)) {
                    val solidColor = baseStyle.solidColor
                    builder.stroke = solidColor
                    state.hasStroke = solidColor != null
                }

                if (baseStyle.isSpecified(Style.SPECIFIED_SOLID_OPACITY)) {
                    builder.strokeOpacity = baseStyle.solidOpacity
                }

                // If either fill or its opacity has changed, update the fillPaint
                if (baseStyle.isSpecifiedAny(Style.SPECIFIED_SOLID_COLOR or Style.SPECIFIED_SOLID_OPACITY)) {
                    setStrokePaintColor(state, builder, builder.stroke)
                }
            }
            state.style = builder.build()
        }
    }

    private fun stabilizeDimension(dimension: Int): Int {
        if (dimension <= 0) return 0
        // Round up to the next multiple of 32 to stabilize bitmap allocations during animations
        return (dimension + 31) and 31.inv()
    }

    /**
     * Reusable paint for compositing a filtered bitmap back onto the canvas. Must honour the
     * element's own `opacity` and `mix-blend-mode`, which are otherwise silently dropped when a
     * `filter` is present (see renderWithFilter). Kept per-Renderer-instance (not in the
     * companion object) so it is never shared mutable state across Drawables/threads.
     */
    private val filterCompositePaint: Paint = Paint()

    /**
     * The filtered bitmap is composited back onto the original canvas. This paint must
     * honour the element's own `opacity` and `mix-blend-mode`, otherwise they are silently
     * dropped when a `filter` is present (see renderWithFilter).
     *
     * When neither applies (fully opaque, normal blend) we return `null` so the bitmap is
     * drawn exactly as before, preserving existing rendering/compositing behaviour.
     */
    private fun configureFilterCompositePaint(state: RendererState): Paint? {
        val opacity = if (state.style.opacity.isNaN()) 1f else state.style.opacity
        val alpha = (opacity * 255f).toInt().coerceIn(0, 255)
        val blendMode = state.style.mixBlendMode
        if (alpha >= 255 && (blendMode == null || blendMode == CSSBlendMode.normal)) {
            return null
        }
        filterCompositePaint.alpha = alpha
        setBlendMode(state, filterCompositePaint)
        return filterCompositePaint
    }

    companion object {
        private const val TAG = "Renderer"

        // paint-order component codes (2 bits each) and the six packed orders.
        private const val COMPONENT_FILL = 1
        private const val COMPONENT_STROKE = 2
        private const val COMPONENT_MARKERS = 3
        private const val FILL_STROKE_MARKERS = (COMPONENT_FILL shl 4) or (COMPONENT_STROKE shl 2) or COMPONENT_MARKERS
        private const val STROKE_FILL_MARKERS = (COMPONENT_STROKE shl 4) or (COMPONENT_FILL shl 2) or COMPONENT_MARKERS
        private const val FILL_MARKERS_STROKE = (COMPONENT_FILL shl 4) or (COMPONENT_MARKERS shl 2) or COMPONENT_STROKE
        private const val MARKERS_FILL_STROKE = (COMPONENT_MARKERS shl 4) or (COMPONENT_FILL shl 2) or COMPONENT_STROKE
        private const val STROKE_MARKERS_FILL = (COMPONENT_STROKE shl 4) or (COMPONENT_MARKERS shl 2) or COMPONENT_FILL
        private const val MARKERS_STROKE_FILL = (COMPONENT_MARKERS shl 4) or (COMPONENT_STROKE shl 2) or COMPONENT_FILL

        // The feColorMatrix luminance-to-alpha coefficient. Used for <mask>s.
        // Note we are using the CSS/SVG2 version of the coefficients here, rather than the older SVG1.1 coefficients.
        const val LUMINANCE_TO_ALPHA_RED: Float = 0.2127f
        const val LUMINANCE_TO_ALPHA_GREEN: Float = 0.7151f
        const val LUMINANCE_TO_ALPHA_BLUE: Float = 0.0722f

        private const val DEBUG = false

        private val maskPaintCombined: Paint = Paint().apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
        }

        private val luminanceToAlphaPaint: Paint = Paint().apply {
            val luminanceToAlpha = ColorMatrix(luminanceToAlphaFloatArray)
            setColorFilter(ColorMatrixColorFilter(luminanceToAlpha))
        }

        private val dstInPaint: Paint = Paint().apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN)
        }

        private val bitmapPaint: Paint = Paint(Paint.FILTER_BITMAP_FLAG)
        private val bitmapPaintOptimizeSpeed: Paint = Paint()

        @Suppress("SameParameterValue")
        private fun error(message: String) {
            Log.e(TAG, message)
        }

        private fun error(format: String, vararg args: Any?) {
            Log.e(TAG, String.format(format, *args))
        }

        @Suppress("SimplifyBooleanWithConstants")
        private inline fun debug(lazyMessage: () -> String) {
            if (DEBUG && BuildConfig.DEBUG) {
                Log.d(TAG, lazyMessage.invoke())
            }
        }

        private fun setBlendMode(state: RendererState, paint: Paint) {
            val mixBlendMode = state.style.mixBlendMode ?: CSSBlendMode.normal

            debug {
                "Setting blend mode to $mixBlendMode"
            }

            paint.setBlendModeCompat(mixBlendMode.toBlendModeCompat())
        }

        private fun CSSBlendMode.toBlendModeCompat(): BlendModeCompat? {
            return when (this) {
                CSSBlendMode.multiply -> BlendModeCompat.MULTIPLY
                CSSBlendMode.screen -> BlendModeCompat.SCREEN
                CSSBlendMode.overlay -> BlendModeCompat.OVERLAY
                CSSBlendMode.darken -> BlendModeCompat.DARKEN
                CSSBlendMode.lighten -> BlendModeCompat.LIGHTEN
                CSSBlendMode.color_dodge -> BlendModeCompat.COLOR_DODGE
                CSSBlendMode.color_burn -> BlendModeCompat.COLOR_BURN
                CSSBlendMode.hard_light -> BlendModeCompat.HARD_LIGHT
                CSSBlendMode.soft_light -> BlendModeCompat.SOFT_LIGHT
                CSSBlendMode.difference -> BlendModeCompat.DIFFERENCE
                CSSBlendMode.exclusion -> BlendModeCompat.EXCLUSION
                CSSBlendMode.hue -> BlendModeCompat.HUE
                CSSBlendMode.saturation -> BlendModeCompat.SATURATION
                CSSBlendMode.color -> BlendModeCompat.COLOR
                CSSBlendMode.luminosity -> BlendModeCompat.LUMINOSITY
                else -> null
            }
        }

        /*
        * This was one of the ambiguous markers. Try to see if we can find a better direction for
        * it, now that we have more info available on the neighboring marker positions.
        */
        private fun realignMarkerMid(
            lastPos: MarkerVector,
            thisPos: MarkerVector,
            nextPos: MarkerVector
        ): MarkerVector {
            // Check the temporary marker vector against the incoming vector
            var dot = dotProduct(
                x1 = thisPos.dx,
                y1 = thisPos.dy,
                x2 = thisPos.x - lastPos.x,
                y2 = thisPos.y - lastPos.y
            )
            if (dot == 0f) {
                // Those two were perpendicular, so instead try the outgoing vector
                dot = dotProduct(
                    x1 = thisPos.dx,
                    y1 = thisPos.dy,
                    x2 = nextPos.x - thisPos.x,
                    y2 = nextPos.y - thisPos.y
                )
            }
            if (dot > 0) return thisPos
            if (dot == 0f) {
                // If that was perpendicular also, then give up.
                // Else use the one that points in the same direction as 0deg (1,0) or has non-negative y.
                if (thisPos.dx > 0f || thisPos.dy >= 0) return thisPos
            }
            // Reverse this vector and point the marker in the opposite direction.
            thisPos.dx = -thisPos.dx
            thisPos.dy = -thisPos.dy
            return thisPos
        }

        /*
        * Calculate the dot product of two vectors.
        */
        private fun dotProduct(x1: Float, y1: Float, x2: Float, y2: Float): Float {
            return x1 * x2 + y1 * y2
        }
    }
}
