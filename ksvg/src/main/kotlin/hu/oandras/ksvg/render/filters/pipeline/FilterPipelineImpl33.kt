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
import android.graphics.PorterDuffColorFilter
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.COLOR_WHITE
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeCompositeOperator
import hu.oandras.ksvg.dom.filter.FeDistantLight
import hu.oandras.ksvg.dom.filter.FePointLight
import hu.oandras.ksvg.dom.filter.FeSpotLight
import hu.oandras.ksvg.dom.filter.FeTurbulenceType
import hu.oandras.ksvg.dom.filter.Lighting
import hu.oandras.ksvg.dom.style.ColorValue
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
import hu.oandras.ksvg.render.calculatePrimitiveRegion
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.pool.withPooledObject
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.ceilToInt
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

/**
 * AGSL (RuntimeShader) GPU backend (API 33+, hardware canvas only).
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal class FilterPipelineImpl33(renderContext: RenderContext) : FilterPipelineImpl31(renderContext) {

    override fun supports(primitives: FilterPrimitiveSet): Boolean {
        val supportedMask = FilterPrimitiveSet.FLAG_COLOR_MATRIX or
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
        return primitives.bits != 0 && (primitives.bits and supportedMask.inv()) == 0
    }

    context(renderContext: RenderContext)
    override fun tryBuildChain(
        filterNode: FilterRenderNode,
        scaleX: Float,
        scaleY: Float,
        filterRegion: RectF,
        deviceRegion: RectF,
        sx: Float,
        sy: Float,
        boundingBox: Box
    ): Chain? {
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
        val resultShaders = mutableMapOf<String, RuntimeShader>()
        val resultEffects = mutableMapOf<String, RenderEffect>()

        filterNode.primitives.forEachElement { primitive ->
            val resultName = when (primitive) {
                is FeOffsetRenderNode -> primitive.sourceElement.result
                is FeGaussianBlurRenderNode -> primitive.sourceElement.result
                is FeMorphologyRenderNode -> primitive.sourceElement.result
                is FeColorMatrixRenderNode -> primitive.sourceElement.result
                is FeDiffuseLightingRenderNode -> primitive.sourceElement.result
                is FeSpecularLightingRenderNode -> primitive.sourceElement.result
                is FeComponentTransferRenderNode -> primitive.sourceElement.result
                is FeConvolveMatrixRenderNode -> primitive.sourceElement.result
                is FeBlendRenderNode -> primitive.sourceElement.result
                is FeCompositeRenderNode -> primitive.sourceElement.result
                is FeDisplacementMapRenderNode -> primitive.sourceElement.result
                is FeTurbulenceRenderNode -> primitive.sourceElement.result
                is FeFloodRenderNode -> primitive.sourceElement.result
                is FeMergeRenderNode -> primitive.sourceElement.result
                else -> null
            }

            val input = when (primitive) {
                is FeOffsetRenderNode -> primitive.sourceElement.`in`
                is FeGaussianBlurRenderNode -> primitive.sourceElement.`in`
                is FeMorphologyRenderNode -> primitive.sourceElement.`in`
                is FeColorMatrixRenderNode -> primitive.sourceElement.`in`
                is FeDiffuseLightingRenderNode -> primitive.sourceElement.`in`
                is FeSpecularLightingRenderNode -> primitive.sourceElement.`in`
                is FeComponentTransferRenderNode -> primitive.sourceElement.`in`
                is FeConvolveMatrixRenderNode -> primitive.sourceElement.`in`
                is FeBlendRenderNode -> primitive.sourceElement.`in`
                is FeCompositeRenderNode -> primitive.sourceElement.`in`
                is FeDisplacementMapRenderNode -> primitive.sourceElement.`in`
                is FeFloodRenderNode -> primitive.sourceElement.`in`
                else -> null
            }

            val inputEffect = resolveEffect(input, previousResult, first, chain, resultEffects) ?: return null

            val effect = when (primitive) {
                is FeOffsetRenderNode -> {
                    val offset = primitive.sourceElement
                    val dx = offset.dx?.floatValueInContext() ?: 0f
                    val dy = offset.dy?.floatValueInContext() ?: 0f
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
                is FeGaussianBlurRenderNode -> {
                    val sigmaX = primitive.stdDeviationX * scaleX
                    val sigmaY = primitive.stdDeviationY * scaleY
                    if (sigmaX <= 0f && sigmaY <= 0f) {
                        inputEffect
                    } else {
                        padX = max(padX, (sigmaX * 3f).ceilToInt())
                        padY = max(padY, (sigmaY * 3f).ceilToInt())
                        if (inputEffect == IDENTITY_EFFECT) {
                            RenderEffect.createBlurEffect(sigmaX, sigmaY, Shader.TileMode.CLAMP)
                        } else {
                            RenderEffect.createBlurEffect(sigmaX, sigmaY, inputEffect, Shader.TileMode.CLAMP)
                        }
                    }
                }
                is FeMorphologyRenderNode -> {
                    val morph = primitive.sourceElement
                    val radX = morph.radiusX * scaleX
                    val radY = morph.radiusY * scaleY
                    padX = max(padX, radX.ceilToInt())
                    padY = max(padY, radY.ceilToInt())
                    val shader = RuntimeShader(MORPHOLOGY_SHADER)
                    shader.setFloatUniform("uRadius", radX, radY)
                    shader.setIntUniform("uErode", if (primitive.erode) 1 else 0)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeColorMatrixRenderNode -> {
                    val colorMatrix = primitive.sourceElement
                    val matrix = buildColorMatrix(colorMatrix.type, colorMatrix.values)
                    val shader = RuntimeShader(COLOR_MATRIX_SHADER)
                    shader.setFloatUniform("uMatrix", matrix.array)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeDiffuseLightingRenderNode -> {
                    val shader = buildLightingShader(primitive, false) ?: return null
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeSpecularLightingRenderNode -> {
                    val shader = buildLightingShader(primitive, true) ?: return null
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeComponentTransferRenderNode -> {
                    val shader = buildComponentTransferShader(primitive)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeConvolveMatrixRenderNode -> {
                    val shader = buildConvolveMatrixShader(primitive) ?: return null
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeBlendRenderNode -> {
                    val blend = primitive.sourceElement
                    val in2Effect = resolveEffect(blend.in2, previousResult, first, chain, resultEffects) ?: return null
                    val mode = primitive.mode.toBlendMode() ?: return null
                    
                    RenderEffect.createBlendModeEffect(
                        if (in2Effect == IDENTITY_EFFECT) RenderEffect.createOffsetEffect(0f, 0f) else in2Effect,
                        if (inputEffect == IDENTITY_EFFECT) RenderEffect.createOffsetEffect(0f, 0f) else inputEffect,
                        mode
                    )
                }
                is FeCompositeRenderNode -> {
                    val composite = primitive.sourceElement
                    val in2Effect = resolveEffect(composite.in2, previousResult, first, chain, resultEffects) ?: return null
                    
                    if (composite.operator == FeCompositeOperator.arithmetic) {
                        if (composite.k1 == 0f && composite.k2 == 1f && composite.k3 == 1f && composite.k4 == 0f) {
                            RenderEffect.createBlendModeEffect(
                                in2Effect,
                                inputEffect,
                                BlendMode.PLUS
                            )
                        } else {
                            val in2Shader = composite.in2?.let { resultShaders[it] }
                            if (in2Shader != null) {
                                val shader = RuntimeShader(COMPOSITE_SHADER)
                                shader.setInputShader("uIn2", in2Shader)
                                shader.setIntUniform("uOperator", 5)
                                shader.setFloatUniform("uK", floatArrayOf(composite.k1, composite.k2, composite.k3, composite.k4))
                                
                                val effect = RenderEffect.createRuntimeShaderEffect(shader, "uInput")
                                resultShaders[resultName ?: ""] = shader
                                if (inputEffect == IDENTITY_EFFECT) effect else RenderEffect.createChainEffect(effect, inputEffect)
                            } else {
                                return null
                            }
                        }
                    } else {
                        val mode = composite.operator.toBlendMode() ?: return null
                        RenderEffect.createBlendModeEffect(
                            in2Effect,
                            inputEffect,
                            mode
                        )
                    }
                }
                is FeDisplacementMapRenderNode -> {
                    val disp = primitive.sourceElement
                    val mapShader = resultShaders[disp.in2] ?: return null
                    val shader = buildDisplacementMapShader(primitive, scaleX, scaleY)
                    shader.setInputShader("uMap", mapShader)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeTurbulenceRenderNode -> {
                    val shader = buildTurbulenceShader(primitive, scaleX, scaleY, filterRegion, sx, sy, padX, padY)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "in_source")
                }
                is FeFloodRenderNode -> {
                    val color = renderContext.resolveFloodColor(primitive, filterNode.renderState.style)
                    val shader = RuntimeShader(FLOOD_SHADER)
                    shader.setColorUniform("uColor", color)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput")
                }
                is FeMergeRenderNode -> {
                    var mergeEffect: RenderEffect? = null
                    primitive.mergeNodes.forEach { inputName ->
                        val inputNodeEffect = resolveEffect(inputName, previousResult, first, chain, resultEffects) ?: return null
                        mergeEffect = if (mergeEffect == null) {
                            inputNodeEffect
                        } else {
                            RenderEffect.createBlendModeEffect(
                                inputNodeEffect,
                                mergeEffect,
                                BlendMode.SRC_OVER
                            )
                        }
                    }
                    mergeEffect
                }
                is FeTileRenderNode -> {
                    val tile = primitive.sourceElement
                    val tileRect = renderContext.rectFPool.withPooledObject { rect ->
                        calculatePrimitiveRegion(
                            primitive = tile,
                            filterRegion = filterRegion,
                            unitsAreUser = filterNode.sourceElement.primitiveUnitsAreUser != false,
                            originalObjBBox = boundingBox,
                            outRect = rect
                        )
                        // Transform user-space tile region to device-pixel space relative to the deviceRegion
                        floatArrayOf(
                            (rect.left - filterRegion.left) * sx + padX,
                            (rect.top - filterRegion.top) * sy + padY,
                            (rect.right - filterRegion.left) * sx + padX,
                            (rect.bottom - filterRegion.top) * sy + padY
                        )
                    }
                    
                    val shader = RuntimeShader(TILE_SHADER)
                    shader.setFloatUniform("uRect", tileRect)
                    shader.setFloatUniform("uOffset", deviceRegion.left - padX, deviceRegion.top - padY)
                    resultShaders[resultName ?: ""] = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput").let {
                        if (inputEffect == IDENTITY_EFFECT) it else RenderEffect.createChainEffect(it, inputEffect)
                    }
                }
                is FeDropShadowRenderNode -> {
                    val alphaEffect = if (inputEffect == IDENTITY_EFFECT) {
                        SOURCE_ALPHA_EFFECT
                    } else {
                        RenderEffect.createColorFilterEffect(
                            android.graphics.ColorMatrixColorFilter(floatArrayOf(
                                0f, 0f, 0f, 0f, 0f,
                                0f, 0f, 0f, 0f, 0f,
                                0f, 0f, 0f, 0f, 0f,
                                0f, 0f, 0f, 1f, 0f
                            )),
                            inputEffect
                        )
                    }

                    val sigmaX = primitive.blurNode.stdDeviationX * scaleX
                    val sigmaY = primitive.blurNode.stdDeviationY * scaleY
                    val blurredEffect = if (sigmaX > 0f || sigmaY > 0f) {
                        padX = max(padX, (sigmaX * 3f).ceilToInt())
                        padY = max(padY, (sigmaY * 3f).ceilToInt())
                        RenderEffect.createBlurEffect(sigmaX, sigmaY, alphaEffect, Shader.TileMode.CLAMP)
                    } else {
                        alphaEffect
                    }

                    val dx = primitive.offsetNode.dx * scaleX
                    val dy = primitive.offsetNode.dy * scaleY
                    val offsetEffect = RenderEffect.createOffsetEffect(dx, dy, blurredEffect)

                    val floodColor = renderContext.resolveFloodColor(primitive, filterNode.renderState.style)
                    val coloredShadowEffect = RenderEffect.createColorFilterEffect(
                        PorterDuffColorFilter(floodColor, android.graphics.PorterDuff.Mode.SRC_IN),
                        offsetEffect
                    )

                    RenderEffect.createBlendModeEffect(
                        inputEffect,
                        coloredShadowEffect,
                        BlendMode.SRC_OVER
                    )
                }
                else -> return null
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
        val built = Chain(result, padX, padY, scaleX, scaleY)
        filterNode.gpuChain = built
        filterNode.gpuChainVersion = filterNode.version
        filterNode.gpuChainScaleX = scaleX
        filterNode.gpuChainScaleY = scaleY
        return built
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
        val lut = node.lutTables ?: Array(4) { ByteArray(256) { it.toByte() } }
        val bitmap = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
        val pixels = IntArray(256)
        for (i in 0 until 256) {
            val a = lut[0][i].toInt() and 0xFF
            val r = lut[1][i].toInt() and 0xFF
            val g = lut[2][i].toInt() and 0xFF
            val b = lut[3][i].toInt() and 0xFF
            pixels[i] = a shl 24 or (r shl 16) or (g shl 8) or b
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

    private fun buildDisplacementMapShader(node: FeDisplacementMapRenderNode, pScaleX: Float, pScaleY: Float): RuntimeShader {
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
        padY: Int
    ): RuntimeShader {
        val shader = RuntimeShader(TURBULENCE_SHADER)
        val element = node.sourceElement
        shader.setFloatUniform(
            /* uniformName = */ "uBaseFrequency",
            /* value1 = */ element.baseFrequencyX * pScaleX,
            /* value2 = */ element.baseFrequencyY * pScaleY
        )
        shader.setIntUniform("uNumOctaves", element.numOctaves)
        shader.setIntUniform("uIsFractal", if (element.type == FeTurbulenceType.fractalNoise) 1 else 0)
        shader.setFloatUniform("uTilePeriod", 0f, 0f) // Simplified
        shader.setFloatUniform("uOrigin", filterRegion.left, filterRegion.top)
        shader.setFloatUniform("uUserLeftTop", filterRegion.left, filterRegion.top)
        shader.setFloatUniform("uInvCanvasScale", 1f / canvasScaleX, 1f / canvasScaleY)
        shader.setFloatUniform("uOffset", filterRegion.left * canvasScaleX - padX, filterRegion.top * canvasScaleY - padY)

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

            fun packG(g: Double): Int = ((g + 1.0) * 127.5 + 0.5).toInt().coerceIn(0, 255)
            val g0x = packG(generators[0].g2[i][0])
            val g1x = packG(generators[1].g2[i][0])
            val g2x = packG(generators[2].g2[i][0])
            val g3x = packG(generators[3].g2[i][0])
            pixels[256 + i] = (g3x shl 24) or (g0x shl 16) or (g1x shl 8) or g2x

            val g0y = packG(generators[0].g2[i][1])
            val g1y = packG(generators[1].g2[i][1])
            val g2y = packG(generators[2].g2[i][1])
            val g3y = packG(generators[3].g2[i][1])
            pixels[512 + i] = (g3y shl 24) or (g0y shl 16) or (g1y shl 8) or g2y
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 3)
        node.gpuLatticeBitmap = bitmap
        return bitmap
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
                
                float3 n = float3(-dx * uSurfaceScale, -dy * uSurfaceScale, 1.0);
                return normalize(n);
            }

            half4 main(float2 fragCoord) {
                float3 n = getNormal(fragCoord);
                float3 l;
                if (uLightType == 0) {
                    l = normalize(uLightPosDir);
                } else {
                    float3 p = float3(fragCoord, uInput.eval(fragCoord).a * uSurfaceScale);
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

        private const val BLEND_SHADER = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform int uMode;
            half4 main(float2 fragCoord) {
                float4 src = uIn2.eval(fragCoord);
                float4 dst = uInput.eval(fragCoord);
                if (uMode == 0) return half4(dst);
                if (uMode == 1) return half4(src * dst + src * (1.0 - dst.a) + dst * (1.0 - src.a));
                if (uMode == 2) return half4(src + dst - src * dst);
                if (uMode == 3) return half4(min(src * dst.a, dst * src.a) + src * (1.0 - dst.a) + dst * (1.0 - src.a));
                if (uMode == 4) return half4(max(src * dst.a, dst * src.a) + src * (1.0 - dst.a) + dst * (1.0 - src.a));
                return half4(dst);
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
            half4 main(float2 fragCoord) {
                return uColor;
            }
        """

        private const val TILE_SHADER = """
            uniform shader uInput;
            uniform float4 uRect;
            uniform float2 uOffset;
            half4 main(float2 fragCoord) {
                float2 localCoord = fragCoord - uOffset;
                float w = uRect.z - uRect.x;
                float h = uRect.w - uRect.y;
                float2 coord = float2(
                    mod(localCoord.x - uRect.x, w),
                    mod(localCoord.y - uRect.y, h)
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
            uniform float2 uUnitSize;
            uniform float2 uUserLeftTop;
            uniform float2 uInvCanvasScale;
            uniform float2 uOffset;

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
                float2 local = fragCoord - uOffset;
                float2 user = uUserLeftTop + local * uInvCanvasScale;
                float2 primitive = (user - uOrigin) / uUnitSize;
                float2 p = primitive * uBaseFrequency;
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
