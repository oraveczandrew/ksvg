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

import android.content.pm.ActivityInfo
import android.content.res.ColorStateList
import android.content.res.Resources
import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Matrix
import android.graphics.Outline
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.LayoutDirection
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.RenderOptionsImpl
import hu.oandras.ksvg.render.RenderScene
import hu.oandras.ksvg.render.Renderer
import hu.oandras.ksvg.render.collectHitRegions
import hu.oandras.ksvg.render.inverseRootMapping
import hu.oandras.ksvg.render.pool.PoolOwner

/**
 * A [Drawable] backed by an [SVG] document.
 *
 * Single-thread affinity: draws, scene rebuilds and hit-region computation share
 * mutable state ([scene], pools, cached regions) without synchronization. Use one
 * drawable per thread, normally the main thread. Concurrent [draw] calls corrupt
 * rendering state.
 *
 * Scene ownership: the cached [scene] (plus renderer and pools) belongs to this
 * drawable instance alone and is rebuilt when bounds, DPI or options change. Do
 * not share one drawable between concurrently drawn views; create a drawable per
 * view instead (they can share the same parsed [SVG] document, which is read-only
 * after parsing).
 *
 * Sizing: SVGs without intrinsic width/height report -1 intrinsics, so
 * `wrap_content` hosts collapse. Give the view explicit bounds (or the SVG
 * explicit dimensions) instead.
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

    /**
     * Construction-time snapshot of the render options, untouched by per-draw
     * viewport updates. Backs [getConstantState]: every `newDrawable()` copy
     * starts from these options, never from another instance's last-draw state.
     */
    @JvmField
    internal val baseOptions: RenderOptionsImpl = RenderOptionsImpl(this.renderOptions)

    private var alpha: Int = 0xFF
    private var colorFilter: ColorFilter? = null
    private var tintList: ColorStateList? = null
    private var tintMode: PorterDuff.Mode = PorterDuff.Mode.SRC_IN
    private val layerPaint = Paint()
    // Cached tint-derived filter: rebuilt only when the resolved (color, mode)
    // pair changes, so steady-state draws never allocate (hot-path rule).
    private var tintFilterCache: PorterDuffColorFilter? = null
    private var tintFilterColor: Int = 0
    private var tintFilterCacheMode: PorterDuff.Mode = PorterDuff.Mode.SRC_IN
    private var autoMirrored: Boolean = false

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
        if (!ownsAnimationClock) {
            // Legacy/test seam: follow direct document-clock manipulation.
            // Drawables that own their clock (animated) never read the shared
            // document clock here.
            (svg as? SVGImpl)?.let { renderer.animationTimeMs = it.animationTimeMs }
        }
        val saveCount = saveForAlphaAndFilter(
            canvas = canvas,
            left = bounds.left.toFloat(),
            top = bounds.top.toFloat(),
            right = bounds.right.toFloat(),
            bottom = bounds.bottom.toFloat()
        )
        val mirrored = autoMirrored && layoutDirection == LayoutDirection.RTL
        if (mirrored) {
            canvas.translate(bounds.left.toFloat() + bounds.right.toFloat(), 0f)
            canvas.scale(-1f, 1f)
        }
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

    /**
     * Whether this drawable owns the animation clock (pushed per draw) instead
     * of following the document clock. The base drawable follows the document
     * clock so direct clock manipulation keeps working; the animated drawable
     * owns its clock so sharers never see each other's animation time.
     */
    protected open val ownsAnimationClock: Boolean = false

    /**
     * Pushes this drawable's animation clock into its renderer. The clock is
     * per-drawable state: drawables sharing one document never see each
     * other's animation time. Takes ownership of the clock; see
     * [ownsAnimationClock].
     */
    protected fun setAnimationClock(timeMs: Long) {
        renderer.animationTimeMs = timeMs
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

    private fun saveForAlphaAndFilter(
        canvas: Canvas,
        left: Float,
        top: Float,
        right: Float,
        bottom: Float
    ): Int {
        val filter = effectiveFilter()
        return if (alpha == 0xFF && filter == null) {
            canvas.save()
        } else {
            layerPaint.alpha = alpha
            layerPaint.colorFilter = filter
            canvas.saveLayer(left, top, right, bottom, layerPaint)
        }
    }

    private fun effectiveFilter(): ColorFilter? {
        colorFilter?.let { return it }
        val list = tintList ?: return null
        val color = list.getColorForState(state, list.defaultColor)
        val mode = tintMode
        val cached = tintFilterCache
        if (cached != null && tintFilterColor == color && tintFilterCacheMode == mode) {
            return cached
        }
        return PorterDuffColorFilter(color, mode).also {
            tintFilterCache = it
            tintFilterColor = color
            tintFilterCacheMode = mode
        }
    }

    private fun invalidateTintFilter() {
        tintFilterCache = null
    }

    override fun setAlpha(alpha: Int) {
        if (this.alpha == alpha) return
        this.alpha = alpha.coerceIn(0, 0xFF)
        invalidateSelf()
    }

    override fun getAlpha(): Int = alpha

    /**
     * Shares the parsed document (`svg`) and the construction-time options, so
     * each `newDrawable()` is a fresh instance with its own scene, pools and
     * bounds. Never shares viewport geometry or render caches.
     */
    override fun getConstantState(): ConstantState {
        return KSVGConstantState(svg, RenderOptionsImpl(baseOptions), animated = false)
    }

    /**
     * This drawable already owns all of its mutable state (scene, pools,
     * bounds); nothing is shared with siblings from the same constant state,
     * so `mutate()` is a no-op returning this.
     */
    override fun mutate(): Drawable {
        return this
    }

    /**
     * Post-filters the fully rendered document via one `saveLayer` with a
     * reused per-drawable [Paint] holding [alpha] and the effective filter
     * (explicit [colorFilter], else the tint-derived filter — the base
     * `Drawable` tint plumbing never calls [setColorFilter], so tint is
     * resolved explicitly here). The tint-derived filter is cached and rebuilt
     * only when the resolved (color, mode) pair changes, so steady-state
     * tinted draws allocate nothing and [getColorFilter] returns a stable
     * instance. Filtered draws cost one extra fullscreen blend; the
     * unfiltered path is a plain `save()` and is unaffected. Per-drawable
     * state like [alpha]: a `ConstantState` copy starts with a clean (null)
     * filter and no tint.
     */
    override fun setColorFilter(colorFilter: ColorFilter?) {
        if (this.colorFilter === colorFilter) return
        this.colorFilter = colorFilter
        invalidateSelf()
    }

    override fun getColorFilter(): ColorFilter? = effectiveFilter()

    override fun setTintList(tint: ColorStateList?) {
        if (tintList === tint) return
        tintList = tint
        invalidateTintFilter()
        invalidateSelf()
    }

    override fun setTintMode(tintMode: PorterDuff.Mode?) {
        val mode = tintMode ?: PorterDuff.Mode.SRC_IN
        if (this.tintMode == mode) return
        this.tintMode = mode
        invalidateTintFilter()
        invalidateSelf()
    }

    /**
     * API 29+ entry point; funnels into the same [tintMode]. Modes without a
     * `PorterDuff` equivalent (`COLOR_DODGE`, `COLOR_BURN`, `HARD_LIGHT`,
     * `SOFT_LIGHT`, `DIFFERENCE`, `EXCLUSION`, `HUE`, `SATURATION`, `COLOR`,
     * `LUMINOSITY`) fall back to `SRC_IN`: a documented approximation, not a
     * silent drop — the tint still applies.
     */
    @RequiresApi(Build.VERSION_CODES.Q)
    override fun setTintBlendMode(blendMode: BlendMode?) {
        setTintMode(blendMode?.toPorterDuffMode() ?: PorterDuff.Mode.SRC_IN)
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun BlendMode.toPorterDuffMode(): PorterDuff.Mode = when (this) {
        BlendMode.CLEAR -> PorterDuff.Mode.CLEAR
        BlendMode.SRC -> PorterDuff.Mode.SRC
        BlendMode.DST -> PorterDuff.Mode.DST
        BlendMode.SRC_OVER -> PorterDuff.Mode.SRC_OVER
        BlendMode.DST_OVER -> PorterDuff.Mode.DST_OVER
        BlendMode.SRC_IN -> PorterDuff.Mode.SRC_IN
        BlendMode.DST_IN -> PorterDuff.Mode.DST_IN
        BlendMode.SRC_OUT -> PorterDuff.Mode.SRC_OUT
        BlendMode.DST_OUT -> PorterDuff.Mode.DST_OUT
        BlendMode.SRC_ATOP -> PorterDuff.Mode.SRC_ATOP
        BlendMode.DST_ATOP -> PorterDuff.Mode.DST_ATOP
        BlendMode.XOR -> PorterDuff.Mode.XOR
        BlendMode.PLUS -> PorterDuff.Mode.ADD
        BlendMode.MODULATE -> PorterDuff.Mode.MULTIPLY
        BlendMode.SCREEN -> PorterDuff.Mode.SCREEN
        BlendMode.OVERLAY -> PorterDuff.Mode.OVERLAY
        BlendMode.DARKEN -> PorterDuff.Mode.DARKEN
        BlendMode.LIGHTEN -> PorterDuff.Mode.LIGHTEN
        else -> PorterDuff.Mode.SRC_IN
    }

    /**
     * Conservative default: always `TRANSLUCENT`. A provably opaque document
     * would allow `OPAQUE`, but that needs a scene-level transparency signal
     * (alpha < 255 anywhere, `fill="none"`, transparent background, filter
     * output) that is not reliably computed today. A wrong `OPAQUE` is a
     * visual bug; a wrong `TRANSLUCENT` is only slower — so this stays.
     */
    @Deprecated(
        message = "Deprecated in Android platform API",
        replaceWith = ReplaceWith("PixelFormat.TRANSLUCENT")
    )
    override fun getOpacity(): Int = PixelFormat.TRANSLUCENT

    /**
     * No content-based padding: like `VectorDrawable`, padding stays empty
     * (returns `false`). There is no meaningful content-bounds → padding
     * mapping for a scaled SVG viewport.
     */
    override fun getPadding(padding: Rect): Boolean {
        padding.set(0, 0, 0, 0)
        return false
    }

    override fun getOutline(outline: Outline) {
        if (bounds.isEmpty) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                outline.setEmpty()
            } else {
                @Suppress("DEPRECATION")
                super.getOutline(outline)
            }
            return
        }
        outline.setRect(bounds)
    }

    override fun isAutoMirrored(): Boolean = autoMirrored

    override fun setAutoMirrored(mirrored: Boolean) {
        if (autoMirrored == mirrored) return
        autoMirrored = mirrored
        invalidateSelf()
    }

    override fun onLayoutDirectionChanged(layoutDirection: Int): Boolean {
        invalidateSelf()
        return super.onLayoutDirectionChanged(layoutDirection)
    }

    override fun getIntrinsicWidth(): Int = validatedDocumentSize(svg.documentWidth)

    override fun getIntrinsicHeight(): Int = validatedDocumentSize(svg.documentHeight)

    /**
     * Performs a hit-test at the given screen coordinates and returns the `href`
     * of the topmost `<a>` element that contains the point, or `null` if none.
     */
    public fun hitTest(x: Float, y: Float): String? {
        ensureHitRegions()
        val transform = screenToSvgTransform ?: return null
        var px = x
        if (autoMirrored && layoutDirection == LayoutDirection.RTL) {
            val bounds = bounds
            px = (bounds.left + bounds.right).toFloat() - x
        }
        val pts = floatArrayOf(px, y)
        transform.mapPoints(pts)
        val svgX = pts[0]
        val svgY = pts[1]

        val regions = hitRegions ?: return null
        for (i in regions.indices.reversed()) {
            val region = regions[i]
            if (region.bounds.contains(svgX, svgY)) {
                return region.href
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

    /**
     * Releases cached bitmaps held by this drawable's pools. Call it from
     * `ComponentCallbacks2.onTrimMemory` (or Glide's `Resource.recycle`) when
     * the system is low on memory; the drawable re-renders on demand.
     */
    public fun trimMemory() {
        pools.clear()
    }

    /**
     * Estimated retained memory in bytes: pooled bitmaps plus render-tree
     * bitmaps and pixel-sized buffers (scene caches, filter LUTs/lattices,
     * pixel buckets). Excludes the DOM, geometry, paints and GPU display
     * lists (not measurable via public APIs, and small next to bitmaps).
     * Best-effort under concurrency; intended for cache weighing
     * (e.g., Glide's `Resource.getSize`).
     */
    public fun getMemorySizeBytes(): Long {
        return pools.bitmapPool.retainedBytes() + (scene?.retainedByteCount() ?: 0L)
    }
}

/**
 * Shared state behind [KSVGDrawable.getConstantState]. Holds the parsed
 * document by reference (read-only after handoff) plus a snapshot of the
 * construction-time render options. Every [newDrawable] copies the options
 * again, so instances never share viewport geometry or render caches.
 */
internal class KSVGConstantState internal constructor(
    private val svg: SVG,
    private val renderOptions: RenderOptions,
    private val animated: Boolean,
) : Drawable.ConstantState() {

    override fun newDrawable(): Drawable {
        val options = RenderOptionsImpl(renderOptions)
        return if (animated) {
            svg.toAnimatedDrawable(options)
        } else {
            svg.toDrawable(options)
        }
    }

    override fun newDrawable(res: Resources?): Drawable {
        // `res` is intentionally unused: the scene is density-aware via
        // `svg.renderDPI`, not via the host Resources. Density changes are
        // signaled through `getChangingConfigurations` instead.
        return newDrawable()
    }

    override fun getChangingConfigurations(): Int {
        return ActivityInfo.CONFIG_DENSITY
    }
}
