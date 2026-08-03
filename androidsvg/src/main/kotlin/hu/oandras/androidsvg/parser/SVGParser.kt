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
package hu.oandras.androidsvg.parser

import hu.oandras.androidsvg.SVG
import hu.oandras.androidsvg.SVGExternalFileResolver
import hu.oandras.androidsvg.SVGParseException
import hu.oandras.androidsvg.dom.SVGImpl
import java.io.InputStream

internal interface SVGParser {
    /**
     * Try to parse the stream contents to an [SVG] instance.
     */
    @Throws(SVGParseException::class)
    fun parseStream(input: InputStream): SVGImpl

    /**
     * Tells the parser whether to allow the expansion of internal entities.
     * An example of a document containing an internal entities is:
     */
    fun setInternalEntitiesEnabled(enable: Boolean): SVGParser

    /**
     * Register an [SVGExternalFileResolver] instance that the parser should use when resolving
     * external references such as images, fonts, and CSS stylesheets.
     */
    fun setExternalFileResolver(fileResolver: SVGExternalFileResolver?): SVGParser
}