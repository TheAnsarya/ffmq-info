# Screenshot Organization Guide

**Purpose:** Organize game screenshots and VRAM captures for graphics extraction verification  
**Target Users:** Graphics artists, asset extractors, ROM hackers  
**Last Updated:** November 17, 2025

---

## Directory Structure

```
assets/
├── screenshots/
│   ├── README.md (this file)
│   ├── gameplay/
│   │   ├── overworld/
│   │   │   ├── town_scenes/
│   │   │   ├── dungeon_scenes/
│   │   │   ├── world_map/
│   │   │   └── battle_transitions/
│   │   ├── menus/
│   │   │   ├── main_menu/
│   │   │   ├── inventory/
│   │   │   ├── equipment/
│   │   │   ├── magic_menu/
│   │   │   └── status_screen/
│   │   └── cutscenes/
│   │       ├── intro_sequence/
│   │       ├── boss_intros/
│   │       └── ending_sequence/
│   ├── vram_dumps/
│   │   ├── character_sprites/
│   │   │   ├── benjamin_walking/
│   │   │   ├── benjamin_attacking/
│   │   │   ├── benjamin_jumping/
│   │   │   └── companion_sprites/
│   │   ├── enemy_sprites/
│   │   │   ├── bosses/
│   │   │   └── regular_enemies/
│   │   ├── ui_elements/
│   │   │   ├── borders_frames/
│   │   │   ├── icons_symbols/
│   │   │   ├── fonts/
│   │   │   └── cursors/
│   │   ├── backgrounds/
│   │   │   ├── battle_backgrounds/
│   │   │   └── menu_backgrounds/
│   │   └── effects/
│   │       ├── magic_effects/
│   │       ├── weapon_effects/
│   │       └── environmental/
│   ├── tile_maps/
│   │   ├── dungeon_tiles/
│   │   ├── town_tiles/
│   │   └── world_tiles/
│   └── palettes/
│       ├── character_palettes/
│       ├── enemy_palettes/
│       ├── background_palettes/
│       └── palette_animations/
```

---

## File Naming Conventions

### Gameplay Screenshots

**Format:** `{location}_{scene_type}_{optional_detail}_{frame_number}.png`

**Examples:**
```
foresta_town_entrance_001.png
lava_dome_boss_battle_hydra_intro_001.png
focus_tower_puzzle_room_crystals_activated_045.png
overworld_east_continent_bridge_scene_012.png
```

**Rules:**
- Use lowercase with underscores
- Location comes first
- Add frame number for sequences (001, 002, etc.)
- Keep filenames descriptive but concise

---

### VRAM Dumps

**Format:** `{sprite_type}_{name}_{animation}_{frame}_{address_range}.png`

**Examples:**
```
char_benjamin_walk_north_frame_01_vram_0000-01ff.png
char_benjamin_walk_north_frame_02_vram_0000-01ff.png
char_benjamin_attack_sword_frame_01_vram_0200-03ff.png
enemy_boss_hydra_idle_frame_01_vram_2000-23ff.png
ui_icon_sword_equipment_vram_4800-48ff.png
bg_battle_lava_dome_vram_5000-6fff.png
```

**VRAM Address Ranges:**
```
Character Sprites:  $0000-$1FFF (8KB)
Enemy Sprites:      $2000-$3FFF (8KB)
UI Elements:        $4000-$4FFF (4KB)
Backgrounds (BG1):  $5000-$6FFF (8KB)
Backgrounds (BG2):  $7000-$8FFF (8KB)
Backgrounds (BG3):  $9000-$9FFF (4KB)
Fonts/Text:         $A000-$AFFF (4KB)
Effects:            $B000-$BFFF (4KB)
```

**Rules:**
- Include VRAM address range in filename
- Specify animation name and frame number
- Use consistent naming across related frames
- Match names to code labels when possible

---

### Tile Maps

**Format:** `{map_type}_{location}_{layer}_{tile_range}.png`

**Examples:**
```
dungeon_ice_pyramid_bg1_tiles_0000-03ff.png
town_foresta_bg2_tiles_0400-07ff.png
world_map_continent_bg1_tiles_1000-13ff.png
```

---

### Palettes

**Format:** `{palette_type}_{subject}_{variant}_{index}.pal`

**Examples:**
```
char_benjamin_default_pal0.pal
char_benjamin_fire_armor_pal1.pal
enemy_hydra_normal_pal3.pal
bg_lava_dome_day_pal0.pal
bg_lava_dome_night_pal1.pal
```

**Palette File Format (.pal):**
```
; FFMQ Palette - Benjamin Default
; Address: $7EC000, Size: 16 colors (32 bytes)
; Format: SNES 15-bit BGR (0BBB BBGG GGGR RRRR)

0000: 7FFF  ; Color 0: Transparent/background
0002: 0000  ; Color 1: Black (outline)
0004: 14A5  ; Color 2: Skin tone (light)
0006: 1084  ; Color 3: Skin tone (mid)
0008: 0C63  ; Color 4: Skin tone (dark)
000A: 5294  ; Color 5: Hair (brown)
000C: 4210  ; Color 6: Hair (dark brown)
000E: 001F  ; Color 7: Shirt (red)
0010: 0018  ; Color 8: Shirt (dark red)
0012: 03E0  ; Color 9: Pants (green)
0014: 0340  ; Color 10: Pants (dark green)
0016: 7C00  ; Color 11: Boots (blue)
0018: 6800  ; Color 12: Boots (dark blue)
001A: 7FFF  ; Color 13: Highlight (white)
001C: 4210  ; Color 14: Shadow (gray)
001E: 0000  ; Color 15: Reserved
```

---

## Screenshot Capture Methods

### Method 1: Emulator Built-in Tools (Recommended)

**Mesen-S (SNES):**
1. Launch Mesen-S with FFMQ ROM
2. Navigate to `Debug → Debugger`
3. For VRAM capture:
   - Go to `Debug → Tile Viewer` (for tile data)
   - Go to `Debug → Sprite Viewer` (for OAM sprites)
   - Go to `Debug → Palette Viewer` (for palettes)
   - Right-click and select `Export to PNG`
4. For gameplay screenshots:
   - Press `F12` for screenshot
   - Find in `Mesen/Screenshots/` folder

**BSNES-Plus:**
1. Launch BSNES-Plus with FFMQ ROM
2. For VRAM capture:
   - Go to `Tools → Tile Viewer`
   - Select appropriate VRAM range
   - Click `Export` button
3. For OAM capture:
   - Go to `Tools → Sprite Viewer`
   - Click `Export All Sprites`

**Snes9x:**
1. Launch Snes9x with FFMQ ROM
2. Press `PrintScreen` for screenshots
3. For VRAM dumps:
   - Not directly supported
   - Use save state + VRAM extraction tool

---

### Method 2: Command-Line VRAM Extraction

**Using vram-extract.py (custom tool):**

```bash
# Extract character sprite VRAM
python tools/vram-extract.py \
  --savestate ffmq_foresta.000 \
  --vram-start 0x0000 \
  --vram-end 0x1FFF \
  --output assets/screenshots/vram_dumps/character_sprites/

# Extract with palette
python tools/vram-extract.py \
  --savestate ffmq_battle_hydra.000 \
  --vram-start 0x2000 \
  --vram-end 0x23FF \
  --palette-addr 0x7EC000 \
  --palette-count 16 \
  --output assets/screenshots/vram_dumps/enemy_sprites/bosses/
```

---

### Method 3: Live Capture During Gameplay

**Recording Animated Sequences:**

1. **Setup:**
   - Configure emulator to record at 60 FPS
   - Set output format to PNG sequence or MP4
   - Enable frame number overlay (optional)

2. **Capture Locations:**
   ```
   Character Walking:
   - All 4 directions (N, S, E, W)
   - All movement speeds (walk, run)
   - All states (normal, attacking, jumping)
   
   Enemy Sprites:
   - Idle animation
   - Attack animations
   - Hit/damage reactions
   - Death animations
   
   UI Elements:
   - Menu transitions (fade in/out)
   - Cursor movements
   - Text box displays
   - Battle command selection
   ```

3. **Frame Extraction:**
   ```bash
   # Extract frames from recording
   ffmpeg -i benjamin_walk_north.mp4 -vf fps=60 \
     assets/screenshots/gameplay/overworld/benjamin_walk_north_frame_%04d.png
   ```

---

## Verification Checklist

### Character Sprite Verification

Use these screenshots to verify extracted character graphics:

**Benjamin - Walking Animations:**
- [ ] `benjamin_walk_north_frames_01-04.png` - North walking cycle (4 frames)
- [ ] `benjamin_walk_south_frames_01-04.png` - South walking cycle (4 frames)
- [ ] `benjamin_walk_east_frames_01-04.png` - East walking cycle (4 frames)
- [ ] `benjamin_walk_west_frames_01-04.png` - West walking cycle (4 frames)

**Expected VRAM Layout:**
```
Frame 1: $0000-$003F (16×16 tile, 4 tiles)
Frame 2: $0040-$007F (16×16 tile, 4 tiles)
Frame 3: $0080-$00BF (16×16 tile, 4 tiles)
Frame 4: $00C0-$00FF (16×16 tile, 4 tiles)
```

**Benjamin - Attack Animations:**
- [ ] `benjamin_attack_sword_frames_01-08.png` - Sword attack (8 frames)
- [ ] `benjamin_attack_axe_frames_01-08.png` - Axe attack (8 frames)
- [ ] `benjamin_attack_claw_frames_01-08.png` - Claw attack (8 frames)

**Companion Characters:**
- [ ] `companion_kaeli_walk_frames_01-04.png` - Kaeli walking
- [ ] `companion_tristam_walk_frames_01-04.png` - Tristam walking
- [ ] `companion_phoebe_walk_frames_01-04.png` - Phoebe walking
- [ ] `companion_reuben_walk_frames_01-04.png` - Reuben walking

---

### Enemy Sprite Verification

**Boss Sprites:**
- [ ] `boss_hydra_vram_2000-23ff.png` - Lava Dome boss
- [ ] `boss_medusa_vram_2400-27ff.png` - Pazuzu boss
- [ ] `boss_dullahan_vram_2800-2bff.png` - Spencer boss
- [ ] `boss_flamerus_rex_vram_2c00-2fff.png` - Volcano boss

**Regular Enemies (sample):**
- [ ] `enemy_goblin_vram_3000-30ff.png` - Standard goblin
- [ ] `enemy_lizard_man_vram_3100-31ff.png` - Lizard Man
- [ ] `enemy_minotaur_vram_3200-32ff.png` - Minotaur

**Expected Tile Count:**
```
Small enemies (16×16): 4 tiles (64 bytes)
Medium enemies (32×32): 16 tiles (512 bytes)
Large enemies (64×64): 64 tiles (2048 bytes)
Boss sprites (variable): Up to 128 tiles (4096 bytes)
```

---

### UI Element Verification

**Menu Borders:**
- [ ] `ui_border_main_menu.png` - Main menu frame
- [ ] `ui_border_battle_window.png` - Battle command window
- [ ] `ui_border_dialog_box.png` - Dialog text box

**Icons:**
- [ ] `ui_icon_weapons_all.png` - All weapon icons (sword, axe, claw, bomb)
- [ ] `ui_icon_armor_all.png` - All armor icons
- [ ] `ui_icon_accessories_all.png` - All accessory icons
- [ ] `ui_icon_items_consumable.png` - Consumable item icons

**Cursor Sprites:**
- [ ] `ui_cursor_hand_frames_01-02.png` - Hand cursor animation
- [ ] `ui_cursor_battle_target.png` - Battle target cursor

---

### Background Verification

**Battle Backgrounds:**
- [ ] `bg_battle_foresta_forest.png` - Forest battle background
- [ ] `bg_battle_lava_dome.png` - Lava Dome battle background
- [ ] `bg_battle_ice_pyramid.png` - Ice Pyramid battle background
- [ ] `bg_battle_volcano.png` - Volcano battle background

**Expected Resolution:** 256×224 pixels (SNES native)

**Expected Layers:**
```
BG1: Main background layer (parallax layer 1)
BG2: Foreground details (parallax layer 2)
BG3: Far background (sky, distant mountains)
```

---

### Palette Verification

**Character Palettes:**
- [ ] `palette_benjamin_default.pal` - Default outfit
- [ ] `palette_benjamin_steel_armor.pal` - With Steel Armor
- [ ] `palette_benjamin_fire_armor.pal` - With Flame Armor
- [ ] `palette_benjamin_ice_armor.pal` - With Blizzard Armor

**Expected Palette Counts:**
```
Character sprites: 4-8 colors per sprite (uses palette 0-1)
Enemy sprites: 8-16 colors per enemy (uses palette 2-7)
Backgrounds: 16-128 colors (uses all 8 palettes)
UI elements: 4-8 colors (uses palette 0)
```

**Palette Memory Locations:**
```
CGRAM: $000-$1FF (512 bytes, 256 colors)
Palette 0: $000-$01F (16 colors, character/UI)
Palette 1: $020-$03F (16 colors, character alternate)
Palette 2: $040-$05F (16 colors, enemy 1)
Palette 3: $060-$07F (16 colors, enemy 2)
Palette 4: $080-$09F (16 colors, background 1)
Palette 5: $0A0-$0BF (16 colors, background 2)
Palette 6: $0C0-$0DF (16 colors, background 3)
Palette 7: $0E0-$0FF (16 colors, effects)
```

---

## Integration with Code

### Linking Screenshots to Code

**In assembly documentation:**

```asm
; Character walking animation - North direction
; Graphics data loaded at $7E0000-$7E01FF
; Animation frames: 4 frames, 60 ticks per frame
; See screenshot: assets/screenshots/vram_dumps/character_sprites/
;                 benjamin_walking/benjamin_walk_north_frame_01_vram_0000-01ff.png

LoadCharacterWalkNorth:
    ldx.w #$0000        ; VRAM destination
    ldy.w #CharWalkNorth_Tiles ; Source address
    lda.w #$0200        ; Size: 512 bytes (4 frames × 128 bytes)
    jsl.l DMA_Transfer  ; Execute DMA
    rts

CharWalkNorth_Tiles:
    .incbin "data/graphics/char_benjamin_walk_north.bin"
```

**In documentation files:**

```markdown
## Character Animation System

### Walking Animation - Benjamin

The walking animation consists of 4 frames repeated in a cycle:

![Benjamin Walk North Frame 1](../assets/screenshots/vram_dumps/character_sprites/benjamin_walking/benjamin_walk_north_frame_01_vram_0000-01ff.png)
![Benjamin Walk North Frame 2](../assets/screenshots/vram_dumps/character_sprites/benjamin_walking/benjamin_walk_north_frame_02_vram_0000-01ff.png)

**VRAM Layout:**
- Frame 1: $0000-$003F
- Frame 2: $0040-$007F
```

---

## Automated Verification Scripts

### compare_extracted_sprites.py

```python
#!/usr/bin/env python3
"""
Compare extracted sprite data against reference screenshots
to verify graphics extraction is correct.
"""

import os
from PIL import Image
import numpy as np

def compare_sprites(reference_path, extracted_path, tolerance=5):
    """
    Compare reference screenshot with extracted sprite data.
    
    Args:
        reference_path: Path to reference screenshot
        extracted_path: Path to extracted sprite image
        tolerance: Pixel difference tolerance (0-255)
    
    Returns:
        (match_percentage, difference_image)
    """
    ref_img = Image.open(reference_path).convert('RGB')
    ext_img = Image.open(extracted_path).convert('RGB')
    
    # Resize if needed
    if ref_img.size != ext_img.size:
        ext_img = ext_img.resize(ref_img.size, Image.NEAREST)
    
    ref_arr = np.array(ref_img)
    ext_arr = np.array(ext_img)
    
    # Calculate pixel-wise difference
    diff = np.abs(ref_arr.astype(int) - ext_arr.astype(int))
    matches = np.all(diff <= tolerance, axis=2)
    match_percentage = np.sum(matches) / matches.size * 100
    
    # Create difference visualization
    diff_img = np.zeros_like(ref_arr)
    diff_img[matches] = [0, 255, 0]  # Green for matches
    diff_img[~matches] = [255, 0, 0]  # Red for differences
    
    return match_percentage, Image.fromarray(diff_img.astype(np.uint8))

# Usage example
if __name__ == "__main__":
    ref = "assets/screenshots/vram_dumps/character_sprites/benjamin_walking/benjamin_walk_north_frame_01_vram_0000-01ff.png"
    ext = "build/extracted_graphics/character_sprites/benjamin_walk_north_01.png"
    
    match_pct, diff_img = compare_sprites(ref, ext)
    
    print(f"Match: {match_pct:.2f}%")
    
    if match_pct < 95.0:
        print("WARNING: Extracted sprite differs from reference!")
        diff_img.save("verification/sprite_diff.png")
    else:
        print("✓ Sprite extraction verified successfully!")
```

---

## Tools and Resources

### Recommended Emulators

**Mesen-S:**
- Homepage: https://mesen.ca
- Features: Best debugging tools, VRAM viewer, tile viewer, sprite viewer
- Download: https://github.com/SourMesen/Mesen-S/releases

**BSNES-Plus:**
- Homepage: https://github.com/devinacker/bsnes-plus
- Features: Comprehensive debugging, memory viewers, trace logging
- Best for: Advanced ROM hacking and reverse engineering

**Snes9x:**
- Homepage: https://www.snes9x.com
- Features: Fast, lightweight, good for recording
- Best for: Gameplay screenshots and video capture

### Graphics Extraction Tools

**Lunar Compress:**
- Purpose: Decompress SNES graphics data
- Download: https://www.romhacking.net/utilities/
- Usage: `lc -d ffmq.smc char_graphics.bin`

**YY-CHR:**
- Purpose: View and edit SNES tile data
- Download: https://www.romhacking.net/utilities/119/
- Features: Real-time tile viewer, palette editor

**Tile Molester:**
- Purpose: Generic tile viewer for multiple formats
- Download: https://www.romhacking.net/utilities/108/
- Features: Custom codecs, batch export

---

## Next Steps

1. **Capture Reference Screenshots:**
   - Play through entire game with emulator
   - Capture all unique graphics states
   - Organize into directory structure

2. **Extract Graphics from ROM:**
   - Use extraction tools to pull graphics data
   - Convert to PNG format
   - Organize matching reference structure

3. **Verify Extraction:**
   - Run automated comparison scripts
   - Manually review any differences
   - Document any discrepancies

4. **Document Graphics System:**
   - Link screenshots to code
   - Create graphics data maps
   - Build asset database

5. **Asset Re-insertion Testing:**
   - Modify extracted graphics
   - Re-insert into ROM
   - Verify in-game appearance

---

*For questions or contributions, see CONTRIBUTING.md*
