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