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

package hu.oandras.ksvg.showcase

/**
 * Curated "highlights" subset per gallery category: the most visually
 * impressive asset of each family, one representative per type. Used when
 * `ViewsTestActivity` is started with the `highlights` intent flag, so a
 * screen recording or demo does not have to scroll through every asset.
 * Order is the display order in the gallery.
 */
internal object GalleryHighlights {

    fun filesFor(category: Category): List<String> = when (category) {
        Category.METEOCONS -> METEOCONS
        Category.VISUAL -> VISUAL
    }

    private val METEOCONS: List<String> = listOf(
        "alert-avalanche-danger.svg",
        "barometer-extreme.svg",
        "clear-day.svg",
        "clear-night.svg",
        "cloud-up.svg",
        "cloudy.svg",
        "compass.svg",
        "drizzle.svg",
        "dust-day.svg",
        "extreme-thunderstorms-extreme-day-sleet.svg",
        "falling-stars.svg",
        "fog-day.svg",
        "hail.svg",
        "haze-day.svg",
        "hurricane.svg",
        "lightning-bolts.svg",
        "moon-full.svg",
        "moonrise.svg",
        "overcast.svg",
        "partly-cloudy-day.svg",
        "pollen-flower.svg",
        "rainbow-clear.svg",
        "raindrops.svg",
        "sleet.svg",
        "smoke.svg",
        "snow.svg",
        "solar-eclipse.svg",
        "starry-night.svg",
        "sunrise.svg",
        "sunset.svg",
        "thermometer-sun.svg",
        "thunderstorms.svg",
        "tornado.svg",
        "umbrella-wind.svg",
        "uv-index-11-plus.svg",
        "wind-beaufort-12.svg",
        "wind-dust.svg",
        "windmill.svg",
    )

    private val VISUAL: List<String> = listOf(
        "animate_motion.svg",
        "animate_path.svg",
        "animation_keyframes.svg",
        "animateTransform_skews.svg",
        "filters.svg",
        "filter_specular.svg",
        "filter_component_transfer_complex.svg",
        "filter_morphology_erode.svg",
        "filter_feImage.svg",
        "turbulence.svg",
        "displacement.svg",
        "blend_mode.svg",
        "gradients.svg",
        "gradient_radial_fr.svg",
        "gradient_spread.svg",
        "pattern_transform.svg",
        "patterns_markers.svg",
        "clipping_masking.svg",
        "mask_units_types.svg",
        "clip_path_units.svg",
        "shadow.svg",
        "vector_effect.svg",
        "text_path.svg",
        "text_variation_settings.svg",
        "use_symbol.svg",
        "nested_svgs.svg",
        "marker_orient.svg",
        "stroke_dasharray.svg",
        "image.svg",
        "transforms.svg",
        "css_style.svg",
    )
}
