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
class C7PathLengthTest {

    @Test
    fun pathLengthScalesDashArray() {
        val svg = """
            <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
              <path d="M0 50 L100 50" fill="none" stroke="black" stroke-width="4"
                    stroke-dasharray="10 10" pathLength="50"/>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)

        val bitmap = createBitmap(100, 100)
        val canvas = Canvas(bitmap)
        document.renderToCanvas(canvas)

        val drawn = { x: Int -> bitmap.getPixel(x, 50).ushr(24) and 0xff > 100 }
        // pathLength=50 on a 100px path doubles the dash array: [10,10] -> [20,20].
        // Pattern on a 100px stroke: on [0,20), off [20,40), on [40,60), off [60,80), on [80,100).
        // Without pathLength scaling the dash stays [10,10] -> x=25 would be ON.
        assertTrue("Expected stroke to be drawn near the path start (x=5)", drawn(5))
        assertTrue("Expected a dash gap at x=25 (pathLength=50 doubles the dash -> gap)", !drawn(25))
        assertTrue("Expected a dash segment at x=45", drawn(45))
        assertTrue("Expected a dash gap at x=65 (pathLength=50 doubles the dash -> gap)", !drawn(65))
    }
}
