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

package hu.oandras.ksvg.css

/**
 * This is a container for pre-parsed CSS that can be used to avoid parsing raw CSS string on each
 * render. It can be passed to RenderOptions like this:
 * <pre class="code-block">
 * `CSS css = CSS.getFromString("...some complex and long css here that takes time to parse...") RenderOption renderOptions = RenderOptions.create(); renderOptions.css(css) // And now you can reuse the already parsed css svg1.renderToCanvas(canvas, renderOptions); svg2.renderToCanvas(canvas, renderOptions); svg3.renderToCanvas(canvas, renderOptions); `
</pre> *
 */
public class CSS internal constructor(
    @JvmField
    internal val cssRuleSet: CSSParser.Ruleset
) {

    internal constructor(css: String) : this(
        cssRuleSet = CSSParser(
            source = CSSParser.Source.RenderOptions,
        ).parse(css)
    )

    public companion object {
        /**
         * @param css CSS string to parse
         * @return pre-parsed CSS
         */
        public fun getFromString(css: String): CSS {
            return CSS(css)
        }
    }
}