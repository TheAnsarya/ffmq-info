# Graphics Tools

This directory contains tools for working with Final Fantasy Mystic Quest's graphics, including sprites, tiles, palettes, backgrounds, and visual effects.

## Core Graphics Libraries

### SNES Graphics Engine
- **snes_graphics.py** ⭐ - Core SNES graphics format handler
  - 2bpp, 3bpp, 4bpp, 8bpp tile decoding/encoding
  - Planar to chunky conversion
  - Palette management (15-bit BGR555)
  - Tile arrangement and mapping
  - Usage: Import as module or run standalone

### Conversion Tools
- **convert_graphics.py** ⭐ - Convert between graphics formats
  - PNG ↔ SNES tile format
  - Batch conversion support
  - Automatic palette extraction
  - Tile deduplication
  - Usage: `python tools/graphics/convert_graphics.py --input <file> --output <file> --format <2bpp|4bpp>`

- **graphics_converter.py** - Legacy graphics converter
  - Alternative conversion implementation
  - Specific format support
  - Usage: `python tools/graphics/graphics_converter.py <input> <output>`

### Palette Management
- **palette_manager.py** - Palette editing and management
  - Extract palettes from ROM/images
  - Edit colors in multiple formats (RGB, HSV, hex)
  - Apply palettes to graphics
  - Palette optimization
  - Export/import palette files
  - Usage: `python tools/graphics/palette_manager.py [--extract|--apply|--edit]`

## Asset Generation

### Assembly Generation
- **generate_graphics_asm.py** - Generate assembly from graphics data
  - Create .asm includes for graphics data
  - Generate tile definitions
  - Create palette definitions
  - Build CHR ROM sections
  - Usage: `python tools/graphics/generate_graphics_asm.py --input <data> --output <file.asm>`

### Inventory and Cataloging
- **inventory_graphics.py** - Catalog all graphics in ROM
  - Scan ROM for graphics data
  - Generate visual inventory
  - Create graphics database
  - Export catalog to HTML/JSON
  - Usage: `python tools/graphics/inventory_graphics.py --output <catalog.html>`

## Visualization Tools

### Data Visualization
- **visualize_elements.py** - Visualize elemental data
  - Create element interaction charts
  - Visualize weakness/resistance matrices
  - Generate element distribution graphs
  - Usage: `python tools/graphics/visualize_elements.py --output <chart.png>`

- **visualize_enemy_attacks.py** - Visualize enemy attack patterns
  - Chart attack usage by enemy
  - Visualize attack power distribution
  - Create attack element breakdown
  - Usage: `python tools/graphics/visualize_enemy_attacks.py --output <chart.png>`

- **visualize_spell_effectiveness.py** - Visualize spell effectiveness
  - Create spell damage charts
  - Compare spell efficiency
  - Visualize MP cost vs power
  - Usage: `python tools/graphics/visualize_spell_effectiveness.py --output <chart.png>`

## Testing

- **test_graphics_pipeline.py** - Test graphics conversion pipeline
  - Validate round-trip conversions
  - Test palette extraction
  - Verify tile encoding/decoding
  - Benchmark performance
  - Usage: `python tools/graphics/test_graphics_pipeline.py`

## Common Workflows

### Extracting and Editing Sprites
```bash
# 1. Extract sprite from ROM
python tools/data-extraction/extract_graphics_v2.py --type sprite --id 42 --output sprite42.png

# 2. Edit sprite42.png in image editor (maintain palette!)

# 3. Convert back to SNES format
python tools/graphics/convert_graphics.py --input sprite42.png --output sprite42.bin --format 4bpp

# 4. Integrate into ROM
python tools/import/import_graphics.py --type sprite --id 42 --input sprite42.bin

# 5. Test in emulator
```

### Creating Custom Palettes
```bash
# 1. Extract existing palette
python tools/graphics/palette_manager.py --extract --address 0x0C8000 --output palette.pal

# 2. Edit palette colors
python tools/graphics/palette_manager.py --edit --input palette.pal

# 3. Apply to graphics
python tools/graphics/palette_manager.py --apply --palette palette.pal --input sprite.png --output sprite_recolored.png

# 4. Convert and import
python tools/graphics/convert_graphics.py --input sprite_recolored.png --output sprite.bin --format 4bpp
python tools/import/import_graphics.py --input sprite.bin --address 0x0C8000
```

### Generating Graphics Assembly
```bash
# 1. Extract graphics data
python tools/data-extraction/extract_graphics_v2.py --bank 0x0C --output graphics_bank0C/

# 2. Generate assembly includes
python tools/graphics/generate_graphics_asm.py --input graphics_bank0C/ --output src/data/graphics_bank0C.asm

# 3. Include in build
# Add to src/main.asm: .include "data/graphics_bank0C.asm"

# 4. Rebuild ROM
python tools/build/build_rom.py
```

### Creating Graphics Inventory
```bash
# Generate comprehensive graphics catalog
python tools/graphics/inventory_graphics.py --output reports/graphics_inventory.html

# Open in browser to browse all graphics
```

### Visualizing Game Data
```bash
# Create element interaction chart
python tools/graphics/visualize_elements.py --output reports/elements.png

# Create enemy attack distribution chart
python tools/graphics/visualize_enemy_attacks.py --output reports/enemy_attacks.png

# Create spell effectiveness comparison
python tools/graphics/visualize_spell_effectiveness.py --output reports/spell_effectiveness.png
```

## SNES Graphics Formats

### Tile Formats

**2bpp (4 colors)**
- Used for: Simple backgrounds, UI elements
- Size: 16 bytes per 8x8 tile
- Colors per tile: 4 (including transparency)

**4bpp (16 colors)**
- Used for: Sprites, detailed backgrounds, character graphics
- Size: 32 bytes per 8x8 tile
- Colors per tile: 16 (including transparency)

**8bpp (256 colors)**
- Used for: Mode 7 graphics (rare in FFMQ)
- Size: 64 bytes per 8x8 tile
- Colors per tile: 256

### Palette Format

**BGR555 Format**
- 15-bit color (5 bits per channel)
- Format: `0bbbbbgggggrrrrr` (MSB to LSB)
- Color $0000 is transparent
- 8 palettes × 16 colors = 128 colors max on screen

```python
# Convert RGB888 to BGR555
def rgb_to_bgr555(r, g, b):
    r5 = (r >> 3) & 0x1F
    g5 = (g >> 3) & 0x1F
    b5 = (b >> 3) & 0x1F
    return (b5 << 10) | (g5 << 5) | r5

# Convert BGR555 to RGB888
def bgr555_to_rgb(bgr555):
    r5 = bgr555 & 0x1F
    g5 = (bgr555 >> 5) & 0x1F
    b5 = (bgr555 >> 10) & 0x1F
    r = (r5 << 3) | (r5 >> 2)
    g = (g5 << 3) | (g5 >> 2)
    b = (b5 << 3) | (b5 >> 2)
    return (r, g, b)
```

### Tile Arrangement

**Tilemap Format**
- 2 bytes per tile entry
- Bits 0-9: Tile index (0-1023)
- Bit 10-12: Palette number (0-7)
- Bit 13: Priority
- Bit 14: X flip
- Bit 15: Y flip

```python
# Parse tilemap entry
tile_num = entry & 0x03FF
palette = (entry >> 10) & 0x07
priority = (entry >> 13) & 0x01
x_flip = (entry >> 14) & 0x01
y_flip = (entry >> 15) & 0x01
```

## Image Editor Recommendations

### For Sprite Editing
- **Aseprite** - Best for pixel art and animation
- **GraphicsGale** - Free, good palette support
- **GIMP** - Free, powerful but complex
- **Photoshop** - Professional, expensive

### Important Editor Settings
- Use indexed color mode (256 colors max)
- Disable antialiasing
- Disable dithering on save
- Export as PNG-8 with exact palette
- Keep transparent color at index 0

## File Format Reference

### .PAL - Palette File
```
# JASC-PAL
# 0100
# 16
255 0 255    # Color 0 (transparency - magenta placeholder)
248 248 248  # Color 1
216 216 216  # Color 2
...
```

### .CHR - Tile Data File
- Raw SNES tile data
- Format specified by extension: `.2bpp.chr`, `.4bpp.chr`
- No header, just raw planar data

### .TIL - Tilemap File
- 2 bytes per tile entry
- Little-endian format
- Can include header with dimensions

## Dependencies

- Python 3.7+
- **PIL/Pillow** - `pip install Pillow`
- **numpy** - `pip install numpy` (for visualization)
- **matplotlib** - `pip install matplotlib` (for charts)
- ROM access modules from `tools/rom-operations/`

## See Also

- **tools/data-extraction/** - For extracting graphics from ROM
- **tools/import/** - For importing graphics into ROM
- **tools/battle/** - For battle graphics and enemy sprites
- **docs/technical/GRAPHICS_FORMAT.md** - Detailed format documentation
- **docs/rom-hacking/GRAPHICS_GUIDE.md** - Graphics hacking guide

## Tips and Best Practices

### Sprite Editing
- Always work with PNG-8 indexed color
- Never exceed 16 colors per sprite (4bpp)
- Keep color 0 transparent (magenta placeholder)
- Use consistent palettes across related sprites
- Test in emulator frequently

### Palette Creation
- Start from extracted original palettes
- Maintain color count (don't add colors)
- Test readability on CRT and LCD
- Consider colorblind accessibility
- Save intermediate versions

### Graphics Conversion
- Always test round-trip conversion (PNG → CHR → PNG)
- Verify tile deduplication works correctly
- Check palette order preservation
- Validate against original data
- Use `test_graphics_pipeline.py` regularly

### Performance
- Cache decoded tiles when processing multiple
- Use numpy for batch operations
- Minimize PIL format conversions
- Profile with `cProfile` for optimization

## Common Issues and Solutions

**Issue: Colors look wrong after import**
- Cause: Palette order mismatch
- Solution: Use `palette_manager.py --verify` to check palette

**Issue: Sprites appear garbled**
- Cause: Wrong bpp format used
- Solution: Verify format with `snes_graphics.py --analyze`

**Issue: Transparency not working**
- Cause: Color 0 is not transparent in palette
- Solution: Set color 0 to magenta (255,0,255) in source PNG

**Issue: Conversion produces wrong colors**
- Cause: RGB888 ↔ BGR555 rounding errors
- Solution: Use exact color values from original palette

**Issue: Graphics too large for ROM space**
- Cause: Not enough free space at target address
- Solution: Use compression or relocate to expanded ROM

## Advanced Topics

### Compression
Some graphics in FFMQ use custom compression. See `tools/rom-operations/ffmq_compression.py` for decompression utilities.

### Mode 7 Graphics
FFMQ uses Mode 7 for overworld. These graphics use different formats and require special handling.

### Animation
Sprite animations are controlled by data tables. See `docs/technical/ANIMATION_FORMAT.md` for details.

## Contributing

When adding graphics tools:
1. Use `snes_graphics.py` as base library
2. Support batch operations where applicable
3. Include format validation
4. Add visual preview/export for debugging
5. Document format specifications
6. Add tests to `test_graphics_pipeline.py`
7. Update this README

## Future Development

Planned additions:
- [ ] Animation editor GUI
- [ ] Sprite sheet generator
- [ ] Palette swap tool
- [ ] Graphics compression tool
- [ ] Tile optimizer (deduplication)
- [ ] Background editor
- [ ] Real-time emulator preview
- [ ] Graphics diff tool
