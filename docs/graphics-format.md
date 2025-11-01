# SNES Graphics Format Reference

Comprehensive guide to SNES graphics formats used in Final Fantasy Mystic Quest

## Table of Contents

1. [Overview](#overview)
2. [Tile Formats](#tile-formats)
3. [Palette Format](#palette-format)
4. [Tilemap Format](#tilemap-format)
5. [OAM (Sprite) Format](#oam-sprite-format)
6. [Tools Usage](#tools-usage)
7. [Workflow Examples](#workflow-examples)

---

## Overview

The Super Nintendo Entertainment System (SNES) uses tile-based graphics with separate palette data. Understanding these formats is essential for modifying game graphics.

### Key Concepts

- **Tile:** 8x8 pixel graphics building block
- **Palette:** Collection of colors (SNES uses 15-bit RGB)
- **Tilemap:** Array of tile indices and attributes
- **Sprite:** Object composed of one or more tiles
- **BPP:** Bits Per Pixel (determines color depth)

---

## Tile Formats

SNES tiles are always 8x8 pixels, stored in planar format.

### 2BPP (2 Bits Per Pixel)

**Size:** 16 bytes per tile  
**Colors:** 4 colors (2 bits)  
**Usage:** Fonts, simple UI elements

**Structure:**
```
Bytes 0-1:   Row 0 (Plane 0, Plane 1)
Bytes 2-3:   Row 1 (Plane 0, Plane 1)
Bytes 4-5:   Row 2 (Plane 0, Plane 1)
Bytes 6-7:   Row 3 (Plane 0, Plane 1)
Bytes 8-9:   Row 4 (Plane 0, Plane 1)
Bytes 10-11: Row 5 (Plane 0, Plane 1)
Bytes 12-13: Row 6 (Plane 0, Plane 1)
Bytes 14-15: Row 7 (Plane 0, Plane 1)
```

**Example:**
```
For pixel at position (x=3, y=2):
- Read byte 4 (Row 2, Plane 0)
- Read byte 5 (Row 2, Plane 1)
- Extract bit 4 (7-x) from each byte
- Combine: bit1 << 1 | bit0
- Result: palette index 0-3
```

### 4BPP (4 Bits Per Pixel)

**Size:** 32 bytes per tile  
**Colors:** 16 colors (4 bits)  
**Usage:** Most FFMQ graphics (backgrounds, sprites)

**Structure:**
```
Bytes 0-1:   Row 0 Planes 0-1
Bytes 2-3:   Row 1 Planes 0-1
...
Bytes 14-15: Row 7 Planes 0-1
Bytes 16-17: Row 0 Planes 2-3
Bytes 18-19: Row 1 Planes 2-3
...
Bytes 30-31: Row 7 Planes 2-3
```

**Decoding Algorithm:**
```python
for y in range(8):
	plane0 = data[y * 2]
	plane1 = data[y * 2 + 1]
	plane2 = data[16 + y * 2]
	plane3 = data[16 + y * 2 + 1]
	
	for x in range(8):
		bit_mask = 1 << (7 - x)
		pixel = 0
		if plane0 & bit_mask: pixel |= 1
		if plane1 & bit_mask: pixel |= 2
		if plane2 & bit_mask: pixel |= 4
		if plane3 & bit_mask: pixel |= 8
		# pixel is now palette index 0-15
```

### 8BPP (8 Bits Per Pixel)

**Size:** 64 bytes per tile  
**Colors:** 256 colors (8 bits)  
**Usage:** Mode 7 graphics, high-color images

**Structure:**
```
Bytes 0-1:   Row 0 Planes 0-1
...
Bytes 14-15: Row 7 Planes 0-1
Bytes 16-17: Row 0 Planes 2-3
...
Bytes 30-31: Row 7 Planes 2-3
Bytes 32-33: Row 0 Planes 4-5
...
Bytes 46-47: Row 7 Planes 4-5
Bytes 48-49: Row 0 Planes 6-7
...
Bytes 62-63: Row 7 Planes 6-7
```

---

## Palette Format

SNES uses RGB555 format: 15-bit color (5 bits per channel).

### RGB555 Structure

**Size:** 2 bytes (16 bits) per color  
**Format:** `0BBBBBGGGGGRRRRR` (bit 15 unused)

```
Bit:  15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
      0  B  B  B  B  B  G  G  G  G  G  R  R  R  R  R
```

### Conversion to RGB888

```python
# Read 16-bit word (little-endian)
color_word = (byte1 << 8) | byte0

# Extract 5-bit components
r5 = color_word & 0x1F
g5 = (color_word >> 5) & 0x1F
b5 = (color_word >> 10) & 0x1F

# Convert to 8-bit (0-255)
r8 = (r5 << 3) | (r5 >> 2)  # Scale and fill low bits
g8 = (g5 << 3) | (g5 >> 2)
b8 = (b5 << 3) | (b5 >> 2)
```

### Palette Organization

Palettes are organized into sub-palettes:
- **Full Palette:** 256 colors (512 bytes)
- **Sub-Palette:** 16 colors (32 bytes)
- **Sprites:** Use palettes 8-15 (128-255)
- **Backgrounds:** Use palettes 0-7 (0-127)

**Color 0 is always transparent** in each sub-palette.

---

## Tilemap Format

Tilemaps define how tiles are arranged on screen.

### Tilemap Entry

**Size:** 2 bytes per entry  
**Format:** `vhopppcccccccccc`

```
Bit:  15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
      v  h  o  p  p  p  c  c  c  c  c  c  c  c  c  c
```

**Fields:**
- `v`: Vertical flip (1 = flip)
- `h`: Horizontal flip (1 = flip)
- `o`: Priority (0 = normal, 1 = high)
- `ppp`: Palette number (0-7 for BG, 0-7 for sprites)
- `cccccccccc`: Tile number (0-1023)

### Example

```
Entry: $34A5 = 0011 0100 1010 0101
v=0, h=0, o=1, ppp=100 (4), tile=$0A5 (165)
Result: Tile 165, Palette 4, High priority
```

---

## OAM (Sprite) Format

Object Attribute Memory stores sprite data.

### OAM Entry (4 bytes)

```
Byte 0: X position (low 8 bits)
Byte 1: Y position
Byte 2: Tile number
Byte 3: vhoo Nppp
	v = vertical flip
	h = horizontal flip
	oo = priority
	N = tile page (high bit of tile number)
	ppp = palette (0-7, uses palettes 8-15)
```

### High Table (1 byte per 4 sprites)

Stores X position high bit and size for 4 sprites:
```
Bits: ssssssss
	s0 = sprite 0 size
	s1 = sprite 1 size
	...
```

---

## Tools Usage

### Extract Graphics from ROM

```bash
# Extract all graphics to PNG
python tools/extract_graphics_v2.py "rom.sfc" assets/graphics

# Extract raw data only (no PNG)
python tools/extract_graphics_v2.py "rom.sfc" assets/graphics --no-png

# Generate documentation
python tools/extract_graphics_v2.py "rom.sfc" assets/graphics --docs
```

### Convert SNES to PNG

```bash
# Convert 4BPP tiles to PNG
python tools/convert_graphics.py to-png tiles.bin output.png \
	--palette palette.bin --bpp 4 --tiles-per-row 16

# Convert without palette (grayscale)
python tools/convert_graphics.py to-png tiles.bin output.png --bpp 4

# Convert to indexed PNG (preserves exact palette indices)
python tools/convert_graphics.py to-png tiles.bin output.png \
	--palette palette.bin --bpp 4 --indexed
```

### Convert PNG to SNES

```bash
# Convert PNG to 4BPP tiles
python tools/convert_graphics.py to-snes input.png tiles.bin --bpp 4

# Also export palette
python tools/convert_graphics.py to-snes input.png tiles.bin \
	--bpp 4 --palette palette.bin
```

---

## Workflow Examples

### Editing Character Sprites

1. **Extract sprites:**
   ```bash
   python tools/extract_graphics_v2.py "ffmq.sfc" assets/graphics
   ```

2. **Edit PNG:**
   - Open `sprite_tiles.png` in your image editor
   - Edit the sprites (maintain 8x8 tile boundaries)
   - Save as indexed PNG if possible

3. **Convert back to SNES:**
   ```bash
   python tools/convert_graphics.py to-snes \
       assets/graphics/sprite_tiles_edited.png \
       assets/graphics/sprite_tiles_new.bin \
       --bpp 4
   ```

4. **Test in emulator:**
   ```bash
   # Inject into test ROM and run
   make test
   ```

### Creating Custom Tiles

1. **Create PNG:**
   - Create 8x8 tiles in image editor
   - Arrange in grid (16 tiles per row recommended)
   - Use indexed color mode with 16 colors max (4BPP)
   - Set color 0 to transparent color

2. **Convert to SNES:**
   ```bash
   python tools/convert_graphics.py to-snes \
       mytiles.png custom_tiles.bin \
       --bpp 4 --palette custom_palette.bin
   ```

3. **Reference in assembly:**
   ```asm
   .include "custom_tiles.bin"
   ```

### Palette Editing

1. **Extract palette:**
   ```bash
   python tools/extract_graphics_v2.py "ffmq.sfc" assets/graphics
   # Creates main_palettes_palette.txt and .bin
   ```

2. **Edit colors:**
   - Open `main_palettes_palette.txt`
   - Note SNES color values
   - Edit palette in image editor or hex editor
   - Save modified .bin file

3. **Apply to ROM:**
   - Use hex editor or custom injection tool
   - Replace palette data at correct address

---

## FFMQ-Specific Graphics Locations

### Tile Data

| Name | ROM Address | Size | Format | Description |
|------|-------------|------|--------|-------------|
| Main Tiles | $05:8C80 | ~219KB | 4BPP | Background tiles (34 banks) |
| Extra Tiles | $04:8000 | 6KB | 4BPP | Additional background tiles |
| Sprite Tiles | $07:B013 | ~67KB | 4BPP | Character/enemy sprites |

### Palette Data

| Name | ROM Address | Size | Description |
|------|-------------|------|-------------|
| Main Palettes | $07:8000 | 512 bytes | Primary color palettes |

*Note: Addresses are SNES addresses. Add $200 for PC offset if ROM has header.*

---

## Technical Details

### VRAM Layout

SNES VRAM (Video RAM) is 64KB organized as:
- **Character data:** Tile graphics
- **Screen data:** Tilemaps
- **BG1-BG4:** Four background layers
- **OBJ:** Sprite layer

### DMA Transfer

Graphics are typically loaded via DMA (Direct Memory Access):
```asm
lda #$01        ; DMA mode: 2 bytes write once
sta $4300       ; DMA control
lda #$18        ; Destination: VRAM write ($2118)
sta $4301
ldx #source_addr
stx $4302       ; Source address
lda #source_bank
sta $4304       ; Source bank
ldx #$1000      ; Transfer 4096 bytes
stx $4305
lda #$01
sta $420B       ; Start DMA channel 0
```

### Color Math

SNES supports color math operations:
- **Addition:** Brighten colors
- **Subtraction:** Darken colors
- **Half-color:** 50% transparency
- **Per-pixel effects:** Different math per pixel

---

## References

- **SNES Dev Manual:** Official Nintendo development documentation
- **Fullsnes:** Comprehensive SNES hardware documentation
- **SNESdev Wiki:** Community SNES development resources
- **Romhacking.net:** ROM hacking tutorials and tools

---

## Tools Reference

### Python Modules

- **snes_graphics.py:** Core SNES format library
  - `SNESTile`: Tile data structure and encoding/decoding
  - `SNESPalette`: Palette handling and color conversion
  - `SNESColor`: Individual color representation

- **convert_graphics.py:** PNG conversion utilities
  - `TileImageConverter`: Bidirectional tile/PNG conversion
  - Command-line interface for batch conversion

- **extract_graphics_v2.py:** ROM extraction tool
  - `FFMQGraphicsExtractorV2`: FFMQ-specific extractor
  - Automatic palette detection
  - PNG output support

### External Tools

- **YY-CHR:** Windows graphics editor for SNES/NES tiles
- **Tile Molester:** Java-based tile viewer/editor
- **GIMP:** Free image editor with indexed color support
- **Aseprite:** Pixel art editor excellent for SNES graphics

---

## Tips and Tricks

### Indexed Color in GIMP

1. Image → Mode → Indexed
2. Maximum colors: 16 (for 4BPP)
3. Ensure color 0 is transparent
4. Use palette tools to organize colors

### Tile Boundaries

Always work in 8x8 pixel increments:
- Grid size: 8×8 pixels
- Enable pixel grid in editor
- Snap to grid when drawing

### Palette Optimization

- Group similar colors together
- Reserve color 0 for transparency
- Use sub-palettes efficiently (16 colors each)
- Test on actual SNES/emulator (colors may differ from PC)

### Testing Changes

1. Extract original graphics
2. Make small changes
3. Test immediately in emulator
4. Iterate quickly
5. Keep backups of working versions

---

*Last updated: 2025-01-24*
