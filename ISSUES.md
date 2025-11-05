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

### Issue #70: Verify Sprite Extraction Against Game Output
**Priority**: LOW  
**Effort**: 8-12 hours  
**Status**: 🔄 IN PROGRESS - Extraction Complete, Verification Pending

**Description**: Current sprite assembly uses guessed tile arrangements that don't match actual game graphics. Need to verify extracted sprites against actual VRAM and update definitions.

**Current State**:
- ✅ Multi-palette tile extraction working correctly
- ✅ Extracted character sprites from verified ROM addresses
- ✅ Benjamin: 512 tiles, others: 256 tiles each
- ❌ Sprite tile arrangements are guessed, not verified

**Verification Process**:
1. ✅ Extract raw tiles from correct ROM addresses (DONE)
2. ⏳ Compare with game screenshots/VRAM viewer
3. ⏳ Identify actual sprite tile arrangements (not [0,1,16,17])
4. ⏳ Parse metasprite tables at ROM $062c4c for real layouts
5. ⏳ Update assemble_sprites.py with verified data
6. ⏳ Expand to all 83 enemies + NPCs + UI elements

**Files**:
- `tools/extraction/analyze_vram.py` - Extract tiles from verified ROM addresses
- `tools/extraction/assemble_sprites.py` - Needs update with real tile arrangements
- `data/extracted/graphics/vram_analysis/*_tiles.png` - Raw extracted tiles

**Blocking Items**:
- Manual visual inspection required (AI cannot do this)
- Need emulator with VRAM viewer for verification
- Metasprite table parsing needed for accurate layouts

**Deliverables**:
- [ ] Verified sprite definitions with correct tile indices
- [ ] Comparison screenshots (extracted vs actual game)
- [ ] Documentation of sprite organization patterns
- [ ] All 83 enemies extracted and verified
- [ ] Animation frame support

**Next Actions** (when prioritized):
1. Run FFMQ in emulator with VRAM viewer
2. Capture actual sprite layouts
3. Map tile indices to sprite poses
4. Update sprite definitions with real data

---

### Issue #5: Create RAM Map Documentation
**Priority**: MEDIUM  
**Effort**: 4-6 hours  
**Status**: ✅ ALREADY EXISTS

**Description**: Document all RAM addresses used by the game.

**Result**: `docs/RAM_MAP.md` already exists with comprehensive coverage!

**Contents** (338 lines):
- Zero Page variables ($00-$FF)
- WRAM Low ($0200-$1FFF)
- WRAM Extended ($7E0000-$7EFFFF)
- Memory map diagrams
- Usage statistics and priorities

**Deliverable**: ✅ `docs/RAM_MAP.md` exists

---

### Issue #6: Create ROM Data Map
**Priority**: MEDIUM  
**Effort**: 4-6 hours  
**Status**: ✅ ALREADY EXISTS

**Description**: Document all data tables, graphics, text in ROM.

**Result**: `docs/ROM_DATA_MAP.md` already exists with comprehensive coverage!

**Contents** (721 lines):
- Bank-by-bank data organization
- Pointer tables
- Graphics data locations
- Text string locations
- Music/sound data

**Deliverable**: ✅ `docs/ROM_DATA_MAP.md` exists

---

### Issue #7: Standardize Hardware Register Names
**Priority**: MEDIUM  
**Effort**: 2 hours  
**Status**: ✅ COMPLETE

**Description**: Ensure all SNES hardware register references use consistent names.

**Result**: Replaced 105 numeric register references with symbolic names

**Completions**:
- ✅ Bank_02: 65 replacements (VRAM, CGRAM, OAM, Windows, Color Math, WRAM)
- ✅ Bank_0B: 19 replacements (Mode 7, BG, Screen, Color Math, WRAM)
- ✅ Bank_0C: 21 replacements (VRAM registers)
- ✅ Created `tools/standardize_registers.ps1` automation script
- ✅ Created `docs/HARDWARE_REGISTER_STANDARDIZATION.md` documentation
- ✅ 100% ROM match maintained (F71817F5...)

**Outcome**: All hardware register references now use consistent SNES_* symbolic names from `labels.asm`

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
**Status**: � IN PROGRESS (Phase 1 - Common System Constants)

**Description**: Extract magic numbers to named constants for better code readability.

**Note**: `src/include/ffmq_constants.inc` already exists with game-specific constants.
This task focuses on **system/technical constants** used in the actual code.

**Phase 1 - Common System Constants** (IMPLEMENTING):
- Boolean/state values: $00 (FALSE/OFF), $01 (TRUE/ON)
- Common bit flags: $80, $40, $20, $10, $08, $04, $02, $01
- Common init values for registers/counters

**Examples**:
```asm
; Instead of: LDA #$00
; Use: LDA #FALSE  or  LDA #INIT_ZERO

; Instead of: AND #$80
; Use: AND #BIT_7  or  AND #SIGN_BIT
```

**Deliverable**: Enhanced `src/asm/banks/labels.asm` with system constants section

---

## 📊 ISSUE STATISTICS

**Total Issues**: 11  
**High Priority**: 0 (all completed!)  
**Medium Priority**: 0 (all completed!)  
**Low Priority**: 4 (Issue #70 added)  
**Completed**: 8 (Issues #1, #2, #5, #6, #7, #10)  
**Skipped**: 2 (Issues #3, #4 - not needed)  
**In Progress**: 1 (Issue #70 - sprites)  
**Remaining**: 2 (Issues #8, #9 - optional enhancements)

**Status Breakdown**:
- 🟢 Complete: 8 (Issues #1, #2, #5, #6, #7, #10)
- ❌ Skipped: 2 (Issues #3, #4 - files already formatted)
- � In Progress: 1 (Issue #70 - sprite verification)
- �🔴 TODO: 2 (Issues #8, #9 - optional future work)

**Current Status**: 🎉 **ALL HIGH, MEDIUM, & QUALITY ISSUES COMPLETE!**  
**Latest Achievement**: ✅ Issue #10 Complete - Added 121 constants (both phases)

Remaining items are optional documentation enhancements for future work

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


