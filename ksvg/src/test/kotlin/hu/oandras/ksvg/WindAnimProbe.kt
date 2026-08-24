package hu.oandras.ksvg

import android.graphics.Canvas
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.render.createBitmap
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WindAnimProbe {

    private fun renderAt(doc: SVGImpl, timeMs: Long): android.graphics.Bitmap {
        doc.animationTimeMs = timeMs
        val bmp = createBitmap(128, 128)
        doc.renderToCanvas(Canvas(bmp))
        return bmp
    }

    @Test fun dashOffsetAnimates() {
        val f = File("test-data/meteocons/animated/fill/wind.svg")
        val doc = SVG.getFromString(f.readText(), parseAnimations = true) as SVGImpl

        val b0 = renderAt(doc, 0L)
        val diff = { a: android.graphics.Bitmap, b: android.graphics.Bitmap ->
            var n = 0
            for (y in 0 until 128) for (x in 0 until 128) {
                if (a.getPixel(x, y) != b.getPixel(x, y)) n++
            }
            n
        }
        val d03 = diff(b0, renderAt(doc, 3000L))
        val d06 = diff(b0, renderAt(doc, 6000L))
        println("PROBE diff(0s,3s)=$d03 diff(0s,6s)=$d06")
        // values="0;1000" dur=6s repeatCount=indefinite -> t=3s differs, t=6s wraps to same
        assertTrue("Expected dash animation to change output", d03 > 50)
    }
}
