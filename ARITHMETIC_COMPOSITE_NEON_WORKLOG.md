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

---

# ARMv7-A (`armeabi-v7a`) NEON kernel — bug list and fixes

Status: **DONE — 20/20 parity tests pass on CPH2449 running the 32-bit kernel**
(`:filtering:connectedDebugAndroidTest -PfilterAbis=armeabi-v7a -Pandroid.testInstrumentationRunnerArguments.annotation=hu.oandras.ksvg.filtering.NativeParityTest`);
`tests=319 failures=0` overall, including the `[neon32]` ArithmeticComposite cases.
File: `arithmetic_composite_armv7a_neon.S`. The kernel mirrors the validated AArch64
kernel bit-for-bit (constant `k1*(1/255f)` = `0x3b808081`, `+0.5` then truncate,
non-FMA ordering, AArch64-style channel staging, scalar tail clamp [0,255] + truncate).
User directive honored: fixed lazily first (register staging with d16-d23), no
allocation/performance micro-optimisation yet.

## Bug 1 — row width captured after the constant builder clobbered r3

`mov r7, r3` (width capture) originally ran several instructions late, after
`movw`/`movt`/`vmov` had destroyed r3. Fix: capture width immediately after
`sub sp, sp, #16`.

## Bug 2 — FORMULA8 coefficients loaded through s-registers aliased live pixel lanes

`vldr s8/s9/s10` write d4/d5 low words = live src2 B/R lanes, and the subsequent
`vdup.32 q5, d8[0]`/`vdup.32 q6, d9[0]`/`vdup.32 q7, d10[0]` read the *wrong*
registers (d8..d10, not d4/d5). Fix: `ldr r2, [sp,#0/#4/#8/#12]` + `vdup.32 q5/q6/q7, r2`
(broadcast from a core register). Verified in disassembly.

## Bug 3 — scratch spills `[sp,#20]/[sp,#24]` corrupted the saved d8/d9

The scratch stores happened to land inside the `vpush {d8-d15}` area. Removed; no
stale references remain (grep-verified; only `[sp,#0-#12]` locals and entry args at
`[sp,#116-#156]` are touched).

## Bug 4 — useLinear lived in r12, which both `.Lnext_row` and LUT8 clobbered

Moved the flag to r9 for the whole invocation. Verified: `ldr r9, [sp,#148]` after
the row-count arithmetic, `cmp r9, #0` in `.Lrow`, and r9 untouched everywhere else.

## Bug 5 — scalar tails copied raw source bytes instead of computing the formula

Both `.Lnonlin_tail`/`.Llinear_tail` were copy loops. Replaced with real scalar
channels via new `CHANNEL`/`CHANNEL_L` macros (VFP s8..s11 constants, d6=0/d7=255,
`vmax`/`vmin` clamp to [0,255], truncating `vcvt.s32.f32 d2,d1`, `vmov r,s4`).
CHANNEL_L additionally applies srgbToLinear (`ldrb byte,[lut,byte]`) before and
linearToSrgb after the formula; alpha is formula-only, matching AArch64.
Register contracts: nonlin tail p=r0,q=r1,acc=r2,scratch=r12,counter=r3;
linear tail p=r2,q=r3,acc=r14,counter=r12,scratch=r7,lut=r0,lut2=r1.

## Bug 6 — fused VMLA vs non-FMA ordering

The original used `vmla` instructions; the validated kernels emit separate
`vmul`/`vadd` in the order `((a*b*k1) + a*k2) + b*k3) + c4`. FORMULA8 rewritten to
low/high groups matching AArch64 op-for-op.

## Bug 7 — prologue FDIV vs `k1 * (1/255f)`

The prologue computed `k1 / 255` with `vdiv`; a `vdiv 255` can differ by 1 ULP from
`k1 * 0x3b808081`, breaking bit-parity with the reference. Now `movw/movt 0x3b808081`
+ `vmul`. Also removed the now-dead `.L255`/`.Lhalf` literal-pool words.

## Bug 8 — LUT8 ran 256 iterations, over-reading the 256-byte LUT 16x

The loop used `adds r12,#1; bne`, so r12 walked 0..255 and the kernel yanked
`256*16 = 4096` bytes past the end of the caller's 256-byte LUT on every linear-mode
lookup (heap over-read). The row-select logic only needs the 16 LUT rows, so the loop
is now bounded with `cmp r12,#16`. Verified in disassembly: all LUT8 instantiations
end `adds r12,r12,#1; cmp r12,#16; bne`.

## Bug 9 — FORMULA8 clobbers q0..q7 after VLD4, destroying all channel planes

Both vector loops called FORMULA8 four times in sequence on the VLD4 planes d0..d7;
after the first call the G/R/A planes of both sources were gone (visible in the
original source too). The AArch64 kernel avoids this by staging the 8 channels in
x16..x23 GPRs. Fixed lazily: stage the planes in d16..d23 (q8..q11, free on AAPCS32)
right after the two VLD4s, process per channel from the staging regs, collect the
results in d24..d27 (q12/q13), then `vst4.8 {d24,d25,d26,d27}, [r6]!`. Applied to
both `.Lnonlin_vec` and `.Llinear_vec`.

## ARMv7 assembler gotcha (caught by build)

GAS/LLVM macro `#\shift` token-pastes when the shift argument already carries `#`
(`lsl ##24`). Pass bare shift numbers at CHANNEL/CHANNEL_L call sites.

## Build / disassembly verification

- `./gradlew ":filtering:buildCMakeDebug[armeabi-v7a]" -PfilterAbis=armeabi-v7a` builds clean.
- Disassembly of the packaged `libksvgblur.so` (armeabi-v7a) confirms every fix:
  `mov r7,r3` at 0x2222c; k1/255 `vmul` at 0x22240; `ldr r2` + `vdup.32 q5/q6/q7, r2`
  broadcasts; `vorr d16..d23` staging + `vst4.8 {d24,d25,d26,d27}`; LUT8 `cmp r12,#16`
  bounds; scalar tail clamp/truncate sequences.
- `.cxx/Debug/5q282620` and `build/intermediates/cmake/debug/obj` hold stale mixture
  artifacts from earlier builds; the authoritative, APK-packaged copies are
  `library_jni/debug/copyDebugJniLibsProjectOnly` and `merged_native_libs` — there both
  fixed and clean.

## Remaining notes

- Zero-height clips (`clipBottom == clipTop`) would run one row / loop in both the
  AArch64 and ARMv7 kernels (no upfront guard, mirroring the reference); the C++
  scalar loop is the only guarded variant. Out of scope: the SVG caller never passes
  empty clips, and diverging from the reference kernel was intentionally avoided.