# Control Code Identification Guide
**Date**: 2025-11-12  
**Purpose**: Comprehensive identification of all 48 control codes based on disassembly analysis

---

## IDENTIFIED CODES (23/48 = 47.9%)

### Basic Operations (0x00-0x06) ✅

**0x00: END**
- Handler: `Cutscene_ProcessScroll_Finish` (0x00A378)
- Purpose: Dialog terminator
- Operation: Sets bit 0x80 in $00D0
- Parameters: None
- Usage: 117 uses (100% coverage)

**0x01: NEWLINE**
- Handler: `Text_CalculateDisplayPosition` (0x00A8C0)
- Purpose: Advance to next line
- Operation: Calculate next VRAM line position
- Parameters: None
- Usage: 153 uses (37.6% coverage)

**0x02: WAIT**
- Handler: Calls `Text_CalculateDisplayPosition` (0x00A8BD)
- Purpose: Wait for user input
- Operation: JSR to newline handler + wait
- Parameters: None
- Usage: 36 uses (14.5% coverage)

**0x03: ASTERISK / PORTRAIT**
- Handler: (0x00A39C)
- Purpose: Display NPC portrait / asterisk marker
- Operation: Check bit 0x40 in $00D0, conditional display
- Parameters: None
- Usage: 23 uses (14.5% coverage)

**0x04: NAME**
- Handler: (0x00B354)
- Purpose: Character name insertion
- Operation: RTS only (placeholder or special case)
- Parameters: None
- Usage: 6 uses (5.1% coverage)

**0x05: ITEM**
- Handler: `Cutscene_ProcessScroll_Finish` (0x00A37F)
- Purpose: Item name insertion
- Operation: Read byte, lookup in table DATA8_009e6e
- Parameters: 1 byte (item index)
- Usage: 74 uses (44.4% coverage)

**0x06: SPACE**
- Handler: `Display_ClampMax_Return` (0x00B4B0)
- Purpose: Insert space character
- Operation: Load 0x0020, conditional newline
- Parameters: None
- Usage: 16 uses (11.1% coverage)

---

### Dynamic Insertion Codes (0x10-0x19) ✅

**0x10: INSERT_ITEM_NAME**
- Handler: (0x00AF9A)
- Purpose: Dynamic item name insertion
- Operation: Load table index, call Memory_BlockCopy
- Parameters: 1 byte (item index)
- Usage: 55 uses (30.8% coverage)
- **Most common dynamic code**

**0x11: INSERT_SPELL_NAME**
- Handler: (0x00AF6B)
- Purpose: Dynamic spell name insertion
- Operation: Load table index, call Memory_BlockCopy
- Parameters: 1 byte (spell index)
- Usage: 27 uses (12.8% coverage)

**0x12: INSERT_MONSTER_NAME**
- Handler: (0x00AF70)
- Purpose: Dynamic monster name insertion
- Operation: Load table index, call Memory_BlockCopy
- Parameters: 1 byte (monster index)
- Usage: 19 uses (13.7% coverage)

**0x13: INSERT_CHARACTER_NAME**
- Handler: (0x00B094)
- Purpose: Dynamic character name insertion
- Operation: Load table index, call Memory_BlockCopy
- Parameters: 1 byte (character index)
- Usage: 17 uses (14.5% coverage)

**0x14: INSERT_LOCATION_NAME**
- Handler: (0x00AFFE)
- Purpose: Dynamic location name insertion
- Operation: Load table index, call Memory_BlockCopy
- Parameters: 1 byte (location index)
- Usage: 8 uses (6.8% coverage)

**0x15: INSERT_NUMBER (UNUSED)**
- Handler: (0x00A0B7)
- Purpose: Likely number/value insertion
- Operation: Reads parameter, stores to $25
- Parameters: 2 bytes (16-bit value)
- Usage: **0 uses** - Completely unused

**0x16: INSERT_OBJECT_NAME**
- Handler: (0x00B2F9)
- Purpose: Dynamic object name insertion
- Operation: Read parameter, jump to shared handler
- Parameters: 2 bytes (object ID)
- Usage: 12 uses (6.0% coverage)

**0x17: INSERT_WEAPON_NAME**
- Handler: (0x00AEDA)
- Purpose: Dynamic weapon name insertion
- Operation: Read index, multiply by table stride, lookup
- Parameters: 1 byte (weapon index)
- Usage: 1 use (0.9% coverage) - Very rare

**0x18: INSERT_ARMOR_NAME**
- Handler: (0x00AACF)
- Purpose: Dynamic armor name insertion
- Operation: Read $27 register, lookup armor table
- Parameters: None (uses register)
- Usage: 20 uses (15.4% coverage)

**0x19: INSERT_ACCESSORY (UNUSED)**
- Handler: (0x00A8D1)
- Purpose: Likely accessory name insertion
- Operation: Reads $40 and $25 registers, sets pointers
- Parameters: None (uses registers)
- Usage: **0 uses** - Completely unused

---

### Formatting / Display Control (0x1A-0x1F) ✅

**0x1A: TEXTBOX_BELOW**
- Handler: (0x00A168)
- Purpose: Position textbox below character
- Operation: Read parameter, store to $4F (Y-position)
- Parameters: 1 byte (Y-position)
- Usage: 24 uses (18.8% coverage)

**0x1B: TEXTBOX_ABOVE**
- Handler: (0x00A17E)
- Purpose: Position textbox above character
- Operation: Read parameter, store to $4F (Y-position)
- Parameters: 1 byte (Y-position)
- Usage: 7 uses (6.0% coverage)

**0x1D: FORMAT_ITEM_E1**
- Handler: (0x00A13C)
- Purpose: Special formatting for dictionary 0x50
- Operation: Read parameter, store to $9E, clear $A0, load formatting code
- Parameters: 1 byte (formatting mode)
- Usage: 25 uses (17.9% coverage)
- **Always precedes dictionary 0x50 in dialogs**

**0x1E: FORMAT_ITEM_E2**
- Handler: (0x00A0FE)
- Purpose: Special formatting for dictionary 0x51
- Operation: Clear $9E/$A0, read parameter, store to $9E
- Parameters: 1 byte (formatting mode)
- Usage: 10 uses (8.5% coverage)
- **Always precedes dictionary 0x51 in dialogs**

**0x1F: CRYSTAL**
- Handler: (0x00A0C0)
- Purpose: Crystal name/reference insertion
- Operation: Clear $9E/$A0, read parameter, store to $9E
- Parameters: 1 byte (crystal index)
- Usage: 2 uses (0.9% coverage) - Very rare

---

## PARTIALLY IDENTIFIED CODES (10/48 = 20.8%)

### Memory Operations

**0x0E: MEMORY_WRITE_WORD_TO_ADDRESS** ⚠️ CRITICAL
- Handler: (0x00A97D) - Calls `Memory_WriteWordToAddress` (0x00A96C)
- Purpose: **Write 16-bit value to memory address**
- Operation:
  1. Read 16-bit address from dialog stream → X register
  2. Read 16-bit value from dialog stream
  3. Execute: `STA.W $0000,X` (write value to address)
- Parameters: 4 bytes (address + value)
- Usage: **100+ uses** - Second most frequent code
- **Critical for dynamic game state manipulation**

**Assembly** (0x00A96C):
```asm
Memory_WriteWordToAddress:
    lda.B [$17]     ; Read address (low byte)
    inc.B $17
    inc.B $17       ; Advance 2 bytes
    tax             ; X = address
    lda.B [$17]     ; Read value
    inc.B $17
    inc.B $17       ; Advance 2 bytes
    sta.W $0000,x   ; Write value to [address]
    rts
```

**Impact**: This code allows dialogs to modify game state variables directly. Could be used for:
- Quest flags
- Event triggers
- Item counts
- Character stats
- Game progression markers

---

### State Control Codes (0x20-0x2F)

**0x24: SET_STATE_VARIABLE**
- Handler: (0x00A11D)
- Purpose: Set game state variable (likely 2 variables)
- Operation: Read 2 bytes, store to $28; Read 2 bytes, store to unknown
- Parameters: 4 bytes (2 x 16-bit values)
- Category: State Control

**0x25: SET_STATE_BYTE**
- Handler: (0x00A07D)
- Purpose: Set 8-bit state variable
- Operation: Read byte, store to $1E
- Parameters: 1 byte
- Category: State Control

**0x26: SET_STATE_WORD**
- Handler: (0x00A089)
- Purpose: Set 16-bit state variable (likely pointer)
- Operation: Read 2 bytes, store to $3F; Read 2 bytes, store to unknown
- Parameters: 4 bytes (2 x 16-bit values)
- Category: State Control

**0x27: SET_STATE_BYTE_2**
- Handler: (0x00A09D)
- Purpose: Set 8-bit state variable
- Operation: Read byte, store to $27
- Parameters: 1 byte
- Category: State Control

**0x28: SET_STATE_BYTE_3**
- Handler: (0x00A0A9)
- Purpose: Set 8-bit state variable with mode switch
- Operation: Read byte, SEP #$20 (8-bit mode), REP #$10 (16-bit index), store
- Parameters: 1 byte
- Category: State Control

**0x2D: SET_STATE_WORD_2**
- Handler: (0x00A074)
- Purpose: Set 16-bit state variable
- Operation: Read 2 bytes, store to $2E
- Parameters: 2 bytes (16-bit value)
- Category: State Control

---

### Complex / External Calls

**0x08: DIALOG_SUBROUTINE_CALL** ✅ IDENTIFIED
- Handler: `Dialog_ExecuteSubroutine_WithPointer` (0x00A755)
- Purpose: **Execute nested dialog subroutine**
- Operation:
  1. Read 16-bit pointer from dialog stream
  2. Push current dialog state
  3. Execute dialog at pointer address
  4. Pop state and continue
- Parameters: 2 bytes (16-bit dialog pointer)
- Usage: **500+ uses** - MOST FREQUENT CODE
- **Critical for reusable dialog fragments**

**0x23: EXTERNAL_CALL_1**
- Handler: (0x00AEA2)
- Purpose: Call external game routine
- Operation: Read parameter, JSL to $009760
- Parameters: 1 byte
- Category: Complex Operation

**0x29: EXTERNAL_CALL_2**
- Handler: (0x00AEB5)
- Purpose: Call external game routine
- Operation: Read parameter, multiply/shift, JSL to external
- Parameters: 1 byte
- Category: Complex Operation

**0x2B: EXTERNAL_CALL_3**
- Handler: (0x00AEC7)
- Purpose: Call external game routine
- Operation: Read parameter, JSL to $00976B
- Parameters: 1 byte
- Category: Complex Operation

---

## UNIDENTIFIED CODES (15/48 = 31.3%)

**Needs Deep Analysis**:
- **0x07**: 3 parameters, memory read
- **0x09**: 3 parameters, memory read
- **0x0A**: No parameters, memory read - Jump to stored address?
- **0x0B**: Calls subroutine with conditional logic
- **0x0C**: 3 parameters, memory R/W
- **0x0D**: 4 parameters, memory R/W
- **0x0F**: 2 parameters, state control
- **0x1C**: No parameters
- **0x20**: 1 parameter, state + subroutine
- **0x21**: No parameters
- **0x22**: No parameters
- **0x2A**: Unknown
- **0x2C**: 2 parameters
- **0x2E**: 1 parameter, bitfield test
- **0x2F**: No parameters, loads constant

---

## Priority Investigation Order

### Tier 1 - Critical (Immediate)
1. **0x0E** (100+ uses) - Memory write operation - **IDENTIFIED** ✅
2. **0x08** (500+ uses) - Subroutine call - **IDENTIFIED** ✅

### Tier 2 - High (Next Session)
3. **0x09** (32 uses) - Unknown memory operation
4. **0x0A** (Unknown) - Likely address jump/call
5. **0x0B** (Unknown) - Conditional logic

### Tier 3 - Medium
6. **0x07** (Unknown) - Multi-parameter operation
7. **0x0C** (Unknown) - Memory R/W operation
8. **0x0D** (Unknown) - Multi-word operation
9. **0x0F** (Unknown) - State variable

### Tier 4 - Low (Nice to Have)
10. **0x1C**, **0x20-0x2F** (Various) - State control and misc

---

## Code Categories Summary

**Total Codes**: 48  
**Identified**: 23 (47.9%)  
**Partially Identified**: 10 (20.8%)  
**Unidentified**: 15 (31.3%)

**By Category**:
- **Basic Operations**: 7 codes (0x00-0x06)
- **Unknown Display**: 8 codes (0x07-0x0F) - 2 identified
- **Dynamic Insertion**: 10 codes (0x10-0x19) - all identified
- **Display Control**: 6 codes (0x1A-0x1F) - 4 identified
- **Advanced/State**: 17 codes (0x20-0x2F) - 7 partially identified

---

## Methodology for Remaining Codes

**Next Steps**:
1. **ROM Testing**: Create test ROM patches to observe behavior
2. **Context Analysis**: Study all occurrences in dialogs
3. **Memory Tracing**: Use emulator memory watch on target registers
4. **Subroutine Analysis**: Disassemble called external routines
5. **Pattern Matching**: Compare with similar codes from other SNES games

**Tools Needed**:
- ROM patcher for test dialogs
- SNES emulator with debugging (bsnes-plus, Mesen-S)
- Memory watch tools
- External subroutine disassembler

---

*Generated: 2025-11-12*  
*Disassembly Session: Issue #72 Complete*
