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
package hu.oandras.ksvg

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.Rect
import android.graphics.RectF
import androidx.collection.ArrayMap
import hu.oandras.ksvg.utils.compilePattern
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import java.util.Locale
import java.util.Stack
import java.util.regex.Matcher

/**
 * Mock version of Android Canvas class for testing.
 */
@Suppress("TestFunctionName", "unused")
@Implements(Canvas::class)
class MockCanvas {
    private lateinit var bitmap: Bitmap
    private val clipRect: Rect = Rect()
    private var clipPath: Path = Path()
    private var matrix: Matrix = Matrix()

    private val clipPathStack: Stack<Path> = Stack()
    private val matrixStack: Stack<Matrix> = Stack()

    private val operations: ArrayList<String> = ArrayList()

    @Implementation
    fun __constructor__(bitmap: Bitmap?) {
        this.bitmap = bitmap!!
        //this.operations.add(String.format(Locale.US, "new Canvas(%s)", bitmap));
    }

    fun getOperations(): MutableList<String> {
        return operations
    }

    fun clearOperations() {
        operations.clear()
    }


    @Implementation
    fun clipRect(left: Float, top: Float, right: Float, bottom: Float): Boolean {
        this.clipRect.set(left.toInt(), top.toInt(), right.toInt(), bottom.toInt())
        this.operations.add(
            String.format(
                Locale.US,
                "clipRect(%s, %s, %s, %s)",
                num(left),
                num(top),
                num(right),
                num(bottom)
            )
        )
        return right > left && bottom > top
    }

    @Implementation
    fun clipRect(rect: RectF): Boolean {
        return clipRect(rect.left, rect.top, rect.right, rect.bottom)
    }

    @Implementation
    fun clipRect(rect: Rect): Boolean {
        return clipRect(rect.left.toFloat(), rect.top.toFloat(), rect.right.toFloat(), rect.bottom.toFloat())
    }

    @Implementation
    fun concat(matrix: Matrix) {
        this.matrix.postConcat(matrix)
        val m = FloatArray(9)
        matrix.getValues(m)
        this.operations.add(
            String.format(
                Locale.US,
                "concat(Matrix(%s %s %s %s %s %s))",
                num(m[0]),
                num(m[3]),
                num(m[1]),
                num(m[4]),
                num(m[2]),
                num(m[5])
            )
        )
    }

    @Implementation
    fun clipPath(path: Path): Boolean {
        //this.clipPath.op(path, Path.Op.INTERSECT);
        this.clipPath = path // Good enough for our testing purposes
        this.operations.add(
            String.format(
                Locale.US,
                "clipPath(%s)",
                path.asShadow().pathDescription
            )
        )
        return this.clipPath.isEmpty
    }

    @Implementation
    fun drawBitmap(bm: Bitmap?, left: Float, top: Float, paint: Paint?) {
        this.operations.add(
            String.format(
                Locale.US,
                "drawBitmap(%s, %s, %s, %s)",
                bm,
                num(left),
                num(top),
                paint.paintToStr()
            )
        )
    }

    @Implementation
    fun drawColor(color: Int) {
        operations.add(String.format(Locale.US, "drawColor(#%08x)", color))
    }

    @Implementation
    fun drawColor(color: Int, mode: PorterDuff.Mode) {
        operations.add(String.format(Locale.US, "drawColor(#%08x, %s)", color, mode))
    }

    @Implementation
    fun drawPath(path: Path, paint: Paint?) {
        operations.add(
            String.format(
                Locale.US,
                "drawPath('%s', %s)",
                path.asShadow().pathDescription,
                paint.paintToStr()
            )
        )
    }

    @Implementation
    fun drawText(text: String?, x: Float, y: Float, paint: Paint?) {
        operations.add(
            String.format(
                Locale.US,
                "drawText('%s', %s, %s, %s)",
                text,
                num(x),
                num(y),
                paint.paintToStr()
            )
        )
    }

    @Implementation
    fun drawTextOnPath(text: String?, path: Path, hOffset: Float, vOffset: Float, paint: Paint?) {
        operations.add(
            String.format(
                Locale.US,
                "drawTextOnPath('%s', '%s', %s, %s, %s)",
                text,
                path.asShadow().pathDescription,
                num(hOffset),
                num(vOffset),
                paint.paintToStr()
            )
        )
    }

    @get:Implementation
    val height: Int
        get() =//this.operations.add("getHeight()");
            this.bitmap.getHeight()

    @Implementation
    fun getMatrix(): Matrix {
        //this.operations.add("getMatrix()");
        return Matrix(this.matrix)
    }

    @Implementation
    fun getMatrix(matrix: Matrix) {
        matrix.set(this.matrix)
    }

    @get:Implementation
    val width: Int
        get() =//this.operations.add("getWidth()");
            this.bitmap.getWidth()

    @get:Implementation
    val saveCount: Int
        get() = matrixStack.size + 1

    @Implementation
    fun restore() {
        internalRestore()
        operations.add("restore()")
    }

    private fun internalRestore() {
        check(!matrixStack.isEmpty()) { "Stack underflow" }
        val m: Matrix? = this.matrixStack.pop()
        val cp: Path? = this.clipPathStack.pop()
        if (m != null) this.matrix = m
        if (cp != null) this.clipPath = cp
    }

    @Implementation
    fun restoreToCount(saveCount: Int) {
        operations.add(String.format(Locale.US, "restoreToCount(%d)", saveCount))
        if (saveCount < 1 || saveCount >= this.saveCount) return
        while (this.saveCount > saveCount) {
            internalRestore()
        }
    }

    @Implementation
    fun save(): Int {
        val n = saveCount
        operations.add("save()")
        internalSave(ALL_SAVE_FLAG)
        return n
    }

    @Implementation
    fun save(saveFlags: Int): Int {
        val n = saveCount
        this.operations.add(String.format(Locale.US, "save(%x)", saveFlags))
        internalSave(saveFlags)
        return n
    }

    private fun internalSave(saveFlags: Int) {
        this.matrixStack.push(
            if (saveFlags and MATRIX_SAVE_FLAG != 0) Matrix(
                this.matrix
            ) else null
        )
        this.clipPathStack.push(
            if (saveFlags and CLIP_SAVE_FLAG != 0) Path(
                this.clipPath
            ) else null
        )
    }

    @Implementation
    fun saveLayer(bounds: RectF?, paint: Paint?): Int {
        val n = saveCount
        this.operations.add(
            String.format(
                Locale.US,
                "saveLayer(%s, %s)",
                bounds,
                paint.paintToStr()
            )
        )
        internalSave(ALL_SAVE_FLAG)
        return n
    }

    @Implementation
    fun saveLayer(bounds: RectF?, paint: Paint?, saveFlags: Int): Int {
        val n = saveCount
        this.operations.add(
            String.format(
                Locale.US,
                "saveLayer(%s, %s, %x)",
                bounds,
                paint.paintToStr(),
                saveFlags
            )
        )
        internalSave(saveFlags)
        return n
    }

    @Implementation
    fun saveLayerAlpha(bounds: RectF?, alpha: Int): Int {
        val n = saveCount
        this.operations.add(
            String.format(
                Locale.US,
                "saveLayerAlpha(%s, %d)",
                bounds,
                alpha
            )
        )
        internalSave(ALL_SAVE_FLAG)
        return n
    }

    @Implementation
    fun saveLayerAlpha(bounds: RectF?, alpha: Int, saveFlags: Int): Int {
        val n = saveCount
        this.operations.add(
            String.format(
                Locale.US,
                "saveLayerAlpha(%s, %d, %x)",
                bounds,
                alpha,
                saveFlags
            )
        )
        internalSave(saveFlags)
        return n
    }

    @Implementation
    fun scale(sx: Float, sy: Float) {
        this.matrix.postScale(sx, sy)
        this.operations.add(
            String.format(
                Locale.US,
                "scale(%s, %s)",
                num(sx),
                num(sy)
            )
        )
    }

    @Implementation
    fun setMatrix(matrix: Matrix?) {
        this.matrix = Matrix()
        if (matrix != null) {
            this.matrix.set(matrix)
        }
        val m = FloatArray(9)
        this.matrix.getValues(m)
        this.operations.add(
            String.format(
                Locale.US,
                "setMatrix(Matrix(%s %s %s %s %s %s))",
                num(m[0]),
                num(m[3]),
                num(m[1]),
                num(m[4]),
                num(m[2]),
                num(m[5])
            )
        )
    }

    @Implementation
    fun translate(dx: Float, dy: Float) {
        this.matrix.postTranslate(dx, dy)
        this.operations.add(
            String.format(
                Locale.US,
                "translate(%s, %s)",
                num(dx),
                num(dy)
            )
        )
    }


    /*
    * Look for "Paint()" value in ops entry with index opIndex.
    * Return the value of the paint property with name propName.
    */
    fun paintProp(opsIndex: Int, propName: String): String {
        val op: String = operations[opsIndex]
        val m: Matcher = matcherForProp(propName).reset(op)
        return if (m.find()) m.group(1) else "NO $propName"
    }

    companion object {
        /**
         * Save flags
         */
        const val MATRIX_SAVE_FLAG: Int = 0x01
        const val CLIP_SAVE_FLAG: Int = 0x02
        const val HAS_ALPHA_LAYER_SAVE_FLAG: Int = 0x04
        const val FULL_COLOR_LAYER_SAVE_FLAG: Int = 0x08
        const val CLIP_TO_LAYER_SAVE_FLAG: Int = 0x10
        const val ALL_SAVE_FLAG: Int = 0x1F

        private val matcherCache: MutableMap<String, Matcher> = ArrayMap()

        private fun matcherForProp(propName: String): Matcher {
            return  matcherCache.getOrPut(propName) {
                compilePattern("[(\\s]$propName:([^;)]*)").matcher("")
            }
        }

        fun num(f: Float): String {
            val fL = f.toLong()
            return if (f == fL.toFloat()) {
                String.format("%d", fL)
            } else {
                String.format("%s", f)
            }
        }
    }
}

private fun Paint?.paintToStr(): String {
    return this?.asShadow()?.description ?: "null"
}

