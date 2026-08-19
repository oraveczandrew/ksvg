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
import hu.oandras.ksvg.dom.core.ContainerImpl
import hu.oandras.ksvg.dom.core.SVGAttr
import org.xml.sax.Attributes

internal class FeMergeNode(
    baseParams: BaseParams,
    @JvmField
    val `in`: String?,
) : ContainerImpl(
    baseParams = baseParams,
) {

    override fun getNodeName(): String {
        return "feMergeNode"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : ContainerImpl.Builder<FeMergeNode>(
        document = document,
        parent = parent
    ) {
        private var `in`: String? = null

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.`in` -> `in` = value
                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }

        override fun build(): FeMergeNode {
            return FeMergeNode(
                baseParams = getBaseParams(),
                `in` = `in`,
            )
        }
    }
}