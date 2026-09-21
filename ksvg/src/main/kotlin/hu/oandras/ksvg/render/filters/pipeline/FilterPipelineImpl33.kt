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
import android.graphics.BitmapShader
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
import hu.oandras.ksvg.dom.COLOR_WHITE
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.filter.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeCompositeOperator
import hu.oandras.ksvg.dom.filter.FeDistantLight
import hu.oandras.ksvg.dom.filter.FePointLight
import hu.oandras.ksvg.dom.filter.FeSpotLight
import hu.oandras.ksvg.dom.filter.FeTurbulenceType
import hu.oandras.ksvg.dom.filter.FilterPrimitive
import hu.oandras.ksvg.dom.filter.Lighting
import hu.oandras.ksvg.dom.style.ColorValue
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
import hu.oandras.ksvg.render.FilterPrimitiveRenderNode
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.RenderNode
import hu.oandras.ksvg.render.RendererState
import hu.oandras.ksvg.render.calculatePrimitiveRegion
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.resolvePrimitiveInputRegion
import hu.oandras.ksvg.dom.filter.ColorInterpolation
import hu.oandras.ksvg.filtering.ColorLuts
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.filters.buildTransferLutTables
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.filters.pipeline.shaders.COLOR_MATRIX_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.COMPONENT_TRANSFER_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.COMPOSITE_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.CONVOLVE_MATRIX_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.DISPLACEMENT_MAP_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.FLOOD_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.LIGHTING_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.TILE_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.TURBULENCE_SHADER
import hu.oandras.ksvg.render.filters.pipeline.shaders.createMorphologyDilateShaderEffect
import hu.oandras.ksvg.render.filters.pipeline.shaders.createMorphologyErodeShaderEffect
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.render.withSave
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

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
                            val shader = RuntimeShader(COLOR_MATRIX_SHADER)
                            shader.setFloatUniform("uMatrix", matrix.array)
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
                        }

                        is FeDiffuseLightingRenderNode -> {
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val shader = buildLightingShader(
                                primitive, false, terminalPremult = false,
                            ) ?: return null
                            shader.setFloatUniform("uUserLeftTop", filterRegion.left, filterRegion.top)
                            shader.setFloatUniform("uInvCanvasScale", 1f / sx, 1f / sy)
                            shader.setFloatUniform("uOffset", totalPadX.toFloat(), totalPadY.toFloat())
                            shader.setRectFUniform("uPrimitiveRegion", primitiveRegion)

                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
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
                            val shader = buildLightingShader(
                                primitive, true, terminalPremult,
                            ) ?: return null
                            shader.setFloatUniform("uUserLeftTop", filterRegion.left, filterRegion.top)
                            shader.setFloatUniform("uInvCanvasScale", 1f / sx, 1f / sy)
                            shader.setFloatUniform("uOffset", totalPadX.toFloat(), totalPadY.toFloat())
                            shader.setFloatUniform(
                                "uPrimitiveRegion",
                                primitiveRegion.left, primitiveRegion.top,
                                primitiveRegion.right, primitiveRegion.bottom
                            )

                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
                        }

                        is FeComponentTransferRenderNode -> {
                            val shader = buildComponentTransferShader(primitive)
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
                        }

                        is FeConvolveMatrixRenderNode -> {
                            val shader = buildConvolveMatrixShader(
                                primitive,
                                filterRegion,
                                sx,
                                sy,
                                totalPadX,
                                totalPadY,
                            ) ?: return null
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
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
                                if (composite.k1 == 0f && composite.k2 == 1f && composite.k3 == 1f && composite.k4 == 0f) {
                                    createBlendModeRenderEffect(in2Effect, inputEffect, BlendMode.PLUS)
                                } else {
                                    val in2Shader = composite.in2?.let { resultShaders[it] }
                                    if (in2Shader != null) {
                                        val shader = RuntimeShader(COMPOSITE_SHADER)
                                        shader.setInputShader("uIn2", in2Shader)
                                        shader.setIntUniform("uOperator", 5)
                                        shader.setFloatUniform(
                                            "uK",
                                            composite.k1,
                                            composite.k2,
                                            composite.k3,
                                            composite.k4
                                        )

                                        resultShaders[resultName ?: ""] = shader
                                        RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
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
                            val shader = buildDisplacementMapShader(primitive, scaleX, scaleY)
                            shader.setInputShader("uMap", mapShader)
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
                        }

                        is FeTurbulenceRenderNode -> {
                            // Map to buffer space: (user - filterRegion.left) * sx + padX
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val shader = buildTurbulenceShader(
                                node = primitive,
                                pScaleX = scaleX,
                                pScaleY = scaleY,
                                filterRegion = filterRegion,
                                canvasScaleX = sx,
                                canvasScaleY = sy,
                                padX = totalPadX,
                                padY = totalPadY,
                                filterNode = filterNode,
                                boundingBox = boundingBox,
                            )
                            shader.setFloatUniform(
                                "uPrimitiveRegion",
                                primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom
                            )

                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "in_source")
                        }

                        is FeFloodRenderNode -> {
                            primitiveRegion.set(
                                (primitiveRegion.left - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.top - filterRegion.top) * sy + totalPadY,
                                (primitiveRegion.right - filterRegion.left) * sx + totalPadX,
                                (primitiveRegion.bottom - filterRegion.top) * sy + totalPadY
                            )

                            val color = renderContext.resolveFloodColor(primitive, filterNode.renderState.style)
                            val shader = RuntimeShader(FLOOD_SHADER)
                            shader.setColorUniform("uColor", color)
                            shader.setFloatUniform(
                                "uPrimitiveRegion",
                                primitiveRegion.left, primitiveRegion.top, primitiveRegion.right, primitiveRegion.bottom
                            )
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput")
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

                            val shader = RuntimeShader(TILE_SHADER)
                            shader.setRectFUniform("uRect", primitiveRegion)
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
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

    private fun RuntimeShader.setRectFUniform(name: String, rect: RectF) {
        setFloatUniform(name, rect.left, rect.top, rect.right, rect.bottom)
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

    private fun buildLightingShader(
        node: FilterPrimitiveRenderNode<*>,
        isSpecular: Boolean,
        terminalPremult: Boolean,
    ): RuntimeShader? {
        val shader = RuntimeShader(LIGHTING_SHADER)
        val light: Lighting?
        val surfaceScale: Float
        val constant: Float
        val exponent: Float
        val baseStyle = node.sourceElement.baseStyle
        val styleColor = ((baseStyle?.lightingColor ?: baseStyle?.color) as? ColorValue)?.value ?: COLOR_WHITE

        when (node) {
            is FeDiffuseLightingRenderNode -> {
                val diff = node.sourceElement
                light = diff.light
                surfaceScale = diff.surfaceScale
                constant = diff.diffuseConstant
                exponent = 1f
            }

            is FeSpecularLightingRenderNode -> {
                val spec = node.sourceElement
                light = spec.light
                surfaceScale = spec.surfaceScale
                constant = spec.specularConstant
                exponent = spec.specularExponent
            }

            else -> {
                return null
            }
        }

        if (light == null) return null

        shader.setFloatUniform("uSurfaceScale", surfaceScale)
        shader.setFloatUniform("uConstant", constant)
        shader.setFloatUniform("uExponent", exponent)
        // Exact sRGB->linear table lookup (same tables as the CPU kernel);
        // the linearized color feeds the useLinear path, the raw color the
        // terminal-specular premultiplied output (which skips the EOTF).
        val useLinear = node.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB
        val lut = ColorLuts.SRGB_TO_LINEAR
        val linR = lut[styleColor.red].toFloat()
        val linG = lut[styleColor.green].toFloat()
        val linB = lut[styleColor.blue].toFloat()
        if (useLinear) {
            shader.setFloatUniform("uLightColor", linR / 255f, linG / 255f, linB / 255f)
        } else {
            shader.setFloatUniform(
                "uLightColor",
                styleColor.red / 255f, styleColor.green / 255f, styleColor.blue / 255f,
            )
        }
        shader.setFloatUniform(
            "uLightColorRaw",
            styleColor.red / 255f, styleColor.green / 255f, styleColor.blue / 255f,
        )
        shader.setIntUniform("uUseLinear", if (useLinear) 1 else 0)
        shader.setIntUniform("uTerminalPremult", if (terminalPremult) 1 else 0)
        shader.setIntUniform("uIsSpecular", if (isSpecular) 1 else 0)

        when (light) {
            is FeDistantLight -> {
                shader.setIntUniform("uLightType", 0)
                val azimuthRad = Math.toRadians(light.azimuth.toDouble())
                val elevationRad = Math.toRadians(light.elevation.toDouble())
                val lx = cos(azimuthRad) * cos(elevationRad)
                val ly = sin(azimuthRad) * cos(elevationRad)
                val lz = sin(elevationRad)
                shader.setFloatUniform("uLightPosDir", lx.toFloat(), ly.toFloat(), lz.toFloat())
            }

            is FePointLight -> {
                shader.setIntUniform("uLightType", 1)
                shader.setFloatUniform("uLightPosDir", light.x, light.y, light.z)
            }

            is FeSpotLight -> {
                shader.setIntUniform("uLightType", 2)
                shader.setFloatUniform("uLightPosDir", light.x, light.y, light.z)
                shader.setFloatUniform("uPointsAt", light.pointsAtX, light.pointsAtY, light.pointsAtZ)
                shader.setFloatUniform("uSpotParams", 1f, light.limitingConeAngle ?: 0f)
            }
        }
        return shader
    }

    private fun buildComponentTransferShader(node: FeComponentTransferRenderNode): RuntimeShader {
        val shader = RuntimeShader(COMPONENT_TRANSFER_SHADER)
        // NB: lutTables is lazily built by the CPU path; on a pure-GPU render it
        // is still null here, so build the real tables (same as the CPU kernel
        // uses) instead of falling back to zeros (which would zero the alpha).
        val lut = node.lutTables ?: buildTransferLutTables(
            node.transferFunctions,
            node.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB,
        ).also { node.lutTables = it }
        // Two opaque textures (RGB tables + alpha table as gray): data bitmaps
        // MUST stay opaque because GPU uploads premultiply, corrupting any data
        // byte packed into RGB wherever alpha < 255.
        var rgb = node.gpuLutBitmap
        if (rgb == null || rgb.isRecycled) {
            rgb = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
            node.gpuLutBitmap = rgb
        }
        var alpha = node.gpuLutAlphaBitmap
        if (alpha == null || alpha.isRecycled) {
            alpha = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
            node.gpuLutAlphaBitmap = alpha
        }
        val rgbPixels = IntArray(256)
        val alphaPixels = IntArray(256)
        for (i in 0 until 256) {
            val a = (lut[0][i] ushr 24) and 0xFF
            rgbPixels[i] = -0x1000000 or lut[1][i] or lut[2][i] or lut[3][i]
            alphaPixels[i] = -0x1000000 or (a shl 16) or (a shl 8) or a
        }
        rgb.setPixels(rgbPixels, 0, 256, 0, 0, 256, 1)
        alpha.setPixels(alphaPixels, 0, 256, 0, 0, 256, 1)
        shader.setInputShader("uLutRgb", BitmapShader(rgb, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
        shader.setInputShader("uLutA", BitmapShader(alpha, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
        return shader
    }

    private fun buildConvolveMatrixShader(
        node: FeConvolveMatrixRenderNode,
        filterRegion: RectF,
        sx: Float,
        sy: Float,
        padX: Int,
        padY: Int,
    ): RuntimeShader? {
        val size = node.orderX * node.orderY
        val kernel = node.kernel ?: FloatArray(size)
        if (size > 25 || kernel.size > 25) return null
        // The AGSL sampling below clamps out-of-bounds taps (Skia child
        // clamping), which is only correct for edgeMode=duplicate. wrap/none
        // would silently compute the wrong edges on the GPU, so decline the
        // chain and let the software backend handle them (round-B fallback
        // coverage in GpuConvolveCorpusParityTest).
        if (node.edgeMode != ConvolveMatrixEdgeMode.duplicate) return null
        val shader = RuntimeShader(CONVOLVE_MATRIX_SHADER)
        val paddedKernel = FloatArray(25)
        kernel.copyInto(paddedKernel)
        shader.setFloatUniform("uKernel", paddedKernel)
        shader.setIntUniform("uOrderX", node.orderX)
        shader.setIntUniform("uOrderY", node.orderY)
        shader.setIntUniform("uTargetX", node.targetX)
        shader.setIntUniform("uTargetY", node.targetY)
        shader.setFloatUniform("uDivisor", node.divisor)
        shader.setFloatUniform("uBias", node.bias)
        shader.setIntUniform("uPreserveAlpha", if (node.preserveAlpha) 1 else 0)
        // Input extent for tap clamping (mirrors the CPU bitmap bounds).
        // Inset by half a texel: clamped taps must land on texel CENTERS
        // (integer-corner clamping would bilinearly blend two edge texels
        // where the CPU samples the single clamped index exactly).
        shader.setFloatUniform(
            "uBounds",
            padX + 0.5f,
            padY + 0.5f,
            padX + filterRegion.width() * sx - 0.5f,
            padY + filterRegion.height() * sy - 0.5f,
        )
        return shader
    }

    private fun buildDisplacementMapShader(
        node: FeDisplacementMapRenderNode,
        pScaleX: Float,
        pScaleY: Float
    ): RuntimeShader {
        val element = node.sourceElement
        val shader = RuntimeShader(DISPLACEMENT_MAP_SHADER)
        shader.setFloatUniform("uScale", element.scale * pScaleX, element.scale * pScaleY)
        shader.setIntUniform("uXChannel", element.xChannelSelector.ordinal)
        shader.setIntUniform("uYChannel", element.yChannelSelector.ordinal)
        return shader
    }

    private fun buildTurbulenceShader(
        node: FeTurbulenceRenderNode,
        pScaleX: Float,
        pScaleY: Float,
        filterRegion: RectF,
        canvasScaleX: Float,
        canvasScaleY: Float,
        padX: Int,
        padY: Int,
        filterNode: FilterRenderNode,
        boundingBox: Box,
    ): RuntimeShader {
        val shader = RuntimeShader(TURBULENCE_SHADER)
        val element = node.sourceElement
        val primitiveUnitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false
        val originX = if (primitiveUnitsAreUser) 0f else boundingBox.minX
        val originY = if (primitiveUnitsAreUser) 0f else boundingBox.minY
        // Size of one primitive unit in user units (matches the CPU FilterGeneration math).
        val unitSizeX = pScaleX / canvasScaleX
        val unitSizeY = pScaleY / canvasScaleY

        shader.setFloatUniform(
            /* uniformName = */ "uBaseFrequency",
            /* value1 = */ element.baseFrequencyX,
            /* value2 = */ element.baseFrequencyY
        )
        shader.setIntUniform("uNumOctaves", element.numOctaves)
        shader.setIntUniform("uIsFractal", if (element.type == FeTurbulenceType.fractalNoise) 1 else 0)
        shader.setFloatUniform("uTilePeriod", 0f, 0f) // stitchTiles="stitch" not yet GPU-supported
        shader.setFloatUniform("uOrigin", originX, originY)
        shader.setFloatUniform("uUserLeftTop", filterRegion.left, filterRegion.top)
        shader.setFloatUniform("uInvCanvasScale", 1f / canvasScaleX, 1f / canvasScaleY)
        shader.setFloatUniform("uPrimitiveUnitSize", unitSizeX, unitSizeY)
        // fragCoord is in gpuNode-local buffer space; the filter region top-left sits at (padX, padY).
        shader.setFloatUniform("uOffset", padX.toFloat(), padY.toFloat())
        // Terminal turbulence under linearRGB gets the linear->sRGB transfer
        // (CPU unLinearizeBitmap equivalent); anything else stays linear.
        val unlinearize = node === filterNode.primitives.lastOrNull() &&
            filterNode.colorInterpolationFilters == ColorInterpolation.LINEAR_RGB
        shader.setIntUniform("uUnlinearize", if (unlinearize) 1 else 0)

        val lattice = obtainLatticeBitmap(node)
        shader.setInputShader("uLattice", BitmapShader(lattice, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
        val latticeB = obtainLatticeBitmapB(node)
        shader.setInputShader("uLatticeB", BitmapShader(latticeB, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
        return shader
    }

    private fun obtainLatticeBitmap(node: FeTurbulenceRenderNode): Bitmap {
        val cached = node.gpuLatticeBitmap
        if (cached != null) {
            return cached
        }
        val generators = node.generators
        // 256x4 data texture: row k holds channel k's (permutation,
        // gradientX-hi, gradientX-lo) in RGB with opaque alpha. Data bitmaps
        // MUST stay opaque: the GPU backend uploads textures premultiplied,
        // which corrupts any data byte packed into RGB wherever alpha < 255.
        // Gradients are 16-bit (hi/lo bytes): 8-bit packing leaves ~1-2 LSB
        // of Perlin noise error, amplified by the terminal EOTF.
        val bitmap = createBitmap(256, 4)
        val pixels = IntArray(256 * 4)
        for (i in 0 until 256) {
            pixels[i] = packLattice(generators[0].p[i], packGradient16(generators[0].gx[i]))
            pixels[256 + i] = packLattice(generators[1].p[i], packGradient16(generators[1].gx[i]))
            pixels[512 + i] = packLattice(generators[2].p[i], packGradient16(generators[2].gx[i]))
            pixels[768 + i] = packLattice(generators[3].p[i], packGradient16(generators[3].gx[i]))
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 4)
        node.gpuLatticeBitmap = bitmap
        return bitmap
    }

    private fun obtainLatticeBitmapB(node: FeTurbulenceRenderNode): Bitmap {
        val cached = node.gpuLatticeBitmapB
        if (cached != null) {
            return cached
        }
        val generators = node.generators
        // Companion to [obtainLatticeBitmap]: row k holds channel k's
        // (permutation, gradientY-hi, gradientY-lo), opaque.
        val bitmap = createBitmap(256, 4)
        val pixels = IntArray(256 * 4)
        for (i in 0 until 256) {
            pixels[i] = packLattice(generators[0].p[i], packGradient16(generators[0].gy[i]))
            pixels[256 + i] = packLattice(generators[1].p[i], packGradient16(generators[1].gy[i]))
            pixels[512 + i] = packLattice(generators[2].p[i], packGradient16(generators[2].gy[i]))
            pixels[768 + i] = packLattice(generators[3].p[i], packGradient16(generators[3].gy[i]))
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 4)
        node.gpuLatticeBitmapB = bitmap
        return bitmap
    }

    private fun packLattice(p: Int, g16: Int): Int {
        return -0x1000000 or ((p and 0xFF) shl 16) or (((g16 shr 8) and 0xFF) shl 8) or (g16 and 0xFF)
    }

    private fun packGradient16(g: Double): Int =
        (((g + 1.0) * 32767.5 + 0.5).toInt()).coerceIn(0, 65535)

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
