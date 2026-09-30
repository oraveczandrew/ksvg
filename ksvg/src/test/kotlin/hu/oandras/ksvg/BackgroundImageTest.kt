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
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

/**
 * `BackgroundImage`/`BackgroundAlpha` filter inputs on the software backend.
 *
 * Documented deviation (see SUPPORT `<filter>` row): both resolve to
 * transparent on every path. A true backdrop snapshot would need readable
 * surfaces, which neither the software `Canvas` (no readback, opaque layers)
 * nor hardware canvases provide — the same reason Firefox never implemented
 * them (bug 437554) and Chrome fakes `BackgroundImage`. rsvg does snapshot,
 * so no rsvg reference images here by design; these pin the defined transparent
 * behavior instead. Primitives still run (defined output) instead of being
 * skipped; the GPU chain declines (device suite).
 *
 * Renders with the software backend (`softwareFiltering = true`) for
 * deterministic output (see AGENTS.md).
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class BackgroundImageTest {

    private fun render(svg: String): Bitmap {
        return renderWithLibrary(
            svg,
            createBitmap(256, 256, Bitmap.Config.ARGB_8888),
            softwareFiltering = true,
        )
    }

    private fun rectSvg(filterBody: String): String {
        return """
            <svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
              <defs>
                <filter id="f" x="-20%" y="-20%" width="140%" height="140%">
                  $filterBody
                </filter>
              </defs>
              <rect x="48" y="48" width="160" height="160" fill="#ff0000" filter="url(#f)"/>
            </svg>
        """.trimIndent()
    }

    @Test
    fun backgroundImageIdentityIsTransparent() {
        // Identity on BackgroundImage: the red rect must vanish. Before the
        // fix the input resolves to null (primitive skipped) and the source
        // passes through opaque red.
        val b = render(
            rectSvg(
                """<feComposite in="BackgroundImage" in2="BackgroundImage" operator="over"/>""",
            ),
        )
        val center = b.getPixel(128, 128)
        assertTrue(
            "BackgroundImage identity must be transparent, was ${Integer.toHexString(center)}",
            center.alpha < 50,
        )
    }

    @Test
    fun backgroundImageClipsFloodToEmpty() {
        // Flood clipped to BackgroundImage (`in`): transparent, proving the
        // input resolved (not null) and applied. Skipped, the flood (previous
        // result) would pass through opaque blue.
        val b = render(
            rectSvg(
                """
                <feFlood flood-color="#0000ff" result="f"/>
                <feComposite in="f" in2="BackgroundImage" operator="in"/>
                """.trimIndent(),
            ),
        )
        val center = b.getPixel(128, 128)
        assertTrue(
            "flood clipped to BackgroundImage must be transparent, was ${Integer.toHexString(center)}",
            center.alpha < 50,
        )
    }

    @Test
    fun backgroundAlphaIdentityIsTransparent() {
        // Same as BackgroundImage but through the alpha extraction.
        val b = render(
            rectSvg(
                """<feComposite in="BackgroundAlpha" in2="BackgroundAlpha" operator="over"/>""",
            ),
        )
        val center = b.getPixel(128, 128)
        assertTrue(
            "BackgroundAlpha identity must be transparent, was ${Integer.toHexString(center)}",
            center.alpha < 50,
        )
    }
}
