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
package hu.oandras.ksvg.compat

import android.graphics.Canvas
import android.graphics.RectF
import android.os.Build
import androidx.annotation.RequiresApi

private interface CanvasCompat {
    fun quickReject(canvas: Canvas, r: RectF): Boolean
}

@RequiresApi(Build.VERSION_CODES.R)
private class CanvasCompatImpl30 : CanvasCompat {
    override fun quickReject(canvas: Canvas, r: RectF): Boolean {
        return canvas.quickReject(r)
    }
}

private class CanvasCompatImplBase : CanvasCompat {
    override fun quickReject(canvas: Canvas, r: RectF): Boolean {
        @Suppress("DEPRECATION")
        return canvas.quickReject(r, Canvas.EdgeType.AA)
    }
}

private val canvasCompat: CanvasCompat = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
    CanvasCompatImpl30()
} else {
    CanvasCompatImplBase()
}

internal fun Canvas.quickRejectCompat(r: RectF): Boolean {
    return canvasCompat.quickReject(this, r)
}
