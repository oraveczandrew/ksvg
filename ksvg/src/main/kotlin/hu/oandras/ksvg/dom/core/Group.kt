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
import hu.oandras.ksvg.dom.SVGImpl

// An SVG element that can contain other elements.
internal open class Group(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
) : ConditionalContainer(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
) {

    override fun getNodeName(): String {
        return "g"
    }

    open class Builder<T : Group>(
        document: SVGImpl,
        parent: Container?,
    ) : ConditionalContainer.Builder<T>(document, parent) {
        @Suppress("UNCHECKED_CAST")
        override fun build(): T {
            return Group(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform()
            ) as T
        }
    }
}
