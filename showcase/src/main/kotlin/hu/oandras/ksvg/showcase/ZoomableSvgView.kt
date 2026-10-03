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

package hu.oandras.ksvg.showcase

import android.content.Context
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import kotlin.math.max
import kotlin.math.min

// Pinch-to-zoom + pan + double-tap view for large vector drawables (e.g. KSVG PictureDrawable).
// Vector content stays sharp at any zoom because it is re-drawn through the matrix.
class ZoomableSvgView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : View(context, attrs, defStyleAttr) {

    private var drawable: Drawable? = null
    private val drawMatrix = Matrix()
    private val matrixValues = FloatArray(9)
    private var fitted = false

    var minScale: Float = 1f
    var maxScale: Float = 12f

    private val scaleDetector = ScaleGestureDetector(
        context,
        object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                val current = currentScale()
                val target = (current * detector.scaleFactor).coerceIn(minScale, maxScale)
                val factor = target / current
                drawMatrix.postScale(factor, factor, detector.focusX, detector.focusY)
                fixBounds()
                invalidate()
                return true
            }
        },
    )

    private val gestureDetector = GestureDetector(
        context,
        object : GestureDetector.SimpleOnGestureListener() {
            override fun onScroll(
                e1: MotionEvent?,
                e2: MotionEvent,
                distanceX: Float,
                distanceY: Float,
            ): Boolean {
                drawMatrix.postTranslate(-distanceX, -distanceY)
                fixBounds()
                invalidate()
                return true
            }

            override fun onDoubleTap(e: MotionEvent): Boolean {
                val current = currentScale()
                val target = if (current < (minScale + maxScale) / 2f) current * 2.5f else minScale
                zoomTo(target.coerceIn(minScale, maxScale), e.x, e.y)
                return true
            }
        },
    )

    fun setSvgDrawable(d: Drawable?) {
        drawable = d
        fitted = false
        drawMatrix.reset()
        requestLayout()
        invalidate()
    }

    fun resetZoom() {
        fitted = false
        requestLayout()
        invalidate()
    }

    private fun currentScale(): Float {
        drawMatrix.getValues(matrixValues)
        return matrixValues[Matrix.MSCALE_X].coerceAtLeast(0.0001f)
    }

    private fun zoomTo(target: Float, focusX: Float, focusY: Float) {
        val factor = target / currentScale()
        drawMatrix.postScale(factor, factor, focusX, focusY)
        fixBounds()
        invalidate()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        if (!fitted) fitCenter()
    }

    private fun fitCenter() {
        val d = drawable ?: return
        val dw = d.intrinsicWidth
        val dh = d.intrinsicHeight
        if (dw <= 0 || dh <= 0 || width <= 0 || height <= 0) return
        drawMatrix.reset()
        val scale = min(width / dw.toFloat(), height / dh.toFloat())
        val dx = (width - dw * scale) / 2f
        val dy = (height - dh * scale) / 2f
        drawMatrix.postScale(scale, scale)
        drawMatrix.postTranslate(dx, dy)
        minScale = scale
        fitted = true
        invalidate()
    }

    // Keep content covering the viewport when zoomed in, centered when smaller.
    private fun fixBounds() {
        val d = drawable ?: return
        val dw = d.intrinsicWidth * currentScale()
        val dh = d.intrinsicHeight * currentScale()
        if (dw <= 0f || dh <= 0f) return
        drawMatrix.getValues(matrixValues)
        var tx = matrixValues[Matrix.MTRANS_X]
        var ty = matrixValues[Matrix.MTRANS_Y]
        tx = if (dw <= width) (width - dw) / 2f else tx.coerceIn(width - dw, 0f)
        ty = if (dh <= height) (height - dh) / 2f else ty.coerceIn(height - dh, 0f)
        matrixValues[Matrix.MTRANS_X] = tx
        matrixValues[Matrix.MTRANS_Y] = ty
        drawMatrix.setValues(matrixValues)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        var handled = scaleDetector.onTouchEvent(event)
        handled = gestureDetector.onTouchEvent(event) || handled
        return handled || super.onTouchEvent(event)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val d = drawable ?: return
        if (!fitted) fitCenter()
        val save = canvas.save()
        canvas.concat(drawMatrix)
        d.setBounds(0, 0, max(d.intrinsicWidth, 1), max(d.intrinsicHeight, 1))
        d.draw(canvas)
        canvas.restoreToCount(save)
    }
}
