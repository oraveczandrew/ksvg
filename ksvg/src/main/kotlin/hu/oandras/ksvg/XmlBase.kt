/*
 *    Copyright 2026 András Oravecz <info@oandras.hu>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        https://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package hu.oandras.ksvg

import java.net.URI

/**
 * XML Base (https://www.w3.org/TR/xmlbase/) helpers for resolving relative
 * resource references (`<image>` / `<feImage>` file hrefs, `<a>` click URLs)
 * against the in-scope `xml:base` chain.
 *
 * KSVG parses `xml:base` on every element and tracks the effective
 * (parent-resolved) base URI, but it never resolves references itself: the raw `href`
 * and the in-scope base reach [ExternalFileResolver] side by side, and the
 * host decides how to combine them (these helpers implement the default
 * RFC 3986 behavior).
 */
public fun effectiveXmlBase(parentBase: String?, ownBase: String?): String? {
    if (ownBase.isNullOrEmpty()) {
        return parentBase?.ifEmpty { null }
    }
    if (parentBase.isNullOrEmpty()) {
        return ownBase
    }
    return try {
        URI(parentBase).resolve(ownBase).toString()
    } catch (_: Exception) {
        ownBase
    }
}

/**
 * Resolves [href] against [base] per RFC 3986.
 *
 * Same-document fragment references (`#id`) are internal lookups, never
 * URIs, and pass through untouched; so do `href`s without an in-scope base.
 * Absolute `href`s (including `data:` URLs) resolve to themselves. Returns
 * the original [href] when either side is not a valid URI.
 */
public fun resolveHrefAgainstBase(base: String?, href: String): String {
    if (href.startsWith("#") || base.isNullOrEmpty()) {
        return href
    }
    return try {
        URI(base).resolve(href).toString()
    } catch (_: Exception) {
        href
    }
}
