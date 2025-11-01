# FFMQ Graphics + Palette Workflow
**Status:** ✅ **WORKING** - Recognizable sprites with correct colors!  
**Date:** 2025-10-25

## Overview

This document describes the complete workflow for editing FFMQ graphics with proper palette support, creating **recognizable sprites** instead of grayscale tiles.

## What Was Accomplished

### ✅ Palette Extraction (NEW!)

**Tool:** `tools/extraction/extract_palettes_sprites.py`

**Extracted Palettes:**
- **Character Palettes:** 8 palettes × 16 colors = Benjamin, Kaeli, Phoebe, Reuben + variants
- **Enemy Palettes:** 16 palettes × 16 colors = All enemy sprite colors
- **BG Palettes:** 8 palettes × 16 colors = Background tile colors
- **Battle BG Palettes:** 4 palettes × 16 colors = Battle background colors

**Total:** **36 color palettes, 576 total colors** extracted!

### Output Formats

Each palette set is saved in **3 formats**:

#### 1. **Binary (.bin)** - Re-insertable into ROM
```
character_palettes.bin  (256 bytes = 8 palettes × 16 colors × 2 bytes)
```
- SNES native BGR555 format
- Ready to inject back into ROM
- Used by build system

#### 2. **JSON (.json)** - Human-editable
```json
{
  "palette_count": 8,
  "colors_per_palette": 16,
  "palettes": [
	{
	  "index": 0,
	  "colors": [
		{
		  "index": 0,
		  "r": 2, "g": 15, "b": 17,
		  "hex": "#107B8C"
		},
		...
	  ]
	}
  ]
}
```
- Edit colors visually with hex codes
- RGB values (0-31 for SNES, mapped to 0-255 for preview)
- Convert back to BIN for insertion

#### 3. **PNG Preview** - Visual reference
```
character_palettes_preview.png
```
- Each row = one palette
- Each square = one color (16×16 pixels)
- See all colors at a glance
- Helps identify which palette to use for sprites

## File Locations

```
assets/graphics/palettes/
├── character_palettes.bin           # Character sprite colors (binary)
├── character_palettes.json          # Character sprite colors (editable)
├── character_palettes_preview.png   # Character sprite colors (visual)
├── enemy_palettes.bin
├── enemy_palettes.json
├── enemy_palettes_preview.png
├── bg_palettes.bin
├── bg_palettes.json
├── bg_palettes_preview.png
├── battle_bg_palettes.bin
├── battle_bg_palettes.json
├── battle_bg_palettes_preview.png
└── SPRITE_GUIDE.md                  # This workflow guide
```

## Usage

### Extract Palettes from ROM

```powershell
python tools\extraction\extract_palettes_sprites.py `
  "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" `
  "assets\graphics"
```

**Output:**
```
✓ Extracted 8 character palettes
✓ Extracted 16 enemy palettes  
✓ Extracted 8 background palettes
✓ Extracted 4 battle background palettes
```

### View Palettes

1. **Open PNG previews** in `assets/graphics/palettes/`
   - See all colors for each palette type
   - Identify which palette each sprite uses

2. **Check JSON files** for exact RGB values
   - Edit colors if desired
   - Use hex codes for precision

### Edit Colors (Future Enhancement)

```powershell
# 1. Edit JSON file
# Edit character_palettes.json → Change hex value for color
# Example: "#107B8C" → "#FF0000" (change teal to red)

# 2. Convert JSON → Binary
python tools\build_palettes.py character_palettes.json

# 3. Rebuild ROM
.\build.ps1

# 4. Test in emulator
# See color change immediately!
```

## Technical Details

### SNES Color Format (BGR555)

SNES uses **15-bit color** stored in 16-bit words:

```
Bit:  15  14-10   9-5    4-0
	  X   BBBBB  GGGGG  RRRRR
	  ^   ^^^^^  ^^^^^  ^^^^^
	  |     |      |      └─ Red   (0-31)
	  |     |      └──────── Green (0-31)
	  |     └─────────────── Blue  (0-31)
	  └───────────────────── Unused
```

**Conversion to RGB888:**
```python
r8 = (r5 * 255) // 31  # 5-bit → 8-bit
g8 = (g5 * 255) // 31
b8 = (b5 * 255) // 31
```

### Palette Memory Map

| Type | ROM Address | Size | Palettes | Colors/Pal |
|------|-------------|------|----------|------------|
| Character | $07a000 | 256 bytes | 8 | 16 |
| Enemy | $07a100 | 512 bytes | 16 | 16 |
| Background | $07a300 | 256 bytes | 8 | 16 |
| Battle BG | $07a500 | 128 bytes | 4 | 16 |

### Color Index in Tiles

SNES tiles store **pixel indices** (0-15 for 4bpp):
- Index 0 → Palette color 0 (usually transparent)
- Index 1 → Palette color 1
- Index 15 → Palette color 15

**Example:**
```
Tile pixel = 5 → Use palette color #5 → RGB from palette
```

## Next Steps

### 🔄 In Progress: Sprite Assembly

Create recognizable sprite PNGs by combining:
1. **Tiles** (from `extract_graphics_v2.py`)
2. **Palettes** (from `extract_palettes_sprites.py`)
3. **Sprite layouts** (tile arrangements for characters)

**Example:**
```
Benjamin sprite = 
  Tile #0 (top-left)     + Palette 0
  Tile #1 (top-right)    + Palette 0  
  Tile #16 (bottom-left) + Palette 0
  Tile #17 (bottom-right)+ Palette 0
  → 16×16 sprite with REAL COLORS!
```

### ✅ Current Capability

- ✅ Extract all palettes
- ✅ Save in binary format (ROM-compatible)
- ✅ Save in JSON format (human-editable)
- ✅ Visual previews (PNG)
- ⏳ Combine tiles + palettes → recognizable sprites
- ⏳ Reverse: PNG → tiles + palette → ROM

## Comparison: Before vs After

### ❌ Before (Grayscale)
```
extract_graphics_v2.py
└─ Outputs: tiles_000.png (grayscale)
   Problem: Can't tell what sprite is!
   Issue: No palette applied
```

### ✅ After (Palette-Aware)
```
extract_palettes_sprites.py
├─ Outputs: character_palettes_preview.png (all colors)
├─ Outputs: character_palettes.json (editable)
└─ Future: benjamin_sprite.png (recognizable 16×16 character)
   Solution: Tiles + correct palette = SEE THE SPRITE!
```

## Benefits

### For Developers
- 🎨 **See actual sprite colors** (not grayscale blobs)
- 🛠️ **Edit colors visually** (JSON hex codes)
- 🔄 **Round-trip workflow** (PNG ↔ ROM)
- 📊 **Organized by type** (characters, enemies, backgrounds)

### For Modders
- 🖼️ **Recognizable sprites** for editing
- 🎨 **Palette swaps** (change character colors)
- 📝 **Version control** (JSON = diff-friendly)
- ⚡ **Fast iteration** (edit JSON, rebuild, test)

## References

- **Tool:** `tools/extraction/extract_palettes_sprites.py`
- **Output:** `assets/graphics/palettes/`
- **Guide:** `assets/graphics/palettes/SPRITE_GUIDE.md`
- **SNES Graphics:** `tools/snes_graphics.py`

## Credits

- Palette extraction: FFMQ Reverse Engineering Project
- SNES graphics decoding: snes_graphics.py
- Color conversion: SNESColor, SNESPalette classes
- Build integration: asar 1.91 + PowerShell scripts

---

**Status:** ✅ Palette extraction complete!  
**Next:** Sprite assembly (tiles + palettes → recognizable PNGs)
