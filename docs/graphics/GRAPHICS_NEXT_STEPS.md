# Graphics Extraction - Next Steps Guide

## Current Status ✓

### Completed
- ✅ Banks 04/05/06 fully documented (6,786 lines)
- ✅ Graphics extraction tool (454 lines)
- ✅ Sprite assembly tool (464 lines)
- ✅ Tile analysis tool (246 lines)
- ✅ Visual catalog generator (345 lines)
- ✅ 4 character sprites extracted (16 animation frames)
- ✅ 2 UI elements extracted (font + borders)
- ✅ 1 sample enemy extracted (Brownie)
- ✅ 16 palettes extracted and documented
- ✅ Visual catalog generated (HTML + PNG)

### Total Infrastructure: 8,295 lines of code

## Next Phase: Enemy Sprite Extraction

### Challenge
We have 83 enemy definitions in `data/extracted/enemies/enemies.json` but need to:
1. Find where each enemy's sprite is in ROM
2. Determine sprite dimensions for each
3. Identify animation frames
4. Map correct palette for each

### Approach Options

#### Option A: Manual ROM Inspection (Slow but Accurate)
1. Use tile viewer (YY-CHR or similar)
2. Load Bank 04 at offset 0x028000
3. Manually identify each of 83 enemy sprites
4. Document offsets, sizes, palettes
5. Create sprite definitions for extract_sprites.py

**Pros**: 100% accurate, visual confirmation
**Cons**: Very time-consuming (8-12 hours)

#### Option B: Pattern-Based Extraction (Fast but May Need Adjustment)
1. Analyze tile cluster patterns from analyze_tiles.py
2. Estimate sprite locations based on:
   - Game progression order
   - Size patterns (early enemies smaller)
   - Density clusters
3. Extract with best guesses
4. Visually verify and adjust

**Pros**: Quick initial pass, iterative refinement
**Cons**: May require multiple iterations

#### Option C: Disassembly Analysis (Most Accurate)
1. Find sprite lookup tables in disassembly
2. Trace enemy battle rendering code
3. Identify sprite pointer table
4. Extract offsets/dimensions from code
5. Automate extraction using discovered table

**Pros**: Authoritative source, fully automated
**Cons**: Requires deep disassembly work (4-6 hours)

### Recommended: Hybrid Approach

**Phase 1** - Quick wins (1-2 hours):
1. Extract first 10-20 enemies using progression order
2. Assume similar sizes for similar enemy types
3. Visual verification in catalog

**Phase 2** - Disassembly research (2-3 hours):
1. Search for sprite loading code in banks/
2. Identify enemy sprite table structure
3. Extract table data programmatically

**Phase 3** - Complete extraction (1-2 hours):
1. Use discovered table to extract all 83
2. Generate complete visual catalog
3. Verify against in-game screenshots

## Sprite Dimension Estimates

Based on typical SNES RPG patterns:

### Small Enemies (16×16 or 24×24)
Likely first ~20 enemies (Brownie, Mintmint, etc.)
- Tiles: 4-9 per sprite
- Palette: Shared palettes (4-7)

### Medium Enemies (32×32 or 32×48)
Mid-game enemies (~30 enemies)
- Tiles: 16-24 per sprite
- Palette: Shared or dedicated

### Large Enemies (48×48 or 64×64)
Late game / bosses (~10 enemies)
- Tiles: 36-64 per sprite
- Palette: Often dedicated

### Boss Enemies (64×64 or larger)
Major bosses (~5 enemies)
- Tiles: 64-256 per sprite
- Palette: Dedicated palettes

## Code Locations to Search

### Disassembly Files to Check
```
src/asm/banks/bank_09.asm - Battle system
src/asm/banks/bank_0A.asm - Enemy AI
src/asm/banks/bank_0D.asm - Graphics rendering?
```

### Look for:
- Sprite pointer tables (16-bit addresses)
- Dimension tables (width/height in tiles)
- Palette assignment tables
- Animation frame tables

### Pattern to find:
```asm
; Enemy sprite data table
enemy_sprites:
  .dw $8000  ; Enemy 0 tile offset
  .db $04    ; Width in tiles
  .db $04    ; Height in tiles
  .db $00    ; Palette index
  ; ... repeat for all 83 enemies
```

## Quick Start: Extract Next 10 Enemies

### Estimated Offsets (Based on Brownie at 0x02B000)

Assuming ~512 bytes per enemy sprite (16 tiles × 32 bytes):

```python
# Add to extract_sprites.py
ENEMY_SPRITES = [
    # ID 0
    SpriteDefinition(
        name="brownie",
        tile_offset=0x02B000,  # Known from sample
        num_tiles=16,
        width_tiles=4,
        height_tiles=4,
        palette_index=4,
        format="4BPP",
        category="enemy"
    ),
    # ID 1
    SpriteDefinition(
        name="mintmint",
        tile_offset=0x02B200,  # +512 bytes
        num_tiles=16,
        width_tiles=4,
        height_tiles=4,
        palette_index=4,
        format="4BPP",
        category="enemy"
    ),
    # ID 2
    SpriteDefinition(
        name="sandman",
        tile_offset=0x02B400,  # +512 bytes
        num_tiles=16,
        width_tiles=4,
        height_tiles=4,
        palette_index=5,
        format="4BPP",
        category="enemy"
    ),
    # Continue for next 7...
]
```

Run extraction:
```bash
python tools/extraction/extract_sprites.py
python tools/extraction/create_sprite_catalog.py
```

Review catalog → Adjust offsets if needed → Iterate

## Alternative: Use Existing Tools

### YY-CHR (Tile Viewer)
1. Download: https://www.romhacking.net/utilities/958/
2. Open FFMQ ROM
3. Navigate to offset 0x028000
4. Set format: SNES 4BPP
5. Load palette from offset 0x030000
6. Manually identify sprites

### Tile Molester
Similar to YY-CHR, different UI

### SNES Palette Editor
Verify palette assignments

## Progress Tracking

Create `docs/ENEMY_SPRITE_MAP.md`:

```markdown
# Enemy Sprite Location Map

| ID | Name | Offset | Size | Palette | Status |
|----|------|--------|------|---------|--------|
| 0  | Brownie | 0x02B000 | 4×4 | 4 | ✓ Extracted |
| 1  | Mintmint | 0x02B200 | 4×4 | 4 | Estimated |
| 2  | Sandman | 0x02B400 | 4×4 | 5 | Estimated |
| ... | ... | ... | ... | ... | ... |
```

## Success Criteria

When complete, you'll have:
- ✓ All 83 enemy sprites extracted as PNG
- ✓ JSON metadata for each enemy
- ✓ Complete visual catalog
- ✓ Documented sprite location map
- ✓ Palette assignments verified
- ✓ Animation frames identified (if any)

## Time Estimates

- **Quick 10 enemies**: 1-2 hours
- **Disassembly research**: 2-3 hours  
- **Complete extraction**: 1-2 hours
- **Verification/cleanup**: 1 hour

**Total**: 5-8 hours to complete all enemy sprites

## After Enemy Extraction

Once enemies are done, remaining graphics work:

1. **Map graphics** - Tileset extraction from Bank 06
2. **Effect sprites** - Magic/battle effects
3. **Overworld sprites** - Walking characters, NPCs
4. **Import pipeline** - PNG → ROM (Phase 2)
5. **Graphics modding guide** - Documentation for ROM hackers

## Questions?

If you want to proceed:
1. Choose approach (A/B/C or Hybrid)
2. Start with first 10 enemies
3. Verify results in catalog
4. Iterate to completion

Or:
1. Move to build integration (Option 2 from original plan)
2. Move to other data types (maps, text, music)

Current infrastructure is solid - any direction is ready to go!
