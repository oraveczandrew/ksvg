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

/*
 * Copyright 2010-2024 JetBrains s.r.o. and Kotlin Programming Language contributors.
 * Use of this source code is governed by the Apache 2.0 license that can be found in the license/LICENSE.txt file.
 */

@file:Suppress("NOTHING_TO_INLINE")

package hu.oandras.ksvg.utils

import java.util.*
import java.util.regex.Pattern

internal fun String.charCount(c: Char): Int {
    var count = 0
    for (i in indices) {
        if (this[i] == c) count++
    }
    return count
}

internal fun String.removeDoubleSpaces(): String {
    // Regex-free `\\s{2,} -> " "`: collapsing runs of Java whitespace
    // (space, tab, LF, VT, FF, CR) to one space. Fast path returns `this`
    // when there is nothing to collapse (no allocation at all).
    var i = 0
    while (i < length && !isDoubleWhitespaceAt(i)) i++
    if (i >= length) return this
    val out = StringBuilder(length)
    out.append(this, 0, i)
    while (i < length) {
        if (isRegexWhitespace(this[i])) {
            out.append(' ')
            do {
                i++
            } while (i < length && isRegexWhitespace(this[i]))
        } else {
            out.append(this[i])
            i++
        }
    }
    return out.toString()
}

private inline fun String.isDoubleWhitespaceAt(i: Int): Boolean {
    return i + 1 < length && isRegexWhitespace(this[i]) && isRegexWhitespace(this[i + 1])
}

private inline fun isRegexWhitespace(c: Char): Boolean {
    return c == ' ' || c == '\t' || c == '\n' || c == '\u000B' || c == '\u000C' || c == '\r'
}

internal fun textXMLSpaceTransform(
    text: String,
    isFirstChild: Boolean,
    isLastChild: Boolean,
    spacePreserve: Boolean,
): String {
    if (spacePreserve) {
        // Preserve mode (xml:space="preserve" or white-space: pre/...):
        // keep spaces/tabs verbatim, but fold line breaks to spaces.
        // Chrome parity (measured): no engine breaks SVG <text> on newlines,
        // Chrome collapses them even under white-space: pre.
        return text.replace("\r\n", " ").replace('\n', ' ').replace('\r', ' ')
    }

    // xml:space = "default": per SVG/CSS text whitespace handling, newlines and tabs
    // are converted to spaces (not deleted), leading/trailing spaces are trimmed, and
    // runs of spaces are collapsed to a single space.
    val withSpaces = text.replace('\n', ' ').replace('\t', ' ').replace('\r', ' ')

    val trimmed = withSpaces
        .let { if (isFirstChild) it.trimStart { c -> c.isSpaceLike() } else it }
        .let { if (isLastChild) it.trimEnd { c -> c.isSpaceLike() } else it }

    return trimmed.removeDoubleSpaces()
}

internal fun String.trimLowerThanSpace(): String {
    // Own two-pointer trim: leading/trailing chars <= ' ' go, nothing else is
    // touched, and an already-clean string returns `this` (no substring copy,
    // which is the common case on scanner/attribute reads).
    var start = 0
    var end = length
    while (start < end && this[start] <= ' ') start++
    while (end > start && this[end - 1] <= ' ') end--
    return if (start == 0 && end == length) {
        this
    } else {
        substring(start, end)
    }
}

/**
 * Start of the `[start, end)` window in [input] with leading chars `<= ' '`
 * excluded. Zero-allocation trim primitive for scanners; [input] is never sliced.
 */
internal fun skipLeading(input: String, start: Int, end: Int): Int {
    var i = start
    while (i < end && input[i] <= ' ') i++
    return i
}

/**
 * End of the `[start, end)` window in [input] with trailing chars `<= ' '`
 * excluded. Zero-allocation trim primitive for scanners; [input] is never sliced.
 */
internal fun skipTrailing(input: String, start: Int, end: Int): Int {
    var e = end
    while (e > start && input[e - 1] <= ' ') e--
    return e
}

internal fun skipLeading(input: String): Int = skipLeading(input, 0, input.length)

internal fun skipTrailing(input: String, start: Int): Int = skipTrailing(input, start, input.length)

/**
 * Exact match of the `[start, end)` window against [word]. The length check
 * comes first, so a window that merely starts with [word] (or ends early)
 * never matches; the rest is a single `regionMatches` — no lowercase or
 * substring copy on either outcome.
 */
internal fun String.equalsWindow(start: Int, end: Int, word: String, ignoreCase: Boolean): Boolean =
    end - start == word.length && regionMatches(start, word, 0, word.length, ignoreCase)

@Suppress("UNNECESSARY_NOT_NULL_ASSERTION")
internal fun String.toPattern(): Pattern {
    return Pattern.compile(this)!!
}

internal fun String.capitalizeStr(locale: Locale): String {
    if (isEmpty()) return this
    // Single pass over the raw string: no split list, no per-word strings,
    // no transform lambdas. Mirrors split(" ")/join(" ") semantics exactly
    // (consecutive spaces preserved, only word-initial lowercase chars
    // titlecased, word bodies are untouched).
    val out = StringBuilder(length)
    var wordStart = true
    for (c in this) {
        if (c == ' ') {
            wordStart = true
            out.append(c)
        } else if (wordStart) {
            out.append(if (c.isLowerCase()) c.titlecase(locale) else c.toString())
            wordStart = false
        } else {
            out.append(c)
        }
    }
    return out.toString()
}

/**
 * Parses this string as an [Int], returning [default] when it is not a valid
 * representation. The [isValidInt] screen runs first, so malformed input
 * never pays for a [NumberFormatException] (only overflow still throws, and
 * is caught); the happy path allocates nothing.
 */
internal inline fun String.parseIntOrDefault(default: Int): Int {
    return try {
        if (isValidInt(this))
            toInt()
        else
            default
    } catch (_: NumberFormatException) {
        default
    }
}

internal fun isValidInt(s: String): Boolean {
    if (s.isEmpty()) return false
    var i = 0
    if (s[0] == '-' || s[0] == '+') {
        if (s.length == 1) return false
        i = 1
    }
    while (i < s.length) {
        if (s[i] < '0' || s[i] > '9') return false
        i++
    }
    return true
}

/**
 * Splits on separator runs without [Regex]: single pass, no [trim], empty
 * tokens never emitted. Replacement for
 * `trim().split(Regex(...)).filter { it.isNotEmpty() }`, which paid for a
 * trim copy, a regex match, and a second filtered list.
 */
internal inline fun String.splitBy(isSeparator: (Char) -> Boolean): List<String> {
    val out = ArrayList<String>(4)
    var i = 0
    while (i < length) {
        while (i < length && isSeparator(this[i])) i++
        if (i >= length) break
        val start = i
        while (i < length && !isSeparator(this[i])) i++
        out.add(substring(start, i))
    }
    return out
}
/**
 * Parses this string as a [Float], returning [default] when it is not a valid
 * representation. The [isValidFloat] screen runs first, so malformed input
 * never pays for a [NumberFormatException] (only overflow still throws, and
 * is caught); the happy path allocates nothing.
 */
internal inline fun String.parseFloatOrDefault(default: Float): Float {
    return try {
        if (isValidFloat(this))
            toFloat()
        else
            default
    } catch (_: NumberFormatException) {
        default
    }
}

/**
 * Lambda-default twin of [parseFloatOrDefault] for early exits: the default
 * is only evaluated when parsing fails, and as this is inline, it may
 * non-local-return (e.g. `parseFloatOrElse { return null }`).
 */
internal inline fun String.parseFloatOrElse(default: () -> Float): Float {
    return try {
        if (isValidFloat(this))
            toFloat()
        else
            default()
    } catch (_: NumberFormatException) {
        default()
    }
}

internal fun isValidFloat(s: String): Boolean {
    // A float can have one of two representations:
    //
    // 1. Standard:
    //     - With an integer part only: 1234
    //     - With an integer part followed by the decimal point: 1234.
    //     - With integer and fractional parts: 1234.4678
    //     - With a fractional part only: .4678
    //
    //     Optional sign prefix: + or -
    //     Optional signed exponent: e or E, followed by optionally signed digits (+12, -12, 12)
    //     Optional suffix: f, F, d, or D (for instance, 12.34f or .34D)
    //
    // 2. Hexadecimal:
    //     - With an integer part only: 0x12ab
    //     - With an integer part followed by the decimal point: 0x12ab.
    //     - With integer and fractional parts: 0x12ab.CD78
    //     - With a fractional part only: 0x.CD78
    //
    //     Mandatory signed exponent: p or P, followed by optionally signed decimal digits (+12, -12, 12)
    //
    //     Optional sign prefix: + or -
    //     Optional suffix: f, F, d, or D (for instance 0xAB.01P1f or 0x.34P0D)
    //
    // Two special cases:
    //     "NaN" and "Infinity" strings can have an optional sign prefix (+ or -)
    //
    // Implementation notes:
    //     - The pattern "myChar.code or 0x20 == 'x'.code" is used to perform a case-insensitive
    //       comparison of a character. Adding the 0x20 bit turns an upper case ASCII letter into
    //       a lower case one. This is encapsulated in the asciiLetterToLowerCaseCode() extension

    var start = 0
    var endInclusive = s.length - 1

    // Skip leading spaces
    start = s.advanceWhile(start, endInclusive) { it.code <= 0x20 }

    // Empty/whitespace string
    if (start > endInclusive) return false

    // Skip trailing spaces
    endInclusive = s.backtrackWhile(start, endInclusive) { it.code <= 0x20 }

    // Number starts with a positive or negative sign
    if (s[start] == '+' || s[start] == '-') start++
    // If we have nothing after the sign, the string is invalid
    if (start > endInclusive) return false

    var isHex = false

    // Might be a hex string
    if (s[start] == '0') {
        start++
        // A "0" on its own is valid
        if (start > endInclusive) return true

        // Test for [xX] to see if we truly have a hex string
        if (s[start].asciiLetterToLowerCaseCode() == 'x'.code) {
            start++

            start = s.advanceAndValidateMantissa(start, endInclusive, true) { it.isAsciiDigit() || it.isHexLetter() }

            // A hex string must have an exponent, the string is invalid if we only found an
            // integer and/or fractional part
            if (start == -1 || start > endInclusive) return false

            isHex = true
        } else {
            // Rewind the 0 we just parsed to make things easier below and try to parse a non-
            // hexadecimal string representation of a float
            start--
        }
    }

    // Parse a non-hexadecimal representation
    if (!isHex) {
        start = s.advanceAndValidateMantissa(start, endInclusive, false) { it.isAsciiDigit() }

        // We couldn't validate the mantissa, stop here
        if (start == -1) return false

        // If we have validated the mantissa, we can stop here if we've run out of characters
        if (start > endInclusive) return true
    }

    // Look for an exponent:
    //     - Mandatory for hexadecimal strings (marked by a p or P)
    //     - Optional for "regular" strings (marked by an e or E)
    var l = s[start++].asciiLetterToLowerCaseCode()
    if (l != if (isHex) 'p'.code else 'e'.code) {
        // We're here if the exponent character is not valid, but if the string is a "regular"
        // string, it could be a valid f/F/d/D suffix, so check for that (it must be the last
        // character too)
        return !isHex && (l == 'f'.code || l == 'd'.code) && start > endInclusive
    }

    // Digits must follow an exponent
    if (start > endInclusive) return false

    // There may be a sign prefix before the exponent digits
    if (s[start] == '+' || s[start] == '-') {
        start++
        if (start > endInclusive) return false
    }

    // Look for digits after the exponent and its optional sign
    start = s.advanceWhile(start, endInclusive) { it.isAsciiDigit() }

    // The last suffix is optional, the string is valid here
    if (start > endInclusive) return true

    // We may have an optional fFdD suffix
    if (start == endInclusive) {
        l = s[start].asciiLetterToLowerCaseCode()
        return l == 'f'.code || l == 'd'.code
    }

    // Anything left is invalid
    return false
}

private inline fun String.advanceWhile(start: Int, endInclusive: Int, predicate: (Char) -> Boolean): Int {
    var start = start
    while (start <= endInclusive && predicate(this[start])) start++
    return start
}

private inline fun String.backtrackWhile(start: Int, endInclusive: Int, predicate: (Char) -> Boolean): Int {
    var endInclusive = endInclusive
    while (endInclusive > start && predicate(this[endInclusive])) endInclusive--
    return endInclusive
}

private inline fun Char.asciiLetterToLowerCaseCode(): Int = this.code or 0x20

/**
 * Advances until after the end of the mantissa, in the substring defined by the [start] and [endInclusive] indices.
 * If a valid mantissa cannot be found, this method returns -1.
 * If a valid mantissa is found, this method returns [endInclusive] + 1.
 */
private inline fun String.advanceAndValidateMantissa(start: Int, endInclusive: Int, hexFormat: Boolean, predicate: (Char) -> Boolean): Int {
    var start = start

    // Look for hex digits after the 0x prefix
    var checkpoint = start
    start = advanceWhile(start, endInclusive, predicate)

    // Check if we found the integer part of the number
    val hasIntegerPart = checkpoint != start

    // A hex string must have an exponent, the string is invalid if we only found an
    // integer part, but a non-hex string is valid if there's only an integer part
    if (start > endInclusive) return if (hexFormat) -1 else start

    var hasFractionalPart = false
    if (this[start] == '.') {
        start++

        // Look for hex digits for the fractional part
        checkpoint = start
        start = advanceWhile(start, endInclusive, predicate)

        // Did we find a fractional part?
        hasFractionalPart = checkpoint != start
    }

    // Both hex and non-hex strings must have an integer part, or a fractional part, or both
    if (!hasIntegerPart && !hasFractionalPart) {
        if (hexFormat) {
            return -1
        } else {
            // Check for non-finite constants
            val constant = guessNamedFloatConstant(start, endInclusive) ?: return -1

            // If the string contains exactly the constant we guessed, advance to after the constant
            return if (indexOf(constant, start, false) == start) endInclusive + 1 else -1
        }
    }

    return start
}

private inline fun Char.isAsciiDigit(): Boolean {
    // "and 0xFFFF" wraps negative values
    return (this - '0') and 0xFFFF < 10
}

private inline fun Char.isHexLetter(): Boolean {
    // "and 0xFFFF" wraps negative values
    return (asciiLetterToLowerCaseCode() - 'a'.code) and 0xFFFF < 6
}

private inline fun guessNamedFloatConstant(start: Int, endInclusive: Int): String? = when (endInclusive) {
    start + 3 - 1 -> { // "NaN".length == 3, - 1 because we used an inclusive end index
        "NaN"
    }
    start + 8 - 1 -> { // "Infinity".length == 8, - 1 because we used an inclusive end index
        "Infinity"
    }
    else -> {
        // We have too many or too few characters, there's no valid constant
        null
    }
}