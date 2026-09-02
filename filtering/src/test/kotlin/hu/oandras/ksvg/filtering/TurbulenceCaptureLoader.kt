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

package hu.oandras.ksvg.filtering

import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Loader for the librsvg feTurbulence kernel-boundary dump format written by
 * `capture_dump` in `turbulence-parity/librsvg/turbulence.rs`.
 *
 * Layout (all little-endian), see the Rust writer for the authoritative spec:
 *
 *   "KSVGTURB" (8) + version u32 (4)
 *   canvasWidth u32, canvasHeight u32
 *   bounds x0,y0,x1,y1  i32 x4
 *   seed i32
 *   baseFreqX f64, baseFreqY f64          (RAW parsed, pre-stitch-adjust)
 *   numOctaves i32
 *   noiseType u8 (0=Turbulence, 1=FractalNoise), stitchTiles u8, pad u16
 *   tileWidth f64, tileHeight f64
 *   affine xx,yx,xy,yy,x0,y0  f64 x6
 *   gradient 4 x 514 x 2 f64  (channel-major)
 *   lattice_selector 514 x i32
 *   then one record per (pixel, color channel):
 *     pointX f64, pointY f64, tileX f64, tileY f64,
 *     baseFx f64, baseFy f64 (POST-stitch-adjusted, used in this call),
 *     colorChannel u32, numOctaves u32,
 *     numOctaves x { vecX f64, vecY f64, stW u32, stH u32,
 *                    wrapX i64, wrapY i64, noise f64, sum f64 }
 *
 * Record order is y outer, x middle, color channel inner:
 * index = ((y - y0) * width + (x - x0)) * 4 + channel.
 */
internal class TurbulenceCaptureLoader private constructor(
    val canvasWidth: Int,
    val canvasHeight: Int,
    val boundsX0: Int,
    val boundsY0: Int,
    val boundsX1: Int,
    val boundsY1: Int,
    val seed: Int,
    val baseFreqX: Double,
    val baseFreqY: Double,
    val numOctaves: Int,
    val noiseType: Int,
    val stitch: Boolean,
    val tileWidth: Double,
    val tileHeight: Double,
    val affine: DoubleArray,
    val gradient: DoubleArray,
    val latticeSelector: IntArray,
    val records: List<TurbulenceRecord>,
) {
    val boundsWidth: Int get() = boundsX1 - boundsX0
    val boundsHeight: Int get() = boundsY1 - boundsY0

    fun gradientValue(channel: Int, i: Int, j: Int): Double =
        gradient[((channel * 514) + i) * 2 + j]

    companion object {
        private const val MAGIC = "KSVGTURB"
        private const val LATTICE_SIZE = 514
        private const val B_SIZE = 256

        private const val RESOURCE_PATH = "hu/oandras/ksvg/filtering/turbulence-parity"

        /**
         * Resolution order:
         *  1. explicit filesystem path (if the name itself is an existing file);
         *  2. classpath resource committed under src/test/resources (the hermetic
         *     default, used by CI and by the committed parity regression test);
         *  3. `KSVG_TURB_CAPTURE_DIR` / `ksvg.turb.capture.dir`;
         *  4. a few repo-relative candidates for regenerated local captures.
         */
        fun resolveCaptureFile(name: String): File {
            val file = File(name)
            if (file.isFile) return file
            resolveResource(name)?.let { return it }
            val explicit = System.getenv("KSVG_TURB_CAPTURE_DIR")
                ?: System.getProperty("ksvg.turb.capture.dir")
            if (explicit != null) {
                val f = File(explicit, name)
                if (f.isFile) return f
            }
            val candidates = listOf(
                "tmp/librsvg-capture",
                "../tmp/librsvg-capture",
                "../../tmp/librsvg-capture",
            )
            for (rel in candidates) {
                val f = File(rel, name)
                if (f.isFile) return f
            }
            error(
                "Could not locate turbulence capture '$name'.\n" +
                    "It must be either on the test classpath under $RESOURCE_PATH,\n" +
                    "or resolvable via KSVG_TURB_CAPTURE_DIR/<dir containing *.kernel.bin>."
            )
        }

        /** Materializes a committed capture resource (binary; handles file+jar URLs). */
        private fun resolveResource(name: String): File? {
            val path = "$RESOURCE_PATH/$name"
            val classLoader = TurbulenceCaptureLoader::class.java.classLoader ?: return null
            val url = classLoader.getResource(path) ?: return null
            if (url.protocol == "file") {
                return File(url.toURI()).takeIf { it.isFile }
            }
            // Nested in a jar during execution: copy out to a temp file.
            val tmp = File.createTempFile("ksvgturb-", ".kernel.bin")
            tmp.deleteOnExit()
            url.openStream().use { input -> tmp.outputStream().use { input.copyTo(it) } }
            return tmp
        }

        fun load(name: String): TurbulenceCaptureLoader {
            val bytes = resolveCaptureFile(name).readBytes()
            val buf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
            val magic = ByteArray(8)
            buf.get(magic)
            require(String(magic) == MAGIC) { "bad magic: ${String(magic)}" }
            require(buf.int == 1) { "bad capture version" }

            val canvasWidth = buf.int
            val canvasHeight = buf.int
            val x0 = buf.int
            val y0 = buf.int
            val x1 = buf.int
            val y1 = buf.int
            val seed = buf.int
            val baseFreqX = buf.double
            val baseFreqY = buf.double
            val numOctaves = buf.int
            val noiseType = buf.get().toInt()
            val stitch = buf.get().toInt() != 0
            buf.short // pad
            val tileWidth = buf.double
            val tileHeight = buf.double
            val affine = DoubleArray(6) { buf.double }

            val gradient = DoubleArray(4 * LATTICE_SIZE * 2) { buf.double }
            val latticeSelector = IntArray(LATTICE_SIZE) { buf.int }

            val recordHeaderBytes = 6 * 8 + 4 + 4
            val octaveBytes = 2 * 8 + 2 * 4 + 2 * 8 + 2 * 8
            val recordBytes = recordHeaderBytes + octaveBytes * numOctaves
            require(buf.remaining() % recordBytes == 0) {
                "dump size does not align: remaining=${buf.remaining()} recordBytes=$recordBytes"
            }
            val recordCount = buf.remaining() / recordBytes
            val expected = 4 * (x1 - x0) * (y1 - y0)
            require(recordCount == expected) {
                "record count $recordCount != expected $expected (${4}x${x1 - x0}x${y1 - y0})"
            }

            val records = ArrayList<TurbulenceRecord>(recordCount)
            repeat(recordCount) {
                val pointX = buf.double
                val pointY = buf.double
                val tileX = buf.double
                val tileY = buf.double
                val baseFx = buf.double
                val baseFy = buf.double
                val colorChannel = buf.int
                val recOctaves = buf.int
                require(recOctaves == numOctaves) {
                    "record octave count $recOctaves != header $numOctaves"
                }
                val octavesArr = Array(recOctaves) {
                    TurbulenceRecord.Octave(
                        vecX = buf.double,
                        vecY = buf.double,
                        stW = buf.int,
                        stH = buf.int,
                        wrapX = buf.long,
                        wrapY = buf.long,
                        noise = buf.double,
                        sum = buf.double,
                    )
                }
                records.add(
                    TurbulenceRecord(
                        pointX = pointX,
                        pointY = pointY,
                        tileX = tileX,
                        tileY = tileY,
                        baseFx = baseFx,
                        baseFy = baseFy,
                        colorChannel = colorChannel,
                        octaves = octavesArr,
                    )
                )
            }

            return TurbulenceCaptureLoader(
                canvasWidth, canvasHeight, x0, y0, x1, y1,
                seed, baseFreqX, baseFreqY, numOctaves, noiseType, stitch,
                tileWidth, tileHeight, affine, gradient, latticeSelector, records,
            )
        }
    }
}

internal class TurbulenceRecord(
    val pointX: Double,
    val pointY: Double,
    val tileX: Double,
    val tileY: Double,
    val baseFx: Double,
    val baseFy: Double,
    val colorChannel: Int,
    val octaves: Array<TurbulenceRecord.Octave>,
) {
    /** Per-octave captured kernel state, mirroring librsvg's `turbulence()` loop. */
    class Octave(
        val vecX: Double,
        val vecY: Double,
        val stW: Int,
        val stH: Int,
        val wrapX: Long,
        val wrapY: Long,
        val noise: Double,
        val sum: Double,
    )
}