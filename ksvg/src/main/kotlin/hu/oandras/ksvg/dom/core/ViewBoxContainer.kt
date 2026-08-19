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

import android.graphics.Matrix
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.PreserveAspectRatio
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.parser.TextScanner
import org.xml.sax.Attributes

internal abstract class ViewBoxContainer(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix? = null,
    preserveAspectRatio: PreserveAspectRatio?,
    @JvmField
    var viewBox: Box?
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
    preserveAspectRatio = preserveAspectRatio,
) {

    abstract class Builder<T : ViewBoxContainer>(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalContainer.Builder<T>(document, parent) {
        private var viewBox: Box? = null

        protected fun getViewBox(): Box? = viewBox

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.viewBox -> viewBox = parseViewBox(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        @Throws(KSVGParseException::class)
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
                throw KSVGParseException("Invalid viewBox definition - should have four numbers")
            }
            if (width < 0) {
                throw KSVGParseException("Invalid viewBox. width cannot be negative")
            }
            if (height < 0) {
                throw KSVGParseException("Invalid viewBox. height cannot be negative")
            }

            return Box(minX, minY, width, height)
        }
    }
}
