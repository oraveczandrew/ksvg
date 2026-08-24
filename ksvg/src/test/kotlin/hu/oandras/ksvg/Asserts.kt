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

// ---------------------------------------------------------------------------
// Pixel helpers shared by render-based tests
// ---------------------------------------------------------------------------

private const val CHANNEL_MAX_THRESHOLD = 200
private const val CHANNEL_MIN_THRESHOLD = 60

data class PixelColor(val red: Int, val green: Int, val blue: Int, val alpha: Int)

fun pixelColor(bitmap: android.graphics.Bitmap, x: Int, y: Int): PixelColor {
    val p = bitmap.getPixel(x, y)
    return PixelColor(
        red = (p shr 16) and 0xff,
        green = (p shr 8) and 0xff,
        blue = p and 0xff,
        alpha = (p ushr 24) and 0xff
    )
}

/** True when the pixel is a saturated primary/named color with full-ish alpha. */
fun isColor(
    bitmap: android.graphics.Bitmap,
    x: Int,
    y: Int,
    red: Int,
    green: Int,
    blue: Int
): Boolean {
    val c = pixelColor(bitmap, x, y)
    fun near(v: Int, target: Int) =
        if (target > 128) v >= CHANNEL_MAX_THRESHOLD else v <= CHANNEL_MIN_THRESHOLD
    return near(c.red, red) && near(c.green, green) && near(c.blue, blue) &&
            c.alpha >= CHANNEL_MAX_THRESHOLD
}

fun isRed(bitmap: android.graphics.Bitmap, x: Int, y: Int): Boolean =
    isColor(bitmap, x, y, red = 255, green = 0, blue = 0)

fun isGreen(bitmap: android.graphics.Bitmap, x: Int, y: Int): Boolean =
    isColor(bitmap, x, y, red = 0, green = 255, blue = 0)

fun isBlue(bitmap: android.graphics.Bitmap, x: Int, y: Int): Boolean =
    isColor(bitmap, x, y, red = 0, green = 0, blue = 255)

fun isBlack(bitmap: android.graphics.Bitmap, x: Int, y: Int): Boolean {
    val c = pixelColor(bitmap, x, y)
    return c.alpha >= CHANNEL_MAX_THRESHOLD && c.red < 60 && c.green < 60 && c.blue < 60
}

fun isTransparent(bitmap: android.graphics.Bitmap, x: Int, y: Int): Boolean =
    pixelColor(bitmap, x, y).alpha == 0