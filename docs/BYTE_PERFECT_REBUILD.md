# Byte-Perfect ROM Rebuild Guide

## Goal

Create a **byte-perfect rebuild** of Final Fantasy Mystic Quest where:
1. Extract ALL assets from original ROM
2. Organize into editable formats (PNG, JSON, TXT, etc.)
3. Build ROM from extracted sources
4. Compare with original using automated tools
5. Iterate until built ROM matches original ROM **100%**

Once achieved, we can modify any asset and rebuild custom ROMs.

---

## Current Process

### Phase 1: Asset Extraction

**Goal:** Extract EVERYTHING from the original ROM into editable formats

```powershell
# Extract all assets
make -f Makefile.enhanced extract-all
```

**What Gets Extracted:**

| Asset Type | Source Format | Extracted Format | Tool | Status |
|------------|---------------|------------------|------|--------|
| **Code** | 65816 Assembly | ASM files (Diztinguish) | Already done | ✅ Complete |
| **Graphics** | SNES 2/4/8BPP | PNG images | extract_graphics_v2.py | ✅ Complete |
| **Text/Dialog** | Custom encoding | TXT + JSON | extract_text.py | ✅ Complete |
| **Enemy Stats** | Binary tables | JSON + CSV | extract_enemies.py | ✅ Complete |
| **Item Data** | Binary tables | JSON | extract_items.py | 🔧 In Progress |
| **Maps** | Tilemap + data | JSON + tilemap | extract_maps.py | 🔧 Planned |
| **Palettes** | SNES RGB | JSON + GPL | extract_palettes.py | 🔧 Planned |
| **Music** | SPC700 binary | SPC + MIDI | extract_music.py | 🔧 Planned |
| **Fonts** | Bitmap tiles | PNG + metrics | extract_fonts.py | 🔧 Planned |

**Extracted Directory Structure:**
```
assets/
├── graphics/           # PNG images with palettes
│   ├── characters/
│   ├── enemies/
│   ├── tiles/
│   └── backgrounds/
├── text/               # All strings and dialog
│   ├── dialog.txt
│   ├── item_names.txt
│   ├── monster_names.txt
│   └── ...
├── data/               # Game data in JSON/CSV
│   ├── enemies.json
│   ├── enemies.csv
│   ├── items.json
│   ├── weapons.json
│   ├── armor.json
│   └── spells.json
├── maps/               # Level/map data
│   ├── map_001.json
│   └── ...
├── palettes/           # Color palettes
│   ├── palette_001.json
│   └── ...
└── audio/              # Music and sound
    ├── music/
    │   ├── track_001.spc
    │   ├── track_001.mid
    │   └── ...
    └── sfx/
```

### Phase 2: Build from Sources

**Goal:** Rebuild ROM from extracted assets

```powershell
# Build ROM from extracted assets
make -f Makefile.enhanced build-rom
```

**Build Process:**
1. **Assemble Code** - asar assembles all bank files
2. **Convert Graphics** - PNG → SNES binary format (2BPP/4BPP/8BPP)
3. **Encode Text** - TXT → ROM encoding using character table
4. **Pack Data** - JSON → binary tables (enemies, items, etc.)
5. **Inject Assets** - Insert all converted data into ROM
6. **Fix Checksums** - Update ROM header checksums

**Output:**
- `build/ffmq-modified.sfc` - Built ROM

### Phase 3: Compare and Verify

**Goal:** Find what differs between original and built ROM

```powershell
# Detailed comparison with reports
make -f Makefile.enhanced compare-detailed
```

**Comparison Tool (`rom_compare.py`):**

Generates three reports:

#### 1. Text Report (`reports/comparison.txt`)
```
================================================================================
FFMQ ROM Comparison Report
================================================================================

Overall Statistics:
--------------------------------------------------------------------------------
Total Bytes:         524,288
Matching Bytes:      498,532
Differing Bytes:      25,756
Match Percentage:      95.09%

Statistics by Category:
--------------------------------------------------------------------------------
Category        Total       Matching    Differing   Match %
--------------------------------------------------------------------------------
code            98,304       95,234        3,070      96.88%
graphics        131,072     125,000        6,072      95.37%
text            32,768       30,500        2,268      93.08%
data            49,152       48,200          952      98.06%
audio           65,536       52,142       13,394      79.56%
unknown         147,456     147,456            0     100.00%

Difference Blocks (First 50):
--------------------------------------------------------------------------------
Start      End        Size    Region                    Category
--------------------------------------------------------------------------------
$030120   $030240      288    Enemy Stats               data
$040000   $041000    4,096    Enemy Graphics            graphics
$050234   $050456      546    Music Data                audio
... and 127 more difference blocks

Recommendations:
--------------------------------------------------------------------------------
1. Focus on 'audio' category (13,394 differing bytes)

2. Largest difference blocks to investigate:
   1. $040000-$041000 (4,096 bytes) - Enemy Graphics
   2. $050000-$052000 (8,192 bytes) - Music Data
   3. $030000-$030500 (1,280 bytes) - Enemy Stats
   4. $024000-$024800 (2,048 bytes) - Dialog Data
   5. $060000-$060200 (512 bytes) - VBlank Handler

📊 Good progress. Focus on extracting remaining data structures.
```

#### 2. JSON Report (`reports/comparison.json`)
Machine-readable data for automation:
```json
{
  "original_rom": "~roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc",
  "built_rom": "build/ffmq-modified.sfc",
  "statistics": {
    "total_bytes": 524288,
    "matching_bytes": 498532,
    "differing_bytes": 25756,
    "match_percentage": 95.09,
    "by_category": {
      "code": {
        "total_bytes": 98304,
        "matching_bytes": 95234,
        "differing_bytes": 3070,
        "match_percentage": 96.88
      },
      ...
    }
  },
  "difference_blocks": [
    {
      "start": "$030120",
      "end": "$030240",
      "size": 288,
      "region": "Enemy Stats",
      "category": "data",
      "original_sample": "1f4e2a3c...",
      "built_sample": "1f4e0000..."
    },
    ...
  ]
}
```

#### 3. HTML Report (`reports/comparison.html`)
Visual report with:
- Progress bars showing match percentage
- Color-coded categories
- Interactive tables
- Statistics dashboard

**Open in browser:** `reports/comparison.html`

### Phase 4: Iterate and Fix

**Goal:** Eliminate differences until 100% match

**Workflow:**

1. **Check Report**
   ```powershell
   make compare-detailed
   # Opens reports/comparison.html
   ```

2. **Identify Category with Most Differences**
   - Look at "Statistics by Category" table
   - Focus on category with lowest match %

3. **Investigate Difference Blocks**
   - Find largest difference blocks in report
   - Note the ROM addresses and regions

4. **Improve Extraction/Insertion**
   - If differences in **graphics**: Improve graphics extraction
   - If differences in **text**: Fix text encoding/decoding
   - If differences in **data**: Improve data structure parsing
   - If differences in **audio**: Implement audio extraction
   - If differences in **code**: Check assembly/disassembly

5. **Re-extract and Rebuild**
   ```powershell
   make extract-all          # Re-extract with improved tools
   make build-rom            # Rebuild ROM
   make compare-detailed     # Check progress
   ```

6. **Repeat** until match percentage = 100%

---

## ROM Memory Map

Understanding ROM structure helps target extraction efforts:

| Address Range | Bank | Category | Contents | Extraction Tool |
|---------------|------|----------|----------|-----------------|
| $000000-$004000 | $00 | Code | Boot, main engine | Diztinguish ✅ |
| $004000-$008000 | $00 | Data | Engine data tables | extract_data.py 🔧 |
| $008000-$010000 | $01 | Code | Field system, events | Diztinguish ✅ |
| $010000-$018000 | $02 | Code | Battle system, AI | Diztinguish ✅ |
| $018000-$020000 | $03 | Code | Menu system | Diztinguish ✅ |
| $020000-$024000 | $04 | Code | Text engine | Diztinguish ✅ |
| $024000-$028000 | $04 | Text | Dialog strings | extract_text.py ✅ |
| $028000-$02c000 | $05 | Code | Magic system | Diztinguish ✅ |
| $02c000-$030000 | $05 | Code | Item system | Diztinguish ✅ |
| $030000-$032000 | $06 | Data | Enemy stats | extract_enemies.py ✅ |
| $032000-$038000 | $06 | Data | Battle data | extract_battles.py 🔧 |
| $038000-$040000 | $07 | Graphics | Character sprites | extract_graphics_v2.py ✅ |
| $040000-$048000 | $08 | Graphics | Enemy sprites | extract_graphics_v2.py ✅ |
| $048000-$050000 | $09 | Graphics | Tile graphics | extract_graphics_v2.py ✅ |
| $050000-$054000 | $0a | Code | Sound engine | Diztinguish ✅ |
| $054000-$058000 | $0a | Audio | Music sequences | extract_music.py 🔧 |
| $058000-$060000 | $0b | Audio | Sound effects | extract_music.py 🔧 |
| $060000-$064000 | $0c | Code | VBlank handler | Diztinguish ✅ |
| $064000-$068000 | $0d | Code | Save system | Diztinguish ✅ |
| $068000-$080000 | $0e-$0f | Code/Data | Additional logic | Diztinguish ✅ |

---

## Tracking Progress

### Current Status

Check current rebuild status:
```powershell
make -f Makefile.enhanced report
```

### Goal Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| **Overall Match** | 100% | TBD | 🔧 |
| **Code Match** | 100% | ~95%? | 🔧 |
| **Graphics Match** | 100% | ~90%? | 🔧 |
| **Text Match** | 100% | ~85%? | 🔧 |
| **Data Match** | 100% | ~90%? | 🔧 |
| **Audio Match** | 100% | 0%? | ❌ |

### Completion Criteria

**Phase 1 Complete When:**
- ✅ All code disassembled (Done)
- ✅ All graphics extracted to PNG (Done)
- ✅ All text extracted (Done)
- ✅ Enemy data extracted (Done)
- 🔧 Item/equipment data extracted
- 🔧 Map data extracted
- 🔧 Palette data extracted
- 🔧 Audio data extracted

**Phase 2 Complete When:**
- Built ROM matches original ROM 100%
- `make compare-detailed` shows 0 differing bytes
- All checksums match
- ROM is playable and identical

---

## Implementation Plan

### Step 1: Extract Remaining Assets (Current)

**Priority Order:**

1. **Item/Equipment Data** (High Priority)
   - [ ] Create `extract_items.py`
   - [ ] Extract weapon stats ($04fe00?)
   - [ ] Extract armor stats ($04ff00?)
   - [ ] Extract accessory stats ($050000?)
   - [ ] Extract item properties
   - [ ] Output to JSON

2. **Palettes** (High Priority)
   - [ ] Create `extract_palettes.py`
   - [ ] Identify palette locations in ROM
   - [ ] Extract to JSON (RGB values)
   - [ ] Extract to GPL (GIMP palette format)
   - [ ] Link palettes to graphics

3. **Maps/Levels** (Medium Priority)
   - [ ] Create `extract_maps.py`
   - [ ] Parse map structure
   - [ ] Extract tile arrangements
   - [ ] Extract entity placements
   - [ ] Extract triggers/events
   - [ ] Output to JSON + tilemap format

4. **Audio/Music** (Medium Priority)
   - [ ] Create `extract_music.py`
   - [ ] Identify SPC700 data format
   - [ ] Extract music sequences
   - [ ] Extract sound effect samples
   - [ ] Convert to SPC format
   - [ ] Attempt MIDI conversion

5. **Fonts** (Low Priority)
   - [ ] Create `extract_fonts.py`
   - [ ] Extract font tile data
   - [ ] Extract character metrics
   - [ ] Output to PNG + JSON

### Step 2: Create Insertion Tools

For each extractor, create corresponding injector:

1. **Item Data** - `inject_items.py`
2. **Palettes** - `inject_palettes.py`
3. **Maps** - `inject_maps.py`
4. **Audio** - `inject_audio.py`
5. **Fonts** - `inject_fonts.py`

### Step 3: Refine Existing Tools

Improve extraction accuracy:

1. **Graphics Extraction**
   - Verify all graphics found
   - Correct palette associations
   - Handle compressed graphics

2. **Text Extraction**
   - Verify character table completeness
   - Handle all control codes
   - Extract all text tables

3. **Enemy Data**
   - Verify ROM addresses
   - Validate all stat fields
   - Check AI script parsing

### Step 4: Achieve Byte-Perfect Build

Iterative process:

1. Run `make compare-detailed`
2. Check match percentage
3. Identify worst category
4. Improve extraction/insertion for that category
5. Rebuild and compare again
6. Repeat until 100%

---

## Tools Reference

### Makefile Commands

```powershell
# Full workflow
make -f Makefile.enhanced extract-all      # Extract everything
make -f Makefile.enhanced build-rom        # Build ROM
make -f Makefile.enhanced compare-detailed # Compare and report

# Individual operations
make -f Makefile.enhanced extract-graphics
make -f Makefile.enhanced extract-text
make -f Makefile.enhanced extract-enemies
make -f Makefile.enhanced convert-graphics
make -f Makefile.enhanced inject-all

# Verification
make -f Makefile.enhanced verify           # Quick binary check
make -f Makefile.enhanced compare          # Detailed analysis
make -f Makefile.enhanced report           # Show report
```

### Python Tools

```powershell
# ROM comparison
python tools/rom_compare.py original.sfc built.sfc --report-dir reports/

# Asset extraction
python tools/extract_all_assets.py original.sfc assets/

# Individual extractors
python tools/extract_graphics_v2.py rom.sfc assets/graphics/
python tools/extraction/extract_text.py rom.sfc assets/text/
python tools/extraction/extract_enemies.py rom.sfc assets/data/enemies.json --format all
```

---

## Success Criteria

### Phase 1: Asset Extraction (Current Goal)

**DONE when:**
- All ROM data extracted to editable formats
- No unknown/unidentified regions remain
- All extraction tools working and documented

### Phase 2: Byte-Perfect Rebuild (Next Goal)

**DONE when:**
```powershell
make compare-detailed
```

Shows:
```
Match Percentage: 100.00%
Matching Bytes:   524,288 / 524,288
Differing Bytes:  0

✅ SUCCESS! Byte-perfect match achieved!
```

### Phase 3: Modification Support (Future Goal)

**DONE when:**
- Can modify any asset (graphics, text, data)
- Rebuild ROM with modifications
- ROM boots and plays correctly
- Changes work as expected

---

## Next Steps

1. **Run initial comparison** to establish baseline:
   ```powershell
   make -f Makefile.enhanced extract-all
   make -f Makefile.enhanced build-rom
   make -f Makefile.enhanced compare-detailed
   ```

2. **Review reports** in `reports/` directory

3. **Prioritize work** based on difference analysis

4. **Create missing extractors** (items, palettes, maps, audio)

5. **Iterate** until byte-perfect match achieved

---

## References

- **Build System Docs:** `docs/BUILD_SYSTEM.md`
- **Quick Start:** `BUILD_QUICK_START.md`
- **Analysis Docs:** `src/asm/analyzed/README.md`
- **Comparison Reports:** `reports/comparison.html`

---

**Goal:** Extract → Build → Compare → Fix → Repeat until 100% match

Then we can modify anything and rebuild custom ROMs!
