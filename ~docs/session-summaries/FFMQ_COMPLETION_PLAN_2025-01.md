# FFMQ Project Completion Plan

**Created:** 2025-01 Analysis Session
**Purpose:** Comprehensive plan to complete FFMQ disassembly, editors, and project format

---

## Project Architecture Overview

### Multi-Repo Structure

| Repository | Purpose | Primary Language |
|------------|---------|------------------|
| `ffmq-info` | Main disassembly, Python tools, documentation | Python/ASM |
| `logsmall/FFMQLib` | C# ROM reading library | C# .NET 10 |
| `GameInfo/Games/SNES/Final Fantasy Mystic Quest (SNES)` | Wiki content for Dark Repos | Wikitext/Markdown |

---

## Current Status Assessment

### 1. Disassembly (src/asm/)

**Raw Line Counts:**

| Bank | Original (banks/) | Documented | Status |
|------|-------------------|------------|--------|
| bank_00 | 22,839 lines | 12,795 lines | ~56% documented |
| bank_01 | 15,480 lines | 8,801 lines | ~57% documented |
| bank_02 | 12,262 lines | 8,382 lines | ~68% documented |
| bank_03 | 2,353 lines | 2,370 lines | ✅ Complete |
| bank_04 | 2,072 lines | 2,172 lines | ✅ Complete |
| bank_05 | 2,258 lines | 2,381 lines | ✅ Complete |
| bank_06 | 2,200 lines | 2,317 lines | ✅ Complete |
| bank_07 | 2,626 lines | 2,655 lines | ✅ Complete |
| bank_08 | 2,057 lines | 1,944 lines | ~94% documented |
| bank_09 | 2,082 lines | 1,836 lines | ~88% documented |
| bank_0A | 2,057 lines | 2,222 lines | ✅ Complete |
| bank_0B | 3,727 lines | 3,312 lines | ~89% documented |
| bank_0C | 4,226 lines | 3,831 lines | ~91% documented |
| bank_0D | 2,955 lines | 2,755 lines | ~93% documented |
| bank_0E | 2,051 lines | 2,781 lines | ✅ Complete |
| bank_0F | 2,054 lines | 2,246 lines | ✅ Complete |

**Core Code Coverage:**
- Banks 00-02 (main code): ~60% documented
- Banks 03-0F (data/specialized): ~95% documented
- **Overall Estimate:** ~70% raw disassembly documented

**Documentation Quality Issues:**
- Still using CODE_XXXXXX labels
- Missing routine purpose comments
- Missing input/output documentation
- Not fully integrated into build system

### 2. Python Tools (Complete ✅)

**Editor Suite Status (v1.1 - 17,550 lines):**

| Component | Status | Lines |
|-----------|--------|-------|
| Enemy System | ✅ Complete | 860 |
| Spell System | ✅ Complete | 750 |
| Item System | ✅ Complete | 600 |
| Dungeon System | ✅ Complete | 470 |
| Graphics System | ✅ Complete | 1,350 |
| Music System | ✅ Complete | 1,400 |
| Visual Editors | ✅ Complete | 1,660 |
| Dialog CLI | ⚠️ Partial | 379 |

**Dialog System:**
- 116 dialogs extractable
- 77 control codes mapped
- DTE compression working (57.9% savings)
- CLI needs completion

### 3. C# Library (FFMQLib)

**Implemented:**
- ✅ `FfmqTextDecoder.cs` (336 lines) - Text encoding/decoding
- ✅ `FfmqTextTables` - ROM offset tables for all text
- ✅ `FfmqMonster.cs` (141 lines) - Monster data structures
- ✅ `FfmqItem.cs` (260 lines) - Item/Weapon/Armor data
- ✅ `FfmqSpell.cs` - Spell data structures
- ✅ `FfmqEnums.cs` - Element/Status enums

**Missing:**
- ❌ Project file format (.giproj) support
- ❌ Full ROM writer
- ❌ Map/tile data reader
- ❌ Dialog system reader

### 4. Build System

**Current State:** Not functional for byte-perfect rebuild
- ❌ Build copies original ROM (dishonest match)
- ❌ Assets extracted but not integrated
- ❌ No incbin directives for graphics
- ❌ No db statements for data

---

## Completion Tasks

### Phase 1: Build System (Priority: HIGH)

**Goal:** Achieve honest progress tracking

1. **Remove ROM copying from build.ps1**
   - Delete `Copy-Item $baseRom $Output`
   - Build entirely from source
   - Accept low match % initially

2. **Integrate extracted assets**
   - Add `incbin` for graphics tiles
   - Add `incbin` for palettes
   - Add `db` statements for text
   - Add data tables for enemies/items

3. **Track real progress**
   - Match % = actual assembled bytes / ROM size
   - Log which sections build correctly

### Phase 2: Disassembly Completion (Priority: HIGH)

**Goal:** Complete banks 00-02 documentation

1. **Bank 00 (Core routines)**
   - Document boot sequence
   - Document interrupt handlers
   - Document main loop
   - Remaining: ~10,000 lines

2. **Bank 01 (Battle system)**
   - Document battle engine
   - Document AI routines
   - Remaining: ~6,600 lines

3. **Bank 02 (Menu/text)**
   - Document menu system
   - Document text engine
   - Remaining: ~3,800 lines

4. **Replace CODE_XXXXXX labels**
   - Create meaningful names
   - Document each routine's purpose
   - Add input/output comments

### Phase 3: Dialog CLI Completion (Priority: MEDIUM)

**Goal:** Full dialog editing workflow

1. **Complete import/export**
   - JSON export working
   - JSON import to ROM
   - Batch operations

2. **Add search functionality**
   - Search by text
   - Search by control code
   - Search by dialog ID

3. **Add batch operations**
   - Find/replace across all dialogs
   - Validate all dialogs
   - Stats reporting

### Phase 4: Universal Editor Integration (Priority: MEDIUM)

**Goal:** Unified editing experience

1. **Integrate all editors into game_editor.py**
   - Enemy editor tab
   - Spell editor tab
   - Item editor tab
   - Dialog editor tab

2. **Add project file format**
   - Save/load project state
   - Track modifications
   - Export modified ROM

### Phase 5: Project File Format (Priority: HIGH)

**Goal:** Create .giproj format for GameInfo universal editor

1. **Define .giproj specification**
   ```json
   {
     "version": "1.0",
     "game": "ffmq",
     "platform": "snes",
     "baseRom": {
       "sha256": "...",
       "name": "Final Fantasy - Mystic Quest (USA).sfc"
     },
     "modifications": {
       "enemies": [...],
       "items": [...],
       "dialogs": [...],
       "graphics": [...]
     },
     "assets": {
       "graphics/": "extracted graphics",
       "text/": "extracted text"
     }
   }
   ```

2. **Create C# project reader in FFMQLib**
   - Parse .giproj files
   - Apply modifications to ROM
   - Export patched ROM

3. **Create Python project support**
   - Load .giproj in game_editor.py
   - Save modifications to .giproj
   - Interoperability with C# tools

---

## Milestone Definitions

### Milestone 1: Honest Build (2 weeks)
- [ ] Build system creates ROM from source
- [ ] Match % reflects real progress
- [ ] Assets integrated with incbin

### Milestone 2: Complete Disassembly (4 weeks)
- [ ] Banks 00-02 fully documented
- [ ] All CODE_XXXXXX labels renamed
- [ ] Build achieves 50%+ match

### Milestone 3: Dialog System Complete (1 week)
- [ ] Full CLI functionality
- [ ] Round-trip editing verified
- [ ] Integration tests pass

### Milestone 4: Project Format (2 weeks)
- [ ] .giproj specification finalized
- [ ] C# reader/writer implemented
- [ ] Python interoperability working

### Milestone 5: Byte-Perfect Rebuild (6 weeks)
- [ ] 100% match achieved
- [ ] All assets from extracted sources
- [ ] Full documentation

---

## Quick Reference

### Key Files

| Purpose | Location |
|---------|----------|
| Main disassembly | `src/asm/bank_*_documented.asm` |
| Python tools | `tools/map-editor/`, `utils/` |
| C# library | `logsmall/FFMQLib/` |
| Documentation | `docs/` |
| Build script | `build.ps1` |

### Build Commands

```powershell
# Current (needs fixing)
.\build.ps1

# Run tests
python -m pytest tests/

# Extract text
python tools/extraction/extract_all_text.py roms/FFMQ.sfc

# Launch editor
python tools/map-editor/game_editor.py
```

### GitHub Project

All issues tracked at: https://github.com/users/TheAnsarya/projects/3

---

## What's Next

1. **Immediate:** Fix build.ps1 to remove ROM copying
2. **Short-term:** Complete dialog CLI
3. **Medium-term:** Document banks 00-02
4. **Long-term:** Achieve byte-perfect rebuild

---

*Last updated: 2025-01 Session*
