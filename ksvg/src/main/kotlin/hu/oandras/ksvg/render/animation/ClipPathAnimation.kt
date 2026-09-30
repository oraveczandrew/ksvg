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
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.animation.CalcMode
import hu.oandras.ksvg.dom.style.BasicShape
import hu.oandras.ksvg.dom.style.CSSClipPath
import hu.oandras.ksvg.dom.style.ClipPosition
import hu.oandras.ksvg.dom.style.ClipRadius
import hu.oandras.ksvg.utils.clamp

/**
 * Current `clip-path` value of an [AnimateClipPathNode] at [animationTimeMs],
 * or null when the animation is inactive (before `begin`, or finished without
 * `fill="freeze"`). Timing mirrors [AnimatePathNode.withPathAt]:
 * `to`-only ramps resolve against [base] at apply time, `calcMode="paced"`
 * degrades to linear segment timing (no paced table is built for shapes),
 * `additive`/`accumulate` are ignored (shapes do not add).
 */
internal fun AnimateClipPathNode.clipAt(animationTimeMs: Long, base: CSSClipPath?): CSSClipPath? {
    val elapsed = animationTimeMs - beginMs
    if (elapsed < 0L) return null

    if (isFinished(durMs, repeatCount, repeatDurMs, endMs, animationTimeMs, elapsed, minMs, maxMs) && !fillFreeze) return null

    val progress = calculateProgress(durMs, repeatCount, repeatDurMs, elapsed, minMs, maxMs)
    val values = effectiveValues
    val count = values.size
    if (count == 0) return null

    if (baseRelative && base != null) {
        // SMIL to-only: ramp base→to at apply time (the path baseRelative
        // pattern). Discrete freezes at `to`.
        if (calcMode == CalcMode.discrete) return values[0]
        val p = easedBaseProgress(calcMode, parsedKeySplines, progress)
        return interpolateClipPath(base, values[0], p)
    }

    if (count == 1) return values[0]

    if (calcMode == CalcMode.discrete) {
        return values[discreteClipIndex(count, keyTimes, progress)]
    }

    val segmentCount = count - 1
    var fromIdx = 0
    var toIdx = 1
    var eased = progress
    val keyTimes = this.keyTimes
    if (keyTimes != null && keyTimes.size == count) {
        for (i in 0 until segmentCount) {
            val start = keyTimes[i]
            val end = keyTimes[i + 1]
            if (progress <= end || i == segmentCount - 1) {
                val local = if (end == start) {
                    1f
                } else {
                    clamp((progress - start) / (end - start), 0f, 1f)
                }
                eased = if (parsedKeySplines != null && i < parsedKeySplines.size) {
                    applySplineInterpolation(local, parsedKeySplines[i])
                } else {
                    local
                }
                fromIdx = i
                toIdx = i + 1
                break
            }
        }
    } else {
        val scaled = progress * segmentCount
        val index = clamp(scaled.toInt(), 0, segmentCount - 1)
        val local = scaled - index
        eased = if (parsedKeySplines != null && index < parsedKeySplines.size) {
            applySplineInterpolation(local, parsedKeySplines[index])
        } else {
            local
        }
        fromIdx = index
        toIdx = index + 1
    }

    return interpolateClipPath(values[fromIdx], values[toIdx], eased)
}

/**
 * SMIL discrete segment index for a value list (same convention as
 * `selectAnimationSegmentDiscrete`: `values[i]` holds for
 * `keyTime[i] <= t < keyTime[i + 1]`).
 */
private fun discreteClipIndex(count: Int, keyTimes: FloatList?, progress: Float): Int {
    val segmentCount = count - 1
    if (keyTimes != null && keyTimes.size == count) {
        for (i in 0 until segmentCount) {
            if (progress < keyTimes[i + 1]) return i
        }
        return segmentCount
    }
    if (progress >= 1f) return segmentCount
    return clamp((progress * segmentCount).toInt(), 0, segmentCount - 1)
}

/**
 * Interpolates two `clip-path` values per the CSS Shapes rule: same basic-shape
 * function with the same reference box and the same arity interpolates
 * component-wise; everything else (`url()`, `none`, mismatched shapes or
 * boxes, `path()`) is discrete and holds [from].
 */
internal fun interpolateClipPath(from: CSSClipPath, to: CSSClipPath, progress: Float): CSSClipPath {
    // Exact endpoints even when the pair cannot interpolate (so a frozen end
    // state reaches `to`, and a zero progress holds `from`).
    if (progress <= 0f) return from
    if (progress >= 1f) return to
    if (from is CSSClipPath.ShapeClip && to is CSSClipPath.ShapeClip && from.refBox == to.refBox) {
        interpolateBasicShape(from.shape, to.shape, progress)?.let {
            return CSSClipPath.ShapeClip(it, from.refBox)
        }
    }
    return from
}

private fun interpolateBasicShape(from: BasicShape, to: BasicShape, p: Float): BasicShape? {
    return when {
        from is BasicShape.Circle && to is BasicShape.Circle -> BasicShape.Circle(
            r = lerpRadius(from.r, to.r, p) ?: return null,
            cx = lerpPosition(from.cx, to.cx, p) ?: return null,
            cy = lerpPosition(from.cy, to.cy, p) ?: return null,
        )

        from is BasicShape.Ellipse && to is BasicShape.Ellipse -> BasicShape.Ellipse(
            rx = lerpRadius(from.rx, to.rx, p) ?: return null,
            ry = lerpRadius(from.ry, to.ry, p) ?: return null,
            cx = lerpPosition(from.cx, to.cx, p) ?: return null,
            cy = lerpPosition(from.cy, to.cy, p) ?: return null,
        )

        from is BasicShape.Inset && to is BasicShape.Inset -> {
            val round = lerpRound(from.roundX, from.roundY, to.roundX, to.roundY, p) ?: return null
            BasicShape.Inset(
                top = lerpLength(from.top, to.top, p) ?: return null,
                right = lerpLength(from.right, to.right, p) ?: return null,
                bottom = lerpLength(from.bottom, to.bottom, p) ?: return null,
                left = lerpLength(from.left, to.left, p) ?: return null,
                roundX = round.first,
                roundY = round.second,
            )
        }

        from is BasicShape.Rect && to is BasicShape.Rect -> {
            val round = lerpRound(from.roundX, from.roundY, to.roundX, to.roundY, p) ?: return null
            BasicShape.Rect(
                top = lerpLength(from.top, to.top, p) ?: return null,
                right = lerpLength(from.right, to.right, p) ?: return null,
                bottom = lerpLength(from.bottom, to.bottom, p) ?: return null,
                left = lerpLength(from.left, to.left, p) ?: return null,
                roundX = round.first,
                roundY = round.second,
            )
        }

        from is BasicShape.Xywh && to is BasicShape.Xywh -> {
            val round = lerpRound(from.roundX, from.roundY, to.roundX, to.roundY, p) ?: return null
            BasicShape.Xywh(
                x = lerpLength(from.x, to.x, p) ?: return null,
                y = lerpLength(from.y, to.y, p) ?: return null,
                w = lerpLength(from.w, to.w, p) ?: return null,
                h = lerpLength(from.h, to.h, p) ?: return null,
                roundX = round.first,
                roundY = round.second,
            )
        }

        from is BasicShape.Polygon && to is BasicShape.Polygon ->
            if (from.fillRule == to.fillRule && from.points.size == to.points.size) {
                val points = ArrayList<CSSLength>(from.points.size)
                for (i in from.points.indices) {
                    points.add(lerpLength(from.points[i], to.points[i], p) ?: return null)
                }
                BasicShape.Polygon(points, from.fillRule)
            } else {
                null
            }

        // BasicShape.Path and mismatched kinds: discrete (hold `from`).
        else -> null
    }
}

/** Lengths only interpolate within the same unit (px↔%, em↔ex, … stay discrete). */
private fun lerpLength(a: CSSLength, b: CSSLength, p: Float): CSSLength? {
    if (a.unit != b.unit) return null
    return CSSLength(a.value + (b.value - a.value) * p, a.unit)
}

private fun lerpRadius(a: ClipRadius, b: ClipRadius, p: Float): ClipRadius? {
    if (a is ClipRadius.Len && b is ClipRadius.Len) {
        return ClipRadius.Len(lerpLength(a.v, b.v, p) ?: return null)
    }
    // Side keywords only continue identical ones (`closest-side` has no
    // numeric ramp against a length or against `farthest-side`).
    return if (a == b) a else null
}

private fun lerpPosition(a: ClipPosition, b: ClipPosition, p: Float): ClipPosition? {
    if (a is ClipPosition.Len && b is ClipPosition.Len) {
        return ClipPosition.Len(lerpLength(a.v, b.v, p) ?: return null)
    }
    if (a is ClipPosition.Offset && b is ClipPosition.Offset && a.anchor == b.anchor) {
        return ClipPosition.Offset(a.anchor, lerpLength(a.delta, b.delta, p) ?: return null)
    }
    return if (a == b) a else null
}

private fun lerpRound(
    aX: CSSLength?,
    aY: CSSLength?,
    bX: CSSLength?,
    bY: CSSLength?,
    p: Float
): Pair<CSSLength?, CSSLength?>? {
    if (aX == null && aY == null && bX == null && bY == null) return Pair(null, null)
    if (aX == null || bX == null) return null
    val x = lerpLength(aX, bX, p) ?: return null
    // A lone `round <r>` parses to roundX == roundY; a missing Y still means X.
    val y = if (aY == null && bY == null) {
        x
    } else if (aY != null && bY != null) {
        lerpLength(aY, bY, p) ?: return null
    } else {
        return null
    }
    return Pair(x, y)
}
