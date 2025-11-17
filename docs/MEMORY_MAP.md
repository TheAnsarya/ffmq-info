# Final Fantasy Mystic Quest - Complete Memory Map

## Overview

This document provides a comprehensive mapping of all RAM variables, buffers, and system memory used in Final Fantasy Mystic Quest (FFMQ) for the SNES. Memory ranges from zero page ($00-$FF) through extended WRAM ($7E0000-$7EFFFF).

---

## Table of Contents

1. [Zero Page ($00-$FF)](#zero-page-00-ff)
2. [Low WRAM ($0100-$0FFF)](#low-wram-0100-0fff)
3. [Extended WRAM ($1000-$1FFF)](#extended-wram-1000-1fff)
4. [High WRAM ($2000-$6FFF)](#high-wram-2000-6fff)
5. [WRAM Mirror ($7E0000-$7EFFFF)](#wram-mirror-7e0000-7effff)
6. [System Categories](#system-categories)
7. [Usage Statistics](#usage-statistics)

---

## Zero Page ($00-$FF)

The zero page provides fast direct-page addressing for frequently accessed variables.

### Core System Registers ($00-$2F)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $00 | `!dp_base` | Direct page base address | 2 | Initialization |
| $10-$21 | Entity system | Entity state/status registers | 18 | High |
| $22-$28 | `!dma_*` | DMA channel/mode/source/size | 7 | High |

### Graphics Processing ($30-$6F)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $38-$39 | Calculation parameters | Calculation type/param | 2 | Medium |
| $42-$4A | Graphics registers | Graphics processing (5×2 bytes) | 10 | High |
| $4C-$52 | State registers | State/calculation params | 7 | High |
| $58 | `!sys_pointer_58` | System pointer | 2 | Medium |
| $5A | `!sys_pointer_5a` | System pointer | 2 | Medium |
| $64 | `!sys_pointer_64` | System pointer | 2 | Medium |

### System Variables ($70-$FF)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $76 | Control state | Control state register | 1 | High |
| $7C | Entity data | Entity data array (indexed) | varies | High |
| $89-$95 | Calculation system | Entity counters/flags | 13 | High |
| $8B | `!current_entity` | Current entity ID | 1 | Very High |
| $8D-$91 | Calculation indices | Calc mode/index/execution | 5 | High |
| $94 | System flags | Validation/status flags | 1 | High |
| $95 | Cleanup status | Cleanup status register | 1 | High |
| $B2 | `!gfx_processing_b2` | Graphics processing | 1 | High |
| $B3 | `!gfx_processing_b3` | Graphics processing | 1 | High |
| $B4 | `!gfx_processing_b4` | Graphics processing | 1 | High |
| $B5 | `!gfx_processing_b5` / validation counter | Graphics processing | 1 | High |
| $DE | `!calculation_mode` | Calculation mode | 1 | Medium |
| $EF | `!gfx_processing_ef` | Graphics processing | 1 | Medium |

---

## Low WRAM ($0100-$0FFF)

Standard WRAM for game state, buffers, and system variables.

### System State ($0100-$01FF)

| Address Range | Label | Purpose | Size | Usage |
|---------------|-------|---------|------|-------|
| $0105-$0118 | System interrupts & DMA | Interrupt/DMA management | 20 | High |
| $01EB-$01F8 | DMA transfer parameters | DMA size/dest/source params | 14 | High |

### Audio System ($0200-$02FF)

| Address Range | Label | Purpose | Size | Usage |
|---------------|-------|---------|------|-------|
| $0200-$0207 | `!audio_channel_*` | SPC700 audio channel params (8 channels) | 8 | High |
| $0220-$0227 | `!audio_ram_*` | SPC700 RAM start/end addresses | 8 | High |
| $0240-$0247 | `!audio_pattern_size` | Pattern data sizes (8 channels) | 8 | Medium |
| $0260-$0267 | `!audio_pattern_buffer` | Pattern buffer slots (8 channels) | 8 | Medium |
| $0628 | `!audio_channel_assign` | Audio channel assignments | 8 | High |
| $0648 | `!audio_ram_addr_start` | SPC700 RAM start addresses | 8 | High |
| $064A | `!audio_ram_addr_end` | SPC700 RAM end addresses | 8 | High |
| $0668 | `!audio_pattern_size` | Pattern data sizes | 8 | High |
| $0688 | `!audio_pattern_buffer` | Pattern buffer slots | 8 | High |

### System Variables ($0400-$04FF)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0402 | `!sys_pointer_402` | System pointer | 2 | Medium |
| $0410-$0411 | Base/flags registers | Calculation base/flags | 2 | High |
| $0417 | `!sys_command_status` | Command status register | 1 | High |
| $0438-$0439 | Parameter set | Calculation type/param | 2 | Medium |
| $048F-$0495 | Iteration/status | Iteration counter, flags | 7 | High |
| $04A4 | `!sys_work_buffer_count` | Graphics buffer counter | 1 | High |
| $04A5 | `!sys_work_control` | Working control value | 1 | High |
| $04A7 | `!sys_work_register` | Temporary processing register | 1 | Very High |
| $04B3 | `!sys_work_result` | Working result storage | 1 | High |
| $04DE | Calculation mode | Calculation mode storage | 1 | Medium |
| $050C | `!sys_param_1` | System parameter 1 | 1 | Medium |
| $050D | `!sys_param_2` | System parameter 2 | 1 | Medium |

### Graphics Sprite Buffers ($0800-$09FF)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0802 | `!gfx_sprite_buffer_1` | Sprite buffer 1 | varies | High |
| $0880 | `!gfx_sprite_buffer_2` | Sprite buffer 2 | varies | High |
| $0882 | `!gfx_sprite_buffer_3` | Sprite buffer 3 | varies | High |
| $0902 | `!gfx_sprite_buffer_4` | Alternate/memory buffer | varies | High |
| $0980 | `!gfx_sprite_buffer_5` | Alternate buffer | varies | Medium |
| $0982 | `!gfx_sprite_buffer_6` | Alternate buffer | varies | Medium |

### DMA Parameters ($0900-$09FF)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0903 | `!dma_dest_addr_param` | DMA destination parameter | 3 | High |

### Controller & System State ($0A00-$0AFF)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0A02 | `!controller_input_array` | Controller data array (indexed) | varies | Very High |
| $0A07 | `!controller_data_alt_1` | Controller data indexed ($0a07,x) | varies | High |
| $0A0A | `!controller_data_alt_2` | Controller data indexed ($0a0a,x) | varies | High |
| $0A1C | `!sys_state_data` | System state data | 2 | Medium |
| $0A25 | `!gfx_position_x` | Graphics X position | 2 | High |
| $0A26 | `!gfx_position_y` | Graphics Y position | 2 | High |
| $0A29 | `!gfx_position_x_alt` | Secondary X position | 2 | Medium |
| $0A2A | `!gfx_position_y_alt` | Secondary Y position | 2 | Medium |
| $0A70 | `!sys_memory_addr` | System memory address | 2 | Medium |
| $0A79 | `!sys_multiplier` | System multiplier | 2 | Medium |
| $0A7E | `!display_flag` | Display flag | 1 | Medium |
| $0A8B | `!gfx_system_addr` | Graphics system address | 2 | High |
| $0A91 | `!gfx_coord_x` | Graphics X coordinate | 2 | High |
| $0A92 | `!gfx_coord_y` | Graphics Y coordinate | 2 | High |
| $0A94 | `!gfx_pattern_counter` | Graphics pattern counter (shifted ×4) | 2 | High |
| $0A9C | `!gfx_sprite_mode` | Graphics sprite mode | 1 | High |
| $0A9D | `!gfx_sprite_base` | Graphics sprite base | 1 | High |
| $0A9F | `!gfx_special_flag` | Graphics special flag | 1 | Medium |
| $0AA0 | `!gfx_param_mode` | Graphics parameter mode | 1 | Medium |
| $0AA2 | `!sys_control_aa2` | System control variable | 1 | Medium |
| $0AAA | `!sys_control_aaa` | System control variable | 1 | Medium |
| $0AAB | `!sys_control_aab` | System control variable | 1 | Medium |
| $0AAE | `!sys_control_aae` | System control variable | 1 | Medium |
| $0AB0 | `!sys_control_ab0` | System control variable | 1 | Medium |
| $0ADE | `!sprite_obj_index_1` | Primary sprite object index | 1 | High |
| $0ADF | `!sprite_obj_index_2` | Secondary sprite object index | 1 | High |
| $0AE9 | `!gfx_index` | Graphics index | 1 | Medium |
| $0AEE | `!sprite_config` | Sprite configuration | 1 | Medium |
| $0AF0 | `!frame_counter_ext` | Extended frame counter | 1 | High |
| $0AF4 | `!processing_flag_2` | Processing flag 2 | 1 | Medium |
| $0AF5 | `!processing_flag_3` | Processing flag 3 | 1 | Medium |
| $0AF8 | `!processing_flag_4` | Processing flag 4 | 1 | Medium |

### OAM Sprite Buffer ($0C00-$0CFF)

| Address Range | Label | Purpose | Size | Usage |
|---------------|-------|---------|------|-------|
| $0C00 | `!oam_sprite_buffer` | OAM sprite buffer base (128 sprites × 4 bytes) | 512 | Very High |
| $0C00-$0C03 | Sprite 0 | X, Y, tile, attributes | 4 | Very High |
| $0C04-$0C07 | Sprite 1 | X, Y, tile, attributes | 4 | High |
| $0C08-$0C0B | Sprite 2 | X, Y, tile, attributes | 4 | High |
| $0C0C-$0C0F | Sprite 3 | X, Y, tile, attributes | 4 | High |
| ... | ... | Continues for 128 sprites | ... | ... |

### Battle State Registers ($0C50-$0C5F)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0C50 | `!battle_state_c50` | Battle state register | 1 | High |
| $0C51 | `!sprite_data_c51` | Sprite data register | 1 | High |
| $0C52-$0C5F | `!battle_state_c52` through `!battle_state_c5f` | Battle state registers | 14 | High |

### Battle Coordinates ($0C60-$0C6D)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0C60-$0C61 | `!battle_coord_x_lo/hi` | Battle X coordinate | 2 | High |
| $0C64-$0C65 | `!battle_coord_y_lo/hi` | Battle Y coordinate | 2 | High |
| $0C68-$0C69 | `!battle_coord_z_lo/hi` | Battle Z coordinate | 2 | Medium |
| $0C6C-$0C6D | `!battle_coord_w_lo/hi` | Battle W coordinate | 2 | Medium |

### DMA Graphics Coordinates ($0CD0-$0CDC)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $0CD0 | `!dma_dest_addr` | DMA destination X coordinate | 2 | High |
| $0CD4 | `!dma_source_addr` | DMA source X+8 coordinate | 2 | High |
| $0CD8 | `!dma_dest_addr_alt` | DMA source high (with VRAM offset) | 2 | High |
| $0CDC | `!dma_source_addr_alt` | DMA destination high (with VRAM page offset) | 2 | High |

### Graphics Registers ($0C80-$0CFF)

| Address Range | Label | Purpose | Size | Usage |
|---------------|-------|---------|------|-------|
| $0C80-$0C98 | `!gfx_register_*` | Graphics processing registers (15 registers) | 30 | Very High |
| $0CC0-$0CCD | `!vram_tile_*` | VRAM tile addresses (8 addresses) | 16 | High |
| $0CC2 | `!sprite_tile_cc2` | Sprite tile register | 2 | High |
| $0CC6 | `!sprite_tile_cc6` | Sprite tile register | 2 | High |
| $0CCA | `!sprite_tile_cca` | Sprite tile register | 2 | High |
| $0CCE | `!sprite_tile_cce` | Sprite tile register | 2 | High |

### Graphics Tile Data Buffers ($0CEF4-$0D174)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $CEF4 | `!wram_buffer_cef4` | Graphics tile buffer 1 (indexed) | varies | High |
| $CEF6 | `!wram_buffer_cef6` | Graphics tile buffer 2 (offset +2) | varies | High |
| $D0F4 | `!wram_buffer_d0f4` | Graphics tile buffer 3 | varies | Medium |
| $D174 | `!wram_buffer_d174` | Graphics tile buffer 4 | varies | Medium |

### Extended Data Storage

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $C588 | `!wram_buffer_c588` | WRAM data buffer (indexed) | varies | Medium |
| $F0F0 | `!wram_buffer_f0f0` | Extended data buffer (high WRAM) | varies | Low |

---

## Extended WRAM ($1000-$1FFF)

Extended working RAM for larger buffers and system state.

### System Status ($1020-$10B0)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1020 | `!sys_status_register` | System status register (read/write) | 2 | High |
| $10A5 | `!sys_timing_param` | Timing parameter | 1 | Medium |
| $10B0 | `!sys_state_1` | System state register | 1 | Medium |

### Graphics Buffer Array ($1144-$115C)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1144-$115C | `!gfx_buffer_1144` through `!gfx_buffer_115c` | Graphics buffers (7 word values) | 14 | High |

### Sprite Management ($1500-$1502)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1500 | `!sprite_output_var` | Sprite output variable | 2 | Medium |
| $1502 | `!sprite_target_id` | Target sprite ID for comparison | 2 | Medium |

### Layer Scroll Positions ($190C-$190E)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $190C | `!layer1_scroll_x` | Layer 1 scroll X position | 2 | High |
| $190E | `!layer2_scroll_x` | Layer 2 scroll X position | 2 | High |

### Background and Map Variables ($19AB-$19D8)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $19AB | `!bg_variable_19ab` | Background variable | 2 | Medium |
| $19B2 | `!bg_map_ptr_19b2` | Background map pointer | 2 | Medium |
| $1953 | `!bg_data_1953` | Background data | 2 | Medium |
| $19D8 | `!bg_variable_19d8` | Background variable | 2 | Medium |

### Tilemap Configuration ($1A4D-$1A50)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1A4D | `!bg2_tilemap_config` | BG2 tilemap configuration | 1 | High |
| $1A50 | `!color_math_control` | Color math control / layer config 0 | 1 | High |

### Memory Graphics System ($1A18-$1A2C)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1A18 | `!mem_gfx_flags` | Memory graphics flags | 2 | High |
| $1A1A | `!mem_gfx_final` | Memory graphics final | 2 | High |
| $1A20 | `!mem_gfx_buffer_sec` | Memory graphics buffer secondary | 2 | High |
| $1A22 | `!mem_gfx_ext_sec` | Memory graphics extended secondary | 2 | High |
| $1A2C | `!gfx_completion_mode` | Graphics completion mode counter | 2 | High |

### Final Attribute Storage ($1A3E)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1A3E | `!sprite_final_attrs` | Final sprite attribute result (indexed) | varies | High |

### Sprite Property Arrays ($1A73-$1A79)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $1A73 | `!sprite_x_array` | Sprite X position array (indexed) | varies | Very High |
| $1A75 | `!sprite_y_array` | Sprite Y position array (indexed) | varies | Very High |
| $1A77 | `!sprite_tile_array` | Sprite tile index array (indexed) | varies | Very High |
| $1A79 | `!sprite_attrs_array` | Sprite attributes array (indexed) | varies | Very High |

---

## High WRAM ($2000-$6FFF)

### Delta Calculation Buffers ($3671-$36A9)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $3671 | `!delta_buffer_base` | Delta buffer base (indexed +0, +1) | varies | High |
| $3679 | `!delta_buffer_1` | Delta buffer 1 (indexed) | varies | High |
| $3689 | `!delta_buffer_2` | Delta buffer 2 (indexed) | varies | High |
| $3699 | `!delta_buffer_3` | Delta buffer 3 (indexed) | varies | High |
| $36A9 | `!delta_buffer_4` | Delta buffer 4 (indexed) | varies | High |

### Color Palette Buffer ($5011-$5027)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $5011 | `!color_buffer_5011` | Color buffer offset $11 | 2 | Medium |
| $5014 | `!color_buffer_5014` | Color buffer offset $14 | 2 | Medium |
| $5017 | `!color_adjusted_5017` | Adjusted color storage | 2 | Medium |
| $501A | `!color_buffer_501a` | Color buffer offset $1a | 2 | Medium |
| $501E | `!color_buffer_501e` | Color buffer offset $1e | 2 | Medium |
| $5021 | `!color_buffer_5021` | Color buffer offset $21 | 2 | Medium |
| $5024 | `!color_adjusted_5024` | Adjusted color storage 2 | 2 | Medium |
| $5027 | `!color_buffer_5027` | Color buffer offset $27 | 2 | Medium |

---

## WRAM Mirror ($7E0000-$7EFFFF)

The $7E bank mirrors WRAM at $0000-$1FFF, but also contains extended high WRAM from $2000+.

### Save System State ($7E3665-$7E3668)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $7E3665 | `!save_state_flag` | Save state flag / screen ready flag | 1 | High |
| $7E3667 | `!save_file_flag_1` | Save file state flag 1 | 1 | Medium |
| $7E3668 | `!save_file_flag_2` | Save file state flag 2 ($FF = set) | 1 | Medium |

### Sprite System Arrays ($7EC260-$7EC480)

These are indexed sprite management arrays accessed with `,x` indexing.

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $7EC260 | `!sprite_slot_array` | Sprite slot index array | varies | Very High |
| $7EC320 | `!sprite_base_array` | Sprite base index / X-position array | varies | Very High |
| $7EC360 | `!sprite_frame_array` | Animation frame counter array | varies | Very High |
| $7EC400 | `!sprite_state_array` | Sprite state / animation state array | varies | Very High |
| $7EC480 | `!sprite_tile_id_array` | Base tile index / channel array | varies | Very High |

### Graphics System State ($7EC240-$7EC380)

Graphics processing and control arrays.

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $7EC240 | `!gfx_state_control` | Graphics state/control register | varies | Very High |
| $7EC280 | `!gfx_result_data` | Graphics result/data storage | varies | Very High |
| $7EC2A0 | `!gfx_param_buffer` | Graphics parameter/buffer control | varies | Very High |
| $7EC2E0 | `!gfx_channel_state` | Channel state register | varies | High |
| $7EC300 | `!gfx_mode_register` | Graphics mode register | varies | Very High |
| $7EC340 | `!gfx_mode_buffer` | Graphics mode/buffer size | varies | Very High |
| $7EC380 | `!gfx_buffer_main` | Main graphics buffer | varies | Very High |

### Graphics Extended System ($7EC440-$7EC460)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $7EC440 | `!gfx_base_addr` | Graphics base address / coordinate data | varies | Very High |
| $7EC460 | `!gfx_pattern_index` | Graphics pattern index / extended memory | varies | Very High |

### Sound System ($7EC580-$7EC5C0)

| Address | Label | Purpose | Size | Usage |
|---------|-------|---------|------|-------|
| $7EC580 | `!sound_param` | Sound parameter | varies | High |
| $7EC5A0 | `!sound_result` | Sound result | varies | High |
| $7EC5C0 | `!sound_processed` | Processed sound data | varies | High |

---

## System Categories

### Audio System

**Total Labels:** 10 labels  
**Memory Range:** $0200-$0688  
**Key Components:**
- SPC700 channel parameters (8 channels)
- RAM start/end addresses
- Pattern data sizes
- Pattern buffer slots

**Usage:** Audio playback, music synthesis, SFX

### Graphics System

**Total Labels:** 80+ labels  
**Memory Ranges:** 
- Zero page: $42-$4A, $B2-$B5, $EF
- Low WRAM: $0800-$0982, $0A00-$0AFF, $0C80-$0CFF
- Extended WRAM: $1A18-$1A79
- High WRAM: $7EC240-$7EC460

**Key Components:**
- Sprite buffers (6 buffers)
- Graphics registers (15+ registers)
- Position coordinates (X/Y primary/secondary)
- Pattern counters and indices
- VRAM tile addresses
- Graphics state/control/mode
- Graphics buffers and processing

**Usage:** All graphics rendering, sprite management, tilemap display

### Battle System

**Total Labels:** 20+ labels  
**Memory Range:** $0C50-$0CDC  
**Key Components:**
- Battle state registers (16 registers)
- Battle coordinates (X, Y, Z, W)
- DMA graphics coordinates (4 addresses)

**Usage:** Combat mechanics, sprite positioning, battle graphics

### Controller System

**Total Labels:** 4 labels  
**Memory Range:** $0A02-$0A0A  
**Key Components:**
- Primary input array
- Alternative access patterns (2 arrays)

**Usage:** Input processing, controller reading

### DMA System

**Total Labels:** 15+ labels  
**Memory Ranges:** $22-$28 (zero page), $0105-$0118, $01EB-$0903, $0CD0-$0CDC  
**Key Components:**
- DMA channel/mode registers
- Source/destination addresses
- Transfer size parameters
- Graphics coordinate DMA

**Usage:** Fast memory transfers, VRAM updates, graphics loading

### Sprite System

**Total Labels:** 15+ labels  
**Memory Ranges:** $0C00-$0C1F+ (OAM), $1A73-$1A79, $7EC260-$7EC480  
**Key Components:**
- OAM sprite buffer (128 sprites)
- Sprite property arrays (X, Y, tile, attributes)
- Sprite slot/base/frame/state arrays
- Sprite management variables

**Usage:** All sprite rendering, animation, positioning

### Save System

**Total Labels:** 3 labels  
**Memory Range:** $7E3665-$7E3668  
**Key Components:**
- Save state flag / screen ready
- Save file state flags (2 flags)

**Usage:** Game saving/loading, state persistence

### Calculation System

**Total Labels:** 20+ labels  
**Memory Ranges:** $38-$39, $48-$52, $89-$95, $8D-$91  
**Key Components:**
- Calculation type/parameters
- Iteration counters
- Mode/index/execution registers
- Validation/status flags

**Usage:** Game calculations, entity processing, validation

---

## Usage Statistics

### Label Count by Memory Range

| Memory Range | Label Count | % of Total |
|--------------|-------------|------------|
| Zero Page ($00-$FF) | ~35 | 15% |
| Low WRAM ($0100-$0FFF) | ~120 | 52% |
| Extended WRAM ($1000-$1FFF) | ~30 | 13% |
| High WRAM ($2000-$6FFF) | ~15 | 7% |
| WRAM Mirror ($7E0000+) | ~30 | 13% |
| **Total** | **~230** | **100%** |

### Label Count by System Category

| System Category | Label Count | % of Total |
|-----------------|-------------|------------|
| Graphics System | ~80 | 35% |
| Sprite System | ~25 | 11% |
| Battle System | ~20 | 9% |
| DMA System | ~15 | 7% |
| Audio System | ~10 | 4% |
| Controller System | ~4 | 2% |
| Save System | ~3 | 1% |
| Calculation/Entity | ~25 | 11% |
| System/General | ~48 | 20% |
| **Total** | **~230** | **100%** |

### Most Frequently Used Labels

| Label | Address | Usage Count | Purpose |
|-------|---------|-------------|---------|
| `!oam_sprite_buffer` | $0C00 | 156+ | OAM sprite buffer base |
| `!current_entity` | $8B | 100+ | Current entity ID |
| `!controller_input_array` | $0A02 | 80+ | Controller data |
| `!sys_work_register` | $04A7 | 70+ | Temporary processing |
| `!sprite_x_array` | $1A73 | 60+ | Sprite X positions |
| `!sprite_y_array` | $1A75 | 60+ | Sprite Y positions |
| `!gfx_state_control` | $7EC240 | 50+ | Graphics state |
| `!sprite_frame_array` | $7EC360 | 50+ | Animation frames |
| `!oam_sprite0_y` | $0C01 | 46+ | Sprite 0 Y position |
| `!oam_sprite0_tile` | $0C02 | 54+ | Sprite 0 tile index |

---

## Cross-Reference Guide

### Finding Memory by Purpose

**Need to process graphics?**
→ See Graphics System ($42-$4A, $0A00-$0AFF, $0C80-$0CFF, $7EC240-$7EC460)

**Need to handle sprites?**
→ See Sprite System ($0C00-$0C1F+, $1A73-$1A79, $7EC260-$7EC480)

**Need to manage audio?**
→ See Audio System ($0200-$0688)

**Need to work with battle mechanics?**
→ See Battle System ($0C50-$0CDC)

**Need to handle input?**
→ See Controller System ($0A02-$0A0A)

**Need fast temporary storage?**
→ See Zero Page ($00-$FF, especially $8B, $04A7, $89-$95)

**Need to transfer data?**
→ See DMA System ($22-$28, $01EB-$0903, $0CD0-$0CDC)

**Need to save/load?**
→ See Save System ($7E3665-$7E3668)

---

## Memory Organization Principles

### Zero Page Strategy
- **$00-$2F:** Core system, DMA, entity state
- **$30-$6F:** Graphics processing, calculations
- **$70-$FF:** System variables, counters, flags

### Low WRAM Organization
- **$0100-$01FF:** System initialization, interrupts, DMA params
- **$0200-$06FF:** Audio system (SPC700 communication)
- **$0400-$04FF:** System variables, working registers
- **$0800-$09FF:** Graphics sprite buffers
- **$0A00-$0AFF:** Controller, graphics state, positions
- **$0C00-$0CFF:** OAM sprites, battle state, graphics registers

### Extended WRAM ($1000+)
- **$1000-$11FF:** System status, graphics buffers
- **$1500-$1A79:** Sprite management, layers, backgrounds, sprite arrays

### High WRAM ($3000-$7EFFFF)
- **$3600-$36FF:** Delta calculation buffers
- **$5000-$5027:** Color palette buffers
- **$7E3665-$7E3668:** Save system state
- **$7EC260-$7EC5C0:** Large sprite/graphics/sound arrays

---

## Document History

**Version:** 1.0  
**Date:** 2025  
**Created by:** FFMQ Reverse Engineering Project  
**Total Labels Documented:** ~230  
**Coverage:** Complete memory map from $00 to $7EFFFF

This document was generated from comprehensive analysis of all documented bank ASM files and the RAM variables include file.

---

## Related Documentation

- See `ffmq_ram_variables.inc` for complete label definitions
- See individual bank documentation for usage context
- See build documentation for assembly/compilation information
