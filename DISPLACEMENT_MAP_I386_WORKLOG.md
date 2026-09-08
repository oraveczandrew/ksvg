# i386 SSSE3 displacement-map crash fix

## Finding

`ksvgDisplacementMapApplySsse3_i386` loaded the scalar `width - 1` and
`height - 1` locals as four-lane vectors. The adjacent stack slots were then
used as clamp limits for lanes 2–4, producing invalid source indices and an
i386 emulator SIGSEGV.

The 16 SSSE3 dispatch entries also used B/G/R/A masks for the public
R/G/B/A channel indices.

## Fix and verification

- Broadcast each scalar clamp limit with `movd`/`pshufd`.
- Correct the 16 channel-dispatch entries to R/G/B/A order.
- Rebuilt the x86 native library and ran
  `DisplacementMapNativeParityTest` on the API 26 x86 emulator: 10/10 passed,
  no crash.
