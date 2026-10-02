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

package hu.oandras.ksvg.compose

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.DefaultAlpha
import androidx.compose.ui.layout.ContentScale
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import hu.oandras.ksvg.logger.AndroidLoggerContext
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.KSVGAnimatedDrawable
import hu.oandras.ksvg.logger.LoggerContext
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers

/**
 * Displays an animated SVG document (SMIL `<animate>` family).
 *
 * The document must have been parsed with `parseAnimations = true`; [KSVGAnimatedDrawable.start]
 * is a no-op for documents without animations, so this composable is safe to use unconditionally.
 *
 * Lifecycle: the animation starts when the composition enters and follows `ON_START`/`ON_STOP`
 * via `setVisible` (which pauses the frame ticker but keeps pooled render memory, so resume is
 * cheap). Disposal stops the drawable terminally and releases its pools.
 */
@Composable
public fun KsvgAnimatedImage(
    svg: SVG?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    renderOptions: RenderOptions? = null,
    alignment: Alignment = Alignment.Center,
    contentScale: ContentScale = ContentScale.Fit,
    alpha: Float = DefaultAlpha,
    colorFilter: ColorFilter? = null,
) {
    if (svg == null) {
        // Reserve the caller-provided bounds while loading instead of collapsing to zero.
        Spacer(modifier = modifier)
        return
    }
    val drawable: KSVGAnimatedDrawable = remember(svg, renderOptions) {
        svg.toAnimatedDrawable(renderOptions)
    }
    val painter: KsvgDrawablePainter = remember(drawable) {
        KsvgDrawablePainter(drawable)
    }
    val lifecycle: Lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, painter) {
        drawable.setVisible(visible = true, restart = false)
        drawable.start()
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> drawable.setVisible(visible = true, restart = false)
                Lifecycle.Event.ON_STOP -> drawable.setVisible(visible = false, restart = false)
                else -> {}
            }
        }
        lifecycle.addObserver(observer)
        onDispose {
            lifecycle.removeObserver(observer)
            drawable.setVisible(visible = false, restart = false)
            drawable.stop()
            painter.release()
        }
    }
    Image(
        painter = painter,
        contentDescription = contentDescription,
        modifier = modifier,
        alignment = alignment,
        contentScale = contentScale,
        alpha = alpha,
        colorFilter = colorFilter,
    )
}

/**
 * Displays an animated SVG loaded from the `assets` folder.
 *
 * The asset is always parsed with `parseAnimations = true`. See [KsvgAnimatedImage].
 */
@Composable
public fun KsvgAnimatedImage(
    assetPath: String,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    renderOptions: RenderOptions? = null,
    dispatcher: CoroutineDispatcher = Dispatchers.IO,
    loggerContext: LoggerContext = AndroidLoggerContext,
    externalFileResolver: ExternalFileResolver? = null,
    isInternalEntitiesEnabled: Boolean = true,
    alignment: Alignment = Alignment.Center,
    contentScale: ContentScale = ContentScale.Fit,
    alpha: Float = DefaultAlpha,
    colorFilter: ColorFilter? = null,
) {
    val svg: SVG? = rememberSvgAsset(
        assetPath = assetPath,
        parseAnimations = true,
        dispatcher = dispatcher,
        loggerContext = loggerContext,
        externalFileResolver = externalFileResolver,
        isInternalEntitiesEnabled = isInternalEntitiesEnabled,
    )
    KsvgAnimatedImage(
        svg = svg,
        contentDescription = contentDescription,
        modifier = modifier,
        renderOptions = renderOptions,
        alignment = alignment,
        contentScale = contentScale,
        alpha = alpha,
        colorFilter = colorFilter,
    )
}
