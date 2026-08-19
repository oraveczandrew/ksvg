# SVG Reference — Audit-First Implementation Reference

**Purpose:** AI-facing reference for implementing and reviewing SVG behavior in a renderer/parser such as KSVG.

**Scope:** SVG 2 + SVG 1.1 compatibility + the CSS/graphics specifications that SVG delegates behavior to.

**Core principle:** this document is a *map and audit framework*, not a replacement for the specifications. A feature is not considered covered merely because its name appears here.

**Snapshot:** 2026-08-23.

---

# 1. Why this document exists

SVG is not a single self-contained specification.

SVG 2 defines the SVG language, but important behavior is supplied by other standards, especially CSS. SVG itself explicitly describes compatibility/dependencies with other standards. The current published SVG 2 document is still the 4 October 2018 Candidate Recommendation; SVG 1.1 Second Edition is the 16 August 2011 Recommendation. Therefore a renderer targeting real-world SVG cannot use “SVG 2” as the only source of truth.

This reference intentionally separates:

1. **SVG language features**
2. **delegated CSS/graphics behavior**
3. **SVG 1.1 compatibility behavior**
4. **implementation policy**
5. **tests**

The goal is to prevent a coding AI from silently filling gaps from memory.

---

# 2. Source-of-truth hierarchy

Use this order when resolving a question.

## 2.1 Normative SVG

### SVG 2

https://www.w3.org/TR/SVG2/

Status: Candidate Recommendation, 4 October 2018.

Editor draft:

https://svgwg.org/svg2-draft/

Repository:

https://github.com/w3c/svgwg/

SVG 2 defines the SVG language and processing model. Do not describe the 2018 CR as the final SVG 2 standard.

### SVG 1.1 Second Edition

https://www.w3.org/TR/SVG11/

Status: W3C Recommendation, 16 August 2011.

Use this as an important compatibility source for established SVG 1.1 documents and for behavior retained from SVG 1.1.

SVG 1.1 also has errata. Check those when behavior appears contradictory or ambiguous.

---

# 3. Delegated specifications

The following specifications must be treated as part of the SVG implementation surface whenever the corresponding feature is supported.

## 3.1 CSS Cascade

CSS Cascading and Inheritance:

https://www.w3.org/TR/css-cascade-6/

Editor draft:

https://drafts.csswg.org/css-cascade-6/

Use the Recommendation-level/CR snapshot appropriate to the implementation target rather than blindly depending on the newest editor draft.

Audit:

- cascade origins
- importance
- specificity
- inheritance
- initial values
- computed values
- used values
- `initial`
- `inherit`
- `unset`
- `revert`
- `revert-layer`
- layers where supported
- animation/transition origins
- presentation attributes
- inline style
- author stylesheets
- selector matching
- invalid declarations
- invalid at computed-value time
- custom properties and `var()`

### Important

`revert` is **CSS cascade behavior**, not an SVG-specific keyword.

A renderer that only maintains an ad-hoc “SVG property cascade” is likely to get these semantics wrong.

---

## 3.2 CSS Values and Units

https://www.w3.org/TR/css-values-4/

Audit:

- `<number>`
- `<integer>`
- `<length>`
- `<percentage>`
- `<angle>`
- dimensions
- unitless zero
- relative units
- absolute units
- CSS-wide keywords
- parsing
- computed/used value stages
- serialization

SVG also defines SVG-specific grammars. Do not replace SVG value definitions with generic CSS parsing rules unless the SVG specification actually delegates that grammar.

---

## 3.3 CSS Color

https://www.w3.org/TR/css-color-4/

Audit:

- named colors
- hexadecimal notation
- `rgb()`
- `rgba()`
- `hsl()`
- `hsla()`
- alpha
- `currentColor`
- color interpolation
- color spaces
- gamut handling

Implementation policy must explicitly state the supported color model. A renderer can intentionally support a subset; it must not silently claim full CSS Color support.

---

## 3.4 CSS Transforms

Level 1:

https://www.w3.org/TR/css-transforms-1/

Level 2:

https://www.w3.org/TR/css-transforms-2/

Audit:

- transform lists
- matrix
- translate
- scale
- rotate
- skew
- transform origin
- transform reference boxes
- SVG transform behavior
- nested transforms
- transform order
- coordinate system changes

Do not assume the CSS `transform` property is identical to the SVG `transform` attribute without checking the applicable SVG rules.

---

## 3.5 CSS Masking

https://www.w3.org/TR/css-masking-1/

This is a critical dependency for SVG:

- `clip-path`
- `<clipPath>`
- `clip-rule`
- `clipPathUnits`
- basic-shape clipping
- `mask`
- `<mask>`
- `mask-type`
- `maskUnits`
- `maskContentUnits`
- mask painting
- alpha vs luminance masks
- clipping/masking interaction

Do not model a mask as merely a binary clip. Masks can produce partial opacity.

---

## 3.6 Filter Effects

https://www.w3.org/TR/filter-effects-1/

Audit:

- `filter`
- `<filter>`
- `filterUnits`
- `primitiveUnits`
- filter region
- primitive subregion
- filter input/output graph
- filter color space
- filter references

Primitive inventory:

- `feBlend`
- `feColorMatrix`
- `feComponentTransfer`
- `feComposite`
- `feConvolveMatrix`
- `feDiffuseLighting`
- `feDisplacementMap`
- `feDropShadow`
- `feFlood`
- `feGaussianBlur`
- `feImage`
- `feMerge`
- `feMergeNode`
- `feMorphology`
- `feOffset`
- `feSpecularLighting`
- `feTile`
- `feTurbulence`

Component transfer:

- `feFuncA`
- `feFuncB`
- `feFuncG`
- `feFuncR`

Lighting:

- `feDistantLight`
- `fePointLight`
- `feSpotLight`

Filter behavior also has to be reconciled with compositing and clipping.

---

## 3.7 Compositing and Blending

https://www.w3.org/TR/compositing-1/

Audit:

- source-over
- Porter-Duff operators where exposed
- blend modes
- `mix-blend-mode`
- isolation
- group compositing
- opacity
- premultiplied-alpha behavior
- stacking/compositing contexts

This matters because `opacity`, masks, filters and blending are not interchangeable operations.

---

## 3.8 CSS Fonts / Text / Writing Modes

CSS Fonts:

https://www.w3.org/TR/css-fonts-4/

CSS Text:

https://www.w3.org/TR/css-text-4/

CSS Writing Modes:

https://www.w3.org/TR/css-writing-modes-4/

Audit when implementing SVG text:

- font selection
- fallback
- font weight/style/stretch
- white-space handling
- line/layout behavior
- bidi
- writing modes
- text direction
- glyph shaping where the platform exposes it
- baseline behavior

SVG has additional text-specific rules, so CSS text behavior must not be substituted blindly.

---

# 4. SVG feature inventory

The inventory is deliberately split into implementation domains. Each domain is a checklist, not a declaration that all items have identical semantics.

---

## 4.1 XML / document model

Audit:

- XML syntax
- namespace declarations
- SVG namespace
- XML attributes
- `xml:base`
- `xml:lang`
- `xml:space`
- IDs
- document fragments
- comments/processing instructions as applicable
- embedded SVG in other XML
- SVG embedded in HTML
- HTML parsing differences where relevant

Implementation questions:

- What parser is used?
- Does XML entity processing occur?
- How is `xml:space` represented?
- How are duplicate IDs handled?
- How are base URLs resolved?

---

## 4.2 Root / viewport / document structure

Elements:

- `<svg>`
- nested `<svg>`
- `<g>`
- `<defs>`
- `<symbol>`
- `<use>`
- `<switch>`

Audit:

- `x`
- `y`
- `width`
- `height`
- `viewBox`
- `preserveAspectRatio`
- viewport creation
- nested viewport creation
- user coordinate system
- viewport coordinate system
- default viewport
- percentage resolution
- overflow
- transforms on viewport-establishing elements

---

## 4.3 Basic shapes

Elements:

- `<rect>`
- `<circle>`
- `<ellipse>`
- `<line>`
- `<polyline>`
- `<polygon>`

Audit each shape for:

- geometry attributes
- default values
- zero dimensions
- negative dimensions
- percentage dimensions
- fill geometry
- stroke geometry
- path equivalence where defined
- bounding box
- transforms
- clipping
- markers where applicable
- hit testing

---

## 4.4 Paths

Element:

- `<path>`

Attributes:

- `d`
- `pathLength`

Commands:

- `M/m`
- `L/l`
- `H/h`
- `V/v`
- `C/c`
- `S/s`
- `Q/q`
- `T/t`
- `A/a`
- `Z/z`

Parser audit:

- command repetition
- implicit commands
- relative coordinates
- separator rules
- sign as separator
- exponent notation
- malformed input
- unexpected EOF
- arc flags
- closepath
- current point
- subpaths

Geometry audit:

- line/curve evaluation
- arc conversion
- length
- tangents
- markers
- `pathLength`
- bounding boxes
- transformed geometry

A parser bug can become a rendering bug. Keep syntax parsing separate from geometry normalization.

---

## 4.5 Fill and stroke

Fill:

- `fill`
- `fill-opacity`
- `fill-rule`

Stroke:

- `stroke`
- `stroke-opacity`
- `stroke-width`
- `stroke-linecap`
- `stroke-linejoin`
- `stroke-miterlimit`
- `stroke-dasharray`
- `stroke-dashoffset`

Additional:

- `paint-order`
- `vector-effect`
- `currentColor`
- `color-interpolation`
- `color-interpolation-filters`

Audit:

- `none`
- solid colors
- paint servers
- fallback paint
- inheritance
- initial values
- geometry dependence
- percentages
- stroke scaling under transforms
- non-scaling stroke behavior
- miter clipping/limits
- dash placement
- cap/join geometry

---

## 4.6 Markers

Elements:

- `<marker>`

Attributes/properties:

- `marker-start`
- `marker-mid`
- `marker-end`
- `markerUnits`
- `refX`
- `refY`
- `orient`
- `viewBox`
- `preserveAspectRatio`

Audit:

- marker coordinate system
- marker units
- marker orientation
- path direction
- closed subpaths
- corner handling
- marker transforms
- marker overflow
- marker paint/opacity
- interaction with stroke width and vector effects

---

## 4.7 Gradients

Elements:

- `<linearGradient>`
- `<radialGradient>`
- `<stop>`

Linear gradient:

- `x1`
- `y1`
- `x2`
- `y2`

Radial gradient:

- `cx`
- `cy`
- `r`
- `fx`
- `fy`
- `fr`

Common:

- `gradientUnits`
- `gradientTransform`
- `spreadMethod`
- `href`
- `stop-color`
- `stop-opacity`
- `offset`

Audit:

- `userSpaceOnUse`
- `objectBoundingBox`
- transform order
- inherited attributes through `href`
- reference chains
- cyclic references
- degenerate geometry
- spread modes
- stop ordering
- missing/invalid stops
- opacity interaction

---

## 4.8 Patterns

Element:

- `<pattern>`

Audit:

- `x`
- `y`
- `width`
- `height`
- `patternUnits`
- `patternContentUnits`
- `patternTransform`
- `viewBox`
- `preserveAspectRatio`
- `href`

Important distinctions:

- tile coordinate system
- content coordinate system
- user space
- object bounding box
- pattern transform
- nested references
- cyclic references
- nested pattern content

---

## 4.9 Images and external graphics

Element:

- `<image>`

Audit:

- `href`
- data URLs
- external URLs
- intrinsic size
- `width`
- `height`
- `x`
- `y`
- `preserveAspectRatio`
- image decoding
- image color/alpha
- clipping
- filtering
- opacity
- transform

Implementation policy should explicitly define supported image formats and external resource restrictions.

---

## 4.10 Text

Elements:

- `<text>`
- `<tspan>`
- `<textPath>`

Audit:

- `x`
- `y`
- `dx`
- `dy`
- `rotate`
- `textLength`
- `lengthAdjust`
- `text-anchor`
- baseline properties
- font properties
- letter spacing
- word spacing
- direction
- bidi
- writing mode
- text path
- whitespace
- font fallback
- shaping
- glyph positioning
- text measurement
- bounding boxes
- clipping
- transforms

Text is one of the highest-risk areas for partial implementations because rendering can depend on the platform text stack.

---

## 4.11 Paint servers and references

Reference forms:

- `url(#id)`
- `href`
- external document references
- CSS URLs

Audit:

- fragment lookup
- base URL
- local vs external resource
- missing reference
- invalid reference
- cyclic reference
- inheritance/reference chaining
- reference element type
- reference coordinate system

This must be a shared subsystem. Do not implement separate “gradient lookup”, “clip lookup”, “mask lookup”, etc. with subtly different rules unless the relevant specs require differences.

---

# 5. Coordinate-system matrix

SVG implementations should explicitly model coordinate systems.

Common systems:

- viewport space
- user space
- local element space
- transformed user space
- object bounding box
- normalized object bounding box
- marker space
- gradient space
- pattern tile space
- pattern content space
- clipPath space
- mask coordinate space
- mask content space
- filter coordinate space
- filter primitive coordinate space
- text coordinate space

For every feature ask:

1. What is the base coordinate system?
2. Can it switch between user space and object bounding box?
3. Is a transform applied before or after the coordinate conversion?
4. Does the feature establish a new viewport?
5. Does its own `viewBox` create another transform?
6. Are percentages resolved before or after transforms?

---

# 6. ViewBox and preserveAspectRatio

Audit these independently from generic transforms.

`viewBox` introduces a mapping between viewport and user coordinate systems.

`preserveAspectRatio` controls how the viewBox mapping is fitted into the viewport.

Audit:

- missing `viewBox`
- zero/negative viewBox dimensions
- `meet`
- `slice`
- `none`
- x alignment
- y alignment
- nested SVG
- symbol
- marker
- pattern
- image
- other viewBox-bearing elements
- transform interaction

A renderer should have regression tests that distinguish:

- viewBox scaling
- element transform
- nested viewport
- preserveAspectRatio

---

# 7. CSS presentation and cascade

The following sources of style must be distinguishable:

- default/user-agent behavior
- presentation attributes
- author stylesheet
- inline `style`
- inherited values
- animations if supported
- transitions if supported

Audit:

- selector matching
- specificity
- cascade order
- inheritance
- initial values
- CSS-wide keywords
- invalid values
- custom properties
- shorthand expansion
- property aliases where applicable
- animation origin
- `revert`
- `revert-layer`

A presentation attribute is not simply equivalent to an inline `style` declaration in every cascade context.

---

# 8. CSS property audit set

At minimum, audit these SVG-relevant groups.

## Painting

- `fill`
- `fill-opacity`
- `fill-rule`
- `stroke`
- `stroke-width`
- `stroke-opacity`
- `stroke-linecap`
- `stroke-linejoin`
- `stroke-miterlimit`
- `stroke-dasharray`
- `stroke-dashoffset`
- `paint-order`
- `vector-effect`

## Rendering/compositing

- `display`
- `visibility`
- `opacity`
- `overflow`
- `clip-path`
- `clip-rule`
- `mask`
- `mask-type`
- `filter`
- `isolation`
- `mix-blend-mode`
- `pointer-events`

## Color/rendering quality

- `color`
- `color-interpolation`
- `color-interpolation-filters`
- `shape-rendering`
- `text-rendering`
- `image-rendering`

## Geometry-related CSS

- `x`
- `y`
- `cx`
- `cy`
- `r`
- `rx`
- `ry`
- `width`
- `height`
- `d`
- `pathLength`

## Typography

- `font-family`
- `font-size`
- `font-size-adjust`
- `font-stretch`
- `font-style`
- `font-variant`
- `font-weight`
- `font-feature-settings`
- `font-variation-settings`
- `letter-spacing`
- `word-spacing`
- `text-anchor`
- `dominant-baseline`
- `alignment-baseline`
- `baseline-shift`
- `direction`
- `unicode-bidi`
- `writing-mode`
- `text-decoration`

---

# 9. Clipping

Core concepts:

- `clip-path`
- `<clipPath>`
- `clipPathUnits`
- `clip-rule`
- basic shapes
- referenced paths/shapes
- nested clip paths

Audit:

- clip coordinate system
- transforms
- nested clips
- clipping groups
- clip + filter
- clip + mask
- clip + opacity
- clip + pointer events
- empty clips
- invalid references

Do not confuse “not painted” with “not hit-testable”; pointer-events rules need their own audit.

---

# 10. Masking

Core concepts:

- `<mask>`
- `mask`
- `mask-type`
- `maskUnits`
- `maskContentUnits`
- mask x/y/width/height
- alpha masking
- luminance masking
- mask compositing

Audit:

- mask coordinate system
- mask content coordinate system
- transforms
- nested masks
- opacity
- filters inside masks
- clip paths inside masks
- empty masks
- reference failures

---

# 11. Filter pipeline

A filter reference is not just “run Gaussian blur”.

Audit separately:

## Filter region

- `x`
- `y`
- `width`
- `height`
- `filterUnits`

## Primitive region

- `x`
- `y`
- `width`
- `height`
- `primitiveUnits`

## Inputs

- `SourceGraphic`
- `SourceAlpha`
- `BackgroundImage`
- `BackgroundAlpha`
- `FillPaint`
- `StrokePaint`
- result chaining

## Color/intermediate representation

- filter color space
- alpha handling
- premultiplication

## Primitive semantics

Each primitive needs its own normative behavior and test suite.

---

# 12. Compositing / blending order

Maintain an explicit conceptual pipeline for:

- painting
- group opacity
- filters
- clipping
- masks
- blending
- parent compositing

Do not flatten these into a single generic “alpha” step.

The same SVG can render differently when operations are reordered.

Every non-trivial renderer should have interaction tests such as:

- filter + clip
- filter + mask
- filter + opacity
- mask + opacity
- blend + opacity
- nested group opacity
- clip + blend
- mask + blend

---

# 13. Visibility, display and hit testing

Distinguish:

- `display: none`
- `visibility: hidden`
- zero opacity
- zero-size geometry
- clipping
- masking to zero
- filtered-out pixels
- `pointer-events`

Audit hit testing independently from visual rendering.

---

# 14. Animation / dynamic behavior

SVG declarative animation has historically involved SMIL/SVG animation concepts.

Audit:

- `<animate>`
- `<set>`
- `<animateTransform>`
- `<animateMotion>`
- timing
- begin/end
- duration
- repeat
- fill
- additive animation
- accumulation
- interpolation
- animated presentation attributes
- animated geometry
- CSS animation interaction

Implementation policy must explicitly state whether animation is:

- fully supported
- partially supported
- parsed but not rendered
- intentionally unsupported

Never imply support merely because the parser accepts animation elements.

---

# 15. Interaction / events

Audit:

- pointer events
- hit testing
- event target selection
- event propagation
- pointer-events property
- links
- scripting/event attributes if supported

A library designed only for static SVG may deliberately omit scripting and DOM events. That is valid; record it explicitly.

---

# 16. Linking

Audit:

- `<a>`
- `href`
- fragment identifiers
- local fragment references
- external document references
- `xml:base`
- URL resolution
- security/resource policies
- broken references
- cycles

---

# 17. Conditional processing

Audit SVG conditional constructs where targeted:

- `<switch>`
- required features
- required extensions
- system language
- conditional rendering

Document unsupported conditional-processing behavior explicitly.

---

# 18. Accessibility and metadata

Elements/concepts:

- `<title>`
- `<desc>`
- `<metadata>`
- ARIA where embedded/appropriate
- language metadata
- directionality

A renderer may not expose accessibility APIs, but parsing and preserving metadata can still matter.

---

# 19. Legacy / compatibility surface

Create a deliberate policy for:

- SVG 1.1-only/legacy features
- deprecated SVG behavior
- attributes moved into CSS
- legacy XML attributes
- browser-compatibility quirks
- AndroidSVG-compatible behavior
- malformed real-world SVG

Do not mix “standard semantics” and “compatibility hacks” in the same implementation branch without a documented reason.

---

# 20. Implementation status model

Every implementation item should have one of these states:

- `UNASSESSED`
- `SPEC_READ`
- `PARSER_ONLY`
- `STYLE_ONLY`
- `PARTIAL`
- `RENDERED`
- `TESTED`
- `INTERACTION_TESTED`
- `KNOWN_DEVIATION`
- `UNSUPPORTED`
- `LEGACY_COMPAT`

Never use a single boolean called `supported`.

---

# 21. Required feature record

For each feature, keep a record of this form:

```text
Feature:
Spec:
Spec section:
SVG version:
CSS/graphics dependencies:

Syntax:
Applies to:
Initial value:
Inherited:
Animatable:

Value grammar:

Coordinate system:
Percentage basis:
Reference resolution:

Rendering semantics:
Processing order:
Interaction with transform:
Interaction with clip:
Interaction with mask:
Interaction with filter:
Interaction with opacity:
Interaction with compositing:

Invalid input behavior:
Missing reference behavior:
Cyclic reference behavior:

SVG 1.1 compatibility:
SVG 2 behavior:
Known browser behavior:
KSVG policy:

Tests:
```

This is intentionally verbose. It prevents AI-generated implementations from filling in unspecified details with assumptions.

---

# 22. Completeness matrix

The project should maintain a machine-readable inventory with columns equivalent to:

| Domain | Feature | Element/property | Defining spec | Dependency specs | Initial | Inherited | Coordinate system | Parser | Style | Geometry | Render | Interaction tests | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

The matrix is the actual completeness mechanism.

This Markdown document is the human/AI reference; the matrix should become the project’s auditable source of implementation status.

---

# 23. Small-feature audit list

These are deliberately listed because they are easy to miss in AI-generated SVG implementations.

## CSS / cascade

- `revert`
- `revert-layer`
- `unset`
- `inherit`
- `initial`
- presentation attributes
- custom properties
- `var()`
- invalid-at-computed-value-time
- specificity
- stylesheet order

## Coordinate systems

- `viewBox`
- `preserveAspectRatio`
- nested `<svg>`
- `objectBoundingBox`
- `userSpaceOnUse`
- `gradientTransform`
- `patternTransform`
- `clipPathUnits`
- `maskUnits`
- `maskContentUnits`
- `filterUnits`
- `primitiveUnits`
- marker coordinate system

## References

- `href`
- `url(#id)`
- external references
- missing references
- invalid references
- cyclic references
- inherited referenced attributes

## Paint

- `paint-order`
- `vector-effect`
- `currentColor`
- `fill-rule`
- `clip-rule`
- dash behavior
- miter limits
- markers
- marker orientation

## Rendering

- `overflow`
- `display`
- `visibility`
- opacity
- filter region
- filter primitive region
- compositing
- blending
- isolation

## Text

- whitespace
- `xml:space`
- text length
- baseline
- bidi
- writing mode
- font fallback
- textPath
- glyph positioning

## Parsing

- path exponent notation
- omitted separators
- implicit command repetition
- relative coordinates
- arc flags
- malformed path recovery
- CSS tokenization
- URL tokenization
- percentage parsing
- unitless values

---

# 24. AI-specific implementation rules

This section is intentionally written for coding agents.

## Rule 1

Do not invent SVG semantics from memory when a normative source is available.

## Rule 2

When implementing a property, first identify whether its semantics come from:

- SVG
- CSS
- another graphics specification
- SVG 1.1 compatibility behavior

## Rule 3

When changing the renderer, inspect interaction with existing features.

Example:

```text
Adding clip-path
→ inspect transforms
→ inspect nested groups
→ inspect opacity
→ inspect masks
→ inspect filters
→ inspect hit testing
```

## Rule 4

Do not simplify two concepts merely because simple examples look equivalent.

Examples:

- `display:none` != `visibility:hidden`
- clipping != masking
- opacity != alpha paint
- SVG `transform` attribute != blindly assumed CSS transform behavior
- presentation attribute != blindly assumed inline CSS
- `userSpaceOnUse` != `objectBoundingBox`
- parser acceptance != rendering support

## Rule 5

Every newly discovered missing feature gets:

1. specification reference
2. inventory entry
3. implementation status
4. regression test
5. interaction tests if relevant

---

# 25. Suggested repository structure

```text
docs/
  svg/
    SVG_REFERENCE.md
    SVG_SOURCES.md
    SVG_FEATURE_MATRIX.md
    SVG_COMPATIBILITY.md

tests/
  svg/
    css/
    geometry/
    paint/
    gradients/
    patterns/
    markers/
    clipping/
    masking/
    filters/
    compositing/
    text/
    references/
    viewports/
```

The reference should remain stable even while implementation code changes.

---

# 26. Source links

## SVG

- SVG 2: https://www.w3.org/TR/SVG2/
- SVG 2 single page: https://www.w3.org/TR/SVG/single-page.html
- SVG 2 editor draft: https://svgwg.org/svg2-draft/
- SVG WG repository: https://github.com/w3c/svgwg/
- SVG 1.1 Second Edition: https://www.w3.org/TR/SVG11/
- SVG specification index: https://www.w3.org/TR/SVG/all/

## CSS / graphics

- CSS Cascade: https://www.w3.org/TR/css-cascade-6/
- CSS Values & Units: https://www.w3.org/TR/css-values-4/
- CSS Color: https://www.w3.org/TR/css-color-4/
- CSS Transforms 1: https://www.w3.org/TR/css-transforms-1/
- CSS Transforms 2: https://www.w3.org/TR/css-transforms-2/
- CSS Masking: https://www.w3.org/TR/css-masking-1/
- Filter Effects: https://www.w3.org/TR/filter-effects-1/
- Compositing and Blending: https://www.w3.org/TR/compositing-1/
- CSS Fonts: https://www.w3.org/TR/css-fonts-4/
- CSS Text: https://www.w3.org/TR/css-text-4/
- CSS Writing Modes: https://www.w3.org/TR/css-writing-modes-4/

---

# 27. What “complete” means here

This document does **not** claim:

> “Everything SVG supports is written above.”

Instead it defines the process by which that claim can eventually be audited.

A trustworthy implementation reference needs two layers:

### Layer A — normative coverage

A complete inventory of relevant specification definitions, including dependencies.

### Layer B — implementation coverage

For every inventory item:

```text
specification
    ↓
feature
    ↓
parser/style/geometry/rendering behavior
    ↓
interaction behavior
    ↓
regression tests
```

Without Layer A, an AI can omit a feature because it forgot it existed.

Without Layer B, an implementation can claim support while only parsing the syntax.

---

# 28. Current conclusion

Use this document as the **architecture of the reference**, not as the final word on SVG.

The next serious step is to generate `SVG_FEATURE_MATRIX.md` from the specifications themselves and use that matrix to audit this document. That is the point where “I think I covered everything” changes into “we can point to the inventory and see what is still missing.”

