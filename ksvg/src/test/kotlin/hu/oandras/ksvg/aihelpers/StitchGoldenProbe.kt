package hu.oandras.ksvg.aihelpers

import hu.oandras.ksvg.filtering.LcgRandom
import hu.oandras.ksvg.filtering.SvgPathNoise
import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.decodePng
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.roundToInt

/**
 * Targeted probe for `turbulence_seed_stitch.svg`.
 *
 * Uses the exact parameters captured from `doFeTurbulenceFilter` debug output:
 *   invCanvasScale = 0.625, userLeft = -4, userTop = 0, unitSize = 1,
 *   baseFx = 0.07063197026022305, baseFy = 0.07253886010362694,
 *   periodX = 19, periodY = 14, octaves = 2, seed = 7, fractal = false.
 *
 * For each canvas pixel (x, y) it computes the raw turbulence channels exactly as
 * `KotlinKernels.turbulence` does (px/py from userLeft+tile*invScale), blends the rgb
 * over white using alpha (= channel 3), and compares the resulting composite against
 * the golden. It sweeps the octave wrap-update rule: KSVG's recompute-from-doubled
 * `curtlx` vs librsvg's `octaveWrap = 2*wrap - PERLIN_N`.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class StitchGoldenProbe {

    @Test
    fun probe() {
        val golden = createBitmap(256, 256)
        decodePng(File("test-data/visual-golden/turbulence_seed_stitch.png"), golden)
        val gPx = IntArray(256 * 256)
        golden.getPixels(gPx, 0, 256, 0, 0, 256, 256)

        val lcg = LcgRandom(7)
        val p = IntArray(SvgPathNoise.LATTICE_SIZE)
        val gens = Array(4) { SvgPathNoise(lcg, p) }
        SvgPathNoise.buildPermutation(lcg, p)

        val invCS = 0.625
        val userLeft = -4.0
        val userTop = 0.0
        val unit = 1.0
        val baseFx = 0.07063197026022305
        val baseFy = 0.07253886010362694
        val periodX = 19
        val periodY = 14
        val octaves = 2

        // deviceRegion = RectF(-6.4, 16.0, 262.4, 208.0). The 269x193 kernel bitmap is drawn
        // 1:1 at deviceRegion.left/top, so:
        //   kernel x = canvasX + 6.4     (kernel col 0 at canvas -6.4)
        //   kernel y = canvasY - 16.0    (kernel row 0 at canvas +16)
        // Sweep the exact fractional kernel-left offset around -6.4 to confirm the anchoring.
        for (kleft in listOf(-6.0, -6.25, -6.4, -6.5, -6.75, -7.0, -7.25, -7.5, -8.0)) {
            var close = 0
            var sumAbs = 0L
            val top = 16.0
            for (cy in 0 until 256) {
                val ky = cy - top
                val userY = userTop + ky * invCS
                val py0 = (userY / unit) * baseFy
                for (cx in 0 until 256) {
                    val kx = cx + kleft
                    val userX = userLeft + kx * invCS
                    val px0 = (userX / unit) * baseFx

                    val fX = (invCS / unit) * baseFx
                    val fY = (invCS / unit) * baseFy
                    val tileX = kx
                    val tileY = ky

                    val sums = DoubleArray(4)
                    for (ch in 0 until 4) {
                        var px = px0
                        var py = py0
                        var curtlx = tileX * fX
                        var curtly = tileY * fY
                        var octPeriodX = periodX
                        var octPeriodY = periodY
                        var ratio = 1.0
                        var value = 0.0
                        repeat(octaves) {
                            val wrapX = floor(curtlx).toInt() + 4096 + octPeriodX
                            val wrapY = floor(curtly).toInt() + 4096 + octPeriodY
                            val n = gens[ch].noise2(px, py, octPeriodX, octPeriodY, wrapX, wrapY)
                            value += abs(n) / ratio
                            px *= 2.0
                            py *= 2.0
                            ratio *= 2.0
                            curtlx *= 2.0
                            curtly *= 2.0
                            octPeriodX *= 2
                            octPeriodY *= 2
                        }
                        sums[ch] = value
                    }
                    val r = clamp(sums[0] * 255.0)
                    val g = clamp(sums[1] * 255.0)
                    val b = clamp(sums[2] * 255.0)
                    val a = clamp(sums[3] * 255.0)

                    val cr = (r * a / 255.0 + 255 * (1 - a / 255.0))
                    val cg = (g * a / 255.0 + 255 * (1 - a / 255.0))
                    val cb = (b * a / 255.0 + 255 * (1 - a / 255.0))

                    val gv = gPx[cy * 256 + cx]
                    val gr = (gv shr 16) and 0xff
                    val gg2 = (gv shr 8) and 0xff
                    val gb = gv and 0xff

                    val dr = abs(cr.roundToInt() - gr)
                    val dg = abs(cg.roundToInt() - gg2)
                    val db = abs(cb.roundToInt() - gb)
                    if (dr <= 8 && dg <= 8 && db <= 8) {
                        close++
                        sumAbs += dr + dg + db
                    }
                }
            }
            println("KLEFT=$kleft  close(<=8): $close/65536  meanAbs(close px)=${if (close>0) sumAbs.toDouble()/close else 0.0}")
        }
    }

    private fun clamp(v: Double): Int = v.toInt().coerceIn(0, 255)
}