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

package hu.oandras.ksvg.glide

import com.bumptech.glide.load.Options
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPoolAdapter
import com.bumptech.glide.request.target.Target
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode
import java.io.ByteArrayInputStream
import java.io.FilterInputStream
import java.io.IOException
import java.io.InputStream

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class SvgDecoderTest {

    private lateinit var decoder: SvgDecoder

    @Before
    fun init() {
        decoder = SvgDecoder(BitmapPoolAdapter())
    }

    @Test
    fun testHandles() {
        resourceAsInputStream("example.svg").use {
            assertTrue(decoder.handles(it, Options()))
        }
    }

    @Test
    fun testNotHandles() {
        resourceAsInputStream("example.jpg").use {
            assertFalse(decoder.handles(it, Options()))
        }
    }

    @Test
    fun testHandlesLeadingComment() {
        // SVGs may start with a license/author comment before the <svg> tag, pushing the
        // marker beyond a small fixed look-ahead window. The decoder must still claim them.
        resourceAsInputStream("leading_comment.svg").use {
            assertTrue(decoder.handles(it, Options()))
        }
    }

    @Test
    fun testDecode() {
        resourceAsInputStream("example.svg").use {
            assertNotNull(decoder.decode(it, 192, 192, Options()))
        }
    }

    // Glide hands the same stream to decode() after handles().
    @Test
    fun testHandlesDoesNotConsumeStream() {
        val bytes = resourceAsInputStream("example.svg").use { it.readBytes() }
        val shared = ByteArrayInputStream(bytes)
        assertTrue(decoder.handles(shared, Options()))
        assertNotNull(decoder.decode(shared, 192, 192, Options()))
    }

    // Absurd document dimensions clamp aspect-preserving
    // instead of exploding the bitmap allocation.
    @Test
    fun testHugeDocumentClamps() {
        val svg = """<svg xmlns="http://www.w3.org/2000/svg" width="20000" height="100">""" +
            """<rect width="20000" height="100" fill="#FF0000"/></svg>"""
        val stream = ByteArrayInputStream(svg.toByteArray())
        val bitmap = decoder.decode(stream, Target.SIZE_ORIGINAL, Target.SIZE_ORIGINAL, Options()).get()
        assertEquals(SvgDecoder.MAX_DECODE_DIMENSION, bitmap.width)
        assertEquals(41, bitmap.height)
    }

    @Test
    fun testDecodeSizeOriginalUsesIntrinsicSize() {
        val svg = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50">""" +
            """<rect width="100" height="50"/></svg>"""
        val bitmap = decoder.decode(
            ByteArrayInputStream(svg.toByteArray()),
            Target.SIZE_ORIGINAL, Target.SIZE_ORIGINAL, Options(),
        ).get()
        assertEquals(100, bitmap.width)
        assertEquals(50, bitmap.height)
    }

    @Test
    fun testDecodeViewBoxOnlyFallsBackToTargetSize() {
        val svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 20">""" +
            """<rect width="40" height="20"/></svg>"""
        val bitmap = decoder.decode(
            ByteArrayInputStream(svg.toByteArray()), 200, 100, Options(),
        ).get()
        assertEquals(200, bitmap.width)
        assertEquals(100, bitmap.height)
    }

    @Test
    fun testDecodeViewBoxOnlySizeOriginalFallsBackTo192() {
        val svg = """<svg xmlns="http://www.w3.org/2000/svg">""" +
            """<rect width="40" height="20"/></svg>"""
        val bitmap = decoder.decode(
            ByteArrayInputStream(svg.toByteArray()),
            Target.SIZE_ORIGINAL, Target.SIZE_ORIGINAL, Options(),
        ).get()
        assertEquals(192, bitmap.width)
        assertEquals(192, bitmap.height)
    }

    @Test
    fun testDecodeSingleFixedDimensionKeepsAspect() {
        val svg = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50">""" +
            """<rect width="100" height="50"/></svg>"""
        val onlyHeight = decoder.decode(
            ByteArrayInputStream(svg.toByteArray()),
            Target.SIZE_ORIGINAL, 100, Options(),
        ).get()
        assertEquals(200, onlyHeight.width)
        assertEquals(100, onlyHeight.height)

        val onlyWidth = decoder.decode(
            ByteArrayInputStream(svg.toByteArray()),
            200, Target.SIZE_ORIGINAL, Options(),
        ).get()
        assertEquals(200, onlyWidth.width)
        assertEquals(100, onlyWidth.height)
    }

    @Test
    fun testDecodeUsesMaxScaleToFill() {
        // 100x50 intrinsic into a 200x200 target: max scale (4x) wins over min (2x).
        val svg = """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50">""" +
            """<rect width="100" height="50"/></svg>"""
        val bitmap = decoder.decode(
            ByteArrayInputStream(svg.toByteArray()), 200, 200, Options(),
        ).get()
        assertEquals(400, bitmap.width)
        assertEquals(200, bitmap.height)
    }

    @Test
    fun testDecodeInvalidSvgThrowsIOException() {
        val stream = ByteArrayInputStream("this is not xml {{{".toByteArray())
        try {
            decoder.decode(stream, 100, 100, Options())
            fail("Expected IOException")
        } catch (_: IOException) {
            // expected: KSVGParseException is wrapped
        }
    }

    @Test
    fun testHandlesStreamWithoutMarkSupport() {
        val raw = ByteArrayInputStream("<svg/>".toByteArray())
        val noMark: InputStream = object : FilterInputStream(raw) {
            override fun markSupported(): Boolean = false
        }
        assertFalse(decoder.handles(noMark, Options()))
    }
}