# AArch64 (A64) — Implicit Register/State Effects

| Instruction | Bits | Implicit read | Implicit clobber/write |
|---|---:|---|---|
| `B` | 64 | PC | PC |
| `B.<cond>` | 64 | PSTATE.NZCV | PC |
| `BL` | 64 | PC | X30, PC |
| `BR` | 64 | — | PC |
| `BLR` | 64 | — | X30, PC |
| `RET` | 64 | X30 | PC |
| `RETAA` | 64 | X30, SP, pointer-auth state | X30, PC |
| `RETAB` | 64 | X30, SP, pointer-auth state | X30, PC |
| `CBZ` | 64 | — | PC |
| `CBNZ` | 64 | — | PC |
| `TBZ` | 64 | — | PC |
| `TBNZ` | 64 | — | PC |
| `ADR` | 64 | PC | — |
| `ADRP` | 64 | PC | — |
| `LDR (literal)` | 64 | PC | — |
| `ADD` with `SP` operand | 64 | SP | explicit destination |
| `SUB` with `SP` operand | 64 | SP | explicit destination |
| `ADDG` | 64 | tag-control state | explicit destination |
| `SUBG` | 64 | tag-control state | explicit destination |
| `IRG` | 64 | tag-control/random state | explicit destination |
| `ADC` | 64 | PSTATE.C | explicit destination |
| `ADCS` | 64 | PSTATE.C | explicit destination, PSTATE.NZCV |
| `SBC` | 64 | PSTATE.C | explicit destination |
| `SBCS` | 64 | PSTATE.C | explicit destination, PSTATE.NZCV |
| `CSEL` | 64 | PSTATE.NZCV | explicit destination |
| `CSINC` | 64 | PSTATE.NZCV | explicit destination |
| `CSINV` | 64 | PSTATE.NZCV | explicit destination |
| `CSNEG` | 64 | PSTATE.NZCV | explicit destination |
| `CCMP` | 64 | PSTATE.NZCV | PSTATE.NZCV |
| `CCMN` | 64 | PSTATE.NZCV | PSTATE.NZCV |
| `CMP` / `SUBS ..., XZR/WZR` | 64 | — | PSTATE.NZCV |
| `CMN` / `ADDS ..., XZR/WZR` | 64 | — | PSTATE.NZCV |
| `TST` / `ANDS ..., XZR/WZR` | 64 | — | PSTATE.NZCV |
| `FCSEL` | 64 | PSTATE.NZCV | explicit destination |
| `FCMP` / `FCMPE` | 64 | FP operands, FPCR as applicable | PSTATE.NZCV, FPSR as applicable |
| `FCCMP` / `FCCMPE` | 64 | PSTATE.NZCV, FP operands | PSTATE.NZCV, FPSR as applicable |
| `MRS Xt, NZCV` | 64 | PSTATE.NZCV | Xt |
| `MSR NZCV, Xt` | 64 | Xt | PSTATE.NZCV |
| `MRS Xt, FPCR/FPSR` | 64 | FPCR/FPSR | Xt |
| `MSR FPCR/FPSR, Xt` | 64 | Xt | FPCR/FPSR |
| `MRS Xt, <sysreg>` | 64 | system register | Xt |
| `MSR <sysreg>, Xt` | 64 | Xt | system register |
| `LDXR`, `LDAXR`, `LDXP` | 32/64 | — | exclusive-monitor state |
| `STXR`, `STLXR`, `STXP` | 32/64 | exclusive-monitor state | exclusive-monitor state |
| `CLREX` | 32/64 | exclusive-monitor state | exclusive-monitor state |
| `CAS*` | 32/64 | memory/coherence state | memory/coherence state |
| `SWP*` | 32/64 | memory/coherence state | memory/coherence state |
| `LDADD*`, `LDCLR*`, `LDEOR*`, `LDSET*`, `LDSMAX*`, `LDSMIN*`, `LDUMAX*`, `LDUMIN*` | 32/64 | memory/coherence state | memory/coherence state |
| `PACIASP` | 64 | SP, APIAKey | X30 |
| `PACIBSP` | 64 | SP, APIBKey | X30 |
| `AUTIASP` | 64 | SP, APIAKey, X30 | X30 |
| `AUTIBSP` | 64 | SP, APIBKey, X30 | X30 |
| `XPACLRI` | 64 | X30 | X30 |
| `SVC` | 64 | PC, PSTATE | exception state, PC |
| `HVC` | 64 | PC, PSTATE | exception state, PC |
| `SMC` | 64 | PC, PSTATE | exception state, PC |
| `BRK` | 64 | PC, PSTATE | debug/exception state |
| `HLT` | 64 | PC, PSTATE | debug/exception/halting state |
| `ERET` | 64 | ELR_ELx, SPSR_ELx | PC, PSTATE |
| `DMB` | architectural | memory-ordering state | ordering state |
| `DSB` | architectural | memory/system state | ordering state |
| `ISB` | architectural | instruction-stream state | instruction-stream state |
| `LDAR`, `LDAPR` | 32/64 | memory-ordering state | ordering state |
| `STLR`, `STLLR` | 32/64 | memory-ordering state | ordering state |
| `STG`, `STZG`, `ST2G`, `STZ2G`, `STGM`, `STZGM` | 64 | tag state | memory allocation tags |
| `LDG` | 64 | allocation-tag memory | explicit destination |
| `RDFFR` | SVE | FFR | explicit predicate destination |
| `WRFFR` | SVE | explicit predicate source | FFR |
| SME streaming-mode/control instructions | SVE/SME | PSTATE.SM / PSTATE.ZA as defined | PSTATE.SM / PSTATE.ZA |

## Register-specific summary

| State | Implicitly used by |
|---|---|
| `PC` | branches, calls, returns, PC-relative addressing |
| `X30/LR` | `BL`, `BLR`, `PACIASP/B`, `AUTIASP/B`, `RETAA/B` |
| `SP` | SP-relative/control-flow/authentication/tagging instructions where specified |
| `PSTATE.NZCV` | conditional branches, `ADC/SBC`, `CSEL/CS*`, `CCMP/CCMN`, `FCSEL`, FP compares |
| `FPCR/FPSR` | floating-point instructions and explicit system-register accesses |
| exclusive-monitor state | `LDXR/LDAXR/LDXP`, `STXR/STLXR/STXP`, `CLREX` |
| system registers | `MRS/MSR` and extension-specific instructions |
| `FFR` | SVE `RDFFR/WRFFR` and instructions defined to consume/modify it |
| `ZA`, `PSTATE.SM`, `PSTATE.ZA` | SME instructions as defined by the extension |
