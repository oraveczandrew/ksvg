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

package hu.oandras.ksvg.dom.text

import android.graphics.Matrix
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.Group
import hu.oandras.ksvg.dom.core.SVGAttr
import org.xml.sax.Attributes

// A linking element (we don't currently do anything with this. It is basically just treated like a Group.)
internal class A(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
    @JvmField
    val href: String?
) : Group(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform
) {

    override fun getNodeName(): String {
        return "a"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Group.Builder<A>(document, parent) {
        private var href: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.href -> href = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }
            return true
        }

        override fun build(): A {
            return A(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform(),
                href = href
            )
        }
    }
}