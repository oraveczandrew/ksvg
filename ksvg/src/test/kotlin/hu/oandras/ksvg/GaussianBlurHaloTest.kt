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
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import hu.oandras.ksvg.utils.alpha
import hu.oandras.ksvg.utils.red
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * F1 (`tmp/VISUAL_FIX_PLAN.md`): the SW blur must keep chroma in the halo.
 *
 * Blurring uniform red over transparency must fade ALPHA while red stays
 * 255 (straight storage, rsvg reference) — i.e. the blur kernel contract is
 * straight-in → straight-out like the native true-Gaussian path (proven by
 * `GaussianBlurNativeParityTest` on translucent inputs) and the corpus
 * reference. Regression test for the double-premultiplied halo
 * (RGB was 255·(a/255)²): `blur.svg` differed 32.6% from rsvg.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class GaussianBlurHaloTest {

    private fun renderBlur(): Bitmap {
        // Same content as test-data/visual/blur.svg.
        val svg = """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
              <defs>
                <filter id="blur" color-interpolation-filters="sRGB">
                  <feGaussianBlur stdDeviation="10"/>
                </filter>
              </defs>
              <rect x="50" y="50" width="156" height="156" fill="red" filter="url(#blur)"/>
            </svg>
        """.trimIndent()
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
        )
    }

    @Test
    fun haloKeepsChroma() {
        val out = renderBlur()
        // (44,128): 6px outside the rect edge — mid-halo, must be
        // translucent with full red chroma.
        val p = out.getPixel(44, 128)
        assertTrue(
            "halo pixel must be translucent (alpha=${p.alpha})",
            p.alpha in 1..254,
        )
        assertEquals(
            "halo chroma must stay red (pixel=${p.toUInt().toString(16)})",
            255,
            p.red,
        )
    }

    @Test
    fun haloAlphaProfile() {
        val out = renderBlur()
        // Alpha must fade outward monotonically-ish and reach ~0 well
        // outside (3 sigma = 30px from the edge at x=50).
        val a44 = out.getPixel(44, 128).alpha
        val a36 = out.getPixel(36, 128).alpha
        val a20 = out.getPixel(20, 128).alpha
        assertTrue("mid-halo alpha sane (a44=$a44)", a44 in 20..200)
        assertTrue("halo fades outward (a36=$a36 < a44=$a44)", a36 < a44)
        assertEquals("far outside is transparent (a20=$a20)", 0, a20)
    }
}
