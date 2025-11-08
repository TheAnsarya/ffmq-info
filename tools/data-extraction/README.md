# Data Extraction Tools

This directory contains tools for extracting game data, graphics, text, and other assets from the Final Fantasy Mystic Quest ROM.

## Core Extraction Tools

### Comprehensive Extractors
- **extract_all_assets.py** ⭐ - Extract all assets from ROM
  - One-command extraction of all game data
  - Graphics, text, music, maps, battle data
  - Organized output structure
  - Progress tracking and logging
  - Usage: `python tools/data-extraction/extract_all_assets.py --output assets/`

- **extract_graphics_v2.py** ⭐ - Advanced graphics extractor
  - Extract sprites, tiles, backgrounds
  - Automatic palette detection
  - PNG export with transparency
  - Metadata generation
  - Usage: `python tools/data-extraction/extract_graphics_v2.py --type <sprite|tile|bg> --id <n> --output <file.png>`

### Graphics Extraction
- **extract_graphics.py** - Legacy graphics extractor
  - Original graphics extraction tool
  - Basic sprite/tile extraction
  - Raw format output
  - Usage: `python tools/data-extraction/extract_graphics.py --address <hex> --output <file.bin>`

- **extract_palettes.py** - Palette extractor
  - Extract color palettes from ROM
  - Export to multiple formats (.pal, .json, .png)
  - Palette visualization
  - Usage: `python tools/data-extraction/extract_palettes.py --address <hex> --count <n> --output <file.pal>`

### Text Extraction
- **extract_text.py** - Text extractor
  - Extract dialogue and text strings
  - DTE (Dual-Tile Encoding) support
  - Character table mapping
  - Usage: `python tools/data-extraction/extract_text.py --output text.json`

- **extract_text_enhanced.py** - Enhanced text extractor
  - Advanced text extraction with context
  - Script organization by location
  - Speaker identification
  - Control code parsing
  - Usage: `python tools/data-extraction/extract_text_enhanced.py --output scripts/`

### Map and World Data
- **extract_maps_enhanced.py** - Enhanced map extractor
  - Extract map data with layers
  - Tileset extraction
  - Event/trigger data
  - Map metadata
  - Usage: `python tools/data-extraction/extract_maps_enhanced.py --output maps/`

- **extract_overworld.py** - Overworld map extractor
  - Extract Mode 7 overworld data
  - World map graphics
  - Location data
  - Usage: `python tools/data-extraction/extract_overworld.py --output overworld/`

### Music and Audio
- **extract_music.py** - Music extractor
  - Extract SPC music data
  - SNES audio format support
  - Export to SPC/MIDI
  - Track metadata
  - Usage: `python tools/data-extraction/extract_music.py --track <n> --output <file.spc>`

### Battle and Spell Data
- **extract_effects.py** - Battle effects extractor
  - Extract spell effects
  - Animation data
  - Particle systems
  - Usage: `python tools/data-extraction/extract_effects.py --output effects/`

### Bank-Specific Extractors
- **extract_bank06_data.py** - Extract Bank $06 data
  - Map tile data
  - Metatile definitions
  - Collision data
  - Usage: `python tools/data-extraction/extract_bank06_data.py --output bank06/`

- **extract_bank08_data.py** - Extract Bank $08 data
  - Battle graphics
  - Enemy sprites
  - Battle backgrounds
  - Usage: `python tools/data-extraction/extract_bank08_data.py --output bank08/`

- **generate_bank06_metatiles.py** - Generate Bank $06 metatile assembly
  - Creates assembly definitions for metatiles
  - Validates metatile structure
  - Generates documentation
  - Usage: `python tools/data-extraction/generate_bank06_metatiles.py --output metatiles.asm`

### Generic Data Extraction
- **extract_data.py** - Generic data extractor
  - Extract arbitrary data ranges
  - Multiple format support
  - Custom data structures
  - Usage: `python tools/data-extraction/extract_data.py --address <hex> --length <n> --format <hex|bin|asm>`

## PowerShell Extraction Scripts

- **catalog_rom_data.ps1** - Catalog all ROM data
  - Scans entire ROM for data patterns
  - Generates comprehensive catalog
  - Identifies data types
  - Usage: `.\tools\data-extraction\catalog_rom_data.ps1 -RomFile <rom.smc> -Output <catalog.json>`

- **scan_addresses.ps1** - Scan for specific data
  - Search ROM for patterns
  - Address range scanning
  - Pattern matching
  - Usage: `.\tools\data-extraction\scan_addresses.ps1 -Pattern <hex> -Start <addr> -End <addr>`

## Extraction Subdirectory

The `tools/extraction/` subdirectory contains specialized extraction tools:

### Enemy and Battle Data
- **extract_enemies.py** - Extract enemy data
- **extract_all_enemies.py** - Batch extract all enemies
- **extract_enemy_palettes.py** - Extract enemy palettes
- **extract_enemy_pointers.py** - Extract enemy pointer tables
- **reextract_enemies_correct_palettes.py** - Re-extract with corrected palettes
- **extract_attacks.py** - Extract attack data
- **extract_enemy_attack_links.py** - Extract attack linkage data
- **validate_attacks.py** - Validate extracted attack data

### Character and Items
- **extract_characters.py** - Extract character/party data
- **extract_items.py** - Extract item data
- **extract_spells.py** - Extract spell data

### Graphics and Sprites
- **extract_sprites.py** - Extract sprite graphics
- **extract_ui_graphics.py** - Extract UI graphics
- **extract_palettes_sprites.py** - Extract sprite palettes
- **assemble_sprites.py** - Assemble sprite sheets
- **create_sprite_catalog.py** - Generate sprite catalog

### Map Data
- **extract_maps.py** - Extract map data
- **extract_text.py** - Extract in-map text

### Analysis Tools
- **analyze_tiles.py** - Analyze tile usage
- **analyze_vram.py** - VRAM allocation analysis

### Utilities
- **extract_graphics.py** - Generic graphics extraction
- **png_to_tiles.py** - Convert PNGs to tile data (import helper)

See `tools/extraction/README.md` for detailed documentation.

## Common Workflows

### Complete Asset Extraction
```bash
# Extract everything at once
python tools/data-extraction/extract_all_assets.py --output assets/

# Output structure:
# assets/
#   graphics/
#   text/
#   music/
#   maps/
#   battle/
#   data/
```

### Extract Specific Enemy
```bash
# Extract enemy data
python tools/extraction/extract_enemies.py --id 42 --output enemy_42.json

# Extract enemy sprite
python tools/data-extraction/extract_graphics_v2.py --type sprite --id 42 --output enemy_42.png

# Extract enemy palette
python tools/extraction/extract_enemy_palettes.py --id 42 --output enemy_42.pal
```

### Extract and Edit Dialogue
```bash
# 1. Extract all text
python tools/data-extraction/extract_text_enhanced.py --output scripts/

# 2. Edit scripts/location_01.txt

# 3. Validate changes
python tools/validation/validate_text.py --input scripts/

# 4. Import back to ROM
python tools/import/import_text.py --input scripts/
```

### Extract Map Data
```bash
# Extract specific map
python tools/data-extraction/extract_maps_enhanced.py --map 10 --output map_10/

# Extract all maps
python tools/data-extraction/extract_maps_enhanced.py --all --output maps/

# Extract overworld
python tools/data-extraction/extract_overworld.py --output overworld/
```

### Extract Music Tracks
```bash
# Extract specific track
python tools/data-extraction/extract_music.py --track 5 --output track_05.spc

# Extract all music
python tools/data-extraction/extract_music.py --all --output music/

# Export as MIDI
python tools/data-extraction/extract_music.py --track 5 --format midi --output track_05.mid
```

### Create Graphics Catalog
```bash
# Scan ROM for all graphics
python tools/data-extraction/extract_all_assets.py --graphics-only --output graphics_catalog/

# Generate visual catalog
python tools/graphics/inventory_graphics.py --input graphics_catalog/ --output catalog.html
```

## Extraction Formats

### Graphics Formats
- **PNG** - Images with transparency, indexed color
- **BIN** - Raw SNES tile data (2bpp, 4bpp, 8bpp)
- **CHR** - Tile data with format extension (.2bpp.chr)
- **PAL** - JASC-PAL palette format

### Text Formats
- **JSON** - Structured text data with metadata
- **TXT** - Plain text scripts
- **CSV** - Tabular text data

### Data Formats
- **JSON** - Structured data (enemies, items, spells)
- **ASM** - Assembly data definitions
- **BIN** - Raw binary data
- **HEX** - Hex dump format

### Music Formats
- **SPC** - SNES SPC700 music file
- **MIDI** - MIDI sequence
- **JSON** - Music metadata

## Extraction Configuration

### extraction_config.json
```json
{
    "rom_file": "roms/original.smc",
    "output_base": "assets/",
    "graphics": {
        "format": "png",
        "include_palettes": true,
        "transparency": true
    },
    "text": {
        "format": "json",
        "encoding": "utf-8",
        "dte_table": "data/dte_table.json"
    },
    "music": {
        "format": "spc",
        "include_metadata": true
    }
}
```

## Data Mapping

### Known Data Locations
```
$0C8000-$0CFFFF: Character/Enemy sprites
$0E0000-$0EFFFF: Map tile data
$10C000-$10FFFF: Text/Dialogue data
$118000-$11FFFF: Music data
$1A0000-$1AFFFF: Enemy data
```

See `docs/technical/ROM_MAP.md` for complete memory map.

## Dependencies

- Python 3.7+
- **Pillow** - `pip install Pillow` (for graphics extraction)
- **numpy** - `pip install numpy` (optional, for advanced graphics)
- ROM file access modules

## See Also

- **tools/import/** - For importing modified assets back to ROM
- **tools/conversion/** - For converting between formats
- **tools/graphics/** - For graphics processing
- **tools/validation/** - For validating extracted data
- **docs/technical/DATA_FORMATS.md** - Data format specifications
- **docs/rom-hacking/EXTRACTION_GUIDE.md** - Extraction guide

## Tips and Best Practices

### General Extraction
- Always work with a copy of the ROM
- Extract to organized directory structure
- Keep metadata with extracted assets
- Document custom extractions
- Validate extracted data

### Graphics Extraction
- Extract with transparency enabled
- Keep palettes with graphics
- Use PNG-8 indexed color format
- Verify colors match in-game
- Test re-import after extraction

### Text Extraction
- Preserve control codes
- Keep line breaks
- Document special characters
- Validate character table
- Test with various text lengths

### Batch Operations
- Use `extract_all_assets.py` for initial extraction
- Process in batches for large datasets
- Log all extraction operations
- Verify extraction completeness
- Keep original ROM unchanged

## Troubleshooting

**Issue: Graphics extracted with wrong colors**
- Solution: Check palette address, use correct palette with sprite

**Issue: Text extracted with garbage characters**
- Solution: Verify character table, check DTE encoding

**Issue: Music extraction fails**
- Solution: Verify SPC address, check music bank

**Issue: Map data incomplete**
- Solution: Extract all layers, check metatile data

**Issue: Extraction produces different results**
- Solution: Verify ROM is unmodified original, check extraction config

## Advanced Topics

### Custom Data Structures
Define custom extraction for unknown data:
```python
from tools.rom_operations.rom_extractor import ROMExtractor

extractor = ROMExtractor('rom.smc')
data = extractor.extract_struct(0x1A0000, 'enemy_format')
```

### Compression Handling
Some data is compressed. Use `ffmq_compression.py`:
```python
from tools.rom_operations.ffmq_compression import decompress
data = decompress(compressed_data)
```

### Scripted Extraction
Automate complex extractions:
```python
# Extract all enemies with sprites and palettes
for enemy_id in range(256):
    extract_enemy(enemy_id)
    extract_sprite(enemy_id)
    extract_palette(enemy_id)
```

## Contributing

When adding extraction tools:
1. Follow existing naming conventions
2. Support batch operations
3. Include format documentation
4. Add validation for extracted data
5. Create corresponding import tool
6. Update this README
7. Add to `extract_all_assets.py` if appropriate

## Future Development

Planned additions:
- [ ] Automated data structure detection
- [ ] AI-assisted unknown data identification
- [ ] Real-time extraction preview
- [ ] Cloud-based extraction pipeline
- [ ] Extraction templates for common tasks
- [ ] Diff extraction (compare ROM versions)
- [ ] Extraction undo/redo
