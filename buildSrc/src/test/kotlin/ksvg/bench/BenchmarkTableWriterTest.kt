package ksvg.bench

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BenchmarkTableWriterTest {

    private val headers = listOf(
        "Kernel",
        "Backend",
        "Size",
        "MinMs",
        "MedianMs",
        "MeanMs",
        "MaxMs",
        "P90",
        "P95",
        "P99",
        "StdDevMs",
        "MPix/s",
        "GB/s",
        "InvalidatedBatches",
        "CooldownMs",
        "Classification",
        "VALID",
    )

    private fun row(kernel: String, backend: String, size: String, medianMs: String, classification: String = "VALID"): BenchRow =
        BenchRow(
            headers,
            listOf(
                kernel,
                backend,
                size,
                medianMs,
                medianMs,
                medianMs,
                medianMs,
                "",
                "",
                "",
                "",
                "100.0",
                "1.0",
                "0",
                "0",
                classification,
                "true",
            ),
        )

    @Test
    fun parsesQuotedCommas() {
        val line = "\"ConvolveMatrix (duplicate, alpha)\",sse2,512x512,4.381,59.84,0.48"
        val parsed = parseCsvLine(line)
        assertEquals(6, parsed.size)
        assertEquals("ConvolveMatrix (duplicate, alpha)", parsed[0])
        assertEquals("sse2", parsed[1])
        assertEquals("4.381", parsed[3])
    }

    @Test
    fun ranksBackendsInIsaOrder() {
        val order = listOf("kotlin", "scalar", "sse2", "ssse3", "avx2", "avx512", "neon32", "neon64")
        for ((i, b) in order.withIndex()) {
            assertEquals(i, BenchmarkTableWriter.backendRank(b))
        }
        assertEquals(999, BenchmarkTableWriter.backendRank("powerpc"))
    }

    @Test
    fun sortsRowsByKernelThenSizeThenBackend() {
        val table = BenchmarkTableWriter.deviceFlatTable(
            listOf(
                toCsv(
                    row("Lighting", "avx2", "2048x2048", "10.0"),
                    row("Lighting", "scalar", "512x512", "10.0"),
                    row("GaussianBlur", "sse2", "512x512", "10.0"),
                    row("GaussianBlur", "scalar", "512x512", "10.0"),
                ),
            ),
        )
        val body = table.lines().filter { it.startsWith("| ") }.drop(2)
        assertEquals(4, body.size)
        assertTrue(body[0].startsWith("| GaussianBlur | scalar | 512x512"))
        assertTrue(body[1].startsWith("| GaussianBlur | sse2 | 512x512"))
        assertTrue(body[2].startsWith("| Lighting | scalar | 512x512"))
        assertTrue(body[3].startsWith("| Lighting | avx2 | 2048x2048"))
    }

    @Test
    fun marksUnstableClassification() {
        val table = BenchmarkTableWriter.deviceFlatTable(
            listOf(
                toCsv(
                    row("Lighting", "scalar", "512x512", "10.0"),
                    row("Lighting", "avx2", "512x512", "5.0", classification = "NOISY"),
                ),
            ),
        )
        val avxLine = table.lines().first { it.contains("| avx2 |") }
        assertTrue(avxLine.endsWith("|  |\n") || avxLine.endsWith("| |\n") || "⚠️ UNSTABLE" in avxLine)
        assertTrue("⚠️ UNSTABLE" in avxLine)
    }

    @Test
    fun deviceSpeedupStatusIcons() {
        val table = BenchmarkTableWriter.deviceFlatTable(
            listOf(
                toCsv(
                    row("K", "kotlin", "512x512", "2.0"),
                    row("K", "scalar", "512x512", "10.0"),
                    row("K", "sse2", "512x512", "1.0"),
                    row("K", "avx2", "512x512", "12.0"),
                    row("K", "avx512", "512x512", "8.0"),
                ),
            ),
        )
        val lines = table.lines().filter { it.startsWith("| ") }.drop(2)
        assertTrue("kotlin 2ms vs scalar 10ms should show ⬆️", lines[0].contains("⬆️"))
        assertTrue("scalar should have empty status", lines[1].contains("|  |  |"))
        assertTrue("10x should be 🚀 + bold", lines[2].contains("🚀") && lines[2].contains("**10.00x**"))
        assertTrue("0.83x should be 🔴", lines[3].contains("🔴"))
        assertTrue("1.25x should be 🟢", lines[4].contains("🟢"))
    }

    private fun toCsv(vararg rows: BenchRow): java.io.File {
        val f = java.io.File.createTempFile("bench-", ".csv")
        f.writeText(
            buildString {
                append(headers.joinToString(",")).append("\n")
                for (r in rows) {
                    append(r.values.joinToString(",")).append("\n")
                }
            },
        )
        return f
    }
}