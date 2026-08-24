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

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.RectF
import hu.oandras.ksvg.dom.COLOR_WHITE
import hu.oandras.ksvg.filtering.KotlinKernels
import hu.oandras.ksvg.filtering.LightingNative
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.dom.filter.FeDistantLight
import hu.oandras.ksvg.dom.filter.FePointLight
import hu.oandras.ksvg.dom.filter.FeSpotLight
import hu.oandras.ksvg.dom.filter.FilterPrimitive
import hu.oandras.ksvg.dom.filter.Lighting
import hu.oandras.ksvg.dom.style.ColorValue
import hu.oandras.ksvg.render.FeDiffuseLightingRenderNode
import hu.oandras.ksvg.render.FeSpecularLightingRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.pool.IntArrayBucket
import hu.oandras.ksvg.utils.clamp

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
private inline fun doLightingFilter(
    primitive: FilterPrimitive,
    light: Lighting?,
    surfaceScale: Float,
    pixels: IntArrayBucket,
    outPixels: IntArrayBucket,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveOriginX: Float,
    primitiveOriginY: Float,
    regionLeft: Float,
    regionTop: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
    // feSpecularLighting produces a transparency map (alpha = max(R,G,B)); feDiffuseLighting is opaque.
    alphaIsMaxOfChannels: Boolean = false,
    k: Float = 0f,
    exponent: Float = 0f,
): Bitmap {
    val lightSource = light ?: return inputBitmap

    val width = inputBitmap.width
    val height = inputBitmap.height
    if (width <= 0 || height <= 0) {
        return inputBitmap
    }

    val styleColor = ((primitive.baseStyle?.lightingColor ?: primitive.baseStyle?.color) as? ColorValue)?.value ?: COLOR_WHITE
    val lightR = styleColor.red
    val lightG = styleColor.green
    val lightB = styleColor.blue

    val res = renderContext.bitmapPool.acquireSameAs(inputBitmap)
    val size = width * height
    val pix = pixels.getWithSize(size)
    val out = outPixels.getWithSize(size)
    inputBitmap.getPixels(pix, 0, width, 0, 0, width, height)

    val surfaceScaleNormalized = surfaceScale / 255f

    val invCanvasScaleX = 1.0 / canvasScaleX.toDouble()
    val invCanvasScaleY = 1.0 / canvasScaleY.toDouble()
    val userLeft = regionLeft.toDouble()
    val userTop = regionTop.toDouble()
    val originX = primitiveOriginX.toDouble()
    val originY = primitiveOriginY.toDouble()

    val primitiveUnitSizeX = primitiveScaleX.toDouble() / canvasScaleX.toDouble()
    val primitiveUnitSizeY = primitiveScaleY.toDouble() / canvasScaleY.toDouble()

    val clipLeft = clamp(((primitiveRegion.left - filterRegion.left)).toInt(), 0, width)
    val clipTop = clamp(((primitiveRegion.top - filterRegion.top)).toInt(), 0, height)
    val clipRight = clamp(((primitiveRegion.right - filterRegion.left)).toInt(), 0, width)
    val clipBottom = clamp(((primitiveRegion.bottom - filterRegion.top)).toInt(), 0, height)

    val params = DoubleArray(8)
    val lightType: Int
    when (lightSource) {
        is FeDistantLight -> {
            lightType = 0
            params[0] = lightSource.azimuth.toDouble()
            params[1] = lightSource.elevation.toDouble()
        }
        is FePointLight -> {
            lightType = 1
            params[0] = lightSource.x.toDouble()
            params[1] = lightSource.y.toDouble()
            params[2] = lightSource.z.toDouble()
        }
        is FeSpotLight -> {
            lightType = 2
            params[0] = lightSource.x.toDouble()
            params[1] = lightSource.y.toDouble()
            params[2] = lightSource.z.toDouble()
            params[3] = lightSource.pointsAtX.toDouble()
            params[4] = lightSource.pointsAtY.toDouble()
            params[5] = lightSource.pointsAtZ.toDouble()
            params[6] = lightSource.limitingConeAngle?.toDouble() ?: Double.NaN
        }
    }

    if (LightingNative.isAvailable) {
        LightingNative.apply(
            pix, out, width, height,
            clipLeft, clipTop, clipRight, clipBottom,
            surfaceScaleNormalized,
            invCanvasScaleX, invCanvasScaleY,
            userLeft, userTop, originX, originY,
            primitiveUnitSizeX, primitiveUnitSizeY,
            canvasScaleX, canvasScaleY,
            lightType, alphaIsMaxOfChannels,
            k, exponent,
            lightR, lightG, lightB,
            params
        )
    } else {
        KotlinKernels.lighting(
            pix, out, width, height,
            clipLeft, clipTop, clipRight, clipBottom,
            surfaceScaleNormalized,
            invCanvasScaleX, invCanvasScaleY,
            userLeft, userTop, originX, originY,
            primitiveUnitSizeX, primitiveUnitSizeY,
            canvasScaleX, canvasScaleY,
            lightType, alphaIsMaxOfChannels,
            k, exponent,
            lightR, lightG, lightB,
            params
        )
    }
    res.setPixels(out, 0, width, 0, 0, width, height)
    return res
}



context(renderContext: RenderContext)
internal fun doFeDiffuseLightingFilter(
    primitiveNode: FeDiffuseLightingRenderNode,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveOriginX: Float,
    primitiveOriginY: Float,
    regionLeft: Float,
    regionTop: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val diffuseConstant = primitive.diffuseConstant
    return doLightingFilter(
        primitive = primitive,
        light = primitive.light,
        surfaceScale = primitive.surfaceScale,
        pixels = primitiveNode.pixels,
        outPixels = primitiveNode.outPixels,
        inputBitmap = inputBitmap,
        primitiveScaleX = primitiveScaleX,
        primitiveScaleY = primitiveScaleY,
        primitiveOriginX = primitiveOriginX,
        primitiveOriginY = primitiveOriginY,
        regionLeft = regionLeft,
        regionTop = regionTop,
        canvasScaleX = canvasScaleX,
        canvasScaleY = canvasScaleY,
        primitiveRegion = primitiveRegion,
        filterRegion = filterRegion,
        k = diffuseConstant,
    )
}

context(renderContext: RenderContext)
internal fun doFeSpecularLightingFilter(
    primitiveNode: FeSpecularLightingRenderNode,
    inputBitmap: Bitmap,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    primitiveOriginX: Float,
    primitiveOriginY: Float,
    regionLeft: Float,
    regionTop: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    primitiveRegion: RectF,
    filterRegion: RectF,
): Bitmap {
    val primitive = primitiveNode.sourceElement
    val specularConstant = primitive.specularConstant
    val specularExponent = clamp(primitive.specularExponent, 1f, 128f)
    return doLightingFilter(
        primitive = primitive,
        light = primitive.light,
        surfaceScale = primitive.surfaceScale,
        pixels = primitiveNode.pixels,
        outPixels = primitiveNode.outPixels,
        inputBitmap = inputBitmap,
        primitiveScaleX = primitiveScaleX,
        primitiveScaleY = primitiveScaleY,
        primitiveOriginX = primitiveOriginX,
        primitiveOriginY = primitiveOriginY,
        regionLeft = regionLeft,
        regionTop = regionTop,
        canvasScaleX = canvasScaleX,
        canvasScaleY = canvasScaleY,
        primitiveRegion = primitiveRegion,
        filterRegion = filterRegion,
        alphaIsMaxOfChannels = true,
        k = specularConstant,
        exponent = specularExponent,
    )
}

internal class LightVector(
    @JvmField
    var x: Float,
    @JvmField
    var y: Float,
    @JvmField
    var z: Float,
    @JvmField
    var factor: Float,
) {
    constructor(): this(
        x = 0f,
        y = 0f,
        z = 0f,
        factor = 0f,
    )
}

internal class NormalVector(
    @JvmField
    var x: Float,
    @JvmField
    var y: Float,
    @JvmField
    var z: Float,
) {
    constructor(): this(
        x = 0f,
        y = 0f,
        z = 0f,
    )
}










