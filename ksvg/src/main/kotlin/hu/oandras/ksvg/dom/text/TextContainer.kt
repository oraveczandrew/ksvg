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
import hu.oandras.ksvg.KSVGParseException
import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Conditional
import hu.oandras.ksvg.dom.core.ConditionalContainer
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SvgObject
import hu.oandras.ksvg.parser.checkState

internal abstract class TextContainer(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix? = null,
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
) {
    @Throws(KSVGParseException::class)
    override fun addChild(elem: SvgObject) {
        checkState(elem is TextChild) {
            "Text content elements cannot contain $elem elements."
        }
        super.addChild(elem)
    }

    abstract class Builder<T : TextContainer>(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalContainer.Builder<T>(document, parent)
}
