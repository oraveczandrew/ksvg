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

package hu.oandras.ksvg.render.animation

import androidx.collection.FloatList
import androidx.collection.IntList
import androidx.collection.MutableFloatList
import androidx.collection.mutableFloatListOf
import hu.oandras.ksvg.dom.animation.Animation
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.NumberParser
import hu.oandras.ksvg.parser.TextScanner
import hu.oandras.ksvg.utils.CubicBezier
import hu.oandras.ksvg.utils.charCount
import hu.oandras.ksvg.utils.clamp
import hu.oandras.ksvg.utils.optimizeReadOnlyList
import kotlin.math.abs
import kotlin.math.sqrt
import hu.oandras.ksvg.utils.forEachElement

internal fun interpolate(from: Float, to: Float, progress: Float): Float {
    return from + (to - from) * progress
}

internal fun parseKeySplines(keySplines: String?): List<CubicBezier>? {
    if (keySplines.isNullOrBlank()) return null
    val scanner = TextScanner(keySplines)
    val result = ArrayList<CubicBezier>(keySplines.charCount(';'))
    while (!scanner.empty()) {
        val x1 = scanner.nextFloat()
        scanner.skipWhitespace()
        val y1 = scanner.nextFloat()
        scanner.skipWhitespace()
        val x2 = scanner.nextFloat()
        scanner.skipWhitespace()
        val y2 = scanner.nextFloat()
        result.add(CubicBezier(x1, y1, x2, y2))
        scanner.skipSemicolonWhitespace()
    }
    return result.optimizeReadOnlyList()
}

internal fun applySplineInterpolation(progress: Float, bezier: CubicBezier): Float {
    val t = bezier.solveY(progress)
    val u = 1f - t
    val tt = t * t
    val uu = u * u
    return 3f * uu * t * bezier.y1 + 3f * u * tt * bezier.y2 + t * t * t
}

internal fun selectAnimationSegment(
    values: FloatList,
    stride: Int,
    keyTimes: FloatList?,
    progress: Float,
    parsedKeySplines: List<CubicBezier>?,
    out: FloatArray,
) {
    val elementCount = values.size / stride
    val segmentCount = elementCount - 1
    if (segmentCount <= 0) {
        if (values.size >= stride) {
            for (i in 0 until stride) {
                out[i] = values[i]
            }
        }
        return
    }

    if (keyTimes != null && keyTimes.size == elementCount) {
        for (i in 0 until segmentCount) {
            val start = keyTimes[i]
            val end = keyTimes[i + 1]
            if (progress <= end || i == segmentCount - 1) {
                val localProgress = if (end == start) {
                    1f
                } else {
                    clamp((progress - start) / (end - start), 0f, 1f)
                }
                val easedProgress = if (parsedKeySplines != null && i < parsedKeySplines.size) {
                    applySplineInterpolation(localProgress, parsedKeySplines[i])
                } else {
                    localProgress
                }
                val fromIdx = i * stride
                val toIdx = (i + 1) * stride
                for (j in 0 until stride) {
                    out[j] = interpolate(values[fromIdx + j], values[toIdx + j], easedProgress)
                }
                return
            }
        }
    }

    val scaled = progress * segmentCount
    val index = clamp(scaled.toInt(), 0, segmentCount - 1)
    val localProgress = scaled - index
    val easedProgress = if (parsedKeySplines != null && index < parsedKeySplines.size) {
        applySplineInterpolation(localProgress, parsedKeySplines[index])
    } else {
        localProgress
    }
    val fromIdx = index * stride
    val toIdx = (index + 1) * stride
    for (j in 0 until stride) {
        out[j] = interpolate(values[fromIdx + j], values[toIdx + j], easedProgress)
    }
}

internal fun selectAnimationSegmentDiscrete(
    values: FloatList,
    keyTimes: FloatList?,
    progress: Float,
): Float {
    val elementCount = values.size
    if (elementCount == 0) return 0f
    if (elementCount == 1) return values[0]

    val segmentCount = elementCount - 1

    if (keyTimes != null && keyTimes.size == elementCount) {
        for (i in 0 until segmentCount) {
            val end = keyTimes[i + 1]
            if (progress < end || i == segmentCount - 1) {
                return values[i + 1]
            }
        }
    }

    val scaled = progress * segmentCount
    val index = clamp(scaled.toInt(), 0, segmentCount - 1)
    return values[index + 1]
}

internal inline fun selectAnimationSegment(
    values: FloatList,
    keyTimes: FloatList?,
    progress: Float,
    interpolator: (from: Float, to: Float, progress: Float) -> Float,
    parsedKeySplines: List<CubicBezier>? = null
): Float {
    val elementCount = values.size
    val segmentCount = elementCount - 1
    if (segmentCount <= 0) {
        return if (values.size > 0) values[0] else 0f
    }

    if (keyTimes != null && keyTimes.size == elementCount) {
        for (i in 0 until segmentCount) {
            val start = keyTimes[i]
            val end = keyTimes[i + 1]
            if (progress <= end || i == segmentCount - 1) {
                val localProgress = if (end == start) {
                    1f
                } else {
                    clamp((progress - start) / (end - start), 0f, 1f)
                }
                val easedProgress = if (parsedKeySplines != null && i < parsedKeySplines.size) {
                    applySplineInterpolation(localProgress, parsedKeySplines[i])
                } else {
                    localProgress
                }
                return interpolator(values[i], values[i + 1], easedProgress)
            }
        }
    }

    val scaled = progress * segmentCount
    val index = clamp(scaled.toInt(), 0, segmentCount - 1)
    val localProgress = scaled - index
    val easedProgress = if (parsedKeySplines != null && index < parsedKeySplines.size) {
        applySplineInterpolation(localProgress, parsedKeySplines[index])
    } else {
        localProgress
    }
    return interpolator(values[index], values[index + 1], easedProgress)
}

internal inline fun selectAnimationSegment(
    values: IntList,
    keyTimes: FloatList?,
    progress: Float,
    interpolator: (from: Int, to: Int, progress: Float) -> Int,
    parsedKeySplines: List<CubicBezier>? = null
): Int {
    val elementCount = values.size
    val segmentCount = elementCount - 1
    if (segmentCount <= 0) {
        return if (values.size > 0) values[0] else 0
    }

    if (keyTimes != null && keyTimes.size == elementCount) {
        for (i in 0 until segmentCount) {
            val start = keyTimes[i]
            val end = keyTimes[i + 1]
            if (progress <= end || i == segmentCount - 1) {
                val localProgress = if (end == start) {
                    1f
                } else {
                    clamp((progress - start) / (end - start), 0f, 1f)
                }
                val easedProgress = if (parsedKeySplines != null && i < parsedKeySplines.size) {
                    applySplineInterpolation(localProgress, parsedKeySplines[i])
                } else {
                    localProgress
                }
                return interpolator(values[i], values[i + 1], easedProgress)
            }
        }
    }

    val scaled = progress * segmentCount
    val index = clamp(scaled.toInt(), 0, segmentCount - 1)
    val localProgress = scaled - index
    val easedProgress = if (parsedKeySplines != null && index < parsedKeySplines.size) {
        applySplineInterpolation(localProgress, parsedKeySplines[index])
    } else {
        localProgress
    }
    return interpolator(values[index], values[index + 1], easedProgress)
}

internal fun selectAnimationSegmentDiscrete(
    values: IntList,
    keyTimes: FloatList?,
    progress: Float,
): Int {
    val elementCount = values.size
    if (elementCount == 0) return 0
    if (elementCount == 1) return values[0]

    val segmentCount = elementCount - 1

    if (keyTimes != null && keyTimes.size == elementCount) {
        for (i in 0 until segmentCount) {
            val end = keyTimes[i + 1]
            if (progress < end || i == segmentCount - 1) {
                return values[i + 1]
            }
        }
    }

    val scaled = progress * segmentCount
    val index = clamp(scaled.toInt(), 0, segmentCount - 1)
    return values[index + 1]
}

internal fun selectAnimationSegmentDiscrete(
    values: FloatList,
    stride: Int,
    keyTimes: FloatList?,
    progress: Float,
    out: FloatArray,
) {
    val elementCount = values.size / stride
    if (elementCount == 0) return

    if (elementCount == 1) {
        for (i in 0 until stride) {
            out[i] = values[i]
        }
        return
    }

    val segmentCount = elementCount - 1

    if (keyTimes != null && keyTimes.size == elementCount) {
        for (i in 0 until segmentCount) {
            val end = keyTimes[i + 1]
            if (progress < end || i == segmentCount - 1) {
                val toIdx = (i + 1) * stride
                for (j in 0 until stride) {
                    out[j] = values[toIdx + j]
                }
                return
            }
        }
    }

    val scaled = progress * segmentCount
    val index = clamp(scaled.toInt(), 0, segmentCount - 1)
    val toIdx = (index + 1) * stride
    for (j in 0 until stride) {
        out[j] = values[toIdx + j]
    }
}

internal fun parseClockValueMillis(value: String): Long {
    return try {
        val trimmed = value.trim()
        return when {
            trimmed.endsWith("ms") -> NumberParser.parseNumber(trimmed, 0, trimmed.length - 2).toLong()
            trimmed.endsWith("s") -> (NumberParser.parseNumber(trimmed, 0, trimmed.length - 1) * 1000f).toLong()
            else -> trimmed.toFloat().toLong()
        }
    } catch (_: NumberFormatException) {
        0L
    }
}

internal fun parseSemicolonColorList(value: String): IntList {
    return TextScanner(value).nextSemicolonColorList()
}

internal fun parseSemicolonFloatList(value: String): FloatList {
    return TextScanner(value).nextSemicolonFloatList()
}

internal fun parseDashArrayKeyframes(value: String): List<FloatArray> {
    val scanner = TextScanner(value)
    val keyframes = mutableListOf<FloatArray>()
    while (!scanner.empty()) {
        scanner.skipWhitespace()
        if (scanner.empty()) break
        if (scanner.consume(';')) continue

        val numbers = mutableListOf<Float>()
        while (!scanner.empty()) {
            scanner.skipWhitespace()
            if (scanner.empty()) break
            if (scanner.consume(';')) break
            scanner.skipCommaWhitespace()
            val f = scanner.nextFloat()
            if (f.isNaN()) break
            numbers.add(f)
        }
        if (numbers.isNotEmpty()) {
            keyframes.add(numbers.toFloatArray())
        }
    }
    return keyframes
}

internal fun normalizeDashArrays(keyframes: List<FloatArray>): Pair<Int, FloatList> {
    if (keyframes.isEmpty()) return 0 to mutableFloatListOf()

    val maxLen = keyframes.maxOf { it.size }
    if (maxLen == 0) return 0 to mutableFloatListOf()

    val result = MutableFloatList(maxLen * keyframes.size)
    keyframes.forEachElement { keyframe ->
        for (i in 0 until maxLen) {
            result.add(keyframe[i % keyframe.size])
        }
    }
    return maxLen to result
}

internal fun parseSingleDashArray(value: String): FloatArray {
    val scanner = TextScanner(value)
    val numbers = mutableListOf<Float>()
    while (!scanner.empty()) {
        scanner.skipCommaWhitespace()
        if (scanner.empty()) break
        val f = scanner.nextFloat()
        if (f.isNaN()) break
        numbers.add(f)
    }
    return numbers.toFloatArray()
}

internal fun computePacedKeyTimesFloat(values: FloatList): FloatList? {
    if (values.size <= 1) return null
    val segmentCount = values.size - 1
    val distances = MutableFloatList(segmentCount + 1)
    distances.add(0f)
    var total = 0f
    for (i in 0 until segmentCount) {
        total += abs(values[i + 1] - values[i])
        distances.add(total)
    }
    if (total == 0f) return null
    val result = MutableFloatList(segmentCount + 1)
    distances.forEach { d ->
        result.add(d / total)
    }
    return result
}

internal fun computePacedKeyTimesColor(values: IntList): FloatList? {
    if (values.size <= 1) return null
    val segmentCount = values.size - 1
    val distances = MutableFloatList(segmentCount + 1)
    distances.add(0f)
    var total = 0f
    for (i in 0 until segmentCount) {
        val c1 = values[i]
        val c2 = values[i + 1]
        val dr = ((c1 shr 16) and 0xFF) - ((c2 shr 16) and 0xFF)
        val dg = ((c1 shr 8) and 0xFF) - ((c2 shr 8) and 0xFF)
        val db = (c1 and 0xFF) - (c2 and 0xFF)
        total += sqrt((dr * dr + dg * dg + db * db).toDouble()).toFloat()
        distances.add(total)
    }
    if (total == 0f) return null
    val result = MutableFloatList(segmentCount + 1)
    distances.forEach { d ->
        result.add(d / total)
    }
    return result
}

internal fun computePacedKeyTimesDashArray(values: FloatList, stride: Int): FloatList? {
    val elementCount = values.size / stride
    if (elementCount <= 1) return null
    val segmentCount = elementCount - 1
    val distances = MutableFloatList(segmentCount + 1)
    distances.add(0f)
    var total = 0f
    for (i in 0 until segmentCount) {
        var segDist = 0f
        for (j in 0 until stride) {
            val diff = values[(i + 1) * stride + j] - values[i * stride + j]
            segDist += diff * diff
        }
        total += sqrt(segDist.toDouble()).toFloat()
        distances.add(total)
    }
    if (total == 0f) return null
    val result = MutableFloatList(segmentCount + 1)
    distances.forEach { d ->
        result.add(d / total)
    }
    return result
}

internal fun isColorAttribute(attr: SVGAttr?): Boolean {
    return when (attr) {
        SVGAttr.fill,
        SVGAttr.stroke,
        SVGAttr.stop_color,
        SVGAttr.flood_color,
        SVGAttr.color,
        SVGAttr.lighting_color,
        SVGAttr.solid_color -> true
        else -> false
    }
}

internal fun calculateProgress(
    durMs: Long,
    repeatCount: Int,
    repeatDurMs: Long,
    elapsed: Long,
): Float {
    if (durMs <= 0) return 1f

    val totalDurMs = if (repeatCount == Animation.REPEAT_INDEFINITE) {
        Long.MAX_VALUE
    } else {
        durMs * repeatCount
    }

    val activeDurMs = if (repeatDurMs != 0L) {
        if (repeatDurMs == Animation.REPEAT_INDEFINITE.toLong()) {
            Long.MAX_VALUE
        } else {
            minOf(totalDurMs, repeatDurMs)
        }
    } else {
        totalDurMs
    }

    return if (elapsed >= activeDurMs) {
        1f
    } else {
        (elapsed % durMs).toFloat() / durMs.toFloat()
    }
}

internal fun isFinished(
    durMs: Long,
    repeatCount: Int,
    repeatDurMs: Long,
    endMs: Long,
    animationTimeMs: Long,
    elapsed: Long,
): Boolean {
    if (animationTimeMs >= endMs) return true

    val totalDurMs = if (repeatCount == Animation.REPEAT_INDEFINITE) {
        Long.MAX_VALUE
    } else {
        durMs * repeatCount
    }

    val activeDurMs = if (repeatDurMs != 0L) {
        if (repeatDurMs == Animation.REPEAT_INDEFINITE.toLong()) {
            Long.MAX_VALUE
        } else {
            minOf(totalDurMs, repeatDurMs)
        }
    } else {
        totalDurMs
    }

    return elapsed >= activeDurMs
}
