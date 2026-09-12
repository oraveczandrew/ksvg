package ksvg.bench

import java.io.File
import java.util.Locale

data class BenchRow(val header: List<String>, val values: List<String>)

/**
 * Minimal RFC-4180-ish CSV line parser. Handles quoted fields (kernel names such
 * as "ConvolveMatrix (duplicate, alpha)" contain commas) and trims whitespace.
 */
fun parseCsvLine(line: String): List<String> {
    val result = mutableListOf<String>()
    val sb = StringBuilder()
    var inQuotes = false
    for (ch in line) {
        when {
            ch == '"' -> inQuotes = !inQuotes
            ch == ',' && !inQuotes -> {
                result.add(sb.toString().trim())
                sb.clear()
            }
            else -> sb.append(ch)
        }
    }
    result.add(sb.toString().trim())
    return result
}

/** Reads every data row of a benchmark CSV (skips blank lines). */
fun readBenchmarkRows(file: File): List<BenchRow> {
    val rows = mutableListOf<BenchRow>()
    file.bufferedReader().use {
        val lines = it.lineSequence().mapNotNull { line ->
            line.trim().ifEmpty { null }
        }

        val linesIterator = lines.iterator()
        if (!linesIterator.hasNext()) return rows
        val header = parseCsvLine(linesIterator.next())
        for (line in linesIterator) {
            rows.add(BenchRow(header, parseCsvLine(line)))
        }
    }
    return rows
}

/**
 * Builds the single flat BENCHMARKS.md-style table for the pull-and-print path:
 * kernels alphabetical, sizes ascending, backends in ISA superset order, speedup
 * relative to the (Kernel, Size) group's scalar median, status icons
 * (kotlin faster than scalar -> ⬆️; >9x -> 🚀 bold; >1x -> 🟢; <1x -> 🔴) and a
 * "⚠️ UNSTABLE" note when Classification is missing or != VALID.
 *
 * Safe to call from a Gradle task action: reads only the given [csvFiles] and
 * returns a plain [String], holding no state that would break the configuration cache.
 */
object BenchmarkTableWriter {

    val isaOrder = listOf("kotlin", "scalar", "sse2", "ssse3", "avx2", "avx512", "neon32", "neon64")

    fun backendRank(backend: String): Int {
        val lower = backend.lowercase()
        val idx = isaOrder.indexOfFirst { lower.contains(it) }
        return if (idx >= 0) idx else 999
    }

    fun sizeRank(size: String): Int {
        val parts = size.lowercase().split("x")
        val w = parts.getOrNull(0)?.toIntOrNull() ?: Int.MAX_VALUE
        val h = parts.getOrNull(1)?.toIntOrNull() ?: Int.MAX_VALUE
        return if (w == Int.MAX_VALUE || h == Int.MAX_VALUE) Int.MAX_VALUE else w * h
    }

    fun deviceFlatTable(csvFiles: List<File>): String {
        val rows = mutableListOf<BenchRow>()
        for (reportFile in csvFiles) {
            rows.addAll(readBenchmarkRows(reportFile))
        }
        if (rows.isEmpty()) return ""

        val firstHeader = rows.first().header
        val kernelIdx = firstHeader.indexOf("Kernel")
        val backendIdx = firstHeader.indexOf("Backend")
        val sizeIdx = firstHeader.indexOf("Size")
        val medianIdx = firstHeader.indexOf("MedianMs")
        val mpixIdx = firstHeader.indexOf("MPix/s")
        val gbsIdx = firstHeader.indexOf("GB/s")
        val classIdx = firstHeader.indexOf("Classification")

        val scalarMedian = mutableMapOf<List<String>, Double>()
        for (row in rows) {
            if (row.values.getOrNull(backendIdx).equals("scalar", ignoreCase = true)) {
                scalarMedian.putIfAbsent(
                    listOf(row.values[kernelIdx], row.values[sizeIdx]),
                    row.values.getOrNull(medianIdx)?.toDoubleOrNull() ?: 0.0,
                )
            }
        }

        val sorted = rows.sortedWith(
            compareBy<BenchRow>(
                { it.values[kernelIdx] },
                { sizeRank(it.values[sizeIdx]) },
                { backendRank(it.values[backendIdx]) },
            )
        )

        val sb = StringBuilder()
        sb.append("| Kernel | Backend | Size | ms | MPix/s | GB/s | Speedup | Status | Note |\n")
        sb.append("| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |\n")
        for (row in sorted) {
            val values = row.values
            val name = values.getOrNull(kernelIdx) ?: ""
            val b = values.getOrNull(backendIdx) ?: ""
            val size = values.getOrNull(sizeIdx) ?: ""
            val med = values.getOrNull(medianIdx)?.toDoubleOrNull() ?: 0.0
            val mpix = values.getOrNull(mpixIdx) ?: ""
            val gbs = values.getOrNull(gbsIdx) ?: ""
            val scalarMed = scalarMedian[listOf(name, size)]
            val sp = if (scalarMed != null && scalarMed > 0.0 && med > 0.0) scalarMed / med else null
            val spText = sp?.let { fmt2(it) + "x" } ?: ""
            val isKotlin = b.equals("kotlin", ignoreCase = true)
            val isScalar = b.equals("scalar", ignoreCase = true)
            var status = ""
            var bold = false
            if (sp != null) {
                when {
                    isScalar -> status = ""
                    isKotlin -> status = if (sp > 1.0) "⬆️" else ""
                    sp > 9.0 -> {
                        status = "🚀"
                        bold = true
                    }
                    sp > 1.0 -> status = "🟢"
                    sp < 1.0 -> status = "🔴"
                }
            }
            val spCell = if (bold) "**$spText**" else spText
            val classification = values.getOrNull(classIdx) ?: ""
            val note = if (classification.isNotBlank() && classification != "VALID") "⚠️ UNSTABLE" else ""
            sb.append("| $name | $b | $size | ${fmt2(med)} | $mpix | $gbs | $spCell | $status | $note |\n")
        }
        return sb.toString()
    }

    /**
     * Full BENCHMARKS.md export for `exportBenchmarkTable`: dispatches on the CSV
     * format (device format when a MedianMs column exists, host format otherwise).
     */
    fun markdownTable(rows: List<BenchRow>): String {
        if (rows.isEmpty()) return ""
        return if (rows.first().header.contains("MedianMs")) {
            groupedDeviceTable(rows)
        } else {
            hostTable(rows)
        }
    }

    /** Port of the old per-(kernel,size) grouped export for the device CSV format. */
    private fun groupedDeviceTable(rows: List<BenchRow>): String {
        val header = rows.first().header
        val kernelIdx = header.indexOf("Kernel")
        val sizeIdx = header.indexOf("Size")
        val backendIdx = header.indexOf("Backend")

        val outMd = StringBuilder()
        val groups = rows.groupBy { listOf(it.values[kernelIdx], it.values[sizeIdx]) }
        for ((key, group) in groups.entries.sortedBy { it.key.joinToString(" ") }) {
            val kernel = key[0]
            val size = key[1]
            outMd.append("### $kernel ($size)\n\n")

            val sorted = group.sortedBy { backendRank(it.values[backendIdx]) }

            outMd.append("| Backend | Median (ms) | Min (ms) | Max (ms) | Speedup (vs Scalar) | Speedup (vs Kotlin) | Status |\n")
            outMd.append("| :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n")

            val scalarMedian = sorted.firstOrNull { it.values[backendIdx].equals("scalar", ignoreCase = true) }
                ?.let { it.header.zip(it.values).toMap()["MedianMs"]?.toDoubleOrNull() }
            val kotlinMedian = sorted.firstOrNull { it.values[backendIdx].equals("kotlin", ignoreCase = true) }
                ?.let { it.header.zip(it.values).toMap()["MedianMs"]?.toDoubleOrNull() }

            for (row in sorted) {
                val map = row.header.zip(row.values).toMap()
                val b = map["Backend"] ?: ""
                val medStr = map["MedianMs"] ?: ""
                val minStr = map["MinMs"] ?: ""
                val maxStr = map["MaxMs"] ?: ""
                val med = medStr.toDoubleOrNull()

                val spScalar = map["SpeedupVsScalar"]?.takeIf { it.isNotEmpty() }
                    ?: if (med != null && scalarMedian != null && med > 0.0) {
                        String.format(Locale.US, "%.2fx", scalarMedian / med)
                    } else {
                        "—"
                    }

                val spKotlin = map["SpeedupVsKotlin"]?.takeIf { it.isNotEmpty() }
                    ?: if (med != null && kotlinMedian != null && med > 0.0) {
                        String.format(Locale.US, "%.2fx", kotlinMedian / med)
                    } else {
                        "—"
                    }

                val speedupNum = spScalar.removeSuffix("x").toDoubleOrNull() ?: 1.0

                val status = when {
                    b.equals("Kotlin", ignoreCase = true) -> "—"
                    b.equals("scalar", ignoreCase = true) -> "🟢 baseline"
                    speedupNum >= 2.0 -> "🚀 $spScalar"
                    speedupNum > 1.05 -> "🟢 $spScalar"
                    speedupNum < 0.95 -> "🔴 regression"
                    else -> "—"
                }

                outMd.append("| $b | $medStr | $minStr | $maxStr | $spScalar | $spKotlin | $status |\n")
            }
            outMd.append("\n")
        }
        return outMd.toString()
    }

    /** Port of the host-format branch: BENCHMARKS.md-style flat table using AvgMs/Speedup columns. */
    private fun hostTable(rows: List<BenchRow>): String {
        val header = rows.first().header
        val kernelIdx = header.indexOf("Kernel")
        val sizeIdx = header.indexOf("Size")
        val backendIdx = header.indexOf("Backend")

        val outMd = StringBuilder()
        outMd.append("| Kernel | Backend | Size | Avg ms | MPix/s | GB/s | Speedup | Status | Note |\n")
        outMd.append("| :--- | :--- | :---: | ---: | ---: | ---: | ---: | :---: | :--- |\n")

        val sorted = rows.sortedWith(
            compareBy<BenchRow>(
                { it.values[kernelIdx] },
                { sizeRank(it.values[sizeIdx]) },
                { backendRank(it.values[backendIdx]) },
            )
        )

        for (row in sorted) {
            val map = row.header.zip(row.values).toMap()
            val name = map["Kernel"] ?: ""
            val b = map["Backend"] ?: ""
            val size = map["Size"] ?: ""
            val avgMs = map["AvgMs"] ?: ""
            val mpix = map["MPix/s"] ?: ""
            val gbs = map["GB/s"] ?: ""
            val spRaw = map["Speedup"] ?: ""
            val spNum = spRaw.removeSuffix("x").toDoubleOrNull()
            val spText = if (spRaw.endsWith("x")) spRaw else "${spRaw}x"

            val isKotlin = b.equals("kotlin", ignoreCase = true)
            val isScalar = b.equals("scalar", ignoreCase = true)
            val status: String
            val bold: Boolean
            when {
                isScalar -> {
                    status = ""
                    bold = false
                }
                isKotlin -> {
                    bold = false
                    status = if (spNum != null && spNum > 1.0) "⬆️" else ""
                }
                else -> {
                    val rocket = spNum != null && spNum > 9.0
                    bold = rocket
                    status = when {
                        rocket -> "🚀"
                        spNum != null && spNum > 1.0 -> "🟢"
                        spNum != null && spNum < 1.0 -> "🔴"
                        else -> ""
                    }
                }
            }
            val spCell = if (bold) "**${spText}**" else spText
            outMd.append("| $name | $b | $size | $avgMs | $mpix | $gbs | $spCell | $status |  |\n")
        }
        outMd.append("\n")
        return outMd.toString()
    }

    private fun fmt2(v: Double): String = String.format(Locale.US, "%.2f", v)
}