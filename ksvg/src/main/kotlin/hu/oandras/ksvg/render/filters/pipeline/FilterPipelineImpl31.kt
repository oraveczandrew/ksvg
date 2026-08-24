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

import android.graphics.RenderEffect
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.utils.forEachElement

/**
 * RenderEffect GPU backend (API 31+, hardware canvas only).
 *
 * Supports strictly linear single-input chains of feColorMatrix,
 * feGaussianBlur and feOffset (each primitive's `in` refers to the previous
 * result or is the implicit source). ColorMatrix maps 1:1 onto
 * [RenderEffect.createColorFilterEffect] (same [buildColorMatrix] as the CPU
 * path). GaussianBlur uses [RenderEffect.createBlurEffect] with CLAMP edge
 * mode; the caller must record the source with a transparent pad of
 * [Chain.padX]/[Chain.padY] device pixels on every side so the clamp reads
 * transparent black — matching the CPU kernel's transparent-black pedestal.
 * Offset maps to [RenderEffect.createOffsetEffect] with device-pixel deltas
 * resolved by the caller (CSSLength needs renderer context).
 *
 * Deliberately NOT claimed yet: two-input or canvas-drawn primitives
 * (Blend/Composite/Merge/Flood/Image), displacement, lighting.
 */
internal class FilterPipelineImpl31 : FilterBackend {

    /** Effect chain plus the transparent recording pad it requires. */
    internal class Chain internal constructor(
        @JvmField internal val effect: RenderEffect,
        @JvmField internal val padX: Int,
        @JvmField internal val padY: Int,
    )

    override fun supports(primitives: FilterPrimitiveSet): Boolean {
        val supportedMask = FilterPrimitiveSet.FLAG_COLOR_MATRIX or
                FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR or
                FilterPrimitiveSet.FLAG_OFFSET
        return primitives.bits != 0 && (primitives.bits and supportedMask.inv()) == 0
    }

    /**
     * Builds the whole-graph effect chain; null when the graph is not a
     * strict linear sequence of supported primitives.
     *
     * [scaleX]/[scaleY] are the CPU-path primitive scales (canvas scale for
     * userSpaceOnUse units, bounding-box based otherwise) used to convert
     * blur stdDeviation to device pixels; [resolveLength] resolves offset
     * CSSLengths to device pixels.
     */
    fun tryBuildChain(
            filterNode: FilterRenderNode,
            scaleX: Float,
            scaleY: Float,
            resolveLength: (CSSLength?, Boolean) -> Float,
    ): Chain? {
        var chain: RenderEffect? = null
        var previousResult: String? = null
        var first = true
        var padX = 0
        var padY = 0

        filterNode.primitives.forEachElement { primitive ->
            val effect = when (primitive) {
                is FeColorMatrixRenderNode -> {
                    val element = primitive.sourceElement
                    checkLinearInput(element.`in`, previousResult, first) ?: return null
                    previousResult = element.result
                    first = false
                    RenderEffect.createColorFilterEffect(
                        android.graphics.ColorMatrixColorFilter(
                            buildColorMatrix(element.type, element.values)
                        )
                    )
                }
                is FeGaussianBlurRenderNode -> {
                    checkLinearInput(primitive.sourceElement.`in`, previousResult, first) ?: return null
                    previousResult = primitive.sourceElement.result
                    first = false
                    val sigmaX = primitive.stdDeviationX * scaleX
                    val sigmaY = primitive.stdDeviationY * scaleY
                    if (sigmaX <= 0f && sigmaY <= 0f) {
                        null // matches the CPU path: identity when both sigmas are zero
                    } else {
                        // Transparent pad so CLAMP reads transparent black,
                        // matching the CPU kernel's pedestal (3 sigma rule).
                        padX = maxOf(padX, kotlin.math.ceil(sigmaX * 3f).toInt())
                        padY = maxOf(padY, kotlin.math.ceil(sigmaY * 3f).toInt())
                        RenderEffect.createBlurEffect(sigmaX, sigmaY,
                            android.graphics.Shader.TileMode.CLAMP)
                    }
                }
                is FeOffsetRenderNode -> {
                    checkLinearInput(primitive.sourceElement.`in`, previousResult, first) ?: return null
                    previousResult = primitive.sourceElement.result
                    first = false
                    val dx = resolveLength(primitive.sourceElement.dx, true)
                    val dy = resolveLength(primitive.sourceElement.dy, false)
                    if (dx == 0f && dy == 0f) null else RenderEffect.createOffsetEffect(dx, dy)
                }
                else -> return null
            }

            if (effect != null) {
                val previous = chain
                chain = if (previous == null) effect else RenderEffect.createChainEffect(effect, previous)
            }
        }

        val result = chain ?: return null
        return Chain(result, padX, padY)
    }

    private fun checkLinearInput(input: String?, previousResult: String?, first: Boolean): Unit? {
        if (first) {
            // First input may be implicit or the explicit source graphic.
            if (input != null && input != "SourceGraphic") return null
        } else {
            if (input == null || input != previousResult) return null
        }
        return Unit
    }

    override fun release() {}
}
