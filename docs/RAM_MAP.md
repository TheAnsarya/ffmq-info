# FFMQ RAM Memory Map

**Last Updated:** November 1, 2025
**Related Issues:** #24, #28, #3
**Related Files:** `src/include/ffmq_ram_variables.inc`

## Table of Contents

1. [Overview](#overview)
2. [Memory Map Diagram](#memory-map-diagram)
3. [Zero Page](#zero-page-00-ff)
4. [WRAM Low](#wram-low-0200-1fff)
5. [WRAM Extended](#wram-extended-7e0000-7effff)
6. [Usage Statistics](#usage-statistics)

---

## Overview

This document provides a comprehensive map of all RAM (Random Access Memory) variables used in Final Fantasy: Mystic Quest for the SNES.

### Memory Regions

- **Zero Page / Direct Page ($00-$FF)**: Fastest access, 256 bytes
- **Stack ($0100-$01FF)**: Hardware stack, 256 bytes
- **WRAM Low ($0200-$1FFF)**: Fast access, ~7.5 KB
- **WRAM Extended ($7E0000-$7EFFFF)**: Standard access, ~960 KB

### Naming Conventions

All variables follow [LABEL_CONVENTIONS.md](LABEL_CONVENTIONS.md):
- lowercase_snake_case for all RAM variables
- Multi-byte suffixes: `_lo`, `_hi`, `_bank`
- Scope prefixes: `temp_`, `char1_`, `battle_`, etc.

---

## Memory Map Diagram

```
SNES WRAM Map
════════════════════════════════════════════════════════════════

Bank $00 (Mirror)                Bank $7E (Extended)
┌─────────────────┬──────┐      ┌─────────────────┬──────┐
│ $00-$FF         │ 256B │ ←→   │ $7E:0000-$00FF  │ 256B │
│ Zero Page (DP)  │      │      │ (Same data)     │      │
├─────────────────┼──────┤      ├─────────────────┼──────┤
│ $0100-$01FF     │ 256B │ ←→   │ $7E:0100-$01FF  │ 256B │
│ Stack           │      │      │ (Same data)     │      │
├─────────────────┼──────┤      ├─────────────────┼──────┤
│ $0200-$1FFF     │ 7.5K │ ←→   │ $7E:0200-$1FFF  │ 7.5K │
│ WRAM Low        │      │      │ (Same data)     │      │
└─────────────────┴──────┘      ├─────────────────┼──────┤
                                │ $7E:2000-$FFFF  │ 56KB │
                                │ Extended only   │      │
                                └─────────────────┴──────┘

Memory Layout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$00-$1F     Temporary variables & pointers (32 bytes)
$20-$3F     Graphics/DMA system (32 bytes)
$40-$5F     Player state & map data (32 bytes)
$60-$6F     Controller input (16 bytes)
$70-$8F     Game state & timing (32 bytes)
$90-$BF     Battle system (48 bytes)
$C0-$FF     Miscellaneous (64 bytes)

$0100-$01FF Stack (CPU managed)

$0200-$02FF Inventory system
$0300-$03FF Progress flags
$0400-$07FF Map system caches
$0800-$0BFF Battle data
$0C00-$0FFF Text system
$1000-$1FFF Graphics control

$7E:1000+   Large buffers (OAM, tilemaps, audio)
```

---

## Zero Page ($00-$FF)

### General Temporary ($00-$1F)

Most frequently used addresses in the game:

| Addr | Label | Size | Usage | Priority |
|------|-------|------|-------|----------|
| $00 | temp_ptr_1_lo | 1B | Temp pointer 1 (low) | **Critical (60×)** |
| $01 | temp_ptr_1_hi | 1B | Temp pointer 1 (high) | Medium (19×) |
| $02 | temp_ptr_2_lo | 1B | Temp pointer 2 (low) | Medium (14×) |
| $03 | temp_ptr_2_hi | 1B | Temp pointer 2 (high) | - |
| $04 | temp_ptr_3_lo | 1B | Temp pointer 3 (low) | Medium (10×) |
| $05 | temp_ptr_3_hi | 1B | Temp pointer 3 (high) | - |
| $06 | temp_byte_1 | 1B | Temp byte 1 | Medium (10×) |
| $07 | temp_byte_2 | 1B | Temp byte 2 | - |
| $08 | temp_byte_3 | 1B | Temp byte 3 | Medium (10×) |
| $09 | temp_word_1_lo | 1B | Temp word (low) | - |
| $0A | temp_word_1_hi | 1B | Temp word (high) | Medium (10×) |
| $0B | temp_index | 1B | Temp index/counter | - |
| $0C | temp_flags | 1B | Temp flags | Medium (10×) |

### Graphics/DMA ($20-$3F)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $20-$21 | vram_write_addr | 2B | VRAM write address |
| $22 | dma_channel | 1B | Active DMA channel (0-7) |
| $23 | dma_mode | 1B | DMA transfer mode |
| $24-$25 | dma_source | 2B | DMA source address |
| $26 | dma_source_bank | 1B | DMA source bank |
| $27-$28 | dma_size | 2B | DMA transfer size |
| $29 | screen_brightness | 1B | Brightness (0-15) |
| $2A | bg_mode | 1B | BG mode setting |
| $2C-$2F | bg_scroll_x | 4B | BG1/BG2 X scroll |
| $30-$33 | bg_scroll_y | 4B | BG1/BG2 Y scroll |

### Player State ($40-$5F)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $40-$41 | player_x_pos | 2B | Player X position |
| $42-$43 | player_y_pos | 2B | Player Y position |
| $44 | player_direction | 1B | Facing (0=up,1=down,2=left,3=right) |
| $45 | player_speed | 1B | Movement speed |
| $46 | player_state | 1B | Player state |
| $47 | player_animation | 1B | Animation frame |
| $48 | map_id | 1B | Current map ID |
| $49-$4A | map_x_pos, map_y_pos | 2B | Tile coordinates |
| $4B | collision_flags | 1B | Collision results |

### Input ($60-$6F)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $60 | joy1_current | 1B | P1 current buttons |
| $61 | joy1_previous | 1B | P1 previous frame |
| $62 | joy1_pressed | 1B | P1 newly pressed |
| $63 | joy1_held | 1B | P1 held buttons |
| $64-$67 | joy2_* | 4B | Player 2 inputs |

### Game State ($70-$8F)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $70-$71 | frame_counter | 2B | Frame counter |
| $72-$73 | rng_seed | 2B | RNG seed |
| $74 | game_mode | 1B | Title/Field/Battle/Menu |
| $75 | game_state | 1B | Current state |
| $76-$77 | menu_selection, menu_index | 2B | Menu cursors |
| $78 | dialog_state | 1B | Dialog system state |
| $79 | dialog_speed | 1B | Text speed |
| $7A-$7B | text_char_index, text_line | 2B | Text display |
| $7C-$7D | fade_state, fade_timer | 2B | Screen fade |
| $7E-$7F | music_track, sfx_queue | 2B | Audio control |

### Battle System ($90-$BF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $90-$91 | battle_state, battle_phase | 2B | Battle state |
| $92-$94 | active_character, target_index, command_index | 3B | Battle selection |
| $95-$98 | atb_gauge_* | 4B | ATB gauges (chars + enemies) |
| $99-$9A | damage_value | 2B | Damage calculation |
| $9B-$9D | hit_chance, critical_flag, status_effect | 3B | Battle calculations |
| $9E-$9F | exp_gained | 2B | Post-battle EXP |

---

## WRAM Low ($0200-$1FFF)

### Character Data ($7E:0100-$01FF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:0100-$0111 | char1_* | 18B | Benjamin stats (HP, stats, equipment) |
| $7E:0120-$013F | char2_* | 32B | Companion character data |

### Inventory ($7E:0200-$02FF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:0200-$021F | inventory_weapons | 32B | Weapon slots |
| $7E:0220-$023F | inventory_armor | 32B | Armor slots |
| $7E:0240-$025F | inventory_accessories | 32B | Accessory slots |
| $7E:0260-$029F | inventory_consumables | 64B | Consumable items |
| $7E:02A0-$02BF | inventory_key_items | 32B | Key items |
| $7E:02C0-$02CF | inventory_counts | 16B | Item quantities |

### Progress Flags ($7E:0300-$03FF)

All 32-byte bitflag arrays (256 flags each):

- $7E:0300-$031F: story_flags
- $7E:0320-$033F: event_flags
- $7E:0340-$035F: treasure_flags
- $7E:0360-$037F: npc_flags
- $7E:0380-$039F: boss_defeated_flags
- $7E:03A0-$03BF: crystal_flags

### Map System ($7E:0400-$07FF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:0400-$04FF | map_cache_1 | 256B | Map cache slot 1 |
| $7E:0500-$05FF | map_cache_2 | 256B | Map cache slot 2 |
| $7E:0600-$06FF | map_cache_3 | 256B | Map cache slot 3 |
| $7E:0700-$077F | npc_positions | 128B | NPC positions |
| $7E:0780-$07FF | event_data | 128B | Event states |

### Battle Extended ($7E:0800-$0BFF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:0800-$087F | enemy_data_1 | 128B | Enemy 1 data |
| $7E:0880-$08FF | enemy_data_2 | 128B | Enemy 2 data |
| $7E:0900-$097F | enemy_data_3 | 128B | Enemy 3 data (optional) |
| $7E:0980-$09FF | enemy_data_4 | 128B | Enemy 4 data (optional) |
| $7E:0A00-$0A7F | battle_state_data | 128B | Battle state |
| $7E:0A80-$0AFF | command_queue | 128B | Command queue |

### Text System ($7E:0C00-$0FFF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:0C00-$0CFF | text_buffer | 256B | Decompressed text |
| $7E:0D00-$0DFF | dialog_buffer | 256B | Dialog display |
| $7E:0E00-$0EFF | menu_buffer | 256B | Menu text |

### Graphics Control ($0800-$1FFF)

Tilemap DMA structures and graphics variables:

| Addr | Label | Usage |
|------|-------|-------|
| $0E89 | wram_0e89 | Medium (12×) |
| $0E91 | wram_0e91 | Medium (10×) |
| $19FA-$1A12 | tilemap_vram_control (set 1) | VRAM DMA control |
| $1A13-$1A2B | tilemap_vram_control_2 (set 2) | VRAM DMA control |

---

## WRAM Extended ($7E0000-$7EFFFF)

### Graphics Buffers ($7E:1000-$6FFF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:1000-$11FF | oam_buffer | 512B | Sprite OAM (128 sprites) |
| $7E:1200-$1FFF | bg1_tilemap_buffer | 3584B | BG1 tilemap |
| $7E:2000-$2FFF | bg2_tilemap_buffer | 4096B | BG2 tilemap |
| $7E:3000-$3FFF | bg3_tilemap_buffer | 4096B | BG3/text layer |
| $7E:4000-$4FFF | tile_buffer | 4096B | Tile decompression |
| $7E:5000-$5FFF | sprite_buffer | 4096B | Sprite data |
| $7E:6000-$6FFF | palette_buffer | 4096B | Palette staging |

### Audio System ($7E:8000-$8FFF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:8000-$80FF | audio_command_buffer | 256B | Audio commands |
| $7E:8100-$81FF | music_data_buffer | 256B | Music sequences |
| $7E:8200-$82FF | sfx_data_buffer | 256B | SFX data |

### Working Memory ($7E:9000-$FFFF)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7E:9000-$9FFF | general_work_1 | 4KB | General working memory |
| $7E:A000-$AFFF | general_work_2 | 4KB | General working memory |
| $7E:B000-$BFFF | general_work_3 | 4KB | General working memory |
| $7E:C000-$CFFF | decompression_buffer | 4KB | Data decompression |

---

## Usage Statistics

Based on address scanning (see `reports/address_usage_report.csv`):

### Top 10 Most-Used WRAM Addresses

| Rank | Addr | Occurrences | Priority | Label |
|------|------|-------------|----------|-------|
| 1 | $0000 | 60 | **Critical** | temp_ptr_1_lo |
| 2 | $0001 | 19 | Medium | temp_ptr_1_hi |
| 3 | $0010 | 18 | Medium | var_0010 |
| 4 | $0002 | 14 | Medium | temp_ptr_2_lo |
| 5 | $0E89 | 12 | Medium | wram_0e89 |
| 6 | $000C | 10 | Medium | temp_flags |
| 7 | $000E | 10 | Medium | var_000e |
| 8 | $0008 | 10 | Medium | temp_byte_3 |
| 9 | $0006 | 10 | Medium | temp_byte_1 |
| 10 | $0004 | 10 | Medium | temp_ptr_3_lo |

### Distribution

- **Total unique addresses:** 192
- **WRAM:** 123 (64.1%)
- **ROM:** 36 (18.8%)
- **Hardware:** 14 (7.3%)
- **PPU:** 12 (6.3%)

### Priority Levels

- **Critical:** 1 (50+ uses)
- **High:** 7 (10-49 uses)
- **Medium:** 16 (5-19 uses)
- **Low:** 168 (<5 uses)

---

## Cross-References

### Related Documents

- [LABEL_CONVENTIONS.md](LABEL_CONVENTIONS.md) - Naming standards
- [src/include/ffmq_ram_variables.inc](../src/include/ffmq_ram_variables.inc) - Assembly definitions
- [reports/address_usage_report.csv](../reports/address_usage_report.csv) - Detailed statistics

### Related Issues

- #3: Memory Address & Variable Label System (parent)
- #23: Address Inventory and Analysis
- #24: RAM Map Documentation (this doc)
- #28: High Priority WRAM Labels
- #29: Medium Priority WRAM Labels

### Related Tools

- [tools/scan_addresses.ps1](../tools/scan_addresses.ps1) - Address scanner
- [tools/apply_labels.ps1](../tools/apply_labels.ps1) - Label application

---

**End of RAM Map**
