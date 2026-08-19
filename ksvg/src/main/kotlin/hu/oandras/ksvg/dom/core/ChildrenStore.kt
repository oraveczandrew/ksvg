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

package hu.oandras.ksvg.dom.core

import hu.oandras.ksvg.KSVGParseException

internal class ChildrenStore : DomParent {
    private var children: ArrayList<SvgObject>? = null
    private var singleChild: List<SvgObject>? = null

    override fun childCount(): Int {
        return children?.size ?: if (singleChild != null) 1 else 0
    }

    override fun getChildren(): List<SvgObject> {
        return children ?: singleChild ?: emptyList()
    }

    override fun addAll(list: List<SvgObject>) {
        if (list.isEmpty()) return

        children?.let {
            it.addAll(list)
            return
        }

        val single = singleChild
        if (single == null) {
            if (list.size == 1) {
                singleChild = listOf(list[0])
            } else {
                children = ArrayList(list)
            }
        } else {
            children = ArrayList<SvgObject>(list.size + 1).apply {
                add(single[0])
                addAll(list)
            }
            singleChild = null
        }
    }

    @Throws(KSVGParseException::class)
    override fun addChild(elem: SvgObject) {
        children?.let {
            it.add(elem)
            return
        }

        val single = singleChild
        if (single == null) {
            singleChild = listOf(elem)
        } else {
            children = ArrayList<SvgObject>(2).apply {
                add(single[0])
                add(elem)
            }
            singleChild = null
        }
    }

    override fun toString(): String {
        val list = children ?: singleChild
        return "ChildrenStore(children=$list)"
    }
}