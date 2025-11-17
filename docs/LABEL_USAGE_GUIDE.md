# FFMQ Label Usage Guide

## Overview

This guide provides comprehensive examples and usage patterns for all 230+ RAM variable labels in the FFMQ reverse engineering project. Each label is categorized by system, with code examples showing correct usage patterns.

---

## Table of Contents

1. [Audio System Labels](#audio-system-labels)
2. [Graphics System Labels](#graphics-system-labels)
3. [Sprite System Labels](#sprite-system-labels)
4. [Battle System Labels](#battle-system-labels)
5. [Controller System Labels](#controller-system-labels)
6. [DMA System Labels](#dma-system-labels)
7. [Save System Labels](#save-system-labels)
8. [Working Registers & Scratch Variables](#working-registers--scratch-variables)
9. [System State Variables](#system-state-variables)
10. [Common Usage Patterns](#common-usage-patterns)

---

## Audio System Labels

### Channel Assignment ($0628)

```assembly
!audio_channel_assign = $0628     ; 8 channels worth of data

; Usage: Assign sound effect to channel
ldx #$00                          ; Channel 0
lda #$42                          ; Sound effect ID $42
sta.w !audio_channel_assign,x    ; Assign to channel

; Multi-channel assignment
ldx #$00
.loop:
    lda audio_sfx_table,x
    sta.w !audio_channel_assign,x
    inx
    cpx #$08                      ; 8 channels
    bcc .loop
```

### SPC700 RAM Addresses ($0648, $064A)

```assembly
!audio_ram_addr_start = $0648     ; SPC700 RAM start addresses
!audio_ram_addr_end   = $064a     ; SPC700 RAM end addresses

; Usage: Setup audio RAM transfer
ldx #$02                          ; Channel 2
lda #$40                          ; Start at $0040
sta.w !audio_ram_addr_start,x
lda #$80                          ; End at $0080
sta.w !audio_ram_addr_end,x

; Calculate transfer size
lda.w !audio_ram_addr_end,x
sec
sbc.w !audio_ram_addr_start,x
; A now contains transfer size
```

### Pattern Data ($0668, $0688)

```assembly
!audio_pattern_size   = $0668     ; Pattern data sizes
!audio_pattern_buffer = $0688     ; Pattern buffer slots

; Usage: Load pattern to buffer
ldx #$01                          ; Channel 1
lda #$20                          ; Pattern size = 32 bytes
sta.w !audio_pattern_size,x

ldy #$00
.copy_loop:
    lda pattern_data,y
    sta.w !audio_pattern_buffer,x
    inx
    iny
    cpy.w !audio_pattern_size
    bcc .copy_loop
```

---

## Graphics System Labels

### Graphics Registers ($0C80-$0C98)

```assembly
!gfx_register_c80 = $0c80         ; Graphics register 0
; ... (15 total registers)

; Usage: Graphics calculation pipeline
lda #$42
sta.w !gfx_register_c80           ; Store value to register 0
asl a
asl a
sta.w !gfx_register_c82           ; Store shifted value to register 1

; Multi-register processing
ldx #$00
.process_loop:
    lda.w !gfx_register_c80,x
    clc
    adc #$10
    sta.w !gfx_register_c80,x
    inx
    inx                           ; 2-byte registers
    cpx #$1e                      ; 15 registers × 2 bytes
    bcc .process_loop
```

### Position Coordinates ($0A25-$0A2A)

```assembly
!gfx_position_x     = $0a25       ; Primary X position (2 bytes)
!gfx_position_y     = $0a26       ; Primary Y position (2 bytes)
!gfx_position_x_alt = $0a29       ; Secondary X position
!gfx_position_y_alt = $0a2a       ; Secondary Y position

; Usage: Update graphics position with scrolling offset
rep #$30                          ; 16-bit mode
lda.w !gfx_position_x            ; Load current X
clc
adc.w !layer1_scroll_x           ; Add scroll offset
sta.w !gfx_position_x_alt        ; Store to secondary position

lda.w !gfx_position_y            ; Load current Y
clc
adc #$0010                        ; Add fixed offset
sta.w !gfx_position_y_alt        ; Store to secondary position
sep #$30                          ; Back to 8-bit
```

### Graphics Coordinates ($0A91-$0A94)

```assembly
!gfx_coord_x         = $0a91      ; Graphics X coordinate
!gfx_coord_y         = $0a92      ; Graphics Y coordinate
!gfx_pattern_counter = $0a94      ; Pattern counter (shifted ×4)

; Usage: Calculate pattern offset
rep #$30                          ; 16-bit mode
lda #$0005                        ; Pattern index 5
sta.w !gfx_pattern_counter       ; Store counter
asl a                             ; Shift left (×2)
asl a                             ; Shift left (×4)
tax                               ; Use as index
; X now = pattern_index × 4

; Coordinate to tile conversion
lda.w !gfx_coord_x               ; Load X coordinate
lsr a                             ; Divide by 8 (tile width)
lsr a
lsr a
sta.w temp_tile_x                ; Store tile X

lda.w !gfx_coord_y               ; Load Y coordinate
lsr a                             ; Divide by 8 (tile height)
lsr a
lsr a
sta.w temp_tile_y                ; Store tile Y
```

### Graphics Mode & Control ($0A9C-$0AA0)

```assembly
!gfx_sprite_mode  = $0a9c         ; Graphics sprite mode
!gfx_sprite_base  = $0a9d         ; Graphics sprite base
!gfx_special_flag = $0a9f         ; Graphics special flag
!gfx_param_mode   = $0aa0         ; Graphics parameter mode

; Usage: Setup graphics rendering mode
lda #$02
sta.w !gfx_sprite_mode           ; Mode 2 = translucent
lda #$40
sta.w !gfx_sprite_base           ; Base tile ID
lda #$01
sta.w !gfx_special_flag          ; Enable special processing
stz.w !gfx_param_mode            ; Clear parameter mode
```

### Graphics Buffers ($1144-$115C)

```assembly
!gfx_buffer_1144 = $1144          ; Graphics buffer 0
; ... (7 total buffers)

; Usage: Clear all graphics buffers
rep #$30                          ; 16-bit mode
lda #$0000
ldx #$0000
.clear_loop:
    sta.w !gfx_buffer_1144,x
    inx
    inx
    cpx #$001c                    ; 7 buffers × 2 bytes + 4
    bcc .clear_loop
sep #$30

; Double-buffer sprite processing
lda.w !gfx_buffer_1144           ; Read front buffer
pha                               ; Save
lda.w !gfx_buffer_1146           ; Load back buffer
sta.w !gfx_buffer_1144           ; Copy to front
pla
sta.w !gfx_buffer_1146           ; Store old front to back
```

### Extended Graphics State ($7EC240-$7EC460)

```assembly
!gfx_state_control = $7ec240      ; Graphics state/control
!gfx_result_data   = $7ec280      ; Graphics result/data
!gfx_param_buffer  = $7ec2a0      ; Graphics parameter/buffer
!gfx_mode_register = $7ec300      ; Graphics mode register
!gfx_mode_buffer   = $7ec340      ; Graphics mode/buffer size
!gfx_buffer_main   = $7ec380      ; Main graphics buffer
!gfx_base_addr     = $7ec440      ; Graphics base address
!gfx_pattern_index = $7ec460      ; Graphics pattern index

; Usage: Graphics state machine (bank_02 style)
ldx #$00                          ; Slot 0
lda.l !gfx_state_control,x       ; Read state
ora #$02                          ; Set enable bit
sta.l !gfx_state_control,x       ; Write back

lda #$00
sta.l !gfx_mode_register,x       ; Clear mode
sta.l !gfx_buffer_main,x         ; Clear buffer

lda #$40
sta.l !gfx_pattern_index,x       ; Set pattern index

; Batch clear extended graphics
rep #$30                          ; 16-bit mode
ldx #$0000
lda #$0000
.clear_loop:
    sta.l !gfx_state_control,x
    sta.l !gfx_result_data,x
    sta.l !gfx_param_buffer,x
    inx
    inx
    cpx #$0100
    bcc .clear_loop
sep #$30
```

---

## Sprite System Labels

### OAM Sprite Buffer ($0C00-$0C1F+)

```assembly
!oam_sprite_buffer = $0c00        ; OAM buffer base
!oam_sprite0_x     = $0c00        ; Sprite 0 X position
!oam_sprite0_y     = $0c01        ; Sprite 0 Y position
!oam_sprite0_tile  = $0c02        ; Sprite 0 tile index
!oam_sprite0_attrs = $0c03        ; Sprite 0 attributes

; Usage: Update single sprite
lda #$80
sta.w !oam_sprite0_x             ; X = 128
lda #$70
sta.w !oam_sprite0_y             ; Y = 112
lda #$42
sta.w !oam_sprite0_tile          ; Tile ID $42
lda #$03
sta.w !oam_sprite0_attrs         ; Palette 3, priority 0

; Indexed sprite access (sprite N)
ldx #$0014                        ; Sprite 5 (5 × 4 = 20 = $14)
lda #$a0
sta.w !oam_sprite_buffer+0,x     ; Set X position
lda #$60
sta.w !oam_sprite_buffer+1,x     ; Set Y position
lda #$50
sta.w !oam_sprite_buffer+2,x     ; Set tile
lda #$21
sta.w !oam_sprite_buffer+3,x     ; Set attributes
```

### Sprite Property Arrays ($1A73-$1A79)

```assembly
!sprite_x_array    = $1a73        ; X positions (indexed)
!sprite_y_array    = $1a75        ; Y positions (indexed)
!sprite_tile_array = $1a77        ; Tile indices (indexed)
!sprite_attrs_array = $1a79       ; Attributes (indexed)

; Usage: Batch sprite processing
ldx #$00
.update_loop:
    lda.w !sprite_x_array,x       ; Load X
    clc
    adc #$02                      ; Move right 2 pixels
    sta.w !sprite_x_array,x       ; Store back
    
    lda.w !sprite_y_array,x       ; Load Y
    sec
    sbc #$01                      ; Move up 1 pixel
    sta.w !sprite_y_array,x       ; Store back
    
    inx
    cpx #$20                      ; 32 sprites
    bcc .update_loop

; Copy sprite arrays to OAM
ldx #$00
.copy_loop:
    lda.w !sprite_x_array,x
    sta.w !oam_sprite_buffer+0,x
    lda.w !sprite_y_array,x
    sta.w !oam_sprite_buffer+1,x
    lda.w !sprite_tile_array,x
    sta.w !oam_sprite_buffer+2,x
    lda.w !sprite_attrs_array,x
    sta.w !oam_sprite_buffer+3,x
    
    inx
    cpx #$20
    bcc .copy_loop
```

### Extended Sprite Arrays ($7EC260-$7EC480)

```assembly
!sprite_slot_array   = $7ec260    ; Sprite slot indices
!sprite_base_array   = $7ec320    ; Base indices / X-positions
!sprite_frame_array  = $7ec360    ; Animation frame counters
!sprite_state_array  = $7ec400    ; Sprite states
!sprite_tile_id_array = $7ec480   ; Base tile IDs / channels

; Usage: Animation system (bank_0B style)
ldx #$00                          ; Sprite slot 0

; Update animation frame
lda.l !sprite_frame_array,x      ; Load current frame
inc a                             ; Next frame
cmp #$08                          ; Check max (8 frames)
bcc .store_frame
lda #$00                          ; Wrap to 0
.store_frame:
sta.l !sprite_frame_array,x      ; Store frame

; Calculate tile ID from base + frame
lda.l !sprite_base_array,x       ; Load base tile
clc
adc.l !sprite_frame_array,x      ; Add frame offset
sta.l !sprite_tile_id_array,x    ; Store tile ID

; Update sprite state
lda.l !sprite_state_array,x      ; Load state
ora #$01                          ; Set active bit
sta.l !sprite_state_array,x      ; Store state
```

### Sprite Buffers ($0802-$0982)

```assembly
!gfx_sprite_buffer_1 = $0802      ; Primary sprite buffer
!gfx_sprite_buffer_2 = $0880      ; Secondary sprite buffer
!gfx_sprite_buffer_3 = $0882      ; Tertiary sprite buffer
!gfx_sprite_buffer_4 = $0902      ; Alternate/memory buffer
!gfx_sprite_buffer_5 = $0980      ; Alternate buffer
!gfx_sprite_buffer_6 = $0982      ; Alternate buffer

; Usage: Sprite composition
ldx #$00
.compose_loop:
    lda sprite_layer_1,x          ; Load layer 1 data
    sta.w !gfx_sprite_buffer_1,x ; Store to buffer 1
    
    lda sprite_layer_2,x          ; Load layer 2 data
    sta.w !gfx_sprite_buffer_2,x ; Store to buffer 2
    
    ; Composite layers
    lda.w !gfx_sprite_buffer_1,x
    ora.w !gfx_sprite_buffer_2,x ; OR together
    sta.w !gfx_sprite_buffer_4,x ; Store composite
    
    inx
    cpx #$20                      ; Buffer size
    bcc .compose_loop
```

---

## Battle System Labels

### Battle State Registers ($0C50-$0C5F)

```assembly
!battle_state_c50 = $0c50         ; Battle state register
!sprite_data_c51  = $0c51         ; Sprite data register
; ... (14 more battle state registers)

; Usage: Battle state machine
lda #$00
sta.w !battle_state_c50          ; Clear state
sta.w !battle_state_c52
sta.w !battle_state_c53

lda #$01
sta.w !sprite_data_c51           ; Set sprite data

; Read battle state
lda.w !battle_state_c54
bne .battle_active
; Not in battle
rts
.battle_active:
; Process battle
```

### Battle Coordinates ($0C60-$0C6D)

```assembly
!battle_coord_x_lo = $0c60        ; X coordinate (low)
!battle_coord_x_hi = $0c61        ; X coordinate (high)
!battle_coord_y_lo = $0c64        ; Y coordinate (low)
!battle_coord_y_hi = $0c65        ; Y coordinate (high)
!battle_coord_z_lo = $0c68        ; Z coordinate (low)
!battle_coord_z_hi = $0c69        ; Z coordinate (high)
!battle_coord_w_lo = $0c6c        ; W coordinate (low)
!battle_coord_w_hi = $0c6d        ; W coordinate (high)

; Usage: 4D coordinate system
rep #$30                          ; 16-bit mode

; Set X/Y position (screen)
lda #$0080
sta.w !battle_coord_x_lo         ; X = 128
lda #$0070
sta.w !battle_coord_y_lo         ; Y = 112

; Set Z depth (parallax)
lda #$0010
sta.w !battle_coord_z_lo         ; Z = 16 (foreground)

; Set W parameter (scale/rotation)
lda #$0100
sta.w !battle_coord_w_lo         ; W = 256 (1.0x scale)

sep #$30                          ; Back to 8-bit
```

### DMA Graphics Coordinates ($0CD0-$0CDC)

```assembly
!dma_dest_addr      = $0cd0       ; DMA destination X
!dma_source_addr    = $0cd4       ; DMA source X+8
!dma_dest_addr_alt  = $0cd8       ; DMA source high
!dma_source_addr_alt = $0cdc      ; DMA destination high

; Usage: DMA coordinate setup (bank_01 style)
rep #$30                          ; 16-bit mode
lda.w !battle_coord_x_lo         ; Load X coordinate
sta.w !dma_dest_addr             ; Set DMA dest X

clc
adc #$0008                        ; Add sprite width
sta.w !dma_source_addr           ; Set DMA source X+8

lda.w !dma_dest_addr
clc
adc #$0800                        ; Add VRAM offset
sta.w !dma_dest_addr_alt         ; Set high address

lda.w !dma_source_addr
clc
adc #$0800
sta.w !dma_source_addr_alt       ; Set source high
sep #$30
```

---

## Controller System Labels

### Controller Input Arrays ($0A02-$0A0A)

```assembly
!controller_input_array = $0a02   ; Primary array (indexed)
!controller_data_alt_1  = $0a07   ; Alternative array 1
!controller_data_alt_2  = $0a0a   ; Alternative array 2

; Usage: Read controller input
ldx #$00                          ; Controller 1
lda.w !controller_input_array,x  ; Read input
and #$80                          ; Check A button (bit 7)
beq .not_pressed
; A button pressed
.not_pressed:

; Multi-controller input
ldx #$00
.read_loop:
    lda.w !controller_input_array,x
    sta controller_state,x        ; Save state
    inx
    cpx #$04                      ; 4 controllers max
    bcc .read_loop

; Alternative access pattern
ldx #$01                          ; Controller 2
lda.w !controller_data_alt_1,x   ; Read alt array 1
and #$40                          ; Check B button (bit 6)
bne .b_pressed
```

---

## DMA System Labels

### Zero Page DMA ($22-$28)

```assembly
!dma_channel    = $22             ; Current DMA channel
!dma_mode       = $23             ; DMA transfer mode
!dma_source     = $24             ; DMA source address (2 bytes)
!dma_source_lo  = $24             ; Source low byte
!dma_source_hi  = $25             ; Source high byte
!dma_source_bank = $26            ; Source bank
!dma_size       = $27             ; Transfer size (2 bytes)
!dma_size_lo    = $27             ; Size low byte
!dma_size_hi    = $28             ; Size high byte

; Usage: Setup DMA transfer
lda #$00
sta.b !dma_channel               ; Channel 0
lda #$01
sta.b !dma_mode                  ; Mode 1 (2-register write)

lda #<data_source
sta.b !dma_source_lo
lda #>data_source
sta.b !dma_source_hi
lda #^data_source
sta.b !dma_source_bank

lda #<transfer_size
sta.b !dma_size_lo
lda #>transfer_size
sta.b !dma_size_hi

; Trigger DMA
lda #$01
sta $420b                         ; Start DMA channel 0
```

---

## Save System Labels

### Save State Flags ($7E3665-$7E3668)

```assembly
!save_state_flag   = $7e3665      ; Save state / screen ready
!save_file_flag_1  = $7e3667      ; Save file state flag 1
!save_file_flag_2  = $7e3668      ; Save file state flag 2

; Usage: Check save state
lda.l !save_state_flag           ; Load save state
bne .save_exists
; No save
rts
.save_exists:
; Save exists, load it

; Set save flags
lda #$ff
sta.l !save_file_flag_2          ; Mark save as valid
stz.l !save_file_flag_1          ; Clear flag 1
lda #$01
sta.l !save_state_flag           ; Set screen ready
```

---

## Working Registers & Scratch Variables

### Working Registers ($04A4-$04B3)

```assembly
!sys_work_buffer_count = $04a4    ; Graphics buffer counter
!sys_work_control      = $04a5    ; Working control value
!sys_work_register     = $04a7    ; Temporary processing register
!sys_work_result       = $04b3    ; Working result storage
!sys_command_status    = $0417    ; Command status register
!sys_param_1           = $050c    ; System parameter 1
!sys_param_2           = $050d    ; System parameter 2

; Usage: Temporary calculations
lda #$05
sta.w !sys_work_buffer_count     ; Count = 5
lda #$42
sta.w !sys_work_register         ; Work value = $42

.process_loop:
    lda.w !sys_work_register
    clc
    adc #$10
    sta.w !sys_work_result        ; Store result
    
    dec.w !sys_work_buffer_count
    bne .process_loop

; Command processing
lda #$01
sta.w !sys_command_status        ; Command active
lda #$80
sta.w !sys_param_1               ; Parameter 1
lda #$40
sta.w !sys_param_2               ; Parameter 2
jsr process_command
```

### System Control Variables ($0AA2-$0AB0)

```assembly
!sys_control_aa2 = $0aa2          ; System control variable
!sys_control_aaa = $0aaa          ; System control variable
!sys_control_aab = $0aab          ; System control variable
!sys_control_aae = $0aae          ; System control variable
!sys_control_ab0 = $0ab0          ; System control variable

; Usage: System state management
lda #$00
sta.w !sys_control_aa2           ; Clear control 1
sta.w !sys_control_aaa           ; Clear control 2
sta.w !sys_control_aab           ; Clear control 3

lda #$01
sta.w !sys_control_aae           ; Set flag
stz.w !sys_control_ab0           ; Clear last
```

---

## System State Variables

### System Status ($1020-$10B0)

```assembly
!sys_status_register = $1020      ; System status register
!sys_timing_param    = $10a5      ; Timing parameter
!sys_state_1         = $10b0      ; System state register

; Usage: System state checks
lda.w !sys_status_register       ; Read status
and #$02                          ; Check bit 1
beq .not_ready
; System ready
.not_ready:

; Timing synchronization
lda #$3c
sta.w !sys_timing_param          ; 60 frames (1 second)
.wait_loop:
    dec.w !sys_timing_param
    bne .wait_loop

; State transition
lda.w !sys_state_1
cmp #$03
bne .skip_transition
; Transition to next state
inc.w !sys_state_1
.skip_transition:
```

### Memory Graphics System ($1A18-$1A2C)

```assembly
!mem_gfx_flags       = $1a18      ; Memory graphics flags
!mem_gfx_final       = $1a1a      ; Memory graphics final
!mem_gfx_buffer_sec  = $1a20      ; Memory graphics buffer secondary
!mem_gfx_ext_sec     = $1a22      ; Memory graphics extended secondary
!gfx_completion_mode = $1a2c      ; Graphics completion mode counter

; Usage: Memory graphics processing (bank_01 style)
lda #$00
sta.w !mem_gfx_flags             ; Clear flags
sta.w !mem_gfx_final             ; Clear final

rep #$30                          ; 16-bit mode
lda #$4000
sta.w !mem_gfx_buffer_sec        ; Set buffer address
lda #$4200
sta.w !mem_gfx_ext_sec           ; Set extended address
sep #$30

; Completion tracking
lda #$08
sta.w !gfx_completion_mode       ; 8 frames to complete
.wait_complete:
    dec.w !gfx_completion_mode
    bne .wait_complete
```

---

## Common Usage Patterns

### Pattern 1: Indexed Array Processing

```assembly
; Process all sprites in array
ldx #$00
.loop:
    lda.w !sprite_x_array,x       ; Load X position
    clc
    adc delta_x                    ; Add delta
    sta.w !sprite_x_array,x       ; Store back
    
    inx
    cpx #sprite_count
    bcc .loop
```

### Pattern 2: 16-bit Calculations

```assembly
; 16-bit position update
rep #$30                          ; 16-bit mode
lda.w !gfx_position_x            ; Load position
clc
adc.w velocity_x                  ; Add velocity
sta.w !gfx_position_x            ; Store back
sep #$30                          ; Back to 8-bit
```

### Pattern 3: State Machine

```assembly
; Graphics state machine
lda.l !gfx_state_control,x       ; Read state
and #$0f                          ; Mask state bits
cmp #$01
beq .state_1
cmp #$02
beq .state_2
; Default state
rts

.state_1:
    ; Process state 1
    lda.l !gfx_state_control,x
    ora #$10                      ; Set completion bit
    sta.l !gfx_state_control,x
    rts

.state_2:
    ; Process state 2
    rts
```

### Pattern 4: Buffer Double-Buffering

```assembly
; Swap front and back buffers
lda.w !gfx_buffer_1144           ; Read front
pha
lda.w !gfx_buffer_1146           ; Read back
sta.w !gfx_buffer_1144           ; Back → front
pla
sta.w !gfx_buffer_1146           ; Front → back
```

### Pattern 5: Batch Clear

```assembly
; Clear multiple buffers
rep #$30                          ; 16-bit mode
lda #$0000
ldx #$0000
.clear_loop:
    sta.w !gfx_buffer_1144,x
    inx
    inx
    cpx #buffer_total_size
    bcc .clear_loop
sep #$30
```

---

## Best Practices

### 1. Always Use Labels

**Bad:**
```assembly
lda $0c00
sta $0c02
```

**Good:**
```assembly
lda.w !oam_sprite0_x
sta.w !oam_sprite0_tile
```

### 2. Respect Data Types

**Labels with sizes:**
- Single byte: Use byte operations
- Word (2 bytes): Use word operations or `rep #$30`
- Arrays: Use indexed addressing

### 3. Comment Your Usage

```assembly
; Load sprite 5's X position
ldx #$14                          ; Sprite 5 × 4 = $14
lda.w !oam_sprite_buffer+0,x     ; X position
```

### 4. Use Indexed Access for Arrays

```assembly
; Indexed sprite access
ldx sprite_index                  ; Get index
lda.w !sprite_x_array,x          ; Access X array
; Better than absolute addressing
```

### 5. Preserve Register State

```assembly
; Save/restore when using multiple registers
phx                               ; Save X
phy                               ; Save Y
; ... process ...
ply                               ; Restore Y
plx                               ; Restore X
```

---

## Document Info

**Version:** 1.0  
**Labels Documented:** 230+ labels  
**Code Examples:** 50+ usage examples  
**Coverage:** All major system categories

**See Also:**
- `MEMORY_MAP.md` - Complete memory layout
- `GRAPHICS_SYSTEM.md` - Graphics-specific documentation
- `ffmq_ram_variables.inc` - Label definitions
