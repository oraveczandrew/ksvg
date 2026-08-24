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
import hu.oandras.ksvg.filtering.LightingNative
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
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

@SuppressLint("UseKtx")
context(renderContext: RenderContext)
private inline fun doLightingFilter(
    primitive: FilterPrimitive,
    light: Lighting?,
    surfaceScale: Float,
    pixels: IntArrayBucket,
    outPixels: IntArrayBucket,
    normal: NormalVector,
    lightVec: LightVector,
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
    computeIntensity: (NormalVector, LightVector) -> Float
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

    if (LightingNative.isAvailable) {
        val params = DoubleArray(8)
        var lightType = 0
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
        res.setPixels(out, 0, width, 0, 0, width, height)
        return res
    }

    for (y in clipTop until clipBottom) {
        val userY = userTop + y.toDouble() * invCanvasScaleY
        val uy = ((userY - originY) / primitiveUnitSizeY).toFloat()
        val rowOffset = y * width
        for (x in clipLeft until clipRight) {
            val userX = userLeft + x.toDouble() * invCanvasScaleX
            val ux = ((userX - originX) / primitiveUnitSizeX).toFloat()

            val surfaceZ = h(pix, width, height, x, y, surfaceScaleNormalized)
            resolveLightVector(lightSource, ux, uy, surfaceZ, lightVec)

            // 3x3 Sobel gradient estimation as per SVG spec
            val dzdx = (
                h(pix, width, height, x + 1, y - 1, surfaceScaleNormalized) + 2 * h(pix, width, height, x + 1, y, surfaceScaleNormalized) + h(pix, width, height, x + 1, y + 1, surfaceScaleNormalized) -
                (h(pix, width, height, x - 1, y - 1, surfaceScaleNormalized) + 2 * h(pix, width, height, x - 1, y, surfaceScaleNormalized) + h(pix, width, height, x - 1, y + 1, surfaceScaleNormalized))
            ) / (4f / canvasScaleX)
            val dzdy = (
                h(pix, width, height, x - 1, y + 1, surfaceScaleNormalized) + 2 * h(pix, width, height, x, y + 1, surfaceScaleNormalized) + h(pix, width, height, x + 1, y + 1, surfaceScaleNormalized) -
                (h(pix, width, height, x - 1, y - 1, surfaceScaleNormalized) + 2 * h(pix, width, height, x, y - 1, surfaceScaleNormalized) + h(pix, width, height, x + 1, y - 1, surfaceScaleNormalized))
            ) / (4f / canvasScaleY)

            surfaceNormal(dzdx, dzdy, normal)
            val intensity = computeIntensity(normal, lightVec)
            val outR = clamp255(lightR * intensity)
            val outG = clamp255(lightG * intensity)
            val outB = clamp255(lightB * intensity)
            val outA = if (alphaIsMaxOfChannels) maxOf(outR, outG, outB) else 255
            out[rowOffset + x] = argb(outA, outR, outG, outB)
        }
    }
    res.setPixels(out, 0, width, 0, 0, width, height)
    return res
}

private fun h(pix: IntArray, width: Int, height: Int, x: Int, y: Int, surfaceScaleNormalized: Float): Float {
    val cx = clamp(x, 0, width - 1)
    val cy = clamp(y, 0, height - 1)
    return (pix[cy * width + cx] shr 24 and 0xff) * surfaceScaleNormalized
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
        normal = primitiveNode.normal,
        lightVec = primitiveNode.lightVec,
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
    ) { normal, lightVec ->
        diffuseIntensity(normal, lightVec, diffuseConstant)
    }
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
        normal = primitiveNode.normal,
        lightVec = primitiveNode.lightVec,
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
    ) { normal, lightVec ->
        specularIntensity(normal, lightVec, specularConstant, specularExponent)
    }
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

private fun resolveLightVector(light: Lighting, x: Float, y: Float, surfaceZ: Float, out: LightVector) {
    when (light) {
        is FeDistantLight -> {
            val azimuth = light.azimuth.toRadians()
            val elevation = light.elevation.toRadians()

            out.x = cos(azimuth) * cos(elevation)
            out.y = sin(azimuth) * cos(elevation)
            out.z = sin(elevation)
            out.factor = 1f
        }

        is FePointLight -> {
            val vx = light.x - x
            val vy = light.y - y
            val vz = light.z - surfaceZ
            normalizeWithFactor(vx, vy, vz, out)
        }

        is FeSpotLight -> {
            val lx = light.x
            val ly = light.y
            val lz = light.z
            val vx = lx - x
            val vy = ly - y
            val vz = lz - surfaceZ
            normalizeWithFactor(vx, vy, vz, out)

            val tx = light.pointsAtX - lx
            val ty = light.pointsAtY - ly
            val tz = light.pointsAtZ - lz
            val tLen = sqrt(tx * tx + ty * ty + tz * tz)
            val factor = if (tLen == 0f) {
                1f
            } else {
                val sx = tx / tLen
                val sy = ty / tLen
                val sz = tz / tLen
                val toSurfaceDot = clamp(
                    n = sx * -out.x + sy * -out.y + sz * -out.z,
                    min = -1f,
                    max = 1f
                )
                val coneAngle = light.limitingConeAngle
                if (coneAngle != null) {
                    val cosLimit = cos(coneAngle.toRadians())
                    if (toSurfaceDot < cosLimit) 0f else toSurfaceDot
                } else {
                    toSurfaceDot
                }
            }

            out.factor = factor.coerceAtLeast(0f)
        }
    }
}

private fun surfaceNormal(dzdx: Float, dzdy: Float, out: NormalVector) {
    var nx = -dzdx
    var ny = -dzdy
    var nz = 1f
    val nLen = sqrt(nx * nx + ny * ny + nz * nz)
    if (nLen != 0f) {
        nx /= nLen
        ny /= nLen
        nz /= nLen
    }
    out.x = nx
    out.y = ny
    out.z = nz
}

private fun diffuseIntensity(normal: NormalVector, light: LightVector, diffuseConstant: Float): Float {
    val dot = (normal.x * light.x + normal.y * light.y + normal.z * light.z).coerceAtLeast(0f)
    return clamp(dot * diffuseConstant * light.factor, 0f, 1f)
}

private fun specularIntensity(
    normal: NormalVector,
    light: LightVector,
    specularConstant: Float,
    specularExponent: Float,
): Float {
    var hx = light.x
    var hy = light.y
    var hz = light.z + 1f
    val hLen = sqrt(hx * hx + hy * hy + hz * hz)
    if (hLen != 0f) {
        hx /= hLen
        hy /= hLen
        hz /= hLen
    }

    val ndoth = (normal.x * hx + normal.y * hy + normal.z * hz).coerceAtLeast(0f)
    return clamp(
        n = (specularConstant * ndoth.toDouble().pow(specularExponent.toDouble()) * light.factor).toFloat(),
        min = 0f,
        max = 1f
    )
}

private fun normalizeWithFactor(vx: Float, vy: Float, vz: Float, out: LightVector) {
    val vLen = sqrt(vx * vx + vy * vy + vz * vz)
    if (vLen == 0f) {
        out.x = 0f
        out.y = 0f
        out.z = 0f
        out.factor = 0f
    } else {
        out.x = vx / vLen
        out.y = vy / vLen
        out.z = vz / vLen
        out.factor = 1f
    }
}
