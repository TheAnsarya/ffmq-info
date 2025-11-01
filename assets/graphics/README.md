# Final Fantasy Mystic Quest - Extracted Graphics

This directory contains graphics extracted from the FFMQ ROM.

## Tile Sets

### main_tiles
- **Description:** Main background tiles (34 banks)
- **PC Address:** $028C80
- **Size:** 222720 bytes
- **Format:** 4BPP
- **Files:**
  - `main_tiles_raw.bin` - Raw SNES tile data
  - `main_tiles.png` - PNG preview image

### extra_tiles
- **Description:** Extra background tiles
- **PC Address:** $020000
- **Size:** 6144 bytes
- **Format:** 4BPP
- **Files:**
  - `extra_tiles_raw.bin` - Raw SNES tile data
  - `extra_tiles.png` - PNG preview image

### sprite_tiles
- **Description:** Sprite graphics data
- **PC Address:** $03B013
- **Size:** 68585 bytes
- **Format:** 4BPP
- **Files:**
  - `sprite_tiles_raw.bin` - Raw SNES tile data
  - `sprite_tiles.png` - PNG preview image

## Palettes

### main_palettes
- **Description:** Main color palettes
- **PC Address:** $038000
- **Size:** 512 bytes
- **Files:**
  - `main_palettes_palette.bin` - Raw SNES palette data
  - `main_palettes_palette.txt` - Human-readable color list

## File Formats

### SNES Tile Format
- **2BPP:** 16 bytes per 8x8 tile (4 colors)
- **4BPP:** 32 bytes per 8x8 tile (16 colors)
- **8BPP:** 64 bytes per 8x8 tile (256 colors)

### SNES Palette Format
- **RGB555:** 2 bytes per color (15-bit color)
- **Format:** `0BBBBBGGGGGRRRRR` (5 bits per channel)
- **Organization:** 16 colors per sub-palette

## Editing Graphics

1. Edit the PNG files in your image editor
2. Use `convert_graphics.py` to convert back to SNES format:
   ```bash
   python convert_graphics.py to-snes <input.png> <output.bin> --bpp 4
   ```
3. Inject the modified data back into the ROM

## Tools

- `extract_graphics_v2.py` - This extraction script
- `convert_graphics.py` - Convert between SNES and PNG
- `snes_graphics.py` - Core SNES graphics format library

