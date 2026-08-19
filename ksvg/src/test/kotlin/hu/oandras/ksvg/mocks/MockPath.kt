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

package hu.oandras.ksvg.mocks

import android.graphics.Matrix
import android.graphics.Path
import android.graphics.RectF
import hu.oandras.ksvg.utils.forEachElement
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowLegacyPath
import java.math.BigDecimal
import java.math.RoundingMode
import java.util.*

/**
 * Created by Paul on 10/07/2017.
 */
@Suppress("TestFunctionName", "unused")
@Implements(Path::class)
class MockPath: ShadowLegacyPath() {
    @JvmField
    internal var path: ArrayList<String> = ArrayList()
    @JvmField
    internal var transforms: ArrayList<Matrix>? = null
    @JvmField
    internal var fillType: Path.FillType = Path.FillType.WINDING

    private var silent = false
    private var transforming = false

    @Implementation
    fun __constructor__() {
        path.clear()
        transforms = null
        fillType = Path.FillType.WINDING
    }

    @Implementation
    public override fun __constructor__(src: Path) {
        super.__constructor__(src)
        val shadow = src.asShadow()
        this.path = ArrayList(shadow.path)
        this.transforms = shadow.transforms?.let { ArrayList(it) }
        this.fillType = shadow.fillType
    }

    @Implementation
    public override fun reset() {
        super.reset()
        path.clear()
        transforms = null
    }

    @Implementation
    public override fun isEmpty(): Boolean {
        return super.isEmpty() && path.isEmpty()
    }

    @Implementation
    public override fun setFillType(ft: Path.FillType) {
        super.setFillType(ft)
        this.fillType = ft
    }

    @Implementation
    public override fun getFillType(): Path.FillType {
        return super.getFillType()
    }

    @Implementation
    public override fun moveTo(x: Float, y: Float) {
        super.moveTo(x, y)
        if (!silent) {
            path.add(String.format(Locale.US, "M %s %s", num(x), num(y)))
        }
    }

    @Implementation
    public override fun lineTo(x: Float, y: Float) {
        super.lineTo(x, y)
        if (!silent) {
            path.add(String.format(Locale.US, "L %s %s", num(x), num(y)))
        }
    }

    @Implementation
    public override fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) {
        super.quadTo(x1, y1, x2, y2)
        if (!silent) {
            path.add(String.format(Locale.US, "Q %s %s %s %s", num(x1), num(y1), num(x2), num(y2)))
        }
    }

    @Implementation
    public override fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
        super.cubicTo(x1, y1, x2, y2, x3, y3)
        if (!silent) {
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
    }

    @Implementation
    public override fun close() {
        super.close()
        if (!silent) {
            path.add("Z")
        }
    }

    @Implementation
    public override fun set(src: Path) {
        val wasSilent = silent
        silent = true
        try {
            super.set(src)
        } finally {
            silent = wasSilent
        }
        val shadow = src.asShadow()
        this.path = ArrayList(shadow.path)
        this.transforms = shadow.transforms?.let { ArrayList(it) }
        this.fillType = shadow.fillType
    }

    @Implementation
    fun addRect(left: Float, top: Float, right: Float, bottom: Float) {
        addRect(left, top, right, bottom, Path.Direction.CW)
    }

    @Implementation
    public override fun addRect(left: Float, top: Float, right: Float, bottom: Float, dir: Path.Direction) {
        val wasSilent = silent
        silent = true
        try {
            super.addRect(left, top, right, bottom, dir)
        } finally {
            silent = wasSilent
        }
        path.add(String.format(Locale.US, "M %s %s", num(left), num(top)))
        path.add(String.format(Locale.US, "L %s %s", num(right), num(top)))
        path.add(String.format(Locale.US, "L %s %s", num(right), num(bottom)))
        path.add(String.format(Locale.US, "L %s %s", num(left), num(bottom)))
        path.add(String.format(Locale.US, "L %s %s", num(left), num(top)))
        path.add("Z")
    }

    @Implementation
    public override fun addRect(rect: RectF, dir: Path.Direction) {
        addRect(rect.left, rect.top, rect.right, rect.bottom, dir)
    }

    @Implementation
    fun addOval(left: Float, top: Float, right: Float, bottom: Float) {
        addOval(left, top, right, bottom, Path.Direction.CW)
    }

    @Implementation
    public override fun addOval(left: Float, top: Float, right: Float, bottom: Float, dir: Path.Direction) {
        val wasSilent = silent
        silent = true
        try {
            super.addOval(left, top, right, bottom, dir)
        } finally {
            silent = wasSilent
        }
        path.add(
            String.format(Locale.US, "O %s %s %s %s", num(left), num(top), num(right), num(bottom))
        )
    }

    @Implementation
    public override fun addCircle(x: Float, y: Float, radius: Float, dir: Path.Direction) {
        val wasSilent = silent
        silent = true
        try {
            super.addCircle(x, y, radius, dir)
        } finally {
            silent = wasSilent
        }
        path.add(String.format(Locale.US, "CIR %s %s %s", num(x), num(y), num(radius)))
    }

    @Implementation
    public override fun addRoundRect(
        left: Float,
        top: Float,
        right: Float,
        bottom: Float,
        rx: Float,
        ry: Float,
        dir: Path.Direction
    ) {
        val wasSilent = silent
        silent = true
        try {
            super.addRoundRect(left, top, right, bottom, rx, ry, dir)
        } finally {
            silent = wasSilent
        }
        path.add(
            String.format(
                Locale.US,
                "RR %s %s %s %s %s %s",
                num(left),
                num(top),
                num(right),
                num(bottom),
                num(rx),
                num(ry)
            )
        )
    }

    @Implementation
    public override fun addRoundRect(rect: RectF, rx: Float, ry: Float, dir: Path.Direction) {
        addRoundRect(rect.left, rect.top, rect.right, rect.bottom, rx, ry, dir)
    }

    @Implementation
    public override fun addPath(src: Path) {
        val wasSilent = silent
        silent = true
        try {
            super.addPath(src)
        } finally {
            silent = wasSilent
        }
        path.addAll(src.asShadow().path)
    }

    @Implementation
    public override fun addPath(src: Path, matrix: Matrix) {
        val wasSilent = silent
        silent = true
        try {
            super.addPath(src, matrix)
        } finally {
            silent = wasSilent
        }
        // For simplicity, we just add the path description and apply a transform to it later if needed.
        // But for mock purposes, we can just say we added the path.
        path.add("addPath(" + src.asShadow().pathDescription + ", " + matrix + ")")
    }

    @Implementation
    public override fun computeBounds(bounds: RectF, exact: Boolean) {
        super.computeBounds(bounds, exact)
        // Mock implementation used to set dummy bounds, but now we let super do its job.
    }

    @Suppress("SameReturnValue")
    @Implementation
    fun op(otherPath: Path, op: Path.Op): Boolean {
        // ShadowLegacyPath in 4.16.1 should have op, but let's be safe.
        // We manually update the string representation as before.
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
    public override fun transform(matrix: Matrix) {
        if (transforming) {
            super.transform(matrix)
            return
        }
        transforming = true
        try {
            super.transform(matrix)
        } finally {
            transforming = false
        }
        
        if (matrix.isIdentity) return
        val transforms = transforms ?: ArrayList<Matrix>().also {
            transforms = it
        }
        transforms.add(Matrix(matrix))
    }

    @Implementation
    public override fun transform(matrix: Matrix, dst: Path?) {
        if (transforming) {
            super.transform(matrix, dst)
            return
        }
        transforming = true
        try {
            super.transform(matrix, dst)
        } finally {
            transforming = false
        }
        
        val targetShadow = if (dst == null) this else dst.asShadow()
        targetShadow.path = ArrayList(this.path)
        targetShadow.transforms = this.transforms?.let { ArrayList(it) }
        
        if (matrix.isIdentity) return
        val transforms = targetShadow.transforms ?: ArrayList<Matrix>().also {
            targetShadow.transforms = it
        }
        transforms.add(Matrix(matrix))
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
