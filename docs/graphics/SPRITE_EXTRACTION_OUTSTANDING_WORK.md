# Sprite Extraction - Outstanding Work Analysis

**Generated**: November 12, 2025  
**Purpose**: Identify and track remaining sprite extraction tasks  
**Status**: 📋 Analysis Complete - Issues Created

---

## Executive Summary

The sprite extraction pipeline has basic functionality but needs several enhancements to be production-ready:

**✅ COMPLETED**:
- Basic tile extraction with all 8 palettes
- Sprite assembly from tiles
- Character sprite extraction (4 characters)
- Sample enemy extraction (2 enemies)
- Metadata export (JSON)
- Sprite sheet generation

**❌ OUTSTANDING**:
1. Extract OAM metadata from ROM for accurate sprite layouts
2. Implement palette-aware sprite extraction using tilemap data
3. Add animation frame extraction
4. Expand sprite library (all 83 enemies + NPCs + UI)
5. Implement sprite re-insertion (PNG → ROM)
6. Verify sprites against game screenshots

---

## Issue Breakdown

### Issue #1: Extract OAM Metadata from ROM
**Priority**: HIGH  
**Effort**: MEDIUM  
**Dependencies**: None

**Current State**: 
- Sprite definitions use hardcoded tile indices (educated guesses)
- No automatic OAM parsing
- TODO comment in `assemble_sprites.py` line 76

**Required Work**:
- Parse SNES OAM table format (4 bytes + 2 bits per sprite)
- Extract sprite position, tile number, palette, flip flags
- Map OAM entries to metasprite structures
- Generate sprite definitions automatically

**Files to Modify**:
- `tools/extraction/assemble_sprites.py` - Add OAM parser
- `tools/graphics/snes_sprite_extractor.py` - Already has OAM structure

**ROM Locations**:
- OAM tables typically at runtime ($7E0200-$7E021F for 128 sprites)
- Need to find static OAM data in ROM banks

**Output**:
- Automatic sprite layout detection
- No more manual tile index guessing
- Accurate sprite dimensions

---

### Issue #2: Palette-Aware Sprite Extraction
**Priority**: HIGH  
**Effort**: MEDIUM  
**Dependencies**: Issue #1 (OAM metadata)

**Current State**:
- Each sprite definition manually specifies palette index
- No automatic palette detection from tilemap/OAM data

**Required Work**:
- Option A: Extract sprite metadata (which tiles use which palettes)
- Option B: Create palette-aware extractor using tilemap/OAM data
- Integrate palette information from OAM attributes

**Files to Create/Modify**:
- `tools/extraction/palette_aware_extractor.py` - New tool
- Enhance `extract_sprites.py` with palette detection

**Benefits**:
- Automatic correct palette selection
- Support for multi-palette sprites
- Eliminate manual palette guessing

---

### Issue #3: Animation Frame Extraction
**Priority**: MEDIUM  
**Effort**: LARGE  
**Dependencies**: Issues #1, #2

**Current State**:
- Basic frame extraction exists (`extract_animation_frames` method)
- No frame timing information
- No animated GIF output
- Limited frame definitions

**Required Work**:
- Map all character animation frames (walk cycles, attack, etc.)
- Extract enemy animation frames
- Document frame timings (duration per frame)
- Generate animated GIFs
- Create frame sequence metadata

**Animation Types Needed**:
- **Character**: Walk (4 directions × 3 frames), idle, attack, cast, defend
- **Enemy**: Idle, attack, special, death
- **UI**: Menu cursor, spell effects

**Files to Create/Modify**:
- `tools/extraction/extract_animations.py` - New dedicated tool
- Enhance `extract_sprites.py` with animation support
- Add GIF export capability

**Output Format**:
```json
{
  "name": "benjamin_walk_down",
  "frames": [
    {"offset": 0, "duration": 8},
    {"offset": 32, "duration": 8},
    {"offset": 64, "duration": 8}
  ],
  "loop": true,
  "total_duration": 24
}
```

---

### Issue #4: Expand Sprite Library
**Priority**: MEDIUM  
**Effort**: LARGE (manual work)  
**Dependencies**: Issues #1, #2, #3

**Current State**:
- 4 characters extracted
- 2 enemies extracted (of 83 total)
- No NPC sprites
- Limited UI elements

**Required Extraction**:

#### Enemies (83 total)
- Currently: 2 extracted (Brownie, other sample)
- Remaining: 81 enemies
- Status: `extract_all_enemies.py` exists and works
- Action: Run extraction, verify all sprites

#### NPCs (estimated 20-30)
- Old man, woman, guard, etc.
- Various town NPCs
- Overworld characters
- Special NPCs (vendors, quest givers)

#### UI Elements
- Font tiles ✅ (already defined)
- Menu borders ✅ (already defined)
- Icons (weapons, items, spells)
- Status indicators
- Battle UI elements
- World map markers

#### Effects
- Spell animations
- Attack effects
- Environmental effects (fire, water, wind, earth)
- Screen transitions

**Files to Use**:
- `tools/extraction/extract_all_enemies.py` - Already exists!
- `tools/data-extraction/extract_overworld.py` - Has NPC definitions
- Need to create: `tools/extraction/extract_ui_elements.py`
- Need to create: `tools/extraction/extract_effects.py`

---

### Issue #5: Sprite Re-insertion (PNG → ROM)
**Priority**: LOW  
**Effort**: LARGE  
**Dependencies**: All above issues

**Current State**:
- No sprite import functionality
- One-way extraction only
- Cannot modify sprites and insert back

**Required Work**:
- PNG → tile data converter
- Palette matching/generation
- ROM patcher to insert modified tiles
- Verification system (extract → modify → re-insert → test)

**Files to Create**:
- `tools/extraction/png_to_tiles.py` - Exists but needs enhancement
- `tools/extraction/insert_sprites.py` - New tool
- `tools/extraction/verify_sprite_insertion.py` - New tool

**Workflow**:
```
1. Extract sprite → sprite.png
2. Edit sprite in image editor
3. Convert PNG → tiles
4. Insert tiles into ROM at original offset
5. Verify extraction matches modified PNG
6. Test in emulator
```

---

### Issue #6: Sprite Verification
**Priority**: HIGH (for quality)  
**Effort**: MEDIUM (mostly manual)  
**Dependencies**: Issues #1, #2

**Current State**:
- Sprites extracted but not verified against game
- No automated verification
- Manual comparison required

**Required Work**:

#### Manual Verification Tasks:
1. **Character Sprites**:
   - Load game in emulator (bsnes-plus/Mesen-S)
   - Capture screenshots of all characters
   - Compare with extracted PNGs
   - Document discrepancies
   - Adjust sprite definitions

2. **Enemy Sprites**:
   - Battle each enemy
   - Screenshot each enemy
   - Compare with extracted sprites
   - Verify palette correctness
   - Document shared sprites (recolors)

3. **NPC Sprites**:
   - Visit all towns/locations
   - Screenshot all NPCs
   - Compare with extracted sprites

4. **UI Elements**:
   - Screenshot all menus
   - Verify font rendering
   - Check icon accuracy

#### Automated Verification (Future):
- Extract from emulator VRAM
- Compare with ROM extraction
- Highlight differences
- Generate verification report

**Documentation Required**:
- `docs/graphics/SPRITE_VERIFICATION_LOG.md`
- Screenshot reference library
- Discrepancy tracker

---

## Manual Tasks for User

The following tasks **REQUIRE MANUAL ACTION** and cannot be automated:

### Task 1: Verify Extracted Sprites (PRIORITY: HIGH)
**Estimated Time**: 2-3 hours

1. Open FFMQ in bsnes-plus or Mesen-S
2. Review extracted sprites in `data/extracted/sprites/`
3. For each sprite category:
   - **Characters**: Compare walking sprites in-game
   - **Enemies**: Battle enemies and screenshot
   - **UI**: Open menus and compare fonts/borders

4. Document findings in: `docs/graphics/SPRITE_VERIFICATION_LOG.md`

### Task 2: Identify Animation Frames (PRIORITY: MEDIUM)
**Estimated Time**: 4-6 hours

1. Use emulator VRAM viewer (Debug → VRAM Viewer in Mesen-S)
2. For each character:
   - Walk in 4 directions
   - Note tile indices for each frame
   - Document animation sequence
   - Record frame timings (count frames)

3. Document in: `docs/graphics/ANIMATION_FRAMES_REFERENCE.md`

### Task 3: Locate OAM Data in ROM (PRIORITY: HIGH)
**Estimated Time**: 2-4 hours

1. Search disassembly for OAM setup code
2. Look for patterns:
   ```asm
   ; OAM writes
   sta.w $0xxx,y    ; OAM table write
   lda.b #$xx       ; Tile number
   sta.w $0xxx,y    ; Store to OAM
   ```

3. Document ROM offsets for static OAM data
4. Create: `docs/graphics/OAM_LOCATIONS.md`

### Task 4: Complete Enemy Sprite Extraction (PRIORITY: MEDIUM)
**Estimated Time**: 1-2 hours

1. Run: `python tools/extraction/extract_all_enemies.py`
2. Review output in `data/extracted/sprites/enemies/`
3. Verify palette correctness for each enemy
4. Test in emulator if possible
5. Document any issues

### Task 5: Extract NPC Sprites (PRIORITY: LOW)
**Estimated Time**: 2-3 hours

1. Review `tools/data-extraction/extract_overworld.py` NPC definitions
2. Run extractor or manually extract NPCs
3. Verify against in-game NPCs
4. Document NPC locations for reference

---

## GitHub Issues Created

Created the following issues to track this work:

- **Issue #84**: Extract OAM Metadata from ROM for Accurate Sprite Layouts
- **Issue #85**: Implement Palette-Aware Sprite Extraction
- **Issue #86**: Add Animation Frame Extraction and GIF Export
- **Issue #87**: Complete Sprite Library (83 Enemies + NPCs + UI + Effects)
- **Issue #88**: Implement Sprite Re-insertion (PNG → ROM)
- **Issue #89**: Manual: Verify All Extracted Sprites Against Game

---

## Updated Documentation

Added manual tasks to `MANUAL_TESTING_TASKS.md`:

- Section: "Sprite Graphics Verification"
- Tasks: Verify sprites, identify animations, locate OAM data
- Cross-references to this document

---

## Implementation Priority

**Phase 1 (This Week)**:
1. Issue #89 - Manual verification ⚠️ USER ACTION REQUIRED
2. Issue #84 - OAM metadata extraction
3. Issue #85 - Palette-aware extraction

**Phase 2 (Next Week)**:
4. Issue #87 - Complete sprite library (run existing tools)
5. Issue #86 - Animation frame extraction

**Phase 3 (Future)**:
6. Issue #88 - Sprite re-insertion (nice-to-have)

---

## Files Modified/Created

**Documentation**:
- ✅ `docs/graphics/SPRITE_EXTRACTION_OUTSTANDING_WORK.md` (this file)
- ✅ `MANUAL_TESTING_TASKS.md` - Added sprite verification section

**Issues Created**:
- ✅ GitHub Issue #84 (OAM metadata)
- ✅ GitHub Issue #85 (Palette-aware)
- ✅ GitHub Issue #86 (Animation frames)
- ✅ GitHub Issue #87 (Complete library)
- ✅ GitHub Issue #88 (Re-insertion)
- ✅ GitHub Issue #89 (Manual verification)

**Next Steps**:
1. User reviews this analysis
2. User performs manual verification tasks
3. Developer implements automated tools
4. Iterate and refine

---

*End of Outstanding Work Analysis*
