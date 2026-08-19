package hu.oandras.ksvg.glide

import com.bumptech.glide.load.Options
import com.bumptech.glide.load.engine.bitmap_recycle.BitmapPoolAdapter
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

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
}