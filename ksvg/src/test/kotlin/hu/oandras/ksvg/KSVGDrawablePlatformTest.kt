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

import android.content.pm.ActivityInfo
import android.content.res.ColorStateList
import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.Outline
import android.view.View
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.blue
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.shadows.ShadowSystemClock
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [34])
class KSVGDrawablePlatformTest {

    private fun render(drawable: KSVGDrawable, size: Int = 100): android.graphics.Bitmap {
        val bitmap = createBitmap(size, size)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(Canvas(bitmap))
        return bitmap
    }

    private fun redSvg(): SVG = SVG.getFromString(
        """<svg width="100" height="100"><rect width="100" height="100" fill="red"/></svg>"""
    )

    @Test
    fun colorFilterTintsAndClears() {
        val d = redSvg().toDrawable()
        val plain = render(d).getPixel(50, 50)
        assertTrue(plain.red > 200)
        val filter = PorterDuffColorFilter(0xFF0000FF.toInt(), PorterDuff.Mode.SRC_IN)
        d.setColorFilter(filter)
        val tinted = render(d).getPixel(50, 50)
        assertSame(filter, d.colorFilter)
        assertTrue(tinted.blue > tinted.red)
        d.colorFilter = null
        val cleared = render(d).getPixel(50, 50)
        assertTrue(cleared.red > 200)
    }

    @Test
    fun tintEntryPointWorks() {
        val d = redSvg().toDrawable()
        d.setTint(0xFF0000FF.toInt())
        val p = render(d).getPixel(50, 50)
        assertTrue(p.blue > p.red)
    }

    @Test
    fun tintFilterIsCachedAcrossDraws() {
        val d = redSvg().toDrawable()
        d.setTint(0xFF0000FF.toInt())
        render(d)
        val first = d.colorFilter
        render(d)
        assertSame(first, d.colorFilter)
    }

    @Test
    fun tintBlendModeEntryPointWorks() {
        val d = redSvg().toDrawable()
        d.setTintList(ColorStateList.valueOf(0xFF0000FF.toInt()))
        d.setTintBlendMode(BlendMode.SRC_IN)
        val p = render(d).getPixel(50, 50)
        assertTrue(p.blue > p.red)
    }

    @Test
    fun alphaPlusFilterCombines() {
        val d = redSvg().toDrawable()
        d.alpha = 128
        d.setColorFilter(PorterDuffColorFilter(0xFFFFFFFF.toInt(), PorterDuff.Mode.SRC_ATOP))
        val bitmap = render(d)
        val p = bitmap.getPixel(50, 50)
        assertTrue(p.alpha in 1..254)
        d.alpha = 255
        d.colorFilter = null
    }

    @Test
    fun constantStateCopyStartsClean() {
        val d = redSvg().toDrawable()
        d.setColorFilter(PorterDuffColorFilter(0xFF0000FF.toInt(), PorterDuff.Mode.SRC_IN))
        d.setTint(0xFF0000FF.toInt())
        val copy = d.constantState!!.newDrawable() as KSVGDrawable
        assertNull(copy.colorFilter)
        val p = render(copy).getPixel(50, 50)
        assertTrue(p.red > 200)
    }

    @Test
    fun changingConfigurationsReportsDensity() {
        val d = redSvg().toDrawable()
        val cfg = d.constantState!!.changingConfigurations
        assertTrue(cfg and ActivityInfo.CONFIG_DENSITY != 0)
    }

    @Test
    fun outlineFollowsBounds() {
        val d = redSvg().toDrawable()
        d.setBounds(0, 0, 100, 100)
        val outline = Outline()
        d.getOutline(outline)
        val outRect = android.graphics.Rect()
        assertTrue(outline.getRect(outRect))
        assertEquals(100, outRect.width())
        val empty = redSvg().toDrawable()
        empty.setBounds(0, 0, 0, 0)
        val outline2 = Outline()
        empty.getOutline(outline2)
        assertTrue(outline2.isEmpty)
    }

    @Test
    fun autoMirrorFlipsInRtl() {
        val svg = SVG.getFromString(
            """<svg width="100" height="100"><a href="left"><rect width="50" height="100" fill="red"/></a><rect x="50" width="50" height="100" fill="blue"/></svg>"""
        )
        val d = svg.toDrawable()
        d.setAutoMirrored(true)
        assertTrue(d.isAutoMirrored)
        d.layoutDirection = View.LAYOUT_DIRECTION_LTR
        val ltrLeft = render(d).getPixel(10, 50)
        assertTrue(ltrLeft.red > ltrLeft.blue)
        assertEquals("left", d.hitTest(10f, 50f))
        d.layoutDirection = View.LAYOUT_DIRECTION_RTL
        val rtlLeft = render(d).getPixel(10, 50)
        assertTrue(rtlLeft.blue > rtlLeft.red)
        // hitTest follows the mirror: the link moved to the right half.
        assertNull(d.hitTest(10f, 50f))
        assertEquals("left", d.hitTest(90f, 50f))
    }

    @Test
    fun paddingStaysEmptyAndOpacityTranslucent() {
        val d = redSvg().toDrawable()
        val rect = android.graphics.Rect()
        assertTrue(!d.getPadding(rect))
        assertEquals(android.graphics.PixelFormat.TRANSLUCENT, d.opacity)
    }

    @Test
    fun setVisibleRestartResetsClock() {
        val svg = SVG.getFromString(
            """<svg width="100" height="100"><rect width="100" height="100" fill="red"><animate attributeName="opacity" from="1" to="0" dur="1s" fill="freeze"/></rect></svg>""",
            parseAnimations = true
        )
        val d = svg.toAnimatedDrawable()
        d.start()
        assertTrue(d.isRunning)
        // Robolectric freezes SystemClock: advance it explicitly instead of sleeping.
        val initialAlpha = render(d).getPixel(50, 50).alpha
        ShadowSystemClock.advanceBy(500, TimeUnit.MILLISECONDS)
        val midAlpha = render(d).getPixel(50, 50).alpha
        assertTrue("mid-animation frame is translucent (a=$midAlpha)", midAlpha < initialAlpha)
        // restart=false continues the clock.
        d.setVisible(false, false)
        d.setVisible(true, false)
        ShadowSystemClock.advanceBy(200, TimeUnit.MILLISECONDS)
        val continuedAlpha = render(d).getPixel(50, 50).alpha
        assertTrue(
            "restart=false continues (mid=$midAlpha, continued=$continuedAlpha)",
            continuedAlpha < midAlpha
        )
        // restart=true jumps back to the initial frame.
        d.setVisible(false, false)
        d.setVisible(true, true)
        assertTrue(d.isRunning)
        val restartedAlpha = render(d).getPixel(50, 50).alpha
        assertTrue(
            "restart=true shows the initial frame again (continued=$continuedAlpha, restarted=$restartedAlpha)",
            restartedAlpha > continuedAlpha
        )
        d.stop()
    }
}
