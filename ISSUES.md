# FFMQ Disassembly - Active Issues & Tasks
**Created**: November 2, 2025  
**Status**: Post-100% Completion - Code Quality Phase

---

## 🎯 HIGH PRIORITY ISSUES

### Issue #1: Create .editorconfig for Consistent Formatting
**Priority**: HIGH  
**Effort**: 15 minutes  
**Status**: 🔴 TODO

**Description**: Create .editorconfig file to standardize formatting across all ASM files.

**Requirements**:
- CRLF line endings (Windows standard)
- UTF-8 encoding
- Tab indentation (4 spaces display width)
- Trim trailing whitespace
- Insert final newline

**Implementation**:
```ini
# EditorConfig for FFMQ Disassembly Project
root = true

[*.asm]
charset = utf-8
end_of_line = crlf
indent_style = tab
indent_size = 4
tab_width = 4
insert_final_newline = true
trim_trailing_whitespace = true
```

**Acceptance Criteria**:
- [ ] .editorconfig file created in repository root
- [ ] File committed to git
- [ ] Documentation updated mentioning .editorconfig

---

### Issue #2: Analyze Current Formatting State
**Priority**: HIGH  
**Effort**: 30 minutes  
**Status**: 🔴 TODO

**Description**: Survey all ASM files to understand current formatting (tabs vs spaces, line endings, encoding).

**Tasks**:
- [ ] Count files using tabs vs spaces for indentation
- [ ] Check line ending types (CRLF vs LF)
- [ ] Verify UTF-8 encoding (with/without BOM)
- [ ] Document any formatting inconsistencies
- [ ] Create baseline report

**Commands**:
```powershell
# Check line endings
Get-ChildItem -Recurse -Filter *.asm | ForEach-Object {
    $content = [System.IO.File]::ReadAllBytes($_.FullName)
    # Check for CRLF vs LF
}

# Check tabs vs spaces
Get-ChildItem -Recurse -Filter *.asm | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "`t") { "TABS: $($_.Name)" }
    else { "SPACES: $($_.Name)" }
}
```

**Deliverable**: `docs/FORMATTING_ANALYSIS.md` with current state

---

### Issue #3: Create ASM Formatting Tool
**Priority**: HIGH  
**Effort**: 2-3 hours  
**Status**: 🔴 TODO

**Description**: Create PowerShell script to automatically format ASM files according to standards.

**Features Required**:
- Convert spaces to tabs (preserve column alignment)
- Standardize line endings to CRLF
- Ensure UTF-8 encoding
- Trim trailing whitespace
- Add final newline if missing
- Dry-run mode (preview changes without modifying)
- Verify mode (check formatting without changes)

**Script Location**: `tools/format_asm.ps1`

**Usage Examples**:
```powershell
# Dry run - preview changes
.\tools\format_asm.ps1 -File src/asm/banks/bank_00.asm -DryRun

# Apply formatting
.\tools\format_asm.ps1 -File src/asm/banks/bank_00.asm

# Verify formatting
.\tools\format_asm.ps1 -File src/asm/banks/bank_00.asm -Verify

# Format all banks
.\tools\format_asm.ps1 -Path src/asm/banks/*.asm
```

**Critical**: Must preserve ROM match! Test with build verification.

---

### Issue #4: Apply Formatting to Bank Files
**Priority**: MEDIUM  
**Effort**: 3-4 hours  
**Status**: 🔴 TODO  
**Blocked By**: Issue #3

**Description**: Apply standardized formatting to all bank ASM files.

**Order of Operations**:
1. Test on one file (bank_00.asm)
2. Verify ROM build matches
3. If successful, apply to remaining banks
4. Commit each bank individually

**Files to Format** (16 banks):
- [ ] src/asm/banks/bank_00.asm
- [ ] src/asm/banks/bank_01.asm
- [ ] src/asm/banks/bank_02.asm
- [ ] src/asm/banks/bank_03.asm
- [ ] src/asm/banks/bank_04.asm
- [ ] src/asm/banks/bank_05.asm
- [ ] src/asm/banks/bank_06.asm
- [ ] src/asm/banks/bank_07.asm
- [ ] src/asm/banks/bank_08.asm
- [ ] src/asm/banks/bank_09.asm
- [ ] src/asm/banks/bank_0A.asm
- [ ] src/asm/banks/bank_0B.asm
- [ ] src/asm/banks/bank_0C.asm
- [ ] src/asm/banks/bank_0D.asm
- [ ] src/asm/banks/bank_0E.asm
- [ ] src/asm/banks/bank_0F.asm

**Verification After Each**:
```powershell
.\build.ps1
# Check SHA256 hash matches F71817F5...
```

---

## 🎨 MEDIUM PRIORITY ISSUES

### Issue #5: Create RAM Map Documentation
**Priority**: MEDIUM  
**Effort**: 4-6 hours  
**Status**: 🔴 TODO

**Description**: Document all RAM addresses used by the game.

**Structure**:
```markdown
# FFMQ RAM Map

## Zero Page ($00-$FF)
| Address | Size | Type | Name | Description |
|---------|------|------|------|-------------|
| $00-$01 | 2 | ptr | temp_ptr | Temporary pointer |
| ...

## WRAM ($0200-$1FFF)
...

## Extended RAM ($7E2000-$7FFFFF)
...
```

**Tools Needed**:
- Scan all ASM files for direct page references ($xx)
- Scan for absolute addresses ($xxxx in WRAM range)
- Cross-reference with existing documentation

**Deliverable**: `docs/RAM_MAP.md`

---

### Issue #6: Create ROM Data Map
**Priority**: MEDIUM  
**Effort**: 4-6 hours  
**Status**: 🔴 TODO

**Description**: Document all data tables, graphics, text in ROM.

**Categories**:
- Pointer tables
- Stat/equipment data
- Graphics (compressed/uncompressed)
- Text strings
- Music/sound data
- Map data

**Deliverable**: `docs/ROM_DATA_MAP.md`

---

### Issue #7: Standardize Hardware Register Names
**Priority**: MEDIUM  
**Effort**: 2 hours  
**Status**: 🔴 TODO

**Description**: Ensure all SNES hardware register references use consistent names.

**Current State**: Mix of numeric ($2100) and symbolic (INIDISP)

**Target**: All symbolic names (using standard SNES register names)

**Tools**:
- Search for `$21xx`, `$42xx`, `$43xx` patterns
- Replace with symbolic constants
- Use labels.asm or create hardware.inc

---

## 🔵 LOW PRIORITY ISSUES

### Issue #8: Add More Inline Comments
**Priority**: LOW  
**Effort**: Ongoing  
**Status**: 🔴 TODO

**Description**: Enhance code readability with more explanatory comments.

**Guidelines**:
- Explain complex algorithms
- Document hardware quirks
- Add references to SNES programming guides
- Explain non-obvious game logic

**Target Areas**:
- Battle damage calculation
- Mode 7 mathematics
- Graphics decompression
- AI behavior

---

### Issue #9: Create System Flow Diagrams
**Priority**: LOW  
**Effort**: 6-8 hours  
**Status**: 🔴 TODO

**Description**: Create visual documentation of major game systems.

**Diagrams Needed**:
- Game initialization flow
- Battle system flow
- Menu system flow
- Map/field system flow
- Save/load flow

**Format**: Mermaid diagrams in Markdown

**Deliverable**: `docs/SYSTEM_FLOWS.md`

---

### Issue #10: Extract All Game Constants
**Priority**: LOW  
**Effort**: 4 hours  
**Status**: 🔴 TODO

**Description**: Create constants.inc file with all magic numbers.

**Examples**:
```asm
; Instead of: LDA #$03
; Use: LDA #MAX_PARTY_SIZE

; Instead of: CMP #$63
; Use: CMP #MAX_LEVEL
```

**Deliverable**: `src/asm/includes/constants.inc`

---

## 📊 ISSUE STATISTICS

**Total Issues**: 10  
**High Priority**: 4  
**Medium Priority**: 3  
**Low Priority**: 3  

**Status Breakdown**:
- 🔴 TODO: 10
- 🟡 In Progress: 0
- 🟢 Complete: 0

---

## 🎯 RECOMMENDED WORKFLOW

**Week 1**: Code Formatting Foundation
1. Issue #1: Create .editorconfig (15 min)
2. Issue #2: Analyze current formatting (30 min)
3. Issue #3: Create formatting tool (2-3 hours)
4. Issue #4: Apply formatting to banks (3-4 hours)

**Week 2**: Documentation
5. Issue #5: Create RAM map (4-6 hours)
6. Issue #6: Create ROM data map (4-6 hours)
7. Issue #7: Standardize register names (2 hours)

**Week 3+**: Enhancement (Optional)
8. Issue #8: Add inline comments (ongoing)
9. Issue #9: Create flow diagrams (6-8 hours)
10. Issue #10: Extract constants (4 hours)

**Total Estimated Time**: 30-40 hours for all high/medium priority items

---

## 📝 NOTES

- All changes MUST preserve 100% ROM match
- Build verification required after every change
- Commit frequently with descriptive messages
- Update this file as issues are completed
- Add new issues as discovered

**Last Updated**: November 2, 2025
