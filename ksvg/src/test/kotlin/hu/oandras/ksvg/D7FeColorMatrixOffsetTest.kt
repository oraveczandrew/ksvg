package hu.oandras.ksvg

import android.graphics.Canvas
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class D7FeColorMatrixOffsetTest {

    @Test
    fun offsetIsInUnitSpace() {
        val svg = """
            <svg width="10" height="10" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <filter id="f" x="0" y="0" width="1" height="1" color-interpolation-filters="sRGB">
                  <feColorMatrix type="matrix"
                    values="1 0 0 0 0.5  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0"/>
                </filter>
              </defs>
              <rect x="0" y="0" width="10" height="10" fill="black" filter="url(#f)"/>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)

        val bitmap = createBitmap(10, 10)
        val canvas = Canvas(bitmap)
        document.renderToCanvas(canvas)

        val pixel = bitmap.getPixel(5, 5)
        val r = (pixel shr 16) and 0xff
        val g = (pixel shr 8) and 0xff
        val b = pixel and 0xff
        val a = (pixel shr 24) and 0xff

        // SVG: offset 0.5 adds 0.5 to R in [0,1] space -> ~128.
        // Bug (offset * 255 = 127.5): R' clamps to 255 (full white).
        assertTrue("Expected R ~= 128 (offset in [0,1]), got R=$r", r in 120..140)
        assertTrue("Expected G=0, got G=$g", g == 0)
        assertTrue("Expected B=0, got B=$b", b == 0)
        assertTrue("Expected A=255, got A=$a", a == 255)
    }
}
