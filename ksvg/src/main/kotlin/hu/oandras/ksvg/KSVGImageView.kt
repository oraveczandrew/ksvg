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

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import android.widget.ImageView
import hu.oandras.ksvg.SVG.Companion.getFromResource
import hu.oandras.ksvg.SVG.Companion.getFromString
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream

/**
 * SVGImageView is a View widget that allows users to include SVG images in their layouts.
 * 
 * It is implemented as a thin layer over `android.widget.ImageView`.
 * 
 * <h2>XML attributes</h2>
 * <dl>
 * <dt>`svg`</dt>
 * <dd>A resource reference, or a file name, of an SVG in your application</dd>
 * <dt>`css`</dt>
 * <dd>Optional extra CSS to apply when rendering the SVG</dd>
</dl> * 
 */
@SuppressLint("AppCompatCustomView", "UseKtx")
@Suppress("unused")
public class KSVGImageView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0
) : ImageView(
    context,
    attrs,
    defStyle
) {
    private var svg: SVG? = null
    private val renderOptions: RenderOptions = RenderOptions.create()
    private var onSvgClickListener: OnSvgClickListener? = null

    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private var loadJob: Job? = null

    init {
        if (!isInEditMode) {
            val a = context.theme.obtainStyledAttributes(attrs, R.styleable.SVGImageView, defStyle, 0)
            try {
                // Check for css attribute
                val css = a.getString(R.styleable.SVGImageView_css)
                if (css != null) {
                    renderOptions.css(css = css, externalFileResolver = null)
                }

                // Check whether svg attribute is a resourceId
                val resourceId = a.getResourceId(R.styleable.SVGImageView_svg, -1)
                if (resourceId != -1) {
                    setImageResource(resourceId)
                } else {
                    // Check whether svg attribute is a string.
                    // Could be a URL/filename or an SVG itself
                    val url = a.getString(R.styleable.SVGImageView_svg)
                    if (url != null) {
                        val uri = Uri.parse(url)
                        if (!internalSetImageURI(uri)) {
                            // Not a URL, so try loading it as an asset filename
                            if (!internalSetImageAsset(url)) {
                                // Last chance, maybe there is an actual SVG in the string
                                // If the SVG is in the string, then we will assume it is not very large, and thus doesn't need to be parsed in the background.
                                setFromString(url)
                            }
                        }
                    }
                }
            } finally {
                a.recycle()
            }
        }
    }

    /**
     * Directly set the SVG that should be rendered by this view.
     * @param svg An `SVG` instance

     */
    public fun setSVG(svg: SVG) {
        this.svg = svg
        doRender()
    }

    /**
     * Directly set the SVG and the CSS.
     * @param svg An `SVG` instance
     * @param css Optional extra CSS to apply when rendering

     */
    public fun setSVG(svg: SVG, css: String?, externalFileResolver: ExternalFileResolver?) {
        this.svg = svg
        renderOptions.css(css, externalFileResolver)

        doRender()
    }

    /**
     * Directly set the CSS.
     * @param css Extra CSS to apply when rendering

     */
    public fun setCSS(css: String?, externalFileResolver: ExternalFileResolver?) {
        renderOptions.css(css, externalFileResolver)
        doRender()
    }

    /**
     * Sets a listener for click events on `<a>` elements in the rendered SVG.
     * @param listener the listener to invoke when an `<a>` element is clicked, or `null` to remove.
     */
    public fun setOnSvgClickListener(listener: OnSvgClickListener?) {
        onSvgClickListener = listener
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_UP) {
            val listener = onSvgClickListener
            if (listener != null) {
                val drawable = drawable as? KSVGDrawable
                if (drawable != null) {
                    val href = drawable.hitTest(event.x, event.y)
                    if (href != null) {
                        listener.onLinkClicked(href)
                        return true
                    }
                }
            }
        }
        return super.onTouchEvent(event)
    }

    /**
     * Load an SVG image from the given resource id.
     * @param resourceId the id of an Android resource in your application
     */
    override fun setImageResource(resourceId: Int) {
        loadResource(resourceId)
    }

    private fun loadResource(resourceId: Int) {
        loadJob?.cancel()
        loadJob = scope.launch {
            val loadedSvg = withContext(Dispatchers.IO) {
                try {
                    getFromResource(context, resourceId)
                } catch (e: KSVGParseException) {
                    Log.e(
                        "SVGImageView",
                        String.format("Error loading resource 0x%x: %s", resourceId, e.message)
                    )
                    null
                }
            }
            this@KSVGImageView.svg = loadedSvg
            doRender()
        }
    }

    /**
     * Load an SVG image from the given resource URI.
     * @param uri the URI of an Android resource in your application
     */
    override fun setImageURI(uri: Uri?) {
        if (!internalSetImageURI(uri)) Log.e("SVGImageView", "File not found: $uri")
    }

    /**
     * Load an SVG image from the given asset filename.
     * @param filename the file name of an SVG in the assets folder in your application
     */
    public fun setImageAsset(filename: String) {
        if (!internalSetImageAsset(filename)) Log.e("SVGImageView", "File not found: $filename")
    }

    //===============================================================================================
    /*
    * Attempt to set a picture from a Uri. Return true if it worked.
    */
    private fun internalSetImageURI(uri: Uri?): Boolean {
        return uri != null && try {
            val inputStream = context.contentResolver.openInputStream(uri)
            loadFromInputStream(inputStream)
            true
        } catch (_: FileNotFoundException) {
            false
        }
    }

    private fun internalSetImageAsset(filename: String): Boolean {
        return try {
            val inputStream = context.assets.open(filename)
            loadFromInputStream(inputStream)
            true
        } catch (_: IOException) {
            false
        }
    }

    private fun loadFromInputStream(inputStream: InputStream?) {
        if (inputStream == null) return
        loadJob?.cancel()
        loadJob = scope.launch {
            val loadedSvg = withContext(Dispatchers.IO) {
                try {
                    SVG.getFromInputStream(inputStream)
                } catch (e: KSVGParseException) {
                    Log.e("SVGImageView", "Parse error loading URI: " + e.message)
                    null
                } finally {
                    try {
                        inputStream.close()
                    } catch (_: IOException) { /* do nothing */
                    }
                }
            }
            this@KSVGImageView.svg = loadedSvg
            doRender()
        }
    }

    private fun setFromString(url: String) {
        try {
            svg = getFromString(url)
            doRender()
        } catch (_: KSVGParseException) {
            // Failed to interpret url as a resource, a filename, or an actual SVG...
            Log.e("SVGImageView", "Could not find SVG at: $url")
        }
    }

    private fun doRender() {
        val svg = svg ?: return
        setLayerType(LAYER_TYPE_SOFTWARE, null)
        setImageDrawable(svg.toDrawable(renderOptions))
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        scope.cancel()
        // Release pooled bitmap memory eagerly: the drawable (and its native
        // pixel buffers) would otherwise linger until GC (audit D5).
        (drawable as? KSVGDrawable)?.trimMemory()
    }
}
