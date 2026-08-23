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
class D11TransformViewBoxOrderTest {

    @Test
    fun elementTransformIsOutermost() {
        // Nested <svg> with viewBox="0 0 10 10" over a 100x100 viewport (scale x10),
        // plus transform="translate(50,0)". Per SVG the element `transform` is outermost:
        // content (0..10) -> viewBox scale x10 -> (0..100) -> translate(50,0) -> (50..150).
        // So the red rect must sit at x in [50,150], shifted right by 50.
        val svg = """
            <svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
              <svg x="0" y="0" width="100" height="100" viewBox="0 0 10 10"
                   transform="translate(50,0)" overflow="visible">
                <rect x="0" y="0" width="10" height="10" fill="red"/>
              </svg>
            </svg>
        """.trimIndent()

        val document = SVG.getFromString(svg)
        val bitmap = createBitmap(200, 200)
        val canvas = Canvas(bitmap)
        document.renderToCanvas(canvas)

        val isRed: (Int, Int) -> Boolean = { x, y ->
            val p = bitmap.getPixel(x, y)
            (p shr 16 and 0xff) > 200 && (p shr 8 and 0xff) < 60 && (p and 0xff) < 60
        }

        // Correct (transform outermost): red spans x 50..150.
        assertTrue("Expected red rect shifted to x=75 (transform outermost)", isRed(75, 50))
        assertTrue("Expected red rect at x=125 (transform outermost)", isRed(125, 50))
        // It must NOT be at the origin (that would be the no-transform / wrong-order case).
        assertTrue("Expected no red at x=25 (rect should be shifted right by 50)", !isRed(25, 50))
    }
}
