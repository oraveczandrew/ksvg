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
import android.graphics.Rect
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.css.CssUnit
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.Svg
import hu.oandras.ksvg.dom.core.View
import hu.oandras.ksvg.dom.core.ViewBoxContainer
import hu.oandras.ksvg.render.PaintConfiguration.Companion.DEFAULT_TEXT_SIZE
import hu.oandras.ksvg.render.pool.BitmapPool
import hu.oandras.ksvg.render.pool.PoolOwner

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
) : RenderContext, PoolOwner by pools {
    override val dPI: Float = dpi
    override val currentFontSize: Float = DEFAULT_TEXT_SIZE
    override val currentFontXHeight: Float = currentFontSize / 2f
    var walkViewPort: Box? = null
    var walkViewBox: Box? = null
    override val effectiveViewPortInUserUnits: Box
        get() = walkViewBox ?: checkNotNull(walkViewPort) { "Viewport is null" }
}
