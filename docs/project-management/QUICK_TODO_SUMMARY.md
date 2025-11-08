# FFMQ Project - Quick TODO Summary
**Date**: October 31, 2025

## 🏆 RECENT ACHIEVEMENT
**Bank 01: 100% COMPLETE!** (Batch 38 - 103 labels eliminated)
- **SIXTH bank** at 100% completion
- **95% campaign completion** (1,539 → 68 labels remaining)
- All battle systems fully documented

---

## 🎯 IMMEDIATE NEXT STEPS (1-2 weeks)

### 1. ✅ Finish Code Labeling (8-12 hours)
**Goal**: Eliminate final 68 CODE_* labels → **100% CAMPAIGN COMPLETION!** 🏆

**Remaining**:
- `bank_00_section2.asm` - 8 labels
- `bank_00_section3.asm` - 10 labels  
- `bank_00_section4.asm` - 20 labels
- `bank_00_section5.asm` - 30 labels

**Priority**: HIGH - Near completion, big milestone

---

### 2. 🎨 ASM Code Formatting (16-24 hours)
**Goal**: Standardize all ASM files with consistent formatting

**Requirements**:
- Line endings: CRLF (`\r\n`)
- Encoding: UTF-8
- Indentation: **TABS** (not spaces)
- Tab display: 4 spaces per tab
- Column alignment: Labels, opcodes, operands, comments

**Action**:
1. Create `.editorconfig` file
2. Create `tools/format_asm.ps1` script
3. Test on one file → verify ROM match
4. Apply to all 16+ ASM files
5. Commit each file individually

**Priority**: HIGH - Foundation for maintainability
**Critical**: MUST maintain 100% ROM match!

---

### 3. 📚 Basic Documentation (8-12 hours)
**Goal**: Write essential docs for contributors

**Docs to Create**:
- `docs/ARCHITECTURE.md` - High-level ROM overview
- `docs/BUILD_GUIDE.md` - How to build the ROM
- `docs/MODDING_GUIDE.md` - Quick start for modders

**Priority**: HIGH - Enables collaboration

---

## 📋 SHORT-TERM (1-2 months)

### 4. 🏷️ Memory Address Labels (20-30 hours)
- Replace raw addresses (`$1234`) with meaningful names (`g_PlayerHP`)
- Start with most-used variables (biggest impact)
- Create `docs/RAM_MAP.md` and `docs/ROM_DATA_MAP.md`

### 5. 🖼️ Graphics Extraction (30-40 hours)
- Extract all character/enemy/UI sprites → PNG
- Extract all palettes → PNG swatches + JSON
- Create sprite sheets with multiple palette views
- Generate visual asset catalog (HTML browser)

### 6. 📦 Data Extraction (20-30 hours)
- Extract all text → JSON (translation-ready)
- Extract all stats/items/spells → JSON/CSV
- Extract all maps → JSON
- Decompress and document all data structures

---

## 🗺️ MID-TERM (3-6 months)

### 7. 🔍 Finish Disassembly (120-180 hours)
- Banks $04, $05, $06 (data banks, ~12k lines)
- Banks $0e, $0f (unknown, ~10k lines)
- Complete system documentation

### 8. 🔄 Asset Build System (40-50 hours)
- Create import tools (PNG→SNES, JSON→binary)
- Orchestrate full build pipeline
- Test round-trip: extract → import → identical ROM
- Enable ROM hacking workflow

### 9. 📚 Complete Documentation (80-120 hours)
- Document all systems (battle, graphics, sound, text, map)
- Document all functions (~500+ functions)
- Document all data structures
- Create tutorials and guides

---

## 📊 PROJECT STATUS

| Category | Progress | Remaining Hours |
|----------|----------|-----------------|
| Code Labeling | 95% | 8-12 |
| Code Disassembly | 70% | 120-180 |
| ASM Formatting | 0% | 16-24 |
| Memory Labels | 0% | 40-60 |
| Graphics Extraction | 5% | 60-80 |
| Data Extraction | 5% | 40-60 |
| Asset Build System | 0% | 40-50 |
| Documentation | 30% | 80-120 |
| **TOTAL** | **~35%** | **584-846** |

**Estimated Completion**:
- At 20 hrs/week: 7-10 months
- At 40 hrs/week: 4-5 months

---

## 🚀 QUICK START

**To finish code labeling**:
```powershell
# Analyze section files
grep -n "^CODE_00" src/asm/bank_00_section*.asm

# Rename labels (create PowerShell batch)
# Build and verify ROM match
.\build.ps1
```

**To start formatting**:
```powershell
# Create .editorconfig
# Create tools/format_asm.ps1
# Test on one file
.\tools\format_asm.ps1 -File "src/asm/bank_00_documented.asm" -DryRun
```

**To extract graphics**:
```powershell
# Use existing tool
python tools/rom_extractor.py --bank 09 --output assets/graphics/
```

---

## 📌 KEY FILES

- `TODO.md` - Complete detailed roadmap (this summary's source)
- `CAMPAIGN_PROGRESS.md` - Label elimination tracking
- `build.ps1` - ROM build script (asar assembler)
- `tools/update_chat_log.py` - Session logging
- `src/asm/bank_*_documented.asm` - Documented source files

---

**See `TODO.md` for complete details, action items, and estimates!**
