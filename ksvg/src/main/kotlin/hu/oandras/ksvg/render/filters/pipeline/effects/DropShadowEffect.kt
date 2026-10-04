/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg.render.filters.pipeline.effects

import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.RenderEffect
import android.graphics.Shader
import android.os.Build
import androidx.annotation.RequiresApi
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.render.ALPHA_MATRIX_COLOR_FILTER
import hu.oandras.ksvg.render.FeDropShadowRenderNode
import hu.oandras.ksvg.render.RenderContext
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthX
import hu.oandras.ksvg.render.filters.filterPrimitiveLengthY
import hu.oandras.ksvg.render.filters.pipeline.GpuFilterBackend.Companion.IDENTITY_EFFECT
import hu.oandras.ksvg.render.filters.pipeline.GpuFilterBackend.Companion.SOURCE_ALPHA_EFFECT
import hu.oandras.ksvg.render.filters.pipeline.GpuFilterBackend.Companion.skiaBlurRadiusForSigma

/**
 * Assembles the drop-shadow framework-effect stack (source alpha, blur,
 * offset, flood `SRC_IN`) without the final `SRC_OVER` composite, which
 * stays host-side (same idiom as the merge branch). Returns null when the
 * primitive carries an explicit subregion: the Skia dropShadow composite
 * ignores it (like the blur/offset declines) and would silently paint the
 * whole input, so the caller declines to software instead.
 *
 * @param inputEffect the primitive input (the shadow source and, host-side,
 * the `SRC_OVER` backdrop)
 * @param primitiveUnitsAreUser primitiveScaleX primitiveScaleY canvasScaleX
 * canvasScaleY the `dx`/`dy`/sigma length mapping (see
 * [filterPrimitiveLengthX])
 * @param baseStyle the style base used to resolve the flood color
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
context(renderContext: RenderContext)
internal fun createDropShadowEffect(
    node: FeDropShadowRenderNode,
    inputEffect: RenderEffect,
    primitiveUnitsAreUser: Boolean,
    primitiveScaleX: Float,
    primitiveScaleY: Float,
    canvasScaleX: Float,
    canvasScaleY: Float,
    baseStyle: Style,
): RenderEffect? {
    val shadowElement = node.sourceElement
    if (shadowElement.x != null || shadowElement.y != null ||
        shadowElement.width != null || shadowElement.height != null
    ) {
        return null
    }
    val alphaEffect = if (inputEffect == IDENTITY_EFFECT) {
        SOURCE_ALPHA_EFFECT
    } else {
        RenderEffect.createColorFilterEffect(
            ALPHA_MATRIX_COLOR_FILTER,
            inputEffect
        )
    }

    val blurNode = node.blurNode
    val sigmaX = blurNode.stdDeviationX * primitiveScaleX
    val sigmaY = blurNode.stdDeviationY * primitiveScaleY
    val blurredEffect = if (sigmaX > 0f || sigmaY > 0f) {
        RenderEffect.createBlurEffect(
            /* radiusX = */ skiaBlurRadiusForSigma(sigmaX),
            /* radiusY = */ skiaBlurRadiusForSigma(sigmaY),
            /* inputEffect = */ alphaEffect,
            /* edgeTreatment = */ Shader.TileMode.CLAMP,
        )
    } else {
        alphaEffect
    }

    val dx = filterPrimitiveLengthX(
        length = node.sourceElement.dx,
        primitiveUnitsAreUser = primitiveUnitsAreUser,
        primitiveScaleX = primitiveScaleX,
        canvasScaleX = canvasScaleX
    )
    val dy = filterPrimitiveLengthY(
        length = node.sourceElement.dy,
        primitiveUnitsAreUser = primitiveUnitsAreUser,
        primitiveScaleY = primitiveScaleY,
        canvasScaleY = canvasScaleY
    )
    val offsetEffect = RenderEffect.createOffsetEffect(dx, dy, blurredEffect)
    val floodColor = renderContext.resolveFloodColor(node, baseStyle)

    return RenderEffect.createColorFilterEffect(
        PorterDuffColorFilter(floodColor, PorterDuff.Mode.SRC_IN),
        offsetEffect
    )
}
