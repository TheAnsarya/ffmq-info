# Graphics System Documentation

This directory contains comprehensive documentation for the Final Fantasy Mystic Quest graphics system, including SNES graphics formats, extraction workflows, palette management, and sprite editing.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation Index](#documentation-index)
  - [Graphics System](#graphics-system)
  - [Extraction & Tools](#extraction--tools)
  - [Specific Graphics Types](#specific-graphics-types)
  - [Workflows & Processes](#workflows--processes)
  - [Reference & Catalogs](#reference--catalogs)
- [Common Workflows](#common-workflows)
- [Graphics Formats](#graphics-formats)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

---

## Overview

FFMQ uses the standard SNES graphics system with some game-specific conventions:

**Graphics Features:**
- **4bpp (16-color) tiles** - Standard SNES tile format
- **8x8 pixel tiles** - Basic tile unit
- **256 8x8 tiles per tileset** - Standard tileset size
- **Multiple palettes** - Character, enemy, UI, background palettes
- **Compression** - Some graphics use custom compression
- **DMA transfers** - Graphics loaded via DMA during gameplay

**Graphics Categories:**
- **Character Sprites** - Player characters, NPCs
- **Enemy Sprites** - Battle enemy graphics
- **UI Elements** - Menus, windows, fonts
- **Background Tiles** - Map tiles, decorative elements
- **Battle Backgrounds** - Battle scene backgrounds
- **Effect Sprites** - Spell effects, animations

---

## Quick Start

### View Graphics Catalog

```bash
# Open graphics catalog in browser
start docs/graphics/graphics_catalog/index.html

# Categories available:
# - Characters (player, NPCs)
# - Enemies (all battle sprites)
# - UI (menus, fonts, icons)
# - Palettes (all color palettes)
```

### Extract Graphics

```bash
# Extract all graphics
python tools/graphics/extract_graphics_v2.py --all

# Extract specific category
python tools/graphics/extract_graphics_v2.py --enemies
python tools/graphics/extract_graphics_v2.py --characters

# Extract to specific directory
python tools/graphics/extract_graphics_v2.py --all --output assets/graphics/
```

### Convert Graphics

```bash
# Convert SNES tile to PNG
python tools/graphics/snes_graphics.py tile_to_png \
    --input src/graphics/character_tiles.bin \
    --output assets/graphics/character.png \
    --palette src/graphics/character_palette.bin

# Convert PNG to SNES tile
python tools/graphics/snes_graphics.py png_to_tile \
    --input assets/graphics/modified_character.png \
    --output src/graphics/character_tiles_new.bin \
    --palette-output src/graphics/character_palette_new.bin
```

### Edit Palettes

```bash
# Extract palette
python tools/graphics/palette_editor.py extract \
    --rom roms/ffmq.sfc \
    --address 0x123456 \
    --output palettes/character.pal

# Edit palette (opens editor GUI)
python tools/graphics/palette_editor.py edit \
    --palette palettes/character.pal

# Apply palette to ROM
python tools/graphics/palette_editor.py apply \
    --palette palettes/character_modified.pal \
    --rom build/ffmq.sfc \
    --address 0x123456
```

---

## Documentation Index

### Graphics System

#### [`GRAPHICS_SYSTEM.md`](GRAPHICS_SYSTEM.md) 🎨 **START HERE**
*Complete graphics system architecture and overview*

**Contents:**
- SNES graphics fundamentals
- FFMQ graphics architecture
- Memory layout and organization
- DMA and loading system
- Graphics data structures

**Use when:**
- Understanding graphics system
- Planning graphics modifications
- Debugging graphics issues
- Learning SNES graphics

**SNES Graphics Fundamentals:**

**Tile Format (4bpp):**
```
Each 8x8 tile = 32 bytes
- 2 bitplanes: 16 bytes (8 bytes each)
- 2 more bitplanes: 16 bytes (8 bytes each)
- Total: 4 bits per pixel = 16 colors

Tile structure:
Bytes 0-7:   Bitplane 0
Bytes 8-15:  Bitplane 1
Bytes 16-23: Bitplane 2
Bytes 24-31: Bitplane 3

Pixel decoding:
- Bit from each plane = 4-bit color index
- Color index → palette → 15-bit RGB color
```

**Palette Format:**
```
Each palette = 16 colors
Each color = 2 bytes (15-bit RGB)

Format: 0bbbbbgggggrrrrr
- 5 bits red
- 5 bits green
- 5 bits blue
- 1 bit unused (always 0)

Example:
0x7FFF = white (11111 11111 11111)
0x0000 = black (00000 00000 00000)
0x001F = red   (00000 00000 11111)
0x03E0 = green (00000 11111 00000)
0x7C00 = blue  (11111 00000 00000)
```

**FFMQ Graphics Organization:**

**Character Graphics:**
```
Bank $0C: Character sprite data
- Player character sprites
- NPC sprites
- Overworld sprites

Format: 4bpp tiles
Loading: DMA during map load
Palettes: Multiple per character
```

**Enemy Graphics:**
```
Bank $0D: Enemy sprite data
- Battle enemy sprites
- Boss sprites
- Enemy animations

Format: 4bpp tiles
Loading: DMA during battle init
Palettes: Unique per enemy
Compression: Custom RLE compression
```

**UI Graphics:**
```
Bank $0E: UI element data
- Menu windows
- Font data
- Icons and cursors
- HP/MP bars

Format: 4bpp tiles
Loading: Loaded at game start
Palettes: Fixed UI palette
```

**DMA Loading System:**
```
Graphics loaded via DMA:
1. Set source address (ROM)
2. Set destination (VRAM)
3. Set transfer size
4. Initiate DMA transfer
5. Wait for completion

Example (65816 assembly):
    LDA #$01        ; DMA channel 0
    STA $4300       ; Set DMA mode
    LDA #$18        ; Destination: VRAM data
    STA $4301
    LDX #$C000      ; Source: Bank $0C, $C000
    STX $4302
    LDA #$0C
    STA $4304
    LDX #$2000      ; Size: 8KB
    STX $4305
    LDA #$01        ; Start DMA
    STA $420B
```

---

#### [`graphics-format.md`](graphics-format.md) 📐 Technical Format Details
*Low-level graphics data format specifications*

**Contents:**
- Byte-level format specifications
- Bitplane encoding details
- Palette data structures
- Compression formats
- VRAM layout

**Use when:**
- Implementing graphics tools
- Debugging format issues
- Understanding compression
- Manual hex editing

**4bpp Tile Format Specification:**

**Tile Structure (32 bytes per 8x8 tile):**
```
Offset  Size  Description
------  ----  -----------
0x00    8     Bitplane 0 (rows 0-7, bit 0 of each pixel)
0x08    8     Bitplane 1 (rows 0-7, bit 1 of each pixel)
0x10    8     Bitplane 2 (rows 0-7, bit 2 of each pixel)
0x18    8     Bitplane 3 (rows 0-7, bit 3 of each pixel)
```

**Bitplane Encoding:**
```
Each row = 1 byte
8 pixels per row
Bit order: MSB = leftmost pixel

Example row (bitplane 0):
Binary:  10110001
Pixels:  1 0 1 1 0 0 0 1
         ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
         0 1 2 3 4 5 6 7 (pixel positions)

Complete pixel color:
Pixel 0 = bit0(plane0) | bit1(plane1) | bit2(plane2) | bit3(plane3)
        = 1 | 0<<1 | 1<<2 | 0<<3
        = 0b0101 = 5 (color index 5)
```

**Palette Format Specification:**

**16-Color Palette (32 bytes):**
```
Offset  Size  Description
------  ----  -----------
0x00    2     Color 0 (little-endian 15-bit RGB)
0x02    2     Color 1
0x04    2     Color 2
...
0x1E    2     Color 15
```

**15-bit RGB Color Format:**
```
Little-endian 2-byte value:
Byte 0: gggrrrrr
Byte 1: 0bbbbbgg

Bit layout (big-endian view):
15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
 0  b  b  b  b  b  g  g  g  g  g  r  r  r  r  r

Extraction:
Red   = (value & 0x001F)
Green = (value & 0x03E0) >> 5
Blue  = (value & 0x7C00) >> 10

Conversion to 24-bit RGB:
Red24   = Red5 << 3   | Red5 >> 2    (distribute over 8 bits)
Green24 = Green5 << 3 | Green5 >> 2
Blue24  = Blue5 << 3  | Blue5 >> 2
```

**Compression Format:**

**RLE Compression (used for enemy sprites):**
```
Compressed data format:
- Control byte determines operation
- If control byte < 0x80: Literal run
  - Next N bytes are literal data
- If control byte >= 0x80: RLE run
  - Next byte repeated N times

Example:
Input:  AA AA AA AA BB CC DD DD DD
Compressed: 83 AA 01 BB 01 CC 82 DD
            ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑
            |  |  |  |  |  |  |  └─ Data
            |  |  |  |  |  |  └─ Count (repeat 3x)
            |  |  |  |  |  └─ Data
            |  |  |  |  └─ Count (literal 1)
            |  |  |  └─ Data
            |  |  └─ Count (literal 1)
            |  └─ Data
            └─ Count (repeat 4x)
```

**Decompression Algorithm:**
```python
def decompress_rle(compressed_data):
    output = []
    i = 0
    while i < len(compressed_data):
        control = compressed_data[i]
        i += 1
        
        if control < 0x80:
            # Literal run
            count = control + 1
            output.extend(compressed_data[i:i+count])
            i += count
        else:
            # RLE run
            count = control - 0x80 + 1
            value = compressed_data[i]
            output.extend([value] * count)
            i += 1
    
    return bytes(output)
```

---

### Extraction & Tools

#### [`GRAPHICS_EXTRACTION_GUIDE.md`](GRAPHICS_EXTRACTION_GUIDE.md) 🔧 Extraction Guide
*Complete guide to extracting graphics from ROM*

**Contents:**
- Extraction tool usage
- Finding graphics in ROM
- Handling compressed graphics
- Batch extraction workflows
- Format conversion

**Use when:**
- Extracting graphics from ROM
- Building graphics asset library
- Preparing for graphics editing
- Reverse engineering graphics

**Extraction Workflow:**

**Step 1: Identify Graphics Location**
```bash
# Search for graphics patterns
python tools/rom-operations/find_graphics.py roms/ffmq.sfc

# Output:
# Found potential graphics at:
#   $0C8000 - Character sprites (4bpp, uncompressed)
#   $0D0000 - Enemy sprites (4bpp, RLE compressed)
#   $0E0000 - UI graphics (4bpp, uncompressed)
```

**Step 2: Extract Graphics**
```bash
# Extract specific address range
python tools/graphics/extract_graphics_v2.py \
    --rom roms/ffmq.sfc \
    --address 0x0C8000 \
    --size 0x8000 \
    --output assets/graphics/characters/ \
    --format 4bpp

# Extract with automatic detection
python tools/graphics/extract_graphics_v2.py \
    --rom roms/ffmq.sfc \
    --auto-detect \
    --output assets/graphics/
```

**Step 3: Handle Compressed Graphics**
```bash
# Extract compressed enemy sprites
python tools/graphics/extract_graphics_v2.py \
    --rom roms/ffmq.sfc \
    --address 0x0D0000 \
    --compressed rle \
    --output assets/graphics/enemies/

# Decompress to raw tiles
python tools/graphics/decompress_graphics.py \
    --input assets/graphics/enemies/enemy_01.bin.compressed \
    --output assets/graphics/enemies/enemy_01.bin \
    --format rle
```

**Step 4: Extract Palettes**
```bash
# Extract all palettes
python tools/graphics/extract_palettes.py \
    --rom roms/ffmq.sfc \
    --output assets/palettes/

# Extract specific palette
python tools/graphics/palette_editor.py extract \
    --rom roms/ffmq.sfc \
    --address 0x123456 \
    --count 16 \
    --output assets/palettes/character.pal
```

**Step 5: Convert to PNG**
```bash
# Convert tiles to viewable PNG
python tools/graphics/snes_graphics.py tile_to_png \
    --input assets/graphics/characters/benjamin.bin \
    --palette assets/palettes/benjamin.pal \
    --output assets/graphics/characters/benjamin.png \
    --tile-width 16 \
    --tile-height 16

# Batch convert all graphics
python tools/graphics/batch_convert.py \
    --input-dir assets/graphics/raw/ \
    --output-dir assets/graphics/png/ \
    --format png
```

**Finding Graphics in ROM:**

**Method 1: Known Addresses (from disassembly)**
```bash
# Check disassembly for graphics references
grep -r "graphics_" src/

# Example findings:
# src/bank_0C.asm:char_graphics_benjamin: .incbin "graphics/benjamin.bin"
# src/bank_0D.asm:enemy_graphics_minotaur: .incbin "graphics/enemies/minotaur.bin"
```

**Method 2: Pattern Recognition**
```bash
# Search for graphics patterns
python tools/rom-operations/find_graphics.py \
    --rom roms/ffmq.sfc \
    --type 4bpp \
    --min-size 0x1000

# Heuristics used:
# - Low entropy (graphics have patterns)
# - Aligned addresses (usually 0x100 or 0x1000 aligned)
# - Reasonable size (multiple of 32 bytes for tiles)
# - Valid tile patterns (not random noise)
```

**Method 3: Visual ROM Scanning**
```bash
# Use tile viewer to scan ROM
python tools/graphics/rom_tile_viewer.py \
    --rom roms/ffmq.sfc \
    --start 0x0C0000 \
    --end 0x100000 \
    --format 4bpp

# Visually identify graphics regions
# Save regions of interest
```

**Handling Compressed Graphics:**

**Detect Compression:**
```python
# tools/graphics/detect_compression.py
def detect_compression(data):
    """Detect if data is compressed and what format."""
    # RLE detection
    if has_rle_patterns(data):
        return 'rle'
    
    # LZ77 detection
    if has_lz77_header(data):
        return 'lz77'
    
    # Uncompressed
    if is_valid_tile_data(data):
        return None
    
    return 'unknown'
```

**Decompress RLE:**
```bash
# Automatic decompression
python tools/graphics/extract_graphics_v2.py \
    --rom roms/ffmq.sfc \
    --address 0x0D0000 \
    --auto-decompress \
    --output assets/graphics/enemies/

# Manual decompression with format specification
python tools/graphics/decompress_graphics.py \
    --input compressed_data.bin \
    --format rle \
    --output decompressed_data.bin
```

---

#### [`GRAPHICS_EXTRACTION_REPORT.md`](GRAPHICS_EXTRACTION_REPORT.md) 📊 Extraction Status
*Report on graphics extraction completeness*

**Contents:**
- Extraction completion status
- Identified graphics locations
- Missing/unknown graphics
- Catalog of extracted assets

**Use when:**
- Checking extraction progress
- Finding specific graphics
- Identifying gaps in extraction

**Extraction Status Summary:**

**Character Graphics: 95% Complete**
- ✅ Player characters (Benjamin, Kaeli, Phoebe, Reuben)
- ✅ NPCs (townsfolk, merchants, old men, etc.)
- ✅ Overworld sprites
- ⏳ Some minor NPC variations
- ❌ Unused character sprites (if any)

**Enemy Graphics: 100% Complete** ✅
- ✅ All enemy battle sprites extracted
- ✅ All boss sprites extracted
- ✅ Enemy palettes documented
- ✅ Animation frames identified

**UI Graphics: 90% Complete**
- ✅ Menu windows
- ✅ Font (complete character set)
- ✅ Icons (items, status, etc.)
- ✅ HP/MP bars
- ⏳ Some minor UI elements
- ❌ Debug UI (if exists)

**Background Tiles: 80% Complete**
- ✅ Main map tilesets
- ✅ Town tilesets
- ✅ Dungeon tilesets
- ⏳ Special area tiles
- ❌ Unused tiles

**Palette Extraction: 100% Complete** ✅
- ✅ Character palettes
- ✅ Enemy palettes
- ✅ UI palettes
- ✅ Background palettes
- ✅ Battle background palettes

**Graphics Location Map:**
```
Bank $0C: Character Graphics
  $0C8000-$0CBFFF: Player character sprites
  $0CC000-$0CFFFF: NPC sprites

Bank $0D: Enemy Graphics (compressed)
  $0D0000-$0D3FFF: Small enemies
  $0D4000-$0D7FFF: Medium enemies
  $0D8000-$0DFFFF: Large enemies and bosses

Bank $0E: UI Graphics
  $0E0000-$0E1FFF: Menu graphics
  $0E2000-$0E3FFF: Font data
  $0E4000-$0E5FFF: Icons and cursors

Bank $0F: Background Tiles
  $0F0000-$0F3FFF: Overworld tiles
  $0F4000-$0F7FFF: Town tiles
  $0F8000-$0FBFFF: Dungeon tiles
```

---

#### [`GRAPHICS_PALETTE_WORKFLOW.md`](GRAPHICS_PALETTE_WORKFLOW.md) 🎨 Palette Workflow
*Complete palette editing and management workflow*

**Contents:**
- Palette extraction
- Palette editing techniques
- Color selection best practices
- SNES color limitations
- Re-inserting modified palettes

**Use when:**
- Creating palette variations
- Color customization
- Fixing palette issues
- Understanding SNES color system

**Complete Palette Workflow:**

**Step 1: Extract Current Palette**
```bash
# Extract palette from ROM
python tools/graphics/palette_editor.py extract \
    --rom roms/ffmq.sfc \
    --address 0x123456 \
    --count 16 \
    --output palettes/original.pal \
    --format snes

# View palette
python tools/graphics/palette_editor.py view \
    --palette palettes/original.pal
```

**Step 2: Edit Palette**

**Option A: GUI Editor**
```bash
# Launch GUI editor
python tools/graphics/palette_editor.py edit \
    --palette palettes/original.pal \
    --output palettes/modified.pal

# Features:
# - Visual color picker
# - RGB/HSV editing
# - Color swapping
# - Palette preview with tiles
# - SNES color preview (15-bit)
```

**Option B: Programmatic Editing**
```python
# Python script for batch palette editing
from tools.graphics import palette_utils

# Load palette
palette = palette_utils.load_palette('palettes/original.pal')

# Modify colors
palette[0] = (255, 0, 0)      # Red
palette[1] = (0, 255, 0)      # Green
palette[2] = (0, 0, 255)      # Blue
palette[3] = (255, 255, 0)    # Yellow

# Apply color transformation
palette = palette_utils.adjust_brightness(palette, 1.2)
palette = palette_utils.adjust_saturation(palette, 0.8)

# Save modified palette
palette_utils.save_palette(palette, 'palettes/modified.pal')
```

**Step 3: Preview with Tiles**
```bash
# Preview palette with actual tiles
python tools/graphics/snes_graphics.py tile_to_png \
    --input assets/graphics/character.bin \
    --palette palettes/modified.pal \
    --output preview/character_new_palette.png

# Compare with original
python tools/graphics/compare_palettes.py \
    --original-tiles preview/character_original.png \
    --modified-tiles preview/character_new_palette.png \
    --output preview/comparison.png
```

**Step 4: Insert Modified Palette**
```bash
# Insert palette into ROM
python tools/graphics/palette_editor.py apply \
    --palette palettes/modified.pal \
    --rom build/ffmq.sfc \
    --address 0x123456

# Verify insertion
python tools/graphics/palette_editor.py verify \
    --rom build/ffmq.sfc \
    --address 0x123456 \
    --expected-palette palettes/modified.pal
```

**SNES Color Limitations:**

**15-bit Color Space:**
```
SNES uses 15-bit color (5 bits per channel)
- 32 levels per channel (0-31)
- 32768 total colors (32 × 32 × 32)

Converting 24-bit RGB to 15-bit:
Red15   = Red24 >> 3    (divide by 8)
Green15 = Green24 >> 3
Blue15  = Blue24 >> 3

Converting 15-bit back to 24-bit:
Red24   = (Red15 << 3) | (Red15 >> 2)
Green24 = (Green15 << 3) | (Green15 >> 2)
Blue24  = (Blue15 << 3) | (Blue15 >> 2)

Note: Converting to 15-bit and back loses precision!
```

**Color Selection Best Practices:**

**1. Work in 15-bit from the start:**
```python
# Use quantized colors
def quantize_to_snes(r, g, b):
    """Convert 24-bit RGB to SNES 15-bit and back."""
    r15 = r >> 3
    g15 = g >> 3
    b15 = b >> 3
    return (r15 << 3, g15 << 3, b15 << 3)

# Use this when selecting colors
color = quantize_to_snes(128, 192, 255)
```

**2. Use palette templates:**
```bash
# Create palette template with good color ramps
python tools/graphics/create_palette_template.py \
    --type character \
    --output palettes/template.pal

# Templates include:
# - Proper shadow/highlight ramps
# - Complementary colors
# - SNES-quantized colors
```

**3. Test on hardware/accurate emulator:**
```bash
# SNES colors look different on real hardware
# Always test with accurate emulator (Mesen-S, bsnes)
# or on real SNES hardware

# Export for testing
python tools/build/build_rom.py
# Test in Mesen-S or on real hardware
```

**Common Palette Techniques:**

**Creating Color Ramps:**
```python
def create_color_ramp(start_color, end_color, steps):
    """Create smooth color ramp between two colors."""
    ramp = []
    for i in range(steps):
        t = i / (steps - 1)
        r = int(start_color[0] * (1-t) + end_color[0] * t)
        g = int(start_color[1] * (1-t) + end_color[1] * t)
        b = int(start_color[2] * (1-t) + end_color[2] * t)
        ramp.append(quantize_to_snes(r, g, b))
    return ramp

# Example: Skin tone ramp
skin_ramp = create_color_ramp(
    (255, 220, 177),  # Light skin
    (139, 90, 60),    # Dark skin
    8                 # 8 levels
)
```

**Palette Swapping for Variations:**
```python
# Create enemy variations by palette swapping
base_palette = load_palette('palettes/slime_blue.pal')

# Green slime
green_palette = base_palette.copy()
swap_hue(green_palette, target_hue=120)  # Green
save_palette(green_palette, 'palettes/slime_green.pal')

# Red slime
red_palette = base_palette.copy()
swap_hue(red_palette, target_hue=0)  # Red
save_palette(red_palette, 'palettes/slime_red.pal')
```

---

### Specific Graphics Types

#### [`ENEMY_SPRITES_COMPLETE.md`](ENEMY_SPRITES_COMPLETE.md) 👾 Enemy Sprites
*Complete enemy sprite documentation*

**Contents:**
- All enemy sprite locations
- Enemy sprite formats
- Animation frame organization
- Palette assignments
- Extraction and editing guide

**Use when:**
- Working with enemy graphics
- Creating enemy variations
- Understanding enemy animations
- Debugging enemy display

**Enemy Sprite Organization:**

**Storage Format:**
```
Location: Bank $0D ($0D0000-$0DFFFF)
Format: 4bpp tiles, RLE compressed
Organization: Sequential by enemy ID

Enemy data structure:
- Compressed tile data
- Palette reference (2 bytes)
- Animation frame count (1 byte)
- Frame timing data (N bytes)
```

**Enemy List with Locations:**

**Small Enemies (1-2 tiles, $0D0000-$0D3FFF):**
```
Enemy ID  Name             Address    Size (compressed)  Frames
--------  ----             -------    -----------------  ------
0x00      Goblin           $0D0000    0x0180            4
0x01      Snake            $0D0180    0x0140            2
0x02      Bee              $0D02C0    0x0160            4
0x03      Lizard           $0D0420    0x01A0            2
...
```

**Medium Enemies (2-4 tiles, $0D4000-$0D7FFF):**
```
Enemy ID  Name             Address    Size (compressed)  Frames
--------  ----             -------    -----------------  ------
0x20      Orc              $0D4000    0x0280            4
0x21      Skeleton         $0D4280    0x02C0            6
0x22      Gargoyle         $0D4540    0x0300            4
...
```

**Large Enemies & Bosses (4+ tiles, $0D8000-$0DFFFF):**
```
Enemy ID  Name             Address    Size (compressed)  Frames
--------  ----             -------    -----------------  ------
0x40      Minotaur         $0D8000    0x0500            8
0x41      Dark King        $0D8500    0x0600            12
0x42      Pazuzu           $0D8B00    0x0700            10
...
```

**Enemy Palettes:**
```
Location: Bank $0D, after sprite data
Format: 16-color SNES palettes (32 bytes each)

Palette assignments:
- Each enemy has dedicated palette
- Some enemies share palettes (color variations)
- Boss enemies have unique palettes
```

**Extracting Enemy Sprites:**

**Single Enemy:**
```bash
# Extract specific enemy
python tools/graphics/extract_enemy_sprite.py \
    --rom roms/ffmq.sfc \
    --enemy-id 0x40 \
    --output assets/enemies/minotaur/

# Output:
#   minotaur_tiles.bin (decompressed)
#   minotaur_palette.pal
#   minotaur_frame_00.png
#   minotaur_frame_01.png
#   ...
```

**All Enemies (Batch):**
```bash
# Extract all enemy sprites
python tools/graphics/extract_all_enemies.py \
    --rom roms/ffmq.sfc \
    --output assets/enemies/

# Creates directory per enemy with all frames
```

**Editing Enemy Sprites:**

**Workflow:**
```bash
# 1. Extract enemy
python tools/graphics/extract_enemy_sprite.py \
    --rom roms/ffmq.sfc \
    --enemy-id 0x40 \
    --output assets/enemies/minotaur/

# 2. Edit PNG files
# (Use your favorite image editor)

# 3. Convert back to tiles
python tools/graphics/png_to_enemy_sprite.py \
    --input-dir assets/enemies/minotaur/ \
    --output minotaur_tiles_new.bin

# 4. Compress tiles
python tools/graphics/compress_graphics.py \
    --input minotaur_tiles_new.bin \
    --output minotaur_compressed.bin \
    --format rle

# 5. Insert into ROM
python tools/rom-operations/insert_data.py \
    --rom build/ffmq.sfc \
    --address 0x0D8000 \
    --input minotaur_compressed.bin
```

**Animation Frames:**

**Frame Organization:**
```
Most enemies have multiple animation frames:
- Idle: 1-2 frames (breathing, floating)
- Attack: 2-4 frames (attack animation)
- Damage: 1 frame (hit reaction)
- Death: 2-3 frames (defeat animation)

Frames stored sequentially in tile data
Frame timing defined separately
```

**Frame Timing Data:**
```
Location: After compressed tile data
Format: 1 byte per frame = duration in frames (60 fps)

Example (Minotaur):
Frame 0: 30 (0.5 seconds)
Frame 1: 10 (0.17 seconds)
Frame 2: 10
Frame 3: 10
Frame 4: 30 (0.5 seconds)
```

---

### Workflows & Processes

#### [`GRAPHICS_NEXT_STEPS.md`](GRAPHICS_NEXT_STEPS.md) 🚀 Next Steps
*Planned graphics work and future improvements*

**Contents:**
- Planned extraction work
- Tool improvements
- Documentation needs
- Known issues

**Use when:**
- Planning graphics work
- Understanding project roadmap
- Contributing to graphics tools

**Planned Work:**

**High Priority:**
- ⏳ Complete background tile extraction
- ⏳ Document tile arrangement for maps
- ⏳ Create tileset editor tool
- ⏳ Improve compression tool performance
- ⏳ Add batch palette editing

**Medium Priority:**
- 📋 Create graphics modification tutorials
- 📋 Document unused graphics
- 📋 Build graphics asset browser
- 📋 Add animation preview tool
- 📋 Create palette optimization tool

**Low Priority:**
- 💭 Research custom compression
- 💭 Implement LZ77 compression
- 💭 Create graphics format converter
- 💭 Build web-based graphics viewer

---

#### [`GRAPHICS_PIPELINE_STATUS.md`](GRAPHICS_PIPELINE_STATUS.md) 📊 Pipeline Status
*Status of graphics extraction and processing pipeline*

**Contents:**
- Pipeline stage status
- Completion percentages
- Blockers and issues
- Recent completions

**Use when:**
- Checking pipeline progress
- Understanding what's complete
- Identifying blockers

---

#### [`PALETTE_EXTRACTION_SUMMARY.md`](PALETTE_EXTRACTION_SUMMARY.md) 🎨 Palette Summary
*Summary of palette extraction work*

**Contents:**
- Extracted palette catalog
- Palette locations in ROM
- Palette usage documentation
- Color scheme analysis

**Use when:**
- Finding palette locations
- Understanding color usage
- Planning palette modifications

---

### Reference & Catalogs

#### [`GRAPHICS_README.md`](GRAPHICS_README.md) 📖 Graphics Quick Reference
*Quick reference for graphics system*

**Contents:**
- Quick format reference
- Common addresses
- Tool quick reference
- FAQ

**Use when:**
- Need quick format reminder
- Looking up addresses
- Quick tool usage

---

#### [`graphics-quickstart.md`](graphics-quickstart.md) ⚡ Quick Start Guide
*Get started with graphics quickly*

**Contents:**
- 5-minute extraction guide
- Common workflows
- Essential commands
- Troubleshooting basics

**Use when:**
- First time working with graphics
- Need quick workflow
- Learning the tools

---

#### [`graphics_catalog/`](graphics_catalog/) 🖼️ Visual Catalog
*Visual catalog of all extracted graphics*

**Contents:**
- `index.html` - Main catalog page
- `characters_catalog.png` - All character sprites
- `enemies_catalog.png` - All enemy sprites
- `ui_catalog.png` - All UI elements
- `palettes_catalog.png` - All palettes visualized

**Use when:**
- Browsing available graphics
- Finding specific sprite
- Visual reference

**Viewing the Catalog:**
```bash
# Windows
start docs/graphics/graphics_catalog/index.html

# Linux
xdg-open docs/graphics/graphics_catalog/index.html

# macOS
open docs/graphics/graphics_catalog/index.html
```

---

## Common Workflows

### Extract and Edit Enemy Sprite

```bash
# 1. Extract enemy
python tools/graphics/extract_enemy_sprite.py \
    --rom roms/ffmq.sfc \
    --enemy-id 0x40 \
    --output work/enemy_edit/

# 2. Edit PNGs in work/enemy_edit/
# (Use GIMP, Photoshop, etc.)

# 3. Convert back
python tools/graphics/png_to_snes.py \
    --input work/enemy_edit/frame_*.png \
    --output work/enemy_edit/new_tiles.bin \
    --palette work/enemy_edit/palette.pal

# 4. Compress
python tools/graphics/compress_graphics.py \
    --input work/enemy_edit/new_tiles.bin \
    --output work/enemy_edit/compressed.bin \
    --format rle

# 5. Build ROM with modifications
# (Update source to reference new data)
python tools/build/build_rom.py
```

### Create Palette Variation

```bash
# 1. Extract base palette
python tools/graphics/palette_editor.py extract \
    --rom roms/ffmq.sfc \
    --address 0x123456 \
    --output palettes/base.pal

# 2. Create variation
python tools/graphics/palette_editor.py edit \
    --palette palettes/base.pal \
    --output palettes/variation.pal

# 3. Preview with existing tiles
python tools/graphics/snes_graphics.py tile_to_png \
    --input assets/graphics/sprite.bin \
    --palette palettes/variation.pal \
    --output preview/sprite_variation.png

# 4. Apply to ROM
python tools/graphics/palette_editor.py apply \
    --palette palettes/variation.pal \
    --rom build/ffmq.sfc \
    --address 0x123456
```

### Batch Extract All Graphics

```bash
# Extract everything
python tools/graphics/extract_all_graphics.py \
    --rom roms/ffmq.sfc \
    --output assets/graphics/extracted/

# Organize by category
python tools/graphics/organize_extracted_graphics.py \
    --input assets/graphics/extracted/ \
    --output assets/graphics/organized/

# Generate catalog
python tools/graphics/generate_catalog.py \
    --input assets/graphics/organized/ \
    --output docs/graphics/graphics_catalog/
```

---

## Graphics Formats

### SNES 4bpp Tile Format

**Tile Size:** 8x8 pixels, 32 bytes  
**Color Depth:** 4 bits per pixel (16 colors)  
**Bitplane Organization:** 4 bitplanes, 8 bytes each

**Structure:**
```
Bytes 0-7:   Bitplane 0
Bytes 8-15:  Bitplane 1
Bytes 16-23: Bitplane 2
Bytes 24-31: Bitplane 3
```

### SNES Palette Format

**Palette Size:** 16 colors, 32 bytes  
**Color Format:** 15-bit RGB (5-5-5)  
**Byte Order:** Little-endian

**Format:**
```
Each color: 2 bytes (little-endian)
Bits: 0bbbbbgg gggrrrrr
      ↑      ↑      ↑
      Blue   Green  Red
```

### RLE Compression

**Control Byte:**
- < 0x80: Literal run (next N+1 bytes)
- >= 0x80: RLE run (next byte repeated N-128+1 times)

**Example:**
```
Compressed: 83 FF 01 AB
Decompressed: FF FF FF FF AB
```

---

## Troubleshooting

### Graphics Look Corrupted

**Problem:** Extracted graphics appear as garbage

**Solutions:**

1. **Check format (2bpp vs 4bpp):**
   ```bash
   # Try different format
   python tools/graphics/snes_graphics.py tile_to_png \
       --input graphics.bin \
       --format 2bpp  # or 4bpp
       --output test.png
   ```

2. **Check palette:**
   ```bash
   # Verify palette is correct
   python tools/graphics/palette_editor.py view \
       --palette palette.pal
   ```

3. **Check compression:**
   ```bash
   # Try decompressing first
   python tools/graphics/decompress_graphics.py \
       --input graphics.bin \
       --format rle \
       --output graphics_decompressed.bin
   ```

### Wrong Colors

**Problem:** Colors don't match game

**Solutions:**

1. **Verify palette address:**
   ```bash
   # Double-check palette location
   grep -r "palette_" src/ | grep address
   ```

2. **Check palette format:**
   ```python
   # Verify 15-bit SNES format
   python tools/graphics/verify_palette.py palette.pal
   ```

3. **Check byte order:**
   ```python
   # Ensure little-endian
   color = struct.unpack('<H', bytes)[0]
   ```

### Compression Fails

**Problem:** Can't decompress graphics

**Solutions:**

1. **Verify compression format:**
   ```bash
   # Detect compression type
   python tools/graphics/detect_compression.py graphics.bin
   ```

2. **Check data alignment:**
   ```bash
   # Ensure correct starting address
   python tools/rom-operations/find_data_start.py \
       --rom ffmq.sfc \
       --pattern graphics
   ```

### Tools Can't Find ROM

**Problem:** Tools report ROM not found

**Solutions:**

1. **Check ROM path:**
   ```bash
   # Verify ROM exists
   ls -l roms/ffmq.sfc
   
   # Use absolute path
   python tools/graphics/extract.py \
       --rom "C:\full\path\to\ffmq.sfc"
   ```

2. **Check ROM format:**
   ```bash
   # Verify ROM is valid SNES ROM
   python tools/rom-operations/verify_rom.py roms/ffmq.sfc
   ```

---

## Related Documentation

### Within This Directory

- **[GRAPHICS_SYSTEM.md](GRAPHICS_SYSTEM.md)** - Graphics system architecture
- **[GRAPHICS_EXTRACTION_GUIDE.md](GRAPHICS_EXTRACTION_GUIDE.md)** - Extraction guide
- **[ENEMY_SPRITES_COMPLETE.md](ENEMY_SPRITES_COMPLETE.md)** - Enemy sprite reference
- **[GRAPHICS_PALETTE_WORKFLOW.md](GRAPHICS_PALETTE_WORKFLOW.md)** - Palette editing
- **[graphics_catalog/index.html](graphics_catalog/index.html)** - Visual catalog

### Other Documentation

- **[../../tools/graphics/README.md](../../tools/graphics/README.md)** - Graphics tools
- **[../reference/DATA_STRUCTURES.md](../reference/DATA_STRUCTURES.md)** - Data structures
- **[../build/BUILD_GUIDE.md](../build/BUILD_GUIDE.md)** - Building ROM
- **[../rom-hacking/MODDING_GUIDE.md](../rom-hacking/MODDING_GUIDE.md)** - Modding guide

### External Resources

- **[SNES Dev Manual](https://snes.nesdev.org/)** - SNES hardware
- **[Super Famicom Development Wiki](https://wiki.superfamicom.org/)** - SNES development
- **[YY-CHR Documentation](http://www.geocities.jp/yy_6502/yychr/)** - Tile editor

---

## Contributing

When adding graphics documentation:

1. **Include visual examples** - Screenshots, diagrams
2. **Document addresses** - ROM locations, sizes
3. **Provide workflows** - Step-by-step processes
4. **Test procedures** - Verify instructions work
5. **Update catalog** - Add to visual catalog if applicable

---

**Last Updated:** 2025-11-07  
**Graphics Format:** SNES 4bpp  
**Extraction Status:** 90% Complete
