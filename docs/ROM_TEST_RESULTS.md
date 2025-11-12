# ROM Test Results Documentation
**Date**: 2025-11-12  
**Test ROMs Generated**: 5  
**Status**: ⏳ Awaiting Emulator Testing

---

## Test Overview

**Purpose**: Validate control code behavior hypotheses through empirical ROM testing.

**Test ROMs Location**: `roms/test/`

**Emulator Required**: bsnes-plus or Mesen-S (with debugging features)

---

## Test 1: Formatting Codes (0x1D vs 0x1E)

**ROM**: `test_format_1d_vs_1e.sfc`

**Hypothesis**:
- Code 0x1D formats dictionary entry 0x50
- Code 0x1E formats dictionary entry 0x51
- Both prepare equipment names for display
- Different formatting modes (E1 vs E2)

**Test Dialog**:
```
Test 1D: [0x1D][0x00][0x50]
Test 1E: [0x1E][0x00][0x51]
```

**Expected Behavior**:
- Different visual formatting for equipment names
- May affect spacing, alignment, or character table selection
- Dictionary entries 0x50 and 0x51 should display differently

**Actual Results**: ⏳ *Not yet tested*

**Notes**:


---

## Test 2: Memory Write Operation (0x0E)

**ROM**: `test_memory_write_0e.sfc`

**Hypothesis**:
- Code 0x0E writes 16-bit value to arbitrary memory address
- Parameters: [address_low][address_high][value_low][value_high]
- Critical for dynamic game state modification

**Test Dialog**:
```
Memory write test
[0x0E][0x00][0x01][0xCD][0xAB]  ; Write 0xABCD to address 0x0100
Value written
```

**Expected Behavior**:
- Dialog displays normally
- Memory address 0x0100 contains value 0xABCD after dialog
- No crash or freeze

**Actual Results**: ⏳ *Not yet tested*

**Memory Watch**:
- Address: `0x0100`
- Expected Value: `0xABCD` (or `0xCD 0xAB` in little-endian)

**Notes**:


---

## Test 3: Subroutine Call (0x08)

**ROM**: `test_subroutine_0x08.sfc`

**Hypothesis**:
- Code 0x08 executes dialog fragment at pointer address
- Enables reusable dialog composition
- Returns to caller after fragment completes

**Test Dialog**:
```
Main Dialog:
  Before call: [0x08][addr_low][addr_high]
  After call

Subroutine (at 0x03F100):
  SUBROUTINE TEXT[0x00]
```

**Expected Behavior**:
- Dialog displays: "Before call: SUBROUTINE TEXT"
- Then newline and "After call"
- Confirms nested execution and return

**Actual Results**: ⏳ *Not yet tested*

**Notes**:


---

## Test 4: Equipment Slot Detection (0x10, 0x17, 0x18)

**ROM**: `test_equipment_slots.sfc`

**Hypothesis**:
- Code 0x10: General items (consumables) - broad item table
- Code 0x17: Weapons - specific weapon name table
- Code 0x18: Armor - specific armor name table
- Different codes access different data tables

**Test Dialog**:
```
Item 10: [0x10][0x00]    ; Index 0 from item table
Weapon 17: [0x17][0x00]  ; Index 0 from weapon table
Armor 18: [0x18][0x00]   ; Index 0 from armor table (uses register)
```

**Expected Behavior**:
- Three different item names displayed
- 0x10 shows consumable item
- 0x17 shows weapon name
- 0x18 shows armor name

**Actual Results**: ⏳ *Not yet tested*

**Notes**:


---

## Test 5: Unused Codes (0x15, 0x19)

**ROM**: `test_unused_codes.sfc`

**Hypothesis**:
- Code 0x15: INSERT_NUMBER (never used in game)
- Code 0x19: INSERT_ACCESSORY (never used in game)
- May still be functional but unused
- Could display numbers or accessory names

**Test Dialog**:
```
Before 15
[0x15][0x2A][0x00]  ; Parameter: 42 (0x002A)
After 15
Testing 19
[0x19]              ; Uses registers like 0x18
Complete
```

**Expected Behavior** (3 possibilities):
1. **Functional**: Code 0x15 displays "42", Code 0x19 displays accessory
2. **Non-functional**: Nothing displayed, codes silently ignored
3. **Buggy**: Crash, freeze, or garbage displayed

**Actual Results**: ⏳ *Not yet tested*

**Notes**:


---

## Testing Procedure

### Setup
1. **Emulator**: Download bsnes-plus or Mesen-S
2. **ROM**: Load test ROM from `roms/test/`
3. **Debugger**: Enable CPU debugger and memory viewer
4. **Save States**: Create save state before dialog trigger

### Testing Steps
1. Load test ROM
2. Start new game
3. Observe opening dialog (modified by patch)
4. For memory test (0x0E):
   - Open memory viewer
   - Navigate to address 0x0100
   - Check value after dialog completes
5. Screenshot results
6. Document observations

### Documentation
- Update "Actual Results" sections above
- Add screenshots to `docs/screenshots/`
- Note any unexpected behavior
- Update `CONTROL_CODE_IDENTIFICATION.md` with confirmed findings

---

## Results Summary

**Tests Completed**: 0 / 5

**Hypotheses Confirmed**: 0

**Hypotheses Rejected**: 0

**New Discoveries**: 0

---

## Next Steps

### After Testing
1. Update CONTROL_CODE_IDENTIFICATION.md with confirmed behaviors
2. Create additional tests for remaining unknown codes (0x07-0x0D, 0x20-0x2F)
3. Document any crashes or unexpected behaviors
4. Generate bug reports if needed

### Additional Tests Needed
- [ ] Test unknown codes 0x07, 0x09, 0x0A, 0x0B
- [ ] Test state control codes 0x24-0x28
- [ ] Test external call codes 0x23, 0x29, 0x2B
- [ ] Test conditional code 0x2E
- [ ] Stress test memory write with various addresses
- [ ] Test subroutine nesting depth (multiple 0x08 calls)

---

## Test ROM Specifications

**All test ROMs based on**: Final Fantasy - Mystic Quest (U) (V1.1).sfc

**Modification Method**: Dialog pointer redirection

**Modified Dialog**: Dialog #0 (opening dialog)

**Test Data Location**: ROM address 0x03F000 (safe unused space)

**Backup Recommended**: Yes - keep original ROM separate

---

*Document will be updated after emulator testing*  
*Last Updated*: 2025-11-12
