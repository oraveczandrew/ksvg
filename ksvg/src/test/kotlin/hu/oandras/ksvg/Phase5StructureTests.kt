package hu.oandras.ksvg

import android.graphics.Bitmap
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.renderWithLibrary
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class Phase5StructureTests {

    private fun render(svg: String): Bitmap = renderWithLibrary(svg, createBitmap(120, 120))


    // --- marker placement & orientation on a path start ---

    @Test
    fun markerStartIsPlacedAtFirstVertex() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <marker id="m" markerWidth="10" markerHeight="10" refX="5" refY="5"
                        orient="auto">
                  <rect x="0" y="0" width="10" height="10" fill="red"/>
                </marker>
              </defs>
              <path d="M60 20 H110" stroke="black" stroke-width="2"
                    marker-start="url(#m)" fill="none"/>
            </svg>
        """.trimIndent()
        val b = render(svg)

        // refX/refY=5 centers the 10x10 marker on the path start (60,20):
        // red must appear around it and NOT at the far end.
        assertTrue("Marker expected at start vertex", isRed(b, 60, 20))
        assertTrue(isRed(b, 56, 16))
        assertTrue("No marker at end vertex", !isRed(b, 108, 20))
    }

    // --- textPath positions glyphs along the referenced path ---

    @Test
    fun textPathFollowsPathGeometry() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <path id="curve" d="M10 90 H110"/>
              </defs>
              <text font-size="24" fill="black">
                <textPath href="#curve">WIDE</textPath>
              </text>
            </svg>
        """.trimIndent()
        val b = render(svg)

        // Glyphs must be drawn near the path's y (90), not at the text default
        // position (0,0).
        fun darkInBand(yFrom: Int, yTo: Int): Int {
            var n = 0
            for (y in yFrom until yTo) for (x in 0 until 120) {
                if (isBlack(b, x, y)) n++
            }
            return n
        }
        val nearPath = darkInBand(70, 95)
        val atOrigin = darkInBand(0, 25)
        assertTrue("Expected glyphs along the path band (got $nearPath)", nearPath > 20)
        assertTrue("Expected no glyphs at the origin", atOrigin == 0)
    }

    // --- <switch> picks the child matching the runtime locale ---

    @Test
    fun switchSelectsMatchingLanguage() {
        val svg = """
            <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              <switch>
                <rect x="0" y="0" width="120" height="120" fill="red" systemLanguage="de"/>
                <rect x="0" y="0" width="120" height="120" fill="lime" systemLanguage="en"/>
                <rect x="0" y="0" width="120" height="120" fill="blue"/>
              </switch>
            </svg>
        """.trimIndent()
        val b = render(svg)
        // Robolectric default locale is en -> the second child must win; the bare
        // fallback rect is only used when NO systemLanguage child matches.
        assertTrue("Expected 'en' child to be selected", isRed(b, 60, 60).not())
        assertTrue(
            "Expected lime ('en' branch)",
            isGreen(b, 60, 60)
        )
    }
}
