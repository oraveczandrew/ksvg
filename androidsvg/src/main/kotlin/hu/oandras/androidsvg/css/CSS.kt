package hu.oandras.androidsvg.css

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