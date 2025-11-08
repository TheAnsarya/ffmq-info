# Architecture Documentation

This directory contains system architecture documentation for Final Fantasy Mystic Quest, including high-level design, subsystem interactions, memory management, and core engine documentation.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Documentation Index](#documentation-index)
- [System Architecture](#system-architecture)
- [Core Subsystems](#core-subsystems)
- [Memory Architecture](#memory-architecture)
- [Testing Framework](#testing-framework)
- [Related Documentation](#related-documentation)

---

## Overview

This directory documents the high-level architecture and design of FFMQ's game engine, covering how different subsystems interact and how the game is structured at a system level.

**Architecture Documentation:**
- **System Architecture** - Overall game engine design
- **Map System** - World maps, collision, events
- **Sound System** - Music, sound effects, APU
- **Text System** - Dialogue, rendering, encoding
- **Testing Framework** - Test architecture and code quality

---

## Quick Start

### Understanding the Game Engine

```bash
# Start with overall architecture
cat docs/architecture/ARCHITECTURE.md

# Then study specific subsystems:
cat docs/architecture/MAP_SYSTEM.md
cat docs/architecture/SOUND_SYSTEM.md
cat docs/architecture/TEXT_SYSTEM.md
```

### Exploring Subsystems

```bash
# View subsystem relationships
python tools/analysis/visualize_architecture.py --output architecture.png

# Analyze subsystem dependencies
python tools/analysis/subsystem_dependencies.py
```

---

## Documentation Index

### [`ARCHITECTURE.md`](ARCHITECTURE.md) 🏛️ **MAIN ARCHITECTURE DOC**
*Complete system architecture overview*

**Contents:**
- Game engine overview
- Core subsystems
- Data flow
- Initialization sequence
- Main game loop
- Memory layout
- Subsystem interactions

**Use when:**
- Understanding overall system design
- Learning codebase structure
- Planning major changes
- Documenting new features

**Game Engine Architecture:**

**High-Level Structure:**
```
┌─────────────────────────────────────────┐
│           Game Engine Core              │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────┐ │
│  │   Map    │  │  Battle  │  │  Menu │ │
│  │  System  │  │  System  │  │System │ │
│  └────┬─────┘  └────┬─────┘  └───┬───┘ │
│       │             │             │     │
│  ┌────┴─────┬──────┴──────┬──────┴───┐ │
│  │ Graphics │    Sound    │   Text   │ │
│  │  Engine  │    Engine   │  Engine  │ │
│  └────┬─────┴──────┬──────┴──────┬───┘ │
│       │            │             │     │
│  ┌────┴────────────┴─────────────┴───┐ │
│  │         Hardware Abstraction       │ │
│  │    (PPU, APU, DMA, Controllers)    │ │
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

**Initialization Sequence:**
```asm
;-----------------------------------------------------------------------------
; Game Initialization (Reset Vector)
;-----------------------------------------------------------------------------
Reset:
    ; 1. CPU initialization
    SEI                     ; Disable interrupts
    CLC                     ; Clear carry
    XCE                     ; Native mode
    
    ; 2. Register initialization
    REP #$30                ; 16-bit A, X, Y
    LDA #$0000
    TCD                     ; Direct page = $0000
    LDA #$1FFF
    TCS                     ; Stack = $001FFF
    
    ; 3. Hardware initialization
    JSR InitPPU             ; Initialize graphics
    JSR InitAPU             ; Initialize sound
    JSR InitDMA             ; Initialize DMA
    JSR InitControllers     ; Initialize input
    
    ; 4. System initialization
    JSR ClearRAM            ; Clear work RAM
    JSR InitVRAM            ; Initialize VRAM
    JSR InitPalettes        ; Load palettes
    JSR LoadFont            ; Load text font
    
    ; 5. Game initialization
    JSR InitGameState       ; Initialize game variables
    JSR LoadSaveData        ; Check for save file
    
    ; 6. Start game
    JSR TitleScreen         ; Show title
    ; Falls through to main loop
```

**Main Game Loop:**
```asm
;-----------------------------------------------------------------------------
; Main Game Loop
;-----------------------------------------------------------------------------
MainLoop:
    ; 1. Wait for V-Blank
    JSR WaitVBlank
    
    ; 2. Update input
    JSR ReadControllers
    JSR UpdateInputBuffer
    
    ; 3. Update game logic
    JSR UpdateGameState
    
    ; 4. Update subsystems
    LDA GameMode
    CMP #MODE_FIELD
    BEQ .field_mode
    CMP #MODE_BATTLE
    BEQ .battle_mode
    CMP #MODE_MENU
    BEQ .menu_mode
    
.field_mode:
    JSR UpdateMapSystem
    JSR UpdatePlayerMovement
    JSR UpdateNPCs
    JSR CheckEvents
    JMP .done_update
    
.battle_mode:
    JSR UpdateBattleSystem
    JSR UpdateEnemyAI
    JSR ProcessActions
    JSR UpdateBattleDisplay
    JMP .done_update
    
.menu_mode:
    JSR UpdateMenuSystem
    JSR ProcessMenuInput
    JSR UpdateMenuDisplay
    JMP .done_update
    
.done_update:
    ; 5. Update graphics
    JSR UpdateSprites
    JSR UpdateBackgrounds
    JSR DMATransfers
    
    ; 6. Update sound
    JSR UpdateSoundSystem
    JSR ProcessMusicQueue
    JSR ProcessSFXQueue
    
    ; 7. Loop
    JMP MainLoop
```

**Subsystem Overview:**

**1. Map System:**
- **Purpose:** Manage overworld and dungeon navigation
- **Components:** Tilemap rendering, collision detection, events
- **Memory:** $7E2000-$7E3FFF (map buffer)
- **See:** [MAP_SYSTEM.md](MAP_SYSTEM.md)

**2. Battle System:**
- **Purpose:** Handle turn-based combat
- **Components:** Enemy AI, damage calculation, animations
- **Memory:** $7E0100-$7E03FF (battle state)
- **See:** [../battle/BATTLE_SYSTEM.md](../battle/BATTLE_SYSTEM.md)

**3. Graphics Engine:**
- **Purpose:** Manage PPU and graphics rendering
- **Components:** Sprite management, BG updates, DMA
- **Memory:** VRAM, OAM, CGRAM
- **See:** [../graphics/GRAPHICS_SYSTEM.md](../graphics/GRAPHICS_SYSTEM.md)

**4. Sound Engine:**
- **Purpose:** Music and sound effect playback
- **Components:** SPC-700 driver, music sequencer
- **Memory:** APU RAM ($00-$FFFF)
- **See:** [SOUND_SYSTEM.md](SOUND_SYSTEM.md)

**5. Text Engine:**
- **Purpose:** Dialogue and text rendering
- **Components:** Text decompression, font rendering, text boxes
- **Memory:** $7E6000-$7E6FFF (text buffer)
- **See:** [TEXT_SYSTEM.md](TEXT_SYSTEM.md)

**Data Flow:**

**Player Movement → Map Update:**
```
Controller Input
    ↓
Input Handler
    ↓
Movement Calculator
    ↓
Collision Checker
    ↓
Position Update
    ↓
Camera Update
    ↓
Sprite Update
    ↓
DMA to PPU
```

**Battle Turn → Damage:**
```
Player/Enemy Action
    ↓
Action Validator
    ↓
Damage Calculator
    ↓
Animation Trigger
    ↓
HP Update
    ↓
Status Check
    ↓
Victory/Defeat Check
```

---

### [`MAP_SYSTEM.md`](MAP_SYSTEM.md) 🗺️ Map System
*Map rendering, collision, and events*

**Contents:**
- Map data structure
- Tilemap rendering
- Collision detection
- Event system
- NPC management
- Camera system

**Use when:**
- Understanding map mechanics
- Modifying map behavior
- Adding events
- Debugging map issues

**Map System Architecture:**

**Components:**
```
Map System
├── Map Loader
│   ├── Load map header
│   ├── Decompress tilemap
│   ├── Load collision data
│   └── Initialize events
├── Tilemap Renderer
│   ├── Update BG layers
│   ├── Handle scrolling
│   └── Tile animations
├── Collision System
│   ├── Check walkability
│   ├── Detect triggers
│   └── Handle elevation
├── Event System
│   ├── NPC interactions
│   ├── Chest opens
│   ├── Warp points
│   └── Script triggers
└── Camera System
    ├── Follow player
    ├── Screen boundaries
    └── Smooth scrolling
```

**Map Loading Process:**
```asm
;-----------------------------------------------------------------------------
; LoadMap
; Input: A = Map ID
;-----------------------------------------------------------------------------
LoadMap:
    ; Save map ID
    STA CurrentMap
    
    ; Load map header
    JSR LoadMapHeader       ; Get dimensions, tileset, etc.
    
    ; Load tileset graphics
    JSR LoadTileset
    
    ; Load map palettes
    JSR LoadMapPalettes
    
    ; Decompress tilemap data
    JSR DecompressTilemap
    
    ; Load collision data
    JSR LoadCollisionData
    
    ; Initialize events
    JSR InitializeEvents
    
    ; Set up camera
    JSR InitializeCamera
    
    ; Start map music
    JSR StartMapMusic
    
    RTS
```

**Collision Detection:**
```asm
;-----------------------------------------------------------------------------
; CheckCollision
; Input: X = Player X, Y = Player Y
; Output: Carry set if blocked
;-----------------------------------------------------------------------------
CheckCollision:
    ; Convert pixel coords to tile coords
    TXA
    LSR A                   ; X / 8
    LSR A
    LSR A
    STA TileX
    
    TYA
    LSR A                   ; Y / 8
    LSR A
    LSR A
    STA TileY
    
    ; Get collision data offset
    LDA TileY
    STA $4202               ; Multiply by map width
    LDA MapWidth
    STA $4203
    NOP
    NOP
    NOP
    LDA $4216               ; Product
    CLC
    ADC TileX
    TAX
    
    ; Check collision byte
    LDA CollisionData,X
    AND #$01                ; Bit 0 = walkable
    BEQ .blocked
    
    CLC                     ; Not blocked
    RTS
    
.blocked:
    SEC                     ; Blocked
    RTS
```

**Event Triggering:**
```asm
;-----------------------------------------------------------------------------
; CheckEventTriggers
; Checks if player is standing on any event triggers
;-----------------------------------------------------------------------------
CheckEventTriggers:
    ; Get player position
    LDA PlayerX
    STA CheckX
    LDA PlayerY
    STA CheckY
    
    ; Loop through events
    LDX #$00
.check_loop:
    ; Get event data
    LDA EventTable+EVENT_X,X
    CMP CheckX
    BNE .next_event
    
    LDA EventTable+EVENT_Y,X
    CMP CheckY
    BNE .next_event
    
    ; Event triggered!
    LDA EventTable+EVENT_TYPE,X
    JSR ExecuteEvent
    RTS
    
.next_event:
    TXA
    CLC
    ADC #EVENT_SIZE
    TAX
    CPX EventCount
    BCC .check_loop
    
    RTS
```

---

### [`SOUND_SYSTEM.md`](SOUND_SYSTEM.md) 🔊 Sound System
*Music and sound effect architecture*

**Contents:**
- SPC-700 sound driver
- Music sequencing
- Sound effect system
- Audio memory layout
- Music data format

**Use when:**
- Understanding audio system
- Adding music/SFX
- Debugging audio
- Modifying sound

**Sound System Architecture:**

**Components:**
```
Sound System
├── SPC-700 Driver (APU)
│   ├── Note playback
│   ├── Sample management
│   ├── Effects processing
│   └── Mixing
├── Music Sequencer (CPU)
│   ├── Track parsing
│   ├── Pattern playback
│   ├── Loop handling
│   └── Tempo control
├── SFX Manager (CPU)
│   ├── Effect prioritization
│   ├── Channel allocation
│   └── Queue management
└── Communication (CPU ↔ APU)
    ├── Command sending
    ├── Data transfer
    └── Status checking
```

**SPC-700 Memory Layout:**
```
APU RAM ($0000-$FFFF, 64KB):

$0000-$00EF: Zero Page / Variables
$00F0-$00FF: Hardware registers
$0100-$01FF: Stack
$0200-$02FF: Driver code variables
$0300-$13FF: Music driver code (~4KB)
$1400-$3FFF: Sample data (~11KB)
$4000-$FFBF: Music sequence data (~48KB)
$FFC0-$FFFF: IPL ROM area
```

---

### [`TEXT_SYSTEM.md`](TEXT_SYSTEM.md) 📝 Text System
*Dialogue and text rendering*

**Contents:**
- Text encoding
- Text compression
- Rendering engine
- Text box system
- Variable-width font

**Use when:**
- Understanding text display
- Adding dialogue
- Modifying font
- Debugging text

---

### [`testing.md`](testing.md) ✅ Testing Overview
*Testing strategy and overview*

**Contents:**
- Testing philosophy
- Test categories
- Coverage goals
- Testing workflows

**Use when:**
- Understanding testing approach
- Writing new tests
- Running test suites

---

### [`TESTING_FRAMEWORK.md`](TESTING_FRAMEWORK.md) 🧪 Testing Framework
*Detailed testing framework documentation*

**Contents:**
- Test framework architecture
- Test utilities
- Assertion libraries
- Mock systems
- Test data management

**Use when:**
- Implementing tests
- Extending framework
- Understanding test infrastructure

---

### [`FORMATTING_ANALYSIS.md`](FORMATTING_ANALYSIS.md) 📐 Code Formatting
*Code formatting standards analysis*

**Contents:**
- Formatting rules
- Analysis results
- Inconsistencies found
- Automated formatting

**Use when:**
- Standardizing code format
- Running formatters
- Analyzing code quality

---

## System Architecture

### Game Engine Core

**Responsibilities:**
- Overall system initialization
- Main game loop
- Mode management (Field, Battle, Menu)
- Subsystem coordination
- Resource management

**Key Functions:**
- `Reset` - System initialization
- `MainLoop` - Main game loop
- `SwitchMode` - Change game mode
- `WaitVBlank` - V-Blank synchronization

### Hardware Abstraction

**Purpose:**  
Provide consistent interface to SNES hardware

**Components:**
- PPU wrapper functions
- APU communication
- DMA utilities
- Controller reading
- Timer management

---

## Core Subsystems

### Map System
- **Location:** Bank $01, $03, $07
- **RAM:** $7E2000-$7E3FFF
- **See:** [MAP_SYSTEM.md](MAP_SYSTEM.md)

### Battle System
- **Location:** Bank $02
- **RAM:** $7E0100-$7E03FF
- **See:** [../battle/BATTLE_SYSTEM.md](../battle/BATTLE_SYSTEM.md)

### Graphics Engine
- **Location:** Bank $01
- **Hardware:** PPU, VRAM, OAM
- **See:** [../graphics/GRAPHICS_SYSTEM.md](../graphics/GRAPHICS_SYSTEM.md)

### Sound Engine
- **Location:** Bank $0A, $0B
- **Hardware:** APU, SPC-700
- **See:** [SOUND_SYSTEM.md](SOUND_SYSTEM.md)

### Text Engine
- **Location:** Bank $08, $09
- **RAM:** $7E6000-$7E6FFF
- **See:** [TEXT_SYSTEM.md](TEXT_SYSTEM.md)

---

## Memory Architecture

### ROM Organization (LoROM)
```
$00-$0F: System and game code
$10-$1F: ROM mirror
$20-$3F: Data tables
$40-$6F: Graphics, sound, maps
$70-$7D: Reserved
$7E-$7F: RAM
$80-$FF: ROM mirrors
```

### RAM Layout
```
$7E0000-$7E1FFF: System RAM (8KB)
  - Zero page, stack
  - Battle state
  - System variables

$7E2000-$7E7FFF: Work RAM (24KB)
  - Map buffers
  - Graphics buffers
  - Text buffers
  - Free space

$7F0000-$7FFFFF: Extended RAM (64KB)
  - Save data backup
  - Large buffers
  - Expansion space
```

---

## Testing Framework

### Test Categories
- **Unit Tests** - Individual functions
- **Integration Tests** - Subsystem interactions
- **System Tests** - Complete workflows
- **Regression Tests** - Bug prevention

### Running Tests
```bash
# Run all tests
python tools/testing/run_all_tests.py

# Run specific category
python tools/testing/run_all_tests.py --unit
python tools/testing/run_all_tests.py --integration

# Run with coverage
python tools/testing/run_all_tests.py --coverage
```

### Writing Tests
```python
# tests/test_damage_calc.py
import unittest
from tools.battle import damage_calc

class TestDamageCalculation(unittest.TestCase):
    def test_basic_damage(self):
        """Test basic physical damage calculation."""
        damage = damage_calc.calculate_physical(
            attacker_attack=100,
            defender_defense=50
        )
        # Expected: (100 × 2) - 50 = 150 base
        self.assertGreaterEqual(damage, 150)
        self.assertLessEqual(damage, 150 + 150//16)
```

---

## Related Documentation

### Within This Directory
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Overall architecture
- **[MAP_SYSTEM.md](MAP_SYSTEM.md)** - Map system
- **[SOUND_SYSTEM.md](SOUND_SYSTEM.md)** - Sound system
- **[TEXT_SYSTEM.md](TEXT_SYSTEM.md)** - Text system
- **[TESTING_FRAMEWORK.md](TESTING_FRAMEWORK.md)** - Testing

### Other Documentation
- **[../battle/](../battle/)** - Battle system
- **[../graphics/](../graphics/)** - Graphics system
- **[../reference/](../reference/)** - Data structures
- **[../build/](../build/)** - Build system

---

**Last Updated:** 2025-11-07  
**Architecture Version:** 1.0
