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

import android.graphics.Matrix
import android.graphics.PathMeasure
import android.graphics.Rect
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.Svg
import hu.oandras.ksvg.dom.core.ViewBoxContainer
import hu.oandras.ksvg.dom.shapes.CircleShape
import hu.oandras.ksvg.dom.shapes.EllipseShape
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PathShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.shapes.RectShape
import hu.oandras.ksvg.dom.shapes.Shape
import hu.oandras.ksvg.dom.text.TextPath
import hu.oandras.ksvg.render.PaintConfiguration.Companion.DEFAULT_TEXT_SIZE
import hu.oandras.ksvg.render.pool.BitmapPool
import hu.oandras.ksvg.render.pool.PoolOwner
import hu.oandras.ksvg.utils.anyElement

/**
 * Owns a built render-node tree together with the state that decides when the
 * tree has to be rebuilt versus when it can be updated in place.
 *
 * Rebuild triggers:
 *  - document [modificationCount] changed (parse/mutation),
 *  - render-options fingerprint changed (css / view / viewBox / preserveAspectRatio / target).
 *
 * Viewport (drawable bounds) changes are handled IN PLACE by [applyViewport]:
 * only nested viewport containers (<svg>/<symbol>) re-resolve their viewport
 * and viewBox transform; everything else stays in user units.
 */
internal class RenderScene private constructor(
    @JvmField val rootNode: RenderNode<*>?,
    @JvmField val dPI: Float,
    @JvmField val modificationCount: Int,
    @JvmField val optionsFingerprint: Long,
) {

    /** Last applied drawable bounds. */
    @JvmField
    var viewport: Rect? = null

    // Root-level view overrides resolved at build time (shared helper with the builder).
    private var rootOverrides: RootViewOverrides = RootViewOverrides(null, null)

    fun isUpToDate(modificationCount: Int, fingerprint: Long): Boolean {
        return this.modificationCount == modificationCount &&
                this.optionsFingerprint == fingerprint
    }

    /**
     * In-place viewport update: re-resolves every nested viewport container's
     * viewport box and viewBox transform against the new drawable bounds.
     * Content whose recorded geometry changed bumps its own contentVersion so
     * display-list caches replay fresh content.
     */
    fun applyViewport(bounds: Rect, options: RenderOptionsImpl, pools: PoolOwner) {
        val root = rootNode ?: return
        val rootSvg = root.sourceElement as? Svg ?: return
        if (root !is GroupRenderNode<*>) return

        val ctx = SceneUpdateContext(pools, dPI)

        // Mirror build(renderOptions): the external viewport is decisive, root
        // width/height only refine it when expressed in percent.
        var vp = options.viewPort ?: Box(
            bounds.left.toFloat(),
            bounds.top.toFloat(),
            bounds.width().toFloat(),
            bounds.height().toFloat()
        )
        with(ctx) {
            rootSvg.width?.let {
                if (it.unit == CssUnit.percent) vp = vp.copy(width = it.floatValueInContext(vp.width))
            }
            rootSvg.height?.let {
                if (it.unit == CssUnit.percent) vp = vp.copy(height = it.floatValueInContext(vp.height))
            }
        }

        updateViewportContainer(root, rootSvg, vp, rootOverrides.viewBoxOverride, rootOverrides.parOverride, ctx)
        viewport = Rect(bounds)
    }

    fun recycle(bitmapPool: BitmapPool) {
        rootNode?.recycle(bitmapPool)
    }

    /**
     * Recomputes one viewport container's viewport box + viewBox transform;
     * pushes the new coordinate context while its children are updated.
     */
    private fun updateViewportContainer(
        node: GroupRenderNode<*>,
        container: ViewBoxContainer,
        viewPort: Box,
        viewBoxOverride: Box?,
        parOverride: PreserveAspectRatio?,
        ctx: SceneUpdateContext,
    ) {
        node.viewPort = viewPort

        val oldViewPort = ctx.walkViewPort
        val oldViewBox = ctx.walkViewBox
        ctx.walkViewPort = viewPort

        val matrix = Matrix()
        val viewBox = viewBoxOverride ?: container.viewBox
        val positioning = parOverride
            ?: container.preserveAspectRatio
            ?: PreserveAspectRatio.LETTERBOX

        ctx.walkViewBox = applyViewportTransform(viewPort, viewBox, positioning, matrix)

        if (node.viewBoxTransform != matrix) {
            node.viewBoxTransform = matrix
            // Recorded display-list content lives in the OLD coordinate system.
            node.notifyChange(contentChanged = true)
        }

        updateChildren(node, ctx)

        ctx.walkViewPort = oldViewPort
        ctx.walkViewBox = oldViewBox
    }

    private fun updateChildren(node: GroupRenderNode<*>, ctx: SceneUpdateContext) {
        val children = node.children
        for (i in children.indices) {
            val child = children[i]
            resolveViewportDependentFields(child, ctx)

            if (child !is GroupRenderNode<*>) continue

            val container = child.sourceElement as? ViewBoxContainer
            if (child.viewportSpec != null && container != null) {
                // Nested viewport container (<svg>/<symbol>): re-resolve its box
                // and transform; recursion continues with the pushed context.
                val vp = resolveViewport(child.viewportSpec!!, ctx)
                updateViewportContainer(child, container, vp, null, null, ctx)
            } else {
                // Plain group: keep walking - nested viewports can sit at any depth.
                updateChildren(child, ctx)
            }
        }
    }

    /**
     * Re-resolves viewport-relative fields from the source element's original
     * lengths. Only values expressed in percent units can actually change with
     * the drawable bounds; recomputing unconditionally and comparing keeps the
     * logic simple and allocation-free for the common all-px case.
     */
    private fun resolveViewportDependentFields(node: RenderNode<*>, ctx: SceneUpdateContext) {
        when (node) {
            is TextRenderNode -> {
                val obj = node.sourceElement
                if (!obj.hasViewportDependentLengths()) return
                with(ctx) {
                    val x = obj.x?.firstOrNull()?.floatValueXInContext() ?: 0f
                    val y = obj.y?.firstOrNull()?.floatValueYInContext() ?: 0f
                    val dx = obj.dx?.firstOrNull()?.floatValueXInContext() ?: 0f
                    val dy = obj.dy?.firstOrNull()?.floatValueYInContext() ?: 0f
                    if (x != node.x || y != node.y || dx != node.dx || dy != node.dy) {
                        node.x = x; node.y = y; node.dx = dx; node.dy = dy
                        node.notifyChange(true)
                    }
                }
            }

            is TSpanRenderNode -> {
                val obj = node.sourceElement
                if (!obj.hasViewportDependentLengths()) return
                with(ctx) {
                    val x = obj.x?.map { it.floatValueXInContext() }?.toFloatArray()
                    val y = obj.y?.map { it.floatValueYInContext() }?.toFloatArray()
                    val dx = obj.dx?.map { it.floatValueXInContext() }?.toFloatArray()
                    val dy = obj.dy?.map { it.floatValueYInContext() }?.toFloatArray()
                    if (!x.contentEquals(node.x) || !y.contentEquals(node.y) ||
                            !dx.contentEquals(node.dx) || !dy.contentEquals(node.dy)) {
                        node.x = x; node.y = y; node.dx = dx; node.dy = dy
                        node.notifyChange(true)
                    }
                }
            }

            is TextPathRenderNode -> {
                val obj = node.sourceElement
                if (!obj.hasViewportDependentLengths()) return
                with(ctx) {
                    val startOffset = obj.startOffset?.floatValueInContext(PathMeasure(node.path, false).length) ?: 0f
                    if (startOffset != node.startOffset) {
                        node.startOffset = startOffset
                        node.notifyChange(true)
                    }
                }
            }

            is TRefRenderNode -> {
                val obj = node.sourceElement
                if (!obj.hasViewportDependentLengths()) return
                with(ctx) {
                    val x = obj.x?.map { it.floatValueXInContext() }?.toFloatArray()
                    val y = obj.y?.map { it.floatValueYInContext() }?.toFloatArray()
                    val dx = obj.dx?.map { it.floatValueXInContext() }?.toFloatArray()
                    val dy = obj.dy?.map { it.floatValueYInContext() }?.toFloatArray()
                    if (!x.contentEquals(node.x) || !y.contentEquals(node.y) ||
                            !dx.contentEquals(node.dx) || !dy.contentEquals(node.dy)) {
                        node.x = x; node.y = y; node.dx = dx; node.dy = dy
                        node.notifyChange(true)
                    }
                }
            }

            is PathRenderNode -> updatePercentShape(node, ctx)

            else -> {}
        }
    }

    /**
     * Shapes carry their geometry in user units; only percent coordinates move
     * with the viewport. When present, regenerate path + element/node bounding box.
     */
    private fun updatePercentShape(node: PathRenderNode, ctx: SceneUpdateContext) {
        val shape = node.sourceElement
        if (!shapeUsesPercentUnits(shape)) return

        with(ctx) {
            val regenerated = when (shape) {
                is RectShape -> updatePathAndBoundingBox(shape, node.path, node)
                is CircleShape -> updatePathAndBoundingBox(shape, node.path, node)
                is EllipseShape -> updatePathAndBoundingBox(shape, node.path, node)
                is LineShape -> updatePathAndBoundingBox(shape, node.path, node)
                else -> false
            }
            if (regenerated) {
                node.boundingBox = shape.boundingBox
                node.notifyChange(true)
            }
        }
    }

    private fun CSSLength?.isPercent(): Boolean = this != null && unit == CssUnit.percent

    private fun shapeUsesPercentUnits(shape: Shape): Boolean {
        return when (shape) {
            is RectShape -> shape.x.isPercent() || shape.y.isPercent() ||
                    shape.width.isPercent() || shape.height.isPercent() ||
                    shape.rx.isPercent() || shape.ry.isPercent()
            is CircleShape -> shape.cx.isPercent() || shape.cy.isPercent() || shape.r.isPercent()
            is EllipseShape -> shape.cx.isPercent() || shape.cy.isPercent() ||
                    shape.rx.isPercent() || shape.ry.isPercent()
            is LineShape -> shape.x1.isPercent() || shape.y1.isPercent() ||
                    shape.x2.isPercent() || shape.y2.isPercent()
            is PolyLineShape, is PathShape -> false // point lists / path data contain no lengths
        }
    }

    /**
     * Builder post-processing (e.g. text-anchor justification) can adjust the
     * resolved values away from their raw length resolution, so fields are only
     * touched when a percent unit is actually present.
     */
    private fun hu.oandras.ksvg.dom.text.TextPositionedContainer.hasViewportDependentLengths(): Boolean =
        hasPercent(x) || hasPercent(y) || hasPercent(dx) || hasPercent(dy)

    private fun hu.oandras.ksvg.dom.text.TRef.hasViewportDependentLengths(): Boolean =
        hasPercent(x) || hasPercent(y) || hasPercent(dx) || hasPercent(dy)

    private fun TextPath.hasViewportDependentLengths(): Boolean = startOffset?.unit == CssUnit.percent

    private fun hasPercent(lengths: List<CSSLength>?): Boolean = lengths.anyElement { it.unit == CssUnit.percent }

    private fun resolveViewport(spec: ViewportSpec, ctx: SceneUpdateContext): Box {
        return with(ctx) { makeViewportInContext(spec.x, spec.y, spec.width, spec.height) }
    }

    internal companion object {
        fun build(
            document: SVGImpl,
            dPI: Float,
            externalFileResolver: ExternalFileResolver?,
            pools: PoolOwner,
            options: RenderOptionsImpl,
            modificationCount: Int,
            optionsFingerprint: Long,
        ): RenderScene {
            val builder = RenderTreeBuilder(
                document = document,
                dPI = dPI,
                externalFileResolver = externalFileResolver,
                pools = pools,
            )
            val node = builder.build(options)
            val scene = RenderScene(node, dPI, modificationCount, optionsFingerprint)
            scene.rootOverrides = resolveRootViewOverrides(document, options) ?: RootViewOverrides(null, null)
            return scene
        }

        /**
         * Fingerprint of the render-options fields that require a tree rebuild.
         * Excludes the viewport (frequent, handled by the update path).
         */
        fun computeOptionsFingerprint(options: RenderOptionsImpl): Long {
            var result = options.css.hashCode().toLong()
            result = 31L * result + options.preserveAspectRatio.hashCode()
            result = 31L * result + options.targetId.hashCode()
            result = 31L * result + options.viewBox.hashCode()
            result = 31L * result + options.viewId.hashCode()
            return result
        }
    }
}

/**
 * Minimal [RenderContext] for the update walk: length resolution only needs
 * DPI (fixed), font size (build-time constant) and the current walk viewport.
 */
private class SceneUpdateContext(
    pools: PoolOwner,
    dpi: Float,
) : hu.oandras.ksvg.render.animation.AnimationContext, PoolOwner by pools {
    override val dPI: Float = dpi
    override val currentFontSize: Float = DEFAULT_TEXT_SIZE
    override val currentFontXHeight: Float = currentFontSize / 2f
    override val animationTimeMs: Long = 0L // no animation state during viewport updates
    var walkViewPort: Box? = null
    var walkViewBox: Box? = null
    override val effectiveViewPortInUserUnits: Box
        get() = walkViewBox ?: checkNotNull(walkViewPort) { "Viewport is null" }
}
