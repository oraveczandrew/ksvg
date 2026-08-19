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

@file:OptIn(ExperimentalContracts::class)

package hu.oandras.ksvg

import androidx.collection.FloatList
import org.junit.Assert
import org.junit.Assert.assertEquals
import org.junit.Assert.fail
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.contract

fun assertNotNull(o: Any?) {
    contract {
        returns() implies (o != null)
    }
    Assert.assertNotNull(o)
}

inline fun <reified T: Any> assertIs(actual: Any?) {
    contract {
        returns() implies (actual is T)
    }

    if (actual !is T) {
        fail("Expected instance of ${T::class.java.name} but was ${actual?.javaClass?.name}")
    }
}

internal fun assertFloatListEquals(
    expected: FloatArray,
    actual: FloatList,
    delta: Float = 0.001f
) {
    assertEquals("FloatList size mismatch", expected.size, actual.size)
    for (i in expected.indices) {
        assertEquals("Mismatch at index $i", expected[i], actual[i], delta)
    }
}

internal fun assertArrayEquals(
    expected: FloatArray,
    actual: FloatArray,
    delta: Float = 0.001f
) {
    assertEquals("FloatArray size mismatch", expected.size, actual.size)
    for (i in expected.indices) {
        assertEquals("Mismatch at index $i", expected[i], actual[i], delta)
    }
}