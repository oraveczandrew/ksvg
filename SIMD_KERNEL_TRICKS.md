# SIMD Kernel Tricks from the Top-Performing Filters

Distilled from the kernels that benchmark best in `BENCHMARKS.md`, plus the
worst cases used as negative controls. Goal: a checklist of transferable tricks
for optimizing any future filter kernel.

Source data: host (i7-7820X), x86-32 emulator, OnePlus 11 arm64 + arm32 tables.
Marker legend as in `BENCHMARKS.md` (🚀 >9x, 🟢 >1x, 🔴 <1x).

## Analysed kernels

| Kernel | Best speedups | What wins | Source |
| :--- | :--- | :--- | :--- |
| Morphology | arm64 101–117x, arm32 139–143x, x86-32 sse2 103–105x | two-pass fold + byte-lane min/max | `morphology/` |
| GaussianBlur | arm64 55–57x, arm32 42x | unrolled branch-table window, fixed-point, register window | `blur/blur_aarch64_neon.S` (AOSP-derived) |
| ConvolveMatrix | arm64 17–19x, arm32 14–18x | 4px block, fused scaling consts, interior/edge split | `convolve/` |
| Turbulence | arm64 20x | 2px interleave, branchless fabs, packed tail | `turbulence/turbulence_noise_aarch64_neon.S` |
| ArithmeticComposite (non-linear) | arm64 18–19x, arm32 18–23x | register-resident LUT + whole-vector float math | `arithmetic_composite/arithmetic_composite_neon.cpp` |
| Lighting | host 15–16x, x86-32 38–55x 🚀 (arm64 neon64 0.97x 🔴!) | 4px unroll, hoisted reciprocals, fused domain scale | `lighting/lighting_distant_diffuse_x86_64_ssse3.S` |

The last row is the most instructive warning in the table: an AArch64 NEON
kernel that does *exactly scalar-speed* work is usually a broken or
mis-optimized path, not a "no SIMD gain" case.

---

## 1. Decompose the footprint: two-pass folds + shared scratch

Morphology (a *square* window) is not separable in the classic sense, but the
window's structure lets you split work:

1. **Vertical fold into a scratch "span buffer"** — for each output column fold
   `2*radiusY+1` rows with `umin`/`umax` on raw 16-byte vectors.
2. **Horizontal fold over the scratch** — fold the `2*radiusX+1` span with
   `umin`/`umax`, then reduce the 4 pixels of the resulting vector to one.

Why it wins (vs. per-pixel re-touching the source):
- Overlapping horizontal windows of adjacent outputs share all but one tap.
  Re-reading the same source bytes per output pixel is replaced by a **shared
  L1 scratch row** (`spanBuf`). `morphology.cpp:267`, `morphology.cpp:585`.
- The row kernel is called **once per row, not once per pixel**; all header
  math (bounds, strides, sign-extension) is hoisted out of per-pixel work.
- The scratch buffer is allocated **once** in `applyForcedRow` (outside the
  row loop), not inside it.

Do the same whenever outputs overlap: fold once into scratch, then per-output
work sees L1-resident input.

Also note the interior/border split used by Morphology and Convolve: only
**fully-interior windows** run the row kernel; the thin top/bottom/left/right
bands run scalar. The interior band is where the speedup lives; the borders
would fight it (see §9).

## 2. Keep pixels packed: byte-lane SIMD wherever the math is per-channel

Morphology and blur never deinterleave to planar. Because a little-endian
ARGB int is bytes `B G R A` in memory, a vector load starting on a pixel
boundary has a **fixed channel→lane map** (lane 0=B, 1=G, 2=R, 3=A). So a
single `vminq_u8`/`pmaxub` is exactly the scalar per-channel min/max — no
unpack, no repack, no masks. SSE2 is sufficient (`pminub`/`pmaxub`); only the
horizontal reduce needs the shift-ladder on x86:

- ARM: `uminv b0, v0.16b` / `umaxv b0, v0.16b` reduces all 4 pixels' worth of
  lanes in **one instruction**, then `dup v0.4s, v0.s[0]` + `str s0`.
- x86: `psrldq $8` + `pmaxub`, then `psrldq $4` + `pmaxub`, then `movd`
  (`morphology_x86_64_sse2.S:267-274`).

Lesson: prefer filters that *stay packed* (min/max, dash, opacity masks). Only
go planar (and→shift→`ucvtf` per channel) when the math genuinely needs
float/numeric per channel.

## 3. Fold the domain conversion and rounding bias into constants

Lighting (`lighting_distant_diffuse_x86_64_ssse3.S`) and ArithmeticComposite
both move *every* per-pixel scale into pre-computed, `dup`'d scalars:

- `1/invDx` and `1/invDy` are computed with **one `fdiv` before the loop**
  (`:34-42`) instead of per pixel.
- The `/255` domain scale is algebraically folded: `result = k1*in1*in2/255 +
  k2*in1 + k3*in2 + k4*255` — the compiler/AI passes `k1/255.0f` and `k4*255.0f`
  as scalars, so the loop body contains **no division** at all.
- The `+0.5` rounding bias (matching the scalar `floor(v+0.5)` convention) is
  pre-added to the constant (`k4_255 + 0.5f`) or added once per vector.

Same pattern in Convolve: `1/divisor` and `bias*255` materialized once into
`v30`/`v31` (`convolve_aarch64_neon.S:85-91`).

## 4. Runtime-variable window: fully unrolled, jump into the middle

GaussianBlur's AOSP macros are a masterclass for a **variable-radius
convolution** where branching per tap would dominate:

- The vertical fetch loop is fully unrolled for taps `0..MAX_R` (here 27),
  ordered **outside-in**. Entry for a given `r` is computed as a pointer
  (`adr/adrp` + `br`) into the *middle* of the unrolled body, so the kernel
  executes exactly `r` taps with **zero per-tap loop overhead**
  (`fetch` macro, `blur_aarch64_neon.S:82-234`). Two loop variants exist:
  `clamped` (edge, uses `csel` to clamp row pointers) and `noclamp` (interior).
- **Symmetric taps are folded first**: `uaddl v16.8h, v10.8b, v11.8b` adds the
  two symmetric rows, then one `umlal` multiplies the pair — halving multiply
  count.
- Runs at 8-bit → 16-bit → 32-bit **fixed point** (`.set FRACTION_BITS, 7`),
  not float: `umull`/`umlal` widen, and `uqrshrn` narrows back with
  rounding + saturation for free. This beats float on integer-heavy cores.
- The horizontal convolution keeps the sliding window **register-resident**
  as long as usable, rotating with `mov vN, vN+1` (`hconv1_8`…`hconv4_25`).
  Only the widest variant spills to the `[x9]` buffer, still using a circular
  `base + (index & mask)` addressing trick (`bic x9, x9, #0x40`).
- Prefetch (`prfm`) is compiled in/out with a `#define` so it can be cheaply
  A/B-tested per core.

## 5. Interleave two or four pixels per iteration

Per-pixel setup that cannot be hoisted is amortized by processing **N pixels
per iteration**:

- Turbulence processes **2 adjacent pixels per outer-loop iteration**, sharing
  all Y geometry (floor/frac/smoothstep/permutation) and the stitch/octave
  counters (`turbulence_noise_aarch64_neon.S`, `octave_loop_2`). Two
  independent accumulator pairs (`v0/v1` = P0, `v14/v15` = P1) also hide FP
  latency by giving the OoO core independent chains.
- Lighting processes **4 pixels** (one SSE vector) per iteration.
- Convolve processes a **4-pixel block** per iteration: one base-pointer
  computation, four `ld1 {v0.4s}` per tap.
- Pairs/blocks have a scalar tail for the leftover 1–3 pixels (`tail_pixel`,
  the morphology `tail` paths). Never write a partial vector.

## 6. One canonical ARGB pack pipeline

The winners converge on the same numeric → ARGB32 tail. Copy this shape:

```
convert  float → int with scalar-matching rounding      // Lighting: addps half + cvttps2dq
or       fadd 0.5 (into pre-made [0.5,] vector)
clamp to [0,255]: fmax/fmin against dup'd 0 and 255.0   // after the rounding, as float
or       sqxtun (s64→u32, negatives→0) THEN umin #255   // NEON: 2 instr replace 4-way clamp
shl R <<16, G <<8, A <<24
orr chains (B | R | G | A)
store the packed vector
```

Details worth copying:
- Convolve keeps `0.5` in `v29` and clamps with `fmax/fmin` + `fcvtzs`
  (`convolve_aarch64_neon.S:189-206`) — matching the scalar `clamp255`
  round-half-up *exactly* (this exactness is why parity stays bit-exact).
- Turbulence's single-pixel tail uses `fcvtzs` + `csel` clamp pairs; the
  2-pixel path uses `sqxtun`+`umin` saturation — the latter is preferable.
- **Preserve alpha**: Convolve reloads the 4 source pixels and does
  `ushr #24` + `shl #24` on the vector (`:212-214`) instead of per-lane scalar
  extraction. ArithmeticComposite keeps alpha **out of the sRGB LUT**
  (`alpha remains non-linear in linear-light mode`) and processes it directly.
- Pre-build constant vectors once, then either keep them in permanent vector
  registers or cache them in the stack frame and reload with plain qword loads
  (`S_PACK_SCALE`/`OFFSET`/`HALF`, turbulence G5). Only the reload-from-frame
  variant is safe when later code clobbers the registers — see the `v30`
  "reset to #255" comment in `pack_pixel_pair`.

## 7. Branchless mode selection with a sign mask

Turbulence's fractal/turbulence choice is not a per-pixel branch. A permanent
`v7` holds `0x8000000000000000` in both 64-bit lanes for turbulence, `0` for
fractal; the accumulation does `bic v2.16b, v2.16b, v7.16b` — fabs when set,
identity when zero. One mask, zero branches, set once at entry
(`turbulence_noise_aarch64_neon.S:135-143`).

## 8. Register-resident LUTs — and when SIMD LUT is a trap

Two very different outcomes for per-byte LUT work:

**Works (ArithmeticComposite linear-light, arm64 18–19x):** the whole 256-byte
sRGB↔linear table is loaded **once per call** into 16 **register-resident**
16-byte `vtbl` tables (`tS2L[16]`, `parse` in the header comment), reused for
every row. It still wins big *because under the LUT there is a real
per-pixel float computation* (`applyArithmeticFormulaNeon64`) to amortize the
gather.

**Fails (UnLinearize / ComponentTransfer / Arithmetic(linear) SSSE3, 0.03–0.6x 🔴):**
when the *entire kernel is the LUT*, the 128-bit exact-lookup cost is
irreducible: an exact 256-entry per-byte map needs a 16-way `pshufb`
compare-and-select ≈ **21.75 ALU/px + 4 LUT loads/px** against the cache-hot
scalar's **19 ops/px**. The `UnLinearize` A..E study proved this surgical:
- unroll factor (4/8/16 px) — noise;
- relocating/hoisting the LUT rows into registers so the load-port pressure
  disappears (`variant D`) — **no** gain;
- replacing all 16 `pcmpeqb`/`paddb` with an exact 4-bit decision tree
  (`variant E`, −17% ALU, dependency depth 16→4 levels) — **no** gain.

Residue is the fixed per-vector leaf gather. Conclusion: **on 128-bit
registers, a pure LUT kernel should stay scalar** (or wait for a wide enough
vector — AVX2 hoists the 256-entry table into 8 YMM and measured 1.4x). Do not
chase structural overhead before running a negative-control experiment like D/E.

## 9. Thin edge bands: scalar wins; specialize scalar instead

Convolve's NEON edge kernels were tried, measured, and reverted
(`NEON_EDGE_OPT_WORKLOG.md`): edge bands are thin (a 5×5 kernel → ~2px bands),
so per-pixel SIMD setup exceeds the work it saves. What won instead:

- **Specialized scalar edge**: pin the runtime `edgeMode` (clamp) so the
  branchy sampler collapses (`convolveScalarPixelClamp` removes the wrap/none
  branch and the `srcX<0` guard). Cheap, big, and bit-exact.
- Interior rectangle gets the branch-free SIMD kernel; the 1..3 px row tail is
  filled **by the caller** with scalar (the ASM returns its first-unprocessed
  `x`).

Rule: measure edge SIMD before shipping it. Setup-dominated kernels on thin
ranges lose; the interior is where SIMD pays.

## 10. Bit-exactness & measurement discipline (preconditions for all of the above)

- **Reference first.** A bit-exact scalar reference (Kotlin `SoftwareKernels` /
  C++ scalar) is written before the SIMD kernel; the parity suite (18/18
  green on host + device) blocks every assembly change. The Lighting x86 fix
  found the *kernel itself was mathematically wrong* (extra `/255`) — verify
  the math before optimizing the vectors. `sqrt`/`rsqrt` choices (`frsqrte`+
  Newton, `vrsqrts`) must match the reference's rounding to stay byte-exact.
- **Keep FP op order identical.** The reference compiles with `ffp-contract`
  off and the asm is hand-scheduled; a reordered `fmla`/`fmul` chain changes
  low bits. Verify bit-exactly after *every* scheduling change.
- **Controlled benchmarking.** Cross-session numbers mislead — the "NEON-edge
  win" was thermal/clock noise invalidated by a single-session, kernel-only,
  median-based re-run. Compare backends in the same session, use medians, and
  flag unstable rows.
- **ABI traps.** ARM32 NEON has q0–q15 only (AArch64 q16+ assembles on some
  toolchains but fails `armeabi-v7a`); callee-saved d8–d15 must be
  `vpush`'d/`vpop`'d; stack-arg offsets shift when the prologue grows. Recheck
  on the 32-bit target even when the 64-bit build is green.

## 11. Correctness and dispatch lessons from failed optimizations

### 11.1 Treat rounding as part of the algorithm

The scalar reference defines the contract. Do not fold a division into a
reciprocal multiply, change `fmul`/`fadd` ordering, or introduce FMA merely
because the real-number formula is unchanged. A one-ULP intermediate
difference can cross the final `+0.5` pack threshold. For every such change,
run the complete forced parity corpus before benchmarking.

### 11.2 Disable measured losers instead of preserving a bad fast path

The 128-bit exact-LUT experiments established a durable negative result:
unrolling, keeping LUT rows in registers, and changing the compare/select tree
did not remove the fixed per-byte gather cost. On those targets the scalar
loop is the production choice. Keep `applyForced` for characterization, but do
not advertise a backend that loses to scalar.

### 11.3 ABI, aliasing, and PIC checks belong in the optimization loop

- Capture dimensions and flags before constant materialization can clobber
  argument registers.
- Never put live coefficients, divisors, counters, or constants in registers
  whose lanes are overwritten by pixel loads or row broadcasts.
- Keep pointer and counter roles distinct; aliasing can turn a tail bug into an
  out-of-bounds loop.
- On ARM32, preserve d8-d15 and use the actual post-prologue stack offsets. On
  i386, recalculate stack arguments after every prologue change.
- Address literal pools and dispatch tables PC-relatively. A successful
  assembly is insufficient if the final Android library contains text
  relocations.

### 11.4 Edges and tails are separate kernels

Thin borders rarely amortize vector setup. Use a branch-specialized scalar
sampler for edge modes when measurements support it, reserve SIMD for the
interior, and let the caller handle 1-3 pixel tails. Never use a full-vector
load/store on a partial block just to avoid a scalar tail.

### 11.5 Benchmark validity is part of the result

Compare scalar and SIMD in the same harness run and prefer medians over
cross-session averages. Record thermal invalidations, batch CV, and CPU
frequency where available. A changed absolute time without a controlled
same-session comparison is not evidence of a kernel improvement.

### 11.6 Turbulence and byte-LUT validation traps

- A 256-entry table is not covered by a 64-byte AArch64 `vqtbl4q_u8` lookup.
  Use a bounded 16-row scheme (or a wider proven design), and test every
  index 0..255 on every color channel.
- When an indexed lattice table has a mirrored tail, initialize the
  `selector32` and gradient mirrors too. Host scalar/SSSE3 parity can pass
  while an AVX2-only index range reads uninitialized tail data.
- Native seed normalization must match the Kotlin RNG for `seed <= 0`; parity
  cases with only positive seeds do not cover this validation failure.
- `roundToInt()` parity requires explicit `floor(v + 0.5f)` semantics. Native
  nearest-even conversion is not an equivalent replacement at half values.
- AArch64 assembly must save every used AAPCS64 callee-saved register. Also
  re-establish constants at the point of use when a low D lane aliases a
  geometry scratch register.

### 11.7 Validated implementation outcomes

- ConvolveMatrix scalar edge specialization is bit-exact and outperforms
  forcing SIMD across thin borders; keep the vector kernel focused on the
  interior rectangle.
- The AArch64 Morphology kernel required explicit separation of tail counters
  from row cursors and per-column accumulator reset. After those fixes it
  passed the 108-case corpus and measured about 12.5x at 512² and 14.7x at
  2048² in one controlled device run.
- UnLinearize uses a bounded 16-row AArch64 lookup for the full byte domain;
  the lean SSSE3/AVX2 paths are byte-exact. Do not replace this with a
  64-entry lookup that silently truncates indices.

---

## Quick checklist for a new filter

1. Is the footprint separable, or do outputs overlap? → scratch span buffer +
   row kernel (§1, §4).
2. Is the math per-channel and monotone? → stay packed, byte-lane min/max
   (§2); numerics → planar extract→`ucvtf` (§3).
3. Hoist: reciprocals, `/255`, `+0.5`, `*255` → pre-computed dup'd scalars (§3).
4. Variable radius/taps? → unrolled body + computed jump entry (§4).
5. Amortize per-pixel setup → 2/4 px per iteration + scalar tail (§5).
6. Pack with the canonical +0.5 → round → clamp → shift/orr chain (§6).
7. Mode switch → sign-mask, not branch (§7).
8. Edges → specialized scalar, interior-only SIMD (§9).
9. Pure LUT on 128-bit? → keep scalar; only vectorize if real math sits under
   the lookup (§8).
10. Parity suite + controlled single-session bench before/after every change
    (§10, §11).
11. ABI/PIC audit → verify struct offsets, callee-saved registers, stack args,
    and final-library relocations before trusting runtime dispatch (§11.3).