# ArithmeticComposite AArch64 NEON Worklog

Goal: make `ArithmeticCompositeNativeParityTest` green on arm64 (OnePlus 11 CPH2449).

Status: **DONE — 20/20 parity tests pass.**

## Root cause 1 — k1 was never applied in the vector path

`fmul v8.4s, v8.4s, v0.s[0]` was missing in the setup of both the non-linear and
linear vector paths. `v8` only contained `1/255`, so the `a*b` term was scaled by
`1/255` instead of `k1/255`. Fixed by adding the `fmul` in `.Lnonlinear` and `.Llinear`.

The scalar `SCALAR_FORMULA` path was already correct (`fmul s6, s6, s8` with `s8=k1/255`).

## Root cause 2 — `.Lnonlin_32` used a 32-pixel counter as a group counter

`w24` was computed as `span >> 5` (32-pixel groups) but decremented once per 8-pixel
store: 32 bytes are stored per iteration, so each iteration only consumed 8 pixels,
but `w24` counted 32-pixel units. For a 16-pixel row this produced 4x the writes.
Restructured to a single `.Lnonlin_8` 8-pixel loop; group count = `spanPixels >> 3`,
remainder = `spanPixels & 7`.

## Root cause 3 — scalar tails read garbage coefficients (user tip)

The vector loop's `ld4 {v0.8b-v3.8b}, [x9], #32` clobbers v0..v3, which initially hold
k1..k4. The scalar tails must recompute the folded constants from the *raw* k1..k4,
but they ran after the vector loop had overwritten v0..v3 with pixel data.

Fix: the prologue saves the raw k1..k4 in the spare frame slots:
- `stp s0, s1, [sp, #144]` / `stp s2, s3, [sp, #152]` (argument area starts at +160)

and both `.Ltail_scalar_nonlin` and `.Ltail_scalar_linear` reload them
(`ldr s0..s3, [sp, #144..156]`) before recomputing the scalar constants.

Verified in the deployed disassembly: `ldr s0..s3` present in both tails, prologue
`stp s0,s1,[sp,#144]` / `stp s2,s3,[sp,#152]` present.

## Root cause 4 — clipped width units: bytes vs pixels

For a clipped row the kernel walks rows at the full image stride `width*4`, but the
group counter was derived from `w13`, which `lsl x13,x13,#2` had converted to *bytes*:
`lsr w24, w13, #3` treated the byte span as a pixel span, producing 4x groups for the
clipped region (`subclip sRGB 32x32` failed; full-frame cases happened to be masked by
the overrun in root cause 2).

Fix in both `.Lrow_start_nonlin` and `.Lrow_start_linear`:
```
lsr w17, w13, #2  # clip width in pixels
lsr w24, w17, #3  # 8-pixel groups
and w25, w17, #7  # tail pixels
```

This also explains the OOM/SIGSEGV heap corruption pattern observed in the parity test
before the fix: the kernel wrote several times more output bytes than the caller's
`out` array, stomping adjacent ART objects (ArtMethod etc.). A guarded scratch-buffer
probe (temp, since removed) confirmed the overrun was real and confined it.

## Verification

- `ArithmeticCompositeNativeParityTest`: 20/20 pass on CPH2449.
- Both scalar tails confirmed to recompute constants from the saved coefficients.
- Temporary probe (ArithmeticDebugProbe.kt) and guard instrumentation in
  `arithmetic_composite.cpp` removed after the fix; the diff against the base contains
  only the `arithmetic_composite_aarch64_neon.S` changes above.