# FFMQ Data Extraction Pipeline
# Complete asset extraction, conversion, and re-insertion system

## Directory Structure

```
ffmq-info/
├── data/                           # Extracted data repository
│   ├── graphics/                   # Graphics data
│   │   ├── 1_original_bin/        # Original binary graphics data
│   │   ├── 2_converted_png/       # PNG conversions of graphics
│   │   ├── 3_converted_json/      # JSON metadata for graphics
│   │   └── 4_reinsert_bin/        # Rebuilt binary from PNG/JSON
│   ├── palettes/                   # Color palettes
│   │   ├── 1_original_bin/        # Original BGR555 palette data
│   │   ├── 2_converted_json/      # JSON palette definitions
│   │   ├── 3_converted_png/       # PNG palette swatches
│   │   └── 4_reinsert_bin/        # Rebuilt binary palettes
│   ├── music/                      # Music and sound
│   │   ├── 1_original_bin/        # Original SPC700 music data
│   │   ├── 2_converted_spc/       # SPC sound files
│   │   ├── 3_converted_json/      # JSON music metadata
│   │   └── 4_reinsert_bin/        # Rebuilt binary music
│   ├── sprites/                    # Sprite data
│   │   ├── 1_original_bin/        # Original sprite tile data
│   │   ├── 2_converted_png/       # PNG sprite sheets
│   │   ├── 3_converted_json/      # JSON sprite configs
│   │   └── 4_reinsert_bin/        # Rebuilt binary sprites
│   ├── maps/                       # Map/tilemap data
│   │   ├── 1_original_bin/        # Original map data
│   │   ├── 2_converted_tmx/       # Tiled TMX map files
│   │   ├── 3_converted_json/      # JSON map definitions
│   │   └── 4_reinsert_bin/        # Rebuilt binary maps
│   ├── text/                       # Text/dialog data
│   │   ├── 1_original_bin/        # Original compressed text
│   │   ├── 2_converted_txt/       # Plain text strings
│   │   ├── 3_converted_json/      # JSON text + metadata
│   │   └── 4_reinsert_bin/        # Rebuilt binary text
│   ├── animation/                  # Animation sequences
│   │   ├── 1_original_bin/        # Original animation data
│   │   ├── 2_converted_json/      # JSON animation frames
│   │   ├── 3_converted_csv/       # CSV timing data
│   │   └── 4_reinsert_bin/        # Rebuilt binary animations
│   └── tables/                     # Data tables
│       ├── 1_original_bin/        # Original table data
│       ├── 2_converted_csv/       # CSV table exports
│       ├── 3_converted_json/      # JSON structured data
│       └── 4_reinsert_bin/        # Rebuilt binary tables
├── tools/                          # Extraction/conversion tools
│   ├── extract_all.py             # Master extraction script
│   ├── convert_all.py             # Master conversion script
│   ├── reinsert_all.py            # Master reinsertion script
│   ├── graphics_converter.py      # Graphics <-> PNG converter
│   ├── palette_converter.py       # Palette <-> JSON/PNG converter
│   ├── music_converter.py         # Music <-> SPC converter
│   ├── sprite_converter.py        # Sprite <-> PNG/JSON converter
│   ├── map_converter.py           # Map <-> TMX/JSON converter
│   ├── text_converter.py          # Text <-> TXT/JSON converter
│   ├── animation_converter.py     # Animation <-> JSON/CSV converter
│   └── table_converter.py         # Table <-> CSV/JSON converter
└── logs/                           # Extraction logs
    ├── extraction_log.txt         # Extraction session logs
    ├── conversion_log.txt         # Conversion session logs
    └── validation_log.txt         # Validation/comparison logs
```

## Extraction Workflow

### Phase 1: Binary Extraction
Extract all raw binary data from ROM banks to `1_original_bin/` directories:
- Graphics tiles, palettes, sprite data
- Music sequences, sound effects
- Map data, tilemap arrays
- Text strings, dialog tables
- Animation sequences
- Configuration tables

### Phase 2: Format Conversion
Convert binary data to human-readable/editable formats in `2_converted_*/` and `3_converted_*/`:
- **Graphics**: BIN → PNG (4bpp tiles → 8-bit indexed PNG)
- **Palettes**: BIN → JSON (BGR555 → RGB JSON) + PNG swatches
- **Music**: BIN → SPC (SPC700 bytecode → .spc files) + JSON metadata
- **Sprites**: BIN → PNG sprite sheets + JSON configs (coords, animations)
- **Maps**: BIN → TMX (Tiled format) + JSON definitions
- **Text**: BIN → TXT (decompressed strings) + JSON (with metadata)
- **Animations**: BIN → JSON (frame data) + CSV (timing tables)
- **Tables**: BIN → CSV/JSON (structured data exports)

### Phase 3: Re-insertion/Validation
Rebuild binary data from converted formats to `4_reinsert_bin/` and validate:
- Convert PNG/JSON back to original binary format
- Byte-for-byte comparison with `1_original_bin/`
- Validation report showing any discrepancies
- Round-trip conversion verification

## Data Extraction Map

### Graphics Data (Bank $07 + others)
**Source Addresses**:
- $07b013: Graphics DMA configuration table
- $07d274: Graphics tile buffer (32-byte blocks)
- $048000: Main graphics tiles (tiles.bin exists)

**Extraction**:
```
Bank $07 $b013-$b07a → data/graphics/1_original_bin/dma_config.bin
Bank $07 $d274-$ffff → data/graphics/1_original_bin/tile_buffer.bin
ROM $048000+        → data/graphics/1_original_bin/main_tiles.bin
```

**Conversion**:
```
main_tiles.bin → 2_converted_png/tiles_sheet.png (4bpp planar → indexed PNG)
               → 3_converted_json/tiles_metadata.json (tile dimensions, count)
```

### Palette Data (Multiple Banks)
**Source Addresses**:
- $7fcdc8: Active palette buffer (32 bytes per layer)
- Bank $03: Embedded BGR555 palette data

**Extraction**:
```
Bank $03 palette data → data/palettes/1_original_bin/bgr555_palettes.bin
Bank $07 $cdc8 refs   → data/palettes/1_original_bin/active_palettes.bin
```

**Conversion**:
```
bgr555_palettes.bin → 2_converted_json/palettes.json (BGR555 → RGB JSON)
                    → 3_converted_png/palette_swatches.png (visual reference)
```

### Sprite Data (Bank $07)
**Source Addresses**:
- $07a736: Character/NPC sprite configurations
- $07a906: Monster/enemy sprite data
- $07aa60: Item/treasure sprite data

**Extraction**:
```
Bank $07 $a736-$a805 → data/sprites/1_original_bin/character_sprites.bin
Bank $07 $a906-$aa5f → data/sprites/1_original_bin/enemy_sprites.bin
Bank $07 $aa60-$aaad → data/sprites/1_original_bin/item_sprites.bin
```

**Conversion**:
```
character_sprites.bin → 2_converted_png/characters/ (individual PNGs)
                      → 3_converted_json/characters.json (coords, palettes)
enemy_sprites.bin     → 2_converted_png/enemies/ (individual PNGs)
                      → 3_converted_json/enemies.json (animation data)
```

### Animation Data (Bank $07)
**Source Addresses**:
- $07921e: Sprite animation command sequences
- $07af3b: Animation pointer table
- $079174: Frame rotation routines

**Extraction**:
```
Bank $07 $921e-$93ff → data/animation/1_original_bin/animation_sequences.bin
Bank $07 $af3b-$b012 → data/animation/1_original_bin/animation_pointers.bin
```

**Conversion**:
```
animation_sequences.bin → 2_converted_json/animations.json (frame sequences)
                        → 3_converted_csv/animation_timing.csv (timing data)
```

### Map Data (Bank $03 + others)
**Source**: Already partially extracted to `map_tilemaps.json`

**Complete Extraction**:
```
Bank $03 map data → data/maps/1_original_bin/map_data.bin
                  → 2_converted_tmx/ (Tiled-compatible TMX files)
                  → 3_converted_json/maps.json (enhanced metadata)
```

### Text Data (Multiple Banks)
**Source**: Already partially extracted to `text_data.json`

**Complete Extraction**:
```
All text banks → data/text/1_original_bin/compressed_text.bin
               → 2_converted_txt/dialog_strings.txt (decompressed)
               → 3_converted_json/text_metadata.json (pointers, encoding)
```

### Music Data (Separate SPC region)
**Source Addresses**: SPC700 RAM + ROM music banks

**Extraction**:
```
SPC700 region → data/music/1_original_bin/spc_sequences.bin
              → 2_converted_spc/ (playable .spc files)
              → 3_converted_json/music_metadata.json (tempo, instruments)
```

### Data Tables (Bank $07 + others)
**Source Addresses**:
- $07b932+: NPC configurations
- $07ba52+: Enemy formations
- $07ab38+: Object placement

**Extraction**:
```
Bank $07 NPC tables → data/tables/1_original_bin/npc_configs.bin
                    → 2_converted_csv/npc_configs.csv
                    → 3_converted_json/npc_configs.json
Enemy formations    → data/tables/1_original_bin/enemy_formations.bin
                    → 2_converted_csv/enemy_formations.csv
Object placement    → data/tables/1_original_bin/object_placement.bin
                    → 2_converted_csv/object_placement.csv
```

## Implementation Priority

1. **Create directory structure** (all `data/` subdirectories)
2. **Build extraction tools** (Python scripts to pull binary data)
3. **Extract Phase 1** (all binary data to `1_original_bin/`)
4. **Build conversion tools** (binary → PNG/JSON/CSV/TMX converters)
5. **Convert Phase 2** (all data to human-readable formats)
6. **Build reinsertion tools** (PNG/JSON/CSV → binary rebuilders)
7. **Validate Phase 3** (round-trip conversion verification)
8. **Git commit** (document entire extraction pipeline)

## Next Steps

Execute this plan to create a complete, bidirectional data extraction system that:
- ✅ Preserves original binary data
- ✅ Converts to editable formats (PNG, JSON, CSV, TMX, TXT)
- ✅ Supports round-trip conversion back to binary
- ✅ Validates byte-for-byte accuracy
- ✅ Documents all extraction addresses and formats
