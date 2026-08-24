/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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

import android.graphics.Matrix
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.css.CSSLength
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Box
import hu.oandras.ksvg.dom.core.View
import kotlin.math.max
import kotlin.math.min

/**
 * Root-level viewBox/preserveAspectRatio overrides resolved from
 * render-options (`view()` / `viewBox()` / `preserveAspectRatio()`) or the
 * document root element. `null` means "no override, use element values".
 */
internal class RootViewOverrides(
    @JvmField val viewBoxOverride: Box?,
    @JvmField val parOverride: PreserveAspectRatio?,
)

/**
 * Resolves the effective root view overrides from render options.
 * Returns null when `options.view()` names an invalid <view> element
 * (the build must fail in that case).
 */
internal fun resolveRootViewOverrides(document: SVGImpl, options: RenderOptionsImpl): RootViewOverrides? {
    val rootObj = document.rootElement ?: return RootViewOverrides(null, null)
    if (options.hasView()) {
        val obj = document.getElementById(options.viewId)
        if (obj !is View) return null
        if (obj.viewBox == null) return null
        return RootViewOverrides(obj.viewBox, obj.preserveAspectRatio)
    }
    val viewBoxOverride = if (options.hasViewBox()) options.viewBox else rootObj.viewBox
    val parOverride = if (options.hasPreserveAspectRatio()) {
        options.preserveAspectRatio
    } else {
        rootObj.preserveAspectRatio
    }
    return RootViewOverrides(viewBoxOverride, parOverride)
}

/**
 * Builds a viewport Box from x/y/width/height lengths resolved in the current
 * [RenderContext]; missing width/height fall back to the effective viewport.
 */
context(renderContext: RenderContext)
internal fun makeViewportInContext(
    x: CSSLength?,
    y: CSSLength?,
    width: CSSLength?,
    height: CSSLength?
): Box {
    val viewPortUser = renderContext.effectiveViewPortInUserUnits
    return Box(
        minX = x?.floatValueXInContext() ?: 0f,
        minY = y?.floatValueYInContext() ?: 0f,
        width = width?.floatValueXInContext() ?: viewPortUser.width,
        height = height?.floatValueYInContext() ?: viewPortUser.height
    )
}

/**
 * Writes the viewBox->viewport fit for one viewport container into [outMatrix]
 * and returns the coordinate context the container's CONTENT lives in
 * (the viewBox when present, null otherwise = the viewport itself is user space).
 */
internal fun applyViewportTransform(
    viewPort: Box,
    viewBox: Box?,
    positioning: PreserveAspectRatio?,
    outMatrix: Matrix,
): Box? {
    return if (viewBox != null) {
        calculateViewBoxTransform(viewPort, viewBox, positioning, outMatrix)
        viewBox
    } else {
        outMatrix.preTranslate(viewPort.minX, viewPort.minY)
        null
    }
}

/*
   * Calculate the transform required to fit the supplied viewBox into the current viewPort.
   * See spec section 7.8 for an explanation of how this works.
   *
   * aspectRatioRule determines where the graphic is placed in the viewPort when aspect ratio
   *    is kept.  xMin means left justified, xMid is centred, xMax is right justified etc.
   * slice determines whether we see the whole image or not. True fill the whole viewport.
   *    If slice is false, the image will be "letter-boxed".
   *
   * Note box values in the two Box parameters would be in user units. If you pass values
   * that are in "objectBoundingBox" space, you will get incorrect results.
   */
internal fun calculateViewBoxTransform(
    viewPortMinX: Float,
    viewPortMinY: Float,
    viewPortWidth: Float,
    viewPortHeight: Float,
    viewBox: Box,
    positioning: PreserveAspectRatio?,
    outMatrix: Matrix
) {
    if (positioning == null) return

    val alignment = positioning.alignment ?: return

    val xScale = viewPortWidth / viewBox.width
    val yScale = viewPortHeight / viewBox.height
    var xOffset = -viewBox.minX
    var yOffset = -viewBox.minY

    if (positioning == PreserveAspectRatio.STRETCH) {
        outMatrix.preTranslate(viewPortMinX, viewPortMinY)
        outMatrix.preScale(xScale, yScale)
        outMatrix.preTranslate(xOffset, yOffset)
        return
    }

    val scale = if (positioning.scale == PreserveAspectRatio.Scale.slice) {
        max(xScale, yScale)
    } else {
        min(xScale, yScale)
    }
    val imageW = viewPortWidth / scale
    val imageH = viewPortHeight / scale

    when (alignment) {
        PreserveAspectRatio.Alignment.xMidYMin,
        PreserveAspectRatio.Alignment.xMidYMid,
        PreserveAspectRatio.Alignment.xMidYMax -> xOffset -= (viewBox.width - imageW) / 2
        PreserveAspectRatio.Alignment.xMaxYMin,
        PreserveAspectRatio.Alignment.xMaxYMid,
        PreserveAspectRatio.Alignment.xMaxYMax -> xOffset -= viewBox.width - imageW
        else -> {}
    }

    when (alignment) {
        PreserveAspectRatio.Alignment.xMinYMid,
        PreserveAspectRatio.Alignment.xMidYMid,
        PreserveAspectRatio.Alignment.xMaxYMid -> yOffset -= (viewBox.height - imageH) / 2
        PreserveAspectRatio.Alignment.xMinYMax,
        PreserveAspectRatio.Alignment.xMidYMax,
        PreserveAspectRatio.Alignment.xMaxYMax -> yOffset -= viewBox.height - imageH
        else -> {}
    }

    outMatrix.preTranslate(viewPortMinX, viewPortMinY)
    outMatrix.preScale(scale, scale)
    outMatrix.preTranslate(xOffset, yOffset)
}

internal fun calculateViewBoxTransform(
    viewPort: Box,
    viewBox: Box,
    positioning: PreserveAspectRatio?,
    outMatrix: Matrix
) {
    calculateViewBoxTransform(
        viewPortMinX = viewPort.minX,
        viewPortMinY = viewPort.minY,
        viewPortWidth = viewPort.width,
        viewPortHeight = viewPort.height,
        viewBox = viewBox,
        positioning = positioning,
        outMatrix = outMatrix
    )
}
