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
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.withSave
import hu.oandras.ksvg.utils.forEachElement

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
    protected val renderContext: RenderContext,
) : FilterBackend {

    /** Effect chain plus the transparent recording pad it requires. */
    internal class Chain internal constructor(
        @JvmField internal val effect: RenderEffect,
        @JvmField internal val padX: Int,
        @JvmField internal val padY: Int,
        @JvmField internal val scaleX: Float,
        @JvmField internal val scaleY: Float,
    ) {
        override fun toString(): String {
            return "Chain(effect=$effect, padX=$padX, padY=$padY, scaleX=$scaleX, scaleY=$scaleY)"
        }
    }

    // Caller-owned mutable state; a backend instance is owned by a single
    // render operation and never shared between threads.
    private var recordingActive: Boolean = false

    override fun supports(primitives: FilterPrimitiveSet): Boolean {
        val supportedMask = FilterPrimitiveSet.FLAG_COLOR_MATRIX or
                FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR or
                FilterPrimitiveSet.FLAG_OFFSET
        return primitives.bits != 0 && (primitives.bits and supportedMask.inv()) == 0
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
    internal open fun tryBuildChain(
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
            filterNode.gpuChainScaleY == scaleY
        ) {
            return cached
        }

        var chain: RenderEffect? = null
        var previousResult: String? = null
        var first = true
        var padX = 0
        var padY = 0
        val resultEffects = mutableMapOf<String, RenderEffect>()

        filterNode.primitives.forEachElement { primitive ->
            val resultName = when (primitive) {
                is FeColorMatrixRenderNode -> primitive.sourceElement.result
                is FeGaussianBlurRenderNode -> primitive.sourceElement.result
                is FeOffsetRenderNode -> primitive.sourceElement.result
                else -> null
            }

            val input = when (primitive) {
                is FeColorMatrixRenderNode -> primitive.sourceElement.`in`
                is FeGaussianBlurRenderNode -> primitive.sourceElement.`in`
                is FeOffsetRenderNode -> primitive.sourceElement.`in`
                else -> null
            }

            val inputEffect = resolveEffect(input, previousResult, first, chain, resultEffects) ?: return null

            val effect = when (primitive) {
                is FeColorMatrixRenderNode -> {
                    val element = primitive.sourceElement
                    val colorFilter = android.graphics.ColorMatrixColorFilter(
                        buildColorMatrix(element.type, element.values)
                    )
                    if (inputEffect == IDENTITY_EFFECT) {
                        RenderEffect.createColorFilterEffect(colorFilter)
                    } else {
                        RenderEffect.createColorFilterEffect(colorFilter, inputEffect)
                    }
                }
                is FeGaussianBlurRenderNode -> {
                    val sigmaX = primitive.stdDeviationX * scaleX
                    val sigmaY = primitive.stdDeviationY * scaleY
                    if (sigmaX <= 0f && sigmaY <= 0f) {
                        inputEffect
                    } else {
                        // Transparent pad so CLAMP reads transparent black,
                        // matching the CPU kernel's pedestal (3 sigma rule).
                        padX = maxOf(padX, kotlin.math.ceil(sigmaX * 3f).toInt())
                        padY = maxOf(padY, kotlin.math.ceil(sigmaY * 3f).toInt())
                        
                        if (inputEffect == IDENTITY_EFFECT) {
                            RenderEffect.createBlurEffect(sigmaX, sigmaY,
                                android.graphics.Shader.TileMode.CLAMP)
                        } else {
                            RenderEffect.createBlurEffect(sigmaX, sigmaY, inputEffect,
                                android.graphics.Shader.TileMode.CLAMP)
                        }
                    }
                }
                is FeOffsetRenderNode -> {
                    val dx = filterPrimitiveLengthX(
                        length = primitive.sourceElement.dx,
                        primitiveUnitsAreUser = true,
                        primitiveScaleX = scaleX,
                        canvasScaleX = 1f
                    )
                    val dy = filterPrimitiveLengthY(
                        length = primitive.sourceElement.dy,
                        primitiveUnitsAreUser = true,
                        primitiveScaleY = scaleY,
                        canvasScaleY = 1f
                    )
                    if (dx == 0f && dy == 0f) {
                        inputEffect
                    } else {
                        if (inputEffect == IDENTITY_EFFECT) {
                            RenderEffect.createOffsetEffect(dx, dy)
                        } else {
                            RenderEffect.createOffsetEffect(dx, dy, inputEffect)
                        }
                    }
                }
                else -> return null
            }

            chain = effect
            previousResult = resultName
            first = false
            if (resultName != null) {
                resultEffects[resultName] = effect
            }
        }

        val result = chain ?: return null
        val built = Chain(result, padX, padY, scaleX, scaleY)
        filterNode.gpuChain = built
        filterNode.gpuChainVersion = filterNode.version
        filterNode.gpuChainScaleX = scaleX
        filterNode.gpuChainScaleY = scaleY
        return built
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
        val chain = obtainChain(filterNode, sx, sy, filterRegion, deviceRegion, boundingBox) ?: return null
        if (recordingActive) return null

        val padX = chain.padX
        val padY = chain.padY
        val contentVersion = filterNode.contentVersion
        var gpuNode = filterNode.gpuNode
        val valid = gpuNode != null &&
                gpuNode.hasDisplayList() &&
                filterNode.gpuSourceVersion == contentVersion &&
                filterNode.gpuFilterVersion == filterNode.version &&
                filterNode.gpuScaleX == sx && filterNode.gpuScaleY == sy &&
                filterNode.gpuWidth == width && filterNode.gpuHeight == height &&
                filterNode.gpuPadX == padX && filterNode.gpuPadY == padY
        if (!valid) {
            gpuNode = gpuNode ?: android.graphics.RenderNode("ksvg-filter-source")
            val recording = gpuNode.beginRecording(width + 2 * padX, height + 2 * padY)
            recording.translate(padX - deviceRegion.left, padY - deviceRegion.top)
            recording.concat(matrix)
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

    companion object {
        internal val IDENTITY_EFFECT = RenderEffect.createOffsetEffect(0f, 0f)
        internal val SOURCE_ALPHA_EFFECT = RenderEffect.createColorFilterEffect(
            android.graphics.ColorMatrixColorFilter(floatArrayOf(
                0f, 0f, 0f, 0f, 0f,
                0f, 0f, 0f, 0f, 0f,
                0f, 0f, 0f, 0f, 0f,
                0f, 0f, 0f, 1f, 0f
            ))
        )
    }
}
