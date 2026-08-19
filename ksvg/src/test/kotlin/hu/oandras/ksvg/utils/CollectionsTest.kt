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

package hu.oandras.ksvg.utils

import androidx.collection.MutableFloatList
import androidx.collection.MutableObjectFloatMap
import androidx.collection.MutableObjectIntMap
import androidx.collection.SimpleArrayMap
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CollectionsTest {

    @Test
    fun testForEachElement() {
        val list = listOf(1, 2, 3)
        val result = mutableListOf<Int>()
        list.forEachElement { result.add(it) }
        assertEquals(list, result)
    }

    @Test
    fun testIndexOfFirstElement() {
        val list = listOf("a", "b", "c")
        assertEquals(1, list.indexOfFirstElement { it == "b" })
        assertEquals(-1, list.indexOfFirstElement { it == "z" })
    }

    @Test
    fun testForEachInstance() {
        val list = listOf(1, "a", 2, "b")
        val strings = mutableListOf<String>()
        list.forEachInstance<String> { strings.add(it) }
        assertEquals(listOf("a", "b"), strings)
    }

    @Test
    fun testCopyIfNotEmptyIntMap() {
        assertNull((null as MutableObjectIntMap<String>?).copyIfNotEmpty())
        
        val emptyMap = MutableObjectIntMap<String>()
        assertNull(emptyMap.copyIfNotEmpty())

        val map = MutableObjectIntMap<String>()
        map.put("key", 1)
        val copy = map.copyIfNotEmpty()
        assertEquals(1, copy!!.size)
        assertEquals(1, copy["key"])
        assertNotSame(map, copy)
    }

    @Test
    fun testCopyIfNotEmptyFloatMap() {
        assertNull((null as MutableObjectFloatMap<String>?).copyIfNotEmpty())

        val emptyMap = MutableObjectFloatMap<String>()
        assertNull(emptyMap.copyIfNotEmpty())

        val map = MutableObjectFloatMap<String>()
        map.put("key", 1.0f)
        val copy = map.copyIfNotEmpty()
        assertEquals(1, copy!!.size)
        assertEquals(1.0f, copy["key"])
        assertNotSame(map, copy)
    }

    @Test
    fun testSimpleArrayMapForEach() {
        val map = SimpleArrayMap<String, Int>()
        map.put("a", 1)
        map.put("b", 2)

        val keys = mutableListOf<String>()
        val values = mutableListOf<Int>()
        map.forEachKeyValue { k, v ->
            keys.add(k)
            values.add(v)
        }
        assertEquals(setOf("a", "b"), keys.toSet())
        assertEquals(setOf(1, 2), values.toSet())

        val keysOnly = mutableListOf<String>()
        map.forEachKey { keysOnly.add(it) }
        assertEquals(setOf("a", "b"), keysOnly.toSet())
    }

    @Test
    fun testFloatListToFloatArray() {
        val list = MutableFloatList()
        list.add(1.0f)
        list.add(2.0f)
        
        val array = list.toFloatArray()
        assertArrayEquals(floatArrayOf(1.0f, 2.0f), array, 0.0f)
    }

    @Test
    fun testMapNotNullElements() {
        val list = listOf(1, 2, 3, 4)
        val result = list.mapNotNullElements { if (it % 2 == 0) it.toString() else null }
        assertEquals(listOf("2", "4"), result)

        assertEquals(emptyList<String>(), emptyList<Int>().mapNotNullElements { it.toString() })
        assertEquals(listOf("1"), listOf(1).mapNotNullElements { it.toString() })
        assertEquals(emptyList<String>(), listOf(1).mapNotNullElements { null })
    }

    @Test
    fun testOptimizeReadOnlyList() {
        val empty = emptyList<Int>()
        assertEquals(empty, empty.optimizeReadOnlyList())

        val single = listOf(1)
        assertEquals(single, single.optimizeReadOnlyList())

        val arrayList = ArrayList<Int>()
        arrayList.add(1)
        arrayList.add(2)
        val optimized = arrayList.optimizeReadOnlyList()
        assertEquals(2, optimized.size)
        assertTrue(optimized is ArrayList)
    }
}
