# ROM Hacking & Modding Documentation

This directory contains comprehensive guides for modding and hacking Final Fantasy Mystic Quest, including tutorials, technical references, and complete workflows for various modification types.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation Index](#documentation-index)
- [Common Modifications](#common-modifications)
- [Modding Workflows](#modding-workflows)
- [Technical Reference](#technical-reference)
- [Troubleshooting](#troubleshooting)
- [Related Documentation](#related-documentation)

---

## Overview

This documentation covers all aspects of FFMQ ROM hacking:

**Modification Categories:**
- **Graphics Modding** - Sprites, tiles, palettes
- **Text Editing** - Dialogue, menus, item names
- **Map Editing** - Layouts, events, NPCs
- **Battle Modding** - Enemy stats, AI, spells
- **Music Editing** - BGM, sound effects
- **Data Editing** - Items, equipment, stats
- **Code Modification** - Assembly hacking, new features

**Skill Levels:**
- 🟢 **Beginner** - No programming needed, use tools
- 🟡 **Intermediate** - Basic hex editing, data formats
- 🔴 **Advanced** - Assembly programming, reverse engineering

---

## Quick Start

### For Complete Beginners

**1. Read the Modding Guide:**
```bash
# Start here
docs/rom-hacking/MODDING_GUIDE.md
```

**2. Try a Simple Mod:**
```bash
# Change enemy HP (beginner-friendly)
python tools/battle/enemy_editor_gui.py
# Select enemy, change HP, save, test
```

**3. Test Your Mod:**
```bash
# Build ROM with changes
python tools/build/build_rom.py

# Open in emulator
build/ffmq.sfc
```

### For Intermediate Modders

**1. Extract Game Data:**
```bash
# Extract everything
python tools/data-extraction/extract_all.py --output extracted/
```

**2. Edit Data Files:**
```bash
# Edit JSON files in extracted/
# Use any text editor
```

**3. Rebuild ROM:**
```bash
# Insert modifications
python tools/build/build_rom.py --update-all
```

### For Advanced Hackers

**1. Study Disassembly:**
```bash
# Review source code
src/bank_*.asm
```

**2. Make Code Changes:**
```asm
; Edit assembly files
; Add new features
; Modify game logic
```

**3. Build and Test:**
```bash
# Assemble and test
python tools/build/build_rom.py
python tools/testing/run_all_tests.py
```

---

## Documentation Index

### [`MODDING_GUIDE.md`](MODDING_GUIDE.md) 📖 **START HERE**
*Complete modding guide for all skill levels*

**Contents:**
- Getting started with modding
- Required tools and setup
- Beginner tutorials (no programming)
- Intermediate techniques (hex editing)
- Advanced topics (assembly hacking)
- Best practices and tips
- Safety and backup strategies

**Use when:**
- Starting ROM hacking for first time
- Learning SNES modding
- Need comprehensive reference
- Teaching others to mod

**Skill Level Sections:**

**🟢 Beginner Section (No Programming Required):**

**Setting Up:**
```bash
# 1. Get tools
python tools/build/install_asar.py  # Assembler
# Install emulator (Mesen-S recommended)

# 2. Backup original ROM
cp roms/ffmq.sfc roms/ffmq_backup.sfc

# 3. Verify ROM
python tools/rom-operations/verify_rom.py roms/ffmq.sfc
```

**Simple Modifications:**

**Change Enemy Stats:**
```bash
# Launch enemy editor
python tools/battle/enemy_editor_gui.py

# GUI Steps:
# 1. Select enemy from list (e.g., "Goblin")
# 2. Change HP from 50 to 100
# 3. Change Attack from 30 to 40
# 4. Click "Save"
# 5. Click "Build ROM"
# 6. Test in emulator
```

**Change Item Prices:**
```python
# Use item editor
python tools/data-extraction/item_editor.py

# Steps:
# 1. Select item (e.g., "Cure Potion")
# 2. Change price from 20 to 10
# 3. Save changes
# 4. Build ROM
```

**Edit Text:**
```bash
# Extract dialogue
python tools/data-extraction/extract_text.py --output text/

# Edit text/dialogue.txt with notepad
# Example:
Old: "Welcome to Foresta!"
New: "Welcome, brave hero!"

# Re-insert text
python tools/data-extraction/insert_text.py --input text/

# Build ROM
python tools/build/build_rom.py
```

**Change Palettes:**
```bash
# Edit palette with GUI
python tools/graphics/palette_editor.py edit \
    --palette-id 5

# Steps:
# 1. Click color to edit
# 2. Choose new color
# 3. Preview changes
# 4. Save palette
# 5. Build ROM
```

**🟡 Intermediate Section (Hex Editing & Data Formats):**

**Understanding Data Formats:**

**Enemy Stat Structure (12 bytes per enemy):**
```
Offset  Size  Description           Example (Goblin)
------  ----  -----------           ----------------
0x00    2     HP (little-endian)    0x0032 (50 HP)
0x02    1     Attack                0x1E (30)
0x03    1     Defense               0x14 (20)
0x04    1     Magic                 0x0A (10)
0x05    1     Magic Defense         0x0F (15)
0x06    1     Agility               0x19 (25)
0x07    1     Element Flags         0x01 (weak to fire)
0x08    2     EXP (little-endian)   0x000F (15)
0x0A    2     Gold (little-endian)  0x000A (10)
```

**Hex Editing Example:**
```bash
# Open ROM in hex editor
HxD.exe build/ffmq.sfc

# Navigate to enemy data (Bank $02)
# Address: 0x012345 (Goblin stats)

# Change HP from 50 (0x0032) to 100 (0x0064):
Offset 0x012345: 32 00  →  64 00
                 ↑         ↑
                 Old HP    New HP (little-endian)

# Change Attack from 30 (0x1E) to 50 (0x32):
Offset 0x012347: 1E  →  32
                 ↑       ↑
                 Old     New
```

**Data Formats:**

**Little-Endian 16-bit Values:**
```
Value: 1000 (0x03E8)
Bytes: E8 03 (low byte first)

Reading: 0x03E8 = (0x03 << 8) | 0xE8 = 768 + 232 = 1000

Writing 2000 (0x07D0):
Bytes: D0 07
```

**Bit Flags:**
```
Elemental Weakness Byte:
Bit 0: Fire
Bit 1: Ice
Bit 2: Thunder
Bit 3: Earth
Bit 4-7: Unused

Example: 0x05 = 0b00000101 = Fire + Thunder weakness
```

**Pointer Tables:**
```
Table of pointers to text strings:
Address  Value     Points To
-------  -----     ---------
0x08000  0x8100    First string at 0x8100
0x08002  0x8150    Second string at 0x8150
0x08004  0x81A0    Third string at 0x81A0

Pointer format: SNES LoROM address
- Bank byte implied or separate
- 16-bit offset within bank
```

**🔴 Advanced Section (Assembly Hacking):**

**Reading Assembly Code:**

**Example Function (Enemy AI):**
```asm
; Enemy Attack Decision
; Input: A = enemy ID
; Output: A = chosen attack ID
EnemyAI_ChooseAttack:
    ; Store enemy ID
    STA $7E0200             ; Current enemy ID
    
    ; Load enemy AI script pointer
    ASL A                   ; ID × 2 (pointers are 2 bytes)
    TAX                     ; Use as index
    LDA.l AIScriptTable,X   ; Load script pointer
    STA $00                 ; Store in zero page
    LDA.l AIScriptTable+1,X
    STA $01
    
    ; Execute AI script
    JSR ($0000)             ; Call AI function
    
    ; Return attack ID in A
    RTS

; AI Script Table
AIScriptTable:
    .dw AIScript_Goblin     ; 0x00: Goblin
    .dw AIScript_Snake      ; 0x01: Snake
    .dw AIScript_Bee        ; 0x02: Bee
    ; ... more entries
```

**Modifying Game Logic:**

**Example: Double All Damage:**
```asm
; Original damage application code
ApplyDamage:
    LDA DamageAmount        ; Load calculated damage
    STA $7E0100             ; Store for processing
    ; ... rest of function

; Modified: Double damage
ApplyDamage:
    LDA DamageAmount        ; Load calculated damage
    ASL A                   ; Multiply by 2 (shift left)
    STA $7E0100             ; Store doubled damage
    ; ... rest of function
```

**Adding New Features:**

**Example: Critical Hit System Enhancement:**
```asm
; Original: 1/16 critical chance
CheckCritical:
    JSR GetRandom           ; Get random 0-255
    AND #$0F                ; Mask to 0-15
    BNE .not_critical       ; If not 0, no critical
    ; ... critical hit code

; Modified: Critical based on agility
CheckCritical:
    ; Load attacker agility
    LDX AttackerIndex
    LDA CharacterAgility,X
    
    ; Critical chance = Agility / 8
    LSR A                   ; Divide by 8
    LSR A
    LSR A
    STA Temp.CritChance     ; Store threshold
    
    ; Roll random
    JSR GetRandom
    AND #$1F                ; 0-31 range
    CMP Temp.CritChance     ; Compare with threshold
    BCS .not_critical       ; If >= threshold, no crit
    
    ; Critical hit!
    ; ... critical hit code

.not_critical:
    RTS
```

**Free Space Finding:**
```bash
# Find free space in ROM
python tools/rom-operations/find_free_space.py \
    --rom build/ffmq.sfc \
    --min-size 0x1000

# Output:
# Found free space:
# Bank $0F: 0x0F8000-0x0FFFFF (32KB)
# Bank $1E: 0x1E0000-0x1EFFFF (64KB)
```

**Inserting Custom Code:**
```asm
; New code in free space (Bank $0F, 0x0F8000)
org $0F8000

CustomCriticalSystem:
    ; Save registers
    PHA
    PHX
    
    ; Your custom code here
    LDX AttackerIndex
    LDA CharacterAgility,X
    ; ... logic
    
    ; Restore registers
    PLX
    PLA
    RTS

; Hook original code
org $028456  ; Original CheckCritical location
    JML CustomCriticalSystem  ; Jump to custom code
    NOP
    NOP
```

---

### [`TEXT_EDITING.md`](TEXT_EDITING.md) 💬 Text Editing Guide
*Complete guide to editing game text*

**Contents:**
- Text encoding system
- Text extraction
- Editing dialogue
- Control codes
- Text re-insertion
- Variable-width font

**Use when:**
- Translating game
- Changing dialogue
- Fixing text bugs
- Adding custom text

**Text System Architecture:**

**Text Storage:**
```
Location: Bank $08-$09
Format: Compressed text strings
Encoding: Custom SNES character set
Compression: Dictionary-based

String format:
- Control codes (0x00-0x1F)
- Character data (0x20-0xFF)
- String terminator (0xFF)
```

**Character Encoding:**
```
Character Map (partial):
0x20: Space
0x21-0x3A: ! " # $ % & ' ( ) * + , - . / 0-9
0x41-0x5A: A-Z
0x61-0x7A: a-z
0x80-0x9F: Special characters
0xA0-0xFF: Japanese characters (original) / Extended (hack)
```

**Control Codes:**
```
Code  Description
----  -----------
0x00  End of string
0x01  Newline
0x02  Wait for button press
0x03  Clear text box
0x04  Character name (auto-insert)
0x05  Item name (parameter follows)
0x06  Number (parameter follows)
0x07  Pause (parameter = frames)
0x08  Speed change (parameter = delay)
0x09  Color change (parameter = color)
0x0A  SFX (parameter = sound ID)
```

**Extraction Workflow:**

**Step 1: Extract Text:**
```bash
# Extract all text strings
python tools/data-extraction/extract_text.py \
    --rom roms/ffmq.sfc \
    --output text/extracted/

# Output files:
# text/extracted/dialogue.txt     (NPC dialogue)
# text/extracted/menus.txt        (Menu text)
# text/extracted/items.txt        (Item names/descriptions)
# text/extracted/battles.txt      (Battle text)
```

**Step 2: Edit Text:**

**Text File Format:**
```
# dialogue.txt

[STRING_001]
<en>Welcome to Foresta!</en>
<jp>フォレスタへようこそ!</jp>

[STRING_002]
<en>Benjamin, you must find\n<02>the Crystal!</en>
<jp>ベンジャミン、クリスタルを\n<02>見つけてください!</jp>

[STRING_003]
<en>Take this <05:CURE_POTION>.</en>
<jp>この<05:CURE_POTION>を持って行け。</jp>
```

**Control Code Usage:**
```
\n or <01>    - New line
<02>          - Wait for button
<03>          - Clear text box
<04>          - Insert character name
<05:item_id>  - Insert item name
<06:number>   - Insert number
<07:frames>   - Pause
```

**Editing Examples:**
```
# Simple change
Old: "Hello, traveler!"
New: "Greetings, hero!"

# Multi-line dialogue
New: "Welcome to the shop!\nWhat can I get you?"
# \n creates new line

# Using control codes
New: "You received <05:CURE_POTION>!\n<02>HP restored!"
# <02> = wait for button before continuing

# Character name insertion
New: "<04>, you must save\nthe world!"
# <04> = automatically insert player name
```

**Step 3: Validate Text:**
```bash
# Check for errors
python tools/data-extraction/validate_text.py \
    --input text/extracted/dialogue.txt

# Checks:
# - String length limits
# - Valid control codes
# - Proper encoding
# - Missing translations
```

**Step 4: Re-insert Text:**
```bash
# Insert modified text
python tools/data-extraction/insert_text.py \
    --input text/extracted/ \
    --rom build/ffmq.sfc

# Compress and insert all text strings
# Updates pointers automatically
```

**Text Length Limits:**

**Dialogue Text:**
```
Max characters per line: 32
Max lines per box: 3
Total limit: ~96 characters per dialogue box

Line overflow handled automatically:
- Long strings auto-wrap
- Use <02> to manually control pacing
```

**Item Names:**
```
Max length: 16 characters
Encoding: Single-byte characters only
Padding: Space-padded to 16 bytes
```

**Menu Text:**
```
Fixed positions, strict limits:
Menu item: 16 characters
Description: 64 characters
```

**Variable-Width Font:**

**Font Data:**
```
Location: Bank $0E, 0x0E2000
Format: 1bpp (2-color) characters
Size: 8×8 pixels per character

Width table:
- Each character has defined width (3-8 pixels)
- Stored separately from glyph data
- Used for proportional spacing
```

**Adding Custom Characters:**
```bash
# Edit font graphics
python tools/graphics/font_editor.py \
    --rom build/ffmq.sfc \
    --output font/

# Edit font/ directory:
# - character_XX.png (glyph image)
# - widths.txt (character widths)

# Re-insert font
python tools/graphics/insert_font.py \
    --input font/ \
    --rom build/ffmq.sfc
```

---

### [`MAP_EDITING.md`](MAP_EDITING.md) 🗺️ Map Editing Guide
*Complete guide to editing maps and events*

**Contents:**
- Map data structure
- Tile editing
- Event scripting
- NPC placement
- Collision data
- Warp points

**Use when:**
- Designing new maps
- Modifying existing areas
- Adding NPCs
- Creating events

**Map System Architecture:**

**Map Storage:**
```
Maps stored in: Bank $03, $07
Format: Compressed tilemap data
Size: Variable (compressed)
Tile Size: 8×8 pixels
Map Dimensions: Up to 64×64 tiles

Map components:
1. Tilemap data (which tiles where)
2. Collision data (walkable/blocked)
3. Event data (NPCs, chests, warps)
4. Layer data (background/foreground)
```

**Map Data Structure:**
```
Map Header (16 bytes):
Offset  Size  Description
------  ----  -----------
0x00    2     Map ID
0x02    2     Width (in tiles)
0x04    2     Height (in tiles)
0x06    2     Tileset ID
0x08    2     Palette ID
0x0A    2     Collision data pointer
0x0C    2     Event data pointer
0x0E    2     Music ID

Followed by compressed tilemap data
```

**Extraction:**
```bash
# Extract all maps
python tools/data-extraction/extract_maps.py \
    --rom roms/ffmq.sfc \
    --output maps/

# Output:
# maps/
#   foresta_town/
#     tilemap.bin       (raw tile data)
#     tilemap.png       (visual preview)
#     collision.bin     (collision data)
#     events.json       (event definitions)
#     metadata.json     (map properties)
```

**Editing Workflow:**

**Step 1: Extract Map:**
```bash
python tools/data-extraction/extract_map.py \
    --map-id 0x05 \
    --output maps/foresta_town/
```

**Step 2: Edit Tilemap:**

**Option A: Visual Editor:**
```bash
# Launch map editor
python tools/data-extraction/map_editor.py \
    --map maps/foresta_town/

# Editor features:
# - Visual tile placement
# - Tileset browser
# - Collision editing
# - Event placement
# - Real-time preview
```

**Option B: Manual Editing:**
```
# Edit tilemap.png in image editor
# Each pixel = one tile
# Pixel color = tile ID from tileset
# Save and convert back to binary
```

**Step 3: Edit Events:**

**Event JSON Format:**
```json
{
  "events": [
    {
      "type": "npc",
      "id": 1,
      "x": 15,
      "y": 10,
      "sprite_id": 5,
      "direction": "down",
      "dialogue": "STRING_042",
      "script": "npc_shopkeeper"
    },
    {
      "type": "chest",
      "id": 2,
      "x": 30,
      "y": 8,
      "item_id": 12,
      "item_count": 1,
      "once": true
    },
    {
      "type": "warp",
      "id": 3,
      "x": 32,
      "y": 0,
      "dest_map": 0x06,
      "dest_x": 16,
      "dest_y": 30
    },
    {
      "type": "trigger",
      "id": 4,
      "x": 20,
      "y": 20,
      "width": 3,
      "height": 3,
      "script": "boss_battle_trigger",
      "once": true
    }
  ]
}
```

**Event Types:**

**NPC Event:**
```json
{
  "type": "npc",
  "x": 15, "y": 10,           // Position
  "sprite_id": 5,             // Which sprite to display
  "direction": "down",        // Facing direction
  "movement": "none",         // Movement pattern
  "dialogue": "STRING_042",   // Dialogue string ID
  "script": "npc_shopkeeper"  // Event script
}
```

**Chest Event:**
```json
{
  "type": "chest",
  "x": 30, "y": 8,
  "item_id": 12,              // Item to give
  "item_count": 1,            // Quantity
  "once": true,               // Can only open once
  "flag": 0x0042              // Game flag to set
}
```

**Warp Point:**
```json
{
  "type": "warp",
  "x": 32, "y": 0,            // Trigger position
  "dest_map": 0x06,           // Destination map ID
  "dest_x": 16,               // Destination X
  "dest_y": 30,               // Destination Y
  "animation": "fade"         // Transition effect
}
```

**Step 4: Edit Collision:**
```bash
# Edit collision visually
python tools/data-extraction/collision_editor.py \
    --map maps/foresta_town/

# Or edit collision.bin directly:
# Each byte = one tile's collision
# 0x00 = walkable
# 0x01 = blocked
# 0x02 = water
# 0x03 = warp trigger
```

**Step 5: Re-insert Map:**
```bash
# Compress and insert map
python tools/data-extraction/insert_map.py \
    --map maps/foresta_town/ \
    --map-id 0x05 \
    --rom build/ffmq.sfc
```

**Map Scripting:**

**Event Scripts (Assembly):**
```asm
; NPC shopkeeper script
npc_shopkeeper:
    JSR ShowDialogue        ; Show greeting
    JSR OpenShopMenu        ; Show shop menu
    
    ; Check if player made purchase
    LDA ShopResult
    BEQ .no_purchase
    
    ; Thank you message
    LDA #STRING_THANKS
    JSR ShowDialogue
    
.no_purchase:
    RTS

; Boss battle trigger
boss_battle_trigger:
    ; Check if already defeated
    LDA GameFlags
    AND #FLAG_BOSS_01_DEFEATED
    BNE .skip                ; Skip if already done
    
    ; Play cutscene
    JSR Cutscene_BossAppears
    
    ; Start battle
    LDA #ENEMY_BOSS_01
    JSR InitBattle
    
    ; Set flag after victory
    LDA GameFlags
    ORA #FLAG_BOSS_01_DEFEATED
    STA GameFlags
    
.skip:
    RTS
```

---

### [`DATA_EXTRACTION.md`](DATA_EXTRACTION.md) 📦 Data Extraction Guide
*Complete guide to extracting all game data*

**Contents:**
- Extraction tool usage
- Data formats
- Organizing extracted data
- Batch extraction
- Data cataloging

**Use when:**
- Starting major mod project
- Analyzing game data
- Creating documentation
- Building tools

**Complete Extraction Workflow:**

**Extract Everything:**
```bash
# One command to extract all data
python tools/data-extraction/extract_all.py \
    --rom roms/ffmq.sfc \
    --output extracted/

# Creates organized directory structure:
extracted/
  graphics/
    enemies/
    characters/
    ui/
    backgrounds/
  text/
    dialogue.json
    menus.json
    items.json
  maps/
    map_00/
    map_01/
    ...
  battle/
    enemies.json
    spells.json
    ai_scripts/
  music/
    tracks/
    sound_effects/
  data/
    items.json
    equipment.json
    characters.json
```

**Selective Extraction:**
```bash
# Extract only graphics
python tools/data-extraction/extract_all.py --graphics-only

# Extract only battle data
python tools/data-extraction/extract_all.py --battle-only

# Extract specific categories
python tools/data-extraction/extract_all.py \
    --categories graphics,text,maps
```

---

### [`EXTRACTION_COMPLETE.md`](EXTRACTION_COMPLETE.md) ✅ Extraction Status
*Status of complete data extraction*

**Contents:**
- Extraction completion status
- Extracted data catalog
- Known gaps
- Validation results

**Use when:**
- Checking what's been extracted
- Finding specific data
- Identifying missing data

---

### [`ROM_DATA_MAP.md`](ROM_DATA_MAP.md) 🗺️ ROM Data Map
*Complete map of ROM data locations*

**Contents:**
- Bank-by-bank data locations
- Important addresses
- Data structure offsets
- Pointer tables

**Use when:**
- Finding data in ROM
- Hex editing
- Understanding ROM organization

**ROM Organization:**

**Bank Map:**
```
Bank  Address Range   Description
----  -------------   -----------
$00   $008000-$00FFFF System code, initialization
$01   $018000-$01FFFF Graphics DMA, PPU code
$02   $028000-$02FFFF Game logic, battle system
$03   $038000-$03FFFF Map data
$04   $048000-$04FFFF Item/equipment data
$05   $058000-$05FFFF Enemy/battle data
$06   $068000-$06FFFF Event scripts
$07   $078000-$07FFFF More map data
$08   $088000-$08FFFF Text data (compressed)
$09   $098000-$09FFFF More text data
$0A   $0A8000-$0AFFFF Music/sound
$0B   $0B8000-$0BFFFF Sound data
$0C   $0C8000-$0CFFFF Character graphics
$0D   $0D8000-$0DFFFF Enemy graphics
$0E   $0E8000-$0EFFFF UI graphics
$0F   $0F8000-$0FFFFF Background graphics
```

**Important Addresses:**

**Enemy Data:**
```
Base Address: 0x028000 (Bank $02)
Entry Size: 12 bytes
Count: 128 enemies
Total Size: 1536 bytes (0x600)

Enemy 0x00 (Goblin):    0x028000-0x02800B
Enemy 0x01 (Snake):     0x02800C-0x028017
Enemy 0x40 (Minotaur):  0x028480-0x02848B
...
```

**Item Data:**
```
Base Address: 0x048000 (Bank $04)
Entry Size: 8 bytes
Count: 256 items
Total Size: 2048 bytes (0x800)

Item structure:
+0: Type (consumable, equipment, etc.)
+1: Power/Effect
+2: Buy price (low byte)
+3: Buy price (high byte)
+4: Sell price (low byte)
+5: Sell price (high byte)
+6: Icon ID
+7: Flags
```

---

### [`ROM_PIPELINE_PLAN.md`](ROM_PIPELINE_PLAN.md) 🔄 ROM Pipeline Plan
*Plan for ROM modification pipeline*

**Contents:**
- Planned pipeline features
- Automation workflows
- Tool integration
- Future improvements

**Use when:**
- Planning large mods
- Understanding workflow
- Contributing to tools

---

## Common Modifications

### Change Enemy Stats
```bash
python tools/battle/enemy_editor_gui.py --enemy-id 0x40
# Modify stats in GUI, save, build ROM
```

### Edit Dialogue
```bash
python tools/data-extraction/extract_text.py --output text/
# Edit text/dialogue.txt
python tools/data-extraction/insert_text.py --input text/
python tools/build/build_rom.py
```

### Replace Graphics
```bash
# Extract graphics
python tools/graphics/extract_graphics_v2.py --enemy-id 0x40 --output work/

# Edit work/*.png in image editor

# Convert back and insert
python tools/graphics/insert_graphics.py --input work/ --enemy-id 0x40
python tools/build/build_rom.py
```

### Create Custom Map
```bash
python tools/data-extraction/map_editor.py --new --map-id 0xFF
# Design map in editor
# Save and build ROM
```

### Modify Item Effects
```bash
python tools/data-extraction/item_editor.py
# Edit item properties
# Save and build ROM
```

---

## Modding Workflows

### Complete Gameplay Overhaul

**Planning:**
1. Document all planned changes
2. Create backup of original ROM
3. Set up version control

**Execution:**
```bash
# 1. Extract all data
python tools/data-extraction/extract_all.py --output mod/

# 2. Make changes to extracted data
# Edit JSON files, graphics, etc.

# 3. Validate changes
python tools/testing/validate_mod_data.py --input mod/

# 4. Build ROM
python tools/build/build_rom.py --mod-dir mod/

# 5. Test thoroughly
python tools/testing/run_all_tests.py
# Manual playtesting
```

### Graphics Romhack

```bash
# Extract graphics
python tools/graphics/extract_all_graphics.py

# Replace with new graphics
# (maintain format and dimensions)

# Insert graphics
python tools/graphics/insert_all_graphics.py

# Build and test
python tools/build/build_rom.py
```

### Translation Project

```bash
# Extract text
python tools/data-extraction/extract_text.py --output translation/

# Translate all text files
# translation/dialogue.txt
# translation/menus.txt
# etc.

# Validate translations
python tools/data-extraction/validate_translation.py

# Insert translated text
python tools/data-extraction/insert_text.py --input translation/

# Test in-game
python tools/build/build_rom.py
```

---

## Technical Reference

### SNES Memory Map
```
$000000-$7FFFFF: ROM (LoROM)
$800000-$FFFFFF: ROM mirror
$7E0000-$7FFFFF: RAM (128KB)
$0000-$1FFF: Low RAM / Zero Page
$2000-$7FFF: PPU registers / Cart RAM
```

### Data Formats

**Little-Endian 16-bit:**
```
Value: 0x1234
Bytes: 34 12 (low byte first)
```

**Compressed Data:**
```
RLE compression used for:
- Graphics data
- Some map data

LZ77-style compression for:
- Text data
```

**Pointer Tables:**
```
Format: 16-bit pointers (SNES address)
Often bank byte separate or implied
```

---

## Troubleshooting

### ROM Won't Build

1. Check for syntax errors in modified files
2. Verify all required data files present
3. Check for data size overruns
4. Review build log for specific errors

### Changes Don't Appear

1. Ensure ROM actually rebuilt
2. Check if modified correct version
3. Verify changes saved before build
4. Clear emulator save states

### Game Crashes

1. Check modified data is valid format
2. Verify pointers updated correctly
3. Test smaller changes incrementally
4. Use emulator debugger to find crash point

---

## Related Documentation

- **[../../tools/data-extraction/README.md](../../tools/data-extraction/README.md)** - Extraction tools
- **[../graphics/README.md](../graphics/README.md)** - Graphics system
- **[../battle/README.md](../battle/README.md)** - Battle system
- **[../build/README.md](../build/README.md)** - Building ROMs

---

**Last Updated:** 2025-11-07  
**Difficulty Levels:** 🟢 Beginner | 🟡 Intermediate | 🔴 Advanced
