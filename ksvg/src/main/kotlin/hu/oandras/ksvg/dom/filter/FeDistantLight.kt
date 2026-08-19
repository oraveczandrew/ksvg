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

package hu.oandras.ksvg.dom.filter

import hu.oandras.ksvg.dom.SVGImpl
import hu.oandras.ksvg.dom.core.Container
import hu.oandras.ksvg.dom.core.SVGAttr
import hu.oandras.ksvg.parser.parseFloat
import org.xml.sax.Attributes

internal class FeDistantLight(
    baseParams: BaseParams,
    @JvmField
    val azimuth: Float,
    @JvmField
    val elevation: Float,
) : Lighting(
    baseParams = baseParams,
) {

    override fun getNodeName(): String {
        return "feDistantLight"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Lighting.Builder<FeDistantLight>(
        document = document,
        parent = parent
    ) {
        private var azimuth: Float = 0f

        private var elevation: Float = 0f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.azimuth -> azimuth = parseFloat(value)
                SVGAttr.elevation -> elevation = parseFloat(value)
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeDistantLight {
            return FeDistantLight(
                baseParams = getBaseParams(),
                azimuth = azimuth,
                elevation = elevation,
            )
        }
    }
}