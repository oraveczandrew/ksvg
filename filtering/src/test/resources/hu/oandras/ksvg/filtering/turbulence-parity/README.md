# librsvg feTurbulence kernel parity — oracle fixtures

This directory holds the deterministic oracle data for the standalone KSVG-vs-librsvg
`feTurbulence` **kernel** parity regression test:

```text
TurbulenceKernelParityTest
```

The test compares the *isolated* KSVG turbulence kernel (lattice build + `noise2` +
per-octave running sum + channel finalization) against librsvg's actual runtime
behaviour for the exact same SVG, bit-exactly, without going through either renderer's
pipeline.

## Files

| File | Contents |
| --- | --- |
| `turbulence_seed_stitch.kernel.bin` | librsvg kernel-boundary dump for `turbulence_seed_stitch.svg` rendered at 256x256 (stitch, seed 7, octaves 2, baseFrequency 0.07). 198 656 records. |
| `turbulence.kernel.bin` | librsvg kernel-boundary dump for `turbulence.svg` rendered at 256x256 (fractal noise, no stitch, seed 0, octaves 3, baseFrequency 0.05). 262 144 records. |
| `librsvg/turbulence.rs` | The librsvg `feTurbulence` filter source **instrumented** with `capture_dump` (the writer of this format). Reference for the exact record layout. |

The source SVGs live in the shared visual test data: `ksvg/test-data/visual/turbulence_seed_stitch.svg`
and `ksvg/test-data/visual/turbulence.svg`. The captures were produced by rendering those
SVGs at canvas 256x256 (the root `width`/`height` overridden on the command line) with
the instrumented `rsvg-convert`, e.g.:

```bash
cd tmp/librsvg
KSVG_TURB_CAPTURE=$PWD/../../filtering/src/test/resources/hu/oandras/ksvg/filtering/turbulence-parity/turbulence_seed_stitch.kernel.bin \
  target/release/rsvg-convert -w 256 -h 256 \
  ../../ksvg/test-data/visual/turbulence_seed_stitch.svg -o /tmp/tss.png
```

## Dump format

All little-endian. Header (35080 bytes):

```text
magic "KSVGTURB" (8) + version u32 (=1)
canvasWidth u32, canvasHeight u32
bounds x0,y0,x1,y1 i32 x4
seed i32
baseFreqX f64, baseFreqY f64        (RAW parsed, pre-stitch-adjust)
numOctaves i32
noiseType u8 (0=Turbulence, 1=FractalNoise), stitchTiles u8, pad u16
tileWidth f64, tileHeight f64        (== bounds w/h)
affine xx,yx,xy,yy,x0,y0 f64 x6
gradient 4 x 514 x 2 f64            (channel-major, [ch][k][i/j])
lattice_selector 514 x i32
```

Then one record per (pixel, color channel) kernel call:

```text
pointX f64, pointY f64, tileX f64, tileY f64
baseFx f64, baseFy f64              (POST-stitch-adjusted, used in this call)
colorChannel u32, numOctaves u32
numOctaves x {
  vecX f64, vecY f64,              (per-octave lattice coords)
  stW u32, stH u32,                (stitch period; 0 when not stitching)
  wrapX i64, wrapY i64,            (per-octave stitch wrap)
  noise f64,                       (raw noise2 result)
  sum f64,                         (running energy sum, incl. this octave)
}
```

Record order is y outer, x middle, color channel inner:

```text
index = ((y - y0) * width + (x - x0)) * 4 + channel
```

The instrumentation is output-neutral: `capture_dump` only writes; the computation is
bit-identical to an uninstrumented build (verified by byte-identical PNGs).

## Regenerating the oracle

1. Build the instrumented librsvg (a checkout of the same crate version, applying
   `librsvg/turbulence.rs`), then run the `rsvg-convert` commands above with the env
   var set to the absolute dump path.
2. Confirm the PNG written at the same time matches
   `tmp/librsvg-capture/turbulence_captured.png` / `tss_captured.png` (instrumentation
   outputs the same pixels).
3. Replace the `.kernel.bin` files here.

## Provenance / license

`librsvg/turbulence.rs` is a modified copy of librsvg (LGPL-2.1-or-later, copyright the
librsvg project) — see `COPYING.LIB` in a librsvg checkout. It is kept in the KSVG
repository solely to document the capture format and to make the parity test
reproducible; it is not part of the KSVG library build.