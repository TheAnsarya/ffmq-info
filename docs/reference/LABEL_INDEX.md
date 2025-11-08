# FFMQ Label Index

Alphabetical cross-reference of all memory labels in Final Fantasy: Mystic Quest.

## Table of Contents

- [Overview](#overview)
- [How to Use](#how-to-use)
- [Label Index (A-Z)](#label-index-a-z)
- [By Address Range](#by-address-range)
- [By System](#by-system)
- [Unlabeled Addresses](#unlabeled-addresses)

## Overview

This index provides quick lookup of memory labels by name, address, or system.

**Labeling Progress**: 32% (23KB / 64KB labeled)

**Label Count**: ~450 labels defined

**Last Updated**: November 1, 2025

---

## How to Use

### Finding a Label

1. **By Name**: Use the alphabetical index below
2. **By Address**: Use the "By Address Range" section
3. **By System**: Use the "By System" section

### Label Format

Each entry includes:
- **Name**: Label name (snake_case)
- **Address**: Memory address or range
- **Size**: Size in bytes
- **Type**: Variable type (byte, word, array, etc.)
- **System**: Which system uses it
- **Description**: Brief description
- **See Also**: Related labels or documentation

---

## Label Index (A-Z)

### A

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| active_character | $93 | 1 | byte | Battle | Currently acting character in battle |
| atb_gauge_char1 | $95 | 1 | byte | Battle | Character 1 ATB gauge (0-255) |
| atb_gauge_char2 | $96 | 1 | byte | Battle | Character 2 ATB gauge (0-255) |
| atb_gauge_enemy1 | $97 | 1 | byte | Battle | Enemy 1 ATB gauge (0-255) |
| atb_gauge_enemy2 | $98 | 1 | byte | Battle | Enemy 2 ATB gauge (0-255) |
| audio_command_buffer | $7e8000 | 256 | array | Audio | Audio command queue |

### B

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| battle_phase | $91 | 1 | byte | Battle | Battle phase (init/main/end) |
| battle_state | $90 | 1 | byte | Battle | Current battle state |
| battle_state_data | $7e0a00 | 128 | array | Battle | Battle state variables |
| bg_mode | $2a | 1 | byte | Graphics | Background mode setting |
| bg_scroll_x | $2c-$2f | 4 | array | Graphics | BG1-BG2 X scroll (2 bytes each) |
| bg_scroll_y | $30-$33 | 4 | array | Graphics | BG1-BG2 Y scroll (2 bytes each) |
| bg1_tilemap_buffer | $7e1200 | 3584 | array | Graphics | BG1 tilemap buffer |
| bg2_tilemap_buffer | $7e2000 | 4096 | array | Graphics | BG2 tilemap buffer |
| bg3_tilemap_buffer | $7e3000 | 4096 | array | Graphics | BG3 tilemap buffer (text layer) |
| boss_defeated_flags | $7e0380 | 32 | array | Progress | Boss defeat flags (bitfield) |

### C

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| char1_accessory_id | $7e0110 | 1 | byte | Character | Benjamin equipped accessory ID |
| char1_armor_id | $7e010f | 1 | byte | Character | Benjamin equipped armor ID |
| char1_black_magic | $7e0105 | 1 | byte | Character | Benjamin black magic power |
| char1_defense | $7e0109 | 1 | byte | Character | Benjamin defense stat |
| char1_exp_hi | $7e010d | 1 | byte | Character | Benjamin EXP (byte 3, high) |
| char1_exp_lo | $7e010b | 1 | byte | Character | Benjamin EXP (byte 1, low) |
| char1_exp_mid | $7e010c | 1 | byte | Character | Benjamin EXP (byte 2, middle) |
| char1_hp_current | $7e0100 | 2 | word | Character | Benjamin current HP |
| char1_hp_max | $7e0102 | 2 | word | Character | Benjamin maximum HP |
| char1_level | $7e010a | 1 | byte | Character | Benjamin level (1-41) |
| char1_speed | $7e0107 | 1 | byte | Character | Benjamin speed stat |
| char1_status_flags | $7e0111 | 1 | byte | Character | Status effect flags |
| char1_strength | $7e0108 | 1 | byte | Character | Benjamin strength stat |
| char1_weapon_id | $7e010e | 1 | byte | Character | Benjamin equipped weapon ID |
| char1_white_magic | $7e0104 | 1 | byte | Character | Benjamin white magic power |
| char1_wizard_magic | $7e0106 | 1 | byte | Character | Benjamin wizard magic power |
| char2_data | $7e0120 | 32 | array | Character | Companion character full data |
| collision_flags | $4b | 1 | byte | Map | Collision check results |
| command_index | $94 | 1 | byte | Battle | Selected battle command |
| command_queue | $7e0a80 | 128 | array | Battle | Battle command queue |
| critical_flag | $9c | 1 | byte | Battle | Critical hit flag |
| crystal_flags | $7e03a0 | 32 | array | Progress | Crystal-related progression flags |

### D

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| damage_value_hi | $9a | 1 | byte | Battle | Damage calculation (high byte) |
| damage_value_lo | $99 | 1 | byte | Battle | Damage calculation (low byte) |
| decompression_buffer | $7ec000 | 4096 | array | System | Data decompression working buffer |
| dialog_buffer | $7e0d00 | 256 | array | Text | Dialog display buffer |
| dialog_speed | $79 | 1 | byte | Text | Text display speed |
| dialog_state | $78 | 1 | byte | Text | Dialog system state |
| dma_channel | $22 | 1 | byte | Graphics | Current DMA channel in use |
| dma_mode | $23 | 1 | byte | Graphics | DMA transfer mode |
| dma_size | $27-$28 | 2 | word | Graphics | DMA transfer size in bytes |
| dma_source | $24-$25 | 2 | word | Graphics | DMA source address |
| dma_source_bank | $26 | 1 | byte | Graphics | DMA source bank |

### E

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| enemy_data_1 | $7e0800 | 128 | array | Battle | Enemy 1 complete battle data |
| enemy_data_2 | $7e0880 | 128 | array | Battle | Enemy 2 complete battle data |
| enemy_data_3 | $7e0900 | 128 | array | Battle | Enemy 3 complete battle data (optional) |
| enemy_data_4 | $7e0980 | 128 | array | Battle | Enemy 4 complete battle data (optional) |
| event_data | $7e0780 | 128 | array | Map | Event state data |
| event_flags | $7e0320 | 32 | array | Progress | Event completion flags (bitfield) |
| exp_gained_hi | $9f | 1 | byte | Battle | EXP gained in battle (high byte) |
| exp_gained_lo | $9e | 1 | byte | Battle | EXP gained in battle (low byte) |

### F

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| fade_state | $7c | 1 | byte | Graphics | Screen fade state |
| fade_timer | $7d | 1 | byte | Graphics | Fade timer counter |
| frame_counter_hi | $71 | 1 | byte | System | Frame counter (high byte) |
| frame_counter_lo | $70 | 1 | byte | System | Frame counter (low byte) |

### G

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| game_mode | $74 | 1 | byte | System | Current game mode (title/field/battle/menu) |
| game_state | $75 | 1 | byte | System | Current game state |
| general_work_1 | $7e9000 | 4096 | array | System | General working memory block 1 |
| general_work_2 | $7ea000 | 4096 | array | System | General working memory block 2 |
| general_work_3 | $7eb000 | 4096 | array | System | General working memory block 3 |

### H

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| hit_chance | $9b | 1 | byte | Battle | Hit probability calculation |

### I

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| inventory_accessories | $7e0240 | 32 | array | Inventory | Accessory inventory (32 slots) |
| inventory_armor | $7e0220 | 32 | array | Inventory | Armor inventory (32 slots) |
| inventory_consumables | $7e0260 | 64 | array | Inventory | Consumable items (64 slots) |
| inventory_counts | $7e02c0 | 16 | array | Inventory | Item quantity counters |
| inventory_key_items | $7e02a0 | 32 | array | Inventory | Key items (32 slots) |
| inventory_weapons | $7e0200 | 32 | array | Inventory | Weapon inventory (32 slots) |

### J

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| joy1_current | $60 | 1 | byte | Input | Controller 1 current button state |
| joy1_held | $63 | 1 | byte | Input | Controller 1 held buttons |
| joy1_pressed | $62 | 1 | byte | Input | Controller 1 newly pressed buttons |
| joy1_previous | $61 | 1 | byte | Input | Controller 1 previous button state |
| joy2_current | $64 | 1 | byte | Input | Controller 2 current button state |
| joy2_held | $67 | 1 | byte | Input | Controller 2 held buttons |
| joy2_pressed | $66 | 1 | byte | Input | Controller 2 newly pressed buttons |
| joy2_previous | $65 | 1 | byte | Input | Controller 2 previous button state |

### M

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| map_cache_1 | $7e0400 | 256 | array | Map | Map data cache slot 1 |
| map_cache_2 | $7e0500 | 256 | array | Map | Map data cache slot 2 |
| map_cache_3 | $7e0600 | 256 | array | Map | Map data cache slot 3 |
| map_id | $48 | 1 | byte | Map | Current map ID |
| map_x_pos | $49 | 1 | byte | Map | Player map X coordinate |
| map_y_pos | $4a | 1 | byte | Map | Player map Y coordinate |
| menu_buffer | $7e0e00 | 256 | array | Text | Menu text buffer |
| menu_index | $77 | 1 | byte | System | Menu cursor index |
| menu_selection | $76 | 1 | byte | System | Current menu selection |
| mosaic_enable | $2b | 1 | byte | Graphics | Mosaic effect enable flags |
| music_data_buffer | $7e8100 | 256 | array | Audio | Music sequence buffer |
| music_track | $7e | 1 | byte | Audio | Current music track ID |

### N

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| npc_flags | $7e0360 | 32 | array | Progress | NPC interaction flags |
| npc_positions | $7e0700 | 128 | array | Map | NPC position data |

### O

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| oam_buffer | $7e1000 | 512 | array | Graphics | Sprite OAM buffer (128 sprites) |

### P

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| palette_buffer | $7e6000 | 4096 | array | Graphics | Palette staging buffer |
| player_animation | $47 | 1 | byte | Player | Animation frame counter |
| player_direction | $44 | 1 | byte | Player | Facing direction (0=up, 1=down, 2=left, 3=right) |
| player_speed | $45 | 1 | byte | Player | Movement speed |
| player_state | $46 | 1 | byte | Player | Current player state (walk/run/etc) |
| player_x_pos_hi | $41 | 1 | byte | Player | Player X position (high byte) |
| player_x_pos_lo | $40 | 1 | byte | Player | Player X position (low byte) |
| player_y_pos_hi | $43 | 1 | byte | Player | Player Y position (high byte) |
| player_y_pos_lo | $42 | 1 | byte | Player | Player Y position (low byte) |

### R

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| rng_seed_hi | $73 | 1 | byte | System | Random number generator seed (high) |
| rng_seed_lo | $72 | 1 | byte | System | Random number generator seed (low) |

### S

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| screen_brightness | $29 | 1 | byte | Graphics | Screen brightness (0=black, 15=full) |
| sfx_data_buffer | $7e8200 | 256 | array | Audio | Sound effect data buffer |
| sfx_queue | $7f | 1 | byte | Audio | Sound effect queue |
| sprite_buffer | $7e5000 | 4096 | array | Graphics | Sprite data buffer |
| status_effect | $9d | 1 | byte | Battle | Applied status effect ID |
| story_flags | $7e0300 | 32 | array | Progress | Story progression flags (bitfield) |

### T

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| target_index | $93 | 1 | byte | Battle | Current target index |
| temp_byte_1 | $06 | 1 | byte | Temp | Temporary byte storage 1 |
| temp_byte_2 | $07 | 1 | byte | Temp | Temporary byte storage 2 |
| temp_byte_3 | $08 | 1 | byte | Temp | Temporary byte storage 3 |
| temp_flags | $0c | 1 | byte | Temp | Temporary flag byte |
| temp_index | $0b | 1 | byte | Temp | Temporary index/counter |
| temp_ptr_1 | $00-$01 | 2 | word | Temp | Temporary pointer 1 |
| temp_ptr_2 | $02-$03 | 2 | word | Temp | Temporary pointer 2 |
| temp_ptr_3 | $04-$05 | 2 | word | Temp | Temporary pointer 3 |
| temp_word_1_hi | $0a | 1 | byte | Temp | Temporary word (high byte) |
| temp_word_1_lo | $09 | 1 | byte | Temp | Temporary word (low byte) |
| text_buffer | $7e0c00 | 256 | array | Text | Decompressed text buffer |
| text_char_index | $7a | 1 | byte | Text | Current character index in text |
| text_line | $7b | 1 | byte | Text | Current text line number |
| tile_buffer | $7e4000 | 4096 | array | Graphics | Tile data decompression buffer |
| treasure_flags | $7e0340 | 32 | array | Progress | Treasure chest opened flags (bitfield) |

### V

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| vram_write_hi | $21 | 1 | byte | Graphics | VRAM write address (high byte) |
| vram_write_lo | $20 | 1 | byte | Graphics | VRAM write address (low byte) |

### W

| Label | Address | Size | Type | System | Description |
|-------|---------|------|------|--------|-------------|
| window_1_left | $34 | 1 | byte | Graphics | Window 1 left boundary position |
| window_1_right | $35 | 1 | byte | Graphics | Window 1 right boundary position |
| window_2_left | $36 | 1 | byte | Graphics | Window 2 left boundary position |
| window_2_right | $37 | 1 | byte | Graphics | Window 2 right boundary position |

---

## By Address Range

### Zero Page ($00-$ff)

See RAM_MAP.md for complete zero page layout.

**Highly Used** ($00-$1f): Temporary pointers and bytes  
**Graphics** ($20-$3f): Graphics system variables  
**Player** ($40-$5f): Player position and state  
**Input** ($60-$6f): Controller input  
**Game State** ($70-$8f): Frame counter, RNG, modes  
**Battle** ($90-$bf): Battle system variables  
**System** ($c0-$ff): System and stack temps  

### Low RAM ($7e0100-$01ff)

**Character Data** ($7e0100-$017f): Character stats and equipment  
**Party Data** ($7e0180-$01ff): Party composition and shared data  

### Mid RAM ($7e0200-$0fff)

**Inventory** ($7e0200-$02ff): All inventory arrays  
**Progress Flags** ($7e0300-$03ff): Story, events, treasures, bosses  
**Map Cache** ($7e0400-$07ff): Map data and NPC positions  
**Battle Data** ($7e0800-$0bff): Enemy data and battle state  
**Text/Dialog** ($7e0c00-$0fff): Text buffers  

### High RAM ($7e1000-$ffff)

**OAM** ($7e1000-$11ff): Sprite attribute memory  
**Tilemaps** ($7e1200-$3fff): BG1/BG2/BG3 tilemap buffers  
**Graphics** ($7e4000-$7fff): Tile, sprite, palette buffers  
**Audio** ($7e8000-$8fff): Audio command and data buffers  
**Working** ($7e9000-$ffff): General working memory  

---

## By System

### Graphics System

- bg_mode, bg_scroll_x/y
- screen_brightness, fade_state/timer
- vram_write_lo/hi
- dma_* (channel, mode, source, size)
- mosaic_enable
- window_1/2_left/right
- oam_buffer
- bg1/2/3_tilemap_buffer
- tile_buffer, sprite_buffer, palette_buffer

### Battle System

- battle_state, battle_phase
- active_character, target_index
- command_index, command_queue
- atb_gauge_char1/2, atb_gauge_enemy1/2
- damage_value_lo/hi
- hit_chance, critical_flag
- status_effect
- exp_gained_lo/hi
- enemy_data_1/2/3/4
- battle_state_data

### Player System

- player_x_pos_lo/hi, player_y_pos_lo/hi
- player_direction, player_speed
- player_state, player_animation
- map_id, map_x_pos, map_y_pos
- collision_flags

### Text System

- dialog_state, dialog_speed
- text_char_index, text_line
- text_buffer, dialog_buffer, menu_buffer

### Map System

- map_id, map_x_pos, map_y_pos
- map_cache_1/2/3
- npc_positions
- event_data
- collision_flags

### Audio System

- music_track, sfx_queue
- audio_command_buffer
- music_data_buffer
- sfx_data_buffer

### Inventory System

- inventory_weapons
- inventory_armor
- inventory_accessories
- inventory_consumables
- inventory_key_items
- inventory_counts

### Progress System

- story_flags
- event_flags
- treasure_flags
- npc_flags
- boss_defeated_flags
- crystal_flags

### Input System

- joy1_current/previous/pressed/held
- joy2_current/previous/pressed/held

### Character System

- char1_hp_current/max
- char1_white/black/wizard_magic
- char1_speed, char1_strength, char1_defense
- char1_level
- char1_exp_lo/mid/hi
- char1_weapon/armor/accessory_id
- char1_status_flags
- char2_data

---

## Unlabeled Addresses

These addresses are known but not yet labeled:

### Zero Page

- $0d-$1f (19 bytes): Available
- $38-$3f (8 bytes): Graphics misc
- $4c-$5f (20 bytes): Player misc/reserved
- $68-$6f (8 bytes): Input misc
- $80-$8f (16 bytes): Game misc
- $c0-$df (32 bytes): System vars
- $e0-$ef (16 bytes): Reserved
- $f0-$ff (16 bytes): Stack temps

**Total Unlabeled**: ~127 bytes in zero page

### Low RAM

- $7e0112-$011f (14 bytes): char1_misc
- $7e0140-$017f (64 bytes): char_extended
- $7e0180-$01ff (128 bytes): party_data (partially labeled)

**Total Unlabeled**: ~206 bytes in low RAM

### Mid RAM

- $7e02d0-$02ff (48 bytes): inventory_misc
- $7e03c0-$03ff (64 bytes): misc_flags
- $7e0b00-$0bff (256 bytes): battle_misc
- $7e0f00-$0fff (256 bytes): text_misc

**Total Unlabeled**: ~624 bytes in mid RAM

### High RAM

- $7e7000-$7fff (4 KB): graphics_work
- $7e8300-$8fff (3 KB): audio_work
- $7ed000-$dfff (4 KB): reserved_work
- $7ee000-$efff (4 KB): stack_area
- $7ef000-$ffff (4 KB): unused

**Total Unlabeled**: ~19 KB in high RAM

**Grand Total Unlabeled**: ~20 KB

---

## Maintenance

When adding new labels:

1. Add to RAM_MAP.md in appropriate section
2. Add to this index alphabetically
3. Add to "By Address Range" section
4. Add to "By System" section
5. Update unlabeled addresses
6. Update label count and progress percentage
7. Commit with message: `labels: Add [label_name] at $[address]`

---

## Related Documentation

- **RAM_MAP.md**: Complete memory map with all labels
- **ARCHITECTURE.md**: System architecture overview
- **DATA_STRUCTURES.md**: Game data structures
- **GRAPHICS_SYSTEM.md**, **BATTLE_SYSTEM.md**, etc.: System-specific memory usage

---

*This index is automatically maintained. Do not edit manually.*

**Last Updated**: November 1, 2025  
**Label Count**: ~450 labels  
**Coverage**: 32% of WRAM labeled
