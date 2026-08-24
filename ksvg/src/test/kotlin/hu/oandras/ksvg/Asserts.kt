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

import android.graphics.Bitmap
import androidx.collection.FloatList
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.green
import hu.oandras.ksvg.utils.red
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

fun assertInRange(
    expectedLow: Int,
    expectedHigh: Int,
    actual: Int,
) {
    assertInRange("Expected $actual to be in range $expectedLow .. $expectedHigh", expectedLow, expectedHigh, actual)
}

fun assertInRange(
    message: String,
    expectedLow: Int,
    expectedHigh: Int,
    actual: Int,
) {
    if (actual !in expectedLow..expectedHigh) {
        fail(message)
    }
}

fun assertStrictlyIncreasing(
    message: String,
    first: Int,
    second: Int,
    vararg rest: Int,
) {
    val values = intArrayOf(first, second, *rest)
    for (i in 1 until values.size) {
        if (values[i] <= values[i - 1]) {
            fail("$message (values not strictly increasing: ${values.contentToString()})")
        }
    }
}
}

// ---------------------------------------------------------------------------
// Pixel helpers shared by render-based tests
// ---------------------------------------------------------------------------

private const val CHANNEL_MAX_THRESHOLD = 200
private const val CHANNEL_MIN_THRESHOLD = 60

/** True when the pixel is a saturated primary/named color with full-ish alpha. */
fun isColor(
    bitmap: Bitmap,
    x: Int,
    y: Int,
    red: Int,
    green: Int,
    blue: Int
): Boolean {
    val c = bitmap.getPixel(x, y)
    fun near(v: Int, target: Int) =
        if (target > 128) v >= CHANNEL_MAX_THRESHOLD else v <= CHANNEL_MIN_THRESHOLD
    return near(c.red, red) && near(c.green, green) && near(c.blue, blue) &&
            c.alpha >= CHANNEL_MAX_THRESHOLD
}

fun isRed(bitmap: Bitmap, x: Int, y: Int): Boolean =
    isColor(bitmap, x, y, red = 255, green = 0, blue = 0)

fun isGreen(bitmap: Bitmap, x: Int, y: Int): Boolean =
    isColor(bitmap, x, y, red = 0, green = 255, blue = 0)

fun isBlue(bitmap: Bitmap, x: Int, y: Int): Boolean =
    isColor(bitmap, x, y, red = 0, green = 0, blue = 255)

fun isBlack(bitmap: Bitmap, x: Int, y: Int): Boolean {
    val c = bitmap.getPixel(x, y)
    return c.alpha >= CHANNEL_MAX_THRESHOLD && c.red < 60 && c.green < 60 && c.blue < 60
}

fun isTransparent(bitmap: Bitmap, x: Int, y: Int): Boolean =
    bitmap.getPixel(x, y).alpha == 0