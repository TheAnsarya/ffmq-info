# Manual Testing Tasks - User Action Required

**Generated**: 2025-11-12  
**Purpose**: Comprehensive list of all manual tasks requiring emulator testing, ROM validation, and user verification  
**Status**: 📋 Ready for User Action

---

## Overview

This document lists ALL manual tasks that require user action through emulator testing, ROM editors, or visual verification. These tasks cannot be automated and require human judgment, observation, and documentation.

**Task Categories**:
1. **Test ROM Validation** - 5 test ROMs requiring emulator testing
2. **VRAM Graphics Verification** - Visual sprite/tile verification
3. **Character Encoding Validation** - Text system verification
4. **Build System Testing** - ROM assembly and patching verification
5. **Editor Tool Testing** - Interactive tool validation
6. **Documentation Updates** - Recording test results

**Total Tasks**: 25+ manual verification tasks

---

## Priority 1: Test ROM Validation (CRITICAL)

### Context
5 test ROMs were generated to validate control code behavior hypotheses. Each ROM patches dialog #0 with test scenarios. **These have NOT been tested yet** and are critical for confirming control code documentation accuracy.

**Location**: `roms/test/*.sfc`  
**Documentation**: `docs/ROM_TEST_RESULTS.md` (awaiting results)  
**Emulator Required**: bsnes-plus or Mesen-S (with debugging features)

---

### Task 1.1: Test Formatting Codes (0x1D vs 0x1E)

**ROM**: `roms/test/test_format_1d_vs_1e.sfc`

**Hypothesis**:
- Code 0x1D formats dictionary entry 0x50
- Code 0x1E formats dictionary entry 0x51
- Both prepare equipment names for display
- Different formatting modes (E1 vs E2)

**Testing Procedure**:
1. Load `test_format_1d_vs_1e.sfc` in emulator
2. Start new game
3. Observe opening dialog (modified by patch)
4. Compare visual formatting of two dictionary entries
5. Screenshot both formatted outputs
6. Note any spacing, alignment, or character differences

**Expected Behavior**:
- Different visual formatting for equipment names
- May affect spacing, alignment, or character table selection
- Dictionary entries 0x50 and 0x51 should display differently

**Document Results In**: `docs/ROM_TEST_RESULTS.md` - Test 1 section

**Success Criteria**:
- [ ] ROM boots successfully
- [ ] Dialog displays without crashes
- [ ] Visual differences noted and documented
- [ ] Screenshots saved to `docs/screenshots/`
- [ ] Results confirm or reject hypothesis

---

### Task 1.2: Test Memory Write Operation (0x0E)

**ROM**: `roms/test/test_memory_write_0e.sfc`

**Hypothesis**:
- Code 0x0E writes 16-bit value to arbitrary memory address
- Parameters: [address_low][address_high][value_low][value_high]
- Critical for dynamic game state modification

**Testing Procedure**:
1. Load `test_memory_write_0e.sfc` in emulator
2. Open memory viewer/debugger
3. Add memory watch at address `0x0100`
4. Create save state BEFORE starting new game
5. Start new game and observe dialog
6. Check memory address `0x0100` value after dialog
7. Verify value is `0xABCD` (or `0xCD 0xAB` in little-endian)

**Expected Behavior**:
- Dialog displays: "Memory write test" followed by "Value written"
- Memory address `0x0100` contains value `0xABCD` after dialog
- No crash or freeze

**Memory Watch Configuration**:
- Address: `$0100` (or `$000100`)
- Size: 2 bytes (16-bit)
- Expected Value: `0xABCD` or `0xCD 0xAB` (check byte order)

**Document Results In**: `docs/ROM_TEST_RESULTS.md` - Test 2 section

**Success Criteria**:
- [ ] ROM boots successfully
- [ ] Dialog displays correctly
- [ ] Memory address `0x0100` contains expected value
- [ ] No crashes or unexpected behavior
- [ ] Hypothesis confirmed or rejected
- [ ] Screenshots of memory viewer saved

---

### Task 1.3: Test Subroutine Call (0x08)

**ROM**: `roms/test/test_subroutine_0x08.sfc`

**Hypothesis**:
- Code 0x08 executes dialog fragment at pointer address
- Enables reusable dialog composition
- Returns to caller after fragment completes

**Testing Procedure**:
1. Load `test_subroutine_0x08.sfc` in emulator
2. Start new game
3. Observe opening dialog (modified by patch)
4. Verify dialog displays in correct sequence:
   - "Before call: "
   - "SUBROUTINE TEXT"
   - Newline
   - "After call"
5. Confirm nested execution and return behavior

**Expected Behavior**:
- Dialog displays: "Before call: SUBROUTINE TEXT"
- Then newline and "After call"
- Confirms nested execution and return from subroutine
- No infinite loops or crashes

**Document Results In**: `docs/ROM_TEST_RESULTS.md` - Test 3 section

**Success Criteria**:
- [ ] ROM boots successfully
- [ ] Dialog displays in correct sequence
- [ ] Subroutine executes and returns properly
- [ ] No crashes or infinite loops
- [ ] Hypothesis confirmed
- [ ] Screenshots saved

---

### Task 1.4: Test Equipment Slot Detection (0x10, 0x17, 0x18)

**ROM**: `roms/test/test_equipment_slots.sfc`

**Hypothesis**:
- Code 0x10: General items (consumables) - broad item table
- Code 0x17: Weapons - specific weapon name table
- Code 0x18: Armor - specific armor name table
- Different codes access different data tables

**Testing Procedure**:
1. Load `test_equipment_slots.sfc` in emulator
2. Start new game
3. Observe dialog displaying three item names:
   - Item name from code 0x10 (index 0 from item table)
   - Weapon name from code 0x17 (index 0 from weapon table)
   - Armor name from code 0x18 (index 0 from armor table)
4. Verify three DIFFERENT names are displayed
5. Note which item appears for each code

**Expected Behavior**:
- Three different item names displayed
- 0x10 shows consumable item (e.g., "Cure Potion")
- 0x17 shows weapon name (e.g., "Steel Sword")
- 0x18 shows armor name (e.g., "Iron Armor")

**Document Results In**: `docs/ROM_TEST_RESULTS.md` - Test 4 section

**Success Criteria**:
- [ ] ROM boots successfully
- [ ] Three different item names displayed
- [ ] Each code accesses different table confirmed
- [ ] Item names documented
- [ ] Hypothesis confirmed
- [ ] Screenshots saved

---

### Task 1.5: Test Unused Codes (0x15, 0x19)

**ROM**: `roms/test/test_unused_codes.sfc`

**Hypothesis**:
- Code 0x15: INSERT_NUMBER (never used in game)
- Code 0x19: INSERT_ACCESSORY (never used in game)
- May still be functional but unused
- Could display numbers or accessory names

**Testing Procedure**:
1. Load `test_unused_codes.sfc` in emulator
2. Start new game
3. Observe dialog behavior
4. Note what happens when 0x15 and 0x19 execute
5. Watch for three possible outcomes:
   - **Functional**: Code 0x15 displays "42", Code 0x19 displays accessory
   - **Non-functional**: Nothing displayed, codes silently ignored
   - **Buggy**: Crash, freeze, or garbage displayed

**Expected Behavior** (3 possibilities):
1. **Best case**: Codes work as expected (number and accessory displayed)
2. **Likely case**: Codes silently ignored (nothing displayed)
3. **Worst case**: ROM crashes or displays garbage

**Document Results In**: `docs/ROM_TEST_RESULTS.md` - Test 5 section

**Success Criteria**:
- [ ] ROM boots successfully
- [ ] Behavior of code 0x15 documented
- [ ] Behavior of code 0x19 documented
- [ ] No permanent damage to save file (if crashes)
- [ ] Results inform future control code usage
- [ ] Screenshots saved

---

## Priority 2: VRAM Graphics Verification (HIGH)

### Context
Graphics extraction tools have extracted sprite/tile data from ROM, but **tile arrangements and palettes are GUESSED**. Manual verification against emulator VRAM viewer is required to confirm extracted graphics match actual game display.

**Location**: `assets/graphics/*.png`  
**Documentation**: `tools/extraction/VRAM_ANALYSIS_README.md`  
**Emulator Required**: Mesen-S, Snes9x, or bsnes-plus (with VRAM viewer)

---

### Task 2.1: Verify Character Sprite Tiles

**Extracted Files**:
- `assets/graphics/benjamin_tiles.png` (128×256px, 512 tiles)
- `assets/graphics/kaeli_tiles.png` (128×128px, 256 tiles)
- `assets/graphics/tristam_tiles.png` (128×128px, 256 tiles)
- `assets/graphics/phoebe_tiles.png` (128×128px, 256 tiles)
- `assets/graphics/reuben_tiles.png` (128×128px, 256 tiles)

**Testing Procedure**:
1. Run FFMQ in emulator (Mesen-S recommended)
2. Start new game and reach gameplay
3. Open VRAM viewer (Tools → VRAM Viewer in Mesen-S)
4. Walk character in all 4 directions
5. Take screenshots of VRAM during walking animations
6. Compare extracted tile images with VRAM viewer display
7. Verify colors match (palette verification)
8. Identify actual tile indices for sprite animations

**Verification Questions**:
- [ ] Do extracted tiles match VRAM viewer display?
- [ ] Are colors correct (palette matches)?
- [ ] Are tiles in correct 4bpp format?
- [ ] Can you identify walking animation tile sequences?
- [ ] Can you identify battle pose tiles?
- [ ] Are there any missing or corrupted tiles?

**Document Results In**: `tools/extraction/VRAM_ANALYSIS_README.md` - Step 2 section

**Success Criteria**:
- [ ] All 5 character sprite sheets verified
- [ ] Tile index mapping documented
- [ ] Color/palette issues noted (if any)
- [ ] Screenshots saved to `docs/screenshots/vram/`
- [ ] Actual sprite layouts documented in JSON format

---

### Task 2.2: Verify Character Portrait Tiles

**Extracted Files**:
- `assets/graphics/benjamin_portrait_tiles.png` (128×16px, 32 tiles)
- `assets/graphics/kaeli_portrait_tiles.png` (128×16px, 32 tiles)
- `assets/graphics/tristam_portrait_tiles.png` (128×16px, 32 tiles)
- `assets/graphics/phoebe_portrait_tiles.png` (128×16px, 32 tiles)
- `assets/graphics/reuben_portrait_tiles.png` (128×16px, 32 tiles)

**Testing Procedure**:
1. Load game and reach overworld map
2. Open VRAM viewer
3. Observe character portraits on map
4. Take screenshots of portrait tiles in VRAM
5. Compare with extracted portrait PNG files
6. Verify 8×8 tile portraits are correct

**Document Results In**: `tools/extraction/VRAM_ANALYSIS_README.md` - Step 2 section

**Success Criteria**:
- [ ] All 5 portrait tile sheets verified
- [ ] Portraits match in-game display
- [ ] Tile indices confirmed
- [ ] Screenshots saved

---

### Task 2.3: Document Sprite Layout Mappings

**Purpose**: Create accurate sprite layout JSON files for sprite assembly tool

**Testing Procedure**:
1. Using VRAM viewer observations, document actual tile layouts
2. Create sprite mapping JSON file like:
   ```json
   {
     "benjamin": {
       "standing_front": {
         "tiles": [12, 13, 28, 29],
         "width": 2,
         "height": 2,
         "palette": 0
       },
       "walking_front_frame1": {
         "tiles": [14, 15, 30, 31],
         "width": 2,
         "height": 2,
         "palette": 0
       }
     }
   }
   ```
3. Document all animation frames for each character
4. Document all 4 walking directions
5. Document battle poses

**Document Results In**: Create new file `data/graphics/sprite_layouts.json`

**Success Criteria**:
- [ ] Complete sprite layout JSON created
- [ ] All character animations documented
- [ ] Tile indices verified against VRAM
- [ ] Palette information included
- [ ] Documentation updated in VRAM_ANALYSIS_README.md

---

## Priority 3: Character Encoding Validation (HIGH)

### Context
User indicated: "sometimes `*` in a table means ` ` (space)" and there are TWO text systems (simple and complex). Character encoding tables need manual verification against ROM data and in-game display.

**Files to Verify**:
- `simple.tbl` - Simple text character mappings
- `complex.tbl` - DTE (Dual Tile Encoding) mappings
- Dictionary entries in `data/text/dictionary.json`

---

### Task 3.1: Verify Simple Character Table (simple.tbl)

**Testing Procedure**:
1. Open `simple.tbl` in text editor
2. Extract sample monster names using extraction tool:
   ```powershell
   python tools/extraction/extract_simple_text.py --category monsters --output test_monsters.txt
   ```
3. Load FFMQ in emulator
4. View monster names in-game (battle screen or bestiary)
5. Compare extracted names with in-game display
6. Verify character mappings (especially special characters)
7. **CRITICAL**: Verify if `*` means ` ` (space) or if space is 0xFF

**Specific Verifications**:
- [ ] Verify space character encoding (0xFF vs `*`)
- [ ] Verify letter mappings (A-Z, a-z)
- [ ] Verify number mappings (0-9)
- [ ] Verify punctuation (., !, ?, ', etc.)
- [ ] Verify special characters (™, ♪, etc.)
- [ ] Document any incorrect mappings

**Document Results In**: Create `docs/CHARACTER_ENCODING_VERIFICATION.md`

**Success Criteria**:
- [ ] All character mappings verified
- [ ] Space character encoding confirmed
- [ ] Incorrect mappings documented and fixed
- [ ] simple.tbl updated if needed
- [ ] Test extraction verified to match game

---

### Task 3.2: Verify Complex Text Table (complex.tbl)

**Testing Procedure**:
1. Open `complex.tbl` in text editor
2. Extract sample dialogs using extraction tool:
   ```powershell
   python tools/extraction/extract_dialogs.py --dialog 0 --output test_dialog.txt
   ```
3. Load FFMQ in emulator
4. View opening dialog in game
5. Compare extracted text with in-game display
6. Verify DTE (Dual Tile Encoding) mappings
7. Check for trailing spaces in DTE entries (e.g., `0x41` = "the ")

**Specific Verifications**:
- [ ] Verify common DTE pairs ("the ", "and ", "you ", etc.)
- [ ] Verify trailing spaces are included in mappings
- [ ] Check ambiguous mappings (e.g., 0x5C)
- [ ] Document incorrect DTE mappings
- [ ] Test dialog extraction accuracy

**Document Results In**: `docs/CHARACTER_ENCODING_VERIFICATION.md`

**Success Criteria**:
- [ ] All DTE mappings verified
- [ ] Trailing spaces confirmed in mappings
- [ ] Incorrect mappings fixed in complex.tbl
- [ ] Dialog extraction matches game display
- [ ] Updated complex.tbl tested

---

### Task 3.3: Verify Dictionary Entries

**Testing Procedure**:
1. Review `data/text/dictionary.json`
2. Cross-reference dictionary entries with dialog extraction
3. Test dictionary-compressed dialogs in emulator
4. Verify decompression is accurate
5. Check for any missing or incorrect dictionary entries

**Document Results In**: `docs/CHARACTER_ENCODING_VERIFICATION.md`

**Success Criteria**:
- [ ] Dictionary entries verified
- [ ] Decompression tested and accurate
- [ ] No missing entries found
- [ ] Dictionary documented

---

## Priority 4: Build System Testing (MEDIUM)

### Context
ROM build system assembles source files into working ROM. Build verification and testing workflows need manual execution and validation.

---

### Task 4.1: Test Full Build Pipeline

**Testing Procedure**:
1. Clean build environment:
   ```powershell
   make clean
   # or
   .\build.ps1 -Clean
   ```
2. Run full build:
   ```powershell
   make build
   # or
   .\build.ps1
   ```
3. Verify build completes without errors
4. Check ROM size is correct (2MB = 2,097,152 bytes)
5. Verify ROM header checksum
6. Load ROM in emulator and test basic functionality:
   - ROM boots to title screen
   - New game starts successfully
   - Gameplay works normally
   - Save/load functions work

**Success Criteria**:
- [ ] Build completes without errors
- [ ] ROM size is exactly 2,097,152 bytes
- [ ] Checksum is valid
- [ ] ROM boots in emulator
- [ ] Title screen displays correctly
- [ ] New game starts
- [ ] Basic gameplay tested (walk around, battle, save)
- [ ] No crashes or freezes

**Document Results In**: `docs/BUILD_TEST_RESULTS.md` (create new file)

---

### Task 4.2: Test ROM Comparison Tool

**Testing Procedure**:
1. Build ROM from source
2. Compare with original ROM:
   ```powershell
   python tools/build/compare_roms.py roms/ffmq-original.sfc roms/ffmq_rebuilt.sfc
   ```
3. Review difference report
4. Verify expected differences (if any modifications made)
5. Confirm no unexpected differences

**Success Criteria**:
- [ ] Comparison tool runs without errors
- [ ] Difference report generated
- [ ] All differences explained
- [ ] No unexpected byte changes
- [ ] Report saved

**Document Results In**: `docs/BUILD_TEST_RESULTS.md`

---

### Task 4.3: Test Patch Application

**Testing Procedure**:
1. Create test patch (if not already created)
2. Apply patch to original ROM:
   ```powershell
   python tools/build/apply_patch.py roms/ffmq-original.sfc patches/test_patch.ips roms/ffmq_patched.sfc
   ```
3. Load patched ROM in emulator
4. Verify patch was applied correctly
5. Test patched functionality works as expected

**Success Criteria**:
- [ ] Patch applies without errors
- [ ] Patched ROM loads in emulator
- [ ] Modifications work as intended
- [ ] No unintended side effects
- [ ] Patch documented

**Document Results In**: `docs/BUILD_TEST_RESULTS.md`

---

### Task 4.4: Test Make Targets

**Testing Procedure**:
1. Test each make target individually:
   ```powershell
   make test          # Full testing (validation + emulator)
   make test-rom      # ROM validation only
   make test-setup    # Setup emulator integration
   make test-launch   # Launch in MesenS
   make test-debug    # Launch with debugging
   ```
2. Verify each target works as expected
3. Document any errors or issues
4. Test PowerShell equivalents:
   ```powershell
   .\ffmq-tasks.ps1 -Task test
   ```

**Success Criteria**:
- [ ] `make test` runs successfully
- [ ] `make test-rom` validates ROM
- [ ] `make test-setup` configures emulator
- [ ] `make test-launch` opens emulator with ROM
- [ ] `make test-debug` opens debugger
- [ ] PowerShell tasks work equivalently
- [ ] All errors documented

**Document Results In**: `docs/BUILD_TEST_RESULTS.md`

---

## Priority 5: Editor Tool Testing (MEDIUM)

### Context
Interactive editing tools have been created for enemy editing, dialog editing, and data modification. These tools require manual testing with actual user workflows.

---

### Task 5.1: Test Enemy Editor

**Tool**: `enemy_editor.bat` (GUI editor)

**Testing Procedure**:
1. Launch enemy editor:
   ```powershell
   .\enemy_editor.bat
   ```
2. Load ROM
3. Select an enemy (e.g., Enemy #0: Brownie)
4. Modify stats (HP, attack, defense, etc.)
5. Save changes
6. Rebuild ROM
7. Test in emulator:
   - Battle modified enemy
   - Verify stat changes are applied
   - Check for any bugs or crashes

**Test Scenarios**:
- [ ] Modify enemy HP and verify in battle
- [ ] Change enemy attack power and test damage
- [ ] Modify enemy defense and test damage reduction
- [ ] Change enemy drops (gold, items, exp)
- [ ] Test edge cases (max stats, min stats, zero values)
- [ ] Verify save/load functionality

**Success Criteria**:
- [ ] Editor launches without errors
- [ ] ROM loads successfully
- [ ] Enemy data displays correctly
- [ ] Modifications save properly
- [ ] ROM rebuilds with changes
- [ ] Changes work in-game
- [ ] No crashes or data corruption

**Document Results In**: `docs/EDITOR_TEST_RESULTS.md` (create new file)

---

### Task 5.2: Test Dialog CLI

**Tool**: `tools/map-editor/dialog_cli.py`

**Testing Procedure**:
1. Launch dialog CLI:
   ```powershell
   python tools/map-editor/dialog_cli.py
   ```
2. List all dialogs
3. View specific dialog (e.g., dialog #0)
4. Edit dialog text
5. Save changes
6. Export to ROM format
7. Test in emulator:
   - Trigger edited dialog
   - Verify text displays correctly
   - Check control codes work ([WAIT], [PAGE], etc.)

**Test Scenarios**:
- [ ] List dialogs command works
- [ ] View dialog displays correctly
- [ ] Edit text and save
- [ ] Add control codes ([NAME], [ITEM], [WAIT])
- [ ] Export to ROM format
- [ ] Test in-game display
- [ ] Verify text doesn't overflow dialog box

**Success Criteria**:
- [ ] CLI launches without errors
- [ ] All commands work as expected
- [ ] Dialog editing functions properly
- [ ] Control codes are preserved
- [ ] Export creates valid ROM data
- [ ] In-game display matches edits
- [ ] No text overflow or corruption

**Document Results In**: `docs/EDITOR_TEST_RESULTS.md`

---

### Task 5.3: Test Text Extraction/Import Tools

**Tools**:
- `tools/extraction/extract_dialogs.py`
- `tools/import/import_text.py`

**Testing Procedure**:
1. Extract all text to CSV:
   ```powershell
   python tools/extraction/extract_dialogs.py --format csv --output data/text/dialogs.csv
   ```
2. Edit CSV in spreadsheet program (Excel, Google Sheets)
3. Make test modifications to dialog text
4. Import modified CSV back to ROM:
   ```powershell
   python tools/import/import_text.py data/text/dialogs.csv roms/ffmq_modified.sfc
   ```
5. Test modified ROM in emulator
6. Verify round-trip encode/decode preserves data

**Test Scenarios**:
- [ ] Extract dialogs to CSV
- [ ] CSV opens in spreadsheet program
- [ ] Edit dialog text in spreadsheet
- [ ] Import modified CSV
- [ ] ROM builds successfully
- [ ] Modified text displays in-game
- [ ] Round-trip preserves original data (if no edits)

**Success Criteria**:
- [ ] Extraction works for all text types
- [ ] CSV format is spreadsheet-compatible
- [ ] Import accepts valid edits
- [ ] Import rejects invalid edits (overflow, etc.)
- [ ] Round-trip is byte-perfect (no changes)
- [ ] Modified text displays correctly in-game

**Document Results In**: `docs/EDITOR_TEST_RESULTS.md`

---

## Priority 6: Documentation Updates (ONGOING)

### Context
As testing is completed, documentation files need to be updated with actual results, findings, and any corrections to hypotheses.

---

### Task 6.1: Update ROM_TEST_RESULTS.md

**File**: `docs/ROM_TEST_RESULTS.md`

**Updates Needed**:
- [ ] Fill in "Actual Results" for Test 1 (Formatting codes)
- [ ] Fill in "Actual Results" for Test 2 (Memory write)
- [ ] Fill in "Actual Results" for Test 3 (Subroutine call)
- [ ] Fill in "Actual Results" for Test 4 (Equipment slots)
- [ ] Fill in "Actual Results" for Test 5 (Unused codes)
- [ ] Update "Results Summary" section
- [ ] Update hypothesis confirmation/rejection counts
- [ ] Add screenshots to `docs/screenshots/`
- [ ] Update "Next Steps" based on findings

---

### Task 6.2: Update CONTROL_CODE_IDENTIFICATION.md

**File**: `docs/CONTROL_CODE_IDENTIFICATION.md`

**Updates Needed**:
- [ ] Update code 0x08 behavior (confirmed from Test 3)
- [ ] Update code 0x0E behavior (confirmed from Test 2)
- [ ] Update code 0x10, 0x17, 0x18 behavior (confirmed from Test 4)
- [ ] Update code 0x15, 0x19 status (confirmed from Test 5)
- [ ] Update code 0x1D, 0x1E behavior (confirmed from Test 1)
- [ ] Mark hypotheses as "CONFIRMED" or "REJECTED"
- [ ] Add evidence references (link to test results)

---

### Task 6.3: Create CHARACTER_ENCODING_VERIFICATION.md

**File**: `docs/CHARACTER_ENCODING_VERIFICATION.md` (new file)

**Content Needed**:
- [ ] Simple text character mappings verification results
- [ ] Complex text (DTE) mappings verification results
- [ ] Space character encoding clarification (0xFF vs `*`)
- [ ] List of corrected mappings
- [ ] Before/after examples
- [ ] Testing methodology
- [ ] Screenshots of character comparisons

---

### Task 6.4: Create BUILD_TEST_RESULTS.md

**File**: `docs/BUILD_TEST_RESULTS.md` (new file)

**Content Needed**:
- [ ] Build pipeline test results
- [ ] ROM comparison test results
- [ ] Patch application test results
- [ ] Make target test results
- [ ] Build times and performance notes
- [ ] Any build errors encountered
- [ ] Solutions to build issues

---

### Task 6.5: Create EDITOR_TEST_RESULTS.md

**File**: `docs/EDITOR_TEST_RESULTS.md` (new file)

**Content Needed**:
- [ ] Enemy editor test results
- [ ] Dialog CLI test results
- [ ] Text extraction/import test results
- [ ] Known bugs or issues
- [ ] Feature requests
- [ ] Usage tips and best practices

---

### Task 6.6: Update VRAM_ANALYSIS_README.md

**File**: `tools/extraction/VRAM_ANALYSIS_README.md`

**Updates Needed**:
- [ ] Update Step 2 with verification results
- [ ] Document actual sprite tile layouts
- [ ] Add sprite mapping JSON examples
- [ ] Link to created sprite_layouts.json
- [ ] Add VRAM screenshots
- [ ] Update "Next Steps" section

---

## Summary Statistics

**Total Manual Tasks**: 29 tasks across 6 categories

**By Priority**:
- Priority 1 (Critical): 5 tasks - Test ROM validation
- Priority 2 (High): 3 tasks - VRAM verification
- Priority 3 (High): 3 tasks - Character encoding
- Priority 4 (Medium): 4 tasks - Build system
- Priority 5 (Medium): 3 tasks - Editor tools
- Priority 6 (Ongoing): 6 tasks - Documentation
- Additional: 5 tasks - Advanced testing (see below)

**By Category**:
- Emulator Testing: 8 tasks
- ROM Validation: 4 tasks
- Graphics Verification: 3 tasks
- Text System Verification: 3 tasks
- Editor Testing: 3 tasks
- Documentation: 6 tasks
- Build Testing: 4 tasks

**Estimated Time**:
- Test ROMs (Priority 1): 2-3 hours
- VRAM Verification (Priority 2): 1-2 hours
- Character Encoding (Priority 3): 1-2 hours
- Build Testing (Priority 4): 1 hour
- Editor Testing (Priority 5): 1-2 hours
- Documentation (Priority 6): 2-3 hours
- **Total**: 8-13 hours of manual testing

---

## Additional Testing (Optional)

These tasks are mentioned in documentation but not critical for current work:

### Task A.1: Real Hardware Testing

**Purpose**: Verify ROM works on actual SNES hardware

**Testing Procedure**:
1. Flash ROM to flash cart (e.g., SD2SNES, FXPak Pro)
2. Test on real SNES console
3. Verify all functionality works
4. Note any differences from emulator behavior

**Success Criteria**:
- [ ] ROM boots on real hardware
- [ ] All features work correctly
- [ ] No performance issues
- [ ] Any differences documented

---

### Task A.2: Multiple Emulator Testing

**Purpose**: Verify ROM works across different emulators

**Testing Procedure**:
1. Test ROM in multiple emulators:
   - Mesen-S (recommended)
   - bsnes-plus
   - Snes9x
   - higan
   - ZSNES (legacy)
2. Document any compatibility issues
3. Note emulator-specific bugs

**Success Criteria**:
- [ ] ROM works in all major emulators
- [ ] Compatibility issues documented
- [ ] Recommended emulator noted

---

### Task A.3: Automated Test Script Execution

**Purpose**: Run Lua test scripts in emulator

**Testing Procedure**:
1. Configure Mesen-S for Lua scripting
2. Run test scripts from `tools/testing/lua_tests/`
3. Review automated test results
4. Document any failures

**Success Criteria**:
- [ ] Lua scripts execute successfully
- [ ] Automated tests pass
- [ ] Any failures investigated and documented

---

### Task A.4: Pre-Release Testing Checklist

**From**: `docs/tutorials/ADVANCED_MODDING.md` line 1034

**Full Testing Checklist**:
- [ ] ROM builds without errors
- [ ] ROM boots in emulator
- [ ] Modified features work as intended
- [ ] No crashes or freezes
- [ ] No graphical glitches
- [ ] Save states work correctly
- [ ] Tested on real hardware (if possible)
- [ ] Documented all changes
- [ ] Created clean patch file
- [ ] Tested patch application
- [ ] Verified no unintended changes

---

### Task A.5: Stress Testing

**Purpose**: Test ROM stability under edge cases

**Testing Procedure**:
1. Test extreme stat values (9999 HP, 255 attack, etc.)
2. Test overflow conditions
3. Test rapid input/state changes
4. Test save/load repeatedly
5. Test long play sessions (1+ hours)

**Success Criteria**:
- [ ] No crashes under extreme values
- [ ] No overflow bugs
- [ ] No memory leaks
- [ ] Saves work reliably
- [ ] Long sessions stable

---

## Testing Workflows

### Recommended Testing Order

1. **Start with Priority 1**: Test all 5 test ROMs first (most critical)
2. **Then Priority 3**: Verify character encoding (blocks text work)
3. **Then Priority 2**: VRAM verification (graphics validation)
4. **Then Priority 4**: Build system testing (development workflow)
5. **Then Priority 5**: Editor testing (tool validation)
6. **Finally Priority 6**: Update all documentation with findings

### Daily Testing Routine

**If testing incrementally over multiple days**:

**Day 1** (2-3 hours):
- Task 1.1: Test formatting codes ROM
- Task 1.2: Test memory write ROM
- Task 1.3: Test subroutine ROM
- Update ROM_TEST_RESULTS.md

**Day 2** (2-3 hours):
- Task 1.4: Test equipment slots ROM
- Task 1.5: Test unused codes ROM
- Task 3.1: Verify simple.tbl
- Task 3.2: Verify complex.tbl

**Day 3** (2-3 hours):
- Task 2.1: VRAM character sprites
- Task 2.2: VRAM portraits
- Task 2.3: Document sprite layouts

**Day 4** (1-2 hours):
- Task 4.1: Build pipeline
- Task 4.2: ROM comparison
- Task 4.3: Patch application
- Task 4.4: Make targets

**Day 5** (1-2 hours):
- Task 5.1: Enemy editor
- Task 5.2: Dialog CLI
- Task 5.3: Text tools

**Day 6** (2-3 hours):
- Task 6.1-6.6: All documentation updates
- Review and organize all findings
- Create summary report

---

## Tools and Resources

### Emulators

**Recommended**:
- **Mesen-S**: https://www.mesen.ca/ (best debugging features)
- **bsnes-plus**: https://github.com/devinacker/bsnes-plus (excellent debugging)

**Alternatives**:
- **Snes9x**: https://www.snes9x.com/ (good compatibility)
- **higan**: https://higan.dev/ (high accuracy)

### Debugging Tools

**Memory Viewers**:
- Mesen-S: Built-in memory viewer and debugger
- bsnes-plus: Built-in memory editor
- Hex editors: HxD (Windows), Hex Fiend (Mac)

**VRAM Viewers**:
- Mesen-S: Tools → VRAM Viewer
- bsnes-plus: Tools → Tile Viewer
- Snes9x: Tools → Tile Viewer

### ROM Tools

**Patch Creation**:
- Lunar IPS: https://www.romhacking.net/utilities/240/
- beat: https://github.com/higan-emu/beat (UPS format)

**ROM Editing**:
- YY-CHR: Tile editor
- SNES Palette Editor
- Hex editors for direct ROM editing

---

## Reporting Results

### Screenshot Naming Convention

Save screenshots with descriptive names:

```
docs/screenshots/
├── test_roms/
│   ├── test1_formatting_1d.png
│   ├── test1_formatting_1e.png
│   ├── test2_memory_watch.png
│   ├── test3_subroutine_dialog.png
│   ├── test4_equipment_items.png
│   └── test5_unused_codes.png
├── vram/
│   ├── benjamin_walking_front.png
│   ├── benjamin_vram_tiles.png
│   ├── kaeli_portrait.png
│   └── ...
├── character_encoding/
│   ├── simple_text_comparison.png
│   ├── dte_trailing_spaces.png
│   └── ...
└── editors/
    ├── enemy_editor_interface.png
    ├── dialog_cli_output.png
    └── ...
```

### Result Templates

Use these templates when updating documentation:

**Test ROM Result Template**:
```markdown
**Actual Results**: ✅ CONFIRMED / ❌ REJECTED / ⚠️ PARTIAL

**Observations**:
- [Describe what happened]
- [Note any unexpected behavior]
- [Include screenshot references]

**Hypothesis Status**: [CONFIRMED/REJECTED/MODIFIED]

**Evidence**:
- Screenshot: `docs/screenshots/test_roms/[filename].png`
- Memory values: [if applicable]
- Behavior notes: [detailed observations]

**Conclusions**:
- [What this confirms about the control code]
- [Any new questions raised]
- [Recommended next steps]
```

**Character Encoding Verification Template**:
```markdown
**Mapping**: `0x[HEX]` = "[CHARACTER]"

**Verification**:
- [ ] Extracted correctly
- [ ] Displays correctly in-game
- [ ] Matches character table

**Status**: ✅ CORRECT / ❌ INCORRECT / 🔧 FIXED

**Screenshot**: `docs/screenshots/character_encoding/[filename].png`

**Notes**: [Any special observations]
```

---

## Getting Help

### If Tests Fail

**ROM won't boot**:
1. Check ROM size (should be exactly 2,097,152 bytes)
2. Verify ROM header checksum
3. Try different emulator
4. Check for corruption in hex editor

**Emulator crashes**:
1. Update emulator to latest version
2. Try different emulator
3. Check emulator compatibility settings
4. Report bug with crash log

**Unexpected behavior**:
1. Document exact steps to reproduce
2. Take screenshots/video
3. Check emulator state (memory, registers)
4. Save state for later analysis
5. Report findings in documentation

### Questions or Issues

**Create GitHub issues** for:
- Test failures not covered in documentation
- Bug reports with test ROMs
- Feature requests for testing tools
- Documentation unclear or incomplete

**Tag issues appropriately**:
- `testing` - Testing-related tasks
- `emulator` - Emulator-specific issues
- `documentation` - Documentation updates needed
- `bug` - Bugs discovered during testing
- `question` - Questions about testing procedures

---

## Completion Checklist

Mark tasks complete as you finish them:

**Priority 1: Test ROMs** (5/5 complete):
- [ ] Task 1.1: Formatting codes tested
- [ ] Task 1.2: Memory write tested
- [ ] Task 1.3: Subroutine call tested
- [ ] Task 1.4: Equipment slots tested
- [ ] Task 1.5: Unused codes tested

**Priority 2: VRAM** (3/3 complete):
- [ ] Task 2.1: Character sprites verified
- [ ] Task 2.2: Portraits verified
- [ ] Task 2.3: Sprite layouts documented

**Priority 3: Character Encoding** (3/3 complete):
- [ ] Task 3.1: Simple.tbl verified
- [ ] Task 3.2: Complex.tbl verified
- [ ] Task 3.3: Dictionary verified

**Priority 4: Build System** (4/4 complete):
- [ ] Task 4.1: Full build tested
- [ ] Task 4.2: ROM comparison tested
- [ ] Task 4.3: Patch application tested
- [ ] Task 4.4: Make targets tested

**Priority 5: Editors** (3/3 complete):
- [ ] Task 5.1: Enemy editor tested
- [ ] Task 5.2: Dialog CLI tested
- [ ] Task 5.3: Text tools tested

**Priority 6: Documentation** (6/6 complete):
- [ ] Task 6.1: ROM_TEST_RESULTS.md updated
- [ ] Task 6.2: CONTROL_CODE_IDENTIFICATION.md updated
- [ ] Task 6.3: CHARACTER_ENCODING_VERIFICATION.md created
- [ ] Task 6.4: BUILD_TEST_RESULTS.md created
- [ ] Task 6.5: EDITOR_TEST_RESULTS.md created
- [ ] Task 6.6: VRAM_ANALYSIS_README.md updated

**Overall Progress**: 0/24 tasks complete (0%)

---

*Last Updated: 2025-11-12*  
*Total Tasks: 24 core tasks + 5 optional*  
*Estimated Time: 8-13 hours*
