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

- **Zero Page / Direct Page ($00-$ff)**: Fastest access, 256 bytes
- **Stack ($0100-$01ff)**: Hardware stack, 256 bytes
- **WRAM Low ($0200-$1fff)**: Fast access, ~7.5 KB
- **WRAM Extended ($7e0000-$7effff)**: Standard access, ~960 KB

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

Bank $00 (Mirror)                Bank $7e (Extended)
┌─────────────────┬──────┐      ┌─────────────────┬──────┐
│ $00-$ff         │ 256B │ ←→   │ $7e:0000-$00ff  │ 256B │
│ Zero Page (DP)  │      │      │ (Same data)     │      │
├─────────────────┼──────┤      ├─────────────────┼──────┤
│ $0100-$01ff     │ 256B │ ←→   │ $7e:0100-$01ff  │ 256B │
│ Stack           │      │      │ (Same data)     │      │
├─────────────────┼──────┤      ├─────────────────┼──────┤
│ $0200-$1fff     │ 7.5K │ ←→   │ $7e:0200-$1fff  │ 7.5K │
│ WRAM Low        │      │      │ (Same data)     │      │
└─────────────────┴──────┘      ├─────────────────┼──────┤
								│ $7e:2000-$ffff  │ 56KB │
								│ Extended only   │      │
								└─────────────────┴──────┘

Memory Layout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$00-$1f     Temporary variables & pointers (32 bytes)
$20-$3f     Graphics/DMA system (32 bytes)
$40-$5f     Player state & map data (32 bytes)
$60-$6f     Controller input (16 bytes)
$70-$8f     Game state & timing (32 bytes)
$90-$bf     Battle system (48 bytes)
$c0-$ff     Miscellaneous (64 bytes)

$0100-$01ff Stack (CPU managed)

$0200-$02ff Inventory system
$0300-$03ff Progress flags
$0400-$07ff Map system caches
$0800-$0bff Battle data
$0c00-$0fff Text system
$1000-$1fff Graphics control

$7e:1000+   Large buffers (OAM, tilemaps, audio)
```

---

## Zero Page ($00-$ff)

### General Temporary ($00-$1f)

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
| $0a | temp_word_1_hi | 1B | Temp word (high) | Medium (10×) |
| $0b | temp_index | 1B | Temp index/counter | - |
| $0c | temp_flags | 1B | Temp flags | Medium (10×) |

### Graphics/DMA ($20-$3f)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $20-$21 | vram_write_addr | 2B | VRAM write address |
| $22 | dma_channel | 1B | Active DMA channel (0-7) |
| $23 | dma_mode | 1B | DMA transfer mode |
| $24-$25 | dma_source | 2B | DMA source address |
| $26 | dma_source_bank | 1B | DMA source bank |
| $27-$28 | dma_size | 2B | DMA transfer size |
| $29 | screen_brightness | 1B | Brightness (0-15) |
| $2a | bg_mode | 1B | BG mode setting |
| $2c-$2f | bg_scroll_x | 4B | BG1/BG2 X scroll |
| $30-$33 | bg_scroll_y | 4B | BG1/BG2 Y scroll |

### Player State ($40-$5f)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $40-$41 | player_x_pos | 2B | Player X position |
| $42-$43 | player_y_pos | 2B | Player Y position |
| $44 | player_direction | 1B | Facing (0=up,1=down,2=left,3=right) |
| $45 | player_speed | 1B | Movement speed |
| $46 | player_state | 1B | Player state |
| $47 | player_animation | 1B | Animation frame |
| $48 | map_id | 1B | Current map ID |
| $49-$4a | map_x_pos, map_y_pos | 2B | Tile coordinates |
| $4b | collision_flags | 1B | Collision results |

### Input ($60-$6f)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $60 | joy1_current | 1B | P1 current buttons |
| $61 | joy1_previous | 1B | P1 previous frame |
| $62 | joy1_pressed | 1B | P1 newly pressed |
| $63 | joy1_held | 1B | P1 held buttons |
| $64-$67 | joy2_* | 4B | Player 2 inputs |

### Game State ($70-$8f)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $70-$71 | frame_counter | 2B | Frame counter |
| $72-$73 | rng_seed | 2B | RNG seed |
| $74 | game_mode | 1B | Title/Field/Battle/Menu |
| $75 | game_state | 1B | Current state |
| $76-$77 | menu_selection, menu_index | 2B | Menu cursors |
| $78 | dialog_state | 1B | Dialog system state |
| $79 | dialog_speed | 1B | Text speed |
| $7a-$7b | text_char_index, text_line | 2B | Text display |
| $7c-$7d | fade_state, fade_timer | 2B | Screen fade |
| $7e-$7f | music_track, sfx_queue | 2B | Audio control |

### Battle System ($90-$bf)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $90-$91 | battle_state, battle_phase | 2B | Battle state |
| $92-$94 | active_character, target_index, command_index | 3B | Battle selection |
| $95-$98 | atb_gauge_* | 4B | ATB gauges (chars + enemies) |
| $99-$9a | damage_value | 2B | Damage calculation |
| $9b-$9d | hit_chance, critical_flag, status_effect | 3B | Battle calculations |
| $9e-$9f | exp_gained | 2B | Post-battle EXP |

---

## WRAM Low ($0200-$1fff)

### Character Data ($7e:0100-$01ff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:0100-$0111 | char1_* | 18B | Benjamin stats (HP, stats, equipment) |
| $7e:0120-$013f | char2_* | 32B | Companion character data |

### Inventory ($7e:0200-$02ff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:0200-$021f | inventory_weapons | 32B | Weapon slots |
| $7e:0220-$023f | inventory_armor | 32B | Armor slots |
| $7e:0240-$025f | inventory_accessories | 32B | Accessory slots |
| $7e:0260-$029f | inventory_consumables | 64B | Consumable items |
| $7e:02A0-$02bf | inventory_key_items | 32B | Key items |
| $7e:02C0-$02cf | inventory_counts | 16B | Item quantities |

### Progress Flags ($7e:0300-$03ff)

All 32-byte bitflag arrays (256 flags each):

- $7e:0300-$031f: story_flags
- $7e:0320-$033f: event_flags
- $7e:0340-$035f: treasure_flags
- $7e:0360-$037f: npc_flags
- $7e:0380-$039f: boss_defeated_flags
- $7e:03A0-$03bf: crystal_flags

### Map System ($7e:0400-$07ff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:0400-$04ff | map_cache_1 | 256B | Map cache slot 1 |
| $7e:0500-$05ff | map_cache_2 | 256B | Map cache slot 2 |
| $7e:0600-$06ff | map_cache_3 | 256B | Map cache slot 3 |
| $7e:0700-$077f | npc_positions | 128B | NPC positions |
| $7e:0780-$07ff | event_data | 128B | Event states |

### Battle Extended ($7e:0800-$0bff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:0800-$087f | enemy_data_1 | 128B | Enemy 1 data |
| $7e:0880-$08ff | enemy_data_2 | 128B | Enemy 2 data |
| $7e:0900-$097f | enemy_data_3 | 128B | Enemy 3 data (optional) |
| $7e:0980-$09ff | enemy_data_4 | 128B | Enemy 4 data (optional) |
| $7e:0A00-$0a7f | battle_state_data | 128B | Battle state |
| $7e:0A80-$0aff | command_queue | 128B | Command queue |

### Text System ($7e:0C00-$0fff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:0C00-$0cff | text_buffer | 256B | Decompressed text |
| $7e:0D00-$0dff | dialog_buffer | 256B | Dialog display |
| $7e:0E00-$0eff | menu_buffer | 256B | Menu text |

### Graphics Control ($0800-$1fff)

Tilemap DMA structures and graphics variables:

| Addr | Label | Usage |
|------|-------|-------|
| $0e89 | wram_0e89 | Medium (12×) |
| $0e91 | wram_0e91 | Medium (10×) |
| $19fa-$1a12 | tilemap_vram_control (set 1) | VRAM DMA control |
| $1a13-$1a2b | tilemap_vram_control_2 (set 2) | VRAM DMA control |

---

## WRAM Extended ($7e0000-$7effff)

### Graphics Buffers ($7e:1000-$6fff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:1000-$11ff | oam_buffer | 512B | Sprite OAM (128 sprites) |
| $7e:1200-$1fff | bg1_tilemap_buffer | 3584B | BG1 tilemap |
| $7e:2000-$2fff | bg2_tilemap_buffer | 4096B | BG2 tilemap |
| $7e:3000-$3fff | bg3_tilemap_buffer | 4096B | BG3/text layer |
| $7e:4000-$4fff | tile_buffer | 4096B | Tile decompression |
| $7e:5000-$5fff | sprite_buffer | 4096B | Sprite data |
| $7e:6000-$6fff | palette_buffer | 4096B | Palette staging |

### Audio System ($7e:8000-$8fff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:8000-$80ff | audio_command_buffer | 256B | Audio commands |
| $7e:8100-$81ff | music_data_buffer | 256B | Music sequences |
| $7e:8200-$82ff | sfx_data_buffer | 256B | SFX data |

### Working Memory ($7e:9000-$ffff)

| Addr | Label | Size | Purpose |
|------|-------|------|---------|
| $7e:9000-$9fff | general_work_1 | 4KB | General working memory |
| $7e:A000-$afff | general_work_2 | 4KB | General working memory |
| $7e:B000-$bfff | general_work_3 | 4KB | General working memory |
| $7e:C000-$cfff | decompression_buffer | 4KB | Data decompression |

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
| 5 | $0e89 | 12 | Medium | wram_0e89 |
| 6 | $000c | 10 | Medium | temp_flags |
| 7 | $000e | 10 | Medium | var_000e |
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
