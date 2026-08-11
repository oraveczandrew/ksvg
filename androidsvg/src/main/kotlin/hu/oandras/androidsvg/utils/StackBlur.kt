package hu.oandras.androidsvg.utils

import kotlin.math.abs

internal fun stackBlur(pix: IntArray, w: Int, h: Int, radius: Int, horizontal: Boolean) {
    val div = radius + radius + 1
    val divSum = (radius + 1) * (radius + 1)
    val dv = IntArray(256 * divSum) { it / divSum }

    val stack = Array(div) { IntArray(4) }
    val r1 = radius + 1

    val outerLimit = if (horizontal) h else w
    val innerLimit = if (horizontal) w else h
    val innerMax = innerLimit - 1

    for (i in 0 until outerLimit) {
        var aSum = 0
        var rSum = 0
        var gSum = 0
        var bSum = 0
        var aOutSum = 0
        var rOutSum = 0
        var gOutSum = 0
        var bOutSum = 0
        var aInSum = 0
        var rInSum = 0
        var gInSum = 0
        var bInSum = 0

        for (j in -radius..radius) {
            val pos = if (horizontal) {
                i * w + clamp(j, 0, innerMax)
            } else {
                clamp(j, 0, innerMax) * w + i
            }
            val p = pix[pos]
            val a = p shr 24 and 0xff
            val sir = stack[j + radius]
            sir[0] = a
            sir[1] = ((p shr 16 and 0xff) * a + 127) / 255
            sir[2] = ((p shr 8 and 0xff) * a + 127) / 255
            sir[3] = (p and 0xff * a + 127) / 255

            val rbs = r1 - abs(j)
            aSum += sir[0] * rbs
            rSum += sir[1] * rbs
            gSum += sir[2] * rbs
            bSum += sir[3] * rbs

            if (j > 0) {
                aInSum += sir[0]
                rInSum += sir[1]
                gInSum += sir[2]
                bInSum += sir[3]
            } else {
                aOutSum += sir[0]
                rOutSum += sir[1]
                gOutSum += sir[2]
                bOutSum += sir[3]
            }
        }

        var stackPointer = radius
        for (j in 0 until innerLimit) {
            val pos = if (horizontal) i * w + j else j * w + i
            val aOut = dv[aSum]
            if (aOut > 0) {
                val r = (dv[rSum] * 255 + aOut / 2) / aOut
                val g = (dv[gSum] * 255 + aOut / 2) / aOut
                val b = (dv[bSum] * 255 + aOut / 2) / aOut
                pix[pos] = argb(aOut, clamp255(r), clamp255(g), clamp255(b))
            } else {
                pix[pos] = 0
            }

            aSum -= aOutSum
            rSum -= rOutSum
            gSum -= gOutSum
            bSum -= bOutSum

            val stackStart = (stackPointer - radius + div) % div
            val sirOut = stack[stackStart]
            aOutSum -= sirOut[0]
            rOutSum -= sirOut[1]
            gOutSum -= sirOut[2]
            bOutSum -= sirOut[3]

            val nextPos = if (horizontal) {
                i * w + clamp(j + r1, 0, innerMax)
            } else {
                clamp(j + r1, 0, innerMax) * w + i
            }
            val pNext = pix[nextPos]
            val aNext = pNext shr 24 and 0xff
            sirOut[0] = aNext
            sirOut[1] = ((pNext shr 16 and 0xff) * aNext + 127) / 255
            sirOut[2] = ((pNext shr 8 and 0xff) * aNext + 127) / 255
            sirOut[3] = (pNext and 0xff * aNext + 127) / 255

            aInSum += sirOut[0]
            rInSum += sirOut[1]
            gInSum += sirOut[2]
            bInSum += sirOut[3]
            aSum += aInSum
            rSum += rInSum
            gSum += gInSum
            bSum += bInSum

            stackPointer = (stackPointer + 1) % div
            val sirIn = stack[stackPointer]
            aOutSum += sirIn[0]
            rOutSum += sirIn[1]
            gOutSum += sirIn[2]
            bOutSum += sirIn[3]
            aInSum -= sirIn[0]
            rInSum -= sirIn[1]
            gInSum -= sirIn[2]
            bInSum -= sirIn[3]
        }
    }
}