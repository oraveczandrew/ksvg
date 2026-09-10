/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

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
import kotlin.math.pow

/**
 * At the CONFIRMED projection (kernelX = outX + 6.4, kernelY = outY - 16,
 * scale 1.0 — verified: out.png matches dump at 0.45 err), fit the model that
 * turns the (correct) kernel-dump composite into the golden. This isolates
 * exactly how the golden's turbulence differs from KSVG's.
 */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [33])
class GoldenModelProbe {

    @Test
    fun probe() {
        val golden = createBitmap(256, 256)
        val gPx = IntArray(256 * 256)
        decodePng(File("test-data/visual-golden/turbulence_seed_stitch.png"), golden)
        golden.getPixels(gPx, 0, 256, 0, 0, 256, 256)

        val dumpFile = listOf(File("tmp/turb_kernel_dump.bin"), File("../tmp/turb_kernel_dump.bin")).firstOrNull { it.exists() } ?: File("tmp/turb_kernel_dump.bin")
        if (!dumpFile.exists()) return
        val bytes = dumpFile.readBytes()
        val buf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        val kw = 269
        val kh = 193
        val kPx = IntArray(kw * kh)
        for (i in kPx.indices) kPx[i] = buf.int

        // projection: kernel = canvas + (6.4, -16)
        val offX = 6.4
        val offY = -16.0

        // Gather per-pixel (golden composite, dump raw rgb, dump alpha).
        data class Px(val gr: Int, val gg: Int, val gb: Int, val rr: Int, val gg2: Int, val bb: Int, val aa: Int, val ga: Int)
        val pts = mutableListOf<Px>()
        for (cy in 0 until 256) {
            val kyy = (cy + offY).toInt()
            if (kyy < 0 || kyy >= kh) continue
            for (cx in 0 until 256) {
                val kxx = (cx + offX).toInt()
                if (kxx < 0 || kxx >= kw) continue
                val kv = kPx[kyy * kw + kxx]
                val aa = (kv shr 24) and 0xff
                if (aa == 0) continue
                val rr = (kv shr 16) and 0xff
                val gg2 = (kv shr 8) and 0xff
                val bb = kv and 0xff
                val gv = gPx[cy * 256 + cx]
                val gr = (gv shr 16) and 0xff
                val gg = (gv shr 8) and 0xff
                val gb = gv and 0xff
                val gaCh = (gv shr 24) and 0xff
                // only the noise region: golden not pure white and dump not pure white
                if (gr < 250 || gg < 250 || gb < 250) pts.add(Px(gr, gg, gb, rr, gg2, bb, aa, gaCh))
            }
        }
        if (pts.isEmpty()) return
        println("points=${pts.size}")
        // Alpha-channel comparison: does the golden PNG's alpha == dump channel-3?
        var aExact = 0
        var aDelta = 0L
        var aSum = 0L
        var gaCount255 = 0
        var aaCount255 = 0
        for (p in pts) {
            if (p.ga == p.aa) aExact++
            aDelta += abs(p.ga - p.aa)
            aSum += p.aa
            if (p.ga == 255) gaCount255++
            if (p.aa == 255) aaCount255++
        }
        println("golden.alpha == dump.channel3: $aExact/${pts.size}  mean|ga-aa|=${(aDelta.toDouble() / pts.size).toString().take(6)}")
        println("golden.alpha=255: $gaCount255/${pts.size}  dump.alpha=255(=channel3): $aaCount255/${pts.size}  mean dump.aa=${(aSum.toDouble() / pts.size).toString().take(6)}")

        // Model 1: out-composite (alpha blend with dump alpha) vs golden
        var m1 = 0.0
        // Model 2: constant lerp golden = c*outcomp + (1-c)*255
        var m2num = 0.0
        var m2den = 0.0
        // Model 3: golden = c*255 - ... gamma? golden = (comp/255)^gamma *255
        // Model 4: raw composited with a fixed constant alpha A (golden = raw*A/255 + (1-A/255)*255)
        // We'll solve A per-channel by linear regression.
        var s1 = 0.0; var s2 = 0.0; var s3 = 0.0; var s4 = 0.0; var s5 = 0.0
        for (p in pts) {
            val ac = p.aa / 255.0
            val comp = (p.rr * ac + 255 * (1 - ac))
            m1 += abs(p.gr - comp)

            // Model 2: golden = c*comp + (1-c)*255  => (golden-255) = c*(comp-255)
            m2num += (p.gr - 255) * (comp - 255)
            m2den += (comp - 255) * (comp - 255)

            // Model 4 solve A/255 = (golden-255)/(raw-255) using raw (not composite)
            s1 += (p.gr - 255.0) / (p.rr - 255.0)
            s2 += ((p.gr - 255.0) / (p.rr - 255.0)) * ((p.gr - 255.0) / (p.rr - 255.0))
        }
        val c2 = m2num / m2den
        // re-eval model2 residual
        var m2e = 0.0
        var m3e = 0.0 // gamma fit via mean-ratio golden^(1/g)
        var m4e = 0.0
        val Amean = s1 / pts.size
        // also sqrt-mean for A
        val aMean = Amean
        for (p in pts) {
            val ac = p.aa / 255.0
            val comp = (p.rr * ac + 255 * (1 - ac))
            val model2 = c2 * comp + (1 - c2) * 255
            m2e += abs(p.gr - model2)
            // model4: raw with constant A
            val m4 = aMean * p.rr + (1 - aMean) * 255
            m4e += abs(p.gr - m4)
        }
        println("Model1 (out-comp, alpha blend) err = ${(m1 / pts.size).toString().take(7)}")
        println("Model2 (const lerp golden=c*comp+(1-c)*255) c=$c2  err=${(m2e / pts.size).toString().take(7)}")
        println("Model4 (raw with const A=$aMean) err=${(m4e / pts.size).toString().take(7)}")

        // Model KA: golden = raw*(k*ac) + white*(1-k*ac), opaque; fit scalar k applied to alpha.
        // (golden-255) = k*ac*(raw-255)  =>  k = sum(ac*(golden-255)*(raw-255)) / sum(ac^2*(raw-255)^2)
        var kNum = 0.0
        var kDen = 0.0
        for (p in pts) {
            val ac = p.aa / 255.0
            kNum += ac * (p.gr - 255.0) * (p.rr - 255.0)
            kDen += ac * ac * (p.rr - 255.0) * (p.rr - 255.0)
        }
        val k = kNum / kDen
        var mkE = 0.0
        var mkEall = 0.0
        for (p in pts) {
            val ac = p.aa / 255.0
            val aeff = (k * ac).coerceIn(0.0, 1.0)
            val m = p.rr * aeff + 255 * (1 - aeff)
            mkE += abs(p.gr - m)
            mkEall += abs(p.gr - m) + abs(p.gg - m) // not used, placeholder
        }
        println("ModelKA (raw*(k*ac)+white, opaque) k=$k  err=${(mkE / pts.size).toString().take(7)}")

        // Per-channel fit of k: golden_ch = raw_ch*(k_c*ac) + 255*(1 - k_c*ac)
        for (chan in 0 until 3) {
            var kn = 0.0
            var kd = 0.0
            for (p in pts) {
                val ac = p.aa / 255.0
                var rawv = p.rr
                var gv = p.gr
                if (chan == 1) { rawv = p.gg2; gv = p.gg }
                if (chan == 2) { rawv = p.bb; gv = p.gb }
                kn += ac * (gv - 255.0) * (rawv - 255.0)
                kd += ac * ac * (rawv - 255.0) * (rawv - 255.0)
            }
            val kc = kn / kd
            var wyk = 0.0
            for (p in pts) {
                val ac = p.aa / 255.0
                var rawv = p.rr
                var gv = p.gr
                if (chan == 1) { rawv = p.gg2; gv = p.gg }
                if (chan == 2) { rawv = p.bb; gv = p.gb }
                val aeff = (kc * ac).coerceIn(0.0, 1.0)
                wyk += abs(gv - (rawv * aeff + 255 * (1 - aeff)))
            }
            println("  k[chan=$chan]=$kc  err=${(wyk / pts.size).toString().take(6)}")
        }

        // Candidate: golden = raw*ac2 + white*(1-ac2) where ac2 = f(ac). Test a few re-encodings per pixel.
        fun evalAlphaModel(name: String, f: (Double) -> (Double), p: Px): Double {
            val ac = p.aa / 255.0
            val a2 = f(ac).coerceIn(0.0, 1.0)
            val m = p.rr * a2 + 255 * (1 - a2)
            return abs(p.gr - m) + abs(p.gg - m) + abs(p.gb - m) / 1.0
        }
        fun report(name: String, f: (Double) -> (Double)) {
            var e = 0.0
            for (p in pts) e += evalAlphaModel(name, f, p)
            println("AltModel $name err=${(e / pts.size / 1.0).toString().take(6)}")
        }
        // model uses only alpha channel (no raw) => report separate
        report("ac", { ac -> ac })
        report("sqrt(ac)", { ac -> kotlin.math.sqrt(ac) })
        report("ac*ac", { ac -> ac * ac })
        report("ac*(2-ac)", { ac -> ac * (2 - ac) })
        report("ac^0.4", { ac -> ac.pow(0.4) })
        report("ac*0.65237", { ac -> ac * 0.6523714044525095 })

        // Per-pixel effective alpha: a_eff = (255-golden)/(255-raw)  (assumes opaque golden over white).
        // Compare a_eff against 0.65*ac and against ac; look for structure.
        var aeffNum = 0.0; var aeffDen = 0.0
        var corXY = 0.0; var corX2 = 0.0; var corY2 = 0.0; var corN = 0.0
        var meanAeff = 0.0
        var neq065 = 0.0
        var cntHigh = 0
        for (p in pts) {
            val ac = p.aa / 255.0
            val rawm = p.rr
            val denom = (255.0 - rawm)
            if (denom < 1.0) continue
            val aeff = (255.0 - p.gr) / denom
            meanAeff += aeff
            corXY += (aeff) * (ac); corX2 += ac * ac; corY2 += aeff * aeff
            corN += 1.0
            neq065 += abs(aeff - 0.65237 * ac)
            if (aeff > 1.0 + 0.05) cntHigh++
        }
        meanAeff /= corN
        val corr = (corXY / corN) / kotlin.math.sqrt((corX2 / corN) * (corY2 / corN))
        println("a_eff: mean=${(meanAeff).toString().take(6)}  corr(a_eff, ac)=${(corr).toString().take(6)}  mean|a_eff-0.65237*ac|=${(neq065 / corN).toString().take(6)}  count(a_eff>1.05)=$cntHigh/${corN.toInt()}")

        // Model 5: alpha-premultiply-ish: golden = comp but where golden alpha value is channel3 (aa).
        // golden composite = raw premul: already the same as comp. So skip.
        // Model 6: golden r = (rr*aa/255) (premultiplied raw) then NO unpremultiply over white?
        // i.e. golden returns premultiplied value directly = rr*aa/255 (dark, not over white).
        var m6 = 0.0
        for (p in pts) {
            val ac = p.aa / 255.0
            val pre = (p.rr * ac)
            m6 += abs(p.gr - pre)
        }
        println("Model6 (premultiplied raw, no white) err=${(m6 / pts.size).toString().take(7)}")

        // Model 7: golden = lerp(raw, white, t) i.e. raw faded, then NO alpha (opaque). solve t and c
        var tnum = 0.0; var tden = 0.0
        for (p in pts) {
            // golden-raw = t*(255-raw)
            tnum += (p.gr - p.rr) * (255 - p.rr)
            tden += (255 - p.rr) * (255 - p.rr)
        }
        val t7 = tnum / tden
        var m7e = 0.0
        for (p in pts) {
            val m = t7 * p.rr + (1 - t7) * 255
            m7e += abs(p.gr - m)
        }
        println("Model7 (const lerp raw, opaque) t=$t7 err=${(m7e / pts.size).toString().take(7)}")
    }
}
