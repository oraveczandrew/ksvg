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

package hu.oandras.ksvg

import hu.oandras.ksvg.dom.filter.ConvolveMatrixEdgeMode
import hu.oandras.ksvg.dom.filter.FeChannelSelector
import hu.oandras.ksvg.render.filters.channelSelectorValue
import hu.oandras.ksvg.render.filters.sampleCoordinate
import org.junit.Assert.assertEquals
import org.junit.Test

class FilterPixelsTest {

    // --- channelSelectorValue ---

    @Test
    fun testChannelSelectorR() {
        val pixel = 0xFF804020.toInt() // ARGB: A=FF, R=80, G=40, B=20
        assertEquals(0x80 / 255f, channelSelectorValue(pixel, FeChannelSelector.R), 0.001f)
    }

    @Test
    fun testChannelSelectorG() {
        val pixel = 0xFF804020.toInt()
        assertEquals(0x40 / 255f, channelSelectorValue(pixel, FeChannelSelector.G), 0.001f)
    }

    @Test
    fun testChannelSelectorB() {
        val pixel = 0xFF804020.toInt()
        assertEquals(0x20 / 255f, channelSelectorValue(pixel, FeChannelSelector.B), 0.001f)
    }

    @Test
    fun testChannelSelectorA() {
        val pixel = 0xFF804020.toInt()
        assertEquals(0xFF / 255f, channelSelectorValue(pixel, FeChannelSelector.A), 0.001f)
    }

    @Test
    fun testChannelSelectorZeroAlpha() {
        val pixel = 0x00FF0000.toInt()
        assertEquals(0f, channelSelectorValue(pixel, FeChannelSelector.A), 0.001f)
    }

    @Test
    fun testChannelSelectorMaxValues() {
        val pixel = 0xFFFFFFFF.toInt()
        assertEquals(1f, channelSelectorValue(pixel, FeChannelSelector.R), 0.001f)
        assertEquals(1f, channelSelectorValue(pixel, FeChannelSelector.G), 0.001f)
        assertEquals(1f, channelSelectorValue(pixel, FeChannelSelector.B), 0.001f)
        assertEquals(1f, channelSelectorValue(pixel, FeChannelSelector.A), 0.001f)
    }

    @Test
    fun testChannelSelectorMinValues() {
        val pixel = 0x00000000
        assertEquals(0f, channelSelectorValue(pixel, FeChannelSelector.R), 0.001f)
        assertEquals(0f, channelSelectorValue(pixel, FeChannelSelector.G), 0.001f)
        assertEquals(0f, channelSelectorValue(pixel, FeChannelSelector.B), 0.001f)
        assertEquals(0f, channelSelectorValue(pixel, FeChannelSelector.A), 0.001f)
    }

    // --- sampleCoordinate ---

    @Test
    fun testSampleCoordinateInRange() {
        assertEquals(5, sampleCoordinate(5, 10, ConvolveMatrixEdgeMode.none))
        assertEquals(5, sampleCoordinate(5, 10, ConvolveMatrixEdgeMode.wrap))
        assertEquals(5, sampleCoordinate(5, 10, ConvolveMatrixEdgeMode.duplicate))
    }

    @Test
    fun testSampleCoordinateNoneNegative() {
        assertEquals(-1, sampleCoordinate(-1, 10, ConvolveMatrixEdgeMode.none))
    }

    @Test
    fun testSampleCoordinateNoneOverLimit() {
        assertEquals(-1, sampleCoordinate(15, 10, ConvolveMatrixEdgeMode.none))
    }

    @Test
    fun testSampleCoordinateWrapNegative() {
        assertEquals(8, sampleCoordinate(-2, 10, ConvolveMatrixEdgeMode.wrap))
    }

    @Test
    fun testSampleCoordinateWrapOverLimit() {
        assertEquals(2, sampleCoordinate(12, 10, ConvolveMatrixEdgeMode.wrap))
    }

    @Test
    fun testSampleCoordinateWrapExactlyAtLimit() {
        assertEquals(0, sampleCoordinate(10, 10, ConvolveMatrixEdgeMode.wrap))
    }

    @Test
    fun testSampleCoordinateWrapMultiple() {
        assertEquals(0, sampleCoordinate(20, 10, ConvolveMatrixEdgeMode.wrap))
        assertEquals(0, sampleCoordinate(-20, 10, ConvolveMatrixEdgeMode.wrap))
    }

    @Test
    fun testSampleCoordinateDuplicateNegative() {
        assertEquals(0, sampleCoordinate(-5, 10, ConvolveMatrixEdgeMode.duplicate))
    }

    @Test
    fun testSampleCoordinateDuplicateOverLimit() {
        assertEquals(9, sampleCoordinate(15, 10, ConvolveMatrixEdgeMode.duplicate))
    }

    @Test
    fun testSampleCoordinateDuplicateAtBoundary() {
        assertEquals(0, sampleCoordinate(0, 10, ConvolveMatrixEdgeMode.duplicate))
        assertEquals(9, sampleCoordinate(9, 10, ConvolveMatrixEdgeMode.duplicate))
    }
}
