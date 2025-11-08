# Final Fantasy Mystic Quest - Complete Build System Integration Guide

## Overview

This document describes the complete workflow for disassembling, modifying, and rebuilding FFMQ ROM with integrated data extraction and graphics conversion.

**Last Updated:** 2025-10-25  
**Version:** 1.1-enhanced

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Directory Structure](#directory-structure)
3. [Complete Workflow](#complete-workflow)
4. [Data Extraction](#data-extraction)
5. [Graphics Pipeline](#graphics-pipeline)
6. [Text Editing](#text-editing)
7. [Assembly Integration](#assembly-integration)
8. [Testing & Verification](#testing--verification)
9. [Makefile Reference](#makefile-reference)
10. [Tool Reference](#tool-reference)

---

## Quick Start

### First Time Setup

```powershell
# 1. Install dependencies
make setup
make install-deps

# 2. Extract all data from original ROM
make extract-all

# 3. Build ROM
make build-rom

# 4. Verify build matches original
make verify
```

### Make a Modification

```powershell
# 1. Extract graphics to PNG
make extract-graphics

# 2. Edit PNG files in assets/graphics/

# 3. Convert back to SNES format
make convert-graphics

# 4. Build and inject
make build-rom inject-graphics

# 5. Test
make test
```

---

## Directory Structure

```
ffmq-info/
├── Makefile.enhanced          # Enhanced build system
├── Makefile                   # Original build system
│
├── ~roms/                     # Original ROMs (not in git)
│   └── Final Fantasy - Mystic Quest (U) (V1.1).sfc
│
├── src/                       # Source code
│   ├── asm/
│   │   ├── ffmq_complete.asm  # Main assembly file
│   │   ├── analyzed/          # Reverse-engineered analysis
│   │   │   ├── boot_sequence.asm
│   │   │   ├── dma_graphics.asm
│   │   │   ├── nmi_handler.asm
│   │   │   ├── input_handler.asm
│   │   │   ├── menu_system.asm
│   │   │   ├── battle_system.asm
│   │   │   ├── ram_map.asm
│   │   │   └── README.md
│   │   └── banks/             # Actual buildable disassembly
│   │       ├── main.asm
│   │       ├── labels.asm
│   │       └── bank_00.asm ... bank_0F.asm
│   ├── include/               # Headers and macros
│   ├── data/                  # Data tables
│   └── graphics/              # Graphics binary data
│
├── assets/                    # EDITABLE extracted assets
│   ├── graphics/              # PNG graphics files
│   ├── text/                  # Text files (.txt + .asm)
│   ├── data/                  # JSON/CSV data files
│   │   ├── enemies.json
│   │   ├── enemies.csv
│   │   ├── items.json
│   │   └── palettes/
│   └── palettes/              # Palette files
│
├── build/                     # Build outputs
│   ├── ffmq-modified.sfc      # Built ROM
│   ├── ffmq-clean.sfc         # Clean reference
│   ├── extracted/             # Raw extracted data
│   ├── converted/             # Converted SNES format
│   └── obj/                   # Object files
│
├── tools/                     # Build tools
│   ├── snes_graphics.py       # Graphics library
│   ├── convert_graphics.py    # Graphics converter
│   ├── extract_graphics_v2.py # Graphics extractor
│   ├── extraction/            # Data extraction tools
│   │   ├── extract_enemies.py
│   │   ├── extract_text.py
│   │   ├── extract_items.py
│   │   ├── extract_maps.py
│   │   └── extract_palettes.py
│   └── injection/             # Data injection tools
│       ├── inject_enemies.py
│       ├── inject_text.py
│       ├── inject_items.py
│       └── inject_graphics.py
│
└── docs/                      # Documentation
	├── BUILD_SYSTEM.md        # This file
	├── rom_map.html           # ROM memory map
	└── maps/                  # Extracted map data
```

---

## Complete Workflow

### Phase 1: Initial Extraction

```powershell
# Extract all data from original ROM
make extract-all
```

This runs:
- `extract-graphics` → PNG files in `assets/graphics/`
- `extract-text` → Text files in `assets/text/`
- `extract-enemies` → JSON/CSV in `assets/data/`
- `extract-items` → JSON in `assets/data/`
- `extract-palettes` → Palette files in `assets/palettes/`
- `extract-maps` → Map data in `docs/maps/`

**Output:**
- `assets/graphics/*.png` - All graphics as indexed PNG
- `assets/text/*.txt` - All text/dialog (human-readable)
- `assets/text/*.asm` - Text as assembly (re-assemblable)
- `assets/data/enemies.json` - Enemy stats (editable JSON)
- `assets/data/enemies.csv` - Enemy stats (spreadsheet)

### Phase 2: Modification

Edit extracted files in your favorite tools:

**Graphics:**
```powershell
# Edit PNG files in:
assets/graphics/
```
- Use any image editor (Photoshop, GIMP, etc.)
- Preserve indexed color mode
- Keep same dimensions
- Don't change palette without updating palette files

**Text/Dialog:**
```powershell
# Edit text in:
assets/text/item_names.txt
assets/text/dialog.txt
# etc.
```
- Plain text format: `ID | Text | Address`
- Control codes: `[WAIT]`, `[CLEAR]`, `[NAME]`, `[ITEM]`

**Enemy Data:**
```powershell
# Edit CSV in Excel/LibreOffice:
assets/data/enemies.csv

# Or edit JSON:
assets/data/enemies.json
```
- Modify HP, stats, resistances
- Change AI scripts
- Adjust exp/gold rewards

### Phase 3: Conversion

Convert modified data back to SNES format:

```powershell
# Convert all PNG → SNES binary
make convert-graphics

# Convert specific file
make convert-one INPUT=assets/graphics/hero.png OUTPUT=build/converted/hero.bin BPP=4
```

**Output:**
- `build/converted/*.bin` - SNES format graphics data

### Phase 4: Assembly

Build the ROM from source:

```powershell
# Build ROM with code changes
make build-rom
```

This:
1. Copies original ROM → `build/ffmq-modified.sfc`
2. Assembles `src/asm/ffmq_complete.asm` with asar
3. Patches ROM with assembled code

**Output:**
- `build/ffmq-modified.sfc` - Modified ROM

### Phase 5: Injection

Inject modified data into ROM:

```powershell
# Inject all modified data
make inject-all

# Or inject specific types
make inject-graphics
make inject-text
make inject-enemies
make inject-items
```

This inserts:
- Converted graphics → ROM
- Modified text → ROM
- Modified enemy data → ROM
- Modified item data → ROM

### Phase 6: Testing

Test the modified ROM:

```powershell
# Verify ROM integrity
make verify

# Test in emulator
make test

# Compare with original
make diff
```

---

## Data Extraction

### Graphics Extraction

```powershell
make extract-graphics
```

**What it does:**
- Scans ROM for graphics data
- Identifies 2BPP, 4BPP, 8BPP formats
- Detects palettes
- Converts to indexed PNG
- Creates documentation

**Output:**
```
assets/graphics/
├── tileset_001.png          # 4BPP tileset
├── tileset_001_palette.json # Associated palette
├── sprites_hero.png         # Character sprites
├── enemies_001.png          # Enemy graphics
└── ... (100+ files)
```

**PNG Properties:**
- Indexed color mode (palette embedded)
- Organized by tile (8×8 or 16×16)
- Metadata in JSON sidecar files

### Text Extraction

```powershell
make extract-text
```

**What it does:**
- Reads text encoding from `simple.tbl`
- Scans known text table locations
- Decodes strings
- Handles control codes
- Outputs in multiple formats

**Output:**
```
assets/text/
├── item_names.txt       # Human-readable
├── item_names.asm       # Re-assemblable
├── weapon_names.txt
├── monster_names.txt
├── dialog.txt           # All dialog
└── ...
```

**Text Format:**
```
# ITEM_NAMES
# ID | Text | Address
0001 | Cure           | $04f000
0002 | Heal           | $04f00c
0003 | Life           | $04f018
```

### Enemy Data Extraction

```powershell
make extract-enemies
```

**What it does:**
- Reads enemy stat tables from ROM
- Parses HP, attack, defense, etc.
- Extracts resistances (element, status)
- Reads AI script pointers
- Outputs JSON and CSV

**Output:**
```json
{
  "enemies": [
	{
	  "id": 0,
	  "name": "Behemoth",
	  "stats": {
		"hp": 1500,
		"attack": 80,
		"defense": 60,
		"magic": 40,
		"magic_defense": 30,
		"speed": 25,
		"accuracy": 200,
		"evade": 10
	  },
	  "resistances": {
		"elements": {"fire": "resist", "ice": "weak"},
		"status": ["poison", "sleep"]
	  },
	  "rewards": {
		"exp": 250,
		"gold": 150,
		"drop_item": 42,
		"drop_rate": 25
	  }
	}
  ]
}
```

### Item Data Extraction

```powershell
make extract-items
```

**What it does:**
- Extracts weapon stats
- Extracts armor stats
- Extracts accessory effects
- Extracts item properties

**Output:**
- `assets/data/weapons.json`
- `assets/data/armor.json`
- `assets/data/accessories.json`
- `assets/data/items.json`

---

## Graphics Pipeline

### Overview

FFMQ graphics workflow:

```
ROM Data → Extract → PNG → Edit → Convert → SNES Data → Inject → ROM
  (binary)            (indexed)             (binary)
```

### Extract Graphics

```powershell
python tools/extract_graphics_v2.py ~roms/ffmq.sfc assets/graphics/ --docs --verbose
```

**Parameters:**
- `--docs` - Generate documentation/info files
- `--verbose` - Show detailed progress
- `--format png` - Output format (default)

### Edit Graphics

Use any image editor:
- **Must preserve:** Indexed color mode, dimensions
- **Can change:** Pixel art, colors (within palette)
- **Tools:** Aseprite, GraphicsGale, GIMP, Photoshop

### Convert Graphics

```powershell
# Single file
python tools/convert_graphics.py to-snes assets/graphics/hero.png build/converted/hero.bin --bpp 4

# All files (via Makefile)
make convert-graphics
```

**Formats:**
- `2BPP` - 4 colors (HUD elements)
- `4BPP` - 16 colors (most graphics)
- `8BPP` - 256 colors (title screen, some backgrounds)

### Inject Graphics

```powershell
python tools/injection/inject_graphics.py build/ffmq-modified.sfc build/converted/ --backup
```

**What it does:**
- Reads converted SNES binary files
- Writes to correct ROM offsets
- Creates backup before modifying
- Validates checksums

---

## Text Editing

### Extract Text

```powershell
make extract-text
```

Creates:
- `assets/text/*.txt` - Human-readable
- `assets/text/*.asm` - Assembly source

### Edit Text

Edit `.txt` files:

```
# Before
0042 | This sword is legendary! | $100234

# After (changed text)
0042 | This blade is ULTIMATE! | $100234
```

**Rules:**
- Don't change ID or address
- Keep length similar (or adjust pointers)
- Use control codes: `[WAIT]`, `[CLEAR]`, `[NAME]`

### Convert Text

Text is automatically converted during injection:

```powershell
make inject-text
```

Reads: `assets/text/*.txt`  
Encodes: Using `simple.tbl` character table  
Writes: To ROM at specified addresses  

---

## Assembly Integration

### Analyzed Code Structure

The `src/asm/analyzed/` directory contains **documentation** files:
- Not directly assembled
- Provide labels, comments, discoveries
- Reference actual code in `banks/`

### Building ROM

1. **Main File:** `src/asm/ffmq_complete.asm`
   - Includes all bank files
   - Sets up LoROM mapping
   - References labels

2. **Bank Files:** `src/asm/banks/bank_XX.asm`
   - Actual disassembled code
   - Originally from Diztinguish
   - Can be enhanced with analyzed labels

3. **Labels:** `src/asm/banks/labels.asm`
   - SNES hardware registers
   - Global constants
   - Function entry points

### Integrating Analysis into Source

To add analyzed labels to bank files:

```assembly
; In bank_00.asm

; OLD (generic label)
CODE_008123:
	lda $00d8
	bit #$40
	beq CODE_008123
	; ... more code

; NEW (with analyzed label)
WaitForVBlank:              ; From nmi_handler.asm analysis
	lda VBLANK_FLAGS        ; $00d8 - VBlank sync flags
	bit #$40                ; Check bit 6 (VBlank occurred)
	beq WaitForVBlank       ; Loop until VBlank
	; ... more code
```

### Build Process

```powershell
# Build ROM
asar src/asm/ffmq_complete.asm build/ffmq-modified.sfc
```

**What happens:**
1. asar reads main file
2. Processes includes (bank files)
3. Assembles 65816 code
4. Patches into ROM
5. Outputs modified ROM

---

## Testing & Verification

### Verify Build

```powershell
make verify
```

Compares built ROM with clean reference:
- Shows differences (if any)
- Validates expected changes
- Catches unintended modifications

### Test in Emulator

```powershell
make test
```

Launches ROM in MesenS emulator with:
- Debugging enabled
- Save state support
- Memory watch windows

### Automated Testing

```powershell
# Run ROM tests
make test-rom
```

Validates:
- ROM header checksum
- Bank checksums
- Known data structures
- Graphics integrity

---

## Makefile Reference

### Build Targets

| Target | Description |
|--------|-------------|
| `all` | Build ROM (default) |
| `build-rom` | Assemble and build ROM |
| `build-clean` | Build clean reference ROM |

### Extraction Targets

| Target | Description |
|--------|-------------|
| `extract-all` | Extract all data |
| `extract-graphics` | Extract graphics to PNG |
| `extract-text` | Extract text/dialog |
| `extract-enemies` | Extract enemy data |
| `extract-items` | Extract item data |
| `extract-palettes` | Extract palettes |
| `extract-maps` | Extract map data |

### Conversion Targets

| Target | Description |
|--------|-------------|
| `convert-graphics` | Convert PNG → SNES |
| `convert-one` | Convert single file |

### Injection Targets

| Target | Description |
|--------|-------------|
| `inject-all` | Inject all modifications |
| `inject-graphics` | Inject graphics |
| `inject-text` | Inject text |
| `inject-enemies` | Inject enemy data |
| `inject-items` | Inject item data |

### Utility Targets

| Target | Description |
|--------|-------------|
| `setup` | Setup environment |
| `install-deps` | Install dependencies |
| `docs` | Generate documentation |
| `test` | Test ROM in emulator |
| `verify` | Verify ROM build |
| `clean` | Clean build files |
| `clean-all` | Clean everything |
| `help` | Show help |

---

## Tool Reference

### Python Scripts

#### snes_graphics.py
Graphics library for SNES format conversion.

**Features:**
- 2BPP, 4BPP, 8BPP support
- Tile encoding/decoding
- Palette management

#### convert_graphics.py
Bidirectional graphics converter.

**Usage:**
```powershell
# PNG → SNES
python convert_graphics.py to-snes input.png output.bin --bpp 4

# SNES → PNG
python convert_graphics.py to-png input.bin output.png --palette colors.json --bpp 4
```

#### extract_graphics_v2.py
Extract graphics from ROM.

**Usage:**
```powershell
python extract_graphics_v2.py rom.sfc output_dir/ --docs --verbose
```

#### extract_enemies.py
Extract enemy data.

**Usage:**
```powershell
python extract_enemies.py rom.sfc output.json --format all --verbose
```

#### extract_text.py
Extract text/dialog.

**Usage:**
```powershell
python extract_text.py rom.sfc output_dir/ --tbl simple.tbl
```

---

## Troubleshooting

### Build Fails

**Error:** `asar: unknown opcode`
- Check bank files for syntax errors
- Verify asar version (need v1.60+)

**Error:** `file not found: bank_XX.asm`
- Check include paths in `ffmq_complete.asm`
- Verify all bank files exist

### Graphics Issues

**PNG has wrong colors:**
- Check palette JSON file
- Verify indexed color mode
- Ensure palette matches SNES format

**Graphics garbled in ROM:**
- Verify BPP setting (2/4/8)
- Check tile organization
- Validate ROM addresses

### Text Issues

**Text displays wrong:**
- Check character table (`simple.tbl`)
- Verify text encoding
- Check for length overruns

**Control codes not working:**
- Use correct format: `[WAIT]`, not `<WAIT>`
- Check encoding in text table

---

## Advanced Topics

### Adding New Labels

1. Analyze code in `banks/bank_XX.asm`
2. Document in `analyzed/system_name.asm`
3. Add labels to bank file
4. Update `labels.asm` if global
5. Commit both analyzed + bank changes

### Custom Data Structures

Create extractor:
1. Identify ROM addresses
2. Parse data structure
3. Create Python script in `tools/extraction/`
4. Add Makefile target
5. Document in `BUILD_SYSTEM.md`

### Graphics Hacking

Advanced techniques:
- Palette animation
- Dynamic tile loading
- Compressed graphics
- Hardware effects (Mode 7, HDMA)

See specialized docs in `docs/graphics/`

---

## Version History

**1.1-enhanced (2025-10-25)**
- Added comprehensive build system
- Integrated data extraction tools
- Created injection pipeline
- Enhanced Makefile
- Complete documentation

**1.0 (Original)**
- Initial Diztinguish disassembly
- Basic graphics tools
- Manual process

---

## Credits

- **Original Game:** Square (1992)
- **Disassembly:** Diztinguish tool
- **Reverse Engineering:** Community effort
- **Build System:** Enhanced 2025
- **Graphics Tools:** snes_graphics.py library

---

## License

See LICENSE file in project root.
