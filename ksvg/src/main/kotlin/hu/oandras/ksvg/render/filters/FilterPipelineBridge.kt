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

package hu.oandras.ksvg.render.filters

import hu.oandras.ksvg.filtering.pipeline.FilterGraphInfo
import hu.oandras.ksvg.filtering.pipeline.FilterPrimitiveSet
import hu.oandras.ksvg.render.FilterRenderNode
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
import hu.oandras.ksvg.utils.forEachElement

/**
 * Bridges the `:ksvg`-internal render-node types to the capability bit-set of
 * the `:filtering` pipeline. Walks the primitive list exactly once; allocates
 * nothing (value-class bits only).
 */
internal fun FilterPrimitiveSet.Companion.collect(filterNode: FilterRenderNode): FilterPrimitiveSet {
    var bits = 0
    filterNode.primitives.forEachElement { primitive ->
        bits = bits or flagOf(primitive)
    }
    return FilterPrimitiveSet(bits)
}

internal fun filterGraphInfo(filterNode: FilterRenderNode): FilterGraphInfo {
    val set = FilterPrimitiveSet.collect(filterNode)
    return object : FilterGraphInfo {
        override val primitives: FilterPrimitiveSet = set
    }
}

private fun flagOf(primitive: Any?): Int = when (primitive) {
    is FeFloodRenderNode -> FilterPrimitiveSet.FLAG_FLOOD
    is FeBlendRenderNode -> FilterPrimitiveSet.FLAG_BLEND
    is FeTileRenderNode -> FilterPrimitiveSet.FLAG_TILE
    is FeDropShadowRenderNode -> FilterPrimitiveSet.FLAG_DROP_SHADOW
    is FeGaussianBlurRenderNode -> FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR
    is FeColorMatrixRenderNode -> FilterPrimitiveSet.FLAG_COLOR_MATRIX
    is FeOffsetRenderNode -> FilterPrimitiveSet.FLAG_OFFSET
    is FeMergeRenderNode -> FilterPrimitiveSet.FLAG_MERGE
    is FeConvolveMatrixRenderNode -> FilterPrimitiveSet.FLAG_CONVOLVE_MATRIX
    is FeMorphologyRenderNode -> FilterPrimitiveSet.FLAG_MORPHOLOGY
    is FeComponentTransferRenderNode -> FilterPrimitiveSet.FLAG_COMPONENT_TRANSFER
    is FeCompositeRenderNode -> FilterPrimitiveSet.FLAG_COMPOSITE
    is FeTurbulenceRenderNode -> FilterPrimitiveSet.FLAG_TURBULENCE
    is FeDisplacementMapRenderNode -> FilterPrimitiveSet.FLAG_DISPLACEMENT_MAP
    is FeDiffuseLightingRenderNode -> FilterPrimitiveSet.FLAG_DIFFUSE_LIGHTING
    is FeSpecularLightingRenderNode -> FilterPrimitiveSet.FLAG_SPECULAR_LIGHTING
    is FeImageRenderNode -> FilterPrimitiveSet.FLAG_IMAGE
    else -> 0
}
