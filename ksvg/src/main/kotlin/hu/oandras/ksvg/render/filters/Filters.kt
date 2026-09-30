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

import android.graphics.Bitmap
import hu.oandras.ksvg.render.FilterSourceMap

internal fun getFilterInput(
    name: String?,
    results: FilterSourceMap,
    lastResult: Bitmap?
): Bitmap? {
    if (name == null) return lastResult
    return results.get(name)
}

/**
 * Standard input names for the element's own paint, without its filter.
 * `FillPaint` is the fill without the stroke; `StrokePaint` the stroke
 * without the fill. Resolved from element-owned recordings (see
 * `FilterSourceMap`), never from primitive `result`s (a primitive shadowing
 * these names with its own `result` wins for later references, per spec).
 */
internal const val FILL_PAINT_INPUT: String = "FillPaint"
internal const val STROKE_PAINT_INPUT: String = "StrokePaint"

/**
 * Standard input names for the backdrop behind the filtered element.
 *
 * Per the documented deviation (see SUPPORT `<filter>` row) these resolve to
 * transparent on every path: a true backdrop snapshot would need readable
 * surfaces, which neither the software `Canvas` (no readback, opaque layers)
 * nor hardware canvases provide. Primitives still run with the transparent
 * input (defined output) instead of being skipped.
 */
internal const val BACKGROUND_IMAGE_INPUT: String = "BackgroundImage"
internal const val BACKGROUND_ALPHA_INPUT: String = "BackgroundAlpha"
