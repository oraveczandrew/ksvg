/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 *
 *    Portions derived from kXML 2 (http://kxml.org), whose license follows:
 *
 *    Copyright (c) 2002,2003, Stefan Haustein, Oberhausen, Rhld., Germany
 *
 *    Permission is hereby granted, free of charge, to any person obtaining a copy
 *    of this software and associated documentation files (the "Software"), to deal
 *    in the Software without restriction, including without limitation the rights
 *    to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *    sell copies of the Software, and to permit persons to whom the Software is
 *    furnished to do so, subject to the following conditions:
 *
 *    The above copyright notice and this permission notice shall be included in
 *    all copies or substantial portions of the Software.
 *
 *    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 *    IN THE SOFTWARE.
 *
 *    Contributors: Paul Hackenberger (unterminated entity handling in relaxed mode).
 */

package hu.oandras.ksvg.parser

import androidx.collection.SimpleArrayMap
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader
import java.io.Reader
import kotlin.math.max
import kotlin.math.min
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserException

/**
 * A simple, pull-based XML parser. This class replaces the kXML 1
 * XmlParser class and the corresponding event classes.
 */
@SuppressWarnings("kotlin:S1066", "kotlin:S3776")
@Suppress("DEPRECATION", "HttpUrlsUsage")
internal class KXmlParser : XmlPullParser {
    private var location: Any? = null

    // general
    private var version: String? = null
    private var standalone: Boolean? = null
    private var processNamespaces: Boolean = false
    private var processUnderscoreCdata: Boolean = false
    private var relaxed: Boolean = false
    // Accepted for XmlPullParser-compat (set by callers that also target the
    // platform parser); DOCTYPE sections are skipped either way.
    private var processDocDecl: Boolean = false
    private var entityMap: SimpleArrayMap<String, String>? = null
    private var depth: Int = 0
    private var elementStack: Array<String?> = arrayOfNulls(20)
    private var nspStack: Array<String?> = arrayOfNulls(14)
    private var nspCounts: IntArray = IntArray(4)

    // source
    private var reader: Reader? = null
    private var encoding: String? = null
    private val srcBuf: CharArray = CharArray(8192)
    private var srcPos: Int = 0
    private var srcCount: Int = 0
    private var line: Int = 0
    private var column: Int = 0

    // txt buffer
    private var txtBuf: CharArray = CharArray(8 * 1024)
    private var txtPos: Int = 0

    // Event-related
    private var type: Int = 0
    private var isWhitespace: Boolean = false
    private var namespace: String? = null
    private var prefix: String? = null
    private var name: String? = null
    private var degenerated: Boolean = false
    private var attributeCount: Int = 0
    private var attributes: Array<String?> = arrayOfNulls(80)
    private var stackMismatch: Int = 0
    private var error: String? = null

    /**
     * A separate peek buffer seems simpler than managing
     * wrap around in the first level read buffer
     */
    private val peek: IntArray = IntArray(10)
    private var peekCount: Int = 0
    private var wasCR: Boolean = false
    private var unresolved: Boolean = false
    private var token: Boolean = false

    private var skipSubTree: Boolean = false

    @JvmField
    var dictionary: StringDictionary? = null

    @Throws(XmlPullParserException::class)
    private fun adjustNamespace(): Boolean {
        var any = false
        var i = 0
        val attributes = attributes
        while (i < attributeCount shl 2) {

            // * 4 - 4; i >= 0; i -= 4) {
            var attrName = attributes[i + ATTR_NAME]
            val cut = attrName!!.indexOf(':')
            val prefix: String
            if (cut != -1) {
                prefix = attrName.take(cut)
                attrName = attrName.substring(cut + 1)
            } else if (attrName == "xmlns") {
                prefix = attrName
                attrName = null
            } else {
                i += 4
                continue
            }
            if (prefix != "xmlns") {
                any = true
            } else {
                val j = nspCounts[depth]++ shl 1
                val nspStack = ensureCapacity(nspStack, j + 2).also {
                    this.nspStack = it
                }
                nspStack[j + NSP_PREFIX] = attrName
                nspStack[j + NSP_URI] = attributes[i + ATTR_VALUE]
                if (attrName != null && attributes[i + ATTR_VALUE] == "") {
                    error("illegal empty namespace")
                }
                System.arraycopy(
                    attributes,
                    i + 4,
                    attributes,
                    i,
                    (--attributeCount shl 2) - i
                )
                i -= 4
            }
            i += 4
        }

        if (any) {
            var k = (attributeCount shl 2) - 4
            while (k >= 0) {
                var attrName = attributes[k + ATTR_NAME]
                val cut = attrName!!.indexOf(':')
                if (cut == 0 && !relaxed) {
                    throw RuntimeException("illegal attribute name: $attrName at $this")
                } else if (cut != -1) {
                    val attrPrefix = attrName.take(cut)
                    attrName = attrName.substring(cut + 1)
                    val attrNs = getNamespace(attrPrefix)
                    if (attrNs == null && !relaxed) {
                        throw RuntimeException("Undefined Prefix: $attrPrefix in $this")
                    }
                    attributes[k + ATTR_NS] = attrNs
                    attributes[k + ATTR_PREFIX] = attrPrefix
                    attributes[k + ATTR_NAME] = attrName
                }
                k -= 4
            }
        }

        val name = name!!
        val cut = name.indexOf(':')
        if (cut == 0) {
            onError { "illegal tag name: $name" }
        }
        if (cut != -1) {
            prefix = name.take(cut)
            this.name = name.substring(cut + 1)
        }

        namespace = getNamespace(prefix) ?: run {
            if (prefix != null) {
                onError { "undefined prefix: $prefix" }
            }
            XmlPullParser.NO_NAMESPACE
        }

        return any
    }

    private fun ensureCapacity(arr: Array<String?>, required: Int): Array<String?> {
        if (arr.size >= required) {
            return arr
        }
        val bigger = arrayOfNulls<String>(max(required + 16, required * 3 / 2))
        System.arraycopy(arr, 0, bigger, 0, arr.size)
        return bigger
    }

    private inline fun onNonFatalError(r: () -> String) {
        if (error == null) {
            error(r.invoke())
        }
    }

    private inline fun onError(r: () -> String) {
        if (error == null || !relaxed) {
            error(r.invoke())
        }
    }

    @Throws(XmlPullParserException::class)
    private fun error(desc: String) {
        if (relaxed) {
            if (error == null) error = "ERR: $desc"
        } else {
            exception(desc)
        }
    }

    @Throws(XmlPullParserException::class)
    private fun exception(desc: String) {
        val message = if (desc.length < 100) desc else """
 ${desc.take(100)}
 
 """.trimIndent()

        throw XmlPullParserException(
            message,
            this,
            null
        )
    }

    /**
     * Common base for next and nextToken. Clears the state, except from
     * txtPos and whitespace. Does not set the type variable
     */
    @Throws(IOException::class, XmlPullParserException::class)
    private fun nextImpl() {
        if (reader == null) {
            exception("No Input specified")
        }

        if (type == XmlPullParser.END_TAG) {
            depth--
        }

        while (true) {
            attributeCount = -1

            // degenerated needs to be handled before error because of possible
            // processor expectations(!)
            if (degenerated) {
                degenerated = false
                type = XmlPullParser.END_TAG
                return
            }

            val err = error
            if (err != null) {
                pushCharSequence(err)
                error = null
                type = XmlPullParser.COMMENT
                return
            }

            if (relaxed && (stackMismatch > 0 || peek(0) == -1 && depth > 0)) {
                val sp = depth - 1 shl 2
                type = XmlPullParser.END_TAG
                val elementStack = elementStack
                namespace = elementStack[sp + EL_NS]
                prefix = elementStack[sp + EL_PREFIX]
                name = elementStack[sp + EL_NAME]
                if (stackMismatch != 1) {
                    onNonFatalError {
                        "missing end tag /$name inserted"
                    }
                }
                if (stackMismatch > 0) {
                    stackMismatch--
                }
                return
            }

            prefix = null
            name = null
            namespace = null
            type = peekType()

            when (type) {
                XmlPullParser.ENTITY_REF -> {
                    pushEntity()
                    return
                }
                XmlPullParser.START_TAG -> {
                    parseStartTag(false)
                    return
                }
                XmlPullParser.END_TAG -> {
                    parseEndTag()
                    return
                }
                XmlPullParser.END_DOCUMENT -> return
                XmlPullParser.TEXT -> {
                    if (insideScript()) {
                        pushScript()
                    } else {
                        pushText('<'.toInt(), !token)
                    }

                    if (depth == 0) {
                        if (isWhitespace) {
                            type = XmlPullParser.IGNORABLE_WHITESPACE
                        }
                        // make exception switchable for instances.chg... !!!!
                        //	else 
                        //    exception ("text '"+getText ()+"' not allowed outside the root element");
                    }
                    return
                }
                else -> {
                    type = parseLegacy(token)
                    if (type != XML_DECL) {
                        return
                    }
                }
            }
        }
    }

    @Throws(IOException::class, XmlPullParserException::class)
    private fun parseLegacy(pPush: Boolean): Int {
        var push = pPush
        var req = ""
        val term: Int
        val result: Int
        var prev = 0
        read() // <
        when (val c = read()) {
            '?'.toInt() -> {
                if ((peek(0) == 'x'.toInt() || peek(0) == 'X'.toInt())
                    && (peek(1) == 'm'.toInt() || peek(1) == 'M'.toInt())
                ) {
                    if (push) {
                        push(peek(0))
                        push(peek(1))
                    }
                    read()
                    read()
                    if ((peek(0) == 'l'.toInt() || peek(0) == 'L'.toInt()) && peek(1) <= ' '.toInt()) {
                        if (line != 1 || column > 4) error("PI must not start with xml")
                        parseStartTag(true)
                        val attributes = attributes
                        if (attributeCount < 1 || "version" != attributes[ATTR_NAME]) {
                            error("version expected")
                        }
                        version = attributes[ATTR_VALUE]
                        var pos = 1
                        if (pos < attributeCount && "encoding" == attributes[4 * pos + ATTR_NAME]) {
                            encoding = attributes[4 * pos + ATTR_VALUE]
                            pos++
                        }
                        if (pos < attributeCount && "standalone" == attributes[4 * pos + ATTR_NAME]) {
                            when (val st = attributes[4 * pos + ATTR_VALUE]) {
                                "yes" -> standalone = java.lang.Boolean.TRUE
                                "no" -> standalone = java.lang.Boolean.FALSE
                                else -> onError {
                                    "illegal standalone value: $st"
                                }
                            }
                            pos++
                        }
                        if (pos != attributeCount) error("illegal xmldecl")
                        isWhitespace = true
                        txtPos = 0
                        return XML_DECL
                    }
                }
                term = '?'.toInt()
                result = XmlPullParser.PROCESSING_INSTRUCTION
            }
            '!'.toInt() -> {
                when (peek(0)) {
                    '-'.toInt() -> {
                        result = XmlPullParser.COMMENT
                        req = "--"
                        term = '-'.toInt()
                    }
                    '['.toInt() -> {
                        result = XmlPullParser.CDSECT
                        req = "[CDATA["
                        term = ']'.toInt()
                        push = true
                    }
                    else -> {
                        result = XmlPullParser.DOCDECL
                        req = "DOCTYPE"
                        term = -1
                    }
                }
            }
            else -> {
                onError {
                    "illegal: <$c"
                }
                return XmlPullParser.COMMENT
            }
        }

        for (i in req.indices) {
            read(req[i])
        }

        if (result == XmlPullParser.DOCDECL) {
            parseDoctype(push)
        } else {
            while (true) {
                val c = read()
                if (c == -1) {
                    error(UNEXPECTED_EOF)
                    return XmlPullParser.COMMENT
                }
                if (push) push(c)
                if ((term == '?'.toInt() || c == term)
                    && peek(0) == term && peek(1) == '>'.toInt()
                ) break
                prev = c
            }
            if (term == '-'.toInt() && prev == '-'.toInt()) error("illegal comment delimiter: --->")
            read()
            read()
            if (push && term != '?'.toInt()) {
                txtPos--
            }
        }
        return result
    }

    /**
     * precondition: &lt! consumed
     */
    @Throws(IOException::class, XmlPullParserException::class)
    private fun parseDoctype(push: Boolean) {
        var nesting = 1
        var quoted = false

        while (true) {
            val i = read()
            when (i) {
                -1 -> {
                    error(UNEXPECTED_EOF)
                    return
                }
                '\''.toInt() -> quoted = !quoted
                '<'.toInt() -> if (!quoted) nesting++
                '>'.toInt() -> if (!quoted) {
                    if (--nesting == 0) {
                        return
                    }
                }
            }
            if (push) push(i)
        }
    }

    /* precondition: &lt;/ consumed */
    @Throws(IOException::class, XmlPullParserException::class)
    private fun parseEndTag() {
        read() // '<'
        read() // '/'
        name = readName()
        skip()
        read('>')
        val sp = depth - 1 shl 2
        if (depth == 0) {
            error("element stack empty")
            type = XmlPullParser.COMMENT
            return
        }

        val elementStack = elementStack
        if (name != elementStack[sp + EL_RAW_NAME]) {
            onError { "expected: /${elementStack[sp + EL_RAW_NAME]} read: $name" }

            // become case-insensitive in relaxed mode
            var probe = sp
            while (probe >= 0 && !name.equals(elementStack[probe + EL_RAW_NAME], ignoreCase = true)) {
                stackMismatch++
                probe -= 4
            }
            if (probe < 0) {
                stackMismatch = 0
                type = XmlPullParser.COMMENT
                return
            }
        }
        namespace = elementStack[sp + EL_NS]
        prefix = elementStack[sp + EL_PREFIX]
        name = elementStack[sp + EL_NAME]
    }

    @Throws(IOException::class)
    private fun peekType(): Int {
        return when (peek(0)) {
            -1 -> XmlPullParser.END_DOCUMENT
            '&'.toInt() -> XmlPullParser.ENTITY_REF
            '<'.toInt() -> when (peek(1)) {
                '/'.toInt() -> XmlPullParser.END_TAG
                '?'.toInt(),
                '!'.toInt() -> LEGACY
                else -> {
                    if (insideScript()) {
                        XmlPullParser.TEXT
                    } else {
                        XmlPullParser.START_TAG
                    }
                }
            }
            else -> XmlPullParser.TEXT
        }
    }

    private fun insideScript(): Boolean {
        val sp = depth - 1 shl 2
        return sp >= 0 && elementStack[sp + EL_NAME] == "script" && !peekedIsScriptEnd()
    }

    private fun get(pos: Int, useMap: Boolean): String {
        val length = txtPos - pos

        if (useMap) {
            val value = dictionary?.obtainForRange(txtBuf, pos, length)
            if (value != null) {
                return value
            }
        }

        return String(txtBuf, pos, length)
    }

    private fun pushCharSequence(charSequence: CharSequence) {
        for (ch in charSequence) {
            push(ch.toInt())
        }
    }

    private fun push(c: Int) {
        isWhitespace = isWhitespace and (c <= ' '.toInt())
        var txtBuf = txtBuf
        if (txtPos == txtBuf.size) {
            // Past 64 KiB (giant attribute values / text runs) doubling beats
            // the default 5/3 growth: fewer full-buffer copies on the way up.
            val grown = if (txtBuf.size >= 65536) txtPos * 2 + 4 else txtPos * 5 / 3 + 4
            txtBuf = createCharArray(old = txtBuf, size = grown).also {
                this.txtBuf = it
            }
        }
        txtBuf[txtPos++] = c.toChar()
    }

    private fun createCharArray(old: CharArray, size: Int): CharArray {
        val bigger = CharArray(size)
        System.arraycopy(old, 0, bigger, 0, old.size)
        return bigger
    }

    /**
     * Sets name and attributes
     */
    @Throws(IOException::class, XmlPullParserException::class)
    private fun parseStartTag(xmlDecl: Boolean) {
        if (!xmlDecl) {
            read()
        }
        name = readName()
        attributeCount = 0
        while (true) {
            skip()
            val c = peek(0)
            if (xmlDecl) {
                if (c == '?'.toInt()) {
                    read()
                    read('>')
                    return
                }
            } else {
                if (c == '/'.toInt()) {
                    degenerated = true
                    read()
                    skip()
                    read('>')
                    break
                }
                if (c == '>'.toInt()) {
                    read()
                    break
                }
            }
            if (c == -1) {
                error(UNEXPECTED_EOF)
                //type = COMMENT;
                return
            }
            val attrName = readName()
            if (attrName.isEmpty()) {
                error("attr name expected")
                //type = COMMENT;
                break
            }
            val i = attributeCount++ shl 2
            attributes = ensureCapacity(attributes, i + 4).also {
                it[i + ATTR_NS] = ""
                it[i + ATTR_PREFIX] = null
                it[i + ATTR_NAME] = attrName
            }
            skip()
            if (peek(0) != '='.toInt()) {
                onError { "Attr.value missing f. $attrName" }
                attributes[i + ATTR_VALUE] = "1"
            } else {
                read('=')
                skip()
                var delimiter = peek(0)
                if (delimiter != '\''.toInt() && delimiter != '"'.toInt()) {
                    error("attr value delimiter missing!")
                    delimiter = ' '.toInt()
                } else {
                    read()
                }
                val p = txtPos
                pushText(delimiter, true)
                // Short values go through the dictionary (common literals hit
                // with zero allocation); long ones (path data, ids) never would,
                // so skip hashing them entirely.
                attributes[i + ATTR_VALUE] = if (txtPos - p <= 64) get(p, true) else get(p, false)
                txtPos = p
                if (delimiter != ' '.toInt()) read() // skip end quote
            }
        }
        val sp = depth++ shl 2
        val elementStack = ensureCapacity(elementStack, sp + 4).also {
            this.elementStack = it
        }
        elementStack[sp + EL_RAW_NAME] = name

        var nspCounts = nspCounts
        if (depth >= nspCounts.size) {
            val bigger = IntArray(depth + 4)
            System.arraycopy(nspCounts, 0, bigger, 0, nspCounts.size)
            nspCounts = bigger
            this.nspCounts = nspCounts
        }
        nspCounts[depth] = nspCounts[depth - 1]

        if (processNamespaces) {
            adjustNamespace()
        } else {
            namespace = ""
        }

        elementStack.let {
            it[sp + EL_NS] = namespace
            it[sp + EL_PREFIX] = prefix
            it[sp + EL_NAME] = name
        }
    }

    @Throws(IOException::class, XmlPullParserException::class)
    private fun parseUnderscoreCdata() {
        while (true) {
            if (peek(0) == '<'.toInt() &&
                peek(1) == '/'.toInt() &&
                peek(2) == '_'.toInt() &&
                peek(3) == 'c'.toInt() &&
                peek(4) == 'd'.toInt() &&
                peek(5) == 'a'.toInt() &&
                peek(6) == 't'.toInt() &&
                peek(7) == 'a'.toInt() &&
                peek(8) == '>'.toInt()
            ) {

                for (_ in 0..8) read()
                break
            }

            val c = read()
            if (c == -1) {
                error(UNEXPECTED_EOF)
                return
            }
            push(c)
        }

        depth--
        type = XmlPullParser.TEXT
    }

    /**
     * result: isWhitespace; if the setName parameter is set,
     * the name of the entity is stored in "name"
     */
    @Throws(IOException::class, XmlPullParserException::class)
    private fun pushEntity() {
        push(read()) // &
        val pos = txtPos
        while (true) {
            val c = read()
            if (c == ';'.toInt()) break
            if (c < 128 && (c < '0'.toInt() || c > '9'.toInt())
                && (c < 'a'.toInt() || c > 'z'.toInt())
                && (c < 'A'.toInt() || c > 'Z'.toInt())
                && c != '_'.toInt() && c != '-'.toInt() && c != '#'.toInt()
            ) {
                if (!relaxed) {
                    error("unterminated entity ref")
                }
                //; ends with:"+(char)c);           
                if (c != -1) push(c)
                return
            }
            push(c)
        }
        val code = get(pos, true)
        txtPos = pos - 1
        if (token && type == XmlPullParser.ENTITY_REF) {
            name = code
        }
        if (code[0] == '#') {
            val c = if (code[1] == 'x') {
                code.substring(2).toInt(16)
            } else {
                code.substring(1).toInt()
            }
            push(c)
            return
        }
        val result = entityMap!![code]
        if (result == null) {
            unresolved = true
            if (!token) onError { "unresolved: &$code;" }
        } else {
            unresolved = false
            pushCharSequence(result)
        }
    }

    private fun pushScript() {
        var next = peek(0)
        while (next != -1) {
            if (peekedIsScriptEnd()) {
                break
            }

            val c = read()
            if (!skipSubTree) {
                push(c)
            }
            next = peek(0)
        }
    }

    private fun peekedIsScriptEnd(): Boolean {
        return peek(0) == '<'.toInt() &&
                peek(1) == '/'.toInt() &&
                peek(2) == 's'.toInt() &&
                peek(3) == 'c'.toInt() &&
                peek(4) == 'r'.toInt() &&
                peek(5) == 'i'.toInt() &&
                peek(6) == 'p'.toInt() &&
                peek(7) == 't'.toInt() &&
                peek(8) == '>'.toInt()
    }

    /**
     * types:
     * '<': parse to any token (for nextToken ())
     * '"': parse to quote
     * ' ': parse to whitespace or '>'
     */
    @Throws(IOException::class, XmlPullParserException::class)
    private fun pushText(delimiter: Int, resolveEntities: Boolean) {
        var next = peek(0)
        var cbrCount = 0
        while (next != -1 && next != delimiter) { // covers eof, '<', '"'
            if (delimiter == ' '.toInt() && (next <= ' '.toInt() || next == '>'.toInt())) {
                break
            }
            if (next == '&'.toInt()) {
                if (!resolveEntities) break
                pushEntity()
            } else if (next == '\n'.toInt() && type == XmlPullParser.START_TAG) {
                read()
                push(' '.toInt())
            } else {
                val c = read()
                if (!skipSubTree) {
                    push(c)
                }
            }
            @Suppress("KotlinConstantConditions")
            if (next == '>'.toInt() && cbrCount >= 2 && delimiter != ']'.toInt()) {
                error("Illegal: ]]>")
            }

            cbrCount = if (next == ']'.toInt()) {
                cbrCount + 1
            } else {
                0
            }

            next = peek(0)
        }
    }

    @Throws(IOException::class, XmlPullParserException::class)
    private fun read(requiredChar: Char) {
        val a = read()
        if (a != requiredChar.toInt()) {
            onError { "expected: '$requiredChar' actual: '${a.toChar()}'" }
        }
    }

    @Throws(IOException::class)
    private fun read(): Int {
        val result: Int
        if (peekCount == 0) {
            result = peek(0)
        } else {
            val peek = peek
            result = peek[0]
            System.arraycopy(peek, 1, peek, 0, peek.size - 1)
        }

        peekCount--
        column++
        if (result == '\n'.toInt()) {
            line++
            column = 1
        }
        return result
    }

    /**
     * Does never read more than needed
     */
    @Throws(IOException::class)
    private fun peek(pos: Int): Int {
        val reader = reader!!
        val peek = peek
        val srcBuf = srcBuf
        while (pos >= peekCount) {
            val nw: Int

            when {
                srcBuf.size <= 1 -> {
                    nw = reader.read()
                }
                srcPos < srcCount -> {
                    nw = srcBuf[srcPos++].toInt()
                }
                else -> {
                    srcCount = reader.read(srcBuf, 0, srcBuf.size)
                    nw = if (srcCount <= 0) -1 else srcBuf[0].toInt()
                    srcPos = 1
                }
            }

            when (nw) {
                '\r'.toInt() -> {
                    wasCR = true
                    peek[peekCount++] = '\n'.toInt()
                }
                '\n'.toInt() -> {
                    if (!wasCR) peek[peekCount++] = '\n'.toInt()
                    wasCR = false
                }
                else -> {
                    peek[peekCount++] = nw
                    wasCR = false
                }
            }
        }
        return peek[pos]
    }

    @Throws(IOException::class, XmlPullParserException::class)
    private fun readName(): String {
        val pos = txtPos
        var c = peek(0)
        if ((c < 'a'.toInt() || c > 'z'.toInt())
            && (c < 'A'.toInt() || c > 'Z'.toInt())
            && c != '_'.toInt() && c != ':'.toInt() && c < 0x0c0 && !relaxed
        ) error("name expected")
        do {
            push(read())
            c = peek(0)
        } while (c >= 'a'.toInt() && c <= 'z'.toInt()
            || c >= 'A'.toInt() && c <= 'Z'.toInt()
            || c >= '0'.toInt() && c <= '9'.toInt()
            || c == '_'.toInt() || c == '-'.toInt() || c == ':'.toInt() || c == '.'.toInt() || c >= 0x0b7
        )
        val result = get(pos, true)
        txtPos = pos
        return result
    }

    @Throws(IOException::class)
    private fun skip() {
        while (true) {
            val c = peek(0)
            if (c > ' '.toInt() || c == -1) break
            read()
        }
    }

    //  public part starts here...
    @Throws(XmlPullParserException::class)
    override fun setInput(reader: Reader) {
        this.reader = reader
        line = 1
        column = 0
        type = XmlPullParser.START_DOCUMENT
        name = null
        namespace = null
        degenerated = false
        attributeCount = -1
        encoding = null
        version = null
        standalone = null
        srcPos = 0
        srcCount = 0
        peekCount = 0
        depth = 0

        entityMap = SimpleArrayMap<String, String>(5).apply {
            put("amp", "&")
            put("apos", "'")
            put("gt", ">")
            put("lt", "<")
            put("quot", "\"")
        }
    }

    @Throws(XmlPullParserException::class)
    override fun setInput(inputStream: InputStream, inputEncoding: String?) {
        srcPos = 0
        srcCount = 0
        val srcBuf = srcBuf
        var enc = inputEncoding
        try {
            if (enc == null) {
                // read four bytes
                var chk = 0
                while (srcCount < 4) {
                    val i = inputStream.read()
                    if (i == -1) break
                    chk = chk shl 8 or i
                    srcBuf[srcCount++] = i.toChar()
                }
                if (srcCount == 4) {
                    when (chk) {
                        0x00000FEFF -> {
                            enc = "UTF-32BE"
                            srcCount = 0
                        }
                        -0x20000 -> {
                            enc = "UTF-32LE"
                            srcCount = 0
                        }
                        0x03c -> {
                            enc = "UTF-32BE"
                            srcBuf[0] = '<'
                            srcCount = 1
                        }
                        0x03c000000 -> {
                            enc = "UTF-32LE"
                            srcBuf[0] = '<'
                            srcCount = 1
                        }
                        0x0003c003f -> {
                            enc = UTF_16BE
                            srcBuf[0] = '<'
                            srcBuf[1] = '?'
                            srcCount = 2
                        }
                        0x03c003f00 -> {
                            enc = UTF_16LE
                            srcBuf[0] = '<'
                            srcBuf[1] = '?'
                            srcCount = 2
                        }
                        0x03c3f786d -> {
                            while (true) {
                                val i = inputStream.read()
                                if (i == -1) break
                                srcBuf[srcCount++] = i.toChar()
                                if (i == '>'.toInt()) {
                                    val s = String(srcBuf, 0, srcCount)
                                    var i0 = s.indexOf("encoding")
                                    if (i0 != -1) {
                                        while (s[i0] != '"'
                                            && s[i0] != '\''
                                        ) i0++
                                        val deli = s[i0++]
                                        val i1 = s.indexOf(deli, i0)
                                        enc = s.substring(i0, i1)
                                    }
                                    break
                                }
                            }
                        }
                        else -> when {
                            chk and -0x10000 == -0x1010000 -> {
                                enc = UTF_16BE
                                srcBuf[0] = (srcBuf[2].toInt() shl 8 or srcBuf[3].toInt()).toChar()
                                srcCount = 1
                            }
                            chk and -0x10000 == -0x20000 -> {
                                enc = UTF_16LE
                                srcBuf[0] = (srcBuf[3].toInt() shl 8 or srcBuf[2].toInt()).toChar()
                                srcCount = 1
                            }
                            chk and -0x100 == -0x10444100 -> {
                                enc = "UTF-8"
                                srcBuf[0] = srcBuf[3]
                                srcCount = 1
                            }
                        }
                    }
                }
            }
            val sc = srcCount
            setInput(InputStreamReader(inputStream, enc ?: "UTF-8"))
            encoding = inputEncoding
            srcCount = sc
        } catch (e: Exception) {
            throw XmlPullParserException("Invalid stream or encoding: $e", this, e)
        }
    }

    override fun getFeature(feature: String): Boolean {
        return when (feature) {
            XmlPullParser.FEATURE_PROCESS_NAMESPACES -> processNamespaces
            FEATURE_RELAXED -> relaxed
            else -> false
        }
    }

    override fun getInputEncoding(): String? {
        return encoding
    }

    @Throws(XmlPullParserException::class)
    override fun defineEntityReplacementText(entity: String, value: String) {
        val entityMap = entityMap ?:
            throw XmlPullParserException("entity replacement text must be defined after setInput!")
        entityMap.put(entity, value)
    }

    override fun getProperty(property: String): Any? {
        return when (property) {
            PROPERTY_XMLDECL_VERSION -> version
            PROPERTY_XMLDECL_STANDALONE -> standalone
            PROPERTY_LOCATION -> location ?: reader.toString()
            else -> null
        }
    }

    override fun getNamespaceCount(depth: Int): Int {
        if (depth > this.depth) {
            throw IndexOutOfBoundsException()
        }
        return nspCounts[depth]
    }

    override fun getNamespacePrefix(pos: Int): String? {
        return nspStack[(pos shl 1) + NSP_PREFIX]
    }

    override fun getNamespaceUri(pos: Int): String {
        return nspStack[(pos shl 1) + NSP_URI]!!
    }

    override fun getNamespace(prefix: String?): String? {
        if ("xml" == prefix) return "http://www.w3.org/XML/1998/namespace"
        if ("xmlns" == prefix) return "http://www.w3.org/2000/xmlns/"
        var i = (getNamespaceCount(depth) shl 1) - 2
        val nspStack = nspStack
        while (i >= 0) {
            if (prefix == nspStack[i + NSP_PREFIX]) {
                return nspStack[i + NSP_URI]
            }
            i -= 2
        }
        return null
    }

    override fun getDepth(): Int {
        return depth
    }

    override fun getPositionDescription(): String {
        val type = type

        return buildString(128) {
            append(
                TYPES.getOrElse(type) {
                    "unknown"
                }
            )
            append(' ')

            when (type) {
                XmlPullParser.START_TAG,
                XmlPullParser.END_TAG -> {
                    if (degenerated) {
                        append("(empty) ")
                    }
                    append('<')
                    if (type == XmlPullParser.END_TAG) {
                        append('/')
                    }

                    if (prefix != null) {
                        append('{')
                        append(namespace)
                        append('}')
                        append(prefix)
                        append(':')
                    }

                    append(name)
                    val cnt = attributeCount shl 2
                    var i = 0
                    while (i < cnt) {
                        append(' ')

                        val attributes = attributes
                        if (attributes[i + ATTR_PREFIX] != null) {
                            append('{')
                            append(attributes[i + ATTR_NS])
                            append('}')
                            append(attributes[i + ATTR_PREFIX])
                            append(':')
                        }

                        append(attributes[i + ATTR_NAME])
                        append("='")
                        append(attributes[i + ATTR_VALUE])
                        append('\'')

                        i += 4
                    }
                    append('>')
                }
                XmlPullParser.IGNORABLE_WHITESPACE -> {
                    // ignore
                }
                else -> {
                    if (type != XmlPullParser.TEXT) {
                        append(text)
                    } else if (isWhitespace) {
                        append("(whitespace)")
                    } else {
                        val text = text
                        if (text != null && text.length > 16) {
                            append(text, 0, 16)
                            append("...")
                        } else {
                            append(text)
                        }
                    }
                }
            }

            append('@')
            append(line)
            append(':')
            append(column)

            if (location != null) {
                append(" in ")
                append(location)
            } else if (reader != null) {
                append(" in ")
                append(reader.toString())
            }
        }
    }

    override fun getLineNumber(): Int {
        return line
    }

    override fun getColumnNumber(): Int {
        return column
    }

    @Throws(XmlPullParserException::class)
    override fun isWhitespace(): Boolean {
        val type = type
        if (type != XmlPullParser.TEXT && type != XmlPullParser.IGNORABLE_WHITESPACE && type != XmlPullParser.CDSECT) {
            exception(ILLEGAL_TYPE)
        }
        return isWhitespace
    }

    override fun getText(): String? {
        val type = type
        return if (type < XmlPullParser.TEXT || type == XmlPullParser.ENTITY_REF && unresolved) {
            null
        } else {
            get(0, false)
        }
    }

    override fun getTextCharacters(poslen: IntArray): CharArray? {
        val type = type
        return if (type >= XmlPullParser.TEXT) {
            if (type == XmlPullParser.ENTITY_REF) {
                val name = name!!
                poslen[0] = 0
                poslen[1] = name.length
                name.toCharArray()
            } else {
                poslen[0] = 0
                poslen[1] = txtPos
                txtBuf
            }
        } else {
            poslen[0] = -1
            poslen[1] = -1
            null
        }
    }

    override fun getNamespace(): String? {
        return namespace
    }

    override fun getName(): String? {
        return name
    }

    override fun getPrefix(): String? {
        return prefix
    }

    @Throws(XmlPullParserException::class)
    override fun isEmptyElementTag(): Boolean {
        if (type != XmlPullParser.START_TAG) {
            exception(ILLEGAL_TYPE)
        }
        return degenerated
    }

    override fun getAttributeCount(): Int {
        return attributeCount
    }

    override fun getAttributeType(index: Int): String {
        return "CDATA"
    }

    override fun isAttributeDefault(index: Int): Boolean {
        return false
    }

    override fun getAttributeNamespace(index: Int): String {
        if (index >= attributeCount) throw IndexOutOfBoundsException()
        return attributes[(index shl 2) + ATTR_NS] ?: ""
    }

    override fun getAttributeName(index: Int): String {
        if (index >= attributeCount) throw IndexOutOfBoundsException()
        return attributes[(index shl 2) + ATTR_NAME] ?: ""
    }

    override fun getAttributePrefix(index: Int): String {
        if (index >= attributeCount) throw IndexOutOfBoundsException()
        return attributes[(index shl 2) + ATTR_PREFIX] ?: ""
    }

    override fun getAttributeValue(index: Int): String {
        if (index >= attributeCount) throw IndexOutOfBoundsException()
        return attributes[(index shl 2) + ATTR_VALUE] ?: ""
    }

    override fun getAttributeValue(namespace: String?, name: String): String? {
        var i = (attributeCount shl 2) - 4
        val attributes = attributes
        while (i >= 0) {
            if (attributes[i + ATTR_NAME] == name && (namespace == null || attributes[i + ATTR_NS] == namespace)) {
                return attributes[i + ATTR_VALUE]
            }
            i -= 4
        }
        return null
    }

    @Throws(XmlPullParserException::class)
    override fun getEventType(): Int {
        return type
    }

    @Throws(XmlPullParserException::class, IOException::class)
    override fun next(): Int {
        txtPos = 0
        isWhitespace = true
        var minType = 9999
        token = false
        do {
            nextImpl()
            minType = min(minType, type)
        } while (minType > XmlPullParser.ENTITY_REF // ignorable
            || minType >= XmlPullParser.TEXT && peekType() >= XmlPullParser.TEXT
        )

        return min(minType, XmlPullParser.TEXT).also {
            type = it
        }
    }

    @Throws(XmlPullParserException::class, IOException::class)
    override fun nextToken(): Int {
        isWhitespace = true
        txtPos = 0
        token = true
        nextImpl()
        return type
    }

    //
    // utility methods to make XML parsing easier ...
    @Throws(XmlPullParserException::class, IOException::class)
    override fun nextTag(): Int {
        var type = next()
        if (type == XmlPullParser.TEXT && isWhitespace) {
            type = next()
        }
        if (type != XmlPullParser.END_TAG && type != XmlPullParser.START_TAG) {
            exception("unexpected type")
        }
        return type
    }

    @Throws(XmlPullParserException::class, IOException::class)
    override fun require(type: Int, namespace: String?, name: String?) {
        if (
            type != this.type ||
            namespace != null && namespace != this.namespace ||
            name != null && name != this.name
        ) {
            exception("expected: ${TYPES[type]} {$namespace}$name")
        }
    }

    @Throws(XmlPullParserException::class, IOException::class)
    override fun nextText(): String {
        var type = type
        if (type != XmlPullParser.START_TAG) {
            exception("precondition: START_TAG")
        }

        type = next()

        var result: String
        if (type == XmlPullParser.TEXT) {
            result = text!!
            type = next()
        } else {
            result = ""
        }

        if (type == XmlPullParser.START_TAG && name == "_cdata" && processUnderscoreCdata) {
            parseUnderscoreCdata()
            result = text!!
            type = next()
            if (type == XmlPullParser.TEXT) {
                type = next()
            }
        }

        if (type != XmlPullParser.END_TAG) {
            exception("END_TAG expected")
        }

        return result
    }

    @Throws(XmlPullParserException::class)
    override fun setFeature(feature: String, value: Boolean) {
        when (feature) {
            XmlPullParser.FEATURE_PROCESS_NAMESPACES -> {
                processNamespaces = value
            }
            XmlPullParser.FEATURE_PROCESS_DOCDECL -> {
                processDocDecl = value
            }
            FEATURE_PROCESS_UNDERSCORE_CDATA -> {
                processUnderscoreCdata = value
            }
            FEATURE_RELAXED -> {
                relaxed = value
            }
            else -> {
                exception("unsupported feature: $feature")
            }
        }
    }

    @Throws(XmlPullParserException::class)
    override fun setProperty(property: String, value: Any) {
        when (property) {
            PROPERTY_LOCATION -> {
                location = value
            }
            else -> {
                throw XmlPullParserException("unsupported property: $property")
            }
        }
    }

    /**
     * Skip the subtree that is currently parser positioned on.
     * <br></br>NOTE: parser must be on START_TAG, and when the function returns, the
     * parser will be positioned on corresponding END_TAG.
     */
    //	Implementation copied from Alek's mail... 
    @Throws(XmlPullParserException::class, IOException::class)
    fun skipSubTree() {
        require(XmlPullParser.START_TAG, null, null)
        skipSubTree = true
        var level = 1
        while (level > 0) {
            val eventType = next()
            if (eventType == XmlPullParser.END_TAG) {
                --level
            } else if (eventType == XmlPullParser.START_TAG) {
                ++level
            }
        }
        skipSubTree = false
    }

    companion object {
        private const val UNEXPECTED_EOF: String = "Unexpected EOF"
        private const val ILLEGAL_TYPE: String = "Wrong event type"
        private const val LEGACY: Int = 999
        private const val XML_DECL: Int = 998

        private const val UTF_16BE: String = "UTF-16BE"
        private const val UTF_16LE: String = "UTF-16LE"

        private const val ATTR_NS = 0
        private const val ATTR_PREFIX = 1
        private const val ATTR_NAME = 2
        private const val ATTR_VALUE = 3

        private const val EL_NS = 0
        private const val EL_PREFIX = 1
        private const val EL_NAME = 2
        private const val EL_RAW_NAME = 3

        private const val NSP_PREFIX = 0
        private const val NSP_URI = 1

        private const val PROPERTIES_PREFIX = "http://xmlpull.org/v1/doc/properties.html#"

        const val PROPERTY_XMLDECL_VERSION = "${PROPERTIES_PREFIX}xmldecl-version"
        const val PROPERTY_XMLDECL_STANDALONE = "${PROPERTIES_PREFIX}xmldecl-standalone"
        const val PROPERTY_LOCATION: String = "${PROPERTIES_PREFIX}location"

        const val FEATURE_RELAXED: String = "http://xmlpull.org/v1/doc/features.html#relaxed"
        const val FEATURE_PROCESS_UNDERSCORE_CDATA: String = "http://xmlpull.org/v1/doc/features.html#process-underscore-cdata"

        private val TYPES: Array<String> = arrayOf(
            "START_DOCUMENT",
            "END_DOCUMENT",
            "START_TAG",
            "END_TAG",
            "TEXT",
            "CDSECT",
            "ENTITY_REF",
            "IGNORABLE_WHITESPACE",
            "PROCESSING_INSTRUCTION",
            "COMMENT",
            "DOCDECL"
        )
    }
}