# FFMQ Memory Map (RAM)

Complete reference for SNES memory addresses (RAM) used in Final Fantasy: Mystic Quest.

## Table of Contents

- [Overview](#overview)
- [Memory Regions](#memory-regions)
- [WRAM ($7E0000-$7FFFFF)](#wram-7e0000-7fffff)
- [SRAM ($700000-$7FFFFF)](#sram-700000-7fffff)
- [Hardware Registers](#hardware-registers)
- [Label Categories](#label-categories)
- [Labeling Status](#labeling-status)

## Overview

### SNES Memory Map

The SNES has multiple memory regions accessible through different addressing modes:

| Region      | Address Range      | Size    | Description                |
|-------------|--------------------|---------|----------------------------|
| WRAM        | $7E0000-$7EFFFF    | 64 KB   | Work RAM (Bank $7E)        |
| WRAM Mirror | $7F0000-$7FFFFF    | 64 KB   | Work RAM (Bank $7F)        |
| SRAM        | $700000-$7FFFFF    | 128 KB  | Save RAM (battery backed)  |
| Hardware    | $2100-$21FF        | 256 B   | PPU registers              |
| Hardware    | $4000-$43FF        | 1 KB    | CPU/controller registers   |

### Addressing Modes

- **Direct Page** ($00-$FF): Fast access to first 256 bytes of WRAM
- **Absolute** ($0000-$FFFF): Full 64KB bank access
- **Long** ($000000-$FFFFFF): Full 24-bit addressing

### Label Naming Convention

Labels follow these conventions:
- **Variables**: `variable_name` (snake_case)
- **Arrays**: `array_name_table` or `array_name_buffer`
- **Pointers**: `ptr_destination` or `destination_pointer`
- **Flags**: `flag_description` or `is_state`
- **Counters**: `counter_name` or `timer_name`

**Size prefixes** (optional):
- `b_` = byte (8-bit)
- `w_` = word (16-bit)
- `l_` = long (24-bit)
- `a_` = array

---

## Memory Regions

### Zero Page ($00-$FF)

Critical fast-access memory. Heavily used by all game systems.

#### General Purpose ($00-$1F)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $00-$01 | temp_ptr_1         | 2    | Temporary pointer 1            |
| $02-$03 | temp_ptr_2         | 2    | Temporary pointer 2            |
| $04-$05 | temp_ptr_3         | 2    | Temporary pointer 3            |
| $06     | temp_byte_1        | 1    | Temporary byte storage         |
| $07     | temp_byte_2        | 1    | Temporary byte storage         |
| $08     | temp_byte_3        | 1    | Temporary byte storage         |
| $09     | temp_word_1_lo     | 1    | Temporary word (low byte)      |
| $0A     | temp_word_1_hi     | 1    | Temporary word (high byte)     |
| $0B     | temp_index         | 1    | Temporary index/counter        |
| $0C     | temp_flags         | 1    | Temporary flag byte            |
| $0D-$1F | (unassigned)       | 19   | Available for labeling         |

#### Graphics System ($20-$3F)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $20     | vram_write_lo      | 1    | VRAM write address (low)       |
| $21     | vram_write_hi      | 1    | VRAM write address (high)      |
| $22     | dma_channel        | 1    | Current DMA channel            |
| $23     | dma_mode           | 1    | DMA transfer mode              |
| $24-$25 | dma_source         | 2    | DMA source address             |
| $26     | dma_source_bank    | 1    | DMA source bank                |
| $27-$28 | dma_size           | 2    | DMA transfer size              |
| $29     | screen_brightness  | 1    | Screen brightness (0-15)       |
| $2A     | bg_mode            | 1    | Background mode                |
| $2B     | mosaic_enable      | 1    | Mosaic enable flags            |
| $2C-$2F | bg_scroll_x        | 4    | BG1-BG2 X scroll (2 bytes each)|
| $30-$33 | bg_scroll_y        | 4    | BG1-BG2 Y scroll (2 bytes each)|
| $34     | window_1_left      | 1    | Window 1 left position         |
| $35     | window_1_right     | 1    | Window 1 right position        |
| $36     | window_2_left      | 1    | Window 2 left position         |
| $37     | window_2_right     | 1    | Window 2 right position        |
| $38-$3F | (graphics_misc)    | 8    | Graphics-related variables     |

#### Player State ($40-$5F)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $40     | player_x_pos_lo    | 1    | Player X position (low byte)   |
| $41     | player_x_pos_hi    | 1    | Player X position (high byte)  |
| $42     | player_y_pos_lo    | 1    | Player Y position (low byte)   |
| $43     | player_y_pos_hi    | 1    | Player Y position (high byte)  |
| $44     | player_direction   | 1    | Facing direction (0-3)         |
| $45     | player_speed       | 1    | Movement speed                 |
| $46     | player_state       | 1    | Current state (walk/run/etc)   |
| $47     | player_animation   | 1    | Animation frame counter        |
| $48     | map_id             | 1    | Current map ID                 |
| $49     | map_x_pos          | 1    | Map X coordinate               |
| $4A     | map_y_pos          | 1    | Map Y coordinate               |
| $4B     | collision_flags    | 1    | Collision check results        |
| $4C-$4F | (player_misc)      | 4    | Player-related variables       |
| $50-$5F | (reserved)         | 16   | Reserved for player system     |

#### Input/Controller ($60-$6F)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $60     | joy1_current       | 1    | Controller 1 current state     |
| $61     | joy1_previous      | 1    | Controller 1 previous state    |
| $62     | joy1_pressed       | 1    | Controller 1 newly pressed     |
| $63     | joy1_held          | 1    | Controller 1 held buttons      |
| $64     | joy2_current       | 1    | Controller 2 current state     |
| $65     | joy2_previous      | 1    | Controller 2 previous state    |
| $66     | joy2_pressed       | 1    | Controller 2 newly pressed     |
| $67     | joy2_held          | 1    | Controller 2 held buttons      |
| $68-$6F | (input_misc)       | 8    | Input-related variables        |

#### Game State ($70-$8F)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $70     | frame_counter_lo   | 1    | Frame counter (low byte)       |
| $71     | frame_counter_hi   | 1    | Frame counter (high byte)      |
| $72     | rng_seed_lo        | 1    | RNG seed (low byte)            |
| $73     | rng_seed_hi        | 1    | RNG seed (high byte)           |
| $74     | game_mode          | 1    | Current game mode              |
| $75     | game_state         | 1    | Current game state             |
| $76     | menu_selection     | 1    | Current menu selection         |
| $77     | menu_index         | 1    | Menu cursor index              |
| $78     | dialog_state       | 1    | Dialog system state            |
| $79     | dialog_speed       | 1    | Text display speed             |
| $7A     | text_char_index    | 1    | Current character index        |
| $7B     | text_line          | 1    | Current text line              |
| $7C     | fade_state         | 1    | Screen fade state              |
| $7D     | fade_timer         | 1    | Fade timer counter             |
| $7E     | music_track        | 1    | Current music track            |
| $7F     | sfx_queue          | 1    | Sound effect queue             |
| $80-$8F | (game_misc)        | 16   | Game state variables           |

#### Battle System ($90-$BF)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $90     | battle_state       | 1    | Current battle state           |
| $91     | battle_phase       | 1    | Battle phase (init/main/end)   |
| $92     | active_character   | 1    | Currently acting character     |
| $93     | target_index       | 1    | Current target index           |
| $94     | command_index      | 1    | Selected command               |
| $95     | atb_gauge_char1    | 1    | Character 1 ATB gauge          |
| $96     | atb_gauge_char2    | 1    | Character 2 ATB gauge          |
| $97     | atb_gauge_enemy1   | 1    | Enemy 1 ATB gauge              |
| $98     | atb_gauge_enemy2   | 1    | Enemy 2 ATB gauge              |
| $99     | damage_value_lo    | 1    | Damage calculation (low)       |
| $9A     | damage_value_hi    | 1    | Damage calculation (high)      |
| $9B     | hit_chance         | 1    | Hit probability                |
| $9C     | critical_flag      | 1    | Critical hit flag              |
| $9D     | status_effect      | 1    | Applied status effect          |
| $9E     | exp_gained_lo      | 1    | EXP gained (low byte)          |
| $9F     | exp_gained_hi      | 1    | EXP gained (high byte)         |
| $A0-$AF | (battle_chars)     | 16   | Character battle data          |
| $B0-$BF | (battle_enemies)   | 16   | Enemy battle data              |

#### Stack & System ($C0-$FF)

| Address | Label              | Size | Description                    |
|---------|--------------------|------|--------------------------------|
| $C0-$DF | (system_vars)      | 32   | System variables               |
| $E0-$EF | (reserved)         | 16   | Reserved                       |
| $F0-$FF | (stack_temps)      | 16   | Near-stack temporaries         |

---

### Low RAM ($7E0100-$7E01FF)

Extended work area beyond zero page.

#### Character Stats ($7E0100-$7E01FF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E0100-0101 | char1_hp_current       | 2    | Benjamin current HP            |
| $7E0102-0103 | char1_hp_max           | 2    | Benjamin max HP                |
| $7E0104      | char1_white_magic      | 1    | Benjamin white magic power     |
| $7E0105      | char1_black_magic      | 1    | Benjamin black magic power     |
| $7E0106      | char1_wizard_magic     | 1    | Benjamin wizard magic power    |
| $7E0107      | char1_speed            | 1    | Benjamin speed stat            |
| $7E0108      | char1_strength         | 1    | Benjamin strength stat         |
| $7E0109      | char1_defense          | 1    | Benjamin defense stat          |
| $7E010A      | char1_level            | 1    | Benjamin level                 |
| $7E010B      | char1_exp_lo           | 1    | Benjamin EXP (byte 1)          |
| $7E010C      | char1_exp_mid          | 1    | Benjamin EXP (byte 2)          |
| $7E010D      | char1_exp_hi           | 1    | Benjamin EXP (byte 3)          |
| $7E010E      | char1_weapon_id        | 1    | Equipped weapon ID             |
| $7E010F      | char1_armor_id         | 1    | Equipped armor ID              |
| $7E0110      | char1_accessory_id     | 1    | Equipped accessory ID          |
| $7E0111      | char1_status_flags     | 1    | Status effect flags            |
| $7E0112-011F | (char1_misc)           | 14   | Additional character data      |
| $7E0120-013F | char2_data             | 32   | Companion character data       |
| $7E0140-017F | (char_extended)        | 64   | Extended character data        |
| $7E0180-01FF | (party_data)           | 128  | Party and inventory data       |

---

### Mid RAM ($7E0200-$7E0FFF)

General game data storage.

#### Inventory ($7E0200-$7E02FF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E0200-021F | inventory_weapons      | 32   | Weapon inventory (1 byte each) |
| $7E0220-023F | inventory_armor        | 32   | Armor inventory (1 byte each)  |
| $7E0240-025F | inventory_accessories  | 32   | Accessory inventory            |
| $7E0260-029F | inventory_consumables  | 64   | Consumable items               |
| $7E02A0-02BF | inventory_key_items    | 32   | Key items                      |
| $7E02C0-02CF | inventory_counts       | 16   | Item quantities                |
| $7E02D0-02FF | (inventory_misc)       | 48   | Inventory metadata             |

#### Game Progress Flags ($7E0300-$7E03FF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E0300-031F | story_flags            | 32   | Story progression flags        |
| $7E0320-033F | event_flags            | 32   | Event completion flags         |
| $7E0340-035F | treasure_flags         | 32   | Treasure chest opened flags    |
| $7E0360-037F | npc_flags              | 32   | NPC interaction flags          |
| $7E0380-039F | boss_defeated_flags    | 32   | Boss defeat flags              |
| $7E03A0-03BF | crystal_flags          | 32   | Crystal-related flags          |
| $7E03C0-03FF | (misc_flags)           | 64   | Miscellaneous flags            |

#### Map Data Cache ($7E0400-$7E07FF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E0400-04FF | map_cache_1            | 256  | Map data cache slot 1          |
| $7E0500-05FF | map_cache_2            | 256  | Map data cache slot 2          |
| $7E0600-06FF | map_cache_3            | 256  | Map data cache slot 3          |
| $7E0700-077F | npc_positions          | 128  | NPC position data              |
| $7E0780-07FF | event_data             | 128  | Event state data               |

#### Battle Data ($7E0800-$7E0BFF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E0800-087F | enemy_data_1           | 128  | Enemy 1 full data              |
| $7E0880-08FF | enemy_data_2           | 128  | Enemy 2 full data              |
| $7E0900-097F | enemy_data_3           | 128  | Enemy 3 full data (optional)   |
| $7E0980-09FF | enemy_data_4           | 128  | Enemy 4 full data (optional)   |
| $7E0A00-0A7F | battle_state_data      | 128  | Battle state variables         |
| $7E0A80-0AFF | command_queue          | 128  | Battle command queue           |
| $7E0B00-0BFF | (battle_misc)          | 256  | Battle system working data     |

#### Text & Dialog ($7E0C00-$7E0FFF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E0C00-0CFF | text_buffer            | 256  | Decompressed text buffer       |
| $7E0D00-0DFF | dialog_buffer          | 256  | Dialog display buffer          |
| $7E0E00-0EFF | menu_buffer            | 256  | Menu text buffer               |
| $7E0F00-0FFF | (text_misc)            | 256  | Text system working data       |

---

### High RAM ($7E1000-$7EFFFF)

Large buffers and working memory.

#### OAM Buffer ($7E1000-$7E11FF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E1000-11FF | oam_buffer             | 512  | Sprite OAM buffer (128 sprites)|

#### Tilemap Buffers ($7E1200-$7E3FFF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E1200-1FFF | bg1_tilemap_buffer     | 3.5K | BG1 tilemap buffer             |
| $7E2000-2FFF | bg2_tilemap_buffer     | 4K   | BG2 tilemap buffer             |
| $7E3000-3FFF | bg3_tilemap_buffer     | 4K   | BG3 tilemap buffer (text)      |

#### Graphics Buffers ($7E4000-$7E7FFF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E4000-4FFF | tile_buffer            | 4K   | Tile data decompression buffer |
| $7E5000-5FFF | sprite_buffer          | 4K   | Sprite data buffer             |
| $7E6000-6FFF | palette_buffer         | 4K   | Palette staging buffer         |
| $7E7000-7FFF | (graphics_work)        | 4K   | Graphics working memory        |

#### Audio Buffers ($7E8000-$7E8FFF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E8000-80FF | audio_command_buffer   | 256  | Audio command queue            |
| $7E8100-81FF | music_data_buffer      | 256  | Music sequence buffer          |
| $7E8200-82FF | sfx_data_buffer        | 256  | SFX data buffer                |
| $7E8300-8FFF | (audio_work)           | 3K   | Audio working memory           |

#### Working Memory ($7E9000-$7EFFFF)

| Address      | Label                  | Size | Description                    |
|--------------|------------------------|------|--------------------------------|
| $7E9000-9FFF | general_work_1         | 4K   | General working memory         |
| $7EA000-AFFF | general_work_2         | 4K   | General working memory         |
| $7EB000-BFFF | general_work_3         | 4K   | General working memory         |
| $7EC000-CFFF | decompression_buffer   | 4K   | Data decompression buffer      |
| $7ED000-DFFF | (reserved_work)        | 4K   | Reserved working space         |
| $7EE000-EFFF | (stack_area)           | 4K   | Extended stack area            |
| $7EF000-FFFF | (unused)               | 4K   | Unused/available               |

---

## SRAM ($700000-$7FFFFF)

Battery-backed save RAM for game saves.

### Save Slot Structure

Each save slot is 256 bytes. The game supports 4 save slots.

| Offset | Size | Description                         |
|--------|------|-------------------------------------|
| $00    | 2    | Checksum                            |
| $02    | 1    | Save slot validity flag             |
| $03    | 1    | Play time (hours)                   |
| $04    | 1    | Play time (minutes)                 |
| $05    | 1    | Play time (seconds)                 |
| $06    | 32   | Character 1 data                    |
| $26    | 32   | Character 2 data                    |
| $46    | 64   | Inventory data                      |
| $86    | 32   | Story flags                         |
| $A6    | 32   | Event flags                         |
| $C6    | 32   | Treasure flags                      |
| $E6    | 26   | Misc game state                     |

### SRAM Layout

| Address          | Description          |
|------------------|----------------------|
| $700000-$7000FF  | Save Slot 1 (256 B)  |
| $700100-$7001FF  | Save Slot 2 (256 B)  |
| $700200-$7002FF  | Save Slot 3 (256 B)  |
| $700300-$7003FF  | Save Slot 4 (256 B)  |
| $700400-$7FFFFF  | Unused (~127 KB)     |

---

## Hardware Registers

### PPU Registers ($2100-$21FF)

See GRAPHICS_SYSTEM.md for complete PPU register documentation.

**Key registers**:
- $2100: Screen display (brightness, forced blank)
- $2105: BG mode and character size
- $2107-210A: BG tilemap addresses
- $210B-210C: BG character data addresses
- $210D-2114: BG scroll positions
- $2115: VRAM address increment mode
- $2116-2117: VRAM address
- $2118-2119: VRAM data write
- $2121: CGRAM address
- $2122: CGRAM data write
- $212C: Main screen designation
- $212D: Sub screen designation

### CPU Registers ($4000-$43FF)

**Controller ports**:
- $4016: Joypad 1
- $4017: Joypad 2

**Multiplication/Division**:
- $4202: Multiplicand
- $4203: Multiplier
- $4204-4205: Dividend
- $4206: Divisor
- $4214-4215: Quotient
- $4216-4217: Remainder/Product

**DMA registers** ($43x0-$43xB, x=channel 0-7):
- $43x0: DMA control
- $43x1: DMA destination
- $43x2-4: DMA source address
- $43x5-6: DMA size
- $420B: DMA enable
- $420C: HDMA enable

---

## Label Categories

### Priority Levels

**High Priority** (Most frequently accessed):
- Player position and state
- Controller input
- Graphics system variables
- Battle ATB gauges
- Character stats (HP, stats)

**Medium Priority** (Frequently accessed):
- Inventory data
- Game progression flags
- Menu state
- NPC data
- Map cache

**Low Priority** (Less frequently accessed):
- Extended character data
- Treasure flags
- Audio buffers
- Working memory

---

## Labeling Status

### Overall Progress

**Zero Page ($00-$FF)**: 25% labeled
- General Purpose: 60% (12/20 addresses)
- Graphics: 80% (32/40 addresses)
- Player State: 75% (24/32 addresses)
- Input: 100% (16/16 addresses)
- Game State: 80% (24/30 addresses)
- Battle: 50% (24/48 addresses)
- System: 10% (8/80 addresses)

**Low RAM ($7E0100-$01FF)**: 60% labeled
- Character Stats: 80% (192/240 bytes)
- Extended Data: 20% (16/80 bytes)

**Mid RAM ($7E0200-$0FFF)**: 40% labeled
- Inventory: 90% (230/256 bytes)
- Progress Flags: 100% (256/256 bytes)
- Map Cache: 60% (640/1024 bytes)
- Battle Data: 30% (384/1024 bytes)
- Text/Dialog: 50% (512/1024 bytes)

**High RAM ($7E1000-$FFFF)**: 15% labeled
- OAM Buffer: 100% (512/512 bytes)
- Tilemap Buffers: 100% (11776/11776 bytes)
- Graphics Buffers: 50% (8192/16384 bytes)
- Audio Buffers: 25% (1024/4096 bytes)
- Working Memory: 0% (0/28672 bytes)

**Total RAM Labeling**: ~32% (23KB / 64KB labeled)

### Top 50 Most-Used WRAM Addresses

See Issue #28 for the complete list of high-priority addresses to label.

**Top 10**:
1. $40-$43: Player position (X,Y coordinates)
2. $7E0100-0103: Benjamin HP (current/max)
3. $60-$63: Controller 1 input state
4. $20-$21: VRAM write address
5. $70-$71: Frame counter
6. $90: Battle state
7. $74-$75: Game mode/state
8. $7E0C00: Text buffer start
9. $7E1000: OAM buffer start
10. $00-$05: Temporary pointers

### Code References

Labels are used in these code sections:
- **Character loading**: Bank $01, $018450
- **Battle system**: Bank $0B, $0B8000-$0B9FFF
- **Graphics engine**: Bank $01, $015000-$016FFF
- **Input handling**: Bank $01, $019000-$019FFF
- **Save/Load**: Bank $01, $01A000-$01AFFF

---

## Maintenance

### Keeping RAM_MAP.md In Sync

**When adding new labels**:
1. Add label to appropriate section in this document
2. Update "Labeling Status" percentages
3. Add cross-reference in label index (see LABEL_INDEX.md)
4. Update code references if applicable
5. Commit with message: `labels: Add [label_name] at $[address]`

**When changing labels**:
1. Update all occurrences in this document
2. Update label index cross-references
3. Update code that uses the label
4. Verify ROM still builds
5. Commit with message: `labels: Rename [old] to [new]`

### Related Documentation

- **LABEL_INDEX.md**: Alphabetical cross-reference of all labels
- **ARCHITECTURE.md**: System architecture and memory usage
- **CODE_ORGANIZATION.md**: How code accesses these addresses
- **docs/BATTLE_SYSTEM.md**: Battle system memory layout
- **docs/GRAPHICS_SYSTEM.md**: Graphics memory and VRAM

---

*This document is maintained alongside label additions. Last updated: November 1, 2025*
