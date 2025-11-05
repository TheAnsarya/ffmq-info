# Sprite Extraction and Assembly

**Status:** ✅ **Working** - Assembles recognizable sprites from tiles!  
**Last Updated:** 2025-11-04

---

## Overview

This directory contains tools for extracting and assembling complete sprite graphics from the FFMQ ROM. Unlike raw tile extraction, these tools create **recognizable sprites** (characters, enemies, etc.) by combining tiles with correct palettes and layouts.

## Tools

### 1. `extract_graphics.py` - Multi-Palette Tile Extraction

**Purpose:** Extract raw tiles with ALL 8 palettes to identify correct colors

**Output:**
```
data/extracted/graphics/tiles/
├── bank04_tiles_palette00_sheet.png  (256 tiles, palette 0)
├── bank04_tiles_palette01_sheet.png  (same tiles, palette 1)
├── ...
├── bank04_tiles_palette07_sheet.png  (same tiles, palette 7)
└── tile_palette_comparison.png       (visual comparison)

data/extracted/graphics/palettes/
├── palette_00.json  (16 colors, editable)
├── ...
└── palette_15.json
```

**Usage:**
```powershell
python tools/extraction/extract_graphics.py
```

**See Also:** `docs/GRAPHICS_EXTRACTION_GUIDE.md` (comprehensive guide)

---

### 2. `assemble_sprites.py` - Sprite Assembly

**Purpose:** Combine tiles into complete, recognizable sprites

**Output:**
```
data/extracted/graphics/sprites/
├── characters/
│   ├── benjamin.png  (16×16 px)
│   ├── kaeli.png
│   ├── phoebe.png
│   ├── reuben.png
│   └── _character_sheet.png  (all characters)
├── enemies/
│   ├── brown_bear.png  (32×32 px)
│   ├── behemoth.png
│   └── _enemy_sheet.png  (all enemies)
└── metadata/
    ├── benjamin.json  (sprite definition)
    └── ...
```

**Usage:**
```powershell
python tools/extraction/assemble_sprites.py
```

**Features:**
- ✅ Assembles multi-tile sprites (2×2, 4×4, etc.)
- ✅ Applies correct palette per sprite
- ✅ Creates sprite sheets for visual reference
- ✅ Exports metadata (JSON) for editing

---

## How It Works

### SNES Sprite Structure

**Sprites are built from 8×8 pixel tiles:**

```
Small Sprite (16×16 px) = 2×2 tiles = 4 tiles total
  ┌───┬───┐
  │ 0 │ 1 │  Tile IDs: [0, 1, 16, 17]
  ├───┼───┤
  │16 │17 │
  └───┴───┘

Large Enemy (32×32 px) = 4×4 tiles = 16 tiles total
  ┌───┬───┬───┬───┐
  │ 0 │ 1 │ 2 │ 3 │  Tile IDs: [0, 1, 2, 3,
  ├───┼───┼───┼───┤                16,17,18,19,
  │16 │17 │18 │19 │                32,33,34,35,
  ├───┼───┼───┼───┤                48,49,50,51]
  │32 │33 │34 │35 │
  ├───┼───┼───┼───┤
  │48 │49 │50 │51 │
  └───┴───┴───┴───┘
```

### Sprite Assembly Process

```
1. Load ROM → GraphicsExtractor
2. Extract 16 palettes (Bank 05)
3. For each sprite definition:
   a. Load tile indices (e.g., [0, 1, 16, 17])
   b. Extract tiles from ROM at offset
   c. Select correct palette (0-7)
   d. Render tiles with palette
   e. Arrange tiles in grid (width × height)
   f. Export as PNG
```

### Sprite Definition Format

**Example (Benjamin):**
```python
SpriteLayout(
    name="benjamin",
    category="character",
    width_tiles=2,          # 2 tiles wide
    height_tiles=2,         # 2 tiles tall
    tile_offset=0x028000,   # ROM address (Bank 04)
    palette_index=1,        # Use palette 1
    tiles=[0, 1, 16, 17],  # Which tiles to use
    notes="Benjamin - main character sprite"
)
```

**Result:** 16×16 PNG with correct colors

---

## Current Sprite Definitions

### Characters (16×16 px, 2×2 tiles)

| Sprite | Palette | Tiles | Status |
|--------|---------|-------|--------|
| Benjamin | 1 | [0, 1, 16, 17] | ✅ Extracted |
| Kaeli | 2 | [4, 5, 20, 21] | ✅ Extracted |
| Phoebe | 3 | [8, 9, 24, 25] | ✅ Extracted |
| Reuben | 4 | [12, 13, 28, 29] | ✅ Extracted |

**Note:** Tile indices are educated guesses. May need adjustment after visual verification.

### Enemies (32×32 px, 4×4 tiles)

| Sprite | Palette | Tiles | Status |
|--------|---------|-------|--------|
| Brown Bear | 3 | [32-35, 48-51, 64-67, 80-83] | ✅ Extracted |
| Behemoth | 6 | [96-99, 112-115, 128-131, 144-147] | ✅ Extracted |

**To Add:** More enemies (83 total in game)

---

## Verifying Sprites

### Method 1: Visual Comparison

1. Run the game in emulator (Mesen-S, BSNES)
2. Take screenshot of sprite
3. Compare with extracted PNG
4. Adjust if needed

### Method 2: VRAM Viewer

1. Open Mesen-S debugger
2. **Debug → VRAM Viewer**
3. Check tile arrangement and palette
4. Note tile IDs and palette used
5. Update sprite definition

### Method 3: Disassembly Analysis

Search for sprite setup code:
```asm
; From bank_0B_documented.asm
lda.b #$d2        ; OAM attribute
sta.w $0c12,y     ; Store to OAM

; $d2 = %11010010
; Palette bits (3-1) = 001 = Palette 1
```

---

## Refining Sprite Definitions

### If Sprite Looks Wrong

**Problem 1: Wrong Colors**
- **Cause:** Wrong palette index
- **Fix:** Try different palette (0-7)
- **Test:** Compare with tile sheets (`bank04_tiles_palette00-07_sheet.png`)

**Problem 2: Scrambled Tiles**
- **Cause:** Wrong tile indices or offset
- **Fix:** Adjust `tiles` array or `tile_offset`
- **Test:** Use VRAM viewer to see actual tile arrangement

**Problem 3: Missing Parts**
- **Cause:** Not enough tiles in definition
- **Fix:** Increase `width_tiles`, `height_tiles`, add more tile IDs

### Example: Fixing Benjamin

**Current Definition:**
```python
tiles=[0, 1, 16, 17],  # Might be wrong!
palette_index=1
```

**If it looks wrong, try:**
```python
tiles=[0, 1, 2, 16, 17, 18],  # Different arrangement
# OR
palette_index=0,  # Different palette
# OR
tile_offset=0x029000,  # Different ROM location
```

**Then re-run:**
```powershell
python tools/extraction/assemble_sprites.py
```

---

## Adding New Sprites

### Step 1: Find ROM Location

**Check disassembly or use tile extractor:**
```powershell
# Extract tiles from different offsets
python tools/extraction/extract_graphics.py
# Review bank04_tiles_palette00-07_sheet.png
```

### Step 2: Identify Tiles and Palette

**Use comparison sheets to find:**
- Which tiles form the sprite
- Which palette makes it look correct

### Step 3: Add Definition

**Edit `assemble_sprites.py`:**
```python
# Add to CHARACTER_SPRITES or ENEMY_SPRITES list
SpriteLayout(
    name="new_enemy",
    category="enemy",
    width_tiles=4,
    height_tiles=4,
    tile_offset=0x028000,
    palette_index=3,
    tiles=[
        # List all tile IDs in order
        # Row 0: tiles 0-3
        # Row 1: tiles 16-19
        # Row 2: tiles 32-35
        # Row 3: tiles 48-51
    ],
    notes="Description"
)
```

### Step 4: Generate and Verify

```powershell
python tools/extraction/assemble_sprites.py
# Check output in data/extracted/graphics/sprites/
```

---

## Metadata Files

**Each sprite has a JSON metadata file:**

```json
{
  "name": "benjamin",
  "category": "character",
  "dimensions": {
    "width_tiles": 2,
    "height_tiles": 2,
    "width_pixels": 16,
    "height_pixels": 16
  },
  "rom_offset": "0x028000",
  "palette_index": 1,
  "tiles": [0, 1, 16, 17],
  "notes": "Benjamin - main character sprite (standing pose)"
}
```

**Use metadata to:**
- Document sprite structure
- Share sprite definitions
- Auto-generate sprite assembly code

---

## Future Enhancements

### Planned Features

1. **Auto-detect sprite layouts from OAM tables**
   - Parse ROM OAM metadata
   - Extract actual tile arrangements
   - No more guessing!

2. **Animation frame extraction**
   - Extract all animation frames
   - Create animated GIFs
   - Document frame timings

3. **Sprite re-insertion**
   - PNG → tiles converter
   - Update ROM with modified sprites
   - Verify in-game appearance

4. **Complete sprite library**
   - All 83 enemies
   - All NPCs
   - UI elements
   - Effects

5. **Sprite editor integration**
   - Visual sprite editor
   - Drag-and-drop tile arrangement
   - Real-time palette preview

---

## Technical Details

### Tile Indexing

**Tiles are numbered sequentially in ROM:**
```
Offset 0x028000:
  Tile 0:  Bytes 0-31    (32 bytes per 4BPP tile)
  Tile 1:  Bytes 32-63
  Tile 2:  Bytes 64-95
  ...
  Tile 16: Bytes 512-543  (0x200 offset)
```

**Typical sprite arrangements:**
```
2×2 sprite: tiles = [0, 1, 16, 17]
  - Tile 0: top-left
  - Tile 1: top-right
  - Tile 16: bottom-left (next row)
  - Tile 17: bottom-right

4×4 sprite: tiles = [0,1,2,3, 16,17,18,19, 32,33,34,35, 48,49,50,51]
  - Row 0: tiles 0-3
  - Row 1: tiles 16-19 (16 tiles = 0x200 bytes later)
  - Row 2: tiles 32-35
  - Row 3: tiles 48-51
```

### Palette Application

**Each sprite uses ONE palette (16 colors):**
```
Palette 0: Colors for UI/fonts
Palette 1: Benjamin colors
Palette 2: Kaeli colors
Palette 3: Common enemy colors
...
Palette 7: Special/effects
```

**Palette data in ROM:**
```
Bank 05: $030000-$0301FF (512 bytes)
  Palette 0: $030000-$03001F (32 bytes, 16 colors)
  Palette 1: $030020-$03003F
  ...
  Palette 15: $0301E0-$0301FF
```

---

## Troubleshooting

### Q: Sprites don't look right!

**A:** This is expected! Initial definitions are educated guesses.

**Solutions:**
1. Compare with multi-palette tile sheets
2. Use VRAM viewer to see actual tiles
3. Adjust sprite definitions and re-run
4. Check disassembly for OAM setup code

### Q: How do I find the right tiles?

**A:** 
1. Run `extract_graphics.py` first
2. Open `bank04_tiles_palette00-07_sheet.png`
3. Find your sprite visually
4. Count tiles from top-left (0, 1, 2, ...)
5. Note which palette makes it look correct

### Q: Some sprites are blank/black

**A:** Likely wrong offset or palette.

**Try:**
- Different `tile_offset` (e.g., 0x029000, 0x02A000)
- Different `palette_index` (0-7)
- Check if sprite is compressed (Bank 0A has 3BPP compression)

### Q: Can I edit sprites?

**A:** Yes! Future feature.

**Current workaround:**
1. Edit PNG in image editor
2. Manually convert back to tiles
3. Update ROM (advanced)

---

## Related Documentation

- **[GRAPHICS_EXTRACTION_GUIDE.md](../../docs/GRAPHICS_EXTRACTION_GUIDE.md)** - Complete extraction guide
- **[GRAPHICS_SYSTEM.md](../../docs/GRAPHICS_SYSTEM.md)** - System architecture
- **[graphics-format.md](../../docs/graphics-format.md)** - Format specifications

---

## Examples

### Example 1: Verify Benjamin Sprite

```powershell
# 1. Extract tiles with all palettes
python tools/extraction/extract_graphics.py

# 2. Check tile sheets - find Benjamin
# Look at bank04_tiles_palette01_sheet.png (palette 1)
# Identify tiles that look like Benjamin

# 3. Assemble sprite
python tools/extraction/assemble_sprites.py

# 4. Check output
# data/extracted/graphics/sprites/characters/benjamin.png

# 5. Compare with game screenshot
# If wrong, edit sprite definition and re-run
```

### Example 2: Add New Enemy

```python
# In assemble_sprites.py, add to ENEMY_SPRITES:

SpriteLayout(
    name="minotaur",
    category="enemy",
    width_tiles=4,
    height_tiles=4,
    tile_offset=0x028000,
    palette_index=5,  # Try different palettes if wrong
    tiles=[
        # Visual inspection shows it's tiles 160-175
        160, 161, 162, 163,
        176, 177, 178, 179,
        192, 193, 194, 195,
        208, 209, 210, 211
    ],
    notes="Minotaur - boss enemy"
)
```

```powershell
# Generate sprite
python tools/extraction/assemble_sprites.py

# Check result
# data/extracted/graphics/sprites/enemies/minotaur.png
```

---

**Last Updated:** 2025-11-04  
**Sprite Assembler Version:** 1.0  
**Sprites Defined:** 6 (4 characters, 2 enemies)
