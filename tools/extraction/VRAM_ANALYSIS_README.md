# VRAM Analysis Results

**Generated**: Using verified ROM addresses from datacrystal documentation  
**Purpose**: Extract ACTUAL sprite tiles (not guessed layouts)

## Extraction Results

### Character Sprites (Walking/Battle)

These are the full sprite sheets for each character containing ALL animation frames.

| Character | ROM Address | Size | Tiles | Output File |
|-----------|-------------|------|-------|-------------|
| Benjamin  | `$020000`   | 16KB | 512   | `benjamin_tiles.png` (128×256px) |
| Kaeli     | `$024000`   | 8KB  | 256   | `kaeli_tiles.png` (128×128px) |
| Tristam   | `$026000`   | 8KB  | 256   | `tristam_tiles.png` (128×128px) |
| Phoebe    | `$028000`   | 8KB  | 256   | `phoebe_tiles.png` (128×128px) |
| Reuben    | `$02a000`   | 8KB  | 256   | `reuben_tiles.png` (128×128px) |

### Character Portraits (Overworld)

Small 8×8 tile portraits used in the overworld map.

| Character | ROM Address | Size | Tiles | Output File |
|-----------|-------------|------|-------|-------------|
| Benjamin  | `$02e000`   | 1KB  | 32    | `benjamin_portrait_tiles.png` (128×16px) |
| Kaeli     | `$02e400`   | 1KB  | 32    | `kaeli_portrait_tiles.png` (128×16px) |
| Tristam   | `$02e800`   | 1KB  | 32    | `tristam_portrait_tiles.png` (128×16px) |
| Phoebe    | `$02ec00`   | 1KB  | 32    | `phoebe_portrait_tiles.png` (128×16px) |
| Reuben    | `$02f000`   | 1KB  | 32    | `reuben_portrait_tiles.png` (128×16px) |

## Analysis Grid

**File**: `character_comparison_grid.png`  
**Layout**: 5 characters × 16 tiles each (first 16 tiles of each character side-by-side)

This comparison shows the first 16 tiles of each character's sprite sheet aligned for easy comparison.

## Next Steps: MANUAL VERIFICATION REQUIRED

### Step 1: Visual Inspection

Open each `*_tiles.png` file and:

1. **Identify sprite patterns**:
   - Look for recognizable body parts (head, torso, legs)
   - Find walking animation frames (4 directions × 2-3 frames)
   - Locate battle poses (standing, attacking, magic casting)

2. **Note tile arrangements**:
   - Characters are typically 2×2 tiles (16×16 pixels) or larger
   - Tiles may NOT be sequential (e.g., head at tile 5, body at tile 22)
   - Animation frames reuse tiles with slight variations

3. **Record tile indices**:
   - Example: "Benjamin standing front = tiles [12, 13, 28, 29]"
   - This is what we need to update `assemble_sprites.py` with

### Step 2: Compare with Game Screenshots

To verify extracted tiles match the actual game:

1. **Run FFMQ in emulator** (Mesen-S, Snes9x, etc.)
2. **Open VRAM viewer** during gameplay
3. **Take screenshots** of:
   - Characters walking (all 4 directions)
   - Battle screen (standing pose)
   - Character portraits on overworld
4. **Compare** extracted tiles with VRAM viewer display
5. **Verify** colors and arrangements match

### Step 3: Document Actual Sprite Layouts

Create a mapping file like:

```json
{
  "benjamin": {
    "standing_front": {
      "tiles": [12, 13, 28, 29],
      "width": 2,
      "height": 2,
      "palette": 0
    },
    "walking_front_frame1": {
      "tiles": [14, 15, 30, 31],
      "width": 2,
      "height": 2,
      "palette": 0
    }
  }
}
```

### Step 4: Update assemble_sprites.py

Replace current GUESSED definitions with ACTUAL data:

```python
# OLD (WRONG):
CHARACTER_SPRITES = [
    SpriteLayout(
        name="benjamin",
        tile_offset=0x028000,  # WRONG ADDRESS
        tiles=[0, 1, 16, 17],  # GUESSED
        palette_index=1,
    )
]

# NEW (CORRECT):
CHARACTER_SPRITES = [
    SpriteLayout(
        name="benjamin_standing_front",
        tile_offset=0x020000,  # CORRECT from datacrystal
        tiles=[12, 13, 28, 29],  # ACTUAL from visual inspection
        palette_index=0,  # CORRECT palette
        width_tiles=2,
        height_tiles=2,
    )
]
```

## Important Notes

### Why Previous Sprites Were Wrong

1. **Wrong ROM addresses**: Used `$028000` for all characters
   - Benjamin is actually at `$020000`
   - Phoebe is at `$028000` (what we thought was Benjamin!)

2. **Guessed tile arrangements**: Used `[0, 1, 16, 17]` for all
   - Real sprites use non-sequential tiles
   - Different poses use different tile combinations
   - Animation reuses tiles in different arrangements

3. **Missing animations**: Only extracted 1 pose per character
   - Benjamin has 512 tiles = 30+ animation frames
   - Each direction × multiple frames × multiple poses

### Sprite Sheet Organization

From ROM analysis, sprite sheets appear to be organized as:

```
Tiles 0-127:   Walking animations (4 directions × 8 frames each?)
Tiles 128-255: Battle animations (attacking, magic, victory, damaged)
Tiles 256-383: Additional poses/effects
Tiles 384-511: (Benjamin only - more animations)
```

**This is speculative** - must verify by visual inspection!

### Palette Selection

Sprites use palette indices 0-4 (not palette 1 for all):
- Benjamin: Palette 0
- Kaeli: Palette 1
- Tristam: Palette 2
- Phoebe: Palette 3
- Reuben: Palette 4

These correspond to sprite palettes 8-12 in CGRAM (add 8 to index).

## Files Generated

```
data/extracted/graphics/vram_analysis/
├── benjamin_tiles.png            # All Benjamin sprite tiles
├── kaeli_tiles.png               # All Kaeli sprite tiles
├── tristam_tiles.png             # All Tristam sprite tiles
├── phoebe_tiles.png              # All Phoebe sprite tiles
├── reuben_tiles.png              # All Reuben sprite tiles
├── benjamin_portrait_tiles.png   # Benjamin overworld portrait
├── kaeli_portrait_tiles.png      # Kaeli overworld portrait
├── tristam_portrait_tiles.png    # Tristam overworld portrait
├── phoebe_portrait_tiles.png     # Phoebe overworld portrait
├── reuben_portrait_tiles.png     # Reuben overworld portrait
└── character_comparison_grid.png # Side-by-side comparison
```

## References

- **datacrystal/ROM_map/Graphics.wikitext**: Character sprite ROM addresses
- **datacrystal/ROM_map/Characters.wikitext**: Character portrait addresses
- **SNES Graphics Format**: 4BPP tiles (32 bytes per 8×8 tile)
- **Palette Format**: RGB555 (16 colors per palette)

---

**Status**: ✅ Tiles extracted with CORRECT ROM addresses  
**Next**: 🔍 Manual verification against game screenshots required  
**Goal**: Update `assemble_sprites.py` with ACTUAL sprite definitions
