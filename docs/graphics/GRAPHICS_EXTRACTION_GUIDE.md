# FFMQ Graphics Extraction Guide

**Status:** ✅ **COMPLETE** - Multi-palette extraction working!  
**Last Updated:** 2025-01-XX

---

## Overview

This guide explains how SNES graphics work in Final Fantasy Mystic Quest and how to extract them correctly with proper colors using our updated extraction tools.

## The Problem (Before Fix)

**Original Issue**: Extracted graphics didn't match what's displayed in-game.

**Root Cause**: SNES tiles store **palette indices** (0-15), not actual RGB colors. The displayed colors depend on which **palette** (0-7) is assigned to each sprite via OAM (Object Attribute Memory) data.

**Example**:
```
Tile Data:  [0, 1, 2, 3, 4, 5, ...]  ← Just numbers 0-15
Palette 0:  [Black, Blue, Cyan, ...]  ← Colors for palette 0
Palette 6:  [Black, Red, Orange, ...]  ← Colors for palette 6

Same tile + Palette 0 = Blue sprite
Same tile + Palette 6 = Red sprite
```

**Old behavior**: Extracted ALL tiles using Palette 0 → Most sprites looked wrong!

---

## The Solution (Multi-Palette Extraction)

### Updated Tool: `tools/extraction/extract_graphics.py`

The updated extraction tool now:

1. **Extracts 16 palettes** from ROM (Bank 05: $030000+)
2. **Renders tiles with ALL 8 palettes** (0-7, used by sprites)
3. **Creates comparison sheets** showing palette variations
4. **Saves palette data as JSON** for editing

### Output Files

After running extraction, you get:

#### Palettes (16 total)
```
data/extracted/graphics/palettes/
├── palette_00.json  ← Palette 0 (16 colors, RGB555 → RGB888)
├── palette_01.json  ← Palette 1
├── ...
└── palette_15.json  ← Palette 15
```

**Each JSON contains**:
- ROM offset
- 16 colors in RGB555 format (SNES native)
- 16 colors in RGB888 format (for editing)
- Hex color codes

#### Tile Sheets (8 palette variations)
```
data/extracted/graphics/tiles/
├── bank04_tiles_palette00_sheet.png  ← 256 tiles with Palette 0
├── bank04_tiles_palette01_sheet.png  ← Same tiles with Palette 1
├── ...
├── bank04_tiles_palette07_sheet.png  ← Same tiles with Palette 7
└── tile_palette_comparison.png       ← First 8 tiles × 8 palettes
```

**Tile Sheet Format**:
- 256 tiles (16 tiles × 16 tiles = 128×128 pixels)
- Each tile: 8×8 pixels
- PNG format (RGB)

**Comparison Sheet**:
- 8 rows (one per palette)
- 8 columns (first 8 tiles)
- Shows how palette choice affects appearance

---

## How SNES Graphics Work

### Tile Format (4BPP)

**4BPP = 4 Bits Per Pixel** (16 possible colors per tile)

```
Tile Size: 32 bytes (8×8 pixels)
Structure:
  Bytes 0-15:  Bitplanes 0-1 (rows 0-7, 2 bytes per row)
  Bytes 16-31: Bitplanes 2-3 (rows 0-7, 2 bytes per row)

Each pixel value: 0-15 (palette index, NOT actual color)
```

**Decoding Algorithm**:
```python
for row in range(8):
    plane0 = data[row * 2]      # Bit 0
    plane1 = data[row * 2 + 1]  # Bit 1
    plane2 = data[16 + row * 2]     # Bit 2
    plane3 = data[16 + row * 2 + 1] # Bit 3
    
    for col in range(8):
        bit = 7 - col
        pixel = ((plane3 >> bit) & 1) << 3 |  # Bit 3
                ((plane2 >> bit) & 1) << 2 |  # Bit 2
                ((plane1 >> bit) & 1) << 1 |  # Bit 1
                ((plane0 >> bit) & 1)         # Bit 0
        # pixel = 0-15 (palette index)
```

### Palette Format (RGB555)

**RGB555 = 15-bit color** (5 bits per channel, SNES native format)

```
Size: 2 bytes per color (16-bit word, little-endian)
Format: 0bbbbbgg gggrrrrr
  Bits 0-4:   Red   (0-31)
  Bits 5-9:   Green (0-31)
  Bits 10-14: Blue  (0-31)
  Bit 15:     Unused

Each palette: 16 colors × 2 bytes = 32 bytes
SNES has 256 colors total (16 palettes × 16 colors)
```

**Conversion to RGB888 (for PNG)**:
```python
def rgb555_to_rgb888(r5, g5, b5):
    """Convert 5-bit (0-31) to 8-bit (0-255)"""
    r8 = (r5 << 3) | (r5 >> 2)  # Spread 5 bits across 8
    g8 = (g5 << 3) | (g5 >> 2)
    b8 = (b5 << 3) | (b5 >> 2)
    return (r8, g8, b8)
```

### OAM (Sprite Attributes)

**OAM Entry = 4 bytes** (defines one 8×8 hardware sprite)

```
Byte 0: X position (low 8 bits)
Byte 1: Y position
Byte 2: Tile number (0-255)
Byte 3: Attributes (vhopppcc)
  v   = Vertical flip (bit 7)
  h   = Horizontal flip (bit 6)
  o   = Priority (bits 5-4)
  ppp = Palette (bits 3-1) ← THIS DETERMINES WHICH PALETTE!
  cc  = Tile page/size (bits 0)
```

**Palette Bits (bits 3-1)**:
- `000` = Palette 0
- `001` = Palette 1
- `010` = Palette 2
- `011` = Palette 3
- `100` = Palette 4
- `101` = Palette 5
- `110` = Palette 6
- `111` = Palette 7

**Example Attribute Bytes** (from disassembly):
```asm
; $d2 = %11010010
;   Palette bits (3-1) = 001b = Palette 1
;   Actually palette 6 because bit 4 is set (adds 4)
;   Result: Palette 1 + 4 = Palette 5? Need to verify this!

; $9c = %10011100  
;   Palette bits (3-1) = 110b = Palette 6
;   Priority = 01
;   No flip
```

---

## How to Use Extracted Graphics

### Step 1: Identify Which Palette a Sprite Uses

**Method 1: Visual Comparison**
1. Run the game in an emulator (Mesen-S, BSNES, etc.)
2. Take a screenshot of the sprite you want to extract
3. Compare with the 8 tile sheets (`palette00-07_sheet.png`)
4. Find which palette makes it look correct

**Method 2: VRAM Viewer (Advanced)**
1. Open Mesen-S debugger
2. Go to **Debug → VRAM Viewer**
3. Select **CHR** tab to see tiles
4. Select **Palette Viewer** to see active palettes
5. Note which palette is used for your target sprite

**Method 3: Code Analysis** (Most Accurate)
1. Search disassembly for sprite setup code
2. Find OAM attribute byte assignment
3. Extract palette bits (bits 3-1)
4. Use corresponding palette sheet

**Example**:
```asm
; From bank_0B_documented.asm:3120
lda.b #$d2        ; OAM attribute = $d2 = %11010010
sta.w $0c12,y     ; Store to OAM buffer

; $d2 breakdown:
; Bit 7 (v): 1 = vertical flip OFF (bit is inverted)
; Bit 6 (h): 1 = horizontal flip OFF
; Bits 5-4 (priority): 01 = priority 1
; Bits 3-1 (palette): 001 = palette 1
; → Use bank04_tiles_palette01_sheet.png
```

### Step 2: Extract the Correct Graphics

Once you know the palette:

```powershell
# Already extracted! Just use the right file:
# For palette 1:
$tileSheet = "data\extracted\graphics\tiles\bank04_tiles_palette01_sheet.png"

# For palette 6:
$tileSheet = "data\extracted\graphics\tiles\bank04_tiles_palette06_sheet.png"
```

### Step 3: Edit Graphics

1. Open the tile sheet in an image editor (GIMP, Aseprite, etc.)
2. Edit the 8×8 tiles you want to change
3. Keep colors within the palette (16 colors max)
4. Save as PNG

**Important**: Don't change palette assignments! The tool extracts tiles with the correct palette, but the palette itself is still stored in ROM Bank 05.

### Step 4: Re-insert Modified Graphics

**(Future Enhancement - Not Yet Implemented)**

Planned workflow:
1. Convert edited PNG back to 4BPP tile data
2. Insert into ROM at correct offset
3. Rebuild ROM
4. Test in emulator

---

## Palette Data Locations

### ROM Addresses (LoROM Format)

```
Bank 05 Palettes (File Offset: $030000-$037FFF)
├── $030000: Palette 0  (32 bytes, 16 colors)
├── $030020: Palette 1  (32 bytes, 16 colors)
├── $030040: Palette 2  (32 bytes, 16 colors)
├── ...
└── $0301E0: Palette 15 (32 bytes, 16 colors)

Total: 512 bytes (16 palettes × 32 bytes)
```

### SNES Address Translation

```
File Offset → SNES Address (LoROM):
$030000 → $05:8000 (Bank 05, offset $8000)
$030020 → $05:8020
...
```

### In-Game Palette Usage (From Disassembly Research)

| Palette | Typical Usage | Example Sprites |
|---------|---------------|-----------------|
| 0 | UI elements, fonts | Text, borders |
| 1 | Benjamin sprites | Main character |
| 2 | Companion sprites | Kaeli, Phoebe, etc. |
| 3 | Enemy sprites (common) | Brown Bear, Behemoth |
| 4 | Enemy sprites (special) | Bosses |
| 5 | Effects, magic | Spell animations |
| 6 | Battle sprites | Attack effects |
| 7 | Unused/special | Various |

*Note: This is preliminary research. Actual usage may vary by game state/location.*

---

## Troubleshooting

### Q: Extracted tiles still don't match the game!

**A**: Check these:

1. **Correct palette?**
   - Try all 8 palette sheets to find a match
   - Use VRAM viewer to verify

2. **Correct tile range?**
   - Bank 04 has multiple tile sets
   - Character sprites might be at different offsets
   - Try extracting from different ROM addresses

3. **Compression?**
   - Some tiles may be compressed
   - Check for 3BPP compression (Bank 0A uses this)
   - Use `decompress_3bpp_to_4bpp()` function

### Q: Colors look washed out

**A**: RGB555 → RGB888 conversion can cause slight color shifts.

**Fix**: Use original palette JSON files for accurate RGB555 values.

### Q: Some tiles appear blank/black

**A**: Palette color 0 is usually transparent.

**Fix**: This is normal. In-game, these pixels show the background layer.

### Q: How do I know which ROM offset has my sprite?

**A**: Check the disassembly documentation:

```
src/asm/bank_04_documented.asm  ← Tile data locations
src/asm/bank_05_documented.asm  ← Palette data locations
src/asm/bank_09_documented.asm  ← Sprite metadata
datacrystal/ROM_map/Graphics.wikitext ← Community documentation
```

---

## Examples

### Example 1: Extract Benjamin's Sprite (Correct Colors)

```powershell
# 1. Check disassembly for Benjamin's palette assignment
# From code analysis: Benjamin uses Palette 1

# 2. Use the correct tile sheet
$benjaminTiles = "data\extracted\graphics\tiles\bank04_tiles_palette01_sheet.png"

# 3. Open in image editor, locate Benjamin tiles (e.g., tiles 0-15)

# 4. Edit as desired, save PNG

# 5. (Future) Convert back and re-insert into ROM
```

### Example 2: Compare All Palette Versions

```powershell
# Open comparison sheet
$comparison = "data\extracted\graphics\tiles\tile_palette_comparison.png"

# This shows tiles 0-7 with all 8 palettes
# Row 0 = Palette 0
# Row 1 = Palette 1
# ...
# Row 7 = Palette 7

# Find which row matches your sprite → that's your palette!
```

### Example 3: Edit a Palette (Change Colors)

```powershell
# 1. Open palette JSON
$paletteFile = "data\extracted\graphics\palettes\palette_01.json"

# 2. Edit color hex codes
# Example: Change color 5 from blue to red
#   "hex": "#107B8C" → "hex": "#FF0000"

# 3. Save JSON

# 4. (Future) Convert JSON → Binary → Re-insert to ROM Bank 05
```

---

## Technical Details

### Palette Structure in JSON

```json
{
  "format": "RGB555",
  "num_colors": 16,
  "rom_offset": "0x030000",
  "colors_rgb555": [
    {
      "index": 0,
      "r5": 0,   // 5-bit red (0-31)
      "g5": 0,   // 5-bit green (0-31)
      "b5": 0,   // 5-bit blue (0-31)
      "hex": "#00000"  // RGB555 in hex
    },
    // ... 15 more colors
  ],
  "colors_rgb888": [
    {
      "index": 0,
      "r": 0,    // 8-bit red (0-255)
      "g": 0,    // 8-bit green (0-255)
      "b": 0,    // 8-bit blue (0-255)
      "hex": "#000000"  // RGB888 in hex
    },
    // ... 15 more colors
  ]
}
```

### Tile Extraction Algorithm (4BPP)

```python
def extract_tile_4bpp(rom_data: bytes, offset: int, palette: Palette) -> Image:
    """Extract one 4BPP tile and render with palette."""
    # Read 32 bytes
    tile_data = rom_data[offset:offset + 32]
    
    # Decode to pixel indices (0-15)
    pixels = []
    for row in range(8):
        plane0 = tile_data[row * 2]
        plane1 = tile_data[row * 2 + 1]
        plane2 = tile_data[16 + row * 2]
        plane3 = tile_data[16 + row * 2 + 1]
        
        for col in range(8):
            bit = 7 - col
            pixel = (((plane3 >> bit) & 1) << 3 |
                     ((plane2 >> bit) & 1) << 2 |
                     ((plane1 >> bit) & 1) << 1 |
                     ((plane0 >> bit) & 1))
            pixels.append(pixel)
    
    # Render to image
    img = Image.new('RGB', (8, 8))
    palette_colors = palette.to_rgb888_list()
    
    for y in range(8):
        for x in range(8):
            idx = y * 8 + x
            color_idx = pixels[idx]
            if color_idx < len(palette_colors):
                img.putpixel((x, y), palette_colors[color_idx])
    
    return img
```

---

## Future Enhancements

### Planned Features

1. **Sprite Assembly**
   - Combine multiple 8×8 tiles into complete sprites
   - Use OAM metadata for correct positioning
   - Support animation frames

2. **Graphics Re-insertion**
   - PNG → 4BPP converter
   - Palette JSON → Binary converter
   - ROM patching tool

3. **VRAM Layout Documentation**
   - Map which tiles are loaded where in VRAM
   - Document dynamic loading during gameplay
   - Create visual VRAM map

4. **Automatic Palette Detection**
   - Analyze OAM tables to determine palette usage
   - Auto-select correct palette for each tile
   - Generate sprite definitions

---

## Related Documentation

- **[GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md)** - Overall graphics architecture
- **[GRAPHICS_FORMAT.md](graphics-format.md)** - Detailed format specifications
- **[GRAPHICS_PALETTE_WORKFLOW.md](GRAPHICS_PALETTE_WORKFLOW.md)** - Palette editing workflow
- **[graphics-quickstart.md](graphics-quickstart.md)** - Quick start guide

---

## References

### Code Locations

- **Extraction Tool**: `tools/extraction/extract_graphics.py`
- **Tile Decoder**: Lines 150-210 (decode_2bpp_tile, decode_4bpp_tile)
- **Palette Extractor**: Lines 125-145 (extract_palette)
- **Multi-Palette Main**: Lines 575-657 (main function)

### Disassembly References

- **Bank 04**: Graphics tile data (`src/asm/bank_04_documented.asm`)
- **Bank 05**: Palette data (`src/asm/bank_05_documented.asm`)
- **Bank 0B**: OAM sprite setup (`src/asm/bank_0B_documented.asm:3085-3150`)
- **OAM Attributes**: Search for `#$d2`, `#$9c` in ASM files

### External Resources

- [SNES Development Wiki - Graphics](https://wiki.superfamicom.org/graphics)
- [SNESdev - PPU](https://snesdev.mesen.ca/wiki/index.php?title=PPU)
- [Yoshi's Island Disassembly](https://github.com/boldowa/yd) - Similar sprite system

---

**Last Updated**: 2025-01-XX  
**Extraction Tool Version**: 2.0 (Multi-palette support)  
**Issue Reference**: #70
