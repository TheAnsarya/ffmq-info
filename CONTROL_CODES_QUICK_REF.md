# FFMQ Control Code Quick Reference
**Last Updated**: 2025-11-12  
**Status**: 68.7% Identified (33/48 codes)

---

## ✅ FULLY IDENTIFIED (23 codes)

### Basic Operations
```
0x00  END               - Dialog terminator (sets bit 0x80 in $00D0)
0x01  NEWLINE           - Advance to next line
0x02  WAIT              - Wait for user input
0x03  PORTRAIT          - Display NPC portrait (check bit 0x40)
0x04  NAME              - Character name insertion
0x05  ITEM              - Item name from table
0x06  SPACE             - Insert space character (0x20)
```

### Dynamic Insertion (Most Common: 0x10)
```
0x10  INSERT_ITEM_NAME      - Item names (55 uses)
0x11  INSERT_SPELL_NAME     - Spell names (27 uses)
0x12  INSERT_MONSTER_NAME   - Monster names (19 uses)
0x13  INSERT_CHARACTER_NAME - Character names (17 uses)
0x14  INSERT_LOCATION_NAME  - Location names (8 uses)
0x16  INSERT_OBJECT_NAME    - Object names (12 uses)
0x17  INSERT_WEAPON_NAME    - Weapon names (1 use - rare)
0x18  INSERT_ARMOR_NAME     - Armor names (20 uses)
```

### Display Control
```
0x1A  TEXTBOX_BELOW     - Position textbox below (24 uses)
0x1B  TEXTBOX_ABOVE     - Position textbox above (7 uses)
0x1D  FORMAT_ITEM_E1    - Dictionary 0x50 formatting (25 uses)
0x1E  FORMAT_ITEM_E2    - Dictionary 0x51 formatting (10 uses)
0x1F  CRYSTAL           - Crystal reference (2 uses - rare)
```

### CRITICAL CODES 🔥
```
0x08  SUBROUTINE_CALL   - Execute dialog fragment (500+ uses) ⚠️ MOST FREQUENT
      Parameters: 2 bytes (16-bit dialog pointer)
      Enables: Reusable dialog composition

0x0E  MEMORY_WRITE      - Write value to address (100+ uses) ⚠️ CRITICAL
      Parameters: 4 bytes (16-bit address + 16-bit value)
      Enables: Dynamic game state modification
```

---

## 🔍 PARTIALLY IDENTIFIED (10 codes)

### State Control (Likely)
```
0x0F  SET_STATE_1       - 2 parameters (16-bit) → $9E, $A0
0x20  SET_STATE_2       - 1 parameter (8-bit) + subroutine call
0x24  SET_STATE_3       - 4 parameters → $28 + unknown
0x25  SET_STATE_4       - 1 parameter (8-bit) → $1E
0x26  SET_STATE_5       - 4 parameters → $3F + unknown
0x27  SET_STATE_6       - 1 parameter (8-bit) → $27
0x28  SET_STATE_7       - 1 parameter (8-bit) with mode switch
0x2D  SET_STATE_8       - 2 parameters (16-bit) → $2E
```

### External Calls (Likely)
```
0x23  EXTERNAL_CALL_1   - JSL to $009760
0x29  EXTERNAL_CALL_2   - JSL to external routine
0x2B  EXTERNAL_CALL_3   - JSL to $00976B
```

---

## ❓ UNIDENTIFIED (15 codes)

### Priority 1 - Needs Investigation
```
0x07  UNKNOWN (3 params) - Memory read operation
0x09  UNKNOWN (3 params) - Memory read (32 uses)
0x0A  UNKNOWN (no params) - Memory read, likely jump
0x0B  UNKNOWN (no params) - Conditional logic
```

### Priority 2 - Medium
```
0x0C  UNKNOWN (3 params) - Memory R/W
0x0D  UNKNOWN (4 params) - Memory R/W
0x1C  UNKNOWN (no params)
0x20  UNKNOWN (1 param)  - State + subroutine
```

### Priority 3 - Low
```
0x21  UNKNOWN (no params)
0x22  UNKNOWN (no params)
0x2A  UNKNOWN
0x2C  UNKNOWN (2 params)
0x2E  UNKNOWN (1 param)  - Bitfield test
0x2F  UNKNOWN (no params) - Loads constant
```

### Unused Codes
```
0x15  INSERT_NUMBER?    - 0 uses (completely unused)
0x19  INSERT_ACCESSORY? - 0 uses (completely unused)
```

---

## Handler Addresses (ROM)

### Critical Handlers
```
0x00  0x00A378  Dialog_End
0x01  0x00A8C0  Text_CalculateDisplayPosition
0x08  0x00A755  Dialog_ExecuteSubroutine_WithPointer ⚠️
0x0E  0x00A97D  Memory_WriteWordToAddress ⚠️
0x10  0x00AF9A  Dialog_InsertItemName
```

### Jump Table
```
Location: ROM 0x009E0E (SNES 0x009E0E)
Size:     96 bytes (48 word pointers)
Access:   jsr.W (DATA8_009e0e,x)
```

---

## Usage Patterns

### Most Frequent
1. **0x08** (SUBROUTINE): 500+ uses - Dialog composition
2. **0x0E** (MEMORY_WRITE): 100+ uses - Game state
3. **0x01** (NEWLINE): 153 uses
4. **0x05** (ITEM): 74 uses
5. **0x10** (INSERT_ITEM_NAME): 55 uses

### Rarely Used
- **0x17** (WEAPON): 1 use
- **0x1F** (CRYSTAL): 2 uses
- **0x15**, **0x19**: 0 uses (unused)

---

## Parameter Encoding

### 8-bit Parameter
```
Dialog: [CODE] [PARAM]
Read:   lda.B [$17], inc.B $17
        and.W #$00FF
Size:   2 bytes total
```

### 16-bit Parameter
```
Dialog: [CODE] [LOW] [HIGH]
Read:   lda.B [$17], inc.B $17, inc.B $17
Size:   3 bytes total
```

### 32-bit (Address + Value)
```
Dialog: [CODE] [ADDR_L] [ADDR_H] [VAL_L] [VAL_H]
Read:   lda.B [$17] → tax (address)
        lda.B [$17] → sta $0000,x (value)
Size:   5 bytes total
Example: 0x0E (Memory Write)
```

---

## Common Combinations

### Equipment Name Display
```
[0x1D][param] [0x50]  - Format + Dictionary 0x50
[0x1E][param] [0x51]  - Format + Dictionary 0x51
```

### Dialog Fragment Call
```
[0x08][addr_low][addr_high]  - Execute subroutine at address
```

### Item Insertion
```
[0x10][index]  - Insert item name from table
```

---

## Testing Checklist

### Priority Tests
- [ ] 0x0E: Memory write verification
- [ ] 0x08: Subroutine call validation
- [ ] 0x1D vs 0x1E: Formatting difference
- [ ] 0x10 vs 0x17 vs 0x18: Table detection

### Emulator Setup
- Tool: bsnes-plus or Mesen-S (debugging)
- Memory watch: $17 (dialog pointer), $00D0 (flags)
- Breakpoints: Handler addresses

---

## Files Reference

### Documentation
- `docs/CONTROL_CODE_IDENTIFICATION.md` - Complete guide
- `docs/HANDLER_DISASSEMBLY.md` - Full disassembly (1,052 lines)
- `docs/DIALOG_DISASSEMBLY.md` - System overview
- `docs/DYNAMIC_CODES.md` - Dynamic codes (0x10-0x1E)
- `docs/UNKNOWN_CODES_ANALYSIS.md` - Unknown code analysis

### Data
- `data/control_code_handlers.txt` - Address lookup
- `data/extracted_dialogs.json` - All 117 dialogs
- `data/dynamic_code_analysis.txt` - Usage statistics

### Tools
- `tools/analysis/disassemble_dialog_system.py` - Jump table mapper
- `tools/analysis/extract_handler_disassembly.py` - Code extractor
- `tools/analysis/analyze_dynamic_codes.py` - Dynamic analyzer
- `tools/analysis/analyze_unknown_codes.py` - Unknown analyzer

---

**Progress**: 68.7% identified (23 full + 10 partial = 33/48)  
**Next**: ROM testing, unknown code investigation  
**Updated**: 2025-11-12
