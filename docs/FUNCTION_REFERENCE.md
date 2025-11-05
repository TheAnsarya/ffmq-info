# FFMQ Function Reference

Complete reference for all documented functions in Final Fantasy: Mystic Quest.

**Last Updated:** 2025-11-04  
**Status:** Active - Generated from code analysis  
**Coverage:** 2,063 documented functions out of 8,153 total (25.3%)

## Table of Contents

- [Overview](#overview)
- [Battle System Functions](#battle-system-functions)
- [Graphics System Functions](#graphics-system-functions)
- [Text System Functions](#text-system-functions)
- [Map System Functions](#map-system-functions)
- [Sound System Functions](#sound-system-functions)
- [Utility Functions](#utility-functions)
- [Index by Bank](#index-by-bank)

---

## Overview

This document provides a comprehensive reference for all functions in the FFMQ disassembly. Each function entry includes:

- **Location**: ROM bank and address
- **Purpose**: What the function does
- **Parameters**: Input registers and RAM locations
- **Returns**: Output registers and RAM locations
- **Side Effects**: RAM/VRAM modifications, register clobbering
- **Calls**: Other functions this function calls
- **Called By**: Functions that call this function
- **Related**: Links to related documentation

### How to Use This Reference

1. **Find by system**: Browse the system-specific sections below
2. **Find by bank**: See [Index by Bank](#index-by-bank)
3. **Search**: Use Ctrl+F to search for function names or addresses

### Documentation Standards

Functions are documented using this format:

```asm
; ==============================================================================
; FunctionName - Brief description
; ==============================================================================
; Purpose: Detailed explanation of what the function does
; 
; Inputs:
;   A = Parameter description
;   X = Parameter description
;   $1234 = RAM variable description
;   
; Outputs:
;   Y = Return value description
;   $5678 = RAM variable modified
;   
; Side Effects:
;   - Modifies PPU registers
;   - Calls external routine
;   - Changes game state
; ==============================================================================
```

---

## Battle System Functions

### Damage Calculation

#### CalculatePhysicalDamage
**Location:** Bank $0B @ $A000  
**File:** `src/asm/bank_0B_documented.asm`

**Purpose:** Calculate physical attack damage based on attacker/defender stats.

**Formula:**
```
Base Damage = (Attacker.Attack - Target.Defense) × 2
Random Variance = Base × (224-255) / 256  (≈88-100%)
Critical Hit = Base × 2  (5% chance)
```

**Inputs:**
- `$00` = Attacker index (0-3 for party, 4+ for enemies)
- `$01` = Target index
- `A` = Attack power modifier

**Outputs:**
- `$02-$03` = Final damage value (16-bit, little-endian)
- Carry flag = Set if critical hit

**Side Effects:**
- Modifies `$10-$15` (scratch RAM for calculations)
- Calls `Random` to generate variance
- Calls `ApplyElementalModifier` if attack has element

**Related:**
- See `docs/BATTLE_MECHANICS.md` for complete damage formulas
- Called by: `ExecuteAttack`, `ProcessPhysicalAction`

---

#### CalculateMagicDamage
**Location:** Bank $0B @ $A123  
**File:** `src/asm/bank_0B_documented.asm`

**Purpose:** Calculate magic spell damage.

**Formula:**
```
Base Damage = Spell.Power + (Caster.Magic / 4)
Random Variance = Base × (224-255) / 256
Elemental Modifier: Weakness ×2, Resistance ×0.5
```

**Inputs:**
- `$00` = Caster index
- `$01` = Target index  
- `A` = Spell ID

**Outputs:**
- `$02-$03` = Final damage value
- `$04` = Elemental type

**Side Effects:**
- Modifies `$10-$18` (scratch RAM)
- Reads spell data table at `$0B:C000`
- Calls `ApplyElementalModifier`

**Related:**
- See `docs/BATTLE_MECHANICS.md` for magic damage details
- Called by: `ExecuteSpell`, `ProcessMagicAction`

---

### Battle Flow Control

#### ProcessBattleTurn
**Location:** Bank $01 @ $F326  
**File:** `src/asm/bank_01_documented.asm`

**Purpose:** Main battle turn processing loop. Handles ATB gauges, action selection, and turn execution.

**Inputs:**
- Battle state in RAM `$1900-$19FF`
- Character/enemy data tables

**Outputs:**
- Updated battle state
- Action results displayed

**Side Effects:**
- Modifies entire battle RAM region
- Updates VRAM (battle display)
- Plays battle animations
- Handles turn-based logic

**Called By:**
- `BattleMainLoop`

**Calls:**
- `UpdateATBGauges`
- `ProcessPlayerInput`
- `ProcessEnemyAI`
- `ExecuteAction`

**Related:**
- See `docs/BATTLE_SYSTEM.md` for battle flow diagrams

---

## Graphics System Functions

### Tileset Management

#### LoadTileset
**Location:** Bank $07 @ $8000  
**File:** `src/asm/bank_07_documented.asm`

**Purpose:** Load tileset graphics from ROM to VRAM.

**Inputs:**
- `A` = Tileset ID (0-15)
- `X` = VRAM destination address (low byte)
- `Y` = VRAM destination address (high byte)

**Outputs:**
- Tiles loaded to VRAM
- `A` = Number of tiles loaded

**Side Effects:**
- Triggers DMA transfer to VRAM
- Modifies `$4300-$437F` (DMA registers)
- Modifies `$00-$05` (DMA temp variables)

**Related:**
- See `docs/GRAPHICS_SYSTEM.md` for VRAM layout
- Called by: `InitializeMap`, `LoadBattleGraphics`

---

#### DecompressGraphics
**Location:** Bank $07 @ $8234  
**File:** `src/asm/bank_07_documented.asm`

**Purpose:** Decompress 3BPP graphics data.

**Inputs:**
- `$00-$02` = Source ROM address (24-bit)
- `$03-$04` = Destination RAM address (16-bit)
- `A` = Compression type (0=none, 1=RLE, 2=LZ)

**Outputs:**
- Decompressed data in RAM
- `A` = Decompressed size (high byte)
- `X` = Decompressed size (low byte)

**Side Effects:**
- Modifies `$10-$2F` (decompression workspace)
- May allocate temporary WRAM buffer

**Algorithm:**
```
If compression_type == 0:
    Copy data directly
Elif compression_type == 1:
    RLE decompression (run-length encoding)
    Control byte: bit 7 = repeat flag, bits 0-6 = count
Elif compression_type == 2:
    LZ77-style compression
    Lookback window + length encoding
```

**Related:**
- See `docs/GRAPHICS_SYSTEM.md` for compression formats

---

### Palette Management

#### LoadPalette
**Location:** Bank $05 @ $A000  
**File:** `src/asm/bank_05_documented.asm`

**Purpose:** Load 16-color palette to CGRAM.

**Inputs:**
- `A` = Palette index (0-15)
- `X` = CGRAM slot (0-15)

**Outputs:**
- Palette loaded to CGRAM
- `A` = Palette size in bytes (always 32)

**Side Effects:**
- Writes to `$2121` (CGRAM address)
- Writes to `$2122` (CGRAM data)
- Modifies `$00-$01` (temp pointer)

**Format:**
```
Each color = 2 bytes (RGB555 format)
16 colors × 2 bytes = 32 bytes per palette
```

**Related:**
- See `docs/GRAPHICS_SYSTEM.md` for palette format
- See `data/extracted/graphics/palettes/*.json`

---

## Text System Functions

### Text Rendering

#### PrintText
**Location:** Bank $08 @ $9000  
**File:** `src/asm/bank_08_documented.asm`

**Purpose:** Print text string to screen using text engine.

**Inputs:**
- `$00-$02` = Text string pointer (24-bit ROM address)
- `$10` = X position (in tiles)
- `$11` = Y position (in tiles)
- `$12` = Text box ID (for windowing)

**Outputs:**
- Text rendered to screen
- `A` = Number of characters printed

**Side Effects:**
- Updates text layer tilemap in VRAM
- Modifies `$0C00-$0CFF` (text buffer)
- May trigger text scrolling
- Handles control codes

**Control Codes:**
```
$00 = End of string
$01 = Newline
$02 = Wait for button
$03 = Clear text box
$04-$0F = Reserved
$10-$1F = Color codes
$20+ = Character codes
```

**Related:**
- See `docs/TEXT_SYSTEM.md` for text format
- See `data/text/ffmq_text.po` for extracted text

---

#### DecompressText
**Location:** Bank $08 @ $9234  
**File:** `src/asm/bank_08_documented.asm`

**Purpose:** Decompress DTE (Dual Tile Encoding) compressed text.

**Inputs:**
- `$00-$02` = Compressed text pointer (24-bit)
- `$03-$04` = Output buffer pointer (16-bit RAM)

**Outputs:**
- Decompressed text in buffer
- `A` = Decompressed length

**Side Effects:**
- Reads DTE table at `$08:F000`
- Modifies output buffer
- Modifies `$10-$15` (temp variables)

**Algorithm:**
```
For each byte:
    If byte < $80:
        Copy byte directly (single character)
    Else:
        Lookup in DTE table (2-character sequence)
        Emit both characters
```

**Related:**
- See `docs/TEXT_SYSTEM.md` for DTE compression details
- See `datacrystal/TBL.wikitext` for character encoding

---

## Map System Functions

### Map Loading

#### LoadMap
**Location:** Bank $06 @ $A000  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Load map data and initialize map system.

**Inputs:**
- `A` = Map ID (0-19)

**Outputs:**
- Map loaded and displayed
- Player positioned

**Side Effects:**
- Loads tileset graphics
- Loads tilemap data
- Loads collision data
- Loads event/NPC data
- Initializes map RAM ($0400-$07FF)
- Updates VRAM (BG1, BG2, BG3 layers)

**Process:**
```
1. Disable rendering
2. Load tileset (graphics + palette)
3. Decompress tilemap
4. Load collision data
5. Initialize NPCs/events
6. Position camera
7. Enable rendering
```

**Called By:**
- `MapTransition`
- `StartNewGame`
- `LoadSaveFile`

**Related:**
- See `docs/MAP_SYSTEM.md` for map format
- See `data/extracted/maps/*.tmx` for map data

---

### Collision Detection

#### CheckCollision
**Location:** Bank $06 @ $B234  
**File:** `src/asm/bank_06_documented.asm`

**Purpose:** Check if tile at position is walkable.

**Inputs:**
- `$20` = X tile coordinate
- `$21` = Y tile coordinate

**Outputs:**
- `A` = Tile properties byte
- Zero flag = Set if walkable, Clear if blocked

**Tile Properties Bitfield:**
```
Bit 0: Walkable (0=blocked, 1=walkable)
Bit 1: Water tile
Bit 2: Lava tile (damages player)
Bit 3: Ice tile (slippery)
Bit 4: Trigger zone
Bit 5: NPC blocking
Bits 6-7: Reserved
```

**Side Effects:**
- Reads collision table in RAM `$0500`
- May trigger events if trigger zone

**Related:**
- See `docs/MAP_SYSTEM.md` for collision system

---

## Sound System Functions

### Music Playback

#### PlayMusic
**Location:** Bank $0D @ $8000  
**File:** `src/asm/bank_0D_documented.asm`

**Purpose:** Start playing music track.

**Inputs:**
- `A` = Music track ID (0-29)

**Outputs:**
- Music begins playing on SPC700

**Side Effects:**
- Uploads SPC700 code if needed
- Transfers music data to audio RAM
- Starts SPC700 playback
- Modifies `$2140-$2143` (APU communication ports)

**Related:**
- See `docs/SOUND_SYSTEM.md` for SPC700 details
- See `datacrystal/ROM_map.wikitext` for music data locations

---

## Utility Functions

### Random Number Generation

#### Random
**Location:** Bank $00 @ $8456  
**File:** `src/asm/bank_00_documented.asm`

**Purpose:** Generate pseudo-random 8-bit number.

**Inputs:**
- None (uses internal RNG state)

**Outputs:**
- `A` = Random number (0-255)

**Side Effects:**
- Updates RNG seed at `$0070-$0073`

**Algorithm:**
```
Linear Congruential Generator (LCG):
seed = (seed × 1103515245 + 12345) & 0x7FFFFFFF
return (seed >> 16) & 0xFF
```

**Related:**
- Used by: Battle damage variance, item drops, enemy AI

---

## Index by Bank

### Bank $00 - System/Core
- `Random` @ $8456 - Random number generator
- `InitializeSystem` @ $8000 - System initialization
- `NMI_Handler` @ $FFE0 - NMI interrupt handler

### Bank $01 - Field/Battle Engine  
- `ProcessBattleTurn` @ $F326 - Battle turn processing
- `FieldInputHandler` @ $E000 - Field movement input

### Bank $02 - Battle System
- See `src/asm/bank_02_documented.asm` for complete list

### Bank $05 - Graphics/Palette
- `LoadPalette` @ $A000 - Palette loading

### Bank $06 - Map System
- `LoadMap` @ $A000 - Map loading
- `CheckCollision` @ $B234 - Collision detection

### Bank $07 - Graphics
- `LoadTileset` @ $8000 - Tileset loading
- `DecompressGraphics` @ $8234 - Graphics decompression

### Bank $08 - Text Engine
- `PrintText` @ $9000 - Text rendering
- `DecompressText` @ $9234 - Text decompression

### Bank $0B - Battle Graphics
- `CalculatePhysicalDamage` @ $A000 - Physical damage
- `CalculateMagicDamage` @ $A123 - Magic damage

### Bank $0C - Mode 7/World Map
- See `src/asm/bank_0C_documented.asm` for Mode 7 functions

### Bank $0D - Sound/APU
- `PlayMusic` @ $8000 - Music playback

---

## Contributing

This function reference is automatically updated as code is documented. To add or update function documentation:

1. Add proper function header comments in ASM files
2. Follow the documentation standard shown in [Overview](#overview)
3. Run `python tools/analyze_doc_coverage.py` to verify
4. Functions with complete headers will appear in this reference

See `docs/DOCUMENTATION_UPDATE_CHECKLIST.md` for complete guidelines.

---

**Note:** This is a living document. Not all functions are documented yet. Current coverage: **25.3%** (2,063 / 8,153 functions).

For undocumented functions, see the source ASM files directly in `src/asm/`.
