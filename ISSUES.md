# FFMQ Disassembly - Active Issues & Tasks
**Created**: November 2, 2025  
**Status**: Post-100% Completion - Code Quality Phase

---

## 🎯 HIGH PRIORITY ISSUES

### Issue #1: Create .editorconfig for Consistent Formatting
**Priority**: HIGH  
**Effort**: 15 minutes  
**Status**: ✅ COMPLETE (Already existed!)

**Description**: Create .editorconfig file to standardize formatting across all ASM files.

**Requirements**:
- CRLF line endings (Windows standard)
- UTF-8 encoding
- Tab indentation (4 spaces display width)
- Trim trailing whitespace
- Insert final newline

**Result**: Comprehensive .editorconfig already exists in repository root with settings for:
- Assembly files (.asm, .inc) - tabs, 4 space width
- All source files - UTF-8, CRLF
- Python, PowerShell, JSON, YAML, etc.

**Acceptance Criteria**:
- [x] .editorconfig file exists in repository root
- [x] Covers all file types in project
- [x] Follows Windows/SNES development standards

---

### Issue #2: Analyze Current Formatting State
**Priority**: HIGH  
**Effort**: 30 minutes  
**Status**: ✅ COMPLETE

**Description**: Survey all ASM files to understand current formatting (tabs vs spaces, line endings, encoding).

**Result**: Created comprehensive `docs/FORMATTING_ANALYSIS.md` report

**Findings**:
- ✅ All 16 bank files use TABS for indentation
- ✅ All files use CRLF line endings (Windows standard)
- ✅ All files are UTF-8 encoded
- ✅ Consistent column alignment across all files
- ✅ Already compliant with .editorconfig standards

**Deliverable**: ✅ `docs/FORMATTING_ANALYSIS.md` created

**Conclusion**: **NO FORMATTING CHANGES NEEDED** - code already follows professional standards

---

### Issue #3: Create ASM Formatting Tool
**Priority**: ~~HIGH~~ LOW  
**Effort**: ~~2-3 hours~~ N/A  
**Status**: ❌ NOT NEEDED

**Description**: Create PowerShell script to automatically format ASM files according to standards.

**Result**: Analysis (Issue #2) revealed formatting tool is unnecessary
- All files already properly formatted
- No inconsistencies detected
- Tool would provide no value

**Decision**: Skip this issue - time better spent on documentation

---

### Issue #4: Apply Formatting to Bank Files
**Priority**: ~~MEDIUM~~ N/A  
**Effort**: ~~3-4 hours~~ N/A  
**Status**: ❌ NOT NEEDED  
**Blocked By**: ~~Issue #3~~ N/A

**Description**: Apply standardized formatting to all bank ASM files.

**Result**: Files already properly formatted (Issue #2 analysis)
- No changes required
- 100% ROM match already guaranteed

**Decision**: Skip this issue - no work needed

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
**High Priority**: 1 (down from 4)  
**Medium Priority**: 3  
**Low Priority**: 3  
**Completed**: 3 (Issues #1, #2, #4)  
**Skipped**: 2 (Issues #3, #4 - not needed)

**Status Breakdown**:
- � Complete: 3 (Issues #1, #2, #4)
- ❌ Skipped: 2 (Issues #3, #4)
- � TODO: 5 (Issues #5, #6, #7, #8, #9, #10)

**Current Focus**: Documentation tasks (RAM/ROM maps, register names)

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
