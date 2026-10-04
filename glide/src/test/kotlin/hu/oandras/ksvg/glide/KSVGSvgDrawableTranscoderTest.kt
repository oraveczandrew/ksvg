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

package hu.oandras.ksvg.glide

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import com.bumptech.glide.load.Options
import hu.oandras.ksvg.KSVGAnimatedDrawable
import hu.oandras.ksvg.KSVGDrawable
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class KSVGSvgDrawableTranscoderTest {

    private val transcoder = KSVGSvgDrawableTranscoder()

    private fun svgResource(): KSVGSvgResource {
        resourceAsInputStream("example.svg").use {
            return KSVGSvgDecoder().decode(it, 192, 192, Options()) as KSVGSvgResource
        }
    }

    @Test
    fun transcodeReturnsDrawable() {
        val resource = transcoder.transcode(svgResource(), Options())
        assertTrue(resource.get() is KSVGDrawable)
    }

    @Test
    fun transcodeWithAnimationsReturnsAnimatedDrawable() {
        val options = Options().set(KSVGOptions.PARSE_ANIMATIONS, true)
        val resource = transcoder.transcode(animatedSvgResource(parseAnimations = true), options)
        assertTrue(resource.get() is KSVGAnimatedDrawable)
    }

    @Test
    fun transcodeStaticDocumentWithAnimationsReturnsPlainDrawable() {
        val options = Options().set(KSVGOptions.PARSE_ANIMATIONS, true)
        val resource = transcoder.transcode(svgResource(), options)
        assertTrue(resource.get() is KSVGDrawable)
        assertFalse(resource.get() is KSVGAnimatedDrawable)
    }

    @Test
    fun transcodeAnimationsDroppedAtParseReturnsPlainDrawable() {
        val options = Options().set(KSVGOptions.PARSE_ANIMATIONS, true)
        val resource = transcoder.transcode(animatedSvgResource(parseAnimations = false), options)
        assertTrue(resource.get() is KSVGDrawable)
        assertFalse(resource.get() is KSVGAnimatedDrawable)
    }

    private fun animatedSvgResource(parseAnimations: Boolean): KSVGSvgResource {
        val bytes = """
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
              <g>
                <animateTransform attributeName="transform" type="translate" values="0 0;10 0" dur="1s"/>
                <rect width="10" height="10"/>
              </g>
            </svg>
        """.trimIndent().toByteArray()
        val options = Options().set(KSVGOptions.PARSE_ANIMATIONS, parseAnimations)
        return bytes.inputStream().use {
            KSVGSvgDecoder().decode(it, 20, 20, options) as KSVGSvgResource
        }
    }

    // Every transcode must hand out a fresh instance: drawables own per-view
    // mutable state (scene, pools, bounds) and are never shared across targets.
    @Test
    fun eachTranscodeReturnsFreshInstance() {
        val svg = svgResource()
        val first = transcoder.transcode(svg, Options()).get()
        val second = transcoder.transcode(svg, Options()).get()
        assertNotSame(first, second)
    }

    // Glide 5 `DrawableResource.get()` hands out a `constantState.newDrawable()`
    // copy per call: every copy must render the same content as the original.
    @Test
    fun constantStateCopiesRenderIdentically() {
        val resource = transcoder.transcode(svgResource(), Options())
        val first = resource.get()
        val second = resource.get()
        assertNotSame(first, second)
        assertEquals(countOpaquePixels(first), countOpaquePixels(second))
        assertTrue(countOpaquePixels(first) > 0)
    }

    private fun countOpaquePixels(drawable: Drawable): Int {
        val width = drawable.intrinsicWidth
        val height = drawable.intrinsicHeight
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            drawable.setBounds(0, 0, width, height)
            drawable.draw(Canvas(bitmap))
            // Transparent-black canvas: any nonzero pixel was painted.
            var count = 0
            for (y in 0 until height) {
                for (x in 0 until width) {
                    if (bitmap.getPixel(x, y) != 0) count++
                }
            }
            return count
        } finally {
            bitmap.recycle()
        }
    }
}
