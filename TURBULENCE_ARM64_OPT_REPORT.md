# feTurbulence ARM64 Kernel — Applicability Report: 32-bit Tricks → 64-bit

**Scope:** Which of the techniques refined on `turbulence_noise_neon32.S`
(scalar 1-px, 6.76× vs scalar at 512²) can be ported to
`turbulence_noise_neon64.S` (SIMD 2-px interleaved). Assessment only — no edits.
Follow-up execution order is in `TURBULENCE_ARM64_OPT_PLAN.md`.

**64-bit baseline (device, adbca122):**
| Backend | 512² ms | 2048² ms | Speedup |
| :--- | :--- | :--- | :--- |
| scalar | 81.224 | 1450.020 | 1.0 |
| neon64 | 4.534 | 72.342 | 17.9× / 20.0× |

**Key architectural difference:** the 32-bit kernel is a *scalar double* loop
with 4 channel accumulators (d16-d19) and a permanent VFP constant set. The
64-bit kernel is already vectorized (2 pixels interleaved, 4 sum-vectors,
branchless fabs via a sign mask), so several 32-bit tricks are simply *already
present* in stronger form. The real wins are the ones exploiting AArch64
addressing/instruction encodings that ARM32 lacked.

---

## Technique-by-technique analysis

### Round 3 — usat clamp  ➜  NOT NEW (already done, SIMD)
- 32-bit: per-pixel `usat r12,#8,r12` replaced a `cmp/movlt/cmp/movgt` clamp.
- 64-bit: the vector pack already does `sqxtun` (s64→u32 saturate, neg→0) +
  `umin` (cap 255) — the SIMD super-set of usat. Nothing to port.

### Round 3 — accumulator clear (veor q)  ➜  NOT NEW (already done)
- 64-bit uses `movi v0.2d,#0` / `v14.2d,#0` etc. Equivalent. Nothing to port.

### Rounds 3+4 — bitwise weight step (2^52 exponent decrement)  ➜  PORTABLE, MINOR
- 32-bit: `vsub.i64 d24,d24,d25` with permanent `d25=2^52` halves the reciprocal
  weight 1/2^octave bit-exactly, no Fp division.
- 64-bit current: per octave `ldr d29, const_half; fmul d28,d28,d29` (2 instr).
- Port: keep a permanent `dN=2^52` and do `fsub d28,d28,dN` (integer sub on the
  binary64 register) — 1 instr, and drops the const_half load. Valid because the
  weight is always a normal power of two (octave<1022). Gain: ~1 instr/octave.
- **Rating: easy, safe, ~small.** Requires a spare dN live across the loop.

### Round 4 — G1 hoisted fractal cmp  ➜  NOT NEW (already better)
- 32-bit hoisted one `cmp r8,#0` to feed 4 `vabseq`. 64-bit already folds the
  fractal test into a *per-entry* sign-mask `BIC` — no branch in the loop at all.
  Nothing to port.

### Round 4 — G2 dead freq load removal  ➜  PORTABLE, MINOR
- 64-bit `row_loop` reloads `ldr d21,[x0,#A_FREQ_Y]` at the start of the
  `curtly` computation (line 151) immediately after it was loaded for `py0`
  (line 143), with nothing clobbering d21 in between — the second load is dead.
  Likewise the scalar tail/row affine setup has redundant base-frequency loads.
- Port: hoist `freqX`/`freqY` (and the affine scalars) once into registers.
  Gain: a few loads/row. **Rating: trivial, low risk.**

### Round 4 — G4 row address `mul`→`mla`  ➜  PORTABLE, TRIVIAL
- 64-bit computes `y*width + clipLeft` as `mul w17,w6,w17; add w17,w17,w18`.
- Port: `madd w17, w6, w17, w18`. Saves 1 instr/row. **Rating: trivial.**

### Round 4 — G5 stack-cached pack constants  ➜  PORTABLE, GOOD WIN
- 32-bit moved the scale/offset/0.5 build out of the per-pixel path into the
  frame once per call; pack then does a single `vldm`.
- 64-bit current `pack_pixel_pair`: every pixel pair runs `cbz w1` branch +
  `ldr` (const_127_5/const_1 or const_255/0) + `dup` ×3 (`v24/v25/v26`) + `ldr`
  const_half. That is ~8-9 instr PER PIXEL PAIR doing work invariant across the
  whole row.
- Port: branch on the fractal flag **once at entry**, materialize the three
  `dup`'d vectors (scale/offset/0.5) into permanent vector registers (the pack
  context reuses v24/v25/v26, which are dead there), and the pack path becomes a
  straight FMA chain with no loads/branch. Saves ~8 instr/pixel-pair.
- **Rating: clean win, moderate risk (register lifetime), the most valuable
  G5-style port.**

### Round 5 — shared 8-pointer gradient cache  ➜  SUPERSEDED BY a better encoding
- 32-bit cached 8 gradient *addresses* in GPRs because ARM32 `vldr` has no
  register-indexed addressing, costing 32→8 adds/octave.
- AArch64 **hardware supports register-indexed addressing**, so the same idea is
  expressed more cheaply: `ldr q16,[x3,x12,lsl#5]` replaces
  `add x16,x3,x12,lsl#5; ldr q16,[x16]`, and the channel-2/3 +16 offset is
  `ldr q16,[x3,x12,lsl#5,#16]`. Both channel blocks collapse from 16 adds+16
  loads to 16 loads — **saves ~16 adds/pixel**, which is *more* than the 32-bit
  round-5 win and needs NO new registers (x16/x17 were only address scratch).
- This is the single largest, cleanest transferable win. **Rating: top priority.**
- Constraint: gradient rows must stay `[ch0,ch1]` at +0 and `[ch2,ch3]` at +16
  of a 32-byte-stride lattice — the existing layout already satisfies this
  (the +16 loads confirm it), so parity is preserved address-for-address.

### Round 4 — permanent 2^52 SMOOTHSTEP doubling  ➜  N/A for 64-bit
- 32-bit used `vadd d5,t,t` for the exact 2*t to keep d25 purely the step
  constant. 64-bit already does FMUL by a const_2 literal; s̄moothing order is
  unchanged and there is no shared-constant pressure conflict here. Not needed.

### Not applicable (structural)
- The whole octave-outer/channel-inner restructure (Steps A-F / Session 3) is
  already how the 64-bit kernel is built.
- The ARM32-only stack-collapse / constant-set tricks (d0=1.0, d1=4096, d2=3.0
  permanents) mirror constants the 64-bit kernel loads from the literal pool per
  use; the 64-bit FADD/FMUL/FSUB operand-style does not need the same
  register-hoist, though a few literals could be pre-loaded (see G2).

---

## Priority ranking (found in the plan)
| # | Trick | Est. gain | Risk |
| :--- | :--- | :--- | :--- |
| 1 | AArch64 register-indexed gradient loads (`[x3,xN,lsl#5]`, `#16`) | ~16 instr/px (highest) | low |
| 2 | G5 pack constants materialized once (vectors) | ~8 instr/px-pair | med |
| 3 | G2 dead freq load removal + affine scalars | few/row | low |
| 4 | bitwise weight step (permanent 2^52) | ~1 instr/octave | low |
| 5 | madd row address | 1/row | trivial |

All ports must keep the FP op order identical (parity is bit-exact, `ffp-contract`
is off in the reference and the asm is hand-scheduled). Each change is verified
against `TurbulenceNativeParityTest` on-device before the next.