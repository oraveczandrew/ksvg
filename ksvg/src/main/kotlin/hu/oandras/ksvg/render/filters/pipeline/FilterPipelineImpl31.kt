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

import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.RectF
import android.graphics.RenderEffect
import android.os.Build
import android.util.ArrayMap
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.render.ALPHA_MATRIX_COLOR_FILTER
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeDropShadowRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeMorphologyRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.withSave
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.forEachElement
import kotlin.math.abs
import android.graphics.RenderNode as AndroidRenderNode

/**
 * RenderEffect GPU backend (API 31+, hardware canvas only).
 *
 * Supports strictly linear single-input chains of feColorMatrix,
 * feGaussianBlur and feOffset (each primitive's `in` refers to the previous
 * result or is the implicit source). ColorMatrix maps 1:1 onto
 * [RenderEffect.createColorFilterEffect] (same [buildColorMatrix] as the CPU
 * path). GaussianBlur uses [RenderEffect.createBlurEffect] with CLAMP edge
 * mode; the source is recorded with a transparent pad of
 * [Chain.padX]/[Chain.padY] device pixels on every side so the clamp reads
 * transparent black — matching the CPU kernel's transparent-black pedestal.
 * Offset maps to [RenderEffect.createOffsetEffect] with device-pixel deltas.
 *
 * Deliberately NOT claimed yet: two-input or canvas-drawn primitives
 * (Blend/Composite/Merge/Flood/Image), displacement, lighting.
 */
@RequiresApi(Build.VERSION_CODES.S)
internal open class FilterPipelineImpl31 internal constructor(
    @JvmField
    protected val renderContext: RenderContext,
) : FilterBackend {

    /** Effect chain plus the transparent recording pad it requires. */
    internal class Chain internal constructor(
        @JvmField internal val effect: RenderEffect,
        @JvmField internal val padX: Int,
        @JvmField internal val padY: Int,
        @JvmField internal val scaleX: Float,
        @JvmField internal val scaleY: Float,
        @JvmField internal val deviceLeft: Float,
        @JvmField internal val deviceTop: Float,
    ) {
        override fun toString(): String {
            return buildString {
                append("Chain(effect=")
                append(effect)
                append(", padX=")
                append(padX)
                append(", padY=")
                append(padY)
                append(", scaleX=")
                append(scaleX)
                append(", scaleY=")
                append(scaleY)
                append(", deviceLeft=")
                append(deviceLeft)
                append(", deviceTop=")
                append(deviceTop)
                append(')')
            }
        }
    }

    protected open val supportedMask: Int
        get() = FilterPrimitiveSet.FLAG_COLOR_MATRIX or
                FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR or
                FilterPrimitiveSet.FLAG_OFFSET

    context(renderContext: RenderContext)
    protected open fun calculateTotalPadding(
        filterNode: FilterRenderNode,
        scaleX: Float,
        scaleY: Float,
        sx: Float,
        sy: Float
    ): Long {
        var expandX = 0f
        var expandY = 0f
        var offsetX = 0f
        var offsetY = 0f

        filterNode.primitives.forEachElement { primitive ->
            when (primitive) {
                is FeGaussianBlurRenderNode -> {
                    expandX += primitive.stdDeviationX * scaleX * 4f
                    expandY += primitive.stdDeviationY * scaleY * 4f
                }
                is FeMorphologyRenderNode -> {
                    expandX += primitive.sourceElement.radiusX * scaleX
                    expandY += primitive.sourceElement.radiusY * scaleY
                }
                is FeOffsetRenderNode -> {
                    val primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false
                    offsetX += abs(
                        filterPrimitiveLengthX(
                            length = primitive.sourceElement.dx,
                            primitiveUnitsAreUser = primitiveUnitsAreUser,
                            primitiveScaleX = scaleX,
                            canvasScaleX = sx
                        )
                    )
                    offsetY += abs(
                        filterPrimitiveLengthY(
                            length = primitive.sourceElement.dy,
                            primitiveUnitsAreUser = primitiveUnitsAreUser,
                            primitiveScaleY = scaleY,
                            canvasScaleY = sy
                        )
                    )
                }
                is FeDropShadowRenderNode -> {
                    expandX += primitive.blurNode.stdDeviationX * scaleX * 4f
                    expandY += primitive.blurNode.stdDeviationY * scaleY * 4f
                    offsetX += abs(
                        filterPrimitiveLengthX(
                            length = primitive.sourceElement.dx,
                            primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                            primitiveScaleX = scaleX,
                            canvasScaleX = sx
                        )
                    )
                    offsetY += abs(
                        filterPrimitiveLengthY(
                            length = primitive.sourceElement.dy,
                            primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                            primitiveScaleY = scaleX,
                            canvasScaleY = sy
                        )
                    )
                }
                else -> {}
            }
        }

        val padX = (expandX + offsetX + 10f).ceilToInt()
        val padY = (expandY + offsetY + 10f).ceilToInt()

        return (padX.toLong() shl 32) or (padY.toLong() and 0xFFFFFFFFL)
    }

    // Caller-owned mutable state; a backend instance is owned by a single
    // render operation and never shared between threads.
    private var recordingActive: Boolean = false

    final override fun supports(primitives: FilterPrimitiveSet): Boolean {
        return primitives.bits != 0 && (primitives.bits and supportedMask.inv()) == 0
    }

    context(renderContext: RenderContext)
    internal fun tryBuildChain(
        filterNode: FilterRenderNode,
        scaleX: Float,
        scaleY: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        sx: Float,
        sy: Float,
        boundingBox: Box,
    ): Chain? {
        // Node-keyed chain cache: the chain depends only on the filter's
        // attributes (version) and the primitive scales - not on the rendered
        // content - so it survives across frames while the keys match.
        val cached = filterNode.gpuChain
        if (cached != null &&
            filterNode.gpuChainVersion == filterNode.version &&
            filterNode.gpuChainScaleX == scaleX &&
            filterNode.gpuChainScaleY == scaleY &&
            filterNode.gpuChainDeviceLeft == deviceRegion.left &&
            filterNode.gpuChainDeviceTop == deviceRegion.top
        ) {
            return cached
        }

        val chain = tryBuildChainImpl(
            filterNode,
            scaleX,
            scaleY,
            filterRegion,
            deviceRegion,
            sx,
            sy,
            boundingBox,
        )

        if (chain != null) {
            filterNode.gpuChain = chain
            filterNode.gpuChainVersion = filterNode.version
            filterNode.gpuChainScaleX = scaleX
            filterNode.gpuChainScaleY = scaleY
            filterNode.gpuChainDeviceLeft = deviceRegion.left
            filterNode.gpuChainDeviceTop = deviceRegion.top
        }

        return chain
    }

    /**
     * Builds (or returns the cached) whole-graph effect chain; null when the
     * graph is not a strict linear sequence of supported primitives.
     *
     * [scaleX]/[scaleY] are the primitive scales (canvas scale for
     * userSpaceOnUse units, bounding-box based otherwise) used to convert
     * blur stdDeviation to device pixels; offset lengths are resolved through
     * the renderer's [renderContext].
     */
    context(renderContext: RenderContext)
    protected open fun tryBuildChainImpl(
        filterNode: FilterRenderNode,
        scaleX: Float,
        scaleY: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        sx: Float,
        sy: Float,
        boundingBox: Box,
    ): Chain? {
        var chainEffect: RenderEffect? = null
        var previousResult: String? = null
        var first = true
        val packed = calculateTotalPadding(filterNode, scaleX, scaleY, sx, sy)
        val totalPadX = (packed shr 32).toInt()
        val totalPadY = (packed and 0xFFFFFFFFL).toInt()
        val resultEffects = ArrayMap<String, RenderEffect>()

        filterNode.primitives.forEachElement { primitive ->
            val sourceElement = primitive.sourceElement

            val resultName = sourceElement.result
            val input = sourceElement.`in`

            val inputEffect = resolveEffect(input, previousResult, first, chainEffect, resultEffects) ?: return null

            val effect = when (primitive) {
                is FeColorMatrixRenderNode -> {
                    val element = primitive.sourceElement
                    val colorFilter = android.graphics.ColorMatrixColorFilter(
                        buildColorMatrix(element.type, element.values)
                    )
                    RenderEffect.createColorFilterEffect(colorFilter).chainWith(inputEffect)
                }

                is FeGaussianBlurRenderNode -> {
                    val sigmaX = primitive.stdDeviationX * scaleX
                    val sigmaY = primitive.stdDeviationY * scaleY
                    if (sigmaX <= 0f && sigmaY <= 0f) {
                        inputEffect
                    } else {
                        RenderEffect.createBlurEffect(
                            sigmaX, sigmaY,
                            android.graphics.Shader.TileMode.CLAMP
                        ).chainWith(inputEffect)
                    }
                }

                is FeOffsetRenderNode -> {
                    val dx = filterPrimitiveLengthX(
                        length = primitive.sourceElement.dx,
                        primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                        primitiveScaleX = scaleX,
                        canvasScaleX = scaleX
                    )
                    val dy = filterPrimitiveLengthY(
                        length = primitive.sourceElement.dy,
                        primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                        primitiveScaleY = scaleY,
                        canvasScaleY = scaleY
                    )
                    if (dx == 0f && dy == 0f) {
                        inputEffect
                    } else {
                        RenderEffect.createOffsetEffect(dx, dy).chainWith(inputEffect)
                    }
                }

                else -> return null
            }

            chainEffect = effect
            previousResult = resultName
            first = false
            if (resultName != null) {
                resultEffects[resultName] = effect
            }
        }

        val result = chainEffect ?: return null
        return Chain(
            effect = result,
            padX = totalPadX,
            padY = totalPadY,
            scaleX = scaleX,
            scaleY = scaleY,
            deviceLeft = deviceRegion.left,
            deviceTop = deviceRegion.top
        )
    }

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
        val chain = obtainChain(
            filterNode = filterNode,
            sx = sx,
            sy = sy,
            filterRegion = filterRegion,
            deviceRegion = deviceRegion,
            boundingBox = boundingBox
        ) ?: return null

        if (recordingActive) return null

        val padX = chain.padX
        val padY = chain.padY
        val contentVersion = node.contentVersion
        var gpuNode = filterNode.gpuNode
        val valid = gpuNode != null &&
                gpuNode.hasDisplayList() &&
                filterNode.gpuSourceVersion == contentVersion &&
                filterNode.gpuFilterVersion == filterNode.version &&
                filterNode.gpuScaleX == sx && filterNode.gpuScaleY == sy &&
                filterNode.gpuWidth == width && filterNode.gpuHeight == height &&
                filterNode.gpuPadX == padX && filterNode.gpuPadY == padY &&
                matrix == filterNode.gpuSourceMatrix
        if (!valid) {
            gpuNode = gpuNode ?: AndroidRenderNode("ksvg-filter-source")
            val recording = gpuNode.beginRecording(width + 2 * padX, height + 2 * padY)
            recording.translate(padX - deviceRegion.left, padY - deviceRegion.top)
            recording.concat(matrix)
            // The source content and the CTM applied above are baked into the
            // display list; snapshot the matrix so a later CTM change (e.g. an
            // animated transform, or an ancestor moving) forces a re-record
            // instead of reusing the stale, frozen content.
            val sourceMatrix = filterNode.gpuSourceMatrix ?: Matrix().also { filterNode.gpuSourceMatrix = it }
            sourceMatrix.set(matrix)
            filterNode.gpuNode = gpuNode
            filterNode.gpuSourceVersion = contentVersion
            filterNode.gpuFilterVersion = filterNode.version
            filterNode.gpuScaleX = sx
            filterNode.gpuScaleY = sy
            filterNode.gpuWidth = width
            filterNode.gpuHeight = height
            filterNode.gpuPadX = padX
            filterNode.gpuPadY = padY
            gpuNode.setPosition(0, 0, width + 2 * padX, height + 2 * padY)
            recordingActive = true
            return recording
        }

        // Cached recording is still valid: nothing to re-record.
        return null
    }

    override fun endRecording(filterNode: FilterRenderNode) {
        if (recordingActive) {
            filterNode.gpuNode?.endRecording()
            recordingActive = false
        }
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
        val chain = filterNode.gpuChain ?: return
        val gpuNode = filterNode.gpuNode ?: return
        gpuNode.setRenderEffect(chain.effect)
        canvas.withSave {
            @Suppress("DEPRECATION")
            canvas.setMatrix(null)
            // The software backend composites a region-sized bitmap, so its output is
            // inherently clipped to the filter effects region. Clip the GPU blit the
            // same way: framework effects (offset/blur/…) carry no region of their own
            // and would otherwise leak translated/spread content outside the region.
            canvas.clipRect(deviceRegion)
            canvas.translate(deviceRegion.left - chain.padX, deviceRegion.top - chain.padY)
            canvas.drawRenderNode(gpuNode)
        }
    }

    protected open fun obtainChain(
        filterNode: FilterRenderNode,
        sx: Float,
        sy: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        boundingBox: Box,
    ): Chain? =
        with(renderContext) {
            val primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false
            val pScaleX = if (primitiveUnitsAreUser) sx else boundingBox.width * sx
            val pScaleY = if (primitiveUnitsAreUser) sy else boundingBox.height * sy
            tryBuildChain(
                filterNode, pScaleX, pScaleY,
                filterRegion, deviceRegion, sx, sy, boundingBox
            )
        }

    protected fun resolveEffect(
        input: String?,
        previousResult: String?,
        first: Boolean,
        currentChain: RenderEffect?,
        resultEffects: Map<String, RenderEffect>
    ): RenderEffect? {
        if (input == null) {
            return if (first) IDENTITY_EFFECT else currentChain
        }

        return when (input) {
            "SourceGraphic" -> IDENTITY_EFFECT
            "SourceAlpha" -> SOURCE_ALPHA_EFFECT
            previousResult -> currentChain
            else -> resultEffects[input]
        }
    }

    override fun release() {
        recordingActive = false
    }

    internal fun RenderEffect.chainWith(input: RenderEffect?): RenderEffect {
        if (input == null || input == IDENTITY_EFFECT) {
            return this
        }
        return RenderEffect.createChainEffect(this, input)
    }

    companion object {
        @JvmField
        internal val IDENTITY_EFFECT = RenderEffect.createOffsetEffect(0f, 0f)

        @JvmField
        internal val SOURCE_ALPHA_EFFECT = RenderEffect.createColorFilterEffect(ALPHA_MATRIX_COLOR_FILTER)
    }
}
