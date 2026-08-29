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

package hu.oandras.ksvg.parser

import android.util.Xml
import androidx.collection.ArrayMap
import hu.oandras.ksvg.AndroidLoggerContext
import hu.oandras.ksvg.BuildConfig
import hu.oandras.ksvg.ExternalFileResolver
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.LoggerContext
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.MediaType
import hu.oandras.ksvg.css.Source
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.animation.AnimateColor
import hu.oandras.ksvg.dom.animation.AnimateDashArray
import hu.oandras.ksvg.dom.animation.AnimateFloat
import hu.oandras.ksvg.dom.animation.AnimateMotion
import hu.oandras.ksvg.dom.animation.AnimatePath
import hu.oandras.ksvg.dom.animation.AnimateTransform
import hu.oandras.ksvg.dom.animation.Animation
import hu.oandras.ksvg.dom.animation.CalcMode
import hu.oandras.ksvg.dom.animation.MPath
import hu.oandras.ksvg.dom.core.ClipPath
import hu.oandras.ksvg.dom.core.ConditionalContainer
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.Defs
import hu.oandras.ksvg.dom.core.ElementBase
import hu.oandras.ksvg.dom.core.Group
import hu.oandras.ksvg.dom.core.Image
import hu.oandras.ksvg.dom.core.Marker
import hu.oandras.ksvg.dom.core.Mask
import hu.oandras.ksvg.dom.core.Pattern
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.dom.core.SVGTag
import hu.oandras.ksvg.dom.core.SolidColor
import hu.oandras.ksvg.dom.core.Svg
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.dom.core.Switch
import hu.oandras.ksvg.dom.core.Symbol
import hu.oandras.ksvg.dom.core.Use
import hu.oandras.ksvg.dom.core.View
import hu.oandras.ksvg.dom.filter.FeBlend
import hu.oandras.ksvg.dom.filter.FeColorMatrix
import hu.oandras.ksvg.dom.filter.FeComponentTransfer
import hu.oandras.ksvg.dom.filter.FeComposite
import hu.oandras.ksvg.dom.filter.FeConvolveMatrix
import hu.oandras.ksvg.dom.filter.FeDiffuseLighting
import hu.oandras.ksvg.dom.filter.FeDisplacementMap
import hu.oandras.ksvg.dom.filter.FeDistantLight
import hu.oandras.ksvg.dom.filter.FeDropShadow
import hu.oandras.ksvg.dom.filter.FeFlood
import hu.oandras.ksvg.dom.filter.FeFunc
import hu.oandras.ksvg.dom.filter.FeGaussianBlur
import hu.oandras.ksvg.dom.filter.FeImage
import hu.oandras.ksvg.dom.filter.FeLighting
import hu.oandras.ksvg.dom.filter.FeMerge
import hu.oandras.ksvg.dom.filter.FeMergeNode
import hu.oandras.ksvg.dom.filter.FeMorphology
import hu.oandras.ksvg.dom.filter.FeOffset
import hu.oandras.ksvg.dom.filter.FePointLight
import hu.oandras.ksvg.dom.filter.FeSpecularLighting
import hu.oandras.ksvg.dom.filter.FeSpotLight
import hu.oandras.ksvg.dom.filter.FeTile
import hu.oandras.ksvg.dom.filter.FeTurbulence
import hu.oandras.ksvg.dom.filter.Filter
import hu.oandras.ksvg.dom.gradient.Gradient
import hu.oandras.ksvg.dom.gradient.GradientLinear
import hu.oandras.ksvg.dom.gradient.GradientRadial
import hu.oandras.ksvg.dom.gradient.Stop
import hu.oandras.ksvg.dom.shapes.CircleShape
import hu.oandras.ksvg.dom.shapes.EllipseShape
import hu.oandras.ksvg.dom.shapes.LineShape
import hu.oandras.ksvg.dom.shapes.PathShape
import hu.oandras.ksvg.dom.shapes.PolyLineShape
import hu.oandras.ksvg.dom.shapes.PolygonShape
import hu.oandras.ksvg.dom.shapes.RectShape
import hu.oandras.ksvg.dom.text.A
import hu.oandras.ksvg.dom.text.TRef
import hu.oandras.ksvg.dom.text.TSpan
import hu.oandras.ksvg.dom.text.Text
import hu.oandras.ksvg.dom.text.TextChild
import hu.oandras.ksvg.dom.text.TextContainer
import hu.oandras.ksvg.dom.text.TextPath
import hu.oandras.ksvg.dom.text.TextRoot
import hu.oandras.ksvg.dom.text.TextSequence
import hu.oandras.ksvg.logD
import hu.oandras.ksvg.logE
import hu.oandras.ksvg.render.animation.isColorAttribute
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.trimLowerThanSpace
import org.xml.sax.Attributes
import org.xml.sax.InputSource
import org.xml.sax.SAXException
import org.xml.sax.ext.DefaultHandler2
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserException
import java.io.IOException
import java.io.InputStream
import java.util.zip.GZIPInputStream
import javax.xml.parsers.ParserConfigurationException
import javax.xml.parsers.SAXParserFactory


/*
 * SVG parser code. Used by SVG class. Should not be called directly.
 */
internal class SVGParserImpl(
    enableInternalEntities: Boolean = true,
    externalFileResolver: ExternalFileResolver? = null,
    animationsEnabled: Boolean = false,
    logger: LoggerContext = AndroidLoggerContext,
) : SVGParser {
    // SVG parser
    private var svgDocument: SVGImpl? = null

    private fun requireSvgDocument(): SVGImpl {
        return svgDocument!!
    }

    private var currentElement: Container? = null
    private var currentAnimationElement: ElementBase? = null
    private val enableInternalEntities = enableInternalEntities
    private val animationsEnabled = animationsEnabled
    private val externalFileResolver: ExternalFileResolver? = externalFileResolver
    private val logger: LoggerContext = logger

    // For handling elements we don't support
    private var ignoring = false
    private var ignoreDepth = 0

    // For handling <title> and <desc>
    private var inMetadataElement = false
    private var metadataTag: SVGTag? = null
    private var metadataElementContents: StringBuilder? = null

    // For handling <style>
    private var inStyleElement = false
    private var styleElementContents: StringBuilder? = null

    private fun requireCurrentElement(): Container {
        return currentElement
            ?: throw KSVGParseException("Invalid document. Root element must be <svg>")
    }

    //=========================================================================
    // Main parser invocation methods
    //=========================================================================
    @Throws(KSVGParseException::class)
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
            logger.logE(TAG) {
                "Error occurred while performing check for entities.  File may not be parsed correctly if it contains entity definitions.\n" + e.stackTraceToString()
            }
            parseUsingXmlPullParser(input)
            return checkNotNull(svgDocument) { "svgDocument is null after fallback parse" }
        } finally {
            try {
                input.close()
            } catch (_: IOException) {
                logger.logE(TAG) { "Exception thrown closing input stream" }
            }
        }
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

    @Throws(KSVGParseException::class)
    private fun parseUsingXmlPullParser(inputStream: InputStream) {
        try {
            val parser = Xml.newPullParser()
            val attributes = XPPAttributesWrapper(parser)

            parser.setFeature(XmlPullParser.FEATURE_PROCESS_DOCDECL, false)
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, true)
            parser.setInput(inputStream, null)

            val tempStartAndLength = IntArray(2)

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
                        tempStartAndLength.fill(0)
                        val text = parser.getTextCharacters(tempStartAndLength)
                        text(text, tempStartAndLength[0], tempStartAndLength[1])
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
            throw KSVGParseException("XML parser problem", e)
        } catch (e: IOException) {
            throw KSVGParseException("Stream error", e)
        }
    }

    //=========================================================================
    // SAX parsing method and handler class
    //=========================================================================
    @Throws(KSVGParseException::class)
    private fun parseUsingSAX(inputStream: InputStream?) {
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

            xr.parse(InputSource(inputStream))
        } catch (e: ParserConfigurationException) {
            throw KSVGParseException("XML parser problem", e)
        } catch (e: SAXException) {
            throw KSVGParseException("SVG parse error", e)
        } catch (e: IOException) {
            throw KSVGParseException("Stream error", e)
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
        svgDocument = SVGImpl(
            enableInternalEntities,
            externalFileResolver,
            logger
        ).apply {
            animationsEnabled = this@SVGParserImpl.animationsEnabled
        }
    }

    @Throws(KSVGParseException::class)
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

        when (val elem = SVGTag.fromString(tag)) {
            SVGTag.svg -> svg(attributes)
            SVGTag.animate -> animate(attributes)
            SVGTag.animateColor -> animateColor(attributes)
            SVGTag.animateMotion -> animateMotion(attributes)
            SVGTag.animateTransform -> animateTransform(attributes)
            SVGTag.mpath -> mpath(attributes)
            SVGTag.set -> set(attributes)
            SVGTag.g -> g(attributes)
            SVGTag.defs -> defs(attributes)
            SVGTag.a -> a(attributes)
            SVGTag.use -> use(attributes)
            SVGTag.path -> path(attributes)
            SVGTag.rect -> rect(attributes)
            SVGTag.circle -> circle(attributes)
            SVGTag.ellipse -> ellipse(attributes)
            SVGTag.line -> line(attributes)
            SVGTag.polyline -> polyline(attributes)
            SVGTag.polygon -> polygon(attributes)
            SVGTag.text -> text(attributes)
            SVGTag.tspan -> tspan(attributes)
            SVGTag.tref -> tref(attributes)
            SVGTag.switch -> switch(attributes)
            SVGTag.symbol -> symbol(attributes)
            SVGTag.marker -> marker(attributes)
            SVGTag.linearGradient -> linearGradient(attributes)
            SVGTag.radialGradient -> radialGradient(attributes)
            SVGTag.stop -> stop(attributes)
            SVGTag.filter -> filter(attributes)
            SVGTag.feBlend -> feBlend(attributes)
            SVGTag.feColorMatrix -> feColorMatrix(attributes)
            SVGTag.feComponentTransfer -> feComponentTransfer(attributes)
            SVGTag.feFuncA -> feFunc(attributes, FeFunc.Channel.A)
            SVGTag.feFuncB -> feFunc(attributes, FeFunc.Channel.B)
            SVGTag.feFuncG -> feFunc(attributes, FeFunc.Channel.G)
            SVGTag.feFuncR -> feFunc(attributes, FeFunc.Channel.R)
            SVGTag.feConvolveMatrix -> feConvolveMatrix(attributes)
            SVGTag.feComposite -> feComposite(attributes)
            SVGTag.feDiffuseLighting -> feDiffuseLighting(attributes)
            SVGTag.feDisplacementMap -> feDisplacementMap(attributes)
            SVGTag.feDistantLight -> feDistantLight(attributes)
            SVGTag.fePointLight -> fePointLight(attributes)
            SVGTag.feSpecularLighting -> feSpecularLighting(attributes)
            SVGTag.feSpotLight -> feSpotLight(attributes)
            SVGTag.feFlood -> feFlood(attributes)
            SVGTag.feGaussianBlur -> feGaussianBlur(attributes)
            SVGTag.feImage -> feImage(attributes)
            SVGTag.feMerge -> feMerge(attributes)
            SVGTag.feMergeNode -> feMergeNode(attributes)
            SVGTag.feMorphology -> feMorphology(attributes)
            SVGTag.feOffset -> feOffset(attributes)
            SVGTag.feTurbulence -> feTurbulence(attributes)
            SVGTag.feTile -> feTile(attributes)
            SVGTag.feDropShadow -> feDropShadow(attributes)
            SVGTag.title, SVGTag.desc -> {
                inMetadataElement = true
                metadataTag = elem
            }

            SVGTag.clipPath -> clipPath(attributes)
            SVGTag.textPath -> textPath(attributes)
            SVGTag.pattern -> pattern(attributes)
            SVGTag.image -> image(attributes)
            SVGTag.view -> view(attributes)
            SVGTag.mask -> mask(attributes)
            SVGTag.style -> style(attributes)
            SVGTag.solidColor -> solidColor(attributes)
            else -> {
                ignoring = true
                ignoreDepth = 1
            }
        }
    }

    @Throws(KSVGParseException::class)
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

    @Throws(KSVGParseException::class)
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


    @Throws(KSVGParseException::class)
    private fun appendToTextContainer(characters: String) {
        // The parser can pass us several text nodes in a row. If this happens, we
        // want to collapse them all into one SVGBase.TextSequence node
        val parent = currentElement as ConditionalContainer
        val previousSibling = parent.getChildren().lastOrNull()
        if (previousSibling is TextSequence) {
            // Last sibling was a TextSequence also, so merge them.
            previousSibling.text += characters
        } else {
            // Add a new TextSequence to the child node list
            parent.addChild(
                TextSequence(
                    id = null,
                    document = requireSvgDocument(),
                    parent = parent,
                    spacePreserve = null,
                    text = characters
                )
            )
        }
    }

    @Throws(KSVGParseException::class)
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
        when (SVGTag.fromString(tag)) {
            SVGTag.title,
            SVGTag.desc -> {
                inMetadataElement = false
                val metadataElementContents = metadataElementContents
                if (metadataElementContents != null) {
                    val svgDocument = requireSvgDocument()
                    when (metadataTag) {
                        SVGTag.title -> {
                            svgDocument.setTitle(metadataElementContents.toString())
                        }

                        SVGTag.desc -> {
                            svgDocument.setDesc(metadataElementContents.toString())
                        }

                        else -> {}
                    }
                    metadataElementContents.setLength(0)
                }
                return
            }

            SVGTag.style -> {
                val styleElementContents = styleElementContents
                if (styleElementContents != null) {
                    inStyleElement = false
                    parseCSSStyleSheet(styleElementContents.toString())
                    styleElementContents.setLength(0)
                    return
                }
            }

            SVGTag.svg,
            SVGTag.g,
            SVGTag.defs,
            SVGTag.a,
            SVGTag.use,
            SVGTag.image,
            SVGTag.text,
            SVGTag.tspan,
            SVGTag.switch,
            SVGTag.symbol,
            SVGTag.marker,
            SVGTag.linearGradient,
            SVGTag.radialGradient,
            SVGTag.stop,
            SVGTag.clipPath,
            SVGTag.textPath,
            SVGTag.pattern,
            SVGTag.view,
            SVGTag.mask,
            SVGTag.solidColor,
            SVGTag.filter,
            SVGTag.feBlend,
            SVGTag.feColorMatrix,
            SVGTag.feComponentTransfer,
            SVGTag.feFuncA,
            SVGTag.feFuncB,
            SVGTag.feFuncG,
            SVGTag.feFuncR,
            SVGTag.feConvolveMatrix,
            SVGTag.feComposite,
            SVGTag.feDiffuseLighting,
            SVGTag.feDisplacementMap,
            SVGTag.feDistantLight,
            SVGTag.fePointLight,
            SVGTag.feSpecularLighting,
            SVGTag.feSpotLight,
            SVGTag.feFlood,
            SVGTag.feGaussianBlur,
            SVGTag.feImage,
            SVGTag.feMerge,
            SVGTag.feMergeNode,
            SVGTag.feMorphology,
            SVGTag.feOffset,
            SVGTag.feTurbulence,
            SVGTag.feTile,
            SVGTag.feDropShadow -> {
                val elem = currentElement
                checkState(elem != null) {
                    // This situation has been reported by a user. But I am unable to reproduce this fault.
                    // If you can get this error please add your SVG file as a test case.
                    // For now we'll return a parse exception for consistency (instead of NPE).
                    throw KSVGParseException(
                        String.format(
                            "Unbalanced end element </%s> found",
                            tag
                        )
                    )
                }
                currentElement = elem.parent
            }

            SVGTag.animate,
            SVGTag.animateColor,
            SVGTag.animateTransform,
            SVGTag.set -> {
                // Animation elements do not affect the current container stack.
            }

            SVGTag.animateMotion -> {
                // Only pop the container stack when animations are enabled, matching the
                // push performed in animateMotion() (which is skipped when disabled).
                if (animationsEnabled) {
                    val elem = currentElement
                    checkState(elem != null) {
                        throw KSVGParseException(
                            String.format(
                                "Unbalanced end element </%s> found",
                                tag
                            )
                        )
                    }
                    currentElement = elem.parent
                }
            }

            SVGTag.path,
            SVGTag.rect,
            SVGTag.circle,
            SVGTag.ellipse,
            SVGTag.line,
            SVGTag.polyline,
            SVGTag.polygon -> {
                currentAnimationElement = null
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
                var css = externalFileResolver.resolveCSSStyleSheet(attr) ?: return

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
    @Suppress("SimplifyBooleanWithConstants")
    private inline fun debug(lazyMessage: () -> String) {
        if (BuildConfig.DEBUG && DEBUG_MODE) {
            logger.logD(TAG, lazyMessage)
        }
    }

    private fun dumpNode(elem: SvgObject?, indent: String?) {
        if (!DEBUG_MODE) return
        var indent = indent
        logger.logD(TAG) { (indent ?: "") + elem }
        if (elem is ConditionalContainer) {
            indent = "$indent  "
            elem.getChildren().forEachElement { child ->
                dumpNode(child, indent)
            }
        }
    }

    //=========================================================================
    // Handlers for each SVG element
    //=========================================================================
    // <svg> element
    @Throws(KSVGParseException::class)
    private fun svg(attributes: Attributes) {
        debug { "<svg>" }

        val currentElement = currentElement
        val builder = Svg.Builder(
            requireSvgDocument(),
            currentElement
        )
        builder.parseAttributes(attributes)
        val obj = builder.build()
        if (currentElement == null) {
            svgDocument?.rootElement = obj
        } else {
            currentElement.addChild(obj)
        }
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun g(attributes: Attributes) {
        debug { "<g>" }

        val currentElement = requireCurrentElement()
        val builder = Group.Builder<Group>(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(KSVGParseException::class)
    private fun defs(attributes: Attributes) {
        debug { "<defs>" }

        val currentElement = requireCurrentElement()
        val builder = Defs.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(KSVGParseException::class)
    private fun a(attributes: Attributes) {
        debug { "<a>" }

        val currentElement = requireCurrentElement()
        val builder = A.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }

    private fun animateTransform(attributes: Attributes) {
        if (!animationsEnabled) return

        try {
            debug { "<animateTransform>" }

            val currentElement = requireCurrentElement()
            val target = currentAnimationElement ?: (currentElement as ElementBase)

            val builder = AnimateTransform.Builder(requireSvgDocument(), target.parent)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            target.addAnimation(obj)
        } catch (e: Throwable) {
            logger.logE(TAG) { "Cannot parse <animateTransform>\n" + e.stackTraceToString() }
        }
    }

    private fun animate(attributes: Attributes) {
        if (!animationsEnabled) return

        try {
            debug { "<animate>" }

            val currentElement = requireCurrentElement()
            val target = currentAnimationElement ?: (currentElement as ElementBase)

            // We need to check if it's a color animation or float animation
            val attributeName: SVGAttr? = attributes.getAttributeValueByLocalName("attributeName")
                ?.let { SVGAttr.fromString(it) }

            val builder = animationBuilderFor(attributeName, target)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            target.addAnimation(obj)
        } catch (e: Throwable) {
            logger.logE(TAG) { "Cannot parse <animate>\n" + e.stackTraceToString() }
        }
    }

    private fun animateColor(attributes: Attributes) {
        if (!animationsEnabled) return

        try {
            debug { "<animateColor>" }

            val currentElement = requireCurrentElement()
            val target = currentAnimationElement ?: (currentElement as ElementBase)

            val builder = AnimateColor.Builder(requireSvgDocument(), target.parent)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            target.addAnimation(obj)
        } catch (e: Throwable) {
            logger.logE(TAG) { "Cannot parse <animateColor>\n" + e.stackTraceToString() }
        }
    }

    private fun animateMotion(attributes: Attributes) {
        if (!animationsEnabled) return

        try {
            debug { "<animateMotion>" }

            val currentElement = requireCurrentElement()
            val target = currentAnimationElement ?: (currentElement as ElementBase)

            val builder = AnimateMotion.Builder(requireSvgDocument(), target.parent)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            target.addAnimation(obj)
            this.currentElement = obj
        } catch (e: Throwable) {
            logger.logE(TAG) { "Cannot parse <animateMotion>\n" + e.stackTraceToString() }
        }
    }

    private fun mpath(attributes: Attributes) {
        try {
            debug { "<mpath>" }

            val currentElement = requireCurrentElement()
            val builder = MPath.Builder(requireSvgDocument(), currentElement)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            currentElement.addChild(obj)
        } catch (e: Throwable) {
            logger.logE(TAG) { "Cannot parse <mpath>\n" + e.stackTraceToString() }
        }
    }

    private fun set(attributes: Attributes) {
        if (!animationsEnabled) return

        try {
            debug { "<set>" }

            val currentElement = requireCurrentElement()
            val target = currentAnimationElement ?: (currentElement as ElementBase)

            val attributeName: SVGAttr? = attributes.getAttributeValueByLocalName("attributeName")
                ?.let { SVGAttr.fromString(it) }

            val builder = animationBuilderFor(attributeName, target)

            builder.parseAttributes(attributes)

            // <set> always uses discrete mode and an indefinite simple duration
            // when no dur is given (active from begin until end).
            builder.calcMode = CalcMode.discrete
            builder.useIndefiniteDurationForSet()

            val obj = builder.build()
            target.addAnimation(obj)
        } catch (e: Throwable) {
            logger.logE(TAG) { "Cannot parse <set>\n" + e.stackTraceToString() }
        }
    }

    private fun animationBuilderFor(attributeName: SVGAttr?, target: ElementBase): Animation.Builder<out Animation> {
        return when {
            attributeName != null && isColorAttribute(attributeName) -> {
                AnimateColor.Builder(requireSvgDocument(), target.parent)
            }

            attributeName == SVGAttr.stroke_dasharray -> {
                AnimateDashArray.Builder(requireSvgDocument(), target.parent)
            }

            attributeName == SVGAttr.d || attributeName == SVGAttr.points -> {
                AnimatePath.Builder(requireSvgDocument(), target.parent)
            }

            else -> {
                AnimateFloat.Builder(requireSvgDocument(), target.parent)
            }
        }
    }

    @Throws(KSVGParseException::class)
    private fun use(attributes: Attributes) {
        debug { "<use>" }

        val currentElement = requireCurrentElement()
        val builder = Use.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun image(attributes: Attributes) {
        debug { "<image>" }

        val currentElement = requireCurrentElement()
        val builder = Image.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }



    //=========================================================================
    @Throws(KSVGParseException::class)
    private fun path(attributes: Attributes) {
        debug { "<path>" }

        val currentElement = requireCurrentElement()
        val builder = PathShape.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }

    //=========================================================================
    // <rect> element
    @Throws(KSVGParseException::class)
    private fun rect(attributes: Attributes) {
        debug { "<rect>" }

        val currentElement = requireCurrentElement()
        val builder = RectShape.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }

    //=========================================================================
    // <circle> element
    @Throws(KSVGParseException::class)
    private fun circle(attributes: Attributes) {
        debug { "<circle>" }

        val currentElement = requireCurrentElement()
        val builder = CircleShape.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }

    //=========================================================================
    // <ellipse> element
    @Throws(KSVGParseException::class)
    private fun ellipse(attributes: Attributes) {
        debug { "<ellipse>" }

        val currentElement = requireCurrentElement()
        val builder = EllipseShape.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }


    //=========================================================================
    // <line> element
    @Throws(KSVGParseException::class)
    private fun line(attributes: Attributes) {
        debug { "<line>" }

        val currentElement = requireCurrentElement()
        val builder = LineShape.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun polyline(attributes: Attributes) {
        debug { "<polyline>" }

        val currentElement = requireCurrentElement()
        val builder = PolyLineShape.Builder<PolyLineShape>(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun polygon(attributes: Attributes) {
        debug { "<polygon>" }

        val currentElement = requireCurrentElement()
        val builder = PolygonShape.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        currentAnimationElement = obj
    }

    //=========================================================================
    // <text> element
    @Throws(KSVGParseException::class)
    private fun text(attributes: Attributes) {
        debug { "<text>" }

        val currentElement = requireCurrentElement()
        val builder = Text.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <tspan> element
    @Throws(KSVGParseException::class)
    private fun tspan(attributes: Attributes) {
        debug { "<tspan>" }

        val currentElement = requireCurrentElement()
        checkState(currentElement is TextContainer) { "Invalid document. <tspan> elements are only valid inside <text> or other <tspan> elements." }
        val builder = TSpan.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        
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
    @Throws(KSVGParseException::class)
    private fun tref(attributes: Attributes) {
        debug { "<tref>" }

        val currentElement = requireCurrentElement()
        if (currentElement is TextContainer) {
            val builder = TRef.Builder(requireSvgDocument(), currentElement)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            currentElement.addChild(obj)
            obj.textRoot = if (currentElement is TextRoot) {
                currentElement
            } else {
                (currentElement as TextChild).textRoot
            }
        } else {
            // A <tref> directly under <svg>/<g> is not strictly valid SVG 1.1, but
            // browsers render it as if it were a top-level <text>. Wrap it in a
            // synthetic <text> so it gains a text root and is drawn.
            val syntheticText = Text.Builder(requireSvgDocument(), currentElement).build()
            currentElement.addChild(syntheticText)

            val builder = TRef.Builder(requireSvgDocument(), syntheticText)
            builder.parseAttributes(attributes)
            val obj = builder.build()

            syntheticText.addChild(obj)
            obj.textRoot = syntheticText
        }
    }

    //=========================================================================
    // <switch> element
    @Throws(KSVGParseException::class)
    private fun switch(attributes: Attributes) {
        debug { "<switch>" }

        val currentElement = requireCurrentElement()
        val builder = Switch.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun symbol(attributes: Attributes) {
        debug { "<symbol>" }

        val currentElement = requireCurrentElement()
        val builder = Symbol.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }


    @Throws(KSVGParseException::class)
    private fun marker(attributes: Attributes) {
        debug { "<marker>" }

        val currentElement = requireCurrentElement()
        val builder = Marker.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()

        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <linearGradient> element
    @Throws(KSVGParseException::class)
    private fun linearGradient(attributes: Attributes) {
        debug { "<linearGradient>" }

        val currentElement = requireCurrentElement()
        val builder = GradientLinear.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <radialGradient> element
    @Throws(KSVGParseException::class)
    private fun radialGradient(attributes: Attributes) {
        debug { "<radialGradient>" }

        val currentElement = requireCurrentElement()
        val builder = GradientRadial.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // Gradient <stop> element
    @Throws(KSVGParseException::class)
    private fun stop(attributes: Attributes) {
        debug { "<stop>" }

        val currentElement = requireCurrentElement()

        checkState(currentElement is Gradient) {
            "Invalid document. <stop> elements are only valid inside <linearGradient> or <radialGradient> elements."
        }

        val builder = Stop.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <solidColor> element
    @Throws(KSVGParseException::class)
    private fun solidColor(attributes: Attributes) {
        debug { "<solidColor>" }

        val currentElement = requireCurrentElement()
        val builder = SolidColor.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <clipPath> element
    @Throws(KSVGParseException::class)
    private fun clipPath(attributes: Attributes) {
        debug { "<clipPath>" }

        val currentElement = requireCurrentElement()
        val builder = ClipPath.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <textPath> element
    @Throws(KSVGParseException::class)
    private fun textPath(attributes: Attributes) {
        debug { "<textPath>" }

        val currentElement = requireCurrentElement()
        val builder = TextPath.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
        obj.textRoot = if (currentElement is TextRoot) {
            currentElement
        } else {
            (currentElement as TextChild).textRoot
        }
    }

    //=========================================================================
    // <pattern> element
    @Throws(KSVGParseException::class)
    private fun pattern(attributes: Attributes) {
        debug { "<pattern>" }

        val currentElement = requireCurrentElement()
        val builder = Pattern.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // <view> element
    @Throws(KSVGParseException::class)
    private fun view(attributes: Attributes) {
        debug { "<view>" }

        val currentElement = requireCurrentElement()
        val builder = View.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }


    //=========================================================================
    // <mask> element
    @Throws(KSVGParseException::class)
    private fun mask(attributes: Attributes) {
        debug { "<mask>" }

        val currentElement = requireCurrentElement()
        val builder = Mask.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    //=========================================================================
    // Parsing <style> element. Very basic CSS parser.
    //=========================================================================
    @Throws(KSVGParseException::class)
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

        if (isTextCSS && CSSParser.mediaMatches(media, MediaType.screen)) {
            inStyleElement = true
        } else {
            ignoring = true
            ignoreDepth = 1
        }
    }

    private fun parseCSSStyleSheet(sheet: String) {
        val parser = CSSParser(
            deviceMediaType = MediaType.screen,
            source = Source.Document,
            externalFileResolver = externalFileResolver,
            logger = logger
        )
        requireSvgDocument().addCSSRules(ruleset = parser.parse(sheet))
    }

    //=========================================================================
    // <filter> element
    @Throws(KSVGParseException::class)
    private fun filter(attributes: Attributes) {
        debug { "<filter>" }

        val currentElement = requireCurrentElement()
        val builder = Filter.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feBlend(attributes: Attributes) {
        debug { "<feBlend>" }
        val currentElement = requireCurrentElement()
        val builder = FeBlend.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feColorMatrix(attributes: Attributes) {
        debug { "<feColorMatrix>" }
        val currentElement = requireCurrentElement()
        val builder = FeColorMatrix.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feComponentTransfer(attributes: Attributes) {
        debug { "<feComponentTransfer>" }
        val currentElement = requireCurrentElement()
        val builder = FeComponentTransfer.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feFunc(attributes: Attributes, channel: FeFunc.Channel) {
        debug { "<feFunc${channel.name}>" }
        val currentElement = requireCurrentElement()
        val builder = FeFunc.Builder(
            document = requireSvgDocument(),
            parent = currentElement,
            channel = channel
        )
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feConvolveMatrix(attributes: Attributes) {
        debug { "<feConvolveMatrix>" }
        val currentElement = requireCurrentElement()
        val builder = FeConvolveMatrix.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feComposite(attributes: Attributes) {
        debug { "<feComposite>" }
        val currentElement = requireCurrentElement()
        val builder = FeComposite.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feDisplacementMap(attributes: Attributes) {
        debug { "<feDisplacementMap>" }
        val currentElement = requireCurrentElement()
        val builder = FeDisplacementMap.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feDiffuseLighting(attributes: Attributes) {
        debug { "<feDiffuseLighting>" }
        val currentElement = requireCurrentElement()
        val builder = FeDiffuseLighting.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feDistantLight(attributes: Attributes) {
        debug { "<feDistantLight>" }
        val currentElement = requireCurrentElement()
        if (currentElement !is FeLighting) {
            return
        }
        val builder = FeDistantLight.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.light = obj
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun fePointLight(attributes: Attributes) {
        debug { "<fePointLight>" }
        val currentElement = requireCurrentElement()
        if (currentElement !is FeLighting) {
            return
        }
        val builder = FePointLight.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.light = obj
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feSpecularLighting(attributes: Attributes) {
        debug { "<feSpecularLighting>" }
        val currentElement = requireCurrentElement()
        val builder = FeSpecularLighting.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feSpotLight(attributes: Attributes) {
        debug { "<feSpotLight>" }
        val currentElement = requireCurrentElement()
        if (currentElement !is FeLighting) {
            return
        }
        val builder = FeSpotLight.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.light = obj
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feFlood(attributes: Attributes) {
        debug { "<feFlood>" }
        val currentElement = requireCurrentElement()
        val builder = FeFlood.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feGaussianBlur(attributes: Attributes) {
        debug { "<feGaussianBlur>" }
        val currentElement = requireCurrentElement()
        val builder = FeGaussianBlur.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feDropShadow(attributes: Attributes) {
        debug { "<feDropShadow>" }
        val currentElement = requireCurrentElement()
        val builder = FeDropShadow.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feImage(attributes: Attributes) {
        debug { "<feImage>" }
        val currentElement = requireCurrentElement()
        val builder = FeImage.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feMerge(attributes: Attributes) {
        debug { "<feMerge>" }
        val currentElement = requireCurrentElement()
        val builder = FeMerge.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feMergeNode(attributes: Attributes) {
        debug { "<feMergeNode>" }
        val currentElement = requireCurrentElement()
        val builder = FeMergeNode.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feOffset(attributes: Attributes) {
        debug { "<feOffset>" }
        val currentElement = requireCurrentElement()
        val builder = FeOffset.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feTurbulence(attributes: Attributes) {
        debug { "<feTurbulence>" }
        val currentElement = requireCurrentElement()
        val builder = FeTurbulence.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feMorphology(attributes: Attributes) {
        debug { "<feMorphology>" }
        val currentElement = requireCurrentElement()
        val builder = FeMorphology.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    @Throws(KSVGParseException::class)
    private fun feTile(attributes: Attributes) {
        debug { "<feTile>" }
        val currentElement = requireCurrentElement()
        val builder = FeTile.Builder(requireSvgDocument(), currentElement)
        builder.parseAttributes(attributes)
        val obj = builder.build()
        currentElement.addChild(obj)
        this.currentElement = obj
    }

    companion object {
        private const val TAG = "SVGParser"

        private const val SVG_NAMESPACE = "http://www.w3.org/2000/svg"
        internal const val XLINK_NAMESPACE = "http://www.w3.org/1999/xlink"

        private const val XML_STYLESHEET_PROCESSING_INSTRUCTION = "xml-stylesheet"

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

        private const val DEBUG_MODE: Boolean = false
    }
}
