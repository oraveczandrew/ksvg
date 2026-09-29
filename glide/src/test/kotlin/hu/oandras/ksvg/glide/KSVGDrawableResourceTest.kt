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
import hu.oandras.ksvg.KSVGDrawable
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class KSVGDrawableResourceTest {

    @Test
    fun getSizeCoversRetainedMemory() {
        val resource = resourceAsInputStream("example.svg").use {
            val svg = KSVGSvgDecoder().decode(it, 192, 192, Options())
            KSVGSvgDrawableTranscoder().transcode(svg, Options())
        }
        val drawable = resource.get() as KSVGDrawable
        // Retained bitmaps when present, otherwise a positive intrinsic-based
        // estimate — never weightless in the memory cache.
        assertTrue(resource.size > 0)
        assertTrue(
            resource.size >= drawable.getMemorySizeBytes()
                .coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
        )
    }

    @Test
    fun getSizeIsNonNegative() {
        resourceAsInputStream("example.svg").use {
            val svg = KSVGSvgDecoder().decode(it, 192, 192, Options())
            assertTrue(KSVGSvgDrawableTranscoder().transcode(svg, Options()).size >= 0)
        }
    }
}
