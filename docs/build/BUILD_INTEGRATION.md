# Graphics Build Integration - Phase 2 Complete

## Overview

The graphics build integration system enables a complete round-trip workflow for editing FFMQ graphics:

```
Extract → Edit in PNG → Re-import → Build ROM
```

## Architecture

### Phase 1: Extraction (✅ COMPLETE)
- **extract_graphics.py** - Extract tiles from ROM to PNG
- **extract_sprites.py** - Assemble sprites from tiles
- **extract_enemy_palettes.py** - Extract enemy-specific palettes
- **reextract_enemies_correct_palettes.py** - Re-extract with correct colors
- **create_sprite_catalog.py** - Generate visual documentation

### Phase 2: Build Integration (✅ COMPLETE)
- **png_to_tiles.py** - Convert PNG back to 4BPP/2BPP tiles
- **import_sprites.py** - Re-import edited sprites
- **build_integration.py** - Manage complete pipeline

## Tools Created

### 1. PNG to Tiles Converter (`tools/import/png_to_tiles.py`)

Converts PNG images back to SNES tile format for ROM insertion.

**Features:**
- PNG → 4BPP tile encoding
- PNG → 2BPP tile encoding  
- Automatic palette generation from PNG
- RGB888 → RGB555 color conversion
- Tile validation and error checking

**Usage:**
```bash
# Convert PNG to 4BPP tiles with palette
python tools/import/png_to_tiles.py input.png output.bin --format 4bpp --auto-palette

# Convert PNG to 2BPP tiles
python tools/import/png_to_tiles.py sprite.png sprite.bin --format 2bpp

# Specify custom palette output
python tools/import/png_to_tiles.py image.png data.bin --palette custom_palette.json
```

**Technical Details:**
- Validates PNG dimensions are multiples of 8
- Extracts unique colors from PNG (max 16 for 4BPP, 4 for 2BPP)
- Generates palette sorted by transparency and brightness
- Encodes tiles using SNES bitplane format
- Outputs palette in RGB555 format compatible with ROM

### 2. Sprite Importer (`tools/import/import_sprites.py`)

Imports edited PNG sprites back into ROM-ready binary format.

**Features:**
- Batch import entire directories
- Single sprite import
- Metadata validation
- Palette binary export
- Import summary generation

**Usage:**
```bash
# Import entire directory of sprites
python tools/import/import_sprites.py data/extracted/sprites/enemies/ data/rebuilt/sprites/

# Import single sprite
python tools/import/import_sprites.py sprite.png sprite.bin --metadata sprite_meta.json
```

**Output:**
- `{sprite_name}.bin` - Binary tile data
- `{sprite_name}_palette.bin` - Palette in RGB555 format
- `import_summary.json` - Build manifest

### 3. Build Integration System (`tools/build_integration.py`)

Manages the complete graphics pipeline with incremental builds.

**Features:**
- Automatic detection of modified PNGs
- Incremental rebuild (only changed graphics)
- Build manifest tracking (SHA256 hashes)
- Validation and error checking
- Integration with extraction tools

**Usage:**
```bash
# Extract all graphics from ROM
python tools/build_integration.py --extract

# Rebuild only modified graphics
python tools/build_integration.py --rebuild

# Full rebuild (extract + rebuild)
python tools/build_integration.py --full

# Validate all graphics
python tools/build_integration.py --validate
```

**Build Manifest:**
The system maintains `build/graphics_manifest.json` to track:
- File hashes (SHA256)
- Last modification times
- Build timestamps

## Workflow Examples

### Editing an Enemy Sprite

1. **Extract** (if not already done):
   ```bash
   python tools/build_integration.py --extract
   ```

2. **Edit** the sprite in your favorite editor:
   - Open `data/extracted/sprites/enemies/enemy_18_skeleton.png`
   - Edit in Aseprite, GIMP, etc.
   - Save (preserve palette and dimensions!)

3. **Rebuild**:
   ```bash
   python tools/build_integration.py --rebuild
   ```
   - System detects changed PNG
   - Re-imports to `data/rebuilt/sprites/enemies/`
   - Generates binary tile data

4. **Build ROM** (future integration):
   ```bash
   make rom
   ```
   - Asar assembler includes rebuilt graphics
   - Creates modified ROM with your changes

### Creating New Graphics

1. **Create PNG** matching format:
   - Dimensions: Multiple of 8 (e.g., 24×24 for 3×3 tiles)
   - Colors: Max 16 colors for 4BPP, 4 for 2BPP
   - Format: PNG with transparency

2. **Create metadata** JSON:
   ```json
   {
     "name": "my_sprite",
     "format": "4bpp",
     "tile_width": 3,
     "tile_height": 3,
     "rom_offset": "0x??????",
     "palette_offset": "0x??????"
   }
   ```

3. **Import**:
   ```bash
   python tools/import/import_sprites.py my_sprite.png my_sprite.bin --metadata my_sprite_meta.json
   ```

## File Structure

```
data/
├── extracted/              # Extracted graphics (edit these!)
│   ├── sprites/
│   │   ├── enemies/        # 83 enemy sprites with correct palettes
│   │   ├── characters/     # 4 character battle sprites
│   │   └── ui/             # UI elements
│   ├── graphics/
│   │   ├── tiles/          # Individual tiles
│   │   └── palettes/       # Palette JSON files
│   └── palettes/
│       └── enemy_palettes.json
│
├── rebuilt/                # Re-imported graphics (binary)
│   └── sprites/
│       ├── enemies/
│       │   ├── enemy_00_brownie.bin
│       │   ├── enemy_00_brownie_palette.bin
│       │   └── ...
│       └── import_summary.json
│
└── build/
    └── graphics_manifest.json  # Build tracking
```

## Format Specifications

### 4BPP Tile Format
- **Size:** 32 bytes per 8×8 tile
- **Colors:** 16 colors per tile
- **Bitplanes:** 4 (2 bytes × 8 rows × 2 bitplane pairs)
- **Layout:**
  - Bytes 0-15: Bitplanes 0-1 (2 bytes per row)
  - Bytes 16-31: Bitplanes 2-3 (2 bytes per row)

### 2BPP Tile Format
- **Size:** 16 bytes per 8×8 tile
- **Colors:** 4 colors per tile
- **Bitplanes:** 2 (2 bytes × 8 rows)
- **Layout:**
  - Bytes 0-15: Bitplanes 0-1 (2 bytes per row)

### RGB555 Palette Format
- **Format:** 15-bit BGR color (0bbbbbgg gggrrrrr)
- **Size:** 2 bytes per color (little-endian)
- **Conversion:** `RGB888 → RGB555 = (R>>3, G>>3, B>>3)`

## Integration with Asar

The rebuild system prepares graphics for integration with the asar assembler:

```asm
; Example: Include rebuilt enemy sprite
org $098000
incbin "data/rebuilt/sprites/enemies/enemy_18_skeleton.bin"

; Example: Include rebuilt palette
org $048120  
incbin "data/rebuilt/sprites/enemies/enemy_18_skeleton_palette.bin"
```

**Future Enhancement:**
Auto-generate `.asm` include files from import summary.

## Validation

The system includes comprehensive validation:

### Automatic Checks
- ✓ PNG dimensions are multiples of 8
- ✓ Color count within format limits
- ✓ Metadata exists for each PNG
- ✓ PNG exists for each metadata file
- ✓ File hash tracking for changes

### Manual Verification
```bash
# Validate all graphics
python tools/build_integration.py --validate
```

Checks for:
- Orphaned metadata files
- Missing metadata files  
- Corrupt PNG files
- Invalid dimensions

## Performance

### Incremental Builds
- Only rebuilds **changed** PNGs (SHA256 hash tracking)
- Typical rebuild: < 1 second for single sprite
- Full rebuild: ~5-10 seconds for all 89 sprites

### Build Manifest
Located at `build/graphics_manifest.json`:
```json
{
  "version": "1.0",
  "last_build": "2025-11-02T01:23:45",
  "files": {
    "data/extracted/sprites/enemies/enemy_18_skeleton.png": {
      "hash": "a7f3b2c1...",
      "last_modified": "2025-11-02T01:20:00"
    }
  }
}
```

## Status

### ✅ Completed
- PNG → Tile conversion (4BPP/2BPP)
- Palette RGB888 → RGB555 conversion
- Sprite import system
- Build manifest tracking
- Incremental rebuild detection
- Validation system
- Documentation

### 🔄 Next Steps
1. Asar integration (auto-generate include files)
2. ROM insertion automation
3. Build verification (compare rebuilt vs original)
4. Continuous integration tests

## Technical Notes

### Color Conversion Accuracy
RGB888 → RGB555 conversion is lossy due to bit depth reduction:
- RGB888: 8 bits per channel = 16.7M colors
- RGB555: 5 bits per channel = 32K colors

The conversion formula preserves visual accuracy:
```python
rgb555 = ((r >> 3) << 0) | ((g >> 3) << 5) | ((b >> 3) << 10)
```

### Tile Encoding Algorithm
4BPP tiles use planar encoding where each pixel's 4 bits are split across 4 bitplanes:
```
Pixel value: 0b1101 (13)
Bitplane 0: bit 0 = 1
Bitplane 1: bit 1 = 0  
Bitplane 2: bit 2 = 1
Bitplane 3: bit 3 = 1
```

This matches the SNES PPU's native tile format.

## References

- [SNES Development Manual - Graphics](https://snes.nesdev.org/wiki/Graphics)
- [4BPP Tile Format](https://snes.nesdev.org/wiki/Tile_formats#4bpp)
- [RGB555 Color Format](https://snes.nesdev.org/wiki/Palette)
- FFMQ ROM Map (Banks 04/05/06/09 documentation)

---

**Author:** FFMQ Disassembly Project  
**Date:** 2025-11-02  
**Version:** 2.0 - Build Integration Phase
