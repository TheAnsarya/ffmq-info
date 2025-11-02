# Phase 3: Extended Data Extraction & Editing Pipeline
**Final Fantasy Mystic Quest - Complete Asset Modding System**

## Overview

Phase 3 builds upon the successful graphics pipeline (Phase 2) to create a **complete ROM hacking toolchain** that enables editing of:
- **Additional Graphics**: Overworld, NPCs, magic effects, UI elements
- **Text/Dialogue**: Full text extraction, editing, and reinsertion
- **Maps**: Tiled-compatible map editing with full reinsertion
- **Music/Sound**: SPC extraction and metadata (exploration phase)
- **Data Tables**: Items, spells, enemies, stats (CSV/JSON editing)

## Phase 2 Achievements (Baseline)

✅ **Complete Graphics Pipeline**:
- Extract sprites → Edit PNGs → Rebuild binaries → Auto-generate ASM → Build ROM
- Single command workflow: `make rom-with-graphics`
- 89 sprites supported (83 enemies, 4 characters, 2 UI)
- Incremental builds with SHA256 tracking
- Production-ready documentation

## Phase 3 Objectives

### 1. Additional Graphics Extraction 🎨

**Priority: HIGH** | **Estimated: 8-12 hours**

#### 1.1 Overworld Graphics
- **Overworld Tiles**: Extract 8×8 and 16×16 map tiles
  - Locations: Banks $01-$03 (map tile data)
  - Format: 4BPP planar tiles
  - Output: PNG tilesheets with JSON metadata
  - Tools: Extend `extract_graphics.py` for tileset extraction

- **Overworld Sprites**: Characters, NPCs, objects
  - Benjamin walking sprites (4 directions × 3 frames)
  - NPC sprites (various characters)
  - Object sprites (chests, doors, switches)
  - Format: 4BPP, various dimensions
  - Output: Individual PNGs + sprite sheets

#### 1.2 Battle/Effect Graphics
- **Magic Effects**: Spell animations (Fire, Ice, Thunder, etc.)
  - Frame-by-frame animation tiles
  - Effect overlays and particles
  - Format: 4BPP, variable size
  
- **Battle UI**: Battle menus, status displays
  - HP/MP bars, command windows
  - Icons and indicators
  - Format: 2BPP/4BPP mixed

#### 1.3 Additional UI Graphics
- **Menu Graphics**: Title screen, main menu, save screen
- **Font Graphics**: Complete character set extraction
- **Icon Set**: Items, spells, status icons
- **Borders/Windows**: Dialogue boxes, menu frames

**Deliverables**:
- `tools/extract_overworld.py` - Overworld tile/sprite extractor
- `tools/extract_effects.py` - Magic effect extractor
- `tools/extract_ui.py` - UI element extractor
- `tools/import/import_overworld.py` - Overworld reimporter
- Extended `build_integration.py` to handle all graphics types
- Updated Makefile targets for new graphics categories

---

### 2. Text/Dialogue Extraction & Editing 📝

**Priority: HIGH** | **Estimated: 10-14 hours**

#### 2.1 Enhanced Text Extraction
**Current State**: Basic `extract_text.py` exists, partial extraction to `text_data.json`

**Improvements Needed**:
- **Complete Character Table**: Full FFMQ character mapping (including special chars)
- **Dialogue Pointers**: Extract pointer tables for all text sections
- **Text Compression**: Handle FFMQ's text compression/encoding
- **Text Categories**:
  - Story dialogue (NPCs, cutscenes)
  - Battle text (enemy names, spell names, item names)
  - Menu text (commands, options)
  - Item/spell descriptions
  - Character names
  - Location names
  - Tutorial/help text

#### 2.2 Text Editing Pipeline
**Goal**: Make text editing as easy as graphics editing

**Workflow**:
```bash
make text-extract        # Extract all text to data/extracted/text/
# Edit .txt or .json files
make rom-with-text      # Rebuild ROM with modified text
```

**Components**:
- `tools/import/import_text.py` - Text reimporter
  - Parse edited text files
  - Re-encode with FFMQ character table
  - Apply compression if needed
  - Validate text fits in original space
  
- `tools/text_integration.py` - Text build integration
  - SHA256 tracking for changed text files
  - Automatic pointer recalculation
  - ASM generation for text data
  - Overflow detection (text too long)

#### 2.3 Text Format
**JSON Structure** (enhanced):
```json
{
  "dialogue": {
    "npc_001": {
      "id": "npc_001",
      "location": "Hill of Destiny",
      "speaker": "Old Man",
      "text": "Welcome to the world\nof Final Fantasy!",
      "address": "0x0B1234",
      "max_length": 64
    }
  },
  "items": {
    "cure_potion": {
      "name": "Cure Potion",
      "description": "Restores 30 HP",
      "address": "0x0B5678",
      "max_length": 16
    }
  }
}
```

**Deliverables**:
- Enhanced `tools/extract_text.py` with complete character table
- `tools/import/import_text.py` - Text reimporter
- `tools/text_integration.py` - Text build integration
- `docs/TEXT_EDITING.md` - Text editing guide
- Makefile targets: `text-extract`, `text-rebuild`, `rom-with-text`

---

### 3. Map Extraction & Editing 🗺️

**Priority: MEDIUM** | **Estimated: 12-16 hours**

#### 3.1 Enhanced Map Extraction
**Current State**: Partial extraction to `maps_data.json`

**Improvements Needed**:
- **Tiled TMX Export**: Export maps in Tiled editor format
- **Tileset Integration**: Link to extracted overworld tiles
- **Layer Support**: Separate layers for terrain, objects, events
- **Collision Data**: Extract walkability/collision maps
- **Event Triggers**: NPC positions, chest locations, door links
- **Map Properties**: Metadata (music, palette, encounters)

#### 3.2 Map Editing Pipeline
**Goal**: Edit maps in professional tools (Tiled), reinsert to ROM

**Workflow**:
```bash
make maps-extract        # Extract all maps to .tmx files
# Edit in Tiled editor
make rom-with-maps      # Rebuild ROM with modified maps
```

#### 3.3 Tiled Integration
**TMX Format** (example):
```xml
<map version="1.0" orientation="orthogonal" width="32" height="32" tilewidth="16" tileheight="16">
  <tileset name="overworld" tilewidth="16" tileheight="16">
    <image source="../../graphics/overworld_tiles.png" width="256" height="256"/>
  </tileset>
  <layer name="Terrain" width="32" height="32">
    <data encoding="csv">
      1,2,3,4,5,6,7,8,...
    </data>
  </layer>
  <layer name="Objects" width="32" height="32">
    <data encoding="csv">
      0,0,12,0,0,15,0,0,...
    </data>
  </layer>
  <objectgroup name="Events">
    <object id="1" name="NPC_001" x="128" y="192" type="npc"/>
    <object id="2" name="CHEST_001" x="256" y="128" type="chest"/>
  </objectgroup>
</map>
```

**Components**:
- `tools/extract_maps.py` (enhanced) - Full map extraction with TMX export
- `tools/import/import_maps.py` - TMX → ROM map data converter
- `tools/map_integration.py` - Map build integration
- Collision map handling
- Event trigger preservation

**Deliverables**:
- Enhanced `tools/extract_maps.py` with TMX export
- `tools/import/import_maps.py` - Map reimporter
- `tools/map_integration.py` - Map build integration
- `docs/MAP_EDITING.md` - Map editing guide with Tiled instructions
- Makefile targets: `maps-extract`, `maps-rebuild`, `rom-with-maps`

---

### 4. Music/Sound Exploration 🎵

**Priority: LOW** | **Estimated: 6-10 hours**

**Goal**: Extract music for analysis, possibly enable editing (stretch goal)

#### 4.1 SPC Extraction
- Extract SPC700 music sequences
- Export to .spc files (playable in emulators)
- Document music metadata (tempo, instruments, patterns)

#### 4.2 Sound Effects
- Extract sound effect data
- Catalog sound IDs and usage
- Document trigger points in code

**Note**: Full music editing may require specialized tools (SNESMOD, etc.)

**Deliverables**:
- `tools/extract_music.py` (enhanced) - SPC extraction
- `tools/extract_sfx.py` - Sound effect extraction
- `docs/MUSIC_REFERENCE.md` - Music/sound documentation
- Exploration only, reinsertion optional

---

### 5. Data Tables Extraction 📊

**Priority: MEDIUM** | **Estimated: 8-12 hours**

**Goal**: Make game data (items, spells, enemies, stats) editable via CSV/JSON

#### 5.1 Data Categories
- **Items**: Names, descriptions, effects, prices, stats
- **Spells**: Names, costs, power, animations
- **Enemies**: Names, HP, stats, drops, AI
- **Weapons/Armor**: Equipment stats, bonuses
- **Character Stats**: Level-up tables, base stats
- **Shop Data**: Shop inventory, prices
- **Chest Data**: Contents, locations (already partially done)
- **Encounter Tables**: Enemy formations per map area

#### 5.2 Editing Pipeline
**Workflow**:
```bash
make data-extract       # Extract all tables to CSV/JSON
# Edit in Excel, text editor, etc.
make rom-with-data     # Rebuild ROM with modified data
```

**Components**:
- `tools/extract_tables.py` - Extract all data tables
- `tools/import/import_tables.py` - Table reimporter
- `tools/data_integration.py` - Data build integration

**Deliverables**:
- `tools/extract_tables.py` - Complete table extraction
- `tools/import/import_tables.py` - Table reimporter
- `tools/data_integration.py` - Data build integration
- `docs/DATA_EDITING.md` - Data editing guide
- Makefile targets: `data-extract`, `data-rebuild`, `rom-with-data`

---

## Unified Build System 🏗️

**Goal**: Single command to rebuild ROM with ALL modifications

### Master Makefile Targets

```makefile
# Individual pipelines
make graphics-pipeline    # Rebuild graphics
make text-pipeline       # Rebuild text
make maps-pipeline       # Rebuild maps
make data-pipeline       # Rebuild data tables

# Complete rebuild
make rom-full           # Rebuild ROM with ALL modifications
```

### Unified Integration Tool

**`tools/master_integration.py`**:
- Orchestrates all pipelines
- Tracks changes across all data types
- Generates master ASM include file
- Single build manifest for everything
- Validates no address conflicts

```bash
python tools/master_integration.py --full    # Full rebuild
python tools/master_integration.py          # Incremental
```

---

## Implementation Plan

### Phase 3.1: Additional Graphics (Week 1)
1. Create overworld extraction tools
2. Create effect extraction tools
3. Extend import pipeline for new graphics
4. Update build_integration.py
5. Add Makefile targets
6. Documentation

### Phase 3.2: Text Pipeline (Week 2)
1. Enhance text extraction (character table, pointers)
2. Create text import tool
3. Create text_integration.py
4. Add Makefile targets
5. Documentation

### Phase 3.3: Map Pipeline (Week 2-3)
1. Enhance map extraction with TMX export
2. Create map import tool (TMX → ROM)
3. Create map_integration.py
4. Add Makefile targets
5. Tiled integration documentation

### Phase 3.4: Data Tables (Week 3)
1. Create comprehensive table extraction
2. Create table import tools
3. Create data_integration.py
4. Add Makefile targets
5. Documentation

### Phase 3.5: Music Exploration (Week 4)
1. Enhance music extraction
2. Create sound effect extraction
3. Documentation only
4. Reinsertion optional/future work

### Phase 3.6: Unified System (Week 4)
1. Create master_integration.py
2. Update Makefile with master targets
3. Create comprehensive documentation
4. Testing and validation

---

## Success Criteria

✅ **Complete Asset Extraction**:
- All graphics extractable and editable
- All text extractable and editable
- All maps extractable and editable (via Tiled)
- All data tables extractable and editable

✅ **Professional Workflow**:
- Single command extraction per category
- Single command rebuild per category
- Master command for complete ROM rebuild
- Incremental builds (only rebuild changed assets)

✅ **Quality Documentation**:
- User-friendly guides for each system
- Technical reference documentation
- Example workflows and tutorials
- Troubleshooting guides

✅ **Production Ready**:
- Round-trip validation (extract → edit → reinsert → verify)
- No data loss or corruption
- Comprehensive error handling
- Automated testing

---

## Expected Deliverables

### Tools (Python)
- `tools/extract_overworld.py` - Overworld graphics extractor
- `tools/extract_effects.py` - Effect graphics extractor
- `tools/extract_ui.py` - UI graphics extractor
- `tools/import/import_overworld.py` - Overworld reimporter
- Enhanced `tools/extract_text.py` - Complete text extractor
- `tools/import/import_text.py` - Text reimporter
- `tools/text_integration.py` - Text build integration
- Enhanced `tools/extract_maps.py` - TMX map exporter
- `tools/import/import_maps.py` - TMX map importer
- `tools/map_integration.py` - Map build integration
- `tools/extract_tables.py` - Data table extractor
- `tools/import/import_tables.py` - Table reimporter
- `tools/data_integration.py` - Data build integration
- `tools/master_integration.py` - Unified build system
- Enhanced `tools/extract_music.py` - Music/SPC extractor
- `tools/extract_sfx.py` - Sound effect extractor

### Documentation (Markdown)
- `docs/TEXT_EDITING.md` - Text editing guide
- `docs/MAP_EDITING.md` - Map editing guide (with Tiled)
- `docs/DATA_EDITING.md` - Data table editing guide
- `docs/MUSIC_REFERENCE.md` - Music/sound reference
- `docs/MASTER_WORKFLOW.md` - Complete workflow guide
- `docs/PHASE_3_COMPLETE.md` - Achievement summary

### Makefile Targets
- Graphics: `graphics-pipeline` (already exists)
- Text: `text-extract`, `text-rebuild`, `text-pipeline`, `rom-with-text`
- Maps: `maps-extract`, `maps-rebuild`, `maps-pipeline`, `rom-with-maps`
- Data: `data-extract`, `data-rebuild`, `data-pipeline`, `rom-with-data`
- Master: `rom-full` (complete rebuild)

---

## Timeline Estimate

- **Phase 3.1** (Graphics): 8-12 hours
- **Phase 3.2** (Text): 10-14 hours
- **Phase 3.3** (Maps): 12-16 hours
- **Phase 3.4** (Data): 8-12 hours
- **Phase 3.5** (Music): 6-10 hours
- **Phase 3.6** (Integration): 4-6 hours

**Total**: 48-70 hours (~2-3 weeks of full-time work)

---

## Next Steps

1. ✅ Create this plan document
2. Start with **Phase 3.1** (Additional Graphics) - highest value
3. Build incrementally, test after each component
4. Document as we go
5. Commit regularly to preserve progress

**Let's begin with overworld graphics extraction!** 🚀
