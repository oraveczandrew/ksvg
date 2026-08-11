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

@file:Suppress("HttpUrlsUsage")

package hu.oandras.androidsvg.parser

import android.graphics.Matrix
import android.os.Build
import android.util.Log
import android.util.Xml
import androidx.collection.ArrayMap
import androidx.collection.ArraySet
import androidx.collection.MutableFloatList
import hu.oandras.androidsvg.BuildConfig
import hu.oandras.androidsvg.PreserveAspectRatio
import hu.oandras.androidsvg.SVGExternalFileResolver
import hu.oandras.androidsvg.SVGParseException
import hu.oandras.androidsvg.css.CSSFontFeatureSettings
import hu.oandras.androidsvg.css.CSSFontVariationSettings
import hu.oandras.androidsvg.css.CSSLength
import hu.oandras.androidsvg.css.CSSParser
import hu.oandras.androidsvg.css.CSSTextScanner
import hu.oandras.androidsvg.css.CssUnit
import hu.oandras.androidsvg.dom.Box
import hu.oandras.androidsvg.dom.COLOR_BLACK
import hu.oandras.androidsvg.dom.CSSClipRect
import hu.oandras.androidsvg.dom.ColorValue
import hu.oandras.androidsvg.dom.ConvolveMatrixEdgeMode
import hu.oandras.androidsvg.dom.CurrentColor
import hu.oandras.androidsvg.dom.FeBlendMode
import hu.oandras.androidsvg.dom.FeChannelSelector
import hu.oandras.androidsvg.dom.FeColorMatrixType
import hu.oandras.androidsvg.dom.FeCompositeOperator
import hu.oandras.androidsvg.dom.FeFuncType
import hu.oandras.androidsvg.dom.FeMorphologyOperator
import hu.oandras.androidsvg.dom.FeStitchTiles
import hu.oandras.androidsvg.dom.FeTurbulenceType
import hu.oandras.androidsvg.dom.HasTransform
import hu.oandras.androidsvg.dom.PaintReference
import hu.oandras.androidsvg.dom.PathDefinition
import hu.oandras.androidsvg.dom.SVGAttr
import hu.oandras.androidsvg.dom.SVGImpl
import hu.oandras.androidsvg.dom.Style
import hu.oandras.androidsvg.dom.Style.FillRule
import hu.oandras.androidsvg.dom.Style.FontKerning
import hu.oandras.androidsvg.dom.Style.FontStyle
import hu.oandras.androidsvg.dom.Style.Isolation
import hu.oandras.androidsvg.dom.Style.LineCap
import hu.oandras.androidsvg.dom.Style.LineJoin
import hu.oandras.androidsvg.dom.Style.RenderQuality
import hu.oandras.androidsvg.dom.Style.TextAnchor
import hu.oandras.androidsvg.dom.Style.TextDecoration
import hu.oandras.androidsvg.dom.Style.TextDirection
import hu.oandras.androidsvg.dom.Style.VectorEffect
import hu.oandras.androidsvg.dom.SvgColor
import hu.oandras.androidsvg.dom.SvgObject
import hu.oandras.androidsvg.dom.SvgObject.*
import hu.oandras.androidsvg.dom.SvgPaint
import hu.oandras.androidsvg.dom.TextChild
import hu.oandras.androidsvg.dom.TextRoot
import hu.oandras.androidsvg.utils.ColorKeywords
import hu.oandras.androidsvg.utils.FontSizeKeywords
import hu.oandras.androidsvg.utils.GradientSpread
import hu.oandras.androidsvg.utils.clamp
import hu.oandras.androidsvg.utils.compilePattern
import hu.oandras.androidsvg.utils.forEachElement
import hu.oandras.androidsvg.utils.pack3Hex
import hu.oandras.androidsvg.utils.pack4Hex
import hu.oandras.androidsvg.utils.pack8Hex
import hu.oandras.androidsvg.utils.packHsla
import hu.oandras.androidsvg.utils.packRgba
import hu.oandras.androidsvg.utils.toFloatArray
import hu.oandras.androidsvg.utils.toRadians
import hu.oandras.androidsvg.utils.trimLowerThanSpace
import org.xml.sax.Attributes
import org.xml.sax.InputSource
import org.xml.sax.SAXException
import org.xml.sax.ext.DefaultHandler2
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserException
import java.io.IOException
import java.io.InputStream
import java.util.Locale
import java.util.regex.Matcher
import java.util.regex.Pattern
import java.util.zip.GZIPInputStream
import javax.xml.parsers.ParserConfigurationException
import javax.xml.parsers.SAXParserFactory
import kotlin.math.tan

private const val NORMAL = "normal"

/*
 * SVG parser code. Used by SVG class. Should not be called directly.
 */
internal class SVGParserImpl : SVGParser {
    // SVG parser
    private var svgDocument: SVGImpl? = null

    private fun requireSvgDocument(): SVGImpl {
        return svgDocument!!
    }

    private var currentElement: SvgContainer? = null
    private var enableInternalEntities = true
    private var externalFileResolver: SVGExternalFileResolver? = null

    // For handling elements we don't support
    private var ignoring = false
    private var ignoreDepth = 0

    // For handling <title> and <desc>
    private var inMetadataElement = false
    private var metadataTag: SVGElem? = null
    private var metadataElementContents: StringBuilder? = null

    // For handling <style>
    private var inStyleElement = false
    private var styleElementContents: StringBuilder? = null

    private fun requireCurrentElement(): SvgContainer {
        return currentElement
            ?: throw SVGParseException("Invalid document. Root element must be <svg>")
    }

    //=========================================================================
    // Main parser invocation methods
    //=========================================================================
    @Throws(SVGParseException::class)
    override fun parseStream(input: InputStream): SVGImpl {
        // Transparently handle zipped files (.svgz)
        var input = input
        if (!input.markSupported()) {
            // We need a buffered stream so we can use mark() and reset()
            input = input.buffered()
        }
        try {
            input.mark(3)
            val firstTwoBytes = input.read() + (input.read() shl 8)
            input.reset()
            if (firstTwoBytes == GZIPInputStream.GZIP_MAGIC) {
                // Looks like a zipped file.
                input = GZIPInputStream(input).buffered()
            }
        } catch (_: IOException) {
            // Not a zipped SVG. Fall through and try parsing it normally.
        }

        try {
            if (enableInternalEntities) {
                // We need to check for the presence of entities in the file so we can decide which parser to use.
                input.mark(ENTITY_WATCH_BUFFER_SIZE)
                // Read that number of bytes into a buffer so we
                val checkBuf = ByteArray(ENTITY_WATCH_BUFFER_SIZE)
                val n = input.read(checkBuf)
                // Read in the bytes as a string. We should probably use UTF-8 here, but the string
                // constructor that takes a charset requires SDK 9. We should be okay though, since we
                // are only looking for plain ASCII. And that'll be the same in any encoding.
                val preamble = String(checkBuf, 0, n)
                // Reset the stream so that the XML parsers can do their job.
                input.reset()
                if (preamble.contains("<!ENTITY ") || preamble.contains("<!ATTLIST ")) {
                    // Found something that looks like an entity definition.
                    // So we'll use the SAX parser which supports them.
                    debug {
                        "Switching to SAX parser to process entities"
                    }
                    parseUsingSAX(input)
                    return checkNotNull(svgDocument) { "svgDocument is null after SAX parse" }
                }
            }

            // Use the (faster) XmlPullParser
            parseUsingXmlPullParser(input)
            return checkNotNull(svgDocument) { "svgDocument is null after XmlPullParser parse" }
        } catch (e: IOException) {
            Log.e(
                TAG,
                "Error occurred while performing check for entities.  File may not be parsed correctly if it contains entity definitions.",
                e
            )
            parseUsingXmlPullParser(input)
            return checkNotNull(svgDocument) { "svgDocument is null after fallback parse" }
        } finally {
            try {
                input.close()
            } catch (_: IOException) {
                Log.e(TAG, "Exception thrown closing input stream")
            }
        }
    }

    //=========================================================================
    // Attribute setters
    //=========================================================================
    override fun setInternalEntitiesEnabled(enable: Boolean): SVGParser {
        enableInternalEntities = enable
        return this
    }

    override fun setExternalFileResolver(fileResolver: SVGExternalFileResolver?): SVGParser {
        externalFileResolver = fileResolver
        return this
    }


    //=========================================================================
    // XmlPullParser parsing
    //=========================================================================
    /*
    * Implements the SAX Attributes class so that our parser can share a common attributes object
    */
    private class XPPAttributesWrapper(private val parser: XmlPullParser) : Attributes {
        override fun getLength(): Int {
            return parser.attributeCount
        }

        override fun getURI(index: Int): String? {
            return parser.getAttributeNamespace(index)
        }

        override fun getLocalName(index: Int): String? {
            return parser.getAttributeName(index)
        }

        override fun getQName(index: Int): String? {
            var qName = parser.getAttributeName(index)
            val prefix = parser.getAttributePrefix(index)
            if (prefix != null) {
                qName = buildString {
                    append(prefix)
                    append(':')
                    append(qName)
                }
            }
            return qName
        }

        override fun getValue(index: Int): String? {
            return parser.getAttributeValue(index)
        }

        // Not used, and not implemented
        override fun getType(index: Int): String? {
            return null
        }

        override fun getIndex(uri: String?, localName: String?): Int {
            return -1
        }

        override fun getIndex(qName: String?): Int {
            return -1
        }

        override fun getType(uri: String?, localName: String?): String? {
            return null
        }

        override fun getType(qName: String?): String? {
            return null
        }

        override fun getValue(uri: String?, localName: String?): String? {
            return null
        }

        override fun getValue(qName: String?): String? {
            return null
        }
    }

    @Throws(SVGParseException::class)
    private fun parseUsingXmlPullParser(inputStream: InputStream) {
        try {
            val parser = Xml.newPullParser()
            val attributes = XPPAttributesWrapper(parser)

            parser.setFeature(XmlPullParser.FEATURE_PROCESS_DOCDECL, false)
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, true)
            parser.setInput(inputStream, null)

            var eventType = parser.eventType
            while (eventType != XmlPullParser.END_DOCUMENT) {
                when (eventType) {
                    XmlPullParser.START_DOCUMENT -> startDocument()
                    XmlPullParser.START_TAG -> {
                        val localName = parser.name
                        var qName = localName
                        val prefix = parser.prefix
                        if (prefix != null) {
                            qName = "$prefix:$qName"
                        }
                        startElement(parser.namespace, localName, qName, attributes)
                    }

                    XmlPullParser.END_TAG -> {
                        val localName = parser.name
                        var qName = localName
                        val prefix = parser.prefix
                        if (prefix != null) {
                            qName = "$prefix:$qName"
                        }
                        endElement(parser.namespace, localName, qName)
                    }

                    XmlPullParser.TEXT -> {
                        val startAndLength = IntArray(2)
                        val text = parser.getTextCharacters(startAndLength)
                        text(text, startAndLength[0], startAndLength[1])
                    }

                    XmlPullParser.ENTITY_REF -> text(parser.text)
                    XmlPullParser.CDSECT -> text(parser.text)
                    XmlPullParser.PROCESSING_INSTRUCTION -> {
                        val scan = TextScanner(parser.text)
                        val instr = scan.requireNextToken()
                        handleProcessingInstruction(
                            instruction = instr,
                            attributes = parseProcessingInstructionAttributes(scan)
                        )
                    }
                }
                eventType = parser.nextToken()
            }
            endDocument()
        } catch (e: XmlPullParserException) {
            throw SVGParseException("XML parser problem", e)
        } catch (e: IOException) {
            throw SVGParseException("Stream error", e)
        }
    }


    //=========================================================================
    // SAX parsing method and handler class
    //=========================================================================
    @Throws(SVGParseException::class)
    private fun parseUsingSAX(`is`: InputStream?) {
        try {
            // Invoke the SAX XML parser on the input.
            val spf = SAXParserFactory.newInstance()

            spf.setFeature("http://xml.org/sax/features/external-general-entities", false)
            spf.setFeature("http://xml.org/sax/features/external-parameter-entities", false)

            val sp = spf.newSAXParser()
            val xr = sp.xmlReader

            val handler = SAXHandler()
            xr.contentHandler = handler
            xr.setProperty("http://xml.org/sax/properties/lexical-handler", handler)

            xr.parse(InputSource(`is`))
        } catch (e: ParserConfigurationException) {
            throw SVGParseException("XML parser problem", e)
        } catch (e: SAXException) {
            throw SVGParseException("SVG parse error", e)
        } catch (e: IOException) {
            throw SVGParseException("Stream error", e)
        }
    }


    private inner class SAXHandler : DefaultHandler2() {
        override fun startDocument() {
            this@SVGParserImpl.startDocument()
        }


        @Throws(SAXException::class)
        override fun startElement(
            uri: String?,
            localName: String,
            qName: String?,
            attributes: Attributes
        ) {
            this@SVGParserImpl.startElement(uri, localName, qName, attributes)
        }


        @Throws(SAXException::class)
        override fun characters(ch: CharArray, start: Int, length: Int) {
            this@SVGParserImpl.text(ch = ch, start = start, length = length)
        }

        /*
        @Override
        public void comment(char[] ch, int start, int length) throws SAXException
        {
            SVGParser.this.text(new String(ch, start, length));
        }
         */

        @Throws(SAXException::class)
        override fun endElement(uri: String?, localName: String, qName: String) {
            this@SVGParserImpl.endElement(uri, localName, qName)
        }


        override fun endDocument() {
            this@SVGParserImpl.endDocument()
        }


        override fun processingInstruction(target: String, data: String) {
            val scan = TextScanner(data)
            val attributes = parseProcessingInstructionAttributes(scan)
            handleProcessingInstruction(target, attributes)
        }
    }


    //=========================================================================
    // Parser event classes used by both XML parser implementations
    //=========================================================================
    private fun startDocument() {
        svgDocument = SVGImpl(enableInternalEntities, externalFileResolver)
    }

    @Throws(SVGParseException::class)
    private fun startElement(
        uri: String?,
        localName: String,
        qName: String?,
        attributes: Attributes
    ) {
        if (ignoring) {
            ignoreDepth++
            return
        }
        if (SVG_NAMESPACE != uri && "" != uri) {
            return
        }

        val tag = localName.ifEmpty { qName }

        when (val elem = SVGElem.fromString(tag)) {
            SVGElem.svg -> svg(attributes)
            SVGElem.g -> g(attributes)
            SVGElem.defs -> defs(attributes)
            SVGElem.a -> a(attributes)
            SVGElem.use -> use(attributes)
            SVGElem.path -> path(attributes)
            SVGElem.rect -> rect(attributes)
            SVGElem.circle -> circle(attributes)
            SVGElem.ellipse -> ellipse(attributes)
            SVGElem.line -> line(attributes)
            SVGElem.polyline -> polyline(attributes)
            SVGElem.polygon -> polygon(attributes)
            SVGElem.text -> text(attributes)
            SVGElem.tspan -> tspan(attributes)
            SVGElem.tref -> tref(attributes)
            SVGElem.switch -> switch(attributes)
            SVGElem.symbol -> symbol(attributes)
            SVGElem.marker -> marker(attributes)
            SVGElem.linearGradient -> linearGradient(attributes)
            SVGElem.radialGradient -> radialGradient(attributes)
            SVGElem.stop -> stop(attributes)
            SVGElem.filter -> filter(attributes)
            SVGElem.feBlend -> feBlend(attributes)
            SVGElem.feColorMatrix -> feColorMatrix(attributes)
            SVGElem.feComponentTransfer -> feComponentTransfer(attributes)
            SVGElem.feFuncA -> feFunc(attributes, FeFunc.Channel.A)
            SVGElem.feFuncB -> feFunc(attributes, FeFunc.Channel.B)
            SVGElem.feFuncG -> feFunc(attributes, FeFunc.Channel.G)
            SVGElem.feFuncR -> feFunc(attributes, FeFunc.Channel.R)
            SVGElem.feConvolveMatrix -> feConvolveMatrix(attributes)
            SVGElem.feComposite -> feComposite(attributes)
            SVGElem.feDiffuseLighting -> feDiffuseLighting(attributes)
            SVGElem.feDisplacementMap -> feDisplacementMap(attributes)
            SVGElem.feDistantLight -> feDistantLight(attributes)
            SVGElem.fePointLight -> fePointLight(attributes)
            SVGElem.feSpecularLighting -> feSpecularLighting(attributes)
            SVGElem.feSpotLight -> feSpotLight(attributes)
            SVGElem.feFlood -> feFlood(attributes)
            SVGElem.feGaussianBlur -> feGaussianBlur(attributes)
            SVGElem.feImage -> feImage(attributes)
            SVGElem.feMerge -> feMerge(attributes)
            SVGElem.feMergeNode -> feMergeNode(attributes)
            SVGElem.feMorphology -> feMorphology(attributes)
            SVGElem.feOffset -> feOffset(attributes)
            SVGElem.feTurbulence -> feTurbulence(attributes)
            SVGElem.feTile -> feTile(attributes)
            SVGElem.title, SVGElem.desc -> {
                inMetadataElement = true
                metadataTag = elem
            }

            SVGElem.clipPath -> clipPath(attributes)
            SVGElem.textPath -> textPath(attributes)
            SVGElem.pattern -> pattern(attributes)
            SVGElem.image -> image(attributes)
            SVGElem.view -> view(attributes)
            SVGElem.mask -> mask(attributes)
            SVGElem.style -> style(attributes)
            SVGElem.solidColor -> solidColor(attributes)
            else -> {
                ignoring = true
                ignoreDepth = 1
            }
        }
    }


    @Throws(SVGParseException::class)
    private fun text(characters: String) {
        if (ignoring) {
            return
        }

        if (inMetadataElement) {
            val metadataElementContents = metadataElementContents ?: StringBuilder(characters.length).also {
                metadataElementContents = it
            }
            metadataElementContents.append(characters)
        } else if (inStyleElement) {
            val styleElementContents = styleElementContents ?: StringBuilder(characters.length).also {
                styleElementContents = it
            }
            styleElementContents.append(characters)
        } else if (currentElement is TextContainer) {
            appendToTextContainer(characters)
        }
    }

    @Throws(SVGParseException::class)
    private fun text(ch: CharArray, start: Int, length: Int) {
        if (ignoring) {
            return
        }

        if (inMetadataElement) {
            val metadataElementContents = metadataElementContents ?: StringBuilder(length).also {
                metadataElementContents = it
            }
            metadataElementContents.appendRange(ch, start, start + length)
        } else if (inStyleElement) {
            val styleElementContents = styleElementContents ?: StringBuilder(length).also {
                styleElementContents = it
            }
            styleElementContents.appendRange(ch, start, start + length)
        } else if (currentElement is TextContainer) {
            appendToTextContainer(String(ch, start, length))
        }
    }


    @Throws(SVGParseException::class)
    private fun appendToTextContainer(characters: String) {
        // The parser can pass us several text nodes in a row. If this happens, we
        // want to collapse them all into one SVGBase.TextSequence node
        val parent = currentElement as SvgConditionalContainer
        val numOlderSiblings = parent.getChildren().size
        val previousSibling =
            if (numOlderSiblings == 0) null else parent.getChildren()[numOlderSiblings - 1]
        if (previousSibling is TextSequence) {
            // Last sibling was a TextSequence also, so merge them.
            previousSibling.text += characters
        } else {
            // Add a new TextSequence to the child node list
            parent.addChild(TextSequence(characters))
        }
    }

    @Throws(SVGParseException::class)
    private fun endElement(uri: String?, localName: String, qName: String) {
        if (ignoring) {
            if (--ignoreDepth == 0) {
                ignoring = false
            }
            return
        }

        if (SVG_NAMESPACE != uri && "" != uri) {
            return
        }

        val tag: String = localName.ifEmpty { qName }
        when (SVGElem.fromString(tag)) {
            SVGElem.title,
            SVGElem.desc -> {
                inMetadataElement = false
                val metadataElementContents = metadataElementContents
                if (metadataElementContents != null) {
                    val svgDocument = requireSvgDocument()
                    when (metadataTag) {
                        SVGElem.title -> {
                            svgDocument.setTitle(metadataElementContents.toString())
                        }

                        SVGElem.desc -> {
                            svgDocument.setDesc(metadataElementContents.toString())
                        }

                        else -> {}
                    }
                    metadataElementContents.setLength(0)
                }
                return
            }

            SVGElem.style -> {
                val styleElementContents = styleElementContents
                if (styleElementContents != null) {
                    inStyleElement = false
                    parseCSSStyleSheet(styleElementContents.toString())
                    styleElementContents.setLength(0)
                    return
                }
            }

            SVGElem.svg,
            SVGElem.g,
            SVGElem.defs,
            SVGElem.a,
            SVGElem.use,
            SVGElem.image,
            SVGElem.text,
            SVGElem.tspan,
            SVGElem.switch,
            SVGElem.symbol,
            SVGElem.marker,
            SVGElem.linearGradient,
            SVGElem.radialGradient,
            SVGElem.stop,
            SVGElem.clipPath,
            SVGElem.textPath,
            SVGElem.pattern,
            SVGElem.view,
            SVGElem.mask,
            SVGElem.solidColor,
            SVGElem.filter,
            SVGElem.feBlend,
            SVGElem.feColorMatrix,
            SVGElem.feComponentTransfer,
            SVGElem.feFuncA,
            SVGElem.feFuncB,
            SVGElem.feFuncG,
            SVGElem.feFuncR,
            SVGElem.feConvolveMatrix,
            SVGElem.feComposite,
            SVGElem.feDiffuseLighting,
            SVGElem.feDisplacementMap,
            SVGElem.feDistantLight,
            SVGElem.fePointLight,
            SVGElem.feSpecularLighting,
            SVGElem.feSpotLight,
            SVGElem.feFlood,
            SVGElem.feGaussianBlur,
            SVGElem.feMerge,
            SVGElem.feMergeNode,
            SVGElem.feMorphology,
            SVGElem.feOffset,
            SVGElem.feTurbulence,
            SVGElem.feTile -> {
                val elem = currentElement
                checkState(elem != null) {
                    // This situation has been reported by a user. But I am unable to reproduce this fault.
                    // If you can get this error please add your SVG file to https://github.com/BigBadaboom/androidsvg/issues/177
                    // For now we'll return a parse exception for consistency (instead of NPE).
                    throw SVGParseException(
                        String.format(
                            "Unbalanced end element </%s> found",
                            tag
                        )
                    )
                }
                currentElement = elem.parent
            }

            else -> {
                // do nothing
            }
        }
    }


    private fun endDocument() {
        // Dump document
        if (BuildConfig.DEBUG) {
            dumpNode(requireSvgDocument().rootElement, "")
        }
    }

    private fun handleProcessingInstruction(
        instruction: String,
        attributes: Map<String, String>
    ) {
        if (instruction == XML_STYLESHEET_PROCESSING_INSTRUCTION && externalFileResolver != null) {
            // If a "type" is specified, make sure it is the CSS type
            var attr = attributes[XML_STYLESHEET_ATTR_TYPE]
            if (attr != null && CSSParser.CSS_MIME_TYPE != attributes["type"]) return
            // Alternate stylesheets are not supported
            attr = attributes[XML_STYLESHEET_ATTR_ALTERNATE]
            if (attr != null && XML_STYLESHEET_ATTR_ALTERNATE_NO != attributes["alternate"]) return

            attr = attributes[XML_STYLESHEET_ATTR_HREF]
            if (attr != null) {
                var css = externalFileResolver!!.resolveCSSStyleSheet(attr) ?: return

                val mediaAttr = attributes[XML_STYLESHEET_ATTR_MEDIA]
                if (mediaAttr != null && XML_STYLESHEET_ATTR_MEDIA_ALL != mediaAttr.trimLowerThanSpace()) {
                    css = "@media $mediaAttr { $css}"
                }

                parseCSSStyleSheet(css)
            }
        }
    }


    private fun parseProcessingInstructionAttributes(scan: TextScanner): Map<String, String> {
        val attributes = ArrayMap<String, String>()

        scan.skipWhitespace()
        var attrName = scan.nextToken('=')
        while (attrName != null) {
            scan.consume('=')
            val value = scan.nextQuotedString()
            attributes[attrName] = value

            scan.skipWhitespace()
            attrName = scan.nextToken('=')
        }
        return attributes
    }


    //=========================================================================
    private fun dumpNode(elem: SvgObject?, indent: String?) {
        var indent = indent
        if (!BuildConfig.DEBUG) return
        Log.d(TAG, indent + elem)
        if (elem is SvgConditionalContainer) {
            indent = "$indent  "
            elem.getChildren().forEachElement { child ->
                dumpNode(child, indent)
            }
        }
    }

    private inline fun debug(lazyMessage: () -> String) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, lazyMessage())
        }
    }

    //=========================================================================
    // Handlers for each SVG element
    //=========================================================================
    // <svg> element
    @Throws(SVGParseException::class)
    private fun svg(attributes: Attributes) {
        debug { "<svg>" }

        val currentElement = currentElement
        val obj = Svg()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesViewBox(obj, attributes)
        parseAttributesSVG(obj, attributes)
        if (currentElement == null) {
            svgDocument?.rootElement = obj
        } else {
            currentElement.addChild(obj)
        }
        this.currentElement = obj
    }

    private fun Attributes.getTrimmedValue(index: Int): String {
        return getValue(index).trimLowerThanSpace()
    }

    private fun Attributes.getSVGAttr(index: Int): SVGAttr {
        return SVGAttr.fromString(getLocalName(index))
    }

    private inline fun Attributes.forEachKeyValue(
        crossinline r: (index: Int, attr: SVGAttr, value: String) -> Unit
    ) {
        for (index in 0..<length) {
            r(
                index,
                getSVGAttr(index),
                getTrimmedValue(index)
            )
        }
    }

    @Throws(SVGParseException::class)
    private fun parseAttributesSVG(obj: Svg, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> obj.width = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <svg> element. width cannot be negative"
                )

                SVGAttr.height -> obj.height = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <svg> element. height cannot be negative"
                )

                SVGAttr.version -> obj.version = value
                else -> {}
            }
        }
    }


    //=========================================================================
    // <g> group element
    @Throws(SVGParseException::class)
    private fun g(attributes: Attributes) {
        debug { "<g>" }

        val currentElement = requireCurrentElement()
        val obj = Group()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    //=========================================================================
    // <defs> group element
    @Throws(SVGParseException::class)
    private fun defs(attributes: Attributes) {
        debug { "<defs>" }

        val currentElement = requireCurrentElement()
        val obj = Defs()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    //=========================================================================
    // <a> element
    @Throws(SVGParseException::class)
    private fun a(attributes: Attributes) {
        debug { "<a>" }

        val currentElement = requireCurrentElement()
        val obj = A()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesA(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    private fun parseAttributesA(obj: A, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <use> element
    @Throws(SVGParseException::class)
    private fun use(attributes: Attributes) {
        debug { "<use>" }

        val currentElement = requireCurrentElement()
        val obj = Use()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesUse(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesUse(obj: Use, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> {
                    obj.width = parseNonNegativeLength(
                        value,
                        "Invalid <use> element. width cannot be negative"
                    )
                }

                SVGAttr.height -> {
                    obj.height = parseNonNegativeLength(
                        value,
                        "Invalid <use> element. height cannot be negative"
                    )
                }

                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <image> element
    @Throws(SVGParseException::class)
    private fun image(attributes: Attributes) {
        debug { "<image>" }

        val currentElement = requireCurrentElement()
        val obj = Image()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesImage(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesImage(obj: Image, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.x -> {
                    obj.x = parseLength(value)
                }

                SVGAttr.y -> {
                    obj.y = parseLength(value)
                }

                SVGAttr.width -> {
                    obj.width = parseNonNegativeLength(
                        value,
                        "Invalid <image> element. width cannot be negative"
                    )
                }

                SVGAttr.height -> {
                    obj.height = parseNonNegativeLength(
                        value,
                        "Invalid <image> element. height cannot be negative"
                    )
                }

                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                SVGAttr.preserveAspectRatio -> {
                    parsePreserveAspectRatio(obj, value)
                }

                else -> {}
            }
        }
    }

    //=========================================================================
    // <path> element
    @Throws(SVGParseException::class)
    private fun path(attributes: Attributes) {
        debug { "<path>" }

        val currentElement = requireCurrentElement()
        val obj = Path()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesPath(obj, attributes)
        currentElement.addChild(obj)
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesPath(obj: Path, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.d -> obj.d = parsePath(value)
                SVGAttr.pathLength -> obj.pathLength = parseNonNegativeFloat(
                    value = value,
                    errorMessage = "Invalid <path> element. pathLength cannot be negative"
                )

                else -> {}
            }
        }
    }


    //=========================================================================
    // <rect> element
    @Throws(SVGParseException::class)
    private fun rect(attributes: Attributes) {
        debug { "<rect>" }

        val currentElement = requireCurrentElement()
        val obj = Rect()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesRect(obj, attributes)
        currentElement.addChild(obj)
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesRect(obj: Rect, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> {
                    obj.width = parseNonNegativeLength(
                        value,
                        "Invalid <rect> element. width cannot be negative"
                    )
                }

                SVGAttr.height -> {
                    obj.height = parseNonNegativeLength(
                        value,
                        "Invalid <rect> element. height cannot be negative"
                    )
                }

                SVGAttr.rx -> {
                    obj.rx = parseNonNegativeLength(
                        value,
                        "Invalid <rect> element. rx cannot be negative"
                    )
                }

                SVGAttr.ry -> {
                    obj.ry = parseNonNegativeLength(
                        value,
                        "Invalid <rect> element. ry cannot be negative"
                    )
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <circle> element
    @Throws(SVGParseException::class)
    private fun circle(attributes: Attributes) {
        debug { "<circle>" }

        val currentElement = requireCurrentElement()
        val obj = Circle()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesCircle(obj, attributes)
        currentElement.addChild(obj)
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesCircle(obj: Circle, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.cx -> obj.cx = parseLength(value)
                SVGAttr.cy -> obj.cy = parseLength(value)
                SVGAttr.r -> obj.r = parseNonNegativeLength(
                    value,
                    "Invalid <circle> element. r cannot be negative"
                )

                else -> {}
            }
        }
    }


    //=========================================================================
    // <ellipse> element
    @Throws(SVGParseException::class)
    private fun ellipse(attributes: Attributes) {
        debug { "<ellipse>" }

        val currentElement = requireCurrentElement()
        val obj = Ellipse()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesEllipse(obj, attributes)
        currentElement.addChild(obj)
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesEllipse(obj: Ellipse, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.cx -> obj.cx = parseLength(value)
                SVGAttr.cy -> obj.cy = parseLength(value)
                SVGAttr.rx -> {
                    obj.rx = parseNonNegativeLength(
                        value,
                        "Invalid <ellipse> element. rx cannot be negative"
                    )
                }

                SVGAttr.ry -> {
                    obj.ry = parseNonNegativeLength(
                        value,
                        "Invalid <ellipse> element. ry cannot be negative"
                    )
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <line> element
    @Throws(SVGParseException::class)
    private fun line(attributes: Attributes) {
        debug { "<line>" }

        val currentElement = requireCurrentElement()
        val obj = Line()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesLine(obj, attributes)
        currentElement.addChild(obj)
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesLine(obj: Line, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x1 -> obj.x1 = parseLength(value)
                SVGAttr.y1 -> obj.y1 = parseLength(value)
                SVGAttr.x2 -> obj.x2 = parseLength(value)
                SVGAttr.y2 -> obj.y2 = parseLength(value)
                else -> {}
            }
        }
    }


    //=========================================================================
    // <polyline> element
    @Throws(SVGParseException::class)
    private fun polyline(attributes: Attributes) {
        debug { "<polyline>" }

        val currentElement = requireCurrentElement()
        val obj = PolyLine()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesPolyLine(obj, attributes, "polyline")
        currentElement.addChild(obj)
    }


    /*
    *  Parse the "points" attribute. Used by both <polyline> and <polygon>.
    */
    @Throws(SVGParseException::class)
    private fun parseAttributesPolyLine(obj: PolyLine, attributes: Attributes, tag: String?) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.points -> {
                    val scan = TextScanner(value)
                    val points = MutableFloatList()
                    scan.skipWhitespace()

                    while (!scan.empty()) {
                        val x = scan.nextFloat()
                        checkState(!x.isNaN()) { "Invalid <$tag> points attribute. Non-coordinate content found in list." }
                        scan.skipCommaWhitespace()
                        val y = scan.nextFloat()
                        checkState(!y.isNaN()) { "Invalid <$tag> points attribute. There should be an even number of coordinates." }
                        scan.skipCommaWhitespace()
                        points.add(x)
                        points.add(y)
                    }

                    obj.points = points.toFloatArray()
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <polygon> element
    @Throws(SVGParseException::class)
    private fun polygon(attributes: Attributes) {
        debug { "<polygon>" }

        val currentElement = requireCurrentElement()
        val obj = Polygon()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesPolyLine(obj, attributes, "polygon") // reuse of polyline "points" parser
        currentElement.addChild(obj)
    }


    //=========================================================================
    // <text> element
    @Throws(SVGParseException::class)
    private fun text(attributes: Attributes) {
        debug { "<text>" }

        val currentElement = requireCurrentElement()
        val obj = Text()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesTextPosition(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesTextPosition(obj: TextPositionedContainer, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseLengthList(value)
                SVGAttr.y -> obj.y = parseLengthList(value)
                SVGAttr.dx -> obj.dx = parseLengthList(value)
                SVGAttr.dy -> obj.dy = parseLengthList(value)
                else -> {}
            }
        }
    }


    //=========================================================================
    // <tspan> element
    @Throws(SVGParseException::class)
    private fun tspan(attributes: Attributes) {
        debug { "<tspan>" }

        val currentElement = requireCurrentElement()
        checkState(currentElement is TextContainer) { "Invalid document. <tspan> elements are only valid inside <text> or other <tspan> elements." }
        val obj = TSpan()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesTextPosition(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
        obj.textRoot = if (currentElement is TextRoot) {
            currentElement
        } else {
            (currentElement as TextChild).textRoot
        }
    }


    //=========================================================================
    // <tref> element
    @Throws(SVGParseException::class)
    private fun tref(attributes: Attributes) {
        debug { "<tref>" }

        val currentElement = requireCurrentElement()
        checkState(currentElement is TextContainer) { "Invalid document. <tref> elements are only valid inside <text> or <tspan> elements." }
        val obj = TRef()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesTRef(obj, attributes)
        currentElement.addChild(obj)
        obj.textRoot = if (currentElement is TextRoot) {
            currentElement
        } else {
            (currentElement as TextChild).textRoot
        }
    }


    private fun parseAttributesTRef(obj: TRef, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <switch> element
    @Throws(SVGParseException::class)
    private fun switch(attributes: Attributes) {
        debug { "<switch>" }

        val currentElement = requireCurrentElement()
        val obj = Switch()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    private fun parseAttributesConditional(obj: SvgConditional, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.requiredFeatures -> obj.requiredFeatures = parseRequiredFeatures(value)
                SVGAttr.requiredExtensions -> obj.requiredExtensions = value
                SVGAttr.systemLanguage -> obj.systemLanguage = parseSystemLanguage(value)
                SVGAttr.requiredFormats -> obj.requiredFormats = parseRequiredFormats(value)
                SVGAttr.requiredFonts -> {
                    val fonts = parseFontFamily(value)
                    obj.requiredFonts = if (fonts != null) {
                        ArraySet(fonts)
                    } else {
                        emptySet()
                    }
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <symbol> element
    @Throws(SVGParseException::class)
    private fun symbol(attributes: Attributes) {
        debug { "<symbol>" }

        val currentElement = requireCurrentElement()
        val obj = Symbol()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesViewBox(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    //=========================================================================
    // <marker> element
    @Throws(SVGParseException::class)
    private fun marker(attributes: Attributes) {
        debug { "<marker>" }

        val currentElement = requireCurrentElement()
        val obj = Marker()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesViewBox(obj, attributes)
        parseAttributesMarker(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesMarker(obj: Marker, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.refX -> obj.refX = parseLength(value)
                SVGAttr.refY -> obj.refY = parseLength(value)
                SVGAttr.markerWidth -> {
                    obj.markerWidth = parseNonNegativeLength(
                        value,
                        "Invalid <marker> element. markerWidth cannot be negative"
                    )
                }

                SVGAttr.markerHeight -> {
                    obj.markerHeight = parseNonNegativeLength(
                        value,
                        "Invalid <marker> element. markerHeight cannot be negative"
                    )
                }

                SVGAttr.markerUnits -> when (value) {
                    "strokeWidth" -> {
                        obj.markerUnitsAreUser = false
                    }

                    "userSpaceOnUse" -> {
                        obj.markerUnitsAreUser = true
                    }

                    else -> {
                        throw SVGParseException("Invalid value for attribute markerUnits")
                    }
                }

                SVGAttr.orient -> obj.orient = if ("auto" == value) {
                    Float.NaN
                } else {
                    parseFloat(value)
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <linearGradient> element
    @Throws(SVGParseException::class)
    private fun linearGradient(attributes: Attributes) {
        debug { "<linearGradient>" }

        val currentElement = requireCurrentElement()
        val obj = SvgLinearGradient()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesGradient(obj, attributes)
        parseAttributesLinearGradient(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesGradient(obj: GradientElement, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.gradientUnits -> obj.gradientUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw SVGParseException("Invalid value for attribute gradientUnits")
                }

                SVGAttr.gradientTransform -> obj.gradientTransform = parseTransformList(value)
                SVGAttr.spreadMethod -> try {
                    obj.spreadMethod = GradientSpread.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid spreadMethod attribute. \"$value\" is not a valid value.")
                }

                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                else -> {}
            }
        }
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesLinearGradient(obj: SvgLinearGradient, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x1 -> obj.x1 = parseLength(value)
                SVGAttr.y1 -> obj.y1 = parseLength(value)
                SVGAttr.x2 -> obj.x2 = parseLength(value)
                SVGAttr.y2 -> obj.y2 = parseLength(value)
                else -> {}
            }
        }
    }


    //=========================================================================
    // <radialGradient> element
    @Throws(SVGParseException::class)
    private fun radialGradient(attributes: Attributes) {
        debug { "<radialGradient>" }

        val currentElement = requireCurrentElement()
        val obj = SvgRadialGradient()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesGradient(obj, attributes)
        parseAttributesRadialGradient(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesRadialGradient(obj: SvgRadialGradient, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.cx -> obj.cx = parseLength(value)
                SVGAttr.cy -> obj.cy = parseLength(value)
                SVGAttr.r -> obj.r = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <radialGradient> element. r cannot be negative"
                )

                SVGAttr.fx -> obj.fx = parseLength(value)
                SVGAttr.fy -> obj.fy = parseLength(value)
                SVGAttr.fr -> obj.fr = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <radialGradient> element. fr cannot be negative"
                )

                else -> {}
            }
        }
    }


    //=========================================================================
    // Gradient <stop> element
    @Throws(SVGParseException::class)
    private fun stop(attributes: Attributes) {
        debug { "<stop>" }

        val currentElement = requireCurrentElement()

        checkState(currentElement is GradientElement) {
            "Invalid document. <stop> elements are only valid inside <linearGradient> or <radialGradient> elements."
        }

        val obj = Stop()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesStop(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesStop(obj: Stop, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.offset -> obj.offset = parseGradientOffset(value)
                else -> {}
            }
        }
    }


    @Throws(SVGParseException::class)
    private fun parseGradientOffset(value: String): Float {
        checkState(value.isNotEmpty()) { "Invalid offset value in <stop> (empty string)" }
        var end = value.length
        var isPercent = false

        if (value[value.length - 1] == '%') {
            end -= 1
            isPercent = true
        }

        try {
            var scalar: Float = parseFloat(value, 0, end)
            if (isPercent) {
                scalar /= 100f
            }
            return clamp(scalar, 0f, 100f)
        } catch (e: NumberFormatException) {
            throw SVGParseException("Invalid offset value in <stop>: $value", e)
        }
    }


    //=========================================================================
    // <solidColor> element
    @Throws(SVGParseException::class)
    private fun solidColor(attributes: Attributes) {
        debug { "<solidColor>" }

        val currentElement = requireCurrentElement()
        val obj = SolidColor()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    //=========================================================================
    // <clipPath> element
    @Throws(SVGParseException::class)
    private fun clipPath(attributes: Attributes) {
        debug { "<clipPath>" }

        val currentElement = requireCurrentElement()
        val obj = ClipPath()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesTransform(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesClipPath(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesClipPath(obj: ClipPath, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.clipPathUnits -> obj.clipPathUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw SVGParseException("Invalid value for attribute clipPathUnits")
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <textPath> element
    @Throws(SVGParseException::class)
    private fun textPath(attributes: Attributes) {
        debug { "<textPath>" }

        val currentElement = requireCurrentElement()
        val obj = TextPath()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesTextPath(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
        obj.textRoot = if (currentElement is TextRoot) {
            currentElement
        } else {
            (currentElement as TextChild).textRoot
        }
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesTextPath(obj: TextPath, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                SVGAttr.startOffset -> obj.startOffset = parseLength(value)
                else -> {}
            }
        }
    }


    //=========================================================================
    // <pattern> element
    @Throws(SVGParseException::class)
    private fun pattern(attributes: Attributes) {
        debug { "<pattern>" }

        val currentElement = requireCurrentElement()
        val obj = Pattern()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesViewBox(obj, attributes)
        parseAttributesPattern(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesPattern(obj: SvgObject.Pattern, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.patternUnits -> obj.patternUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw SVGParseException("Invalid value for attribute patternUnits")
                }

                SVGAttr.patternContentUnits -> obj.patternContentUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw SVGParseException("Invalid value for attribute patternContentUnits")
                }

                SVGAttr.patternTransform -> obj.patternTransform = parseTransformList(value)
                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> obj.width = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <pattern> element. width cannot be negative"
                )

                SVGAttr.height -> obj.height = parseNonNegativeLength(
                    value = value,
                    errorMessage = "Invalid <pattern> element. height cannot be negative"
                )

                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // <view> element
    @Throws(SVGParseException::class)
    private fun view(attributes: Attributes) {
        debug { "<view>" }

        val currentElement = requireCurrentElement()
        val obj = View()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesViewBox(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    //=========================================================================
    // <mask> element
    @Throws(SVGParseException::class)
    private fun mask(attributes: Attributes) {
        debug { "<mask>" }

        val currentElement = requireCurrentElement()
        val obj = Mask()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesConditional(obj, attributes)
        parseAttributesMask(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(SVGParseException::class)
    private fun parseAttributesMask(obj: Mask, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.maskUnits -> obj.maskUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw SVGParseException("Invalid value for attribute maskUnits")
                }

                SVGAttr.maskContentUnits -> obj.maskContentUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw SVGParseException("Invalid value for attribute maskContentUnits")
                }

                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> {
                    obj.width = parseNonNegativeLength(
                        value,
                        "Invalid <mask> element. width cannot be negative"
                    )
                }

                SVGAttr.height -> {
                    obj.height = parseNonNegativeLength(
                        value,
                        "Invalid <mask> element. height cannot be negative"
                    )
                }

                else -> {}
            }
        }
    }


    //=========================================================================
    // Attribute parsing
    //=========================================================================
    @Throws(SVGParseException::class)
    private fun parseAttributesCore(obj: SvgElementBase, attributes: Attributes) {
        var k = 0
        for (i in 0..<attributes.length) {
            when (SVGAttr.fromString(attributes.getQName(i))) {
                SVGAttr.id, -> {
                    obj.id = attributes.getTrimmedValue(i)
                    k++
                }

                SVGAttr.space -> {
                    obj.spacePreserve = when (val value = attributes.getTrimmedValue(i)) {
                        "default" -> false
                        "preserve" -> true
                        else -> throw SVGParseException("Invalid value for \"xml:space\" attribute: $value")
                    }
                    k++
                }

                else -> {}
            }

            if (k>= 2) {
                break
            }
        }
    }

    /*
    * Parse the style attributes for an element.
    */
    private fun parseAttributesStyle(obj: SvgElementBase, attributes: Attributes) {
        attributes.forEachKeyValue { i, attr, value ->
            val localName = attributes.getLocalName(i)
            if (value.isEmpty()) {  // Empty attribute. Ignore it.
                return@forEachKeyValue
            }

            //boolean  inherit = val.equals("inherit");   // NYI
            when (attr) {
                SVGAttr.style -> parseStyle(obj, value)
                SVGAttr.`class` -> obj.classNames = CSSParser.parseClassAttribute(value)
                else -> {
                    val baseStyle = obj.baseStyle ?: Style().also {
                        obj.baseStyle = it
                    }
                    Style.processStyleProperty(
                        style = baseStyle,
                        localName = localName,
                        value = value,
                        isFromAttribute = true
                    )
                }
            }
        }
    }

    private val blockCommentsMatcher: Matcher = PATTERN_BLOCK_COMMENTS.matcher("")

    /*
    * Parse the 'style' attribute.
    */
    private fun parseStyle(obj: SvgElementBase, style: String) {
        val scan = CSSTextScanner(
            input = blockCommentsMatcher.reset(style).replaceAll("")
        ) // regex strips block comments

        while (!scan.empty()) {
            scan.skipWhitespace()
            val propertyName = scan.nextIdentifier()
            scan.skipWhitespace()
            if (scan.consume(';')) continue  // Handle stray/extra separators gracefully

            if (!scan.consume(':')) break // Unrecoverable parse error

            scan.skipWhitespace()
            val propertyValue = scan.nextPropertyValue() ?: continue
            // Empty value. Just ignore this property and keep parsing

            scan.skipWhitespace()
            if (scan.empty() || scan.consume(';')) {
                val style = obj.style ?: Style().also {
                    obj.style = it
                }
                Style.processStyleProperty(
                    style = style,
                    localName = propertyName,
                    value = propertyValue,
                    isFromAttribute = false
                )
                scan.skipWhitespace()
            }
        }
    }

    @Throws(SVGParseException::class)
    private fun parseAttributesViewBox(obj: SvgViewBoxContainer, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.viewBox -> obj.viewBox = parseViewBox(value)
                SVGAttr.preserveAspectRatio -> parsePreserveAspectRatio(obj, value)
                else -> {}
            }
        }
    }

    @Throws(SVGParseException::class)
    private fun parseAttributesTransform(obj: HasTransform, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            if (attr == SVGAttr.transform) {
                obj.setTransform(parseTransformList(value))
            }
        }
    }

    @Throws(SVGParseException::class)
    private fun parseTransformList(value: String): Matrix {
        val matrix = Matrix()

        val scan = TextScanner(value)
        scan.skipWhitespace()

        while (!scan.empty()) {
            val cmd = scan.nextFunction()
                ?: throw SVGParseException("Bad transform function encountered in transform list: $value")

            when (cmd) {
                "matrix" -> {
                    scan.skipWhitespace()
                    val a = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    val b = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    val c = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    val d = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    val e = scan.nextFloat()
                    scan.skipCommaWhitespace()
                    val f = scan.nextFloat()
                    scan.skipWhitespace()

                    checkState(!f.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                    val m = Matrix()
                    m.setValues(floatArrayOf(a, c, e, b, d, f, 0f, 0f, 1f))
                    matrix.preConcat(m)
                }

                "translate" -> {
                    scan.skipWhitespace()
                    val tx = scan.nextFloat()
                    val ty = scan.possibleNextFloat()
                    scan.skipWhitespace()

                    checkState(!tx.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                    if (ty.isNaN()) matrix.preTranslate(tx, 0f)
                    else matrix.preTranslate(tx, ty)
                }

                "scale" -> {
                    scan.skipWhitespace()
                    val sx = scan.nextFloat()
                    val sy = scan.possibleNextFloat()
                    scan.skipWhitespace()

                    checkState(!sx.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                    if (sy.isNaN()) matrix.preScale(sx, sx)
                    else matrix.preScale(sx, sy)
                }

                "rotate" -> {
                    scan.skipWhitespace()
                    val ang = scan.nextFloat()
                    val cx = scan.possibleNextFloat()
                    val cy = scan.possibleNextFloat()
                    scan.skipWhitespace()

                    checkState(!ang.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                    if (cx.isNaN()) {
                        matrix.preRotate(ang)
                    } else if (!cy.isNaN()) {
                        matrix.preRotate(ang, cx, cy)
                    } else {
                        throw SVGParseException("Invalid transform list: $value")
                    }
                }

                "skewX" -> {
                    scan.skipWhitespace()
                    val ang = scan.nextFloat()
                    scan.skipWhitespace()

                    checkState(!ang.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                    matrix.preSkew(tan(ang.toRadians()), 0f)
                }

                "skewY" -> {
                    scan.skipWhitespace()
                    val ang = scan.nextFloat()
                    scan.skipWhitespace()

                    checkState(!ang.isNaN() && scan.consume(')')) { "Invalid transform list: $value" }

                    matrix.preSkew(0f, tan(ang.toRadians()))
                }

                else -> throw SVGParseException("Invalid transform list fn: $cmd)")
            }

            if (scan.empty()) break
            scan.skipCommaWhitespace()
        }

        return matrix
    }


    //=========================================================================
    // Parsing <style> element. Very basic CSS parser.
    //=========================================================================
    @Throws(SVGParseException::class)
    private fun style(attributes: Attributes) {
        debug { "<style>" }

        requireCurrentElement()

        // Check style sheet is in CSS format
        var isTextCSS = true
        var media = "all"

        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.type -> isTextCSS = value == CSSParser.CSS_MIME_TYPE
                SVGAttr.media -> media = value
                else -> {}
            }
        }

        if (isTextCSS && CSSParser.mediaMatches(media, CSSParser.MediaType.screen)) {
            inStyleElement = true
        } else {
            ignoring = true
            ignoreDepth = 1
        }
    }


    private fun parseCSSStyleSheet(sheet: String) {
        val parser = CSSParser(
            deviceMediaType = CSSParser.MediaType.screen,
            source = CSSParser.Source.Document,
            externalFileResolver = externalFileResolver
        )
        requireSvgDocument().addCSSRules(ruleset = parser.parse(sheet))
    }

    //=========================================================================
    // <filter> element
    @Throws(SVGParseException::class)
    private fun filter(attributes: Attributes) {
        debug { "<filter>" }

        val currentElement = requireCurrentElement()
        val obj = Filter()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilter(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    private fun parseAttributesFilter(obj: Filter, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.filterUnits -> obj.filterUnitsAreUser = value == "userSpaceOnUse"
                SVGAttr.primitiveUnits -> obj.primitiveUnitsAreUser = value == "userSpaceOnUse"
                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> obj.width = parseLength(value)
                SVGAttr.height -> obj.height = parseLength(value)
                else -> {}
            }
        }
    }

    private fun parseAttributesFilterPrimitive(obj: FilterPrimitive, attributes: Attributes) {
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseLength(value)
                SVGAttr.y -> obj.y = parseLength(value)
                SVGAttr.width -> obj.width = parseLength(value)
                SVGAttr.height -> obj.height = parseLength(value)
                SVGAttr.result -> obj.result = value
                SVGAttr.`in` -> obj.`in` = value
                else -> {}
            }
        }
    }

    @Throws(SVGParseException::class)
    private fun feBlend(attributes: Attributes) {
        debug { "<feBlend>" }
        val currentElement = requireCurrentElement()
        val obj = FeBlend()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.in2 -> obj.in2 = value
                SVGAttr.mode -> obj.mode = if (value.isEmpty()) FeBlendMode.normal else try {
                    FeBlendMode.valueOf(value.lowercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid blend mode: $value")
                }
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feColorMatrix(attributes: Attributes) {
        debug { "<feColorMatrix>" }
        val currentElement = requireCurrentElement()
        val obj = FeColorMatrix()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.type -> obj.type = if (value.isEmpty()) FeColorMatrixType.matrix else try {
                    FeColorMatrixType.valueOf(value.lowercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid matrix type: $value")
                }
                SVGAttr.values -> obj.values = parseFloatList(value)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feComponentTransfer(attributes: Attributes) {
        debug { "<feComponentTransfer>" }
        val currentElement = requireCurrentElement()
        val obj = FeComponentTransfer()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feFunc(attributes: Attributes, channel: FeFunc.Channel) {
        debug { "<feFunc${channel.name}>" }
        val currentElement = requireCurrentElement()
        val obj = FeFunc()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        obj.channel = channel
        parseAttributesCore(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.type -> obj.type = if (value.isEmpty()) FeFuncType.identity else try {
                    FeFuncType.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid feFunc type: $value")
                }
                SVGAttr.tableValues -> obj.tableValues = parseFloatList(value)
                SVGAttr.slope -> obj.slope = parseFloat(value)
                SVGAttr.intercept -> obj.intercept = parseFloat(value)
                SVGAttr.amplitude -> obj.amplitude = parseFloat(value)
                SVGAttr.exponent -> obj.exponent = parseFloat(value)
                SVGAttr.offset -> obj.offset = parseFloat(value)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feConvolveMatrix(attributes: Attributes) {
        debug { "<feConvolveMatrix>" }
        val currentElement = requireCurrentElement()
        val obj = FeConvolveMatrix()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.order -> {
                    val values = parseFloatList(value)
                    obj.orderX = values.getOrNull(0)?.toInt() ?: 3
                    obj.orderY = values.getOrNull(1)?.toInt() ?: obj.orderX
                }
                SVGAttr.kernelMatrix -> obj.kernelMatrix = parseFloatList(value)
                SVGAttr.divisor -> obj.divisor = parseFloat(value)
                SVGAttr.bias -> obj.bias = parseFloat(value)
                SVGAttr.targetX -> obj.targetX = parseFloat(value).toInt()
                SVGAttr.targetY -> obj.targetY = parseFloat(value).toInt()
                SVGAttr.edgeMode -> obj.edgeMode = if (value.isEmpty()) ConvolveMatrixEdgeMode.duplicate else try {
                    ConvolveMatrixEdgeMode.valueOf(value.lowercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid matrix edge mode: $value")
                }
                SVGAttr.preserveAlpha -> obj.preserveAlpha = value.equals("true", ignoreCase = true)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feComposite(attributes: Attributes) {
        debug { "<feComposite>" }
        val currentElement = requireCurrentElement()
        val obj = FeComposite()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.in2 -> obj.in2 = value
                SVGAttr.operator -> obj.operator = if (value.isEmpty()) FeCompositeOperator.over else try {
                    FeCompositeOperator.valueOf(value.lowercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid FeComposite operator: $value")
                }
                SVGAttr.k1 -> obj.k1 = parseFloat(value)
                SVGAttr.k2 -> obj.k2 = parseFloat(value)
                SVGAttr.k3 -> obj.k3 = parseFloat(value)
                SVGAttr.k4 -> obj.k4 = parseFloat(value)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feDisplacementMap(attributes: Attributes) {
        debug { "<feDisplacementMap>" }
        val currentElement = requireCurrentElement()
        val obj = FeDisplacementMap()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.in2 -> obj.in2 = value
                SVGAttr.scale -> obj.scale = parseFloat(value)
                SVGAttr.xChannelSelector -> obj.xChannelSelector = if (value.isEmpty()) FeChannelSelector.A else try {
                    FeChannelSelector.valueOf(value.uppercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid xChannelSelector attribute: $value")
                }
                SVGAttr.yChannelSelector -> obj.yChannelSelector = if (value.isEmpty()) FeChannelSelector.A else try {
                    FeChannelSelector.valueOf(value.uppercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid yChannelSelector attribute: $value")
                }
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feDiffuseLighting(attributes: Attributes) {
        debug { "<feDiffuseLighting>" }
        val currentElement = requireCurrentElement()
        val obj = FeDiffuseLighting()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.surfaceScale -> obj.surfaceScale = parseFloat(value)
                SVGAttr.diffuseConstant -> obj.diffuseConstant = parseFloat(value)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feDistantLight(attributes: Attributes) {
        debug { "<feDistantLight>" }
        val currentElement = requireCurrentElement()
        if (currentElement !is FeDiffuseLighting && currentElement !is FeSpecularLighting) {
            return
        }
        val obj = FeDistantLight()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.azimuth -> obj.azimuth = parseFloat(value)
                SVGAttr.elevation -> obj.elevation = parseFloat(value)
                else -> {}
            }
        }
        when (currentElement) {
            is FeDiffuseLighting -> currentElement.light = obj
            is FeSpecularLighting -> currentElement.light = obj
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun fePointLight(attributes: Attributes) {
        debug { "<fePointLight>" }
        val currentElement = requireCurrentElement()
        if (currentElement !is FeDiffuseLighting && currentElement !is FeSpecularLighting) {
            return
        }
        val obj = FePointLight()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseFloat(value)
                SVGAttr.y -> obj.y = parseFloat(value)
                SVGAttr.z -> obj.z = parseFloat(value)
                else -> {}
            }
        }
        when (currentElement) {
            is FeDiffuseLighting -> currentElement.light = obj
            is FeSpecularLighting -> currentElement.light = obj
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feSpecularLighting(attributes: Attributes) {
        debug { "<feSpecularLighting>" }
        val currentElement = requireCurrentElement()
        val obj = FeSpecularLighting()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.surfaceScale -> obj.surfaceScale = parseFloat(value)
                SVGAttr.specularConstant -> obj.specularConstant = parseFloat(value)
                SVGAttr.specularExponent -> obj.specularExponent = parseFloat(value)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feSpotLight(attributes: Attributes) {
        debug { "<feSpotLight>" }
        val currentElement = requireCurrentElement()
        if (currentElement !is FeDiffuseLighting && currentElement !is FeSpecularLighting) {
            return
        }
        val obj = FeSpotLight()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.x -> obj.x = parseFloat(value)
                SVGAttr.y -> obj.y = parseFloat(value)
                SVGAttr.z -> obj.z = parseFloat(value)
                SVGAttr.pointsAtX -> obj.pointsAtX = parseFloat(value)
                SVGAttr.pointsAtY -> obj.pointsAtY = parseFloat(value)
                SVGAttr.pointsAtZ -> obj.pointsAtZ = parseFloat(value)
                SVGAttr.limitingConeAngle -> obj.limitingConeAngle = parseFloat(value)
                else -> {}
            }
        }
        when (currentElement) {
            is FeDiffuseLighting -> currentElement.light = obj
            is FeSpecularLighting -> currentElement.light = obj
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feFlood(attributes: Attributes) {
        debug { "<feFlood>" }
        val currentElement = requireCurrentElement()
        val obj = FeFlood()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feGaussianBlur(attributes: Attributes) {
        debug { "<feGaussianBlur>" }
        val currentElement = requireCurrentElement()
        val obj = FeGaussianBlur()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.stdDeviation -> {
                    val values = parseFloatList(value)
                    obj.stdDeviationX = values.getOrNull(0) ?: 0f
                    obj.stdDeviationY = values.getOrNull(1) ?: obj.stdDeviationX
                }
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feImage(attributes: Attributes) {
        debug { "<feImage>" }
        val currentElement = requireCurrentElement()
        val obj = FeImage()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { i, attr, value ->
            when (attr) {
                SVGAttr.href -> {
                    val uri = attributes.getURI(i)
                    if (uri == "" || uri == XLINK_NAMESPACE) {
                        obj.href = value
                    }
                }
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feMerge(attributes: Attributes) {
        debug { "<feMerge>" }
        val currentElement = requireCurrentElement()
        val obj = FeMerge()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.result -> obj.result = value
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feMergeNode(attributes: Attributes) {
        debug { "<feMergeNode>" }
        val currentElement = requireCurrentElement()
        val obj = FeMergeNode()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.`in` -> obj.`in` = value
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feOffset(attributes: Attributes) {
        debug { "<feOffset>" }
        val currentElement = requireCurrentElement()
        val obj = FeOffset()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.dx -> obj.dx = parseLength(value)
                SVGAttr.dy -> obj.dy = parseLength(value)
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feTurbulence(attributes: Attributes) {
        debug { "<feTurbulence>" }
        val currentElement = requireCurrentElement()
        val obj = FeTurbulence()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.baseFrequency -> {
                    val values = parseFloatList(value)
                    obj.baseFrequencyX = values.getOrNull(0) ?: 0f
                    obj.baseFrequencyY = values.getOrNull(1) ?: obj.baseFrequencyX
                }
                SVGAttr.numOctaves -> obj.numOctaves = value.toIntOrNull() ?: 1
                SVGAttr.seed -> obj.seed = parseFloat(value)
                SVGAttr.stitchTiles -> obj.stitchTiles = if (value.isEmpty()) FeStitchTiles.noStitch else try {
                    FeStitchTiles.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid stitchTiles attribute: $value")
                }
                SVGAttr.type -> obj.type = if (value.isEmpty()) FeTurbulenceType.turbulence else try {
                    FeTurbulenceType.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid feTurbulence type: $value")
                }
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feMorphology(attributes: Attributes) {
        debug { "<feMorphology>" }
        val currentElement = requireCurrentElement()
        val obj = FeMorphology()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        attributes.forEachKeyValue { _, attr, value ->
            when (attr) {
                SVGAttr.operator -> obj.operator = if (value.isEmpty()) FeMorphologyOperator.erode else try {
                    FeMorphologyOperator.valueOf(value)
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid feMorphology operator: $value")
                }
                SVGAttr.radius -> {
                    val values = parseFloatList(value)
                    obj.radiusX = values.getOrNull(0) ?: 0f
                    obj.radiusY = values.getOrNull(1) ?: obj.radiusX
                }
                else -> {}
            }
        }
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(SVGParseException::class)
    private fun feTile(attributes: Attributes) {
        debug { "<feTile>" }
        val currentElement = requireCurrentElement()
        val obj = FeTile()
        obj.document = requireSvgDocument()
        obj.parent = currentElement
        parseAttributesCore(obj, attributes)
        parseAttributesStyle(obj, attributes)
        parseAttributesFilterPrimitive(obj, attributes)
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @JvmSynthetic
    internal fun parseFloatList(value: String): FloatArray {
        val scanner = TextScanner(value)
        val list = MutableFloatList()
        while (!scanner.empty()) {
            val f = scanner.nextFloat()
            if (!f.isNaN()) {
                list.add(f)
            }
            scanner.skipCommaWhitespace()
        }
        return list.toFloatArray()
    }

    companion object {
        private const val TAG = "SVGParser"

        private const val SVG_NAMESPACE = "http://www.w3.org/2000/svg"
        private const val XLINK_NAMESPACE = "http://www.w3.org/1999/xlink"
        private const val FEATURE_STRING_PREFIX = "http://www.w3.org/TR/SVG11/feature#"

        private const val XML_STYLESHEET_PROCESSING_INSTRUCTION = "xml-stylesheet"

        private val PATTERN_BLOCK_COMMENTS: Pattern = compilePattern("/\\*.*?\\*/")

        // <?xml-stylesheet> attribute names and values
        const val XML_STYLESHEET_ATTR_TYPE: String = "type"
        const val XML_STYLESHEET_ATTR_ALTERNATE: String = "alternate"
        const val XML_STYLESHEET_ATTR_HREF: String = "href"
        const val XML_STYLESHEET_ATTR_MEDIA: String = "media"
        const val XML_STYLESHEET_ATTR_MEDIA_ALL: String = "all"
        const val XML_STYLESHEET_ATTR_ALTERNATE_NO: String = "no"

        // Used by the automatic XML parser switching code.
        // This value defines how much of the SVG file preamble will we keep in order to check for
        // a doctype definition that has internal entities defined.
        const val ENTITY_WATCH_BUFFER_SIZE: Int = 4096


        // Special attribute keywords
        const val NONE: String = "none"
        const val CURRENT_COLOR: String = "currentColor"

        const val VALID_DISPLAY_VALUES: String =
            "|inline|block|list-item|run-in|compact|marker|table|inline-table" +
                    "|table-row-group|table-header-group|table-footer-group|table-row" +
                    "|table-column-group|table-column|table-cell|table-caption|none|"
        const val VALID_VISIBILITY_VALUES: String = "|visible|hidden|collapse|"

        //=========================================================================
        // Parsing various SVG value types
        //=========================================================================
        /*
        * Parse an SVG 'Length' value (usually a coordinate).
        * Spec says: length ::= number ("em" | "ex" | "px" | "in" | "cm" | "mm" | "pt" | "pc" | "%")?
        */
        @JvmStatic
        @Throws(SVGParseException::class)
        fun parseLength(value: String): CSSLength {
            checkState(value.isNotEmpty()) { "Invalid length value (empty string)" }

            var end = value.length
            var unit = CssUnit.px
            val lastChar = value[end - 1]

            if (lastChar == '%') {
                end -= 1
                unit = CssUnit.percent
            } else if (end > 2 && lastChar.isLetter() && value[end - 2].isLetter()) {
                end -= 2
                val unitStr = value.substring(end)
                try {
                    unit = CssUnit.valueOf(unitStr.lowercase())
                } catch (_: IllegalArgumentException) {
                    throw SVGParseException("Invalid length unit specifier: $value")
                }
            }
            try {
                val scalar: Float = parseFloat(value, 0, end)
                return CSSLength(scalar, unit)
            } catch (e: NumberFormatException) {
                throw SVGParseException("Invalid length value: $value", e)
            }
        }

        @JvmStatic
        @Throws(SVGParseException::class)
        fun parseNonNegativeLength(value: String, errorMessage: String): CSSLength {
            return parseLength(value).also {
                checkState(!it.isNegative) { errorMessage }
            }
        }

        /*
        * Parse a list of Length/Coords
        */
        @Throws(SVGParseException::class)
        private fun parseLengthList(value: String): List<CSSLength> {
            checkState(value.isNotEmpty()) { "Invalid length list (empty string)" }

            val coords = ArrayList<CSSLength>(1)

            val scan = TextScanner(value)
            scan.skipWhitespace()

            while (!scan.empty()) {
                val scalar = scan.nextFloat()
                checkState(!scalar.isNaN()) { "Invalid length list value: " + scan.ahead() }
                val unit = scan.nextUnit() ?: CssUnit.px
                coords.add(CSSLength(scalar, unit))
                scan.skipCommaWhitespace()
            }
            return coords
        }


        /*
        * Parse a generic float value.
        */
        @JvmStatic
        @Throws(SVGParseException::class)
        fun parseFloat(value: String): Float {
            val len = value.length
            if (len == 0) {
                throw SVGParseException("Invalid float value (empty string)")
            }
            return parseFloat(value, 0, len)
        }

        @JvmStatic
        @Throws(SVGParseException::class)
        fun parseNonNegativeFloat(value: String, errorMessage: String): Float {
            return parseFloat(value).also {
                checkState(it >= 0f) { errorMessage }
            }
        }

        @Suppress("SameParameterValue")
        @Throws(SVGParseException::class)
        private fun parseFloat(value: String, offset: Int, len: Int): Float {
            val num = NumberParser.parseNumber(value, offset, len)
            if (num.isNaN()) {
                throw SVGParseException("Invalid float value: $value")
            }
            return num
        }

        /*
        * Parse an opacity value (a float clamped to the range 0..1).
        */
        @JvmStatic
        fun parseOpacity(value: String): Float? {
            return try {
                clamp(n = parseFloat(value), min = 0f, max = 1f)
            } catch (_: SVGParseException) {
                null
            }
        }

        /*
        * Parse a viewBox attribute.
        */
        @Throws(SVGParseException::class)
        private fun parseViewBox(value: String): Box {
            val scan = TextScanner(value)
            scan.skipWhitespace()

            val minX = scan.nextFloat()
            scan.skipCommaWhitespace()
            val minY = scan.nextFloat()
            scan.skipCommaWhitespace()
            val width = scan.nextFloat()
            scan.skipCommaWhitespace()
            val height = scan.nextFloat()

            if (minX.isNaN() || minY.isNaN() || width.isNaN() || height.isNaN()) {
                throw SVGParseException("Invalid viewBox definition - should have four numbers")
            }
            if (width < 0) {
                throw SVGParseException("Invalid viewBox. width cannot be negative")
            }
            if (height < 0) {
                throw SVGParseException("Invalid viewBox. height cannot be negative")
            }

            return Box(minX, minY, width, height)
        }


        /*
        * Parse a preserveAspectRation attribute
        */
        @Throws(SVGParseException::class)
        private fun parsePreserveAspectRatio(obj: SvgPreserveAspectRatioContainer, value: String) {
            obj.preserveAspectRatio = PreserveAspectRatio.of(value)
        }


        /*
        * Parse a paint specifier such as in the fill and stroke attributes.
        */
        @JvmStatic
        fun parsePaintSpecifier(valueParam: String): SvgPaint {
            var value = valueParam
            return if (value.startsWith("url(")) {
                val closeBracket = value.indexOf(')')
                if (closeBracket != -1) {
                    val href = value.substring(4, closeBracket).trimLowerThanSpace()
                    value = value.substring(closeBracket + 1).trimLowerThanSpace()
                    val fallback: SvgPaint? = if (value.isNotEmpty()) {
                        parseColorSpecifier(value)
                    } else {
                        null
                    }
                    PaintReference(href, fallback)
                } else {
                    val href = value.substring(4).trimLowerThanSpace()
                    PaintReference(href, null)
                }
            } else {
                parseColorSpecifier(value)
            }
        }

        private fun parseColorSpecifier(value: String): SvgColor {
            return when (value) {
                NONE -> ColorValue.TRANSPARENT
                CURRENT_COLOR -> CurrentColor
                else -> parseColor(value)
            }
        }

        /*
        * Parse a color definition.
        */
        @JvmStatic
        fun parseColor(value: String): ColorValue {
            if (value[0] == '#') {
                val ip = IntegerParser.parseHex(value, 1, value.length) ?: return ColorValue.BLACK

                return when (ip.endPos) {
                    4 -> ColorValue(pack3Hex(ip.value))
                    5 -> ColorValue(pack4Hex(ip.value))
                    7 -> ColorValue(COLOR_BLACK or ip.value)
                    9 -> ColorValue(pack8Hex(ip.value))
                    else -> {
                        // Hex value had bad length for a color
                        ColorValue.BLACK
                    }
                }
            }

            // Parse a rgb() or rgba() color.
            // In CSS Color 4, these are synonyms, and the alpha parameter is optional in both cases.
            val valueLowerCase = value.lowercase()
            val isRGBA = valueLowerCase.startsWith("rgba(")
            if (isRGBA || valueLowerCase.startsWith("rgb(")) {
                val scan = TextScanner(value.substring(if (isRGBA) 5 else 4))
                scan.skipWhitespace()

                var red = scan.nextFloat()
                if (!red.isNaN()) {
                    if (scan.consume('%')) {
                        red = red * 256 / 100
                    }

                    // If there is a comma, then it is the "legacy" format: rgb(r, g, b, a?).
                    // Otherwise, we assume it is the new format: rgb[a?](r g b / a?).
                    val isLegacyCSSColor3 = scan.skipCommaWhitespace()

                    var green = scan.nextFloat()
                    if (!green.isNaN()) {
                        if (scan.consume('%')) {
                            green = green * 256 / 100
                        }

                        if (isLegacyCSSColor3) {
                            if (!scan.skipCommaWhitespace()) return ColorValue.BLACK // Error
                        } else {
                            scan.skipWhitespace()
                        }

                        var blue = scan.nextFloat()
                        if (!blue.isNaN()) {
                            if (scan.consume('%')) {
                                blue = blue * 256 / 100
                            }

                            // Now look for optional alpha
                            var alpha = Float.NaN
                            if (isLegacyCSSColor3) {
                                if (scan.skipCommaWhitespace()) alpha = scan.nextFloat()
                            } else {
                                scan.skipWhitespace()
                                if (scan.consume('/')) {
                                    scan.skipWhitespace()
                                    alpha = scan.nextFloat()
                                }
                            }
                            scan.skipWhitespace()

                            return if (!scan.consume(')')) {
                                ColorValue.BLACK
                            } else {
                                ColorValue(packRgba(red, green, blue, alpha))
                            }
                        }
                    }
                }
            } else {
                // Parse a hsl() or hsla() color.
                // In CSS Color 4, these are synonyms, and the alpha parameter is optional in both cases.
                val isHSLA = valueLowerCase.startsWith("hsla(")
                if (isHSLA || valueLowerCase.startsWith("hsl(")) {
                    val scan = TextScanner(value.substring(if (isHSLA) 5 else 4))
                    scan.skipWhitespace()

                    val hue = scan.nextFloat()
                    if (!hue.isNaN()) {
                        scan.consume("deg") // Optional units

                        // If there is a comma, then it is the "legacy" format: rgb(r, g, b, a?).
                        // Otherwise, we assume it is the new format: rgb[a?](r g b / a?).
                        val isLegacyCSSColor3 = scan.skipCommaWhitespace()

                        val saturation = scan.nextFloat()
                        if (!saturation.isNaN()) {
                            if (!scan.consume('%')) {
                                return ColorValue.BLACK
                            }

                            if (isLegacyCSSColor3) {
                                if (!scan.skipCommaWhitespace()) {
                                    return ColorValue.BLACK
                                }
                            } else {
                                scan.skipWhitespace()
                            }

                            val lightness = scan.nextFloat()
                            if (!lightness.isNaN()) {
                                if (!scan.consume('%')) {
                                    return ColorValue.BLACK
                                }

                                // Now look for optional alpha
                                var alpha = Float.NaN
                                if (isLegacyCSSColor3) {
                                    if (scan.skipCommaWhitespace()) alpha = scan.nextFloat()
                                } else {
                                    scan.skipWhitespace()
                                    if (scan.consume('/')) {
                                        scan.skipWhitespace()
                                        alpha = scan.nextFloat()
                                    }
                                }
                                scan.skipWhitespace()
                                return if (scan.consume(')')) {
                                    ColorValue(packHsla(hue, saturation, lightness, alpha))
                                } else {
                                    ColorValue.BLACK
                                }
                            }
                        }
                    }
                }
            }

            // Must be a color keyword
            return parseColorKeyword(valueLowerCase)
        }

        // Parse a color component value (0..255 or 0%-100%)
        private fun parseColorKeyword(nameLowerCase: String): ColorValue {
            val col: Int = ColorKeywords.get(nameLowerCase)
            return if (col == COLOR_BLACK) {
                ColorValue.BLACK
            } else {
                ColorValue(col)
            }
        }

        // Parse a font attribute
        // [ [ <'font-style'> || <'font-variant'> || <'font-weight'> ]? <'font-size'> [ / <'line-height'> ]? <'font-family'> ] | caption | icon | menu | message-box | small-caption | status-bar | inherit
        @JvmStatic
        fun parseFont(style: Style, value: String) {
            var fontWeight: Float? = null
            var fontStyle: FontStyle? = null
            var fontWidth: Float? = null
            var fontVariantSmallCaps: Boolean? = null

            // Start by checking for the fixed size standard system font names (which we don't support)
            if ("|caption|icon|menu|message-box|small-caption|status-bar|".contains("|$value|")) return


            // First part: style/variant/weight (opt - one or more)
            val scan = TextScanner(value)
            var item: String?
            while (true) {
                item = scan.nextToken('/')
                scan.skipWhitespace()
                if (item == null) return
                if (fontWeight != null && fontStyle != null) break
                if (item == NORMAL) {
                    // indeterminate right now which of these this refers to
                    continue
                }
                if (fontWeight == null) {
                    fontWeight = FontWeightKeywords.get(item)
                    if (fontWeight != null) {
                        continue
                    }
                }
                if (fontStyle == null) {
                    fontStyle = parseFontStyle(item)
                    if (fontStyle != null) continue
                }
                // Must be a font-variant keyword?
                if (fontVariantSmallCaps == null && item == CSSFontFeatureSettings.FONT_VARIANT_SMALL_CAPS) {
                    fontVariantSmallCaps = true
                    continue
                }
                if (fontWidth == null) {
                    fontWidth = FontWidthKeywords.get(item)
                    if (fontWidth != null) {
                        continue
                    }
                }
                // Not any of these. Break and try next section
                break
            }

            // Second part: font size (reqd) and line-height (opt)
            val fontSize: CSSLength? = parseFontSize(item)

            // Check for line-height (which we don't support)
            if (scan.consume('/')) {
                scan.skipWhitespace()
                item = scan.nextToken()
                if (item != null) {
                    try {
                        parseLength(item)
                    } catch (_: SVGParseException) {
                        return
                    }
                }
                scan.skipWhitespace()
            }


            // Third part: font family
            style.fontFamily = parseFontFamily(scan.restOfText())

            style.fontSize = fontSize
            style.fontWeight = fontWeight ?: Style.FONT_WEIGHT_NORMAL
            style.fontStyle = fontStyle ?: FontStyle.normal
            style.fontWidth = fontWidth ?: Style.FONT_WIDTH_NORMAL
            style.fontKerning = FontKerning.auto
            style.fontVariantLigatures = CSSFontFeatureSettings.LIGATURES_NORMAL
            style.fontVariantPosition = CSSFontFeatureSettings.POSITION_ALL_OFF
            style.fontVariantCaps = CSSFontFeatureSettings.CAPS_ALL_OFF
            if (fontVariantSmallCaps == true) style.fontVariantCaps =
                CSSFontFeatureSettings.CAPS_SMALL_CAPS
            style.fontVariantNumeric = CSSFontFeatureSettings.NUMERIC_ALL_OFF
            style.fontVariantEastAsian = CSSFontFeatureSettings.EAST_ASIAN_ALL_OFF
            style.fontFeatureSettings = CSSFontFeatureSettings.FONT_FEATURE_SETTINGS_NORMAL
            style.fontVariationSettings = CSSFontVariationSettings()

            style.addSpecifiedFlag(
                Style.SPECIFIED_FONT_FAMILY or Style.SPECIFIED_FONT_SIZE or Style.SPECIFIED_FONT_WEIGHT or Style.SPECIFIED_FONT_STYLE or Style.SPECIFIED_FONT_WIDTH or
                        Style.SPECIFIED_FONT_KERNING or Style.SPECIFIED_FONT_VARIANT_LIGATURES or Style.SPECIFIED_FONT_VARIANT_POSITION or Style.SPECIFIED_FONT_VARIANT_CAPS or
                        Style.SPECIFIED_FONT_VARIANT_NUMERIC or Style.SPECIFIED_FONT_VARIANT_EAST_ASIAN or Style.SPECIFIED_FONT_FEATURE_SETTINGS or Style.SPECIFIED_FONT_VARIATION_SETTINGS
            )
        }


        // Parse a font family list
        @JvmStatic
        fun parseFontFamily(value: String?): List<String>? {
            if (value == null) return null

            var fonts: MutableList<String>? = null
            val scan = TextScanner(value)
            while (true) {
                val item = scan.nextQuotedString()
                    ?: scan.nextTokenWithWhitespace(',')
                    ?: break
                if (fonts == null) {
                    fonts = ArrayList()
                }
                fonts.add(item)
                scan.skipCommaWhitespace()
                if (scan.empty()) break
            }
            return fonts
        }


        // Parse a font size keyword or numerical value
        @JvmStatic
        fun parseFontSize(value: String): CSSLength? {
            return try {
                FontSizeKeywords.get(value) ?: parseLength(value)
            } catch (_: SVGParseException) {
                null
            }
        }


        // Parse a font weight keyword or numerical value
        @JvmStatic
        fun parseFontWeight(value: String): Float? {
            var result: Float? = FontWeightKeywords.get(value)
            if (result == null) {
                // Check for a number
                val scan = TextScanner(value)
                result = scan.nextFloat()
                scan.skipWhitespace()
                if (!scan.empty()) {
                    return null
                } else if (result < Style.FONT_WEIGHT_MIN || result > Style.FONT_WEIGHT_MAX) {
                    return null // Invalid
                }
            }
            return result
        }


        // Parse a font width/stretch keyword or numerical value
        @JvmStatic
        fun parseFontWidth(value: String): Float? {
            var result: Float? = FontWidthKeywords.get(value)
            if (result == null) {
                // Check for a percentage value
                val scan = TextScanner(value)
                result = scan.nextFloat()
                if (!scan.consume('%')) return null
                scan.skipWhitespace()
                if (!scan.empty()) return null
                if (result < Style.FONT_WIDTH_MIN) return null // Invalid
            }
            return result
        }


        // Parse a font style keyword
        @JvmStatic
        fun parseFontStyle(value: String): FontStyle? {
            // Italic is probably the most common, so test that first :)
            return when (value) {
                "italic" -> FontStyle.italic
                "normal" -> FontStyle.normal
                "oblique" -> FontStyle.oblique
                else -> null
            }
        }


        // Parse a text decoration keyword
        @JvmStatic
        fun parseTextDecoration(value: String): TextDecoration? {
            return when (value) {
                NONE -> TextDecoration.None
                "underline" -> TextDecoration.Underline
                "overline" -> TextDecoration.Overline
                "line-through" -> TextDecoration.LineThrough
                "blink" -> TextDecoration.Blink
                else -> null
            }
        }


        // Parse a text decoration keyword
        @JvmStatic
        fun parseTextDirection(value: String): TextDirection? {
            return when (value) {
                "ltr" -> TextDirection.LTR
                "rtl" -> TextDirection.RTL
                else -> null
            }
        }


        // Parse fill rule
        @JvmStatic
        fun parseFillRule(value: String?): FillRule? {
            return when (value) {
                "nonzero" -> FillRule.NonZero
                "evenodd" -> FillRule.EvenOdd
                else -> null
            }
        }


        // Parse stroke-line-cap
        @JvmStatic
        fun parseStrokeLineCap(value: String?): LineCap? {
            return when (value) {
                "butt" -> LineCap.Butt
                "round" -> LineCap.Round
                "square" -> LineCap.Square
                else -> null
            }
        }


        // Parse stroke-line-join
        @JvmStatic
        fun parseStrokeLineJoin(value: String?): LineJoin? {
            return when (value) {
                "miter" -> LineJoin.Miter
                "round" -> LineJoin.Round
                "bevel" -> LineJoin.Bevel
                else -> null
            }
        }


        // Parse stroke-dash-array
        @JvmStatic
        fun parseStrokeDashArray(value: String): Array<CSSLength>? {
            val scan = TextScanner(value)
            scan.skipWhitespace()

            if (scan.empty()) return null

            val dash: CSSLength = scan.nextLength() ?: return null
            if (dash.isNegative) return null

            var sum = dash.floatValue()

            val dashes: ArrayList<CSSLength> = ArrayList()
            dashes.add(dash)
            while (!scan.empty()) {
                scan.skipCommaWhitespace()
                val nextDash = scan.nextLength() ?: return null
                if (nextDash.isNegative) return null
                dashes.add(nextDash)
                sum += nextDash.floatValue()
            }

            // Spec (section 11.4) says if the sum of dash lengths is zero, it should
            // be treated as "none" ie a solid stroke.
            return if (sum == 0f) {
                null
            } else {
                dashes.toTypedArray<CSSLength>()
            }
        }


        // Parse a text anchor keyword
        @JvmStatic
        fun parseTextAnchor(value: String): TextAnchor? {
            return when (value) {
                "start" -> TextAnchor.Start
                "middle" -> TextAnchor.Middle
                "end" -> TextAnchor.End
                else -> null
            }
        }


        // Parse a text anchor keyword
        @JvmStatic
        fun parseOverflow(value: String): Boolean? {
            return when (value) {
                "visible", "auto" -> true
                "hidden", "scroll" -> false
                else -> null
            }
        }


        // Parse CSS clip shape (always a rect())
        @JvmStatic
        fun parseClip(value: String): CSSClipRect? {
            if ("auto" == value) return null
            if (!value.startsWith("rect(")) return null

            val scan = TextScanner(value.substring(5))
            scan.skipWhitespace()

            val top: CSSLength = parseLengthOrAuto(scan)
            scan.skipCommaWhitespace()
            val right: CSSLength = parseLengthOrAuto(scan)
            scan.skipCommaWhitespace()
            val bottom: CSSLength = parseLengthOrAuto(scan)
            scan.skipCommaWhitespace()
            val left: CSSLength = parseLengthOrAuto(scan)

            scan.skipWhitespace()
            return if (!scan.consume(')') && !scan.empty()) {
                // Be forgiving. Allow missing ')'.
                null
            } else {
                CSSClipRect(top, right, bottom, left)
            }
        }


        private fun parseLengthOrAuto(scan: TextScanner): CSSLength {
            return if (scan.consume("auto")) {
                CSSLength.ZERO
            } else {
                scan.nextLength() ?: CSSLength.ZERO
            }
        }


        // Parse a vector effect keyword
        @JvmStatic
        fun parseVectorEffect(value: String): VectorEffect? {
            return when (value) {
                NONE -> VectorEffect.None
                "non-scaling-stroke" -> VectorEffect.NonScalingStroke
                else -> null
            }
        }


        // Parse a rendering quality property
        @JvmStatic
        fun parseRenderQuality(value: String): RenderQuality? {
            return when (value) {
                "auto" -> RenderQuality.auto
                "optimizeQuality" -> RenderQuality.optimizeQuality
                "optimizeSpeed" -> RenderQuality.optimizeSpeed
                else -> null
            }
        }


        // Parse an isolation property
        @JvmStatic
        fun parseIsolation(value: String): Isolation? {
            return when (value) {
                "auto" -> Isolation.auto
                "isolate" -> Isolation.isolate
                else -> null
            }
        }


        @JvmStatic
        fun parseLetterOrWordSpacing(value: String): CSSLength? {
            return if ("normal" == value) {
                CSSLength.ZERO
            } else {
                try {
                    val result: CSSLength = parseLength(value)
                    // Percent units were removed in SVG2 and are treated as an error.
                    if (result.unit == CssUnit.percent) {
                        null
                    } else {
                        result
                    }
                } catch (_: SVGParseException) {
                    null
                }
            }
        }


        //=========================================================================
        // Parse the string that defines a path.
        @JvmStatic
        fun parsePath(value: String): PathDefinition {
            val scan = TextScanner(value)

            var currentX = 0f
            var currentY = 0f // The last point visited in the subpath
            var lastMoveX = 0f
            var lastMoveY = 0f // The initial point of current subpath
            var lastControlX = 0f
            var lastControlY = 0f // Last control point of the just completed Bézier curve.
            var x: Float
            var y: Float
            var x1: Float
            var y1: Float
            var x2: Float
            var y2: Float
            var rx: Float
            var ry: Float
            var xAxisRotation: Float
            var largeArcFlag: Boolean?
            var sweepFlag: Boolean?

            val length = value.length
            val path = PathDefinition(
                initialCommands = (length / 8).coerceAtLeast(8),
                initialCoords = (length / 4).coerceAtLeast(16)
            )

            if (scan.empty()) return path

            var pathCommand = scan.nextChar()

            if (pathCommand != 'M' && pathCommand != 'm') return path // Invalid path - doesn't start with a move

            while (true) {
                scan.skipWhitespace()

                when (pathCommand) {
                    'M',
                    'm' -> {
                        x = scan.nextFloat()
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        // Relative moveto at the start of a path is treated as an absolute moveto.
                        if (pathCommand == 'm' && !path.isEmpty) {
                            x += currentX
                            y += currentY
                        }
                        path.moveTo(
                            x = x,
                            y = y
                        )
                        run {
                            lastControlX = x
                            lastMoveX = lastControlX
                            currentX = lastMoveX
                        }
                        run {
                            lastControlY = y
                            lastMoveY = lastControlY
                            currentY = lastMoveY
                        }
                        // Any subsequent coord pairs should be treated as a lineto.
                        pathCommand = if (pathCommand == 'm') 'l' else 'L'
                    }

                    'L',
                    'l' -> {
                        x = scan.nextFloat()
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 'l') {
                            x += currentX
                            y += currentY
                        }
                        path.lineTo(
                            x = x,
                            y = y
                        )
                        run {
                            lastControlX = x
                            currentX = lastControlX
                        }
                        run {
                            lastControlY = y
                            currentY = lastControlY
                        }
                    }

                    'C',
                    'c' -> {
                        x1 = scan.nextFloat()
                        y1 = scan.checkedNextFloat(x1)
                        x2 = scan.checkedNextFloat(y1)
                        y2 = scan.checkedNextFloat(x2)
                        x = scan.checkedNextFloat(y2)
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 'c') {
                            x += currentX
                            y += currentY
                            x1 += currentX
                            y1 += currentY
                            x2 += currentX
                            y2 += currentY
                        }
                        path.cubicTo(
                            x1 = x1,
                            y1 = y1,
                            x2 = x2,
                            y2 = y2,
                            x3 = x,
                            y3 = y
                        )
                        lastControlX = x2
                        lastControlY = y2
                        currentX = x
                        currentY = y
                    }

                    'S',
                    's' -> {
                        x1 = 2 * currentX - lastControlX
                        y1 = 2 * currentY - lastControlY
                        x2 = scan.nextFloat()
                        y2 = scan.checkedNextFloat(x2)
                        x = scan.checkedNextFloat(y2)
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 's') {
                            x += currentX
                            y += currentY
                            x2 += currentX
                            y2 += currentY
                        }
                        path.cubicTo(
                            x1 = x1,
                            y1 = y1,
                            x2 = x2,
                            y2 = y2,
                            x3 = x,
                            y3 = y
                        )
                        lastControlX = x2
                        lastControlY = y2
                        currentX = x
                        currentY = y
                    }

                    'Z',
                    'z' -> {
                        path.close()
                        run {
                            lastControlX = lastMoveX
                            currentX = lastControlX
                        }
                        run {
                            lastControlY = lastMoveY
                            currentY = lastControlY
                        }
                    }

                    'H',
                    'h' -> {
                        x = scan.nextFloat()
                        if (x.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 'h') {
                            x += currentX
                        }
                        path.lineTo(
                            x = x,
                            y = currentY
                        )
                        run {
                            lastControlX = x
                            currentX = lastControlX
                        }
                        lastControlY = currentY
                    }

                    'V',
                    'v' -> {
                        y = scan.nextFloat()
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 'v') {
                            y += currentY
                        }
                        path.lineTo(
                            x = currentX,
                            y = y
                        )
                        lastControlX = currentX
                        run {
                            lastControlY = y
                            currentY = lastControlY
                        }
                    }

                    'Q',
                    'q' -> {
                        x1 = scan.nextFloat()
                        y1 = scan.checkedNextFloat(x1)
                        x = scan.checkedNextFloat(y1)
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 'q') {
                            x += currentX
                            y += currentY
                            x1 += currentX
                            y1 += currentY
                        }
                        path.quadTo(
                            x1 = x1,
                            y1 = y1,
                            x2 = x,
                            y2 = y
                        )
                        lastControlX = x1
                        lastControlY = y1
                        currentX = x
                        currentY = y
                    }

                    'T',
                    't' -> {
                        x1 = 2 * currentX - lastControlX
                        y1 = 2 * currentY - lastControlY
                        x = scan.nextFloat()
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN()) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 't') {
                            x += currentX
                            y += currentY
                        }
                        path.quadTo(
                            x1 = x1,
                            y1 = y1,
                            x2 = x,
                            y2 = y
                        )
                        lastControlX = x1
                        lastControlY = y1
                        currentX = x
                        currentY = y
                    }

                    'A',
                    'a' -> {
                        rx = scan.nextFloat()
                        ry = scan.checkedNextFloat(rx)
                        xAxisRotation = scan.checkedNextFloat(ry)
                        largeArcFlag = scan.checkedNextFlag(xAxisRotation)
                        sweepFlag = scan.checkedNextFlag(largeArcFlag)
                        x = scan.checkedNextFloat(sweepFlag)
                        y = scan.checkedNextFloat(x)
                        if (y.isNaN() || rx < 0 || ry < 0) {
                            Log.e(
                                TAG,
                                "Bad path coords for $pathCommand path segment"
                            )
                            return path
                        }
                        if (pathCommand == 'a') {
                            x += currentX
                            y += currentY
                        }
                        path.arcTo(
                            rx = rx,
                            ry = ry,
                            xAxisRotation = xAxisRotation,
                            largeArcFlag = largeArcFlag!!,
                            sweepFlag = sweepFlag!!,
                            x = x,
                            y = y
                        )
                        run {
                            lastControlX = x
                            currentX = lastControlX
                        }
                        run {
                            lastControlY = y
                            currentY = lastControlY
                        }
                    }

                    else -> return path
                }

                scan.skipCommaWhitespace()
                if (scan.empty()) break

                // Test to see if there is another set of coords for the current path command
                if (scan.hasLetter()) {
                    // Nope, so get the new path command instead
                    pathCommand = scan.nextChar()
                }
            }
            return path
        }


        //=========================================================================
        // Conditional processing (ie for <switch> element)
        // Parse the attribute that declares the list of SVG features that must be
        // supported if we are to render this element
        private fun parseRequiredFeatures(value: String): Set<String> {
            val scan = TextScanner(value)
            val result = ArraySet<String>()

            while (!scan.empty()) {
                val feature = scan.requireNextToken()
                if (feature.startsWith(FEATURE_STRING_PREFIX)) {
                    result.add(feature.substring(FEATURE_STRING_PREFIX.length))
                } else {
                    // Not a feature string we recognize or support. (In order to avoid accidentally
                    // matches with our truncated feature strings, we'll replace it with a string
                    // we know for sure won't match anything.)
                    result.add("UNSUPPORTED")
                }
                scan.skipWhitespace()
            }
            return result
        }


        // Parse the attribute that declares the list of languages, one of which
        // must be supported if we are to render this element
        private fun parseSystemLanguage(value: String): Set<String> {
            val scan = TextScanner(value)
            val result = ArraySet<String>()

            while (!scan.empty()) {
                var language = scan.requireNextToken()
                val hyphenPos = language.indexOf('-')
                if (hyphenPos != -1) {
                    language = language.substring(0, hyphenPos)
                }
                // Get canonical version of language code in case it has changed (see the Javadoc for Locale.getLanguage())
                language = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
                    Locale.of(language, "", "")
                } else {
                    @Suppress("DEPRECATION")
                    Locale(language, "", "")
                }.language
                result.add(language)
                scan.skipWhitespace()
            }
            return result
        }


        // Parse the attribute that declares the list of MIME types that must be
        // supported if we are to render this element
        private fun parseRequiredFormats(value: String): Set<String> {
            val scan = TextScanner(value)
            val result = ArraySet<String>()

            while (!scan.empty()) {
                val mimetype = scan.requireNextToken()
                result.add(mimetype)
                scan.skipWhitespace()
            }
            return result
        }

        @JvmStatic
        fun parseFunctionalIRI(value: String, @Suppress("unused") attrName: String?): String? {
            return when {
                value == NONE -> {
                    null
                }

                !value.startsWith("url(") -> {
                    null
                }

                else -> {
                    if (value.endsWith(')')) {
                        value.substring(4, value.length - 1)
                    } else {
                        value.substring(4)
                    }.trimLowerThanSpace()
                }
            }
            // Unlike CSS, the SVG spec seems to indicate that quotes are not allowed in "url()" references
        }
    }
}
