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

package hu.oandras.ksvg.glide

import android.graphics.drawable.Drawable
import com.bumptech.glide.load.resource.drawable.DrawableResource
import hu.oandras.ksvg.KSVGDrawable

public class KSVGDrawableResource(private val drawable: KSVGDrawable) : DrawableResource<Drawable>(drawable) {
    override fun getResourceClass(): Class<Drawable> = Drawable::class.java
    override fun getSize(): Int = 1 // Not easily measurable
    override fun recycle() {
        drawable.trimMemory()
    }
}