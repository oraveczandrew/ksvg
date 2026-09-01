package hu.oandras.ksvg.aihelpers

import hu.oandras.ksvg.render.createBitmap
import hu.oandras.ksvg.test.decodePng
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs

/**
 * Broad search over a scale+offset transform mapping out.png/golden canvas
 * pixels back to kernel-dump pixels: kernelX = outX*scale + offX,
 * kernelY = outY*scale + offY. Finds whether ANY simple transform makes the
 * dumped field line up with out.png / golden.png.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class KernelVsImagesProbe {

    @Test
    fun probe() {
        val golden = createBitmap(256, 256)
        val out = createBitmap(256, 256)
        decodePng(File("test-data/visual-golden/turbulence_seed_stitch.png"), golden)
        decodePng(File("test-data/ai-helper/turbulence_seed_stitch.out.png"), out)
        val gPx = IntArray(256 * 256)
        val oPx = IntArray(256 * 256)
        golden.getPixels(gPx, 0, 256, 0, 0, 256, 256)
        out.getPixels(oPx, 0, 256, 0, 0, 256, 256)

        val dumpFile = listOf(File("tmp/turb_kernel_dump.bin"), File("../tmp/turb_kernel_dump.bin")).firstOrNull { it.exists() } ?: File("tmp/turb_kernel_dump.bin")
        if (!dumpFile.exists()) return
        val bytes = dumpFile.readBytes()
        val buf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        val kw = 269
        val kh = 193
        val kPx = IntArray(kw * kh)
        for (i in kPx.indices) kPx[i] = buf.int

        val scales = listOf(1.0, 1.25, 1.6, 1.5, 0.8, 0.625, 2.0)
        val offsets = listOf(0.0, -3.2, -6.4, 6.4, -16.0, 16.0, 32.0, 3.2, -1.0, 1.0, -2.0, 2.0, -4.0, 4.0, -8.0, 8.0, -12.0, 12.0)
        for (scale in scales) {
            var bestE = Double.MAX_VALUE
            var bestOx = 0.0
            var bestOy = 0.0
            for (offX in offsets) {
                for (offY in offsets) {
                    var outErr = 0.0
                    var n = 0
                    for (cy in 0 until 256) {
                        val kyy = (cy * scale + offY).toInt()
                        if (kyy < 0 || kyy >= kh) continue
                        for (cx in 0 until 256) {
                            val kxx = (cx * scale + offX).toInt()
                            if (kxx < 0 || kxx >= kw) continue
                            val kv = kPx[kyy * kw + kxx]
                            val a = (kv shr 24) and 0xff
                            val ac = a / 255.0
                            val cri = (((kv shr 16) and 0xff) * ac + 255 * (1 - ac)).toInt()
                            val cgi = (((kv shr 8) and 0xff) * ac + 255 * (1 - ac)).toInt()
                            val cbi = ((kv and 0xff) * ac + 255 * (1 - ac)).toInt()
                            val ov = oPx[cy * 256 + cx]
                            outErr += abs(((ov shr 16) and 0xff) - cri) + abs(((ov shr 8) and 0xff) - cgi) + abs((ov and 0xff) - cbi)
                            n++
                        }
                    }
                    val e = outErr / n / 3
                    if (e < bestE) { bestE = e; bestOx = offX; bestOy = offY }
                }
            }
            // golden at best offset
            var gErr = 0.0
            var m = 0
            for (cy in 0 until 256) {
                val kyy = (cy * scale + bestOy).toInt()
                if (kyy < 0 || kyy >= kh) continue
                for (cx in 0 until 256) {
                    val kxx = (cx * scale + bestOx).toInt()
                    if (kxx < 0 || kxx >= kw) continue
                    val kv = kPx[kyy * kw + kxx]
                    val a = (kv shr 24) and 0xff; val ac = a / 255.0
                    val cri = (((kv shr 16) and 0xff) * ac + 255 * (1 - ac)).toInt()
                    val cgi = (((kv shr 8) and 0xff) * ac + 255 * (1 - ac)).toInt()
                    val cbi = ((kv and 0xff) * ac + 255 * (1 - ac)).toInt()
                    val gv = gPx[cy * 256 + cx]
                    gErr += abs(((gv shr 16) and 0xff) - cri) + abs(((gv shr 8) and 0xff) - cgi) + abs((gv and 0xff) - cbi); m++
                }
            }
            println("scale=$scale BEST out=${bestE.toString().take(7)} off=(${bestOx},${bestOy})  golden@thatoff=${(gErr / m / 3).toString().take(7)}")
        }
    }
}
