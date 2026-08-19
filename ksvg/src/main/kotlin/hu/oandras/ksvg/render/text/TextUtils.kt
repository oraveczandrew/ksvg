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

package hu.oandras.ksvg.render.text

import hu.oandras.ksvg.dom.text.TextContainer
import hu.oandras.ksvg.dom.text.TextSequence
import hu.oandras.ksvg.utils.textXMLSpaceTransform

internal fun extractRawText(
    parent: TextContainer,
    str: StringBuilder,
    spacePreserve: Boolean
) {
    val children = parent.getChildren()
    val lastIndex = children.lastIndex

    for (i in 0 .. lastIndex) {
        when (val child = children[i]) {
            is TextContainer -> {
                extractRawText(
                    parent = child,
                    str = str,
                    spacePreserve = spacePreserve,
                )
            }

            is TextSequence -> {
                str.append(
                    textXMLSpaceTransform(
                        text = child.text,
                        isFirstChild = i == 0,
                        isLastChild = i == lastIndex,
                        spacePreserve = spacePreserve
                    )
                )
            }
        }
    }
}
