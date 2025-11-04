# Label Rename Mapping

**Purpose**: Track all UNREACH_* label renames for systematic refactoring  
**Status**: Planning Phase  
**Last Updated**: November 4, 2025

---

## Overview

This document tracks the renaming of all `UNREACH_*` labels to descriptive names based on disassembly analysis. Each label has been analyzed for:
1. **Reachability** - Whether code is truly unreachable or conditionally reachable
2. **Purpose** - What the code does
3. **Suggested Name** - Descriptive replacement label

---

## Rename Legend

- ✅ **Renamed** - Label has been successfully renamed in all files
- 🔄 **In Progress** - Rename started but not complete
- ⏳ **Pending** - Rename planned but not started
- ❌ **Keep As-Is** - Dead code, keeping UNREACH prefix for clarity

---

## Bank $00 Renames

### Reachable Code (Should be Renamed)

| Old Label | New Label | Status | Category | Line | References |
|-----------|-----------|--------|----------|------|------------|
| `UNREACH_008D93` | `Map_InvalidPositionReturn` | ⏳ Pending | 🟡 Conditional | 4463 | beq at line 4455 |
| `UNREACH_00A2FF` | `Graphics_CommandDispatch_IndexPath` | ✅ Renamed | 🟢 Table-Driven | 6670 | bcc at line 6646 |
| `UNREACH_00AAF7` | `Sprite_DrawDispatchTable` | ⏳ Pending | 🟢 Table-Driven | 9129 | jsr (label,x) at 9099 |
| `UNREACH_00B4BB` | `System_AlternateModeJump` | ⏳ Pending | 🟡 Conditional | 11191 | beq at line 11174 |
| `UNREACH_00B5C2` | `Sprite_AdjustYPosition_Location6B` | ⏳ Pending | 🟡 Conditional | 11438 | beq at line 11415 |
| `UNREACH_00B607` | `Sprite_ClampYMin` | ⏳ Pending | 🟡 Conditional | 11504 | bcc at line 11482 |
| `UNREACH_00B797` | `Menu_InputHandler_YButton_JumpUp` | ⏳ Pending | 🟡 Conditional | 11812 | bne at line 11737 |
| `UNREACH_00B9D5` | `Game_StartNew` | ⏳ Pending | 🟡 Conditional | 12207 | bmi at line 12184 |
| `UNREACH_00B9DB` | `Game_HandleEmptySlot` | ⏳ Pending | 🟡 Conditional | 12225 | beq at line 12188 |
| `UNREACH_00B9E0` | `Game_HandleAlternateButton` | ⏳ Pending | 🟡 Conditional | 12245 | bne at line 12174 |
| `UNREACH_00BA6D` | `CharName_ErrorSound` | ⏳ Pending | 🟡 Conditional | 12324 | 2× beq (lines 12358, 12406) |
| `UNREACH_00BAC2` | `CharName_DeleteCharacter` | ⏳ Pending | 🟡 Conditional | 12395 | bne at line 12349 |

### Dead Code (Keep UNREACH Prefix)

| Old Label | Status | Category | Line | Reason |
|-----------|--------|----------|------|--------|
| `UNREACH_008C81` | ❌ Keep | 🔴 Dead | 4169 | Orphaned function epilogue |
| `UNREACH_008D06` | ❌ Keep | 🔴 Dead | 4309 | Removed graphics code |
| `UNREACH_00A2D4` | ❌ Keep | 🔴 Dead | 6622 | Orphaned initialization |
| `UNREACH_00B76B` | ❌ Keep | 🔴 Dead | 11766 | Duplicate cursor increment |
| `UNREACH_00BDCA` | ❌ Keep | 🔴 Dead | 12852 | Orphaned error sound |

### Undetermined (Need Further Analysis)

| Old Label | Status | Line | Notes |
|-----------|--------|------|-------|
| `UNREACH_00BEC0` | ⏳ Pending | 12977 | Need to analyze call sites |
| `UNREACH_00BED4` | ⏳ Pending | 12989 | Need to analyze call sites |
| `UNREACH_00BEBB` | ⏳ Pending | 13047 | Need to analyze call sites |
| `UNREACH_00BED5` | ⏳ Pending | 13059 | Need to analyze call sites |
| `UNREACH_00BEE5` | ⏳ Pending | 13069 | Need to analyze call sites |
| `UNREACH_00BF1B` | ⏳ Pending | 13102 | Need to analyze call sites |
| `UNREACH_00BFD5` | ⏳ Pending | 13216 | 2× bne references |
| `UNREACH_00C044` | ⏳ Pending | 13290 | 3× bne/beq references |
| `UNREACH_00C064` | ⏳ Pending | 13306 | 1× beq reference |
| `UNREACH_00C095` | ⏳ Pending | 13316 | 2× beq references |
| `UNREACH_00C1EB` | ⏳ Pending | 13517 | Need to analyze call sites |
| `UNREACH_00C20E` | ⏳ Pending | 13535 | 1× bne reference |
| `UNREACH_00C784` | ⏳ Pending | 14292 | 1× beq reference |
| `UNREACH_00C9CB` | ⏳ Pending | 14614 | 1× bne reference |

---

## Cross-Bank References

| Label | Bank | New Name | Notes |
|-------|------|----------|-------|
| `UNREACH_03D5E5` | $03 | TBD | Referenced from Bank $00 at line 6559 |

---

## Rename Strategy

### Phase 1: Documentation Update (Current)
1. ✅ Create this mapping document
2. ⏳ Complete analysis of all remaining UNREACH sections
3. ⏳ Verify reachability of undetermined sections
4. ⏳ Assign descriptive names to all reachable code

### Phase 2: Systematic Renaming
1. Rename labels in source files (bank_00_documented.asm, etc.)
2. Update all references to renamed labels
3. Update analysis comments to remove "Should be renamed" notes
4. Update catalog documentation

### Phase 3: Verification
1. Test ROM build after renames
2. Verify byte-perfect assembly
3. Update documentation with final names
4. Commit changes

---

## Naming Conventions

### Prefixes
- `Map_` - Map/tile coordinate functions
- `Sprite_` - Sprite rendering and positioning
- `Graphics_` - Graphics command processing
- `System_` - System mode and state management
- `Menu_` - Menu navigation and input
- `Game_` - Game flow control (new game, load, etc.)
- `CharName_` - Character naming screen
- `Window_` - Window drawing routines
- `Text_` - Text rendering
- `Anim_` - Animation control

### Suffixes
- `_Handler` - Input or event handlers
- `_Init` - Initialization routines
- `_Update` - Update/refresh routines
- `_Check` - Condition checking
- `_Table` - Data tables or dispatch tables
- `_Helper` - Helper/utility functions

---

## Impact Assessment

### Files to Update
1. `src/asm/bank_00_documented.asm` (primary)
2. `src/asm/bank_00_section4.asm` (secondary)
3. `docs/UNREACHABLE_CODE_CATALOG.md`
4. `docs/UNREACHABLE_CODE_REPORT.md`
5. Any other files with cross-references

### Estimated Effort
- **Phase 1**: 2-3 hours (analysis + planning)
- **Phase 2**: 4-6 hours (systematic renaming)
- **Phase 3**: 1-2 hours (verification)
- **Total**: 8-12 hours

---

## Notes

- Some UNREACH labels are intentionally kept to mark dead code
- Labels in dead code sections retain UNREACH prefix for historical accuracy
- All renamed labels maintain address comments (e.g., `;00A2FF|`)
- Cross-references updated atomically to prevent broken builds
