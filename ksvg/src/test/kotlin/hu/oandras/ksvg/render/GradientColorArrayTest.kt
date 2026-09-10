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

package hu.oandras.ksvg.render

import android.graphics.Paint
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class GradientColorArrayIntsTest {

    @Test
    fun testSize() {
        val arr = GradientColorArray.Ints(intArrayOf(1, 2, 3))
        assertEquals(3, arr.size)
    }

    @Test
    fun testSetAndGet() {
        val arr = GradientColorArray.Ints(IntArray(3))
        arr[0] = 0xFF0000.toInt()
        arr[1] = 0x00FF00.toInt()
        arr[2] = 0x0000FF.toInt()
        assertEquals(0xFF0000.toInt(), arr.array[0])
        assertEquals(0x00FF00.toInt(), arr.array[1])
        assertEquals(0x0000FF.toInt(), arr.array[2])
    }

    @Test
    fun testSetOnPaint() {
        val arr = GradientColorArray.Ints(intArrayOf(0xAABBCC.toInt()))
        val paint = Paint()
        arr.setOnPaint(paint, 0)
        assertEquals(0xAABBCC.toInt(), paint.color)
    }

    @Test
    fun testContentHashCodeConsistent() {
        val arr = GradientColorArray.Ints(intArrayOf(1, 2, 3))
        val h1 = arr.contentHashCode()
        val h2 = arr.contentHashCode()
        assertEquals(h1, h2)
    }

    @Test
    fun testContentHashCodeDiffersOnDataChange() {
        val arr = GradientColorArray.Ints(intArrayOf(1, 2, 3))
        val h1 = arr.contentHashCode()
        arr[0] = 99
        val h2 = arr.contentHashCode()
        assertNotEquals(h1, h2)
    }

    @Test
    fun testContentHashCodeSameForEqualArrays() {
        val a = GradientColorArray.Ints(intArrayOf(10, 20))
        val b = GradientColorArray.Ints(intArrayOf(10, 20))
        assertEquals(a.contentHashCode(), b.contentHashCode())
    }

    @Test
    fun testSetOverwritesValue() {
        val arr = GradientColorArray.Ints(intArrayOf(0))
        arr[0] = 42
        arr[0] = 100
        assertEquals(100, arr.array[0])
    }
}
