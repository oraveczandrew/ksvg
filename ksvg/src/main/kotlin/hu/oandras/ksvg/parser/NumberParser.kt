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
 * Parse an SVG 'number' or a CSS 'number' from a String.
 * 
 * We use our own parser because the one in Android (from Harmony, I think) is slow.
 * 
 * An SVG 'number' is defined as
 * integer (\[Ee] integer)?
 * | [+-]? [0-9]* "." [0-9]+ (\[Ee] integer)?
 * Where is 'integer'
 * [+-]? [0-9]+
 * CSS numbers were different, but have now been updated to a compatible definition (see 2.1 Errata)
 * [+-]?([0-9]+|[0-9]*\.[0-9]+)(e[+-]?[0-9]+)?
 * 
 */

/**
 * A parsed number and the position where parsing stopped, packed into a single
 * [Long] so number parsing never allocates a holder object: the value bits go
 * in the low 32 bits (the first thing callers need), the end position in the
 * high 32 bits. A failed parse packs end position -1.
 */
@Suppress("NOTHING_TO_INLINE")
@JvmInline
internal value class NumberParserResult(val packed: Long) {
    constructor(value: Float, endPos: Int) : this(
        (endPos.toLong() shl 32) or (value.toRawBits().toLong() and 0xFFFFFFFFL)
    )

    inline val value: Float
        get() = Float.fromBits(packed.toInt())

    inline val endPos: Int
        get() = (packed shr 32).toInt()

    inline fun isInvalid(): Boolean = endPos == -1

    companion object {
        /** Failure sentinel: end position -1, value meaningless. */
        val INVALID = NumberParserResult(Float.NaN, -1)
    }
}

internal object NumberParser {

    fun parseNumber(input: String, startPos: Int, len: Int): Float {
        return parseNumberPacked(input = input, startPos = startPos, len = len).value
    }

    /*
     * Scan the string for an SVG number.
     * Assumes maxPos will not be greater than str.length().
     */
    fun parseNumberPacked(input: String, startPos: Int, len: Int): NumberParserResult {
        var isNegative = false
        var significand: Long = 0
        var numDigits = 0
        var numLeadingZeroes = 0
        var numTrailingZeroes = 0
        var decimalSeen = false
        var decimalPos = 0

        var endPos = startPos

        if (endPos >= len) {
            return NumberParserResult.INVALID // String is empty - no number found
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
                            return NumberParserResult.INVALID
                        }
                        significand *= 10
                        numTrailingZeroes--
                    }

                    if (significand > TOO_BIG_L) {
                        // We will overflow if we continue...
                        return NumberParserResult.INVALID
                    }
                    significand = significand * 10 + d
                    numDigits++

                    if (significand < 0) {
                        return NumberParserResult.INVALID // overflowed from +ve to -ve
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
            // No digits following decimal point (e.g., "1.")
            //Log.e("Missing fraction part of number");
            return NumberParserResult.INVALID
        }

        // Have we seen anything number-ish at all so far?
        if (numDigits == 0) {
            if (numLeadingZeroes == 0) {
                //Log.e("Number not found");
                return NumberParserResult.INVALID
            }
            // Leading zeroes have been seen, though, so we
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
                    return NumberParserResult.INVALID
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
                                return NumberParserResult.INVALID
                            }
                            expVal = expVal * 10 + d
                            endPos++
                        } else break
                    }

                    // Check that at least some exponent digits were read
                    if (endPos == expStart) {
                        return NumberParserResult.INVALID
                    }

                    if (expIsNegative) exponent -= expVal
                    else exponent += expVal
                }
            }
        }

        // Quick check to eliminate huge exponents.
        // The biggest float is (2 - 2^23). 2^127 ~== 3.4e38
        // Biggest negative float is 2^-149 ~== 1.4e-45
        // Some numbers that will overflow will get through the scan
        // and be returned as 'valid', yet fail when value() is called.
        // However, they will be very rare and not worth slowing down
        // the parse for.
        if ((exponent + numDigits) > 39 || (exponent + numDigits) < -44) {
            return NumberParserResult.INVALID
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

        return NumberParserResult(if (isNegative) -f else f, endPos)
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
