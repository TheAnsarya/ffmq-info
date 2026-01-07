# Final Fantasy: Mystic Quest (SNES) - How to Finish This Project

**Project Completion Roadmap & Current Status**

This document tracks what's needed to consider the FFMQ disassembly project "complete."

## 📊 Current Status: ~30% Complete

FFMQ is a relatively simple SNES RPG but still requires significant work to complete.

### ✅ Completed Work

#### Infrastructure (100%)
- [x] Project structure established
- [x] GitHub repository configured
- [x] Comprehensive .github setup (issues, templates)
- [x] Python tools framework
- [x] VS Code workspace
- [x] JSON schemas defined
- [x] Build system (asar-based)

#### Asset Extraction (60%)
- [x] Graphics tiles extracted (9,295 tiles → PNG)
- [x] Palettes extracted (36 palettes)
- [x] Text strings extracted (679 strings)
- [x] Dialog extracted (245 strings)
- [x] Enemy data extracted (215 enemies → CSV/JSON)
- [x] Item data extracted (67 items)
- [x] Spell data extracted (JSON)
- [x] Weapon/armor data extracted

#### Raw Disassembly (40%)
- [x] Bank $00 raw disassembly generated
- [x] Banks $01-$0F raw disassembly exists
- [x] CODE_XXXXXX labels from DiztinGUIsh
- [x] Initial Mesen label files

#### Documentation (50%)
- [x] Extensive docs folder (~100+ files)
- [x] Memory map basics
- [x] Battle system analysis
- [x] Text systems analysis
- [x] Save system documentation
- [x] Audio system overview
- [x] DataCrystal content

---

## 🔲 Remaining Work

### 1. Code Disassembly Completion (Priority: CRITICAL)
**Estimated effort: 80-150 hours**

FFMQ has ~16 PRG banks (~512KB code/data).

Current state: Raw disassembly with CODE_XXXXXX labels.
Target state: Fully commented with meaningful labels.

- [ ] **Bank $00** - Core engine
  - Replace CODE_XXXXXX with meaningful names
  - Add function header comments
  - Document inputs/outputs

- [ ] **Bank $01-$05** - Game logic
  - Battle system
  - Menu systems  
  - Event handling

- [ ] **Bank $06-$0B** - Data banks
  - Map data
  - Enemy data
  - Item tables

- [ ] **Bank $0C-$0F** - Graphics/audio
  - Graphics decompression
  - SPC700 driver

- [ ] **Label inventory** - Track all labels
- [ ] **Cross-reference** - Document call relationships

### 2. Build System Integration (Priority: CRITICAL)
**Estimated effort: 40-60 hours**

The build currently copies the original ROM and patches over it - this is NOT true disassembly!

- [ ] **Clean build** - Assemble from source only
  - No binary ROM copying
  - All code from .asm files
  - All data from extracted assets

- [ ] **Asset pipeline integration**
  - Graphics: PNG → incbin
  - Palettes: JSON → db statements
  - Text: TXT → db statements
  - Enemies: JSON → db statements
  - Items: JSON → db statements

- [ ] **Maps extraction** - Not yet done
- [ ] **Audio extraction** - SPC700 data not extracted

### 3. Asset Extraction Completion (Priority: HIGH)
**Estimated effort: 20-30 hours**

- [ ] **Maps** - All map data
  - World map
  - Dungeon layouts
  - Town layouts
  - NPC positions
  - Chest contents
  - Trigger zones

- [ ] **Audio** - SPC700
  - BGM tracks
  - Sound effects
  - Instrument samples

- [ ] **Verify existing extractions**
  - Cross-check enemy stats
  - Verify item data
  - Validate spell effects

### 4. Dark Repos Wiki (Priority: HIGH)
**Estimated effort: 20-30 hours**

Wiki pages in `GameInfo/DarkRepos/Wiki/SNES/Final_Fantasy_Mystic_Quest/`:

Existing pages need completion:
- [ ] **ROM_Map.wikitext** - Complete all banks
- [ ] **RAM_Map.wikitext** - Complete WRAM
- [ ] **SRAM_Map.wikitext** - Save data format

New pages needed:
- [ ] **Monster_Data.wikitext** - 215 enemies
- [ ] **Boss_Data.wikitext** - Boss specifics
- [ ] **Items.wikitext** - 67 items
- [ ] **Weapons.wikitext** - Weapon progression
- [ ] **Armor.wikitext** - Armor/accessories
- [ ] **Magic.wikitext** - Spell list and effects
- [ ] **Battle_System.wikitext** - Damage formulas
- [ ] **Battlefields.wikitext** - Field mechanics
- [ ] **Companion_System.wikitext** - Partner mechanics
- [ ] **TBL.wikitext** - Text encoding
- [ ] **Glitches.wikitext** - Exploits
- [ ] **Secrets.wikitext** - Hidden content

### 5. Tool Enhancements (Priority: MEDIUM)
**Estimated effort: 15-25 hours**

- [ ] **Enemy editor** - GUI for 215 enemies
- [ ] **Item editor** - All item properties
- [ ] **Map viewer** - Visual maps
- [ ] **Spell editor** - Magic effects
- [ ] **Battlefield editor** - Custom battlefields
- [ ] **Text editor** - Dialog editing

---

## 🎯 Definition of "Complete"

1. **Clean Build** - ROM assembles from source without copying original
2. **100% Labeled** - No CODE_XXXXXX labels remain
3. **100% Commented** - All routines documented
4. **All Assets Extracted** - Maps, audio included
5. **Asset Pipeline** - JSON/PNG → ASM automated
6. **Working Tools** - Can edit any game aspect
7. **Complete Wiki** - All Dark Repos pages populated

---

## 📋 FFMQ Specifics

| Feature | Value | Notes |
|---------|-------|-------|
| ROM Size | 1MB | LoROM mapping |
| Banks | ~16 | 32KB each |
| Enemies | 215 | Including palette swaps |
| Items | 67 | Weapons, armor, consumables |
| Spells | ~20 | White/Black/Wizard |
| Partners | 4 | Kaeli, Tristam, Phoebe, Reuben |
| Battlefields | 10 | Optional combat zones |

---

## 🗓️ Suggested Timeline

### Phase 1: Build System (Weeks 1-3)
- Establish clean build (no ROM copying)
- Integrate existing extracted assets
- Verify byte-perfect match

### Phase 2: Disassembly Polish (Weeks 4-8)
- Rename all CODE_XXXXXX labels
- Add comments to all routines
- Document all data tables

### Phase 3: Missing Extractions (Weeks 9-10)
- Extract map data
- Extract audio data
- Complete asset pipeline

### Phase 4: Wiki & Tools (Weeks 11-12)
- Complete Dark Repos wiki
- Polish editing tools
- Final documentation

---

## 📁 Key File Locations

| Content | Location |
|---------|----------|
| Disassembly source | `src/` |
| Extracted assets | `assets/` |
| DataCrystal content | `datacrystal/` |
| Wiki content | `GameInfo/DarkRepos/Wiki/SNES/Final_Fantasy_Mystic_Quest/` |
| Tools | `tools/` |
| Build output | `build/` |
| Documentation | `docs/` |
| Mesen labels | `labels/` |

---

## 📝 GitHub Issues to Create

### Epic Issues
1. `epic: Complete FFMQ Clean Build System`
2. `epic: Label All FFMQ Code`
3. `epic: Complete FFMQ Asset Pipeline`
4. `epic: Complete FFMQ Dark Repos Wiki`

### Major Tasks
5. `task: Integrate graphics into build pipeline`
6. `task: Integrate text strings into build`
7. `task: Extract map data`
8. `task: Extract SPC700 audio`
9. `task: Rename Bank $00 CODE_XXXXXX labels`
10. `task: Document battle damage formulas`
11. `task: Create enemy editor GUI`
12. `task: Complete ROM_Map wiki page`

---

## 🔗 Related Resources

- [Data Crystal - FFMQ](https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest)
- [RHDN - FFMQ](https://www.romhacking.net/games/377/)
- [FFMQ Speedrun Wiki](https://speedrun.com/ffmq)
- [asar Assembler](https://github.com/RPGHacker/asar)

---

## 📊 Honest Progress Tracking

See [HONEST_PROGRESS.md](HONEST_PROGRESS.md) for detailed breakdown of actual progress vs. inflated metrics.

Key insight: A "99.996% match" is meaningless if you're copying the original ROM. True progress is measured by:
- Lines of commented assembly
- Assets integrated into build
- Clean compilation without binary blobs

---

*Last updated: 2025*
