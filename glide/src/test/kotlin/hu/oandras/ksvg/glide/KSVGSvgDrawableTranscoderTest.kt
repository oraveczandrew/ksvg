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
import hu.oandras.ksvg.KSVGAnimatedDrawable
import hu.oandras.ksvg.KSVGDrawable
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
        val resource = transcoder.transcode(svgResource(), options)
        assertTrue(resource.get() is KSVGAnimatedDrawable)
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
}
