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

package hu.oandras.ksvg.dom.core

import androidx.collection.ArrayMap
import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.CSSTextScanner
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.animation.Animation
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.utils.forEachElement
import org.xml.sax.Attributes
import java.util.Collections

// Any object in the tree that corresponds to an SVG element
internal abstract class ElementBase(
    baseParams: BaseParams,
) : SvgObjectImpl(
    id = baseParams.id,
    document = baseParams.document,
    parent = baseParams.parent,
    spacePreserve = baseParams.spacePreserve
) {

    @JvmField
    val baseStyle: Style? = baseParams.baseStyle // style defined by explicit style attributes in the element (e.g., fill="black")
    @JvmField
    val style: Style? = baseParams.style // style expressed in a 'style' attribute (e.g., style="fill:black")
    @JvmField
    val classNames: List<String>? = baseParams.classNames // contents of the 'class' attribute
    @JvmField
    val attributes: Map<String, String>? = baseParams.attributes
    @JvmField
    val xmlBase: String? = baseParams.xmlBase // effective in-scope xml:base (parent-resolved), or null

    private var _animations: ArrayList<Animation>? = null

    val animations: List<Animation>?
        get() = _animations

    override fun toString(): String {
        return getNodeName()
    }

    override fun hasAnimationsOnTree(): Boolean {
        if (!_animations.isNullOrEmpty()) {
            return true
        }

        if (this is DomParent) {
            getChildren().forEachElement {
                if (it.hasAnimationsOnTree()) {
                    return true
                }
            }
        }

        return false
    }

    fun addAnimation(animation: Animation) {
        val animations = _animations ?: ArrayList<Animation>(1).also {
            _animations = it
        }
        animations.add(animation)
    }

    class BaseParams(
        @JvmField
        val id: String?,
        @JvmField
        val document: SVGImpl,
        @JvmField
        val parent: Container?,
        @JvmField
        val spacePreserve: Boolean?,
        @JvmField
        val baseStyle: Style?,
        @JvmField
        val style: Style?,
        @JvmField
        val classNames: List<String>?,
        @JvmField
        val attributes: Map<String, String>?,
        @JvmField
        val xmlBase: String?,
    ) {
        override fun toString(): String {
            return "BaseParams(id=$id, document=$document, parent=$parent, spacePreserve=$spacePreserve, baseStyle=$baseStyle, style=$style, classNames=$classNames, attributes=$attributes, xmlBase=$xmlBase)"
        }
    }

    open class Builder<T : SvgObjectImpl>(
        document: SVGImpl,
        parent: Container?,
    ) : SvgObjectImpl.Builder<T>(document, parent) {

        private var baseStyleUsed: Boolean = false
        private var inlineStyle: Style? = null
        private var classNames: List<String>? = null
        private var attributesMap: MutableMap<String, String>? = null

        protected fun getBaseParams(): BaseParams {
            return BaseParams(
                id = getId(),
                document = document,
                parent = parent,
                baseStyle = if (baseStyleUsed) {
                    document.internStyle(document.sharedBaseStyleBuilder.build())
                } else {
                    null
                },
                classNames = classNames,
                style = inlineStyle?.let(document::internStyle),
                spacePreserve = getSpacePreserve(),
                // Single-entry maps (the common case after id/class/style/d
                // skipping) don't need ArrayMap's two arrays; the built map is
                // never mutated afterward, so an immutable singleton is safe.
                attributes = attributesMap?.let { map ->
                    if (map.size == 1) {
                        val entry = map.entries.first()
                        Collections.singletonMap(entry.key, entry.value)
                    } else {
                        map
                    }
                },
                xmlBase = effectiveXmlBase(),
            )
        }

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            if (value.isEmpty()) {  // Empty attribute. Ignore it.
                return false
            }

            when (attr) {
                SVGAttr.style -> parseStyle(value)
                SVGAttr.`class` -> classNames = CSSParser.parseClassAttribute(value)
                // Typed by the ancestor (id/space/base) or parsed by shapes and
                // unused as a style property (`d`): super only, never stored.
                SVGAttr.id, SVGAttr.space, SVGAttr.base, SVGAttr.d -> {
                    return super.onAttribute(attributes, index, attr, value)
                }
                else -> {
                    // Foreign-namespace attributes (sodipodi:, inkscape:, ...)
                    // are never selector-matched (a ':' can't appear in the
                    // attribute-name grammar) and typed parsing uses local
                    // names, so there is nothing to retain them for. The prefix
                    // test tolerates both conventions for "no prefix": a bare
                    // local name (platform parser) and ":name" (empty prefix).
                    val localName = attributes.getLocalName(index)
                    val qName = attributes.getQName(index)
                    val prefixed = qName != null && localName != null &&
                        qName.length > localName.length + 1 &&
                        qName.endsWith(localName) &&
                        qName[qName.length - localName.length - 1] == ':'
                    if (!prefixed) {
                        val attributesMap = this.attributesMap
                            ?: ArrayMap<String, String>(attributes.length).also {
                                this.attributesMap = it
                            }
                        attributesMap[localName] = value
                    }

                    if (super.onAttribute(attributes, index, attr, value)) {
                        return true
                    }

                    // Presentation attributes share the document builder: reset
                    // once per element, so consecutive identical styles reuse
                    // the builder's lastBuilt instance without allocating.
                    val baseStyleBuilder = document.sharedBaseStyleBuilder
                    if (!baseStyleUsed) {
                        baseStyleBuilder.reset(Style.EMPTY)
                        baseStyleUsed = true
                    }
                    Style.processStyleProperty(
                        builder = baseStyleBuilder,
                        localName = localName,
                        value = value,
                        isFromAttribute = true
                    )
                    return false
                }
            }

            return true
        }

        private fun parseStyle(style: String) {
            if (style.isBlank()) return
            // Inline styles are context-free: the same text always parses to the same
            // Style, so share one built instance per document instead of reparsing.
            // containsKey is needed: a cached null (specifies nothing) is a hit too.
            val cache = document.inlineStyleCache
            if (cache.containsKey(style)) {
                inlineStyle = cache[style]
                return
            }
            val styleBuilder = Style().toBuilder()
            // CSSTextScanner strips block comments itself (only when present).
            val scan = CSSTextScanner(style)

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
                var important = false
                if (scan.consume('!')) {
                    scan.skipWhitespace()
                    // Be forgiving about malformed '!important' in inline styles.
                    important = scan.consumeIgnoreCase("important")
                    scan.skipWhitespace()
                }
                if (scan.empty() || scan.consume(';')) {
                    styleBuilder.lastTouchedFlag = 0L
                    Style.processStyleProperty(
                        builder = styleBuilder,
                        localName = propertyName,
                        value = propertyValue,
                        isFromAttribute = false
                    )
                    if (important && styleBuilder.lastTouchedFlag != 0L) {
                        styleBuilder.markImportant(styleBuilder.lastTouchedFlag)
                    }
                    scan.skipWhitespace()
                }
            }
            // An attribute that specifies nothing behaves as absent (null Style),
            // exactly like before; cache the null so repeats skip parsing too.
            // Note CSS-wide keywords (inherit/initial/unset) land in
            // cssWideKeywordFlags, not in the specified/important masks.
            if (styleBuilder.specifiedFlags == 0L && styleBuilder.specifiedFlags2 == 0L &&
                styleBuilder.importantFlags == 0L && styleBuilder.cssWideKeywordFlags == 0L
            ) {
                cache[style] = null
                return
            }
            styleBuilder.build().also {
                val canonical = document.internStyle(it)
                cache[style] = canonical
                inlineStyle = canonical
            }
        }
    }
}