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
package hu.oandras.androidsvg.parser

/**
 * Parse an SVG/CSS 'integer' or hex number from a String.
 * 
 * We use our own parser to gain a bit of speed.  This routine is
 * around twice as fast as the system one.
 */
internal object IntegerParser {

    class Result(
        val value: Int,
        /*
         * Return the value of pos after the parse.
         */
        val endPos: Int
    )

    /*
    * Scan the string for an SVG integer.
    * Assumes maxPos will not be greater than input.length().
    */
    @JvmStatic
    fun parseInt(input: String, startPos: Int, len: Int, includeSign: Boolean): Result? {
        var pos = startPos
        var isNegative = false
        var value = 0L
        var ch: Char

        if (pos >= len) return null // String is empty - no number found


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
                    if (value < Int.MIN_VALUE) return null
                } else {
                    value = value * 10L + d
                    if (value > Int.MAX_VALUE) return null
                }
            } else break
            pos++
        }

        // Have we seen anything number-ish at all so far?
        if (pos == sigStart) {
            return null
        }

        return Result(value.toInt(), pos)
    }

    /*
    * Scan the string for an SVG hex integer.
    * Assumes maxPos will not be greater than input.length().
    */
    @JvmStatic
    fun parseHex(input: String, startPos: Int, len: Int): Result? {
        if (startPos >= len) return null // String is empty - no number found

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

            if (value > 0xffffffffL) return null

            pos++
        }

        // Have we seen anything number-ish at all so far?
        if (pos == startPos) {
            return null
        }

        return Result(value.toInt(), pos)
    }
}
