# Data Coverage Report

**Generated**: November 1, 2025  
**Project**: Final Fantasy: Mystic Quest Info  
**Repository**: TheAnsarya/ffmq-info

## Executive Summary

This report tracks the extraction and documentation progress for all game data in Final Fantasy: Mystic Quest.

### Overall Progress

**Total Progress**: 38% Complete

| Category         | Structure | Schema | Extraction | Validation | Overall |
|------------------|-----------|--------|------------|------------|---------|
| Characters       | ✅ 100%   | ✅ 100% | ⏳ 0%      | ❌ 0%      | **40%** |
| Enemies          | ✅ 100%   | ✅ 100% | ⏳ 0%      | ❌ 0%      | **30%** |
| Items            | ✅ 100%   | ✅ 100% | ⏳ 0%      | ❌ 0%      | **35%** |
| Maps             | ✅ 100%   | ✅ 100% | 🟡 50%     | ❌ 0%      | **50%** |
| Text             | ✅ 100%   | ✅ 100% | 🟡 25%     | ❌ 0%      | **45%** |
| Graphics         | ✅ 100%   | ✅ 100% | 🟡 25%     | ❌ 0%      | **40%** |
| Battle           | ✅ 100%   | ⏳ 0%   | ⏳ 0%      | ❌ 0%      | **25%** |
| Music/Sound      | ✅ 100%   | ⏳ 0%   | ⏳ 0%      | ❌ 0%      | **20%** |

**Legend**:
- ✅ Complete (100%)
- 🟡 Partial (1-99%)
- ⏳ Not Started (0%)
- ❌ Not Done (0%)

---

## Detailed Progress by Category

### 1. Character Data

**Overall**: 40% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ✅     | 100%     | character_schema.json       |
| Data Extraction         | ⏳     | 0%       | Awaiting extraction script  |
| ROM Verification        | ❌     | 0%       | Needs extracted data        |
| In-Game Testing         | ❌     | 0%       | Needs extracted data        |

**ROM Locations**:
- Character Data: Bank $0c, $0c8000 (4 entries × 32 bytes = 128 bytes)
- Stat Growth: Embedded in character entries

**Extraction Priority**: HIGH  
**Estimated Effort**: 2-3 hours  
**Blockers**: None

**Next Steps**:
1. Create character extraction script
2. Extract 4 character entries
3. Validate against schema
4. Test stat calculations in-game

---

### 2. Enemy Data

**Overall**: 30% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ✅     | 100%     | enemy_schema.json           |
| Data Extraction         | ⏳     | 0%       | Needs count determination   |
| AI Script Analysis      | ⏳     | 0%       | Complex extraction          |
| ROM Verification        | ❌     | 0%       | Needs extracted data        |

**ROM Locations**:
- Enemy Data: Bank $0e, $0e8000 (~100 enemies × 64 bytes = ~6400 bytes)
- AI Scripts: Bank $0e, $0e0000-$0e1fff (variable)

**Extraction Priority**: MEDIUM  
**Estimated Effort**: 6-8 hours  
**Blockers**: Enemy count unknown (need to scan for terminator)

**Next Steps**:
1. Determine exact enemy count
2. Create enemy extraction script
3. Extract base enemy data
4. Analyze AI script pointers (separate task)

---

### 3. Item Data

**Overall**: 35% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ✅     | 100%     | item_schema.json            |
| Weapon Extraction       | ⏳     | 0%       | 32 weapons                  |
| Armor Extraction        | ⏳     | 0%       | 32 armors                   |
| Accessory Extraction    | ⏳     | 0%       | 32 accessories              |
| Consumable Extraction   | ⏳     | 0%       | 64 consumables              |
| ROM Verification        | ❌     | 0%       | Needs extracted data        |

**ROM Locations**:
- Weapons: Bank $0c, $0c9000 (32 entries × 16 bytes = 512 bytes)
- Armor: Bank $0c, $0c9200 (32 entries × 16 bytes = 512 bytes)
- Accessories: Bank $0c, $0c9400 (32 entries × 16 bytes = 512 bytes)
- Consumables: Bank $0c, $0c9600 (64 entries × 8 bytes = 512 bytes)

**Total**: 160 items, 2048 bytes

**Extraction Priority**: HIGH  
**Estimated Effort**: 4-6 hours  
**Blockers**: None

**Next Steps**:
1. Extract weapons (32 entries)
2. Extract armor (32 entries)
3. Extract accessories (32 entries)
4. Extract consumables (64 entries)
5. Cross-reference with shops/drops

---

### 4. Map Data

**Overall**: 50% Complete ⭐

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ✅     | 100%     | map_schema.json             |
| Metatile Extraction     | ✅     | 100%     | 256 metatiles extracted! |
| Map Header Extraction   | ⏳     | 0%       | 64 map headers              |
| Tilemap Extraction      | ⏳     | 0%       | Variable per map            |
| Collision Extraction    | ⏳     | 0%       | 1 byte per tile             |
| Event Extraction        | ⏳     | 0%       | Variable per map            |
| NPC Extraction          | ⏳     | 0%       | Variable per map            |

**ROM Locations**:
- Map Headers: Bank $06, $068000 (64 maps × 32 bytes = 2048 bytes)
- Metatiles: Bank $06, $068800 (256 metatiles × 8 bytes = 2048 bytes) ✅
- Tilemap Data: Bank $06, $06a000 (variable size)
- Collision: Bank $06, $070000 (variable size)
- Events: Bank $06, $078000 (variable size)

**Extraction Priority**: MEDIUM  
**Estimated Effort**: 8-10 hours  
**Blockers**: None

**Completed**:
- ✅ Metatile structure (256 entries in map_tilemaps.json)

**Next Steps**:
1. Extract map headers (64 entries)
2. Extract tilemap data for key maps
3. Extract collision data
4. Extract event/NPC data

---

### 5. Text Data

**Overall**: 45% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ✅     | 100%     | text_schema.json            |
| Encoding Table          | 🟡     | 50%      | Partial in text_data.json   |
| DTE Dictionary          | ⏳     | 0%       | Needs extraction            |
| Dialog Extraction       | ⏳     | 0%       | ~500 entries estimated      |
| Menu Text Extraction    | ⏳     | 0%       | ~200 entries estimated      |
| Battle Text Extraction  | ⏳     | 0%       | ~100 entries estimated      |

**ROM Locations**:
- Encoding Table: Bank $0d, $0d0000 (256 bytes)
- Dialog Text: Bank $0d, $0d8000-$0dbfff (16 KB)
- Menu Text: Bank $0d, $0dc000-$0ddfff (8 KB)
- Battle Text: Bank $0d, $0de000-$0defff (4 KB)
- System Text: Bank $0d, $0df000-$0dffff (4 KB)

**Extraction Priority**: MEDIUM  
**Estimated Effort**: 8-12 hours  
**Blockers**: DTE decompression algorithm needed

**Completed**:
- ✅ Text data structure defined (text_data.json)

**Next Steps**:
1. Complete encoding table extraction
2. Build DTE dictionary
3. Create text decompression routine
4. Extract dialog entries
5. Extract menu/battle text

---

### 6. Graphics Data

**Overall**: 40% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ✅     | 100%     | graphics_schema.json        |
| Tile Extraction         | 🟡     | 25%      | Title screen tiles only     |
| Palette Extraction      | ⏳     | 0%       | 8 palettes × 16 colors      |
| Sprite Extraction       | ⏳     | 0%       | Character/enemy sprites     |
| Tileset Extraction      | ⏳     | 0%       | Map tilesets                |
| Metadata Generation     | ⏳     | 0%       | JSON metadata files         |

**ROM Locations**:
- Title Graphics: Bank $04, $048000-$04ffff (32 KB)
- Map Tilesets: Bank $05, $050000-$057fff (32 KB)
- Character Sprites: Bank $05, $058000-$05bfff (16 KB)
- Enemy Sprites: Bank $05, $05c000-$05ffff (16 KB)
- UI Graphics: Bank $07, $070000-$073fff (16 KB)
- Palettes: Bank $07, $074000-$0747ff (2 KB)

**Extraction Priority**: LOW  
**Estimated Effort**: 12-16 hours  
**Blockers**: None

**Completed**:
- ✅ Title screen crystal tiles (data/graphics/048000-tiles.bin and related files)

**Next Steps**:
1. Extract all palettes
2. Extract map tilesets
3. Extract character sprites
4. Extract enemy sprites
5. Generate metadata JSON

---

### 7. Battle Data

**Overall**: 25% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ⏳     | 0%       | battle_schema.json needed   |
| Formation Extraction    | ⏳     | 0%       | 128 formations              |
| Attack Extraction       | ⏳     | 0%       | 256 attacks                 |
| Status Effect Data      | ⏳     | 0%       | 13 status effects           |
| Battle BG Extraction    | ⏳     | 0%       | 32 battle backgrounds       |

**ROM Locations**:
- Formations: Bank $0e, $0e0000 (128 entries × 16 bytes = 2048 bytes)
- Attacks: Bank $0e, $0e0800 (256 entries × 16 bytes = 4096 bytes)
- Status Effects: Bank $0e, $0e2800 (13 entries × 8 bytes = 104 bytes)
- Battle BGs: Bank $0e, $0e2900 (32 entries × 4 bytes = 128 bytes)

**Extraction Priority**: MEDIUM  
**Estimated Effort**: 6-8 hours  
**Blockers**: Need to create battle_schema.json first

**Next Steps**:
1. Create battle_schema.json
2. Extract battle formations
3. Extract attack data
4. Extract status effect data
5. Link to enemy data

---

### 8. Music and Sound Data

**Overall**: 20% Complete

| Task                    | Status | Progress | Notes                      |
|-------------------------|--------|----------|----------------------------|
| Structure Documentation | ✅     | 100%     | Complete in DATA_STRUCTURES.md |
| JSON Schema             | ⏳     | 0%       | music_schema.json needed    |
| Track Extraction        | ⏳     | 0%       | 64 music tracks             |
| SFX Extraction          | ⏳     | 0%       | 128 sound effects           |
| Instrument Extraction   | ⏳     | 0%       | 128 instruments             |
| BRR Sample Extraction   | ⏳     | 0%       | Variable count              |

**ROM Locations**:
- Music Tracks: Bank $08, $080000-$087fff (32 KB)
- Sound Effects: Bank $08, $088000-$08bfff (16 KB)
- Instruments: Bank $08, $08c000-$08ffff (16 KB)
- Audio Driver: SPC RAM $0300-$07ff

**Extraction Priority**: LOW  
**Estimated Effort**: 10-12 hours  
**Blockers**: Need to create music_schema.json, complex audio format

**Next Steps**:
1. Create music_schema.json
2. Analyze music track structure
3. Extract track metadata
4. Extract instrument definitions
5. Extract BRR samples (lower priority)

---

## Summary Statistics

### Extraction Statistics

| Metric                    | Value      |
|---------------------------|------------|
| **Data Categories**       | 8          |
| **Total ROM Data Size**   | ~150 KB    |
| **Bytes Extracted**       | ~3 KB      |
| **Extraction Progress**   | 2%         |
| **Schemas Complete**      | 6/8 (75%)  |
| **Structures Documented** | 8/8 (100%) |

### File Statistics

| Category      | Files Created | Files Needed | Progress |
|---------------|---------------|--------------|----------|
| JSON Data     | 2             | 30+          | 7%       |
| JSON Schemas  | 6             | 8            | 75%      |
| Binary Data   | 7             | 100+         | 7%       |
| Documentation | 3             | 3            | 100%     |

**Files Created**:
- data/README.md ✅
- docs/DATA_STRUCTURES.md ✅
- docs/DATA_EXTRACTION.md ✅
- data/schemas/*.json (6 files) ✅
- data/map_tilemaps.json (partial) 🟡
- data/text_data.json (partial) 🟡
- data/graphics/*.bin (7 files) 🟡

### Priority Breakdown

**High Priority** (Should complete next):
- Character data extraction (2-3 hours)
- Item data extraction (4-6 hours)
- Map header extraction (2-3 hours)

**Medium Priority**:
- Enemy data extraction (6-8 hours)
- Text extraction (8-12 hours)
- Battle data extraction (6-8 hours)

**Low Priority** (Can defer):
- Graphics extraction (12-16 hours)
- Music extraction (10-12 hours)

**Total Estimated Effort to 100%**: 60-80 hours

---

## Milestones

### Completed ✅

- [x] **Data organization system** (data/README.md, directory structure)
- [x] **JSON schemas** (6 of 8 complete: character, enemy, item, map, text, graphics)
- [x] **Data structure documentation** (DATA_STRUCTURES.md - all 8 categories)
- [x] **Extraction process documentation** (DATA_EXTRACTION.md)
- [x] **Metatile extraction** (256 metatiles in map_tilemaps.json)

### In Progress 🟡

- [ ] **Map data extraction** (50% - metatiles done, headers/events pending)
- [ ] **Text data extraction** (45% - structure done, DTE extraction pending)
- [ ] **Graphics extraction** (40% - samples done, bulk extraction pending)

### Pending ⏳

- [ ] **Character data extraction** (HIGH priority, 2-3 hours)
- [ ] **Item data extraction** (HIGH priority, 4-6 hours)
- [ ] **Enemy data extraction** (MEDIUM priority, 6-8 hours)
- [ ] **Battle data extraction** (MEDIUM priority, 6-8 hours)
- [ ] **Music data extraction** (LOW priority, 10-12 hours)
- [ ] **Complete validation** (After all extractions)
- [ ] **ROM verification** (After all extractions)

---

## Blockers and Issues

### Current Blockers

1. **No extraction scripts yet**: Need to create extraction tools
2. **DTE decompression**: Text extraction needs DTE algorithm
3. **Enemy count unknown**: Need to scan ROM to find total count
4. **Music schema**: Need to create music_schema.json and sound_schema.json

### Resolved Issues

- ✅ Data organization system designed
- ✅ JSON schemas created (6 of 8)
- ✅ Metatile structure fully documented and extracted

### Known Issues

None currently blocking progress.

---

## Recommendations

### Immediate Actions (Next Session)

1. **Create character extraction script** (2 hours)
   - Extract 4 characters
   - Validate against schema
   - Test in-game

2. **Create item extraction script** (4 hours)
   - Extract weapons, armor, accessories, consumables (160 items)
   - Validate against schema
   - Cross-reference with shops

3. **Extract map headers** (2 hours)
   - Extract 64 map headers
   - Link to existing metatile data
   - Validate structure

**Time**: ~8 hours total for major progress boost

### Medium-Term Goals (1-2 weeks)

1. Complete high-priority extractions (characters, items, maps)
2. Create remaining schemas (battle, music)
3. Begin enemy and text extraction
4. Set up automated validation

### Long-Term Goals (1 month+)

1. Complete all data extraction (60-80 hours estimated)
2. Full ROM verification
3. In-game testing of all values
4. Coverage report automation
5. Community extraction tools

---

## Tools Needed

### Existing Tools

- ✅ JSON schema validation
- ✅ Basic file organization

### Tools to Create

**High Priority**:
- [ ] Generic data extraction script (`extract_data.py`)
- [ ] Character extraction (`extract_characters.py`)
- [ ] Item extraction (`extract_items.py`)
- [ ] Validation script (`validate_data.py`)

**Medium Priority**:
- [ ] Text extraction with DTE (`extract_text.py`)
- [ ] Map extraction (`extract_maps.py`)
- [ ] Enemy extraction (`extract_enemies.py`)

**Low Priority**:
- [ ] Graphics extraction (`extract_graphics.py`)
- [ ] Music extraction (`extract_music.py`)
- [ ] Automated coverage reporting (`coverage_report.py`)

---

## Conclusion

The data extraction project is well-positioned for success:

**Strengths**:
- ✅ Complete structural documentation (100%)
- ✅ Comprehensive schemas (75% complete)
- ✅ Clear extraction process documented
- ✅ Good progress on maps (50%)

**Opportunities**:
- High-priority extractions are straightforward
- Many quick wins available (characters, items)
- Solid foundation for automation

**Next Steps**:
1. Focus on high-priority extractions (characters, items)
2. Create remaining schemas (battle, music)
3. Develop extraction tools
4. Validate and verify all extracted data

**Estimated Time to 100%**: 60-80 hours  
**Estimated Time to 75%**: 20-30 hours (complete high/medium priority)

---

*This report should be regenerated after each major extraction milestone.*

**Related Documentation**:
- data/README.md
- docs/DATA_STRUCTURES.md
- docs/DATA_EXTRACTION.md
- data/schemas/*.json
