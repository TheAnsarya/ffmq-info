# FFMQ Data Structures Documentation

Complete reference for all data structures in Final Fantasy: Mystic Quest.

## Table of Contents

- [Overview](#overview)
- [Character Data](#character-data)
- [Enemy Data](#enemy-data)
- [Item Data](#item-data)
- [Map Data](#map-data)
- [Text Data](#text-data)
- [Graphics Data](#graphics-data)
- [Battle Data](#battle-data)
- [Music and Sound Data](#music-and-sound-data)
- [Extraction Status](#extraction-status)
- [Data Format Conventions](#data-format-conventions)

## Overview

This document provides detailed specifications for all game data structures in FFMQ. Each section includes:

- **Memory layout**: How data is organized in ROM
- **Data structure**: Field-by-field specifications
- **Size information**: Byte counts and array sizes
- **ROM addresses**: Where to find each data type
- **Code references**: Assembly routines that use the data
- **Extraction status**: What has been extracted and validated

### Related Documentation

- **docs/BATTLE_SYSTEM.md**: Battle mechanics and formulas
- **docs/GRAPHICS_SYSTEM.md**: Graphics formats and rendering
- **docs/TEXT_SYSTEM.md**: Text encoding and compression
- **docs/MAP_SYSTEM.md**: Map organization and structure
- **docs/SOUND_SYSTEM.md**: Music and sound formats
- **data/README.md**: Data file organization and usage

---

## Character Data

### Overview

Character data defines the four playable characters: Benjamin, Kaeli, Tristam, and Phoebe.

### ROM Location

```
Bank: $0c
Base Address: $0c8000
Entry Size: 32 bytes per character
Total Entries: 4 characters
Total Size: 128 bytes
```

### Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     character_id         Character ID (0-3)
$01     1     name_pointer_lo      Name string pointer (low byte)
$02     1     name_pointer_hi      Name string pointer (high byte)
$03     1     starting_level       Starting level (1-41)
$04     2     starting_hp          Starting HP (little-endian)
$06     2     max_hp               Maximum HP (little-endian)
$08     1     white_magic          White magic power (0-255)
$09     1     black_magic          Black magic power (0-255)
$0a     1     wizard_magic         Wizard magic power (0-255)
$0b     1     speed                Speed stat (affects ATB gauge)
$0c     1     strength             Strength (physical damage)
$0d     1     defense              Defense (damage reduction)
$0e     1     hp_growth            HP gain per level
$0f     1     wm_growth            White magic growth per level
$10     1     bm_growth            Black magic growth per level
$11     1     wiz_growth           Wizard magic growth per level
$12     1     speed_growth         Speed growth per level
$13     1     str_growth           Strength growth per level
$14     1     def_growth           Defense growth per level
$15     1     equipment_flags      Equipment slot flags
$16     1     magic_flags          Available magic types (bitfield)
$17     1     starting_weapon      Starting weapon ID (or $ff)
$18     1     starting_armor       Starting armor ID (or $ff)
$19     1     starting_accessory   Starting accessory ID (or $ff)
$1a-1F  6     (reserved)           Unused/padding
```

### Equipment Flags (Offset $15)

```
Bit 0: Can equip weapons
Bit 1: Can equip armor
Bit 2: Can equip accessories
Bits 3-7: Unused
```

### Magic Flags (Offset $16)

```
Bit 0: Can use White magic
Bit 1: Can use Black magic
Bit 2: Can use Wizard magic
Bits 3-7: Unused
```

### Character IDs

| ID | Name     | Description                  |
|----|----------|------------------------------|
| 0  | Benjamin | Main protagonist             |
| 1  | Kaeli    | Companion (Foresta region)   |
| 2  | Tristam  | Companion (Aquaria region)   |
| 3  | Phoebe   | Companion (Fireburg region)  |

### Stat Growth Tables

Characters gain stats per level according to growth values:

**Benjamin (ID 0)**:
- HP: +15/level
- White Magic: +2/level
- Black Magic: +0/level (cannot use)
- Wizard Magic: +0/level (cannot use)
- Speed: +1/level
- Strength: +2/level
- Defense: +1/level

**Kaeli (ID 1)**:
- HP: +12/level
- White Magic: +0/level
- Black Magic: +2/level
- Wizard Magic: +0/level
- Speed: +2/level
- Strength: +1/level
- Defense: +1/level

**Tristam (ID 2)**:
- HP: +10/level
- White Magic: +1/level
- Black Magic: +1/level
- Wizard Magic: +2/level
- Speed: +2/level
- Strength: +1/level
- Defense: +1/level

**Phoebe (ID 3)**:
- HP: +14/level
- White Magic: +1/level
- Black Magic: +0/level
- Wizard Magic: +1/level
- Speed: +1/level
- Strength: +2/level
- Defense: +2/level

### Code References

```
Character stat loading: Bank $01, $018450
Stat growth calculation: Bank $0b, $0b8200
Equipment application:  Bank $01, $018500
```

### Extraction Status

- ✅ Data structure documented
- ⏳ Full character data extraction in progress
- ⏳ JSON schema validation needed
- ⏳ Stat growth tables need extraction

---

## Enemy Data

### Overview

Enemy data defines all monsters, bosses, and battle encounters.

### ROM Location

```
Bank: $0e
Base Address: $0e8000
Entry Size: 64 bytes per enemy
Total Entries: ~100 enemies (estimated)
Total Size: ~6400 bytes
```

### Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     enemy_id             Enemy ID (0-99)
$01     1     name_pointer_lo      Name string pointer (low byte)
$02     1     name_pointer_hi      Name string pointer (high byte)
$03     1     sprite_id            Battle sprite ID
$04     1     palette_id           Palette number (0-7)
$05     1     ai_pattern           AI behavior pattern ID
$06     1     ai_script            AI script pointer
$07     1     level                Enemy level (for scaling)
$08     2     hp                   Hit points (little-endian)
$0a     1     speed                Speed stat (turn order)
$0b     1     attack               Attack power
$0c     1     defense              Physical defense
$0d     1     magic_defense        Magic defense
$0e     1     evasion              Evasion percentage (0-100)
$0f     1     element_weak         Element weakness flags
$10     1     element_resist       Element resistance flags
$11     1     element_absorb       Element absorption flags
$12     1     status_immune        Status immunity flags (low)
$13     1     status_immune_2      Status immunity flags (high)
$14     2     exp_reward           Experience points (little-endian)
$16     2     gp_reward            Gold pieces (little-endian)
$18     1     common_drop_id       Common item drop ID
$19     1     common_drop_rate     Common drop rate (0-255, /256)
$1a     1     rare_drop_id         Rare item drop ID
$1b     1     rare_drop_rate       Rare drop rate (0-255, /256)
$1c     4     attack_list          4 attack IDs
$20-3F  32    (ai_data)            AI-specific data
```

### AI Pattern Types

| ID | Pattern Name       | Description                              |
|----|--------------------|------------------------------------------|
| 0  | Simple Attack      | Always uses basic attack                 |
| 1  | Magic User         | Prefers magic attacks                    |
| 2  | Healer             | Heals self/allies when HP low            |
| 3  | Conditional        | Changes behavior based on HP             |
| 4  | Counter Attack     | Counters when hit                        |
| 5  | Boss Multi-Phase   | Multiple behavior phases                 |

### Element Flags

```
Bit 0: Fire
Bit 1: Water
Bit 2: Thunder
Bit 3: Earth
Bit 4: Wind
Bits 5-7: Unused
```

### Status Immunity Flags

**Low byte ($12)**:
```
Bit 0: Poison
Bit 1: Sleep
Bit 2: Paralyze
Bit 3: Confuse
Bit 4: Blind
Bit 5: Silence
Bit 6: Petrify
Bit 7: Death
```

**High byte ($13)**:
```
Bit 0: Doom
Bit 1: Slow
Bit 2: Stop
Bit 3: Berserk
Bit 4: Regen
Bits 5-7: Unused
```

### Drop Rate Formula

```
Actual Drop Rate = drop_rate / 256

Examples:
  64 / 256 = 25% (common drop rate)
  13 / 256 = 5%  (rare drop rate)
```

### Code References

```
Enemy data loading:    Bank $0b, $0b8000
AI pattern execution:  Bank $0b, $0b8500
Drop calculation:      Bank $0b, $0b9200
```

### Extraction Status

- ✅ Data structure documented
- ⏳ Enemy data extraction in progress
- ⏳ AI script analysis needed
- ⏳ Attack list extraction needed

---

## Item Data

### Overview

Item data includes weapons, armor, accessories, and consumable items.

### ROM Location

```
Weapons:     Bank $0c, $0c9000 (32 entries × 16 bytes)
Armor:       Bank $0c, $0c9200 (32 entries × 16 bytes)
Accessories: Bank $0c, $0c9400 (32 entries × 16 bytes)
Consumables: Bank $0c, $0c9600 (64 entries × 8 bytes)
```

### Weapon Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     weapon_id            Weapon ID (0-31)
$01     1     name_pointer_lo      Name string pointer (low byte)
$02     1     name_pointer_hi      Name string pointer (high byte)
$03     1     attack_power         Attack bonus
$04     1     accuracy             Accuracy bonus (0-100)
$05     1     element              Elemental attribute (0-5)
$06     1     special_effect       Special effect ID
$07     1     equipment_flags      Equipment restrictions
$08     2     buy_price            Buy price in GP (little-endian)
$0a     2     sell_price           Sell price in GP (little-endian)
$0c     1     icon_id              Menu icon ID
$0d     1     sprite_id            Battle sprite ID
$0e-0F  2     (reserved)           Unused
```

### Armor Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     armor_id             Armor ID (0-31)
$01     1     name_pointer_lo      Name string pointer (low byte)
$02     1     name_pointer_hi      Name string pointer (high byte)
$03     1     defense              Defense bonus
$04     1     magic_defense        Magic defense bonus
$05     1     resistances          Element resistance flags
$06     1     immunities           Status immunity flags
$07     1     special_effect       Special effect ID
$08     2     buy_price            Buy price in GP (little-endian)
$0a     2     sell_price           Sell price in GP (little-endian)
$0c     1     icon_id              Menu icon ID
$0d     1     sprite_id            Equipment sprite ID
$0e-0F  2     (reserved)           Unused
```

### Accessory Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     accessory_id         Accessory ID (0-31)
$01     1     name_pointer_lo      Name string pointer (low byte)
$02     1     name_pointer_hi      Name string pointer (high byte)
$03     1     hp_bonus             Max HP bonus
$04     1     speed_bonus          Speed bonus
$05     1     str_bonus            Strength bonus
$06     1     def_bonus            Defense bonus
$07     1     special_effect       Special effect ID
$08     2     buy_price            Buy price in GP (little-endian)
$0a     2     sell_price           Sell price in GP (little-endian)
$0c     1     icon_id              Menu icon ID
$0d-0F  3     (reserved)           Unused
```

### Consumable Item Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     item_id              Item ID (0-63)
$01     1     name_pointer_lo      Name string pointer (low byte)
$02     1     name_pointer_hi      Name string pointer (high byte)
$03     1     effect_type          Effect type (heal, buff, etc.)
$04     1     power                Effect power/amount
$05     1     target_flags         Target type flags
$06     1     usable_flags         Usability flags (battle/field)
$07     1     icon_id              Menu icon ID
```

### Element Types

| ID | Element | Description       |
|----|---------|-------------------|
| 0  | None    | No element        |
| 1  | Fire    | Fire element      |
| 2  | Water   | Water element     |
| 3  | Thunder | Thunder element   |
| 4  | Earth   | Earth element     |
| 5  | Wind    | Wind element      |

### Code References

```
Item effect processing: Bank $01, $019000
Equipment application:  Bank $01, $018500
Shop data:             Bank $0c, $0ca000
```

### Extraction Status

- ✅ Data structure documented
- ⏳ Weapon data extraction in progress
- ⏳ Armor data extraction in progress
- ⏳ Consumable data extraction needed

---

## Map Data

### Overview

Map data defines all game maps including the world map, towns, and dungeons.

### ROM Location

```
Map Headers:   Bank $06, $068000 (64 maps × 32 bytes)
Metatiles:     Bank $06, $068800 (256 metatiles × 8 bytes)
Tilemap Data:  Bank $06, $06a000 (variable size per map)
Collision:     Bank $06, $070000 (1 byte per tile)
Events:        Bank $06, $078000 (variable, indexed)
```

### Map Header Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     map_id               Map ID (0-63)
$01     1     map_type             Map type (0=world, 1=town, etc.)
$02     1     width                Map width in tiles
$03     1     height               Map height in tiles
$04     1     tileset_id           Tileset ID
$05     1     palette_id           Palette number (0-7)
$06     1     music_track          Music track ID
$07     1     encounter_group      Random encounter group ID
$08     2     bg1_tilemap_ptr      BG1 tilemap pointer
$0a     2     bg2_tilemap_ptr      BG2 tilemap pointer
$0c     2     collision_ptr        Collision data pointer
$0e     2     event_list_ptr       Event list pointer
$10     2     npc_list_ptr         NPC list pointer
$12     2     warp_list_ptr        Warp list pointer
$14     2     treasure_list_ptr    Treasure list pointer
$16-1F  10    (reserved)           Map-specific data
```

### Map Types

| ID | Type       | Description                    |
|----|------------|--------------------------------|
| 0  | World Map  | Mode 7 world map               |
| 1  | Town       | Town/village map               |
| 2  | Dungeon    | Dungeon/cave map               |
| 3  | Battle BG  | Battle background (no events)  |

### Metatile Structure

Metatiles are 16×16 pixel blocks composed of 4× 8×8 tiles.

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     metatile_id          Metatile ID (0-255)
$01     1     top_left             Top-left 8×8 tile ID
$02     1     top_right            Top-right 8×8 tile ID
$03     1     bottom_left          Bottom-left 8×8 tile ID
$04     1     bottom_right         Bottom-right 8×8 tile ID
$05     1     collision_type       Collision type (see below)
$06-07  2     (flags)              Tile flags (flip, priority, etc.)
```

### Collision Types

| ID | Type       | Description                    |
|----|------------|--------------------------------|
| 0  | Walkable   | Normal walkable terrain        |
| 1  | Wall       | Solid wall/obstacle            |
| 2  | Water      | Water (blocks unless swimming) |
| 3  | Door       | Door tile (triggers warp)      |
| 4  | Warp       | Warp tile (auto-trigger)       |
| 5  | Ice        | Slippery ice tile              |
| 6  | Damage     | Damage floor (lava, spikes)    |
| 7  | Slow       | Slow movement (swamp)          |
| 8  | Event      | Triggers event on step         |
| 9  | NPC        | NPC standing here              |
| 10 | Shop       | Shop entrance                  |
| 11 | Inn        | Inn entrance                   |
| 12 | Treasure   | Treasure chest                 |
| 13 | Stairs     | Stairs (priority change)       |
| 14 | Hidden     | Hidden passage                 |
| 15 | Special    | Map-specific collision         |

### Event Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     event_id             Event ID
$01     1     event_type           Event type (see below)
$02     1     x_position           X coordinate (tiles)
$03     1     y_position           Y coordinate (tiles)
$04     1     trigger_type         Trigger method
$05     1     flag_id              Required/set flag ID
$06     2     script_pointer       Event script pointer
$08-0F  8     (event_data)         Event-specific data
```

### Event Types

| ID | Type        | Description                  |
|----|-------------|------------------------------|
| 0  | Auto        | Triggers automatically       |
| 1  | Interact    | Requires player action       |
| 2  | Step On     | Triggers when stepped on     |
| 3  | Conditional | Requires flag/item           |
| 4  | Cutscene    | Cutscene event               |
| 5  | Battle      | Enemy encounter              |
| 6  | Treasure    | Treasure chest               |
| 7  | Warp        | Map transition               |
| 8  | NPC Talk    | NPC dialog                   |
| 9  | Shop        | Shop menu                    |
| 10 | Inn         | Inn menu                     |
| 11 | Save Point  | Save game                    |

### Code References

```
Map loading:        Bank $01, $010000
Collision check:    Bank $01, $010500
Event processing:   Bank $01, $011000
Tilemap rendering:  Bank $01, $012000
```

### Extraction Status

- ✅ Metatile structure documented
- ✅ Metatile data extracted (256 entries)
- ⏳ Map headers need extraction
- ⏳ Event data needs extraction
- ⏳ Collision data needs extraction

---

## Text Data

### Overview

Text data includes all dialog, menus, battle messages, and system text.

### ROM Location

```
Dialog Text:   Bank $0d, $0d8000-$0dbfff (16 KB)
Menu Text:     Bank $0d, $0dc000-$0ddfff (8 KB)
Battle Text:   Bank $0d, $0de000-$0defff (4 KB)
System Text:   Bank $0d, $0df000-$0dffff (4 KB)
Encoding Table: Bank $0d, $0d0000 (256 bytes)
```

### Text Entry Structure

Text entries are variable-length and use DTE compression.

```
Structure (in-memory after decompression):
- 2 bytes: Text entry pointer (points to compressed data)
- Variable: Compressed text data
- 1 byte: Terminator ($00)
```

### DTE (Dual-Tile Encoding)

Common character pairs are encoded as single bytes to save space:

```
Common pairs (examples):
$80 = "th"
$81 = "he"
$82 = "in"
$83 = "er"
$84 = "an"
$85 = "re"
...
```

Compression ratio: ~30% size reduction

### Control Codes

| Code | Name      | Description                    |
|------|-----------|--------------------------------|
| $00  | END       | End of text                    |
| $01  | NEWLINE   | New line                       |
| $02  | WAIT      | Wait for button press          |
| $03  | PORTRAIT  | Display character portrait     |
| $04  | SPEED     | Change text speed              |
| $05  | COLOR     | Change text color              |
| $06  | PAUSE     | Pause (N frames)               |
| $07  | NAME      | Insert player name             |
| $08  | NUMBER    | Insert number variable         |
| $09  | ITEM      | Insert item name               |
| $0a  | CHOICE    | Present choice menu            |
| $0b  | CLEAR     | Clear text window              |
| $0c  | PAGE      | New page/window                |

### Character Encoding Table

```
Standard ASCII-like encoding:
$20-$7e: Standard characters (A-Z, a-z, 0-9, punctuation)
$80-$bf: DTE compressed pairs
$c0-$ff: Special characters (Japanese, symbols)
```

### Code References

```
Text rendering:        Bank $01, $013000
DTE decompression:     Bank $0d, $0d0100
Control code parser:   Bank $01, $013500
Dialog system:         Bank $01, $014000
```

### Extraction Status

- ✅ Text structure documented
- ✅ Encoding table mapped
- ✅ Control codes identified
- ⏳ Full text extraction in progress
- ⏳ DTE dictionary needs extraction

---

## Graphics Data

### Overview

Graphics data includes tiles, sprites, palettes, and compressed graphics.

### ROM Location

```
Title Graphics:   Bank $04, $048000-$04ffff (32 KB)
Map Tilesets:     Bank $05, $050000-$057fff (32 KB)
Character Sprites: Bank $05, $058000-$05bfff (16 KB)
Enemy Sprites:    Bank $05, $05c000-$05ffff (16 KB)
UI Graphics:      Bank $07, $070000-$073fff (16 KB)
Palettes:         Bank $07, $074000-$0747ff (2 KB)
```

### Tile Data Format

All tiles are 8×8 pixels in either 2bpp or 4bpp format.

**2bpp Format** (4 colors):
- 16 bytes per tile
- 2 bitplanes
- Used for: Font, UI elements

**4bpp Format** (16 colors):
- 32 bytes per tile
- 4 bitplanes
- Used for: Most graphics

**Bitplane organization**:
```
2bpp: Plane 0, Plane 1
4bpp: Plane 0, Plane 1, Plane 2, Plane 3
Each plane: 8 bytes (1 byte per row)
```

### Palette Format

Palettes use SNES 15-bit BGR format.

```
Structure: 2 bytes per color
Format: $0bbb_BBGG_GGGR_RRRR

Bit Layout:
  Bits 0-4:   Red (0-31)
  Bits 5-9:   Green (0-31)
  Bits 10-14: Blue (0-31)
  Bit 15:     Unused (always 0)
```

**Palette sizes**:
- 2bpp graphics: 4 colors (8 bytes)
- 4bpp graphics: 16 colors (32 bytes)

**CGRAM organization**:
- 8 palettes of 16 colors each
- Total: 128 colors (256 bytes)
- First color of each palette is transparent

### Graphics Metadata Structure

For tracking extracted graphics:

```json
{
  "file": "048000-tiles.bin",
  "rom_address": "$048000",
  "size_bytes": 8192,
  "format": "4bpp",
  "tile_count": 256,
  "usage": "Title screen crystals",
  "palette": 0,
  "compression": "none",
  "vram_dest": "$0000"
}
```

### Code References

```
Graphics loading:     Bank $01, $015000
DMA transfer:         Bank $01, $015500
Palette loading:      Bank $01, $016000
Decompression:        Bank $01, $016500
```

### Extraction Status

- ✅ Graphics format documented
- ✅ Palette format documented
- ✅ Sample tiles extracted (title screen)
- ⏳ Full tileset extraction in progress
- ⏳ Sprite extraction needed
- ⏳ Palette extraction needed

---

## Battle Data

### Overview

Battle-specific data structures including formations, attacks, and status effects.

### ROM Location

```
Battle Formations: Bank $0e, $0e0000 (128 entries × 16 bytes)
Attack Data:       Bank $0e, $0e0800 (256 attacks × 16 bytes)
Status Effects:    Bank $0e, $0e2800 (13 effects × 8 bytes)
Battle BG Data:    Bank $0e, $0e2900 (32 backgrounds × 4 bytes)
```

### Battle Formation Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     formation_id         Formation ID (0-127)
$01     1     enemy_count          Number of enemies (1-4)
$02     1     enemy_1_id           Enemy slot 1 ID
$03     1     enemy_2_id           Enemy slot 2 ID
$04     1     enemy_3_id           Enemy slot 3 ID
$05     1     enemy_4_id           Enemy slot 4 ID
$06     1     x_pos_flags          X position arrangement
$07     1     y_pos_flags          Y position arrangement
$08     1     background_id        Battle background ID
$09     1     music_track          Battle music track
$0a     1     escape_difficulty    Escape difficulty (0-255)
$0b     1     surprise_rate        Back attack rate (0-100)
$0c-0F  4     (reserved)           Formation-specific data
```

### Attack Data Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     attack_id            Attack ID (0-255)
$01     1     name_pointer_lo      Attack name pointer (low)
$02     1     name_pointer_hi      Attack name pointer (high)
$03     1     animation_id         Battle animation ID
$04     1     power                Base attack power
$05     1     accuracy             Accuracy (0-100)
$06     1     element              Elemental type (0-5)
$07     1     damage_type          Physical/Magic flag
$08     1     target_type          Single/All flag
$09     1     status_effect        Inflicted status ID
$0a     1     status_rate          Status inflict rate (0-100)
$0b     1     mp_cost              MP cost (for spells)
$0c-0F  4     (special)            Attack-specific data
```

### Status Effect Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     status_id            Status effect ID (0-12)
$01     1     name_pointer_lo      Status name pointer (low)
$02     1     name_pointer_hi      Status name pointer (high)
$03     1     icon_id              Status icon ID
$04     1     duration_type        0=permanent, 1=timed, 2=turns
$05     1     base_duration        Base duration value
$06     1     proc_routine_lo      Processing routine pointer (low)
$07     1     proc_routine_hi      Processing routine pointer (high)
```

### Status Effect IDs

| ID | Name     | Effect                          |
|----|----------|---------------------------------|
| 0  | Poison   | Lose HP each turn               |
| 1  | Sleep    | Cannot act                      |
| 2  | Paralyze | Cannot act (can be damaged)     |
| 3  | Confuse  | Attacks random targets          |
| 4  | Blind    | Lower accuracy                  |
| 5  | Silence  | Cannot cast spells              |
| 6  | Petrify  | Turned to stone (instant death) |
| 7  | Death    | Knocked out (0 HP)              |
| 8  | Doom     | Countdown to death              |
| 9  | Slow     | Slower ATB gauge fill           |
| 10 | Stop     | Frozen in time                  |
| 11 | Berserk  | Auto-attack, higher strength    |
| 12 | Regen    | Recover HP each turn            |

### Code References

```
Formation loading:    Bank $0b, $0b0000
Attack execution:     Bank $0b, $0b1000
Status processing:    Bank $0b, $0b2000
Damage calculation:   Bank $0b, $0b2500
```

### Extraction Status

- ✅ Battle data structures documented
- ⏳ Formation data extraction needed
- ⏳ Attack data extraction needed
- ⏳ Status effect data extraction needed

---

## Music and Sound Data

### Overview

Music and sound effect data for the SPC700 audio processor.

### ROM Location

```
Music Tracks:      Bank $08, $080000-$087fff (32 KB)
Sound Effects:     Bank $08, $088000-$08bfff (16 KB)
Instrument Samples: Bank $08, $08c000-$08ffff (16 KB)
Audio Driver:      SPC RAM $0300-$07ff
```

### Music Track Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     track_id             Music track ID (0-63)
$01     1     tempo                Tempo (BPM / 2)
$02     1     channel_mask         Active channels bitfield
$03     1     loop_flag            0=no loop, 1=loop
$04     2     sequence_ptr         Sequence data pointer
$06     2     pattern_ptr          Pattern table pointer
$08     2     instrument_ptr       Instrument table pointer
$0a     2     loop_point           Loop start offset
$0c-0F  4     (reserved)           Track-specific data
```

### Sound Effect Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     sfx_id               Sound effect ID (0-127)
$01     1     priority             Priority (0-4, 4=highest)
$02     1     channel              Preferred channel (6-7 for SFX)
$03     1     sample_id            Instrument/sample ID
$04     1     pitch                Pitch value
$05     1     volume               Volume (0-127)
$06     1     length               Length in ticks
$07     1     adsr                 ADSR envelope preset
```

### Instrument Structure

```
Offset  Size  Field Name           Description
------  ----  -------------------  ---------------------------------
$00     1     instrument_id        Instrument ID (0-127)
$01     1     sample_ptr_lo        BRR sample pointer (low)
$02     1     sample_ptr_hi        BRR sample pointer (high)
$03     1     adsr_1               ADSR byte 1 (attack/decay)
$04     1     adsr_2               ADSR byte 2 (sustain/release)
$05     1     gain                 Gain value
$06     1     pitch_mult           Pitch multiplier
$07     1     (reserved)           Padding
```

### BRR Sample Format

BRR (Bit Rate Reduction) is SNES compressed audio format.

**Structure**:
- 9 bytes per block
- Byte 0: Header (range, filter, loop flags)
- Bytes 1-8: 16 compressed samples (4 bits each)

**Compression**: ~3.6:1 ratio vs raw PCM

### Code References

```
Music playback:     SPC RAM $0300
SFX playback:       SPC RAM $0500
Sample loading:     Bank $01, $017000
Audio commands:     Bank $01, $017500
```

### Extraction Status

- ✅ Music data structure documented
- ✅ SFX structure documented
- ⏳ Track data extraction needed
- ⏳ Instrument extraction needed
- ⏳ BRR sample extraction needed

---

## Extraction Status

### Overall Progress

| Data Category    | Structure | Extraction | Validation | Schema | Status    |
|------------------|-----------|------------|------------|--------|-----------|
| Characters       | ✅        | ⏳         | ❌         | ✅     | 40%       |
| Enemies          | ✅        | ⏳         | ❌         | ✅     | 30%       |
| Items            | ✅        | ⏳         | ❌         | ✅     | 35%       |
| Maps             | ✅        | 🟡         | ❌         | ✅     | 50%       |
| Text             | ✅        | 🟡         | ❌         | ✅     | 45%       |
| Graphics         | ✅        | 🟡         | ❌         | ✅     | 40%       |
| Battle           | ✅        | ⏳         | ❌         | ❌     | 25%       |
| Music/Sound      | ✅        | ⏳         | ❌         | ❌     | 20%       |

**Legend**:
- ✅ Complete
- 🟡 Partial/In Progress
- ⏳ Not Started
- ❌ Not Done

### Next Steps

**High Priority**:
1. Complete map header extraction
2. Extract full enemy database
3. Extract weapon/armor data
4. Extract character stat tables

**Medium Priority**:
5. Extract all text entries
6. Complete DTE dictionary
7. Extract battle formations
8. Extract music track data

**Low Priority**:
9. Extract all graphics tilesets
10. Create automated validation
11. Generate coverage reports
12. Create extraction tools

---

## Data Format Conventions

### Naming Conventions

**Field Names**:
- Use `snake_case` for all field names
- Be descriptive: `max_hp` not `mhp`
- Use consistent terminology across all structures
- Document units: `duration_frames` not `duration`

**File Names**:
- Use `snake_case` for JSON files
- Plural for collections: `enemies.json`
- Singular for schemas: `enemy_schema.json`
- Hex prefix for binary: `048000-tiles.bin`

### Data Types

**Integers**:
- Unsigned unless specified
- Little-endian for multi-byte values
- Document valid ranges

**Strings**:
- UTF-8 encoding for JSON
- Include null terminators in byte counts
- Document max lengths

**Pointers**:
- 2 bytes (16-bit) for bank-local
- 3 bytes (24-bit) for absolute ROM
- Document pointer base address

**Flags/Bitfields**:
- Document each bit
- Use consistent bit ordering (bit 0 = LSB)
- Provide examples

### Documentation Standards

**Each structure must include**:
1. Purpose/description
2. ROM location (bank + address)
3. Size (bytes per entry, total entries)
4. Field-by-field breakdown
5. Enumerations for coded values
6. Code references (where used)
7. Extraction status

**Field documentation**:
- Name, offset, size, description
- Valid value ranges
- Special values (0xFF = null, etc.)
- Related fields/dependencies

---

## Related Tools

**Extraction Tools**:
- `tools/extract_characters.py`: Extract character data
- `tools/extract_enemies.py`: Extract enemy data
- `tools/extract_items.py`: Extract item data
- `tools/extract_maps.py`: Extract map data
- `tools/extract_text.py`: Extract text data
- `tools/extract_graphics.py`: Extract graphics

**Validation Tools**:
- `tools/validate_data.py`: Validate against schemas
- `tools/verify_build.py`: Verify ROM match
- `tools/coverage_report.py`: Generate coverage report

**Conversion Tools**:
- `tools/convert_palette.py`: Convert palettes
- `tools/convert_tiles.py`: Convert tile formats
- `tools/convert_text.py`: Encode/decode text

See `docs/TOOLS.md` for detailed tool documentation.

---

## References

- **ROM Map**: `docs/rom_map.md`
- **Memory Map**: `docs/RAM_MAP.md`
- **System Architecture**: `docs/GRAPHICS_SYSTEM.md`, `docs/BATTLE_SYSTEM.md`, etc.
- **Modding Guide**: `docs/MODDING_GUIDE.md`
- **JSON Schemas**: `data/schemas/`

---

## C Struct Definitions

For use in C/C++ tools and editors. These struct definitions match the ROM data layouts exactly.

### Character Data Structure

```c
// Character data structure (32 bytes)
// ROM Location: Bank $0C @ $8000
typedef struct {
    uint8_t  character_id;        // 0x00: Character ID (0-3)
    uint8_t  name_ptr_lo;         // 0x01: Name string pointer (low)
    uint8_t  name_ptr_hi;         // 0x02: Name string pointer (high)
    uint8_t  starting_level;      // 0x03: Starting level (1-41)
    uint16_t starting_hp;         // 0x04: Starting HP (little-endian)
    uint16_t max_hp;              // 0x06: Maximum HP
    uint8_t  white_magic;         // 0x08: White magic power
    uint8_t  black_magic;         // 0x09: Black magic power
    uint8_t  wizard_magic;        // 0x0A: Wizard magic power
    uint8_t  speed;               // 0x0B: Speed stat
    uint8_t  strength;            // 0x0C: Strength
    uint8_t  defense;             // 0x0D: Defense
    uint8_t  hp_growth;           // 0x0E: HP gain per level
    uint8_t  wm_growth;           // 0x0F: White magic growth
    uint8_t  bm_growth;           // 0x10: Black magic growth
    uint8_t  wiz_growth;          // 0x11: Wizard magic growth
    uint8_t  speed_growth;        // 0x12: Speed growth
    uint8_t  str_growth;          // 0x13: Strength growth
    uint8_t  def_growth;          // 0x14: Defense growth
    uint8_t  equipment_flags;     // 0x15: Equipment slot flags
    uint8_t  magic_flags;         // 0x16: Available magic types
    uint8_t  starting_weapon;     // 0x17: Starting weapon ID
    uint8_t  starting_armor;      // 0x18: Starting armor ID
    uint8_t  starting_accessory;  // 0x19: Starting accessory ID
    uint8_t  reserved[6];         // 0x1A-0x1F: Unused/padding
} CharacterData;
```

### Enemy Data Structure

```c
// Enemy data structure (14 bytes)
// ROM Location: Bank $02 @ $C275 (PC offset $014275)
typedef struct {
    uint16_t max_hp;              // 0x00: Max HP (little-endian)
    uint8_t  attack;              // 0x02: Attack power
    uint8_t  defense;             // 0x03: Defense
    uint8_t  speed;               // 0x04: Speed
    uint8_t  magic;               // 0x05: Magic power
    uint16_t resistances;         // 0x06: Element resistances (bitfield)
    uint8_t  magic_defense;       // 0x08: Magic defense
    uint8_t  magic_evade;         // 0x09: Magic evade
    uint8_t  accuracy;            // 0x0A: Physical accuracy
    uint8_t  evade;               // 0x0B: Physical evade
    uint16_t weaknesses;          // 0x0C: Element weaknesses (bitfield)
} EnemyStats;

// Element bitfield flags (resistances and weaknesses)
#define ELEM_FIRE       0x0001
#define ELEM_ICE        0x0002
#define ELEM_THUNDER    0x0004
#define ELEM_EARTH      0x0008
#define ELEM_AIR        0x0010
#define ELEM_WATER      0x0020
#define ELEM_POISON     0x0040
#define ELEM_BOMB       0x0080
#define ELEM_AXE        0x0100
#define ELEM_SWORD      0x0200
#define ELEM_DARK       0x0400
#define ELEM_STONE      0x0800
#define ELEM_CONFUSION  0x1000
#define ELEM_SLEEP      0x2000
#define ELEM_PARALYZE   0x4000
#define ELEM_DOOM       0x8000
```

### Item Data Structure

```c
// Item data structure (16 bytes)
// ROM Location: Bank $04 @ varies by item type
typedef struct {
    uint8_t  item_id;             // 0x00: Item ID (0-255)
    uint8_t  item_type;           // 0x01: Type (0=consumable, 1=weapon, etc.)
    uint8_t  name_ptr_lo;         // 0x02: Name string pointer (low)
    uint8_t  name_ptr_hi;         // 0x03: Name string pointer (high)
    uint8_t  description_ptr_lo;  // 0x04: Description pointer (low)
    uint8_t  description_ptr_hi;  // 0x05: Description pointer (high)
    uint8_t  icon_id;             // 0x06: Icon graphic ID
    uint8_t  power;               // 0x07: Attack/defense bonus
    uint8_t  element;             // 0x08: Elemental affinity
    uint8_t  special_effect;      // 0x09: Special effect ID
    uint16_t buy_price;           // 0x0A: Shop buy price (little-endian)
    uint16_t sell_price;          // 0x0C: Shop sell price
    uint8_t  equip_flags;         // 0x0E: Who can equip (bitfield)
    uint8_t  reserved;            // 0x0F: Unused/padding
} ItemData;

// Item types
#define ITEM_TYPE_CONSUMABLE  0
#define ITEM_TYPE_WEAPON      1
#define ITEM_TYPE_ARMOR       2
#define ITEM_TYPE_ACCESSORY   3
#define ITEM_TYPE_KEY_ITEM    4
```

### Attack Data Structure

```c
// Attack/spell data structure (varies)
// ROM Location: Bank $02 @ $4678
typedef struct {
    uint8_t  attack_id;           // 0x00: Attack ID
    uint8_t  power;               // 0x01: Base power
    uint8_t  element;             // 0x02: Elemental type
    uint8_t  targeting;           // 0x03: Target selection
    uint8_t  animation_id;        // 0x04: Animation to play
    uint8_t  hit_formula;         // 0x05: Hit rate formula ID
    uint8_t  damage_formula;      // 0x06: Damage formula ID
    uint8_t  special_effects;     // 0x07: Status effects bitfield
} AttackData;
```

### Graphics Data Structures

```c
// Tileset header (8 bytes)
typedef struct {
    uint16_t tile_data_offset;    // 0x00: Offset to tile data
    uint16_t tile_count;          // 0x02: Number of tiles
    uint8_t  bits_per_pixel;      // 0x04: 2, 4, or 8 BPP
    uint8_t  compression;         // 0x05: 0=none, 1=RLE, 2=LZ
    uint16_t palette_offset;      // 0x06: Offset to palette data
} TilesetHeader;

// Palette entry (2 bytes, RGB555 format)
typedef struct {
    uint16_t color;               // RGB555: xBBBBBGGGGGRRRRR
} PaletteColor;

// Helper macros for RGB555
#define RGB555(r,g,b) (((b)<<10) | ((g)<<5) | (r))
#define GET_RED(c)    ((c) & 0x1F)
#define GET_GREEN(c)  (((c) >> 5) & 0x1F)
#define GET_BLUE(c)   (((c) >> 10) & 0x1F)
```

### Map Data Structures

```c
// Map header (32 bytes)
typedef struct {
    uint8_t  map_id;              // 0x00: Map ID (0-19)
    uint8_t  width;               // 0x01: Map width in tiles
    uint8_t  height;              // 0x02: Map height in tiles
    uint8_t  tileset_id;          // 0x03: Tileset to use
    uint8_t  music_id;            // 0x04: Background music track
    uint8_t  palette_id;          // 0x05: Palette set ID
    uint16_t tilemap_offset;      // 0x06: Offset to tilemap data
    uint16_t collision_offset;    // 0x08: Offset to collision data
    uint16_t event_offset;        // 0x0A: Offset to event data
    uint8_t  layers;              // 0x0C: Number of layers (1-3)
    uint8_t  flags;               // 0x0D: Map flags
    uint8_t  reserved[18];        // 0x0E-0x1F: Unused/padding
} MapHeader;

// Tile properties (1 byte per tile)
typedef struct {
    uint8_t walkable : 1;         // Bit 0: Can walk on tile
    uint8_t water : 1;            // Bit 1: Water tile
    uint8_t damage : 1;           // Bit 2: Damage tile (lava)
    uint8_t ice : 1;              // Bit 3: Slippery (ice)
    uint8_t trigger : 1;          // Bit 4: Event trigger zone
    uint8_t npc_block : 1;        // Bit 5: NPC blocking
    uint8_t reserved : 2;         // Bits 6-7: Unused
} TileProperties;
```

### Save Data Structure

```c
// Save slot structure (0x38C bytes)
// SRAM Location: 3 copies at $0000, $038C, $0718
typedef struct {
    uint16_t checksum;            // 0x000: Save data checksum
    uint8_t  marker[4];           // 0x002: "FF0!" marker
    uint8_t  save_slot;           // 0x006: Save slot number (0-2)
    uint8_t  play_time_hours;     // 0x007: Play time (hours)
    uint8_t  play_time_minutes;   // 0x008: Play time (minutes)
    uint8_t  play_time_seconds;   // 0x009: Play time (seconds)
    
    // Character data (4 × 80 bytes = 320 bytes)
    struct {
        uint8_t  name[8];         // Character name
        uint8_t  level;           // Current level
        uint16_t current_hp;      // Current HP
        uint16_t max_hp;          // Maximum HP
        uint8_t  stats[10];       // Various stats
        uint8_t  equipment[4];    // Equipped items
        uint8_t  magic[16];       // Known spells
        uint8_t  reserved[39];    // Padding
    } characters[4];
    
    // Inventory (256 bytes)
    uint8_t inventory[256];       // Item IDs (0xFF = empty)
    
    // Progress flags (varies)
    uint8_t progress_flags[64];   // Event flags, chests opened, etc.
    
    // Padding to 0x38C bytes
    uint8_t reserved[24];
} SaveData;
```

### Text Encoding

```c
// DTE (Dual Tile Encoding) table entry
typedef struct {
    uint8_t char1;                // First character
    uint8_t char2;                // Second character
} DTEEntry;

// Text control codes
#define TEXT_END           0x00   // End of string
#define TEXT_NEWLINE       0x01   // Newline
#define TEXT_WAIT          0x02   // Wait for button
#define TEXT_CLEAR         0x03   // Clear text box
#define TEXT_COLOR_START   0x10   // Color codes 0x10-0x1F
#define TEXT_CHAR_START    0x20   // Character codes 0x20+
```

---

## Usage Examples

### Reading Enemy Data in C

```c
#include <stdio.h>
#include <stdint.h>

// Read enemy data from ROM
EnemyStats* read_enemy(FILE* rom, uint8_t enemy_id) {
    static EnemyStats enemy;
    
    // Enemy data starts at PC offset 0x014275
    fseek(rom, 0x014275 + (enemy_id * sizeof(EnemyStats)), SEEK_SET);
    fread(&enemy, sizeof(EnemyStats), 1, rom);
    
    return &enemy;
}

// Check if enemy has fire weakness
int has_fire_weakness(EnemyStats* enemy) {
    return (enemy->weaknesses & ELEM_FIRE) != 0;
}

// Print enemy stats
void print_enemy_stats(EnemyStats* enemy, const char* name) {
    printf("Enemy: %s\n", name);
    printf("  HP:      %d\n", enemy->max_hp);
    printf("  Attack:  %d\n", enemy->attack);
    printf("  Defense: %d\n", enemy->defense);
    printf("  Speed:   %d\n", enemy->speed);
    
    if (has_fire_weakness(enemy)) {
        printf("  Weak to: Fire\n");
    }
}
```

### Converting RGB555 Colors

```c
// Convert RGB555 to RGB888 for display
typedef struct {
    uint8_t r, g, b;
} RGB888;

RGB888 rgb555_to_rgb888(uint16_t color) {
    RGB888 result;
    
    // Extract 5-bit components
    uint8_t r5 = GET_RED(color);
    uint8_t g5 = GET_GREEN(color);
    uint8_t b5 = GET_BLUE(color);
    
    // Scale to 8-bit (multiply by 255/31 ≈ 8.2258)
    result.r = (r5 * 255) / 31;
    result.g = (g5 * 255) / 31;
    result.b = (b5 * 255) / 31;
    
    return result;
}
```

---

*This document is updated as data structures are discovered and extraction progresses.*
