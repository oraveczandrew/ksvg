# SVG Filter Primitive Usage in Chrome

## Overview

This document summarizes the observed usage of SVG filter primitives in Chrome based on the Chrome Status UseCounter data retrieved from the `featurepopularity` API.

The data point shown below is for **2026-09-16**. For stability, the table also includes the **30-day median**, **30-day average**, and the **historical maximum** returned by the same dataset.

### Data source

Chrome Status timeline API:

```text
https://chromestatus.com/data/timeline/featurepopularity?bucket_id=<BUCKET_ID>
```

The relevant Chromium SVG filter primitive UseCounter bucket IDs are 5747–5763.

## Usage table

| Rank | SVG filter primitive | Bucket ID | Latest % | 30-day median % | 30-day average % | Historical max % |
|---:|---|---:|---:|---:|---:|---:|
| 1 | `feGaussianBlur` | 5756 | 0.04204357 | 0.04200645 | 0.0418812673 | 0.04618755 |
| 2 | `feOffset` | 5760 | 0.02208327 | 0.022584775 | 0.0228310760 | 0.03724700 |
| 3 | `feFlood` | 5755 | 0.01900134 | 0.018628855 | 0.0185630013 | 0.02567000 |
| 4 | `feColorMatrix` | 5748 | 0.01869757 | 0.018652555 | 0.0186477100 | 0.04078300 |
| 5 | `feBlend` | 5747 | 0.01785438 | 0.017718340 | 0.0176095590 | 0.02517900 |
| 6 | `feComposite` | 5750 | 0.01404327 | 0.013714840 | 0.0136730203 | 0.03193399 |
| 7 | `feComponentTransfer` | 5749 | 0.00701578 | 0.007198935 | 0.0073433303 | 0.01005800 |
| 8 | `feMerge` | 5758 | 0.00648625 | 0.007462845 | 0.0075634247 | 0.00996900 |
| 9 | `feMorphology` | 5759 | 0.00251078 | 0.002182505 | 0.0022846030 | 0.00336200 |
| 10 | `feDropShadow` | 5754 | 0.00137456 | 0.001343460 | 0.0013251147 | 0.00262300 |
| 11 | `feTurbulence` | 5763 | 0.00091455 | 0.000919580 | 0.0009208163 | 0.02042280 |
| 12 | `feDisplacementMap` | 5753 | 0.00014490 | 0.000149640 | 0.0002070787 | 0.00664700 |
| 13 | `feImage` | 5757 | 0.00004928 | 0.000043195 | 0.0000427710 | 0.00005554 |
| 14 | `feSpecularLighting` | 5761 | 0.00002102 | 0.000019405 | 0.0000192740 | 0.00003800 |
| 15 | `feConvolveMatrix` | 5751 | 0.00001177 | 0.000013380 | 0.0000137247 | 0.00002985 |
| 16 | `feDiffuseLighting` | 5752 | 0.00000169 | 0.000001415 | 0.0000014540 | 0.00000400 |
| 17 | `feTile` | 5762 | 0.00000059 | 0.000000460 | 0.0000004650 | 0.00000335 |

**Latest measurement date:** 2026-09-16

## Usage per one million page loads

The latest percentage can be converted to an intuitive approximate count per one million page loads:

| SVG filter primitive | Approx. uses per 1,000,000 page loads |
|---|---:|
| `feGaussianBlur` | 420.44 |
| `feOffset` | 220.83 |
| `feFlood` | 190.01 |
| `feColorMatrix` | 186.98 |
| `feBlend` | 178.54 |
| `feComposite` | 140.43 |
| `feComponentTransfer` | 70.16 |
| `feMerge` | 64.86 |
| `feMorphology` | 25.11 |
| `feDropShadow` | 13.75 |
| `feTurbulence` | 9.15 |
| `feDisplacementMap` | 1.45 |
| `feImage` | 0.49 |
| `feSpecularLighting` | 0.21 |
| `feConvolveMatrix` | 0.12 |
| `feDiffuseLighting` | 0.02 |
| `feTile` | 0.00059 |

These figures are simple conversions of the latest percentages and should be read as expected feature occurrences per one million page loads, not as counts of unique pages.

### Chromium UseCounter documentation

The Chromium UseCounter system measures feature usage on page loads and exposes Blink feature usage data through Chrome Status.

```text
https://chromium.googlesource.com/chromium/src/+/HEAD/docs/use_counter_wiki.md
```
