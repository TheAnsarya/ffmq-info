# Graphics System Architecture

Complete documentation of the Final Fantasy Mystic Quest graphics rendering system.

## Table of Contents

- [System Overview](#system-overview)
- [PPU Architecture](#ppu-architecture)
- [Graphics Data Flow](#graphics-data-flow)
- [Background System](#background-system)
- [Sprite System](#sprite-system)
- [Palette Management](#palette-management)
- [VRAM Organization](#vram-organization)
- [Graphics Loading](#graphics-loading)
- [Rendering Pipeline](#rendering-pipeline)
- [Code Locations](#code-locations)

## System Overview

The FFMQ graphics system manages all visual rendering through the SNES Picture Processing Unit (PPU). The system handles:

- **4 Background Layers** (BG1-BG4) for scrolling tilemaps
- **128 Hardware Sprites** (OAM objects) for characters and effects
- **Dynamic VRAM Management** for tiles and tilemaps
- **8 Palettes** (256 total colors) for backgrounds and sprites
- **Mode 1 Graphics** (16 colors per tile, 3 BG layers + sprites)

### Key Components

```
┌──────────────────┐
│  Game Logic      │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│ Graphics Engine  │ ← Controls what to display
├──────────────────┤
│ - Load Graphics  │
│ - Update Palettes│
│ - Set Scroll Pos │
│ - Manage Sprites │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│  PPU Hardware    │ ← Renders to screen
├──────────────────┤
│ - Backgrounds    │
│ - Sprites        │
│ - Color Math     │
└──────────────────┘
```

## PPU Architecture

### Graphics Modes

FFMQ uses **Mode 1** primarily:

```
Mode 1 Configuration:
- BG1: 16 colors (4bpp) - Main tilemap layer
- BG2: 16 colors (4bpp) - Secondary/UI layer  
- BG3: 4 colors (2bpp)  - Text/overlay layer
- Sprites: 16 colors (4bpp) - Characters, enemies, effects
```

**Other modes used:**
- **Mode 0** - Title screen (4 layers, 4 colors each)
- **Mode 7** - World map rotation effects

### VRAM Layout (32KB)

```
VRAM Address    Size      Purpose
────────────────────────────────────────────────
$0000-$1fff     8KB       BG1 Character Data (Tiles)
$2000-$3fff     8KB       BG2 Character Data
$4000-$5fff     8KB       Sprite Character Data
$6000-$6fff     4KB       BG1 Tilemap
$7000-$77ff     2KB       BG2 Tilemap
$7800-$7bff     1KB       BG3 Tilemap
$7c00-$7fff     1KB       Sprite Attribute Table (OAM)
```

### Color Palette (512 bytes CGRAM)

```
Palette     Colors   Purpose
─────────────────────────────────────
0-7         8×16     Background palettes
8-15        8×16     Sprite palettes
```

Each color is 15-bit BGR format: `0bbbbbgg gggrrrrr`

## Graphics Data Flow

### Startup Sequence

```
1. VBlank Start
   ↓
2. DMA Graphics Data → VRAM
   ↓
3. Upload Palettes → CGRAM
   ↓
4. Initialize Tilemap → VRAM
   ↓
5. Setup PPU Registers
   ↓
6. Enable Display
```

### Per-Frame Update

```
Game Loop
   ↓
Update Logic (Positions, States)
   ↓
VBlank Interrupt
   ↓
┌────────────────────┐
│ VBlank Routine     │
├────────────────────┤
│ 1. Update OAM      │ ← Sprite positions/tiles
│ 2. Scroll Update   │ ← Background scroll values
│ 3. Palette Changes │ ← Color effects/fading
│ 4. VRAM Updates    │ ← Tilemap changes (limited)
│ 5. HDMA Setup      │ ← Scanline effects
└────────────────────┘
   ↓
Resume Game Logic
```

## Background System

### Tilemap Structure

Each background layer uses a tilemap in VRAM:

```
Tilemap Entry (16 bits):
  vhopppcc cccccccc

  v = Vertical flip
  h = Horizontal flip
  o = Priority (above/below sprites)
  p = Palette (0-7)
  c = Character (tile) number (0-1023)
```

### BG1: Main Game Layer

- **Primary rendering** for dungeons, towns, battles
- **32×32 tiles** (256×256 pixels)
- **Scrolls independently** via $210d/$210e registers
- **Uses palettes 0-3** typically

**Code Location**: `bank_01.asm` - `UpdateBG1Scroll`

### BG2: Secondary Layer

- **UI elements** (menus, windows, borders)
- **Parallax scrolling** in some areas
- **28×32 tiles** typically
- **Uses palettes 4-6**

**Code Location**: `bank_01.asm` - `UpdateBG2`

### BG3: Text Layer

- **Dialog boxes** and text rendering
- **2bpp format** (4 colors - saves VRAM)
- **Fixed position** or slow scroll
- **Uses palette 7** (text colors)

**Code Location**: `bank_01.asm` - `TextRenderEngine`

## Sprite System

### OAM (Object Attribute Memory)

FFMQ uses the SNES hardware sprite system with:
- **128 sprites maximum** (hardware limit)
- **32 sprites per scanline** (hardware limit)
- **Each sprite**: 8×8 to 64×64 pixels

### OAM Structure

**Primary OAM (512 bytes)**: 128 sprites × 4 bytes

```
Byte 0: X position (low 8 bits)
Byte 1: Y position (low 8 bits)
Byte 2: Tile number (character)
Byte 3: Attributes
  vhpppccc
  v = Vertical flip
  h = Horizontal flip
  p = Priority (0-3)
  c = Palette (0-7, offset by 8)
```

**Secondary OAM (32 bytes)**: Size and X MSB

```
Each byte controls 4 sprites:
  Bits 0-1: Sprite 0 - Size (00=small, 01=large)
  Bit 2:    Sprite 0 - X position bit 8
  Bits 3-4: Sprite 1 - Size
  Bit 5:    Sprite 1 - X position bit 8
  ... (continues for 4 sprites per byte)
```

### Sprite Sizes

FFMQ uses size configuration: **Small=8×8, Large=16×16**

```
Size Config #0 (OBSEL=$00):
- Small sprites:  8×8 pixels  (1 tile)
- Large sprites: 16×16 pixels (4 tiles)
```

### Sprite Management

**Game uses sprite allocation system:**

```
Sprite Slots:
  0-15:   Player character and party
  16-31:  NPCs and allies
  32-63:  Enemies (battles)
  64-95:  Effects and projectiles
  96-127: UI elements and cursor
```

**Priority system:**
```
Priority 0: Behind backgrounds
Priority 1: Between BG2 and BG1
Priority 2: In front of BG1
Priority 3: In front of all backgrounds
```

**Code Locations**:
- `bank_01.asm` - `UpdateOAM` - Main sprite update
- `bank_02.asm` - `LoadSpriteGraphics` - Load sprite tiles
- `bank_02.asm` - `AllocateSprite` - Sprite slot management

## Palette Management

### Palette Loading

Palettes loaded via DMA during VBlank:

```asm
; Example from bank_01.asm
LoadPalette:
    lda #$00        ; CGRAM address low
    sta $2121       ; Set CGRAM address
    
    ; DMA from ROM to CGRAM
    lda #$00        ; DMA mode: 1 register write twice
    sta $4300       ; DMA control
    lda #$22        ; Destination: $2122 (CGRAM data)
    sta $4301
    
    ; Source address (ROM)
    lda #<PaletteData
    sta $4302       ; Source address low
    lda #>PaletteData  
    sta $4303       ; Source address high
    lda #^PaletteData
    sta $4304       ; Source bank
    
    ; Transfer size
    lda #$00
    sta $4305       ; 512 bytes (256 words)
    lda #$02
    sta $4306
    
    lda #$01        ; Trigger DMA on channel 0
    sta $420b
    rts
```

### Palette Effects

**Fading:**
```
- Black fade: Gradually reduce RGB components
- White fade: Gradually increase RGB components  
- Color fade: Interpolate between palettes
```

**Code Location**: `bank_01.asm` - `FadePalette`

**Color Math:**
```
- PPU can add/subtract colors
- Used for dark rooms, lighting effects
- Configured via $2131 (CGADSUB register)
```

## VRAM Organization

### Graphics Banks

Game organizes graphics into "banks" loaded on demand:

```
Graphics Bank 0: Title screen
Graphics Bank 1: World map
Graphics Bank 2: Battle backgrounds
Graphics Bank 3: Character sprites
Graphics Bank 4: Enemy sprites  
Graphics Bank 5: UI elements
Graphics Bank 6: Font and text
Graphics Bank 7: Effects
```

### Dynamic Loading

```
Game State Change
   ↓
Determine Required Graphics
   ↓
Wait for VBlank
   ↓
DMA Transfer New Graphics → VRAM
   ↓
Update Tile Mappings
   ↓
Resume Rendering
```

**Typical load time**: 1-2 frames (16-32ms)

## Graphics Loading

### DMA Transfer Process

**Code Example** from `bank_02.asm`:

```asm
; ==============================================================================
; LoadGraphicsToVRAM - DMA graphics data to VRAM
; ==============================================================================
; Inputs:
;   X = Source address (ROM)
;   A = Source bank
;   $00-$01 = VRAM destination address
;   $02-$03 = Transfer size
; ==============================================================================
LoadGraphicsToVRAM:
    ; Set VRAM address
    lda $00
    sta $2116       ; VRAM address low
    lda $01
    sta $2117       ; VRAM address high
    
    ; Configure DMA
    lda #$01        ; DMA mode: 2 registers write once
    sta $4300       ; $2118-$2119 (VRAM data ports)
    
    lda #$18        ; Destination: $2118
    sta $4301
    
    ; Source address
    stx $4302       ; Source address low/high
    sta $4304       ; Source bank
    
    ; Transfer size
    lda $02
    sta $4305       ; Size low
    lda $03
    sta $4306       ; Size high
    
    ; Wait for VBlank
    jsr WaitVBlank
    
    ; Execute DMA
    lda #$01
    sta $420b       ; Trigger DMA channel 0
    
    rts
```

### Compression

Some graphics use simple RLE compression:

```
Format:
  Byte 0: Command
    If bit 7 = 0: Copy next N bytes literally
    If bit 7 = 1: Repeat next byte N times
  
Example:
  $05 $12 $34 $56 $78 $90  →  Copy 5 bytes: 12 34 56 78 90
  $83 $ff                   →  Repeat $ff 3 times: FF FF FF
```

**Code Location**: `bank_02.asm` - `DecompressGraphics`

## Rendering Pipeline

### Frame Rendering Sequence

```
1. VBlank Start (NMI interrupt)
   │
   ├─ Disable rendering ($2100 = $80)
   │
   ├─ Update OAM
   │  └─ Copy sprite buffer → OAM memory
   │
   ├─ Update Scroll Registers
   │  ├─ BG1: $210d/$210e
   │  ├─ BG2: $210f/$2110
   │  └─ BG3: $2111/$2112
   │
   ├─ Palette Updates (if needed)
   │  └─ DMA → CGRAM
   │
   ├─ VRAM Updates (if needed)
   │  └─ DMA → VRAM (small changes only!)
   │
   ├─ HDMA Setup (scanline effects)
   │  └─ Configure channels for gradients/wave effects
   │
   └─ Enable rendering ($2100 = $0f)

2. VBlank End
   │
   └─ PPU renders scanlines automatically
      ├─ Scanline 0-224: Active display
      │  └─ For each scanline:
      │     ├─ Render BG layers
      │     ├─ Render sprites
      │     ├─ Apply color math
      │     └─ Apply HDMA effects
      │
      └─ Scanline 225-261: VBlank period

3. Repeat next frame (60 Hz)
```

### Scanline Timing

```
Total scanline: 341.25 dots (≈21.5 µs)
├─ H-Blank: ~60 dots (≈3.8 µs)
└─ Active: ~280 dots (≈17.7 µs)

VBlank duration: ~1.1 ms
- Enough for ~4-6 KB of DMA transfers
- Limited time for VRAM updates!
```

## Code Locations

### Core Graphics Engine

**File**: `src/asm/bank_01_documented.asm`

```asm
; Main graphics update routines
VBlankHandler:          ; NMI interrupt handler
    jsr UpdateOAM       ; Update sprite positions
    jsr UpdateScroll    ; Update background scroll
    jsr UpdatePalette   ; Apply palette effects
    jsr RunHDMA         ; Setup scanline effects
    rti

UpdateOAM:              ; Copy sprite buffer → OAM
    ; Located at $01:8234
    
UpdateScroll:           ; Update BG scroll registers
    ; Located at $01:8156
    
UpdatePalette:          ; Palette fading/effects
    ; Located at $01:82A5
```

### Graphics Loading

**File**: `src/asm/bank_02_documented.asm`

```asm
LoadGraphicsToVRAM:     ; DMA graphics to VRAM
    ; Located at $02:9122
    
LoadPaletteData:        ; Load palette via DMA
    ; Located at $02:9234
    
DecompressGraphics:     ; Decompress RLE graphics
    ; Located at $02:9456
    
LoadSpriteGraphics:     ; Load sprite tiles
    ; Located at $02:9678
```

### Sprite Management

**File**: `src/asm/bank_02_documented.asm`

```asm
AllocateSprite:         ; Find free sprite slot
    ; Located at $02:A123
    
FreeSprite:             ; Free sprite slot
    ; Located at $02:A145
    
UpdateSpriteAnimation:  ; Animate sprite frames
    ; Located at $02:A234
    
SetSpritePosition:      ; Update sprite X/Y
    ; Located at $02:A267
```

### Background System

**File**: `src/asm/bank_01_documented.asm`

```asm
InitBackground:         ; Setup BG layers
    ; Located at $01:7234
    
UpdateBG1Scroll:        ; Scroll BG1
    ; Located at $01:7456
    
UpdateTilemap:          ; Modify tilemap data
    ; Located at $01:7678
    
LoadBackgroundGfx:      ; Load BG graphics bank
    ; Located at $01:7890
```

## Hardware Registers

### PPU Registers (Write)

```
$2100 - INIDISP - Screen display enable and brightness
$2105 - BGMODE  - BG mode and character size
$2107 - BG1SC   - BG1 tilemap address
$2108 - BG2SC   - BG2 tilemap address
$2109 - BG3SC   - BG3 tilemap address
$210b - BG12NBA - BG1/BG2 character address
$210c - BG34NBA - BG3/BG4 character address
$210d - BG1HOFS - BG1 horizontal scroll
$210e - BG1VOFS - BG1 vertical scroll
$210f - BG2HOFS - BG2 horizontal scroll
$2110 - BG2VOFS - BG2 vertical scroll
$2111 - BG3HOFS - BG3 horizontal scroll
$2112 - BG3VOFS - BG3 vertical scroll
$2115 - VMAIN   - VRAM address increment mode
$2116 - VMADDL  - VRAM address low
$2117 - VMADDH  - VRAM address high
$2118 - VMDATAL - VRAM data write low
$2119 - VMDATAH - VRAM data write high
$2121 - CGADD   - CGRAM address
$2122 - CGDATA  - CGRAM data
```

### DMA Registers

```
$4300 - DMAP0   - DMA control for channel 0
$4301 - BBAD0   - DMA destination register
$4302 - A1T0L   - DMA source address low
$4303 - A1T0H   - DMA source address high
$4304 - A1B0    - DMA source bank
$4305 - DAS0L   - DMA transfer size low
$4306 - DAS0H   - DMA transfer size high
$420b - MDMAEN  - DMA enable (trigger)
```

## Performance Considerations

### VRAM Access Limitations

**During active display** (scanlines 0-224):
- ❌ **Cannot write to VRAM** (corrupts display)
- ✅ **Can read from VRAM** (limited)
- ✅ **Can update scroll registers**
- ✅ **Can update OAM** (double-buffered)

**During VBlank** (scanlines 225-261):
- ✅ **Can freely access VRAM**
- ⚠️ **Limited time** (~1.1ms = ~4-6KB transfer)

### Optimization Strategies

1. **Batch VRAM Updates**: Queue changes, apply in VBlank
2. **Minimize Transfers**: Only update changed tiles
3. **Use HDMA**: Update during scanlines (scroll, palettes)
4. **Sprite Limits**: Stay under 32 sprites per scanline
5. **Preload Graphics**: Load during transitions, not gameplay

### Common Bottlenecks

```
Problem: Sprite flicker
Cause: More than 32 sprites on one scanline
Solution: Sprite rotation, reduce sprite count

Problem: Slow screen transitions  
Cause: Large VRAM transfers during gameplay
Solution: Load during fade-out, multi-frame loading

Problem: Scroll stuttering
Cause: Missed VBlank updates
Solution: Ensure VBlank code completes in time
```

## Debug Tools

### Emulator Features (Mesen-S)

- **Tilemap Viewer**: View all BG layers in real-time
- **Sprite Viewer**: See all OAM entries
- **VRAM Viewer**: Inspect VRAM contents as tiles
- **Palette Viewer**: View all 256 colors
- **Event Viewer**: Track PPU register writes
- **Performance**: Monitor VBlank timing

### Debugging Techniques

```asm
; Visual debug: Flash color
DebugFlashRed:
    lda #$1f        ; Pure red (SNES BGR format)
    sta $2122       ; Write to color 0
    rts

; Sprite debug: Draw marker at position
DebugDrawMarker:
    lda #$00        ; X position
    sta OAMBuffer+0
    lda #$00        ; Y position  
    sta OAMBuffer+1
    lda #$01        ; Tile (use visible pattern)
    sta OAMBuffer+2
    lda #$30        ; Attributes (priority 3, palette 0)
    sta OAMBuffer+3
    rts
```

## See Also

- **[graphics-format.md](graphics-format.md)** - Detailed tile/palette format specs
- **[graphics-quickstart.md](graphics-quickstart.md)** - Graphics tools guide
- **[MODDING_GUIDE.md](MODDING_GUIDE.md)** - Graphics modification examples
- **[data_formats.md](data_formats.md)** - Game data structures

---

**For technical details on file formats**, see [graphics-format.md](graphics-format.md).

**For modding graphics**, see [MODDING_GUIDE.md](MODDING_GUIDE.md#graphics-and-visuals).
