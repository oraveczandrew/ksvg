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
import hu.oandras.ksvg.dom.SVGImpl
import org.xml.sax.Attributes

internal class ClipPath(
    baseParams: BaseParams,
    conditionalBundle: Conditional,
    transform: Matrix?,
    @JvmField
    val clipPathUnitsAreUser: Boolean?,
) : Group(
    baseParams = baseParams,
    conditionalBundle = conditionalBundle,
    transform = transform,
), NotDirectlyRendered {

    override fun getNodeName(): String {
        return NODE_NAME
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Group.Builder<ClipPath>(
        document = document,
        parent = parent
    ) {
        private var clipPathUnitsAreUser: Boolean? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.clipPathUnits -> clipPathUnitsAreUser = when (value) {
                    "objectBoundingBox" -> false
                    "userSpaceOnUse" -> true
                    else -> throw KSVGParseException("Invalid value for attribute clipPathUnits")
                }
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): ClipPath {
            return ClipPath(
                baseParams = getBaseParams(),
                conditionalBundle = getSvgConditionalBundle(),
                transform = getTransform(),
                clipPathUnitsAreUser = clipPathUnitsAreUser,
            )
        }
    }

    companion object {
        const val NODE_NAME: String = "clipPath"
    }
}