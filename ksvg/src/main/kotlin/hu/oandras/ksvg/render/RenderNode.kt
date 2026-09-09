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
import android.graphics.Paint
import android.graphics.Path
import hu.oandras.ksvg.compat.XFerModes
import hu.oandras.ksvg.compat.toBlendModeCompat
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.ClipPath
import hu.oandras.ksvg.dom.core.ConditionalContainer
import hu.oandras.ksvg.dom.core.Image
import hu.oandras.ksvg.dom.core.Marker
import hu.oandras.ksvg.dom.core.Mask
import hu.oandras.ksvg.dom.core.Pattern
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.core.Switch
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.filter.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.dom.filter.FeBlend
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeColorMatrix
import hu.oandras.ksvg.dom.filter.FeColorMatrixType
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
import hu.oandras.ksvg.dom.filter.FeMorphology
import hu.oandras.ksvg.dom.filter.FeOffset
import hu.oandras.ksvg.dom.filter.FeSpecularLighting
import hu.oandras.ksvg.dom.filter.FeTile
import hu.oandras.ksvg.dom.filter.FeTurbulence
import hu.oandras.ksvg.dom.filter.Filter
import hu.oandras.ksvg.dom.filter.FilterPrimitive
import hu.oandras.ksvg.dom.gradient.Stop
import hu.oandras.ksvg.dom.shapes.Shape
import hu.oandras.ksvg.dom.style.CSSBlendMode
import hu.oandras.ksvg.dom.style.Isolation
import hu.oandras.ksvg.dom.text.TRef
import hu.oandras.ksvg.dom.text.TSpan
import hu.oandras.ksvg.dom.text.Text
import hu.oandras.ksvg.dom.text.TextContainer
import hu.oandras.ksvg.dom.text.TextPath
import hu.oandras.ksvg.filtering.StackBlurScratch
import hu.oandras.ksvg.filtering.SvgPathNoise
import hu.oandras.ksvg.render.animation.AnimationNode
import hu.oandras.ksvg.render.filters.LightVector
import hu.oandras.ksvg.render.filters.NormalVector
import hu.oandras.ksvg.render.filters.pipeline.FilterPipelineImpl31
import hu.oandras.ksvg.render.filters.pipeline.FilterPrimitiveSet
import hu.oandras.ksvg.render.pool.BitmapPool
import hu.oandras.ksvg.render.pool.FloatArrayBucket
import hu.oandras.ksvg.render.pool.IntArrayBucket
import hu.oandras.ksvg.utils.anyElement
import hu.oandras.ksvg.utils.forEachElement
import kotlin.math.abs
import kotlin.math.max

internal sealed class RenderNode<T: SvgObject>(
    @JvmField val sourceElement: T
) {
    @JvmField var transform: Matrix? = null
    // Base transform, for instance, nodes whose transform is composed during tree building.
    @JvmField var animationBaseTransform: Matrix? = null
    // ViewBox -> viewport fit transform (e.g., for the root <svg>, <image>, nested <svg>).
    // Kept separate from [transform] because updateAnimations() re-derives [transform] from the
    // element each frame and must not clobber the fit.
    @JvmField var viewBoxTransform: Matrix? = null
    @JvmField var opacity: Float = 1f
    @JvmField var filterNode: FilterRenderNode? = null
    @JvmField var maskNode: MaskRenderNode? = null
    @JvmField var clipPathNode: ClipPathRenderNode? = null
    @JvmField var markerStartNode: MarkerRenderNode? = null
    @JvmField var markerMidNode: MarkerRenderNode? = null
    @JvmField var markerEndNode: MarkerRenderNode? = null
    @JvmField var fillPatternNode: PatternRenderNode? = null
    @JvmField var strokePatternNode: PatternRenderNode? = null
    @JvmField var fillPaintRef: ResolvedPaint? = null
    @JvmField var strokePaintRef: ResolvedPaint? = null
    @JvmField var animationNodes: List<AnimationNode>? = null
    @JvmField var hasAnimationsInSubtree: Boolean = false
    @JvmField var hasFilterInSubtree: Boolean = false
    @JvmField var subtreeContainsBlendMode: Boolean = false

    /**
     * When true the node never captures a display-list cache. Used for groups
     * that aggregate a viewport-establishing descendant (<use> of <symbol>/<svg>):
     * that descendant's viewBox transform is resolved by [RenderScene.applyViewport]
     * after the first build, and its change would otherwise leave this node's
     * cached pixels stale (the cache key only tracks this node's own version).
     */
    @JvmField var disableDisplayListCache: Boolean = false

    // Snapshot of the fully resolved base style + paint state (before any animation),
    // captured lazily on the first updateAnimations() pass. Each animation frame reverts
    // `renderState` to this base before applying the current animation values, so
    // `fill="remove"` reverts to the base and `additive="sum"` adds to the base rather
    // than compounding the previous frame's result.
    @JvmField var baseAnimatorState: RendererState? = null

    // The state at the time of building (resolved styles, etc.); filled via apply() at build time.
    @JvmField val renderState: RendererState = RendererState()

    // Node-owned paints: synced lazily (field-diff) against renderState's
    // PaintConfigurations right before this node contributes draw operations.
    // Null until first needed, so container-only subtrees never allocate.
    var nodeFillPaint: Paint? = null
    var nodeStrokePaint: Paint? = null
    // SNAPSHOT copies (never aliased to a live config!) used as diff base.
    var appliedFillConfig: PaintConfiguration? = null
    var appliedStrokeConfig: PaintConfiguration? = null

    // Off-screen display-list capture for static subtrees (CanvasRenderNodeCompat).
    // Populated only for eligible (non-animated) nodes on hardware canvases.
    var displayList: CanvasRenderNodeCompat? = null
    var displayListKey: Long = Long.MIN_VALUE

    // Pre-calculated bounding box in user units
    @JvmField var boundingBox: Box? = null

    @JvmField var version: Int = 0
    @JvmField var contentVersion: Int = 0

    fun notifyChange(contentChanged: Boolean = true) {
        if (contentChanged) {
            contentVersion++
        }
        version++
    }

    @JvmField var cachedFilterOutput: Bitmap? = null
    @JvmField var cachedSourceContent: Bitmap? = null
    
    @JvmField var lastSourceVersion: Int = -1
    @JvmField var lastFilterVersion: Int = -1
    @JvmField var lastScaleX: Float = 0f
    @JvmField var lastScaleY: Float = 0f

    internal fun hasAnimations(): Boolean = hasAnimationsInSubtree || computeHasAnimations()
    internal open fun hasFilters(): Boolean = hasFilterInSubtree || filterNode != null

    /** Returns the maximum filter extent (blur + offset) in device pixels for any filter in the subtree. */
    internal open fun computeMaxFilterExtent(sx: Float, sy: Float): Float {
        var maxExtent = 0f
        val fn = filterNode
        if (fn != null) {
            maxExtent = max(maxExtent, fn.computeMaxExtent(sx, sy))
        }
        return maxExtent
    }

    internal open fun hasMarkers(): Boolean {
        return markerStartNode != null || markerMidNode != null || markerEndNode != null
    }

    internal open fun computeHasAnimations(): Boolean {
        return animationNodes?.isNotEmpty() == true
    }

    /**
     * True when any node in the subtree (including this one) has a mix-blend-mode that
     * actually composites against its backdrop. Used to skip the root offscreen layer when
     * the document has no blending, since that layer only exists to give blend modes a
     * transparent backdrop.
     */
    internal open fun computeSubtreeContainsBlendMode(): Boolean {
        val style = renderState.style
        val mode = style.mixBlendMode
        return (mode != null && mode != CSSBlendMode.normal && mode.toBlendModeCompat() != null) ||
                style.isolation == Isolation.isolate
    }


    abstract fun render(renderer: Renderer, canvas: Canvas)

    open fun recycle(bitmapPool: BitmapPool) {
        cachedFilterOutput?.let { 
            bitmapPool.release(it)
            cachedFilterOutput = null
        }
        cachedSourceContent?.let {
            bitmapPool.release(it)
            cachedSourceContent = null
        }
        filterNode?.recycle()
    }

    override fun toString(): String {
        return "RenderNode(sourceElement=$sourceElement, transform=$transform, viewBoxTransform=$viewBoxTransform, opacity=$opacity, filterNode=$filterNode, maskNode=$maskNode, clipPathNode=$clipPathNode, markerStartNode=$markerStartNode, markerMidNode=$markerMidNode, markerEndNode=$markerEndNode, fillPatternNode=$fillPatternNode, strokePatternNode=$strokePatternNode, fillPaintRef=$fillPaintRef, strokePaintRef=$strokePaintRef, animationNodes=$animationNodes, renderState=$renderState, boundingBox=$boundingBox, version=$version, contentVersion=$contentVersion, cachedFilterOutput=$cachedFilterOutput, cachedSourceContent=$cachedSourceContent, lastSourceVersion=$lastSourceVersion, lastFilterVersion=$lastFilterVersion, lastScaleX=$lastScaleX, lastScaleY=$lastScaleY)"
    }
}

internal sealed interface TextNode

internal class TextSequenceNode(
    @JvmField val text: String
) : TextNode {
    // Per-node width buffer: sized once to this run's fixed text length and
    // reused every frame, so measuring it never resizes/reallocates.
    @JvmField val textWidthBuffer = FloatArrayBucket()
}

/**
 * The x/y/width/height length sources a nested viewport container (<svg>,
 * <symbol> via <use>) was sized from at build time. Kept so RenderScene can
 * re-resolve the viewport when the drawable bounds change without rebuilding.
 */
internal class ViewportSpec(
    @JvmField val x: CSSLength?,
    @JvmField val y: CSSLength?,
    @JvmField val width: CSSLength?,
    @JvmField val height: CSSLength?,
)

internal open class GroupRenderNode<T: ConditionalContainer>(
    sourceElement: T,
    @JvmField val children: List<RenderNode<*>>
) : RenderNode<T>(sourceElement) {
    @JvmField var viewPort: Box? = null

    /** Present when this node establishes its own viewport (nested <svg>/<symbol>). */
    @JvmField var viewportSpec: ViewportSpec? = null

    override fun hasMarkers(): Boolean {
        return super.hasMarkers() || children.anyElement { it.hasMarkers() }
    }

    override fun computeHasAnimations(): Boolean {
        return super.computeHasAnimations() || children.anyElement { it.hasAnimations() }
    }

    override fun hasFilters(): Boolean {
        return super.hasFilters() || children.anyElement { it.hasFilters() }
    }

    override fun computeMaxFilterExtent(sx: Float, sy: Float): Float {
        var maxExtent = super.computeMaxFilterExtent(sx, sy)
        children.forEachElement { child ->
            maxExtent = max(maxExtent, child.computeMaxFilterExtent(sx, sy))
        }
        return maxExtent
    }

    override fun computeSubtreeContainsBlendMode(): Boolean {
        return super.computeSubtreeContainsBlendMode() || children.anyElement { it.subtreeContainsBlendMode }
    }

    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderGroupNode(canvas, this)
    }

    override fun recycle(bitmapPool: BitmapPool) {
        super.recycle(bitmapPool)
        children.forEachElement { it.recycle(bitmapPool) }
    }

    override fun toString(): String {
        return "GroupRenderNode(${super.toString()}, children=$children, viewPort=$viewPort)"
    }
}

internal class MaskRenderNode(
    sourceElement: Mask,
    children: List<RenderNode<*>>
) : GroupRenderNode<Mask>(sourceElement, children) {

    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderGroupNode(canvas, this)
    }

    override fun toString(): String {
        return "MaskRenderNode(${super.toString()})"
    }
}

internal class MarkerRenderNode(
    sourceElement: Marker,
    children: List<RenderNode<*>>
) : GroupRenderNode<Marker>(sourceElement, children) {

    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderGroupNode(canvas, this)
    }

    override fun toString(): String {
        return "MarkerRenderNode(${super.toString()})"
    }
}

internal class ClipPathRenderNode(
    sourceElement: ClipPath,
    @JvmField val children: List<RenderNode<*>>
) : RenderNode<ClipPath>(sourceElement) {
    override fun hasMarkers(): Boolean {
        return super.hasMarkers() || children.anyElement { it.hasMarkers() }
    }

    override fun computeHasAnimations(): Boolean {
        return super.computeHasAnimations() || children.anyElement { it.hasAnimations() }
    }

    override fun hasFilters(): Boolean {
        return super.hasFilters() || children.anyElement { it.hasFilters() }
    }

    override fun computeSubtreeContainsBlendMode(): Boolean {
        return super.computeSubtreeContainsBlendMode() || children.anyElement { it.subtreeContainsBlendMode }
    }

    override fun render(renderer: Renderer, canvas: Canvas) {
        error("ClipPaths are not rendered directly")
    }

    override fun toString(): String {
        return "ClipPathRenderNode(${super.toString()}, children=$children)"
    }
}

internal class SwitchRenderNode(
    sourceElement: Switch,
    @JvmField val selectedChild: RenderNode<*>?
) : RenderNode<Switch>(sourceElement) {
    override fun hasMarkers(): Boolean {
        return super.hasMarkers() || selectedChild?.hasMarkers() == true
    }

    override fun computeHasAnimations(): Boolean {
        return super.computeHasAnimations() || selectedChild?.hasAnimations() == true
    }

    override fun computeSubtreeContainsBlendMode(): Boolean {
        return super.computeSubtreeContainsBlendMode() || selectedChild?.subtreeContainsBlendMode == true
    }

    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderSwitchNode(canvas, this)
    }

    override fun toString(): String {
        return "SwitchRenderNode(${super.toString()}, selectedChild=$selectedChild)"
    }
}

internal class PathRenderNode(
    sourceElement: Shape,
    @JvmField val path: Path,
    @JvmField val markers: List<MarkerVector>? = null
) : RenderNode<Shape>(sourceElement) {
    @JvmField val pointsBuffer = FloatArrayBucket()

    override fun hasMarkers(): Boolean {
        return super.hasMarkers() || markers?.isNotEmpty() == true
    }

    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderPathNode(canvas, this)
    }

    override fun toString(): String {
        return "PathRenderNode(${super.toString()}, path=$path, markers=$markers)"
    }
}

internal abstract class KSVGTextContainerRenderNode<T : TextContainer>(
    sourceElement: T,
    @JvmField val children: List<TextNode>
) : RenderNode<T>(sourceElement), TextNode {
    override fun hasMarkers(): Boolean {
        return super.hasMarkers() || children.anyElement { (it as? RenderNode<*>)?.hasMarkers() == true }
    }

    override fun computeHasAnimations(): Boolean {
        return super.computeHasAnimations() || children.anyElement { (it as? RenderNode<*>)?.hasAnimations() == true }
    }

    override fun hasFilters(): Boolean {
        return super.hasFilters() || children.anyElement { (it as? RenderNode<*>)?.hasFilters() == true }
    }
}

internal class TextRenderNode(
    sourceElement: Text,
    @JvmField var x: Float,
    @JvmField var y: Float,
    @JvmField var dx: Float,
    @JvmField var dy: Float,
    children: List<TextNode>
) : KSVGTextContainerRenderNode<Text>(sourceElement, children) {
    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderTextNode(canvas, this)
    }
}

internal class TSpanRenderNode(
    sourceElement: TSpan,
    @JvmField var x: FloatArray?,
    @JvmField var y: FloatArray?,
    @JvmField var dx: FloatArray?,
    @JvmField var dy: FloatArray?,
    children: List<TextNode>
) : KSVGTextContainerRenderNode<TSpan>(sourceElement, children) {
    override fun render(renderer: Renderer, canvas: Canvas) {
        error("TSpan is rendered via renderTSpanNode(node, processor) during text traversal")
    }
}

internal class TextPathRenderNode(
    sourceElement: TextPath,
    @JvmField val path: Path,
    @JvmField var startOffset: Float,
    children: List<TextNode>
) : KSVGTextContainerRenderNode<TextPath>(sourceElement, children) {
    override fun render(renderer: Renderer, canvas: Canvas) {
        error("TextPath is rendered via renderTextPathNode(node, processor) during text traversal")
    }
}

internal class TRefRenderNode(
    sourceElement: TRef,
    @JvmField val text: String,
    @JvmField var x: FloatArray?,
    @JvmField var y: FloatArray?,
    @JvmField var dx: FloatArray?,
    @JvmField var dy: FloatArray?,
) : RenderNode<TRef>(sourceElement), TextNode {
    // Per-node width buffer (see TextSequenceNode.textWidthBuffer).
    @JvmField val textWidthBuffer = FloatArrayBucket()

    override fun render(renderer: Renderer, canvas: Canvas) {
        error("TRef is rendered via renderTRefNode(node, processor) during text traversal")
    }
}

internal class ImageRenderNode(
    sourceElement: Image,
    @JvmField val imageBox: Box,
    @JvmField val bitmap: Bitmap?,
    @JvmField val imageNaturalSize: Box?
) : RenderNode<Image>(sourceElement) {
    override fun render(renderer: Renderer, canvas: Canvas) {
        renderer.renderImageNode(canvas, this)
    }
}

internal class PatternRenderNode(
    sourceElement: Pattern,
    @JvmField val children: List<RenderNode<*>>
) : RenderNode<Pattern>(sourceElement) {
    @JvmField var hasOverflow: Boolean = true
    @JvmField var hasAnimations: Boolean = false

    override fun hasMarkers(): Boolean {
        return super.hasMarkers() || children.anyElement { it.hasMarkers() }
    }

    override fun computeHasAnimations(): Boolean {
        return super.computeHasAnimations() || children.anyElement { it.hasAnimations() }
    }

    override fun hasFilters(): Boolean {
        return super.hasFilters() || children.anyElement { it.hasFilters() }
    }

    override fun computeSubtreeContainsBlendMode(): Boolean {
        return super.computeSubtreeContainsBlendMode() || children.anyElement { it.subtreeContainsBlendMode }
    }

    override fun render(renderer: Renderer, canvas: Canvas) {
        error("Patterns are rendered via fillWithPattern in Renderer")
    }

    override fun recycle(bitmapPool: BitmapPool) {
        super.recycle(bitmapPool)
        children.forEachElement { it.recycle(bitmapPool) }
    }
}

internal class FilterRenderNode(
    @JvmField val sourceElement: Filter,
    @JvmField val primitives: List<FilterPrimitiveRenderNode<*>>
) {
    // GPU fast-path state (touched only on hardware canvases, API 31+).
    @JvmField var gpuNode: android.graphics.RenderNode? = null
    @JvmField var gpuSourceVersion: Int = -1
    @JvmField var gpuFilterVersion: Int = -1
    @JvmField var gpuScaleX: Float = 0f
    @JvmField var gpuScaleY: Float = 0f
    @JvmField var gpuWidth: Int = 0
    @JvmField var gpuHeight: Int = 0
    @JvmField var gpuPadX: Int = 0
    @JvmField var gpuPadY: Int = 0
    // The CTM captured when the source display list was recorded. Content and
    // matrix are baked into the display list, so either changing invalidates
    // it (e.g. an animated transform must force a re-record every frame).
    @JvmField var gpuSourceMatrix: Matrix? = null
    // Built effect chain cache: depends on the filter's attributes (version)
    // and the primitive scales, not on the rendered content.
    @JvmField var gpuChain: FilterPipelineImpl31.Chain? = null
    @JvmField var gpuChainVersion: Int = -1
    @JvmField var gpuChainScaleX: Float = 0f
    @JvmField var gpuChainScaleY: Float = 0f
    @JvmField var gpuChainDeviceLeft: Float = 0f
    @JvmField var gpuChainDeviceTop: Float = 0f
    @JvmField var colorInterpolationFilters: Int = ColorInterpolation.LINEAR_RGB
    @JvmField val renderState: RendererState = RendererState()

    @JvmField var filterSourceMap: FilterSourceMap? = null

    @JvmField var version: Int = 0
    @JvmField var contentVersion: Int = 0

    fun collectPrimitives(): FilterPrimitiveSet {
        var bits = 0
        primitives.forEachElement { primitive ->
            bits = bits or primitive.primitiveFlag
        }
        return FilterPrimitiveSet.from(bits)
    }

    fun notifyChange(contentChanged: Boolean = true) {
        if (contentChanged) {
            contentVersion++
        }
        version++
    }

    fun recycle() {
        filterSourceMap?.recycle()
        filterSourceMap = null
    }

    /** Maximum extent (blur radius * 5 + offset) in device pixels for this filter. */
    fun computeMaxExtent(sx: Float, sy: Float): Float {
        var expandX = 0f
        var expandY = 0f
        var offsetX = 0f
        var offsetY = 0f

        primitives.forEachElement { primitive ->
            when (primitive) {
                is FeGaussianBlurRenderNode -> {
                    expandX += primitive.stdDeviationX * sx * 5f
                    expandY += primitive.stdDeviationY * sy * 5f
                }
                is FeMorphologyRenderNode -> {
                    expandX += primitive.sourceElement.radiusX * sx
                    expandY += primitive.sourceElement.radiusY * sy
                }
                is FeOffsetRenderNode -> {
                    offsetX += abs(primitive.dx)
                    offsetY += abs(primitive.dy)
                }
                is FeDropShadowRenderNode -> {
                    expandX += primitive.blurNode.stdDeviationX * sx * 5f
                    expandY += primitive.blurNode.stdDeviationY * sy * 5f
                    offsetX += abs(primitive.offsetNode.dx)
                    offsetY += abs(primitive.offsetNode.dy)
                }
                else -> {}
            }
        }
        return max(max(expandX, expandY) + max(offsetX, offsetY) + 20f, 0f)
    }
}

internal sealed class FilterPrimitiveRenderNode<T: FilterPrimitive>(
    @JvmField val sourceElement: T
) {
    internal abstract val primitiveFlag: Int
    @JvmField var colorInterpolationFilters: Int = ColorInterpolation.LINEAR_RGB
    @JvmField var x: Float? = null
    @JvmField var y: Float? = null
    @JvmField var width: Float? = null
    @JvmField var height: Float? = null

    @JvmField var version: Int = 0
    @JvmField var contentVersion: Int = 0

    fun notifyChange(contentChanged: Boolean = true) {
        if (contentChanged) {
            contentVersion++
        }
        version++
    }

    /**
     * Precomputed animation nodes, built once. Non-null lets the renderer apply
     * animated styles without falling back to reading the DOM `animations`.
     */
    @JvmField var animationNodes: List<AnimationNode>? = null
}

internal class FeFloodRenderNode(
    sourceElement: FeFlood
) : FilterPrimitiveRenderNode<FeFlood>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_FLOOD
}

internal class FeBlendRenderNode(
    sourceElement: FeBlend,
    @JvmField val mode: FeBlendMode,
    @JvmField val in2: String?,
    @JvmField val paint: Paint,
) : FilterPrimitiveRenderNode<FeBlend>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_BLEND
}

    internal class FeTileRenderNode(
        sourceElement: FeTile
    ) : FilterPrimitiveRenderNode<FeTile>(sourceElement) {
        override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_TILE
    }

    internal class FeDropShadowRenderNode(
        sourceElement: FeDropShadow,
        @JvmField val blurNode: FeGaussianBlurRenderNode,
        @JvmField val offsetNode: FeOffsetRenderNode,
        @JvmField val shadowPaint: Paint = Paint().apply {
            xfermode = XFerModes.SrcIn
        },
    ) : FilterPrimitiveRenderNode<FeDropShadow>(sourceElement) {
        override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_DROP_SHADOW
    }

internal class StopRenderNode(
    @JvmField val sourceElement: Stop
) {
    /**
     * Precomputed animation nodes, built once. Non-null lets the renderer animate the stop
     * without falling back to reading the DOM `animations`.
     */
    @JvmField var animationNodes: List<AnimationNode>? = null
}

internal class FeGaussianBlurRenderNode(
    sourceElement: FeGaussianBlur,
    @JvmField var stdDeviationX: Float,
    @JvmField var stdDeviationY: Float
) : FilterPrimitiveRenderNode<FeGaussianBlur>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR
    /**
     * Pixel buffer reused across renders; resized only when the input dimensions change.
     */
    @JvmField val pixels: IntArrayBucket = IntArrayBucket()

    /**
     * Caller-owned blur scratch (native true-Gaussian or Kotlin fallback), reused across renders.
     */
    @JvmField val blurScratch: StackBlurScratch = StackBlurScratch()
}

internal class FeColorMatrixRenderNode(
    sourceElement: FeColorMatrix,
    @JvmField val type: FeColorMatrixType,
    @JvmField var values: FloatArray?
) : FilterPrimitiveRenderNode<FeColorMatrix>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_COLOR_MATRIX
    /**
     * Cached [Paint] used to apply the color matrix, built lazily on first use.
     */
    @JvmField var paint: Paint? = null
}

internal class FeOffsetRenderNode(
    sourceElement: FeOffset,
    @JvmField var dx: Float,
    @JvmField var dy: Float
) : FilterPrimitiveRenderNode<FeOffset>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_OFFSET
}

internal class FeMergeRenderNode(
    sourceElement: FeMerge,
    @JvmField val mergeNodes: List<String?>
) : FilterPrimitiveRenderNode<FeMerge>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_MERGE
}

internal class FeConvolveMatrixRenderNode(
    sourceElement: FeConvolveMatrix,
    @JvmField val orderX: Int,
    @JvmField val orderY: Int,
    @JvmField val kernel: FloatArray?,
    @JvmField val targetX: Int,
    @JvmField val targetY: Int,
    @JvmField val divisor: Float,
    @JvmField val bias: Float,
    @JvmField val preserveAlpha: Boolean,
    @JvmField val edgeMode: ConvolveMatrixEdgeMode,
) : FilterPrimitiveRenderNode<FeConvolveMatrix>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_CONVOLVE_MATRIX
    /**
     * Pixel buffers reused across renders; resized only when the input dimensions change.
     */
    @JvmField val srcPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val outPixels: IntArrayBucket = IntArrayBucket()
}

internal class FeMorphologyRenderNode(
    sourceElement: FeMorphology,
    @JvmField val erode: Boolean,
) : FilterPrimitiveRenderNode<FeMorphology>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_MORPHOLOGY
    /**
     * Pixel buffers reused across renders; resized only when the input dimensions change.
     */
    @JvmField val srcPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val dstPixels: IntArrayBucket = IntArrayBucket()
}

internal class ComponentTransferFunctions(
    @JvmField val r: FeFunc?,
    @JvmField val g: FeFunc?,
    @JvmField val b: FeFunc?,
    @JvmField val a: FeFunc?,
)

internal class FeComponentTransferRenderNode(
    sourceElement: FeComponentTransfer,
    @JvmField val transferFunctions: ComponentTransferFunctions,
) : FilterPrimitiveRenderNode<FeComponentTransfer>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_COMPONENT_TRANSFER
    @JvmField val srcPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val outPixels: IntArrayBucket = IntArrayBucket()

    // Lazily built [A,R,G,B] 256-entry LUTs; null until first use. The tables
    // depend only on build-time transfer functions, so they are computed once.
    @JvmField var lutTables: Array<IntArray>? = null

    @JvmField var gpuLutBitmap: Bitmap? = null
}

internal class FeCompositeRenderNode(
    sourceElement: FeComposite,
    @JvmField val paint: Paint,
) : FilterPrimitiveRenderNode<FeComposite>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_COMPOSITE
    @JvmField val inputPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val in2Pixels: IntArrayBucket = IntArrayBucket()
    @JvmField val outPixels: IntArrayBucket = IntArrayBucket()
}

internal class FeTurbulenceRenderNode(
    sourceElement: FeTurbulence,
    @JvmField val generators: Array<SvgPathNoise>,
) : FilterPrimitiveRenderNode<FeTurbulence>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_TURBULENCE
    @JvmField val pixels: IntArrayBucket = IntArrayBucket()

    @JvmField var gpuLatticeBitmap: Bitmap? = null
    @JvmField var gpuLatticeVersion: Int = -1
}

internal class FeDisplacementMapRenderNode(
    sourceElement: FeDisplacementMap,
) : FilterPrimitiveRenderNode<FeDisplacementMap>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_DISPLACEMENT_MAP
    @JvmField val inputPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val mapPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val outPixels: IntArrayBucket = IntArrayBucket()
}

internal class FeDiffuseLightingRenderNode(
    sourceElement: FeDiffuseLighting,
) : FilterPrimitiveRenderNode<FeDiffuseLighting>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_DIFFUSE_LIGHTING
    @JvmField val pixels: IntArrayBucket = IntArrayBucket()
    @JvmField val outPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val normal: NormalVector = NormalVector()
    @JvmField val lightVec: LightVector = LightVector()
}

internal class FeSpecularLightingRenderNode(
    sourceElement: FeSpecularLighting,
) : FilterPrimitiveRenderNode<FeSpecularLighting>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_SPECULAR_LIGHTING
    @JvmField val pixels: IntArrayBucket = IntArrayBucket()
    @JvmField val outPixels: IntArrayBucket = IntArrayBucket()
    @JvmField val normal: NormalVector = NormalVector()
    @JvmField val lightVec: LightVector = LightVector()
}

internal class FeImageRenderNode(
    sourceElement: FeImage,
    @JvmField val image: Bitmap?,
    @JvmField val referencedNode: RenderNode<*>?,
) : FilterPrimitiveRenderNode<FeImage>(sourceElement) {
    override val primitiveFlag: Int get() = FilterPrimitiveSet.FLAG_IMAGE
}

internal class GenericFilterPrimitiveRenderNode(
    sourceElement: FilterPrimitive
) : FilterPrimitiveRenderNode<FilterPrimitive>(sourceElement) {
    override val primitiveFlag: Int get() = 0
}
