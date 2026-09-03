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

package hu.oandras.ksvg.filtering

import org.junit.Assert.assertArrayEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

@RunWith(Parameterized::class)
class ComponentTransferNativeParityTest(
    private val clipLeft: Int,
    private val clipTop: Int,
    private val table: ByteArray,
) {
    companion object {

        @JvmStatic
        @Parameterized.Parameters
        fun data(): List<Array<Any>> = listOf(
            arrayOf(0, 0, ByteArray(256) { it.toByte() }), // identity
            arrayOf(4, 3, ByteArray(256) { (255 - it).toByte() }), // inverted
            arrayOf(2, 2, ByteArray(256) { ((it * 7) and 0xFF).toByte() }), // stepping table
        )
    }

    @Test
    fun nativeMatchesKotlin() {
        assertNativeBackendAvailable()

        val width = 36
        val height = 30
        val clipRight = if (clipLeft == 0) width else 32
        val clipBottom = if (clipTop == 0) height else 27
        val src = pattern(width, height, 31)
        val ref = IntArray(width * height)
        val native = IntArray(width * height)

        val tableA = table
        val tableR = ByteArray(256) { (table[it].toInt() + 31).toByte() }
        val tableG = ByteArray(256) { (table[it].toInt() * 3).toByte() }
        val tableB = ByteArray(256) { (255 - (table[it].toInt() and 0xFF)).toByte() }

        KotlinKernels.componentTransfer(
            src, ref, width, clipLeft, clipTop, clipRight, clipBottom,
            tableA, tableR, tableG, tableB,
        )
        SoftwareKernels.componentTransfer(
            src, native, width, height, clipLeft, clipTop, clipRight, clipBottom,
            tableA, tableR, tableG, tableB,
        )

        assertArrayEquals("componentTransfer mismatch", ref, native)
    }
}
