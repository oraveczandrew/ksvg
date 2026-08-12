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

package hu.oandras.ksvg.utils

import hu.oandras.ksvg.dom.COLOR_BLACK

// These static inner classes are only loaded/initialized when first used and are thread safe
@Suppress("SpellCheckingInspection")
internal object ColorKeywords {

    fun get(colorName: String): Int = when (colorName) {
        "aliceblue" -> -0xf0701
        "antiquewhite" -> -0x51429
        "aqua" -> -0xff0001
        "aquamarine" -> -0x80002c
        "azure" -> -0xf0001
        "beige" -> -0xa0a24
        "bisque" -> -0x1b3c
        "black" -> COLOR_BLACK
        "blanchedalmond" -> -0x1433
        "blue" -> -0xffff01
        "blueviolet" -> -0x75d41e
        "brown" -> -0x5ad5d6
        "burlywood" -> -0x214779
        "cadetblue" -> -0xa06160
        "chartreuse" -> -0x800100
        "chocolate" -> -0x2d96e2
        "coral" -> -0x80b0
        "cornflowerblue" -> -0x9b6a13
        "cornsilk" -> -0x724
        "crimson" -> -0x23ebc4
        "cyan" -> -0xff0001
        "darkblue" -> -0xffff75
        "darkcyan" -> -0xff7475
        "darkgoldenrod" -> -0x4779f5
        "darkgray" -> -0x565657
        "darkgreen" -> -0xff9c00
        "darkgrey" -> -0x565657
        "darkkhaki" -> -0x424895
        "darkmagenta" -> -0x74ff75
        "darkolivegreen" -> -0xaa94d1
        "darkorange" -> -0x7400
        "darkorchid" -> -0x66cd34
        "darkred" -> -0x750000
        "darksalmon" -> -0x166986
        "darkseagreen" -> -0x704371
        "darkslateblue" -> -0xb7c275
        "darkslategray" -> -0xd0b0b1
        "darkslategrey" -> -0xd0b0b1
        "darkturquoise" -> -0xff312f
        "darkviolet" -> -0x6bff2d
        "deeppink" -> -0xeb6d
        "deepskyblue" -> -0xff4001
        "dimgray" -> -0x969697
        "dimgrey" -> -0x969697
        "dodgerblue" -> -0xe16f01
        "firebrick" -> -0x4dddde
        "floralwhite" -> -0x510
        "forestgreen" -> -0xdd74de
        "fuchsia" -> -0xff01
        "gainsboro" -> -0x232324
        "ghostwhite" -> -0x70701
        "gold" -> -0x2900
        "goldenrod" -> -0x255ae0
        "gray" -> -0x7f7f80
        "green" -> -0xff8000
        "greenyellow" -> -0x5200d1
        "grey" -> -0x7f7f80
        "honeydew" -> -0xf0010
        "hotpink" -> -0x964c
        "indianred" -> -0x32a3a4
        "indigo" -> -0xb4ff7e
        "ivory" -> -0x10
        "khaki" -> -0xf1974
        "lavender" -> -0x191906
        "lavenderblush" -> -0xf0b
        "lawngreen" -> -0x830400
        "lemonchiffon" -> -0x533
        "lightblue" -> -0x52271a
        "lightcoral" -> -0xf7f80
        "lightcyan" -> -0x1f0001
        "lightgoldenrodyellow" -> -0x5052e
        "lightgray" -> -0x2c2c2d
        "lightgreen" -> -0x6f1170
        "lightgrey" -> -0x2c2c2d
        "lightpink" -> -0x493f
        "lightsalmon" -> -0x5f86
        "lightseagreen" -> -0xdf4d56
        "lightskyblue" -> -0x783106
        "lightslategray" -> -0x887767
        "lightslategrey" -> -0x887767
        "lightsteelblue" -> -0x4f3b22
        "lightyellow" -> -0x20
        "lime" -> -0xff0100
        "limegreen" -> -0xcd32ce
        "linen" -> -0x50f1a
        "magenta" -> -0xff01
        "maroon" -> -0x800000
        "mediumaquamarine" -> -0x993256
        "mediumblue" -> -0xffff33
        "mediumorchid" -> -0x45aa2d
        "mediumpurple" -> -0x6c8f25
        "mediumseagreen" -> -0xc34c8f
        "mediumslateblue" -> -0x849712
        "mediumspringgreen" -> -0xff0566
        "mediumturquoise" -> -0xb72e34
        "mediumvioletred" -> -0x38ea7b
        "midnightblue" -> -0xe6e690
        "mintcream" -> -0xa0006
        "mistyrose" -> -0x1b1f
        "moccasin" -> -0x1b4b
        "navajowhite" -> -0x2153
        "navy" -> -0xffff80
        "oldlace" -> -0x20a1a
        "olive" -> -0x7f8000
        "olivedrab" -> -0x9471dd
        "orange" -> -0x5b00
        "orangered" -> -0xbb00
        "orchid" -> -0x258f2a
        "palegoldenrod" -> -0x111756
        "palegreen" -> -0x670468
        "paleturquoise" -> -0x501112
        "palevioletred" -> -0x248f6d
        "papayawhip" -> -0x102b
        "peachpuff" -> -0x2547
        "peru" -> -0x327ac1
        "pink" -> -0x3f35
        "plum" -> -0x225f23
        "powderblue" -> -0x4f1f1a
        "purple" -> -0x7fff80
        "rebeccapurple" -> -0x99cc67
        "red" -> -0x10000
        "rosybrown" -> -0x437071
        "royalblue" -> -0xbe961f
        "saddlebrown" -> -0x74baed
        "salmon" -> -0x57f8e
        "sandybrown" -> -0xb5ba0
        "seagreen" -> -0xd174a9
        "seashell" -> -0xa12
        "sienna" -> -0x5fadd3
        "silver" -> -0x3f3f40
        "skyblue" -> -0x783115
        "slateblue" -> -0x95a533
        "slategray" -> -0x8f7f70
        "slategrey" -> -0x8f7f70
        "snow" -> -0x506
        "springgreen" -> -0xff0081
        "steelblue" -> -0xb97d4c
        "tan" -> -0x2d4b74
        "teal" -> -0xff7f80
        "thistle" -> -0x274028
        "tomato" -> -0x9cb9
        "turquoise" -> -0xbf1f30
        "violet" -> -0x117d12
        "wheat" -> -0xa214d
        "white" -> -0x1
        "whitesmoke" -> -0xa0a0b
        "yellow" -> -0x100
        "yellowgreen" -> -0x6532ce
        "transparent" -> 0x00000000
        else -> COLOR_BLACK
    }
}
