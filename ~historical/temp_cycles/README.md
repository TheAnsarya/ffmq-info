# Temporary Cycle Files Archive

This directory contains 64 temporary assembly files that were created during the aggressive disassembly campaign on October 28-29, 2025.

## Purpose

These files represent intermediate work products from the multi-cycle disassembly process. Each "cycle" was an iterative pass that added more documentation and understanding to specific sections of ROM banks.

## File Naming Convention

- `temp_bank{XX}_cycle{N}.asm` - Regular cycle file
- `temp_bank{XX}_cycle{N}_part{M}.asm` - Multi-part cycle (for large sections)
- `temp_bank{XX}_cycle{N}_final.asm` - Final consolidation cycle
- `temp_bank{XX}_import.asm` - Import files from DiztinGUIsh reference

Where:
- `{XX}` = Bank number in hex (01, 02, 03, 07, 08, 09, 0A, 0F)
- `{N}` = Cycle number (1-24 depending on bank)
- `{M}` = Part number for split cycles

## Status

**All content from these temp files has been successfully merged into the main documented files** in `src/asm/bank_{XX}_documented.asm`.

The temp files are preserved here for historical reference and to document the development process.

## File Distribution

| Bank | Temp Files | Final Cycle | Status |
|------|------------|-------------|--------|
| $01  | 9 files    | cycle11_final | ✅ Merged into bank_01_documented.asm (9,670 lines) |
| $02  | 24 files   | cycle24 | ✅ Merged into bank_02_documented.asm (8,997 lines) |
| $03  | 6 files    | cycle05 | ✅ Merged into bank_03_documented.asm (2,672 lines) |
| $07  | 8 files    | cycle07-08 | ✅ Merged into bank_07_documented.asm (2,647 lines) |
| $08  | 7 files    | cycle06 | ✅ Merged into bank_08_documented.asm (2,156 lines) |
| $09  | 2 files    | cycle02 | ✅ Merged into bank_09_documented.asm (2,083 lines) |
| $0a  | 1 file     | cycle01 | ✅ Merged into bank_0A_documented.asm (2,078 lines) |
| $0f  | 1 file     | cycle01 | ✅ Merged into bank_0F_documented.asm |

Additionally, 8 `*_import.asm` files from the DiztinGUIsh reference integration.

## Methodology

The "cycle" approach allowed for:

1. **Incremental Progress** - Small, manageable chunks of disassembly
2. **Quality Control** - Each cycle reviewed before moving forward
3. **Flexibility** - Could adjust strategy based on what was discovered
4. **Risk Mitigation** - Temp files preserved work if issues arose
5. **Velocity Tracking** - Clear metrics on lines documented per cycle

## Achievement

Through 24 cycles across multiple banks, the team documented **28,303+ lines** of professional-grade assembly code, achieving **100% ROM match** (524,288/524,288 bytes).

## Date Archived

October 30, 2025

---

These files represent a successful aggressive disassembly campaign and serve as a testament to the "don't stop until all banks are done" directive.
