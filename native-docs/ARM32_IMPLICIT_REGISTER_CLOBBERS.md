# ARM32 (A32/T32) — Implicit Register/State Effects

| Instruction | Bits | Implicit read | Implicit clobber/write |
|---|---:|---|---|
| `B` | 32 | PC | PC |
| `B<cond>` | 32 | PC, APSR condition flags | PC |
| `BL` | 32 | PC | LR, PC |
| `BL<cond>` | 32 | PC, APSR condition flags | LR, PC |
| `BLX <label>` | 32 | PC | LR, PC |
| `BLX <Rm>` | 32 | — | LR, PC |
| `BX <Rm>` | 32 | — | PC |
| `CBZ` | 32 | — | PC |
| `CBNZ` | 32 | — | PC |
| `TBB` | 32 | PC | PC |
| `TBH` | 32 | PC | PC |
| `ADR` | 32 | PC | — |
| PC-relative `LDR` | 32 | PC | — |
| `LDM* <Rn>!` | 32 | base register | base register |
| `STM* <Rn>!` | 32 | base register | base register |
| `LDM* {...,pc}` | 32 | base/SP | PC, base/SP if write-back |
| `POP {...,pc}` | 32 | SP | SP, PC |
| `ADC` | 32 | APSR.C | — |
| `ADCS` | 32 | APSR.C | APSR.NZCV |
| `SBC` | 32 | APSR.C | — |
| `SBCS` | 32 | APSR.C | APSR.NZCV |
| `RSC` | 32 | APSR.C | — |
| `RSCS` | 32 | APSR.C | APSR.NZCV |
| `RRX` | 32 | APSR.C | — |
| `CMN` | 32 | — | APSR.NZCV |
| `CMP` | 32 | — | APSR.NZCV |
| `TST` | 32 | — | APSR.NZCV |
| `TEQ` | 32 | — | APSR.NZCV |
| `ADDS` | 32 | — | APSR.NZCV |
| `SUBS` | 32 | — | APSR.NZCV |
| flag-setting logical ops | 32 | — | APSR.NZCV* |
| `QADD`, `QSUB` | 32 | — | APSR.Q |
| `QDADD`, `QDSUB` | 32 | APSR.Q | APSR.Q |
| `SSAT`, `SSAT16` | 32 | APSR.Q | APSR.Q |
| `USAT`, `USAT16` | 32 | APSR.Q | APSR.Q |
| `SEL` | 32 | APSR.GE | — |
| `UADD8`, `UADD16` | 32 | — | APSR.GE |
| `UASX`, `USAX`, `USUB8`, `USUB16` | 32 | — | APSR.GE |
| `QADD8`, `QADD16`, `QASX`, `QSAX` | 32 | — | APSR.Q/GE as defined |
| `QSUB8`, `QSUB16` | 32 | — | APSR.Q/GE as defined |
| `MRS <Rd>, CPSR/APSR` | 32 | CPSR/APSR | — |
| `MRS <Rd>, SPSR` | 32 | SPSR | — |
| `MSR CPSR/APSR, <Rn>` | 32 | explicit source | CPSR/APSR fields |
| `MSR SPSR, <Rn>` | 32 | explicit source | SPSR |
| `MSR CPSR/APSR, #imm` | 32 | — | CPSR/APSR fields |
| `CPS` | 32 | — | CPSR control fields |
| `SETEND` | 32 | — | CPSR.E |
| `LDREX*` | 32 | — | exclusive-monitor state |
| `STREX*` | 32 | exclusive-monitor state | exclusive-monitor state |
| `CLREX` | 32 | exclusive-monitor state | exclusive-monitor state |
| `SVC` | 32 | PC, processor state | exception state, PC |
| `BKPT` | 32 | PC | debug/exception state |
| `UDF` | 32 | PC | exception state, PC |
| `RFE` | 32 | SPSR + memory/stack state | CPSR, PC, SP/base as applicable |

\* Exact N/Z/C/V behavior is instruction-specific; model from the architecture pseudocode rather than treating all logical flag-setting forms identically.

## Notes

- `PC`, `LR`, `SP`, and `APSR/CPSR/SPSR` are architectural state, not ordinary hidden scratch registers.
- `LDM/STM` write-back is implicit when `!` is present.
- `POP {...,pc}` is an alias for an `LDM` form with `SP` write-back and `PC` in the register list.
