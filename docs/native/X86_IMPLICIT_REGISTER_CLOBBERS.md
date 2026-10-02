# x86 / x86-64 — Implicit Register and State Clobbers

| Instruction | 32/64 bit | Implicit input(s) | Clobbered / modified register(s) or state |
|---|---|---|---|
| `MUL r/m8` | 32/64 | `AL` | `AX`, flags (`CF/OF` defined; others undefined) |
| `MUL r/m16` | 32/64 | `AX` | `DX:AX`, flags |
| `MUL r/m32` | 32/64 | `EAX` | `EDX:EAX`, flags |
| `MUL r/m64` | 64 | `RAX` | `RDX:RAX`, flags |
| `IMUL r/m8` | 32/64 | `AL` | `AX`, flags |
| `IMUL r/m16` | 32/64 | `AX` | `DX:AX`, flags |
| `IMUL r/m32` | 32/64 | `EAX` | `EDX:EAX`, flags |
| `IMUL r/m64` | 64 | `RAX` | `RDX:RAX`, flags |
| `DIV r/m8` | 32/64 | `AX` | `AL`, `AH` (quotient/remainder), flags undefined |
| `DIV r/m16` | 32/64 | `DX:AX` | `AX`, `DX`, flags undefined |
| `DIV r/m32` | 32/64 | `EDX:EAX` | `EAX`, `EDX`, flags undefined |
| `DIV r/m64` | 64 | `RDX:RAX` | `RAX`, `RDX`, flags undefined |
| `IDIV r/m8` | 32/64 | `AX` | `AL`, `AH`, flags undefined |
| `IDIV r/m16` | 32/64 | `DX:AX` | `AX`, `DX`, flags undefined |
| `IDIV r/m32` | 32/64 | `EDX:EAX` | `EAX`, `EDX`, flags undefined |
| `IDIV r/m64` | 64 | `RDX:RAX` | `RAX`, `RDX`, flags undefined |
| `CQO` | 64 | `RAX` | `RDX` |
| `CQD` / `CDQ` | 32 | `EAX` | `EDX` |
| `CWD` | 16 | `AX` | `DX` |
| `CBW` | 16 | `AL` | `AX` |
| `CWDE` / `CWDE` | 32 | `AX` | `EAX` |
| `CDQE` | 64 | `EAX` | `RAX` |
| `CWD` | 16 | `AX` | `DX` |
| `XLAT` | 32/64 | `AL`, `RBX/EBX` base | `AL` |
| `IN AL, DX` | 32/64 | `DX` | `AL` |
| `IN AX, DX` | 32/64 | `DX` | `AX` |
| `IN EAX, DX` | 32/64 | `DX` | `EAX` |
| `IN RAX, DX` | 64 | `DX` | `RAX` |
| `OUT DX, AL/AX/EAX` | 32/64 | `DX`, source | I/O side effect; no GPR destination |
| `INSB` | 32/64 | `RDI`, `RDX`, `DF` | memory at `RDI/EDI`, `RDI/EDI` |
| `INSW` | 32/64 | `RDI/EDI`, `RDX`, `DF` | memory, `RDI/EDI` |
| `INSD` | 32/64 | `RDI/EDI`, `RDX`, `DF` | memory, `RDI/EDI` |
| `INSQ` | 64 | `RDI`, `RDX`, `DF` | memory, `RDI` |
| `OUTSB` | 32/64 | `RSI/ESI`, `RDX`, `DF` | `RSI/ESI` |
| `OUTSW` | 32/64 | `RSI/ESI`, `RDX`, `DF` | `RSI/ESI` |
| `OUTSD` | 32/64 | `RSI/ESI`, `RDX`, `DF` | `RSI/ESI` |
| `OUTSQ` | 64 | `RSI`, `RDX`, `DF` | `RSI` |
| `MOVSB` | 32/64 | `RSI`, `RDI`, `DF` | memory, `RSI`, `RDI` |
| `MOVSW` | 32/64 | `RSI`, `RDI`, `DF` | memory, `RSI`, `RDI` |
| `MOVSD` (string) | 32/64 | `RSI`, `RDI`, `DF` | memory, `RSI`, `RDI` |
| `MOVSQ` | 64 | `RSI`, `RDI`, `DF` | memory, `RSI`, `RDI` |
| `STOSB` | 32/64 | `AL`, `RDI`, `DF` | memory, `RDI` |
| `STOSW` | 32/64 | `AX`, `RDI`, `DF` | memory, `RDI` |
| `STOSD` | 32/64 | `EAX`, `RDI`, `DF` | memory, `RDI` |
| `STOSQ` | 64 | `RAX`, `RDI`, `DF` | memory, `RDI` |
| `LODSB` | 32/64 | `RSI`, `DF` | `AL`, `RSI` |
| `LODSW` | 32/64 | `RSI`, `DF` | `AX`, `RSI` |
| `LODSD` | 32/64 | `RSI`, `DF` | `EAX`, `RSI` |
| `LODSQ` | 64 | `RSI`, `DF` | `RAX`, `RSI` |
| `SCASB` | 32/64 | `AL`, `RDI`, `DF` | `RDI`, flags |
| `SCASW` | 32/64 | `AX`, `RDI`, `DF` | `RDI`, flags |
| `SCASD` | 32/64 | `EAX`, `RDI`, `DF` | `RDI`, flags |
| `SCASQ` | 64 | `RAX`, `RDI`, `DF` | `RDI`, flags |
| `CMPSB` | 32/64 | `RSI`, `RDI`, `DF` | `RSI`, `RDI`, flags |
| `CMPSW` | 32/64 | `RSI`, `RDI`, `DF` | `RSI`, `RDI`, flags |
| `CMPSD` (string) | 32/64 | `RSI`, `RDI`, `DF` | `RSI`, `RDI`, flags |
| `CMPSQ` | 64 | `RSI`, `RDI`, `DF` | `RSI`, `RDI`, flags |
| `LOOP` | 32/64 | `RCX/ECX`, flags not used | `RCX/ECX` |
| `LOOPE` / `LOOPZ` | 32/64 | `RCX/ECX`, `ZF` | `RCX/ECX` |
| `LOOPNE` / `LOOPNZ` | 32/64 | `RCX/ECX`, `ZF` | `RCX/ECX` |
| `JECXZ` | 32/64 | `ECX` | none |
| `JCXZ` | 32/64 | `CX` | none |
| `JRCXZ` | 64 | `RCX` | none |
| `CALL rel/abs` | 32/64 | — | `EIP/RIP` + stack; `ESP/RSP` modified; near form writes return address to stack |
| `CALL r/m` | 32/64 | target | `EIP/RIP`, `ESP/RSP`; stack return address |
| `RET` | 32/64 | stack | `EIP/RIP`, `ESP/RSP` |
| `RET imm16` | 32/64 | stack | `EIP/RIP`, `ESP/RSP` |
| `IRET` | 32/64 | stack | `EIP/RIP`, `CS`, `EFLAGS/RFLAGS`, `ESP/RSP`, possibly `SS` |
| `SYSCALL` | 64 | `RCX`, `R11` are architecturally relevant | `RIP`, `RFLAGS`, `RCX`, `R11`, privilege state |
| `SYSRET` | 64 | `RCX`, `R11` | `RIP`, `RFLAGS`, privilege state |
| `SYSENTER` | 32/64 | MSR-defined state | `EIP/RIP`, `CS`, `ESP/RSP` |
| `SYSEXIT` | 32/64 | `ECX`, `EDX` / `RCX`, `RDX` | `EIP/RIP`, `CS`, `ESP/RSP` |
| `CPUID` | 32/64 | `EAX`, `ECX` | `EAX`, `EBX`, `ECX`, `EDX` |
| `RDTSC` | 32/64 | — | `EDX:EAX` |
| `RDTSCP` | 32/64 | — | `EDX:EAX`, `ECX` |
| `RDPMC` | 32/64 | `ECX` | `EDX:EAX` |
| `RDRAND r16/r32/r64` | 32/64 | — | destination; `CF` |
| `RDSEED r16/r32/r64` | 32/64 | — | destination; `CF` |
| `CLAC` | 32/64 | — | `RFLAGS.AC` |
| `STAC` | 32/64 | — | `RFLAGS.AC` |
| `CMC` | 32/64 | `CF` | `CF` |
| `CLC` | 32/64 | — | `CF` |
| `STC` | 32/64 | — | `CF` |
| `CLI` | 32/64 | — | `RFLAGS.IF` |
| `STI` | 32/64 | — | `RFLAGS.IF` |
| `CLD` | 32/64 | — | `RFLAGS.DF` |
| `STD` | 32/64 | — | `RFLAGS.DF` |
| `LAHF` | 32/64 | `SF/ZF/AF/PF/CF` | `AH` |
| `SAHF` | 32/64 | `AH` | `SF/ZF/AF/PF/CF` |
| `PUSHF/PUSHFD/PUSHFQ` | 32/64 | flags | `ESP/RSP` + memory |
| `POPF/POPFD/POPFQ` | 32/64 | stack | flags, `ESP/RSP` |
| `PUSH` | 32/64 | source | `ESP/RSP` + memory |
| `POP` | 32/64 | stack | `ESP/RSP` + destination |
| `ENTER` | 32/64 | `EBP/RBP`, stack | `EBP/RBP`, `ESP/RSP`, memory |
| `LEAVE` | 32/64 | `EBP/RBP` | `ESP/RSP`, `EBP/RBP` |
| `BOUND` | 32 | index register | exception on bounds violation; no normal output |
| `ARPL` | 32 | destination/source | destination, `ZF` |
| `LAR` | 32/64 | segment selector | destination, `ZF` |
| `LSL` | 32/64 | segment selector | destination, `ZF` |
| `LLDT` | 32/64 | source selector | LDTR/system state |
| `LTR` | 32/64 | source selector | TR/system state |
| `LIDT` | 32/64 | memory operand | IDTR |
| `LGDT` | 32/64 | memory operand | GDTR |
| `LMSW` | 32/64 | source | CR0 low bits |
| `SMSW` | 32/64 | — | destination |
| `CLTS` | 32/64 | — | `CR0.TS` |
| `INVLPG` | 32/64 | memory address | TLB state |
| `INVPCID` | 32/64 | descriptor + type | TLB/cache translation state |
| `XGETBV` | 32/64 | `ECX` | `EDX:EAX` |
| `XSETBV` | 32/64 | `ECX`, `EDX:EAX` | XCR state |
| `FXSAVE` | 32/64 | memory, `RSP` alignment requirements | x87/MMX/XMM + MXCSR state to memory; memory side effect |
| `FXRSTOR` | 32/64 | memory | x87/MMX/XMM + MXCSR state |
| `XSAVE*` | 32/64 | `EDX:EAX` mask (variant-dependent) | extended state to memory; memory side effect |
| `XRSTOR*` | 32/64 | `EDX:EAX` mask (variant-dependent) | extended processor state |
| `FSTENV` | 32/64 | x87 env | x87 environment to memory; no GPR clobber |
| `FLDENV` | 32/64 | memory | x87 environment |
| `FNSTENV` | 32/64 | x87 env | x87 environment to memory |
| `FSAVE/FNSAVE` | 32/64 | x87 state | x87 state to memory; may alter x87 state |
| `FRSTOR` | 32/64 | memory | x87 state |
| `FINIT/FNINIT` | 32/64 | — | x87 control/status/tag/IP/DP state |
| `FCLEX/FNCLEX` | 32/64 | — | x87 exception flags |
| `SAHF` | 32/64 | `AH` | flags |
| `FSTSW AX` | 32/64 | x87 status word | `AX` |
| `FNSTSW AX` | 32/64 | x87 status word | `AX` |
| `WAIT` / `FWAIT` | 32/64 | — | x87 exception processing state |
| `PINSRW` | 32/64 | GPR/memory source | XMM/MMX destination |
| `EXTRQ` (MMX/XOP where applicable) | 32/64 | control operands | destination SIMD register |
| `CMPXCHG r/m8` | 32/64 | `AL` | `AL` on success/failure; flags |
| `CMPXCHG r/m16` | 32/64 | `AX` | `AX` on failure; flags |
| `CMPXCHG r/m32` | 32/64 | `EAX` | `EAX` on failure; flags |
| `CMPXCHG r/m64` | 64 | `RAX` | `RAX` on failure; flags |
| `CMPXCHG8B m64` | 32/64 | `EDX:EAX`, `ECX:EBX` | `EDX:EAX` on failure; flags |
| `CMPXCHG16B m128` | 64 | `RDX:RAX`, `RCX:RBX` | `RDX:RAX` on failure; flags |
| `XADD r/m, reg` | 32/64 | source + destination | both operands; flags |
| `XCHG r/m, reg` | 32/64 | both operands | both operands |
| `LOCK`-prefixed RMW instructions | 32/64 | memory + registers | normal destinations; atomic memory side effect |
| `MONITOR` | 32/64 | `EAX/RAX`, `ECX`, `EDX` | monitor address/state |
| `MWAIT` | 32/64 | `EAX`, `ECX` | sleep/monitor state |
| `UMONITOR` | 64 | `RAX` | monitor state |
| `UMWAIT` | 64 | `ECX`, `EDX:EAX` timeout | execution state |
| `TPAUSE` | 64 | `RCX`, `EDX:EAX` | execution state |
| `GETSEC` | 32 | implicit security state | multiple MSRs/system state (feature-dependent) |

## SIMD / FP instructions with implicit GPR or architectural state

| Instruction | 32/64 bit | Implicit input(s) | Clobbered / modified register(s) or state |
|---|---|---|---|
| `LDMXCSR` | 32/64 | memory | `MXCSR` |
| `STMXCSR` | 32/64 | `MXCSR` | memory |
| `FXAM` | 32/64 | x87 top-of-stack | x87 condition codes |
| `FCOMI/FUCOMI` | 32/64 | x87 stack operands | `ZF/PF/CF` |
| `FNCSTSW` | 32/64 | x87 state | `AX` |
| `COMISS/UCOMISS` | 32/64 | XMM sources | `ZF/PF/CF` |
| `COMISD/UCOMISD` | 32/64 | XMM sources | `ZF/PF/CF` |

## Notes for register-liveness / clobber analysis

- **Implicit GPR clobbers:** `MUL`, `IMUL` (one-operand form), `DIV`, `IDIV`, `CPUID`, `RDTSC`, `RDTSCP`, `RDPMC`, string instructions, `CALL`, `RET`, `ENTER`, `LEAVE`, `CMPXCHG8B`, `CMPXCHG16B`.
- **Implicit flag/state clobbers:** many arithmetic/compare instructions modify `RFLAGS`; the table above calls out cases where the flags are themselves the main implicit operand/output.
- `CALL`/`RET` modify the instruction pointer and stack pointer architecturally; the return address is stored/loaded through the stack rather than a hidden GPR on x86.
- `CPUID` is the canonical instruction that clobbers several otherwise unrelated GPRs (`EAX`, `EBX`, `ECX`, `EDX`).
- `RDRAND`/`RDSEED` use the destination register explicitly but also modify `CF` as the success indication.
- `XSAVE*`/`XRSTOR*`, x87 environment/state instructions, and system instructions have architectural state effects beyond ordinary integer/SIMD register liveness.
