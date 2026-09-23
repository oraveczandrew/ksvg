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
package hu.oandras.ksvg

import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Matrix
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.Drawable
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.RenderOptionsImpl
import hu.oandras.ksvg.render.RenderScene
import hu.oandras.ksvg.render.Renderer
import hu.oandras.ksvg.render.collectHitRegions
import hu.oandras.ksvg.render.inverseRootMapping
import hu.oandras.ksvg.render.pool.PoolOwner

/**
 * A [Drawable] backed by an [SVG] document.
 */
public open class KSVGDrawable @JvmOverloads public constructor(
    @JvmField
    protected val svg: SVG,
    renderOptions: RenderOptions? = null
) : Drawable() {

    private val renderOptions: RenderOptionsImpl = if (renderOptions == null) {
        RenderOptionsImpl()
    } else {
        RenderOptionsImpl(renderOptions)
    }

    private var alpha: Int = 0xFF

    private val pools = PoolOwner()

    private val renderer = Renderer(
        document = svg as SVGImpl,
        dPI = svg.renderDPI,
        pools = pools,
        // Member (not the nullable constructor parameter, which shadows it here).
        gpuBackendFactory = this.renderOptions.gpuBackendFactory,
    )

    private var scene: RenderScene? = null

    // Hit region support (lazily computed on hitTest)
    private var hitRegions: List<HitRegion>? = null
    private var screenToSvgTransform: Matrix? = null
    private var hitRegionsDirty: Boolean = true

    @JvmField
    protected var hasAnimation: Boolean = run {
        val svg = svg as SVGImpl
        svg.requireRootElement().hasAnimationsOnTree()
    }

    override fun draw(canvas: Canvas) {
        val bounds = bounds
        if (bounds.isEmpty) {
            drawIntoIntrinsicBounds(canvas)
            return
        }

        drawIntoBounds(canvas, bounds)
    }

    private fun drawIntoIntrinsicBounds(canvas: Canvas) {
        val width = intrinsicWidth
        val height = intrinsicHeight
        if (width <= 0 || height <= 0) return
        
        val bounds = Rect(0, 0, width, height)
        drawIntoBounds(canvas, bounds)
    }

    private fun drawIntoBounds(canvas: Canvas, bounds: Rect) {
        val saveCount = saveForAlpha(
            canvas = canvas,
            left = bounds.left.toFloat(),
            top = bounds.top.toFloat(),
            right = bounds.right.toFloat(),
            bottom = bounds.bottom.toFloat()
        )
        val options = getRenderOptions(
            left = bounds.left.toFloat(),
            top = bounds.top.toFloat(),
            width = bounds.width().toFloat(),
            height = bounds.height().toFloat()
        ) as RenderOptionsImpl

        val svgImpl = svg as SVGImpl

        var node = scene?.rootNode
        val modCount = svgImpl.modificationCount
        val fingerprint = RenderScene.computeOptionsFingerprint(options)
        val currentScene = scene
        val upToDate = currentScene != null &&
                currentScene.isUpToDate(modCount, fingerprint)

        if (!upToDate) {
            scene?.recycle(pools.bitmapPool)

            val newScene = RenderScene.build(
                document = svgImpl,
                dPI = svg.renderDPI,
                externalFileResolver = svg.externalFileResolver,
                pools = pools,
                options = options,
                modificationCount = modCount,
                optionsFingerprint = fingerprint,
            )
            scene = newScene
            node = newScene.rootNode
            hitRegionsDirty = true
        } else {
            // Bounds-only change: update viewports/transforms in place, no rebuild.
            currentScene.applyViewport(bounds, options, pools)
            // Viewport geometry changed: cached hit regions map to the old one.
            hitRegionsDirty = true
        }

        if (node != null) {
            renderer.renderDocument(canvas, node, options)
        }
        
        canvas.restoreToCount(saveCount)
    }

    protected open fun getRenderOptions(
        left: Float,
        top: Float,
        width: Float,
        height: Float
    ): RenderOptions {
        val options = renderOptions
        options.viewPort(
            minX = left,
            minY = top,
            width = width,
            height = height
        )
        return options
    }

    private fun saveForAlpha(
        canvas: Canvas,
        left: Float,
        top: Float,
        right: Float,
        bottom: Float
    ): Int {
        val alpha = alpha
        return if (alpha == 0xFF) {
            canvas.save()
        } else {
            canvas.saveLayerAlpha(
                left,
                top,
                right,
                bottom,
                alpha
            )
        }
    }

    override fun setAlpha(alpha: Int) {
        if (this.alpha == alpha) return
        this.alpha = alpha.coerceIn(0, 0xFF)
        invalidateSelf()
    }

    override fun getAlpha(): Int = alpha

    override fun setColorFilter(colorFilter: ColorFilter?) {
        // Rendering is delegated to the SVG renderer. Color filtering the complete result requires
        // an intermediate layer paint, which is intentionally left unsupported for now.
    }

    @Deprecated(
        message = "Deprecated in Android platform API",
        replaceWith = ReplaceWith("PixelFormat.TRANSLUCENT")
    )
    override fun getOpacity(): Int = PixelFormat.TRANSLUCENT

    override fun getIntrinsicWidth(): Int = validatedDocumentSize(svg.documentWidth)

    override fun getIntrinsicHeight(): Int = validatedDocumentSize(svg.documentHeight)

    /**
     * Performs a hit-test at the given screen coordinates and returns the `href`
     * of the topmost `<a>` element that contains the point, or `null` if none.
     */
    public fun hitTest(x: Float, y: Float): String? {
        ensureHitRegions()
        val transform = screenToSvgTransform ?: return null
        val pts = floatArrayOf(x, y)
        transform.mapPoints(pts)
        val svgX = pts[0]
        val svgY = pts[1]

        val regions = hitRegions ?: return null
        for (i in regions.indices.reversed()) {
            if (regions[i].bounds.contains(svgX, svgY)) {
                return regions[i].href
            }
        }
        return null
    }

    /**
     * Returns the list of clickable `<a>` regions in the most recent render.
     */
    public fun getHitRegions(): List<HitRegion> {
        ensureHitRegions()
        return hitRegions ?: emptyList()
    }

    private fun ensureHitRegions() {
        if (!hitRegionsDirty) return
        hitRegionsDirty = false

        val node = scene?.rootNode ?: run {
            hitRegions = emptyList()
            screenToSvgTransform = null
            return
        }


        val regions = mutableListOf<HitRegion>()
        collectHitRegions(node, regions)

        screenToSvgTransform = inverseRootMapping(node) ?: run {
            val vp = scene?.viewport
            if (vp != null) {
                val identity = Matrix()
                identity.setTranslate(-vp.left.toFloat(), -vp.top.toFloat())
                identity
            } else {
                null
            }
        }

        hitRegions = regions
    }

    private fun validatedDocumentSize(reportedSize: Float): Int {
        val reportedSizeI = reportedSize.toInt()
        return if (reportedSizeI > 0) {
            reportedSizeI
        } else {
            -1
        }
    }

    public fun trimMemory() {
        pools.clear()
    }

    /**
     * Estimated retained memory in bytes: pooled bitmaps plus render-tree
     * bitmaps and pixel-sized buffers (scene caches, filter LUTs/lattices,
     * pixel buckets). Excludes the DOM, geometry, paints and GPU display
     * lists (not measurable via public APIs, and small next to bitmaps).
     * Best-effort under concurrency; intended for cache weighing
     * (e.g. Glide's `Resource.getSize`).
     */
    public fun getMemorySizeBytes(): Long {
        return pools.bitmapPool.retainedBytes() + (scene?.retainedByteCount() ?: 0L)
    }
}
