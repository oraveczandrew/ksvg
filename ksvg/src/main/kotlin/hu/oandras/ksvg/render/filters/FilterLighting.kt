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
import hu.oandras.ksvg.dom.COLOR_WHITE
import hu.oandras.ksvg.dom.SvgObject.FeDiffuseLighting
import hu.oandras.ksvg.dom.SvgObject.FeDistantLight
import hu.oandras.ksvg.dom.SvgObject.FePointLight
import hu.oandras.ksvg.dom.SvgObject.FeSpecularLighting
import hu.oandras.ksvg.dom.SvgObject.FeSpotLight
import hu.oandras.ksvg.dom.SvgObject.SvgLight
import hu.oandras.ksvg.utils.argb
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.clamp255
import hu.oandras.ksvg.utils.createBitmapSameAs
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
import hu.oandras.ksvg.utils.toRadians
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

@SuppressLint("UseKtx")
internal fun doFeDiffuseLightingFilter(
    primitive: FeDiffuseLighting,
    inputBitmap: Bitmap,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val light = primitive.light ?: return inputBitmap

    val width = inputBitmap.width
    val height = inputBitmap.height
    if (width <= 0 || height <= 0) {
        return inputBitmap
    }

    val surfaceScale = primitive.surfaceScale
    val diffuseConstant = primitive.diffuseConstant
    val styleColor = primitive.baseStyle?.color?.value ?: COLOR_WHITE
    val lightR = styleColor.red
    val lightG = styleColor.green
    val lightB = styleColor.blue

    val normal = NormalVector()
    val lightVec = LightVector()

    val res = createBitmapSameAs(inputBitmap)
    val pixels = IntArray(width * height)
    val outPixels = IntArray(width * height)
    inputBitmap.getPixels(pixels, 0, width, 0, 0, width, height)

    val surfaceScaleNormalized = surfaceScale / 255f

    fun h(x: Int, y: Int): Float {
        val cx = clamp(x, 0, width - 1)
        val cy = clamp(y, 0, height - 1)
        return (pixels[cy * width + cx] shr 24 and 0xff) * surfaceScaleNormalized
    }

    for (y in 0 until height) {
        val rowOffset = y * width
        for (x in 0 until width) {
            val surfaceZ = h(x, y)
            resolveLightVector(light, x, y, surfaceZ, lightVec)

            // 3x3 Sobel gradient estimation as per SVG spec
            val dzdx = (
                h(x + 1, y - 1) + 2 * h(x + 1, y) + h(x + 1, y + 1) -
                (h(x - 1, y - 1) + 2 * h(x - 1, y) + h(x - 1, y + 1))
            ) / (4f / canvasScaleX)
            val dzdy = (
                h(x - 1, y + 1) + 2 * h(x, y + 1) + h(x + 1, y + 1) -
                (h(x - 1, y - 1) + 2 * h(x, y - 1) + h(x + 1, y - 1))
            ) / (4f / canvasScaleY)
            
            surfaceNormal(dzdx, dzdy, normal)
            val intensity = diffuseIntensity(normal, lightVec, diffuseConstant)
            val outR = clamp255(lightR * intensity)
            val outG = clamp255(lightG * intensity)
            val outB = clamp255(lightB * intensity)
            outPixels[rowOffset + x] = argb(255, outR, outG, outB)
        }
    }
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

@SuppressLint("UseKtx")
internal fun doFeSpecularLightingFilter(
    primitive: FeSpecularLighting,
    inputBitmap: Bitmap,
    canvasScaleX: Float,
    canvasScaleY: Float,
): Bitmap {
    val light = primitive.light ?: return inputBitmap

    val width = inputBitmap.width
    val height = inputBitmap.height
    if (width <= 0 || height <= 0) {
        return inputBitmap
    }

    val surfaceScale = primitive.surfaceScale
    val specularConstant = primitive.specularConstant
    val specularExponent = clamp(primitive.specularExponent, 1f, 128f)
    val styleColor = primitive.baseStyle?.color?.value ?: COLOR_WHITE
    val lightR = styleColor.red
    val lightG = styleColor.green
    val lightB = styleColor.blue

    val normal = NormalVector()
    val lightVec = LightVector()

    val res = createBitmapSameAs(inputBitmap)
    val pixels = IntArray(width * height)
    val outPixels = IntArray(width * height)
    inputBitmap.getPixels(pixels, 0, width, 0, 0, width, height)

    val surfaceScaleNormalized = surfaceScale / 255f

    fun h(x: Int, y: Int): Float {
        val cx = clamp(x, 0, width - 1)
        val cy = clamp(y, 0, height - 1)
        return (pixels[cy * width + cx] shr 24 and 0xff) * surfaceScaleNormalized
    }

    for (y in 0 until height) {
        val rowOffset = y * width
        for (x in 0 until width) {
            val surfaceZ = h(x, y)
            resolveLightVector(light, x, y, surfaceZ, lightVec)

            // 3x3 Sobel gradient estimation as per SVG spec
            val dzdx = (
                h(x + 1, y - 1) + 2 * h(x + 1, y) + h(x + 1, y + 1) -
                (h(x - 1, y - 1) + 2 * h(x - 1, y) + h(x - 1, y + 1))
            ) / (4f / canvasScaleX)
            val dzdy = (
                h(x - 1, y + 1) + 2 * h(x, y + 1) + h(x + 1, y + 1) -
                (h(x - 1, y - 1) + 2 * h(x, y - 1) + h(x + 1, y - 1))
            ) / (4f / canvasScaleY)

            surfaceNormal(dzdx, dzdy, normal)
            val intensity = specularIntensity(normal, lightVec, specularConstant, specularExponent)
            val outR = clamp255(lightR * intensity)
            val outG = clamp255(lightG * intensity)
            val outB = clamp255(lightB * intensity)
            outPixels[rowOffset + x] = argb(255, outR, outG, outB)
        }
    }
    res.setPixels(outPixels, 0, width, 0, 0, width, height)
    return res
}

private data class LightVector(
    var x: Float,
    var y: Float,
    var z: Float,
    var factor: Float,
) {
    constructor(): this(
        x = 0f,
        y = 0f,
        z = 0f,
        factor = 0f,
    )
}

private data class NormalVector(
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

private fun resolveLightVector(light: SvgLight, x: Int, y: Int, surfaceZ: Float, out: LightVector) {
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
        (specularConstant * ndoth.toDouble()
            .pow(specularExponent.toDouble()) * light.factor).toFloat(), 0f, 1f
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
