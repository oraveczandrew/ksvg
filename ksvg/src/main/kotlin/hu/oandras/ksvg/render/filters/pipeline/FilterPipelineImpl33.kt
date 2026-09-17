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
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
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
                                RenderEffect.createBlurEffect(sigmaX, sigmaY, Shader.TileMode.CLAMP)
                                    .chainWith(inputEffect)
                            }
                        }

                        is FeMorphologyRenderNode -> {
                            val morph = primitive.sourceElement
                            val radX = morph.radiusX * scaleX
                            val radY = morph.radiusY * scaleY
                            val shader = RuntimeShader(MORPHOLOGY_SHADER)
                            shader.setFloatUniform("uRadius", radX, radY)
                            shader.setIntUniform("uErode", if (primitive.erode) 1 else 0)
                            resultShaders[resultName ?: ""] = shader
                            RenderEffect.createRuntimeShaderEffect(shader, "uInput").chainWith(inputEffect)
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

                            val shader = buildLightingShader(primitive, false) ?: return null
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

                            val shader = buildLightingShader(primitive, true) ?: return null
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
                            val shader = buildConvolveMatrixShader(primitive) ?: return null
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
                                RenderEffect.createBlurEffect(sigmaX, sigmaY, alphaEffect, Shader.TileMode.CLAMP)
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
            resolveInputRegion = { _ -> if (hasInput) inputUnion else null },
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
            canvas.translate(deviceRegion.left - chain.padX, deviceRegion.top - chain.padY)
            canvas.drawRenderNode(gpuNode)
        }
    }

    private fun buildLightingShader(
        node: FilterPrimitiveRenderNode<*>,
        isSpecular: Boolean
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
        shader.setFloatUniform("uLightColor", styleColor.red / 255f, styleColor.green / 255f, styleColor.blue / 255f)
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
        val lut = node.lutTables ?: Array(4) { IntArray(256) { i -> i } }
        var bitmap = node.gpuLutBitmap
        if (bitmap == null || bitmap.isRecycled) {
            bitmap = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
            node.gpuLutBitmap = bitmap
        }
        val pixels = IntArray(256)
        for (i in 0 until 256) {
            pixels[i] = lut[0][i] or lut[1][i] or lut[2][i] or lut[3][i]
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 1)
        shader.setInputShader("uLut", BitmapShader(bitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
        return shader
    }

    private fun buildConvolveMatrixShader(node: FeConvolveMatrixRenderNode): RuntimeShader? {
        val size = node.orderX * node.orderY
        val kernel = node.kernel ?: FloatArray(size)
        if (size > 25 || kernel.size > 25) return null
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

        val lattice = obtainLatticeBitmap(node)
        shader.setInputShader("uLattice", BitmapShader(lattice, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP))
        return shader
    }

    private fun obtainLatticeBitmap(node: FeTurbulenceRenderNode): Bitmap {
        val cached = node.gpuLatticeBitmap
        if (cached != null) {
            return cached
        }
        val generators = node.generators
        val bitmap = createBitmap(256, 3)
        val pixels = IntArray(256 * 3)
        for (i in 0 until 256) {
            val p0 = generators[0].p[i] and 0xFF
            val p1 = generators[1].p[i] and 0xFF
            val p2 = generators[2].p[i] and 0xFF
            val p3 = generators[3].p[i] and 0xFF
            pixels[i] = (p3 shl 24) or (p0 shl 16) or (p1 shl 8) or p2

            val g0x = packG(generators[0].gx[i])
            val g1x = packG(generators[1].gx[i])
            val g2x = packG(generators[2].gx[i])
            val g3x = packG(generators[3].gx[i])
            pixels[256 + i] = (g3x shl 24) or (g0x shl 16) or (g1x shl 8) or g2x

            val g0y = packG(generators[0].gy[i])
            val g1y = packG(generators[1].gy[i])
            val g2y = packG(generators[2].gy[i])
            val g3y = packG(generators[3].gy[i])
            pixels[512 + i] = (g3y shl 24) or (g0y shl 16) or (g1y shl 8) or g2y
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 3)
        node.gpuLatticeBitmap = bitmap
        return bitmap
    }

    private fun packG(g: Double): Int = ((g + 1.0) * 127.5 + 0.5).toInt().coerceIn(0, 255)

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

        private const val LIGHTING_SHADER = """
            uniform shader uInput;
            uniform float uSurfaceScale;
            uniform float uConstant;
            uniform float uExponent;
            uniform float3 uLightColor;
            uniform int uIsSpecular;
            uniform int uLightType;
            uniform float3 uLightPosDir;
            uniform float3 uPointsAt;
            uniform float2 uSpotParams;

            uniform float2 uUserLeftTop;
            uniform float2 uInvCanvasScale;
            uniform float2 uOffset;
            uniform float4 uPrimitiveRegion;

            float3 getNormal(float2 fragCoord) {
                float h0 = uInput.eval(fragCoord + float2(-1.0, -1.0)).a;
                float h1 = uInput.eval(fragCoord + float2(0.0, -1.0)).a;
                float h2 = uInput.eval(fragCoord + float2(1.0, -1.0)).a;
                float h3 = uInput.eval(fragCoord + float2(-1.0, 0.0)).a;
                float h5 = uInput.eval(fragCoord + float2(1.0, 0.0)).a;
                float h6 = uInput.eval(fragCoord + float2(-1.0, 1.0)).a;
                float h7 = uInput.eval(fragCoord + float2(0.0, 1.0)).a;
                float h8 = uInput.eval(fragCoord + float2(1.0, 1.0)).a;
                
                float dx = (h2 + 2.0*h5 + h8) - (h0 + 2.0*h3 + h6);
                float dy = (h6 + 2.0*h7 + h8) - (h0 + 2.0*h1 + h2);
                
                // SVG spec kernel: Nx = -surfaceScale * dx / 4.0. 
                // Since samples are separated by 2 pixels, Nx is the slope per pixel.
                // We multiply by uInvCanvasScale to get user-space slopes.
                float Nx = -dx * 0.25 * uSurfaceScale * uInvCanvasScale.x;
                float Ny = -dy * 0.25 * uSurfaceScale * uInvCanvasScale.y;
                
                float3 n = float3(Nx, Ny, 1.0);
                return normalize(n);
            }

            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x - 0.5 || fragCoord.x > uPrimitiveRegion.z + 0.5 ||
                    fragCoord.y < uPrimitiveRegion.y - 0.5 || fragCoord.y > uPrimitiveRegion.w + 0.5) {
                    return half4(0.0);
                }

                float3 n = getNormal(fragCoord);
                float3 l;
                if (uLightType == 0) {
                    l = normalize(uLightPosDir);
                } else {
                    float2 local = fragCoord - uOffset;
                    float2 user = uUserLeftTop + local * uInvCanvasScale;

                    float3 p = float3(user, uInput.eval(fragCoord).a * uSurfaceScale);
                    l = normalize(uLightPosDir - p);
                }
                
                float dotNL = max(dot(n, l), 0.0);
                float3 color;
                float a = 1.0;
                if (uIsSpecular == 0) {
                    color = uLightColor * uConstant * dotNL;
                } else {
                    float3 v = float3(0.0, 0.0, 1.0);
                    float3 h = normalize(l + v);
                    color = uLightColor * uConstant * pow(max(dot(n, h), 0.0), uExponent);
                    a = max(max(color.r, color.g), color.b);
                }
                
                return half4(color, a);
            }
        """

        private const val COLOR_MATRIX_SHADER = """
            uniform shader uInput;
            uniform float uMatrix[20];
            half4 main(float2 fragCoord) {
                float4 c = uInput.eval(fragCoord);
                float alpha = c.a;
                if (alpha > 0.0) c.rgb /= alpha;
                float4 res;
                res.r = uMatrix[0]*c.r + uMatrix[1]*c.g + uMatrix[2]*c.b + uMatrix[3]*c.a + uMatrix[4]/255.0;
                res.g = uMatrix[5]*c.r + uMatrix[6]*c.g + uMatrix[7]*c.b + uMatrix[8]*c.a + uMatrix[9]/255.0;
                res.b = uMatrix[10]*c.r + uMatrix[11]*c.g + uMatrix[12]*c.b + uMatrix[13]*c.a + uMatrix[14]/255.0;
                res.a = uMatrix[15]*c.r + uMatrix[16]*c.g + uMatrix[17]*c.b + uMatrix[18]*c.a + uMatrix[19]/255.0;
                res = clamp(res, 0.0, 1.0);
                return half4(res.r * res.a, res.g * res.a, res.b * res.a, res.a);
            }
        """

        private const val COMPOSITE_SHADER = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform int uOperator;
            uniform float4 uK;
            half4 main(float2 fragCoord) {
                float4 src = uInput.eval(fragCoord);
                float4 dst = uIn2.eval(fragCoord);
                if (uOperator == 0) return half4(src + dst * (1.0 - src.a));
                if (uOperator == 1) return half4(src * dst.a);
                if (uOperator == 2) return half4(src * (1.0 - dst.a));
                if (uOperator == 3) return half4(src * dst.a + dst * (1.0 - src.a));
                if (uOperator == 4) return half4(src * (1.0 - dst.a) + dst * (1.0 - src.a));
                if (uOperator == 5) {
                    float4 res = uK.x * dst * src + uK.y * src + uK.z * dst + uK.w;
                    return half4(clamp(res, 0.0, 1.0));
                }
                return half4(dst);
            }
        """

        private const val FLOOD_SHADER = """
            uniform shader uInput;
            layout(color) uniform half4 uColor;
            uniform float4 uPrimitiveRegion;
            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x - 0.5 || fragCoord.x > uPrimitiveRegion.z + 0.5 ||
                    fragCoord.y < uPrimitiveRegion.y - 0.5 || fragCoord.y > uPrimitiveRegion.w + 0.5) {
                    return half4(0.0);
                }
                return uColor;
            }
        """

        private const val TILE_SHADER = """
            uniform shader uInput;
            uniform float4 uRect;
            half4 main(float2 fragCoord) {
                // feTile only paints inside its own subregion (uRect); outside it is transparent.
                if (fragCoord.x < uRect.x || fragCoord.x > uRect.z ||
                    fragCoord.y < uRect.y || fragCoord.y > uRect.w) {
                    return half4(0.0);
                }
                float w = uRect.z - uRect.x;
                float h = uRect.w - uRect.y;
                float2 coord = float2(
                    mod(fragCoord.x - uRect.x, w),
                    mod(fragCoord.y - uRect.y, h)
                ) + uRect.xy;
                return uInput.eval(coord);
            }
        """

        private const val COMPONENT_TRANSFER_SHADER = """
            uniform shader uInput;
            uniform shader uLut;
            half4 main(float2 fragCoord) {
                float4 color = uInput.eval(fragCoord);
                float alpha = color.a;
                if (alpha > 0.0) color.rgb /= alpha;
                float r = uLut.eval(float2(color.r * 255.0 + 0.5, 0.5)).r;
                float g = uLut.eval(float2(color.g * 255.0 + 0.5, 0.5)).g;
                float b = uLut.eval(float2(color.b * 255.0 + 0.5, 0.5)).b;
                float a = uLut.eval(float2(color.a * 255.0 + 0.5, 0.5)).a;
                return half4(r * a, g * a, b * a, a);
            }
        """

        private const val CONVOLVE_MATRIX_SHADER = """
            uniform shader uInput;
            uniform float uKernel[25];
            uniform int uOrderX;
            uniform int uOrderY;
            uniform int uTargetX;
            uniform int uTargetY;
            uniform float uDivisor;
            uniform float uBias;
            uniform int uPreserveAlpha;
            half4 main(float2 fragCoord) {
                float4 sum = float4(0.0);
                int kx = 0;
                int ky = 0;
                for (int i = 0; i < 25; ++i) {
                    if (i >= uOrderX * uOrderY) break;
                    float2 offset = float2(float(kx - uTargetX), float(ky - uTargetY));
                    sum += uInput.eval(fragCoord + offset) * uKernel[i];
                    kx++;
                    if (kx >= uOrderX) {
                        kx = 0;
                        ky++;
                    }
                }
                float4 res = sum / uDivisor + uBias;
                if (uPreserveAlpha != 0) res.a = uInput.eval(fragCoord).a;
                return half4(res);
            }
        """

        private const val MORPHOLOGY_SHADER = """
            uniform shader uInput;
            uniform float2 uRadius;
            uniform int uErode;
            half4 main(float2 fragCoord) {
                float2 r = abs(uRadius);
                int steps = int(max(r.x, r.y));
                float2 dir = sign(uRadius);
                float4 res = uInput.eval(fragCoord);
                for (int i = 1; i <= 20; ++i) {
                    if (i > steps) break;
                    res = (uErode != 0) 
                        ? min(res, min(uInput.eval(fragCoord + float(i) * dir), uInput.eval(fragCoord - float(i) * dir)))
                        : max(res, max(uInput.eval(fragCoord + float(i) * dir), uInput.eval(fragCoord - float(i) * dir)));
                }
                return half4(res);
            }
        """

        private const val DISPLACEMENT_MAP_SHADER = """
            uniform shader uInput;
            uniform shader uMap;
            uniform float2 uScale;
            uniform int uXChannel;
            uniform int uYChannel;
            float getChannel(float4 color, int selector) {
                if (selector == 0) return color.r;
                if (selector == 1) return color.g;
                if (selector == 2) return color.b;
                return color.a;
            }
            half4 main(float2 fragCoord) {
                float4 mapColor = uMap.eval(fragCoord);
                float dx = (getChannel(mapColor, uXChannel) - 0.5) * uScale.x;
                float dy = (getChannel(mapColor, uYChannel) - 0.5) * uScale.y;
                return uInput.eval(fragCoord + float2(dx, dy));
            }
        """

        private const val TURBULENCE_SHADER = """
            uniform shader uLattice;
            uniform shader in_source;
            uniform float2 uBaseFrequency;
            uniform int uNumOctaves;
            uniform int uIsFractal;
            uniform float2 uTilePeriod;
            uniform float2 uOrigin;
            uniform float2 uPrimitiveUnitSize;
            uniform float2 uUserLeftTop;
            uniform float2 uInvCanvasScale;
            uniform float2 uOffset;
            uniform float4 uPrimitiveRegion;

            int customMod(int x, int y) {
                return x - y * int(floor(float(x) / float(y)));
            }

            float4 getLattice(int x, int row) {
                return uLattice.eval(float2(float(x) + 0.5, float(row) + 0.5));
            }

            float4 sCurve(float4 t) {
                return t * t * (3.0 - 2.0 * t);
            }

            float4 noise2(float2 p, float2 period) {
                float2 pf = floor(p);
                float2 r0 = p - pf;
                float2 r1 = r0 - 1.0;
                int2 b0 = int2(pf);

                if (period.x > 0.0) {
                    b0.x = customMod(b0.x, int(period.x));
                } else {
                    b0.x = customMod(b0.x, 256);
                }

                int bx1;
                if (period.x > 0.0) {
                    bx1 = customMod(b0.x + 1, int(period.x));
                } else {
                    bx1 = customMod(b0.x + 1, 256);
                }

                if (period.y > 0.0) {
                    b0.y = customMod(b0.y, int(period.y));
                } else {
                    b0.y = customMod(b0.y, 256);
                }

                int by1;
                if (period.y > 0.0) {
                    by1 = customMod(b0.y + 1, int(period.y));
                } else {
                    by1 = customMod(b0.y + 1, 256);
                }

                float4 i = getLattice(b0.x, 0) * 255.0;
                float4 j = getLattice(bx1, 0) * 255.0;

                float4 val00 = i + float4(b0.y) + 0.5;
                float4 val10 = j + float4(b0.y) + 0.5;
                float4 val01 = i + float4(by1) + 0.5;
                float4 val11 = j + float4(by1) + 0.5;

                int4 idx00 = int4(val00 - 256.0 * floor(val00 / 256.0));
                int4 idx10 = int4(val10 - 256.0 * floor(val10 / 256.0));
                int4 idx01 = int4(val01 - 256.0 * floor(val01 / 256.0));
                int4 idx11 = int4(val11 - 256.0 * floor(val11 / 256.0));

                float4 b00 = float4(getLattice(idx00.r, 0).r, getLattice(idx00.g, 0).g, getLattice(idx00.b, 0).b, getLattice(idx00.a, 0).a) * 255.0;
                float4 b10 = float4(getLattice(idx10.r, 0).r, getLattice(idx10.g, 0).g, getLattice(idx10.b, 0).b, getLattice(idx10.a, 0).a) * 255.0;
                float4 b01 = float4(getLattice(idx01.r, 0).r, getLattice(idx01.g, 0).g, getLattice(idx01.b, 0).b, getLattice(idx01.a, 0).a) * 255.0;
                float4 b11 = float4(getLattice(idx11.r, 0).r, getLattice(idx11.g, 0).g, getLattice(idx11.b, 0).b, getLattice(idx11.a, 0).a) * 255.0;

                float4 sx = sCurve(float4(r0.x));
                float4 sy = sCurve(float4(r0.y));

                float4 q00x = float4(getLattice(int(b00.r+0.5), 1).r, getLattice(int(b00.g+0.5), 1).g, getLattice(int(b00.b+0.5), 1).b, getLattice(int(b00.a+0.5), 1).a) * 2.0 - 1.0;
                float4 q00y = float4(getLattice(int(b00.r+0.5), 2).r, getLattice(int(b00.g+0.5), 2).g, getLattice(int(b00.b+0.5), 2).b, getLattice(int(b00.a+0.5), 2).a) * 2.0 - 1.0;
                float4 q10x = float4(getLattice(int(b10.r+0.5), 1).r, getLattice(int(b10.g+0.5), 1).g, getLattice(int(b10.b+0.5), 1).b, getLattice(int(b10.a+0.5), 1).a) * 2.0 - 1.0;
                float4 q10y = float4(getLattice(int(b10.r+0.5), 2).r, getLattice(int(b10.g+0.5), 2).g, getLattice(int(b10.b+0.5), 2).b, getLattice(int(b10.a+0.5), 2).a) * 2.0 - 1.0;
                float4 q01x = float4(getLattice(int(b01.r+0.5), 1).r, getLattice(int(b01.g+0.5), 1).g, getLattice(int(b01.b+0.5), 1).b, getLattice(int(b01.a+0.5), 1).a) * 2.0 - 1.0;
                float4 q01y = float4(getLattice(int(b01.r+0.5), 2).r, getLattice(int(b01.g+0.5), 2).g, getLattice(int(b01.b+0.5), 2).b, getLattice(int(b01.a+0.5), 2).a) * 2.0 - 1.0;
                float4 q11x = float4(getLattice(int(b11.r+0.5), 1).r, getLattice(int(b11.g+0.5), 1).g, getLattice(int(b11.b+0.5), 1).b, getLattice(int(b11.a+0.5), 1).a) * 2.0 - 1.0;
                float4 q11y = float4(getLattice(int(b11.r+0.5), 2).r, getLattice(int(b11.g+0.5), 2).g, getLattice(int(b11.b+0.5), 2).b, getLattice(int(b11.a+0.5), 2).a) * 2.0 - 1.0;

                float4 u = r0.x * q00x + r0.y * q00y;
                float4 v = r1.x * q10x + r0.y * q10y;
                float4 a = u + sx * (v - u);
                float4 u2 = r0.x * q01x + r1.y * q01y;
                float4 v2 = r1.x * q11x + r1.y * q11y;
                float4 b = u2 + sx * (v2 - u2);
                return a + sy * (b - a);
            }

            half4 main(float2 fragCoord) {
                if (fragCoord.x < uPrimitiveRegion.x - 0.5 || fragCoord.x > uPrimitiveRegion.z + 0.5 ||
                    fragCoord.y < uPrimitiveRegion.y - 0.5 || fragCoord.y > uPrimitiveRegion.w + 0.5) {
                    return half4(0.0);
                }

                // fragCoord is in gpuNode-local buffer space; uOffset maps it back to
                // device-pixel coordinates relative to the filter region top-left.
                float2 local = fragCoord - uOffset;
                float2 user = uUserLeftTop + local * uInvCanvasScale;
                float2 p = ((user - uOrigin) / uPrimitiveUnitSize) * uBaseFrequency;
                float4 sums = float4(0.0);
                float ratio = 1.0;
                float2 period = uTilePeriod;
                for (int i = 0; i < 8; ++i) {
                    if (i >= uNumOctaves) break;
                    float4 n = noise2(p, period);
                    if (uIsFractal != 0) sums += n / ratio; else sums += abs(n) / ratio;
                    p *= 2.0; ratio *= 2.0; if (period.x > 0.0) period *= 2.0;
                }
                float4 finalVal = (uIsFractal != 0) ? (sums + 1.0) * 0.5 : sums;
                finalVal = clamp(finalVal, 0.0, 1.0);
                return half4(finalVal.r * finalVal.a, finalVal.g * finalVal.a, finalVal.b * finalVal.a, finalVal.a);
            }
        """
    }
}
