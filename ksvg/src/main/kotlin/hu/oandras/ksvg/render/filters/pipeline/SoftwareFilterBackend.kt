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

package hu.oandras.ksvg.render.filters.pipeline

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import hu.oandras.ksvg.compat.setBlendModeCompat
import hu.oandras.ksvg.compat.toBlendModeCompat
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.style.CSSBlendMode
import hu.oandras.ksvg.render.FeBlendRenderNode
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeComponentTransferRenderNode
import hu.oandras.ksvg.render.FeCompositeRenderNode
import hu.oandras.ksvg.render.FeConvolveMatrixRenderNode
import hu.oandras.ksvg.render.FeDiffuseLightingRenderNode
import hu.oandras.ksvg.render.FeDisplacementMapRenderNode
import hu.oandras.ksvg.render.FeDropShadowRenderNode
import hu.oandras.ksvg.render.FeFloodRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeImageRenderNode
import hu.oandras.ksvg.render.FeMergeRenderNode
import hu.oandras.ksvg.render.FeMorphologyRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.FeSpecularLightingRenderNode
import hu.oandras.ksvg.render.FeTileRenderNode
import hu.oandras.ksvg.render.FeTurbulenceRenderNode
import hu.oandras.ksvg.render.FilterPrimitiveRenderNode
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.FilterSourceMap
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.calculatePrimitiveRegion
import hu.oandras.ksvg.render.filters.doFeBlendFilter
import hu.oandras.ksvg.render.filters.doFeColorMatrixFilter
import hu.oandras.ksvg.render.filters.doFeComponentTransferFilter
import hu.oandras.ksvg.render.filters.doFeCompositeFilter
import hu.oandras.ksvg.render.filters.doFeConvolveMatrixFilter
import hu.oandras.ksvg.render.filters.doFeDiffuseLightingFilter
import hu.oandras.ksvg.render.filters.doFeDisplacementMapFilter
import hu.oandras.ksvg.render.filters.doFeDropShadowFilter
import hu.oandras.ksvg.render.filters.doFeFloodFilter
import hu.oandras.ksvg.render.filters.doFeGaussianBlurFilter
import hu.oandras.ksvg.render.filters.doFeImageFilter
import hu.oandras.ksvg.render.filters.doFeMergeFilter
import hu.oandras.ksvg.render.filters.doFeMorphologyFilter
import hu.oandras.ksvg.render.filters.doFeOffsetFilter
import hu.oandras.ksvg.render.filters.doFeSpecularLightingFilter
import hu.oandras.ksvg.render.filters.doFeTileFilter
import hu.oandras.ksvg.render.filters.doFeTurbulenceFilter
import hu.oandras.ksvg.render.filters.getFilterInput
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.withSave
import hu.oandras.ksvg.utils.forEachElement

/**
 * Software (CPU) filter backend driving the existing Kotlin/native kernel
 * path. It is both the software-canvas workhorse and the final fallback of
 * [FilterPipeline]: it claims every primitive set.
 */
internal class SoftwareFilterBackend internal constructor(
    private val renderContext: RenderContext,
) : FilterBackend {

    // Backend-owned recording canvas for source-bitmap rendering; reused to
    // avoid per-frame allocation. Owned by a single render operation.
    private val recordCanvas: Canvas = Canvas()

    private var activeNode: RenderNode<*>? = null

    /**
     * Reusable paint for compositing a filtered bitmap back onto the canvas.
     * Must honour the element's own `opacity` and `mix-blend-mode`, which are
     * otherwise silently dropped when a `filter` is present.
     * Kept per-backend-instance so it is never shared mutable state across
     * Drawables/threads.
     */
    private val filterCompositePaint: Paint = Paint()

    override fun supports(primitives: FilterPrimitiveSet): Boolean = true

    override fun beginRecording(
        node: RenderNode<*>,
        filterNode: FilterRenderNode,
        width: Int,
        height: Int,
        sx: Float,
        sy: Float,
        matrix: Matrix,
        newMatrix: Matrix,
        filterRegion: RectF,
        deviceRegion: RectF,
        boundingBox: Box,
    ): Canvas? {
        var sourceBitmap = node.cachedSourceContent
        val contentVersion = node.contentVersion

        val canReuseSource = sourceBitmap != null &&
                !sourceBitmap.isRecycled &&
                sourceBitmap.allocationByteCount >= width * height * 4

        if (sourceBitmap == null ||
            sourceBitmap.isRecycled ||
            node.lastSourceVersion != contentVersion ||
            node.lastScaleX != sx ||
            node.lastScaleY != sy ||
            sourceBitmap.width != width ||
            sourceBitmap.height != height
        ) {
            if (!canReuseSource) {
                if (sourceBitmap != null) {
                    renderContext.bitmapPool.release(sourceBitmap)
                }
                sourceBitmap = renderContext.bitmapPool.acquire(
                    width,
                    height,
                    Bitmap.Config.ARGB_8888
                )
                node.cachedSourceContent = sourceBitmap
            } else {
                sourceBitmap.reconfigure(width, height, Bitmap.Config.ARGB_8888)
                sourceBitmap.eraseColor(0)
            }

            newMatrix.set(matrix)
            newMatrix.postTranslate(-deviceRegion.left, -deviceRegion.top)
            recordCanvas.setBitmap(sourceBitmap)
            recordCanvas.setMatrix(newMatrix)

            activeNode = node
            return recordCanvas
        }

        // Cached source content is still valid: nothing to re-record.
        activeNode = null
        return null
    }

    override fun endRecording(filterNode: FilterRenderNode) {
        val node = activeNode ?: return
        node.lastSourceVersion = node.contentVersion
        activeNode = null
    }

    override fun drawFiltered(
        canvas: Canvas,
        node: RenderNode<*>,
        filterNode: FilterRenderNode,
        width: Int,
        height: Int,
        sx: Float,
        sy: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        boundingBox: Box,
        state: RendererState,
    ) {
        val cachedFilterOutput = node.cachedFilterOutput
        if (cachedFilterOutput != null &&
            node.lastSourceVersion == node.contentVersion &&
            node.lastFilterVersion == filterNode.version &&
            node.lastScaleX == sx &&
            node.lastScaleY == sy &&
            cachedFilterOutput.width == width &&
            cachedFilterOutput.height == height
        ) {
            drawResult(canvas, deviceRegion, cachedFilterOutput, state)
            return
        }

        val sourceBitmap = node.cachedSourceContent ?: return

        if (cachedFilterOutput != null && cachedFilterOutput !== sourceBitmap) {
            if (cachedFilterOutput.allocationByteCount < width * height * 4) {
                renderContext.bitmapPool.release(cachedFilterOutput)
                node.cachedFilterOutput = null
            }
        }

        val filteredBitmap = applyFilterToBitmap(
            canvas = canvas,
            sourceBitmap = sourceBitmap,
            filterRegion = filterRegion,
            deviceRegion = deviceRegion,
            sx = sx,
            sy = sy,
            filterNode = filterNode,
            originalObjBBox = boundingBox,
            state = state,
        )

        node.cachedFilterOutput = filteredBitmap
        node.lastFilterVersion = filterNode.version
        node.lastScaleX = sx
        node.lastScaleY = sy

        if (filteredBitmap != null) {
            drawResult(canvas, deviceRegion, filteredBitmap, state)
        }
    }

    override fun release() {
        activeNode = null
        recordCanvas.setBitmap(null)
    }

    private fun drawResult(canvas: Canvas, deviceRegion: RectF, bitmap: Bitmap, state: RendererState) {
        canvas.withSave {
            renderContext.matrixPool.withPooledObject { matrix ->
                @Suppress("DEPRECATION")
                canvas.getMatrix(matrix)
                if (matrix.invert(matrix)) {
                    canvas.concat(matrix)
                } else {
                    // Fallback to absolute reset if not invertible (rare)
                    @Suppress("DEPRECATION")
                    canvas.setMatrix(null)
                }
                canvas.drawBitmap(bitmap, deviceRegion.left, deviceRegion.top, configureFilterCompositePaint(state))
            }
        }
    }

    /**
     * The filtered bitmap is composited back onto the original canvas. This paint must
     * honour the element's own `opacity` and `mix-blend-mode`, otherwise they are silently
     * dropped when a `filter` is present.
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
        filterCompositePaint.setBlendModeCompat(state.style.mixBlendMode?.toBlendModeCompat())
        return filterCompositePaint
    }

    @JvmSynthetic
    internal fun applyFilterToBitmap(
        canvas: Canvas,
        sourceBitmap: Bitmap,
        filterRegion: RectF,
        deviceRegion: RectF,
        sx: Float,
        sy: Float,
        filterNode: FilterRenderNode,
        originalObjBBox: Box,
        state: RendererState,
    ): Bitmap? = with(renderContext) {
        val filter = filterNode.sourceElement

        val results = filterNode.filterSourceMap ?: FilterSourceMap(renderContext).also {
            filterNode.filterSourceMap = it
        }

        results.reInitWith(sourceBitmap)

        // The filter bitmap is sized to the *device-space* filter region, while
        // `filterRegion` (below) is in user space. Per-primitive subregion clipping
        // compares `primitiveRegion - filterRegion` against the bitmap's pixel
        // dimensions, so both must be expressed in bitmap-pixel space. The bitmap
        // maps exactly onto the filter region, so the pixel-space filter region is
        // simply the full bitmap.
        renderContext.rectFPool.withPooledObject { filterRegionPx ->
            filterRegionPx.set(0f, 0f, sourceBitmap.width.toFloat(), sourceBitmap.height.toFloat())

            renderContext.rectFPool.withPooledObject { inputUnion ->
                var lastResult: Bitmap? = sourceBitmap
                // The user-space subregion of the previous primitive's result. `in` == null on a
                // subsequent primitive means "the result of the previous primitive" (per spec), so
                // the default subregion inherits this. It starts as the filter region to represent
                // SourceGraphic (the first primitive's default input).
                val lastResultRegion = renderContext.rectFPool.pull()
                lastResultRegion.set(filterRegion)
                val primitiveUnitsAreUser = filter.primitiveUnitsAreUser != false
                val primitiveScaleX = if (primitiveUnitsAreUser) sx else originalObjBBox.width * sx
                val primitiveScaleY = if (primitiveUnitsAreUser) sy else originalObjBBox.height * sy
                val primitiveOriginX = if (primitiveUnitsAreUser) 0f else originalObjBBox.minX
                val primitiveOriginY = if (primitiveUnitsAreUser) 0f else originalObjBBox.minY

                val primitives = filterNode.primitives
                val terminalNode = primitives.lastOrNull()

                primitives.forEachElement { primitiveNode ->
                    val child = primitiveNode.sourceElement

                    // Compute the union of the referenced input node(s)' subregions in user
                    // space. When a primitive omits x/y/width/height and its input is a
                    // referenced node's result, its subregion defaults to this union (per the
                    // SVG Filter Effects spec) instead of the whole filter region.
                    inputUnion.setEmpty()
                    var hasInputRegion = false
                    when (primitiveNode) {
                        is FeMergeRenderNode -> primitiveNode.mergeNodes.forEachElement { inputId ->
                            // Standard inputs (no `in`, SourceGraphic, SourceAlpha) span the whole
                            // filter region, so they contribute the filter region to the union.
                            val r = if (inputId == null || inputId == "SourceGraphic" || inputId == "SourceAlpha") {
                                filterRegion
                            } else {
                                results.getResultRegion(inputId)
                            }
                            if (r != null) {
                                if (hasInputRegion) inputUnion.union(r) else inputUnion.set(r)
                                hasInputRegion = true
                            }
                        }

                        else -> {
                            // `in` == null on a non-first primitive means "the result of the
                            // previous primitive", so the default subregion inherits the previous
                            // primitive's subregion (lastResultRegion, initialised to the filter
                            // region for the first primitive / SourceGraphic). A named result uses
                            // its recorded subregion. Other standard-input names are never
                            // registered results, so `getResultRegion` returns null and the
                            // default falls back to the filter region (spec-correct).
                            val r = if (child.`in` == null) {
                                lastResultRegion
                            } else {
                                results.getResultRegion(child.`in`)
                            }
                            if (r != null) {
                                inputUnion.set(r)
                                hasInputRegion = true
                            }
                        }
                    }
                    val regionResolver: (String?) -> RectF? = { _ ->
                        if (hasInputRegion) inputUnion else null
                    }

                    val res = renderContext.rectFPool.withPooledObject { primitiveRegion ->
                        calculatePrimitiveRegion(
                            primitive = child,
                            filterRegion = filterRegion,
                            unitsAreUser = primitiveUnitsAreUser,
                            originalObjBBox = originalObjBBox,
                            outRect = primitiveRegion,
                            resolveInputRegion = regionResolver,
                        )

                        // Record the primitive's own user-space subregion (used by a following
                        // primitive that references this result) before remapping below.
                        results.setResultRegion(child.result, primitiveRegion)
                        lastResultRegion.set(primitiveRegion)

                        // Remap `primitiveRegion` from user space to bitmap-pixel space so
                        // the per-primitive subregion clipping (which uses the bitmap's
                        // pixel dimensions) lines up correctly at any render scale.
                        val frW = filterRegion.width()
                        val frH = filterRegion.height()
                        if (frW > 0f && frH > 0f) {
                            val scaleX = sourceBitmap.width / frW
                            val scaleY = sourceBitmap.height / frH
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * scaleX,
                                (primitiveRegion.top - filterRegion.top) * scaleY,
                                (primitiveRegion.right - filterRegion.left) * scaleX,
                                (primitiveRegion.bottom - filterRegion.top) * scaleY,
                            )
                        }

                        when (primitiveNode) {
                            is FeMergeRenderNode -> doFeMergeFilter(
                                merge = primitiveNode,
                                results = results,
                                lastResult = lastResult,
                                region = primitiveRegion
                            )

                            else -> applyPrimitive(
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
                                filterRegion = filterRegion,
                                filterRegionPx = filterRegionPx,
                                primitiveRegion = primitiveRegion,
                                state = state,
                                terminalNode = terminalNode,
                            )
                        }
                    }

                    if (res != null) {
                        results.set(child.result, res)
                        lastResult = res
                    }
                }

                renderContext.rectFPool.release(lastResultRegion)
                results.recycle(exclude = lastResult)
                return lastResult
            }
        }
    }

    private fun applyPrimitive(
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
        filterRegion: RectF,
        filterRegionPx: RectF,
        primitiveRegion: RectF,
        state: RendererState,
        // The primitive whose result becomes the terminal canvas draw. For an
        // feSpecularLighting terminal the kernel emits premultiplied output.
        // Nullable to avoid star-projection type mismatch; null means "not terminal".
        terminalNode: FilterPrimitiveRenderNode<*>? = null,
    ): Bitmap? {
        val primitive = primitiveNode.sourceElement
        val input = getFilterInput(
            name = primitive.`in`,
            results = results,
            lastResult = lastResult
        )

        val inputBitmap = input ?: return null

        return when (primitiveNode) {

            is FeTurbulenceRenderNode -> with(renderContext) {
                doFeTurbulenceFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveScaleX = primitiveScaleX,
                    primitiveScaleY = primitiveScaleY,
                    primitiveOriginX = primitiveOriginX,
                    primitiveOriginY = primitiveOriginY,
                    regionLeft = filterRegion.left,
                    regionTop = filterRegion.top,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegion,
                    filterRegionPx = filterRegionPx,
                )
            }

            is FeOffsetRenderNode -> with(renderContext) {
                doFeOffsetFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveUnitsAreUser = primitiveUnitsAreUser,
                    primitiveScaleX = primitiveScaleX,
                    primitiveScaleY = primitiveScaleY,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                )
            }

            is FeConvolveMatrixRenderNode -> with(renderContext) {
                doFeConvolveMatrixFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                )
            }

            is FeMorphologyRenderNode -> with(renderContext) {
                doFeMorphologyFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveScaleX = primitiveScaleX,
                    primitiveScaleY = primitiveScaleY,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                )
            }

            is FeComponentTransferRenderNode -> with(renderContext) {
                doFeComponentTransferFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                )
            }

            is FeCompositeRenderNode -> with(renderContext) {
                doFeCompositeFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    results = results,
                    lastResult = lastResult,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                )
            }

            is FeDisplacementMapRenderNode -> with(renderContext) {
                doFeDisplacementMapFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    results = results,
                    lastResult = lastResult,
                )
            }

            is FeDiffuseLightingRenderNode -> with(renderContext) {
                doFeDiffuseLightingFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveScaleX = primitiveScaleX,
                    primitiveScaleY = primitiveScaleY,
                    primitiveOriginX = primitiveOriginX,
                    primitiveOriginY = primitiveOriginY,
                    regionLeft = filterRegion.left,
                    regionTop = filterRegion.top,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                )
            }

            is FeSpecularLightingRenderNode -> with(renderContext) {
                doFeSpecularLightingFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveScaleX = primitiveScaleX,
                    primitiveScaleY = primitiveScaleY,
                    primitiveOriginX = primitiveOriginX,
                    primitiveOriginY = primitiveOriginY,
                    regionLeft = filterRegion.left,
                    regionTop = filterRegion.top,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                    premultipliedOutput = primitiveNode === terminalNode,
                )
            }

            is FeColorMatrixRenderNode -> with(renderContext) {
                doFeColorMatrixFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                )
            }

            is FeGaussianBlurRenderNode -> with(renderContext) {
                doFeGaussianBlurFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveScaleX = primitiveScaleX,
                    primitiveScaleY = primitiveScaleY,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                )
            }

            is FeImageRenderNode -> with(renderContext) {
                doFeImageFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                )
            }

            is FeFloodRenderNode -> with(renderContext) {
                doFeFloodFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                    baseStyle = state.style,
                )
            }

            is FeBlendRenderNode -> with(renderContext) {
                doFeBlendFilter(
                    primitiveNode = primitiveNode,
                    inputBitmap = inputBitmap,
                    results = results,
                    lastResult = lastResult,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                    canvasScaleX = canvasScaleX,
                    canvasScaleY = canvasScaleY,
                )
            }

            is FeTileRenderNode -> with(renderContext) {
                doFeTileFilter(
                    inputBitmap = inputBitmap,
                    primitiveRegion = primitiveRegion,
                    filterRegion = filterRegionPx,
                )
            }

            is FeDropShadowRenderNode -> with(renderContext) {
                doFeDropShadowFilter(
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
                    filterRegion = filterRegionPx,
                    baseStyle = state.style,
                )
            }

            else -> {
                val res = renderContext.bitmapPool.acquireSameAs(input)
                recordCanvas.setBitmap(res)
                recordCanvas.drawBitmap(input, 0f, 0f, null)
                res
            }
        }
    }
}
