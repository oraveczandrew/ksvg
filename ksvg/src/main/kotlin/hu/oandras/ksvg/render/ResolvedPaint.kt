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

package hu.oandras.ksvg.render

import android.graphics.LinearGradient
import android.graphics.RadialGradient
import android.graphics.Shader.TileMode
import android.util.Log
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.SolidColor
import hu.oandras.ksvg.dom.gradient.Gradient
import hu.oandras.ksvg.dom.gradient.GradientLinear
import hu.oandras.ksvg.dom.gradient.GradientRadial
import hu.oandras.ksvg.dom.style.PaintReference
import hu.oandras.ksvg.dom.style.SvgPaint
import hu.oandras.ksvg.render.animation.AnimationNode

private const val TAG = "Renderer"

/**
 * The outcome of resolving a paint reference (e.g. fill="url(#grad)") at build time.
 *
 * Each node that references a gradient carries its own [Linear]/[Radial] instance with its own
 * render state (shader cache), so that different elements referencing the same gradient don't
 * share mutable geometry/color buffers.
 */
internal sealed class ResolvedPaint {
    // A paint reference whose href could not be resolved to a gradient or solid-color element.
    object Missing : ResolvedPaint()

    data class Solid(@JvmField val ref: SolidColor) : ResolvedPaint()

    class Linear(@JvmField val gradient: GradientLinear) : ResolvedPaint() {
        @JvmField
        var colors: IntArray = IntArray(0)
        @JvmField
        var positions: FloatArray = FloatArray(0)
        @JvmField
        var shader: LinearGradient? = null

        private var colorsHash = 0
        private var positionsHash = 0
        private var _x1 = 0f
        private var _y1 = 0f
        private var _x2 = 0f
        private var _y2 = 0f
        private var tileMode: TileMode? = null

        /**
         * Precomputed animation nodes (aligned with the gradient's DOM ancestor chain, root first),
         * and one entry per child <stop>. Non-null lets the renderer animate gradient stops and
         * inherited styles without reading the DOM `animations` at render time.
         */
        @JvmField
        var ancestorAnimationNodes: List<List<AnimationNode>>? = null

        @JvmField
        var stopNodes: List<StopRenderNode> = emptyList()

        fun updateGeometry(
            x1: Float, y1: Float, x2: Float, y2: Float, tileMode: TileMode,
        ): Boolean {
            return if (_x1 != x1 || _y1 != y1 || _x2 != x2 || _y2 != y2 || this.tileMode != tileMode) {
                _x1 = x1
                _y1 = y1
                _x2 = x2
                _y2 = y2
                this.tileMode = tileMode
                true
            } else {
                false
            }
        }

        fun colorsChanged(): Boolean {
            return colors.contentHashCode() != colorsHash ||
                positions.contentHashCode() != positionsHash
        }

        fun markColorsClean() {
            colorsHash = colors.contentHashCode()
            positionsHash = positions.contentHashCode()
        }
    }

    class Radial(@JvmField val gradient: GradientRadial) : ResolvedPaint() {
        @JvmField
        var colors: GradientColorArray? = null
        @JvmField
        var positions: FloatArray = FloatArray(0)
        @JvmField
        var shader: RadialGradient? = null
        private var colorsHash = 0
        private var positionsHash = 0
        private var _cx = 0f
        private var _cy = 0f
        private var _r = 0f
        private var _fx = 0f
        private var _fy = 0f
        private var _fr = 0f
        private var tileMode: TileMode? = null

        /**
         * Precomputed animation nodes (aligned with the gradient's DOM ancestor chain, root first),
         * and one entry per child <stop>. Non-null lets the renderer animate gradient stops and
         * inherited styles without reading the DOM `animations` at render time.
         */
        var ancestorAnimationNodes: List<List<AnimationNode>?>? = null
        var stopNodes: List<StopRenderNode> = emptyList()

        fun updateGeometry(
            cx: Float, cy: Float, r: Float, fx: Float, fy: Float, fr: Float, tileMode: TileMode,
        ): Boolean {
            return if (_cx != cx || _cy != cy || _r != r || _fx != fx || _fy != fy || _fr != fr || this.tileMode != tileMode) {
                _cx = cx
                _cy = cy
                _r = r
                _fx = fx
                _fy = fy
                _fr = fr
                this.tileMode = tileMode
                true
            } else {
                false
            }
        }

        fun colorsChanged(): Boolean {
            val c = colors ?: return true
            return c.contentHashCode() != colorsHash ||
                positions.contentHashCode() != positionsHash
        }

        fun markColorsClean() {
            colors?.let { colorsHash = it.contentHashCode() }
            positionsHash = positions.contentHashCode()
        }
    }
}

/**
 * Resolves a CSS paint value to the referenced gradient/solid-color element, if it is a paint reference.
 *
 * Returns null when the paint is not a [PaintReference] or does not reference a gradient/solid-color
 * (patterns are handled separately via [RenderNode.fillPatternNode]).
 */
internal fun resolvePaintReference(document: SVGImpl, paint: SvgPaint?): ResolvedPaint? {
    if (paint !is PaintReference) return null
    val ref = document.resolveIRI(paint.href) ?: return ResolvedPaint.Missing
    return when (ref) {
        is GradientLinear -> {
            ref.href?.let { fillInChainedGradientFields(ref, it) }
            ResolvedPaint.Linear(ref)
        }

        is GradientRadial -> {
            ref.href?.let { fillInChainedGradientFields(ref, it) }
            ResolvedPaint.Radial(ref)
        }

        is SolidColor -> ResolvedPaint.Solid(ref)
        else -> null
    }
}

/**
 * Any unspecified fields in this gradient can be 'borrowed' from another
 * gradient specified by the href attribute.
 */
internal fun fillInChainedGradientFields(gradient: Gradient, href: String) {
    // Locate the referenced object
    val ref = gradient.document.resolveIRI(href)
    if (ref == null) {
        Log.w(TAG, String.format("Gradient reference '%s' not found", href))
        return
    }
    if (ref !is Gradient) {
        Log.e(TAG, "Gradient href attributes must point to other gradient elements")
        return
    }
    if (ref === gradient) {
        Log.e(TAG, String.format("Circular reference in gradient href attribute '%s'", href))
        return
    }

    val gradientRef: Gradient = ref

    if (gradient.gradientUnitsAreUser == null) {
        gradient.gradientUnitsAreUser = gradientRef.gradientUnitsAreUser
    }
    if (gradient.gradientTransform == null) {
        gradient.gradientTransform = gradientRef.gradientTransform
    }
    if (gradient.spreadMethod == null) {
        gradient.spreadMethod = gradientRef.spreadMethod
    }
    if (gradient.childCount() == 0) {
        gradient.addAll(gradientRef.getChildren())
    }

    when (gradient) {
        is GradientLinear -> if (gradientRef is GradientLinear) {
            fillInChainedGradientFields(gradient, gradientRef)
        }

        is GradientRadial -> if (gradientRef is GradientRadial) {
            fillInChainedGradientFields(gradient, gradientRef)
        }
    }

    gradientRef.href?.let { fillInChainedGradientFields(gradient, it) }
}

private fun fillInChainedGradientFields(gradient: GradientLinear, grRef: GradientLinear) {
    if (gradient.x1 == null) gradient.x1 = grRef.x1
    if (gradient.y1 == null) gradient.y1 = grRef.y1
    if (gradient.x2 == null) gradient.x2 = grRef.x2
    if (gradient.y2 == null) gradient.y2 = grRef.y2
}

private fun fillInChainedGradientFields(gradient: GradientRadial, grRef: GradientRadial) {
    if (gradient.cx == null) gradient.cx = grRef.cx
    if (gradient.cy == null) gradient.cy = grRef.cy
    if (gradient.r == null) gradient.r = grRef.r
    if (gradient.fx == null) gradient.fx = grRef.fx
    if (gradient.fy == null) gradient.fy = grRef.fy
    if (gradient.fr == null) gradient.fr = grRef.fr
}
