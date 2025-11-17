# Final Fantasy Mystic Quest - PPU Graphics System Documentation

## Overview

The FFMQ graphics system interfaces with the SNES Picture Processing Unit (PPU) to render all visuals through hardware-accelerated background layers and sprites. The system manages dynamic VRAM allocation, OAM sprite configuration, palette effects, DMA transfers, and Mode 7 special effects.

**Key Features:**

- **Mode 1 Graphics:** 4 BPP + 2 BPP backgrounds with 16-color palettes
- **4 Background Layers:** BG1 (main), BG2 (decorations), BG3 (collision/events), BG4 (unused)
- **128 Hardware Sprites (OAM):** 64KB sprite character space
- **64KB VRAM:** Dynamic allocation for tiles, tilemaps, and sprite data
- **512-byte CGRAM:** 256 colors (16 palettes × 16 colors)
- **8 DMA Channels:** Hardware transfer during VBlank/HBlank
- **Mode 7 Support:** Rotation/scaling for world map and special effects
- **HDMA Effects:** Scanline-accurate updates for wave, transparency

## PPU Architecture

### Hardware Configuration

**PPU Registers:** Memory-mapped $2100-$213F

**Key Capabilities:**
- **4 simultaneous BG layers** (Mode 1: 3 BG + OBJ)
- **128 sprites** (maximum 32 per scanline)
- **262 scanlines** @ 60.098 Hz NTSC (224 visible)
- **256×224 resolution** (overscan: 256×240)
- **15-bit BGR color** (32,768 total colors)
- **32KB VRAM main** + 32KB VRAM mirror
- **544-byte OAM** (512 bytes main + 32 bytes high table)

### VRAM Organization

**Total VRAM:** 64 KB (32,768 words @ $0000-$7FFF)

**FFMQ VRAM Layout (Mode 1):**

```
VRAM Address    Size      Purpose
────────────────────────────────────────────────
$0000-$0FFF     4 KB      BG3 Tilemap (32×32 tiles, 2 BPP)
$1000-$17FF     2 KB      BG3 Character Data (128 tiles)
$2000-$2FFF     4 KB      BG1 Tilemap (32×32 tiles, 16-color)
$3000-$3FFF     4 KB      BG2 Tilemap (32×32 tiles, 16-color)
$4000-$5FFF     8 KB      BG1 Character Data (256 tiles, 4 BPP)
$6000-$7FFF     8 KB      BG2 Character Data (256 tiles, 4 BPP)
$8000-$BFFF    16 KB      Sprite Character Data (512 tiles, 4 BPP)
$C000-$DFFF     8 KB      Dynamic allocation (battle graphics)
$E000-$FFFF     8 KB      Dynamic allocation (special effects)
```

**Notes:**
- Word address mode: Each address = 2 bytes
- BG3 uses 2 BPP (4 colors) for collision/event layer
- BG1/BG2 use 4 BPP (16 colors) for graphics
- Sprites use 4 BPP (16 colors) from 8 palettes

### CGRAM (Color RAM) Organization

**Total CGRAM:** 512 bytes (256 colors)

**Palette Layout:**

```
Palette #   Address     Colors    Purpose
────────────────────────────────────────────────
0-7         $00-$7F     8×16      Background palettes
8-15        $80-$FF     8×16      Sprite/OBJ palettes
```

**Color Format:** 15-bit BGR (0bbbbbgggggrrrrr)

```c
typedef struct {
    uint16_t color;  // Format: 0BBBBBGGGGGRRRRR
    /*
     * Bits 0-4:   Red   (0-31)
     * Bits 5-9:   Green (0-31)
     * Bits 10-14: Blue  (0-31)
     * Bit 15:     Unused (always 0)
     */
} CGRAMColor;
```

**Example Colors:**

```asm
; Black
dw $0000    ; RGB = (0, 0, 0)

; White
dw $7FFF    ; RGB = (31, 31, 31)

; Pure Red
dw $001F    ; RGB = (31, 0, 0)

; Pure Green
dw $03E0    ; RGB = (0, 31, 0)

; Pure Blue
dw $7C00    ; RGB = (0, 0, 31)

; FFMQ UI Blue
dw $5E60    ; RGB = (0, 19, 23)
```

### OAM (Object Attribute Memory)

**OAM Structure:** 544 bytes total

**Main OAM:** 512 bytes (128 sprites × 4 bytes)

```c
typedef struct {
    uint8_t  x;           // $00: X position (0-255)
    uint8_t  y;           // $01: Y position (0-239)
    uint8_t  tile;        // $02: Character/tile number
    uint8_t  attr;        // $03: Attributes
    /*
     * Attr format: VHOOPPPC
     * V = Vertical flip
     * H = Horizontal flip
     * O = Priority (0-3, 3=front)
     * P = Palette (0-7)
     * C = Tile bank (bit 8 of tile number)
     */
} OAMEntry;  // 4 bytes
```

**OAM High Table:** 32 bytes (extra bits for X/size)

```c
typedef struct {
    uint8_t hi_bits;  // Format: SsXxxxxx (per 4 sprites)
    /*
     * Bits 0-3: X position bit 8 for sprites N,N+1,N+2,N+3
     * Bits 4-7: Size select for sprites N,N+1,N+2,N+3
     * S=0: Small size, S=1: Large size
     */
} OAMHighTable[32];
```

**Sprite Sizes (OBSEL Register $2101):**

```
Size Mode 0 (Small/Large = 8×8 / 16×16):
  Small: 8×8 pixels    (1 tile)
  Large: 16×16 pixels  (4 tiles in 2×2 arrangement)

Size Mode 1 (Small/Large = 8×8 / 32×32):
  Small: 8×8 pixels
  Large: 32×32 pixels  (16 tiles in 4×4 arrangement)

Size Mode 6 (Small/Large = 16×16 / 64×64) - FFMQ Battle:
  Small: 16×16 pixels
  Large: 64×64 pixels  (64 tiles in 8×8 arrangement)
```

## DMA Transfer System

### DMA Hardware

**8 DMA Channels:** $4300-$437F (each channel = 16 bytes)

**DMA Control Register ($43X0):**

```
Format: DA-AAAIM
D  = Direction (0=CPU→PPU, 1=PPU→CPU)
A  = HDMA addressing mode
AAA= Transfer mode
I  = Address increment (0=increment, 1=decrement/fixed)
M  = Transfer mode LSB
```

**Transfer Modes:**

```
Mode 0: 1 register write once          (e.g., single byte to $2118)
Mode 1: 2 registers write once         (e.g., $2118, $2119)
Mode 2: 1 register write twice         (e.g., $2118, $2118)
Mode 3: 2 registers write twice each   (e.g., $2118, $2119, $2118, $2119)
Mode 4: 4 registers write once         (e.g., $2118, $2119, $211A, $211B)
```

### VRAM DMA Transfer

**Standard VRAM Upload:**

```asm
; DMA channel 0 setup for VRAM transfer
DMAtransferToVRAM:
    php
    rep #$30                ; 16-bit mode
    
    ; Setup VRAM address
    ldx #$4000              ; Destination VRAM address
    stx !SNES_VMADDL        ; Set VRAM address
    
    ; Setup DMA channel 0
    lda #$01                ; Mode 1: 2 registers write once
    sta !SNES_DMA0PARAM     ; DMA control
    
    lda #$18                ; Destination: $2118 (VMDATAL)
    sta !SNES_DMA0REG       ; PPU register
    
    ldx #TileData           ; Source address low/mid
    stx !SNES_DMA0ADDRL
    
    lda #^TileData          ; Source bank
    sta !SNES_DMA0ADDRH
    
    ldx #$2000              ; Transfer size (8 KB)
    stx !SNES_DMA0CNTL
    
    ; Trigger DMA
    lda #$01                ; Enable channel 0
    sta !SNES_MDMAEN        ; Start DMA transfer
    
    plp
    rts
```

**Performance:**

- **DMA speed:** 2.68 MHz / 8 = ~335 KB/s
- **8 KB transfer:** ~24 microseconds
- **VBlank window:** ~1,310 microseconds (4.5 scanlines @ NTSC)
- **Max transfer/VBlank:** ~43 KB (enough for full VRAM updates)

### OAM DMA Transfer

```asm
; Transfer OAM buffer → hardware OAM
UpdateOAMDMA:
    ; Setup OAM address
    stz !SNES_OAMADDL       ; OAM address = $0000
    stz !SNES_OAMADDH
    
    ; DMA channel 0 for main OAM
    lda #$00                ; Mode 0: 1 register write once
    sta !SNES_DMA0PARAM
    
    lda #$04                ; Destination: $2104 (OAMDATA)
    sta !SNES_DMA0REG
    
    ldx #oam_buffer         ; Source: RAM buffer
    stx !SNES_DMA0ADDRL
    lda #^oam_buffer
    sta !SNES_DMA0ADDRH
    
    ldx #$0200              ; 512 bytes (main OAM)
    stx !SNES_DMA0CNTL
    
    lda #$01
    sta !SNES_MDMAEN        ; Start DMA
    
    ; DMA channel 1 for OAM high table
    lda #$00
    sta !SNES_DMA1PARAM
    lda #$04
    sta !SNES_DMA1REG
    
    ldx #oam_high_buffer
    stx !SNES_DMA1ADDRL
    lda #^oam_high_buffer
    sta !SNES_DMA1ADDRH
    
    ldx #$0020              ; 32 bytes (high table)
    stx !SNES_DMA1CNTL
    
    lda #$02
    sta !SNES_MDMAEN        ; Start DMA channel 1
    
    rts
```

### Palette (CGRAM) DMA

```asm
; Transfer palette data to CGRAM
LoadPaletteDMA:
    ; Setup CGRAM address
    lda #$00                ; Start at color 0
    sta !SNES_CGADD
    
    ; DMA channel 0
    lda #$00                ; Mode 0: single write
    sta !SNES_DMA0PARAM
    
    lda #$22                ; Destination: $2122 (CGDATA)
    sta !SNES_DMA0REG
    
    ldx #palette_buffer
    stx !SNES_DMA0ADDRL
    lda #^palette_buffer
    sta !SNES_DMA0ADDRH
    
    ldx #$0200              ; 512 bytes (full palette)
    stx !SNES_DMA0CNTL
    
    lda #$01
    sta !SNES_MDMAEN
    
    rts
```

## Background Layer System

### Mode 1 Configuration

**BGMODE Register ($2105):**

```asm
; Setup Mode 1
lda #$09                ; Mode 1: BG1=4BPP, BG2=4BPP, BG3=2BPP
sta !SNES_BGMODE
; Format: 000DCBA M
; M   = Mode (001 = Mode 1)
; A   = BG1 tile size (0=8×8, 1=16×16)
; B   = BG2 tile size
; C   = BG3 tile size
; D   = BG4 tile size
```

**Tilemap Configuration:**

```asm
; BG1 tilemap at VRAM $2000, size 32×32
lda #$10                ; $2000 / $400 = $10
sta !SNES_BG1SC
; Format: AAAAAAYX
; AAAAAA = Base address / $400 ($10 = $2000)
; Y      = Horizontal mirroring (0=none, 1=64 tiles)
; X      = Vertical mirroring

; BG2 tilemap at VRAM $3000
lda #$18                ; $3000 / $400 = $18
sta !SNES_BG2SC

; BG3 tilemap at VRAM $0000
lda #$00
sta !SNES_BG3SC
```

**Character Data Configuration:**

```asm
; BG1/BG2 character data
lda #$42                ; BG1=$4000, BG2=$6000
sta !SNES_BG12NBA
; Format: BBBBAAAA
; AAAA = BG1 base / $1000 ($4 = $4000)
; BBBB = BG2 base / $1000 ($6 = $6000)

; BG3/BG4 character data
lda #$10                ; BG3=$1000, BG4=$0000 (unused)
sta !SNES_BG34NBA
```

### Scrolling System

**Scroll Registers:** $210D-$2114 (write twice for 10-bit values)

```asm
; Scroll BG1 to position (X=100, Y=50)
ScrollBG1:
    lda #100                ; X offset low byte
    sta !SNES_BG1HOFS
    lda #0                  ; X offset high 2 bits
    sta !SNES_BG1HOFS
    
    lda #50                 ; Y offset low byte
    sta !SNES_BG1VOFS
    lda #0                  ; Y offset high 2 bits
    sta !SNES_BG1VOFS
    rts

; Smooth scrolling update (called per frame)
UpdateScrolling:
    lda camera_x            ; 16-bit camera position
    sta !SNES_BG1HOFS
    xba                     ; High byte
    sta !SNES_BG1HOFS
    
    lda camera_y
    sta !SNES_BG1VOFS
    xba
    sta !SNES_BG1VOFS
    rts
```

**Parallax Scrolling:**

```asm
; BG1 scrolls at 100%, BG2 at 50% (parallax)
UpdateParallax:
    ; BG1: Full speed
    lda camera_x
    sta !SNES_BG1HOFS
    xba
    sta !SNES_BG1HOFS
    
    ; BG2: Half speed
    lda camera_x
    lsr a                   ; Divide by 2
    sta !SNES_BG2HOFS
    lda camera_x+1
    ror a
    sta !SNES_BG2HOFS
    rts
```

### Tilemap Format

**Tilemap Entry:** 16-bit per tile

```
Format: VHOPPPCC CCCCCCCC
V        = Vertical flip
H        = Horizontal flip
O        = Priority (0=normal, 1=high)
PPP      = Palette number (0-7)
CCCCCCCC = Character/tile number (0-1023)
```

**Example Tilemap Writing:**

```asm
; Write tile to BG1 tilemap
; Input: A = tile number, X = palette, Y = screen position
WriteTileToBG1:
    php
    rep #$30
    
    ; Calculate VRAM address
    ; VRAM = $2000 + (Y_tile × 32 + X_tile) × 2
    tya                     ; Y position
    lsr a                   ; / 8 (tile row)
    lsr a
    lsr a
    asl a                   ; × 64 (32 tiles × 2 bytes)
    asl a
    asl a
    asl a
    asl a
    asl a
    sta $00                 ; Row offset
    
    txa                     ; X position
    lsr a
    lsr a
    lsr a                   ; / 8 (tile column)
    asl a                   ; × 2 bytes
    clc
    adc $00
    adc #$2000              ; + BG1 base
    
    tax
    stx !SNES_VMADDL        ; Set VRAM address
    
    ; Build tile data
    lda tile_number
    and #$03FF              ; Tile number (10 bits)
    sta $02
    
    lda palette_number
    and #$0007              ; Palette (3 bits)
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a
    asl a                   ; Shift to bits 10-12
    ora $02
    ora tile_flags          ; V/H flip, priority
    
    sta !SNES_VMDATAL       ; Write tile data
    
    plp
    rts
```

## Sprite Management System

### Sprite Allocation

**FFMQ Sprite Usage:**

```c
// Sprite allocation strategy
typedef enum {
    SPRITE_PLAYER_START    = 0,    // Sprites 0-7: Player character
    SPRITE_COMPANION_START = 8,    // Sprites 8-15: Companion
    SPRITE_ENEMY_START     = 16,   // Sprites 16-47: Enemies (up to 8 × 4 sprites)
    SPRITE_NPC_START       = 48,   // Sprites 48-79: NPCs/field objects
    SPRITE_EFFECT_START    = 80,   // Sprites 80-111: Effects/particles
    SPRITE_UI_START        = 112,  // Sprites 112-127: UI elements
} SpriteSlotAllocation;
```

### Sprite Update Routine

```asm
; Update single sprite in OAM buffer
; Input: X = sprite index (0-127), Y = sprite data pointer
UpdateSprite:
    php
    rep #$30
    
    ; Calculate OAM buffer offset (sprite × 4)
    txa
    asl a
    asl a
    tax                     ; X = sprite offset
    
    ; Copy sprite data
    lda [Y]                 ; X position
    sta oam_buffer,X
    iny
    iny
    
    lda [Y]                 ; Y position
    sta oam_buffer+1,X
    iny
    iny
    
    lda [Y]                 ; Tile number
    sta oam_buffer+2,X
    iny
    iny
    
    lda [Y]                 ; Attributes
    sta oam_buffer+3,X
    
    plp
    rts

; Update OAM high table (X position bit 8 + size)
UpdateOAMHighTable:
    ; Input: A = sprite index, X = X position (9-bit), Y = size flag
    php
    sep #$20
    
    ; Calculate high table index (sprite / 4)
    lsr a
    lsr a
    tax
    
    ; Build high table byte
    lda sprite_x_positions,X
    lsr a                   ; Get bit 8 of X
    and #$01
    ora sprite_sizes,X      ; Combine with size flags
    
    sta oam_high_buffer,X
    
    plp
    rts
```

### Sprite Animation

```asm
; Animate sprite by cycling through frames
; Input: X = sprite index, A = animation frame
AnimateSprite:
    ; Load frame data
    tax
    lda animation_frame_table,X
    sta current_tile
    
    ; Calculate OAM offset
    lda sprite_index
    asl a
    asl a
    tax
    
    ; Update tile number in OAM
    lda current_tile
    sta oam_buffer+2,X
    
    rts

; Animation frame table (example: walking cycle)
animation_frame_table:
    ; Frame 0: Standing
    db $00, $01, $02, $03
    
    ; Frame 1: Step 1
    db $04, $05, $06, $07
    
    ; Frame 2: Standing
    db $00, $01, $02, $03
    
    ; Frame 3: Step 2
    db $08, $09, $0A, $0B
```

## VBlank Timing

### NMI Handler Structure

```asm
; Non-Maskable Interrupt handler (VBlank)
NMI_Handler:
    php
    pha
    phx
    phy
    phd
    phb
    
    rep #$30                ; 16-bit mode
    
    ; Save data bank
    lda #$0000
    tcd                     ; Direct page = $0000
    
    ; Wait for VBlank confirmation
.wait_vblank:
    lda !SNES_HVBJOY
    and #$0080              ; Check VBlank flag
    beq .wait_vblank
    
    ; Priority 1: OAM update (fastest)
    jsr UpdateOAMDMA
    
    ; Priority 2: Scroll registers
    jsr UpdateScrollRegisters
    
    ; Priority 3: Palette updates
    lda palette_update_flag
    beq .skip_palette
    jsr LoadPaletteDMA
    stz palette_update_flag
    
.skip_palette:
    ; Priority 4: VRAM updates (if time allows)
    lda vram_update_flag
    beq .skip_vram
    jsr UpdateVRAMDMA
    stz vram_update_flag
    
.skip_vram:
    ; Priority 5: HDMA setup
    jsr SetupHDMA
    
    ; Restore registers
    plb
    pld
    ply
    plx
    pla
    plp
    
    rti
```

**VBlank Timing Budget:**

```
VBlank start: Scanline 225
VBlank end:   Scanline 261 (NTSC)
Duration:     37 scanlines = ~2,223 PPU clocks

Typical usage:
- OAM update:       512 bytes = ~100 clocks
- Palette update:   512 bytes = ~100 clocks
- Scroll update:    ~50 clocks
- VRAM transfer:    Variable (up to ~1,800 clocks available)
- HDMA setup:       ~100 clocks
Total safe:         ~350 clocks baseline + VRAM
```

## Mode 7 Effects

### Mode 7 Configuration

**Mode 7 Registers:**

```
$211A - M7SEL   : Mode 7 settings (flip H/V, screen over)
$211B - M7A     : Matrix A (scaling factor)
$211C - M7B     : Matrix B (rotation)
$211D - M7C     : Matrix C (rotation)
$211E - M7D     : Matrix D (scaling factor)
$211F - M7X     : Center point X
$2120 - M7Y     : Center point Y
```

### Rotation Matrix

```
Standard rotation matrix:
| cos(θ)  -sin(θ) |
| sin(θ)   cos(θ) |

SNES M7 matrix:
| A   B |   | cos(θ)×scale  -sin(θ)×scale |
| C   D | = | sin(θ)×scale   cos(θ)×scale |

Fixed-point format: 8.8 (256 = 1.0)
```

**Rotation Example:**

```asm
; Rotate Mode 7 layer by angle in A
; Input: A = angle (0-255, representing 0-360°)
RotateMode7:
    php
    rep #$30
    
    ; Load sine/cosine from table
    tax
    lda sine_table,X
    sta $00                 ; sin(θ)
    lda cosine_table,X
    sta $02                 ; cos(θ)
    
    ; Write matrix A = cos(θ)
    lda $02
    sta !SNES_M7A
    xba
    sta !SNES_M7A
    
    ; Write matrix B = -sin(θ)
    lda $00
    eor #$FFFF
    inc a                   ; Negate
    sta !SNES_M7B
    xba
    sta !SNES_M7B
    
    ; Write matrix C = sin(θ)
    lda $00
    sta !SNES_M7C
    xba
    sta !SNES_M7C
    
    ; Write matrix D = cos(θ)
    lda $02
    sta !SNES_M7D
    xba
    sta !SNES_M7D
    
    plp
    rts
```

### Scaling Example

```asm
; Scale Mode 7 layer
; Input: A = scale factor (256 = 1.0×, 128 = 0.5×, 512 = 2.0×)
ScaleMode7:
    sta $00                 ; Save scale
    
    ; A = scale
    sta !SNES_M7A
    xba
    sta !SNES_M7A
    
    ; B = 0
    stz !SNES_M7B
    stz !SNES_M7B
    
    ; C = 0
    stz !SNES_M7C
    stz !SNES_M7C
    
    ; D = scale
    lda $00
    sta !SNES_M7D
    xba
    sta !SNES_M7D
    
    rts
```

## HDMA (Horizontal-DMA)

### HDMA Overview

**Purpose:** Update PPU registers during specific scanlines

**Common Uses:**
- Gradient palettes
- Wavy water effects
- Transparency windows
- Per-scanline color math

### HDMA Setup

```asm
; Setup HDMA channel for scanline color math
; Changes brightness/color per scanline for fade effect
SetupHDMAGradient:
    php
    rep #$30
    
    ; DMA channel 7 for HDMA
    lda #$02                ; Mode 2: Write once per scanline
    sta !SNES_DMA7PARAM
    
    lda #$32                ; Destination: $2132 (COLDATA)
    sta !SNES_DMA7REG
    
    ; Point to HDMA table in RAM
    ldx #hdma_gradient_table
    stx !SNES_DMA7ADDRL
    lda #^hdma_gradient_table
    sta !SNES_DMA7ADDRH
    
    ; Enable HDMA channel 7
    lda #$80                ; Bit 7 = channel 7
    sta !SNES_HDMAEN
    
    plp
    rts

; HDMA table format:
; Byte 0: Scanline count (0 = end, $80 = repeat)
; Byte 1+: Data to write
hdma_gradient_table:
    db $20, $E0             ; 32 scanlines: black addition
    db $20, $E4             ; 32 scanlines: dark gray
    db $20, $E8             ; 32 scanlines: medium gray
    db $20, $EC             ; 32 scanlines: light gray
    db $20, $EF             ; 32 scanlines: white
    db $00                  ; End table
```

### Wave Effect (Water)

```asm
; HDMA for horizontal wave effect
; Updates BG1 H-scroll per scanline
SetupWaveHDMA:
    ; DMA channel 6
    lda #$00                ; Mode 0: Single write
    sta !SNES_DMA6PARAM
    
    lda #$0D                ; Destination: $210D (BG1HOFS)
    sta !SNES_DMA6REG
    
    ldx #hdma_wave_table
    stx !SNES_DMA6ADDRL
    lda #^hdma_wave_table
    sta !SNES_DMA6ADDRH
    
    lda #$40                ; Enable channel 6
    sta !SNES_HDMAEN
    
    rts

; Wave table (generated per frame)
GenerateWaveTable:
    ldx #$0000
    ldy #$0000
    
.loop:
    ; Calculate wave: offset = sin(scanline + time)
    txa
    clc
    adc wave_time
    and #$FF
    tax
    
    lda sine_table,X
    lsr a                   ; Reduce amplitude
    lsr a
    lsr a
    sta hdma_wave_table+1,Y ; Store offset
    
    lda #$01                ; 1 scanline
    sta hdma_wave_table,Y
    
    iny
    iny
    
    cpx #224                ; All visible scanlines
    bcc .loop
    
    ; End table
    lda #$00
    sta hdma_wave_table,Y
    
    rts
```

## Graphics Compression

### LZSS Decompression

```asm
; Decompress LZSS-compressed graphics data
; Input: X = source address, Y = destination address
; Output: Decompressed data at destination
DecompressLZSS:
    php
    rep #$30
    
    lda #$0000
    sta $00                 ; Byte counter
    
.main_loop:
    ; Read control byte
    lda [X]
    sta $02
    inx
    
    ldy #$0008              ; 8 bits to process
    
.bit_loop:
    lsr $02                 ; Check next bit
    bcc .copy_literal
    
    ; Back-reference: Copy from earlier data
    lda [X]                 ; Read offset/length
    inx
    sta $04
    
    ; Extract offset (12 bits)
    and #$0FFF
    sta $06
    
    ; Extract length (4 bits) + 3
    lda $04
    lsr a
    lsr a
    lsr a
    lsr a
    clc
    adc #$0003
    sta $08                 ; Copy length
    
    ; Copy data
.copy_loop:
    lda destination_buffer
    sec
    sbc $06                 ; Back-reference offset
    tax
    
    lda [X]
    sta [destination_buffer]
    inc destination_buffer
    
    dec $08
    bne .copy_loop
    
    bra .next_bit
    
.copy_literal:
    ; Literal byte: Copy as-is
    lda [X]
    inx
    sta [destination_buffer]
    inc destination_buffer
    
.next_bit:
    dey
    bne .bit_loop
    
    ; Check if done
    lda [X]
    cmp #$FFFF              ; End marker
    bne .main_loop
    
    plp
    rts
```

## Performance Metrics

**PPU Timing (NTSC):**

- **Dot clock:** 21.477 MHz
- **Master clock:** 21.477 MHz / 4 = 5.369 MHz
- **Scanline:** 1,364 dots = 63.695 microseconds
- **Frame:** 262 scanlines = 16.689 ms (59.94 Hz)
- **VBlank:** 37 scanlines = 2.357 ms

**DMA Performance:**

- **DMA bandwidth:** 2.68 MHz (1 byte per 8 master clocks)
- **Max transfer/frame:** ~44 KB (entire VBlank)
- **Practical limit:** ~20 KB (OAM + palette + some VRAM)

**VRAM Access:**

- **CPU access:** Only during VBlank or Force Blank
- **DMA access:** Anytime (but best during VBlank)
- **VRAM write:** 2 cycles minimum (VMDATAL + VMDATAH)

**OAM Limits:**

- **Max sprites:** 128 total
- **Max sprites/scanline:** 32
- **Max tiles/scanline:** 34 (8×8 tiles)
- **Sprite overflow:** Automatic dropping (no flicker control)

**Memory Footprint:**

- **VRAM:** 64 KB total
- **CGRAM:** 512 bytes
- **OAM:** 544 bytes (512 main + 32 high)
- **RAM buffers:** ~2 KB (OAM shadow, palette shadow)

## Summary

The FFMQ PPU graphics system efficiently utilizes SNES hardware capabilities:

**Strengths:**

- Hardware-accelerated sprite system (128 OBJ)
- 4 independent scrolling background layers
- DMA transfer for fast updates during VBlank
- HDMA for scanline effects (water, gradients)
- Mode 7 rotation/scaling for world map
- 15-bit color depth (32,768 colors)

**Technical Implementation:**

- Compact VRAM layout (64 KB efficiently allocated)
- OAM buffer system for sprite updates
- DMA channels prioritized by speed requirements
- HDMA tables generated dynamically per frame
- Mode 1 graphics (4BPP + 2BPP backgrounds)

---

**Documentation Version**: 1.0  
**Last Updated**: 2025-11-17  
**Related Documentation**: MAP_SYSTEM.md, COMBAT_SYSTEM.md, ANIMATION_SYSTEM.md
