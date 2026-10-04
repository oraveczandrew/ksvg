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

import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.collection.MutableScatterMap
import androidx.collection.MutableScatterSet
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.dom.filter.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeCompositeOperator
import hu.oandras.ksvg.dom.filter.FilterPrimitive
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
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.calculatePrimitiveRegion
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.filters.pipeline.effects.createColorMatrixShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createComponentTransferShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createCompositeShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createConvolveMatrixShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createDiffuseLightingShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createDisplacementMapShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createDropShadowEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createFloodShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createImageShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createLinearBlendShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createMorphologyShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createOffsetShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createSpecularLightingShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createTileShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createTurbulenceShaderEffect
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.resolvePrimitiveInputRegion
import hu.oandras.ksvg.render.resolveSingleInputRegion
import hu.oandras.ksvg.render.withSave
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.forEachElement
import kotlin.math.abs

/**
 * AGSL (RuntimeShader) GPU backend (API 33+, hardware canvas only).
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal class GpuFilterBackendApi33(renderContext: RenderContext) : GpuFilterBackend(renderContext) {

    // Chain-build scratch state. tryBuildChainImpl is reentrancy-free pure
    // construction on a thread-confined backend (the same confinement as the
    // inherited recordingActive/activeSlot fields), so these containers are
    // reused across chain builds instead of reallocated per build — a build
    // happens per frame for animated filters and on every scroll reposition.
    // Reset at the start of every build; only the containers are shared, values
    // retained by the built chain live their normal lives.
    // `boundResults` is deliberately a MutableScatterSet, not an ArraySet:
    // ArraySet.clear() drops its backing arrays while ScatterSet.clear() only
    // resets occupancy, so the scratch storage survives across builds.
    private val scratchResultShaders = MutableScatterMap<String, RuntimeShader>()
    private val scratchResultEffects = MutableScatterMap<String, RenderEffect>()
    private val scratchBoundResults = MutableScatterSet<String>()
    private val scratchResultRegions = MutableScatterMap<String, RectF>()
    private val scratchRegionRects = ArrayList<RectF>()
    private val scratchLastRegion = RectF()

    override val supportedMask: Int
        get() = FilterPrimitiveSet.FLAG_COLOR_MATRIX or
                FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR or
                FilterPrimitiveSet.FLAG_OFFSET or
                FilterPrimitiveSet.FLAG_MORPHOLOGY or
                FilterPrimitiveSet.FLAG_DIFFUSE_LIGHTING or
                FilterPrimitiveSet.FLAG_SPECULAR_LIGHTING or
                FilterPrimitiveSet.FLAG_COMPONENT_TRANSFER or
                FilterPrimitiveSet.FLAG_CONVOLVE_MATRIX or
                FilterPrimitiveSet.FLAG_DISPLACEMENT_MAP or
                FilterPrimitiveSet.FLAG_TURBULENCE or
                FilterPrimitiveSet.FLAG_BLEND or
                FilterPrimitiveSet.FLAG_COMPOSITE or
                FilterPrimitiveSet.FLAG_FLOOD or
                FilterPrimitiveSet.FLAG_MERGE or
                FilterPrimitiveSet.FLAG_TILE or
                FilterPrimitiveSet.FLAG_IMAGE or
                FilterPrimitiveSet.FLAG_DROP_SHADOW

    context(renderContext: RenderContext)
    override fun tryBuildChainImpl(
        filterNode: FilterRenderNode,
        scaleX: Float,
        scaleY: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        sx: Float,
        sy: Float,
        boundingBox: Box
    ): Chain? {
        var chain: RenderEffect? = null
        var previousResult: String? = null
        var first = true
        val resultShaders = scratchResultShaders.also { it.clear() }
        val resultEffects = scratchResultEffects.also { it.clear() }
        // Raw-shader input bindings for downstream in2/uMap references:
        // `resultShaders` holds RAW RuntimeShaders, but the
        // chain wires inputs at the EFFECT level
        // (`createRuntimeShaderEffect(...).chainWith(inputEffect)`). A raw
        // shader sampled via `setInputShader` (displacement `uMap`,
        // composite `uIn2`) therefore sees UNBOUND inputs (= transparent
        // black) unless bound here. `boundResults` names the results whose
        // raw shader evaluates standalone (generative, or raw-`uInput`
        // bound to another bound result); in2 references outside it
        // declines the chain instead of sampling transparent.
        var lastRawShader: RuntimeShader? = null
        var lastRawBound = false
        val boundResults = scratchBoundResults.also { it.clear() }

        // 1. Pre-calculate total padding for the entire chain
        val packed = calculateTotalPadding(filterNode, scaleX, scaleY, sx, sy)
        val totalPadX = (packed shr 32).toInt()
        val totalPadY = (packed and 0xFFFFFFFFL).toInt()

        // Track per-result user-space subregions so a primitive that omits x/y/width/height and
        // references a prior result defaults to that result's subregion (instead of the whole
        // filter region), matching the software backend. `lastResultRegion` starts as the filter
        // region (the first primitive's SourceGraphic default). Region value
        // RectFs come from the scratch-free list (recycled from the previous
        // build at the top of this function), so a chain build allocates none.
        val lastResultRegion = scratchLastRegion.also { it.set(filterRegion) }
        scratchResultRegions.forEach { _, region ->
            scratchRegionRects.add(region)
        }
        val hwResultRegion = scratchResultRegions.also { it.clear() }

        filterNode.primitives.forEachElement { primitive ->
            val sourceElement = primitive.sourceElement

            val resultName = sourceElement.result
            val input = sourceElement.`in`

            val inputEffect = resolveEffect(input, previousResult, first, chain, resultEffects) ?: return null

            val mergeNodes = (primitive as? FeMergeRenderNode)?.mergeNodes
            val effect = renderContext.rectFPool.withPooledObject { primitiveRegion ->
                renderContext.rectFPool.withPooledObject { inputUnion ->
                    // Compute the primitive's user-space subregion (defaulting to the input
                    // subregion(s) when x/y/width/height are omitted, per the SVG Filter Effects
                    // spec) and record it for later primitives that reference this result.
                    // Mirrors SoftwareFilterBackend, which does this for every primitive so the
                    // "previous primitive" region stays up to date across any primitive type.
                    computePrimitiveRegionAndRecord(
                        primitiveSource = primitive.sourceElement,
                        filterRegion = filterRegion,
                        unitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                        originalObjBBox = boundingBox,
                        resultName = resultName,
                        mergeNodes = mergeNodes,
                        input = input,
                        lastResultRegion = lastResultRegion,
                        hwResultRegion = hwResultRegion,
                        userRegion = primitiveRegion,
                        inputUnion = inputUnion,
                    )

                    when (primitive) {
                        is FeOffsetRenderNode -> {
                            val primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false
                            val dx = filterPrimitiveLengthX(
                                length = primitive.sourceElement.dx,
                                primitiveUnitsAreUser = primitiveUnitsAreUser,
                                primitiveScaleX = scaleX,
                                canvasScaleX = sx
                            )
                            val dy = filterPrimitiveLengthY(
                                length = primitive.sourceElement.dy,
                                primitiveUnitsAreUser = primitiveUnitsAreUser,
                                primitiveScaleY = scaleY,
                                canvasScaleY = sy
                            )
                            if (dx == 0f && dy == 0f) {
                                inputEffect
                            } else {
                                mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                                val (shader, offsetEffect) = createOffsetShaderEffect(
                                    offsetX = dx,
                                    offsetY = dy,
                                    primitiveRegion = primitiveRegion,
                                    filterRegion = filterRegion,
                                    scaleX = sx,
                                    scaleY = sy,
                                    padX = totalPadX,
                                    padY = totalPadY,
                                    inputUniformName = "uInput",
                                )
                                lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                                offsetEffect.chainWith(inputEffect)
                            }
                        }

                        is FeGaussianBlurRenderNode -> {
                            // Skia blur ignores the primitive subregion (no
                            // region guard on this path): an explicit
                            // x/y/width/height would silently blur the whole
                            // input (endpoint geometry_units precedent).
                            // Decline so software renders the clip instead.
                            val blurElement = primitive.sourceElement
                            if (blurElement.x != null || blurElement.y != null ||
                                blurElement.width != null || blurElement.height != null
                            ) {
                                return null
                            }
                            val sigmaX = primitive.stdDeviationX * scaleX
                            val sigmaY = primitive.stdDeviationY * scaleY
                            // Same pad architecture as the base backend (see
                            // drawFiltered): the recorded source carries a
                            // transparent pad, so CLAMP already implements
                            // `none` exactly, while a TileMode switch would
                            // replicate/tile the pad. Decline duplicate/wrap
                            // to software.
                            if (primitive.edgeMode != ConvolveMatrixEdgeMode.none &&
                                (sigmaX > 0f || sigmaY > 0f)
                            ) {
                                return null
                            }
                            if (sigmaX <= 0f && sigmaY <= 0f) {
                                inputEffect
                            } else {
                                lastRawShader = null
                                lastRawBound = false
                                RenderEffect.createBlurEffect(
                                    /* radiusX = */ skiaBlurRadiusForSigma(sigmaX),
                                    /* radiusY = */ skiaBlurRadiusForSigma(sigmaY),
                                    /* edgeTreatment = */ Shader.TileMode.CLAMP,
                                ).chainWith(inputEffect)
                            }
                        }

                        is FeMorphologyRenderNode -> {
                            val morph = primitive.sourceElement
                            val passes = createMorphologyShaderEffect(
                                erode = primitive.erode,
                                radiusX = morph.radiusX * scaleX,
                                radiusY = morph.radiusY * scaleY,
                                primitiveRegion = primitiveRegion,
                                filterRegion = filterRegion,
                                scaleX = scaleX,
                                scaleY = scaleY,
                                sx = sx,
                                sy = sy,
                                totalPadX = totalPadX,
                                totalPadY = totalPadY,
                                inputUniformName = "uInput",
                            ) ?: return null
                            lastRawBound = trackRawShaderBound(
                                shader = passes.headShader,
                                resultName = null,
                                input = input,
                                previousResult = previousResult,
                                first = first,
                                generative = false,
                                lastRawShader = lastRawShader,
                                lastRawBound = lastRawBound,
                                resultShaders = resultShaders,
                                boundResults = boundResults
                            ).also { lastRawShader = passes.tailShader }
                            if (resultName != null) {
                                resultShaders[resultName] = passes.tailShader
                                if (lastRawBound) boundResults += resultName
                            }
                            val headChained = passes.headEffect.chainWith(inputEffect)
                            if (passes.twoPass) passes.tailEffect.chainWith(headChained) else headChained
                        }

                        is FeColorMatrixRenderNode -> {
                            mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                            val (shader, colorMatrixEffect) = createColorMatrixShaderEffect(
                                node = primitive,
                                primitiveRegion = primitiveRegion,
                                inputUniformName = "uInput",
                            )
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            colorMatrixEffect.chainWith(inputEffect)
                        }

                        is FeDiffuseLightingRenderNode -> {
                            // kernelUnitLength needs downscale-light-upscale,
                            // which the GPU chain cannot represent: decline to SW.
                            if (hasKernelUnitLength(primitive.sourceElement.kernelUnitLengthX, primitive.sourceElement.kernelUnitLengthY)) {
                                return null
                            }
                            mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                            // No light source: the CPU passes the input through
                            // (`doLightingFilter`: `light ?: return inputBitmap`).
                            // Mirror with passthrough; the output raw form
                            // is the input raw form for downstream in2.
                            val boundDiffuseShader = lastRawShader
                            if (primitive.sourceElement.light == null) {
                                if (resultName != null && lastRawBound && boundDiffuseShader != null) {
                                    resultShaders[resultName] = boundDiffuseShader
                                    boundResults += resultName
                                }
                                inputEffect
                            } else {
                                val (shader, lightingEffect) = createDiffuseLightingShaderEffect(
                                    node = primitive,
                                    filterRegion = filterRegion,
                                    canvasScaleX = sx,
                                    canvasScaleY = sy,
                                    padX = totalPadX,
                                    padY = totalPadY,
                                    primitiveRegion = primitiveRegion,
                                    inputUniformName = "uInput",
                                ) ?: return null
                                lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }

                                lightingEffect.chainWith(inputEffect)
                            }
                        }

                        is FeSpecularLightingRenderNode -> {
                            // kernelUnitLength needs downscale-light-upscale,
                            // which the GPU chain cannot represent: decline to SW.
                            if (hasKernelUnitLength(primitive.sourceElement.kernelUnitLengthX, primitive.sourceElement.kernelUnitLengthY)) {
                                return null
                            }
                            mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                            // Terminal specular emits premultiplied output on the CPU
                            // path (full light color + intensity alpha); mirror it.
                            // No light source: input passthrough like diffuse.
                            val boundSpecularShader = lastRawShader
                            if (primitive.sourceElement.light == null) {
                                if (resultName != null && lastRawBound && boundSpecularShader != null) {
                                    resultShaders[resultName] = boundSpecularShader
                                    boundResults += resultName
                                }
                                inputEffect
                            } else {
                                val terminalPremult =
                                    primitive === filterNode.primitives.lastOrNull()
                                val (shader, lightingEffect) = createSpecularLightingShaderEffect(
                                    node = primitive,
                                    terminalPremult = terminalPremult,
                                    filterRegion = filterRegion,
                                    canvasScaleX = sx,
                                    canvasScaleY = sy,
                                    padX = totalPadX,
                                    padY = totalPadY,
                                    primitiveRegion = primitiveRegion,
                                    inputUniformName = "uInput",
                                ) ?: return null
                                lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }

                                lightingEffect.chainWith(inputEffect)
                            }
                        }

                        is FeComponentTransferRenderNode -> {
                            mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                            val (shader, transferEffect) = createComponentTransferShaderEffect(
                                primitive, primitiveRegion, "uInput",
                            )
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            transferEffect.chainWith(inputEffect)
                        }

                        is FeConvolveMatrixRenderNode -> {
                            val (shader, convolveEffect) = createConvolveMatrixShaderEffect(
                                node = primitive,
                                filterRegion = filterRegion,
                                scaleX = sx,
                                scaleY = sy,
                                padX = totalPadX,
                                padY = totalPadY,
                                inputUniformName = "uInput",
                            ) ?: return null
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            convolveEffect.chainWith(inputEffect)
                        }

                        is FeBlendRenderNode -> {
                            val blend = primitive.sourceElement
                            if (primitive.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB &&
                                primitive.mode != FeBlendMode.normal
                            ) {
                                // Linear-light blend runs linearized (like the
                                // arithmetic path); the BlendMode effect
                                // below is sRGB-only. Needs the backdrop as a raw
                                // shader: null in2 defaults to the previous result
                                // (spec), named in2 to a bound result — decline
                                // otherwise and let the (correct) software backend
                                // take the filter.
                                val in2Shader = resolveRawInputShader(blend.in2, lastRawShader, lastRawBound, resultShaders, boundResults) ?: return null
                                mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                                val (shader, blendEffect) = createLinearBlendShaderEffect(
                                    mode = primitive.mode.ordinal.toFloat(),
                                    in2Shader = in2Shader,
                                    primitiveRegion = primitiveRegion,
                                    inputUniformName = "uInput",
                                )
                                lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                                blendEffect.chainWith(inputEffect)
                            } else {
                                val in2Effect =
                                    resolveEffect(blend.in2, previousResult, first, chain, resultEffects) ?: return null
                                val mode = primitive.mode.toBlendMode() ?: return null
                                lastRawShader = null
                                lastRawBound = false

                                createBlendModeRenderEffect(
                                    dst = in2Effect,
                                    src = inputEffect,
                                    blendMode = mode
                                )
                            }
                        }

                        is FeCompositeRenderNode -> {
                            val composite = primitive.sourceElement
                            val in2Effect =
                                resolveEffect(composite.in2, previousResult, first, chain, resultEffects) ?: return null

                            if (composite.operator == FeCompositeOperator.arithmetic) {
                                // Linear-light arithmetic runs linearized;
                                // the PLUS fast path below is sRGB-only (raw
                                // tap addition), so linear always takes the
                                // shader even for PLUS coefficients.
                                val useLinear =
                                    primitive.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB
                                if (!useLinear && composite.k1 == 0f && composite.k2 == 1f && composite.k3 == 1f && composite.k4 == 0f) {
                                    lastRawShader = null
                                    lastRawBound = false
                                    createBlendModeRenderEffect(in2Effect, inputEffect, BlendMode.PLUS)
                                } else {
                                    // Null in2 defaults to the previous result
                                    // (spec): reuse its raw shader when bound,
                                    // decline otherwise.
                                    val in2Shader = resolveRawInputShader(composite.in2, lastRawShader, lastRawBound, resultShaders, boundResults) ?: return null
                                    mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                                    val (shader, compositeEffect) = createCompositeShaderEffect(
                                        k1 = composite.k1,
                                        k2 = composite.k2,
                                        k3 = composite.k3,
                                        k4 = composite.k4,
                                        useLinear = useLinear,
                                        primitiveRegion = primitiveRegion,
                                        in2Shader = in2Shader,
                                        inputUniformName = "uInput",
                                    )

                                    lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                                    compositeEffect.chainWith(inputEffect)
                                }
                            } else {
                                val mode = composite.operator.toBlendMode() ?: return null
                                lastRawShader = null
                                lastRawBound = false
                                createBlendModeRenderEffect(in2Effect, inputEffect, mode)
                            }
                        }

                        is FeDisplacementMapRenderNode -> {
                            // Null in2 defaults to the previous result (spec):
                            // reuse its raw shader when bound, decline
                            // otherwise. Bound gate like composite in2.
                            val mapShader = resolveRawInputShader(primitive.sourceElement.in2, lastRawShader, lastRawBound, resultShaders, boundResults) ?: return null
                            val (shader, displacementEffect) = createDisplacementMapShaderEffect(
                                node = primitive,
                                scaleX = scaleX,
                                scaleY = scaleY,
                                mapShader = mapShader,
                                inputUniformName = "uInput",
                            )
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            displacementEffect.chainWith(inputEffect)
                        }

                        is FeTurbulenceRenderNode -> {
                            // Terminal turbulence under linearRGB gets the linear->sRGB transfer
                            // (CPU unLinearizeBitmap equivalent); anything else stays linear.
                            val unlinearize = primitive === filterNode.primitives.lastOrNull() &&
                                filterNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB
                            val (shader, turbulenceEffect) = createTurbulenceShaderEffect(
                                node = primitive,
                                primitiveRegion = primitiveRegion,
                                filterRegion = filterRegion,
                                primitiveScaleX = scaleX,
                                primitiveScaleY = scaleY,
                                canvasScaleX = sx,
                                canvasScaleY = sy,
                                padX = totalPadX,
                                padY = totalPadY,
                                unlinearize = unlinearize,
                                primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                                boundingBox = boundingBox,
                                inputUniformName = "in_source",
                            )

                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, true, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            turbulenceEffect
                        }

                        is FeFloodRenderNode -> {
                            mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                            val color = renderContext.resolveFloodColor(primitive, filterNode.renderState.style)
                            val (shader, floodEffect) = createFloodShaderEffect(color, primitiveRegion, "uInput")
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, true, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            floodEffect
                        }

                        is FeMergeRenderNode -> {
                            var mergeEffect: RenderEffect? = null
                            primitive.mergeNodes.forEachElement { inputName ->
                                // A null node must reach `resolveEffect` as
                                // null (previous result, or SourceGraphic when
                                // the merge is first) — stringifying it to
                                // "SourceGraphic" here misroutes every null
                                // node of a non-first merge to the source.
                                val inputNodeEffect = resolveEffect(
                                    input = inputName,
                                    previousResult = previousResult,
                                    first = first,
                                    currentChain = chain,
                                    resultEffects = resultEffects
                                ) ?: return null
                                mergeEffect = if (mergeEffect == null) {
                                    inputNodeEffect
                                } else {
                                    createBlendModeRenderEffect(mergeEffect, inputNodeEffect, BlendMode.SRC_OVER)
                                }
                            }
                            lastRawShader = null
                            lastRawBound = false
                            mergeEffect
                        }

                        is FeImageRenderNode -> {
                            val (shader, imageEffect) = createImageShaderEffect(
                                node = primitive,
                                primitiveRegion = primitiveRegion,
                                filterRegion = filterRegion,
                                sx = sx,
                                sy = sy,
                                padX = totalPadX,
                                padY = totalPadY,
                                inputUniformName = "uInput",
                            ) ?: return null
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, true, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            imageEffect
                        }

                        is FeTileRenderNode -> {
                            // Transform user-space tile region to device-pixel space relative to the deviceRegion
                            mapPrimitiveToBufferSpace(primitiveRegion, filterRegion, sx, sy, totalPadX, totalPadY)

                            val (shader, tileEffect) = createTileShaderEffect(primitiveRegion, "uInput")
                            lastRawBound = trackRawShaderBound(shader, resultName, input, previousResult, first, false, lastRawShader, lastRawBound, resultShaders, boundResults).also { lastRawShader = shader }
                            tileEffect.chainWith(inputEffect)
                        }

                        is FeDropShadowRenderNode -> {
                            val shadowed = createDropShadowEffect(
                                node = primitive,
                                inputEffect = inputEffect,
                                primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                                primitiveScaleX = scaleX,
                                primitiveScaleY = scaleY,
                                canvasScaleX = sx,
                                canvasScaleY = sy,
                                baseStyle = filterNode.renderState.style,
                            ) ?: return null
                            lastRawShader = null
                            lastRawBound = false
                            createBlendModeRenderEffect(shadowed, inputEffect, BlendMode.SRC_OVER)
                        }

                        else -> return null
                    }
                }
            }

            chain = effect
            previousResult = resultName
            first = false
            if (resultName != null) {
                if (effect != null) {
                    resultEffects[resultName] = effect
                }
            }
        }

        val result = chain ?: return null
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

    private fun createBlendModeRenderEffect(
        dst: RenderEffect,
        src: RenderEffect,
        blendMode: BlendMode
    ): RenderEffect {
        val d = if (dst == IDENTITY_EFFECT) RenderEffect.createOffsetEffect(0f, 0f) else dst
        val s = if (src == IDENTITY_EFFECT) RenderEffect.createOffsetEffect(0f, 0f) else src
        return RenderEffect.createBlendModeEffect(d, s, blendMode)
    }

    /**
     * Remaps the primitive's user-space subregion into buffer space in
     * place: `(user - filterRegion.origin) * s + pad` (the CPU kernels
     * write the clip only). Shared by every region-guarded shader branch.
     */
    private fun mapPrimitiveToBufferSpace(
        primitiveRegion: RectF,
        filterRegion: RectF,
        sx: Float,
        sy: Float,
        padX: Int,
        padY: Int,
    ) {
        primitiveRegion.set(
            (primitiveRegion.left - filterRegion.left) * sx + padX,
            (primitiveRegion.top - filterRegion.top) * sy + padY,
            (primitiveRegion.right - filterRegion.left) * sx + padX,
            (primitiveRegion.bottom - filterRegion.top) * sy + padY
        )
    }

    /**
     * Resolves a secondary (`in2`/`uMap`) raw-shader operand: a null name
     * defaults to the previous result (spec) and reuses its raw shader when
     * bound, a named one to a bound result. Returns null when the chain must
     * be declined instead of sampling transparent. Shared by the linear
     * blend, arithmetic composite and displacement branches.
     */
    private fun resolveRawInputShader(
        name: String?,
        lastRawShader: RuntimeShader?,
        lastRawBound: Boolean,
        resultShaders: MutableScatterMap<String, RuntimeShader>,
        boundResults: MutableScatterSet<String>,
    ): RuntimeShader? {
        if (name == null) {
            if (!lastRawBound) return null
            return lastRawShader
        }
        if (name !in boundResults) return null
        return resultShaders[name]
    }

    /**
     * `kernelUnitLength` needs a downscale-filter-upscale sequence, which
     * the GPU chain cannot represent: the caller declines to software when
     * this returns true.
     */
    private fun hasKernelUnitLength(unitLengthX: Float, unitLengthY: Float): Boolean =
        unitLengthX != 0f || unitLengthY != 0f

    /**
     * Binds a raw shader's `uInput` to the previous bound result (or a named
     * dependency) and records named results for downstream references. Returns
     * whether the shader's input ended up bound.
     *
     * Deliberately a member function with an explicit loop state instead of a local
     * function: a local `fun` capturing the reassigned `lastRawShader` /
     * `lastRawBound` forces `Ref$ObjectRef` / `Ref$BooleanRef` wrappers per chain
     * build. Callers assign the returned flag and `shader` to their own locals
     * (inside inlined loops, so no wrappers there either).
     */
    private fun trackRawShaderBound(
        shader: RuntimeShader,
        resultName: String?,
        input: String?,
        previousResult: String?,
        first: Boolean,
        generative: Boolean,
        lastRawShader: RuntimeShader?,
        lastRawBound: Boolean,
        resultShaders: MutableScatterMap<String, RuntimeShader>,
        boundResults: MutableScatterSet<String>,
    ): Boolean {
        val bound = generative || when (input) {
            null if first -> false // SourceGraphic: no raw form
            "SourceGraphic", "SourceAlpha" -> false
            null, previousResult -> {
                val prev: RuntimeShader? = lastRawShader
                if (lastRawBound && prev != null) {
                    shader.setInputShader("uInput", prev)
                    true
                } else {
                    false
                }
            }

            else -> {
                val dep = resultShaders[input]
                if (dep != null && input in boundResults) {
                    shader.setInputShader("uInput", dep)
                    true
                } else {
                    false
                }
            }
        } // SourceGraphic: no raw form
        if (resultName != null) {
            resultShaders[resultName] = shader
            if (bound) boundResults += resultName
        }
        return bound
    }

    /**
     * Computes the primitive's user-space subregion (with an input-region defaulting per the SVG
     * Filter Effects spec) into [userRegion] and records it for later reference by primitives
     * that reference this result. The caller remaps [userRegion] to pixel space afterward.
     */
    context(renderContext: RenderContext)
    private fun computePrimitiveRegionAndRecord(
        primitiveSource: FilterPrimitive,
        filterRegion: RectF,
        unitsAreUser: Boolean,
        originalObjBBox: Box,
        resultName: String?,
        mergeNodes: List<String?>?,
        input: String?,
        lastResultRegion: RectF,
        hwResultRegion: MutableScatterMap<String, RectF>,
        userRegion: RectF,
        inputUnion: RectF,
    ) {
        val hasInput = if (mergeNodes != null) {
            resolvePrimitiveInputRegion(
                inputIds = mergeNodes,
                isMerge = true,
                standardFilterRegion = filterRegion,
                namedRegions = hwResultRegion,
                lastResultRegion = lastResultRegion,
                out = inputUnion,
            )
        } else {
            resolveSingleInputRegion(
                id = input,
                standardFilterRegion = filterRegion,
                namedRegions = hwResultRegion,
                lastResultRegion = lastResultRegion,
                out = inputUnion,
            )
        }
        calculatePrimitiveRegion(
            primitive = primitiveSource,
            filterRegion = filterRegion,
            unitsAreUser = unitsAreUser,
            originalObjBBox = originalObjBBox,
            outRect = userRegion,
            inputRegion = if (hasInput) inputUnion else null,
        )
        recordResultRegion(resultName, userRegion, lastResultRegion, hwResultRegion)
    }

    private fun recordResultRegion(
        resultName: String?,
        userRegion: RectF,
        lastResultRegion: RectF,
        hwResultRegion: MutableScatterMap<String, RectF>,
    ) {
        if (resultName != null) {
            val rec = hwResultRegion[resultName] ?: obtainRegionRect().also { hwResultRegion[resultName] = it }
            rec.set(userRegion)
        }
        lastResultRegion.set(userRegion)
    }

    /** Region-value scratch RectF, recycled across chain builds (see fields). */
    private fun obtainRegionRect(): RectF {
        val pooled = scratchRegionRects
        return if (pooled.isNotEmpty()) {
            pooled.removeAt(pooled.size - 1)
        } else {
            RectF()
        }
    }

    context(renderContext: RenderContext)
    override fun calculateTotalPadding(
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
                    expandX += primitive.stdDeviationX * scaleX * 5f
                    expandY += primitive.stdDeviationY * scaleY * 5f
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
                    val blurNode = primitive.blurNode
                    expandX += blurNode.stdDeviationX * scaleX * 5f
                    expandY += blurNode.stdDeviationY * scaleY * 5f
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
                            primitiveScaleY = scaleY,
                            canvasScaleY = sy
                        )
                    )
                }

                else -> {}
            }
        }

        val padX = (expandX + offsetX + 20f).ceilToInt()
        val padY = (expandY + offsetY + 20f).ceilToInt()

        return (padX.toLong() shl 32) or (padY.toLong() and 0xFFFFFFFFL)
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
        val slot = filterNode.gpuSlotFor(node)
        var chain = slot.gpuChain ?: return
        if (chain.deviceLeft != deviceRegion.left || chain.deviceTop != deviceRegion.top) {
            // Screen position changed (e.g., scroll): re-create chain to update absolute uniforms.
            with(renderContext) {
                chain = tryBuildChain(
                    element = node,
                    filterNode = filterNode,
                    scaleX = sx,
                    scaleY = sy,
                    filterRegion = filterRegion,
                    deviceRegion = deviceRegion,
                    sx = sx,
                    sy = sy,
                    boundingBox = boundingBox
                ) ?: return
            }
        }

        val gpuNode = slot.gpuNode ?: return
        GpuChainEvents.record(filterNode, GpuChainEvents.GPU)
        gpuNode.setRenderEffect(chain.effect)
        canvas.withSave {
            @Suppress("DEPRECATION")
            canvas.setMatrix(null)
            // Same region clip as Impl31.drawFiltered: the software backend composites
            // a region-sized bitmap, so framework effects must not leak outside.
            canvas.clipRect(deviceRegion)
            canvas.translate(deviceRegion.left - chain.padX, deviceRegion.top - chain.padY)
            canvas.drawRenderNode(gpuNode)
        }
    }

    companion object {
        @JvmSynthetic
        internal fun FeBlendMode.toBlendMode(): BlendMode? = when (this) {
            FeBlendMode.normal -> BlendMode.SRC_OVER
            FeBlendMode.multiply -> BlendMode.MULTIPLY
            FeBlendMode.screen -> BlendMode.SCREEN
            FeBlendMode.overlay -> BlendMode.OVERLAY
            FeBlendMode.darken -> BlendMode.DARKEN
            FeBlendMode.lighten -> BlendMode.LIGHTEN
            FeBlendMode.`color-dodge` -> BlendMode.COLOR_DODGE
            FeBlendMode.`color-burn` -> BlendMode.COLOR_BURN
            FeBlendMode.`hard-light` -> BlendMode.HARD_LIGHT
            FeBlendMode.`soft-light` -> BlendMode.SOFT_LIGHT
            FeBlendMode.difference -> BlendMode.DIFFERENCE
            FeBlendMode.exclusion -> BlendMode.EXCLUSION
            FeBlendMode.hue -> BlendMode.HUE
            FeBlendMode.saturation -> BlendMode.SATURATION
            FeBlendMode.color -> BlendMode.COLOR
            FeBlendMode.luminosity -> BlendMode.LUMINOSITY
        }

        @JvmSynthetic
        internal fun FeCompositeOperator.toBlendMode(): BlendMode? = when (this) {
            FeCompositeOperator.over -> BlendMode.SRC_OVER
            FeCompositeOperator.`in` -> BlendMode.SRC_IN
            FeCompositeOperator.out -> BlendMode.SRC_OUT
            FeCompositeOperator.atop -> BlendMode.SRC_ATOP
            FeCompositeOperator.xor -> BlendMode.XOR
            FeCompositeOperator.arithmetic -> null
        }
    }
}
