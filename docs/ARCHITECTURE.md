# FFMQ System Architecture

Comprehensive architecture documentation for Final Fantasy: Mystic Quest.

## Table of Contents

- [Overview](#overview)
- [Memory Organization](#memory-organization)
- [System Architecture](#system-architecture)
- [Code Organization](#code-organization)
- [Data Flow](#data-flow)
- [Initialization](#initialization)
- [Main Loop](#main-loop)
- [Subsystems](#subsystems)

## Overview

Final Fantasy: Mystic Quest is built on the Super Nintendo Entertainment System (SNES) and uses the following hardware:

**CPU**: Ricoh 5A22 (65816-based), 3.58 MHz  
**Audio**: SPC700 + Sony DSP, 64KB audio RAM  
**Graphics**: PPU (Picture Processing Unit), Mode 1 primarily  
**RAM**: 128KB (64KB WRAM + 64KB VRAM), 512 bytes CGRAM  
**ROM**: 1MB (8 banks × 128KB)  
**SRAM**: 8KB battery-backed save RAM  

### Design Philosophy

The game architecture follows these principles:

1. **Bank-based organization**: Code separated into logical banks
2. **Event-driven execution**: Main loop processes events and updates systems
3. **Layered graphics**: BG1/BG2 for maps, BG3 for text, sprites for characters
4. **Data-driven design**: Extensive use of tables for enemies, items, maps
5. **Modular systems**: Separate systems for battle, graphics, text, sound

---

## Memory Organization

### ROM Layout

```
Bank $00 ($008000-$00FFFF): Core engine and main loop
Bank $01 ($018000-$01FFFF): Graphics, input, map engine
Bank $02 ($028000-$02FFFF): Extended map and event code
Bank $03 ($038000-$03FFFF): Text engine and dialog
Bank $04 ($048000-$04FFFF): Title screen graphics
Bank $05 ($050000-$05FFFF): Map tilesets and sprites
Bank $06 ($068000-$06FFFF): Map data (headers, metatiles, tilemaps)
Bank $07 ($078000-$07FFFF): UI graphics and palettes
Bank $08 ($088000-$08FFFF): Music and sound data
Bank $09 ($098000-$09FFFF): Extended code
Bank $0A ($0A8000-$0AFFFF): Extended code
Bank $0B ($0B8000-$0BFFFF): Battle system
Bank $0C ($0C8000-$0CFFFF): Character and item data
Bank $0D ($0D8000-$0DFFFF): Text strings and encoding
Bank $0E ($0E8000-$0EFFFF): Enemy and battle data
Bank $0F ($0F8000-$0FFFFF): Extended data
```

**Total ROM**: 1MB (16 banks × 64KB)

### RAM Layout

See RAM_MAP.md for complete memory map.

**Memory regions**:
- **Zero Page** ($00-$FF): Fast-access critical variables
- **Low RAM** ($7E0100-$01FF): Character stats and party data
- **Mid RAM** ($7E0200-$0FFF): Inventory, flags, cache, battle data
- **High RAM** ($7E1000-$FFFF): Buffers (OAM, tilemaps, graphics, audio)
- **SRAM** ($700000-$7003FF): 4 save slots × 256 bytes

**Memory usage by system**:
| System    | Zero Page | Low RAM | Mid RAM | High RAM | Total  |
|-----------|-----------|---------|---------|----------|--------|
| Graphics  | 32 bytes  | 0       | 0       | 19 KB    | ~19 KB |
| Battle    | 48 bytes  | 0       | 1 KB    | 0        | ~1 KB  |
| Player    | 32 bytes  | 64 bytes| 0       | 0        | 96 B   |
| Text      | 16 bytes  | 0       | 1 KB    | 0        | ~1 KB  |
| Map       | 16 bytes  | 0       | 1 KB    | 0        | ~1 KB  |
| Audio     | 8 bytes   | 0       | 0       | 4 KB     | ~4 KB  |
| Inventory | 0         | 128 bytes| 256 bytes| 0       | 384 B  |

**Available RAM**: ~38KB free for future expansion

### VRAM Organization

```
$0000-$1FFF: BG1 character data (8 KB)
$2000-$3FFF: BG2 character data (8 KB)
$4000-$5FFF: Sprite character data (8 KB)
$6000-$67FF: BG3 character data (2 KB, font)
$6800-$6FFF: (Available, 2 KB)
$7000-$77FF: BG1 tilemap (2 KB, 32×32)
$7800-$7FFF: BG2 tilemap (2 KB, 32×32)
```

**Total VRAM**: 32 KB (64KB in Mode 7)

### CGRAM (Palette RAM)

```
Palettes 0-3: Background palettes (16 colors each)
Palettes 4-7: Sprite palettes (16 colors each)
```

**Total**: 256 bytes (128 colors × 2 bytes)

---

## System Architecture

### High-Level Architecture

```
┌────────────────────────────────────────────┐
│           Main Game Loop                    │
│  - Input Processing                         │
│  - Game State Update                        │
│  - Subsystem Updates                        │
│  - VBlank Wait                              │
└────────────────┬───────────────────────────┘
                 │
         ┌───────┴────────┐
         │                │
    ┌────▼────┐     ┌────▼────┐
    │ Game    │     │ Battle  │
    │ Mode    │     │ Mode    │
    └────┬────┘     └────┬────┘
         │               │
    ┌────▼────┐     ┌────▼────┐
    │ Map     │     │ Battle  │
    │ Engine  │     │ Engine  │
    └────┬────┘     └────┬────┘
         │               │
    ┌────▼────────────────▼────┐
    │   Subsystems              │
    │ - Graphics                │
    │ - Text/Dialog             │
    │ - Sound/Music             │
    │ - Input                   │
    └───────────────────────────┘
```

### Layer Architecture

**Game Layer**:
- Main loop
- Game mode management (title, field, battle, menu)
- Global state management

**Gameplay Layer**:
- Map navigation
- Event processing
- NPC interactions
- Battle execution

**System Layer**:
- Graphics rendering
- Text rendering
- Audio playback
- Input handling

**Hardware Layer**:
- PPU control
- DMA transfers
- SPC700 communication
- Controller reading

---

## Code Organization

### Code Structure by Bank

**Bank $00-$02**: Core Engine
- Main loop
- Mode switching
- Graphics engine
- Map engine
- Event system

**Bank $03**: Text Engine
- Text rendering
- Dialog system
- DTE decompression
- Font management

**Bank $0B**: Battle Engine
- Battle initialization
- ATB system
- Damage calculation
- AI execution
- Status effects

**Bank $08**: Audio Driver
- Music playback
- SFX triggering
- SPC700 communication

**Banks $0C-$0E**: Game Data
- Character stats
- Item definitions
- Enemy data
- Battle formations

### Function Organization

**Entry Points**:
- $008000: Reset vector → initialization
- $00FFE4: NMI vector → VBlank handler
- $00FFE8: IRQ vector → (unused)

**Major Routines**:
- $008100: Main loop
- $015000: Graphics loading
- $010000: Map loading
- $013000: Text rendering
- $019000: Input processing
- $0B8000: Battle initialization

---

## Data Flow

### Game Loop Data Flow

```
Input → State Update → Rendering → Display
  ↓          ↓            ↓          ↓
Controller  Game       VRAM/OAM   VBlank
  Read      Logic      Update     Transfer
```

### Graphics Pipeline

```
ROM Graphics → Decompression → DMA Transfer → VRAM
                                    ↓
                              Palette → CGRAM
                                    ↓
                              Tilemap → VRAM
                                    ↓
                              Rendering → Screen
```

### Battle Data Flow

```
Formation Load → Enemy Init → Main Loop ┐
       ↓              ↓           ↓      │
   Enemy Data    Character   ATB Update │
       ↓          Stats          ↓      │
   AI Scripts → Command → Damage Calc   │
                   ↓          ↓          │
              Animation → Results → ────┘
                              ↓
                          Battle End
```

### Text Rendering Flow

```
Text ID → Pointer Lookup → ROM Data
             ↓
        DTE Decompress
             ↓
        Control Codes → State Updates
             ↓
        Character → Tile Lookup
             ↓
        BG3 Tilemap Update
             ↓
        VBlank Transfer → Display
```

---

## Initialization

### Boot Sequence

1. **Reset Vector** ($008000):
   - Disable interrupts
   - Set stack pointer
   - Clear decimal mode
   - Jump to initialization

2. **Hardware Init** ($008020):
   - Disable screen (forced blank)
   - Clear VRAM
   - Clear CGRAM
   - Clear OAM
   - Set screen mode (Mode 1)
   - Initialize DMA

3. **System Init** ($008080):
   - Clear WRAM
   - Initialize variables
   - Load audio driver to SPC700
   - Start driver

4. **Game Init** ($0080E0):
   - Load title screen graphics
   - Load title palettes
   - Initialize game state
   - Enable screen
   - Jump to title screen mode

### Title Screen Flow

```
Title Init → Title Loop → Menu Selection → Game Start
    ↓            ↓              ↓              ↓
Graphics    Animation    New Game/     Clear Save Data
 Load       Update       Continue         (if New)
                                            ↓
                                       Load Game Data
                                         (if Continue)
                                            ↓
                                       Start Game Mode
```

---

## Main Loop

### Frame Structure

```assembly
main_loop:
    jsr process_input        ; Read controllers
    jsr update_game_state    ; Update game logic
    jsr update_graphics      ; Prepare graphics
    jsr wait_vblank          ; Wait for VBlank
    jsr transfer_data        ; DMA graphics to VRAM
    jsr update_audio         ; Send audio commands
    jmp main_loop            ; Repeat
```

**Frame timing**: 60 Hz (16.67ms per frame)

### VBlank Handler

```assembly
vblank_handler:
    ; Save registers
    pha
    phx
    phy
    
    ; DMA transfers (1.1ms limit)
    jsr dma_oam              ; Sprites
    jsr dma_tilemaps         ; BG tilemaps
    jsr dma_palettes         ; Color data
    
    ; Update hardware registers
    jsr update_scroll        ; BG scroll
    jsr update_hdma          ; HDMA settings
    
    ; Audio communication
    jsr send_audio_commands  ; SPC700 commands
    
    ; Increment frame counter
    inc frame_counter
    
    ; Restore registers
    ply
    plx
    pla
    rti
```

---

## Subsystems

### Graphics Subsystem

**Architecture**:
```
Graphics Engine
├── Tile Management
│   ├── Load tiles from ROM
│   ├── Decompress (if needed)
│   └── DMA to VRAM
├── Palette Management
│   ├── Load palettes from ROM
│   ├── Apply fading
│   └── Update CGRAM
├── Tilemap Updates
│   ├── Build tilemaps in RAM
│   ├── Apply scrolling
│   └── DMA to VRAM
└── Sprite Management
    ├── Update OAM buffer
    ├── Set positions/tiles
    └── DMA to OAM
```

**See**: GRAPHICS_SYSTEM.md for complete details

### Battle Subsystem

**Architecture**:
```
Battle Engine
├── Initialization
│   ├── Load formation
│   ├── Initialize enemies
│   └── Setup characters
├── Main Loop (ATB)
│   ├── Update ATB gauges
│   ├── Check for ready units
│   ├── Execute commands
│   └── Check win/loss
├── Command Execution
│   ├── Attack calculation
│   ├── Magic calculation
│   ├── Item usage
│   └── Status processing
└── AI System
    ├── Select targets
    ├── Choose actions
    └── Execute AI script
```

**See**: BATTLE_SYSTEM.md for complete details

### Text Subsystem

**Architecture**:
```
Text Engine
├── Text Loading
│   ├── Lookup pointer
│   ├── Load from ROM
│   └── DTE decompress
├── Text Rendering
│   ├── Parse control codes
│   ├── Map to tiles
│   └── Update BG3
├── Dialog System
│   ├── Window management
│   ├── Text speed control
│   └── Button wait
└── Font Management
    ├── Load font tiles
    └── Character mapping
```

**See**: TEXT_SYSTEM.md for complete details

### Map Subsystem

**Architecture**:
```
Map Engine
├── Map Loading
│   ├── Load map header
│   ├── Load metatiles
│   ├── Build tilemap
│   └── Load events/NPCs
├── Player Movement
│   ├── Input processing
│   ├── Collision check
│   ├── Position update
│   └── Scrolling update
├── Event Processing
│   ├── Check triggers
│   ├── Execute scripts
│   └── Update flags
└── NPC System
    ├── NPC movement AI
    ├── Collision with player
    └── Dialog triggers
```

**See**: MAP_SYSTEM.md for complete details

### Audio Subsystem

**Architecture**:
```
Audio System (SPC700)
├── Main CPU Side
│   ├── Command queue
│   ├── SPC communication
│   └── Music/SFX requests
└── SPC700 Side
    ├── Audio Driver
    │   ├── Main loop (60 Hz)
    │   ├── Command processing
    │   └── Memory management
    ├── Music Playback
    │   ├── Sequence parsing
    │   ├── Pattern playback
    │   └── Instrument setup
    └── DSP Control
        ├── Channel setup (8 channels)
        ├── ADSR control
        └── Sample playback (BRR)
```

**See**: SOUND_SYSTEM.md for complete details

---

## Performance Characteristics

### CPU Usage (per frame)

| System          | Approximate Time | % of Frame |
|-----------------|------------------|------------|
| Input Processing| 0.1ms            | 0.6%       |
| Game Logic      | 2.0ms            | 12%        |
| Graphics Prep   | 3.0ms            | 18%        |
| VBlank Wait     | 1.0ms            | 6%         |
| VBlank Transfer | 1.1ms            | 6.6%       |
| Audio Update    | 0.5ms            | 3%         |
| **Idle Time**   | 8.97ms           | 53.8%      |

**Total**: 16.67ms (60 Hz)

### Memory Bandwidth

**DMA Transfer limits** (per VBlank):
- Maximum: ~6 KB in 1.1ms VBlank period
- Typical: 2-4 KB per frame
  - OAM: 544 bytes
  - Tilemaps: 2-3 KB
  - Palettes: 256 bytes

### Optimization Strategies

1. **DMA Batching**: Group transfers to minimize overhead
2. **Tile Reuse**: Maximize shared tiles between maps
3. **Palette Sharing**: Use same palettes across multiple graphics
4. **Lazy Loading**: Load graphics only when needed
5. **Data Compression**: Use DTE for text, RLE for graphics
6. **Code Banking**: Organize code to minimize bank switching

---

## Design Patterns

### Event-Driven Architecture

Events trigger actions throughout the game:
- **Map events**: Stepped on, interacted with
- **Battle events**: Turn start, damage dealt, status applied
- **Menu events**: Selection, cancellation
- **System events**: VBlank, frame update

### State Machine Pattern

Game modes use state machines:
```
Title Screen → Field Mode → Battle Mode
     ↓             ↓             ↓
  Menu Mode    Menu Mode    Battle End
     ↓             ↓             ↓
  New Game     Save/Load     Victory/Defeat
```

### Table-Driven Design

Extensive use of data tables:
- Enemy stats and AI (Bank $0E)
- Item definitions (Bank $0C)
- Map data (Bank $06)
- Text strings (Bank $0D)

Benefits:
- Easy to modify
- Data-driven balance
- Minimal code changes for content

---

## Related Documentation

**System-Specific**:
- GRAPHICS_SYSTEM.md - Graphics and rendering
- BATTLE_SYSTEM.md - Battle mechanics
- TEXT_SYSTEM.md - Text and dialog
- MAP_SYSTEM.md - Map and navigation
- SOUND_SYSTEM.md - Audio and music

**Memory and Data**:
- RAM_MAP.md - Complete RAM layout
- DATA_STRUCTURES.md - Game data formats
- LABEL_INDEX.md - Label cross-reference

**Development**:
- CODE_ORGANIZATION.md - Source code structure
- MODDING_GUIDE.md - How to modify the game
- BUILD_GUIDE.md - Building the ROM

---

*This document provides the high-level architecture. See system-specific docs for implementation details.*

**Last Updated**: November 1, 2025
