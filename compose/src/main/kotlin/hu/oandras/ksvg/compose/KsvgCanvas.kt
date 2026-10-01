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

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import hu.oandras.ksvg.RenderOptions
import hu.oandras.ksvg.SVG

/**
 * Renders a static SVG document directly into the Compose canvas, without an intermediate
 * `Drawable`.
 *
 * The full canvas bounds are used as the viewport. Unlike [KsvgImage] there is no intrinsic
 * size: the caller must always supply layout bounds via [modifier]. Animation is not driven
 * on this path (direct renders share the document clock); use [KsvgAnimatedImage] for SMIL.
 */
@Composable
public fun KsvgCanvas(
    svg: SVG?,
    modifier: Modifier = Modifier,
    renderOptions: RenderOptions? = null,
    contentDescription: String? = null,
) {
    if (svg == null) {
        // Reserve the caller-provided bounds while loading instead of collapsing to zero.
        Spacer(modifier = modifier)
        return
    }
    // Snapshot the options once per composition input; the direct render path reads them
    // on every draw, so a stable instance avoids per-frame allocation.
    val options: RenderOptions? = remember(renderOptions) { renderOptions }
    Canvas(
        modifier = modifier.semantics {
            if (contentDescription != null) {
                this.contentDescription = contentDescription
            }
        },
    ) {
        val frameworkCanvas: android.graphics.Canvas = drawContext.canvas.nativeCanvas
        if (options == null) {
            svg.renderToCanvas(frameworkCanvas)
        } else {
            svg.renderToCanvas(frameworkCanvas, options)
        }
    }
}
