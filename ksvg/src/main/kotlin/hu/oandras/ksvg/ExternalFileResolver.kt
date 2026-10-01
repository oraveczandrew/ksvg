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
package hu.oandras.ksvg

import android.graphics.Bitmap
import android.graphics.Typeface

/**
 * Resolver class used by the renderer when resolving font, image, and external CSS references.
 *
 * When KSVG encounters a reference to an external object, such as an image, it will call the
 * associated method on this class in an attempt to load it.
 *
 * The default behavior of each method is to tell KSVG that the reference could not be found.
 * Extend this class and override the methods if you want to customize how KSVG treats font, image, and external CSS references.
 *
 * Security and scope contract (applies to every override):
 * - KSVG performs no network fetch itself and resolves no references: `href`
 *   values (`../foo.png`, `/abs/path`, `http(s)://…`) reach your resolver
 *   verbatim, together with the in-scope `xml:base` (or null when there is
 *   none). Combine them with [resolveHrefAgainstBase] (or your own policy);
 *   enforce your own allow-list there (no `..` escapes, no unexpected
 *   schemes) if the SVG source is untrusted.
 * - Same-document fragment references (`#id`) never reach the resolver; they
 *   are internal lookups.
 * - `data:` image URLs decode only with `;base64` payloads; anything else falls
 *   through to [resolveImage] (which then usually also declines).
 */
public open class ExternalFileResolver {
    /**
     * A stylesheet fetched through [resolveCSSStyleSheet].
     *
     * @property url the effective URL the content was loaded from, as reported by the
     *   host (after its own normalization or redirects). The library trusts it as the
     *   base for relative `@import`s nested inside [css].
     * @property css the stylesheet text.
     */
    public data class ResolvedStylesheet(
        @JvmField
        public val url: String,
        @JvmField
        public val css: String,
    )

    /**
     * Called by renderer to resolve font references in &lt;text&gt; elements.
     * 
     * 
     * An implementation of this method should return a `Typeface` instance, or null
     * if you want the renderer to ignore this font request.
     * 
     * 
     * Note that KSVG does not attempt to cache Typeface references.  If you want
     * them cached, for speed or memory reasons, you should do so yourself.
     * 
     * 
     * If you return are using Android O or later, and return a variable Truetype or Opentype font,
     * then KSVG will automatically set the weight, stretch and oblique slant for you. Note that
     * it is quite rare for variable fonts to include the italic variant. Commonly, there will be two
     * files, one with the regular glyphs and one with the italic ones.  In those cases, use the
     * {`fontStyle`} parameter to choose between those two font files, and leave KSVG to do
     * the rest.
     * 
     * @param fontFamily Font family name, as specified in a font-family style attribute.
     * @param fontWeight Font weight as specified in a font-weight style attribute (typically 100 - 900).
     * @param fontStyle  Font style as specified in a font-style style attribute ("normal",
     * "italic", "oblique").
     * @param fontStretch  Font stretch as specified in a font-stretch style attribute. It is treated
     * as a percentage value, where 100 maps to "normal". The typical range is
     * between 50 ("ultra-condensed") and 200 ("ultra-expanded").
     * @return an Android Typeface instance, or null
     */
    public open fun resolveFont(
        fontFamily: String,
        fontWeight: Float,
        fontStyle: String,
        fontStretch: Float
    ): Typeface? {
        return null
    }

    /**
     * Called by renderer to resolve image file references in &lt;image&gt; elements.
     * 
     * 
     * An implementation of this method should return a `Bitmap` instance, or null if
     * you want the renderer to ignore this image.
     * 
     * 
     * Note that KSVG does not attempt to cache Bitmap references.  If you want
     * them cached, for speed or memory reasons, you should do so yourself.
     * 
     * @param filename the filename as provided in the xlink:href attribute of a &lt;image&gt; element.
     * @param baseUri the in-scope `xml:base` for the referencing element, or null when there is none.
     *   Resolve with [resolveHrefAgainstBase] unless you deliberately want raw-href behavior.
     * @return an Android Bitmap object, or null if the image could not be found.
     */
    public open fun resolveImage(filename: String, baseUri: String?): Bitmap? {
        return null
    }

    /**
     * Called by the parser to resolve CSS stylesheet file references in &lt;?xml-stylesheet?&gt;
     * processing instructions.
     * 
     * 
     * An implementation of this method should return a `String` whose contents
     * correspond to the URL passed in.
     * 
     * 
     * Note that KSVG does not attempt to cache stylesheet references.  If you want
     * them cached, for speed or memory reasons, you should do so yourself.
     * 
     * @param url the URL of the CSS file as it appears in the SVG file.
     * @param baseUri the base URI in scope for the reference, or null when unknown
     *   (`&lt;?xml-stylesheet?&gt;` resolves against the document base URL when the
     *   document was parsed with one; `@import` resolves against the importing
     *   stylesheet's reported URL).
     * @return the stylesheet and the effective URL it was loaded from, or null if
     *   the stylesheet could not be found.
     */
    public open fun resolveCSSStyleSheet(url: String, baseUri: String?): ResolvedStylesheet? {
        return null
    }

    /**
     * Called by renderer to determine whether a particular format is supported.  In particular,
     * this method is used in &lt;switch&gt; elements when processing `requiredFormats`
     * conditionals.
     * 
     * @param mimeType A MIME type (such as "image/jpeg").
     * @return true if your `resolveImage()` implementation supports this file format.
     */
    public open fun isFormatSupported(mimeType: String): Boolean {
        return false
    }
}
