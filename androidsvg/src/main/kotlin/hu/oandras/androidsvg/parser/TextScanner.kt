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

import hu.oandras.androidsvg.css.CSSLength
import hu.oandras.androidsvg.css.CssUnit
import hu.oandras.androidsvg.parser.IntegerParser.parseInt
import hu.oandras.androidsvg.utils.trimLowerThanSpace

internal const val INVALID_CHAR: Char = (-1).toChar()

internal open class TextScanner(input: String) {
    @JvmField
    protected val input: String = input.trimLowerThanSpace()

    @JvmField
    protected var position: Int = 0

    @JvmField
    protected var inputLength: Int = this.input.length

    private val tempEndPosRef = NumberParser.EndPosRef(0)

    /**
     * Returns true if we have reached the end of the input.
     */
    fun empty(): Boolean {
        return position == inputLength
    }

    fun isWhitespace(c: Char): Boolean = when (c) {
        ' ',
        '\n',
        '\r',
        '\t' -> true
        else -> false
    }

    fun skipWhitespace() {
        while (position < inputLength) {
            if (!isWhitespace(input[position])) break
            position++
        }
    }

    fun isEOL(c: Char): Boolean = c == '\n' || c == '\r'

    // Skip the sequence: <space>*(<comma><space>)?
    // Returns true if we found a comma in there.
    fun skipCommaWhitespace(): Boolean {
        skipWhitespace()
        if (position == inputLength) return false
        if (input[position] != ',') return false
        position++
        skipWhitespace()
        return true
    }


    fun nextFloat(): Float {
        val value = NumberParser.parseNumber(
            input = input,
            startPos = position,
            len = inputLength,
            endPosRefOut = tempEndPosRef
        )
        if (!value.isNaN()) position = tempEndPosRef.endPos
        return value
    }

    /*
    * Scans for a comma-whitespace sequence with a float following it.
    * If found, the float is returned. Otherwise, null is returned and
    * the scan position left as it was.
    */
    fun possibleNextFloat(): Float {
        skipCommaWhitespace()
        val value = NumberParser.parseNumber(
            input = input,
            startPos = position,
            len = inputLength,
            endPosRefOut = tempEndPosRef
        )
        if (!value.isNaN()) position = tempEndPosRef.endPos
        return value
    }

    /*
    * Scans for comma-whitespace sequence with a float following it.
    * But only if the provided 'lastFloat' (representing the last coord
    * scanned was non-null (ie parsed correctly).)
    */
    fun checkedNextFloat(lastRead: Float): Float {
        return if (lastRead.isNaN()) {
            Float.NaN
        } else {
            skipCommaWhitespace()
            nextFloat()
        }
    }

    fun checkedNextFloat(lastRead: Boolean?): Float {
        return if (lastRead == null) {
            Float.NaN
        } else {
            skipCommaWhitespace()
            nextFloat()
        }
    }

    fun nextInteger(withSign: Boolean): Int? {
        val ip = parseInt(input, position, inputLength, withSign) ?: return null
        position = ip.endPos
        return ip.value
    }

    /*
    * Returns the char at the current position and advances the pointer.
    */
    fun nextChar(): Char {
        if (position == inputLength) throw IndexOutOfBoundsException()
        return input[position++]
    }

    fun nextLength(): CSSLength? {
        val scalar = nextFloat()
        if (scalar.isNaN()) return null
        val unit = nextUnit() ?: CssUnit.px
        return CSSLength(scalar, unit)
    }

    /*
    * Scan for a 'flag'. A flag is a '0' or '1' digit character.
    */
    fun nextFlag(): Boolean? {
        if (position == inputLength) return null
        val ch = input[position]
        return if (ch == '0' || ch == '1') {
            position++
            ch == '1'
        } else {
            null
        }
    }

    /*
    * Like checkedNextFloat, but reads a flag (see path definition parser)
    */
    fun checkedNextFlag(lastRead: Any?): Boolean? {
        return if (lastRead == null) {
            null
        } else {
            skipCommaWhitespace()
            nextFlag()
        }
    }

    fun consume(ch: Char): Boolean {
        val found = position < inputLength && input[position] == ch
        if (found) position++
        return found
    }


    fun consume(str: String): Boolean {
        val found = input.startsWith(str, position)
        if (found) position += str.length
        return found
    }

    /*
    * Skip the current char and peek at the char in the following position.
    */
    fun advanceChar(): Char {
        return if (position == inputLength) {
            INVALID_CHAR
        } else {
            position++
            if (position < inputLength) {
                input[position]
            } else {
                INVALID_CHAR
            }
        }
    }


    /*
    * Scans the input starting immediately at 'position' for the next token.
    * A token is a sequence of characters terminating at a whitespace character.
    * Note that this routine only checks for whitespace characters.  Use nextToken(char)
    * if token might end with another character.
    */
    fun nextToken(): String? {
        return nextToken(' ', false)
    }

    fun requireNextToken(): String {
        return nextToken()!!
    }

    /*
    * Scans the input starting immediately at 'position' for the next token.
    * A token is a sequence of characters terminating at either a whitespace character
    * or the supplied terminating character.
    */
    fun nextToken(terminator: Char): String? {
        return nextToken(terminator, false)
    }

    /*
    * Scans the input starting immediately at 'position' for the next token.
    * A token is a sequence of characters terminating at either the supplied terminating
    * character.  Whitespaces are allowed.
    */
    fun nextTokenWithWhitespace(terminator: Char): String? {
        return nextToken(terminator, true)
    }

    /*
    * Scans the input starting immediately at 'position' for the next token.
    * A token is a sequence of characters terminating at either the supplied terminating
    * character, or (optionally) a whitespace character.
    */
    fun nextToken(terminator: Char, allowWhitespace: Boolean): String? {
        if (empty()) return null

        var ch = input[position]
        if (!allowWhitespace && isWhitespace(ch) || ch == terminator) return null

        val start = position
        ch = advanceChar()
        while (ch != INVALID_CHAR) {
            if (ch == terminator) break
            if (!allowWhitespace && isWhitespace(ch)) break
            ch = advanceChar()
        }
        return input.substring(start, position)
    }


    /*
    * Scans the input starting immediately at 'position' looking for a continuous
    * sequence of ASCII letters. Terminates at any non-letter.
    */
    fun nextWord(): String? {
        if (empty()) return null
        val start = position

        var ch = input[position]
        if (ch in 'A'..'Z' || ch in 'a'..'z') {
            ch = advanceChar()
            while (ch in 'A'..'Z' || ch in 'a'..'z') ch =
                advanceChar()
            return input.substring(start, position)
        }
        position = start
        return null
    }


    /*
    * Scans the input starting immediately at 'position' for the sequence
    * of letter characters terminated by an open bracket.  The function
    * name is returned.
    */
    fun nextFunction(): String? {
        if (empty()) return null
        val start = position

        var ch = input[position]
        while (ch in 'a'..'z' || ch in 'A'..'Z') ch =
            advanceChar()
        val end = position
        while (isWhitespace(ch)) ch = advanceChar()
        if (ch == '(') {
            position++
            return input.substring(start, end)
        }
        position = start
        return null
    }

    /*
    * Get the next few chars. Mainly used for error messages.
    */
    fun ahead(): String {
        val start = position
        while (!empty() && !isWhitespace(input[position])) position++
        val str = input.substring(start, position)
        position = start
        return str
    }

    internal fun nextUnit(): CssUnit? {
        if (empty()) return null
        val ch = input[position]
        if (ch == '%') {
            position++
            return CssUnit.percent
        }
        if (position > inputLength - 2) return null

        val c1 = input[position]
        val c2 = input[position + 1]

        val unit = when (c1) {
            'p', 'P' -> when (c2) {
                'x', 'X' -> CssUnit.px
                't', 'T' -> CssUnit.pt
                'c', 'C' -> CssUnit.pc
                else -> null
            }
            'e', 'E' -> when (c2) {
                'm', 'M' -> CssUnit.em
                'x', 'X' -> CssUnit.ex
                else -> null
            }
            'i', 'I' -> if (c2 == 'n' || c2 == 'N') CssUnit.`in` else null
            'c', 'C' -> if (c2 == 'm' || c2 == 'M') CssUnit.cm else null
            'm', 'M' -> if (c2 == 'm' || c2 == 'M') CssUnit.mm else null
            else -> null
        }

        if (unit != null) {
            position += 2
        }
        return unit
    }

    /*
    * Check whether the next character is a letter.
    */
    fun hasLetter(): Boolean {
        return if (position == inputLength) {
            false
        } else {
            val ch = input[position]
            ch in 'a'..'z' || ch in 'A'..'Z'
        }
    }

    /*
    * Extract a quoted string from the input.
    */
    fun nextQuotedString(): String? {
        if (empty()) return null
        val start = position
        var ch = input[position]
        val endQuote = ch
        if (ch != '\'' && ch != '"') return null
        ch = advanceChar()
        while (ch != INVALID_CHAR && ch != endQuote) ch = advanceChar()
        if (ch == INVALID_CHAR) {
            position = start
            return null
        }
        position++
        return input.substring(start + 1, position - 1)
    }

    /*
    * Return the remaining input as a string.
    */
    fun restOfText(): String? {
        return if (empty()) {
            null
        } else {
            val start = position
            position = inputLength
            input.substring(start)
        }
    }
}


