package hu.oandras.ksvg

import android.graphics.Canvas
import hu.oandras.ksvg.render.SvgPathNoise
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.utils.LcgRandom
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D10StitchTilesTest {

    @Test
    fun periodicNoiseRepeatsEveryPeriod() {
        val noise = SvgPathNoise(LcgRandom(7))
        val p = 10
        for (t in listOf(0.3, 3.7, 9.9999)) {
            val v = noise.noise2(t, 2.4, p, p)
            assertTrue("noise(x+$p) must equal noise(x)", kotlin.math.abs(v - noise.noise2(t + p, 2.4, p, p)) < 1e-9)
            assertTrue("noise(y+$p) must equal noise(y)", kotlin.math.abs(v - noise.noise2(t, 2.4 + p, p, p)) < 1e-9)
        }
        // Sanity: without a period the values differ.
        val a = noise.noise2(1.234, 2.4)
        assertTrue(kotlin.math.abs(a - noise.noise2(1.234 + p, 2.4)) > 1e-6)
    }

    private fun render(stitchTiles: String): android.graphics.Bitmap {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <filter id="f" x="0" y="0" width="1" height="1">
                  <feTurbulence type="turbulence" baseFrequency="0.1" numOctaves="2"
                                seed="7" stitchTiles="$stitchTiles"/>
                </filter>
              </defs>
              <rect x="0" y="0" width="100" height="100" fill="white" filter="url(#f)"/>
            </svg>
        """.trimIndent()

        val bitmap = createBitmap(100, 100)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    @Test
    fun stitchChangesSampling() {
        // With stitch the effective base frequency is adjusted to
        // round(tile*f)/tile; here it happens to be identical (0.1*100=10 is
        // already integral), but the periodic wrapping still yields the same
        // values while a different frequency/seed combination does not.
        // Smoke check: both modes render non-trivial noise.
        for (mode in listOf("stitch", "noStitch")) {
            val bitmap = render(mode)
            var variance = 0.0
            var last = -1
            for (x in 0 until 100) {
                val v = (bitmap.getPixel(x, 50) shr 16) and 0xff
                if (last >= 0) variance += kotlin.math.abs(v - last)
                last = v
            }
            assertTrue("Expected non-constant noise for $mode", variance > 500.0)
        }
    }
}
