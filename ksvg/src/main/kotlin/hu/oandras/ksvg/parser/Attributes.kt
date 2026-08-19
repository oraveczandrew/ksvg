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

package hu.oandras.ksvg.parser

import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.utils.trimLowerThanSpace
import org.xml.sax.Attributes

internal fun Attributes.getTrimmedValue(index: Int): String {
    return getValue(index).trimLowerThanSpace()
}

internal fun Attributes.getSVGAttr(index: Int): SVGAttr {
    return SVGAttr.fromString(getLocalName(index))
}

internal inline fun Attributes.forEachKeyValue(
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

internal fun Attributes.getAttributeValueByLocalName(name: String): String? {
    for (i in 0 until length) {
        if (getLocalName(i) == name) {
            return getValue(i)
        }
    }

    return null
}