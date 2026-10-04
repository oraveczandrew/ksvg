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

package hu.oandras.ksvg.showcase

import android.content.Context
import android.graphics.drawable.Drawable
import android.util.TypedValue
import hu.oandras.ksvg.SVG

internal fun dpInPixels(context: Context, dp: Float): Int {
    return TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        dp,
        context.resources.displayMetrics
    ).toInt()
}

internal fun Context.ksvgMenuIcon(svg: String, fallbackRes: Int): Drawable {
    try {
        return SVG.getFromString(svg).toDrawable()
    } catch (_: Exception) {
        // Fall through to the fallback drawable below.
    }
    return checkNotNull(getDrawable(fallbackRes)) { "Missing fallback drawable resource" }
}
