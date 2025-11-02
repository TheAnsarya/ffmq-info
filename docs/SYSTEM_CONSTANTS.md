# System Constants - FFMQ Disassembly

**Created**: November 2, 2025  
**Status**: Phase 1 Complete  
**Location**: `src/asm/banks/labels.asm` (System Constants section)

---

## Overview

This document describes the system-level constants added to improve code readability. These constants represent common technical values (bit masks, processor flags, common byte values) rather than game-specific constants.

**Related Files**:
- `src/asm/banks/labels.asm` - System constants (technical/hardware)
- `src/include/ffmq_constants.inc` - Game constants (player stats, items, spells, etc.)

---

## Constant Categories

### Boolean and State Values

| Constant | Value | Description | Usage |
|----------|-------|-------------|-------|
| `FALSE` | `$00` | Boolean false / state off | State flags, boolean checks |
| `TRUE` | `$01` | Boolean true / state on | State flags, boolean checks |
| `INIT_ZERO` | `$00` | Initialize to zero | Clearing registers/memory |

**Examples**:
```asm
; Instead of: LDA #$00
LDA #FALSE              ; Clear state flag
LDA #INIT_ZERO          ; Initialize counter

; Instead of: CMP #$01
CMP #TRUE               ; Check if flag is set
```

---

### Bit Masks (AND/OR/BIT operations)

| Constant | Value | Binary | Description |
|----------|-------|--------|-------------|
| `BIT_0` | `$01` | `00000001` | Bit 0 mask |
| `BIT_1` | `$02` | `00000010` | Bit 1 mask |
| `BIT_2` | `$04` | `00000100` | Bit 2 mask |
| `BIT_3` | `$08` | `00001000` | Bit 3 mask |
| `BIT_4` | `$10` | `00010000` | Bit 4 mask |
| `BIT_5` | `$20` | `00100000` | Bit 5 mask |
| `BIT_6` | `$40` | `01000000` | Bit 6 mask |
| `BIT_7` | `$80` | `10000000` | Bit 7 mask |

**Examples**:
```asm
; Instead of: AND #$80
AND #BIT_7              ; Mask high bit
AND #SIGN_BIT           ; Check sign bit (same as BIT_7)

; Instead of: ORA #$01
ORA #BIT_0              ; Set bit 0

; Instead of: BIT #$20
BIT #BIT_5              ; Test bit 5
```

---

### Processor Status Flag Bits

| Constant | Value | Flag | Description |
|----------|-------|------|-------------|
| `SIGN_BIT` | `$80` | N | Sign/Negative flag (alias for BIT_7) |
| `OVERFLOW_BIT` | `$40` | V | Overflow flag (alias for BIT_6) |
| `CARRY_BIT` | `$01` | C | Carry flag (alias for BIT_0) |
| `ZERO_BIT` | `$02` | Z | Zero flag (alias for BIT_1) |

**Examples**:
```asm
; Instead of: AND #$80
AND #SIGN_BIT           ; Check if result is negative

; Instead of: BIT #$40
BIT #OVERFLOW_BIT       ; Test overflow
```

---

### Processor Status Register (P) Flag Masks

| Constant | Value | Flag | Description |
|----------|-------|------|-------------|
| `P_FLAG_CARRY` | `$01` | C | Carry flag mask |
| `P_FLAG_ZERO` | `$02` | Z | Zero flag mask |
| `P_FLAG_IRQ_DISABLE` | `$04` | I | IRQ disable flag mask |
| `P_FLAG_DECIMAL` | `$08` | D | Decimal mode flag mask |
| `P_FLAG_INDEX_8BIT` | `$10` | X | 8-bit index registers (6502 mode) |
| `P_FLAG_MEM_8BIT` | `$20` | M | 8-bit accumulator/memory |
| `P_FLAG_OVERFLOW` | `$40` | V | Overflow flag mask |
| `P_FLAG_NEGATIVE` | `$80` | N | Negative flag mask |

**SNES Processor Flags**:
- **N** (Negative): Set if result is negative (bit 7 set)
- **V** (Overflow): Set if signed overflow occurred
- **M** (Memory/Accumulator): 0 = 16-bit A, 1 = 8-bit A
- **X** (Index): 0 = 16-bit X/Y, 1 = 8-bit X/Y
- **D** (Decimal): Decimal mode (rarely used on SNES)
- **I** (IRQ Disable): 1 = IRQs disabled
- **Z** (Zero): Set if result is zero
- **C** (Carry): Carry from addition / borrow from subtraction

**Examples**:
```asm
; Instead of: REP #$30
REP #P_FLAG_MEM_8BIT | P_FLAG_INDEX_8BIT    ; 16-bit A/X/Y mode

; Instead of: SEP #$20
SEP #P_FLAG_MEM_8BIT    ; Switch to 8-bit accumulator
```

---

### SNES Register Mode Shortcuts

| Constant | Value | Description |
|----------|-------|-------------|
| `REP_FLAGS_16BIT` | `$30` | REP #$30 - 16-bit A/X/Y mode |
| `SEP_FLAGS_8BIT` | `$30` | SEP #$30 - 8-bit A/X/Y mode |
| `REP_FLAG_ACCUM` | `$20` | REP #$20 - 16-bit accumulator |
| `SEP_FLAG_ACCUM` | `$20` | SEP #$20 - 8-bit accumulator |
| `REP_FLAG_INDEX` | `$10` | REP #$10 - 16-bit index |
| `SEP_FLAG_INDEX` | `$10` | SEP #$10 - 8-bit index |

**Examples**:
```asm
; Instead of: REP #$30
REP #REP_FLAGS_16BIT    ; 16-bit mode for A/X/Y

; Instead of: SEP #$20
SEP #SEP_FLAG_ACCUM     ; Switch to 8-bit accumulator

; Instead of: REP #$20
REP #REP_FLAG_ACCUM     ; Switch to 16-bit accumulator
```

---

### Common Byte and Word Values

| Constant | Value | Description |
|----------|-------|-------------|
| `BYTE_00` | `$00` | Zero byte |
| `BYTE_FF` | `$FF` | All bits set (255) |
| `BYTE_80` | `$80` | High bit set (128 / -128) |
| `WORD_0000` | `$0000` | Zero word |
| `WORD_FFFF` | `$FFFF` | All bits set (65535) |
| `WORD_8000` | `$8000` | High bit set (32768 / -32768) |

**Examples**:
```asm
; Instead of: LDA #$FF
LDA #BYTE_FF            ; Load all bits set

; Instead of: LDX #$0000
LDX #WORD_0000          ; Clear X register
```

---

## Implementation Status

### Phase 1: Core System Constants ✅ COMPLETE
**Date**: November 2, 2025  
**Files Modified**: `src/asm/banks/labels.asm`

**Added Constants** (53 total):
- Boolean/state values: 3 constants (FALSE, TRUE, INIT_ZERO)
- Bit masks: 8 constants (BIT_0 through BIT_7)
- Processor flag bits: 4 constants (SIGN_BIT, OVERFLOW_BIT, etc.)
- P register flags: 8 constants (P_FLAG_CARRY through P_FLAG_NEGATIVE)
- SNES mode shortcuts: 6 constants (REP_FLAGS_16BIT, etc.)
- Common byte values: 3 constants (BYTE_00, BYTE_FF, BYTE_80)
- Common word values: 3 constants (WORD_0000, WORD_FFFF, WORD_8000)

**Build Verification**: ✅ 100% ROM match maintained  
**SHA256**: `F71817F55FEBD32FD1DCE617A326A77B6B062DD0D4058ECD289F64AF1B7A1D05`

---

### Phase 2: Game-Specific Constants (PLANNED)

**Future Enhancements**:
1. **Extract common immediate values** from actual code usage
   - Find frequently used magic numbers: `#$03`, `#$04`, `#$63`, etc.
   - Determine semantic meaning from context
   - Create named constants (e.g., `MAX_PARTY_SIZE`, `MAX_LEVEL`)

2. **Battle system constants**
   - Damage calculation values
   - Status effect IDs
   - Element type IDs

3. **Menu system constants**
   - Menu state IDs
   - Cursor position limits
   - Selection ranges

4. **Graphics constants**
   - Tile sizes
   - Palette sizes
   - VRAM addresses

**Approach**: Incremental, analyze code sections to identify meaningful constants

---

## Usage Guidelines

### When to Use Constants

✅ **DO use constants for**:
- Bit masks and flags (`AND #BIT_7`, `ORA #BIT_0`)
- Processor mode changes (`REP #REP_FLAGS_16BIT`)
- Boolean values (`LDA #TRUE`, `CMP #FALSE`)
- Common initialization (`LDA #INIT_ZERO`)
- Semantic values with clear meaning

❌ **DON'T use constants for**:
- Data tables or lookup values (keep raw hex)
- ROM addresses (already have labels)
- Hardware register addresses (use SNES_* labels)
- Values that change meaning by context
- Single-use magic numbers without clear semantic meaning

### Choosing the Right Constant

**For bit operations**:
```asm
AND #BIT_7              ; Generic bit masking
AND #SIGN_BIT           ; When checking sign specifically
```

**For initialization**:
```asm
LDA #INIT_ZERO          ; When initializing/clearing
LDA #FALSE              ; When setting boolean state
LDA #BYTE_00            ; When $00 is meaningful value (not initialization)
```

**For mode changes**:
```asm
REP #REP_FLAGS_16BIT    ; Standard 16-bit mode
REP #P_FLAG_MEM_8BIT    ; When only changing accumulator size
```

---

## Implementation Notes

### Design Decisions

1. **Location**: Added to `labels.asm` instead of separate file
   - Keeps all constants in one place
   - Follows existing project structure
   - No additional include needed

2. **Naming Convention**: 
   - Uppercase with underscores (CONSTANT_NAME)
   - Descriptive, not abbreviated
   - Consistent with existing SNES_* labels

3. **Organization**:
   - Grouped by category (boolean, bits, flags, etc.)
   - Documented with inline comments
   - Clear header separator

4. **Conservative Approach**:
   - Phase 1 adds only well-understood system constants
   - Phase 2 will analyze actual code usage
   - Avoids over-abstraction

### Future Considerations

**Analysis Tools** (Phase 2):
- Create script to find common immediate values
- Count usage frequency across all banks
- Identify patterns and semantic meaning
- Generate constant definitions automatically

**Documentation**:
- Update this file as new constants added
- Document usage patterns found in code
- Create examples from actual disassembly

---

## References

- **SNES Development Manual**: Processor modes and flags
- **asar Assembler**: Constant definition syntax
- **Project Standards**: `docs/FORMATTING_ANALYSIS.md`
- **Hardware Registers**: `src/asm/banks/labels.asm` (SNES_* section)
- **Game Constants**: `src/include/ffmq_constants.inc`

---

**Last Updated**: November 2, 2025  
**Issue**: #10 - Extract All Game Constants (Phase 1)
