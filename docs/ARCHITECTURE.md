# Final Fantasy Mystic Quest - System Architecture

## Document Overview

**Purpose:** Comprehensive system architecture documentation for FFMQ ROM  
**Audience:** Developers, modders, and researchers  
**Last Updated:** 2025-11-01  
**Status:** Complete  

---

## Table of Contents

1. [System Overview](#system-overview)
2. [ROM Bank Layout](#rom-bank-layout)
3. [Memory Map](#memory-map)
4. [System Initialization](#system-initialization)
5. [Main Game Loop](#main-game-loop)
6. [Inter-System Communication](#inter-system-communication)
7. [Architecture Diagram](#architecture-diagram)
8. [Related Documentation](#related-documentation)

---

## System Overview

Final Fantasy Mystic Quest is a Super Nintendo Entertainment System (SNES) game that uses a **LoROM memory mapping** configuration with **16 ROM banks** of 32KB each ($8000 bytes per bank).

### Key Characteristics

- **Platform:** Super Nintendo Entertainment System (SNES)
- **Processor:** 65816 CPU (16-bit with 8-bit mode)
- **ROM Size:** 512KB (4 Mbit)
- **ROM Mapping:** LoROM (banks $00-$0F mapped to $8000-$FFFF)
- **SRAM:** Battery-backed save data
- **Architecture:** Event-driven with fixed game loop

### Core Systems

The game is organized into several major subsystems:

1. **Graphics Engine** - Tile/sprite rendering, DMA transfers, VRAM management
2. **Text Engine** - Character rendering, text boxes, dialogue system
3. **Battle System** - Combat mechanics, enemy AI, damage calculation
4. **Menu System** - UI navigation, inventory, character screens
5. **Map System** - Overworld/dungeon navigation, collision detection
6. **Audio Engine** - SPC700 sound driver, music playback
7. **Event System** - Scripting, triggers, cutscenes
8. **Save/Load System** - SRAM management, game state persistence

---

## ROM Bank Layout

### Bank Organization (LoROM Mapping)

Each bank occupies $8000 bytes ($0000-$7FFF in PC space, $8000-$FFFF in SNES space).

| Bank | SNES Address | PC Address | Primary Contents | Key Components |
|------|--------------|------------|------------------|----------------|
| **$00** | $00:8000-$00:FFFF | $000000-$007FFF | **Core Engine & Initialization** | Boot sequence, NMI/IRQ handlers, core engine routines, initialization code |
| **$01** | $01:8000-$01:FFFF | $008000-$00FFFF | **Engine Code** | Additional engine routines, DMA handlers, utility functions |
| **$02** | $02:8000-$02:FFFF | $010000-$017FFF | **Engine Routines** | Extended engine code, graphics helpers, system utilities |
| **$03** | $03:8000-$03:FFFF | $018000-$01FFFF | **Game Logic** | Core game logic, event handlers, script interpreter |
| **$04** | $04:8000-$04:FFFF | $020000-$027FFF | **Graphics Data (Tiles)** | Character/enemy sprite graphics (2BPP/4BPP format at $04:8000) |
| **$05** | $05:8000-$05:FFFF | $028000-$02FFFF | **Graphics Data (Main Tiles)** | Primary tileset graphics ($05:8C80), background tiles, metatiles |
| **$06** | $06:8000-$06:FFFF | $030000-$037FFF | **Map Data & Routines** | Map tilemaps ($06:8000+), collision data, map-related code |
| **$07** | $07:8000-$07:FFFF | $038000-$03FFFF | **Palettes & Sprite Graphics** | Color palettes ($07:B013+), additional sprite data, visual assets |
| **$08** | $08:8000-$08:FFFF | $040000-$047FFF | **Game Data & Text** | Text pointers, dialogue strings, compressed text, item/spell names |
| **$09** | $09:8000-$09:FFFF | $048000-$04FFFF | **Battle System** | Combat engine, damage formulas, enemy AI, battle animations |
| **$0A** | $0A:8000-$0A:FFFF | $050000-$057FFF | **Game Logic** | Character management, inventory system, progression tracking |
| **$0B** | $0B:8000-$0B:FFFF | $058000-$05FFFF | **Game Logic** | Additional game mechanics, field abilities, puzzle logic |
| **$0C** | $0C:8000-$0C:FFFF | $060000-$067FFF | **Menu System & UI** | Menu rendering, text display routines, UI navigation, OAM clearing ($0C:8948) |
| **$0D** | $0D:8000-$0D:FFFF | $068000-$06FFFF | **Menu & UI** | Extended menu code, character screens, inventory display |
| **$0E** | $0E:8000-$0E:FFFF | $070000-$077FFF | **Additional Systems** | Supplementary game systems, special events |
| **$0F** | $0F:8000-$0F:FFFF | $078000-$07FFFF | **Additional Code** | Extended routines, overflow code, miscellaneous |

### Bank Usage Patterns

```
┌─────────────────────────────────────────┐
│ Banks $00-$03: Core Engine & Logic      │ ← System critical, loaded at boot
├─────────────────────────────────────────┤
│ Banks $04-$05: Graphics Tiles           │ ← DMA'd to VRAM during gameplay
├─────────────────────────────────────────┤
│ Banks $06-$08: Maps, Palettes, Text     │ ← Streamed/loaded as needed
├─────────────────────────────────────────┤
│ Banks $09-$0B: Battle & Game Logic      │ ← Context-switched during battles
├─────────────────────────────────────────┤
│ Banks $0C-$0D: Menu System              │ ← Loaded when menus active
├─────────────────────────────────────────┤
│ Banks $0E-$0F: Extended Systems         │ ← Auxiliary/overflow code
└─────────────────────────────────────────┘
```

### Key Data Structures by Bank

#### Bank $04: Graphics Tiles
- **$04:8000+** - Character and enemy sprite graphics (2BPP/4BPP)
- Organized as 8x8 pixel tiles in SNES tile format

#### Bank $05: Main Tilesets
- **$05:8C80+** - Primary tileset for backgrounds and maps
- Background layer graphics

#### Bank $06: Map Tilemaps
- **$06:8000-$06:81FF** - Metatile Set 1 (Overworld/outdoor, 128 metatiles)
- **$06:8200-$06:83FF** - Metatile Set 2 (Indoor/building, 128 metatiles)
- **$06:8400-$06:85FF** - Metatile Set 3 (Dungeon/cave, 128 metatiles)
- **$06:A000-$06:AFFF** - Collision data (interleaved with screen layouts)

**Metatile Format:** 4 bytes per 16x16 metatile
```
Byte 0: Top-Left 8x8 tile index
Byte 1: Top-Right 8x8 tile index
Byte 2: Bottom-Left 8x8 tile index
Byte 3: Bottom-Right 8x8 tile index
```

#### Bank $07: Palettes
- **$07:B013+** - Color palette data (SNES RGB555 format)
- Sprite and background palettes

#### Bank $08: Text Data
- Text pointer tables (16-bit offsets)
- Dialogue strings (custom character encoding)
- Item/spell/monster names
- Compressed text data

#### Bank $0C: OAM Management
- **$0C:8948** - `ClearOAM` routine (fills $220 bytes of OAM via DMA channel 5)

---

## Memory Map

### SNES Memory Space

The SNES uses a complex memory map with multiple regions. FFMQ uses the following key areas:

#### Work RAM (WRAM)

| Address Range | Size | Purpose | Details |
|---------------|------|---------|---------|
| **$7E:0000-$7E:1FFF** | 8KB | Low RAM (Bank $00 mirror) | Fast access, critical variables, stack ($0100-$01FF) |
| **$7E:2000-$7E:7FFF** | 24KB | Extended WRAM | Game variables, buffers, temporary storage |
| **$7E:8000-$7E:FFFF** | 32KB | WRAM Bank $7E | Additional game state, large buffers |
| **$7F:0000-$7F:FFFF** | 64KB | WRAM Bank $7F | Extended memory, rarely used in FFMQ |

**Total WRAM:** 128KB (FFMQ primarily uses ~64KB in banks $7E-$7F)

#### Save RAM (SRAM)

| Address Range | Size | Purpose |
|---------------|------|---------|
| **$70:0000-$70:7FFF** | 32KB | Battery-backed save data | Save slots, game progress, flags |
| **$71:0000-$71:7FFF** | 32KB | Extended SRAM (if used) | Additional save data or unused |

**Total SRAM:** Up to 64KB (battery-backed for save persistence)

#### Hardware Registers (Memory-Mapped I/O)

| Address Range | Purpose | Key Registers |
|---------------|---------|---------------|
| **$21:00-$21:FF** | PPU Registers | Screen mode, background config, VRAM/OAM/CGRAM access |
| **$22:00-$22:FF** | Window & Math Registers | Window masking, color math, mosaic effects |
| **$40:00-$40:FF** | Joypad & Serial I/O | Controller input, serial port |
| **$41:00-$41:FF** | DMA Channels | DMA transfer configuration (8 channels) |
| **$42:00-$43:FF** | PPU Extended | H/V counters, multiplication/division hardware |

**Critical PPU Registers:**
- **$2100 (INIDISP)** - Screen brightness/blanking
- **$2105 (BGMODE)** - Background mode selection
- **$2107-$210A** - Background tilemap addresses
- **$2115-$2119** - VRAM access control/data
- **$2121-$2122 (CGADD/CGDATA)** - Palette (CGRAM) access
- **$2140-$2143** - SPC700 audio communication ports

#### Video RAM (VRAM)

| Address Range | Size | Purpose |
|---------------|------|---------|
| **$0000-$7FFF** | 32KB word-addressable | Tile graphics ($0000-$5FFF), Tilemaps ($6000-$7FFF) |

**VRAM Access:** Through PPU registers $2115-$2119 (VMAIN, VMADDL, VMADDH, VMDATAL, VMDATAH)

#### Character Graphics RAM (CGRAM)

| Address Range | Size | Purpose |
|---------------|------|---------|
| **$00-$FF** | 512 bytes (256 colors × 2 bytes) | Palette memory (RGB555 format) |

**CGRAM Access:** Through registers $2121 (CGADD) and $2122 (CGDATA)

#### Object Attribute Memory (OAM)

| Address Range | Size | Purpose |
|---------------|------|---------|
| **$00-$1FF** | 512 bytes | Sprite attributes (128 sprites × 4 bytes) |
| **$200-$21F** | 32 bytes | Extended sprite attributes (size/toggle bits) |

**OAM Access:** Through registers $2102-$2104 (OAMADDL, OAMADDH, OAMDATA)

### RAM Variable Map (WRAM $7E:0000+)

Key game variables are documented in `src/include/ffmq_ram_variables.inc`:

**Critical Memory Locations:**
- **$0100-$01FF** - CPU Stack
- **$0C00+** - OAM buffer (544 bytes, DMA'd to hardware OAM)
- Game state flags, character stats, inventory, map state, etc.

> **Note:** See [`RAM_MAP.md`](RAM_MAP.md) (future) for complete RAM variable documentation.

### Memory Access Patterns

```
CPU ←──────────→ WRAM ($7E/$7F)
 ↓               ↓
 ├──→ ROM Banks ($00-$0F:8000-FFFF via LoROM mapping)
 ├──→ SRAM ($70/$71 for save data)
 └──→ Hardware Registers ($21xx-$43xx)
      ↓
      ├──→ VRAM (via $2115-$2119) ← DMA Channels
      ├──→ CGRAM (via $2121-$2122)
      ├──→ OAM (via $2102-$2104)
      └──→ SPC700 Audio (via $2140-$2143)
```

---

## System Initialization

### Boot Sequence

The SNES boot process follows this sequence when the console powers on:

#### 1. Hardware Reset ($00:8000 - RESET Vector)

**Location:** Bank $00, RESET interrupt vector  
**File:** `src/asm/bank_00_documented.asm` or `src/asm/banks/bank_00.asm`

**Steps:**
1. CPU starts in **8-bit mode** (emulation mode)
2. Disable interrupts (SEI)
3. Clear decimal mode (CLD)
4. Initialize stack pointer ($0100-$01FF)
5. Switch to **native mode** (CLC, XCE for 65816 native 16-bit mode)

#### 2. Hardware Initialization

**PPU Setup:**
- Force blank ($2100 = $80) - screen off
- Clear VRAM, OAM, CGRAM
- Set background mode (Mode 1 for FFMQ)
- Configure tilemap base addresses

**DMA Setup:**
- Initialize all 8 DMA channels
- Set up standard transfer patterns

**Audio Setup:**
- Initialize SPC700 communication ports ($2140-$2143)
- Upload sound driver to SPC700
- Start audio engine

#### 3. Memory Initialization

**WRAM Clear:**
- Zero out critical RAM regions ($7E:0000-$7E:1FFF)
- Initialize game variables to default states
- Clear buffers (OAM buffer at $0C00+, etc.)

**SRAM Detection:**
- Test SRAM presence
- Validate save data checksums
- Load save slot metadata

#### 4. Graphics Loading

**Initial Assets:**
- Load font tiles to VRAM
- Load title screen graphics
- Set up initial palettes (CGRAM)
- Configure sprite tables (OAM)

#### 5. Audio Start

- Verify SPC700 ready
- Load initial music track
- Start title screen music

#### 6. Interrupt Handlers Setup

**NMI (Non-Maskable Interrupt - VBlank):**
- Enable NMI ($4200)
- Set NMI vector to game's VBlank handler
- VBlank used for VRAM/OAM/CGRAM updates

**IRQ (Interrupt Request):**
- Configure if used (FFMQ uses limited IRQ)
- Set up H/V timers if needed

#### 7. Jump to Title Screen

- Initialize title screen state
- Enable screen rendering ($2100 = $0F)
- Enter main game loop

### Boot Sequence Diagram

```
Power On
   ↓
RESET Vector ($00:8000)
   ↓
[1] CPU Initialization
   ├─ Set 8-bit mode
   ├─ Disable interrupts
   ├─ Clear decimal mode
   ├─ Initialize stack
   └─ Switch to native mode (16-bit)
   ↓
[2] Hardware Initialization
   ├─ Force blank (screen off)
   ├─ Clear VRAM/OAM/CGRAM
   ├─ Set BG mode
   └─ Configure DMA channels
   ↓
[3] Memory Initialization
   ├─ Clear WRAM
   ├─ Initialize variables
   ├─ Detect SRAM
   └─ Load save metadata
   ↓
[4] Graphics Loading
   ├─ Load font tiles → VRAM
   ├─ Load title graphics → VRAM
   ├─ Load palettes → CGRAM
   └─ Clear OAM (sprites off-screen)
   ↓
[5] Audio Start
   ├─ Initialize SPC700
   ├─ Upload sound driver
   └─ Start title music
   ↓
[6] Interrupt Setup
   ├─ Enable NMI (VBlank)
   └─ Set interrupt vectors
   ↓
[7] Enable Screen
   ├─ Set brightness ($2100 = $0F)
   └─ Jump to main loop
   ↓
Main Game Loop (Title Screen)
```

---

## Main Game Loop

### Game Loop Structure

FFMQ uses an **event-driven game loop** with a central dispatch system. The loop runs continuously, processing input and updating game state on each frame (60 FPS).

### Frame Timing

- **NTSC:** 60.0988 Hz (~16.67ms per frame)
- **PAL:** 50.0070 Hz (~20ms per frame)

FFMQ uses NTSC timing primarily.

### Main Loop Flow

```
┌─────────────────────────────────────────┐
│         START OF FRAME                  │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  [1] Wait for VBlank (NMI)              │
│      - CPU halts (WAI instruction)      │
│      - Hardware triggers NMI interrupt  │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  [2] VBlank Handler (NMI Routine)       │
│      - DMA graphics to VRAM             │
│      - DMA sprites to OAM               │
│      - Update palettes (CGRAM)          │
│      - Update scroll registers          │
│      - Read joypad input                │
│      - Increment frame counter          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  [3] Return from NMI                    │
│      - CPU resumes main loop            │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  [4] Update Game State (Active Render)  │
│      - Process controller input         │
│      - Update game mode state machine   │
│      - Execute current mode logic:      │
│        * Title Screen                   │
│        * Field/Overworld                │
│        * Battle                         │
│        * Menu                           │
│        * Event/Cutscene                 │
│      - Calculate sprite positions       │
│      - Build OAM buffer in WRAM         │
│      - Prepare VRAM updates             │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  [5] Prepare Next Frame Assets          │
│      - Queue graphics for DMA           │
│      - Build tilemap changes            │
│      - Update palette buffers           │
│      - Calculate music/SFX commands     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  [6] Loop Back                          │
│      - Jump back to [1] (Wait for VBlank)
└─────────────────────────────────────────┘
```

### Game Mode State Machine

FFMQ uses a **mode-based architecture** where different game states (field, battle, menu) have separate logic handlers:

| Mode | State Variable | Handler Bank | Description |
|------|----------------|--------------|-------------|
| **Title Screen** | $00 | Banks $00-$03 | Logo, main menu, file select |
| **Field/Overworld** | $01 | Banks $03, $06, $0A-$0B | Map navigation, NPC interaction, collision |
| **Battle** | $02 | Bank $09 | Combat engine, enemy AI, animations |
| **Menu** | $03 | Banks $0C-$0D | Inventory, equipment, status screens |
| **Event/Cutscene** | $04 | Bank $03 | Scripted sequences, dialogue, triggers |
| **Transition** | $05 | Banks $00-$01 | Screen fades, map transitions |

**Mode Switch Example:**
```
Field Mode (walking) 
   → Player presses Start 
   → Mode = $03 (Menu)
   → Menu loop runs until B pressed
   → Mode = $01 (return to Field)
```

### Frame Budget

**VBlank Window:** ~4,500 cycles (~1.4ms @ 3.58 MHz)

**VBlank Tasks (NMI Handler):**
- DMA transfers: ~1,000-2,000 cycles (OAM + partial VRAM)
- Register updates: ~200-500 cycles (scroll, palettes, etc.)
- Joypad read: ~50 cycles
- **Total VBlank:** ~1,500-3,000 cycles (must fit in 4,500)

**Active Render Period:** ~12ms (main game logic)
- Game mode update: ~2,000-5,000 cycles
- Physics/collision: ~1,000-3,000 cycles
- AI/event processing: Variable (controlled by frame skip)
- Sprite calculations: ~500-2,000 cycles
- Sound commands: ~200-500 cycles

### VBlank Handler (NMI)

**Critical Operations During VBlank:**

1. **DMA Sprite Data** - Transfer OAM buffer ($7E:0C00+) → hardware OAM
2. **DMA Tile Updates** - Transfer changed tiles → VRAM
3. **Update Palettes** - Write CGRAM changes
4. **Update Scroll Registers** - Background positions ($210D-$2114)
5. **Read Controllers** - Joypad auto-read ($4218-$421B after auto-read completes)
6. **Increment Timers** - Frame counter, RNG seed

**Code Location:** Bank $00, NMI vector handler

---

## Inter-System Communication

FFMQ systems communicate through shared memory (WRAM) and function calls. There is no message-passing or event queue; all communication is synchronous.

### Communication Patterns

#### 1. Shared Memory (WRAM Variables)

**Primary Method:** Systems read/write shared RAM variables.

**Example - Battle System → Graphics Engine:**
```
Battle System writes to:
  $7E:XXXX - Enemy sprite ID
  $7E:YYYY - Enemy X position
  $7E:ZZZZ - Enemy Y position

Graphics Engine reads these and:
  - Builds OAM entries
  - Loads sprite tiles to VRAM
  - Draws enemy on screen
```

**Variable Categories:**
- **Player State:** HP, MP, stats, position, equipment
- **Game State:** Flags, progression, map ID, mode
- **Graphics State:** BG scroll, OAM buffer, VRAM queue
- **Input State:** Button states, last input, repeat timer
- **Audio State:** Music track ID, SFX queue

**Location:** `src/include/ffmq_ram_variables.inc` (variable definitions)

#### 2. Function Calls (JSR/JSL)

**Subroutine Calls:**
- **JSR** (Jump to SubRoutine) - Same bank, 16-bit address
- **JSL** (Jump to SubRoutine Long) - Cross-bank, 24-bit address
- **RTS/RTL** - Return from subroutine

**Example - Text Engine Call:**
```asm
; Call text display routine from game logic
LDA #$1234          ; Text string ID
JSL DisplayText     ; Long call to text engine (Bank $0C)
; Text engine displays string, returns
```

**Common Subsystem Entry Points:**
- **Graphics Engine:** DMA routines, tile loading
- **Text Engine:** `DisplayText`, `RenderTextBox`
- **Battle System:** `EnterBattle`, `ProcessTurn`, `CalculateDamage`
- **Menu System:** `OpenMenu`, `HandleMenuInput`, `CloseMenu`
- **Audio Engine:** `PlayMusic`, `PlaySFX`, `StopAudio`

#### 3. DMA System (Graphics Pipeline)

**Graphics Data Flow:**

```
Game Logic (Banks $03/$09/$0A/etc.)
   ↓
Build graphics data in WRAM buffers:
   - Tile changes → VRAM queue buffer
   - Sprite positions → OAM buffer ($0C00+)
   - Palette changes → CGRAM queue buffer
   ↓
VBlank Handler (NMI) triggered
   ↓
DMA Controller transfers:
   - OAM buffer → Hardware OAM ($2102-$2104)
   - VRAM queue → VRAM ($2115-$2119)
   - CGRAM queue → CGRAM ($2121-$2122)
   ↓
Screen displays updated graphics
```

**DMA Channels Used by FFMQ:**
- **Channel 0:** VRAM tile uploads
- **Channel 1:** Tilemap uploads
- **Channel 5:** OAM transfers (`ClearOAM` at $0C:8948 uses channel 5)
- **Other channels:** Audio, palettes, dynamic transfers

#### 4. Audio Communication (APU Ports)

**CPU ↔ SPC700 Communication:**

```
Main CPU (65816)
   ↓
Write to APU ports ($2140-$2143):
   - Command byte (track ID, SFX ID, etc.)
   - Data bytes (parameters)
   ↓
SPC700 Audio Processor reads ports
   ↓
Process command:
   - Load music track
   - Play sound effect
   - Adjust volume
   ↓
SPC700 writes acknowledgment → $2140
   ↓
Main CPU reads $2140 to confirm
```

**Audio Commands:**
- **Play Music:** Command $01, Track ID in $2141
- **Play SFX:** Command $02, SFX ID in $2141
- **Stop Audio:** Command $03
- **Set Volume:** Command $04, Volume in $2141

**Asynchronous:** SPC700 runs independently; CPU sends commands and polls for completion.

### System Dependency Map

```
┌────────────────────────────────────────────────┐
│              Main Game Loop (Bank $00)          │
│         (Orchestrates all subsystems)           │
└────────────────────────────────────────────────┘
      ↓              ↓              ↓
┌──────────┐   ┌──────────┐   ┌──────────┐
│ Graphics │   │   Text   │   │  Audio   │
│  Engine  │←──│  Engine  │   │  Engine  │
│ (Banks   │   │ (Bank 0C)│   │ (SPC700) │
│ 00-02,04)│   └──────────┘   └──────────┘
└──────────┘        ↑              ↑
      ↑             │              │
      │     ┌───────┴──────────────┴──────┐
      │     │                              │
┌─────┴─────┴──────┐   ┌──────────────────┴──────┐
│  Field/Map System │   │    Battle System        │
│  (Banks 03,06,0A) │   │    (Bank 09)            │
└───────────────────┘   └─────────────────────────┘
      ↑                           ↑
      │                           │
      └───────────┬───────────────┘
                  │
         ┌────────┴────────┐
         │  Menu System    │
         │  (Banks 0C-0D)  │
         └─────────────────┘
                  ↑
                  │
         ┌────────┴────────┐
         │  Save/Load      │
         │  (SRAM $70-$71) │
         └─────────────────┘
```

**Key Dependencies:**
- **Graphics Engine** ← Nearly all systems (for visual output)
- **Text Engine** ← Field, Battle, Menu (for dialogue/UI text)
- **Audio Engine** ← All systems (for music/SFX)
- **Menu System** ← Field, Battle (for inventory/status)
- **Battle System** → Graphics, Text, Audio (isolated combat logic)
- **Field System** → Graphics, Text, Audio, Menu (main gameplay)

---

## Architecture Diagram

### High-Level System Overview

```
╔═══════════════════════════════════════════════════════════════════╗
║                    SNES Hardware Layer                             ║
╠═══════════════════════════════════════════════════════════════════╣
║  CPU: 65816 (16-bit) │ PPU │ SPC700 Audio │ DMA │ Joypad │ SRAM   ║
╚═══════════════════════════════════════════════════════════════════╝
                              ↓ ↑
╔═══════════════════════════════════════════════════════════════════╗
║                      Memory Subsystem                              ║
╠═══════════════════════════════════════════════════════════════════╣
║ ROM (16 Banks × 32KB) │ WRAM (128KB) │ VRAM (64KB) │ CGRAM (512B) ║
║ SRAM (64KB Battery)   │ OAM (544B)    │ APU Ports                  ║
╚═══════════════════════════════════════════════════════════════════╝
                              ↓ ↑
┌───────────────────────────────────────────────────────────────────┐
│                     Core Engine (Banks $00-$02)                    │
├───────────────────────────────────────────────────────────────────┤
│  • Initialization & Boot                                           │
│  • Main Game Loop (60 FPS)                                         │
│  • VBlank Handler (NMI)                                            │
│  • DMA Manager                                                     │
│  • Mode State Machine                                              │
│  • Interrupt Handlers (NMI/IRQ)                                    │
└───────────────────────────────────────────────────────────────────┘
         ↓                    ↓                    ↓
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ Graphics Engine  │  │   Text Engine    │  │  Audio Engine    │
│  (Banks 00-02)   │  │   (Bank $0C)     │  │  (SPC700 CPU)    │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ • Tile DMA       │  │ • Text Rendering │  │ • Music Playback │
│ • Sprite Mgmt    │  │ • Text Boxes     │  │ • Sound Effects  │
│ • VRAM Upload    │  │ • Dialogue       │  │ • Volume Control │
│ • Palette Load   │  │ • Font Drawing   │  │ • Channel Mixing │
│ • BG Scroll      │  │ • Text Compress  │  └──────────────────┘
└──────────────────┘  └──────────────────┘
         ↑                    ↑                    ↑
         │                    │                    │
┌────────┴────────────────────┴────────────────────┴───────────────┐
│                    Game Mode Dispatcher                            │
├───────────────────────────────────────────────────────────────────┤
│  Mode Switch: Title → Field → Battle → Menu → Event               │
└───────────────────────────────────────────────────────────────────┘
    ↓            ↓            ↓            ↓            ↓
┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
│ Title  │  │ Field  │  │ Battle │  │  Menu  │  │ Event  │
│ Screen │  │ System │  │ System │  │ System │  │ System │
├────────┤  ├────────┤  ├────────┤  ├────────┤  ├────────┤
│ Bank   │  │ Banks  │  │ Bank   │  │ Banks  │  │ Bank   │
│ $00-03 │  │ $03,06 │  │ $09    │  │ $0C-0D │  │ $03    │
│        │  │ $0A-0B │  │        │  │        │  │        │
├────────┤  ├────────┤  ├────────┤  ├────────┤  ├────────┤
│• Logo  │  │• Map   │  │• Combat│  │• Invent│  │• Script│
│• Menu  │  │• Walk  │  │• AI    │  │• Equip │  │• NPC   │
│• Save  │  │• NPC   │  │• Damage│  │• Status│  │• Trig  │
│  Select│  │• Collid│  │• Anim  │  │• Save  │  │• Dialog│
└────────┘  └────────┘  └────────┘  └────────┘  └────────┘
                │            │            │
                └────────────┴────────────┘
                             ↓
                    ┌─────────────────┐
                    │ Data Layer      │
                    ├─────────────────┤
                    │ • Maps (Bank 6) │
                    │ • Tiles (4/5)   │
                    │ • Text (Bank 8) │
                    │ • Palettes (7)  │
                    │ • SRAM (Save)   │
                    └─────────────────┘
```

### Data Flow Diagram

```
┌─────────────┐
│ Player      │
│ Controller  │
└──────┬──────┘
       ↓
┌──────────────────────────────────┐
│  Joypad Auto-Read ($4218-$421B)  │
│  (During VBlank)                 │
└──────────────┬───────────────────┘
               ↓
┌──────────────────────────────────┐
│  Input Processing                │
│  (Main Loop, Active Render)      │
└──────────────┬───────────────────┘
               ↓
       ┌───────┴────────┐
       ↓                ↓
┌─────────────┐  ┌─────────────┐
│ Field Input │  │ Battle Input│
│ Processing  │  │ Processing  │
└──────┬──────┘  └──────┬──────┘
       │                │
       └────────┬───────┘
                ↓
┌──────────────────────────────────┐
│  Update Game State (WRAM)        │
│  • Character position            │
│  • HP/MP/stats                   │
│  • Map state                     │
│  • Flags/progression             │
└──────────────┬───────────────────┘
               ↓
┌──────────────────────────────────┐
│  Build Graphics Buffers (WRAM)   │
│  • OAM buffer ($0C00+)           │
│  • VRAM update queue             │
│  • Palette update queue          │
└──────────────┬───────────────────┘
               ↓
┌──────────────────────────────────┐
│  Wait for VBlank (WAI)           │
└──────────────┬───────────────────┘
               ↓
┌──────────────────────────────────┐
│  NMI Handler (VBlank Interrupt)  │
│  ┌────────────────────────────┐  │
│  │ 1. DMA OAM → Hardware OAM  │  │
│  │ 2. DMA VRAM updates        │  │
│  │ 3. Write CGRAM (palettes)  │  │
│  │ 4. Update scroll registers │  │
│  │ 5. Send audio commands     │  │
│  └────────────────────────────┘  │
└──────────────┬───────────────────┘
               ↓
┌──────────────────────────────────┐
│  PPU Renders Frame (Hardware)    │
│  • Reads VRAM for tiles          │
│  • Reads OAM for sprites         │
│  • Reads CGRAM for colors        │
│  • Outputs to TV (60 Hz)         │
└──────────────────────────────────┘
               ↓
         Loop back to top
```

---

## Related Documentation

### Core Documentation

- **[BUILD_SYSTEM.md](BUILD_SYSTEM.md)** - Complete build workflow, dependencies, and Makefile reference
- **[BYTE_PERFECT_REBUILD.md](BYTE_PERFECT_REBUILD.md)** - Asset extraction and byte-perfect rebuild process
- **[data_formats.md](data_formats.md)** - Binary data format specifications (maps, text, graphics)
- **[graphics-format.md](graphics-format.md)** - SNES graphics tile formats (2BPP/4BPP/8BPP)

### Source Code References

- **[src/asm/README.md](../src/asm/README.md)** - Source code organization and file structure
- **[src/include/ffmq_ram_variables.inc](../src/include/ffmq_ram_variables.inc)** - Complete RAM variable definitions
- **[src/include/snes_registers.inc](../src/include/snes_registers.inc)** - SNES hardware register definitions
- **[src/include/ffmq_macros.inc](../src/include/ffmq_macros.inc)** - Assembly macros and helper functions

### System-Specific Documentation

- **RAM_MAP.md** (future) - Complete memory map with all WRAM variables
- **ROM_DATA_MAP.md** (future) - Detailed ROM data structure locations
- **TEXT_ENGINE.md** (future) - Text rendering and dialogue system architecture
- **GRAPHICS_ENGINE.md** (future) - Graphics pipeline and DMA transfer details
- **BATTLE_SYSTEM.md** (future) - Combat mechanics and damage formulas
- **AUDIO_SYSTEM.md** (future) - SPC700 sound driver and music engine

### External Resources

- **SNES Development Manual** - Official Nintendo SNES hardware documentation
- **65816 CPU Reference** - WDC 65816 processor instruction set
- **SPC700 Audio Reference** - Sony SPC700 audio processor documentation

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial architecture documentation created | GitHub Copilot |

---

**Document Status:** ✅ Complete  
**Next Steps:** Create system-specific documentation (RAM_MAP.md, ROM_DATA_MAP.md, etc.)

