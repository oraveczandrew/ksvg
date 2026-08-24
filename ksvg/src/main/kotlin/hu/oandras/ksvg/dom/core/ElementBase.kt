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

import hu.oandras.ksvg.css.CSSParser
import hu.oandras.ksvg.css.CSSTextScanner
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.animation.Animation
import hu.oandras.ksvg.dom.style.Style
import hu.oandras.ksvg.utils.forEachElement
import hu.oandras.ksvg.utils.toPattern
import org.xml.sax.Attributes
import java.util.regex.Matcher

// Any object in the tree that corresponds to an SVG element
internal abstract class ElementBase(
    @JvmField
    val baseParams: BaseParams,
) : SvgObjectImpl(
    id = baseParams.id,
    document = baseParams.document,
    parent = baseParams.parent,
    spacePreserve = baseParams.spacePreserve
) {

    @JvmField
    val baseStyle: Style? = baseParams.baseStyle // style defined by explicit style attributes in the element (e.g. fill="black")
    @JvmField
    val style: Style? = baseParams.style // style expressed in a 'style' attribute (e.g. style="fill:black")
    @JvmField
    val classNames: List<String>? = baseParams.classNames // contents of the 'class' attribute
    @JvmField
    val attributes: Map<String, String>? = baseParams.attributes

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
    ) {
        override fun toString(): String {
            return "BaseParams(id=$id, document=$document, parent=$parent, spacePreserve=$spacePreserve, baseStyle=$baseStyle, style=$style, classNames=$classNames, attributes=$attributes)"
        }
    }

    open class Builder<T : SvgObjectImpl>(
        document: SVGImpl,
        parent: Container?,
    ) : SvgObjectImpl.Builder<T>(document, parent) {

        private var baseStyleBuilder: Style.Builder? = null
        private var styleBuilder: Style.Builder? = null
        private var classNames: List<String>? = null
        private var attributesMap: MutableMap<String, String>? = null

        protected fun getBaseParams(): BaseParams {
            return BaseParams(
                id = getId(),
                document = document,
                parent = parent,
                baseStyle = baseStyleBuilder?.build(),
                classNames = classNames,
                style = styleBuilder?.build(),
                spacePreserve = getSpacePreserve(),
                attributes = attributesMap,
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

            val localName = attributes.getLocalName(index)
            val attributesMap = this.attributesMap ?: HashMap<String, String>().also {
                this.attributesMap = it
            }
            attributesMap[localName] = value

            when (attr) {
                SVGAttr.style -> parseStyle(value)
                SVGAttr.`class` -> classNames = CSSParser.parseClassAttribute(value)
                else -> {
                    if (super.onAttribute(attributes, index, attr, value)) {
                        return true
                    }

                    val baseStyleBuilder = this.baseStyleBuilder ?: Style().toBuilder().also {
                        this.baseStyleBuilder = it
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
                var important = false
                if (scan.consume('!')) {
                    scan.skipWhitespace()
                    // Be forgiving about malformed '!important' in inline styles.
                    important = scan.consume("important")
                    scan.skipWhitespace()
                }
                if (scan.empty() || scan.consume(';')) {
                    val styleBuilder = this.styleBuilder ?: Style().toBuilder().also {
                        this.styleBuilder = it
                    }
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
        }

        companion object {
            private val PATTERN_BLOCK_COMMENTS = "/\\*.*?\\*/".toPattern()
            private val blockCommentsMatcher: Matcher = PATTERN_BLOCK_COMMENTS.matcher("")
        }
    }
}