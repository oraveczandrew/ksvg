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
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.collection.ArrayMap
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeCompositeOperator
import hu.oandras.ksvg.dom.filter.FeStitchTiles
import hu.oandras.ksvg.dom.filter.FilterPrimitive
import hu.oandras.ksvg.render.ALPHA_MATRIX_COLOR_FILTER
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
import hu.oandras.ksvg.render.resolvePrimitiveInputRegion
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.filters.pipeline.effects.createArithmeticCompositeShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createColorMatrixShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createComponentTransferShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createConvolveMatrixShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createDiffuseLightingShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createDisplacementMapShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createFloodShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createMorphologyDilateShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createMorphologyErodeShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createSpecularLightingShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createTileShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.effects.createTurbulenceShaderEffect
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.withSave
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.forEachElement
import kotlin.math.abs

/**
 * AGSL (RuntimeShader) GPU backend (API 33+, hardware canvas only).
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal class FilterPipelineImpl33(renderContext: RenderContext) : FilterPipelineImpl31(renderContext) {

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
        val resultShaders = ArrayMap<String, RuntimeShader>()
        val resultEffects = ArrayMap<String, RenderEffect>()

        // 1. Pre-calculate total padding for the entire chain
        val packed = calculateTotalPadding(filterNode, scaleX, scaleY, sx, sy)
        val totalPadX = (packed shr 32).toInt()
        val totalPadY = (packed and 0xFFFFFFFFL).toInt()

        // Track per-result user-space subregions so a primitive that omits x/y/width/height and
        // references a prior result defaults to that result's subregion (instead of the whole
        // filter region), matching the software backend. `lastResultRegion` starts as the filter
        // region (the first primitive's SourceGraphic default).
        val lastResultRegion = RectF(filterRegion)
        val hwResultRegion = ArrayMap<String, RectF>()

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
                        inputs = mergeNodes ?: listOf(input),
                        isMerge = mergeNodes != null,
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
                                RenderEffect.createOffsetEffect(dx, dy).chainWith(inputEffect)
                            }
                        }

                        is FeGaussianBlurRenderNode -> {
                            val sigmaX = primitive.stdDeviationX * scaleX
                            val sigmaY = primitive.stdDeviationY * scaleY
                            if (sigmaX <= 0f && sigmaY <= 0f) {
                                inputEffect
                            } else {
                                RenderEffect.createBlurEffect(
                                    skiaBlurRadiusForSigma(sigmaX), skiaBlurRadiusForSigma(sigmaY),
                                    Shader.TileMode.CLAMP,
                                ).chainWith(inputEffect)
                            }
                        }

                        is FeMorphologyRenderNode -> {
                            val morph = primitive.sourceElement
                            val radX = morph.radiusX * scaleX
                            val radY = morph.radiusY * scaleY
                            // Interior rule (matches the CPU kernel's write window).
                            // Erode writes only [max(clip, r), min(clip,
                            // size - r)) — everything else stays transparent.
                            // Dilate instead covers the full clip rect with
                            // clamped windows, so it gets the unshrunk clip.
                            // Coordinates reuse the lighting mapping into
                            // fragCoord space.
                            val rxWs = if (scaleX != 0f) radX * (sx / scaleX) else 0f
                            val ryWs = if (scaleY != 0f) radY * (sy / scaleY) else 0f
                            val clipL = (primitiveRegion.left - filterRegion.left) * sx + totalPadX
                            val clipT = (primitiveRegion.top - filterRegion.top) * sy + totalPadY
                            val clipR = (primitiveRegion.right - filterRegion.left) * sx + totalPadX
                            val clipB = (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            val inputR = totalPadX + filterRegion.width() * sx
                            val inputB = totalPadY + filterRegion.height() * sy
                            val (shader, morphEffect) = if (primitive.erode) {
                                createMorphologyErodeShaderEffect(
                                    radX,
                                    radY,
                                    maxOf(clipL, totalPadX + rxWs),
                                    maxOf(clipT, totalPadY + ryWs),
                                    minOf(clipR, inputR - rxWs),
                                    minOf(clipB, inputB - ryWs),
                                    "uInput",
                                )
                            } else {
                                createMorphologyDilateShaderEffect(
                                    radX,
                                    radY,
                                    clipL,
                                    clipT,
                                    clipR,
                                    clipB,
                                    "uInput",
                                )
                            }
                            resultShaders[resultName ?: ""] = shader
                            morphEffect.chainWith(inputEffect)
                        }

                        is FeColorMatrixRenderNode -> {
                            val colorMatrix = primitive.sourceElement
                            val matrix = buildColorMatrix(colorMatrix.type, colorMatrix.values)
                            val (shader, colorMatrixEffect) = createColorMatrixShaderEffect(matrix.array, "uInput")
                            resultShaders[resultName ?: ""] = shader
                            colorMatrixEffect.chainWith(inputEffect)
                        }

                        is FeDiffuseLightingRenderNode -> {
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val (shader, lightingEffect) = createDiffuseLightingShaderEffect(
                                primitive, filterRegion, sx, sy, totalPadX, totalPadY, primitiveRegion, "uInput",
                            ) ?: return null

                            resultShaders[resultName ?: ""] = shader
                            lightingEffect.chainWith(inputEffect)
                        }

                        is FeSpecularLightingRenderNode -> {
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            // Terminal specular emits premultiplied output on the CPU
                            // path (full light color + intensity alpha); mirror it.
                            val terminalPremult =
                                primitive === filterNode.primitives.lastOrNull()
                            val (shader, lightingEffect) = createSpecularLightingShaderEffect(
                                primitive, terminalPremult,
                                filterRegion, sx, sy, totalPadX, totalPadY, primitiveRegion, "uInput",
                            ) ?: return null

                            resultShaders[resultName ?: ""] = shader
                            lightingEffect.chainWith(inputEffect)
                        }

                        is FeComponentTransferRenderNode -> {
                            // Map to buffer space: (user - filterRegion.left) * sx + padX
                            // (the CPU kernel writes the clip only).
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val (shader, transferEffect) = createComponentTransferShaderEffect(
                                primitive, primitiveRegion, "uInput",
                            )
                            resultShaders[resultName ?: ""] = shader
                            transferEffect.chainWith(inputEffect)
                        }

                        is FeConvolveMatrixRenderNode -> {
                            val (shader, convolveEffect) = createConvolveMatrixShaderEffect(
                                primitive,
                                filterRegion,
                                sx,
                                sy,
                                totalPadX,
                                totalPadY,
                                "uInput",
                            ) ?: return null
                            resultShaders[resultName ?: ""] = shader
                            convolveEffect.chainWith(inputEffect)
                        }

                        is FeBlendRenderNode -> {
                            val blend = primitive.sourceElement
                            val in2Effect =
                                resolveEffect(blend.in2, previousResult, first, chain, resultEffects) ?: return null
                            val mode = primitive.mode.toBlendMode() ?: return null

                            createBlendModeRenderEffect(in2Effect, inputEffect, mode)
                        }

                        is FeCompositeRenderNode -> {
                            val composite = primitive.sourceElement
                            val in2Effect =
                                resolveEffect(composite.in2, previousResult, first, chain, resultEffects) ?: return null

                            if (composite.operator == FeCompositeOperator.arithmetic) {
                                // Linear-light arithmetic has no GPU support (the
                                // shader computes on raw taps, while the CPU
                                // linearizes via LUTs): decline the chain so the
                                // software reference renders instead of silently
                                // wrong clamps (round-B fallback coverage in
                                // GpuArithmeticCompositeCorpusParityTest).
                                if (primitive.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB) {
                                    return null
                                }
                                if (composite.k1 == 0f && composite.k2 == 1f && composite.k3 == 1f && composite.k4 == 0f) {
                                    createBlendModeRenderEffect(in2Effect, inputEffect, BlendMode.PLUS)
                                } else {
                                    val in2Shader = composite.in2?.let { resultShaders[it] }
                                    if (in2Shader != null) {
                                        // Map to buffer space: (user - filterRegion.left) * sx + padX
                                        // (the CPU kernel writes the clip only).
                                        primitiveRegion.set(
                                            (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                            (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                            (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                            (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                                        )

                                        val (shader, compositeEffect) = createArithmeticCompositeShaderEffect(
                                            composite.k1,
                                            composite.k2,
                                            composite.k3,
                                            composite.k4,
                                            primitiveRegion,
                                            in2Shader,
                                            "uInput",
                                        )

                                        resultShaders[resultName ?: ""] = shader
                                        compositeEffect.chainWith(inputEffect)
                                    } else {
                                        return null
                                    }
                                }
                            } else {
                                val mode = composite.operator.toBlendMode() ?: return null
                                createBlendModeRenderEffect(in2Effect, inputEffect, mode)
                            }
                        }

                        is FeDisplacementMapRenderNode -> {
                            val disp = primitive.sourceElement
                            val mapShader = resultShaders[disp.in2] ?: return null
                            val (shader, displacementEffect) = createDisplacementMapShaderEffect(
                                primitive, scaleX, scaleY, mapShader, "uInput",
                            )
                            resultShaders[resultName ?: ""] = shader
                            displacementEffect.chainWith(inputEffect)
                        }

                        is FeTurbulenceRenderNode -> {
                            // Map to buffer space: (user - filterRegion.left) * sx + padX
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            // stitchTiles="stitch" has no GPU support (the
                            // shader hardcodes uTilePeriod=0 = no stitching and
                            // would silently compute the wrong tile field):
                            // decline the chain so the software reference
                            // renders instead (round-B fallback coverage in
                            // GpuTurbulenceCorpusParityTest).
                            if (primitive.sourceElement.stitchTiles != FeStitchTiles.noStitch) {
                                return null
                            }

                            // Terminal turbulence under linearRGB gets the linear->sRGB transfer
                            // (CPU unLinearizeBitmap equivalent); anything else stays linear.
                            val unlinearize = primitive === filterNode.primitives.lastOrNull() &&
                                filterNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB
                            val primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false
                            val (shader, turbulenceEffect) = createTurbulenceShaderEffect(
                                node = primitive,
                                primitiveScaleX = scaleX,
                                primitiveScaleY = scaleY,
                                filterRegion = filterRegion,
                                canvasScaleX = sx,
                                canvasScaleY = sy,
                                padX = totalPadX,
                                padY = totalPadY,
                                unlinearize = unlinearize,
                                primitiveUnitsAreUser = primitiveUnitsAreUser,
                                boundingBox = boundingBox,
                                primitiveRegion = primitiveRegion,
                                inputUniformName = "in_source",
                            )

                            resultShaders[resultName ?: ""] = shader
                            turbulenceEffect
                        }

                        is FeFloodRenderNode -> {
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val color = renderContext.resolveFloodColor(primitive, filterNode.renderState.style)
                            val (shader, floodEffect) = createFloodShaderEffect(color, primitiveRegion, "uInput")
                            resultShaders[resultName ?: ""] = shader
                            floodEffect
                        }

                        is FeMergeRenderNode -> {
                            var mergeEffect: RenderEffect? = null
                            primitive.mergeNodes.forEach { inputName ->
                                val inputNodeEffect =
                                    resolveEffect(
                                        inputName ?: "SourceGraphic",
                                        previousResult,
                                        first,
                                        chain,
                                        resultEffects
                                    )
                                        ?: return null
                                mergeEffect = if (mergeEffect == null) {
                                    inputNodeEffect
                                } else {
                                    createBlendModeRenderEffect(mergeEffect, inputNodeEffect, BlendMode.SRC_OVER)
                                }
                            }
                            mergeEffect
                        }

                        is FeTileRenderNode -> {
                            // Transform user-space tile region to device-pixel space relative to the deviceRegion
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val (shader, tileEffect) = createTileShaderEffect(primitiveRegion, "uInput")
                            resultShaders[resultName ?: ""] = shader
                            tileEffect.chainWith(inputEffect)
                        }

                        is FeDropShadowRenderNode -> {
                            val alphaEffect = if (inputEffect == IDENTITY_EFFECT) {
                                SOURCE_ALPHA_EFFECT
                            } else {
                                RenderEffect.createColorFilterEffect(
                                    ALPHA_MATRIX_COLOR_FILTER,
                                    inputEffect
                                )
                            }

                            val sigmaX = primitive.blurNode.stdDeviationX * scaleX
                            val sigmaY = primitive.blurNode.stdDeviationY * scaleY
                            val blurredEffect = if (sigmaX > 0f || sigmaY > 0f) {
                                RenderEffect.createBlurEffect(
                                    skiaBlurRadiusForSigma(sigmaX), skiaBlurRadiusForSigma(sigmaY),
                                    alphaEffect, Shader.TileMode.CLAMP,
                                )
                            } else {
                                alphaEffect
                            }

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
                            val offsetEffect = RenderEffect.createOffsetEffect(dx, dy, blurredEffect)

                            val floodColor = renderContext.resolveFloodColor(primitive, filterNode.renderState.style)
                            val coloredShadowEffect = RenderEffect.createColorFilterEffect(
                                PorterDuffColorFilter(floodColor, android.graphics.PorterDuff.Mode.SRC_IN),
                                offsetEffect
                            )

                            createBlendModeRenderEffect(coloredShadowEffect, inputEffect, BlendMode.SRC_OVER)
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
     * Computes the primitive's user-space subregion (with input-region defaulting per the SVG
     * Filter Effects spec) into [userRegion] and records it for later reference by primitives
     * that reference this result. The caller remaps [userRegion] to pixel space afterwards.
     */
    context(renderContext: RenderContext)
    private fun computePrimitiveRegionAndRecord(
        primitiveSource: FilterPrimitive,
        filterRegion: RectF,
        unitsAreUser: Boolean,
        originalObjBBox: Box,
        resultName: String?,
        inputs: List<String?>,
        isMerge: Boolean,
        lastResultRegion: RectF,
        hwResultRegion: ArrayMap<String, RectF>,
        userRegion: RectF,
        inputUnion: RectF,
    ) {
        val hasInput = resolvePrimitiveInputRegion(
            inputIds = inputs,
            isMerge = isMerge,
            standardFilterRegion = filterRegion,
            namedRegion = { id -> id?.let { hwResultRegion[it] } },
            lastResultRegion = lastResultRegion,
            out = inputUnion,
        )
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
        hwResultRegion: ArrayMap<String, RectF>,
    ) {
        if (resultName != null) {
            val rec = hwResultRegion[resultName] ?: RectF().also { hwResultRegion[resultName] = it }
            rec.set(userRegion)
        }
        lastResultRegion.set(userRegion)
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
                    expandX += primitive.blurNode.stdDeviationX * scaleX * 5f
                    expandY += primitive.blurNode.stdDeviationY * scaleY * 5f
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
        var chain = filterNode.gpuChain ?: return
        if (chain.deviceLeft != deviceRegion.left || chain.deviceTop != deviceRegion.top) {
            // Screen position changed (e.g. scroll): re-create chain to update absolute uniforms.
            with(renderContext) {
                chain = tryBuildChain(
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

        val gpuNode = filterNode.gpuNode ?: return
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
        private fun FeBlendMode.toBlendMode(): BlendMode? = when (this) {
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

        private fun FeCompositeOperator.toBlendMode(): BlendMode? = when (this) {
            FeCompositeOperator.over -> BlendMode.SRC_OVER
            FeCompositeOperator.`in` -> BlendMode.SRC_IN
            FeCompositeOperator.out -> BlendMode.SRC_OUT
            FeCompositeOperator.atop -> BlendMode.SRC_ATOP
            FeCompositeOperator.xor -> BlendMode.XOR
            FeCompositeOperator.arithmetic -> null
        }
    }
}
