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

import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SvgObjectImpl

internal class TextSequence(
    id: String?,
    document: SVGImpl,
    parent: Container?,
    spacePreserve: Boolean?,
    @JvmField
    var text: String
) : SvgObjectImpl(
    id = id,
    document = document,
    parent = parent,
    spacePreserve = spacePreserve,
), TextChild {
    override var textRoot: TextRoot? = null

    override fun toString(): String {
        return "TextChild: '$text'"
    }
}