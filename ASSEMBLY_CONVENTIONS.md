# SIMD Kernel Development Ground Truth

This document collects the most important invariants and reverse-engineered lessons required for continuing development of the hand-written SIMD kernels in `filtering/src/main/cpp/**/*.S`.

The priority order is:

> **ABI → register liveness → PIC → exact FP operation order → rounding → lighting window/center-height → tail → parity → target build/link/runtime validation**

## 1. ABI and argument layout — hard contract

The assembly argument layout is ISA-specific and must never be copied from one ISA to another.

| ISA | srcT | srcM | srcB | dst | count | params | l2s |
|---|---|---|---|---|---|---|---|
| x86-64 SysV | `rdi` | `rsi` | `rdx` | `rcx` | `r8` | `r9` | register |
| i386 cdecl | `frame+20(%esp)` | `+24` | `+28` | `+32` | `+36` | `+40` | **global / not passed** |
| AArch64 AAPCS64 | `x0` | `x1` | `x2` | `x3` | `x4` | `x5` | register |
| ARMv7 AAPCS32 | `r0` | `r1` | `r2` | `r3` | `[sp,#0]` | `[sp,#4]` | register |

### i386-specific rule

i386 stack offsets depend on the frame size.

With the standard prologue:

```asm
push ebp
push ebx
push edi
push esi
sub $N
```

the first argument is at:

```text
(N + 20)(%esp)
```

and every subsequent argument is at `+4`.

**Never port x86-64 argument offsets to i386.**

Always derive the actual offsets from:

1. the C/C++ call site,
2. the dispatcher,
3. and the assembly prologue/frame size

for the target ISA.

### i386 Linear kernels

The i386 `Linear` kernels take **6 arguments**. There is no `l2s` register/stack slot.

The linear → sRGB LUT is accessed globally:

```text
ksvg_linear_to_srgb_lut
```

with PIC access:

```text
@GOT(%ebx)
```

Reading a nonexistent seventh argument can return stack garbage and lead directly to a SIGSEGV.

---

## 2. Register budget and liveness

### Register budget

- x86-64: 16 XMM/YMM registers
- i386: **8 XMM/YMM registers (`xmm0–xmm7` / `ymm0–ymm7`)**
- AArch64: `v0–v31` are caller-saved
- ARMv7: 16 q-registers
- On ARMv7, `d8–d15` (`q4–q7`) are **callee-saved**

This is especially important for i386 register allocation and spill planning.

### Register liveness — hard review rule

A register may only be considered dead if it is dead across the entire remaining control-flow path.

Check:

- straight-line code,
- LUT paths,
- fallback paths,
- epilogues,
- every later branch.

A register that appears dead locally may still be live in a later branch.

---

## 3. PIC — mandatory shared-library invariant

### x86-64

Use RIP-relative addressing for read-only constants:

```asm
addps .Lhalf(%rip), %xmm1
```

Never use absolute addressing.

### i386

PIC requires a GOT base:

```asm
calll .L0$pb
.L0$pb: popl %ebx
addl $_GLOBAL_OFFSET_TABLE_+(.Ltmp0-.L0$pb), %ebx
```

Local constants:

```asm
@GOTOFF(%ebx)
```

Global symbols:

```asm
@GOT(%ebx)
```

As long as such code is reachable, `%ebx` must not be clobbered.

### AArch64

Use PC-relative addressing (`adrp/add`, literal pools, etc.).

Avoid absolute addressing for tables and LUTs that would introduce text relocations.

---

## 4. Symbol / build convention

Every `.S` file uses:

```asm
#include "asm_macros.S"
```

Do not duplicate platform/symbol/CFI wrappers inside individual files.

`asm_macros.S` handles, among other things:

- `SYM`
- `TYPE`
- `SIZE`
- `CFI_*`
- `CALL`
- section macros

The kernel entry-point name must **exactly match** the corresponding C/C++ declaration and dispatch symbol.

Symbol mismatches typically cause:

- link errors on x86,
- potentially runtime crashes on ARM.

---

## 5. Calls/jumps to exported functions in ELF shared libraries

For an exported global symbol in an ELF shared library:

```asm
jmp symbol@PLT
```

and:

```asm
call symbol@PLT
```

A plain:

```asm
jmp symbol
```

may use an invalid relocation form in a shared library.

Use `CALL()` where applicable for calls. Forwarding `jmp` stubs must explicitly use the proper PLT form.

Apple/Mach-O must follow the platform wrappers defined by `asm_macros.S`.

---

## 6. sRGB rounding invariant — every channel

The reference rounding is:

```cpp
clamp255(value) = value.roundToInt().coerceIn(0, 255);
```

Therefore, before float → int conversion:

```text
value + 0.5f
```

is required.

Example on x86:

```asm
addps .Lhalf(%rip), %xmm...
cvttps2dq ...
```

On i386 the `0.5f` constant is typically loaded from `.rodata` via `@GOTOFF(%ebx)`.

On AArch64, for example:

```asm
fmov v27.4s, #0.5
```

### Important

The `0.5f` addition is not an optional optimization detail. Omitting it causes approximately half of the affected output values to differ by 1 LSB.

---

## 7. Exact floating-point operation order

For parity, floating-point operation order is semantically significant.

For example:

```text
/255.0f
```

and:

```text
* (1/255.0f)
```

are not necessarily bit-identical.

Introducing FMA/fused instructions can also change output bytes.

### Rule

**Keep the assembly FP operation order compatible with the reference backend when optimizing.**

Do not assume that a mathematically equivalent reassociation is parity-safe.

---

## 8. Lighting window semantics

For lighting kernels, the output pixel `x` uses a three-tap window:

```text
src + 0
src + 4
src + 8
```

The pointers:

```text
srcT/srcM/srcB -> x-1
```

therefore mean:

```text
src[+0] = x-1
src[+1] = x
src[+2] = x+1
```

### Center height — critical rule

For point/spot light Z-distance, the surface height is:

```text
srcM[+1]
```

i.e. the **window-center pixel** height.

**Not `srcT`.**

`srcT` is the top Sobel row. It must not be substituted for the surface height used by the proximity term.

---

## 9. Lighting math invariants

- `h = (alpha >> 24) * ss`
- Distant Sobel gradient:
  - `dzdx = (sumT_r - sumT_l)` etc.
  - `ss` is folded into the gradient scale
- Per-pixel:
  ```text
  dxRel = (rT - lT) + 2*(rM - lM) + (rB - lB)
  ```
- For frontal lights:
  ```text
  dot = max(0, n·l)
  ```
- Negative dot → black
- Negative dot → no specular term
- Intensity:
  ```text
  clamp(k * dot) -> [0,1]
  ```

The reference operation order takes priority for parity.

---

## 10. Output packing

Final ARGB:

```text
(R << 16) | (G << 8) | B | 0xFF000000
```

The alpha may come from a constant or a LUT-based path.

Important:

- 8-bit channel values remain linear until the final stage,
- the linear → sRGB LUT is only used by the `*Linear` kernels.

---

## 11. Vector loop and tail

Every vector kernel must also work when:

```text
count % vector_width != 0
```

### General structure

- vector main loop,
- required fallback/tail,
- scalar remainder.

AArch64 commonly uses:

```text
8 pixels main
→ 4-lane tail
→ scalar remainder
```

x86 commonly uses:

- full-vector main loop,
- epilogue,
- scalar tail or branch-specialized fallback.

### Performance

For a 1–3 pixel remainder, a simple scalar fallback is often faster than introducing masked vector operations.

---

## 12. Resource discipline

- Do not introduce mutable global/static write buffers.
- Scratch must be caller-owned.
- State must be per-call or stored in caller-provided scratch.
- On ARMv7, used `d8–d15` registers must be preserved.
- Do not introduce mutable global state as a performance optimization.

---

## 13. Parity gate — absolute correctness gate

Every native-kernel change must pass the corresponding:

```text
*NativeParityTest
```

The parity test:

- uses a deterministic corpus,
- checks bit-exact output,
- compares against the Kotlin/scalar reference.

### Important

The following are **not** correctness proofs:

- compile success,
- assembler success,
- linker success,
- improved benchmark numbers.

**Parity is the correctness gate.**

---

## 14. First-mismatch rule

The parity assertion aborts on the first mismatch.

Therefore the development loop is:

```text
fix → full parity run → new mismatch → fix → full parity run
```

Fixing one issue can reveal another mismatch that was previously masked.

Do not treat the current mismatch index as the complete bug set.

---

## 15. i386 PIC / runtime validation

Successful assembly does not prove that i386 PIC code is correct.

When modifying i386 PIC code, explicitly check:

- GOT/GOTOFF addressing,
- GOT-base liveness,
- stack argument offsets,
- destination-pointer liveness,
- PLT calls/jumps,
- shared-library relocations.

Validation sequence:

```text
assemble
→ build shared object
→ link
→ target runtime
→ NativeParityTest
```

For text-relocation-sensitive changes, inspect relocations with tools such as `llvm-readelf`, including `TEXTREL` and problematic `R_386_32` relocations.

---

## 16. NDK vs host-native build

Keep these two artifacts separate.

### Android

```text
NDK / CMake
```

This produces the real Android native library.

### Host

```text
buildHostNativeLib
```

This is only for host-JVM parity testing.

Do not automatically treat a host toolchain or IDE error as an Android native-code problem.

---

## 17. Spill and register reuse

On i386, vector-register pressure is high, so spill budget is critical.

When there is no room for another stack spill, a loop constant can be broadcast into a dead vector register:

```asm
vbroadcastss .LCPI...@GOTOFF(%ebx), %ymm3
```

but only when the register is **provably dead across the entire downstream control flow**.

Register reuse may be preferable to reorganizing the stack frame.

---

## 18. Deterministic parity corpus

The parity corpus uses a deterministic LCG:

```text
state = state * 1664525 + 1013904223
```

Seed:

```text
0x9E3779B9
```

Pixel height/alpha is derived from:

```text
(state >> 24) & 0xFF
```

Do not:

- reseed,
- normalize,
- alter,

the corpus merely to make a parity test pass.

Determinism is part of the parity mechanism.

---

# Development Checklist

Before modifying assembly:

- [ ] C/C++ call site and ABI verified
- [ ] ISA-specific arguments re-derived
- [ ] i386 frame offsets recalculated
- [ ] register budget checked
- [ ] every reused register proven dead across downstream control flow
- [ ] PIC addressing verified
- [ ] i386 `%ebx` preserved as GOT base
- [ ] exported ELF calls/jumps use PLT
- [ ] lighting center height uses `srcM[+1]`
- [ ] FP operation order remains reference-compatible
- [ ] `+0.5f` rounding invariant preserved
- [ ] output packing unchanged
- [ ] vector tail handled
- [ ] ARMv7 callee-saved NEON registers preserved where relevant
- [ ] no mutable global scratch introduced

After modifying assembly:

- [ ] target shared library built
- [ ] linker result verified
- [ ] relocations checked where relevant
- [ ] target runtime executed
- [ ] full `*NativeParityTest` passed
- [ ] any newly exposed mismatch fixed and parity rerun
- [ ] benchmark run only after clean parity
- [ ] performance improvement accepted only together with parity success
