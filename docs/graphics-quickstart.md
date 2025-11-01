# Graphics Tools Quick Start Guide

Get started editing FFMQ graphics in 5 minutes!

## Prerequisites

```bash
# Install Python dependencies
make install-deps
# Or manually:
pip install Pillow
```

## Basic Workflow

### 1. Extract Graphics from ROM

```bash
# Extract all graphics with PNG output
make extract-graphics
```

This creates:
- `assets/graphics/*.png` - Editable PNG images
- `assets/graphics/*_raw.bin` - Original SNES tile data
- `assets/graphics/*_palette.bin` - Color palettes
- `assets/graphics/README.md` - Documentation

### 2. Edit Graphics

Open PNG files in your favorite image editor:
- **GIMP** (Free): Works great with indexed colors
- **Aseprite** (Paid): Excellent for pixel art
- **Photoshop**: Also works

**Important:**
- Keep 8×8 tile boundaries
- Use indexed color mode (4BPP = 16 colors max)
- Color 0 is always transparent

### 3. Convert Back to SNES Format

```bash
# Convert edited PNG to SNES tiles
make convert-graphics-to-snes \
    INPUT=assets/graphics/main_tiles_edited.png \
    OUTPUT=assets/graphics/main_tiles_new.bin \
    BPP=4
```

### 4. Test Your Changes

```bash
# Build ROM with your changes and test
make rom
make test-launch
```

## Common Tasks

### View Tiles as PNG

```bash
# Convert SNES tiles to PNG for viewing
python tools/convert_graphics.py to-png \
    tiles.bin \
    output.png \
    --palette palette.bin \
    --bpp 4 \
    --tiles-per-row 16
```

**Options:**
- `--bpp 2|4|8` - Bits per pixel (2=4 colors, 4=16 colors, 8=256 colors)
- `--tiles-per-row 16` - How many tiles per row in PNG
- `--indexed` - Save as indexed PNG (preserves exact palette)
- `--palette file.bin` - Use specific palette file

### Edit Specific Tile Set

```bash
# 1. Extract just the tiles you want
python tools/convert_graphics.py to-png \
    assets/graphics/sprite_tiles_raw.bin \
    my_sprites.png \
    --bpp 4 \
    --indexed

# 2. Edit my_sprites.png in your image editor

# 3. Convert back
python tools/convert_graphics.py to-snes \
    my_sprites.png \
    sprite_tiles_modified.bin \
    --bpp 4
```

### Create Custom Tiles

```bash
# 1. Create PNG in image editor
#    - Use indexed color mode
#    - 8x8 pixel tiles
#    - 16 colors max (for 4BPP)
#    - Arrange in grid (16 tiles per row)

# 2. Convert to SNES format
python tools/convert_graphics.py to-snes \
    custom_tiles.png \
    custom_tiles.bin \
    --bpp 4 \
    --palette custom_palette.bin

# 3. Use in your assembly code
# custom_tiles.bin now contains SNES-format tiles
```

### Edit Palettes

```bash
# 1. Extract and view palette
make extract-graphics
# Check assets/graphics/main_palettes_palette.txt for colors

# 2. Edit palette.bin in hex editor
#    Format: 2 bytes per color (RGB555)
#    $0000-$001f: Red (5 bits)
#    $0020-$03ff: Green (5 bits)
#    $0400-$7fff: Blue (5 bits)

# 3. Or create new palette from PNG
python tools/convert_graphics.py to-snes \
    image_with_palette.png \
    tiles.bin \
    --bpp 4 \
    --palette new_palette.bin
```

## Understanding SNES Graphics

### Tile Formats

| Format | Bytes per Tile | Colors | Common Use |
|--------|----------------|--------|------------|
| 2BPP | 16 bytes | 4 | Fonts, simple UI |
| 4BPP | 32 bytes | 16 | Most FFMQ graphics |
| 8BPP | 64 bytes | 256 | High-detail images |

### Palette Organization

- **Full palette:** 256 colors (16 sub-palettes × 16 colors)
- **Sub-palette:** 16 colors each
- **Color 0:** Always transparent in each sub-palette
- **Sprites:** Use sub-palettes 8-15
- **Backgrounds:** Use sub-palettes 0-7

### Tile Layout

```
One 8x8 tile = 64 pixels arranged like:

  0 1 2 3 4 5 6 7  (X →)
0 □ □ □ □ □ □ □ □
1 □ □ □ □ □ □ □ □
2 □ □ □ □ □ □ □ □
3 □ □ □ □ □ □ □ □
4 □ □ □ □ □ □ □ □
5 □ □ □ □ □ □ □ □
6 □ □ □ □ □ □ □ □
7 □ □ □ □ □ □ □ □
(Y ↓)
```

## Image Editor Tips

### GIMP

```
1. Open PNG
2. Image → Mode → Indexed
3. Set max colors to 16 (for 4BPP)
4. Windows → Dockable Dialogs → Colormap
5. Edit colors in colormap
6. Export as PNG
```

### Aseprite

```
1. File → Open
2. Already works with indexed color!
3. View → Show Grid (set to 8×8)
4. Edit with pixel-perfect tools
5. File → Export
```

### Setting Up Grid

Most editors support a pixel grid:
- **Grid size:** 8×8 pixels
- **Enable snap to grid**
- **Show grid lines**

This helps you see tile boundaries while editing!

## Troubleshooting

### "PIL not found" Error

```bash
# Install Pillow (PIL fork)
pip install Pillow
```

### Colors Look Wrong

- SNES uses RGB555 (5 bits per channel)
- Some colors may look slightly different
- Test on actual emulator to see true colors
- Use provided palette files for accuracy

### Tiles Corrupted After Editing

- Make sure you saved as **indexed color** PNG
- Don't use more than 16 colors (for 4BPP)
- Keep alpha/transparency in color 0
- Maintain 8×8 pixel boundaries

### PNG Won't Convert

```bash
# Force re-quantize to correct color count
python tools/convert_graphics.py to-snes \
    input.png \
    output.bin \
    --bpp 4  # This will auto-quantize to 16 colors
```

## Advanced Usage

### Batch Convert Multiple Files

PowerShell:
```powershell
# Convert all bin files to PNG
Get-ChildItem assets/graphics/*.bin | ForEach-Object {
    python tools/convert_graphics.py to-png `
        $_.FullName `
        ($_.BaseName + ".png") `
        --bpp 4
}
```

### Extract Specific Tile Range

```python
# Python script
from snes_graphics import decode_tiles, SNESPalette
from convert_graphics import TileImageConverter

with open('tiles.bin', 'rb') as f:
    data = f.read()

# Extract tiles 100-199 only
tiles = decode_tiles(data, offset=100*32, count=100, bpp=4)

# Convert to PNG...
```

### Custom Palette from Image

```bash
# This extracts both tiles AND generates palette
python tools/convert_graphics.py to-snes \
    reference_image.png \
    tiles.bin \
    --bpp 4 \
    --palette extracted_palette.bin
```

## Next Steps

1. **Read the full documentation:**
   - `docs/graphics-format.md` - Complete SNES format reference
   - `assets/graphics/README.md` - Extracted graphics info

2. **Try the examples:**
   - Edit a simple tile set
   - Change some colors
   - Create custom graphics

3. **Build and test:**
   ```bash
   make rom
   make test-launch
   ```

4. **Explore advanced tools:**
   - YY-CHR for tile editing
   - Tile Molester for analysis
   - Custom Python scripts

---

**Need Help?**

- Check `docs/graphics-format.md` for technical details
- See `tools/README.md` for tool documentation
- Read SNES dev wiki for general SNES info

**Happy hacking! 🎮**
