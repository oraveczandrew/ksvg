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
class Phase5PaintTests {

    private fun render(svg: String): android.graphics.Bitmap {
        val bitmap = createBitmap(120, 120)
        SVG.getFromString(svg).renderToCanvas(Canvas(bitmap))
        return bitmap
    }

    // --- odd-length stroke-dasharray must be doubled ([10] -> [10,10]) ---

    @Test
    fun oddLengthDashArrayIsDoubled() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <path d="M10 60 H110" stroke="black" stroke-width="6"
                    stroke-dasharray="20" fill="none"/>
            </svg>
        """.trimIndent()
        val b = render(svg)

        // Pattern becomes on[0,20) off[20,40): sample mid-dash and mid-gap.
        val on = isBlack(b, 65, 60)   // 5..25 within segment -> ON region (x=65 is 55 from start: off)
        // Compute explicitly: dashes start at x=10: on [10,30), off [30,50), on [50,70), off [70,90), on [90,110).
        assertTrue("x=20 must be a dash", isBlack(b, 20, 60))
        assertTrue("x=40 must be a gap", !isBlack(b, 40, 60))
        assertTrue("x=60 must be a dash", isBlack(b, 60, 60))
        assertTrue("x=80 must be a gap", !isBlack(b, 80, 60))
        assertTrue("x=100 must be a dash", isBlack(b, 100, 60))
    }

    // --- vector-effect: non-scaling-stroke keeps stroke width in device units ---

    @Test
    fun nonScalingStrokeKeepsDeviceWidth() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <g transform="scale(4)">
                <path d="M10 20 H20" stroke="black" stroke-width="2"
                      vector-effect="non-scaling-stroke" fill="none"/>
              </g>
            </svg>
        """.trimIndent()
        val b = render(svg)

        // Line at user y=20 -> device y=80; device stroke width should be ~2px, not 8px.
        fun dark(x: Int, y: Int) = isBlack(b, x, y)
        val column = (11..19).map { x -> x * 4 }.map { x ->
            (74..86).count { y -> dark(x, y) }
        }.maxOrNull() ?: 0
        assertTrue("Expected ~2px device stroke, got $column", column <= 4)
    }

    // --- scaled stroke WITHOUT vector-effect grows with the transform ---

    @Test
    fun scalingStrokeGrowsWithTransform() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <g transform="scale(4)">
                <path d="M10 20 H20" stroke="black" stroke-width="2" fill="none"/>
              </g>
            </svg>
        """.trimIndent()
        val b = render(svg)
        fun dark(x: Int, y: Int) = isBlack(b, x, y)
        val column = (11..19).map { x -> x * 4 }.map { x ->
            (74..86).count { y -> dark(x, y) }
        }.maxOrNull() ?: 0
        assertTrue("Expected ~8px device stroke (2*4), got $column", column >= 7)
    }

    // --- currentColor resolves against the 'color' property ---

    @Test
    fun currentColorUsesColorProperty() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <g color="lime">
                <rect x="10" y="10" width="100" height="100" fill="currentColor"/>
              </g>
            </svg>
        """.trimIndent()
        val b = render(svg)
        val p = b.getPixel(60, 60)
        assertTrue(
            "Expected lime via currentColor",
            (p shr 16 and 0xff) < 60 && (p shr 8 and 0xff) > 200 && (p and 0xff) < 60
        )
    }
}
