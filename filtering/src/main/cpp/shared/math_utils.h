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

#pragma once

#include <cmath>
#include <algorithm>
#include <cstdint>

namespace ksvg {

inline int clamp255(const float v) {
    const int i = static_cast<int>(std::floor(v + 0.5f));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

inline int clamp255(const double v) {
    const int i = static_cast<int>(std::floor(v + 0.5));
    return i < 0 ? 0 : (i > 255 ? 255 : i);
}

} // namespace ksvg
