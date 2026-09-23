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

import com.bumptech.glide.load.Options
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode
import java.io.ByteArrayInputStream
import java.io.IOException

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class KSVGDrawableDecoderTest {

    private val decoder = KSVGDrawableDecoder()

    @Test
    fun testDecodeValid() {
        resourceAsInputStream("example.svg").use {
            assertNotNull(decoder.decode(it, 192, 192, Options()))
        }
    }

    // Audit R5: parse failures must surface as IOException (Glide's decode
    // contract, mirroring SvgDecoder), never as RuntimeException.
    @Test
    fun testDecodeInvalidThrowsIOException() {
        ByteArrayInputStream("<<<not xml>>>".toByteArray()).use {
            val e = assertThrows(IOException::class.java) {
                decoder.decode(it, 192, 192, Options())
            }
            assertTrue(e.message?.isNotEmpty() == true)
        }
    }
}
