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
package hu.oandras.androidsvg

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class ViewsTest {

    @Throws(SVGParseException::class)
    @Test
    fun getViewList() {
        val test = "<?xml version=\"1.0\" standalone=\"no\"?>\n" +
                "<svg xmlns=\"http://www.w3.org/2000/svg\">" +
                "  <view id=\"normalView\" viewBox=\"0 0 100 100\"/>" +
                "  <g>" +
                "    <view id=\"halfView\"   viewBox=\"0 0 200 200\"/>" +
                "    <g>" +
                "      <view id=\"doubleView\" viewBox=\"0 0  50  50\"/>" +
                "    </g>" +
                "  </g>" +
                "</svg>"
        val svg: SVG = SVG.getFromString(test)

        val views: Set<String> = svg.viewList
        assertEquals(3, views.size)
        assertTrue(views.contains("normalView"))
        assertTrue(views.contains("halfView"))
        assertTrue(views.contains("doubleView"))
    }
}
