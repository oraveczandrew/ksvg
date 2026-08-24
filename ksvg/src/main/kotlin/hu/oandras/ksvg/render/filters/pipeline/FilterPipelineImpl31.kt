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
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.utils.forEachElement

/**
 * RenderEffect GPU backend (API 31+, hardware canvas only).
 *
 * First slice: strictly linear feColorMatrix chains (each primitive's `in`
 * refers to the previous result or is the implicit source). These map 1:1 onto
 * [RenderEffect.createColorFilterEffect] because the CPU path composes exactly
 * the same ColorMatrixColorFilter — pixel parity by construction.
 *
 * Deliberately NOT claimed yet (falls back to the CPU backend):
 * - GaussianBlur: CPU path pads transparent black, createBlurEffect(CLAMP)
 *   clamps edge pixels -> halo differences until pad handling is added;
 * - Offset: needs CSSLength resolution with renderer context (planned);
 * - everything two-input or canvas-drawn (Blend/Composite/Merge/Flood/Image).
 */
@RequiresApi(Build.VERSION_CODES.S)
internal class FilterPipelineImpl31 : FilterBackend {

    override fun supports(primitives: FilterPrimitiveSet): Boolean {
        val supportedMask = FilterPrimitiveSet.FLAG_COLOR_MATRIX
        return primitives.bits != 0 && (primitives.bits and supportedMask.inv()) == 0
    }

    /**
     * Builds the whole-graph effect chain for a strict linear ColorMatrix
     * sequence; null otherwise. Cheap object graph — rebuilt per frame until
     * the node-keyed effect cache lands.
     */
    fun tryBuildChain(filterNode: FilterRenderNode): RenderEffect? {
        var chain: RenderEffect? = null
        var previousResult: String? = null
        var first = true

        filterNode.primitives.forEachElement { primitive ->
            if (primitive !is FeColorMatrixRenderNode) return null
            val element = primitive.sourceElement

            val input = element.`in`
            if (first) {
                // First input may be implicit or the explicit source graphic.
                if (input != null && input != "SourceGraphic") return null
            } else {
                if (input == null || input != previousResult) return null
            }

            val effect = RenderEffect.createColorFilterEffect(
                android.graphics.ColorMatrixColorFilter(
                    buildColorMatrix(element.type, element.values)
                )
            )
            chain = if (chain == null) effect else RenderEffect.createChainEffect(effect, chain!!)
            previousResult = element.result
            first = false
        }

        return chain
    }

    override fun release() {}
}
