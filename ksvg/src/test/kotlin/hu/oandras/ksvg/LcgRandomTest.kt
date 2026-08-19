package hu.oandras.ksvg

import hu.oandras.ksvg.utils.LcgRandom
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
