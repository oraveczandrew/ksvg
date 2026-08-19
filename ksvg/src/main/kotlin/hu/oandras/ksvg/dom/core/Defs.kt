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

// A <defs> object contains objects that are not rendered directly but are instead
// referenced from other parts of the file.
internal class Defs(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
) : Group(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
), NotDirectlyRendered {
    override fun getNodeName(): String {
        return "defs"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Group.Builder<Defs>(document, parent) {
        override fun build(): Defs {
            return Defs(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform()
            )
        }
    }
}