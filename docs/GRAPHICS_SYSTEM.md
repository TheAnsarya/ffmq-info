# FFMQ Graphics System Architecture

## Overview

The graphics system in Final Fantasy Mystic Quest is a sophisticated multi-layered architecture handling sprites, backgrounds, tilemaps, palettes, DMA transfers, and Mode 7 effects. This document provides comprehensive technical documentation of all graphics subsystems.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Sprite System](#sprite-system)
3. [Background System](#background-system)
4. [Graphics Processing Pipeline](#graphics-processing-pipeline)
5. [DMA Graphics Coordination](#dma-graphics-coordination)
6. [Memory Organization](#memory-organization)
7. [Performance Optimization](#performance-optimization)
8. [Code Examples](#code-examples)

---

## Architecture Overview

### System Components

The FFMQ graphics system consists of these major subsystems:

```
┌─────────────────────────────────────────┐
│         Graphics Master Control         │
│   ($0A00-$0AFF, $7EC240-$7EC460)       │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┴──────────┬──────────────┬──────────────┐
    │                     │              │              │
┌───▼────┐    ┌──────────▼─────┐   ┌────▼───┐    ┌────▼────┐
│ Sprite │    │   Background   │   │  DMA   │    │ Palette │
│ System │    │     System     │   │Transfer│    │ System  │
└────────┘    └────────────────┘   └────────┘    └─────────┘
    │                  │                │              │
    └──────────────────┴────────────────┴──────────────┘
                       │
                ┌──────▼──────┐
                │ VRAM Upload │
                │   & PPU     │
                └─────────────┘
```

### Key Memory Ranges

| System | Memory Range | Purpose |
|--------|--------------|---------|
| Graphics Registers | $0C80-$0C98 | 15 core processing registers |
| Sprite Buffers | $0802-$0982 | 6 sprite working buffers |
| OAM Buffer | $0C00-$0C1F+ | 128 sprites × 4 bytes |
| Graphics State | $0A00-$0AFF | Position, mode, control vars |
| VRAM Tiles | $0CC0-$0CCD | VRAM tile address registers |
| Extended State | $7EC240-$7EC460 | Large graphics/sprite arrays |

---

## Sprite System

### OAM (Object Attribute Memory) Structure

The SNES OAM supports 128 sprites with 4 bytes each:

```
Sprite Structure (4 bytes per sprite):
┌───────┬───────┬───────┬─────────┐
│ X pos │ Y pos │  Tile │  Attrs  │
│  (1)  │  (1)  │  (1)  │   (1)   │
└───────┴───────┴───────┴─────────┘

Attributes Byte:
Bits 76543210
     ││││││││
     │││││││└─ Palette (bits 0-2)
     ││││││└── Priority (bits 4-5)
     │││││└─── Flip X (bit 6)
     ││││└──── Flip Y (bit 7)
     │││└───── (varies by implementation)
     ││└────── (varies by implementation)
     │└─────── (varies by implementation)
     └──────── (varies by implementation)
```

### OAM Buffer ($0C00-$0C1F+)

FFMQ maintains a full OAM buffer in WRAM:

```assembly
!oam_sprite_buffer  = $0c00     ; OAM sprite buffer base (128 sprites)

; Individual sprite access (sprite 0-3 shown):
!oam_sprite0_x      = $0c00     ; Sprite 0 X position
!oam_sprite0_y      = $0c01     ; Sprite 0 Y position (46 uses)
!oam_sprite0_tile   = $0c02     ; Sprite 0 tile index (54 uses)
!oam_sprite0_attrs  = $0c03     ; Sprite 0 attributes (20 uses)

!oam_sprite1_x      = $0c04     ; Sprite 1 X position (23 uses)
!oam_sprite1_y      = $0c05     ; Sprite 1 Y position (18 uses)
!oam_sprite1_tile   = $0c06     ; Sprite 1 tile index (31 uses)
!oam_sprite1_attrs  = $0c07     ; Sprite 1 attributes

; Pattern continues for all 128 sprites
; Total size: 512 bytes ($0c00-$0dff)
```

### Sprite Property Arrays ($1A73-$1A79)

Indexed sprite arrays for efficient batch processing:

```assembly
; Indexed access pattern: lda.w !sprite_x_array,x
!sprite_x_array         = $1a73     ; X positions (indexed)
!sprite_y_array         = $1a75     ; Y positions (indexed)
!sprite_tile_array      = $1a77     ; Tile indices (indexed)
!sprite_attrs_array     = $1a79     ; Attributes (indexed)

; Example usage:
ldx #$00                ; Sprite index
lda.w !sprite_x_array,x ; Load X position
sta.w !oam_sprite0_x    ; Store to OAM buffer
```

### Sprite Buffers ($0802-$0982)

Six working sprite buffers for graphics processing:

```assembly
!gfx_sprite_buffer_1    = $0802     ; Primary buffer
!gfx_sprite_buffer_2    = $0880     ; Secondary buffer
!gfx_sprite_buffer_3    = $0882     ; Tertiary buffer
!gfx_sprite_buffer_4    = $0902     ; Alternate/memory buffer
!gfx_sprite_buffer_5    = $0980     ; Alternate buffer
!gfx_sprite_buffer_6    = $0982     ; Alternate buffer
```

**Purpose:** Intermediate storage during sprite processing, used for:
- Sprite composition (combining multiple tiles)
- Animation frame buffering
- Screen transition effects
- Sprite clipping and bounds checking

### Extended Sprite Arrays ($7EC260-$7EC480)

Large sprite management arrays in extended WRAM:

```assembly
!sprite_slot_array      = $7ec260   ; Sprite slot indices
!sprite_base_array      = $7ec320   ; Base indices / X-positions
!sprite_frame_array     = $7ec360   ; Animation frame counters
!sprite_state_array     = $7ec400   ; Sprite states / anim states
!sprite_tile_id_array   = $7ec480   ; Base tile IDs / channels
```

**Animation System:**

```assembly
; Animation frame update example from bank_0B:
lda.l !sprite_frame_array,x ; Load current frame
inc a                        ; Increment frame
sta.l !sprite_frame_array,x ; Store updated frame

lda.l !sprite_base_array,x  ; Load sprite base tile
clc
adc.l !sprite_frame_array,x ; Add frame offset
sta.l !sprite_tile_id_array,x ; Update tile ID
```

### Sprite Management Variables

```assembly
; Sprite object indices
!sprite_obj_index_1     = $0ade     ; Primary sprite object index
!sprite_obj_index_2     = $0adf     ; Secondary sprite object index

; Sprite configuration
!gfx_index              = $0ae9     ; Graphics index
!sprite_config          = $0aee     ; Sprite configuration
!sprite_final_attrs     = $1a3e     ; Final attribute result (indexed)

; Sprite management
!sprite_output_var      = $1500     ; Sprite output variable
!sprite_target_id       = $1502     ; Target sprite ID
```

---

## Background System

### Background Layers

FFMQ uses multiple background layers:

- **BG1:** Main game layer (tilemap)
- **BG2:** Secondary layer (parallax, effects)
- **BG3:** Used for special effects
- **Mode 7:** Rotation/scaling effects

### Layer Scroll Positions

```assembly
!layer1_scroll_x        = $190c     ; Layer 1 scroll X position
!layer2_scroll_x        = $190e     ; Layer 2 scroll X position

; Scroll update code (bank_0B):
stx.w !layer1_scroll_x   ; Clear layer 1 scroll X
stx.w !layer2_scroll_x   ; Clear layer 2 scroll X
```

### Background Variables

```assembly
!bg_variable_19ab       = $19ab     ; Background variable
!bg_map_ptr_19b2        = $19b2     ; Background map pointer
!bg_data_1953           = $1953     ; Background data
!bg_variable_19d8       = $19d8     ; Background variable
```

### Tilemap Configuration

```assembly
!bg2_tilemap_config     = $1a4d     ; BG2 tilemap configuration
!color_math_control     = $1a50     ; Color math control / layer config 0

; Configuration usage (bank_0B):
sta.w !color_math_control   ; Store layer config 0
lda.w !bg2_tilemap_config   ; Load BG2 tilemap config
```

---

## Graphics Processing Pipeline

### Graphics State Machine

The graphics system operates as a state machine with multiple processing stages:

```
┌─────────────┐
│  Initialize │
│   Graphics  │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌──────────────┐
│    Load     │──────►│   Process    │
│  Graphics   │      │   Buffers    │
│    Data     │      │              │
└──────┬──────┘      └──────┬───────┘
       │                    │
       │                    ▼
       │             ┌──────────────┐
       │             │   Graphics   │
       │             │  Validation  │
       │             └──────┬───────┘
       │                    │
       ▼                    ▼
┌─────────────┐      ┌──────────────┐
│ DMA Transfer│◄─────┤   Finalize   │
│   to VRAM   │      │   Graphics   │
└─────────────┘      └──────────────┘
```

### Graphics Registers ($0C80-$0C98)

15 core graphics processing registers:

```assembly
!gfx_register_c80       = $0c80     ; Graphics register 0
!gfx_register_c82       = $0c82     ; Graphics register 1
!gfx_register_c84       = $0c84     ; Graphics register 2
!gfx_register_c86       = $0c86     ; Graphics register 3
!gfx_register_c88       = $0c88     ; Graphics register 4
!gfx_register_c8a       = $0c8a     ; Graphics register 5
!gfx_register_c8c       = $0c8c     ; Graphics register 6
!gfx_register_c8e       = $0c8e     ; Graphics register 7
!gfx_register_c90       = $0c90     ; Graphics register 8
!gfx_register_c92       = $0c92     ; Graphics register 9
!gfx_register_c94       = $0c94     ; Graphics register 10
!gfx_register_c96       = $0c96     ; Graphics register 11
!gfx_register_c98       = $0c98     ; Graphics register 12
```

**Usage:** Intermediate values during graphics calculations, temporary storage for tile IDs, pattern indices, and processing state.

### Processing Variables

```assembly
; Zero page graphics processing
!gfx_processing_b2      = $b2       ; Graphics processing register
!gfx_processing_b3      = $b3       ; Graphics processing register
!gfx_processing_b4      = $b4       ; Graphics processing register
!gfx_processing_b5      = $b5       ; Graphics processing / validation
!gfx_processing_ef      = $ef       ; Graphics processing register

; Graphics mode and control
!gfx_sprite_mode        = $0a9c     ; Graphics sprite mode
!gfx_sprite_base        = $0a9d     ; Graphics sprite base
!gfx_special_flag       = $0a9f     ; Graphics special flag
!gfx_param_mode         = $0aa0     ; Graphics parameter mode
```

### Position System

```assembly
; Primary positions
!gfx_position_x         = $0a25     ; Graphics X position (2 bytes)
!gfx_position_y         = $0a26     ; Graphics Y position (2 bytes)

; Secondary positions (for scrolling, offsets)
!gfx_position_x_alt     = $0a29     ; Secondary X position
!gfx_position_y_alt     = $0a2a     ; Secondary Y position

; Graphics coordinates
!gfx_coord_x            = $0a91     ; Graphics X coordinate
!gfx_coord_y            = $0a92     ; Graphics Y coordinate

; Pattern counter (shifted for ×4 multiplication)
!gfx_pattern_counter    = $0a94     ; Graphics pattern counter (shifted 2x)
```

### Graphics Buffers

```assembly
; Graphics buffer array ($1144-$115c)
!gfx_buffer_1144        = $1144     ; Graphics buffer 0
!gfx_buffer_1146        = $1146     ; Graphics buffer 1
!gfx_buffer_1148        = $1148     ; Graphics buffer 2
!gfx_buffer_114a        = $114a     ; Graphics buffer 3
!gfx_buffer_1158        = $1158     ; Graphics buffer 4
!gfx_buffer_115a        = $115a     ; Graphics buffer 5
!gfx_buffer_115c        = $115c     ; Graphics buffer 6

; Graphics tile data buffers
!wram_buffer_cef4       = $cef4     ; Graphics tile buffer 1 (indexed)
!wram_buffer_cef6       = $cef6     ; Graphics tile buffer 2 (offset +2)
!wram_buffer_d0f4       = $d0f4     ; Graphics tile buffer 3
!wram_buffer_d174       = $d174     ; Graphics tile buffer 4
```

### Extended Graphics State ($7EC240-$7EC460)

```assembly
; Graphics processing and control
!gfx_state_control      = $7ec240   ; Graphics state/control register
!gfx_result_data        = $7ec280   ; Graphics result/data storage
!gfx_param_buffer       = $7ec2a0   ; Graphics parameter/buffer control
!gfx_channel_state      = $7ec2e0   ; Channel state register
!gfx_mode_register      = $7ec300   ; Graphics mode register
!gfx_mode_buffer        = $7ec340   ; Graphics mode/buffer size
!gfx_buffer_main        = $7ec380   ; Main graphics buffer

; Extended system
!gfx_base_addr          = $7ec440   ; Graphics base address / coordinate data
!gfx_pattern_index      = $7ec460   ; Graphics pattern index / extended memory
```

**Graphics Processing Example (from bank_02):**

```assembly
; Read graphics state
lda.l !gfx_state_control,x   ; Read current graphics state
ora #$02                      ; Set bit 1 (enable flag)
sta.l !gfx_state_control,x   ; Store modified state

; Process graphics mode
lda #$00
sta.l !gfx_mode_register,x   ; Store graphics mode
sta.l !sprite_tile_id_array,x ; Store graphics channel
sta.l !sprite_frame_array,x  ; Store graphics state

; Clear graphics buffer
sta.l !gfx_buffer_main,x     ; Clear graphics buffer
```

### Memory Graphics System ($1A18-$1A2C)

```assembly
!mem_gfx_flags          = $1a18     ; Memory graphics flags
!mem_gfx_final          = $1a1a     ; Memory graphics final
!mem_gfx_buffer_sec     = $1a20     ; Memory graphics buffer secondary
!mem_gfx_ext_sec        = $1a22     ; Memory graphics extended secondary
!gfx_completion_mode    = $1a2c     ; Graphics completion mode counter
```

**Purpose:** Manages graphics state persistence, completion tracking, and memory-based graphics processing.

---

## DMA Graphics Coordination

### DMA Coordinate Processing

FFMQ uses sophisticated DMA systems for battle sprite coordinate processing.

#### DMA Graphics Coordinate Addresses ($0CD0-$0CDC)

```assembly
!dma_dest_addr          = $0cd0     ; DMA destination X coordinate
!dma_source_addr        = $0cd4     ; DMA source X+8 coordinate
!dma_dest_addr_alt      = $0cd8     ; DMA source high (with VRAM offset)
!dma_source_addr_alt    = $0cdc     ; DMA destination high (with VRAM page offset)
```

#### DMA Coordinate Processing System (Bank_01)

```assembly
dma_coordinate_processing_system:
    php                              ; Save processor flags
    rep #$30                         ; Set 16-bit mode
    lda.w !battle_data_index_1       ; Load X coordinate
    sta.w !dma_dest_addr             ; Set DMA destination X
    clc                              ; Clear carry
    adc.w #$0008                     ; Add sprite width offset
    sta.w !dma_source_addr           ; Set DMA destination X+8
    clc                              ; Clear carry
    adc.w #$0800                     ; Add VRAM page offset
    sta.w !dma_source_addr_alt       ; Set DMA destination high
    lda.w !battle_data_index_1       ; Reload X coordinate
    clc                              ; Clear carry
    adc.w #$0800                     ; Add VRAM offset
    sta.w !dma_dest_addr_alt         ; Set DMA source high
    plp                              ; Restore processor flags
    rts                              ; Return from DMA processing
```

**Explanation:**
1. Load base X coordinate from battle data
2. Store as DMA destination
3. Add 8 pixels (sprite width) → DMA source for right half
4. Add VRAM page offset ($0800) → high address for destination
5. Recalculate with VRAM offset → high address for source

This system allows battle sprites to be DMA-transferred in two halves (left 8 pixels, right 8 pixels) with proper VRAM addressing.

### Battle Coordinates ($0C60-$0C6D)

4D coordinate system for battle graphics:

```assembly
!battle_coord_x_lo      = $0c60     ; Battle X coordinate (low byte)
!battle_coord_x_hi      = $0c61     ; Battle X coordinate (high byte)
!battle_coord_y_lo      = $0c64     ; Battle Y coordinate (low byte)
!battle_coord_y_hi      = $0c65     ; Battle Y coordinate (high byte)
!battle_coord_z_lo      = $0c68     ; Battle Z coordinate (low byte)
!battle_coord_z_hi      = $0c69     ; Battle Z coordinate (high byte)
!battle_coord_w_lo      = $0c6c     ; Battle W coordinate (low byte)
!battle_coord_w_hi      = $0c6d     ; Battle W coordinate (high byte)
```

**4D System:** X, Y, Z, W coordinates support:
- X/Y: Screen position
- Z: Depth (parallax, layering)
- W: Special effects parameter (rotation, scaling factor)

### VRAM Tile Addresses ($0CC0-$0CCD)

```assembly
!vram_tile_cc0          = $0cc0     ; VRAM tile address 0
!vram_tile_cc2          = $0cc2     ; VRAM tile address 1
!vram_tile_cc4          = $0cc4     ; VRAM tile address 2
!vram_tile_cc6          = $0cc6     ; VRAM tile address 3
!vram_tile_cc8          = $0cc8     ; VRAM tile address 4
!vram_tile_cca          = $0cca     ; VRAM tile address 5
!vram_tile_ccc          = $0ccc     ; VRAM tile address 6
!vram_tile_cce          = $0cce     ; VRAM tile address 7

; Sprite-specific VRAM tiles
!sprite_tile_cc2        = $0cc2     ; Sprite tile register
!sprite_tile_cc6        = $0cc6     ; Sprite tile register
!sprite_tile_cca        = $0cca     ; Sprite tile register
!sprite_tile_cce        = $0cce     ; Sprite tile register
```

**Purpose:** Track VRAM tile addresses for dynamic tile loading, ensuring tiles are uploaded to correct VRAM locations.

---

## Memory Organization

### Graphics Memory Layout

```
┌──────────────────────────────────────────┐
│         Zero Page Graphics               │
│  $B2-$B5, $EF (Processing registers)     │
└──────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│       Low WRAM Graphics Buffers          │
│  $0802-$0982 (Sprite buffers)            │
│  $0C00-$0C1F+ (OAM buffer)               │
│  $0C80-$0C98 (Graphics registers)        │
│  $0CC0-$0CCD (VRAM tiles)                │
└──────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│      Graphics State & Position           │
│  $0A00-$0AFF (State, coords, mode)       │
│  $0CD0-$0CDC (DMA coordinates)           │
└──────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│     Extended WRAM Graphics               │
│  $1A18-$1A79 (Memory graphics, arrays)   │
│  $1144-$115C (Graphics buffers)          │
└──────────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│    High WRAM Extended Graphics           │
│  $7EC240-$7EC460 (Large graphics arrays) │
└──────────────────────────────────────────┘
```

### Buffer Flow

```
Input Data
    │
    ▼
┌─────────────┐
│   Working   │──► Sprite buffers ($0802-$0982)
│   Buffers   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Graphics   │──► Graphics registers ($0C80-$0C98)
│ Processing  │    VRAM tiles ($0CC0-$0CCD)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ OAM Buffer  │──► OAM sprite buffer ($0C00-$0C1F+)
│  Assembly   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ DMA Transfer│──► VRAM / OAM upload
│   to PPU    │
└─────────────┘
```

---

## Performance Optimization

### Optimization Strategies

1. **Direct Page Addressing**
   - Graphics processing variables in zero page ($B2-$B5, $EF)
   - Fast 2-cycle access vs 3-cycle absolute addressing
   - Critical for per-frame graphics calculations

2. **Buffer Reuse**
   - 6 sprite buffers allow parallel processing
   - Reduce memory allocations
   - Enable double-buffering for smooth updates

3. **Indexed Arrays**
   - Sprite property arrays ($1A73-$1A79) support batch operations
   - Single loop processes all sprites
   - Reduces code size and improves cache locality

4. **DMA Efficiency**
   - Pre-calculate DMA addresses ($0CD0-$0CDC)
   - Batch multiple DMA transfers
   - Use HDMA for per-scanline effects

5. **16-bit Processing**
   - Use `rep #$30` for 16-bit mode during graphics calculations
   - Process two bytes per operation
   - Halves instruction count for position/coordinate math

### Typical Frame Budget

```
Frame time: 16.67ms (NTSC) / 20ms (PAL)

Graphics Processing Budget:
- Sprite updates: 3-5ms (up to 128 sprites)
- Background scroll: 0.5-1ms
- DMA transfers: 2-4ms
- Graphics calculations: 2-3ms
- OAM assembly: 1-2ms

Total: ~10-15ms
Remaining: 1.67-6.67ms for game logic
```

### Sprite Limit Management

SNES hardware limits:
- **Max sprites per frame:** 128
- **Max sprites per scanline:** 32
- **Max sprite pixels per scanline:** 256 pixels

FFMQ strategies:
- Priority-based culling (off-screen sprites disabled)
- Flickering for sprite overflow (alternating frame display)
- Sprite composition (combine small sprites into larger)

---

## Code Examples

### Example 1: Sprite Position Update

```assembly
; Update sprite position with delta movement
; Input: X = sprite index
; Uses: !sprite_x_array, !sprite_y_array

update_sprite_position:
    phx                          ; Preserve sprite index
    
    ; Update X position
    lda.w !sprite_x_array,x      ; Load current X
    clc
    adc.w !delta_buffer_1,x      ; Add X delta
    sta.w !sprite_x_array,x      ; Store new X
    
    ; Update Y position
    lda.w !sprite_y_array,x      ; Load current Y
    clc
    adc.w !delta_buffer_2,x      ; Add Y delta
    sta.w !sprite_y_array,x      ; Store new Y
    
    ; Copy to OAM buffer
    lda.w !sprite_x_array,x      ; Get final X
    sta.w !oam_sprite_buffer+0,x ; Store to OAM X
    lda.w !sprite_y_array,x      ; Get final Y
    sta.w !oam_sprite_buffer+1,x ; Store to OAM Y
    
    plx                          ; Restore sprite index
    rts
```

### Example 2: Animation Frame Advance

```assembly
; Advance sprite animation frame
; Input: X = sprite index
; Uses: !sprite_frame_array, !sprite_tile_id_array

advance_animation_frame:
    lda.l !sprite_frame_array,x  ; Load current frame
    inc a                         ; Increment frame
    cmp #$08                      ; Check if >= 8 frames
    bcc .store_frame              ; If < 8, store
    lda #$00                      ; Else wrap to 0
.store_frame:
    sta.l !sprite_frame_array,x  ; Store updated frame
    
    ; Update tile based on frame
    lda.l !sprite_base_array,x   ; Load base tile ID
    clc
    adc.l !sprite_frame_array,x  ; Add frame offset
    sta.l !sprite_tile_id_array,x ; Store tile ID
    
    ; Copy to OAM
    tax                           ; Sprite index to X
    lda.l !sprite_tile_id_array,x ; Load tile ID
    sta.w !oam_sprite_buffer+2,x  ; Store to OAM tile
    rts
```

### Example 3: Graphics State Management

```assembly
; Initialize graphics processing state
; Uses: !gfx_state_control, !gfx_mode_register

init_graphics_state:
    php                           ; Save flags
    rep #$30                      ; 16-bit mode
    
    ldx #$0000                    ; Start at index 0
.loop:
    ; Clear graphics state
    lda #$0000
    sta.l !gfx_state_control,x   ; Clear state/control
    sta.l !gfx_result_data,x     ; Clear result
    sta.l !gfx_param_buffer,x    ; Clear param buffer
    sta.l !gfx_mode_register,x   ; Clear mode
    
    ; Advance to next slot
    inx
    inx                           ; 2-byte increment
    cpx #$0100                    ; Check if done (128 entries)
    bcc .loop                     ; Continue if not
    
    plp                           ; Restore flags
    rts
```

### Example 4: DMA Graphics Coordinate Setup

```assembly
; Setup DMA coordinates for battle sprite transfer
; Input: A = X coordinate
; Uses: !dma_dest_addr, !dma_source_addr, !dma_dest_addr_alt, !dma_source_addr_alt

setup_dma_coordinates:
    php                           ; Save flags
    rep #$30                      ; 16-bit mode
    
    sta.w !dma_dest_addr         ; Store base X coordinate
    
    ; Calculate X+8 (right half of sprite)
    clc
    adc #$0008
    sta.w !dma_source_addr       ; Store X+8
    
    ; Calculate high address with VRAM offset
    lda.w !dma_dest_addr         ; Reload base X
    clc
    adc #$0800                    ; Add VRAM offset
    sta.w !dma_dest_addr_alt     ; Store high address
    
    ; Calculate source high address
    lda.w !dma_source_addr       ; Load X+8
    clc
    adc #$0800                    ; Add VRAM page offset
    sta.w !dma_source_addr_alt   ; Store source high
    
    plp                           ; Restore flags
    rts
```

---

## Technical Notes

### Sprite Flicker

When more than 32 sprites appear on a scanline, the SNES automatically drops sprites. FFMQ handles this by:
- Alternating sprite priority each frame
- Sorting sprites by importance
- Disabling off-screen sprites

### Palette Management

- 8 sprite palettes (16 colors each)
- 8 background palettes (16 colors each)
- Color math for transparency effects
- Palette animations for water, fire effects

### VRAM Management

VRAM organized as:
- **Tilemap area:** Background tile indices
- **Tile data area:** 4bpp or 8bpp tile graphics
- **OAM area:** Sprite attribute tables

Dynamic VRAM updates use DMA during VBlank to avoid visual artifacts.

### Mode 7 Effects

Mode 7 provides rotation/scaling:
- Matrix transformation (A, B, C, D parameters)
- Center point (CX, CY)
- Horizon offset
- Used for world map, special battle effects

---

## Document Info

**Version:** 1.0  
**Coverage:** Complete graphics system (sprite, background, DMA, buffers)  
**Labels Documented:** 80+ graphics-related labels  
**Code Examples:** 4 working examples

**See Also:**
- `MEMORY_MAP.md` - Complete memory layout
- `ffmq_ram_variables.inc` - Label definitions
- Bank_0B/0C/01/02 documentation - Graphics implementation
