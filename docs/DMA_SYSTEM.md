# FFMQ DMA System Architecture

## Table of Contents

1. [Overview](#overview)
2. [SNES DMA Hardware](#snes-dma-hardware)
3. [DMA Channel Configuration](#dma-channel-configuration)
4. [Transfer Modes](#transfer-modes)
5. [HDMA Effects](#hdma-effects)
6. [FFMQ DMA Usage](#ffmq-dma-usage)
7. [Performance Optimization](#performance-optimization)
8. [Code Examples](#code-examples)

---

## Overview

The SNES Direct Memory Access (DMA) system allows rapid data transfer between memory regions without CPU intervention. FFMQ uses DMA extensively for graphics uploads, sprite updates, and special effects.

### Key Features

- **8 DMA channels:** Independent, simultaneous transfers
- **High bandwidth:** ~2.68 MB/s peak transfer rate
- **Flexible modes:** Byte, word, and pattern-based transfers
- **HDMA support:** Scanline-based effects (Mode 7, parallax, color)
- **Zero CPU overhead:** CPU freed during transfers (with caveats)

### DMA Use Cases in FFMQ

| Use Case                | DMA Channel | Transfer Size | Frequency        |
|-------------------------|-------------|---------------|------------------|
| OAM sprite data         | 0           | 544 bytes     | Every frame      |
| CGRAM palette           | 1           | 512 bytes     | On palette change|
| VRAM tileset            | 2           | 2-16 KB       | Scene transitions|
| VRAM tilemap            | 3           | 2-4 KB        | Map updates      |
| Audio data to SPC700    | 4           | Variable      | Music/SFX load   |
| HDMA color effects      | 5 (HDMA)    | Per-scanline  | Continuous       |
| HDMA scroll effects     | 6 (HDMA)    | Per-scanline  | Continuous       |
| General purpose         | 7           | Variable      | As needed        |

---

## SNES DMA Hardware

### DMA Registers

Each of the 8 DMA channels has dedicated control registers:

| Register | Address  | Purpose                                    |
|----------|----------|--------------------------------------------|
| DMAPx    | $43x0    | DMA parameters (mode, direction, etc.)     |
| BBADx    | $43x1    | Bus B address (PPU register $21xx)         |
| A1TxL    | $43x2    | DMA source address (low byte)              |
| A1TxH    | $43x3    | DMA source address (high byte)             |
| A1Bx     | $43x4    | DMA source bank                            |
| DASxL    | $43x5    | DMA size (low byte)                        |
| DASxH    | $43x6    | DMA size (high byte)                       |
| A2AxL    | $43x7    | HDMA table address (low) / unused for DMA  |
| A2AxH    | $43x8    | HDMA table address (high) / unused for DMA |
| NTRLx    | $43x9    | HDMA line counter / unused for DMA         |
| UNUSEDx  | $43xA    | Unused                                     |

**x** = Channel number (0-7)

### Global DMA Control

| Register | Address | Purpose                                    |
|----------|---------|-------------------------------------------|
| MDMAEN   | $420B   | Enable DMA channels (bits 0-7)            |
| HDMAEN   | $420C   | Enable HDMA channels (bits 0-7)           |

### Transfer Timing

DMA transfers occur during CPU execution halt:
- **CPU halted:** Yes (DMA blocks CPU)
- **Transfer rate:** ~2.68 MB/s (one byte every 8 master cycles)
- **Overhead:** ~18 cycles setup per channel
- **Total time:** setup + (size × 8 cycles)

**Example timing:**
```
Transfer 544 bytes (OAM):
  Setup: 18 cycles
  Data: 544 × 8 = 4352 cycles
  Total: 4370 cycles (~204 µs at 21.47 MHz)
```

---

## DMA Channel Configuration

### DMAPx Register ($43x0)

```
Bit 7: Direction (0 = A→B, 1 = B→A)
Bit 6: HDMA addressing mode (0 = direct, 1 = indirect)
Bit 5: Reserved
Bit 4: Increment/decrement (0 = increment, 1 = decrement)
Bits 3-0: Transfer mode

Transfer Modes:
  %0000: 1-register write (A→B)
  %0001: 2-register write (A→B, A→B+1)
  %0010: 1-register write twice (A→B, A→B)
  %0011: 2-register write twice (A→B, A→B+1, A→B, A→B+1)
  %0100: 4-register write (A→B, A→B+1, A→B+2, A→B+3)
  %0101-0111: Variations of above
```

### Common Configuration Examples

#### OAM Upload (Mode 0)

```assembly
; Upload 544 bytes to OAM
lda #$00                          ; Mode 0: 1-register write
sta $4300                         ; Channel 0 parameters
lda #$04                          ; Write to $2104 (OAM data)
sta $4301                         ; Bus B address
lda #<oam_buffer
sta $4302                         ; Source low
lda #>oam_buffer
sta $4303                         ; Source high
lda #^oam_buffer
sta $4304                         ; Source bank
lda #$20                          ; Size low (544 = $220)
sta $4305
lda #$02                          ; Size high
sta $4306
lda #$01                          ; Enable channel 0
sta $420b                         ; Start DMA
```

#### Palette Upload (Mode 0)

```assembly
; Upload 512 bytes to CGRAM
lda #$00                          ; Mode 0
sta $4310                         ; Channel 1 parameters
lda #$22                          ; Write to $2122 (CGRAM data)
sta $4311                         ; Bus B address
lda #<palette_buffer
sta $4312                         ; Source low
lda #>palette_buffer
sta $4313                         ; Source high
lda #^palette_buffer
sta $4314                         ; Source bank
lda #$00                          ; Size low (512 = $200)
sta $4315
lda #$02                          ; Size high
sta $4316
lda #$02                          ; Enable channel 1
sta $420b                         ; Start DMA
```

#### VRAM Upload (Mode 1)

```assembly
; Upload 8 KB tileset to VRAM
lda #$01                          ; Mode 1: 2-register write
sta $4320                         ; Channel 2 parameters
lda #$18                          ; Write to $2118/$2119 (VRAM data)
sta $4321                         ; Bus B address

; Set VRAM address
lda #$00
sta $2116                         ; VRAM address low
lda #$40
sta $2117                         ; VRAM address high ($4000)

; Set VRAM increment mode
lda #$80                          ; Increment on $2119 write
sta $2115

lda #<tileset_data
sta $4322                         ; Source low
lda #>tileset_data
sta $4323                         ; Source high
lda #^tileset_data
sta $4324                         ; Source bank
lda #$00                          ; Size low (8192 = $2000)
sta $4325
lda #$20                          ; Size high
sta $4326
lda #$04                          ; Enable channel 2
sta $420b                         ; Start DMA
```

---

## Transfer Modes

### Mode 0: Single-Register Write

**Pattern:** A → B

**Use cases:**
- OAM data upload ($2104)
- CGRAM palette upload ($2122)
- Simple byte streams

**Data format:**
```
Source: [byte0] [byte1] [byte2] ...
Writes: byte0→B, byte1→B, byte2→B, ...
```

### Mode 1: Two-Register Write

**Pattern:** A → B, A+1 → B+1

**Use cases:**
- VRAM data upload ($2118/$2119)
- 16-bit word transfers

**Data format:**
```
Source: [low0] [high0] [low1] [high1] ...
Writes: low0→B, high0→B+1, low1→B, high1→B+1, ...
```

### Mode 2: Single-Register Write Twice

**Pattern:** A → B, A+1 → B

**Use cases:**
- Special VRAM patterns
- Double-buffered writes

**Data format:**
```
Source: [byte0] [byte1] [byte2] [byte3] ...
Writes: byte0→B, byte1→B, byte2→B, byte3→B, ...
```

### Mode 3: Two-Register Write Twice

**Pattern:** A → B, A+1 → B+1, A+2 → B, A+3 → B+1

**Use cases:**
- Complex VRAM patterns
- Interleaved data

### Mode 4: Four-Register Write

**Pattern:** A → B, A+1 → B+1, A+2 → B+2, A+3 → B+3

**Use cases:**
- Multi-register initialization
- Complex PPU setups

---

## HDMA Effects

### HDMA Overview

Horizontal blanking DMA (HDMA) transfers data every scanline:
- Executes during HBlank (horizontal blanking)
- Can update PPU registers per-scanline
- Enables advanced visual effects

### HDMA Configuration

HDMA uses same registers as DMA but different setup:

```assembly
; HDMA channel setup
lda #$02                          ; HDMA mode (varies)
ora #$40                          ; Set HDMA addressing bit
sta $43x0                         ; DMAPx

lda #<hdma_table
sta $43x2                         ; Source low (table address)
lda #>hdma_table
sta $43x3                         ; Source high
lda #^hdma_table
sta $43x4                         ; Source bank

lda #$01                          ; Enable HDMA channel x
sta $420c                         ; HDMAEN register
```

### HDMA Table Format

**Direct HDMA:**
```
hdma_table:
  .db scanline_count, data_byte(s)
  .db scanline_count, data_byte(s)
  ...
  .db $00                         ; End marker
```

**Indirect HDMA:**
```
hdma_table:
  .db scanline_count
  .dw data_address
  .db scanline_count
  .dw data_address
  ...
  .db $00                         ; End marker
```

### Common HDMA Effects in FFMQ

#### 1. Color Gradient (Battle Backgrounds)

```assembly
; Fade background color top to bottom
hdma_color_gradient:
  .db $10, $00, $00              ; 16 lines: Black
  .db $10, $08, $00              ; 16 lines: Dark blue
  .db $10, $10, $00              ; 16 lines: Blue
  .db $10, $18, $00              ; 16 lines: Light blue
  .db $10, $1f, $00              ; 16 lines: Bright blue
  .db $00                         ; End

; Setup HDMA channel 5 for BG color
lda #$00                          ; Mode 0: 1-register write
ora #$40                          ; HDMA mode
sta $4350
lda #$32                          ; Write to $2132 (COLDATA)
sta $4351
lda #<hdma_color_gradient
sta $4352
lda #>hdma_color_gradient
sta $4353
lda #^hdma_color_gradient
sta $4354
lda #$20                          ; Enable HDMA channel 5
sta $420c
```

#### 2. Parallax Scrolling (Layer Offsets)

```assembly
; Wavy water effect (horizontal scroll per line)
hdma_water_scroll:
  .db $01                         ; 1 line
  .dw scroll_line_0
  .db $01
  .dw scroll_line_1
  ; ... (repeat for all 224 lines)
  .db $00

scroll_line_0:  .dw $0000         ; No offset
scroll_line_1:  .dw $0001         ; 1 pixel right
scroll_line_2:  .dw $0002         ; 2 pixels right
; ... (sine wave pattern)

; Setup HDMA for BG1 horizontal scroll
lda #$01                          ; Mode 1: 2-register write
ora #$40                          ; HDMA mode (indirect)
sta $4360
lda #$0d                          ; Write to $210D (BG1HOFS)
sta $4361
lda #<hdma_water_scroll
sta $4362
lda #>hdma_water_scroll
sta $4363
lda #^hdma_water_scroll
sta $4364
lda #$40                          ; Enable HDMA channel 6
sta $420c
```

#### 3. Mode 7 Perspective (3D Floor Effect)

```assembly
; Mode 7 scaling per-scanline for 3D floor
hdma_mode7_scale:
  .db $01                         ; 1 line
  .dw scale_near
  .db $01
  .dw scale_mid
  .db $01
  .dw scale_far
  ; ... (repeat for horizon effect)
  .db $00

scale_near: .dw $0100             ; 1.0× scale (near)
scale_mid:  .dw $0180             ; 1.5× scale (middle)
scale_far:  .dw $0200             ; 2.0× scale (far/horizon)

; Setup HDMA for Mode 7 matrix A
lda #$01                          ; Mode 1
ora #$40                          ; HDMA indirect
sta $4370
lda #$1b                          ; Write to $211B (M7A)
sta $4371
lda #<hdma_mode7_scale
sta $4372
lda #>hdma_mode7_scale
sta $4373
lda #^hdma_mode7_scale
sta $4374
lda #$80                          ; Enable HDMA channel 7
sta $420c
```

---

## FFMQ DMA Usage

### Zero Page DMA Variables ($22-$28)

```assembly
!dma_channel    = $22             ; Current DMA channel (0-7)
!dma_mode       = $23             ; DMA transfer mode
!dma_source     = $24             ; DMA source address (2 bytes)
!dma_source_lo  = $24
!dma_source_hi  = $25
!dma_source_bank = $26            ; Source bank
!dma_size       = $27             ; Transfer size (2 bytes)
!dma_size_lo    = $27
!dma_size_hi    = $28
```

### Battle Graphics DMA Coordinates ($0CD0-$0CDC)

```assembly
!dma_dest_addr      = $0cd0       ; DMA destination X coordinate
!dma_source_addr    = $0cd4       ; DMA source X+8 coordinate
!dma_dest_addr_alt  = $0cd8       ; DMA source high address
!dma_source_addr_alt = $0cdc      ; DMA destination high address
```

These coordinates are used for sprite DMA during battles:
- **X coordinate mapping:** Transform battle coordinates to VRAM addresses
- **Dual addressing:** Support ping-pong buffering
- **High addresses:** Extended VRAM range support

### Common DMA Patterns in FFMQ

#### 1. OAM Update (Every Frame)

```assembly
; Upload sprite data to OAM
UpdateOAM:
    ; Setup DMA channel 0
    lda #$00
    sta !dma_channel
    sta !dma_mode                 ; Mode 0
    
    lda #<oam_buffer
    sta !dma_source_lo
    lda #>oam_buffer
    sta !dma_source_hi
    lda #$00                      ; Bank 0 (WRAM)
    sta !dma_source_bank
    
    lda #$20                      ; 544 bytes ($220)
    sta !dma_size_lo
    lda #$02
    sta !dma_size_hi
    
    jsr ExecuteDMATransfer        ; Common DMA routine
    rts
```

#### 2. Palette Fade (Color Effects)

```assembly
; Upload faded palette to CGRAM
UploadPalette:
    ; Set CGRAM address
    stz $2121                     ; Start at color 0
    
    ; Setup DMA channel 1
    lda #$01
    sta !dma_channel
    lda #$00
    sta !dma_mode                 ; Mode 0
    
    lda #<palette_buffer
    sta !dma_source_lo
    lda #>palette_buffer
    sta !dma_source_hi
    lda #$00
    sta !dma_source_bank
    
    lda #$00                      ; 512 bytes ($200)
    sta !dma_size_lo
    lda #$02
    sta !dma_size_hi
    
    jsr ExecuteDMATransfer
    rts
```

#### 3. Tileset Swap (Scene Transition)

```assembly
; Load new tileset to VRAM
LoadTileset:
    ; Set VRAM address and increment
    lda #$00
    sta $2116                     ; VRAM address low
    lda #$40
    sta $2117                     ; VRAM address high ($4000)
    lda #$80
    sta $2115                     ; Increment on $2119 write
    
    ; Setup DMA channel 2
    lda #$02
    sta !dma_channel
    lda #$01                      ; Mode 1 (2-register write)
    sta !dma_mode
    
    lda #<tileset_data
    sta !dma_source_lo
    lda #>tileset_data
    sta !dma_source_hi
    lda #^tileset_data
    sta !dma_source_bank
    
    lda #$00                      ; 16 KB ($4000)
    sta !dma_size_lo
    lda #$40
    sta !dma_size_hi
    
    jsr ExecuteDMATransfer
    rts
```

---

## Performance Optimization

### DMA Timing Considerations

#### Frame Budget

NTSC frame: 16.67 ms (at 60 Hz)
- **VBlank time:** ~1.3 ms (available for DMA/updates)
- **Typical DMA usage:** 0.5-1.0 ms per frame
- **Headroom:** ~30-50% of VBlank

**Frame time breakdown:**
```
Total frame: 16.67 ms (100%)
  VBlank:     1.30 ms (7.8%) ← DMA window
    OAM DMA:    0.20 ms (1.2%)
    Palette:    0.10 ms (0.6%) [occasional]
    Other:      0.20 ms (1.2%)
    Available:  0.80 ms (4.8%)
  
  Active display: 15.37 ms (92.2%)
    Game logic:     8.00 ms
    Physics:        2.00 ms
    Input:          0.50 ms
    Audio:          1.00 ms
    Available:      3.87 ms
```

### Optimization Strategies

#### 1. Batch Transfers

**Bad (multiple small DMAs):**
```assembly
; Upload palette colors one at a time
ldx #$00
.loop:
    ; Setup DMA for 2 bytes
    ; ... (DMA config overhead: 18 cycles)
    ; Transfer 2 bytes (16 cycles)
    inx
    inx
    cpx #$200                     ; 256 colors × 2 bytes
    bcc .loop
; Total: (18 + 16) × 256 = 8704 cycles
```

**Good (single batch DMA):**
```assembly
; Upload entire palette at once
; Setup DMA for 512 bytes (18 cycles)
; Transfer 512 bytes (4096 cycles)
; Total: 18 + 4096 = 4114 cycles (2.1× faster!)
```

#### 2. Use Appropriate DMA Channels

Reserve channels for specific tasks:
- **Channels 0-1:** High-frequency (OAM, palette)
- **Channels 2-4:** Medium-frequency (VRAM, audio)
- **Channels 5-7:** HDMA effects

#### 3. Minimize Transfer Size

**Delta compression example:**
```assembly
; Only upload changed OAM sprites
UpdateOAMDelta:
    ; Check which sprites changed
    ldx #$00
    ldy #$00                      ; Destination offset
.check_loop:
    lda sprite_dirty_flags,x
    beq .skip_sprite              ; Not dirty, skip
    
    ; Copy sprite data (4 bytes)
    lda oam_buffer+0,x
    sta oam_upload_buffer,y
    iny
    lda oam_buffer+1,x
    sta oam_upload_buffer,y
    iny
    lda oam_buffer+2,x
    sta oam_upload_buffer,y
    iny
    lda oam_buffer+3,x
    sta oam_upload_buffer,y
    iny
    
.skip_sprite:
    ; Clear dirty flag
    stz sprite_dirty_flags,x
    
    ; Next sprite
    inx
    cpx #128                      ; 128 sprites
    bcc .check_loop
    
    ; Upload only changed sprites
    sty !dma_size_lo              ; Y = actual size
    stz !dma_size_hi
    jsr ExecuteDMATransfer
    rts
```

**Result:** Instead of 544 bytes every frame, upload only ~50-100 bytes (5-10× reduction!)

#### 4. Interleave DMA with CPU Work

```assembly
; Don't just wait during DMA
UpdateGraphics:
    ; Start DMA transfer
    jsr StartOAMDMA               ; Non-blocking
    
    ; Do other work while DMA executes
    jsr UpdateAudioBuffers
    jsr ProcessInput
    jsr UpdateTimers
    
    ; Wait for DMA completion (if needed)
    jsr WaitDMAComplete
    rts
```

#### 5. Use HDMA for Continuous Effects

Instead of updating registers every frame with DMA:

**CPU-based (expensive):**
```assembly
; Update 224 scanlines every frame
UpdateScrollEffect:
    lda frame_counter
    ldx #$00
.loop:
    ; Calculate scroll offset for line X
    jsr CalculateSineWave         ; Expensive!
    sta scroll_table,x
    inx
    cpx #224
    bcc .loop
    
    ; Upload 224 words to PPU (448 bytes DMA)
    ; ... (costs ~2000 cycles)
```

**HDMA-based (cheap):**
```assembly
; Setup once, runs automatically
SetupScrollHDMA:
    ; Configure HDMA channel
    lda #$01
    ora #$40
    sta $4360
    lda #$0d                      ; BG1HOFS
    sta $4361
    lda #<scroll_table
    sta $4362
    lda #>scroll_table
    sta $4363
    lda #^scroll_table
    sta $4364
    lda #$40
    sta $420c                     ; Enable HDMA
    
    ; Done! No CPU time per frame
    rts
```

**Savings:** ~2000 cycles/frame → ~0 cycles/frame (HDMA runs during HBlank)

---

## Code Examples

### Example 1: Generic DMA Transfer Routine

```assembly
; Generic DMA transfer using zero-page variables
; Inputs: !dma_channel, !dma_mode, !dma_source, !dma_size
ExecuteDMATransfer:
    ; Calculate register base ($43x0)
    lda !dma_channel
    asl a
    asl a
    asl a
    asl a                         ; × 16
    tax                           ; X = channel offset
    
    ; Set DMA parameters
    lda !dma_mode
    sta $4300,x                   ; DMAPx
    
    lda #$04                      ; Default: Write to $2104 (OAM)
    sta $4301,x                   ; BBADx
    
    lda !dma_source_lo
    sta $4302,x                   ; A1TxL
    lda !dma_source_hi
    sta $4303,x                   ; A1TxH
    lda !dma_source_bank
    sta $4304,x                   ; A1Bx
    
    lda !dma_size_lo
    sta $4305,x                   ; DASxL
    lda !dma_size_hi
    sta $4306,x                   ; DASxH
    
    ; Enable channel
    lda !dma_channel
    tax
    lda power_of_2_table,x        ; Convert to bit mask
    sta $420b                     ; Start DMA
    
    rts

power_of_2_table:
    .db $01, $02, $04, $08, $10, $20, $40, $80
```

### Example 2: Battle Sprite DMA with Coordinates

```assembly
; Upload battle sprite using 4D coordinate mapping
UploadBattleSprite:
    ; Load battle coordinates
    ldx sprite_index
    lda #$08
    jsr MultiplyA                 ; A = index × 8
    tax
    
    rep #$30                      ; 16-bit mode
    lda.w !battle_coord_x_lo,x
    sta temp_x
    lda.w !battle_coord_y_lo,x
    sta temp_y
    sep #$30
    
    ; Convert coordinates to VRAM address
    ; VRAM_addr = $4000 + (Y × 32) + X
    rep #$30
    lda temp_y
    asl a
    asl a
    asl a
    asl a
    asl a                         ; Y × 32
    clc
    adc temp_x                    ; + X
    clc
    adc #$4000                    ; + base address
    sta.w !dma_dest_addr          ; Store destination
    sep #$30
    
    ; Calculate source address (sprite data)
    lda sprite_tile_id
    asl a
    asl a
    asl a
    asl a                         ; Tile ID × 16 (16 bytes/tile)
    clc
    adc #<sprite_data
    sta !dma_source_lo
    lda #>sprite_data
    adc #$00                      ; Carry
    sta !dma_source_hi
    lda #^sprite_data
    sta !dma_source_bank
    
    ; Setup DMA
    lda #$02
    sta !dma_channel              ; Channel 2
    lda #$01
    sta !dma_mode                 ; Mode 1 (VRAM)
    lda #$10                      ; 16 bytes
    sta !dma_size_lo
    stz !dma_size_hi
    
    ; Set VRAM address
    rep #$30
    lda.w !dma_dest_addr
    sta $2116                     ; VRAM address
    sep #$30
    lda #$80
    sta $2115                     ; Increment mode
    
    jsr ExecuteDMATransfer
    rts
```

### Example 3: Multi-Channel Simultaneous DMA

```assembly
; Upload OAM + Palette + Tilemap simultaneously
UpdateGraphicsAll:
    ; Disable rendering
    lda $2100
    pha                           ; Save brightness
    lda #$80
    sta $2100                     ; Force blank
    
    ; Setup Channel 0: OAM
    lda #$00
    sta $4300                     ; Mode 0
    lda #$04
    sta $4301                     ; $2104 (OAM)
    lda #<oam_buffer
    sta $4302
    lda #>oam_buffer
    sta $4303
    lda #$00
    sta $4304
    lda #$20
    sta $4305                     ; 544 bytes
    lda #$02
    sta $4306
    
    ; Setup Channel 1: CGRAM
    stz $2121                     ; CGRAM address 0
    lda #$00
    sta $4310                     ; Mode 0
    lda #$22
    sta $4311                     ; $2122 (CGRAM)
    lda #<palette_buffer
    sta $4312
    lda #>palette_buffer
    sta $4313
    lda #$00
    sta $4314
    lda #$00
    sta $4315                     ; 512 bytes
    lda #$02
    sta $4316
    
    ; Setup Channel 2: VRAM Tilemap
    lda #$00
    sta $2116                     ; VRAM address $0000
    stz $2117
    lda #$80
    sta $2115                     ; Increment on $2119
    lda #$01
    sta $4320                     ; Mode 1
    lda #$18
    sta $4321                     ; $2118/$2119 (VRAM)
    lda #<tilemap_buffer
    sta $4322
    lda #>tilemap_buffer
    sta $4323
    lda #$00
    sta $4324
    lda #$00
    sta $4325                     ; 2048 bytes
    lda #$08
    sta $4326
    
    ; Start all channels simultaneously!
    lda #$07                      ; Channels 0, 1, 2
    sta $420b                     ; Go!
    
    ; Restore rendering
    pla
    sta $2100                     ; Restore brightness
    
    rts
```

### Example 4: Dynamic HDMA Table Generation

```assembly
; Generate sine wave scroll table for water effect
GenerateWaterScroll:
    ; Water parameters
    lda #$40
    sta wave_amplitude            ; Amplitude: 64 pixels
    lda #$20
    sta wave_frequency            ; Frequency: 32 pixels/cycle
    
    ldx #$00                      ; Scanline index
    ldy #$00                      ; Table index
    
.line_loop:
    ; Calculate sine value for scanline X
    stx temp_scanline
    
    ; sine_value = sin(scanline × frequency) × amplitude
    lda temp_scanline
    sta temp_a
    lda wave_frequency
    sta temp_b
    jsr Multiply8                 ; scanline × frequency
    
    lda result
    and #$ff                      ; Wrap to 0-255
    tax
    lda sine_table,x              ; Look up sine (-127 to 127)
    
    ; Scale by amplitude
    sta temp_a
    lda wave_amplitude
    sta temp_b
    jsr Multiply8
    lda result
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a
    lsr a                         ; Divide by 128
    
    ; Store to HDMA table (indirect mode)
    ldx temp_scanline
    ldy #$00
    
    ; Scanline count (1 line)
    lda #$01
    sta hdma_water_table,y
    iny
    
    ; Address of scroll value (low)
    lda #<scroll_values
    clc
    adc temp_scanline
    adc temp_scanline             ; × 2 (word address)
    sta hdma_water_table,y
    iny
    
    ; Address of scroll value (high)
    lda #>scroll_values
    adc #$00                      ; Carry
    sta hdma_water_table,y
    iny
    
    ; Store actual scroll value
    ldx temp_scanline
    lda result
    sta scroll_values,x
    sta scroll_values+1,x         ; Word value
    
    ; Next scanline
    ldx temp_scanline
    inx
    cpx #224                      ; All scanlines
    bcc .line_loop
    
    ; End marker
    lda #$00
    sta hdma_water_table,y
    
    rts

; Sine table (256 entries, -127 to 127)
sine_table:
    .db $00, $03, $06, $09, $0c, $0f, $12, $15
    .db $18, $1b, $1e, $21, $24, $27, $2a, $2d
    ; ... (full 256-byte table)
```

### Example 5: Compressed Tileset DMA

```assembly
; Upload compressed tileset using RLE decompression
UploadCompressedTileset:
    ; Set VRAM destination
    lda #$00
    sta $2116
    lda #$40
    sta $2117                     ; VRAM $4000
    lda #$80
    sta $2115                     ; Increment on $2119
    
    ; Decompress directly to VRAM
    lda #<compressed_tileset
    sta source_ptr
    lda #>compressed_tileset
    sta source_ptr+1
    lda #^compressed_tileset
    sta source_bank
    
    ldy #$00                      ; Source offset
    
.decompress_loop:
    ; Read control byte
    lda [source_ptr],y
    iny
    bmi .run_length               ; Bit 7 = RLE run
    
    ; Literal bytes
    tax                           ; X = count
    beq .done                     ; 0 = end
    
.literal_loop:
    lda [source_ptr],y
    iny
    sta $2118                     ; Write to VRAM low
    lda [source_ptr],y
    iny
    sta $2119                     ; Write to VRAM high
    dex
    bne .literal_loop
    bra .decompress_loop
    
.run_length:
    ; RLE run
    and #$7f                      ; Mask count (0-127)
    tax                           ; X = count
    
    ; Read value
    lda [source_ptr],y
    iny
    sta temp_value_lo
    lda [source_ptr],y
    iny
    sta temp_value_hi
    
    ; Write value X times
.run_loop:
    lda temp_value_lo
    sta $2118
    lda temp_value_hi
    sta $2119
    dex
    bne .run_loop
    bra .decompress_loop
    
.done:
    rts
```

---

## Document Info

**Version:** 1.0  
**Last Updated:** December 2024  
**DMA Channels:** 8 (0-7)  
**Transfer Rate:** ~2.68 MB/s peak  
**HDMA Channels:** Up to 8 simultaneous

**See Also:**
- `MEMORY_MAP.md` - DMA memory variables ($22-$28, $0CD0-$0CDC)
- `GRAPHICS_SYSTEM.md` - Graphics DMA usage
- `BATTLE_SYSTEM.md` - Battle sprite DMA coordination
- SNES Development Manual - DMA hardware reference
