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

package hu.oandras.ksvg.showcase

import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.RequestManager
import hu.oandras.ksvg.glide.KSVGOptions

internal class SvgAdapter(
    private val requestManager: RequestManager
) : ListAdapter<SvgEntry, SvgAdapter.ViewHolder>(SvgEntryDiffCallback) {

    internal class ViewHolder(
        binding: SvgItemBinding,
        private val requestManager: RequestManager
    ) : RecyclerView.ViewHolder(binding.root) {
        private val imageView: ImageView = binding.imageView
        private val textView: TextView = binding.textView

        fun onBind(entry: SvgEntry) {
            textView.text = entry.displayName

            requestManager
                .asDrawable()
                .set(KSVGOptions.PARSE_ANIMATIONS, true)
                .load(entry.uri)
                .into(imageView)
        }

        fun onRecycled() {
            // Stop ticking animated drawables on recycled cells.
            requestManager.clear(imageView)
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = parent.context.svgItemLayout()
        return ViewHolder(binding, requestManager)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.onBind(getItem(position))
    }

    override fun onViewRecycled(holder: ViewHolder) {
        holder.onRecycled()
        super.onViewRecycled(holder)
    }

    private object SvgEntryDiffCallback : DiffUtil.ItemCallback<SvgEntry>() {
        override fun areItemsTheSame(oldItem: SvgEntry, newItem: SvgEntry): Boolean = oldItem.uri == newItem.uri

        override fun areContentsTheSame(oldItem: SvgEntry, newItem: SvgEntry): Boolean = oldItem.uri == newItem.uri && oldItem.displayName == newItem.displayName
    }
}
