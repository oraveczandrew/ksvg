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
 * Parse an SVG 'number' or a CSS 'number' from a String.
 * 
 * We use our own parser because the one in Android (from Harmony I think) is slow.
 * 
 * An SVG 'number' is defined as
 * integer ([Ee] integer)?
 * | [+-]? [0-9]* "." [0-9]+ ([Ee] integer)?
 * Where 'integer' is
 * [+-]? [0-9]+
 * CSS numbers were different, but have now been updated to a compatible definition (see 2.1 Errata)
 * [+-]?([0-9]+|[0-9]*\.[0-9]+)(e[+-]?[0-9]+)?
 * 
 */
internal object NumberParser {

    class EndPosRef(
        @JvmField
        var endPos: Int,
    )

    fun parseNumber(input: String, startPos: Int, len: Int): Float {
        return parseNumber(input = input, startPos = startPos, len = len, endPosRefOut = null)
    }

    /*
     * Scan the string for an SVG number.
     * Assumes maxPos will not be greater than str.length().
     */
    fun parseNumber(input: String, startPos: Int, len: Int, endPosRefOut: EndPosRef?): Float {
        var isNegative = false
        var significand: Long = 0
        var numDigits = 0
        var numLeadingZeroes = 0
        var numTrailingZeroes = 0
        var decimalSeen = false
        var decimalPos = 0

        var endPos = startPos

        if (endPos >= len) {
            endPosRefOut?.endPos = endPos
            return Float.NaN // String is empty - no number found
        }


        var ch = input[endPos]
        when (ch) {
            '-' -> {
                isNegative = true
                endPos++
            }

            '+' -> endPos++
        }

        val sigStart: Int = endPos

        while (endPos < len) {
            ch = input[endPos]
            val d = ch - '0'
            if (d in 0..9) {
                if (d == 0) {
                    if (numDigits == 0) {
                        numLeadingZeroes++
                    } else {
                        // We potentially skip trailing zeroes. Keep count for now.
                        numTrailingZeroes++
                    }
                } else {
                    // Multiply any skipped zeroes into buffer
                    numDigits += numTrailingZeroes
                    while (numTrailingZeroes > 0) {
                        if (significand > TOO_BIG_L) {
                            endPosRefOut?.endPos = endPos
                            return Float.NaN
                        }
                        significand *= 10
                        numTrailingZeroes--
                    }

                    if (significand > TOO_BIG_L) {
                        // We will overflow if we continue...
                        endPosRefOut?.endPos = endPos
                        return Float.NaN
                    }
                    significand = significand * 10 + d
                    numDigits++

                    if (significand < 0) {
                        endPosRefOut?.endPos = endPos
                        return Float.NaN // overflowed from +ve to -ve
                    }
                }
            } else if (ch == '.') {
                if (decimalSeen) {
                    // Stop parsing here.  We may be looking at a new number.
                    break
                }
                decimalPos = endPos - sigStart
                decimalSeen = true
            } else break
            endPos++
        }

        if (decimalSeen && endPos == (decimalPos + 1)) {
            // No digits following decimal point (e.g. "1.")
            //Log.e("Missing fraction part of number");
            endPosRefOut?.endPos = endPos
            return Float.NaN
        }

        // Have we seen anything number-ish at all so far?
        if (numDigits == 0) {
            if (numLeadingZeroes == 0) {
                //Log.e("Number not found");
                endPosRefOut?.endPos = endPos
                return Float.NaN
            }
            // Leading zeroes have been seen though, so we
            // treat that as a '0'.
            numDigits = 1
        }

        var exponent: Int = if (decimalSeen) {
            decimalPos - numLeadingZeroes - numDigits
        } else {
            numTrailingZeroes
        }

        // Now look for exponent
        if (endPos < len) {
            ch = input[endPos]
            if (ch == 'E' || ch == 'e') {
                var expIsNegative = false
                var expVal = 0
                var abortExponent = false

                endPos++
                if (endPos == len) {
                    endPosRefOut?.endPos = endPos
                    return Float.NaN
                }

                when (input[endPos]) {
                    '-' -> {
                        expIsNegative = true
                        endPos++
                    }
                    '+' -> endPos++
                    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' -> {}
                    else -> {
                        abortExponent = true
                        endPos-- // reset pos to position of 'E'/'e'
                    }
                }

                if (!abortExponent) {
                    val expStart = endPos

                    while (endPos < len) {
                        val d = input[endPos] - '0'
                        if (d in 0..9) {
                            if (expVal > TOO_BIG_I) {
                                endPosRefOut?.endPos = endPos
                                return Float.NaN
                            }
                            expVal = expVal * 10 + d
                            endPos++
                        } else break
                    }

                    // Check that at least some exponent digits were read
                    if (endPos == expStart) {
                        endPosRefOut?.endPos = endPos
                        return Float.NaN
                    }

                    if (expIsNegative) exponent -= expVal
                    else exponent += expVal
                }
            }
        }

        // Quick check to eliminate huge exponents.
        // Biggest float is (2 - 2^23) . 2^127 ~== 3.4e38
        // Biggest negative float is 2^-149 ~== 1.4e-45
        // Some numbers that will overflow will get through the scan
        // and be returned as 'valid', yet fail when value() is called.
        // However they will be very rare and not worth slowing down
        // the parse for.
        if ((exponent + numDigits) > 39 || (exponent + numDigits) < -44) {
            endPosRefOut?.endPos = endPos
            return Float.NaN
        }

        var f = significand.toFloat()

        if (significand != 0L) {
            if (exponent > 0) {
                f *= positivePowersOf10[exponent]
            } else if (exponent < 0) {
                if (exponent < -38) {
                    // Long.MAX_VALUE is 19 digits, so taking 20 off the exponent should be enough.
                    f *= 1e-20f
                    exponent += 20
                }
                f *= negativePowersOf10[-exponent]
            }
        }

        endPosRefOut?.endPos = endPos
        return if (isNegative) -f else f
    }

    private val positivePowersOf10: FloatArray = floatArrayOf(
        1e0f, 1e1f, 1e2f, 1e3f, 1e4f, 1e5f, 1e6f, 1e7f, 1e8f, 1e9f,
        1e10f, 1e11f, 1e12f, 1e13f, 1e14f, 1e15f, 1e16f, 1e17f, 1e18f, 1e19f,
        1e20f, 1e21f, 1e22f, 1e23f, 1e24f, 1e25f, 1e26f, 1e27f, 1e28f, 1e29f,
        1e30f, 1e31f, 1e32f, 1e33f, 1e34f, 1e35f, 1e36f, 1e37f, 1e38f
    )

    private val negativePowersOf10: FloatArray = floatArrayOf(
        1e0f, 1e-1f, 1e-2f, 1e-3f, 1e-4f, 1e-5f, 1e-6f, 1e-7f, 1e-8f, 1e-9f,
        1e-10f, 1e-11f, 1e-12f, 1e-13f, 1e-14f, 1e-15f, 1e-16f, 1e-17f, 1e-18f, 1e-19f,
        1e-20f, 1e-21f, 1e-22f, 1e-23f, 1e-24f, 1e-25f, 1e-26f, 1e-27f, 1e-28f, 1e-29f,
        1e-30f, 1e-31f, 1e-32f, 1e-33f, 1e-34f, 1e-35f, 1e-36f, 1e-37f, 1e-38f
    )

    private const val TOO_BIG_L: Long = Long.MAX_VALUE / 10
    private const val TOO_BIG_I: Int = Int.MAX_VALUE / 10
}
