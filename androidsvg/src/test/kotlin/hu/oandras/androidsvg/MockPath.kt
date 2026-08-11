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

package hu.oandras.androidsvg

import android.graphics.Matrix
import android.graphics.Path
import android.graphics.RectF
import hu.oandras.androidsvg.utils.forEachElement
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import java.math.BigDecimal
import java.math.RoundingMode
import java.util.Locale

/**
 * Created by Paul on 10/07/2017.
 */
@Suppress("TestFunctionName", "unused")
@Implements(Path::class)
class MockPath {
    private var path: ArrayList<String> = ArrayList()
    private var transforms: ArrayList<Matrix>? = null
    private var fillType: Path.FillType = Path.FillType.WINDING


    @Implementation
    fun __constructor__() {
        path.clear()
        transforms = null
        fillType = Path.FillType.WINDING
    }

    @Implementation
    fun __constructor__(src: Path) {
        val shadow = src.asShadow()
        this.path = ArrayList(shadow.path)
        this.transforms = shadow.transforms?.let { ArrayList(it) }
        this.fillType = shadow.fillType
    }

    @Implementation
    fun reset() {
        path.clear()
        transforms = null
    }

    @Implementation
    fun isEmpty(): Boolean {
        return path.isEmpty()
    }

    @Implementation
    fun setFillType(ft: Path.FillType) {
        this.fillType = ft
    }

    @Implementation
    fun getFillType(): Path.FillType {
        return this.fillType
    }

    @Implementation
    fun moveTo(x: Float, y: Float) {
        path.add(String.format(Locale.US, "M %s %s", num(x), num(y)))
    }

    @Implementation
    fun lineTo(x: Float, y: Float) {
        path.add(String.format(Locale.US, "L %s %s", num(x), num(y)))
    }

    @Implementation
    fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
        path.add(String.format(Locale.US, "Q %s %s %s %s", num(x1), num(y1), num(x2), num(y2)))
    }

    @Implementation
    fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
        path.add(
            String.format(
                Locale.US,
                "C %s %s %s %s %s %s",
                num(x1),
                num(y1),
                num(x2),
                num(y2),
                num(x3),
                num(y3)
            )
        )
    }

    @Implementation
    fun close() {
        path.add("Z")
    }

    @Implementation
    fun addPath(src: Path) {
        path.addAll(src.asShadow().path)
    }

    @Implementation
    fun addPath(src: Path, matrix: Matrix) {
        // For simplicity, we just add the path description and apply a transform to it later if needed.
        // But for mock purposes, we can just say we added the path.
        path.add("addPath(" + src.asShadow().pathDescription + ", " + matrix + ")")
    }

    @Implementation
    fun computeBounds(bounds: RectF, exact: Boolean) {
        // Mock implementation: we can't easily compute bounds from string path.
        // Set some dummy bounds or try to keep them empty.
        bounds.set(0f, 0f, 0f, 0f)
    }

    @Suppress("SameReturnValue")
    @Implementation
    fun op(otherPath: Path, op: Path.Op): Boolean {
        val mockOtherPath = otherPath.asShadow()
        if (path.isEmpty()) {
            path = ArrayList(mockOtherPath.path)
            return true
        }

        val path = path
        // Update the path to represent the Op() operation
        path.add(0, "(")
        when (op) {
            Path.Op.UNION -> path.add("\u222a")
            Path.Op.INTERSECT -> path.add("\u2229")
            Path.Op.DIFFERENCE -> path.add("\u2212")
            Path.Op.REVERSE_DIFFERENCE -> path.add("rev\u2212")
            Path.Op.XOR -> path.add("\u2295")
        }
        path.addAll(mockOtherPath.path)
        path.add(")")
        return true
    }

    @Implementation
    fun transform(matrix: Matrix) {
        if (matrix.isIdentity) return
        val transforms = transforms ?: ArrayList<Matrix>().also {
            transforms = it
        }
        transforms.add(Matrix(matrix))
    }

    @Implementation
    fun transform(matrix: Matrix, dst: Path?) {
        val shadow = this
        val newPath = dst ?: Path()
        val newShadow = newPath.asShadow()
        newShadow.path = ArrayList(shadow.path)
        newShadow.transforms = shadow.transforms?.let { ArrayList(it) }
        newShadow.transform(matrix)
    }


    val pathDescription: String
        get() {
            val sb: StringBuilder = StringBuilder()
            path.joinTo(sb, " ")
            val transforms = transforms
            if (!transforms.isNullOrEmpty()) {
                transforms.forEachElement { matrix ->
                    if (matrix.isIdentity) {
                        return@forEachElement
                    }
                    sb.append(" \u00d7 [")
                    formatMatrix(sb, matrix)
                    sb.append(']')
                }
            }
            return sb.toString()
        }

    private fun formatMatrix(sb: StringBuilder, matrix: Matrix) {
        val values = FloatArray(9)
        matrix.getValues(values)
        sb.append(num(values[0]))
        sb.append(", ")
        sb.append(num(values[3]))
        sb.append(", ")
        sb.append(num(values[1]))
        sb.append(", ")
        sb.append(num(values[4]))
        sb.append(", ")
        sb.append(num(values[2]))
        sb.append(", ")
        sb.append(num(values[5]))
    }

    companion object {
        private fun num(f: Float): String {
            return if (f == f.toLong().toFloat()) {
                String.format("%d", f.toLong())
            } else {
                String.format("%s", round(f, 5))
            }
        }

        @Suppress("SameParameterValue")
        private fun round(value: Float, places: Int): Float {
            val bd = BigDecimal(value.toString())
                .setScale(places, RoundingMode.HALF_UP)
            return bd.toFloat()
        }
    }
}
