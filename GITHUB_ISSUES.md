# GitHub Issues for ffmq-info

This file lists the high-priority issues for the repository and provides ready-to-run `gh` CLI commands to create issues on GitHub.

Guidance:
- Install GitHub CLI (`gh`) and authenticate (run `gh auth login`).
- Run `.	ools\gh\create_issues.ps1` in PowerShell to create the issues described below.

---

### ISSUE: Fix DTE table - `complex.tbl` inaccuracies

Description:
Tabs: The `complex.tbl` DTE mappings do not match ROM data; many entries miss trailing spaces (e.g. `0x41` = "the ") and others are incorrect (e.g. `0x5C` mapping ambiguous). This blocks dialog extraction and editing.

Proposed labels: text, dte, priority/high

---

### ISSUE: Simple text extractor - regenerate `data/text_fixed/*`

Description:
Simple fixed-length tables (items, spells, monsters) are produced incorrectly. Update `tools/extraction/*` to use `simple.tbl` and correct ROM addresses; regenerate CSVs in `data/text_fixed`.

Proposed labels: tooling, extraction, priority/medium

---

### ISSUE: Reverse-engineer remaining control codes

Description:
Map all control codes (0x00-0x3B, 0x80-0x8F) to engine behavior (textbox positioning, screen shake, map change, movement). Produce `docs/CONTROL_CODES.md` with byte-level semantics and assembly references.

Proposed labels: research, engine, priority/medium

---

### ISSUE: Dialog re-insertion tooling and validation

Description:
Add safe re-insertion scripts, pointer validation, and unit tests for round-trip encode/decode. Add `tools/import/import_text.py` enhancements and tests.

Proposed labels: tooling, testing, priority/high

---

### ISSUE: Add CI to run extraction tests

Description:
Add a GitHub Actions workflow to run `test_text_systems.py` on push/PR to detect regressions.

Proposed labels: ci, testing, priority/low

---

## Section 2: Manual Testing Tasks (User Action Required)

**See `MANUAL_TESTING_TASKS.md` for detailed procedures.**

### Priority 1: Test ROM Validation (CRITICAL)

#### ISSUE: Test ROM #1 - Formatting Codes (0x1D vs 0x1E)

**File**: `roms/test/test_format_1d_vs_1e.sfc`

**Description**:
Test ROM to validate formatting code hypotheses. Requires emulator testing to verify visual differences between codes 0x1D and 0x1E when formatting dictionary entries.

**Steps**:
1. Load test ROM in Mesen-S or bsnes-plus
2. Start new game and observe opening dialog
3. Compare visual formatting of two dictionary entries
4. Screenshot results
5. Update `docs/ROM_TEST_RESULTS.md` with findings

**Labels**: testing, emulator, control-codes, priority/critical

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 1.1

---

#### ISSUE: Test ROM #2 - Memory Write Operation (0x0E)

**File**: `roms/test/test_memory_write_0e.sfc`

**Description**:
Test ROM to validate memory write control code (0x0E). Requires memory viewer to verify that code writes 16-bit value to specified address.

**Steps**:
1. Load test ROM in emulator with memory viewer
2. Add memory watch at address 0x0100
3. Start new game and observe dialog
4. Verify memory address contains 0xABCD after dialog
5. Document results in `docs/ROM_TEST_RESULTS.md`

**Labels**: testing, emulator, control-codes, priority/critical

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 1.2

---

#### ISSUE: Test ROM #3 - Subroutine Call (0x08)

**File**: `roms/test/test_subroutine_0x08.sfc`

**Description**:
Test ROM to validate subroutine call control code (0x08). Verifies dialog can execute nested fragments and return properly.

**Steps**:
1. Load test ROM in emulator
2. Start new game and observe dialog sequence
3. Verify dialog displays: "Before call: SUBROUTINE TEXT" then "After call"
4. Confirm no crashes or infinite loops
5. Update documentation

**Labels**: testing, emulator, control-codes, priority/critical

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 1.3

---

#### ISSUE: Test ROM #4 - Equipment Slot Detection (0x10, 0x17, 0x18)

**File**: `roms/test/test_equipment_slots.sfc`

**Description**:
Test ROM to validate equipment slot control codes access different item tables. Requires visual confirmation of three different item names.

**Steps**:
1. Load test ROM in emulator
2. Observe three item names displayed
3. Verify different items appear for codes 0x10, 0x17, and 0x18
4. Document which items appear
5. Update documentation

**Labels**: testing, emulator, control-codes, priority/critical

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 1.4

---

#### ISSUE: Test ROM #5 - Unused Codes (0x15, 0x19)

**File**: `roms/test/test_unused_codes.sfc`

**Description**:
Test ROM to determine behavior of unused control codes 0x15 (INSERT_NUMBER) and 0x19 (INSERT_ACCESSORY). May be functional, non-functional, or buggy.

**Steps**:
1. Load test ROM in emulator
2. Observe behavior when codes 0x15 and 0x19 execute
3. Document: functional (displays correctly), non-functional (ignored), or buggy (crashes)
4. Update documentation with findings

**Labels**: testing, emulator, control-codes, priority/critical

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 1.5

---

### Priority 2: VRAM Graphics Verification (HIGH)

#### ISSUE: Verify Character Sprite Tile Extraction

**Files**: `assets/graphics/*_tiles.png` (5 characters)

**Description**:
Extracted character sprite tiles need verification against VRAM viewer. Tile arrangements and palettes are currently guessed and may be incorrect.

**Steps**:
1. Run FFMQ in Mesen-S with VRAM viewer
2. Take screenshots during character animations
3. Compare extracted tiles with VRAM display
4. Document actual tile layouts in JSON format
5. Update `tools/extraction/VRAM_ANALYSIS_README.md`

**Labels**: graphics, verification, emulator, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 2.1

---

#### ISSUE: Verify Character Portrait Tile Extraction

**Files**: `assets/graphics/*_portrait_tiles.png` (5 characters)

**Description**:
Verify extracted character portrait tiles (8×8 tile portraits for overworld map) match in-game display.

**Steps**:
1. Open VRAM viewer during overworld gameplay
2. Compare extracted portrait tiles with VRAM
3. Verify tile indices and colors
4. Document findings

**Labels**: graphics, verification, emulator, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 2.2

---

#### ISSUE: Create Sprite Layout Mapping JSON

**Purpose**: Document actual sprite tile layouts for accurate sprite assembly

**Description**:
Using VRAM viewer observations, create comprehensive sprite_layouts.json file documenting tile indices, dimensions, and palettes for all character animations.

**Steps**:
1. Analyze VRAM viewer screenshots
2. Document tile layouts for all animations (walking, battle poses)
3. Create `data/graphics/sprite_layouts.json`
4. Update sprite assembly tool
5. Verify assembled sprites match game display

**Labels**: graphics, documentation, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 2.3

---

### Priority 3: Character Encoding Validation (HIGH)

#### ISSUE: Verify Simple Character Table (simple.tbl)

**File**: `simple.tbl`

**Description**:
Verify simple text character mappings against in-game display. User indicated "sometimes `*` means ` ` (space)" - need to clarify space encoding (0xFF vs `*`).

**Steps**:
1. Extract sample monster names
2. Compare with in-game display
3. Verify space character encoding (0xFF vs `*`)
4. Document all character mappings
5. Fix any incorrect mappings
6. Update simple.tbl

**Labels**: text, encoding, verification, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 3.1

---

#### ISSUE: Verify Complex Text Table (complex.tbl)

**File**: `complex.tbl`

**Description**:
Verify DTE (Dual Tile Encoding) mappings include correct trailing spaces. Check for ambiguous mappings (e.g., 0x5C). Validate dialog extraction accuracy.

**Steps**:
1. Extract sample dialogs
2. Compare with in-game display
3. Verify DTE trailing spaces (e.g., `0x41` = "the ")
4. Document incorrect mappings
5. Fix complex.tbl
6. Test extraction accuracy

**Labels**: text, encoding, dte, verification, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 3.2

---

#### ISSUE: Verify Dictionary Entries

**File**: `data/text/dictionary.json`

**Description**:
Verify dictionary entries used for dialog compression are accurate and complete. Test decompression against in-game display.

**Steps**:
1. Review dictionary.json entries
2. Test dictionary-compressed dialogs
3. Verify decompression accuracy
4. Check for missing entries
5. Document findings

**Labels**: text, dictionary, compression, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 3.3

---

### Priority 4: Build System Testing (MEDIUM)

#### ISSUE: Test Full Build Pipeline

**Description**:
Validate complete ROM build process from clean environment to working ROM. Ensure build system works correctly with all tools and scripts.

**Steps**:
1. Clean build environment
2. Run full build
3. Verify ROM boots in emulator
4. Test basic gameplay (title screen, new game, walk, battle, save)
5. Document any build errors
6. Create `docs/BUILD_TEST_RESULTS.md`

**Labels**: build, testing, verification, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 4.1

---

#### ISSUE: Test ROM Comparison Tool

**Tool**: `tools/build/compare_roms.py`

**Description**:
Verify ROM comparison tool accurately detects differences between original and rebuilt ROMs.

**Steps**:
1. Build ROM from source
2. Run comparison tool
3. Review difference report
4. Verify expected differences
5. Confirm no unexpected changes

**Labels**: build, tooling, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 4.2

---

#### ISSUE: Test Patch Application System

**Tool**: `tools/build/apply_patch.py`

**Description**:
Validate IPS/UPS patch creation and application tools work correctly.

**Steps**:
1. Create test patch
2. Apply patch to ROM
3. Load patched ROM in emulator
4. Verify modifications work
5. Document patch workflows

**Labels**: build, patching, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 4.3

---

#### ISSUE: Test Make Targets and Build Scripts

**Description**:
Validate all make targets and PowerShell build scripts function correctly.

**Steps**:
1. Test `make test`, `make test-rom`, `make test-launch`, `make test-debug`
2. Test PowerShell equivalents
3. Document any errors
4. Verify emulator integration works

**Labels**: build, testing, automation, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 4.4

---

### Priority 5: Editor Tool Testing (MEDIUM)

#### ISSUE: Test Enemy Editor Tool

**Tool**: `enemy_editor.bat`

**Description**:
Validate enemy editor GUI allows modification of enemy stats, and changes apply correctly in-game.

**Steps**:
1. Launch enemy editor
2. Modify enemy stats (HP, attack, defense, drops)
3. Save changes and rebuild ROM
4. Test in emulator (battle modified enemy)
5. Verify changes work correctly
6. Document any bugs

**Labels**: editor, tooling, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 5.1

---

#### ISSUE: Test Dialog CLI Tool

**Tool**: `tools/map-editor/dialog_cli.py`

**Description**:
Validate dialog command-line interface for viewing, editing, and exporting dialog text.

**Steps**:
1. Launch dialog CLI
2. List dialogs, view specific dialog
3. Edit dialog text with control codes
4. Export to ROM format
5. Test in emulator
6. Document functionality

**Labels**: editor, tooling, dialog, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 5.2

---

#### ISSUE: Test Text Extraction and Import Tools

**Tools**: `extract_dialogs.py`, `import_text.py`

**Description**:
Validate round-trip text extraction to CSV, editing in spreadsheet, and re-import to ROM.

**Steps**:
1. Extract all text to CSV
2. Edit in spreadsheet program
3. Import modified CSV to ROM
4. Test in emulator
5. Verify round-trip preserves data
6. Document workflow

**Labels**: text, tooling, extraction, import, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 5.3

---

### Priority 6: Documentation Updates (ONGOING)

#### ISSUE: Update ROM_TEST_RESULTS.md with Test Findings

**File**: `docs/ROM_TEST_RESULTS.md`

**Description**:
Fill in "Actual Results" sections for all 5 test ROMs after emulator testing is complete.

**Steps**:
1. Complete ROM testing (Tasks 1.1-1.5)
2. Update each test section with findings
3. Add screenshots
4. Update results summary
5. Mark hypotheses as confirmed/rejected

**Labels**: documentation, testing, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 6.1

---

#### ISSUE: Update CONTROL_CODE_IDENTIFICATION.md

**File**: `docs/CONTROL_CODE_IDENTIFICATION.md`

**Description**:
Update control code documentation with confirmed behaviors from test ROM results.

**Steps**:
1. Review test ROM findings
2. Update code behaviors (0x08, 0x0E, 0x10, 0x15, 0x17, 0x18, 0x19, 0x1D, 0x1E)
3. Mark hypotheses as confirmed/rejected
4. Add evidence references

**Labels**: documentation, control-codes, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 6.2

---

#### ISSUE: Create CHARACTER_ENCODING_VERIFICATION.md

**File**: `docs/CHARACTER_ENCODING_VERIFICATION.md` (new)

**Description**:
Create comprehensive documentation of character encoding verification results for both simple and complex text systems.

**Steps**:
1. Document simple.tbl verification results
2. Document complex.tbl verification results
3. Clarify space encoding (0xFF vs `*`)
4. List corrected mappings
5. Include before/after examples

**Labels**: documentation, text, encoding, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 6.3

---

#### ISSUE: Create BUILD_TEST_RESULTS.md

**File**: `docs/BUILD_TEST_RESULTS.md` (new)

**Description**:
Document all build system testing results including pipeline, comparison, patching, and make targets.

**Steps**:
1. Document build pipeline test results
2. Document ROM comparison results
3. Document patch application results
4. Document make target results
5. Include build times and performance notes

**Labels**: documentation, build, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 6.4

---

#### ISSUE: Create EDITOR_TEST_RESULTS.md

**File**: `docs/EDITOR_TEST_RESULTS.md` (new)

**Description**:
Document all editor tool testing results including enemy editor, dialog CLI, and text extraction/import.

**Steps**:
1. Document enemy editor test results
2. Document dialog CLI test results
3. Document text extraction/import results
4. List known bugs or issues
5. Include usage tips and best practices

**Labels**: documentation, tooling, testing, priority/medium

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 6.5

---

#### ISSUE: Update VRAM_ANALYSIS_README.md

**File**: `tools/extraction/VRAM_ANALYSIS_README.md`

**Description**:
Update VRAM analysis documentation with verification results and sprite layout mappings.

**Steps**:
1. Update with VRAM verification results
2. Document actual sprite tile layouts
3. Add sprite mapping JSON examples
4. Include VRAM screenshots
5. Update next steps section

**Labels**: documentation, graphics, verification, priority/high

**Related Doc**: MANUAL_TESTING_TASKS.md - Task 6.6

---

## Section 3: Additional Testing (Optional)

#### ISSUE: Test ROM on Real SNES Hardware

**Description**:
Verify ROM works on actual SNES hardware (not just emulators).

**Steps**:
1. Flash ROM to flash cart (SD2SNES, FXPak Pro)
2. Test on real SNES console
3. Verify all functionality works
4. Document any hardware-specific behavior

**Labels**: testing, hardware, optional, priority/low

**Related Doc**: MANUAL_TESTING_TASKS.md - Task A.1

---

#### ISSUE: Test ROM Across Multiple Emulators

**Description**:
Ensure ROM compatibility across different SNES emulators.

**Steps**:
1. Test in Mesen-S, bsnes-plus, Snes9x, higan, ZSNES
2. Document compatibility issues
3. Note emulator-specific bugs
4. Recommend best emulator for modding

**Labels**: testing, emulation, compatibility, priority/low

**Related Doc**: MANUAL_TESTING_TASKS.md - Task A.2

---

## References

- DataCrystal: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/TBL
- TCRF: https://tcrf.net/Final_Fantasy:_Mystic_Quest
- Manual Testing Guide: `MANUAL_TESTING_TASKS.md`
- Test ROM Documentation: `docs/ROM_TEST_RESULTS.md`
- VRAM Analysis: `tools/extraction/VRAM_ANALYSIS_README.md`

---

## How to create issues

### Method 1: PowerShell Script (Automated)

Run the PowerShell script included at `tools\gh\create_issues.ps1`. It will create the issues above using the `gh` CLI. You will be prompted before each create.

```powershell
# Install GitHub CLI first
winget install GitHub.cli

# Authenticate
gh auth login

# Run issue creation script
.\tools\gh\create_issues.ps1
```

### Method 2: Manual Creation with gh CLI

```powershell
# Example: Create test ROM issue
gh issue create --title "Test ROM #1 - Formatting Codes (0x1D vs 0x1E)" `
  --body "See GITHUB_ISSUES.md for full description" `
  --label "testing,emulator,control-codes,priority/critical"

# Create all issues from file
# (Script does this automatically)
```

### Method 3: GitHub Web Interface

1. Go to repository Issues page
2. Click "New Issue"
3. Copy title and description from this file
4. Add appropriate labels
5. Submit issue

---

## Issue Statistics

**Total Issues**: 30

**By Priority**:
- Critical: 5 (test ROMs)
- High: 9 (VRAM, encoding, documentation)
- Medium: 11 (build, editors, documentation)
- Low: 3 (original issues + optional testing)
- Optional: 2 (hardware, compatibility)

**By Category**:
- Testing: 13 issues
- Documentation: 6 issues
- Tooling: 5 issues
- Text Systems: 4 issues
- Graphics: 3 issues
- Build System: 4 issues
- Research: 1 issue
- CI/CD: 1 issue
- Optional: 2 issues

**By Status**:
- Not Started: 30
- In Progress: 0
- Completed: 0

---

*Last Updated: 2025-11-12*  
*See `MANUAL_TESTING_TASKS.md` for detailed testing procedures*
