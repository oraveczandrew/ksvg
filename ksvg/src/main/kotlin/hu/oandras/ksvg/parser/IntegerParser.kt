/*
 *    Copyright 2013-2020 Paul LeBeau, Cave Rock Software Ltd.
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
package hu.oandras.ksvg.parser

/**
 * Parse an SVG/CSS 'integer' or hex number from a String.
 * 
 * We use our own parser to gain a bit of speed.  This routine is
 * around twice as fast as the system one.
 */
/**
 * A parsed integer and the position where parsing stopped, packed into a single
 * [Long] so integer parsing never allocates a holder object: the value lives in
 * the low 32 bits (the first thing callers need), the end position in the high
 * 32 bits. A failed parse packs end position -1; the value is meaningless then
 * and must not be read.
 */
@Suppress("NOTHING_TO_INLINE")
@JvmInline
internal value class IntegerParserResult(val packed: Long) {
    constructor(value: Int, endPos: Int) : this(
        (endPos.toLong() shl 32) or (value.toLong() and 0xFFFFFFFFL)
    )

    inline val value: Int
        get() = packed.toInt()

    inline val endPos: Int
        get() = (packed shr 32).toInt()

    inline fun isInvalid(): Boolean = endPos == -1

    companion object {
        /** Failure sentinel: end position -1, value meaningless. */
        val INVALID = IntegerParserResult(0, -1)
    }
}

internal object IntegerParser {

    /*
    * Scan the string for an SVG integer.
    * Assumes maxPos will not be greater than input.length().
    */
    @JvmStatic
    fun parseInt(input: String, startPos: Int, len: Int, includeSign: Boolean): IntegerParserResult {
        var pos = startPos
        var isNegative = false
        var value = 0L
        var ch: Char

        if (pos >= len) return IntegerParserResult.INVALID // String is empty - no number found

        if (includeSign) {
            ch = input[pos]
            when (ch) {
                '-' -> {
                    isNegative = true
                    pos++
                }

                '+' -> pos++
            }
        }
        val sigStart = pos

        while (pos < len) {
            ch = input[pos]
            val d = ch - '0'
            if (d in 0..9) {
                if (isNegative) {
                    value = value * 10L - d
                    if (value < Int.MIN_VALUE) return IntegerParserResult.INVALID
                } else {
                    value = value * 10L + d
                    if (value > Int.MAX_VALUE) return IntegerParserResult.INVALID
                }
            } else break
            pos++
        }

        // Have we seen anything number-ish at all so far?
        if (pos == sigStart) {
            return IntegerParserResult.INVALID
        }

        return IntegerParserResult(value.toInt(), pos)
    }

    /*
    * Scan the string for an SVG hex integer.
    * Assumes maxPos will not be greater than input.length().
    */
    @JvmStatic
    fun parseHex(input: String, startPos: Int, len: Int): IntegerParserResult {
        if (startPos >= len) return IntegerParserResult.INVALID // String is empty - no number found

        var pos = startPos
        var value: Long = 0
        var ch: Char

        while (pos < len) {
            ch = input[pos]
            val d = ch - '0'
            value = if (d in 0..9) {
                value * 16L + d
            } else {
                val hexD = ch.code or 0x20
                if (hexD in 'a'.code..'f'.code) {
                    value * 16L + (hexD - 'a'.code) + 10L
                } else break
            }

            if (value > 0xffffffffL) return IntegerParserResult.INVALID

            pos++
        }

        // Have we seen anything number-ish at all so far?
        if (pos == startPos) {
            return IntegerParserResult.INVALID
        }

        return IntegerParserResult(value.toInt(), pos)
    }
}
