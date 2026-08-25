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
import android.graphics.ColorMatrixColorFilter
import android.graphics.RectF
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.filter.FeStitchTiles
import hu.oandras.ksvg.dom.filter.FeTurbulenceType
import hu.oandras.ksvg.dom.filter.FeDisplacementMap
import hu.oandras.ksvg.dom.filter.FeChannelSelector
import hu.oandras.ksvg.dom.filter.FeMorphology
import hu.oandras.ksvg.dom.filter.FeConvolveMatrix
import hu.oandras.ksvg.dom.filter.FeMorphologyOperator
import hu.oandras.ksvg.dom.filter.FeBlendMode
import hu.oandras.ksvg.dom.filter.FeCompositeOperator
import hu.oandras.ksvg.render.FilterRenderNode
import hu.oandras.ksvg.render.FeTurbulenceRenderNode
import hu.oandras.ksvg.render.FeDisplacementMapRenderNode
import hu.oandras.ksvg.render.FeMorphologyRenderNode
import hu.oandras.ksvg.render.FeConvolveMatrixRenderNode
import hu.oandras.ksvg.render.FeComponentTransferRenderNode
import hu.oandras.ksvg.render.FeBlendRenderNode
import hu.oandras.ksvg.render.FeCompositeRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.filters.buildColorMatrix
import hu.oandras.ksvg.render.FeColorMatrixRenderNode
import hu.oandras.ksvg.render.FeGaussianBlurRenderNode
import hu.oandras.ksvg.render.FeOffsetRenderNode
import hu.oandras.ksvg.utils.forEachElement
import kotlin.math.ceil

/**
 * AGSL (RuntimeShader) GPU backend (API 33+, hardware canvas only).
 *
 * Extends [FilterPipelineImpl31] to add support for complex primitives via
 * AGSL shaderek: feTurbulence, feDisplacementMap, etc.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
internal class FilterPipelineImpl33 internal constructor(
    renderContext: RenderContext,
) : FilterPipelineImpl31(renderContext) {

    override fun supports(primitives: FilterPrimitiveSet): Boolean {
        val supportedMask = FilterPrimitiveSet.FLAG_COLOR_MATRIX or
                FilterPrimitiveSet.FLAG_GAUSSIAN_BLUR or
                FilterPrimitiveSet.FLAG_OFFSET or
                FilterPrimitiveSet.FLAG_TURBULENCE or
                FilterPrimitiveSet.FLAG_DISPLACEMENT_MAP or
                FilterPrimitiveSet.FLAG_MORPHOLOGY or
                FilterPrimitiveSet.FLAG_CONVOLVE_MATRIX or
                FilterPrimitiveSet.FLAG_COMPONENT_TRANSFER or
                FilterPrimitiveSet.FLAG_BLEND or
                FilterPrimitiveSet.FLAG_COMPOSITE
        
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
        boundingBox: Box,
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
        val namedShaders = mutableMapOf<String, RuntimeShader>()
        var first = true
        var padX = 0
        var padY = 0

        val filter = filterNode.sourceElement
        val primitiveUnitsAreUser = filter.primitiveUnitsAreUser != false

        filterNode.primitives.forEachElement { primitive ->
            val element = primitive.sourceElement
            var currentShader: RuntimeShader? = null

            val effect = when (primitive) {
                is FeTurbulenceRenderNode -> {
                    if (!first) return null // Turbulence must be the first primitive (it ignores input)
                    val shader = buildTurbulenceShader(
                        primitive, scaleX, scaleY, 
                        filterRegion, sx, sy, boundingBox,
                        padX, padY,
                        primitiveUnitsAreUser
                    )
                    currentShader = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "in_source")
                }
                is FeDisplacementMapRenderNode -> {
                    val displacementMap = primitive.sourceElement
                    // in2: displacement map (must be a named shader we already saw, e.g. turbulence)
                    val in2Map = namedShaders[displacementMap.in2] ?: return null
                    
                    val shader = buildDisplacementMapShader(primitive, scaleX, scaleY, in2Map)
                    currentShader = shader
                    
                    // in: image to displace (must be previous or SourceGraphic)
                    if (displacementMap.`in` != null && displacementMap.`in` != "SourceGraphic" && displacementMap.`in` != previousResult) {
                        return null
                    }
                    
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput")
                }
                is FeMorphologyRenderNode -> {
                    val morphology = primitive.sourceElement
                    checkLinearInput(morphology.`in`, previousResult, first) ?: return null
                    
                    val rx = morphology.radiusX * scaleX
                    val ry = morphology.radiusY * scaleY
                    val erode = morphology.operator == FeMorphologyOperator.erode
                    
                    // Horizontal pass
                    val hShader = RuntimeShader(MORPHOLOGY_SHADER)
                    hShader.setFloatUniform("uRadius", rx, 0f)
                    hShader.setIntUniform("uErode", if (erode) 1 else 0)
                    val hEffect = RenderEffect.createRuntimeShaderEffect(hShader, "uInput")
                    
                    // Vertical pass
                    val vShader = RuntimeShader(MORPHOLOGY_SHADER)
                    vShader.setFloatUniform("uRadius", 0f, ry)
                    vShader.setIntUniform("uErode", if (erode) 1 else 0)
                    val vEffect = RenderEffect.createRuntimeShaderEffect(vShader, "uInput")
                    
                    RenderEffect.createChainEffect(vEffect, hEffect)
                }
                is FeConvolveMatrixRenderNode -> {
                    checkLinearInput(element.`in`, previousResult, first) ?: return null
                    
                    val shader = buildConvolveMatrixShader(primitive) ?: return null
                    currentShader = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput")
                }
                is FeComponentTransferRenderNode -> {
                    checkLinearInput(element.`in`, previousResult, first) ?: return null
                    
                    val shader = buildComponentTransferShader(primitive)
                    currentShader = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput")
                }
                is FeBlendRenderNode -> {
                    val blend = primitive.sourceElement
                    // For now, only support when 'in' is previous result and 'in2' is SourceGraphic
                    // or vice-versa.
                    if (blend.`in` != previousResult && !first) return null
                    if (blend.in2 != "SourceGraphic" && blend.in2 != null) return null
                    
                    val shader = RuntimeShader(BLEND_SHADER)
                    shader.setIntUniform("uMode", blend.mode.ordinal)
                    currentShader = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uIn2") // uIn2 is SourceGraphic
                }
                is FeCompositeRenderNode -> {
                    val composite = primitive.sourceElement
                    if (composite.`in` != previousResult && !first) return null
                    if (composite.in2 != "SourceGraphic" && composite.in2 != null) return null
                    
                    val shader = RuntimeShader(COMPOSITE_SHADER)
                    shader.setIntUniform("uOperator", composite.operator.ordinal)
                    shader.setFloatUniform("uK", composite.k1, composite.k2)
                    shader.setFloatUniform("uK34", composite.k3, composite.k4)
                    currentShader = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uIn2")
                }
                is FeColorMatrixRenderNode -> {
                    val colorMatrix = primitive.sourceElement
                    checkLinearInput(colorMatrix.`in`, previousResult, first) ?: return null
                    val matrix = buildColorMatrix(colorMatrix.type, colorMatrix.values)
                    
                    val shader = RuntimeShader(COLOR_MATRIX_SHADER)
                    shader.setFloatUniform("uMatrix", matrix.getArray())
                    currentShader = shader
                    RenderEffect.createRuntimeShaderEffect(shader, "uInput")
                }
                is FeGaussianBlurRenderNode -> {
                    checkLinearInput(element.`in`, previousResult, first) ?: return null
                    val sigmaX = primitive.stdDeviationX * scaleX
                    val sigmaY = primitive.stdDeviationY * scaleY
                    if (sigmaX <= 0f && sigmaY <= 0f) {
                        null
                    } else {
                        padX = maxOf(padX, ceil(sigmaX * 3f).toInt())
                        padY = maxOf(padY, ceil(sigmaY * 3f).toInt())
                        RenderEffect.createBlurEffect(sigmaX, sigmaY, Shader.TileMode.CLAMP)
                    }
                }
                is FeOffsetRenderNode -> {
                    val offset = primitive.sourceElement
                    checkLinearInput(offset.`in`, previousResult, first) ?: return null
                    val dx = filterPrimitiveLengthX(offset.dx,
                        primitiveUnitsAreUser = true, primitiveScaleX = scaleX, canvasScaleX = 1f)
                    val dy = filterPrimitiveLengthY(offset.dy,
                        primitiveUnitsAreUser = true, primitiveScaleY = scaleY, canvasScaleY = 1f)
                    if (dx == 0f && dy == 0f) null else RenderEffect.createOffsetEffect(dx, dy)
                }
                else -> return null
            }

            if (effect != null) {
                chain = if (chain == null || (first && primitive !is FeDisplacementMapRenderNode)) {
                    effect
                } else {
                    RenderEffect.createChainEffect(effect, chain)
                }
                element.result?.let { resultName ->
                    currentShader?.let { namedShaders[resultName] = it }
                }
            }
            
            previousResult = element.result
            first = false
        }

        val result = chain ?: return null
        val built = Chain(result, padX, padY, scaleX, scaleY)
        filterNode.gpuChain = built
        filterNode.gpuChainVersion = filterNode.version
        filterNode.gpuChainScaleX = scaleX
        filterNode.gpuChainScaleY = scaleY
        return built
    }

    private fun buildComponentTransferShader(
        node: FeComponentTransferRenderNode,
    ): RuntimeShader {
        val shader = RuntimeShader(COMPONENT_TRANSFER_SHADER)
        
        // Build LUT texture
        // node.lutTables is Array<ByteArray>(4) [R, G, B, A]
        // Wait! FeComponentTransferRenderNode says [A, R, G, B] in the comment?
        // Let's check RenderNode.kt.
        // Line 562: // Lazily built [A,R,G,B] 256-entry LUTs
        
        val lut = node.lutTables ?: Array(4) { ByteArray(256) { it.toByte() } }
        val bitmap = Bitmap.createBitmap(256, 1, Bitmap.Config.ARGB_8888)
        val pixels = IntArray(256)
        for (i in 0 until 256) {
            val a = lut[0][i].toInt() and 0xFF
            val r = lut[1][i].toInt() and 0xFF
            val g = lut[2][i].toInt() and 0xFF
            val b = lut[3][i].toInt() and 0xFF
            pixels[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
        }
        bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 1)
        
        val lutShader = BitmapShader(bitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        shader.setInputShader("uLut", lutShader)
        
        return shader
    }

    private fun buildConvolveMatrixShader(
        node: FeConvolveMatrixRenderNode,
    ): RuntimeShader? {
        val element = node.sourceElement
        val size = node.orderX * node.orderY
        if (size > 25) return null // AGSL uniform array size limit safety
        
        val shader = RuntimeShader(CONVOLVE_MATRIX_SHADER)
        shader.setFloatUniform("uKernel", node.kernel ?: FloatArray(size))
        shader.setIntUniform("uOrderX", node.orderX)
        shader.setIntUniform("uOrderY", node.orderY)
        shader.setIntUniform("uTargetX", node.targetX)
        shader.setIntUniform("uTargetY", node.targetY)
        shader.setFloatUniform("uDivisor", node.divisor)
        shader.setFloatUniform("uBias", node.bias)
        shader.setIntUniform("uPreserveAlpha", if (node.preserveAlpha) 1 else 0)
        shader.setIntUniform("uEdgeMode", element.edgeMode.ordinal)

        return shader
    }

    private fun buildDisplacementMapShader(
        node: FeDisplacementMapRenderNode,
        pScaleX: Float,
        pScaleY: Float,
        in2Map: RuntimeShader,
    ): RuntimeShader {
        val element = node.sourceElement
        val shader = RuntimeShader(DISPLACEMENT_MAP_SHADER)
        
        shader.setInputShader("uMap", in2Map)
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
        sx: Float,
        sy: Float,
        boundingBox: Box,
        padX: Int,
        padY: Int,
        primitiveUnitsAreUser: Boolean,
    ): RuntimeShader {
        val element = node.sourceElement
        val shader = RuntimeShader(TURBULENCE_SHADER)

        val latticeBitmap = obtainLatticeBitmap(node)
        val latticeShader = BitmapShader(latticeBitmap, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        shader.setInputShader("uLattice", latticeShader)

        val octaves = element.numOctaves.coerceIn(1, 8)
        val isFractal = element.type == FeTurbulenceType.fractalNoise

        shader.setFloatUniform("uBaseFrequency", element.baseFrequencyX, element.baseFrequencyY)
        shader.setIntUniform("uNumOctaves", octaves)
        shader.setIntUniform("uIsFractal", if (isFractal) 1 else 0)

        val invCanvasScaleX = 1f / sx
        val invCanvasScaleY = 1f / sy
        val userLeft = filterRegion.left
        val userTop = filterRegion.top
        val originX = if (primitiveUnitsAreUser) 0f else boundingBox.minX
        val originY = if (primitiveUnitsAreUser) 0f else boundingBox.minY
        val primitiveUnitSizeX = pScaleX / sx
        val primitiveUnitSizeY = pScaleY / sy

        shader.setFloatUniform("uInvCanvasScale", invCanvasScaleX, invCanvasScaleY)
        shader.setFloatUniform("uUserLeftTop", userLeft, userTop)
        shader.setFloatUniform("uOrigin", originX, originY)
        shader.setFloatUniform("uPrimitiveUnitSize", primitiveUnitSizeX, primitiveUnitSizeY)
        shader.setFloatUniform("uPad", padX.toFloat(), padY.toFloat())

        // For now, no stitch support in AGSL (period=0)
        shader.setFloatUniform("uTilePeriod", 0f, 0f)

        return shader
    }

    private fun obtainLatticeBitmap(node: FeTurbulenceRenderNode): Bitmap {
        var bitmap = node.gpuLatticeBitmap
        if (bitmap == null || bitmap.isRecycled || node.gpuLatticeVersion != node.version) {
            if (bitmap == null || bitmap.isRecycled) {
                bitmap = Bitmap.createBitmap(256, 3, Bitmap.Config.ARGB_8888)
                node.gpuLatticeBitmap = bitmap
            }

            val pixels = IntArray(256 * 3)
            val generators = node.generators
            for (i in 0 until 256) {
                // Row 0: p (permutations)
                val pR = generators[0].p[i] and 0xFF
                val pG = generators[1].p[i] and 0xFF
                val pB = generators[2].p[i] and 0xFF
                val pA = generators[3].p[i] and 0xFF
                pixels[i] = (pA shl 24) or (pR shl 16) or (pG shl 8) or pB

                // Row 1: gradX (mapped [-1, 1] to [0, 255])
                val gxR = ((generators[0].g2[i][0] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                val gxG = ((generators[1].g2[i][0] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                val gxB = ((generators[2].g2[i][0] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                val gxA = ((generators[3].g2[i][0] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                pixels[256 + i] = (gxA shl 24) or (gxR shl 16) or (gxG shl 8) or gxB

                // Row 2: gradY (mapped [-1, 1] to [0, 255])
                val gyR = ((generators[0].g2[i][1] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                val gyG = ((generators[1].g2[i][1] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                val gyB = ((generators[2].g2[i][1] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                val gyA = ((generators[3].g2[i][1] + 1.0) * 127.5).toInt().coerceIn(0, 255)
                pixels[512 + i] = (gyA shl 24) or (gyR shl 16) or (gyG shl 8) or gyB
            }
            bitmap.setPixels(pixels, 0, 256, 0, 0, 256, 3)
            node.gpuLatticeVersion = node.version
        }
        return bitmap
    }

    companion object {
        private const val COLOR_MATRIX_SHADER = """
            uniform shader uInput;
            uniform float uMatrix[20];

            half4 main(float2 fragCoord) {
                float4 c = uInput.eval(fragCoord);
                
                // Unpremultiply for matrix (standard SVG requirement)
                float alpha = c.a;
                if (alpha > 0.0) {
                    c.rgb /= alpha;
                }

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
                float4 src = uIn2.eval(fragCoord); // SourceGraphic
                float4 dst = uInput.eval(fragCoord); // Previous result
                
                // standard feBlend modes (simplified)
                if (uMode == 0) return half4(dst); // normal
                if (uMode == 1) return half4(src * dst + src * (1.0 - dst.a) + dst * (1.0 - src.a)); // multiply
                if (uMode == 2) return half4(src + dst - src * dst); // screen
                if (uMode == 3) return half4(min(src * dst.a, dst * src.a) + src * (1.0 - dst.a) + dst * (1.0 - src.a)); // darken
                if (uMode == 4) return half4(max(src * dst.a, dst * src.a) + src * (1.0 - dst.a) + dst * (1.0 - src.a)); // lighten
                return half4(dst);
            }
        """

        private const val COMPOSITE_SHADER = """
            uniform shader uInput;
            uniform shader uIn2;
            uniform int uOperator;
            uniform float2 uK; // k1, k2
            uniform float2 uK34; // k3, k4

            half4 main(float2 fragCoord) {
                float4 src = uIn2.eval(fragCoord);
                float4 dst = uInput.eval(fragCoord);
                
                if (uOperator == 0) return half4(src + dst * (1.0 - src.a)); // over
                if (uOperator == 1) return half4(src * dst.a); // in
                if (uOperator == 2) return half4(src * (1.0 - dst.a)); // out
                if (uOperator == 3) return half4(src * dst.a + dst * (1.0 - src.a)); // atop
                if (uOperator == 4) return half4(src * (1.0 - dst.a) + dst * (1.0 - src.a)); // xor
                if (uOperator == 5) { // arithmetic
                    float4 res = uK.x * src * dst + uK.y * src + uK34.x * dst + uK34.y;
                    return half4(clamp(res, 0.0, 1.0));
                }
                return half4(dst);
            }
        """

        private const val COMPONENT_TRANSFER_SHADER = """
            uniform shader uInput;
            uniform shader uLut;

            half4 main(float2 fragCoord) {
                float4 color = uInput.eval(fragCoord);
                
                // Unpremultiply for transfer (standard SVG requirement)
                float alpha = color.a;
                if (alpha > 0.0) {
                    color.rgb /= alpha;
                }
                
                // Lookup per channel
                float r = uLut.eval(float2(color.r * 255.0 + 0.5, 0.5)).r;
                float g = uLut.eval(float2(color.g * 255.0 + 0.5, 0.5)).g;
                float b = uLut.eval(float2(color.b * 255.0 + 0.5, 0.5)).b;
                float a = uLut.eval(float2(color.a * 255.0 + 0.5, 0.5)).a;
                
                // Premultiply back
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
            uniform int uEdgeMode;

            float4 sampleEdge(float2 coord) {
                // TODO: implement edge mode (clamp/wrap/none)
                return uInput.eval(coord);
            }

            half4 main(float2 fragCoord) {
                float4 sum = float4(0.0);
                for (int ky = 0; ky < 5; ++ky) {
                    if (ky >= uOrderY) break;
                    for (int kx = 0; kx < 5; ++kx) {
                        if (kx >= uOrderX) break;
                        float2 offset = float2(float(kx - uTargetX), float(ky - uTargetY));
                        float4 color = sampleEdge(fragCoord + offset);
                        sum += color * uKernel[ky * uOrderX + kx];
                    }
                }
                
                float4 res = sum / uDivisor + uBias;
                if (uPreserveAlpha != 0) {
                    res.a = uInput.eval(fragCoord).a;
                }
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
            uniform float2 uPad;

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
                    b0.x = b0.x % int(period.x);
                    if (b0.x < 0) b0.x += int(period.x);
                } else {
                    b0.x = b0.x & 255;
                }
                int bx1 = (period.x > 0.0) ? (b0.x + 1) % int(period.x) : (b0.x + 1) & 255;

                if (period.y > 0.0) {
                    b0.y = b0.y % int(period.y);
                    if (b0.y < 0) b0.y += int(period.y);
                } else {
                    b0.y = b0.y & 255;
                }
                int by1 = (period.y > 0.0) ? (b0.y + 1) % int(period.y) : (b0.y + 1) & 255;

                float4 i = getLattice(b0.x, 0) * 255.0;
                float4 j = getLattice(bx1, 0) * 255.0;

                int4 idx00 = int4(i + float4(b0.y) + 0.5) & 255;
                int4 idx10 = int4(j + float4(b0.y) + 0.5) & 255;
                int4 idx01 = int4(i + float4(by1) + 0.5) & 255;
                int4 idx11 = int4(j + float4(by1) + 0.5) & 255;
                
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
                float2 local = fragCoord - uPad;
                float2 user = uUserLeftTop + local * uInvCanvasScale;
                float2 primitive = (user - uOrigin) / uPrimitiveUnitSize;
                float2 p = primitive * uBaseFrequency;

                float4 sums = float4(0.0);
                float ratio = 1.0;
                float2 period = uTilePeriod;
                for (int i = 0; i < uNumOctaves; ++i) {
                    float4 n = noise2(p, period);
                    if (uIsFractal != 0) {
                        sums += n / ratio;
                    } else {
                        sums += abs(n) / ratio;
                    }
                    p *= 2.0;
                    ratio *= 2.0;
                    if (period.x > 0.0) period *= 2.0;
                }
                
                float4 finalVal;
                if (uIsFractal != 0) {
                    finalVal = (sums + 1.0) * 0.5;
                } else {
                    finalVal = sums;
                }
                finalVal = clamp(finalVal, 0.0, 1.0);
                return half4(finalVal.r * finalVal.a, finalVal.g * finalVal.a, finalVal.b * finalVal.a, finalVal.a);
            }
        """
    }
}
