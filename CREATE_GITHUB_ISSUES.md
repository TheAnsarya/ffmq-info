# Quick Reference: Creating GitHub Issues

**Generated**: 2025-11-12  
**Purpose**: Quick commands to create all GitHub issues for manual testing tasks

---

## Prerequisites

```powershell
# Install GitHub CLI
winget install GitHub.cli

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

---

## Create All Issues (Batch Script)

Save this as `create_all_issues.ps1`:

```powershell
# Create All GitHub Issues for Manual Testing Tasks
# Run from repository root directory

$issues = @(
    @{
        title = "Test ROM #1 - Formatting Codes (0x1D vs 0x1E)"
        body = "**File**: ``roms/test/test_format_1d_vs_1e.sfc``

Test ROM to validate formatting code hypotheses. Requires emulator testing to verify visual differences between codes 0x1D and 0x1E when formatting dictionary entries.

**Steps**:
1. Load test ROM in Mesen-S or bsnes-plus
2. Start new game and observe opening dialog
3. Compare visual formatting of two dictionary entries
4. Screenshot results
5. Update ``docs/ROM_TEST_RESULTS.md`` with findings

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 1.1

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "testing,emulator,control-codes,priority/critical"
    },
    @{
        title = "Test ROM #2 - Memory Write Operation (0x0E)"
        body = "**File**: ``roms/test/test_memory_write_0e.sfc``

Test ROM to validate memory write control code (0x0E). Requires memory viewer to verify that code writes 16-bit value to specified address.

**Steps**:
1. Load test ROM in emulator with memory viewer
2. Add memory watch at address 0x0100
3. Start new game and observe dialog
4. Verify memory address contains 0xABCD after dialog
5. Document results in ``docs/ROM_TEST_RESULTS.md``

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 1.2

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "testing,emulator,control-codes,priority/critical"
    },
    @{
        title = "Test ROM #3 - Subroutine Call (0x08)"
        body = "**File**: ``roms/test/test_subroutine_0x08.sfc``

Test ROM to validate subroutine call control code (0x08). Verifies dialog can execute nested fragments and return properly.

**Steps**:
1. Load test ROM in emulator
2. Start new game and observe dialog sequence
3. Verify dialog displays: 'Before call: SUBROUTINE TEXT' then 'After call'
4. Confirm no crashes or infinite loops
5. Update documentation

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 1.3

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "testing,emulator,control-codes,priority/critical"
    },
    @{
        title = "Test ROM #4 - Equipment Slot Detection (0x10, 0x17, 0x18)"
        body = "**File**: ``roms/test/test_equipment_slots.sfc``

Test ROM to validate equipment slot control codes access different item tables. Requires visual confirmation of three different item names.

**Steps**:
1. Load test ROM in emulator
2. Observe three item names displayed
3. Verify different items appear for codes 0x10, 0x17, and 0x18
4. Document which items appear
5. Update documentation

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 1.4

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "testing,emulator,control-codes,priority/critical"
    },
    @{
        title = "Test ROM #5 - Unused Codes (0x15, 0x19)"
        body = "**File**: ``roms/test/test_unused_codes.sfc``

Test ROM to determine behavior of unused control codes 0x15 (INSERT_NUMBER) and 0x19 (INSERT_ACCESSORY). May be functional, non-functional, or buggy.

**Steps**:
1. Load test ROM in emulator
2. Observe behavior when codes 0x15 and 0x19 execute
3. Document: functional (displays correctly), non-functional (ignored), or buggy (crashes)
4. Update documentation with findings

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 1.5

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "testing,emulator,control-codes,priority/critical"
    },
    @{
        title = "Verify Character Sprite Tile Extraction"
        body = "**Files**: ``assets/graphics/*_tiles.png`` (5 characters)

Extracted character sprite tiles need verification against VRAM viewer. Tile arrangements and palettes are currently guessed and may be incorrect.

**Steps**:
1. Run FFMQ in Mesen-S with VRAM viewer
2. Take screenshots during character animations
3. Compare extracted tiles with VRAM display
4. Document actual tile layouts in JSON format
5. Update ``tools/extraction/VRAM_ANALYSIS_README.md``

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 2.1

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "graphics,verification,emulator,priority/high"
    },
    @{
        title = "Verify Character Portrait Tile Extraction"
        body = "**Files**: ``assets/graphics/*_portrait_tiles.png`` (5 characters)

Verify extracted character portrait tiles (8×8 tile portraits for overworld map) match in-game display.

**Steps**:
1. Open VRAM viewer during overworld gameplay
2. Compare extracted portrait tiles with VRAM
3. Verify tile indices and colors
4. Document findings

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 2.2

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "graphics,verification,emulator,priority/high"
    },
    @{
        title = "Create Sprite Layout Mapping JSON"
        body = "Using VRAM viewer observations, create comprehensive sprite_layouts.json file documenting tile indices, dimensions, and palettes for all character animations.

**Steps**:
1. Analyze VRAM viewer screenshots
2. Document tile layouts for all animations (walking, battle poses)
3. Create ``data/graphics/sprite_layouts.json``
4. Update sprite assembly tool
5. Verify assembled sprites match game display

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 2.3

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "graphics,documentation,priority/high"
    },
    @{
        title = "Verify Simple Character Table (simple.tbl)"
        body = "**File**: ``simple.tbl``

Verify simple text character mappings against in-game display. User indicated 'sometimes ``*`` means `` `` (space)' - need to clarify space encoding (0xFF vs ``*``).

**Steps**:
1. Extract sample monster names
2. Compare with in-game display
3. Verify space character encoding (0xFF vs ``*``)
4. Document all character mappings
5. Fix any incorrect mappings
6. Update simple.tbl

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 3.1

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "text,encoding,verification,priority/high"
    },
    @{
        title = "Verify Complex Text Table (complex.tbl)"
        body = "**File**: ``complex.tbl``

Verify DTE (Dual Tile Encoding) mappings include correct trailing spaces. Check for ambiguous mappings (e.g., 0x5C). Validate dialog extraction accuracy.

**Steps**:
1. Extract sample dialogs
2. Compare with in-game display
3. Verify DTE trailing spaces (e.g., ``0x41`` = 'the ')
4. Document incorrect mappings
5. Fix complex.tbl
6. Test extraction accuracy

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 3.2

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "text,encoding,dte,verification,priority/high"
    },
    @{
        title = "Verify Dictionary Entries"
        body = "**File**: ``data/text/dictionary.json``

Verify dictionary entries used for dialog compression are accurate and complete. Test decompression against in-game display.

**Steps**:
1. Review dictionary.json entries
2. Test dictionary-compressed dialogs
3. Verify decompression accuracy
4. Check for missing entries
5. Document findings

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 3.3

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "text,dictionary,compression,priority/high"
    },
    @{
        title = "Test Full Build Pipeline"
        body = "Validate complete ROM build process from clean environment to working ROM. Ensure build system works correctly with all tools and scripts.

**Steps**:
1. Clean build environment
2. Run full build
3. Verify ROM boots in emulator
4. Test basic gameplay (title screen, new game, walk, battle, save)
5. Document any build errors
6. Create ``docs/BUILD_TEST_RESULTS.md``

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 4.1

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "build,testing,verification,priority/medium"
    },
    @{
        title = "Test ROM Comparison Tool"
        body = "**Tool**: ``tools/build/compare_roms.py``

Verify ROM comparison tool accurately detects differences between original and rebuilt ROMs.

**Steps**:
1. Build ROM from source
2. Run comparison tool
3. Review difference report
4. Verify expected differences
5. Confirm no unexpected changes

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 4.2

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "build,tooling,testing,priority/medium"
    },
    @{
        title = "Test Patch Application System"
        body = "**Tool**: ``tools/build/apply_patch.py``

Validate IPS/UPS patch creation and application tools work correctly.

**Steps**:
1. Create test patch
2. Apply patch to ROM
3. Load patched ROM in emulator
4. Verify modifications work
5. Document patch workflows

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 4.3

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "build,patching,testing,priority/medium"
    },
    @{
        title = "Test Make Targets and Build Scripts"
        body = "Validate all make targets and PowerShell build scripts function correctly.

**Steps**:
1. Test ``make test``, ``make test-rom``, ``make test-launch``, ``make test-debug``
2. Test PowerShell equivalents
3. Document any errors
4. Verify emulator integration works

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 4.4

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "build,testing,automation,priority/medium"
    },
    @{
        title = "Test Enemy Editor Tool"
        body = "**Tool**: ``enemy_editor.bat``

Validate enemy editor GUI allows modification of enemy stats, and changes apply correctly in-game.

**Steps**:
1. Launch enemy editor
2. Modify enemy stats (HP, attack, defense, drops)
3. Save changes and rebuild ROM
4. Test in emulator (battle modified enemy)
5. Verify changes work correctly
6. Document any bugs

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 5.1

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "editor,tooling,testing,priority/medium"
    },
    @{
        title = "Test Dialog CLI Tool"
        body = "**Tool**: ``tools/map-editor/dialog_cli.py``

Validate dialog command-line interface for viewing, editing, and exporting dialog text.

**Steps**:
1. Launch dialog CLI
2. List dialogs, view specific dialog
3. Edit dialog text with control codes
4. Export to ROM format
5. Test in emulator
6. Document functionality

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 5.2

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "editor,tooling,dialog,testing,priority/medium"
    },
    @{
        title = "Test Text Extraction and Import Tools"
        body = "**Tools**: ``extract_dialogs.py``, ``import_text.py``

Validate round-trip text extraction to CSV, editing in spreadsheet, and re-import to ROM.

**Steps**:
1. Extract all text to CSV
2. Edit in spreadsheet program
3. Import modified CSV to ROM
4. Test in emulator
5. Verify round-trip preserves data
6. Document workflow

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 5.3

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "text,tooling,extraction,import,testing,priority/medium"
    },
    @{
        title = "Update ROM_TEST_RESULTS.md with Test Findings"
        body = "**File**: ``docs/ROM_TEST_RESULTS.md``

Fill in 'Actual Results' sections for all 5 test ROMs after emulator testing is complete.

**Steps**:
1. Complete ROM testing (Tasks 1.1-1.5)
2. Update each test section with findings
3. Add screenshots
4. Update results summary
5. Mark hypotheses as confirmed/rejected

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 6.1

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "documentation,testing,priority/high"
    },
    @{
        title = "Update CONTROL_CODE_IDENTIFICATION.md"
        body = "**File**: ``docs/CONTROL_CODE_IDENTIFICATION.md``

Update control code documentation with confirmed behaviors from test ROM results.

**Steps**:
1. Review test ROM findings
2. Update code behaviors (0x08, 0x0E, 0x10, 0x15, 0x17, 0x18, 0x19, 0x1D, 0x1E)
3. Mark hypotheses as confirmed/rejected
4. Add evidence references

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 6.2

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "documentation,control-codes,priority/high"
    },
    @{
        title = "Create CHARACTER_ENCODING_VERIFICATION.md"
        body = "**File**: ``docs/CHARACTER_ENCODING_VERIFICATION.md`` (new)

Create comprehensive documentation of character encoding verification results for both simple and complex text systems.

**Steps**:
1. Document simple.tbl verification results
2. Document complex.tbl verification results
3. Clarify space encoding (0xFF vs ``*``)
4. List corrected mappings
5. Include before/after examples

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 6.3

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "documentation,text,encoding,priority/high"
    },
    @{
        title = "Create BUILD_TEST_RESULTS.md"
        body = "**File**: ``docs/BUILD_TEST_RESULTS.md`` (new)

Document all build system testing results including pipeline, comparison, patching, and make targets.

**Steps**:
1. Document build pipeline test results
2. Document ROM comparison results
3. Document patch application results
4. Document make target results
5. Include build times and performance notes

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 6.4

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "documentation,build,testing,priority/medium"
    },
    @{
        title = "Create EDITOR_TEST_RESULTS.md"
        body = "**File**: ``docs/EDITOR_TEST_RESULTS.md`` (new)

Document all editor tool testing results including enemy editor, dialog CLI, and text extraction/import.

**Steps**:
1. Document enemy editor test results
2. Document dialog CLI test results
3. Document text extraction/import results
4. List known bugs or issues
5. Include usage tips and best practices

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 6.5

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "documentation,tooling,testing,priority/medium"
    },
    @{
        title = "Update VRAM_ANALYSIS_README.md"
        body = "**File**: ``tools/extraction/VRAM_ANALYSIS_README.md``

Update VRAM analysis documentation with verification results and sprite layout mappings.

**Steps**:
1. Update with VRAM verification results
2. Document actual sprite tile layouts
3. Add sprite mapping JSON examples
4. Include VRAM screenshots
5. Update next steps section

**Related Doc**: ``MANUAL_TESTING_TASKS.md`` - Task 6.6

See ``GITHUB_ISSUES.md`` for complete details."
        labels = "documentation,graphics,verification,priority/high"
    }
)

Write-Host "Creating $($issues.Count) GitHub issues..." -ForegroundColor Cyan
Write-Host ""

$created = 0
$failed = 0

foreach ($issue in $issues) {
    Write-Host "Creating: $($issue.title)" -ForegroundColor Yellow
    
    try {
        gh issue create --title $issue.title --body $issue.body --label $issue.labels 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Created successfully" -ForegroundColor Green
            $created++
        } else {
            Write-Host "  ❌ Failed to create" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
        $failed++
    }
    
    # Small delay to avoid rate limiting
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Created: $created" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "View issues at: https://github.com/YOUR-USERNAME/ffmq-info/issues" -ForegroundColor Cyan
```

---

## Manual Issue Creation (One by One)

If you prefer to create issues manually or review each one:

### Priority 1: Test ROMs (Critical)

```powershell
# Test ROM #1
gh issue create --title "Test ROM #1 - Formatting Codes (0x1D vs 0x1E)" `
  --body "See MANUAL_TESTING_TASKS.md Task 1.1 and GITHUB_ISSUES.md for details." `
  --label "testing,emulator,control-codes,priority/critical"

# Test ROM #2
gh issue create --title "Test ROM #2 - Memory Write Operation (0x0E)" `
  --body "See MANUAL_TESTING_TASKS.md Task 1.2 and GITHUB_ISSUES.md for details." `
  --label "testing,emulator,control-codes,priority/critical"

# Test ROM #3
gh issue create --title "Test ROM #3 - Subroutine Call (0x08)" `
  --body "See MANUAL_TESTING_TASKS.md Task 1.3 and GITHUB_ISSUES.md for details." `
  --label "testing,emulator,control-codes,priority/critical"

# Test ROM #4
gh issue create --title "Test ROM #4 - Equipment Slot Detection (0x10, 0x17, 0x18)" `
  --body "See MANUAL_TESTING_TASKS.md Task 1.4 and GITHUB_ISSUES.md for details." `
  --label "testing,emulator,control-codes,priority/critical"

# Test ROM #5
gh issue create --title "Test ROM #5 - Unused Codes (0x15, 0x19)" `
  --body "See MANUAL_TESTING_TASKS.md Task 1.5 and GITHUB_ISSUES.md for details." `
  --label "testing,emulator,control-codes,priority/critical"
```

### Priority 2: VRAM Verification (High)

```powershell
gh issue create --title "Verify Character Sprite Tile Extraction" `
  --body "See MANUAL_TESTING_TASKS.md Task 2.1 and GITHUB_ISSUES.md for details." `
  --label "graphics,verification,emulator,priority/high"

gh issue create --title "Verify Character Portrait Tile Extraction" `
  --body "See MANUAL_TESTING_TASKS.md Task 2.2 and GITHUB_ISSUES.md for details." `
  --label "graphics,verification,emulator,priority/high"

gh issue create --title "Create Sprite Layout Mapping JSON" `
  --body "See MANUAL_TESTING_TASKS.md Task 2.3 and GITHUB_ISSUES.md for details." `
  --label "graphics,documentation,priority/high"
```

### Priority 3: Character Encoding (High)

```powershell
gh issue create --title "Verify Simple Character Table (simple.tbl)" `
  --body "See MANUAL_TESTING_TASKS.md Task 3.1 and GITHUB_ISSUES.md for details." `
  --label "text,encoding,verification,priority/high"

gh issue create --title "Verify Complex Text Table (complex.tbl)" `
  --body "See MANUAL_TESTING_TASKS.md Task 3.2 and GITHUB_ISSUES.md for details." `
  --label "text,encoding,dte,verification,priority/high"

gh issue create --title "Verify Dictionary Entries" `
  --body "See MANUAL_TESTING_TASKS.md Task 3.3 and GITHUB_ISSUES.md for details." `
  --label "text,dictionary,compression,priority/high"
```

---

## Quick Create All Issues (Single Command)

```powershell
# Download and run the batch script
.\create_all_issues.ps1
```

---

## Verify Issues Created

```powershell
# List all open issues
gh issue list

# List issues by label
gh issue list --label "testing"
gh issue list --label "priority/critical"
gh issue list --label "documentation"

# View specific issue
gh issue view ISSUE_NUMBER
```

---

## Additional Commands

```powershell
# Close an issue
gh issue close ISSUE_NUMBER

# Reopen an issue
gh issue reopen ISSUE_NUMBER

# Add label to issue
gh issue edit ISSUE_NUMBER --add-label "bug"

# Remove label from issue
gh issue edit ISSUE_NUMBER --remove-label "bug"

# Assign issue to yourself
gh issue edit ISSUE_NUMBER --add-assignee @me

# Add comment to issue
gh issue comment ISSUE_NUMBER --body "Testing in progress..."
```

---

## Issue Labels Used

**Priority**:
- `priority/critical` - Test ROMs requiring immediate attention
- `priority/high` - VRAM, encoding, important documentation
- `priority/medium` - Build system, editors, general documentation
- `priority/low` - Optional testing, CI/CD

**Category**:
- `testing` - Manual testing tasks
- `emulator` - Requires emulator usage
- `documentation` - Documentation updates
- `tooling` - Tool testing/development
- `text` - Text system related
- `graphics` - Graphics/VRAM related
- `build` - Build system related
- `control-codes` - Control code verification
- `encoding` - Character encoding
- `dte` - Dual Tile Encoding
- `verification` - Verification tasks

---

*Last Updated: 2025-11-12*  
*See MANUAL_TESTING_TASKS.md and GITHUB_ISSUES.md for complete details*
