# Unreachable Code Catalog

**Purpose**: Comprehensive documentation of all unreachable code sections in Final Fantasy Mystic Quest ROM disassembly.

**Status**: Discovery Phase (In Progress)  
**Last Updated**: November 4, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Statistics Summary](#statistics-summary)
3. [Bank $00 - Core Engine](#bank-00---core-engine)
4. [Bank $01 - Field/Map](#bank-01---fieldmap)
5. [Bank $02 - Battle System](#bank-02---battle-system)
6. [Bank $03 - Graphics/Data](#bank-03---graphicsdata)
7. [Bank $05 - Unknown](#bank-05---unknown)
8. [Bank $06 - Unknown](#bank-06---unknown)
9. [Bank $07 - Unknown](#bank-07---unknown)
10. [Bank $0B - Battle Graphics](#bank-0b---battle-graphics)
11. [Bank $0C - Unknown](#bank-0c---unknown)
12. [Bank $0D - Audio/SPC700](#bank-0d---audiospc700)
13. [Analysis Patterns](#analysis-patterns)
14. [Next Steps](#next-steps)

---

## Overview

This document catalogs all code sections that are marked as unreachable (`UNREACH_*` labels) or represented as data (`db` directives) but may actually be executable code. The goal is to:

1. **Identify** all unreachable sections across all 16 ROM banks
2. **Categorize** by type (dead code, error handlers, table-driven, cross-bank references)
3. **Disassemble** `db` blocks into proper opcodes
4. **Document** purpose and reachability analysis
5. **Verify** completeness for true 100% code disassembly

### Categorization Legend

- 🔴 **Category 1: Truly Unreachable** - Dead code, development leftovers, orphaned functions
- 🟡 **Category 2: Conditionally Reachable** - Edge cases, error paths, rare conditions
- 🟢 **Category 3: Table-Driven Reachable** - Jump table targets, dispatch tables, indirect calls
- 🔵 **Category 4: Cross-Bank References** - Used by other banks, cross-module calls

### Analysis Status

- ⏳ **Pending**: Not yet analyzed
- 🔍 **In Progress**: Currently being disassembled
- ✅ **Complete**: Fully documented and categorized
- ❓ **Unknown**: Requires further investigation

---

## Statistics Summary

| Bank | Total UNREACH Labels | Dead Code | Reachable | % Reachable | Status |
|------|---------------------|-----------|-----------|-------------|--------|
| $00  | 37                  | 9 (24%)   | 28 (76%)  | 75.7%       | ✅     |
| $01  | 4                   | 1 (25%)   | 3 (75%)   | 75.0%       | 🔍     |
| $02  | 33                  | ?         | ?         | ?           | ⏳     |
| $03  | 1                   | ?         | ?         | ?           | ⏳     |
| $05  | 2                   | ?         | ?         | ?           | ⏳     |
| $06  | 2                   | ?         | ?         | ?           | ⏳     |
| $07  | 1                   | ?         | ?         | ?           | ⏳     |
| $0B  | 4                   | ?         | ?         | ?           | ⏳     |
| $0C  | 10                  | ?         | ?         | ?           | ⏳     |
| $0D  | 5                   | ?         | ?         | ?           | ⏳     |
| **TOTAL** | **117**         | **10**    | **31**    | **26.5%**   | 35.0%  |

**Legend**:
- ✅ Complete - All sections analyzed and processed
- 🔍 In Progress - Partial analysis complete
- ⏳ Pending - Not yet analyzed

**Progress**: 41/117 sections processed (35.0%)

---

## Bank $00 - Core Engine

**File**: `src/asm/bank_00_documented.asm`  
**Total Sections**: 37 (28 reachable + 9 dead code)  
**Status**: ✅ **100% Complete** - All sections analyzed, disassembled, and documented

### Summary Statistics
- **Reachable Code**: 28 sections (75.7%) - All disassembled and renamed
- **Dead Code**: 9 sections (24.3%) - All documented with UNREACH prefix
- **Bytes Disassembled**: 129+ bytes across all reachable sections
- **Git Commits**: 5 commits (label renames + dead code marking)

### Reachable Sections (All Renamed ✅)

| Old Label | New Label | Category | Bytes | Purpose |
|-----------|-----------|----------|-------|---------|
| `UNREACH_008D93` | `Map_InvalidPositionReturn` | 🟡 Conditional | 4 | Returns $FFFF for invalid map position |
| `UNREACH_00A2FF` | `Graphics_CommandDispatch_IndexPath` | 🟢 Table-Driven | varies | Graphics command dispatch via index |
| `UNREACH_00AAF7` | `Sprite_DrawDispatchTable` | 🟢 Table-Driven | varies | Sprite draw dispatch table |
| `UNREACH_00B4BB` | `System_AlternateModeJump` | 🟡 Conditional | varies | Alternate system mode handler |
| `UNREACH_00B5C2` | `Sprite_AdjustYPosition_Location6B` | 🟡 Conditional | varies | Y position adjustment for location $6B |
| `UNREACH_00B607` | `Sprite_ClampYMin` | 🟡 Conditional | varies | Clamp Y to minimum value |
| `UNREACH_00B76B` | `Menu_InputHandler_SelectNoWrap` | 🟡 Conditional | 3 | Handle Select button without wrap |
| `UNREACH_00B797` | `Menu_InputHandler_YButton_JumpUp` | 🟡 Conditional | varies | Y button cursor jump |
| `UNREACH_00B7B5` | `Menu_InputHandler_XButton_JumpDown` | 🟡 Conditional | varies | X button cursor jump |
| `UNREACH_00B9D5` | `Game_StartNew` | 🟡 Conditional | varies | Start new game handler |
| `UNREACH_00B9DB` | `Game_HandleEmptySlot` | 🟡 Conditional | varies | Handle empty save slot |
| `UNREACH_00B9E0` | `Game_HandleAlternateButton` | 🟡 Conditional | varies | Alternate button handler |
| `UNREACH_00BA6D` | `CharName_ErrorSound` | 🟡 Conditional | varies | Character naming error sound |
| `UNREACH_00BAC2` | `CharName_DeleteCharacter` | 🟡 Conditional | varies | Delete character in naming |
| `UNREACH_00BFD5` | `Menu_Item_Discard_Cancel` | 🟡 Conditional | 3 | Item discard cancellation |
| `UNREACH_00C044` | `Menu_Spell_ErrorSound` | 🟡 Conditional | 3 | Spell menu error sound |
| `UNREACH_00C064` | `Menu_Spell_Slot0Handler` | 🟡 Conditional | 47 | Special spell slot 0 handler |
| `UNREACH_00C095` | `Menu_Spell_InvalidSpellJump` | 🟡 Conditional | 3 | Invalid spell redirect |
| `UNREACH_00C20E` | `Menu_BattleSettings_YButton` | 🟡 Conditional | 9 | Battle settings Y button |
| `UNREACH_00C784` | `WRAM_SetupSprites_IncrementY2` | 🟡 Conditional | 2 | Y register increment utility |
| `UNREACH_00C9CB` | `SaveData_ChecksumMismatch` | 🟡 Conditional | 3 | Save checksum error handler |

**Note**: Additional 7 reachable sections from initial batch (not listed in original catalog document)

### Dead Code Sections (Documented ❌)

| Label | Address | Bytes | Description |
|-------|---------|-------|-------------|
| `UNREACH_008C81` | $008C81 | 2 | Orphaned function epilogue (PLP, RTS) |
| `UNREACH_008D06` | $008D06 | 11 | Removed graphics code |
| `UNREACH_00A2D4` | $00A2D4 | varies | Orphaned initialization |
| `UNREACH_00BDCA` | $00BDCA | 3 | Orphaned error sound handler (JSR Sprite_SetMode2C) |
| `UNREACH_00BEBB` | $00BEBB | 7 | Orphaned config data (LDA #$0001, TRB $00d8, RTS) |
| `UNREACH_00BED5` | $00BED5 | 5 | Orphaned long call to Bank $0C (PHA, JSL CODE_0C8000) |
| `UNREACH_00BEE5` | $00BEE5 | 25 | Orphaned menu polling handler (complex sequence) |
| `UNREACH_00BF1B` | $00BF1B | 12 | Orphaned cleanup handler (JSR Anim_SetMode10, etc.) |
| `UNREACH_00C1EB` | $00C1EB | 3 | Orphaned error sound (duplicate, JSR Sprite_SetMode2C) |

**All dead code sections verified with no references via grep searches**

---

## Bank $01 - Battle System

**File**: `src/asm/bank_01_documented.asm`  
**Total Sections**: 4 (3 reachable + 1 dead code)  
**Status**: 🔍 **75% Complete** - 3/4 reachable sections processed

### Summary Statistics
- **Reachable Code**: 3 sections (75%) - All disassembled and renamed
- **Dead Code**: 1 section (25%) - Documented with UNREACH prefix
- **Remaining**: 0 sections pending analysis

### Reachable Sections (All Renamed ✅)

| Old Label | New Label | Category | Bytes | Purpose |
|-----------|-----------|----------|-------|---------|
| `UNREACH_01AC7D` | `Battle_CharacterSystemJumpTable` | 🟢 Table-Driven | 76 | 38 function pointers for character system |
| `UNREACH_01B53F` | `BattleAI_SpecialCase` | 🟡 Conditional | 6 | Special case AI handler |
| `UNREACH_01F407` | `Battle_AnimationModeTable` | 🟢 Table-Driven | 8 | Animation mode data table |

### Dead Code Sections (Documented ❌)

| Label | Address | Bytes | Description |
|-------|---------|-------|-------------|
| `UNREACH_01EF3B` | $01EF3B | varies | No references found - orphaned code |

**Note**: Bank $01 has significantly fewer unreachable sections than initially cataloged. Most sections are reachable via table-driven dispatch or conditional branches.

---

## Bank $02 - Battle System (Extended)

**File**: `src/asm/bank_02_documented.asm`  
**Total Unreachable Sections**: 33  
**Status**: ⏳ **Pending Analysis**
- UNREACH_01C659 (line 8754)
- UNREACH_01C69D (line 8801)
- UNREACH_01C8A3 (line 9110)
- UNREACH_01DF46 (line 11313)
- UNREACH_01EC55 (line 13176)
- UNREACH_01EDC2 (line 13351)
- UNREACH_01EE3F (line 13402)
- UNREACH_01EEDA (line 13471)
- UNREACH_01EF3B (line 7717 in documented)
- UNREACH_01F407 (line 8502 in documented)

*(Detailed analysis pending)*

---

## Bank $02 - Battle System

**File**: `src/asm/bank_02_documented.asm`, `src/asm/banks/bank_02.asm`  
**Total Unreachable Sections**: 33

### UNREACH_0282EE (⏳ Pending)
- **Address**: $0282EE
- **File Line**: 410
- **Current Form**: `db $a2,$ac,$d2,$20,$35,$88,$a9,$01,$85,$76,$60`
- **Category**: ❓ Unknown
- **Context**: Immediately after `Battle_DisplayMessage` call
- **Disassembly**:
  ```asm
  UNREACH_0282EE:
      ldx.W #$d2ac                     ; Load X with $D2AC
      jsr.W $8835                      ; Call subroutine
      lda.B #$01                       ; Load A with $01
      sta.B $76                        ; Store to zero page $76
      rts                              ; Return
  ```
- **Analysis Notes**: 
  - Appears to be alternate battle initialization path
  - Sets battle mode flag ($76)
  - Calls display function at $8835

### UNREACH_0293E5 through UNREACH_02EAC6
*(32 additional entries documented in issue #67)*

**Quick Reference List**:
- UNREACH_0282EE (line 410)
- UNREACH_028965 (line 1408)
- UNREACH_02907D (line 2358)
- UNREACH_029215 (line 2502)
- UNREACH_0292A3 (line 2541)
- UNREACH_029354 (line 2593)
- UNREACH_0293E5 (line 1789/2652)
- UNREACH_029572 (line 2040/2863)
- UNREACH_02992E (line 3373) - Jump table target
- UNREACH_029BB7 (line 2603/3789)
- UNREACH_029C1F (line 2674/3850)
- UNREACH_029C67 (line 2712/3886)
- UNREACH_029DC8 (line 2904/4059)
- UNREACH_029EE8 (line 4220)
- UNREACH_02A014 (line 4384)
- UNREACH_02A1BA (line 4533)
- UNREACH_02A1CC (line 4537)
- UNREACH_02A1EB (line 4550) - JSR indirect target
- UNREACH_02A32E (line 3124/4719)
- UNREACH_02A511 (line 4990)
- UNREACH_02A82B (line 5478)
- UNREACH_02A82E (line 5481)
- UNREACH_02A88F (line 5520)
- UNREACH_02A92C (line 3813/5620) - Comment: "Unreachable Error Handler"
- UNREACH_02CA6A (line 6455/6662)
- UNREACH_02D269 (line 4640/6938) - Comment: "Unreachable Code Section"
- UNREACH_02D89B (line 5535/7724) - Comment: "Unreachable Special Case Handler"
- UNREACH_02DBBD (line 6030/8150) - Comment: "Unreachable Alternate Renderer Path"
- UNREACH_02DCD4 (line 6209/8293) - Comment: "Unreachable Alternate Processing Path"
- UNREACH_02DF5B (line 6337/8397)
- UNREACH_02E777 (line 9369)
- UNREACH_02EA9C (line 7434/9876)
- UNREACH_02EAC6 (line 7476/9913)
- UNREACH_02ED90 (line 10363)
- UNREACH_02F33B (line 11116)
- UNREACH_02F46B (line 11293)
- UNREACH_02F510 (line 11388)
- UNREACH_02FA30 (line 11887)

*(Detailed analysis pending)*

---

## Bank $03 - Graphics/Data

**File**: `src/asm/bank_03_documented.asm`  
**Total Unreachable Sections**: 1 (plus large data block)

### UNREACH_03D5E5 (⏳ Pending)
- **Address**: $03D5E5
- **File Line**: 1655
- **Comment**: "Orphaned Jump Table (Development Artifact / Cut Content)"
- **Category**: 🔴 Category 1: Truly Unreachable (Orphaned development data)
- **Analysis Notes**: 
  - Documented as orphaned jump table
  - Likely cut content or development artifact
  - ~1000 lines of unreachable data follow (lines 1200-2200)
  - Comment at line 2282: "Unreachable data catalogued"

*(Detailed analysis of data block pending)*

---

## Bank $05 - Unknown

**File**: `src/asm/bank_05_documented.asm`  
**Total Unreachable Sections**: 2

### Quick Reference List
- UNREACH_05F920 (line 2099)
- UNREACH_05F9FA (line 2131)

*(Detailed analysis pending)*

---

## Bank $06 - Unknown

**File**: `src/asm/bank_06_documented.asm`  
**Total Unreachable Sections**: 2

### Quick Reference List
- UNREACH_06FBC1 (line 2195)
- UNREACH_06FBC3 (line 2198)

*(Detailed analysis pending)*

---

## Bank $07 - Unknown

**File**: `src/asm/bank_07_documented.asm`  
**Total Unreachable Sections**: 1

### UNREACH_07F7C3 (⏳ Pending)
- **Address**: $07F7C3
- **File Line**: 2512
- **Category**: 🔵 Category 4: Cross-Bank References
- **Analysis Notes**: 
  - Referenced by Bank $0B battle system
  - Formation data pointer
  - Actually reachable via cross-bank call

*(Detailed analysis pending)*

---

## Bank $0B - Battle Graphics

**File**: `src/asm/bank_0B_documented.asm`  
**Total Unreachable Sections**: 4

### UNREACH_0B8144 (⏳ Pending)
- **Address**: $0B8144
- **File Line**: 509
- **Current Form**: `db $0f,$2f,$4f,$6f,$8f`
- **Category**: 🟢 Category 3: Table-Driven Reachable
- **Analysis Notes**: 
  - Battle phase graphics address table
  - Located immediately before `InitBattleGraphics` function
  - May be indexed table for graphics loading

### UNREACH_0B8540 (⏳ Pending)
- **Address**: $0B8540
- **File Line**: 1286
- **Category**: 🟢 Category 3: Table-Driven Reachable
- **Analysis Notes**: 
  - Tile stride lookup table (16 modes × 2 bytes)
  - Graphics system related

### UNREACH_0B9385 (⏳ Pending)
- **Address**: $0B9385
- **File Line**: 3192
- **Category**: 🟢 Category 3: Table-Driven Reachable
- **Analysis Notes**: 
  - Battlefield background graphics pointer table

### UNREACH_0BEB4C (⏳ Pending)
- **Address**: $0BEB4C
- **File Line**: 3160 (banks/bank_0B.asm)
- **Category**: ❓ Unknown

### Dead Code - Unreachable RTS
- **Addresses**: $0B92B0, $0B92D5
- **Category**: 🔴 Category 1: Truly Unreachable
- **Analysis Notes**: Dead code sections

*(Detailed analysis pending)*

---

## Bank $0C - Unknown

**File**: `src/asm/bank_0C_documented.asm`  
**Total Unreachable Sections**: 10

### UNREACH_0CD500 & UNREACH_0CD501 (⏳ Pending)
- **Addresses**: $0CD500, $0CD501
- **File Lines**: 3354, 3357 (banks/bank_0C.asm)
- **Category**: 🔵 Category 4: Cross-Bank References
- **Analysis Notes**: 
  - Referenced by Bank $07
  - Cross-bank data access

### Quick Reference List
- UNREACH_0C83E8 (line 772)
- UNREACH_0C9885 (line 2336 in banks/)
- UNREACH_0CD500 (line 3354 in banks/)
- UNREACH_0CD501 (line 3357 in banks/)
- UNREACH_0CD666 (line 3387 in banks/)
- UNREACH_0CD667 (line 3390 in banks/)
- UNREACH_0CF425 (line 4087)
- UNREACH_0CF715 (line 4147)
- UNREACH_0CF716 (line 4149)
- UNREACH_0CF717 (line 4151)

*(Detailed analysis pending)*

---

## Bank $0D - Audio/SPC700

**File**: `src/asm/bank_0D_documented.asm`  
**Total Unreachable Sections**: 5

### UNREACH_0D8175 (⏳ Pending)
- **Address**: $0D8175
- **File Line**: 652
- **Category**: 🟡 Category 2: Conditionally Reachable
- **Analysis Notes**: 
  - Advanced audio command handler
  - May be triggered by specific music/SFX events

### UNREACH_0DBDAE, 0DBDAF, 0DBDB0 (⏳ Pending)
- **Addresses**: $0DBDAE, $0DBDAF, $0DBDB0
- **File Lines**: 1851, 1852, 1853
- **Comments**: "Unknown table entry", "More entries"
- **Category**: ❓ Unknown
- **Analysis Notes**: 
  - Data pointer tables
  - Post-padding lookup tables (comment: "UNREACHABLE DATA - Post-Padding Lookup Tables")

### UNREACH_0DBEA1 (⏳ Pending)
- **Address**: $0DBEA1
- **File Line**: 1915
- **Comment**: "Pattern map 0 (empty)"
- **Category**: 🟢 Category 3: Table-Driven Reachable
- **Analysis Notes**: 
  - Channel pattern assignment tables
  - Audio pattern data

*(Detailed analysis pending)*

---

## Analysis Patterns

### Pattern Types Identified

1. **Jump Table Targets** (🟢 Category 3)
   - Example: `UNREACH_02992E` - `jmp.W` indirect target
   - May be reachable through dispatch tables

2. **Indirect JSR Targets** (🟢 Category 3)
   - Example: `UNREACH_02A1EB` - `jsr.W` indirect target
   - Function pointer tables

3. **Conditional Branches** (🟡 Category 2)
   - Example: `UNREACH_0282EE`, `UNREACH_028965`
   - Error paths, edge case handlers

4. **Data Tables** (🟢 Category 3)
   - Examples: `UNREACH_0DBDAE` series, `UNREACH_0B8144`
   - Lookup tables, pointer tables

5. **Cross-Bank References** (🔵 Category 4)
   - Example: `UNREACH_07F7C3` (Bank $0B → Bank $07)
   - Example: `UNREACH_0CD500` (Bank $07 → Bank $0C)
   - Inter-module calls

6. **Dead Code** (🔴 Category 1)
   - Example: Unreachable RTS at `$0B92B0`, `$0B92D5`
   - Example: `UNREACH_03D5E5` (orphaned jump table)

### Common `db` Patterns That Are Code

- `$28, $60` → `plp; rts` (function epilogue)
- `$a2, $ff, $ff, $60` → `ldx #$ffff; rts` (error return)
- `$a9, $XX, $9d, $XX, $XX` → `lda #$XX; sta $XXXX,X` (indexed store)
- `$eb` → `xba` (accumulator exchange)
- `$80, $XX` → `bra $XX` (branch always)

---

## Next Steps

### Phase 1: Discovery & Cataloging (Current)
- [x] Create this catalog document
- [x] Scan all 16 bank files for `UNREACH_*` labels (117 found)
- [ ] Read context around each unreachable section
- [ ] Document surrounding code and potential call sites
- [ ] Identify cross-references between banks

### Phase 2: Analysis & Classification
- [ ] Categorize each section (Categories 1-4)
- [ ] Identify `db` blocks that should be code
- [ ] Trace jump tables and indirect calls
- [ ] Cross-reference with FFMQ community research

### Phase 3: Disassembly
- [ ] Disassemble each `UNREACH_*` section
- [ ] Replace `db` directives with proper opcodes
- [ ] Add descriptive comments
- [ ] Rename labels where purpose is clear

### Phase 4: Documentation
- [ ] Complete all entries in this catalog
- [ ] Create `UNREACHABLE_CODE_REPORT.md` with statistics
- [ ] Add header comments to each ASM section
- [ ] Update bank documentation headers

### Phase 5: Verification
- [ ] Test ROM build after each change
- [ ] Verify byte-perfect match
- [ ] Document any discoveries
- [ ] Update `.diz` file if needed

---

## References

- **Related Issue**: GitHub Issue #67
- **Related Files**: 
  - `src/asm/bank_*.asm` (all bank files)
  - `src/asm/banks/bank_*.asm` (alternate versions)
- **External Resources**:
  - 65816 Opcode Reference: https://wiki.superfamicom.org/65816-reference
  - FFMQ Community Research: [TBD]

---

**Document Status**: 🔍 Discovery Phase - Initial catalog created, detailed analysis in progress
