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

import android.content.res.AssetManager
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.DefaultAlpha
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import hu.oandras.ksvg.logger.AndroidLoggerContext
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.KSVGDrawable
import hu.oandras.ksvg.logger.LoggerContext
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Loads and parses an SVG asset on a background thread, caching the parsed document across
 * recompositions.
 *
 * Returns `null` while loading and when loading/parsing fails, so callers can show a
 * placeholder; use the [SVG.getFromAsset] family directly when parse errors must surface.
 */
@Composable
public fun rememberSvgAsset(
    assetPath: String,
    parseAnimations: Boolean = false,
    dispatcher: CoroutineDispatcher = Dispatchers.IO,
    loggerContext: LoggerContext = AndroidLoggerContext,
    externalFileResolver: ExternalFileResolver? = null,
    isInternalEntitiesEnabled: Boolean = true,
): SVG? {
    val assets: AssetManager = LocalContext.current.assets
    return produceState<SVG?>(
        initialValue = null,
        assetPath,
        parseAnimations,
        dispatcher,
        loggerContext,
        externalFileResolver,
        isInternalEntitiesEnabled,
    ) {
        value = withContext(dispatcher) {
            try {
                SVG.getFromAsset(
                    assetManager = assets,
                    filename = assetPath,
                    parseAnimations = parseAnimations,
                    loggerContext = loggerContext,
                    externalFileResolver = externalFileResolver,
                    isInternalEntitiesEnabled = isInternalEntitiesEnabled,
                )
            } catch (_: Exception) {
                null
            }
        }
    }.value
}

/**
 * Displays a static SVG document.
 *
 * The parsed [SVG] document is shared and read-only; one `KSVGDrawable` is created per
 * composition (drawables must not be shared between concurrently drawn hosts). `renderOptions`
 * is treated as an immutable snapshot: it is copied when the drawable is created, so later
 * mutation does not re-trigger anything — pass a new instance to re-render.
 *
 * Sizing: SVGs without intrinsic width/height report `-1` intrinsics, so an unconstrained
 * layout collapses. Give the content an explicit size (e.g., `Modifier.size(96.dp)`) or set
 * explicit dimensions on the document.
 */
@Composable
public fun KsvgImage(
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
    val drawable: KSVGDrawable = remember(svg, renderOptions) {
        svg.toDrawable(renderOptions)
    }
    val painter: KsvgDrawablePainter = remember(drawable) {
        KsvgDrawablePainter(drawable)
    }
    DisposableEffect(painter) {
        drawable.setVisible(true, false)
        onDispose {
            drawable.setVisible(false, false)
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
 * Displays a static SVG loaded from the `assets` folder (e.g., `"visual/a_link.svg"`).
 *
 * See [KsvgImage] for sizing and options semantics.
 */
@Composable
public fun KsvgImage(
    assetPath: String,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    renderOptions: RenderOptions? = null,
    parseAnimations: Boolean = false,
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
        parseAnimations = parseAnimations,
        dispatcher = dispatcher,
        loggerContext = loggerContext,
        externalFileResolver = externalFileResolver,
        isInternalEntitiesEnabled = isInternalEntitiesEnabled,
    )
    KsvgImage(
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
