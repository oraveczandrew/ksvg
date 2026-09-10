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

import hu.oandras.ksvg.filtering.LcgRandom
import org.junit.Assert.assertTrue
import org.junit.Test

class LcgRandomTest {

    @Test
    fun testNextReturnsPositiveValue() {
        val rng = LcgRandom(42)
        repeat(100) {
            val value = rng.next()
            assertTrue("Expected positive value but got $value", value > 0)
        }
    }

    @Test
    fun testNextWithinRange() {
        val rng = LcgRandom(42)
        repeat(100) {
            val value = rng.next()
            assertTrue("Value $value out of range", value in 1..<Int.MAX_VALUE)
        }
    }

    @Test
    fun testSeedClampedToMin() {
        val rng = LcgRandom(0)
        val value = rng.next()
        assertTrue(value > 0)
    }

    @Test
    fun testSeedClampedToMaxMinusOne() {
        val rng = LcgRandom(Int.MAX_VALUE)
        val value = rng.next()
        assertTrue(value > 0)
    }

    @Test
    fun testNegativeSeedClamped() {
        val rng = LcgRandom(-100)
        val value = rng.next()
        assertTrue(value > 0)
    }

    @Test
    fun testDeterministic() {
        val rng1 = LcgRandom(42)
        val rng2 = LcgRandom(42)
        repeat(50) {
            assertTrue(rng1.next() == rng2.next())
        }
    }

    @Test
    fun testDifferentSeedsProduceDifferentSequences() {
        val rng1 = LcgRandom(1)
        val rng2 = LcgRandom(2)
        val values1 = (0..9).map { rng1.next() }
        val values2 = (0..9).map { rng2.next() }
        assertTrue(values1 != values2)
    }
}
