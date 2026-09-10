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

import hu.oandras.ksvg.render.pool.Pool
import hu.oandras.ksvg.render.pool.withPooledObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertSame
import org.junit.Test

class PoolTest {

    private class IntPool : Pool<Int>() {
        var createCount = 0
            private set

        override fun createInstance(): Int {
            createCount++
            return createCount
        }

        override fun resetInstance(item: Int) {
            // no-op for tests
        }
    }

    @Test
    fun testPullCreatesInstance() {
        val pool = IntPool()
        val item = pool.pull()
        assertEquals(1, item)
        assertEquals(1, pool.createCount)
    }

    @Test
    fun testPullReusesReleasedInstance() {
        val pool = IntPool()
        val item1 = pool.pull()
        pool.release(item1)
        val item2 = pool.pull()
        assertSame(item1, item2)
    }

    @Test
    fun testPullCreatesNewWhenEmpty() {
        val pool = IntPool()
        val item1 = pool.pull()
        val item2 = pool.pull()
        assertEquals(1, item1)
        assertEquals(2, item2)
    }

    @Test
    fun testReleasePreventsDuplicate() {
        val pool = IntPool()
        val item = pool.pull()
        pool.release(item)
        pool.release(item) // Should not add duplicate
        val item2 = pool.pull()
        assertSame(item, item2)
        // Pulling again should create a new one since only one was in pool
        val item3 = pool.pull()
        assertEquals(2, item3)
    }

    @Test
    fun testReleaseAll() {
        val pool = IntPool()
        val items = mutableListOf(pool.pull(), pool.pull(), pool.pull())
        pool.releaseAll(items)
        assertEquals(0, items.size)
        // Now pulling should return released items
        val item1 = pool.pull()
        val item2 = pool.pull()
        val item3 = pool.pull()
        assertNotNull(item1)
        assertNotNull(item2)
        assertNotNull(item3)
    }

    @Test
    fun testWithPooledObject() {
        val pool = IntPool()
        val result = pool.withPooledObject { it * 10 }
        assertEquals(10, result)
        // Item should be released back to pool
        val reused = pool.pull()
        assertEquals(1, reused)
    }

    @Test
    fun testWithPooledObjectReleasesOnException() {
        val pool = IntPool()
        try {
            pool.withPooledObject<Int, Unit> { throw IllegalStateException("test") }
        } catch (_: IllegalStateException) {
            // expected
        }
        // Item should still be released back
        val reused = pool.pull()
        assertEquals(1, reused)
    }
}
