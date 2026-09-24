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

internal class FeSpotLight(
    baseParams: BaseParams,
    @JvmField
    val x: Float,
    @JvmField
    val y: Float,
    @JvmField
    val z: Float,
    @JvmField
    val pointsAtX: Float,
    @JvmField
    val pointsAtY: Float,
    @JvmField
    val pointsAtZ: Float,
    @JvmField
    val limitingConeAngle: Float?,
    /**
     * Beam-focus exponent (default 1.0). The software lighting kernels evaluate
     * it per light; the GPU path declines non-default values to software.
     */
    @JvmField
    val specularExponent: Float,
) : Lighting(
    baseParams = baseParams,
) {

    override fun getNodeName(): String {
        return "feSpotLight"
    }

    class Builder(
        document: SVGImpl,
        parent: Container?,
    ) : Lighting.Builder<FeSpotLight>(
        document = document,
        parent = parent
    ) {
        private var x: Float = 0f
        private var y: Float = 0f
        private var z: Float = 0f
        private var pointsAtX: Float = 0f
        private var pointsAtY: Float = 0f
        private var pointsAtZ: Float = 0f
        private var limitingConeAngle: Float? = null
        private var specularExponent: Float = 1f

        override fun onAttribute(
            attributes: Attributes,
            index: Int,
            attr: SVGAttr,
            value: String
        ): Boolean {
            when (attr) {
                SVGAttr.x -> x = parseFloat(value)
                SVGAttr.y -> y = parseFloat(value)
                SVGAttr.z -> z = parseFloat(value)
                SVGAttr.pointsAtX -> pointsAtX = parseFloat(value)
                SVGAttr.pointsAtY -> pointsAtY = parseFloat(value)
                SVGAttr.pointsAtZ -> pointsAtZ = parseFloat(value)
                SVGAttr.limitingConeAngle -> limitingConeAngle = parseFloat(value)
                SVGAttr.specularExponent -> specularExponent = parseFloat(value)

                else -> return super.onAttribute(attributes, index, attr, value)
            }

            return true
        }


        override fun build(): FeSpotLight {
            return FeSpotLight(
                baseParams = getBaseParams(),
                x = x,
                y = y,
                z = z,
                pointsAtX = pointsAtX,
                pointsAtY = pointsAtY,
                pointsAtZ = pointsAtZ,
                limitingConeAngle = limitingConeAngle,
                specularExponent = specularExponent,
            )
        }
    }
}