/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg

import android.graphics.Bitmap
import android.graphics.Canvas
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.render.pool.BitmapPool
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class KSVGDrawableMemoryTest {

    @Test
    fun bitmapPoolAccountsRetainedBitmaps() {
        val pool = BitmapPool()
        assertEquals(0L, pool.retainedBytes())

        // Checked-out bitmaps are not pooled (not counted).
        val bitmap = pool.acquire(100, 100, Bitmap.Config.ARGB_8888)
        assertEquals(0L, pool.retainedBytes())
        pool.release(bitmap)

        // Released bitmaps stay retained (pooled), so they still count.
        assertEquals(40000L, pool.retainedBytes())

        pool.clear()
        assertEquals(0L, pool.retainedBytes())
    }

    @Test
    fun drawableReportsSceneBitmaps() {
        val svg = SVG.getFromString(
            """
                <svg width="100" height="100">
                  <defs>
                    <filter id="blur">
                      <feGaussianBlur stdDeviation="4"/>
                    </filter>
                  </defs>
                  <rect width="100" height="100" fill="red" filter="url(#blur)"/>
                </svg>
            """.trimIndent()
        )
        val drawable = svg.toDrawable()
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(Canvas(createBitmap(100, 100)))

        // Source + filter-output caches alone (100x100 ARGB_8888 each).
        assertTrue(
            "expected at least cached bitmaps, got ${drawable.getMemorySizeBytes()}",
            drawable.getMemorySizeBytes() >= 2L * 100 * 100 * 4
        )
    }

    @Test
    fun trimMemoryDoesNotGrowAccounting() {
        val svg = SVG.getFromString(
            """<svg width="100" height="100"><rect width="100" height="100" fill="red"/></svg>"""
        )
        val drawable = svg.toDrawable()
        drawable.setBounds(0, 0, 100, 100)
        drawable.draw(Canvas(createBitmap(100, 100)))

        val before = drawable.getMemorySizeBytes()
        drawable.trimMemory()
        assertTrue(drawable.getMemorySizeBytes() <= before)
    }
}
